//
//  XCWorkspace.m
//  xcode-editor
//
//  Created by Marko Hlebar on 06/05/2014.
//  Copyright (c) 2014 EXPANZ. All rights reserved.
//

#import "SXCWorkspace.h"

#import <XcodeEditor/SXCProject.h>
#import <XcodeEditor/SXCSourceFile.h>

#import "NSString+SXCAdditions.h"
#import "SXCProject+Extensions.h"

NSString * const SXCWorkspaceProjectWorkspaceFile =  @"project.xcworkspace";

static NSString * const SXCWorkspaceContents =       @"contents.xcworkspacedata";
static NSString * const SXCFileRefElement =          @"FileRef";
static NSString * const SXCLocationKey =             @"location";

@interface SXCWorkspace () <NSXMLParserDelegate>

@end

@implementation SXCWorkspace
{
    NSXMLParser *_parser;
}

+ (instancetype)workspaceWithFilePath:(NSString*)filePath
{
    return [[self alloc] initWithFilePath:filePath];
}

- (instancetype)initWithFilePath:(NSString*)filePath
{
    self = [super init];
    if (self)
    {
        _filePath = filePath.copy;
        
        [self parseWorkspaceWithFilePath:_filePath];
    }
    return self;
}

- (void)parseWorkspaceWithFilePath:(NSString *)filePath
{
    _projects = [NSArray new];
    
    filePath = [filePath stringByAppendingPathComponent:SXCWorkspaceContents];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    
    _parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    _parser.delegate = self;
    [_parser parse];
}

- (void) addProjectWithFilePath:(NSString *)filePath {
    if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]) return;
    
    SXCProject *project = [SXCProject projectWithFilePath:filePath];
    _projects = [_projects arrayByAddingObject:project];
    
    //subprojects
    NSArray *subProjects = [project subProjectFiles];
    if (subProjects.count > 0) {
        NSString *rootPath = [filePath stringByDeletingLastPathComponent];
        [subProjects enumerateObjectsUsingBlock:^(SXCSourceFile *projectFile, NSUInteger idx, BOOL *stop) {
            NSString *fullPath = [rootPath stringByAppendingPathComponent:projectFile.pathRelativeToProjectRoot];
            [self addProjectWithFilePath:fullPath];
        }];
    }
}

-   (void)parser:(NSXMLParser *)parser
 didStartElement:(NSString *)elementName
    namespaceURI:(NSString *)namespaceURI
   qualifiedName:(NSString *)qName
      attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:SXCFileRefElement]) {
        NSString *location = attributeDict[SXCLocationKey];
        
        if ([location sxc_containsString:@"self:"]) {
            location = [self workspaceRootPath];
        }
        else {
            NSArray *stringsToReplace = @[@"group:", @"container:"];
            location = [location sxc_stringByReplacingOccurrencesOfStrings:stringsToReplace
                                                                withString:@""];
            location = [[self workspaceRootPath] stringByAppendingPathComponent:location];
        }

        [self addProjectWithFilePath:location];
    }
}

- (NSString *)workspaceRootPath
{
    return [_filePath stringByDeletingLastPathComponent];
}

- (void) parserDidEndDocument:(NSXMLParser *)parser
{
    _parser = nil;
}

@end
