using System;
using System.Collections;

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
