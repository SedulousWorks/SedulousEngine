namespace Sedulous.Engine.Input;

using Sedulous.Runtime;

/// Manages input device state and key mappings.
/// Runs very early (UpdateOrder -900) so input is available to all other systems.
class InputSubsystem : Subsystem
{
	public override int32 UpdateOrder => -900;

	protected override void OnInit()
	{
	}

	protected override void OnShutdown()
	{
	}

	public override void Update(float deltaTime)
	{
	}
}
