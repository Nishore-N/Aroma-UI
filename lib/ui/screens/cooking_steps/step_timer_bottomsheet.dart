//lib/ui/screens/cooking_steps/step_timer_bottomsheet.dart

import 'package:flutter/material.dart';
import 'step_time_selection_bottomsheet.dart';

Future<int?> showStepTimerBottomSheet(BuildContext context) async {
  return await showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const StepTimerBottomSheet(),
  );
}

class StepTimerBottomSheet extends StatefulWidget {
  const StepTimerBottomSheet({super.key});

  @override
  State<StepTimerBottomSheet> createState() => _StepTimerBottomSheetState();
}

class _StepTimerBottomSheetState extends State<StepTimerBottomSheet> {
  int selectedMinutes = 5;
  int? customMinutes;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// BACKDROP
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(color: Colors.black.withOpacity(0.35)),
        ),

        /// BOTTOM SHEET
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// CLOSE BUTTON
                Transform.translate(
                  offset: const Offset(0, -80),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.black,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                /// TITLE
                const Text(
                  "Add Timer",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),

                const SizedBox(height: 22),

                /// ROW 1
                Row(
                  children: [
                    _timeButton(5),
                    const SizedBox(width: 12),
                    _timeButton(15),
                    const SizedBox(width: 12),
                    _timeButton(30),
                  ],
                ),

                const SizedBox(height: 14),

                /// ROW 2
                Row(
                  children: [
                    _timeButton(45),
                    const SizedBox(width: 12),
                    _timeButton(55),
                    const SizedBox(width: 12),
                    _timeButton(60),
                  ],
                ),

                const SizedBox(height: 16),

                /// CUSTOM TIMING
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.55,
                    height: 44,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: customMinutes != null
                            ? const Color(0xFFFFF1EC)
                            : Colors.white,
                        side: BorderSide(
                          color: customMinutes != null
                              ? const Color(0xFFFF6A45)
                              : Colors.grey.shade300,
                          width: 1.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _showCustomTimingDialog,
                      child: Text(
                        customMinutes != null
                            ? "$customMinutes mins"
                            : "Custom Timing",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: customMinutes != null
                              ? const Color(0xFFFF6A45)
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                /// CONFIRM BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6A45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      // Return the selected minutes when confirmed
                      Navigator.of(context).pop(selectedMinutes);
                    },
                    child: const Text(
                      "Confirm Timer",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// PRESET TIME BUTTON
  Widget _timeButton(int min) {
    final bool selected = selectedMinutes == min && customMinutes == null;

    return Expanded(
      child: SizedBox(
        height: 44,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor:
                selected ? const Color(0xFFFFF1EC) : Colors.white,
            side: BorderSide(
              color:
                  selected ? const Color(0xFFFF6A45) : Colors.grey.shade300,
              width: 1.4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            setState(() {
              selectedMinutes = min;
              customMinutes = null;
            });
          },
          child: Text(
            "$min mins",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color:
                  selected ? const Color(0xFFFF6A45) : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  /// CUSTOM TIMING DIALOG
  void _showCustomTimingDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Custom Timing"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: "Enter minutes",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A45),
            ),
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                setState(() {
                  customMinutes = value;
                  selectedMinutes = value;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text(
              "Set",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}