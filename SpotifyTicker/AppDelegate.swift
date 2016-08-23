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
    
    weak var pausedIcon: NSString!
    
    var spotifyController: SpotifyController! = SpotifyController();
    var popoverController: PopoverController! = PopoverController(nibName: "PopoverController", bundle: nil);
    
    var eventMonitor: EventMonitor!
    
    lazy var statusItem: NSStatusItem = {
        let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength);
        statusItem.button?.target = self;
        statusItem.button?.action = #selector(AppDelegate.showContextMenu(_:));
        let options: NSEventMask = [.LeftMouseUpMask, .RightMouseUpMask];
        statusItem.button?.sendActionOn(Int(options.rawValue));
        return statusItem;
    }()
    
    lazy var statusMenu: NSMenu = {
        let rightClickMenu = NSMenu();
        rightClickMenu.addItem(NSMenuItem(title: "Quit", action: #selector(AppDelegate.quit), keyEquivalent: ""));
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
        
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(timerDidFire), userInfo: nil, repeats: true);
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)

        NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: #selector(notify), name: "com.spotify.client.PlaybackStateChanged", object: nil);
        NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: #selector(toggleDark), name: "AppleInterfaceThemeChangedNotification", object: nil);
        
        toggleDark();
        updateImage();
        
        eventMonitor = EventMonitor(mask: NSEventMask.LeftMouseDownMask) { [unowned self] event in
            if self.popover.shown {
                self.closePopover(event);
            }
        }
        eventMonitor.start();
        timer.fire();
    }
    
    func showContextMenu(sender: NSStatusBarButton!){
        switch NSApp.currentEvent!.type {
        case .RightMouseUp:
            statusItem.popUpStatusItemMenu(statusMenu);
        default:
            togglePopover(sender);
        }
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
        updateTrackInfo();
        updateImage();
    }
    
    func updateTrackInfo() {
        if (spotifyController.isPlaying()) {
            let current = spotifyController.currentTrack();
            let position = timeFormatted(spotifyController.playerPosition());
            let duration = timeFormatted((current.duration)! / 1000);
            updateTitle("\(current.artist!) - \(current.name!) (\(position)/\(duration)");
        } else {
            statusItem.title = "▐▐ ";
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

