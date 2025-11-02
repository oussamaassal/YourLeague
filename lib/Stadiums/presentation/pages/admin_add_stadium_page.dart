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
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  List<File> _imageFiles = []; // Multiple images support

  // 🟦 Your Cloudinary credentials
  final String cloudName = 'dcqs7fphe';
  final String uploadPreset = 'YourLeague'; // safer for client use

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(picked.map((p) => File(p.path)));
      });
    }
  }

  Future<void> _pickSingleImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFiles.add(File(picked.path));
      });
    }
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
      List<String> imageUrls = [];
      // Upload all images
      for (final imageFile in _imageFiles) {
        final url = await _uploadToCloudinary(imageFile);
        imageUrls.add(url);
      }

      stadiumCubit.createStadium(
        name: _nameController.text.trim(),
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        capacity: int.tryParse(_capacityController.text.trim()) ?? 100,
        pricePerHour: double.parse(_priceController.text.trim()),
        imageUrls: imageUrls,
        userId: currentUser?.uid,
        latitude: _latitudeController.text.trim().isEmpty
            ? null
            : double.tryParse(_latitudeController.text.trim()),
        longitude: _longitudeController.text.trim().isEmpty
            ? null
            : double.tryParse(_longitudeController.text.trim()),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
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
    _phoneController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
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
          setState(() {
            _imageFiles.clear();
            _phoneController.clear();
            _descriptionController.clear();
            _latitudeController.clear();
            _longitudeController.clear();
          });
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
                          // Multiple Images
                          if (_imageFiles.isNotEmpty)
                            SizedBox(
                              height: 150,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _imageFiles.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            _imageFiles[index],
                                            width: 150,
                                            height: 150,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.red,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              iconSize: 16,
                                              icon: const Icon(Icons.close, color: Colors.white),
                                              onPressed: isLoading
                                                  ? null
                                                  : () {
                                                      setState(() {
                                                        _imageFiles.removeAt(index);
                                                      });
                                                    },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            const Text('No images selected'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: isLoading ? null : _pickSingleImage,
                                  icon: const Icon(Icons.image),
                                  label: const Text('Add Image'),
                                ),
                              ),
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: isLoading ? null : _pickImages,
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Add Multiple'),
                                ),
                              ),
                            ],
                          ),
                          // Additional Fields
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(labelText: 'Phone Number (Optional)'),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(labelText: 'Description (Optional)'),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _latitudeController,
                                  decoration: const InputDecoration(
                                      labelText: 'Latitude (Optional)'),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _longitudeController,
                                  decoration: const InputDecoration(
                                      labelText: 'Longitude (Optional)'),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                            ],
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
