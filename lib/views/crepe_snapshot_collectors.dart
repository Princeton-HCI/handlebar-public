import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:handlebar/services/collector_service.dart';
import 'package:handlebar/services/media_store_service.dart';
import 'package:handlebar/widgets/crepe/available_collectors.dart';
import 'package:handlebar/widgets/crepe/replay_ui.dart';
import 'package:handlebar/widgets/playback_controls.dart';
import 'package:path_provider/path_provider.dart';
import '../models/collector.dart';

class CrepeSnapshotCollectors extends StatefulWidget {
  const CrepeSnapshotCollectors({super.key});

  @override
  State<CrepeSnapshotCollectors> createState() =>
      _CrepeSnapshotCollectorsState();
}

class _CrepeSnapshotCollectorsState extends State<CrepeSnapshotCollectors> {
  CollectorService collectorService = CollectorService();
  Timer? _playbackTimer;
  List<Map<String, dynamic>> snapshots = [];
  List<Collector> collectors = [];
  int _replayIndex = 0;
  bool _debugToggleValue = false;
  bool _isPlaying = false;
  int? _startTimestamp;
  int? _endTimestamp;

  @override
  void initState() {
    super.initState();
    collectors = collectorService.activeCollectorResponse?.collectors ?? [];

    // Load collectors from the directory
    _loadCollectorsFromDirectory();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
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
      _startTimestamp = minTime;
      _endTimestamp = maxTime;
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _playbackTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_replayIndex < snapshots.length - 1) {
          setState(() {
            _replayIndex++;
          });
        } else {
          setState(() {
            _isPlaying = false;
            _replayIndex = 0;
          });
          _playbackTimer?.cancel();
        }
      });
    } else {
      _playbackTimer?.cancel();
    }
  }

  void _seekToIndex(int index) {
    setState(() {
      _replayIndex = index.clamp(0, snapshots.length - 1);
    });
  }

  void _onToggleView(bool isSnapshotView) {
    // Placeholder for future video/snapshot toggle
    print('View toggled to: ${isSnapshotView ? "Snapshot" : "Video"}');
  }

  int? _getCurrentTimestamp() {
    if (snapshots.isEmpty || _replayIndex >= snapshots.length) return null;
    return snapshots[_replayIndex]['captureTimestamp'] as int?;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Crepe UI Snapshot'),
            bottom: const TabBar(tabs: <Widget>[
              Tab(icon: Icon(Icons.video_file), text: "View recorded session"),
              Tab(
                  icon: Icon(Icons.collections_bookmark_outlined),
                  text: "Select Collectors"),
            ]),
          ),
          body: TabBarView(children: <Widget>[
            // Tab 1 → replay snapshots with controls
            snapshots.isEmpty
                ? const Center(child: Text("No snapshots loaded"))
                : Column(
                    children: [
                      Expanded(
                        child: ReplayUI(snapshot: snapshots[_replayIndex]),
                      ),
                      PlaybackControls(
                        currentIndex: _replayIndex,
                        totalSnapshots: snapshots.length,
                        isPlaying: _isPlaying,
                        onSeek: _seekToIndex,
                        onPlayPause: _togglePlayPause,
                        onToggleView: _onToggleView,
                        showVideoToggle: true,
                        startTimestamp: _startTimestamp,
                        endTimestamp: _endTimestamp,
                        currentTimestamp: _getCurrentTimestamp(),
                      ),
                    ],
                  ),
            AvailableCollectors(
                collectors: collectors,
                onToggle: (Collector collector, bool toggleValue) {
                  log('Collector toggled: ${collector.dataFields}');
                  setState(() {
                    _debugToggleValue = toggleValue;
                  });
                },
                debugToggleValue: _debugToggleValue)
          ]),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.folder_open),
            onPressed: () async {
              final loaded = await pickFile();
              setState(() {
                snapshots = loaded;
                _replayIndex = 0;
                _isPlaying = false;
              });
              _playbackTimer?.cancel();
              _extractTimestamps();
            },
          ),
        ));
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

  // Method to load collectors from the directory
  Future<void> _loadCollectorsFromDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final collectorsDir = Directory('${directory.path}/collectors');
      if (await collectorsDir.exists()) {
        await for (var file in collectorsDir.list(recursive: false)) {
          if (file is File && file.path.endsWith('.json')) {
            final jsonString = await file.readAsString();
            final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
            final collector = Collector.fromJson(
                jsonMap); // Assumes Collector.fromJson exists
            setState(() {
              collectors.add(collector);
            });
          }
        }
      }
    } catch (e) {
      log('Error loading collectors: $e');
    }
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
      log('Found: ${file.name}');
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
