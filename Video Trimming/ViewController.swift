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

class ViewController: UIViewController {

    @IBOutlet weak var movieView: UIView!
    var videoPlayerVC : AVPlayerViewController?
    var originalURL: URL?
    var destinationURL: URL?
    
    var totlaTime: NSInteger?
    var startTime: CMTime?
    var endTime: CMTime?
    
    typealias TrimPoints = [(CMTime, CMTime)]
    typealias TrimCompletion = (NSError?) -> ()
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configPlayer()
    }
    
    
    // MARK: - Private

    func configPlayer() {
        self.videoPlayerVC = AVPlayerViewController.init()
        let bounds = movieView.bounds
        videoPlayerVC?.view.frame = bounds
        videoPlayerVC?.view.autoresizingMask = .flexibleWidth
        movieView.addSubview((videoPlayerVC?.view)!)
    }
    
    func playVideo() {
        
        let asset = AVAsset.init(url: originalURL!)

        
        videoPlayerVC?.player = AVPlayer.init(url: originalURL!)
        videoPlayerVC?.player?.play()
    }
    
    
    func trimVideo(sourceURL: URL, destinationURL: URL, trimPoints: TrimPoints, completion: TrimCompletion?) {
        
        guard sourceURL.isFileURL else { return }
        guard destinationURL.isFileURL else { return }
        
        let options = [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ]
        
        let asset = AVURLAsset(url: sourceURL as URL, options: options)
        let preferredPreset = AVAssetExportPresetPassthrough
        
            
            let composition = AVMutableComposition()
        let videoCompTrack = composition.addMutableTrack(withMediaType: kUTTypeMovie as AVMediaType, preferredTrackID: CMPersistentTrackID())
        let audioCompTrack = composition.addMutableTrack(withMediaType: kUTTypeMovie as AVMediaType, preferredTrackID: CMPersistentTrackID())
            
        guard let assetVideoTrack: AVAssetTrack = asset.tracks(withMediaType: AVMediaType.video as AVMediaType).first else { return }
        guard let assetAudioTrack: AVAssetTrack = asset.tracks(withMediaType: AVMediaType.audio as AVMediaType).first else { return }
        


            var accumulatedTime = kCMTimeZero
            for (startTimeForCurrentSlice, endTimeForCurrentSlice) in trimPoints {
                let durationOfCurrentSlice = CMTimeSubtract(endTimeForCurrentSlice, startTimeForCurrentSlice)
                let timeRangeForCurrentSlice = CMTimeRangeMake(startTimeForCurrentSlice, durationOfCurrentSlice)
                
                do {
                    try videoCompTrack?.insertTimeRange(timeRangeForCurrentSlice, of: assetVideoTrack, at: accumulatedTime)
                    try audioCompTrack?.insertTimeRange(timeRangeForCurrentSlice, of: assetAudioTrack, at: accumulatedTime)
                    accumulatedTime = CMTimeAdd(accumulatedTime, durationOfCurrentSlice)
                }
                catch let compError {
                    print("TrimVideo: error during composition: \(compError)")
                    completion?(compError as NSError)
                }
            }
            
            guard let exportSession = AVAssetExportSession(asset: composition, presetName: preferredPreset) else { return }
            
            exportSession.outputURL = destinationURL as URL
        exportSession.outputFileType = AVFileType.m4v
            exportSession.shouldOptimizeForNetworkUse = true
        
            originalURL =  exportSession.outputURL
            
            exportSession.exportAsynchronously {
                completion?((exportSession.error! as NSError))
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
        
        startTime = CMTimeMake(2, 1)
        endTime = CMTimeMake(4, 1)
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


extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        self.dismiss(animated: true)
        originalURL = info[UIImagePickerControllerMediaURL] as? URL
        self.playVideo()
        
    }
    
    
}



