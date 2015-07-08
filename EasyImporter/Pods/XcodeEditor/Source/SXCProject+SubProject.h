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

#import "SXCProject.h"

#import <Foundation/Foundation.h>

@interface SXCProject (SubProject)

- (NSString *)referenceProxyKeyForName:(NSString *)name;

- (NSArray *)buildProductsForTargets:(NSString *)xcodeprojKey;

- (void)addAsTargetDependency:(SXCSubProjectDefinition *)xcodeprojDefinition toTargets:(NSArray *)targets;

- (NSArray *)keysForProjectObjectsOfType:(SXCXcodeMemberType)memberType
                          withIdentifier:(NSString *)identifier
                               singleton:(BOOL)singleton
                                required:(BOOL)required;

- (NSMutableDictionary *)PBXProjectDict;

- (void)removeProxies:(NSString *)xcodeprojKey;
- (void)addProxies:(SXCSubProjectDefinition *)xcodeproj;

- (void)removeFromProjectReferences:(NSString *)key forProductsGroup:(NSString *)productsGroupKey;

- (void)removeTargetDependencies:(NSString *)name;

- (NSString *)containerItemProxyKeyForName:(NSString *)name proxyType:(NSString *)proxyType;

- (NSString *)productsGroupKeyForKey:(NSString *)key;

@end
