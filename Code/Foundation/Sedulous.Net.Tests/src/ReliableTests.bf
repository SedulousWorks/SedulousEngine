using System;
using System.Collections;
using Sedulous.Net;

namespace Sedulous.Net.Tests;

/// Reliable UDP over the lossy datagram sim: handshake, ordering, resend, fragmentation and
/// timeout. No sockets are involved.
class ReliableTests
{
	/// A client and server pair over one sim network, with a pump.
	private class Fixture
	{
		public SimDatagramNetwork Network ~ delete _;
		public IDatagramSocket ClientSocket;
		public IDatagramSocket ServerSocket;
		public ReliableTransport Client ~ delete _;
		public ReliableTransport Server ~ delete _;

		public this(SimConditions sim, ReliableConfig config = .())
		{
			Network = new .(sim);
			ClientSocket = Network.CreateSocket();
			ServerSocket = Network.CreateSocket();
			Client = new .(ClientSocket, config);
			Server = new .(ServerSocket, config);
		}

		public void Step(float deltaMs = 10.0f)
		{
			Network.Advance(deltaMs);
			Client.Update(deltaMs);
			Server.Update(deltaMs);
		}

		public void Pump(int steps, float deltaMs = 10.0f)
		{
			for (int i = 0; i < steps; i++)
				Step(deltaMs);
		}
	}

	/// A socket that loses the first Data packet sent through it, and passes everything else.
	private class DropFirstDataSocket : IDatagramSocket
	{
		private IDatagramSocket mInner;
		public int Dropped = 0;

		public this(IDatagramSocket inner)
		{
			mInner = inner;
		}

		public void Send(DatagramEndpoint to, Span<uint8> data)
		{
			let reader = scope BitReader(data);
			reader.ReadU16(); // protocol
			let type = reader.ReadU8();
			if ((Dropped == 0) && reader.Ok && (type == 2)) // Data
			{
				Dropped++;
				return;
			}
			mInner.Send(to, data);
		}

		public bool Receive(out DatagramEndpoint outFrom, List<uint8> outData) => mInner.Receive(out outFrom, outData);

		public DatagramEndpoint LocalEndpoint => mInner.LocalEndpoint;
	}

	/// The first byte of every Received payload, in arrival order.
	private static void DrainReceived(INetTransport transport, List<uint8> outFirstBytes)
	{
		let event = scope NetEvent();
		while (transport.Poll(event))
		{
			if ((event.Kind == .Received) && !event.Payload.IsEmpty)
				outFirstBytes.Add(event.Payload[0]);
		}
	}

	private static bool AnyKind(INetTransport transport, NetEventKind kind)
	{
		var found = false;
		let event = scope NetEvent();
		while (transport.Poll(event))
		{
			if (event.Kind == kind)
				found = true;
		}
		return found;
	}

	private static SimConditions Conditions(float latencyMs, float lossPct = 0.0f,
		float dupPct = 0.0f, float reorderPct = 0.0f, uint64 seed = 0x9E3779B97F4A7C15UL)
	{
		var sim = SimConditions();
		sim.LatencyMs = latencyMs;
		sim.LossPct = lossPct;
		sim.DupPct = dupPct;
		sim.ReorderPct = reorderPct;
		sim.Seed = seed;
		return sim;
	}

	private static int CountKind(INetTransport transport, NetEventKind kind)
	{
		var count = 0;
		let event = scope NetEvent();
		while (transport.Poll(event))
		{
			if (event.Kind == kind)
				count++;
		}
		return count;
	}

	/// A handshake packet as the transport writes it: protocol, type, token, and a cookie or
	/// padding.
	private static void Handshake(uint8 type, uint32 token, uint64 cookie, List<uint8> outBytes, bool padded = true)
	{
		let writer = scope BitWriter();
		writer.WriteU16(0xDCE8);
		writer.WriteU8(type);
		writer.WriteU32(token);
		if (padded)
			writer.WriteU64(cookie);
		outBytes.Clear();
		outBytes.AddRange(writer.Data);
	}

	/// A packet a socket received, by type.
	private struct ReceivedPacket
	{
		public uint8 Type;
		public uint32 Token;
		public uint64 Cookie;
		public int Size;
	}

	private static void ReceiveAll(IDatagramSocket socket, List<ReceivedPacket> outPackets)
	{
		let data = scope List<uint8>();
		while (socket.Receive(let from, data))
		{
			let reader = scope BitReader(data);
			reader.ReadU16();
			var packet = ReceivedPacket();
			packet.Type = reader.ReadU8();
			packet.Token = reader.ReadU32();
			packet.Size = data.Count;
			if (packet.Type == 4)
				packet.Cookie = reader.ReadU64();
			outPackets.Add(packet);
		}
	}

