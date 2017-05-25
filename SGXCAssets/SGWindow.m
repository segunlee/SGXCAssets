//
//  SGWindow.m
//  SGXCAssets
//
//  Created by SegunLee on 2017. 5. 24..
//  Copyright © 2017년 SGIOS. All rights reserved.
//

#import "SGWindow.h"

@implementation SGWindow

#pragma mark - NSDraggingDestination
- (void)registerForDraggedTypes:(NSArray<NSString *> *)newTypes {
    [super registerForDraggedTypes:newTypes];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return NSDragOperationGeneric;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    if ([self.draggingDelegate respondsToSelector:@selector(receiveWindowPerformDragOperation:)]) {
        return [self.draggingDelegate receiveWindowPerformDragOperation:sender];
    }
    return NO;
}

@end
