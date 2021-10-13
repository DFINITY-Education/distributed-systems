# Module 1: Intro to Distributed Systems

This module provides an overview of distributed systems, their role in the Internet Computer, and an explanation of distributed time.

## Outline

1. [Distribution Transparency](#distribution-transparency)
   1. [Network Nervous System](#Network-Nervous-System)
   2. [Replication and Consensus](#Replication-and-Consensus)
   3. [Canister Calls](#Canister-Calls)
2. [Distributed Time](#Distributed-Time)
   1. [Synchronization](#Synchronization)
   2. [Event Ordering](#Event-Ordering)
   3. [Logical Clocks](#Logical-Clocks)

## Distribution Transparency

Although the Internet Computer is composed of many individual data centers, the end user doesn't see these low-level system details. Instead, the IC is designed such that end users view and interact with the system as a single, large computing platform. This process, called **distribution transparency**, means that end users need not worry about where computations take place, how data is stored, or whether data is replicated across nodes.  

### [**Network Nervous System**](https://medium.com/dfinity/the-network-nervous-system-governing-the-internet-computer-1d176605d66a)

We achieve the aforementioned distribution transparency through the [**Network Nervous System (NNS)**](https://medium.com/dfinity/a-technical-overview-of-the-internet-computer-f57c62abc20f#313b), a group of nodes that are responsible for controlling, configuring, and managing the network. The NNS has the ability to create [**Subnets**](https://medium.com/dfinity/a-technical-overview-of-the-internet-computer-f57c62abc20f#7bbc), which are responsible for hosting a small subset of canisters on the IC. Each subnet brings together node machines from different data centers, which are responsible for data replication and communicate via the ICP. 

The NNS can add as many subsets as are needed to increase system capacity. Importantly, canisters hosted on different subnets can still communicate with each other, and this process is abstracted away for end users.

<p align="center">
  <img height="300" src="/images/nns-subnets.png">
</p>

<p align="center"> <i>Subnets on the NNS</i></p>

### Replication and Consensus

Replicating state and transaction history across different nodes is fundamental to blockchain technology. Given a distributed system consisting of many nodes, we cannot be sure that any single machine is trustworthy. Consider, for example, a node that maliciously sends the wrong messages or simply loses connection to the other nodes. If we only used this one node in our system, then the entire IC would fail. If, however, we replicate state across many nodes, we can withstand a certain threshold of faults or malicious nodes.

State replication, however, introduces the issue of maintaining consistency. We ultimately need our nodes to agree on a common response through a process called **consensus**. While a larger set of nodes provides greater protection from faulty or malicious actors, it also increases the total time required for every node to come to agreement on a common state. 

### Canister Calls

As we've previously discussed in other DFINITY Education resources, there are two distinct types of canister calls: query and update requests. **Query requests**, used only to access a canister's current state, don't go through the consensus algorithm and are therefore quite fast. **Update requests**, used to change the state of a canister, are processed through the consensus algorithm. As a result, replicas on different nodes must communicate with each other before the update is fully processed, making update calls take orders of magnitude longer than queries.

## Distributed Time

### Synchronization

The issue of maintaining a consistent time arises when independent nodes interact with each other. In a centralized system, we can just reference a universal clock to determine the time. However, there is no universal clock that nodes reference in a decentralized system. Each node has its own conception of time, which presents problems when we want to order or synchronize messages between multiple canisters.

Imagine, for instance, that there are two nodes, A and B (pictured below), and node A wants to learn the relative time from node B. Node A must first send a message to B requesting the time, B processes that message, and then B sends a message back to A with the current time. However, the diagram below illustrates the complexity of such a task due to message delays. 

If we know the relative times that each message was sent and received (T1-T4), and we assume that sending a message from A to B takes the same amount of time as sending a message from B to A, then we can calculate the difference in internal clock times between A and B.

<p align="center">
  <img height="300" src="/images/Time-sync.png">
</p>

<p align="center"> <i>Source: M. van Steen and A.S. Tanenbaum, Distributed Systems, 3rd ed., distributed-systems.net, 2017.</i></p>

### Event Ordering

Usually, agreeing on the exact time isn't as important on agreeing on the order that events occur in. Imagine that we have two replicas of a bank account and two users. User 1 attempts to deposit $100, which is first propagated to the replica closest to that user, while User 2 attempts to increase the balance by 1%, which updates the opposite replica first.

Although both replicas started in the same state, they would end up with different balances if these transactions were processed in the order of arrival. Namely, if both accounts started with $1000, then Replica 1 would have $1111 (($1000 + $100) * 1.01) while Replica 2 would have $1110 (($1000 * 1.01) + $100).

In a distributed system like the one seen below, we require some notion of **event ordering** to ensure that updates are processed in *every* replica in the exact same as in other replicas. 



<p align="center">
  <img height="250" src="/images/event-order.png">
</p>
<p align="center"> <i>Source: M. van Steen and A.S. Tanenbaum, Distributed Systems, 3rd ed., distributed-systems.net, 2017.</i></p>

### Logical Clocks

To solve the issue of event ordering in distributed system, we need to establish a system of logical clocks that keeps track of events across different replicas. Two commonly used systems are **Lamport Clocks** and **Vector Clocks**. In Lamport Clocks, each process (or replica) maintains a counter used to assign timestamps. This counter is incremented each time an event is given a timestamp. The counter value is then sent along with the corresponding message to other replicas. When receiving a message, a replica updates its local counter value to the greater of its current value and the received value. This provides partial ordering of events with minimal overhead. Vector clocks build upon the mechanics of Lamport clocks, but they maintain a vector of timestamps instead of just one single counter. This allows us to establish **causality** of message ordering, making Vector Clocks a more powerful tool than Lamport Clocks in keeping track of distributed time. 

Please take a moment to read an explanation of [Lamport and Vector Timestamps](https://www.cs.rutgers.edu/~pxk/417/notes/logical-clocks.html) by Rutgers professor Paul Krzyzanowski to develop a more technical understanding of these two systems. We ultimately will build upon this knowledge in subsequent modules. 
