////////////////////////////////////////////////////////////////////////////////
//
//  JASPER BLUES
//  Copyright 2012 - 2013 Jasper Blues
//  All Rights Reserved.
//
//  NOTICE: Jasper Blues permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

#import "SXCProject.h"

#import "SXCFileOperationQueue.h"
#import "SXCGroup.h"
#import "SXCProjectBuildConfig.h"
#import "SXCSourceFile.h"
#import "SXCTarget.h"

NSString* const SXCProjectNotFoundException = @"SXCProjectNotFoundException";

@implementation SXCProject

@synthesize fileOperationQueue = _fileOperationQueue;

//-------------------------------------------------------------------------------------------
#pragma mark - Class Methods
//-------------------------------------------------------------------------------------------

+ (instancetype)projectWithFilePath:(NSString*)filePath
{
    return [[self alloc] initWithFilePath:filePath];
}

//-------------------------------------------------------------------------------------------
#pragma mark - Initialization & Destruction
//-------------------------------------------------------------------------------------------

- (instancetype)initWithFilePath:(NSString*)filePath
{
    if ((self = [super init])) {
        _filePath = [filePath copy];
        _dataStorePath = [_filePath stringByAppendingPathComponent:@"project.pbxproj"];

        _dataStore = [[NSMutableDictionary alloc] initWithContentsOfFile:_dataStorePath];
        if (!_dataStore) {
            [NSException raise:SXCProjectNotFoundException format:@"Project file not found at file path %@", _filePath];
        }

        _fileOperationQueue =
            [[SXCFileOperationQueue alloc] initWithBaseDirectory:[_filePath stringByDeletingLastPathComponent]];

    }
    return self;
}

//-------------------------------------------------------------------------------------------
#pragma mark - Interface Methods
//-------------------------------------------------------------------------------------------

#pragma mark Files

- (NSArray*)files
{
    NSMutableArray* results = [NSMutableArray array];
    [self.objects enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSDictionary* obj, BOOL* stop) {
        if ([obj[@"isa"] sxc_hasFileReferenceType]) {
            SXCXcodeFileType fileType = SXCXcodeFileTypeFromStringRepresentation(obj[@"lastKnownFileType"]);
            NSString* path = obj[@"path"];
            NSString* sourceTree = obj[@"sourceTree"];
            SXCSourceFile* sourceFile = [SXCSourceFile sourceFileWithProject:self
                                                                         key:key
                                                                        type:fileType
                                                                        name:path
                                                                  sourceTree:(sourceTree ?: @"<group>")
                                                                        path:nil];
            [results addObject:sourceFile];
        }
    }];
    return results;
}

- (SXCSourceFile*)fileWithKey:(NSString*)key
{
    NSDictionary* obj = self.objects[key];
    if (obj && [obj[@"isa"] sxc_hasFileReferenceOrReferenceProxyType]) {
        SXCXcodeFileType fileType = SXCXcodeFileTypeFromStringRepresentation(obj[@"lastKnownFileType"]);

        NSString* name = obj[@"name"];
        NSString* sourceTree = obj[@"sourceTree"];
        NSString* path = obj[@"path"];

        if (name == nil) {
            name = path;
        }
        return [SXCSourceFile sourceFileWithProject:self
                                                key:key
                                               type:fileType
                                               name:name
                                         sourceTree:(sourceTree ?: @"<group>")
                                               path:path];
    }
    return nil;
}

- (SXCSourceFile*)fileWithName:(NSString*)name
{
    for (SXCSourceFile* projectFile in [self files]) {
        if ([[projectFile name] isEqualToString:name]) {
            return projectFile;
        }
    }
    return nil;
}

- (NSArray*)headerFiles
{
    return [self projectFilesOfType:SXCXcodeFileTypeSourceCodeHeader];
}

- (NSArray*)objectiveCFiles
{
    return [self projectFilesOfType:SXCXcodeFileTypeSourceCodeObjC];
}

- (NSArray*)objectiveCPlusPlusFiles
{
    return [self projectFilesOfType:SXCXcodeFileTypeSourceCodeObjCPlusPlus];
}

- (NSArray*)xibFiles
{
    return [self projectFilesOfType:SXCXcodeFileTypeXibFile];
}

- (NSArray*)imagePNGFiles
{
    return [self projectFilesOfType:SXCXcodeFileTypeImageResourcePNG];
}

// need this value to construct relative path in XcodeprojDefinition
- (NSString*)filePath
{
    return _filePath;
}

//-------------------------------------------------------------------------------------------
#pragma mark Groups
//-------------------------------------------------------------------------------------------

- (NSArray*)groups
{
    NSMutableArray* results = [[NSMutableArray alloc] init];
    [self.objects enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSDictionary* obj, BOOL* stop) {
        if ([obj[@"isa"] sxc_hasGroupType]) {
            SXCGroup* group = _groups[key];
            if (group == nil) {
                group = [self createGroupWithDictionary:obj forKey:key];
                _groups[key] = group;
            }
            [results addObject:group];
        }
    }];
    return results;
}

//TODO: Optimize this implementation.
- (SXCGroup*)rootGroup
{
    for (SXCGroup* group in [self groups]) {
        if ([group isRootGroup]) {
            return group;
        }
    }
    return nil;
}

