using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;

namespace Sedulous.PropertyAnimation;

/// Resolving a dot joined property path against a reflected type, and reading or writing the
/// leaf through it.
///
/// Reflection ONLY, with no scene dependency at all: the caller hands over a component
/// instance, and the engine is what binds an entity to a component. That is what lets a
/// headless consumer, an editor page or a test, evaluate a clip without any of the scene.
///
/// Beef's reflection IS the language's, so the chain here is the language's own field
/// descriptions rather than a parallel set of them. A type must be marked for reflection
/// for its fields to be found.
static class PropertyBindingResolver
{
	/// Resolves a dot joined path against a type, walking a nested struct for each
	/// intermediate segment.
	///
	/// Answers an UNRESOLVED binding when a segment is missing, or when an intermediate one is
	/// not something that can be walked into. Pure over the static metadata: no instance is
	/// touched.
	public static void Resolve(Type componentType, StringView propertyPath,
		PropertyBinding outBinding)
	{
		outBinding.Clear();
		if (propertyPath.IsEmpty || (componentType == null))
			return;

		var current = componentType;
		var start = 0;

		while (true)
		{
			var dot = start;
			while ((dot < propertyPath.Length) && (propertyPath[dot] != '.'))
				dot++;

			let segment = propertyPath.Substring(start, dot - start);
			if (segment.IsEmpty || (current == null))
			{
				outBinding.Clear();
				return;
			}

			let name = scope String(segment);
			if (!(current.GetField(name) case .Ok(let field)))
			{
				outBinding.Clear();
				return;
			}
			outBinding.Add(field);

			let isLast = (dot >= propertyPath.Length);
			if (isLast)
				break;

			// An intermediate segment has to be something with fields of its own, or there is
			// nowhere further to walk.
			if (!CanWalkInto(field.FieldType))
			{
				outBinding.Clear();
				return;
			}

			current = field.FieldType;
			start = dot + 1;
		}
	}

	/// Writes a value through a resolved binding.
	///
	/// The nested sub objects are re-derived from the LIVE instance every call, never cached.
	/// Fails for an unresolved binding, an absent instance, or a value whose kind does not
	/// match the leaf.
	public static Result<void> Write(PropertyBinding binding, Object instance,
		PropertyValue value)
	{
		if (instance == null)
			return .Err;
		return Write(binding, Internal.UnsafeCastToPtr(instance), instance.GetType(), value);
	}

	/// The same write against a RAW instance: an address and the type that describes it.
	///
	/// What an engine component needs. A component lives as a struct inside its manager's
	/// packed pool rather than as an object, so there is no reference to hand over, and the
	/// pool's storage moves under it as components are added and removed. Nothing is cached:
	/// the caller re-derives the address every write and this walks from it afresh.
	public static Result<void> Write(PropertyBinding binding, void* instance, Type instanceType,
		PropertyValue value)
	{
		if ((binding == null) || !binding.IsResolved || (instance == null)
			|| (instanceType == null) || !value.HasValue)
			return .Err;

		void* address = ?;
		Type ownerType = ?;
		if (!(WalkToLeafOwner(binding, instance, instanceType, out address, out ownerType)
			case .Ok))
			return .Err;

		let leaf = binding.Chain[binding.Chain.Length - 1];
		var target = Variant.CreateReference(ownerType, address);

		var converted = Variant();
		if (!(MakeVariant(leaf.FieldType, value, out converted) case .Ok))
			return .Err;
		defer converted.Dispose();

		if (leaf.SetValue(target, converted) case .Err)
			return .Err;
		return .Ok;
	}

	/// Reads the leaf's current value through a resolved binding, which is the inverse of a
	/// write and what SNAPSHOTS a property before a transient one.
	///
	/// Answers an empty value for an unresolved binding, an absent instance, or a leaf whose
	/// type is not one a track animates.
	public static PropertyValue Read(PropertyBinding binding, Object instance)
	{
		if (instance == null)
			return .Empty;
		return Read(binding, Internal.UnsafeCastToPtr(instance), instance.GetType());
	}

	/// The same read against a RAW instance, for the same reason the raw write exists.
	public static PropertyValue Read(PropertyBinding binding, void* instance, Type instanceType)
	{
		if ((binding == null) || !binding.IsResolved || (instance == null)
			|| (instanceType == null))
			return .Empty;

		void* address = ?;
		Type ownerType = ?;
		if (!(WalkToLeafOwner(binding, instance, instanceType, out address, out ownerType)
			case .Ok))
			return .Empty;

		let leaf = binding.Chain[binding.Chain.Length - 1];
		let target = Variant.CreateReference(ownerType, address);

		if (!(leaf.GetValue(target) case .Ok(var stored)))
			return .Empty;
		defer stored.Dispose();

		if (leaf.FieldType == typeof(float))
			return .FromFloat(stored.Get<float>());
		if (leaf.FieldType == typeof(Float3))
			return .FromFloat3(stored.Get<Float3>());
		if (leaf.FieldType == typeof(Color))
			return .FromColor(stored.Get<Color>());
		if (leaf.FieldType == typeof(Quaternion))
			return .FromQuaternion(stored.Get<Quaternion>());

		return .Empty;
	}

	/// Whether an intermediate segment's type can be walked into for a further segment.
	private static bool CanWalkInto(Type type)
	{
		if (type == null)
			return false;
		// A leaf value is the end of the path even though it has fields of its own: a vector's
		// components are not separately animated, the whole vector is.
		if ((type == typeof(float)) || (type == typeof(Float3)) || (type == typeof(Color))
			|| (type == typeof(Quaternion)))
			return false;

		return type.IsStruct || type.IsObject;
	}

	/// Walks the chain down to the leaf's OWNER, answering that owner's address and type. The
	/// walk starts fresh from the live instance every time.
	private static Result<void> WalkToLeafOwner(PropertyBinding binding, void* instance,
		Type instanceType, out void* address, out Type ownerType)
	{
		address = instance;
		ownerType = instanceType;

		let chain = binding.Chain;
		for (int i = 0; (i + 1) < chain.Length; i++)
		{
			let field = chain[i];
			if (field.FieldType == null)
				return .Err;

			// A reference member is followed through, and a value member is simply an offset
			// within what already holds it.
			if (field.FieldType.IsObject)
			{
				let nested = *(Object*)((uint8*)address + field.MemberOffset);
				if (nested == null)
					return .Err;
				address = Internal.UnsafeCastToPtr(nested);
				ownerType = nested.GetType();
			}
			else
			{
				address = (uint8*)address + field.MemberOffset;
				ownerType = field.FieldType;
			}
		}

		return .Ok;
	}

	/// Boxes a sampled value as the leaf's own type, refusing a mismatch rather than writing
	/// the wrong bytes into it.
	private static Result<void> MakeVariant(Type fieldType, PropertyValue value,
		out Variant outVariant)
	{
		outVariant = .();

		switch (value.Kind)
		{
		case .Float:
			if (fieldType != typeof(float))
				return .Err;
			outVariant = Variant.Create<float>(value.Scalar);

		case .Float3:
			if (fieldType != typeof(Float3))
				return .Err;
			outVariant = Variant.Create<Float3>(value.Vector);

		case .Color:
			if (fieldType != typeof(Color))
				return .Err;
			outVariant = Variant.Create<Color>(value.Color);

		case .Quat:
			if (fieldType != typeof(Quaternion))
				return .Err;
			outVariant = Variant.Create<Quaternion>(value.Rotation);
		}

		return .Ok;
	}
}
