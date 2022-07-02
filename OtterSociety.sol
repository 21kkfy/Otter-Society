// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
// Azuki-labs ERC721A
import "./ERC721A.sol";
// Open-Zeppelin Ownable - modified under the MIT license.
import "./OwnableNR.sol";
// Open-Zeppelin Reentrancy Guard
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// ERC2981 NFT Royalty Standard
import "@openzeppelin/contracts/token/common/ERC2981.sol";
// Open-Zeppelin Strings Library
import "@openzeppelin/contracts/utils/Strings.sol";

/*


 _____ _   _              _____            _      _         
|  _  | | | |            /  ___|          (_)    | |        
| | | | |_| |_ ___ _ __  \ `--.  ___   ___ _  ___| |_ _   _ 
| | | | __| __/ _ \ '__|  `--. \/ _ \ / __| |/ _ \ __| | | |
\ \_/ / |_| ||  __/ |    /\__/ / (_) | (__| |  __/ |_| |_| |
 \___/ \__|\__\___|_|    \____/ \___/ \___|_|\___|\__|\__, |
                                                       __/ |
                                                      |___/ 

 */
/// @title Otter Society ERC721A, Royalty NFT contract.
/// @author Otter Society | Robbo
/// @notice This contract provides a team mint, a whitelist mint and a public mint.
/// Note before sold-out the royalty fee will be 10%
/// And after sold-out the royalty fee will be 5%

