using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Scene;

/// A component pool whose components PERSIST.
///
/// Serialization is opt in: subclass this rather than ComponentManager when the components
/// should be saved, and a manager that says nothing simply is not written.
///
/// The identity on disk comes from the component's own [SerializableComponent] attribute,
/// not from this manager: the id describes the TYPE, and stating it here would let two
/// managers of the same component disagree about what it is called.
///
/// DIVERGES from Raptor in how the payload is reached. Raptor finds a free Serialize by
/// argument dependent lookup; Beef has no such thing, so the component states it by
/// implementing ISerializable, which the constraint here requires.
class SerializableComponentManager<T> : ComponentManager<T>
	where T : struct, ISerializable, new
{
	private String mTypeId = new .() ~ delete _;
	private uint32 mDataVersion = 1;

	public this()
	{
		EmitIdentity(typeof(T));
	}

	/// Reads the component's [SerializableComponent] at COMPILE time and bakes the two values
	/// in, rather than reconstructing the attribute on every manager built.
	///
	/// Comptime is not an optimisation here, it is the only path that works everywhere.
	/// Type.GetCustomAttribute has to CONSTRUCT the attribute to hand it back, and at runtime
	/// that construction goes through MethodInfo.Invoke, which is libffi. The wasm runtime is
	/// built with -DBF_DISABLE_FFI, so PrepCif answers NoFFI there and every runtime
	/// GetCustomAttribute returns Err: on the web this pool used to fatal on a component whose
	/// attribute was plainly present. Comptime reads it through the compiler and never calls a
	/// constructor at all. HasCustomAttribute stays usable at runtime, being a type id compare.
	///
	/// The message is built with Append rather than interpolation: comptime cannot evaluate an
	/// interpolated string, which boxes its arguments into a Span<Object>.
	[Comptime]
	private static void EmitIdentity(Type type)
	{
		String code = scope .();
		if (type.GetCustomAttribute<SerializableComponentAttribute>() case .Ok(let attribute))
		{
			code.Append("mTypeId.Set(\"");
			code.Append(attribute.TypeId);
			code.Append("\");\n");
			code.Append("mDataVersion = ");
			attribute.DataVersion.ToString(code);
			code.Append(";");
			Compiler.MixinRoot(code);
			return;
		}

		// EMITTED rather than asserted, because the UNSPECIALIZED generic is comptimed too and
		// carries no attribute: it is not a component yet, and it is never constructed either,
		// so the fatal it receives is unreachable. A concrete pool that really is missing its
		// attribute still fatals the moment it is built.
		//
		// Not a warning: a pool that cannot name itself cannot route a record back on load, so
		// every component it holds would be silently unreadable.
		code.Append("Runtime.FatalError(\"");
		type.GetFullName(code);
		code.Append(" is stored by a SerializableComponentManager but carries no ");
		code.Append("[SerializableComponent] attribute\");");
		Compiler.MixinRoot(code);
	}

	public override bool IsSerializable => true;
	public override StringView SerializationTypeId => mTypeId;

	public override void WriteComponent(ISerializer ar, EntityHandle entity)
	{
		var component = Get(entity);
		if (component == null)
			return;

		BeginVersionedPayload(ar, TypeIdOf(mTypeId), mDataVersion);
		component.Serialize(ar);
		EndVersionedPayload(ar);
	}

	public override void ReadComponent(ISerializer ar, EntityHandle entity)
	{
		// OVERWRITE when it is already there. A duplicate record, which is what a corrupt
		// save recovered by the loader produces, has to consume its payload rather than
		// trip the one-per-entity assert in Add and leave the stream mid record.
		var component = Get(entity);
		if (component == null)
			component = Add(entity);

		BeginVersionedPayload(ar, TypeIdOf(mTypeId), mDataVersion);
		component.Serialize(ar);
		EndVersionedPayload(ar);
	}
}
