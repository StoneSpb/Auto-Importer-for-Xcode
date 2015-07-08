//
//  LAFIDESourceCodeEditor.h
//  AutoImporter
//
//  Created by Luis Floreani on 10/2/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "LAFIDESourceCodeEditor.h"

@class DVTSourceTextStorage;

@interface LAFIDESourceCodeEditor ()

- (NSUInteger)appropriateLineInSource:(DVTSourceTextStorage*)source
                   forImportStatement:(NSString*)statement
                          isDuplicate:(BOOL*)duplicate
           shouldCreateNewImportBlock:(BOOL*)shouldCreateNewImportBlock;

- (BOOL)isFrameworkImportString:(NSString*)string;

@end
