//
//  LAFImportStatementFormatterTests.m
//  AutoImporter
//
//  Created by Alexander Denisov on 03.05.15.
//  Copyright (c) 2015 luisfloreani.com. All rights reserved.
//

#import "LAFImportStatementFormatter.h"

#import <XCTest/XCTest.h>

#import "LAFIdentifier.h"

static LAFIdentifier* HeaderWithPathAndSrcRoot(NSString* path,
                                               NSString* srcRootPath) {
    LAFIdentifier* identifier = [[LAFIdentifier alloc] init];
    identifier.type = LAFIdentifierTypeHeader;
    identifier.fullPath = path;
    identifier.srcRootPath = srcRootPath;
    identifier.name = path.lastPathComponent;
    return identifier;
}

static NSString* ImportStatementForPath(NSString* path) {
    return [NSString stringWithFormat:@"#import \"%@\"", path];
}

@interface LAFImportStatementFormatterTests : XCTestCase

@property(nonatomic, copy) NSString *basePath;

@end

@implementation LAFImportStatementFormatterTests

- (void)setUp {
    [super setUp];

    self.basePath = @"/Test/src_root";
}

- (void)testHeaderWithoutSrcRoot {
    LAFIdentifier *header = HeaderWithPathAndSrcRoot(@"/Test/src_root/test/Header1.h", nil);
    NSString *statement = [LAFImportStatementFormatter importStatementForHeader:header];
    XCTAssertEqualObjects(statement, ImportStatementForPath(@"Header1.h"));
}

- (void)testHeaderWithBasePath {
    LAFIdentifier *header = HeaderWithPathAndSrcRoot(@"/Test/src_root/test/Header1.h", self.basePath);
    NSString *statement = [LAFImportStatementFormatter importStatementForHeader:header];
    XCTAssertEqualObjects(statement, ImportStatementForPath(@"test/Header1.h"));
}

- (void)testHeaderWithMismatchedBasePath {
    LAFIdentifier *header = HeaderWithPathAndSrcRoot(@"/Test/other/test/Header1.h", self.basePath);
    NSString *statement = [LAFImportStatementFormatter importStatementForHeader:header];
    XCTAssertEqualObjects(statement, ImportStatementForPath(@"Header1.h"));
}

- (void)testHeaderWithBasePathAndUnstandartizedRelativePath {
    LAFIdentifier *header = HeaderWithPathAndSrcRoot(@"/Test/src_root/test/subfolder/../Header1.h", self.basePath);
    NSString *statement = [LAFImportStatementFormatter importStatementForHeader:header];
    XCTAssertEqualObjects(statement, ImportStatementForPath(@"test/Header1.h"));
}

@end
