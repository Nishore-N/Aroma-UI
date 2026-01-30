import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReviewSection extends StatefulWidget {
  final List<Map<String, dynamic>> reviews;
  final String recipeName;

  const ReviewSection({
    super.key,
    required this.reviews,
    required this.recipeName,
  });

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  late List<Map<String, dynamic>> _reviews;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _reviews = widget.reviews;
    // AI review generation disabled - using only backend data
  }

  double get averageRating {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold<double>(
      0,
      (sum, r) => sum + (r["rating"] ?? 5).toDouble(),
    );
    return (total / _reviews.length).clamp(0.0, 5.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ---- HEADER ----
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Reviews",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),

            if (_reviews.isNotEmpty)
              Row(
                children: [
                  const Text(
                    "Rating",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),

        const SizedBox(height: 10),

        /// ---- META ----
        Row(
          children: [
            Text(
              "${_reviews.length} Comments",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                width: 4, 
                height: 4, 
                decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle),
              ),
            ),
            Text(
              "Reviewed by ${_reviews.length + 100}", // Mocking 'Reviewed by' count to match typical social proof design
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        /// ---- EMPTY STATE ----
        if (_reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.rate_review, size: 24, color: Colors.black),
                SizedBox(width: 12),
                Text(
                  "No reviews available for this recipe",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          )
        else
          /// ---- SHOW REVIEWS ----
          Column(
            children: (isExpanded ? _reviews : _reviews.take(2)).map((review) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Avatar with AI badge
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: (review['isAI'] ?? false)
                              ? Colors.blue.shade100
                              : Colors.orange.shade100,
                          child: Text(
                            (review["name"] ?? "U")
                                .toString()
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: (review['isAI'] ?? false)
                                  ? Colors.blue.shade800
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ),
                        if (review['isAI'] ?? false)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 14),

                    /// Name + Comment
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review["name"] ?? "Anonymous",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              ...List.generate(
                                5,
                                (index) => Icon(
                                  index < (review['rating'] ?? 5)
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                review['timeAgo'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            review["comment"] ?? "",
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 12),

        /// ---- ACTION BUTTONS ----
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _actionButton("assets/images/reviews/write_review.svg", "Write review", () {}),
            if (_reviews.length > 2)
              _actionButton(
                isExpanded 
                    ? "assets/images/reviews/read_more.svg" 
                    : "assets/images/reviews/read_more.svg", 
                isExpanded ? "Read Less" : "Read More",
                () => setState(() => isExpanded = !isExpanded),
              ),
          ],
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  Widget _actionButton(String svgAsset, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          SvgPicture.asset(svgAsset, width: 22, height: 22, colorFilter: const ColorFilter.mode(Color(0xFFFF6A45), BlendMode.srcIn)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFFFF6A45),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
