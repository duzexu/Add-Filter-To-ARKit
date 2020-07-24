//
//  ViewController.swift
//  ARKit-Filter
//
//  Created by xu on 2020/7/22.
//  Copyright © 2020 du. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    
    var sceneView: ARSCNView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView = ARSCNView(frame: UIScreen.main.bounds)
        view.insertSubview(sceneView, at: 0)
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [])
        
    }

    @IBAction func switchAction(_ sender: UIButton) {
        ARFilterManager.shared.next()
    }
    
}
