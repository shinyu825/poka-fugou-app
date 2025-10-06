class CardImages {
  final String svg;
  final String png;
  CardImages({required this.svg, required this.png});

  factory CardImages.fromJson(Map<String, dynamic> json) =>
      CardImages(svg: json['svg'] as String, png: json['png'] as String);
}
