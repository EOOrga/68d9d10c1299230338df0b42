import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');
const String kAppName = 'SCP Operations';
const String kDeveloperName =
    "SOCIETE CIVILE PROFESSIONNELLE D'INFIRMIERS MARTIAL SALABERT - SANDRA RANDO - LAURE AUBERGER";
const String kSupportEmail = 'support@scp-operations.app';

const Color _brandNavy = Color(0xFF153C51);
const Color _brandInk = Color(0xFF031A31);
const Color _brandTeal = Color(0xFF48B3C2);
const Color _brandAmber = Color(0xFFE6A64B);
const Color _brandMint = Color(0xFF2E8F76);
const Color _pageBackground = Color(0xFFF4F8F9);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OperationsApp());
}

class OperationsApp extends StatefulWidget {
  const OperationsApp({super.key, this.controller});

  final OperationsController? controller;

  @override
  State<OperationsApp> createState() => _OperationsAppState();
}

class _OperationsAppState extends State<OperationsApp> {
  late final OperationsController _controller;
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? OperationsController();
    _loadFuture = _controller.load();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _brandNavy,
          brightness: Brightness.light,
        ).copyWith(
          primary: _brandNavy,
          onPrimary: Colors.white,
          secondary: _brandTeal,
          onSecondary: _brandInk,
          tertiary: _brandAmber,
          surface: Colors.white,
          surfaceContainerHighest: const Color(0xFFE5F0F2),
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: kAppName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _pageBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: _pageBackground,
          foregroundColor: _brandInk,
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFD9E6EA)),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide.none,
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: _brandTeal.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD9E6EA)),
          ),
        ),
      ),
      home: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return OperationsScope(
            controller: _controller,
            child: const MainShell(),
          );
        },
      ),
    );
  }
}

