String formatCountAdvanced(int count) {
  if (count < 1000) return count.toString();

  final suffixes = ["K", "M", "B", "T"];
  double value = count.toDouble();
  int i = -1;

  while (value >= 1000 && i < suffixes.length - 1) {
    value /= 1000;
    i++;
  }

  String formatted =
      (value < 10 ? value.toStringAsFixed(1) : value.toStringAsFixed(0)) +
          suffixes[i];

  if (formatted.endsWith(".0" + suffixes[i])) {
    formatted = formatted.replaceAll(".0" + suffixes[i], suffixes[i]);
  }

  return formatted;
}
