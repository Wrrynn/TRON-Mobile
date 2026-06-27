import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post.dart';
import '../models/destination.dart';
import '../services/post_api.dart';
import '../utils/formatters.dart'; // Asumsi Anda punya formatter tanggal

class EditPostController extends ChangeNotifier {
  final PostApi _api;
  final PostDetail originalPost;

  // Form Controllers
  final titleCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final storyCtrl = TextEditingController();
  final budgetCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  List<Destination> destinations = [];
  
  // State untuk Foto
  List<String> originalPhotos = [];
  List<String> photosToDelete = [];
  List<XFile> newPhotos = [];
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;
  String? error;

  EditPostController(this._api, this.originalPost) {
    _initializeData();
  }

  void _initializeData() {
    titleCtrl.text = originalPost.title;
    locationCtrl.text = originalPost.location ?? '';
    storyCtrl.text = originalPost.story ?? '';
    budgetCtrl.text = originalPost.totalBudget.toString();
    dateCtrl.text = originalPost.travelDate ?? '';
    
    // Inisialisasi destinasi dan foto
    destinations = List.from(originalPost.destinations);
    originalPhotos = List.from(originalPost.photos);
  }

  // --- Logika Destinasi ---
  void addDestination() {
    // Removed the 'id: 0' parameter to match your Destination model
    destinations.add(const Destination(name: ''));
    notifyListeners();
  }

  void removeDestination(int index) {
    destinations.removeAt(index);
    notifyListeners();
  }

  void updateDestinationName(int index, String name) {
    // Removed the 'id' parameter to match your Destination model
    destinations[index] = Destination(
      name: name,
      lat: destinations[index].lat,
      lng: destinations[index].lng,
    );
    notifyListeners();
  }

  // --- Logika Tanggal ---
  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      dateCtrl.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      notifyListeners();
    }
  }

  // --- Logika Foto ---
  void toggleDeletePhoto(String photoUrl) {
    if (photosToDelete.contains(photoUrl)) {
      photosToDelete.remove(photoUrl);
    } else {
      photosToDelete.add(photoUrl);
    }
    notifyListeners();
  }

  Future<void> pickNewPhotos() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      newPhotos.addAll(pickedFiles);
      notifyListeners();
    }
  }

  void removeNewPhoto(int index) {
    newPhotos.removeAt(index);
    notifyListeners();
  }

  Future<bool> submitUpdate() async {
    if (titleCtrl.text.trim().isEmpty) {
      error = 'Judul tidak boleh kosong';
      notifyListeners();
      return false;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Catatan: Jika backend Laravel Anda butuh list `deleted_photos`, Anda perlu
      // menambahkannya ke parameter `update` di file post_api.dart
      await _api.update(
        id: originalPost.id,
        title: titleCtrl.text.trim(),
        location: locationCtrl.text.trim(),
        story: storyCtrl.text.trim(),
        totalBudget: int.tryParse(budgetCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        travelDate: dateCtrl.text.trim(),
        destinations: destinations,
        newPhotoPaths: newPhotos.map((e) => e.path).toList(),
      );
      
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    locationCtrl.dispose();
    storyCtrl.dispose();
    budgetCtrl.dispose();
    dateCtrl.dispose();
    super.dispose();
  }
}