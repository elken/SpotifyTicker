//
//  About.swift
//  SpotifyTicker
//
//  Created by elken on 23/08/2016.
//  Copyright © 2016 tdos. All rights reserved.
//

import Cocoa

class AboutController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func githubClicked(sender: AnyObject) {
        if let url = NSURL(string: "http://www.github.com/elken") {
            NSWorkspace.sharedWorkspace().openURL(url)
        }
    }
}
