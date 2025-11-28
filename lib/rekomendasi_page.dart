import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer'; // Untuk logging yang lebih baik

class RekomendasiPage extends StatefulWidget {
  const RekomendasiPage({super.key});

  @override
  State<RekomendasiPage> createState() => _RekomendasiPageState();
}

class _RekomendasiPageState extends State<RekomendasiPage> {
  // Gunakan Map untuk menampung data
  List<Map<String, dynamic>> rekomendasi = []; 
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchRekomendasi();
  }

  Future<void> fetchRekomendasi() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    // Pastikan kunci API sudah dimuat di main.dart
    final apiKey = dotenv.env['GEMINI_API_KEY']; 

    if (apiKey == null) {
      log('ERROR: GEMINI_API_KEY tidak ditemukan di .env', name: 'API');
      setState(() {
        isLoading = false;
        errorMessage = 'API Key tidak ditemukan. Pastikan file .env sudah diatur.';
      });
      return;
    }

    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey";

    // MENGUBAH PROMPT: Minta URL gambar yang valid secara eksplisit
    const improvedPrompt =
        "Buatkan daftar 4 makanan sehat berformat JSON. Format: [{\"nama\": \"Nama Makanan\", \"kalori\": 123, \"gambar\": \"URL_Gambar_Makanan_Valid_dan_Publik\"}]. Pastikan nilai 'gambar' adalah URL gambar yang valid dan dapat diakses dari internet.";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {"parts": [{"text": improvedPrompt}]}
          ]
        }),
      ).timeout(const Duration(seconds: 30)); // Tambahkan timeout

      if (response.statusCode != 200) {
        log('API Status Code: ${response.statusCode}', name: 'API_RESPONSE');
        log('API Body: ${response.body}', name: 'API_RESPONSE');
        setState(() {
          isLoading = false;
          errorMessage = 'Gagal mengambil data. Status: ${response.statusCode}';
        });
        return;
      }

      final data = jsonDecode(response.body);
      final text = data["candidates"][0]["content"]["parts"][0]["text"];

      // Gemini terkadang mengembalikan teks di luar blok JSON (misal: "```json ... ```")
      final cleanedText = text.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final List<dynamic> list = jsonDecode(cleanedText); 
      
      // Mengubah List<dynamic> menjadi List<Map<String, dynamic>>
      final List<Map<String, dynamic>> finalRekomendasi = list
          .map((item) => item as Map<String, dynamic>)
          .toList();

      setState(() {
        rekomendasi = finalRekomendasi;
        isLoading = false;
      });

    } catch (e) {
      log("ERROR PARSE/FETCH: $e", name: 'FETCH_ERROR');
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan saat memproses data.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.arrow_back_ios, color: Colors.white),
        title: const Text(
          "Rekomendasi Makanan",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 Search bar (tetap sama)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B1B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.white54),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Cari makanan sehat...",
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Filter kategori (tetap sama)
            Row(
              children: [
                filterChip("Semua", true),
                filterChip("Sarapan", false),
                filterChip("Rendah Kalori", false),
                filterChip("Tinggi Protein", false),
              ],
            ),

            const SizedBox(height: 20),

            // List Card dengan Loading/Error State
            Expanded(
              child: () {
                if (isLoading) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }
                if (errorMessage.isNotEmpty) {
                  return Center(
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                    ),
                  );
                }
                if (rekomendasi.isEmpty) {
                  return const Center(
                    child: Text(
                      "Tidak ada rekomendasi yang ditemukan.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                
                return GridView.builder(
                  itemCount: rekomendasi.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 230,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    final item = rekomendasi[index];

                    return makananCard(
                      imageUrl: item["gambar"] ?? '', // Pastikan tidak null
                      nama: item["nama"] ?? 'Tidak Diketahui',
                      kalori: (item["kalori"] as num?)?.toInt() ?? 0, // Handle int/num
                    );
                  },
                );
              }(), // Eksekusi function anonim
            ),
          ],
        ),
      ),

      // Floating button dan Bottom nav (tetap sama)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        onPressed: () {},
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.white54,
        backgroundColor: const Color(0xFF1B1B1B),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Lacak"),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu), label: "Rekomendasi"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }

  // Chip Widget (tetap sama)
  Widget filterChip(String label, bool selected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
      decoration: BoxDecoration(
        color: selected ? Colors.green : const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white70,
          fontSize: 13,
        ),
      ),
    );
  }

  // Card Widget (dengan penanganan error gambar)
  Widget makananCard({
    required String imageUrl,
    required String nama,
    required int kalori,
  }) {
    // Fallback URL jika Gemini tidak memberikan URL yang valid
    final String validUrl = Uri.tryParse(imageUrl)?.hasAbsolutePath == true 
        ? imageUrl 
        : 'https://via.placeholder.com/300x110.png?text=Image+Missing'; // Placeholder
        
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GAMBAR
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              validUrl, // Menggunakan URL yang sudah divalidasi
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Menampilkan ikon jika gambar gagal dimuat
                return Container(
                  height: 110,
                  color: const Color(0xFF2B2B2B),
                  child: const Center(
                    child: Icon(Icons.fastfood, color: Colors.white54, size: 40),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              nama,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),

          const SizedBox(height: 4),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "≈ $kalori kcal",
              style: const TextStyle(color: Colors.green, fontSize: 13),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}