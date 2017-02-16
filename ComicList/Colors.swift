//
//  Colors.swift
//  ComicList
//
//  Created by Alberto Ortega on 13/12/15.
//  Copyright © 2015 Alberto Ortega. All rights reserved.
//

import UIKit


// Extendemos la clase UIColor
extension UIColor {

    // Definimos una enumeracion con los nombres de los colores que utilizaremos en la app.
    // Tambien incluimos una variable calculada, que para cada nombre de color, devuelve su codificacion RGB.
    // Con esta variable calculada, en el codigo nos podemos olvidar de utilizar rawValue, ya que la enumeracion podria tener tipo UInt32
    enum Name {
        case background
        case bar
        case buttonTint
        case darkText
        case detailBackground
        case lightText

        var rgbaValue: UInt32 {
            switch self {
            case .background: return 0xf2f2f3ff
            case .bar: return 0x2e3134ff
            case .buttonTint: return 0x257f17ff
            case .darkText: return 0x282828ff
            case .detailBackground: return 0xecedeeff
            case .lightText: return 0x696e72ff
            }
        }
    }

    
    // Creamos un inicializador de conveniencia, para crear colores a partir del nombre del mismo.
    convenience init(named name: Name) {
    
        // Llamamos a otro inicializador de conveniencia con la oodificacion del nombre del color.
        self.init(rgbaValue: name.rgbaValue)
    }
    
    
    // Creamos un inicializador de conveniencia, que llamara al designado, con la codificacion del color.
    convenience init(rgbaValue: UInt32) {
        
        // Coge el peso de cada color dentro de la codificacion y lo convierte en decimal. Utiliza para ello los operadores a nivel de bits
        // >> y & (and), que aseguran en el caso del alpha que sera ff en el caso de ser 0 a nivel de bit.
        let red   = CGFloat((rgbaValue >> 24) & 0xff) / 255.0
        let green = CGFloat((rgbaValue >> 16) & 0xff) / 255.0
        let blue  = CGFloat((rgbaValue >>  8) & 0xff) / 255.0
        let alpha = CGFloat((rgbaValue      ) & 0xff) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
