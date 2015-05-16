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

#import "SXCClassDefinition.h"

@implementation SXCClassDefinition

@synthesize className = _className;
@synthesize header = _header;
@synthesize source = _source;

/* ================================================================================================================== */
#pragma mark - Class Methods

+ (instancetype)classDefinitionWithName:(NSString*)fileName
{
    return [[self alloc] initWithName:fileName];
}

+ (instancetype)classDefinitionWithName:(NSString*)className language:(SXCClassDefinitionLanguage)language
{
    return [[self alloc] initWithName:className language:language];
}

/* ================================================================================================================== */
#pragma mark - Initialization & Destruction

- (instancetype)initWithName:(NSString*)className
{
    return [self initWithName:className language:SXCClassDefinitionLanguageObjectiveC];
}

- (instancetype)initWithName:(NSString*)className language:(SXCClassDefinitionLanguage)language
{
    self = [super init];
    if (self) {
        _className = [className copy];
        if (!(language == SXCClassDefinitionLanguageObjectiveC ||
              language == SXCClassDefinitionLanguageObjectiveCPlusPlus ||
              language == SXCClassDefinitionLanguageCPlusPlus)) {
            [NSException raise:NSInvalidArgumentException
                        format:@"Language must be one of ObjectiveC, ObjectiveCPlusPlus"];
        }
        _language = language;
    }
    return self;
}

/* ================================================================================================================== */
#pragma mark - Interface Methods

- (BOOL)isObjectiveC
{
    return _language == SXCClassDefinitionLanguageObjectiveC;
}

- (BOOL)isObjectiveCPlusPlus
{
    return _language == SXCClassDefinitionLanguageObjectiveCPlusPlus;
}

- (BOOL)isCPlusPlus
{
    return _language == SXCClassDefinitionLanguageCPlusPlus;
}

- (NSString*)headerFileName
{
    return [_className stringByAppendingString:@".h"];
}

- (NSString*)sourceFileName
{
    if (!_sourceFileName) {
        if ([self isObjectiveC]) {
            _sourceFileName = [_className stringByAppendingString:@".m"];
        }
        else if ([self isObjectiveCPlusPlus]) {
            _sourceFileName = [_className stringByAppendingString:@".mm"];
        }
        else if ([self isCPlusPlus]) {
            _sourceFileName = [_className stringByAppendingString:@".cpp"];
        }
        return _sourceFileName;
    }
    return _sourceFileName;
}

@end
