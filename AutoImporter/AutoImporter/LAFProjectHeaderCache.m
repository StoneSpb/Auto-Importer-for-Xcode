//
//  LAFProjectHeaderCache.m
//  AutoImporter
//
//  Created by Luis Floreani on 9/15/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "LAFProjectHeaderCache.h"

#import "LAFCategoryProcessor.h"
#import "LAFClassProcessor.h"
#import "LAFIdentifier.h"
#import "LAFProtocolProcessor.h"
#import "LAFSrcRootFinder.h"
#import "XCProject.h"
#import "XCSourceFile+Path.h"
#import "XCSourceFile.h"

#define kPatternRegExp @"regexp"
#define kPatternType @"type"

@interface LAFProjectHeaderCache()

@property (nonatomic, copy) NSString *srcRootPath;

// value is NSString
@property (nonatomic, strong) NSMapTable *headersByIdentifiers;

// value is an array of LAFIdentifier
@property (nonatomic, strong) NSMapTable *identifiersByHeaders;

@property (nonatomic, strong) NSOperationQueue *headersQueue;

@end

@implementation LAFProjectHeaderCache

- (instancetype)initWithProjectPath:(NSString *)projectPath
{
    self = [super init];
    if (self) {
        _projectPath = projectPath;
        _srcRootPath = [LAFSrcRootFinder findSrcRootFromPath:projectPath];
        _headersByIdentifiers = [NSMapTable strongToStrongObjectsMapTable];
        _identifiersByHeaders = [NSMapTable strongToStrongObjectsMapTable];
        _headersQueue = [NSOperationQueue new];
        _headersQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void)refreshWithCompletion:(dispatch_block_t)doneBlock {
    [_headersByIdentifiers removeAllObjects];
    [_identifiersByHeaders removeAllObjects];
    
    XCProject *project = [XCProject projectWithFilePath:self.projectPath];
    [_headersQueue addOperationWithBlock:^{
        [self updateProject:project];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            doneBlock();
        }];
    }];
}

- (BOOL)containsHeaderWithPath:(NSString *)headerPath {
    LAFIdentifier* header = [self headerIdentifierWithFilePath:headerPath];
    return [_identifiersByHeaders objectForKey:header] != nil;
}

- (void)refreshHeaderWithPath:(NSString *)headerPath {
    LAFIdentifier* header = [self headerIdentifierWithFilePath:headerPath];
    NSMutableArray *identifiers = [_identifiersByHeaders objectForKey:header];
    for (LAFIdentifier *identifier in identifiers) {
        [_headersByIdentifiers removeObjectForKey:identifier];
    }

    [identifiers removeAllObjects];
    
    [self processHeader:header];
}

- (LAFIdentifier *)headerForIdentifier:(NSString *)name {
    LAFIdentifier *identifier = [[LAFIdentifier alloc] initWithName:name];
    return [_headersByIdentifiers objectForKey:identifier];
}

- (NSArray *)headers {
    return _identifiersByHeaders.keyEnumerator.allObjects;
}

- (NSArray *)identifiers {
    return _headersByIdentifiers.keyEnumerator.allObjects;
}

- (BOOL)processHeader:(LAFIdentifier *)header {
    @autoreleasepool {
        NSError *error = nil;
        NSString *content = [NSString stringWithContentsOfFile:header.fullPath
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
        if (error) {
            return NO;
        }
        
        NSMutableArray *identifiers = [_identifiersByHeaders objectForKey:header];
        if (!identifiers) {
            identifiers = [NSMutableArray array];
            [_identifiersByHeaders setObject:identifiers forKey:header];
        }
        
        NSArray *processors = @[
          [LAFCategoryProcessor new],
          [LAFClassProcessor new],
          [LAFProtocolProcessor new]
        ];

        for (LAFElementProcessor *processor in processors) {
            NSArray *elements = [processor createElements:content];
            [identifiers addObjectsFromArray:elements];
            for (LAFIdentifier *element in elements) {
                [_headersByIdentifiers setObject:header forKey:element];
            }
        }
        
        return YES;
    }
}

- (void)updateProject:(XCProject *)project {
    NSDate *start = [NSDate date];

    NSMutableSet *missingFiles = [NSMutableSet set];
    for (XCSourceFile *header in project.headerFiles) {
        LAFIdentifier *headerIdentifier = [self headerIdentifierWithFilePath:header.fullPath];
        if (![self processHeader:headerIdentifier]) {
            NSString *file = [header.pathRelativeToProjectRoot lastPathComponent];
            if (file) {
                [missingFiles addObject:file];
            }
        }
    }

    NSString *projectPath = project.filePath;
    NSString *projectDir = [projectPath stringByDeletingLastPathComponent];
    NSArray *missingHeaderFullPaths = [self fullPathsForFiles:missingFiles inDirectory:projectDir];
    
    for (NSString *fullPath in missingHeaderFullPaths) {
        LAFIdentifier *headerIdentifier = [self headerIdentifierWithFilePath:fullPath];
        [self processHeader:headerIdentifier];
    }

    NSTimeInterval executionTime = -[start timeIntervalSinceNow];
    
    LAFLog(@"%llu Headers in project %@ - parse time: %f",
           (uint64_t)_headersByIdentifiers.count,
           [projectPath lastPathComponent],
           executionTime);
}

#pragma mark -

- (NSArray *)fullPathsForFiles:(NSSet *)fileNames inDirectory:(NSString *)directoryPath {
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:directoryPath];
    
    NSMutableArray *fullPaths = [NSMutableArray array];
    
    NSString *filePath = nil;
    while ( (filePath = [enumerator nextObject] ) != nil ){
        if ([fileNames containsObject:[filePath lastPathComponent]]) {
            [fullPaths addObject:[directoryPath stringByAppendingPathComponent:filePath]];
        }
    }
    
    return fullPaths;
}

- (LAFIdentifier *)headerIdentifierWithFilePath:(NSString *)headerPath {
    LAFIdentifier *identifier = [[LAFIdentifier alloc] init];
    identifier.name = headerPath.lastPathComponent;
    identifier.fullPath = headerPath;
    identifier.srcRootPath = self.srcRootPath;
    identifier.type = LAFIdentifierTypeHeader;
    return identifier;
}

@end
