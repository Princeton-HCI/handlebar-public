import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:handlebar/services/media_store_service.dart';
import '../widgets/crepe_primitive_ui.dart';

class ReplayCrepeSnapshot extends StatefulWidget {
  const ReplayCrepeSnapshot({super.key});

  @override
  State<ReplayCrepeSnapshot> createState() => _ReplayCrepeSnapshotState();
}

class _ReplayCrepeSnapshotState extends State<ReplayCrepeSnapshot> {
  List<Map<String, dynamic>> snapshots = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crepe UI Snapshot')),
      body: snapshots.isEmpty
          ? Center(child: Text('No UI loaded'))
          : PageView(
        children: snapshots.map((s) => CrepePrimitiveUI(s)).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.folder_open),
        onPressed: () async {
          final loaded = await pickFile();
          setState(() => snapshots = loaded);
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> loadJsonFromZip() async {
    final zipPaths = await MediaStoreService.getSavedRecordings();
    if (zipPaths.isEmpty) return [];

    List<Map<String, dynamic>> snapshots = [];

    for (final path in zipPaths) {
      final bytes = File(path).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (file.isFile && file.name.endsWith('.json')) {
          final content = utf8.decode(file.content as List<int>);
          snapshots.add(jsonDecode(content));
        }
      }
    }

    return snapshots;
  }

  Future<List<Map<String, dynamic>>> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.single.path == null) {
      return []; // user canceled
    }

    final filePath = result.files.single.path!;
    final bytes = File(filePath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    List<Map<String, dynamic>> snapshots = [];
    for (final file in archive) {
      print('Found: ${file.name}');
    }
    for (final file in archive) {
      if (file.isFile && file.name.endsWith('.json')) {
        final content = utf8.decode(file.content as List<int>);
        final decoded = jsonDecode(content);

        // Only keep files that contain UI snapshots
        if (decoded is Map && decoded.containsKey('entities')) {
          snapshots.add(Map<String, dynamic>.from(decoded));
        }
      }
    }
    return snapshots;
  }
}