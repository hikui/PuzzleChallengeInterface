//
//  PuzzleBoardView.swift
//  CollectionViewManipulation
//
//  Created by Henry Miao on 16/6/18.
//  Copyright © 2018 Henry Miao. All rights reserved.
//

import UIKit

class PuzzleBoardView: UICollectionView {
    
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
        
        
        /// Get direction from a vector
        static func from(vector: CGVector) -> MoveDirection {
            if abs(vector.dx) > abs(vector.dy) {
                // horizontal movement
                return vector.dx > 0 ? .right : .left
            } else {
                return vector.dy > 0 ? .down : .up
            }
        }
    }
    
    @IBInspectable var gameSize = 5
    var cellVMs: [GridCellVM]!
    
    // Variables used during a movement
    // The indexPath of the cell being moved
    var movingIndexPath: IndexPath?
    // The cell being moved
    var movingCell: UICollectionViewCell?
    // The destimation indexPath that the current cell is being moved to
    var targetIndexPath: IndexPath?
    // The target cell will eventually be swapped for the moving cell
    var targetCell: UICollectionViewCell?
    // The snapshot view for the moving cell. This view "fakes" the animation
    var cellSnapshot: UIView?
    
    lazy var customPanGestureRecognizer: UIPanGestureRecognizer = {
        return UIPanGestureRecognizer(target: self, action: #selector(panGestureDetected(recognizer:)))
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Install custom pan gesture recognizer
        self.delegate = self
        self.dataSource = self
        self.addGestureRecognizer(customPanGestureRecognizer)
        self.cellVMs = (0..<gameSize*gameSize).map { GridCellVM(number: $0) }
        self.cellVMs.shuffle()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

// MARK: - Helper functions
extension PuzzleBoardView {
    
    /// Given an indexPath, tells the target indexPath after moving with given direction
    ///
    /// - Parameters:
    ///   - indexPath: current index path
    ///   - direction: moving direction
    /// - Returns: target index path after movement. Returns nil if the current item can't be moved to given direction
    func indexPath(fromIndexPath indexPath: IndexPath, direction: MoveDirection) -> IndexPath? {
        let idx = indexPath.item
        switch direction {
        case .up:
            return (idx - gameSize) < 0 ? nil : IndexPath(item: idx - gameSize, section: indexPath.section)
        case .down:
            return (idx + gameSize) >= gameSize * gameSize ? nil : IndexPath(item: idx + gameSize, section: indexPath.section)
        case .left:
            return (idx % gameSize) == 0 ? nil : IndexPath(item: idx - 1, section: indexPath.section)
        case .right:
            return ((idx + 1) % gameSize == 0) ? nil : IndexPath(item: idx + 1, section: indexPath.section)
        }
    }
    
    /// Given an indexPath, tells which direction can it be moved.
    ///
    /// - Parameter indexPath: current index path
    /// - Returns: the direction it can be moved to. Returns nil if it can't be moved.
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
}

extension PuzzleBoardView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gameSize * gameSize
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = self.collectionViewLayout as! UICollectionViewFlowLayout
        let contentWidth = self.frame.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right - flowLayout.minimumInteritemSpacing * CGFloat((gameSize - 1))
        
        let width = floor(contentWidth / CGFloat(gameSize))
        return CGSize(width: width, height: width)
    }
    
}

// MARK: - Gesture handling
extension PuzzleBoardView {
    @objc func panGestureDetected(recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: self)
        
        switch recognizer.state {
        case .began:
            guard let itemIdx = self.indexPathForItem(at: location),
                let cell = self.cellForItem(at: itemIdx) else { return }
            movingIndexPath = itemIdx
            movingCell = cell
            // Create a fake cell
            cellSnapshot = cell.snapshotView(afterScreenUpdates: true)
            cellSnapshot?.center = cell.center
            if let cellSnapshot = cellSnapshot {
                self.addSubview(cellSnapshot)
            }
            // Make the real cell invisible
            movingCell?.alpha = 0
            
            if let availableDirection = availableDirectionToMove(forIndexPath: itemIdx) {
                self.targetIndexPath = indexPath(fromIndexPath: itemIdx, direction: availableDirection)
                self.targetCell = self.cellForItem(at: targetIndexPath!)
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
        
        // Compute the current position of the "fake" cell
        let deltaX = movingSnapshot.center.x - movingCell.center.x
        let deltaY = movingSnapshot.center.y - movingCell.center.y
        
        let direction = MoveDirection.from(vector: CGVector(dx: deltaX, dy: deltaY))
        
        var shouldComplete = false
        // Complete the half-way movement
        if (direction.isVertical()) && abs(deltaY) > movingCell.frame.size.height / 2 {
            shouldComplete = true
        } else if (direction.isHorizontal()) && abs(deltaX) > movingCell.frame.size.width / 2 {
            shouldComplete = true
        }
        
        // If the position is less than half-way, the cell will be moved back
        var targetIndexPath = movingIndexPath
        if shouldComplete {
            targetIndexPath = indexPath(fromIndexPath: movingIndexPath, direction: direction) ?? movingIndexPath
        }
        
        customPanGestureRecognizer.isEnabled = false
        UIView.animate(withDuration: 0.4, animations: {
            guard let targetCell = self.cellForItem(at: targetIndexPath) else { return }
            movingSnapshot.center = targetCell.center
        }, completion: { finished in
            // Clean up
            movingSnapshot.removeFromSuperview()
            movingCell.alpha = 1
            if shouldComplete {
                // Swap data in data source
                self.cellVMs.swapAt(movingIndexPath.item, targetIndexPath.item)
            }
            
            self.reloadData()
            self.customPanGestureRecognizer.isEnabled = true
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
        
        // Determine the possible range of the gesture translation
        // For example, if the empty position is on the left side of the current tile,
        // then the leftMostTranslation should be diffX and the rightMostTranslation should be 0(can't move to right)
        let leftMostTranslation = diffX > 0 ? 0 : diffX
        let rightMostTranslation = diffX > 0 ? diffX : 0
        let topMostTranslation = diffY > 0 ? 0 : diffY
        let bottomMostTranslation = diffY > 0 ? diffY : 0
        
        var translation = gestureRecognizer.translation(in: self)
        
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
        gestureRecognizer.setTranslation(translation, in: self)
        
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
