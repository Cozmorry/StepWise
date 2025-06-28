import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/activity_record.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenHint = prefs.getBool('trends_hint_seen') ?? false;
    if (!hasSeenHint) {
      setState(() {
        _showHint = true;
      });
    }
  }

  Future<void> _dismissHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trends_hint_seen', true);
    setState(() {
      _showHint = false;
    });
  }

  List<ActivityRecord> _getLastNDays(Box<ActivityRecord> box, int n) {
    final now = DateTime.now();
    return List.generate(n, (i) {
      final date = now.subtract(Duration(days: n - 1 - i));
      final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      return box.get(key) ?? ActivityRecord(date: date, steps: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final activityBox = Hive.box<ActivityRecord>('activity_log');
    final last7 = _getLastNDays(activityBox, 7);
    return Scaffold(
      backgroundColor: AppColors.getBackground(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(brightness),
        elevation: 0,
        title: Text('Trends', style: AppTextStyles.title(brightness)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (_showHint)
              _buildHintBanner(context),
            _buildShareableChartSection(
              context,
              'Steps (last 7 days)',
              last7.map((r) => r.steps.toDouble()).toList(),
              last7.map((r) => r.date).toList(),
              brightness,
              color: Colors.blue,
              yLabelFormat: (v) => NumberFormat.compact().format(v),
            ),
            const SizedBox(height: 24),
            _buildShareableChartSection(
              context,
              'Calories (last 7 days)',
              last7.map((r) => (r.calories ?? 0).toDouble()).toList(),
              last7.map((r) => r.date).toList(),
              brightness,
              color: Colors.redAccent,
              yLabelFormat: (v) => NumberFormat.compact().format(v),
            ),
            const SizedBox(height: 24),
            _buildShareableChartSection(
              context,
              'Distance (km, last 7 days)',
              last7.map((r) => (r.distance ?? 0.0)).toList(),
              last7.map((r) => r.date).toList(),
              brightness,
              color: Colors.green,
              yLabelFormat: (v) => v.toStringAsFixed(1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintBanner(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Card(
      color: AppColors.getSecondary(brightness),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.lightbulb_outline,
              color: Colors.amber,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Tip: Share your progress!',
                    style: AppTextStyles.subtitle(brightness).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Long press on any graph to share it with friends',
                    style: AppTextStyles.body(brightness),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.grey[600]),
              onPressed: _dismissHint,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareableChartSection(
    BuildContext context,
    String title,
    List<double> data,
    List<DateTime> dates,
    Brightness brightness, {
    required Color color,
    required String Function(num) yLabelFormat,
  }) {
    final repaintKey = GlobalKey();
    return GestureDetector(
      onLongPress: () async {
        HapticFeedback.vibrate();
        // Capture chart as image
        final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 3.0);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final pngBytes = byteData.buffer.asUint8List();
            final tempDir = await getTemporaryDirectory();
            final file = await File('${tempDir.path}/${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png').create();
            await file.writeAsBytes(pngBytes);
            await Share.shareXFiles([XFile(file.path)], text: 'Check out my $title progress on StepWise!');
          }
        }
      },
      child: RepaintBoundary(
        key: repaintKey,
        child: _buildChartSection(title, data, dates, brightness, color: color, yLabelFormat: yLabelFormat),
      ),
    );
  }

  Widget _buildChartSection(
    String title,
    List<double> data,
    List<DateTime> dates,
    Brightness brightness, {
    required Color color,
    required String Function(num) yLabelFormat,
  }) {
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final avg = data.isNotEmpty ? (data.reduce((a, b) => a + b) / data.length) : 0.0;
    return Card(
      color: AppColors.getSecondary(brightness),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.subtitle(brightness)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Min: ${yLabelFormat(min)}', style: AppTextStyles.body(brightness).copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                Text('Max: ${yLabelFormat(max)}', style: AppTextStyles.body(brightness).copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                Text('Avg: ${yLabelFormat(avg)}', style: AppTextStyles.body(brightness).copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: (max > 0) ? (max / 4).ceilToDouble() : 1,
                    getDrawingHorizontalLine: (value) => const FlLine(
                      color: Colors.white24,
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => const FlLine(
                      color: Colors.white24,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Text(yLabelFormat(value), style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                        ),
                        interval: (max > 0) ? (max / 4).ceilToDouble() : 1,
                        reservedSize: 36,
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int idx = value.toInt();
                          if (idx < 0 || idx >= dates.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('E').format(dates[idx]),
                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                            ),
                          );
                        },
                        interval: 1,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i]),
                      ],
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.08)),
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${DateFormat('E').format(dates[spot.x.toInt()])}\n${yLabelFormat(spot.y)}',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 