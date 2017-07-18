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
#import "SGXCAssetsResultViewController.h"



@interface SGXCAssetsViewController ()<SGWindowDraggingDelegate>

@property (strong) SGXCAssetsManager *assetsManager;

@property (weak) IBOutlet NSView *aView;
@property (weak) IBOutlet NSImageView *aImageView;
@property (weak) IBOutlet NSColorWell *aColorWell;
@property (weak) IBOutlet NSTextField *aLabel;

@property (weak) IBOutlet NSView *iView;
@property (weak) IBOutlet NSImageView *iImageView;
@property (weak) IBOutlet NSColorWell *iColorWell;
@property (weak) IBOutlet NSTextField *iLabel;

@property (weak) IBOutlet NSButton *createOption;
@property (weak) IBOutlet NSButton *updateOption;
@property (weak) IBOutlet NSButton *deleteOption;

@property (weak) IBOutlet NSSegmentedControl *renderOption;

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
    
    // Unregister block dragging
    [_aImageView unregisterDraggedTypes];
    [_iImageView unregisterDraggedTypes];
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
        [self updateAStuff:returnValue];
    }
    // setInputImagesPaths
    else if (NSPointInRect(point, _iView.frame) == YES)
    {
        returnValue = [_assetsManager setInputImagesPaths:filePaths];
        [self updateIStuff:returnValue];
    }
    
    _processButton.enabled = _assetsManager.readyToProcess;
    return returnValue;
}


#pragma mark - UI Update
- (void)updateAStuff:(BOOL)active {
    _aImageView.image = [NSImage imageNamed:active ? @"ic_directory_done" : @"ic_directory_add"];
    _aColorWell.color = active ? [NSColor colorWithSRGBRed:0.3743 green:0.7419 blue:0.4814 alpha:1.0] : [NSColor whiteColor];
    _aLabel.textColor = active ? [NSColor whiteColor] : [NSColor blackColor];
    
    if (active)
    {
        _aLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"A_LABEL_SELECTED_FORMAT", nil), _assetsManager.xcassetsProjectName];
    }
    else
    {
        _aLabel.stringValue = NSLocalizedString(@"A_LABEL_DEFAULT", nil);
    }
}

- (void)updateIStuff:(BOOL)active {
    _iImageView.image = [NSImage imageNamed:active ? @"ic_images_done" : @"ic_images_add"];
    _iColorWell.color = active ? [NSColor colorWithSRGBRed:0.3743 green:0.7419 blue:0.4814 alpha:1.0] : [NSColor whiteColor];
    _iLabel.textColor = active ? [NSColor whiteColor] : [NSColor blackColor];
    
    if (active)
    {
        _iLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"I_LABEL_SELECTED_FORMAT", nil), _assetsManager.inputImagesCount];
    }
    else
    {
        _iLabel.stringValue = NSLocalizedString(@"I_LABEL_DEFAULT", nil);
    }
}


#pragma mark - IBActions
- (IBAction)didTappedProcess:(id)sender {
    if (_assetsManager.readyToProcess == NO) {
        return;
    }
    
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
    _processButton.enabled = NO;
    __weak typeof(self) _self = self;
    [_assetsManager processWithOption:option renderAs:_renderOption.integerValue completion:^(SGXCAssetsManagerResult *complete) {
        
        __strong typeof(_self) self = _self;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setAlertStyle:NSAlertStyleInformational];
            [alert setMessageText:[[NSBundle mainBundle] infoDictionary][@"CFBundleName"]];
            [alert setInformativeText:complete.resultMessage];
            [alert addButtonWithTitle:NSLocalizedString(@"CONFIRM", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"RESULT_DETAIL", nil)];
            [alert beginSheetModalForWindow:SGWindowInstance completionHandler:^(NSModalResponse returnCode) {
                self.processButton.enabled = YES;
                if (returnCode == 1001) {
                    SGXCAssetsResultViewController *vc = [[SGXCAssetsResultViewController alloc] initWithResultString:complete.resultMessage];
                    [self presentViewControllerAsModalWindow:vc];
                }
            }];
        });
        
    } interrupt:^NSInteger(NSString *message, NSArray *buttons) {
        
        __block dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        __block BOOL returnValue = NO;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setAlertStyle:NSAlertStyleInformational];
            [alert setMessageText:[[NSBundle mainBundle] infoDictionary][@"CFBundleName"]];
            [alert setInformativeText:message];
            for (NSString *button in buttons) {
                [alert addButtonWithTitle:button];
            }
            [alert beginSheetModalForWindow:SGWindowInstance completionHandler:^(NSModalResponse returnCode) {
                returnValue = returnCode == 1000;
                dispatch_semaphore_signal(sema);
            }];
        });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        return returnValue;
    }];
}

- (IBAction)didTappedReset:(id)sender {
    [_assetsManager resetPaths];
    _createOption.state = 1;
    _updateOption.state = 1;
    _deleteOption.state = 0;
    _renderOption.integerValue = SGXCAssetsRenderAsOverride;
    _processButton.enabled = NO;
    [self updateAStuff:NO];
    [self updateIStuff:NO];
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
