using System;
using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Scene;

/// The base for a per scene system: the unit a scene owns, ticks per phase, and notifies
/// of entity lifecycle.
///
/// A component manager is the most common kind, but a system need not own components at
/// all: a spatial index, a physics world or an audio listener are plain systems.
///
/// BEHAVIOUR LIVES HERE, not on the components. That is what lets a component be plain
/// value data in a contiguous pool.
abstract class SceneSystem
{
	/// The capability query. A system that IS a component manager returns itself, so the
	/// scene can drive component initialisation and lookup without asking what type it is.
	/// A plain system returns null.
	public virtual ComponentManagerBase AsComponentManager => null;

	// ---- lifecycle, driven by the scene ----

	public virtual void OnSceneCreate(Scene scene) {}
	public virtual void OnSceneStarted() {}
	public virtual void OnSceneStopped() {}
	public virtual void OnEntityDestroyed(EntityHandle entity) {}
	public virtual void OnEntityActiveChanged(EntityHandle entity, bool active) {}

	// ---- per frame ----

	/// Called for EACH phase this system takes part in, so a system switches on `phase`.
	/// The scene runs phases in ScenePhase order and, within a phase, systems in
	/// UpdateOrder.
	public virtual void OnUpdate(ScenePhase phase, float deltaTime) {}
	public virtual void OnFixedUpdate(float fixedDeltaTime) {}

	// ---- scene level settings ----

	/// A system with ONE per scene settings block, as opposed to per entity state, exposes
	/// it here: an editor inspects it when no entity is selected, and saving a scene
	/// persists it alongside. All four members go together or not at all.
	///
	/// SettingsType is the block's type, null when there is none; SettingsInstance is the
	/// live block, which a property edit writes straight into; SettingsId is its stable id
	/// on disk; SerializeSettings writes the fields, with the caller wrapping it in the
	/// versioned payload so a body can gate on the version.
	public virtual Type SettingsType => null;
	public virtual void* SettingsInstance => null;
	public virtual StringView SettingsId => default;

	/// The settings block's own data version, which a SerializeSettings body gates on to
	/// migrate an older scene. DIVERGES from Raptor, which reads it off the reflected type;
	/// there is no reflected data version here, so a system states it.
	public virtual uint32 SettingsDataVersion => 1;

	public virtual void SerializeSettings(ISerializer ar) {}

	/// Binds every resource reference this system holds, settings blocks included: the
	/// post load resolve pass. A component manager overrides it for its pools, and a plain
	/// system with resource bearing settings overrides it too.
	public virtual void ResolveResources(ResourceManager manager) {}

	/// Lower runs EARLIER within a phase.
	public virtual int32 UpdateOrder => 0;

	/// When true, the update hooks are skipped while the scene's simulation is paused, as
	/// in edit mode. A system with mixed work leaves this false and asks the scene instead.
	public virtual bool IsSimulationOnly => false;
}
