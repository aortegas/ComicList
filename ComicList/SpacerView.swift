//
//  SpacerView.swift
//  ComicList
//
//  Created by Alberto Ortega on 09/01/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import UIKit


class SpacerView: UIView {

    // MARK: - Init.
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        self.setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    
    // MARK: - View methods.
    override var intrinsicContentSize : CGSize {
        
        return CGSize(width: 9999, height: 9999)
    }

    
    // MARK: - Private Methods.
    // Intentamos adaptar la view para que se adapte al espacio libre que pueda quedar, bajandole la prioridad.
    private func setupView() {
        
        setContentCompressionResistancePriority(1, for: .horizontal)
        setContentCompressionResistancePriority(1, for: .vertical)
        setContentHuggingPriority(1, for: .horizontal)
        setContentHuggingPriority(1, for: .vertical)
    }
}
