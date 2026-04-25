import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'example_providers.dart';

class ExampleScreen extends ConsumerWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(exampleListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Examples')),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (items) => RefreshIndicator(
          onRefresh: () async => ref.refresh(exampleListProvider.future),
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) => ListTile(
              title: Text(items[i].name),
              subtitle: Text('id: ${items[i].id}'),
            ),
          ),
        ),
      ),
    );
  }
}
