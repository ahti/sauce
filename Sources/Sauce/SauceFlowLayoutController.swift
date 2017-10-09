//
//  SauceFlowLayoutController.swift
//  TabTool
//
//  Created by Lukas Stabe on 19.12.15.
//  Copyright © 2015 2C. All rights reserved.
//

import UIKit

struct FlowLayoutSectionMetrics: SectionMetrics {
    var insets: UIEdgeInsets = UIEdgeInsets.zero
    var minimumLineSpacing: CGFloat = 0
    var minimumInteritemSpacing: CGFloat = 0
    var headerSize: CGSize = CGSize.zero
    var footerSize: CGSize = CGSize.zero
    var hasCellSeparators = false
    var separatorColor = UIColor(red: 0.78, green: 0.78, blue: 0.8, alpha: 1)
    var shouldStretchCells = true
}

struct FlowLayoutItemMetrics: ItemMetrics {
    var size: CGSize = CGSize(width: 320, height: 43)
}

class SauceFlowLayoutController: SauceCollectionViewController, UICollectionViewDelegateFlowLayout {

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

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return _itemMetrics(indexPath, collectionView, collectionViewLayout).size
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return _sectionMetrics(section, collectionView, collectionViewLayout).insets
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return _sectionMetrics(section, collectionView, collectionViewLayout).minimumLineSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return _sectionMetrics(section, collectionView, collectionViewLayout).minimumInteritemSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return _sectionMetrics(section, collectionView, collectionViewLayout).headerSize
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return _sectionMetrics(section, collectionView, collectionViewLayout).footerSize
    }
}
