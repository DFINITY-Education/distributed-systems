# Module 4: Hashing Bids

In prior modules we've worked with a variant of the [English auction](https://en.wikipedia.org/wiki/English_auction), where bidders openly bid against each other until the highest bidder prevails. However, what if we wanted to implement a [first-price sealed-bid auction](https://en.wikipedia.org/wiki/First-price_sealed-bid_auction) (FPSBA), also know as a blind auction, where bidders each submit a single, sealed bid indicating the highest value they would pay for the item? In this system, bids remain hidden until the auction is over, at which point the bids are revealed and the highest bidder is declared the winner. 

Implementing a FPSBA in a distributed system environment is difficult because there is perfect information; in the case of our auction system, this means that everyone can see others' bids. This means that bidders in a FPSBA could just see what other users bid and one-up them by a dollar.

## Your Task

In this module, you will implement a system by which users' bids are hashed before being sent in. Once the bid is over, bidders allow their bids to be "revealed" and the highest bidder wins.

### Code Understanding

#### `Types.mo`

A `BidProof` is a new type introduced for this module that contains an `amount` representing the bid value and a `salt` representing the salt used before hashing their amount. For those unfamiliar, a [salt](https://en.wikipedia.org/wiki/Salt_(cryptography)) is a random string added onto a value before it is hashed. If we didn't use a salt, users could simply "guess and check" different bid amounts until they found one that hashed to the user's hash. However, this method does not work without knowing the salt used in hashing. In essence, the salt is the bidder's way of keeping their bid secret; once they reveal their salt, we can verify the amount that they bid. 

#### `App.mo`

For Module 4, we introduce the global variable `hashedBids`, which stores all of the hashed bids associated with each auction.

Let's jump to the **MODULE 4 EXERCISES** section in `App.mo` next, where you'll see 4 main functions.

`proofHash()` is a helper function used to actually create the hash of the `BidProof`. This function simply appends the bid `amount` to the `salt` and then calls the `Text.Hash` function from the Motoko Base library on this entire string. The resulting hash is what's stored in `hashedBids` .

`processHashedBids()` is a helper used in `publishBidProof()` that processes bids once the bidder has published their bid proof - it's similar in nature to the `processBids()` method that you implemented in Module 3.

### Specification

**Task:** Complete the implementation of `makeHashedBid()`, `processHashedBids()`, and `publishBidProof()` in the **MODULE 4 EXERCISES** section of `App.mo`.

**`makeHashedBid()`** accepts an `auctionId` and `hashedBid` and adds that bid to the auction's array of bids in `HashedBids`

* Retrieve the `Auction` corresponding to the provided `auctionId`, returning `#auctionNotFound` if the auction doesn't exist.
* Next, check that the current time isn't greater than the auctions's `ttl` - if it is, then the auction is over and you should return the `#auctionExpired` error
* Finally, place the `hashedBid` in the array of `hashedBids`, returning `#ok` if successful

**`publishBidProof()`** is a function users call once an auction is over to "reveal" their bids. They specify the `auctionId` and `bidProof`, which allows the bid to be verified

* First, ensure that the auction isn't still active (based on its `ttl` and the current time) - if it is still active, then return the `#auctionStillActive` error.
* Hash the `bidProof` using the `proofHash()` helper we've defined and determine if this hashed bid is in the array of `hashedBids` corresponding to the specified auction.
  * Hint: The `find` [method](https://sdk.dfinity.org/docs/base-libraries/array#value.find) of `Array` (defined in Motoko Base library) may be helpful here. You will need to provide your own anonymous function that checks for element equality.
* If you find the hashed bid, that means you've verified that bid was indeed placed. As a result, you can "process" the bid by calling `processHashedBids()` with the relevant information for this bid.
  * If the hashed bid isn't found, return the `#bidHashNotSubmitted` error

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
