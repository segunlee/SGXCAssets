//
//  SGXCAssetsResultViewController.h
//  SGXCAssets
//
//  Created by SegunLee on 2017. 7. 18..
//  Copyright © 2017년 SGIOS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SGXCAssetsResultViewController : NSViewController

- (instancetype)initWithResultString:(NSString *)string;

@property (weak) IBOutlet NSTextView *textView;

@end
