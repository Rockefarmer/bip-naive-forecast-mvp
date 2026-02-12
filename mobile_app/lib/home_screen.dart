import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'stock_detail_screen.dart';
import 'services/api_service.dart';
import 'models/stock_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  final ApiService _apiService = ApiService();
  
  late Future<List<WatchlistItem>> _watchlistFuture;

  @override
  void initState() {
    super.initState();
    _watchlistFuture = _apiService.fetchWatchlist();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- Helper to Clean Name ---
  String _cleanName(String name) {
    return name
        .replaceAll('Corporation', '')
        .replaceAll('Corp.', '')
        .replaceAll('Incorporated', '')
        .replaceAll('Inc.', '')
        .replaceAll('Inc', '') 
        .replaceAll('Limited', '')
        .replaceAll('Ltd.', '')
        .trim(); 
  }

  Widget _buildWatchlistCard(WatchlistItem item) {
    return WatchlistCard(
      ticker: item.symbol,
      companyName: _cleanName(item.name),
      price: item.priceFormatted,
      changeAmount: item.changeFormatted,
      percentChange: '',
      isPositive: item.isPositive,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StockDetailScreen(symbol: item.symbol),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Rockefarmer Labs',
                style: GoogleFonts.lato(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Search for tickers',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Feature Row
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   FeatureItem(
                    icon: Icons.bar_chart_rounded,
                    label: '4-Quarter\nForecasts',
                  ),
                   FeatureItem(
                    icon: Icons.track_changes_outlined,
                    label: 'Confidence\nRanges',
                  ),
                   FeatureItem(
                    icon: Icons.menu_book_rounded,
                    label: 'Research &\nEducation Only',
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Watchlist Label
              Text(
                'Watchlist',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              // Live Watchlist
              FutureBuilder<List<WatchlistItem>>(
                future: _watchlistFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.cloud_off, color: Colors.grey[400], size: 36),
                            const SizedBox(height: 8),
                            Text(
                              'Could not load watchlist',
                              style: GoogleFonts.lato(color: Colors.grey[500], fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _watchlistFuture = _apiService.fetchWatchlist();
                                });
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No stocks in watchlist',
                          style: GoogleFonts.lato(color: Colors.grey[500]),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildWatchlistCard(item),
                    )).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false, 
        showUnselectedLabels: false,
        onTap: _onItemTapped,
      ),
    );
  }
}

// --- WIDGETS ---

class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const FeatureItem({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 30, color: Colors.blueGrey[800]),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            height: 1.2
          ),
        ),
      ],
    );
  }
}

class WatchlistCard extends StatelessWidget {
  final String ticker;
  final String companyName;
  final String price;
  final String changeAmount; 
  final String percentChange;
  final bool isPositive;
  final VoidCallback? onTap;

  const WatchlistCard({
    super.key,
    required this.ticker,
    required this.companyName,
    required this.price,
    required this.changeAmount, 
    required this.percentChange,
    required this.isPositive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            // --- NEW: US Flag Icon ---
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.red[50], // Softer background
                shape: BoxShape.circle,
              ),
              child: Center(
                  child: Text(
                'US', // 2. Use Text instead of Emoji
                style: GoogleFonts.lato(
                 fontSize : 18,
                 fontWeight: FontWeight.bold,
                 color: Colors.red,
                ),
              )),
            ),
            const SizedBox(width: 16),
            
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticker,
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    companyName,
                    style: GoogleFonts.lato(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Price Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                 color: isPositive ? Colors.green[50] : Colors.red[50],
                 borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$$price',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black, 
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        changeAmount,
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isPositive ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        percentChange,
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isPositive ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}