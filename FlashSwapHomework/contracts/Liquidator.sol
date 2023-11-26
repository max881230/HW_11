// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Callee } from "v2-core/interfaces/IUniswapV2Callee.sol";
import { IUniswapV2Factory } from "v2-core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router01 } from "v2-periphery/interfaces/IUniswapV2Router01.sol";
import { IWETH } from "v2-periphery/interfaces/IWETH.sol";
import { IFakeLendingProtocol } from "./interfaces/IFakeLendingProtocol.sol";

// This is liquidator contract for testing,
// all you need to implement is flash swap from uniswap pool and call lending protocol liquidate function in uniswapV2Call
// lending protocol liquidate rule can be found in FakeLendingProtocol.sol
contract Liquidator is IUniswapV2Callee, Ownable {
    address internal immutable _FAKE_LENDING_PROTOCOL;
    address internal immutable _UNISWAP_ROUTER;
    address internal immutable _UNISWAP_FACTORY;
    address internal immutable _WETH9;
    uint256 internal constant _MINIMUM_PROFIT = 0.01 ether;
    address internal immutable _USDC;

    constructor(address lendingProtocol, address uniswapRouter, address uniswapFactory, address usdc) {
        _FAKE_LENDING_PROTOCOL = lendingProtocol;
        _UNISWAP_ROUTER = uniswapRouter;
        _UNISWAP_FACTORY = uniswapFactory;
        _WETH9 = IUniswapV2Router01(uniswapRouter).WETH();
        _USDC = usdc;
    }

    //
    // EXTERNAL NON-VIEW ONLY OWNER
    //

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Withdraw failed");
    }

    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(msg.sender, amount), "Withdraw failed");
    }

    //
    // EXTERNAL NON-VIEW
    //

    // cash flow
    // USDC: pool -> liquidator -> fakelendingprotocol
    // ETH: fakelendingprotocol -> liquidator => WETH -> pool
    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external override {
        // TODO
        (address pair, uint256 amountsIn) = abi.decode(data, (address, uint256));

        require(msg.sender == pair);
        require(sender == address(this), "sender must be this contract");
        require(amount0 > 0 || amount1 > 0, "amount0 or amount1 must be greater than 0");

        // status: receive 80 usdc
        // call fakelendingprotocols "liquidatePosition" 80 usdc -> 1 ether
        IERC20(_USDC).approve(_FAKE_LENDING_PROTOCOL, 80 * 10 ** 6);
        IFakeLendingProtocol(_FAKE_LENDING_PROTOCOL).liquidatePosition();

        // repay repayamount back to the pool
        IWETH(_WETH9).deposit{ value: amountsIn }();
        IERC20(_WETH9).transfer(msg.sender, amountsIn);

        require(address(this).balance >= _MINIMUM_PROFIT, "profit must be greater than 0.01 ether");
    }

    // we use single hop path for testing
    function liquidate(address[] calldata path, uint256 amountOut) external {
        require(amountOut > 0, "AmountOut must be greater than 0");
        // TODO
        // pair = factory.get_pair (path)
        address pair = IUniswapV2Factory(_UNISWAP_FACTORY).getPair(path[0], path[1]);

        // uint256 repayamount = rounter getAmountint
        uint256[] memory amountsIn = IUniswapV2Router01(_UNISWAP_ROUTER).getAmountsIn(amountOut, path);

        // pair.swap(0, 80(amountOut) , data != '')
        IUniswapV2Pair(pair).swap(0, amountOut, address(this), abi.encode(pair, amountsIn[0]));
    }

    receive() external payable {}
}
