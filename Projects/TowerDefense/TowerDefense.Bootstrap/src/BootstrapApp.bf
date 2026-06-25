namespace TowerDefense.Bootstrap;

using Sedulous.Engine.App;

/// EngineApplication subclass that hosts BootstrapModule. Wires the
/// module's ExitRequest delegate to its own Exit so the main loop
/// breaks out as soon as the bootstrap finishes its OnLaunch pass.
class BootstrapApp : EngineApplication
{
	private BootstrapModule mModule = new .() ~ delete _;

	public this()
	{
		mModule.ExitRequest = new => Exit;
		Module = mModule;
	}
}
