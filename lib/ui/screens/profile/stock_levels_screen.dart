import 'package:flutter/material.dart';

enum UnitType { weight, volume }

class StockLevelsScreen extends StatefulWidget {
  const StockLevelsScreen({super.key});

  @override
  State<StockLevelsScreen> createState() => _StockLevelsScreenState();
}

class _StockLevelsScreenState extends State<StockLevelsScreen> {
  final Map<String, StockValue> stock = {
    'Fruits & Vegetables':
        StockValue(2, 'kg', UnitType.weight),
    'Dairy & Alternatives':
        StockValue(5, 'ml', UnitType.volume),
    'Eggs, Meat & Fish':
        StockValue(1, 'kg', UnitType.weight),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Stock levels',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Column(
        children: stock.entries.map((e) {
          return Column(
            children: [
              ListTile(
                title: Text(
                  e.key,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Set minimum threshold',
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: Text(
                  '${e.value.value} ${e.value.unit}',
                  style: const TextStyle(
                    color: Color(0xFFFF7A4A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => _openBottomSheet(context, e.key),
              ),
              const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _openBottomSheet(BuildContext context, String key) async {
    final result = await showModalBottomSheet<StockValue>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StockBottomSheet(
        title: key,
        initial: stock[key]!,
      ),
    );

    if (result != null) {
      setState(() => stock[key] = result);
    }
  }
}

/// ─────────────────────────────────────────
/// Bottom Sheet
/// ─────────────────────────────────────────

class StockBottomSheet extends StatefulWidget {
  final String title;
  final StockValue initial;

  const StockBottomSheet({
    super.key,
    required this.title,
    required this.initial,
  });

  @override
  State<StockBottomSheet> createState() => _StockBottomSheetState();
}

class _StockBottomSheetState extends State<StockBottomSheet> {
  late TextEditingController controller;
  late String selectedUnit;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.initial.value.toString(),
    );
    selectedUnit = widget.initial.unit;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Specify minimum threshold quantity',
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 18),
          const Text('Low stock level'),
          const SizedBox(height: 8),

          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              suffixText: selectedUnit,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 18),
          const Text('Weighing method'),
          const SizedBox(height: 10),
          _unitSelector(),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A4A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  StockValue(
                    int.tryParse(controller.text) ?? 0,
                    selectedUnit,
                    widget.initial.unitType,
                  ),
                );
              },
              child: const Text(
                'Save Threshold',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ EXACT UI AS IMAGE
  Widget _unitSelector() {
    final units = widget.initial.unitType == UnitType.weight
        ? ['kg', 'gm']
        : ['ltr', 'ml'];

    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: units.map((unit) {
          final isSelected = unit == selectedUnit;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedUnit = unit),
              child: Container(
                margin: const EdgeInsets.all(4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFFFFEFE6) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: const Color(0xFFFF7A4A))
                      : null,
                ),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFFFF7A4A)
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// ─────────────────────────────────────────
/// Model
/// ─────────────────────────────────────────

class StockValue {
  int value;
  String unit;
  UnitType unitType;

  StockValue(this.value, this.unit, this.unitType);
}
