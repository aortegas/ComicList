//
//  AppDelegate.swift
//  ComicList
//
//  Created by Alberto Ortega on 13/12/15.
//  Copyright © 2015 Alberto Ortega. All rights reserved.
//

import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // Properties
    var window: UIWindow?

    
    // Functions
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        customizeAppearance()
        installRootViewController()
        
        window?.makeKeyAndVisible()
        
        return true
    }
    
    
    // Customizamos la apariencia con los proxy de apparance.
    private func customizeAppearance() {
        
        // Creamos el proxy para la apariencia de la navigationBar.
        let navigationBarAppearance = UINavigationBar.appearance()
        
        let barTintColor = UIColor(named: .bar)
        
        // Customizamos los colores de la navigationBar.
        navigationBarAppearance.barStyle = .black // This will make the status bar white by default
        navigationBarAppearance.barTintColor = barTintColor
        navigationBarAppearance.tintColor = UIColor.white
        navigationBarAppearance.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.white
        ]
    }
    
    
    // Creamos el viewController de inicio.
    private func installRootViewController() {
        
        // Creamos un navigationController.
        let navigationController = UINavigationController()
        // Creamos el VolumeListWireframe, pasandole el navigationController.
        let wireframe = VolumeListWireframe(navigationController: navigationController)
        // Creamos el VolumeListViewController, pasandole el VolumeListWireframe.
        let viewController = VolumeListViewController(wireframe: wireframe)
        // Colocamos en el navigationController el VolumeListViewController.
        navigationController.pushViewController(viewController, animated: false)
        // Colocamos el navigationController como root de la window.
        window?.rootViewController = navigationController
    }
}



















