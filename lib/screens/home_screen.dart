import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/notebook.dart';
import '../models/tag.dart';
import '../services/database_service.dart';
import 'note_editor_screen.dart';
import 'tag_manager_screen.dart';
import 'notebook_manager_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Note> _notes = [];
  List<Notebook> _notebooks = [];
  List<Tag> _tags = [];
  Map<int, List<Tag>> _noteTagsMap = {};

  bool _isLoading = true;
  bool _isSearching = false;

  int? _selectedNotebookId;
  int? _selectedTagId;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final notebooks = await _dbService.getNotebooks();
    final tags = await _dbService.getTags();

    final notes = await _dbService.searchNotes(
      _searchQuery,
      notebookId: _selectedNotebookId,
      tagId: _selectedTagId,
    );

    final Map<int, List<Tag>> noteTagsMap = {};
    for (var note in notes) {
        if (note.id != null) {
            noteTagsMap[note.id!] = await _dbService.getTagsForNote(note.id!);
        }
    }

    setState(() {
      _notebooks = notebooks;
      _tags = tags;
      _notes = notes;
      _noteTagsMap = noteTagsMap;
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
                if (!mounted) return;
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  String _getPreviewText(Note note) {
    String text = note.plainTextContent.replaceAll('\n', ' ').trim();
    if (text.length > 100) {
      return '${text.substring(0, 100)}...';
    }
    return text.isEmpty ? 'No additional text' : text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _loadData();
                },
              )
            : const Text('Sanket Notes'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                  _loadData();
                }
              });
            },
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
              selected: _selectedNotebookId == null && _selectedTagId == null,
              onTap: () {
                setState(() {
                  _selectedNotebookId = null;
                  _selectedTagId = null;
                });
                if (!mounted) return;
                Navigator.pop(context);
                _loadData();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.label),
              title: const Text('Manage Tags'),
              onTap: () {
                if (!mounted) return;
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TagManagerScreen()),
                ).then((_) => _loadData());
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Notebooks', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings, size: 20),
                    tooltip: 'Manage Notebooks',
                    onPressed: () {
                      if (!mounted) return;
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotebookManagerScreen()),
                      ).then((_) => _loadData());
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    tooltip: 'Add Notebook',
                    onPressed: _createNotebook,
                  ),
                ],
              ),
            ),
            ..._notebooks.map((notebook) => ListTile(
                  leading: const Icon(Icons.book),
                  title: Text(notebook.name),
                  selected: _selectedNotebookId == notebook.id,
                  onTap: () {
                    setState(() {
                      _selectedNotebookId = notebook.id;
                      // Allow selecting both notebook and tag
                    });
                    Navigator.pop(context);
                    _loadData();
                  },
                )),
            const Divider(),
            const ListTile(
              title: Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ..._tags.map((tag) => ListTile(
                  leading: const Icon(Icons.tag, size: 16),
                  title: Text(tag.name),
                  selected: _selectedTagId == tag.id,
                  onTap: () {
                    setState(() {
                      _selectedTagId = tag.id;
                      // Allow selecting both notebook and tag
                    });
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
              ? Center(
                  child: Text(
                    _searchQuery.isNotEmpty || _selectedNotebookId != null || _selectedTagId != null
                        ? 'No notes match your filters.'
                        : 'No notes yet. Create one!',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    final noteTags = _noteTagsMap[note.id] ?? [];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12.0),
                        title: Text(
                          note.title.isNotEmpty ? note.title : 'Untitled Note',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              _getPreviewText(note),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _formatDate(note.updatedAt),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                if (note.notebookId != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.book, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        _notebooks.firstWhere((n) => n.id == note.notebookId, orElse: () => Notebook(id: 0, name: 'Unknown')).name,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                if (noteTags.isNotEmpty)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.label, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        noteTags.map((t) => t.name).join(', '),
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
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
                      ),
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
