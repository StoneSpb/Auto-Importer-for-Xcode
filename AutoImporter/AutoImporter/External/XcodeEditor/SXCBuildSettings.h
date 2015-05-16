//
//  XCBuildSettings.h
//  MHImportBuster
//
//  Created by Marko Hlebar on 11/05/2014.
//  Copyright (c) 2014 Marko Hlebar. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const SXCBuildSettingsSDKROOTKey;
extern NSString *const SXCBuildSettingsHeaderSearchPathsKey;
extern NSString *const SXCBuildSettingsUserHeaderSearchPathsKey;
extern NSString *const SXCBuildSettingsProjectDirKey;

@class SXCTarget;

@interface SXCBuildSettings : NSObject

@property (nonatomic, strong, readonly) SXCTarget *target;
@property (nonatomic, readonly) NSDictionary *settings;

+ (instancetype)buildSettingsWithTarget:(SXCTarget *)target;
- (id)valueForKey:(NSString *)key;

@end
