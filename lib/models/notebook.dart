class Notebook {
  final int? id;
  final String name;

  Notebook({
    this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Notebook.fromMap(Map<String, dynamic> map) {
    return Notebook(
      id: map['id'],
      name: map['name'],
    );
  }
}
