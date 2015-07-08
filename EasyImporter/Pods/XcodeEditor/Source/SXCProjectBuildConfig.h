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

@interface SXCProjectBuildConfig : NSObject
{
@private
    __weak SXCProject* _project;
    NSString* _key;

    NSMutableDictionary* _buildSettings;
    NSMutableDictionary* _xcconfigSettings;
}

@property(nonatomic, readonly) NSDictionary* specifiedBuildSettings;

+ (NSDictionary*)buildConfigurationsFromArray:(NSArray*)array inProject:(SXCProject*)project;

- (instancetype)initWithProject:(SXCProject*)project key:(NSString*)key;

- (void)addBuildSettings:(NSDictionary*)buildSettings;
- (void)addOrReplaceSetting:(id <NSCopying>)setting forKey:(NSString*)key;

- (id <NSCopying>)valueForKey:(NSString*)key;

+ (NSString*)duplicatedBuildConfigurationListWithKey:(NSString*)buildConfigurationListKey
                                           inProject:(SXCProject*)project
                       withBuildConfigurationVisitor:(void (^)(NSMutableDictionary*))buildConfigurationVisitor;

@end
