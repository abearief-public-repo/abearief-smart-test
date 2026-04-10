/// Membalik digit dari sebuah bilangan bulat.
///
/// Menggunakan pendekatan konversi string karena:
/// 1. Lebih readable dan mudah dipahami dibanding operasi modulo berulang.
/// 2. `int.parse()` secara otomatis menghapus leading zeros pada hasil reverse.
///    Contoh: reverse(30) → string "03" → int.parse("03") = 3 (bukan 03).
///    Ini sesuai requirement di rules.md Sample #2.
/// 3. `.abs()` diterapkan di awal untuk memastikan fungsi tetap benar
///    meskipun menerima angka negatif, sehingga lebih defensif.
int reverseNumber(int number) {
  final reversed = number.abs().toString().split('').reversed.join('');
  return int.parse(reversed);
}

/// Menghitung selisih absolut antara dua bilangan.
///
/// `.abs()` memastikan hasil selalu positif, sesuai requirement:
/// "The result always have to be positive."
///
/// Parameter [number] dan [reversed] dipisah (bukan dihitung internal)
/// agar caller dapat menampilkan kedua nilai di UI tanpa menghitung ulang.
int calculateDifference(int number, int reversed) {
  return (number - reversed).abs();
}
