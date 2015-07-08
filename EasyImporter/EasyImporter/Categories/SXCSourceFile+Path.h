//
//  XCSourceFile+Path.h
//  AutoImporter
//
//  Created by Luis Floreani on 9/11/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <XcodeEditor/SXCSourceFile.h>

@interface SXCSourceFile (Path)

- (NSString *)fullPathAgainstProjectDir:(NSString *)projectDir;

@end
