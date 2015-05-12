//
//  LAFSimpleCommentsParserTests.m
//  AutoImporter
//
//  Created by Alexander Denisov on 12.05.15.
//  Copyright (c) 2015 luisfloreani.com. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "LAFSimpleCommentsParser.h"

@interface LAFSimpleCommentsParserTests : XCTestCase

@property(nonatomic, strong) LAFSimpleCommentsParser* parser;

@end

@implementation LAFSimpleCommentsParserTests

- (void)setUp {
    [super setUp];

    self.parser = [[LAFSimpleCommentsParser alloc] init];
}

- (void)testNoComments {
    NSString* source =
        @"                                  \n"
         "@interface Sample : NSObject      \n"
         "- (void)doIt;                     \n"
         "@end                              \n";
    NSString* expectedResult =
        @"                                  \n"
         "@interface Sample : NSObject      \n"
         "- (void)doIt;                     \n"
         "@end                              \n";
    NSString* result = [self.parser stripComments:source];
    XCTAssertEqualObjects(result, expectedResult);
}

- (void)testSingleLineComment {
    NSString* source =
        @"                                  \n"
         "// Sample class                   \n"
         "@interface Sample : NSObject      \n"
         "- (void)doIt;  // Sample method   \n"
         "@end                              \n";
    NSString* expectedResult =
        @"                                  \n"
         "\n"
         "@interface Sample : NSObject      \n"
         "- (void)doIt;  \n"
         "@end                              \n";
    NSString* result = [self.parser stripComments:source];
    XCTAssertEqualObjects(result, expectedResult);
}

- (void)testMultilineComment {
    NSString* source =
        @"                                  \n"
         "/* Sample class */                \n"
         "@interface Sample : NSObject      \n"
         "- (void)doIt;                     \n"
         "/*                                \n"
         "- (void)doIt2;                    \n"
         "*/                                \n"
         "@end                              \n";
    NSString* expectedResult =
        @"                                  \n"
         "                \n"
         "@interface Sample : NSObject      \n"
         "- (void)doIt;                     \n"
         "                                \n"
         "@end                              \n";
    NSString* result = [self.parser stripComments:source];
    XCTAssertEqualObjects(result, expectedResult);
}

- (void)testMixedNotIntersectingComments {
    NSString* source =
        @"// Comment here                   \n"
         "/* Sample class */  /* other */   \n"
         "@interface Sample : NSObject      \n"
         "- (void)doIt;   /* .. */  // ...  \n"
         "/*                                \n"
         "- (void)doIt2;                    \n"
         "*/                                \n"
         "@end                              \n";
    NSString* expectedResult =
        @"\n"
         "     \n"
         "@interface Sample : NSObject      \n"
         "- (void)doIt;     \n"
         "                                \n"
         "@end                              \n";
    NSString* result = [self.parser stripComments:source];
    XCTAssertEqualObjects(result, expectedResult);
}

- (void)testMixedIntersectingComments {
    NSString* source =
        @"// Comment here  /*               \n"
         "/* Sample class */ /* // other */ \n"
         "@interface Sample : NSObject      \n"
         "- (void)doIt;   /* .. */  // ...  \n"
         "/*                                \n"
         "- (void)doIt2;  // Commented out  \n"
         "*/                                \n"
         "@end                              \n";
    NSString* expectedResult =
        @"\n"
         "  \n"
         "@interface Sample : NSObject      \n"
         "- (void)doIt;     \n"
         "                                \n"
         "@end                              \n";
    NSString* result = [self.parser stripComments:source];
    XCTAssertEqualObjects(result, expectedResult);
}

@end
