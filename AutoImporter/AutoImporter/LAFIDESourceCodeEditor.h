//
//  LAFIDESourceCodeEditor.h
//  AutoImporter
//
//  Created by Luis Floreani on 10/2/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

typedef enum {
  LAFImportResultAlready,
  LAFImportResultNotFound,
  LAFImportResultDone,
} LAFImportResult;

@class LAFIdentifier;

@interface LAFIDESourceCodeEditor: NSObject

- (void)cacheImports;
- (void)invalidateImportsCache;

// need to call cacheImports before
- (BOOL)hasImportedHeader:(LAFIdentifier *)header;

- (LAFImportResult)importHeader:(LAFIdentifier *)header;

- (void)showAboveCaret:(NSString *)text color:(NSColor *)color;
- (void)insertOnCaret:(NSString *)text;
- (NSString *)selectedText;
- (NSView *)view;

@end
