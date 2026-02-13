import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:url_launcher/url_launcher.dart' as launcher;
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../routes/app_routes.dart';

/// Help & Support Screen
/// Provides help and support options
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: TextStyle(
            fontSize: ScreenSize.isSmallPhone ? ScreenSize.textLarge : ScreenSize.headingSmall,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: ScreenSize.isSmallPhone ? 50 : 60,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section
            _buildHeroSection(),
            
            // Content
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ScreenSize.paddingMedium,
                vertical: ScreenSize.spacingMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Quick Help', Icons.flash_on_rounded),
                  SizedBox(height: ScreenSize.spacingSmall),
                  _buildQuickActions(),
                  SizedBox(height: ScreenSize.spacingLarge),
                  
                  // Contact Support
                  _buildSectionTitle('Contact Us', Icons.contact_support_rounded),
                  SizedBox(height: ScreenSize.spacingSmall),
                  _buildContactCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Live Chat',
                    subtitle: 'Chat with our support team 24/7',
                    onTap: () => Get.toNamed(AppRoutes.chat),
                  ),
                  _buildContactCard(
                    icon: Icons.email_outlined,
                    title: 'Email Support',
                    subtitle: 'support@example.com',
                    onTap: () => _launchEmail('support@example.com'),
                  ),
                  _buildContactCard(
                    icon: Icons.phone_outlined,
                    title: 'Phone Support',
                    subtitle: '+1 (555) 123-4567 • Mon-Sat 9AM-6PM',
                    onTap: () => _launchPhone('+15551234567'),
                  ),
                  SizedBox(height: ScreenSize.spacingLarge),
                  
                  // FAQ Section
                  _buildSectionTitle('Frequently Asked Questions', Icons.help_outline_rounded),
                  SizedBox(height: ScreenSize.spacingSmall),
                  _buildFAQItem(
                    question: 'How do I place an order?',
                    answer: 'Browse products, add items to cart, and proceed to checkout. Follow the steps to complete your order.',
                  ),
                  _buildFAQItem(
                    question: 'What payment methods are accepted?',
                    answer: 'We accept credit/debit cards, PayPal, and Cash on Delivery (COD).',
                  ),
                  _buildFAQItem(
                    question: 'How long does shipping take?',
                    answer: 'Standard shipping takes 3-5 business days. Express shipping is available for faster delivery.',
                  ),
                  _buildFAQItem(
                    question: 'Can I cancel my order?',
                    answer: 'Yes, you can cancel your order within 24 hours of placing it. Contact support for assistance.',
                  ),
                  _buildFAQItem(
                    question: 'How do I track my order?',
                    answer: 'You will receive a tracking number via email once your order ships. Use it to track your package. You can also check your order status in the "My Orders" section of the app.',
                  ),
                  _buildFAQItem(
                    question: 'What is your return policy?',
                    answer: 'You can return items within 7 days of delivery. Items must be unused, in original packaging with tags attached. Refunds will be processed within 5-7 business days after we receive the returned item.',
                  ),
                  _buildFAQItem(
                    question: 'How do I change my delivery address?',
                    answer: 'You can update your delivery address before checkout. Go to your profile, select "Addresses", and add or edit your address. You can also manage addresses during checkout.',
                  ),
                  _buildFAQItem(
                    question: 'Do you offer free shipping?',
                    answer: 'Yes! We offer free shipping on orders above ₹500. For orders below ₹500, a nominal shipping charge applies.',
                  ),
                  _buildFAQItem(
                    question: 'How can I apply a coupon code?',
                    answer: 'During checkout, you\'ll see an option to apply a coupon code. Enter your code and click "Apply". Valid coupons will show the discount amount immediately.',
                  ),
                  _buildFAQItem(
                    question: 'What if I receive a damaged product?',
                    answer: 'If you receive a damaged product, please contact our support team within 48 hours of delivery. We\'ll arrange a replacement or full refund. Please keep the product and packaging for inspection.',
                  ),
                  SizedBox(height: ScreenSize.spacingLarge),
                  
                  // Additional Help
                  _buildSectionTitle('Additional Resources', Icons.info_outline_rounded),
                  SizedBox(height: ScreenSize.spacingSmall),
                  _buildHelpTile(
                    icon: Icons.article_outlined,
                    title: 'Terms & Conditions',
                    onTap: () => Get.toNamed(AppRoutes.termsConditions),
                  ),
                  _buildHelpTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
                  ),
                  _buildHelpTile(
                    icon: Icons.assignment_return,
                    title: 'Return Policy',
                    onTap: () => Get.toNamed(AppRoutes.returnPolicy),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ScreenSize.paddingMedium,
        vertical: ScreenSize.isSmallPhone ? ScreenSize.spacingMedium : ScreenSize.spacingLarge,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(ScreenSize.isSmallPhone ? 12 : 16),
            decoration: BoxDecoration(
              color: AppColors.textWhite.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.support_agent_rounded,
              size: ScreenSize.isSmallPhone ? 32 : 48,
              color: AppColors.textWhite,
            ),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: ScreenSize.isSmallPhone ? ScreenSize.headingSmall : ScreenSize.headingMedium,
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'We\'re here 24/7 to assist you',
            style: TextStyle(
              fontSize: ScreenSize.isSmallPhone ? ScreenSize.textSmall : ScreenSize.textMedium,
              color: AppColors.textWhite.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Chat Now',
            subtitle: 'Instant help',
            color: AppColors.primary,
            onTap: () => Get.toNamed(AppRoutes.chat),
          ),
        ),
        SizedBox(width: ScreenSize.spacingSmall),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.phone_outlined,
            title: 'Call Us',
            subtitle: 'Phone support',
            color: AppColors.success,
            onTap: () => _launchPhone('+15551234567'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ScreenSize.isSmallPhone ? ScreenSize.spacingSmall : ScreenSize.spacingMedium,
          horizontal: ScreenSize.spacingSmall,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(ScreenSize.borderRadiusMedium),
          boxShadow: AppColors.cardShadow,
          border: Border.all(
            color: color.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: ScreenSize.isSmallPhone ? 20 : 24,
              ),
            ),
            SizedBox(height: ScreenSize.spacingSmall),
            Text(
              title,
              style: TextStyle(
                fontSize: ScreenSize.isSmallPhone ? ScreenSize.textSmall : ScreenSize.textMedium,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: ScreenSize.isSmallPhone ? ScreenSize.textExtraSmall : ScreenSize.textSmall,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: ScreenSize.spacingSmall),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: ScreenSize.isSmallPhone ? 18 : 22),
          SizedBox(width: ScreenSize.spacingSmall),
          Text(
            title,
            style: TextStyle(
              fontSize: ScreenSize.isSmallPhone ? ScreenSize.textLarge : ScreenSize.headingSmall,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: ScreenSize.spacingSmall),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.borderRadiusMedium),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ScreenSize.borderRadiusMedium),
          child: Padding(
            padding: EdgeInsets.all(ScreenSize.isSmallPhone ? 12 : 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: ScreenSize.isSmallPhone ? 20 : 24,
                  ),
                ),
                SizedBox(width: ScreenSize.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: ScreenSize.isSmallPhone ? ScreenSize.textMedium : ScreenSize.textLarge,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: ScreenSize.isSmallPhone ? ScreenSize.textSmall : ScreenSize.textMedium,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textTertiary,
                  size: ScreenSize.isSmallPhone ? 14 : 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Container(
      margin: EdgeInsets.only(bottom: ScreenSize.spacingSmall),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.borderRadiusMedium),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(
            horizontal: ScreenSize.paddingMedium,
            vertical: 4,
          ),
          childrenPadding: EdgeInsets.fromLTRB(
            ScreenSize.paddingMedium,
            0,
            ScreenSize.paddingMedium,
            ScreenSize.paddingMedium,
          ),
          leading: Icon(
            Icons.help_outline_rounded,
            color: AppColors.primary,
            size: ScreenSize.isSmallPhone ? 18 : 22,
          ),
          title: Text(
            question,
            style: TextStyle(
              fontSize: ScreenSize.isSmallPhone ? ScreenSize.textSmall : ScreenSize.textMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondary,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: ScreenSize.isSmallPhone ? ScreenSize.textSmall : ScreenSize.textMedium,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: ScreenSize.spacingSmall),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.borderRadiusMedium),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ScreenSize.borderRadiusMedium),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ScreenSize.paddingMedium,
              vertical: ScreenSize.isSmallPhone ? 10 : 12,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.primary,
                  size: ScreenSize.isSmallPhone ? 18 : 22,
                ),
                SizedBox(width: ScreenSize.spacingMedium),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: ScreenSize.isSmallPhone ? ScreenSize.textSmall : ScreenSize.textMedium,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: ScreenSize.isSmallPhone ? 18 : 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _launchEmail(String email) async {
    // TODO: Install url_launcher package for email functionality
    Get.snackbar('Info', 'Email: $email');
  }
  
  Future<void> _launchPhone(String phone) async {
    // TODO: Install url_launcher package for phone functionality
    Get.snackbar('Info', 'Phone: $phone');
  }
}

