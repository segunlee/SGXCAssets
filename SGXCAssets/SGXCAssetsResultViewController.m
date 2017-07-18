//
//  SGXCAssetsResultViewController.m
//  SGXCAssets
//
//  Created by SegunLee on 2017. 7. 18..
//  Copyright © 2017년 SGIOS. All rights reserved.
//

#import "SGXCAssetsResultViewController.h"

@interface SGXCAssetsResultViewController ()
@property (nonatomic) NSString *resultString;
@end

@implementation SGXCAssetsResultViewController

- (instancetype)initWithResultString:(NSString *)string {
    self = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"SGXCAssetsResultViewController"];
    if (self) {
        self.title = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
        self.resultString = string;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textView.string = self.resultString;
}

@end
