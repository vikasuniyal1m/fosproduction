import 'package:flutter/material.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';

/// Return Policy Screen
class ReturnPolicyScreen extends StatelessWidget {
  const ReturnPolicyScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Return Policy',
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
              'Return & Refund Policy',
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
              title: '1. Return Eligibility',
              content: 'You can return most items within 7 days of delivery. To be eligible for a return:\n\n• Item must be unused and in the same condition as received\n• Item must be in original packaging with all tags attached\n• Item must include original receipt or proof of purchase\n• Item must not be damaged, altered, or missing parts\n• Item must not be a perishable, personalized, or intimate product',
            ),
            
            _buildSection(
              title: '2. Non-Returnable Items',
              content: 'The following items cannot be returned:\n\n• Perishable goods (food, beverages, flowers)\n• Personalized or custom-made products\n• Intimate or sanitary goods (underwear, swimwear)\n• Digital products (software, e-books, gift cards)\n• Items damaged by misuse or normal wear\n• Items without original packaging or tags\n• Items purchased during clearance sales (unless defective)',
            ),
            
            _buildSection(
              title: '3. How to Initiate a Return',
              content: 'To return an item:\n\n1. Log in to your account and go to "My Orders"\n2. Select the order containing the item you want to return\n3. Click "Return Item" and select the reason for return\n4. Fill out the return form with required details\n5. Print the return shipping label (if provided)\n6. Package the item securely in original packaging\n7. Ship the item back using the provided label or your preferred carrier\n\nYou will receive a confirmation email once we receive your return request.',
            ),
            
            _buildSection(
              title: '4. Return Shipping',
              content: 'Return shipping costs:\n\n• Free Returns: We provide free return shipping for defective or wrong items\n• Customer Pays: For change of mind returns, customer is responsible for return shipping costs\n• Return Label: We may provide a prepaid return label for eligible returns\n• Original Shipping: Original shipping charges are non-refundable unless the return is due to our error',
            ),
            
            _buildSection(
              title: '5. Processing Time',
              content: 'Return processing timeline:\n\n• Return Request: Processed within 1-2 business days\n• Item Inspection: 2-3 business days after we receive the item\n• Refund Processing: 5-7 business days after approval\n• Refund Credit: Appears in your account within 1-2 business days after processing\n\nTotal time: Approximately 10-14 business days from when we receive your return.',
            ),
            
            _buildSection(
              title: '6. Refund Methods',
              content: 'Refunds will be issued to the original payment method:\n\n• Credit/Debit Cards: Refunded to the original card (5-7 business days)\n• PayPal: Refunded to your PayPal account (3-5 business days)\n• Cash on Delivery: Refunded via bank transfer (7-10 business days)\n• Store Credit: Available immediately for exchange or future purchases\n\nIf the original payment method is no longer available, please contact customer support.',
            ),
            
            _buildSection(
              title: '7. Exchanges',
              content: 'We offer exchanges for:\n\n• Different size or color of the same product\n• Defective items replaced with the same product\n• Wrong items received\n\nTo exchange an item:\n1. Initiate a return for the original item\n2. Place a new order for the desired item\n3. We will process the refund once we receive the returned item\n\nNote: Exchanges are subject to product availability.',
            ),
            
            _buildSection(
              title: '8. Damaged or Defective Items',
              content: 'If you receive a damaged or defective item:\n\n• Contact us within 48 hours of delivery\n• Provide photos of the damage or defect\n• Keep the item and all packaging\n• We will arrange for a replacement or full refund\n• Return shipping is free for damaged/defective items\n• We may request the item to be returned for inspection',
            ),
            
            _buildSection(
              title: '9. Wrong Item Received',
              content: 'If you receive the wrong item:\n\n• Contact us immediately\n• Do not open or use the item\n• We will arrange for the correct item to be sent\n• Return shipping for the wrong item is free\n• You may keep the wrong item or return it\n• Full refund available if the correct item is out of stock',
            ),
            
            _buildSection(
              title: '10. Late or Missing Refunds',
              content: 'If you haven\'t received your refund:\n\n• Check your bank account or payment method\n• Contact your bank or payment provider (processing may take time)\n• Check your email for refund confirmation\n• Contact us with your order number if more than 14 business days have passed\n\nWe will investigate and resolve the issue promptly.',
            ),
            
            _buildSection(
              title: '11. Return Conditions',
              content: 'Items must be returned in:\n\n• Original condition (unused, unworn, unwashed)\n• Original packaging with all tags and labels\n• All accessories and free gifts included\n• Original receipt or invoice\n\nItems not meeting these conditions may be rejected or subject to a restocking fee.',
            ),
            
            _buildSection(
              title: '12. Restocking Fee',
              content: 'A restocking fee may apply in the following cases:\n\n• Item returned in used or damaged condition\n• Missing original packaging or accessories\n• Returned after the 7-day return period\n• Items that cannot be resold as new\n\nThe restocking fee is typically 15-20% of the item price and will be deducted from your refund.',
            ),
            
            _buildSection(
              title: '13. Sale Items',
              content: 'Items purchased during sales or promotions:\n\n• Are eligible for return within the standard return period\n• Refund will be for the sale price paid\n• Cannot be returned for full original price\n• Subject to the same return conditions as regular items',
            ),
            
            _buildSection(
              title: '14. Contact for Returns',
              content: 'For return-related inquiries, contact us at:\n\nEmail: returns@example.com\nPhone: +1 (555) 123-4567\nLive Chat: Available 24/7 in the app\n\nPlease have your order number ready when contacting us for faster service.',
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

