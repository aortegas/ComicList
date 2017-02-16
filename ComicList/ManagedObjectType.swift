//
//  ManagedObjectType.swift
//  ComicList
//
//  Created by Alberto Ortega on 6/6/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import Foundation
import CoreData


// Basicamente en este fichero realizamos dos protocolos que deberian cumplir todas las subclases de NSManagedObject en nuestra app.
// Uno de ellos, contempla varias variables de clase con datos sobre la entidad. El otro contiene una funcion que deberia saber como 
// alimentar todos los atributos de la entidad subclase de NSManagedObject a partir de los datos de un JSONDictionary.


// Definimos un protocolo que deberia conformar cualquier subclase de NSManagedObject en nuestra app.
protocol ManagedObjectType {
    
    // Variable de clase para devolver el nombre de la entidad (get).
    static var entityName: String { get }
    // Variable de clase para devolver los criterios de ordenacion (get).
    static var defaultSortDescriptors: [NSSortDescriptor] { get }
    // Variable de clase para devolver un NSFetchRequest de tipo NSFetchRequestResult (get).
    // Esta se completa con las dos anteriores.
    static var defaultFetchRequest: NSFetchRequest<NSFetchRequestResult> { get }
}


// Realizamos una implementacion por defecto del protocolo ManagedObjectType.
extension ManagedObjectType {
    
    // Implementamos la variable calculada defaultFetchRequest
    static var defaultFetchRequest: NSFetchRequest<NSFetchRequestResult> {
        
        // Creamos un NSFetchRequest, para una entidad dada que nos venga.
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        // Para ese NSFetchRequest, creamos asignamos el sort descriptor que tenemos.
        fetchRequest.sortDescriptors = defaultSortDescriptors
        // Devolvemos el fetchRequest.
        return fetchRequest
    }
}


// Definimos un protocolo que tambien deberian conformar todas las subclases de NSManagedObject en nuestra app.
protocol ManagedJSONDecodable {
    
    func updateWithJSONDictionary(_ dictionary: JSONDictionary) throws
}


// Esta funcion generica devuelve una array de objetos NSManagedObject o subclases de esta, para un array de JSONDictionary
// de entrada, insertando estos como registros en el contexto que se especifique como parametro de entrada.
// La subclase de NSManagedObject, debe conformar los protocolos: ManagedObjectType y ManagedJSONDecodable.
// Esta funcion sera llamada una vez por cada pagina (20 registros). Devolvera 20 registros.
func decode<T: NSManagedObject>(_ dictionaries: [JSONDictionary], insertIntoContext context: NSManagedObjectContext) -> [T]
    where T: ManagedObjectType, T: ManagedJSONDecodable {
        
        // Declaramos e inicializamos un array de objectos genericos.
        var objects: [T] = []
        
        // performAndWait (sincrona), permite que le digamos al contexto lo que debe hacer en el siguiente bloque y él, en base a su
        // definicion, ejecutara este bloque en la cola (principal o privada) que le hayamos dicho.
        context.performAndWait {
            
            // Mapeamos el array que recibimos como parametro de entrada de JSONDictinary, creando objetos que heredan de NSManagedObject y
            // que conformaran los protocolos: ManagedObjectType y ManagedJSONDecodable.
            objects = dictionaries.map { dictionary in
                
                // Esto devuelve un NSManagedObject insertado en el contexto que tenemos como parametro de entrada. Y posteriormente lo que
                // hacemos es hacerle un down casting para sea un tipo T, es decir, una subclase de NSManagedObject, que conforme los protocolos:
                // ManagedObjectType y ManagedJSONDecodable.
                // Lo que aqui estamos forzando es a que la subclase de NSManagedObject, conforme obligatoriamente estos protocolos, sino
                // queremos que devuelva error.
                guard let object = NSEntityDescription.insertNewObject(forEntityName: T.entityName, into: context) as? T else {
                    
                    fatalError("Error inserting [JSONDictionary]")
                }
                
                // El proceso de insercion, funciona en dos partes:
                // 1. Inserta un nuevo objecto en el contexto que le indicamos. Esto devuelve el NSManagedObject que casteamos a T. (Lo anterior).
                // 2. Una vez construido (lo que tenemos dentro del objeto T, es el insertionDate), en este segundo paso, rellenamos el resto de
                // atributos.
                do {
                    
                    try object.updateWithJSONDictionary(dictionary)
                }
                catch {
                    
                    fatalError("Error during update with JSONDictionary")
                }
                
                return object
            }
        }
        
        return objects
}

