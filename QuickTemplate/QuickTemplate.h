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
    <ifnot:cond>text that appears if cond evaluates to nil or NO or false</if>
 
*/


#import <Foundation/Foundation.h>

@interface QuickTemplate : NSObject

@property (strong, nonatomic) NSDictionary *stylesheet;
@property (strong, nonatomic) NSString *template;
@property (strong, nonatomic) NSArray *pcode;

- initWithString:(NSString*)template stylesheet:(NSDictionary*)stylesheet;

- (NSAttributedString*)attributedStringUsingRootValue:root;
- (NSMutableAttributedString*)inserAttributedStringUsingRootValue:root
                                             intoAttributedString:(NSMutableAttributedString*)astr
                                                               at:(NSInteger)pos;

@end
