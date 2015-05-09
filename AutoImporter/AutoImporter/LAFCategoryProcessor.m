//
//  LAFCategoryProcessor.m
//  AutoImporter
//
//  Created by Luis Floreani on 10/16/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "LAFCategoryProcessor.h"
#import "LAFIdentifier.h"

@implementation LAFCategoryProcessor

- (NSString *)pattern {
    return @"(?:@interface)\\s+([a-z][a-z0-9_\\s*]+)\\(\\s*[^\\s]+\\s*\\)\\s*$(.+)^@end";
}

- (NSArray *)createElements:(NSString *)content {
    NSMutableArray *array = [NSMutableArray array];
    [self processContent:content resultBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        NSArray *elements = [self createCategoryElements:match from:content];
        [array addObjectsFromArray:elements];
    }];
    
    return array;
}

- (NSArray *)createCategoryElements:(NSTextCheckingResult *)match from:(NSString *)content {
    NSRange matchRange = [match rangeAtIndex:1];
    NSString *matchString = [content substringWithRange:matchRange];
    NSString *matchClass =
            [matchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    matchRange = [match rangeAtIndex:2];
    matchString = [content substringWithRange:matchRange];
    NSString *matchMethods = [matchString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSArray *methods = [matchMethods componentsSeparatedByString:@";"];
    NSUInteger count = methods.count;

    NSMutableArray *elements = [[NSMutableArray alloc] init];
    [methods enumerateObjectsUsingBlock:^(NSString *method, NSUInteger idx, BOOL *stop) {
        if (idx != count - 1) {
            method = [method stringByAppendingString:@";"];
        }
        NSString *signature = [self extractSignature:method];
        if (signature) {
            LAFIdentifier *element = [[LAFIdentifier alloc] init];
            element.name = [self extractSignature:method];
            element.customTypeString = matchClass;
            element.type = LAFIdentifierTypeCategory;
            [elements addObject:element];
        }
    }];
    
    return [elements copy];
}

- (NSString *)extractSignature:(NSString *)method {
    method = [method stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([method length] == 0) {
        return nil;
    }

    NSError *error = nil;
    NSRegularExpression *regex =
        [NSRegularExpression regularExpressionWithPattern:@"([a-z][a-z0-9_]+\\s*[:;])"
                                                  options:NSRegularExpressionCaseInsensitive |
                                                          NSRegularExpressionAllowCommentsAndWhitespace
                                                    error:&error];
    
    if (error) {
        LAFLog(@"processing header path error: %@", error);
        return nil;
    }
    
    NSMutableString *signature = [[NSMutableString alloc] init];
    [regex enumerateMatchesInString:method
                            options:0
                              range:NSMakeRange(0, [method length])
                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
        NSRange matchRange = [match rangeAtIndex:1];
        NSString *matchString = [method substringWithRange:matchRange];
        NSString *matchPart =
            [matchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *partWithoutSpaces = [matchPart stringByReplacingOccurrencesOfString:@" " withString:@""];
        if ([partWithoutSpaces hasSuffix:@";"]) {
            if ([signature length] > 0) {
                return; // it's not the first part so it already has a name
            } else {
                partWithoutSpaces = [partWithoutSpaces substringToIndex:([partWithoutSpaces length] - 1)];
            }
        }
        
        [signature appendString:partWithoutSpaces];
    }];
    
    if ([signature length] > 0)
        return [signature copy];
    else
        return nil;
}


@end
