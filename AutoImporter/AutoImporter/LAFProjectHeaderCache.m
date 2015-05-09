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
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation *weakOperation = operation;
    [operation addExecutionBlock:^{
        __strong NSBlockOperation *strongOperation = weakOperation;
        [self updateProject:project operation:strongOperation];
        if (!strongOperation.cancelled) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                doneBlock();
            }];
        }
    }];
    [_headersQueue addOperation:operation];
}

- (void)cancelRefreshOperations {
    [_headersQueue cancelAllOperations];
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

- (void)updateProject:(XCProject *)project operation:(NSOperation *)operation {
    NSDate *startDate = [NSDate date];

    NSString *projectPath = project.filePath;
    NSString *projectName = projectPath.lastPathComponent;
    NSString *projectDir = [projectPath stringByDeletingLastPathComponent];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableSet *missingFiles = [[NSMutableSet alloc] init];

    LAFLog(@"%@: %llu headers", projectName, (uint64_t)project.headerFiles.count);

    for (XCSourceFile *header in project.headerFiles) {
        if (operation.cancelled) {
            return;
        }

        NSString *fullPath = [header fullPathAgainstProjectDir:projectDir];
        if ([fileManager fileExistsAtPath:fullPath]) {
            [self processHeaderAtPath:fullPath];
        } else {
            NSString *fileName = fullPath.lastPathComponent;
            if (fileName) {
                [missingFiles addObject:fileName];
            }
        }
    }

    NSArray *missingHeaderFullPaths = [self fullPathsForFiles:missingFiles inDirectory:projectDir];
    for (NSString *headerPath in missingHeaderFullPaths) {
        if (operation.cancelled) {
            return;
        }

        [self processHeaderAtPath:headerPath];
    }

    NSTimeInterval executionTime = -[startDate timeIntervalSinceNow];
    LAFLog(@"%@: processed in %fs", projectName, executionTime);
}

#pragma mark - Header processing

- (void)processHeaderAtPath:(NSString *)headerPath {
    LAFIdentifier *headerIdentifier = [self headerIdentifierWithFilePath:headerPath];
    [self processHeader:headerIdentifier];
}

- (BOOL)processHeader:(LAFIdentifier *)header {
    @autoreleasepool {
        NSError *error = nil;
        NSString *content = [NSString stringWithContentsOfFile:header.fullPath
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
        if (error) {
            LAFLog(@"Failed to process %@: %@", header.name, error);
            return NO;
        }
        
        NSMutableArray *identifiers = [_identifiersByHeaders objectForKey:header];
        if (!identifiers) {
            identifiers = [NSMutableArray array];
            [_identifiersByHeaders setObject:identifiers forKey:header];
        }
        
        NSArray *processors = @[
          [[LAFCategoryProcessor alloc] init],
          [[LAFClassProcessor alloc] init],
          [[LAFProtocolProcessor alloc] init]
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

#pragma mark -

- (NSArray *)fullPathsForFiles:(NSSet *)fileNames inDirectory:(NSString *)directoryPath {
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:directoryPath];
    
    NSMutableArray *fullPaths = [[NSMutableArray alloc] init];
    
    NSString *relativePath = nil;
    while ((relativePath = [enumerator nextObject]) != nil){
        if ([fileNames containsObject:relativePath.lastPathComponent]) {
            [fullPaths addObject:[directoryPath stringByAppendingPathComponent:relativePath]];
        }
    }
    
    return [fullPaths copy];
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
