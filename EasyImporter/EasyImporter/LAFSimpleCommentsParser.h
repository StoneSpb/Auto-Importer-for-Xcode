//
//  LAFSimpleCommentsParser.h
//  AutoImporter
//
//  Created by Alexander Denisov on 12.05.15.
//  Copyright (c) 2015 luisfloreani.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LAFSimpleCommentsParser : NSObject

- (NSString*)stripComments:(NSString*)source;

@end
