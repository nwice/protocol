// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-staking-rewards-base.sol";

abstract contract StrategyZeroFarmBase is StrategyStakingRewardsBase {
    // Token addresses
    address public zero = 0x008E26068B3EB40B443d3Ea88c1fF99B789c10F7;

    // WAVAX/<token1> pair
    address public token1;

    // How much ZERO tokens to keep?
    uint256 public keepZERO = 0;
    uint256 public constant keepZEROMax = 10000;

    constructor(
        address _token1,
        address _rewards,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStakingRewardsBase(
            _rewards,
            _lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        token1 = _token1;
    }

    // **** Setters ****

    function setKeepZERO(uint256 _keepZERO) external {
        require(msg.sender == timelock, "!timelock");
        keepZERO = _keepZERO;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects ZERO tokens
        IStakingRewards(rewards).getReward();
        uint256 _zero = IERC20(zero).balanceOf(address(this));
        if (_zero > 0) {
            // 10% is locked up for future gov
            uint256 _keepZERO = _zero.mul(keepZERO).div(keepZEROMax);
            IERC20(zero).safeTransfer(
                IController(controller).treasury(),
                _keepZERO
            );
            
           //If the Token is Zero then only sell half 
            if (token1 == zero) {
                _swapZero(zero, wavax, _zero.sub(_keepZERO).div(2));
            } else {            
             _swapZero(zero, wavax, _zero.sub(_keepZERO));
            }
             
        }

        // Swap half WAVAX for token if the token isn't Zero
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0 && token1 != zero) {
            _swapZero(wavax, token1, _wavax.div(2));
        }

        // Adds in liquidity for WAVAX/token
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_wavax > 0 && _token1 > 0) {
            IERC20(wavax).safeApprove(zeroRouter, 0);
            IERC20(wavax).safeApprove(zeroRouter, _wavax);

            IERC20(token1).safeApprove(zeroRouter, 0);
            IERC20(token1).safeApprove(zeroRouter, _token1);

            IZeroRouter(zeroRouter).addLiquidity(
                wavax,
                token1,
                _wavax,
                _token1,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(wavax).transfer(
                IController(controller).treasury(),
                IERC20(wavax).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        // We want to get back ZERO LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