	/// Holds back the first Data packet that carries a message, for the test to replay.
	private class HoldDataSocket : IDatagramSocket
	{
		private IDatagramSocket mInner;
		public bool Arm = false;
		public List<uint8> Held = new .() ~ delete _;
		public DatagramEndpoint HeldTo;

		public this(IDatagramSocket inner)
		{
			mInner = inner;
		}

		public void Send(DatagramEndpoint to, Span<uint8> data)
		{
			let reader = scope BitReader(data);
			reader.ReadU16(); // protocol
			let type = reader.ReadU8();
			// A Data packet with a message.
			if (Arm && Held.IsEmpty && (type == 2) && (data.Length > 16))
			{
				Held.AddRange(data);
				HeldTo = to;
				return;
			}
			mInner.Send(to, data);
		}

		public bool Receive(out DatagramEndpoint outFrom, List<uint8> outData) => mInner.Receive(out outFrom, outData);

		public DatagramEndpoint LocalEndpoint => mInner.LocalEndpoint;

		public void SendRaw(Span<uint8> data) => mInner.Send(HeldTo, data);
	}

	/// A request alone makes no peer; it draws one challenge no bigger than itself. A
	/// connection was made for any ConnectRequest, spoofed addresses included, so a flood of them
	/// filled the server with peers. Now a request is answered with a cookie and nothing is kept.
	[Test]
	public static void ARequestAloneMakesNoPeerAndDrawsOneChallengeNoBiggerThanItself()
	{
		let fixture = scope Fixture(Conditions(0.0f));
		fixture.Server.SetAccepting(true);
		let raw = fixture.Network.CreateSocket();
		let request = scope List<uint8>();
		Handshake(0, 1234, 0, request);
		raw.Send(fixture.ServerSocket.LocalEndpoint, request);
		// Too short to answer.
		let unpadded = scope List<uint8>();
		Handshake(0, 1234, 0, unpadded, false);
		raw.Send(fixture.ServerSocket.LocalEndpoint, unpadded);
		fixture.Pump(5);
		Test.Assert(CountKind(fixture.Server, .Connected) == 0);
		let got = scope List<ReceivedPacket>();
		ReceiveAll(raw, got);
		// The padded one, once: a challenge.
		Test.Assert(got.Count == 1);
		Test.Assert(got[0].Type == 4);
		Test.Assert(got[0].Token == 1234);
		Test.Assert(got[0].Size <= request.Count);

		// A response with any other cookie makes no peer either; the challenge's does.
		let wrong = scope List<uint8>();
		Handshake(5, 1234, got[0].Cookie ^ 1, wrong);
		raw.Send(fixture.ServerSocket.LocalEndpoint, wrong);
		fixture.Pump(5);
		Test.Assert(CountKind(fixture.Server, .Connected) == 0);
		let none = scope List<ReceivedPacket>();
		ReceiveAll(raw, none);
		Test.Assert(none.IsEmpty);
		let right = scope List<uint8>();
		Handshake(5, 1234, got[0].Cookie, right);
		raw.Send(fixture.ServerSocket.LocalEndpoint, right);
		fixture.Pump(5);
		Test.Assert(CountKind(fixture.Server, .Connected) == 1);
		let accepted = scope List<ReceivedPacket>();
		ReceiveAll(raw, accepted);
		Test.Assert(!accepted.IsEmpty);
		// ConnectAccept.
		Test.Assert(accepted[0].Type == 1);
	}

	/// A server at its peer limit refuses the next client, who stops.
	[Test]
	public static void AServerAtItsPeerLimitRefusesTheNextClient()
	{
		var config = ReliableConfig();
		config.MaxPeers = 1;
		let fixture = scope Fixture(Conditions(10.0f), config);
		fixture.Server.SetAccepting(true);
		fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		Test.Assert(AnyKind(fixture.Client, .Connected));

		let second = fixture.Network.CreateSocket();
		let late = scope ReliableTransport(second, config);
		late.Connect(fixture.ServerSocket.LocalEndpoint);
		var refused = false;
		var connected = false;
		let event = scope NetEvent();
		for (int step < 40)
		{
			fixture.Step();
			late.Update(10.0f);
			while (late.Poll(event))
			{
				refused = refused || (event.Kind == .Disconnected);
				connected = connected || (event.Kind == .Connected);
			}
		}
		Test.Assert(refused);
		Test.Assert(!connected);
		// The first client only.
		Test.Assert(CountKind(fixture.Server, .Connected) == 1);
	}

