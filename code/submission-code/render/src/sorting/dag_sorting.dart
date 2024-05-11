// TODO: build custom sorting algorithm which can handle the partial order and ignores cycles.

// TODO: go into ProcessItem once done and replace the sorting algorithm it uses there with this one.


import 'package:drender/src/extensions.dart';

import '../process_items.dart';

List<E> sortPreorder<E>(Iterable<E> items, Comparator<E> compare) {
  final graph = _generateGraph(items, compare, skipReflexive: true);
  // print(graph);
  final order = _destructivelyGetATotalOrder(graph);
  // print('order: ${order.map((e) => e is ProcessItem ? e.label : e)}');

  return order;
}

_Graph<E> _generateGraph<E>(Iterable<E> items, Comparator<E> compare,
    {bool skipReflexive = true}) {
  final graph = _Graph<E>(values: items);

  for (final nodeA in graph.nodes) {
    for (final nodeB in graph.nodes) {
      if (skipReflexive && nodeA == nodeB) continue;

      final res = compare(nodeA.value, nodeB.value);

      if (res < 0)
        nodeA.addEdgeTo(nodeB);
      else if (res > 0) nodeA.addEdgeFrom(nodeB);
    }
  }

  return graph;
}

void _removeReflexiveEdges<E>(_Graph<E> graph) {
  for (final node in graph.nodes) {
    node.removeEdgeTo(node);
  }
}

// void _makeAcyclic<E>(_Graph<E> graph) {
//   final Set<_Node<E>> toVisit = graph.nodes;
//   visited(_Node<E> node) => !toVisit.contains(node);
//   final bfsToVisit = [];
//
//   for (final node in toVisit) {
//     while (bfsToVisit.isNotEmpty) {
//       toVisit.add(node);
//     }
//   }
// }

// Modifies graph.
List<E> _destructivelyGetATotalOrder<E>(_Graph<E> graph) {
  final Set<_Node<E>> toVisit = graph.nodes.copy();
  final List<_Node<E>> noInEdgesQueue =
      graph.nodes.where((node) => node.from.isEmpty).toList();
  final List<E> result = [];

  while (toVisit.isNotEmpty) {
    while (noInEdgesQueue.isNotEmpty) {
      final node = noInEdgesQueue.removeAt(0);
      if (!toVisit.contains(node)) {
        continue;
      }
      result.add(node.value);
      toVisit.remove(node);
      for (final toNode in node.to) {
        toNode.removeEdgeFrom(node);
        if (toNode.from.isEmpty) {
          noInEdgesQueue.add(toNode);
        }
      }
    }
    if (toVisit.isNotEmpty) {
      noInEdgesQueue.add(toVisit.first);
    }
  }

  return result;
}

class _Graph<E> {
  _Graph({Iterable<E>? values}) {
    values?.forEach((value) => newNode(value));
  }

  final Set<_Node<E>> _nodes = {};

  Set<_Node<E>> get nodes => _nodes.immutable();

  void addNode(_Node<E> node) => _nodes.add(node);

  void removeNode(_Node<E> node) {
    if (_nodes.contains(node)) return;
    node.removeAllEdges();
    _nodes.remove(node);
  }

  _Node<E> newNode(E value) => _Node<E>(this, value);

  @override
  String toString() {
    return 'Graph:\n  ${nodes.map((e) => e.toString()).join('\n  ')}';
  }
}

class _Node<E> {
  _Node(
    this.graph,
    this.value, {
    Iterable<_Node<E>>? to,
    Iterable<_Node<E>>? from,
  })  : _to = Set.from(to ?? <_Node<E>>[]),
        _from = Set.from(from ?? <_Node<E>>[]) {
    graph.addNode(this);
  }

  final _Graph<E> graph;
  final E value;
  final Set<_Node<E>> _to;
  final Set<_Node<E>> _from;

  Set<_Node<E>> get to => _to.immutable();

  Set<_Node<E>> get from => _from.immutable();

  void addEdgeTo(_Node<E> other) {
    _to.add(other);
    other._from.add(this);
  }

  void removeEdgeTo(_Node<E> other) {
    _to.remove(other);
    other._from.remove(this);
  }

  void addEdgeFrom(_Node<E> other) {
    _from.add(other);
    other._to.add(this);
  }

  void removeEdgeFrom(_Node<E> other) {
    _from.remove(other);
    other._to.remove(this);
  }

  void removeAllEdges() {
    _to.copy().forEach(removeEdgeTo);
    _from.copy().forEach(removeEdgeFrom);
  }

  @override
  String toString() {
    return '$debugName -> ${to.map((e) => e.debugName).sorted().join(',')}';
  }

  // TODO: remove ?
  String get debugName {
    if (value is ProcessItem) {
      return (value as ProcessItem).label;
    }
    return value.toString();
  }
}
