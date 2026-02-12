class StockData {
  final StockMeta meta;
  final HeaderView headerView;
  final ChartView chartView;
  final ForecastSummary forecastSummary;
  final AnalysisView analysisView;

  StockData({
    required this.meta,
    required this.headerView,
    required this.chartView,
    required this.forecastSummary,
    required this.analysisView,
  });

  factory StockData.fromJson(Map<String, dynamic> json) {
    return StockData(
      meta: StockMeta.fromJson(json['meta']),
      headerView: HeaderView.fromJson(json['header_view']),
      chartView: ChartView.fromJson(json['chart_view']),
      forecastSummary: ForecastSummary.fromJson(json['forecast_summary']),
      analysisView: AnalysisView.fromJson(json['analysis_view']),
    );
  }
}

class StockMeta {
  final String ticker;
  final String name;

  StockMeta({required this.ticker, required this.name});

  factory StockMeta.fromJson(Map<String, dynamic> json) {
    return StockMeta(
      ticker: json['ticker'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class HeaderView {
  final String priceFormatted;
  final String changeFormatted;
  final bool isPositive;

  HeaderView({
    required this.priceFormatted,
    required this.changeFormatted,
    required this.isPositive,
  });

  factory HeaderView.fromJson(Map<String, dynamic> json) {
    return HeaderView(
      priceFormatted: json['price_formatted'] ?? '',
      changeFormatted: json['change_formatted'] ?? '',
      isPositive: json['is_positive'] ?? true,
    );
  }
}

class ChartView {
  final SeriesData revenueSeries;
  final SeriesData netIncomeSeries;

  ChartView({required this.revenueSeries, required this.netIncomeSeries});

  factory ChartView.fromJson(Map<String, dynamic> json) {
    return ChartView(
      revenueSeries: SeriesData.fromJson(json['revenue_series']),
      netIncomeSeries: SeriesData.fromJson(json['net_income_series']),
    );
  }
}

class SeriesData {
  final List<GraphPoint> history;
  final List<GraphPoint> forecast;

  SeriesData({required this.history, required this.forecast});

  factory SeriesData.fromJson(Map<String, dynamic> json) {
    return SeriesData(
      history: (json['history'] as List?)
              ?.map((e) => GraphPoint.fromJson(e))
              .toList() ??
          [],
      forecast: (json['forecast'] as List?)
              ?.map((e) => GraphPoint.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class GraphPoint {
  final String period;
  final double value;

  GraphPoint({required this.period, required this.value});

  /// Display-ready string, e.g. "$95.0B"
  String get formatted => '\$${value.toStringAsFixed(1)}B';

  factory GraphPoint.fromJson(Map<String, dynamic> json) {
    return GraphPoint(
      period: json['period'] ?? '',
      value: (json['value'] ?? 0.0).toDouble(),
    );
  }
}

class ForecastSummary {
  final String myForecast;
  final String deltaValue;
  final String deltaPercent;
  final bool deltaIsPositive;
  final String wallStreet;

  ForecastSummary({
    required this.myForecast,
    required this.deltaValue,
    required this.deltaPercent,
    required this.deltaIsPositive,
    required this.wallStreet,
  });

  factory ForecastSummary.fromJson(Map<String, dynamic> json) {
    return ForecastSummary(
      myForecast: json['my_forecast'] ?? '',
      deltaValue: json['delta_value'] ?? '',
      deltaPercent: json['delta_percent'] ?? '',
      deltaIsPositive: json['delta_is_positive'] ?? true,
      wallStreet: json['wall_street'] ?? '',
    );
  }
}

class AnalysisView {
  final List<AnalysisItem> tailwinds;
  final List<AnalysisItem> headwinds;

  AnalysisView({required this.tailwinds, required this.headwinds});

  factory AnalysisView.fromJson(Map<String, dynamic> json) {
    return AnalysisView(
      tailwinds: (json['tailwinds'] as List?)
              ?.map((e) => AnalysisItem.fromJson(e))
              .toList() ??
          [],
      headwinds: (json['headwinds'] as List?)
              ?.map((e) => AnalysisItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AnalysisItem {
  final String claim;
  final String sentiment;

  AnalysisItem({required this.claim, required this.sentiment});

  factory AnalysisItem.fromJson(Map<String, dynamic> json) {
    return AnalysisItem(
      claim: json['claim'] ?? '',
      sentiment: json['sentiment'] ?? 'neutral',
    );
  }
}

class AlphaGap {
  final double gapValue;
  final double gapPercent;
  final bool isPositive;

  AlphaGap({
    required this.gapValue,
    required this.gapPercent,
    required this.isPositive,
  });

  factory AlphaGap.fromJson(Map<String, dynamic> json) {
    return AlphaGap(
      gapValue: (json['gap_value'] ?? 0.0).toDouble(),
      gapPercent: (json['gap_percent'] ?? 0.0).toDouble(),
      isPositive: json['is_positive'] ?? true,
    );
  }

  /// Build an AlphaGap from the existing ForecastSummary fields.
  factory AlphaGap.fromForecastSummary(ForecastSummary fs) {
    // Parse numeric value out of strings like "+$7.26B" and "+7%"
    final numericValue = double.tryParse(
      fs.deltaValue.replaceAll(RegExp(r'[^\d.\-]'), ''),
    ) ?? 0.0;
    final numericPercent = double.tryParse(
      fs.deltaPercent.replaceAll(RegExp(r'[^\d.\-]'), ''),
    ) ?? 0.0;
    return AlphaGap(
      gapValue: numericValue,
      gapPercent: numericPercent,
      isPositive: fs.deltaIsPositive,
    );
  }
}

class WatchlistItem {
  final String symbol;
  final String name;
  final double currentPrice;
  final double change;
  final double changePercent;

  WatchlistItem({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.change,
    required this.changePercent,
  });

  bool get isPositive => changePercent >= 0;

  String get priceFormatted => currentPrice.toStringAsFixed(2);

  /// e.g. "+12.30 +5.45%" or "-13.50 -4.95%"
  String get changeFormatted {
    final sign = change >= 0 ? '+' : '';
    final pctSign = changePercent >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(2)} $pctSign${changePercent.toStringAsFixed(2)}%';
  }

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      currentPrice: (json['current_price'] ?? 0.0).toDouble(),
      change: (json['change'] ?? 0.0).toDouble(),
      changePercent: (json['change_percent'] ?? 0.0).toDouble(),
    );
  }
}
