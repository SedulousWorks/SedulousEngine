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
/// The payload is reached through ISerializable, which the constraint here requires: the
/// component states how it is stored rather than a free Serialize being found by lookup.
class SerializableComponentManager<T> : ComponentManager<T>
	where T : struct, ISerializable, new
{
	private String mTypeId = new .() ~ delete _;
	private uint32 mDataVersion = 1;
	/// The oldest stored version a legacy reader accepts; nought is the current one alone.
	private uint32 mMinReadDataVersion = 0;

	public this()
	{
		EmitIdentity(typeof(T));
	}

	/// Reads the component's [SerializableComponent] at COMPILE time and bakes the two values
	/// in, rather than reconstructing the attribute on every manager built.
	///
	/// Comptime began as the only path that worked everywhere: Type.GetCustomAttribute has to
	/// CONSTRUCT the attribute to hand it back, construction goes through MethodInfo.Invoke,
	/// and the wasm runtime had no FFI to dispatch it, so this pool used to fatal on the web
	/// over an attribute that was plainly present. Invoke works on wasm now, so that is no
	/// longer the reason.
	///
	/// It stays comptime because it is simply better. The compiler reads the attribute and
	/// bakes the two values in, so building a pool costs nothing at run time, and a component
	/// missing its attribute is caught when it is compiled rather than when it is first
	/// constructed.
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
			code.Append(";\n");
			code.Append("mMinReadDataVersion = ");
			attribute.MinReadDataVersion.ToString(code);
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

		BeginVersionedPayload(ar, TypeIdOf(mTypeId), mDataVersion, mMinReadDataVersion);
		component.Serialize(ar);
		EndVersionedPayload(ar);
	}
}
