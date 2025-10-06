# KipuBank

## Descripción

KipuBank es un contrato inteligente en Solidity que permite a los usuarios **depositar y retirar ETH** de manera segura, con límites predefinidos.  

- Cada usuario tiene una **bóveda personal** para sus depósitos.  
- El contrato mantiene un **registro de depósitos y retiros**.  
- Hay un **límite global de depósitos** (`bankCap`) y un **límite de retiro por transacción** (`withdrawLimitPerTx`).  
- Se siguen buenas prácticas de seguridad: errores personalizados, protección contra reentrancy y transferencias seguras.

---

## Instrucciones de despliegue

1. Abrir [Remix IDE](https://remix.ethereum.org/).  
2. Crear un archivo llamado `KipuBank.sol` dentro de `/contracts` y pegar el código del contrato.  
3. Seleccionar **Injected Web3** como entorno para conectarse a **MetaMask** en la red **Sepolia**.  
4. Seleccionar la versión del compilador `0.8.20`.  
5. Ingresar los parámetros del constructor:
   - `_bankCap` → límite global de depósitos en **wei** (ej. `100000000000000000000` para 100 ETH).  
   - `_withdrawLimitPerTx` → límite de retiro por transacción en **wei** (ej. `1000000000000000000` para 1 ETH).  
6. Hacer clic en **Deploy** y confirmar la transacción en MetaMask.

> Nota: No enviar ETH en el constructor (no es `payable`).

---

## Cómo interactuar con el contrato

### 1. Depositar ETH
- Función: `deposit() payable`  
- Campo Value: monto de ETH a depositar  
- Restricciones: no se puede depositar 0 y el total de depósitos no puede superar `bankCap`  
- Evento emitido: `Deposited(address, amount)`

### 2. Retirar ETH
- Función: `withdraw(uint256 amount)`  
- Parámetro: cantidad a retirar en wei  
- Restricciones: saldo suficiente y no superar `withdrawLimitPerTx`  
- Evento emitido: `Withdrawn(address, amount)`

### 3. Consultar saldo
- Función: `getBalance(address user)`  
- Retorna el saldo actual del usuario en wei.

### 4. Consultar estadísticas del banco
- Función: `getBankStats()`  
- Retorna: total de depósitos, número de depósitos y número de retiros.

---

## Licencia

MIT
