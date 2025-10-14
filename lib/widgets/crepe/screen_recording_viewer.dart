import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:handlebar/models/collector.dart';
import 'package:handlebar/models/data_field.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class ScreenRecordingViewer extends StatefulWidget {
  final List<Map<String, dynamic>> snapshots;
  final List<Collector> collectors;

  const ScreenRecordingViewer({
    super.key,
    required this.snapshots,
    required this.collectors,
  });

  @override
  State<ScreenRecordingViewer> createState() => _ScreenRecordingViewerState();
}

class _ScreenRecordingViewerState extends State<ScreenRecordingViewer>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  VideoPlayerController? _controller;
  List<Rect> _matchingBounds = [];
  final GlobalKey _videoKey = GlobalKey();
  final bool _absorbing = true;
  int _lastTimestamp = -1;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = DefaultTabController.of(context);
      if (_tabController != controller) {
        _tabController?.removeListener(_handleTabChange);
        _tabController = controller;
        _tabController?.addListener(_handleTabChange);
      }
    });
  }

  void _handleTabChange() {
    if (_controller != null && _controller!.value.isInitialized) {
      if (_tabController!.index == 0) {
        if (!_controller!.value.isPlaying) {
          _controller!.play();
        }
      } else {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        }
      }
    }
  }

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      _controller = VideoPlayerController.file(File(result.files.single.path!));
      await _controller!.initialize();
      _controller!.addListener(_updateOverlaysListener);
      setState(() {});
    }
  }

  Map<String, dynamic>? _findSnapshot(int timestamp) {
    if (widget.snapshots.isEmpty) return null;
    Map<String, dynamic>? closest;
    int minDiff = 999999999;
    for (var snap in widget.snapshots) {
      int snapTs = snap['metadata']['timestamp'] as int;
      int diff = (snapTs - timestamp).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = snap;
      }
    }
    return closest;
  }

  Map<String, dynamic>? _findIntersectingEntity(Offset localPos, List<dynamic> entities, Size videoSize, Size displaySize) {
    double scaleX = videoSize.width / displaySize.width;
    double scaleY = videoSize.height / displaySize.height;
    double tapX = localPos.dx * scaleX;
    double tapY = localPos.dy * scaleY;

    for (var ent in entities) {
      Rect? bounds = _parseBounds(ent['boundsInScreen'] as String?);
      if (bounds != null && bounds.contains(Offset(tapX, tapY))) {
        return ent as Map<String, dynamic>;
      }
    }
    return null;
  }

  Rect? _parseBounds(String? boundsStr) {
    if (boundsStr == null) return null;
    List<String> parts = boundsStr.split(' ');
    if (parts.length != 4) return null;
    try {
      double left = double.parse(parts[0]);
      double top = double.parse(parts[1]);
      double right = double.parse(parts[2]);
      double bottom = double.parse(parts[3]);
      return Rect.fromLTRB(left, top, right, bottom);
    } catch (e) {
      return null;
    }
  }

  void _handleTap(TapDownDetails details) {
    if (_controller == null || !_controller!.value.isInitialized || widget.snapshots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No video or snapshots loaded')),
      );
      return;
    }

    final renderBox = _videoKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    Size displaySize = renderBox.size;
    Size videoSize = _controller!.value.size;
    int ts = _controller!.value.position.inMilliseconds;

    var snapshot = _findSnapshot(ts);
    if (snapshot != null) {
      var entities = snapshot['entities'] as List<dynamic>? ?? [];
      var entity = _findIntersectingEntity(details.localPosition, entities, videoSize, displaySize);
      if (entity != null) {
        _showCreateCollectorOption(entity, snapshot['triples'] as List<dynamic>? ?? []);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No entity found at tap location')),
        );
      }
    }
  }

  void _showCreateCollectorOption(Map<String, dynamic> entity, List<dynamic> triples) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Collector?'),
        content: Text('Save a collector for entity: ${entity['contentDescription'] ?? entity['className']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              // Create DataField objects from entity fields and triples
              List<DataField> dataFields = [];
              int dataFieldId = 0;
              final entityId = entity['entityId'] as int;
              final relevantTriples = triples.where((t) => t['subjectId'] == entityId).toList();

              // Example: Create DataFields for key properties
              for (var triple in relevantTriples) {
                String predicate = triple['predicateType'] as String;
                if (['HAS_CLASS_NAME', 'IS_CLICKABLE', 'CONTENT_DESCRIPTION'].contains(predicate)) {
                  // Resolve objectId to value (simplified, may need mapping to entities or literals)
                  String value = triple['objectId'].toString(); // Adjust based on actual object resolution
                  dataFields.add(DataField(
                    dataFieldId: dataFieldId++,
                    graphQuery: '$predicate=$value',
                    name: predicate.toLowerCase().replaceAll('_', ' '),
                  ));
                }
              }

              // Add entity fields directly if relevant
              if (entity['className'] != null) {
                dataFields.add(DataField(
                  dataFieldId: dataFieldId++,
                  graphQuery: 'HAS_CLASS_NAME=${entity['className']}',
                  name: 'class name',
                ));
              }
              if (entity['contentDescription'] != null) {
                dataFields.add(DataField(
                  dataFieldId: dataFieldId++,
                  graphQuery: 'HAS_CONTENT_DESCRIPTION=${entity['contentDescription']}',
                  name: 'content description',
                ));
              }
              if (entity['isClickable'] == true) {
                dataFields.add(DataField(
                  dataFieldId: dataFieldId++,
                  graphQuery: 'IS_CLICKABLE=true',
                  name: 'is clickable',
                ));
              }

              final collector = Collector(
                collectorId: DateTime.now().millisecondsSinceEpoch,
                appName: 'Unknown', // Could derive from packageName or app context
                appPackage: entity['packageName'] as String,
                description: entity['contentDescription']?.toString() ?? entity['className'].toString(),
                dataFields: dataFields,
              );

              final dir = await getApplicationDocumentsDirectory();
              final file = File('${dir.path}/collectors/collector_${collector.collectorId}.json');
              await file.create(recursive: true);
              await file.writeAsString(jsonEncode(collector.toJson()));

              if (context.mounted) {
                DefaultTabController.of(context).animateTo(1); // Switch to collectors tab
              }
              Navigator.pop(context);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _updateOverlaysListener() {
    if (_controller == null || widget.collectors.isEmpty || widget.snapshots.isEmpty) return;

    int currentTs = _controller!.value.position.inMilliseconds;
    if ((currentTs - _lastTimestamp).abs() < 500) return;
    _lastTimestamp = currentTs;

    _updateOverlays(currentTs);
  }

  void _updateOverlays(int ts) {
    final renderBox = _videoKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    Size displaySize = renderBox.size;
    Size videoSize = _controller!.value.size;
    double scaleToDisplay = min(displaySize.width / videoSize.width, displaySize.height / videoSize.height);

    var snapshot = _findSnapshot(ts);
    if (snapshot != null) {
      var entities = snapshot['entities'] as List<dynamic>? ?? [];
      var triples = snapshot['triples'] as List<dynamic>? ?? [];
      List<Rect> bounds = [];
      for (var ent in entities) {
        if (_matchesAnyCollector(ent as Map<String, dynamic>, triples)) {
          Rect? origRect = _parseBounds(ent['boundsInScreen'] as String?);
          if (origRect != null) {
            Rect displayRect = Rect.fromLTRB(
              origRect.left * scaleToDisplay,
              origRect.top * scaleToDisplay,
              origRect.right * scaleToDisplay,
              origRect.bottom * scaleToDisplay,
            );
            bounds.add(displayRect);
          }
        }
      }
      setState(() {
        _matchingBounds = bounds;
      });
    }
  }

  bool _matchesAnyCollector(Map<String, dynamic> entity, List<dynamic> triples) {
    final entityId = entity['entityId'] as int;
    for (var collector in widget.collectors) {
      bool matches = true;
      for (var dataField in collector.dataFields) {
        // Parse graphQuery (assumed format: predicateType=value)
        final parts = dataField.graphQuery.split('=');
        if (parts.length != 2) continue;
        final predicate = parts[0];
        final expectedValue = parts[1];

        // Check if triple exists for this entity
        bool tripleMatches = triples.any((t) =>
        t['subjectId'] == entityId &&
            t['predicateType'] == predicate &&
            t['objectId'].toString() == expectedValue);

        // Check entity fields directly if applicable
        bool entityMatches = entity.containsKey(predicate.toLowerCase()) &&
            entity[predicate.toLowerCase()].toString() == expectedValue;

        if (!tripleMatches && !entityMatches) {
          matches = false;
          break;
        }
      }
      if (matches) return true;
    }
    return false;
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _controller?.removeListener(_updateOverlaysListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        if (_controller == null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _pickVideo,
              child: const Text('Pick Video'),
            ),
          ),
        if (_controller != null && _controller!.value.isInitialized && widget.snapshots.isNotEmpty)
          Expanded(
            child: AspectRatio(
              key: _videoKey,
              aspectRatio: _controller!.value.aspectRatio,
              child: Stack(
                children: [
                  AbsorbPointer(
                    absorbing: _absorbing,
                    child: VideoPlayer(_controller!),
                  ),
                  GestureDetector(
                    onTapDown: _handleTap,
                    behavior: HitTestBehavior.opaque,
                  ),
                  ..._matchingBounds.map((rect) => Positioned.fromRect(
                    rect: rect,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        if (_controller != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(_controller!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  setState(() {
                    _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                  });
                },
              ),
            ],
          ),
      ],
    );
  }
}