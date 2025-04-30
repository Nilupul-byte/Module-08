// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import OpenZeppelin Libraries
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract SiriAdvanced is ERC721, Ownable, Multicall {
    using BitMaps for BitMaps.BitMap;

    // --- Sale State Machine ---
    enum SaleState {
        CLOSED,
        PRESALE,
        PUBLIC,
        SOLD_OUT
    }

    SaleState public saleState;

    // --- Merkle Airdrop ---
    bytes32 public merkleRoot;
    BitMaps.BitMap private claimedBitmap;

    // Mapping way for comparison
    mapping(address => bool) public hasMintedMapping;

    // --- Commit Reveal Randomness ---
    struct Commitment {
        uint256 blockNumber;
        bytes32 commitHash;
    }

    mapping(address => Commitment) public commitments;
    uint256 public totalSupply;
    uint256 public maxSupply;

    // --- Pull Payment Withdrawal ---
    mapping(address => uint256) public pendingWithdrawals;

    // --- Constructor ---
    constructor(uint256 _maxSupply, bytes32 _merkleRoot) ERC721("SiriAdvanced", "SIRI") Ownable(msg.sender) {
        maxSupply = _maxSupply;
        merkleRoot = _merkleRoot;
        saleState = SaleState.CLOSED;
    }

    // --- Merkle Mint ---
    function merkleMint(uint256 index, bytes32[] calldata _proof) external {
        require(saleState == SaleState.PRESALE, "Presale not active");
        require(totalSupply < maxSupply, "Sold out");

        // Calculate leaf
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
       

        // Verify Merkle Proof
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof");

        // Check bitmap or mapping
        require(!claimedBitmap.get(index), "Already claimed");

        // Mark as claimed in bitmap
        claimedBitmap.set(index);

        // Track with mapping also (for gas comparison)
        require(!hasMintedMapping[msg.sender], "Already minted");
        hasMintedMapping[msg.sender] = true;

        // Commit Phase (commit a random secret)
        // You should call `commit` separately (see below)

        // Minting part
        _safeMint(msg.sender, totalSupply);
        totalSupply++;

        if (totalSupply >= maxSupply) {
            saleState = SaleState.SOLD_OUT;
        }
    }

    //PublicSale -- Public Mint
    function publicMint() external {
    require(saleState == SaleState.PUBLIC, "Public sale not active");
    require(totalSupply < maxSupply, "Sold out");

    _safeMint(msg.sender, totalSupply);
    totalSupply++;

    if (totalSupply >= maxSupply) {
        saleState = SaleState.SOLD_OUT;
    }
    }


    // --- Commit Reveal Randomness ---
    function commit(bytes32 commitHash) external {
        commitments[msg.sender] = Commitment(block.number, commitHash);
    }

    function reveal(uint256 secret, string calldata salt) external {
        Commitment memory userCommit = commitments[msg.sender];
        require(userCommit.blockNumber > 0, "No commitment found");
        require(block.number > userCommit.blockNumber + 10, "Reveal not ready yet");

        // Verify commit matches
        bytes32 expectedCommitHash = keccak256(abi.encodePacked(secret, salt));
        require(userCommit.commitHash == expectedCommitHash, "Commitment mismatch");

        // Generate Random NFT ID
        uint256 randomNFTId = uint256(keccak256(abi.encodePacked(secret, blockhash(userCommit.blockNumber + 10)))) % maxSupply;

        // Minting Random NFT
        _safeMint(msg.sender, randomNFTId);

        delete commitments[msg.sender];
    }

    // --- Admin functions ---
    function setSaleState(SaleState _state) external onlyOwner {
        saleState = _state;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    // --- Pull Payments ---
    function withdraw() external {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function depositShares(address[] calldata contributors, uint256[] calldata amounts) external payable onlyOwner {
        require(contributors.length == amounts.length, "Length mismatch");

        uint256 total;
        for (uint i = 0; i < amounts.length; i++) {
            total += amounts[i];
            pendingWithdrawals[contributors[i]] += amounts[i];
        }

        require(total <= msg.value, "Insufficient deposit");
    }

    // --- Multicall (already inherited) ---

    // Note: Inherited from OpenZeppelin's Multicall.sol
    // It lets you batch multiple calls in a single transaction!
}
