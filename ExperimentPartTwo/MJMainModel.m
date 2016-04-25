//
//  MJMainModel.m
//  ExperimentPartTwo
//
//  Created by Marcus John Rice Lee on 7/11/14.
//  Copyright (c) 2014 Marcus John Rice Lee. All rights reserved.
//

#import "MJMainModel.h"
#import "MJMainViewController.h"

@interface MJMainModel ()
{
    MJMainViewController *ourViewController;
    AVAudioPlayer *audioPlayer;
    AVAudioPlayer *textAudioPlayer;
    NSMutableDictionary *audioPlayerDictionary;
    BOOL isPlaying;
    BOOL onStory;
    BOOL optionsHaveBeenRead;
    BOOL isTextWaiting;
    NSMutableArray *readerPath;
    NSString *currentPage;
    NSArray *optionsArray;
    NSDictionary *bookRoute;
    NSTimer *textTimer;
    NSInteger secondsSinceLastText;
    NSInteger secondsBetweenTexts;
    NSString *mode;
    NSInteger rememberedSecondsOfStory;
    NSTimer *audioFader;
    NSDate *timePaused;
    // Properties for 20Q
    WebView *ourWebView;
    NSSpeechSynthesizer *ourSpeechSynthesizer;
    NSString *currentTextToRead;
    BOOL onQuestions;
    // ROS properties
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    NSDate *timeWhenQuestionPosed;
}

@end

@implementation MJMainModel

-(id)initWithMode:(NSString *)experimentType AndViewController:(MJMainViewController *)viewController AndTimeBewteenTexts:(NSInteger)time AndPageNumber:(NSString *)pageString AndWebView:(WebView *)webView {
    self = [super init];
    if (self) {
        // Initialize self
        ourSpeechSynthesizer = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
        [ourSpeechSynthesizer setDelegate:self];
        audioPlayerDictionary = [[NSMutableDictionary alloc] init];
        mode = experimentType;
        ourViewController = viewController;
        isPlaying = YES;
        onStory = YES;
        optionsHaveBeenRead = NO;
        readerPath = [[NSMutableArray alloc] init];
        secondsBetweenTexts = time;
        
        // Initialize Web View
        ourWebView = webView;
        // [self loadWebPage];
        
        // Make Dictionary
        NSArray *pageStrings = [self makePageStrings];
        NSArray *optionArray = [self makeOptionArray];
        if ([pageStrings count] == [optionArray count]) {
            bookRoute = [[NSDictionary alloc] initWithObjects:optionArray forKeys:pageStrings];
            NSLog(@"Dictionary constructed");
        }
        
        // Initialize for correct page
        currentPage = pageStrings[0];
        for (NSInteger i = 0; i < [pageStrings count]; i++) {
            if ([pageString isEqualToString:pageStrings[i]]) {
                NSLog(@"Page set to given string.");
                currentPage = pageString;
                break;
            }
        }
        [readerPath addObject:currentPage];
        optionsArray = [bookRoute objectForKey:currentPage];
        
        // Start audiobook
        [self playAudioPlayerWithFileName:currentPage];
        
        // Start Text Timer
        // [self startTextTimer];
        
        // Set up connection to ROS
        // [self makeConnection];
        // [self sendMessage:@"Heyyo"]; // test message
    }
    return self;
}

