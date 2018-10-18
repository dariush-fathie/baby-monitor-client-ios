//
//  BabyMonitorGeneralViewModelProtocol.swift
//  Baby Monitor
//

import UIKit

protocol BabyMonitorGeneralViewModelProtocol {
    
    var babyService: BabyService { get set }

    var numberOfSections: Int { get }
    
    func configure(cell: BabyMonitorCell, for indexPath: IndexPath)
    func numberOfRows(for section: Int) -> Int
}
