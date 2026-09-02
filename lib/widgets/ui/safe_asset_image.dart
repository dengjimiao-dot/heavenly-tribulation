import 'package:flutter/material.dart';

/// Asset image that falls back to a solid color instead of throwing.
///
/// [DecorationImage] has no errorBuilder; use this inside a Stack /
/// [Positioned.fill] (or as an [InkButton] child) instead of BoxDecoration.image.
class SafeAssetImage extends StatelessWidget {
  const SafeAssetImage(
    this.asset, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.borderRadius,
    this.fallbackColor = const Color(0xFF3A2A1A),
  });

  final String asset;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    Widget image = Image(
      image: AssetImage(asset),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: fallbackColor,
        );
      },
    );
    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}
