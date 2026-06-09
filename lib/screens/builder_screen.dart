import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/challenge_store.dart';
import '../data/lang_store.dart';
import '../data/mulberry.dart';
import '../design/spectrum.dart';
import '../models/challenge.dart';
import '../models/pictogram_ref.dart';
import '../theme.dart';
import '../widgets/pictogram_view.dart';

const _uuid = Uuid();

class BuilderScreen extends StatefulWidget {
  final Challenge? existing;
  const BuilderScreen({super.key, this.existing});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> {
  late final TextEditingController _title;
  late ChallengeCategory _category;
  late PictogramRef _cover;
  late List<_StepDraft> _steps;
  late final String _id;

  String get _lang => LangStore.instance.lang;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _id = e?.id ?? 'custom.${_uuid.v4()}';
    _title = TextEditingController(text: e?.titleCs ?? '');
    _category = e?.category ?? ChallengeCategory.routine;
    _cover = e?.cover ?? const PictogramRef.mulberry('star');
    _steps = (e?.steps ?? <ChallengeStep>[]).map(_StepDraft.from).toList();
    if (_steps.isEmpty) _steps.add(_StepDraft.blank());
  }

  @override
  void dispose() {
    _title.dispose();
    for (final s in _steps) { s.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_lang == 'en' ? 'Enter a title' : 'Zadej název'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final t = _title.text.trim();
    final challenge = Challenge(
      id: _id,
      titleCs: t,
      titleEn: t,
      category: _category,
      cover: _cover,
      steps: _steps.map((s) => s.toStep()).toList(),
      builtIn: false,
    );
    await ChallengeStore.instance.upsert(challenge);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_lang == 'en' ? 'Delete?' : 'Smazat?'),
        content: Text(_lang == 'en'
            ? 'This challenge will be permanently deleted.'
            : 'Tato výzva bude trvale smazána.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_lang == 'en' ? 'Cancel' : 'Zrušit')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text(_lang == 'en' ? 'Delete' : 'Smazat')),
        ],
      ),
    );
    if (ok == true) {
      await ChallengeStore.instance.delete(_id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    final accent = Spectrum.accent(_category);
    return Scaffold(
      backgroundColor: Spectrum.bg,
      appBar: AppBar(
        title: Text(editing
            ? (_lang == 'en' ? 'Edit challenge' : 'Upravit výzvu')
            : (_lang == 'en' ? 'New challenge' : 'Nová výzva')),
        actions: [
          if (editing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: Colors.redAccent,
              onPressed: _confirmDelete,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                minimumSize: const Size(72, 40),
                textStyle: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
              child: Text(_lang == 'en' ? 'Save' : 'Uložit'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.md, 120),
        children: [
          // ── Cover + title ────────────────────────────────────
          _Card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _PictogramPicker(
                  value: _cover,
                  size: 84,
                  tint: Spectrum.accentTint(_category),
                  onChanged: (p) => setState(() => _cover = p),
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: TextField(
                    controller: _title,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3),
                    decoration: InputDecoration(
                      hintText: _lang == 'en'
                          ? 'Challenge name…'
                          : 'Název výzvy…',
                      hintStyle: const TextStyle(
                          color: Spectrum.inkSoft,
                          fontWeight: FontWeight.normal),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.sm),
          // ── Category chips ────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label(_lang == 'en' ? 'Category' : 'Kategorie'),
                const SizedBox(height: Gap.sm),
                Row(
                  children: [
                    for (int i = 0;
                        i < ChallengeCategory.values.length;
                        i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _CategoryChip(
                          label: ChallengeCategory.values[i]
                              .label(_lang),
                          color: Spectrum.accent(
                              ChallengeCategory.values[i]),
                          selected:
                              _category == ChallengeCategory.values[i],
                          onTap: () => setState(() =>
                              _category = ChallengeCategory.values[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.md),
          // ── Steps header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text(
                  _lang == 'en' ? 'Steps' : 'Kroky',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3),
                ),
                const SizedBox(width: 8),
                Text('${_steps.length}',
                    style: const TextStyle(color: Spectrum.inkSoft)),
              ],
            ),
          ),
          const SizedBox(height: Gap.sm),
          // ── Step cards ────────────────────────────────────────
          for (int i = 0; i < _steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.sm),
              child: _StepEditor(
                key: ValueKey(_steps[i].key),
                index: i,
                draft: _steps[i],
                lang: _lang,
                accent: accent,
                onChanged: () => setState(() {}),
                onRemove: _steps.length == 1
                    ? null
                    : () => setState(() => _steps.removeAt(i)),
              ),
            ),
          // ── Add step ──────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _steps.add(_StepDraft.blank())),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Spectrum.accentTint(_category),
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(
                    color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: accent, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    _lang == 'en' ? 'Add step' : 'Přidat krok',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: accent),
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

// ── Shared card shell ────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Spectrum.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        boxShadow: [
          BoxShadow(
              color: Spectrum.ink.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Padding(
          padding: const EdgeInsets.all(Gap.md), child: child),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: Spectrum.inkSoft),
      );
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(
            color: selected
                ? color
                : Spectrum.inkSoft.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? color : Spectrum.inkSoft),
        ),
      ),
    );
  }
}

// ── Step editor ──────────────────────────────────────────────

class _StepEditor extends StatelessWidget {
  final int index;
  final _StepDraft draft;
  final String lang;
  final Color accent;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;
  const _StepEditor({
    super.key,
    required this.index,
    required this.draft,
    required this.lang,
    required this.accent,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Spectrum.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        boxShadow: [
          BoxShadow(
              color: Spectrum.ink.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('${index + 1}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accent)),
                ),
                const SizedBox(width: Gap.sm),
                _PictogramPicker(
                  value: draft.pictogram,
                  size: 64,
                  tint: accent.withValues(alpha: 0.1),
                  onChanged: (p) {
                    draft.pictogram = p;
                    onChanged();
                  },
                ),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: TextField(
                    controller: draft.labelCs,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: lang == 'en'
                          ? 'Step label…'
                          : 'Název kroku…',
                      hintStyle: const TextStyle(
                          color: Spectrum.inkSoft),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                ),
                if (onRemove != null)
                  GestureDetector(
                    onTap: onRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: Spectrum.inkSoft),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Gap.sm),
            _KindPills(
              selected: draft.kind,
              lang: lang,
              onSelect: (k) {
                draft.kind = k;
                onChanged();
              },
            ),
            if (draft.kind == StepKind.countdown)
              Padding(
                padding: const EdgeInsets.only(top: Gap.sm),
                child: _NumberField(
                  controller: draft.count,
                  label: lang == 'en' ? 'Count' : 'Počet',
                  accent: accent,
                ),
              ),
            if (draft.kind == StepKind.timer)
              Padding(
                padding: const EdgeInsets.only(top: Gap.sm),
                child: _NumberField(
                  controller: draft.duration,
                  label: lang == 'en' ? 'Seconds' : 'Sekundy',
                  accent: accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KindPills extends StatelessWidget {
  final StepKind selected;
  final String lang;
  final ValueChanged<StepKind> onSelect;
  const _KindPills(
      {required this.selected,
      required this.lang,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final opts = <(StepKind, String, Color)>[
      (
        StepKind.info,
        lang == 'en' ? 'Picture' : 'Obrázek',
        Spectrum.sky
      ),
      (
        StepKind.countdown,
        lang == 'en' ? 'Count' : 'Odpočet',
        Spectrum.amber
      ),
      (
        StepKind.timer,
        lang == 'en' ? 'Timer' : 'Časovač',
        Spectrum.mint
      ),
    ];
    return Row(
      children: [
        for (int i = 0; i < opts.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _Pill(
              label: opts[i].$2,
              color: opts[i].$3,
              selected: selected == opts[i].$1,
              onTap: () => onSelect(opts[i].$1),
            ),
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _Pill(
      {required this.label,
      required this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : Spectrum.bg,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(
            color: selected
                ? color
                : Spectrum.inkSoft.withValues(alpha: 0.18),
            width: selected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? color : Spectrum.inkSoft),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color accent;
  const _NumberField(
      {required this.controller,
      required this.label,
      required this.accent});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(
          fontSize: 15,
          color: accent,
          fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: Spectrum.inkSoft, fontSize: 13),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide:
              BorderSide(color: accent.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide:
              BorderSide(color: accent.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}

// ── Pictogram picker ─────────────────────────────────────────

class _PictogramPicker extends StatelessWidget {
  final PictogramRef value;
  final double size;
  final Color tint;
  final ValueChanged<PictogramRef> onChanged;
  const _PictogramPicker({
    required this.value,
    required this.size,
    required this.tint,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Spectrum.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(Radii.lg))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text('Vyber obrázek',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ),
            ListTile(
                leading:
                    const Icon(Icons.grid_view_rounded),
                title: const Text('Symbol (Mulberry)'),
                onTap: () =>
                    Navigator.pop(ctx, 'symbol')),
            ListTile(
                leading:
                    const Icon(Icons.emoji_emotions_outlined),
                title: const Text('Emoji'),
                onTap: () =>
                    Navigator.pop(ctx, 'emoji')),
            ListTile(
                leading:
                    const Icon(Icons.photo_camera_outlined),
                title: const Text('Vyfotit'),
                onTap: () =>
                    Navigator.pop(ctx, 'camera')),
            ListTile(
                leading:
                    const Icon(Icons.photo_library_outlined),
                title: const Text('Z galerie'),
                onTap: () =>
                    Navigator.pop(ctx, 'gallery')),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    if (choice == 'symbol') {
      final name = await Navigator.push<String>(
        context,
        MaterialPageRoute(
            builder: (_) => const _SymbolPickerScreen()),
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
          decoration: const InputDecoration(
              hintText: '🪥 ✂️ 🦷 …'),
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
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        alignment: Alignment.center,
        child: PictogramView(value, size: size * 0.68),
      ),
    );
  }
}

// ── Mulberry symbol picker ───────────────────────────────────

class _SymbolPickerScreen extends StatefulWidget {
  const _SymbolPickerScreen();
  @override
  State<_SymbolPickerScreen> createState() =>
      _SymbolPickerScreenState();
}

class _SymbolPickerScreenState
    extends State<_SymbolPickerScreen> {
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
        : _all
            .where((s) => s.contains(_query.toLowerCase()))
            .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Vyber symbol')),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText:
                    'Hledat (anglicky): tooth, sock, door…',
              ),
              onChanged: (v) =>
                  setState(() => _query = v.trim()),
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
                borderRadius:
                    BorderRadius.circular(20),
                onTap: () =>
                    Navigator.pop(context, items[i]),
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

// ── Step draft ───────────────────────────────────────────────

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
        count: TextEditingController(
            text: '${s.count ?? 10}'),
        duration: TextEditingController(
            text: '${s.durationSec ?? 60}'),
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
