using System;

namespace Sedulous.Scene;

/// Marks a value type as a COMPONENT.
///
/// It carries no data of its own. What it does is force reflection on the type's fields,
/// which is what lets the engine find and rewrite the entity references inside a component
/// without a line of per component code: spawning a prefab has to remap an EntityRef field
/// that points INSIDE the template, and it can only do that if it can see the field.
///
/// Beef's reflection is opt in, so a component that simply forgot to ask would have its
/// references silently left pointing at the template. Attaching the reflection to the
/// attribute that says "this is a component" removes the chance to forget: declaring one
/// IS asking.
///
/// Its default constructor is reflected too: an inspector's Reset reads the type's defaults
/// from an instance it makes.
[AttributeUsage(.Struct, .ReflectAttribute, ReflectUser = .Type | .NonStaticFields | .DefaultConstructor)]
struct ComponentAttribute : Attribute
{
}
