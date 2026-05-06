import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../state/app_state.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _batchMode = false;
  final List<String> _batchLabels = <String>[];

  Future<void> _pickFromCamera() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _selectedImage = image);
      _processImage();
    }
  }

  Future<void> _pickFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
      _processImage();
    }
  }

  void _processImage() {
    _showLabelSelector();
  }

  Future<void> _showLabelSelector() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LabelSelectorSheet(labels: widget.appState.supportedLabels),
    );

    if (selected != null && selected.isNotEmpty) {
      if (_batchMode) {
        // collect into batch and remain in scan flow
        setState(() {
          _batchLabels.add(selected);
          _selectedImage = null; // ready for next capture
        });
      } else {
        widget.appState.simulateScan(selected);
        if (mounted) {
          Navigator.of(context).pop(widget.appState.lastOutcome);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan scrap'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_batchMode ? Icons.collections : Icons.collections_outlined),
            tooltip: _batchMode ? 'Batch mode on' : 'Enable batch mode',
            onPressed: () => setState(() => _batchMode = !_batchMode),
          ),
        ],
      ),
      body: _selectedImage != null ? _buildImagePreview() : _buildPickerOptions(),
      floatingActionButton: _batchMode && _batchLabels.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showBatchPreview,
              label: Text('Finish (${_batchLabels.length})'),
              icon: const Icon(Icons.playlist_add_check),
            )
          : null,
    );
  }

  Future<void> _showBatchPreview() async {
    final suggestions = widget.appState.suggestForLabels(_batchLabels);

    final commit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Batch preview', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Scanned items: ${_batchLabels.join(', ')}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                ...suggestions.map((r) => Padding(padding: const EdgeInsets.only(bottom: 8), child: ListTile(
                      title: Text(r.title),
                      subtitle: Text(r.summary),
                    ))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Commit batch'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );

    if (commit == true) {
      widget.appState.addBatchItems(List<String>.from(_batchLabels));
      if (mounted) Navigator.of(context).pop(widget.appState.lastOutcome);
    }
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black12,
            child: Image.file(
              File(_selectedImage!.path),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Confirm the scrap type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _selectedImage = null),
                      icon: const Icon(Icons.close),
                      label: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _showLabelSelector,
                      icon: const Icon(Icons.check),
                      label: const Text('Use this photo'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPickerOptions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.camera_alt, size: 80, color: Color(0xFF2F6B57)),
          const SizedBox(height: 24),
          const Text(
            'Capture your scrap',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a photo or pick from gallery. Then identify what you\'re logging.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _pickFromCamera,
              icon: const Icon(Icons.camera),
              label: const Text('Take photo'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.image),
              label: const Text('Choose from gallery'),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F7F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'The app captures a photo first, then you confirm the scrap label from the supported list.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelSelectorSheet extends StatefulWidget {
  const _LabelSelectorSheet({required this.labels});

  final List<String> labels;

  @override
  State<_LabelSelectorSheet> createState() => _LabelSelectorSheetState();
}

class _LabelSelectorSheetState extends State<_LabelSelectorSheet> {
  String? selectedLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'What did you capture?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Select from our supported list',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 3.4,
                ),
                itemCount: widget.labels.length,
                itemBuilder: (context, index) {
                  final label = widget.labels[index];
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: ChoiceChip(
                      label: Text(label),
                      selected: selectedLabel == label,
                      onSelected: (_) => setState(() => selectedLabel = label),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: selectedLabel == null
                    ? null
                    : () {
                        Navigator.of(context).pop(selectedLabel);
                      },
                child: const Text('Log this scrap'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
