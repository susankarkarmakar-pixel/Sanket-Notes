import 'package:flutter/material.dart';
import '../models/notebook.dart';
import '../services/database_service.dart';

class NotebookManagerScreen extends StatefulWidget {
  const NotebookManagerScreen({Key? key}) : super(key: key);

  @override
  NotebookManagerScreenState createState() => NotebookManagerScreenState();
}

class NotebookManagerScreenState extends State<NotebookManagerScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Notebook> _notebooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotebooks();
  }

  Future<void> _loadNotebooks() async {
    setState(() => _isLoading = true);
    final notebooks = await _dbService.getNotebooks();
    setState(() {
      _notebooks = notebooks;
      _isLoading = false;
    });
  }

  Future<void> _createNotebook() async {
    final TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Notebook'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Notebook Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _dbService.insertNotebook(Notebook(name: controller.text));
                if (!mounted) return;
                Navigator.pop(context);
                _loadNotebooks();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameNotebook(Notebook notebook) async {
    final TextEditingController controller = TextEditingController(text: notebook.name);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Notebook'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Notebook Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty && controller.text != notebook.name) {
                await _dbService.updateNotebook(Notebook(id: notebook.id, name: controller.text));
                if (!mounted) return;
                Navigator.pop(context);
                _loadNotebooks();
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNotebook(Notebook notebook) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notebook?'),
        content: Text('Are you sure you want to delete "${notebook.name}"? Notes inside will not be deleted, but will be unassigned.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && notebook.id != null) {
      await _dbService.deleteNotebook(notebook.id!);
      _loadNotebooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Notebooks'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notebooks.isEmpty
              ? const Center(child: Text('No notebooks yet.'))
              : ListView.builder(
                  itemCount: _notebooks.length,
                  itemBuilder: (context, index) {
                    final notebook = _notebooks[index];
                    return ListTile(
                      leading: const Icon(Icons.book),
                      title: Text(notebook.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _renameNotebook(notebook),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteNotebook(notebook),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _createNotebook,
      ),
    );
  }
}
