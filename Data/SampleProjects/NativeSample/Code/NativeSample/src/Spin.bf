using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace NativeSample;

/// Turns its entity about an axis of the entity's own (its local up by default) while the scene
/// simulates: the reference game's own component, saved with the scene.
[SerializableComponent("nativesample.Spin")]
[DisplayName("Spin")]
[Category("Native Sample")]
[Description("Turns the entity about an axis of its own while the scene simulates.")]
struct SpinComponent : ISerializable
{
	[DisplayName("Turns Per Second")]
	public float TurnsPerSecond = 0.25f;
	[DisplayName("Axis")]
	public Float3 Axis = .(0.0f, 1.0f, 0.0f);

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "turnsPerSecond", ref TurnsPerSecond);
		SerializeValue(ar, "axis", ref Axis);
	}
}

/// The spin components of a scene, saved with it; each update turns their entities. The Engine
/// part adds it to every scene.
class SpinManager : SerializableComponentManager<SpinComponent>
{
	/// BORROWED: the scene outlives its systems.
	private Sedulous.Scene.Scene mScene = null;

	public override void OnSceneCreate(Sedulous.Scene.Scene scene)
	{
		mScene = scene;
	}

	/// The editor's edit mode does not turn them; a simulating page, play and the player do.
	public override bool IsSimulationOnly => true;

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if ((phase != .Update) || (mScene == null))
			return;
		ForEach(scope [&] (spin, owner) =>
			{
				if (!mScene.IsEffectivelyActive(owner))
					return;
				let turn = Quaternion.FromAxisAngle(spin.Axis, spin.TurnsPerSecond * TwoPi * deltaTime);
				// The turn applies in the entity's own frame; normalizing keeps the rotation a unit
				// one over many frames of accumulated products.
				var local = mScene.GetLocalTransform(owner);
				let r = local.Rotation * turn;
				let length = Math.Sqrt(r.X * r.X + r.Y * r.Y + r.Z * r.Z + r.W * r.W);
				local.Rotation = (length > 0.0f) ? Quaternion(r.X / length, r.Y / length, r.Z / length, r.W / length) : Quaternion.Identity;
				mScene.SetLocalTransform(owner, local);
			});
	}
}
