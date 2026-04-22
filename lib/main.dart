import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
// PERBAIKAN: Import library intl untuk menangani lokalisasi
import 'package:intl/date_symbol_data_local.dart';

import 'app/routes.dart';
import 'app/theme.dart';
import 'models/transaction_model.dart';
import 'models/savings_model.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/transaction_service.dart';
import 'services/savings_service.dart';

/// Entry point utama aplikasi DompetKu
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // PERBAIKAN: Inisialisasi data format tanggal dan mata uang untuk lokal Indonesia (id_ID)
  // Ini akan menghilangkan error LocaleDataException
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Hive untuk penyimpanan lokal
  await Hive.initFlutter();

  // Daftarkan adapter Hive
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(SavingsModelAdapter());
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());
  Hive.registerAdapter(TransactionCategoryAdapter());

  // Buka box Hive yang diperlukan
  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox<SavingsModel>('savings');
  await Hive.openBox<UserModel>('users');
  await Hive.openBox('settings');

  // Paksa orientasi portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set warna status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const DompetKuApp());
}

/// Widget utama aplikasi
class DompetKuApp extends StatelessWidget {
  const DompetKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => TransactionService()),
        ChangeNotifierProvider(create: (_) => SavingsService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'DompetKu',
            debugShowCheckedModeBanner: false,
            // Tambahkan konfigurasi locale agar format otomatis mengikuti standar Indonesia
            locale: const Locale('id', 'ID'),
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}
