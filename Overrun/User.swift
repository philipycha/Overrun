//
//  User.swift
//  Overrun
//
//  Created by Tevin Maker on 2016-10-19.
//  Copyright © 2016 Philip Ha. All rights reserved.
//

import UIKit

class User: NSObject {

    let userName: String!
    let email: String!
    let uid: String!
    
    init(userName: String, email: String, uid: String) {
        self.userName = userName
        self.email = email
        self.uid = uid
    }
    
    
}
