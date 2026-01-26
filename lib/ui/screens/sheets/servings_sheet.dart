import 'package:flutter/material.dart';
import 'sheet_layout.dart';

class ServingsSheet {
  static Future<int?> open(BuildContext context, int initial) {
    int value = initial;

    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (_, setState) => sheetLayout(
          title: 'Serving needed',
          subtitle: '',
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kAccent),
              color: Colors.transparent,
            ),
            child: Row(
              children: [
                // ➖ MINUS BUTTON
                _sideButton(
                  isLeft: true,
                  icon: Icons.remove,
                  onTap: () {
                    if (value > 1) setState(() => value--);
                  },
                ),

                // ✅ VALUE
                Expanded(
                  child: Center(
                    child: Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                // ➕ PLUS BUTTON
                _sideButton(
                  isLeft: false,
                  icon: Icons.add,
                  onTap: () => setState(() => value++),
                ),
              ],
            ),
          ),
          onSave: () => Navigator.pop(context, value),
        ),
      ),
    );
  }

  // ================= BUTTON UI =================

  static Widget _sideButton({
    required bool isLeft,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 56,
      height: double.infinity,
      child: InkWell(
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(14) : Radius.zero,
          right: !isLeft ? const Radius.circular(14) : Radius.zero,
        ),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: kAccent.withOpacity(0.10),
            borderRadius: BorderRadius.horizontal(
              left: isLeft ? const Radius.circular(14) : Radius.zero,
              right: !isLeft ? const Radius.circular(14) : Radius.zero,
            ),
          ),
          child: Icon(
            icon,
            color: kAccent,
            size: 22,
          ),
        ),
      ),
    );
  }
}
