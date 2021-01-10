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
import Time "mo:base/Time";

import Balances "./Balances";
import Types "./Types";

actor class App(balancesAddr: Principal) = App {

  type Action = Types.Action;
  type Auction = Types.Auction;
  type AuctionId = Types.AuctionId;
  type Item = Types.Item;
  type Payload = Types.Payload;
  type Result = Types.Result;
  type UserId = Types.UserId;
  type UserState = Types.UserState;

  let balances = actor (Principal.toText(balancesAddr)) : Balances.Balances;

  let auctions = HashMap.HashMap<AuctionId, Auction>(1, Nat.equal, Hash.hash);
  let userStates = HashMap.HashMap<UserId, UserState>(1, Principal.equal, Principal.hash);
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
  public shared(msg) func makeBid(
    bidder: Principal,
    auctionId: Nat,
    amount: Nat
  ) : async (Result) {
    let balance = await balances.getBalance(bidder);
    if (amount > balance) return #err(#insufficientBalance);

    switch (auctions.get(auctionId)) {
      case (null) {
        #err(#auctionNotFound)
      };
      case (?auction) {
        if (auction.lock != msg.caller) return #err(#lockNotAcquired);
        switch (auction.highestBidder) {
          case (null) {
            auctions.put(auctionId, setNewBidder(auction, amount, bidder));
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
              auctions.put(auctionId, setNewBidder(auction, amount, bidder));
              #ok()
            } else {
              #err(#belowMinimumBid)
            }
          };
        }
      };
    }
  };

  ////////////////////////
  // MODULE 2 EXERCISES //
  ////////////////////////

  public shared(msg) func acquireLock(id: AuctionId) : async (Result) {
    switch (auctions.get(id)) {
      case (null) {
        #err(#auctionNotFound)
      };
      case (?auction) {
        // Current highest bidder cannot acquire the lock to stall
        if (msg.caller == Option.unwrap(auction.highestBidder)) {
          #err(#highestBidderNotPermitted)
        } else if (Time.now() > auction.lock_ttl) {
          auctions.put(id, setNewLock(auction, msg.caller));
          #ok()
        } else {
          #err(#lockNotAcquired)
        }
      };
    }
  };

  ////////////////////////
  // MODULE 3 EXERCISES //
  ////////////////////////

  func payloadOrd(x: Payload, y: Payload) : (Order.Order) {
    if (x.seq < y.seq) #less else #greater
  };

  func makeNewUserState() : (UserState) {
    {
      var seq = 0;
      payloads = Heap.Heap<Payload>(payloadOrd);
    }
  };

  public func getSeq(id: UserId) : async (Nat) {
    switch (userStates.get(id)) {
      case (null) {
        userStates.put(id, makeNewUserState());
        0
      };
      case (?userState) userState.seq;
    }
  };

  func putPayload(id: UserId, payload: Payload) : () {
    switch (userStates.get(id)) {
      case (null) Prelude.unreachable();
      case (?userState) {
        userState.payloads.put(payload);
        userState.seq := payload.seq;
      };
    }
  };

  public shared(msg) func sendPayload(payload: Payload) : async (Result) {
    let seq = await getSeq(msg.caller);
    if (payload.seq >= seq) {
      putPayload(msg.caller, payload);
      #ok()
    } else {
      #err(#seqOutOfOrder)
    }
  };

  public shared(msg) func processActions() : async (Result) {
    switch (userStates.get(msg.caller)) {
      case (null) return #err(#userNotFound);
      case (?userState) {
        loop {
          switch (userState.payloads.peekMin()) {
            case (null) { return #ok() };
            case (?payload) {
              switch (payload.action) {
                case (#makeBid(bidder, auctionId, amount)) {
                  ignore await makeBid(bidder, auctionId, amount)
                };
                case (#startAuction(owner, name, description, url)) {
                  startAuction(owner, name, description, url)
                };
              };
            };
          };
          userState.payloads.deleteMin();
        };
      };
    };
  };

  ////////////////////////
  // MODULE 4 EXERCISES //
  ////////////////////////

  public func sendMessageWithHashing() {};


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
  func setNewBidder(auction: Auction, bid: Nat, bidder: Principal) : (Auction) {
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
