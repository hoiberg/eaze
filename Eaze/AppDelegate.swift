//
//  AppDelegate.swift
//  CleanflightMobile
//
//  Created by Alex on 09-10-15.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit

extension Notification.Name {
    enum App {
        static let didBecomeActive = Notification.Name("AppDidBecomeActive")
        static let willResignActive = Notification.Name("AppWillResignActive")
    }
}

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {

    var window: UIWindow?,
        launchWindow: UIWindow?,
        previousTab = 0

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // bluetooth serial
        bluetoothSerial.delegate = msp
        
        // userdefaults
        userDefaults.register(
            defaults: [DefaultsAutoConnectNewKey: true,
             DefaultsAutoConnectOldKey: true]
        )
        
        // it's much cleaner to load all initial viewcontrollers programmatically .. first load the storyboards
        let bundle = Bundle.main,
            specific = UIStoryboard(name: UIDevice.isPhone ? "iPhone" : "iPad", bundle: bundle),
            univerial = UIStoryboard(name: "Uni", bundle: bundle),
            preferences = UIStoryboard(name: "Preferences", bundle: bundle)
        
        // load viewcontrollers
        let first = specific.instantiateViewController(withIdentifier: "HomeViewController") // override for testing
        first.tabBarItem = UITabBarItem(title: "Dashboard", image: UIImage(named: "Dashboard"), tag: 0)
        let second = specific.instantiateViewController(withIdentifier: "TuningViewController")
        second.tabBarItem = UITabBarItem(title: "Tuning", image: UIImage(named: "Tuning"), tag: 1)
        let third = preferences.instantiateViewController(withIdentifier: UIDevice.isPhone ? "PhoneEntry" : "PadEntry")
        third.tabBarItem = UITabBarItem(title: "Setup", image: UIImage(named: "Config"), tag: 2)
        let fourth = univerial.instantiateViewController(withIdentifier: "CLITabViewController")
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
        UITabBar.appearance().backgroundColor = UIColor.black

        // set window
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.tintColor = UIColor.cleanflightGreen()
        window?.rootViewController = tabBar
        window?.makeKeyAndVisible()
        
        // ready!
        log("App started")

        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        log("Will resign active")
        notificationCenter.post(name: Notification.Name.App.willResignActive, object: nil)

    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        log("Became active")
        notificationCenter.post(name: Notification.Name.App.didBecomeActive, object: nil)
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if UIDevice.isPad || landscapeMode {
            return [.landscapeLeft, .landscapeRight]
        }

        return .portrait
    }

    
    // MARK: - UITabBarDelegate
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard tabBarController.selectedIndex != previousTab else { return }
        previousTab = tabBarController.selectedIndex
        
        // notify if it is a configscreen
        var vc = viewController
        while let v = vc as? UINavigationController { vc = v.viewControllers.first! }
        if let v = vc as? ConfigScreen { v.willBecomePrimaryView() }
    }
}
