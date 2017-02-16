//
//  Issue.swift
//  ComicList
//
//  Created by Alberto Ortega on 15/6/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import Foundation


struct Issue {
    let title: String
    let imageURL: URL?
}


extension Issue: JSONDecodable {
    
    init?(dictionary: JSONDictionary) {
        
        guard let title = dictionary["name"] as? String else {

            return nil
        }
        
        self.title = title
    
        if let images = dictionary["image"] as? JSONDictionary,
            let image = images["small_url"] as? String,
                let imageURL = URL(string: image) {
            
            self.imageURL = imageURL
        }
        else {
            self.imageURL = nil
        }
    }
}
