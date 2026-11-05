using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

/// What the MCP panel shows and does, from the application. Owned hooks; one not given reads as
/// nothing (no activity, stopped, no client) and does nothing.
class McpPanelSeams
{
	/// The service's activity. BORROWED; null while there is no service.
	public delegate McpActivity() Activity ~ delete _;
	public delegate bool() Listening ~ delete _;
	/// Where the host listens (0: stopped).
	public delegate uint16() Port ~ delete _;
	/// Where it starts.
	public delegate uint32() ConfiguredPort ~ delete _;
	/// The client that connected, appended ("claude-code 2.1.0"; nothing: none yet).
	public delegate void(String outClient) Client ~ delete _;
	/// The user's Start; false when it could not listen.
	public delegate bool() Start ~ delete _;
	/// The user's Stop.
	public delegate void() Stop ~ delete _;
	/// The command that wires an agent to the running host, appended; nothing while stopped.
	public delegate void(String outCommand) ConnectCommand ~ delete _;
	public delegate bool() StartsWithProject ~ delete _;
	public delegate void(bool on) SetStartsWithProject ~ delete _;
	/// Puts `text` on the clipboard; `what` names it for the user ("the connect command").
	public delegate void(StringView text, StringView what) Copy ~ delete _;
	public delegate void() Preferences ~ delete _;
}

/// The MCP panel. Its frame is markup (Data/Editor/Mcp.xml). The bar shows the host's state (a
/// dot lit while it listens, where it listens, the client that connected), Start or Stop, Copy
/// Connect Command (the command that wires Claude Code to the host, with its token) and whether
/// the host starts with each project (the MCP preference); then a chip per filter (All; Edits, the
/// calls whose tool creates, overwrites or deletes authored data; Failed, holding the calls refused
/// before any tool ran too: an unknown tool, arguments the schema refuses), each with its count, a
/// search over a call's tool, summary and arguments, Clear and the preferences. Under it the
/// activity (McpActivity), newest first: each call's time, outcome, tool, summary, an Edit badge
/// and how long it took, with the host's own events between; beside it the chosen call's
/// arguments and answer, read only, and Copy as JSON. It is refreshed once a frame from the
/// activity.
class McpPanel
{
	/// Its frame under the data root.
	public const String cMarkupPath = "Editor/Mcp.xml";

	public enum Filter : uint8
	{
		All,
		Edits,
		Failed,
	}

	/// The shown entries as the list's model: a row's id its entry's, so a selection follows it.
	private class EntryModel : IModel
	{
		private McpPanel mPanel;

		public this(McpPanel panel) { mPanel = panel; }

		public override int RowCount(ModelIndex parent) => parent.IsValid ? 0 : mPanel.mShown.Count;
		public override int ColumnCount() => 1;

		public override Sedulous.GUI.Variant Data(ModelIndex index, ModelRole role = .Display)
		{
			let entry = mPanel.ShownEntry(index.Row);
			if ((role != .Display) || (entry == null))
				return .();
			return .((StringView)entry.Tool);
		}

		public override ItemId IdOf(ModelIndex index)
		{
			let entry = mPanel.ShownEntry(index.Row);
			return (entry != null) ? entry.Id : NoItem;
		}

		public override ModelIndex IndexOfId(ItemId id)
		{
			for (int row < mPanel.mShown.Count)
			{
				if (mPanel.ShownEntry(row).Id == id)
					return Index((int32)row);
			}
			return .();
		}

		public void Reset() => NotifyReset();
	}

	private static StringView[5] sOutcomeClasses = .("running", "done", "failed", "abandoned", "refused");
	private static StringView[6] sRowClasses = .("running", "done", "failed", "abandoned", "refused", "event");

