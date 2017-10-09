//
//  ComposedDataSource.swift
//  TabTool
//
//  Created by Lukas Stabe on 19.12.15.
//  Copyright © 2015 2C. All rights reserved.
//

import UIKit

class ComposedDataSource: NSObject, UICollectionViewDataSource, DataSource, DataSourceContainer {
    weak var container: DataSourceContainer?

    var movingEnabled = false

    var children: [DataSource] = []

    var mapping: [(DataSource, Int)] = []
    var mappingUpToDate = false

    var editing: Bool = false {
        didSet {
            for c in children {
                c.editing = editing
            }
        }
    }

    func updateMapping() {
        if mappingUpToDate {
            return
        }

        guard let cv = container?.collectionView else { fatalError() }
        mapping = []
        for s in children {
            let sections = s.numberOfSections!(in: cv)
            mapping += [(s, sections)]
        }
        mappingUpToDate = true
    }

    func add(_ ds: DataSource, atIndex index: Int? = nil) {
        guard !children.contains(where: { $0 === ds }) else {
            return
        }
        ds.container = self
        ds.editing = self.editing
        if let index = index {
            children.insert(ds, at: index)
        } else {
            children += [ds]
        }
        mappingUpToDate = false
        if let cv = container?.collectionView {
            ds.registerReusableViewsWith(cv)
            let newSections = self.sectionIndices(dataSource: ds)
            perform(.batch({
                for s in newSections { self.perform(.insertSection(s)) }
            }))
        }
    }

    func remove(_ ds: DataSource) {
        guard let index = children.index(where: { $0 === ds }) else { return }
        ds.container = nil
        var oldSections: [Int]!
        if container?.collectionView != nil {
            oldSections = sectionIndices(dataSource: ds)
        }
        children.remove(at: index)
        mappingUpToDate = false
        if container?.collectionView != nil {
            perform(.batch({
                for s in oldSections { self.perform(.deleteSection(s)) }
            }))
        }
    }

    func updateChildren(_ newChildren: [DataSource]) {
        // don't do any unnecessary work if nothing changed
        // most importantly, calling perform(...) can be very expensive
        // with a big number of cells, since it triggers sizing calculations
        guard !newChildren.elementsEqual(children, by: ===) else { return }

        let added = newChildren.filter { s in !children.contains { $0 === s } }
        let deleted = children.filter { s in !newChildren.contains { $0 === s } }
        let remaining = newChildren.filter { s in children.contains { $0 === s } }

        let hasCv = container?.collectionView != nil

        let prevIndices = hasCv ? remaining.map { ($0, sectionIndices(dataSource: $0)) } : nil
        let deletedIndices = hasCv ? deleted.map { sectionIndices(dataSource: $0) } : nil

        for a in added {
            a.container = self
            a.editing = self.editing
        }

        for d in deleted {
            d.container = nil
        }

        children = newChildren
        mappingUpToDate = false

        guard let cv = collectionView else { return }

        for source in added {
            source.registerReusableViewsWith(cv)
        }

        perform(.batch {
            for index in deletedIndices!.joined() {
                self.perform(.deleteSection(index))
            }

            for (source, oldIndices) in prevIndices! {
                let newIndices = self.sectionIndices(dataSource: source)
                for (from, to) in zip(oldIndices, newIndices) {
                    self.perform(.moveSection(from: from, to: to))
                }
            }

            for index in added.flatMap({ self.sectionIndices(dataSource: $0) }) {
                self.perform(.insertSection(index))
            }
        })
    }

    func indexOf(_ ds: DataSource) -> Int {
        return children.index { $0 === ds }!
    }

    func sectionIndices(dataSource: DataSource) -> [Int] {
        updateMapping()
        var base = 0
        for (s, num) in mapping {
            guard s === dataSource else {
                base += num
                continue
            }
            return Array(base..<(base + num))
        }
        fatalError("expected to find child source \(dataSource)")
    }

    func childSource(at ip: IndexPath) -> DataSource? {
        updateMapping()
        var acc = 0
        for (source, num) in mapping {
            let firstSectionOfNextSource = acc + num
            if ip[0] < firstSectionOfNextSource {
                return source
            }
            acc += num
        }
        return nil
    }

    func map(_ section: Int) -> (DataSource, Int) {
        updateMapping()
        var acc = 0
        for (source, num) in mapping {
            let firstSectionOfNextSource = acc + num
            if section < firstSectionOfNextSource {
                return (source, section - acc)
            }
            acc += num
        }
        fatalError()
    }

