//
//  ComicVineSession.swift
//  ComicList
//
//  Created by Alberto Ortega on 2/6/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import Foundation
import RxSwift


// Creamos un enum, para inventariar todos los errores de red y de mapeo de JSON de respuesta.
enum ComicVineError: Error {
    case couldNotDecodeJSON
    case badStatus(status: UInt, message: String) //Errores del Servidor.
    case other(NSError) // Errors Conectivity, etc.
}

// Damos descripcion a cada uno de los errores anteriores.
extension ComicVineError: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .couldNotDecodeJSON:
            return "Could not decode JSON"
        case let .badStatus(status, message):
            return "Bad Status: \(status), \(message)"
        case let .other(error):
            return "Other error: \(error)"
        }
    }
}


final class ComicVineSession {

    // MARK: - Properties.
    // Key obtenida de ComicVine, para utilizar el API.
    fileprivate let key = "4ec4716ad8a47d963d9ddf7cc78e75881285286d"
    // Creamos un URLSession, con configuracion por defecto.
    private let session: URLSession = URLSession(configuration: URLSessionConfiguration.default)
    
    
    // MARK: - Public Functions.
    // Las dos siguientes funciones, toman un Resource de solicitud al API, realizan la solicitud (mediante el metodo response, ver mas
    // abajo) y transforman el observable de tipo Response (con .map) en otra secuencia observable de tipo JSONDecodable, controlando
    // los errores de parseo que se puedan producir.
    // El Data recuperado en la solicitud al API dentro del metodo: response, se transforma ya dentro de este a un objeto Response, que 
    // posteriormente en estas funciones, transformamos en un objeto de negocio, es decir, un tipo de dato que conforma el protocolo 
    // JSONDecodable.
    func object<T: JSONDecodable>(_ resource: Resource) -> Observable<T> {

        // Convertimos una secuencia observable de tipo Response en otra secuencia observable cuyo tipo es un JSONDecodable.
        return response(resource).map { response in
            
            // Controlamos que la variable calculada: results de Response, devuelva un posible opcional al decodificar los objetos de
            // negocio como por ejemplo: Volume.
            guard let result = response.result,
                    let object: T = decode(result) else {
                
                throw ComicVineError.couldNotDecodeJSON
            }
            
            return object
        }
    }
    
    func objects<T: JSONDecodable>(_ resource: Resource) -> Observable<[T]> {
        
        // Convertimos una secuencia observable de tipo Response en otra secuencia observable cuyo tipo es un JSONDecodable.
        return response(resource).map { response in
            
            // Controlamos que la variable calculada: results de Response, devuelva un posible opcional al decodificar los objetos de
            // negocio como por ejemplo: Volume.
            guard let results = response.results,
                    let objects: [T] = decode(results) else {
                        
                throw ComicVineError.couldNotDecodeJSON
            }
            
            return objects
        }
    }

    
    // Esta funcion se ocupa de tomar un Resource y realizar la solicitud al API (mediante el metodo data).
    // Es importante comprender, que realizamos una transformacion desde el Data hacia un tipo Response.
    func response(_ resource: Resource) -> Observable<Response> {
        
        // Obtiene el objeto URLRequest, a partir de la baseURL.
        let request = resource.requestWithBaseURL()

        // Que hacemos aqui:
        // Convertimos una secuencia observable de tipo Data en otra secuencia observable cuyo tipo es Response, añadiendola la 
        // logica de errores del servidor, es decir, errores de parseo de JSON y los propios de la API.
        // Para ello, ejecutamos el metodo .data (ver mas abajo), transformando con .map el Data obtenido. con el metodo decode
        // (ver file: JSONDecodable).
        return data(request as URLRequest).map { data in
            
            guard let response: Response = decode(data) else {
                // Un throw dentro de RxSwift, lo que significa es que RxSwift lo captura y lo devuelve como un evento onError 
                // al observer.
                throw ComicVineError.couldNotDecodeJSON
            }
            
            // Preguntamos a la variable calculada que tenemos en Response.
            guard response.succeeded else {
                
                throw ComicVineError.badStatus(status: response.status, message: response.message)
            }

            // Si hemos podido transformar el JSON y este no tiene una respuesta incorrecta, entonces lo devolvemos.
            return response
        }
    }


