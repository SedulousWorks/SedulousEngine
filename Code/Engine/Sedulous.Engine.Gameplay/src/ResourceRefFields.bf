using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core.Serialization;

namespace Sedulous.Engine.Gameplay;

/// The asset references a game class saves, found at compile time: what its resolve binds. A
/// behaviour and a level write no resolve of their own, where a component implements
/// IComponentResources by hand.
static class ResourceRefFields
{
	/// Appends `<target>.<field>.Bind(manager);` for each public, saved Ref<T> field of `type`
	/// and its bases below `stopAt`, base first. Nothing for the unspecialized generic.
	[Comptime]
	public static void AppendBinds(Type type, Type stopAt, StringView target, String outCode)
	{
		if (!(type is TypeInstance))
			return;
		let chain = scope List<Type>();
		for (var walk = type; (walk != null) && (walk != stopAt); walk = walk.BaseType)
			chain.Add(walk);
		for (int i = chain.Count - 1; i >= 0; i--)
		{
			let declaring = chain[i];
			for (let field in declaring.GetFields())
			{
				if (!field.IsInstanceField || !field.IsPublic || (field.DeclaringType != declaring))
					continue;
				if (field.GetCustomAttribute<NotSerializedAttribute>() case .Ok)
					continue;
				if (!IsResourceRef(field.FieldType))
					continue;
				outCode.Append(target);
				outCode.Append('.');
				outCode.Append(field.Name);
				outCode.Append(".Bind(manager);\n");
			}
		}
	}

	/// Appends `if (<target>.<field>.Id != Guid()) outIds.Add(<target>.<field>.Id);` for each
	/// public, saved id reference field of `type` (a SceneRef: [IdReference]) and its bases below
	/// `stopAt`, base first: the ids nothing binds, which a pruned export follows. Nothing for the
	/// unspecialized generic.
	[Comptime]
	public static void AppendIdReferences(Type type, Type stopAt, StringView target, String outCode)
	{
		if (!(type is TypeInstance))
			return;
		let chain = scope List<Type>();
		for (var walk = type; (walk != null) && (walk != stopAt); walk = walk.BaseType)
			chain.Add(walk);
		for (int i = chain.Count - 1; i >= 0; i--)
		{
			let declaring = chain[i];
			for (let field in declaring.GetFields())
			{
				if (!field.IsInstanceField || !field.IsPublic || (field.DeclaringType != declaring))
					continue;
				if (field.GetCustomAttribute<NotSerializedAttribute>() case .Ok)
					continue;
				if (!field.FieldType.IsStruct || !(field.FieldType.GetCustomAttribute<Sedulous.Resource.IdReferenceAttribute>() case .Ok))
					continue;
				outCode.Append("if (");
				outCode.Append(target);
				outCode.Append('.');
				outCode.Append(field.Name);
				outCode.Append(".Id != System.Guid()) outIds.Add(");
				outCode.Append(target);
				outCode.Append('.');
				outCode.Append(field.Name);
				outCode.Append(".Id);\n");
			}
		}
	}

	/// Whether `type` is a Ref<T>. Matched by name, as the serializer matches a List.
	[Comptime]
	public static bool IsResourceRef(Type type)
	{
		if (type == null)
			return false;
		let name = scope String();
		type.GetFullName(name);
		return name.StartsWith("Sedulous.Resource.Ref<");
	}
}
