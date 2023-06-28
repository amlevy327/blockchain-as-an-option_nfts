// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Sword is
    ERC721Enumerable,
    AccessControl
{
  // Incremental counter for token id for minted nfts
  using Counters for Counters.Counter;
  Counters.Counter private _tokenId;

  // Authorized role to mint nfts.
  // For example, a back end wallet controlled by the game studio that only calls the mint function for approved mint requests by the player.
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");

  // Token uri management for metadata.
  // This implementation allows each token uri to be different (not use same base uri) for decentralized storage such as ipfs.
  mapping(uint256 => string) private _tokenUris;

  // Blockchain and database sync management. Allows tracking between nft token id and database uuid.
  mapping(string => uint256) private _swordIdToTokenId;
  mapping(uint256 => string) private _tokenIdToSwordId;

  constructor(string memory name_, string memory symbol_, address manager_) ERC721(name_, symbol_) {
    // Setup acccess control roles.
    // This implementation allows for separate admin and manager role for security.
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MANAGER_ROLE, manager_);

    // Increment token id to start at token id 1.
    // Prevents potential issues using token id 0
    _tokenId.increment();
  }

  /**
  ////////////////////////////////////////////////////
  // Public functions
  ///////////////////////////////////////////////////
  */

  // mint sword into nft
  function mintSword(
    address player_,
    string memory swordId_,
    string memory swordUri_
  ) public onlyRole(MANAGER_ROLE) {
    require(_swordIdToTokenId[swordId_] == 0, "SWORD_ALREADY_MINTED");

    // Get current token id and mint nft
    uint256 tokenId = _tokenId.current();
    _mint(player_, tokenId);

    // Set token metadata uri
    _setTokenUri(tokenId, swordUri_);

    // Set blockchain and database sync values
    _swordIdToTokenId[swordId_] = tokenId;
    _tokenIdToSwordId[tokenId] = swordId_;

    // Increment token id for next mint
    _tokenId.increment();
  }

  /**
  ////////////////////////////////////////////////////
  // View only functions
  ///////////////////////////////////////////////////
  */

  // Get token metadata uri
  // Uses OpenSea metadata standard function name.
  function tokenURI(uint256 tokenId_)
    public
    view
    virtual
    override
    returns (string memory)
  {
      _requireMinted(tokenId_);
      return _tokenUris[tokenId_];
  }

  // Get token id from sword id
  function swordIdToTokenId(string memory swordId_)
    external
    view
    returns (uint256)
  {
    return _swordIdToTokenId[swordId_];
  }

  // get sword id from token id
  function tokenIdToSwordId(uint256 tokenId_)
    external
    view
    returns (string memory)
  {
    return _tokenIdToSwordId[tokenId_];
  }

  /**
  ////////////////////////////////////////////////////
  // Internal functions
  ///////////////////////////////////////////////////
  */

  // Set token metadata uri
  function _setTokenUri(uint256 tokenId_, string memory tokenUri_)
    internal
    virtual
  {
    require(_exists(tokenId_), "TOKEN_DOESNT_EXIST");
    _tokenUris[tokenId_] = tokenUri_;
  }

  /**
  ////////////////////////////////////////////////////
  // Override functions
  ///////////////////////////////////////////////////
  */

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}