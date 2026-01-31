import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReviewSection extends StatefulWidget {
  final List<Map<String, dynamic>> reviews;
  final String recipeName;

  const ReviewSection({
    super.key,
    required this.reviews,

    required this.recipeName,
    required this.onAddReview,
  });

  final Function(String) onAddReview;

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  bool isExpanded = false;

  String _getImageForName(String name) {
    if (name == "Mike Chen") return "https://i.pravatar.cc/150?img=11";
    if (name == "Sarah Johnson") return "https://i.pravatar.cc/150?img=5";
    if (name == "Emily Davis") return "https://i.pravatar.cc/150?img=9";
    return "https://i.pravatar.cc/150?img=12"; // Default
  }

  double get averageRating {
    if (widget.reviews.isEmpty) return 0.0;
    final total = widget.reviews.fold<double>(
      0,
      (sum, r) => sum + (r["rating"] ?? 5).toDouble(),
    );
    return (total / widget.reviews.length).clamp(0.0, 5.0);
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

            if (widget.reviews.isNotEmpty) ...[
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
          ],
        ),

        const SizedBox(height: 10),

        /// ---- META ----
        Row(
          children: [
            Text(
              widget.reviews.isEmpty
                  ? "No reviews yet"
                  : "${widget.reviews.length} Comments",
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
              "Reviewed by ${widget.reviews.length + 100}", // Mocking 'Reviewed by' count to match typical social proof design
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
        if (widget.reviews.isEmpty)
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
            children: (isExpanded ? widget.reviews : widget.reviews.take(2)).map((review) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Avatar with AI badge
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(review["imageUrl"] ?? _getImageForName(review["name"])), // Dynamic image with fallback
                        backgroundColor: Colors.grey.shade200,
                      ),

                    const SizedBox(width: 14),

                    /// Name + Comment
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review["name"] ?? "Anonymous",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const SizedBox(height: 6),
                          Text(
                            review["comment"] ?? "",
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: Colors.grey.shade600,
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
            _actionButton("assets/images/reviews/write_review.svg", "Write review", () => _showWriteReviewBottomSheet(context)),
            if (widget.reviews.length > 2)
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

  void _showWriteReviewBottomSheet(BuildContext context) {
    final TextEditingController _controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Write a Review",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Share your thoughts on this recipe...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF6A45), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      widget.onAddReview(_controller.text.trim());
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A45),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Post Review",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}

