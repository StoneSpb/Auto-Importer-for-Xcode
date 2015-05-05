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

#import <Foundation/Foundation.h>

#import "XCAbstractDefinition.h"

typedef enum
{
    ObjectiveC,
    ObjectiveCPlusPlus,
    CPlusPlus,
} ClassDefinitionLanguage;

@interface XCClassDefinition : XCAbstractDefinition
{
    NSString* _className;
    NSString* _header;
    NSString* _source;

@private
    ClassDefinitionLanguage _language;
    NSString* _sourceFileName;
}

@property(strong, nonatomic, readonly) NSString* className;
@property(nonatomic, strong) NSString* header;
@property(nonatomic, strong) NSString* source;

/**
 * Creates a new objective-c class definition.
 */
+ (instancetype)classDefinitionWithName:(NSString*)fileName;

/**
 * Creates a new class definition with the specified language.
 */
+ (instancetype)classDefinitionWithName:(NSString*)className language:(ClassDefinitionLanguage)language;

- (BOOL)isObjectiveC;
- (BOOL)isObjectiveCPlusPlus;
- (BOOL)isCPlusPlus;

@property(nonatomic, copy, readonly) NSString* headerFileName;
@property(nonatomic, copy, readonly) NSString* sourceFileName;

@end
