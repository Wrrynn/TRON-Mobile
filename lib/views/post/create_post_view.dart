import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../controllers/create_post_controller.dart';
import '../../services/post_api.dart';
import '../../utils/formatters.dart';

class CreatePostView extends StatelessWidget {
  const CreatePostView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CreatePostController(ctx.read<PostApi>()),
      child: const _CreatePostForm(),
    );
  }
}

class _CreatePostForm extends StatefulWidget {
  const _CreatePostForm();

  @override
  State<_CreatePostForm> createState() => _CreatePostFormState();
}

class _CreatePostFormState extends State<_CreatePostForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _story = TextEditingController();
  final _budget = TextEditingController();
  final _destination = TextEditingController();
  DateTime? _travelDate;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _story.dispose();
    _budget.dispose();
    _destination.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final ctrl = context.read<CreatePostController>();
    final files = await _picker.pickMultiImage(imageQuality: 80);
    for (final f in files) {
      ctrl.addPhoto(f.path);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _travelDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _travelDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ctrl = context.read<CreatePostController>();
    final budget = int.tryParse(_budget.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    final post = await ctrl.submit(
      title: _title.text.trim(),
      location: _location.text.trim(),
      story: _story.text.trim(),
      totalBudget: budget,
      travelDate: _travelDate?.toIso8601String().split('T').first,
    );

    if (!mounted) return;
    if (post != null) {
      Navigator.of(context).pop(true); // sukses → feed refresh
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Postingan berhasil dibuat!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ctrl.error ?? 'Gagal membuat postingan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CreatePostController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Postingan Baru')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _PhotoPicker(
                paths: ctrl.photoPaths,
                onAdd: _pickPhotos,
                onRemove: ctrl.removePhoto,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Judul *',
                  hintText: 'mis. Liburan ke Bandung',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(
                  labelText: 'Lokasi',
                  hintText: 'mis. Buah Batu, Bandung',
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Tanggal perjalanan',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      hintText: _travelDate == null
                          ? 'Pilih tanggal'
                          : Format.tanggal(
                              _travelDate!.toIso8601String().split('T').first),
                    ),
                    controller: TextEditingController(
                      text: _travelDate == null
                          ? ''
                          : Format.tanggal(
                              _travelDate!.toIso8601String().split('T').first),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _budget,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total budget (Rp)',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  hintText: '0',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _story,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Cerita',
                  hintText: 'Ceritakan pengalaman perjalananmu...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              _DestinationEditor(
                controller: _destination,
                destinations: ctrl.destinations,
                onAdd: () {
                  ctrl.addDestination(_destination.text);
                  _destination.clear();
                },
                onRemove: ctrl.removeDestination,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: ctrl.submitting ? null : _submit,
                icon: ctrl.submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(ctrl.submitting ? 'Mengirim...' : 'Posting'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final List<String> paths;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const _PhotoPicker({
    required this.paths,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                color: AppColors.bg3,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border2),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: AppColors.purple),
                  SizedBox(height: 6),
                  Text('Tambah foto',
                      style: TextStyle(color: AppColors.text2, fontSize: 12)),
                ],
              ),
            ),
          ),
          for (var i = 0; i < paths.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(paths[i]),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DestinationEditor extends StatelessWidget {
  final TextEditingController controller;
  final List destinations;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const _DestinationEditor({
    required this.controller,
    required this.destinations,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Destinasi',
            style: TextStyle(
                color: AppColors.white, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'mis. Dago, Lembang...',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        if (destinations.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < destinations.length; i++)
                Chip(
                  label: Text(destinations[i].name),
                  backgroundColor: AppColors.bg3,
                  labelStyle: const TextStyle(color: AppColors.text),
                  deleteIconColor: AppColors.text2,
                  onDeleted: () => onRemove(i),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
