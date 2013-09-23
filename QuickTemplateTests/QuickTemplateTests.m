//
//  QuickTemplateTests.m
//  QuickTemplateTests
//
//  Created by Jason Jobe on 9/21/13.
//  Copyright (c) 2013 Jason Jobe. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "QuickTemplate.h"

@interface QuickTemplateTests : XCTestCase

@property (strong, nonatomic) NSDictionary *stylesheet;
@property (strong, nonatomic) NSString *templateString;
@property NSDictionary *root;

@end

@implementation QuickTemplateTests

- (void)setUp
{
    [super setUp];
    self.stylesheet =
    @{
        @"bold": @{ NSFontAttributeName: [NSFont boldSystemFontOfSize:12.0] }
    };
    self.templateString = @"<s:bold>Hello <v:name/></s:bold>\nHow are <q:LT/><q>you</q><q:GT/> today?";

    self.root = @{ @"name": @"George", @"age": @(23), @"children": @[@"Leroy", @"Jane"] };
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testTemplateEval
{
    QuickTemplate *qt = [[QuickTemplate alloc] initWithString:self.templateString stylesheet:self.stylesheet];
    NSAttributedString *str = [qt attributedStringUsingRootValue:self.root];
    NSLog (@"pcode: %@", str);

}

- (void)testStyles
{
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:@"Boldness" attributes:[self.stylesheet objectForKey:@"bold"]];
    NSLog (@"Styled: %@", as);
}

- (void)testParser
{
    QuickTemplate *qt = [[QuickTemplate alloc] initWithString:self.templateString stylesheet:self.stylesheet];
    NSLog (@"pcode: %@", qt.pcode);
//    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
