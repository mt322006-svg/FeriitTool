import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/app_settings_store.dart';
import '../data/pdf_asset_cache.dart';

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
  static const double _pageSpacing = 0.0;

  late final PdfViewerController _controller;
  late final TextEditingController _searchTextController;
  late final Future<_PdfViewerBoot> _bootFuture;

  PdfTextSearchResult? _searchResult;
  Timer? _saveDebounce;
  Timer? _hudAutoHideTimer;
  bool _isSearchOpen = false;
  int _pagesCount = 0;
  int _currentPage = 1;
  double _currentZoom = _minZoom;
  bool _noMatchesToastShown = false;
  bool _restoredZoomApplied = false;
  bool _isPageHudVisible = true;
  bool _isTopOverlaysVisible = true;
  int _rotationQuarterTurns = 0;
  late final List<_BlockJump> _blockJumps;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
    _searchTextController = TextEditingController();
    _bootFuture = _prepareBoot();
    _blockJumps = _resolveBlockJumps(widget.assetPath);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _hudAutoHideTimer?.cancel();
    unawaited(_persistViewState());
    unawaited(WakelockPlus.disable());
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
          IconButton(
            tooltip: 'Повернуть схему',
            icon: const Icon(Icons.screen_rotation_alt_outlined),
            onPressed: _rotateViewer,
          ),
        ],
      ),
      body: FutureBuilder<_PdfViewerBoot>(
        future: _bootFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Не удалось открыть PDF: ${snapshot.error}',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final boot = snapshot.data!;

          return Column(
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
                    blockJumps: _blockJumps,
                    onJump: (jump) => _goToPage(jump.pages.first),
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _togglePageHud,
                        child: Listener(
                          onPointerDown: (_) => _hidePageHud(),
                          onPointerMove: (_) => _hidePageHud(),
                          onPointerSignal: (_) => _hidePageHud(),
                          child: RotatedBox(
                            quarterTurns: _rotationQuarterTurns,
                            child: SfPdfViewer.memory(
                              boot.bytes,
                              controller: _controller,
                              pageSpacing: _pageSpacing,
                              pageLayoutMode: PdfPageLayoutMode.single,
                              scrollDirection: PdfScrollDirection.horizontal,
                              interactionMode: PdfInteractionMode.pan,
                              initialPageNumber: boot.initialPage,
                              initialZoomLevel: 1.0,
                              maxZoomLevel: _maxZoom,
                              enableDoubleTapZooming: true,
                              enableTextSelection: false,
                              enableDocumentLinkAnnotation: false,
                              canShowPaginationDialog: false,
                              canShowScrollHead: false,
                              canShowScrollStatus: false,
                              canShowHyperlinkDialog: false,
                              enableHyperlinkNavigation: false,
                              currentSearchTextHighlightColor:
                                  const Color(0xFFFF5A1F),
                              otherSearchTextHighlightColor:
                                  const Color(0xFFFFF176),
                              onDocumentLoaded: (details) {
                                if (!mounted) {
                                  return;
                                }
                                if (!_restoredZoomApplied && boot.initialZoom > 1.0) {
                                  _restoredZoomApplied = true;
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (!mounted) {
                                      return;
                                    }
                                    _controller.zoomLevel = boot.initialZoom.clamp(
                                      _minZoom,
                                      _maxZoom,
                                    );
                                  });
                                }
                                setState(() {
                                  _pagesCount = details.document.pages.count;
                                  _currentPage = _controller.pageNumber;
                                  _currentZoom = boot.initialZoom.clamp(
                                    _minZoom,
                                    _maxZoom,
                                  );
                                });
                                _showPageHudTemporarily();
                              },
                              onDocumentLoadFailed: (details) {
                                _showDocumentError(
                                  '${details.error}: ${details.description}',
                                );
                              },
                              onPageChanged: (details) {
                                if (!mounted) {
                                  return;
                                }
                                setState(() {
                                  _currentPage = details.newPageNumber;
                                });
                                _hidePageHud();
                                _schedulePersistViewState();
                              },
                              onZoomLevelChanged: (details) {
                                if (!mounted) {
                                  return;
                                }
                                setState(() {
                                  _currentZoom = details.newZoomLevel.clamp(
                                    _minZoom,
                                    _maxZoom,
                                  );
                                });
                                _hidePageHud();
                                _schedulePersistViewState();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.quickPages.isNotEmpty && _isTopOverlaysVisible)
                      Positioned(
                        left: 12,
                        top: 12,
                        child: _QuickPagesBar(
                          pages: widget.quickPages,
                          currentPage: _currentPage,
                          onTapPage: _goToPage,
                        ),
                      ),
                    if (_isSearchOpen &&
                        _searchTextController.text.trim().isNotEmpty)
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
                        top: (_isTopOverlaysVisible &&
                                (widget.quickPages.isNotEmpty ||
                                    _blockJumps.isNotEmpty))
                            ? 108
                            : 12,
                        right: 12,
                        child: _ModeBadge(
                          label:
                              'Стр. $_currentPage · ${(_currentZoom * 100).round()}%',
                        ),
                      ),
                    if (_pagesCount > 1 && _isPageHudVisible)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: _PageHud(
                          current: _currentPage,
                          total: _pagesCount,
                          canGoBack: _currentPage > 1,
                          canGoForward: _currentPage < _pagesCount,
                          onBack: () => _goToPage(_currentPage - 1),
                          onForward: () => _goToPage(_currentPage + 1),
                          onTap: () => _openPageNavigator(context),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_PdfViewerBoot> _prepareBoot() async {
    final settings = AppSettingsStore.instance;
    await settings.ensureLoaded();
    final cachedPdf = await PdfAssetCache.instance.load(widget.assetPath);
    final savedState = await settings.loadPdfViewState(widget.assetPath);

    if (settings.keepScreenAwakeInPdf) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }

    return _PdfViewerBoot(
      bytes: cachedPdf,
      initialPage: savedState?.page ?? widget.initialPage,
      initialZoom: savedState?.zoom ?? _minZoom,
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
      if (!mounted) {
        return;
      }
      FocusScope.of(context).requestFocus(FocusNode());
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

  void _rotateViewer() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
    _showPageHudTemporarily();
  }

  void _togglePageHud() {
    if (_isPageHudVisible) {
      _hidePageHud();
      return;
    }
    _showPageHudTemporarily();
  }

  void _showPageHudTemporarily() {
    if (!mounted || _pagesCount <= 1) {
      return;
    }
    setState(() {
      _isPageHudVisible = true;
      _isTopOverlaysVisible = true;
    });
    _hudAutoHideTimer?.cancel();
    _hudAutoHideTimer = Timer(
      const Duration(milliseconds: 1800),
      _hidePageHud,
    );
  }

  void _hidePageHud() {
    _hudAutoHideTimer?.cancel();
    if (!mounted || (!_isPageHudVisible && !_isTopOverlaysVisible)) {
      return;
    }
    setState(() {
      _isPageHudVisible = false;
      _isTopOverlaysVisible = false;
    });
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
    _showPageHudTemporarily();
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

  void _schedulePersistViewState() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(
      const Duration(milliseconds: 450),
      _persistViewState,
    );
  }

  Future<void> _persistViewState() {
    return AppSettingsStore.instance.savePdfViewState(
      widget.assetPath,
      page: _currentPage,
      zoom: _currentZoom,
    );
  }

  List<_BlockJump> _resolveBlockJumps(String assetPath) {
    switch (assetPath) {
      case 'assets/pdfs/dnk10_schema.pdf':
        return const [
          _BlockJump(label: 'R1', pages: [5]),
          _BlockJump(label: 'R2', pages: [6, 7]),
          _BlockJump(label: 'R3', pages: [8, 9]),
          _BlockJump(label: 'R4', pages: [10, 11]),
          _BlockJump(label: 'R5', pages: [14]),
        ];
      case 'assets/pdfs/dnk14_schema.pdf':
        return const [
          _BlockJump(label: 'R1', pages: [3]),
          _BlockJump(label: 'R2', pages: [4]),
          _BlockJump(label: 'R3', pages: [5]),
          _BlockJump(label: 'R4', pages: [6]),
          _BlockJump(label: 'R5', pages: [7]),
        ];
      case 'assets/pdfs/dnk17_schema.pdf':
        return const [
          _BlockJump(label: 'R1', pages: [4]),
          _BlockJump(label: 'R2', pages: [5]),
          _BlockJump(label: 'R3', pages: [6]),
          _BlockJump(label: 'R4', pages: [7]),
          _BlockJump(label: 'R5', pages: [8]),
        ];
      default:
        return const [];
    }
  }
}

class _PdfViewerBoot {
  const _PdfViewerBoot({
    required this.bytes,
    required this.initialPage,
    required this.initialZoom,
  });

  final Uint8List bytes;
  final int initialPage;
  final double initialZoom;
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
  final List<_BlockJump> blockJumps;
  final ValueChanged<_BlockJump> onJump;

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
    this.blockJumps = const [],
    required this.onJump,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
          if (blockJumps.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: blockJumps
                    .map(
                      (jump) => ActionChip(
                        avatar: const Icon(Icons.account_tree_outlined, size: 16),
                        label: Text('${jump.label} · ${jump.pagesLabel}'),
                        onPressed: () => onJump(jump),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PageHud extends StatelessWidget {
  final int current;
  final int total;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onTap;

  const _PageHud({
    required this.current,
    required this.total,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Предыдущая страница',
            onPressed: canGoBack ? onBack : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Стр. $current / $total',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.swap_horiz, size: 18),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Следующая страница',
            onPressed: canGoForward ? onForward : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
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

class _BlockJump {
  final String label;
  final List<int> pages;

  const _BlockJump({
    required this.label,
    required this.pages,
  });

  String get pagesLabel {
    if (pages.isEmpty) {
      return '';
    }
    if (pages.length == 1) {
      return pages.first.toString();
    }
    return '${pages.first}-${pages.last}';
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
            'Схема откроется там, где ты остановился в прошлый раз.',
            style: textTheme.bodySmall?.copyWith(color: const Color(0xFF9EA7B3)),
          ),
        ],
      ),
    );
  }
}
