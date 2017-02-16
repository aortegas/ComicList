//
//  SearchSuggestionsViewModel.swift
//  ComicList
//
//  Created by Alberto Ortega on 08/01/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import Foundation
import RxSwift


protocol SearchSuggestionsViewModelType: class {
    
    // Variable calculada de RxSwift de tipo String. El tipo Variable de RxSwift, permite definir genericos para cualquier tipo del 
    // que queramos convertirnos en observer (haciendonos un bindTo) u observable (o ambos a la vez).
    // Este tipo no termina con eventos onError y antes de desaparacer la variable, se recibe un evento onComplete.
    // con el metodo asObservable(), la convertimos en observable y no se obtendran los valores anteriores, cuando nos hagamos
    // observers de ellas.
    var query: Variable<String> { get }
    
    // Variable calculada de RxSwift que devuelve un observable de tipo array de String, con las sugerencias.
    var suggestions: Observable<[String]> { get }
}


// Implementamos el protocolo anterior.
final class SearchSuggestionsViewModel: SearchSuggestionsViewModelType {
    
    // Incluimos el codigo de conexion con la API. Obtenemos un objeto ComicVineSession, ya que en este es el que contiene las 
    // las funciones de acceso al API.
    private let session = ComicVineSession()

    // Implementamos el protocolo: SearchSuggestionsViewModelType...
    // Creamos una variable calculada query para conformar el protocolo, sin contenido.
    let query = Variable("")
    
    // query contiene un string con la query a buscar, que mediante el metodo: .asObservable() crea un observable, al cual nos vamos a 
    // subscribir en la variable suggestions (array observable de String), para ir recibiendo (mediante eventos next()) los nuevos valores 
    // de busqueda que vaya teniendo query e ir realizando con ellos peticiones al API para obtener las "n" suggestions.
    // Creamos suggestions, indicando que es privada en modo set y haciendola lazy para solo crearla, si llega algun valor de query 
    // buscar. Por cada valor diferente de query, recibimos un evento next, que tratamos y que iremos explicando.
    // IMPORTANTE: De cara a toda esta transformacion de la secuencia observable, todo el proceso es sincrono, aunque haya una peticion
    // de datos al API por medio, es decir, todo el proceso se va realizando y se llega a realizar la solicitud, esta se hace y se 
    // espera a que lleguen los datos de la misma, para poder continuar con el resto de los metodos.
    private(set) lazy var suggestions: Observable<[String]> = self.query.asObservable()
    
        // 1. Filtramos con .filter, para obviar valores que pueda tener query inferiores a tres caracteres. De esta forma no sobrecargamos
        //    al API de conexiones. Si llegamos a filtrar entonces no seguimos ejecutando metodos y no devolveremos ningun evento onNext al 
        //    observer de suggestions.
        .filter { query in
            
            query.characters.count > 2
        }

        
        // 2. Mediante .throttle, ralentizamos la recepcion de nuevos eventos, haciendo que solo los recibamos nuevos valores de query
        //    cuando haya un cierto tiempo fijado (p.e.: 0.3 segundos), desde el ultimo caracter tecleado. De esta forma tambien filtramos 
        //    y conseguimos no hacer tantas peticiones al API.
        .throttle(0.3, scheduler: MainScheduler.instance)

        
        // 3. Mediante .flatMapLatest, nos quedamos con la ultimo valor de query, cancelando el procesamiento que hubieran implicado los 
        //    anteriores valores. Es decir, si nos llega un valor nuevo, haces la peticion nueva, pero la anterior sigue en marcha, con lo 
        //    cual si por ejemplo si nuestra buqueda final tiene 10 caracteres, tecleamos rapido los 7 primeros y despues los 3 ultimos, 
        //    generaremos dos peticiones (una en vuelo por los 7 primeros caracteres) y otra por los 10 ultimos. Con flatMapLatest, lo que
        //    hacemos es quedarnos con el ultimo valor que ha llegado (el de los 10 caracteres), cancelando la anterior solicitud que 
        //    tendriamos que realizar al API. Con esto, mas los filtros anteriores, reducimos el numero de solitudes al API.
        .flatMapLatest { query in

            // Realiamos la peticion de busqueda de sugerencias al API.
            self.session.suggestedVolumes(query)
            
                // Si nos llega algun error, podemos optar por devolver el mensaje de error como texto de la primera sugerencia. Pero 
                // en este caso, vamos devolver un array de sugerencias, omitiendo los errores. Terminaremos aqui el procesamiento de 
                // los siguientes metodos, devolviendo un evento next, con el array vacio.
                .catchErrorJustReturn([])
        }
        
        
        // 4. Si hemos llegado hasta aqui, es porque hemos conseguido obtener un array observable de objetos Volume. Por tanto, tenemos 
        //    que mapear este array observable de objetos Volume a un array de String, que es lo que vamos a mostrar como contenido de las 
        //    celdas de la lista de sugerencias. Con .map, realizamos dicho mapeo.
        .map { volumes in
            
            // Creamos un array de String, que es lo que vamos a devolver, como resultado del mapeo.
            var titles: [String] = []
            
            // Procesamos todos los Volume con for. Con where filtramos, para no procesar un Volume que ya hubieramos procesado 
            // anteriormente y que ya tuvieramos en nuestro array de Strings, es decir, eliminando duplicados.
            for volume in volumes where !titles.contains(volume.title) {
                
                // Añadimos el titulo del Volume a nuestro array de String.
                titles.append(volume.title)
            }
            
            // Devolvemos el array de String, con todas las sugerencias.
            return titles
        }
    
        
        // 5. Establecemos o nos aseguramos que todo lo que hagamos a partir de aqui, se realizara en el main thread, ya que los resultados
        //    se van a obtener en este thread, para ser mostrados en la vista.
        .observeOn(MainScheduler.instance)

        
        // 6. En este caso sabemos que como variable observable suggestions, solo tendremos un observer, pero si por el contrario, tuvieramos
        //    mas de un observer con .shareReplay nos aseguramos que cuando se subscribieran esos nuevos observers, no se volvera a realizar 
        //    la solucitud al API. Es decir, .shareReplay configura un observable para que tenga un buffer con el tamaño que le digamos (en
        //    este caso 1 porque va a devolver un solo evento next), por lo tanto, los nuevos observers recibiran el ultimo evento next
        //    enviado anteriormente. Comentamos este metodo, porque no estamos seguros de que ante un nuevo observer, las busquedas que
        //    solicitaran fueran las mismas que la ultima consulta realizada al API.
        //    .shareReplay(1)
}










