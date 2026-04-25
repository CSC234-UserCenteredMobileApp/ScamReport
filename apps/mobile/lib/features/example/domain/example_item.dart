// TODO: replace with a generated type once scripts/codegen.sh is wired up.

class ExampleItem {
  const ExampleItem({required this.id, required this.name});

  final String id;
  final String name;

  factory ExampleItem.fromJson(Map<String, dynamic> json) {
    return ExampleItem(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
