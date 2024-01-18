/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contains view controller code for previewing live-captured content.
*/

import UIKit
import AVFoundation
import CoreVideo
import MobileCoreServices
import Accelerate
import Photos
import Vision
import SwiftGifOrigin

@available(iOS 13.0, *)
class CameraViewController: UIViewController, AVCaptureDataOutputSynchronizerDelegate {
    
    
    
    //    private var isAll = true
    private var frametot = 0
    private var frametotA = 0
    private var saving = false
    private var savingPercentage = 0
    static var islogin = false
    private var jumpFrame = 0
    static var username = "user1"
    static var password = "123456"
    static var token = "test"
    static var patientName = "例如：LiMing"

    // MARK: - Properties
    @IBOutlet weak private var startButton: UIButton!
    private var startPressed = false
    
    @IBOutlet weak private var recordButton: UIButton!

    @IBOutlet weak private var uploadButton: UIButton!
    
    @IBOutlet weak private var resumeButton: UIButton!
    
    @IBOutlet weak private var loginButton: UIButton!
    
    @IBOutlet weak private var cameraUnavailableLabel: UILabel!
    
    @IBOutlet weak private var jetView: PreviewMetalView!
    
    @IBOutlet weak private var depthSmoothingSwitch: UISwitch!
    
    @IBOutlet weak private var mixFactorSlider: UISlider!
    
    @IBOutlet weak private var touchDepth: UILabel!
    
    @IBOutlet weak var autoPanningSwitch: UISwitch!
    
    fileprivate let avSpeech = AVSpeechSynthesizer()

     //  最常视频录制时间，单位 秒
     let MaxVideoRecordTime = 6000
     var timer: Timer?
     var secondCount = 0
     var speechText = "12345";
     //  表示当时是否在录像中
     var isRecording = false
     var state = 0
     var speaking = 0
     var lastTime = 0
     static var camerafx = ""
     static var camerafy = ""
     static var cameracx = ""
     static var cameracy = ""
     static var resColorW = ""
     static var resColorH = ""
     static var cameraDepthfx = ""
     static var cameraDepthfy = ""
     static var cameraDepthcx = ""
     static var cameraDepthcy = ""
     static var resDepthW = ""
     static var resDepthH = ""
     static var cameraframe = ""
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    var tmpUserMgr = UserMgr()

    var sequenceHandler = VNSequenceRequestHandler()

    var imageView:UIView!
    var gifView:UIImageView!
    
    var rotateLeft = [UILabel]()
    var rotateRight = [UILabel]()
    var LeftLevel = 0
    var RightLevel = 0
    var stepState = -1
    var setflag = false
    
    private var setupResult: SessionSetupResult = .success
    
    private let session = AVCaptureSession()
    
