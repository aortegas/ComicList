//
//  VolumeDetailViewModel.swift
//  ComicList
//
//  Created by Alberto Ortega on 11/01/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import Foundation
import RxSwift


protocol VolumeDetailViewModelType: class {
    
    // Titulo del boton, hacemos que sea un observable, ya que vamos a cambiar el titulo en funcion de que este incluido o no en nuestra 
    // base de datos y queremos que la UI se entere despues para actualizarse en funcion de ello.
    var buttonTitle: Observable<String> { get }
    
    /// The volume summary
    var summary: VolumeSummary { get }
    
    /// The volume description
    var description: Observable<String> { get }
    
    /// The issues for this volume
    var issues: Observable<[IssueSummary]> { get }
    
    /// Adds or removes the volume
    func addOrRemove()
}


final class VolumeDetailViewModel: VolumeDetailViewModelType {
    
    // MARK: Properties
    // Referencia a nuestro singleton de stack CoreData de gestion de los Volumenes.
    private let store = VolumeListStore.sharedStore

    // Variable de RxSwift para saber si tenemos o no el volumen en la base de datos. Es decir, encapsula una variable de la 
    // que puedes obtener un observable (ver abajo como obtenemos el observable<String> de buttonTitle). Es decir, tengo un 
    // observable cuya secuencia, seran todos los valores posibles que tenga esa variable.
    private let owned: Variable<Bool>
    
    // Referencia a nuestra session, para recuperar los datos de detalle.
    private let session = ComicVineSession()
    
    // Datos de detalle del Volume.
    let summary: VolumeSummary
    
    
    // MARK: Initialization.
    init(summary: VolumeSummary) throws {
    
        // Nos guardamos a un variable propia los datos del Volume.
        self.summary = summary
        
        // Inicializamos nuestra variable owned que almacenara si el volumen lo tenemos o no en la base de datos.
        // Creamos una variable observable. Informamos el valor inicial de la variable, accediendo a CoreData.
        // Accedemos a uno de los metodos que tenemos para ello en VolumeListStore y seteamos la variable con el valor
        // Bool que obtenemos de dicho método.
        self.owned = try Variable(store.containsVolume(summary.identifier))
    }


    // MARK: - VolumeDetailViewModelType Implementation.
    // Ver el funcionamiento del tipo Variable de RxSwift (owned), y como a partir de ella obtenemos el buttonTitle, que ha su vez es un 
    // observable de tipo String. Ver la vista: VolumeDetailHeaderView.swift para ver como se binding a los valores de este observable, desde 
    // el boton de add/remove.
    var buttonTitle: Observable<String> {
        
        // Devolvemos toda la secuencia de valores observables futuros de tipo string que va a tener la variable owned (tipo variable de RxSwift)
        // Mapeamos a un string, que sera el texto del boton, y que dependera del valor de la variable boolean.
        return owned.asObservable().map { $0 ? "Remove" : "Add" }
    }
  
    
    // MARK: - Lógina del Tap button (Add / Remove).
    func addOrRemove() {
        
        do {
            
            // Si owned es true, entonces significa que tenemos el volumen en nuestra base datos y entonces lo borramos.
            if owned.value {
                try store.removeVolume(summary.identifier)
            }
            // Si owned es false, entonces significa lo contrario y entonces añadimos el volumen a la base de datos.
            else {
                try store.addVolume(summary)
            }
            
            // Cambiamos el valor de la propiedad owned. Lo que hara que al cambiar se ejecute el codigo la variable owned y de
            // esta forma se generen los eventos que haran que el titulo del boton (Add / Remove) cambie.
            owned.value = !owned.value
        }
        catch let error {
            print("Error adding or removing volume: \(error)")
        }
    }
    
    
    // Al observable resultante de la peticion que hacemos en el metodo de session (volumeDetail), que es de tipo VolumeDetail, 
    // realizamos una transformación (con .map), para convertirlo en otro observable de tipo String, que será lo vayamos a presentar 
    // en la vista. Si no tenemos conectividad o se devuelven errores en la conversion, devolvemos una cadena vacia.
    // Hacemos que el observable resultante se devuelva en thread principal, ya que los datos son para nuestra view.
    private(set) lazy var description: Observable<String> = self.session.volumeDetail(self.summary.identifier)
        
