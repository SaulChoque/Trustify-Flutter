import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/web3dart.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:http/http.dart';
import 'dart:developer' as developer;

class WalletService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _privateKeyKey = 'wallet_private_key';
  static const String _mnemonicKey = 'wallet_mnemonic';
  static const String _addressKey = 'wallet_address';

  /// Crear una nueva wallet
  Future<Map<String, String>> createWallet() async {
    try {
      // Generar mnemonic (frase de recuperación)
      final mnemonic = bip39.generateMnemonic();
      
      // Generar seed desde el mnemonic
      final seed = bip39.mnemonicToSeed(mnemonic);
      
      // Crear clave privada desde el seed (usando los primeros 32 bytes)
      final privateKeyBytes = seed.sublist(0, 32);
      final privateKeyHex = '0x${privateKeyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
      
      // Crear objeto de clave privada
      final privateKey = EthPrivateKey.fromHex(privateKeyHex);
      final address = privateKey.address.hex;

      // Guardar en almacenamiento seguro
      await _storage.write(key: _privateKeyKey, value: privateKeyHex);
      await _storage.write(key: _mnemonicKey, value: mnemonic);
      await _storage.write(key: _addressKey, value: address);

      developer.log('Nueva wallet creada - Dirección: $address', name: 'WalletService');

      return {
        'address': address,
        'mnemonic': mnemonic,
        'privateKey': privateKeyHex,
      };
    } catch (e) {
      developer.log('Error creando wallet: $e', name: 'WalletService');
      rethrow;
    }
  }

  /// Verificar si ya existe una wallet
  Future<bool> hasWallet() async {
    try {
      final privateKey = await _storage.read(key: _privateKeyKey);
      return privateKey != null && privateKey.isNotEmpty;
    } catch (e) {
      developer.log('Error verificando wallet existente: $e', name: 'WalletService');
      return false;
    }
  }

  /// Obtener la dirección de la wallet
  Future<String?> getWalletAddress() async {
    try {
      return await _storage.read(key: _addressKey);
    } catch (e) {
      developer.log('Error obteniendo dirección: $e', name: 'WalletService');
      return null;
    }
  }

  /// Obtener la clave privada (para transacciones)
  Future<EthPrivateKey?> getPrivateKey() async {
    try {
      final privateKeyHex = await _storage.read(key: _privateKeyKey);
      if (privateKeyHex != null) {
        return EthPrivateKey.fromHex(privateKeyHex);
      }
      return null;
    } catch (e) {
      developer.log('Error obteniendo clave privada: $e', name: 'WalletService');
      return null;
    }
  }

  /// Obtener el mnemonic para backup
  Future<String?> getMnemonic() async {
    try {
      return await _storage.read(key: _mnemonicKey);
    } catch (e) {
      developer.log('Error obteniendo mnemonic: $e', name: 'WalletService');
      return null;
    }
  }

  /// Conectar a la red Sepolia
  Web3Client getSepoliaClient() {
    // Puedes usar tu propio endpoint de Infura o Alchemy aquí
    const rpcUrl = 'https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID';
    return Web3Client(rpcUrl, Client());
  }

  /// Obtener balance de la wallet en Sepolia
  Future<EtherAmount> getBalance() async {
    try {
      final address = await getWalletAddress();
      if (address == null) throw Exception('No hay wallet configurada');

      final client = getSepoliaClient();
      final ethAddress = EthereumAddress.fromHex(address);
      final balance = await client.getBalance(ethAddress);
      
      client.dispose();
      return balance;
    } catch (e) {
      developer.log('Error obteniendo balance: $e', name: 'WalletService');
      rethrow;
    }
  }
}
