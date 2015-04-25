//
//  LAFImportStatementFormatter.h
//  AutoImporter
//
//  Created by Alexander Denisov on 03.05.15.
//  Copyright (c) 2015 luisfloreani.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LAFIdentifier;

@interface LAFImportStatementFormatter : NSObject

+ (NSString*)importStatementForHeader:(LAFIdentifier*)header;

@end
