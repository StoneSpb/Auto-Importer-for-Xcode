//
//  LAFSrcRootFinder.m
//  AutoImporter
//
//  Created by Alexander Denisov on 03.05.15.
//  Copyright (c) 2015 luisfloreani.com. All rights reserved.
//

#import "LAFSrcRootFinder.h"

@implementation LAFSrcRootFinder

+ (NSString*)findSrcRootFromPath:(NSString*)path {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* currentPath = [path stringByStandardizingPath];

    // Just in case
    NSInteger maxIterations = 1000;

    while (currentPath.length > 0 && ![currentPath isEqualToString:@"/"] &&
           (maxIterations-- > 0)) {
        if ([currentPath.lastPathComponent isEqualToString:@"src"]) {
            NSString* hgPath = [currentPath stringByAppendingPathComponent:@".hg"];
            if ([fileManager fileExistsAtPath:hgPath]) {
                return currentPath;
            }
        }

        currentPath = [currentPath stringByDeletingLastPathComponent];
    }

    return nil;
}

@end