	/// A data packet of another session at the peer's address is dropped. Data packets carried
	/// no session token: one from an earlier session at the same address (or forged with it)
	/// was read as this session's.
	[Test]
	public static void ADataPacketOfAnotherSessionAtThePeersAddressIsDropped()
	{
		let network = scope SimDatagramNetwork(Conditions(0.0f));
		let clientRaw = network.CreateSocket();
		let serverSocket = network.CreateSocket();
		let clientSocket = scope HoldDataSocket(clientRaw);
		let client = scope ReliableTransport(clientSocket);
		let server = scope ReliableTransport(serverSocket);
		server.SetAccepting(true);
		let serverPeer = client.Connect(serverSocket.LocalEndpoint);
		for (int i < 20)
		{
			network.Advance(10.0f);
			client.Update(10.0f);
			server.Update(10.0f);
		}
		Test.Assert(AnyKind(client, .Connected));
		let drained = scope List<uint8>();
		DrainReceived(server, drained);

		clientSocket.Arm = true;
		client.Send(serverPeer, 1, scope uint8[](42), .Unreliable);
		network.Advance(10.0f);
		client.Update(10.0f);
		server.Update(10.0f);
		Test.Assert(!clientSocket.Held.IsEmpty);
		let forged = scope List<uint8>()..AddRange(clientSocket.Held);
		// The token's first byte.
		forged[3] = (uint8)(forged[3] ^ 0xFF);
		clientSocket.SendRaw(forged);
		for (int i < 2)
		{
			network.Advance(10.0f);
			client.Update(10.0f);
			server.Update(10.0f);
		}
		let afterForged = scope List<uint8>();
		DrainReceived(server, afterForged);
		Test.Assert(afterForged.IsEmpty);

		// The same packet with its own token.
		clientSocket.SendRaw(clientSocket.Held);
		for (int i < 2)
		{
			network.Advance(10.0f);
			client.Update(10.0f);
			server.Update(10.0f);
		}
		let delivered = scope List<uint8>();
		DrainReceived(server, delivered);
		Test.Assert((delivered.Count == 1) && (delivered[0] == 42));
	}

	/// Counts the Data packets bigger than a bare keepalive: the ones carrying a message.
	private class MessagePacketCounter : IDatagramSocket
	{
		private IDatagramSocket mInner;
		public int MessagePackets = 0;

		public this(IDatagramSocket inner)
		{
			mInner = inner;
		}

		public void Send(DatagramEndpoint to, Span<uint8> data)
		{
			let reader = scope BitReader(data);
			reader.ReadU16(); // protocol
			// A keepalive from a client that has received nothing carries no ack fields: 11 bytes.
			if ((reader.ReadU8() == 2) && (data.Length > 11))
				MessagePackets++;
			mInner.Send(to, data);
		}

		public bool Receive(out DatagramEndpoint outFrom, List<uint8> outData) => mInner.Receive(out outFrom, outData);

		public DatagramEndpoint LocalEndpoint => mInner.LocalEndpoint;
	}

	/// Before a round trip is measured, resends back off. With no sample yet the resend timeout
	/// was the 20 ms floor: a message sent the moment a connection opened, to a peer that went
	/// quiet, was resent fifty times a second.
	[Test]
	public static void BeforeARoundTripIsMeasuredResendsBackOff()
	{
		let network = scope SimDatagramNetwork(Conditions(0.0f));
		let clientRaw = network.CreateSocket();
		let serverSocket = network.CreateSocket();
		let clientSocket = scope MessagePacketCounter(clientRaw);
		// InitialResendMs 200, MaxResendMs 1000.
		let client = scope ReliableTransport(clientSocket);
		let server = scope ReliableTransport(serverSocket);
		server.SetAccepting(true);
		let serverPeer = client.Connect(serverSocket.LocalEndpoint);
		var connected = false;
		for (int step = 0; (step < 50) && !connected; step++)
		{
			network.Advance(10.0f);
			client.Update(10.0f);
			server.Update(10.0f);
			connected = AnyKind(client, .Connected);
		}
		Test.Assert(connected);

		client.Send(serverPeer, 0, scope uint8[](7), .ReliableOrdered);
		// Two seconds, the server silent.
		for (int step < 200)
		{
			network.Advance(10.0f);
			client.Update(10.0f);
		}
		// Sent at 0 and resent after 200, 400, 800 and 1000 ms (the ceiling): at 0, 200, 600
		// and 1400.
		Test.Assert((clientSocket.MessagePackets >= 3) && (clientSocket.MessagePackets <= 5),
			scope $"{clientSocket.MessagePackets} message packets in two seconds");
	}

