//
//  SearchResultsViewModel.swift
//  ComicList
//
//  Created by Alberto Ortega on 09/01/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import Foundation
import RxSwift
import CoreData


// Se declara un protocolo, para ser implementado por una clase.
protocol SearchResultsViewModelType: class {
    
    // The search query, o lo que haya seleccionado como sugerencia o lo que tenga escrito en la barra de busqueda cuando
    // se pulsa buscar.
    var query: String { get }
    
    // Esta variable closure sera llamada cuando existan nuevos datos o cambios en los resultados.
    // Aqui vamos a ocultar un FecthResultController, el viewController no sabe que por debajo estamos utilizando CoreData.
    // Tenemos que comunicarle de alguna forma, que los datos han cambiado y que debe un reload de los datos de la tabla.
    // Ese reload, lo vamos a realizar a traves de un bloque, que es lo mas sencillo, es decir, el viewController le dara 
    // la funcionalidad (porque esta pegado a la vista) y desde aqui llamamos a bloque de esta variable para refrescar la
    // vista con nuevos datos.
    var didUpdateResults: () -> () { get set }
    
    // The current number of search results, que lo vamos a necesitar para saber el numero de elementos de la tabla.
    // Esto por debajo lo vamos implementar llamando al fetchResultController, devolviendo el numero de elementos que este tenga.
    var numberOfResults: Int { get }
    
    // Returns the search result at a given position.
    // El SearchResult es el view-model de la celda que queremos renderizar o pintar.
    subscript(position: Int) -> SearchResult { get }
    
    // Returns the volume summary at a given position.
    // Lo utilizaremos para comunicarnos con la pantalla de detalle. El VolumeSumary es el viewModel de detalle.
    subscript(position: Int) -> VolumeSummary { get }
    
    // Fetches the next page of results. Obtiene una nueva pagina de busqueda.
    // Esto permite que cuando llegamos al final de la tabla o scroll, volvamos a recargar la tabla.
    // La funcion devuelve un Observable de tipo Void, porque no devuelve nada, es decir, esta función realizara las solicitudes 
    // al API, obtendra los datos, los insertará en el contexto de escritura y devolvera el evento next(), al que nos subscribiremos
    // desde el viewController, para poner/quitar un activity en las solicitudes.
    func nextPage() -> Observable<Void>
}


// Heredamos de un NSObject porque nos vamos a poner como delegate de un fetchResultController.
// Esto es debido a que el protocolo NSFecthResultControllerProtocol, implica que para ser delegate, debemos heredar de NSObject.
final class SearchResultsViewModel: NSObject {
    
    // MARK: - Properties.
    let query: String
    var didUpdateResults: () -> () = {}
    
    // Propiedades para las solicitudes al API.
    fileprivate let session = ComicVineSession()
    // Nos servira para saber la pagina por la que vamos y que sera por la que vayamos a seguir despues.
    fileprivate var currentPage: UInt = 1
    
    // Propiedades para NSData.
    private let store: ManagedStore // Nos creamos un store propio.
    // Creamos un contexto que se utilizara en un thread privado y que utlizaremos para escribir en la BD, cuando vayan llegando los datos
    // de solicitud al API.
    fileprivate let writeContext: NSManagedObjectContext
    // Creamos un contexto que se utilizara en el main thread y que utilizaremos para leer de la BD, los datos de solicitud al API.
    private let readContext: NSManagedObjectContext
    // Nos ayudara para mostrar los datos recuperados en la vista.
    fileprivate let fetchedResultController: NSFetchedResultsController<NSFetchRequestResult>
    
