import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'dart:developer' as developer;

/// Ejemplo de servicio para interactuar con contratos de certificados NFT
/// Este es un ejemplo de cómo podrías extender la funcionalidad para 
/// interactuar con contratos reales de certificados.
class CertificateContractService {
  late Web3Client _client;
  late DeployedContract _contract;
  
  // Dirección del contrato de certificados (ejemplo)
  static const String contractAddress = '0x1234567890123456789012345678901234567890';
  
  // Endpoint RPC de Sepolia - reemplazar con tu endpoint real
  static const String rpcUrl = 'https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID';
  
  // ABI del contrato (ejemplo simplificado)
  static const String contractABI = '''[
    {
      "inputs": [
        {"name": "to", "type": "address"},
        {"name": "certificateName", "type": "string"},
        {"name": "certificateData", "type": "string"}
      ],
      "name": "issueCertificate",
      "outputs": [{"name": "tokenId", "type": "uint256"}],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name": "owner", "type": "address"}],
      "name": "getCertificates",
      "outputs": [{"name": "", "type": "uint256[]"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"name": "tokenId", "type": "uint256"}],
      "name": "getCertificateInfo",
      "outputs": [
        {"name": "name", "type": "string"},
        {"name": "data", "type": "string"},
        {"name": "timestamp", "type": "uint256"}
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "anonymous": false,
      "inputs": [
        {"indexed": true, "name": "to", "type": "address"},
        {"indexed": true, "name": "tokenId", "type": "uint256"},
        {"indexed": false, "name": "certificateName", "type": "string"}
      ],
      "name": "CertificateIssued",
      "type": "event"
    }
  ]''';

  CertificateContractService() {
    _client = Web3Client(rpcUrl, Client());
    _loadContract();
  }

  void _loadContract() {
    _contract = DeployedContract(
      ContractAbi.fromJson(contractABI, 'CertificateContract'),
      EthereumAddress.fromHex(contractAddress),
    );
  }

  /// Obtener los certificados de una dirección
  Future<List<CertificateInfo>> getCertificatesForAddress(String address) async {
    try {
      final ethAddress = EthereumAddress.fromHex(address);
      final function = _contract.function('getCertificates');
      
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [ethAddress],
      );
      
      List<BigInt> tokenIds = List<BigInt>.from(result.first);
      List<CertificateInfo> certificates = [];
      
      // Obtener información de cada certificado
      for (BigInt tokenId in tokenIds) {
        final info = await getCertificateInfo(tokenId);
        if (info != null) {
          certificates.add(info);
        }
      }
      
      developer.log('Obtenidos ${certificates.length} certificados para $address', 
                   name: 'CertificateService');
      
      return certificates;
    } catch (e) {
      developer.log('Error obteniendo certificados: $e', name: 'CertificateService');
      return [];
    }
  }

  /// Obtener información de un certificado específico
  Future<CertificateInfo?> getCertificateInfo(BigInt tokenId) async {
    try {
      final function = _contract.function('getCertificateInfo');
      
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [tokenId],
      );
      
      return CertificateInfo(
        tokenId: tokenId,
        name: result[0] as String,
        data: result[1] as String,
        timestamp: result[2] as BigInt,
      );
    } catch (e) {
      developer.log('Error obteniendo info del certificado $tokenId: $e', 
                   name: 'CertificateService');
      return null;
    }
  }

  /// Escuchar eventos de certificados emitidos
  Stream<CertificateIssuedEvent> listenToCertificateEvents(String userAddress) {
    final event = _contract.event('CertificateIssued');
    final ethAddress = EthereumAddress.fromHex(userAddress);
    
    return _client
        .events(FilterOptions.events(
          contract: _contract,
          event: event,
          fromBlock: const BlockNum.current(),
        ))
        .where((event) => 
            event.topics!.length > 1 && 
            EthereumAddress.fromHex(event.topics![1]!) == ethAddress)
        .map((event) {
          // Parse the event data manually since decodedResults is not available
          // This is a simplified version - in production you'd need proper ABI decoding
          return CertificateIssuedEvent(
            to: EthereumAddress.fromHex(event.topics![1]!),
            tokenId: BigInt.from(0), // Placeholder - would need proper decoding
            certificateName: 'Certificate', // Placeholder - would need proper decoding
            blockNumber: 0, // Placeholder - event.blockNumber is not available
            transactionHash: event.transactionHash!,
          );
        });
  }

  /// Cerrar conexiones
  void dispose() {
    _client.dispose();
  }
}

/// Información de un certificado
class CertificateInfo {
  final BigInt tokenId;
  final String name;
  final String data;
  final BigInt timestamp;

  CertificateInfo({
    required this.tokenId,
    required this.name,
    required this.data,
    required this.timestamp,
  });

  DateTime get issuedDate => DateTime.fromMillisecondsSinceEpoch(
    timestamp.toInt() * 1000,
  );

  @override
  String toString() {
    return 'CertificateInfo(tokenId: $tokenId, name: $name, issued: $issuedDate)';
  }
}

/// Evento de certificado emitido
class CertificateIssuedEvent {
  final EthereumAddress to;
  final BigInt tokenId;
  final String certificateName;
  final int blockNumber;
  final String transactionHash;

  CertificateIssuedEvent({
    required this.to,
    required this.tokenId,
    required this.certificateName,
    required this.blockNumber,
    required this.transactionHash,
  });

  @override
  String toString() {
    return 'CertificateIssuedEvent(to: $to, tokenId: $tokenId, name: $certificateName)';
  }
}

/// Ejemplo de uso del servicio de certificados
class CertificateServiceExample {
  static Future<void> exampleUsage() async {
    final service = CertificateContractService();
    final userAddress = '0x742d35Cc6bf6b4Fd0C3DB4e1a8E8F8D12345678910';
    
    try {
      // Obtener certificados del usuario
      final certificates = await service.getCertificatesForAddress(userAddress);
      developer.log('Usuario tiene ${certificates.length} certificados', 
                   name: 'Example');
      
      for (final cert in certificates) {
        developer.log('Certificado: ${cert.name} - Emitido: ${cert.issuedDate}', 
                     name: 'Example');
      }
      
      // Escuchar nuevos certificados
      service.listenToCertificateEvents(userAddress).listen((event) {
        developer.log('¡Nuevo certificado recibido: ${event.certificateName}!', 
                     name: 'Example');
        
        // Aquí podrías disparar una notificación
        // NotificationService.showCertificateNotification(
        //   certificateName: event.certificateName,
        // );
      });
      
    } finally {
      service.dispose();
    }
  }
}
