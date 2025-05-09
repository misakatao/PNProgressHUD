//
//  ViewController.swift
//  PNProgressHUD
//
//  Created by misakatao@gmail.com on 08/07/2024.
//  Copyright (c) 2024 misakatao@gmail.com. All rights reserved.
//

import UIKit
import PNProgressHUD

final class ViewController: UIViewController {
    
    // MARK: - Types
    
    private typealias Example = (title: String, action: () -> Void)
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellId)
        table.rowHeight = 50
        return table
    }()
    
    // MARK: - Properties
    
    private let examples: [Example] = [
        ("Show Message", {
            ProgressHUD.showMessage("This is a message")
        }),
        ("Show Loading", {
            ProgressHUD.show("Loading...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                ProgressHUD.dismiss()
            }
        }),
        ("Show Success", {
            ProgressHUD.showSuccess("Operation completed")
        }),
        ("Show Error", {
            ProgressHUD.showError("Something went wrong")
        }),
        ("Show Info", {
            ProgressHUD.showInfo("Here's some information")
        }),
        ("Show Progress", {
            ViewController.demonstrateProgress()
        }),
        ("Light Style", {
            ViewController.demonstrateStyle(.light)
        }),
        ("Dark Style", {
            ViewController.demonstrateStyle(.dark)
        }),
        ("Custom Style", {
            ViewController.demonstrateCustomStyle()
        }),
        ("Mask Types", {
            ViewController.demonstrateMaskTypes()
        })
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        title = "ProgressHUD Examples"
        view.backgroundColor = .white
        
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    private static func demonstrateProgress() {
        var progress: CGFloat = 0.0
        
        func updateProgress() {
            progress += 0.1
            ProgressHUD.show("Loading...", progress)
            
            guard progress < 1.0 else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    ProgressHUD.showSuccess("Done!")
                }
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                updateProgress()
            }
        }
        
        updateProgress()
    }
    
    private static func demonstrateStyle(_ style: ProgressHUD.Style) {
        let hud = ProgressHUD.shared
        hud.defaultStyle = style
        ProgressHUD.show("\(style) Style")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            ProgressHUD.dismiss()
            hud.defaultStyle = .dark // Reset to default
        }
    }
    
    private static func demonstrateCustomStyle() {
        let hud = ProgressHUD.shared
        hud.defaultStyle = .custom
        hud.customColor = .black
        hud.foregroundColor = .white
        
        ProgressHUD.show("Custom Style")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            ProgressHUD.dismiss()
            // Reset to default
            hud.defaultStyle = .dark
            hud.customColor = .white
            hud.foregroundColor = .black
        }
    }
    
    private static func demonstrateMaskTypes() {
        let maskTypes: [ProgressHUD.MaskType] = [.none, .clear, .black, .gradient]
        var currentIndex = 0
        
        func showNextMask() {
            guard currentIndex < maskTypes.count else {
                ProgressHUD.shared.defaultMaskType = .none // Reset to default
                return
            }
            
            let maskType = maskTypes[currentIndex]
            ProgressHUD.shared.defaultMaskType = maskType
            ProgressHUD.show("Mask Type: \(maskType)")
            currentIndex += 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                ProgressHUD.dismiss(0) {
                    showNextMask()
                }
            }
        }
        
        showNextMask()
    }
}

// MARK: - Constants

private extension ViewController {
    enum Constants {
        static let cellId = "ExampleCell"
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        examples.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellId, for: indexPath)
        cell.textLabel?.text = examples[indexPath.row].title
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        examples[indexPath.row].action()
    }
}

