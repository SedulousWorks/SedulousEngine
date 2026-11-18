using System;
using System.Collections;
using System.Reflection;
using System.Threading;
using Sedulous.Core;

namespace Sedulous.Resource;

/// The resource ids a value names, read by reflection: every Ref<T> field, in a nested struct or
/// in a List<> field's elements (an element object's fields too), whatever T. Any other object a
/// field points at is runtime state (a manager, a GPU object, a pointer that may be stale) and is
/// not followed. What a holder answers the
/// manager with before it releases anything (a scene: its components and settings), so a
/// reference re-pointed by any path (a script, an agent's component_set, the inspector, an undo)
/// is seen without being told. A type's walk is planned once and cached.
static class ReferenceIds
{
	/// How deep a walk follows nested values: a reflected object graph may loop.
	private const int cMaxDepth = 8;

	private enum StepKind
	{
		/// A Ref<T>: its Id at the offset.
		Reference,
		/// A struct value: its own steps.
		Struct,
		/// A List<> field: its elements.
		List
	}

	private struct Step : this(StepKind Kind, int Offset, Type FieldType);

	private static Dictionary<Type, List<Step>> sPlans = new .() ~ DeleteDictionaryAndValues!(_);
	private static Monitor sLock = new .() ~ delete _;

	/// Adds the ids the value of `type` at `address` names to `outIds` (nil ids left out).
	public static void Collect(Type type, void* address, HashSet<Guid> outIds)
	{
		Walk(type, address, outIds, 0);
	}

	private static void Walk(Type type, void* address, HashSet<Guid> outIds, int depth)
	{
		if ((type == null) || (address == null) || (depth > cMaxDepth))
			return;
		if (ReferenceShape.IsBound(type))
		{
			AddId(type, address, outIds);
			return;
		}
		for (let step in PlanOf(type))
		{
			let at = (uint8*)address + step.Offset;
			switch (step.Kind)
			{
			case .Reference:
				AddId(step.FieldType, at, outIds);
			case .Struct:
				Walk(step.FieldType, at, outIds, depth + 1);
			case .List:
				WalkList(*(Object*)at as IReflectedList, outIds, depth + 1);
			}
		}
	}

	private static void WalkList(IReflectedList list, HashSet<Guid> outIds, int depth)
	{
		if ((list == null) || (depth > cMaxDepth))
			return;
		let element = list.ElementType;
		if (!MayHoldReferences(element))
			return;
		for (int i < list.Count)
		{
			let at = list.ElementAddress(i);
			if (!element.IsObject)
			{
				Walk(element, at, outIds, depth + 1);
				continue;
			}
			// An element object (an IK leg, a vegetation layer): its own fields, by its type.
			let obj = *(Object*)at;
			if (obj != null)
				Walk(obj.GetType(), Internal.UnsafeCastToPtr(obj), outIds, depth + 1);
		}
	}

	private static bool IsList(Type type)
	{
		let generic = type as SpecializedGenericType;
		return (generic != null) && (generic.UnspecializedType == typeof(List<>));
	}

	private static void AddId(Type type, void* at, HashSet<Guid> outIds)
	{
		if (ReferenceShape.Id(type, at) case .Ok(let id))
		{
			if (id != Guid.Empty)
				outIds.Add(id);
		}
	}

	/// Whether a value of `type` can hold a reference at all: a primitive, an enum or a string
	/// never does, so its walk is skipped.
	private static bool MayHoldReferences(Type type)
	{
		if ((type == null) || type.IsPrimitive || type.IsEnum || (type == typeof(String)) || (type == typeof(Guid)))
			return false;
		return true;
	}

	/// The steps a value of `type` takes: each field that is a reference, a struct that may hold
	/// one, or a List<>. Cached per type.
	private static List<Step> PlanOf(Type type)
	{
		using (sLock.Enter())
		{
			if (sPlans.TryGetValue(type, let cached))
				return cached;
			let steps = new List<Step>();
			sPlans[type] = steps;
			for (let field in type.GetFields())
			{
				if (field.IsStatic)
					continue;
				let fieldType = field.FieldType;
				if (!MayHoldReferences(fieldType))
					continue;
				if (ReferenceShape.IsBound(fieldType))
					steps.Add(.(.Reference, field.MemberOffset, fieldType));
				// A [Hidden] list holds runtime state, not data.
				else if (IsList(fieldType) && !field.HasCustomAttribute<HiddenAttribute>())
					steps.Add(.(.List, field.MemberOffset, fieldType));
				else if (fieldType.IsStruct && !fieldType.IsPointer)
					steps.Add(.(.Struct, field.MemberOffset, fieldType));
			}
			return steps;
		}
	}
}
