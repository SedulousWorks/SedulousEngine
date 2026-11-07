using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

/// The contacts the contact tests' behaviours hear, into the lifecycle log so they read in
/// order with the ticks, each as "<tag>:<entity>.<call>(<other>) ", "-" for an other that is
/// no live entity.
static class ContactLog
{
	public static void Add(Behaviour behaviour, StringView tag, StringView call, EntityHandle other)
	{
		let scene = behaviour.Scene;
		StringView otherName = ((scene != null) && scene.IsValid(other)) ? scene.GetEntityName(other) : "-";
		LifecycleLog.Add(behaviour, tag, scope $"{call}({otherName})");
	}
}

/// Overrides all four contact callbacks, and keeps the last collision's geometry.
[Behaviour("test.bumper")]
class Bumper : Behaviour
{
	public Float3 LastPoint = .(0.0f, 0.0f, 0.0f);
	public Float3 LastNormal = .(0.0f, 0.0f, 0.0f);
	public float LastSpeed = -1.0f;

	protected override void OnContactBegin(EntityHandle other, Float3 point, Float3 normal, float speed)
	{
		ContactLog.Add(this, "B", "Begin", other);
		LastPoint = point;
		LastNormal = normal;
		LastSpeed = speed;
	}

	protected override void OnContactEnd(EntityHandle other, Float3 point, Float3 normal, float speed)
		=> ContactLog.Add(this, "B", "End", other);
	protected override void OnTriggerEnter(EntityHandle other) => ContactLog.Add(this, "B", "Enter", other);
	protected override void OnTriggerExit(EntityHandle other) => ContactLog.Add(this, "B", "Exit", other);
}

/// Overrides the trigger entry alone: a collision reaches it not at all.
[Behaviour("test.sensor")]
class Sensor : Behaviour
{
	protected override void OnTriggerEnter(EntityHandle other) => ContactLog.Add(this, "S", "Enter", other);
}
