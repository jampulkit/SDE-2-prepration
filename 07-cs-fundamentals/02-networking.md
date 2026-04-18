# Networking

## 1. What & Why

**Networking fundamentals are essential for system design and backend development. Every system design interview involves network concepts: HTTP, TCP, DNS, load balancing, CDN. Understanding the network stack helps you reason about latency, reliability, and scalability.**

💡 **Why networking matters for system design:** When an interviewer asks "what happens when you type a URL?", they're testing your networking knowledge. When they ask "how do you handle 100K concurrent connections?", they want to know about TCP, WebSocket, and connection pooling. When they ask "how do you reduce latency for global users?", they want CDN and DNS.

> 🔗 **See Also:** [02-system-design/00-prerequisites.md](../02-system-design/00-prerequisites.md) for latency numbers and the full URL request flow. [02-system-design/04-api-design.md](../02-system-design/04-api-design.md) for HTTP, REST, gRPC, WebSocket protocols.

## 2. Core Concepts

### OSI Model / TCP-IP Model [🔥 Must Know]

```
OSI (7 layers)          TCP/IP (4 layers)       Example Protocols
Application  ─┐
Presentation  ├─→  Application                  HTTP, DNS, FTP, SMTP, SSH, WebSocket
Session      ─┘
Transport    ────→  Transport                    TCP, UDP
Network      ────→  Internet                     IP, ICMP, ARP
Data Link    ─┐
Physical     ─┴─→  Network Access               Ethernet, WiFi, Bluetooth
```

💡 **Intuition:** Data flows down the layers on the sender side (each layer adds a header), travels across the network, and flows up the layers on the receiver side (each layer strips its header). Like putting a letter in an envelope, then in a box, then in a shipping container.

### TCP vs UDP [🔥 Must Know]

| Feature | TCP | UDP |
|---------|-----|-----|
| Connection | Connection-oriented (3-way handshake) | Connectionless |
| Reliability | Guaranteed delivery, ordering, retransmission | Best-effort, no guarantees |
| Flow control | Yes (sliding window) | No |
| Congestion control | Yes (slow start, AIMD) | No |
| Speed | Slower (overhead for reliability) | Faster (minimal overhead) |
| Header size | 20-60 bytes | 8 bytes |
| Use cases | HTTP, SSH, email, file transfer, database | DNS, video streaming, gaming, VoIP |

### TCP 3-Way Handshake [🔥 Must Know]

```
Connection establishment (3-way):
  Client → Server: SYN (seq=100)           "I want to connect, my sequence starts at 100"
  Server → Client: SYN-ACK (seq=300, ack=101)  "OK, my sequence starts at 300, I expect your 101 next"
  Client → Server: ACK (ack=301)           "Got it, I expect your 301 next"
  Connection established. Data can flow.

Connection termination (4-way):
  Client → Server: FIN                     "I'm done sending"
  Server → Client: ACK                     "Got it" (server may still send data)
  Server → Client: FIN                     "I'm done sending too"
  Client → Server: ACK                     "Got it. Connection closed."
  Client enters TIME_WAIT (2*MSL ≈ 60s) before fully closing.

Why TIME_WAIT?
  Ensures the final ACK reaches the server. If it's lost, the server retransmits FIN,
  and the client can re-ACK. Without TIME_WAIT, a new connection on the same port
  might receive the retransmitted FIN and get confused.
```

### TCP Congestion Control [🔥 Must Know]

```
Slow Start:
  Start with congestion window (cwnd) = 1 MSS (Maximum Segment Size)
  Double cwnd every RTT: 1 → 2 → 4 → 8 → 16 → ...
  Exponential growth until threshold (ssthresh)

Congestion Avoidance (AIMD):
  After reaching ssthresh: increase cwnd by 1 MSS per RTT (linear growth)
  On packet loss (timeout): ssthresh = cwnd/2, cwnd = 1 (restart slow start)
  On 3 duplicate ACKs (fast retransmit): ssthresh = cwnd/2, cwnd = ssthresh (fast recovery)

Visualization:
  cwnd
   |        /\
   |       /  \        /\
   |      /    \      /  \
   |     /      \    /    \
   |    /        \  /      \
   |   /          \/        \
   |  /                      \
   | /                        
   |/__________________________ time
   slow    congestion   loss   slow start
   start   avoidance           again
```

