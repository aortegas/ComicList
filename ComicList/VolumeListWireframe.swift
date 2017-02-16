//
//  VolumeListWireframe.swift
//  ComicList
//
//  Created by Alberto Ortega on 08/01/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import UIKit


// Definimos un protocolo que unicamente pueden conformar clases, con las acciones de navegacion que debe resolver este 
// Wireframe.
protocol VolumeListWireframeType: class {
    
    // Funcion para instalar un SearchViewController pasandole un ViewController.
    func installSearchInViewController(_ viewController: UIViewController)
    
    // Funcion para presentar un VolumeDetailViewController desde otro ViewController.
    func presentVolumeDetailWithSummary(_ summary: VolumeSummary, fromViewController viewController: UIViewController) throws
}


// Clase VolumeListWireFrame.
final class VolumeListWireframe: NSObject {
    
    // MARK: - Properties.
    // Propiedad unowned para guardar referencia debil al navigationController.
    fileprivate unowned let navigationController: UINavigationController
    fileprivate var searchController: UISearchController?
    
    
    // MARK: - Init
    init(navigationController: UINavigationController) {
        
        self.navigationController = navigationController
    }
    
    
    // MARK: - Private Functions
    // Metodo privado para presentar los resultados de una busqueda en un SearchResultsViewController. Hacemos privada esta funcion, 
    // porque aunque se trata de navegacion, la invocamos desde implementacion del protocolo: SearchSuggestionsViewControllerDelegate y 
    // tambien desde la implementación del delegado del protocolo: UISearchBarDelegate, cuando se pulsa el boton de busqueda. 
    // Es decir, aqui acabamos cuando pulsamos sobre alguna sugerencia o tambien cuando presionamos la tecla de Buscar, ya que puede que 
    // no tengamos sugerencias, al ser por ejemplo el texto de la query de busqueda < 3 caracteres y en ese punto, pulsamos Saarch.
    fileprivate func presentSearchResultsWithQuery(_ query: String) {
        
        // Creamos el SearchResultsWireframe, pasandole el navigationController.
        let wireframe = SearchResultsWireframe(navigationController: navigationController)
        // Creamos el SearchResultsViewController, pasandole el SearchResultsWireframe.
        let viewController = SearchResultsViewController(wireframe: wireframe, query: query)
        // Colocamos en el navigationController el SearchResultsViewController.
        self.navigationController.pushViewController(viewController, animated: true)
    }
}


// Conformamos el protocolo VolumeListWireframeType
extension VolumeListWireframe: VolumeListWireframeType {
    
    func installSearchInViewController(_ viewController: UIViewController) {
        
        // Creamos un SearchSuggestionsViewController
        let suggestionsViewController = SearchSuggestionsViewController()
        // Y nos hacemos delegados de el.
        suggestionsViewController.delegate = self
        
        // Customizamos el UISearchController. Lo creamos pasandole como viewController el SearchSuggestionsViewController que hemos creado.
        searchController = UISearchController(searchResultsController: suggestionsViewController)
        // Propiedad para: The object responsible for updating the contents of the search results controller.
        searchController?.searchResultsUpdater = suggestionsViewController
        // Propiedad para: A Boolean indicating whether the navigation bar should be hidden when searching.
        searchController?.hidesNavigationBarDuringPresentation = false
        
        // Customizamos la searchBar del UISearchController.
        // Propiedad para: Nos hacemos delegados de el.
        searchController?.searchBar.delegate = self
        searchController?.searchBar.placeholder = NSLocalizedString("Search Comic Vine", comment: "")
        searchController?.searchBar.searchBarStyle = .minimal
        searchController?.searchBar.searchFieldTextColor = UIColor.white  // Propiedad extendida de UISearchBar (ver: SearchBarHelpers)
        searchController?.searchBar.keyboardAppearance = .dark
        
        // Colocamos el UISearchController en el viewController que nos han pasado.
        viewController.navigationItem.titleView = searchController?.searchBar
        // Indicamos que la vista del viewController que nos han pasado, estara cubierta por el UISearchController.
        viewController.definesPresentationContext = true
    }
    
    func presentVolumeDetailWithSummary(_ summary: VolumeSummary, fromViewController viewController: UIViewController) throws {
        
        // Creamos un VolumeDetailViewController (ojo, devolvemos el throw que nos pueda devolver).
        let detailViewController = try VolumeDetailViewController(summary: summary)
        // Colocamos en el navigationController el VolumeDetailViewController.
        navigationController.pushViewController(detailViewController, animated: true)
    }
}


// Conformamos el protocolo SearchSuggestionsViewControllerDelegate.
extension VolumeListWireframe: SearchSuggestionsViewControllerDelegate {
    
    func searchSuggestionsViewController(_ viewController: SearchSuggestionsViewController, didSelectSuggestion suggestion: String) {
      
        // Presentamos los resultados para una sugerencia que nos haya devuelto el API y que hayamos seleccionado.
        presentSearchResultsWithQuery(suggestion)
    }
}


// Conformamos los metodos delegados de UISearchBarDelegate.
extension VolumeListWireframe: UISearchBarDelegate {
    
    // Esta func es invocada por el UISearchViewController, cada vez que el boton de busqueda es pulsado.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        // Presentamos los resultados para el texto tecleado en la searchBar.
        presentSearchResultsWithQuery(searchBar.text ?? "")
    }
}


