import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/humanitarian.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';

class FormScreen extends StatefulWidget {
  final Humanitarian humanitarian;
  final Note? existingNote;

  const FormScreen({
    super.key,
    required this.humanitarian,
    this.existingNote,
  });

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

    if (widget.existingNote?.humanitarianData != null) {
      final humanitarianData = widget.existingNote!.humanitarianData!;
      if (humanitarianData.containsKey('fields')) {
        _formValues.addAll(humanitarianData['fields'] as Map<String, dynamic>);
      }
    }

    for (final field in widget.humanitarian.fields) {
      if (field.type == FieldType.text ||
          field.type == FieldType.textarea ||
          field.type == FieldType.number ||
          field.type == FieldType.date) {
        _controllers[field.label] = TextEditingController(
          text: _formValues[field.label]?.toString() ?? '',
        );
      }
      if (field.type == FieldType.multiChoice) {
        _formValues[field.label] = _formValues[field.label] is List
            ? List<String>.from(_formValues[field.label])
            : <String>[];
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

      final humanitarianData = {
        'templateId': widget.humanitarian.id,
        'templateName': widget.humanitarian.name,
        'fields': Map<String, dynamic>.from(_formValues),
      };

      final note = Note(
        id: widget.existingNote?.id,
        title: widget.humanitarian.name,
        content: content,
        category: 'Humanitaire',
        tags: ['humanitaire', widget.humanitarian.id],
        createdAt: widget.existingNote?.createdAt ?? now,
        updatedAt: now,
        isFavorite: widget.existingNote?.isFavorite ?? false,
        humanitarianData: humanitarianData,
      );

      if (widget.existingNote != null) {
        await context.read<NotesProvider>().updateNote(note);
      } else {
        await context.read<NotesProvider>().addNote(note);
      }

      if (mounted) {
        Navigator.pop(context);
        if (widget.existingNote == null) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingNote != null
                ? 'Fiche modifiée avec succès'
                : 'Fiche créée avec succès'),
            backgroundColor: const Color(0xFF10B981),
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
        title: Text(widget.existingNote != null
            ? 'Modifier ${widget.humanitarian.name}'
            : widget.humanitarian.name),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.humanitarian.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.humanitarian.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.5,
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
                  : const Icon(Icons.save_rounded),
              label: Text(widget.existingNote != null
                  ? 'Mettre à jour la fiche'
                  : 'Enregistrer la fiche'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
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
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            alignLabelWithHint: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            suffixIcon: const Icon(Icons.calendar_today_rounded),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
          value: _formValues[field.label],
          decoration: InputDecoration(
            labelText: field.label + (field.required ? ' *' : ''),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                fontWeight: FontWeight.w600,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }).toList() ??
                  [],
            ),
          ],
        );
    }
  }
}
