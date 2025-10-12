class ErrorMessages {
  static String getActivationError(String errorCode) {
    switch (errorCode) {
      case 'INVALID_FORMAT':
        return 'Format de clé invalide. La clé doit être au format SERIAL:SIGNATURE (ex: ABC123:A1B2C3D4).';
      case 'KEY_REVOKED':
        return 'Cette clé d\'activation a été révoquée et ne peut plus être utilisée. Contactez l\'administrateur pour obtenir une nouvelle clé.';
      case 'KEY_ALREADY_USED':
        return 'Cette clé est déjà utilisée sur un autre appareil. Chaque clé ne peut être activée que sur un seul appareil.';
      case 'INVALID_SIGNATURE':
        return 'La signature de la clé est invalide. Vérifiez que vous avez copié la clé complète sans erreur.';
      case 'NETWORK_ERROR':
        return 'Impossible de vérifier la clé. Vérifiez votre connexion internet et réessayez.';
      case 'DATABASE_ERROR':
        return 'Erreur lors de l\'enregistrement de l\'activation. Veuillez réessayer.';
      default:
        return 'Erreur lors de l\'activation. Veuillez vérifier votre clé et réessayer.';
    }
  }

  static String getPinError(String errorCode, {int? remainingAttempts, int? lockoutMinutes}) {
    switch (errorCode) {
      case 'INVALID_PIN':
        if (remainingAttempts != null && remainingAttempts > 0) {
          return 'PIN incorrect. Il vous reste $remainingAttempts tentative${remainingAttempts > 1 ? 's' : ''}.';
        }
        return 'PIN incorrect. Veuillez réessayer.';
      case 'LOCKED_OUT':
        if (lockoutMinutes != null) {
          return 'Trop de tentatives échouées. Veuillez réessayer dans $lockoutMinutes minute${lockoutMinutes > 1 ? 's' : ''}.';
        }
        return 'Compte temporairement verrouillé. Veuillez réessayer plus tard.';
      case 'PIN_TOO_SHORT':
        return 'Le PIN doit contenir au moins 4 chiffres.';
      case 'PIN_TOO_WEAK':
        return 'Ce PIN est trop simple. Évitez les séquences comme 1234 ou 0000.';
      case 'PINS_DONT_MATCH':
        return 'Les deux PINs ne correspondent pas. Veuillez réessayer.';
      default:
        return 'Erreur lors de la vérification du PIN.';
    }
  }

  static String getNoteError(String errorCode) {
    switch (errorCode) {
      case 'TITLE_EMPTY':
        return 'Le titre de la note ne peut pas être vide.';
      case 'CONTENT_EMPTY':
        return 'Le contenu de la note ne peut pas être vide.';
      case 'TITLE_TOO_LONG':
        return 'Le titre est trop long (maximum 200 caractères).';
      case 'SAVE_FAILED':
        return 'Impossible d\'enregistrer la note. Vérifiez l\'espace de stockage disponible.';
      case 'DELETE_FAILED':
        return 'Impossible de supprimer la note. Veuillez réessayer.';
      case 'NOT_FOUND':
        return 'Cette note n\'existe plus ou a été supprimée.';
      case 'ENCRYPTION_FAILED':
        return 'Erreur lors du chiffrement de la note. Vos données sont en sécurité mais non chiffrées.';
      default:
        return 'Une erreur est survenue lors de l\'opération sur la note.';
    }
  }

  static String getSharingError(String errorCode) {
    switch (errorCode) {
      case 'QR_GENERATION_FAILED':
        return 'Impossible de générer le QR code. La note est peut-être trop volumineuse.';
      case 'QR_SCAN_FAILED':
        return 'Impossible de scanner le QR code. Assurez-vous qu\'il est bien visible et éclairé.';
      case 'INVALID_QR_DATA':
        return 'Le QR code scanné ne contient pas de données valides.';
      case 'SHARE_CANCELLED':
        return 'Partage annulé.';
      case 'NO_APP_AVAILABLE':
        return 'Aucune application disponible pour partager ce contenu.';
      case 'CAMERA_PERMISSION_DENIED':
        return 'Permission caméra refusée. Activez-la dans les paramètres de l\'application.';
      default:
        return 'Erreur lors du partage. Veuillez réessayer.';
    }
  }

  static String getPdfError(String errorCode) {
    switch (errorCode) {
      case 'GENERATION_FAILED':
        return 'Impossible de générer le PDF. Vérifiez l\'espace de stockage disponible.';
      case 'NO_NOTES_SELECTED':
        return 'Veuillez sélectionner au moins une note à exporter.';
      case 'FILE_TOO_LARGE':
        return 'Le fichier PDF est trop volumineux. Essayez d\'exporter moins de notes.';
      case 'STORAGE_PERMISSION_DENIED':
        return 'Permission de stockage refusée. Activez-la dans les paramètres.';
      default:
        return 'Erreur lors de l\'export PDF.';
    }
  }

  static String getSuccessMessage(String action) {
    switch (action) {
      case 'NOTE_SAVED':
        return 'Note enregistrée avec succès';
      case 'NOTE_DELETED':
        return 'Note supprimée';
      case 'NOTES_DELETED':
        return 'Notes supprimées';
      case 'NOTE_SHARED':
        return 'Note partagée';
      case 'PDF_EXPORTED':
        return 'PDF exporté avec succès';
      case 'ACTIVATION_SUCCESS':
        return 'Application activée avec succès';
      case 'PIN_CHANGED':
        return 'PIN modifié avec succès';
      case 'SETTINGS_SAVED':
        return 'Paramètres enregistrés';
      default:
        return 'Opération réussie';
    }
  }
}