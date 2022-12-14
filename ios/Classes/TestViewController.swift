import UIKit
import AVFoundation
import Vision
import MLKitVision
import MLKitCommon
import MLCompute
import MLKitFaceDetection
 


protocol DismissProtocol{
    func sendData(filePath: String)
}

class TestViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureMessageText = ""
    var blinkMessageText = ""

    private let captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var drawings: [CAShapeLayer] = []
     
    var faceDetector = FaceDetector.faceDetector()

    var lastKnownDeviceOrientation : UIDeviceOrientation?
    var videoDataOutputQueue : DispatchQueue?
    var state : Int = 0
   // var Open_threshold : CGFloat = 0.85
   // var Close_threshold : CGFloat = 0.20
    var Open_threshold : CGFloat = 0.8
    var Close_threshold : CGFloat = 0.35
    var isEyeBlinked : Bool = false
    var mainBuffer : CMSampleBuffer?
    var overlayCircle : UIView = UIView()
    var backButton : UIButton = UIButton()
    var lblEyeBlink : UILabel = UILabel()
    //var bgImageView : UIImageView = UIImageView()
    var labelStatus : UILabel = UILabel()
    
    var dismissDelegate: DismissProtocol!

    
    let shape = CAShapeLayer()
    var borderColor : UIColor = UIColor.red

    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async { [self] in
                    self.backButton.frame = CGRect(x: self.view.frame.width - 50, y: 30, width: 40, height: 40)
            self.backButton.titleLabel?.font = UIFont.init(name: "GillSans", size: 20)
                    self.backButton.setTitle("X", for: .normal)
//                    self.backButton.setImage(UIImage.init(named: "close-button.png"), for: .normal)
            self.backButton.addTarget(self, action: #selector(self.backButtonPressed(sender:)), for: .touchUpInside)
            self.overlayCircle.frame = CGRect(x: (self.view.frame.width/2) - ((self.view.frame.width/1.3)/2), y: (self.view.frame.height/2) - ((self.view.frame.width)/2), width: (self.view.frame.width/1.3), height: (self.view.frame.width))
//            self.overlayCircle.layer.cornerRadius = self.overlayCircle.frame.height/2
            
            let gradient = CAGradientLayer()
            let size = CGSize(width: (self.view.frame.width/1.3), height: (self.view.frame.width))
            let rect = CGRect(origin: .zero, size: size)
            gradient.frame =  CGRect(origin: CGPoint.zero, size: size)
            gradient.colors = [UIColor.blue.cgColor, UIColor.green.cgColor]
//            let shape = CAShapeLayer()
            shape.lineWidth = 5
            shape.backgroundColor = UIColor.red.cgColor
            shape.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: (self.view.frame.width/1.3), height: (self.view.frame.width))).cgPath
            shape.strokeColor = borderColor.cgColor
            shape.fillColor = UIColor.clear.cgColor
            gradient.mask = shape
            self.overlayCircle.layer.addSublayer(shape)
             
                    self.labelStatus.frame = CGRect(x: 30, y:  70, width: self.view.frame.width - 60, height: 60)
                    self.lblEyeBlink.frame = CGRect(x: 30, y:  125, width: self.view.frame.width - 60, height: 30)
                    
            self.lblEyeBlink.text = self.blinkMessageText //"Blink your eyes"
             self.labelStatus.text = self.captureMessageText
            //"Your selfie will be captured. Hold steady and fill your face in the circle."
            //        self.labelStatus.font = UIFont.init(name: "Helvetica-BoldOblique", size: 17.0)
            //        self.lblEyeBlink.font = UIFont.init(name: "Helvetica-BoldOblique", size: 18.0)
                    
                    self.labelStatus.font = UIFont.init(name: "Helvetica-Bold", size: 17.0)
                    self.lblEyeBlink.font = UIFont.init(name: "Helvetica-Bold", size: 18.0)

                    self.labelStatus.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
                    self.lblEyeBlink.textColor = #colorLiteral(red: 0, green: 1, blue: 0, alpha: 1)
                    
                    self.labelStatus.numberOfLines = 0
                    self.lblEyeBlink.numberOfLines = 0
                    
                    //labelStatus.alpha = 0
                    self.captureSession.sessionPreset = .medium
                    self.labelStatus.textAlignment = .center
                    self.lblEyeBlink.textAlignment = .center
                    
                    self.lblEyeBlink.isHidden = true
            
            
            let options = FaceDetectorOptions()
            options.performanceMode = .accurate
            options.landmarkMode = .all
            options.classificationMode = .all
            self.faceDetector  = FaceDetector.faceDetector(options: options)
                    self.captureSession.startRunning()
                    self.addCameraInput()
                    self.showCameraFeed()
                    self.getCameraFrames()
        }
       
