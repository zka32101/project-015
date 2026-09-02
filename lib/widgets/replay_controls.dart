import 'package:flutter/material.dart';

import '../engine/game_replay.dart';
import '../engine/models.dart';

/// Complete replay control interface with timeline and playback
class ReplayControlsPanel extends StatefulWidget {
  final GameReplay replay;
  final VoidCallback onMoveChanged;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const ReplayControlsPanel({
    Key? key,
    required this.replay,
    required this.onMoveChanged,
    this.isPlaying = false,
    required this.onPlayPause,
  }) : super(key: key);

  @override
  State<ReplayControlsPanel> createState() => _ReplayControlsPanelState();
}

class _ReplayControlsPanelState extends State<ReplayControlsPanel> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = (widget.replay.currentMoveIndex + 1).toDouble();
  }

  @override
  void didUpdateWidget(ReplayControlsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sliderValue = (widget.replay.currentMoveIndex + 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Move counter and progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Move ${widget.replay.currentMoveIndex + 1} / ${widget.replay.totalMoves}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${(widget.replay.progressPercent * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress slider
          Slider(
            value: _sliderValue,
            min: 0,
            max: (widget.replay.totalMoves).toDouble(),
            divisions: widget.replay.totalMoves,
            label: 'Move ${_sliderValue.toInt()}',
            onChanged: (value) {
              setState(() {
                _sliderValue = value;
              });
              widget.replay.jumpToMove(value.toInt() - 1);
              widget.onMoveChanged();
            },
          ),

          const SizedBox(height: 16),

          // Playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Go to start
              IconButton(
                onPressed: widget.replay.currentMoveIndex > 0
                    ? () {
                        widget.replay.jumpToStart();
                        setState(() {
                          _sliderValue = 0;
                        });
                        widget.onMoveChanged();
                      }
                    : null,
                icon: const Icon(Icons.skip_previous),
                tooltip: 'Go to start',
              ),

              // Previous move
              IconButton(
                onPressed: widget.replay.canMoveBackward
                    ? () {
                        widget.replay.moveBackward();
                        setState(() {
                          _sliderValue = (widget.replay.currentMoveIndex + 1).toDouble();
                        });
                        widget.onMoveChanged();
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous move',
              ),

              const SizedBox(width: 8),

              // Play/Pause
              ElevatedButton.icon(
                onPressed: widget.onPlayPause,
                icon: Icon(
                  widget.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                label: Text(widget.isPlaying ? 'Pause' : 'Play'),
              ),

              const SizedBox(width: 8),

              // Next move
              IconButton(
                onPressed: widget.replay.canMoveForward
                    ? () {
                        widget.replay.moveForward();
                        setState(() {
                          _sliderValue = (widget.replay.currentMoveIndex + 1).toDouble();
                        });
                        widget.onMoveChanged();
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next move',
              ),

              // Go to end
              IconButton(
                onPressed: widget.replay.currentMoveIndex < widget.replay.totalMoves - 1
                    ? () {
                        widget.replay.jumpToEnd();
                        setState(() {
                          _sliderValue = widget.replay.totalMoves.toDouble();
                        });
                        widget.onMoveChanged();
                      }
                    : null,
                icon: const Icon(Icons.skip_next),
                tooltip: 'Go to end',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact replay timeline showing all moves
class ReplayTimeline extends StatelessWidget {
  final GameReplay replay;
  final VoidCallback onMoveChanged;

  const ReplayTimeline({
    Key? key,
    required this.replay,
    required this.onMoveChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            // Initial position button
            _TimelineButton(
              label: '初',
              isSelected: replay.currentMoveIndex == -1,
              onPressed: () {
                replay.jumpToStart();
                onMoveChanged();
              },
            ),
            const SizedBox(width: 4),
            // Move buttons
            ...List.generate(
              replay.totalMoves,
              (index) {
                final move = replay.getMoveAt(index);
                if (move == null) return const SizedBox.shrink();

                return _TimelineButton(
                  label: '${index + 1}',
                  isSelected: replay.currentMoveIndex == index,
                  onPressed: () {
                    replay.jumpToMove(index);
                    onMoveChanged();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual timeline button for move selection
class _TimelineButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _TimelineButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.blue[900]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.blue[300]! : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// Move information display
class ReplayMoveInfo extends StatelessWidget {
  final GameReplay replay;

  const ReplayMoveInfo({
    Key? key,
    required this.replay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentMove = replay.currentMove;
    final nextMove = replay.nextMove;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replay.getCurrentPositionDescription(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          if (currentMove != null) ...[
            Text(
              'Current move: ${currentMove.from.row}${currentMove.from.col} → ${currentMove.to.row}${currentMove.to.col}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Courier',
              ),
            ),
          ] else ...[
            Text(
              'Initial board position',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (nextMove != null) ...[
            const SizedBox(height: 6),
            Text(
              'Next move: ${nextMove.from.row}${nextMove.from.col} → ${nextMove.to.row}${nextMove.to.col}',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontFamily: 'Courier',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Speed control for automatic playback
class ReplaySpeedControl extends StatelessWidget {
  final double speed; // 1.0 = normal, 0.5 = slow, 2.0 = fast
  final ValueChanged<double> onSpeedChanged;

  const ReplaySpeedControl({
    Key? key,
    required this.speed,
    required this.onSpeedChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '再生速度',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: speed,
                  min: 0.25,
                  max: 2.0,
                  divisions: 7,
                  label: '${speed.toStringAsFixed(2)}x',
                  onChanged: onSpeedChanged,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${speed.toStringAsFixed(2)}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
