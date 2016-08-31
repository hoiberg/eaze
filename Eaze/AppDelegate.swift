//
//  AppDelegate.swift
//  CleanflightMobile
//
//  Created by Alex on 09-10-15.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit

let AppWillResignActiveNotification = "AppWillResignActiveNotification",
    AppDidBecomeActiveNotification = "AppDidBecomeActiveNotification"

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {

    var window: UIWindow?,
        launchWindow: UIWindow?,
        previousTab = 0

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
        tabBar.delegate = self
        
        // reduce icon size. Because of a bug in iOS we can't resize the image
        tabBar.viewControllers?.forEach { $0.tabBarItem!.imageInsets = UIEdgeInsetsMake(1, 0, -1, 0) }
        
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

    
    // MARK: - UITabBarDelegate
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        guard tabBarController.selectedIndex != previousTab else { return }
        previousTab = tabBarController.selectedIndex
        
        // notify if it is a configscreen
        var vc = viewController
        while let v = vc as? UINavigationController { vc = v.viewControllers.first! }
        if let v = vc as? ConfigScreen { v.willBecomePrimaryView() }
    }
}