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

#import <Foundation/Foundation.h>

#import "SXCXcodeGroupMember.h"

@class SXCClassDefinition;
@class SXCFileOperationQueue;
@class SXCFrameworkDefinition;
@class SXCProject;
@class SXCSourceFile;
@class SXCSourceFileDefinition;
@class SXCSubProjectDefinition;
@class SXCXibDefinition;

/**
* Represents a group container in an Xcode project. A group can contain members of type `XCSourceFile` or other
* groups.
*/
@interface SXCGroup : NSObject <SXCXcodeGroupMember>
{
    NSString* _pathRelativeToParent;
    NSString* _key;
    NSString* _alias;

@private
    NSString* _pathRelativeToProjectRoot;
    NSMutableArray* _children;
    NSMutableArray* _members;

    SXCFileOperationQueue* _fileOperationQueue; // weak
    SXCProject* _project;
}

/**
 * The alias of the group, which can be used to give the group a name other than the last path component.
 *
 * See: [XcodeGroupMember displayName]
 */
@property(nonatomic, strong, readonly) NSString* alias;

/**
 * The path of the group relative to the group's parent.
 *
 * See: [XcodeGroupMember displayName]
*/
@property(nonatomic, strong, readonly) NSString* pathRelativeToParent;

/**
 * The group's unique key.
*/
@property(nonatomic, strong, readonly) NSString* key;

/**
 * An array containing the groups members as `XcodeGroupMember` types.
*/
@property(nonatomic, strong, readonly) NSMutableArray* children;

#pragma mark Initializers

+ (instancetype)groupWithProject:(SXCProject*)project
                             key:(NSString*)key
                           alias:(NSString*)alias
                            path:(NSString*)path
                        children:(NSArray*)children;

#pragma mark Parent group

- (void)removeFromParentGroup;
- (void)removeFromParentDeletingChildren:(BOOL)deleteChildren;

- (SXCGroup*)parentGroup;

- (BOOL)isRootGroup;

#pragma mark Adding children
/**
 * Adds a class to the group, as specified by the ClassDefinition. If the group already contains a class by the same
 * name, the contents will be updated.
*/
- (void)addClass:(SXCClassDefinition*)classDefinition;

/**
 * Adds a class to the group, making it a member of the specified [targets](XCTarget).
*/
- (void)addClass:(SXCClassDefinition*)classDefinition toTargets:(NSArray*)targets;

/**
* Adds a framework to the group. If the group already contains the framework, the contents will be updated if the
* framework definition's copyToDestination flag is yes, otherwise it will be ignored.
*/
- (void)addFramework:(SXCFrameworkDefinition*)frameworkDefinition;

/**
* Adds a group with a path relative to this group.
*/
- (SXCGroup*)addGroupWithPath:(NSString*)path;

/**
* Adds a reference to a folder
*/
- (void)addFolderReference:(NSString*)sourceFolder;

/**
* Adds a framework to the group, making it a member of the specified targets.
*/
- (void)addFramework:(SXCFrameworkDefinition*)framework toTargets:(NSArray*)targets;

/**
* Adds a source file of arbitrary type - image resource, header, etc.
*/
- (void)addSourceFile:(SXCSourceFileDefinition*)sourceFileDefinition;

/**
 * Adds a xib file to the group. If the group already contains a class by the same name, the contents will be updated.
*/
- (void)addXib:(SXCXibDefinition*)xibDefinition;

/**
 * Adds a xib to the group, making it a member of the specified [targets](XCTarget).
*/
- (void)addXib:(SXCXibDefinition*)xibDefinition toTargets:(NSArray*)targets;

/**
 * Adds a sub-project to the group. If the group already contains a sub-project by the same name, the contents will be
 * updated.
 * Returns boolean success/fail; if method fails, caller should assume that project file is corrupt (or file format has
 * changed).
*/
- (void)addSubProject:(SXCSubProjectDefinition*)projectDefinition;

/**
* Adds a sub-project to the group, making it a member of the specified [targets](XCTarget).
*/
- (void)addSubProject:(SXCSubProjectDefinition*)projectDefinition toTargets:(NSArray*)targets;

- (void)removeSubProject:(SXCSubProjectDefinition*)projectDefinition;

- (void)removeSubProject:(SXCSubProjectDefinition*)projectDefinition fromTargets:(NSArray*)targets;

#pragma mark Locating children

/**
 * Instances of `XCSourceFile` and `XCGroup` returned as the type `XcodeGroupMember`.
*/
- (NSArray*)members;

/**
* Instances of `XCSourceFile` from this group and any child groups.
*/
- (NSArray*)recursiveMembers;

- (NSArray*)buildFileKeys;

/**
 * Returns the child with the specified key, or nil.
*/
- (id <SXCXcodeGroupMember>)memberWithKey:(NSString*)key;

/**
* Returns the child with the specified name, or nil.
*/
- (id <SXCXcodeGroupMember>)memberWithDisplayName:(NSString*)name;

@end
