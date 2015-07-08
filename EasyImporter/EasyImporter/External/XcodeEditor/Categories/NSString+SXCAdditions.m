//
//  NSString+XCAdditions.m
//  xcode-editor
//
//  Created by Marko Hlebar on 08/05/2014.
//  Copyright (c) 2014 EXPANZ. All rights reserved.
//

#import "NSString+SXCAdditions.h"

@implementation NSString (SXCAdditions)

- (NSString *)sxc_stringByReplacingOccurrencesOfStrings:(NSArray *)targets
                                             withString:(NSString *)replacement {
    __block NSString *string = self;
    [targets enumerateObjectsUsingBlock:^(NSString *target, NSUInteger idx, BOOL *stop) {
        string = [string stringByReplacingOccurrencesOfString:target withString:replacement];
    }];
    return string;
}

- (BOOL)sxc_containsOccurencesOfStrings:(NSArray *)strings {
    for (NSString *string in strings) {
        if ([self sxc_containsString:string]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)sxc_containsString:(NSString *)string {
    return [self rangeOfString:string].location != NSNotFound;
}

@end

//http://stackoverflow.com/questions/412562/execute-a-terminal-command-from-a-cocoa-app
@implementation NSString (ShellExecution)

- (NSString*)sxc_runAsCommand {
    NSPipe* pipe = [NSPipe pipe];
    
    NSTask* task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    [task setArguments:@[@"-c", [NSString stringWithFormat:@"%@", self]]];
    [task setStandardOutput:pipe];
    [task launch];

    NSFileHandle* file = [pipe fileHandleForReading];
    return [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
}

@end

@implementation NSString (ParseSXCSettings)

- (NSDictionary*)sxc_settingsDictionary {
    NSArray *settingsArray = [self componentsSeparatedByString:@"\n"];
//    NSLog(@"%@", settingsArray);
    NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceCharacterSet];
    NSMutableDictionary *settingsDictionary = [NSMutableDictionary dictionary];
    [settingsArray enumerateObjectsUsingBlock:^(NSString *keyValuePair, NSUInteger idx, BOOL *stop) {
        NSArray *keyValueArray = [keyValuePair componentsSeparatedByString:@" = "];
        if (keyValueArray.count == 2) {
            NSString *key = [keyValueArray[0] stringByTrimmingCharactersInSet:whitespaceSet];
            [settingsDictionary setObject:keyValueArray[1]
                                   forKey:key];
        }
    }];
    return settingsDictionary.copy;
}

- (id)sxc_parseWhitespaceArray {
    //if string doesn't contain whitespaces it is not an array of options
    if(![self sxc_containsString:@" "]) return self;
    NSString *trimmedString = [self stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    return [trimmedString componentsSeparatedByString:@" "];
}

@end
