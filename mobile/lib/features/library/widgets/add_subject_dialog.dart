import 'package:flutter/material.dart';
import '../library_style.dart';

/// Kết quả trả về khi người dùng bấm Tạo môn học.
typedef NewSubjectInput = ({String name, String programmingLanguage});

/// Hộp thoại "+ Thêm môn học". Trả về null nếu người dùng bấm Hủy.
Future<NewSubjectInput?> showAddSubjectDialog(BuildContext context) {
  return showDialog<NewSubjectInput>(
    context: context,
    builder: (_) => const _AddSubjectDialog(),
  );
}

class _AddSubjectDialog extends StatefulWidget {
  const _AddSubjectDialog();

  @override
  State<_AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<_AddSubjectDialog> {
  static const List<String> _languages = [
    'Dart / Flutter',
    'Java',
    'Kotlin',
    'Python',
    'C++',
    'JavaScript',
    'Khác',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _language = _languages.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((
      name: _nameController.text.trim(),
      programmingLanguage: _language,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Thêm môn học',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: LibraryStyle.textPrimary,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Tên môn học',
                hintText: 'VD: Lập trình Flutter',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên môn học';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _language,
              decoration: const InputDecoration(
                labelText: 'Ngôn ngữ lập trình',
                border: OutlineInputBorder(),
              ),
              items: _languages
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _language = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Tạo môn học'),
        ),
      ],
    );
  }
}
