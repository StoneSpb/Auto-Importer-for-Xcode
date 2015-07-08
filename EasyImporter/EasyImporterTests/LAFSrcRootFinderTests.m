//
//  LAFSrcRootFinderTests.m
//  AutoImporter
//
//  Created by Alexander Denisov on 03.05.15.
//  Copyright (c) 2015 luisfloreani.com. All rights reserved.
//

#import "LAFSrcRootFinder.h"

#import <XCTest/XCTest.h>

static NSString* AbsolutePath(NSString* relativePath) {
    NSString* currentDir = [[NSFileManager defaultManager] currentDirectoryPath];
    NSString* fullPath = [currentDir stringByAppendingPathComponent:relativePath];
    return fullPath;
}

static NSString* ProjectPathWithSrcRoot() {
    return AbsolutePath(@"/../TestProjects/AutoImporterTestProject2/src/project/AutoImporterTestProject2.xcodeproj");
}

static NSString* ProjectPathWithoutSrcRoot() {
    return AbsolutePath(@"/../TestProjects/AutoImporterTestProject1/AutoImporterTestProject1.xcodeproj");
}

@interface LAFSrcRootFinderTests : XCTestCase

@end

@implementation LAFSrcRootFinderTests

- (void)testSrcRoot {
    NSString* srcRootPath = [LAFSrcRootFinder findSrcRootFromPath:ProjectPathWithSrcRoot()];
    NSString* expectedPath = [AbsolutePath(@"/../TestProjects/AutoImporterTestProject2/src") stringByStandardizingPath];
    XCTAssertEqualObjects(srcRootPath, expectedPath);
}

- (void)testSrcRootNotFound {
    NSString* srcRootPath = [LAFSrcRootFinder findSrcRootFromPath:ProjectPathWithoutSrcRoot()];
    XCTAssertNil(srcRootPath);
}

@end
