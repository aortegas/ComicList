//
//  JSONDecodable.swift
//  ComicList
//
//  Created by Alberto Ortega on 1/6/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import Foundation


// Nos creamos un typeAlias de lo que consideramos un diccionario de JSON y que llamaremos JSONDictionary.
typealias JSONDictionary = [String: AnyObject]


// Como la API de ComicVine, sabemos siempre que devuelve un JSONDictionary o array de JSONDictionary, en caso correcto,
// definimos un protocolo, para que todo aquel objeto de negocio de respuesta que lo implemente, sea capaz de construirse 
// a partir de un JSONDictionary que le pasemos.
protocol JSONDecodable {
    
    init?(dictionary: JSONDictionary)
}


// Las siguiente funciones devuelven tipos genericos (JSONDecodable), es decir, clases o structs que implementen el 
// protocolo JSONDecodable. El protocolo especifica, que los objetos JSONDecodable deben crearse a partir de un tipo
// JSONDictionary. Estos mismos objetos se obtendran con estas funciones a partir de los datos recibidos del API.
func decode<T: JSONDecodable>(_ dictionary: JSONDictionary) -> T? {

    // Devolvemos un objeto de tipo T (opcional) que construimos con el constructor del tipo del protocolo, a partir
    // del JSONDictionary que nos pasan.
    return T(dictionary: dictionary)
}


// La misma funcion que la anterior, pero para un array de JSONDictionary.
func decode<T: JSONDecodable>(_ dictionaries: [JSONDictionary]) -> [T]? {
    
    // Hacemos lo mismo que la funcion anterior, pero en este caso devolveremos solamente aquellos que hayamos podido 
    // desempaquetar correctamente. Es decir, inicialmente podriamos hacer esto con map, pero map solo trabaja con la 
    // seguridad de que todos se desempaquetarian correctamente. Es decir, las mismas ocurrencias de entrada que de 
    // salida. La solucion aqui es flatmap, para hacer lo que queremos, ya que flatMap, solo coge lo que es diferente 
    // de nil. En este caso, flatMap es como un flatMap + filter
    return dictionaries.flatMap { T(dictionary: $0) }
}


// En todas las peticiones al API, en primer lugar, obtenemos un Data, que posteriormente, esperamos convertir en un 
// tipo JSONDecodable.
func decode<T: JSONDecodable>(_ data: Data) -> T? {
    
    // try?, significa que en caso de error, devolvera un opcional y el valor que sea en caso correcto.
    // Hacemos un guard para verificar que lo que estamos transformando pase todas las validaciones, en caso contrario, 
    // devolvemos nil. Es decir, que funcione ok NSJSONSerialization, que lo que nos hayan pasado se pueda transformar a 
    // un JSONDictionary y por ultimo, que se pueda decodificar el dictionary en un objeto de tipo que conforme 
    // JSONDecodable.
    guard let JSONObject = try? JSONSerialization.jsonObject(with: data, options: []),
            let dictionary = JSONObject as? JSONDictionary,
                let object: T = decode(dictionary) else {
                
        return nil
    }
    
    return object
}


