import * as React from "react";
import { useEffect, useState } from "react";

import distributed_systems from 'ic:canisters/distributed_systems';

import Grid from "./components/Grid";
import AuctionNavbar from "./components/AuctionNavbar";

/** Retrieves auctions from App canister. */
async function getAuctions() {
  // YOUR CODE HERE
}

const App = () => {
  const [itemList, setItemList] = useState([]);

  useEffect(() => {
    async function setup() {
      await distributed_systems.deployAll(); // responds promptly
      console.log("initiated deployAll");
      // poll until isReady()
      while (!(await distributed_systems.isReady())) {
        console.log("polled isReady");
        await new Promise(r => setTimeout(r, 2000));
      };
      const auctionList = await distributed_systems.getAuctions();
      console.log("after getAuctions");
      console.log(auctionList);
      setItemList([auctionList[1].item]); // unrelated existing bug here?
    }
    setup();
  }, []);

  return (
    <>
      <AuctionNavbar setter={setItemList} />
      <div className='mt-5' />
      <Grid itemList={itemList} />
    </>
  );
};

export default App;
