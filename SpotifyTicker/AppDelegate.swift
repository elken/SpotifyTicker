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

    var statusMenu: NSMenu!
    var timer: NSTimer!
    var statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)

    var pausedIcon: String!
    
    var popover: NSPopover!
    
    var spotifyController: SpotifyController!
    var popoverController: PopoverController!
    
    var eventMonitor: EventMonitor!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        popover = NSPopover();
        statusMenu = NSMenu();
        spotifyController = SpotifyController();
        
        if let button = statusItem.button {
            button.action = #selector(togglePopover);
        }
        
        popoverController = PopoverController(nibName: "PopoverController", bundle: nil);
        popover.contentViewController = popoverController;
        popover.behavior = NSPopoverBehavior.Transient;
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(timerDidFire), userInfo: nil, repeats: true);
        NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: #selector(notify), name: "com.spotify.client.PlaybackStateChanged", object: nil);
        NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: #selector(toggleDark), name: "AppleInterfaceThemeChangedNotification", object: nil);
        
        statusItem.highlightMode = true;
        toggleDark();
        updateImage();
        
        // Event monitor to listen for clicks outside the popover
        eventMonitor = EventMonitor(mask: NSEventMask.LeftMouseDownMask) { [unowned self] event in
            if self.popover.shown {
                self.closePopover(event);
            }
        }
        eventMonitor.start();
    }
    
    func updateImage() {
        statusItem.image = NSImage(named: updateIcon());
    }
    
    func updateTitle(name: String) {
        statusItem.title = name;
    }
    
    func showPopover(sender: AnyObject?) {
        if let button = statusItem.button {
            popover.showRelativeToRect(button.bounds, ofView: button, preferredEdge: NSRectEdge.MinY);
            popoverController.updateView();
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
        
        return hours == 0 ? String.init(format: "%02d:%02d", minutes, seconds) : String.init(format: "%02d:%02d%02d", hours, minutes, seconds);
    }
    
    func updateIcon() -> String {
        return spotifyController.isPlaying() ? "spotify" : pausedIcon;
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        NSDistributedNotificationCenter.defaultCenter().removeObserver(self);
        statusMenu = nil;
        timer.invalidate();
        timer = nil;
    }
    
    func timerDidFire() {
        updateTrackInfo();
    }
    
    func notify() {
        updateTrackInfo();
        updateImage();
    }
    
    func updateTrackInfo() {
        if (spotifyController.isPlaying()) {
            let current = spotifyController.currentTrack();
            let position = timeFormatted(spotifyController.playerPosition());
            let duration = timeFormatted((current.duration)! / 1000);
            updateTitle(String.init(format: "%@ - %@ (%@/%@)", (current.artist)!, (current.name)!, position, duration));
        } else {
            statusItem.title = "▐▐";
        }
    }
    
    func toggleDark() {
        pausedIcon = NSUserDefaults.standardUserDefaults().stringForKey("AppleInterfaceStyle") == "Dark" ? "spotify-white" : "spotify-black";
        updateImage();
    }
    
    func quit(sender : NSMenuItem) {
        NSApp.terminate(self);
    }
}

