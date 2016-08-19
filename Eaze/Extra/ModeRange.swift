//
//  ModeRange.swift
//  Eaze
//
//  Created by Alex on 09-08-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit

class ModeRange: Copyable {
    var identifier = 0,
        auxChannelIndex = 0,
        range = (start: 1300, end: 1700)
    
    init(id: Int) {
        identifier = id
    }
    
    required init(copy: ModeRange) {
        identifier = copy.identifier
        auxChannelIndex = copy.auxChannelIndex
        range.start = copy.range.start
        range.end = copy.range.end
    }
}
