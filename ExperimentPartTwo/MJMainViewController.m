//
//  MJMainViewController.m
//  ExperimentPartTwo
//
//  Created by Marcus John Rice Lee on 7/10/14.
//  Copyright (c) 2014 Marcus John Rice Lee. All rights reserved.
//

#import "MJMainViewController.h"

@interface MJMainViewController ()
{
    MJMainModel *ourModel;
    NSString *pageStringText;
    NSString *mode;
}
@property (weak) IBOutlet NSTextField *pageString;

@property (weak) IBOutlet NSButton *repeatStoryButton;
- (IBAction)repeatStoryPress:(id)sender;

@property (weak) IBOutlet NSButton *repeatOptionsButton;
- (IBAction)repeatOptionsPress:(id)sender;

@property (weak) IBOutlet NSButton *optionOneButton;
- (IBAction)optionOnePress:(id)sender;

@property (weak) IBOutlet NSButton *optionTwoButton;
- (IBAction)optionTwoPress:(id)sender;

@property (weak) IBOutlet NSButton *optionThreeButton;
- (IBAction)optionThreePress:(id)sender;

@property (weak) IBOutlet NSButton *backButton;
- (IBAction)backPress:(id)sender;

@property (weak) IBOutlet NSButton *restartButton;
- (IBAction)restartPress:(id)sender;

@property (weak) IBOutlet NSButton *modOneButton;
- (IBAction)modOnePress:(id)sender;

@property (weak) IBOutlet NSButton *modTwoButton;
- (IBAction)modTwoPress:(id)sender;

@property (weak) IBOutlet NSButton *textWaitingTrigger;

@property (weak) IBOutlet NSMatrix *typeMatrix;

@property (unsafe_unretained) IBOutlet NSTextView *instructionTextView;

@property (weak) IBOutlet NSTextField *textSecondsTextField;

@property (weak) IBOutlet NSTextField *pageStartTextField;

@property (weak) IBOutlet WebView *ourWebView;
@end

@implementation MJMainViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Imposter init code.
    }
    return self;
}
@synthesize pageString;
@synthesize repeatStoryButton;
@synthesize repeatOptionsButton;
@synthesize optionOneButton;
@synthesize optionTwoButton;
@synthesize optionThreeButton;
@synthesize backButton;
@synthesize restartButton;
@synthesize modOneButton;
@synthesize modTwoButton;
@synthesize typeMatrix;
@synthesize instructionTextView;
@synthesize textWaitingTrigger;
@synthesize textSecondsTextField;
@synthesize pageStartTextField;
@synthesize ourWebView;
- (id)initWithCoder:(NSCoder*)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        // Actual init method, occurs before any views are set up.
    }
    return self;
}
-(void)properlySetButtons {
    [repeatStoryButton setEnabled:[ourModel shouldStoryRepeatBeEnabled]];
    [repeatStoryButton setTitle:[ourModel storyRepeatTitle]];
    
    [repeatOptionsButton setEnabled:[ourModel shouldOptionsRepeatBeEnabled]];
    [repeatOptionsButton setTitle:[ourModel optionsRepeatTitle]];
    
    [optionOneButton setEnabled:[ourModel shouldOptionOneBeEnabled]];
    [optionOneButton setTitle:[ourModel optionOneText]];
    
    [optionTwoButton setEnabled:[ourModel shouldOptionTwoBeEnabled]];
    [optionTwoButton setTitle:[ourModel optionTwoText]];
    
    [optionThreeButton setEnabled:[ourModel shouldOptionThreeBeEnabled]];
    [optionThreeButton setTitle:[ourModel optionThreeText]];
    
    [backButton setEnabled:[ourModel shouldBackBeEnabled]];
    
    [restartButton setEnabled:[ourModel shouldRestartBeEnabled]];
    
    [modOneButton setEnabled:[ourModel shouldModOneBeEnabled]];
    [modOneButton setTitle:[ourModel modOneText]];
    
    [modTwoButton setEnabled:[ourModel shouldModTwoBeEnabled]];
    [modTwoButton setTitle:[ourModel modTwoText]];
    
    [instructionTextView setString:[ourModel instructionText]];
    
    [textWaitingTrigger setState:[ourModel shouldTextWaitingTriggerBeOn]];
    
    [pageString setStringValue:[NSString stringWithFormat:@"%@ %@", pageStringText, [ourModel currentPage]]];
    
    [ourModel setWebViewVisibility];
}
- (IBAction)repeatStoryPress:(id)sender {
    [ourModel repeatStoryPress];
    [self properlySetButtons];
}
- (IBAction)repeatOptionsPress:(id)sender {
    [ourModel repeatOptionsPress];
    [self properlySetButtons];
}
- (IBAction)optionOnePress:(id)sender {
    [ourModel optionOnePress];
    [self properlySetButtons];
}
- (IBAction)optionTwoPress:(id)sender {
    [ourModel optionTwoPress];
    [self properlySetButtons];
}
- (IBAction)optionThreePress:(id)sender {
    [ourModel optionThreePress];
    [self properlySetButtons];
}
- (IBAction)backPress:(id)sender {
    [ourModel backPress];
    [self properlySetButtons];
}
- (IBAction)restartPress:(id)sender {
    [ourModel restartPress];
    [self properlySetButtons];
}
- (IBAction)modOnePress:(id)sender {
    if (!ourModel) {
        // Initializing
        [typeMatrix setEnabled:NO];
        [textSecondsTextField setEnabled:NO];
        [pageStartTextField setEnabled:NO];
        NSInteger secondsBetweenTexts = [textSecondsTextField integerValue];
        if (secondsBetweenTexts == 0) {
            secondsBetweenTexts = 20;
            NSLog(@"Invalid text. The time between texts is now 20 seconds.");
        }
        NSString *pageNumber = [pageStartTextField stringValue];
        mode = [[typeMatrix selectedCell] title];; // figure it out
        ourModel = [[MJMainModel alloc] initWithMode:mode AndViewController:self AndTimeBewteenTexts:secondsBetweenTexts AndPageNumber:pageNumber AndWebView:ourWebView];
        pageStringText = [pageString stringValue];
    } else {
        [ourModel modOnePress];
    }
    [self properlySetButtons];
}
- (IBAction)modTwoPress:(id)sender {
    [ourModel modTwoPress];
    [self properlySetButtons];
}
@end
