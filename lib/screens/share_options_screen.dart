import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/sharing_service.dart';
import 'qr_share_screen.dart';

class ShareOptionsScreen extends StatelessWidget {
  final Note note;

  const ShareOptionsScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Partager la note'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            note.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez une méthode de partage',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          _buildShareOption(
            context,
            icon: Icons.qr_code_2,
            title: 'QR Code',
            description: 'Générer un QR code pour partager hors-ligne',
            color: const Color(0xFF6366F1),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QrShareScreen(note: note),
                ),
              );
            },
            isDark: isDark,
          ),

          const SizedBox(height: 16),

          _buildShareOption(
            context,
            icon: Icons.text_fields,
            title: 'Texte simple',
            description: 'Partager comme texte via SMS, email, etc.',
            color: const Color(0xFF10B981),
            onTap: () async {
              await SharingService.shareNoteAsText(note);
            },
            isDark: isDark,
          ),

          const SizedBox(height: 16),

          _buildShareOption(
            context,
            icon: Icons.code,
            title: 'Format JSON',
            description: 'Exporter en JSON pour import ultérieur',
            color: const Color(0xFFF59E0B),
            onTap: () async {
              await SharingService.shareNotesAsJson([note]);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note exportée en JSON'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            isDark: isDark,
          ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.wifi_off,
                      color: const Color(0xFF6366F1),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Partage hors-ligne',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Ces méthodes fonctionnent sans connexion internet. Le QR code est idéal pour partager rapidement avec des personnes à proximité.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
        required Color color,
        required VoidCallback onTap,
        required bool isDark,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 20,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
