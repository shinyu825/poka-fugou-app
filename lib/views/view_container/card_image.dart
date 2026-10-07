import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';

/// カード画像（端末にキャッシュする。読み込み失敗時はプレースホルダーを出し、タップで再読み込み）
class CardImage extends StatefulWidget {
  final String url;
  final double width;
  final double height;

  const CardImage({
    super.key,
    required this.url,
    this.width = 72,
    this.height = 100,
  });

  @override
  State<CardImage> createState() => _CardImageState();
}

class _CardImageState extends State<CardImage> {
  /// 再読み込みのたびに増やして画像を作り直す
  int _retryCount = 0;

  void _retry() {
    setState(() => _retryCount++);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CachedNetworkImage(
        key: ValueKey('${widget.url}-$_retryCount'),
        imageUrl: widget.url,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) {
          return GestureDetector(
            onTap: _retry,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(4),
              child: const Text(
                '${AppStrings.imageLoadFailed}\n${AppStrings.tapToReload}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10),
              ),
            ),
          );
        },
      ),
    );
  }
}
