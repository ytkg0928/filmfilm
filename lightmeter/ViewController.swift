//
//  ViewController.swift
//  lightmeter
//
//  Created by Yuto Takagi on 2017/10/14.
//  Copyright © 2017年 Yuto Takagi. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var currentCameraPosition: AVCaptureDevice.Position?
    var captureSession: AVCaptureSession!
    
    @IBOutlet var cameraView: UIView!
    @IBOutlet var slider: UISlider!
    @IBOutlet var calibrationLabel: UILabel!
    @IBOutlet var luxValueLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.calibrationLabel.text = String(self.slider.value)
        initCamera()
    }
    
    func initCamera() {
        
        self.captureSession = AVCaptureSession()
        self.captureSession.sessionPreset = AVCaptureSession.Preset.medium
        
        let captureVideoPreviewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        
        captureVideoPreviewLayer.frame = self.cameraView.layer.bounds
        
        self.cameraView.layer.addSublayer(captureVideoPreviewLayer)
        
        // MARK: - 納得いかない
        // let device: AVCaptureDevice = AVCaptureDevice.Position.front
        // let device: AVCaptureDevice!
        // device.position = AVCaptureDevice.Position.front
        
        let device:AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)!
        
        let input = try? AVCaptureDeviceInput(device: device)

        currentCameraPosition = device.position
        
        if input == nil {
            // Handle the error appropriately.
            print("ERROR")
        }
        
        self.captureSession.addInput(input!)
        
        let output: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        self.captureSession.addOutput(output)
        
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
      
        // dispatch_queue_t queue = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL);
        
        let queue = DispatchQueue(label: "VideoQueue", attributes: .concurrent)
        output.setSampleBufferDelegate(self, queue: queue)
        
        self.captureSession.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // MARK: - えぐい
        let exifDictionary = CMGetAttachment(sampleBuffer, kCGImagePropertyExifDictionary, nil)
        print(exifDictionary)
        
        if exifDictionary != nil {
            let c: Double = 1.0
            let n: Double = exifDictionary?.value(forKey: "FNumber") as! Double
            let t: Double = exifDictionary?.value(forKey: "ExposureTime") as! Double
            let s: Double = (exifDictionary?.value(forKey: "ISOSpeedRatings") as! NSArray).firstObject as! Double
            var lux: Double = (c * n * n) / (t * s)
            lux -= 0.09
            lux = lux <= 0 ? 0 : lux
            lux *= Double(self.calibrationLabel.text!)!
            
            print(lux)
            
            DispatchQueue.main.async {
                self.luxValueLabel.text = String(lux)
            }
        }
        
        
    }
    
    @IBAction func frontCameraButton() {
        if let captureSession = self.captureSession {
            captureSession.beginConfiguration()
            
            let currentCameraInput: AVCaptureInput = captureSession.inputs[0]
            captureSession.removeInput(currentCameraInput)
            
            let newCamera: AVCaptureDevice?
            
            if currentCameraPosition! == .back {
                newCamera = self.cameraWithPosition(position: .front)
            } else {
                newCamera = self.cameraWithPosition(position: .back)
            }
            
            let newVideoInput: AVCaptureDeviceInput = try! AVCaptureDeviceInput(device: newCamera!)
            captureSession.addInput(newVideoInput)
            
            captureSession.commitConfiguration()
        }
    }
    
    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: .video)
        for device in devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    @IBAction func sliderChanged(sender: UISlider) {
        self.calibrationLabel.text = String(sender.value)
    }
}


