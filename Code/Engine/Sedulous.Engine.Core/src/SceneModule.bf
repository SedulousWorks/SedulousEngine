namespace Sedulous.Engine.Core;

using System;
using System.Collections;

/// Base class for per-scene systems.
/// Each scene has its own instances of scene modules.
/// ComponentManager<T> extends this - most scene modules are component managers.
///
/// Scene modules can register update functions for specific phases
/// and fixed update functions for physics-rate updates.
public abstract class SceneModule : IDisposable
{
	/// The scene this module belongs to. Set when added to a scene.
	public Scene Scene { get; private set; }

	/// Registered update functions per phase.
	private List<UpdateRegistration> mUpdateRegistrations = new .() ~ delete _;

	/// Registered fixed update functions.
	private List<UpdateRegistration> mFixedUpdateRegistrations = new .() ~ delete _;

	/// Called when this module is added to a scene.
	public virtual void OnSceneCreate(Scene scene)
	{
		Scene = scene;
		OnRegisterUpdateFunctions();
	}

	/// Called when this module is removed from a scene or the scene is destroyed.
	public virtual void OnSceneDestroy()
	{
		Scene = null;
	}

	/// Serialization type ID for this module.
	/// Override and return a non-empty string to make this module's components serializable.
	/// This ID is stored in scene files to identify which manager owns which components.
	/// Use a stable string (e.g., "Sedulous.MeshComponent") - not a type name that could change.
	public virtual StringView SerializationTypeId => default;

	/// Whether this module participates in serialization.
	public bool IsSerializable => !SerializationTypeId.IsEmpty;

	/// Called when an entity is destroyed. Override to clean up references.
	public virtual void OnEntityDestroyed(EntityHandle entity) { }

	/// Called when an entity's active state changes. Override to sync component state.
	public virtual void OnEntityActiveChanged(EntityHandle entity, bool active) { }

	/// Override to register update functions via RegisterUpdate() and RegisterFixedUpdate().
	protected virtual void OnRegisterUpdateFunctions() { }

	/// Registers an update function for a specific scene phase.
	protected void RegisterUpdate(ScenePhase phase, delegate void(float) fn, float priority = 0)
	{
		mUpdateRegistrations.Add(.()
		{
			Phase = phase,
			Function = fn,
			Priority = priority
		});
	}

	/// Registers a fixed update function (called at fixed timestep, e.g., physics).
	protected void RegisterFixedUpdate(delegate void(float) fn, float priority = 0)
	{
		mFixedUpdateRegistrations.Add(.()
		{
			Phase = .Update, // unused for fixed, but keeps struct consistent
			Function = fn,
			Priority = priority
		});
	}

	/// Gets all registered phase update functions. Called by Scene.
	public Span<UpdateRegistration> UpdateRegistrations => mUpdateRegistrations;

	/// Gets all registered fixed update functions. Called by Scene.
	public Span<UpdateRegistration> FixedUpdateRegistrations => mFixedUpdateRegistrations;

	public virtual void Dispose()
	{
		for (let reg in mUpdateRegistrations)
			delete reg.Function;
		mUpdateRegistrations.Clear();

		for (let reg in mFixedUpdateRegistrations)
			delete reg.Function;
		mFixedUpdateRegistrations.Clear();
	}

	/// An update function registered to a specific phase.
	public struct UpdateRegistration
	{
		public ScenePhase Phase;
		public delegate void(float) Function;
		public float Priority; // higher = runs earlier in the phase
	}
}
