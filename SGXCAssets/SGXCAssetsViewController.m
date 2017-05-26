//
//  SGXCAssetsViewController.m
//  SGXCAssets
//
//  Created by SegunLee on 2017. 5. 24..
//  Copyright © 2017년 SGIOS. All rights reserved.
//

#import "SGXCAssetsViewController.h"
#import "SGWindow.h"
#import "SGXCAssetsManager.h"

@interface SGXCAssetsViewController ()<SGWindowDraggingDelegate>

@property (strong) SGXCAssetsManager *assetsManager;

@property (weak) IBOutlet NSView *aView;
@property (weak) IBOutlet NSImageView *aImageView;
@property (weak) IBOutlet NSColorWell *aColorWell;

@property (weak) IBOutlet NSView *iView;
@property (weak) IBOutlet NSImageView *iImageView;
@property (weak) IBOutlet NSColorWell *iColorWell;

@property (weak) IBOutlet NSButton *createOption;
@property (weak) IBOutlet NSButton *updateOption;
@property (weak) IBOutlet NSButton *deleteOption;

@property (weak) IBOutlet NSButton *processButton;

@end

@implementation SGXCAssetsViewController

#pragma mark - Life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // SGWindowDraggingDelegate Setup
    SGWindowInstance.draggingDelegate = self;
    
    // SGXCAssetsManager Setup
    _assetsManager = [[SGXCAssetsManager alloc] init];
    
    // Button Setup
    _processButton.enabled = NO;
}


#pragma mark - SGWindowDraggingDelegate
- (BOOL)receiveWindowPerformDragOperation:(id <NSDraggingInfo>)sender {
    NSPoint point = [sender draggingLocation];
    NSArray *filePaths = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    
    BOOL returnValue = NO;
    
    // setXCAssetsPath
    if (NSPointInRect(point, _aView.frame) == YES)
    {
        if (filePaths.count == 1) {
            NSString *filePath = filePaths.firstObject;
            if ([[filePath pathExtension] isEqualToString:SGXCAssetsExtension] == YES) {
                returnValue = [_assetsManager setXCAssetsPath:filePath];
            }
        }
        _aImageView.image = [NSImage imageNamed:returnValue ? @"assets_on" : @"assets_add"];
    }
    // setInputImagesPaths
    else if (NSPointInRect(point, _iView.frame) == YES)
    {
        returnValue = [_assetsManager setInputImagesPaths:filePaths];
        _iImageView.image = [NSImage imageNamed:returnValue ? @"images_on" : @"images_add"];
    }
    
    _processButton.enabled = _assetsManager.readyToProcess;
    
    return returnValue;
}


#pragma mark - IBActions
- (IBAction)didTappedProcess:(id)sender {
    if (_assetsManager.readyToProcess) {
        
        SGXCAssetsOption option = SGXCAssetsOptionNone;
        
        if (_createOption.state) {
            option = option | SGXCAssetsOptionC;
        }
        
        if (_updateOption.state) {
            option = option | SGXCAssetsOptionU;
        }
        
        if (_deleteOption.state) {
            option = option | SGXCAssetsOptionD;
        }
        
        [_assetsManager processWithOption:option completion:^(SGXCAssetsManagerResult *complete) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setAlertStyle:NSAlertStyleInformational];
                [alert setMessageText:@"SGXCAssets"];
                [alert setInformativeText:complete.resultMessage];
                [alert addButtonWithTitle:NSLocalizedString(@"CONFIRM", nil)];
                [alert beginSheetModalForWindow:SGWindowInstance completionHandler:nil];
            });
            
        } interrupt:^NSInteger(NSString *message) {
            
            __block dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            __block BOOL returnValue = NO;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setAlertStyle:NSAlertStyleInformational];
                [alert setMessageText:@"SGXCAssets"];
                [alert setInformativeText:message];
                [alert addButtonWithTitle:NSLocalizedString(@"YES", nil)];
                [alert addButtonWithTitle:NSLocalizedString(@"NO", nil)];
                [alert beginSheetModalForWindow:SGWindowInstance completionHandler:^(NSModalResponse returnCode) {
                    returnValue = returnCode == 1000;
                    dispatch_semaphore_signal(sema);
                }];
            });
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            return returnValue;
        }];
        
    }
}

- (IBAction)didTappedHelpCreate:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert setMessageText:NSLocalizedString(@"CREATE?", nil)];
    [alert setInformativeText:NSLocalizedString(@"CREATEDESC", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"CONFIRM", nil)];
    [alert beginSheetModalForWindow:SGWindowInstance completionHandler:nil];
}

- (IBAction)didTappedHelpUpdate:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert setMessageText:NSLocalizedString(@"UPDATE?", nil)];
    [alert setInformativeText:NSLocalizedString(@"UPDATEDESC", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"CONFIRM", nil)];
    [alert beginSheetModalForWindow:SGWindowInstance completionHandler:nil];
}

- (IBAction)didTappedHelpDelete:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert setMessageText:NSLocalizedString(@"DELETE?", nil)];
    [alert setInformativeText:NSLocalizedString(@"DELETEDESC", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"CONFIRM", nil)];
    [alert beginSheetModalForWindow:SGWindowInstance completionHandler:nil];
}


@end
