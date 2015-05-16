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

#import "SXCProject+SubProject.h"

#import "SXCSourceFile.h"
#import "SXCSubProjectDefinition.h"
#import "SXCTarget.h"
#import "Utils/SXCKeyBuilder.h"

@implementation SXCProject (SubProject)

#pragma mark sub-project related public methods

// returns the key for the reference proxy with the given path (nil if not found)
// does not use keysForProjectObjectsOfType:withIdentifier: because the identifier it uses for
// PBXReferenceProxy is different.
- (NSString *)referenceProxyKeyForName:(NSString *)name
{
    __block NSString *result = nil;
    [self.objects enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL *stop) {
        if ([obj[@"isa"] sxc_hasReferenceProxyType]) {
            NSString *candidate = obj[@"path"];
            if ([candidate isEqualToString:name]) {
                result = key;
                *stop = YES;
            }
        }
    }];
    return result;
}

// returns an array of build products, excluding bundles with extensions other than ".bundle" (which is kind
// of gross, but I didn't see a better way to exclude test bundles without giving them their own XcodeSourceFileType)
- (NSArray *)buildProductsForTargets:(NSString *)xcodeprojKey
{
    NSMutableArray *results = [[NSMutableArray alloc] init];
    NSMutableDictionary *objects = self.objects;
    [objects enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL *stop) {
        if ([obj[@"isa"] sxc_hasReferenceProxyType]) {
            // make sure it belongs to the xcodeproj we're adding
            NSString *remoteRef = obj[@"remoteRef"];
            NSDictionary *containerProxy = objects[remoteRef];
            NSString *containerPortal = containerProxy[@"containerPortal"];
            if ([containerPortal isEqualToString:xcodeprojKey]) {
                SXCXcodeFileType type = SXCXcodeFileTypeFromStringRepresentation(obj[@"fileType"]);
                NSString *path = (NSString *)obj[@"path"];
                if (type != SXCXcodeFileTypeBundle || [[path pathExtension] isEqualToString:@"bundle"]) {
                    [results addObject:[SXCSourceFile sourceFileWithProject:self
                                                                        key:key
                                                                       type:type
                                                                       name:path
                                                                 sourceTree:nil
                                                                       path:nil]];
                }
            }
        }
    }];
    return results;
}

// makes PBXContainerItemProxy and PBXTargetDependency objects for the xcodeproj, and adds the dependency key
// to all the specified targets
- (void)addAsTargetDependency:(SXCSubProjectDefinition *)xcodeprojDefinition toTargets:(NSArray *)targets
{
    for (SXCTarget *target in targets) {
        // make a new PBXContainerItemProxy
        NSString *key = [[self fileWithName:[xcodeprojDefinition pathRelativeToProjectRoot]] key];
        NSString *containerItemProxyKey = [self makeContainerItemProxyForName:[xcodeprojDefinition name]
                                                                      fileRef:key
                                                                    proxyType:@"1"
                                                                   uniqueName:[target name]];
        // make a PBXTargetDependency
        NSString *targetDependencyKey = [self makeTargetDependency:[xcodeprojDefinition name]
                                          forContainerItemProxyKey:containerItemProxyKey
                                                        uniqueName:[target name]];
        // add entry in each targets dependencies list
        [target addDependency:targetDependencyKey];
    }
}

