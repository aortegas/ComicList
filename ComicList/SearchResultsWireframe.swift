//
//  SearchResultsWireframe.swift
//  ComicList
//
//  Created by Alberto Ortega on 11/01/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import UIKit


// Definimos un protocolo que unicamente pueden conformar clases, con las acciones de navegacion que debe resolver este
// Wireframe.
protocol SearchResultsWireframeType: class {
    
    func presentVolumeDetailWithSummary(_ summary: VolumeSummary, fromViewController viewController: UIViewController) throws
}


// Clase SearchResultsWireframe.
final class SearchResultsWireframe {

    // MARK: - Properties.
    // Propiedad unowned para guardar referencia debil al navigationController.
    fileprivate unowned let navigationController: UINavigationController

    
    // MARK: - Init.
    init(navigationController: UINavigationController) {
        
        self.navigationController = navigationController
    }
}


// Conformamos el protocolo SearchResultsWireframeType
extension SearchResultsWireframe: SearchResultsWireframeType {
    
    func presentVolumeDetailWithSummary(_ summary: VolumeSummary, fromViewController viewController: UIViewController) throws {
        
        let detailViewController = try VolumeDetailViewController(summary: summary)
        navigationController.pushViewController(detailViewController, animated: true)
    }
}
