import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/constants/app_config.dart';
import '../../core/theme/app_typography.dart';
import 'legal_content.dart';
import 'offline_pages.dart';

enum WebPageKind { privacy, support }

extension WebPageKindX on WebPageKind {
  String get title => switch (this) {
        WebPageKind.privacy => 'Privacy Policy',
        WebPageKind.support => 'Support',
      };

  String get url => switch (this) {
        WebPageKind.privacy => AppConfig.privacyPolicyUrl,
        WebPageKind.support => AppConfig.supportUrl,
      };
}

/// Loads the hosted page when the network allows it and falls back to a
/// bundled copy otherwise, so both pages are reachable in every situation.
/// Both are rendered as black text on a white sheet.
class WebPageScreen extends StatefulWidget {
  const WebPageScreen({super.key, required this.kind});

  final WebPageKind kind;

  @override
  State<WebPageScreen> createState() => _WebPageScreenState();
}

class _WebPageScreenState extends State<WebPageScreen> {
  static const Duration _loadTimeout = Duration(seconds: 12);

  WebViewController? _controller;
  StreamSubscription<List<ConnectivityResult>>? _connectivity;
  Timer? _timeout;

  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
    _connectivity = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> result) {
        final bool online = result.any(
          (ConnectivityResult r) => r != ConnectivityResult.none,
        );
        if (online && _failed) _start();
      },
    );
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _connectivity?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _failed = false;
    });

    final List<ConnectivityResult> status = await Connectivity().checkConnectivity();
    final bool online = status.any(
      (ConnectivityResult r) => r != ConnectivityResult.none,
    );
    if (!online) {
      if (mounted) setState(() { _loading = false; _failed = true; });
      return;
    }

    late final WebViewController controller;
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            _timeout?.cancel();
            // Force a readable light rendering no matter what the page ships.
            await controller.runJavaScript(
              "(function(){var s=document.createElement('style');"
              "s.innerHTML='html,body{background:#ffffff !important;"
              "color:#000000 !important;-webkit-text-size-adjust:100%;}"
              "*{color:#000000 !important;}"
              "a{color:#3b3bd6 !important;}"
              "input,textarea,select{background:#ffffff !important;"
              "color:#000000 !important;border:1px solid #cccccc !important;}';"
              "document.head.appendChild(s);})();",
            );
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame ?? true) _fail();
          },
          onHttpError: (HttpResponseError error) => _fail(),
        ),
      );

    _timeout = Timer(_loadTimeout, () {
      if (mounted && _loading) _fail();
    });

    try {
      await controller.loadRequest(Uri.parse(widget.kind.url));
      if (mounted) setState(() => _controller = controller);
    } catch (_) {
      _fail();
    }
  }

  void _fail() {
    _timeout?.cancel();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _LightHeader(
                title: widget.kind.title,
                onRetry: _failed ? _start : null,
              ),
              const Divider(height: 1, color: Color(0xFFE6E6EA)),
              Expanded(
                child: _failed
                    ? OfflinePage(kind: widget.kind)
                    : Stack(
                        children: <Widget>[
                          if (_controller != null)
                            WebViewWidget(controller: _controller!),
                          if (_loading)
                            const ColoredBox(
                              color: Colors.white,
                              child: Center(
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Color(0xFF6C5CE7),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LightHeader extends StatelessWidget {
  const _LightHeader({required this.title, required this.onRetry});

  final String title;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(AppIcons.arrowLeft,
                size: 20, color: Colors.black),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              title,
              style: AppType.titleM(color: Colors.black),
            ),
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(AppIcons.refresh,
                  size: 15, color: Color(0xFF3B3BD6)),
              label: Text(
                'Retry',
                style: AppType.label(color: const Color(0xFF3B3BD6)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Exposed for the offline support form.
const String supportEmailAddress = AppConfig.supportEmail;

/// Re-exported so callers only need this file.
const List<LegalBlock> bundledPrivacy = LegalContent.privacy;
