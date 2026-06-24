namespace TowerDefense;

using Sedulous.Engine.App;

/// Thin EngineApplication subclass: registers the TowerDefenseModule and
/// otherwise inherits everything. Configuration, startup, per-frame tick,
/// and shutdown all live on TowerDefenseModule via the IApplicationModule
/// hooks (Configure / OnStartup / OnLaunch / OnUpdate / OnExit / OnShutdown).
/// EngineApplication's main loop already dispatches Module.OnUpdate each
/// frame, so this subclass exists only to bind the module instance.
class TowerDefenseApp : EngineApplication
{
	private TowerDefenseModule mModule = new .() ~ delete _;

	public this()
	{
		Module = mModule;
	}
}
