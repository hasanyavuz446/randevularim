import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OnboardingView extends StatefulWidget {
  final Future<void> Function() onCompleted;

  const OnboardingView({super.key, required this.onCompleted});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  static const _background = Color(0xFF0D0D1A);
  static const _surface = Color(0xFF1A1A2E);
  static const _primary = Color(0xFF496ED9);
  static const _accent = Color(0xFFC9A84C);

  static const _slides = [
    _OnboardingSlide(
      icon: CupertinoIcons.calendar_badge_plus,
      title: 'Hoş Geldiniz',
      description:
          'Randevularım ile programınızı sade ve profesyonel bir şekilde yönetin.',
    ),
    _OnboardingSlide(
      icon: CupertinoIcons.calendar,
      title: 'Randevularını Yönet',
      description:
          'Günlük takviminizi görün, yeni randevular oluşturun ve planınızı takip edin.',
    ),
    _OnboardingSlide(
      icon: CupertinoIcons.person_2_fill,
      title: 'Müşterilerini Takip Et',
      description:
          'Müşteri bilgilerini ve randevu geçmişlerini tek bir yerde düzenli tutun.',
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  bool get _isLastPage => _currentPage == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _advance() async {
    if (!_isLastPage) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    if (_isCompleting) return;
    setState(() => _isCompleting = true);
    await widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.45),
            radius: 1.15,
            colors: [Color(0xFF25264A), _background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 28),
                child: Text(
                  'Randevularım',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemBuilder: (context, index) =>
                      _OnboardingPage(slide: _slides[index]),
                ),
              ),
              _DotIndicator(count: _slides.length, selectedIndex: _currentPage),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isCompleting ? null : _advance,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      disabledBackgroundColor: _primary.withValues(alpha: 0.65),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isCompleting
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Text(
                            _isLastPage ? 'Başla' : 'Sonraki',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingSlide slide;

  const _OnboardingPage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 154,
            width: 154,
            decoration: BoxDecoration(
              color: _OnboardingViewState._surface,
              borderRadius: BorderRadius.circular(42),
              border: Border.all(
                color: _OnboardingViewState._primary.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: _OnboardingViewState._primary.withValues(alpha: 0.2),
                  blurRadius: 36,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 92,
                  width: 92,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x24496ED9),
                  ),
                ),
                Icon(slide.icon, color: _OnboardingViewState._accent, size: 60),
              ],
            ),
          ),
          const SizedBox(height: 50),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB6B7C9),
              height: 1.5,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final int count;
  final int selectedIndex;

  const _DotIndicator({required this.count, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: index == selectedIndex ? 26 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: index == selectedIndex
                ? _OnboardingViewState._primary
                : const Color(0xFF404159),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
  });
}
