import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../models/note.dart';
import '../models/notebook.dart';
import '../models/tag.dart';
import '../services/database_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final int? notebookId;

  const NoteEditorScreen({Key? key, this.note, this.notebookId}) : super(key: key);

  @override
  _NoteEditorScreenState createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final DatabaseService _dbService = DatabaseService();
  late TextEditingController _titleController;
  late quill.QuillController _quillController;

  List<Notebook> _notebooks = [];
  int? _selectedNotebookId;

  List<Tag> _allTags = [];
  List<Tag> _selectedTags = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');

    if (widget.note != null && widget.note!.content.isNotEmpty) {
      try {
        final doc = quill.Document.fromJson(jsonDecode(widget.note!.content));
        _quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // Fallback for plain text or old format
        final doc = quill.Document()..insert(0, widget.note!.content);
        _quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      _quillController = quill.QuillController.basic();
    }

    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final notebooks = await _dbService.getNotebooks();
    final allTags = await _dbService.getTags();

    List<Tag> selectedTags = [];
    if (widget.note?.id != null) {
      selectedTags = await _dbService.getTagsForNote(widget.note!.id!);
    }

    setState(() {
      _notebooks = notebooks;
      _allTags = allTags;
      _selectedTags = selectedTags;

      int? initialNotebookId = widget.note?.notebookId ?? widget.notebookId;

      // Safety check: ensure the selected notebook actually exists in the list
      if (initialNotebookId != null && !_notebooks.any((n) => n.id == initialNotebookId)) {
        initialNotebookId = null;
      }

      _selectedNotebookId = initialNotebookId;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text;
    final content = jsonEncode(_quillController.document.toDelta().toJson());
    final plainTextContent = _quillController.document.toPlainText().trim();

    if (title.isEmpty && plainTextContent.isEmpty) return;

    final note = Note(
      id: widget.note?.id,
      title: title,
      content: content,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      notebookId: _selectedNotebookId,
    );

    int noteId;
    if (widget.note == null) {
      noteId = await _dbService.insertNote(note);
    } else {
      noteId = widget.note!.id!;
      await _dbService.updateNote(note);

      // Clear existing tags
      final existingTags = await _dbService.getTagsForNote(noteId);
      for (var t in existingTags) {
        if (t.id != null) {
            await _dbService.removeTagFromNote(noteId, t.id!);
        }
      }
    }

    // Assign new tags
    for (var tag in _selectedTags) {
        if (tag.id != null) {
            await _dbService.assignTagToNote(noteId, tag.id!);
        }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteNote() async {
    if (widget.note?.id != null) {
      await _dbService.deleteNote(widget.note!.id!);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _showTagSelector() async {
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Tags'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _allTags.map((tag) {
                    final isSelected = _selectedTags.any((t) => t.id == tag.id);
                    return CheckboxListTile(
                      title: Text(tag.name),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.removeWhere((t) => t.id == tag.id);
                          }
                        });
                        setState(() {}); // Update the underlying screen state
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteNote,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.book, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                DropdownButton<int?>(
                  value: _selectedNotebookId,
                  hint: const Text('No Notebook'),
                  underline: const SizedBox(),
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedNotebookId = newValue;
                    });
                  },
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('No Notebook'),
                    ),
                    ..._notebooks.map((notebook) {
                      return DropdownMenuItem<int?>(
                        value: notebook.id,
                        child: Text(notebook.name),
                      );
                    }).toList(),
                  ],
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.label, size: 16),
                  label: Text(_selectedTags.isEmpty ? 'Add Tags' : '${_selectedTags.length} Tags'),
                  onPressed: _showTagSelector,
                ),
              ],
            ),
          ),
          if (_selectedTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 4.0,
                  children: _selectedTags.map((tag) => Chip(
                    label: Text(tag.name, style: const TextStyle(fontSize: 12)),
                    onDeleted: () {
                      setState(() {
                        _selectedTags.removeWhere((t) => t.id == tag.id);
                      });
                    },
                  )).toList(),
                ),
              ),
            ),
          const Divider(),
          quill.QuillToolbar.simple(
            configurations: quill.QuillSimpleToolbarConfigurations(
              controller: _quillController,
              sharedConfigurations: const quill.QuillSharedConfigurations(
                locale: Locale('en'),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: quill.QuillEditor.basic(
                configurations: quill.QuillEditorConfigurations(
                  controller: _quillController,
                  sharedConfigurations: const quill.QuillSharedConfigurations(
                    locale: Locale('en'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
