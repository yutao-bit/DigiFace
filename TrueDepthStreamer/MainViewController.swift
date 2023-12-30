//
//  MainViewController.swift
//  TrueDepthStreamer
//
//  Created by iosDeveloper on 2022/10/19.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import UIKit
import SwiftGifOrigin
@available(iOS 13.0, *)
class MainViewController: UIViewController{
    @IBOutlet weak private var startButton: UIButton!
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let jeremyGif = UIImage.gif(name: "headFront")
        let bl = Float((jeremyGif?.size.height)!) / Float((jeremyGif?.size.width)!)
        let gifview = UIImageView(image: jeremyGif)
        let jwidth = view.frame.width
        let gifheight = CGFloat(bl) * jwidth
        gifview.frame = CGRect(x: 0.0, y: 100.0, width: jwidth, height: gifheight)
        view.addSubview(gifview)
        print("hhh")
        
        startButton.layer.cornerRadius = startButton.frame.width * 0.5
        startButton.clipsToBounds = true
    }
    @IBAction
    private func start(_ sender:UIButton) {
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "CameraViewController")
            self.present(vc,animated: true,completion: nil)
    }

}

