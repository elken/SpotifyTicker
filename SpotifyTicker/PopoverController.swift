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
    
    var spotify: SpotifyController! = SpotifyController();
    
    var currentArtwork: NSString! = "";
    
    var currentImage: NSImage!
    
    @IBOutlet weak var artistLabel: NSTextField!
    @IBOutlet weak var songLabel: NSTextField!
    @IBOutlet weak var albumLabel: NSTextField!
    
    @IBOutlet weak var imageView: NSImageView!
    
    @IBOutlet weak var playPauseButton: NSButton!
    @IBOutlet weak var repeatButton: NSButton!
    @IBOutlet weak var shuffleButton: NSButton!
    
    @IBOutlet weak var volumeSlider: NSSlider!
    @IBOutlet weak var volumeLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad();
        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(timerDidFire), userInfo: nil, repeats: true);
        
        updateView();
    }
    
    /**
     Update the relevant view items. Could be lazier.
     */
    func updateView() {
        artistLabel.stringValue = spotify.currentTrack().artist!;
        albumLabel.stringValue = spotify.currentTrack().album!;
        songLabel.stringValue = spotify.currentTrack().name!;
        
        playPauseButton.image = NSImage(named: spotify.isPlaying() ? "pauseTemplate" : "playTemplate");
        
        volumeLabel.stringValue = "Volume: \(spotify.volume()) %";
        volumeSlider.integerValue = spotify.volume();
        updateShuffleStatus();
        updateRepeatStatus();
        updateArtwork();
    }
    
    func timerDidFire() {
        updateView();
    }
    
    func updateArtwork() {
        if currentImage == nil {
            downloadArtwork();
        }
        imageView.image = currentImage;
    }
    
    func downloadArtwork() {
        let id = spotify.currentTrack().id!().characters.split{ $0 == ":" }.map(String.init)[2];
        if let url = NSURL(string: "https://api.spotify.com/v1/tracks/\(id)"){
            let request = NSMutableURLRequest(URL: url);
            request.HTTPMethod = "GET";
            
            let session = NSURLSession.sharedSession();
            session.dataTaskWithRequest(request, completionHandler: { (returnData, response, error) -> Void in
                do {
                    let jsonResult: NSDictionary = try NSJSONSerialization.JSONObjectWithData(returnData!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary;
                    let result = jsonResult["album"]!["images"]!![1]["url"]!! as! NSString;
                    if !self.currentArtwork.isEqualToString(result as String) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                            let data = NSData(contentsOfURL: NSURL(string: result as String)!);
                            dispatch_async(dispatch_get_main_queue(), {
                                self.currentImage = NSImage(data: data!);
                            });
                        }
                        
                        self.currentArtwork = result;
                    }
                } catch {
                    print("Error parsing.");
                }
                
            }).resume();
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
    
    @IBAction func sliderChange(sender: NSSliderCell) {
        volumeLabel.stringValue = "Volume: \(spotify.volume()) %";
        spotify.setVolume(sender.integerValue);
    }
}
