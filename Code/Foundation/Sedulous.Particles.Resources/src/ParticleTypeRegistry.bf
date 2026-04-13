namespace Sedulous.Particles.Resources;

using System;
using System.Collections;
using Sedulous.Particles;

/// Registry for creating particle behaviors and initializers by type ID.
/// Used during deserialization to reconstruct the effect graph from saved data.
/// Lives in Sedulous.Particles.Resources — the core Particles project has no
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
		RegisterBehavior("VelocityIntegration", () => new VelocityIntegrationBehavior());
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
}
