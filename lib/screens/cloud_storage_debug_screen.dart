import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class CloudStorageDebugScreen extends StatefulWidget {
  const CloudStorageDebugScreen({super.key});

  @override
  State<CloudStorageDebugScreen> createState() => _CloudStorageDebugScreenState();
}

class _CloudStorageDebugScreenState extends State<CloudStorageDebugScreen> {
  String _out = 'اضغط "فحص"';
  bool _busy = false;

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _out = 'جارٍ الفحص...';
    });
    final sb = StringBuffer();
    
    for (final t in ['users', 'prayer_days', 'workout_entries', 'fasting_entries']) {
      try {
        final r = await SupabaseService.client.from(t).select().limit(1);
        sb.writeln('✅ $t → ${(r as List).length} صف');
      } catch (e) {
        sb.writeln('❌ $t → فشل الاتصال');
      }
    }
    setState(() {
      _out = sb.toString();
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فحص التخزين السحابي')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _check,
                icon: const Icon(Icons.cloud_sync),
                label: const Text('فحص'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  _out,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
