# 🧪 Deploy del Contrato de Prueba - Trustify

## 📋 Instrucciones para Remix IDE

### 1. Preparación
1. Ve a [Remix IDE](https://remix.ethereum.org/)
2. Crea un nuevo archivo llamado `WalletTestContract.sol`
3. Copia y pega el código del contrato desde `contracts/WalletTestContract.sol`

### 2. Compilación
1. Ve a la pestaña "Solidity Compiler" (ícono de Solidity)
2. Selecciona la versión del compilador: `0.8.19+` o superior
3. Haz clic en "Compile WalletTestContract.sol"
4. Verifica que no hay errores

### 3. Deploy en Sepolia
1. Ve a la pestaña "Deploy & Run Transactions"
2. Configura el Environment a "Injected Provider - MetaMask"
3. Asegúrate de que MetaMask esté conectado a la red **Sepolia Testnet**
4. Selecciona el contrato `WalletTestContract`
5. Haz clic en "Deploy"
6. Confirma la transacción en MetaMask

### 4. Configuración en la App
Una vez deployado el contrato:

1. **Copia la dirección del contrato** desde Remix (aparece en "Deployed Contracts")
2. **Actualiza la app Flutter**:
   - Ve al archivo `lib/services/test_contract_service.dart`
   - Reemplaza la línea:
     ```dart
     static const String _contractAddress = '0x0000000000000000000000000000000000000000';
     ```
   - Con tu dirección real:
     ```dart
     static const String _contractAddress = 'TU_DIRECCION_DE_CONTRATO_AQUI';
     ```

### 5. Obtener ETH de Prueba
Para probar la app necesitarás ETH de Sepolia:

1. Ve a un faucet de Sepolia:
   - [Sepolia Faucet de Alchemy](https://sepoliafaucet.com/)
   - [Chainlink Faucet](https://faucets.chain.link/)
2. Ingresa la dirección de tu wallet (la que aparece en la app)
3. Solicita ETH de prueba

## 🔧 Funciones del Contrato

### Funciones Principales
- `registerWallet()`: Registra la wallet actual
- `isWalletRegistered(address)`: Verifica si una wallet está registrada
- `isMyWalletRegistered()`: Verifica si tu wallet está registrada
- `ping()`: Función de prueba simple

### Funciones de Información
- `getContractInfo()`: Información general del contrato
- `getAllRegisteredWallets()`: Lista todas las wallets registradas
- `getRegistrationTime(address)`: Timestamp de registro de una wallet

### Events
- `WalletRegistered`: Se emite cuando una wallet se registra
- `BalanceReceived`: Se emite cuando el contrato recibe ETH

## 🧪 Probar la App

Una vez configurado todo:

1. **Abre la app Trustify**
2. **Verifica que la wallet se cree** correctamente
3. **Toca "Registrar"** en la sección "Test Contract"
4. **Verifica el estado** - debería mostrar "Wallet registrada"
5. **Toca "Actualizar"** para ver el balance actualizado

## 🐛 Troubleshooting

### Error: "Contract address is invalid"
- Verifica que hayas actualizado `_contractAddress` con la dirección real
- Asegúrate de que la dirección empiece con `0x`

### Error: "Insufficient funds"
- Necesitas ETH de Sepolia para realizar transacciones
- Usa un faucet para obtener ETH de prueba

### Error: "Wrong network"
- Verifica que tanto MetaMask como la app estén en Sepolia
- La app usa automáticamente Sepolia

### La wallet no se registra
- Verifica que tengas suficiente ETH para la transacción
- Checa que el contrato esté desplegado correctamente

## 📱 Logs Útiles

Para debug, revisa los logs en la consola de Flutter:
```bash
flutter logs
```

Busca logs que empiecen con:
- `🎉 Nueva wallet creada`
- `📍 Dirección:`
- `✅ Wallet registrada en contrato`
- `❌ Error:` (para errores)

---

## 🎯 Siguiente Paso

Una vez que el contrato de prueba funcione correctamente, estarás listo para implementar contratos más complejos para certificados NFT y firmas digitales.

¡La base de la wallet ya está funcionando! 🚀