    private var isSessionRunning = false
    
    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "session queue", attributes: [], autoreleaseFrequency: .workItem)
    private var videoDeviceInput: AVCaptureDeviceInput!
    
    private let videoSaveQueue = DispatchQueue(label: "video data save", qos: .userInitiated)
    
    private let videoUploadQueue = DispatchQueue(label: "video data upload", qos: .userInitiated)
    
    private let DataSaveQueue = DispatchQueue(label: "img data save", qos: .userInitiated, autoreleaseFrequency: .workItem)
    
    private let dataOutputQueue = DispatchQueue(label: "video data queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let depthDataOutput = AVCaptureDepthDataOutput()
    private var outputSynchronizer: AVCaptureDataOutputSynchronizer?
    
    private let videoDepthMixer = VideoMixer()
    
    private let videoDepthConverter = DepthToJETConverter()
    
    private var renderingEnabled = true
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera],
                                                                               mediaType: .video,
                                                                               position: .front)
    
    private var statusBarOrientation: UIInterfaceOrientation = .portrait
    
    private var touchDetected = false
    
    private var touchCoordinates = CGPoint(x: 0, y: 0)
    
    @IBOutlet weak private var cloudView: PointCloudMetalView!
    
    @IBOutlet weak private var cloudToJETSegCtrl: UISegmentedControl!
    
    @IBOutlet weak private var smoothDepthLabel: UILabel!
    
    private var lastScale = Float(1.0)
    
    private var lastScaleDiff = Float(0.0)
    
    private var lastZoom = Float(0.0)
    
    private var lastXY = CGPoint(x: 0, y: 0)
    
    private var JETEnabled = false
    
    private var viewFrameSize = CGSize()
    
    private var autoPanningIndex = Int(0) // start with auto-panning on
    
    // MARK: - View Controller Life Cycle
    let photoView : PhotoView! = PhotoView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewFrameSize = self.view.frame.size
        for i in 1...4 {
            rotateLeft.append(UILabel())
            rotateRight.append(UILabel())
        }
        if UserMgr.saveFlag {
            CameraViewController.islogin = true
            loginButton.setTitle("Logout", for: .normal)
            CameraViewController.username = tmpUserMgr.currentUser.username
            CameraViewController.password = tmpUserMgr.currentUser.password
            CameraViewController.token = tmpUserMgr.currentUser.token
            print(CameraViewController.token)
        }else{
            CameraViewController.islogin = false
            loginButton.setTitle("Login", for: .normal)

        }
        //下面这段代码是在一个 iOS 应用中设置了一些手势识别器（Gesture Recognizers）。手势识别器用于捕捉用户在屏幕上的手势操作，比如点击、长按、缩放、双击、旋转和拖动等，并在这些手势发生时执行相应的方法（通常是在相应的 selector 方法中定义的操作）。
        let tapGestureJET = UITapGestureRecognizer(target: self, action: #selector(focusAndExposeTap))
        jetView.addGestureRecognizer(tapGestureJET)
        
        let pressGestureJET = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressJET))
        pressGestureJET.minimumPressDuration = 0.05
        pressGestureJET.cancelsTouchesInView = false
        jetView.addGestureRecognizer(pressGestureJET)
        
        //pinchGesture 是一个 UIPinchGestureRecognizer，添加到 cloudView 中，用于识别捏合手势（缩放）。当用户在 cloudView 上进行捏合手势操作时，会触发 handlePinch 方法。
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        cloudView.addGestureRecognizer(pinchGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.numberOfTouchesRequired = 1
        cloudView.addGestureRecognizer(doubleTapGesture)
        
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate))
        cloudView.addGestureRecognizer(rotateGesture)
        
        let panOneFingerGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanOneFinger))
        panOneFingerGesture.maximumNumberOfTouches = 1
        panOneFingerGesture.minimumNumberOfTouches = 1
        cloudView.addGestureRecognizer(panOneFingerGesture)
        
        recordButton.layer.cornerRadius = 20
        recordButton.isEnabled = false
        startButton.layer.cornerRadius = 20
    
        uploadButton.layer.cornerRadius = 20
        uploadButton.backgroundColor = UIColor.green;
        uploadButton.isEnabled = true;
        
        cloudToJETSegCtrl.selectedSegmentIndex = 0
        
        JETEnabled = (cloudToJETSegCtrl.selectedSegmentIndex == 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(loginSucceed), name: NSNotification.Name(rawValue: "refresh"), object: nil)
        
        sessionQueue.sync {
            if JETEnabled {
                self.depthDataOutput.isFilteringEnabled = self.depthSmoothingSwitch.isOn
            } else {
                self.depthDataOutput.isFilteringEnabled = false
            }

            self.cloudView.isHidden = JETEnabled
            self.jetView.isHidden = !JETEnabled
        }
        
        // Check video authorization status, video access is required
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera
            break
            
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant video access
             We suspend the session queue to delay session setup until the access request has completed
             */
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            // The user has previously denied access
            setupResult = .notAuthorized
        }
        
        /*
         Setup the capture session.
         In general it is not safe to mutate an AVCaptureSession or any of its
         inputs, outputs, or connections from multiple threads at the same time.
         
         Why not do all of this on the main queue?
         Because AVCaptureSession.startRunning() is a blocking call which can
         take a long time. We dispatch session setup to the sessionQueue so
         that the main queue isn't blocked, which keeps the UI responsive.
         */
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let interfaceOrientation = UIApplication.shared.statusBarOrientation
        statusBarOrientation = interfaceOrientation
        
        let initialThermalState = ProcessInfo.processInfo.thermalState
        if initialThermalState == .serious || initialThermalState == .critical {
        //            showThermalState(state: initialThermalState)
            print("test")
        }
        
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session running if setup succeeded
                self.addObservers()
                self.videoDataOutput.connection(with: .video)!.videoOrientation = .portrait
                let videoOrientation = self.videoDataOutput.connection(with: .video)!.videoOrientation
                let videoDevicePosition = self.videoDeviceInput.device.position
                let rotation = PreviewMetalView.Rotation(with: interfaceOrientation,
                                                         videoOrientation: videoOrientation,
                                                         cameraPosition: videoDevicePosition)
                self.jetView.mirroring = (videoDevicePosition == .front)
                if let rotation = rotation {
                    self.jetView.rotation = rotation
                }
                self.dataOutputQueue.async {
                    self.renderingEnabled = true
                }
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                
            case .notAuthorized:
                DispatchQueue.main.async {
                    let message = NSLocalizedString("TrueDepthStreamer doesn't have permission to use the camera, please change privacy settings",
                                                    comment: "Alert message when the user has denied access to the camera")
                    let alertController = UIAlertController(title: "TrueDepthStreamer", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                            style: .`default`,
                                                            handler: { _ in
                                                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                          options: [:],
                                                                                          completionHandler: nil)
                    }))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                
            case .configurationFailed:
                DispatchQueue.main.async {
                    self.cameraUnavailableLabel.isHidden = false
                    self.cameraUnavailableLabel.alpha = 0.0
                    UIView.animate(withDuration: 0.25) {
                        self.cameraUnavailableLabel.alpha = 1.0
                    }
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        dataOutputQueue.async {
            self.renderingEnabled = false
        }
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    @objc
    func didEnterBackground(notification: NSNotification) {
        // Free up resources
        dataOutputQueue.async {
            self.renderingEnabled = false
            self.videoDepthMixer.reset()
            self.videoDepthConverter.reset()
            self.jetView.pixelBuffer = nil
            self.jetView.flushTextureCache()
        }
    }
    
    @objc
    func willEnterForground(notification: NSNotification) {
        dataOutputQueue.async {
            self.renderingEnabled = true
        }
    }
    
    // You can use this opportunity to take corrective action to help cool the system down.
    @objc
    func thermalStateChanged(notification: NSNotification) {
        if let processInfo = notification.object as? ProcessInfo {
        //            showThermalState(state: processInfo.thermalState)
        }
    }
    
    func showThermalState(state: ProcessInfo.ThermalState) {
        DispatchQueue.main.async {
            var thermalStateString = "UNKNOWN"
            if state == .nominal {
                thermalStateString = "NOMINAL"
            } else if state == .fair {
                thermalStateString = "FAIR"
            } else if state == .serious {
                thermalStateString = "SERIOUS"
            } else if state == .critical {
                thermalStateString = "CRITICAL"
            }
            
            let message = NSLocalizedString("Thermal state: \(thermalStateString)", comment: "Alert message when thermal state has changed")
            let alertController = UIAlertController(title: "TrueDepthStreamer", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(
            alongsideTransition: { _ in
                let interfaceOrientation = UIApplication.shared.statusBarOrientation
                self.statusBarOrientation = interfaceOrientation
                self.sessionQueue.async {
                    /*
                     The photo orientation is based on the interface orientation. You could also set the orientation of the photo connection based
                     on the device orientation by observing UIDeviceOrientationDidChangeNotification.
                     */
                    
                    let videoOrientation = self.videoDataOutput.connection(with: .video)!.videoOrientation
                    if let rotation = PreviewMetalView.Rotation(with: interfaceOrientation, videoOrientation: videoOrientation,
                                                                cameraPosition: self.videoDeviceInput.device.position) {
                        self.jetView.rotation = rotation
                    }
                }
        }, completion: nil
        )
    }
    
    // MARK: - KVO and Notifications
    
    private var sessionRunningContext = 0
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(thermalStateChanged),
                                               name: ProcessInfo.thermalStateDidChangeNotification,	object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError),
                                               name: NSNotification.Name.AVCaptureSessionRuntimeError, object: session)
        
        session.addObserver(self, forKeyPath: "running", options: NSKeyValueObservingOptions.new, context: &sessionRunningContext)
        
        /*
         A session can only run when the app is full screen. It will be interrupted
         in a multi-app layout, introduced in iOS 9, see also the documentation of
         AVCaptureSessionInterruptionReason. Add observers to handle these session
         interruptions and show a preview is paused message. See the documentation
         of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
         */
        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted),
                                               name: NSNotification.Name.AVCaptureSessionWasInterrupted,
                                               object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded),
                                               name: NSNotification.Name.AVCaptureSessionInterruptionEnded,
                                               object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange),
                                               name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange,
                                               object: videoDeviceInput.device)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        session.removeObserver(self, forKeyPath: "running", context: &sessionRunningContext)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context != &sessionRunningContext {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: - Session Management
    
    // Call this on the session queue
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        let defaultVideoDevice: AVCaptureDevice? = videoDeviceDiscoverySession.devices.first
        
        guard let videoDevice = defaultVideoDevice else {
            print("Could not find any video device")
            setupResult = .configurationFailed
            return
        }
        
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
        } catch {
            print("Could not create video device input: \(error)")
            setupResult = .configurationFailed
            return
        }
        
        session.beginConfiguration()
        
        //        lxk: change video type,resolution
        session.sessionPreset = AVCaptureSession.Preset.hd1920x1080
