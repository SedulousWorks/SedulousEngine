using System;
using Sedulous.GUI;
using Sedulous.Editor.Project; // JobProgress

namespace Sedulous.Editor.App;

// EditorStatusBar: what the frame's status bar says (Raptor's editor-gui spec, 5.1, layer 9), over
// its items by id: the message (`status-message`: the context's status line), the job at the end
// (`status-job`: its name, a progress bar, its count; a sweep when its length is unknown, as a
// cook's) and the agent (`status-agent`: the MCP host while it listens). An item with nothing to
// say is not shown.

class EditorStatusBar
{
	// The frame's: the tree holds them, and the window lets this go before the frame.
	private Sedulous.GUI.Label mMessage = null;
	private Node mJob = null;
	private Sedulous.GUI.Label mJobName = null;
	private Sedulous.GUI.ProgressBar mJobProgress = null;
	private Sedulous.GUI.Label mJobCount = null;
	private Node mAgentItem = null;
	private Sedulous.GUI.Label mAgent = null;

	/// Over `frame`'s items; one it lacks is skipped.
	public this(Node frame)
	{
		mMessage = frame.FindElement("status-message") as Sedulous.GUI.Label;
		mJob = frame.FindElement("status-job");
		mJobName = frame.FindElement("status-job-name") as Sedulous.GUI.Label;
		mJobProgress = frame.FindElement("status-job-progress") as Sedulous.GUI.ProgressBar;
		mJobCount = frame.FindElement("status-job-count") as Sedulous.GUI.Label;
		mAgentItem = frame.FindElement("status-agent");
		mAgent = frame.FindElement("status-agent-text") as Sedulous.GUI.Label;
		ClearJob();
		SetAgent("");
	}

	public void SetMessage(StringView text)
	{
		if (mMessage != null)
			mMessage.Text = text;
	}

	/// The message shown; empty with no message item. The label's.
	public StringView Message => (mMessage != null) ? mMessage.Text : "";

	/// A job running: its name, how far (0 to 1; below 0 when its length is unknown) and its
	/// count ("12 of 40"; empty: none).
	public void SetJob(StringView name, float fraction, StringView count)
	{
		if (mJob != null)
			mJob.Displayed = true;
		if (mJobName != null)
			mJobName.Text = name;
		if (mJobProgress != null)
		{
			mJobProgress.Indeterminate = fraction < 0.0f;
			if (fraction >= 0.0f)
				mJobProgress.Value = Math.Clamp(fraction, 0.0f, 1.0f);
		}
		if (mJobCount != null)
		{
			mJobCount.Text = count;
			mJobCount.Displayed = !count.IsEmpty;
		}
	}

	/// No job running.
	public void ClearJob()
	{
		if (mJob != null)
			mJob.Displayed = false;
		if (mJobProgress != null)
			mJobProgress.Indeterminate = false; // no sweep animates unseen
	}

	public bool ShowsJob => (mJob != null) && mJob.Displayed;

	/// The job item from the editor's work: a running job (its title and step, how far, its step
	/// of how many), else a cook (its length unknown: a sweep), else none.
	public void ShowWork(JobProgress job, bool cooking)
	{
		if (job.Active)
		{
			let name = scope String(job.Title);
			if (!job.Step.IsEmpty)
				name.AppendF(": {}", job.Step);
			let count = scope String();
			if (job.StepCount > 0)
				count.AppendF("{} of {}", job.StepIndex + 1, job.StepCount);
			SetJob(name, job.Fraction, count);
		}
		else if (cooking)
			SetJob("Cooking", -1.0f, "");
		else if (ShowsJob)
			ClearJob();
	}

	/// The agent's line ("MCP on 127.0.0.1:7405"); empty hides it.
	public void SetAgent(StringView text)
	{
		if (mAgent != null)
			mAgent.Text = text;
		if (mAgentItem != null)
			mAgentItem.Displayed = !text.IsEmpty;
	}

	public bool ShowsAgent => (mAgentItem != null) && mAgentItem.Displayed;
}
