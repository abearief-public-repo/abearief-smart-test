import 'package:flutter/material.dart';
import 'package:smart_test/utils/calculator.dart';
import 'package:smart_test/utils/digits_only_formatter.dart';

void main() {
  runApp(const SmartTestApp());
}

/// Root widget aplikasi Smart Test.
///
/// Menggunakan [MaterialApp] dengan Material 3 (useMaterial3: true) untuk
/// memanfaatkan design system terbaru dari Google yang lebih modern dan konsisten.
///
/// [ColorScheme.fromSeed] dipilih karena secara otomatis menghasilkan
/// palette warna yang harmonis dan accessible dari satu seed color,
/// menghindari inkonsistensi warna yang sering terjadi saat mendefinisikan
/// warna secara manual satu per satu.
class SmartTestApp extends StatelessWidget {
  const SmartTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SmartTestScreen(),
    );
  }
}

/// Layar utama aplikasi — satu-satunya screen karena requirement bersifat
/// single-purpose (input angka → tampilkan hasil).
///
/// Menggunakan [StatefulWidget] karena screen ini mengelola state lokal:
/// input teks, hasil kalkulasi, dan error message. Tidak menggunakan
/// state management eksternal (Provider, Bloc, dll.) karena kompleksitas
/// state sangat rendah dan hanya terisolasi di satu screen.
class SmartTestScreen extends StatefulWidget {
  const SmartTestScreen({super.key});

  @override
  State<SmartTestScreen> createState() => _SmartTestScreenState();
}

class _SmartTestScreenState extends State<SmartTestScreen> {
  final _controller = TextEditingController();

  // State hasil kalkulasi menggunakan nullable int (int?) agar bisa membedakan
  // antara "belum ada hasil" (null) dan "hasil adalah 0" (misalnya input 11).
  int? _inputNumber;
  int? _reversedNumber;
  int? _difference;

  // Flag terpisah dari nullable state di atas, karena kita perlu tahu
  // apakah user sudah pernah menekan submit (untuk menampilkan result card).
  bool _hasResult = false;
  String? _errorMessage;

  /// Batas maksimum digit input.
  ///
  /// Dart int64 memiliki range hingga 9,223,372,036,854,775,807 (19 digit).
  /// Dibatasi 18 digit sebagai safety margin agar operasi reverse juga aman
  /// tanpa risiko overflow — angka 19 digit yang di-reverse bisa melebihi batas.
  static const _maxDigits = 18;

