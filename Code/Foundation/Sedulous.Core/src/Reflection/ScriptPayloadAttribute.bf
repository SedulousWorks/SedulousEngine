using System;

namespace Sedulous.Core;

/// A [Scriptable] type the engine publishes on the run's bus for a handler to take (a sequence's
/// notice, a dialogue's). Nothing on the surface names such a type, so this seeds it: without it
/// the surface would never reach the type, and a handler declaring it would not compile. The bus
/// bridge passes a struct carrying this by its bytes, and a class carrying it (weakly held,
/// IScriptWeaklyHeld) as a weak handle: the bus deletes the notice once delivered, so a handle a
/// script keeps past its handler reads as gone.
[AttributeUsage(.Struct | .Class, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct ScriptPayloadAttribute : Attribute
{
}
