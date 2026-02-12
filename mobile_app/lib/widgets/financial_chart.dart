import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/stock_data.dart';

class FinancialChart extends StatelessWidget {
  final List<GraphPoint> history;
  final List<GraphPoint> forecast;

  const FinancialChart({
    super.key,
    required this.history,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    // Combine to determine axis bounds
    final allPoints = [...history, ...forecast];
    if (allPoints.isEmpty) return const SizedBox(height: 250);

    double maxY = 0;
    for (var p in allPoints) {
      if (p.value > maxY) maxY = p.value;
    }
    maxY = maxY * 1.2;

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200], strokeWidth: 1),
            getDrawingVerticalLine: (value) => FlLine(color: Colors.grey[200], strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < allPoints.length) {
                    // Use period directly from JSON (e.g., "24 Q1")
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        allPoints[index].period,
                        style: GoogleFonts.lato(fontSize: 10, color: Colors.grey[600]),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxY > 60 ? 20 : 10,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${value.toInt()}B',
                    style: GoogleFonts.lato(fontSize: 10, color: Colors.grey[600]),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (allPoints.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              // tooltipBgColor: Colors.black, // Deprecated in some versions, check compatibility
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final point = allPoints[spot.x.toInt()];
                  return LineTooltipItem(
                    "\$${point.value}B",
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            // History Line (Solid)
            LineChartBarData(
              spots: history.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.value);
              }).toList(),
              isCurved: true,
              color: Colors.blueGrey[700],
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
            // Forecast Line (Dashed)
            LineChartBarData(
              spots: [
                // Connect from last history point
                if (history.isNotEmpty)
                  FlSpot((history.length - 1).toDouble(), history.last.value),
                ...forecast.asMap().entries.map((e) {
                  return FlSpot((history.length + e.key).toDouble(), e.value.value);
                }),
              ],
              isCurved: true,
              color: Colors.blueGrey[700],
              barWidth: 3,
              dashArray: [5, 5],
              dotData: const FlDotData(show: true), // Maybe show dots for forecast points? Prompt didn't specify, but nice.
            ),
          ],
        ),
      ),
    );
  }
}
