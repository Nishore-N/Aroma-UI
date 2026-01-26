import 'package:flutter/material.dart';
import '../../../core/utils/category_engine.dart';
import '../../../core/utils/item_image_resolver.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../state/pantry_state.dart';


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
  late double quantity;

  @override
  void initState() {
    super.initState();
    quantity = double.tryParse(widget.item['quantity'].toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.item['name'];
    final unit = widget.item['unit'] ?? 'kg';
    final category = CategoryEngine.getCategory(name);
    final pantry = context.watch<PantryState>();
    final imagePath = ItemImageResolver.getImageWidget(
                          name,
                          size: 120,
                          imageUrl: pantry.getItemImage(name) ?? widget.item['imageUrl'],
                        );

final double currentQty =
    pantry.getQty(widget.item['name']);

final List<FlSpot> usageSpots = List.generate(7, (index) {
  // simple decreasing trend (product-safe)
  final value =
      currentQty - ((6 - index) * (currentQty / 6));

  return FlSpot(
    index.toDouble(),
    value < 0 ? 0 : value,
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
                    imageUrl: pantry.getItemImage(name) ?? widget.item['imageUrl'],
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
                      text: "$quantity $unit",
                      style: const TextStyle(
                        color: kAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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
                        if (quantity > 0) quantity--;
                      });
                    }),
                    Expanded(
                      child: Center(
                        child: Text(
                          quantity.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    _qtyButton("+", () {
                      setState(() {
                        quantity++;
                      });
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 🔘 UPDATE BUTTON
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: call update API
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Update"),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),

              // 📊 MACROS SECTION
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Nutritional Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Try to get macros from pantry item data
                    _buildMacrosDisplay(),
                  ],
                ),
              ),
              
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
              const days = [
                'Sun',
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat'
              ];
              return Text(
                days[value.toInt()],
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
