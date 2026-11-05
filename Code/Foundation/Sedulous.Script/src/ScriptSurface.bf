using System;
using System.Collections;
using Sedulous.Core; // the hashes, and the runtime domain

namespace Sedulous.Script;

/// The set of types a script may reach, as data.
///
/// A composition root populates one at startup from the table its comptime walk emitted,
/// tagging every type with its domain. A backend binds from it; a describing host, the
/// MCP server say, reads it with no VM at all; a host holding a wider surface than a
/// script is allowed validates against the domains that script may use.
class ScriptSurface
{
	public List<ScriptTypeInfo> Types = new .() ~ DeleteContainerAndItems!(_);

	/// A hash of what a player's scripts compile against: every runtime-domain type, its name,
	/// kind, fields, methods and enum values, whatever order they were added in (a sum of each
	/// type's hash). Another domain's types stay out, so every host that cooks gets the same answer
	/// for the same build.
	public uint64 RuntimeHash()
	{
		uint64 sum = 0;
		for (let t in Types)
		{
			if (t.Domain != ScriptDomains.Runtime)
				continue;
			var h = HashText(t.FullName);
			h = Mix(h, (uint64)t.Kind);
			for (let field in t.Fields)
			{
				h = Mix(h, HashText(field.Name));
				h = Mix(h, HashText(field.TypeName));
				h = Mix(h, (field.IsStatic ? (uint64)2 : (uint64)0) | (field.CanWrite ? (uint64)1 : (uint64)0));
			}
			for (let method in t.Methods)
			{
				h = Mix(h, HashText(method.Name));
				h = Mix(h, HashText(method.ReturnTypeName));
				h = Mix(h, (method.IsStatic ? (uint64)2 : (uint64)0) | (method.IsConstructor ? (uint64)1 : (uint64)0));
				for (let param in method.Params)
				{
					h = Mix(h, HashText(param.TypeName));
					h = Mix(h, param.IsByRef ? (uint64)1 : (uint64)0);
				}
			}
			for (let value in t.EnumValues)
			{
				h = Mix(h, HashText(value.Name));
				h = Mix(h, (uint64)value.Value);
			}
			sum += HashInteger(h); // a sum: the order the types were added in does not matter
		}
		return sum;
	}

	private static uint64 Mix(uint64 hash, uint64 value)
	{
		var copy = value;
		return HashBytes(&copy, sizeof(uint64), hash);
	}

	public ScriptTypeInfo AddType(StringView fullName, ScriptTypeKind kind, StringView domain)
	{
		let t = new ScriptTypeInfo();
		t.FullName.Set(fullName);
		t.Kind = kind;
		t.Domain.Set(domain);

		if (kind == .Global)
		{
			t.Namespace.Set(fullName);
		}
		else
		{
			let dot = fullName.LastIndexOf('.');
			if (dot >= 0)
			{
				t.Namespace.Set(fullName.Substring(0, dot));
				t.Name.Set(fullName.Substring(dot + 1));
			}
			else
			{
				t.Name.Set(fullName);
			}
		}

		Types.Add(t);
		return t;
	}

	public ScriptTypeInfo Find(StringView fullName)
	{
		for (let t in Types)
		{
			if (t.FullName == fullName)
				return t;
		}
		return null;
	}

	/// The distinct domains present, in first seen order.
	public void CollectDomains(List<String> outDomains)
	{
		for (let t in Types)
		{
			bool seen = false;
			for (let d in outDomains)
			{
				if (d == t.Domain)
				{
					seen = true;
					break;
				}
			}
			if (!seen)
				outDomains.Add(new String(t.Domain));
		}
	}
}
