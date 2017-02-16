//
//  IssueCell.swift
//  ComicList
//
//  Created by Alberto Ortega on 11/01/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import UIKit
import Kingfisher


class IssueCell: UICollectionViewCell {

    // MARK: Properties
    @IBOutlet private weak var imageView: UIImageView!
    // Outlet con variable observada, para que cuando se asigne el outlet en la carga realice la configuracion del color de texto.
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = UIColor(named: .darkText)
        }
    }
    
    // Propiedad observada, para que cuando se asigne el IssueSummary (viewModel), se asigne su informacion a las vistas.
    var summary: IssueSummary? {

        didSet {
        
            titleLabel.text = summary?.title
            
            // Si tenemos la URL de la imagen.
            if let imageURL = summary?.imageURL {

                // Descargamos la imagen en background, con Kingfisher.
                ImageDownloader.default.downloadImage(with: imageURL, options: [], progressBlock: nil) { [weak self] (image, error, url, data) in
                    
                    self?.imageView.image = image
                }
            }
        }
    }
    
    
    // MARK: Life cycle.
    // Liberamos los recursos cuando se libere la celda.
    override func prepareForReuse() {
        
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
    }
}


// Extendemos NibLoadableView, para indicar que coja la implementacion por defecto del protocolo NibLoadableView. Al hacer esto,
// lo que hacemos es que UICollectionViewCell tome la implementacion por defecto dada en la extension de CollectionViewHelpers.
// Importante, con esto hacemos que esta subclase de UICollectionViewCell, conforma el protocolo NibLoadableView y asi,
// pueda entrar por el metodo register, que requieren que esto sea asi y pueda coger su archivo nib correspondiente.
extension IssueCell: NibLoadableView {}
