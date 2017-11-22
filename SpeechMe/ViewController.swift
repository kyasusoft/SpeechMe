//
//  ViewController.swift
//  SpeechMe
//
//  Created by kyasu on 2017/11/19.
//  Copyright © 2017年 kyasu. All rights reserved.
//

import UIKit
import AVFoundation
import AWSCore
import AWSPolly

class ViewController: UIViewController, AVSpeechSynthesizerDelegate, UITextViewDelegate{

    @IBOutlet weak var speechContents: UITextView!
    
    let speech = AVSpeechSynthesizer()
    
    var rate: Float = 0.5
    var pitch: Float = 1.2
    
    var audioPlayer = AVPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()

        // AVSpeechSynthesizer
        speech.delegate = self

        // polly
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: .USEast2,
                                                               identityPoolId: "us-east-2:4e25d6f2-3315-4a4e-9f3e-5290d644034d")
        credentialProvider.clearKeychain()
        let configuration = AWSServiceConfiguration(region: .USEast2,
                                                    credentialsProvider: credentialProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func changeRate(_ sender: UISlider) {
        rate = sender.value
    }
    
    @IBAction func changePitch(_ sender: UISlider) {
        pitch = sender.value
    }

    // iOSの発話
    @IBAction func speech(_ sender: Any) {
        guard let str = speechContents.text else {
            return
        }
    
        let utterance = AVSpeechUtterance(string: str)//読み上げる文字
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")//読み上げの言語
        utterance.rate =  rate //0.5 //読み上げの速度
        utterance.pitchMultiplier = pitch //1.2 //声の高さ
        utterance.preUtteranceDelay = 0 //読み上げまでの待機時間
        utterance.postUtteranceDelay = 0 //読んだあとの待機時間
        speech.speak(utterance) //発話
    }
    
    // pollyの発話
    @IBAction func speechPolly(_ sender: Any) {
        guard let str = speechContents.text else {
            return
        }
        
        let input = AWSPollySynthesizeSpeechURLBuilderRequest()
        input.text = str
        input.outputFormat = AWSPollyOutputFormat.mp3
        input.voiceId = AWSPollyVoiceId.mizuki
        let builder = AWSPollySynthesizeSpeechURLBuilder.default().getPreSignedURL(input)
        builder.continueWith(block: { (awsTask: AWSTask<NSURL>) -> Any? in
            let url = awsTask.result!
            self.audioPlayer.replaceCurrentItem(with: AVPlayerItem(url: url as URL))
            self.audioPlayer.play()
            
            do {
                let data = try Data.init(contentsOf: url as URL)
                let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask,true)
                let docsDir = dirPaths[0]
                let soundFilePath = docsDir + "/sound.mp3"
                FileManager.default.createFile(atPath: soundFilePath, contents: data, attributes: nil)

            } catch {
                return nil
            }
            
            
            return nil
        })
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
                speechContents.resignFirstResponder()
            return false
        }
        return true
    }
}