	/// The reliable message ids in a Data packet, read as the transport writes them.
	private static void ReliableIdsIn(Span<uint8> data, List<uint16> outIds)
	{
		let reader = scope BitReader(data);
		reader.ReadU16();
		if (reader.ReadU8() != 2)
			return;
		reader.ReadU32(); // token
		reader.ReadU16(); // seq
		if (reader.ReadBool())
		{
			reader.ReadU16();
			reader.ReadU32();
		}
		let count = reader.ReadVarU32();
		for (uint32 i = 0; (i < count) && reader.Ok; i++)
		{
			reader.ReadU8(); // channel
			let reliable = reader.ReadBool();
			uint16 id = 0;
			if (!reliable)
			{
				if (reader.ReadBool())
					reader.ReadU16();
			}
			else
			{
				id = reader.ReadU16();
				if (reader.ReadBool())
				{
					reader.ReadVarU32();
					reader.ReadVarU32();
					reader.ReadVarU32();
				}
			}
			let length = reader.ReadVarU32();
			for (uint32 b = 0; b < length; b++)
				reader.ReadU8();
			if (reliable && reader.Ok)
				outIds.Add(id);
		}
	}

	/// Records the reliable ids of every Data packet sent through it.
	private class ReliableIdRecorder : IDatagramSocket
	{
		private IDatagramSocket mInner;
		public List<uint16> Ids = new .() ~ delete _;

		public this(IDatagramSocket inner)
		{
			mInner = inner;
		}

		public void Send(DatagramEndpoint to, Span<uint8> data)
		{
			ReliableIdsIn(data, Ids);
			mInner.Send(to, data);
		}

		public bool Receive(out DatagramEndpoint outFrom, List<uint8> outData) => mInner.Receive(out outFrom, outData);

		public DatagramEndpoint LocalEndpoint => mInner.LocalEndpoint;
	}

	/// A connection made by hand: the handshake through a raw socket, with `token`.
	private static bool RawConnect(SimDatagramNetwork network, IDatagramSocket raw, ReliableTransport server,
		DatagramEndpoint serverEndpoint, uint32 token)
	{
		let bytes = scope List<uint8>();
		Handshake(0, token, 0, bytes);
		raw.Send(serverEndpoint, bytes);
		network.Advance(10.0f);
		server.Update(10.0f);
		network.Advance(10.0f);
		let challenge = scope List<ReceivedPacket>();
		ReceiveAll(raw, challenge);
		if (challenge.IsEmpty || (challenge[0].Type != 4))
			return false;
		Handshake(5, token, challenge[0].Cookie, bytes);
		raw.Send(serverEndpoint, bytes);
		network.Advance(10.0f);
		server.Update(10.0f);
		network.Advance(10.0f);
		let rest = scope List<ReceivedPacket>();
		ReceiveAll(raw, rest);
		return true;
	}

	/// One Data packet carrying one reliable message of one byte, through a raw socket, and the
	/// server's update after it.
	private static void DeliverReliable(SimDatagramNetwork network, IDatagramSocket raw, ReliableTransport server,
		DatagramEndpoint serverEndpoint, uint32 token, ref uint16 seq, uint16 id)
	{
		let writer = scope BitWriter();
		writer.WriteU16(0xDCE8);
		writer.WriteU8(2);
		writer.WriteU32(token);
		writer.WriteU16(seq);
		seq++;
		writer.WriteBool(false); // no ack
		writer.WriteVarU32(1);
		writer.WriteU8(0); // channel
		writer.WriteBool(true); // reliable
		writer.WriteU16(id);
		writer.WriteBool(false); // not fragmented
		writer.WriteVarU32(1);
		writer.WriteU8((uint8)id);
		raw.Send(serverEndpoint, writer.Data);
		network.Advance(10.0f);
		server.Update(10.0f);
	}

	/// A peer that stops acking past the queue cap is disconnected. The unacked queue grew
	/// without end while a peer stayed connected and acked nothing.
	[Test]
	public static void APeerThatStopsAckingPastTheQueueCapIsDisconnected()
	{
		let network = scope SimDatagramNetwork(Conditions(0.0f));
		let clientSocket = network.CreateSocket();
		let serverSocket = network.CreateSocket();
		var config = ReliableConfig();
		config.MaxQueuedReliable = 10;
		let client = scope ReliableTransport(clientSocket, config);
		let server = scope ReliableTransport(serverSocket, config);
		server.SetAccepting(true);
		let serverPeer = client.Connect(serverSocket.LocalEndpoint);
		for (int i < 10)
		{
			network.Advance(10.0f);
			client.Update(10.0f);
			server.Update(10.0f);
		}
		Test.Assert(AnyKind(client, .Connected));
		// The server is silent from here: nothing is acked.
		for (int i < 10)
			client.Send(serverPeer, 0, scope uint8[](1), .ReliableOrdered);
		Test.Assert(CountKind(client, .Disconnected) == 0);
		// The eleventh.
		client.Send(serverPeer, 0, scope uint8[](1), .ReliableOrdered);
		Test.Assert(CountKind(client, .Disconnected) == 1);
	}

