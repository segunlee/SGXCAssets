//
//  SGXCAssetsManager.m
//  SGXCAssets
//
//  Created by SegunLee on 2017. 5. 24..
//  Copyright © 2017년 SGIOS. All rights reserved.
//

#import "SGXCAssetsManager.h"

NSString * const SGXCAssetsExtension = @"xcassets";
NSString * const SGPathExtensionImageSet = @"imageset";
NSString * const SGContentJSONFileName = @"Contents.json";
NSString * const SGImagesKey = @"images";
NSString * const SGIdiomKey = @"idiom";
NSString * const SGFileNameKey = @"filename";
NSString * const SGScaleKey = @"scale";
NSString * const SGInfoKey = @"info";
NSString * const SGVersionKey = @"version";
NSString * const SGAuthorKey = @"author";
NSString * const SGIdiomUniversalValue = @"universal";
NSString * const SGScale1XValue = @"1x";
NSString * const SGScale2XValue = @"2x";
NSString * const SGScale3XValue = @"3x";
NSString * const SGDefaultVersionValue = @"1";
NSString * const SGDefaultAuthorValue = @"SGXCAssets";
NSString * const SGProperties = @"properties";
NSString * const SGRenderingIntent = @"template-rendering-intent";
NSString * const SGRenderingIntentTemplate = @"template";
NSString * const SGRenderingIntentOriginal = @"original";



@implementation SGXCAssetsManagerResult

- (instancetype)init {
    self = [super init];
    if (self) {
        _createFiles = [NSMutableArray new];
        _updateFiles = [NSMutableArray new];
        _deleteFiles = [NSMutableArray new];
    }
    return self;
}

- (NSString *)resultMessage {
    NSMutableString *result = [[NSMutableString alloc] init];
    [result appendFormat:@"Result: %@\n", _result ? @"Complete" : @"Failed"];
    
    if (_createFiles.count > 0) {
        [result appendFormat:@"\nCreate Files %zd\n", _createFiles.count];
        for (NSString *log in _createFiles) {
            [result appendFormat:@"%@\n", log];
        }
    }
    
    if (_updateFiles.count > 0) {
        [result appendFormat:@"\nUpdate Files %zd\n", _updateFiles.count];
        for (NSString *log in _updateFiles) {
            [result appendFormat:@"%@\n", log];
        }
    }
    
    if (_deleteFiles.count > 0) {
        [result appendFormat:@"\nDelete Files %zd\n", _deleteFiles.count];
        for (NSString *log in _deleteFiles) {
            [result appendFormat:@"%@\n", log];
        }
    }
    
    if (_createFiles.count + _updateFiles.count + _deleteFiles.count == 0) {
        [result appendString:@"\nNo changes."];
    }
    
    return result;
}

- (NSString *)deleteFileMessage {
    NSMutableString *message = [[NSMutableString alloc] init];
    for (NSString *log in _deleteFiles) {
        [message appendFormat:@"%@\n", log];
    }
    return message;
}

@end


@interface SGXCAssetsManager()

@property (nonatomic, copy) NSString *xcassetsPath;
@property (nonatomic, copy) NSArray *imagesPaths;
@property (nonatomic, assign) SGXCAssetsOption option;
@property (nonatomic, assign) SGXCAssetsRenderAs renderAs;
@property (nonatomic, copy) SGXCAssetsManagerCompletion completion;
@property (nonatomic, copy) SGXCAssetsManagerInterrupt interrupt;
@property (nonatomic, strong) SGXCAssetsManagerResult *result;

@end

@implementation SGXCAssetsManager

#pragma mark - Public
- (BOOL)readyToProcess {
    return _xcassetsPath.length > 0 && _imagesPaths.count > 0;
}

- (NSInteger)inputImagesCount {
    return _imagesPaths.count;
}

- (NSString *)xcassetsProjectName {
    if (_xcassetsPath.pathComponents.count > 2) {
        return [_xcassetsPath pathComponents][_xcassetsPath.pathComponents.count-2];
    }
    return @"Unknown";
}

