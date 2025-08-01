// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface ISimpleSwap {
    function swapTokens(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256);
    function getQuote(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256);
}

contract StakingRewards {
    // State variables
    address public owner;
    address public stakingToken;
    address public rewardToken;
    address public simpleSwap;
    
    uint256 public rewardRate; // Rewards per second
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public totalStaked;
    uint256 public rewardsDuration = 7 days; // Default 7 days
    uint256 public periodFinish;
    
    // User mappings
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public stakingTime;
    
    // Events
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event SwappedRewards(address indexed user, uint256 rewardAmount, uint256 swappedAmount);
    
    // Errors
    error Unauthorized();
    error InvalidAddress();
    error InvalidAmount();
    error InsufficientBalance();
    error TransferFailed();
    error NoRewards();
    error RewardPeriodNotFinished();
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }
    
    modifier validAddress(address _addr) {
        if (_addr == address(0)) revert InvalidAddress();
        _;
    }
    
    modifier validAmount(uint256 _amount) {
        if (_amount == 0) revert InvalidAmount();
        _;
    }
    
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    
    constructor(
        address _stakingToken,
        address _rewardToken,
        address _simpleSwap,
        uint256 _rewardRate
    ) 
        validAddress(_stakingToken)
        validAddress(_rewardToken)
    {
        owner = msg.sender;
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        simpleSwap = _simpleSwap;
        rewardRate = _rewardRate;
    }
    
    /**
     * @dev Returns the last time rewards were applicable
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }
    
    /**
     * @dev Calculate reward per token
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + 
            (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalStaked);
    }
    
    /**
     * @dev Calculate earned rewards for an account
     */
    function earned(address account) public view returns (uint256) {
        return ((stakedBalance[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + 
            rewards[account];
    }
    
    /**
     * @dev Get reward for duration
     */
    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }
    
    /**
     * @dev Stake tokens
     * @param amount Amount to stake
     */
    function stake(uint256 amount) 
        external 
        validAmount(amount) 
        updateReward(msg.sender) 
    {
        IERC20 token = IERC20(stakingToken);
        
        if (token.balanceOf(msg.sender) < amount) revert InsufficientBalance();
        if (token.allowance(msg.sender, address(this)) < amount) revert InsufficientBalance();
        
        if (!token.transferFrom(msg.sender, address(this), amount)) {
            revert TransferFailed();
        }
        
        totalStaked += amount;
        stakedBalance[msg.sender] += amount;
        stakingTime[msg.sender] = block.timestamp;
        
        emit Staked(msg.sender, amount);
    }
    
    /**
     * @dev Withdraw staked tokens
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) 
        public 
        validAmount(amount) 
        updateReward(msg.sender) 
    {
        if (stakedBalance[msg.sender] < amount) revert InsufficientBalance();
        
        totalStaked -= amount;
        stakedBalance[msg.sender] -= amount;
        
        if (!IERC20(stakingToken).transfer(msg.sender, amount)) {
            revert TransferFailed();
        }
        
        emit Withdrawn(msg.sender, amount);
    }
    
    /**
     * @dev Claim rewards
     */
    function getReward() public  updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward == 0) revert NoRewards();
        
        rewards[msg.sender] = 0;
        
        if (!IERC20(rewardToken).transfer(msg.sender, reward)) {
            revert TransferFailed();
        }
        
        emit RewardPaid(msg.sender, reward);
    }
    
    /**
     * @dev Claim rewards and automatically swap to staking token
     */
    function getRewardAndSwap() public  updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward == 0) revert NoRewards();
        if (simpleSwap == address(0)) revert InvalidAddress();
        
        rewards[msg.sender] = 0;
        
        // Approve SimpleSwap to spend reward tokens
        if (!IERC20(rewardToken).approve(simpleSwap, reward)) {
            revert TransferFailed();
        }
        
        // Swap reward tokens for staking tokens
        uint256 swappedAmount = ISimpleSwap(simpleSwap).swapTokens(
            rewardToken,
            stakingToken,
            reward
        );
        
        emit RewardPaid(msg.sender, reward);
        emit SwappedRewards(msg.sender, reward, swappedAmount);
    }
    
    /**
     * @dev Exit - withdraw all staked tokens and claim rewards
     */
    function exit() external {
        withdraw(stakedBalance[msg.sender]);
        getReward();
    }
    
    // /**
    //  * @dev Exit and swap - withdraw all staked tokens and swap rewards
    //  */
    function exitAndSwap() external {
        withdraw(stakedBalance[msg.sender]);
        getRewardAndSwap();
    }
    
    /**
     * @dev Add rewards to the pool (only owner)
     * @param reward Amount of reward tokens to add
     */
    function notifyRewardAmount(uint256 reward) 
        external 
        onlyOwner 
        validAmount(reward)
        updateReward(address(0)) 
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }
        
        // Ensure the provided reward amount is not more than the balance in the contract
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        if (rewardRate > balance / rewardsDuration) revert InsufficientBalance();
        
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        
        emit RewardAdded(reward);
    }
    
    /**
     * @dev Set rewards duration (only owner)
     * @param _rewardsDuration New rewards duration in seconds
     */
    function setRewardsDuration(uint256 _rewardsDuration) 
        external 
        onlyOwner 
        validAmount(_rewardsDuration)
    {
        if (block.timestamp <= periodFinish) revert RewardPeriodNotFinished();
        
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(_rewardsDuration);
    }
    
    /**
     * @dev Update SimpleSwap address (only owner)
     * @param _simpleSwap New SimpleSwap address
     */
    function setSimpleSwap(address _simpleSwap) external onlyOwner {
        simpleSwap = _simpleSwap;
    }
    
    /**
     * @dev Get quote for swapping rewards
     * @param user User address to check rewards for
     */
    function getSwapQuote(address user) external view returns (uint256) {
        if (simpleSwap == address(0)) return 0;
        
        uint256 reward = earned(user);
        if (reward == 0) return 0;
        
        return ISimpleSwap(simpleSwap).getQuote(rewardToken, stakingToken, reward);
    }
    
    /**
     * @dev Get user staking info
     * @param user User address
     */
    function getUserInfo(address user) 
        external 
        view 
        returns (
            uint256 staked,
            uint256 earnedRewards,
            uint256 stakingDuration,
            uint256 potentialSwapAmount
        ) 
    {
        staked = stakedBalance[user];
        earnedRewards = earned(user);
        stakingDuration = stakingTime[user] > 0 ? block.timestamp - stakingTime[user] : 0;
        
        if (simpleSwap != address(0) && earnedRewards > 0) {
            potentialSwapAmount = ISimpleSwap(simpleSwap).getQuote(
                rewardToken, 
                stakingToken, 
                earnedRewards
            );
        }
    }
    
    /**
     * @dev Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) external onlyOwner validAddress(newOwner) {
        owner = newOwner;
    }
    
    /**
     * @dev Emergency withdraw for owner (only when rewards period is finished)
     * @param token Token address to withdraw
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, uint256 amount) 
        external 
        onlyOwner 
        validAddress(token)
        validAmount(amount)
    {
        if (block.timestamp < periodFinish) revert RewardPeriodNotFinished();
        
        if (!IERC20(token).transfer(owner, amount)) {
            revert TransferFailed();
        }
    }
}