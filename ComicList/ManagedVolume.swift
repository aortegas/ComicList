//
//  ManagedVolume.swift
//  ComicList
//
//  Created by Alberto on 6/6/16.
//  Copyright © 2016 Guillermo Gonzalez. All rights reserved.
//

import CoreData


// Clase para representar los volumenes (comics) de la entidad: Volume (ver: ComicList.xcdatamodeld
final class ManagedVolume: NSManagedObject {
    
    // MARK: - Properties
    // Definimos una propiedad para cada atributo de la base de datos. Definimos si son o no opcionales.
    @NSManaged var title: String
    @NSManaged var identifier: Int
    @NSManaged var publisher: String?
    
    // Por comodidad, queremos tener una propiedad URL en formato String, que sera privada.
    // Mediante una variable calculada publica de tipo URL accederemos a la privada, mediante sus metodos
    // get y set.
    @NSManaged fileprivate var imageURLString: String?
    var imageURL: URL? {
        
        get {
            return (imageURLString != nil) ? URL(string: imageURLString!) : nil
        }
        set {
            // newValue es el nuevo valor que nos llega.
            imageURLString = newValue?.absoluteString
        }
    }
     
    // Queremos que la fecha de insercion se rellene automaticamente, cuando se inserta un registro.
    // Por eso la hacemos como privada de insercion (set), para que desde fuera no se pueda manipular.
    // Fijarse en el metodo awakeFromInsert.
    @NSManaged private(set) var insertionDate: Date
 
    override func awakeFromInsert() {
        
        super.awakeFromInsert()
        insertionDate = Date() // Pone la fecha actual.
    }
}


// Extension para implementar el protocolo ManagedObjectType.
// Basicamente debemos dar implementacion a las variables entityName y defaultSortDescriptors.
extension ManagedVolume: ManagedObjectType {
    
    static var entityName: String {
        
        // Nuestra entidad se llama "Volume"
        return "Volume"
    }
    
    static var defaultSortDescriptors: [NSSortDescriptor] {
        
        // Definimos un sortDescriptor para ordenar los Volume por orden de insercion, desde el mas antiguo al mas nuevo
        // en llegar, que sera como se mostraran en la vista. Indicamos el nombre del atributo (key) y la ordenacion.
        return [NSSortDescriptor(key: "insertionDate", ascending: true)]
    }
}


// Extension para implementar el protocolo ManagedJSONDecodable.
// Debemos implementar la funcion que informa o completa nuestra entidad Volume, a partir de un JSONDictionay.
extension ManagedVolume: ManagedJSONDecodable {
    
    // No hemos definido que devolvemos error en esta funcion, pero si algun dato que necesitamos no viniera, deberiamos hacerlo.
    func updateWithJSONDictionary(_ dictionary: JSONDictionary) throws {
        
        // Si los datos obligatorios de la entidad no vinieran informados, lanzamos una excepcion.
        guard let identifier = dictionary["id"] as? Int,
                let title = dictionary["name"] as? String else {
                    
            throw NSError(domain: "JSONDictonary without id or name", code: 0, userInfo: nil)
        }
        
        // Informamos el id y el titulo.
        self.identifier = identifier
        self.title = title
        
        // Convertimos el diccionario Swift, en un diccionario Objetive-C para poder utilizar el metodo: valueForKeyPath, porque 
        // a este metodo le podemos indicar cosas del tipo xxxxx.xxxxx como clave. (ver el punto)
        self.publisher = (dictionary as NSDictionary).value(forKeyPath: "publisher.name") as? String
        self.imageURLString = (dictionary as NSDictionary).value(forKeyPath: "image.small_url") as? String
    }
}


// Agreagamos una extension de ManagedVolume para recuperar un fetchRequest con un volumen localizado por su identificador (where).
extension ManagedVolume {
    
    // Incluimos esta funcion de clase para obtener un Volume por su identificador.
    static func fetchRequestForVolume(_ identifier: Int) -> NSFetchRequest<NSFetchRequestResult> {
        
        // Preparamos la query con un predicate. (where)
        let predicate = NSPredicate(format: "identifier==%d", identifier)
        
        // Creamos el NSFetchRequest que vamos a devolver. Le pasamos nuestra propia variable entityName, que tenemos al implementar 
        // el protocolo: ManagedVolume.
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        
        // Asignamos al fetchRequest, el predicado que hemos creado.
        fetchRequest.predicate = predicate
        
        // Nos aseguramos de que nos devuelva un unico objeto.
        fetchRequest.fetchLimit = 1
        
        return fetchRequest
    }
}



