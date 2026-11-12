import 'package:flutter/material.dart';

import '../theme.dart';

/// Panel tombol yang menempel di bawah layar.
class BarBawah extends StatelessWidget {
  final Widget child;

  const BarBawah({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Warna.latar,
        border: Border(top: BorderSide(color: Warna.garis)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: child,
        ),
      ),
    );
  }
}
