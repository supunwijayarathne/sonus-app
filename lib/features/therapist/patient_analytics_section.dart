import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/analysis_result.dart';
import '../../models/patient_analytics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/format.dart';
import '../../widgets/result_note.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_tile.dart';

/// "Practice analytics" on the therapist's user profile: activity, the match
/// trend chart, the most frequent possible differences, sounds and words.
///
/// Wording follows CLAUDE.md rule 1: "match with the expected sounds",
/// never "accuracy" or "progress".
class PatientAnalyticsSection extends StatelessWidget {
  const PatientAnalyticsSection({super.key, required this.analytics});

  final PatientAnalytics analytics;

  static const note =
      'These numbers compare the detected sounds with the expected sounds. '
      'They are suggestions for your review, not a measure of speech health '
      'or therapy progress.';

  @override
  Widget build(BuildContext context) {
    final a = analytics;
    const gap = SizedBox(height: AppSpacing.sm + 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Practice analytics'),
        const SizedBox(height: AppSpacing.md),
        if (a.isEmpty)
          Text(
            'Analytics appear here after the first practice session.',
            style: AppTypography.small,
          )
        else ...[
          _ActivityTiles(analytics: a),
          gap,
          if (a.trend.isNotEmpty) ...[_MatchTrendCard(analytics: a), gap],
          _DifferencesCard(differences: a.differences),
          gap,
          _SoundsCard(sounds: a.sounds),
          gap,
          _WordsCard(words: a.words),
          gap,
          const ResultNote(message: note),
        ],
      ],
    );
  }
}

/// Rounded "card" used by every block in this section.
class _Panel extends StatelessWidget {
  const _Panel({required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: AppTypography.option),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle!, style: AppTypography.caption),
          ],
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

String _percent(double value) => '${value.round()}%';

// ----------------------------------------------------------------- activity

class _ActivityTiles extends StatelessWidget {
  const _ActivityTiles({required this.analytics});

  final PatientAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final a = analytics;
    const gap = SizedBox(width: AppSpacing.sm + 2);
    Widget row(Widget left, Widget right) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        gap,
        Expanded(child: right),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(
          StatTile(
            value: '${a.sessionsLast7Days}',
            label: 'Sessions, last 7 days',
          ),
          StatTile(value: '${a.daysActive}', label: 'Days active'),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        row(
          StatTile(value: '${a.wordsRecorded}', label: 'Words recorded'),
          StatTile(
            value: a.averageMatch == null ? '–' : _percent(a.averageMatch!),
            label: 'Average match',
          ),
        ),
        if (a.lastPracticeAt != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Last practice ${relativeDay(a.lastPracticeAt!)}.',
            style: AppTypography.caption,
          ),
        ],
      ],
    );
  }
}

// -------------------------------------------------------------- match trend

class _MatchTrendCard extends StatelessWidget {
  const _MatchTrendCard({required this.analytics});

  final PatientAnalytics analytics;

  String get _changeText {
    final change = analytics.changeSinceFirst;
    if (change == null) return 'One analysed session so far.';
    final points = change.round();
    if (points == 0) return 'Same as the first session.';
    final sign = points > 0 ? '+' : '−';
    return '$sign${points.abs()} points since the first session.';
  }

  @override
  Widget build(BuildContext context) {
    final trend = analytics.trend;
    final spokenPoints = [
      for (final p in trend) '${shortDate(p.at)} ${_percent(p.matchPercent)}',
    ].join(', ');

    return _Panel(
      title: 'Match with expected sounds',
      subtitle: 'Average per session, 0–100%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Match per session: $spokenPoints',
            excludeSemantics: true,
            child: SizedBox(height: 180, child: LineChart(_chartData(trend))),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Row(
            children: [
              const Icon(
                Icons.show_chart_rounded,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(_changeText, style: AppTypography.small)),
            ],
          ),
        ],
      ),
    );
  }

  LineChartData _chartData(List<TrendPoint> trend) {
    final last = trend.length - 1;
    final labelStyle = AppTypography.caption.copyWith(height: 1.2);

    // Dates under the first and last point (and all of them when few).
    Widget bottomLabel(double value, TitleMeta meta) {
      final i = value.round();
      final show = value == i && (trend.length <= 4 || i == 0 || i == last);
      if (!show || i < 0 || i > last) return const SizedBox.shrink();
      return SideTitleWidget(
        meta: meta,
        child: Text(shortDate(trend[i].at), style: labelStyle),
      );
    }

    Widget leftLabel(double value, TitleMeta meta) => SideTitleWidget(
      meta: meta,
      child: Text('${value.round()}%', style: labelStyle),
    );

    return LineChartData(
      minY: 0,
      maxY: 100,
      // A single session still gets some width.
      minX: last == 0 ? -0.5 : 0,
      maxX: last == 0 ? 0.5 : last.toDouble(),
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: 25,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: AppColors.border, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 25,
            reservedSize: 40,
            getTitlesWidget: leftLabel,
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 28,
            getTitlesWidget: bottomLabel,
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.surfaceRaised,
          getTooltipItems: (spots) => [
            for (final s in spots)
              LineTooltipItem(
                '${shortDate(trend[s.x.round()].at)}\n${_percent(s.y)} match',
                AppTypography.small.copyWith(color: AppColors.textPrimary),
              ),
          ],
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (var i = 0; i < trend.length; i++)
              FlSpot(i.toDouble(), trend[i].matchPercent),
          ],
          color: AppColors.accent,
          barWidth: 3,
          isCurved: false,
          dotData: FlDotData(
            getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
              radius: 4,
              color: AppColors.accent,
              strokeColor: AppColors.surface,
              strokeWidth: 2,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.accent.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- differences

/// A horizontal bar, [fraction] 0.0 - 1.0 of the full width.
class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Stack(
        children: [
          Container(height: 8, color: AppColors.surfaceRaised),
          FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            child: Container(height: 8, color: color),
          ),
        ],
      ),
    );
  }
}

