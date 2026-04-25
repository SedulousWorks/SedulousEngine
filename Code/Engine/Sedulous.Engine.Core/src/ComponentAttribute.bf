namespace Sedulous.Engine.Core;

using System;

/// Marks a class as a scene component, enabling runtime reflection for editor inspection.
/// All public instance fields become visible to the reflection inspector.
[AttributeUsage(.Class, .ReflectAttribute, ReflectUser = .All)]
struct ComponentAttribute : Attribute
{
}