class OperationsScope extends InheritedNotifier<OperationsController> {
  const OperationsScope({
    required OperationsController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static OperationsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<OperationsScope>();
    assert(scope != null, 'OperationsScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}

enum RecordKind { resource, maintenance, asset, container }

extension RecordKindDetails on RecordKind {
  String get label {
    switch (this) {
      case RecordKind.resource:
        return 'Resource';
      case RecordKind.maintenance:
        return 'Maintenance';
      case RecordKind.asset:
        return 'Asset';
      case RecordKind.container:
        return 'Container';
    }
  }

  IconData get icon {
    switch (this) {
      case RecordKind.resource:
        return Icons.groups_2_outlined;
      case RecordKind.maintenance:
        return Icons.construction_outlined;
      case RecordKind.asset:
        return Icons.inventory_2_outlined;
      case RecordKind.container:
        return Icons.local_shipping_outlined;
    }
  }
}

class OperationRecord {
  const OperationRecord({
    required this.id,
    required this.kind,
    required this.title,
    required this.owner,
    required this.asset,
    required this.location,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.notes,
    required this.updatedAt,
  });

  final String id;
  final RecordKind kind;
  final String title;
  final String owner;
  final String asset;
  final String location;
  final String status;
  final String priority;
  final DateTime dueDate;
  final String notes;
  final DateTime updatedAt;

  OperationRecord copyWith({
    RecordKind? kind,
    String? title,
    String? owner,
    String? asset,
    String? location,
    String? status,
    String? priority,
    DateTime? dueDate,
    String? notes,
    DateTime? updatedAt,
  }) {
    return OperationRecord(
      id: id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      owner: owner ?? this.owner,
      asset: asset ?? this.asset,
      location: location ?? this.location,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'title': title,
      'owner': owner,
      'asset': asset,
      'location': location,
      'status': status,
      'priority': priority,
      'dueDate': dueDate.toIso8601String(),
      'notes': notes,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory OperationRecord.fromJson(Map<String, Object?> json) {
    final kindName = json['kind'] as String? ?? RecordKind.resource.name;
    return OperationRecord(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      kind: RecordKind.values.firstWhere(
        (kind) => kind.name == kindName,
        orElse: () => RecordKind.resource,
      ),
      title: json['title'] as String? ?? 'Untitled record',
      owner: json['owner'] as String? ?? 'Unassigned',
      asset: json['asset'] as String? ?? 'General',
      location: json['location'] as String? ?? 'Main office',
      status: json['status'] as String? ?? 'Open',
      priority: json['priority'] as String? ?? 'Medium',
      dueDate:
          DateTime.tryParse(json['dueDate'] as String? ?? '') ?? DateTime.now(),
      notes: json['notes'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class OperationsSettings {
  const OperationsSettings({
    required this.handoverCard,
    required this.compactBoard,
    required this.defaultSite,
  });

  final bool handoverCard;
  final bool compactBoard;
  final String defaultSite;

  OperationsSettings copyWith({
    bool? handoverCard,
    bool? compactBoard,
    String? defaultSite,
  }) {
    return OperationsSettings(
      handoverCard: handoverCard ?? this.handoverCard,
      compactBoard: compactBoard ?? this.compactBoard,
      defaultSite: defaultSite ?? this.defaultSite,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'handoverCard': handoverCard,
      'compactBoard': compactBoard,
      'defaultSite': defaultSite,
    };
  }

  factory OperationsSettings.fromJson(Map<String, Object?> json) {
    return OperationsSettings(
      handoverCard: json['handoverCard'] as bool? ?? true,
      compactBoard: json['compactBoard'] as bool? ?? false,
      defaultSite: json['defaultSite'] as String? ?? 'Cabinet principal',
    );
  }

  static const defaults = OperationsSettings(
    handoverCard: true,
    compactBoard: false,
    defaultSite: 'Cabinet principal',
  );
}

class OperationsController extends ChangeNotifier {
  OperationsController({bool screenshotMode = kScreenshotMode})
    : _screenshotMode = screenshotMode,
      _persistenceEnabled = !screenshotMode;

  OperationsController.seeded({
    List<OperationRecord>? records,
    OperationsSettings settings = OperationsSettings.defaults,
  }) : _screenshotMode = false,
       _persistenceEnabled = false,
       _records = records ?? _starterRecords(),
       _settings = settings,
       _loaded = true;

  static const String _recordsKey = 'scp_operations.records.v1';
  static const String _settingsKey = 'scp_operations.settings.v1';

  final bool _screenshotMode;
  final bool _persistenceEnabled;
  SharedPreferences? _preferences;
  List<OperationRecord> _records = const [];
  OperationsSettings _settings = OperationsSettings.defaults;
  bool _loaded = false;

  bool get loaded => _loaded;
  OperationsSettings get settings => _settings;

  List<OperationRecord> get records {
    final sorted = [..._records];
    sorted.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return sorted;
  }

  List<OperationRecord> recordsFor(Set<RecordKind> kinds) {
    return records.where((record) => kinds.contains(record.kind)).toList();
  }

  int countByStatus(String status) {
    return _records.where((record) => record.status == status).length;
  }

  Future<void> load() async {
    if (_loaded) {
      return;
    }

    if (_screenshotMode) {
      _records = _starterRecords();
      _settings = OperationsSettings.defaults;
      _loaded = true;
      notifyListeners();
      return;
    }

    _preferences = await SharedPreferences.getInstance();
    final rawRecords = _preferences?.getString(_recordsKey);
    if (rawRecords == null) {
      _records = _starterRecords();
      await _saveRecords();
    } else {
      final decoded = jsonDecode(rawRecords) as List<dynamic>;
      _records = decoded
          .whereType<Map<String, Object?>>()
          .map(OperationRecord.fromJson)
          .toList();
    }

    final rawSettings = _preferences?.getString(_settingsKey);
    if (rawSettings != null) {
      _settings = OperationsSettings.fromJson(
        jsonDecode(rawSettings) as Map<String, Object?>,
      );
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> addRecord(OperationRecord record) async {
    _records = [..._records, record];
    await _saveRecords();
    notifyListeners();
  }

  Future<void> updateRecord(OperationRecord record) async {
    _records = [
      for (final current in _records)
        if (current.id == record.id) record else current,
    ];
    await _saveRecords();
    notifyListeners();
  }

  Future<void> updateStatus(String id, String status) async {
    _records = [
      for (final record in _records)
        if (record.id == id)
          record.copyWith(status: status, updatedAt: DateTime.now())
        else
          record,
    ];
    await _saveRecords();
    notifyListeners();
  }

  Future<void> updateSettings(OperationsSettings settings) async {
    _settings = settings;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> resetBoard() async {
    _records = _starterRecords();
    await _saveRecords();
    notifyListeners();
  }

  Future<void> _saveRecords() async {
    if (!_persistenceEnabled) {
      return;
    }

    await _preferences?.setString(
      _recordsKey,
      jsonEncode(_records.map((record) => record.toJson()).toList()),
    );
  }

  Future<void> _saveSettings() async {
    if (!_persistenceEnabled) {
      return;
    }

    await _preferences?.setString(_settingsKey, jsonEncode(_settings.toJson()));
  }

  static List<OperationRecord> _starterRecords() {
    final base = DateTime(2026, 5, 12, 9);
    return [
      OperationRecord(
        id: 'rec-resource-north',
        kind: RecordKind.resource,
        title: 'Allocate mobile care team',
        owner: 'Sandra Rando',
        asset: 'Team B / vehicle 07',
        location: 'North sector',
        status: 'Scheduled',
        priority: 'High',
        dueDate: base.add(const Duration(hours: 3)),
        notes: 'Balance afternoon visits after two urgent patient transfers.',
        updatedAt: base,
      ),
      OperationRecord(
        id: 'rec-maintenance-fridge',
        kind: RecordKind.maintenance,
        title: 'Cold storage inspection',
        owner: 'Martial Salabert',
        asset: 'Medical fridge CF-14',
        location: 'Supply room',
        status: 'In progress',
        priority: 'Critical',
        dueDate: base.add(const Duration(hours: 6)),
        notes: 'Temperature drift reported during the morning handover.',
        updatedAt: base.add(const Duration(minutes: 24)),
      ),
      OperationRecord(
        id: 'rec-asset-pumps',
        kind: RecordKind.asset,
        title: 'Infusion pump rotation',
        owner: 'Laure Auberger',
        asset: 'Pumps IP-22 to IP-28',
        location: 'Clinical storage',
        status: 'Open',
        priority: 'Medium',
        dueDate: base.add(const Duration(days: 1)),
        notes: 'Confirm clean, charged, and ready equipment before dispatch.',
        updatedAt: base.add(const Duration(minutes: 48)),
      ),
      OperationRecord(
        id: 'rec-container-sterile',
        kind: RecordKind.container,
        title: 'Sterile kit container return',
        owner: 'Operations desk',
        asset: 'Container ST-310',
        location: 'Outgoing bay',
        status: 'Scheduled',
        priority: 'Medium',
        dueDate: base.add(const Duration(days: 2)),
        notes: 'Track return after route completion and update availability.',
        updatedAt: base.add(const Duration(hours: 1)),
      ),
      OperationRecord(
        id: 'rec-maintenance-tablet',
        kind: RecordKind.maintenance,
        title: 'Field tablet replacement',
        owner: 'Sandra Rando',
        asset: 'Tablet FT-09',
        location: 'South route',
        status: 'Resolved',
        priority: 'Low',
        dueDate: base.subtract(const Duration(hours: 2)),
        notes: 'Replacement prepared; old device marked for internal review.',
        updatedAt: base.add(const Duration(hours: 2)),
      ),
    ];
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _openRecordForm({RecordKind kind = RecordKind.resource}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OperationsScope(
          controller: OperationsScope.of(context),
          child: RecordFormPage(initialKind: kind),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Board', 'Work', 'Assets', 'Settings'];
    final pages = [
      DashboardScreen(
        onOpenWork: () => setState(() => _index = 1),
        onOpenAssets: () => setState(() => _index = 2),
        onCreate: () => _openRecordForm(kind: RecordKind.maintenance),
      ),
      WorkScreen(onCreate: () => _openRecordForm(kind: RecordKind.maintenance)),
      AssetsScreen(onCreate: () => _openRecordForm(kind: RecordKind.asset)),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titles[_index],
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const Text(
              kAppName,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: IndexedStack(index: _index, children: pages),
      ),
      floatingActionButton: _index == 1 || _index == 2
          ? FloatingActionButton.extended(
              tooltip: 'Add operation record',
              onPressed: () => _openRecordForm(
                kind: _index == 2 ? RecordKind.asset : RecordKind.maintenance,
              ),
              icon: const Icon(Icons.add),
              label: const Text('New record'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Board',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Work',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Assets',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.onOpenWork,
    required this.onOpenAssets,
    required this.onCreate,
    super.key,
  });

  final VoidCallback onOpenWork;
  final VoidCallback onOpenAssets;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final controller = OperationsScope.of(context);
    final records = controller.records;
    final openCount =
        controller.countByStatus('Open') +
        controller.countByStatus('In progress');
    final assetCount = controller.recordsFor({RecordKind.asset}).length;
    final containerCount = controller.recordsFor({RecordKind.container}).length;
    final nextRecords = records.take(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _HeroPanel(),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.35,
          children: [
            _MetricCard(
              label: 'Active work',
              value: '$openCount',
              icon: Icons.pending_actions_outlined,
              color: _brandAmber,
            ),
            _MetricCard(
              label: 'Managed assets',
              value: '$assetCount',
              icon: Icons.medical_services_outlined,
              color: _brandMint,
            ),
            _MetricCard(
              label: 'Containers',
              value: '$containerCount',
              icon: Icons.local_shipping_outlined,
              color: _brandTeal,
            ),
            _MetricCard(
              label: 'Due today',
              value:
                  '${records.where((record) => record.dueDate.day == 12).length}',
              icon: Icons.today_outlined,
              color: _brandNavy,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionHeader(
          title: 'Next handover',
          actionLabel: 'Work board',
          onAction: onOpenWork,
        ),
        const SizedBox(height: 8),
        for (final record in nextRecords) ...[
          RecordTile(record: record),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_task_outlined),
          label: const Text('Add maintenance request'),
        ),
        const SizedBox(height: 16),
        _ActionBand(
          title: 'Asset and container control',
          message:
              'Track what is available, where it is assigned, and what needs service before the next route leaves.',
          buttonLabel: 'Open assets',
          icon: Icons.account_tree_outlined,
          onPressed: onOpenAssets,
        ),
      ],
    );
  }
}

class WorkScreen extends StatelessWidget {
  const WorkScreen({required this.onCreate, super.key});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final controller = OperationsScope.of(context);
    final workRecords = controller.recordsFor({
      RecordKind.resource,
      RecordKind.maintenance,
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        _ActionBand(
          title: 'Resource allocation and requests',
          message:
              'Coordinate people, equipment, urgent maintenance, and status updates from one local board.',
          buttonLabel: 'New request',
          icon: Icons.route_outlined,
          onPressed: onCreate,
        ),
        const SizedBox(height: 16),
        const _StatusSummary(),
        const SizedBox(height: 16),
        const _SectionHeader(title: 'Maintenance requests'),
        const SizedBox(height: 8),
        for (final record in workRecords) ...[
          RecordTile(record: record),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class AssetsScreen extends StatelessWidget {
  const AssetsScreen({required this.onCreate, super.key});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final controller = OperationsScope.of(context);
    final records = controller.recordsFor({
      RecordKind.asset,
      RecordKind.container,
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        _ActionBand(
          title: 'Asset and container tracking',
          message:
              'Keep local visibility over equipment readiness, container movements, and service follow-up.',
          buttonLabel: 'Add asset',
          icon: Icons.inventory_2_outlined,
          onPressed: onCreate,
        ),
        const SizedBox(height: 16),
        const _SectionHeader(title: 'Tracked items'),
        const SizedBox(height: 8),
        for (final record in records) ...[
          RecordTile(record: record),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OperationsScope.of(context);
    final settings = controller.settings;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Local workspace',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  settings.defaultSite,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show handover card'),
                  subtitle: const Text(
                    'Keep the daily transfer list visible on the board.',
                  ),
                  value: settings.handoverCard,
                  onChanged: (value) {
                    controller.updateSettings(
                      settings.copyWith(handoverCard: value),
                    );
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Compact board'),
                  subtitle: const Text(
                    'Use tighter record cards for repeated checks.',
                  ),
                  value: settings.compactBoard,
                  onChanged: (value) {
                    controller.updateSettings(
                      settings.copyWith(compactBoard: value),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock_outline),
                    SizedBox(width: 8),
                    Text(
                      'Privacy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Records and preferences stay on this device. The app has no account sign-in, cloud sync, analytics, advertising identifiers, or external service connection.',
                ),
                const SizedBox(height: 12),
                Text('Support: $kSupportEmail'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: kScreenshotMode ? null : () => controller.resetBoard(),
          icon: const Icon(Icons.restore_outlined),
          label: const Text('Restore starter board'),
        ),
      ],
    );
  }
}

class RecordDetailPage extends StatelessWidget {
  const RecordDetailPage({required this.recordId, super.key});

  final String recordId;

  @override
  Widget build(BuildContext context) {
    final controller = OperationsScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final record = controller.records.firstWhere(
          (item) => item.id == recordId,
          orElse: () => controller.records.first,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(record.kind.label),
            actions: [
              IconButton(
                tooltip: 'Edit record',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => OperationsScope(
                        controller: controller,
                        child: RecordFormPage(existing: record),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _KindIcon(kind: record.kind),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _StatusChip(status: record.status),
                                    _PriorityChip(priority: record.priority),
                                    Chip(label: Text(record.kind.label)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _FactRow(label: 'Owner', value: record.owner),
                      _FactRow(label: 'Asset', value: record.asset),
                      _FactRow(label: 'Location', value: record.location),
                      _FactRow(
                        label: 'Due',
                        value: _formatDate(record.dueDate),
                      ),
                      _FactRow(
                        label: 'Updated',
                        value: _formatDateTime(record.updatedAt),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        record.notes,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _SectionHeader(title: 'Update status'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in OperationsValues.statuses)
                    ChoiceChip(
                      label: Text(status),
                      selected: record.status == status,
                      onSelected: (_) =>
                          controller.updateStatus(record.id, status),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class RecordFormPage extends StatefulWidget {
  const RecordFormPage({
    super.key,
    this.initialKind = RecordKind.resource,
    this.existing,
  });

  final RecordKind initialKind;
  final OperationRecord? existing;

  @override
  State<RecordFormPage> createState() => _RecordFormPageState();
}

class _RecordFormPageState extends State<RecordFormPage> {
  final _formKey = GlobalKey<FormState>();
  late RecordKind _kind;
  late String _status;
  late String _priority;
  late final TextEditingController _titleController;
  late final TextEditingController _ownerController;
  late final TextEditingController _assetController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _kind = existing?.kind ?? widget.initialKind;
    _status = existing?.status ?? 'Open';
    _priority = existing?.priority ?? 'Medium';
    _titleController = TextEditingController(text: existing?.title ?? '');
    _ownerController = TextEditingController(text: existing?.owner ?? '');
    _assetController = TextEditingController(text: existing?.asset ?? '');
    _locationController = TextEditingController(text: existing?.location ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _ownerController.dispose();
    _assetController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = OperationsScope.of(context);
    final existing = widget.existing;
    final now = DateTime.now();
    final record = OperationRecord(
      id: existing?.id ?? 'rec-${now.microsecondsSinceEpoch}',
      kind: _kind,
      title: _titleController.text.trim(),
      owner: _ownerController.text.trim().isEmpty
          ? 'Operations desk'
          : _ownerController.text.trim(),
      asset: _assetController.text.trim().isEmpty
          ? 'General equipment'
          : _assetController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? controller.settings.defaultSite
          : _locationController.text.trim(),
      status: _status,
      priority: _priority,
      dueDate: existing?.dueDate ?? now.add(const Duration(days: 1)),
      notes: _notesController.text.trim().isEmpty
          ? 'Record created for local operational follow-up.'
          : _notesController.text.trim(),
      updatedAt: now,
    );

    if (existing == null) {
      await controller.addRecord(record);
    } else {
      await controller.updateRecord(record);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit record' : 'New record')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            DropdownButtonFormField<RecordKind>(
              initialValue: _kind,
              decoration: const InputDecoration(labelText: 'Record type'),
              items: [
                for (final kind in RecordKind.values)
                  DropdownMenuItem(value: kind, child: Text(kind.label)),
              ],
              onChanged: (value) => setState(() => _kind = value ?? _kind),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('titleField'),
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('ownerField'),
              controller: _ownerController,
              decoration: const InputDecoration(labelText: 'Owner'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('assetField'),
              controller: _assetController,
              decoration: const InputDecoration(labelText: 'Asset or resource'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('locationField'),
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: [
                      for (final status in OperationsValues.statuses)
                        DropdownMenuItem(value: status, child: Text(status)),
                    ],
                    onChanged: (value) =>
                        setState(() => _status = value ?? _status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: [
                      for (final priority in OperationsValues.priorities)
                        DropdownMenuItem(
                          value: priority,
                          child: Text(priority),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _priority = value ?? _priority),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('notesField'),
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(isEditing ? 'Save changes' : 'Save record'),
            ),
          ],
        ),
      ),
    );
  }
}

class RecordTile extends StatelessWidget {
  const RecordTile({required this.record, super.key});

  final OperationRecord record;

  @override
  Widget build(BuildContext context) {
    final controller = OperationsScope.of(context);
    final compact = controller.settings.compactBoard;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => OperationsScope(
                controller: controller,
                child: RecordDetailPage(recordId: record.id),
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _KindIcon(kind: record.kind),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${record.asset} - ${record.location}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatusChip(status: record.status),
                          _PriorityChip(priority: record.priority),
                          Chip(
                            avatar: const Icon(Icons.event_outlined, size: 16),
                            label: Text(_formatDate(record.dueDate)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [_brandInk, _brandNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'docs/featured.png',
              fit: BoxFit.cover,
              color: _brandInk.withValues(alpha: 0.68),
              colorBlendMode: BlendMode.srcATop,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Text(
                    'Operations workspace',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Daily resources, assets, maintenance, and containers in one local board.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Built for fast handovers and practical status control without accounts or cloud sync.',
                  style: TextStyle(color: Color(0xFFEAF6F8), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color),
            Text(
              value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSummary extends StatelessWidget {
  const _StatusSummary();

  @override
  Widget build(BuildContext context) {
    final controller = OperationsScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            for (final status in [
              'Open',
              'Scheduled',
              'In progress',
              'Resolved',
            ])
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${controller.countByStatus(status)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionBand extends StatelessWidget {
  const _ActionBand({
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _brandTeal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(height: 1.35)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: onPressed,
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _KindIcon extends StatelessWidget {
  const _KindIcon({required this.kind});

  final RecordKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _brandTeal.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(kind.icon, color: _brandNavy),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Open' => _brandAmber,
      'Scheduled' => _brandTeal,
      'In progress' => _brandNavy,
      'Resolved' => _brandMint,
      _ => Colors.blueGrey,
    };

    return Chip(
      backgroundColor: color.withValues(alpha: 0.14),
      label: Text(
        status,
        style: TextStyle(color: color.darken(), fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final color = priority == 'Critical'
        ? const Color(0xFFC0392B)
        : priority == 'High'
        ? _brandAmber
        : _brandMint;
    return Chip(
      backgroundColor: color.withValues(alpha: 0.12),
      label: Text(
        priority,
        style: TextStyle(color: color.darken(), fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class OperationsValues {
  static const statuses = ['Open', 'Scheduled', 'In progress', 'Resolved'];
  static const priorities = ['Low', 'Medium', 'High', 'Critical'];
}

extension _ColorShade on Color {
  Color darken() {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0)).toColor();
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String _formatDateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${_formatDate(date)} at $hour:$minute';
}
