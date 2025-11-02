import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:yourleague/User/features/shop/presentation/cubits/shop_cubit.dart';
import 'package:yourleague/User/features/shop/presentation/cubits/shop_states.dart';
import 'package:yourleague/User/features/shop/presentation/cubits/cart_cubit.dart';
import 'package:yourleague/User/features/shop/domain/entities/product.dart';
import 'package:yourleague/User/features/shop/domain/entities/review.dart';
import 'package:yourleague/User/features/shop/domain/entities/cart_item.dart';

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

  void _submitReview() {
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

    final currentUser = _firebaseAuth.currentUser;
    context.read<ShopCubit>().createReview(
          productId: widget.product.id,
          rating: _selectedRating,
          comment: _commentController.text.trim(),
          userName: currentUser?.email?.split('@').first,
        );

    // Clear form
    setState(() {
      _selectedRating = 0;
      _commentController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted successfully')),
    );
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
                          Text(
                            '\$${widget.product.price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
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
                        widget.product.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
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

                      // Submit Review Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitReview,
                          child: const Text('Submit Review'),
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

