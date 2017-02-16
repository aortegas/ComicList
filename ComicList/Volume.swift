//
//  Volume.swift
//  ComicList
//
//  Created by Alberto Ortega on 1/6/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import Foundation


struct Volume {
    let title: String
}


extension Volume: JSONDecodable {
    
    init?(dictionary: JSONDictionary) {
        
        guard let title = dictionary["name"] as? String else {
            return nil
        }
        
        self.title = title
    }
}
