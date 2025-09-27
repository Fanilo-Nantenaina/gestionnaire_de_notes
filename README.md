# Gestionnaire de Notes

Application Flutter moderne de gestion de notes avec export PDF, thèmes personnalisables et système d'activation.

## Fonctionnalités

- Création, édition et recherche de notes
- Export PDF avec ouverture automatique
- Système d'activation par clé
- Thèmes sombre/clair
- Stockage SQLite local

## Architecture

```
lib/
├── models/          # Modèles de données
├── providers/       # Gestion d'état (Provider)  
├── screens/         # Écrans de l'interface
├── services/        # Services (DB, PDF, activation)
└── widgets/         # Composants réutilisables
```

## Installation

```bash
git clone <url-du-repository>
cd gestionnaire_de_notes
flutter pub get
flutter run
```

## Build Production

```bash
# APK
flutter build apk --split-per-abi

# Play Store
flutter build appbundle
```

## Configuration

**Clés de démonstration :**
- `DEMO-2024-NOTES-001`
- `TEST-KEY-FLUTTER-01`

Format : `XXXX-XXXX-XXXX-XXX`

## Utilisation

1. Saisir une clé d'activation valide
2. Créer des notes via le bouton FAB
3. Rechercher et filtrer dans la liste
4. Exporter en PDF depuis le détail d'une note

## Développement

Base de données SQLite avec migrations automatiques.
Architecture MVVM avec Provider pour la gestion d'état.

---

*Consultez la documentation Flutter : [flutter.dev](https://flutter.dev)*