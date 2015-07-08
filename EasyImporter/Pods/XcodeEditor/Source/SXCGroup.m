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

#import "SXCGroup.h"

#import "SXCClassDefinition.h"
#import "SXCFileOperationQueue.h"
#import "SXCFrameworkDefinition.h"
#import "SXCProject+SubProject.h"
#import "SXCProject.h"
#import "SXCSourceFile.h"
#import "SXCSourceFileDefinition.h"
#import "SXCSubProjectDefinition.h"
#import "SXCTarget.h"
#import "SXCXibDefinition.h"
#import "Utils/SXCKeyBuilder.h"

@implementation SXCGroup

//-------------------------------------------------------------------------------------------
#pragma mark - Class Methods
//-------------------------------------------------------------------------------------------

+ (instancetype)groupWithProject:(SXCProject*)project
                             key:(NSString*)key
                           alias:(NSString*)alias
                            path:(NSString*)path
                        children:(NSArray*)children
{
    return [[self alloc] initWithProject:project key:key alias:alias path:path children:children];
}

//-------------------------------------------------------------------------------------------
#pragma mark - Initialization & Destruction
//-------------------------------------------------------------------------------------------

- (instancetype)initWithProject:(SXCProject*)project
                            key:(NSString*)key
                          alias:(NSString*)alias
                           path:(NSString*)path
                       children:(NSArray*)children
{
    self = [super init];
    if (self)
    {
        _project = project;
        _fileOperationQueue = [_project fileOperationQueue];
        _key = [key copy];
        _alias = [alias copy];
        _pathRelativeToParent = [path copy];

        _children = [children mutableCopy];
        if (!_children)
        {
            _children = [[NSMutableArray alloc] init];
        }
    }
    return self;
}

//-------------------------------------------------------------------------------------------
#pragma mark - Interface Methods
//-------------------------------------------------------------------------------------------

#pragma mark Parent group

- (void)removeFromParentGroup
{
    [self removeFromParentDeletingChildren:NO];
}

- (void)removeFromParentDeletingChildren:(BOOL)deleteChildren
{
    if (deleteChildren)
    {
        [_fileOperationQueue queueDeletion:[self pathRelativeToProjectRoot]];
    }

    [_project.objects removeObjectForKey:_key];

    for (SXCTarget* target in [_project targets])
    {
        [target removeMembersWithKeys:[self recursiveMembers]];
    }
}

- (SXCGroup*)parentGroup
{
    return [_project groupForGroupMemberWithKey:_key];
}

- (BOOL)isRootGroup
{
    return [self pathRelativeToParent] == nil && [self displayName] == nil;
}

//-------------------------------------------------------------------------------------------
#pragma mark Adding children

- (void)addClass:(SXCClassDefinition*)classDefinition
{
    if ([classDefinition header])
    {
        [self makeGroupMemberWithName:[classDefinition headerFileName]
                             contents:[classDefinition header]
                                 type:SXCXcodeFileTypeSourceCodeHeader
                   fileOperationStyle:[classDefinition fileOperationType]];
    }

    if ([classDefinition isObjectiveC])
    {
        [self makeGroupMemberWithName:[classDefinition sourceFileName]
                             contents:[classDefinition source]
                                 type:SXCXcodeFileTypeSourceCodeObjC
                   fileOperationStyle:[classDefinition fileOperationType]];
    }
    else if ([classDefinition isObjectiveCPlusPlus])
    {
        [self makeGroupMemberWithName:[classDefinition sourceFileName]
                             contents:[classDefinition source]
                                 type:SXCXcodeFileTypeSourceCodeObjCPlusPlus
                   fileOperationStyle:[classDefinition fileOperationType]];
    }

    _project.objects[_key] = [self asDictionary];
}

- (void)addClass:(SXCClassDefinition*)classDefinition toTargets:(NSArray*)targets
{
    [self addClass:classDefinition];
    SXCSourceFile* sourceFile = [_project fileWithName:[classDefinition sourceFileName]];
    [self addSourceFile:sourceFile toTargets:targets];
}

