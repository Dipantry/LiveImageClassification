//
//  ViewController.swift
//  LiveImageClassification
//
//  Created by Auriga Aristo on 28/10/20.
//

import UIKit
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    
    private let classificationModel = try! Inceptionv3(configuration: .init())
    
    var videoHandler: VideoHandler!
    
    var request: VNCoreMLRequest?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupModel()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        videoHandler.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        videoHandler.stop()
    }
    
    func setupModel(){
        if let visionModel = try? VNCoreMLModel(for: classificationModel.model) {
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .scaleFill
        } else {
            fatalError()
        }
    }
    
    func setupCamera(){
        videoHandler = VideoHandler()
        videoHandler.delegate = self
        videoHandler.fps = 50
        videoHandler.setUp(sessionPreset: .vga640x480) { success in
            
            if success {
                if let previewLayer = self.videoHandler.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                
                self.videoHandler.start()
            }
        }
    }
    
    func resizePreviewLayer() {
        videoHandler.previewLayer?.frame = videoPreview.bounds
    }
}

extension ViewController: VideoHandlerDelegate {
    func videoCapture(_ capture: VideoHandler, didCaptureVideoFrame: CVPixelBuffer?) {
        if let pixelBuffer = didCaptureVideoFrame {
            self.predictUsingVision(pixelBuffer: pixelBuffer)
        }
    }
}

extension ViewController {
    func predictUsingVision(pixelBuffer: CVPixelBuffer){
        guard let request = request else {
            fatalError()
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }

    func visionRequestDidComplete(request: VNRequest, error: Error?){
        if let classificationResults = request.results as? [VNClassificationObservation] {
            guard let result = classificationResults.first else {
                showFailResult()
                return
            }
            
            showResults(objectLabel: result.identifier, confidence: result.confidence)
        }
    }

    func showFailResult() {
        DispatchQueue.main.sync {
            self.nameLabel.text = "n/a result"
            self.confidenceLabel.text = "-- %"
        }
    }

    func showResults(objectLabel: String, confidence: VNConfidence) {
        DispatchQueue.main.sync {
            self.nameLabel.text = objectLabel
            self.confidenceLabel.text = "\(round(confidence * 100)) %"
        }
    }
}
