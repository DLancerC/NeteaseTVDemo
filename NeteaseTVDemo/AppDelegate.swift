
import UIKit
import NeteaseRequest
import AVFoundation
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //MARK: 设置屏幕常亮
        UIApplication.shared.isIdleTimerDisabled = true
        //播放器设置
        initConfig()
        UserDefaults.standard.set(1, forKey: "searchIndex")
        //MARK:  服务部署请参考  https://github.com/Binaryify/NeteaseCloudMusicApi/blob/master/README.MD
        //MARK: 为了自己的账号安全，请尽量使用自己部署的服务
        //下面是我在腾讯云部署的（不保证一直能用）
        NR_BASEURL = Settings.service
        
        guard let loginCookie = UserDefaults.standard.string(forKey: "cookie") else {
            window = UIWindow()
            Task {
                do {
                    let anonimousLogin: NRAnonimousModel = try await anonimousLogin()
                    UserDefaults.standard.setValue(anonimousLogin.cookie, forKey: "cookie")
                    cookie = anonimousLogin.cookie
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "login"), object: nil, userInfo: nil)
                } catch {
                    print(error)
                }
            }
            window?.rootViewController = WKTabBarViewController.creat()
            
            window?.makeKeyAndVisible()
            return true
        }
        cookie = loginCookie
        window = UIWindow()
        
        window?.rootViewController = WKTabBarViewController.creat()
        
        window?.makeKeyAndVisible()
        
        return true
    }
    
    
    func reloadApplication() {
        UIView.transition(with: self.window!, duration: 0.3, options: .transitionCrossDissolve) {
            UIView.setAnimationsEnabled(false)
            self.window?.rootViewController = WKTabBarViewController.creat()
            UIView.setAnimationsEnabled(UIView.areAnimationsEnabled)
        }
    }
    
    /** 初始化配置*/
    func initConfig() {
        
        
        /** 激活播放器*/
        wk_player.active()
        /** 计时器初始化配置*/
        wk_countdown.initConfig()
        
    }
    
    func showTabBar() {
        window?.rootViewController = WKTabBarViewController.creat()
    }
    
    
    override func remoteControlReceived(with event: UIEvent?) {
        if event?.type == UIEvent.EventType.remoteControl {
            switch event?.subtype {
            case .remoteControlPause:
                wk_player.pausePlayer()
            case .remoteControlPlay:
                //播放
                wk_player.resumePlayer()
            case .remoteControlPreviousTrack:
                //前一首
                do {
                    try wk_player.playLast()
                } catch {
                    print(error)
                }
            case .remoteControlNextTrack:
                //下一首
                do {
                    try wk_player.playNext()
                } catch {
                    print(error)
                }
            default:
                break
            }
            wk_player.updateLockedScreenMusic()
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        wk_player.active()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let activeAudioId = url.host()
        if let currentAudioId = wk_player.currentModel?.wk_audioId {
            if String(currentAudioId) == activeAudioId && wk_player.isPlaying {
                if let tabBarViewController = window?.rootViewController as? WKTabBarViewController {
                    tabBarViewController.selectedIndex = 4
                }
                return true
            }
        }
        if let playList : [CustomAudioModel] = UserDefaults.standard.shareListValue(forKey: "playList"){
            wk_player.allOriginalModels = playList
            for (index, audio) in playList.enumerated() {
                if let audioId = audio.wk_audioId {
                    if String(audioId) == activeAudioId {
                        if (try? wk_player.play(index: index)) != nil {
                            //刷新缓存播放列表顺序
                            if ( playList.count - 1 > index){
                                var newplayList = Array(playList[index+1...playList.count-1] + playList[0...index])
                                UserDefaults.standard.setShareValue(codable: newplayList, forKey: "playList")
                            }
                            //TODO 回触发播放UI不更新的bug，暂时注释
//                            if let tabBarViewController = window?.rootViewController as? WKTabBarViewController {
//                                tabBarViewController.selectedIndex = 4
//                            }
                        }
                        
                        return true
                    }
                }
            }
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }


}