    func map(_ indexPath: IndexPath) -> (DataSource, IndexPath) {
        let (source, newSection) = map((indexPath as NSIndexPath).section)
        return (source, IndexPath(item: (indexPath as NSIndexPath).item, section: newSection))
    }

    func unmap(_ section: Int, inSource containingSource: DataSource) -> Int {
        updateMapping()
        var acc = 0
        for (source, num) in mapping {
            if source === containingSource {
                return acc + section
            }
            acc += num
        }
        fatalError()
    }

    func unmap(_ indexPath: IndexPath, inSource containingSource: DataSource) -> IndexPath {
        let newSection = unmap((indexPath as NSIndexPath).section, inSource: containingSource)
        return IndexPath(item: (indexPath as NSIndexPath).item, section: newSection)
    }

    // only act like we support moving when configured to do so, because
    // the collectionView will behave differently when these methods are
    // implemented
    override func responds(to aSelector: Selector) -> Bool {
        switch aSelector {
        case #selector(UICollectionViewDataSource.collectionView(_:canMoveItemAt:)): fallthrough
        case #selector(UICollectionViewDataSource.collectionView(_:moveItemAt:to:)):
            return movingEnabled
        default:
            return super.responds(to: aSelector)
        }
    }

    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let (source, mappedSection) = map(section)
        return source.collectionView(collectionView, numberOfItemsInSection: mappedSection)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let (source, path) = map(indexPath)
        return source.collectionView(collectionView, cellForItemAt: path)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        updateMapping()
        let counts = mapping.map({ $0.1 })
        let num = counts.reduce(0, +)
        return num
    }

    @objc func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let (source, path) = map(indexPath)
        return source.collectionView!(collectionView, viewForSupplementaryElementOfKind: kind, at: path)
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        let (source, path) = map(indexPath)
        return source.collectionView?(collectionView, canMoveItemAt: path) ?? false
    }

    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let (source, sourcePath) = map(sourceIndexPath)
        let (otherSource, destPath) = map(destinationIndexPath)

        guard source === otherSource else { fatalError("can't move between sources") }

        source.collectionView?(collectionView, moveItemAt: sourcePath, to: destPath)
    }

    // MARK: DataSource
    func registerReusableViewsWith(_ collectionView: UICollectionView) {
        for c in children {
            c.registerReusableViewsWith(collectionView)
        }
    }

    func metricsForSection(_ section: Int, collectionView: UICollectionView, layout: UICollectionViewLayout) -> SectionMetrics {
        let (source, mappedSection) = map(section)
        return source.metricsForSection(mappedSection, collectionView: collectionView, layout: layout)
    }

    func metricsForItemAt(_ indexPath: IndexPath, collectionView: UICollectionView, layout: UICollectionViewLayout) -> ItemMetrics {
        let (source, mappedIndexPath) = map(indexPath)
        return source.metricsForItemAt(mappedIndexPath, collectionView: collectionView, layout: layout)
    }

    func itemAt(_ indexPath: IndexPath, collectionView: UICollectionView) -> Any? {
        let (source, mappedIndexPath) = map(indexPath)
        return source.itemAt(mappedIndexPath, collectionView: collectionView)
    }

    func canEditItemAt(_ indexPath: IndexPath) -> Bool {
        let (source, mappedIndexPath) = map(indexPath)
        return source.canEditItemAt(mappedIndexPath)
    }

    // MARK: DataSourceContainer
    var collectionView: UICollectionView? {
        return container?.collectionView
    }

    func containingViewController() -> UIViewController? {
        return container?.containingViewController()
    }

    func globalIndexPath(_ localIndexPath: IndexPath, inChild child: DataSource) -> IndexPath? {
        return container?.globalIndexPath(unmap(localIndexPath, inSource: child), inChild: self)
    }

    func localIndexPath(_ globalIndexPath: IndexPath, inChild child: DataSource) -> IndexPath? {
        guard let fromContainer = container?.localIndexPath(globalIndexPath, inChild: self) else { return nil }
        let (source, localIP) = map(fromContainer)
        guard source === child else { fatalError() }
        return localIP
    }

    func dataSource(_ dataSource: DataSource, performed action: DataSourceAction) {
        let ui: (IndexPath) -> IndexPath = { self.unmap($0, inSource: dataSource) }
        let us: (Int) -> Int = { self.unmap($0, inSource: dataSource) }

        container?.dataSource(self, performed: action.actionMappingIndexPath { $0.count == 1 ? [us($0[0])] : ui($0) })

        switch action {
        case .deleteSection(_), .insertSection(_):
            mappingUpToDate = false
        default: break
        }
    }
}
