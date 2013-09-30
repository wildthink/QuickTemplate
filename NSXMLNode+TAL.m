//
//  NSXMLNode+TAL.m
//  WTTAL
//
//  Created by Jason Jobe on 10/29/05.
//  Copyright (c) 2005, 2013 Jason Jobe. All rights reserved.
//

#import "NSXMLNode+TAL.h"
#import "TALContext.h"
#import "WTIterator.h"


static BOOL g_tal_debug = NO;


@interface NSObject (TALContextDelegate)
-(NSXMLElement*)processTaggedAttribute:(NSXMLNode*)node
                         forElement:(NSXMLElement*)element inTALContext:(TALContext*)context;
@end



@implementation NSXMLElement (TALExtensions)

+(void)setDebugTaggedAttributeProcessing:(BOOL)flag
{
  g_tal_debug = flag;
}


- (NSDictionary*)parseTALAttributes:(NSString*)str
{
  NSMutableDictionary *attr = [[NSMutableDictionary alloc] init];
  NSScanner *scanner = [[NSScanner alloc] initWithString:str];
  NSString *key, *value;
  NSCharacterSet *space = [NSCharacterSet whitespaceCharacterSet];
  
  while (! [scanner isAtEnd]) {
    [scanner scanUpToCharactersFromSet:space intoString:&key];
    [scanner scanUpToString:@";" intoString:&value];
    [scanner scanString:@";" intoString:NULL];
    if (value && key)
      [attr setValue:value forKey:key];
  }
  
  return attr;
}

-(void)processTaggedAttributesWithTALContext:(TALContext*)context
                                     forEach:(NSString*)ident inArray:(NSArray*)values
{
  // remove tal:repeat to avoid infinite loop
  [self removeAttributeForName:context->TAL_repeat];
  NSXMLElement *parent = (NSXMLElement*)[self parent]; // get it before we detach
  [self detach];
    
  [context initiateLoop:ident withArray:values];
  
  while ([context nextObjectForLoop:ident]) {
    id nodeCopy = [self copy];
    [parent addChild:nodeCopy];
    [nodeCopy processTaggedAttributesWithTALContext:context];
  }
}

- processTaggedAttributesWithPrefix:(NSString*)prefix context:context
{
  return [self processTaggedAttributesWithPrefix:prefix context:context delegate:nil];
}

- processTaggedAttributesWithPrefix:(NSString*)prefix context:context delegate:anObject;
{
  TALContext *tc = [[TALContext alloc] initWithValues:context prefix:prefix];
  [tc setDelegate:anObject];
  [self processTaggedAttributesWithTALContext:tc];
  [tc release];
  return self;
}

