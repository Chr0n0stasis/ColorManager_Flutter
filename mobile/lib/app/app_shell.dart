import 'package:flutter/material.dart';

class ColorManagerMobileApp extends StatelessWidget {
  const ColorManagerMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ColorManager Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: const MainResponsiveScaffold(),
    );
  }
}

class MainResponsiveScaffold extends StatefulWidget {
  const MainResponsiveScaffold({super.key});

  @override
  State<MainResponsiveScaffold> createState() => _MainResponsiveScaffoldState();
}

class _MainResponsiveScaffoldState extends State<MainResponsiveScaffold> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 1100;

    if (isWide) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ColorManager Mobile'),
          centerTitle: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                SizedBox(width: 300, child: _MaterialsPane()),
                SizedBox(width: 12),
                Expanded(child: _DetailPane()),
                SizedBox(width: 12),
                SizedBox(width: 360, child: _ComposePreviewPane()),
              ],
            ),
          ),
        ),
      );
    }

    final pages = const [
      _MaterialsPane(),
      _DetailPane(),
      _ComposePreviewPane(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ColorManager Mobile'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_open_outlined),
            selectedIcon: Icon(Icons.folder_open),
            label: 'Materials',
          ),
          NavigationDestination(
            icon: Icon(Icons.palette_outlined),
            selectedIcon: Icon(Icons.palette),
            label: 'Detail',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_graph_outlined),
            selectedIcon: Icon(Icons.auto_graph),
            label: 'Compose',
          ),
        ],
      ),
    );
  }
}

class _MaterialsPane extends StatelessWidget {
  const _MaterialsPane();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Materials / Library',
      subtitle: 'Layout anchor: left pane (filters, tree, search)',
      child: ListView(
        children: const [
          _HintTile('Tree and grouping list placeholder'),
          _HintTile('Filter chips placeholder'),
          _HintTile('Search and sort controls placeholder'),
        ],
      ),
    );
  }
}

class _DetailPane extends StatelessWidget {
  const _DetailPane();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Palette Detail',
      subtitle: 'Layout anchor: center pane (preview, color cards, extraction)',
      child: ListView(
        children: const [
          _HintTile('Image/PDF preview placeholder'),
          _HintTile('Color card flow placeholder'),
          _HintTile('PDF extraction entry placeholder'),
        ],
      ),
    );
  }
}

class _ComposePreviewPane extends StatelessWidget {
  const _ComposePreviewPane();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Compose & Preview',
      subtitle: 'Layout anchor: right pane (cart, generation, chart preview)',
      child: ListView(
        children: const [
          _HintTile('Selected colors cart placeholder'),
          _HintTile('Color generation controls placeholder'),
          _HintTile('Chart preview placeholder'),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _HintTile extends StatelessWidget {
  const _HintTile(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.chevron_right),
      title: Text(text),
    );
  }
}
