import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await NotificationService.instance.init();
  runApp(const InjazHabitTrackerApp());
}

// ==========================================
// خدمة الإشعارات المحلية فائقة الدقة
// ==========================================
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  Future<void> showInstantTestNotification() async {
    HapticFeedback.lightImpact();
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'injaz_instant_channel',
      'إشعارات إنجاز الفورية',
      channelDescription: 'قناة التنبيهات الفورية',
      importance: Importance.max,
      priority: Priority.high,
    );
    await _plugin.show(
      999999,
      'إنجاز 🎯',
      'نظام التنبيهات يعمل بنجاح وبأقصى سرعة!',
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> scheduleDailyHabitReminder(Habit habit) async {
    if (habit.reminderHour == null || habit.reminderMinute == null) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      habit.reminderHour!,
      habit.reminderMinute!,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final Duration offset = scheduledDate.difference(now);
    final tz.TZDateTime tzScheduled = tz.TZDateTime.now(tz.local).add(offset);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'injaz_daily_habits',
      'تذكيرات العادات اليومية',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _plugin.zonedSchedule(
      habit.notificationId,
      'حان موعد إنجازك 🎯',
      'تذكير بموعد: ${habit.title}',
      tzScheduled,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelHabitReminder(int notificationId) async {
    await _plugin.cancel(notificationId);
  }
}

// ==========================================
// نموذج البيانات الذكي
// ==========================================
class Habit {
  String id;
  String title;
  String category;
  int iconCode;
  List<bool> days;
  int? reminderHour;
  int? reminderMinute;

  Habit({
    required this.id,
    required this.title,
    required this.category,
    required this.iconCode,
    required this.days,
    this.reminderHour,
    this.reminderMinute,
  });

  int get notificationId => id.hashCode & 0x7FFFFFFF;
  bool get hasReminder => reminderHour != null && reminderMinute != null;

  int get maxStreak {
    int maxS = 0, currentS = 0;
    for (bool done in days) {
      if (done) {
        currentS++;
        if (currentS > maxS) maxS = currentS;
      } else {
        currentS = 0;
      }
    }
    return maxS;
  }

  int get completedCount => days.where((d) => d).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'iconCode': iconCode,
        'days': days,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'],
        title: json['title'],
        category: json['category'],
        iconCode: json['iconCode'],
        days: List<bool>.from(json['days']),
        reminderHour: json['reminderHour'],
        reminderMinute: json['reminderMinute'],
      );
}

// ==========================================
// التطبيق الرئيسي والثيم العصري
// ==========================================
class InjazHabitTrackerApp extends StatefulWidget {
  const InjazHabitTrackerApp({super.key});

  @override
  State<InjazHabitTrackerApp> createState() => _InjazHabitTrackerAppState();
}

class _InjazHabitTrackerAppState extends State<InjazHabitTrackerApp> {
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = prefs.getBool('injaz_dark') ?? true);
  }

  void _toggleTheme() async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = !_isDarkMode);
    await prefs.setBool('injaz_dark', _isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF10B981);

    return MaterialApp(
      title: 'إنجاز',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'AE'),
      supportedLocales: const [Locale('ar', 'AE')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: primaryGreen,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: primaryGreen,
        scaffoldBackgroundColor: const Color(0xFF090D16),
        fontFamily: 'Roboto',
      ),
      home: HabitDashboardScreen(
        isDarkMode: _isDarkMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

// ==========================================
// الشاشة الرئيسية المتطورة
// ==========================================
class HabitDashboardScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const HabitDashboardScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<HabitDashboardScreen> createState() => _HabitDashboardScreenState();
}

