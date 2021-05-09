pragma solidity ^0.8.0;

import {ERC20} from './ERC20.sol';
import {IERC20} from './IERC20.sol';

struct buyToken {
    address tokenAddress;
    string name;
    uint price;
    uint amount;
    uint startBlockNum;
    uint currentAmount;
}

struct stakeInfo {
    uint [] stakedBlockNumList;
    mapping (uint => uint) blockNumStakeAmountMapper;
}

contract Platform {
    event Balance(
        address from_,
        address to
    );

    mapping (address => buyToken) private _buyTokenInfo;
    mapping (address => mapping (address => uint)) private _swappedAmount;
    mapping (address => stakeInfo) private _customerStakeInfos;
    address private _admin;
    address private _platformTokenAddress;
    uint private _minStakeValue = 1000;
    uint private _snapShotTiming = 0;

    constructor (address admin_, address platformTokenAddress_) {
        _admin = admin_;
        _platformTokenAddress = platformTokenAddress_;
    }

    function deposit(uint amount_) public virtual returns (bool) {
        depositToken(_platformTokenAddress, amount_);
        stakeInfo storage info = _customerStakeInfos[msg.sender];
        uint current_amount;
        uint length = info.stakedBlockNumList.length;
        uint block_number = block.number;

        if (length > 0) {
            current_amount = getCurrentDepositAmount(info);
        }
        else {
            current_amount = 0;
        }
        info.stakedBlockNumList.push(block_number);
        info.blockNumStakeAmountMapper[block_number] = current_amount + amount_;
        return true;
    }

    function getDepositedBlockNumbers(address customer) public view returns (uint [] memory) {
        stakeInfo storage info = _customerStakeInfos[customer];
        return info.stakedBlockNumList;
    }

    function getDepositAmountByBlockNumber(address customer, uint blockNumber) public view returns (uint) {
        stakeInfo storage info = _customerStakeInfos[customer];
        return info.blockNumStakeAmountMapper[blockNumber];
    }

    function getCurrentDepositAmount(stakeInfo storage info) internal returns (uint) {
        uint length = info.stakedBlockNumList.length;
        uint current_amount = info.blockNumStakeAmountMapper[info.stakedBlockNumList[length - 1]];

        return current_amount;
    }

    function participateTokenSale(address saleTokenAddress, uint swapAmount) public virtual returns (bool) {
        // check saleTokenAddress is open
        // if user deposit is 0, return
        IERC20 token_ = IERC20(saleTokenAddress);
        uint remainingToken = _buyTokenInfo[saleTokenAddress].currentAmount;
        uint swappedAmount = _swappedAmount[saleTokenAddress][msg.sender];
        if (remainingToken < swapAmount) {
            revert("remainingToken < swapAmount");
        }
        stakeInfo storage info = _customerStakeInfos[msg.sender];
        uint current_amount = getCurrentDepositAmount(info);
        if (current_amount < _minStakeValue) {
            revert("current_amount < _minStakeValue");
        }

        uint length = info.stakedBlockNumList.length;
        uint block_number = block.number;
        uint target_number = block_number + 10 - _snapShotTiming;
        uint snapshotAmount = 0;

        for (uint i = length - 1 ; i >= 0 ; i-- ) {
            if (info.stakedBlockNumList[i] < target_number) {
                snapshotAmount = info.blockNumStakeAmountMapper[info.stakedBlockNumList[i]];
                break;
            }
        }
        if (snapshotAmount < _minStakeValue) {
            string memory msg = "snapshotAmount < _minStakeValue";
            revert(msg);
        }

        // Todo: 현재는 교환이 아니라 조건만 되면 airdrop 형태로 전달해 주는 방식. ether 를 받아서 ether 량 만큼 스왑하도록 수정
        token_.transfer(msg.sender, swapAmount);
        _buyTokenInfo[saleTokenAddress].currentAmount -= swapAmount;
        _swappedAmount[saleTokenAddress][msg.sender] += swapAmount;
        return true;
    }

    function getSwappedAmount(address saleTokenAddress, address customer) public view returns (uint) {
        return _swappedAmount[saleTokenAddress][customer];
    }

    function depositToken(address tokenAddress, uint amount_) internal {
        IERC20 token_ = IERC20(tokenAddress);
        token_.transferFrom(msg.sender, address(this), amount_);
    }

    function registerSaleToken(
        address saleTokenAddress, string memory name_, uint price_, uint amount_, uint startBlockNum_
    ) public virtual returns (bool) {
        _buyTokenInfo[saleTokenAddress] = buyToken(
        {tokenAddress:saleTokenAddress, name: name_, price: price_, amount: amount_, currentAmount: 0, startBlockNum: startBlockNum_}
        );
        return true;
    }

    function getSaleTokenInfo(address saleTokenAddress) public view returns (uint) {
        return _buyTokenInfo[saleTokenAddress].currentAmount;
    }

    function depositSaleToken(address saleTokenAddress, uint amount_) public returns (bool) {
        // deposit sales token which is already get
        depositToken(saleTokenAddress, amount_);
        buyToken storage bti = _buyTokenInfo[saleTokenAddress];
        bti.currentAmount += amount_;
        return true;
    }

    function checkTheBalance (address saleTokenAddress) public view returns (uint) {
        IERC20 saleToken = IERC20(saleTokenAddress);
        uint returnValue;
        returnValue = saleToken.balanceOf(address(this));

        return returnValue;
    }
}