import 'package:flutter/material.dart';

/// Rounded Coupon Card Widget
/// Displays a coupon with teal discount section and cut-out effect
class RoundedCouponCard extends StatelessWidget {
  final String discount; // e.g., "23%" or "$15"
  final String? tagline; // e.g., "WINTER IS HERE"
  final String couponCode;
  final String validUntil;
  final VoidCallback? onTap;
  final bool isUsed;
  final bool isPercentage;

  const RoundedCouponCard({
    super.key,
    required this.discount,
    this.tagline,
    required this.couponCode,
    required this.validUntil,
    this.onTap,
    this.isUsed = false,
    this.isPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUsed ? null : onTap,
      child: Opacity(
        opacity: isUsed ? 0.6 : 1.0,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F7F5), // Light mint background
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipPath(
            clipper: CouponClipper(),
            child: Row(
              children: [
                // Left Part - Teal Discount Section
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: isUsed ? Colors.grey : const Color(0xFF2E7D7B), // Teal color
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Discount % - Big
                      Text(
                        discount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // OFF text
                      const Text(
                        'OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tagline
                      if (tagline != null && tagline!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            tagline!.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),

                // Semi-circle cutout spacer
                Container(
                  width: 20,
                  color: const Color(0xFFE0F7F5),
                ),

                // Right Part - Content
                Expanded(
                  child: Container(
                    color: const Color(0xFFE0F7F5),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Coupon Code Label
                        const Text(
                          'Coupon Code',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Coupon Code - Big Teal Text
                        Text(
                          couponCode,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isUsed ? Colors.grey : const Color(0xFF2E7D7B),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        // Valid Till with date
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 12,
                              color: Color(0xFF888888),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Valid Till - $validUntil',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF888888),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Coupon Clipper for cut-out effect
class CouponClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // The entire card bounding box
    Path rectPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      
    const double circleRadius = 12;
    const double leftSectionWidth = 110; 

    // The cutouts (semi-circles) to remove
    Path cutoutsPath = Path()
      ..addOval(Rect.fromCircle(center: const Offset(leftSectionWidth, 0), radius: circleRadius))
      ..addOval(Rect.fromCircle(center: Offset(leftSectionWidth, size.height), radius: circleRadius));

    return Path.combine(PathOperation.difference, rectPath, cutoutsPath);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
