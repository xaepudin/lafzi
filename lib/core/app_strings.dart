/// Indonesian copy used across the app, preserved from the Android version.
abstract final class AppStrings {
  static const appName = 'Lafzi';

  static const bantuan = 'Bantuan';
  static const pengaturan = 'Pengaturan';
  static const about = 'Tentang Lafzi';
  static const panduan = 'Panduan';

  static String suratAyat(String surahName, int surahNo, int ayatNo) =>
      'Surat $surahName ($surahNo) Ayat $ayatNo';
  static String ayat(int ayatNo) => 'Ayat $ayatNo';
  static String resultCount(int count) => 'Ditemukan $count hasil';
  static String onboardingStep(int step, int total) =>
      'Langkah $step dari $total';

  static const queryLessThan3 = 'Lafaz dicari minimal 3 karakter';
  static const copied = 'Text disalin';
  static const bagikan = 'Bagikan';
  static const berikut = 'Berikut';
  static const sebelum = 'Sebelum';

  static const searchHint = 'Cari lafadz, mis. bismillah';
  static const searchAction = 'Cari';
  static const searchByVoice = 'Cari dengan suara';
  static const clearSearch = 'Hapus pencarian';

  static const onboardingSearchTitle = 'Cari lafadz';
  static const onboardingSearchMessage =
      'Ketik lafadz Al-Quran dalam huruf Latin, lalu tekan tombol cari.';
  static const onboardingVoiceTitle = 'Cari dengan suara';
  static const onboardingVoiceMessage =
      'Ketuk ikon mikrofon di toolbar untuk mencari dengan suara.';
  static const onboardingExampleTitle = 'Contoh cepat';
  static const onboardingExampleMessage =
      'Ketuk salah satu contoh di daftar untuk langsung mencoba.';
  static const onboardingSkip = 'Lewati';
  static const onboardingNext = 'Lanjut';
  static const onboardingDone = 'Selesai';

  static const emptyTitle = 'Temukan lafadz Al-Quran';
  static const emptySubtitle =
      'Ketikkan lafadz yang ingin dicari, atau coba salah satu contoh berikut.';
  static const noResultTitle = 'Tidak ada hasil';
  static const noResultSubtitle =
      'Pastikan lafaz yang dicari ada pada Al-Quran.';

  static const shareSheetTitle = 'Bagikan ayat';
  static const shareSheetSubtitle = 'Pilih format pembagian';
  static const shareImage = 'Gambar';
  static const shareText = 'Teks';
  static const downloadImage = 'Unduh gambar';
  static const imageDownloaded = 'Gambar diunduh';
  static const toolbarLogo = 'Logo Lafzi';
  static const shareUsing = 'Bagikan Menggunakan';

  static const gagalMembagi = 'Gagal Membagi';
  static const tidakBisaMuatGambar = 'Tidak bisa memuat gambar';

  static const noInternetConnection = 'Tidak ada koneksi internet';
  static const noSpeechAvailable =
      'Google App tidak aktif atau belum terinstall';
  static const speechUnavailable =
      'Pencarian suara tidak tersedia di perangkat ini';
  static const speechNotDetected = 'Suara tidak terdeteksi. Silakan coba lagi.';
  static const speechPermissionDenied =
      'Izin mikrofon dan pengenalan suara diperlukan untuk pencarian suara';
  static const speechFailed =
      'Pencarian suara gagal. Periksa mikrofon dan izin pengenalan suara, '
      'lalu coba lagi.';
  static const listening = 'Mendengarkan… Ucapkan lafadz yang dicari';
  static const stopListening = 'Hentikan pencarian suara';

  static const isVocalTitle = 'Perhitungkan huruf vokal';
  static const isVocalSummary =
      'Jika nonaktif, huruf vokal (AIUEO) tidak akan diperhitungkan '
      'dalam pencarian. Contohnya, pencarian "munafiqun" akan '
      'menyertakan juga "munafiqin"';
  static const showSimilarityTitle = 'Tampilkan tingkat kesamaan';
  static const showSimilaritySummary =
      'Persentase kecocokan kata kunci ditampilkan pada setiap kartu hasil.';

