//
//  ViewController.swift
//  YJProgressHUD
//
//  Created by misakatao@gmail.com on 06/01/2023.
//  Copyright (c) 2023 misakatao@gmail.com. All rights reserved.
//

import UIKit
import YJProgressHUD

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let show = UIButton(type: .system)
        show.frame = CGRect(x: 10, y: 100, width: view.bounds.width - 20, height: 44)
        show.setTitle("show", for: .normal)
        show.addTarget(self, action: #selector(show(_:)), for: .touchUpInside)
        view.addSubview(show)
        
        let showProgress = UIButton(type: .system)
        showProgress.frame = CGRect(x: 10, y: show.frame.maxY + 10, width: view.bounds.width - 20, height: 44)
        showProgress.setTitle("showProgress", for: .normal)
        showProgress.addTarget(self, action: #selector(showProgress(_:)), for: .touchUpInside)
        view.addSubview(showProgress)
        
        let showMessage = UIButton(type: .system)
        showMessage.frame = CGRect(x: 10, y: showProgress.frame.maxY + 10, width: view.bounds.width - 20, height: 44)
        showMessage.setTitle("showMessage", for: .normal)
        showMessage.addTarget(self, action: #selector(showMessage(_:)), for: .touchUpInside)
        view.addSubview(showMessage)
        
        let showInfo = UIButton(type: .system)
        showInfo.frame = CGRect(x: 10, y: showMessage.frame.maxY + 10, width: view.bounds.width - 20, height: 44)
        showInfo.setTitle("showInfoWithStatus", for: .normal)
        showInfo.addTarget(self, action: #selector(showInfoWithStatus(_:)), for: .touchUpInside)
        view.addSubview(showInfo)
        
        let showSuccess = UIButton(type: .system)
        showSuccess.frame = CGRect(x: 10, y: showInfo.frame.maxY + 10, width: view.bounds.width - 20, height: 44)
        showSuccess.setTitle("showSuccessWithStatus", for: .normal)
        showSuccess.addTarget(self, action: #selector(showSuccessWithStatus(_:)), for: .touchUpInside)
        view.addSubview(showSuccess)
        
        let showError = UIButton(type: .system)
        showError.frame = CGRect(x: 10, y: showSuccess.frame.maxY + 10, width: view.bounds.width - 20, height: 44)
        showError.setTitle("showErrorWithStatus", for: .normal)
        showError.addTarget(self, action: #selector(showErrorWithStatus(_:)), for: .touchUpInside)
        view.addSubview(showError)
        
        let dismiss = UIButton(type: .system)
        dismiss.frame = CGRect(x: 10, y: showError.frame.maxY + 10, width: view.bounds.width - 20, height: 44)
        dismiss.setTitle("dismiss", for: .normal)
        dismiss.addTarget(self, action: #selector(dismiss(_:)), for: .touchUpInside)
        view.addSubview(dismiss)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc private func show(_ sender: UIButton) {
        YJProgressHUD.show()
    }
    
    @objc private func showProgress(_ sender: UIButton) {
        YJProgressHUD.show(nil, 1.0)
    }
    
    @objc private func showMessage(_ sender: UIButton) {
        YJProgressHUD.showMessage("Useful Information.")
    }
    
    @objc private func showInfoWithStatus(_ sender: UIButton) {
        YJProgressHUD.showInfo("Useful Information.")
    }
    
    @objc private func showSuccessWithStatus(_ sender: UIButton) {
        YJProgressHUD.showInfo("Great Success!")
    }
    
    @objc private func showErrorWithStatus(_ sender: UIButton) {
        YJProgressHUD.showInfo("Failed with Error")
    }
    
    @objc private func dismiss(_ sender: UIButton) {
        YJProgressHUD.dismiss()
    }
}

