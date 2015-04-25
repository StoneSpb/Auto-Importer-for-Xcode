//
//  AutoImporterTests.m
//  AutoImporterTests
//
//  Created by Luis Floreani on 9/15/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LAFProjectHeaderCache.h"
#import "LAFTestCase.h"
#import "LAFIdentifier.h"

static LAFIdentifier * LAFHeaderWithName(NSString *name) {
    LAFIdentifier *identifier = [[LAFIdentifier alloc] initWithName:name];
    identifier.type = LAFIdentifierTypeHeader;
    return identifier;
}

@interface LAFProjectHeaderCacheTests : LAFTestCase
@property (nonatomic, strong) NSString *projectPath;
@end

@implementation LAFProjectHeaderCacheTests

- (void)setUp
{
    [super setUp];
    
    NSString *curDir = [[NSFileManager defaultManager] currentDirectoryPath];
    _projectPath = [curDir stringByAppendingPathComponent:@"/../TestProjects/AutoImporterTestProject1/AutoImporterTestProject1.xcodeproj"];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testClassesAreImported {
    dispatch_group_enter(self.requestGroup);

    LAFProjectHeaderCache *headers = [[LAFProjectHeaderCache alloc] initWithProjectPath:_projectPath];
    [headers refreshWithCompletion:^{
        XCTAssertEqualObjects([headers headerForIdentifier:@"LAFMyClass1"],
                              LAFHeaderWithName(@"LAFMyClass1.h"));
        XCTAssertEqualObjects([headers headerForIdentifier:@"LAFMyClass_1"],
                              LAFHeaderWithName(@"LAFMyClass1.h"));
        XCTAssertEqualObjects([headers headerForIdentifier:@"LAFMyClass2"],
                              LAFHeaderWithName(@"LAFMyClass2.h"));
        XCTAssertEqualObjects([headers headerForIdentifier:@"LAFMyClass2Bis"],
                              LAFHeaderWithName(@"LAFMyClass2.h"));
        XCTAssertEqualObjects([headers headerForIdentifier:@"LAFMyProtocol1"],
                              LAFHeaderWithName(@"LAFMyClass1.h"));
        XCTAssertNil([headers headerForIdentifier:@"NSColor"]);
        
        dispatch_group_leave(self.requestGroup);
    }];
}

- (void)testCategoryMethodsAreImported {
    dispatch_group_enter(self.requestGroup);
    
    LAFProjectHeaderCache *headers = [[LAFProjectHeaderCache alloc] initWithProjectPath:_projectPath];
    [headers refreshWithCompletion:^{
        XCTAssertEqualObjects([headers headerForIdentifier:@"laf_redColor;"],
                              LAFHeaderWithName(@"NSColor+MyColor.h"));
        XCTAssertEqualObjects([headers headerForIdentifier:@"laf_greenColor;"],
                              LAFHeaderWithName(@"NSColor+MyColor.h"));
        XCTAssertEqualObjects([headers headerForIdentifier:@"laf_filterColor:"],
                              LAFHeaderWithName(@"NSColor+MyColor.h"));
        XCTAssertEqualObjects([headers headerForIdentifier:@"laf_filterColor:offset:"],
                              LAFHeaderWithName(@"NSColor+MyColor.h"));
        XCTAssertEqualObjects([headers headerForIdentifier:@"laf_filterColor2:offset:"],
                              LAFHeaderWithName(@"NSColor+MyColor.h"));
        XCTAssertEqualObjects([headers headerForIdentifier:@"laf_filterColor3:offset:"],
                              LAFHeaderWithName(@"NSColor+MyColor.h"));
        
        dispatch_group_leave(self.requestGroup);
    }];
}

- (void)testGroupClassIsImported
{
    dispatch_group_enter(self.requestGroup);

    LAFProjectHeaderCache *headers = [[LAFProjectHeaderCache alloc] initWithProjectPath:_projectPath];
    [headers refreshWithCompletion:^{
        XCTAssertEqualObjects([headers headerForIdentifier:@"LAFGroupClass1"],
                              LAFHeaderWithName(@"LAFGroupClass1.h"));
        
        dispatch_group_leave(self.requestGroup);
    }];
}

- (void)testSubdirectoryClassIsImported
{
    dispatch_group_enter(self.requestGroup);

    LAFProjectHeaderCache *headers = [[LAFProjectHeaderCache alloc] initWithProjectPath:_projectPath];
    [headers refreshWithCompletion:^{
        XCTAssertEqualObjects([headers headerForIdentifier:@"LAFSubdirectoryClass1"],
                              LAFHeaderWithName(@"LAFSubdirectoryClass1.h"));
        
        dispatch_group_leave(self.requestGroup);
    }];
}

- (void)testHeaders
{
    dispatch_group_enter(self.requestGroup);
    
    LAFProjectHeaderCache *headers = [[LAFProjectHeaderCache alloc] initWithProjectPath:_projectPath];
    [headers refreshWithCompletion:^{
        XCTAssertTrue([[headers headers] containsObject:[[LAFIdentifier alloc] initWithName:@"LAFMyClass1.h"]]);
        XCTAssertTrue([[headers headers] containsObject:[[LAFIdentifier alloc] initWithName:@"LAFMyClass2.h"]]);
        XCTAssertTrue([[headers headers] containsObject:[[LAFIdentifier alloc] initWithName:@"NSColor+MyColor.h"]]);
        XCTAssertTrue([[headers headers] containsObject:[[LAFIdentifier alloc] initWithName:@"LAFSubdirectoryClass1.h"]]);
        XCTAssertTrue([[headers headers] containsObject:[[LAFIdentifier alloc] initWithName:@"LAFAppDelegate.h"]]);
        
        dispatch_group_leave(self.requestGroup);
    }];
}

- (void)testHeaderChanged
{
    dispatch_group_enter(self.requestGroup);
    
    LAFProjectHeaderCache *headersCache = [[LAFProjectHeaderCache alloc] initWithProjectPath:_projectPath];
    [headersCache refreshWithCompletion:^{
        XCTAssertNil([headersCache headerForIdentifier:@"LAFMyClass2BisBis"]);
        
        NSString *headerPath = [[_projectPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"AutoImporterTestProject1/LAFMyClass2.h"];
        
        NSString *content = [NSString stringWithContentsOfFile:headerPath encoding:NSUTF8StringEncoding error:nil];
        
        NSString *newContent = [content stringByAppendingString:@"\n@interface LAFMyClass2BisBis : NSObject\n\n@end"];
        
        // replace file
        [newContent writeToFile:headerPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        [headersCache refreshHeaderWithPath:headerPath];
        
        XCTAssertEqualObjects([headersCache headerForIdentifier:@"LAFMyClass2BisBis"],
                              LAFHeaderWithName(@"LAFMyClass2.h"));
        
        // restore file
        [content writeToFile:headerPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        dispatch_group_leave(self.requestGroup);
    }];
    
}

@end
