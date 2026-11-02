import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../providers/settings_provider.dart';
import '../providers/sync_provider.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import 'cloud_storage_debug_screen.dart';
import 'manage_tabs_screen.dart';

class SettingsScreen extends StatelessWidget {
  final UserData? user;
  const SettingsScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = context.watch<SettingsProvider>();
    final sync = context.watch<SyncProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text(t.t('settings'))),
      body: ListView(
        children: [
          const _Header('المظهر'),
          SwitchListTile(
            title: Text(t.t('dark_mode')),
            value: s.darkMode,
            onChanged: s.setDark,
            secondary: const Icon(Icons.dark_mode),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(t.t('language')),
            trailing: DropdownButton<String>(
              value: s.lang,
              items: const [
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (v) {
                if (v != null) s.setLang(v);
              },
            ),
          ),

          const Divider(),
          const _Header('نمط عرض التبويبات'),
          ...TabViewMode.values.map((m) {
            final selected = s.tabViewMode == m;
            return ListTile(
              leading: Icon(_iconForViewMode(m)),
              title: Text(m.label),
              subtitle: Text(m.hint, style: const TextStyle(fontSize: 12)),
              trailing: Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? primary : Colors.grey,
              ),
              onTap: () => s.setTabViewMode(m),
            );
          }),

          const Divider(),
          const _Header('استعادة الحالة'),
          SwitchListTile(
            title: const Text('فتح آخر صفحة تلقائياً'),
            subtitle: const Text(
                'يفتح آخر تبويب كنت فيه عند تشغيل التطبيق',
                style: TextStyle(fontSize: 12)),
            value: s.autoOpenLastTab,
            onChanged: s.setAutoOpenLastTab,
            secondary: const Icon(Icons.restore),
          ),

          const Divider(),
          const _Header('التبويبات الأساسية'),
          SwitchListTile(
            title: Text(t.t('prayer')),
            value: s.showPrayer,
            onChanged: s.setShowPrayer,
          ),
          SwitchListTile(
            title: const Text('الدروس'),
            value: s.showLessons,
            onChanged: s.setShowLessons,
            secondary: const Icon(Icons.menu_book),
          ),
          SwitchListTile(
            title: const Text('المهام اليومية'),
            value: s.showDailyTasks,
            onChanged: s.setShowDailyTasks,
            secondary: const Icon(Icons.task_alt),
          ),
          SwitchListTile(
            title: const Text('المصرف الأسبوعي'),
            value: s.showExpenses,
            onChanged: s.setShowExpenses,
            secondary: const Icon(Icons.account_balance_wallet),
          ),
          SwitchListTile(
            title: Text(t.t('workout')),
            value: s.showWorkout,
            onChanged: s.setShowWorkout,
          ),
          SwitchListTile(
            title: Text(t.t('fasting')),
            value: s.showFasting,
            onChanged: s.setShowFasting,
          ),

          if (user != null) ...[
            const Divider(),
            const _Header('التبويبات المخصصة'),
            ListTile(
              leading: const Icon(Icons.dashboard_customize),
              title: const Text('إدارة التبويبات المخصصة'),
              subtitle: Text('${user!.customTabs.length} تبويب'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManageTabsScreen(user: user!),
                ),
              ),
            ),
          ],

          const Divider(),
          const _Header('الإشعارات'),
          SwitchListTile(
            title: Text(t.t('notifications')),
            value: s.notificationsEnabled,
            onChanged: (v) async {
              s.setNotifEnabled(v);
              if (v) {
                await NotificationService.scheduleDaily(s.notifyHour,
                    s.notifyMinute, 'تذكير', 'لا تنسَ متابعة عباداتك');
              } else {
                await NotificationService.cancelAll();
              }
            },
          ),
          ListTile(
            title: const Text('وقت الإشعار'),
            subtitle: Text(
              '${s.notifyHour.toString().padLeft(2, '0')}:${s.notifyMinute.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final r = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: s.notifyHour, minute: s.notifyMinute),
              );
              if (r != null) {
                s.setNotifTime(r.hour, r.minute);
                if (s.notificationsEnabled) {
                  await NotificationService.scheduleDaily(
                      r.hour, r.minute, 'تذكير', 'حان وقت العبادات');
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('اختبار إشعار'),
            onTap: () => NotificationService.showTest(),
          ),

          const Divider(),
          const _Header('التخزين السحابي والمزامنة'),
          ListTile(
            leading: Icon(_iconForSync(sync.status)),
            title: const Text('حالة المزامنة'),
            subtitle: Text(sync.lastError ?? sync.status.name),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('فحص الاتصال بالتخزين السحابي'),
            onTap: () async {
              final (ok, err) = await SupabaseService.ping();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? '✅ الاتصال ناجح' : '❌ $err')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('فحص مفصل للتخزين السحابي'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CloudStorageDebugScreen()),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  IconData _iconForViewMode(TabViewMode m) {
    switch (m) {
      case TabViewMode.bottomBar:
        return Icons.view_agenda;
      case TabViewMode.grid:
        return Icons.apps;
      case TabViewMode.topTabs:
        return Icons.view_week;
    }
  }

  IconData _iconForSync(SyncStatus s) {
    switch (s) {
      case SyncStatus.ok:
        return Icons.cloud_done;
      case SyncStatus.syncing:
        return Icons.cloud_sync;
      case SyncStatus.fail:
        return Icons.cloud_off;
      default:
        return Icons.cloud_queue;
    }
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext c) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      );
}
