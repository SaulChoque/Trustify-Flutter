import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import '../services/wallet_service.dart';
import 'dart:developer' as developer;

/// Servicio para interactuar con el contrato de prueba en Sepolia
class TestContractService {
  late Web3Client _client;
  late DeployedContract _contract;
  final WalletService _walletService;
  
  // Contract address (Update this after deploying the contract)
  static const String _contractAddress = '0xf24e12Ef8aAcB99FC5843Fc56BEA0BFA5B039BFF'; // TODO: Update with deployed contract address
  
  // Endpoint RPC de Sepolia - reemplaza con tu PROJECT_ID de Infura
  static const String rpcUrl = 'https://sepolia.optimism.io/api?';
  
  // ABI del contrato de prueba
  static const String contractABI = '''[
    {
      "inputs": [],
      "name": "registerAddress",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name": "walletAddress", "type": "address"}],
      "name": "isAddressRegistered",
      "outputs": [{"name": "", "type": "bool"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"name": "", "type": "address"}],
      "name": "registeredAddresses",
      "outputs": [{"name": "", "type": "bool"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "anonymous": false,
      "inputs": [
        {"indexed": true, "name": "walletAddress", "type": "address"}
      ],
      "name": "AddressRegistered",
      "type": "event"
    }
  ]''';

  TestContractService(this._walletService) {
    _client = Web3Client(rpcUrl, Client());
    _loadContract();
  }

  void _loadContract() {
    _contract = DeployedContract(
      ContractAbi.fromJson(contractABI, 'TestWalletContract'),
      EthereumAddress.fromHex(_contractAddress),
    );
  }

  /// Registrar la dirección de la wallet en el contrato
  Future<String?> registerWalletAddress() async {
    try {
      // Verificar que tengamos la clave privada
      final privateKey = await _walletService.getPrivateKey();
      if (privateKey == null) {
        throw Exception('No se pudo obtener la clave privada');
      }

      final function = _contract.function('registerAddress');
      
      // Estimar gas
      final gasEstimate = await _client.estimateGas(
        sender: privateKey.address,
        to: _contract.address,
        data: function.encodeCall([]),
      );

      // Crear transacción
      final transaction = Transaction.callContract(
        contract: _contract,
        function: function,
        parameters: [],
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 gwei
        maxGas: gasEstimate.toInt() + 10000, // Agregar buffer de gas
      );

      // Enviar transacción
      final txHash = await _client.sendTransaction(
        privateKey,
        transaction,
        chainId: 11155111, // Sepolia chain ID
      );

      developer.log('🚀 Transacción enviada: $txHash', name: 'TestContract');
      developer.log('📍 Registrando dirección: ${privateKey.address.hex}', name: 'TestContract');

      return txHash;
    } catch (e) {
      developer.log('❌ Error registrando dirección: $e', name: 'TestContract');
      rethrow;
    }
  }

  /// Verificar si la dirección está registrada
  Future<bool> isAddressRegistered(String walletAddress) async {
    try {
      final function = _contract.function('isAddressRegistered');
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [EthereumAddress.fromHex(walletAddress)],
      );
      
      final isRegistered = result.first as bool;
      developer.log('✅ Dirección $walletAddress registrada: $isRegistered', name: 'TestContract');
      
      return isRegistered;
    } catch (e) {
      developer.log('❌ Error verificando dirección: $e', name: 'TestContract');
      return false;
    }
  }

  /// Verificar si la wallet actual está registrada
  Future<bool> isCurrentWalletRegistered() async {
    try {
      final walletAddress = await _walletService.getWalletAddress();
      if (walletAddress == null) {
        return false;
      }
      return await isAddressRegistered(walletAddress);
    } catch (e) {
      developer.log('❌ Error verificando wallet actual: $e', name: 'TestContract');
      return false;
    }
  }

  /// Escuchar eventos de registro de direcciones
  Stream<AddressRegisteredEvent> listenToRegistrationEvents() {
    final event = _contract.event('AddressRegistered');
    
    return _client
        .events(FilterOptions.events(
          contract: _contract,
          event: event,
          fromBlock: const BlockNum.current(),
        ))
        .map((eventLog) {
          // Los eventos indexados aparecen en topics
          final addressHex = eventLog.topics![1]!;
          final address = EthereumAddress.fromHex(
            '0x${addressHex.substring(26)}' // Remover padding de 0x000...
          );
          
          return AddressRegisteredEvent(
            walletAddress: address,
            blockNumber: 0, // Simplificado para evitar errores de API
            transactionHash: eventLog.transactionHash ?? '',
          );
        });
  }

  /// Obtener el balance de ETH de Sepolia de la wallet
  Future<EtherAmount> getWalletBalance() async {
    try {
      final walletAddress = await _walletService.getWalletAddress();
      if (walletAddress == null) {
        return EtherAmount.zero();
      }

      final address = EthereumAddress.fromHex(walletAddress);
      final balance = await _client.getBalance(address);
      
      developer.log('💰 Balance de Sepolia: ${balance.getValueInUnit(EtherUnit.ether)} SepoliaETH', 
                   name: 'TestContract');
      
      return balance;
    } catch (e) {
      developer.log('❌ Error obteniendo balance: $e', name: 'TestContract');
      return EtherAmount.zero();
    }
  }

  /// Actualizar dirección del contrato después del deployment
  void updateContractAddress(String newAddress) {
    _contract = DeployedContract(
      ContractAbi.fromJson(contractABI, 'TestWalletContract'),
      EthereumAddress.fromHex(newAddress),
    );
    developer.log('📝 Dirección del contrato actualizada: $newAddress', name: 'TestContract');
  }

  /// Cerrar conexiones
  void dispose() {
    _client.dispose();
  }
}

/// Evento de dirección registrada
class AddressRegisteredEvent {
  final EthereumAddress walletAddress;
  final int blockNumber;
  final String transactionHash;

  AddressRegisteredEvent({
    required this.walletAddress,
    required this.blockNumber,
    required this.transactionHash,
  });

  @override
  String toString() {
    return 'AddressRegisteredEvent(address: ${walletAddress.hex}, block: $blockNumber)';
  }
}
