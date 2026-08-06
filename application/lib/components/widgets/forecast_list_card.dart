import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';

enum ForecastChartMode { temperature, rain, wind }

class ForecastListCard extends StatefulWidget {
  final List<Weather> forecast;

  const ForecastListCard({super.key, required this.forecast});

  @override
  State<ForecastListCard> createState() => _ForecastListCardState();
}

class _ForecastListCardState extends State<ForecastListCard> {
  ForecastChartMode selectedMode = ForecastChartMode.temperature;
  int selectedDayIndex = 0;

  @override
  Widget build(BuildContext context) {
    final days = _groupForecastByDay(widget.forecast);
    final dayIndex = days.isEmpty
        ? 0
        : selectedDayIndex.clamp(0, days.length - 1);
    final hourly = days.isEmpty ? <Weather>[] : days[dayIndex].hours;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 14, 10, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ModeTabs(
            selectedMode: selectedMode,
            onChanged: (mode) => setState(() => selectedMode = mode),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: hourly.length < 2
                ? const Center(child: Text('Chưa có dữ liệu dự báo'))
                : CustomPaint(
                    painter: _ForecastChartPainter(
                      data: hourly,
                      mode: selectedMode,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return _DailyForecastBox(
                  day: days[index],
                  isSelected: index == dayIndex,
                  onTap: () => setState(() => selectedDayIndex = index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  final ForecastChartMode selectedMode;
  final ValueChanged<ForecastChartMode> onChanged;

  const _ModeTabs({
    required this.selectedMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ForecastChartMode.values.map((mode) {
        final isSelected = mode == selectedMode;
        return InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => onChanged(mode),
          child: Padding(
            padding: const EdgeInsets.only(right: 14, top: 2, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _modeTitle(mode),
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF111827)
                        : const Color(0xFF6B7280),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 3,
                  width: isSelected ? 58 : 0,
                  decoration: BoxDecoration(
                    color: _modeColor(mode),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DailyForecastBox extends StatelessWidget {
  final _DailyForecast day;
  final bool isSelected;
  final VoidCallback onTap;

  const _DailyForecastBox({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 82,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECEFF1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              day.weekdayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: const Color(0xFF202124),
              ),
            ),
            Text(
              day.dateLabel,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
            Image.network(
              'https://openweathermap.org/img/wn/${day.icon}@2x.png',
              width: 42,
              height: 38,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(Icons.cloud, size: 30),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${day.maxTemp.round()}°',
                    style: const TextStyle(
                      color: Color(0xFF202124),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: '  ${day.minTemp.round()}°',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastChartPainter extends CustomPainter {
  final List<Weather> data;
  final ForecastChartMode mode;

  _ForecastChartPainter({
    required this.data,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final values = data.map((item) => _valueOf(item, mode)).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = (maxValue - minValue).abs() < 0.1 ? 1.0 : maxValue - minValue;
    const topPadding = 30.0;
    const bottomPadding = 30.0;
    const horizontalPadding = 14.0;
    final chartHeight = size.height - topPadding - bottomPadding;
    final baseline = size.height - bottomPadding;
    final stepX = (size.width - horizontalPadding * 2) / (data.length - 1);

    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = horizontalPadding + stepX * i;
      final normalized = (values[i] - minValue) / range;
      final y = topPadding + chartHeight * (1 - normalized);
      points.add(Offset(x, y));
    }

    final color = _modeColor(mode);

    final fillPath = Path()..moveTo(points.first.dx, baseline);
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final controlX = (prev.dx + current.dx) / 2;
      linePath.cubicTo(controlX, prev.dy, controlX, current.dy, current.dx, current.dy);
      fillPath.cubicTo(controlX, prev.dy, controlX, current.dy, current.dx, current.dy);
    }

    fillPath
      ..lineTo(points.last.dx, baseline)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.02)],
        ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    final dotFill = Paint()..color = Colors.white;
    final dotStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = color;

    final labelStyle = TextStyle(
      color: Colors.grey.shade800,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    final timeStyle = TextStyle(
      color: Colors.grey.shade600,
      fontSize: 11,
    );

    for (var i = 0; i < data.length; i++) {
      final point = points[i];

      canvas.drawCircle(point, 3.4, dotFill);
      canvas.drawCircle(point, 3.4, dotStroke);

      _paintCentered(
        canvas,
        _formatValue(values[i], mode),
        labelStyle,
        point.dx,
        point.dy - 22,
        size.width,
      );

      final date = data[i].date;
      if (date != null) {
        _paintCentered(
          canvas,
          DateFormat('HH:mm').format(date),
          timeStyle,
          point.dx,
          size.height - 20,
          size.width,
        );
      }
    }
  }

  void _paintCentered(
    Canvas canvas,
    String text,
    TextStyle style,
    double centerX,
    double top,
    double maxWidth,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        (centerX - painter.width / 2).clamp(0.0, maxWidth - painter.width),
        top,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ForecastChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.mode != mode;
  }
}

class _DailyForecast {
  final DateTime date;
  final String weekdayLabel;
  final String dateLabel;
  final String icon;
  final double minTemp;
  final double maxTemp;
  final List<Weather> hours;

  _DailyForecast({
    required this.date,
    required this.weekdayLabel,
    required this.dateLabel,
    required this.icon,
    required this.minTemp,
    required this.maxTemp,
    required this.hours,
  });
}

List<_DailyForecast> _groupForecastByDay(List<Weather> forecast) {
  final grouped = <DateTime, List<Weather>>{};
  for (final weather in forecast) {
    final date = weather.date;
    if (date == null || weather.temperature?.celsius == null) continue;
    final key = DateTime(date.year, date.month, date.day);
    grouped.putIfAbsent(key, () => []).add(weather);
  }

  final days = grouped.entries.map((entry) {
    final items = entry.value..sort((a, b) => a.date!.compareTo(b.date!));
    final temps = items.map((item) => item.temperature!.celsius!).toList();
    final representative = items.reduce((current, next) {
      final currentHour = (current.date!.hour - 12).abs();
      final nextHour = (next.date!.hour - 12).abs();
      return nextHour < currentHour ? next : current;
    });

    return _DailyForecast(
      date: entry.key,
      weekdayLabel: _weekdayLabel(entry.key),
      dateLabel: DateFormat('dd/MM').format(entry.key),
      icon: representative.weatherIcon ?? '02d',
      minTemp: temps.reduce(math.min),
      maxTemp: temps.reduce(math.max),
      hours: items,
    );
  }).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  return days.take(7).toList();
}

String _weekdayLabel(DateTime date) {
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  final dateOnly = DateTime(date.year, date.month, date.day);
  if (dateOnly == todayOnly) return 'Hôm nay';
  if (dateOnly == todayOnly.add(const Duration(days: 1))) return 'Ngày mai';
  return DateFormat('EEEE', 'vi').format(date);
}

String _modeTitle(ForecastChartMode mode) {
  switch (mode) {
    case ForecastChartMode.temperature:
      return 'Nhiệt độ';
    case ForecastChartMode.rain:
      return 'Lượng mưa';
    case ForecastChartMode.wind:
      return 'Gió';
  }
}

double _valueOf(Weather weather, ForecastChartMode mode) {
  switch (mode) {
    case ForecastChartMode.temperature:
      return weather.temperature?.celsius ?? 0;
    case ForecastChartMode.rain:
      return weather.rainLast3Hours ?? weather.rainLastHour ?? 0;
    case ForecastChartMode.wind:
      return weather.windSpeed ?? 0;
  }
}

String _formatValue(double value, ForecastChartMode mode) {
  switch (mode) {
    case ForecastChartMode.temperature:
      return '${value.round()}°';
    case ForecastChartMode.rain:
      return value == 0 ? '0' : value.toStringAsFixed(1);
    case ForecastChartMode.wind:
      return value.toStringAsFixed(1);
  }
}

Color _modeColor(ForecastChartMode mode) {
  switch (mode) {
    case ForecastChartMode.temperature:
      return const Color(0xFFFFA000);
    case ForecastChartMode.rain:
      return const Color(0xFF2196F3);
    case ForecastChartMode.wind:
      return const Color(0xFF26A69A);
  }
}
