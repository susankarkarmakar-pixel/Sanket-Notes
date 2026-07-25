class Note {
  final int? id;
  final String title;
  final String content;
  final String plainTextContent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? notebookId;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.plainTextContent,
    required this.createdAt,
    required this.updatedAt,
    this.notebookId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'plainTextContent': plainTextContent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notebookId': notebookId,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      plainTextContent: map['plainTextContent'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      notebookId: map['notebookId'],
    );
  }
}