	/// A reference of ours; the panel showing it takes its own. Declared first: it goes last,
	/// after the model the list it holds borrows.
	private Node mContent ~ _?.ReleaseRef();
	private McpPanelSeams mSeams ~ delete _;
	/// Borrowed; the content's.
	private ListView mList = null;
	/// Borrowed; the content's.
	private Sedulous.GUI.Button[3] mChips;
	/// The entries shown, newest first, by their place in the activity.
	private List<int> mShown = new .() ~ delete _;
	/// The calls each filter holds (events are none of them).
	private int[3] mCounts;
	private Filter mFilter = .All;
	/// What a call must contain to show; empty shows every entry.
	private String mSearch = new .() ~ delete _;
	private uint64 mRevision = 0;
	private bool mListed = false;
	private bool mStartFailed = false;
	/// The call the detail shows, and its outcome then: rewritten only when either moves.
	private uint64 mDetailId = 0;
	private McpActivity.Outcome mDetailOutcome = .Done;
	private EntryModel mModel ~ delete _;

	/// Over its frame `content` (the markup's: its parts by id). TAKES OWNERSHIP of `seams` and of
	/// a reference to `content`; null shows nothing.
	public this(McpPanelSeams seams, Node content)
	{
		mSeams = seams;
		mContent = content;
		mModel = new EntryModel(this);
		if (mContent == null)
			return;
		mList = Find<ListView>("mcp-list");
		if (mList != null)
		{
			let rows = new RowFactory();
			rows.Create = new (type) => MakeRow();
			rows.Bind = new (row, index) => { BindRow(row, index); };
			mList.SetRowFactory(rows);
			mList.Model = mModel;
			mList.SetOnSelectionChanged(new (index) => { ShowDetail(); });
		}
		StringView[3] chips = .("mcp-all", "mcp-edits", "mcp-failed");
		for (int i < 3)
		{
			mChips[i] = Find<Sedulous.GUI.Button>(chips[i]);
			if (mChips[i] != null)
			{
				let filter = (Filter)i;
				mChips[i].SetOnClick(new [=this, =filter] () => { SetFilter(filter); });
			}
		}
		if (let search = Find<TextField>("mcp-search"))
			search.SetOnTextChanging(new (text) => { SetSearch(text); });
		if (let clearSearch = Find<Sedulous.GUI.Button>("mcp-clear-search"))
		{
			clearSearch.SetOnClick(new () =>
				{
					if (let field = Find<TextField>("mcp-search"))
						field.Text = "";
					SetSearch("");
				});
		}
		if (let clear = Find<Sedulous.GUI.Button>("mcp-clear"))
			clear.SetOnClick(new () => { Clear(); });
		if (let start = Find<Sedulous.GUI.Button>("mcp-start"))
			start.SetOnClick(new () => { Start(); });
		if (let stop = Find<Sedulous.GUI.Button>("mcp-stop"))
			stop.SetOnClick(new () => { Stop(); });
		if (let copy = Find<Sedulous.GUI.Button>("mcp-copy-connect"))
			copy.SetOnClick(new () => { CopyConnectCommand(); });
		if (let preferences = Find<Sedulous.GUI.Button>("mcp-preferences"))
		{
			preferences.SetOnClick(new () =>
				{
					if (mSeams.Preferences != null)
						mSeams.Preferences();
				});
		}
		if (let withProject = Find<Sedulous.GUI.CheckBox>("mcp-with-project"))
		{
			withProject.SetOnToggled(new (on) =>
				{
					if (mSeams.SetStartsWithProject != null)
						mSeams.SetStartsWithProject(on);
				});
		}
		if (let copyCall = Find<Sedulous.GUI.Button>("mcp-detail-copy"))
			copyCall.SetOnClick(new () => { CopySelectedCall(); });
		StringView[2] areas = .("mcp-arguments", "mcp-result");
		for (let id in areas)
		{
			if (let area = Find<TextArea>(id))
				area.IsReadOnly = true;
		}
		Update();
	}

