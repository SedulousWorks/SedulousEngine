using System;
using Sedulous.Scene;

namespace Sedulous.Script;

/// The core carries an entity opaquely, an index, a generation and an owner object, so it
/// depends on no scene. These read the same values as the scene's types; a project that
/// knows scenes, and the code a surface root emits, reaches them through this one.

extension ScriptEntity
{
	public this(EntityHandle handle, Scene scene) : this(handle.Index, handle.Generation, scene) {}

	public EntityHandle Handle
	{
		get => .(Index, Generation);
		set mut { Index = value.Index; Generation = value.Generation; }
	}

	public Scene Scene
	{
		get => Owner as Scene;
		set mut { Owner = value; }
	}
}

extension ScriptValue
{
	public static ScriptValue FromEntity(EntityHandle v, Scene scene = null) => FromEntityRef(.(v.Index, v.Generation, scene));

	public EntityHandle AsEntity => .(Data.Entity.Index, Data.Entity.Generation);
	/// The scene an entity value names, null when it names none.
	public Scene AsEntityScene => AsEntityOwner as Scene;
}

extension ScriptCallContext
{
	/// The ambient owner as a scene, null when it is none.
	public Scene Scene
	{
		get => AmbientOwner as Scene;
		set => AmbientOwner = value;
	}
}

extension ScriptCallFrame
{
	/// The scene an entity value resolves in: its own, else the context's.
	public Scene SceneOf(ScriptValue entity) => entity.AsEntityScene ?? Context.Scene;
}
