import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/activation_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            'Apparence',
            Icons.palette_outlined,
            [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return _buildModernTile(
                    context,
                    icon: themeProvider.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    title: 'Mode sombre',
                    subtitle: 'Basculer entre thème clair et sombre',
                    trailing: Switch.adaptive(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                      activeColor: const Color(0xFF6366F1),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildSection(
            context,
            'Données',
            Icons.storage_rounded,
            [
              Consumer<NotesProvider>(
                builder: (context, notesProvider, _) {
                  return _buildModernTile(
                    context,
                    icon: Icons.refresh_rounded,
                    title: 'Actualiser les notes',
                    subtitle: 'Recharger toutes les notes depuis le stockage',
                    onTap: () {
                      notesProvider.loadNotes();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Notes actualisées'),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    },
                  );
                },
              ),

              _buildModernTile(
                context,
                icon: Icons.backup_rounded,
                title: 'Sauvegarde automatique',
                subtitle: 'Sauvegarder automatiquement vos modifications',
                trailing: Switch.adaptive(
                  value: true,
                  onChanged: (value) {
                    // TODO: Implémenter la sauvegarde automatique
                  },
                  activeColor: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildSection(
            context,
            'Sécurité',
            Icons.security_rounded,
            [
              Consumer<ActivationProvider>(
                builder: (context, activationProvider, _) {
                  return _buildModernTile(
                    context,
                    icon: Icons.logout_rounded,
                    title: 'Se déconnecter',
                    subtitle: 'Invalider la clé d\'activation et se déconnecter',
                    onTap: () => _showLogoutDialog(context),
                    isDestructive: true,
                  );
                },
              ),

              _buildModernTile(
                context,
                icon: Icons.lock_outline_rounded,
                title: 'Verrouillage par code',
                subtitle: 'Protéger l\'accès à vos notes',
                trailing: Switch.adaptive(
                  value: false,
                  onChanged: (value) {
                    // TODO: Implémenter le verrouillage
                  },
                  activeColor: const Color(0xFF6366F1),
                ),
              ),

              _buildModernTile(
                context,
                icon: Icons.fingerprint_rounded,
                title: 'Authentification biométrique',
                subtitle: 'Utiliser l\'empreinte ou Face ID',
                trailing: Switch.adaptive(
                  value: false,
                  onChanged: (value) {
                    // TODO: Implémenter l'auth biométrique
                  },
                  activeColor: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildSection(
            context,
            'À propos',
            Icons.info_outline_rounded,
            [
              _buildModernTile(
                context,
                icon: Icons.info_rounded,
                title: 'Version de l\'application',
                subtitle: 'Gestionnaire de Notes v2.0.0',
                onTap: () => _showAboutDialog(context),
              ),

              _buildModernTile(
                context,
                icon: Icons.star_outline_rounded,
                title: 'Évaluer l\'application',
                subtitle: 'Donnez votre avis sur l\'App Store',
                onTap: () {
                  // TODO: Ouvrir l'App Store ou Play Store
                },
              ),

              _buildModernTile(
                context,
                icon: Icons.help_outline_rounded,
                title: 'Aide et support',
                subtitle: 'Obtenir de l\'aide ou signaler un problème',
                onTap: () {
                  // TODO: Ouvrir l'aide
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262626) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: children.map((child) {
              final index = children.indexOf(child);
              return Column(
                children: [
                  child,
                  if (index < children.length - 1)
                    Divider(
                      height: 1,
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.withOpacity(0.1),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildModernTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        Widget? trailing,
        VoidCallback? onTap,
        bool isDestructive = false,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? const Color(0xFFEF4444).withOpacity(0.1)
              : (isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDestructive
              ? const Color(0xFFEF4444)
              : (isDark ? Colors.grey[300] : Colors.grey[700]),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive
              ? const Color(0xFFEF4444)
              : (isDark ? Colors.white : Colors.black87),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing: trailing ?? (onTap != null
          ? Icon(
        Icons.chevron_right_rounded,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
      )
          : null),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.note_alt_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Gestionnaire de Notes',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 2.0.0',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Application moderne de gestion de notes avec export PDF, développée en Flutter.',
            ),
            const SizedBox(height: 16),
            Text(
              'Fonctionnalités principales:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            ...[
              '• Interface moderne et minimaliste',
              '• Création et modification de notes',
              '• Recherche intelligente et filtrage',
              '• Export PDF professionnel',
              '• Favoris et organisation',
              '• Thème clair/sombre adaptatif',
            ].map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                feature,
                style: TextStyle(color: Colors.grey[600]),
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Fermer',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Se déconnecter'),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ? Cela invalidera votre clé d\'activation et vous devrez la saisir à nouveau pour accéder à l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                ),
              );

              try {
                await context.read<ActivationProvider>().logout();

                if (context.mounted) {
                  Navigator.of(context).pop();

                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                        (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la déconnexion: $e'),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Se déconnecter',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
