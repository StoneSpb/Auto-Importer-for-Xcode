//
//  XCTarget+XCProject.h
//  MHImportBuster
//
//  Created by Marko Hlebar on 11/05/2014.
//  Copyright (c) 2014 Marko Hlebar. All rights reserved.
//

#import <XcodeEditor/SXCTarget.h>

@interface SXCTarget (SXCProject)

@property (nonatomic, strong, readonly) SXCProject *project;
@property (nonatomic, strong, readonly) NSArray *frameworks;

@end
