using System;
using Sedulous.Core;

namespace Sedulous.Scene;

/// A system that knows how much of the world an entity takes up (render: its meshes;
/// physics: its colliders), for one that only wants the space: the editor framing a selection.
/// Neither side names the other's components; Scene.EntityWorldBounds merges every answer.
interface ISceneEntityBounds
{
	/// The world space box this system's components on `entity` fill. False when it has
	/// nothing on the entity to measure, or what it has is not loaded yet.
	bool EntityBounds(Scene scene, EntityHandle entity, out AABB outBounds);
}
