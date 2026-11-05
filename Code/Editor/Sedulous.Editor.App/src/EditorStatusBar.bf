using System;
using Sedulous.GUI;
using Sedulous.Editor.Project; // JobProgress

namespace Sedulous.Editor.App;

// EditorStatusBar: what the frame's status bar says, over its items by id: the message
// (`status-message`: the context's status line), the job at the end (`status-job`: its name, a
// progress bar, its count; a sweep when its length is unknown, as a cook's; hidden when none
// runs) and the MCP host (`status-agent`, always shown: a dot lit while it listens, its port or
// "off", the tool of a call still running beside it; clicked, it shows the MCP panel).

class EditorStatusBar
{
	// The frame's: the tree holds them, and the window lets this go before the frame.
	private Sedulous.GUI.Label mMessage = null;
	private Node mJob = null;
	private Sedulous.GUI.Label mJobName = null;
	private Sedulous.GUI.ProgressBar mJobProgress = null;
	private Sedulous.GUI.Label mJobCount = null;
	private Node mAgentItem = null;
	private Sedulous.GUI.Button mAgent = null;
	private UIWidget mAgentDot = null;
	private Sedulous.GUI.Label mAgentCall = null;

	/// Over `frame`'s items; one it lacks is skipped.
	public this(Node frame)
	{
		mMessage = frame.FindElement("status-message") as Sedulous.GUI.Label;
		mJob = frame.FindElement("status-job");
		mJobName = frame.FindElement("status-job-name") as Sedulous.GUI.Label;
		mJobProgress = frame.FindElement("status-job-progress") as Sedulous.GUI.ProgressBar;
		mJobCount = frame.FindElement("status-job-count") as Sedulous.GUI.Label;
		mAgentItem = frame.FindElement("status-agent");
		mAgent = frame.FindElement("status-agent-text") as Sedulous.GUI.Button;
		mAgentDot = frame.FindElement("status-agent-dot") as UIWidget;
		mAgentCall = frame.FindElement("status-agent-call") as Sedulous.GUI.Label;
		ClearJob();
		SetAgent(false, "MCP off", "", "MCP: stopped. Show the MCP panel to start it");
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

	/// The MCP host's item: whether it listens (the dot lit), its text ("MCP 7405", "MCP off"),
	/// the tool of a call still running (empty: none) and the item's tooltip.
	public void SetAgent(bool listening, StringView text, StringView runningCall, StringView tooltip)
	{
		if (mAgent != null)
		{
			if (mAgent.Text != text)
				mAgent.Text = text;
			if (mAgent.Tooltip != tooltip)
				mAgent.Tooltip = tooltip;
		}
		if ((mAgentDot != null) && (mAgentDot.HasClass("on") != listening))
		{
			if (listening)
				mAgentDot.AddClass("on");
			else
				mAgentDot.RemoveClass("on");
		}
		if (mAgentCall != null)
		{
			if (mAgentCall.Text != runningCall)
				mAgentCall.Text = runningCall;
			mAgentCall.Displayed = !runningCall.IsEmpty;
		}
	}

	/// What a click on the MCP item does (shows the MCP panel). TAKES OWNERSHIP of `clicked`;
	/// deleted at once when the frame has no item.
	public void SetOnAgentClicked(delegate void() clicked)
	{
		if (mAgent != null)
			mAgent.SetOnClick(clicked);
		else
			delete clicked;
	}

	public bool ShowsAgent => (mAgentItem != null) && mAgentItem.Displayed;
	/// The item's text; empty with no item.
	public StringView AgentText => (mAgent != null) ? mAgent.Text : "";
	/// Whether the dot is lit.
	public bool AgentListening => (mAgentDot != null) && mAgentDot.HasClass("on");
	/// The tool of the call still running; empty with none.
	public StringView AgentCall => ((mAgentCall != null) && mAgentCall.Displayed) ? mAgentCall.Text : "";
}
