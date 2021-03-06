//
//  LAFAutoImporter.m
//  LAFAutoImporter
//
//  Created by Luis Floreani on 9/10/14.
//    Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "LAFEasyImporter.h"

#import "LAFProjectsInspector.h"
#import "LAFIDENotificationHandler.h"

static LAFEasyImporter *sharedPlugin;

@interface LAFEasyImporter()
@property (nonatomic, strong) NSBundle *bundle;
@end

@implementation LAFEasyImporter

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        // init inspector
        [LAFIDENotificationHandler sharedHandler];
        
        // reference to plugin's bundle, for resource acccess
        self.bundle = plugin;

        [self createMenuItem];
        [self subscribeToMenuNotifications];
    }
    return self;
}

- (void)dealloc {
    [self unsubscribeFromMenuNotifications];
}

#pragma mark - Notifications

- (void)subscribeToMenuNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(menuDidChangeItem:)
                                                 name:NSMenuDidChangeItemNotification
                                               object:nil];
}

- (void)unsubscribeFromMenuNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMenuDidChangeItemNotification
                                                  object:nil];

}

- (void)menuDidChangeItem:(NSNotification*)notification {
    [self unsubscribeFromMenuNotifications];

    [self createMenuItem];

    [self subscribeToMenuNotifications];
}

#pragma mark -

- (void)createMenuItem {
    NSString* name = @"Import header";
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
    if (menuItem && ![menuItem.submenu itemWithTitle:name]) {
        NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:name
                                                                action:@selector(importHeaderActionActivated)
                                                         keyEquivalent:@"h"];
        [actionMenuItem setTarget:self];
        [actionMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask+NSControlKeyMask];

        [menuItem.submenu addItem:[NSMenuItem separatorItem]];
        [menuItem.submenu addItem:actionMenuItem];
    }
}

- (void)importHeaderActionActivated {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LAFShowHeaders" object:nil];
}

@end
