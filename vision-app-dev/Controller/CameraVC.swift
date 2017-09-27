//
//  CameraVC.swift
//  vision-app-dev
//
//  Created by IceApinan on 26/9/17.
//  Copyright © 2017 IceApinan. All rights reserved.
//

import UIKit

class CameraVC: UIViewController {

    @IBOutlet weak var captureImageView: RoundedShadowImageView!
    
    @IBOutlet weak var flashButton: RoundedShadowButton!
    @IBOutlet weak var identificationLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    
    @IBOutlet weak var cameraView: UIView!
    
    @IBOutlet weak var roundedLabelView: RoundedShadowView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    

}

