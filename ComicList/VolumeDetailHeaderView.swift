//
//  VolumeDetailHeaderView.swift
//  ComicList
//
//  Created by Alberto Ortega on 11/01/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import UIKit
import Kingfisher
import RxSwift


class VolumeDetailHeaderView: UIStackView {
    
    // MARK: - Propiedades.
    @IBOutlet private weak var imageView: UIImageView!
    
    // Queremos hacer un binding entre el titulo del boton y el observable del viewModel.
    // Estos binding los suele proporcionar RxCocoa a traves de extensiones, sobre las clases de UIKit.
    // Pero en este caso, no existe un metodo para cambiar el titulo del boton, tiene algo para los taps de un boton, pero no para el titulo 
    // de un boton, que es lo que queremos. Por lo que tendremos que hacerlo nosotros mismos.
    // Podriamos hacerlo con subscribe, para subscrirnos al observable, pero queda mas elegante hacerlo con un binding.
    //
    // Y lo creamos asi:
    // 1. Creamos un observer para que pueda observar al observable. Lo creamos de tipo AnyObserver
    var buttonTitle: AnyObserver<String> {
    
        // Creamos el observer con este bloque, que sera lo que se ejecute cuando se reciba un nuevo valor o evento.
        // Cada vez que se reciba un nuevo evento, lo unico que queremos es que se cambie el titulo del boton.
        // Tambien creamos una referencia debil de self, para poder utilizarla dentro del bloque y no hacer referencia a self.
        // Como no sabemos que es self dentro del bloque se recomienda como buena practica, no hacerlo.
        return AnyObserver<String> { [weak self] event in
            
            // Deberiamos asegurarnos de que estamos en thread principal.
            // Saltara una excepcion en thread principal, si intentamos conectar a esta propiedad un observable que emite sus 
            // eventos, en un thread que no es el principal.
            MainScheduler.ensureExecutingOnScheduler()
            
            // Nos preparamos para todos los tipo de evento nos pueden llegar del observable.
            switch event {
            case let .next(value):
                
                // Este self al ser una referencia debil puede tener nil y por eso, nos obliga a poner el ?
                self?.actionButton.setTitle(value, for: .normal)  // Nos quedamos con el titulo que venga en los eventos next.
            
            case let .error(error):
                fatalError("Binding error: \(error)")
            
            case .completed:
                break
            }
        }
    }

    
    // Proceso no Rx. Conectamos la acción del tap del boton (Add / Remove), con lo que queremos que se haga en el viewModel. 
    // Lo haremos en dos pasos:
    //      - Lo que hacemos aqui, es decir, capturar la acción y ejecutar un clousure, que aqui no sabemos que va a hacer.
    //      -
    //
    //
    // Declaramos una variable publica de tipo clousure. La inicializamos con un clousure vacio.
    // Desde el view controller vamos a conectar esta variable actionHandler con el metodo add/remove del viewModel, para que cuando
    // se toque el boton llamemos a add o remove y ejecutemos la logica del viewModel para esta accion.
    var actionHandler: () -> () = {}
    
    // Nos declaramos una action, para los tap en el botton de Add/Remove volumen. Dentro ejecutamos el bloque de la variable actionHandler().
    // Ese bloque conectara con el viewModel y para invocar el metodo de Add/Remove.
    // Por ultimo, tenemos que conectar este action con el xib, al evento Touch Up Inside.
    @IBAction private func didTapActionButton(_ sender: UIButton) {
        actionHandler()
    }
    

    // Variable calculada para setear en la vista los datos de un VolumeSummary, que nos llegaran desde el viewController y a su vez, desde
    // el viewModel a este.
    var summary: VolumeSummary? {
        didSet {
            
            titleLabel.text = summary?.title
            publisherLabel.text = summary?.publisherName
            
            if let imageURL = summary?.imageURL {
                
                ImageDownloader.default.downloadImage(with: imageURL, options: [], progressBlock: nil) { [weak self] (image, error, url, data) in
                    self?.imageView.image = image
                }
            }
        }
    }

    
    // Customizar el resto de outlets cuando esten instanciadas.
    @IBOutlet private weak var actionButton: UIButton! {
        didSet {
            actionButton.tintColor = UIColor(named: .buttonTint)
        }
    }
    
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
}
