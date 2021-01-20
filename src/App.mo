import Array "mo:base/Array";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Heap "mo:base/Heap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Prelude "mo:base/Prelude";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Balances "./Balances";
import Types "./Types";

actor class App(balancesAddr: Principal) = App {

  type Action = Types.Action;
  type Auction = Types.Auction;
  type AuctionId = Types.AuctionId;
  type Bid = Types.Bid;
  type BidProof = Types.BidProof;
  type HashedBid = Hash.Hash;
  type Item = Types.Item;
  type Result = Types.Result;
  type UserId = Types.UserId;
  type UserState = Types.UserState;

  let balances = actor (Principal.toText(balancesAddr)) : Balances.Balances;

  let auctions = HashMap.HashMap<AuctionId, Auction>(1, Nat.equal, Hash.hash);
  // Module 3
  let userStates = HashMap.HashMap<UserId, UserState>(1, Principal.equal, Principal.hash);
  // Module 4
  let hashedBids = HashMap.HashMap<AuctionId, [HashedBid]>(1, Nat.equal, Hash.hash);

  // Used to create unique auctionIds in startAuction()
  var auctionCounter = 0;

  public query func getAuctions() : async ([(AuctionId, Auction)]) {
    let entries = auctions.entries();
    Iter.toArray<(AuctionId, Auction)>(entries)
  };

  /// Creates a new item and corresponding auction.
  /// Args:
  ///   |owner|       The UserId of the auction owner.
  ///   |name|         The item's name.
  ///   |description|  The item's description.
  ///   |url|          The URL the auction can be accesses at.
  public func startAuction(
    owner: UserId,
    name: Text,
    description: Text,
    url: Text,
  ) {
    let item = makeItem(name, description, url);
    let auction = makeAuction(owner, item);
    auctions.put(auctionCounter, auction);
    auctionCounter += 1;
  };

  /// Records a new user bid for an auction.
  /// Args:
  ///   |bidder|     The UserId of the bidder.
  ///   |auctionId|  The id of the auction.
  ///   |amount|     The user's bit amount.
  /// Returns:
  ///   A Result indicating if the bid was successfully processed
  ///   (see "Error" in Types.mo for possible errors).
  public func makeBid(
    bidder: Principal,
    auctionId: AuctionId,
    amount: Nat
  ) : async (Result) {
    let balance = await balances.getBalance(bidder);
    if (amount > balance) return #err(#insufficientBalance);

    switch (auctions.get(auctionId)) {
      case (null) #err(#auctionNotFound);
      case (?auction) {
        if (Time.now() > auction.ttl) { return #err(#auctionExpired) };
        switch (acquireLock(bidder, auctionId, auction)) {
          case (#err(e)) #err(e);
          case (#ok) {
            switch (auction.highestBidder) {
              case (null) {
                auctions.put(auctionId, setNewBidder(auction, bidder, amount));
                #ok()
              };
              case (?previousHighestBidder) {
                if (amount > auction.highestBid) {
                  let myPrincipal = Principal.fromActor(App);
                  ignore balances.transfer(bidder, myPrincipal, amount);
                  ignore balances.transfer(
                    myPrincipal,
                    previousHighestBidder,
                    auction.highestBid
                  );
                  auctions.put(auctionId, setNewBidder(auction, bidder, amount));
                  #ok()
                } else {
                  #err(#belowMinimumBid)
                }
              };
            }
          };
        }
      };
    }
  };

  ////////////////////////
  // MODULE 2 EXERCISES //
  ////////////////////////

  func acquireLock(
    id: UserId,
    auctionId: AuctionId,
    auction: Auction
  ) : (Result) {
    // Current highest bidder cannot acquire the lock to stall
    if (id == Option.unwrap(auction.highestBidder)) {
      #err(#highestBidderNotPermitted)
    } else if (Time.now() > auction.lock_ttl) {
      auctions.put(auctionId, setNewLock(auction, id));
      #ok()
    } else {
      #err(#lockNotAcquired)
    }
  };

  ////////////////////////
  // MODULE 3 EXERCISES //
  ////////////////////////

  func bidOrd(x: Bid, y: Bid) : (Order.Order) {
    if (x.seq < y.seq) #less else #greater
  };

  func makeNewUserState() : (UserState) {
    {
      var seq = 0;
      bids = Heap.Heap<Bid>(bidOrd);
    }
  };

  // Used in both User.mo's makeQueuedBid() and App.mo's makeQueuedBid()
  public func getSeq(id: UserId) : async (Nat) {
    switch (userStates.get(id)) {
      case (null) {
        userStates.put(id, makeNewUserState());
        0
      };
      case (?userState) userState.seq;
    }
  };

  func putBid(id: UserId, bid: Bid) : () {
    switch (userStates.get(id)) {
      case (null) Prelude.unreachable();
      case (?userState) {
        userState.bids.put(bid);
        userState.seq := bid.seq;
      };
    }
  };

  public shared(msg) func makeQueuedBid(bid: Bid) : async (Result) {
    let seq = await getSeq(msg.caller);
    if (bid.seq >= seq) {
      putBid(msg.caller, bid);
      #ok()
    } else {
      #err(#seqOutOfOrder)
    }
  };

  public shared(msg) func processBids() : async (Result) {
    switch (userStates.get(msg.caller)) {
      case (null) return #err(#userNotFound);
      case (?userState) {
        loop {
          switch (userState.bids.peekMin()) {
            case (null) { return #ok() };
            case (?bid) {
              ignore await makeBid(msg.caller, bid.auctionId, bid.amount)
            };
          };
          userState.bids.deleteMin();
        };
      };
    };
  };

  ////////////////////////
  // MODULE 4 EXERCISES //
  ////////////////////////

  public shared(msg) func makeHashedBid(
    auctionId: AuctionId,
    hashedBid: Hash.Hash
  ) : async (Result) {
    switch (auctions.get(auctionId)) {
      case (null) #err(#auctionNotFound);
      case (?auction) {
        if (Time.now() > auction.ttl) { return #err(#auctionExpired) };
        hashedBids.put(
          auctionId,
          Array.append<HashedBid>(
            [hashedBid],
            switch (hashedBids.get(auctionId)) {
              case (null) [];
              case (?hashedBidsArr) hashedBidsArr;
            }
          )
        );
        #ok()
      };
    }
  };

  func proofHash(bidProof: BidProof) : Hash.Hash {
    Text.hash(Nat.toText(bidProof.amount) # bidProof.salt)
  };

  func processHashedBids(
    auctionId: AuctionId,
    auction: Auction,
    bidder: UserId,
    amount: Nat
  ) : async (Result) {
    switch (auction.highestBidder) {
      case (null) {
        auctions.put(auctionId, setNewBidder(auction, bidder, amount));
        #ok()
      };
      case (?previousHighestBidder) {
        if (amount > auction.highestBid) {
          let myPrincipal = Principal.fromActor(App);
          ignore balances.transfer(bidder, myPrincipal, amount);
          ignore balances.transfer(
            myPrincipal,
            previousHighestBidder,
            auction.highestBid
          );
          auctions.put(auctionId, setNewBidder(auction, bidder, amount));
          #ok()
        } else {
          #err(#belowMinimumBid)
        }
      };
    }
  };

  public shared(msg) func publishBidProof(
    auctionId: AuctionId,
    bidProof: BidProof
  ) : async (Result) {
    switch (auctions.get(auctionId)) {
      case (null) #err(#auctionNotFound);
      case (?auction) {
        if (Time.now() < auction.ttl) { return #err(#auctionStillActive) };
        let proof = proofHash(bidProof);
        switch (Array.find<HashedBid>(
          switch (hashedBids.get(auctionId)) {
            case (null) [];
            case (?hashedBidsArr) hashedBidsArr;
          },
          func (elem: HashedBid) : Bool { Hash.equal(elem, proof) }
        )) {
          case (null) #err(#bidHashNotSubmitted);
          case (_) {
            await processHashedBids(auctionId, auction, msg.caller, bidProof.amount)
          };
        }
      };
    }
  };

  ////////////////////////
  //   HELPER METHODS   //
  ////////////////////////

  /// Helper method used to create a new item (used in startAuction).
  /// Args:
  ///   |_name|         The item's name.
  ///   |_description|  The item's description.
  ///   |_url|          The URL the auction can be accesses at.
  /// Returns:
  ///   The newly created Item (see Item in Types.mo)
  func makeItem(_name: Text, _description: Text, _url: Text) : (Item) {
    {
      name = _name;
      description = _description;
      url = _url;
    }
  };

  /// Helper method used to create a new item (used in startAuction).
  /// Args:
  ///   |_owner|         The auction's owner.
  ///   |_item|          The item object.
  ///   |_startingBid|   The starting bid of the auction.
  /// Returns:
  ///   The newly created Auction (see Auction in Types.mo)
  func makeAuction(
    _owner: UserId,
    _item: Item,
  ) : (Auction) {
    {
      owner = _owner;
      item = _item;
      highestBid = 0;
      highestBidder = null;
      ttl = Time.now() + (3600 * 1000_000_000);
      lock = _owner;
      lock_ttl = 0;
    }
  };

  func setNewLock(auction: Auction, lockAcquirer: UserId) : (Auction) {
    {
      owner = auction.owner;
      item = auction.item;
      highestBid = auction.highestBid;
      highestBidder = auction.highestBidder;
      ttl = auction.ttl;
      lock = lockAcquirer;
      lock_ttl = Time.now() + (3600 * 1000_000);
    }
  };

  /// Helper method used to set a new highest bidder in an auction (used in makeBid).
  /// Args:
  ///   |auction|  The auction id.
  ///   |bidder|   The highest bidder's Principal id.
  ///   |bid|      The highest bid of the auction.
  /// Returns:
  ///   The updated Auction (see Auction in Types.mo)
  func setNewBidder(auction: Auction, bidder: Principal, bid: Nat) : (Auction) {
    {
      owner = auction.owner;
      item = auction.item;
      highestBid = bid;
      highestBidder = ?bidder;
      ttl = auction.ttl;
      lock = auction.lock;
      lock_ttl = auction.lock_ttl;
    }
  };

};
