class Humanitarian {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String category;
  final List<TemplateField> fields;

  Humanitarian({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.category,
    required this.fields,
  });

  static List<Humanitarian> getAllTemplates() {
    return [
      Humanitarian(
        id: 'food_need',
        name: 'Besoin Alimentaire',
        icon: '🍽️',
        description: 'Fiche pour documenter les besoins alimentaires',
        category: 'humanitarian',
        fields: [
          TemplateField(label: 'Nom du bénéficiaire', type: FieldType.text, required: true),
          TemplateField(label: 'Village/Localité', type: FieldType.text, required: true),
          TemplateField(label: 'Nombre de personnes', type: FieldType.number, required: true),
          TemplateField(label: 'Nombre d\'enfants', type: FieldType.number),
          TemplateField(label: 'Type de besoin', type: FieldType.multiChoice,
              options: ['Riz', 'Maïs', 'Huile', 'Sucre', 'Sel', 'Lait', 'Autre']),
          TemplateField(label: 'Quantité estimée (kg)', type: FieldType.number),
          TemplateField(label: 'Urgence', type: FieldType.choice,
              options: ['Faible', 'Moyenne', 'Élevée', 'Critique']),
          TemplateField(label: 'Date de la demande', type: FieldType.date, required: true),
          TemplateField(label: 'Contact', type: FieldType.text),
          TemplateField(label: 'Observations', type: FieldType.textarea),
        ],
      ),

      Humanitarian(
        id: 'medical_need',
        name: 'Besoin Médical',
        icon: '🏥',
        description: 'Fiche pour documenter les besoins médicaux',
        category: 'humanitarian',
        fields: [
          TemplateField(label: 'Nom du patient', type: FieldType.text, required: true),
          TemplateField(label: 'Âge', type: FieldType.number, required: true),
          TemplateField(label: 'Sexe', type: FieldType.choice,
              options: ['Masculin', 'Féminin']),
          TemplateField(label: 'Village/Localité', type: FieldType.text, required: true),
          TemplateField(label: 'Type de besoin', type: FieldType.multiChoice,
              options: ['Consultation', 'Médicaments', 'Hospitalisation', 'Transport', 'Chirurgie', 'Autre']),
          TemplateField(label: 'Symptômes principaux', type: FieldType.textarea, required: true),
          TemplateField(label: 'Urgence', type: FieldType.choice,
              options: ['Faible', 'Moyenne', 'Élevée', 'Critique']),
          TemplateField(label: 'Date de la demande', type: FieldType.date, required: true),
          TemplateField(label: 'Contact famille', type: FieldType.text),
          TemplateField(label: 'Observations médicales', type: FieldType.textarea),
        ],
      ),

      Humanitarian(
        id: 'aid_report',
        name: 'Rapport d\'Aide',
        icon: '📋',
        description: 'Rapport de distribution d\'aide humanitaire',
        category: 'humanitarian',
        fields: [
          TemplateField(label: 'Nom du bénéficiaire', type: FieldType.text, required: true),
          TemplateField(label: 'Village/Localité', type: FieldType.text, required: true),
          TemplateField(label: 'Type d\'aide reçue', type: FieldType.multiChoice,
              options: ['Alimentaire', 'Médicale', 'Financière', 'Matériel', 'Éducation', 'Autre']),
          TemplateField(label: 'Description de l\'aide', type: FieldType.textarea, required: true),
          TemplateField(label: 'Quantité/Montant', type: FieldType.text),
          TemplateField(label: 'Date de distribution', type: FieldType.date, required: true),
          TemplateField(label: 'Organisation donatrice', type: FieldType.text),
          TemplateField(label: 'Agent distributeur', type: FieldType.text),
          TemplateField(label: 'Signature/Confirmation', type: FieldType.text),
          TemplateField(label: 'Observations', type: FieldType.textarea),
        ],
      ),

      Humanitarian(
        id: 'needs_assessment',
        name: 'Évaluation des Besoins',
        icon: '📊',
        description: 'Évaluation générale des besoins d\'une communauté',
        category: 'humanitarian',
        fields: [
          TemplateField(label: 'Village/Communauté', type: FieldType.text, required: true),
          TemplateField(label: 'Population estimée', type: FieldType.number),
          TemplateField(label: 'Date d\'évaluation', type: FieldType.date, required: true),
          TemplateField(label: 'Besoins prioritaires', type: FieldType.multiChoice,
              options: ['Eau', 'Nourriture', 'Santé', 'Abri', 'Éducation', 'Protection', 'Autre']),
          TemplateField(label: 'Situation alimentaire', type: FieldType.choice,
              options: ['Bonne', 'Acceptable', 'Préoccupante', 'Critique']),
          TemplateField(label: 'Accès à l\'eau potable', type: FieldType.choice,
              options: ['Bon', 'Limité', 'Très limité', 'Aucun']),
          TemplateField(label: 'Accès aux soins', type: FieldType.choice,
              options: ['Bon', 'Limité', 'Très limité', 'Aucun']),
          TemplateField(label: 'Personnes vulnérables', type: FieldType.textarea),
          TemplateField(label: 'Recommandations', type: FieldType.textarea, required: true),
          TemplateField(label: 'Évaluateur', type: FieldType.text),
        ],
      ),
    ];
  }

  static Humanitarian? getTemplateById(String id) {
    try {
      return getAllTemplates().firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  String generateContent(Map<String, dynamic> values) {
    final buffer = StringBuffer();
    buffer.writeln('=== $name ===\n');

    for (final field in fields) {
      final value = values[field.label];
      if (value != null && value.toString().isNotEmpty) {
        buffer.writeln('${field.label}: $value');
      }
    }

    buffer.writeln('\n--- Généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ---');
    return buffer.toString();
  }
}

class TemplateField {
  final String label;
  final FieldType type;
  final bool required;
  final List<String>? options;

  TemplateField({
    required this.label,
    required this.type,
    this.required = false,
    this.options,
  });
}

enum FieldType {
  text,
  textarea,
  number,
  date,
  choice,
  multiChoice,
}
