//
//  MainViewController.swift
//  laradiosv
//
//  Created by KYC_Mac on 9/27/19.
//  Copyright © 2019 KYC_Mac. All rights reserved.
//

import UIKit
import FRadioPlayer
import AVFoundation
import CoreBluetooth

class MainViewController: UIViewController {

    @IBOutlet weak var hideUV: UIView!
    @IBOutlet weak var menuUV: UIView!
    @IBOutlet weak var menuUTV: UITableView!
    
    @IBOutlet weak var descUL: UILabel!
    
    @IBOutlet weak var menuUB: UIButton!
    @IBOutlet weak var shareUB: UIButton!
    @IBOutlet weak var mediaUB: UIButton!
    @IBOutlet weak var lowUIB: UIButton!
    @IBOutlet weak var highUIB: UIButton!
    @IBOutlet weak var muteUIB: UIButton!
    @IBOutlet weak var webLinkUIIMG: UIImageView!
    
    var isShowMenu = false
    var isMute = false
    var isfirst = false
    var isHighLow = false
    var width = 275
    var ble: CBCentralManager!
    
    var player = FRadioPlayer.shared
    let reachability = Reachability()!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        descUL.alpha = 0.0
        
        let hideTap = UITapGestureRecognizer(target: self, action: #selector(self.handleHideUVTap(_:)))
        hideUV.addGestureRecognizer(hideTap)
        
        ble = CBCentralManager()
        ble.delegate = self
        
        player.delegate = self
        
        let tappedWebLink = UITapGestureRecognizer(target: self, action: #selector(tapDetected))
        webLinkUIIMG.isUserInteractionEnabled = true
        webLinkUIIMG.addGestureRecognizer(tappedWebLink)
        
        NotificationCenter.default.addObserver(self, selector: #selector(internetChanged), name: Notification.Name.reachabilityChanged, object: reachability)
        do{
            try reachability.startNotifier()
        }catch{
            print("Could not start notifier")
        }
        
        ///earset connection check
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        if currentRoute.outputs.count != 0 {
            for description in currentRoute.outputs {
                if description.portType == .headsetMic{
                    print("headset Mic is plugged in")
                }
                else {
                    print("headset Mic is not plugged in")
                }
            }
        }
        else{
            print("device is required")
        }
        NotificationCenter.default.addObserver(self, selector: #selector(audioChangeListenner(_:)), name: AVAudioSession.routeChangeNotification,
        object: nil)
    }
    
//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        UIApplication.shared.endReceivingRemoteControlEvents()
//    }
    
    @objc dynamic private func audioChangeListenner(_ notification: Notification){
        let audioRouteChangeReason = notification.userInfo![AVAudioSessionRouteChangeReasonKey] as! UInt

        switch audioRouteChangeReason {
        case AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue:
            if self.player.isPlaying {
                self.stopEvent()
            }
            else{
                self.playEvent()
            }
            print("headphone plugged in")
        case AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue:
            if self.player.isPlaying {
                self.stopEvent()
            }
            else{
                self.playEvent()
            }
            print("headphone pulled out")
        default:
            break
        }
    }
    
    @objc func internetChanged(note: Notification){
        let reachability = note.object as! Reachability
        if reachability.connection != .none {
            if reachability.connection == .wifi {
                if isfirst == false{
                    self.stopEvent()
                }else{
                    DispatchQueue.main.async {
                        if self.player.isPlaying{
                            self.stopEvent()
                        }
                        else{
                            self.playEvent()
                        }
                    }
                }
                print("connect wifi")
            }
            else if reachability.connection == .cellular{
                if isfirst == false {
                    self.stopEvent()
                }
                else{
                    DispatchQueue.main.async {
                        if self.player.isPlaying{
                            self.stopEvent()
                        }else{
                            self.playEvent()
                        }
                    }
                }
                print("connect 4G")
            }
            else{
                DispatchQueue.main.async {
                    print("can not connet network")
                    self.stopEvent()
                }
            }
        }
        else {
            DispatchQueue.main.async {
                print("can not connet network")
                self.stopEvent()
                self.descUL.text = "Unable to connect network."
            }
        }
    }
    
    func playEvent(){
        let apiUrl = UserDefaults.standard.string(forKey: "Level")!
        player.radioURL = URL(string: apiUrl)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
            print("Playback OK")
            try AVAudioSession.sharedInstance().setActive(true)
            print("Session is Active")
        } catch {
            print(error)
        }
        player.play()
        if UserDefaults.standard.integer(forKey: "isHighLow") == 0 {
            self.lowUIB.setImage(UIImage(named: "img_low_active"), for: .normal)
            self.highUIB.setImage(UIImage(named: "img_high"), for: .normal)
        }
        else{
            self.lowUIB.setImage(UIImage(named: "img_low"), for: .normal)
            self.highUIB.setImage(UIImage(named: "img_high_active"), for: .normal)
        }
        mediaUB.setImage(UIImage(named: "img_btn_stop_active"), for: .normal)
    }
    
    func stopEvent(){
        player.stop()
        mediaUB.setImage(UIImage(named: "img_play_btn_active"), for: .normal)
        self.lowUIB.setImage(UIImage(named: "img_low"), for: .normal)
        self.highUIB.setImage(UIImage(named: "img_high"), for: .normal)
    }
        
    @objc func tapDetected() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SocialViewController") as! SocialViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        menuUV.frame.origin.x = CGFloat(-width)
        hideUV.alpha = 0.0
        hideUV.isUserInteractionEnabled = false
        isShowMenu = false
    }
    
