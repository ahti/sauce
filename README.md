# Sauce

Sauce allows you to write simple, reusable collection view data sources. It is a
work in progress. I use it in a production app, but the API is quite quirky and
has some limitations. When used correctly, it makes complex collection view
sources easy to build. Use with care.

## Usage

Subclass `SauceFlowLayoutController` for your controller. Create data sources by
either implementing `DataSource` or subclassing one of the existing sources
(probably `ArrayDataSource`). Other sources can be used to alter or compose
existing sources.

Implement `registerReusableViewsWith(_:)` to register your sources cell types
with the collection view. Implement
`metricsForSection(_:collectionView:layout:)` and
`metricsForItemAt(_:collectionView:layout:)` to provide layout information. Be
aware that currently, these two can be called many times, so they should be
cheap (cache calculated sizes if necessary).

## Sources

- `ArrayDataSource`: Backed by an array. One cell per item. Implement
  `loadInitialItems()` and `collectionView(_:cellForItem:atIndexPath:)`.
- `ComposedDataSource`: Concatenates multiple sources. Use as is or subclass.
- `FilteredDataSource`: Filters cells of a wrapped source. Implement and pass a
  `Filter`.

## Pitfalls

Index paths passed into your sources methods are local to you index source. If
you put multiple sources into a `ComposedDataSource`, each one will still get
`IndexPath(0, 0)` for its first item.

If you need to pass index paths to the collection view (e.g. for dequeueing
cells), pass them through `globalIndexPath(_:)` first. If it returns nil, the
cell is not actually visible to the collection view (e.g. it may be filtered
out).
