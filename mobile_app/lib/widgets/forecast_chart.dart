import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/stock_data.dart';

class ForecastChart extends StatelessWidget {
  final ChartView chartView;
  final AlphaGap alphaGap;
  final bool isRevenue;

  const ForecastChart({
    super.key,
    required this.chartView,
    required this.alphaGap,
    required this.isRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final series = isRevenue ? chartView.revenueSeries : chartView.netIncomeSeries;
    
    // Combine for Y-axis calculation
    final allPoints = [...series.history, ...series.forecast];
    double maxY = 0;
    for (var p in allPoints) {
      if (p.value > maxY) maxY = p.value;
    }
    maxY = maxY * 1.2; // Buffer

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart container
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                verticalInterval: 1, 
                horizontalInterval: maxY > 60 ? 20 : 10,
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
                         // Simplify label: "2024-Q3" -> "Q3 '24" or just "Q3" depending on space
                         // For now, assume period string is short enough or grab year
                         final p = allPoints[index].period;
                         return Padding(
                           padding: const EdgeInsets.only(top: 8.0),
                           child: Text(
                             p.replaceAll('20', '').replaceAll('-', ' '), // "23 Q4"
                             style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600]),
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
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600]),
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
                   getTooltipItems: (touchedSpots) {
                     return touchedSpots.map((spot) {
                       final point = allPoints[spot.x.toInt()];
                       return LineTooltipItem(
                         point.formatted,
                         const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                       );
                     }).toList();
                   },
                   tooltipBgColor: Colors.black,
                 ),
              ),
              lineBarsData: [
                // History (Solid)
                LineChartBarData(
                  spots: series.history.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.value);
                  }).toList(),
                  isCurved: true,
                  color: const Color(0xFF5F6368),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                ),
                // Forecast (Dashed)
                // Connect last history point to first forecast point visually?
                // FlChart separates lines. We can create a second line starting from last history point.
                LineChartBarData(
                  spots: [
                    // Start from the last history point to make it continuous
                    if (series.history.isNotEmpty)
                      FlSpot((series.history.length - 1).toDouble(), series.history.last.value),
                    ...series.forecast.asMap().entries.map((e) {
                      return FlSpot((series.history.length + e.key).toDouble(), e.value.value);
                    }),
                  ],
                  isCurved: true,
                  color: const Color(0xFF5F6368),
                  barWidth: 3,
                  dashArray: [5, 5],
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Forecast Cards Section
        Text(
          isRevenue ? "Revenue Forecast" : "Net Income Forecast",
          style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Using placeholder logic for values based on chartView.alphaGap and dummy interpretation 
            // since JSON structure for these cards isn't fully explicit in the 'chart_view' root 
            // apart from alpha_gap. 
            // I'll assume the LAST forecast point is the "Forecast" value for now or use alpha_gap logic.
            
            // Forecast
            Expanded(
              child: _buildCard(
                title: "Forecast",
                // Grab last forecast point formatted value
                value: series.forecast.isNotEmpty ? series.forecast.last.formatted : "-",
                subValue: "",
              ),
            ),
            const SizedBox(width: 8),
            // Delta
            Expanded(
              child: _buildCard(
                title: "Delta",
                value: "${alphaGap.isPositive ? '+' : ''}\$${alphaGap.gapValue}B",
                subValue: "${alphaGap.isPositive ? '+' : ''}${alphaGap.gapPercent}%",
                isDelta: true,
                isPositive: alphaGap.isPositive,
              ),
            ),
            const SizedBox(width: 8),
            // Wall St. (Implied from Forecast - Delta? or just placeholder as it is missing in JSON direct fields)
            // JSON alpha_gap says "Model expects +7.0% vs Wall St.". 
            // I'll calculate Wall St as Forecast - GapValue for display if needed, or just leave as "Consensus"
            Expanded(
              child: _buildCard(
                title: "Wall St. consensus",
                value: _calculateConsensus(series, alphaGap),
                subValue: "",
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _calculateConsensus(SeriesData series, AlphaGap gap) {
     if (series.forecast.isEmpty) return "-";
     final interactions = series.forecast.last.value;
     final consensus = interactions - gap.gapValue;
     return "\$${consensus.toStringAsFixed(1)}B";
  }

  Widget _buildCard({
    required String title,
    required String value,
    required String subValue,
    bool isDelta = false,
    bool isPositive = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]), maxLines: 1),
          const SizedBox(height: 4),
          Text(
            value, 
            style: GoogleFonts.inter(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              color: isDelta ? (isPositive ? Colors.green[700] : Colors.red[700]) : Colors.black,
            )
          ),
          if (subValue.isNotEmpty)
            Text(
              subValue,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDelta ? (isPositive ? Colors.green[700] : Colors.red[700]) : Colors.black,
              ),
            ),
        ],
      ),
    );
  }
}
