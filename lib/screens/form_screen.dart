import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/humanitarian.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';

class FormScreen extends StatefulWidget {
  final Humanitarian humanitarian;

  const FormScreen({super.key, required this.humanitarian});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final Map<String, dynamic> _formValues = {};
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (final field in widget.humanitarian.fields) {
      if (field.type == FieldType.text ||
          field.type == FieldType.textarea ||
          field.type == FieldType.number ||
          field.type == FieldType.date) {
        _controllers[field.label] = TextEditingController();
      }
      if (field.type == FieldType.multiChoice) {
        _formValues[field.label] = <String>[];
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      for (final entry in _controllers.entries) {
        _formValues[entry.key] = entry.value.text;
      }

      final content = widget.humanitarian.generateContent(_formValues);
      final now = DateTime.now();

      final note = Note(
        title: widget.humanitarian.name,
        content: content,
        category: 'humanitarian',
        tags: ['humanitaire', widget.humanitarian.id],
        createdAt: now,
        updatedAt: now,
      );

      await context.read<NotesProvider>().addNote(note);

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fiche créée avec succès'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.humanitarian.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _isLoading ? null : _saveNote,
              icon: _isLoading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.check),
              label: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.humanitarian.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.humanitarian.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ...widget.humanitarian.fields.map((field) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildField(field, isDark),
              );
            }),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveNote,
              icon: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.save),
              label: const Text('Enregistrer la fiche'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TemplateField field, bool isDark) {
    switch (field.type) {
      case FieldType.text:
      case FieldType.number:
        return TextFormField(
          controller: _controllers[field.label],
          decoration: InputDecoration(
            labelText: field.label + (field.required ? ' *' : ''),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          ),
          keyboardType: field.type == FieldType.number
              ? TextInputType.number
              : TextInputType.text,
          validator: field.required
              ? (value) => value?.isEmpty ?? true ? 'Champ requis' : null
              : null,
        );

      case FieldType.textarea:
        return TextFormField(
          controller: _controllers[field.label],
          decoration: InputDecoration(
            labelText: field.label + (field.required ? ' *' : ''),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          validator: field.required
              ? (value) => value?.isEmpty ?? true ? 'Champ requis' : null
              : null,
        );

      case FieldType.date:
        return TextFormField(
          controller: _controllers[field.label],
          decoration: InputDecoration(
            labelText: field.label + (field.required ? ' *' : ''),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) {
              _controllers[field.label]!.text =
              '${date.day}/${date.month}/${date.year}';
            }
          },
          validator: field.required
              ? (value) => value?.isEmpty ?? true ? 'Champ requis' : null
              : null,
        );

      case FieldType.choice:
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: field.label + (field.required ? ' *' : ''),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          ),
          items: field.options?.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _formValues[field.label] = value;
            });
          },
          validator: field.required
              ? (value) => value == null ? 'Champ requis' : null
              : null,
        );

      case FieldType.multiChoice:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label + (field.required ? ' *' : ''),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: field.options?.map((option) {
                final isSelected = (_formValues[field.label] as List<String>?)
                    ?.contains(option) ??
                    false;
                return FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      final list = _formValues[field.label] as List<String>? ??
                          <String>[];
                      if (selected) {
                        list.add(option);
                      } else {
                        list.remove(option);
                      }
                      _formValues[field.label] = list;
                    });
                  },
                  selectedColor: const Color(0xFFEF4444).withOpacity(0.2),
                  checkmarkColor: const Color(0xFFEF4444),
                );
              }).toList() ??
                  [],
            ),
          ],
        );
    }
  }
}
