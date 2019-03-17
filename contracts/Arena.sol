pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC20.sol";
import "./Farm.sol";

contract Arena {
    
    using SafeMath for uint256;

    event NewFighter(address indexed owner, uint indexed tokenId);
    event NewFight(uint indexed tokenId, uint indexed reward);
    
    mapping (uint => bool) private _fighters;
    mapping (uint => Fighter) private _fighterById;

    ERC721 private _cryptoFarming;
    ERC20 private _farmCoin;
    Farm private _farm;

    struct Fighter {
        address owner;
        uint wins;
        uint defeats;
        uint reward;
        bool canFight;
    }

    constructor(Farm farm, ERC721 cryptoFarming, ERC20 farmCoin) public {
        _farm = farm;
        _cryptoFarming = cryptoFarming;
        _farmCoin = farmCoin;
    }

    modifier onlyBreeder() {
        require(_farm.isBreeder(msg.sender), "not breeder");
        _;
    }

    modifier onlyOwnerOf(uint id) {
        require(msg.sender == _farm.getOwnerOfAnimal(id), "not animal owner");
        _;
    }

    modifier onlyFighter(uint id) {
        require(_fighters[id], "not a fighter");
        _;
    }

    function registerFighter(uint id) public onlyBreeder() onlyOwnerOf(id) returns (bool) {
        require(!_fighters[id], "already a fighter");
        _fighters[id] = true;
        _fighterById[id] = Fighter(msg.sender, 0, 0, 0, false);
        emit NewFighter(msg.sender, id);
        return true;
    }

    function proposeToFight(uint id, uint reward) public onlyBreeder() onlyOwnerOf(id) onlyFighter(id) returns (bool) {
        _fighterById[id].reward = reward;
        _fighterById[id].canFight = true;
        emit NewFight(id, reward);
        return true;
    }

    function agreeToFight(uint challenger, uint foe, uint value) public 
    onlyBreeder() onlyOwnerOf(challenger) onlyFighter(challenger) onlyFighter(foe)
    returns (bool) {
        require(value == _fighterById[foe].reward, "not right amount");
        require(_fighterById[foe].canFight, "not available");
        Fighter storage fighter = _fighterById[foe];
        if (foe.mod(2) == 0) {
            _fighterById[foe].wins.add(1);
            _fighterById[challenger].defeats.add(1);
            _farmCoin.transferFrom(msg.sender, fighter.owner, value);
        } else {
            _fighterById[challenger].wins.add(1);
            _fighterById[foe].defeats.add(1);
            _farmCoin.transferFrom(fighter.owner, msg.sender, value);
        }
        return true;
    }

}