- (void)addFramework:(SXCFrameworkDefinition*)frameworkDefinition
{
    NSMutableDictionary* objects = _project.objects;
    if (([self memberWithDisplayName:[frameworkDefinition name]]) == nil)
    {
        NSDictionary* fileReference;
        if ([frameworkDefinition copyToDestination])
        {
            fileReference = [self makeFileReferenceWithPath:[frameworkDefinition name]
                                                       name:nil
                                                       type:SXCXcodeFileTypeFramework];
            BOOL copyFramework = NO;
            if ([frameworkDefinition fileOperationType] == SXCFileOperationTypeOverwrite)
            {
                copyFramework = YES;
            }
            else if ([frameworkDefinition fileOperationType] == SXCFileOperationTypeAcceptExisting)
            {
                NSString* frameworkName = [[frameworkDefinition filePath] lastPathComponent];
                if (![_fileOperationQueue fileWithName:frameworkName
                              existsInProjectDirectory:[self pathRelativeToProjectRoot]])
                {
                    copyFramework = YES;
                }

            }
            if (copyFramework)
            {
                [_fileOperationQueue queueFrameworkWithFilePath:[frameworkDefinition filePath]
                                                    inDirectory:[self pathRelativeToProjectRoot]];
            }
        }
        else
        {
            NSString* path = [frameworkDefinition filePath];
            NSString* name = [frameworkDefinition name];
            fileReference = [self makeFileReferenceWithPath:path name:name type:SXCXcodeFileTypeFramework];
        }
        NSString* frameworkKey = [[SXCKeyBuilder forItemNamed:[frameworkDefinition name]] build];
        objects[frameworkKey] = fileReference;
        [self addMemberWithKey:frameworkKey];
    }
    objects[_key] = [self asDictionary];
}

- (void)addFramework:(SXCFrameworkDefinition*)frameworkDefinition toTargets:(NSArray*)targets
{
    [self addFramework:frameworkDefinition];
    SXCSourceFile* frameworkSourceRef = (SXCSourceFile*) [self memberWithDisplayName:[frameworkDefinition name]];
    [self addSourceFile:frameworkSourceRef toTargets:targets];
}

- (void)addFolderReference:(NSString*)sourceFolder {
    NSString* folderName = [sourceFolder lastPathComponent];
    NSDictionary *folderReferenceDictionary = [self makeFileReferenceWithPath:sourceFolder
                                                                         name:folderName
                                                                         type:SXCXcodeFileTypeFolder];
    NSString* folderReferenceKey = [[SXCKeyBuilder forItemNamed:[sourceFolder lastPathComponent]] build];
    [self addMemberWithKey:folderReferenceKey];

    NSMutableDictionary* objects = _project.objects;
    objects[folderReferenceKey] = folderReferenceDictionary;
    objects[_key] = [self asDictionary];
}


- (SXCGroup*)addGroupWithPath:(NSString*)path
{
    NSString* groupKeyPath = self.pathRelativeToProjectRoot
                                 ? [self.pathRelativeToProjectRoot stringByAppendingPathComponent:path]
                                 : path;

    NSString* groupKey = [[SXCKeyBuilder forItemNamed:groupKeyPath] build];

    NSArray* members = [self members];
    for (id <SXCXcodeGroupMember> groupMember in members)
    {
        SXCXcodeMemberType groupMemberType = [groupMember groupMemberType];
        if (groupMemberType == SXCXcodeMemberTypePBXGroup ||
            groupMemberType == SXCXcodeMemberTypePBXVariantGroup)
        {

            if ([[[groupMember pathRelativeToProjectRoot] lastPathComponent] isEqualToString:path] ||
                [[groupMember displayName] isEqualToString:path] ||
                [[groupMember key] isEqualToString:groupKey])
            {
                return nil;
            }
        }
    }

    SXCGroup* group = [[SXCGroup alloc] initWithProject:_project key:groupKey alias:nil path:path children:nil];
    NSDictionary* groupDict = [group asDictionary];

    NSMutableDictionary* objects = _project.objects;
    objects[groupKey] = groupDict;
    [_fileOperationQueue queueDirectory:path inDirectory:[self pathRelativeToProjectRoot]];
    [self addMemberWithKey:groupKey];

    NSDictionary* dict = [self asDictionary];
    objects[_key] = dict;

    return group;
}

