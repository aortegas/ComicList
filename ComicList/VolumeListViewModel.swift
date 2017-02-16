//
//  VolumeListViewModel.swift
//  ComicList
//
//  Created by Alberto Ortega on 31/12/15.
//  Copyright © 2015 Alberto Ortega. All rights reserved.
//

import Foundation
import CoreData


// Definimos un protocolo para un VolumeListViewModel
protocol VolumeListViewModelType: class {
    
    // Variable calculada (set y get) que se llama cuando un comic es add o remove.
    var didUpdateList: () -> () { get set }

    // Variable calculada para obtener el numero de volumenes en lista.
    var numberOfVolumes: Int { get }
    
    // Subscript para poder obtener un VolumeListItem.
    subscript(position: Int) -> VolumeListItem { get }

    // Subscript para poder obtener un VolumeSummary.
    subscript(position: Int) -> VolumeSummary { get }
}


// Para poder ser de delegados de NSFetchedResultsControllerDelegate, necesitamos heredad de NSObject, ya que NSFetchedResultsControllerDelegate
// nos pide que sus delegados implementen el protocolo: NSObjectProtocol.
final class VolumeListViewModel: NSObject {

    // MARK: - Properties
    // Inicializamos con una implementacion vacia a la variable calculada (set), de actualizacion de la lista en funcion de cuando add o remove
    // volumenes.
    var didUpdateList: () -> () = {}
    
    // Definimos una variable para apuntar a nuestro singleton Store.
    private let store = VolumeListStore.sharedStore
    
    // Definimos un NSFetchedResultController para mostrar los volumenes de CoreData en la vista.
    // Creamos un NSFetchedResultsController de tipo NSFetchRequestResult.
    fileprivate let fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>

     
    // MARK: - Initializacion.
    override init() {

        // Configuramos el NSFetchedResultController.
        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: ManagedVolume.defaultFetchRequest, // NSFetchRequest (Ver protocol: ManagedObjectType), que implementa ManagedVolume
            managedObjectContext: store.context, // Le asignamos nuestro contexto que hemos creado en VolumeListStore
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        // Invocamos a super.init, para asegurar que tenemos creado el objeto.
        super.init()
        
        // Nos hacemos delegados del NSFetchedResultController.
        fetchedResultsController.delegate = self
        
        // Para que funcione, es necesario que el fetchedResultController, haga un fetch inicial de los datos, aunque no haya datos en el mismo. 
        // De esta manera, ya estamos conectados a los eventos de nuevos cambios que se produzcan en Core Data.
        do {
            try fetchedResultsController.performFetch()
        }
        catch {
            fatalError("Error in first fetch in VolumeListViewModel")
        }
    }

    
    // MARK: - Private Funcs
    // Metodo privado que es llamado desde los subscripts para devolver un ManagedVolumen para una posicion dada.
    fileprivate subscript(position: Int) -> ManagedVolume {
        
        assert(position < numberOfVolumes, "Position out of range")
        
        let indexPath = IndexPath(item: position, section: 0)
        
        guard let volume = fetchedResultsController.object(at: indexPath) as? ManagedVolume else {
        
            fatalError("Couldn't get volume at position \(position)")
        }
        
        return volume
    }
}


// Conformamos los metodos delegados de NSFetchedResultsControllerDelegate.
extension VolumeListViewModel: NSFetchedResultsControllerDelegate {

    // Cada vez que haya cambios en el contexto de CoreData, actualizamos la lista.
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        // Ver como en el viewController hemos asociado el codigo para recargar la lista con la variable bloque didUpdateList.
        // Al hacer el reload de las collection, esto hara que se ejecuten los metodos delegados que piden los datos, y entonces 
        // pasen a ejecutarse los subscripts y variables calculadas (get) aqui definidas.
        didUpdateList()
    }
}


// Conformamos el protocolo: VolumeListViewModelType.
extension VolumeListViewModel: VolumeListViewModelType {

    // Obtemos el numero de objetos resultantes del NSFetchResultController, y sino devolvemos 0.
    var numberOfVolumes: Int {
        
        return fetchedResultsController.sections?.first?.numberOfObjects ?? 0
    }
    
    
    // Implementamos el metodo, para devolver el titulo y la imagen de un volumen, en una posicion dada.
    subscript(position: Int) -> VolumeListItem {
        
        // Llamamos al subscript privado para obtener un ManagedVolume, de una posicion concreta.
        let volume: ManagedVolume = self[position]
        return VolumeListItem(imageURL: volume.imageURL, title: volume.title)
    }
    
    
    // Implementamos el metodo, para devolver el id, titulo, imagen y publisherName de un volumen, en una posicion dada.
    subscript(position: Int) -> VolumeSummary {

        // Llamamos al subscript privado para obtener un ManagedVolume, de una posicion concreta.
        let volume: ManagedVolume = self[position]
        return VolumeSummary(identifier: volume.identifier, title:  volume.title, imageURL:  volume.imageURL, publisherName: volume.publisher)
    }
}






