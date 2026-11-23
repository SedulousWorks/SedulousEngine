using System;
using Sedulous.Core;

namespace Sedulous.Scene;

/// What one value of an entity event is.
enum EntityEventArgKind
{
	Bool,
	Int,
	Float,
	String,
	Guid,
	Float3,
	/// Another entity (a contact's other side), which a listener turns into its own kind of entity.
	Entity
}

/// One value of an entity event: a contact's other side, its point, its speed; an animation's clip.
/// A string is BORROWED for the post's length, as the event is.
struct EntityEventArg
{
	public EntityEventArgKind Kind;
	public bool Bool;
	public int64 Int;
	public double Float;
	public StringView String;
	public Guid Guid;
	public Float3 Float3;
	public EntityHandle Entity;

	public static Self FromBool(bool v) { var r = Self(); r.Kind = .Bool; r.Bool = v; return r; }
	public static Self FromInt(int64 v) { var r = Self(); r.Kind = .Int; r.Int = v; return r; }
	public static Self FromFloat(double v) { var r = Self(); r.Kind = .Float; r.Float = v; return r; }
	public static Self FromString(StringView v) { var r = Self(); r.Kind = .String; r.String = v; return r; }
	public static Self FromGuid(Guid v) { var r = Self(); r.Kind = .Guid; r.Guid = v; return r; }
	public static Self FromFloat3(Float3 v) { var r = Self(); r.Kind = .Float3; r.Float3 = v; return r; }
	public static Self FromEntity(EntityHandle v) { var r = Self(); r.Kind = .Entity; r.Entity = v; return r; }
}

/// Something that happened to one entity, told to whatever listens on its scene (the entity's
/// behaviors): a contact, an animation ending. `Name` is the event's ("contactBegin",
/// "animationFinished") and `Args` its values in order. Borrowed for the post's length only.
struct EntityEvent
{
	public EntityHandle Target;
	public StringView Name;
	public Span<EntityEventArg> Args;

	public this(EntityHandle target, StringView name, Span<EntityEventArg> args = default)
	{
		Target = target;
		Name = name;
		Args = args;
	}
}

/// Listens to a scene's entity events (Scene.AddEntityEventSink). A domain posts to the scene and
/// knows nothing of who listens, so physics and animation need no behavior layer.
interface IEntityEventSink
{
	/// Called during the post. Enqueue only: never call into a behavior from here, since the poster
	/// may be mid-step (physics) and a behavior's call may change the scene under it.
	void OnEntityEvent(Scene scene, EntityEvent entityEvent);
}
