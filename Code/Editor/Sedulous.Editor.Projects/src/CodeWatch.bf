using System;

namespace Sedulous.Editor.Project;

/// The editor's watch over the project's own code: each sweep's times (ProjectBuild.Staleness's)
/// give where the code stands against the built editor and the running one, and a change the
/// running editor lacks is told once, not at every sweep. The editor sweeps every cPollSeconds
/// from its frame, as the cook watches Sources/; host_info reads the files itself when asked.
class CodeWatch
{
	/// How often the editor sweeps the project's packages, in seconds: as often as the cook's
	/// watch over Sources/.
	public const double cPollSeconds = 2.0;

	private CodeStaleness mState = .();
	private bool mJudged = false;
	/// The newest file's time the last notice was given for: a change is told once.
	private int64 mTold = 0;

	/// The last sweep's word; nothing stale before the first.
	public CodeStaleness State => mState;
	/// Whether a sweep has been taken since the start or the last Reset.
	public bool Judged => mJudged;

	/// Takes a sweep's times: the packages' newest file, the built editor and the running one,
	/// and whether the running one links the project's packages (ProjectBuild.Staleness). True when the running editor lacks a change to the code not told
	/// of yet: the caller says NoticeText once. The first sweep that finds the running editor
	/// behind tells it too.
	public bool Observe(int64 newestSource, int64 built, int64 running, bool linked = true)
	{
		mState = ProjectBuild.Staleness(newestSource, built, running, linked);
		mJudged = true;
		if (!mState.RunningStale || (newestSource <= mTold))
			return false;
		mTold = newestSource;
		return true;
	}

	/// Forgets what it saw and told: another project opened, or none.
	public void Reset()
	{
		mState = .();
		mJudged = false;
		mTold = 0;
	}

	/// What the editor says of `state`, appended: that the project's own editor runs its code when
	/// this one does not link it; build and relaunch when the built editor lags the code too,
	/// relaunch alone when only this one does.
	public static void NoticeText(CodeStaleness state, String outText)
	{
		if (state.Unlinked)
			outText.Append("This editor does not run the project's code, its own editor does: Project > Build Project, then Open With This Build.");
		else if (state.BuildStale)
			outText.Append("Code changed: Project > Build Project, then Open With This Build.");
		else
			outText.Append("Code changed: the project's editor is built with it, Project > Open With This Build runs it.");
	}
}
