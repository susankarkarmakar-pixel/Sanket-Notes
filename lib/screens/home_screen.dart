import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/notebook.dart';
import '../services/database_service.dart';
import 'note_editor_screen.dart';
import 'tag_manager_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Note> _notes = [];
  List<Notebook> _notebooks = [];
  bool _isLoading = true;
  int? _selectedNotebookId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final notebooks = await _dbService.getNotebooks();

    List<Note> notes;
    if (_selectedNotebookId == null) {
      notes = await _dbService.getNotes();
    } else {
      notes = await _dbService.getNotesByNotebook(_selectedNotebookId!);
    }

    setState(() {
      _notebooks = notebooks;
      _notes = notes;
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
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  String _getPlainText(String content) {
    try {
      final doc = jsonDecode(content);
      // Quick way to extract text from quill delta JSON without initializing a controller
      String text = '';
      for (var item in doc) {
        if (item['insert'] is String) {
          text += item['insert'];
        }
      }
      return text;
    } catch (e) {
      return content;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sanket Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {}, // TODO: Search functionality
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Sanket Notes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.note),
              title: const Text('All Notes'),
              selected: _selectedNotebookId == null,
              onTap: () {
                setState(() => _selectedNotebookId = null);
                Navigator.pop(context);
                _loadData();
              },
            ),
            const Divider(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.label),
              title: const Text('Manage Tags'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TagManagerScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Notebooks', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: _createNotebook,
              ),
            ),
            ..._notebooks.map((notebook) => ListTile(
                  leading: const Icon(Icons.book),
                  title: Text(notebook.name),
                  selected: _selectedNotebookId == notebook.id,
                  onTap: () {
                    setState(() => _selectedNotebookId = notebook.id);
                    Navigator.pop(context);
                    _loadData();
                  },
                )),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(child: Text('No notes yet. Create one!'))
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return ListTile(
                      title: Text(note.title.isNotEmpty ? note.title : 'Untitled Note'),
                      subtitle: Text(
                        _getPlainText(note.content),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoteEditorScreen(note: note),
                          ),
                        );
                        _loadData();
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditorScreen(notebookId: _selectedNotebookId),
            ),
          );
          _loadData();
        },
      ),
    );
  }
}
