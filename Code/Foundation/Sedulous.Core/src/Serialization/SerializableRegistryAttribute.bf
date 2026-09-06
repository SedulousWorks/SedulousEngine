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
/// Every [Serializable] type VISIBLE from the applying project is registered, its own and
/// its dependencies'. Registering a dependency's type twice is harmless, since the later
/// registration replaces the earlier with the same thing.
///
/// Calling RegisterAll stays explicit, because when the table is populated is the
/// application's business, not Core's.
[AttributeUsage(.Class, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct SerializableRegistryAttribute : Attribute, IComptimeTypeApply
{
	[Comptime]
	public void ApplyToType(Type type)
	{
		let body = scope String();
		body.Append("/// Registers every [Serializable] type declared in this project.\n");
		body.Append("public static void RegisterAll()\n{\n");

		for (let declaration in Type.TypeDeclarations)
		{
			if (!declaration.HasCustomAttribute<SerializableAttribute>())
				continue;

			let name = scope:: String();
			declaration.GetFullName(name);
			body.AppendF("\tSedulous.Core.Serialization.SerializableRegistry.Register({}.TypeId, () => new {}());\n", name, name);
		}

		body.Append("}\n");
		Compiler.EmitTypeBody(type, body);
	}
}