    // Propiedades para almacenar el la respuesta de subscripcion al notificacion center, que nos servira para comunicar los contextos de 
    // lectura y escritura.
    private var notificacionCenterObserver: NSObjectProtocol!
    
    
    // MARK: - Initialization.
    init(query: String) {
        
        // Query que nos pasan como parametro para el constructor.
        self.query = query
        
        // Configuramos el Stack Core Data.
        // Nos vamos a crear la base de datos en un archivo temporal.
        do {
            self.store = try ManagedStore.temporalyStore()
        }
        catch {
            fatalError("Error creating temporaly Store")
        }
        
        // Creamos un contexto de escritura privado (background) que asignamos al store temporal que hemos creado.
        self.writeContext = store.contextWithConcurrencyTypes(.privateQueueConcurrencyType)
        // Creamos un contexto de lectura (main thread) que asiganamos a nuestro store.
        self.readContext = store.contextWithConcurrencyTypes(.mainQueueConcurrencyType)
        // Creamos un fetchedResultController para obtener datos.
        self.fetchedResultController = NSFetchedResultsController(
            fetchRequest: ManagedVolume.defaultFetchRequest, // NSFetchRequest (Ver protocol: ManagedObjectType), que implementa ManagedVolume
            managedObjectContext: readContext, // Sera el contexto de lectura, ya que sera del que leamos los datos.
            sectionNameKeyPath: nil,
            cacheName: nil)

        // Llamamos al constructor de la superclase.
        super.init()
        
        // A partir de aqui ya podemos usar nuestro fetchedResultController, antes no podriamos ya que no estaba totalmente
        // inicializado nuestro objeto. Es decir, para poder utilizar self, el objeto debe estar construido y esto lo hacemmos 
        // con super. Nos ponemos como delegados del fechedResultController, porque queremos que nos avise de que hay nuevos cambios.
        
        // IMPORTANTE: Entender que un fetchedResultController, sirve para gestionar los datos recibidos desde CoreData y facilitarnos 
        // con ellos alimentar un UITableView.

        // Como funciona el sistema que hemos montado de comunicancion entre los contextos:
        // 1. Obtenemos datos de la peticion.
        // 2. Mediante el sistema de notificaciones (NSNotificationCenter) nos subscribimos a los cambios (save) en el contexto de
        //    escritura (background).
        // 3. En ese momento, se ejecuta el performBlock de la notificacion para actualizar los datos en el contexto de lectura. 
        //    En este momento, los cambios permanecen en la ram de ambos contextos. Utilizamos performBlock (sincrono) en este sentido, 
        //    porque al realizarse la lectura en el main thread, nos aseguramos de ello con su funcionamiento sincrono. En el objeto notificacion,
        //    estan todos los objetos del contexto privado (background), que han cambiado.
        // 4. Cuando los datos se han actualizado en el contexto de lectura, el NSFetchedResultController nos avisa mediante el delegado y 
        //    ejecutamos el metodo didUpdateResults, para indicar al viewcontroller que actualice la tabla y se vean los nuevos datos.
        
        // Nos hacemos delegados de los cambios del fechtResultController.
        fetchedResultController.delegate = self
        
        // Para que funcione, es necesario que el fetchedResultController, haga un fetch inicial de los datos, aunque no haya datos en el mismo. 
        // De esta manera, ya estamos conectados a los eventos de nuevos cambios que se produzcan en CoreData.
        do {
            try fetchedResultController.performFetch()
        }
        catch {
            fatalError("Error in first fetch in SearchResultViewModel")
        }

        // Obtenemos una refencia al notification center.
        let nc = NotificationCenter.default
        
        // Nos suscribimos al notification center. Hay dos maneras, de indicar que queremos hacer cuando se reciba la notificación, una indicando 
        // un metodo y otra indicando un bloque, lo hacemos con esta ultima.
        self.notificacionCenterObserver = nc.addObserver(
            
            // Esta es la notificacion de salvado de datos en el contexto de escritura (background).
            forName: NSNotification.Name.NSManagedObjectContextDidSave,
            // Importante: Indicamos el contexto al que nos queremos subscribir en las notificaciones, para no recibir todas las notificaciones.
            object: writeContext,
            // Nos permite indicarle con este bloque lo que ha de realizarse cuando se reciba la notificación.
            queue: nil) { [unowned readContext] notification in
            
                // En este punto, acabamos de recibir la notificación de que se acaban de guardar los datos en el contexto de escritura en 
                // background. Lo siguiente que haremos sera trabajar de manera sincrona, ya que vamos a utilizar el contexto de lectura, que
                // se leera en el main thread.
                // Le indicamos al contexto de lectura con perform (modo asincrono) no performAndWait (modo sincrono), que queremos que
                // se actualicen los datos guardados en el contexto de escritura, al contexto de lectura, con mergeChange. En este momento, 
                // tenemos los cambios en la ram de ambos contextos.
                readContext.perform {
                
                    readContext.mergeChanges(fromContextDidSave: notification)
                }
        }
    }
    
