//
//  LAFIDESourceCodeEditorTests.m
//  AutoImporter
//
//  Created by Alexander Denisov on 05.05.15.
//  Copyright (c) 2015 luisfloreani.com. All rights reserved.
//

#import "LAFIDESourceCodeEditor.h"
#import "LAFIDESourceCodeEditor_Private.h"

#import <XCTest/XCTest.h>

#import "XCFXcodePrivate.h"

@interface FakeDVTSourceTextStorage : NSObject

@property(nonatomic, copy, readonly) NSString* string;

- (instancetype)initWithString:(NSString*)string;

@end

static DVTSourceTextStorage* SourceWithString(NSString* string) {
    return (DVTSourceTextStorage*)[[FakeDVTSourceTextStorage alloc] initWithString:string];
}


@interface LAFIDESourceCodeEditorTests : XCTestCase

@property(nonatomic, strong) LAFIDESourceCodeEditor* editor;
@property(nonatomic, copy) NSString* importStatement;

@end

@implementation LAFIDESourceCodeEditorTests

- (void)setUp {
    [super setUp];

    self.editor = [[LAFIDESourceCodeEditor alloc] init];
    self.importStatement = @"#import \"src/testFolder1/Header1.h\"";
}

- (void)tearDown {
    [super tearDown];
}

- (void)expecteForSourceCode:(NSString*)sourceCode
             appropriateLine:(NSUInteger)expectedLine
                 isDuplicate:(BOOL)expectDuplicate
  shouldCreateNewImportBlock:(BOOL)expectCreateNewImportBlock {
    DVTSourceTextStorage* sourceStorage = SourceWithString(sourceCode);
    BOOL isDuplicate = NO;
    BOOL shouldCreateNewImportBlock = NO;
    NSUInteger line = [self.editor appropriateLineInSource:sourceStorage
                                        forImportStatement:self.importStatement
                                               isDuplicate:&isDuplicate
                                shouldCreateNewImportBlock:&shouldCreateNewImportBlock];
    XCTAssertEqual(line, expectedLine);
    XCTAssertEqual(isDuplicate, expectDuplicate);
    XCTAssertEqual(shouldCreateNewImportBlock, expectCreateNewImportBlock);
}


- (void)testNoHeaders {
    NSString* code =
        @"// Comment here                         \n"
         "//                                      \n"
         "                                        \n"
         "@interface MyClass                      \n";
    [self expecteForSourceCode:code appropriateLine:3 isDuplicate:NO shouldCreateNewImportBlock:NO];
}

- (void)testHeaderExists_ShouldBePlacedAfter {
    NSString* code =
        @"// Comment here                         \n"
        "//                                       \n"
        "                                         \n"
        "#import \"src/aHeader.h\"                \n"
        "                                         \n"
        "@interface MyClass : NSObject            \n";
    [self expecteForSourceCode:code appropriateLine:4 isDuplicate:NO shouldCreateNewImportBlock:NO];
}

- (void)testHeaderExists_ShouldBePlacedBefore {
    NSString* code =
        @"// Comment here                         \n"
        "//                                       \n"
        "                                         \n"
        "#import \"src/testFolder2/Header1.h\"    \n"
        "                                         \n"
        "@interface MyClass : NSObject            \n";
    [self expecteForSourceCode:code appropriateLine:3 isDuplicate:NO shouldCreateNewImportBlock:NO];
}

- (void)testHeadersAreSorted_ShouldBePlacedAfter {
    NSString* code =
        @"// Comment here                         \n"
        "//                                       \n"
        "                                         \n"
        "#import \"src/aHeader.h\"                \n"
        "#import \"src/testFolder1/Header0.h\"    \n"
        "                                         \n"
        "@interface MyClass : NSObject            \n";
    [self expecteForSourceCode:code appropriateLine:5 isDuplicate:NO shouldCreateNewImportBlock:NO];
}

- (void)testHeadersAreSorted_ShouldBePlacedBetween {
    NSString* code =
        @"// Comment here                         \n"
        "//                                       \n"
        "                                         \n"
        "#import \"src/aHeader.h\"                \n"
        "#import \"src/testFolder2/Header0.h\"    \n"
        "                                         \n"
        "@interface MyClass : NSObject            \n";
    [self expecteForSourceCode:code appropriateLine:4 isDuplicate:NO shouldCreateNewImportBlock:NO];
}

