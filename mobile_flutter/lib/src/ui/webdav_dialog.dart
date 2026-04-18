import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import '../i18n/app_localizations.dart';

class WebDAVFilePickerDialog extends StatefulWidget {
  const WebDAVFilePickerDialog({
    super.key,
    required this.url,
    required this.username,
    required this.password,
  });

  final String url;
  final String username;
  final String password;

  @override
  State<WebDAVFilePickerDialog> createState() => _WebDAVFilePickerDialogState();
}

class _WebDAVFilePickerDialogState extends State<WebDAVFilePickerDialog> {
  late webdav.Client _client;
  bool _isLoading = true;
  String _currentPath = '/';
  List<webdav.File> _files = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _client = webdav.newClient(
      widget.url,
      user: widget.username,
      password: widget.password,
    );
    _loadDirectory(_currentPath);
  }

  Future<void> _loadDirectory(String path) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPath = path;
    });

    try {
      await _client.ping();
      final items = await _client.readDir(path);
      if (mounted) {
        setState(() {
          _files = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '${context.tr('Connect failed')}: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTap(webdav.File item) async {
    if (item.isDir == true) {
      _loadDirectory(item.path ?? '/');
    } else {
      if (item.name == null || item.path == null) return;
      setState(() {
        _isLoading = true;
        _error = context.tr('Downloading {file}...', params: <String, String>{'file': item.name!});
      });
      try {
        final List<int> bytes = await _client.read(item.path!);
        if (mounted) {
          Navigator.of(context).pop((item.name!, Uint8List.fromList(bytes)));
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = '${context.tr('Download failed')}: $e';
            _isLoading = false;
          });
        }
      }
    }
  }

  void _goUp() {
    if (_currentPath == '/' || _currentPath.isEmpty) return;
    
    var segments = _currentPath.split('/');
    segments.removeWhere((s) => s.isEmpty);
    if (segments.isNotEmpty) {
      segments.removeLast();
    }
    final newPath = segments.isEmpty ? '/' : '/${segments.join('/')}/';
    _loadDirectory(newPath);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('Cloud Storage')),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                color: Theme.of(context).colorScheme.errorContainer,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                ),
              ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator())),
            if (!_isLoading && _files.isEmpty)
              const Expanded(child: Center(child: Text('No files found'))),
            if (!_isLoading && _files.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _files.length + (_currentPath != '/' ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_currentPath != '/' && index == 0) {
                      return ListTile(
                        leading: const Icon(Icons.folder_open),
                        title: const Text('.. (Up)'),
                        onTap: _goUp,
                      );
                    }
                    
                    final idx = _currentPath != '/' ? index - 1 : index;
                    final file = _files[idx];
                    
                    return ListTile(
                      leading: Icon(file.isDir == true ? Icons.folder : Icons.insert_drive_file),
                      title: Text(file.name ?? 'Unknown'),
                      onTap: () => _onItemTap(file),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('Cancel')),
        ),
      ],
    );
  }
}
