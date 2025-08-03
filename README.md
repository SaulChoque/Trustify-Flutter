# Trustify - Billetera Sepolia 

Una aplicación móvil Flutter que crea y gestiona una billetera Ethereum no-custodial para la red Sepolia (testnet), específicamente diseñada para interactuar con contratos de certificados NFT.

## 🚀 Características

### ✅ **Wallet No-Custodial**
- **Creación automática**: La wallet se genera automáticamente en el primer uso
- **Almacenamiento seguro**: Las claves privadas se almacenan de forma cifrada usando `flutter_secure_storage`
- **Red Sepolia**: Configurada para trabajar con la testnet de Ethereum
- **Control total**: Solo el usuario tiene acceso a sus claves privadas

### ✅ **Sistema de Notificaciones**
- **Notificaciones push locales**: Alerta cuando se emite un certificado NFT
- **Botón de prueba**: Funcionalidad para probar el sistema de notificaciones
- **Configuración automática**: Permisos y canales configurados automáticamente

### ✅ **Interfaz Simplificada**
- **UX amigable**: Diseñada para usuarios sin conocimientos de Web3
- **Información clara**: Muestra la dirección de la wallet de forma legible
- **Feedback visual**: Estados de carga y mensajes informativos
- **Logs detallados**: Información de desarrollo en la consola

## 📱 Funcionalidades Implementadas

### 🔐 **Gestión de Wallet**
```dart
// Creación automática en primer uso
final walletData = await _walletService.createWallet();

// Verificación de wallet existente
final hasWallet = await _walletService.hasWallet();

// Obtención de dirección
final address = await _walletService.getWalletAddress();
```

### 🔔 **Sistema de Notificaciones**
```dart
// Mostrar notificación de certificado
await NotificationService.showCertificateNotification(
  certificateName: 'Mi Certificado NFT',
  issuerName: 'Trustify Platform',
);
```

## 🛠️ **Instalación y Configuración**

### Prerrequisitos
- Flutter SDK 3.8.1+
- Android Studio / VS Code
- Dispositivo Android o emulador

### Pasos de instalación

1. **Clonar el repositorio**
```bash
git clone <repo-url>
cd trustify
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Ejecutar la aplicación**
```bash
flutter run
```

## 📦 **Dependencias Principales**

```yaml
dependencies:
  # Web3 y Blockchain
  web3dart: ^2.7.3
  bip39: ^1.0.6
  
  # Almacenamiento seguro
  flutter_secure_storage: ^9.2.2
  
  # Notificaciones
  flutter_local_notifications: ^17.2.2
  
  # Utilidades
  shared_preferences: ^2.2.2
  http: ^1.1.0
  crypto: ^3.0.3
```

## 🔧 **Configuración para Producción**

### Para usar con un nodo real de Sepolia:

1. **Obtener un endpoint RPC** (Infura, Alchemy, etc.)
2. **Actualizar el endpoint** en `wallet_service.dart`:
```dart
const rpcUrl = 'https://sepolia.infura.io/v3/TU_PROJECT_ID';
```

### Para conectar con contratos reales:
```dart
// Ejemplo de interacción con contrato
final contract = DeployedContract(
  ContractAbi.fromJson(abiJson, "TrustifyContract"),
  EthereumAddress.fromHex("DIRECCION_DEL_CONTRATO"),
);
```

## 📋 **Flujo de Usuario**

1. **Primera apertura**: 
   - Se crea automáticamente una nueva wallet
   - Se muestran logs en consola con la dirección
   - Aparece SnackBar confirmando la creación

2. **Aperturas posteriores**:
   - Se carga la wallet existente
   - Se muestra la dirección en la interfaz
   - Sistema listo para recibir notificaciones

3. **Prueba de notificaciones**:
   - Botón "Probar Notificación" en la interfaz
   - Se dispara una notificación de prueba
   - Logs en consola para debugging

## 🔒 **Seguridad**

### Características de seguridad implementadas:
- ✅ Claves privadas nunca expuestas en la UI
- ✅ Almacenamiento cifrado usando Keystore/Keychain
- ✅ Generación de claves usando librerías estándar
- ✅ Validación de permisos para notificaciones

### Recomendaciones adicionales para producción:
- [ ] Implementar autenticación biométrica
- [ ] Agregar frases de recuperación (seed phrases)
- [ ] Implementar backup y recuperación
- [ ] Validar certificados SSL para conexiones RPC

## 📊 **Logs y Debugging**

La aplicación genera logs detallados para desarrollo:

```
🎉 Nueva wallet creada exitosamente
📍 Dirección: 0x742d35Cc6bf...
📱 Wallet existente cargada
🔔 Notificación de prueba enviada
```

## 🚧 **Próximas Funcionalidades**

- [ ] Integración con contratos de certificados reales
- [ ] Visualización de NFTs certificados
- [ ] Historial de transacciones
- [ ] Backup y recuperación de wallet
- [ ] Autenticación biométrica
- [ ] Soporte para múltiples redes

## 📞 **Soporte**

Para reportar problemas o solicitar funcionalidades, crear un issue en el repositorio.

## 📄 **Licencia**

[Especificar licencia aquí]

---

**⚠️ Nota Importante**: Esta aplicación está configurada para Sepolia (testnet). Para uso en producción con Ethereum mainnet, revisar y actualizar todas las configuraciones de seguridad.
