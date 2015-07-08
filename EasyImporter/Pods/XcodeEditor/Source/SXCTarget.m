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

#import "SXCTarget.h"

#import "SXCGroup.h"
#import "SXCKeyBuilder.h"
#import "SXCProject.h"
#import "SXCProjectBuildConfig.h"
#import "SXCSourceFile.h"

@interface SXCTarget ()

@property(nonatomic, strong, readonly) NSMutableDictionary* targetObject;

@end

@implementation SXCTarget

/* ================================================================================================================== */
#pragma mark - Class Methods

+ (instancetype)targetWithProject:(SXCProject*)project
                              key:(NSString*)key
                             name:(NSString*)name
                      productName:(NSString*)productName
                 productReference:(NSString*)productReference
{
    return [[self alloc] initWithProject:project
                                     key:key
                                    name:name
                             productName:productName
                        productReference:productReference];
}


/* ================================================================================================================== */
#pragma mark - Initialization & Destruction

- (instancetype)initWithProject:(SXCProject*)project
                            key:(NSString*)key
                           name:(NSString*)name
                    productName:(NSString*)productName
               productReference:(NSString*)productReference
{
    self = [super init];
    if (self) {
        _project = project;
        _key = [key copy];
        _name = [name copy];
        _productName = [productName copy];
        _productReference = [productReference copy];
    }
    return self;
}

/* ================================================================================================================== */
#pragma mark - Interface Methods

- (NSArray*)resources
{
    if (_resources == nil) {
        _resources = [[NSMutableArray alloc] init];
        NSDictionary* objects = _project.objects;
        for (NSString* buildPhaseKey in objects[_key][@"buildPhases"]) {
            NSDictionary* buildPhase = objects[buildPhaseKey];
            if ([buildPhase[@"isa"] sxc_hasResourcesBuildPhaseType]) {
                for (NSString* buildFileKey in buildPhase[@"files"]) {
                    SXCSourceFile* targetMember = [self buildFileWithKey:buildFileKey];
                    if (targetMember) {
                        [_resources addObject:targetMember];
                    }
                }
            }
        }
    }

    return [_resources copy];
}

- (NSDictionary*)configurations
{
    if (_configurations == nil) {
        NSDictionary* objects = _project.objects;
        NSString* buildConfigurationRootSectionKey = objects[_key][@"buildConfigurationList"];
        NSDictionary* buildConfigurationDictionary = objects[buildConfigurationRootSectionKey];
        _configurations =
            [[SXCProjectBuildConfig buildConfigurationsFromArray:buildConfigurationDictionary[@"buildConfigurations"]
                                                      inProject:_project] mutableCopy];
        _defaultConfigurationName = [buildConfigurationDictionary[@"defaultConfigurationName"] copy];
    }

    return [_configurations copy];
}

- (SXCProjectBuildConfig *)defaultConfiguration
{
    return [self configurations][_defaultConfigurationName];
}

- (SXCProjectBuildConfig *)configurationWithName:(NSString*)name
{
    return [self configurations][name];
}

- (NSArray*)members
{
    if (_members == nil) {
        _members = [[NSMutableArray alloc] init];
        NSDictionary* objects = _project.objects;
        for (NSString* buildPhaseKey in objects[_key][@"buildPhases"]) {
            NSDictionary* buildPhase = objects[buildPhaseKey];
            if ([buildPhase[@"isa"] sxc_hasSourcesOrFrameworksBuildPhaseType]) {
                for (NSString* buildFileKey in buildPhase[@"files"]) {
                    SXCSourceFile* targetMember = [self buildFileWithKey:buildFileKey];
                    if (targetMember) {
                        [_members addObject:[_project fileWithKey:targetMember.key]];
                    }
                }
            }
        }
    }
    return _members;
}

- (void)addMember:(SXCSourceFile*)member
{
    [member becomeBuildFile];
    NSDictionary* objects = _project.objects;
    NSDictionary* target = objects[_key];

    for (NSString* buildPhaseKey in target[@"buildPhases"]) {
        NSMutableDictionary* buildPhase = objects[buildPhaseKey];
        if ([buildPhase[@"isa"] sxc_asMemberType] == [member buildPhase]) {
            NSMutableArray* files = buildPhase[@"files"];
            NSString* buildFileKey = [member buildFileKey];
            if (![files containsObject:buildFileKey]) {
                [files addObject:buildFileKey];
            }

            buildPhase[@"files"] = files;
        }
    }
    [self flagMembersAsDirty];
}

