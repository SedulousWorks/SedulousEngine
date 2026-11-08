using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Edit mode Simulate over a page's scene: a snapshot taken, the scene started and run, the page's
/// command stack locked meanwhile (runtime mutations do not belong on the edit history, and undoing
/// into entities the restore recreates is a guid minefield); paused, the simulation holds; stopped,
/// the scene stops and the snapshot is restored into the same scene, so borrowed scene pointers
/// stay valid and the guid keyed selection resolves again (what the run spawned drops out). The
/// game's UI stays not interactive meanwhile: Simulate's pointer serves selection and the camera,
/// the Game tab is the interactive run. A simulated scene has no run, so the screens its scripts
/// push go on the GUI's unbound tier, which no tab draws; the page takes them down when the last
/// simulation stops (RunningCount). Out of the page's class, so the page stays the view and
/// this the run.
class SceneSimulation
{
	private SceneSnapshot mSnapshot = null ~ delete _;
	private bool mRunning = false;
	private bool mPaused = false;
	/// The simulations running across every page.
	private static int sRunning = 0;

	public bool IsRunning => mRunning;
	/// How many simulations run across every page: the GUI's unbound tier is theirs together.
	public static int RunningCount => sRunning;
	public bool IsPaused => mPaused;

	/// Snapshots `scene` and runs it, `commands` locked; false when it runs already or the
	/// snapshot failed (said in the log).
	public bool Start(Sedulous.Scene.Scene scene, EditorCommandStack commands)
	{
		if (mRunning)
			return false;
		delete mSnapshot;
		mSnapshot = SceneSnapshot.Capture(scene);
		if (mSnapshot == null)
		{
			GlobalLog(.Error, "Editor: Simulate: scene snapshot capture failed");
			return false;
		}
		scene.Start();
		scene.SetSimulationEnabled(true);
		commands.IsLocked = true;
		mRunning = true;
		mPaused = false;
		sRunning++;
		return true;
	}

	/// Holds or resumes a running simulation (the per frame freeze, not the start and stop
	/// callbacks the systems get on the big transitions).
	public void Pause(Sedulous.Scene.Scene scene, bool paused)
	{
		if (!mRunning)
			return;
		mPaused = paused;
		scene.SetSimulationEnabled(!paused);
	}

	/// Stops and restores the snapshot into `scene`, its resources resolved through `resources`
	/// (null: none), `commands` unlocked.
	public void Stop(Sedulous.Scene.Scene scene, EditorCommandStack commands, ResourceManager resources)
	{
		if (!mRunning)
			return;
		scene.Stop();
		if (mSnapshot != null)
		{
			if (mSnapshot.Restore(scene, resources) case .Err)
				GlobalLog(.Error, "Editor: Simulate: snapshot restore failed");
			DeleteAndNullify!(mSnapshot);
		}
		scene.SetSimulationEnabled(false);
		commands.IsLocked = false;
		mRunning = false;
		mPaused = false;
		sRunning--;
	}

	/// A page closing with its scene running: no restore (the scene is going), only the count.
	public void Abandon()
	{
		if (!mRunning)
			return;
		DeleteAndNullify!(mSnapshot);
		mRunning = false;
		mPaused = false;
		sRunning--;
	}
}
