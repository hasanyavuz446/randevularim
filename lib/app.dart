import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_config.dart';
import 'providers/providers.dart';
import 'services/notification_service.dart';
import 'views/main/main_scaffold.dart';
import 'views/onboarding/onboarding_view.dart';

class RandevuManagerApp extends ConsumerStatefulWidget {
  const RandevuManagerApp({super.key});

  @override
  ConsumerState<RandevuManagerApp> createState() => _RandevuManagerAppState();
}

class _RandevuManagerAppState extends ConsumerState<RandevuManagerApp> {
  late bool _hasCompletedOnboarding;

  @override
  void initState() {
    super.initState();
    _hasCompletedOnboarding = ref.read(onboardingServiceProvider).isCompleted;
    if (_hasCompletedOnboarding) {
      _requestNotificationPermissionAfterFrame();
    }
  }

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingServiceProvider).complete();
    if (!mounted) return;
    setState(() => _hasCompletedOnboarding = true);
    _requestNotificationPermissionAfterFrame();
  }

  void _requestNotificationPermissionAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        NotificationService.instance.requestPermission();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final config = AppThemeConfig.fromId(settings.themeId);

    return MaterialApp(
      title: 'Randevularım',
      theme: AppTheme.fromConfig(config, brightness: Brightness.light),
      darkTheme: AppTheme.fromConfig(config, brightness: Brightness.dark),
      themeMode: settings.themeMode,
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr', 'TR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR')],
      home: _hasCompletedOnboarding
          ? const MainScaffold()
          : OnboardingView(onCompleted: _completeOnboarding),
    );
  }
}
