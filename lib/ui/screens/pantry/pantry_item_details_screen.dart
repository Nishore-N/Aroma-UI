import 'package:flutter/material.dart';
import '../../../core/utils/category_engine.dart';
import '../../../core/utils/item_image_resolver.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../state/pantry_state.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../data/services/pantry_crud_service.dart';


const Color kAccent = Color(0xFFFF7A4A);

class PantryItemDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const PantryItemDetailsScreen({
    super.key,
    required this.item,
  });

  @override
  State<PantryItemDetailsScreen> createState() =>
      _PantryItemDetailsScreenState();
}

class _PantryItemDetailsScreenState extends State<PantryItemDetailsScreen> {
  double addQuantity = 1.0;

  @override
  void initState() {
    super.initState();
    addQuantity = 1.0; // Default count to add
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.item['name'];
    final unit = widget.item['unit'] ?? 'kg';
    final category = CategoryEngine.getCategory(name);
    final pantry = context.watch<PantryState>();
    final rawUrl = pantry.getItemImage(name) ?? widget.item['imageUrl'];
    final safeUrl = (rawUrl != null && rawUrl.toString().isNotEmpty) ? rawUrl.toString() : null;

    final imagePath = ItemImageResolver.getImageWidget(
                          name,
                          size: 120,
                          imageUrl: safeUrl,
                        );

final double currentQty = pantry.getQty(widget.item['name']);
final pantryItem = pantry.items.firstWhere(
  (e) => e.name.toLowerCase().trim() == (widget.item['name'] as String).toLowerCase().trim(),
  orElse: () => PantryItem(name: '', quantity: 0, unit: ''),
);

final now = DateTime.now();
final List<FlSpot> usageSpots = List.generate(7, (index) {
  final day = now.subtract(Duration(days: 6 - index));
  final count = pantryItem.usageHistory.where((dt) =>
      dt.year == day.year && dt.month == day.month && dt.day == day.day).length;

  return FlSpot(
    index.toDouble(),
    count.toDouble(),
  );
});


    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ❌ CLOSE BUTTON
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),

              const SizedBox(height: 8),

              // 🖼 IMAGE + TITLE
              Row(
                children: [
                  // Dynamic ingredient image with S3 URL support
                  ItemImageResolver.getImageWidget(
                    name,
                    size: 60,
                    imageUrl: safeUrl,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        category,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),

              // 📦 AVAILABLE QTY
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  children: [
                    const TextSpan(text: "Available Quantity: "),
                    TextSpan(
                      text: "${currentQty.toStringAsFixed(1)} $unit",
                      style: const TextStyle(
                        color: kAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "Quantity to adjust",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              // ➖➕ QUANTITY CONTROLLER
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kAccent),
                ),
                child: Row(
                  children: [
                    _qtyButton("-", () {
                      setState(() {
                        if (addQuantity > 0.5) addQuantity -= 0.5;
                      });
                    }),
                    Expanded(
                      child: Center(
                        child: Text(
                          addQuantity.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    _qtyButton("+", () {
                      setState(() {
                        addQuantity += 0.5;
                      });
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 🔘 BUTTONS: ADD & DEDUCT
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final authService = Provider.of<AuthService>(context, listen: false);
                        final String? userId = authService.user?.mobile_no;
                        
                        final double newTotalQty = currentQty + addQuantity;
                        
                        // 1. Update local state immediately (Optimistic)
                        // This triggers notifyListeners() which rebuilds the UI instantly
                        pantry.updateQuantity(name, newTotalQty, userId: userId);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Quantity added successfully!"),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          setState(() {
                            addQuantity = 1.0;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text("Add to Stock"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final authService = Provider.of<AuthService>(context, listen: false);
                        final String? userId = authService.user?.mobile_no;

                        if (currentQty < addQuantity) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Cannot deduct more than available amount!"),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          return;
                        }

                        // 🔻 DEDUCTION FLOW: OPTIMISTIC LOCAL + BACKGROUND REMOTE
                        final double newQty = currentQty - addQuantity;
                        
                        // Use consistent updateQuantity method which now handles 'Set' logic and removal
                        pantry.updateQuantity(name, newQty, userId: userId);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Quantity deducted successfully!"),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          setState(() {
                            addQuantity = 1.0;
                          });
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kAccent),
                        foregroundColor: kAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Deduct from Stock"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),

              // Nutritional information box removed as requested
              
              // 📈 USAGE TREND (STATIC UI)
              const Text(
                "Usage Trend",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Last 7 Days",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 12),

              // Placeholder chart (same visual)
              SizedBox(
  height: 180,
  child: LineChart(
    LineChartData(
      minY: 0,
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) {
              final dayDate = now.subtract(Duration(days: 6 - value.toInt()));
              const days = [
                'Sun',
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat'
              ];
              // return days[dayDate.weekday % 7]; // weekday is 1-7 (Mon-Sun)
              // We need Sun at index 0, but DateTime.weekday has Sun at 7 or 0 depending on version.
              // In Dart, Monday is 1, Sunday is 7.
              final List<String> shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              final label = shortDays[dayDate.weekday - 1]; // Correct index for shortDays
              
              return Text(
                label,
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          color: kAccent,
          barWidth: 3,
          dotData: FlDotData(show: true),
          spots: usageSpots, // 🔥 REAL DATA
        ),
      ],
    ),
  ),
),



              const SizedBox(height: 24),
              const Divider(),

              // 🧪 MACROS
              const Text(
                "Macros",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "per 100 gms",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 12),

              _macroRow("Calories", "23 kcal"),
              _macroRow("Carbohydrates", "4.0 g"),
              _macroRow("Protein", "2.5 g"),
              _macroRow("Fat", "0.3 g"),
              _macroRow("Fiber", "2.1 g"),
              _macroRow("Sugar", "0.4 g"),
            ],
          ),
        ),
      ),
    );
  }

  // BUTTON
  Widget _qtyButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            color: kAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Try to get macros from pantry item data
  Widget _buildMacrosDisplay() {
    // Check if pantry item has macros data
    if (widget.item['macros'] != null && widget.item['macros'] is Map) {
      final macros = widget.item['macros'] as Map<String, dynamic>;
      
      return Column(
        children: [
          _macroRow("Calories", "${macros['calories_kcal'] ?? 0} kcal"),
          _macroRow("Carbohydrates", "${macros['carbohydrates_g'] ?? 0} g"),
          _macroRow("Protein", "${macros['protein_g'] ?? 0} g"),
          _macroRow("Fat", "${macros['fat_g'] ?? 0} g"),
          _macroRow("Fiber", "${macros['fiber_g'] ?? 0} g"),
          _macroRow("Sugar", "${macros['sugar_g'] ?? 0} g"),
        ],
      );
    } else {
      // Fallback if no macros data available
      return const Column(
        children: [
          Text(
            "Macros not available",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }
  }

  // 🧪 MACRO ROW
  Widget _macroRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
