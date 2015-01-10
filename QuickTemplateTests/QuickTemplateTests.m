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


static NSString *imageURL = @"http://s3-media4.fl.yelpcdn.com/assets/2/www/img/c2f3dd9799a5/ico/stars/v1/stars_4.png";

@interface TestNameTransformer: NSValueTransformer {}
@end
@implementation TestNameTransformer
+ (Class)transformedValueClass { return [NSString class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)value {
    return [(NSString*)value lowercaseString];
//    return (value == nil) ? nil : NSStringFromClass([value class]);
}
@end

@interface QuickTemplateTests : XCTestCase

@property (strong, nonatomic) NSDictionary *stylesheet;
@property (strong, nonatomic) NSString *templateString;
@property NSDictionary *root;

@end

@implementation QuickTemplateTests

- (void)setUp
{
    [super setUp];
//    NSFontDescriptor *fontd = [NSFontDescriptor fontDescriptorWithName:<#(NSString *)#> size:0.0];
    self.stylesheet =
    @{
      @"heavy": @{ NSFontAttributeName: [NSFont boldSystemFontOfSize:12.0] },
      @"date_f": [NSDateFormatter new]
    };
    self.templateString = @"<s:heavy>Hello <v:name/></s:heavy>\nHow are <q:LT/><q>you</q><q:GT/> today?\n<a:http://apple.com>Apple</a>\nYou are <value:age/>";

    self.root = @{ @"name": @"George", @"age": @(23), @"birthdate": [NSDate date], @"children": @[@"Elroy", @"Jane"],
                   @"true": @YES, @"false": @NO, @"ratingImage": imageURL };
    
    TestNameTransformer *xformer = [TestNameTransformer new];
    [NSValueTransformer setValueTransformer:xformer forName:@"capitializer"];
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
    NSString *tmpl = @"Hi this is <show:false>here</show>not <omit:true>false</omit>";
    NSString *expected = @"Hi this is not ";
    QuickTemplate *qt = [[QuickTemplate alloc] initWithString:tmpl stylesheet:self.stylesheet];
    NSAttributedString *str = [qt attributedStringUsingRootValue:self.root];
    XCTAssertEqualObjects(expected, [str string], @"BAD");
    NSLog (@"string %@", [str string]);
}

- (void)testAnonymousClose
{
    NSString *tmpl = @"Hi this is <show:true>here</>";
    NSString *expected = @"Hi this is here";
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
    NSAttributedString *expected = [[NSAttributedString alloc] initWithString:@"heavyness" attributes:[self.stylesheet objectForKey:@"heavy"]];
    NSString *tmpl = @"<style:heavy>heavyness</style>";
    QuickTemplate *qt = [[QuickTemplate alloc] initWithString:tmpl stylesheet:self.stylesheet];
    NSAttributedString *str = [qt attributedStringUsingRootValue:self.root];
    XCTAssertEqualObjects(expected, str, @"BAD");
    NSLog (@"Styled: %@", expected);
}

- (void)testImage
{
//    NSAttributedString *expected = [[NSAttributedString alloc] initWithString:@"heavyness" attributes:[self.stylesheet objectForKey:@"heavy"]];
    NSString *tmpl = @"line 1\n<img:ratingImage/>\nline 3";
    QuickTemplate *qt = [[QuickTemplate alloc] initWithString:tmpl stylesheet:self.stylesheet];
    NSAttributedString *str = [qt attributedStringUsingRootValue:self.root];
//    XCTAssertEqualObjects(expected, str, @"BAD");
    NSLog (@"Styled: %@", str);
}

- (void)testTransformer
{
    NSString *expected = @"george"; // ALL lowercase
    NSString *tmpl = @"<v:name:capitializer/>";
    QuickTemplate *qt = [[QuickTemplate alloc] initWithString:tmpl stylesheet:self.stylesheet];
    NSAttributedString *str = [qt attributedStringUsingRootValue:self.root];
    XCTAssertEqualObjects(expected, [str string], @"BAD");
    NSLog (@"Formatted: %@", expected);
}

- (void)testFormatter
{
    NSString *expected = [self.root[@"birthdate"] description];
    NSString *tmpl = @"<v:birthdate:date_f/>";
    QuickTemplate *qt = [[QuickTemplate alloc] initWithString:tmpl stylesheet:self.stylesheet];
    NSAttributedString *str = [qt attributedStringUsingRootValue:self.root];
    XCTAssertEqualObjects(expected, [str string], @"BAD");
    NSLog (@"Formatted: %@", expected);
}


- (void)testParser
{
    QuickTemplate *qt = [[QuickTemplate alloc] initWithString:self.templateString stylesheet:self.stylesheet];
    NSLog (@"pcode: %@", qt.pcode);
//    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}


@end