// Functionality Methods
-(void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking {
    if (!onStory) {
        timeWhenQuestionPosed = [NSDate date];
    }
}
-(void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    if (onQuestions) {
        isTextWaiting = NO;
        onStory = YES;
        [self restartStory];
        currentTextToRead = nil;
        [ourViewController properlySetButtons];
        if (timeWhenQuestionPosed != NULL) {
            NSTimeInterval timeToRespond = [timeWhenQuestionPosed timeIntervalSinceNow];
            // Send Message Here
        }
    }
    NSData *data = [[[sender mainFrame] dataSource] data];
    NSError *error;
    NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyHTML error:&error];
    
    NSXMLElement *rootNode = [document rootElement];
    NSString *xpathQueryString = @"/html/body/table/tr[1]/td[1]/table/tr/td/big/b/node()[1]";
    NSArray *newItemNodes = [rootNode nodesForXPath:xpathQueryString error:&error];
    if ([newItemNodes count] > 0) {
        onQuestions = YES;
        NSXMLElement *node = newItemNodes[0];
        currentTextToRead = [node stringValue];
    }
}
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if ([player isEqual:[audioPlayerDictionary objectForKey:@"storyPlayer"]]) {
        if ([optionsArray count] == 1 && ![currentPage isEqualToString:@"77"]) {
            // Move to default option
            currentPage = optionsArray[0];
            optionsArray = bookRoute[currentPage];
            [readerPath addObject:currentPage];
            [self playAudioPlayerWithFileName:currentPage];
            [ourViewController properlySetButtons];
        } else if ([optionsArray count] == 0) {
            // End of Book, do nothing and wait for input
        } else if (!optionsHaveBeenRead && [optionsArray count] >= 1) {
            // Read options for listener
            NSString *filename =[NSString stringWithFormat:@"%@_options", currentPage];
            [self playAudioPlayerWithFileName:filename];
            optionsHaveBeenRead = YES;
        } else {
            // If the options have already been read for this page wait for a response.
        }
    } else if ([player isEqual:[audioPlayerDictionary objectForKey:@"buzzPlayer"]]) {
        // Return volume to 1.0 of audioPlayer.
        [audioPlayer setVolume:1.0f];
    } else if ([player isEqual:[audioPlayerDictionary objectForKey:@"textPlayer"]]) {
        // If the text message introduction has just finished being read you must wait for
        // the question to be played then press pause.
        [ourSpeechSynthesizer startSpeakingString:currentTextToRead];
    } else {
        // No other audio player should play while onStory is false.
    }
}
-(void)repeatStoryPress {
    if (onStory) {
        optionsHaveBeenRead = NO;
        if (isPlaying) {
            [self playAudioPlayerWithFileName:currentPage];
        } else {
            rememberedSecondsOfStory = 0;
        }
    } else {
        // Play the text introduction.
        [self playTextAudioPlayer];
    }
}
-(void)repeatOptionsPress {
    if (onStory) {
        optionsHaveBeenRead = YES;
        if (isPlaying) {
            NSString *fileName = [NSString stringWithFormat:@"%@_options", currentPage];
            [self playAudioPlayerWithFileName:fileName];
        } else {
            // Wait for play to be pressed
        }
    } else {
        // No option.
    }
}
-(void)optionOnePress {
    if (onStory) {
        optionsHaveBeenRead = NO;
        currentPage = optionsArray[0];
        optionsArray = bookRoute[currentPage];
        [readerPath addObject:currentPage];
        if (isPlaying) {
            [self playAudioPlayerWithFileName:currentPage];
        } else {
            rememberedSecondsOfStory = 0;
        }
    } else {
        NSLog(@"Should not reach");
    }
}
-(void)optionTwoPress {
    if (onStory) {
        optionsHaveBeenRead = NO;
        currentPage = optionsArray[1];
        optionsArray = bookRoute[currentPage];
        [readerPath addObject:currentPage];
        if (isPlaying) {
            [self playAudioPlayerWithFileName:currentPage];
        } else {
            rememberedSecondsOfStory = 0;
        }
    } else {
        NSLog(@"Should not reach");
    }
}
-(void)optionThreePress {
    if (onStory) {
        optionsHaveBeenRead = NO;
        currentPage = optionsArray[2];
        optionsArray = bookRoute[currentPage];
        [readerPath addObject:currentPage];
        if (isPlaying) {
            [self playAudioPlayerWithFileName:currentPage];
        } else {
            rememberedSecondsOfStory = 0;
        }
    } else {
        NSLog(@"Should not reach");
    }
}
-(void)backPress {
    if (onStory) {
        optionsHaveBeenRead = NO;
        [readerPath removeLastObject];
        currentPage = [readerPath lastObject];
        optionsArray = bookRoute[currentPage];
        if (isPlaying) {
            [self playAudioPlayerWithFileName:currentPage];
        } else {
            rememberedSecondsOfStory = 0;
        }
    } else {
        NSLog(@"Should not reach");
    }
}
-(void)restartPress {
    if (onStory) {
        optionsHaveBeenRead = NO;
        currentPage = @"01-02";
        optionsArray = bookRoute[currentPage];
        [readerPath addObject:currentPage];
        if (isPlaying) {
            [self playAudioPlayerWithFileName:currentPage];
        } else {
            rememberedSecondsOfStory = 0;
        }
    } else {
        NSLog(@"Should not reach");
    }
}
-(void)modOnePress {
    if (onStory) {
        if (isPlaying) {
            // Stop the story where it is and record where to start it back up (5 seconds before you stoped it or at the beginning if its less than 5 seconds in (or if its on an options read start it from the beginning))
            [self pauseStory];
        } else {
            // Start the story back up where it stopped
            [self restartStory];
        }
    } else {
        // No Option.
    }
    isPlaying = !isPlaying;
}
-(void)modTwoPress {
    if (onStory) {
        if (isPlaying) {
            [self pauseStory];
        } else {
            // Do nothing.
        }
    } else {
        // Go back to Story.
        if (isPlaying) {
            [self restartStory];
        } else {
            // Do nothing.
        }
    }
    onStory = !onStory;
}

