import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/challenge_store.dart';
import '../data/mulberry.dart';
import '../models/challenge.dart';
import '../models/pictogram_ref.dart';
import '../theme.dart';
import '../widgets/pictogram_view.dart';

const _uuid = Uuid();

/// Create or edit a parent-made challenge. Pictograms can be an emoji (typed)
/// or a real photo (camera/gallery, copied on-device). This is the surface
/// that later becomes the paid "build your own routine" feature.
class BuilderScreen extends StatefulWidget {
  final Challenge? existing;
  const BuilderScreen({super.key, this.existing});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> {
  late final TextEditingController _titleCs;
  late final TextEditingController _titleEn;
  late ChallengeCategory _category;
  late PictogramRef _cover;
  late List<_StepDraft> _steps;
  late final String _id;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _id = e?.id ?? 'custom.${_uuid.v4()}';
    _titleCs = TextEditingController(text: e?.titleCs ?? '');
    _titleEn = TextEditingController(text: e?.titleEn ?? '');
    _category = e?.category ?? ChallengeCategory.routine;
    _cover = e?.cover ?? const PictogramRef.mulberry('star');
    _steps = (e?.steps ?? <ChallengeStep>[])
        .map(_StepDraft.from)
        .toList();
    if (_steps.isEmpty) _steps.add(_StepDraft.blank());
  }

