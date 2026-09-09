namespace Sedulous.Navigation;

/// A snapshot of a live agent: the debugging window into WHY it is or is not moving.
struct NavigationAgentState
{
	public bool Valid = false;
	public NavAgentCrowdState State = .Invalid;
	public NavAgentTargetState TargetState = .None;
	/// What the crowd currently intends, which never exceeds the agent's maximum.
	public float DesiredSpeed = 0.0f;
	/// The corners still ahead, which is how far along its path it is.
	public int32 CornerCount = 0;

	public this() {}
}
