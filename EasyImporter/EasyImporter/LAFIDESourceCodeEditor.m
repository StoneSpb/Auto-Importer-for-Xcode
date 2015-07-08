//
//  LAFIDESourceCodeEditor.m
//  AutoImporter
//
//  Created by Luis Floreani on 10/2/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "LAFIDESourceCodeEditor.h"
#import "LAFIDESourceCodeEditor_Private.h"

#import "MHXcodeDocumentNavigator.h"
#import "DVTSourceTextStorage+Operations.h"
#import "NSTextView+Operations.h"
#import "NSString+Extensions.h"
#import "LAFIdentifier.h"
#import "LAFImportStatementFormatter.h"

@interface LAFIDESourceCodeEditor()

@property (nonatomic, strong) NSMutableSet *importedCache;

@end

@implementation LAFIDESourceCodeEditor

- (NSString *)importStatementForHeader:(LAFIdentifier *)header {
    return [LAFImportStatementFormatter importStatementForHeader:header];
}

- (void)cacheImports {
    [self invalidateImportsCache];
    
    if (!_importedCache) {
        _importedCache = [[NSMutableSet alloc] init];
    }
    
    DVTSourceTextStorage *textStorage = [self currentTextStorage];
    [textStorage.string enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        if ([self isImportString:line]) {
            NSString* trimmedLine =
                [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [_importedCache addObject:trimmedLine];
        }
    }];
}

- (void)invalidateImportsCache {
    [_importedCache removeAllObjects];
}

- (LAFImportResult)importHeader:(LAFIdentifier *)header {
    return [self addImport:[self importStatementForHeader:header]];
}

- (BOOL)hasImportedHeader:(LAFIdentifier *)header {
    return [_importedCache containsObject:[self importStatementForHeader:header]];
}

- (NSView *)view {
    return [MHXcodeDocumentNavigator currentSourceCodeTextView];
}

- (NSString *)selectedText {
    NSTextView *textView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    NSRange range = textView.selectedRange;
    return [[textView string] substringWithRange:range];
}

- (void)insertOnCaret:(NSString *)text {
    NSTextView *textView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    NSRange range = textView.selectedRange;
    [textView insertText:text replacementRange:range];
}

- (void)showAboveCaret:(NSString *)text color:(NSColor *)color {
    NSTextView *currentTextView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    
    NSRect keyRectOnTextView = [currentTextView mhFrameForCaret];
    
    NSTextField *field = [[NSTextField alloc] initWithFrame:CGRectMake(keyRectOnTextView.origin.x,
                                                                       keyRectOnTextView.origin.y, 0, 0)];
    [field setBackgroundColor:color];
    [field setFont:currentTextView.font];
    [field setTextColor:[NSColor colorWithCalibratedWhite:0.2 alpha:1.0]];
    [field setStringValue:text];
    [field sizeToFit];
    [field setBordered:NO];
    [field setEditable:NO];
    field.frame = CGRectOffset(field.frame, 0, - field.bounds.size.height - 3);
    
    [currentTextView addSubview:field];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setCompletionHandler:^{
            [field removeFromSuperview];
        }];
        [[NSAnimationContext currentContext] setDuration:1.0];
        [[field animator] setAlphaValue:0.0];
        [NSAnimationContext endGrouping];
    });
}

- (DVTSourceTextStorage *)currentTextStorage {
    if (![[MHXcodeDocumentNavigator currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        return nil;
    }
    NSTextView *textView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    return (DVTSourceTextStorage*)textView.textStorage;
}

- (LAFImportResult)addImport:(NSString *)statement {
    BOOL duplicate = NO;
    BOOL shouldCreateNewImportBlock = NO;
    DVTSourceTextStorage *textStorage = [self currentTextStorage];
    NSInteger line = [self appropriateLineInSource:textStorage
                                forImportStatement:statement
                                       isDuplicate:&duplicate
                        shouldCreateNewImportBlock:&shouldCreateNewImportBlock];
    
    if (line != NSNotFound) {
        NSString *importString = [NSString stringWithFormat:@"%@%@\n",
                                                            shouldCreateNewImportBlock ? @"\n" : @"",
                                                            statement];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [textStorage mhInsertString:importString atLine:line];
        });
    }
    
    if (duplicate) {
        return LAFImportResultAlready;
    } else {
        return LAFImportResultDone;
    }
}

/**
 * Finds an appropriate line for import statement according to these rules:
 * - Common imports should be separated by a new line from system and third-party frameworks
 * - Imports should be sorted in alphabetic order.
 *
 * ! duplicate
 * ! shouldCreateNewImportBlock
 */
