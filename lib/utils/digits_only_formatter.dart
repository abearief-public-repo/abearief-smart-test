import 'package:flutter/services.dart';

/// Custom [TextInputFormatter] yang hanya mengizinkan karakter digit (0-9).
///
/// Dipilih menggunakan custom formatter (bukan [FilteringTextInputFormatter.digitsOnly])
/// karena requirement spesifik di rules.md:
/// - Jika user mengetik "1.2" atau "1,2", maka yang muncul di field adalah "12".
/// - Artinya titik, koma, dan karakter non-digit lainnya harus di-strip secara real-time
///   saat user mengetik, bukan hanya di-reject.
///
/// Pendekatan regex `[^0-9]` memastikan SEMUA karakter selain digit dihapus,
/// termasuk titik desimal, koma, spasi, huruf, dan simbol lainnya.
///
/// Cursor di-collapse ke akhir teks setelah filtering untuk menghindari
/// posisi cursor yang tidak konsisten setelah karakter dihapus di tengah input.
class DigitsOnlyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Hapus semua karakter non-digit menggunakan regex.
    // Ini menangani kasus "1.2" → "12", "1,2" → "12", "abc" → "" secara sekaligus.
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    return TextEditingValue(
      text: digitsOnly,
      // Cursor selalu ditempatkan di akhir teks untuk UX yang konsisten,
      // karena karakter yang di-strip bisa menggeser posisi cursor secara tidak terduga.
      selection: TextSelection.collapsed(offset: digitsOnly.length),
    );
  }
}
