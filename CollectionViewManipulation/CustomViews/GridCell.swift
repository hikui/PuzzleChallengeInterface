//
//  GridCell.swift
//  CollectionViewManipulation
//
//  Created by Henry Miao on 16/6/18.
//  Copyright © 2018 Henry Miao. All rights reserved.
//

import UIKit

/// View model for grid cell
struct GridCellVM: Equatable {
    var number: Int
}

/// Simple cell that displays a number
class GridCell: UICollectionViewCell {
    
    @IBOutlet weak var label: UILabel!
    
    var viewModel: GridCellVM!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func bind(vm: GridCellVM) {
        self.viewModel = vm
        if vm.number == 0 {
            // 0 represents the empty position
            self.backgroundColor = UIColor.clear
            self.label.text = nil
        } else {
            self.backgroundColor = UIColor.white
            self.label.text = "\(vm.number)"
        }
    }
}
