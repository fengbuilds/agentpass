// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal interface of the SPACE ID Agent ID registry (ERC-721, soulbound).
///         Per Binance Agentic Wallet dev docs: balanceOf(address) > 0 means the
///         address holds an Agent ID (name.ai).
interface IAgentIdRegistry {
    function balanceOf(address owner) external view returns (uint256);
}

/// @title AgentPass Check-In
/// @notice A daily check-in dApp gated by Binance Agent ID.
///         Only wallets holding an Agent ID (.ai) can check in. The first
///         check-in mints a soulbound badge NFT; daily check-ins build a
///         streak recorded on-chain, bound to the holder's wallet identity.
/// @dev    The contract has no owner and no admin functions: nobody can pause
///         it, change the gate, or move user assets. It never takes custody
///         of any funds (checkIn is non-payable).
contract AgentPassCheckIn {
    string public constant name = "AgentPass Badge";
    string public constant symbol = "APASS";

    IAgentIdRegistry public immutable agentIdRegistry;

    // ---- badge (soulbound ERC-721, mint-only) ----
    uint256 public badgeSupply;
    mapping(uint256 => address) private _badgeOwner;
    mapping(address => uint256) private _badgeOf;
    mapping(address => uint256) private _badgeBalance;

    // ---- check-in state ----
    mapping(address => uint256) public lastCheckInDay; // UTC day index
    mapping(address => uint256) public streakOf;
    mapping(address => uint256) public totalCheckInsOf;
    uint256 public uniqueAgents;
    uint256 public totalCheckIns;

    event CheckedIn(address indexed agent, uint256 day, uint256 streak, uint256 totalCheckIns);
    event BadgeMinted(address indexed agent, uint256 indexed tokenId);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor(address registry) {
        require(registry != address(0), "zero registry");
        agentIdRegistry = IAgentIdRegistry(registry);
    }

    /// @notice True if the address holds an Agent ID.
    function isAgent(address who) public view returns (bool) {
        return agentIdRegistry.balanceOf(who) > 0;
    }

    /// @notice Current UTC day index used by the check-in calendar.
    function today() public view returns (uint256) {
        return block.timestamp / 1 days;
    }

    /// @notice Whether the address can check in right now (holds Agent ID and
    ///         has not checked in today).
    function canCheckIn(address who) public view returns (bool) {
        return isAgent(who) && lastCheckInDay[who] < today();
    }

    /// @notice Check in for today. Agent ID holders only, once per UTC day.
    ///         First check-in also mints the soulbound AgentPass badge.
    function checkIn() external {
        require(isAgent(msg.sender), "Agent ID required");
        uint256 day = today();
        require(lastCheckInDay[msg.sender] < day, "already checked in today");

        if (lastCheckInDay[msg.sender] == day - 1) {
            streakOf[msg.sender] += 1;
        } else {
            streakOf[msg.sender] = 1;
        }
        lastCheckInDay[msg.sender] = day;
        totalCheckInsOf[msg.sender] += 1;
        totalCheckIns += 1;

        if (_badgeOf[msg.sender] == 0) {
            uniqueAgents += 1;
            uint256 tokenId = ++badgeSupply;
            _badgeOf[msg.sender] = tokenId;
            _badgeOwner[tokenId] = msg.sender;
            _badgeBalance[msg.sender] = 1;
            emit Transfer(address(0), msg.sender, tokenId);
            emit BadgeMinted(msg.sender, tokenId);
        }

        emit CheckedIn(msg.sender, day, streakOf[msg.sender], totalCheckInsOf[msg.sender]);
    }

    // ---- minimal soulbound ERC-721 surface ----

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "zero address");
        return _badgeBalance[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _badgeOwner[tokenId];
        require(owner != address(0), "nonexistent token");
        return owner;
    }

    /// @notice Badge token id held by an address (0 = none).
    function badgeOf(address who) external view returns (uint256) {
        return _badgeOf[who];
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        address owner = ownerOf(tokenId);
        return string(abi.encodePacked(
            'data:application/json;utf8,{"name":"AgentPass Badge #',
            _toString(tokenId),
            '","description":"Soulbound badge for Agent ID holders who checked in to AgentPass. Identity gate: Binance Agent ID (.ai).","attributes":[{"trait_type":"Holder","value":"',
            _toHexAddress(owner),
            '"},{"trait_type":"Soulbound","value":"true"}]}'
        ));
    }

    // Soulbound: all transfers and approvals are disabled.
    function transferFrom(address, address, uint256) external pure {
        revert("soulbound");
    }
    function safeTransferFrom(address, address, uint256) external pure {
        revert("soulbound");
    }
    function safeTransferFrom(address, address, uint256, bytes calldata) external pure {
        revert("soulbound");
    }
    function approve(address, uint256) external pure {
        revert("soulbound");
    }
    function setApprovalForAll(address, bool) external pure {
        revert("soulbound");
    }
    function getApproved(uint256) external pure returns (address) {
        return address(0);
    }
    function isApprovedForAll(address, address) external pure returns (bool) {
        return false;
    }
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165
            || interfaceId == 0x80ac58cd // ERC721
            || interfaceId == 0x5b5e139f; // ERC721Metadata
    }

    // ---- helpers ----

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) { digits++; temp /= 10; }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _toHexAddress(address a) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(bytes20(a)[i] >> 4)];
            str[3 + i * 2] = alphabet[uint8(bytes20(a)[i] & 0x0f)];
        }
        return string(str);
    }
}
