### Terminology

Caller: Caller is a user’s crypto-wallet. This includes admin, owner, whitelist and public addresses.

Re-entrancy:  [https://hackernoon.com/hack-solidity-reentrancy-attack](https://hackernoon.com/hack-solidity-reentrancy-attack)

### Public Mint

- Caller must fit these requirements to access the public minting:
1. Can not be a contract
2. Caller can not call the function again before the execution has ended. (Re-entrancy Guard)
3. Caller can not access the function when the contract is paused.
- Following conditions must be met for the function to execute successfully and mint the token to end-user.
1. Public sale must be started by the admin or owner of the contract.
2. Total supply (amount of NFTs that were minted to that moment) can NOT exceed the `MAX_SUPPLY`.
3. User can NOT exceed `MAX_PUBLIC_MINT` when minting from public. 
4. $AVAX amount sent by the end-user must be equal to or higher than `PUBLIC_SALE_PRICE`. End-users can mint their NFTs through Kalao and/or SnowTrace (blockchain explorer of Avalanche’s C-chain)
Note: For $N$ NFTs, you must send at least `PUBLIC_SALE_PRICE * N` amount of $AVAX.

> Before sold-out royalty fee: %10
After sold-out royalty fee: %5
**Note:**
Otter Society developer team, or any 3rd party, can NOT set the royalty fee higher than %20
> 

### Whitelist Mint

- Caller must fit these requirements to access the whitelist minting:
1. Can not be a contract.
2. Caller can not call the function again before the execution has ended. (Re-entrancy Guard)
3. Caller can not access the function when the contract is paused.
4. Caller address must be registered as whitelisted.
- Following conditions must be met for the function to execute successfully and mint the token to end-user.
1. Whitelist sale must be started by the admin or owner of the contract.
2. Total supply (amount of NFTs that were minted to that moment) can NOT exceed the `MAX_SUPPLY_WHITELIST`.
3. User can NOT exceed `MAX_WHITELIST_MINT` when minting from whitelist. 
**Note**: Whitelisted users can both mint from whitelist & public within the same wallet.
4. $AVAX amount sent by the end-user must be equal to or higher than `PUBLIC_SALE_PRICE`. End-users can mint their NFTs through Kalao and/or SnowTrace (blockchain explorer of Avalanche’s C-chain)
Note: For $N$ NFTs, you must send at least `WHITELIST_SALE_PRICE * N` amount of $AVAX.

### Team Mint

- Caller can only be owner or the admin of the contract, Otter Society developer team.
1. Owner of the contract will mint `TEAM_MINT_AMOUNT` to their address for once.

### Withdraw

- Caller can be only owner or admin account.
1. On each withdraw, %75 goes to Otter Society developer team, this includes roadmap and crew salaries.
2. On each withdraw, %25 goes to DAO wallet, $AVAX in this wallet will NOT be used by the developers of Otter Society, DAO will decide what happens with this wallet.
