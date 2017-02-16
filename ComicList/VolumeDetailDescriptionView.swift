//
//  VolumeDetailDescriptionView.swift
//  ComicList
//
//  Created by Alberto Ortega on 11/01/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import UIKit

class VolumeDetailDescriptionView: UIStackView {

    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            
            titleLabel.text = NSLocalizedString("About", comment: "")
            titleLabel.textColor = UIColor(named: .darkText)
        }
    }
    
    @IBOutlet private(set) weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.textColor = UIColor(named: .darkText)
        }
    }
}