        // Partimos de que en la petición al API nos llega un tipo VolumeDetail (title + description). Aplicamos map, para quedarnos
        // unicamente con la descripción.
        .map { $0.description }
        
        // Si por lo que fuera hemos encontrado un error, (evento onError()) en la solicitud al API, devolvememos de aqui en adelante
        // una cadena vacia.
        .catchErrorJustReturn("")
        
        // Con startWith, conseguimos enviar antes del primer evento, los items especificados, que tendran que ser del tipo de nuestro
        // observable, en este caso, un String. Con esto conseguimos que cuando se muestre el viewController, no aparezca la info por 
        // defecto del textView (lorem ipsum...).
        .startWith("")

        // Lo que hacemos a partir de aqui, nos aseguramos que corra en el main thread.
        .observeOn(MainScheduler.instance)
        
        // A partir de esta linea, estamos en el thread principal. Vamos a transformar el texto que hemos obtenido de la peticion en HTML, 
        // en texto plano. Para ello, vamos a utilizar una funcion de String, que necesita ejecutarse en el thread principal.
        .map { description in
            
            // 1. Primero necesitamos codificar el HTML en NSData.
            let data = description.data(using: String.Encoding.utf8)
            
            // 2. Creamos un diccionario de opciones de transformación.
            let options: [String: AnyObject] = [
                NSDocumentTypeDocumentAttribute:  NSHTMLTextDocumentType as AnyObject,
                NSCharacterEncodingDocumentAttribute: NSNumber(value: String.Encoding.utf8.rawValue) as AnyObject
            ]
            
            // 3. Creamos el objeto attributedString a partir de las optiones y del Data, para que nos ayudara con la conversion.
            guard let dataDescription = data else {
                
                fatalError("Error mapping description to text plain")
            }
            
            let attributedText = try NSMutableAttributedString(data: dataDescription, options: options, documentAttributes: nil)
                
            // 4. Devolvemos un string plano, a partir el attributedText
            return attributedText.string
        }
        .shareReplay(1)
    
    
    // Al observable resultante de la peticion que hacemos en el metodo de session (volumeIssues), que es de tipo [Issue] (Ver objetos de 
    // negocio), realizamos una transformación (con .map), para convertirlo en otro observable de tipo IssueSummary, que será lo vayamos a 
    // presentar en la vista. Si no tenemos conectividad o se devuelven errores en la conversion, devolvemos una IssueSummary vacio.
    // Hacemos que el observable resultante se devuelva en thread principal, ya que los datos son para nuestra view.
    private(set) lazy var issues: Observable<[IssueSummary]> = self.session.volumeIssues(self.summary.identifier)
        
        // Partimos de que en la petición al API nos llega un tipo Issue (title + imageURL). Aplicamos map, para crear un array de 
        // IssueSummary.
        .map { volumeIssues in
            
            var issueSummarys: [IssueSummary] = []
            
            let issueSummary = volumeIssues.map { issue in
                issueSummarys.append(IssueSummary(title: issue.title, imageURL: issue.imageURL))
            }
            
            return issueSummarys
        }
        
        // Si por lo que fuera hemos encontrado un error, (evento onError()) en la solicitud al API, devolvememos de aqui en adelante
        // un array de IssueSummary vacio.
        .catchErrorJustReturn([IssueSummary]())
        
        // Con startWith, conseguimos enviar antes del primer evento, los items especificados, que tendran que ser del tipo de nuestro
        // observable, en este caso, un [IssueSummary]. Con esto conseguimos que cuando se muestre el viewController, no aparezca la info 
        // por defecto de la lista de Issues.
        .startWith([IssueSummary]())

        // Lo que hacemos a partir de aqui, nos aseguramos que corra en el main thread.
        .observeOn(MainScheduler.instance)
        
        .shareReplay(1)
}
