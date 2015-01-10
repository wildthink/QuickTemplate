//
//  QuickTemplate.m
//  QuickTemplate
//
//  Created by Jason Jobe on 9/21/13.
//  Copyright (c) 2013 Jason Jobe. All rights reserved.
//


/*
 QuickTemplate uses delimters '<' and '>' to indicate and bracket template commands. It borrows the
 XML syntax of using '<cmd/>' to indicate a self-contained command and the '<cmd> ....</cmd>' to bracket
 text to which the command is applied.
 
 The following commands are supported. The full name or the first character may be used, the exception being
 the 'if' and 'ifnot' commands.
 
 v)alue
     <v:myname/>
     <v:myname>default name</v>
 
 s)tyle
    <s:stylename>Some text to style</s>
 
 l)oop
    <loop:var:keypath>Some text named <v:var></loop>
 
 q)uote
     <q>some text</q>    ==>  "some text"
     <q:LT/>             ==>  <
     <q:GT/>             ==>  >
 
 a)
    <a:http://apple.com>Apple</a>
 
 show-if)
    <if:cond>text that appears if cond evaluates to non-nil</if>
 
 omit-if)
    <ifnot:cond_keypath>text that appears if cond evaluates to nil or NO or false</if>
 
 img)
    <img:image_name/>
 */

#import "QuickTemplate.h"
//#import "JREnum.h"
//#import "NSFoundation+Extra.h"

NSString* QTFormatterKey = @"QTFormatterKey";
NSString* QTValueKeypath = @"QTValueKeypath";


typedef NS_ENUM(NSInteger, QTCmdType) {
//JREnum(QTCmdType,
    QTCmdUnknown,
    
    QTCmdValue,
    QTCmdStyle,
    QTCmdLoop,
    QTCmdQuote,
    QTCmdAnchor,
    QTCmdImage,
    QTCmdOmitIf,
    QTCmdUseIf,
    QTCmdEnd
};

NSString *QTCmdTypeToString (QTCmdType type) {
    switch (type) {
        case QTCmdValue: return @"QTCmdValue";
        case QTCmdStyle: return @"QTCmdStyle";
        case QTCmdLoop: return @"QTCmdLoop";
        case QTCmdQuote: return @"QTCmdQuote";
        case QTCmdAnchor: return @"QTCmdAnchor";
        case QTCmdImage: return @"QTCmdImage";
        case QTCmdOmitIf: return @"QTCmdOmitIf";
        case QTCmdUseIf: return @"QTCmdUseIf";
        case QTCmdEnd: return @"QTCmdEnd";
        
        default:
            return @"QTCmdUnknown";
    }
}

static NSString *ScopeParentKey = @"__ScopeParentKey";

//static id top (NSArray *self) {
//    NSInteger ndx = [self count];
//    return (ndx == 0 ? nil : [self objectAtIndex:(ndx - 1)]);
//}

static id pop (NSMutableArray *self) {
    id last = [self lastObject];
    [self removeLastObject];
    return last;
}

static void push (NSMutableArray *self, id item) {
    [self addObject:item];
}

static NSDictionary* popScope (NSDictionary *self) {
    return [self objectForKey:ScopeParentKey];
}

static NSDictionary* pushScope (NSDictionary *self, NSDictionary* newValues) {
    NSMutableDictionary *mdict = [newValues mutableCopy];
    [mdict setValue:mdict forKey:ScopeParentKey];
    return mdict;
}

static BOOL BooleanValue(id nob) {
    if ([nob isKindOfClass:[NSNumber class]] && [nob integerValue] == 0)
        return NO;
    // else
    return (nob == nil ? NO : YES);
}

@interface pcode : NSObject

@property (strong, nonatomic) id arg1;
@property (strong, nonatomic) id arg2;

// This MUST be WEAK to avoid retain cycles
@property (weak, nonatomic) pcode *matching_pcode;

@property QTCmdType code;
@property BOOL isSelfEndTag;
@property BOOL isEndTag;

@end

@implementation pcode