- (void)processTaggedAttributesWithTALContext:(TALContext*)context;
{
  NSString *talCommand;
  id value;
  
  if (talCommand = [[self attributeForName:context->TAL_condition] stringValue]) {
    if ([talCommand length]) {
      value = [context valueForKeyPath:talCommand];
    } else {
      value = @"0";
    }
    if ([value intValue] == 0)
      [self detach];
    
    if (![context debug]) [self removeAttributeForName:context->TAL_condition];
  }
  
  if (talCommand = [[self attributeForName:context->TAL_repeat] stringValue]) {
    NSArray *array = [talCommand componentsSeparatedByString:@" "];
    value = [context valueForKeyPath:[array objectAtIndex:1]];
    [self processTaggedAttributesWithTALContext:(TALContext*)context forEach:[array objectAtIndex:0] inArray:value];
    return;
  }
    
  if (talCommand = [[self attributeForName:context->TAL_replace] stringValue]) {
    if (value = [context valueForKeyPath:talCommand]) {
      NSXMLElement *parent = (NSXMLElement*)[self parent];
      unsigned myIndex = [self index]; // [[parent children] indexOfObject:self];
      NSXMLNode *node = [[NSXMLNode alloc] initWithKind:NSXMLTextKind];
	  // node = [NSXMLNode textWithStringValue:value];
      //[node setStringValue:value];
	  [node setObjectValue:value]; // treats value as a literal
      [parent replaceChildAtIndex:myIndex withNode:node];
	  [node release];
    }
    return;
  }
  
  if (talCommand = [[self attributeForName:context->TAL_content] stringValue]) {
    value = [context valueForKeyPath:talCommand];
    [self setStringValue:value resolvingEntities:NO];
    if (![context debug]) [self removeAttributeForName:context->TAL_content];
  }
/*  
  if (talCommand = [[self attributeForName:context->TAL_cdata] stringValue]) {
    value = [context valueForKeyPath:talCommand];
    [self set
    [self setStringValue:value resolvingEntities:YES];
    if (![context debug]) [self removeAttributeForName:context->TAL_content];
  }
*/
  if (talCommand = [[self attributeForName:context->TAL_include] stringValue]) {
    NSXMLDocument *doc = [context loadContentsOfResource:talCommand];
    NSXMLElement *parent = (NSXMLElement*)[self parent];
    unsigned myIndex = [self index]; // [[parent children] indexOfObject:self];
    NSXMLElement *node = [doc rootElement];
    [node detach];
    [parent replaceChildAtIndex:myIndex withNode:node];
    [node processTaggedAttributesWithTALContext:context];
    return;
  }
  
  if ((talCommand = [[self attributeForName:context->TAL_attributes] stringValue]) && [talCommand length])
  {
    NSDictionary *attr = [self parseTALAttributes:talCommand];
    NSEnumerator *keyCurs = [attr keyEnumerator];
    NSString *key;
    
    while (key = [keyCurs nextObject]) {
      value = [context valueForKeyPath:[attr valueForKey:key]];
      NSXMLNode *attribute = [NSXMLNode attributeWithName:key stringValue:value];
      [self removeAttributeForName:key];
      [self addAttribute:attribute];
    }
           
    if (![context debug]) [self removeAttributeForName:context->TAL_attributes];
  }
  
  if (talCommand = [[self attributeForName:context->TAL_omit] stringValue]) {
    if ([talCommand length]) {
      value = [context valueForKeyPath:talCommand];
    } else {
      value = @"1";
    }
    if ([value intValue] == 1) {
      id parent = [self parent];
      unsigned ndx = [self index]; // [[parent children] indexOfObject:self];
      [self detach];
      NSEnumerator *curs = [[self children] objectEnumerator];
      NSXMLElement *node;
      while (node = [curs nextObject]) {
        [node detach];
        [parent insertChild:node atIndex:ndx];
        ++ndx;
      }
    }
    if (![context debug]) [self removeAttributeForName:context->TAL_omit];
  }
  
  if (context->delegate) {
    NSEnumerator *attrCurs = [[self attributes] objectEnumerator];
    NSXMLElement *node;
    
    while (node = [attrCurs nextObject]) {
      if ([[node name] hasPrefix:context->TAL_prefix])
        node = [context->delegate processTaggedAttribute:node forElement:self inTALContext:context];
    }
  }
  
  NSEnumerator *childCurs = [[self children] objectEnumerator];
  NSXMLElement *node;
  
  while (node = [childCurs nextObject]) {
    if ([node respondsToSelector:@selector(processTaggedAttributesWithTALContext:)])
      [node processTaggedAttributesWithTALContext:context];
  }
}

@end


@implementation NSXMLDocument (TALExtensions)

- initWithContentsOfFile:(NSString*)filename
{
  NSURL *url = [NSURL fileURLWithPath:filename];
  NSError *error;
  
  self = [[[self class] alloc]
            initWithContentsOfURL:url
                          options:(NSXMLDocumentTidyXML|NSXMLNodePrettyPrint)
                            error:&error];

  if (error) {
    NSLog (@"ERROR: [NSXMLDocument initWithContentsOfFile:%@] => %@", filename, error);
  }
  
  return self;
}

- processTaggedAttributesWithPrefix:(NSString*)prefix context:context
{
  return [self processTaggedAttributesWithPrefix:prefix context:context delegate:nil];
}

- processTaggedAttributesWithPrefix:(NSString*)prefix context:context delegate:anObject;
{
  [[self rootElement] processTaggedAttributesWithPrefix:prefix context:context delegate:anObject];
  return self;
}

// Output
- (NSData*)XMLDataWithOptions:(unsigned int)options omitRoot:(BOOL)omitRoot;
{
  if (omitRoot) {
    NSString *xmlStr = [self XMLStringWithOptions:options omitRoot:omitRoot];
    NSData *data = [xmlStr dataUsingEncoding:NSASCIIStringEncoding];
    return data;
  }
  else {
    return [self XMLDataWithOptions:options];
  }
}

- (NSString *)XMLStringWithOptions:(unsigned int)options omitRoot:(BOOL)omitRoot;
{
  if (omitRoot) {
    NSMutableString *xmlStr = [NSMutableString string];
    NSEnumerator *curs = [[[self rootElement] children] objectEnumerator];
    NSXMLNode *node;
    
    while (node = [curs nextObject]) {
      [xmlStr appendString:[node XMLStringWithOptions:options]];
      [xmlStr appendString:@"\n"];
    }
    
    return xmlStr;
  }
  else {
    return [[self rootElement] XMLStringWithOptions:options];
  }
}

@end
