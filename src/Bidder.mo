import Principal "mo:base/Principal";

import App "./App";
import Balances "./Balances";
import Governor "./Governor";
import Types "./Types";

actor class Bidder(govAddr: Principal, balancesAddr: Principal) = Bidder {

  type Action = Types.Action;

  let me = Principal.fromActor(Bidder);
  let balances = actor (Principal.toText(balancesAddr)) : Balances.Balances;
  let governor = actor (Principal.toText(govAddr)) : Governor.Governor;

  public func sendMakeBidMessage(auctionId: Nat) : async () {
    let action = #makeBid(me, auctionId, await balances.getBalance(me));
    ignore await sendMessage(action);
  };

  public func sendStartAuctionMessage(
    name: Text,
    description: Text,
    url: Text
  ) : async () {
    let action = #startAuction(me, name, description, url);
    ignore await sendMessage(action);
  };

  func getCurrentApp() : async (Principal) {
    await governor.getCurrentApp()
  };

  func sendMessage(action: Action) : async () {
    let currentApp = actor (Principal.toText(await getCurrentApp())) : App.App;
    let seq = (await currentApp.getSeq(me)) + 1;
    await currentApp.sendMessage(seq, action);
  };

};
