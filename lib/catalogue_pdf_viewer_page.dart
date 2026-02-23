import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'province_dropdown.dart';

class CataloguePdfViewerPage extends StatefulWidget {
  const CataloguePdfViewerPage({
    super.key,
    required this.storeName,
    required this.pdfUrl,
  });

  final String storeName;
  final String pdfUrl;

  @override
  State<CataloguePdfViewerPage> createState() =>
      _CataloguePdfViewerPageState();
}

class _CataloguePdfViewerPageState extends State<CataloguePdfViewerPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  Uri _buildViewerUri(String pdfUrl) {
    final Uri raw = Uri.parse(pdfUrl);
    return Uri.parse(
      'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(raw.toString())}',
    );
  }

  @override
  void initState() {
    super.initState();

    // On web, WebView is not needed; we simply rely on the browser.
    if (!kIsWeb) {
      final Uri viewerUri = _buildViewerUri(widget.pdfUrl);
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // Optional: update loading progress
            },
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
                _error = null;
              });
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                _isLoading = false;
                _error = error.description;
              });
            },
          ),
        )
        ..enableZoom(true)
        ..setBackgroundColor(const Color(0xFFFFFFFF))
        ..loadRequest(viewerUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF315762);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.storeName} catalogue'),
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ProvinceDropdown(
              foregroundColor: Colors.white,
              dropdownColor: primaryTeal,
            ),
          ),
        ],
      ),
      body: kIsWeb
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'On web, the catalogue PDF opens in your browser.\n\n'
                  'URL: ${widget.pdfUrl}',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Stack(
              children: <Widget>[
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                if (_error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load PDF',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _error = null;
                                _isLoading = true;
                              });
                              _controller.reload();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
