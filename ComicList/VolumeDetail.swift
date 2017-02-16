//
//  VolumeDetail.swift
//  ComicList
//
//  Created by Alberto Ortega on 14/6/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import Foundation


struct VolumeDetail {
    let title: String
    let description: String
}


extension VolumeDetail: JSONDecodable {
    
    init?(dictionary: JSONDictionary) {
        
        guard let title = dictionary["name"] as? String else {
            
            return nil
        }
        
        self.title = title
        self.description = dictionary["description"] as? String ?? ""
    }
}
