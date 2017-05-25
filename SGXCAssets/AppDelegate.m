//
//  AppDelegate.m
//  SGXCAssets
//
//  Created by SegunLee on 2017. 5. 24..
//  Copyright © 2017년 SGIOS. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()


@end

@implementation AppDelegate


#pragma mark - NSApplicationDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    NSWindow *window = [[NSApplication sharedApplication] windows].firstObject;
    [window registerForDraggedTypes:@[NSFilenamesPboardType]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    
}

@end