- (NSUInteger)appropriateLineInSource:(DVTSourceTextStorage *)source
                   forImportStatement:(NSString *)statement
                          isDuplicate:(BOOL *)duplicate
           shouldCreateNewImportBlock:(BOOL *)shouldCreateNewImportBlock {
    __block NSUInteger lineNumber = NSNotFound;
    __block NSUInteger currentLineNumber = 0;
    __block BOOL foundDuplicate = NO;

    __block BOOL hasFrameworkImportInCurrentBlock = NO;
    __block BOOL exactLineIsFoundForCurrentBlock = NO;
    __block BOOL currentlyOnNewLine = NO;

    [source.string enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        // Don't care for now if not import statement
        if ([self isImportString:line]) {
            if (currentlyOnNewLine) {
                // Reset exact insertion position found for previous block
                exactLineIsFoundForCurrentBlock = NO;
                // Reset framework imports flag
                hasFrameworkImportInCurrentBlock = NO;
                currentlyOnNewLine = NO;
            }

            // Compare trimmed lines
            NSString* trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([trimmedLine isEqual:statement]) {
                // If duplicate is found - no further processing is needed
                foundDuplicate = YES;
                *stop = YES;
                return;
            }

            // Track framework imports
            if ([self isFrameworkImportString:line]) {
                hasFrameworkImportInCurrentBlock = YES;
                *shouldCreateNewImportBlock = YES;
            } else  if (!hasFrameworkImportInCurrentBlock) {
                // If no frameworks were found - this import block is a candidate for insertion
                *shouldCreateNewImportBlock = NO;
                // If an exact insertion position was found - don't process current line
                if (!exactLineIsFoundForCurrentBlock) {
                    // Check for alphabetic order violation
                    if ([statement compare:trimmedLine
                                   options:NSCaseInsensitiveSearch] == NSOrderedAscending) {
                        exactLineIsFoundForCurrentBlock = YES;
                        lineNumber = currentLineNumber;
                    }
                }
            }

            // If an exact insertion position was not found - push the line number down
            if (!exactLineIsFoundForCurrentBlock) {
                lineNumber = currentLineNumber;
            }
        } else if ([line mh_isWhitespaceOrNewline]) {
            currentlyOnNewLine = YES;
        }

        currentLineNumber++;
    }];

    // Duplicating has a maximum priority
    if (foundDuplicate) {
        *duplicate = YES;
        *shouldCreateNewImportBlock = NO;
        return NSNotFound;
    }

    // If no imports are present - find the first new line.
    if (lineNumber == NSNotFound) {
        currentLineNumber = 0;
        [source.string enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            if (![line mh_isWhitespaceOrNewline]) {
                currentLineNumber++;
            }
            else {
                lineNumber = currentLineNumber;
                *stop = YES;
            }
        }];
    }

    // If exact insertion position was not found - place a statement after other ones
    if (!exactLineIsFoundForCurrentBlock) {
        lineNumber++;
    }
    return lineNumber;
}

- (NSRegularExpression*)importRegex {
    static NSRegularExpression* _regex = nil;
    if (!_regex) {
        static NSString* const kImportRegexPattern = @"^#.*(import|include).*[\",<].*[\",>]";
        _regex = [self createRegexWithPattern:kImportRegexPattern];
    }
    return _regex;
}

- (NSRegularExpression*)frameworkImportRegex {
    static NSRegularExpression* _regex = nil;
    if (!_regex) {
        static NSString* const kFrameworkImportRegexPattern = @"^#.*(import|include).*[<].*[>]";
        _regex = [self createRegexWithPattern:kFrameworkImportRegexPattern];
    }
    return _regex;
}

- (NSRegularExpression*)createRegexWithPattern:(NSString*)pattern {
    return [[NSRegularExpression alloc] initWithPattern:pattern
                                                options:0
                                                  error:NULL];
}

- (BOOL)isImportString:(NSString*)string {
    return [self string:string matchesRegex:[self importRegex]];
}

- (BOOL)isFrameworkImportString:(NSString*)string {
    return [self string:string matchesRegex:[self frameworkImportRegex]];
}

- (BOOL)string:(NSString*)string matchesRegex:(NSRegularExpression*)regex {
    NSInteger numberOfMatches = [regex numberOfMatchesInString:string options:0 range:NSMakeRange(0, string.length)];
    return numberOfMatches > 0;
}

@end
