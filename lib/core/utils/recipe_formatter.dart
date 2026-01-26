import 'package:flutter/foundation.dart';

class RecipeFormatter {
  /// Formats ingredient quantity based on base quantity, requested servings, and unit.
  static String formatQuantity(dynamic baseQty, int servings, String? unit) {
    if (baseQty == null || baseQty.toString().isEmpty || baseQty.toString().toLowerCase() == 'as needed') {
      return "as needed";
    }
    
    // Handle fractions like "1/2" or "1 1/2"
    double qtyValue = 1.0;
    String qtyStr = baseQty.toString().trim();
    
    try {
      if (qtyStr.contains('/')) {
        // Handle "1 1/2" format
        if (qtyStr.contains(' ')) {
          final parts = qtyStr.split(' ');
          double wholePart = double.tryParse(parts[0]) ?? 0.0;
          final fractionParts = parts[1].split('/');
          if (fractionParts.length == 2) {
            double num = double.tryParse(fractionParts[0]) ?? 0.0;
            double den = double.tryParse(fractionParts[1]) ?? 1.0;
            qtyValue = wholePart + (num / den);
          }
        } else {
          // Handle "1/2" format
          final parts = qtyStr.split('/');
          if (parts.length == 2) {
            double? num = double.tryParse(parts[0]);
            double? den = double.tryParse(parts[1]);
            if (num != null && den != null && den != 0) {
              qtyValue = num / den;
            }
          }
        }
      } else {
        qtyValue = double.tryParse(qtyStr) ?? 1.0;
      }
    } catch (e) {
      debugPrint('RecipeFormatter: Error parsing quantity "$qtyStr": $e');
      qtyValue = 1.0;
    }

    final totalQty = qtyValue * servings;
    // Format to avoid .0 if it's an integer
    String formattedQty = totalQty == totalQty.toInt() ? totalQty.toInt().toString() : totalQty.toStringAsFixed(1);
    
    // Clean up trailing .0 if present from stringAsFixed
    if (formattedQty.endsWith('.0')) {
      formattedQty = formattedQty.substring(0, formattedQty.length - 2);
    }
    
    if (unit != null && unit.isNotEmpty) {
      return "$formattedQty $unit";
    }
    return formattedQty;
  }
}
