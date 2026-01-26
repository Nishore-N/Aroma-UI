import 'package:flutter/material.dart';

const Color kAccent = Color(0xFFFF7A4A);

Widget sheetLayout({
  required String title,
  required String subtitle,
  required Widget child,
  required VoidCallback onSave,
}) {
  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ TITLE
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          // ✅ SUBTITLE
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],

          // ✅ LINE BELOW HEADER (as per image)
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade300),

          // ✅ CONTENT
          const SizedBox(height: 12),
          child,

          // ✅ SPACE + LINE BEFORE SAVE
          const SizedBox(height: 24),
          Divider(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 16),

          // ✅ SAVE BUTTON
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onSave,
              child: const Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
