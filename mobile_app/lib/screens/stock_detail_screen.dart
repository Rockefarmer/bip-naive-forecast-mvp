import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/stock_data.dart';
import '../services/api_service.dart';
import '../widgets/analysis_column.dart';
import '../widgets/financial_chart.dart';
import '../widgets/stock_header.dart'; // Ensure this matches filename

class StockDetailScreen extends StatefulWidget {
  final String symbol;
  const StockDetailScreen({super.key, this.symbol = 'AAPL'});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<StockData> _stockFuture;
  
  // State Logic
  bool _showRevenue = true;

  @override
  void initState() {
    super.initState();
    _stockFuture = _apiService.fetchStock(widget.symbol);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<StockData>(
        future: _stockFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data found'));
          }

          final data = snapshot.data!;
          final forecastSummary = data.forecastSummary;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                StockHeader(meta: data.meta, headerView: data.headerView),

                // 2. Toggle Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildToggleOption('Revenue', true),
                        ),
                        Expanded(
                          child: _buildToggleOption('Net Income', false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Dynamic Chart Title and Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CRITICAL: Dynamic Title
                      Text(
                        _showRevenue ? "Revenue Forecast" : "Net Income Forecast",
                        style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Financial Chart with fl_chart
                      FinancialChart(
                        history: _showRevenue 
                             ? data.chartView.revenueSeries.history 
                             : data.chartView.netIncomeSeries.history,
                        forecast: _showRevenue
                             ? data.chartView.revenueSeries.forecast
                             : data.chartView.netIncomeSeries.forecast,
                      ),
                      
                      const SizedBox(height: 24),

                      // Forecast Summary Cards (My Forecast, Delta, Wall St)
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              title: "My Forecast",
                              value: forecastSummary.myForecast,
                              highlight: false,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryCard(
                              title: "Delta",
                              value: forecastSummary.deltaValue,
                              subValue: forecastSummary.deltaPercent,
                              highlight: true,
                              isPositive: forecastSummary.deltaIsPositive,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryCard(
                              title: "Wall St.",
                              value: forecastSummary.wallStreet,
                              highlight: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Divider(color: Colors.grey[200], thickness: 1),
                const SizedBox(height: 16),

                // 4. Analysis Columns (Compact)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AnalysisColumn(
                          title: "TAILWINDS",
                          titleColor: const Color(0xFF1E8E3E),
                          items: data.analysisView.tailwinds,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: AnalysisColumn(
                          title: "HEADWINDS",
                          titleColor: const Color(0xFFD93025),
                          items: data.analysisView.headwinds,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildToggleOption(String label, bool isValue) {
    final isSelected = _showRevenue == isValue;
    return GestureDetector(
      onTap: () => setState(() => _showRevenue = isValue),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF155DAD) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    String? subValue,
    required bool highlight,
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
          Text(title, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]), maxLines: 1),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: highlight 
                  ? (isPositive ? const Color(0xFF1E8E3E) : const Color(0xFFD93025)) 
                  : Colors.black,
            ),
          ),
          if (subValue != null)
             Text(
              subValue,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: highlight 
                    ? (isPositive ? const Color(0xFF1E8E3E) : const Color(0xFFD93025)) 
                    : Colors.black,
              ),
            ),
        ],
      ),
    );
  }
}
