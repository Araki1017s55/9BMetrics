//
//  String+Localized.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 6/10/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import Foundation

extension String {
    func localized(comment: String = "") -> String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: comment)
    }
}