  static const showTranslationTitle = 'Tampilkan terjemahan';
  static const showTranslationSummary =
      'Tampilkan terjemahan bahasa Indonesia di hasil pencarian';

  static const aboutText =
      'Lafzi adalah aplikasi pencari lafadz pada Al-Quran. Aplikasi ini dibuat '
      'untuk memudahkan pencarian ayat dengan lafadz tertentu pada Al-Quran '
      'hanya dengan aksara Latin biasa berdasarkan pelafalan pembicara bahasa '
      'Indonesia, tanpa perlu mengetikkannya dalam aksara Arab.\n\n'
      'Lafzi untuk Android ini adalah aplikasi open source yang didasarkan pada '
      'hasil penelitian skripsi Departemen Ilmu Komputer, Fakultas MIPA '
      'Institut Pertanian Bogor.\n\n'
      'Kunjungi https://github.com/lafzi untuk melihat source code Lafzi.';
  static const aboutLink = 'https://github.com/lafzi';
  static String aboutTitle(String version) => 'Lafzi versi $version';

  static const exampleQueries = <String>[
    'bismillah',
    'alhamdulillah',
    'allahu samad',
    'maliki yaumid din',
    'iyyaka nabudu',
    'ihdinas siratal mustaqim',
    'inna lillahi',
    'hasbunallahu',
    'la yukallifullahu',
    "ma'al usri yusra",
    'rabbi zidni ilma',
    'qul huwallahu ahad',
    'lam yalid wa lam yulad',
    'birabbil falaq',
    'birabbin nas',
    'wa la tahinu wa la tahzanu',
    'rahmatan lil alamin',
    'wa ma arsalnaka',
  ];

  static const helpHeaderOrder = 'Urutan hasil pencarian';
  static const helpOrderBody =
      'Hasil pencarian terurut kecocokan. Hasil yang paling atas adalah hasil '
      'yang menurut aplikasi paling cocok, sedangkan hasil yang paling bawah '
      'yang kemungkinan kurang cocok.';
  static const helpHeaderVoice = 'Pencarian suara';
  static const helpVoiceBody =
      'Lafzi mendukung pencarian menggunakan suara jika perangkat terhubung ke '
      'internet.\nUntuk melakukan pencarian dengan suara, bisa dengan menekan '
      'ikon microphone di sisi kanan kolom pencarian, kemudian melafalkan ayat '
      'yang ingin dicari';
  static const helpHeaderMismatch =
      'Jika hasil pencarian tidak sesuai harapan...';
  static const helpMismatchBody =
      'Sebagaimana mesin pencari pada umumnya, aplikasi ini tidak sempurna atau '
      'selalu dapat memberikan hasil yang sesuai. Ini dipengaruhi juga oleh '
      'lafadz pencarian yang dimasukkan. Pastikan lafadz yang dicari memang '
      'benar-benar ada di dalam Al-Qur\'an dan bukan misalnya hadits, do\'a, '
      'atau yang lainnya.\n\nSebagai catatan, aplikasi ini ditujukan untuk '
      'mencari lafadz di dalam Al-Qur\'an dengan tulisan latin ataupun suara, '
      'dan bukan untuk mencari:';
  static const helpBullets = <String>[
    'Terjemahan',
    'Nama surat atau nomor ayat',
    "Teks Qur'an dalam huruf Arab",
  ];
  static const helpHeaderTooMany = 'Jika hasil pencarian terlalu banyak...';
  static const helpTooManyBody =
      'Jika lafadz yang dimasukkan terlalu pendek atau memang sangat umum '
      'kemunculannya di dalam Al-Qur\'an, misalnya lafadz "Allah", maka '
      'hasilnya akan sangat banyak. Untuk hasil yang lebih spesifik, Anda dapat '
      'mencoba masukan yang lebih panjang.';
  static const helpHeaderShare = 'Membagikan ayat hasil pencarian';
  static const helpShareBody =
      'Klik pada salah satu hasil pencarian untuk membuka halaman lanjutan, dan '
      'tekan tombol dengan icon share.';
}