// Set Button Methods
-(NSString*)currentPage {
    return currentPage;
}
-(BOOL)shouldOptionsRepeatBeEnabled {
    if (onStory) {
        return YES;
    } else {
        return NO;
    }
}
-(NSString*)storyRepeatTitle {
    if (onStory) {
        return @"Repeat Story";
    } else {
        return @"Repeat Text";
    }
}
-(BOOL)shouldStoryRepeatBeEnabled {
    if (onStory) {
        return YES;
    } else {
        if (isTextWaiting) {
            return YES;
        } else {
            return NO;
        }
    }
}
-(NSString*)optionsRepeatTitle {
    if (onStory) {
        return @"Repeat Options";
    } else {
        return @"None";
    }
}
-(BOOL)shouldOptionOneBeEnabled {
    if (onStory) {
        if ([optionsArray count] >= 1) {
            return YES;
        }
        return NO;
    } else {
        return NO;
    }
}
-(NSString*)optionOneText {
    if ([optionsArray count] >= 1) {
        return [NSString stringWithFormat:@"1) %@", [optionsArray objectAtIndex:0]];
    }
    return @"End";
}
-(BOOL)shouldOptionTwoBeEnabled {
    if (onStory) {
        if ([optionsArray count] >= 2) {
            return YES;
        }
        return NO;
    } else {
        return NO;
    }
}
-(NSString*)optionTwoText {
    if ([optionsArray count] >= 2) {
        return [NSString stringWithFormat:@"2) %@", [optionsArray objectAtIndex:1]];
    }
    return @"None";
}
-(BOOL)shouldOptionThreeBeEnabled {
    if (onStory) {
        if ([optionsArray count] == 3) {
            return YES;
        }
        return NO;
    } else {
        return NO;
    }
}
-(NSString*)optionThreeText {
    if ([optionsArray count] == 3) {
        return [NSString stringWithFormat:@"3) %@", [optionsArray objectAtIndex:2]];
    }
    return @"None";
}
-(BOOL)shouldBackBeEnabled {
    if (onStory) {
        if ([readerPath count] > 1) {
            return YES;
        }
        return NO;
    } else {
        return NO;
    }
}
-(BOOL)shouldRestartBeEnabled {
    if (onStory) {
        if (![currentPage isEqualToString:@"01-02"]) {
            return YES;
        }
        return NO;
    } else {
        return NO;
    }
}
-(BOOL)shouldModOneBeEnabled {
    if (onStory) {
        return YES;
    } else {
        return NO;
    }
}
-(NSString*)modOneText {
    if (isPlaying) {
        return @"Pause";
    } else {
        return @"Play";
    }
}
-(BOOL)shouldModTwoBeEnabled {
    if ([mode  isEqualToString:@"Non Moderated"]) {
        return NO;
    } else {
        if (onStory) {
            if (isTextWaiting) {
                return YES;
            } else {
                return NO;
            }
        } else {
            return NO;
        }
    }
}
-(NSString*)modTwoText {
    if (onStory) {
        return @"Play Text";
    } else {
        return @"Play Story";
    }
}
-(NSString*)instructionText {
    if (onStory) {
        if (isPlaying) {
            return @"The story should be playing for the listener. To navigate through the story use the buttons for options one through three, the back button and the restart button. To hear the page(s) you are on again press the Repeat Story button. To hear your options again press the Repeat Options button.";
        } else {
            return @"Your current selection is the story and it is paused.  To start the story again press the Play button. You may still navigate through the story using the navigation buttons (Options 1-3, Back, and Restart)";
        }
    } else {
        if (isPlaying) {
            return @"The text message should be playing ";
        } else {
            return @"";
        }
    }
}
-(NSInteger)shouldTextWaitingTriggerBeOn {
    if (isTextWaiting) {
        return NSOnState;
    } else {
        return NSOffState;
    }
}
-(void)setWebViewVisibility {
    if (onStory) {
        if (onQuestions) {
            [ourWebView setHidden:NO];
        }
    }
}

