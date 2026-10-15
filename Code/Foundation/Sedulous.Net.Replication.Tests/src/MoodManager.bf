using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Net.Replication.Tests;

/// State a manager keeps itself, as a script behaviour's properties are: no field is marked
/// replicated; the manager writes and reads its own bytes (IReplicatedStateSource).
[SerializableComponent("test.Mood")]
struct Mood : ISerializable
{
	public int32 Value = 0;
	/// How often a peer's state was applied.
	public int32 Reads = 0;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "mood", ref Value);
	}
}

class MoodManager : SerializableComponentManager<Mood>, IReplicatedStateSource
{
	public override IReplicatedStateSource AsReplicatedStateSource => this;

	public bool WriteReplicatedState(EntityHandle entity, List<uint8> outState)
	{
		let mood = Get(entity);
		if ((mood == null) || (mood.Value < 0))
			return false; // a negative mood: nothing to send
		outState.Clear();
		for (int i < 4)
			outState.Add((uint8)(((uint32)mood.Value >> (8 * i)) & 0xFF));
		return true;
	}

	public void ReadReplicatedState(EntityHandle entity, Span<uint8> state)
	{
		let mood = Get(entity);
		if ((mood == null) || (state.Length != 4))
			return;
		uint32 value = 0;
		for (int i < 4)
			value |= (uint32)state[i] << (8 * i);
		mood.Value = (int32)value;
		mood.Reads++;
	}
}
