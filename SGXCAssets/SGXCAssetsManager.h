//
//  SGXCAssetsManager.h
//  SGXCAssets
//
//  Created by SegunLee on 2017. 5. 24..
//  Copyright © 2017년 SGIOS. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 SGXCAssetsOption

 - SGXCAssetsOptionC: Create new Images assets
 - SGXCAssetsOptionU: Update old images assets
 - SGXCAssetsOptionD: Delete unuse Images assets
 - SGXCAssetsOptionAll: All
 */
typedef NS_OPTIONS(NSUInteger, SGXCAssetsOption) {
    SGXCAssetsOptionNone = 1 << 0,
    SGXCAssetsOptionC = 1 << 1,
    SGXCAssetsOptionU = 1 << 2,
    SGXCAssetsOptionD = 1 << 3,
    SGXCAssetsOptionAll = ~0UL
};

typedef void (^SGXCAssetsManagerCompletion)(BOOL complete);
typedef NSInteger (^SGXCAssetsManagerInterrupt) (NSString * _Nonnull message);

extern NSString * _Nonnull const SGXCAssetsExtension;
@interface SGXCAssetsManager : NSObject

#pragma mark - Public
@property (nonatomic, readonly) BOOL readyToProcess;

- (BOOL)setXCAssetsPath:(nonnull NSString *)xcassetsPath;
- (BOOL)setInputImagesPaths:(nonnull NSArray *)inputImagesPaths;
- (void)processWithOption:(SGXCAssetsOption)option completion:(SGXCAssetsManagerCompletion _Nonnull)completion interrupt:(SGXCAssetsManagerInterrupt _Nonnull)interrupt;

@end
