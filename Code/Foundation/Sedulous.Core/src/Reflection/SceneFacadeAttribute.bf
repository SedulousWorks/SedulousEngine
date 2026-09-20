using System;

namespace Sedulous.Core;

/// A script facade over ONE scene: a plain class the engine does not otherwise know,
/// written in script shape, one instance per scene made on first use, reached through the
/// scene as `scene.<Name>`. It holds the scene and looks its systems up as it needs them,
/// so the script API is a layer of its own over the engine's: stable while the engine
/// refactors, shaped for a script, and the owner of verbs that touch two systems.
///
/// The class derives SceneFacade and is [Scriptable].
[AttributeUsage(.Class, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct SceneFacadeAttribute : Attribute
{
	public String Name;

	public this(String name)
	{
		Name = name;
	}
}

/// A script facade over the run: a Service role object reached by a global handle of
/// this name, installed on the run's runtime by the application, which knows what it
/// wraps. `[ScriptService, DisplayName("Audio")]` said the same in two attributes.
[AttributeUsage(.Class, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct ServiceFacadeAttribute : Attribute
{
	public String Name;

	public this(String name)
	{
		Name = name;
	}
}
