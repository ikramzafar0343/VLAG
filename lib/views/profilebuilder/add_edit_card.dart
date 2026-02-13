import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../utils/linkcard_model.dart';
import '../widgets/reuseable.dart';

class AddCard extends StatefulWidget {
  /// If linkcardModel is not null, edit mode is triggered
  const AddCard({super.key, this.linkcardModel});

  final LinkcardModel? linkcardModel;

  @override
  State<AddCard> createState() => _AddCardState();
}

class _AddCardState extends State<AddCard> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  late bool _isNew;

  /// Validates that the input is a valid URL
  String? _validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Cannot be empty';
    }
    final trimmedValue = value.trim();
    
    // Check if it's a valid URL format
    final urlPattern = RegExp(
      r'^(https?:\/\/)?' // optional http:// or https://
      r'([\w\-]+\.)+[\w\-]+' // domain
      r'(\/[\w\-._~:/?#\[\]@!$&()*+,;=%]*)?$', // optional path
      caseSensitive: false,
    );
    
    if (!urlPattern.hasMatch(trimmedValue)) {
      return 'Please enter a valid URL';
    }
    
    // Ensure URL has a protocol
    if (!trimmedValue.startsWith('http://') && !trimmedValue.startsWith('https://')) {
      return 'URL must start with http:// or https://';
    }
    
    return null;
  }

  @override
  void initState() {
    super.initState();
    _isNew = widget.linkcardModel == null; //is not editing
    // initial Value
    if (_isNew) {
      _titleController.text = '';
    } else {
      _titleController.text = widget.linkcardModel!.displayName!;
      _urlController.text = widget.linkcardModel!.link!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isNew ? 'Add VLag' : 'Edit VLag',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 10),
          Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _titleController,
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Title cannot be empty'
                            : null,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Title',
                      hintText: 'e.g., description, rules, instructions…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.text,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    validator: _validateUrl,
                    controller: _urlController,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Link URL',
                      hintText: 'https://example.com/your-profile',
                      helperText: 'Enter the full URL (including https://)',
                      helperStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.url,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                    style: VLagButtonStyle.secondary,
                    icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                    onPressed: () => Navigator.pop(context),
                    label: Text(
                      _isNew ? 'Discard' : 'Cancel',
                      style: VLagButtonStyle.buttonText,
                    )),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.check, size: 14),
                  style: VLagButtonStyle.primary,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      String inputUrl = _urlController.text.trim();

                      Navigator.of(context).pop(LinkcardModel(
                          exactName: _titleController.text.trim(),
                          displayName: _titleController.text.trim(),
                          link: inputUrl));
                    }
                  },
                  label: Text(
                    _isNew ? 'Add' : 'Done',
                    style: VLagButtonStyle.buttonText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5)
        ],
      ),
    );
  }
}
