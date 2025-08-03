import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'services/wallet_service.dart';
import 'services/notification_service.dart';
import 'services/test_contract_service.dart';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicios
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trustify Wallet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TrustifyHomePage(title: 'Trustify - Billetera Sepolia'),
    );
  }
}

class TrustifyHomePage extends StatefulWidget {
  const TrustifyHomePage({super.key, required this.title});

  final String title;

  @override
  State<TrustifyHomePage> createState() => _TrustifyHomePageState();
}

class _TrustifyHomePageState extends State<TrustifyHomePage> {
  final WalletService _walletService = WalletService();
  late TestContractService _testContractService;
  String? _walletAddress;
  bool _isLoading = true;
  String _statusMessage = 'Inicializando...';
  bool _isRegistered = false;
  String _balance = '0.0';

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Verificando wallet existente...';
      });

      // Verificar si es la primera vez que se ejecuta la app
      final prefs = await SharedPreferences.getInstance();
      final isFirstRun = prefs.getBool('first_run') ?? true;

      if (isFirstRun) {
        // Primera ejecución - crear nueva wallet
        setState(() {
          _statusMessage = 'Creando nueva wallet...';
        });

        final walletData = await _walletService.createWallet();
        _walletAddress = walletData['address'];

        // Marcar que ya no es la primera ejecución
        await prefs.setBool('first_run', false);

        developer.log('🎉 Nueva wallet creada exitosamente', name: 'TrustifyApp');
        developer.log('📍 Dirección: $_walletAddress', name: 'TrustifyApp');

        // Mostrar SnackBar con la dirección
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Wallet creada!\nDirección: $_walletAddress'),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Wallet ya existe - obtener dirección
        setState(() {
          _statusMessage = 'Cargando wallet existente...';
        });

        _walletAddress = await _walletService.getWalletAddress();

        developer.log('📱 Wallet existente cargada', name: 'TrustifyApp');
        developer.log('📍 Dirección: $_walletAddress', name: 'TrustifyApp');

        if (mounted && _walletAddress != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📱 Wallet cargada!\nDirección: $_walletAddress'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      // Initialize test contract service after wallet is ready
      if (_walletAddress != null) {
        _testContractService = TestContractService(_walletService);
        
        // Check initial contract status
        await _checkRegistrationStatus();
        await _checkBalance();
      }

      setState(() {
        _isLoading = false;
        _statusMessage = _walletAddress != null ? 'Wallet lista' : 'Error cargando wallet';
      });

    } catch (e) {
      developer.log('❌ Error inicializando wallet: $e', name: 'TrustifyApp');
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error inicializando wallet: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _showTestNotification() async {
    try {
      await NotificationService.showTestNotification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔔 Notificación de prueba enviada'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      developer.log('🔔 Notificación de prueba enviada', name: 'TrustifyApp');
    } catch (e) {
      developer.log('❌ Error enviando notificación: $e', name: 'TrustifyApp');
    }
  }

  Future<void> _registerInContract() async {
    try {
      setState(() {
        _statusMessage = 'Registrando dirección en contrato...';
      });

      final txHash = await _testContractService.registerWalletAddress();
      
      if (mounted && txHash != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Dirección registrada!\nTx: ${txHash.substring(0, 10)}...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Esperar un poco para que la transacción se confirme
        await Future.delayed(const Duration(seconds: 3));
        await _checkRegistrationStatus();
      }
    } catch (e) {
      developer.log('❌ Error registrando en contrato: $e', name: 'TrustifyApp');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _checkRegistrationStatus() async {
    try {
      final isRegistered = await _testContractService.isCurrentWalletRegistered();
      setState(() {
        _isRegistered = isRegistered;
        _statusMessage = isRegistered ? 'Registrada en contrato' : 'No registrada';
      });
    } catch (e) {
      developer.log('❌ Error verificando registro: $e', name: 'TrustifyApp');
    }
  }

  Future<void> _checkBalance() async {
    try {
      final balance = await _testContractService.getWalletBalance();
      setState(() {
        _balance = balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(6);
      });
    } catch (e) {
      developer.log('❌ Error obteniendo balance: $e', name: 'TrustifyApp');
    }
  }

  String _formatAddress(String? address) {
    if (address == null || address.length < 10) return 'No disponible';
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Información de la wallet
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Theme.of(context).primaryColor,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Mi Wallet Sepolia',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text(_statusMessage),
                          ],
                        )
                      else ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 8),
                            const Text('Dirección:', style: TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _walletAddress ?? 'No disponible',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (_walletAddress != null) ...[
                                IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.grey),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _walletAddress!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('📋 Dirección copiada al portapapeles'),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dirección corta: ${_formatAddress(_walletAddress)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Sección de notificaciones
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            color: Colors.orange,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Sistema de Notificaciones',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Recibirás notificaciones cuando se emita un certificado NFT a tu nombre.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showTestNotification,
                          icon: const Icon(Icons.notification_add),
                          label: const Text('Probar Notificación'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Contract Testing Section
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.smart_toy,
                            color: Colors.purple,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Test Contract',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Registration Status
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: _isRegistered ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isRegistered ? Colors.green : Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isRegistered ? Icons.verified_user : Icons.warning_amber,
                              color: _isRegistered ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isRegistered ? 'Wallet registrada en contrato' : 'Wallet no registrada',
                                style: TextStyle(
                                  color: _isRegistered ? Colors.green.shade800 : Colors.orange.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Balance Info
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue, width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_wallet, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Balance: $_balance ETH',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _registerInContract,
                              icon: const Icon(Icons.app_registration),
                              label: const Text('Registrar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _checkBalance,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Actualizar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Información adicional
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Información',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• Tu wallet está configurada para la red Sepolia (testnet)\n'
                        '• Las claves privadas se almacenan de forma segura en tu dispositivo\n'
                        '• Recibirás notificaciones automáticamente cuando se emitan certificados\n'
                        '• Esta es una wallet no-custodial: solo tú tienes control de tus claves',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
