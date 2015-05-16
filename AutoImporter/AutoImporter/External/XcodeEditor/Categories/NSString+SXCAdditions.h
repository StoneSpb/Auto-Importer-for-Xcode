//
//  NSString+XCAdditions.h
//  xcode-editor
//
//  Created by Marko Hlebar on 08/05/2014.
//  Copyright (c) 2014 EXPANZ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SXCAdditions)

- (NSString *)sxc_stringByReplacingOccurrencesOfStrings:(NSArray *)targets
                                             withString:(NSString *)replacement;

- (BOOL)sxc_containsOccurencesOfStrings:(NSArray *)strings;
- (BOOL)sxc_containsString:(NSString *)string;

@end

@interface NSString (ShellExecution)

- (NSString*)sxc_runAsCommand;

@end

@interface NSString (ParseSXCSettings)

- (NSDictionary*)sxc_settingsDictionary;
- (id)sxc_parseWhitespaceArray;

@end