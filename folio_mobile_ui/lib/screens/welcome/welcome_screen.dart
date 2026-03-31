import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:folio_mobile_ui/common/widgets/app_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.onContinue});

  final VoidCallback? onContinue;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));
    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          brightness == Brightness.light ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
      systemNavigationBarIconBrightness:
          brightness == Brightness.light ? Brightness.dark : Brightness.light,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // Subtle background gradient blob
          Positioned(
            top: -size.height * 0.1,
            left: -size.width * 0.3,
            child: Container(
              width: size.width * 1.2,
              height: size.width * 1.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.primaryContainer.withValues(alpha: 0.45),
                    cs.surface.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  children: [
                    // Top spacer
                    const SizedBox(height: 56.0),

                    // Icon + wordmark
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36.0),
                      child: Column(
                        children: [
                          Container(
                            width: 88.0,
                            height: 88.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22.0),
                              boxShadow: [
                                BoxShadow(
                                  color: cs.primary.withValues(alpha: 0.22),
                                  blurRadius: 36.0,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: AppLogo(size: 88.0),
                          ),
                          const SizedBox(height: 20.0),
                          Text(
                            'Folio',
                            style: tt.displaySmall!.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Az e-KRÉTA egy másik arca.',
                            style: tt.bodyLarge!.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 52.0),

                    // Feature highlights
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _FeatureRow(
                              icon: Icons.home_rounded,
                              color: cs.primaryContainer,
                              iconColor: cs.onPrimaryContainer,
                              title: 'Minden egy helyen',
                              subtitle:
                                  'Órarend, jegyek, házi feladatok és üzenetek egyetlen appban.',
                            ),
                            const SizedBox(height: 12.0),
                            _FeatureRow(
                              icon: Icons.bar_chart_rounded,
                              color: cs.secondaryContainer,
                              iconColor: cs.onSecondaryContainer,
                              title: 'Részletes statisztikák',
                              subtitle:
                                  'Kövesd a teljesítményedet és látd az átlagaid alakulását.',
                            ),
                            const SizedBox(height: 12.0),
                            _FeatureRow(
                              icon: Icons.flag_rounded,
                              color: cs.tertiaryContainer,
                              iconColor: cs.onTertiaryContainer,
                              title: 'Célkitűzések',
                              subtitle:
                                  'Tűzz ki célokat és kövesd, hogy mikor éred el őket.',
                            ),
                          ],
                        ),
                      ),
                    ),

                    // CTA button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 12.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52.0,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                          ),
                          onPressed: widget.onContinue ??
                              () => Navigator.of(context).maybePop(),
                          child: const Text(
                            'Kezdjük el',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 8.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(icon, size: 20.0, color: iconColor),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  subtitle,
                  style: tt.bodySmall!.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
