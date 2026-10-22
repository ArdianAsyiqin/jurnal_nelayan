import 'dart:io';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Menampilkan foto tangkapan dari berkas lokal, atau ikon ikan bila belum ada.
class FotoTangkapan extends StatelessWidget {
  final String? path;
  final double? lebar;
  final double? tinggi;
  final double radius;
  final double ukuranIkon;

  const FotoTangkapan({
    super.key,
    this.path,
    this.lebar,
    this.tinggi,
    this.radius = 0,
    this.ukuranIkon = 32,
  });

  @override
  Widget build(BuildContext context) {
    final pengganti = Center(
      child: Icon(Icons.set_meal, size: ukuranIkon, color: Warna.teal),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: lebar,
        height: tinggi,
        color: Warna.tealMuda,
        child: path == null
            ? pengganti
            : Image.file(
                File(path!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => pengganti,
              ),
      ),
    );
  }
}
