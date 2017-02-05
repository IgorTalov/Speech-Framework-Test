//
//  ViewController.swift
//  SpeechToTextTest
//
//  Created by Игорь Талов on 05.02.17.
//  Copyright © 2017 Игорь Талов. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var textView: UITextView?
    @IBOutlet weak var microphoneButton: UIButton?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recongitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        microphoneButton?.isEnabled = false
        
        speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnable = false
            
            switch authStatus {
            case .authorized:
                isButtonEnable = true
                
            case .denied:
                isButtonEnable = false
                
            case .restricted:
                isButtonEnable = false
                
            case .notDetermined:
                isButtonEnable = false
            }
            
            OperationQueue.main.addOperation {
                self.microphoneButton?.isEnabled = isButtonEnable
            }
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startRecording() {
        
        if recongitionTask != nil {
            recongitionTask?.cancel()
            recongitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Error")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Error")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recongitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
             
                self.textView?.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
                
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recongitionTask = nil
                
                self.microphoneButton?.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error")
        }
        
        textView?.text = "Say something? i'm listening!"
    }
    
    //MARK:SFSpeechRecognizerDelegate
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton?.isEnabled = true
        } else {
            microphoneButton?.isEnabled = false
        }
    }

    //MARK: Actions
    @IBAction func microphoneTapped(_ sender: UIButton)
    {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton?.isEnabled = false
            microphoneButton?.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            microphoneButton?.setTitle("Stop Recording", for: .normal)
        }
    }
    
    
    
}

