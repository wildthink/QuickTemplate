//
//  NSXMLNode+TAL.h
//  WTTAL
//
//  Created by Jason Jobe on 10/29/05.
//  Copyright (c) 2005, 2013 Jason Jobe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TALContext;


@interface NSXMLDocument (TALExtensions)

- initWithContentsOfFile:(NSString*)filename;
- processTaggedAttributesWithPrefix:(NSString*)prefix context:context delegate:anObject;
- processTaggedAttributesWithPrefix:(NSString*)prefix context:context;

// Output
- (NSData*)XMLDataWithOptions:(unsigned int)options omitRoot:(BOOL)flag;
- (NSString *)XMLStringWithOptions:(unsigned int)options omitRoot:(BOOL)flag;

@end


@interface NSXMLElement  (TALExtensions)

+ (void)setDebugTaggedAttributeProcessing:(BOOL)flag;
- processTaggedAttributesWithPrefix:(NSString*)prefix context:context delegate:anObject;
- processTaggedAttributesWithPrefix:(NSString*)prefix context:context;

- (void)processTaggedAttributesWithTALContext:(TALContext*)context;

@end
