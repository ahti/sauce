//
//  FilteredDataSource.swift
//  TabTool
//
//  Created by Lukas Stabe on 11.06.16.
//  Copyright © 2016 2C. All rights reserved.
//

import Foundation

open class EmptySource: NSObject, DataSource {
    public weak var container: DataSourceContainer?
    public var editing: Bool = false
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        fatalError()
    }
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 0
    }
    open func metricsForSection(_ section: Int, collectionView: UICollectionView, layout: UICollectionViewLayout) -> SectionMetrics {
        fatalError()
    }
    open func metricsForItemAt(_ indexPath: IndexPath, collectionView: UICollectionView, layout: UICollectionViewLayout) -> ItemMetrics {
        fatalError()
    }

    open func canEditItemAt(_ indexPath: IndexPath) -> Bool { fatalError() }

    open func registerReusableViewsWith(_ collectionView: UICollectionView) {
        fatalError()
    }
}

class FilterHeaderSource: EmptySource {
    static let headerIdentifier = "FilterHeaderIdentifier"

    override func registerReusableViewsWith(_ collectionView: UICollectionView) {
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: FilterHeaderSource.headerIdentifier)
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    override func metricsForSection(_ section: Int, collectionView: UICollectionView, layout: UICollectionViewLayout) -> SectionMetrics {
        var m = FlowLayoutSectionMetrics()
        var s = searchBar.sizeThatFits(CGSize(width: 320, height: 40))
        s.height -= 8
        m.headerSize = s
        return m
    }

    let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.showsScopeBar = true
        return searchBar
    }()

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: IndexPath) -> UICollectionReusableView {
        let v = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FilterHeaderSource.headerIdentifier, for: globalIndexPath(indexPath)!)
        searchBar.removeFromSuperview()
        v.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.leftAnchor.constraint(equalTo: v.leftAnchor),
            searchBar.rightAnchor.constraint(equalTo: v.rightAnchor),
            searchBar.topAnchor.constraint(equalTo: v.topAnchor),
            searchBar.bottomAnchor.constraint(equalTo: v.bottomAnchor),
        ])
        return v
    }
}

class ContentSource<F>: ArrayDataSource<F.Element>, DataSourceContainer where F: Filter {
    typealias T = F.Element
    let wrappedSource: ArrayDataSource<T>
    let filter: F
    init(source: ArrayDataSource<T>, filter: F) {
        wrappedSource = source
        self.filter = filter
        self.scope = filter.scopes.first!.0

        super.init()

        wrappedSource.container = self
    }

    var searchString = "" {
        didSet {
            updateItems(loadInitialItems())
        }
    }
    var scope: F.Scope {
        didSet {
            updateItems(loadInitialItems())
        }
    }

    override func loadInitialItems() -> [T] {
        let unfiltered = wrappedSource.items
        return unfiltered.filter { filter.matchesElement($0, scope: scope, searchString: searchString) }
    }

    func mapIP(_ ip: IndexPath) -> IndexPath {
        let item = self[ip]
        return wrappedSource.indexPathOfItem(item)
    }

    // MARK: data source container

    var collectionViewIfLoaded: UICollectionView? {
        return container?.collectionViewIfLoaded
    }

    func containingViewController() -> UIViewController? {
        return container?.containingViewController()
    }

    func globalIndexPath(_ localIndexPath: IndexPath, inChild child: DataSource) -> IndexPath? {
        let el = wrappedSource[localIndexPath]
        return indexPathOfItem(el)
    }

    func localIndexPath(_ globalIndexPath: IndexPath, inChild child: DataSource) -> IndexPath? {
        let el = self[globalIndexPath]
        return wrappedSource.indexPathOfItem(el)
    }

    func dataSource(_ dataSource: DataSource, performed action: DataSourceAction) {
        container?.dataSource(self, performed: action.actionMappingIndexPath {
            globalIndexPath($0, inChild: wrappedSource)!
            })
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

    override func collectionView(_ collectionView: UICollectionView, cellForItem item: T, atIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        return wrappedSource.collectionView(collectionView, cellForItem: item, atIndexPath: mapIP(indexPath))
    }

    override func metricsForSection(_ section: Int, collectionView: UICollectionView, layout: UICollectionViewLayout) -> SectionMetrics {
        return wrappedSource.metricsForSection(section, collectionView: collectionView, layout: layout)
    }

    override func metricsForItemAt(_ indexPath: IndexPath, collectionView: UICollectionView, layout: UICollectionViewLayout) -> ItemMetrics {
        return wrappedSource.metricsForItemAt(mapIP(indexPath), collectionView: collectionView, layout: layout)
    }

    override func canEditItemAt(_ indexPath: IndexPath) -> Bool {
        return wrappedSource.canEditItemAt(mapIP(indexPath))
    }
}

protocol Filter {
    associatedtype Element: Hashable
    associatedtype Scope

    /// A list of tuples containing scopes and their interface names
    var scopes: [(Scope, String)] { get }
    func matchesElement(_ el: Element, scope: Scope, searchString: String) -> Bool
}

struct UnwrappingFilter<E, S, F: Filter>: Filter where F.Element == E, F.Scope == S {
    typealias Element = SelectableItem<E>
    typealias Scope = S

    let wrapped: F
    init(filter: F) {
        wrapped = filter
    }

    var scopes: [(S, String)] {
        return wrapped.scopes
    }

    func matchesElement(_ el: SelectableItem<E>, scope: Scope, searchString: String) -> Bool {
        return wrapped.matchesElement(el.item, scope: scope, searchString: searchString)
    }
}

class FilteredDataSource<F>: ComposedDataSource, UISearchBarDelegate where F: Filter {
    let filter: F
    let headerSource: FilterHeaderSource
    let contentSource: ContentSource<F>

    typealias T = F.Element

    var filteredItems: [T] {
        return contentSource.items
    }

    func indexPathOfItem(_ item: T) -> IndexPath {
        return unmap(contentSource.indexPathOfItem(item), inSource: contentSource)
    }

    init(source: ArrayDataSource<T>, filter: F) {
        self.filter = filter

        headerSource = FilterHeaderSource()
        contentSource = ContentSource(source: source, filter: filter)

        super.init()

        add(headerSource)
        add(contentSource)

        headerSource.searchBar.scopeButtonTitles = filter.scopes.map { $0.1 }
        headerSource.searchBar.delegate = self
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        contentSource.searchString = searchText
    }

    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        contentSource.scope = filter.scopes[selectedScope].0
    }
}
