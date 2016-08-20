//
//  PopoverController.swift
//  SpotifyTicker
//
//  Created by elken on 20/08/2016.
//  Copyright © 2016 tdos. All rights reserved.
//

import Cocoa
import Foundation

class PopoverController: NSViewController {
    
    var repeatBox: NSButton!
    var spotify: SpotifyController!

    var currentArtwork: NSString!
    
    var imageView: NSImageView!
    
    var playPauseButton: NSButton!
    var shuffleButton: NSButton!
    var repeatButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad();
        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(timerDidFire), userInfo: nil, repeats: true);
        imageView = view.subviews.filter{$0 is NSImageView}[0] as! NSImageView;
        spotify = SpotifyController();
        let id = spotify.currentTrack().id!().characters.split{ $0 == ":" }.map(String.init)[2];
//        downloadArtwork(currentArtwork);
        if let url = NSURL(string: "https://api.spotify.com/v1/tracks/\(id)"){
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "GET"
            
            let session = NSURLSession.sharedSession()
            session.dataTaskWithRequest(request, completionHandler: { (returnData, response, error) -> Void in
                do {
                    let jsonResult: NSDictionary = try NSJSONSerialization.JSONObjectWithData(returnData!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                    print(jsonResult["album"]!["images"]!!);
                    self.downloadArtwork(jsonResult["album"]!["images"]!![0]["url"]!! as! NSString);
                } catch {
                    print("Error parsing.");
                }
                
            }).resume()
        }
        updateView();
    }
    
    /**
    Update the relevant view items. Could be lazier.
    */
    func updateView() {
        let buttons: [NSButton] = view.subviews.filter{$0 is NSButton} as! [NSButton];
        let labels: [NSTextField] = view.subviews.filter{$0 is NSTextField} as! [NSTextField];
        for button in buttons {
            if button.tag == 2 {
                playPauseButton = button;
                button.image = NSImage(named: spotify.isPlaying() ? "pauseTemplate" : "playTemplate");
            } else if button.tag == 4 {
                repeatButton = button;
                updateRepeatStatus();
            } else if button.tag == 5 {
                shuffleButton = button;
                updateShuffleStatus();
            }
        }
        
        for label in labels {
            if label.tag == 1 {
                label.stringValue = spotify.currentTrack().artist!;
            } else if label.tag == 2 {
                label.stringValue = spotify.currentTrack().name!;
            } else if label.tag == 3 {
                label.stringValue = spotify.currentTrack().album!;
            }
        }
    }
    
    func timerDidFire() {
        updateView();
    }

    func updateArtwork() {
        if !currentArtwork.isEqualToString(spotify.artworkURL()) {
            downloadArtwork(spotify.artworkURL());
        }
    }
    
    func downloadArtwork(urlToUse: NSString) {
        let url = NSURL(string: urlToUse as String)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let data = NSData(contentsOfURL: url!);
            dispatch_async(dispatch_get_main_queue(), {
                self.imageView.image = NSImage.init(data: data!);
            });
        }
    }
    
    func updateShuffleStatus() {
        shuffleButton.image = nil;
        shuffleButton.image = NSImage(named: spotify.isShuffling() ? "shufflePressed" : "shuffleTemplate");
    }
    
    func updateRepeatStatus() {
        repeatButton.image = nil;
        repeatButton.image = NSImage(named: spotify.isRepeating() ? "repeatPressed" : "repeatTemplate");
    }
    
    /**
     Action to handle the shuffle box being clicked.
     
     - parameter sender: ID of the object sending this
     */
    @IBAction func shuffleChecked(sender: NSButton) {
        print("Hit shuffle");
        spotify.toggleShuffle();
        updateShuffleStatus();
    }
    
    /**
    Action to handle the repeat box being clicked.
    
    - parameter sender: ID of the object sending this
     */
    @IBAction func repeatChecked(sender: NSButton) {
        print("Hit repeat");
        spotify.toggleRepeat();
        updateRepeatStatus();
    }
    
    @IBAction func rewindClicked(sender: NSButton) {
        spotify.previousTrack();
    }
    
    @IBAction func forwardClicked(sender: NSButton) {
        spotify.nextTrack();
    }
    
    @IBAction func playPauseClicked(sender: NSButton) {
        playPauseButton.image = nil;
        if (spotify.isPlaying()) {
            spotify.pause();
            playPauseButton.image = NSImage(named: "playTemplate");
        } else {
            spotify.play();
            playPauseButton.image = NSImage(named: "pauseTemplate");
        }
    }
}
