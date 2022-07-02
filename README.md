# Otter Society Smart Contract

### Terminology

Caller: Caller is a user’s crypto-wallet. This includes admin, owner, whitelist and public addresses.

Re-entrancy:  [https://hackernoon.com/hack-solidity-reentrancy-attack](https://hackernoon.com/hack-solidity-reentrancy-attack)

### Public Mint

- Caller must fit these requirements to access the public minting:
1. Can not be a contract
    
    ```solidity
    /* EOA->A->B->C->D */
        /* if tx.origin and msg.sender are same,
         * msg.sender can NOT be a contract.
         */
        modifier callerIsUser() {
            require(
                tx.origin == msg.sender,
                "Otter Society :: Cannot be called by a contract"
            );
            _;
        }
    ```
    
2. Caller can not call the function again before the execution has ended. (Re-entrancy Guard)
    
    ```solidity
    /**
         * @dev Prevents a contract from calling itself, directly or indirectly.
         * Calling a `nonReentrant` function from another `nonReentrant`
         * function is not supported. It is possible to prevent this from happening
         * by making the `nonReentrant` function external, and making it call a
         * `private` function that does the actual work.
         */
        modifier nonReentrant() {
            // On the first call to nonReentrant, _notEntered will be true
            require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
    
            // Any calls to nonReentrant after this point will fail
            _status = _ENTERED;
    
            _;
    
            // By storing the original value once again, a refund is triggered (see
            // https://eips.ethereum.org/EIPS/eip-2200)
            _status = _NOT_ENTERED;
        }
    ```
    
3. Caller can not access the function when the contract is paused.
    
    ```solidity
    /// @notice As an end-user, when the pause is set to 'false'
        /// you are allowed to access whitelist mint and public mint.
        modifier notPaused() {
            require(!pause, "Otter Society :: Contract is paused.");
            _;
        }
    ```
    
- Following conditions must be met for the function to execute successfully and mint the token to end-user.
1. Public sale must be started by the admin or owner of the contract.
    
    ```solidity
    require(publicSale, "Otter Society :: Not Yet Active.");
    ```
    
2. Total supply (amount of NFTs that were minted to that moment) can NOT exceed the `MAX_SUPPLY`.
    
    ```solidity
    require(
                (totalSupply() + _quantity) <= MAX_SUPPLY,
                "Otter Society :: Beyond Max Supply"
            );
    ```
    
3. User can NOT exceed `MAX_PUBLIC_MINT` when minting from public. 
    
    ```solidity
    require(
                (totalPublicMint[msg.sender] + _quantity) <= MAX_PUBLIC_MINT,
                "Otter Society :: Minted maximum amount."
            );
    ```
    
4. $AVAX amount sent by the end-user must be equal to or higher than `PUBLIC_SALE_PRICE`. End-users can mint their NFTs through Kalao and/or SnowTrace (blockchain explorer of Avalanche’s C-chain)
Note: For $N$ NFTs, you must send at least `PUBLIC_SALE_PRICE * $N$` amount of $AVAX.
    
    ```solidity
    require(
                msg.value >= (PUBLIC_SALE_PRICE * _quantity),
                "Otter Society :: Not enough AVAX. "
            );
    ```
    

### Whitelist Mint

- Caller must fit these requirements to access the whitelist minting:
1. Can not be a contract.
    
    ```solidity
    /* EOA->A->B->C->D */
        /* if tx.origin and msg.sender are same,
         * msg.sender can NOT be a contract.
         */
        modifier callerIsUser() {
            require(
                tx.origin == msg.sender,
                "Otter Society :: Cannot be called by a contract"
            );
            _;
        }
    ```
    
2. Caller can not call the function again before the execution has ended. (Re-entrancy Guard)
    
    ```solidity
    /**
         * @dev Prevents a contract from calling itself, directly or indirectly.
         * Calling a `nonReentrant` function from another `nonReentrant`
         * function is not supported. It is possible to prevent this from happening
         * by making the `nonReentrant` function external, and making it call a
         * `private` function that does the actual work.
         */
        modifier nonReentrant() {
            // On the first call to nonReentrant, _notEntered will be true
            require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
    
            // Any calls to nonReentrant after this point will fail
            _status = _ENTERED;
    
            _;
    
            // By storing the original value once again, a refund is triggered (see
            // https://eips.ethereum.org/EIPS/eip-2200)
            _status = _NOT_ENTERED;
        }
    ```
    
3. Caller can not access the function when the contract is paused.
    
    ```solidity
    /// @notice As an end-user, when the pause is set to 'false'
        /// you are allowed to access whitelist mint and public mint.
        modifier notPaused() {
            require(!pause, "Otter Society :: Contract is paused.");
            _;
        }
    ```
    
4. Caller address must be registered as whitelisted.
    
    ```solidity
    modifier isWhitelisted(address _address) {
            require(whitelistedAddresses[_address], "You need to be whitelisted");
            _;
        }
    ```
    
- Following conditions must be met for the function to execute successfully and mint the token to end-user.
1. Whitelist sale must be started by the admin or owner of the contract.
    
    ```solidity
    require(
                whiteListSale,
                "Otter Society :: White-list minting is on pause"
            );
    ```
    
2. Total supply (amount of NFTs that were minted to that moment) can NOT exceed the `MAX_SUPPLY_WHITELIST`.
    
    ```solidity
    require(
                (totalSupply() + _quantity) <= MAX_SUPPLY_WHITELIST,
                "Otter Society :: Cannot mint beyond max supply"
            );
    ```
    
3. User can NOT exceed `MAX_WHITELIST_MINT` when minting from whitelist. 
**Note**: Whitelisted users can both mint from whitelist & public within the same wallet.
    
    ```solidity
    require(
                (totalWhitelistMint[msg.sender] + _quantity) <= MAX_WHITELIST_MINT,
                "Otter Society :: Cannot mint beyond whitelist max mint!"
            );
    ```
    
4. $AVAX amount sent by the end-user must be equal to or higher than `PUBLIC_SALE_PRICE`. End-users can mint their NFTs through Kalao and/or SnowTrace (blockchain explorer of Avalanche’s C-chain)
Note: For $N$ NFTs, you must send at least `WHITELIST_SALE_PRICE * $N$` amount of $AVAX.
    
    ```solidity
    require(
                msg.value >= (WHITELIST_SALE_PRICE * _quantity),
                "Otter Society :: Payment is below the price"
            );
    ```
    

### Team Mint

- Caller can only be owner or the admin of the contract, Otter Society developer team.
1. Owner of the contract will mint `TEAM_MINT_AMOUNT` to their address for once.
    
    ```solidity
    require(!teamMinted, "Otter Society :: Team already minted.");
    ```
    

### Withdraw

- Caller can be only owner or admin account.
1. On each withdraw, %75 goes to Otter Society developer team, this includes roadmap and crew salaries.
    
    ```solidity
    _withdraw(owner(), (fullBalance * 75) / 100);
    ```
    
2. On each withdraw, %25 goes to DAO wallet, $AVAX in this wallet will NOT be used by the developers of Otter Society, DAO will decide what happens with this wallet.
    
    ```solidity
    _withdraw(marketDAOWallet, (fullBalance * 25) / 100);
    ```
    

### Royalty Fee

> Before sold-out royalty fee: %10
After sold-out royalty fee: %5
**Note:**
Otter Society developer team, or any 3rd party, can NOT set the royalty fee higher than %20
> 

```solidity
	/// Reveal Otter Society on sold-out.
        /// Reduce royalty fee to 5%
        if (totalSupply() == MAX_SUPPLY) {
            isRevealed = true;
            _setDefaultRoyalty(marketDAOWallet, uint96(royaltyDividend / 2));
        }
```

*This documentation has been made & prepared by Otter Society Developer Team for public access and educational purposes. 

This documentation accurately represents The Otter Society NFT Smart Contract that will be used to host The Otter Society NFT Collection.*
