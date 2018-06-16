//
//  GridCell.swift
//  CollectionViewManipulation
//
//  Created by Henry Miao on 16/6/18.
//  Copyright © 2018 Henry Miao. All rights reserved.
//

import UIKit

struct GridCellVM: Equatable {
    var number: Int
}

protocol GridCellDelegate {
    func gridCell(_ cell: GridCell, panGestureDetected panGesture: UIPanGestureRecognizer)
}

class GridCell: UICollectionViewCell {
    
    @IBOutlet weak var label: UILabel!
    var panGestureRecognizer: UIPanGestureRecognizer!
//    var delegate: GridCellDelegate?
    
    var viewModel: GridCellVM!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
//        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureDidPerform(gestureRecognizer:)))
//        self.addGestureRecognizer(panGestureRecognizer)
    }
    
    func bind(vm: GridCellVM) {
        self.viewModel = vm
        if vm.number == 0 {
            self.backgroundColor = UIColor.clear
            self.label.text = nil
        } else {
            self.backgroundColor = UIColor.white
            self.label.text = "\(vm.number)"
        }
    }
    
    @objc func panGestureDidPerform(gestureRecognizer: UIPanGestureRecognizer) {
//        delegate?.gridCell(self, panGestureDetected: gestureRecognizer)
    }
}
