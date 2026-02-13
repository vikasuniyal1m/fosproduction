import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/screen_size.dart';
import '../utils/app_colors.dart';

/// Review Dialog Widget
/// Dialog for submitting product reviews
class ReviewDialogWithCallback extends StatefulWidget {
  final int productId;
  final String productName;
  final Future<bool> Function(int rating, String title, String comment) onSubmit;
  
  const ReviewDialogWithCallback({
    super.key,
    required this.productId,
    required this.productName,
    required this.onSubmit,
  });
  
  @override
  State<ReviewDialogWithCallback> createState() => _ReviewDialogWithCallbackState();
}

class _ReviewDialogWithCallbackState extends State<ReviewDialogWithCallback> {
  int _selectedRating = 0;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  
  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }
  
  void _submitReview() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRating == 0) {
        Get.snackbar(
          'Error',
          'Please select a rating',
          backgroundColor: AppColors.errorLight,
          colorText: AppColors.error,
        );
        return;
      }
      
      setState(() {
        _isSubmitting = true;
      });
      
      try {
        final success = await widget.onSubmit(
          _selectedRating,
          _titleController.text.trim(),
          _commentController.text.trim(),
        );
        
        if (!mounted) return;
        
        if (success) {
          // Close dialog immediately on success
          // Use Navigator to ensure dialog closes properly
          Navigator.of(context, rootNavigator: true).pop();
        } else {
          // Reset submitting state on error
          setState(() {
            _isSubmitting = false;
          });
        }
      } catch (e) {
        // Handle any exceptions and reset submitting state
        print('Error submitting review: $e');
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
          Get.snackbar(
            'Error',
            'Failed to submit review. Please try again.',
            backgroundColor: AppColors.errorLight,
            colorText: AppColors.error,
            duration: const Duration(seconds: 3),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
      ),
      child: Container(
        padding: EdgeInsets.all(ScreenSize.spacingMedium),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Write a Review',
                        style: TextStyle(
                          fontSize: ScreenSize.headingMedium,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isSubmitting ? null : () => Get.back(),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                SizedBox(height: ScreenSize.spacingSmall),
                Text(
                  widget.productName,
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: ScreenSize.spacingMedium),
                
                // Rating Selection
                Text(
                  'Rating *',
                  style: TextStyle(
                    fontSize: ScreenSize.textMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: ScreenSize.spacingSmall),
                Row(
                  children: List.generate(5, (index) {
                    final rating = index + 1;
                    return GestureDetector(
                      onTap: _isSubmitting ? null : () {
                        setState(() {
                          _selectedRating = rating;
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.only(right: ScreenSize.spacingSmall),
                        child: Icon(
                          rating <= _selectedRating ? Icons.star : Icons.star_border,
                          color: rating <= _selectedRating 
                              ? Colors.amber 
                              : AppColors.textSecondary,
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ),
                SizedBox(height: ScreenSize.spacingMedium),
                
                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Review Title (Optional)',
                    hintText: 'Give your review a title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                    ),
                    enabled: !_isSubmitting,
                  ),
                  maxLength: 100,
                ),
                SizedBox(height: ScreenSize.spacingMedium),
                
                // Comment Field
                TextFormField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    labelText: 'Your Review *',
                    hintText: 'Share your experience with this product...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                    ),
                    enabled: !_isSubmitting,
                  ),
                  maxLines: 5,
                  maxLength: 500,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please write your review';
                    }
                    if (value.trim().length < 10) {
                      return 'Review must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: ScreenSize.spacingMedium),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingMedium),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit Review'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

