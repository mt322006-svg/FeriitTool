import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class TetrisScreen extends StatefulWidget {
  const TetrisScreen({super.key});

  @override
  State<TetrisScreen> createState() => _TetrisScreenState();
}

class _TetrisScreenState extends State<TetrisScreen> {
  static const int cols = 10;
  static const int rows = 18;
  final _rnd = Random();
  late List<List<Color?>> board;
  Piece? current;
  Timer? timer;
  int score = 0;
  int lines = 0;
  int level = 1;
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _reset() {
    board = List.generate(rows, (_) => List.filled(cols, null));
    score = 0;
    lines = 0;
    level = 1;
    gameOver = false;
    current = _newPiece();
    _restartTimer();
    setState(() {});
  }

  void _restartTimer() {
    timer?.cancel();
    final ms = max(120, 700 - (level - 1) * 60);
    timer = Timer.periodic(Duration(milliseconds: ms), (_) => _tick());
  }

  Piece _newPiece() {
    final shapes = <List<Point<int>>>[
      [const Point(0, 0), const Point(1, 0), const Point(-1, 0), const Point(2, 0)],
      [const Point(0, 0), const Point(1, 0), const Point(-1, 0), const Point(-1, 1)],
      [const Point(0, 0), const Point(1, 0), const Point(-1, 0), const Point(1, 1)],
      [const Point(0, 0), const Point(1, 0), const Point(0, 1), const Point(1, 1)],
      [const Point(0, 0), const Point(1, 0), const Point(0, 1), const Point(-1, 1)],
      [const Point(0, 0), const Point(-1, 0), const Point(0, 1), const Point(1, 1)],
      [const Point(0, 0), const Point(-1, 0), const Point(1, 0), const Point(0, 1)],
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
    final i = _rnd.nextInt(shapes.length);
    return Piece(
      x: cols ~/ 2,
      y: 0,
      blocks: shapes[i],
      color: colors[i],
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
    if (gameOver || current == null) return;
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
    }
    _clearLines();
    current = _newPiece();
    if (!_fits(current!)) {
      gameOver = true;
      timer?.cancel();
    }
    setState(() {});
  }

  void _clearLines() {
    int cleared = 0;
    for (int r = rows - 1; r >= 0; r--) {
      if (board[r].every((c) => c != null)) {
        board.removeAt(r);
        board.insert(0, List.filled(cols, null));
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
  }

  void _move(int dx) {
    if (gameOver || current == null) return;
    final p = current!;
    if (_fits(p, dx: dx)) setState(() => current = p.copyWith(x: p.x + dx));
  }

  void _drop() {
    _tick();
  }

  void _rotate() {
    if (gameOver || current == null) return;
    final p = current!;
    if (p.color == Colors.yellow) return;
    final rotated = p.blocks.map((b) => Point(-b.y, b.x)).toList();
    if (_fits(p, blocks: rotated)) {
      setState(() => current = p.copyWith(blocks: rotated));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final cells = List.generate(rows * cols, (i) {
      final r = i ~/ cols;
      final c = i % cols;
      Color? color = board[r][c];
      final p = current;
      if (p != null) {
        for (final b in p.blocks) {
          if (p.x + b.x == c && p.y + b.y == r) color = p.color;
        }
      }
      return Container(
        margin: const EdgeInsets.all(0.8),
        decoration: BoxDecoration(
          color: color ?? const Color(0xFF1A2230),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Ferrit Tetris')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text('Очки: $score   Линии: $lines   Уровень: $level'),
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
            SizedBox(height: max(8.0, bottomInset)),
            if (gameOver) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _reset,
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
}

class Piece {
  const Piece({
    required this.x,
    required this.y,
    required this.blocks,
    required this.color,
  });
  final int x;
  final int y;
  final List<Point<int>> blocks;
  final Color color;

  Piece copyWith({int? x, int? y, List<Point<int>>? blocks}) => Piece(
        x: x ?? this.x,
        y: y ?? this.y,
        blocks: blocks ?? this.blocks,
        color: color,
      );
}
