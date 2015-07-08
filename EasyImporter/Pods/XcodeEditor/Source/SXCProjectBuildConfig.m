////////////////////////////////////////////////////////////////////////////////
//
//  JASPER BLUES
//  Copyright 2012 Jasper Blues
//  All Rights Reserved.
//
//  NOTICE: Jasper Blues permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

#import "SXCProjectBuildConfig.h"

#import "SXCGroup.h"
#import "SXCKeyBuilder.h"
#import "SXCProject.h"
#import "SXCSourceFile.h"

@implementation SXCProjectBuildConfig

/* ================================================================================================================== */
#pragma mark - Class Methods

+ (NSDictionary*)buildConfigurationsFromArray:(NSArray*)array inProject:(SXCProject*)project
{
    NSMutableDictionary* configurations = [[NSMutableDictionary alloc] init];

    NSString* projectDir = [[project filePath] stringByDeletingLastPathComponent];

    for (NSString* buildConfigurationKey in array) {
        NSDictionary* buildConfiguration = project.objects[buildConfigurationKey];
        NSString* name = buildConfiguration[@"name"];

        if ([buildConfiguration[@"isa"] sxc_hasBuildConfigurationType]) {
            SXCProjectBuildConfig* configuration = configurations[name];
            if (!configuration) {
                configuration = [[SXCProjectBuildConfig alloc] initWithProject:project key:buildConfigurationKey];
                configurations[name] = configuration;
            }

            SXCSourceFile* configurationFile = [project fileWithKey:buildConfiguration[@"baseConfigurationReference"]];
            if (configurationFile) {
                NSString* path = configurationFile.path;

                if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    SXCGroup* group = [project groupWithSourceFile:configurationFile];
                    path = [[group pathRelativeToParent] stringByAppendingPathComponent:path];
                }

                if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    path = [projectDir stringByAppendingPathComponent:path];
                }

                if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    path = [projectDir stringByAppendingPathComponent:configurationFile.path];
                }

                if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    [NSException raise:@"XCConfig not found" format:@"Unable to find XCConfig file at %@", path];
                }
            }

            [configuration addBuildSettings:[buildConfiguration objectForKey:@"buildSettings"]];
        }
    }

    return [configurations copy];
}

+ (NSString*)duplicatedBuildConfigurationListWithKey:(NSString*)buildConfigurationListKey
                                           inProject:(SXCProject*)project
                       withBuildConfigurationVisitor:(void (^)(NSMutableDictionary*))buildConfigurationVisitor
{
    NSDictionary* buildConfigurationList = project.objects[buildConfigurationListKey];
    NSMutableDictionary* dupBuildConfigurationList = [buildConfigurationList mutableCopy];

    NSMutableArray* dupBuildConfigurations = [NSMutableArray array];

    for (NSString* buildConfigurationKey in buildConfigurationList[@"buildConfigurations"])
    {
        [dupBuildConfigurations addObject:[self duplicatedBuildConfigurationWithKey:buildConfigurationKey
                                                                          inProject:project
                                                      withBuildConfigurationVisitor:buildConfigurationVisitor]];
    }

    dupBuildConfigurationList[@"buildConfigurations"] = dupBuildConfigurations;

    NSString* dupBuildConfigurationListKey = [[SXCKeyBuilder createUnique] build];

    project.objects[dupBuildConfigurationListKey] = dupBuildConfigurationList;

    return dupBuildConfigurationListKey;
}

/* ================================================================================================================== */
#pragma mark - Initialization & Destruction

- (instancetype)initWithProject:(SXCProject*)project key:(NSString*)key
{
    self = [super init];
    if (self)
    {
        _project = project;
        _key = [key copy];

        _buildSettings = [[NSMutableDictionary alloc] init];
        _xcconfigSettings = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithProject:nil key:nil];
}

/* ================================================================================================================== */
#pragma mark - Interface Methods

- (NSDictionary*)specifiedBuildSettings
{
    return [_buildSettings copy];
}

- (void)addBuildSettings:(NSDictionary*)buildSettings
{
    [_xcconfigSettings removeObjectsForKeys:[buildSettings allKeys]];
    [_buildSettings addEntriesFromDictionary:buildSettings];
}

- (void)addOrReplaceSetting:(id <NSCopying>)setting forKey:(NSString*)key
{
    NSDictionary* settings = [NSDictionary dictionaryWithObject:setting forKey:key];
    [self addBuildSettings:settings];

    NSMutableDictionary* objects = _project.objects;

    NSMutableDictionary* dict = [objects[_key] mutableCopy];
    dict[@"buildSettings"] = _buildSettings;
    objects[_key] = dict;
}

- (id <NSCopying>)valueForKey:(NSString*)key
{
    id <NSCopying> value = [_buildSettings objectForKey:key];
    if (!value)
    {
        value = [_xcconfigSettings objectForKey:key];
    }
    return value;
}

/* ================================================================================================================== */
#pragma mark - Utility Methods

- (NSString*)description
{
    NSMutableString* description = [[super description] mutableCopy];

    [description appendFormat:@"build settings: %@, inherited: %@", _buildSettings, _xcconfigSettings];

    return description;
}

/* ================================================================================================================== */
#pragma mark - Private Methods

+ (NSString*)duplicatedBuildConfigurationWithKey:(NSString*)buildConfigurationKey
                                       inProject:(SXCProject*)project
                   withBuildConfigurationVisitor:(void (^)(NSMutableDictionary*))buildConfigurationVisitor
{
    NSDictionary* buildConfiguration = project.objects[buildConfigurationKey];
    NSMutableDictionary* dupBuildConfiguration = [buildConfiguration mutableCopy];

    buildConfigurationVisitor(dupBuildConfiguration);

    NSString* dupBuildConfigurationKey = [[SXCKeyBuilder createUnique] build];

    project.objects[dupBuildConfigurationKey] = dupBuildConfiguration;

    return dupBuildConfigurationKey;
}

@end
