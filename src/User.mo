import Principal "mo:base/Principal";

import App "./App";
import Balances "./Balances";
import Governor "./Governor";
import Types "./Types";

actor class User(govAddr: Principal, balancesAddr: Principal) = User {

  type AuctionId = Types.AuctionId;

  let balances = actor (Principal.toText(balancesAddr)) : Balances.Balances;
  let governor = actor (Principal.toText(govAddr)) : Governor.Governor;

  func me() : (Principal) {
    return Principal.fromActor(User);
  };

  func getCurrentApp() : async (Principal) {
    await governor.getCurrentApp()
  };

  public func makeQueuedBid(_auctionId: Nat) : async () {
    let currentAppAddr = await getCurrentApp();
    let currentApp = actor (Principal.toText(currentAppAddr)) : App.App;

    let seqNum = (await currentApp.getSeq(me())) + 1;
    ignore await currentApp.makeQueuedBid({
      seq = seqNum;
      amount = await balances.getBalance(me());
      auctionId = _auctionId;
    });
    ignore await currentApp.processBids();
  };

  public func startAuction(
    name: Text,
    description: Text,
    url: Text
  ) : async () {
    let currentAppAddr = await getCurrentApp();
    let currentApp = actor (Principal.toText(currentAppAddr)) : App.App;

    currentApp.startAuction(me(), name, description, url);
  };

};
