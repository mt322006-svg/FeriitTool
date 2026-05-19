import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String assetPath;
  final int initialPage;
  final List<int> quickPages;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.assetPath,
    this.initialPage = 1,
    this.quickPages = const [],
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  static const double _minZoom = 1.0;
  static const double _maxZoom = 30.0;
  static const double _zoomStep = 1.25;

  late final PdfViewerController _controller;
  late final TextEditingController _searchTextController;

  PdfTextSearchResult? _searchResult;
  bool _isSearchOpen = false;
  int _pagesCount = 0;
  int _currentPage = 1;
  double _currentZoom = _minZoom;
  bool _noMatchesToastShown = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _controller = PdfViewerController();
    _searchTextController = TextEditingController();
  }

  @override
  void dispose() {
    _detachSearchListener();
    _searchTextController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResult = _searchResult;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: _isSearchOpen ? 'Закрыть поиск' : 'Поиск по PDF',
            icon: Icon(_isSearchOpen ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            tooltip: 'Уменьшить',
            icon: const Icon(Icons.zoom_out),
            onPressed: () => _changeZoom(1 / _zoomStep),
          ),
          IconButton(
            tooltip: 'Увеличить',
            icon: const Icon(Icons.zoom_in),
            onPressed: () => _changeZoom(_zoomStep),
          ),
          IconButton(
            tooltip: 'Сбросить масштаб',
            icon: const Icon(Icons.fit_screen_outlined),
            onPressed: _resetZoom,
          ),
          IconButton(
            tooltip: 'Переход к странице',
            icon: const Icon(Icons.find_in_page_outlined),
            onPressed: _pagesCount <= 1 ? null : () => _openPageNavigator(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearchOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: _SearchToolbar(
                controller: _searchTextController,
                currentIndex: searchResult?.currentInstanceIndex ?? 0,
                totalCount: searchResult?.totalInstanceCount ?? 0,
                isBusy: (searchResult?.hasResult ?? false) &&
                    !(searchResult?.isSearchCompleted ?? false),
                hasQuery: _searchTextController.text.trim().isNotEmpty,
                onSubmitted: _performSearch,
                onClear: _clearSearch,
                onPrevious: () => _searchResult?.previousInstance(),
                onNext: () => _searchResult?.nextInstance(),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: SfPdfViewer.asset(
                    widget.assetPath,
                    controller: _controller,
                    pageLayoutMode: PdfPageLayoutMode.single,
                    scrollDirection: PdfScrollDirection.horizontal,
                    initialPageNumber: widget.initialPage,
                    initialZoomLevel: 1.0,
                    maxZoomLevel: _maxZoom,
                    enableDoubleTapZooming: true,
                    canShowPaginationDialog: false,
                    canShowScrollHead: false,
                    canShowScrollStatus: false,
                    currentSearchTextHighlightColor: const Color(0xFFFF5A1F),
                    otherSearchTextHighlightColor: const Color(0xFFFFF176),
                    onDocumentLoaded: (details) {
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _pagesCount = details.document.pages.count;
                        _currentPage = _controller.pageNumber;
                      });
                    },
                    onDocumentLoadFailed: (details) {
                      _showDocumentError('${details.error}: ${details.description}');
                    },
                    onPageChanged: (details) {
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _currentPage = details.newPageNumber;
                      });
                    },
                    onZoomLevelChanged: (details) {
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _currentZoom = details.newZoomLevel.clamp(_minZoom, _maxZoom);
                      });
                    },
                  ),
                ),
                if (widget.quickPages.isNotEmpty)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _QuickPagesBar(
                      pages: widget.quickPages,
                      currentPage: _currentPage,
                      onTapPage: _goToPage,
                    ),
                  ),
                if (_isSearchOpen && _searchTextController.text.trim().isNotEmpty)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _SearchBadge(
                      currentIndex: searchResult?.currentInstanceIndex ?? 0,
                      totalCount: searchResult?.totalInstanceCount ?? 0,
                      isBusy: (searchResult?.hasResult ?? false) &&
                          !(searchResult?.isSearchCompleted ?? false),
                    ),
                  )
                else
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _ModeBadge(
                      label: '${(_currentZoom * 100).round()}%',
                    ),
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
          ),
        ],
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearchOpen = !_isSearchOpen;
    });

    if (!_isSearchOpen) {
      _clearSearch(closeToolbar: false);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  void _performSearch(String rawQuery) {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      _clearSearch(closeToolbar: false);
      return;
    }

    _detachSearchListener();
    _noMatchesToastShown = false;
    final result = _controller.searchText(query);
    result.addListener(_handleSearchResultChanged);

    setState(() {
      _searchResult = result;
    });
  }

  void _handleSearchResultChanged() {
    final result = _searchResult;
    if (!mounted || result == null) {
      return;
    }

    if (result.isSearchCompleted &&
        result.totalInstanceCount == 0 &&
        !_noMatchesToastShown) {
      _noMatchesToastShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Совпадений в этом PDF не найдено')),
      );
    }

    setState(() {});
  }

  void _clearSearch({bool closeToolbar = false}) {
    _searchTextController.clear();
    _searchResult?.clear();
    _detachSearchListener();
    _noMatchesToastShown = false;

    setState(() {
      _searchResult = null;
      if (closeToolbar) {
        _isSearchOpen = false;
      }
    });
  }

  void _detachSearchListener() {
    _searchResult?.removeListener(_handleSearchResultChanged);
  }

  void _showDocumentError(String error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('PDF ошибка: $error')));
  }

  void _changeZoom(double factor) {
    final nextZoom = (_controller.zoomLevel * factor).clamp(_minZoom, _maxZoom);
    _controller.zoomLevel = nextZoom;
  }

  void _resetZoom() {
    _controller.zoomLevel = 1.0;
  }

  void _goToPage(int page) {
    if (page < 1 || page > _pagesCount) {
      return;
    }
    _controller.jumpToPage(page);
  }

  void _openPageNavigator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => _PageNavigator(
        current: _currentPage,
        total: _pagesCount,
        onGo: (page) {
          Navigator.pop(context);
          _goToPage(page);
        },
      ),
    );
  }
}

