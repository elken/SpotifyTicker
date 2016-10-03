/*
*  AppDelegate.swift
*  SpotifyTicker
*
*  Created by elken on 16/08/2016.
*  Copyright © 2016 tdos. All rights reserved.
*/

import Cocoa
import ScriptingBridge
import Darwin

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    weak var timer: NSTimer!
    
    var pausedIcon: String!
    var titleFormat: String!
    
    var spotifyController: SpotifyController! = SpotifyController();
    var preferencesController: PreferencesController! = PreferencesController(nibName: "Preferences", bundle: nil);
    var popoverController: PopoverController! = PopoverController(nibName: "PopoverController", bundle: nil);
    
    var eventMonitor: EventMonitor!
    
    lazy var statusItem: NSStatusItem = {
        let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength);
        statusItem.button?.target = self;
        statusItem.button?.action = #selector(AppDelegate.showContextMenu(_:));
        let options: NSEventMask = [NSLeftMouseUpMask, NSRightMouseUpMask];
        statusItem.button?.sendActionOn(NSEventMask(rawValue: UInt64(Int(options.rawValue))));
        return statusItem;
    }()
    
    lazy var statusMenu: NSMenu = {
        let rightClickMenu = NSMenu();
        rightClickMenu.addItem(NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: ""));
        rightClickMenu.addItem(NSMenuItem(title: "Preferences", action: #selector(showPreferences), keyEquivalent: ""));
        rightClickMenu.addItem(NSMenuItem.separatorItem());
        rightClickMenu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: ""));
        return rightClickMenu;
    }()
    
    lazy var popover: NSPopover! = {
        let popover = NSPopover();
        popover.contentViewController = self.popoverController;
        popover.animates = true;
        popover.behavior = .Transient;
        return popover;
    }()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
//        self.popoverController.downloadArtwork();
        
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(timerDidFire), userInfo: nil, repeats: true);
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)

        NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: #selector(notify), name: "com.spotify.client.PlaybackStateChanged", object: nil);
        NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: #selector(toggleDark), name: "AppleInterfaceThemeChangedNotification", object: nil);
        NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateIconImage), name: "com.elken.SpotifyTicker.updateIcon", object: nil);
        NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateFormat), name: "com.elken.SpotifyTicker.updateFormat", object: nil);
        
        toggleDark();
        updateIconImage();
        updateFormat();
        updateTrackInfo();
        
        eventMonitor = EventMonitor(mask: NSLeftMouseDownMask) { [unowned self] event in
            if self.popover.shown {
                self.closePopover(event);
            }
        }
        eventMonitor.start();
        timer.fire();
    }
    
    func updateFormat() {
        titleFormat = preferencesController.checkOrDefault("titleFormat", def: "%a - %s (%p/%d)");
    }
    
    func showPreferences() {
        preferencesController.title = "Preferences";
        preferencesController.presentViewControllerAsModalWindow(preferencesController);
    }
    
    func showAbout() {
        let aboutController: AboutController! = AboutController(nibName: "About", bundle: nil);
        aboutController.title = "About";
        aboutController.presentViewControllerAsModalWindow(aboutController);
    }
    
    func showContextMenu(sender: NSStatusBarButton!){
        switch NSApp.currentEvent!.type {
        case .RightMouseUp:
            statusItem.popUpStatusItemMenu(statusMenu);
        default:
            togglePopover(sender);
        }
    }
    
    func updateIconImage() {
        if preferencesController.checkOrDefault("showIcon", def: 1) == 1 {
            statusItem.image = NSImage(named: updateIcon());
        } else {
            statusItem.image = nil;
        }
    }
    
    func updateTitle(name: String) {
        statusItem.title = name;
    }
    
    func showPopover(sender: AnyObject?) {
        if let button = statusItem.button {
            popover.showRelativeToRect(button.bounds, ofView: button, preferredEdge: NSRectEdge.MinY);
        }
        eventMonitor!.start();
    }
    
    func closePopover(sender: AnyObject?) {
        popover.performClose(sender);
        eventMonitor!.stop();
    }
    
    func togglePopover(sender: AnyObject?) {
        if popover.shown {
            closePopover(sender);
        } else {
            showPopover(sender);
        }
    }
    
    func timeFormatted(totalSeconds: Int) -> String {
        let seconds: Int = totalSeconds % 60;
        let minutes: Int = (totalSeconds / 60) % 60;
        let hours: Int = totalSeconds / 3600;
        
        return hours == 0 ? String(format: "%02d:%02d", minutes, seconds) : String(format: "%02d:%02d%02d", hours, minutes, seconds);
    }
    
    func updateIcon() -> String {
        return (spotifyController.isPlaying() ? "spotify" : pausedIcon) as String;
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        NSDistributedNotificationCenter.defaultCenter().removeObserver(self);
        timer.invalidate();
        timer = nil;
    }
    
    func timerDidFire() {
        updateTrackInfo();
    }
    
    func notify() {
//        self.popoverController.downloadArtwork();
        updateTrackInfo();
    }
    
    func updateTrackInfo() {
        if (spotifyController.isPlaying()) {
            let current = spotifyController.currentTrack();
            let position = timeFormatted(spotifyController.playerPosition());
            let duration = timeFormatted((current.duration)! / 1000);
            var format: String = titleFormat;
            
            let d: [String: String] = ["%a": "\(current.artist!)",
                                       "%s": "\(current.name!)",
                                       "%p": "\(position)",
                                       "%d": "\(duration)"];
            
            for (key, value) in d {
                if format.containsString(key) {
                    if value.characters.count >= 20 {
                        format = format.stringByReplacingOccurrencesOfString(key, withString: "\(value.substringToIndex(value.startIndex.advancedBy(20))) ...");
                    }
                    format = format.stringByReplacingOccurrencesOfString(key, withString: value);
                }
            }
            updateTitle(format);
        } else {
            statusItem.title = "▐▐ ";
        }
    }
    
    func toggleDark() {
        pausedIcon = NSUserDefaults.standardUserDefaults().stringForKey("AppleInterfaceStyle") == "Dark" ? "spotify-white" : "spotify-black";
        updateIconImage();
    }
    
    func quit(sender : NSMenuItem) {
        NSApplication.sharedApplication().terminate(self);
    }
}

