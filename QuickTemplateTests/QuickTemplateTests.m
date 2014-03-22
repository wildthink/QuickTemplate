//
//  QuickTemplateTests.m
//  QuickTemplateTests
//
//  Created by Jason Jobe on 9/21/13.
//  Copyright (c) 2013 Jason Jobe. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "QuickTemplate.h"
#import "NSAttributedString+UITextAttributes.h"


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
    self.templateString = @"<s:bold>Hello <v:name/></s:bold>\nHow are <q:LT/><q>you</q><q:GT/> today?\n<a:http://apple.com>Apple</a>\nYou are <value:age/>";

    self.root = @{ @"name": @"George", @"age": @(23), @"children": @[@"Elroy", @"Jane"],
                   @"true": @YES, @"false": @NO };
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testIfConstructs
{
    NSString *tmpl = @"Hi this is <show:true>here</show> not <omit:false>false</omit>";
    NSString *expected = @"Hi this is here not false";
    QuickTemplate *qt = [[QuickTemplate alloc] initWithString:tmpl stylesheet:self.stylesheet];
    NSAttributedString *str = [qt attributedStringUsingRootValue:self.root];
    XCTAssertEqualObjects(expected, [str string], @"BAD");
    NSLog (@"string %@", [str string]);
}

- (void)testNotIfConstructs
{
    NSString *tmpl = @"Hi this is <show:false>here </show>not <omit:true>false</omit>";
    NSString *expected = @"Hi this is not ";
    QuickTemplate *qt = [[QuickTemplate alloc] initWithString:tmpl stylesheet:self.stylesheet];
    NSAttributedString *str = [qt attributedStringUsingRootValue:self.root];
    XCTAssertEqualObjects(expected, [str string], @"BAD");
    NSLog (@"string %@", [str string]);
}

- (void)testTemplateEval
{
    QuickTemplate *qt = [[QuickTemplate alloc] initWithString:self.templateString stylesheet:self.stylesheet];
    NSAttributedString *str = [qt attributedStringUsingRootValue:self.root];
    NSLog (@"styled: %@", str);

}

- (void)testTemplateVariables
{
    QuickTemplate *qt = [[QuickTemplate alloc] initWithString:self.templateString stylesheet:self.stylesheet];
    NSAttributedString *str = [qt attributedStringUsingRootValue:self.root];

    NSLog (@"styled: %@", str);

    NSSet *variables = [str quickTemplateVariables];
    NSLog (@"Variables: %@", variables);

    str = [str attributedStringWithUpdatedValues:@{@"name": @"Spacely", @"age": @45}];
    NSLog (@"String: %@", str);
}

- (void)testStyles
{
    NSAttributedString *expected = [[NSAttributedString alloc] initWithString:@"Boldness" attributes:[self.stylesheet objectForKey:@"bold"]];
    NSString *tmpl = @"<style:bold>Boldness</style>";
    QuickTemplate *qt = [[QuickTemplate alloc] initWithString:tmpl stylesheet:self.stylesheet];
    NSAttributedString *str = [qt attributedStringUsingRootValue:self.root];
    XCTAssertEqualObjects(expected, str, @"BAD");
    NSLog (@"Styled: %@", expected);
}

- (void)testParser
{
    QuickTemplate *qt = [[QuickTemplate alloc] initWithString:self.templateString stylesheet:self.stylesheet];
    NSLog (@"pcode: %@", qt.pcode);
//    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}


@end