- (void)addSourceFile:(SXCSourceFileDefinition*)sourceFileDefinition
{
    [self makeGroupMemberWithName:[sourceFileDefinition sourceFileName]
                         contents:[sourceFileDefinition data]
                             type:[sourceFileDefinition type]
               fileOperationStyle:[sourceFileDefinition fileOperationType]];
    _project.objects[_key] = [self asDictionary];
}

- (void)addXib:(SXCXibDefinition*)xibDefinition
{
    [self makeGroupMemberWithName:[xibDefinition xibFileName]
                         contents:[xibDefinition content]
                             type:SXCXcodeFileTypeXibFile
               fileOperationStyle:[xibDefinition fileOperationType]];
    _project.objects[_key] = [self asDictionary];
}

- (void)addXib:(SXCXibDefinition*)xibDefinition toTargets:(NSArray*)targets
{
    [self addXib:xibDefinition];
    SXCSourceFile* sourceFile = [_project fileWithName:[xibDefinition xibFileName]];
    [self addSourceFile:sourceFile toTargets:targets];
}

// adds an xcodeproj as a subproject of the current project.
- (void)addSubProject:(SXCSubProjectDefinition*)projectDefinition
{
    // set up path to the xcodeproj file as Xcode sees it - path to top level of project + group path if any
    [projectDefinition setFullProjectPath:_project.filePath groupPath:[self pathRelativeToParent]];

    // create PBXFileReference for xcodeproj file and add to PBXGroup for the current group
    // (will retrieve existing if already there)
    [self makeGroupMemberWithName:[projectDefinition projectFileName]
                             path:[projectDefinition pathRelativeToProjectRoot]
                             type:SXCXcodeFileTypeXcodeProject
               fileOperationStyle:[projectDefinition fileOperationType]];
    _project.objects[_key] = [self asDictionary];

    // create PBXContainerItemProxies and PBXReferenceProxies
    [_project addProxies:projectDefinition];

    // add projectReferences key to PBXProject
    [self addProductsGroupToProject:projectDefinition];
}

// adds an xcodeproj as a subproject of the current project, and also adds all build products except for test bundle(s)
// to targets.
- (void)addSubProject:(SXCSubProjectDefinition*)projectDefinition toTargets:(NSArray*)targets
{
    [self addSubProject:projectDefinition];

    // add subproject's build products to targets (does not add the subproject's test bundle)
    NSArray* buildProductFiles = [_project buildProductsForTargets:[projectDefinition projectKey]];
    for (SXCSourceFile* file in buildProductFiles)
    {
        [self addSourceFile:file toTargets:targets];
    }
    // add main target of subproject as target dependency to main target of project
    [_project addAsTargetDependency:projectDefinition toTargets:targets];
}

// removes an xcodeproj from the current project.
- (void)removeSubProject:(SXCSubProjectDefinition*)projectDefinition
{
    if (projectDefinition == nil)
    {
        return;
    }

    // set up path to the xcodeproj file as Xcode sees it - path to top level of project + group path if any
    [projectDefinition setFullProjectPath:_project.filePath groupPath:[self pathRelativeToParent]];

    NSString* xcodeprojKey = [projectDefinition projectKey];

    // Remove from group and remove PBXFileReference
    [self removeGroupMemberWithKey:xcodeprojKey];

    // remove PBXContainerItemProxies and PBXReferenceProxies
    [_project removeProxies:xcodeprojKey];

    // get the key for the Products group
    NSString* productsGroupKey = [_project productsGroupKeyForKey:xcodeprojKey];

    // remove from the ProjectReferences array of PBXProject
    [_project removeFromProjectReferences:xcodeprojKey forProductsGroup:productsGroupKey];

    // remove PDXBuildFile entries
    [self removeProductsGroupFromProject:productsGroupKey];

    // remove Products group
    [_project.objects removeObjectForKey:productsGroupKey];

    // remove from all targets
    [_project removeTargetDependencies:[projectDefinition name]];
}

