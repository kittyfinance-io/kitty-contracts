// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./lib/Babylonian.sol";
import "./owner/Operator.sol";
import "./utils/ContractGuard.sol";
import "./interfaces/IBasisAsset.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/INursery.sol";

/*
 __  __     __     ______   ______   __  __    
/\ \/ /    /\ \   /\__  _\ /\__  _\ /\ \_\ \   
\ \  _"-.  \ \ \  \/_/\ \/ \/_/\ \/ \ \____ \  
 \ \_\ \_\  \ \_\    \ \_\    \ \_\  \/\_____\ 
  \/_/\/_/   \/_/     \/_/     \/_/   \/_____/ 
                                               

*/
contract Treasury is ContractGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========= CONSTANT VARIABLES ======== */

    uint256 public constant PERIOD = 6 hours;

    /* ========== STATE VARIABLES ========== */

    // governance
    address public operator;

    // flags
    bool public initialized = false;

    // epoch
    uint256 public startTime;
    uint256 public epoch = 0;
    uint256 public epochSupplyContractionLeft = 0;

    // core components
    address public kitty;
    address public bbond;
    address public bshare;

    address public nursery;
    address public kittyOracle;

    // price
    uint256 public kittyPriceOne;
    uint256 public kittyPriceCeiling;

    uint256 public seigniorageSaved;

    uint256[] public supplyTiers;
    uint256[] public maxExpansionTiers;

    uint256 public maxSupplyExpansionPercent;
    uint256 public bondDepletionFloorPercent;
    uint256 public seigniorageExpansionFloorPercent;
    uint256 public maxSupplyContractionPercent;
    uint256 public maxDebtRatioPercent;

    // 28 first epochs (1 week) with 4.5% expansion regardless of KITTY price
    uint256 public bootstrapEpochs;
    uint256 public bootstrapSupplyExpansionPercent;

    /* =================== Added variables =================== */
    uint256 public previousEpochKittyPrice;
    uint256 public maxDiscountRate; // when purchasing bond
    uint256 public maxPremiumRate; // when redeeming bond
    uint256 public discountPercent;
    uint256 public premiumThreshold;
    uint256 public premiumPercent;
    uint256 public mintingFactorForPayingDebt; // print extra KITTY during debt phase

    address public daoFund;
    uint256 public daoFundSharedPercent;

    address public devFund;
    uint256 public devFundSharedPercent;
    address public team1Fund;
    uint256 public team1FundSharedPercent;

    /* =================== Events =================== */

    event Initialized(address indexed executor, uint256 at);
    event BurnedBonds(address indexed from, uint256 bondAmount);
    event RedeemedBonds(address indexed from, uint256 kittyAmount, uint256 bondAmount);
    event BoughtBonds(address indexed from, uint256 kittyAmount, uint256 bondAmount);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event NurseryFunded(uint256 timestamp, uint256 seigniorage);
    event DaoFundFunded(uint256 timestamp, uint256 seigniorage);
    event DevFundFunded(uint256 timestamp, uint256 seigniorage);
    event TeamFundFunded(uint256 timestamp, uint256 seigniorage);

    /* =================== Modifier =================== */

    modifier onlyOperator() {
        require(operator == msg.sender, "Treasury: caller is not the operator");
        _;
    }

    modifier checkCondition() {
        require(now >= startTime, "Treasury: not started yet");

        _;
    }

    modifier checkEpoch() {
        require(now >= nextEpochPoint(), "Treasury: not opened yet");

        _;

        epoch = epoch.add(1);
        epochSupplyContractionLeft = (getKittyPrice() > kittyPriceCeiling) ? 0 : getKittyCirculatingSupply().mul(maxSupplyContractionPercent).div(10000);
    }

    modifier checkOperator() {
        require(
            IBasisAsset(kitty).operator() == address(this) &&
                IBasisAsset(bbond).operator() == address(this) &&
                IBasisAsset(bshare).operator() == address(this) &&
                Operator(nursery).operator() == address(this),
            "Treasury: need more permission"
        );

        _;
    }

    modifier notInitialized() {
        require(!initialized, "Treasury: already initialized");

        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // epoch
    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(epoch.mul(PERIOD));
    }

    // oracle
    function getKittyPrice() public view returns (uint256 kittyPrice) {
        try IOracle(kittyOracle).consult(kitty, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult KITTY price from the oracle");
        }
    }

    function getKittyUpdatedPrice() public view returns (uint256 _kittyPrice) {
        try IOracle(kittyOracle).twap(kitty, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult KITTY price from the oracle");
        }
    }

    // budget
    function getReserve() public view returns (uint256) {
        return seigniorageSaved;
    }

    function getBurnableKittyLeft() public view returns (uint256 _burnableKittyLeft) {
        uint256 _kittyPrice = getKittyPrice();
        if (_kittyPrice <= kittyPriceOne) {
            uint256 _kittySupply = getKittyCirculatingSupply();
            uint256 _bondMaxSupply = _kittySupply.mul(maxDebtRatioPercent).div(10000);
            uint256 _bondSupply = IERC20(bbond).totalSupply();
            if (_bondMaxSupply > _bondSupply) {
                uint256 _maxMintableBond = _bondMaxSupply.sub(_bondSupply);
                uint256 _maxBurnableKitty = _maxMintableBond.mul(_kittyPrice).div(1e18);
                _burnableKittyLeft = Math.min(epochSupplyContractionLeft, _maxBurnableKitty);
            }
        }
    }

    function getRedeemableBonds() public view returns (uint256 _redeemableBonds) {
        uint256 _kittyPrice = getKittyPrice();
        if (_kittyPrice > kittyPriceCeiling) {
            uint256 _totalKitty = IERC20(kitty).balanceOf(address(this));
            uint256 _rate = getBondPremiumRate();
            if (_rate > 0) {
                _redeemableBonds = _totalKitty.mul(1e18).div(_rate);
            }
        }
    }

    function getBondDiscountRate() public view returns (uint256 _rate) {
        uint256 _kittyPrice = getKittyPrice();
        if (_kittyPrice <= kittyPriceOne) {
            if (discountPercent == 0) {
                // no discount
                _rate = kittyPriceOne;
            } else {
                uint256 _bondAmount = kittyPriceOne.mul(1e18).div(_kittyPrice); // to burn 1 KITTY
                uint256 _discountAmount = _bondAmount.sub(kittyPriceOne).mul(discountPercent).div(10000);
                _rate = kittyPriceOne.add(_discountAmount);
                if (maxDiscountRate > 0 && _rate > maxDiscountRate) {
                    _rate = maxDiscountRate;
                }
            }
        }
    }

    function getBondPremiumRate() public view returns (uint256 _rate) {
        uint256 _kittyPrice = getKittyPrice();
        if (_kittyPrice > kittyPriceCeiling) {
            uint256 _kittyPricePremiumThreshold = kittyPriceOne.mul(premiumThreshold).div(100);
            if (_kittyPrice >= _kittyPricePremiumThreshold) {
                //Price > 1.10
                uint256 _premiumAmount = _kittyPrice.sub(kittyPriceOne).mul(premiumPercent).div(10000);
                _rate = kittyPriceOne.add(_premiumAmount);
                if (maxPremiumRate > 0 && _rate > maxPremiumRate) {
                    _rate = maxPremiumRate;
                }
            } else {
                // no premium bonus
                _rate = kittyPriceOne;
            }
        }
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        address _kitty,
        address _bbond,
        address _bshare,
        address _kittyOracle,
        address _nursery,
        uint256 _startTime
    ) public notInitialized {
        kitty = _kitty;
        bbond = _bbond;
        bshare = _bshare;
        kittyOracle = _kittyOracle;
        nursery = _nursery;
        startTime = _startTime;

        kittyPriceOne = 10**18; // This is to allow a PEG of 1 KITTY per AVAX
        kittyPriceCeiling = kittyPriceOne.mul(101).div(100);

        // Dynamic max expansion percent
        supplyTiers = [0 ether, 5000 ether, 10000 ether, 15000 ether, 20000 ether, 50000 ether, 100000 ether, 200000 ether, 500000 ether];
        maxExpansionTiers = [450, 400, 350, 300, 250, 200, 150, 125, 100];

        maxSupplyExpansionPercent = 400; // Upto 4.0% supply for expansion

        bondDepletionFloorPercent = 10000; // 100% of Bond supply for depletion floor
        seigniorageExpansionFloorPercent = 3500; // At least 35% of expansion reserved for nursery
        maxSupplyContractionPercent = 300; // Upto 3.0% supply for contraction (to burn KITTY and mint tBOND)
        maxDebtRatioPercent = 4500; // Upto 35% supply of tBOND to purchase

        premiumThreshold = 110;
        premiumPercent = 7000;

        // First 28 epochs with 4.5% expansion
        bootstrapEpochs = 0;
        bootstrapSupplyExpansionPercent = 450;

        // set seigniorageSaved to it's balance
        seigniorageSaved = IERC20(kitty).balanceOf(address(this));

        initialized = true;
        operator = msg.sender;
        emit Initialized(msg.sender, block.number);
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setNursery(address _nursery) external onlyOperator {
        nursery = _nursery;
    }

    function setKittyOracle(address _kittyOracle) external onlyOperator {
        kittyOracle = _kittyOracle;
    }

    function setKittyPriceCeiling(uint256 _kittyPriceCeiling) external onlyOperator {
        require(_kittyPriceCeiling >= kittyPriceOne && _kittyPriceCeiling <= kittyPriceOne.mul(120).div(100), "out of range"); // [$1.0, $1.2]
        kittyPriceCeiling = _kittyPriceCeiling;
    }

    function setMaxSupplyExpansionPercents(uint256 _maxSupplyExpansionPercent) external onlyOperator {
        require(_maxSupplyExpansionPercent >= 10 && _maxSupplyExpansionPercent <= 1000, "_maxSupplyExpansionPercent: out of range"); // [0.1%, 10%]
        maxSupplyExpansionPercent = _maxSupplyExpansionPercent;
    }

    function setSupplyTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 9, "Index has to be lower than count of tiers");
        if (_index > 0) {
            require(_value > supplyTiers[_index - 1]);
        }
        if (_index < 8) {
            require(_value < supplyTiers[_index + 1]);
        }
        supplyTiers[_index] = _value;
        return true;
    }

    function setMaxExpansionTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 9, "Index has to be lower than count of tiers");
        require(_value >= 10 && _value <= 1000, "_value: out of range"); // [0.1%, 10%]
        maxExpansionTiers[_index] = _value;
        return true;
    }

    function setBondDepletionFloorPercent(uint256 _bondDepletionFloorPercent) external onlyOperator {
        require(_bondDepletionFloorPercent >= 500 && _bondDepletionFloorPercent <= 10000, "out of range"); // [5%, 100%]
        bondDepletionFloorPercent = _bondDepletionFloorPercent;
    }

    function setMaxSupplyContractionPercent(uint256 _maxSupplyContractionPercent) external onlyOperator {
        require(_maxSupplyContractionPercent >= 100 && _maxSupplyContractionPercent <= 1500, "out of range"); // [0.1%, 15%]
        maxSupplyContractionPercent = _maxSupplyContractionPercent;
    }

    function setMaxDebtRatioPercent(uint256 _maxDebtRatioPercent) external onlyOperator {
        require(_maxDebtRatioPercent >= 1000 && _maxDebtRatioPercent <= 10000, "out of range"); // [10%, 100%]
        maxDebtRatioPercent = _maxDebtRatioPercent;
    }

    function setBootstrap(uint256 _bootstrapEpochs, uint256 _bootstrapSupplyExpansionPercent) external onlyOperator {
        require(_bootstrapEpochs <= 120, "_bootstrapEpochs: out of range"); // <= 1 month
        require(_bootstrapSupplyExpansionPercent >= 100 && _bootstrapSupplyExpansionPercent <= 1000, "_bootstrapSupplyExpansionPercent: out of range"); // [1%, 10%]
        bootstrapEpochs = _bootstrapEpochs;
        bootstrapSupplyExpansionPercent = _bootstrapSupplyExpansionPercent;
    }

    function setExtraFunds(
        address _daoFund,
        uint256 _daoFundSharedPercent,
        address _devFund,
        uint256 _devFundSharedPercent,
        address _team1Fund,
        uint256 _team1FundSharedPercent
    ) external onlyOperator {
        require(_daoFund != address(0), "zero");
        require(_daoFundSharedPercent <= 3000, "out of range"); // <= 30%
        require(_devFund != address(0), "zero");
        require(_devFundSharedPercent <= 500, "out of range"); // <= 5%
        require(_team1Fund != address(0), "zero");
        require(_team1FundSharedPercent <= 500, "out of range"); // <= 5%
        daoFund = _daoFund;
        daoFundSharedPercent = _daoFundSharedPercent;
        devFund = _devFund;
        devFundSharedPercent = _devFundSharedPercent;
        team1Fund = _team1Fund;
        team1FundSharedPercent = _team1FundSharedPercent;
    }

    function setMaxDiscountRate(uint256 _maxDiscountRate) external onlyOperator {
        maxDiscountRate = _maxDiscountRate;
    }

    function setMaxPremiumRate(uint256 _maxPremiumRate) external onlyOperator {
        maxPremiumRate = _maxPremiumRate;
    }

    function setDiscountPercent(uint256 _discountPercent) external onlyOperator {
        require(_discountPercent <= 20000, "_discountPercent is over 200%");
        discountPercent = _discountPercent;
    }

    function setPremiumThreshold(uint256 _premiumThreshold) external onlyOperator {
        require(_premiumThreshold >= kittyPriceCeiling, "_premiumThreshold exceeds kittyPriceCeiling");
        require(_premiumThreshold <= 150, "_premiumThreshold is higher than 1.5");
        premiumThreshold = _premiumThreshold;
    }

    function setPremiumPercent(uint256 _premiumPercent) external onlyOperator {
        require(_premiumPercent <= 20000, "_premiumPercent is over 200%");
        premiumPercent = _premiumPercent;
    }

    function setMintingFactorForPayingDebt(uint256 _mintingFactorForPayingDebt) external onlyOperator {
        require(_mintingFactorForPayingDebt >= 10000 && _mintingFactorForPayingDebt <= 20000, "_mintingFactorForPayingDebt: out of range"); // [100%, 200%]
        mintingFactorForPayingDebt = _mintingFactorForPayingDebt;
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function _updateKittyPrice() internal {
        try IOracle(kittyOracle).update() {} catch {}
    }

    function getKittyCirculatingSupply() public view returns (uint256) {
        IERC20 kittyErc20 = IERC20(kitty);
        uint256 totalSupply = kittyErc20.totalSupply();
        uint256 balanceExcluded = 0;
        return totalSupply.sub(balanceExcluded);
    }

    function buyBonds(uint256 _kittyAmount, uint256 targetPrice) external onlyOneBlock checkCondition checkOperator {
        require(_kittyAmount > 0, "Treasury: cannot purchase bonds with zero amount");

        uint256 kittyPrice = getKittyPrice();
        require(kittyPrice == targetPrice, "Treasury: KITTY price moved");
        require(
            kittyPrice < kittyPriceOne, // price < $1
            "Treasury: kittyPrice not eligible for bond purchase"
        );

        require(_kittyAmount <= epochSupplyContractionLeft, "Treasury: not enough bond left to purchase");

        uint256 _rate = getBondDiscountRate();
        require(_rate > 0, "Treasury: invalid bond rate");

        uint256 _bondAmount = _kittyAmount.mul(_rate).div(1e18);
        uint256 kittySupply = getKittyCirculatingSupply();
        uint256 newBondSupply = IERC20(bbond).totalSupply().add(_bondAmount);
        require(newBondSupply <= kittySupply.mul(maxDebtRatioPercent).div(10000), "over max debt ratio");

        IBasisAsset(kitty).burnFrom(msg.sender, _kittyAmount);
        IBasisAsset(bbond).mint(msg.sender, _bondAmount);

        epochSupplyContractionLeft = epochSupplyContractionLeft.sub(_kittyAmount);
        _updateKittyPrice();

        emit BoughtBonds(msg.sender, _kittyAmount, _bondAmount);
    }

    function redeemBonds(uint256 _bondAmount, uint256 targetPrice) external onlyOneBlock checkCondition checkOperator {
        require(_bondAmount > 0, "Treasury: cannot redeem bonds with zero amount");

        uint256 kittyPrice = getKittyPrice();
        require(kittyPrice == targetPrice, "Treasury: KITTY price moved");
        require(
            kittyPrice > kittyPriceCeiling, // price > $1.01
            "Treasury: kittyPrice not eligible for bond purchase"
        );

        uint256 _rate = getBondPremiumRate();
        require(_rate > 0, "Treasury: invalid bond rate");

        uint256 _kittyAmount = _bondAmount.mul(_rate).div(1e18);
        require(IERC20(kitty).balanceOf(address(this)) >= _kittyAmount, "Treasury: treasury has no more budget");

        seigniorageSaved = seigniorageSaved.sub(Math.min(seigniorageSaved, _kittyAmount));

        IBasisAsset(bbond).burnFrom(msg.sender, _bondAmount);
        IERC20(kitty).safeTransfer(msg.sender, _kittyAmount);

        _updateKittyPrice();

        emit RedeemedBonds(msg.sender, _kittyAmount, _bondAmount);
    }

    function _sendToNursery(uint256 _amount) internal {
        IBasisAsset(kitty).mint(address(this), _amount);

        uint256 _daoFundSharedAmount = 0;
        if (daoFundSharedPercent > 0) {
            _daoFundSharedAmount = _amount.mul(daoFundSharedPercent).div(10000);
            IERC20(kitty).transfer(daoFund, _daoFundSharedAmount);
            emit DaoFundFunded(now, _daoFundSharedAmount);
        }

        uint256 _devFundSharedAmount = 0;
        if (devFundSharedPercent > 0) {
            _devFundSharedAmount = _amount.mul(devFundSharedPercent).div(10000);
            IERC20(kitty).transfer(devFund, _devFundSharedAmount);
            emit DevFundFunded(now, _devFundSharedAmount);
        }

        uint256 _team1FundSharedAmount = 0;
        if (team1FundSharedPercent > 0) {
            _team1FundSharedAmount = _amount.mul(team1FundSharedPercent).div(10000);
            IERC20(kitty).transfer(team1Fund, _team1FundSharedAmount);
            emit TeamFundFunded(now, _team1FundSharedAmount);
        }

        _amount = _amount.sub(_daoFundSharedAmount).sub(_devFundSharedAmount).sub(_team1FundSharedAmount);

        IERC20(kitty).safeApprove(nursery, 0);
        IERC20(kitty).safeApprove(nursery, _amount);
        INursery(nursery).allocateSeigniorage(_amount);
        emit NurseryFunded(now, _amount);
    }

    function _calculateMaxSupplyExpansionPercent(uint256 _kittySupply) internal returns (uint256) {
        for (uint8 tierId = 8; tierId >= 0; --tierId) {
            if (_kittySupply >= supplyTiers[tierId]) {
                maxSupplyExpansionPercent = maxExpansionTiers[tierId];
                break;
            }
        }
        return maxSupplyExpansionPercent;
    }

    function allocateSeigniorage() external onlyOneBlock checkCondition checkEpoch checkOperator {
        _updateKittyPrice();
        previousEpochKittyPrice = getKittyPrice();
        uint256 kittySupply = getKittyCirculatingSupply().sub(seigniorageSaved);
        if (epoch < bootstrapEpochs) {
            // 28 first epochs with 4.5% expansion
            _sendToNursery(kittySupply.mul(bootstrapSupplyExpansionPercent).div(10000));
        } else {
            if (previousEpochKittyPrice > kittyPriceCeiling) {
                // Expansion ($KITTY Price > 1 $ETH): there is some seigniorage to be allocated
                uint256 bondSupply = IERC20(bbond).totalSupply();
                uint256 _percentage = previousEpochKittyPrice.sub(kittyPriceOne);
                uint256 _savedForBond;
                uint256 _savedForNursery;
                uint256 _mse = _calculateMaxSupplyExpansionPercent(kittySupply).mul(1e14);
                if (_percentage > _mse) {
                    _percentage = _mse;
                }
                if (seigniorageSaved >= bondSupply.mul(bondDepletionFloorPercent).div(10000)) {
                    // saved enough to pay debt, mint as usual rate
                    _savedForNursery = kittySupply.mul(_percentage).div(1e18);
                } else {
                    // have not saved enough to pay debt, mint more
                    uint256 _seigniorage = kittySupply.mul(_percentage).div(1e18);
                    _savedForNursery = _seigniorage.mul(seigniorageExpansionFloorPercent).div(10000);
                    _savedForBond = _seigniorage.sub(_savedForNursery);
                    if (mintingFactorForPayingDebt > 0) {
                        _savedForBond = _savedForBond.mul(mintingFactorForPayingDebt).div(10000);
                    }
                }
                if (_savedForNursery > 0) {
                    _sendToNursery(_savedForNursery);
                }
                if (_savedForBond > 0) {
                    seigniorageSaved = seigniorageSaved.add(_savedForBond);
                    IBasisAsset(kitty).mint(address(this), _savedForBond);
                    emit TreasuryFunded(now, _savedForBond);
                }
            }
        }
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        // do not allow to drain core tokens
        require(address(_token) != address(kitty), "kitty");
        require(address(_token) != address(bbond), "bond");
        require(address(_token) != address(bshare), "share");
        _token.safeTransfer(_to, _amount);
    }

    function nurserySetOperator(address _operator) external onlyOperator {
        INursery(nursery).setOperator(_operator);
    }

    function nurserySetLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external onlyOperator {
        INursery(nursery).setLockUp(_withdrawLockupEpochs, _rewardLockupEpochs);
    }

    function nurseryAllocateSeigniorage(uint256 amount) external onlyOperator {
        INursery(nursery).allocateSeigniorage(amount);
    }

    function nurseryGovernanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        INursery(nursery).governanceRecoverUnsupported(_token, _amount, _to);
    }
}
