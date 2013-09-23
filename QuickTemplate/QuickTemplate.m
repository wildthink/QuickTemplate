//
//  QuickTemplate.m
//  QuickTemplate
//
//  Created by Jason Jobe on 9/21/13.
//  Copyright (c) 2013 Jason Jobe. All rights reserved.
//

/*
 Time-To-Code
 ------------
 21Sep2013/4
 22Sep2013/2
 
 */

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
 
 if)
    <if:cond>text that appears if cond evaluates to non-nil</if>
 
 ifnot)
    <ifnot:cond_keypath>text that appears if cond evaluates to nil or NO or false</if>
 
 */

#import "QuickTemplate.h"
#import "JREnum.h"
#import "NSArray+Stack.h"


//typedef NS_ENUM(NSInteger, QTCmdType) {
JREnum(QTCmdType,
    QTCmdUnknown,
    QTCmdValue,
    QTCmdStyle,
    QTCmdLoop,
    QTCmdQuote,
//    QTCmdLiteral,
    QTCmdAnchor,
    QTCmdIf,
    QTCmdIfNot,
    QTCmdEnd
);

@interface pcode : NSObject
{
    @public
    QTCmdType code;
    id arg1;
    id arg2;
    BOOL isEndTag;
}
@end

@implementation pcode

+ (QTCmdType)typeFromTag:(NSString*)tag
{
    unichar ch = [tag characterAtIndex:0];
    ch = tolower(ch);
    
    switch (ch) {
        case 'v':
            return QTCmdValue;
        case 'a':
            return QTCmdAnchor;
        case 'l':
            return QTCmdLoop;
        case 's':
            return QTCmdStyle;
        case 'i':
            return QTCmdIf;
        case 'q':
            return QTCmdQuote;
        default:
            return QTCmdUnknown;
    }
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
    
    if ([tag characterAtIndex:0] == '/') {
        tag = [tag substringFromIndex:1];
        pc->isEndTag = YES;
    }

    if ([tag characterAtIndex:[tag length] - 1] == '/') {
        tag = [tag substringToIndex:[tag length] - 1];
        pc->isEndTag = YES;
    }

    NSArray *argv = [tag componentsSeparatedByString:@":"];

    pc->code = [self typeFromTag:[argv objectAtIndex:0]];
    pc->arg1 = ([argv count] > 1) ? [argv objectAtIndex:1] : nil;
    pc->arg2 = ([argv count] > 2) ? [argv objectAtIndex:2] : nil;

    // <q>nnn</q> => "nnn"
    // <q:LT/> => a literal value, in this example <
    if (pc->code == QTCmdQuote) {
        if (pc->arg1) {
            pc->arg1 = [self literalValueForKey:pc->arg1];
        }
        else {
            pc->arg1 = [self literalValueForKey:@"DQ"];
        }
    }
    return pc;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"(%@ %@%s)", QTCmdTypeToString(code), arg1,
            (isEndTag ? " *" : "")];
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
        }
    }
    return codes;
}

- (NSAttributedString*)attributedStringUsingRootValue:root;
{
    return [self insertAttributedStringUsingRootValue:root
                                intoAttributedString:[[NSMutableAttributedString alloc] init] at:0];
}

- (NSMutableAttributedString*)insertAttributedStringUsingRootValue:root intoAttributedString:(NSMutableAttributedString*)astr at:(NSInteger)pos;
{
    QTCmdType code = QTCmdAnchor;
    NSAttributedString *as;
    id value;
    pcode *pc;
    NSInteger cnt = [self.pcode count];
    NSMutableArray *stack = [NSMutableArray array];
    
    for (NSInteger ndx = 0; ndx < cnt; ++ndx)
    {
        NSInteger curpos = [astr length];
        
        id item = [self.pcode objectAtIndex:ndx];
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
        
        code = pc->code;
        if (pc->isEndTag)  {
            NSInteger start = [[stack pop] intValue];
            range = NSMakeRange(start, (curpos - start));
        }
        else {
            [stack push:@(curpos)];
        }

        switch (code)
        {
            case QTCmdValue:
                if (pc->isEndTag) {
                    value = [root valueForKeyPath:pc->arg1];
                    if (value) {
                        as = [[NSAttributedString alloc] initWithString:[value description] attributes:nil];
                        [astr appendAttributedString:as];
                    }
                }
                break;
                
            case QTCmdQuote:
//                if (pc->isEndTag) {
//                    value = [root valueForKeyPath:pc->arg1];
//                    if (value) {
//                        as = [[NSAttributedString alloc] initWithString:[value description] attributes:nil];
//                        [astr appendAttributedString:as];
//                    }
//                }
//                break;
                
//            case QTCmdLiteral:
                if ([pc->arg1 isKindOfClass:[NSAttributedString class]]) {
                   [astr appendAttributedString:pc->arg1];
                }
                else if (pc->arg1) {
                    as = [[NSAttributedString alloc] initWithString:[value description] attributes:nil];
                    [astr appendAttributedString:as];
                }
                break;
             
            case QTCmdStyle:
                if (pc->isEndTag) {
                    NSDictionary *props = [self.stylesheet valueForKey:pc->arg1];
                    [astr addAttributes:props range:range];
                }
                break;

            default:
                break;
        }
    }
    
    return astr;
}


@end

