//
//  LAFProjectHeaderCache.h
//  AutoImporter
//
//  Created by Luis Floreani on 9/15/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LAFIdentifier;

@interface LAFProjectHeaderCache : NSObject

@property (nonatomic, readonly) NSString *projectPath;
// array of LAFIdentifier
@property (nonatomic, readonly) NSArray *identifiers;
// array of LAFIdentifier
@property (nonatomic, readonly) NSArray *headers;

- (instancetype)initWithProjectPath:(NSString *)projectPath;

- (void)refreshWithCompletion:(dispatch_block_t)doneBlock;
- (void)cancelRefreshOperations;
- (void)refreshHeaderWithPath:(NSString *)headerPath;

- (BOOL)containsHeaderWithPath:(NSString *)headerPath;
- (LAFIdentifier *)headerForIdentifier:(NSString *)name;

@end
