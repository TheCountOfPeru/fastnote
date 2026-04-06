// lib/file_view_page.dart
import 'dart:io';
import 'package:flutter/material.dart';

class FileViewPage extends StatefulWidget {
  final File file;
  final String title;

  const FileViewPage({required this.file, required this.title, super.key});

  @override
  State<FileViewPage> createState() => _FileViewPageState();
}

class _FileViewPageState extends State<FileViewPage> with WidgetsBindingObserver {
  // late TextEditingController _controller;
  final TextEditingController _controller = TextEditingController();

  bool _isLoading = true;
  List<String> undoStack = [];
  List<String> redoStack = [];

  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFile();
  }


void _loadFile() async {
  final content = await widget.file.readAsString();
  _controller.text = content;

  undoStack.clear();
  redoStack.clear();
  undoStack.add(content); // Initial state

  _controller.addListener(_onTextChanged);

  setState(() {
    _isLoading = false;
  });
}

void _onTextChanged() {
  if (undoStack.isEmpty || undoStack.last != _controller.text) {
    undoStack.add(_controller.text);
    redoStack.clear(); // Clear redo stack after new edit
  }
}

void _undo() {
  if (undoStack.length < 2) return;
  final last = undoStack.removeLast();
  redoStack.add(last);
  final previous = undoStack.last;
  _controller.text = previous;
  _controller.selection = TextSelection.collapsed(offset: previous.length);
}

void _redo() {
  if (redoStack.isEmpty) return;
  final next = redoStack.removeLast();
  undoStack.add(next);
  _controller.text = next;
  _controller.selection = TextSelection.collapsed(offset: next.length);
}


Future<void> _saveFile() async {
  try {
    await widget.file.writeAsString(_controller.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File saved')),
    );
    Navigator.pop(context, true); // 👈 return true to signal a change
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save file')),
    );
  }
}


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.inactive ||
      state == AppLifecycleState.paused) {
    _autoSave();
  }
}

Future<void> _autoSave() async {
  if (!mounted) return;

  try {
    await widget.file.writeAsString(_controller.text);
  } catch (_) {
    // fail silently
  }
}


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         //title: Text(widget.title),
//         actions: [
//   IconButton(
//     icon: Icon(Icons.undo),
//     onPressed: _undo,
//     tooltip: 'Undo',
//   ),
//   IconButton(
//     icon: Icon(Icons.redo),
//     onPressed: _redo,
//     tooltip: 'Redo',
//   ),
//   IconButton(
//     icon: Icon(Icons.save),
//     onPressed: _saveFile,
//     tooltip: 'Save',
//   ),
// ],

//       ),
// body: _isLoading
//     ? Center(child: CircularProgressIndicator())
//     : SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: TextField(
//   controller: _controller,
//   maxLines: null,
//   expands: true,
//   keyboardType: TextInputType.multiline,
//   textAlign: TextAlign.start,
//   textAlignVertical: TextAlignVertical.top,
//   decoration: InputDecoration(
//     border: InputBorder.none, // 👈 removes outline
//     hintText: 'Edit your text...',
//     contentPadding: EdgeInsets.all(12), // optional spacing
//   ),
// ),


//         ),
//       ),

//     );
//   }
@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false, // we handle pop manually
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;

      await _autoSave();                  // 👈 save first
      Navigator.pop(context, true);       // 👈 then pop with refresh flag
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.undo),
            onPressed: _undo,
          ),
          IconButton(
            icon: Icon(Icons.redo),
            onPressed: _redo,
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveFile,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            expands: true,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    ),
  );
}


}