  @override
  void dispose() {
    _titleCs.dispose();
    _titleEn.dispose();
    for (final s in _steps) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCs.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zadej název')));
      return;
    }
    final challenge = Challenge(
      id: _id,
      titleCs: _titleCs.text.trim(),
      titleEn: _titleEn.text.trim(),
      category: _category,
      cover: _cover,
      steps: _steps.map((s) => s.toStep()).toList(),
      builtIn: false,
    );
    await ChallengeStore.instance.upsert(challenge);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await ChallengeStore.instance.delete(_id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Upravit' : 'Nová výzva'),
        actions: [
          if (editing)
            IconButton(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline)),
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _PictogramPicker(
                value: _cover,
                size: 72,
                onChanged: (p) => setState(() => _cover = p),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    TextField(
                      controller: _titleCs,
                      decoration: const InputDecoration(
                          labelText: 'Název (česky)'),
                    ),
                    TextField(
                      controller: _titleEn,
                      decoration: const InputDecoration(
                          labelText: 'Name (English, optional)'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ChallengeCategory>(
            initialValue: _category,
            decoration:
                const InputDecoration(labelText: 'Kategorie'),
            items: ChallengeCategory.values
                .map((c) => DropdownMenuItem(
                    value: c, child: Text(c.labelCs)))
                .toList(),
            onChanged: (v) =>
                setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 24),
          Text('Kroky',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (int i = 0; i < _steps.length; i++)
            _StepEditor(
              key: ValueKey(_steps[i].key),
              index: i,
              draft: _steps[i],
              onChanged: () => setState(() {}),
              onRemove: _steps.length == 1
                  ? null
                  : () => setState(() => _steps.removeAt(i)),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => _steps.add(_StepDraft.blank())),
            icon: const Icon(Icons.add),
            label: const Text('Přidat krok'),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Step editor ──────────────────────────────────────────────
class _StepEditor extends StatelessWidget {
  final int index;
  final _StepDraft draft;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;
  const _StepEditor(
      {super.key,
      required this.index,
      required this.draft,
      required this.onChanged,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                _PictogramPicker(
                  value: draft.pictogram,
                  size: 56,
                  onChanged: (p) {
                    draft.pictogram = p;
                    onChanged();
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: draft.labelCs,
                    decoration: InputDecoration(
                        labelText: 'Krok ${index + 1} (česky)'),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.close)),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<StepKind>(
                    initialValue: draft.kind,
                    decoration:
                        const InputDecoration(labelText: 'Typ'),
                    items: const [
                      DropdownMenuItem(
                          value: StepKind.info,
                          child: Text('Obrázek')),
                      DropdownMenuItem(
                          value: StepKind.countdown,
                          child: Text('Odpočet')),
                      DropdownMenuItem(
                          value: StepKind.timer,
                          child: Text('Časovač')),
                    ],
                    onChanged: (v) {
                      draft.kind = v ?? StepKind.info;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                if (draft.kind == StepKind.countdown)
                  Expanded(
                    child: TextField(
                      controller: draft.count,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Počet'),
                    ),
                  ),
                if (draft.kind == StepKind.timer)
                  Expanded(
                    child: TextField(
                      controller: draft.duration,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Sekundy'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pictogram picker (emoji or photo) ────────────────────────
class _PictogramPicker extends StatelessWidget {
  final PictogramRef value;
  final double size;
  final ValueChanged<PictogramRef> onChanged;
  const _PictogramPicker(
      {required this.value,
      required this.size,
      required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                leading: const Icon(Icons.grid_view_rounded),
                title: const Text('Symbol (Mulberry)'),
                onTap: () => Navigator.pop(ctx, 'symbol')),
            ListTile(
                leading: const Icon(Icons.emoji_emotions_outlined),
                title: const Text('Emoji'),
                onTap: () => Navigator.pop(ctx, 'emoji')),
            ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Vyfotit'),
                onTap: () => Navigator.pop(ctx, 'camera')),
            ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Z galerie'),
                onTap: () => Navigator.pop(ctx, 'gallery')),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    if (choice == 'symbol') {
      final name = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const _SymbolPickerScreen()),
      );
      if (name != null) onChanged(PictogramRef.mulberry(name));
      return;
    }

    if (choice == 'emoji') {
      final emoji = await _askEmoji(context);
      if (emoji != null && emoji.isNotEmpty) {
        onChanged(PictogramRef.emoji(emoji));
      }
      return;
    }

    final picker = ImagePicker();
    final src = choice == 'camera'
        ? ImageSource.camera
        : ImageSource.gallery;
    final XFile? file = await picker.pickImage(
        source: src, maxWidth: 1024, imageQuality: 85);
    if (file == null) return;
    // Copy on-device into app docs dir so it survives the source cache.
    final dir = await getApplicationDocumentsDirectory();
    final dest =
        '${dir.path}/pic_${_uuid.v4()}${_ext(file.path)}';
    await File(file.path).copy(dest);
    onChanged(PictogramRef.photo(dest));
  }

  String _ext(String path) {
    final i = path.lastIndexOf('.');
    return i >= 0 ? path.substring(i) : '.jpg';
  }

  Future<String?> _askEmoji(BuildContext context) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zadej emoji'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: '🪥 ✂️ 🦷 …'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zrušit')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _pick(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: PictogramView(value, size: size * 0.7),
      ),
    );
  }
}

// ── Mulberry symbol picker ───────────────────────────────────
class _SymbolPickerScreen extends StatefulWidget {
  const _SymbolPickerScreen();
  @override
  State<_SymbolPickerScreen> createState() => _SymbolPickerScreenState();
}

class _SymbolPickerScreenState extends State<_SymbolPickerScreen> {
  List<String> _all = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    bundledMulberrySymbols().then((s) {
      if (mounted) setState(() => _all = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _query.isEmpty
        ? _all
        : _all.where((s) => s.contains(_query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Vyber symbol')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Hledat (anglicky): tooth, sock, door…',
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.pop(context, items[i]),
                child: PictogramTile(
                  PictogramRef.mulberry(items[i]),
                  size: 72,
                  tint: Palette.tealTint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Draft holds editable controllers per step ────────────────
class _StepDraft {
  final String key;
  StepKind kind;
  PictogramRef pictogram;
  final TextEditingController labelCs;
  final TextEditingController count;
  final TextEditingController duration;

  _StepDraft({
    required this.key,
    required this.kind,
    required this.pictogram,
    required this.labelCs,
    required this.count,
    required this.duration,
  });

  factory _StepDraft.blank() => _StepDraft(
        key: _uuid.v4(),
        kind: StepKind.info,
        pictogram: const PictogramRef.mulberry('star'),
        labelCs: TextEditingController(),
        count: TextEditingController(text: '10'),
        duration: TextEditingController(text: '60'),
      );

  factory _StepDraft.from(ChallengeStep s) => _StepDraft(
        key: s.id,
        kind: s.kind,
        pictogram: s.pictogram,
        labelCs: TextEditingController(text: s.labelCs),
        count: TextEditingController(text: '${s.count ?? 10}'),
        duration:
            TextEditingController(text: '${s.durationSec ?? 60}'),
      );

  ChallengeStep toStep() => ChallengeStep(
        id: key,
        kind: kind,
        pictogram: pictogram,
        labelCs: labelCs.text.trim(),
        count: kind == StepKind.countdown
            ? int.tryParse(count.text) ?? 10
            : null,
        durationSec: kind == StepKind.timer
            ? int.tryParse(duration.text) ?? 60
            : null,
      );

  void dispose() {
    labelCs.dispose();
    count.dispose();
    duration.dispose();
  }
}