- (void)removeSubProject:(SXCSubProjectDefinition*)projectDefinition fromTargets:(NSArray*)targets
{
    if (projectDefinition == nil)
    {
        return;
    }

    // set up path to the xcodeproj file as Xcode sees it - path to top level of project + group path if any
    [projectDefinition setFullProjectPath:_project.filePath groupPath:[self pathRelativeToParent]];

    NSString* xcodeprojKey = [projectDefinition projectKey];

    // Remove PBXBundleFile entries and corresponding inclusion in PBXFrameworksBuildPhase and PBXResourcesBuidPhase
    NSString* productsGroupKey = [_project productsGroupKeyForKey:xcodeprojKey];
    [self removeProductsGroupFromProject:productsGroupKey];

    // Remove the PBXContainerItemProxy for this xcodeproj with proxyType 1
    NSString* containerItemProxyKey =
        [_project containerItemProxyKeyForName:[projectDefinition pathRelativeToProjectRoot] proxyType:@"1"];
    if (containerItemProxyKey != nil)
    {
        [_project.objects removeObjectForKey:containerItemProxyKey];
    }

    // Remove PBXTargetDependency and entry in PBXNativeTarget
    [_project removeTargetDependencies:[projectDefinition name]];
}

//-------------------------------------------------------------------------------------------
#pragma mark Members

- (NSArray*)members
{
    if (_members == nil)
    {
        _members = [[NSMutableArray alloc] init];
        for (NSString* childKey in _children)
        {
            SXCXcodeMemberType type = [self typeForKey:childKey];

            @autoreleasepool
            {
                if (type == SXCXcodeMemberTypePBXGroup ||
                    type == SXCXcodeMemberTypePBXVariantGroup)
                {
                    [_members addObject:[_project groupWithKey:childKey]];
                }
                else if (type == SXCXcodeMemberTypePBXFileReference)
                {
                    [_members addObject:[_project fileWithKey:childKey]];
                }
            }
        }
    }
    return _members;
}

- (NSArray*)recursiveMembers
{
    NSMutableArray* recursiveMembers = [NSMutableArray array];
    for (NSString* childKey in _children)
    {
        SXCXcodeMemberType type = [self typeForKey:childKey];
        if (type == SXCXcodeMemberTypePBXGroup ||
            type == SXCXcodeMemberTypePBXVariantGroup)
        {
            SXCGroup* group = [_project groupWithKey:childKey];
            NSArray* groupChildren = [group recursiveMembers];
            [recursiveMembers addObjectsFromArray:groupChildren];
        }
        else if (type == SXCXcodeMemberTypePBXFileReference)
        {
            [recursiveMembers addObject:childKey];
        }
    }
    [recursiveMembers addObject:_key];
    return [recursiveMembers arrayByAddingObjectsFromArray:recursiveMembers];
}

- (NSArray*)buildFileKeys
{
    NSMutableArray* arrayOfBuildFileKeys = [NSMutableArray array];
    for (id <SXCXcodeGroupMember> groupMember in [self members])
    {
        SXCXcodeMemberType groupMemberType = [groupMember groupMemberType];
        if (groupMemberType == SXCXcodeMemberTypePBXGroup ||
            groupMemberType == SXCXcodeMemberTypePBXVariantGroup)
        {
            SXCGroup* group = (SXCGroup*) groupMember;
            [arrayOfBuildFileKeys addObjectsFromArray:[group buildFileKeys]];
        }
        else if (groupMemberType == SXCXcodeMemberTypePBXFileReference)
        {
            [arrayOfBuildFileKeys addObject:[groupMember key]];
        }
    }
    return arrayOfBuildFileKeys;
}

