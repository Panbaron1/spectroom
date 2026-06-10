import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../design/spectrum.dart';
import '../theme.dart';

enum _PinMode { auth, setup }

/// Auth: returns true if correct PIN entered.
Future<bool> showPinAuth(BuildContext context, String existingPin) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (_) => _PinDialog(mode: _PinMode.auth, existingPin: existingPin),
  ).then((v) => v ?? false);
}

/// Setup: returns the new PIN string, or null if cancelled.
Future<String?> showPinSetup(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (_) => const _PinDialog(mode: _PinMode.setup),
  );
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.mode, this.existingPin});
  final _PinMode mode;
  final String? existingPin;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog>
    with SingleTickerProviderStateMixin {
  static const _len = 4;
  String _entered = '';
  String? _firstPin; // setup step 1 capture
  String? _error;
  bool _isConfirmStep = false;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.mode == _PinMode.auth) return 'Enter PIN';
    return _isConfirmStep ? 'Confirm PIN' : 'Set PIN';
  }

  void _tap(String digit) {
    if (_entered.length >= _len) return;
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length == _len) _submit();
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _submit() async {
    if (widget.mode == _PinMode.auth) {
      if (_entered == widget.existingPin) {
        Navigator.of(context).pop(true);
        return;
      }
      await _shakeCtrl.forward(from: 0);
      setState(() {
        _entered = '';
        _error = 'Wrong PIN';
      });
      return;
    }

    // Setup mode
    if (!_isConfirmStep) {
      setState(() {
        _firstPin = _entered;
        _entered = '';
        _isConfirmStep = true;
      });
      return;
    }

    if (_entered == _firstPin) {
      Navigator.of(context).pop(_entered); // caller receives PIN string
      return;
    }

    await _shakeCtrl.forward(from: 0);
    setState(() {
      _firstPin = null;
      _entered = '';
      _isConfirmStep = false;
      _error = 'PINs didn\'t match, try again';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) =>
            Transform.translate(offset: Offset(_shakeAnim.value, 0), child: child),
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Spectrum.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Spectrum.ink.withOpacity(0.18),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_title,
                  style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Spectrum.ink)),
              const SizedBox(height: 6),
              if (_error != null) ...[
                Text(_error!,
                    style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        color: Spectrum.coral)),
                const SizedBox(height: 4),
              ] else
                const SizedBox(height: 4),
              const SizedBox(height: 12),
              _Dots(entered: _entered.length, total: _len),
              const SizedBox(height: 24),
              _Numpad(onDigit: _tap, onBackspace: _backspace),
              const SizedBox(height: 8),
              if (widget.mode == _PinMode.auth)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 14,
                          color: Spectrum.inkSoft)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.entered, required this.total});
  final int entered;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final filled = i < entered;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? Spectrum.lavender : Colors.transparent,
              border: Border.all(
                color: filled ? Spectrum.lavender : Spectrum.inkSoft,
                width: 2,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _Numpad extends StatelessWidget {
  const _Numpad({required this.onDigit, required this.onBackspace});
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 72);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _Key(
                  label: key,
                  onTap: key == '⌫' ? onBackspace : () => onDigit(key),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  bool get _isBack => label == '⌫';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 64,
        height: 56,
        decoration: BoxDecoration(
          color: _isBack ? Colors.transparent : Spectrum.surface,
          borderRadius: BorderRadius.circular(14),
          border: _isBack
              ? null
              : Border.all(color: Spectrum.inkSoft.withOpacity(0.2), width: 1),
          boxShadow: _isBack
              ? null
              : [
                  BoxShadow(
                    color: Spectrum.ink.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: _isBack ? 20 : 22,
            fontWeight: FontWeight.w600,
            color: _isBack ? Spectrum.inkSoft : Spectrum.ink,
          ),
        ),
      ),
    );
  }
}
