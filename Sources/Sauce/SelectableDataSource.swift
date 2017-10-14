//
//  SelectableDataSource.swift
//  TabTool
//
//  Created by Lukas Stabe on 06.07.16.
//  Copyright © 2016 2C. All rights reserved.
//

import Foundation

func == <T>(lhs: SelectableItem<T>, rhs: SelectableItem<T>) -> Bool {
    return lhs === rhs
}

class SelectableItem<T>: Hashable where T: Hashable {
    let item: T
    var selected: Bool = false

    init(item: T) {
        self.item = item
    }

    var hashValue: Int {
        return item.hashValue
    }
}

// due to a bug in uicollectionview, view controller using this source will need to implement
// willDisplayCell, check the selectable item and then async dispatch to main to select the cell
// without animation.
class SelectableDataSource<T>: ArrayDataSource<SelectableItem<T>>, DataSourceContainer where T: Hashable {
    let wrappedSource: ArrayDataSource<T>
    init(source: ArrayDataSource<T>) {
        wrappedSource = source
        super.init()
        wrappedSource.container = self
    }

    override func loadInitialItems() -> [SelectableItem<T>] {
        return wrappedSource.items.map { SelectableItem(item: $0) }
    }

    var selectedItems: [T] {
        return items.filter { $0.selected }.map { $0.item }
    }

    var numberOfSelected: Int {
        return items.filter { $0.selected }.count
    }

    // MARK: data source container

    var collectionViewIfLoaded: UICollectionView? {
        return collectionView
    }

    func containingViewController() -> UIViewController? {
        return container?.containingViewController()
    }

    func globalIndexPath(_ localIndexPath: IndexPath, inChild child: DataSource) -> IndexPath? {
        return container?.globalIndexPath(localIndexPath, inChild: self)
    }

    func localIndexPath(_ globalIndexPath: IndexPath, inChild child: DataSource) -> IndexPath? {
        return container?.localIndexPath(globalIndexPath, inChild: self)
    }

    func dataSource(_ dataSource: DataSource, performed action: DataSourceAction) {
        container?.dataSource(self, performed: action)
    }

    // MARK: pass through data source methods to wrapped

    override var editing: Bool {
        get {
            return wrappedSource.editing
        }
        set {
            wrappedSource.editing = newValue
        }
    }

    override func registerReusableViewsWith(_ collectionView: UICollectionView) {
        wrappedSource.registerReusableViewsWith(collectionView)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItem item: SelectableItem<T>, atIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let cell = wrappedSource.collectionView(collectionView, cellForItem: item.item, atIndexPath: indexPath)

        return cell
    }

    override func metricsForSection(_ section: Int, collectionView: UICollectionView, layout: UICollectionViewLayout) -> SectionMetrics {
        return wrappedSource.metricsForSection(section, collectionView: collectionView, layout: layout)
    }

    override func metricsForItemAt(_ indexPath: IndexPath, collectionView: UICollectionView, layout: UICollectionViewLayout) -> ItemMetrics {
        return wrappedSource.metricsForItemAt(indexPath, collectionView: collectionView, layout: layout)
    }

    override func canEditItemAt(_ indexPath: IndexPath) -> Bool {
        return wrappedSource.canEditItemAt(indexPath)
    }
}
