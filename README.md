![Main](https://github.com/hoiberg/eaze/blob/development/img/main.png)
# Eaze - iOS Cleanflight Configurator

Completely written in Swift. Available for free on the App Store. <br>
Tutorial: www.hangar42.nl/eaze-tutorial <br>
More info and links: www.hangar42.nl/eaze <br>

[![Appstore](https://github.com/hoiberg/eaze/blob/development/img/appstore.png)](https://itunes.apple.com/us/app/eaze-cleanflight-configurator/id1130855585?ls=1&mt=8")


## Description

Tune your Cleanflight flight controller with ease from your iPhone or iPad. Just hook up a bluetooth module to your radio controlled aircraft, and you're ready to go!

Eaze is a 100% free and open source Cleanflight Configurator, it features:

- Minimalist PID tuning screen
- Easy PID backup and restore
- A host of configuration options
- Fully functional command line interface
- Easy auto-connect

All in a minimalist layout.

Eaze requires a HM10 Bluetooth module to work, which is available for a low price on various e-commerce websites. Head over to hangar42.nl for an in-depth tutorial on the setup procedure.


## Some notes

- Because of a bug we can't use the splitViewController in Preferences.storyboard for iPhones (instead, it uses a different entry point).
- This project uses both a folder structure and a XCode group structure. Make sure they stay identical to eachother.
- If you need some code only to be included in the debug builds and not in release versions, use `#if DEBUG` (declared in `Build Settings -> Swift Compiler Misc Flags`)
- SwiftWebVC.swift has one edit: `prefersStatusBarHidden()` has been added (returns `true`)


## License

©2016 Hangar42.nl

But feel free to fork this project and reuse code. Apple does not accept GPL software to the App Store, which is why I simply use ©.

