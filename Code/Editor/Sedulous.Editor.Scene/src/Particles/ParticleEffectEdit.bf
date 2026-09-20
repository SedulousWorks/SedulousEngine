using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Particles;
using Sedulous.Particles.Resource;

namespace Sedulous.Editor.Scene;

/// The particle page's edits on a ParticleEffect, kept off the page so they run headless:
/// the default seed, the module catalogue the tree's menus add from, and the binary
/// snapshot the undo step carries.
static class ParticleEffectEdit
{
	/// The initializer catalogue, in menu order; AddInitializer takes the index.
	public static readonly StringView[7] InitializerNames = .("Position", "Velocity", "Lifetime", "Color", "Size", "Rotation", "Mesh Orientation");
	/// The behavior catalogue, in menu order; AddBehavior takes the index.
	public static readonly StringView[13] BehaviorNames = .("Gravity", "Drag", "Wind", "Turbulence", "Vortex", "Attractor", "Radial Force", "Collision", "Color/Life", "Alpha/Life", "Size/Life", "Rotation/Life", "Speed/Life");

	/// One system, a fountain: lifetime, an upward velocity, size, colour and gravity, at
	/// 120 particles a second.
	public static void SeedDefault(ParticleEffect effect)
	{
		let sys = effect.AddSystem(2000);
		sys.AddInitializer<LifetimeInitializer>().Lifetime = .(1.5f, 2.5f);
		sys.AddInitializer<VelocityInitializer>().BaseVelocity = .(0.0f, 5.0f, 0.0f);
		sys.AddInitializer<SizeInitializer>();
		sys.AddInitializer<ColorInitializer>();
		sys.AddBehavior<GravityBehavior>();
		sys.Emitter.Mode = .Continuous;
		sys.Emitter.SpawnRate = 120.0f;
	}

	/// The module's type name without its namespace, what the tree and the inspector show.
	public static void ModuleLabel(Object module, String outLabel)
	{
		if (module == null)
		{
			outLabel.Set("?");
			return;
		}
		module.GetType().GetName(outLabel);
	}

	/// Adds the catalogue's initializer `kind` to `system`; null for an index off the list.
	public static ParticleInitializer AddInitializer(ParticleSystem system, int kind)
	{
		switch (kind)
		{
		case 0: return system.AddInitializer<PositionInitializer>();
		case 1: return system.AddInitializer<VelocityInitializer>();
		case 2: return system.AddInitializer<LifetimeInitializer>();
		case 3: return system.AddInitializer<ColorInitializer>();
		case 4: return system.AddInitializer<SizeInitializer>();
		case 5: return system.AddInitializer<RotationInitializer>();
		case 6: return system.AddInitializer<MeshOrientationInitializer>();
		default: return null;
		}
	}

	/// Adds the catalogue's behavior `kind` to `system`; null for an index off the list.
	public static ParticleBehavior AddBehavior(ParticleSystem system, int kind)
	{
		switch (kind)
		{
		case 0: return system.AddBehavior<GravityBehavior>();
		case 1: return system.AddBehavior<DragBehavior>();
		case 2: return system.AddBehavior<WindBehavior>();
		case 3: return system.AddBehavior<TurbulenceBehavior>();
		case 4: return system.AddBehavior<VortexBehavior>();
		case 5: return system.AddBehavior<AttractorBehavior>();
		case 6: return system.AddBehavior<RadialForceBehavior>();
		case 7: return system.AddBehavior<CollisionBehavior>();
		case 8: return system.AddBehavior<ColorOverLifetimeBehavior>();
		case 9: return system.AddBehavior<AlphaOverLifetimeBehavior>();
		case 10: return system.AddBehavior<SizeOverLifetimeBehavior>();
		case 11: return system.AddBehavior<RotationOverLifetimeBehavior>();
		case 12: return system.AddBehavior<SpeedOverLifetimeBehavior>();
		default: return null;
		}
	}

	/// The first position initializer's shape, what the emission gizmo draws; null without one.
	public static EmissionShape* EmissionShapeOf(ParticleSystem system)
	{
		for (int32 i < system.InitializerCount)
		{
			if (let pos = system.GetInitializer(i) as PositionInitializer)
				return &pos.Shape;
		}
		return null;
	}

	/// The whole effect as its binary form, what an undo step keeps.
	public static void Snapshot(ParticleEffect effect, List<uint8> outBlob)
	{
		outBlob.Clear();
		let stream = scope MemoryStream();
		let ar = scope BinarySerializer(stream, .Write);
		ParticleEffectSerialization.SerializeEffect(ar, effect);
		outBlob.AddRange(stream.Bytes);
	}

	/// Restores a snapshot over `effect`, which is emptied first since a read appends; false
	/// when it already matched, nothing read.
	public static bool Apply(ParticleEffect effect, Span<uint8> blob)
	{
		let current = scope List<uint8>();
		Snapshot(effect, current);
		if ((current.Count == blob.Length) && (Internal.MemCmp(current.Ptr, blob.Ptr, blob.Length) == 0))
			return false;
		effect.Clear();
		let stream = scope MemoryStream();
		stream.Write(blob);
		stream.Seek(0, .Begin);
		let ar = scope BinarySerializer(stream, .Read);
		ParticleEffectSerialization.SerializeEffect(ar, effect);
		return true;
	}
}
