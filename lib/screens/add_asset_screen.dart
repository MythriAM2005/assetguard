import 'package:flutter/material.dart';
import '../services/asset_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';

class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({super.key});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _trackerCtrl = TextEditingController();
  String _selectedCategory = 'Bag';
  bool _saving = false;
  String? _errorMessage;

  static const List<String> _categories = [
    'Bag',
    'Laptop',
    'ID Card',
    'Book',
    'Phone',
    'Electronics',
    'Keys',
    'Wallet',
    'Other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _trackerCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final asset = await AssetService.instance.createAsset(
        name: _nameCtrl.text.trim(),
        category: _selectedCategory,
        description: _descCtrl.text.trim(),
        trackerId: _trackerCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('${asset.name} added successfully!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Failed to save asset. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Asset')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.errorColor.withAlpha(77)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.errorColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.errorColor)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _sectionLabel('Asset Information'),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Asset Name',
                  hint: 'e.g. College Bag',
                  controller: _nameCtrl,
                  prefixIcon: Icons.label_outline,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter an asset name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildCategoryDropdown(),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Description',
                  hint: 'Colour, brand, serial number, other details…',
                  controller: _descCtrl,
                  maxLines: 3,
                  prefixIcon: Icons.description_outlined,
                ),

                const SizedBox(height: 28),
                _sectionLabel('Tracker Configuration'),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Tracker ID',
                  hint: 'e.g. AG-006',
                  controller: _trackerCtrl,
                  prefixIcon: Icons.nfc_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter a Tracker ID';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'The tracker ID is the unique identifier of the BLE beacon attached to this asset.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveAsset,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 20),
                    label: Text(_saving ? 'Saving…' : 'Save Asset'),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category_outlined, size: 20),
        filled: true,
        fillColor: const Color(0xFFF0F4FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8EDF5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: _categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) => setState(() => _selectedCategory = v!),
    );
  }
}
