/*
    Folio, the unofficial client for e-Kréta
    Copyright (C) 2025  Folio team

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import 'dart:async';
import 'dart:io' show Platform;
import 'package:folio_mobile_ui/common/widgets/app_logo.dart';
import 'package:folio/api/client.dart';
import 'package:folio/api/login.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/models/user.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio_kreta_api/models/school.dart';
import 'package:folio_mobile_ui/common/custom_snack_bar.dart';
import 'package:folio_mobile_ui/common/system_chrome.dart';
import 'package:folio_mobile_ui/screens/settings/privacy_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.i18n.dart';
import 'package:folio_mobile_ui/screens/login/kreten_login.dart';
import 'package:provider/provider.dart';

class _LoginSheetResult {
  final String code;
  final String? idpApplication;
  final String? idpRememberBrowser;
  _LoginSheetResult(
      {required this.code, this.idpApplication, this.idpRememberBrowser});
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.back = false});

  final bool back;

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  LoginState _loginState = LoginState.normal;
  bool showBack = false;
  int _demoTapCount = 0;

  @override
  void initState() {
    super.initState();
    showBack = widget.back;
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final topPadding = Platform.isAndroid ? 20.0 : 0.0;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // Subtle background accent
          Positioned(
            top: -size.width * 0.4,
            right: -size.width * 0.3,
            child: Container(
              width: size.width * 1.2,
              height: size.width * 1.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                if (showBack)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 8.0, top: topPadding),
                      child: BackButton(color: cs.onSurface),
                    ),
                  )
                else
                  SizedBox(height: topPadding + 8.0),

                // Center content
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // App icon
                      GestureDetector(
                        onTap: () {
                          setState(() => _demoTapCount++);
                          if (_demoTapCount >= 10) {
                            _demoTapCount = 0;
                            final userProvider = Provider.of<UserProvider>(
                                context,
                                listen: false);
                            final demoUser = User.demo();
                            userProvider.addUser(demoUser);
                            userProvider.setUser(demoUser.id);
                            setSystemChrome(context);
                            Navigator.of(context)
                                .pushReplacementNamed('login_to_navigation');
                          }
                        },
                        child: Container(
                          width: 108.0,
                          height: 108.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28.0),
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.22),
                                blurRadius: 40.0,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: AppLogo(size: 108.0),
                        ),
                      ),

                      const SizedBox(height: 20.0),

                      Text(
                        'Folio',
                        style: tt.headlineLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: -0.5,
                          fontSize: 36.0,
                        ),
                      ),

                      const SizedBox(height: 6.0),

                      Text(
                        'login_w_kreten'.i18n,
                        style: tt.bodyMedium!.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const Spacer(),

                      // Feature highlights
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 28.0),
                        child: Column(
                          children: [
                            _FeatureRow(
                              icon: Icons.calendar_today_rounded,
                              label: 'welcome_title_1'.i18n,
                            ),
                            const SizedBox(height: 10.0),
                            _FeatureRow(
                              icon: Icons.bar_chart_rounded,
                              label: 'welcome_title_2'.i18n,
                            ),
                            const SizedBox(height: 10.0),
                            _FeatureRow(
                              icon: Icons.flag_rounded,
                              label: 'welcome_title_3'.i18n,
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      if (_loginState == LoginState.failed)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              28.0, 0, 28.0, 12.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14.0, vertical: 10.0),
                            decoration: BoxDecoration(
                              color: cs.errorContainer,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              "error".i18n,
                              style: tt.bodySmall!.copyWith(
                                color: cs.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Bottom actions
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(24.0, 0, 24.0, 12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 54.0,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _loginState == LoginState.inProgress
                              ? null
                              : _openLoginSheet,
                          child: _loginState == LoginState.inProgress
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white),
                                )
                              : Text(
                                  'login_w_kreta_acc'.i18n,
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 14.0),

                      GestureDetector(
                        onTap: () => PrivacyView.show(context),
                        child: Text(
                          'privacy'.i18n,
                          style: tt.bodySmall!.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.38),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8.0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLoginSheet() async {
    // Step 1 — school selection
    final school = await showModalBottomSheet<School>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) =>
              _SchoolSheet(scrollController: scrollController),
        ),
      ),
    );

    if (school == null || !mounted) return;

    // Step 2 — credentials
    final result = await showModalBottomSheet<_LoginSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _CredentialsSheet(
          school: school,
          onLogin: (result) => Navigator.of(sheetContext).pop(result),
          onDemoMode: () {
            Navigator.of(sheetContext).pop();
            final userProvider =
                Provider.of<UserProvider>(context, listen: false);
            final demoUser = User.demo();
            userProvider.addUser(demoUser);
            userProvider.setUser(demoUser.id);
            setSystemChrome(context);
            Navigator.of(context).pushReplacementNamed('login_to_navigation');
          },
        ),
      ),
    );

    if (result != null && mounted) {
      _processLogin(result);
    }
  }

  void _processLogin(_LoginSheetResult result) {
    setState(() => _loginState = LoginState.inProgress);
    newLoginAPI(
      code: result.code,
      idpApplication: result.idpApplication,
      idpRememberBrowser: result.idpRememberBrowser,
      context: context,
      onLogin: (user) {
        ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(
          context: context,
          brightness: Brightness.light,
          content: Text("welcome".i18n.fill([user.name]),
              overflow: TextOverflow.ellipsis),
        ));
      },
      onSuccess: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        setSystemChrome(context);
        Navigator.of(context).pushReplacementNamed("login_to_navigation");
      },
    ).then((res) {
      if (mounted) {
        setState(() => _loginState = res ?? LoginState.failed);
      }
    });
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 36.0,
          height: 36.0,
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Icon(icon, size: 18.0, color: cs.onPrimaryContainer),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Text(
            label,
            style: tt.bodyMedium!.copyWith(
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// School selection sheet
// ---------------------------------------------------------------------------

class _SchoolSheet extends StatefulWidget {
  const _SchoolSheet({required this.scrollController});
  final ScrollController scrollController;

  @override
  State<_SchoolSheet> createState() => _SchoolSheetState();
}

class _SchoolSheetState extends State<_SchoolSheet> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  List<School> _results = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _searchFocus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.trim();
    if (q.length < 3) {
      _debounce?.cancel();
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    _debounce?.cancel();
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final res = await FilcAPI.searchSchoolsFromKreta(q);
      if (!mounted) return;
      setState(() {
        _results = res ?? [];
        _searching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final q = _searchController.text.trim();

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12.0),
          Container(
            width: 32.0,
            height: 4.0,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          const SizedBox(height: 20.0),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'select_school'.i18n,
                style: tt.titleLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'school_search_hint'.i18n,
                hintStyle: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.35),
                  fontSize: 14.0,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: cs.onSurface.withValues(alpha: 0.4),
                  size: 20.0,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 18.0,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: cs.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide:
                      BorderSide(color: cs.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 16.0),
              ),
              style: TextStyle(
                fontSize: 14.0,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8.0),

          // Results
          Expanded(
            child: _searching
                ? Center(
                    child: CircularProgressIndicator(
                      color: cs.primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          q.length < 3
                              ? 'school_type_hint'.i18n
                              : 'school_no_results'.i18n,
                          style: tt.bodyMedium!.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: widget.scrollController,
                        padding: const EdgeInsets.only(bottom: 24.0),
                        itemCount: _results.length,
                        itemBuilder: (context, i) {
                          final school = _results[i];
                          return InkWell(
                            onTap: () => Navigator.of(context).pop(school),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 14.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36.0,
                                    height: 36.0,
                                    decoration: BoxDecoration(
                                      color: cs.primaryContainer
                                          .withValues(alpha: 0.6),
                                      borderRadius:
                                          BorderRadius.circular(10.0),
                                    ),
                                    child: Icon(
                                      Icons.school_rounded,
                                      size: 18.0,
                                      color: cs.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 14.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          school.name,
                                          style: tt.bodyMedium!.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                        if (school.city.isNotEmpty)
                                          Text(
                                            school.city,
                                            style: tt.bodySmall!.copyWith(
                                              color: cs.onSurface
                                                  .withValues(alpha: 0.45),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20.0,
                                    color:
                                        cs.onSurface.withValues(alpha: 0.25),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Credentials sheet (username + password, AutofillGroup for Proton Pass)
// ---------------------------------------------------------------------------

class _CredentialsSheet extends StatefulWidget {
  const _CredentialsSheet({
    required this.school,
    required this.onLogin,
    this.onDemoMode,
  });

  final School school;
  final void Function(_LoginSheetResult) onLogin;
  final VoidCallback? onDemoMode;

  @override
  State<_CredentialsSheet> createState() => _CredentialsSheetState();
}

class _CredentialsSheetState extends State<_CredentialsSheet> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  LoginState _sheetError = LoginState.normal;

  // 2FA state
  bool _showTwoFactor = false;
  int _twoFactorAttempt = 0;
  Completer<String?>? _twoFactorCompleter;
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _twoFactorCompleter?.complete(null);
    super.dispose();
  }

  void _onSubmit() {
    if (_usernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _sheetError = LoginState.missingFields);
      return;
    }
    TextInput.finishAutofillContext();
    setState(() {
      _isLoading = true;
      _sheetError = LoginState.normal;
    });
  }

  Future<String?> _onTwoFactorRequired() async {
    if (!mounted) return null;
    _twoFactorAttempt++;
    _twoFactorCompleter = Completer<String?>();
    for (final c in _otpControllers) {
      c.clear();
    }
    setState(() => _showTwoFactor = true);
    final result = await _twoFactorCompleter!.future;
    if (mounted) setState(() => _showTwoFactor = false);
    return result;
  }

  void _submitTwoFactor() {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length == 6 &&
        _twoFactorCompleter != null &&
        !_twoFactorCompleter!.isCompleted) {
      _twoFactorCompleter!.complete(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12.0),
          Container(
            width: 32.0,
            height: 4.0,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          const SizedBox(height: 24.0),

          if (_isLoading)
            _buildLoading(cs, tt, bottomPad)
          else
            _buildForm(cs, tt, bottomPad),
        ],
      ),
    );
  }

  Widget _buildLoading(ColorScheme cs, TextTheme tt, double bottomPad) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          width: 1,
          height: 1,
          child: KretaBgLoginWidget(
            instituteCode: widget.school.instituteCode,
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            rememberbrowserCookie: null,
            onLogin: (code, app, rem) {
              if (!mounted) return;
              widget.onLogin(_LoginSheetResult(
                code: code,
                idpApplication: app,
                idpRememberBrowser: rem,
              ));
            },
            onError: (state) {
              if (!mounted) return;
              setState(() {
                _isLoading = false;
                _sheetError = state;
              });
            },
            onTwoFactorRequired: _onTwoFactorRequired,
          ),
        ),
        if (_showTwoFactor)
          _buildTwoFactor(cs, tt, bottomPad)
        else
          SizedBox(
            height: 220.0 + bottomPad,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 44.0,
                    height: 44.0,
                    child: CircularProgressIndicator(
                        color: cs.primary, strokeWidth: 3.0),
                  ),
                  const SizedBox(height: 20.0),
                  Text(
                    'Bejelentkezés folyamatban',
                    style: tt.titleSmall!.copyWith(
                        fontWeight: FontWeight.w600, color: cs.onSurface),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Kérjük, várj...',
                    style: tt.bodySmall!
                        .copyWith(color: cs.onSurface.withValues(alpha: 0.45)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTwoFactor(ColorScheme cs, TextTheme tt, double bottomPad) {
    final isRetry = _twoFactorAttempt > 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(24.0, 0, 24.0, bottomPad + 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kétlépéses azonosítás',
            style: tt.titleLarge!.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Add meg a hitelesítő alkalmazásban megjelenő 6 jegyű kódot.',
            style: tt.bodyMedium!.copyWith(
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          if (isRetry) ...[
            const SizedBox(height: 12.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 15.0, color: cs.onErrorContainer),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Hibás kód. Kérjük, próbáld újra.',
                      style: tt.bodySmall!.copyWith(
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...[0, 1, 2].map((i) => _buildOtpBox(i, cs, tt)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Text(
                  '—',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.3),
                    fontSize: 18,
                  ),
                ),
              ),
              ...[3, 4, 5].map((i) => _buildOtpBox(i, cs, tt)),
            ],
          ),
          const SizedBox(height: 24.0),
          SizedBox(
            width: double.infinity,
            height: 52.0,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 0,
              ),
              onPressed: _submitTwoFactor,
              child: const Text(
                'Megerősítés',
                style:
                    TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleOtpPaste(String digits) {
    final clean = digits.replaceAll(RegExp(r'[^0-9]'), '');
    for (int i = 0; i < 6 && i < clean.length; i++) {
      _otpControllers[i].text = clean[i];
    }
    if (clean.length >= 6) {
      _otpFocusNodes[5].unfocus();
      setState(() {});
      _submitTwoFactor();
    } else {
      final next = clean.length.clamp(0, 5);
      _otpFocusNodes[next].requestFocus();
      setState(() {});
    }
  }

  Widget _buildOtpBox(int index, ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: SizedBox(
        width: 42.0,
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _OtpPasteFormatter(_handleOtpPaste),
          ],
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (index < 5) {
                _otpFocusNodes[index + 1].requestFocus();
              } else {
                _otpFocusNodes[index].unfocus();
              }
              if (_otpControllers.every((c) => c.text.isNotEmpty)) {
                _submitTwoFactor();
              }
            } else if (index > 0) {
              _otpFocusNodes[index - 1].requestFocus();
            }
          },
          style: tt.titleLarge!.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
          cursorColor: cs.primary,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14.0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: cs.onSurface.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: cs.primary, width: 2.0),
            ),
            filled: true,
            fillColor: cs.surfaceContainerHigh,
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ColorScheme cs, TextTheme tt, double bottomPad) {
    final hasError = _sheetError == LoginState.missingFields ||
        _sheetError == LoginState.invalidGrant ||
        _sheetError == LoginState.failed;

    return Padding(
      padding: EdgeInsets.fromLTRB(24.0, 0, 24.0, bottomPad + 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'login_w_kreta_acc'.i18n,
            style: tt.titleLarge!.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8.0),

          // School chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_rounded,
                    size: 13.0, color: cs.onPrimaryContainer),
                const SizedBox(width: 5.0),
                Flexible(
                  child: Text(
                    widget.school.name,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelSmall!.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // Error banner
          if (hasError) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 15.0, color: cs.onErrorContainer),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      _sheetError == LoginState.missingFields
                          ? "missing_fields".i18n
                          : _sheetError == LoginState.invalidGrant
                              ? "invalid_grant".i18n
                              : "error".i18n,
                      style: tt.bodySmall!.copyWith(
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
          ],

          // Both fields wrapped in AutofillGroup so Proton Pass / password
          // managers can fill username AND password in a single tap.
          AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('username'.i18n),
                _buildTextField(
                  controller: _usernameController,
                  focusNode: _usernameFocus,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () =>
                      _passwordFocus.requestFocus(),
                  cs: cs,
                ),
                const SizedBox(height: 12.0),
                _FieldLabel('password'.i18n),
                _buildTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  autofillHints: const [AutofillHints.password],
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _onSubmit,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 18.0,
                      color: AppColors.of(context)
                          .text
                          .withValues(alpha: 0.6),
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  cs: cs,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // Login button
          SizedBox(
            width: double.infinity,
            height: 52.0,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 0,
              ),
              onPressed: _onSubmit,
              child: Text(
                'login'.i18n,
                style: const TextStyle(
                    fontSize: 15.0, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          if (widget.onDemoMode != null) ...[
            const SizedBox(height: 6.0),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: cs.onSurface.withValues(alpha: 0.45),
                ),
                onPressed: widget.onDemoMode,
                child: Text('demo_login'.i18n),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required List<String> autofillHints,
    required TextInputAction textInputAction,
    required VoidCallback onEditingComplete,
    required ColorScheme cs,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
      obscureText: obscureText,
      cursorColor: cs.primary,
      style: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        color: cs.onSurface.withValues(alpha: 0.85),
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
              color: cs.onSurface.withValues(alpha: 0.15), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// OTP paste formatter – distributes pasted multi-digit input across all boxes
// ---------------------------------------------------------------------------

class _OtpPasteFormatter extends TextInputFormatter {
  final void Function(String digits) onPaste;
  _OtpPasteFormatter(this.onPaste);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length > 1) {
      Future.microtask(() => onPaste(newValue.text));
      // Clear this box; onPaste will fill all boxes
      return const TextEditingValue();
    }
    // Limit to a single digit
    if (newValue.text.length == 1) {
      return newValue;
    }
    return newValue;
  }
}
