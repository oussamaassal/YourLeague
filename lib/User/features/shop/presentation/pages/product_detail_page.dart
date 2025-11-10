import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:image_picker/image_picker.dart';
import 'package:yourleague/User/features/shop/presentation/cubits/shop_cubit.dart';
import 'package:yourleague/User/features/shop/presentation/cubits/shop_states.dart';
import 'package:yourleague/User/features/shop/presentation/cubits/cart_cubit.dart';
import 'package:yourleague/User/features/shop/domain/entities/product.dart';
import 'package:yourleague/User/features/shop/domain/entities/review.dart';
import 'package:yourleague/User/features/shop/domain/entities/cart_item.dart';
import 'package:yourleague/User/features/shop/data/cloudinary_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:yourleague/config/api_config.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 0;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  File? _selectedImage;
  bool _isUploading = false;
  String? _translatedDescription;
  bool _translating = false;
  
  // Currency converter state
  String _selectedCurrency = 'USD';
  double? _convertedPrice;
  bool _converting = false;

  @override
  void initState() {
    super.initState();
    // Load product reviews when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopCubit>().getProductReviews(widget.product.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _cloudinaryService.uploadImage(_selectedImage!);
      if (imageUrl == null) {
        setState(() {
          _isUploading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
        return;
      }
    }

    final currentUser = _firebaseAuth.currentUser;
    context.read<ShopCubit>().createReview(
          productId: widget.product.id,
          rating: _selectedRating,
          comment: _commentController.text.trim(),
          userName: currentUser?.email?.split('@').first,
          imageUrl: imageUrl,
        );

    setState(() {
      _selectedRating = 0;
      _commentController.clear();
      _selectedImage = null;
      _isUploading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully')),
      );
    }
  }

  double _calculateAverageRating(List<Review> reviews) {
    if (reviews.isEmpty) return 0.0;
    final sum = reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
    return sum / reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
      ),
      body: BlocConsumer<ShopCubit, ShopState>(
        listener: (context, state) {
          if (state is ShopError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          List<Review> reviews = [];
          if (state is ReviewsLoaded) {
            reviews = state.reviews;
          } else if (state is ShopLoading && reviews.isEmpty) {
            // Keep previous reviews while loading
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey[200],
                  child: widget.product.imageUrl != null &&
                          widget.product.imageUrl!.isNotEmpty
                      ? Image.network(
                          widget.product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 64, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            widget.product.name[0].toUpperCase(),
                            style: const TextStyle(fontSize: 80),
                          ),
                        ),
                ),

                // Product Info
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.product.category,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\$${widget.product.price.toStringAsFixed(2)} USD',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                              if (_convertedPrice != null && _selectedCurrency != 'USD') ...[
                                const SizedBox(height: 4),
                                Text(
                                  '≈ ${_convertedPrice!.toStringAsFixed(2)} $_selectedCurrency',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ],
                          ),
                          // Currency dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _converting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : DropdownButton<String>(
                                    value: _selectedCurrency,
                                    underline: const SizedBox(),
                                    isDense: true,
                                    items: const [
                                      DropdownMenuItem(value: 'USD', child: Text('🇺🇸 USD')),
                                      DropdownMenuItem(value: 'EUR', child: Text('🇪🇺 EUR')),
                                      DropdownMenuItem(value: 'GBP', child: Text('🇬🇧 GBP')),
                                      DropdownMenuItem(value: 'JPY', child: Text('🇯🇵 JPY')),
                                      DropdownMenuItem(value: 'CAD', child: Text('🇨🇦 CAD')),
                                      DropdownMenuItem(value: 'AUD', child: Text('🇦🇺 AUD')),
                                      DropdownMenuItem(value: 'CHF', child: Text('🇨🇭 CHF')),
                                      DropdownMenuItem(value: 'CNY', child: Text('🇨🇳 CNY')),
                                      DropdownMenuItem(value: 'INR', child: Text('🇮🇳 INR')),
                                      DropdownMenuItem(value: 'MAD', child: Text('🇲🇦 MAD')),
                                    ],
                                    onChanged: (currency) {
                                      if (currency != null && currency != 'USD') {
                                        _convertPrice(currency);
                                      } else if (currency == 'USD') {
                                        setState(() {
                                          _selectedCurrency = 'USD';
                                          _convertedPrice = null;
                                        });
                                      }
                                    },
                                  ),
                          ),
                          if (!widget.product.isAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Out of Stock',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _translatedDescription ?? widget.product.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (_translatedDescription != null) ...[
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () => setState(() => _translatedDescription = null),
                          child: const Text('Show original'),
                        ),
                      ],
                      if (_translatedDescription == null) ...[
                        const SizedBox(height: 6),
                        _buildTranslateRow(),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Stock: ${widget.product.stockQuantity}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 24),

                      // Average Rating
                      if (reviews.isNotEmpty) ...[
                        Row(
                          children: [
                            ...List.generate(5, (index) {
                              final avgRating = _calculateAverageRating(reviews);
                              return Icon(
                                index < avgRating.floor()
                                    ? Icons.star
                                    : index < avgRating
                                        ? Icons.star_half
                                        : Icons.star_border,
                                color: Colors.amber,
                                size: 24,
                              );
                            }),
                            const SizedBox(width: 8),
                            Text(
                              '${_calculateAverageRating(reviews).toStringAsFixed(1)} (${reviews.length} ${reviews.length == 1 ? 'review' : 'reviews'})',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Add to Cart Button
                      if (widget.product.isAvailable)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final cartItem = CartItem(
                                productId: widget.product.id,
                                name: widget.product.name,
                                price: widget.product.price,
                                quantity: 1,
                                imageUrl: widget.product.imageUrl,
                                category: widget.product.category,
                              );
                              context.read<CartCubit>().addItem(cartItem);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${widget.product.name} added to cart'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.shopping_cart),
                            label: const Text('Add to Cart'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      const SizedBox(height: 32),

                      // Leave a Review Section
                      Text(
                        'Leave a Review',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Star Rating Selector
                      Row(
                        children: List.generate(5, (index) {
                          return IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedRating = index + 1;
                              });
                            },
                            icon: Icon(
                              index < _selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 32,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Comment Input
                      TextField(
                        controller: _commentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Write your review here...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Image Picker
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Add Photo'),
                          ),
                          if (_selectedImage != null) ...[
                            const SizedBox(width: 12),
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImage!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: -8,
                                  top: -8,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.all(4),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImage = null;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Submit Review Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _submitReview,
                          child: _isUploading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Submit Review'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Reviews Section
                      Text(
                        'Reviews (${reviews.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),

                      if (state is ShopLoading && reviews.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (reviews.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(Icons.comment_outlined,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  'No reviews yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to review!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...reviews.map((review) => _buildReviewCard(review)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTranslateRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedLang,
            decoration: const InputDecoration(
              labelText: 'Translate to',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _languages.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (val) => setState(() => _selectedLang = val ?? 'fr'),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _translating ? null : _translateDescription,
          icon: _translating
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.translate),
          label: const Text('Translate'),
        ),
      ],
    );
  }

  String _selectedLang = 'fr';
  final Map<String, String> _languages = {
    'fr': 'French',
    'es': 'Spanish',
    'de': 'German',
    'it': 'Italian',
    'ar': 'Arabic',
    'pt': 'Portuguese',
  };

  Future<void> _translateDescription() async {
    setState(() => _translating = true);
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/translate');
      final resp = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'q': widget.product.description,
              'target': _selectedLang,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final translations = data['translations'] as List<dynamic>?;
        if (translations != null && translations.isNotEmpty) {
          setState(() {
            _translatedDescription = translations.first['translatedText'] as String?;
          });
        } else {
          _showSnack('No translation returned');
        }
      } else {
        _showSnack('Translation failed: ${resp.statusCode}');
      }
    } on TimeoutException {
      _showSnack('Translation timed out. Is the server running at ${ApiConfig.baseUrl}?');
    } catch (e) {
      _showSnack('Translate error: $e');
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  Future<void> _convertPrice(String targetCurrency) async {
    if (_converting) return;
    setState(() {
      _converting = true;
      _selectedCurrency = targetCurrency;
    });

    try {
      final baseUrl = ApiConfig.baseUrl;
      final url = Uri.parse('$baseUrl/convert?amount=${widget.product.price}&from=USD&to=$targetCurrency');
      
      final resp = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        if (mounted) {
          setState(() => _convertedPrice = json['converted']);
        }
      } else {
        _showSnack('Conversion failed: ${resp.statusCode}');
      }
    } on TimeoutException {
      _showSnack('Conversion timed out. Check server connection.');
    } catch (e) {
      _showSnack('Conversion error: $e');
    } finally {
      if (mounted) setState(() => _converting = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    review.userName ?? 'Anonymous',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (review.imageUrl != null && review.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  review.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(review.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(fs.Timestamp timestamp) {
    try {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }
}

