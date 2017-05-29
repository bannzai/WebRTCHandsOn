//
//  ChatViewController.swift
//  WebRTCHandsOn
//
//  Created by Takumi Minamoto on 2017/05/27.
//  Copyright © 2017 tnoho. All rights reserved.
//

import UIKit
import WebRTC
import Starscream

class ChatViewController: UIViewController, WebSocketDelegate, RTCPeerConnectionDelegate {
    var websocket: WebSocket! = nil
    
    var peerConnectionFactory: RTCPeerConnectionFactory! = nil
    var peerConnection: RTCPeerConnection! = nil
    var localVideoTrack: RTCVideoTrack?
    var audioSource: RTCAudioSource?
    var videoSource: RTCAVFoundationVideoSource?

    @IBOutlet weak var cameraPreview: RTCCameraPreviewView!
    @IBOutlet weak var remoteVideoView: RTCEAGLVideoView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // RTCPeerConnectionFactoryの初期化
        peerConnectionFactory = RTCPeerConnectionFactory()
        
        startVideo()
        
        websocket = WebSocket(url: URL(string: "wss://conf.space/WebRTCHandsOnSig/tnoho")!)
        websocket.delegate = self
        websocket.connect()
    }
    
    deinit {
        if peerConnection != nil {
            hangUp()
        }
        if websocket.isConnected {
            websocket.disconnect()
        }
        audioSource = nil
        videoSource = nil
        peerConnectionFactory = nil
    }
    
    func startVideo() {
        // 音声ソースの設定
        let audioSourceConstraints = RTCMediaConstraints(
            mandatoryConstraints: nil, optionalConstraints: nil)
        // 音声ソースの生成
        audioSource = peerConnectionFactory.audioSource(with: audioSourceConstraints)
        
        // 映像ソースの設定
        let videoSourceConstraints = RTCMediaConstraints(
            mandatoryConstraints: nil, optionalConstraints: nil)
        videoSource = peerConnectionFactory.avFoundationVideoSource(with: videoSourceConstraints)
        // 映像ソースをプレビューに設定
        cameraPreview.captureSession = videoSource?.captureSession
    }
    
    func createPeerConnection() {
        // STUN/TURNサーバーの指定
        let configuration = RTCConfiguration()
        configuration.iceServers = [
            RTCIceServer.init(
                urlStrings: ["stun:stun.l.google.com:19302"])]
        // PeerConecctionの設定(今回はなし)
        let peerConnectionConstraints = RTCMediaConstraints(
            mandatoryConstraints: nil, optionalConstraints: nil)
        // PeerConnectionの初期化
        peerConnection = peerConnectionFactory.peerConnection(
            with: configuration, constraints: peerConnectionConstraints, delegate: self)
        
        // 音声トラックの作成
        let localAudioTrack = peerConnectionFactory.audioTrack(with: audioSource!, trackId: "ARDAMSa0")
        // PeerConnectionからSenderを作成
        let audioSender = peerConnection.sender(withKind: kRTCMediaStreamTrackKindAudio, streamId: "ARDAMS")
        // Senderにトラックを設定
        audioSender.track = localAudioTrack
        
        
        // 映像トラックの作成
        localVideoTrack = peerConnectionFactory.videoTrack(with: videoSource!, trackId: "ARDAMSv0")
        // PeerConnectionからVideoのSenderを作成
        let videoSender = peerConnection.sender(withKind: kRTCMediaStreamTrackKindVideo, streamId: "ARDAMS")
        // Senderにトラックを設定
        videoSender.track = localVideoTrack
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
    @IBAction func connectButtonAction(_ sender: Any) {
        if peerConnection == nil {
            createPeerConnection()
        }
    }

    func websocketDidConnect(socket: WebSocket) {
        LOG("websocketが接続されました")
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        LOG("websocketが切断されました: \(String(describing: error?.localizedDescription))")
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        LOG("Messageを受信しました : \(text)")
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        LOG("Dataを受信しました : \(data.count)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        // 接続情報交換の状況が変化した際に呼ばれます
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        // 映像/音声が追加された際に呼ばれます
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        // 映像/音声削除された際に呼ばれます
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        // 接続情報の交換が必要になった際に呼ばれます
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        // PeerConnectionの接続状況が変化した際に呼ばれます
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        // 接続先候補の探索状況が変化した際に呼ばれます
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        // Candidate(自分への接続先候補情報)が生成された際に呼ばれます
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        // DataChannelが作られた際に呼ばれます
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        // Candidateが削除された際に呼ばれます
    }
    
    @IBAction func hangupButtonAction(_ sender: Any) {
        hangUp()
    }
    
    func hangUp() {
        localVideoTrack = nil
        peerConnection = nil
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        // 切断ボタンを押した時
        if peerConnection != nil {
            hangUp()
        }
        websocket.disconnect()
        _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    // 参考にさせていただきました！Thanks: http://seesaakyoto.seesaa.net/article/403680516.html
    func LOG(_ body: String = "",
             function: String = #function,
             line: Int = #line)
    {
        print("[\(function) : \(line)] \(body)")
    }
}
