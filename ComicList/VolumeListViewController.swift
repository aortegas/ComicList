//
//  VolumeListViewController.swift
//  ComicList
//
//  Created by Alberto Ortega on 27/12/15.
//  Copyright © 2015 Alberto Ortega. All rights reserved.
//

import UIKit


final class VolumeListViewController: UIViewController {
    
    // MARK: - Properties
    // Outlet con variable observada, para que cuando se asigne el outlet en la carga realice el registro de las collections y 
    // Se configure el color de fondo.
    @IBOutlet private weak var collectionView: UICollectionView! {
        
        didSet {
            // 
            collectionView.register(VolumeListItemCell.self)
            collectionView.backgroundColor = UIColor(named: .background)
        }
    }

    fileprivate let viewModel: VolumeListViewModelType // Nuestro viewModel
    fileprivate let wireframe: VolumeListWireframeType // Nuestro wireframe, retenemos el wireframe, porque no lo retiene nadie.
    
    
    // MARK: - Initialization
    // Permitimos un parametro para el viewModel, y si no nos lo pasan creamos uno, para que este accesible dentro del init.
    init(wireframe: VolumeListWireframeType, viewModel: VolumeListViewModelType = VolumeListViewModel()) {
        
        self.wireframe = wireframe
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: Bundle(for: type(of: self)))
    }

    required init?(coder aDecoder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Instalamos el searchController sobre nosotros como viewController.
        wireframe.installSearchInViewController(self)
        setupBindings()
    }

    
    // MARK: - Private func
    // Conectamos con el viewModel.
    private func setupBindings() {
        
        // Damos la implementacion para la variable calculada del protocolo: VolumeListViewModelType del ViewModel, que sera llamada o ejecutada
        // desde este. 
        viewModel.didUpdateList = collectionView.reloadData
    }
}


// MARK: - UICollectionViewDataSource
extension VolumeListViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // Devolvemos el numero de volumenes del viewModel.
        return viewModel.numberOfVolumes
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Creamos VolumeListItemCell para devolverlas.
        let cell: VolumeListItemCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
        // Subscript del viewModel para obtener los datos de la collection de sobre el IndexPath.
        cell.item = viewModel[indexPath.item]
        // Devolvemos la VolumeListItemCell.
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension VolumeListViewController: UICollectionViewDelegate {
    
    // Funcion delegada para pedirle al wireframe que muestre el detalle del volumen que se ha seleccionado.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // Manejamos los throws posibles que puede devolver presentar el VolumeDetailViewController.
        do {
            
            try wireframe.presentVolumeDetailWithSummary(viewModel[indexPath.row], fromViewController: self)
        }
        catch let error {
            
            fatalError("Error in collectionView didSelectItemAt: \(error.localizedDescription)")
        }
    }
}









