//
//  CameraViewController.swift
//  AI Snap
//
//  Created by Timothy Barrett on 7/16/17.
//  Copyright © 2017 Timothy Barrett. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

class CameraViewController: UIViewController {

  var captureSession: AVCaptureSession!
  var cameraOutput: AVCapturePhotoOutput!
  var previewLayer: AVCaptureVideoPreviewLayer!
  var photoData: Data?
  var flashControlState: FlashState = .off
  var speechSynthesizer = AVSpeechSynthesizer()
  
  @IBOutlet weak var activitySpinner: UIActivityIndicatorView!
  @IBOutlet weak var roundedLabelView: RoundedShadowView!
  @IBOutlet weak var cameraView: UIView!
  @IBOutlet weak var itemCapturedLabel: UILabel!
  @IBOutlet weak var confidenceLevelLabel: UILabel!
  @IBOutlet weak var flashOnOrOffButton: RoundedShadowButton!
  @IBOutlet weak var capturedImageView: RoundedShadowImageView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    speechSynthesizer.delegate = self
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
    tapGesture.numberOfTapsRequired = 1
    
    captureSession = AVCaptureSession()
    captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
    
    let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
    
    do {
      let input = try AVCaptureDeviceInput(device: backCamera!)
      if captureSession.canAddInput(input) {
        captureSession.addInput(input)
      }
      
      cameraOutput = AVCapturePhotoOutput()
      
      if captureSession.canAddOutput(cameraOutput) {
        captureSession.addOutput(cameraOutput!)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        
        cameraView.layer.addSublayer(previewLayer!)
        cameraView.addGestureRecognizer(tapGesture)
        captureSession.startRunning()
      }
    } catch {
      debugPrint(error)
    }
  }
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    previewLayer.frame = cameraView.bounds
  }
  
  @objc func didTapCameraView() {
    cameraView.isUserInteractionEnabled = false
    activitySpinner.startAnimating()
    activitySpinner.isHidden = false
    
    let settings = AVCapturePhotoSettings()
    let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
    let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType, kCVPixelBufferWidthKey as String: 160, kCVPixelBufferHeightKey as String: 160]
    
    settings.previewPhotoFormat = previewFormat
    
    if flashControlState == .off {
      settings.flashMode = .off
    } else {
      settings.flashMode = .on
    }
    
    cameraOutput.capturePhoto(with: settings, delegate: self)
  }
  
  func resultsMethod(request: VNRequest, error: Error?) {
    guard let results = request.results as? [VNClassificationObservation] else { return }
    
    for classification in results {
      if classification.confidence < 0.5 {
        let unknownObjectMessage = "I'm not sure what this is...Please try again."
        itemCapturedLabel.text = unknownObjectMessage
        synthesizespeech(fromString: unknownObjectMessage)
        confidenceLevelLabel.text = ""
        break
      } else {
        let identification = classification.identifier
        let confidence = Int(classification.confidence * 100)
        itemCapturedLabel.text = identification
        confidenceLevelLabel.text = "CONFIDENCE: \(confidence)%"
        let completeMessage = "This looks like a \(identification) and I'm \(confidence) percent sure"
        synthesizespeech(fromString: completeMessage)
        break
      }
    }
  }
  
  func synthesizespeech(fromString string: String) {
    let speechUtterance = AVSpeechUtterance(string: string)
    speechSynthesizer.speak(speechUtterance)
  }
  
  @IBAction func flashButtonTapped(_ sender: RoundedShadowButton) {
    switch flashControlState {
    case .off:
      flashOnOrOffButton.setTitle("FLASH ON", for: .normal)
      flashControlState = .on
    case .on:
      flashOnOrOffButton.setTitle("FLASH OFF", for: .normal)
      flashControlState = .off
    }
  }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
  
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    if let error = error {
      debugPrint(error)
    } else {
      photoData = photo.fileDataRepresentation()
      
      do {
        let model = try VNCoreMLModel(for: SqueezeNet().model)
        let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
        let handler = VNImageRequestHandler(data: photoData!)
        try handler.perform([request])
      } catch {
        debugPrint(error)
      }
      
      let image = UIImage(data: photoData!)
      capturedImageView.image = image
    }
  }
}

extension CameraViewController: AVSpeechSynthesizerDelegate {
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    cameraView.isUserInteractionEnabled = true
    activitySpinner.isHidden = true
    activitySpinner.stopAnimating()
  }
}
