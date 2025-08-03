// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title WalletTestContract
 * @dev Contrato de prueba para validar la funcionalidad de la wallet Trustify
 * @author Trustify Team
 */
contract WalletTestContract {
    
    // Events
    event WalletRegistered(address indexed walletAddress, uint256 timestamp);
    event BalanceReceived(address indexed from, uint256 amount);
    
    // State variables
    mapping(address => bool) public registeredWallets;
    mapping(address => uint256) public registrationTimestamp;
    address[] public walletList;
    uint256 public totalRegisteredWallets;
    
    // Owner (quien despliega el contrato)
    address public owner;
    
    // Constructor
    constructor() {
        owner = msg.sender;
    }
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier notAlreadyRegistered() {
        require(!registeredWallets[msg.sender], "Wallet already registered");
        _;
    }
    
    /**
     * @dev Permite a una wallet registrarse en el contrato
     */
    function registerWallet() external notAlreadyRegistered {
        registeredWallets[msg.sender] = true;
        registrationTimestamp[msg.sender] = block.timestamp;
        walletList.push(msg.sender);
        totalRegisteredWallets++;
        
        emit WalletRegistered(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Verifica si una wallet específica está registrada
     * @param walletAddress La dirección de la wallet a verificar
     * @return bool true si está registrada, false si no
     */
    function isWalletRegistered(address walletAddress) external view returns (bool) {
        return registeredWallets[walletAddress];
    }
    
    /**
     * @dev Verifica si la wallet del que llama está registrada
     * @return bool true si está registrada, false si no
     */
    function isMyWalletRegistered() external view returns (bool) {
        return registeredWallets[msg.sender];
    }
    
    /**
     * @dev Obtiene el timestamp de cuando se registró una wallet
     * @param walletAddress La dirección de la wallet
     * @return uint256 timestamp de registro (0 si no está registrada)
     */
    function getRegistrationTime(address walletAddress) external view returns (uint256) {
        require(registeredWallets[walletAddress], "Wallet not registered");
        return registrationTimestamp[walletAddress];
    }
    
    /**
     * @dev Obtiene todas las wallets registradas
     * @return address[] array con todas las direcciones registradas
     */
    function getAllRegisteredWallets() external view returns (address[] memory) {
        return walletList;
    }
    
    /**
     * @dev Permite recibir ETH en el contrato
     */
    receive() external payable {
        emit BalanceReceived(msg.sender, msg.value);
    }
    
    /**
     * @dev Permite al owner retirar ETH del contrato
     * @param amount Cantidad a retirar en wei
     */
    function withdrawETH(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient contract balance");
        payable(owner).transfer(amount);
    }
    
    /**
     * @dev Obtiene el balance del contrato
     * @return uint256 balance en wei
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Función de prueba que retorna información del contrato
     * @return string información básica del contrato
     */
    function getContractInfo() external view returns (
        string memory name,
        uint256 totalWallets,
        uint256 contractBalance,
        address contractOwner
    ) {
        return (
            "Trustify Wallet Test Contract",
            totalRegisteredWallets,
            address(this).balance,
            owner
        );
    }
    
    /**
     * @dev Función para verificar que el contrato funciona correctamente
     * @return string mensaje de confirmación
     */
    function ping() external pure returns (string memory) {
        return "Trustify Contract is working correctly!";
    }
    
    /**
     * @dev Solo para emergencias - permite al owner pausar registros
     */
    bool public registrationPaused = false;
    
    function pauseRegistration() external onlyOwner {
        registrationPaused = true;
    }
    
    function resumeRegistration() external onlyOwner {
        registrationPaused = false;
    }
    
    modifier whenNotPaused() {
        require(!registrationPaused, "Registration is paused");
        _;
    }
    
    // Actualizar la función registerWallet con el modifier
    function registerWalletSafe() external notAlreadyRegistered whenNotPaused {
        registeredWallets[msg.sender] = true;
        registrationTimestamp[msg.sender] = block.timestamp;
        walletList.push(msg.sender);
        totalRegisteredWallets++;
        
        emit WalletRegistered(msg.sender, block.timestamp);
    }
}
