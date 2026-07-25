import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../models/note.dart';
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
      notebookId: widget.note?.notebookId ?? widget.notebookId,
    );

    if (widget.note == null) {
      await _dbService.insertNote(note);
    } else {
      await _dbService.updateNote(note);
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

  @override
  Widget build(BuildContext context) {
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
