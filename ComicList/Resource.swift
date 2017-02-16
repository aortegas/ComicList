//
//  Resource.swift
//  ComicList
//
//  Created by Alberto Ortega on 31/5/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import Foundation


// Definimos el protocolo Resource, que esta compuesto de 3 variables calculadas. Todas ellas juntas configuraran una url
// de solicitud al API.
protocol Resource {
    
    var method: Method { get }
    var baseURL: URL { get }
    var path: String { get }
    var parameters: [String: String] { get }
}


// Creaamos un enum para los verbos a utilizar contra el API.
enum Method: String {
    case GET = "GET"
}


// Damos una implementacion por defecto a todo el protocolo.
extension Resource {
    
    var method: Method {
        return .GET
    }
    
    var baseURL: URL {
        get {
            guard let baseURL = URL(string: "http://www.comicvine.com/api") else {
                
                fatalError("Imposible get baseURL for ComicVine")
            }
            
            return baseURL
        }
    }
    
    var parameters: [String: String] {
        return [:]
    }
    
    
    // A partir de la url base que nos llegue como parametro, montamos la url final con el path + los parametros de la query 
    // (con los datos que tenemos) y devolvemos un NSURLRequest.
    func requestWithBaseURL() -> URLRequest {
        
        // Creamos un URL con la base + el path de la peticion.
        let URL = baseURL.appendingPathComponent(path)
        
        // Optenemos un URLComponents, a partir de la URL creada para poder especificar los parametros de la peticion.
        guard var components = URLComponents(url: URL, resolvingAgainstBaseURL: false) else {
            
            fatalError("Unable to create URLComponents form \(URL)")
        }
    
        // Aplicamos un .map a lo que nos devuelva la variable calculada parameters que es un diccionario de String: String, 
        // para obtener los queryItems de components.
        components.queryItems = parameters
            .map {
                URLQueryItem(name: $0, value: $1)
            }

        // A partir de components, obtenemos la URL final.
        guard let finalURL = components.url else {
            
            fatalError("Unable to retrieve final URL")
        }

        // Creamos el NSURLRequest a partir de la URL final y por ultimo le asignamos el verbo.
        // Utilizamos NSMutableURLRequest para que mas adelante podamos modificar el URLRequest e incluir cabeceras.
        let request = NSMutableURLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        return request as URLRequest
    }
}
