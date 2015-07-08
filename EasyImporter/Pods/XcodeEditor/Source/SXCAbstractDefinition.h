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

typedef enum
{
    /**
    * Creates the reference in the project and writes the contents to disk. If a file already exists at the specified
    * location, its contents will be updated.
    */
        SXCFileOperationTypeOverwrite,

    /**
    * Creates the reference in the project. If a file already exists at the specified location, the contents will not
    * be updated.
    */
        SXCFileOperationTypeAcceptExisting,

    /**
    * Creates the reference in the project, but does not write to disk. The filesystem is expected to be updated
     * through some other means.
    */
        SXCFileOperationTypeReferenceOnly
} SXCFileOperationType;

/**
* Holds properties to all types of resource that can be added to an Xcode project.
*/
@interface SXCAbstractDefinition : NSObject
{
    SXCFileOperationType _fileOperationType;
}

@property(nonatomic) SXCFileOperationType fileOperationType;

@end
