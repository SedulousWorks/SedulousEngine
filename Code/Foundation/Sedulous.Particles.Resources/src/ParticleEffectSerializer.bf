namespace Sedulous.Particles.Resources;

using System;
using System.Collections;
using Sedulous.Serialization;
using Sedulous.Core.Mathematics;
using Sedulous.Particles;

/// Serializes/deserializes ParticleEffect graphs.
/// Handles polymorphic behavior/initializer types by matching on type ID
/// and reading/writing each type's specific parameters.
///
/// All serialization knowledge for particle types lives here — the core
/// Sedulous.Particles project has no serialization dependency.
public static class ParticleEffectSerializer
{
	/// Serializes or deserializes a ParticleEffect.
	public static SerializationResult Serialize(Serializer s, ParticleEffect effect)
	{
		ParticleTypeRegistry.EnsureInitialized();

		String name = scope String(effect.Name);
		s.String("name", name);
		if (s.IsReading)
			effect.Name.Set(name);

		// Systems
		int32 systemCount = (int32)effect.SystemCount;
		s.Int32("systemCount", ref systemCount);

		if (s.IsReading)
		{
			for (int32 i = 0; i < systemCount; i++)
			{
				s.BeginObject(scope $"system{i}");
				let system = SerializeSystem(s, null);
				if (system != null)
					effect.AddSystem(system);
				s.EndObject();
			}
		}
		else
		{
			for (int32 i = 0; i < systemCount; i++)
			{
				s.BeginObject(scope $"system{i}");
				SerializeSystem(s, effect.GetSystem(i));
				s.EndObject();
			}
		}

		// Sub-emitter links
		int32 linkCount = (int32)effect.SubEmitterLinks.Length;
		s.Int32("linkCount", ref linkCount);

		if (s.IsReading)
		{
			for (int32 i = 0; i < linkCount; i++)
			{
				s.BeginObject(scope $"link{i}");
				var link = SubEmitterLink.Default();
				SerializeSubEmitterLink(s, ref link);
				effect.AddSubEmitterLink(link);
				s.EndObject();
			}
		}
		else
		{
			for (int32 i = 0; i < linkCount; i++)
			{
				s.BeginObject(scope $"link{i}");
				var link = effect.SubEmitterLinks[i];
				SerializeSubEmitterLink(s, ref link);
				s.EndObject();
			}
		}

		return .Ok;
	}

