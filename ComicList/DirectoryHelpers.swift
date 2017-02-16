//
//  DirectoryHelpers.swift
//  ComicList
//
//  Created by Alberto Ortega on 3/6/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import Foundation


extension URL {
    
    // Funcion de clase que nos devuelva el nombre de un fichero temporal.
    static func temporalyFileURL() -> URL {
        
        // Creamos una URL para el directorio de archivos temporales del Sandbox.
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
        
        // Añadimos el nombre del fichero al directorio temporal, utilizando el generador de nombres del sistema.
        return fileURL.appendingPathComponent(UUID().uuidString)
    }
    
    
    // Variable de clase que nos devuelva el directorio de documentos del Sandbox.
    static var documentDirectoryURL: URL {

        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        }
        catch {
            fatalError("Error during get Document directory")
        }
    }
}
