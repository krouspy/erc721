pragma solidity ^0.4.24;

import "./Farm.sol";

contract Arena {

    event NewFighter(address indexed owner, uint tokenId);
    
    mapping (uint => bool) private _fighters;
    mapping (uint => Fighter) private _fighterById;

    Farm private _farm;

    struct Fighter {
        uint wins;
        uint defeats;
        uint reward;
    }

    constructor(Farm farm) public {
        _farm = farm;
    }

    modifier isFighter(uint id) {
        require(_fighters[id], "not a fighter");
        _;
    }

    function registerFighter(uint id) public returns (bool) {
        _preRegisterFighter(msg.sender, id);
        _fighters[id] = true;
        _fighterById[id] = Fighter(0, 0, 0);
        emit NewFighter(msg.sender, id);
        return true;
    }

    function _preRegisterFighter(address owner, uint id) private view {
        require(_farm.isBreeder(owner), "not breeder");
        require(owner == _farm.getOwnerOfAnimal(id), "not animal owner");
        require(!_fighters[id], "already a fighter");
    }

    

}