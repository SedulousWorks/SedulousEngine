using Sedulous.Physics;

namespace Sedulous.Engine.Physics;

/// Where a physics component's runtime handle goes when the component does (removed, or its
/// entity destroyed): the scene's physics system, which drops it at its next reconcile in
/// dependency order, joints before the bodies they hold.
///
/// The system sets itself on the managers while its world runs. With none set there is no
/// world, and nothing to drop.
interface IPhysicsReleaser
{
	void ReleaseBody(BodyId body);
	void ReleaseCharacter(CharacterId character);
	void ReleaseJoint(JointId joint);
}
