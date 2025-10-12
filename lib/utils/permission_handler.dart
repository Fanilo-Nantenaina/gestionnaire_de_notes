import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/custom_snackbar.dart';
import 'error_messages.dart';

class PermissionHelper {
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.camera.request();

      if (result.isGranted) {
        return true;
      } else if (result.isPermanentlyDenied) {
        _showPermissionDialog(
          context,
          title: 'Permission caméra requise',
          message: 'L\'accès à la caméra est nécessaire pour scanner les QR codes. Veuillez activer la permission dans les paramètres de l\'application.',
        );
        return false;
      } else {
        CustomSnackBar.showError(
          context,
          ErrorMessages.getSharingError('CAMERA_PERMISSION_DENIED'),
        );
        return false;
      }
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        context,
        title: 'Permission caméra requise',
        message: 'L\'accès à la caméra est nécessaire pour scanner les QR codes. Veuillez activer la permission dans les paramètres de l\'application.',
      );
      return false;
    }

    return false;
  }

  static Future<bool> requestStoragePermission(BuildContext context) async {
    final status = await Permission.storage.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.storage.request();

      if (result.isGranted) {
        return true;
      } else if (result.isPermanentlyDenied) {
        _showPermissionDialog(
          context,
          title: 'Permission de stockage requise',
          message: 'L\'accès au stockage est nécessaire pour exporter les fichiers. Veuillez activer la permission dans les paramètres de l\'application.',
        );
        return false;
      } else {
        CustomSnackBar.showError(
          context,
          ErrorMessages.getPdfError('STORAGE_PERMISSION_DENIED'),
        );
        return false;
      }
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        context,
        title: 'Permission de stockage requise',
        message: 'L\'accès au stockage est nécessaire pour exporter les fichiers. Veuillez activer la permission dans les paramètres de l\'application.',
      );
      return false;
    }

    return false;
  }

  static void _showPermissionDialog(
      BuildContext context, {
        required String title,
        required String message,
      }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );
  }
}