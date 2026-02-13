import 'package:flutter/material.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';

/// Privacy Policy Screen
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
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
              'Privacy Policy',
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
              title: '1. Introduction',
              content: 'We respect your privacy and are committed to protecting your personal data. This privacy policy explains how we collect, use, and safeguard your information when you use our e-commerce application.',
            ),
            
            _buildSection(
              title: '2. Information We Collect',
              content: 'We collect information that you provide directly to us, including:\n\n• Personal Information: Name, email address, phone number, shipping address, billing address\n• Account Information: Username, password, profile picture\n• Location Data: We collect precise location data (GPS) to show nearby stores, calculate delivery estimates, and automatically fill shipping addresses. This is only collected with your explicit consent.\n• Device Media: We may access your camera or photo library to scan payment cards or save order receipts, with your permission.\n• Payment Information: Credit/debit card details, payment method preferences (stored securely)\n• Order Information: Purchase history, order details, preferences\n• Communication Data: Messages sent through our support channels\n• Device Information: IP address, device type, operating system, browser type\n• Usage Data: How you interact with our app, pages visited, features used',
            ),
            
            _buildSection(
              title: '3. How We Use Your Information',
              content: 'We use the collected information for:\n\n• Processing and fulfilling your orders\n• Managing your account and providing customer support\n• Sending order confirmations, shipping updates, and invoices\n• Processing payments and preventing fraud\n• Personalizing your shopping experience\n• Sending promotional emails and marketing communications (with your consent)\n• Improving our services and developing new features\n• Analyzing usage patterns and trends\n• Complying with legal obligations',
            ),
            
            _buildSection(
              title: '4. Information Sharing',
              content: 'We do not sell your personal information. We may share your information with:\n\n• Service Providers: Payment processors, shipping companies, email service providers\n• Business Partners: Trusted partners who assist in operating our platform\n• Legal Requirements: When required by law or to protect our rights\n• Business Transfers: In case of merger, acquisition, or sale of assets\n\nAll third parties are required to maintain the confidentiality of your information.',
            ),
            
            _buildSection(
              title: '5. Data Security',
              content: 'We implement appropriate technical and organizational security measures to protect your personal data against unauthorized access, alteration, disclosure, or destruction. These measures include:\n\n• SSL encryption for data transmission\n• Secure payment processing\n• Regular security audits\n• Access controls and authentication\n• Data backup and recovery procedures\n\nHowever, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.',
            ),
            
            _buildSection(
              title: '6. Data Retention',
              content: 'We retain your personal information for as long as necessary to fulfill the purposes outlined in this policy, unless a longer retention period is required or permitted by law. Account information is retained while your account is active. Order information is retained for legal and accounting purposes.',
            ),
            
            _buildSection(
              title: '7. Your Rights',
              content: 'You have the right to:\n\n• Access your personal data\n• Correct inaccurate or incomplete data\n• Request deletion of your data\n• Object to processing of your data\n• Request restriction of processing\n• Data portability\n• Withdraw consent at any time\n• Lodge a complaint with a supervisory authority\n\nTo exercise these rights, please contact us using the information provided below.',
            ),
            
            _buildSection(
              title: '8. Cookies and Tracking',
              content: 'We use cookies and similar tracking technologies to track activity on our app and store certain information. Cookies are files with a small amount of data which may include an anonymous unique identifier. You can instruct your browser to refuse all cookies or to indicate when a cookie is being sent.',
            ),
            
            _buildSection(
              title: '9. Third-Party Links',
              content: 'Our app may contain links to third-party websites or services. We are not responsible for the privacy practices of these external sites. We encourage you to review the privacy policies of any third-party sites you visit.',
            ),
            
            _buildSection(
              title: '10. Children\'s Privacy',
              content: 'Our service is not intended for children under the age of 18. We do not knowingly collect personal information from children. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately.',
            ),
            
            _buildSection(
              title: '11. International Data Transfers',
              content: 'Your information may be transferred to and maintained on computers located outside of your state, province, country, or other governmental jurisdiction where data protection laws may differ. By using our service, you consent to the transfer of your information to these facilities.',
            ),
            
            _buildSection(
              title: '12. Changes to Privacy Policy',
              content: 'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date. You are advised to review this Privacy Policy periodically for any changes.',
            ),
            
            _buildSection(
              title: '13. Contact Us',
              content: 'If you have any questions about this Privacy Policy, please contact us at:\n\nEmail: privacy@example.com\nPhone: +1 (555) 123-4567\nAddress: [Your Company Address]\n\nData Protection Officer: dpo@example.com',
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

