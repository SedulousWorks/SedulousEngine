namespace Sedulous.Runtime.Client.Tests;

/// A tenth of a second per fixed step, with the runner's frame clamp at a quarter second:
/// enough to tell a clamped delta from an unclamped one by the step count alone.
class ClampApp : IApplication
{
	public CountingSubsystem Subsystem = null;
	public int FixedUpdates = 0;

	public ApplicationSettings Settings
	{
		get
		{
			var settings = ApplicationSettings();
			settings.FixedTimeStep = 0.1f;
			settings.MaxFrameTime = 0.25f;
			return settings;
		}
	}

	public void Configure(IApplicationHost host)
		=> Subsystem = host.Context.AddSubsystem<CountingSubsystem>();

	public void OnFixedUpdate(IApplicationHost host, float fixedDeltaTime) { FixedUpdates++; }
}
