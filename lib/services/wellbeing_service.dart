class WellbeingService {
  final List<String> _quotes = [
    "Small steps every day lead to big results. Keep going!",
    "Consistency is the key to good health.",
    "Every dose taken is a step toward a healthier you.",
    "Your health is your wealth — protect it.",
    "A journey of a thousand miles begins with a single step.",
    "Take care of your body. It's the only place you have to live.",
    "Health is a state of body. Wellness is a state of being.",
    "You don't have to be perfect, just be consistent.",
  ];

  String getTodayQuote() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return _quotes[dayOfYear % _quotes.length];
  }
}
