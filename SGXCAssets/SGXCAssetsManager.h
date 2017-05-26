//
//  SGXCAssetsManager.h
//  SGXCAssets
//
//  Created by SegunLee on 2017. 5. 24..
//  Copyright © 2017년 SGIOS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGXCAssetsManagerResult : NSObject
@property (nonatomic, assign) BOOL result;
@property (nonatomic, readonly, nullable) NSString *resultMessage;
@property (nonatomic, strong, nonnull) NSMutableArray *createFiles;
@property (nonatomic, strong, nonnull) NSMutableArray *updateFiles;
@property (nonatomic, strong, nonnull) NSMutableArray *deleteFiles;
@end


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

typedef void (^SGXCAssetsManagerCompletion)(SGXCAssetsManagerResult * _Nonnull result);
typedef NSInteger (^SGXCAssetsManagerInterrupt) (NSString * _Nonnull message);

extern NSString * _Nonnull const SGXCAssetsExtension;
@interface SGXCAssetsManager : NSObject

#pragma mark - Public
@property (nonatomic, readonly) BOOL readyToProcess;

- (BOOL)setXCAssetsPath:(nonnull NSString *)xcassetsPath;
- (BOOL)setInputImagesPaths:(nonnull NSArray *)inputImagesPaths;
- (void)processWithOption:(SGXCAssetsOption)option completion:(SGXCAssetsManagerCompletion _Nonnull)completion interrupt:(SGXCAssetsManagerInterrupt _Nonnull)interrupt;

@end
