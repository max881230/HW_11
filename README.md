## Homework_11

### Practice: 
### Liquidator
`liquidate()` will call `FakeLendingProtocol.liquidatePosition()` to liquidate the position of the user.
Follow the instructions in `contracts/Liquidator.sol` to complete the practice.
(Do not change any other files)

### Sandwich Attack Practice
### Reentrancy Practice
---
### Homework: 
### Arbitrage.sol
`arbitrage()` will do the arbitrage between the given two pools (must be the same pair).
Follow the instructions in `contracts/Arbitrage.sol` to complete the practice.
For convenience, we will only practice method 1, and fix the borrowed amount to 5 WETH

If you are interested in the flash swap arbitrage, you can read more in this [repository](https://github.com/paco0x/amm-arbitrageur)

---
## Testing
Clone this repository, install Node.js dependencies, and build the source code:

```bash
git clone https://github.com/max881230/HW_11.git
cd HW_11
```

```bash
cd FlashSwapHomework
npm install
forge install
forge build
forge test
```

```bash
cd SandwichPractice
npm install
forge install
forge build
forge test
```

```bash
cd UniswapV2Practice
forge install
forge build
forge test
```


