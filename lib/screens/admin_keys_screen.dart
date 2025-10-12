import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/activation_key_service.dart';
import '../services/database_service.dart';
import '../services/crypto_service.dart';
import '../widgets/bottom_sheet.dart';
import 'change_pin_screen.dart';

class AdminKeysScreen extends StatefulWidget {
  const AdminKeysScreen({super.key});

  @override
  State<AdminKeysScreen> createState() => _AdminKeysScreenState();
}

class _AdminKeysScreenState extends State<AdminKeysScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ActivationKeyService? _keyService;
  List<Map<String, dynamic>> _activatedKeys = [];
  List<Map<String, dynamic>> _revokedKeys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeService();
  }

  Future<void> _initializeService() async {
    final DatabaseService databaseService = DatabaseService.instance;
    _keyService = ActivationKeyService(databaseService);
    await _loadKeys();
  }

  Future<void> _loadKeys() async {
    setState(() => _isLoading = true);

    try {
      _activatedKeys = await _keyService!.listActivatedKeys();
      _revokedKeys = await _keyService!.listRevokedKeys();
    } catch (e) {
      debugPrint('Erreur lors du chargement des clés: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showImportKeyDialog() {
    CustomBottomSheet.showTextInput(
      context: context,
      title: 'Importer une clé',
      subtitle: 'Format: SERIAL:SIGNATURE',
      hintText: 'ABC123_XY:dGVzdHNpZ25h',
      labelText: 'Clé d\'activation',
      maxLines: 2,
      icon: Icons.vpn_key,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez saisir une clé';
        }
        if (!CryptoService.verifyKey(value)) {
          return 'Clé invalide ou signature incorrecte';
        }
        return null;
      },
    ).then((key) async {
      if (key != null) {
        final parts = key.split(':');
        if (parts.length == 2) {
          final serialHash = parts[0];

          await _keyService!.createKey(key, serialHash);
          await _loadKeys();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Clé importée avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    });
  }

  void _showGenerateKeyDialog() {
    final newKey = CryptoService.generateKey();
    final parts = newKey.split(':');
    final serialHash = parts[0];

    _keyService!.createKey(newKey, serialHash).then((_) {
      _loadKeys();
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    CustomBottomSheet.showForm(
      context: context,
      title: 'Nouvelle clé générée',
      subtitle: 'Copiez cette clé et partagez-la avec l\'utilisateur',
      icon: Icons.vpn_key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              ),
            ),
            child: SelectableText(
              newKey,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: newKey));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Clé copiée dans le presse-papier'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copier'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Share.share(
                      'Clé d\'activation:\n$newKey\n\nUtilisez cette clé pour activer votre application.',
                      subject: 'Clé d\'activation',
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Partager'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _loadKeys();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).then((_) {
      _loadKeys();
    });
  }

  void _showShareKeyDialog(Map<String, dynamic> key) {
    final keyFull = key['key_full'] as String;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partager la clé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choisissez comment partager cette clé:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copier'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: keyFull));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Clé copiée'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Partager'),
              onTap: () {
                Navigator.pop(context);
                Share.share(
                  'Clé d\'activation:\n$keyFull\n\nUtilisez cette clé pour activer votre application.',
                  subject: 'Clé d\'activation',
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showRevokeDialog(Map<String, dynamic> key) {
    CustomBottomSheet.showTextInput(
      context: context,
      title: 'Révoquer la clé',
      subtitle: 'Cette action empêchera l\'utilisation de cette clé',
      labelText: 'Raison (optionnel)',
      maxLines: 2,
      icon: Icons.block,
      confirmText: 'Révoquer',
    ).then((reason) async {
      if (reason != null) {
        await _keyService!.revokeKey(
          key['serial_hash'],
          reason,
        );
        await _loadKeys();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clé révoquée'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  void _showDeleteDialog(Map<String, dynamic> key) {
    CustomBottomSheet.showConfirmation(
      context: context,
      title: 'Supprimer la clé',
      message: 'Êtes-vous sûr de vouloir supprimer cette clé définitivement ?',
      icon: Icons.delete_forever,
      confirmText: 'Supprimer',
      confirmColor: Colors.red,
    ).then((confirmed) async {
      if (confirmed == true) {
        await _keyService!.deleteActivatedKey(key['serial_hash']);
        await _loadKeys();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clé supprimée'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des clés'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Activées', icon: Icon(Icons.check_circle)),
            Tab(text: 'Révoquées', icon: Icon(Icons.block)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChangePinScreen(),
                ),
              );
            },
            tooltip: 'Changer le PIN',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: _showGenerateKeyDialog,
            tooltip: 'Générer une clé',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showImportKeyDialog,
            tooltip: 'Importer une clé',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadKeys,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildActivatedKeysList(),
          _buildRevokedKeysList(),
        ],
      ),
    );
  }

  Widget _buildActivatedKeysList() {
    if (_activatedKeys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.key_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune clé activée',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Générez une nouvelle clé pour commencer',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activatedKeys.length,
      itemBuilder: (context, index) {
        final key = _activatedKeys[index];
        final serialHash = key['serial_hash'] as String;
        final truncatedSerial = serialHash.length > 16
            ? '${serialHash.substring(0, 16)}...'
            : serialHash;
        final keyFull = key['key_full'] as String;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        truncatedSerial,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (key['device_id'] != null)
                        Text(
                          'Appareil: ${key['device_id']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      Text(
                        'Créé le: ${_formatDate(key['created_at'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (key['activated_at'] != null)
                        Text(
                          'Activé le: ${_formatDate(key['activated_at'])}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 22),
                  color: Colors.blue,
                  tooltip: 'Copier la clé',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: keyFull));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Clé copiée dans le presse-papier'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Plus d\'actions',
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Icons.share, color: Colors.blue),
                        title: Text('Partager'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: () => Future.delayed(
                        Duration.zero,
                            () => _showShareKeyDialog(key),
                      ),
                    ),
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Icons.block, color: Colors.orange),
                        title: Text('Révoquer'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: () => Future.delayed(
                        Duration.zero,
                            () => _showRevokeDialog(key),
                      ),
                    ),
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Supprimer'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: () => Future.delayed(
                        Duration.zero,
                            () => _showDeleteDialog(key),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRevokedKeysList() {
    if (_revokedKeys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune clé révoquée',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _revokedKeys.length,
      itemBuilder: (context, index) {
        final key = _revokedKeys[index];
        final serialHash = key['serial_hash'] as String;
        final truncatedSerial = serialHash.length > 16
            ? '${serialHash.substring(0, 16)}...'
            : serialHash;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.block, color: Colors.white),
            ),
            title: Text(
              truncatedSerial,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Révoqué le: ${_formatDate(key['revoked_at'])}'),
                if (key['revoke_reason'] != null && key['revoke_reason'].toString().isNotEmpty)
                  Text('Raison: ${key['revoke_reason']}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Supprimer'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onTap: () => Future.delayed(
                    Duration.zero,
                        () => _showDeleteDialog(key),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}