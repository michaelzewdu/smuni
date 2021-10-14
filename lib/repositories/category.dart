import 'dart:async';
import 'dart:collection';

import 'package:smuni/models/models.dart';
import 'package:smuni/providers/cache/cache.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'auth.dart';
import 'repositories.dart';

class ApiCategoryRepository extends Repository<String, Category,
    CreateCategoryInput, UpdateCategoryInput> {
  final Cache<String, Category> cache;
  final SmuniApiClient client;
  final AuthTokenRepository tokenRepo;

  final StreamController<Set<String>> _changedItemsController =
      StreamController.broadcast();

  ApiCategoryRepository(this.cache, this.client, this.tokenRepo);

  @override
  Stream<Set<String>> get changedItems => _changedItemsController.stream;

  @override
  Future<Category?> getItem(String id) async {
    var item = await cache.getItem(id);
    if (item != null) return item;
    try {
      final token = await tokenRepo.accessToken;
      item = await client.getCategory(id, tokenRepo.username, token);
      await cache.setItem(id, item);
      return item;
    } on EndpointError catch (e) {
      if (e.type == "CategoryNotFound") return null;
    }
  }

  @override
  Future<Category> updateItem(String id, UpdateCategoryInput input) async {
    if (input.isEmpty) {
      final old = await getItem(id);
      if (old == null) throw ItemNotFoundException(id);
      return old;
    }

    final token = await tokenRepo.accessToken;
    final item =
        await client.updateCategory(id, tokenRepo.username, token, input);

    await cache.setItem(id, item);
    _changedItemsController.add({id});
    _ancestryGraph = null;
    return item;
  }

  @override
  Future<Category> createItem(CreateCategoryInput input, [String? id]) async {
    final token = await tokenRepo.accessToken;
    final item = await client.createCategory(tokenRepo.username, token, input);

    await cache.setItem(item.id, item);
    _changedItemsController.add({item.id});
    _ancestryGraph = null;
    return item;
  }

  Future<void> deleteItem(
    String id,
  ) async {
    final token = await tokenRepo.accessToken;
    await client.deleteCategory(
      id,
      tokenRepo.username,
      token,
    );
    await cache.removeItem(id);
    _changedItemsController.add({id});
  }

  @override
  Future<Map<String, Category>> getItems() => cache.getItems();

  @override
  Future<void> removeItem(String id) async {
    final token = await tokenRepo.accessToken;
    await client.deleteCategory(
      id,
      tokenRepo.username,
      token,
    );
    await cache.removeItem(id);
    _changedItemsController.add({id});
  }

  @override
  UpdateCategoryInput updateFromDiff(Category update, Category old) {
    return UpdateCategoryInput.fromDiff(update: update, old: old);
  }

  Future<Map<String, TreeNode<String>>>? _ancestryGraph;
  Future<Map<String, TreeNode<String>>> get ancestryGraph =>
      _ancestryGraph ??= _calcAncestryTree();

  // FIXME: fix this func
  Future<Map<String, TreeNode<String>>> _calcAncestryTree() async {
    Map<String, TreeNode<String>> nodes = HashMap();
    final items = await getItems();

    TreeNode<String> getTreeNode(Category category) {
      var node = nodes[category.id];
      if (node == null) {
        TreeNode<String>? parentNode;
        if (category.parentId != null) {
          final parent = items[category.parentId];
          if (parent == null) {
            throw Exception("parent not found at id: $category.parentId");
          }
          parentNode = getTreeNode(parent);
          parentNode.children.add(category.id);
        }
        node = TreeNode(category.id, children: [], parent: parentNode);
        nodes[category.id] = node;
      }
      return node;
    }

    for (final category in items.values) {
      if (!nodes.containsKey(category.id)) {
        getTreeNode(category);
      }
    }
    return nodes;
  }

  /// The returned list includes the given id.
  /// Returns null if no category found under id.
  Future<List<String>?> getCategoryDescendantsTree(String forId) async {
    final graph = await ancestryGraph;
    final rootNode = graph[forId];
    if (rootNode == null) return null;

    List<String> descendants = [forId];
    void appendChildren(TreeNode<String> node) {
      descendants.addAll(node.children);
      for (final child in node.children) {
        final childNode = graph[child];
        if (childNode == null) {
          throw Exception("childNode not found in ancestryGraph at id: $child");
        }
        appendChildren(childNode);
      }
    }

    appendChildren(rootNode);

    return descendants;
  }

  @override
  CreateCategoryInput createFromItem(Category item) => CreateCategoryInput(
        name: item.name,
        parentId: item.parentId,
        tags: item.tags,
      );
}
