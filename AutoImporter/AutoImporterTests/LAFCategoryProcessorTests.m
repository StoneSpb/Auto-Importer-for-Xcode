//
//  LAFCategoryProcessorTests.m
//  AutoImporter
//
//  Created by Alexander Denisov on 09.05.15.
//  Copyright (c) 2015 luisfloreani.com. All rights reserved.
//

#import "LAFCategoryProcessor.h"

#import <XCTest/XCTest.h>

#import "LAFIdentifier.h"
#import "LAFSimpleCommentsParser.h"

@interface LAFCategoryProcessorTests : XCTestCase

@property(nonatomic, strong) LAFCategoryProcessor* processor;
@property(nonatomic, strong) LAFSimpleCommentsParser* commentsParser;

@end

@implementation LAFCategoryProcessorTests

- (void)setUp {
    [super setUp];

    self.processor = [[LAFCategoryProcessor alloc] init];
    self.commentsParser = [[LAFSimpleCommentsParser alloc] init];
}

- (NSArray*)createElements:(NSString*)content {
    content = [self.commentsParser stripComments:content];
    return [self.processor createElements:content];
}

- (void)testProcessingCategory {
    NSString* const kContent =
        @"// Comment here               \n"
         "@interface MyClass (Category) \n"
         "                              \n"
         " - (void)sampleMethod;        \n"
         "                              \n"
         "@end                          \n"
         "                              \n"
         "// Comment here               \n";
    NSArray* elements = [self createElements:kContent];
    LAFIdentifier* parsedElement = [elements firstObject];

    XCTAssertNotNil(parsedElement);
    XCTAssertEqual(elements.count, 1);
    XCTAssertEqualObjects(parsedElement.name, @"sampleMethod");
    XCTAssertEqual(parsedElement.type, LAFIdentifierTypeCategory);
    XCTAssertEqualObjects(parsedElement.customTypeString, @"MyClass");
}

- (void)testProcessingCategory_Whitespaces {
    NSString* const kContent =
        @"// Comment here                 \n"
         "@interface MyClass ( Category ) \n"
         "                                \n"
         " - (void)sampleMethod;          \n"
         "                                \n"
         "@end                            \n"
         "                                \n"
         "// Comment here                 \n";
    NSArray* elements = [self createElements:kContent];
    LAFIdentifier* parsedElement = [elements firstObject];

    XCTAssertNotNil(parsedElement);
    XCTAssertEqual(elements.count, 1);
    XCTAssertEqualObjects(parsedElement.name, @"sampleMethod");
    XCTAssertEqual(parsedElement.type, LAFIdentifierTypeCategory);
    XCTAssertEqualObjects(parsedElement.customTypeString, @"MyClass");
}

- (void)testProcessingCategory_Multiline {
    NSString* const kContent =
        @"// Comment here        \n"
         "@interface             \n"
         "    MyClass            \n"
         "        (Category)     \n"
         "                       \n"
         " - (void)sampleMethod; \n"
         "                       \n"
         "@end                   \n"
         "                       \n"
         "// Comment here        \n";
    NSArray* elements = [self createElements:kContent];
    LAFIdentifier* parsedElement = [elements firstObject];

    XCTAssertNotNil(parsedElement);
    XCTAssertEqual(elements.count, 1);
    XCTAssertEqualObjects(parsedElement.name, @"sampleMethod");
    XCTAssertEqual(parsedElement.type, LAFIdentifierTypeCategory);
    XCTAssertEqualObjects(parsedElement.customTypeString, @"MyClass");
}

- (void)testProcessingExtension {
    NSString* const kContent =
        @"// Comment here               \n"
         "@interface MyClass ()         \n"
         "                              \n"
         " - (void)sampleMethod;        \n"
         "                              \n"
         "@end                          \n"
         "                              \n"
         "// Comment here               \n";
    NSArray* elements = [self createElements:kContent];
    LAFIdentifier* parsedElement = [elements firstObject];

    XCTAssertNil(parsedElement);
}

