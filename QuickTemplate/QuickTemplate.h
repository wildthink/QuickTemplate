//
//  QuickTemplate.h
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
 
    Values keypaths may also include a second parameter identifying an NSFormatter
    e.g.
    <v:birthday:DateFormatter/>
 
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
 
 show / omit are our conditional actions if / if (not ..) sort of thing
 
 show)
    <show:cond>text that appears if cond evaluates to non-nil</show>
 
 omit)
    <omit:cond>text that appears if cond evaluates to nil or NO or false</omit>
 
*/


#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
@import UIKit;
@compatibility_alias Image UIImage;
#else
//@import AppKit;
#import <AppKit/AppKit.h>
@compatibility_alias Image NSImage;
#endif

extern NSString* QTFormatterKey;
extern NSString* QTValueKeypath;

@interface QuickTemplate : NSObject

@property (strong, nonatomic) NSDictionary *stylesheet;
@property (strong, nonatomic) NSDictionary *alternateStylesheet;
@property (strong, nonatomic) NSString *template;
@property (strong, nonatomic) NSArray *pcode;

- initWithString:(NSString*)template stylesheet:(NSDictionary*)stylesheet;

- (NSAttributedString*)attributedStringUsingRootValue:root;
- (NSAttributedString*)attributedStringUsingRootValue:root alternateStylesheet:(NSDictionary*)alternateStyles;

- (NSMutableAttributedString*)appendToAttributedString:(NSMutableAttributedString*)astr usingRootValue:root;

- (NSDictionary*)textAttributesForKey:(NSString*)styleKey;
- (Image*)imageForKey:(NSString*)key;

@end
