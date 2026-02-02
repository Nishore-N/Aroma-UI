void main() {
  double val = 0.25;
  print("Value: $val");
  print("formatted (1 dec): ${val.toStringAsFixed(1)}");
  
  double scaled = val * 2;
  print("Scaled * 2: $scaled");
  print("Formatted Scaled: ${scaled.toStringAsFixed(1)}");
  
  double val2 = 0.3; // If it was truly 0.3
  print("Value 2: $val2");
  print("Scaled * 2: ${val2 * 2}");
}
