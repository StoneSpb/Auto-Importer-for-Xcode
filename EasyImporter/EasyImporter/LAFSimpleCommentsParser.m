//
//  LAFSimpleCommentsParser.m
//  AutoImporter
//
//  Created by Alexander Denisov on 12.05.15.
//  Copyright (c) 2015 luisfloreani.com. All rights reserved.
//

#import "LAFSimpleCommentsParser.h"

@implementation LAFSimpleCommentsParser

- (NSString*)stripComments:(NSString*)source {
    NSMutableString* mutableString = [[NSMutableString alloc] init];

    __block BOOL hasOpenMultilineComment = NO;

    [source enumerateLinesUsingBlock:^(NSString* line, BOOL* stop) {
        line = [self stripCommentsInLine:line hasOpenMultilineComment:&hasOpenMultilineComment];
        NSString* ending = hasOpenMultilineComment ? @"" : @"\n";
        [mutableString appendFormat:@"%@%@", line, ending];
    }];

    return [mutableString copy];
}

- (NSString*)stripCommentsInLine:(NSString*)line hasOpenMultilineComment:(BOOL*)hasOpenMultilineComment {
    if (*hasOpenMultilineComment) {
        NSUInteger mlEndIndex = [self findMultilineCommentEnd:line];
        if (mlEndIndex == NSNotFound) {
            return @"";
        } else {
            *hasOpenMultilineComment = NO;
            NSString* right = [line substringFromIndex:mlEndIndex + 2];
            return [self stripCommentsInLine:right hasOpenMultilineComment:hasOpenMultilineComment];
        }
    }

    NSUInteger slIndex = [self findSinglelineComment:line];
    NSUInteger mlStartIndex = [self findMultilineCommentStart:line];
    if (slIndex != NSNotFound && (mlStartIndex == NSNotFound || slIndex < mlStartIndex)) {
        return [line substringToIndex:slIndex];
    } else if (mlStartIndex != NSNotFound && (slIndex == NSNotFound || mlStartIndex < slIndex)) {
        *hasOpenMultilineComment = YES;
        NSString* left = [line substringToIndex:mlStartIndex];
        NSString* right = [line substringFromIndex:mlStartIndex + 2];
        return [left stringByAppendingString:[self stripCommentsInLine:right
                                               hasOpenMultilineComment:hasOpenMultilineComment]];
    }

    return line;
}

- (NSUInteger)findSinglelineComment:(NSString*)line {
    NSParameterAssert(line);
    return [line rangeOfString:@"//"].location;
}

- (NSUInteger)findMultilineCommentStart:(NSString*)line {
    NSParameterAssert(line);
    return [line rangeOfString:@"/*"].location;
}

- (NSUInteger)findMultilineCommentEnd:(NSString*)line {
    NSParameterAssert(line);
    return [line rangeOfString:@"*/"].location;
}

@end
