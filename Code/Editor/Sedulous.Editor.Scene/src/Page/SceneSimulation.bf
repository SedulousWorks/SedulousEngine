using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Resource;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// A scene page's run: its Simulate's screens and sounds. It holds nothing a game has (no input
/// map, save, network or `Run` service), as Simulate has none of those.
class SimulationRun : RunBase
{
	public this(StringView name) : base(name)
	{
	}

	public ~this()
	{
		// Disposed here, so the run's manager hears it go while the run is whole.
		Dispose();
	}
}

/// Edit mode Simulate over a page's scene: a snapshot taken, the scene started and run, the page's
/// command stack locked meanwhile (runtime mutations do not belong on the edit history, and undoing
/// into entities the restore recreates is a guid minefield); paused, the simulation holds; stopped,
/// the scene stops and the snapshot is restored into the same scene, so borrowed scene pointers
/// stay valid and the guid keyed selection resolves again (what the run spawned drops out). The
/// game's UI stays not interactive meanwhile: Simulate's pointer serves selection and the camera,
/// the Game tab is the interactive run. Out of the page's class, so the page stays the view and
/// this the run.
///
/// The page's scene belongs to a run of its own (SimulationRun), as a game's scenes belong to the
/// game's: what its behaviours put on screen and play is the run's, ended when the run's session
/// stops. Each Simulate is one session of the run; edit
/// mode is between sessions. The run lives as long as the page, so its scenes always carry it.
class SceneSimulation
{
	private SimulationRun mRun ~ delete _;
	private SceneSnapshot mSnapshot = null ~ delete _;
	private bool mRunning = false;
	private bool mPaused = false;

	/// The run named `name` (the page's title).
	public this(StringView name)
	{
		mRun = new .(name);
	}

	/// The page's run: its scenes carry it whether or not a Simulate is under way.
	public SimulationRun Run => mRun;
	public bool IsRunning => mRunning;
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
		mRun.Start(); // the session first, so the scene starts inside it
		scene.Start();
		scene.SetSimulationEnabled(true);
		commands.IsLocked = true;
		mRunning = true;
		mPaused = false;
		return true;
	}

	/// Holds or resumes a running simulation (the per frame freeze, not the start and stop
	/// callbacks the systems get on the big transitions); the run pauses with it.
	public void Pause(Sedulous.Scene.Scene scene, bool paused)
	{
		if (!mRunning)
			return;
		mPaused = paused;
		scene.SetSimulationEnabled(!paused);
		mRun.SetPaused(paused);
	}

	/// Stops and restores the snapshot into `scene`, its resources resolved through `resources`
	/// (null: none), `commands` unlocked. The run's session ends last, after the scene's behaviours
	/// have stopped, taking down what they left on screen and playing.
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
		mRun.Stop();
	}

	/// A page closing with its scene running: the scene stops and the session ends, with no
	/// restore (the scene is going).
	public void Abandon(Sedulous.Scene.Scene scene)
	{
		if (!mRunning)
			return;
		scene.Stop();
		DeleteAndNullify!(mSnapshot);
		mRunning = false;
		mPaused = false;
		mRun.Stop();
	}
}