    // Destructor
    deinit {
        
        // Nos des-subscribimos de las notificaciones.
        NotificationCenter.default.removeObserver(notificacionCenterObserver)
    }

    
    // MARK: - Private
    fileprivate subscript(position: Int) -> ManagedVolume {
        
        // El assert solo sirve en modo depuracion (debug) para indicar las situaciones incontroladas que se deben asegurar y asi poder localizarlas.
        assert(position < numberOfResults, "Position out of range")
        
        // Creamos un indexPath. Al no tener secciones, nuestra seccion es la 0. Si tuvieramos seccion el subscript recibiria dos parametros.
        let indexPath = IndexPath(row: position, section: 0)
        
        // Obtenemos el objeto managedObject y lo intentamos castear a un ManagedVolume
        guard let volume = fetchedResultController.object(at: indexPath) as? ManagedVolume else {

            // No controlamos errores, si vamos por un objeto y no lo encontramos, no es culpa del usuario.
            fatalError("Couldn't get volume at position \(position)")
        }
        
        return volume
    }
}


extension SearchResultsViewModel: SearchResultsViewModelType {

    // Implementamos el protocolo SearchResultsViewModelType definido arriba. Este protocolo contiene datos asociados a la vista de la tabla.
    // Gracias a nuestro fetchedResultController que esta pegado a nuestro contexto de lectura, gestionamos los datos a mostrar en la lista.
    var numberOfResults: Int {
        
        // El fetchedResultController tiene secciones y dentro de cada una de las secciones tiene objetos. En nuestro caso, solo tenemos una 
        // seccion. Como no queremos devolver un opcional (nil), si no tenemos datos, devolvemos 0.
        return fetchedResultController.sections?.first?.numberOfObjects ?? 0
    }

    
    // En este metodo queremos mapear un ManagedVolume en un SearchResult.
    subscript(position: Int) -> SearchResult {
        
        // Vamos a convertir el indice en un indexPath, que es lo que maneja el fetchResultController para recuperar el objeto que queremos.
        // El fetchResultController nos va a devolver un ManagedObject que tenemos que convertir en un ManagedVolume.
        // Como esto es comun a este subscript y al siguiente, pasamos toda esta conversion a un metodo privado de nuestra clase.
        // Utilizamos el subscript privado, que nos obliga a indicar el tipo de retorno.
        let volume: ManagedVolume = self[position]
        
        // Ahora necesitamos construir nuestro view-model SearchResult.
        // SearchResult es un struct (ver en esta carpeta) con (imageURL, title, y publisherName).
        // Lo creamos a partir del ManagedVolume.
        return SearchResult(imageURL: volume.imageURL, title: volume.title, publisherName: volume.publisher)
    }

    
    // En este metodo queremos mapear un ManagedVolume en un VolumeSummary.
    subscript(position: Int) -> VolumeSummary {

        // Vamos a convertir el indice en un indexPath, que es lo que maneja el fetchResultController para recuperar el objeto que queremos.
        // El fetchResultController nos va a devolver un ManagedObject que tenemos que convertir en un ManagedVolume.
        // Como esto es comun a este subscript y al siguiente, pasamos toda esta conversion a un metodo privado de nuestra clase.
        // Utilizamos el subscript privado, que nos obliga a indicar el tipo de retorno.
        let volume: ManagedVolume = self[position]

        // Ahora necesitamos construir nuestro view-model VolumeSummary.
        // VolumeSumary es un struct (ver en la carpeta Details) con (identifier, imageURL, title, y publisherName).
        // Lo creamos a partir del ManagedVolume.
        return VolumeSummary(identifier: volume.identifier, title: volume.title, imageURL: volume.imageURL, publisherName: volume.publisher)
    }
    

