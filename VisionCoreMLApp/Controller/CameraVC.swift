//
//  CameraVC.swift
//  VisionCoreMLApp
//
//  Created by IceApinan on 26/9/17.
//  Copyright © 2017 IceApinan. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum FlashState {
    case off
    case on
}

class CameraVC: UIViewController {

    var captureSession: AVCaptureSession!
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var photoData: Data?
    
    var flashControlState: FlashState = .off
    var speechSynthesizer = AVSpeechSynthesizer()
    let activityIndicator = UIActivityIndicatorView()
    
    @IBOutlet weak var captureImageView: RoundedShadowImageView!
    @IBOutlet weak var flashButton: RoundedShadowButton!
    @IBOutlet weak var identificationLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var roundedLabelView: RoundedShadowView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraView.bounds
        speechSynthesizer.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tap.numberOfTapsRequired = 1
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: .video)
        
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
                cameraView.addGestureRecognizer(tap)
                captureSession.startRunning()
            }
        } catch {
            debugPrint(error)
        }
    }
    
    @objc func didTapCameraView() {
        let settings = AVCapturePhotoSettings()
        self.cameraView.isUserInteractionEnabled = false
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        if flashControlState == .off {
            settings.flashMode = .off
        } else {
            settings.flashMode = .on
        }
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func resultsMethod(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else { return }
        DispatchQueue.main.async {
            for classification in results {
                if classification.confidence < 0.5 {
                    let unknowObjectMessage = "I'm not sure what this is. Please try again."
                    self.identificationLabel.text = unknowObjectMessage
                    self.confidenceLabel.text = ""
                    self.synthesizeSpeech(fromString: unknowObjectMessage)
                    break
                } else {
                    let identification = classification.identifier
                    let confidence = Int(classification.confidence * 100)
                    self.identificationLabel.text = identification
                    self.confidenceLabel.text = "CONFIDENCE: \(confidence)%"
                   let completeSentence = "This looks like a \(identification) and I'm \(confidence) percent sure."
                    self.synthesizeSpeech(fromString: completeSentence)
                    break
                }
            }
        }
        
    }
    func synthesizeSpeech(fromString string: String) {
        let utterance = AVSpeechUtterance(string: string)
        speechSynthesizer.speak(utterance)
    }
    
    @IBAction func flashButtonPressed(_ sender: Any) {
        switch flashControlState {
        case .off:
            flashButton.setTitle("FLASH ON", for: .normal)
            flashControlState = .on
        case .on:
            flashButton.setTitle("FLASH OFF", for: .normal)
            flashControlState = .off
        }
    }
}

extension CameraVC: AVCapturePhotoCaptureDelegate {
    fileprivate func showActivityIndicator() {
        activityIndicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = .whiteLarge
        self.view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    fileprivate func startVisionModelRequest(model: MLModel) {
        do {
            let model = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: model, completionHandler: self.resultsMethod)
            let handler = VNImageRequestHandler(data: self.photoData!, options: [:])
            try handler.perform([request])
        } catch {
            debugPrint(error)
        }
        
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            debugPrint(error)
        } else {
            photoData = photo.fileDataRepresentation()
            showActivityIndicator()
            DispatchQueue.global().async {
                self.startVisionModelRequest(model: Resnet50().model)
            }
                let image = UIImage(data: self.photoData!)
                self.captureImageView.image = image
        }
    }
}

extension CameraVC: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.cameraView.isUserInteractionEnabled = true
    }
}

