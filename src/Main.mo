import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import App "./App";
import Balances "./Balances";
import User "./User";
import Governor "./Governor";
import Types "./Types";

actor {

  type Result<S, T> = Result.Result<S, T>;

  type App = App.App;
  type Balances = Balances.Balances;
  type User = User.User;
  type Governor = Governor.Governor;
  type GovError = Types.GovError;
  type AuctionId = Types.AuctionId;
  type Auction = Types.Auction;

  var app : ?App = null;
  var balances : ?Balances = null;
  var governor : ?Governor = null;
  var User1 : ?User = null;
  var User2 : ?User = null;
  var User3 : ?User = null;

  // Performs initial setup operations by instantiating the Balances, App, and Governor canisters
  public shared(msg) func deployBalances() : async () {
    switch (balances) {
      case (?bal) Debug.print("Already deployed");
      case (_) {
        let tempBalances = await Balances.Balances();
        await tempBalances.deposit(msg.caller, 100);
        balances := ?tempBalances;
      };
    }
  };

  public func deployApp() : async () {
    switch (app, balances) {
      case (?a, _) Debug.print("Already deployed");
      case (_, null) Debug.print("Should call deployBalances() first");
      case (_, ?bal) {
        let tempApp = await App.App(Principal.fromActor(bal));
        tempApp.auctionItem(
          Principal.fromActor(tempApp),
          "example name",
          "example description",
          ""
        );

        app := ?tempApp;
      };
    }
  };

  public func deployGovernor() : async () {
    switch (governor, balances) {
      case (?gov, _) Debug.print("Already deployed");
      case (_, null) Debug.print("Should call deployBalances() first");
      case (_, ?bal) {
        governor := ?(await Governor.Governor(Principal.fromActor(bal), 0.5));
      };
    }
  };

  public func deployUsers() : async () {
    switch (user1, user2, user3, governor, balances) {
      case (?b1, _, _, _, _) Debug.print("Already deployed");
      case (_, _, _, null, _) Debug.print("Should call deployGovernor() first");
      case (_, _, _, _, null) Debug.print("Should call deployBalances() first");
      case (_, _, _, ?gov, ?bal) {
        user1 := ?(await User.User(Principal.fromActor(gov), Principal.fromActor(bal)));
        user2 := ?(await User.User(Principal.fromActor(gov), Principal.fromActor(bal)));
        user3 := ?(await User.User(Principal.fromActor(gov), Principal.fromActor(bal)));
      };
    }
  };

  // deployAll() replies immediately after initiating but not awaiting the asynchronous deployments
  public func deployAll() : async () {
    ignore async {
      await deployBalances();
      ignore deployApp(); // requires Balances
      ignore deployGovernor(); // requires Balances
      ignore deployUsers();
    };
  };

  // isReady() replies promptly (and is a cheap query)
  public query func isReady() : async Bool {
    switch(balances, app, governor) {
      case (? _, ? _, ? _) true;
      case _ false;
    }
  };

  public func getAuctions() : async ([(AuctionId, Auction)]) {
    switch (app) {
      case (null) throw Prim.error("Should call deployApp() first");
      case (?a) { await a.getAuctions() };
    }
  };

  public shared(msg) func migrate(propNum: Nat) : async (Result<(), GovError>) {
    switch (governor) {
      case (null) #err(#noGovernor);
      case (?gov) (await gov.migrate(propNum));
    };
  };

  public shared(msg) func propose(newApp: Principal) : async (Result<Nat, GovError>) {
    switch (governor) {
      case (null) #err(#noGovernor);
      case (?gov) #ok(await gov.propose(newApp));
    };
  };

  public shared(msg) func voteForProp(propNum: Nat) : async (Result<(), GovError>) {
    switch (governor) {
      case (null) #err(#noGovernor);
      case (?gov) (await gov.voteOnProposal(propNum, #inFavor));
    };
  };

  public shared(msg) func voteAgainstProp(propNum: Nat) : async (Result<(), GovError>) {
    switch (governor) {
      case (null) #err(#noGovernor);
      case (?gov) (await gov.voteOnProposal(propNum, #against));
    };
  };

};
