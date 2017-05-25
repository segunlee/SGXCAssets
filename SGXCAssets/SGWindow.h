//
//  SGWindow.h
//  SGXCAssets
//
//  Created by SegunLee on 2017. 5. 24..
//  Copyright © 2017년 SGIOS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define SGWindowInstance ((SGWindow *)[[NSApplication sharedApplication] windows].firstObject)

@protocol SGWindowDraggingDelegate;

@interface SGWindow : NSWindow<NSDraggingDestination>

@property (nonatomic, weak) id<SGWindowDraggingDelegate> draggingDelegate;

@end

@protocol SGWindowDraggingDelegate <NSObject>
@required
- (BOOL)receiveWindowPerformDragOperation:(id <NSDraggingInfo>)sender;

@end