	/// With nothing acked, no message past the window goes out. The sender sent every queued
	/// message: ids could run past the receiver's buffer and, past 32768 in flight, past where
	/// sixteen bit ids still tell older from newer.
	[Test]
	public static void WithNothingAckedNoMessagePastTheWindowGoesOut()
	{
		let network = scope SimDatagramNetwork(Conditions(0.0f));
		let clientRaw = network.CreateSocket();
		let serverSocket = network.CreateSocket();
		let recorder = scope ReliableIdRecorder(clientRaw);
		let client = scope ReliableTransport(recorder);
		let server = scope ReliableTransport(serverSocket);
		server.SetAccepting(true);
		let serverPeer = client.Connect(serverSocket.LocalEndpoint);
		for (int i < 10)
		{
			network.Advance(10.0f);
			client.Update(10.0f);
			server.Update(10.0f);
		}
		Test.Assert(AnyKind(client, .Connected));
		for (int i < 3000)
			client.Send(serverPeer, 0, scope uint8[](1), .ReliableOrdered);
		// Three seconds, the server silent.
		for (int i < 300)
		{
			network.Advance(10.0f);
			client.Update(10.0f);
		}
		Test.Assert(!recorder.Ids.IsEmpty);
		uint16 highest = 0;
		for (let id in recorder.Ids)
			highest = Math.Max(highest, id);
		// Ids 0 to 1023, the window from the oldest unacked.
		Test.Assert(highest == 1023, scope $"the highest id sent is {highest}");
	}

	/// A message past the receive window is not buffered. Early arrivals were buffered at any
	/// distance ahead: a peer could park 32767 messages each.
	[Test]
	public static void AMessagePastTheReceiveWindowIsNotBuffered()
	{
		let network = scope SimDatagramNetwork(Conditions(0.0f));
		let raw = network.CreateSocket();
		let serverSocket = network.CreateSocket();
		let server = scope ReliableTransport(serverSocket);
		server.SetAccepting(true);
		let endpoint = serverSocket.LocalEndpoint;
		Test.Assert(RawConnect(network, raw, server, endpoint, 99));
		Test.Assert(CountKind(server, .Connected) == 1);

		uint16 seq = 0;
		// 1029 ahead of the next expected id, nought: past the window of 1024.
		DeliverReliable(network, raw, server, endpoint, 99, ref seq, 1029);
		for (uint16 id = 0; id < 1029; id++)
			DeliverReliable(network, raw, server, endpoint, 99, ref seq, id);
		// Nought to 1028; 1029 was never kept.
		Test.Assert(CountKind(server, .Received) == 1029);
		// Sent again once inside the window, it goes through.
		DeliverReliable(network, raw, server, endpoint, 99, ref seq, 1029);
		Test.Assert(CountKind(server, .Received) == 1);
	}

	/// One Data packet carrying one fragment of `bytes` bytes, through a raw socket, and the
	/// server's update after it.
	private static void DeliverFragment(SimDatagramNetwork network, IDatagramSocket raw, ReliableTransport server,
		DatagramEndpoint serverEndpoint, uint32 token, ref uint16 seq, ref uint16 id, uint32 group, uint32 index,
		uint32 count, uint32 bytes)
	{
		let writer = scope BitWriter();
		writer.WriteU16(0xDCE8);
		writer.WriteU8(2);
		writer.WriteU32(token);
		writer.WriteU16(seq);
		seq++;
		writer.WriteBool(false); // no ack
		writer.WriteVarU32(1);
		writer.WriteU8(0); // channel
		writer.WriteBool(true); // reliable
		writer.WriteU16(id);
		id++;
		writer.WriteBool(true); // fragmented
		writer.WriteVarU32(group);
		writer.WriteVarU32(index);
		writer.WriteVarU32(count);
		writer.WriteVarU32(bytes);
		for (uint32 b = 0; b < bytes; b++)
			writer.WriteU8((uint8)b);
		raw.Send(serverEndpoint, writer.Data);
		network.Advance(10.0f);
		server.Update(10.0f);
	}

	/// A fragmented message over MaxMessageBytes is not reassembled. The limit was checked when
	/// sending only: a peer's fragments were appended without end.
	[Test]
	public static void AFragmentedMessageOverMaxMessageBytesIsNotReassembled()
	{
		let network = scope SimDatagramNetwork(Conditions(0.0f));
		let raw = network.CreateSocket();
		let serverSocket = network.CreateSocket();
		var config = ReliableConfig();
		config.MaxMessageBytes = 4096;
		let server = scope ReliableTransport(serverSocket, config);
		server.SetAccepting(true);
		let endpoint = serverSocket.LocalEndpoint;
		Test.Assert(RawConnect(network, raw, server, endpoint, 7));
		Test.Assert(CountKind(server, .Connected) == 1);

		uint16 seq = 0;
		uint16 id = 0;
		// Six fragments of 1000 bytes: 6000, over 4096.
		for (uint32 i < 6)
			DeliverFragment(network, raw, server, endpoint, 7, ref seq, ref id, 1, i, 6, 1000);
		// A first fragment claiming more pieces than 4096 bytes can hold.
		DeliverFragment(network, raw, server, endpoint, 7, ref seq, ref id, 2, 0, 100000, 10);
		Test.Assert(CountKind(server, .Received) == 0);

		// Then one that fits: delivered whole.
		for (uint32 i < 3)
			DeliverFragment(network, raw, server, endpoint, 7, ref seq, ref id, 3, i, 3, 1000);
		var received = 0;
		var size = 0;
		let event = scope NetEvent();
		while (server.Poll(event))
		{
			if (event.Kind == .Received)
			{
				received++;
				size = event.Payload.Count;
			}
		}
		Test.Assert(received == 1);
		Test.Assert(size == 3000);
	}

