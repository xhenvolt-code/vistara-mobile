import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/demo_catalogue.dart';
import '../models/access_product.dart';
import '../models/account_session.dart';
import '../models/movie.dart';
import '../services/vistara_api.dart';
import '../theme/app_theme.dart';
import 'account_screen.dart';
import 'auth_screen.dart';
import 'discover_screen.dart';
import 'home_screen.dart';
import 'passes_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _api = VistaraApi();
  int _selectedIndex = 0;
  late List<Movie> _movies;
  List<AccessProduct> _products = const [];
  bool _catalogueLoading = false;
  bool _productsLoading = false;
  String? _catalogueError;
  String? _productsError;
  String? _sessionError;
  AccountSession? _session;

  bool get _isPreview => !_api.isConfigured;

  @override
  void initState() {
    super.initState();
    _movies = _isPreview ? demoCatalogue : const [];
    if (_api.isConfigured) {
      _loadCatalogue();
      _loadAccessProducts();
      _restoreSession();
    }
  }

  Future<void> _loadCatalogue() async {
    setState(() {
      _catalogueLoading = true;
      _catalogueError = null;
    });
    try {
      final movies = await _api.loadCatalogue();
      if (!mounted) return;
      setState(() => _movies = movies);
    } on VistaraApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _movies = const [];
        _catalogueError = error.message;
      });
    } finally {
      if (mounted) setState(() => _catalogueLoading = false);
    }
  }

  Future<void> _loadAccessProducts() async {
    setState(() {
      _productsLoading = true;
      _productsError = null;
    });
    try {
      final products = await _api.loadAccessProducts();
      if (!mounted) return;
      setState(() => _products = products);
    } on VistaraApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _products = const [];
        _productsError = error.message;
      });
    } finally {
      if (mounted) setState(() => _productsLoading = false);
    }
  }

  Future<void> _restoreSession() async {
    try {
      final session = await _api.restoreSession();
      if (!mounted) return;
      setState(() {
        _session = session;
        _sessionError = null;
      });
    } on VistaraApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _session = null;
        _sessionError = error.statusCode == 401 ? null : error.message;
      });
    }
  }

  Future<void> _openAccount() async {
    final session = _session;
    if (session != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => AccountScreen(
            session: session,
            onSignOut: () => _signOut(context),
          ),
        ),
      );
      return;
    }

    final signedInSession = await Navigator.of(context).push<AccountSession>(
      MaterialPageRoute<AccountSession>(
        builder: (_) => AuthScreen(api: _api, sessionError: _sessionError),
      ),
    );
    if (signedInSession != null && mounted) {
      setState(() {
        _session = signedInSession;
        _sessionError = null;
      });
    }
  }

  Future<void> _signOut(BuildContext accountContext) async {
    final navigator = Navigator.of(accountContext);
    try {
      await _api.signOut();
    } on VistaraApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _session = null);
        if (navigator.mounted) navigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _session?.user.name;
    final palette = context.vistara;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: palette.background,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: palette.background,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              HomeScreen(
                onSignIn: _openAccount,
                onExplore: () => setState(() => _selectedIndex = 1),
                onViewPasses: () => setState(() => _selectedIndex = 2),
                movies: _movies,
                isPreview: _isPreview,
                isLoading: _catalogueLoading,
                error: _catalogueError,
                onRetry: _loadCatalogue,
                displayName: displayName,
              ),
              DiscoverScreen(
                onSignIn: _openAccount,
                onViewPasses: () => setState(() => _selectedIndex = 2),
                onSearch: () => setState(() => _selectedIndex = 1),
                movies: _movies,
                isPreview: _isPreview,
                error: _catalogueError,
                onRetry: _loadCatalogue,
                displayName: displayName,
              ),
              PassesScreen(
                onSignIn: _openAccount,
                onSearch: () => setState(() => _selectedIndex = 1),
                products: _products,
                isConfigured: _api.isConfigured,
                isLoading: _productsLoading,
                error: _productsError,
                onRetry: _loadAccessProducts,
                displayName: displayName,
              ),
            ],
          ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: palette.line)),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_rounded),
                label: 'Discover',
              ),
              NavigationDestination(
                icon: Icon(Icons.confirmation_number_outlined),
                selectedIcon: Icon(Icons.confirmation_number_rounded),
                label: 'Passes',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
