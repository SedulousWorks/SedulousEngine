using System;
using Sedulous.Core;

namespace Sedulous.Scene;

/// A system that moves characters (physics: its character controllers), for a system that does
/// not depend on it: an animator walking its character by the clip's root motion
/// (root-motion.md P2).
interface ISceneCharacterMotion
{
	/// Whether `entity` has a character this system moves.
	bool HasCharacter(EntityHandle entity);
	/// Its walking velocity (world, m/s; the horizontal part) until the next call: it keeps
	/// colliding and sliding, and gravity and jumps stay its own. Zero stops it.
	void MoveCharacter(EntityHandle entity, Float3 velocity);
}
