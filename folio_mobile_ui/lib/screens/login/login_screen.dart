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

import 'dart:io' show Platform;
import 'package:folio/api/client.dart';
import 'package:folio/api/login.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/models/user.dart';
import 'package:folio_mobile_ui/common/custom_snack_bar.dart';
import 'package:folio_mobile_ui/common/system_chrome.dart';
import 'package:folio_mobile_ui/screens/login/login_input.dart';
import 'package:folio_mobile_ui/screens/login/school_input/school_input.dart';
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28.0),
                            child: Image.asset(
                              'assets/icons/ic_rounded.png',
                              fit: BoxFit.cover,
                            ),
                          ),
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

  void _openLoginSheet() {
    showModalBottomSheet<_LoginSheetResult>(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32.0),
              ),
            ),
            child: _CredentialsSheet(
              onLogin: (result) => Navigator.of(sheetContext).pop(result),
              onDemoMode: () {
                Navigator.of(sheetContext).pop();
                final userProvider =
                    Provider.of<UserProvider>(context, listen: false);
                final demoUser = User.demo();
                userProvider.addUser(demoUser);
                userProvider.setUser(demoUser.id);
                setSystemChrome(context);
                Navigator.of(context)
                    .pushReplacementNamed('login_to_navigation');
              },
            ),
          ),
        );
      },
    ).then((result) {
      if (result != null && mounted) {
        _processLogin(result);
      }
    });
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

class _CredentialsSheet extends StatefulWidget {
  const _CredentialsSheet({required this.onLogin, this.onDemoMode});

  final void Function(_LoginSheetResult) onLogin;
  final VoidCallback? onDemoMode;

  @override
  State<_CredentialsSheet> createState() => _CredentialsSheetState();
}

class _CredentialsSheetState extends State<_CredentialsSheet> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _schoolController = SchoolInputController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  LoginState _sheetError = LoginState.normal;

  @override
  void initState() {
    super.initState();
    _schoolController.schools = [];
    _schoolController.onSearch = FilcAPI.searchSchoolsFromKreta;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_schoolController.selectedSchool == null ||
        _usernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _sheetError = LoginState.missingFields);
      return;
    }
    setState(() {
      _isLoading = true;
      _sheetError = LoginState.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        // Handle
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          child: Center(
            child: Container(
              width: 36.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
        ),

        if (_isLoading)
          Expanded(
            child: Stack(
              children: [
                // Hidden WebView — rendered but invisible
                Positioned(
                  left: 0,
                  top: 0,
                  width: 1,
                  height: 1,
                  child: KretaBgLoginWidget(
                    instituteCode:
                        _schoolController.selectedSchool!.instituteCode,
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
                  ),
                ),

                // Loading overlay (covers the WebView entirely)
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 56.0,
                        height: 56.0,
                        child: CircularProgressIndicator(
                          color: cs.primary,
                          strokeWidth: 3.0,
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      Text(
                        'Bejelentkezés folyamatban',
                        style: tt.titleMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        'Kérjük, várj...',
                        style: tt.bodyMedium!.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding:
                  const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      'login_w_kreta_acc'.i18n,
                      style: tt.headlineSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Text(
                      'login_w_kreten'.i18n,
                      style: tt.bodySmall!.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),

                  // Error banner
                  if (_sheetError == LoginState.missingFields ||
                      _sheetError == LoginState.invalidGrant ||
                      _sheetError == LoginState.failed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
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
                                size: 16.0, color: cs.onErrorContainer),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                _sheetError == LoginState.missingFields
                                    ? "missing_fields".i18n
                                    : _sheetError ==
                                            LoginState.invalidGrant
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
                    ),

                  // School
                  _FieldLabel('school'.i18n),
                  SchoolInput(
                      controller: _schoolController,
                      scroll: _scrollController),
                  const SizedBox(height: 14.0),

                  // Username
                  _FieldLabel('username'.i18n),
                  LoginInput(
                    style: LoginInputStyle.username,
                    controller: _usernameController,
                  ),
                  const SizedBox(height: 14.0),

                  // Password
                  _FieldLabel('password'.i18n),
                  LoginInput(
                    style: LoginInputStyle.password,
                    controller: _passwordController,
                  ),

                  const SizedBox(height: 24.0),

                  // Login button
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
                      onPressed: _onSubmit,
                      child: Text(
                        'login'.i18n,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  if (widget.onDemoMode != null) ...[
                    const SizedBox(height: 10.0),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor:
                              cs.onSurface.withValues(alpha: 0.5),
                        ),
                        onPressed: widget.onDemoMode,
                        child: Text('demo_login'.i18n),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}