	/// Serializes/deserializes a ParticleSystem.
	/// When reading, creates and returns a new system. When writing, system must be non-null.
	private static ParticleSystem SerializeSystem(Serializer s, ParticleSystem existing)
	{
		int32 maxParticles = existing?.MaxParticles ?? 1000;
		s.Int32("maxParticles", ref maxParticles);

		var simMode = (uint8)(existing?.DesiredMode ?? .CPU);
		s.UInt8("simulationMode", ref simMode);

		var space = (uint8)(existing?.SimulationSpace ?? .World);
		s.UInt8("simulationSpace", ref space);

		var blendMode = (uint8)(existing?.BlendMode ?? .Alpha);
		s.UInt8("blendMode", ref blendMode);

		var renderMode = (uint8)(existing?.RenderMode ?? .Billboard);
		s.UInt8("renderMode", ref renderMode);

		bool sortParticles = existing?.SortParticles ?? false;
		s.Bool("sortParticles", ref sortParticles);

		// Trail settings
		s.BeginObject("trail");
		var trail = existing?.Trail ?? TrailSettings.Default();
		s.Bool("enabled", ref trail.Enabled);
		s.Int32("maxPoints", ref trail.MaxPoints);
		s.Float("recordInterval", ref trail.RecordInterval);
		s.Float("lifetime", ref trail.Lifetime);
		s.Float("widthStart", ref trail.WidthStart);
		s.Float("widthEnd", ref trail.WidthEnd);
		s.Float("minVertexDistance", ref trail.MinVertexDistance);
		s.Bool("useParticleColor", ref trail.UseParticleColor);
		SerializeVector4(s, "trailColor", ref trail.TrailColor);
		s.EndObject();

		// LOD
		float lodStart = existing?.LODStartDistance ?? 0;
		float lodCull = existing?.LODCullDistance ?? 0;
		float lodMinRate = existing?.LODMinRate ?? 0.1f;
		s.Float("lodStartDistance", ref lodStart);
		s.Float("lodCullDistance", ref lodCull);
		s.Float("lodMinRate", ref lodMinRate);

		// Emitter
		s.BeginObject("emitter");
		var emissionMode = (uint8)(existing?.Emitter.Mode ?? .Continuous);
		float spawnRate = existing?.Emitter.SpawnRate ?? 10;
		int32 burstCount = existing?.Emitter.BurstCount ?? 0;
		float burstInterval = existing?.Emitter.BurstInterval ?? 0;
		int32 burstCycles = existing?.Emitter.BurstCycles ?? 0;

		s.UInt8("emissionMode", ref emissionMode);
		s.Float("spawnRate", ref spawnRate);
		s.Int32("burstCount", ref burstCount);
		s.Float("burstInterval", ref burstInterval);
		s.Int32("burstCycles", ref burstCycles);
		s.EndObject();

		ParticleSystem system = existing;
		if (s.IsReading)
		{
			system = new ParticleSystem(maxParticles);
			system.DesiredMode = (SimulationMode)simMode;
			system.SimulationSpace = (ParticleSpace)space;
			system.BlendMode = (ParticleBlendMode)blendMode;
			system.RenderMode = (ParticleRenderMode)renderMode;
			system.SortParticles = sortParticles;
			system.LODStartDistance = lodStart;
			system.LODCullDistance = lodCull;
			system.LODMinRate = lodMinRate;
			system.Emitter.Mode = (EmissionMode)emissionMode;
			system.Emitter.SpawnRate = spawnRate;
			system.Emitter.BurstCount = burstCount;
			system.Emitter.BurstInterval = burstInterval;
			system.Emitter.BurstCycles = burstCycles;
			system.Trail = trail;
		}

		// Initializers
		int32 initCount = s.IsWriting ? (int32)system.Initializers.Length : 0;
		s.Int32("initializerCount", ref initCount);

		if (s.IsReading)
		{
			for (int32 i = 0; i < initCount; i++)
			{
				s.BeginObject(scope $"init{i}");
				let init = DeserializeInitializer(s);
				if (init != null)
					system.AddInitializer(init);
				s.EndObject();
			}
		}
		else
		{
			for (int32 i = 0; i < (int32)system.Initializers.Length; i++)
			{
				s.BeginObject(scope $"init{i}");
				SerializeInitializer(s, system.Initializers[i]);
				s.EndObject();
			}
		}

		// Behaviors
		int32 behaviorCount = s.IsWriting ? (int32)system.Behaviors.Length : 0;
		s.Int32("behaviorCount", ref behaviorCount);

		if (s.IsReading)
		{
			for (int32 i = 0; i < behaviorCount; i++)
			{
				s.BeginObject(scope $"behavior{i}");
				let behavior = DeserializeBehavior(s);
				if (behavior != null)
					system.AddBehavior(behavior);
				s.EndObject();
			}
		}
		else
		{
			for (int32 i = 0; i < (int32)system.Behaviors.Length; i++)
			{
				s.BeginObject(scope $"behavior{i}");
				SerializeBehavior(s, system.Behaviors[i]);
				s.EndObject();
			}
		}

		return system;
	}

	// ==================== Behavior Serialization ====================

	/// Gets the type ID string for a behavior.
	private static StringView GetBehaviorTypeId(ParticleBehavior b)
	{
		if (b is GravityBehavior) return "Gravity";
		if (b is DragBehavior) return "Drag";
		if (b is WindBehavior) return "Wind";
		if (b is TurbulenceBehavior) return "Turbulence";
		if (b is VortexBehavior) return "Vortex";
		if (b is AttractorBehavior) return "Attractor";
		if (b is RadialForceBehavior) return "RadialForce";
		if (b is VelocityIntegrationBehavior) return "VelocityIntegration";
		if (b is ColorOverLifetimeBehavior) return "ColorOverLifetime";
		if (b is SizeOverLifetimeBehavior) return "SizeOverLifetime";
		if (b is SpeedOverLifetimeBehavior) return "SpeedOverLifetime";
		if (b is AlphaOverLifetimeBehavior) return "AlphaOverLifetime";
		if (b is RotationOverLifetimeBehavior) return "RotationOverLifetime";
		return "Unknown";
	}

