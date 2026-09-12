import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_controller.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'screen_common.dart';

// =========================================================================
// 1. PRODUCT DETAIL VIEW (Matching ProductDetailView.tsx)
// =========================================================================
class ProductDetailView extends StatefulWidget {
  const ProductDetailView({super.key, required this.product, this.onAdd});
  final Product product;
  final VoidCallback? onAdd;

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  int quantity = 1;
  int activeImage = 0;
  bool isFavorite = false;
  String selectedColor = 'أحمر كلاسيكي';
  String selectedSize = 'L';
  bool _loading = true;
  Map<String, dynamic>? _detail;

  static const _availableColors = [
    ('أحمر كلاسيكي', Color(0xFF9B1344)),
    ('كحلي داكن', Color(0xFF1E293B)),
    ('أخضر زيتي', Color(0xFF065F46)),
    ('أسود ملكي', Color(0xFF0F172A)),
  ];

  static const _availableSizes = ['S', 'M', 'L', 'XL', 'XXL'];

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final app = context.read<AppController>();
      final data = await app.api.productDetail(widget.product.id);
      if (mounted) {
        setState(() {
          _detail = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseProduct = widget.product;
    final d = _detail ?? {};
    final name = d['name']?.toString().isNotEmpty == true ? d['name'].toString() : baseProduct.name;
    final brand = d['brand']?.toString().isNotEmpty == true ? d['brand'].toString() : (baseProduct.brand.isNotEmpty ? baseProduct.brand : 'شبيك بلس');
    final description = d['description']?.toString().isNotEmpty == true ? d['description'].toString() : (baseProduct.description ?? 'منتج أصلي موثق معتمد بجودة عالية وضمان شامل في سوق شبيك.');
    final vendorName = d['vendor_name']?.toString().isNotEmpty == true ? d['vendor_name'].toString() : (baseProduct.vendorName.isNotEmpty ? baseProduct.vendorName : 'متجر زيزو للأزياء');
    final currency = d['currency']?.toString() ?? baseProduct.currency;
    final sku = d['sku']?.toString() ?? 'SKU-${baseProduct.id + 10420}';
    final price = d['price'] != null ? (double.tryParse('${d['price']}') ?? baseProduct.price) : baseProduct.price;
    final salePrice = d['sale_price'] != null ? double.tryParse('${d['sale_price']}') : baseProduct.salePrice;
    final stock = d['stock'] != null ? (int.tryParse('${d['stock']}') ?? baseProduct.stock) : (baseProduct.stock > 0 ? baseProduct.stock : 25);
    final rating = d['rating'] != null ? (double.tryParse('${d['rating']}') ?? baseProduct.rating) : 4.9;
    final reviewsCount = d['reviews_count'] != null ? (int.tryParse('${d['reviews_count']}') ?? baseProduct.reviewsCount) : 48;

    final images = <String>[];
    final mainImg = d['image']?.toString() ?? baseProduct.image;
    if (mainImg != null && mainImg.isNotEmpty) images.add(mainImg);
    final rawGallery = d['gallery'] ?? d['images'] ?? baseProduct.gallery;
    if (rawGallery is List) {
      for (final img in rawGallery) {
        final str = img is Map ? '${img['image'] ?? img['url'] ?? ''}' : '$img';
        if (str.isNotEmpty && !images.contains(str)) images.add(str);
      }
    }
    if (images.isEmpty && baseProduct.image != null && baseProduct.image!.isNotEmpty) {
      images.add(baseProduct.image!);
    }

    final isDiscounted = salePrice != null && salePrice < price;
    final double currentPrice = (salePrice ?? price).toDouble();
    final discountPercent = isDiscounted && price > 0 ? (((price - salePrice) / price) * 100).round() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
        actions: [
          // Store badge
          InkWell(
            onTap: () => _openStore(vendorName, baseProduct.vendorId),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront_rounded, size: 13, color: Color(0xFF8B1D3B)),
                  const SizedBox(width: 4),
                  Text(
                    vendorName,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8B1D3B)),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => isFavorite = !isFavorite);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFavorite ? 'تمت إضافة المنتج إلى المفضلة' : 'تمت إزالة المنتج من المفضلة'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? const Color(0xFFF43F5E) : const Color(0xFF475569),
              size: 22,
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'https://shopik.alattab.site/products/${baseProduct.id}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم نسخ رابط المنتج بنجاح'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.share_outlined, color: Color(0xFF475569), size: 20),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDetail,
        color: const Color(0xFF8B1D3B),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
          children: [
            if (_loading) const LinearProgressIndicator(color: Color(0xFF8B1D3B), minHeight: 2),

            // 1. Big Hero Image Gallery
            _buildImageGallery(images),
            const SizedBox(height: 14),

            // 2. Product Details & Price Card
            _buildProductInfoCard(
              name: name,
              brand: brand,
              sku: sku,
              rating: rating,
              reviewsCount: reviewsCount,
              currentPrice: currentPrice,
              originalPrice: price,
              isDiscounted: isDiscounted,
              discountPercent: discountPercent,
              currency: currency,
              stock: stock,
            ),
            const SizedBox(height: 12),

            // 3. Variant Selectors (Color & Size)
            _buildVariantsCard(),
            const SizedBox(height: 12),

            // 4. Quantity Selector Card
            _buildQuantityCard(stock),
            const SizedBox(height: 12),

            // 5. Merchant Card (Store Profile)
            _buildMerchantCard(vendorName, baseProduct.vendorId),
            const SizedBox(height: 12),

            // 6. Guarantee & Shipping Card
            _buildGuaranteeCard(),
            const SizedBox(height: 12),

            // 7. Specifications and Description Card
            _buildDescriptionCard(description, d),
          ],
        ),
      ),
      // 8. Fixed Bottom Action Bar
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Total Calculation
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الإجمالي المحدد:',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                  Text(
                    money(currentPrice * quantity, currency),
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF8B1D3B),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Add to Cart Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    for (int i = 0; i < quantity; i++) {
                      widget.onAdd?.call();
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تمت إضافة $quantity من "$name" إلى السلة'),
                        backgroundColor: const Color(0xFF059669),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF1F2),
                    foregroundColor: const Color(0xFF8B1D3B),
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('إضافة للسلة', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 8),
              // Buy Now Button
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    widget.onAdd?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('جاري الانتقال للدفع...'),
                        backgroundColor: Color(0xFF8B1D3B),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1D3B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.flash_on_rounded, size: 18),
                  label: const Text('شراء الآن', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers for ProductDetailView ---
  Widget _buildImageGallery(List<String> images) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Main Preview
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: images.isNotEmpty
                        ? Image.network(
                            absoluteUrl(images[activeImage < images.length ? activeImage : 0]),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported_outlined, size: 50, color: Color(0xFF94A3B8)),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image_outlined, size: 50, color: Color(0xFF94A3B8)),
                          ),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x990F172A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${activeImage + 1} / ${images.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (images.length > 1) ...[
            const SizedBox(height: 10),
            // Thumbnails Row
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse: true,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final active = activeImage == i;
                  return InkWell(
                    onTap: () => setState(() => activeImage = i),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active ? const Color(0xFF8B1D3B) : const Color(0xFFE2E8F0),
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          absoluteUrl(images[i]),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.black26),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductInfoCard({
    required String name,
    required String brand,
    required String sku,
    required double rating,
    required int reviewsCount,
    required double currentPrice,
    required double originalPrice,
    required bool isDiscounted,
    required int discountPercent,
    required String currency,
    required int stock,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Text(
                  brand,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF8B1D3B)),
                ),
              ),
              Row(
                children: [
                  Text('كود: $sku', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: sku));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ كود المنتج'), duration: Duration(seconds: 1)),
                      );
                    },
                    child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          // Ratings and Sales
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 4),
              Text(
                '($reviewsCount تقييم)',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: stock > 0 ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  stock > 0 ? 'متوفر بالمخزون ($stock)' : 'نفذت الكمية',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: stock > 0 ? const Color(0xFF065F46) : const Color(0xFFE11D48),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          // Price Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                money(currentPrice, currency),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF8B1D3B),
                ),
              ),
              if (isDiscounted) ...[
                const SizedBox(width: 8),
                Text(
                  money(originalPrice, currency),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF94A3B8),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'وفر $discountPercent%',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariantsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color Select
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('اختر اللون:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text(selectedColor, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B1D3B))),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _availableColors.map((col) {
              final active = selectedColor == col.$1;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: col.$2, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(col.$1, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: active ? Colors.white : const Color(0xFF334155))),
                  ],
                ),
                selected: active,
                selectedColor: const Color(0xFF8B1D3B),
                backgroundColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: active ? const Color(0xFF8B1D3B) : const Color(0xFFE2E8F0)),
                ),
                onSelected: (_) => setState(() => selectedColor = col.$1),
              );
            }).toList(),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          // Size Select
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('المقاس:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('المحدد: $selectedSize', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B1D3B))),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _availableSizes.map((sz) {
              final active = selectedSize == sz;
              return ChoiceChip(
                label: Text(
                  sz,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: active ? Colors.white : const Color(0xFF334155),
                  ),
                ),
                selected: active,
                selectedColor: const Color(0xFF8B1D3B),
                backgroundColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: active ? const Color(0xFF8B1D3B) : const Color(0xFFE2E8F0)),
                ),
                onSelected: (_) => setState(() => selectedSize = sz),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityCard(int stock) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'الكمية المطلوبة:',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                  icon: const Icon(Icons.remove_rounded, size: 18),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ),
                IconButton(
                  onPressed: quantity < stock ? () => setState(() => quantity++) : null,
                  icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF059669)),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantCard(String vendorName, int? vendorId) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFF8B1D3B), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendorName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: const [
                        Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 14),
                        SizedBox(width: 3),
                        Text(
                          'متجر موثوق ومعتمد في سوق شبيك',
                          style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _openStore(vendorName, vendorId),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF8B1D3B)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('زيارة المتجر', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF8B1D3B))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('جاري الاتصال بـ $vendorName...')),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.phone_in_talk_rounded, size: 15, color: Color(0xFF334155)),
                        SizedBox(width: 6),
                        Text('اتصال هاتفي', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OrderChatScreen(orderId: widget.product.id, title: 'محادثة $vendorName')),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.chat_bubble_outline_rounded, size: 15, color: Color(0xFF2563EB)),
                        SizedBox(width: 6),
                        Text('محادثة المتجر', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuaranteeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_outlined, color: Color(0xFF059669), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'ضمان شبيك الذهبي للمنتجات',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                ),
                SizedBox(height: 3),
                Text(
                  'ضمان استبدال أو استرجاع خلال 3 أيام مع فحص الشحنة فور الاستلام وتوصيل لباب المنزل.',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF047857), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(String description, Map<String, dynamic> detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, color: Color(0xFF8B1D3B), size: 18),
              SizedBox(width: 6),
              Text(
                'وصف المنتج ومواصفاته',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.6),
          ),
        ],
      ),
    );
  }

  void _openStore(String vendorName, int? vendorId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreProfileView(
          vendor: {
            'id': vendorId ?? 1,
            'store_name': vendorName,
            'name': vendorName,
            'rating': 4.9,
          },
        ),
      ),
    );
  }
}