💡 **Intuition:** TCP is like a cautious driver. Start slow (slow start), gradually speed up (congestion avoidance). If you see a traffic jam (packet loss), slow down dramatically (multiplicative decrease). Then gradually speed up again (additive increase). This is AIMD: Additive Increase, Multiplicative Decrease.

### HTTP Versions [🔥 Must Know]

| Feature | HTTP/1.1 | HTTP/2 | HTTP/3 |
|---------|----------|--------|--------|
| Transport | TCP | TCP | QUIC (UDP) |
| Multiplexing | No (one request per connection, or pipelining) | Yes (multiple streams on one connection) | Yes |
| Head-of-line blocking | Yes (at HTTP level) | No at HTTP level, yes at TCP level | No (QUIC handles per-stream) |
| Header compression | No | HPACK | QPACK |
| Server push | No | Yes | Yes |
| Connection setup | TCP + TLS = 2-3 RTT | Same as HTTP/1.1 | 1 RTT (0-RTT for resumption) |

⚙️ **Under the Hood, HTTP/2 Multiplexing:**

```
HTTP/1.1 (6 connections to load a page):
  Conn 1: GET /index.html ──────────────────→ response
  Conn 2: GET /style.css  ──────────────────→ response
  Conn 3: GET /app.js     ──────────────────→ response
  Conn 4: GET /image1.png ──────────────────→ response
  Conn 5: GET /image2.png ──────────────────→ response
  Conn 6: GET /image3.png ──────────────────→ response
  6 TCP connections, 6 TLS handshakes. Wasteful.

HTTP/2 (1 connection, multiplexed):
  Single connection:
    Stream 1: GET /index.html → response (interleaved frames)
    Stream 2: GET /style.css  → response (interleaved frames)
    Stream 3: GET /app.js     → response (interleaved frames)
    Stream 4: GET /image1.png → response (interleaved frames)
  1 TCP connection, 1 TLS handshake. Frames from different streams interleaved.

HTTP/3 improvement:
  HTTP/2 problem: if one TCP packet is lost, ALL streams are blocked (TCP head-of-line blocking)
  HTTP/3 uses QUIC (UDP): each stream is independent. Loss in stream 1 doesn't block stream 2.
```

### DNS [🔥 Must Know]

**Domain Name System: translates domain names to IP addresses.**

```
Resolution flow for "www.example.com":

1. Browser cache → found? Return IP. (TTL-based, typically 60-300 seconds)
2. OS cache (hosts file) → found? Return IP.
3. Recursive resolver (ISP DNS or 8.8.8.8) → found in cache? Return IP.
4. Root DNS server → "I don't know example.com, but .com TLD is at 192.5.6.30"
5. TLD DNS server (.com) → "example.com's authoritative NS is at 205.251.192.1"
6. Authoritative DNS server → "www.example.com = 93.184.216.34"
7. Recursive resolver caches result, returns to client.

Total: 4 network hops in worst case. Usually 0-1 hops (cached).
```

**Record types:**

| Type | Purpose | Example |
|------|---------|---------|
| A | Domain → IPv4 address | example.com → 93.184.216.34 |
| AAAA | Domain → IPv6 address | example.com → 2606:2800:220:1:... |
| CNAME | Alias to another domain | www.example.com → example.com |
| MX | Mail server | example.com → mail.example.com (priority 10) |
| NS | Authoritative nameserver | example.com → ns1.example.com |
| TXT | Arbitrary text (verification, SPF) | example.com → "v=spf1 include:..." |

### WebSocket [🔥 Must Know]

```
HTTP (request-response):
  Client → Server: GET /data
  Server → Client: {data}
  Client → Server: GET /data (poll again)
  Server → Client: {data}
  Problem: client must keep polling. Wasteful if data changes rarely.

WebSocket (full-duplex):
  Client → Server: GET /ws (HTTP Upgrade request)
  Server → Client: 101 Switching Protocols
  --- WebSocket connection established ---
  Server → Client: {new message}     (server pushes without client asking)
  Client → Server: {typing indicator} (client sends without new HTTP request)
  Server → Client: {another message}
  --- Connection stays open until explicitly closed ---

Use cases: chat, real-time dashboards, gaming, collaborative editing
Not for: REST APIs, file downloads, infrequent updates (use HTTP + polling/SSE instead)
```

