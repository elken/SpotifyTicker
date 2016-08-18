//
//  AppDelegate.swift
//  SpotifyTicker
//
//  Created by elken on 16/08/2016.
//  Copyright © 2016 tdos. All rights reserved.
//

import Cocoa
import ScriptingBridge
import Darwin

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusMenu: NSMenu!
    var timer: NSTimer!
    var statusItem: NSStatusItem!
    var pausedIcon: String!
    
    var spotify = SBApplication(bundleIdentifier: "com.spotify.client") as SpotifyApplication!
    
    var repeatItem: NSMenuItem!
    var shuffleItem: NSMenuItem!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(timerDidFire), userInfo: nil, repeats: true);
        NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: #selector(notify), name: "com.spotify.client.PlaybackStateChanged", object: nil);
        NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateIcon), name: "AppleInterfaceThemeChangedNotification", object: nil);
        NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: #selector(test), name: "com.apple.HIToolbox.beginMenuTrackingNotification", object: nil);
        statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1.0)
        statusItem.image = NSImage(named: "spotify");
        
        repeatItem = NSMenuItem(title: "Repeat: \(spotify.repeating!.boolValue ? "On" : "Off")", action: #selector(toggleRepeat), keyEquivalent: "");
        shuffleItem = NSMenuItem(title: "Shuffle: \(spotify.shuffling!.boolValue ? "On" : "Off")", action: #selector(toggleShuffle), keyEquivalent: "");
        
        statusMenu = NSMenu();
        
        statusMenu.addItem(repeatItem);
        statusMenu.addItem(shuffleItem);
        statusMenu.addItem(NSMenuItem.separatorItem());
        statusMenu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: ""));
        
        statusItem.menu = statusMenu;
        statusItem.highlightMode = true;
        updateIcon();
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    func test() {
        delay(1) {
            print("Hit");
        }
    }
    
    func timeFormatted(totalSeconds: Int) -> String {
        let seconds: Int = totalSeconds % 60;
        let minutes: Int = (totalSeconds / 60) % 60;
        let hours: Int = totalSeconds / 3600;
        
        return hours == 0 ? String.init(format: "%02d:%02d", minutes, seconds) : String.init(format: "%02d:%02d%02d", hours, minutes, seconds);
    }
    
    func updateIcon() {
        pausedIcon = NSUserDefaults.standardUserDefaults().stringForKey("AppleInterfaceStyle") == "Dark" ? "spotify-white" : "spotify-black";
        if (spotify.playerState == SpotifyEPlS.Playing) {
            statusItem.image = NSImage(named: "spotify");
        } else {
            statusItem.image = NSImage(named: pausedIcon);
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        NSDistributedNotificationCenter.defaultCenter().removeObserver(self);
        spotify = nil;
        statusItem = nil;
        statusMenu = nil;
        timer.invalidate();
        timer = nil;
    }
    
    func timerDidFire() {
        updateTrackInfo();
        repeatItem.title = "Repeat: \(spotify.repeating!.boolValue ? "On" : "Off")";
        shuffleItem.title = "Shuffle: \(spotify.shuffling!.boolValue ? "On" : "Off")";
    }
    
    func notify() {
        updateTrackInfo();
        updateIcon();
    }
    
    func quit(sender : NSMenuItem) {
        NSApp.terminate(self);
    }
    
    func updateTrackInfo() {
        if (spotify.playerState == SpotifyEPlS.Playing) {
            let current = spotify.currentTrack!;
            let position = timeFormatted(Int(spotify.playerPosition!));
            let duration = timeFormatted((current.duration)! / 1000);
            statusItem.title = String.init(format: "%@ - %@ (%@/%@)", (current.artist)!, (current.name)!, position, duration);
        } else {
            statusItem.title = "▐▐";
        }
    }

    func toggleRepeat() {
        spotify.setRepeating!(!spotify.repeating!.boolValue);
        repeatItem.title = "Repeat: \(spotify.repeating!.boolValue ? "On" : "Off")";
    }

    func toggleShuffle() {
        spotify.setShuffling!(!spotify.shuffling!.boolValue);
        shuffleItem.title = "Shuffle: \(spotify.shuffling!.boolValue ? "On" : "Off")";
    }
}

