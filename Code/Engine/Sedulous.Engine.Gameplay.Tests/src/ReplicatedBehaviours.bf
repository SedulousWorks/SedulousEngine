using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Net.Replication;
using Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

/// A behaviour with a [Replicated] field of each kind the wire carries, a private one, and a
/// field each peer keeps for itself.
[Behaviour("test.guest")]
class Guest : Behaviour
{
	[Replicated] public int32 Activity = 0;
	[Replicated] public bool Sprinting = false;
	[Replicated] public float TimeLeft = 0.0f;
	[Replicated] public String Line = new .() ~ delete _;
	[Replicated] public Float3 Facing = .(0.0f, 0.0f, 1.0f);
	[Replicated] public Color Mask = .(1.0f, 1.0f, 1.0f);
	/// Not replicated: each peer's own.
	public float Chatty = 5.0f;
	[Replicated] private int32 mSeen = 0;

	/// The private replicated field, reached the way game code would.
	public int32 Seen
	{
		get => mSeen;
		set => mSeen = value;
	}
}

/// A subclass adding a replicated field of its own: the base's travel first.
[Behaviour("test.seated_guest")]
class SeatedGuest : Guest
{
	[Replicated] public int32 Seat = -1;
}

/// A second replicated class, to ride an entity beside a Guest.
[Behaviour("test.lantern")]
class Lantern : Behaviour
{
	[Replicated] public float Glow = 0.0f;
	public float Hue = 0.5f;
}

/// A class that marks nothing: its manager has nothing to send.
[Behaviour("test.quiet")]
class Quiet : Behaviour
{
	public float Hum = 0.0f;
}

/// Reads its entity's network identity as it starts: what it drives depends on who holds
/// authority.
[Behaviour("test.gate")]
class Gate : Behaviour
{
	public int32 Seen = -1;

	protected override void OnStart()
	{
		if (let network = Get<NetworkComponent>())
			Seen = ((network.Authority == .Server) ? 1000 : 0) + (int32)network.Id.Value;
	}
}