	private static void SerializeBehavior(Serializer s, ParticleBehavior b)
	{
		let typeId = scope String(GetBehaviorTypeId(b));
		s.String("type", typeId);

		if (let g = b as GravityBehavior)
		{
			s.Float("multiplier", ref g.Multiplier);
			SerializeVector3(s, "direction", ref g.Direction);
		}
		else if (let d = b as DragBehavior)
			s.Float("drag", ref d.Drag);
		else if (let w = b as WindBehavior)
		{
			SerializeVector3(s, "force", ref w.Force);
			s.Float("turbulence", ref w.Turbulence);
		}
		else if (let t = b as TurbulenceBehavior)
		{
			s.Float("strength", ref t.Strength);
			s.Float("frequency", ref t.Frequency);
			s.Float("speed", ref t.Speed);
		}
		else if (let v = b as VortexBehavior)
		{
			s.Float("strength", ref v.Strength);
			SerializeVector3(s, "center", ref v.Center);
			SerializeVector3(s, "axis", ref v.Axis);
		}
		else if (let a = b as AttractorBehavior)
		{
			s.Float("strength", ref a.Strength);
			SerializeVector3(s, "position", ref a.Position);
			s.Float("radius", ref a.Radius);
		}
		else if (let r = b as RadialForceBehavior)
			s.Float("strength", ref r.Strength);
		else if (let col = b as ColorOverLifetimeBehavior)
			SerializeCurveColor(s, "curve", ref col.Curve);
		else if (let sz = b as SizeOverLifetimeBehavior)
			SerializeCurveVector2(s, "curve", ref sz.Curve);
		else if (let sp = b as SpeedOverLifetimeBehavior)
			SerializeCurveFloat(s, "curve", ref sp.Curve);
		else if (let al = b as AlphaOverLifetimeBehavior)
			SerializeCurveFloat(s, "curve", ref al.Curve);
		else if (let rot = b as RotationOverLifetimeBehavior)
			SerializeCurveFloat(s, "curve", ref rot.Curve);
		// VelocityIntegrationBehavior has no parameters
	}

	private static ParticleBehavior DeserializeBehavior(Serializer s)
	{
		let typeId = scope String();
		s.String("type", typeId);

		let b = ParticleTypeRegistry.CreateBehavior(typeId);
		if (b == null) return null;

		// Read parameters into the created instance
		SerializeBehavior(s, b); // re-enters but now in reading mode
		return b;
	}

	// ==================== Initializer Serialization ====================

	private static StringView GetInitializerTypeId(ParticleInitializer init)
	{
		if (init is PositionInitializer) return "Position";
		if (init is VelocityInitializer) return "Velocity";
		if (init is LifetimeInitializer) return "Lifetime";
		if (init is ColorInitializer) return "Color";
		if (init is SizeInitializer) return "Size";
		if (init is RotationInitializer) return "Rotation";
		return "Unknown";
	}

	private static void SerializeInitializer(Serializer s, ParticleInitializer init)
	{
		let typeId = scope String(GetInitializerTypeId(init));
		s.String("type", typeId);

		if (let p = init as PositionInitializer)
		{
			SerializeEmissionShape(s, "shape", ref p.Shape);
			s.Bool("localSpace", ref p.LocalSpace);
		}
		else if (let v = init as VelocityInitializer)
		{
			SerializeVector3(s, "baseVelocity", ref v.BaseVelocity);
			SerializeVector3(s, "randomness", ref v.Randomness);
			s.Float("shapeDirectionSpeed", ref v.ShapeDirectionSpeed);
			s.Float("velocityInheritance", ref v.VelocityInheritance);
		}
		else if (let l = init as LifetimeInitializer)
			SerializeRangeFloat(s, "lifetime", ref l.Lifetime);
		else if (let c = init as ColorInitializer)
			SerializeRangeColor(s, "color", ref c.Color);
		else if (let sz = init as SizeInitializer)
			SerializeRangeVector2(s, "size", ref sz.Size);
		else if (let r = init as RotationInitializer)
		{
			SerializeRangeFloat(s, "rotation", ref r.Rotation);
			SerializeRangeFloat(s, "rotationSpeed", ref r.RotationSpeed);
		}
	}

	private static ParticleInitializer DeserializeInitializer(Serializer s)
	{
		let typeId = scope String();
		s.String("type", typeId);

		let init = ParticleTypeRegistry.CreateInitializer(typeId);
		if (init == null) return null;

		SerializeInitializer(s, init);
		return init;
	}

	// ==================== Sub-emitter Link ====================

