//
//  AppDelegate.swift
//  CleanflightMobile
//
//  Created by Alex on 09-10-15.
//  Copyright © 2016 Hangar42. All rights reserved.
//
//
//  General notes about this app: (to be moved to a notes.md)
//
//  - Because of a bug we can't use the splitViewController in Preferences.storyboard for iPhones (instead,
//    it uses a different entry point).
//
//  - This project uses both a folder structure and a XCode group structure. Make sure they stay identical to eachother.
//
//  - If you need some code only to be included in the debug builds and not in release versions, use #if DEBUG (declared in Build Settings -> Swift Compiler Misc Flags)
//
//  - SwiftWebVC.swift has one edit: prefersStatusBarHidden() has been added (returns true)
//

import UIKit

let AppWillResignActiveNotification = "AppWillResignActiveNotification",
    AppDidBecomeActiveNotification = "AppDidBecomeActiveNotification"

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?,
        launchWindow: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // bluetooth serial
        bluetoothSerial.delegate = msp
        
        // userdefaults
        userDefaults.registerDefaults(
            [DefaultsAutoConnectNewKey: true,
             DefaultsAutoConnectOldKey: true]
        )
        
        // it's much cleaner to load all initial viewcontrollers programmatically .. first load the storyboards
        let bundle = NSBundle.mainBundle(),
            specific = UIStoryboard(name: UIDevice.isPhone ? "iPhone" : "iPad", bundle: bundle),
            univerial = UIStoryboard(name: "Uni", bundle: bundle),
            preferences = UIStoryboard(name: "Preferences", bundle: bundle)
        
        // load viewcontrollers
        let first = specific.instantiateViewControllerWithIdentifier("HomeViewController") // override for testing
        first.tabBarItem = UITabBarItem(title: "Dashboard", image: UIImage(named: "Dashboard"), tag: 0)
        let second = specific.instantiateViewControllerWithIdentifier("TuningViewController")
        second.tabBarItem = UITabBarItem(title: "Tuning", image: UIImage(named: "Tuning"), tag: 1)
        let third = preferences.instantiateViewControllerWithIdentifier(UIDevice.isPhone ? "PhoneEntry" : "PadEntry")
        third.tabBarItem = UITabBarItem(title: "Setup", image: UIImage(named: "Config"), tag: 2)
        let fourth = univerial.instantiateViewControllerWithIdentifier("CLITabViewController")
        fourth.tabBarItem = UITabBarItem(title: "CLI", image: UIImage(named: "CLI"), tag: 3)

        // initial tab bar controller
        let tabBar = UITabBarController()
        tabBar.viewControllers = [first, second, third, fourth]
        
        // reduce icon size. Because of a bug in iOS we can't resize the image
        tabBar.viewControllers?.forEach() { $0.tabBarItem!.imageInsets = UIEdgeInsetsMake(1, 0, -1, 0) }
        
        // tabbar UI
        UITabBar.appearance().backgroundImage = UIImage()
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundColor = UIColor.blackColor()

        // set window
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.tintColor = UIColor.cleanflightGreen()
        window?.rootViewController = tabBar
        window?.makeKeyAndVisible()
        
        // ready!
        log("App started")

        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        log("Will resign active")
        notificationCenter.postNotificationName(AppWillResignActiveNotification, object: nil)

    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        log("Became active")
        notificationCenter.postNotificationName(AppDidBecomeActiveNotification, object: nil)
    }
}