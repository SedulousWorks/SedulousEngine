namespace Sedulous.Navigation;

/// One agent's steering profile.
struct NavigationAgentParams
{
	public float Radius = 0.6f;
	public float Height = 2.0f;
	public float MaxSpeed = 3.5f;
	public float MaxAcceleration = 8.0f;

	public this() {}
}
