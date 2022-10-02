// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 < 0.9.0;

contract Auction {

    address payable public Auctioneer; // Owner Address
    uint public startBlock;  // starting block of auction
    uint public endBlock;  // ending block of auciton

    // Auction Status
    enum auction_state {Started, Ended, Running}
    auction_state public AuctionState;

    uint public payableBid; // Final amount of auction
    uint public incrementBid; 

    address payable public highestBidder; // address of highest bidder 
    mapping (address => uint) Bids; // mapping of bids
    mapping (address => bool) insert;  // for checking who place the bid
    address[] Key; // address of bidder

    // To chcek sender is not owner 
    modifier notOwner() {
        require(msg.sender != Auctioneer, "Owner cann't place bid");
        _;
    }

    // To chcek sender is owner 
    modifier Owner() {
        require(msg.sender == Auctioneer, "Only Owner can access this feature");
        _;
    }

    // To check Auction is start or not
    modifier started() {
        require(block.number > startBlock);
        _;
    }
    
    // check if auction is ended or not
    modifier beforeEnded() {
        require(block.number <  endBlock);
        _;
    }

    // event to debug the bids and amount transfer
    event placeBid(address bidder, uint value, address hbidder, uint hvalue, uint payableBid);
    event transferAmount(address person, uint value);

    // Constructor for hosting auction
    constructor() {
        Auctioneer = payable(msg.sender);
        AuctionState = auction_state.Running;
        startBlock = block.number;
        endBlock = block.number + 240;  // for 1 hour
        incrementBid = 1 ether;
    }
    
    // Find Minimum
    function min(uint a, uint b) pure private returns (uint) {
        if ( a <= b) 
            return a;
        else
            return b;
    }
    
    // To end the auction
    function endAuction() public Owner{
        AuctionState = auction_state.Ended;
    }

    // Bid function
    function bid() payable public notOwner started beforeEnded {
        // Chech Pre require condition
        require(AuctionState == auction_state.Running);
        require(msg.value >=1 ether, "Bid Value must be greater than 1");

        // retrive existing bid of sender
        uint currentBid = Bids[msg.sender] + msg.value;

        // check the cuurent bid
        require (currentBid > payableBid );

        Bids[msg.sender] = currentBid;


        // Insert sender into key array
        if(!insert[msg.sender]){
            insert[msg.sender] = true;
            Key.push(msg.sender);
        }

        // check status of bids based on the current bid and accourding that change the highest Bidder.
        if ( currentBid <= Bids[highestBidder]) {
            payableBid = min(currentBid+incrementBid, Bids[highestBidder]);
        }
        else {
            payableBid = min(currentBid, Bids[highestBidder]+incrementBid);
            highestBidder = payable(msg.sender);
        }

        // emit the bid
        emit placeBid(msg.sender, currentBid, highestBidder, Bids[highestBidder], payableBid);
    }

    // Transfer Money to bidder account
    function finalizAuction() public Owner {
        require(block.number > endBlock || AuctionState == auction_state.Ended);
        require(msg.sender == Auctioneer || Bids[msg.sender] > 0);

        address payable personAdd;
        uint amount;

        Auctioneer.transfer(payableBid);

        for (uint i = 0; i < Key.length; i++) 
        {
            if ( Key[i] == highestBidder ) {
                personAdd = highestBidder;
                amount = Bids[highestBidder] - payableBid;             
            }
            else 
            {
                personAdd = payable(Key[i]);
                amount = Bids[Key[i]];
            }
            Bids[personAdd] = 0;
            personAdd.transfer(amount);
            emit transferAmount(personAdd, amount);
        }
    }

    function getBids() view public Owner returns(address[] memory, uint[] memory) {
        address[] memory Accounts = new address[](Key.length);
        uint[] memory Money = new uint[](Key.length);

        for(uint i = 0; i < Key.length; i++) {
            Accounts[i] = Key[i];
            Money[i] = Bids[Key[i]];
        }
        
        return (Accounts, Money);
    }
}