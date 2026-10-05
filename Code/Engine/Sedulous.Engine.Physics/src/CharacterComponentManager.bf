using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics;

/// The pool of characters.
class CharacterComponentManager : SerializableComponentManager<CharacterComponent>, ISceneCharacterMotion
{
	/// An animator walks its character by root motion through this, with no physics dependency:
	/// Move, which keeps gravity, jumps and collisions the controller's.
	public override ISceneCharacterMotion AsCharacterMotion => this;

	public bool HasCharacter(EntityHandle entity) => Get(entity) != null;

	public void MoveCharacter(EntityHandle entity, Float3 velocity)
	{
		if (let character = Get(entity))
			character.Move(velocity.X, velocity.Z);
	}

}