//        session.sessionPreset = AVCaptureSession.Preset.cif352x288
//        session.sessionPreset = AVCaptureSession.Preset.vga640x480
        
        
        // Add a video input
        guard session.canAddInput(videoDeviceInput) else {
            print("Could not add video device input to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        session.addInput(videoDeviceInput)
        
        // Add a video data output
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        } else {
            print("Could not add video data output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // Add a depth data output
        if session.canAddOutput(depthDataOutput) {
            session.addOutput(depthDataOutput)
            depthDataOutput.isFilteringEnabled = false
            if let connection = depthDataOutput.connection(with: .depthData) {
                connection.isEnabled = true
                connection.videoOrientation = .portrait
            } else {
                print("No AVCaptureConnection")
            }
        } else {
            print("Could not add depth data output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // Search for highest resolution with half-point depth values
        let depthFormats = videoDevice.activeFormat.supportedDepthDataFormats
        let filtered = depthFormats.filter({
            CMFormatDescriptionGetMediaSubType($0.formatDescription) == kCVPixelFormatType_DepthFloat16
        })
        let selectedFormat = filtered.max(by: {
            first, second in CMVideoFormatDescriptionGetDimensions(first.formatDescription).width < CMVideoFormatDescriptionGetDimensions(second.formatDescription).width
        })
        print(selectedFormat)
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.activeDepthDataFormat = selectedFormat
            videoDevice.unlockForConfiguration()
        } catch {
            print("Could not lock device for configuration: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // Use an AVCaptureDataOutputSynchronizer to synchronize the video data and depth data outputs.
        // The first output in the dataOutputs array, in this case the AVCaptureVideoDataOutput, is the "master" output.
        outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [videoDataOutput, depthDataOutput])
        outputSynchronizer!.setDelegate(self, queue: dataOutputQueue)
        session.commitConfiguration()
    }
    
    private func focus(with focusMode: AVCaptureDevice.FocusMode,
                       exposureMode: AVCaptureDevice.ExposureMode,
                       at devicePoint: CGPoint,
                       monitorSubjectAreaChange: Bool) {
        sessionQueue.async {
            let videoDevice = self.videoDeviceInput.device
            print("st")
            do {
                try videoDevice.lockForConfiguration()
                if videoDevice.isFocusPointOfInterestSupported && videoDevice.isFocusModeSupported(focusMode) {
                    videoDevice.focusPointOfInterest = devicePoint
                    videoDevice.focusMode = focusMode
                }
                
                if videoDevice.isExposurePointOfInterestSupported && videoDevice.isExposureModeSupported(exposureMode) {
                    videoDevice.exposurePointOfInterest = devicePoint
                    videoDevice.exposureMode = exposureMode
                }
                
                videoDevice.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                videoDevice.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    @IBAction private func changeMixFactor(_ sender: UISlider) {
        let mixFactor = sender.value
        
        dataOutputQueue.async {
            self.videoDepthMixer.mixFactor = mixFactor
        }
    }
    
    @IBAction private func changeDepthSmoothing(_ sender: UISwitch) {
        clearCache()
        self.view.makeToast("Succeed",duration: 1.0, position: .center)
//        let smoothingEnabled = sender.isOn
//        sessionQueue.async {
//            self.depthDataOutput.isFilteringEnabled = smoothingEnabled
//        }
    }
    
    @IBAction func changeCloudToJET(_ sender: UISegmentedControl) {
        JETEnabled = (sender.selectedSegmentIndex == 0)
        
        sessionQueue.sync {
            if JETEnabled {
                self.depthDataOutput.isFilteringEnabled = self.depthSmoothingSwitch.isOn
            } else {
                self.depthDataOutput.isFilteringEnabled = false
            }
            
            self.cloudView.isHidden = JETEnabled
            self.jetView.isHidden = !JETEnabled
        }
    }
    
    @IBAction private func focusAndExposeTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: jetView)
        guard let texturePoint = jetView.texturePointForView(point: location) else {
            return
        }
        
        let textureRect = CGRect(origin: texturePoint, size: .zero)
        let deviceRect = videoDataOutput.metadataOutputRectConverted(fromOutputRect: textureRect)
        focus(with: .autoFocus, exposureMode: .autoExpose, at: deviceRect.origin, monitorSubjectAreaChange: true)
    }
    
    @objc
    func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
    }
    
    @objc
    func sessionWasInterrupted(notification: NSNotification) {
        // In iOS 9 and later, the userInfo dictionary contains information on why the session was interrupted.
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
            let reasonIntegerValue = userInfoValue.integerValue,
            let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
            
            if reason == .videoDeviceInUseByAnotherClient {
                // Simply fade-in a button to enable the user to try to resume the session running.
                resumeButton.isHidden = false
                resumeButton.alpha = 0.0
                UIView.animate(withDuration: 0.25) {
                    self.resumeButton.alpha = 1.0
                }
            } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                // Simply fade-in a label to inform the user that the camera is unavailable.
                cameraUnavailableLabel.isHidden = false
                cameraUnavailableLabel.alpha = 0.0
                UIView.animate(withDuration: 0.25) {
                    self.cameraUnavailableLabel.alpha = 1.0
                }
            }
        }
    }
    
    @objc
    func sessionInterruptionEnded(notification: NSNotification) {
        if !resumeButton.isHidden {
            UIView.animate(withDuration: 0.25,
                           animations: {
                            self.resumeButton.alpha = 0
            }, completion: { _ in
                self.resumeButton.isHidden = true
            }
            )
        }
        if !cameraUnavailableLabel.isHidden {
            UIView.animate(withDuration: 0.25,
                           animations: {
                            self.cameraUnavailableLabel.alpha = 0
            }, completion: { _ in
                self.cameraUnavailableLabel.isHidden = true
            }
            )
        }
    }
    
    @objc
    func sessionRuntimeError(notification: NSNotification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
            return
        }
        
        let error = AVError(_nsError: errorValue)
        print("Capture session runtime error: \(error)")
        
        /*
         Automatically try to restart the session running if media services were
         reset and the last start running succeeded. Otherwise, enable the user
         to try to resume the session running.
         */
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                } else {
                    DispatchQueue.main.async {
                        self.resumeButton.isHidden = false
                    }
                }
            }
        } else {
            resumeButton.isHidden = false
        }
    }
    
    @IBAction 
    private func resumeInterruptedSession(_ sender: UIButton) {
        sessionQueue.async {
            /*
             The session might fail to start running. A failure to start the session running will be communicated via
             a session runtime error notification. To avoid repeatedly failing to start the session
             running, we only try to restart the session running in the session runtime error handler
             if we aren't trying to resume the session running.
             */
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
            if !self.session.isRunning {
                DispatchQueue.main.async {
                    let message = NSLocalizedString("Unable to resume", comment: "Alert message when unable to resume the session running")
                    let alertController = UIAlertController(title: "TrueDepthStreamer", message: message, preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil)
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    self.resumeButton.isHidden = true
                }
            }
        }
    }
    
    // MARK: - Point cloud view gestures
    
    @IBAction 
    private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.numberOfTouches != 2 {
            return
        }
        if gesture.state == .began {
            lastScale = 1
        } else if gesture.state == .changed {
            let scale = Float(gesture.scale)
            let diff: Float = scale - lastScale
            let factor: Float = 1e3
            if scale < lastScale {
                lastZoom = diff * factor
            } else {
                lastZoom = diff * factor
            }
            DispatchQueue.main.async {
                self.autoPanningSwitch.isOn = false
                self.autoPanningIndex = -1
            }
            cloudView.moveTowardCenter(lastZoom)
            lastScale = scale
        } else if gesture.state == .ended {
        } else {
        }
    }
    
    @IBAction 
    private func handlePanOneFinger(gesture: UIPanGestureRecognizer) {
        if gesture.numberOfTouches != 1 {
            return
        }
        
        if gesture.state == .began {
            let pnt: CGPoint = gesture.translation(in: cloudView)
            lastXY = pnt
        } else if (.failed != gesture.state) && (.cancelled != gesture.state) {
            let pnt: CGPoint = gesture.translation(in: cloudView)
            DispatchQueue.main.async {
                self.autoPanningSwitch.isOn = false
                self.autoPanningIndex = -1
            }
            cloudView.yawAroundCenter(Float((pnt.x - lastXY.x) * 0.1))
            cloudView.pitchAroundCenter(Float((pnt.y - lastXY.y) * 0.1))
            lastXY = pnt
        }
    }
    
    @IBAction 
    private func handleDoubleTap(gesture: UITapGestureRecognizer) {
        DispatchQueue.main.async {
            self.autoPanningSwitch.isOn = false
            self.autoPanningIndex = -1
        }
        cloudView.resetView()
    }
    // 显示缓存大小
    func cacheSize() -> CGFloat {
      let cachePath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
      return folderSize(filePath: cachePath)
    }

    //计算单个文件的大小
    func fileSize(filePath: String) -> UInt64 {
      let manager = FileManager.default
      if manager.fileExists(atPath: filePath) {
        do {
            let attr = try manager.attributesOfItem(atPath: filePath)
            let size = attr[FileAttributeKey.size] as! UInt64
            return size
        } catch  {
            print("error :\(error)")
            return 0
        }
      }
      return 0
    }

    //遍历文件夹，返回多少M
    func folderSize(filePath: String) -> CGFloat {
      let folderPath = filePath as NSString
      let manager = FileManager.default
      if manager.fileExists(atPath: filePath) {
        let childFilesEnumerator = manager.enumerator(atPath: filePath)
        var fileName = ""
        var folderSize: UInt64 = 0
        while childFilesEnumerator?.nextObject() != nil {
            fileName = childFilesEnumerator?.nextObject() as! String
            let fileAbsolutePath = folderPath.strings(byAppendingPaths: [fileName])
            folderSize += fileSize(filePath: fileAbsolutePath[0])
        }
        return CGFloat(folderSize) / (1024.0 * 1024.0)
      }
      return 0
    }

    // 清除缓存
    func clearCache() {
        let cachPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
      let files = FileManager.default.subpaths(atPath: cachPath as String)
      for p in files! {
        let path = cachPath.appendingPathComponent(p)
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                print("error:\(error)")
            }
        }
      }
    }

    func clearCacheNovideo() {
        let cachPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
      let files = FileManager.default.subpaths(atPath: cachPath as String)
      for p in files! {
        let path = cachPath.appendingPathComponent(p)
        let tmp = String(path)
        if tmp.contains("mkv") == false &&  tmp.contains("mp4") == false && FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                print("error:\(error)")
            }
        }
      }
    }


    //删除沙盒里的文件
    func deleteFile(filePath: String) {
      let manager = FileManager.default
      let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as NSString
      let uniquePath = path.appendingPathComponent(filePath)
      if manager.fileExists(atPath: uniquePath) {
        do {
            try FileManager.default.removeItem(atPath: uniquePath)
        } catch {
            print("error:\(error)")
        }
      }
    }

    //登录成功
    @objc 
    private func loginSucceed(){
        print("logout")
        CameraViewController.islogin = true
        loginButton.setTitle("Logout", for: .normal)
        UserMgr.saveFlag.toggle()
        tmpUserMgr.currentUser.username = CameraViewController.username
        tmpUserMgr.currentUser.password = CameraViewController.password
        tmpUserMgr.currentUser.token =
        CameraViewController.token
        print(tmpUserMgr.currentUser.token)
        tmpUserMgr.login()
    }

    //点击登录
    @IBAction 
    private func login(_ sender:UIButton) {
        if(CameraViewController.islogin == false){
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "LoginViewController")
            self.present(vc,animated: true,completion: nil)
        }else{
            CameraViewController.islogin = false
            loginButton.setTitle("Login", for: .normal)
            UserMgr.saveFlag.toggle()
            tmpUserMgr.logout()
            self.view.makeToast("Logout Succeed",duration: 1.0, position: .center)
        }
    }
    
    //声音合成
    func startTranslattion(postDelay:Double,preDelay:Double){
             //1. 创建需要合成的声音类型
             let voice = AVSpeechSynthesisVoice(language: "zh-CN")

             //2. 创建合成的语音类
             let utterance = AVSpeechUtterance(string: speechText)
             utterance.rate = 0.6
             utterance.voice = voice
             utterance.volume = 1
             utterance.postUtteranceDelay = postDelay
             utterance.preUtteranceDelay = preDelay
             utterance.pitchMultiplier = 1
             //开始播放
             avSpeech.speak(utterance)
             speaking = 1
    }
    
    //计算时间
    @objc 
    private func videoRecordingTotolTime() {
       secondCount += 1
       print(avSpeech.isSpeaking)
        //  判断是否录制超时
        if secondCount >= MaxVideoRecordTime {
            timer?.invalidate()
            stop();
        }

       let hours = (secondCount / 10) / 3600
       let mintues = ((secondCount / 10) % 3600) / 60
       let seconds = (secondCount / 10) % 60
    }
    public func changeFileName(_ newName:String,_ oldFilePath:String,_ videoSave:String,_ name:Int) ->Bool{
        var sname = ".mp4"
        if(name == 1){
            sname = ".mkv"
        }
        let fileMgr = FileManager.default
        let newPath = videoSave + "/" + newName + sname
        let url = URL(fileURLWithPath: oldFilePath)
        var state = false
        do {
            try fileMgr.moveItem(at: url, to: URL(fileURLWithPath: newPath))
            state = true
        }catch let error as NSError{
            print("error \(error)")
            state = false
        }
        return state
    }
    
    @objc func updateTimer() {
        // 在这里执行你想要重复执行的操作
        print("Timer fired!") // 这里可以是你的操作，比如更新 UI 或者执行其他任务
        self.view.makeToastActivityWithText(.center)
        UIView.sharedlabel.text = "AA：" + String(savingPercentage) + "%"
        savingPercentage = savingPercentage + 1
    }
    //暂停
    private func stop(){
        saving = false
        secondCount = 0
        print("stop!",frametot,frametotA)
        var framecnt = 0
        while(frametotA != frametot){
            usleep(100)
            framecnt = framecnt + 1
            if(framecnt > 10){
                frametot = frametotA
            }
        }
        print("sure stop!",frametot,frametotA)
        CameraViewController.cameraframe = "\(frametot)"
        self.view.makeToastActivityWithText(.center)
        UIView.sharedlabel.text = "预计" + String(frametotA / 5) + "秒"
        recordButton.isEnabled = false
        startButton.isEnabled = false
        videoSaveQueue.async {
            /* 启动定时器，每隔 1 秒触发一次 updateLabel 方法
            var timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTimer), userInfo: nil, repeats: true)*/
            
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            
            self.savingPercentage = 2//800.0 / Double(framecnt)
            MobileFFmpeg.execute("-i \(path)/%d.PNG -r 20 -codec copy \(path)/d.mkv")
            self.savingPercentage = self.savingPercentage + 100 / 7
            
            DispatchQueue.main.async {
                usleep(1500000)
                self.view.makeToastActivityWithText(.center)
                //UIView.sharedlabel.text = "剩余：" + String(self.frametotA / 5 * 86 / 100) + "S"
                UIView.sharedlabel.text = "Save:||........."
            }
            
            let ss0 = "-i \(path)/%d.JPG -r 20 -codec copy \(path)/g.mkv"
            print(ss0)
            MobileFFmpeg.execute("-i \(path)/%d.JPG -r 20 -codec copy \(path)/g.mkv")
            
            DispatchQueue.main.async {
                usleep(1500000)
                self.savingPercentage = self.savingPercentage + 200 / 7
                //UIView.sharedlabel.text = "剩余：" + String(self.frametotA / 5 * 65 / 100) + "S"
                UIView.sharedlabel.text = "Save:|||||......"
            }
            
            MobileFFmpeg.execute("-i \(path)/%d.JPG -r 24 -vcodec libx264 -crf 8 -pix_fmt yuv420p  \(path)/g.mp4")
            //  if(self.isAll == true){
            //      MobileFFmpeg.execute("-i \(path)/%d.png -r 20 -codec copy \(path)/g2.mkv")
            //  }
            let ss1 = "-i \(path)/%d.PNG -r 20 -codec copy \(path)/d.mkv"
            print(ss1)
            
            DispatchQueue.main.async {
                self.savingPercentage = 100
                UIView.sharedlabel.text = "Save:|||||||||||"
            }
            print("save ready");/**/
            usleep(2000000)
            //timer.invalidate() // 停止定时器*/
            
            DispatchQueue.main.async {
                //UIApplication.shared.isIdleTimerDisabled = false//屏幕常亮关闭
                self.recordButton.backgroundColor=UIColor.green
                self.startButton.backgroundColor=UIColor.green
                self.recordButton.setTitle("Record", for: .normal)
                self.uploadButton.backgroundColor=UIColor.green
                self.uploadButton.isEnabled = true
                self.clearCacheNovideo()
                self.view.hideToastActivity()
                //self.view.makeToast("已录制，请上传",duration: 1.0, position: .center)
                self.recordButton.isEnabled = true
                self.startPressed = false;
                self.startButton.isEnabled = true
                self.startButton.backgroundColor=UIColor.green
                self.startButton.setTitle("Start", for: .normal)
                self.uploadButton.isEnabled = true
                self.ShowMyAlertController()
                self.isRecording = false
                self.imageView.removeFromSuperview()
                self.LeftLevel = 0
                self.RightLevel = 0
                self.savingPercentage = 0
            }
        }

    }

    //点击start
    @IBAction
    private func startProcess(_ sender:UIButton) {
        if(startPressed == false){
            startPressed = true;
            self.startButton.backgroundColor = UIColor.gray
            //self.startButton.isEnabled = false
            self.startButton.setTitle("Stop", for: .normal)
        }else{
            startPressed = false;
            self.startButton.backgroundColor = UIColor.green
            //self.startButton.isEnabled = true
            self.startButton.setTitle("Start", for: .normal)
        }
    }
    //点击录制/暂停
    @IBAction 
    private func startVideo(_ sender:UIButton) {
        if(saving == false){
//            clearCache()
//            clearCacheNovideo()
            
            DispatchQueue.main.async {
                UIApplication.shared.isIdleTimerDisabled = true//屏幕常亮
            }
            secondCount = 0
        //  timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(videoRecordingTotolTime), userInfo: nil, repeats: true)
            isRecording = true
            speaking = 0
            lastTime = 0
            frametot = 0
            frametotA = 0
            saving = true
            recordButton.backgroundColor = UIColor.red
            recordButton.setTitle("Recording", for: .normal)
            uploadButton.isEnabled = false
            stepState = -1
            setflag = false
            let jeremyGif = UIImage.gif(name: "headRotate")
            let bl = Float((jeremyGif?.size.height)!) / Float((jeremyGif?.size.width)!)
            gifView = UIImageView(image: jeremyGif)
            let jwidth = jetView.frame.width
            let gifheight = CGFloat(bl) * jwidth
            let startbuttony = self.recordButton.frame.minY
            imageView = UIView()
            imageView.backgroundColor = UIColor.black
//            imageView.frame = CGRect(x: 0.0, y: startbuttony - gifheight - 30, width: jwidth, height: gifheight + 30)
            imageView.frame = CGRect(x: 0.0, y: jetView.frame.minY, width: view.frame.width, height: jetView.frame.height)
            gifView.frame = CGRect(x: 0.0, y: 30, width: jwidth, height: gifheight)
            var asd = jwidth / 16;
            LeftLevel = 0
            RightLevel = 0
            for i in 0...3 {
                rotateLeft[i].frame = CGRect(x: jwidth / 2 - CGFloat(i + 2) * asd * 1.5, y: 0.0, width: asd, height: asd)
                rotateRight[i].frame = CGRect(x: jwidth / 2 +  CGFloat(i + 1) * asd * 1.5, y: 0.0, width: asd, height: asd)
                rotateLeft[i].backgroundColor = UIColor.gray
                rotateRight[i].backgroundColor = UIColor.gray
                rotateLeft[i].layer.cornerRadius = 8.0
                rotateRight[i].layer.cornerRadius = 8.0
                imageView.addSubview(rotateLeft[i])
                imageView.addSubview(rotateRight[i])
            }
            imageView.addSubview(gifView)
            view.addSubview(imageView)
            print(self.recordButton.frame.minY, startbuttony - gifheight - 30,gifheight + 30)
        }else{
            stop();
        }

    }

    //患者名称
    func ShowMyAlertController(){
        let al = BartAlertController.init(title: "提示", message: "请输入患者名称")
    
        let test = UITextField()
        test.placeholder = "例如：LiMing"
        test.textColor = UIColor.black
        al.addTextField(textfield: test)
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        var tmp = ""
        let act = BartAction.init(title: "取消", style: .grayStyle) { (action:BartAction) in
            tmp = "cancel"
        }
        
        let act3 = BartAction.init(title: "确定", style: .blueStyle) { (action:BartAction) in
            CameraViewController.patientName = test.text!
            var filename = test.text!
            if (filename == ""){
                filename = "empty"
            }
            let gmp4 = path + "/g.mp4"
            self.changeFileName(filename,gmp4,path,0)
            let dmkv = path + "/d.mkv"
            self.changeFileName(filename + "d",dmkv,path,1)
            let gmkv = path + "/g.mkv"
            self.changeFileName(filename + "g",gmkv,path,1)
            self.view.makeToast("已录制成功，请上传",duration: 2.2, position: .center)
        }
        al.addAction(action: act)
        al.addAction(action: act3)
        al.show(self)
    }

    private func managerAllVideos() {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let pathString = path[0] as String
        let list = try? FileManager.default.contentsOfDirectory(atPath: pathString)
        if let _ = list {
            print("!")
            let managerVideoVC = IWManagerVideosViewController()
            self.navigationController?.pushViewController(managerVideoVC, animated: true)
        } else {
            self.view.makeToast("暂无视频",duration: 1.0, position: .center)
        }
    }
    //上传视频
    @IBAction private func uploadVideo(_ sender:UIButton) {
        print("click")
        managerAllVideos()
    }
    
    @IBAction private func handleRotate(gesture: UIRotationGestureRecognizer) {
        if gesture.numberOfTouches != 2 {
            return
        }
        
        if gesture.state == .changed {
            let rot = Float(gesture.rotation)
            DispatchQueue.main.async {
                self.autoPanningSwitch.isOn = false
                self.autoPanningIndex = -1
            }
            cloudView.rollAroundCenter(rot * 60)
            gesture.rotation = 0
        }
    }
    
    // MARK: - JET view Depth label gesture
    
    @IBAction private func handleLongPressJET(gesture: UILongPressGestureRecognizer) {
        
        switch gesture.state {
        case .began:
            touchDetected = true
            let pnt: CGPoint = gesture.location(in: self.jetView)
            touchCoordinates = pnt
        case .changed:
            let pnt: CGPoint = gesture.location(in: self.jetView)
            touchCoordinates = pnt
        case .possible, .ended, .cancelled, .failed:
            touchDetected = false
            DispatchQueue.main.async {
                self.touchDepth.text = ""
            }
        @unknown default:
            print("Unknow gesture state.")
            touchDetected = false
        }
    }
    
    @IBAction func didAutoPanningChange(_ sender: Any) {
        if autoPanningSwitch.isOn {
            self.autoPanningIndex = 0
        } else {
            self.autoPanningIndex = -1
        }
    }

    //保存png
    func saveGimage2(img:UIImage,num:Int) -> String{
        let imgData = img.pngData()
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let imgPath = "\(path)/\(num).png"
        NSData(data: imgData!).write(toFile: imgPath, atomically: true)
        return imgPath
    }
    
    //保存JPG
    func saveGimage(img:UIImage,num:Int) -> String{
        let imgData = img.jpegData(compressionQuality: 1.0)
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let imgPath = "\(path)/\(num).JPG"
        NSData(data: imgData!).write(toFile: imgPath, atomically: true)
        return imgPath
    }

    //保存深度图
    func saveDimage(img:UIImage,num:Int) -> String{
        let imgData = img.pngData()
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let imgPath = "\(path)/\(num).PNG"
        NSData(data: imgData!).write(toFile: imgPath, atomically: true)
        return imgPath
    }

    func detectedFace(request: VNRequest, error: Error?) {
      guard
        let results = request.results as? [VNFaceObservation],
        let result = results.first
        else {
          if(!isRecording){
              DispatchQueue.main.async {
                  self.recordButton.backgroundColor = UIColor.gray
                  self.recordButton.isEnabled = false
              }
          }
          return
      }
      let roll = result.roll!.doubleValue
      let pitch = result.pitch!.doubleValue
      let yaw = result.yaw!.doubleValue
//      print(roll,pitch,yaw);
      let isAcceptableRoll = abs(CGFloat(roll)) < 0.5
      let isAcceptablePitch = abs(CGFloat(pitch)) < 0.7
      let isAcceptableYaw = abs(CGFloat(yaw)) < 0.7
      if(isRecording){
          if(avSpeech.isSpeaking == false && stepState == -1){
              speechText = "请直视屏幕"
              if(!setflag){                DispatchQueue.main.async {
                      var tmp = self.gifView.frame
                      self.gifView.loadGif(name: "headFront")
                      self.gifView.frame = tmp
                  }
                  setflag = true
              }
              startTranslattion(postDelay: 0.5,preDelay: 0.0)
          }
            if(avSpeech.isSpeaking == false && stepState == 0){
                speechText = "请向左转头"
                if(!setflag){                DispatchQueue.main.async {
                        var tmp = self.gifView.frame
                        self.gifView.loadGif(name: "turnLeft")
                        self.gifView.frame = tmp
                    }
                    setflag = true
                }
                startTranslattion(postDelay: 0.5,preDelay: 0.0)
            }
            if(avSpeech.isSpeaking == false && stepState == 1){
                speechText = "请向右转头"
                if(!setflag){
                    DispatchQueue.main.async {
                        var tmp = self.gifView.frame
                        self.gifView.loadGif(name: "turnRight")
                        self.gifView.frame = tmp
                    }
                    setflag = true
                }
                startTranslattion(postDelay: 0.5,preDelay: 0.0)
            }
          if(avSpeech.isSpeaking == false && stepState == 2){
              speechText = "请向左转头"
              if(!setflag){
                  DispatchQueue.main.async {
                      var tmp = self.gifView.frame
                      self.gifView.loadGif(name: "turnLeft")
                      self.gifView.frame = tmp
                  }
                  setflag = true
              }
              startTranslattion(postDelay: 0.5,preDelay: 0.0)
          }
          if(avSpeech.isSpeaking == false && stepState == 3){
              speechText = "请向右转头"
              if(!setflag){
                  DispatchQueue.main.async {
                      var tmp = self.gifView.frame
                      self.gifView.loadGif(name: "turnRight")
                      self.gifView.frame = tmp
                  }
                  setflag = true
              }
              startTranslattion(postDelay: 0.5,preDelay: 0.0)
          }
          if(avSpeech.isSpeaking == false && stepState == 4 && saving == true){
              speechText = "请回到中间位置"
              startTranslattion(postDelay: 0.5,preDelay: 0.0)
          }
          if(avSpeech.isSpeaking == true && stepState == 4 && saving == true && RightLevel <= 1 && LeftLevel <= 1){
              stepState = stepState + 1
              DispatchQueue.main.async {
                  var tmp = self.gifView.frame
                  self.gifView.loadGif(name: "headFront")
                  self.gifView.frame = tmp
              }

          }
          if(avSpeech.isSpeaking == false && stepState == 5 && saving == true){
              speechText = "请稍微抬头"
              startTranslattion(postDelay: 0.5,preDelay: 0.0)
              stepState = stepState + 1
          }
          if(avSpeech.isSpeaking == false && stepState == 6 && saving == true){
              speechText = "请回到中间位置"
              startTranslattion(postDelay: 0.5,preDelay: 0.0)
              stepState = stepState + 1
          }
          if(avSpeech.isSpeaking == false && stepState >= 6 && saving == true){
              DispatchQueue.main.async {
                  self.stop()
              }
          }
      }
        
        if(stepState < 0){
            stepState = stepState + 1
            return
        }
        if(CGFloat(yaw) > 0.1 && stepState % 2 == 1){
            DispatchQueue.main.async {
                self.rotateRight[0].backgroundColor = UIColor.green
            }
            RightLevel = 1
        }else if(CGFloat(yaw) < 0.1){
            DispatchQueue.main.async {
                self.rotateRight[0].backgroundColor = UIColor.gray
            }
            RightLevel = 0
        }
        
        if(CGFloat(yaw) > 0.2 && stepState % 2 == 1){
            DispatchQueue.main.async {
                self.rotateRight[1].backgroundColor = UIColor.green
            }
            RightLevel = 2
        }else if(CGFloat(yaw) < 0.2){
            DispatchQueue.main.async {
                self.rotateRight[1].backgroundColor = UIColor.gray
            }
        }
        if(CGFloat(yaw) > 0.4 && stepState % 2 == 1){
            DispatchQueue.main.async {
                self.rotateRight[2].backgroundColor = UIColor.green
            }
            RightLevel = 3
        }else if(CGFloat(yaw) < 0.4){
            DispatchQueue.main.async {
                self.rotateRight[2].backgroundColor = UIColor.gray
            }
        }
        if(CGFloat(yaw) > 0.5 && stepState % 2 == 1){
            DispatchQueue.main.async {
                self.rotateRight[3].backgroundColor = UIColor.green
            }
            if(stepState < 4){
                stepState = stepState + 1
            }
            setflag = false
            RightLevel = 4
        }else if(CGFloat(yaw) < 0.5){
            DispatchQueue.main.async {
                self.rotateRight[3].backgroundColor = UIColor.gray
            }
        }
        
        if(CGFloat(yaw) < -0.1 && stepState % 2 == 0){
            DispatchQueue.main.async {
                self.rotateLeft[0].backgroundColor = UIColor.green
            }
            LeftLevel = 1
        }else if(CGFloat(yaw) > -0.1){
            DispatchQueue.main.async {
                self.rotateLeft[0].backgroundColor = UIColor.gray
            }
            LeftLevel = 0
        }
        if(CGFloat(yaw) < -0.2 && stepState % 2 == 0){
            DispatchQueue.main.async {
                self.rotateLeft[1].backgroundColor = UIColor.green
            }
            LeftLevel = 2
        }else if(CGFloat(yaw) > -0.2){
            DispatchQueue.main.async {
                self.rotateLeft[1].backgroundColor = UIColor.gray
            }
        }
        if(CGFloat(yaw) < -0.4 && stepState % 2 == 0){
            DispatchQueue.main.async {
                self.rotateLeft[2].backgroundColor = UIColor.green
            }
            LeftLevel = 3
        }else if(CGFloat(yaw) > -0.4){
            DispatchQueue.main.async {
                self.rotateLeft[2].backgroundColor = UIColor.gray
            }
        }
        if(CGFloat(yaw) < -0.5 && stepState % 2 == 0){
            DispatchQueue.main.async {
                self.rotateLeft[3].backgroundColor = UIColor.green
            }
            if(stepState < 4){
                stepState = stepState + 1
            }
            LeftLevel = 4
            setflag = false
        }else if(CGFloat(yaw) > -0.5){
            DispatchQueue.main.async {
                self.rotateLeft[3].backgroundColor = UIColor.gray
            }
        }
        
        if(isRecording){
            return
        }
//      print(isAcceptableRoll,isAcceptablePitch,isAcceptableYaw)
      // 3
      let box = result.boundingBox
      let x = box.origin.x
//      let w = box.width * 480
//      let h = box.height * 640
      let y = box.origin.y
//         print(x,y) // > 0.1      < 0.5
//         print(box.width,box.height) // size 0.4
      let isAcceptablePos = (x < 0.5) && (x > 0.0) && (y < 0.5) && (y > 0.0)
      print(x,y)
      let isAcceptableSize = (box.width > 0.4) && (box.height > 0.4)
        if(startPressed == true && isAcceptableRoll && isAcceptablePitch && isAcceptableYaw && isAcceptablePos && isAcceptableSize){
            DispatchQueue.main.async {
                self.recordButton.backgroundColor = UIColor.green
                self.recordButton.isEnabled = true
            }
        }else{
            DispatchQueue.main.async {
                self.recordButton.backgroundColor = UIColor.gray
                self.recordButton.isEnabled = false
            }
        }
        print(box.width)
        if(startPressed == true){
            if(!isAcceptableSize && avSpeech.isSpeaking == false){
                speechText = "请靠近一点"
                startTranslattion(postDelay: 1.0,preDelay: 0.0)
            }else if( (box.width > 0.8) && avSpeech.isSpeaking == false){
                speechText = "请远离一点"
                startTranslattion(postDelay: 1.0,preDelay: 0.0)
            }
            else if(!isAcceptablePos && avSpeech.isSpeaking == false){
                speechText = "请保持人脸在屏幕中心"
                startTranslattion(postDelay: 1.0,preDelay: 0.0)
            }else if((!isAcceptableRoll || !isAcceptableYaw || !isAcceptablePitch) && avSpeech.isSpeaking == false){
                speechText = "请保持人脸呈现端正姿态"
                startTranslattion(postDelay: 1.0,preDelay: 0.0)
            }
        }
//      // 4
//      DispatchQueue.main.async {
//        self.faceView.setNeedsDisplay()
//      }
    }
    
    // MARK: - Video + Depth Frame Processing
    
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        if !renderingEnabled {
            return
        }
        
        // Read all outputs
        guard renderingEnabled,
            let syncedDepthData: AVCaptureSynchronizedDepthData =
            synchronizedDataCollection.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData,
            let syncedVideoData: AVCaptureSynchronizedSampleBufferData =
            synchronizedDataCollection.synchronizedData(for: videoDataOutput) as? AVCaptureSynchronizedSampleBufferData else {
                // only work on synced pairs
                return
        }
        
        if syncedDepthData.depthDataWasDropped || syncedVideoData.sampleBufferWasDropped {
            return
        }
        
        let depthData = syncedDepthData.depthData
        let depthPixelBuffer = depthData.depthDataMap
        let sampleBuffer = syncedVideoData.sampleBuffer
        guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
                return
        }
        if(isRecording){
            jumpFrame = (jumpFrame + 1) % 5
        }else{
            jumpFrame = (jumpFrame + 1) % 10
        }
        if(jumpFrame == 0){
            // 2
            let detectFaceRequest = VNDetectFaceRectanglesRequest(completionHandler: detectedFace)
            detectFaceRequest.revision = VNDetectFaceRectanglesRequestRevision3
            // 3
            do {
              try sequenceHandler.perform(
                [detectFaceRequest],
                on: videoPixelBuffer,
                orientation: .upMirrored)
            } catch {
              print(error.localizedDescription)
            }
        
        }

        //lxk: ----------------------  start read calibration info ------------------------------------///
        let calibration = depthData.cameraCalibrationData;
        let intrinsic = calibration!.intrinsicMatrix;
        
        
