using System;

namespace Sedulous.Core;

/// A [Scriptable] struct the engine publishes on the run's bus for a handler to take by value (a
/// sequence's notice). Nothing on the surface names such a type, so this seeds it: without it
/// the surface would never reach the type, and a handler declaring it would not compile. The bus
/// bridge passes a payload of a type carrying this by its bytes.
[AttributeUsage(.Struct, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct ScriptPayloadAttribute : Attribute
{
}
