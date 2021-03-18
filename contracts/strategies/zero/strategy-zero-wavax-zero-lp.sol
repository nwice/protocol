// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-zero-farm-base.sol";

contract StrategyZeroAvaxZeroLp is StrategyZeroFarmBase {
    // Token addresses
    address public zero_avax_zero_rewards = 0x60F19487bdA9c2F8336784110dc5c4d66425402d;
    address public zero_avax_zero_lp = 0x0751f9A49D921aA282257563C2041B9a0E00eB78;
   
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyZeroFarmBase(
            zero,
            zero_avax_zero_rewards,
            zero_avax_zero_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyZeroAvaxZeroLp";
    }
}