  /// Handler saat tombol Submit ditekan atau keyboard action "done" ditekan.
  ///
  /// Validasi dilakukan di sini (bukan di formatter) karena formatter hanya
  /// bertugas memfilter input, sedangkan validasi bisnis (kosong, terlalu besar)
  /// adalah concern dari submit action.
  void _onSubmit() {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Masukkan angka terlebih dahulu';
        _hasResult = false;
      });
      return;
    }

    // Validasi panjang input untuk mencegah integer overflow.
    // DigitsOnlyFormatter menjamin isi hanya digit, tapi tidak membatasi panjang.
    // Angka > 18 digit berisiko overflow saat int.parse() atau saat di-reverse.
    if (text.length > _maxDigits) {
      setState(() {
        _errorMessage = 'Maksimal $_maxDigits digit';
        _hasResult = false;
      });
      return;
    }

    final number = int.parse(text);
    final reversed = reverseNumber(number);
    final diff = calculateDifference(number, reversed);

    setState(() {
      _inputNumber = number;
      _reversedNumber = reversed;
      _difference = diff;
      _hasResult = true;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    // TextEditingController harus di-dispose untuk mencegah memory leak,
    // karena controller mendaftarkan listener ke framework yang tidak
    // otomatis dibersihkan saat widget di-remove dari tree.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Test',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 2,
      ),
      // GestureDetector membungkus body agar tap di area kosong menutup keyboard.
      // Ini adalah UX pattern standar di mobile — user mengharapkan keyboard
      // tertutup saat tap di luar input field.
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          // SingleChildScrollView memastikan konten tetap scrollable saat keyboard
          // muncul, mencegah overflow pada device dengan layar kecil.
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Number Reverse Calculator',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan angka bulat, lalu tekan Submit untuk melihat selisih angka dengan kebalikannya.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Input field menggunakan kombinasi dua mekanisme untuk memastikan
              // hanya angka bulat yang bisa diinput:
              // 1. keyboardType: TextInputType.number → menampilkan keyboard numerik
              //    di device, sehingga user tidak perlu switch keyboard secara manual.
              // 2. DigitsOnlyFormatter → layer kedua sebagai safety net, karena
              //    beberapa keyboard (terutama third-party) tetap bisa mengirim
              //    karakter non-digit meskipun keyboardType sudah diset number.
              // Semantics membungkus TextField agar screen reader (TalkBack/VoiceOver)
              // dapat memberikan konteks yang jelas tentang fungsi input ini.
              Semantics(
                label: 'Input angka untuk dihitung kebalikannya',
                textField: true,
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [DigitsOnlyFormatter()],
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  // onChanged memicu rebuild agar clear button (suffixIcon) muncul/hilang
                  // secara reaktif sesuai isi field — tanpa perlu listener terpisah.
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Masukkan angka',
                    hintStyle: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    // Clear button hanya muncul saat field tidak kosong.
                    // Memberikan cara cepat untuk menghapus input tanpa backspace manual,
                    // UX pattern standar yang umum di aplikasi mobile modern.
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                            tooltip: 'Hapus input',
                          )
                        : null,
                    // errorText dari state — ditampilkan di bawah field saat input kosong.
                    // Menggunakan built-in error mechanism dari InputDecoration agar
                    // styling error konsisten dengan Material Design guidelines.
                    errorText: _errorMessage,
                  ),
                  // onSubmitted menangani aksi "done" di keyboard, sehingga user
                  // bisa submit tanpa harus menekan tombol Submit secara eksplisit.
                  onSubmitted: (_) => _onSubmit(),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Submit menggunakan FilledButton (Material 3) untuk
              // memberikan visual emphasis yang jelas sebagai primary action.
              // Height 56dp mengikuti minimum touch target yang direkomendasikan
              // oleh Material Design accessibility guidelines.
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _onSubmit,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Submit'),
                ),
              ),
              const SizedBox(height: 32),

              // Result card hanya ditampilkan setelah submit pertama.
              // Menggunakan conditional rendering (if) alih-alih Visibility
              // agar widget tidak di-build sama sekali sebelum ada hasil,
              // menghindari layout space kosong yang membingungkan user.
              if (_hasResult) _buildResultCard(theme),
            ],
          ),
        ),
      ),
    );
  }

  /// Membangun card yang menampilkan hasil kalkulasi.
  ///
  /// Card menggunakan elevation: 0 dengan border outline agar terlihat
  /// flat dan modern sesuai tren Material 3, sambil tetap memberikan
  /// visual separation yang jelas dari konten di atasnya.
  Widget _buildResultCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Hasil',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            _buildResultRow(
              theme,
              label: 'Angka',
              value: '$_inputNumber',
              icon: Icons.looks_one_outlined,
            ),
            const Divider(height: 24),
            _buildResultRow(
              theme,
              label: 'Kebalikan',
              value: '$_reversedNumber',
              icon: Icons.swap_horiz,
            ),
            const Divider(height: 24),
            _buildResultRow(
              theme,
              label: 'Selisih',
              value: '$_difference',
              icon: Icons.calculate_outlined,
              highlight: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Baris individual dalam result card.
  ///
  /// Parameter [highlight] digunakan untuk membedakan baris "Selisih" (hasil utama)
  /// dari baris lainnya, memberikan visual hierarchy yang jelas sehingga user
  /// langsung bisa mengenali mana informasi paling penting.
  Widget _buildResultRow(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
    bool highlight = false,
  }) {
    // Semantics menggabungkan label dan value agar screen reader membaca
    // "Angka: 21" sebagai satu kesatuan, bukan dua elemen terpisah.
    return Semantics(
      label: '$label: $value',
      child: Row(
      children: [
        Icon(
          icon,
          color: highlight
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          size: 28,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: highlight
              ? theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                )
              : theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    ),
    );
  }
}
