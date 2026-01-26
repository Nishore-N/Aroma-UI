import 'package:flutter/material.dart';
import 'sheet_layout.dart';

class SingleSelectSheet {
  static Future<String?> open(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<String> options,
    required String selected,
  }) {
    String temp = selected;

    return showModalBottomSheet<String>(
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
          child: _card(
            children: options.map((item) {
              final isSelected = temp == item;
              return Column(
                children: [
                  _row(
                    item,
                    isSelected,
                    () => setState(() => temp = item),
                  ),
                  _divider(), // ✅ divider after each option
                ],
              );
            }).toList(),
          ),
          onSave: () => Navigator.pop(context, temp),
        ),
      ),
    );
  }

  // ───────────────────────── UI ─────────────────────────

  static Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }

  static Widget _row(
    String text,
    bool selected,
    VoidCallback onTap,
  ) {
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
          ? const Icon(
              Icons.check_circle,
              color: kAccent,
              size: 22,
            )
          : null,
      onTap: onTap,
    );
  }

  static Widget _divider() =>
      Divider(height: 1, thickness: 1, color: Colors.grey.shade300);
}
