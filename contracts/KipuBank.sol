// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title KipuBank
/// @author ---
/** @notice
 *  KipuBank permite a usuarios depositar ETH en bóvedas personales y retirar
 *  hasta un límite por transacción. El contrato tiene un límite global de
 *  depósitos (bankCap) y sigue prácticas de seguridad (checks-effects-interactions,
 *  nonReentrant, errores personalizados).
 */
contract KipuBank {
    // ======= ERRORS =========
    /// @notice Revert when a zero value is sent where a positive amount is required.
    error InvalidValue();

    /// @notice Revert when a deposit would cause the global cap to be exceeded.
    error BankCapExceeded(uint256 currentTotal, uint256 attemptedDeposit, uint256 bankCap);

    /// @notice Revert when user balance is insufficient for requested withdrawal.
    error InsufficientBalance(uint256 available, uint256 requested);

    /// @notice Revert when requested withdrawal amount exceeds per-tx immutable limit.
    error WithdrawLimitExceeded(uint256 requested, uint256 limit);

    /// @notice Revert when native transfer fails.
    error TransferFailed(address to, uint256 amount);

    // ======= EVENTS =========
    /// @notice Emitted when a user deposits ETH.
    event Deposited(address indexed user, uint256 amount);

    /// @notice Emitted when a user withdraws ETH.
    event Withdrawn(address indexed user, uint256 amount);

    // === STATE VARIABLES ====
    /// @notice Mapping user => balance (wei)
    mapping(address => uint256) private balances;

    /// @notice Total ETH currently held (wei)
    uint256 public totalDeposits;

    /// @notice Number of deposit operations performed
    uint256 public totalDepositCount;

    /// @notice Number of withdraw operations performed
    uint256 public totalWithdrawCount;

    /// @notice Maximum allowed total deposits into the contract (immutable, set at deploy)
    uint256 public immutable bankCap;

    /// @notice Maximum allowed withdrawal per transaction (immutable, set at deploy)
    uint256 public immutable withdrawLimitPerTx;

    /// @notice Reentrancy guard state
    bool private locked;

    // ========================
    // ======= CONSTRUCTOR ====
    /// @notice Deploy the contract with a global cap and per-tx withdraw limit.
    /// @param _bankCap Maximum total deposits allowed (in wei)
    /// @param _withdrawLimitPerTx Maximum withdraw amount per tx (in wei)
    constructor(uint256 _bankCap, uint256 _withdrawLimitPerTx) {
        bankCap = _bankCap;
        withdrawLimitPerTx = _withdrawLimitPerTx;
    }

     // ======= MODIFIERS ======
    /// @notice Simple non-reentrant modifier using a boolean lock.
    modifier nonReentrant() {
        if (locked) revert();
        locked = true;
        _;
        locked = false;
    }

     // ======= EXTERNALS ======
   
    /// @notice Deposit ETH into the sender's vault.
    /// @dev Uses checks-effects-interactions. Reverts with custom errors.
    function deposit() external payable {
        if (msg.value == 0) revert InvalidValue();

        uint256 newTotal = totalDeposits + msg.value;
        if (newTotal > bankCap) revert BankCapExceeded(totalDeposits, msg.value, bankCap);

        // effects
        balances[msg.sender] += msg.value;
        totalDeposits = newTotal;
        totalDepositCount++;

        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Withdraw up to the per-transaction limit from caller's vault.
    /// @param amount Amount in wei to withdraw.
    /// @dev nonReentrant, checks-effects-interactions, uses private _safeSend for transfer.
    function withdraw(uint256 amount) external nonReentrant {
        uint256 balanceUser = balances[msg.sender];
        if (balanceUser < amount) revert InsufficientBalance(balanceUser, amount);
        if (amount > withdrawLimitPerTx) revert WithdrawLimitExceeded(amount, withdrawLimitPerTx);
        if (amount == 0) revert InvalidValue();

        // --- effects (reduce balance before external call)
        balances[msg.sender] = balanceUser - amount;
        totalWithdrawCount++;

        // --- interactions
        _safeSend(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    // ======= VIEWS ==========
    
    /// @notice Get the balance of a user (wei)
    /// @param user Address to query
    /// @return balance User's balance in wei
    function getBalance(address user) external view returns (uint256 balance) {
        return balances[user];
    }

    /// @notice Returns basic bank stats.
    /// @return _totalDeposits total deposits held (wei)
    /// @return _depositCount number of deposit operations
    /// @return _withdrawCount number of withdraw operations
    function getBankStats()
        external
        view
        returns (uint256 _totalDeposits, uint256 _depositCount, uint256 _withdrawCount)
    {
        return (totalDeposits, totalDepositCount, totalWithdrawCount);
    }

    // ======= PRIVATE ========
    
    /// @notice Internal helper to send ETH safely via call and revert on failure.
    /// @param to Recipient address
    /// @param amount Amount in wei
    function _safeSend(address to, uint256 amount) private {
        (bool success, ) = to.call{value: amount}("");
        if (!success) revert TransferFailed(to, amount);
    }

    // ==== FALLBACK/RECV =====
    
    /// @notice Reject plain ETH transfers; force users to call deposit().
    receive() external payable {
        revert InvalidValue();
    }

    fallback() external payable {
        revert InvalidValue();
    }
}
