using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Particles;

namespace Sedulous.Particles.Resource;

/// The effect's wire, in ONE bidirectional body per level.
///
/// The modules are POLYMORPHIC, which is why this is hand written rather than generated: an
/// effect is a graph of systems holding module lists whose element types are only known at
/// run time. Each module records its type NAME and its own parameters, and a read rebuilds it
/// through the serializable registry, which is the same machinery a content instance uses for
/// its record.
///
/// The GLOBAL registry, because a Serialize body is handed a serializer and nothing else: the
/// registry a content database was given does not reach this far. Registering the modules is
/// therefore a startup step, which is what ParticleResources.RegisterAll is for.
static class ParticleEffectSerialization
{
	/// The object behind an interface reference. Beef has no direct conversion between an
	/// interface and an unrelated class, so a polymorphic read has to come back through the
	/// object before it can be tested against the module base types.
	private static Object AsObject(ISerializable value) =>
		(value != null) ? Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(value)) : null;

	private static Object AsObject(ISerializer value) =>
		(value != null) ? Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(value)) : null;

	/// The serializer behind the interface, for the framing operations the interface does not
	/// carry. Null for a backend that is not one of Core's, which then gets no framing.
	private static Serializer AsSerializer(ISerializer ar) =>
		AsObject(ar) as Serializer;

	/// Reads or writes one module list.
	///
	/// Each module's parameters sit in a FRAMED REGION, so a module whose type this build does
	/// not know can be skipped: the frame records its length, and ending it lands on the next
	/// module whatever was left unread. Without the frame a binary stream is positional, and
	/// an unknown module would not be skipped but would silently shift everything after it.
	private static void SerializeInitializers(ISerializer ar, ParticleSystem system)
	{
		let reading = (ar.Mode == .Read);
		uint32 count = reading ? 0 : (uint32)system.InitializerCount;
		ar.Key("initializers");
		ar.BeginArray(ref count);

		let typeName = scope String();
		for (uint32 i = 0; i < count; i++)
		{
			ar.BeginObject();

			ParticleInitializer module = null;
			typeName.Clear();
			if (!reading)
			{
				module = system.GetInitializer((int32)i);
				module.GetType().GetFullName(typeName);
			}
			ar.Key("type");
			ar.Text(typeName);

			// Through Object, because Beef will not cast between an interface and an
			// unrelated class directly even when the runtime type satisfies both.
			if (reading)
				module = AsObject(GlobalSerializableRegistry.Create(TypeIdOf(typeName)))
					as ParticleInitializer;

			let framed = AsSerializer(ar);
			if (framed != null)
				framed.BeginFramedRegion();
			if (module != null)
				((ISerializable)module).Serialize(ar);
			if (framed != null)
				framed.EndFramedRegion();
			ar.EndObject();

			// Added AFTER its parameters are read, because adding declares its streams and a
			// module that was never constructed has none to declare.
			if (reading && (module != null))
				system.AddInitializer(module);
		}

		ar.EndArray();
	}

	private static void SerializeBehaviors(ISerializer ar, ParticleSystem system)
	{
		let reading = (ar.Mode == .Read);
		uint32 count = reading ? 0 : (uint32)system.BehaviorCount;
		ar.Key("behaviors");
		ar.BeginArray(ref count);

		let typeName = scope String();
		for (uint32 i = 0; i < count; i++)
		{
			ar.BeginObject();

			ParticleBehavior module = null;
			typeName.Clear();
			if (!reading)
			{
				module = system.GetBehavior((int32)i);
				module.GetType().GetFullName(typeName);
			}
			ar.Key("type");
			ar.Text(typeName);

			if (reading)
				module = AsObject(GlobalSerializableRegistry.Create(TypeIdOf(typeName)))
					as ParticleBehavior;

			let framed = AsSerializer(ar);
			if (framed != null)
				framed.BeginFramedRegion();
			if (module != null)
				((ISerializable)module).Serialize(ar);
			if (framed != null)
				framed.EndFramedRegion();
			ar.EndObject();

			if (reading && (module != null))
				system.AddBehavior(module);
		}

		ar.EndArray();
	}

	/// One system. The budget and the seed come FIRST, because on a read they are what the
	/// system has to be constructed with before anything else can be poured into it.
	private static void SerializeSystem(ISerializer ar, ParticleEffect effect, int32 index)
	{
		let reading = (ar.Mode == .Read);
		int32 maxParticles = reading ? 0 : effect.GetSystem(index).MaxParticles;
		uint64 seed = reading ? 0 : effect.GetSystem(index).Seed;
		SerializeValue(ar, "maxParticles", ref maxParticles);
		SerializeValue(ar, "seed", ref seed);

		let system = reading ? effect.AddSystem(maxParticles, seed) : effect.GetSystem(index);

		Serialize(ar, "name", system.Name);
		ar.Key("desiredMode");
		SerializeEnum(ar, ref system.DesiredMode);
		ar.Key("simSpace");
		SerializeEnum(ar, ref system.SimulationSpace);
		ar.Key("blend");
		SerializeEnum(ar, ref system.BlendMode);
		ar.Key("render");
		SerializeEnum(ar, ref system.RenderMode);

		SerializeValue(ar, "textureRef", ref system.TextureRef);
		SerializeValue(ar, "meshRef", ref system.MeshRef);
		SerializeValue(ar, "meshScale", ref system.MeshScale);
		ar.Key("materialRefs");
		SerializeList(ar, system.MaterialRefs);

		SerializeValue(ar, "sort", ref system.SortParticles);
		SerializeValue(ar, "soft", ref system.SoftParticles);
		SerializeValue(ar, "softDistance", ref system.SoftDistance);

		ar.Key("trail");
		system.Trail.Serialize(ar);
		ar.Key("flipbook");
		system.Flipbook.Serialize(ar);

		SerializeValue(ar, "prewarm", ref system.PrewarmTime);
		SerializeValue(ar, "lodStart", ref system.LodStartDistance);
		SerializeValue(ar, "lodCull", ref system.LodCullDistance);
		SerializeValue(ar, "lodMinRate", ref system.LodMinRate);

		ar.Key("emitter");
		ar.BeginObject();
		ar.Key("mode");
		SerializeEnum(ar, ref system.Emitter.Mode);
		SerializeValue(ar, "spawnRate", ref system.Emitter.SpawnRate);
		SerializeValue(ar, "burstCount", ref system.Emitter.BurstCount);
		SerializeValue(ar, "burstInterval", ref system.Emitter.BurstInterval);
		SerializeValue(ar, "burstCycles", ref system.Emitter.BurstCycles);
		SerializeValue(ar, "isEmitting", ref system.Emitter.IsEmitting);
		SerializeValue(ar, "duration", ref system.Emitter.Duration);
		SerializeValue(ar, "looping", ref system.Emitter.Looping);
		ar.EndObject();

		SerializeInitializers(ar, system);
		SerializeBehaviors(ar, system);
	}

	/// The whole effect. A READ APPENDS: the caller clears the effect first if it is reusing
	/// one.
	public static void SerializeEffect(ISerializer ar, ParticleEffect effect)
	{
		let reading = (ar.Mode == .Read);
		Serialize(ar, "name", effect.Name);

		uint32 systemCount = reading ? 0 : (uint32)effect.SystemCount;
		ar.Key("systems");
		ar.BeginArray(ref systemCount);
		for (uint32 i = 0; i < systemCount; i++)
		{
			ar.BeginObject();
			SerializeSystem(ar, effect, (int32)i);
			ar.EndObject();
		}
		ar.EndArray();

		uint32 linkCount = reading ? 0 : (uint32)effect.SubEmitterLinks.Length;
		ar.Key("links");
		ar.BeginArray(ref linkCount);
		for (uint32 i = 0; i < linkCount; i++)
		{
			ar.BeginObject();
			var link = reading ? SubEmitterLink() : effect.SubEmitterLinks[(int)i];
			link.Serialize(ar);
			ar.EndObject();
			if (reading)
				effect.AddSubEmitterLink(link);
		}
		ar.EndArray();
	}

	/// A deep copy through a serialize round trip, which is what the cook clones an authored
	/// effect with.
	///
	/// A round trip rather than a copy constructor because the modules are polymorphic: this
	/// is the one piece of code that already knows how to rebuild every one of them, and a
	/// hand written clone would be a second place to forget a new module type.
	public static Result<void, ErrorCode> CloneEffect(ParticleEffect source,
		ParticleEffect destination, SerializerFactory factory)
	{
		destination.Clear();

		let buffer = scope MemoryStream();
		{
			let context = factory(buffer, .Write);
			if (context == null)
				return .Err(.Internal);
			defer delete context;
			SerializeEffect(context.Serializer, source);
			context.Flush(buffer);
			if (!context.Serializer.IsPayloadOk)
				return .Err(.Internal);
		}

		buffer.Seek(0, .Begin);
		let context = factory(buffer, .Read);
		if (context == null)
			return .Err(.Internal);
		defer delete context;
		SerializeEffect(context.Serializer, destination);
		return context.Serializer.IsPayloadOk ? .Ok : .Err(.Internal);
	}
}