// =========================================================================
// 2. STORE PROFILE VIEW (Matching StoreProfileView.tsx)
// =========================================================================
class StoreProfileView extends StatefulWidget {
  const StoreProfileView({super.key, required this.vendor});
  final Map<String, dynamic> vendor;

  @override
  State<StoreProfileView> createState() => _StoreProfileViewState();
}

class _StoreProfileViewState extends State<StoreProfileView> {
  String selectedTab = 'الكل';
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final storeName = '${widget.vendor['store_name'] ?? widget.vendor['name'] ?? 'متجر شبيك المعتمد'}';
    final vendorId = int.tryParse('${widget.vendor['id'] ?? widget.vendor['vendor_id'] ?? ''}');
    final rating = num.tryParse('${widget.vendor['rating'] ?? 4.9}') ?? 4.9;

    // Filter vendor products
    final q = search.text.trim().toLowerCase();
    final allVendorProducts = app.products.where((p) {
      final matchesVendor = vendorId != null ? (p.vendorId == vendorId || p.vendorName == storeName) : true;
      final text = '${p.name} ${p.brand} ${p.categories.join(' ')}'.toLowerCase();
      final matchesQuery = q.isEmpty || text.contains(q);
      return matchesVendor && matchesQuery;
    }).toList();

    // Fallback if no matching products
    final displayProducts = allVendorProducts.isNotEmpty ? allVendorProducts : app.products.take(6).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Header Banner
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF8B1D3B),
            leading: IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'https://shopik.alattab.site/stores/${widget.vendor['id'] ?? 1}'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ رابط المتجر')),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF9B1344), Color(0xFF881337), Color(0xFF4C0519)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                          border: Border.all(color: const Color(0xFFFECDD3), width: 2),
                        ),
                        child: Center(
                          child: Text(
                            storeName.replaceAll('متجر', '').trim().isNotEmpty
                                ? storeName.replaceAll('متجر', '').trim().substring(0, 1)
                                : 'م',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF8B1D3B)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeName,
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFDE047)),
                                      const SizedBox(width: 3),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(width: 3),
                                      const Text('(128 تقييم)', style: TextStyle(color: Colors.white70, fontSize: 9.5)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('متجر معتمد', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Store Stats and Contact
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // 4 Quick Stats
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        _StatItem(label: 'الموقع', value: 'صنعاء - التحرير', icon: Icons.location_on_outlined),
                        _StatItem(label: 'أوقات العمل', value: '9 ص - 10 م', icon: Icons.access_time_rounded),
                        _StatItem(label: 'سرعة الرد', value: 'خلال دقائق', icon: Icons.bolt_rounded),
                        _StatItem(label: 'التوصيل', value: '99% ناجح', icon: Icons.local_shipping_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderChatScreen(
                                  orderId: widget.vendor['id'] ?? 1,
                                  title: 'محادثة $storeName',
                                ),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF8B1D3B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                          label: const Text('محادثة المتجر', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('الاتصال بـ $storeName...')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF334155)),
                          label: const Text('اتصال', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF334155))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search Bar within store
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                        hintText: 'ابحث في منتجات هذا المتجر...',
                        hintStyle: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'منتجات المتجر (${displayProducts.length})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Products Grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.70,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final p = displayProducts[i];
                  final price = p.salePrice ?? p.price;
                  return InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProductDetailView(product: p)),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Container(
                                color: const Color(0xFFF1F5F9),
                                child: p.image != null && p.image!.isNotEmpty
                                    ? Image.network(
                                        absoluteUrl(p.image!),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (_, __, ___) => const Center(
                                          child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8)),
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
                                      ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(9),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      money(price, p.currency),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF8B1D3B)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B1D3B),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: displayProducts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8B1D3B)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// =========================================================================
