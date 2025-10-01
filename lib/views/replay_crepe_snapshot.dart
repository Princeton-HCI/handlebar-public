import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:handlebar/services/media_store_service.dart';
import '../widgets/crepe_primitive_ui.dart';
import '../widgets/playback_controls.dart';

class ReplayCrepeSnapshot extends StatefulWidget {
  const ReplayCrepeSnapshot({super.key});

  @override
  State<ReplayCrepeSnapshot> createState() => _ReplayCrepeSnapshotState();
}

class _ReplayCrepeSnapshotState extends State<ReplayCrepeSnapshot> {
  List<Map<String, dynamic>> snapshots = [];
  int currentIndex = 0;
  bool isPlaying = false;
  Timer? playbackTimer;
  int? startTimestamp;
  int? endTimestamp;

  @override
  void dispose() {
    playbackTimer?.cancel();
    super.dispose();
  }

  void _extractTimestamps() {
    if (snapshots.isEmpty) return;

    int? minTime;
    int? maxTime;

    for (final snapshot in snapshots) {
      final timestamp = snapshot['captureTimestamp'] as int?;
      if (timestamp != null) {
        minTime = minTime == null
            ? timestamp
            : (timestamp < minTime ? timestamp : minTime);
        maxTime = maxTime == null
            ? timestamp
            : (timestamp > maxTime ? timestamp : maxTime);
      }
    }

    setState(() {
      startTimestamp = minTime;
      endTimestamp = maxTime;
    });
  }

  void _togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });

    if (isPlaying) {
      playbackTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (currentIndex < snapshots.length - 1) {
          setState(() {
            currentIndex++;
          });
        } else {
          setState(() {
            isPlaying = false;
            currentIndex = 0;
          });
          playbackTimer?.cancel();
        }
      });
    } else {
      playbackTimer?.cancel();
    }
  }

  void _seekToIndex(int index) {
    setState(() {
      currentIndex = index.clamp(0, snapshots.length - 1);
    });
  }

  void _onToggleView(bool isSnapshotView) {
    // Placeholder for future video/snapshot toggle
    log('View toggled to: ${isSnapshotView ? "Snapshot" : "Video"}');
  }

  int? _getCurrentTimestamp() {
    if (snapshots.isEmpty || currentIndex >= snapshots.length) return null;
    return snapshots[currentIndex]['captureTimestamp'] as int?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crepe UI Snapshot Replay')),
      body: snapshots.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No snapshots loaded'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Load Recording'),
                    onPressed: () async {
                      final loaded = await pickFile();
                      setState(() {
                        snapshots = loaded;
                        currentIndex = 0;
                      });
                      _extractTimestamps();
                    },
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: crepePrimitiveUI(snapshots[currentIndex]),
                ),
                PlaybackControls(
                  currentIndex: currentIndex,
                  totalSnapshots: snapshots.length,
                  isPlaying: isPlaying,
                  onSeek: _seekToIndex,
                  onPlayPause: _togglePlayPause,
                  onToggleView: _onToggleView,
                  showVideoToggle: true,
                  startTimestamp: startTimestamp,
                  endTimestamp: endTimestamp,
                  currentTimestamp: _getCurrentTimestamp(),
                ),
              ],
            ),
      floatingActionButton: snapshots.isNotEmpty
          ? FloatingActionButton(
              child: const Icon(Icons.folder_open),
              onPressed: () async {
                final loaded = await pickFile();
                setState(() {
                  snapshots = loaded;
                  currentIndex = 0;
                  isPlaying = false;
                });
                playbackTimer?.cancel();
                _extractTimestamps();
              },
            )
          : null,
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
      log('Found: ${file.name}', name: 'ReplayCrepeSnapshot');
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
