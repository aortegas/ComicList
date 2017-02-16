//
//  VolumeDetailIssuesView.swift
//  ComicList
//
//  Created by Alberto Ortega on 11/01/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import UIKit

class VolumeDetailIssuesView: UIStackView {

    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            
            titleLabel.text = NSLocalizedString("Issues", comment: "")
            titleLabel.textColor = UIColor(named: .darkText)
        }
    }
    
    @IBOutlet private(set) weak var collectionView: UICollectionView! {
        didSet {
            
            collectionView.backgroundColor = UIColor(named: .detailBackground)
            collectionView.register(IssueCell.self)
        }
    }
}