//        let videoDevice = AVCaptureDevice.default(for: .video)
//        let activeFormat = videoDevice?.activeFormat
//        let intrinsicColorMatrix = activeFormat.formatDescription.formatDescriptionExtension(for: cameraIntrinsicMatrix) as? NSData
//        let fxColor = intrinsicColorMatrix?.m11
//        let fyColor = intrinsicColorMatrix?.m22
//        let cxColor = intrinsicColorMatrix?.m31
//        let cyColor = intrinsicColorMatrix?.m32
//
        
        let extrinsic = calibration!.extrinsicMatrix;
        
        let refWidth = calibration!.intrinsicMatrixReferenceDimensions.width;
        let refHeight = calibration!.intrinsicMatrixReferenceDimensions.height;
        
        let videoWidth = CVPixelBufferGetWidth(videoPixelBuffer);
        let videoHeight = CVPixelBufferGetHeight(videoPixelBuffer);
        
        let wScale = CGFloat(videoWidth) / refWidth;
        let hScale = CGFloat(videoHeight)  / refHeight;
        
        
        
        let videoWidth2 = CVPixelBufferGetWidth(depthPixelBuffer);
        let videoHeight2 = CVPixelBufferGetHeight(depthPixelBuffer);
        print(videoWidth2,videoHeight2)
        let wScale2 = CGFloat(videoWidth2) / refWidth;
        let hScale2 = CGFloat(videoHeight2)  / refHeight;
        
        let fx_ori = (intrinsic.columns.0)[0];
        let fy_ori = (intrinsic.columns.1)[1];
        let cx_ori = (intrinsic.columns.2)[0];
        let cy_ori = (intrinsic.columns.2)[1];
        
        let r11 = (extrinsic.columns.0)[0];
        let r12 = (extrinsic.columns.0)[1];
        let r13 = (extrinsic.columns.0)[2];
        let r21 = (extrinsic.columns.1)[0];
        let r22 = (extrinsic.columns.1)[1];
        let r23 = (extrinsic.columns.1)[2];
        let r31 = (extrinsic.columns.2)[0];
        let r32 = (extrinsic.columns.2)[1];
        let r33 = (extrinsic.columns.2)[2];
        let t1 = (extrinsic.columns.3)[0];
        let t2 = (extrinsic.columns.3)[1];
        let t3 = (extrinsic.columns.3)[2];
        
        let fx = CGFloat(fx_ori) * wScale;
        let fy =  CGFloat(fy_ori) * hScale ;
        let cx =   CGFloat(cx_ori) * wScale;
        let cy =  CGFloat(cy_ori) * hScale;
        
        let fx2 = CGFloat(fx_ori) * wScale2;
        let fy2 =  CGFloat(fy_ori) * hScale2 ;
        let cx2 =   CGFloat(cx_ori) * wScale2;
        let cy2 =  CGFloat(cy_ori) * hScale2;
        
        print(fx_ori,fy_ori,cx_ori,cy_ori)
        print(r11,r12,r13,t1)
        print(r21,r22,r23,t2)
        print(r31,r32,r33,t3)
        print(fx,fy,cx,cy)
        print(fx2,fy2,cx2 ,cy2)
        print(refWidth,refHeight)
        CameraViewController.cameracx = "\(cx)"
        CameraViewController.cameracy = "\(cy)"
        CameraViewController.camerafx = "\(fx)"
        CameraViewController.camerafy = "\(fy)"
        CameraViewController.resColorH = "\(videoHeight)"
        CameraViewController.resColorW = "\(videoWidth)"
        CameraViewController.cameraDepthcx = "\(cx2)"
        CameraViewController.cameraDepthcy = "\(cy2)"
        CameraViewController.cameraDepthfx = "\(fx2)"
        CameraViewController.cameraDepthfy = "\(fy2)"
        CameraViewController.resDepthW = "\(videoWidth2)"
        CameraViewController.resDepthH = "\(videoHeight2)"
        
        //        2871.807 2871.807 1164.1051 1533.6299
        //        0.0 -1.0 0.0 0.0
        //        1.0 0.0 0.0 0.0
        //        0.0 0.0 1.0 0.0
        //        594.1669416756465 595.1931367389896 240.84933155980602 317.8507529145078
        
        //       lxk: ----------------------  end read calibration info ------------------------------------///
        
        
        if let UIImageVideoPixelBuffer = UIImage(pixelBuffer: videoPixelBuffer){
               if let UIImagedepthPixelBuffer : UIImage = photoView.depthBuffer(toImage: depthPixelBuffer){
                   // depth image save
                //                   UIImageWriteToSavedPhotosAlbum(UIImagedepthPixelBuffer, nil, nil, nil)
                if(saving){
                    let imgcount = frametot
                    frametot = frametot + 1
                    print(imgcount)
        //                    print(imgpath)
                    videoSaveQueue.async {
                        var imgpath1 = self.saveDimage(img: UIImagedepthPixelBuffer, num: imgcount+1)
                        var imgpath2 = self.saveGimage(img: UIImageVideoPixelBuffer, num: imgcount+1)
                        DispatchQueue.main.async {
                            self.frametotA = self.frametotA + 1
                            print(self.frametot,"fuck",self.frametotA)
                        }
                    }
  

        //                    print(imgpath)
//                    if(isAll == true){
//                        imgpath = saveGimage2(img: UIImageVideoPixelBuffer, num: imgcount+1)
//                        gimages2.append(URL(fileURLWithPath: imgpath))
//                    }
//                    usleep(5000)  //5ms
                }
               }
           }
        
        if JETEnabled {
//            if !videoDepthConverter.isPrepared {
//                /*
//                 outputRetainedBufferCountHint is the number of pixel buffers we expect to hold on to from the renderer.
//                 This value informs the renderer how to size its buffer pool and how many pixel buffers to preallocate. Allow 2 frames of latency
//                 to cover the dispatch_async call.
//                 */
//                var depthFormatDescription: CMFormatDescription?
//                CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
//                                                             imageBuffer: depthPixelBuffer,
//                                                             formatDescriptionOut: &depthFormatDescription)
//                videoDepthConverter.prepare(with: depthFormatDescription!, outputRetainedBufferCountHint: 2)
//            }
            
            jetView.pixelBuffer = videoPixelBuffer
            
            updateDepthLabel(depthFrame: depthPixelBuffer, videoFrame: videoPixelBuffer)
        } else {
            // point cloud
            if self.autoPanningIndex >= 0 {
                
                // perform a circle movement
                let moves = 200
                
                let factor = 2.0 * .pi / Double(moves)
                
                let pitch = sin(Double(self.autoPanningIndex) * factor) * 2
                let yaw = cos(Double(self.autoPanningIndex) * factor) * 2
                self.autoPanningIndex = (self.autoPanningIndex + 1) % moves
                
                cloudView?.resetView()
                cloudView?.pitchAroundCenter(Float(pitch) * 10)
                cloudView?.yawAroundCenter(Float(yaw) * 10)
            }
            
            cloudView?.setDepthFrame(depthData, withTexture: videoPixelBuffer)
        }
    }
    
    func updateDepthLabel(depthFrame: CVPixelBuffer, videoFrame: CVPixelBuffer) {
        
        if touchDetected {
            guard let texturePoint = jetView.texturePointForView(point: self.touchCoordinates) else {
                DispatchQueue.main.async {
                    self.touchDepth.text = ""
                }
                return
            }
            
            // scale
            let scale = CGFloat(CVPixelBufferGetWidth(depthFrame)) / CGFloat(CVPixelBufferGetWidth(videoFrame))
            let depthPoint = CGPoint(x: CGFloat(CVPixelBufferGetWidth(depthFrame)) - 1.0 - texturePoint.x * scale, y: texturePoint.y * scale)
            
            assert(kCVPixelFormatType_DepthFloat16 == CVPixelBufferGetPixelFormatType(depthFrame))
            CVPixelBufferLockBaseAddress(depthFrame, .readOnly)
            let rowData = CVPixelBufferGetBaseAddress(depthFrame)! + Int(depthPoint.y) * CVPixelBufferGetBytesPerRow(depthFrame)
            // swift does not have an Float16 data type. Use UInt16 instead, and then translate
            var f16Pixel = rowData.assumingMemoryBound(to: UInt16.self)[Int(depthPoint.x)]
            CVPixelBufferUnlockBaseAddress(depthFrame, .readOnly)
            
            var f32Pixel = Float(0.0)
            var src = vImage_Buffer(data: &f16Pixel, height: 1, width: 1, rowBytes: 2)
            var dst = vImage_Buffer(data: &f32Pixel, height: 1, width: 1, rowBytes: 4)
            vImageConvert_Planar16FtoPlanarF(&src, &dst, 0)
            
            // Convert the depth frame format to cm
            let depthString = String(format: "%.2f cm", f32Pixel * 100)
            
            // Update the label
            DispatchQueue.main.async {
                self.touchDepth.textColor = UIColor.white
                self.touchDepth.text = depthString
                self.touchDepth.sizeToFit()
            }
        } else {
            DispatchQueue.main.async {
                self.touchDepth.text = ""
            }
        }
    }
    
}

extension AVCaptureVideoOrientation {
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}

extension PreviewMetalView.Rotation {
    
    init?(with interfaceOrientation: UIInterfaceOrientation, videoOrientation: AVCaptureVideoOrientation, cameraPosition: AVCaptureDevice.Position) {
        /*
         Calculate the rotation between the videoOrientation and the interfaceOrientation.
         The direction of the rotation depends upon the camera position.
         */
        self = .rotate0Degrees
    }
}

