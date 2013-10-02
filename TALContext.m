//
//  TALContext.m
//  WTTAL
//
//  Created by Jason Jobe on 1/23/07.
//  Copyright (c) 2007, 2013 Jason Jobe. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TALContext.h"
#import "NSXMLNode+TAL.h"
#import "WTIterator.h"

//static NSString *TemplateMark = @"$";
static NSString *TemplateRepeatKey = @"for";


@implementation TALContext

- initWithValues:(NSDictionary*)vals;
{
	return [self initWithValues:vals prefix:@"tal"];
}

- initWithValues:(NSDictionary*)vals prefix:(NSString*)prefix;
{
	if (prefix == nil)
		prefix = @"tal";
	
	self.TAL_prefix = [[NSString alloc] initWithFormat:@"%@:", prefix];
	self.TAL_condition = [[NSString alloc] initWithFormat:@"%@:if", prefix];
	self.TAL_content = [[NSString alloc] initWithFormat:@"%@:content", prefix];
	self.TAL_replace = [[NSString alloc] initWithFormat:@"%@:replace", prefix];
	self.TAL_attributes = [[NSString alloc] initWithFormat:@"%@:attributes", prefix];
	self.TAL_omit = [[NSString alloc] initWithFormat:@"%@:omit-tag", prefix];
	self.TAL_include = [[NSString alloc] initWithFormat:@"%@:include", prefix];
	self.TAL_repeat = [[NSString alloc] initWithFormat:@"%@:%@", prefix, TemplateRepeatKey];
	
	_loops = [[NSMutableDictionary alloc] init];
	_defines = [[NSMutableDictionary alloc] init];
	_values = [vals mutableCopy];
    
	return self;
}


- (void)initiateLoop:(NSString*)name withArray:(NSArray*)anArray
{
	if ([_loops valueForKey:name]) {
		NSLog (@"TAL Loop ERROR: loop %@ already in use", name);
		return;
	}
	WTIterator *looper = [[WTIterator alloc] initWithArray:anArray];  
	[_loops setValue:looper forKey:name];
}

- nextObjectForLoop:(NSString*)name
{
	WTIterator *looper = [_loops valueForKey:name];
	id value = [looper nextObject];
	if (value) {
		[_values setValue:value forKey:name];
	} else {
		// clean up because we're DONE
		[_loops removeObjectForKey:name];
		[_values removeObjectForKey:name];
	}
	return value;
}

- valueForKeyPath:(NSString*)keypath
{
//	// having the mark indicates we have a template
//	NSRange range = [keypath rangeOfString:TemplateMark];
//	if (range.location != NSNotFound)
//		return [keypath stringWithTemplateValues:values];
//	else
		return [super valueForKeyPath:keypath];
}

- valueForKey:(NSString*)key;
{
	WTIterator *looper;
	id value;
	
	if ([key isEqualToString:TemplateRepeatKey]) {
		return _loops;
	} else if ((value = [_defines valueForKey:key])) {
		return value;
	} else if ((looper = [_loops valueForKey:key])) {
		return [looper currentObject];
	} else {
//		// having a mark indicates we have a template
//		NSRange range = [key rangeOfString:TemplateMark];
//		if (range.location != NSNotFound)
//			return [key stringWithTemplateValues:values];
//		// else
		return [_values valueForKey:key];
	}
}

-(NSString*)resourcePathForKey:(NSString*)key
{
//	// having the mark indicates we have a template
//	NSRange range = [key rangeOfString:TemplateMark];
//	if (range.location != NSNotFound)
//		return [key stringWithTemplateValues:values];
//	else
		return key;
}

- (NSXMLDocument*)loadContentsOfResource:(NSString*)key
{
	NSString *path = [self resourcePathForKey:key];
	NSXMLDocument *doc = [[NSXMLDocument alloc] initWithContentsOfFile:path];
	//  NSString *prefix = [[TAL_prefix componentsSeparatedByString:@":"] objectAtIndex:0];
	//  [doc processTaggedAttributesWithPrefix:prefix context:self];
	return doc;
}

// Template processing
-(NSXMLDocument*)documentUsingTemplate:(NSXMLDocument*)templateDoc
{
//	[templateDoc processTaggedAttributesWithPrefix:@"tal" context:self delegate:delegate];
	[[templateDoc rootElement] processTaggedAttributesWithTALContext:self];
	return templateDoc;
}

-(NSXMLDocument*)documentUsingTemplateURL:(NSURL*)url;
{
	NSXMLDocument *templateDoc;
	NSError *error;
	
	templateDoc = [[NSXMLDocument alloc]
				initWithContentsOfURL:url
							  options:(NSXMLDocumentTidyXML|NSXMLNodePrettyPrint) error:&error];
	
	return [self documentUsingTemplate:templateDoc];
}

-(NSXMLDocument*)documentUsingTemplateURL:(NSURL*)url withValue:value forKey:(NSString*)key 
{
	NSXMLDocument *doc;
	[_defines setValue:value forKey:key];
	doc = [self documentUsingTemplateURL:url];
	return doc;
}

@end

