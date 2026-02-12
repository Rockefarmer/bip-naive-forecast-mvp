import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/stock_data.dart';

class AnalysisColumn extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<AnalysisItem> items;

  const AnalysisColumn({
    super.key,
    required this.title,
    required this.titleColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: titleColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        // Compact List Items
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colored Dot
              Container(
                margin: const EdgeInsets.only(top: 6, right: 8),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: titleColor.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ),
              // Claim Text Only
              Expanded(
                child: Text(
                  item.claim,
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
