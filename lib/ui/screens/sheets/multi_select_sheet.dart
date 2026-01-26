import 'package:flutter/material.dart';
import 'sheet_layout.dart';

class MultiSelectSheet {
  static Future<List<String>?> open(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<String> options,
    required List<String> selected,
    bool showAllOption = true, // ✅ NEW
  }) {
    List<String> temp = [...selected];

    return showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (_, setState) => sheetLayout(
          title: title,
          subtitle: subtitle,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                /// ✅ ALL DAYS (ONLY IF ENABLED)
                if (showAllOption) ...[
                  _row(
                    text: 'All days',
                    selected: temp.length == options.length,
                    onTap: () {
                      setState(() {
                        if (temp.length == options.length) {
                          temp.clear();
                        } else {
                          temp = [...options];
                        }
                      });
                    },
                  ),
                  _divider(),
                ],

                /// ✅ OPTIONS LIST
                ...options.map((item) {
                  final isSelected = temp.contains(item);
                  return Column(
                    children: [
                      _row(
                        text: item,
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            isSelected
                                ? temp.remove(item)
                                : temp.add(item);
                          });
                        },
                      ),
                      _divider(),
                    ],
                  );
                }),
              ],
            ),
          ),
          onSave: () => Navigator.pop(context, temp),
        ),
      ),
    );
  }

  // ───────── UI HELPERS ─────────

  static Widget _row({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      title: Text(
        text,
        style: TextStyle(
          color: selected ? kAccent : Colors.black87,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle,
              color: kAccent, size: 22)
          : null,
      onTap: onTap,
    );
  }

  static Widget _divider() =>
      Divider(height: 1, color: Colors.grey.shade300);
}
