//
//  XCSourceFile+Path.m
//  AutoImporter
//
//  Created by Luis Floreani on 9/11/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "SXCSourceFile+Path.h"

#import "SXCProject+Extensions.h"

@interface SXCSourceFile()

@property (nonatomic, readonly) SXCProject *project;

@end

@implementation SXCSourceFile (Path)

//@dynamic project;

- (NSString *)fullPathAgainstProjectDir:(NSString *)projectDir {
    NSString *filePath = [self pathRelativeToProjectRoot];
    return [projectDir stringByAppendingPathComponent:filePath];
}

@end
