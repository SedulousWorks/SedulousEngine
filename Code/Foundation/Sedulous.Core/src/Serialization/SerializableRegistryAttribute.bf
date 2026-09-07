using System;
using System.Reflection;

namespace Sedulous.Core.Serialization;

/// Generates a RegisterAll that registers every [Serializable] type declared in the
/// project this is applied in.
///
/// Raptor maintains that list by hand, which is a second place to update and a silent
/// failure when someone forgets: the type simply never loads. Here it is read off the
/// declarations, so forgetting is not available.
///
/// Registers the [Serializable] types declared in the NAMESPACE this is applied in.
///
/// Scoped that way because comptime can enumerate every type in the compilation, including
/// ones this project cannot name: a sibling project's types are visible to the enumeration
/// and invisible to the emitted code. A project that owns types in several namespaces
/// applies this once per namespace.
///
/// Calling RegisterAll stays explicit, because when the table is populated is the
/// application's business, not Core's.
[AttributeUsage(.Class, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct SerializableRegistryAttribute : Attribute, IComptimeTypeApply
{
	[Comptime]
	public void ApplyToType(Type type)
	{
		// Scoped to the namespace this is applied in. Comptime can enumerate every type in
		// the compilation, including ones this project cannot NAME: a sibling project's
		// types are visible to the enumeration and invisible to the emitted code, and
		// registering them would emit a reference that does not compile. The namespace is
		// the honest approximation of "the types this project owns".
		let owner = scope String();
		type.GetFullName(owner);
		let lastDot = owner.LastIndexOf('.');
		let namespacePrefix = scope String();
		if (lastDot > 0)
		{
			namespacePrefix.Append(StringView(owner, 0, lastDot));
			namespacePrefix.Append('.');
		}

		let body = scope String();
		body.AppendF("/// Registers every [Serializable] type under {}\n", namespacePrefix);
		body.Append("///\n");
		body.Append("/// Into the global registry unless another is given, which is how a caller runs two\n");
		body.Append("/// tables with different registrations in one process.\n");
		body.Append("public static void RegisterAll(Sedulous.Core.Serialization.SerializableRegistry registry = null)\n{\n");
		body.Append("\tlet target = (registry != null) ? registry : Sedulous.Core.Serialization.GlobalSerializableRegistry;\n");

		for (let declaration in Type.TypeDeclarations)
		{
			if (!declaration.HasCustomAttribute<SerializableAttribute>())
				continue;

			let name = scope:: String();
			declaration.GetFullName(name);
			if (!namespacePrefix.IsEmpty && !name.StartsWith(namespacePrefix))
				continue;

			body.AppendF("\ttarget.Register({}.TypeId, () => new {}());\n", name, name);
		}

		body.Append("}\n");
		Compiler.EmitTypeBody(type, body);
	}
}
