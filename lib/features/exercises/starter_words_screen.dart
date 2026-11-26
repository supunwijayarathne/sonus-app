import 'package:material_ui/material_ui.dart';

import '../../services/g2p.dart';
import '../../services/practice_repository.dart';
import '../../services/reference_audio.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/round_back_button.dart';
import '../auth/auth_common.dart';

/// Therapist adds starter words to the exercise library: 100 words chosen
/// for common sound substitutions, each with a computer-voice reference.
class StarterWordsScreen extends StatefulWidget {
  const StarterWordsScreen({
    super.key,
    required this.therapistId,
    this.alreadyAdded = const {},
  });

  final String therapistId;

  /// Texts already in the therapist's library (shown, but not added twice).
  final Set<String> alreadyAdded;

  @override
  State<StarterWordsScreen> createState() => _StarterWordsScreenState();
}

class _StarterWordsScreenState extends State<StarterWordsScreen> {
  final _selected = <String>{}; // word ids
  String? _playingId;
  bool _busy = false;
  String? _error;

  List<StarterWord> get _addable => [
    for (final w in starterWords.words)
      if (!widget.alreadyAdded.contains(w.text)) w,
  ];

  @override
  void dispose() {
    if (_playingId != null) referencePlayer.stop();
    super.dispose();
  }

  Future<void> _listen(StarterWord word) async {
    if (_playingId != null) await referencePlayer.stop();
    setState(() => _playingId = word.id);
    try {
      await referencePlayer.play(word.assetPath);
    } catch (_) {
      // Ends quietly; the therapist can try again.
    }
    if (mounted && _playingId == word.id) setState(() => _playingId = null);
  }

  Future<void> _add() async {
    final words = [
      for (final w in starterWords.words)
        if (_selected.contains(w.id)) w,
    ];
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      for (final word in words) {
        await practiceRepository.createExercise(
          therapistId: widget.therapistId,
          text: SinhalaG2p.convert(word.text).text,
          romanized: '',
          // The analysis service's G2P, so the library shows what results
          // are compared with.
          expectedPhonemes: word.expected,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            words.length == 1
                ? '1 exercise added.'
                : '${words.length} exercises added.',
          ),
        ),
      );
      Navigator.pop(context);
    } on DataFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addable = _addable;
    final allSelected =
        addable.isNotEmpty && addable.every((w) => _selected.contains(w.id));
    final count = _selected.length;

    return Scaffold(
      body: ResponsivePage(
        builder: (context, scale) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const SizedBox(
                  width: 64,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: RoundBackButton(),
                  ),
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Starter words',
                      textAlign: TextAlign.center,
                      style: AppTypography.barTitle,
                    ),
                  ),
                ),
                const SizedBox(width: 64),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '${starterWords.words.length} words chosen for common sound '
              'substitutions, each with a computer-voice reference. Tap the '
              'speaker to listen before adding.',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: addable.isEmpty
                    ? null
                    : () => setState(() {
                        if (allSelected) {
                          _selected.clear();
                        } else {
                          _selected.addAll(addable.map((w) => w.id));
                        }
                      }),
                child: Text(allSelected ? 'Clear selection' : 'Select all'),
              ),
            ),
            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final word in starterWords.words)
                    _WordTile(
                      word: word,
                      added: widget.alreadyAdded.contains(word.text),
                      selected: _selected.contains(word.id),
                      playing: _playingId == word.id,
                      onChanged: (on) => setState(
                        () => on
                            ? _selected.add(word.id)
                            : _selected.remove(word.id),
                      ),
                      onListen: () => _playingId == word.id
                          ? referencePlayer.stop()
                          : _listen(word),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                FormError(_error!),
                const SizedBox(height: AppSpacing.sm),
              ],
              FilledButton(
                onPressed: count == 0 || _busy ? null : _add,
                child: _busy
                    ? const ButtonSpinner()
                    : Text(
                        count == 0
                            ? 'Choose words to add'
                            : count == 1
                            ? 'Add 1 exercise'
                            : 'Add $count exercises',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One starter word: checkbox, Sinhala, meaning and focus, listen button.
class _WordTile extends StatelessWidget {
  const _WordTile({
    required this.word,
    required this.added,
    required this.selected,
    required this.playing,
    required this.onChanged,
    required this.onListen,
  });

  final StarterWord word;
  final bool added;
  final bool selected;
  final bool playing;
  final ValueChanged<bool> onChanged;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: added || selected,
      onChanged: added ? null : (on) => onChanged(on ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.accent,
      title: Text(
        word.text,
        style: AppTypography.scaled(AppTypography.sinhalaWord, 0.45),
      ),
      subtitle: Text(
        added
            ? '${word.english} · already in your library'
            : '${word.english} · ${word.focus}',
        style: AppTypography.small,
      ),
      secondary: IconButton(
        onPressed: onListen,
        tooltip: playing ? 'Stop ${word.text}' : 'Listen to ${word.text}',
        icon: Icon(
          playing ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
          color: AppColors.accent,
        ),
      ),
    );
  }
}