- (void)testHeadersAreSorted_ShouldBePlacedBetween_CaseDoesNotMatter {
    NSString* code =
    @"// Comment here                         \n"
    "//                                       \n"
    "                                         \n"
    "#import \"src/aHeader1.h\"               \n"
    "#import \"src/aHeader2.h\"               \n"
    "#import \"src/TestFolder1/Header2.h\"    \n"
    "#import \"src/testFolder2/Header0.h\"    \n"
    "#import \"src/testFolder2/Header3.h\"    \n"
    "                                         \n"
    "@interface MyClass : NSObject            \n";
    [self expecteForSourceCode:code appropriateLine:5 isDuplicate:NO shouldCreateNewImportBlock:NO];
}

- (void)testHeadersAreNotSorted_ShouldBePlacedBetween {
    NSString* code =
        @"// Comment here                         \n"
        "//                                       \n"
        "                                         \n"
        "#import \"src/testFolder0/Header0.h\"    \n"
        "#import \"src/testFolder1/Header3.h\"    \n"
        "#import \"src/testFolder1/Header2.h\"    \n"
        "                                         \n"
        "@interface MyClass : NSObject            \n";
    [self expecteForSourceCode:code appropriateLine:4 isDuplicate:NO shouldCreateNewImportBlock:NO];
}

- (void)testFrameworkHeadersExist_ShouldBePlacedInANewSection {
    NSString* code =
        @"// Comment here                         \n"
        "//                                       \n"
        "                                         \n"
        "#import <Foundation/Foundation.h>        \n"
        "                                         \n"
        "@interface MyClass : NSObject            \n";
    [self expecteForSourceCode:code appropriateLine:4 isDuplicate:NO shouldCreateNewImportBlock:YES];
}

- (void)testFrameworkHeadersExistWithOtherSources_ShouldBePlacedAfter {
    NSString* code =
        @"// Comment here                         \n"
        "//                                       \n"
        "                                         \n"
        "#import <Foundation/Foundation.h>        \n"
        "                                         \n"
        "#import \"src/aHeader.h\"                \n"
        "                                         \n"
        "@interface MyClass : NSObject            \n";
    [self expecteForSourceCode:code appropriateLine:6 isDuplicate:NO shouldCreateNewImportBlock:NO];
}

- (void)testFrameworkHeadersExistWithOtherSources_ShouldBePlacedInANewSection {
    NSString* code =
        @"// Comment here                         \n"
        "//                                       \n"
        "                                         \n"
        "#import <Foundation/Foundation.h>        \n"
        "#import \"src/aHeader.h\"                \n"
        "                                         \n"
        "@interface MyClass : NSObject            \n";
    [self expecteForSourceCode:code appropriateLine:5 isDuplicate:NO shouldCreateNewImportBlock:YES];
}

- (void)testHeaderExists_ShouldReturnNSNotFoundAndMarkAsDuplicate {
    NSString* code =
        @"// Comment here                         \n"
        "//                                       \n"
        "                                         \n"
        "#import <Foundation/Foundation.h>        \n"
        "#import \"src/testFolder1/Header1.h\"    \n"
        "                                         \n"
        "@interface MyClass : NSObject            \n";
    [self expecteForSourceCode:code appropriateLine:NSNotFound isDuplicate:YES shouldCreateNewImportBlock:NO];
}

- (void)testHeadersAreSorted_HasSeveralBlocks_ShouldBePlacedAfter {
    NSString* code =
        @"// Comment here                         \n"
        "//                                       \n"
        "                                         \n"
        "#import \"src/zClassHeader.h\"           \n"
        "                                         \n"
        "#import <Foundation/Foundation.h>        \n"
        "                                         \n"
        "#import \"src/aHeader.h\"                \n"
        "#import \"src/testFolder1/Header0.h\"    \n"
        "                                         \n"
        "@interface MyClass : NSObject            \n";
    [self expecteForSourceCode:code appropriateLine:9 isDuplicate:NO shouldCreateNewImportBlock:NO];
}

- (void)testIsNotFrameworkImport {
    BOOL isFrameworkImport = [self.editor isFrameworkImportString:@"#import \"Foundation.h\""];
    XCTAssertFalse(isFrameworkImport);
}

- (void)testIsFrameworkImport {
    BOOL isFrameworkImport = [self.editor isFrameworkImportString:@"#import <Foundation/Foundation.h>"];
    XCTAssertTrue(isFrameworkImport);
}

- (void)testIsFrameworkInclude {
    BOOL isFrameworkImport = [self.editor isFrameworkImportString:@"#include <iostream>"];
    XCTAssertTrue(isFrameworkImport);
}

@end

@implementation FakeDVTSourceTextStorage

- (instancetype)initWithString:(NSString*)string {
    self = [super init];
    if (self) {
        _string = string;
    }
    return self;
}

@end
