// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./NFTrefugio.sol";
import "./NFTdonante.sol";

contract RefugioAnimalFINAL {
    address private owner;
    NFTrefugio public nftRefugio;
    NFTdonante public nftDonante;
    uint private contadorRefugios;
    uint private contadorDonantes;

    struct Refugios {
        uint id;
        string nombre;
        uint8 edadRefugioAnios;
        uint256 cantidadMascotas;
        address payable direccion;
        uint256 totalDonations;
    }

    struct Donation {
        address donor;
        uint256 amount;
    }

    mapping(uint => Refugios) private refugioAnimal;
    mapping(uint => Donation[]) private refugioDonations;
    mapping(address => Donation[]) private donorHistory;

    event NuevoRefugioRegistrado(uint id, string nombre, uint8 edadRefugioAnios, uint256 cantidadMascotas, address direccion);
    event DonationReceived(uint refugioId, address donor, uint256 amount);

    constructor(address _nftRefugioAddress, address _nftDonanteAddress) {
        owner = msg.sender;
        nftRefugio = NFTrefugio(_nftRefugioAddress);
        nftDonante = NFTdonante(_nftDonanteAddress);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "only owner");
        _;
    }

    function registrarRefugio(string memory _nombre, uint8 _edadRefugioAnios, uint256 _cantidadMascotas) external {
        contadorRefugios++;
        address payable _direccion = payable(msg.sender);

        refugioAnimal[contadorRefugios] = Refugios({
            id: contadorRefugios,
            nombre: _nombre,
            edadRefugioAnios: _edadRefugioAnios,
            cantidadMascotas: _cantidadMascotas,
            direccion: _direccion,
            totalDonations: 0
        });

        // Mint NFT for the new refugio
        nftRefugio.safeMintRefugio(_direccion, contadorRefugios);

        emit NuevoRefugioRegistrado(contadorRefugios, _nombre, _edadRefugioAnios, _cantidadMascotas, _direccion);
    }

    function obtenerRefugio(uint _id) public view returns (uint, string memory, uint8, uint256, address, uint256) {
        Refugios memory refugio = refugioAnimal[_id];
        return (refugio.id, refugio.nombre, refugio.edadRefugioAnios, refugio.cantidadMascotas, refugio.direccion, refugio.totalDonations);
    }

    function obtenerTodosRefugios() public view returns (Refugios[] memory) {
        Refugios[] memory refugios = new Refugios[](contadorRefugios);
        for (uint i = 1; i <= contadorRefugios; i++) {
            refugios[i - 1] = refugioAnimal[i];
        }
        return refugios;
    }

    function updateRefugio(uint _id, string memory _nombre, uint8 _edadRefugioAnios, uint256 _cantidadMascotas) public onlyOwner {
        Refugios storage refugio = refugioAnimal[_id];
        refugio.nombre = _nombre;
        refugio.edadRefugioAnios = _edadRefugioAnios;
        refugio.cantidadMascotas = _cantidadMascotas;
    }

    // State variable to track accumulated fees
uint256 public accumulatedFees;

function donateFood(uint _id) payable public {
    require(_id <= contadorRefugios && _id > 0, "Invalid ID");
    require(msg.value > 0, "Amount must be greater than zero");

    // Caching the storage pointer to memory
    Refugios storage refugio = refugioAnimal[_id];

    uint256 totalDonation = msg.value;
    uint256 fee = totalDonation / 5; // 20% fee (Division might be cheaper than multiplication and then division)
    uint256 amountToRefugio = totalDonation - fee;

    // Accumulate the fee instead of transferring it
    accumulatedFees += fee;

    // Transfer to refugio
    (bool sentToRefugio, ) = refugio.direccion.call{value: amountToRefugio}("");
    require(sentToRefugio, "Failed to send Ether to refugio");

    // Update refugio's total donations
    refugio.totalDonations += amountToRefugio;

    // Record the donation
    Donation memory newDonation = Donation({
        donor: msg.sender,
        amount: totalDonation
    });
    refugioDonations[_id].push(newDonation);
    donorHistory[msg.sender].push(newDonation);

    // Mint NFT for the donor
    contadorDonantes++;
    nftDonante.safeMintDonante(msg.sender, contadorDonantes);

    emit DonationReceived(_id, msg.sender, totalDonation);
}



    function getRefugioDonations(uint _id) public view returns (Donation[] memory) {
        return refugioDonations[_id];
    }

    function getDonorHistory(address _donor) public view returns (Donation[] memory) {
        return donorHistory[_donor];
    }

    function borrarRefugio(uint _id) public onlyOwner {
        delete refugioAnimal[_id];
        delete refugioDonations[_id];
    }

    // Function to check the contract's balance
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Function to withdraw funds from the contract
    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Insufficient contract balance");
        (bool success, ) = payable(owner).call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }
}
