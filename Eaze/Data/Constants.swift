//
//  MixerList.swift
//  CleanflightMobile
//
//  Created by Alex on 23-12-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import Foundation

let appVersion: Version = "0.1.0", // version of this app
    apiMinVersion: Version = "1.2.1", // down to and including
    apiMaxVersion: Version = "2.0.0", // up to and not including
    pidControllerChangeMinApiVersion: Version = "1.5.0" // down to and including

let mixerList = [
    (name: "Tricopter",       model: "tricopter"),
    (name: "Quad +",          model: "quad_x"),
    (name: "Quad X",          model: "quad_x"),
    (name: "Bicopter",        model: "custom"),
    (name: "Gimbal",          model: "custom"),
    (name: "Y6",              model: "y6"),
    (name: "Hex +",           model: "hex_plus"),
    (name: "Flying Wing",     model: "custom"),
    (name: "Y4",              model: "y4"),
    (name: "Hex X",           model: "hex_x"),
    (name: "Octo X8",         model: "custom"),
    (name: "Octo Flat +",     model: "custom"),
    (name: "Octo Flat X",     model: "custom"),
    (name: "Airplane",        model: "custom"),
    (name: "Heli 120",        model: "custom"),
    (name: "Heli 90",         model: "custom"),
    (name: "V-tail Quad",     model: "quad_vtail"),
    (name: "Hex H",           model: "custom"),
    (name: "PPM to SERVO",    model: "custom"),
    (name: "Dualcopter",      model: "custom"),
    (name: "Singlecopter",    model: "custom"),
    (name: "A-tail Quad",     model: "quad_atail"),
    (name: "Custom",          model: "custom"),
    (name: "Custom Airplane", model: "custom"),
    (name: "Custom Tricopter", model: "custom")
]

let boards = [
    (identifier: "TEST", name: "Test board"),
    (identifier: "CJM1", name: "CJMCU"),
    (identifier: "AFF3", name: "AfroFlight Naze32 PRO"),
    (identifier: "AFNA", name: "AfroFlight Naze32"),
    (identifier: "AWF3", name: "AlienFlight F3"),
    (identifier: "CC3D", name: "CopterControl 3D (CC3D)"),
    (identifier: "EUF1", name: "EUSTM32F103RC"),
    (identifier: "OLI1", name: "Olimexino STM32"),
    (identifier: "CHF3", name: "Chebuzz F3"),
    (identifier: "CLBR", name: "Colibri Race"),
    (identifier: "LUX",  name: "Lumenier Lux"),
    (identifier: "MOTO", name: "MotoLab Cyclone"),
    (identifier: "103R", name: "Port103R"),
    (identifier: "RMDO", name: "ReadyMade RC Dodo"),
    (identifier: "SPKY", name: "TauLabs Sparky"),
    (identifier: "SRF3", name: "Seriously Pro F3"),
    (identifier: "SDF3", name: "STM32F3 Discovery"),
    (identifier: "SRFM", name: "Seriously Pro Mini"),
    (identifier: "SPEV", name: "Seriously Pro EVO")
]

let flightControllerVariants = [
    (identifier: "MWII", name: "MultiWii"),
    (identifier: "CLFL", name: "Cleanflight"),
    (identifier: "BAFL", name: "Baseflight"),
    (identifier: "BTFL", name: "Betaflight"),
    (identifier: "RCFL", name: "Raceflight")
]