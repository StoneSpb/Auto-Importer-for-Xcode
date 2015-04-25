//
//  LAFSrcRootFinder.h
//  AutoImporter
//
//  Created by Alexander Denisov on 03.05.15.
//  Copyright (c) 2015 luisfloreani.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LAFSrcRootFinder : NSObject

+ (NSString*)findSrcRootFromPath:(NSString*)path;

@end