	/// The panel may hold the content past this view: what of the list calls back here goes
	/// first.
	public ~this()
	{
		if (mList != null)
		{
			mList.SetOnSelectionChanged(null);
			mList.Model = null;
			mList.SetRowFactory(null);
		}
	}

	/// Its frame. Ours: a caller that keeps it takes a reference.
	public Node Content => mContent;

	/// Called each frame: the bar follows the host, the list and the detail the activity.
	public void Update()
	{
		ShowState();
		let activity = Activity();
		let revision = (activity != null) ? activity.Revision : 0;
		if ((revision != mRevision) || !mListed)
		{
			mRevision = revision;
			mListed = true;
			Refilter();
			ShowChrome();
			ShowDetail();
		}
	}

	public void Start()
	{
		mStartFailed = (mSeams.Start != null) && !mSeams.Start();
		ShowState();
	}

	public void Stop()
	{
		mStartFailed = false;
		if (mSeams.Stop != null)
			mSeams.Stop();
		ShowState();
	}

	public void CopyConnectCommand()
	{
		let command = scope String();
		if (mSeams.ConnectCommand != null)
			mSeams.ConnectCommand(command);
		if (!command.IsEmpty && (mSeams.Copy != null))
			mSeams.Copy(command, "the connect command");
	}

	public void Clear()
	{
		if (let activity = Activity())
			activity.Clear();
		Update();
	}

	public Filter CurrentFilter => mFilter;

	public void SetFilter(Filter filter)
	{
		if (mFilter == filter)
			return;
		mFilter = filter;
		Refilter();
		ShowChrome();
		ShowDetail();
	}

	/// Shows only the calls whose tool, summary or arguments hold `text`, ignoring case; empty
	/// shows them all. The search field calls it as the user types.
	public void SetSearch(StringView text)
	{
		if (mSearch == text)
			return;
		mSearch.Set(text);
		Refilter();
		ShowChrome();
		ShowDetail();
	}

	/// The rows shown, newest first.
	public int ShownCount => mShown.Count;

	/// A shown row's entry; null past the end. BORROWED, the activity's.
	public McpActivity.Entry ShownEntry(int row)
	{
		let activity = Activity();
		if ((activity == null) || (row < 0) || (row >= mShown.Count))
			return null;
		return activity[mShown[row]];
	}

	/// Chooses a shown row, so the detail shows it.
	public void Select(int row)
	{
		if ((mList != null) && (row >= 0) && (row < mShown.Count))
			mList.SelectedItem = (int32)row;
		ShowDetail();
	}

	/// The chosen call (null: none, or an event). BORROWED, the activity's.
	public McpActivity.Entry Selected
	{
		get
		{
			if (mList == null)
				return null;
			let entry = ShownEntry(mList.SelectedItem);
			return ((entry != null) && entry.IsCall) ? entry : null;
		}
	}

	/// The chosen call as JSON, appended: its tool, arguments, outcome, how long it took and its
	/// answer (an error's under "error"). Nothing when none is chosen.
	public void SelectedCallJson(String outJson)
	{
		let entry = Selected;
		if (entry == null)
			return;
		let call = JsonValue.MakeObject();
		defer delete call;
		call.Set("tool", JsonValue.MakeString(entry.Tool));
		call.Set("arguments", ParsedOrText(entry.Arguments));
		call.Set("outcome", JsonValue.MakeString(OutcomeName(entry.Outcome)));
		call.Set("milliseconds", JsonValue.MakeNumber((double)(int64)(entry.Elapsed.TotalSeconds * 1000.0 + 0.5)));
		if ((entry.Outcome == .Done) || WentWrong(entry))
			call.Set(WentWrong(entry) ? "error" : "result", ParsedOrText(entry.Result));
		call.ToString(outJson, true);
	}

	public void CopySelectedCall()
	{
		let json = SelectedCallJson(.. scope .());
		if (!json.IsEmpty && (mSeams.Copy != null))
			mSeams.Copy(json, "the call");
	}

