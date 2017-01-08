//
//  Notifications.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 28/4/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import Foundation

let kWheelVariableChangedNotification = "wheelVariableChanged"
let kHonkHonkNotification = "kHonkHonk"



// Settings Constants 

let kTestMode = "enabled_test"
let kDashboardMode = "dashboard_mode"
let kBlockSleepMode = "block_sleep"
let kSpeedAlarm = "speedAlarm"
let kPassword = "password"
let kBatteryAlarm = "battery"
let kNotifySpeed = "notifySpeed"
let kNotifyBattery = "notifyBattery"


// UserNotifications

enum UserNotificationCategory : String{
    case batteryLevel = "es.gorina.9BMetrics.batteryLevel"
    case speed = "es.gorina.9BMetrics.speed"
}

