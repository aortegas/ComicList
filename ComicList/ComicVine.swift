//
//  ComicVine.swift
//  ComicList
//
//  Created by Alberto Ortega on 31/5/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import Foundation


// Creamos un enum con todas las peticiones que vamos a realizar al API de ComicVine.
enum ComicVine {
    case suggestions(key: String, query: String)
    case search(key: String, query: String, page: UInt)
    case volumeDetail(key: String, identifier: Int)
    case volumeIssues(key: String, identifier: Int)
}


// Extendemos el protocolo Resource, para se pueda terminar obteniendo un URLRequest, con la funcion que tiene implementada.
extension ComicVine: Resource {
    
    // Damos el contenido a la variable path para cada peticion.
    var path: String {
        
        switch self {
        case ComicVine.suggestions, ComicVine.search:
            return "search"
        case let ComicVine.volumeDetail(_, identifier):
            return "volume/4050-\(identifier)"
        case ComicVine.volumeIssues:
            return "issues"
        }
    }
    
    
    // Damos el contenido a la variable parameters para cada peticion.
    var parameters: [String: String] {
        
        switch self {
        case let ComicVine.suggestions(key, query):
            return [
                "api_key": key,
                "format": "json",
                "field_list": "name",
                "limit": "10",
                "page": "1",
                "query": query,
                "resources": "volume"
            ]
            
        case let ComicVine.search(key, query, page):
            return [
                "api_key": key,
                "format": "json",
                "field_list": "id,image,name,publisher",
                "limit": "20",
                "page": "\(page)",
                "query": query,
                "resources": "volume"
            ]
            
        case let ComicVine.volumeDetail(key, _):
            return [
                "api_key": key,
                "format": "json",
                "field_list": "name,description"
            ]
        
        case let ComicVine.volumeIssues(key, identifier):
            return [
                "api_key": key,
                "format": "json",
                "field_list": "id,image,name",
                "filter": "volume:\(identifier)"
            ]
        }
    }
}



