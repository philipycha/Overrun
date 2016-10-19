//
//  AppState.swift
//  Overrun
//
//  Created by Philip Ha on 2016-10-18.
//  Copyright © 2016 Philip Ha. All rights reserved.
//

import Foundation

class AppState: NSObject {

  static let sharedInstance = AppState()

  var signedIn = false
  var displayName: String?
  var photoURL: URL?
}
