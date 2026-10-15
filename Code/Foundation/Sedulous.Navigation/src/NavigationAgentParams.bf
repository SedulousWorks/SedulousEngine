namespace Sedulous.Navigation;

/// One agent's steering profile.
struct NavigationAgentParams
{
	public float Radius = 0.6f;
	public float Height = 2.0f;
	public float MaxSpeed = 3.5f;
	public float MaxAcceleration = 8.0f;
	/// Steer round the others (velocity sampled avoidance and separation). Off, the agent goes
	/// straight where it is sent (a player's character) and shoulders past anyone in its way:
	/// the crowd's collision step pushes the two apart, softly.
	public bool AvoidOthers = true;

	public this() {}
}
