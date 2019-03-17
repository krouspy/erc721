pragma solidity ^0.4.24;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC20.sol";

contract Farm is Ownable {
    using SafeMath for uint256;

    event BreederAdded(address indexed breeder);
    event BreederRemoved(address indexed exBreeder);
    event AnimalCreated(address indexed owner, uint tokenId);
    event AnimalDeleted(address indexed owner, uint tokenId);
    event AnimalTransfered(address indexed from, address indexed to, uint tokenId);
    event NewBorn(address indexed owner, uint tokenId);
    event AuctionCreated(address indexed seller, uint tokenId);
    event AuctionClaimed(address indexed claimer, uint tokenId);
    event NewBid(address indexed bidder, uint tokenId, uint price);

    enum AnimalType { Cow, Horse, Chicken, Pig, Sheep, Donkey, Rabbit, Duck }
    enum Age { Young, Adult, Old }
    enum Color { Brown, Black, White, Red, Blue }

    mapping (address => bool) private _breeders;
    mapping (uint => address) private _animalToOwner;
    mapping (address => Animal[]) private _animalsOfOwner;
    mapping (uint => Animal) private _animalsById;
    mapping (uint => Auction) private _auctions;
    mapping (uint => bool) private _auctionedAnimals;

    uint private _currentId;

    ERC721 private _cryptoFarming;
    ERC20 private _farmCoin;

    struct Animal {
        uint id;
        AnimalType race;
        Age age;
        Color color;
        uint rarity;
        bool isMale;
        bool canBreed;
        bool isVaccinated;
    }

    struct Auction {
        address seller;
        address lastBidder;
        uint startDate;
        uint initialPrice;
        uint priceToBid;
        uint bestOffer;
    }

    constructor(ERC721 cryptoFarming, ERC20 farmCoin) public {
        _cryptoFarming = cryptoFarming;
        _farmCoin = farmCoin;
    }

    function registerBreeder(address _address) public onlyOwner() {
        require(!_breeders[_address], "already a breeder");
        _breeders[_address] = true;
        emit BreederAdded(_address);
    }

    function removeBreeders(address _address) public onlyOwner() {
        require(isBreeder(_address), "not breeder");
        _breeders[_address] = false;
        emit BreederRemoved(_address);
    }

    function isBreeder(address _address) public view returns (bool) {
        return _breeders[_address];
    }

    function getOwnerOfAnimal(uint id) public view returns (address) {
        require(_animalToOwner[id] != address(0), "not animal");
        return _animalToOwner[id];
    }

    function getAuctioned(uint id) public view returns (address seller, address lastBidder, uint startDate, uint priceToBid, uint bestOffer) {
        require(_auctionedAnimals[id], "not auctioned");
        Auction memory auction = _auctions[id];
        return (auction.seller, auction.lastBidder, auction.startDate, auction.priceToBid, auction.bestOffer);
    }

    function isAuctioned(uint id) public view returns (bool) {
        return _auctionedAnimals[id];
    }

    modifier onlyBreeder() {
        require(_breeders[msg.sender], "not a breeder");
        _;
    }

    modifier onlyOwnerOfAnimal(uint id) {
        require(msg.sender == _animalToOwner[id], "Not animal owner");
        _;
    }

    modifier onlyAuctionedAnimal(uint id) {
        require(_auctionedAnimals[id], "not auctioned animal");
        _;
    }

    function declareAnimal(address to, AnimalType race, Age age, Color color, uint rarity, bool isMale, bool canBreed, bool isVaccinated)
        public onlyBreeder() returns (bool) {
        _currentId++;
        Animal memory animal = Animal(_currentId, race, age, color, rarity, isMale, canBreed, isVaccinated);
        _animalsOfOwner[msg.sender].push(animal);
        _animalsById[_currentId] = animal;
        _animalToOwner[_currentId] = to;
        _cryptoFarming.mintToken(to, _currentId);
        return true;
    }

    function macgyver(uint rarity, bool isMale, bool canBreed, bool isVaccinated) public {
        AnimalType race = AnimalType.Horse;
        Age age = Age.Young;
        Color color = Color.Black;
        declareAnimal(msg.sender, race, age, color, rarity, isMale, canBreed, isVaccinated);
    }

    function deadAnimal(uint id) public onlyOwnerOfAnimal(id) {
        _cryptoFarming.burnToken(msg.sender, id);
        _removeFromAnimalsOfOwner(msg.sender, id);
        delete _animalsById[id];
        delete _animalToOwner[id];
        emit AnimalDeleted(msg.sender, id);
    }

    function _removeFromAnimalsOfOwner(address owner, uint id) private {
        uint size = _animalsOfOwner[owner].length;
        for (uint index = 0; index < size; index++) {
            Animal storage animal = _animalsOfOwner[owner][index];
            if (animal.id == id) {
                if (index < size - 1) {
                    _animalsOfOwner[owner][index] = _animalsOfOwner[owner][size - 1];
                }
                delete _animalsOfOwner[owner][size - 1];
            }
        }
    }

    // Auctioned Animal are locked
    function _transferAnimal(address sender, address receiver, uint id) private onlyBreeder() onlyOwnerOfAnimal(id) {
        require(isBreeder(receiver), "not a breeder");
        require(_animalsById[id].id != 0, "not animal");
        require(!_auctionedAnimals[id], "auctioned animal");
        _cryptoFarming.transferFrom(sender, receiver, id);
        _removeFromAnimalsOfOwner(sender, id);
        _animalsOfOwner[receiver].push(_animalsById[id]);
        _animalToOwner[id] = receiver;
        emit AnimalTransfered(sender, receiver, id);
    }

    function breedAnimals(uint senderId, uint targetId) public onlyBreeder() onlyOwnerOfAnimal(senderId) returns (bool) {
        _preProcessBreeding(senderId, targetId);
        _processBreeding(msg.sender, senderId, targetId);
        emit NewBorn(msg.sender, _currentId);
        return true;
    }

    // Initially if a token is approved to a specific address means that this address can trade our token
    // We use this functionality to tell if a specific breeder can use our token in order to breed animals
    function _preProcessBreeding(uint senderId, uint targetId) private view {
        require(_cryptoFarming.getApproved(targetId) == _animalToOwner[senderId], "target animal not approved");
        require(_sameRace(senderId, targetId), "not same race");
        require(_canBreed(senderId, targetId), "can't breed");
        require(_breedMaleAndFemale(senderId, targetId), "can't breed");
    }

    function _sameRace(uint id1, uint id2) private view returns (bool) {
        return (_animalsById[id1].race == _animalsById[id2].race);
    }

    function _canBreed(uint id1, uint id2) private view returns (bool) {
        return (_animalsById[id1].canBreed && _animalsById[id2].canBreed);
    }

    function _breedMaleAndFemale(uint id1, uint id2) private view returns (bool) {
        if ((_animalsById[id1].isMale) && (!_animalsById[id2].isMale)) return true;
        if ((!_animalsById[id1].isMale) && (_animalsById[id2].isMale)) return true;
        return false;
    }

    function _processBreeding(address to, uint senderId, uint targetId) private {
        AnimalType race = _animalsById[senderId].race;
        Age age = Age.Young;
        Color color = _animalsById[senderId].color;
        uint rarity = _animalsById[senderId].rarity.add(_animalsById[targetId].rarity);
        bool isMale = _animalsById[targetId].isMale;
        bool canBreed = false;
        bool isVaccinated = _animalsById[senderId].isVaccinated;
        declareAnimal(to, race, age, color, rarity, isMale, canBreed, isVaccinated);
    }

    function createAuction(uint id, uint initialPrice) public onlyBreeder() onlyOwnerOfAnimal(id) {
        require(!_auctionedAnimals[id], "already auctioned");
        _auctionedAnimals[id] = true;
        uint priceToBid = initialPrice.mul(_animalsById[id].rarity);
        _auctions[id] = Auction(msg.sender, address(0), now, initialPrice, priceToBid, 0);
        emit AuctionCreated(msg.sender, id);
    }

    function bidOnAuction(uint id, uint value) public onlyBreeder() {
        require(msg.sender != _auctions[id].seller, "You bid on your own auction");
        require(_auctionedAnimals[id], "not an auctioned animal");
        require(value == _auctions[id].priceToBid, "not right price");
        _transferTokenBid(msg.sender, id, value);
        _updateAuction(msg.sender, id, value);
        emit NewBid(msg.sender, id, value);
    }

    function _transferTokenBid(address newBidder, uint id, uint value) private {
        Auction memory auction = _auctions[id];
        if (auction.lastBidder != address(0)) {
            _farmCoin.transferFrom(auction.seller, auction.lastBidder, auction.bestOffer);
        } 
        _farmCoin.transferFrom(newBidder, auction.seller, value);    
    } 

    function _updateAuction(address newBidder, uint id, uint value) private {
        _auctions[id].lastBidder = newBidder;
        _auctions[id].priceToBid = _calculatepriceToBid(id);
        _auctions[id].bestOffer = value;
    }

    function _calculatepriceToBid(uint id) private view returns (uint) {
        return _auctions[id].priceToBid.mul(_animalsById[id].rarity);
    }

    function claimAuction(uint id) public onlyBreeder() onlyAuctionedAnimal(id) {
        require(_auctions[id].lastBidder == msg.sender, "you are not the last bidder");
        require(_auctions[id].startDate + 2 days <= now, "2 days have not yet passed");
        _processRetrieveAuction(id);
        emit AuctionClaimed(msg.sender, id);
    }
          
    function _processRetrieveAuction(uint id) private {
        Auction storage auction = _auctions[id];
        if (auction.lastBidder != address(0)) {
            _transferAnimal(auction.seller, auction.lastBidder, id);
            _auctionedAnimals[id] = false;
            delete _auctions[id];
        }
    }
}