//        let viewww = self.createOverlay(frame: self.view.frame, xOffset: 50, yOffset: 50, radius: self.view.frame.width/2)

//        view.addSubview(viewww)

    }
    @objc func backButtonPressed(sender : UIButton){
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.frame
        self.previewLayer.addSublayer(self.overlayCircle.layer)
        overlayCircle.center = CGPoint(x: self.previewLayer.frame.size.width  / 2, y: self.previewLayer.frame.size.height / 2)
    }
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {
        
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer")
            return
        }
        self.detectFace(in: frame, sampleBuffer: sampleBuffer)
    }
 
    
    //send the image to the appdalegate class and returns to flutter
    func captureImageAfterBlink(sampleBuffer : CMSampleBuffer){
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let ciimage = CIImage(cvPixelBuffer: imageBuffer)
        let image = self.convert(cmage: ciimage)
        let success = self.saveImage(image: image)
        dismissDelegate.sendData(filePath: success.1)
        self.dismiss(animated: true, completion: nil)
    }
    func convert(cmage: CIImage) -> UIImage {
         let context = CIContext(options: nil)
         let cgImage = context.createCGImage(cmage, from: cmage.extent)!
         let image = UIImage(cgImage: cgImage)
         return image
    }
    
    func saveImage(image: UIImage) -> (Bool, String) {
        self.clearTempFolder()
        var rotatedimage = image.rotate(radians: .pi/2)
//        let data = UIImageJPEGRepresentation(rotatedimage, 1)
        guard let data = rotatedimage.jpegData(compressionQuality: 1) ?? rotatedimage.pngData() else {
            return (false, "")
        }

        guard let directory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return (false, "")
        }

        do {
            let fullPath = "\(directory)/fileName.jpeg"
            try data.write(to: URL.init(fileURLWithPath: fullPath))
            self.state = 0
            print("????????????????????????")
            print(fullPath)
            return (true, fullPath)
            
//            try data.write(to: directory.appendingPathComponent("fileName.png")!)
//            self.state = 0
//            return (true, "\(directory.appendingPathComponent("fileName.png")!)")
        } catch {
            print(error.localizedDescription)
            return (false, "")
        }
    }
    
    func clearTempFolder() {
        let fileManager = FileManager.default
        let tempFolderPath = NSTemporaryDirectory()
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: tempFolderPath)
            for filePath in filePaths {
                try fileManager.removeItem(atPath: tempFolderPath + filePath)
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }
    

    private func addCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInDualCamera, .builtInTrueDepthCamera,.builtInWideAngleCamera],
            mediaType: .video,
            position: .front).devices.first else {
                fatalError("No back camera device found, please make sure to run SimpleLaneDetection in an iOS device and not a simulator")
        }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    private func showCameraFeed() {
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.frame
  //      self.previewLayer.addSublayer(self.bgImageView.layer)
        
//        self.previewLayer.addSublayer(self.labelStatus.layer)
//        self.previewLayer.addSublayer(self.lblEyeBlink.layer)
//        self.previewLayer.addSublayer(self.backButton.layer)
        
    
        
        let ovalFrame : CGRect = CGRect(x: (self.view.frame.width/2) - ((self.view.frame.width/1.3)/2), y: (self.view.frame.height/2) - (self.view.frame.width/2), width: (self.view.frame.width/1.3), height: (self.view.frame.width))
        let customeView = createOverlay(frame: self.view.frame, xOffset: (self.view.frame.width/2), yOffset: (self.view.frame.height/2.15), radius: (self.view.frame.width/1.3)/2, ovalFrame: ovalFrame)
        self.view.addSubview(customeView)
        
        
        customeView.layer.addSublayer(self.labelStatus.layer)
        customeView.layer.addSublayer(self.lblEyeBlink.layer)
        customeView.layer.addSublayer(self.backButton.layer)

        self.view.addSubview(self.backButton)

    }
    
    private func getCameraFrames(){
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        self.captureSession.addOutput(self.videoDataOutput)
      
    }
    
    private func detectFace(in image: CVPixelBuffer,sampleBuffer : CMSampleBuffer) {
        //this function pass the image buffer to the vision api to detect
        //bounding box and also detect facial landmarks
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation] {
                    DispatchQueue.main.async {
                       self.handleFaceDetectionResults(results, sampleBuffer: sampleBuffer)
                        return;
                    }
                  
                  
                } else {
                   
                }
            }
        })
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageRequestHandler.perform([faceDetectionRequest])
    }
    
    
    
    
    
    
    
    
    
    
    
    private func handleFaceDetectionResults(_ observedFaces: [VNFaceObservation],sampleBuffer : CMSampleBuffer) {
        
        let _: [CAShapeLayer] = observedFaces.flatMap({ (observedFace: VNFaceObservation) -> [CAShapeLayer] in
             
            let faceBoundingBoxOnScreen = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
            let faceBoundingBoxPath = CGPath(roundedRect: faceBoundingBoxOnScreen, cornerWidth: faceBoundingBoxOnScreen.width/2, cornerHeight: faceBoundingBoxOnScreen.height/2, transform: nil)
            let faceBoundingBoxShape = CAShapeLayer()
            faceBoundingBoxShape.path = faceBoundingBoxPath
            faceBoundingBoxShape.fillColor = UIColor.clear.cgColor
            faceBoundingBoxShape.strokeColor = UIColor.green.cgColor
            var newDrawings = [CAShapeLayer]()
            newDrawings.append(faceBoundingBoxShape)
            
            
            let faceCalculatedX = faceBoundingBoxOnScreen.origin.x + faceBoundingBoxOnScreen.width
            let faceCalculatedY = faceBoundingBoxOnScreen.origin.y + faceBoundingBoxOnScreen.height
            
            let overlayCalculatedX = overlayCircle.frame.origin.x + overlayCircle.frame.width
            let overlayCalculatedY = overlayCircle.frame.origin.y + overlayCircle.frame.height
            
            self.lblEyeBlink.isHidden = false
             
            if (overlayCalculatedX - faceCalculatedX) < 130 && (overlayCalculatedX - faceCalculatedX) > 0 && (overlayCalculatedY - faceCalculatedY) > 0 && (overlayCalculatedY - faceCalculatedY) < 130 {
                DispatchQueue.main.async {
                    self.lblEyeBlink.isHidden = false
                    self.shape.strokeColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1).cgColor
                    self.overlayCircle.layer.borderColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
                    weak var weakSelf = self
                    let visionImage = VisionImage.init(buffer: sampleBuffer)
                    self.faceDetector.process(visionImage) { faces, error in
                        guard let strongSelf = weakSelf else {
                            print("Self is nil!")
                            return
                        }
                        guard error == nil, let faces = faces, !faces.isEmpty else {
                            // ...
                            return
                        }
                      
                        
                        for face in faces {
                            let frame = face.frame
                            var left : CGFloat = 0.0
                            var right : CGFloat = 0.0
                            if face.hasRightEyeOpenProbability {
                             
                               left = face.rightEyeOpenProbability
                            }
                            if face.hasLeftEyeOpenProbability {
                                right = face.leftEyeOpenProbability
                            }
                           print(self.state)
                            print(right);
                            print(left);
                            switch self.state {
                            case 0:
                                self.lblEyeBlink.text = "blink and open your eyes";
                                if left > self.Open_threshold && right > self.Open_threshold{
                                    self.state = 1
                                }

                                break
                            case 1:
                                self.lblEyeBlink.text = "blink and close your eyes";
                                if left < self.Close_threshold && right < self.Close_threshold{
                                    self.state = 2
                                }
                                break
                            case 2:
                                self.lblEyeBlink.text = "blink and open your eyes";
                                if left > self.Open_threshold && right > self.Open_threshold{

                                    self.mainBuffer = sampleBuffer
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        self.captureImageAfterBlink(sampleBuffer: self.mainBuffer!)
                                    }
                                }
                                break
                            default:
                                print("Default case")
                            }
                            
                        }
                    }

                     
                }
                
            }else{
                shape.strokeColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1).cgColor
                overlayCircle.layer.borderColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
               if(self.state<1)
                {
                   self.lblEyeBlink.isHidden = true
               }
             
            }
            
            return newDrawings
        })
    }
    
    func createOverlay(frame: CGRect,
                       xOffset: CGFloat,
                       yOffset: CGFloat,
                       radius: CGFloat, ovalFrame: CGRect) -> UIView {
        // Step 1
        let overlayView = UIView(frame: frame)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        // Step 2
        let path = CGMutablePath()
        path.addEllipse(in: ovalFrame)
//        path.addArc(center: CGPoint(x: xOffset, y: yOffset),
//                    radius: radius,
//                    startAngle: 0.0,
//                    endAngle: 2.0 * .pi,
//                    clockwise: false)
        path.addRect(CGRect(origin: .zero, size: overlayView.frame.size))
        // Step 3
        let maskLayer = CAShapeLayer()
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.path = path
        // For Swift 4.0
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        // For Swift 4.2
        // Step 4
        overlayView.layer.mask = maskLayer
        overlayView.clipsToBounds = true
        return overlayView
    }
    
}
extension UIImage {
    func rotate(radians: CGFloat) -> UIImage {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .integral.size
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: rotatedSize.width / 2.0,
                                 y: rotatedSize.height / 2.0)
            context.translateBy(x: origin.x, y: origin.y)
            context.rotate(by: radians)
            draw(in: CGRect(x: -origin.y, y: -origin.x,
                            width: size.width, height: size.height))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return rotatedImage ?? self
        }

        return self
    }
}
 
