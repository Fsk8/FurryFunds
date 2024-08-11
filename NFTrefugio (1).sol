// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract NFTrefugio is ERC721, Ownable {
    string private baseTokenURI;


    constructor(string memory _initialBaseURI)
        ERC721("NFTrefugio", "RFUG")
        Ownable(msg.sender)
    {
        baseTokenURI = _initialBaseURI;
    }


       function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require (ownerOf(_tokenId) != address(0), "ERC721Metadata: URI query for nonexistent token");
       
        return string(abi.encodePacked(baseTokenURI, "/", Strings.toString(_tokenId), ".json"));
    }


    function safeMintRefugio(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }


    function setBaseURI(string memory _changeURI) external onlyOwner {
        baseTokenURI = _changeURI;
    }


    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}
