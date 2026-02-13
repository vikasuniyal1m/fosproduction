import 'package:flutter/material.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';

/// Terms & Conditions Screen
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Terms & Conditions',
          style: TextStyle(fontSize: ScreenSize.headingMedium),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: ScreenSize.buttonHeightLarge,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ScreenSize.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms & Conditions',
              style: TextStyle(
                fontSize: ScreenSize.headingLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: ScreenSize.spacingSmall),
            Text(
              'Last Updated: November 27, 2025',
              style: TextStyle(
                fontSize: ScreenSize.textSmall,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: ScreenSize.spacingExtraLarge),
            
            _buildSection(
              title: '1. Acceptance of Terms',
              content: 'By accessing and using this e-commerce application, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
            ),
            
            _buildSection(
              title: '2. Use License',
              content: 'Permission is granted to temporarily download one copy of the materials on this app for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n• Modify or copy the materials\n• Use the materials for any commercial purpose or for any public display\n• Attempt to decompile or reverse engineer any software contained in the app\n• Remove any copyright or other proprietary notations from the materials',
            ),
            
            _buildSection(
              title: '3. Account Registration',
              content: 'To make purchases on our platform, you must create an account. You agree to:\n\n• Provide accurate, current, and complete information during registration\n• Maintain and update your information to keep it accurate\n• Maintain the security of your password and identification\n• Accept all responsibility for activities that occur under your account\n• Notify us immediately of any unauthorized use of your account',
            ),
            
            _buildSection(
              title: '4. Product Information',
              content: 'We strive to provide accurate product descriptions, images, and pricing. However, we do not warrant that product descriptions or other content is accurate, complete, reliable, current, or error-free. If a product offered by us is not as described, your sole remedy is to return it in unused condition.',
            ),
            
            _buildSection(
              title: '5. Pricing and Payment',
              content: 'All prices are displayed in the currency specified and are subject to change without notice. We reserve the right to refuse or cancel any order placed for a product listed at an incorrect price. Payment must be received before we ship your order. We accept various payment methods including credit cards, debit cards, and cash on delivery.',
            ),
            
            _buildSection(
              title: '6. Shipping and Delivery',
              content: 'We will make every effort to deliver products within the estimated timeframe. However, delivery dates are estimates only and we cannot guarantee delivery by a specific date. Risk of loss and title for products purchased pass to you upon delivery to the carrier. We are not responsible for delays caused by the carrier or customs.',
            ),
            
            _buildSection(
              title: '7. Returns and Refunds',
              content: 'You may return most items within 7 days of delivery. Items must be unused, in original packaging with tags attached. To be eligible for a return, your item must be in the same condition that you received it. Refunds will be processed within 5-7 business days after we receive and inspect the returned item.',
            ),
            
            _buildSection(
              title: '8. Prohibited Uses',
              content: 'You may not use our service:\n\n• For any unlawful purpose or to solicit others to perform unlawful acts\n• To violate any international, federal, provincial, or state regulations, rules, laws, or local ordinances\n• To infringe upon or violate our intellectual property rights or the intellectual property rights of others\n• To harass, abuse, insult, harm, defame, slander, disparage, intimidate, or discriminate\n• To submit false or misleading information\n• To upload or transmit viruses or any other type of malicious code',
            ),
            
            _buildSection(
              title: '9. Intellectual Property',
              content: 'The service and its original content, features, and functionality are and will remain the exclusive property of the Company and its licensors. The service is protected by copyright, trademark, and other laws. Our trademarks and trade dress may not be used in connection with any product or service without our prior written consent.',
            ),
            
            _buildSection(
              title: '10. Limitation of Liability',
              content: 'In no event shall the Company, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your use of the service.',
            ),
            
            _buildSection(
              title: '11. Indemnification',
              content: 'You agree to defend, indemnify, and hold harmless the Company and its licensee and licensors, and their employees, contractors, agents, officers and directors, from and against any and all claims, damages, obligations, losses, liabilities, costs or debt, and expenses (including but not limited to attorney\'s fees).',
            ),
            
            _buildSection(
              title: '12. Governing Law',
              content: 'These Terms shall be interpreted and governed by the laws of India, without regard to its conflict of law provisions. Our failure to enforce any right or provision of these Terms will not be considered a waiver of those rights.',
            ),
            
            _buildSection(
              title: '13. Changes to Terms',
              content: 'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material, we will provide at least 30 days notice prior to any new terms taking effect. What constitutes a material change will be determined at our sole discretion.',
            ),
            
            _buildSection(
              title: '14. Contact Information',
              content: 'If you have any questions about these Terms & Conditions, please contact us at:\n\nEmail: support@example.com\nPhone: +1 (555) 123-4567\nAddress: [Your Company Address]',
            ),
            
            SizedBox(height: ScreenSize.spacingExtraLarge),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: EdgeInsets.only(bottom: ScreenSize.spacingLarge),
      padding: EdgeInsets.all(ScreenSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: ScreenSize.textLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Text(
            content,
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