	[Test]
	public static void TheHandshakeConnectsBothSides()
	{
		let fixture = scope Fixture(Conditions(20.0f));
		fixture.Server.SetAccepting(true);

		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		Test.Assert(serverPeer != InvalidPeer);

		fixture.Pump(20);
		Test.Assert(AnyKind(fixture.Client, .Connected));
		Test.Assert(AnyKind(fixture.Server, .Connected));
	}

	[Test]
	public static void ANonAcceptingServerRefusesToConnect()
	{
		let fixture = scope Fixture(Conditions(20.0f));
		// Accepting is off by default, so a client's socket does not quietly become a server.
		fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		Test.Assert(!AnyKind(fixture.Client, .Connected));
	}

	[Test]
	public static void EveryReliableMessageArrivesInOrderDespiteHeavyLoss()
	{
		let fixture = scope Fixture(Conditions(20.0f, 0.5f, 0.0f, 0.2f, 5));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(40);
		AnyKind(fixture.Server, .Connected);

		for (uint8 i = 0; i < 20; i++)
		{
			let message = scope uint8[](i);
			fixture.Client.Send(serverPeer, 0, message, .ReliableOrdered);
		}

		let got = scope List<uint8>();
		for (int step = 0; step < 200; step++)
		{
			fixture.Step();
			DrainReceived(fixture.Server, got);
			if (got.Count >= 20)
				break;
		}

		Test.Assert(got.Count == 20);
		// In order and exactly once, which is what the ordered release plus the duplicate
		// check together promise.
		for (int i = 0; i < got.Count; i++)
			Test.Assert(got[i] == (uint8)i);
	}

	/// More than a packet's worth due at once (a replication delta of a crowd) goes out the
	/// same update, not a packet an update: at one an update a big delta drained over several
	/// updates while the next ones queued behind it, and the delay grew without end.
	[Test]
	public static void ABurstBiggerThanAPacketGoesOutInOneUpdate()
	{
		let fixture = scope Fixture(Conditions(10.0f, 0.0f, 0.0f, 0.0f, 1));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		DrainReceived(fixture.Server, scope .());

		for (uint8 i = 0; i < 20; i++)
		{
			let message = scope uint8[1000]; // one to a packet
			message[0] = i;
			fixture.Client.Send(serverPeer, 1, message, .ReliableOrdered);
		}
		fixture.Pump(3); // the latency and a step or two: far fewer updates than messages
		let got = scope List<uint8>();
		DrainReceived(fixture.Server, got);
		Test.Assert(got.Count == 20, scope $"{got.Count} of 20 arrived");
		for (int i < got.Count)
			Test.Assert(got[i] == (uint8)i);
	}

	/// Unreliable messages that do not fit the packet wait for the next one; they used to be
	/// dropped.
	[Test]
	public static void UnreliableMessagesBeyondOnePacketAreSentNotDropped()
	{
		let fixture = scope Fixture(Conditions(10.0f, 0.0f, 0.0f, 0.0f, 1));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		DrainReceived(fixture.Server, scope .());

		for (uint8 i = 0; i < 10; i++)
		{
			let message = scope uint8[600]; // two do not fit one packet
			message[0] = i;
			fixture.Client.Send(serverPeer, 1, message, .Unreliable);
		}
		fixture.Pump(3);
		let got = scope List<uint8>();
		DrainReceived(fixture.Server, got);
		Test.Assert(got.Count == 10, scope $"{got.Count} of 10: no loss in the sim, so all of them");
	}

	[Test]
	public static void DuplicationNeverDoubleDelivers()
	{
		let fixture = scope Fixture(Conditions(20.0f, 0.0f, 1.0f, 0.0f, 11));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(30);
		AnyKind(fixture.Server, .Connected);

		for (uint8 i = 0; i < 10; i++)
		{
			let message = scope uint8[](i);
			fixture.Client.Send(serverPeer, 0, message, .ReliableOrdered);
		}

		let got = scope List<uint8>();
		for (int step = 0; step < 200; step++)
		{
			fixture.Step();
			DrainReceived(fixture.Server, got);
		}

		Test.Assert(got.Count == 10);
		for (int i = 0; i < got.Count; i++)
			Test.Assert(got[i] == (uint8)i);
	}

