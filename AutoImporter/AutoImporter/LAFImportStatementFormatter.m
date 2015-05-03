//
//  LAFImportStatementFormatter.m
//  AutoImporter
//
//  Created by Alexander Denisov on 03.05.15.
//  Copyright (c) 2015 luisfloreani.com. All rights reserved.
//

#import "LAFImportStatementFormatter.h"

#import "LAFIdentifier.h"

@implementation LAFImportStatementFormatter

+ (NSString*)importStatementForHeader:(LAFIdentifier*)header {
    NSParameterAssert(header.type == LAFIdentifierTypeHeader);
    NSString* path = [self pathForHeader:header];
    return [NSString stringWithFormat:@"#import \"%@\"", path];
}

+ (NSString*)pathForHeader:(LAFIdentifier*)header {
    if (header.srcRootPath) {
        return [self filePath:header.fullPath relativeToPath:header.srcRootPath];
    }

    return header.name;
}

+ (NSString*)filePath:(NSString *)path relativeToPath:(NSString *)basePath {
    NSArray* components = path.pathComponents;
    NSArray* baseComponents = basePath.pathComponents;
    if (components.count > baseComponents.count) {
        NSRange basePartRange = NSMakeRange(0, baseComponents.count);
        NSArray* possibleBaseComponents = [components subarrayWithRange:basePartRange];
        if ([baseComponents isEqual:possibleBaseComponents]) {
            NSRange relativePartRange = NSMakeRange(baseComponents.count,
                                                    components.count - baseComponents.count);
            NSArray* relativePathComponents = [components subarrayWithRange:relativePartRange];
            return [NSString pathWithComponents:relativePathComponents];
        }
    }

    return components.lastObject;
}

@end
