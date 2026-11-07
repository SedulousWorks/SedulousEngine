using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Scene;
using Sedulous.Net;
using Sedulous.Net.Replication;
using Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

/// A networked entity's behaviours keep their [Replicated] fields the same on every peer: the
/// host's manager writes the live values, a client's writes them into its own instance, with
/// no call. The bytes are carried by hand through the source interface, as the host's
/// endpoint would, and once through StateReplication itself.
///
/// A [Replicated] field of a kind the wire does not carry (an EntityRef, a Ref<T>, a list, a
/// class) fails the build, refused by [Behaviour] in the cook's words ("<class>: field '<name>'
/// cannot be replicated: ..."). A build failure cannot be a test here; the kind table that
/// decides it is.
class BehaviourReplicationTests
{
	private const float cDt = 1.0f / 60.0f;

	private static Guid MakeGuid(uint32 seed) => .(seed, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

	[Test]
	public static void AGuestsReplicatedFieldsReachTheOtherScenesInstance()
	{
		let host = scope Scene("host");
		let hostGuests = host.AddSystem<BehaviourManager<Guest>>();
		let onHost = host.CreateEntity("guest");
		let hostGuest = hostGuests.Add(onHost);
		hostGuest.Activity = 3;
		hostGuest.Sprinting = true;
		hostGuest.TimeLeft = 42.5f;
		hostGuest.Line.Set("a dance?");
		hostGuest.Facing = .(1.0f, 0.0f, 0.0f);
		hostGuest.Mask = .(0.25f, 0.5f, 0.75f, 1.0f);
		hostGuest.Seen = 7;
		hostGuest.Chatty = 9.0f;

		let client = scope Scene("client");
		let clientGuests = client.AddSystem<BehaviourManager<Guest>>();
		let onClient = client.CreateEntity("guest");
		let clientGuest = clientGuests.Add(onClient);
		clientGuest.Chatty = 7.0f;

		let state = scope List<uint8>();
		Test.Assert(hostGuests.WriteReplicatedState(onHost, state), "the host has state to send");
		clientGuests.ReadReplicatedState(onClient, state);

		Test.Assert(clientGuest.Activity == 3, scope $"activity {clientGuest.Activity}");
		Test.Assert(clientGuest.Sprinting, "the bool");
		Test.Assert(clientGuest.TimeLeft == 42.5f, scope $"time left {clientGuest.TimeLeft}");
		Test.Assert(clientGuest.Line == "a dance?", scope $"line '{clientGuest.Line}'");
		Test.Assert(clientGuest.Facing == Float3(1.0f, 0.0f, 0.0f), "the Float3");
		Test.Assert(clientGuest.Mask == Color(0.25f, 0.5f, 0.75f, 1.0f), "the Color");
		Test.Assert(clientGuest.Seen == 7, "a private field marked replicated travels too");
		Test.Assert(clientGuest.Chatty == 7.0f, "not replicated: the client's own");
		Test.Assert(hostGuest.Chatty == 9.0f, "and the host's untouched");

		// A later change travels the same way, into the same instance.
		hostGuest.Activity = 1;
		hostGuest.Line.Set("");
		Test.Assert(hostGuests.WriteReplicatedState(onHost, state));
		clientGuests.ReadReplicatedState(onClient, state);
		Test.Assert(clientGuests.Get(onClient) == clientGuest, "written in, not replaced");
		Test.Assert(clientGuest.Activity == 1);
		Test.Assert(clientGuest.Line.IsEmpty, "an empty text is a value too");
	}

	/// Each class's manager sends its own record for the entity, and each reaches only its own
	/// class: a Lantern's bytes read by the Guests' manager change nothing.
	[Test]
	public static void TwoBehaviourClassesOnOneEntityEachReplicate()
	{
		let host = scope Scene("host");
		let hostGuests = host.AddSystem<BehaviourManager<Guest>>();
		let hostLanterns = host.AddSystem<BehaviourManager<Lantern>>();
		let onHost = host.CreateEntity("e");
		hostGuests.Add(onHost).Activity = 2;
		let hostLantern = hostLanterns.Add(onHost);
		hostLantern.Glow = 0.75f;
		hostLantern.Hue = 0.1f;

		let client = scope Scene("client");
		let clientGuests = client.AddSystem<BehaviourManager<Guest>>();
		let clientLanterns = client.AddSystem<BehaviourManager<Lantern>>();
		let onClient = client.CreateEntity("e");
		let clientGuest = clientGuests.Add(onClient);
		let clientLantern = clientLanterns.Add(onClient);

		let guestState = scope List<uint8>();
		let lanternState = scope List<uint8>();
		Test.Assert(hostGuests.WriteReplicatedState(onHost, guestState));
		Test.Assert(hostLanterns.WriteReplicatedState(onHost, lanternState));

		// The wrong manager first: no Guest field is named Glow.
		clientGuests.ReadReplicatedState(onClient, lanternState);
		Test.Assert(clientGuest.Activity == 0, "a Lantern's value never reached a Guest");
		clientLanterns.ReadReplicatedState(onClient, guestState);
		Test.Assert(clientLantern.Glow == 0.0f, "nor a Guest's a Lantern");

		clientGuests.ReadReplicatedState(onClient, guestState);
		clientLanterns.ReadReplicatedState(onClient, lanternState);
		Test.Assert(clientGuest.Activity == 2);
		Test.Assert(clientLantern.Glow == 0.75f);
		Test.Assert(clientLantern.Hue == 0.5f, "not replicated");
	}

	/// The entries run in declaration order, a base class's first, and the same state writes
	/// the same bytes.
	[Test]
	public static void EntriesRunInDeclarationOrderBaseFirst()
	{
		let scene = scope Scene();
		let seated = scene.AddSystem<BehaviourManager<SeatedGuest>>();
		let e = scene.CreateEntity("e");
		let guest = seated.Add(e);
		guest.Seat = 2;
		guest.Line.Set("hi");

		let state = scope List<uint8>();
		Test.Assert(seated.WriteReplicatedState(e, state));

		let stream = scope MemoryStream();
		stream.Write(state);
		stream.Seek(0, .Begin);
		let reader = scope BinaryReader(stream);
		uint32 count = 0;
		reader.Read(out count);
		Test.Assert(count == 8, scope $"count {count}");

		StringView[?] names = .("Activity", "Sprinting", "TimeLeft", "Line", "Facing", "Mask", "mSeen", "Seat");
		ReplicatedKind[?] kinds = .(.Int, .Bool, .Float, .String, .Float3, .Color, .Int, .Int);
		let text = scope String();
		for (int i < names.Count)
		{
			uint64 hash = 0;
			uint8 kind = 0;
			reader.Read(out hash);
			reader.Read(out kind);
			Test.Assert(hash == BehaviourReplication.FieldHash(names[i]), scope $"entry {i} is {names[i]}");
			Test.Assert((ReplicatedKind)kind == kinds[i], scope $"entry {i}'s kind");
			var value = ReplicatedValue();
			Test.Assert(BehaviourReplication.ReadValue(reader, (ReplicatedKind)kind, ref value, text), scope $"entry {i}'s value");
			if (i == 3)
				Test.Assert(text == "hi", scope $"the text '{text}'");
			if (i == 7)
				Test.Assert(value.IntValue == 2, scope $"the seat {value.IntValue}");
		}
		Test.Assert(stream.Tell() == stream.Size(), "nothing after the last entry");

		let again = scope List<uint8>();
		Test.Assert(seated.WriteReplicatedState(e, again));
		Test.Assert(again.Count == state.Count, "the same length");
		for (int i < state.Count)
			Test.Assert(again[i] == state[i], scope $"byte {i} the same");
	}

	/// An entry whose kind is not its field's, or whose name is no field of the class, is
	/// passed over and the rest still apply; one cut short ends the read, what came before it
	/// applied.
	[Test]
	public static void AMismatchedEntryIsPassedOverAndACutOneEndsTheRead()
	{
		let scene = scope Scene();
		let guests = scene.AddSystem<BehaviourManager<Guest>>();
		let e = scene.CreateEntity("e");
		let guest = guests.Add(e);

		let stream = scope MemoryStream();
		let writer = scope BinaryWriter(stream);
		writer.Write((uint32)4);
		BehaviourReplication.Write(writer, BehaviourReplication.FieldHash("Activity"), 9.0f); // a float for an int
		BehaviourReplication.Write(writer, BehaviourReplication.FieldHash("Gone"), (int32)5); // no such field
		BehaviourReplication.Write(writer, BehaviourReplication.FieldHash("Line"), "kept");
		BehaviourReplication.Write(writer, BehaviourReplication.FieldHash("TimeLeft"), 2.5f);
		guests.ReadReplicatedState(e, stream.Bytes);
		Test.Assert(guest.Activity == 0, "the wrong kind is passed over");
		Test.Assert(guest.Line == "kept", "an unknown entry before it does not stop the read");
		Test.Assert(guest.TimeLeft == 2.5f);

		// The whole state of another, cut inside its last entry (the Seen int).
		let other = scene.CreateEntity("other");
		let source = guests.Add(other);
		source.Activity = 4;
		source.Seen = 11;
		let state = scope List<uint8>();
		Test.Assert(guests.WriteReplicatedState(other, state));
		guests.ReadReplicatedState(e, .(state.Ptr, state.Count - 2));
		Test.Assert(guest.Activity == 4, "the entries before the cut applied");
		Test.Assert(guest.Seen == 0, "the cut one did not");
	}

	/// A class marking nothing, and an entity without the behaviour, send nothing.
	[Test]
	public static void NothingMarkedOrNothingThereSendsNothing()
	{
		let scene = scope Scene();
		let quiets = scene.AddSystem<BehaviourManager<Quiet>>();
		let guests = scene.AddSystem<BehaviourManager<Guest>>();
		let e = scene.CreateEntity("e");
		quiets.Add(e);

		let state = scope List<uint8>();
		state.Add(1);
		Test.Assert(!quiets.WriteReplicatedState(e, state), "a class with no replicated field");
		Test.Assert(state.IsEmpty, "the output is cleared");
		Test.Assert(!guests.WriteReplicatedState(e, state), "an entity with no Guest");
		Test.Assert(quiets.AsReplicatedStateSource != null, "a source all the same, so a peer never reads it as reflected fields");
	}

	/// The kinds a [Replicated] field may be: anything else fails the build.
	[Test]
	public static void TheKindTableHoldsTheWiresKindsAlone()
	{
		Test.Assert(BehaviourReplication.KindOf(typeof(bool)) == .Bool);
		Test.Assert(BehaviourReplication.KindOf(typeof(int32)) == .Int);
		Test.Assert(BehaviourReplication.KindOf(typeof(float)) == .Float);
		Test.Assert(BehaviourReplication.KindOf(typeof(String)) == .String);
		Test.Assert(BehaviourReplication.KindOf(typeof(Float3)) == .Float3);
		Test.Assert(BehaviourReplication.KindOf(typeof(Color)) == .Color);

		Test.Assert(BehaviourReplication.KindOf(typeof(EntityRef)) == .None, "an entity reference");
		Test.Assert(BehaviourReplication.KindOf(typeof(EntityHandle)) == .None, "an entity handle");
		Test.Assert(BehaviourReplication.KindOf(typeof(Guid)) == .None, "an asset id");
		Test.Assert(BehaviourReplication.KindOf(typeof(List<int32>)) == .None, "a list");
		Test.Assert(BehaviourReplication.KindOf(typeof(Mover)) == .None, "a class");
		Test.Assert(BehaviourReplication.KindOf(typeof(MoverMood)) == .None, "an enum");
		Test.Assert(BehaviourReplication.KindOf(typeof(int)) == .None, "a platform width int");
		Test.Assert(BehaviourReplication.KindOf(typeof(double)) == .None, "a double");
	}

	/// Through StateReplication itself: the host's delta spawns the client's entity (its
	/// prefab bringing the Guest) and writes the Guest in; an unchanged Guest sends nothing;
	/// a change sends it again; a late joiner's snapshot carries it.
	[Test]
	public static void StateReplicationCarriesABehavioursFields()
	{
		let server = scope Scene("server");
		server.AddSystem<NetworkComponentManager>();
		let guests = server.AddSystem<BehaviourManager<Guest>>();
		let replication = scope StateReplication();
		let entity = server.CreateEntity("guest");
		let guest = guests.Add(entity);
		guest.Activity = 2;
		guest.Line.Set("hello");
		replication.AssignNetworkId(server, entity, MakeGuid(1));

		StateReplication.SpawnHandler Spawner() => new (scene, prefab, id) =>
			{
				let spawned = scene.CreateEntity();
				if (prefab == MakeGuid(1))
					scene.GetSystem<BehaviourManager<Guest>>().Add(spawned);
				return spawned;
			};

		let client = scope Scene("client");
		client.AddSystem<NetworkComponentManager>();
		let clientGuests = client.AddSystem<BehaviourManager<Guest>>();
		let clientReplication = scope StateReplication();
		clientReplication.SetSpawnHandler(Spawner());
		int Send()
		{
			let writer = scope BitWriter();
			let count = replication.CaptureDelta(server, 1, writer);
			let reader = scope BitReader(writer.Data);
			clientReplication.ApplyDelta(client, reader);
			return count;
		}
		Guest ClientGuest() => (clientGuests.Count == 1) ? clientGuests.Instances[0] : null;

		Test.Assert(Send() == 1, "it spawns");
		Test.Assert(ClientGuest() != null, "the prefab brought the Guest");
		Test.Assert(ClientGuest().Activity == 2, scope $"activity {ClientGuest().Activity}");
		Test.Assert(ClientGuest().Line == "hello");
		Test.Assert(Send() == 0, "nothing changed: nothing sent");
		guest.Activity = 3;
		Test.Assert(Send() == 1);
		Test.Assert(ClientGuest().Activity == 3);

		let late = scope Scene("late");
		late.AddSystem<NetworkComponentManager>();
		let lateGuests = late.AddSystem<BehaviourManager<Guest>>();
		let lateReplication = scope StateReplication();
		lateReplication.SetSpawnHandler(Spawner());
		let writer = scope BitWriter();
		replication.CaptureSnapshot(server, writer);
		let reader = scope BitReader(writer.Data);
		lateReplication.ApplySnapshot(late, reader);
		Test.Assert(lateGuests.Count == 1);
		Test.Assert(lateGuests.Instances[0].Activity == 3, "the snapshot carries it");
	}

	/// A behaviour reads its entity's network identity to gate what it drives, and reading it
	/// changes nothing.
	[Test]
	public static void ABehaviourGatesOnAuthorityAndReadsTheId()
	{
		let scene = scope Scene();
		scene.AddSystem<BehaviourSystem>();
		let networks = scene.AddSystem<NetworkComponentManager>();
		let gates = scene.AddSystem<BehaviourManager<Gate>>();
		let e = scene.CreateEntity("e");
		let gate = gates.Add(e);
		networks.Add(e).Id = .(42);

		scene.Update(cDt);
		Test.Assert(gate.Seen == 1042, scope $"seen {gate.Seen}");
		Test.Assert(networks.Get(e).Authority == .Server, "read, untouched");

		// Authority a client holds reads as the client's.
		let other = scene.CreateEntity("other");
		let clientGate = gates.Add(other);
		let identity = networks.Add(other);
		identity.Id = .(7);
		identity.Authority = .Client;
		scene.Update(cDt);
		Test.Assert(clientGate.Seen == 7, scope $"seen {clientGate.Seen}");
	}
}
