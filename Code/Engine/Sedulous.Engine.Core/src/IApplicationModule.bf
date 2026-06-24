namespace Sedulous.Engine;

using Sedulous.Runtime;
using Sedulous.Resources;

/// Composition contract for the payload an application hosts.
///
/// An IApplicationModule describes what an application "is" without saying
/// how it runs - it registers subsystems and performs lifecycle hooks against
/// a Context, but does not itself tick. Per-frame logic lives in the Subsystems
/// the module registers (gated by Subsystem update phase + SceneModule
/// simulationOnly when applicable).
///
/// Hosts:
///   - EngineApplication (standalone game exe) invokes a single module's
///     lifecycle around its main loop.
///   - Editor (in a later phase) instantiates a project's module at project
///     load time so the project's component types and subsystems are visible
///     in the inspector and on scenes during edit mode. Play / Simulate
///     buttons drive Scene.Start() / Scene.Stop(); the module itself does
///     not have a Play lifecycle - simulation gating belongs to the scene.
public interface IApplicationModule
{
	/// Register subsystems and component types with the context.
	/// Called once after the host registers its default subsystems and before
	/// Context.Startup() runs. The module may add Subsystems, set application-
	/// wide configuration, or hook ResourceSystem extensions here.
	void Configure(Context context, ResourceSystem resources);

	/// One-time startup hook fired after Context.Startup() completes.
	/// All subsystems are initialized at this point. Typical work: load the
	/// initial scene, hook a message bus, register editor metadata.
	void OnStartup(Context context, ResourceSystem resources);

	/// Symmetric teardown hook fired before Context.Shutdown().
	/// Subsystems are still alive at this point so the module can publish
	/// final state or release references it owns.
	void OnShutdown(Context context, ResourceSystem resources);
}
