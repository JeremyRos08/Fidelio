import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/brand_promotion_service.dart';

class StoreWebViewScreen extends StatefulWidget {
  const StoreWebViewScreen({
    super.key,
    required this.storeName,
    required this.page,
    this.title,
    this.allowExternalNavigation = false,
    this.initialHtml,
    this.initialBaseUrl,
  });

  final String storeName;
  final BrandPromotionPage page;
  final String? title;
  final bool allowExternalNavigation;
  final String? initialHtml;
  final String? initialBaseUrl;

  @override
  State<StoreWebViewScreen> createState() => _StoreWebViewScreenState();
}

class _StoreWebViewScreenState extends State<StoreWebViewScreen> {
  WebViewController? controller;
  int progress = 0;
  String? errorMessage;
  var nextAlternativeIndex = 0;
  bool usingStoreHome = false;

  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    super.initState();
    if (!_isSupported) return;

    final webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => progress = value);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => errorMessage = null);
          },
          onPageFinished: (_) {
            final currentController = controller;
            if (currentController != null) {
              _keepLinksInWebView(currentController);
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false || !mounted) return;
            if (_tryNextAddress()) return;
            _showLoadError();
          },
          onHttpError: _handleHttpError,
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            if (uri.scheme == 'about' ||
                uri.scheme == 'data' ||
                uri.scheme == 'blob') {
              return NavigationDecision.navigate;
            }
            final isWebLink = uri.scheme == 'https' || uri.scheme == 'http';
            if (isWebLink &&
                (widget.page.allowsHost(uri.host) ||
                    widget.allowExternalNavigation)) {
              return NavigationDecision.navigate;
            }
            _showBlockedLinkMessage();
            return NavigationDecision.prevent;
          },
        ),
      );
    controller = webController;
    _loadInitialPage(webController);
  }

  void _loadInitialPage(WebViewController webController) {
    final initialHtml = widget.initialHtml;
    if (initialHtml == null) {
      webController.loadRequest(widget.page.uri);
    } else {
      webController.loadHtmlString(initialHtml, baseUrl: widget.initialBaseUrl);
    }
  }

  void _keepLinksInWebView(WebViewController webController) {
    if (!widget.allowExternalNavigation) return;
    unawaited(
      webController.runJavaScript('''
        (() => {
          const keepHere = () => {
            document.querySelectorAll('a[target="_blank"]').forEach((link) => {
              link.setAttribute('target', '_self');
            });
          };
          keepHere();
          new MutationObserver(keepHere).observe(document.documentElement, {
            childList: true,
            subtree: true,
          });
        })();
      '''),
    );
  }

  bool _tryNextAddress() {
    if (nextAlternativeIndex >= widget.page.alternativeUris.length) {
      return false;
    }
    final nextUri = widget.page.alternativeUris[nextAlternativeIndex++];
    controller?.loadRequest(nextUri);
    return true;
  }

  Future<void> _handleHttpError(HttpResponseError error) async {
    final statusCode = error.response?.statusCode;
    if (statusCode == null || statusCode < 400 || !mounted) return;

    final failedUri = error.response?.uri ?? error.request?.uri;
    final currentUrl = await controller?.currentUrl();
    final currentUri = currentUrl == null ? null : Uri.tryParse(currentUrl);
    if (!mounted || failedUri == null || currentUri == null) return;
    if (failedUri.host != currentUri.host ||
        failedUri.path != currentUri.path) {
      return;
    }
    _showLoadError();
  }

  void _showLoadError() {
    if (!mounted) return;
    setState(() {
      errorMessage =
          'Cette page n’est plus disponible ou ne peut pas être chargée. Vous pouvez réessayer ou ouvrir le site de l’enseigne.';
    });
  }

  void _openStoreHome(WebViewController webController) {
    final homeUri = widget.page.storeHomeUri;
    if (homeUri == null) return;
    setState(() {
      errorMessage = null;
      progress = 0;
      usingStoreHome = true;
    });
    webController.loadRequest(homeUri);
  }

  void _showBlockedLinkMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce lien extérieur a été bloqué par Fidelio.'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final webController = controller;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Offres ${widget.storeName}'),
        actions: [
          if (webController != null) ...[
            IconButton(
              tooltip: 'Page précédente',
              onPressed: () async {
                if (await webController.canGoBack()) {
                  await webController.goBack();
                }
              },
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            IconButton(
              tooltip: 'Page suivante',
              onPressed: () async {
                if (await webController.canGoForward()) {
                  await webController.goForward();
                }
              },
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
            IconButton(
              tooltip: 'Actualiser',
              onPressed: webController.reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ],
      ),
      body: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          key: const ValueKey('webview-bottom-safe-area'),
          top: false,
          minimum: const EdgeInsets.only(bottom: 12),
          child: webController == null
              ? const _UnsupportedBrowser()
              : Stack(
                  children: [
                    WebViewWidget(controller: webController),
                    if (widget.page.isAddressSuggested && progress < 100)
                      Positioned(
                        left: 12,
                        right: 12,
                        top: 12,
                        child: Material(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Fidelio recherche le site à partir du nom de l’enseigne…',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    if (progress < 100)
                      LinearProgressIndicator(value: progress / 100),
                    if (errorMessage case final message?)
                      ColoredBox(
                        color: Theme.of(context).colorScheme.surface,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.wifi_off_rounded, size: 50),
                                const SizedBox(height: 14),
                                Text(message, textAlign: TextAlign.center),
                                const SizedBox(height: 18),
                                FilledButton.icon(
                                  onPressed: () {
                                    setState(() => errorMessage = null);
                                    _loadInitialPage(webController);
                                  },
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Réessayer'),
                                ),
                                if (widget.page.storeHomeUri != null &&
                                    !usingStoreHome) ...[
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _openStoreHome(webController),
                                    icon: const Icon(Icons.storefront_rounded),
                                    label: const Text(
                                      'Ouvrir le site de l’enseigne',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _UnsupportedBrowser extends StatelessWidget {
  const _UnsupportedBrowser();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'L’affichage intégré des offres est disponible sur mobile.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