- (id <SXCXcodeGroupMember>)memberWithKey:(NSString*)key
{
    id <SXCXcodeGroupMember> groupMember = nil;

    if ([_children containsObject:key])
    {
        SXCXcodeMemberType type = [self typeForKey:key];
        if (type == SXCXcodeMemberTypePBXGroup ||
            type == SXCXcodeMemberTypePBXVariantGroup)
        {
            groupMember = [_project groupWithKey:key];
        }
        else if (type == SXCXcodeMemberTypePBXFileReference)
        {
            groupMember = [_project fileWithKey:key];
        }
    }
    return groupMember;
}

- (id <SXCXcodeGroupMember>)memberWithDisplayName:(NSString*)name
{
    for (id <SXCXcodeGroupMember> member in [self members])
    {
        if ([[member displayName] isEqualToString:name])
        {
            return member;
        }
    }
    return nil;
}

//-------------------------------------------------------------------------------------------
#pragma mark - Protocol Methods

- (SXCXcodeMemberType)groupMemberType
{
    return [self typeForKey:self.key];
}

- (NSString*)displayName
{
    if (_alias)
    {
        return _alias;
    }
    return [_pathRelativeToParent lastPathComponent];
}

- (NSString*)pathRelativeToProjectRoot
{
    if (_pathRelativeToProjectRoot == nil)
    {
        NSMutableArray* pathComponents = [[NSMutableArray alloc] init];
        SXCGroup* group = nil;
        NSString* key = [_key copy];

        while ((group = [_project groupForGroupMemberWithKey:key]) != nil &&
               [group pathRelativeToParent] != nil)
        {
            [pathComponents addObject:[group pathRelativeToParent]];
            key = [[group key] copy];
        }

        NSMutableString* fullPath = [[NSMutableString alloc] init];
        for (NSInteger i = (NSInteger) [pathComponents count] - 1; i >= 0; i--)
        {
            [fullPath appendFormat:@"%@/", pathComponents[i]];
        }
        _pathRelativeToProjectRoot = [[fullPath stringByAppendingPathComponent:_pathRelativeToParent] copy];
    }
    return _pathRelativeToProjectRoot;
}

//-------------------------------------------------------------------------------------------
#pragma mark - Utility Methods

- (NSString*)description
{
    return [NSString stringWithFormat:@"Group: displayName = %@, key=%@", [self displayName], _key];
}

//-------------------------------------------------------------------------------------------
#pragma mark - Private Methods
//-------------------------------------------------------------------------------------------

- (void)addMemberWithKey:(NSString*)key
{
    for (NSString* childKey in _children)
    {
        if ([childKey isEqualToString:key])
        {
            [self flagMembersAsDirty];
            return;
        }
    }
    [_children addObject:key];
    [self flagMembersAsDirty];
}

- (void)flagMembersAsDirty
{
    _members = nil;
}

//-------------------------------------------------------------------------------------------

- (void)makeGroupMemberWithName:(NSString*)name
                       contents:(id)contents
                           type:(SXCXcodeFileType)type
             fileOperationStyle:(SXCFileOperationType)fileOperationStyle
{
    NSString* filePath;
    SXCSourceFile* currentSourceFile = (SXCSourceFile*) [self memberWithDisplayName:name];
    if ((currentSourceFile) == nil)
    {
        NSDictionary* reference = [self makeFileReferenceWithPath:name name:nil type:type];
        NSString* fileKey = [[SXCKeyBuilder forItemNamed:name] build];
        _project.objects[fileKey] = reference;
        [self addMemberWithKey:fileKey];
        filePath = [self pathRelativeToProjectRoot];
    }
    else
    {
        filePath = [[currentSourceFile pathRelativeToProjectRoot] stringByDeletingLastPathComponent];
    }

    BOOL writeFile = NO;
    if (fileOperationStyle == SXCFileOperationTypeOverwrite)
    {
        writeFile = YES;
        [_fileOperationQueue fileWithName:name existsInProjectDirectory:filePath];
    }
    else if (fileOperationStyle == SXCFileOperationTypeAcceptExisting &&
        ![_fileOperationQueue fileWithName:name existsInProjectDirectory:filePath])
    {
        writeFile = YES;
    }
    if (writeFile)
    {
        if ([contents isKindOfClass:[NSString class]])
        {
            [_fileOperationQueue queueTextFile:name inDirectory:filePath withContents:contents];
        }
        else
        {
            [_fileOperationQueue queueDataFile:name inDirectory:filePath withContents:contents];
        }
    }
}