// returns an array of keys for all project objects (not just files) that match the given criteria.  Since this is
// a convenience method intended to save typing elsewhere, each type has its own field to match to rather than each
// matching on name or path as you might expect.
- (NSArray *)keysForProjectObjectsOfType:(SXCXcodeMemberType)memberType
                          withIdentifier:(NSString *)identifier
                               singleton:(BOOL)singleton
                                required:(BOOL)required
{
    __block NSMutableArray *returnValue = [[NSMutableArray alloc] init];
    [self.objects enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL *stop) {
        if ([obj[@"isa"] sxc_asMemberType] == memberType) {
            if (memberType == SXCXcodeMemberTypePBXContainerItemProxy) {
                if ([obj[@"containerPortal"] isEqualToString:identifier]) {
                    [returnValue addObject:key];
                }
            }
            else if (memberType == SXCXcodeMemberTypePBXReferenceProxy) {
                if ([obj[@"remoteRef"] isEqualToString:identifier]) {
                    [returnValue addObject:key];
                }
            }
            else if (memberType == SXCXcodeMemberTypePBXTargetDependency ||
                     memberType == SXCXcodeMemberTypePBXGroup ||
                     memberType == SXCXcodeMemberTypePBXVariantGroup) {
                if ([obj[@"name"] isEqualToString:identifier]) {
                    [returnValue addObject:key];
                }
            }
            else if (memberType == SXCXcodeMemberTypePBXNativeTarget) {
                for (NSString *dependencyKey in obj[@"dependencies"]) {
                    if ([dependencyKey isEqualToString:identifier]) {
                        [returnValue addObject:key];
                    }
                }
            }
            else if (memberType == SXCXcodeMemberTypePBXBuildFile) {
                if ([obj[@"fileRef"] isEqualToString:identifier]) {
                    [returnValue addObject:key];
                }
            }
            else if (memberType == SXCXcodeMemberTypePBXProject) {
                [returnValue addObject:key];
            }
            else if (memberType == SXCXcodeMemberTypePBXFileReference) {
                if ([obj[@"path"] isEqualToString:identifier]) {
                    [returnValue addObject:key];
                }
            }
            else if (memberType == SXCXcodeMemberTypePBXFrameworksBuildPhase ||
                     memberType == SXCXcodeMemberTypePBXResourcesBuildPhase) {
                [returnValue addObject:key];
            }
            else {
                [NSException raise:NSInvalidArgumentException
                            format:@"Unrecognized member type %@", [NSString sxc_stringFromMemberType:memberType]];
            }
        }
    }];
    if (singleton && [returnValue count] > 1) {
        [NSException raise:NSGenericException
                    format:@"Searched for one instance of member type %@ with value %@, but found %ld",
                           [NSString sxc_stringFromMemberType:memberType], identifier,
                           (unsigned long) [returnValue count]];
    }
    if (required && [returnValue count] == 0) {
        [NSException raise:NSGenericException
                    format:@"Searched for instances of member type %@ with value %@, but did not find any",
                           [NSString sxc_stringFromMemberType:memberType], identifier];
    }
    return returnValue;
}

// returns the dictionary for the PBXProject.  Raises an exception if more or less than 1 are found.
- (NSMutableDictionary *)PBXProjectDict
{
    NSString *PBXProjectKey;
    NSArray *PBXProjectKeys = [self keysForProjectObjectsOfType:SXCXcodeMemberTypePBXProject
                                                 withIdentifier:nil
                                                      singleton:YES
                                                       required:YES];
    PBXProjectKey = [PBXProjectKeys objectAtIndex:0];
    NSMutableDictionary *PBXProjectDict = self.objects[PBXProjectKey];
    return PBXProjectDict;
}

// returns the key of the PBXContainerItemProxy for the given name and proxy type. nil if not found.
- (NSString *)containerItemProxyKeyForName:(NSString *)name proxyType:(NSString *)proxyType
{
    NSMutableArray *results = [[NSMutableArray alloc] init];
    [self.objects enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL *stop) {
        if ([obj[@"isa"] sxc_hasContainerItemProxyType]) {
            NSString *remoteInfo = obj[@"remoteInfo"];
            NSString *proxy = obj[@"proxyType"];
            if ([remoteInfo isEqualToString:name] && [proxy isEqualToString:proxyType]) {
                [results addObject:key];
            }
        }
    }];
    if ([results count] > 1) {
        [NSException raise:NSGenericException
            format:@"Searched for one instance of member type %@ with value %@, but found %ld",
                   @"PBXContainerItemProxy", [NSString stringWithFormat:@"%@ and proxyType of %@", name, proxyType],
                (unsigned long) [results count]];
    }
    if ([results count] == 0) {
        return nil;
    }
    return results[0];
}

//-------------------------------------------------------------------------------------------
#pragma mark - Private Methods
//-------------------------------------------------------------------------------------------

// makes a PBXContainerItemProxy object for a given PBXFileReference object.  Replaces pre-existing objects.
- (NSString *)makeContainerItemProxyForName:(NSString *)name
                                    fileRef:(NSString *)fileRef
                                  proxyType:(NSString *)proxyType
                                 uniqueName:(NSString *)uniqueName
{
    NSString *keyName;
    if (uniqueName != nil) {
        keyName = [NSString stringWithFormat:@"%@-%@", name, uniqueName];
    }
    else {
        keyName = name;
    }

    NSMutableDictionary *objects = self.objects;

    // remove old if it exists
    NSString *existingProxyKey = [self containerItemProxyKeyForName:keyName proxyType:proxyType];
    if (existingProxyKey) {
        [objects removeObjectForKey:existingProxyKey];
    }
    // make new one
    NSMutableDictionary *proxy = [NSMutableDictionary dictionary];
    proxy[@"isa"] = [NSString sxc_stringFromMemberType:SXCXcodeMemberTypePBXContainerItemProxy];
    proxy[@"containerPortal"] = fileRef;
    proxy[@"proxyType"] = proxyType;
    // give it a random key - the keys xcode puts here are not in the project file anywhere else
    NSString *key = [[SXCKeyBuilder forItemNamed:[NSString stringWithFormat:@"%@-junk", keyName]] build];
    proxy[@"remoteGlobalIDString"] = key;
    proxy[@"remoteInfo"] = name;
    // add to project. use proxyType to generate key, so that multiple keys for the same name don't overwrite each other
    key = [[SXCKeyBuilder forItemNamed:[NSString stringWithFormat:@"%@-containerProxy-%@", keyName, proxyType]] build];
    objects[key] = proxy;

    return key;
}

