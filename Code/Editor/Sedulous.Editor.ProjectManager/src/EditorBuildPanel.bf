using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.ProjectManager;

/// The build of a project's editor as the manager shows it, a window over its projects
/// (Data/Editor/BuildEditor.xml): what BeefBuild is building, the last lines it printed, the
/// errors and warnings read from them, each a button whose click copies its place
/// ("file:line"), and how the build ended. Cancel stops the build; Close, once it has ended,
/// takes the window away.
///
/// Fill shows a job as it is; the program calls it each frame while the build runs and once
/// after. A test fills a body read from the markup with no window.
class EditorBuildPanel
{
	public const String cMarkupPath = "Editor/BuildEditor.xml";
	/// How many of BeefBuild's last lines it shows.
	public const int cOutputLines = 12;
	private const float cWidth = 720.0f;
	/// The height it opens at; its content's replaces it at the first layout.
	private const float cHeight = 420.0f;

	/// A reference of ours; the window holds its own.
	private Node mBody ~ _?.ReleaseRef();
	/// A reference of ours while it is the window made last.
	private Sedulous.GUI.Window mWindow = null ~ _?.ReleaseRef();
	/// The lines and the diagnostics shown, so each is made again only when it changed.
	private List<String> mShownOutput = new .() ~ DeleteContainerAndItems!(_);
	private List<String> mShownDiagnostics = new .() ~ DeleteContainerAndItems!(_);

	/// Over `body`, the markup's node: TAKES its reference.
	public this(Node body)
	{
		mBody = body;
	}

	public ~this()
	{
		Close();
	}

	public Node Body => mBody;
	public bool IsOpen => (mWindow != null) && mWindow.IsOpen;

	/// Each diagnostic as its button shows it, "file:line:column: message", into `outTexts` (the
	/// caller's).
	public void GetDiagnostics(List<String> outTexts)
	{
		for (let text in mShownDiagnostics)
			outTexts.Add(new .(text));
	}

	/// The words of how the build ended; empty while it runs.
	public StringView Result
	{
		get
		{
			let shown = Find<Sedulous.GUI.Label>("build-editor-result-text");
			return (shown != null) ? shown.Text : default;
		}
	}

	/// Opens it as a modal window over `root`, titled `title`. `cancel` runs on Cancel and `close`
	/// once the window has gone, by Close or its own close button (TAKES OWNERSHIP of both).
	public void Open(Node root, StringView title, delegate void() cancel, delegate void() close)
	{
		if ((root == null) || (mBody == null) || IsOpen)
		{
			delete cancel;
			delete close;
			return;
		}
		if (mWindow != null)
			mWindow.ReleaseRef();
		let window = new Sedulous.GUI.Window();
		mWindow = window;
		window.Title = title;
		window.Size = .(cWidth, cHeight);
		window.FitsHeightToContent = true;
		window.Content.AddChild(mBody);
		window.SetOnClose(close);
		if (let cancelButton = Find<Sedulous.GUI.Button>("build-editor-cancel"))
			cancelButton.SetOnClick(cancel);
		else
			delete cancel;
		if (let closeButton = Find<Sedulous.GUI.Button>("build-editor-close"))
			closeButton.SetOnClick(new [=window] () => { window.Close(); });
		window.OpenModal(root);
	}

	/// Takes the window away, if it is open.
	public void Close()
	{
		if (IsOpen)
			mWindow.Close();
	}