//-------------------------------------------------------------------------------------------

#pragma mark Xcodeproj methods

// creates PBXFileReference and adds to group if not already there;  returns key for file reference.  Locates
// member via path rather than name, because that is how subprojects are stored by Xcode
- (void)makeGroupMemberWithName:(NSString*)name
                           path:(NSString*)path
                           type:(SXCXcodeFileType)type
             fileOperationStyle:(SXCFileOperationType)fileOperationStyle
{
    SXCSourceFile* currentSourceFile = (SXCSourceFile*) [self memberWithDisplayName:name];
    if ((currentSourceFile) == nil)
    {
        NSDictionary* reference = [self makeFileReferenceWithPath:path name:name type:type];
        NSString* fileKey = [[SXCKeyBuilder forItemNamed:name] build];
        _project.objects[fileKey] = reference;
        [self addMemberWithKey:fileKey];
    }
}

// makes a new group called Products and returns its key
- (NSString*)makeProductsGroup:(SXCSubProjectDefinition*)xcodeprojDefinition
{
    NSMutableArray* children = [NSMutableArray array];
    NSString* uniquer = @"";
    for (NSString* productName in [xcodeprojDefinition buildProductNames])
    {
        [children addObject:[_project referenceProxyKeyForName:productName]];
        uniquer = [uniquer stringByAppendingString:productName];
    }
    NSString* productKey = [[SXCKeyBuilder forItemNamed:[NSString stringWithFormat:@"%@-Products", uniquer]] build];
    SXCGroup* productsGroup = [SXCGroup groupWithProject:_project
                                                     key:productKey
                                                   alias:@"Products"
                                                    path:nil
                                                children:children];
    _project.objects[productKey] = [productsGroup asDictionary];
    return productKey;
}

// makes a new Products group (by calling the method above), makes a new projectReferences array for it and
// then adds it to the PBXProject object
- (void)addProductsGroupToProject:(SXCSubProjectDefinition*)xcodeprojDefinition
{
    NSString* productKey = [self makeProductsGroup:xcodeprojDefinition];

    NSMutableDictionary* PBXProjectDict = [_project PBXProjectDict];
    NSMutableArray* projectReferences = [PBXProjectDict valueForKey:@"projectReferences"];

    NSMutableDictionary* newProjectReference = [NSMutableDictionary dictionary];
    newProjectReference[@"ProductGroup"] = productKey;
    NSString* projectFileKey = [[_project fileWithName:[xcodeprojDefinition pathRelativeToProjectRoot]] key];
    newProjectReference[@"ProjectRef"] = projectFileKey;

    if (projectReferences == nil)
    {
        projectReferences = [NSMutableArray array];
    }
    [projectReferences addObject:newProjectReference];
    PBXProjectDict[@"projectReferences"] = projectReferences;
}

// removes PBXFileReference from group and project
- (void)removeGroupMemberWithKey:(NSString*)key
{
    NSMutableArray* children = [self valueForKey:@"children"];
    [children removeObject:key];
    _project.objects[_key] = [self asDictionary];
    // remove PBXFileReference
    [_project.objects removeObjectForKey:key];
}

