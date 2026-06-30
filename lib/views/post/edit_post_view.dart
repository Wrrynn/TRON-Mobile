import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../controllers/edit_post_controller.dart';
import '../../models/post.dart';
import '../../services/post_api.dart';
import '../widgets/route_map.dart';
import '../widgets/network_photo.dart';

class EditPostView extends StatelessWidget {
  final PostDetail post;

  const EditPostView({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => EditPostController(ctx.read<PostApi>(), post),
      child: const _EditPostBody(),
    );
  }
}

class _EditPostBody extends StatelessWidget {
  const _EditPostBody();

  // Widget pembantu untuk merender label form
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Widget pembantu untuk text field bergaya dark mode
  Widget _buildTextField(TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType, Widget? suffixIcon, bool readOnly = false, VoidCallback? onTap}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(color: AppColors.white, fontSize: 14),
      decoration: InputDecoration(
        fillColor: const Color(0xFF2A2B2F),
        filled: true,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<EditPostController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1E), // Background gelap sesuai desain
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit Postingan', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Judul *'),
            _buildTextField(ctrl.titleCtrl),

            _buildLabel('Lokasi *'),
            _buildTextField(ctrl.locationCtrl),

            _buildLabel('Tanggal Perjalanan'),
            _buildTextField(
              ctrl.dateCtrl,
              readOnly: true,
              onTap: () => ctrl.pickDate(context),
              suffixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.text2, size: 20),
            ),

            const SizedBox(height: 10),
            
            // Map terintegrasi[cite: 2]
            if (ctrl.destinations.isNotEmpty) ...[
              _buildLabel('Peta Rute'),
              RouteMap(destinations: ctrl.destinations, height: 200),
            ],

            _buildLabel('Rute Destinasi'),
            const Text(
              'Tambah lokasi satu per satu',
              style: TextStyle(color: AppColors.text2, fontSize: 12),
            ),
            const SizedBox(height: 10),
            
            // List Dinamis Destinasi
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ctrl.destinations.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      // Badge Nomor
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFF8B5CF6), // Ungu
                          shape: BoxShape.circle,
                        ),
                        child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      
                      // Input Destinasi
                      Expanded(
                        child: TextFormField(
                          initialValue: ctrl.destinations[index].name,
                          onChanged: (val) => ctrl.updateDestinationName(index, val),
                          style: const TextStyle(color: AppColors.white, fontSize: 14),
                          decoration: InputDecoration(
                            fillColor: const Color(0xFF2A2B2F),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Tombol Hapus Rute
                      InkWell(
                        onTap: () => ctrl.removeDestination(index),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3F2D2D), // Merah gelap
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // Tombol Tambah Destinasi
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: ctrl.addDestination,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),

            _buildLabel('Cerita Perjalanan'),
            _buildTextField(ctrl.storyCtrl, maxLines: 5),

            _buildLabel('Total Budget (Rp)'),
            _buildTextField(ctrl.budgetCtrl, keyboardType: TextInputType.number),

            // Foto Saat Ini
            if (ctrl.originalPhotos.isNotEmpty) ...[
              _buildLabel('Foto saat ini'),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: ctrl.originalPhotos.length,
                  itemBuilder: (context, index) {
                    final photoUrl = ctrl.originalPhotos[index];
                    final isMarkedForDelete = ctrl.photosToDelete.contains(photoUrl);

                    debugPrint('URL FOTO DARI SERVER: $photoUrl');
                    
                    return GestureDetector(
                      onTap: () => ctrl.toggleDeletePhoto(photoUrl),
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: NetworkPhoto(url: photoUrl, fit: BoxFit.cover),
                            ),
                            // Overlay gelap dan checkbox jika dicentang Hapus
                            Container(
                              decoration: BoxDecoration(
                                color: isMarkedForDelete ? Colors.black54 : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            Positioned(
                              bottom: 4, left: 4,
                              child: Row(
                                children: [
                                  Icon(
                                    isMarkedForDelete ? Icons.check_box : Icons.check_box_outline_blank,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('Hapus', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Tambah Foto Baru
            _buildLabel('Tambah Foto Baru (multiple)'),
            Row(
              children: [
                ElevatedButton(
                  onPressed: ctrl.pickNewPhotos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5E7EB), // Tombol terang
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Pilih File', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ctrl.newPhotos.isEmpty 
                        ? 'Tidak ada file yang dipilih' 
                        : '${ctrl.newPhotos.length} file dipilih',
                    style: const TextStyle(color: AppColors.text2, fontSize: 13),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),

            // MENGGUNAKAN IMAGE.FILE UNTUK PREVIEW FOTO LOKAL
            if (ctrl.newPhotos.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: ctrl.newPhotos.length,
                  itemBuilder: (context, index) {
                    final xfile = ctrl.newPhotos[index];
                    
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Widget inti untuk membaca file dari memori HP
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(xfile.path),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                          // Tombol silang untuk membatalkan pilihan foto
                          Positioned(
                            top: 4, right: 4,
                            child: GestureDetector(
                              onTap: () => ctrl.removeNewPhoto(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54, 
                                  shape: BoxShape.circle
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 14),
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 40),
            
            // Tombol Aksi Bawah
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF3F3F46)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: ctrl.isLoading ? null : () async {
                      final success = await ctrl.submitUpdate();
                      if (success && context.mounted) {
                        Navigator.pop(context, true);
                      } else if (ctrl.error != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ctrl.error!)));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: ctrl.isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}