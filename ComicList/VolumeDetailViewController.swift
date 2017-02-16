//
//  VolumeDetailViewController.swift
//  ComicList
//
//  Created by Alberto Ortega on 09/01/16.
//  Copyright © 2016 Alberto Ortega. All rights reserved.
//

import UIKit
import RxSwift


class VolumeDetailViewController: UIViewController {

    // MARK: - Properties
    @IBOutlet private weak var headerView: VolumeDetailHeaderView!
    @IBOutlet private weak var descriptionView: VolumeDetailDescriptionView!
    @IBOutlet private weak var issuesView: VolumeDetailIssuesView!
    
    private let viewModel: VolumeDetailViewModelType
    private let disposeBag = DisposeBag()
    
    
    // MARK: - Initialization
    init(viewModel: VolumeDetailViewModelType) {
        
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: Bundle(for: type(of: self)))
    }
    
    convenience init(summary: VolumeSummary) throws {

        try self.init(viewModel: VolumeDetailViewModel(summary: summary))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupBindings()
    }

    
    // MARK: - Private
    private func setupView() {
        
        view.backgroundColor = UIColor(named: .detailBackground)
    }
    
    private func setupBindings() {
        
        // Conectamos el titulo del boton del viewModel, con el titulo del boton de la vista.
        // Entonces cuando haya cambios en la variable del viewModel, lo que hara es que se reflejaran automaticamente en la vista.
        viewModel.buttonTitle
            .bindTo(headerView.buttonTitle)
            .addDisposableTo(disposeBag)
        
        
        // Conectamos la propiedad funcion (actionHandler) de nuestra vista, con el metodo Add / Remove del viewModel.
        // Es decir, asignamos una funcion a otra funcion, por eso no indicamos los (). Los parentesis son solo para invocar. 
        // Entonces ahora cada vez que se pulse el boton, se ejecutara actionHandler y como esta conectado, se ejecutara 
        // addOrRemove del viewModel.
        headerView.actionHandler = viewModel.addOrRemove
        
        
        // Conectamos el viewModel con la la vista, para alimentar a esta ultima.
        headerView.summary = viewModel.summary

        
        // Conectamos la descripción del viewModel, con la descripción de la vista.
        // Entonces cuando haya cambios en la variable del viewModel, lo que hara es que se reflejaran automaticamente en la vista.
        viewModel.description
            .bindTo(descriptionView.descriptionLabel.rx.text)
            .addDisposableTo(disposeBag)

        
        // Conectamos los issues del viewModel, con la collectionView de la vista.
        // Entonces cuando haya cambios en la variable del viewModel, lo que hara es que se reflejaran automaticamente en la vista.
        viewModel.issues
            .bindTo(issuesView.collectionView.rx.items) { (collectionView, item, issue) in
                        
                let cell: IssueCell = collectionView.dequeueReusableCell(forItem: item)
                cell.summary = issue
                return cell
            }
            .addDisposableTo(disposeBag)
    }
}
