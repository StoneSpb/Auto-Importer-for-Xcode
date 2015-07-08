//
//  XCProject+NSDate.h
//  MHImportBuster
//
//  Created by Marko Hlebar on 10/06/2014.
//  Copyright (c) 2014 Marko Hlebar. All rights reserved.
//

#import <XcodeEditor/SXCProject.h>

@interface SXCProject (NSDate)

- (NSDate *)dateModified;

@end

@interface SXCProject (MHSubprojects)

- (NSArray *)subProjectFiles;

@end
