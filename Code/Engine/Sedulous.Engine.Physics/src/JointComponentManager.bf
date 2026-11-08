using Sedulous.Scene;

namespace Sedulous.Engine.Physics;

/// The pool of joints.
class JointComponentManager : SerializableComponentManager<JointComponent>
{
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

	/// A removed component's joint leaves the world with it.
	protected override void OnComponentDestroyed(JointComponent* component, EntityHandle entity)
	{
		if ((mReleaser != null) && component.Joint.IsValid)
			mReleaser.ReleaseJoint(component.Joint);
		component.Joint = .();
	}
}
