import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/stock_data.dart';

class StockHeader extends StatelessWidget {
  final StockMeta meta;
  final HeaderView headerView;

  const StockHeader({
    super.key,
    required this.meta,
    required this.headerView,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ticker & Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        meta.ticker,
                        style: GoogleFonts.lato(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Flag placeholder if needed, omitted per strict JSON but looked good before.
                      // Leaving out to be strict about data source, or just adding icon.
                      // Prompt didn't forbid icon.
                      const Icon(Icons.flag, size: 24, color: Colors.blueAccent),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta.name,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Price & Change
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    headerView.priceFormatted,
                    style: GoogleFonts.lato(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    headerView.changeFormatted,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: headerView.isPositive ? const Color(0xFF1E8E3E) : const Color(0xFFD93025),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // No stats grid because new JSON lacks open, prevClose, etc.
          // Adhering strictly to prompt inputs.
        ],
      ),
    );
  }
}