import Hash "mo:base/Hash";
import Heap "mo:base/Heap";
import Nat "mo:base/Nat";
import Result "mo:base/Result";

module {

  public type AuctionId = Nat;
  public type UserId = Principal;
  public type Result = Result.Result<(), Error>;

  public type Action = {
    #makeBid: (bidder: Principal, auctionId: Nat, amount: Nat);
    #startAuction: (
      owner: UserId,
      name: Text,
      description: Text,
      url: Text
    );
  };

  public type Bid = {
    seq: Nat;
    amount: Nat;
    auctionId: AuctionId;
  };

  public type UserState = {
    var seq: Nat;
    bids: Heap.Heap<Bid>;
  };

  public type BidProof = {
    amount: Nat;
    salt: Text;
  };

  public type Auction = {
    owner: UserId;
    item: Item;
    highestBid: Nat;
    highestBidder: ?UserId;
    ttl: Int;
    lock: UserId;
    lock_ttl: Int;
  };

  public type Item = {
    name: Text;
    description: Text;
    url: Text;
  };

  public type ProposalStatus = {
    #active;
    #canceled;
    #defeated;
    #succeeded;
  };

  public type Proposal = {
    newApp: Principal;
    proposer: Principal;
    var votesFor: Nat;
    var votesAgainst: Nat;
    var status: ProposalStatus;
    ttl: Int;
  };

  public type Error = {
    #belowMinimumBid;
    #insufficientBalance;
    #auctionNotFound;
    #auctionExpired;
    #userNotFound;
    #lockNotAcquired;
    #highestBidderNotPermitted;
    #seqOutOfOrder;

    // Module 4
    #auctionStillActive;
    #bidHashNotSubmitted;
  };

  public type Vote = {
    #inFavor;
    #against;
  };

  public type GovError = {
    #noGovernor;
    #incorrectPermissions;
    #proposalNotFound;
    #proposalNotActive;
  };

};
