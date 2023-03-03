// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


// ADD get whitelist all;

contract LaunchPad {
    using SafeERC20 for IERC20;

    IERC20 private token;
    uint256 private contractBalance;
    address private owner;
    string private label;
    string private symbol;
    uint8 private decimals;

    uint256 private hardCap;
    uint256 private softCap;
    uint256 private hardCapPerWallet;
    uint256 private hardCapForWhitelist;
    uint256 private softCapForWhitelist;

    uint256 public totalSupported;

    uint256 private startTime;
    uint256 private endTime;
    uint256 private whitelistPeriod;

    mapping(address => bool) whitelist;
    mapping(address => bool) admins;
    mapping(address => uint256) supporters;
    mapping(address => uint32) indices;
    mapping(address => uint32) whitelistIndices;

    struct Supported {
        address who;
        uint256 amount;
    }
    // struct Whitelist { address who; bool status; }
    Supported[] private supported;
    // Whitelist[] private whitelistStruct;

    event Support(address who, uint256 amount);
    event Withdraw(address who, uint256 amount);
    event TokenTransfer(address token, address to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: not owner");
        _;
    }
    modifier adminToo() {
        require(admins[msg.sender]);
        _;
    }

    function setDecimalAndSymbol(address _token) private {
        ERC20 __token = ERC20(_token);
        symbol = __token.symbol();
        decimals = __token.decimals();
    }

    constructor(IERC20 _token, string memory _label) payable {
        token = _token;
        label = _label;
        setDecimalAndSymbol(address(_token));
        admins[msg.sender] = true;
        owner = msg.sender;
    }

    receive() external payable {
        contractBalance += msg.value;
    }

    function transferETH(address payable recipient, uint256 _amount)
        public
        payable
        onlyOwner
        returns (bool)
    {
        require(_amount != 0, "Zero amount.");
        require(address(this).balance >= _amount, "Not enough balance.");
        (bool success, ) = recipient.call{value: _amount}("");
        contractBalance -= _amount;
        return success;
    }

    function setProject(
        uint256 _startsAt,
        uint256 _endsAt,
        uint256 _whitelistPeriod
    ) public adminToo {
        startTime = _startsAt;
        endTime = _endsAt;
        whitelistPeriod = _whitelistPeriod;
    }

    function setConstants(
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _hardCapPerWallet,
        uint256 _hardCapForWhitelist,
        uint256 _softCapForWhitelist
    ) public adminToo {
        softCap = _softCap * 10**decimals;
        hardCap = _hardCap * 10**decimals;
        hardCapPerWallet = _hardCapPerWallet * 10**decimals;
        hardCapForWhitelist = _hardCapForWhitelist * 10**decimals;
        softCapForWhitelist = _softCapForWhitelist * 10**decimals;
    }

    function setWhitelist(address[] memory _whitelist, bool[] memory _status)
        public
        adminToo
    {
        require(_whitelist.length == _status.length, "Length mismatch.");
        for (uint8 i = 0; i < _whitelist.length; i++) {
            whitelist[_whitelist[i]] = _status[i];
        }
    }

    function resetLabel(string memory _label) public adminToo {
        label = _label;
    }

    function setAdmin(address _admin, bool _status) public onlyOwner {
        admins[_admin] = _status;
    }

    function support(uint256 _amount) public {
        require(_amount > 0, "Zero amount");
        uint256 __amount = _amount * 10**decimals;
        require(
            !whitelist[msg.sender] || __amount >= softCapForWhitelist,
            "Not enough amount."
        );
        require(getProjectIsActive(), "Project not active to suppport yet.");
        require(getIsSupportAvailable(_amount), "Support is not available");
        token.transferFrom(msg.sender, address(this), __amount);
        totalSupported += _amount;

        if (supporters[msg.sender] > 0) {
            supported[indices[msg.sender]].amount += __amount;
        } else {
            indices[msg.sender] = uint32(supported.length);
            supported.push(Supported({who: msg.sender, amount: __amount}));
        }
        supporters[msg.sender] += __amount;

        emit Support(msg.sender, __amount);
    }

    function withdraw() public {
        require(!getProjectIsActive(), "Project is still active.");
        require(totalSupported < softCap, "Total support is enough");
        require(supporters[msg.sender] > 0, "Zero support");
        token.safeTransfer(msg.sender, supporters[msg.sender]);
        totalSupported -= supporters[msg.sender];

        emit Withdraw(msg.sender, supporters[msg.sender]);

        supporters[msg.sender] = 0;
        supported[indices[msg.sender]].amount = 0;
    }

    function transferToken(
        IERC20 _token,
        address to,
        uint256 amount
    ) public onlyOwner {
        _token.safeTransfer(to, amount);
        emit TokenTransfer(address(_token), to, amount);
    }

    /*
    State read funcs
    */

    function getIsSupportAvailable(uint256 _amount) public view returns (bool) {
        uint256 __amount = _amount * 10**decimals;
        require(getProjectIsActive(), "Project not active");
        if (
            (totalSupported + __amount > hardCap) ||
            (whitelist[msg.sender] &&
                supporters[msg.sender] + __amount < softCapForWhitelist) ||
            (whitelist[msg.sender] &&
                supporters[msg.sender] + __amount > hardCapForWhitelist) ||
            (!whitelist[msg.sender] &&
                supporters[msg.sender] + __amount > hardCapPerWallet) ||
            (!whitelist[msg.sender] &&
                (startTime + whitelistPeriod > block.timestamp))
        ) {
            return false;
        } else {
            return true;
        }
    }

    function getProjectIsActive() public view returns (bool) {
        return startTime < block.timestamp && endTime > block.timestamp;
    }

    function AllSupportedList() public view returns (Supported[] memory) {
        return supported;
    }

    function getHardCap() public view returns (uint256) {
        return hardCap;
    }

    function getHardCapPerWallet() public view returns (uint256) {
        if (whitelist[msg.sender]) {
            return hardCapForWhitelist;
        }
        return hardCapPerWallet;
    }

    function getSoftCapForWhitelist() public view returns (uint256) {
        return softCapForWhitelist;
    }

    function getStartTime() public view returns (uint256) {
        require(startTime > 0, "Not started yet");
        return startTime;
    }

    function getEndTime() public view returns (uint256) {
        require(startTime > 0, "Not started yet");
        return endTime;
    }

    function getWhitelistPeriod() public view returns (uint256) {
        return whitelistPeriod;
    }

    function getWhitelistPeriodEndTime() public view returns (uint256) {
        require(whitelist[msg.sender] || msg.sender == owner);
        return startTime + whitelistPeriod;
    }

    function getToken() public view returns (address) {
        return address(token);
    }

    function getSupported() public view returns (uint256) {
        return supporters[msg.sender];
    }

    function singleSupport(address supporter)
        public
        view
        adminToo
        returns (uint256)
    {
        return supporters[supporter];
    }

    function getDecimals() public view returns (uint256) {
        return decimals;
    }

    function getLabel() public view returns (string memory) {
        return label;
    }

    function getSymbol() public view returns (string memory) {
        return symbol;
    }
}



//      TEST 

/*
1. Mint token for wallets
2. Approve amounts 
*/

/*
// 1. whitelist 
// 2. constants
// 3. admin
// 4. project
5. support as whitelist
6. support as wallet
7. transfer ownership
8. transfer token
9. withdraw token (soft cap not reached
10. reset label




contract Token20 is ERC20("HoWo", "HW") {
    function mint(address account, uint256 amount) public {
        _mint(account, amount * 10**decimals());
    }

    function decimals() public pure override returns (uint8) {
        return 8;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount * 10**decimals());
        return true;
    }
}
