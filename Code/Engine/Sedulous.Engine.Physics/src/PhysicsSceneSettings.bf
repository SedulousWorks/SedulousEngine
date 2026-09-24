using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Engine.Physics;

/// The per scene physics settings.
///
/// The collision GROUPS are a designer's tool: the names give the matrix's rows meaning in an
/// editor, and a row beyond what the matrix holds collides with everything, so adding a group
/// never silently switches collisions off.
///
/// The lists are OWNED by this block rather than by a manager, because a settings block is one
/// per scene and is a plain object rather than a component in a pool.
// The inspector writes a field through RUNTIME reflection, so every field needs its
// data emitted; an attribute on a field forces that, a bare field has nothing to.
[Reflect(.Type | .NonStaticFields)]
[DisplayName("Physics Settings")]
[Category("Physics")]
[Scriptable]
class PhysicsSceneSettings : ISerializable
{
	[Scriptable]
	public Float3 Gravity = .(0.0f, -9.81f, 0.0f);
	[Scriptable]
	public int32 CollisionSteps = 1;
	[Scriptable]
	public bool DebugDraw = false;

	public List<String> GroupNames = new .() ~ DeleteContainerAndItems!(_);
	public List<uint32> GroupCollides = new .() ~ delete _;

	/// Whether two groups collide. A row the matrix does not reach collides with everything,
	/// which is what makes an unconfigured scene behave.
	public bool GroupCollidesWith(uint8 a, uint8 b)
	{
		if ((a >= GroupCollides.Count) || (b >= GroupCollides.Count))
			return true;

		// BOTH rows have to agree, so a matrix edited on one side only still reads as a
		// refusal rather than depending on which body is asked first.
		return ((GroupCollides[a] & (1u << b)) != 0) && ((GroupCollides[b] & (1u << a)) != 0);
	}

	public void Serialize(ISerializer ar)
	{
		ar.Key("gravity");
		Sedulous.Core.Serialization.Serialize(ar, ref Gravity);
		SerializeValue(ar, "collisionSteps", ref CollisionSteps);
		SerializeValue(ar, "debugDraw", ref DebugDraw);

		SerializeStrings(ar, "groupNames", GroupNames);

		ar.Key("groupCollides");
		uint32 count = (uint32)GroupCollides.Count;
		ar.BeginArray(ref count);
		if (ar.Mode == .Read)
		{
			GroupCollides.Clear();
			GroupCollides.Reserve((int)count);
			for (uint32 i < count)
			{
				uint32 row = 0;
				SerializeValue(ar, ref row);
				GroupCollides.Add(row);
			}
		}
		else
		{
			for (int i < GroupCollides.Count)
			{
				var row = GroupCollides[i];
				SerializeValue(ar, ref row);
			}
		}
		ar.EndArray();
	}

	private static void SerializeStrings(ISerializer ar, StringView key, List<String> values)
	{
		ar.Key(key);
		uint32 count = (uint32)values.Count;
		ar.BeginArray(ref count);
		if (ar.Mode == .Read)
		{
			ClearAndDeleteItems!(values);
			values.Reserve((int)count);
			for (uint32 i < count)
			{
				let value = new String();
				ar.Text(value);
				values.Add(value);
			}
		}
		else
		{
			for (int i < values.Count)
				ar.Text(values[i]);
		}
		ar.EndArray();
	}
}