	/// The list (its selection, for a test).
	public ListView List => mList;

	/// A time of day as hh:mm:ss, appended, from local seconds since 1970.
	public static void TimeText(int64 at, String outText)
	{
		let time = CivilTimeOf(at);
		outText.AppendF("{:D2}:{:D2}:{:D2}", (int)time.Hour, (int)time.Minute, (int)time.Second);
	}

	/// How long a call took, appended: whole milliseconds under a second, tenths of a second
	/// above.
	public static void TookText(TimeSpan elapsed, String outText)
	{
		let seconds = elapsed.TotalSeconds;
		if (seconds < 1.0)
		{
			outText.AppendF("{} ms", (int64)(seconds * 1000.0 + 0.5));
			return;
		}
		let tenths = (int64)(seconds * 10.0 + 0.5);
		outText.AppendF("{}.{} s", tenths / 10, tenths % 10);
	}

	/// The frame's part with this id, as a T; null when it has none.
	private T Find<T>(StringView id) where T : Node
	{
		return (mContent != null) ? (mContent.FindElement(id) as T) : null;
	}

	private McpActivity Activity() => (mSeams.Activity != null) ? mSeams.Activity() : null;

	private static void SetText(Sedulous.GUI.Label label, StringView text)
	{
		if ((label != null) && (label.Text != text))
			label.Text = text;
	}

	private static void SetClass(UIWidget widget, StringView name, bool on)
	{
		if ((widget == null) || (widget.HasClass(name) == on))
			return;
		if (on)
			widget.AddClass(name);
		else
			widget.RemoveClass(name);
	}

	/// Failed, or refused before any tool ran: what the Failed filter shows.
	private static bool WentWrong(McpActivity.Entry entry) =>
		entry.IsCall && ((entry.Outcome == .Failed) || (entry.Outcome == .Refused));

	private static StringView OutcomeName(McpActivity.Outcome outcome)
	{
		switch (outcome)
		{
		case .Running: return "running";
		case .Failed: return "failed";
		case .Abandoned: return "abandoned";
		case .Refused: return "refused";
		default: return "done";
		}
	}

	/// JSON text as a value, or the text itself as a string when it is not JSON (an error
	/// message). The caller owns it.
	private static JsonValue ParsedOrText(StringView text)
	{
		let parsed = scope JsonParseResult();
		JsonParser.Parse(text, parsed);
		if (parsed.Ok)
			return parsed.TakeValue();
		return JsonValue.MakeString(text);
	}

	/// JSON text laid out over lines, appended; text that is not JSON as it is.
	private static void Pretty(StringView text, String outText)
	{
		let parsed = scope JsonParseResult();
		JsonParser.Parse(text, parsed);
		if (parsed.Ok)
			parsed.Value.ToString(outText, true);
		else
			outText.Append(text);
	}

	/// Whether an entry passes the filter and the search.
	private bool Passes(McpActivity.Entry entry)
	{
		if ((mFilter == .Edits) && !(entry.IsCall && entry.Changes))
			return false;
		if ((mFilter == .Failed) && !WentWrong(entry))
			return false;
		if (mSearch.IsEmpty)
			return true;
		if (entry.Tool.Contains(mSearch, true) || entry.Arguments.Contains(mSearch, true))
			return true;
		return McpActivity.Summary(entry, .. scope .()).Contains(mSearch, true);
	}

	private void Refilter()
	{
		mShown.Clear();
		for (var count in ref mCounts)
			count = 0;
		if (let activity = Activity())
		{
			for (int i = activity.Count - 1; i >= 0; i--)
			{
				let entry = activity[i];
				if (entry.IsCall)
				{
					mCounts[(int)Filter.All]++;
					if (entry.Changes)
						mCounts[(int)Filter.Edits]++;
					if (WentWrong(entry))
						mCounts[(int)Filter.Failed]++;
				}
				if (Passes(entry))
					mShown.Add(i);
			}
		}
		mModel.Reset();
	}

