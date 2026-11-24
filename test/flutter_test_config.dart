import 'package:find_job1_1/src/theme/app_theme_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> testExecutable(Future<void> Function() testMain) async {
  SharedPreferences.setMockInitialValues({});
  AppThemeSettings.instance.isDark = true;
  AppThemeSettings.instance.applyPalette();
  await testMain();
}
