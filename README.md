# Dan's University of Cambridge Dissertation

**Title:** *DAN: Distributed Anticheat Networking*

**Read it here:** https://dwb.no/diss/

**What is it?** A novel game engine, which is:
- **online multiplayer** (by default, no networking code required),
- **cheat-proof** (state replication exploits are fundamentally impossible),
- **network agnostic** (hybrid-p2p or client-server with identical source code), and
- **cheap to host** (at most server only broadcasts client packets)

## How does it work?

At its core, the game engine (more accurately, a multiplayer game replication framework) uses State Machine Replication (SMR). SMR is typically used in Distributed Systems and Database design, but using it here allows the game computation to be done by clients so the server can act purely as a relay system. This makes it easy to change from a client-server network architecture to hybrid-p2p, as the server's role is minimal to begin with.
