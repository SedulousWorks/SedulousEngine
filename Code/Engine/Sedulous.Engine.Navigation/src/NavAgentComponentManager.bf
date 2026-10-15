using System.Collections;
using Sedulous.Scene;

namespace Sedulous.Engine.Navigation;

/// The pool of navigation agents.
class NavAgentComponentManager : SerializableComponentManager<NavAgentComponent>
{
	/// An agent whose component went (its entity destroyed, or the component removed), for the
	/// navigation to take out of its crowd on its next update.
	public struct ReleasedAgent
	{
		public int32 ZoneIndex;
		public int32 AgentId;
	}

	/// Null once torn down: the base's destructor sweeps the components through
	/// OnComponentDestroyed after this class's own fields are gone.
	private List<ReleasedAgent> mReleased = new .();

	public ~this()
	{
		DeleteAndNullify!(mReleased);
	}

	/// The agents released since the last call, moved into `outReleased`.
	public void TakeReleased(List<ReleasedAgent> outReleased)
	{
		outReleased.AddRange(mReleased);
		mReleased.Clear();
	}

	protected override void OnComponentDestroyed(NavAgentComponent* component, EntityHandle entity)
	{
		if ((mReleased != null) && (component.AgentId >= 0))
			mReleased.Add(.() { ZoneIndex = component.ZoneIndex, AgentId = component.AgentId });
	}
}
