// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IMultiverseSavior} from "./interfaces/IMultiverseSavior.sol";

contract Farming is Ownable, Pausable, ReentrancyGuard {
    uint256 public constant SCALE = 1e12;

    IMultiverseSavior public mst; // MultiSavior Token

    uint256 public nextPoolId;

    mapping(address => bool) public alreadyAdded;

    struct PoolInfo {
        address lpToken;
        uint256 mstPerSecond;
        uint256 lastRewardTime;
        uint256 accMstPerShare;
    }

    mapping(uint256 => PoolInfo) public pools;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    mapping(uint256 => mapping(address => UserInfo)) public users;

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount, uint256 reward);
    event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount, uint256 reward);
    event Harvest(address indexed user, uint256 indexed poolId, uint256 reward);
    event PoolUpdated(uint256 indexed poolId, uint256 newReward, uint256 accmstPerSecond);

    constructor(address _mst) {
        mst = IMultiverseSavior(_mst);

        nextPoolId = 1;
    }

    function pendingReward(uint256 _poolId, address _user) external view returns (uint256) {
        uint256 lpBalance = IERC20(pools[_poolId].lpToken).balanceOf(address(this));

        if (lpBalance == 0) {
            return 0;
        }
        if (block.timestamp < pools[_poolId].lastRewardTime) {
            return 0;
        }

        uint256 timePassed = block.timestamp - pools[_poolId].lastRewardTime;
        uint256 accMstPerShare =
            pools[_poolId].accMstPerShare + timePassed * pools[_poolId].mstPerSecond * SCALE / lpBalance;

        uint256 pending = users[_poolId][_user].amount * accMstPerShare / SCALE - users[_poolId][_user].rewardDebt;

        return pending;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function massUpdatePools() public {
        for (uint256 i; i < nextPoolId;) {
            updatePool(i);
            unchecked {
                ++i;
            }
        }
    }

    function addPool(address _lpToken, uint256 _mstPerSecond, bool _withUpdate) external onlyOwner {
        require(_lpToken != address(0), "Zero address");
        require(!alreadyAdded[_lpToken], "Already added");

        if (_withUpdate) massUpdatePools();

        pools[nextPoolId++] = PoolInfo({
            lpToken: _lpToken,
            mstPerSecond: _mstPerSecond,
            lastRewardTime: block.timestamp,
            accMstPerShare: 0
        });

        alreadyAdded[_lpToken] = true;
    }

    function setRewardSpeed(uint256 _poolId, uint256 _mstPerSecond) external onlyOwner {
        PoolInfo storage pool = pools[_poolId];

        require(pool.lastRewardTime > 0, "Pool not added");

        updatePool(_poolId);

        pool.mstPerSecond = _mstPerSecond;
    }

    function updatePool(uint256 _poolId) public {
        PoolInfo storage pool = pools[_poolId];

        if (block.timestamp <= pool.lastRewardTime) return;

        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }

        uint256 time = block.timestamp - pool.lastRewardTime;
        uint256 mstReward = time * pool.mstPerSecond;

        pool.accMstPerShare += mstReward * SCALE / lpSupply;
        pool.lastRewardTime = block.timestamp;

        mst.mint(address(this), mstReward);

        emit PoolUpdated(_poolId, mstReward, pool.accMstPerShare);
    }

    function deposit(uint256 _poolId, uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Zero amount");

        PoolInfo storage pool = pools[_poolId];
        UserInfo storage user = users[_poolId][msg.sender];

        updatePool(_poolId);

        if (user.amount > 0) {
            uint256 pending = user.amount * pool.accMstPerShare / SCALE - user.rewardDebt;
            uint256 actualReward = _safeMstTransfer(msg.sender, pending);
            emit Deposit(msg.sender, _poolId, _amount, actualReward);
        }

        IERC20(pool.lpToken).transferFrom(msg.sender, address(this), _amount);

        user.amount += _amount;
        user.rewardDebt = user.amount * pool.accMstPerShare / SCALE;
    }

    function _safeMstTransfer(address _to, uint256 _amount) internal returns (uint256) {
        uint256 poolBalance = mst.balanceOf(address(this));
        require(poolBalance > 0, "Zero balance");

        if (_amount > poolBalance) {
            mst.transfer(_to, poolBalance);
            return poolBalance;
        } else {
            mst.transfer(_to, _amount);
            return _amount;
        }
    }

    function withdraw(uint256 _poolId, uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Zero amount");

        PoolInfo storage pool = pools[_poolId];
        UserInfo storage user = users[_poolId][msg.sender];

        require(user.amount >= _amount, "Not enough amount");

        updatePool(_poolId);

        uint256 pending = user.amount * pool.accMstPerShare / SCALE - user.rewardDebt;
        uint256 actualReward = _safeMstTransfer(msg.sender, pending);
        emit Withdraw(msg.sender, _poolId, _amount, actualReward);

        user.amount -= _amount;
        user.rewardDebt = user.amount * pool.accMstPerShare / SCALE;

        IERC20(pool.lpToken).transfer(msg.sender, _amount);
    }

    function harvest(uint256 _poolId, address _to) public nonReentrant whenNotPaused {
        PoolInfo storage pool = pools[_poolId];
        UserInfo storage user = users[_poolId][msg.sender];

        updatePool(_poolId);

        uint256 pending = user.amount * pool.accMstPerShare / SCALE - user.rewardDebt;
        uint256 actualReward = _safeMstTransfer(_to, pending);
        emit Harvest(msg.sender, _poolId, actualReward);

        user.rewardDebt = user.amount * pool.accMstPerShare / SCALE;
    }
}