- (BOOL)setXCAssetsPath:(nonnull NSString *)xcassetsPath {
    if ([[xcassetsPath pathExtension] isEqualToString:SGXCAssetsExtension] == YES) {
        _xcassetsPath = xcassetsPath;
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)setInputImagesPaths:(nonnull NSArray *)inputImagesPaths {
    if (inputImagesPaths.count == 0) {
        return NO;
    }
    
    NSArray *extensions = @[@"png", @"pdf"];
    NSArray *filteredArray = [inputImagesPaths filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension IN %@", extensions]];
    if (filteredArray.count) {
        _imagesPaths = filteredArray;
        return YES;
    } else {
        return NO;
    }
}

- (void)processWithOption:(SGXCAssetsOption)option renderAs:(SGXCAssetsRenderAs)renderAs completion:(SGXCAssetsManagerCompletion _Nonnull)completion interrupt:(SGXCAssetsManagerInterrupt _Nonnull)interrupt {
    _option = option;
    _renderAs = renderAs;
    _completion = completion;
    _interrupt = interrupt;
    _result = [[SGXCAssetsManagerResult alloc] init];
    
    __weak typeof(self) wSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong typeof(wSelf) self = wSelf;
        [self process];
    });
}

- (void)resetPaths {
    _option = SGXCAssetsOptionNone;
    _renderAs = SGXCAssetsRenderAsInherited;
    _xcassetsPath = nil;
    _imagesPaths = nil;
}


#pragma mark - Private
- (void)process {
    BOOL returnValue = YES;
    
    if (_option & SGXCAssetsOptionC) {
        BOOL result = [self processImagesCreate];
        returnValue = returnValue && result;
    }
    
    if (_option & SGXCAssetsOptionU) {
        BOOL result = [self processImagesUpdate];
        returnValue = returnValue && result;
    }
    
    if (_option & SGXCAssetsOptionD) {
        BOOL result = [self processImagesDelete];
        returnValue = returnValue && result;
    }
    
    _result.result = returnValue;
    
    _completion(_result);
}

- (BOOL)processImagesCreate {
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSMutableDictionary *contentsJsons = [self contentsJsonsWithAssetPath:self.xcassetsPath];
    for (NSString *imagePath in self.imagesPaths)
    {
        if ([[imagePath pathExtension] isEqualToString:@"png"] == NO) { continue; }
        
        NSString *fileName = [imagePath lastPathComponent];
        NSArray *components = [[fileName stringByDeletingPathExtension] componentsSeparatedByString:@"@"];
        NSString *key = components[0];
        NSString *scale = SGScale1XValue;
        if ([components count] > 1) {
            scale = components[1];
            if (!([scale isEqualToString:SGScale2XValue] || [scale isEqualToString:SGScale3XValue])) {
                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"IMAGE_SCALE_SUFFIX_NAME_WRONG_FORMAT", nil), fileName];
                if (_interrupt(message, @[NSLocalizedString(@"CONFIRM", nil)])) {
                    continue;
                }
            }
        }
        
        
        NSString *imageSetPath = [self imageSetPathWithAssetPath:self.xcassetsPath fileName:key];
        NSDictionary *contentsJson = contentsJsons[key];
        
        // If exist (scale), continue process
        if (contentsJson != nil) {
            BOOL isContinue = NO;
            for (NSMutableDictionary *imageInfo in contentsJson[SGImagesKey]) {
                if ([imageInfo[SGScaleKey] isEqualToString:scale] == YES) {
                    if ([imageInfo[SGFileNameKey] length] > 0) {
                        isContinue = YES;
                        break;
                    }
                }
            }
            
            if (isContinue) {
                continue;
            }
            
        } else {
            contentsJson = [self makeEmptyContentJson];
        }
        
        contentsJson = [self updateRenderAs:_renderAs contentJson:contentsJson];
        
        [_result.createFiles addObject:[NSString stringWithFormat:@"File: %@     Sacle: %@", key, scale]];
        
        contentsJsons[key] = contentsJson;
        
        // If directory not exist, create directory
        if ([fileManager fileExistsAtPath:imageSetPath] == NO) {
            [fileManager createDirectoryAtPath:imageSetPath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        
        // If destinationPath file exist, trash to file
        NSString *destinationPath = [imageSetPath stringByAppendingPathComponent:fileName];
        if ([fileManager fileExistsAtPath:destinationPath] == YES) {
            [fileManager trashItemAtURL:[NSURL fileURLWithPath:destinationPath] resultingItemURL:nil error:NULL];
        }
        
        // Move to destinationPath to image
        [fileManager copyItemAtPath:imagePath toPath:destinationPath error:nil];
        
        // contentsJson Setting
        for (NSMutableDictionary *imageInfo in contentsJson[SGImagesKey]) {
            if ([imageInfo[SGScaleKey] isEqualToString:scale] == YES) {
                imageInfo[SGFileNameKey] = fileName;
                break;
            }
        }
    }
    
    
    // contentsJsons Update
    for (NSString *key in [contentsJsons allKeys])
    {
        NSString *imageSetPath = [self imageSetPathWithAssetPath:self.xcassetsPath fileName:key];
        NSString *jsonPath = [imageSetPath stringByAppendingPathComponent:SGContentJSONFileName];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:contentsJsons[key] options:NSJSONWritingPrettyPrinted error:NULL];
        [jsonData writeToFile:jsonPath atomically:YES];
    }
    
    return YES;
}