	/// Shows `job` as it is: its step, its output's last lines, its diagnostics and, once it has
	/// ended, how, with Close in place of Cancel.
	public void Fill(BuildJob job)
	{
		if (mBody == null)
			return;
		let project = scope String();
		let config = scope String();
		job.GetStep(project, config);
		let state = job.State;
		if (let step = Find<Sedulous.GUI.Label>("build-editor-step"))
		{
			if (state == .Generating)
				step.Text = "Writing the project's workspace";
			else if (project.IsEmpty)
				step.Text = "Waiting to build";
			else
				step.Text = scope $"Building {project} ({config}), {job.DurationMs / 1000} s";
		}
		FillOutput(job);
		FillDiagnostics(job);
		if (let counts = Find<Sedulous.GUI.Label>("build-editor-counts"))
		{
			let errors = job.ErrorCount;
			let warnings = job.WarningCount;
			let tally = scope String();
			tally.AppendF("{} error{}, {} warning{}", errors, (errors == 1) ? "" : "s", warnings, (warnings == 1) ? "" : "s");
			counts.Text = tally;
		}

		let ended = job.IsEnded;
		Show("build-editor-result", ended);
		Show("build-editor-cancel", !ended);
		Show("build-editor-close", ended);
		if (!ended)
			return;
		let words = scope String();
		switch (state)
		{
		case .Succeeded:
			words.Append("Built: the editor starts with the project.");
		case .Cancelled:
			words.Append("The build was cancelled; nothing was started.");
		default:
			words.AppendF("The editor did not build: {}", job.GetError(.. scope .()));
		}
		let line = Find<UIWidget>("build-editor-result");
		SetClass(line, "error", state == .Failed);
		SetClass(line, "warning", state == .Cancelled);
		if (let text = Find<Sedulous.GUI.Label>("build-editor-result-text"))
			text.Text = words;
		if (let icon = Find<Sedulous.GUI.Image>("build-editor-result-icon"))
			icon.Source = (state == .Succeeded) ? "Editor/Icons/check.svg" : ((state == .Failed) ? "Editor/Icons/error.svg" : "Editor/Icons/warning.svg");
	}

	/// The output's last lines, a label each, made again when they changed.
	private void FillOutput(BuildJob job)
	{
		let lines = scope List<String>();
		defer { ClearAndDeleteItems!(lines); }
		job.GetOutput(lines, cOutputLines);
		if (Same(lines, mShownOutput))
			return;
		ClearAndDeleteItems!(mShownOutput);
		let into = Find<Node>("build-editor-output");
		if (into != null)
			into.RemoveAllChildren();
		for (let line in lines)
		{
			mShownOutput.Add(new .(line));
			if (into == null)
				continue;
			let label = new Sedulous.GUI.Label();
			label.Text = line;
			into.AddChild(label);
			label.ReleaseRef(); // the tree's reference in place of the one it was made with
		}
	}

	/// The diagnostics, a button each that copies its place, made again when more came.
	private void FillDiagnostics(BuildJob job)
	{
		let diagnostics = scope List<BuildDiagnostic>();
		defer { ClearAndDeleteItems!(diagnostics); }
		job.GetDiagnostics(diagnostics);
		if (diagnostics.Count == mShownDiagnostics.Count)
			return;
		ClearAndDeleteItems!(mShownDiagnostics);
		let into = Find<Node>("build-editor-diagnostics");
		if (into != null)
			into.RemoveAllChildren();
		for (let diagnostic in diagnostics)
		{
			let text = diagnostic.Describe(.. new .());
			mShownDiagnostics.Add(text);
			if (into == null)
				continue;
			let button = new Sedulous.GUI.Button();
			button.AddClass("ghost");
			SetClass(button, "error", diagnostic.Severity == .Error);
			let shown = scope String(text);
			shown.Replace("&", "&&"); // a button's & marks its access key
			button.Text = shown;
			if (diagnostic.HasPlace)
			{
				let place = new $"{diagnostic.File}:{diagnostic.Line}";
				button.SetOnClick(new [=this, =place] () => { Copy(place); } ~ delete place);
			}
			into.AddChild(button);
			button.ReleaseRef();
		}
	}

	/// `text` onto the clipboard, when the GUI has one.
	private void Copy(StringView text)
	{
		let dispatcher = (mBody != null) ? mBody.EventDispatcher : null;
		if ((dispatcher != null) && (dispatcher.Clipboard != null))
			dispatcher.Clipboard.SetText(text);
	}

	private T Find<T>(StringView id) where T : Node
	{
		return (mBody != null) ? (mBody.FindElement(id) as T) : null;
	}

	private void Show(StringView id, bool shown)
	{
		if (let part = Find<Node>(id))
			part.Displayed = shown;
	}

	private static void SetClass(Node node, StringView name, bool on)
	{
		if (let widget = node as UIWidget)
		{
			if (on)
				widget.AddClass(name);
			else
				widget.RemoveClass(name);
		}
	}

	private static bool Same(List<String> a, List<String> b)
	{
		if (a.Count != b.Count)
			return false;
		for (int i < a.Count)
		{
			if (a[i] != b[i])
				return false;
		}
		return true;
	}
}