class _DifferencesCard extends StatelessWidget {
  const _DifferencesCard({required this.differences});

  final List<DifferenceCount> differences;

  static IconData _icon(OpKind kind) => switch (kind) {
    OpKind.sub => Icons.swap_horiz_rounded,
    OpKind.del => Icons.remove_circle_outline_rounded,
    OpKind.ins => Icons.add_circle_outline_rounded,
    OpKind.match => Icons.check_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final top = differences.take(5).toList();
    final most = top.isEmpty ? 1 : top.first.count;

    return _Panel(
      title: 'Most frequent possible differences',
      subtitle: 'Expected sound → detected sound',
      child: top.isEmpty
          ? Text(
              'No possible differences in the analysed recordings.',
              style: AppTypography.small,
            )
          : Column(
              children: [
                for (final d in top)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                    child: Semantics(
                      label: '${d.key.label}, ${plural(d.count, 'time')}',
                      excludeSemantics: true,
                      child: Row(
                        children: [
                          Icon(
                            _icon(d.key.kind),
                            size: 18,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          SizedBox(
                            width: 92,
                            child: Text(
                              d.key.label,
                              style: AppTypography.option.copyWith(
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _Bar(
                              fraction: d.count / most,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '×${d.count}',
                              textAlign: TextAlign.end,
                              style: AppTypography.small,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ------------------------------------------------------------------ sounds

class _SoundsCard extends StatelessWidget {
  const _SoundsCard({required this.sounds});

  final List<SoundStat> sounds;

  @override
  Widget build(BuildContext context) {
    final notAlways = sounds.where((s) => s.matched < s.total).take(8).toList();
    final always = sounds.where((s) => s.matched == s.total).length;

    return _Panel(
      title: 'Sounds by match',
      subtitle: 'How often each expected sound was matched',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in notAlways)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
              child: Semantics(
                label: '${s.sound}: ${s.matched} of ${s.total} matched',
                excludeSemantics: true,
                child: Row(
                  children: [
                    Container(
                      constraints: const BoxConstraints(minWidth: 36),
                      height: 28,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppColors.warningSurface,
                        border: Border.all(color: AppColors.warningBorder),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(s.sound, style: AppTypography.option),
                    ),
                    const SizedBox(width: AppSpacing.md - 4),
                    Expanded(
                      child: _Bar(fraction: s.rate, color: AppColors.accent),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 92,
                      child: Text(
                        '${s.matched} of ${s.total} matched',
                        textAlign: TextAlign.end,
                        style: AppTypography.small.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Text(
            notAlways.isEmpty
                ? 'Every expected sound was matched in the analysed recordings.'
                : '${plural(always, 'other sound')} matched every time.',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- words

class _WordsCard extends StatelessWidget {
  const _WordsCard({required this.words});

  final List<WordStat> words;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Words',
      subtitle: 'Average match per word, lowest first',
      child: Column(
        children: [
          for (final w in words)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      w.text,
                      style: AppTypography.option.copyWith(
                        fontFamily: AppTypography.sinhalaFamily,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Text(
                    plural(w.attempts, 'attempt'),
                    style: AppTypography.small.copyWith(fontSize: 13),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 48,
                    child: Text(
                      _percent(w.averageMatch),
                      textAlign: TextAlign.end,
                      style: AppTypography.option,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