- (BOOL)processImagesUpdate {
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSMutableDictionary *contentsJsons = [self contentsJsonsWithAssetPath:self.xcassetsPath];
    for (NSString *imagePath in self.imagesPaths)
    {
        if ([[imagePath pathExtension] isEqualToString:@"png"] == NO) { continue; }
        
        NSString *fileName = [imagePath lastPathComponent];
        NSArray *components = [[fileName stringByDeletingPathExtension] componentsSeparatedByString:@"@"];
        NSString *key = components[0];
        NSString *scale = SGScale1XValue;
        if ([components count] > 1) {
            scale = components[1];
            if (!([scale isEqualToString:SGScale2XValue] || [scale isEqualToString:SGScale3XValue])) {
                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"IMAGE_SCALE_SUFFIX_NAME_WRONG_FORMAT", nil), fileName];
                if (_interrupt(message, @[NSLocalizedString(@"CONFIRM", nil)])) {
                    continue;
                }
            }
        }
        
        NSString *imageSetPath = [self imageSetPathWithAssetPath:self.xcassetsPath fileName:key];
        NSDictionary *contentsJson = contentsJsons[key];
        
        // If not exist, continue process
        if (contentsJson == nil) { continue; }
        
        SGXCAssetsRenderAs currentRenderAs = [self getRenderAsWithContentJson:contentsJson];
        
        if (_renderAs != SGXCAssetsRenderAsOverride) {
            contentsJson = [self updateRenderAs:_renderAs contentJson:contentsJson];
        }
        
        contentsJsons[key] = contentsJson;
        
        // If destinationPath file exist, trash to file
        NSString *destinationPath = [imageSetPath stringByAppendingPathComponent:fileName];
        
        
        if ([fileManager contentsEqualAtPath:imagePath andPath:destinationPath]) {
            if (currentRenderAs != _renderAs && _renderAs != SGXCAssetsRenderAsOverride) {
                [_result.updateFiles addObject:[NSString stringWithFormat:@"File: %@     Sacle: %@", key, scale]];
            }
            continue;
        }
        
        // If directory not exist, create directory
        if ([fileManager fileExistsAtPath:imageSetPath] == NO) {
            [fileManager createDirectoryAtPath:imageSetPath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        
        [_result.updateFiles addObject:[NSString stringWithFormat:@"File: %@     Sacle: %@", key, scale]];
        
        if ([fileManager fileExistsAtPath:destinationPath] == YES) {
            [fileManager trashItemAtURL:[NSURL fileURLWithPath:destinationPath] resultingItemURL:nil error:NULL];
        }
        
        // Move to destinationPath to image
        [fileManager copyItemAtPath:imagePath toPath:destinationPath error:nil];
        
        // contentsJson Setting
        for (NSMutableDictionary *imageInfo in contentsJson[SGImagesKey]) {
            if ([imageInfo[SGScaleKey] isEqualToString:scale] == YES) {
                imageInfo[SGFileNameKey] = fileName;
                break;
            }
        }
    }
    
    
    // contentsJsons Update
    for (NSString *key in [contentsJsons allKeys])
    {
        NSString *imageSetPath = [self imageSetPathWithAssetPath:self.xcassetsPath fileName:key];
        NSString *jsonPath = [imageSetPath stringByAppendingPathComponent:SGContentJSONFileName];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:contentsJsons[key] options:NSJSONWritingPrettyPrinted error:NULL];
        [jsonData writeToFile:jsonPath atomically:YES];
    }
    
    return YES;
}

