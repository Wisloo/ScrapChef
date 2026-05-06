import 'package:flutter/material.dart';

import '../state/app_state.dart';

class ManualVerifyScreen extends StatefulWidget {
  const ManualVerifyScreen({
    super.key,
    required this.appState,
    required this.predictedLabel,
    required this.confidence,
  });

  final AppState appState;
  final String predictedLabel;
  final double confidence;

  @override
  State<ManualVerifyScreen> createState() => _ManualVerifyScreenState();
}

class _ManualVerifyScreenState extends State<ManualVerifyScreen> {
  String? selectedLabel;

  @override
  void initState() {
    super.initState();
    selectedLabel = widget.predictedLabel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm classification'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            'Confidence below threshold',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'The mock model predicted ${widget.predictedLabel} at ${(widget.confidence * 100).toStringAsFixed(0)}%. Pick the correct scrap type so it can be logged.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.appState.supportedLabels
                .map(
                  (label) => ChoiceChip(
                    label: Text(label),
                    selected: selectedLabel == label,
                    onSelected: (_) => setState(() => selectedLabel = label),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: selectedLabel == null
                ? null
                : () {
                    widget.appState.confirmManualClassification(
                      selectedLabel!,
                      confidence: widget.confidence,
                    );
                    Navigator.of(context).pop();
                  },
            child: const Text('Save correction'),
          ),
        ],
      ),
    );
  }
}
