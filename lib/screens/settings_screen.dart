import 'package:flutter/material.dart';
import 'package:gestionnaire_de_notes/screens/qr_scan_screen.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/activation_provider.dart';
import '../screens/activation_screen.dart';
import '../screens/humanitarian_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  void initState() {
    super.initState();
  }

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
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.help_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Besoin d\'aide?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cette application fonctionne hors-ligne. Vos notes sont sauvegardées localement sur votre appareil.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Apparence', isDark),
          const SizedBox(height: 12),

          _buildSettingTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: 'Thème sombre',
            subtitle: 'Activer le mode sombre',
            trailing: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                  activeColor: const Color(0xFF6366F1),
                );
              },
            ),
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Raccourcis rapides', isDark),
          const SizedBox(height: 12),

          _buildSettingTile(
            context,
            icon: Icons.qr_code_scanner,
            title: 'Scanner QR Code',
            subtitle: 'Recevoir des notes partagées',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QrScanScreen(),
                ),
              );
            },
            isDark: isDark,
          ),

          const SizedBox(height: 8),

          _buildSettingTile(
            context,
            icon: Icons.favorite,
            title: 'Modèles humanitaires',
            subtitle: 'Fiches prédéfinies pour l\'aide',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HumanitarianTemplatesScreen(),
                ),
              );
            },
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('À propos', isDark),
          const SizedBox(height: 12),

          _buildSettingTile(
            context,
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
            isDark: isDark,
          ),

          const SizedBox(height: 8),

          _buildSettingTile(
            context,
            icon: Icons.description_outlined,
            title: 'Licence',
            subtitle: 'Open Source',
            isDark: isDark,
          ),

          const SizedBox(height: 32),

          Consumer<ActivationProvider>(
            builder: (context, activationProvider, _) {
              return ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Déconnexion'),
                      content: const Text(
                        'Voulez-vous vraiment vous déconnecter?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Déconnexion'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await activationProvider.logout();

                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const ActivationScreen()),
                            (route) => false,
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Déconnexion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        Widget? trailing,
        VoidCallback? onTap,
        required bool isDark,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6366F1),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: trailing ??
            (onTap != null
                ? Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            )
                : null),
      ),
    );
  }
}
