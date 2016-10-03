//
//  Preferences.swift
//  SpotifyTicker
//
//  Created by elken on 23/08/2016.
//  Copyright © 2016 tdos. All rights reserved.
//

import Cocoa

class PreferencesController: NSViewController {

    @IBOutlet weak var showIconButton: NSButton!
    
    @IBOutlet weak var artworkSizeCombo: NSComboBox!
    
    var prefs = NSUserDefaults.standardUserDefaults();
    
    /**
    Testing help
    */
    @IBOutlet weak var titleFormatBox: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad();
        showIconButton.state = checkOrDefault("showIcon", def: 1);
        artworkSizeCombo.selectItemAtIndex(checkOrDefault("artworkSize", def: 1));
        titleFormatBox.stringValue = checkOrDefault("titleFormat", def: "%a - %s (%p/%d)");
    }
    
    func checkOrDefault<ReturnType>(key: String, def: Any?) -> ReturnType {
        if let val = prefs.valueForKey(key) {
            return val as! ReturnType;
        } else {
            return def as! ReturnType;
        }
    }
    
    @IBAction func toggleShowIcon(sender: NSButton) {
        prefs.setObject(sender.state, forKey: "showIcon");
        NSDistributedNotificationCenter.defaultCenter().postNotificationName("com.elken.SpotifyTicker.updateIcon", object: nil);
    }
    
    @IBAction func artworkSizeChanged(sender: NSComboBox) {
        prefs.setObject(sender.indexOfSelectedItem, forKey: "artworkSize");
        NSDistributedNotificationCenter.defaultCenter().postNotificationName("com.elken.SpotifyTicker.updateArtworkSize", object: nil);
    }
    
    @IBAction func formatHelpClicked(sender: NSButton) {
        let popover: NSPopover! = {
            let popover = NSPopover();
            popover.contentViewController = FormatHelp();
            popover.animates = true;
            popover.behavior = .Transient;
            return popover;
        }()
        popover.showRelativeToRect(sender.bounds, ofView: sender, preferredEdge: NSRectEdge.MinY);

    }
    
    @IBAction func titleFormatChanged(sender: AnyObject) {
        prefs.setObject(sender.stringValue!, forKey: "titleFormat");
        NSDistributedNotificationCenter.defaultCenter().postNotificationName("com.elken.SpotifyTicker.updateFormat", object: nil);
    }
}