	/// The bar: the host's state, the controls that apply to it, the preference.
	private void ShowState()
	{
		let listening = (mSeams.Listening != null) && mSeams.Listening();
		if (listening)
			mStartFailed = false;
		let port = (mSeams.Port != null) ? mSeams.Port() : 0;
		let configured = (mSeams.ConfiguredPort != null) ? mSeams.ConfiguredPort() : 0;
		SetClass(Find<UIWidget>("mcp-dot"), "on", listening);
		if (listening)
			SetText(Find<Sedulous.GUI.Label>("mcp-state"), scope $"Listening on 127.0.0.1:{port}");
		else
			SetText(Find<Sedulous.GUI.Label>("mcp-state"), mStartFailed ? "Could not start" : "Stopped");
		let client = scope String();
		if (listening)
		{
			if (mSeams.Client != null)
				mSeams.Client(client);
			if (client.IsEmpty)
				client.Set("no client yet");
		}
		else if (mStartFailed)
			client.AppendF("127.0.0.1:{} is taken, by another editor most likely; change the port in the preferences", configured);
		else
			client.Set("Agents cannot reach the editor");
		SetText(Find<Sedulous.GUI.Label>("mcp-client"), client);
		if (let start = Find<Sedulous.GUI.Button>("mcp-start"))
		{
			start.Displayed = !listening;
			let tooltip = scope $"Start the MCP host on 127.0.0.1:{configured}";
			if (start.Tooltip != tooltip)
				start.Tooltip = tooltip;
		}
		if (let stop = Find<Sedulous.GUI.Button>("mcp-stop"))
			stop.Displayed = listening;
		if (let copy = Find<Sedulous.GUI.Button>("mcp-copy-connect"))
			copy.Displayed = listening;
		if (let withProject = Find<Sedulous.GUI.CheckBox>("mcp-with-project"))
		{
			let on = (mSeams.StartsWithProject != null) && mSeams.StartsWithProject();
			if (withProject.Checked != on)
				withProject.Checked = on;
		}
	}

	/// The chips' counts and states, the search's x, the empty line.
	private void ShowChrome()
	{
		StringView[3] names = .("All", "Edits", "Failed");
		for (int i < 3)
		{
			let chip = mChips[i];
			if (chip == null)
				continue;
			let text = scope String(names[i]);
			if (mCounts[i] != 0)
				text.AppendF("  {}", mCounts[i]);
			if (chip.Text != text)
				chip.Text = text;
			SetClass(chip, "checked", (int)mFilter == i);
		}
		if (let clearSearch = Find<Sedulous.GUI.Button>("mcp-clear-search"))
			clearSearch.Visible = !mSearch.IsEmpty; // keeps its place: the field does not jump
		if (let empty = Find<Sedulous.GUI.Label>("mcp-empty"))
		{
			empty.Displayed = mShown.IsEmpty;
			let activity = Activity();
			let none = (activity == null) || (activity.Count == 0);
			SetText(empty, none ? "No calls yet. Agents' calls show here as they arrive." : "No call matches.");
		}
	}

