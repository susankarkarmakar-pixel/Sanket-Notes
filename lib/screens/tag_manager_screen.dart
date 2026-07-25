import 'package:flutter/material.dart';
import '../models/tag.dart';
import '../services/database_service.dart';

class TagManagerScreen extends StatefulWidget {
  const TagManagerScreen({Key? key}) : super(key: key);

  @override
  _TagManagerScreenState createState() => _TagManagerScreenState();
}

class _TagManagerScreenState extends State<TagManagerScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Tag> _tags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('tags');
    final tags = List.generate(maps.length, (i) => Tag.fromMap(maps[i]));
    setState(() {
      _tags = tags;
      _isLoading = false;
    });
  }

  Future<void> _createTag() async {
    final TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Tag Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final db = await _dbService.database;
                await db.insert('tags', Tag(name: controller.text).toMap());
                Navigator.pop(context);
                _loadTags();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTag(int id) async {
    final db = await _dbService.database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
    _loadTags();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tags'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tags.isEmpty
              ? const Center(child: Text('No tags yet.'))
              : ListView.builder(
                  itemCount: _tags.length,
                  itemBuilder: (context, index) {
                    final tag = _tags[index];
                    return ListTile(
                      title: Text(tag.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteTag(tag.id!),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _createTag,
      ),
    );
  }
}