	[Test]
	public static void UnreliableMessagesCanDropBecauseNothingResendsThem()
	{
		let fixture = scope Fixture(Conditions(20.0f, 0.6f, 0.0f, 0.0f, 3));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		// The handshake's four legs (request, challenge, response, accept) take a few resends at
		// 60% loss.
		var connected = false;
		for (int step = 0; (step < 1000) && !connected; step++)
		{
			fixture.Step();
			connected = AnyKind(fixture.Client, .Connected);
		}
		Test.Assert(connected);
		fixture.Pump(30);
		AnyKind(fixture.Server, .Connected);

		for (uint8 i = 0; i < 40; i++)
		{
			let message = scope uint8[](i);
			fixture.Client.Send(serverPeer, 0, message, .Unreliable);
			fixture.Step();
		}
		fixture.Pump(40);

		let got = scope List<uint8>();
		DrainReceived(fixture.Server, got);
		Test.Assert(got.Count < 40);
	}

	[Test]
	public static void TheRoundTripIsEstimatedFromAcks()
	{
		let fixture = scope Fixture(Conditions(40.0f));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(10);

		for (int i = 0; i < 5; i++)
		{
			let message = scope uint8[](1);
			fixture.Client.Send(serverPeer, 0, message, .ReliableOrdered);
			fixture.Pump(10);
		}

		let stats = fixture.Client.Stats(serverPeer);
		// At least one one-way trip, and realistically about two.
		Test.Assert(stats.RttMs > 40.0f);
		Test.Assert(stats.RttMs < 200.0f);
	}

	[Test]
	public static void ASilentPeerTimesOut()
	{
		var config = ReliableConfig();
		config.TimeoutMs = 500.0f;
		let fixture = scope Fixture(Conditions(10.0f), config);
		fixture.Server.SetAccepting(true);
		fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		Test.Assert(AnyKind(fixture.Client, .Connected));

		// The server goes dark: only the client and the network are ticked from here.
		var disconnected = false;
		for (int step = 0; step < 100; step++)
		{
			fixture.Network.Advance(10.0f);
			fixture.Client.Update(10.0f);
			if (AnyKind(fixture.Client, .Disconnected))
			{
				disconnected = true;
				break;
			}
		}
		Test.Assert(disconnected);
	}

	[Test]
	public static void ALargeMessageFragmentsAndReassemblesIntactOverLoss()
	{
		let fixture = scope Fixture(Conditions(20.0f, 0.3f, 0.0f, 0.2f, 31));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		AnyKind(fixture.Server, .Connected);

		// Several times one datagram, so this has to fragment.
		let payload = scope List<uint8>();
		for (int i = 0; i < 5000; i++)
			payload.Add((uint8)(i * 7));
		fixture.Client.Send(serverPeer, 0, payload, .ReliableOrdered);

		let received = scope List<uint8>();
		let event = scope NetEvent();
		for (int step = 0; step < 400; step++)
		{
			fixture.Step();
			while (fixture.Server.Poll(event))
			{
				if ((event.Kind == .Received) && (event.Payload.Count > 1))
				{
					received.Clear();
					received.AddRange(event.Payload);
				}
			}
			if (received.Count == payload.Count)
				break;
		}

		// Whole, and byte for byte: a fragment that arrived twice or out of order would show
		// up here rather than as a plausible-looking wrong message.
		Test.Assert(received.Count == payload.Count);
		for (int i = 0; i < payload.Count; i++)
			Test.Assert(received[i] == payload[i]);
	}

	[Test]
	public static void ResendIsRoundTripTimedRatherThanPerTick()
	{
		// Nothing gets through, so the message stays unacked and every packet is a resend.
		let fixture = scope Fixture(Conditions(20.0f, 1.0f));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(5);

		let message = scope uint8[](7);
		fixture.Client.Send(serverPeer, 0, message, .ReliableOrdered);

		let before = fixture.Client.Stats(serverPeer).SentBytes;
		// A hundred one-millisecond ticks. A per-tick resend would send about a hundred
		// packets; the floor allows about five.
		for (int step = 0; step < 100; step++)
			fixture.Step(1.0f);
		let sent = fixture.Client.Stats(serverPeer).SentBytes - before;

		Test.Assert(sent > 0);
		Test.Assert(sent < 40 * (uint32)message.Count + 2000);
	}

	[Test]
	public static void AnExplicitDisconnectNotifiesThePeer()
	{
		let fixture = scope Fixture(Conditions(10.0f));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		AnyKind(fixture.Server, .Connected);

		fixture.Client.Disconnect(serverPeer);
		fixture.Pump(10);
		Test.Assert(AnyKind(fixture.Server, .Disconnected));
	}