- (NSDictionary*)buildRefWithFileRefKey
{
    NSMutableDictionary* buildRefWithFileRefDict = [[NSMutableDictionary alloc] init];
    NSDictionary* objects = _project.objects;

    for (NSString* key in [objects keyEnumerator]) {
        NSDictionary* obj = objects[key];
        if ([obj[@"isa"] sxc_hasBuildFileType]) {
            NSString* fileRef = obj[@"fileRef"];
            if (fileRef) {
                buildRefWithFileRefDict[fileRef] = key;
            }
        }
    }
    return [buildRefWithFileRefDict copy];
}

- (void)removeMemberWithKey:(NSString*)key
{
    NSDictionary* buildRefWithFileRef = [self buildRefWithFileRefKey];
    NSDictionary* objects = _project.objects;
    NSDictionary* target = objects[_key];
    NSString* buildRef = buildRefWithFileRef[key];
    if (!buildRef) {
        return;
    }

    for (NSString* buildPhaseKey in target[@"buildPhases"]) {
        NSMutableDictionary* buildPhase = objects[buildPhaseKey];
        NSMutableArray* files = buildPhase[@"files"];

        [files removeObjectIdenticalTo:buildRef];
        buildPhase[@"files"] = files;
    }
    [self flagMembersAsDirty];
}

- (void)removeMembersWithKeys:(NSArray*)keys
{
    for (NSString* key in keys) {
        [self removeMemberWithKey:key];
    }
}

- (void)addDependency:(NSString*)key
{
    NSMutableArray* dependencies = self.targetObject[@"dependencies"];
    // add only if not already there
    BOOL found = NO;
    for (NSString* dependency in dependencies) {
        if ([dependency isEqualToString:key]) {
            found = YES;
            break;
        }
    }
    if (!found) {
        [dependencies addObject:key];
    }
}

- (instancetype)duplicateWithTargetName:(NSString*)targetName productName:(NSString*)productName
{
    NSMutableDictionary* dupTargetObj = [self.targetObject mutableCopy];

    dupTargetObj[@"name"] = targetName;
    dupTargetObj[@"productName"] = productName;

    NSString* buildConfigurationListKey = dupTargetObj[@"buildConfigurationList"];

    void(^visitor)(NSMutableDictionary*) = ^(NSMutableDictionary* buildConfiguration) {
        buildConfiguration[@"buildSettings"][@"PRODUCT_NAME"] = productName;
    };

    dupTargetObj[@"buildConfigurationList"] =
        [SXCProjectBuildConfig duplicatedBuildConfigurationListWithKey:buildConfigurationListKey
                                                            inProject:_project
                                        withBuildConfigurationVisitor:visitor];

    [self duplicateProductReferenceForTargetObject:dupTargetObj withProductName:productName];

    [self duplicateBuildPhasesForTargetObject:dupTargetObj];

    [self addReferenceToProductsGroupForTargetObject:dupTargetObj];

    NSString* dupTargetObjKey = [self addTargetToRootObjectTargets:dupTargetObj];

    [_project dropCache];

    return [[SXCTarget alloc] initWithProject:_project
                                          key:dupTargetObjKey
                                         name:targetName
                                  productName:productName
                             productReference:dupTargetObj[@"productReference"]];
}

/* ================================================================================================================== */
#pragma mark - Overridden Methods

- (void)setName:(NSString*)name
{
    _name = name;
    self.targetObject[@"name"] = _name;
}

- (void)setProductName:(NSString*)productName
{
    _productName = productName;
    self.targetObject[@"productName"] = _productName;
}

/* ================================================================================================================== */
#pragma mark - Utility Methods

- (NSString*)description
{
    return [NSString stringWithFormat:@"Target: name=%@, files=%@", _name, _members];
}

/* ================================================================================================================== */
#pragma mark - Private Methods

