import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('caminhadasBox');
  runApp(
    ChangeNotifierProvider(create: (_) => AppState(), child: const MeuApp()),
  );
}

class AppColors {
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color accent = Color(0xFF10B981);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardLight = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
}

class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  List<Map<String, dynamic>> _caminhadas = [];

  ThemeMode get themeMode => _themeMode;
  List<Map<String, dynamic>> get caminhadas => _caminhadas;

  AppState() {
    carregarCaminhadas();
  }

  void alternarTema() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  void carregarCaminhadas() {
    final box = Hive.box('caminhadasBox');
    final dados = box.get('lista', defaultValue: []);
    _caminhadas = List<Map<String, dynamic>>.from(
      dados.map((e) => Map<String, dynamic>.from(e)),
    );
    notifyListeners();
  }

  void adicionarCaminhada(Map<String, dynamic> item) {
    _caminhadas.add(item);
    final box = Hive.box('caminhadasBox');
    box.put('lista', _caminhadas);
    notifyListeners();
  }

  void atualizarCaminhada(int index, Map<String, dynamic> item) {
    _caminhadas[index] = item;
    final box = Hive.box('caminhadasBox');
    box.put('lista', _caminhadas);
    notifyListeners();
  }
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return MaterialApp(
      title: 'App Caminhadas',
      debugShowCheckedModeBanner: false,
      themeMode: appState.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/nova': (context) => const NovaCaminhadaScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward().then((_) {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_walk_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Caminhadas',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acompanhe o seu ritmo',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('As Minhas Caminhadas')),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 30,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'App Caminhadas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Ver Splash Screen'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/splash');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.dark_mode_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Alternar Tema'),
              onTap: () {
                appState.alternarTema();
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Sair',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: appState.caminhadas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma caminhada registada',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Clique no botão + para iniciar uma nova rota.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: appState.caminhadas.length,
              itemBuilder: (context, index) {
                final item = appState.caminhadas[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DetalhesCaminhadaScreen(index: index),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: item['foto'] != null
                              ? Image.network(item['foto'], fit: BoxFit.cover)
                              : Container(
                                  color: AppColors.primary.withAlpha(20),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    color: AppColors.primary,
                                    size: 36,
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['titulo'] ?? 'Sem título',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.straighten,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(item['distancia'] as double).toStringAsFixed(0)}m',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.local_fire_department,
                                    size: 14,
                                    color: Colors.orange,
                                  ),
                                  Text(
                                    (item['calorias'] as double)
                                        .toStringAsFixed(0),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.pushNamed(context, '/nova'),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nova Caminhada',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class NovaCaminhadaScreen extends StatefulWidget {
  const NovaCaminhadaScreen({super.key});

  @override
  State<NovaCaminhadaScreen> createState() => _NovaCaminhadaScreenState();
}

class _NovaCaminhadaScreenState extends State<NovaCaminhadaScreen> {
  LatLng _pontoAtual = const LatLng(-22.705, -46.765);
  LatLng? _pontoDestino;
  List<LatLng> _rota = [];
  double _distanciaMetros = 0;
  double _calorias = 0;
  int _tempoMinutos = 0;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _obterLocalizacaoAtual();
  }

  Future<void> _obterLocalizacaoAtual() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _pontoAtual = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint("Erro GPS: $e");
    }
  }

  Future<void> _buscarRota(LatLng destino) async {
    setState(() {
      _carregando = true;
      _pontoDestino = destino;
    });

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/foot/${_pontoAtual.longitude},${_pontoAtual.latitude};${destino.longitude},${destino.latitude}?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates =
            data['routes'][0]['geometry']['coordinates'] as List;
        final distance = (data['routes'][0]['distance'] as num).toDouble();

        setState(() {
          _rota = coordinates
              .map((c) => LatLng(c[1] as double, c[0] as double))
              .toList();
          _distanciaMetros = distance;
          _calorias = distance * 0.065;
          _tempoMinutos = (distance / 83.3).round();
        });
      }
    } catch (e) {
      debugPrint("Erro OSRM: $e");
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  void _exibirModalSalvar() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Salvar Caminhada',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Distância: ${_distanciaMetros.toStringAsFixed(0)}m',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Tempo: ~$_tempoMinutos min'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Calorias: ${_calorias.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Título do passeio',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final novaCaminhada = {
                  'titulo': controller.text,
                  'distancia': _distanciaMetros,
                  'calorias': _calorias,
                  'tempo': _tempoMinutos,
                  'origem': [_pontoAtual.latitude, _pontoAtual.longitude],
                  'destino': [
                    _pontoDestino!.latitude,
                    _pontoDestino!.longitude,
                  ],
                  'rota': _rota.map((r) => [r.latitude, r.longitude]).toList(),
                  'foto': null,
                };

                Provider.of<AppState>(
                  context,
                  listen: false,
                ).adicionarCaminhada(novaCaminhada);
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecione o Destino')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _pontoAtual,
              initialZoom: 15.0,
              onTap: (_, point) => _buscarRota(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app_caminhadas',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _rota,
                    strokeWidth: 5.0,
                    color: AppColors.primary,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pontoAtual,
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  if (_pontoDestino != null)
                    Marker(
                      point: _pontoDestino!,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 38,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _pontoDestino == null
                    ? Row(
                        children: const [
                          Icon(
                            Icons.touch_app_outlined,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Clique em qualquer ponto do mapa para definir o destino.',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _infoItem(
                                Icons.straighten,
                                '${_distanciaMetros.toStringAsFixed(0)}m',
                                'Distância',
                              ),
                              _infoItem(
                                Icons.timer_outlined,
                                '$_tempoMinutos min',
                                'Tempo',
                              ),
                              _infoItem(
                                Icons.local_fire_department_outlined,
                                '${_calorias.toStringAsFixed(0)} kcal',
                                'Calorias',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _exibirModalSalvar,
                              child: const Text(
                                'Confirmar e Salvar',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (_carregando)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String valor, String rotulo) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          rotulo,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class DetalhesCaminhadaScreen extends StatefulWidget {
  final int index;
  const DetalhesCaminhadaScreen({super.key, required this.index});

  @override
  State<DetalhesCaminhadaScreen> createState() =>
      _DetalhesCaminhadaScreenState();
}

class _DetalhesCaminhadaScreenState extends State<DetalhesCaminhadaScreen> {
  Future<void> _capturarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      final appState = Provider.of<AppState>(context, listen: false);
      final item = Map<String, dynamic>.from(appState.caminhadas[widget.index]);
      item['foto'] = image.path;
      appState.atualizarCaminhada(widget.index, item);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final item = appState.caminhadas[widget.index];

    final LatLng origem = LatLng(item['origem'][0], item['origem'][1]);
    final LatLng destino = LatLng(item['destino'][0], item['destino'][1]);
    final List<LatLng> rota = (item['rota'] as List)
        .map((p) => LatLng((p as List)[0], p[1]))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(item['titulo'] ?? 'Detalhes')),
      body: Column(
        children: [
          GestureDetector(
            onTap: _capturarFoto,
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[200],
              child: item['foto'] != null
                  ? Image.network(item['foto'], fit: BoxFit.cover)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Toque para adicionar uma fotografia',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricTile(
                  'Distância',
                  '${(item['distancia'] as double).toStringAsFixed(0)}m',
                ),
                _metricTile('Tempo', '~${item['tempo']} min'),
                _metricTile(
                  'Calorias',
                  '${(item['calorias'] as double).toStringAsFixed(0)} kcal',
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: FlutterMap(
                options: MapOptions(initialCenter: origem, initialZoom: 14.5),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app_caminhadas',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: rota,
                        strokeWidth: 5.0,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: origem,
                        child: const Icon(
                          Icons.my_location,
                          color: AppColors.primary,
                          size: 30,
                        ),
                      ),
                      Marker(
                        point: destino,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.redAccent,
                          size: 35,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String titulo, String valor) {
    return Column(
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
