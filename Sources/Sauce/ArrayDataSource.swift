//
//  ArrayDataSource.swift
//  TabTool
//
//  Created by Lukas Stabe on 05.01.16.
//  Copyright © 2016 2C. All rights reserved.
//

import UIKit

private func diffForCollectionViewBatch<T>(oldItems: [T], newItems: [T]) -> (deleted: [Int], inserted: [Int], moved: [(Int, Int)]) where T: Hashable {
    let deletedIndexes = oldItems.enumerated().reversed().filter { (_, element) in
        !newItems.contains(element)
    }.map {
        $0.offset
    }

    let insertedIndexes = newItems.enumerated().filter {
        !oldItems.contains($0.element)
    }.map {
        $0.offset
    }

    let movedIndexes = oldItems.enumerated().filter { (_, element) in
        newItems.contains(element)
    }.map { (offset, element) -> (Int, Int) in
        guard let index = newItems.index(of: element), index != NSNotFound else {
            fatalError()
        }
        return (offset, index)
    }

    return (deletedIndexes, insertedIndexes, movedIndexes)
}

struct CollectionViewDiff {
    private let deleted: [Int]
    private let inserted: [Int]
    private let moved: [(Int, Int)]
    init<T: Hashable>(old: [T], new: [T]) {
        let d = diffForCollectionViewBatch(oldItems: old, newItems: new)
        deleted = d.deleted
        inserted = d.inserted
        moved = d.moved
    }

    func perform(on source: DataSource, section: Int = 0) {
        let intToIp = { IndexPath(item: $0, section: section) }
        let intsToIps = { (a: Int, b: Int) in (intToIp(a), intToIp(b)) }

        var (del, ins, mov) = (deleted.map(intToIp), inserted.map(intToIp), moved.map(intsToIps))

        if del.count + ins.count == 0 {
            // nothing inserted or deleted, so we can filter moves easily
            mov = mov.filter {
                return $0 != $1
            }
        }

        if del.count + ins.count + mov.count == 0 { return }
        source.perform(.batch {
            if del.count > 0 {
                source.perform(.delete(del))
            }
            if ins.count > 0 {
                source.perform(.insert(ins))
            }
            for m in mov {
                source.perform(.move(from: m.0, to: m.1))
            }
        })
    }

    func performOnSections(on source: DataSource, offset: Int = 0) {
        var (del, ins, mov) = (deleted, inserted, moved)

        if del.count + ins.count == 0 {
            // nothing inserted or deleted, so we can filter moves easily
            mov = mov.filter {
                return $0 != $1
            }
        }

        if del.count + ins.count + mov.count == 0 { return }
        source.perform(.batch {
            for d in del {
                source.perform(.deleteSection(d + offset))
            }
            for i in ins {
                source.perform(.insertSection(i + offset))
            }
            for m in mov {
                source.perform(.moveSection(from: m.0 + offset, to: m.1 + offset))
            }
        })
    }
}

public class ArrayDataSource<T>: NSObject, DataSource where T: Hashable {
    weak var container: DataSourceContainer?

    var editing: Bool = false

    fileprivate var lazyItems: [T]?
    var items: [T] {
        guard let items = lazyItems else {
            let items = loadInitialItems()
            lazyItems = items
            return items
        }
        return items
    }
    fileprivate var itemsLoaded: Bool {
        return lazyItems != nil
    }

    fileprivate subscript (index: Int) -> T {
        return items[index]
    }

    subscript (indexPath: IndexPath) -> T {
        return self[(indexPath as NSIndexPath).item]
    }

    func indexOfItem(_ item: T) -> Int {
        guard let index = items.index(of: item)
            else { fatalError("tried to get index of item not contained \(item)") }

        return index
    }

    func indexPathOfItem(_ item: T) -> IndexPath {
        return IndexPath(item: indexOfItem(item), section: 0)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItem item: T, atIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        fatalError()
    }

    func loadInitialItems() -> [T] { fatalError() }
    func updateItems(_ newItems: [T]) {
        let oldItems = lazyItems
        lazyItems = newItems

        let diff = CollectionViewDiff(old: oldItems ?? [], new: newItems)
        diff.perform(on: self)
    }

    // MARK: - UICollectionViewDataSource
    // these need to be in here, because otherwise (in an extension) we get a "non objc method cannot satisfy requirement" error

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return self.collectionView(collectionView, cellForItem: self[indexPath], atIndexPath: indexPath)
    }

    // MARK: - DataSource
    // these need to be here because "declarations in extensions cannot be overridden yet

    func registerReusableViewsWith(_ collectionView: UICollectionView) { fatalError() }
    func metricsForSection(_ section: Int, collectionView: UICollectionView, layout: UICollectionViewLayout) -> SectionMetrics { fatalError() }
    func metricsForItemAt(_ indexPath: IndexPath, collectionView: UICollectionView, layout: UICollectionViewLayout) -> ItemMetrics { fatalError() }

    func canEditItemAt(_ indexPath: IndexPath) -> Bool {
        return false
    }

    func itemAt(_ indexPath: IndexPath, collectionView: UICollectionView) -> Any? {
        return self[indexPath]
    }
}
