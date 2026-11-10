using System;
using System.Threading;
using Sedulous.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.ProjectManager;

/// A project's editor built for the manager to open the project with: one job of a build service
/// run on a thread of its own, so the manager's window keeps drawing while BeefBuild runs. The job
/// is read from the main thread as it runs (its step, its output, its diagnostics) and cancelled
/// from it. Deleted, it cancels the build and waits for its thread.
class EditorBuildRun
{
	private ProjectBuildService mService ~ delete _;
	private BuildJob mJob ~ _.ReleaseRef();
	private Thread mWorker = null;
	private bool mStarted = false;
	private String mProjectDir = new .() ~ delete _;
	private String mSdk = new .() ~ delete _;
	private bool mRestamp;

	/// `job` run by `service` (TAKES OWNERSHIP of both: the service, and the job's reference) for
	/// the project in `projectDir` over the SDK at `sdk`; `restamp` is passed on to the editor it
	/// opens.
	public this(ProjectBuildService service, BuildJob job, StringView projectDir, StringView sdk, bool restamp)
	{
		mService = service;
		mJob = job;
		mProjectDir.Set(projectDir);
		mSdk.Set(sdk);
		mRestamp = restamp;
	}

	public ~this()
	{
		mJob.Cancel();
		Join();
	}

	public BuildJob Job => mJob;
	public StringView ProjectDirectory => mProjectDir;
	public StringView Sdk => mSdk;
	public bool Restamp => mRestamp;

	/// The build started on its thread. Once.
	public void Start()
	{
		if (mStarted)
			return;
		mStarted = true;
		mService.Track(mJob); // its status readable before the thread first runs
		mWorker = new Thread(new () => { mService.Run(mJob).IgnoreError(); });
		mWorker.Start(false);
	}

	/// Whether it has ended, built or not, its thread done with. From the main thread.
	public bool Ended
	{
		get
		{
			if (!mStarted || !mJob.IsEnded)
				return false;
			Join();
			return true;
		}
	}

	/// Stops the build, from any thread: it ends Cancelled.
	public void Cancel() => mJob.Cancel();

	private void Join()
	{
		if (mWorker == null)
			return;
		mWorker.Join();
		DeleteAndNullify!(mWorker);
	}
}
