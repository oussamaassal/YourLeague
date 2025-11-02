import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../cubits/stadium_cubit.dart';
import '../cubits/stadium_states.dart';
import '../../../../User/features/auth/presentation/cubits/auth_cubit.dart';

class AdminAddStadiumPage extends StatefulWidget {
  const AdminAddStadiumPage({super.key});

  @override
  State<AdminAddStadiumPage> createState() => _AdminAddStadiumPageState();
}

class _AdminAddStadiumPageState extends State<AdminAddStadiumPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController(text: '100');

  File? _imageFile;

  // 🟦 Your Cloudinary credentials
  final String cloudName = 'dcqs7fphe';
  final String uploadPreset = 'YourLeague'; // safer for client use

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<String> _uploadToCloudinary(File imageFile) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(resBody);
      return data['secure_url']; // ✅ Cloudinary image URL
    } else {
      throw Exception('Cloudinary upload failed: ${response.statusCode}');
    }
  }

  Future<void> _addStadium() async {
    if (!_formKey.currentState!.validate()) return;

    final stadiumCubit = context.read<StadiumCubit>();
    final authCubit = context.read<AuthCubit>();
    final currentUser = authCubit.currentUser;

    try {
      String imageUrl = '';
      if (_imageFile != null) {
        imageUrl = await _uploadToCloudinary(_imageFile!);
      }

      stadiumCubit.createStadium(
        name: _nameController.text.trim(),
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        capacity: int.tryParse(_capacityController.text.trim()) ?? 100,
        pricePerHour: double.parse(_priceController.text.trim()),
        imageUrl: imageUrl,
        userId: currentUser?.uid,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StadiumCubit, StadiumState>(
      listener: (context, state) {
        if (state is StadiumOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          _formKey.currentState?.reset();
          setState(() => _imageFile = null);
        } else if (state is StadiumError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is StadiumLoading;

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            appBar: AppBar(title: const Text('Add Stadium')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Stadium Name'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(labelText: 'City'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter city' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(labelText: 'Address'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter address' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _capacityController,
                            decoration: const InputDecoration(labelText: 'Capacity'),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter capacity';
                              if (int.tryParse(v) == null) return 'Enter a valid number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(labelText: 'Price per hour'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter price';
                              if (double.tryParse(v) == null) return 'Enter a valid number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(_imageFile!, height: 150, fit: BoxFit.cover),
                                )
                              : const Text('No image selected'),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: isLoading ? null : _pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Pick Image'),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: isLoading ? null : _addStadium,
                            child: const Text('Add Stadium'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