class _SearchToolbar extends StatelessWidget {
  final TextEditingController controller;
  final int currentIndex;
  final int totalCount;
  final bool isBusy;
  final bool hasQuery;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _SearchToolbar({
    required this.controller,
    required this.currentIndex,
    required this.totalCount,
    required this.isBusy,
    required this.hasQuery,
    required this.onSubmitted,
    required this.onClear,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final hasMatches = totalCount > 0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Искать текст в PDF',
                prefixIcon: Icon(Icons.manage_search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Искать',
            icon: const Icon(Icons.search),
            onPressed: () => onSubmitted(controller.text),
          ),
          IconButton(
            tooltip: 'Очистить',
            icon: const Icon(Icons.clear),
            onPressed: hasQuery ? onClear : null,
          ),
          IconButton(
            tooltip: 'Предыдущее совпадение',
            icon: const Icon(Icons.navigate_before),
            onPressed: hasMatches ? onPrevious : null,
          ),
          IconButton(
            tooltip: 'Следующее совпадение',
            icon: const Icon(Icons.navigate_next),
            onPressed: hasMatches ? onNext : null,
          ),
          SizedBox(
            width: 84,
            child: Text(
              isBusy
                  ? 'Поиск...'
                  : hasMatches
                  ? '$currentIndex / $totalCount'
                  : hasQuery
                  ? '0 / 0'
                  : '',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
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
          color: Theme.of(context).cardColor.withValues(alpha: 0.92),
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

class _QuickPagesBar extends StatelessWidget {
  final List<int> pages;
  final int currentPage;
  final ValueChanged<int> onTapPage;

  const _QuickPagesBar({
    required this.pages,
    required this.currentPage,
    required this.onTapPage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: pages
            .map(
              (page) => ActionChip(
                label: Text('Стр. $page'),
                backgroundColor: page == currentPage
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.22)
                    : null,
                onPressed: () => onTapPage(page),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _SearchBadge extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final bool isBusy;

  const _SearchBadge({
    required this.currentIndex,
    required this.totalCount,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF8F00), width: 1.4),
        ),
        child: Text(
          isBusy
              ? 'Поиск...'
              : totalCount > 0
              ? 'Найдено: $currentIndex / $totalCount'
              : '0 совпадений',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
        ),
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final String label;

  const _ModeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
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

  int _clamp(int value) => value.clamp(1, widget.total);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Быстрый переход', style: textTheme.titleMedium),
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
                  onChanged: (value) {
                    setState(() {
                      _value = value;
                      _text.text = value.round().toString();
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
                  onChanged: (text) {
                    final value = int.tryParse(text);
                    if (value == null) {
                      return;
                    }
                    setState(() => _value = _clamp(value).toDouble());
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
            'Поиск по PDF теперь подсвечивает совпадения ярко и позволяет листать их по одному.',
            style: textTheme.bodySmall?.copyWith(color: const Color(0xFF9EA7B3)),
          ),
        ],
      ),
    );
  }
}
