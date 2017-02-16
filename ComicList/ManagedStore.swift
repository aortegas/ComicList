//
//  ManagedStore.swift
//  ComicList
//
//  Created by Alberto Ortega on 3/6/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import Foundation
import CoreData


// Clase para la contruccion de un stack de CoreData.
final class ManagedStore {
    
    
    // MARK: - Properties.
    // Propiedad para hacer referencia a la capa intermedia (Persistent Store Coordinator).
    private let persistentStoreCoordinator: NSPersistentStoreCoordinator

    // Variable calculada para obtener la Url fisica de donde esta base de datos. Es opcional, porque puede ser que este memoria.
    // Seria la capa de mas bajo nivel y que gestiona el Persistent Store Coordinator.
    // Tendremos unicamente una base datos (first?). (A diferencia de las app como bento que se dedican a la creacion de estas).
    // Obtenemos la url, tambien a partir del persistentStoreCoordinator. (cogemos la primera base de datos)
    private var URL: URL? {
        
        return persistentStoreCoordinator.persistentStores.first?.url
    }

    // Propiedad calculada para obtener una referencia a la capa superior (model).
    // Lo hacemos a partir del Persistent Store Coordinator que abamos de crear.
    private var model: NSManagedObjectModel {
        
        return persistentStoreCoordinator.managedObjectModel
    }
    
    
    // MARK: - Initialization
    // Nuestro constructor puede lanzar excepciones.
    // El objetivo de este init, sera crear el Persistent Store Coordinator, asignarle el modelo (capa superior) que nos pasen o el 
    // merge de todos, asi como tambien definir y asignarle la definicion de la capa fisica donde se almacenara la base de datos.
    // Recibe varios parametros para las propiedades definidas. Si no nos pasan el modelo, fusionamos todos los modelos del que 
    // encuentre en el bundle, para tenerlos todos juntos.
    init(URL: URL?, model: NSManagedObjectModel = NSManagedObjectModel.mergedModel(from: nil)!) throws {
        
        // Lo primero de todo sera llamar a nuestro Persistent Store Coordinator, para asignarle el modelo que nos llege como parametro.
        self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        // Si tenemos URL entonces creamos un store de tipo SQLite, sino lo crearemos en memoria.
        let type = (URL != nil) ? NSSQLiteStoreType : NSInMemoryStoreType
        
        // Creamos un diccionario con las opciones de creacion de la capa baja (Store) del Persistent Store Coordinator (para migrar, etc.)
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        
        // Por ultimo, añadimos el persistent store (conexion con la base de datos fisica o memoria) a nuestro stack y esto puede fallar.
        try self.persistentStoreCoordinator.addPersistentStore(ofType: type, configurationName: nil, at: URL, options: options)
    }

    // Se define un nuevo constructor de conveniencia, para crear una base de datos a partir del nombre de un documento, que creara una url
    // para el mismo que se la pasaremos al constructor designado anterior.
    // Recibe varios parametros para las propiedades definidas. Si no nos pasan el modelo, fusionamos todos los modelos del que
    // encuentre en el bundle, para tenerlos todos juntos.
    convenience init(documentName: String, model: NSManagedObjectModel = NSManagedObjectModel.mergedModel(from: nil)!) throws {
        
        // Obtenemos una URL al documento que nos pasan dentro del directorio documents.
        let documentURL = Foundation.URL.documentDirectoryURL.appendingPathComponent(documentName)
        
        // Llamamos al constructor designado.
        try self.init(URL: documentURL, model: model)
    }
    
    
    // MARK: - Public functions.
    // Metodo de clase para que nos devuelva una base de datos temporal en el directorio temporal.
    static func temporalyStore() throws -> ManagedStore {
        
        // Llamamos a nuestro constructor de conveniencia para pasarle un fichero temporal (directorio temporal del Sandbox)
        return try ManagedStore(URL: Foundation.URL.temporalyFileURL())
    }
    
    
    // Funcion para crear un contexto a partir de un NSManagedObjectContextConcurrencyType, que define la cola (main u otra) en la que se
    // creara el contexto. Hay que tener en cuenta que un contexto solo puede ser usado en la cola (thread) en la que se creo.
    func contextWithConcurrencyTypes(_ type: NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
       
        // Creamos un contexto.
        let context = NSManagedObjectContext(concurrencyType: type)
        // Al nuevo contexto le asociamos nuestro Persistent Store Coordinator.
        context.persistentStoreCoordinator = persistentStoreCoordinator
        // Devolvemos el nuevo contexto creado.
        return context
    }
}









