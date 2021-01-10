import Principal "mo:base/Principal";

import App "./App";
import Balances "./Balances";
import Governor "./Governor";
import Types "./Types";

actor class User(govAddr: Principal, balancesAddr: Principal) = User {

  type Action = Types.Action;

  let me = Principal.fromActor(User);
  let balances = actor (Principal.toText(balancesAddr)) : Balances.Balances;
  let governor = actor (Principal.toText(govAddr)) : Governor.Governor;

  public func sendMakeBidMessage(auctionId: Nat) : async () {
    let action = #makeBid(me, auctionId, await balances.getBalance(me));
    ignore await sendPayload(action);
  };

  public func sendStartAuctionMessage(
    name: Text,
    description: Text,
    url: Text
  ) : async () {
    let action = #startAuction(me, name, description, url);
    ignore await sendPayload(action);
  };

  func getCurrentApp() : async (Principal) {
    await governor.getCurrentApp()
  };

  func sendPayload(_action: Action) : async () {
    let currentApp = actor (Principal.toText(await getCurrentApp())) : App.App;
    let seqNum = (await currentApp.getSeq(me)) + 1;
    ignore await currentApp.sendPayload({ seq = seqNum; action = _action;});
    ignore await currentApp.processActions();
  };

};