	private static void SerializeSubEmitterLink(Serializer s, ref SubEmitterLink link)
	{
		var trigger = (uint8)link.Trigger;
		s.UInt8("trigger", ref trigger);
		s.Int32("childSystemIndex", ref link.ChildSystemIndex);
		s.Int32("spawnCount", ref link.SpawnCount);
		s.Float("probability", ref link.Probability);
		s.Bool("inheritPosition", ref link.InheritPosition);
		s.Bool("inheritVelocity", ref link.InheritVelocity);
		s.Float("velocityInheritFactor", ref link.VelocityInheritFactor);
		s.Bool("inheritColor", ref link.InheritColor);

		if (s.IsReading)
			link.Trigger = (ParticleEventType)trigger;
	}

	// ==================== Primitive Helpers ====================

	private static void SerializeVector3(Serializer s, StringView name, ref Vector3 v)
	{
		s.BeginObject(name);
		s.Float("x", ref v.X);
		s.Float("y", ref v.Y);
		s.Float("z", ref v.Z);
		s.EndObject();
	}

	private static void SerializeVector2(Serializer s, StringView name, ref Vector2 v)
	{
		s.BeginObject(name);
		s.Float("x", ref v.X);
		s.Float("y", ref v.Y);
		s.EndObject();
	}

	private static void SerializeVector4(Serializer s, StringView name, ref Vector4 v)
	{
		s.BeginObject(name);
		s.Float("x", ref v.X);
		s.Float("y", ref v.Y);
		s.Float("z", ref v.Z);
		s.Float("w", ref v.W);
		s.EndObject();
	}

	private static void SerializeRangeFloat(Serializer s, StringView name, ref RangeFloat r)
	{
		s.BeginObject(name);
		s.Float("min", ref r.Min);
		s.Float("max", ref r.Max);
		s.EndObject();
	}

	private static void SerializeRangeVector2(Serializer s, StringView name, ref RangeVector2 r)
	{
		s.BeginObject(name);
		SerializeVector2(s, "min", ref r.Min);
		SerializeVector2(s, "max", ref r.Max);
		s.EndObject();
	}

	private static void SerializeRangeColor(Serializer s, StringView name, ref RangeColor r)
	{
		s.BeginObject(name);
		SerializeVector4(s, "min", ref r.Min);
		SerializeVector4(s, "max", ref r.Max);
		s.EndObject();
	}

	private static void SerializeEmissionShape(Serializer s, StringView name, ref EmissionShape shape)
	{
		s.BeginObject(name);
		var shapeType = (uint8)shape.Type;
		s.UInt8("type", ref shapeType);
		SerializeVector3(s, "size", ref shape.Size);
		s.Float("coneAngle", ref shape.ConeAngle);
		s.Float("arc", ref shape.Arc);
		s.Bool("emitFromSurface", ref shape.EmitFromSurface);
		if (s.IsReading)
			shape.Type = (EmissionShapeType)shapeType;
		s.EndObject();
	}

	private static void SerializeCurveFloat(Serializer s, StringView name, ref ParticleCurveFloat curve)
	{
		s.BeginObject(name);
		s.Int32("keyCount", ref curve.KeyCount);
		for (int32 k = 0; k < curve.KeyCount; k++)
		{
			s.BeginObject(scope $"key{k}");
			s.Float("time", ref curve.Keys[k].Time);
			s.Float("value", ref curve.Keys[k].Value);
			s.Float("tangentIn", ref curve.Keys[k].TangentIn);
			s.Float("tangentOut", ref curve.Keys[k].TangentOut);
			s.EndObject();
		}
		s.EndObject();
	}

	private static void SerializeCurveColor(Serializer s, StringView name, ref ParticleCurveColor curve)
	{
		s.BeginObject(name);
		s.Int32("keyCount", ref curve.KeyCount);
		for (int32 k = 0; k < curve.KeyCount; k++)
		{
			s.BeginObject(scope $"key{k}");
			s.Float("time", ref curve.Keys[k].Time);
			SerializeVector4(s, "color", ref curve.Keys[k].Color);
			s.EndObject();
		}
		s.EndObject();
	}

	private static void SerializeCurveVector2(Serializer s, StringView name, ref ParticleCurveVector2 curve)
	{
		s.BeginObject(name);
		s.Int32("keyCount", ref curve.KeyCount);
		for (int32 k = 0; k < curve.KeyCount; k++)
		{
			s.BeginObject(scope $"key{k}");
			s.Float("time", ref curve.Times[k]);
			SerializeVector2(s, "value", ref curve.Values[k]);
			SerializeVector2(s, "tangentIn", ref curve.TangentsIn[k]);
			SerializeVector2(s, "tangentOut", ref curve.TangentsOut[k]);
			s.EndObject();
		}
		s.EndObject();
	}
}
