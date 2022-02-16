pragma ton-solidity >= 0.47.0;

import "./PBStructs.sol";

interface IGameHost {
    function onGameCompleted(GameInfo gameInfo) external;
    function deployGame(uint24[] _renderSettings) external responsible returns (address);
    function activateGame(address gameAddress) external;
}
