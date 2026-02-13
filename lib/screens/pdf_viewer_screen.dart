import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String assetPath;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final PdfControllerPinch _controller;
  int _pagesCount = 0;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openAsset(widget.assetPath),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Переход к странице',
            icon: const Icon(Icons.find_in_page_outlined),
            onPressed: _pagesCount <= 1 ? null : () => _openPageNavigator(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          PdfViewPinch(
            controller: _controller,
            // Свайп по страницам (горизонтально)
            scrollDirection: Axis.horizontal,
            onDocumentLoaded: (document) {
              setState(() {
                _pagesCount = document.pagesCount;
                _currentPage = 1;
              });
            },
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            onDocumentError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PDF ошибка: $error')),
              );
            },
          ),
          if (_pagesCount > 1)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _PageHud(
                current: _currentPage,
                total: _pagesCount,
                onTap: () => _openPageNavigator(context),
              ),
            ),
        ],
      ),
    );
  }

  void _openPageNavigator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => _PageNavigator(
        current: _currentPage,
        total: _pagesCount,
        onGo: (page) {
          _controller.jumpToPage(page);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _PageHud extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback onTap;

  const _PageHud({
    required this.current,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.92),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf_outlined, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Стр. $current / $total',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.swap_horiz, size: 18),
          ],
        ),
      ),
    );
  }
}

class _PageNavigator extends StatefulWidget {
  final int current;
  final int total;
  final ValueChanged<int> onGo;

  const _PageNavigator({
    required this.current,
    required this.total,
    required this.onGo,
  });

  @override
  State<_PageNavigator> createState() => _PageNavigatorState();
}

class _PageNavigatorState extends State<_PageNavigator> {
  late double _value;
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _value = widget.current.toDouble();
    _text = TextEditingController(text: widget.current.toString());
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  int _clamp(int v) => v.clamp(1, widget.total);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Быстрый переход', style: t.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _value,
                  min: 1,
                  max: widget.total.toDouble(),
                  divisions: widget.total - 1,
                  label: _value.round().toString(),
                  onChanged: (v) {
                    setState(() {
                      _value = v;
                      _text.text = v.round().toString();
                    });
                  },
                ),
              ),
              SizedBox(
                width: 88,
                child: TextField(
                  controller: _text,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Стр.',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (s) {
                    final v = int.tryParse(s);
                    if (v == null) return;
                    setState(() => _value = _clamp(v).toDouble());
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => widget.onGo(_clamp(_value.round())),
              icon: const Icon(Icons.arrow_forward),
              label: Text('Перейти на ${_clamp(_value.round())}'),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Пинч‑зум работает. Свайп — влево/вправо.',
            style: t.bodySmall?.copyWith(color: const Color(0xFF9EA7B3)),
          ),
        ],
      ),
    );
  }
}
