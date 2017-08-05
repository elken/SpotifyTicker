//
//  AppDelegate.m
//  MenubarTicker
//
//  Created by Serban Giuroiu on 6/3/12.
//  Copyright (c) 2012 Serban Giuroiu. All rights reserved.
//

#import "AppDelegate.h"

#import "iTunes.h"
#import "Spotify.h"

const NSTimeInterval kPollingInterval = 1.0;


@interface AppDelegate ()

@property (nonatomic, retain) iTunesApplication *iTunes;
@property (nonatomic, retain) SpotifyApplication *spotify;

@property (nonatomic, retain) NSStatusItem *statusItem;
@property (nonatomic, retain) NSTimer *timer;

- (NSString *)timeFormatted:(int)totalSeconds;
@end


@implementation AppDelegate

@synthesize iTunes;
@synthesize spotify;

@synthesize statusItem;
@synthesize statusMenu;
@synthesize timer;

- (NSString *)timeFormatted:(int)totalSeconds
{
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    
    return hours == 0 ? [NSString stringWithFormat:@"%02d:%02d", minutes, seconds] : [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}

- (void)dealloc
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];

    self.iTunes = nil;
    self.spotify = nil;
    
    self.statusItem = nil;
    self.statusMenu = nil;
    
    [self.timer invalidate];
    self.timer = nil;
    
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:kPollingInterval
                                                  target:self
                                                selector:@selector(timerDidFire:)
                                                userInfo:nil
                                                 repeats:YES];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(didReceivePlayerNotification:)
                                                            name:@"com.apple.iTunes.playerInfo"
                                                          object:nil];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(didReceivePlayerNotification:)
                                                            name:@"com.spotify.client.PlaybackStateChanged"
                                                          object:nil];
}

- (void)awakeFromNib
{
    self.iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    self.spotify = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.menu = self.statusMenu;
    self.statusItem.highlightMode = YES;
    self.statusItem.toolTip = @"Menu Bar Ticker";
    
    [self updateTrackInfo];
}

- (NSString*)runningPlayer
{
    if ([self.iTunes isRunning] && [self.iTunes playerState] == iTunesEPlSPlaying) {
        return @"itunes";
    } else if ([self.spotify isRunning] && [self.spotify playerState] == SpotifyEPlSPlaying) {
        return @"spotify";
    } else {
        return nil;
    }
}

- (NSString*)trimString:(NSString*)s
{
    return [NSString stringWithFormat:@"%@...", [s substringToIndex:20]];
}


- (void)updateTrackInfo
{
    NSString *player = [self runningPlayer];
    id currentTrack = nil;
    double duration = 0;
    double position = 0;
    
    if (player != nil) {
        statusItem.image = [NSImage imageNamed: player];
    }
    
    if ([player  isEqual: @"itunes"]) {
        currentTrack = [self.iTunes currentTrack];
        duration = [[self.iTunes currentTrack] duration];
        position = [self.iTunes playerPosition];
    } else if ([player  isEqual: @"spotify"]) {
        currentTrack = [self.spotify currentTrack];
        duration = [self.spotify currentTrack].duration / 1000;
        position = [self.spotify playerPosition];
    }
    if (currentTrack) {
        NSString *artist = [currentTrack artist].length >= 20 ? [self trimString :[currentTrack artist]] : [currentTrack artist];
        NSString *name = [currentTrack name].length >= 20 ? [self trimString: [currentTrack name]] : [currentTrack name];
        statusItem.title = [NSString stringWithFormat:@"%@ - %@ (%@/%@)", artist, name, [self timeFormatted :position], [self timeFormatted :duration]];
    } else {
        statusItem.title = @"❙ ❙";
    }
    
}


- (void)timerDidFire:(NSTimer *)theTimer
{
    [self updateTrackInfo];
}

- (void)didReceivePlayerNotification:(NSNotification *)notification
{
    [self updateTrackInfo];
}


@end
