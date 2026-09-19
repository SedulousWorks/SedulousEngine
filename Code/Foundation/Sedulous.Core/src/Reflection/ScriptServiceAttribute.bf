using System;

namespace Sedulous.Core;

/// Gives a scriptable class the Service role without a Subsystem base: a script reaches one
/// instance of it through a handle named after the class, and a call resolves the instance
/// the run's context holds. A subsystem is a service by its base; a per run object, the
/// game instance a script calls `Run`, is one by this.
[AttributeUsage(.Class, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct ScriptServiceAttribute : Attribute
{
}