+ (QTCmdType)typeFromTag:(NSString*)tag
{
    static NSDictionary *tags;
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        tags =
        @{
          @"v": @(QTCmdValue),
          @"value": @(QTCmdValue),
          @"s": @(QTCmdStyle),
          @"style": @(QTCmdStyle),
          @"a": @(QTCmdAnchor),
          @"img": @(QTCmdImage),
          @"l": @(QTCmdLoop),
          @"loop": @(QTCmdLoop),
          @"q": @(QTCmdQuote),
          @"quote": @(QTCmdQuote),
          @"use-if": @(QTCmdUseIf),
          @"show": @(QTCmdUseIf),
          @"omit": @(QTCmdOmitIf),
          @"omit-if": @(QTCmdOmitIf),
          };
    });
    return [[tags objectForKey:tag] intValue];;
}


+ (NSAttributedString*)literalValueForKey:(NSString*)key
{
    static NSDictionary *literals;
    static dispatch_once_t once;

    dispatch_once(&once, ^{
        literals =
        @{
          @"LT": [[NSAttributedString alloc] initWithString:@"<"],
          @"GT": [[NSAttributedString alloc] initWithString:@">"],
          @"DQ": [[NSAttributedString alloc] initWithString:@"\""],
          @"SQ": [[NSAttributedString alloc] initWithString:@"'"],
          };
    });
    
    return [literals objectForKey:key];
}

+ (instancetype)pcodeFromTag:(NSString*)tag
{
    pcode *pc = [[pcode alloc] init];
    
    if ([@"/" isEqualToString:tag]) {
        // We have an anonymous close tag '</>'
        pc.isEndTag = YES;
        return pc;
    }
    
    if ([tag characterAtIndex:0] == '/') {
        tag = [tag substringFromIndex:1];
        pc.isEndTag = YES;
    }

    if ([tag characterAtIndex:[tag length] - 1] == '/') {
        tag = [tag substringToIndex:[tag length] - 1];
        pc.isEndTag = YES;
        pc.isSelfEndTag = YES;
    }

    NSArray *argv = [tag componentsSeparatedByString:@":"];

    pc.code = [self typeFromTag:[argv objectAtIndex:0]];
    if (pc.code == QTCmdAnchor && ! pc.isEndTag) {
        NSUInteger ndx = [[argv objectAtIndex:0] length] + 1; // extra for the ':'
        pc.arg1 = [tag substringFromIndex:ndx];
    }
    else {
        pc.arg1 = ([argv count] > 1) ? [argv objectAtIndex:1] : nil;
        pc.arg2 = ([argv count] > 2) ? [argv objectAtIndex:2] : nil;
    }
    // <q>nnn</q> => "nnn"
    // <q:LT/> => a literal value, in this example <
    if (pc.code == QTCmdQuote) {
        if (pc.arg1) {
            pc.arg1 = [self literalValueForKey:pc.arg1];
        }
        else {
            pc.arg1 = [self literalValueForKey:@"DQ"];
        }
    }
    return pc;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"(%@ %@%s)", QTCmdTypeToString(self.code), self.arg1,
            (self.isEndTag ? " *" : "")];
}

@end


@implementation NSScanner (QuickTemplateExtras)

- (unichar)nextCharacter
{
    unichar ch = [[self string] characterAtIndex:[self scanLocation]];
    return ch;
}

@end

@implementation QuickTemplate

- initWithString:(NSString*)template stylesheet:(NSDictionary*)stylesheet;
{
    self.template = template;
    self.pcode = [[self class] parseTemplate:template];
    self.stylesheet = stylesheet;
    return self;
}

