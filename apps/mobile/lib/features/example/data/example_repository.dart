import '../domain/example_item.dart';
import 'example_api.dart';

class ExampleRepository {
  ExampleRepository(this._api);

  final ExampleApi _api;

  Future<List<ExampleItem>> fetchAll() => _api.fetchAll();
}
