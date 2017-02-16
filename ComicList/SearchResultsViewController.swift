//
//  SearchResultsViewController.swift
//  ComicList
//
//  Created by Alberto Ortega on 09/01/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import UIKit
import RxSwift


class SearchResultsViewController: UITableViewController {
    
    // MARK: - Properties
    private let viewModel: SearchResultsViewModelType   // Nuestro ViewModel.
    private let wireframe: SearchResultsWireframeType   // Nuestro WireFrame.
    private let disposeBag = DisposeBag() // DisposeBag para eliminar las subscripciones.
    
    // Views para poner un activity indicator, mientras se realizan las solicitudes al API.
    private var footerView: UIView!
    private var activityIndicator: UIActivityIndicatorView!
    private var loading: Bool {
        
        get {
            
            return self.loading
        }
        set {
            // Si ponemos el valor a true.
            if newValue {
                
                // Pintamos la vista pie, ponemos en marcha el activity indicator.
                setupFooterView()
                self.activityIndicator.startAnimating()
                self.activityIndicator.isHidden = false
            }
            // Si el valor esta a false.
            else {
                
                // Paramos el activity y lo ocultamos.
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
            }
        }
    }

    
    // MARK: - Initialization
    init(wireframe: SearchResultsWireframeType, viewModel: SearchResultsViewModelType) {
        
        self.wireframe = wireframe
        self.viewModel = viewModel
        super.init(style: .plain)
    }
    
    convenience init(wireframe: SearchResultsWireframeType, query: String) {
        
        // Creamos un SearchResultsViewModel, pasandole como parametro la sugerencia o la query aceptada como busqueda.
        self.init(wireframe: wireframe, viewModel: SearchResultsViewModel(query: query))
    }
    
    required init?(coder aDecoder: NSCoder) {
     
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
    
        super.viewDidLoad()
        setupView()
        setupBindings()
        // En cuanto se carge el viewController, cargamos los datos de la primera pagina.
        nextPage()
    }
    
    
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return viewModel.numberOfResults
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: SearchResultCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        cell.result = viewModel[indexPath.row]
        return cell
    }
    
    
    // MARK: - UITableViewDelegate
    // Sobreescribimos este metodo para realizar la paginacion.
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.backgroundColor = UIColor.clear
        
        // Cuando estemos al final de la pantalla, recargamos con mas datos.
        if indexPath.row == viewModel.numberOfResults - 2 {
            
            nextPage()
        }
    }
    
    // Si seleccionamos un Volume, consultamos su detalle.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        do {
            try wireframe.presentVolumeDetailWithSummary(viewModel[indexPath.row], fromViewController: self)
        }
        catch let error {
            fatalError("presentVolumeDetailWithSummary error: \(error.localizedDescription)")
        }
    }
    
    // Añadimos un pie a la tabla con un activity indicator.
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {

        setupFooterView()
        return footerView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 44.0
    }
    
    
    // MARK: - Private methods.
    private func setupView() {

        // Indicamos el titulo de la vista, con el texto de la query.
        title = viewModel.query

        // Customizamos el tableView.
        tableView.backgroundColor = UIColor(named: .background)
        tableView.register(SearchResultCell.self)
        
        // Creamos el activity & la vista de pie, a la que incluiremos el activity.
        self.activityIndicator = UIActivityIndicatorView()
        self.footerView = UIView()
        footerView.addSubview(activityIndicator)
    }
    
    private func setupBindings() {
    
        // Asociamos la variable (bloque) del viewModel, con la sentencia que queremos que se ejecute aqui en el viewController
        // cuando se llama al metodo didUpdateResults en el viewModel. Es decir, le estamos suministrando aqui, el codigo que queremos
        // se ejecute aqui.
        viewModel.didUpdateResults = tableView.reloadData
    }
    
    // Metodo privado para conseguir la siguiente pagina de resultados.
    private func nextPage() {
        
        // Ponemos visible el activity indicator, seteando la variable calculada.
        loading = true
        
        // Nos subscribimos al Observable<Void> que devuelve la función nextPage(), del viewModel.
        viewModel.nextPage()

            .subscribe(onNext: {
            
                // Una vez descargados los datos, ponemos oculto el activity indicator, seteando la variable calculada.
                self.loading = false
            })
            .addDisposableTo(disposeBag)  // Añadimos nuestra subscricion al observable a la bolsa de subscripciones.
    }
    
    // Pintamos la vista de pie, con el activity indicator.
    private func setupFooterView() {
        
        footerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 44)
        activityIndicator.frame = CGRect(x: footerView.bounds.size.width, y: 0, width: 40, height: 40)
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        activityIndicator.center = footerView.center
    }
}















