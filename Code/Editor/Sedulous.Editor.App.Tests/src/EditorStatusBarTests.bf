using System;
using Sedulous.Core.IO;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// EditorStatusBar over the editor's own frame (Data/Editor/Shell.xml): the message line; the job
/// with its name, progress and count, a sweep when its length is unknown, hidden when none runs;
/// the MCP item, always shown, lit while the host listens, naming a call still running and
/// showing the MCP panel when clicked; a frame without the items skipped. And the toasts: over
/// the frame's dock, the same message again counted on the one shown, an error staying until it is
/// dismissed while the rest go.
class EditorStatusBarTests
{
	/// The editor's frame, read from the repository's Data with every element the window
	/// registers; the caller releases it.
	private static Node LoadFrame()
	{
		let data = scope String();
		Test.Assert(EditorSplashTests.DataRoot(data));
		let path = PathJoin(data, EditorWindow.cFramePath, .. scope .());
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(path, text) case .Ok);
		RegisterGuiElements();
		RegisterToolkitElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	[Test]
	public static void TheMessageAJobWithItsProgressAndCountOrASweepTheMcpItemAJobHiddenWhenNoneRuns()
	{
		let frame = LoadFrame();
		Test.Assert(frame != null);
		defer frame.ReleaseRef();
		let status = scope EditorStatusBar(frame);
		let job = frame.FindElement("status-job");
		let agent = frame.FindElement("status-agent");
		let progress = frame.FindElement("status-job-progress") as Sedulous.GUI.ProgressBar;
		let count = frame.FindElement("status-job-count") as Sedulous.GUI.Label;
		Test.Assert(job != null);
		Test.Assert(agent != null);
		Test.Assert(progress != null);
		Test.Assert(count != null);
		Test.Assert(!job.Displayed, "nothing running");
		Test.Assert(agent.Displayed, "the MCP item, off");
		Test.Assert(status.AgentText == "MCP off");
		Test.Assert(!status.AgentListening);
		Test.Assert(status.AgentCall.IsEmpty);

		status.SetMessage("Saved 'Level 1'.");
		Test.Assert(status.Message == "Saved 'Level 1'.");

		status.SetJob("Export: Linux", 0.25f, "3 of 12");
		Test.Assert(status.ShowsJob);
		Test.Assert(job.Displayed);
		Test.Assert((frame.FindElement("status-job-name") as Sedulous.GUI.Label).Text == "Export: Linux");
		Test.Assert(!progress.Indeterminate);
		Test.Assert(Math.Abs(progress.Value - 0.25) < 1e-6);
		Test.Assert(count.Text == "3 of 12");
		Test.Assert(count.Displayed);
		status.SetJob("Cooking", -1.0f, ""); // its length unknown: a sweep, no count
		Test.Assert(progress.Indeterminate);
		Test.Assert(!count.Displayed);
		status.ClearJob();
		Test.Assert(!status.ShowsJob);
		Test.Assert(!job.Displayed);
		Test.Assert(!progress.Indeterminate);

		status.SetAgent(true, "MCP 7405", "asset_cook", "MCP: listening on 127.0.0.1:7405");
		Test.Assert(status.ShowsAgent);
		Test.Assert(status.AgentListening);
		Test.Assert((frame.FindElement("status-agent-dot") as UIWidget).HasClass("on"));
		Test.Assert(status.AgentText == "MCP 7405");
		Test.Assert(status.AgentCall == "asset_cook");
		let button = frame.FindElement("status-agent-text") as Sedulous.GUI.Button;
		Test.Assert(button != null);
		Test.Assert(button.Tooltip == "MCP: listening on 127.0.0.1:7405");
		status.SetAgent(true, "MCP 7405", "", "MCP: listening on 127.0.0.1:7405");
		Test.Assert(status.AgentCall.IsEmpty);
		Test.Assert(!(frame.FindElement("status-agent-call") as Sedulous.GUI.Label).Displayed);
		status.SetAgent(false, "MCP off", "", "MCP: stopped");
		Test.Assert(status.ShowsAgent);
		Test.Assert(agent.Displayed);
		Test.Assert(!status.AgentListening);
		Test.Assert(button.Tooltip == "MCP: stopped");

		int clicks = 0;
		status.SetOnAgentClicked(new [&clicks] () => { clicks++; });
		Test.Assert(button.HandleActivate());
		Test.Assert(clicks == 1);
	}

	[Test]
	public static void AFrameWithoutItsItemsIsSkippedNotAFault()
	{
		let bare = new Sedulous.GUI.Panel();
		defer bare.ReleaseRef();
		let status = scope EditorStatusBar(bare);
		status.SetMessage("nothing to show it on");
		status.SetJob("Cooking", -1.0f, "");
		status.SetAgent(true, "MCP 7405", "", "");
		status.SetOnAgentClicked(new () => {}); // deleted: nothing to click
		Test.Assert(status.Message.IsEmpty);
		Test.Assert(status.AgentText.IsEmpty);
		Test.Assert(!status.AgentListening);
		Test.Assert(!status.ShowsJob);
		Test.Assert(!status.ShowsAgent);
	}

