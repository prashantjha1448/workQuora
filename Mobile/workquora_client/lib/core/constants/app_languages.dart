class AppLanguage {
  final String code;
  final String name; // English name
  final String nativeName; // Native script name

  const AppLanguage(this.code, this.name, this.nativeName);
}

const List<AppLanguage> supportedLanguages = [
  AppLanguage('en', 'English', 'English'),
  AppLanguage('hi', 'Hindi', 'हिन्दी'),
  AppLanguage('bn', 'Bengali', 'বাংলা'),
  AppLanguage('te', 'Telugu', 'తెలుగు'),
  AppLanguage('mr', 'Marathi', 'मराठी'),
  AppLanguage('ta', 'Tamil', 'தமிழ்'),
  AppLanguage('gu', 'Gujarati', 'ગુજરાતી'),
  AppLanguage('kn', 'Kannada', 'ಕನ್ನಡ'),
  AppLanguage('ml', 'Malayalam', 'മലയാളം'),
  AppLanguage('pa', 'Punjabi', 'ਪੰਜਾਬੀ'),
  AppLanguage('or', 'Odia', 'ଓଡ଼ିଆ'),
  AppLanguage('as', 'Assamese', 'অসমীয়া'),
  AppLanguage('ur', 'Urdu', 'اردو'),
];
