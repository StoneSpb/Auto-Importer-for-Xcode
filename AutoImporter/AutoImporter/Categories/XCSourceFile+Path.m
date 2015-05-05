//
//  XCSourceFile+Path.m
//  AutoImporter
//
//  Created by Luis Floreani on 9/11/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "XCSourceFile+Path.h"
#import "XCProject+Extensions.h"

@interface XCSourceFile()

@property (nonatomic, readonly) XCProject *project;

@end

@implementation XCSourceFile (Path)

//@dynamic project;

- (NSString *)fullPathAgainstProjectDir:(NSString *)projectDir {
    NSString *filePath = [self pathRelativeToProjectRoot];
    return [projectDir stringByAppendingPathComponent:filePath];
}

@end
