using System;

namespace Sedulous.Core;

/// Puts a scene system's or manager's entity-first method on the entity as well: a
/// `[Scriptable]` instance method whose first parameter is the entity handle is then also
/// called as `entity.Name(rest...)`, the entity's scene resolving the system.
///
/// The scene's own entity-first methods get this without asking, since the scene owns its
/// entities and `GetEntityName(entity)` IS the entity's name. A system's verb has to ask,
/// because `entity.Play()` could mean the animation, the audio or the particle effect, and
/// the surface refuses two of those on one entity. Ask only where the verb is the entity's,
/// as a message sent to it is.
[AttributeUsage(.Method, .ReflectAttribute)]
struct ScriptOnEntityAttribute : Attribute
{
}
