//
//  ViewController.swift
//  Video Trimming
//
//  Created by IMAC 3 on 02.10.17.
//  Copyright © 2017 PasichniakMaryan. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVKit
import ABVideoRangeSlider
import Photos

class ViewController: UIViewController {
    
    @IBOutlet weak var movieView: UIView!
    @IBOutlet weak var videoRangeSlider: ABVideoRangeSlider!
    
    
    var videoPlayerVC : AVPlayerViewController?
    var originalURL: URL?
    var destinationURL: URL?
    
    var totlaTime: NSInteger?
    var startTime: CMTime?
    var endTime: CMTime?
    
    var startTimeSec = 0.0;
    var endTimeSec = 0.0;
    var progressTime = 0.0;
    var shouldUpdateProgressIndicator = true
    var isSeeking = false
    var timeObserver: AnyObject!
    
    typealias TrimPoints = [(CMTime, CMTime)]
    typealias TrimCompletion = (NSError?) -> ()
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.configPlayer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let photos = PHPhotoLibrary.authorizationStatus()
        if photos == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized{
                } else {}
            })
        }
        
    }
    
    
    // MARK: - Private
    
    func configPlayer() {
        
        self.videoPlayerVC = AVPlayerViewController.init()
        let bounds = movieView.bounds
        videoPlayerVC?.view.frame = bounds
        videoPlayerVC?.view.autoresizingMask = .flexibleWidth
        movieView.addSubview((videoPlayerVC?.view)!)
        
        let timeInterval: CMTime = CMTimeMakeWithSeconds(0.01, 100)
        timeObserver = videoPlayerVC?.player?.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main) {
            (elapsedTime: CMTime) -> Void in
            self.observeTime(elapsedTime: elapsedTime) } as AnyObject!
        
    }
    
    func configSlider() {
        
        videoRangeSlider.setVideoURL(videoURL: originalURL!)
        videoRangeSlider.delegate = self
        
    }
    
    
    private func observeTime(elapsedTime: CMTime) {
        
        let elapsedTime = CMTimeGetSeconds(elapsedTime)
        if ((videoPlayerVC?.player?.currentTime().seconds)! > self.endTimeSec){
            videoPlayerVC?.player?.pause()
        }
        if self.shouldUpdateProgressIndicator{
            videoRangeSlider.updateProgressIndicator(seconds: elapsedTime)
        }
    }
    
    func playVideo() {
        
        self.configSlider()
        shouldUpdateProgressIndicator = true
        let asset = AVAsset.init(url: originalURL!)
        videoPlayerVC?.player = AVPlayer.init(url: originalURL!)
        videoPlayerVC?.player?.play()
    }
    
    
    func trimVideo(sourceURL: URL, destinationURL: URL, trimPoints: TrimPoints, completion: TrimCompletion?) {
        
        let asset =  AVURLAsset.init(url: sourceURL)
        let exportSession = AVAssetExportSession.init(asset: asset, presetName: AVAssetExportPreset640x480)
        exportSession?.outputURL = destinationURL
        exportSession?.shouldOptimizeForNetworkUse = true
        exportSession?.outputFileType = AVFileType.mov
        exportSession?.timeRange = CMTimeRangeMake(startTime!, endTime!)
        exportSession?.exportAsynchronously(completionHandler: {
            if exportSession?.status == .completed {
                DispatchQueue.main.async {
                    let urlData = NSData.init(contentsOf: destinationURL)
                    do {
                        try urlData?.write(to: destinationURL, options: .atomic)
                    } catch {
                        print (error.localizedDescription)
                    }
                    print(exportSession?.error?.localizedDescription)
                    self.originalURL = destinationURL
                    self.playVideo()
                    self.saveToLibrary()
                    
                }
            } else {
                print(exportSession?.error?.localizedDescription)
            }
        })
        
    }
    
    func saveToLibrary() {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.destinationURL!)
        }) { saved, error in
            if saved {
                let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    
    // MARK: - Actions
    @IBAction func addVideoAction(_ sender: Any) {
        
        let imagePicker = UIImagePickerController.init()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = NSArray.init(objects: kUTTypeMovie) as! [String]
        self.present(imagePicker, animated: true)
    }
    
    @IBAction func doneAction(_ sender: Any) {
        
        startTime = CMTimeMake(Int64(startTimeSec), 1)
        endTime = CMTimeMake(Int64(endTimeSec), 1)
        let trimPoints = [(startTime, endTime)]
        let originStr = originalURL?.absoluteString
        let destStr = originStr?.prefix((originStr?.count)! - 8)
        destinationURL = URL.init(string: destStr! + ".MOV")
        
        self.trimVideo(sourceURL: originalURL!, destinationURL:destinationURL!, trimPoints: trimPoints as! ViewController.TrimPoints) { (error) in
            if error != nil {
                print(error?.localizedDescription)
            }
            self.playVideo()
            
        }
    }
    
    
}


extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, ABVideoRangeSliderDelegate {
    
    // MARK: - ABVideoRangeSliderDelegate
    func didChangeValue(videoRangeSlider: ABVideoRangeSlider, startTime: Float64, endTime: Float64) {
        
        self.endTimeSec = endTime
        if startTime != self.startTimeSec{
            self.startTimeSec = startTime
            let timescale =  videoPlayerVC?.player?.currentItem?.asset.duration.timescale
            let time = CMTimeMakeWithSeconds(self.startTimeSec, timescale!)
            if !self.isSeeking{
                self.isSeeking = true
                videoPlayerVC?.player?.seek(to: time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero){_ in
                    self.isSeeking = false
                }
            }
        }
        
    }
    
    func indicatorDidChangePosition(videoRangeSlider: ABVideoRangeSlider, position: Float64) {
        
        self.shouldUpdateProgressIndicator = false
        videoPlayerVC?.player?.pause()
        if self.progressTime != position {
            self.progressTime = position 
            let timescale = videoPlayerVC?.player?.currentItem?.asset.duration.timescale
            let time = CMTimeMakeWithSeconds(self.progressTime, timescale!)
            if !self.isSeeking{
                self.isSeeking = true
                videoPlayerVC?.player?.seek(to: time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero){_ in
                    self.isSeeking = false
                }
            }
        }
    }
    
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        self.dismiss(animated: true)
        originalURL = info[UIImagePickerControllerMediaURL] as? URL
        self.playVideo()
        
    }
    
    
}