// removes the given key from the files arrays of the given section, if found (intended to be used with
// PBXFrameworksBuildPhase and PBXResourcesBuildPhase)
// they are not required because we are currently not adding these entries;  Xcode is doing it for us. The existing
// code for adding to a target doesn't do it, and I didn't add it since Xcode will take care of it for me and I was
// avoiding modifying existing code as much as possible)
- (void)removeBuildPhaseFileKey:(NSString*)key forType:(SXCXcodeMemberType)memberType
{
    NSArray* buildPhases = [_project keysForProjectObjectsOfType:memberType
                                                  withIdentifier:nil
                                                       singleton:NO
                                                        required:NO];
    NSDictionary* objects = _project.objects;
    for (NSString* buildPhaseKey in buildPhases)
    {
        NSDictionary* buildPhaseDict = objects[buildPhaseKey];
        NSMutableArray* fileKeys = buildPhaseDict[@"files"];
        for (NSString* fileKey in fileKeys)
        {
            if ([fileKey isEqualToString:key])
            {
                [fileKeys removeObject:fileKey];
            }
        }
    }
}

// removes entries from PBXBuildFiles, PBXFrameworksBuildPhase and PBXResourcesBuildPhase
- (void)removeProductsGroupFromProject:(NSString*)key
{
    NSMutableDictionary* objects = _project.objects;
    // remove product group's build products from PDXBuildFiles
    NSDictionary* productsGroup = objects[key];
    for (NSString* childKey in [productsGroup valueForKey:@"children"])
    {
        NSArray* buildFileKeys = [_project keysForProjectObjectsOfType:SXCXcodeMemberTypePBXBuildFile
                                                        withIdentifier:childKey
                                                             singleton:NO
                                                              required:NO];
        // could be zero - we didn't add the test bundle as a build product
        if ([buildFileKeys count] == 1)
        {
            NSString* buildFileKey = buildFileKeys[0];
            [objects removeObjectForKey:buildFileKey];
            [self removeBuildPhaseFileKey:buildFileKey forType:SXCXcodeMemberTypePBXFrameworksBuildPhase];
            [self removeBuildPhaseFileKey:buildFileKey forType:SXCXcodeMemberTypePBXResourcesBuildPhase];
        }
    }
}

//-------------------------------------------------------------------------------------------

#pragma mark Dictionary Representations

- (NSDictionary*)makeFileReferenceWithPath:(NSString*)path name:(NSString*)name type:(SXCXcodeFileType)type
{
    NSMutableDictionary* reference = [NSMutableDictionary dictionary];
    reference[@"isa"] = [NSString sxc_stringFromMemberType:SXCXcodeMemberTypePBXFileReference];
    reference[@"fileEncoding"] = @"4";
    reference[@"lastKnownFileType"] = SXCNSStringFromSXCXcodeFileType(type);
    if (name != nil)
    {
        reference[@"name"] = [name lastPathComponent];
    }
    if (path != nil)
    {
        reference[@"path"] = path;
    }
    reference[@"sourceTree"] = @"<group>";
    return reference;
}

- (NSDictionary*)asDictionary
{
    NSMutableDictionary* groupData = [NSMutableDictionary dictionary];
    groupData[@"isa"] = [NSString sxc_stringFromMemberType:SXCXcodeMemberTypePBXGroup];
    groupData[@"sourceTree"] = @"<group>";

    if (_alias != nil)
    {
        groupData[@"name"] = _alias;
    }

    if (_pathRelativeToParent)
    {
        groupData[@"path"] = _pathRelativeToParent;
    }

    if (_children)
    {
        groupData[@"children"] = _children;
    }

    return groupData;
}

- (SXCXcodeMemberType)typeForKey:(NSString*)key
{
    NSDictionary* obj = _project.objects[key];
    return [obj[@"isa"] sxc_asMemberType];
}

- (void)addSourceFile:(SXCSourceFile*)sourceFile toTargets:(NSArray*)targets
{
    for (SXCTarget* target in targets)
    {
        [target addMember:sourceFile];
    }
}

@end
