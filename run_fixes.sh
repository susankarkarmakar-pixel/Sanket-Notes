#!/bin/bash
sed -i 's/_HomeScreenState/HomeScreenState/g' lib/screens/home_screen.dart
sed -i 's/_NoteEditorScreenState/NoteEditorScreenState/g' lib/screens/note_editor_screen.dart
sed -i 's/_NotebookManagerScreenState/NotebookManagerScreenState/g' lib/screens/notebook_manager_screen.dart
sed -i 's/_TagManagerScreenState/TagManagerScreenState/g' lib/screens/tag_manager_screen.dart
