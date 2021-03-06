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

@class SXCProject;
@class SXCProjectBuildConfig;
@class SXCSourceFile;

/**
* Represents a target in an xcode project.
*/
@interface SXCTarget : NSObject
{
    SXCProject* _project;
    NSString* _key;
    NSString* _name;
    NSString* _productName;
    NSString* _productReference;
    NSString* _defaultConfigurationName;

@private
    NSMutableArray* _members;
    NSMutableArray* _resources;
    NSMutableDictionary* _configurations;
}

@property(nonatomic, strong, readonly) NSString* key;
@property(nonatomic, strong) NSString* name;
@property(nonatomic, strong) NSString* productName;
@property(nonatomic, strong, readonly) NSString* productReference;

+ (instancetype)targetWithProject:(SXCProject*)project
                              key:(NSString*)key
                             name:(NSString*)name
                      productName:(NSString*)productName
                 productReference:(NSString*)productReference;

- (NSArray*)resources;

- (NSArray*)members;

- (NSDictionary*)configurations;
- (SXCProjectBuildConfig *)configurationWithName:(NSString*)name;
- (SXCProjectBuildConfig *)defaultConfiguration;

- (void)addMember:(SXCSourceFile*)member;
- (void)removeMemberWithKey:(NSString*)key;
- (void)removeMembersWithKeys:(NSArray*)keys;

- (void)addDependency:(NSString*)key;

- (instancetype)duplicateWithTargetName:(NSString*)targetName productName:(NSString*)productName;

@end
