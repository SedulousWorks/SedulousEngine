namespace Sedulous.Particles.Resources;

using System;
using System.Collections;
using Sedulous.Particles;

/// Registry for creating particle behaviors and initializers by type ID.
/// Used during deserialization to reconstruct the effect graph from saved data.
/// Lives in Sedulous.Particles.Resources - the core Particles project has no
/// serialization dependency.
public static class ParticleTypeRegistry
{
	private static Dictionary<StringView, function ParticleBehavior()> sBehaviorFactories = new .() ~ delete _;
	private static Dictionary<StringView, function ParticleInitializer()> sInitializerFactories = new .() ~ delete _;
	private static bool sInitialized = false;

	/// Registers all built-in particle types. Called once on first use.
	public static void EnsureInitialized()
	{
		if (sInitialized) return;
		sInitialized = true;

		// Behaviors
		RegisterBehavior("Gravity", () => new GravityBehavior());
		RegisterBehavior("Drag", () => new DragBehavior());
		RegisterBehavior("Wind", () => new WindBehavior());
		RegisterBehavior("Turbulence", () => new TurbulenceBehavior());
		RegisterBehavior("Vortex", () => new VortexBehavior());
		RegisterBehavior("Attractor", () => new AttractorBehavior());
		RegisterBehavior("RadialForce", () => new RadialForceBehavior());
		// VelocityIntegration is no longer registered - velocity integration
		// is now a built-in ParticleSystem step that runs unconditionally
		// after behaviors. Old assets that listed it explicitly deserialize
		// cleanly (CreateBehavior returns null and the entry is dropped).
		RegisterBehavior("ColorOverLifetime", () => new ColorOverLifetimeBehavior());
		RegisterBehavior("SizeOverLifetime", () => new SizeOverLifetimeBehavior());
		RegisterBehavior("SpeedOverLifetime", () => new SpeedOverLifetimeBehavior());
		RegisterBehavior("AlphaOverLifetime", () => new AlphaOverLifetimeBehavior());
		RegisterBehavior("RotationOverLifetime", () => new RotationOverLifetimeBehavior());

		// Initializers
		RegisterInitializer("Position", () => new PositionInitializer());
		RegisterInitializer("Velocity", () => new VelocityInitializer());
		RegisterInitializer("Lifetime", () => new LifetimeInitializer());
		RegisterInitializer("Color", () => new ColorInitializer());
		RegisterInitializer("Size", () => new SizeInitializer());
		RegisterInitializer("Rotation", () => new RotationInitializer());
		RegisterInitializer("MeshOrientation", () => new MeshOrientationInitializer());
	}

	/// Registers a custom behavior factory.
	public static void RegisterBehavior(StringView typeId, function ParticleBehavior() factory)
	{
		sBehaviorFactories[typeId] = factory;
	}

	/// Registers a custom initializer factory.
	public static void RegisterInitializer(StringView typeId, function ParticleInitializer() factory)
	{
		sInitializerFactories[typeId] = factory;
	}

	/// Creates a behavior by type ID. Returns null if unknown.
	public static ParticleBehavior CreateBehavior(StringView typeId)
	{
		EnsureInitialized();
		if (sBehaviorFactories.TryGetValue(typeId, let factory))
			return factory();
		return null;
	}

	/// Creates an initializer by type ID. Returns null if unknown.
	public static ParticleInitializer CreateInitializer(StringView typeId)
	{
		EnsureInitialized();
		if (sInitializerFactories.TryGetValue(typeId, let factory))
			return factory();
		return null;
	}

	/// Enumerate registered behavior type IDs into outIds (sorted alphabetically).
	/// Used by the editor's type-picker UI.
	public static void GetBehaviorTypeIds(List<StringView> outIds)
	{
		EnsureInitialized();
		for (let kv in sBehaviorFactories)
			outIds.Add(kv.key);
		outIds.Sort(scope (a, b) => a.CompareTo(b, true));
	}

	/// Enumerate registered initializer type IDs into outIds (sorted alphabetically).
	/// Used by the editor's type-picker UI.
	public static void GetInitializerTypeIds(List<StringView> outIds)
	{
		EnsureInitialized();
		for (let kv in sInitializerFactories)
			outIds.Add(kv.key);
		outIds.Sort(scope (a, b) => a.CompareTo(b, true));
	}
}
