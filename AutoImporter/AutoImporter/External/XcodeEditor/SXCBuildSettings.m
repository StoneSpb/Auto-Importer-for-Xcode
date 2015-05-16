//
//  XCBuildSettings.m
//  MHImportBuster
//
//  Created by Marko Hlebar on 11/05/2014.
//  Copyright (c) 2014 Marko Hlebar. All rights reserved.
//

#import "SXCBuildSettings.h"

#import <XcodeEditor/SXCProject.h>

#import "NSString+SXCAdditions.h"
#import "SXCTarget+SXCProject.h"

static NSString * const SXCBuildSettingsCommandFormat =
    @"xcodebuild -project \"%@\" -target \"%@\" -showBuildSettings";

NSString *const SXCBuildSettingsSDKROOTKey                      = @"SDKROOT";
NSString *const SXCBuildSettingsHeaderSearchPathsKey            = @"HEADER_SEARCH_PATHS";
NSString *const SXCBuildSettingsUserHeaderSearchPathsKey        = @"USER_HEADER_SEARCH_PATHS";
NSString *const SXCBuildSettingsProjectDirKey                   = @"PROJECT_DIR";

@implementation SXCBuildSettings
{
    NSDictionary *_settings;
}

+ (instancetype)buildSettingsWithTarget:(SXCTarget *)target
{
    return [[self alloc] initWithTarget:target];
}

- (instancetype)initWithTarget:(SXCTarget *)target
{
    self = [super init];
    if (self) {
        _target = target;
    }
    return self;
}

- (NSDictionary *)settings
{
    if(!_settings) {
        NSString *projectPath = [_target.project filePath];
        NSString *command = [NSString stringWithFormat:SXCBuildSettingsCommandFormat, projectPath, _target.name];
        NSString *output = [command sxc_runAsCommand];
        _settings = [output sxc_settingsDictionary];
    }
    return _settings;
}

- (id) valueForKey:(NSString *)key {
    return self.settings[key];
}

@end
