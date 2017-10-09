//
//  UICollectionView+Sauce.swift
//  TabTool
//
//  Created by Lukas Stabe on 29.07.16.
//  Copyright © 2016 2C. All rights reserved.
//

import UIKit

// this extension copied from the swift branch of zwaldowski/AdvancedCollectionView, license here: https://raw.githubusercontent.com/zwaldowski/AdvancedCollectionView/zwaldowski/old/swift/LICENSE.txt

extension UICollectionView {
    public func register(typeForCell type: UICollectionViewCell.Type, reuseIdentifier: String? = nil) {
        let identifier = reuseIdentifier ?? NSStringFromClass(type)
        self.register(type, forCellWithReuseIdentifier: identifier)
    }

    public func dequeue<V: UICollectionViewCell>(cellOfType type: V.Type, indexPath: IndexPath, reuseIdentifier: String? = nil) -> V {
        let identifier = reuseIdentifier ?? NSStringFromClass(type)
        return dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! V
    }
}

extension UICollectionView {
    func register(typeForSupplement type: UICollectionReusableView.Type, ofKind kind: String, reuseIdentifier: String? = nil) {
        let identifier = reuseIdentifier ?? NSStringFromClass(type)
        self.register(type, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
    }

    func dequeue<V: UICollectionReusableView>(supplementOfType type: V.Type, ofKind kind: String, indexPath: IndexPath, reuseIdentifier: String? = nil) -> V {
        let identifier = reuseIdentifier ?? NSStringFromClass(type)
        return dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath) as! V
    }
}
