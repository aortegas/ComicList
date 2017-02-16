//
//  TableViewHelpers.swift
//  ComicList
//
//  Created by Alberto Ortega on 08/01/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import UIKit


// Extendemos UITableViewCell para poder dar funcionalidad a varios metodos de dos clases diferentes, unos para el registro de celdas y
// otros para obtener dichas celdas. Al hacer esto, lo que hacemos es que UITableViewCell tome la implementacion por defecto dada en la 
// extension de la clase CollectionViewHelpers.
extension UITableViewCell: ReusableView {}


// Extendemos UITableView para poder dar funcionalidad a varios metodos de dos clases diferentes, unos para el registro de celdas y
// otros para obtener dichas celdas.
extension UITableView {
    
    // Implementamos la funcion register para una subclase de UITableViewCell. Se indica el parametro _: T.Type para que no se produzca
    // un error de compilacion, al no utilizar el tipo generico en la definicion de la funcion. El parametro espera un tipo de la clase hija
    // UITableViewCell.
    // self es una referencia de la subclase de UITableViewCell sobre la que se invocara esta funcion. 
    // Con el where especificamos que dicha subclase de UITableViewCell,
    // implementa el protocolo ReusableView, porque sino fallaria en compilacion el acceso a T.defaultReuseIdentifier.
    // Es decir, gracias a los protocolos, ahora la subclase de UITableView tiene un propiedad calculada mas (defaultReuseIdentifier)
    // la cual devuelve un String con el propio nombre de su clase.
    // IMPORTANTE: Esta implementacion del metodo register, se utiliza para registar UITableViewCells y no subclases de de esta.
    func register<T: UITableViewCell>(_: T.Type) where T: ReusableView {
        
        self.register(T.self, forCellReuseIdentifier: T.defaultReuseIdentifier)
    }

    
    // Implementamos la funcion register para una subclase de UITableViewCell. Se indica el parametro _: T.Type para que no se produzca
    // un error de compilacion, al no utilizar el tipo generico en la definicion de la funcion. El parametro espera un tipo de la clase hija
    // UITableViewCell.
    // self es una referencia de la subclase de UITableViewCell sobre la que se invocara esta funcion. 
    // Con el where especificamos que dicha subclase de UITableViewCell,
    // implementa los protocolos: ReusableView y NibLoadableView, porque sino fallaria en compilacion los accesos a T.defaultReuseIdentifier
    // y T.nibName. Es decir, gracias a los protocolos, ahora la subclase de UITableView tiene un par de propiedades calculadas mas
    // (nibName y defaultReuseIdentifier y nibName), las cuales devuelven String con el propio nombre de su clase.
    // IMPORTANTE: Esta implementacion del metodo register, se utiliza para registar subclases de UICollectionViewCell, para que cojan el
    // archivo nib correspondiente.
    func register<T: UITableViewCell>(_: T.Type) where T: ReusableView, T: NibLoadableView {
        
        let bundle = Bundle(for: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        self.register(nib, forCellReuseIdentifier: T.defaultReuseIdentifier)
    }


    // Implementamos la funcion dequeueReusableCell para una subclase de UITableViewCell, indicando que como parametro un indexPath y
    // devolviendo una subclase de UITableViewCell. Con el where especificamos que dicha subclase de UITableViewCell, implementa
    // el protocolo ReusableView.
    func dequeueReusableCell<T: UITableViewCell>(forIndexPath indexPath: IndexPath) -> T where T: ReusableView {
        
        guard let cell = self.dequeueReusableCell(withIdentifier: T.defaultReuseIdentifier, for: indexPath) as? T else {
    
            fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
        }
        
        return cell
    }
    
    
    // Metodo adhoc para esta app.
    // Implementamos la funcion dequeueReusableCell para una subclase de UITableViewCell, indicando que como parametro un item(Int) y
    // devolviendo una subclase de UITableViewCell. Con el where especificamos que dicha subclase de UITableViewCell, implementa
    // el protocolo ReusableView.
    // IMPORTANTE: Lo utilizamos por ejemplo en las suggestions para obtener viewCells, ya que no se trabaja con un tableViewController ahi.
    func dequeueReusableCell<T: UITableViewCell>() -> T where T: ReusableView {
        
        guard let cell = self.dequeueReusableCell(withIdentifier: T.defaultReuseIdentifier) as? T else {
            
            fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
        }
        
        return cell
    }
}