	/// The editor's work on the job item: a running job by its title and step, how far and its
	/// step of how many, ahead of a cook; a cook alone a sweep with no count; neither, no item.
	[Test]
	public static void TheWorkShownAJobAheadOfACookACookASweepNeitherNothing()
	{
		let frame = LoadFrame();
		Test.Assert(frame != null);
		defer frame.ReleaseRef();
		let status = scope EditorStatusBar(frame);
		let name = frame.FindElement("status-job-name") as Sedulous.GUI.Label;
		let progress = frame.FindElement("status-job-progress") as Sedulous.GUI.ProgressBar;
		let count = frame.FindElement("status-job-count") as Sedulous.GUI.Label;

		let work = scope JobProgress();
		work.Active = true;
		work.Title.Set("Export");
		work.Step.Set("Linux");
		work.Fraction = 0.5f;
		work.StepIndex = 2;
		work.StepCount = 12;
		status.ShowWork(work, true); // a cook beside it: the job is shown
		Test.Assert(status.ShowsJob);
		Test.Assert(name.Text == "Export: Linux");
		Test.Assert(!progress.Indeterminate);
		Test.Assert(Math.Abs(progress.Value - 0.5) < 1e-6);
		Test.Assert(count.Text == "3 of 12");
		Test.Assert(count.Displayed);

		work.Step.Clear();
		work.StepCount = 0; // no steps: the title alone, no count
		status.ShowWork(work, false);
		Test.Assert(name.Text == "Export");
		Test.Assert(!count.Displayed);

		work.Active = false;
		status.ShowWork(work, true);
		Test.Assert(status.ShowsJob);
		Test.Assert(name.Text == "Cooking");
		Test.Assert(progress.Indeterminate);
		Test.Assert(!count.Displayed);

		status.ShowWork(work, false);
		Test.Assert(!status.ShowsJob);
		Test.Assert(!progress.Indeterminate);
	}

	/// The toasts stack over the frame's dock (above the status bar), else over the frame.
	[Test]
	public static void TheToastsGoOverTheDockElseTheFrame()
	{
		let frame = LoadFrame();
		Test.Assert(frame != null);
		defer frame.ReleaseRef();
		let into = EditorWindow.ToastsInto(frame);
		Test.Assert(into === frame.FindElement("frame-dock"));
		Test.Assert(into !== frame);

		let bare = new Sedulous.GUI.Panel();
		defer bare.ReleaseRef();
		Test.Assert(EditorWindow.ToastsInto(bare) === bare);
	}

	/// A host in a root of a GUI of its own; its clock advanced by hand.
	private class ToastBed
	{
		public SceneRoot Root;
		public ToastHost Host = new .();

		public this()
		{
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(800.0f, 600.0f);
			Root.AddChild(Host);
		}

		public ~this()
		{
			Host.ReleaseRef();
			Root.ReleaseRef();
		}
	}

	[Test]
	public static void TheSameNoticeAgainCountsOnTheOneShownAnotherStacks()
	{
		let bed = scope ToastBed();
		let first = EditorWindow.PostNotice(bed.Host, .Warning, "Cook: 1 failed");
		let again = EditorWindow.PostNotice(bed.Host, .Warning, "Cook: 1 failed");
		Test.Assert(again != first);
		Test.Assert(bed.Host.ShownCount == 1);
		let card = bed.Host.GetCard(first);
		Test.Assert(card != null);
		Test.Assert(card.Count == 2);
		Test.Assert(card.Severity == .Warning);
		Test.Assert(card.TitlePart.Text == "Cook: 1 failed");

		EditorWindow.PostNotice(bed.Host, .Info, "Saved");
		Test.Assert(bed.Host.ShownCount == 2);
		Test.Assert(bed.Host.GetCard(first).Count == 2);
	}

	[Test]
	public static void AnErrorStaysUntilDismissedTheRestGo()
	{
		let bed = scope ToastBed();
		let error = EditorWindow.PostNotice(bed.Host, .Error, "Export failed");
		let info = EditorWindow.PostNotice(bed.Host, .Info, "Saved");
		Test.Assert(bed.Host.GetCard(error).Severity == .Error);
		bed.Host.Tick(4.5f);
		Test.Assert(bed.Host.IsShown(info), "a notice stays its five seconds");
		bed.Host.Tick(1.0f);
		Test.Assert(!bed.Host.IsShown(info), "then goes");
		bed.Host.Tick(600.0f);
		Test.Assert(bed.Host.IsShown(error), "an error stays");
		Test.Assert(bed.Host.Dismiss(error));
		Test.Assert(!bed.Host.IsShown(error));
	}
}
