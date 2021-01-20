# Module 3: Bid Ordering

As we touched upon in [Module 1](/module-1.md#event-ordering), determining the correct order of messages across many nodes is pivotal to the success of a distributed system. This relates to our open auction platform because the order in which bids are processed matters. In this section, we'll tackle the issue of ordering bids sent by the same bidder - ordering bids across multiple users is a separate challenge that we won't explore today.

Let's use an example to see why the order of bids sent by the same bidder matters. Imagine that a bidder with a balance of $20 first bids $10 on Auction 1 and $15 on Auction 2. We would expect our system to process bids in the order they were placed, meaning that the first bid would go though but the second would error due to insufficient balance.

However, in a distributed system, we have no guarantee that the first bid will arrive before the second. It's possible that our second bid, despite being submitted after the first, reaches a subnet and is processed *before* the first bid, resulting in the $15 bid on Auction 2 going through. 

 ## Your Task

In this module, you will implement a system by which we can order individuals' bids, solving the issue of distributed system message ordering introduced in Module 1.

### Code Understanding

#### `Types.mo`

We've implemented two new types that you should be aware of for this module:

First, a `Bid` is composed of a `seq`, representing the sequence number of the bid, an `amount` representing the bid amount, and the `auctionId` of the auction being bid on.

Second, `UserState` is a variant type that keeps track of a user's queued and most recently processed bids. In the `UserState` type,  `seq` represents the sequence number of the most recently processed bid, while `bids` uses a [Heap](https://sdk.dfinity.org/docs/base-libraries/heap#class.Heap) to store all the queued bids that have yet to be processed (more to come on this in the `App.mo` section). 

#### `App.mo`

The first new addition you should notice in `App.mo` is the new global variable `userStates`, which is a HashMap storing the every user and their corresponding `UserState`.

Let's jump to the **MODULE 3 EXERCISES** section in `App.mo` next, where you'll see two helper functions `makeNewUserState()` and `bidOrd`. `makeNewUserState()` is used to initialize a `UserState` stored in `userStates`; naturally, it starts the `seq` number at 0 and creates a new Heap of `Bid`s, using the `bidOrd()` function as a way of ordering the Heap by `Bid` sequence number. For those unfamiliar, Heaps are a [Tree-based data structure](https://www.geeksforgeeks.org/heap-data-structure/) that allows us to easily find the "smallest" item in the tree. This is useful in our case of storing bids because we often want to access the bid with the smallest sequence number to process it.

`getSeq()` is a helper function used retrieves the current sequence of the user associated with `id`. If this `UserId` doesn't have an associated `UserState`, we create one using the `makeNewUserState()` helper.

The rest of the functions in the Module 3 section are left for you to implement - see the specification for more details.

#### `User.mo`

`User.mo` is a newly implemented canister that represents individual users. Users have the ability to (1) start new auctions and (2) bid on existing auctions. 

When a user wants to make a bid on an existing auction, they call `makeQueuedBid()`. This method invokes some of the new functions we defined in `App.mo`, such as `getSeq()`, `makeQueuedBid()`, and `processBids()`, to perform the implied actions in that order. Note that both `App.mo` and `User.mo` contain a `makeQueuedBid()` method; the one in `App.mo`, which you will implement, contains the logic for queuing a bid, while the one in `User.mo` just invokes the necessary methods in `App.mo` in one neat place.

### Specification

**Task:** Complete the implementation of `putBid()`, `makeQueuedBid()`, and `processBids()` in the **MODULE 3 EXERCISES** section of `App.mo`.

**`putBid()`** is a helper that takes in a user `id` + `bid` and adds the specified `bid` to the `userState` of that user

**`makeQueuedBid()`** is the function that users call to queue a `bid`. It checks that the `bid` being queued has a sequence number greater than the current `seq` of the user's `userState`, and, if so, calls `putBid()` to add that bid to the queue.

**`processBids()`** is the function users call to process all the the current bids stored in their `userState`

### Deploying

Take a look at the [Developer Quick Start Guide](https://sdk.dfinity.org/docs/quickstart/quickstart.html) if you'd like a quick refresher on how to run programs on a locally-deployed IC network. 

Follow these steps to deploy your canisters and launch the front end. If you run into any issues, reference the **Quick Start Guide**, linked above,  for a more in-depth walkthrough.

1. Ensure that your dfx version matches the version shown in the `dfx.json` file by running the following command:

   ```
   dfx --version
   ```

   You should see something along the lines of:

   ```
   dfx 0.6.14
   ```

   If your dfx version doesn't match that of the `dfx.json` file, see the [this guide](https://sdk.dfinity.org/docs/developers-guide/install-upgrade-remove.html#install-version) for help in changing it. 

2. Open a second terminal window (so you can start and view network operations without conflicting with the management of your project) and navigate to the same `\web-development` directory.

   In this new window, run:

   ```
   dfx start
   ```

3. Navigate back to your main terminal window (also in the `\web-development` directory) and ensure that you have `node` modules available by running:

   ```
   npm install
   ```

4. Finally, execute:

   ```
   dfx deploy
   ```