- (NSArray*)rootGroups
{
    SXCGroup* group = [self rootGroup];
    if (group) {
        return [NSArray arrayWithObject:group];
    }

    NSMutableArray* results = [NSMutableArray array];
    for (SXCGroup* group in [self groups]) {
        if ([group parentGroup] == nil) {
            [results addObject:group];
        }
    }

    return [results copy];
}

- (SXCGroup*)groupWithKey:(NSString*)key
{
    SXCGroup* group = _groups[key];
    if (group) {
        return group;
    }

    NSDictionary* obj = self.objects[key];
    if (obj && [obj[@"isa"] sxc_hasGroupType]) {
        SXCGroup* group = [self createGroupWithDictionary:obj forKey:key];
        _groups[key] = group;

        return group;
    }
    return nil;
}

- (SXCGroup*)groupForGroupMemberWithKey:(NSString*)key
{
    for (SXCGroup* group in [self groups]) {
        if ([group memberWithKey:key]) {
            return group;
        }
    }
    return nil;
}

- (SXCGroup*)groupWithSourceFile:(SXCSourceFile*)sourceFile
{
    for (SXCGroup* group in [self groups]) {
        for (id <SXCXcodeGroupMember> member in [group members]) {
            if ([member isKindOfClass:[SXCSourceFile class]] && [[sourceFile key] isEqualToString:[member key]]) {
                return group;
            }
        }
    }
    return nil;
}

//TODO: This could fail if the path attribute on a given group is more than one directory. Start with candidates and
//TODO: search backwards.
- (SXCGroup*)groupWithPathFromRoot:(NSString*)path
{
    NSArray* pathItems = [path pathComponents];
    SXCGroup* currentGroup = [self rootGroup];
    for (NSString* pathItem in pathItems) {
        id <SXCXcodeGroupMember> group = [currentGroup memberWithDisplayName:pathItem];
        if ([group isKindOfClass:[SXCGroup class]]) {
            currentGroup = group;
        } else {
            return nil;
        }
    }
    return currentGroup;
}

- (SXCGroup*)createGroupWithDictionary:(NSDictionary*)dictionary forKey:(NSString*)key
{
    return [SXCGroup groupWithProject:self
                                 key:key
                               alias:dictionary[@"name"]
                                path:dictionary[@"path"]
                            children:dictionary[@"children"]];
}

//-------------------------------------------------------------------------------------------
#pragma mark targets
//-------------------------------------------------------------------------------------------

- (NSArray*)targets
{
    if (_targets == nil) {
        _targets = [[NSMutableArray alloc] init];
        [self.objects enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSDictionary* obj, BOOL* stop) {
            if ([obj[@"isa"] sxc_hasNativeTargetType]) {
                SXCTarget* target = [SXCTarget targetWithProject:self
                                                           key:key
                                                          name:obj[@"name"]
                                                   productName:obj[@"productName"]
                                              productReference:obj[@"productReference"]];
                [_targets addObject:target];
            }
        }];
    }
    return _targets;
}

- (SXCTarget*)targetWithName:(NSString*)name
{
    for (SXCTarget* target in [self targets]) {
        if ([[target name] isEqualToString:name]) {
            return target;
        }
    }
    return nil;
}

- (void)save
{
    [_fileOperationQueue commitFileOperations];
    [_dataStore writeToFile:_dataStorePath atomically:YES];

    NSLog(@"Saved project");
}

- (NSMutableDictionary*)objects
{
    return _dataStore[@"objects"];
}

- (NSMutableDictionary*)dataStore
{
    return _dataStore;
}

- (void)dropCache
{
    _targets = nil;
    _configurations = nil;
    _rootObjectKey = nil;
}

- (NSDictionary*)configurations
{
    if (_configurations == nil) {
      NSDictionary* objects = self.objects;
        NSString* buildConfigurationRootSectionKey =
            [[objects objectForKey:[self rootObjectKey]] objectForKey:@"buildConfigurationList"];
        NSDictionary* buildConfigurationDictionary = objects[buildConfigurationRootSectionKey];
        NSArray* buildConfigurations = buildConfigurationDictionary[@"buildConfigurations"];
        _configurations =
            [[SXCProjectBuildConfig buildConfigurationsFromArray:buildConfigurations
                                                      inProject:self] mutableCopy];
        _defaultConfigurationName = [buildConfigurationDictionary[@"defaultConfigurationName"] copy];
    }

    return [_configurations copy];
}

- (NSDictionary*)configurationWithName:(NSString*)name
{
    return [[self configurations] objectForKey:name];
}

- (SXCProjectBuildConfig *)defaultConfiguration
{
    return [[self configurations] objectForKey:_defaultConfigurationName];
}

//-------------------------------------------------------------------------------------------
#pragma mark Private
//-------------------------------------------------------------------------------------------

- (NSString*)rootObjectKey
{
    if (_rootObjectKey == nil) {
        _rootObjectKey = [_dataStore[@"rootObject"] copy];
    }

    return _rootObjectKey;
}

- (NSArray*)projectFilesOfType:(SXCXcodeFileType)projectFileType
{
    NSMutableArray* results = [NSMutableArray array];
    for (SXCSourceFile* file in [self files]) {
        if ([file type] == projectFileType) {
            [results addObject:file];
        }
    }
    return results;
}

@end