// 3. ORDERS DETAIL VIEW (Matching OrdersDetailView.tsx)
// =========================================================================
class OrdersDetailView extends StatefulWidget {
  const OrdersDetailView({super.key});

  @override
  State<OrdersDetailView> createState() => _OrdersDetailViewState();
}

class _OrdersDetailViewState extends State<OrdersDetailView> {
  String filter = 'الكل';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();

    final orders = app.orders.where((o) {
      if (filter == 'قيد المعالجة') {
        return o.status != 'completed' && o.status != 'delivered';
      }
      if (filter == 'المكتملة') {
        return o.status == 'completed' || o.status == 'delivered';
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'سجل وطلبات المتجر',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
        actions: [
          IconButton(
            onPressed: app.refreshAll,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: ['الكل', 'قيد المعالجة', 'المكتملة'].map((tab) {
                final active = filter == tab;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => filter = tab),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF8B1D3B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          tab,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: active ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Orders List
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.inventory_2_outlined, size: 52, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 12),
                        Text(
                          'لا توجد طلبات في هذا القسم',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'تصفح متجر شبيك وأضف المنتجات لسلتك',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final o = orders[i];
                      final isCompleted = o.status == 'completed' || o.status == 'delivered';
                      final statusLabel = isCompleted
                          ? 'مكتمل ومستلم'
                          : (o.status == 'processing' ? 'قيد التجهيز والتغليف' : (o.status == 'shipped' ? 'قيد الشحن والتوصيل' : 'تم استلام الطلب'));
                      final statusColor = isCompleted
                          ? const Color(0xFF059669)
                          : (o.status == 'processing' ? const Color(0xFFD97706) : const Color(0xFF2563EB));

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isCompleted ? Icons.check_circle_outline_rounded : Icons.local_shipping_outlined,
                                    color: statusColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'طلب رقم #${o.number}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        o.createdAt ?? 'اليوم',
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 18, color: Color(0xFFF1F5F9)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'الإجمالي: ${money(o.total, o.currency)}',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF8B1D3B)),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B1D3B),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text(
                                    'عرض التفاصيل والمتابعة ←',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 4. ORDER DETAIL SCREEN (With 5-step visual tracking timeline & Order Editing)
// =========================================================================
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final int orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _orderData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final app = context.read<AppController>();
      final data = await app.api.orderDetail(widget.orderId);
      if (mounted) {
        setState(() {
          _orderData = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  void _showEditOrderDialog(Map<String, dynamic> currentData) {
    final addr = currentData['shipping_address'] is Map ? currentData['shipping_address'] as Map : {};
    final phoneCtrl = TextEditingController(text: '${addr['phone'] ?? currentData['customer_phone'] ?? ''}');
    final streetCtrl = TextEditingController(text: '${addr['street_details'] ?? addr['street'] ?? ''}');
    final notesCtrl = TextEditingController(text: '${currentData['notes'] ?? addr['notes'] ?? ''}');
    bool updating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('تعديل تفاصيل الطلب غير المؤكد', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 6),
              const Text('الطلب لم يتم تأكيده وشحنه بعد من قبل التاجر، يمكنك تعديل عنوان التوصيل ورقم التواصل.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم هاتف المستلم للتواصل',
                  prefixIcon: Icon(Icons.phone_iphone_rounded),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: streetCtrl,
                decoration: const InputDecoration(
                  labelText: 'عنوان التوصيل / تفاصيل الشارع والحي',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات إضافية للتوصيل',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: updating
                      ? null
                      : () async {
                          setSheetState(() => updating = true);
                          try {
                            final app = context.read<AppController>();
                            await app.api.updateOrderDetails(widget.orderId, {
                              'shipping_address': {
                                ...addr,
                                'phone': phoneCtrl.text.trim(),
                                'street_details': streetCtrl.text.trim(),
                              },
                              'notes': notesCtrl.text.trim(),
                            });
                            await app.refreshAll(quiet: true);
                            await _fetchOrder();
                            if (mounted) {
                              Navigator.pop(ctx);
                              showAppToast(context, 'تم تحديث تفاصيل الطلب بنجاح', isSuccess: true);
                            }
                          } catch (e) {
                            setSheetState(() => updating = false);
                            if (mounted) showAppToast(context, 'فشل تحديث الطلب: $e', isError: true);
                          }
                        },
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1D3B)),
                  child: updating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('حفظ التعديلات في الخادم', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إلغاء الطلب', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        content: const Text('هل أنت متأكد من رغبتك في إلغاء هذا الطلب واسترجاع قيمته للمحفظة؟', style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final app = context.read<AppController>();
      await app.api.cancelOrder(widget.orderId);
      await app.refreshAll(quiet: true);
      await _fetchOrder();
      if (mounted) {
        showAppToast(context, 'تم إلغاء الطلب بنجاح', isSuccess: true);
      }
    } catch (e) {
      if (mounted) showAppToast(context, 'فشل إلغاء الطلب: $e', isError: true);
    }
  }

  Future<void> _confirmReceived() async {
    try {
      final app = context.read<AppController>();
      await app.api.confirmReceived(widget.orderId);
      await app.refreshAll(quiet: true);
      await _fetchOrder();
      if (mounted) {
        showAppToast(context, 'تم تأكيد استلام الطلب بنجاح. شكراً لتسوقك معنا!', isSuccess: true);
      }
    } catch (e) {
      if (mounted) showAppToast(context, 'فشل تأكيد الاستلام: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF8B1D3B))),
      );
    }

    final d = _orderData ?? {};
    final List<Map<dynamic, dynamic>> items = d['items'] is List
        ? (d['items'] as List)
            .whereType<Map>()
            .map<Map<dynamic, dynamic>>((item) => Map<dynamic, dynamic>.from(item))
            .toList()
        : <Map<dynamic, dynamic>>[];
    final status = '${d['status'] ?? 'pending'}';
    final currency = '${d['currency'] ?? 'YER'}';
    final isPending = status == 'pending' || status == 'placed' || status == 'received' || status == 'new' || status == 'under_review';
    final isShipped = status == 'shipped' || status == 'out_for_delivery';
    final isCompleted = status == 'completed' || status == 'delivered';
    final orderNumber = d['order_number'] ?? d['number'] ?? widget.orderId;
    final total = num.tryParse('${d['total'] ?? 0}') ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'تفاصيل الطلب #$orderNumber',
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            onPressed: _fetchOrder,
            icon: const Icon(Icons.sync_rounded, color: Color(0xFF64748B)),
            tooltip: 'تحديث حالة الطلب من الخادم',
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // If order is unconfirmed / pending, show editable notice banner
          if (isPending) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: Color(0xFFD97706), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('الطلب غير مؤكد بعد من التاجر', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF92400E))),
                        SizedBox(height: 2),
                        Text('يمكنك تعديل بيانات التوصيل ورقم الهاتف أو إلغاء الطلب فوراً.', style: TextStyle(fontSize: 10.5, color: Color(0xFFB45309))),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _showEditOrderDialog(d),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF92400E),
                      side: const BorderSide(color: Color(0xFFD97706)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    child: const Text('تعديل الطلب', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 1. Five-step visual tracking timeline (Matching OrdersDetailView.tsx)
          _buildTimelineCard(status),
          const SizedBox(height: 12),

          // 2. Ordered Items List
          _buildItemsCard(items, currency),
          const SizedBox(height: 12),

          // 3. Shipping Address Card
          _buildAddressCard(d),
          const SizedBox(height: 12),

          // 4. Payment Summary Card
          _buildPaymentSummaryCard(total, currency),
          const SizedBox(height: 12),

          // 5. Actions Bar
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OrderChatScreen(orderId: widget.orderId, title: 'محادثة الطلب #$orderNumber')),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1D3B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('محادثة التاجر / المندوب', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 8),

              if (isShipped) ...[
                FilledButton.icon(
                  onPressed: _confirmReceived,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('تأكيد الاستلام', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 8),
              ],

              if (isPending) ...[
                OutlinedButton.icon(
                  onPressed: _cancelOrder,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('إلغاء الطلب', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(String status) {
    int activeStep = 1;
    if (status == 'processing') activeStep = 2;
    if (status == 'shipped') activeStep = 3;
    if (status == 'out_for_delivery') activeStep = 4;
    if (status == 'completed' || status == 'delivered') activeStep = 5;

    final steps = const [
      'تم استلام وتأكيد الطلب',
      'قيد التجهيز والتغليف',
      'تم تسليم الشحنة للمندوب',
      'في الطريق إلى عنوانك',
      'تم الاستلام بنجاح',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.local_shipping_outlined, color: Color(0xFF8B1D3B), size: 18),
              SizedBox(width: 6),
              Text(
                'حالة وتتبع الشحنة الفعلي',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Column(
            children: List.generate(steps.length, (i) {
              final stepNumber = i + 1;
              final isDone = stepNumber <= activeStep;
              final isCurrent = stepNumber == activeStep;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDone ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                              : Text('$stepNumber', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ),
                      ),
                      if (i < steps.length - 1)
                        Container(
                          width: 2,
                          height: 24,
                          color: stepNumber < activeStep ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        steps[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCurrent ? FontWeight.w900 : (isDone ? FontWeight.bold : FontWeight.w500),
                          color: isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(List<Map> items, String currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shopping_bag_outlined, color: Color(0xFF8B1D3B), size: 18),
              SizedBox(width: 6),
              Text(
                'المنتجات المطلوبة',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          if (items.isEmpty)
            const Text('منتجات متجر شبيك بلس المعتمدة', style: TextStyle(fontSize: 11, color: Color(0xFF64748B)))
          else
            ...items.map((item) {
              final title = '${item['product_name'] ?? item['name'] ?? 'منتج شبيك'}';
              final price = num.tryParse('${item['price'] ?? 0}') ?? 0;
              final qty = item['quantity'] ?? 1;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF8B1D3B), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'الكمية: $qty',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      money(price * qty, currency),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF8B1D3B)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> d) {
    final addr = d['shipping_address'] is Map ? d['shipping_address'] as Map : {};
    final gov = addr['governorate'] ?? 'صنعاء';
    final city = addr['city'] ?? 'حدة';
    final street = addr['street_details'] ?? addr['street'] ?? 'الشارع العام';
    final phone = addr['phone'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on_outlined, color: Color(0xFF8B1D3B), size: 18),
              SizedBox(width: 6),
              Text(
                'عنوان التوصيل والاستلام',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          Text('$gov - $city, $street', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 3),
          Text('رقم هاتف المستلم: $phone', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(num total, String currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('طريقة الدفع:', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              Row(
                children: const [
                  Icon(Icons.account_balance_wallet_rounded, size: 14, color: Color(0xFF059669)),
                  SizedBox(width: 4),
                  Text('محفظة شبيك (مدفوع بالكامل)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF065F46))),
                ],
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إجمالي الطلب:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text(money(total, currency), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF8B1D3B))),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 5. ORDER CHAT SCREEN (Direct vendor and driver chat)
// =========================================================================
class OrderChatScreen extends StatefulWidget {
  const OrderChatScreen({super.key, required this.orderId, this.title});
  final int orderId;
  final String? title;

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  final controller = TextEditingController();
  final messages = <Map<String, dynamic>>[
    {
      'sender': 'vendor',
      'text': 'أهلاً بك! تم استلام طلبك وجاري تجهيزه للشحن فوراً.',
      'time': '10:30 ص',
    },
    {
      'sender': 'user',
      'text': 'مرحباً، شكراً لكم، متى موعد التوصيل المتوقع؟',
      'time': '10:32 ص',
    },
    {
      'sender': 'vendor',
      'text': 'سيصلك المندوب اليوم خلال ساعتين إن شاء الله.',
      'time': '10:33 ص',
    },
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add({
        'sender': 'user',
        'text': text,
        'time': 'الآن',
      });
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title ?? 'محادثة الطلب #${widget.orderId}',
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Column(
        children: [
          // Quick suggestions
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              children: [
                _buildQuickChip('أين وصلت الشحنة؟'),
                _buildQuickChip('يرجى الاتصال بي عند الوصول'),
                _buildQuickChip('شكراً جزيلاً'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final m = messages[i];
                final isMe = m['sender'] == 'user';
                return Align(
                  alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF8B1D3B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 4)],
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${m['text']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isMe ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${m['time']}',
                          style: TextStyle(
                            fontSize: 9,
                            color: isMe ? Colors.white70 : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالتك للمتجر أو المندوب...',
                          hintStyle: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _send,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B1D3B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        onPressed: () {
          setState(() {
            messages.add({'sender': 'user', 'text': label, 'time': 'الآن'});
          });
        },
      ),
    );
  }
}

// =========================================================================
// 6. CATEGORY PRODUCTS VIEW & SCREEN (Matching CategoryProductsView.tsx)
// =========================================================================
class CategoryProductsView extends StatelessWidget {
  const CategoryProductsView({super.key, this.initialCategory});
  final String? initialCategory;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final catName = initialCategory ?? 'جميع الأقسام';
    final products = catName == 'جميع الأقسام' || catName == 'الكل'
        ? app.products
        : app.products.where((p) => p.categories.contains(catName)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          catName,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: products.isEmpty
          ? const Center(child: Text('لا توجد منتجات في هذا القسم حالياً'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductDetailView(product: p)),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: p.image != null && p.image!.isNotEmpty
                                ? Image.network(absoluteUrl(p.image!), fit: BoxFit.cover, width: double.infinity)
                                : const ColoredBox(color: Color(0xFFF1F5F9), child: Icon(Icons.image_outlined)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text(money(p.salePrice ?? p.price, p.currency), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF8B1D3B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class CategoriesFlutterScreen extends StatelessWidget {
  const CategoriesFlutterScreen({super.key});
  @override
  Widget build(BuildContext context) => const CategoryProductsView();
}