    @objc func handleHideUVTap(_ sender: UITapGestureRecognizer? = nil) {
        // handling code
        if isShowMenu {
            isShowMenu = false
            Global.onMoveAnimationUIView(view: menuUV, moveSpace: CGFloat(-width), direction: true, success:{
                () in
                self.menuUV.frame.origin.x = CGFloat(-self.width)
            })
            Global.onFadeAnimationUIView(view: hideUV, direction: false)
        }
    }
    
    func onClickMenuItem(index: Int) {
        switch index {
        case 0:
            self.handleHideUVTap()
            break
        case 1:
            if let appleUrl = URL(string: "https://apps.apple.com/us/app/id") {
                UIApplication.shared.open(appleUrl)
            } else {
                guard let url = URL(string: "market://details?id=\(appBundleID)")  else { return }
                UIApplication.shared.open(url)
            }
            break
        default:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "AboutViewController") as! AboutViewController
            navigationController?.pushViewController(vc, animated: true)
            break
        }
    }
    
    @IBAction func onClickMenuUB(_ sender: Any) {
        if !isShowMenu {
            isShowMenu = true
            Global.onMoveAnimationUIView(view: menuUV, moveSpace: CGFloat(width), direction: true, success:{
                () in
                self.menuUV.frame.origin.x = 0.0
            })
            Global.onFadeAnimationUIView(view: hideUV, direction: true)
        }
    }
    
    @IBAction func onClickShareUB(_ sender: Any) {
        let shareLine = descUL.text
        let firstActivityItem = "Jeg lytter til \(shareLine ?? "") på PartyFM"
        let secondActivityItem : NSURL = NSURL(string: "https://apps.apple.com/us/app/id")!
        let image : UIImage = UIImage(named: "img_icon")!
        
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [firstActivityItem, secondActivityItem, image], applicationActivities: nil)
        
        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
        
        activityViewController.excludedActivityTypes = [
            UIActivity.ActivityType.postToWeibo,
            UIActivity.ActivityType.print,
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.addToReadingList,
            UIActivity.ActivityType.postToFlickr,
            UIActivity.ActivityType.postToVimeo,
            UIActivity.ActivityType.postToTencentWeibo
        ]
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func onClickMediaUB(_ sender: Any) {
        if isfirst == false{
            isfirst = true
            playEvent()
        }
        if player.isPlaying {
            stopEvent()
        } else {
            playEvent()
        }
    }
    
    @IBAction func onClickLowUIB(_ sender: Any) {
        if isfirst == false {
            UserDefaults.standard.set(0, forKey: "isHighLow")
            UserDefaults.standard.set(apiAudioLinkLow, forKey: "Level")
            playEvent()
            isfirst = true
        }else{
            if UserDefaults.standard.integer(forKey: "isHighLow") == 0{
                return
            }
            else{
                UserDefaults.standard.set(0, forKey: "isHighLow")
                UserDefaults.standard.set(apiAudioLinkLow, forKey: "Level")
                playEvent()
            }
        }
    }
    @IBAction func onClickHighUIB(_ sender: Any) {
        if isfirst == false {
            UserDefaults.standard.set(1, forKey: "isHighLow")
            UserDefaults.standard.set(apiAudioLinkHigh, forKey: "Level")
            playEvent()
            isfirst = true
        }else{
            if UserDefaults.standard.integer(forKey: "isHighLow") == 1{
                return
            }
            else{
                UserDefaults.standard.set(1, forKey: "isHighLow")
                UserDefaults.standard.set(apiAudioLinkHigh, forKey: "Level")
                playEvent()
            }
        }
    }
    @IBAction func onClickMuteUIB(_ sender: Any) {
        if isMute == false {
            muteUIB.setImage(UIImage(named: "img_sound_off"), for: .normal)
            player.pause()
            descUL.alpha = 1.0
            isMute = true
        }
        else{
            muteUIB.setImage(UIImage(named: "img_sound_on"), for: .normal)
            player.play()
            isMute = false
        }
    }
    
//    public func disconnectAVPlayer() {
//        self.player = nil
//    }
//
//    public func reconnectAVPlayer() {
//        self.player = player
//    }
}

extension MainViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuItemTableViewCell", for: indexPath) as! MenuItemTableViewCell
        
        let item = menuItems[indexPath.row]
        cell.initWithMenuItem(item: item)
        
        return cell
    }
    
}

extension MainViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        for item in menuItems {
            item.isSelected = false
        }
        
        let item = menuItems[indexPath.row]
        item.isSelected = true
        menuUTV.reloadData()
        
        onClickMenuItem(index: indexPath.row)
    }
    
}

extension MainViewController: FRadioPlayerDelegate {
    
    func radioPlayer(_ player: FRadioPlayer, playerStateDidChange state: FRadioPlayerState) {
        if state == .loading{
            descUL.alpha = 1;
            descUL.text = state.description
        }
    }
    
    func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlaybackState) {
        if player.isPlaying {
            Global.onFadeAnimationUIView(view: descUL, direction: true)
        } else {
            Global.onFadeAnimationUIView(view: descUL, direction: false)
        }
    }
    
    func radioPlayer(_ player: FRadioPlayer, metadataDidChange rawValue: String?) {
        descUL.text = rawValue
    }
    
}

extension MainViewController: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if isfirst == false {
                self.stopEvent()
            }
            else{
                self.playEvent()
                print("bluetooth ON")
            }
            break
        case .poweredOff:
            self.stopEvent()
            print("bluetooth OFF")
            break
        default:
            break
        }
    }
}