contract OtterSociety is ERC721A, OwnableNR, ReentrancyGuard, ERC2981 {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 3456;
    uint256 public constant TEAM_MINT_AMOUNT = 50;
    /// @dev MAX_SUPPLY_WHITELIST must be declared AFTER TEAM_MINT_AMOUNT to avoid
    /// it being summed up as non-assigned (0).
    uint256 public constant MAX_SUPPLY_WHITELIST = 1000 + TEAM_MINT_AMOUNT;
    uint256 public constant MAX_WHITELIST_MINT = 5;
    uint256 public constant WHITELIST_SALE_PRICE = 0.5 ether;
    uint256 public constant MAX_PUBLIC_MINT = 10;
    uint256 public constant PUBLIC_SALE_PRICE = 0.6 ether;
    uint256 public constant MAX_WHITELIST_WALLETS = 300;
    uint96 public royaltyDividend = 1000;
    /// @notice totalWhitelistWallets variable keeps track of how many wallets have been registered to whitelist.
    uint256 public totalWhitelistWallets = 0;
    string private baseTokenUri;
    string public placeholderTokenUri;

    /***********************
     * OTTER WALLETS *
     ***********************/
    /// Developer wallet
    address payable robboWallet = payable(msg.sender);
    /// Admin wallet
    address payable reedWallet =
        payable(0x4AC2cf9b186b39EFb2eAe8AdC56dD4889333fe60);
    /// DAO wallet
    address payable marketDAOWallet =
        payable(0x4AC2cf9b186b39EFb2eAe8AdC56dD4889333fe60);
    /// These variables control the state of the contract.
    bool public isRevealed = false;
    bool public publicSale = false;
    bool public whiteListSale = false;
    bool public pause = true;
    bool public teamMinted = false;

    mapping(address => bool) whitelistedAddresses;
    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;

    /*************
     * MODIFIERS *
     *************/

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
    modifier isWhitelisted(address _address) {
        require(whitelistedAddresses[_address], "You need to be whitelisted");
        _;
    }
    /// @notice As an end-user, when the pause is set to 'false'
    /// you are allowed to access whitelist mint and public mint.
    modifier notPaused() {
        require(!pause, "Otter Society :: Contract is paused.");
        _;
    }

    constructor() ERC721A("Otter Society_1", "OS") {
        require(marketDAOWallet != address(0));
        transferAdmin(reedWallet);
        _setDefaultRoyalty(marketDAOWallet, uint96(royaltyDividend));
        createWhitelist();
    }

    /*********************
     * MINTING FUNCTIONS *
     *********************/

    /// @notice This is where the public minting process happens.
    /// @dev 1. This is the mint function available for the non-whitelisted(public) & whitelisted wallets.
    /// @dev 2. Require functions are important especially for this function.
    /// First of all, a modifier checks if the wallet address connecting to this function is a real user
    /// Secondly, There are multiple require functions inside the function that can be understood easily.
    /// @notice Note If you prefer to mint from snowtrace.io you must include the PUBLIC_SALE_PRICE as a parameter given.
    function mint(uint256 _quantity)
        external
        payable
        nonReentrant
        callerIsUser
        notPaused
    {
        require(publicSale, "Otter Society :: Not Yet Active.");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Otter Society :: Beyond Max Supply"
        );
        require(
            (totalPublicMint[msg.sender] + _quantity) <= MAX_PUBLIC_MINT,
            "Otter Society :: Minted maximum amount."
        );
        require(
            msg.value >= (PUBLIC_SALE_PRICE * _quantity),
            "Otter Society :: Not enough AVAX. "
        );
        /// Reveal Otter Society on sold-out.
        /// Reduce royalty fee to 5%
        if (totalSupply() == MAX_SUPPLY) {
            isRevealed = true;
            _setDefaultRoyalty(marketDAOWallet, uint96(royaltyDividend / 2));
        }
        totalPublicMint[msg.sender] += _quantity;

        _safeMint(msg.sender, _quantity);
    }

    /// @notice This is where the whitelist minting process happens.
    /// @dev 1. This is the mint function available for the whitelisted wallets.
    /// @dev 2. Require functions are important especially for this function.
    /// First of all, a modifier checks if the wallet address connecting to this function is a real user
    /// Secondly, There is also a modifier that checks to make sure the calling address is whitelisted.
    /// Lastly, There are multiple require functions inside the function that can be understood easily.
    /// @notice IMPORTANT If you prefer to mint from snowtrace.io you must include the WHITELIST_SALE_PRICE as a parameter given.
    function whitelistMint(uint256 _quantity)
        external
        payable
        nonReentrant
        callerIsUser
        notPaused
        isWhitelisted(msg.sender)
    {
        require(
            whiteListSale,
            "Otter Society :: White-list minting is on pause"
        );
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY_WHITELIST,
            "Otter Society :: Cannot mint beyond max supply"
        );
        require(
            (totalWhitelistMint[msg.sender] + _quantity) <= MAX_WHITELIST_MINT,
            "Otter Society :: Cannot mint beyond whitelist max mint!"
        );
        require(
            msg.value >= (WHITELIST_SALE_PRICE * _quantity),
            "Otter Society :: Payment is below the price"
        );
        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    /// @notice This function mints ONLY X amount of NFTs ONCE for the developer team.
    /// These NFTs will be used by the team for marketing campaign.
    /// param teamMinted is set to true, this means the owner can only call this contract once.

    function teamMint() external nonReentrant onlyOwnerAdmin {
        require(!teamMinted, "Otter Society :: Team already minted.");
        teamMinted = true;
        _safeMint(msg.sender, TEAM_MINT_AMOUNT);
    }

    /*****************
     * URI FUNCTIONS *
     *****************/

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    /// @notice This is the function contract uses to access the metadata, JSON files, for the created images.
    /// This contract uses the gas-saver approach of storing images and JSON files to the IPFS.
    /// The actual images are not stored on the blockchain platform, Avalanche, and stored on the IPFS.
    /// IPFS is a service that is used by most of the smart contracts to reduce the gas fee, it uses decentralized approach.
    /// @param tokenId, tokenId is the UID for an NFT's JSON file from this collection.
    /// @return String this function returns a URI address. Example: "ipfs://cid-for-json-directory/1.json"
    /// IMPORTANT: ipfs://cid-for-json-directory/ there must be a "/" to indicate it's a directory.
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256 trueId = tokenId + 1;

        if (!isRevealed) {
            return placeholderTokenUri;
        }
        //string memory baseURI = _baseURI();
        return
            bytes(baseTokenUri).length > 0
                ? string(
                    abi.encodePacked(baseTokenUri, trueId.toString(), ".json")
                )
                : "";
    }

    /// @notice setTokenUri & setPlaceHolderUri
    /// @dev This is used to set the IPFS URI that will be provided to the
    /// @param _baseTokenUri param is set to baseTokenUri, this is the uri file that contains the IPFS directory.
    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setPlaceHolderUri(string memory _placeholderTokenUri)
        external
        onlyOwner
    {
        placeholderTokenUri = _placeholderTokenUri;
    }

    /***********************
     * WHITELIST FUNCTIONS *
     ***********************/

    /// @notice This function is accessed by only the owner and it's used to add addresses to whitelist.
    /// Requires at least 2 AVAX or more.
    /// @dev CTRL+F -> "mapping(address => bool) whitelistedAddresses" : Every address has a boolean attribute.
    /// If an address has been verified for whitelist, it's set to true.
    /// @param _addressToWhitelist this is the address to be whitelisted.
    function addUser(address _addressToWhitelist) public onlyOwnerAdmin {
        /* Require whitelist address to have at least 0.5 AVAX of balance. */
        require(_addressToWhitelist.balance >= 0.5 ether);
        require(totalWhitelistWallets + 1 <= MAX_WHITELIST_WALLETS);
        totalWhitelistWallets++;
        whitelistedAddresses[_addressToWhitelist] = true;
    }

    /// @notice This function adds the whitelist addresses
    /// that were collected before mint.
    /// to the whitelist when the contract is deployed.
    function createWhitelist() internal {
        addUser(0x107f3496682CA5E9C7A08F1cbac1F54B6C963aD1);
        addUser(0x61D4D36a3684b7E3a06BA949EFa98493cde8A84C);
        addUser(0x19663EA2f36501a398e70Ce3A330E3EB401f40D3);
        addUser(0xE38c866a941AE5eC2FB89dCD4dce1b0Cc9475926);
        addUser(0x213D1809C3261967A2e7B20fE4fBf56050Dbc631);
        addUser(0x1C5a9Ca4ADc024B79bCFfb96c74Fc3263769FdCc);
        addUser(0xCE6E4F1dc56eE1bcB0546A021D884eCb4B22eC42);
        addUser(0x0955C6965Df31558C5D2a7A0F66631c16Dd42980);
        addUser(0x558e4048458A09FdFc86d2f102e1380936E9272f);
        addUser(0xac74a999fd71Bed40F59001D16b31eBb4DE3D85D);
        addUser(0x2111748AbB7622cE401DBe7BaAA4CA7E9eE46BfE);
    }

    function removeUser(address _addressToWhitelist) external onlyOwnerAdmin {
        whitelistedAddresses[_addressToWhitelist] = false;
    }

    /// @notice This function can be called by any wallet(user, contract)
    /// @param _whitelistedAddress this is where it's checked if the given address is verified or not.
    /// @return true if the address in question has been set "true" to the address.
    function verifyUser(address _whitelistedAddress)
        external
        view
        returns (bool)
    {
        bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
        return userIsWhitelisted;
    }

    /********************
     * TOGGLE FUNCTIONS *
     ********************/

    /// @notice togglePause, toggleWhiteListSale, togglePublicSale, toggleReveal
    /// functions are only accesses by the owner of this contract. Allows the owner wallet to access
    /// @dev Explain to a developer any extra details
    function togglePause() external onlyOwnerAdmin {
        pause = !pause;
    }

    function toggleWhiteListSale() external onlyOwnerAdmin {
        whiteListSale = !whiteListSale;
    }

    function togglePublicSale() external onlyOwnerAdmin {
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwnerAdmin {
        isRevealed = !isRevealed;
    }

    /*********************
     * ROYALTY FUNCTIONS *
     *********************/
    // 1. Before sold-out royalty 10%
    // 2. After sold-out royalty 5%
    // 3. Contract only allows royalty fee to be 10% up-most.
    // Note "feeDenominator" is a constant value: 10000
    // -> 500/10000 = %0.5

    /**
    @notice Sets the contract-wide royalty info.
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwnerAdmin
    {
        require(
            feeBasisPoints <= 2000,
            "OS-Royalty: Royalty fee can't exceed %20"
        );
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        //suppress error
        _tokenId;
        return (marketDAOWallet, (_salePrice * royaltyDividend) / 10000);
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721A)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /// @notice This function changes the address for DAO
    /// @param _newAddress for DAO payment receivements.
    function setMarketDAOWallet(address payable _newAddress)
        external
        onlyOwnerAdmin
    {
        require(
            _newAddress != address(0),
            "Otter Society: New receiver can't be 0."
        );
        marketDAOWallet = _newAddress;
    }

    /**********************
     * WITHDRAW FUNCTIONS *
     **********************/

    function withdraw() external payable onlyOwnerAdmin {
        uint256 fullBalance = address(this).balance;
        /// Market & development budget, can't go to address ZERO
        /// and/or an address that doesn't exists.
        require(marketDAOWallet != address(0));
        require(owner() != address(0));
        /* 75% goes to Otter Society Team */
        _withdraw(owner(), (fullBalance * 75) / 100);
        /* 25% goes to Marketing & DAO */
        _withdraw(marketDAOWallet, (fullBalance * 25) / 100);
    }

    /**
     * @notice This is an internal function called to withdraw AVAX.
     * @dev This is a private function called via withdraw.
     */
    function _withdraw(address wallet, uint256 amount) private {
        (bool success, ) = wallet.call{value: amount}("");
        require(success, "Otter Society: Transfer failed.");
    }
}
