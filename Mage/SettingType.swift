//
//  SettingType.swift
//  MAGE
//
//  Created by Brent Michalski on 5/26/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

public enum SettingType: Int, CaseIterable {
    case connection
    case locationServices
    case observationServices
    case dataSynchronization
    case dataFetching
    case dataPushing
    case locationDisplay
    case navigation
    case timeDisplay
    case mediaPhoto
    case mediaVideo
    case eventInfo
    case changeEvent
    case moreEvents
    case theme
    case logout
    case changePassword
    case attributions
    case disclaimer
    case contactUs
}
