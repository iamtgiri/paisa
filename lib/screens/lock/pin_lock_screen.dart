import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_prefs.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';

/// Shown on app launch when a PIN is set. Also used for setting/changing PIN.
class PinLockScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;
  const PinLockScreen({super.key, this.onUnlocked});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  String _entered = '';
  bool _shake = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
    _shakeCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _shakeCtrl.reverse();
        setState(() {
          _entered = '';
          _shake = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onDigit(String d) {
    if (_entered.length >= 4) return;
    setState(() => _entered += d);
    if (_entered.length == 4) {
      Future.delayed(const Duration(milliseconds: 100), _verify);
    }
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _verify() {
    if (AppPrefs.instance.verifyPin(_entered)) {
      widget.onUnlocked?.call();
    } else {
      setState(() => _shake = true);
      _shakeCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 30, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            Text('Enter PIN',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.onSurface)),
            const SizedBox(height: 6),
            Text('Unlock Paisa',
                style: TextStyle(
                    fontSize: 13, color: context.appColors.onSurfaceMuted)),
            const SizedBox(height: 40),
            // Dot indicators
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shake ? _shakeAnim.value : 0, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _entered.length;
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? (_shake ? AppTheme.expense : AppTheme.primary)
                          : context.appColors.surfaceCard2,
                      border: Border.all(
                        color: filled
                            ? Colors.transparent
                            : context.appColors.divider,
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 48),
            // Number pad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _numRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _numRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _numRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 72), // empty slot
                      _digitBtn('0'),
                      _deleteBtn(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_digitBtn).toList(),
    );
  }

  Widget _digitBtn(String digit) {
    return GestureDetector(
      onTap: () => _onDigit(digit),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: context.appColors.surfaceCard,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: context.appColors.onSurface),
          ),
        ),
      ),
    );
  }

  Widget _deleteBtn() {
    return GestureDetector(
      onTap: _onDelete,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: context.appColors.surfaceCard,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(Icons.backspace_outlined,
              size: 22, color: context.appColors.onSurfaceMuted),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PIN SETUP SCREEN — used from Settings
// ═══════════════════════════════════════════════════════════════
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  // Two-step: first enter new PIN, then confirm
  String _first = '';
  String _confirm = '';
  bool _confirming = false;
  bool _shake = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 12)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    _shakeCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _shakeCtrl.reverse();
        setState(() {
          _confirm = '';
          _shake = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  String get _current => _confirming ? _confirm : _first;

  void _onDigit(String d) {
    if (_current.length >= 4) return;
    if (_confirming) {
      setState(() => _confirm += d);
      if (_confirm.length == 4) {
        Future.delayed(const Duration(milliseconds: 100), _handleConfirm);
      }
    } else {
      setState(() => _first += d);
      if (_first.length == 4) {
        Future.delayed(const Duration(milliseconds: 150), () {
          setState(() => _confirming = true);
        });
      }
    }
  }

  void _onDelete() {
    if (_confirming) {
      if (_confirm.isEmpty) return;
      setState(() => _confirm = _confirm.substring(0, _confirm.length - 1));
    } else {
      if (_first.isEmpty) return;
      setState(() => _first = _first.substring(0, _first.length - 1));
    }
  }

  Future<void> _handleConfirm() async {
    if (_first == _confirm) {
      await AppPrefs.instance.setPin(_first);
      ref.read(pinStateProvider.notifier).state = _first;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN set successfully')));
        Navigator.pop(context, true);
      }
    } else {
      setState(() => _shake = true);
      _shakeCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _confirming ? 'Confirm your PIN' : 'Set a new PIN';
    final sub = _confirming ? 'Enter your PIN again' : 'Choose a 4-digit PIN';
    final displayed = _confirming ? _confirm : _first;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        title: const Text('Set PIN'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Container(
                key: ValueKey(_confirming),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  _confirming
                      ? Icons.check_circle_outline
                      : Icons.lock_open_outlined,
                  size: 28,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(label,
                  key: ValueKey(label),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.onSurface)),
            ),
            const SizedBox(height: 6),
            Text(sub,
                style: TextStyle(
                    fontSize: 13, color: context.appColors.onSurfaceMuted)),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) => Transform.translate(
                offset: Offset(_shake ? _shakeAnim.value : 0, 0),
                child: child,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < displayed.length;
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? (_shake ? AppTheme.expense : AppTheme.primary)
                          : context.appColors.surfaceCard2,
                      border: Border.all(
                        color: filled
                            ? Colors.transparent
                            : context.appColors.divider,
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _numRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _numRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _numRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 72),
                      _digitBtn('0'),
                      _deleteBtn(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numRow(List<String> digits) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: digits.map(_digitBtn).toList(),
      );

  Widget _digitBtn(String digit) => GestureDetector(
        onTap: () => _onDigit(digit),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
              color: context.appColors.surfaceCard, shape: BoxShape.circle),
          child: Center(
            child: Text(digit,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.onSurface)),
          ),
        ),
      );

  Widget _deleteBtn() => GestureDetector(
        onTap: _onDelete,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
              color: context.appColors.surfaceCard, shape: BoxShape.circle),
          child: Center(
            child: Icon(Icons.backspace_outlined,
                size: 22, color: context.appColors.onSurfaceMuted),
          ),
        ),
      );
}