// Helper methods
-(void)makeConnection {
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"10.0.22.202", 5080, &readStream, &writeStream);
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];
    [outputStream open];
}
-(void)sendMessage:(NSString*)message {
    // This method should be used to send data to ROS, the ros message has two fields (a header and a string)
    // The string that will be in the message is the one passed into this method, NSString message.
    NSData *data = [[NSData alloc] initWithData:[message dataUsingEncoding:NSASCIIStringEncoding]];
	[outputStream write:[data bytes] maxLength:[data length]];
}
-(NSURL*)soundURLFromName:(NSString*)soundFileName {
    NSString *path = [NSString stringWithFormat:@"%@/%@.wav", [[NSBundle mainBundle] resourcePath], soundFileName];
    NSURL *result = [NSURL fileURLWithPath:path];
    return result;
}
-(void)playAudioPlayerWithFileName:(NSString*)soundFileName {
    AVAudioPlayer *newAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[self soundURLFromName:soundFileName] error:nil];
    if (newAudioPlayer != nil) {
        audioPlayer = newAudioPlayer;
        [audioPlayer setDelegate:self];
        [audioPlayer play];
        [audioPlayer setVolume:1.0];
        [audioPlayerDictionary setObject:audioPlayer forKey:@"storyPlayer"];
    }
}
-(void)playTextAudioPlayer {
    NSString *path = [NSString stringWithFormat:@"%@/new_text.wav", [[NSBundle mainBundle] resourcePath]];
    NSURL *textIntroductionURL = [NSURL fileURLWithPath:path];
    AVAudioPlayer *newAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:textIntroductionURL error:nil];
    if (newAudioPlayer != nil) {
        textAudioPlayer = newAudioPlayer;
        [textAudioPlayer play];
        [audioPlayerDictionary setObject:textAudioPlayer forKey:@"textPlayer"];
        [textAudioPlayer setDelegate:self];
    }
}
-(void)playBuzz {
    [audioPlayer setVolume:0.2f];
    NSString *path = [NSString stringWithFormat:@"%@/buzz.wav", [[NSBundle mainBundle] resourcePath]];
    NSURL *buzzURL = [NSURL fileURLWithPath:path];
    textAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:buzzURL error:nil];
    [textAudioPlayer setDelegate:self];
    [audioPlayerDictionary setObject:textAudioPlayer forKey:@"buzzPlayer"];
    [textAudioPlayer play];
}
-(void)triggerTextMethod {
    // blah
    if (secondsSinceLastText == secondsBetweenTexts) {
        if (currentTextToRead != nil) {
            isTextWaiting = YES;
            if ([mode isEqualToString:@"Non Moderated"]) {
                // Play Text Immediately.
                onStory = NO;
                [self pauseStory];
                [self playTextAudioPlayer];
            } else if ([mode isEqualToString:@"User Controlled"]) {
                // Play buzz over story.
                [self playBuzz];
            }
            [ourViewController properlySetButtons];
        } else {
            NSLog(@"Text fired but no text was ready.");
        }
        secondsSinceLastText = 0;
    } else {
        secondsSinceLastText++;
    }
}
-(void)fadeAudioPlayer:(NSTimer*)theTimer {
    float volume = [audioPlayer volume];
    if (volume <= 0.2) {
        [audioPlayer pause];
        [audioFader invalidate];
    } else {
        [audioPlayer setVolume:(volume - 0.04)];
    }
}
-(void)pauseStory {
    [self pauseTextTimer];
    rememberedSecondsOfStory = [audioPlayer currentTime];
    audioFader = [NSTimer scheduledTimerWithTimeInterval:(1.0/30)
                                                  target:self
                                                selector:@selector(fadeAudioPlayer:)
                                                userInfo:nil
                                                 repeats:YES];
    timePaused = [NSDate date];
}
-(void)restartStory {
    [self startTextTimer];
    if (optionsHaveBeenRead) {
        NSString *fileName = [NSString stringWithFormat:@"%@_options", currentPage];
        [self playAudioPlayerWithFileName:fileName];
    } else {
        NSTimeInterval lengthOfPause = -[timePaused timeIntervalSinceNow];
        NSInteger secondsToGoBack = lengthOfPause/5;
        if (secondsToGoBack == 0) {
            secondsToGoBack = 1;
        } else if (secondsToGoBack > 5) {
            secondsToGoBack = 5;
        }
        if (rememberedSecondsOfStory <= secondsToGoBack) {
            [self playAudioPlayerWithFileName:currentPage];
        } else {
            [self playAudioPlayerWithFileName:currentPage];
            [audioPlayer setCurrentTime:(rememberedSecondsOfStory - secondsToGoBack)];
        }
    }
}
-(void)startTextTimer {
    textTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                 target:self
                                               selector:@selector(triggerTextMethod)
                                               userInfo:nil
                                                repeats:YES];
}
-(void)pauseTextTimer {
    [textTimer invalidate];
}
-(void)loadWebPage {
    NSString *urlText = @"http://movies.20q.net/";
    NSURLRequest *loadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlText]];
    [[ourWebView mainFrame] loadRequest:loadRequest];
    [ourWebView setFrameLoadDelegate:self];
    [ourWebView setUIDelegate:self];
}
-(NSArray *)makePageStrings {
    NSArray *pageStrings = [[NSArray alloc] initWithObjects:@"01-02",
                            @"03",
                            @"04-05",
                            @"06-07",
                            @"08",
                            @"09",
                            @"10-11",
                            @"12",
                            @"13",
                            @"14-15",
                            @"16-17",
                            @"18",
                            @"19",
                            @"20",
                            @"21",
                            @"22",
                            @"23",
                            @"24",
                            @"25",
                            @"26",
                            @"28-29",
                            @"30",
                            @"31",
                            @"32",
                            @"33",
                            @"34-35",
                            @"36-37",
                            @"38",
                            @"39",
                            @"40-41",
                            @"42",
                            @"43",
                            @"44",
                            @"45",
                            @"46-47",
                            @"48",
                            @"49",
                            @"50",
                            @"51",
                            @"52",
                            @"53",
                            @"54",
                            @"55",
                            @"56",
                            @"57",
                            @"58",
                            @"59",
                            @"60-61",
                            @"62",
                            @"63",
                            @"64-65",
                            @"66",
                            @"67",
                            @"68",
                            @"69",
                            @"70",
                            @"71",
                            @"72-73",
                            @"74",
                            @"75",
                            @"76",
                            @"77",
                            @"78",
                            @"79",
                            @"80",
                            @"81",
                            @"82",
                            @"83",
                            @"84-85",
                            @"86",
                            @"87",
                            @"88",
                            @"89",
                            @"90-91",
                            @"92",
                            @"93",
                            @"94",
                            @"95",
                            @"96",
                            @"97",
                            @"98",
                            @"99",
                            @"100",
                            @"101",
                            @"102",
                            @"103",
                            @"104",
                            @"105",
                            @"106",
                            @"107-108-109",
                            @"110",
                            @"111",
                            @"112-113",
                            @"114-115",
                            @"116",
                            @"117", nil];
    return pageStrings;
}
-(NSArray *)makeOptionArray {
    NSArray *optionArray = [[NSArray alloc] initWithObjects:
                            [[NSArray alloc] initWithObjects:@"06-07", @"04-05", nil],
                            [[NSArray alloc] initWithObjects:@"09", @"14-15", nil],
                            [[NSArray alloc] initWithObjects:@"03", @"08", nil],
                            [[NSArray alloc] initWithObjects:@"10-11", @"12", nil],
                            [[NSArray alloc] initWithObjects:@"18", @"13", nil],
                            [[NSArray alloc] initWithObjects:@"25", @"21", nil],
                            [[NSArray alloc] initWithObjects:@"16-17", @"19", nil],
                            [[NSArray alloc] initWithObjects:@"20", @"22", nil],
                            [[NSArray alloc] initWithObjects:@"24", @"27", nil],
                            [[NSArray alloc] initWithObjects:@"23", @"26", nil],
                            [[NSArray alloc] initWithObjects:@"31", @"32", nil],
                            [[NSArray alloc] initWithObjects:@"28-29", @"30", nil],
                            [[NSArray alloc] initWithObjects:@"34-35", @"36-37", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] initWithObjects:@"38", @"33", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] initWithObjects:@"06-07", nil],
                            [[NSArray alloc] initWithObjects:@"40-41", @"39", nil],
                            [[NSArray alloc] initWithObjects:@"44", @"45", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] initWithObjects:@"46-47", @"48", nil],
                            [[NSArray alloc] initWithObjects:@"51", @"53", nil],
                            [[NSArray alloc] initWithObjects:@"50", @"49", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] initWithObjects:@"54", @"52", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] initWithObjects:@"55", @"56", nil],
                            [[NSArray alloc] initWithObjects:@"57", @"58", nil],
                            [[NSArray alloc] initWithObjects:@"06-07", nil],
                            [[NSArray alloc] initWithObjects:@"59", @"60-61", nil],
                            [[NSArray alloc] initWithObjects:@"64-65", @"62", nil],
                            [[NSArray alloc] initWithObjects:@"63", @"66", nil],
                            [[NSArray alloc] initWithObjects:@"50", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] initWithObjects:@"08", nil],
                            [[NSArray alloc] initWithObjects:@"67", @"68", nil],
                            [[NSArray alloc] initWithObjects:@"74", @"75", nil],
                            [[NSArray alloc] initWithObjects:@"69", @"70", nil],
                            [[NSArray alloc] initWithObjects:@"71", @"72-73", nil],
                            [[NSArray alloc] initWithObjects:@"76", @"77", nil],
                            [[NSArray alloc] initWithObjects:@"78", @"79", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] initWithObjects:@"80", @"82", nil],
                            [[NSArray alloc] initWithObjects:@"81", @"84", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] initWithObjects:@"87", @"88", nil],
                            [[NSArray alloc] initWithObjects:@"62", @"83", @"86", nil],
                            [[NSArray alloc] initWithObjects:@"31", nil],
                            [[NSArray alloc] initWithObjects:@"06-07", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] initWithObjects:@"96", @"97", nil],
                            [[NSArray alloc] initWithObjects:@"98", @"99", nil],
                            [[NSArray alloc] initWithObjects:@"90-91", @"89", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] initWithObjects:@"92", @"93", nil],
                            [[NSArray alloc] initWithObjects:@"106", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] initWithObjects:@"107-108-109", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] initWithObjects:@"51", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] initWithObjects:@"116", @"117", nil],
                            [[NSArray alloc] initWithObjects:@"112-113", @"114-115", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] initWithObjects:@"94", @"95", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] initWithObjects:@"101", @"103", nil],
                            [[NSArray alloc] initWithObjects:@"100", @"102", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] initWithObjects:@"104", @"105", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] initWithObjects:@"111", @"110", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] initWithObjects:@"54", nil],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init],
                            [[NSArray alloc] init], nil];
    return optionArray;
}
@end
