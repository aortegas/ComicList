//
//  VolumeListStore.swift
//  ComicList
//
//  Created by Alberto Ortega on 13/6/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import Foundation
import CoreData


// Esta clase Singleton nos permitira tener un nuevo stack de CoreData para la lista de comics guardados (que solo sera una).
final class VolumeListStore {
    
    // MARK: - Properties.
    // Propiedad publica para tener acceso al Singleton que sera esta clase.
    // Importante: Es un Singleton, porque no tiene sentido tener mas de dos bases de datos de comics guardados.
    static let sharedStore = VolumeListStore(documentName: "My Comics")
    
    // Definimos una variable para nuestro stack de CoreData.
    private let managedStore: ManagedStore
    
    // Variable para tener un contexto.
    let context: NSManagedObjectContext

    
    // MARK: - Initialization.
    // Constructor privado porque vamos a implementar un singleton con esta clase. 
    private init(documentName: String) {
        
        // Construimos el contexto en el directorio de documentos, no temporal, porque aqui si que queremos guardar nuestros comics.
        // El otro stack que definimos en la aplicacion, lo definimos en el directorio temporal, porque realmente lo tenemos para
        // optimizar el trabajo con la descarga y mostrar los volumenes que vamos descargando.
        do {
            self.managedStore = try ManagedStore(documentName: documentName)
        }
        catch {
            fatalError("Error creating ManageStore in VolumeListStore")
        }
            
        // Utilizamos el tipo de concurrencia del main thread, porque vamos a escribir y leer de el, en el thread principal.
        self.context = managedStore.contextWithConcurrencyTypes(.mainQueueConcurrencyType)
    }
    
    
    // MARK: - Methods for use data base.
    // Metodo para saber si tenemos guardado o no un volumen. 
    func containsVolume(_ identifier: Int) throws -> Bool {
        
        // Contamos el numero de volumenes que tenemos con el criterio de busqueda de un unico volumen y que hemos definido en 
        // en ManagedVolumen.
        let fetchRequest = ManagedVolume.fetchRequestForVolume(identifier)
        
        // Obtenemos el numero de Volumenes encontrados.
        let count = try context.count(for: fetchRequest)
        
        // Devolmemos true/false en funcion de si hemos encontrado o no objetos.
        return (count != NSNotFound) && (count > 0)
    }
    
    
    // Metodo para eliminar un volumen que hayamos guardado en el contexto.
    func removeVolume(_ identifier: Int) throws {

        // Recuperamos el volumen que cumpla el criterio de busqueda de un unico volumen y que hemos definido en ManagedVolumen.
        let fetchRequest = ManagedVolume.fetchRequestForVolume(identifier)
        
        // Indicamos al contexto que queremos recuperar el Volume que queremos eliminar. En realidad realidad nos preparamos para 
        // recuperar un array de ManagedVolumes, con un solo elemento.
        guard let volumes = try context.fetch(fetchRequest) as? [ManagedVolume] else {
            
            fatalError("Error during casting to [ManagedVolume]")
        }
        
        // Si hemos recuperado el volumen (array con mas de 0 objetos), lo borramos.
        if volumes.count > 0 {
            
            // Borramos el Volumen del contexto.
            context.delete(volumes[0])
            
            // Salvamos el contexto.
            try context.save()
        }
    }
    
    
    // Metodo para añadir un Volumen que hayamos decidido guardar desde la pagina de detalle.
    // Los datos que necesitamos, estan todos en el volumeSumary, que es la estructura de datos con la que trabajamos en la 
    // pantalla de detalle.
    func addVolume(_ summary: VolumeSummary) throws {
        
        // Vamos a insertar el objeto, con un Volumen vacio (excepto por la fecha de insercion que si estara informada).
        guard let volume = NSEntityDescription.insertNewObject(forEntityName: ManagedVolume.entityName, into: context) as? ManagedVolume else {
            
            fatalError("Error during casting to ManagedVolume")
        }
        
        // Ahora informamos el resto de datos del Volumen.
        volume.identifier = summary.identifier
        volume.title = summary.title
        volume.publisher = summary.publisherName
        volume.imageURL = summary.imageURL
        
        // Por ultimo guardamos el Volumen en el contexto.
        try context.save()
    }
}