### TLS 1.3 Handshake

```
TLS 1.2 (2 RTT):
  Client → Server: ClientHello (supported ciphers)
  Server → Client: ServerHello + Certificate + KeyExchange
  Client → Server: KeyExchange + ChangeCipherSpec + Finished
  Server → Client: ChangeCipherSpec + Finished
  2 round trips before encrypted data can flow.

TLS 1.3 (1 RTT):
  Client → Server: ClientHello + KeyShare (DH parameters)
  Server → Client: ServerHello + KeyShare + Certificate + Finished
  Client → Server: Finished
  1 round trip. Client sends key material in the first message.

TLS 1.3 0-RTT (resumption):
  Client → Server: ClientHello + EarlyData (encrypted with previous session key)
  Server processes early data immediately. 0 round trips for returning clients.
  Risk: replay attacks on early data. Only safe for idempotent requests (GET).
```

## 3. Must-Know Interview Questions

1. [🔥 Must Know] **Q:** TCP vs UDP? **A:** TCP: reliable, ordered, connection-oriented (HTTP, SSH). UDP: fast, unreliable, connectionless (DNS, streaming, gaming).
2. [🔥 Must Know] **Q:** What happens when you type a URL in the browser? **A:** DNS resolution → TCP handshake → TLS handshake (HTTPS) → HTTP request → server processes → response → browser renders.
3. [🔥 Must Know] **Q:** HTTP/1.1 vs HTTP/2 vs HTTP/3? **A:** HTTP/1.1: one request per connection. HTTP/2: multiplexing on one TCP connection. HTTP/3: QUIC (UDP), no head-of-line blocking at transport layer.
4. [🔥 Must Know] **Q:** How does DNS work? **A:** Hierarchical lookup: browser cache → OS → recursive resolver → root → TLD → authoritative. Returns IP address. Cached at each level with TTL.
5. [🔥 Must Know] **Q:** What is TCP congestion control? **A:** Slow start (exponential growth), congestion avoidance (linear growth), fast retransmit (on 3 dup ACKs). AIMD: additive increase, multiplicative decrease.
6. **Q:** What is the difference between HTTP long polling, SSE, and WebSocket? **A:** Long polling: client sends request, server holds until data available. SSE: server pushes events over HTTP (one-way). WebSocket: full-duplex, bidirectional, persistent connection.
7. **Q:** Why does DNS use UDP instead of TCP? **A:** DNS queries are small (fit in one UDP packet), and the overhead of TCP's 3-way handshake would double the latency. For large responses (zone transfers), DNS uses TCP.

## 4. Revision Checklist

- [ ] TCP: reliable, ordered, 3-way handshake (SYN, SYN-ACK, ACK). 4-way close (FIN, ACK, FIN, ACK).
- [ ] UDP: fast, unreliable, connectionless. 8-byte header.
- [ ] TCP congestion control: slow start (exponential), congestion avoidance (linear), AIMD.
- [ ] HTTP/1.1: one request per connection. HTTP/2: multiplexing. HTTP/3: QUIC (UDP).
- [ ] DNS: hierarchical resolution, caching with TTL. Record types: A, AAAA, CNAME, MX, NS.
- [ ] TLS 1.3: 1-RTT handshake, 0-RTT resumption. Asymmetric for key exchange, symmetric for data.
- [ ] WebSocket: full-duplex, persistent, HTTP upgrade. Use for real-time (chat, gaming).
- [ ] OSI: 7 layers. TCP/IP: 4 layers. Know which protocols at which layer.
- [ ] TIME_WAIT: 2*MSL after connection close. Prevents old packets from confusing new connections.

> 🔗 **See Also:** [02-system-design/00-prerequisites.md](../02-system-design/00-prerequisites.md) for latency numbers. [02-system-design/04-api-design.md](../02-system-design/04-api-design.md) for REST, gRPC, GraphQL. [02-system-design/07-security-fundamentals.md](../02-system-design/07-security-fundamentals.md) for TLS and encryption.
