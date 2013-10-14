//
//  NSAttributedString+UITextAttributes.h
//  QuickTemplate
//
//  Created by Jason Jobe on 9/29/13.
//  Copyright (c) 2013 Jason Jobe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (UITextAttributes)

- (NSAttributedString*)attributedStringWithCurrentTextStyle;

@end

@interface NSMutableAttributedString (UITextAttributes)

- (NSAttributedString*)updateWithCurrentTextStyle;

@end