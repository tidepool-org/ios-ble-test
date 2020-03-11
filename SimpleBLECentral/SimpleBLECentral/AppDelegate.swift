//
//  AppDelegate.swift
//  SimpleBLECentral
//
//  Created by Rick Pasetto on 3/5/20.
//  Copyright © 2020 Rick Pasetto. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Logger.instance.output("\(String(describing: launchOptions))")
        
        if let launchOptions = launchOptions {
            UserDefaults.standard.set(launchOptions, forKey: "lastLaunchOptions")
        }
        
        UserDefaults.standard.synchronize()
        
        dump()
        
        if let ids = launchOptions?[UIApplication.LaunchOptionsKey.bluetoothCentrals] as? [String] {
            for id in ids {
                Logger.instance.output("bluetooth Central: \(id)")
            }
        }
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
}


func dump() {
    UserDefaults.standard.dictionaryRepresentation()
        .filter {
            $0.key.starts(with: "SimpleBLECentral.")
        }
        .forEach { item in
        Logger.instance.output("\(item.key): \(item.value)")
    }
}

func store() {
    Logger.instance.output("")
    let now = Date()
    // TODO: see if the behavior is different if you create a Suite
    UserDefaults.standard.set(ISO8601DateFormatter().string(from: now), forKey: "SimpleBLECentral.now")
    UserDefaults.standard.set(-now.timeIntervalSince1970, forKey: "SimpleBLECentral.nowTimestamp")
    UserDefaults.standard.set(Bundle.main.bundleIdentifier ?? "<>", forKey: "SimpleBLECentral.bundleDisplayName")
}
