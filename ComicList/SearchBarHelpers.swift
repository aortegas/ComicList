//
//  SearchBarHelpers.swift
//  ComicList
//
//  Created by Alberto Ortega on 10/02/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import UIKit


extension UISearchBar {
    
    // Variable calculada de tipo UIColor, que devuelve y setea la clave "searchField.textColor", que no aparece directamente en una UISearchBar,
    var searchFieldTextColor: UIColor? {
        
        get {
            return self.value(forKeyPath: "searchField.textColor") as? UIColor
        }
        set {
            self.setValue(newValue, forKeyPath: "searchField.textColor")
        }
    }
}