	/// A reliable message in a connection's very first Data packet is resent when that packet is
	/// lost: the far end, having received nothing, acks nothing. The resend waits longer than the
	/// far end's first keepalive, so an ack of a packet never received would retire it first.
	[Test]
	public static void AReliableMessageInTheFirstPacketIsResentWhenThatPacketIsLost()
	{
		var config = ReliableConfig();
		config.KeepAliveMs = 50.0f;
		config.MinResendMs = 500.0f;
		let network = scope SimDatagramNetwork(Conditions(10.0f));
		let serverSocket = network.CreateSocket();
		let dropping = scope DropFirstDataSocket(network.CreateSocket());
		let client = scope ReliableTransport(dropping, config);
		let server = scope ReliableTransport(serverSocket, config);
		server.SetAccepting(true);

		let serverPeer = client.Connect(serverSocket.LocalEndpoint);
		// Queued while connecting, so it goes in the first Data packet, which is lost.
		client.Send(serverPeer, 0, scope uint8[](42), .ReliableOrdered);
		let got = scope List<uint8>();
		for (int step < 200)
		{
			network.Advance(10.0f);
			client.Update(10.0f);
			server.Update(10.0f);
			DrainReceived(server, got);
		}
		Test.Assert(dropping.Dropped == 1);
		Test.Assert((got.Count == 1) && (got[0] == 42), "resent, and delivered once");
	}

	/// A client that restarts and connects again from the same address starts a new session: the
	/// server ends the old one and accepts the new, whose messages arrive though their ids start
	/// over.
	[Test]
	public static void AClientRestartingAtTheSameAddressConnectsAgain()
	{
		let fixture = scope Fixture(Conditions(10.0f));
		fixture.Server.SetAccepting(true);
		let first = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		for (uint8 i = 0; i < 3; i++)
			fixture.Client.Send(first, 0, scope uint8[](i), .ReliableOrdered);
		fixture.Pump(20);
		let before = scope List<uint8>();
		DrainReceived(fixture.Server, before);
		Test.Assert(before.Count == 3);

		// The client process restarts on the same socket address.
		delete fixture.Client;
		fixture.Client = new .(fixture.ClientSocket);
		let second = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		Test.Assert(AnyKind(fixture.Client, .Connected));
		var disconnected = 0;
		var connected = 0;
		let event = scope NetEvent();
		while (fixture.Server.Poll(event))
		{
			if (event.Kind == .Disconnected)
				disconnected++;
			else if (event.Kind == .Connected)
				connected++;
		}
		Test.Assert((disconnected == 1) && (connected == 1), "the old session ends, the new one starts");

		fixture.Client.Send(second, 0, scope uint8[](7), .ReliableOrdered);
		fixture.Pump(20);
		let after = scope List<uint8>();
		DrainReceived(fixture.Server, after);
		Test.Assert((after.Count == 1) && (after[0] == 7), "the new session's first message arrives");
	}

	/// A client that disconnects and connects again to the same server gets a working session.
	[Test]
	public static void AClientThatDisconnectedConnectsAgain()
	{
		let fixture = scope Fixture(Conditions(10.0f));
		fixture.Server.SetAccepting(true);
		let first = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		fixture.Client.Send(first, 0, scope uint8[](1), .ReliableOrdered);
		fixture.Pump(20);
		fixture.Client.Disconnect(first);
		fixture.Pump(10);
		Test.Assert(AnyKind(fixture.Server, .Disconnected));

		let second = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		Test.Assert(AnyKind(fixture.Client, .Connected));
		fixture.Client.Send(second, 0, scope uint8[](9), .ReliableOrdered);
		fixture.Pump(20);
		let got = scope List<uint8>();
		DrainReceived(fixture.Server, got);
		Test.Assert((got.Count == 1) && (got[0] == 9), "the new session's message arrives");
	}

	/// Sequenced messages never arrive out of order: over a link that reorders, a stale one is
	/// dropped rather than delivered after a newer one.
	[Test]
	public static void SequencedMessagesNeverArriveOutOfOrder()
	{
		let fixture = scope Fixture(Conditions(20.0f, 0.0f, 0.1f, 0.5f, 11));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		AnyKind(fixture.Server, .Connected);

		let got = scope List<uint8>();
		for (uint8 i = 0; i < 200; i++)
		{
			fixture.Client.Send(serverPeer, 3, scope uint8[](i), .UnreliableSequenced);
			fixture.Step();
			DrainReceived(fixture.Server, got);
		}
		fixture.Pump(20);
		DrainReceived(fixture.Server, got);
		Test.Assert(got.Count > 50, "most arrive");
		for (int i = 1; i < got.Count; i++)
			Test.Assert(got[i] > got[i - 1], "each newer than the one before");
	}
}
