import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activation_provider.dart';
import 'admin_keys_screen.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _keyController = TextEditingController();

  AnimationController? _animationController;
  AnimationController? _pulseController;
  Animation<double>? _fadeAnimation;
  Animation<double>? _scaleAnimation;
  Animation<double>? _pulseAnimation;

  bool _isActivating = false;
  bool _isDisposed = false;
  int _logoTapCount = 0;
  DateTime? _lastTapTime;

  static const String _adminAccessCode = '##ADMIN##';
  static const String _alternativeAdminCode = 'ADMIN2025';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.elasticOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController!,
        curve: Curves.easeInOut,
      ),
    );

    _animationController!.forward();
    _pulseController!.repeat(reverse: true);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _keyController.dispose();
    _animationController?.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceId = windowsInfo.deviceId;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        deviceId = linuxInfo.machineId ?? '';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        deviceId = macInfo.systemGUID ?? '';
      } else {
        deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      }

      final bytes = utf8.encode(deviceId);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  Future<void> _activateApp() async {
    if (_isDisposed || !mounted) return;

    final enteredKey = _keyController.text.trim();

    if (enteredKey.isEmpty) {
      _showSnackBar('Veuillez entrer une clé d\'activation', isError: true);
      return;
    }

    if (enteredKey == _adminAccessCode || enteredKey == _alternativeAdminCode) {
      _keyController.clear();
      await _showAdminPinDialog();
      return;
    }

    if (!mounted || _isDisposed) return;

    setState(() {
      _isActivating = true;
    });

    try {
      final deviceId = await getDeviceId();

      if (!mounted || _isDisposed) return;

      final provider = context.read<ActivationProvider>();
      final success = await provider.activate(enteredKey, deviceId);

      if (!mounted || _isDisposed) return;

      setState(() {
        _isActivating = false;
      });

      if (success) {
        _showSnackBar('Activation réussie! Bienvenue!');

        await Future.delayed(const Duration(milliseconds: 100));

        if (!mounted || _isDisposed) return;

        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else {
        final error = provider.errorMessage;
        _showSnackBar(
          error.isNotEmpty ? error : 'Échec de l\'activation',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;

      setState(() {
        _isActivating = false;
      });

      _showSnackBar('Erreur lors de l\'activation', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted || _isDisposed) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _showAdminPinDialog() async {
    if (!mounted || _isDisposed) return;

    final pinController = TextEditingController();
    bool obscurePin = true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Color(0xFF6366F1)),
              SizedBox(width: 12),
              Text('Accès Administrateur'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Entrez le code PIN administrateur pour accéder à la gestion des clés.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                decoration: InputDecoration(
                  labelText: 'Code PIN',
                  hintText: '••••••',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePin ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscurePin = !obscurePin;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                obscureText: obscurePin,
                maxLength: 4,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pin = pinController.text.trim();
                if (pin.isEmpty) {
                  return;
                }

                if (!mounted) return;

                final provider = Provider.of<ActivationProvider>(
                  context,
                  listen: false,
                );

                final isValid = await provider.verifyAdminPin(pin);

                await Future.delayed(const Duration(milliseconds: 50));

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, isValid);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 100));
    pinController.dispose();

    if (!mounted || _isDisposed) return;

    if (result == true) {
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted || _isDisposed) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminKeysScreen(),
        ),
      );
    } else if (result == false) {
      _showSnackBar('Code PIN incorrect', isError: true);
    }
  }

  void _handleLogoTap() {
    if (_isDisposed || !mounted) return;

    final now = DateTime.now();

    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _logoTapCount = 0;
    }

    _lastTapTime = now;
    _logoTapCount++;

    if (_logoTapCount >= 5) {
      _logoTapCount = 0;
      _showAdminPinDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_fadeAnimation == null || _scaleAnimation == null || _pulseAnimation == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final double topSpacing = screenHeight * 0.05;
    final double logoSize = screenWidth * 0.25 > 120 ? 120 : screenWidth * 0.25;
    final double verticalSpacing = screenHeight * 0.03;
    final double horizontalPadding = screenWidth * 0.08 > 32 ? 32 : screenWidth * 0.08;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.grey[50],
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation!,
          child: ScaleTransition(
            scale: _scaleAnimation!,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: topSpacing),

                          Center(
                            child: GestureDetector(
                              onTap: _handleLogoTap,
                              child: ScaleTransition(
                                scale: _pulseAnimation!,
                                child: Container(
                                  width: logoSize,
                                  height: logoSize,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF8B5CF6),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6366F1)
                                            .withOpacity(0.3),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.security_rounded,
                                    size: logoSize * 0.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: verticalSpacing * 1.5),

                          Text(
                            'Activation requise',
                            style: TextStyle(
                              fontSize: screenWidth < 360 ? 26 : 32,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: verticalSpacing * 0.4),

                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                            ),
                            child: Text(
                              'Entrez votre clé d\'activation pour débloquer toutes les fonctionnalités',
                              style: TextStyle(
                                fontSize: screenWidth < 360 ? 14 : 16,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          SizedBox(height: verticalSpacing * 1.5),

                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _keyController,
                              decoration: InputDecoration(
                                labelText: 'Clé d\'activation',
                                hintText: 'SERIAL:SIGNATURE',
                                prefixIcon: const Icon(Icons.vpn_key_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF1A1A1A)
                                    : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              textCapitalization: TextCapitalization.characters,
                              onSubmitted: (_) => _activateApp(),
                            ),
                          ),

                          SizedBox(height: verticalSpacing),

                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF8B5CF6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1)
                                      .withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isActivating ? null : _activateApp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isActivating
                                  ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                                  : Text(
                                'Activer l\'application',
                                style: TextStyle(
                                  fontSize: screenWidth < 360 ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: verticalSpacing),

                          Consumer<ActivationProvider>(
                            builder: (context, provider, _) {
                              if (provider.errorMessage.isNotEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFEF4444)
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xFFEF4444),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          provider.errorMessage,
                                          style: TextStyle(
                                            color: const Color(0xFFEF4444),
                                            fontWeight: FontWeight.w500,
                                            fontSize:
                                            screenWidth < 360 ? 13 : 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),

                          SizedBox(height: topSpacing),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}