- (void)testProcessingExtension_Multiline {
    NSString* const kContent =
        @"// Comment here        \n"
         "@interface             \n"
         "    MyClass            \n"
         "        ()             \n"
         "                       \n"
         " - (void)sampleMethod; \n"
         "                       \n"
         "@end                   \n"
         "                       \n"
         "// Comment here        \n";
    NSArray* elements = [self createElements:kContent];
    LAFIdentifier* parsedElement = [elements firstObject];

    XCTAssertNil(parsedElement);
}

- (void)testProcessingExtension_Whitespaces {
    NSString* const kContent =
        @"// Comment here               \n"
         "@interface MyClass ( )         \n"
         "                              \n"
         " - (void)sampleMethod;        \n"
         "                              \n"
         "@end                          \n"
         "                              \n"
         "// Comment here               \n";
    NSArray* elements = [self createElements:kContent];
    LAFIdentifier* parsedElement = [elements firstObject];

    XCTAssertNil(parsedElement);
}

- (void)testProcessingCategory_MultipleArguments {
    NSString* const kContent =
        @"// Comment here                                     \n"
         "@interface MyClass (Category)                       \n"
         "                                                    \n"
         " - (void)sampleMethodWithBool:(BOOL)bool id:(id)id; \n"
         "                                                    \n"
         "@end                                                \n"
         "                                                    \n"
         "// Comment here                                     \n";
    NSArray* elements = [self createElements:kContent];
    LAFIdentifier* parsedElement = [elements firstObject];

    XCTAssertNotNil(parsedElement);
    XCTAssertEqual(elements.count, 1);
    XCTAssertEqualObjects(parsedElement.name, @"sampleMethodWithBool:id:");
    XCTAssertEqual(parsedElement.type, LAFIdentifierTypeCategory);
    XCTAssertEqualObjects(parsedElement.customTypeString, @"MyClass");
}

- (void)testProcessingCategory_MultipleArguments_Multiline {
    NSString* const kContent =
        @"// Comment here                                     \n"
         "@interface MyClass (Category)                       \n"
         "                                                    \n"
         " - (void)sampleMethodWithBool:(BOOL)bool            \n"
         "                                                    \n"
         "                           id:(id)id;               \n"
         "                                                    \n"
         "@end                                                \n"
         "                                                    \n"
         "// Comment here                                     \n";
    NSArray* elements = [self createElements:kContent];
    LAFIdentifier* parsedElement = [elements firstObject];

    XCTAssertNotNil(parsedElement);
    XCTAssertEqual(elements.count, 1);
    XCTAssertEqualObjects(parsedElement.name, @"sampleMethodWithBool:id:");
    XCTAssertEqual(parsedElement.type, LAFIdentifierTypeCategory);
    XCTAssertEqualObjects(parsedElement.customTypeString, @"MyClass");
}

- (void)testProcessingCategory_MultipleArguments_Multiline_Comment {
    NSString* const kContent =
        @"// Comment here                                     \n"
         "@interface MyClass (Category)                       \n"
         "                                                    \n"
         " // TODO:                                           \n"
         " - (void)sampleMethodWithBool:(BOOL)bool            \n"
         "                                                    \n"
         "                           id:(id)id;               \n"
         "                                                    \n"
         "@end                                                \n"
         "                                                    \n"
         "// Comment here                                     \n";
    NSArray* elements = [self createElements:kContent];
    LAFIdentifier* parsedElement = [elements firstObject];

    XCTAssertNotNil(parsedElement);
    XCTAssertEqual(elements.count, 1);
    XCTAssertEqualObjects(parsedElement.name, @"sampleMethodWithBool:id:");
    XCTAssertEqual(parsedElement.type, LAFIdentifierTypeCategory);
    XCTAssertEqualObjects(parsedElement.customTypeString, @"MyClass");
}

@end
