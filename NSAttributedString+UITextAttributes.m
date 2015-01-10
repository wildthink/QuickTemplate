//
//  NSAttributedString+UITextAttributes.m
//  QuickTemplate
//
//  Created by Jason Jobe on 9/29/13.
//  Copyright (c) 2013 Jason Jobe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSAttributedString+UITextAttributes.h"


@implementation NSAttributedString (UITextAttributes)

- (NSAttributedString*)attributedStringWithCurrentTextStyle
{
    NSMutableAttributedString *attributedString = [self mutableCopy];
    return [attributedString updateWithCurrentTextStyle];
}


@end

/// NSMutableString

@implementation NSMutableAttributedString (UITextAttributes)

- (NSAttributedString*)updateWithCurrentTextStyle
{
    NSRange range = NSMakeRange(0, self.length - 1);
    
    [self beginEditing];
    
    // Walk the string's attributes
    [self enumerateAttributesInRange:range options:NSAttributedStringEnumerationReverse usingBlock:
=======
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self  ];
    NSRange range = NSMakeRange(0, attributedString.length);
    
    // Walk the string's attributes
    [attributedString enumerateAttributesInRange:range options:0 usingBlock:
>>>>>>> 208854a9198b8b51cf53ba117a6d6ad8b6a717f7
     ^(NSDictionary *attributes, NSRange range, BOOL *stop) {
         
         // Find the font descriptor which is based on the old font size change
         NSMutableDictionary *mutableAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
         UIFont *font = mutableAttributes[@"NSFont"];
         UIFontDescriptor *fontDescriptor = font.fontDescriptor;
         
         // Get the text style and get a new font descriptor based on the style and update font size
         id styleAttribute = [fontDescriptor objectForKey:UIFontDescriptorTextStyleAttribute];
         UIFontDescriptor *newFontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:styleAttribute];
         
         // Get the new font from the new font descriptor and update the font attribute over the range
         UIFont *newFont = [UIFont fontWithDescriptor:newFontDescriptor size:0.0];
         [attributedString addAttribute:NSFontAttributeName value:newFont range:range];
     }];
    
    [self endEditing];
    return self;
}

@end


@implementation NSMutableAttributedString (UITextAttributes)

- (NSAttributedString*)attributedStringWithCurrentTextStyle;
{
    NSRange range = NSMakeRange(0, attributedString.length);

    // Walk the string's attributes
    [self enumerateAttributesInRange:range options:0 usingBlock:
     ^(NSDictionary *attributes, NSRange range, BOOL *stop) {
         UIFont *font = attributes[@"NSFont"];
         if (!font) {
             return;
         }
         // Find the font descriptor which is based on the old font size change
         NSMutableDictionary *mutableAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
         UIFontDescriptor *fontDescriptor = font.fontDescriptor;

         // Get the text style and get a new font descriptor based on the style and update font size
         id styleAttribute = [fontDescriptor objectForKey:UIFontDescriptorTextStyleAttribute];
         UIFontDescriptor *newFontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:styleAttribute];

         // Get the new font from the new font descriptor and update the font attribute over the range
         UIFont *newFont = [UIFont fontWithDescriptor:newFontDescriptor size:0.0];
         [self addAttribute:NSFontAttributeName value:newFont range:range];
     }];

    return self;
}

@end
