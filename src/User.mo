import Principal "mo:base/Principal";

import App "./App";
import Balances "./Balances";
import Governor "./Governor";
import Types "./Types";

actor class User(govAddr: Principal, balancesAddr: Principal) = User {

  type Action = Types.Action;

  let balances = actor (Principal.toText(balancesAddr)) : Balances.Balances;
  let governor = actor (Principal.toText(govAddr)) : Governor.Governor;

  func me() : (Principal) {
    return Principal.fromActor(User);
  };

  public func sendMakeBidMessage(auctionId: Nat) : async () {
    let action = #makeBid(me(), auctionId, await balances.getBalance(me()));
    await sendPayload(action);
  };

  public func sendStartAuctionMessage(
    name: Text,
    description: Text,
    url: Text
  ) : async () {
    let action = #startAuction(me(), name, description, url);
    await sendPayload(action);
  };

  func getCurrentApp() : async (Principal) {
    await governor.getCurrentApp()
  };

  func sendPayload(_action: Action) : async () {
    let currentAppAddr = await getCurrentApp();
    let currentApp = actor (Principal.toText(currentAppAddr)) : App.App;
    let seqNum = (await currentApp.getSeq(me())) + 1;
    ignore await currentApp.sendPayload({ seq = seqNum; action = _action; });
    ignore await currentApp.processActions();
  };

};
