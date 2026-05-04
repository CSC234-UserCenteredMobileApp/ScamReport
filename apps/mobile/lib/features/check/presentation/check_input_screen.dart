import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../data/check_api_client.dart';
import '../domain/check_result.dart';

class CheckInputScreen extends StatefulWidget {
  const CheckInputScreen({super.key, this.initialText});

  final String? initialText;

  @override
  State<CheckInputScreen> createState() => _CheckInputScreenState();
}

class _CheckInputScreenState extends State<CheckInputScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runCheck() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.push(
      '/verdict',
      extra: CheckQuery(
        payload: text,
        type: detectType(text),
        source: 'manual',
      ),
    );
  }

  void _prefill(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hasText = _controller.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l.checkInputTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: null,
                minLines: 4,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => hasText ? _runCheck() : null,
                decoration: InputDecoration(
                  hintText: l.checkInputHint,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.checkInputPrivacyNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: hasText ? _runCheck : null,
                child: Text(l.checkInputRunCheck),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: Text(l.checkInputSampleNumber),
                    onPressed: () => _prefill('+66 84 419 2270'),
                  ),
                  ActionChip(
                    label: Text(l.checkInputSampleLink),
                    onPressed: () => _prefill('http://bit.ly/example'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