+ (NSArray*)parseTemplate:(NSString*)template
{
    NSScanner *scanr = [NSScanner scannerWithString:template];
    NSMutableArray *codes = [NSMutableArray array];
    NSMutableArray *stack = [NSMutableArray array];

    NSString *text;
    NSString *tag;
    
    [scanr setCharactersToBeSkipped:nil];
    
    while (! [scanr isAtEnd])
    {
        // Gather up literal text
        text = nil;
        [scanr scanUpToString:@"<" intoString:&text];
        if (text) {
            [codes addObject:text];
        }
        // scan and parse instruction
        [scanr scanString:@"<" intoString:NULL];
        tag = nil;
        [scanr scanUpToString:@">" intoString:&tag];
        [scanr scanString:@">" intoString:NULL];
        if (tag) {
            pcode *pc = [pcode pcodeFromTag:tag];

            [codes addObject:pc];
            if (pc.isSelfEndTag) {
                pc.matching_pcode = pc;
            }
            else if (pc.isEndTag) {
//                pcode *start_tag = [stack pop];
                pcode *start_tag = pop(stack);
                start_tag.matching_pcode = pc;
                pc.matching_pcode = start_tag;
            }
            else {
//                [stack push:pc];
                push (stack, pc);
            }
        }
    }
    return codes;
}

- (NSDictionary*)textAttributesForKey:(NSString*)styleKey {
    id value = [self.alternateStylesheet objectForKey:styleKey];
    if (value) {
        return value;
    }
    // else
    return [self.stylesheet objectForKey:styleKey];
}

- (Image*)imageForKey:(NSString*)key {
    return [Image imageNamed:key];
}

- (NSAttributedString*)attributedStringForImageNamed:(NSString*)imageKey withRoot:root inScope:(NSDictionary*)scope
{
    Image *img;
    NSString *imageName;
    
    imageName = [root valueForKeyPath:imageKey];
    if (!imageName) {
        imageName = [scope valueForKeyPath:imageKey];
    }
    if (!imageName) {
        imageName = imageKey;
    }
    if ([imageName hasPrefix:@"http:"] || [imageName hasPrefix:@"file:"]) {
        img = [[Image alloc] initWithContentsOfURL:[NSURL URLWithString:imageName]];
    }
    else {

        img = [Image imageNamed:imageName];
    }
    return [self attributedStringForImage:img];
}

- (NSAttributedString*)attributedStringForImage:(Image*)image
{
#if TARGET_OS_IPHONE
    NSTextAttachment *textAttachment = [NSTextAttachment initWithData:nil ofType:nil];
    textAttachment.image = image;
    return [NSAttributedString attributedStringWithAttachment:textAttachment];
#else
    NSFileWrapper* wrapper =[[NSFileWrapper alloc] initRegularFileWithContents:
                              [image TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:1]];
                             
    [wrapper setPreferredFilename:@"image.tiff"];

    return [NSAttributedString attributedStringWithAttachment:
                                            [[NSTextAttachment alloc] initWithFileWrapper:wrapper]];
#endif
}

- (NSAttributedString*)attributedStringUsingRootValue:root;
{
    return [self attributedStringUsingRootValue:root alternateStylesheet:nil];
}

- (NSAttributedString*)attributedStringUsingRootValue:root alternateStylesheet:(NSDictionary*)alternateStyles;
{
    self.alternateStylesheet = alternateStyles;
    NSAttributedString *attrStr = [self appendToAttributedString:[[NSMutableAttributedString alloc] init] usingRootValue:root];
    self.alternateStylesheet = nil;
    return attrStr;
}

- (NSMutableAttributedString*)appendToAttributedString:(NSMutableAttributedString*)astr usingRootValue:root
{
    return [self executeCodes:self.pcode appendingToAttributedString:astr usingRootValue:root inScope:@{}];
}

