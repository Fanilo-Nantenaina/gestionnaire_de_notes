import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/sharing_service.dart';
import '../providers/notes_provider.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    try {
      final note = SharingService.decodeNote(code);

      if (note != null && mounted) {
        await context.read<NotesProvider>().addNote(note);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note reçue avec succès!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR Code invalide'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

          // Overlay avec cadre de scan
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),

          // Instructions
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

          // Bouton lampe torche
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

    // Coins du cadre
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
