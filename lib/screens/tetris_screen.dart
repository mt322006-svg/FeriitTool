import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class TetrisScreen extends StatefulWidget {
  const TetrisScreen({super.key});

  @override
  State<TetrisScreen> createState() => _TetrisScreenState();
}

class _TetrisScreenState extends State<TetrisScreen>
    with WidgetsBindingObserver {
  static const int cols = 10;
  static const int rows = 18;
  static const _saveKey = 'tetris_saved_state_v1';
  final _rnd = Random();
  late List<List<Color?>> board;
  late List<List<String?>> boardLabels;
  Piece? current;
  Timer? timer;
  int score = 0;
  int lines = 0;
  int level = 1;
  bool gameOver = false;
  String? _streakMessage;
  Timer? _streakMessageTimer;
  Timer? _attentionTimer;
  Timer? _heartbeatTimer;
  DateTime _lastInteractionAt = DateTime.now();
  DateTime? _attentionSnoozeUntil;
  bool _isAttentionDialogOpen = false;
  bool _prizeOffered = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initGame();
  }

  @override
  void dispose() {
    _saveGameState();
    WakelockPlus.disable();
    timer?.cancel();
    _streakMessageTimer?.cancel();
    _attentionTimer?.cancel();
    _heartbeatTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pauseGame();
    }
  }

  Future<void> _initGame() async {
    await WakelockPlus.enable();
    final restored = await _tryRestoreGame();
    if (!mounted) return;
    if (!restored) {
      _reset(clearSaved: false);
    }
  }

  void _reset({bool clearSaved = true}) {
    board = List.generate(rows, (_) => List.filled(cols, null));
    boardLabels = List.generate(rows, (_) => List.filled(cols, null));
    score = 0;
    lines = 0;
    level = 1;
    gameOver = false;
    _streakMessage = null;
    _prizeOffered = false;
    _isPaused = false;
    current = _newPiece();
    _restartTimer();
    _startAttentionTimer();
    _startHeartbeatTimer();
    _lastInteractionAt = DateTime.now();
    _attentionSnoozeUntil = null;
    if (clearSaved) {
      _clearSavedGame();
    } else {
      _saveGameState();
    }
    setState(() {});
  }

  void _restartTimer() {
    timer?.cancel();
    final ms = max(120, 700 - (level - 1) * 60);
    timer = Timer.periodic(Duration(milliseconds: ms), (_) => _tick());
  }

  void _pauseGame() {
    if (gameOver) return;
    _isPaused = true;
    timer?.cancel();
    _saveGameState();
    if (mounted) {
      setState(() {});
    }
  }

  void _resumeGame() {
    if (gameOver) return;
    if (current == null) {
      current = _newPiece();
      if (!_fits(current!)) {
        gameOver = true;
        _saveGameState();
        if (mounted) {
          setState(() {});
        }
        return;
      }
    }
    _isPaused = false;
    _markInteraction();
    _restartTimer();
    _startHeartbeatTimer();
    _saveGameState();
    if (mounted) {
      setState(() {});
    }
  }

  void _startAttentionTimer() {
    _attentionTimer?.cancel();
    _attentionTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _maybeShowAttentionDialog();
    });
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || gameOver || _isPaused) return;
      if (current == null) {
        current = _newPiece();
        if (!_fits(current!)) {
          gameOver = true;
          timer?.cancel();
        }
        setState(() {});
      }
      if (timer == null || !(timer?.isActive ?? false)) {
        _restartTimer();
      }
    });
  }

  void _markInteraction() {
    _lastInteractionAt = DateTime.now();
  }

  void _maybeShowAttentionDialog() {
    if (!mounted || gameOver || _isAttentionDialogOpen) {
      return;
    }
    final now = DateTime.now();
    if (_attentionSnoozeUntil != null && now.isBefore(_attentionSnoozeUntil!)) {
      return;
    }
    final idle = now.difference(_lastInteractionAt);
    if (idle < const Duration(minutes: 10)) {
      return;
    }
    _isAttentionDialogOpen = true;
    showDialog<_AttentionChoice>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Attention'),
        content: const Text('Работать сегодня будешь? Или всё сделал?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _AttentionChoice.done),
            child: const Text('Сделал'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _AttentionChoice.notDone),
            child: const Text('Не сделал'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _AttentionChoice.oneMoreMinute),
            child: const Text('Еще минутку'),
          ),
        ],
      ),
    ).then((choice) {
      _isAttentionDialogOpen = false;
      if (!mounted) return;
      switch (choice) {
        case _AttentionChoice.done:
          _clearSavedGame();
          Navigator.pop(context);
          break;
        case _AttentionChoice.notDone:
          _markInteraction();
          break;
        case _AttentionChoice.oneMoreMinute:
          _attentionSnoozeUntil =
              DateTime.now().add(const Duration(minutes: 1));
          _markInteraction();
          break;
        case null:
          _markInteraction();
          break;
      }
    });
  }

  Piece _newPiece() {
    final shapes = <List<Point<int>>>[
      [
        const Point(0, 0),
        const Point(1, 0),
        const Point(-1, 0),
        const Point(2, 0)
      ],
      [
        const Point(0, 0),
        const Point(1, 0),
        const Point(-1, 0),
        const Point(-1, 1)
      ],
      [
        const Point(0, 0),
        const Point(1, 0),
        const Point(-1, 0),
        const Point(1, 1)
      ],
      [
        const Point(0, 0),
        const Point(1, 0),
        const Point(0, 1),
        const Point(1, 1)
      ],
      [
        const Point(0, 0),
        const Point(1, 0),
        const Point(0, 1),
        const Point(-1, 1)
      ],
      [
        const Point(0, 0),
        const Point(-1, 0),
        const Point(0, 1),
        const Point(1, 1)
      ],
      [
        const Point(0, 0),
        const Point(-1, 0),
        const Point(1, 0),
        const Point(0, 1)
      ],
    ];
    final colors = <Color>[
      Colors.cyan,
      Colors.blue,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.red,
      Colors.purple,
    ];
    const labels = <String>['R5', 'R1', 'R2', 'R3', 'R4', 'R7', 'R5'];
    final i = _rnd.nextInt(shapes.length);
    return Piece(
      x: cols ~/ 2,
      y: 0,
      blocks: shapes[i],
      color: colors[i],
      label: labels[i],
    );
  }

  bool _fits(Piece p, {int dx = 0, int dy = 0, List<Point<int>>? blocks}) {
    final b = blocks ?? p.blocks;
    for (final cell in b) {
      final x = p.x + dx + cell.x;
      final y = p.y + dy + cell.y;
      if (x < 0 || x >= cols || y >= rows) return false;
      if (y >= 0 && board[y][x] != null) return false;
    }
    return true;
  }

  void _tick() {
    if (gameOver || _isPaused) return;
    if (current == null) {
      current = _newPiece();
      if (!_fits(current!)) {
        gameOver = true;
        timer?.cancel();
      }
      setState(() {});
      return;
    }
    final p = current!;
    if (_fits(p, dy: 1)) {
      setState(() => current = p.copyWith(y: p.y + 1));
      return;
    }
    _lockPiece();
  }

  void _lockPiece() {
    final p = current!;
    for (final cell in p.blocks) {
      final x = p.x + cell.x;
      final y = p.y + cell.y;
      if (y < 0) {
        gameOver = true;
        timer?.cancel();
        setState(() {});
        return;
      }
      board[y][x] = p.color;
      boardLabels[y][x] = p.label;
    }
    _clearLines();
    current = _newPiece();
    if (!_fits(current!)) {
      gameOver = true;
      timer?.cancel();
    }
    _saveGameState();
    setState(() {});
  }

  void _clearLines() {
    int cleared = 0;
    for (int r = rows - 1; r >= 0; r--) {
      if (board[r].every((c) => c != null)) {
        board.removeAt(r);
        boardLabels.removeAt(r);
        board.insert(0, List.filled(cols, null));
        boardLabels.insert(0, List.filled(cols, null));
        cleared++;
        r++;
      }
    }
    if (cleared == 0) return;
    lines += cleared;
    score += switch (cleared) {
      1 => 100 * level,
      2 => 300 * level,
      3 => 500 * level,
      _ => 800 * level,
    };
    final nextLevel = 1 + (lines ~/ 10);
    if (nextLevel != level) {
      level = nextLevel;
      _restartTimer();
    }
    _showStreakMessage(cleared);
    _maybeOfferPrize();
  }

  void _maybeOfferPrize() {
    if (_prizeOffered || score < 1000 || !mounted) {
      return;
    }
    _prizeOffered = true;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Приз за 1000 очков'),
        content: const Text('Забрать приз: морепродукты?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              showDialog<void>(
                context: context,
                builder: (ctx2) => AlertDialog(
                  title: const Text('Краб от разработчика'),
                  content: const Text('Держи краба от разработчика 🦀'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx2),
                      child: const Text('Спасибо'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Забрать'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Позже'),
          ),
        ],
      ),
    );
  }

  void _showStreakMessage(int cleared) {
    if (cleared < 2) {
      return;
    }
    final messages = switch (cleared) {
      2 => const [
          'Дабл! Молодец, инженер.',
          'Чётко, мастер: двойная зачистка.',
          'Отлично сработано, сервисник.',
          'Двойной проход, как по мануалу.',
        ],
      3 => const [
          'Трипл! Инженер в ударе.',
          'Тройной вынос — красавчик.',
          'Вот это уже уровень старшего диагноста.',
          'Три линии. Сервис одобряет.',
        ],
      _ => const [
          'TETRIS! Респект, инженер!',
          'Четверной проход: будто R5 ожил.',
          'Легендарно. Премия по ТО твоя.',
          'Так играют те, кто чинит с душой.',
        ],
    };
    final text = messages[_rnd.nextInt(messages.length)];
    _streakMessageTimer?.cancel();
    setState(() => _streakMessage = text);
    _streakMessageTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _streakMessage = null);
    });
  }

  void _move(int dx) {
    if (gameOver || _isPaused || current == null) return;
    _markInteraction();
    final p = current!;
    if (_fits(p, dx: dx)) {
      setState(() => current = p.copyWith(x: p.x + dx));
      _saveGameState();
    }
  }

  void _drop() {
    if (_isPaused) return;
    _markInteraction();
    _tick();
    _saveGameState();
  }

  void _rotate() {
    if (gameOver || _isPaused || current == null) return;
    _markInteraction();
    final p = current!;
    if (p.color == Colors.yellow) return;
    final rotated = p.blocks.map((b) => Point(-b.y, b.x)).toList();
    if (_fits(p, blocks: rotated)) {
      setState(() => current = p.copyWith(blocks: rotated));
      _saveGameState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final cells = List.generate(rows * cols, (i) {
      final r = i ~/ cols;
      final c = i % cols;
      Color? color = board[r][c];
      String? label = boardLabels[r][c];
      final p = current;
      if (p != null) {
        for (final b in p.blocks) {
          if (p.x + b.x == c && p.y + b.y == r) {
            color = p.color;
            label = p.label;
          }
        }
      }
      return Container(
        margin: const EdgeInsets.all(0.8),
        decoration: BoxDecoration(
          color: color ?? const Color(0xFF1A2230),
          borderRadius: BorderRadius.circular(2),
        ),
        child: (color == null || label == null)
            ? null
            : Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color.computeLuminance() > 0.45
                        ? Colors.black
                        : Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ferrit Tetris'),
        actions: [
          IconButton(
            tooltip: _isPaused ? 'Продолжить' : 'Пауза',
            onPressed: gameOver
                ? null
                : () {
                    _isPaused ? _resumeGame() : _pauseGame();
                  },
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text('Очки: $score   Линии: $lines   Уровень: $level'),
            if (_isPaused) ...[
              const SizedBox(height: 6),
              const Text(
                'Пауза',
                style: TextStyle(
                  color: Color(0xFFFFB067),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            if (_streakMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                _streakMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFB067),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: AspectRatio(
                aspectRatio: cols / rows,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0x44FF8A3D)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: GridView.count(
                    crossAxisCount: cols,
                    physics: const NeverScrollableScrollPhysics(),
                    children: cells,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ctl(Icons.arrow_left, () => _move(-1)),
                _ctl(Icons.rotate_right, _rotate),
                _ctl(Icons.arrow_drop_down, _drop),
                _ctl(Icons.arrow_right, () => _move(1)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: gameOver
                    ? null
                    : () {
                        _isPaused ? _resumeGame() : _pauseGame();
                      },
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                label: Text(_isPaused ? 'Продолжить' : 'Пауза'),
              ),
            ),
            SizedBox(height: max(8.0, bottomInset)),
            if (gameOver) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _reset(),
                icon: const Icon(Icons.replay),
                label: const Text('Игра окончена · Начать заново'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ctl(IconData icon, VoidCallback onTap) {
    return ElevatedButton(onPressed: onTap, child: Icon(icon));
  }

  Future<void> _saveGameState() async {
    final p = current;
    if (p == null) return;
    final prefs = await SharedPreferences.getInstance();
    final state = <String, dynamic>{
      'board': board
          .map((row) => row.map((c) => c?.toARGB32()).toList(growable: false))
          .toList(growable: false),
      'labels': boardLabels
          .map((row) => row.map((l) => l).toList(growable: false))
          .toList(growable: false),
      'score': score,
      'lines': lines,
      'level': level,
      'gameOver': gameOver,
      'isPaused': _isPaused,
      'current': {
        'x': p.x,
        'y': p.y,
        'color': p.color.toARGB32(),
        'label': p.label,
        'blocks':
            p.blocks.map((b) => {'x': b.x, 'y': b.y}).toList(growable: false),
      },
    };
    await prefs.setString(_saveKey, jsonEncode(state));
  }

  Future<void> _clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }

  Future<bool> _tryRestoreGame() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw == null || raw.isEmpty) {
      return false;
    }
    if (!mounted) return false;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final action = await showDialog<_RestoreChoice>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Найдена сохранённая игра'),
        content: const Text('Продолжить с места выхода или начать заново?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _RestoreChoice.restart),
            child: const Text('Начать сначала'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _RestoreChoice.continueGame),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
    if (!mounted) return false;
    if (action != _RestoreChoice.continueGame) {
      await _clearSavedGame();
      return false;
    }

    final boardRaw = (decoded['board'] as List<dynamic>);
    final labelsRaw = (decoded['labels'] as List<dynamic>);
    board = boardRaw
        .map((row) => (row as List<dynamic>)
            .map((v) => v == null ? null : Color(v as int))
            .toList(growable: false))
        .toList(growable: false);
    boardLabels = labelsRaw
        .map((row) => (row as List<dynamic>)
            .map((v) => v?.toString())
            .toList(growable: false))
        .toList(growable: false);
    score = (decoded['score'] as num?)?.toInt() ?? 0;
    lines = (decoded['lines'] as num?)?.toInt() ?? 0;
    level = (decoded['level'] as num?)?.toInt() ?? 1;
    gameOver = decoded['gameOver'] == true;
    _isPaused = decoded['isPaused'] == true;

    final currentRaw = decoded['current'] as Map<String, dynamic>;
    final blocksRaw = currentRaw['blocks'] as List<dynamic>;
    current = Piece(
      x: (currentRaw['x'] as num).toInt(),
      y: (currentRaw['y'] as num).toInt(),
      color: Color((currentRaw['color'] as num).toInt()),
      label: (currentRaw['label'] ?? 'R5').toString(),
      blocks: blocksRaw
          .map((b) => Point<int>(
                (b['x'] as num).toInt(),
                (b['y'] as num).toInt(),
              ))
          .toList(growable: false),
    );

    _lastInteractionAt = DateTime.now();
    _attentionSnoozeUntil = null;
    if (!gameOver && !_isPaused) {
      _restartTimer();
    } else {
      timer?.cancel();
    }
    _startAttentionTimer();
    _startHeartbeatTimer();
    setState(() {});
    return true;
  }
}

enum _RestoreChoice { continueGame, restart }

enum _AttentionChoice { done, notDone, oneMoreMinute }

class Piece {
  const Piece({
    required this.x,
    required this.y,
    required this.blocks,
    required this.color,
    required this.label,
  });
  final int x;
  final int y;
  final List<Point<int>> blocks;
  final Color color;
  final String label;

  Piece copyWith({int? x, int? y, List<Point<int>>? blocks}) => Piece(
        x: x ?? this.x,
        y: y ?? this.y,
        blocks: blocks ?? this.blocks,
        color: color,
        label: label,
      );
}