- (NSMutableDictionary*)targetObject {
    return _project.objects[_key];
}

- (SXCSourceFile*)buildFileWithKey:(NSString*)theKey
{
    NSDictionary* obj = _project.objects[theKey];
    if (obj) {
        if ([obj[@"isa"] sxc_hasBuildFileType]) {
            return [_project fileWithKey:obj[@"fileRef"]];
        }
    }
    return nil;
}

- (void)flagMembersAsDirty
{
    _members = nil;
}

- (void)duplicateProductReferenceForTargetObject:(NSMutableDictionary*)dupTargetObj
                                 withProductName:(NSString*)productName
{
    NSMutableDictionary* objects = _project.objects;
    NSString* productReferenceKey = dupTargetObj[@"productReference"];
    NSMutableDictionary* dupProductReference = [objects[productReferenceKey] mutableCopy];

    NSString* path = dupProductReference[@"path"];
    NSString* dupPath = [path stringByDeletingLastPathComponent];
    dupPath = [dupPath stringByAppendingPathComponent:productName];
    dupPath = [dupPath stringByAppendingPathExtension:@"app"];
    dupProductReference[@"path"] = dupPath;

    NSString* dupProductReferenceKey = [[SXCKeyBuilder createUnique] build];

    objects[dupProductReferenceKey] = dupProductReference;
    dupTargetObj[@"productReference"] = dupProductReferenceKey;
}

- (void)duplicateBuildPhasesForTargetObject:(NSMutableDictionary*)dupTargetObj
{
    NSMutableArray* buildPhases = [NSMutableArray array];
    NSMutableDictionary* objects = _project.objects;

    for (NSString* buildPhaseKey in dupTargetObj[@"buildPhases"]) {
        NSMutableDictionary* dupBuildPhase = [objects[buildPhaseKey] mutableCopy];
        NSMutableArray* dupFiles = [NSMutableArray array];

        for (NSString* fileKey in dupBuildPhase[@"files"]) {
            NSMutableDictionary* dupFile = [objects[fileKey] mutableCopy];
            NSString* dupFileKey = [[SXCKeyBuilder createUnique] build];

            objects[dupFileKey] = dupFile;
            [dupFiles addObject:dupFileKey];
        }

        dupBuildPhase[@"files"] = dupFiles;

        NSString* dupBuildPhaseKey = [[SXCKeyBuilder createUnique] build];
        objects[dupBuildPhaseKey] = dupBuildPhase;
        [buildPhases addObject:dupBuildPhaseKey];
    }

    dupTargetObj[@"buildPhases"] = buildPhases;
}

- (void)addReferenceToProductsGroupForTargetObject:(NSMutableDictionary*)dupTargetObj
{
    SXCGroup* mainGroup = nil;
    NSPredicate* productsPredicate = [NSPredicate predicateWithFormat:@"displayName == 'Products'"];
    NSArray* filteredGroups = [_project.groups filteredArrayUsingPredicate:productsPredicate];

    if (filteredGroups.count > 0) {
        mainGroup = filteredGroups[0];
        NSMutableDictionary* mainGroupDictionary = _project.objects[mainGroup.key];
        NSMutableArray* children = [mainGroupDictionary[@"children"] mutableCopy];
        [children addObject:dupTargetObj[@"productReference"]];
        mainGroupDictionary[@"children"] = children;
    }
}

- (NSString*)addTargetToRootObjectTargets:(NSMutableDictionary*)dupTargetObj
{
    NSString* dupTargetObjKey = [[SXCKeyBuilder createUnique] build];
    NSMutableDictionary* objects = _project.objects;

    objects[dupTargetObjKey] = dupTargetObj;

    NSString* rootObjKey = _project.dataStore[@"rootObject"];
    NSMutableDictionary* rootObj = [objects[rootObjKey] mutableCopy];
    NSMutableArray* rootObjTargets = [rootObj[@"targets"] mutableCopy];
    [rootObjTargets addObject:dupTargetObjKey];

    rootObj[@"targets"] = rootObjTargets;
    objects[rootObjKey] = rootObj;

    return dupTargetObjKey;
}

@end
