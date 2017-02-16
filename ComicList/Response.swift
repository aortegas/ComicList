//
//  Response.swift
//  ComicList
//
//  Created by Alberto Ortega on 1/6/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import Foundation


// Definomos una estructura con los datos de respuesta del API, sobre + payload.
struct Response {
    
    // MARK: - Properties.
    let status: UInt
    let message: String
    var succeeded: Bool {
        
        return status == 1
    }

    // Dejamos como opcional el payload, por si acaso algun dia la API al dar error, no da contenido. Las variables result y
    // results, las utilizamos en funcion de si tenemos uno o varios JSONDictionary en el payload.
    fileprivate let payload: Any?

    var result: JSONDictionary? {
        return payload as? JSONDictionary
    }
    
    var results: [JSONDictionary]? {
        return payload as? [JSONDictionary]
    }
}


// Como queremos ser un objeto que conforme el JSONDecodable, implementamos el metodo init().
extension Response: JSONDecodable {
    
    init?(dictionary: JSONDictionary) {
        
        guard let status = dictionary["status_code"] as? UInt,
                let message = dictionary["error"] as? String else {
                
            return nil
        }
        
        self.status = status
        self.message = message
        // Guardamos el payload en la variable privada.
        self.payload = dictionary["results"]
    }
}



