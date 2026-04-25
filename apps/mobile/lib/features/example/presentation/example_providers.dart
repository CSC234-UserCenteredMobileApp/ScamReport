import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../data/example_api.dart';
import '../data/example_repository.dart';
import '../domain/example_item.dart';

final exampleApiProvider = Provider<ExampleApi>((ref) {
  return ExampleApi(ref.watch(httpClientProvider));
});

final exampleRepositoryProvider = Provider<ExampleRepository>((ref) {
  return ExampleRepository(ref.watch(exampleApiProvider));
});

final exampleListProvider = FutureProvider<List<ExampleItem>>((ref) {
  return ref.watch(exampleRepositoryProvider).fetchAll();
});
