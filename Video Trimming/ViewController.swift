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
                    
                }
            } else {
                print(exportSession?.error?.localizedDescription)
            }
        })
        
        
        
        


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