    // MARK: - Private functions
    // Funcion que toma como parametro URLRequest y devuelve una secuencia observable (RxSwift) de tipo Data.
    private func data(_ request: URLRequest) -> Observable<Data> {
        
        // El metodo .create de Observable, crea un secuencia observable a la que pueden susbcribirse diferentes observers.
        // Cuando un observer se subscribe a este observable, se ejecuta todo el codigo que esta dentro de él, y se empiezan a enviar a 
        // este, eventos next, error o complete.
        // Tambien se devuelve un disposable al observer, que en este caso se ha configurado para cancelar la solicitud al API, si el 
        // observer llama a dispose(). Un disposable, encapsula el concepto de lo que ocurre cuando la subscripcion acaba. En nuestro
        // caso, cuando eso suceda, lo que queremos es que se cancele la peticion. RxSwift nos permite crear un disposable, con un 
        // bloque con lo que queremos que se ejecute cuando la subscripcion se acabe.
        return Observable.create { observer in
 
            // Creamos una tarea y le pasamos un closure con los datos de respuesta del API que esperamos.
            let task = self.session.dataTask(with: request as URLRequest) { data, response, error in
                
                if let error = error {
                    
                    // Si se ha produccido erro, le indicamos a nuestro observer el mismo mediante la generacion de un evento
                    // onError. Despues de este evento, ya no le enviaremos mas.
                    observer.onError(ComicVineError.other(error as NSError))
                
                } else {
                
                    // With a typical web service we should check the HTTP status code, but Comic Vine always returns 200 OK 
                    // and its own status code in the JSON response.
                    
                    // Le entregamos a nuestro observer, el Data de salida. El Data puede tener estar vacio, pero decidimos 
                    // enviarlo vacio (si llegara como nil), para no hacerlo opcional.
                    // Cuando todo ha ido bien, tenemos que mandar dos eventos a nuestro observer:
                    // 1. Evento Next: Enviado el Data.
                    // 2. Evento Completed: Lo mandamos, porque la secuencia observable acaba aqui y ya no le vamos a mandar mas 
                    // eventos.
                    observer.onNext(data ?? Data())
                }
            }
            
            // Una vez creada la tarea, la ponemos en marcha, es decir, realizamos la solicitud al API.
            task.resume()
            
            // Podemos hacer lo siguiente para crear el disposable de salida:
            // 1. return AnonymousDisposable(task.cancel())
            // 2. o esto otro:
            //return AnonymousDisposable {
            return Disposables.create {
                task.cancel()
            }
        }
    }
}


// Extendemos ComicVineSession, para implementamos las peticiones al API de ComicVine.
extension ComicVineSession {
    
    // Implementamos la peticion de volumenes sugeridos para una query.
    // Es importante ver, como le estamos diciendo el tipo de dato (Volume) al metodo objects (para que infiera este tipo)
    // cuando trabaje con los genericos.
    func suggestedVolumes(_ query: String) -> Observable<[Volume]> {
        
        return objects(ComicVine.suggestions(key: key, query: query))
    }
    
    
    // Implementamos la peticion para encontrar volumenes por una query. Vamos a devolver datos en crudo ([JSONDictionary])
    // es decir, sin ningun tipo de negocio, para que estos puedan ser decodificados con la funcion decode que tenemos en 
    // ManagedObjectType y que devuelve un objetos NSManagedObject. De esta manera independizamos el codigo de red (este) 
    // con el de CoreData.
    // Ejecutamos el metodo: response de arriba, que devuelve datos en crudo (Response), es decir, no tipos de negocio.
    // De la respuesta invocamos a map para obtener los JSONDictionary en crudo.
    func searchVolumes(_ query: String, page: UInt) -> Observable<[JSONDictionary]> {
        
        return response(ComicVine.search(key: key, query: query, page: page)).map { response in
        
            // Nos quedamos con los resultados del payload.
            guard let results = response.results else {
                throw ComicVineError.couldNotDecodeJSON
            }
            
            return results
        }
    }
    

    // Implementamos la peticion para los datos de detalle del volumen.
    func volumeDetail(_ identifier: Int) -> Observable<VolumeDetail> {

        // Llamamos a object porque esperamos recibir un solo objeto con los datos del volumen.
        return object(ComicVine.volumeDetail(key: key, identifier: identifier))
    }
    
    
    // Implementamos la peticion para los datos para los issues.
    func volumeIssues(_ identifier: Int) -> Observable<[Issue]> {
        
        // Llamamos a objects porque esperamos recibir varios objetos de tipo Issue.
        return objects(ComicVine.volumeIssues(key: key, identifier: identifier))
    }
}



