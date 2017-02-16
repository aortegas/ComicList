//
//  CollectionViewHelpers.swift
//  ComicList
//
//  Created by Alberto Ortega on 31/12/15.
//  Copyright © 2015 Alberto Ortega. All rights reserved.
//

import Foundation
import UIKit

// Definimos el protocolo Reusable que solo puede ser conformado por una clase.
// El protocolo solo tiene una variable calculada de clase, de tipo String para devolver el nombre de registro de una View.
protocol ReusableView: class {
    
    static var defaultReuseIdentifier: String { get }
}


// Definimos el protocolo NibLoadableView que solo puede ser conformado por una clase.
// El protocolo solo tiene una variable calculada de clase, de tipo String para devolver el nombre del Nib de una View.
protocol NibLoadableView: class {
    
    static var nibName: String { get }
}


// Extendemos para dar una implementacion por defecto a la propiedad calculada del protocolo ReusableView, especificando con 
// where el propio tipo con el trabajara (en este caso: UIView). Por lo tanto, devuelve un string a partir de una UIView,
// cuando hace uso de self.
extension ReusableView where Self: UIView {
    
    static var defaultReuseIdentifier: String {
        
        return String(describing: self)
    }
}


// Extendemos para dar una implementacion por defecto a la propiedad calculada del protocolo NibLoadableView, especificando con
// where el propio tipo con el trabajara (en este caso: UIView). Por lo tanto, devuelve un string a partir de una UIView,
// cuando hace uso de self.
extension NibLoadableView where Self: UIView {
    
    static var nibName: String {
        
        return String(describing: self)
    }
}


// Extendemos UICollectionViewCell, para indicar que coja la implementacion por defecto del protocolo ReusableView. Al hacer esto, 
// lo que hacemos es que UICollectionViewCell tome la implementacion por defecto dada en la extension anterior.
extension UICollectionViewCell: ReusableView {}


// Extendemos UICollectionView para poder dar funcionalidad a varios metodos de dos clases diferentes, unos para el registro de celdas y
// otros para obtener dichas celdas. 
extension UICollectionView {
    
    // Implementamos la funcion register para una subclase de UICollectionViewCell. Se indica el parametro _: T.Type para que no se produzca
    // un error de compilacion, al no utilizar el tipo generico en la definicion de la funcion. El parametro espera un tipo de la clase hija
    // UICollectionViewCell.
    // self es una referencia de la subclase de UICollectionViewCell sobre la que se invocara esta funcion. 
    // Con el where especificamos que dicha subclase de UICollectionViewCell,
    // implementa el protocolo ReusableView, porque sino fallaria en compilacion el acceso a T.defaultReuseIdentifier.
    // Es decir, gracias a los protocolos, ahora la subclase de UICollectionView tiene un propiedad calculada mas (defaultReuseIdentifier)
    // la cual devuelve un String con el propio nombre de su clase.
    // IMPORTANTE: Esta implementacion del metodo register, se utiliza para registar UICollectionViewCells y no subclases de de esta.
    func register<T: UICollectionViewCell>(_: T.Type) where T: ReusableView {
        
        self.register(T.self, forCellWithReuseIdentifier: T.defaultReuseIdentifier)
    }
    
    
    // Implementamos la funcion register para una subclase de UICollectionViewCell. Se indica el parametro _: T.Type para que no se produzca
    // un error de compilacion, al no utilizar el tipo generico en la definicion de la funcion. El parametro espera un tipo de la clase hija
    // UICollectionViewCell.
    // self es una referencia de la subclase de UICollectionViewCell sobre la que se invocara esta funcion. 
    // Con el where especificamos que dicha subclase de UICollectionViewCell,
    // implementa los protocolos: ReusableView y NibLoadableView, porque sino fallaria en compilacion los accesos a T.defaultReuseIdentifier 
    // y T.nibName. Es decir, gracias a los protocolos, ahora la subclase de UICollectionView tiene un par de propiedades calculadas mas 
    // (nibName y defaultReuseIdentifier y nibName), las cuales devuelven String con el propio nombre de su clase.
    // IMPORTANTE: Esta implementacion del metodo register, se utiliza para registar subclases de UICollectionViewCell, para que cojan el
    // archivo nib correspondiente.
    func register<T: UICollectionViewCell>(_: T.Type) where T: ReusableView, T: NibLoadableView {

        let bundle = Bundle(for: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        self.register(nib, forCellWithReuseIdentifier: T.defaultReuseIdentifier)
    }
    
    
    // Implementamos la funcion dequeueReusableCell para una subclase de UICollectionViewCell, indicando que como parametro un indexPath y
    // devolviendo una subclase de UICollectionViewCell. Con el where especificamos que dicha subclase de UICollectionViewCell, implementa 
    // el protocolo ReusableView.
    func dequeueReusableCell<T: UICollectionViewCell>(forIndexPath indexPath: IndexPath) -> T where T: ReusableView {
        
        guard let cell = self.dequeueReusableCell(withReuseIdentifier: T.defaultReuseIdentifier, for: indexPath) as? T else {
            
            fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
        }
        
        return cell
    }
    
    
    // Metodo adhoc para esta app.
    // Implementamos la funcion dequeueReusableCell para una subclase de UICollectionViewCell, indicando que como parametro un item(Int) y
    // devolviendo una subclase de UICollectionViewCell. Con el where especificamos que dicha subclase de UICollectionViewCell, implementa
    // el protocolo ReusableView.
    // IMPORTANTE: Lo utilizamos por ejemplo para obtener collections en los issues del VolumeDetail.
    func dequeueReusableCell<T: UICollectionViewCell>(forItem item: Int) -> T where T: ReusableView {
        
        return dequeueReusableCell(forIndexPath: IndexPath(item: item, section: 0))
    }
}

// Resumiendo: El uso posterior de todo esto se reduce a:
// Para el registro:
//      @IBOutlet private weak var collectionView: UICollectionView! {
//          didSet {
//              collectionView.register(VolumeListItemCell.self)
//
// Para la obtencion de collections:
//      func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//
//          let cell: VolumeListItemCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
//          cell.item = viewModel[indexPath.item]
//          return cell
//      }
// 
// En las subclases de UICollectionViewCell:
//      extension VolumeListItemCell: NibLoadableView {}





