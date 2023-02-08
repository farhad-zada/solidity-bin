pragma solidity >=0.4.22 <0.9.0;

contract PayableContract {
    address payable public owner;
    uint ticketPrice = 10e18;

    constructor () payable {
        owner = payable (msg.sender);
    }

    function deposit() public payable returns (bool isTrue){
        require(msg.value > 0, "You must deposit a positive value");
        if (msg.value >= ticketPrice){
            return true;
        }
    }

    function withdraw(uint256 amount) public {
        require(amount <= address(this).balance, "Insufficient funds");
        require(msg.sender == owner, "Only the owner can withdraw funds");
        payable (msg.sender).transfer(amount);
    }

    function isContract(address account) public  view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function getContractAddress() public view returns (address) {
        return address(this);
    }

}

