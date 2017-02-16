//
//  SearchResultCell.swift
//  ComicList
//
//  Created by Alberto Ortega on 09/01/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import UIKit
import Kingfisher


class SearchResultCell: UITableViewCell {

    // MARK: Properties
    @IBOutlet private weak var coverImageView: UIImageView!
    // Outlet con variable observada, para que cuando se asigne el outlet en la carga realice la configuracion del color de texto.
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = UIColor(named: .darkText)
        }
    }
    @IBOutlet private weak var publisherLabel: UILabel! {
        didSet {
            publisherLabel.textColor = UIColor(named: .lightText)
        }
    }
    
    // Propiedad observada, para que cuando se asigne el SearchResult (viewModel), se asigne su informacion a las vistas.
    var result: SearchResult? {
        
        didSet {
            
            titleLabel.text = result?.title
            publisherLabel.text = result?.publisherName
            
            // Si tenemos la URL de la imagen.
            if let imageURL = result?.imageURL {
                
                // Descargamos la imagen en background, con Kingfisher.
                ImageDownloader.default.downloadImage(with: imageURL, options: [], progressBlock: nil) { [weak self] (image, error, url, data) in
                    
                    self?.coverImageView.image = image
                }
            }
        }
    }
    
    
    // MARK: Life cycle.
    // Liberamos los recursos cuando se libere la celda.
    override func prepareForReuse() {
        
        super.prepareForReuse()
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil;
    }
}


// Extendemos NibLoadableView, para indicar que coja la implementacion por defecto del protocolo NibLoadableView. Al hacer esto,
// lo que hacemos es que UITableViewCell tome la implementacion por defecto dada en la extension de TableViewHelpers.
// Importante, con esto hacemos que esta subclase de UITableViewCell, conforma el protocolo NibLoadableView y asi,
// pueda entrar por el metodo register, que requieren que esto sea asi y pueda coger su archivo nib correspondiente.
extension SearchResultCell: NibLoadableView {}