// makes a PBXReferenceProxy object for a given PBXContainerProxy object.  Replaces pre-existing objects.
- (void)makeReferenceProxyForContainerItemProxy:(NSString *)containerItemProxyKey
                          buildProductReference:(NSDictionary *)buildProductReference
{
    NSMutableDictionary *objects = self.objects;
    NSString *path = buildProductReference[@"path"];
    // remove old if any exists
    NSArray *existingProxyKeys = [self keysForProjectObjectsOfType:SXCXcodeMemberTypePBXReferenceProxy
                                                    withIdentifier:path
                                                         singleton:NO
                                                          required:NO];
    if ([existingProxyKeys count] > 0) {
        for (NSString *existingProxyKey in existingProxyKeys) {
            [objects removeObjectForKey:existingProxyKey];
        }
    }
    // make new one
    NSMutableDictionary *proxy = [NSMutableDictionary dictionary];
    proxy[@"isa"] = [NSString sxc_stringFromMemberType:SXCXcodeMemberTypePBXReferenceProxy];
    proxy[@"fileType"] = [buildProductReference valueForKey:@"explicitFileType"];
    proxy[@"path"] = path;
    proxy[@"remoteRef"] = containerItemProxyKey;
    proxy[@"sourceTree"] = [buildProductReference valueForKey:@"sourceTree"];
    // add to project
    NSString *key = [[SXCKeyBuilder forItemNamed:[NSString stringWithFormat:@"%@-referenceProxy", path]] build];
    objects[key] = proxy;
}

// makes a PBXTargetDependency object for a given PBXContainerItemProxy.  Replaces pre-existing objects.
- (NSString *)makeTargetDependency:(NSString *)name
          forContainerItemProxyKey:(NSString *)containerItemProxyKey
                        uniqueName:(NSString *)uniqueName
{
    NSString *keyName;
    if (uniqueName != nil) {
        keyName = [NSString stringWithFormat:@"%@-%@", name, uniqueName];
    }
    else {
        keyName = name;
    }

    NSMutableDictionary *objects = self.objects;

    // remove old if it exists
    NSArray *existingDependencyKeys = [self keysForProjectObjectsOfType:SXCXcodeMemberTypePBXTargetDependency
                                                         withIdentifier:keyName
                                                              singleton:NO
                                                               required:NO];
    if ([existingDependencyKeys count] > 0) {
        for (NSString *existingDependencyKey in existingDependencyKeys) {
            [objects removeObjectForKey:existingDependencyKey];
        }
    }
    // make new one
    NSMutableDictionary *targetDependency = [NSMutableDictionary dictionary];
    targetDependency[@"isa"] = [NSString sxc_stringFromMemberType:SXCXcodeMemberTypePBXTargetDependency];
    targetDependency[@"name"] = name;
    targetDependency[@"targetProxy"] = containerItemProxyKey;
    NSString *targetDependencyKey =
        [[SXCKeyBuilder forItemNamed:[NSString stringWithFormat:@"%@-targetProxy", keyName]] build];
    objects[targetDependencyKey] = targetDependency;
    return targetDependencyKey;
}

// make a PBXContainerItemProxy and PBXReferenceProxy for each target in the subProject
- (void)addProxies:(SXCSubProjectDefinition *)xcodeproj
{
    NSString *fileRef = [[self fileWithName:[xcodeproj pathRelativeToProjectRoot]] key];
    SXCProject *subProject = xcodeproj.subProject;
    NSDictionary *subProjectObjects = subProject.objects;

    for (SXCTarget *target in [subProject targets]) {
        NSString *containerItemProxyKey = [self makeContainerItemProxyForName:target.name
                                                                      fileRef:fileRef
                                                                    proxyType:@"2"
                                                                   uniqueName:nil];
        NSString *productFileReferenceKey = target.productReference;
        NSDictionary *productFileReference = subProjectObjects[productFileReferenceKey];
        [self makeReferenceProxyForContainerItemProxy:containerItemProxyKey buildProductReference:productFileReference];
    }
}

