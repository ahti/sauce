//
//  DataSource.swift
//  TabTool
//
//  Created by Lukas Stabe on 14.12.15.
//  Copyright © 2015 2C. All rights reserved.
//

import UIKit

public enum DataSourceAction {
    case insert([IndexPath])
    case delete([IndexPath])
    case reload([IndexPath])
    case move(from: IndexPath, to: IndexPath)

    case reloadSections([Int])
    case insertSection(Int)
    case deleteSection(Int)
    case moveSection(from: Int, to: Int)

    case batch(() -> Void)

    func actionMappingIndexPath(_ map: (IndexPath) -> IndexPath) -> DataSourceAction {
        switch self {
        case .batch:
            return self
        case .reloadSections(let sections):
            return .reloadSections(
                sections.map { map(IndexPath(index: $0))[0] }
            )
        case .insertSection(let i):
            return .insertSection(map(IndexPath(index: i))[0])
        case .deleteSection(let i):
            return .deleteSection(map(IndexPath(index: i))[0])
        case .moveSection(from: let f, to: let t):
            return .moveSection(from: map(IndexPath(index: f))[0], to: map(IndexPath(index: t))[0])
        case .insert(let ips):
            return .insert(ips.map(map))
        case .delete(let ips):
            return .delete(ips.map(map))
        case .reload(let ips):
            return .reload(ips.map(map))
        case .move(let from, let to):
            return .move(from: map(from), to: map(to))
        }
    }
}

public protocol DataSourceContainer: class {
    // this will contain methods that pass up changes form leaf sources
    // to the collection view
    var collectionView: UICollectionView? { get }
    func globalIndexPath(_ localIndexPath: IndexPath, inChild child: DataSource) -> IndexPath?
    func localIndexPath(_ globalIndexPath: IndexPath, inChild child: DataSource) -> IndexPath?
    func containingViewController() -> UIViewController?
    func dataSource(_ dataSource: DataSource, performed action: DataSourceAction)
}

extension DataSourceContainer {
    func globalIndexPath(_ localIndexPath: IndexPath, inChild child: DataSource) -> IndexPath? {
        return localIndexPath
    }

    func localIndexPath(_ globalIndexPath: IndexPath, inChild child: DataSource) -> IndexPath? {
        return globalIndexPath
    }
}

public protocol SectionMetrics {}

public protocol ItemMetrics {}

public protocol DataSource: UICollectionViewDataSource {
    func registerReusableViewsWith(_ collectionView: UICollectionView)

    weak var container: DataSourceContainer? { get set }

    // Implementations should return metrics appropriate for the layout.
    // Layouts should assert that metrics are of an appropriate type.
    // I'd love to find a way to express this better using generics, but
    // I couldn't think of one.
    func metricsForSection(_ section: Int, collectionView: UICollectionView, layout: UICollectionViewLayout) -> SectionMetrics
    func metricsForItemAt(_ indexPath: IndexPath, collectionView: UICollectionView, layout: UICollectionViewLayout) -> ItemMetrics

    // delegate can use this to decide what to do in -didSelect...
    // if your dataSource does not represent any items or you don't
    // ever use this on your own, just return nil
    func itemAt(_ indexPath: IndexPath, collectionView: UICollectionView) -> Any?

    func canEditItemAt(_ indexPath: IndexPath) -> Bool

    var editing: Bool { get set }
}

private struct DummyMetrics: SectionMetrics, ItemMetrics { }

extension DataSource {
    var containingViewController: UIViewController? {
        return container?.containingViewController()
    }

    var collectionView: UICollectionView? {
        return container?.collectionView
    }

    func globalIndexPath(_ localIndexPath: IndexPath) -> IndexPath? {
        return container?.globalIndexPath(localIndexPath, inChild: self)
    }

    func localIndexPath(_ globalIndexPath: IndexPath) -> IndexPath? {
        return container?.localIndexPath(globalIndexPath, inChild: self)
    }

    func perform(_ action: DataSourceAction) {
        container?.dataSource(self, performed: action)
    }

    func metricsForSection(_ section: Int, collectionView: UICollectionView, layout: UICollectionViewLayout) -> SectionMetrics {
        return DummyMetrics()
    }

    func metricsForItemAt(_ indexPath: IndexPath, collectionView: UICollectionView, layout: UICollectionViewLayout) -> ItemMetrics {
        return DummyMetrics()
    }

    func canEditItemAt(_ indexPath: IndexPath) -> Bool {
        return false
    }

    func itemAt(_ indexPath: IndexPath, collectionView: UICollectionView) -> Any? {
        return nil
    }
}
