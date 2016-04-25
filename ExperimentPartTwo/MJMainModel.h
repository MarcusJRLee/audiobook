//
//  MJMainModel.h
//  ExperimentPartTwo
//
//  Created by Marcus John Rice Lee on 7/11/14.
//  Copyright (c) 2014 Marcus John Rice Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <WebKit/WebKit.h>
@class MJMainViewController;

@interface MJMainModel : NSObject <AVAudioPlayerDelegate, NSStreamDelegate, NSSpeechSynthesizerDelegate, WebFrameLoadDelegate, WebUIDelegate>

-(id)initWithMode:(NSString*)mode AndViewController:(MJMainViewController*)viewController AndTimeBewteenTexts:(NSInteger)time AndPageNumber:(NSString*)pageString AndWebView:(WebView*)webView;
-(NSURL*)soundURLFromName:(NSString*)soundFileName;
-(NSString*)currentPage;
-(void)repeatStoryPress;
-(void)repeatOptionsPress;
-(void)optionOnePress;
-(void)optionTwoPress;
-(void)optionThreePress;
-(void)backPress;
-(void)restartPress;
-(void)modOnePress;
-(void)modTwoPress;
-(BOOL)shouldStoryRepeatBeEnabled;
-(NSString*)storyRepeatTitle;
-(BOOL)shouldOptionsRepeatBeEnabled;
-(NSString*)optionsRepeatTitle;
-(BOOL)shouldOptionOneBeEnabled;
-(NSString*)optionOneText;
-(BOOL)shouldOptionTwoBeEnabled;
-(NSString*)optionTwoText;
-(BOOL)shouldOptionThreeBeEnabled;
-(NSString*)optionThreeText;
-(BOOL)shouldBackBeEnabled;
-(BOOL)shouldRestartBeEnabled;
-(BOOL)shouldModOneBeEnabled;
-(NSString*)modOneText;
-(BOOL)shouldModTwoBeEnabled;
-(NSString*)modTwoText;
-(NSString*)instructionText;
-(NSInteger)shouldTextWaitingTriggerBeOn;
-(void)setWebViewVisibility;


@end