// remove the PBXContainerItemProxy and PBXReferenceProxy objects for the given object key
// (which is the PBXFilereference for the xcodeproj file)
- (void)removeProxies:(NSString *)xcodeprojKey
{
    NSMutableArray *keysToDelete = [[NSMutableArray alloc] init];
    // use the xcodeproj's PBXFileReference key to get the PBXContainerItemProxy keys
    NSArray *containerItemProxyKeys = [self keysForProjectObjectsOfType:SXCXcodeMemberTypePBXContainerItemProxy
                                                         withIdentifier:xcodeprojKey
                                                              singleton:NO
                                                               required:YES];

    // use the PBXContainerItemProxy keys to get the PBXReferenceProxy keys
    for (NSString *key in containerItemProxyKeys) {
        [keysToDelete addObjectsFromArray:[self keysForProjectObjectsOfType:SXCXcodeMemberTypePBXReferenceProxy
                                                             withIdentifier:key
                                                                  singleton:NO
                                                                   required:NO]];
        [keysToDelete addObject:key];
    }

    // remove all objects located above
    NSMutableDictionary *objects = self.objects;
    [keysToDelete enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [objects removeObjectForKey:obj];
    }];
}

// returns the Products group key for the given PBXFileReference key, nil if not found.
- (NSString *)productsGroupKeyForKey:(NSString *)key
{
    NSMutableArray *projectReferences = [[self PBXProjectDict] valueForKey:@"projectReferences"];
    NSString *productsGroupKey = nil;
    for (NSDictionary *projectRef in projectReferences) {
        if ([[projectRef valueForKey:@"ProjectRef"] isEqualToString:key]) {
            // it's an error if we find more than one
            if (productsGroupKey != nil) {
                [NSException raise:NSGenericException format:@"Found more than one project reference for key %@", key];
            }
            productsGroupKey = [projectRef valueForKey:@"ProductGroup"];
        }
    }
    return productsGroupKey;
}

// removes a file reference from the projectReferences array in PBXProject (removing the array itself if this action
// leaves it empty).
- (void)removeFromProjectReferences:(NSString *)key forProductsGroup:(NSString *)productsGroupKey
{
    NSMutableArray *projectReferences = [[self PBXProjectDict] valueForKey:@"projectReferences"];
    // remove entry from PBXProject's projectReferences
    NSMutableArray *referencesToRemove = [NSMutableArray array];
    for (NSDictionary *projectRef in projectReferences) {
        if ([[projectRef valueForKey:@"ProjectRef"] isEqualToString:key]) {
            [referencesToRemove addObject:projectRef];
        }
    }
    for (NSDictionary *projectRef in referencesToRemove) {
        [projectReferences removeObject:projectRef];
    }
    // if that was the last project reference, remove the array from the project
    if ([projectReferences count] == 0) {
        [[self PBXProjectDict] removeObjectForKey:@"projectReferences"];
    }
}

// removes a specific xcodeproj file from any targets (by name).  It's not an error if no entries are found,
// because we support adding a project file without adding it to any targets.
- (void)removeTargetDependencies:(NSString *)name
{
    NSMutableDictionary *objects = self.objects;

    // get the key for the PBXTargetDependency with name = xcodeproj file name (without extension)
    NSArray *targetDependencyKeys = [self keysForProjectObjectsOfType:SXCXcodeMemberTypePBXTargetDependency
                                                       withIdentifier:name
                                                            singleton:NO
                                                             required:NO];

    // we might not find any if the project wasn't added to targets in the first place
    if ([targetDependencyKeys count] == 0) {
        return;
    }
    NSString *targetDependencyKey = targetDependencyKeys[0];

    // use the key for the PBXTargetDependency to get the key for any PBXNativeTargets that depend on it
    NSArray *nativeTargetKeys = [self keysForProjectObjectsOfType:SXCXcodeMemberTypePBXNativeTarget
                                                   withIdentifier:targetDependencyKey
                                                        singleton:NO
                                                         required:NO];

    // remove the key for the PBXTargetDependency from the PBXNativeTarget's dependencies arrays
    // (leave in place even if empty)
    for (NSString *nativeTargetKey in nativeTargetKeys) {
        NSMutableDictionary *nativeTarget = objects[nativeTargetKey];
        NSMutableArray *dependencies = [nativeTarget valueForKey:@"dependencies"];
        [dependencies removeObject:targetDependencyKey];
        nativeTarget[@"dependencies"] = dependencies;
    }
    // remove the PBXTargetDependency
    [objects removeObjectForKey:targetDependencyKey];
}

@end