    // Este metodo cogera el valor del currentPage y hara la siguiente solicitud de datos al API. Pasaremos la pagina sobre la que queremos rellenar
    // los datos. Devolvemos un observable<void> (o nada) que devolvemos como un evento next(). Es decir, es como cualquier otro evento que podamos 
    // devolver, pero este, sin informacion, por ejemplo, como cuando se produce el tap en un boton.
    func nextPage() -> Observable<Void> {
        
        // Realizamos la solicitud de nuevos volumenes.
        return session.searchVolumes(query, page: currentPage)

            // Necesitamos realizar mapeo de los datos obtenidos en la peticion a objetos ManagedVolume.
            // En realidad no estamos haciendo un .map, estamos haciendo un .map para insertar un efecto colateral. El efecto colateral que
            // queremos que ocurra cuando recibimos los diccionarios, es que se guarden en base de datos, es decir, el uso mas comun de .map 
            // seria para transformar los JSON en ManagedVolume que devolvieramos, pero no es asi en nuestro caso, necesitamos cambiaentonces, para 
            // insertar efectos colaterales en un observable, hay un metodo que se llama "do" que nos permite realizar eso.

            // Es decir, podriamos haber hecho...
            /*
            .map { dictionaries in
             
                // Obtenemos el array de ManagedVolume, mapeando con la funcion decode que definimos en ManagedObjectType.
                let _: [ManagedVolume] = decode(dictionaries, insertIntoContext: contextWrite)
               
                // Hacemos el save, pero para ello, debemos asegurarnos de que lo hacemos en la cola privada del contexto (ver un poco mas de
                // explicación mas abajo).
            }
            */
        
            // Lo realizamos con "do", "do" se llamara por cada evento next() que se produzca en el observable. En nuestro caso, solo habra 
            // un next() y luego un complete() para cada solicitud. El bloque es lo que se ejecutara con los datos que traiga el evento next.
            .do(onNext: { [unowned writeContext] dictionaries in
                
                // Con la funcion decode que se encuentra en ManagedObjectType.swift, realizamos en modo sincrono la transformación de los
                // datos recuperados en la solicitud en objectos ManagedVolume. No guardamos el array de ManagedVolume en ninguna variable,
                // ya que tenemos ya insertados los mismos en el contexto de escritura. Lo unico que ahora nos falta es realizar un save,
                // para que al guardarse los datos en el contexto.
                let _: [ManagedVolume] = decode(dictionaries, insertIntoContext: writeContext)
                
                // Hacemos el save, pero para ello, debemos asegurarnos de que lo hacemos en la cola privada del contexto pero en modo 
                // sincrono, por eso hacemos todo este proceso, con el operador: do y no con map. Tambien sumamos 1 al numero de paginas.
                writeContext.performAndWait() {
                    do {
                        try writeContext.save()
                        self.currentPage += 1
                    }
                    catch {
                        // Si el salvado da error, realizamos rollback de todos los cambios realizados hasta el ultimo commit.
                        print("Couln't save search result")
                        writeContext.rollback()
                    }
                }
            })
        
            // Hacemos un .map para convertir nuestros datos en nada, para que el observable que vamos a devolver, no tenga nada.
            // Con esto, estamos conformando al tipo del observable que devolvemos.
            .map { _ in
                ()  // Esto es void
            }
        
            // Y por ultimo, notificamos en el main thread que acabamos de hacer save de los datos, para que se produzcan las notificaciones.
            .observeOn(MainScheduler.instance)
        
            // Y como no queremos hacer n peticiones, en caso de tener n observables, compartimos el buffer entre ellos.
            .shareReplay(1)
    }
}


extension SearchResultsViewModel: NSFetchedResultsControllerDelegate {
    
    // Implemetamos el protocologo delegado del FetchedResultsControllerDelegate.
    // Este metodo es el que nos interesa, porque en la tabla vamos a realizar un reload data de los datos que han cambiado.
    // El reload data, recarga solo aquellas celdas visibles, no toda la tabla.
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        // Llamamos al metodo de la variable didUpdateResults(), para indicar que se acaban de producir cambios en el contexto de escritura.
        didUpdateResults()
    }
}










