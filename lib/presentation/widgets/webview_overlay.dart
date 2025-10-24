import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewOverlay extends StatefulWidget {
  final String url;
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final bool isMinimized;
  final Function(String)? onAskAI;

  const WebViewOverlay({
    super.key,
    required this.url,
    required this.onClose,
    required this.onMinimize,
    this.isMinimized = false,
    this.onAskAI,
  });

  @override
  State<WebViewOverlay> createState() => _WebViewOverlayState();
}

class _WebViewOverlayState extends State<WebViewOverlay> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  String _currentUrl = '';
  String _pageTitle = 'Loading...';
  bool _canGoBack = false;
  bool _canGoForward = false;
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();
  late ContextMenu _contextMenu;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _urlController.text = widget.url;

    // Configure context menu with Ask AI option
    _contextMenu = ContextMenu(
      menuItems: [
        ContextMenuItem(
          id: 1,
          title: '🧠 Ask AI about this',
          action: () async {
            final selectedText = await _controller?.getSelectedText();
            if (selectedText != null && selectedText.isNotEmpty) {
              if (widget.onAskAI != null) {
                widget.onAskAI!(selectedText);
              }
            }
          },
        ),
        ContextMenuItem(
          id: 2,
          title: '📋 Copy',
          action: () async {
            final selectedText = await _controller?.getSelectedText();
            if (selectedText != null && selectedText.isNotEmpty) {
              Clipboard.setData(ClipboardData(text: selectedText));
            }
          },
        ),
      ],
    );
  }

  Future<void> _updateNavigationState() async {
    if (_controller == null) return;
    final canGoBack = await _controller!.canGoBack();
    final canGoForward = await _controller!.canGoForward();
    if (mounted) {
      setState(() {
        _canGoBack = canGoBack;
        _canGoForward = canGoForward;
      });
    }
  }

  void _navigateToUrl(String url) {
    String finalUrl = url.trim();

    // Add https:// if no protocol specified
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }

    _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(finalUrl)));
    _urlFocusNode.unfocus();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMinimized) {
      return _buildMinimizedView();
    }
    return _buildFullView();
  }

  Widget _buildFullView() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header bar
          Column(
            children: [
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: widget.onClose,
                      tooltip: 'Close',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    // Minimize button
                    IconButton(
                      icon: const Icon(Icons.minimize, size: 20),
                      onPressed: widget.onMinimize,
                      tooltip: 'Minimize',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed:
                          _canGoBack ? () => _controller?.goBack() : null,
                      tooltip: 'Back',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    // Forward button
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, size: 20),
                      onPressed:
                          _canGoForward ? () => _controller?.goForward() : null,
                      tooltip: 'Forward',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    // Refresh button
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () => _controller?.reload(),
                      tooltip: 'Refresh',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // URL bar
                    Expanded(
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: TextField(
                          controller: _urlController,
                          focusNode: _urlFocusNode,
                          style: theme.textTheme.bodySmall,
                          decoration: InputDecoration(
                            hintText: 'Enter URL',
                            hintStyle: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            isDense: true,
                          ),
                          onSubmitted: _navigateToUrl,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
              // Linear progress indicator
              if (_isLoading)
                LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                  minHeight: 2,
                ),
            ],
          ),
          // WebView content with context menu
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  iframeAllow: 'camera; microphone',
                  iframeAllowFullscreen: true,
                  // Enable mixed content for PubMed
                  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                ),
                contextMenu: _contextMenu,
                onWebViewCreated: (controller) {
                  _controller = controller;
                  debugPrint('WebView created, loading: ${widget.url}');
                },
                onLoadStart: (controller, url) {
                  debugPrint('WebView loading: $url');
                  if (mounted) {
                    setState(() {
                      _isLoading = true;
                      _loadingProgress = 0.0;
                      _currentUrl = url?.toString() ?? '';
                      _urlController.text = _currentUrl;
                    });
                    _updateNavigationState();
                  }
                },
                onLoadStop: (controller, url) async {
                  debugPrint('WebView loaded: $url');
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                      _loadingProgress = 1.0;
                    });
                    _updateNavigationState();

                    // Get page title
                    final title = await controller.getTitle();
                    if (title != null && mounted) {
                      setState(() => _pageTitle = title);
                    }
                  }
                },
                onProgressChanged: (controller, progress) {
                  if (mounted) {
                    setState(() {
                      _loadingProgress = progress / 100.0;
                    });
                  }
                },
                onReceivedError: (controller, request, error) {
                  debugPrint(
                    'WebView error: ${error.type} - ${error.description} for ${request.url}',
                  );
                },
                onReceivedHttpError: (controller, request, response) {
                  debugPrint(
                    'WebView HTTP error: ${response.statusCode} for ${request.url}',
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimizedView() {
    final theme = Theme.of(context);

    return Positioned(
      bottom: 16,
      left: 16,
      child: GestureDetector(
        onTap: widget.onMinimize, // Toggle back to full view
        child: Container(
          width: 200,
          height: 120,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Preview (frozen WebView)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.article,
                      size: 40,
                      color: theme.iconTheme.color?.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              // Overlay with controls
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Title and close button
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _pageTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Click to expand hint
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Click to expand',
                      style: TextStyle(color: Colors.white, fontSize: 10),
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
