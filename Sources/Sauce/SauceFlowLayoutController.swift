//
//  SauceFlowLayoutController.swift
//  TabTool
//
//  Created by Lukas Stabe on 19.12.15.
//  Copyright © 2015 2C. All rights reserved.
//

import UIKit

public struct FlowLayoutSectionMetrics: SectionMetrics {
    public init() {}
    public var insets: UIEdgeInsets = UIEdgeInsets.zero
    public var minimumLineSpacing: CGFloat = 0
    public var minimumInteritemSpacing: CGFloat = 0
    public var headerSize: CGSize = CGSize.zero
    public var footerSize: CGSize = CGSize.zero
    public var hasCellSeparators = false
    public var separatorColor = UIColor(red: 0.78, green: 0.78, blue: 0.8, alpha: 1)
    public var shouldStretchCells = true
}

public struct FlowLayoutItemMetrics: ItemMetrics {
    public init() {}
    public var size: CGSize = CGSize(width: 320, height: 43)
}

open class SauceFlowLayoutController: SauceCollectionViewController, UICollectionViewDelegateFlowLayout {

    fileprivate func _itemMetrics(_ indexPath: IndexPath, _ collectionView: UICollectionView, _ layout: UICollectionViewLayout) -> FlowLayoutItemMetrics {
        let m = dataSource.metricsForItemAt(indexPath, collectionView: collectionView, layout: layout)
        guard let metrics = m as? FlowLayoutItemMetrics else {
            fatalError("dataSource of SauceFlowLayoutController's collectionView needs to return FlowLayoutItemMetrics")
        }
        return metrics
    }

    fileprivate func _sectionMetrics(_ section: Int, _ collectionView: UICollectionView, _ layout: UICollectionViewLayout) -> FlowLayoutSectionMetrics {
        let m = dataSource.metricsForSection(section, collectionView: collectionView, layout: layout)
        guard let metrics = m as? FlowLayoutSectionMetrics else {
            fatalError("dataSource of SauceFlowLayoutController's collectionView needs to return FlowLayoutSectionMetrics")
        }
        return metrics
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return _itemMetrics(indexPath, collectionView, collectionViewLayout).size
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return _sectionMetrics(section, collectionView, collectionViewLayout).insets
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return _sectionMetrics(section, collectionView, collectionViewLayout).minimumLineSpacing
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return _sectionMetrics(section, collectionView, collectionViewLayout).minimumInteritemSpacing
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return _sectionMetrics(section, collectionView, collectionViewLayout).headerSize
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return _sectionMetrics(section, collectionView, collectionViewLayout).footerSize
    }
}