class _HabitDashboardScreenState extends State<HabitDashboardScreen> {
  static const String _storageKey = 'injaz_data_v3';
  final List<String> _weekDays = ['أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];

  List<Habit> _habits = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategoryFilter = 'الكل';

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString(_storageKey);
    if (stored != null) {
      final List<dynamic> decoded = jsonDecode(stored);
      setState(() {
        _habits = decoded.map((item) => Habit.fromJson(item)).toList();
        _isLoading = false;
      });
    } else {
      final defaults = [
        Habit(
          id: '1',
          title: 'قراءة 20 صفحة يومياً',
          category: 'تعلم',
          iconCode: Icons.menu_book_rounded.codePoint,
          days: [true, true, true, false, true, true, false],
          reminderHour: 20,
          reminderMinute: 0,
        ),
        Habit(
          id: '2',
          title: 'تمارين رياضية ونشاط',
          category: 'صحة',
          iconCode: Icons.fitness_center_rounded.codePoint,
          days: [true, true, true, true, false, true, true],
          reminderHour: 17,
          reminderMinute: 30,
        ),
        Habit(
          id: '3',
          title: 'الورد اليومي والأذكار',
          category: 'روحانيات',
          iconCode: Icons.mosque_rounded.codePoint,
          days: [true, true, true, true, true, true, true],
          reminderHour: 6,
          reminderMinute: 30,
        ),
      ];
      setState(() {
        _habits = defaults;
        _isLoading = false;
      });
      await _saveHabits();
    }
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_habits.map((h) => h.toJson()).toList()));
  }

  void _toggleDay(int habitIndex, int dayIndex) {
    HapticFeedback.mediumImpact();
    setState(() {
      _habits[habitIndex].days[dayIndex] = !_habits[habitIndex].days[dayIndex];
    });
    _saveHabits();
  }

  void _backupAndRestoreDialog() {
    HapticFeedback.lightImpact();
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_sync_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('النسخ الاحتياطي'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('يمكنك نسخ بيانات عاداتك كنص للاحتفاظ بها أو استعادتها في أي وقت:'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('نسخ البيانات'),
                    onPressed: () {
                      final data = jsonEncode(_habits.map((h) => h.toJson()).toList());
                      Clipboard.setData(ClipboardData(text: data));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ بيانات العادات إلى الحافظة بنجاح')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'الصق البيانات هنا للاستعادة',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          FilledButton(
            onPressed: () async {
              try {
                final List<dynamic> decoded = jsonDecode(textController.text.trim());
                final loaded = decoded.map((e) => Habit.fromJson(e)).toList();
                setState(() => _habits = loaded);
                await _saveHabits();
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم استرجاع عاداتك بنجاح!')),
                  );
                }
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('البيانات غير صالحة، تأكد من صحة النص')),
                );
              }
            },
            child: const Text('استعادة الآن'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'صحة':
        return const Color(0xFF10B981);
      case 'تعلم':
        return const Color(0xFF3B82F6);
      case 'إنتاجية':
        return const Color(0xFF8B5CF6);
      case 'روحانيات':
        return const Color(0xFFF59E0B);
      case 'مالي':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF10B981);
    }
  }

  double get _overallCompletionRate {
    if (_habits.isEmpty) return 0.0;
    int total = _habits.length * 7;
    int done = _habits.fold(0, (sum, h) => sum + h.completedCount);
    return (done / total) * 100;
  }

  int get _bestStreak =>
      _habits.isEmpty ? 0 : _habits.map((h) => h.maxStreak).reduce((a, b) => a > b ? a : b);

  List<Habit> get _filteredHabits {
    return _habits.where((h) {
      final matchesSearch = h.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat =
          _selectedCategoryFilter == 'الكل' || h.category == _selectedCategoryFilter;
      return matchesSearch && matchesCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = widget.isDarkMode;
    final cardBg = isDark ? const Color(0xFF131D2D) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 8),
            Text(
              'إنجاز',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'نسخ احتياطي',
            onPressed: _backupAndRestoreDialog,
            icon: const Icon(Icons.cloud_sync_rounded),
          ),
          IconButton(
            tooltip: 'تنبيه تجريبي',
            onPressed: NotificationService.instance.showInstantTestNotification,
            icon: const Icon(Icons.notifications_active_outlined, color: Color(0xFF10B981)),
          ),
          IconButton(
            tooltip: 'المظهر',
            onPressed: widget.onToggleTheme,
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 4,
        onPressed: _showAddHabitModal,
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text('هدف جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 95),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة مؤشرات الأداء والتحفيز
            _buildHeroProgressCard(isDark),
            const SizedBox(height: 16),

            // شريط البحث الذكي
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'بحث في أهدافك وعاداتك...',
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                filled: true,
                fillColor: isDark ? const Color(0xFF131D2D) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // شريط تصنيفات التصفية
            _buildCategoryFilterRow(),
            const SizedBox(height: 16),

            // الرسم البياني السريع
            _buildChartSection(cardBg),
            const SizedBox(height: 20),

            // قائمة العادات
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('العادات الأسبوعية',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${_filteredHabits.length} هدف',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),

            if (_filteredHabits.isEmpty)
              _buildEmptyState()
            else
              ...List.generate(
                _filteredHabits.length,
                (i) => _buildHabitCard(_filteredHabits[i], isDark, cardBg),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroProgressCard(bool isDark) {
    final rate = _overallCompletionRate;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F3B2E), const Color(0xFF112233)]
              : [const Color(0xFFD1FAE5), const Color(0xFFE0F2FE)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: CircularProgressIndicator(
                  value: rate / 100,
                  strokeWidth: 7,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  color: const Color(0xFF10B981),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${rate.toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rate >= 80
                      ? 'أداء استثنائي! 🌟'
                      : rate >= 50
                          ? 'استمر في التقدم 💪'
                          : 'بداية رحلة النجاح 🎯',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'أفضل سلسلة متتالية: $_bestStreak أيام التزام بدون توقف',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterRow() {
    final categories = ['الكل', 'إنتاجية', 'صحة', 'تعلم', 'روحانيات', 'مالي'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategoryFilter == cat;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: const Color(0xFF10B981),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategoryFilter = cat);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartSection(Color cardBg) {
    final maxHabits = _habits.isEmpty ? 1.0 : _habits.length.toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('معدل إنجاز أيام الأسبوع',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: maxHabits,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        int idx = val.toInt();
                        if (idx < 0 || idx >= 7) return const SizedBox();
                        return Text(_weekDays[idx],
                            style: const TextStyle(fontSize: 10, color: Colors.grey));
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(7, (i) {
                  final doneOnDay = _habits.where((h) => h.days[i]).length.toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: doneOnDay,
                        color: const Color(0xFF10B981),
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxHabits,
                          color: Colors.grey.withOpacity(0.08),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, bool isDark, Color cardBg) {
    final habitIndex = _habits.indexOf(habit);
    final catColor = _getCategoryColor(habit.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(IconData(habit.iconCode, fontFamily: 'MaterialIcons'),
                    color: catColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Row(
                      children: [
                        Text(habit.category,
                            style: TextStyle(
                                fontSize: 11, color: catColor, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        const Icon(Icons.local_fire_department_rounded,
                            size: 14, color: Color(0xFFF59E0B)),
                        Text('${habit.maxStreak} أيام متتالية',
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  setState(() => _habits.removeAt(habitIndex));
                  _saveHabits();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (d) {
              final isDone = habit.days[d];
              return InkWell(
                onTap: () => _toggleDay(habitIndex, d),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 40,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF10B981)
                        : (isDark ? const Color(0xFF090D16) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDone ? const Color(0xFF10B981) : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _weekDays[d],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isDone ? Colors.white : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Icon(
                        isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
                        size: 16,
                        color: isDone ? Colors.white : Colors.grey.withOpacity(0.4),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showAddHabitModal() {
    HapticFeedback.lightImpact();
    final titleController = TextEditingController();
    String selectedCategory = 'إنتاجية';
    int selectedIcon = Icons.check_circle_outline_rounded.codePoint;
    TimeOfDay reminderTime = const TimeOfDay(hour: 20, minute: 0);
    bool enableReminder = true;

    final categories = ['إنتاجية', 'صحة', 'تعلم', 'روحانيات', 'مالي'];
    final icons = [
      Icons.check_circle_outline_rounded,
      Icons.menu_book_rounded,
      Icons.fitness_center_rounded,
      Icons.mosque_rounded,
      Icons.water_drop_rounded,
      Icons.savings_rounded,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إضافة عادة جديدة 🎯', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'اسم الهدف أو العادة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                children: categories.map((c) => ChoiceChip(
                  label: Text(c),
                  selected: selectedCategory == c,
                  onSelected: (_) => setModalState(() => selectedCategory = c),
                )).toList(),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: icons.map((ico) => InkWell(
                  onTap: () => setModalState(() => selectedIcon = ico.codePoint),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selectedIcon == ico.codePoint ? const Color(0xFF10B981).withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selectedIcon == ico.codePoint ? const Color(0xFF10B981) : Colors.grey.withOpacity(0.3)),
                    ),
                    child: Icon(ico, color: selectedIcon == ico.codePoint ? const Color(0xFF10B981) : Colors.grey),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تفعيل المنبه اليومي 🔔'),
                value: enableReminder,
                onChanged: (v) => setModalState(() => enableReminder = v),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    final habit = Habit(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      category: selectedCategory,
                      iconCode: selectedIcon,
                      days: List.filled(7, false),
                      reminderHour: enableReminder ? reminderTime.hour : null,
                      reminderMinute: enableReminder ? reminderTime.minute : null,
                    );
                    setState(() => _habits.add(habit));
                    await _saveHabits();
                    if (habit.hasReminder) {
                      await NotificationService.instance.scheduleDailyHabitReminder(habit);
                    }
                    if (mounted) Navigator.pop(ctx);
                  },
                  child: const Text('حفظ الهدف الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: const Column(
        children: [
          Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('لا توجد عادات مطابقة للبحث', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