	/// The chosen call's head, arguments and answer; the placeholder when none is chosen.
	private void ShowDetail()
	{
		let entry = Selected;
		if (let detail = Find<UIWidget>("mcp-detail"))
			detail.Displayed = entry != null;
		if (let none = Find<UIWidget>("mcp-no-detail"))
			none.Displayed = entry == null;
		if (entry == null)
		{
			mDetailId = 0;
			return;
		}
		// Rewritten only when the call or its outcome changed, so a selection in the text stays.
		if ((mDetailId == entry.Id) && (mDetailOutcome == entry.Outcome))
			return;
		mDetailId = entry.Id;
		mDetailOutcome = entry.Outcome;
		SetText(Find<Sedulous.GUI.Label>("mcp-detail-tool"), entry.Tool);
		if (let outcome = Find<Sedulous.GUI.Label>("mcp-detail-outcome"))
		{
			StringView[5] texts = .("Running", "Done", "Failed", "Abandoned", "Refused");
			SetText(outcome, texts[(int)entry.Outcome]);
			for (let name in sOutcomeClasses)
				SetClass(outcome, name, name == OutcomeName(entry.Outcome));
		}
		let stamp = TimeText(entry.At, .. scope .());
		if ((entry.Outcome != .Running) && (entry.Outcome != .Refused)) // a refusal took no time
		{
			stamp.Append(", ");
			TookText(entry.Elapsed, stamp);
		}
		SetText(Find<Sedulous.GUI.Label>("mcp-detail-when"), stamp);
		if (let arguments = Find<TextArea>("mcp-arguments"))
		{
			arguments.Text = Pretty(entry.Arguments, .. scope .());
			arguments.Caret = 0; // read from the top
		}
		SetText(Find<Sedulous.GUI.Label>("mcp-result-title"), WentWrong(entry) ? "Error" : "Result");
		if (let result = Find<TextArea>("mcp-result"))
		{
			if (entry.Outcome == .Running)
				result.Text = "(still running)";
			else if (entry.Outcome == .Abandoned)
				result.Text = "(no answer: the caller left or the host stopped)";
			else
				result.Text = Pretty(entry.Result, .. scope .());
			result.Caret = 0;
		}
	}

	/// A row: its time, its outcome's mark, its tool, its summary, the Edit badge and how long it
	/// took. A node with one reference, the row's.
	private Node MakeRow()
	{
		let row = new Sedulous.GUI.Panel();
		row.AddClass("mcp-row");
		AddLabel(row, "mcp-time", true);
		let mark = new Sedulous.GUI.Panel();
		mark.AddClass("mcp-mark");
		row.AddChild(mark);
		mark.ReleaseRef(); // the row's reference keeps it
		AddLabel(row, "mcp-tool", true);
		AddLabel(row, "mcp-summary", false);
		AddLabel(row, "mcp-badge", false);
		AddLabel(row, "mcp-took", true);
		return row;
	}

	private static void AddLabel(Node row, StringView className, bool mono)
	{
		let label = new Sedulous.GUI.Label();
		label.AddClass(className);
		if (mono)
			label.AddClass("mono");
		row.AddChild(label);
		label.ReleaseRef(); // the row's reference keeps it
	}

	private void BindRow(Node node, ModelIndex index)
	{
		let row = node as UIWidget;
		let entry = ShownEntry(index.Row);
		if ((row == null) || (entry == null) || (row.ChildCount < 6))
			return;
		let call = entry.IsCall;
		let outcome = call ? OutcomeName(entry.Outcome) : "event";
		for (let name in sRowClasses)
		{
			SetClass(row, name, name == outcome);
			SetClass(row.GetChildAt(1) as UIWidget, name, name == outcome);
		}
		SetText(row.GetChildAt(0) as Sedulous.GUI.Label, TimeText(entry.At, .. scope .()));
		if (let tool = row.GetChildAt(2) as Sedulous.GUI.Label)
		{
			SetText(tool, call ? (StringView)entry.Tool : "");
			tool.Displayed = call;
		}
		SetText(row.GetChildAt(3) as Sedulous.GUI.Label, McpActivity.Summary(entry, .. scope .()));
		if (let badge = row.GetChildAt(4) as Sedulous.GUI.Label)
		{
			badge.Displayed = call && entry.Changes;
			SetText(badge, "Edit");
			SetClass(badge, "edit", true);
		}
		let took = scope String();
		if (call)
		{
			if (entry.Outcome == .Running)
				took.Set("running");
			else if (entry.Outcome == .Refused)
				took.Set("refused");
			else
				TookText(entry.Elapsed, took);
		}
		SetText(row.GetChildAt(5) as Sedulous.GUI.Label, took);
	}
}
