import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RekomendasiPage extends StatefulWidget {
  const RekomendasiPage({super.key});

  @override
  State<RekomendasiPage> createState() => _RekomendasiPageState();
}

class _RekomendasiPageState extends State<RekomendasiPage> {
  List<dynamic> rekomendasi = [];

  @override
  void initState() {
    super.initState();
    fetchRekomendasi();
  }

  Future<void> fetchRekomendasi() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey";

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "Buatkan daftar 4 makanan sehat berformat JSON. Format: [{\"nama\":..., \"kalori\":..., \"gambar\":...}]"
              }
            ]
          }
        ]
      }),
    );

    final data = jsonDecode(response.body);

    try {
      final text = data["candidates"][0]["content"]["parts"][0]["text"];
      final list = jsonDecode(text); // ini sudah JSON array dari Gemini

      setState(() {
        rekomendasi = list;
      });
    } catch (e) {
      debugPrint("ERROR PARSE: $e");
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
            // 🔍 Search bar
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

            // Filter kategori (dummy)
            Row(
              children: [
                filterChip("Semua", true),
                filterChip("Sarapan", false),
                filterChip("Rendah Kalori", false),
                filterChip("Tinggi Protein", false),
              ],
            ),

            const SizedBox(height: 20),

            // List Card
            Expanded(
              child: rekomendasi.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                  : GridView.builder(
                      itemCount: rekomendasi.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 230,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemBuilder: (context, index) {
                        final item = rekomendasi[index];

                        return makananCard(
                          imageUrl: item["gambar"],
                          nama: item["nama"],
                          kalori: item["kalori"],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // Floating button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        onPressed: () {},
      ),

      // Bottom nav
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

  // Chip Widget
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

  // Card Widget
  Widget makananCard({
    required String imageUrl,
    required String nama,
    required int kalori,
  }) {
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
              imageUrl,
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
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
