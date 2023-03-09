// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/*
get soft cap for whitelist
problem
*/

contract LaunchPad {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable private token;
    address owner;
    string private label;
    string public symbol;
    uint8 public decimals;

    uint256 private hardCap;
    uint256 private softCap;
    uint256 private hardCapPerWallet;
    uint256 private hardCapForWhitelist;
    uint256 private softCapForWhitelist;

    uint256 public totalSupported;

    uint256 private startTime;
    uint256 private endTime;
    uint256 private whitelistPeriod;

    mapping(address => bool) admins;
    mapping(address => uint256) indices;
    mapping(address => uint256) whitelistIndices;

    struct Supported {
        address who;
        uint256 amount;
    }
    struct Whitelist {
        address who;
        bool status;
    }
    Supported[] private supported;
    Whitelist[] private whitelistList;

    event Support(address who, uint256 amount);
    event Withdraw(address who, uint256 amount);
    event TokenTransfer(address token, address to, uint256 amount);
    event Admin(address who, bool status);
    event SetWhitelist(address who, bool status);
    event Project(uint256 start, uint256 end, uint256 whitelistPeriod);
    event Constants(
        uint256 soft,
        uint256 hard,
        uint256 walletHard,
        uint256 whitelistSoft,
        uint256 whitelistHard
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: not owner");
        _;
    }
    modifier adminToo() {
        require(admins[msg.sender]);
        _;
    }

    function setDecimalAndSymbol(address _token) private {
        ERC20Upgradeable __token = ERC20Upgradeable(_token);
        symbol = __token.symbol();
        decimals = __token.decimals();
    }

    constructor(IERC20Upgradeable _token, string memory _label) payable {
        token = _token;
        label = _label;
        setDecimalAndSymbol(address(_token));
        admins[msg.sender] = true;
        owner = msg.sender;
    }

    receive() external payable {}

    function transferETH(
        address payable recipient,
        uint256 _amount
    ) public payable onlyOwner returns (bool) {
        require(_amount != 0, "Zero amount.");
        require(address(this).balance >= _amount, "Not enough balance.");
        (bool success, ) = recipient.call{value: _amount}("");
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
        emit Project({
            start: _startsAt,
            end: _endsAt,
            whitelistPeriod: _whitelistPeriod
        });
    }

    function setConstants(
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _hardCapPerWallet,
        uint256 _hardCapForWhitelist,
        uint256 _softCapForWhitelist
    ) public adminToo {
        softCap = _softCap * 10 ** decimals;
        hardCap = _hardCap * 10 ** decimals;
        hardCapPerWallet = _hardCapPerWallet * 10 ** decimals;
        hardCapForWhitelist = _hardCapForWhitelist * 10 ** decimals;
        softCapForWhitelist = _softCapForWhitelist * 10 ** decimals;
        emit Constants(
            softCap,
            hardCap,
            hardCapPerWallet,
            softCapForWhitelist,
            hardCapForWhitelist
        );
    }

    function setWhitelist(
        address[] memory _whitelist,
        bool[] memory _status
    ) public adminToo {
        require(_whitelist.length == _status.length, "Length mismatch.");
        for (uint8 i = 0; i < _whitelist.length; i++) {
            whitelistIndices[_whitelist[i]] = whitelistList.length;
            whitelistList.push(
                Whitelist({who: _whitelist[i], status: _status[i]})
            );
            emit SetWhitelist(_whitelist[i], _status[i]);
        }
    }

    function resetLabel(string memory _label) public adminToo {
        label = _label;
    }

    function setAdmin(address _admin, bool _status) public onlyOwner {
        admins[_admin] = _status;
        emit Admin(_admin, _status);
    }

    function support(uint256 _amount) public {
        require(_amount > 0, "Zero amount");
        _amount = _amount * 10 ** decimals;
        require(getProjectIsActive(), "Project not active to suppport yet.");
        require(getIsSupportAvailable(_amount), "Support not available yet.");
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Transfer faild"
        );
        if (supported[indices[msg.sender]].amount > 0) {
            supported[indices[msg.sender]].amount += _amount;
        } else {
            indices[msg.sender] = uint256(supported.length);
            supported.push(Supported({who: msg.sender, amount: _amount}));
        }

        totalSupported += _amount;
        emit Support(msg.sender, _amount);
    }

    function withdraw() public {
        require(!getProjectIsActive(), "Project is still active.");
        require(totalSupported < softCap, "Total support is enough");
        token.safeTransfer(msg.sender, supported[indices[msg.sender]].amount);
        supported[indices[msg.sender]].amount = 0;

        emit Withdraw(msg.sender, supported[indices[msg.sender]].amount);
    }

    // Check this func
    function transferToken(
        IERC20Upgradeable _token,
        address to,
        uint256 amount
    ) public onlyOwner {
        _token.safeTransfer(to, amount);
        emit TokenTransfer(address(_token), to, amount);
    }

    /*
    Executive return functions
    */

    function getIsSupportAvailable(
        uint256 _amount
    ) public view returns (bool isAvailable) {
        require(getProjectIsActive(), "Project not active");
        require(
            totalSupported + _amount <= hardCap,
            "Amount exceeds hard cap."
        );

        if (!whitelistList[whitelistIndices[msg.sender]].status) {
            return
                supported[indices[msg.sender]].amount + _amount <=
                hardCapPerWallet &&
                startTime + whitelistPeriod > block.timestamp;
        } else if (whitelistList[whitelistIndices[msg.sender]].status) {
            return
                supported[indices[msg.sender]].amount + _amount <=
                hardCapForWhitelist &&
                _amount > softCapForWhitelist;
        }
    }

    function getProjectIsActive() public view returns (bool) {
        return startTime < block.timestamp && block.timestamp < endTime;
    }

    function getWhitelistPeriod() public view returns (uint256) {
        return whitelistPeriod;
    }

    // REMOVE AT END

    function getTimeAfter(uint256 _after) public view returns (uint256) {
        return block.timestamp + _after;
    }

    /*
    Data returns
    */

    function getSupported() public view returns (uint256) {
        return supported[indices[msg.sender]].amount;
    }

    function getToken() public view returns (address) {
        return address(token);
    }

    function getEndTime() public view returns (uint256) {
        require(startTime > 0, "Not started yet");
        return endTime;
    }

    function getStartTime() public view returns (uint256) {
        require(startTime > 0, "Not started yet");
        return startTime;
    }

    function SupportedList() public view returns (Supported[] memory) {
        return supported;
    }

    function singleSupport(
        address supporter
    ) public view adminToo returns (Supported memory) {
        return supported[indices[supporter]];
    }

    function getHardCap() public view returns (uint256) {
        return hardCap;
    }

    function getHardCapPerWallet() public view returns (uint256) {
        return hardCapPerWallet;
    }

    function getHardCapPerWhitelist() public view returns (uint256) {
        return hardCapForWhitelist;
    }

    function getSoftCapForWhitelist() public view returns (uint256) {
        return softCapForWhitelist;
    }
}

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

*/

// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 - a
// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db -- owner
// 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
// ["0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"]
// ["true"]
// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"]

// ADD get whitelist all;
