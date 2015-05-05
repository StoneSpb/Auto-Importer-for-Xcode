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

#import "XCTarget.h"

#import "XCGroup.h"
#import "XCKeyBuilder.h"
#import "XCSourceFile.h"
#import "XCProject.h"
#import "XCProjectBuildConfig.h"

@interface XCTarget ()

@property(nonatomic, strong, readonly) NSMutableDictionary* targetObject;

@end

@implementation XCTarget

/* ================================================================================================================== */
#pragma mark - Class Methods

+ (instancetype)targetWithProject:(XCProject*)project
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

- (instancetype)initWithProject:(XCProject*)project
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

/* ====================================================================================================================================== */
#pragma mark - Interface Methods

- (NSArray*)resources
{
    if (_resources == nil) {
        _resources = [[NSMutableArray alloc] init];
        NSDictionary* objects = _project.objects;
        for (NSString* buildPhaseKey in objects[_key][@"buildPhases"]) {
            NSDictionary* buildPhase = objects[buildPhaseKey];
            if ([buildPhase[@"isa"] xce_hasResourcesBuildPhaseType]) {
                for (NSString* buildFileKey in buildPhase[@"files"]) {
                    XCSourceFile* targetMember = [self buildFileWithKey:buildFileKey];
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
            [[XCProjectBuildConfig buildConfigurationsFromArray:buildConfigurationDictionary[@"buildConfigurations"]
                                                      inProject:_project] mutableCopy];
        _defaultConfigurationName = [buildConfigurationDictionary[@"defaultConfigurationName"] copy];
    }

    return [_configurations copy];
}

- (XCProjectBuildConfig *)defaultConfiguration
{
    return [self configurations][_defaultConfigurationName];
}

- (XCProjectBuildConfig *)configurationWithName:(NSString*)name
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
            if ([buildPhase[@"isa"] xce_hasSourcesOrFrameworksBuildPhaseType]) {
                for (NSString* buildFileKey in buildPhase[@"files"]) {
                    XCSourceFile* targetMember = [self buildFileWithKey:buildFileKey];
                    if (targetMember) {
                        [_members addObject:[_project fileWithKey:targetMember.key]];
                    }
                }
            }
        }
    }
    return _members;
}

- (void)addMember:(XCSourceFile*)member
{
    [member becomeBuildFile];
    NSDictionary* objects = _project.objects;
    NSDictionary* target = objects[_key];

    for (NSString* buildPhaseKey in target[@"buildPhases"]) {
        NSMutableDictionary* buildPhase = objects[buildPhaseKey];
        if ([buildPhase[@"isa"] xce_asMemberType] == [member buildPhase]) {
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
        if ([obj[@"isa"] xce_hasBuildFileType]) {
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
        [XCProjectBuildConfig duplicatedBuildConfigurationListWithKey:buildConfigurationListKey
                                                            inProject:_project
                                        withBuildConfigurationVisitor:visitor];

    [self duplicateProductReferenceForTargetObject:dupTargetObj withProductName:productName];

    [self duplicateBuildPhasesForTargetObject:dupTargetObj];

    [self addReferenceToProductsGroupForTargetObject:dupTargetObj];

    NSString* dupTargetObjKey = [self addTargetToRootObjectTargets:dupTargetObj];

    [_project dropCache];

    return [[XCTarget alloc] initWithProject:_project
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

/* ====================================================================================================================================== */
#pragma mark - Utility Methods

- (NSString*)description
{
    return [NSString stringWithFormat:@"Target: name=%@, files=%@", _name, _members];
}

/* ====================================================================================================================================== */
#pragma mark - Private Methods

- (NSMutableDictionary*)targetObject {
    return _project.objects[_key];
}

- (XCSourceFile*)buildFileWithKey:(NSString*)theKey
{
    NSDictionary* obj = _project.objects[theKey];
    if (obj) {
        if ([obj[@"isa"] xce_hasBuildFileType]) {
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

    NSString* dupProductReferenceKey = [[XCKeyBuilder createUnique] build];

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
            NSString* dupFileKey = [[XCKeyBuilder createUnique] build];

            objects[dupFileKey] = dupFile;
            [dupFiles addObject:dupFileKey];
        }

        dupBuildPhase[@"files"] = dupFiles;

        NSString* dupBuildPhaseKey = [[XCKeyBuilder createUnique] build];
        objects[dupBuildPhaseKey] = dupBuildPhase;
        [buildPhases addObject:dupBuildPhaseKey];
    }

    dupTargetObj[@"buildPhases"] = buildPhases;
}

- (void)addReferenceToProductsGroupForTargetObject:(NSMutableDictionary*)dupTargetObj
{
    XCGroup* mainGroup = nil;
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
    NSString* dupTargetObjKey = [[XCKeyBuilder createUnique] build];
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
