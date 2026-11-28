import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'controllers/theme_controller.dart';
import 'theme/app_theme.dart';
import 'views/home_screen.dart';

export 'views/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  final themeController = ThemeController();
  await themeController.initialize();
  runApp(KrediKartiHesapTakipApp(themeController: themeController));
}

class KrediKartiHesapTakipApp extends StatefulWidget {
  final ThemeController? themeController;

  const KrediKartiHesapTakipApp({super.key, this.themeController});

  @override
  State<KrediKartiHesapTakipApp> createState() => _KrediKartiHesapTakipAppState();
}

class _KrediKartiHesapTakipAppState extends State<KrediKartiHesapTakipApp> {
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = widget.themeController ?? ThemeController();
    if (widget.themeController == null) {
      _themeController.initialize();
    }
  }

  @override
  void dispose() {
    if (widget.themeController == null) {
      _themeController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Hesap & Harcama Takibi',
          debugShowCheckedModeBanner: false,
          themeMode: _themeController.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          locale: const Locale('tr', 'TR'),
          supportedLocales: const [
            Locale('tr', 'TR'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: HomeScreen(themeController: _themeController),
        );
      },
    );
  }
}
