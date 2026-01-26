import 'package:flutter/material.dart';

class ScalesScreen extends StatefulWidget {
  const ScalesScreen({super.key});

  @override
  State<ScalesScreen> createState() => _ScalesScreenState();
}

class _ScalesScreenState extends State<ScalesScreen> {
  String weight = 'metric';
  String volume = 'metric';
  String temperature = 'c';
  String pressure = 'metric';
  String energy = 'metric';

  final Color accent = const Color(0xFFFF7A4A); // same orange tone

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ APP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ✅ TITLE
            const SizedBox(height: 8),
            const Text(
              'Scales',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'your measurement preferences',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade300),

            // ✅ SECTIONS
            const SizedBox(height: 16),
            _measureSection(
              icon: Icons.scale,
              title: 'Weight',
              selected: weight,
              options: const {
                'metric': 'Kilograms (kg), Grams (g)',
                'imperial': 'Pounds (lbs), Ounces (oz)',
              },
              onChanged: (v) => setState(() => weight = v),
            ),

            _measureSection(
              icon: Icons.local_drink_outlined,
              title: 'Volume',
              selected: volume,
              options: const {
                'metric': 'Litres (L), Millilitres (ml)',
                'imperial': 'Gallons (gal), Quarts (qt), Pints (pt)',
              },
              onChanged: (v) => setState(() => volume = v),
            ),

            _measureSection(
              icon: Icons.thermostat_outlined,
              title: 'Temperature',
              selected: temperature,
              options: const {
                'c': 'Celsius (°C)',
                'f': 'Fahrenheit (°F)',
              },
              onChanged: (v) => setState(() => temperature = v),
            ),

            _measureSection(
              icon: Icons.av_timer_outlined,
              title: 'Pressure',
              selected: pressure,
              options: const {
                'metric': 'Kilopascals (kPa), Pascals (Pa)',
                'imperial': 'Pounds per Square Inch (psi)',
              },
              onChanged: (v) => setState(() => pressure = v),
            ),

            _measureSection(
              icon: Icons.flash_on_outlined,
              title: 'Energy',
              selected: energy,
              options: const {
                'metric': 'Kilojoules (kJ), Joules (J)',
                'imperial': 'Kilocalories (kcal), Calories (cal)',
              },
              onChanged: (v) => setState(() => energy = v),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ✅ SECTION WIDGET (MATCHES IMAGE)
  Widget _measureSection({
    required IconData icon,
    required String title,
    required String selected,
    required Map<String, String> options,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // ✅ ICON + TITLE
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ✅ BOX
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: options.entries.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final e = entry.value;
              final isSelected = selected == e.key;

              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 2),
                    tileColor:
                        isSelected ? accent.withOpacity(0.08) : Colors.white,
                    title: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? accent : Colors.black,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: accent)
                        : null,
                    onTap: () => onChanged(e.key),
                  ),

                  // ✅ Divider between rows
                  if (index != options.length - 1)
                    Divider(height: 1, color: Colors.grey.shade300),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
