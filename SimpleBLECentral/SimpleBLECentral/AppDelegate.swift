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
        
    private var isAfterFirstUnlock: Bool {
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let fileURL = documentDirectory.appendingPathComponent("protection.test")
            guard fileManager.fileExists(atPath: fileURL.path) else {
                let contents = Data("unimportant".utf8)
                do {
                    try contents.write(to: fileURL, options: .completeFileProtectionUntilFirstUserAuthentication)
                    // If file doesn't exist, we're at first start, which will be user directed.
                    return true
                } catch {
                    Logger.instance.error("Something is wrong: \(fileURL) can't be written to")
                    fatalError("Something is wrong: \(fileURL) can't be written to")
                }
            }
            do {
                let data = try Data(contentsOf: fileURL)
                if data.count == 0 {
                    Logger.instance.error("Something is wrong: \(fileURL) is empty")
                    fatalError("Something is wrong: \(fileURL) is empty")
                }
                return true
            } catch {
                // Should be normal return for failing to read the file before first unlock
                Logger.instance.output("Couldn't read \(fileURL): \(error)")
                return false
            }
        } catch {
            Logger.instance.error("\(error)")
        }
        return false
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Logger.prefixFunc = {
            return "(\(application.applicationState))"
        }
        Logger.instance.output("\(String(describing: launchOptions))")
        
        if let launchOptions = launchOptions {
            UserDefaults.standard.set(launchOptions, forKey: "lastLaunchOptions")
        }
        
        if !isAfterFirstUnlock {
            Logger.instance.output("Launching before first unlock!")
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
    UserDefaults.standard.set(now.description(with: .current), forKey: "SimpleBLECentral.now")
    UserDefaults.standard.set(-now.timeIntervalSince1970, forKey: "SimpleBLECentral.nowTimestamp")
    UserDefaults.standard.set(Bundle.main.bundleIdentifier ?? "<>", forKey: "SimpleBLECentral.bundleDisplayName")
}

extension UIApplication.State: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .active: return "A"
        case .inactive: return "I"
        case .background: return "B"
        @unknown default: return "?"
        }
    }
}
