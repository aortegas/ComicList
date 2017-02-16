//
//  SearchSuggestionsViewController.swift
//  ComicList
//
//  Created by Alberto Ortega on 08/01/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


// Creamos un protocolo con la accion de seleccionar una de las sugerencias mostradas. Este protocolo se implementa en el 
// VolumeListWireFrame y consiste en mostrar el SearchResultViewController. Esta funcion se llama en este viewController cuando
// se selecciona una de las sugerencias.
protocol SearchSuggestionsViewControllerDelegate: class {

    func searchSuggestionsViewController(_ viewController: SearchSuggestionsViewController, didSelectSuggestion suggestion: String)
}


// Este view controller es una subclase de UITableViewController, para mostrar una lista de las sugerencias encontradas para la
// busqueda solicitada por el usuario.
final class SearchSuggestionsViewController: UITableViewController {

    // MARK: - Properties
    // Guardamos una referencia de delegado para el que conforme el protocolo, que en este caso sera el VolumeListWireframe.
    weak var delegate: SearchSuggestionsViewControllerDelegate?
    
    // Constante para nuestro viewModel
    fileprivate let viewModel: SearchSuggestionsViewModelType
    
    // Constante para almacenar todas las referencias que guardamos como observadores, de tal manera que cuando nos vayamos de 
    // memoria, se vayan tambien los observers a los que nos hemos subscrito.
    private let disposeBag = DisposeBag()
    
    
    // MARK: - Initialization.
    // Creamos por defecto, nuestro propio viewModel, por si no nos lo pasan.
    init(viewModel: SearchSuggestionsViewModelType = SearchSuggestionsViewModel()) {
        
        // Guardamos la referencia a nuestro viewModel.
        self.viewModel = viewModel
        super.init(style: .plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    // MARK: - Lifecycle.
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setupView()
        setupBindings()
    }
    
    
    // MARK: - Metodos UITableViewDelegate.
    // Especificamos con este metodo de UITableViewDelegate, como queremos que se dibujen las celdas.
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    
        // En este caso, dejamos sin color el fondo de las celdas.
        cell.backgroundColor = UIColor.clear
    }

    
    // MARK: - Private methods.
    private func setupView() {
        
        // Cambiamos el backgroundColor de la tableView.
        tableView.backgroundColor = UIColor(named: .background).withAlphaComponent(0.3)
        
        // Creamos un efecto blur effect y una vista con dicho efecto y la colocamos como backgroundView de la tableView.
        let effect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: effect)
        tableView.backgroundView = blurView
        tableView.separatorEffect = UIVibrancyEffect(blurEffect: effect)

        // Registramos el tipo de celda que vamos a utilizar en la lista.
        tableView.register(UITableViewCell.self)
    }

    
    private func setupBindings() {
        
        // Aunque seamos un UITableViewController, no necesitamos implementar los metodos de UITableViewDelegate, ni tampoco de
        // UITableViewDataSource, porque todo esto lo haremos mediante RxCocoa.
        tableView.dataSource = nil
        
        // Nos hacemos observers de la Variable Rx suggestions del nuestro viewModel, que nos ira dando mediante eventos next()
        // las sugerencias encontradas para las busquedas solicitadas.
        viewModel.suggestions
            
            // Utilizamos RxCocoa para hacer binding a los elementos de una tableView. Es decir, por cada evento next() que nos 
            // llegue de suggestions, con todas las sugerencias, informaremos dichas sugerencias a la tableView, a traves de 
            // este bindTo, para que vaya creando celdas para la misma.
            .bindTo(tableView.rx.items) { (tableView, index, suggestion) in

                // Obtenemos una cell, informamos su contenido y la devolvemos.
                let cell: UITableViewCell = tableView.dequeueReusableCell()
                cell.textLabel?.text = suggestion
                return cell
            }
            // Como observers, guardamos la referenica sobre el observable.
            .addDisposableTo(disposeBag)

        // Nos hacemos observers de la tableView a traves de RxCocoa, para que nos lleguen como eventos onNext, las selecciones de
        // sugerencias y podamos mostrar resultados para las mismas.
        tableView
            
            // El siguiente metodo, es un wrapper del metodo: tableView:didSelectItemAtIndexPath:, para obtener los eventos de 
            // seleccion de celdas de la tableView. Informamos como parametro el modelo de nuestras celdas, en este caso: String.
            .rx.modelSelected(String.self)
            
            // Nos subscribimos al las secuencias observables que llegaran en forma de evento: onNext() cuando se seleccione una
            // celda. suggestion en este caso, sera de tipo String, que es como le hemos indicado que es nuestro modelo en el 
            // metodo anterior.
            .subscribe(onNext: { [unowned self] suggestion in
                
                // Llamamos al metodo: searchSuggestionsViewController de nuestro delegado, que sera el: VolumeListWireframe
                // para indicarle la seleccion de la sugerencia y pueda mostrar los resultados asociados a esta.
                self.delegate?.searchSuggestionsViewController(self, didSelectSuggestion: suggestion)
            })
            // Como observers, guardamos la referenica sobre el observable.
            .addDisposableTo(disposeBag)
    }
}


// MARK: - UISearchResultsUpdating delegate.
extension SearchSuggestionsViewController: UISearchResultsUpdating {

    // Implementamos el metodo que nos informa cada vez que hay un cambio en el texto de busqueda el UISearchController.
    func updateSearchResults(for searchController: UISearchController) {
        
        // Obtenemos el texto de la searchBar o "" y se lo damos como un nuevo valor a la Variable observable query, lo que hara
        // que se generen los siguientes eventos de busqueda sugerencias para esta consulta.
        viewModel.query.value = searchController.searchBar.text ?? ""
        
        // Si la caja de texto no tiene nada que buscar, limpiamos el contenido de la tableView que podria tener de suggestions anteriores.
        if searchController.searchBar.text == "" {
        
            // Recorremos todas las celdas de la tableView. Damos por hecho que solo tenemos una sola seccion.
            for i in 0...tableView.numberOfRows(inSection: 0) {
                
                // Obtenemos la celda y borramos su contenido.
                if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) {
                    
                    cell.textLabel?.text = ""
                }
            }
        }
    }
}
