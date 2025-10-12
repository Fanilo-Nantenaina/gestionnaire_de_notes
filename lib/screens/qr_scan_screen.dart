import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gestionnaire_de_notes/models/note.dart';
import 'package:gestionnaire_de_notes/utils/error_messages.dart';
import 'package:gestionnaire_de_notes/utils/permission_handler.dart';
import 'package:gestionnaire_de_notes/widgets/custom_snackbar.dart';
import 'package:gestionnaire_de_notes/widgets/loading_overlay.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _isTorchOn = false;
  bool _permissionDenied = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCameraPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && _permissionDenied) {
      _checkCameraPermission();
    }
  }

  Future<void> _checkCameraPermission() async {
    if (!mounted) return;

    setState(() {
      _isCheckingPermission = true;
    });

    final hasPermission = await PermissionHelper.requestCameraPermission(context);

    if (!mounted) return;

    setState(() {
      _permissionDenied = !hasPermission;
      _isCheckingPermission = false;
    });

    if (!hasPermission) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Note? _parseQrCode(String code) {
    try {
      final Map<String, dynamic> json = jsonDecode(code);

      if (!json.containsKey('id') ||
          !json.containsKey('title') ||
          !json.containsKey('content')) {
        return null;
      }

      return Note.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || _permissionDenied) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) {
      CustomSnackBar.showError(
        context,
        ErrorMessages.getSharingError('INVALID_QR_DATA'),
      );
      return;
    }

    setState(() => _isProcessing = true);

    LoadingOverlay.show(context, message: 'Importation en cours...');

    try {
      final note = _parseQrCode(code);

      if (note != null && mounted) {
        LoadingOverlay.hide();
        CustomSnackBar.showSuccess(
          context,
          ErrorMessages.getSuccessMessage('NOTE_SHARED'),
        );
        Navigator.pop(context, note);
      } else {
        if (mounted) {
          LoadingOverlay.hide();
          CustomSnackBar.showError(
            context,
            ErrorMessages.getSharingError('INVALID_QR_DATA'),
          );
          setState(() => _isProcessing = false);
        }
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.hide();
        CustomSnackBar.showError(
          context,
          ErrorMessages.getSharingError('QR_SCAN_FAILED'),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Scanner un QR Code'),
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6366F1),
          ),
        ),
      );
    }

    if (_permissionDenied) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Scanner un QR Code'),
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 80,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 24),
                Text(
                  'Permission caméra requise',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Veuillez autoriser l\'accès à la caméra dans les paramètres',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scanner un QR Code'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),

          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    _isProcessing ? Icons.check_circle : Icons.qr_code_scanner,
                    color: _isProcessing ? const Color(0xFF10B981) : Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isProcessing
                        ? 'Traitement en cours...'
                        : 'Placez le QR code dans le cadre',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                onPressed: () {
                  _controller.toggleTorch();
                  setState(() => _isTorchOn = !_isTorchOn);
                },
                icon: Icon(
                  _isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 32,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 280,
      height: 280,
    );

    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(16)))
        ..fillType = PathFillType.evenOdd,
      paint,
    );

    final borderPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanArea, const Radius.circular(16)),
      borderPaint,
    );

    final cornerPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;

    canvas.drawLine(
      Offset(scanArea.left, scanArea.top),
      Offset(scanArea.left + cornerLength, scanArea.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.left, scanArea.top),
      Offset(scanArea.left, scanArea.top + cornerLength),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(scanArea.right, scanArea.top),
      Offset(scanArea.right - cornerLength, scanArea.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.top),
      Offset(scanArea.right, scanArea.top + cornerLength),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(scanArea.left, scanArea.bottom),
      Offset(scanArea.left + cornerLength, scanArea.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.left, scanArea.bottom),
      Offset(scanArea.left, scanArea.bottom - cornerLength),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(scanArea.right, scanArea.bottom),
      Offset(scanArea.right - cornerLength, scanArea.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.bottom),
      Offset(scanArea.right, scanArea.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}