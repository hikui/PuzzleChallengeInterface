//
//  ViewController.swift
//  CollectionViewManipulation
//
//  Created by Henry Miao on 16/6/18.
//  Copyright © 2018 Henry Miao. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    enum MoveDirection {
        case up
        case down
        case left
        case right
        
        func isHorizontal() -> Bool {
            return self == .left || self == .right
        }
        
        func isVertical() -> Bool {
            return self == .up || self == .down
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var cellVMs: [GridCellVM] = {
        return (0..<16).map { GridCellVM(number: $0) }
    }()
    
    lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        return UIPanGestureRecognizer(target: self, action: #selector(panGestureDetected(recognizer:)))
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.addGestureRecognizer(panGestureRecognizer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let collectionViewWidth = self.collectionView.frame.size.width
        let cellWidth = floor((collectionViewWidth - 5) / 4)
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize = CGSize(width: cellWidth, height: cellWidth)
    }
    
    var movingIndexPath: IndexPath?
    var movingCell: UICollectionViewCell?
    var targetIndexPath: IndexPath?
    var targetCell: UICollectionViewCell?
    var cellSnapshot: UIView?
    
    func indexPath(fromIndexPath indexPath: IndexPath, direction: MoveDirection) -> IndexPath? {
        let idx = indexPath.item
        switch direction {
        case .up:
            return (idx - 4) < 0 ? nil : IndexPath(item: idx - 4, section: indexPath.section)
        case .down:
            return (idx + 4) > 15 ? nil : IndexPath(item: idx + 4, section: indexPath.section)
        case .left:
            return (idx % 4) == 0 ? nil : IndexPath(item: idx - 1, section: indexPath.section)
        case .right:
            return ((idx + 1) % 4 == 0) ? nil : IndexPath(item: idx + 1, section: indexPath.section)
        }
    }
    
    func availableDirectionToMove(forIndexPath indexPath: IndexPath) -> MoveDirection? {
        if let upperIndexPath = self.indexPath(fromIndexPath: indexPath, direction: .up), cellVMs[upperIndexPath.item].number == 0 {
            return .up
        } else if let downIndexPath = self.indexPath(fromIndexPath: indexPath, direction: .down), cellVMs[downIndexPath.item].number == 0 {
            return .down
        } else if let leftIndexPath = self.indexPath(fromIndexPath: indexPath, direction: .left), cellVMs[leftIndexPath.item].number == 0 {
            return .left
        } else if let rightIndexPath = self.indexPath(fromIndexPath: indexPath, direction: .right), cellVMs[rightIndexPath.item].number == 0 {
            return .right
        }
        return nil
    }
    
    func moveDirection(forVector vector: CGVector) -> MoveDirection {
        if abs(vector.dx) > abs(vector.dy) {
            // horizontal movement
            return vector.dx > 0 ? .right : .left
        } else {
            return vector.dy > 0 ? .down : .up
        }
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCell", for: indexPath)
        let itemIndex = indexPath.item
        let vm = cellVMs[itemIndex]
        if let gridCell = cell as? GridCell {
            gridCell.bind(vm: vm)
        }
        return cell
    }
    
    
    @objc func panGestureDetected(recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: collectionView)
        
        switch recognizer.state {
        case .began:
            guard let itemIdx = collectionView.indexPathForItem(at: location),
                let cell = collectionView.cellForItem(at: itemIdx) else { return }
            movingIndexPath = itemIdx
            movingCell = cell
            // Create a fake cell
            cellSnapshot = cell.snapshotView(afterScreenUpdates: true)
            cellSnapshot?.center = cell.center
            if let cellSnapshot = cellSnapshot {
                collectionView.addSubview(cellSnapshot)
            }
            // Make the real cell invisible
            movingCell?.alpha = 0
            
            if let availableDirection = availableDirectionToMove(forIndexPath: itemIdx) {
                self.targetIndexPath = indexPath(fromIndexPath: itemIdx, direction: availableDirection)
                self.targetCell = collectionView.cellForItem(at: targetIndexPath!)
            }
        case .cancelled:
            endMoving()
        case .ended:
            endMoving()
        case .changed:
            moveSelectedCell(gestureRecognizer: recognizer)
        default:
            ()
        }
        
    }

    func endMoving() {
        // See if the movement should be completed or discarded
        guard let movingCell = movingCell,
            let movingSnapshot = cellSnapshot,
            let movingIndexPath = movingIndexPath else {
            return
        }
        
        let deltaX = movingSnapshot.center.x - movingCell.center.x
        let deltaY = movingSnapshot.center.y - movingCell.center.y
        
        let direction = moveDirection(forVector: CGVector(dx: deltaX, dy: deltaY))
        
        var shouldComplete = false
        if (direction.isVertical()) && abs(deltaY) > movingCell.frame.size.height / 2 {
            shouldComplete = true
        } else if (direction.isHorizontal()) && abs(deltaX) > movingCell.frame.size.width / 2 {
            shouldComplete = true
        }
        
        var targetIndexPath = movingIndexPath
        if shouldComplete {
            targetIndexPath = indexPath(fromIndexPath: movingIndexPath, direction: direction) ?? movingIndexPath
        }
        
        panGestureRecognizer.isEnabled = false
        UIView.animate(withDuration: 0.4, animations: {
            guard let targetCell = self.collectionView.cellForItem(at: targetIndexPath) else { return }
            movingSnapshot.center = targetCell.center
        }, completion: { finished in
            // Clean up
            movingSnapshot.removeFromSuperview()
            movingCell.alpha = 1
            if shouldComplete {
                // Swap data in data source
                self.cellVMs.swapAt(movingIndexPath.item, targetIndexPath.item)
            }
            
            self.collectionView.reloadData()
            self.panGestureRecognizer.isEnabled = true
        })
    }
    
    func moveSelectedCell(gestureRecognizer: UIPanGestureRecognizer) {
        guard let originalIndexPath = movingIndexPath,
            let movingSnapshot = cellSnapshot,
            let movingCell = movingCell,
            let targetCell = targetCell
            else {
                return
                
        }
        // diffY > 0 : target is on the bottom
        let diffY = targetCell.center.y - movingCell.center.y
        // diffX > 0 : target is on the right
        let diffX = targetCell.center.x - movingCell.center.x
        
        let leftMostTranslation = diffX > 0 ? 0 : diffX
        let rightMostTranslation = diffX > 0 ? diffX : 0
        let topMostTranslation = diffY > 0 ? 0 : diffY
        let bottomMostTranslation = diffY > 0 ? diffY : 0
        
        var translation = gestureRecognizer.translation(in: collectionView)
        
        guard let availableDirection = availableDirectionToMove(forIndexPath: originalIndexPath) else {
            // Can't apply any movement
            return
        }
        
        // Restrict the range of movement
        if availableDirection.isHorizontal() {
            if translation.x < leftMostTranslation {
                translation.x = leftMostTranslation
            }
            if translation.x > rightMostTranslation {
                translation.x = rightMostTranslation
            }
        } else {
            if translation.y < topMostTranslation {
                translation.y = topMostTranslation
            }
            if translation.y > bottomMostTranslation {
                translation.y = bottomMostTranslation
            }
        }
        
        // Adjust the translation
        gestureRecognizer.setTranslation(translation, in: collectionView)
        
        var newCenter = movingCell.center
        
        // Only apply one direction movement
        if availableDirection.isHorizontal() {
            newCenter.x += translation.x
        } else {
            newCenter.y += translation.y
        }
        
        movingSnapshot.center = newCenter
    }
}
