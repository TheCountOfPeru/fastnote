// lib/home_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'file_view_page.dart';
import 'settings_page.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TextFileInfo {
  final File file;
  final String title;
  final DateTime lastModified;

  TextFileInfo({
    required this.file,
    required this.title,
    required this.lastModified,
  });
}

class FileListPage extends StatefulWidget {
  @override
  _FileListPageState createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  List<TextFileInfo> textFiles = [];
  Set<String> pinnedFiles = {}; // file paths
  static const String _pinnedKey = 'pinned_files';


  @override
  void initState() {
    super.initState();
     _loadPinnedFiles().then((_) => _loadTextFiles());
  }


Future<void> _loadPinnedFiles() async {
  final prefs = await SharedPreferences.getInstance();
  final pinnedList = prefs.getStringList(_pinnedKey) ?? [];
  pinnedFiles = pinnedList.toSet();
}

Future<void> _savePinnedFiles() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setStringList(_pinnedKey, pinnedFiles.toList());
}

void _createNewNote() async {
  final dir = Directory('/storage/emulated/0/fastnote');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final now = DateTime.now();
  final formatter = DateFormat('yyyy-MM-dd-HH-mm-ss');
  final formatted = formatter.format(now); // e.g. 2025-07-05_13-48-23
  final newFile = File('${dir.path}/$formatted.txt');
  await newFile.writeAsString('');

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => FileViewPage(
        file: newFile,
        title: '(New Note)',
      ),
    ),
  );

  if (result == true) {
    _loadTextFiles(); // refresh file list
  }
}



  Future<void> _loadTextFiles() async {
    var status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission not granted')),
      );
      return;
    }

    Directory fastnoteDir = Directory('/storage/emulated/0/fastnote');
    if (!await fastnoteDir.exists()) {
      await fastnoteDir.create(recursive: true);
    }

    List<FileSystemEntity> files = fastnoteDir
        .listSync()
        .where((f) => f.path.endsWith('.txt'))
        .toList();

    List<TextFileInfo> loadedFiles = [];

    for (var f in files) {
      File file = File(f.path);
      String firstLine = '';
      DateTime modified;

      try {
        List<String> lines = await file.readAsLines();
        firstLine = lines.isNotEmpty ? lines.first : '(Empty file)';
        modified = await file.lastModified();
      } catch (e) {
        firstLine = '(Could not read)';
        modified = DateTime.fromMillisecondsSinceEpoch(0);
      }

      loadedFiles.add(TextFileInfo(
        file: file,
        title: firstLine,
        lastModified: modified,
      ));
    }

    loadedFiles.sort((a, b) {
  final aPinned = pinnedFiles.contains(a.file.path);
  final bPinned = pinnedFiles.contains(b.file.path);

  if (aPinned && !bPinned) return -1;
  if (!aPinned && bPinned) return 1;

  return b.lastModified.compareTo(a.lastModified);
});


    setState(() {
      textFiles = loadedFiles;
    });
  }

void _showFileOptions(BuildContext context, TextFileInfo fileInfo) async {
  showModalBottomSheet(
    context: context,
    builder: (_) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete'),
              onTap: () async {
                Navigator.pop(context); // Close the bottom sheet
                final confirmed = await _confirmDelete(context, fileInfo.title);
                if (confirmed) {
                  await fileInfo.file.delete();
                  _loadTextFiles(); // Refresh the list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('File deleted')),
                  );
                }
              },
            ),
          ],
        ),
      );
    },
  );
}
Future<bool> _confirmDelete(BuildContext context, String fileTitle) async {
  // Truncate title to max 40 characters
  final shortTitle = fileTitle.length > 40
      ? '${fileTitle.substring(0, 37)}...'
      : fileTitle;

  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
  'Delete "$shortTitle"?',
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
),

          content: Text('Are you sure you want to delete this file?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ??
      false;
}


@override
Widget build(BuildContext context) {
  return Scaffold(
appBar: AppBar(
  title: Text('FastNote Files'),
  actions: [
    IconButton(
      icon: Icon(Icons.note_add),
      tooltip: 'New Note',
      onPressed: _createNewNote,
    ),
    IconButton(
      icon: Icon(Icons.settings),
      tooltip: 'Settings',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsPage()),
        );
      },
    ),
  ],
),



body: SafeArea(
  child: Scrollbar(
    thumbVisibility: true, // always show scrollbar (optional)
    child: ListView.builder(
      itemCount: textFiles.length,
      itemBuilder: (context, index) {
        final fileInfo = textFiles[index];
        final formattedDate = DateFormat('yyyy-MM-dd').format(fileInfo.lastModified);
return ListTile(
  title: Text(fileInfo.title),
  subtitle: Text(
    '${fileInfo.file.uri.pathSegments.last} · $formattedDate',
    style: TextStyle(fontSize: 12),
  ),
  trailing: IconButton(
    icon: Icon(
      pinnedFiles.contains(fileInfo.file.path)
          ? Icons.push_pin
          : Icons.push_pin_outlined,
    ),
    tooltip: pinnedFiles.contains(fileInfo.file.path)
        ? 'Unpin'
        : 'Pin to top',
onPressed: () async {
  setState(() {
    final path = fileInfo.file.path;
    if (pinnedFiles.contains(path)) {
      pinnedFiles.remove(path);
    } else {
      pinnedFiles.add(path);
    }
  });
  await _savePinnedFiles(); // 👈 Save after update
  _loadTextFiles();         // 👈 Re-sort list
},

  ),
  onTap: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FileViewPage(
          file: fileInfo.file,
          title: fileInfo.title,
        ),
      ),
    );
    if (result == true) _loadTextFiles();
  },
  onLongPress: () => _showFileOptions(context, fileInfo),
);

      },
    ),
  ),
),

  );
}

}
