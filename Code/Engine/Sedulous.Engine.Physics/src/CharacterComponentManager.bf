using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics;

/// The pool of characters.
class CharacterComponentManager : SerializableComponentManager<CharacterComponent>, ISceneCharacterMotion
{
	/// An animator walks its character by root motion through this, with no physics dependency:
	/// Move, which keeps gravity, jumps and collisions the controller's.
	public override ISceneCharacterMotion AsCharacterMotion => this;

	/// BORROWED: the scene's physics system while its world runs, else null.
	private IPhysicsReleaser mReleaser = null;

	/// The base's destructor sweeps the components through OnComponentDestroyed; mid teardown the
	/// physics system may be gone, so nothing is handed over then.
	public ~this()
	{
		mReleaser = null;
	}

	public void SetReleaser(IPhysicsReleaser releaser)
	{
		mReleaser = releaser;
	}

	public bool HasCharacter(EntityHandle entity) => Get(entity) != null;

	public void MoveCharacter(EntityHandle entity, Float3 velocity)
	{
		if (let character = Get(entity))
			character.Move(velocity.X, velocity.Z);
	}

	/// A removed component's character leaves the world with it.
	protected override void OnComponentDestroyed(CharacterComponent* component, EntityHandle entity)
	{
		if ((mReleaser != null) && component.Character.IsValid)
			mReleaser.ReleaseCharacter(component.Character);
		component.Character = .();
	}
}
