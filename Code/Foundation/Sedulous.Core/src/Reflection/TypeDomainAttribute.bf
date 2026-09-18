using System;

namespace Sedulous.Core;

/// Which processes carry this type, so a generator can leave out what its target cannot
/// have.
///
/// An OPEN SET named by string, not an enum, which is Raptor's shape and the right one: a
/// layer that did not exist when this was written can name its own domain without editing
/// Core. [[ScriptDomains]] holds the names Core itself knows.
///
/// Absent means [[ScriptDomains.Runtime]]. Everything the player runs is that, so the
/// common case carries no annotation and only the exceptions are marked.
///
/// A DECLARATION, not an enforcement. Nothing stops an editor type being referenced from
/// runtime code; what this does is let a generator emitting a runtime script module leave
/// out the editor's types, and let a browser mark what it shows. Raptor is explicit on the
/// same point: tooling reads it and runtime behaviour never depends on it.
[AttributeUsage(.Types, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct TypeDomainAttribute : Attribute
{
	public String Domain;

	public this(String domain)
	{
		Domain = domain;
	}
}