- (NSMutableAttributedString*)executeCodes:(NSArray*)codes
               appendingToAttributedString:(NSMutableAttributedString*)astr
                            usingRootValue:root
                                   inScope:(NSDictionary*)scope
{
    QTCmdType code;
    NSAttributedString *as;
    id value;
    pcode *pc;
    NSInteger cnt = [codes count];
    NSMutableArray *stack = [NSMutableArray array]; // Holds numbers to build the tag range
    NSInteger stackNdx;
    NSArray *list;

    BOOL flag;
    
    
    for (NSInteger ndx = 0; ndx < cnt; ++ndx)
    {
        NSInteger curpos = [astr length];
        
        id item = [codes objectAtIndex:ndx];
        if ([item isKindOfClass:[NSString class]]) {
            [astr appendAttributedString:[[NSAttributedString alloc] initWithString:item]];
            continue;
        }
        if ([item isKindOfClass:[NSAttributedString class]]) {
            [astr appendAttributedString:item];
            continue;
        }
        NSRange range;
        pc = (pcode*)item;
        
        code = pc.code;
        if (pc.isEndTag)  {
            NSInteger start = [pop(stack) intValue]; // [[stack pop] intValue];
            range = NSMakeRange(start, (curpos - start));
        }
        else {
//            [stack push:@(curpos)];
            push (stack, @(curpos));
        }

        NSString *strValue;
        NSValueTransformer *transformer;
        
        switch (code)
        {
            case QTCmdValue:
                if (pc.isEndTag) {
                    value = [root valueForKeyPath:pc.arg1];
                    if (value) {
                        if (pc.arg2) {
                            // Then we may have a NSFormatter identifier
                            NSDictionary *props = [self textAttributesForKey:pc.matching_pcode.arg1];
                            id fmtr = props[pc.arg2];
                            
                            fmtr = fmtr ?: pc.arg2;

                            if ([fmtr isKindOfClass:[NSFormatter class]]) {
                                strValue = [(NSFormatter*)fmtr stringForObjectValue:value];
                            }
                            else if ((transformer = [NSValueTransformer valueTransformerForName:fmtr])) {
                                strValue = [transformer transformedValue:value];
                            }
                            else {
                                strValue = [value description];
                            }
                        }
                        as = [[NSAttributedString alloc] initWithString:strValue];
                        [astr appendAttributedString:as];
                    }
                }
                break;
                
            case QTCmdQuote:
                if ([pc.arg1 isKindOfClass:[NSAttributedString class]]) {
                   [astr appendAttributedString:pc.arg1];
                }
                else if (pc.arg1) {
                    as = [[NSAttributedString alloc] initWithString:[pc.arg1 description]];
                    [astr appendAttributedString:as];
                }
                break;
             
            case QTCmdStyle:
                if (pc.isEndTag) {
                    NSDictionary *props = [self textAttributesForKey:pc.matching_pcode.arg1];
                    [astr addAttributes:props range:range];
                }
                break;

            case QTCmdAnchor:
                if (pc.isEndTag) {
                    NSDictionary *props = @{ NSLinkAttributeName: pc.matching_pcode.arg1 };
                    [astr addAttributes:props range:range];
                }
                break;

            case QTCmdImage:
                if (pc.isEndTag) {
                    [astr appendAttributedString:[self attributedStringForImageNamed:pc.matching_pcode.arg1 withRoot:root inScope:scope]];
                }
                break;

            case QTCmdUseIf:
                if (!pc.isEndTag) {
                    flag = BooleanValue([root valueForKeyPath:pc.arg1]);
                    if (!flag) {
                        stackNdx = [codes indexOfObjectIdenticalTo:pc.matching_pcode];
                        if (stackNdx != NSNotFound) {
                            ndx = stackNdx - 1;
                        }
                    }
                }
                break;

            case QTCmdOmitIf:
                if (!pc.isEndTag) {
                    flag = BooleanValue([root valueForKeyPath:pc.arg1]);
                    if (flag) {
                        stackNdx = [codes indexOfObjectIdenticalTo:pc.matching_pcode];
                        if (stackNdx != NSNotFound) {
                            ndx = stackNdx - 1;
                        }
                    }
                }
                break;

            case QTCmdLoop:
                list = [root valueForKeyPath:pc.arg2];
                for (id item in list) {
//                    scope = [scope pushScope:@{pc.arg1: item}];
                    scope = pushScope(scope, @{ pc.arg1: item });
                    NSUInteger endNdx = [codes indexOfObjectIdenticalTo:pc.matching_pcode];
                    [self executeCodes:[codes subarrayWithRange:NSMakeRange(ndx, (endNdx - ndx))]
                                                appendingToAttributedString:astr usingRootValue:root inScope:scope];
                }
//                 scope = [scope popScope];
                scope = popScope(scope);
                
            default:
                break;
        }
    }
    
    return astr;
}


@end

