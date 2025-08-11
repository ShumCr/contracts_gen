// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public value;
    event ValueChanged(uint256 indexed newValue, address indexed changedBy);

    function set(uint256 _value) external {
        value = _value;
        emit ValueChanged(_value, msg.sender);
    }
}
