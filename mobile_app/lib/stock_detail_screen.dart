import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/stock_data.dart';
import 'services/api_service.dart';
import 'widgets/analysis_section.dart';
import 'widgets/forecast_chart.dart';
import 'widgets/stock_header.dart';

class StockDetailScreen extends StatefulWidget {
  final String symbol;
  const StockDetailScreen({super.key, this.symbol = 'AAPL'});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<StockData> _stockFuture;
  bool _isRevenue = true;

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

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                StockHeader(meta: data.meta, headerView: data.headerView),

                // 2. Toggle
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(child: _buildToggleOption('Revenue', true)),
                        Expanded(child: _buildToggleOption('Net Income', false)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Chart
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ForecastChart(
                    chartView: data.chartView,
                    alphaGap: AlphaGap.fromForecastSummary(data.forecastSummary),
                    isRevenue: _isRevenue,
                  ),
                ),
                
                const SizedBox(height: 32),
                Divider(color: Colors.grey[200], thickness: 1),
                const SizedBox(height: 16),

                // 4. Analysis
                AnalysisSection(analysisView: data.analysisView),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildToggleOption(String label, bool isValue) {
    final isSelected = _isRevenue == isValue;
    return GestureDetector(
      onTap: () => setState(() => _isRevenue = isValue),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF155DAD) : Colors.transparent, 
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}