- (BOOL)processImagesDelete {
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSMutableDictionary *contentsJsons = [self contentsJsonsWithAssetPath:self.xcassetsPath];
    
    NSMutableArray *removeImageSetPaths = [NSMutableArray new];
    
    for(NSString *key in [contentsJsons allKeys])
    {
        NSString *imageSetPath = [self imageSetPathWithAssetPath:self.xcassetsPath fileName:key];
        
        BOOL used = NO;
        for (NSString *imagePath in self.imagesPaths)
        {
            if ([[imagePath pathExtension] isEqualToString:@"png"] == NO) { continue; }
            
            NSString *fileName = [imagePath lastPathComponent];
            NSArray *components = [[fileName stringByDeletingPathExtension] componentsSeparatedByString:@"@"];
            NSString *currentKey = components[0];
            
            if ([key isEqualToString:currentKey]) {
                used = YES;
                break;
            }
        }
        
        if (used == NO) {
            [_result.deleteFiles addObject:[NSString stringWithFormat:@"File: %@.imageset", key]];
            [removeImageSetPaths addObject:imageSetPath];
        }
    }
    
    if (removeImageSetPaths.count) {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"DELETE_ALERT_FORMAT", nil), removeImageSetPaths.count, _result.deleteFileMessage];
        if (_interrupt(message, @[NSLocalizedString(@"YES", nil), NSLocalizedString(@"NO", nil)])) {
            for (NSString *path in removeImageSetPaths) {
                [fileManager removeItemAtPath:path error:NULL];
            }
        }
        else
        {
            [_result.deleteFiles removeAllObjects];
            [removeImageSetPaths removeAllObjects];
        }
    }
    
    return YES;
}


#pragma mark - Private Utility
- (NSString *)imageSetPathWithAssetPath:(NSString *)assetPath fileName:(NSString *)fileName {
    NSString *imageSetPath = [[assetPath stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:SGPathExtensionImageSet];
    return imageSetPath;
}

- (NSMutableDictionary *)contentsJsonsWithAssetPath:(NSString *)assetPath {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:assetPath error:nil];
    for (NSString *path in contents) {
        
        if ([[path pathExtension] isEqualToString:SGPathExtensionImageSet] == YES)
        {
            NSString *jsonPath = [[assetPath stringByAppendingPathComponent:path] stringByAppendingPathComponent:SGContentJSONFileName];
            
            if ([fileManager fileExistsAtPath:jsonPath] == YES)
            {
                NSData *data = [NSData dataWithContentsOfFile:jsonPath];
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:NULL];
                
                if (json != nil)
                {
                    NSString *key = [path stringByDeletingPathExtension];
                    result[key] = json;
                }
            }
        }
    }
    
    return result;
}

- (NSDictionary *)makeEmptyContentJson {
    NSArray *scales = @[SGScale1XValue, SGScale2XValue, SGScale3XValue];
    
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:scales.count];
    for (NSInteger index=0; index<scales.count; index++) {
        NSMutableDictionary *image = [@{SGIdiomKey : SGIdiomUniversalValue,
                                        SGScaleKey : scales[index]} mutableCopy];
        [images addObject:image];
    }
    
    NSMutableDictionary *info = [@{SGVersionKey : @(SGDefaultVersionValue.integerValue),
                                   SGAuthorKey  : SGDefaultAuthorValue} mutableCopy];
    
    return [@{SGImagesKey : images, SGInfoKey : info} mutableCopy];
}

- (NSDictionary *)updateRenderAs:(SGXCAssetsRenderAs)renderAs contentJson:(NSDictionary *)contentJson {
    NSMutableDictionary *returnContentJson = [contentJson mutableCopy];
    if (returnContentJson[SGProperties] != nil) {
        [returnContentJson removeObjectForKey:SGProperties];
    }
    
    if (renderAs == SGXCAssetsRenderAsInherited) {
        return returnContentJson;
    }
    
    [returnContentJson setValue:[self makeRenderingIntent:renderAs] forKey:SGProperties];
    return returnContentJson;
}

- (SGXCAssetsRenderAs)getRenderAsWithContentJson:(NSDictionary *)contentJson {
    if (contentJson[SGProperties] != nil)
    {
        if ([contentJson[SGProperties][SGRenderingIntent] isEqualToString:SGRenderingIntentOriginal])
        {
            return SGXCAssetsRenderAsOriginal;
        }
        else if ([contentJson[SGProperties][SGRenderingIntent] isEqualToString:SGRenderingIntentTemplate])
        {
            return SGXCAssetsRenderAsTemplate;
        }
    }
    return SGXCAssetsRenderAsInherited;
}

- (NSDictionary *)makeRenderingIntent:(SGXCAssetsRenderAs)renderAs {
    if (renderAs == SGXCAssetsRenderAsInherited) {
        return nil;
    }
    
    NSString *renderAsValue = SGRenderingIntentOriginal;
    if (renderAs == SGXCAssetsRenderAsTemplate) {
        renderAsValue = SGRenderingIntentTemplate;
    }
    return @{SGRenderingIntent : renderAsValue};
}

@end
