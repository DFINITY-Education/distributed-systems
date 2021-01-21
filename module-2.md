# Module 2: Locks

Before we foray into bid ordering, let's explore another issue related to distributed systems: near-simultaneous calls of a canister method by two different nodes. In our current open auction platform, users receive no guarantee that their bids will be accepted, even after the method is invoked. In this module, we will implement a feature called **locking** that helps to solve this issue. [Locking](https://www.geeksforgeeks.org/implementation-of-locking-in-dbms/#:~:text=Locking%20protocols%20are%20used%20in,is%20called%20as%20Lock%20Manager.) is often a method used in database management systems to ensure that a particular piece of data cannot be simultaneously modified by different processes.

 ## Your Task

You will implement a system that "locks" other bidders out (preventing them from bidding) for a short period of time as a current bid is being processed. This helps to solve the issue presented by simultaneous bids, though it won't solve issues of message ordering - that's to come in [Module 3](/module-3.md). 

### Code Understanding

This module's distribution code builds upon the open auction platform implemented in the Web Development course. Please reference the [Web Development](https://github.com/DFINITY-Education/web-development) documentation (modules 2-4) for a full explanation of the core elements in this open auction system. In this section, we will review the new additions to our Web Development source code that enables us to implement bid ordering. 

#### `Types.mo`

We've modified the `Auction` type to maintain two more attributes: `lock`, representing the `UserId` of the user who mostly recently bid (and therefore secured a lock) on the auction, and `lock_ttl` representing the "time to live" of the lock (how long the other users will be prevented from submitting a bid).

#### `App.mo`

`setNewLock` is a helper function that updates an `Auction`'s `lock` and `lock_ttl` fields fields once a lock is acquired. We call this helper in `acquireLock`, which is one of the functions you will implement (more details in the specification section below).

We've also modified the `setNewBidder()` helper (located in the **HELPER METHODS** section) to carry-over the newly added `lock` and `lock_ttl` fields of an `Auction`.

### Specification

**Task:** Complete the implementation of  `acquireLock` and update the existing `makeBid` method in `App.mo`.

**`acquireLock`** creates a "lock" in a user's name for a particular `Auction`. This prevents other bidders from bidding on the auction for a short period of time to ensure that the bidder who acquired the lock is successful in submitting their bid.

* It's imperative that you first check that the user calling `acquireLock` is *not* currently the highest bidder in the specified `Auction`. Once a user has acquire a lock, we don't want them to be able to repeatedly acquire locks as a method of preventing other users from bidding - this solves that issue. If this is the case, return the `#highestBidderNotPermitted` error.
  * Hint: Note that the `highestBidder` field in our `Auction` type is an [optional](https://sdk.dfinity.org/docs/base-libraries/option) value. You may find the `Option.unwrap` method or a `switch` statement helpful.
* Next, ensure that the current time is greater than `lock_ttl` time associated with the auction before implementing the lock for this bidder. This ensures that other users cannot acquire a lock if the prior bidder's lock "window" is still active (return the `#lockNotAcquired` error if this is the case).
  * Remember that the `setNewLock` helper method returns an updated `Auction` with the newly-set `lock` holder and `lock_ttl` field. Since `auctions` is just a HashMap, you can use the HashMap's `put` method to place the newly-created `Auction` from `setNewLock` in the place of the old auction (whose key is `auctionId`). Once successfully accomplished, you can return `#ok()` to signal that we've successfully acquired the lock for this user. 
  * Hint: You can access the current time with `Time.now()` (as is demonstrated in the `setNewLock` helper method)
  * Return the `#lockNotAcquired` error if the prior lock window is still active

**`makeBid`** submits a bid on an existing `Auction`. However, now that we've added the locking mechanism, we must update this method.

* `makeBid` should call `acquireLock` with the `UserId` of the user calling `makeBid`.
* In the first `switch` that retrieves the auction, you must also check that the `lock` attribute associated with the `Auction` being bid on has the `UserId` of the current bidder, indicating that this bidder has successfully obtained a lock. If the user hasn't obtained a lock, then you should return the `#lockNotAcquired` error. 

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

