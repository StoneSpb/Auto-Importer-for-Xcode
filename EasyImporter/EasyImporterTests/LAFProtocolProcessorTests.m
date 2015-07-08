//
//  LAFProtocolProcessorTests.m
//  AutoImporter
//
//  Created by Alexander Denisov on 09.05.15.
//  Copyright (c) 2015 luisfloreani.com. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "LAFIdentifier.h"
#import "LAFProtocolProcessor.h"

@interface LAFProtocolProcessorTests : XCTestCase

@property(nonatomic, strong) LAFProtocolProcessor* processor;

@end

@implementation LAFProtocolProcessorTests

- (void)setUp {
    [super setUp];

    self.processor = [[LAFProtocolProcessor alloc] init];
}

- (void)testProcessingProtocol {
    NSString* const kContent =
        @"// Comment here       \n"
         "@protocol MyProtocol  \n"
         "                      \n"
         "- (void)sampleMethod; \n"
         "                      \n"
         "@end                  \n"
         "                      \n"
         "// Comment here       \n";
    NSArray* elements = [self.processor createElements:kContent];
    LAFIdentifier* parsedElement = [elements firstObject];

    XCTAssertNotNil(parsedElement);
    XCTAssertEqualObjects(parsedElement.name, @"MyProtocol");
    XCTAssertEqual(parsedElement.type, LAFIdentifierTypeProtocol);
}

- (void)testProcessingProtocol_Multiline {
    NSString* const kContent =
        @"// Comment here       \n"
         "@protocol             \n"
         "    MyProtocol        \n"
         "                      \n"
         "- (void)sampleMethod; \n"
         "                      \n"
         "@end                  \n"
         "                      \n"
         "// Comment here       \n";
    NSArray* elements = [self.processor createElements:kContent];
    LAFIdentifier* parsedElement = [elements firstObject];

    XCTAssertNotNil(parsedElement);
    XCTAssertEqualObjects(parsedElement.name, @"MyProtocol");
    XCTAssertEqual(parsedElement.type, LAFIdentifierTypeProtocol);
}

- (void)testProcessingProtocolConformingToProtocol {
    NSString* const kContent =
        @"// Comment here                          \n"
         "@protocol MyProtocol <ProtocolToConform> \n"
         "                                         \n"
         "- (void)sampleMethod;                    \n"
         "                                         \n"
         "@end                                     \n"
         "                                         \n"
         "// Comment here                          \n";
    NSArray* elements = [self.processor createElements:kContent];
    LAFIdentifier* parsedElement = [elements firstObject];

    XCTAssertNotNil(parsedElement);
    XCTAssertEqualObjects(parsedElement.name, @"MyProtocol");
    XCTAssertEqual(parsedElement.type, LAFIdentifierTypeProtocol);
}

- (void)testProcessingProtocolConformingToProtocol_Multiline {
    NSString* const kContent =
        @"// Comment here             \n"
         "@protocol                   \n"
         "    MyProtocol              \n"
         "        <ProtocolToConform> \n"
         "                            \n"
         "- (void)sampleMethod;       \n"
         "                            \n"
         "@end                        \n"
         "                            \n"
         "// Comment here             \n";
    NSArray* elements = [self.processor createElements:kContent];
    LAFIdentifier* parsedElement = [elements firstObject];

    XCTAssertNotNil(parsedElement);
    XCTAssertEqualObjects(parsedElement.name, @"MyProtocol");
    XCTAssertEqual(parsedElement.type, LAFIdentifierTypeProtocol);
}

- (void)testProcessingProtocolForwardDeclaration {
    NSString* const kContent =
        @"// Comment here       \n"
         "@protocol MyProtocol; \n"
         "                      \n"
         "// Comment here       \n";
    NSArray* elements = [self.processor createElements:kContent];
    LAFIdentifier* parsedElement = [elements firstObject];

    XCTAssertNil(parsedElement);
}

- (void)testProcessingProtocolForwardDeclaration_Multiline {
    NSString* const kContent =
        @"// Comment here       \n"
         "@protocol             \n"
         "    MyProtocol;       \n"
         "                      \n"
         "// Comment here       \n";
    NSArray* elements = [self.processor createElements:kContent];
    LAFIdentifier* parsedElement = [elements firstObject];

    XCTAssertNil(parsedElement);
}

@end
