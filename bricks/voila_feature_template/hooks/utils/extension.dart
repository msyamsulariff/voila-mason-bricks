extension StringE on String {
  String get uid => '$this${DateTime.now().microsecondsSinceEpoch}';
}
