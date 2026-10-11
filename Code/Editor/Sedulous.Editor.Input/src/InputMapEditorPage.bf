using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Input;
using Sedulous.Input.Pipeline;
using Sedulous.Runtime.Client;
using Sedulous.UI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Input;

/// The input map page: an InputMapAsset's sets of actions and each action's bindings, laid out
/// two ways to compare: an outline (each set a collapsible section of its actions) or two panes
/// (the sets and actions listed, the selected one edited). Both are made of the same editors: a
/// set's name and priority; an action's name, kind and interaction; its bindings as cards, each
/// input a key cap to click and then press the new input (captured from the shell each frame,
/// filtered by the action's kind), its settings named in full; Add Binding as a menu of the
/// sources the kind takes; and an axis's processing. Every change is one undoable deep copy
/// command, a field's edits merged into one. Save validates the map first.
class InputMapEditorPage : UIEditorPage
{
	/// How the map is laid out, the two ways to compare: one outline, each set a collapsible
	/// section of its actions; or two panes, the sets and actions listed on the left and the
	/// selected one edited on the right. Both build from the same editors.
	public enum Layout
	{
		Outline,
		TwoPanes
	}

	private static readonly Color cDimText = .(0.62f, 0.62f, 0.62f, 1.0f);
	private static readonly Color cWarningText = .(0.91f, 0.69f, 0.29f, 1.0f);
	private static readonly Color cAccent = .(0.31f, 0.56f, 0.95f, 1.0f);
	/// A settings row's label column.
	private const float cLabelWidth = 96.0f;

	/// Borrowed.
	private EditorContext mContext;
	private String mTitle = new .() ~ delete _;
	/// The map being edited, owned.
	private InputMap mMap = new .() ~ delete _;

	/// Borrowed: the content owns them.
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private PageToolbar mToolbar = null;
	/// Rebuilt: the layout in use.
	private FlexLayout mBody = null;
	/// The map's state, or what listening waits for.
	private Label mStatus = null;
	private ComboBox mLayoutChoice = null;
	/// Held across rebuilds (only their content is rebuilt), so an edit never throws the view
	/// back to the top. Owned: one reference each, the body taking its own while shown.
	private ScrollView mOutlineScroll = null ~ _?.ReleaseRef();
	private ScrollView mListScroll = null ~ _?.ReleaseRef();
	private ScrollView mDetailScroll = null ~ _?.ReleaseRef();

	private Layout mLayout = .Outline;
	private int mSelectedSet = 0;
	/// Below zero: the set itself.
	private int mSelectedAction = 0;
	/// The outline's collapsed sets, by name.
	private List<String> mCollapsed = new .() ~ DeleteContainerAndItems!(_);
	/// A field's edit is executing: no rebuild under it.
	private bool mQuietEdit = false;

	private bool mListening = false;
	private int mListenSet = 0;
	private int mListenAction = 0;
	private int mListenBinding = 0;
	/// At or above zero: capturing one Composite2D direction key.
	private int mListenDirection = -1;
	private CaptureFilter mListenFilter = .();

	public this(EditorContext context, Instance instance)
	{
		mContext = context;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;
		let object = instance.ReadObject();
		if (let asset = object as InputMapAsset)
			asset.Map.CopyTo(mMap);
		delete object;

		let column = new FlexLayout();
		column.Direction = .Vertical;

		// The top bar: what the map says (or what listening waits for), and the layout.
		{
			let bar = Row(8.0f);
			bar.Padding = .(10, 6);
			mStatus = new Label("");
			mStatus.FontSize.Value = 12.0f;
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.AlignSelf = .Center;
			bar.AddView(mStatus, grow);
			AddLabel(bar, "Layout", 11.0f, true);
			mLayoutChoice = new ComboBox();
			mLayoutChoice.AddItem("Outline");
			mLayoutChoice.AddItem("Two panes");
			mLayoutChoice.SetSelectedIndex(0);
			mLayoutChoice.OnSelectionChanged.Add(new [=this](combo, index) => { SetLayout((index == 1) ? .TwoPanes : .Outline); });
			var fixedWidth = LayoutStyle();
			fixedWidth.Width = SizeSpec.Fixed(Unit.Dp(120.0f));
			fixedWidth.AlignSelf = .Center;
			bar.AddView(mLayoutChoice, fixedWidth);
			var match = LayoutStyle();
			match.Width = SizeSpec.Match();
			column.AddView(bar, match);
			var line = LayoutStyle();
			line.Width = SizeSpec.Match();
			line.Height = SizeSpec.Fixed(Unit.Dp(1.0f));
			column.AddView(new Separator(), line);
		}

		mBody = new FlexLayout();
		mBody.Direction = .Horizontal;
		var growMatch = LayoutStyle();
		growMatch.FlexGrow = 1.0f;
		growMatch.Width = SizeSpec.Match();
		column.AddView(mBody, growMatch);
		mOutlineScroll = MakeScroll();
		mListScroll = MakeScroll();
		mDetailScroll = MakeScroll();

		mToolbar = new PageToolbar(this, mContext.Actions);
		mContent = PageToolbar.Frame(mToolbar, column);
		Rebuild();
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;

	/// For tests: the map as edited, the layout, the two-pane selection, the body.
	public InputMap Map => mMap;
	public bool IsListening => mListening;
	public Layout CurrentLayout => mLayout;
	public int SelectedSet => mSelectedSet;
	public int SelectedAction => mSelectedAction;
	public FlexLayout Body => mBody;

	/// The body, rebuilt now (tests; the page itself defers through RequestRebuild).
	public void RebuildNow() => Rebuild();

	public override Result<void, ErrorCode> Save()
	{
		let error = scope String();
		if (!InputMapValidation.Validate(mMap, error))
		{
			mContext.Notify(.Error, scope $"Input map invalid: {error}");
			return .Err(.InvalidArgument);
		}
		let instance = (mContext.Project != null) ? mContext.Project.SourceDb.GetInstance(InstanceId) : null;
		if (instance == null)
			return .Err(.NotFound);
		let asset = scope InputMapAsset();
		mMap.CopyTo(asset.Map);
		let written = instance.WriteObject(asset);
		if (written case .Ok)
			ClearDirty();
		return written;
	}

	/// While listening, the first input the shell reports lands in the slot being rebound.
	public override void OnUpdate(IApplicationHost host, float dt)
	{
		if (mToolbar != null)
			mToolbar.Refresh();
		if (!mListening)
			return;
		let shellInput = (host.Shell != null) ? host.Shell.Input : null;
		if (shellInput == null)
			return;
		// Escape is a BINDABLE key, so it is not a cancel here: cancel is clicking the key cap
		// again. The capture takes whatever qualifies.
		let devices = scope ShellInputSource(shellInput);
		Binding captured = ?;
		if (BindingCapture.Capture(devices, mListenFilter, out captured))
		{
			let set = mListenSet;
			let action = mListenAction;
			let binding = mListenBinding;
			let direction = mListenDirection;
			mListening = false;
			mListenDirection = -1;
			Mutate(new [=set, =action, =binding, =direction, =captured](map) => { InputMapEdit.ApplyCapture(map, set, action, binding, direction, captured); });
		}
	}

	public void SetLayout(Layout layout)
	{
		if (mLayout == layout)
			return;
		mLayout = layout;
		mLayoutChoice.SetSelectedIndex((layout == .TwoPanes) ? 1 : 0);
		RequestRebuild();
	}

	/// Selects a set (`action` below zero) or one of its actions, in the two-pane layout.
	public void Select(int set, int action)
	{
		mSelectedSet = set;
		mSelectedAction = action;
		mDetailScroll.SetScrollY(0.0f);
		RequestRebuild();
	}

	/// Whether the outline hides a set's actions. Kept by the set's name, so it survives a
	/// rebuild and a reorder.
	public bool IsSetCollapsed(int set)
	{
		if ((set < 0) || (set >= mMap.Sets.Count))
			return false;
		for (let name in mCollapsed)
		{
			if (name == mMap.Sets[set].Name)
				return true;
		}
		return false;
	}

	public void SetSetCollapsed(int set, bool collapsed)
	{
		if ((set < 0) || (set >= mMap.Sets.Count) || (IsSetCollapsed(set) == collapsed))
			return;
		if (collapsed)
		{
			mCollapsed.Add(new String(mMap.Sets[set].Name));
			return;
		}
		for (int i < mCollapsed.Count)
		{
			if (mCollapsed[i] == mMap.Sets[set].Name)
			{
				delete mCollapsed[i];
				mCollapsed.RemoveAt(i);
				return;
			}
		}
	}

	/// Adds a binding of `source` to an action: the Add Binding menu's choice.
	public void AddBinding(int set, int action, BindingSource source)
	{
		Mutate(new [=set, =action, =source](m) =>
			{
				if (let target = InputMapEdit.ActionAt(m, set, action))
					target.Bindings.Add(InputMapEdit.FreshBinding(source));
			});
	}

	/// Starts, or on the same slot cancels, a capture into a binding or one composite
	/// direction.
	public void BeginListen(int set, int action, int binding, int compositeDirection = -1)
	{
		// The same key cap again cancels (Escape is a key a game binds, so it cannot cancel).
		if (mListening && (mListenSet == set) && (mListenAction == action) && (mListenBinding == binding) && (mListenDirection == compositeDirection))
		{
			mListening = false;
			mListenDirection = -1;
			RequestRebuild();
			return;
		}
		mListening = true;
		mListenSet = set;
		mListenAction = action;
		mListenBinding = binding;
		mListenDirection = compositeDirection;
		let target = InputMapEdit.ActionAt(mMap, set, action);
		mListenFilter = InputMapEdit.FilterFor((target != null) ? target.Kind : .Button, compositeDirection >= 0);
		// Deferred: this runs inside the key cap's click, which a rebuild would free.
		RequestRebuild();
	}

	/// The undo and redo path, and an edit's: the command's copy becomes the map, and the page
	/// rebuilds unless a field's edit is executing (the field stays under the pointer).
	public void ApplyMap(InputMap map)
	{
		map.CopyTo(mMap);
		if (!mQuietEdit)
			RequestRebuild();
	}

	/// Runs `edit` on a copy and records before and after as one command, whose execute
	/// installs the result. `edit` is consumed.
	public void Mutate(delegate void(InputMap map) edit)
	{
		MutateWith("", false, edit);
	}

	/// A field's edit: no rebuild, and merged with this field's edit before it, so a drag is
	/// one undo step. `edit` is consumed.
	private void MutateField(StringView field, delegate void(InputMap map) edit)
	{
		MutateWith(field, true, edit);
	}

	private void MutateWith(StringView mergeKey, bool quiet, delegate void(InputMap map) edit)
	{
		defer delete edit;
		let after = scope InputMap();
		mMap.CopyTo(after);
		edit(after);
		mQuietEdit = quiet;
		Commands.Execute(new InputMapEditCommand(this, mMap, after, mergeKey));
		mQuietEdit = false;
	}

	/// `apply` is consumed.
	private void MutateAction(int s, int a, delegate void(InputAction action) apply)
	{
		Mutate(new [=s, =a, =apply](m) =>
			{
				if (let action = InputMapEdit.ActionAt(m, s, a))
					apply(action);
			} ~ delete apply);
	}

	private static Binding* BindingAt(InputMap map, int s, int a, int b)
	{
		if (!InputMapEdit.HasBinding(map, s, a, b))
			return null;
		return &InputMapEdit.ActionAt(map, s, a).Bindings[b];
	}

	/// Deferred while attached, since a rebuild tears down the view that asked for it.
	private void RequestRebuild()
	{
		let ctx = (mBody != null) ? mBody.Context : null;
		if (ctx == null)
		{
			Rebuild();
			return;
		}
		ctx.MutationQueue.QueueAction(new [=this]() => { Rebuild(); });
	}

	private void Rebuild()
	{
		// Keep the two-pane selection on something that exists.
		if (mSelectedSet >= mMap.Sets.Count)
		{
			mSelectedSet = Math.Max(mMap.Sets.Count - 1, 0);
			mSelectedAction = -1;
		}
		if (!mMap.Sets.IsEmpty && (mSelectedAction >= mMap.Sets[mSelectedSet].Actions.Count))
			mSelectedAction = mMap.Sets[mSelectedSet].Actions.Count - 1;
		mBody.RemoveAllViews();
		if (mLayout == .Outline)
			BuildOutline();
		else
			BuildTwoPanes();
		RefreshStatus();
		mContent.Invalidate();
	}

	// ==== The outline: each set a collapsible section of its actions =========================

	private void BuildOutline()
	{
		let page = Column(10.0f);
		page.Padding = .(14, 10);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		{
			let head = Row();
			AddLabel(head, "Action sets", 14.0f);
			AddLabel(head, scope $"{mMap.Sets.Count}", 12.0f, true);
			AddSpacer(head);
			let add = new Button("Add Set");
			add.OnClick.Add(new [=this](b) => { Mutate(new (m) => { AddSetTo(m); }); });
			head.AddView(add);
			page.AddView(head, match);
		}
		if (mMap.Sets.IsEmpty)
			AddNote(page, "No action sets. A set groups the actions a game turns on together (gameplay, menus); add one to begin.");

		for (int s < mMap.Sets.Count)
		{
			let set = mMap.Sets[s];
			let section = new Expander();
			section.HeaderHeight.Value = 32.0f;
			// A border round the whole section, band and body: a set reads as one block.
			section.SetStyle(.BorderWidth, 1.0f);
			section.SetStyle(.BorderColor, Color(1.0f, 1.0f, 1.0f, 0.14f));
			section.SetIsExpanded(!IsSetCollapsed(s));
			section.OnExpandedChanged.Add(new [=this, =s](expander, expanded) => { SetSetCollapsed(s, !expanded); });

			// The header: the set's name, renamed in place, then its priority and its verbs.
			let name = new EditableLabel();
			name.SetText(set.Name);
			name.FontSize.Value = 13.5f;
			name.TooltipText.Set("Double-click to rename the set");
			name.OnRenameCommitted.Add(new [=this, =s](label, value) => { RenameSet(s, value); });
			section.SetHeaderTitle(name);
			let verbs = Row(6.0f);
			AddLabel(verbs, scope $"{set.Actions.Count} actions", 11.0f, true);
			AddPriority(verbs, s, set.Priority);
			AddIcon(verbs, EditorIcons.Add, "Add an action to this set", new [=this, =s]() =>
				{
					SetSetCollapsed(s, false);
					Mutate(new [=s](m) => { AddActionTo(m, s); });
				});
			AddIcon(verbs, EditorIcons.Remove, "Remove the set and its actions", new [=this, =s]() => { Mutate(new [=s](m) => { RemoveSetFrom(m, s); }); });
			section.SetHeaderActions(verbs);

			// The body: each action a card.
			let body = Column(8.0f);
			body.Padding = .(8, 4, 8, 8);
			if (set.Actions.IsEmpty)
				AddNote(body, "No actions. Add one with + in the header.");
			for (int a < set.Actions.Count)
			{
				let card = Column(8.0f);
				card.Padding = .(12, 10);
				BuildActionHeader(card, s, a);
				BuildBindings(card, s, a);
				BuildProcessing(card, s, a);
				body.AddView(Card(card), match);
			}
			section.SetContent(body);
			page.AddView(section, match);
		}

		mOutlineScroll.RemoveAllViews();
		mOutlineScroll.AddView(page, match);
		var fill = LayoutStyle();
		fill.FlexGrow = 1.0f;
		fill.Height = SizeSpec.Match();
		mOutlineScroll.AddRef(); // the body's reference; the page keeps its own
		mBody.AddView(mOutlineScroll, fill);
	}

	// ==== Two panes: the sets and actions listed, the selected one edited ====================

	private void BuildTwoPanes()
	{
		let any = !mMap.Sets.IsEmpty;
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();

		// ---- The list ----
		let side = Column(0.0f);
		{
			let bar = Row(4.0f);
			bar.Padding = .(8, 6);
			AddLabel(bar, "Sets and actions", 12.0f, true);
			AddSpacer(bar);
			AddIcon(bar, EditorIcons.Add, "Add a set", new [=this]() =>
				{
					Mutate(new (m) => { AddSetTo(m); });
					Select(mMap.Sets.Count - 1, -1);
				});
			let addAction = AddIcon(bar, EditorIcons.Copy, "Add an action to the selected set", new [=this]() =>
				{
					let s = mSelectedSet;
					Mutate(new [=s](m) => { AddActionTo(m, s); });
					if (s < mMap.Sets.Count)
						Select(s, mMap.Sets[s].Actions.Count - 1);
				});
			addAction.IsEnabled = any;
			let remove = AddIcon(bar, EditorIcons.Remove, "Remove the selected set or action", new [=this]() =>
				{
					let s = mSelectedSet;
					let a = mSelectedAction;
					Mutate(new [=s, =a](m) =>
						{
							if (a < 0)
								RemoveSetFrom(m, s);
							else
								RemoveActionFrom(m, s, a);
						});
				});
			remove.IsEnabled = any;
			side.AddView(bar, match);
		}
		let list = Column(1.0f);
		list.Padding = .(6, 2, 6, 8);
		for (int s < mMap.Sets.Count)
		{
			let set = mMap.Sets[s];
			AddListRow(list, "", set.Name, scope $"priority {set.Priority}", (mSelectedSet == s) && (mSelectedAction < 0), 0.0f, true,
				new [=this, =s]() => { Select(s, -1); });
			for (int a < set.Actions.Count)
			{
				let action = set.Actions[a];
				let badge = (action.Kind == .Axis2D) ? "2D" : (action.Kind == .Axis1D) ? "1D" : "B";
				AddListRow(list, badge, action.Name, "", (mSelectedSet == s) && (mSelectedAction == a), 14.0f, false,
					new [=this, =s, =a]() => { Select(s, a); });
			}
		}
		if (!any)
			AddNote(list, "No action sets yet: add one with +.");
		mListScroll.RemoveAllViews();
		mListScroll.AddView(list, match);
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		grow.Width = SizeSpec.Match();
		mListScroll.AddRef(); // the side's reference; the page keeps its own
		side.AddView(mListScroll, grow);
		var sideWidth = LayoutStyle();
		sideWidth.Width = SizeSpec.Fixed(Unit.Dp(240.0f));
		sideWidth.Height = SizeSpec.Match();
		mBody.AddView(side, sideWidth);
		let rule = new Separator();
		rule.Orientation.Value = .Vertical;
		var line = LayoutStyle();
		line.Width = SizeSpec.Fixed(Unit.Dp(1.0f));
		line.Height = SizeSpec.Match();
		mBody.AddView(rule, line);

		// ---- The selected set or action ----
		let detail = Column(10.0f);
		detail.Padding = .(16, 12);
		if (!any)
			AddNote(detail, "A set groups the actions a game turns on together (gameplay, menus). Add one on the left to begin.");
		else if (mSelectedAction < 0)
			BuildSetFields(detail, mSelectedSet);
		else
		{
			BuildActionHeader(detail, mSelectedSet, mSelectedAction);
			BuildBindings(detail, mSelectedSet, mSelectedAction);
			BuildProcessing(detail, mSelectedSet, mSelectedAction);
		}
		mDetailScroll.RemoveAllViews();
		mDetailScroll.AddView(detail, match);
		var fill = LayoutStyle();
		fill.FlexGrow = 1.0f;
		fill.Height = SizeSpec.Match();
		mDetailScroll.AddRef(); // the body's reference; the page keeps its own
		mBody.AddView(mDetailScroll, fill);
	}

	/// A row of the two-pane list: a toggle, checked while its row is the selection (a click
	/// selects; the rebuild that follows checks the new row). `onClick` is consumed.
	private void AddListRow(FlexLayout list, StringView badge, StringView text, StringView detail, bool selected, float indent, bool strong, delegate void() onClick)
	{
		let content = Row(6.0f);
		content.Padding = .(indent, 0, 0, 0);
		if (!badge.IsEmpty)
		{
			let chip = new Label(badge);
			chip.FontSize.Value = 9.5f;
			chip.TextColor.Value = cDimText;
			let pill = new Panel();
			pill.SetStyle(.Background, new RoundedRectDrawable(Color(1, 1, 1, 0.06f), 3.0f, Color(1, 1, 1, 0.12f), 1.0f));
			pill.SetStyle(.Padding, Thickness(4.0f, 1.0f));
			pill.AddView(chip);
			var chipWidth = LayoutStyle();
			chipWidth.Width = SizeSpec.Fixed(Unit.Dp(26.0f));
			chipWidth.AlignSelf = .Center;
			content.AddView(pill, chipWidth);
		}
		AddLabel(content, text, strong ? 12.5f : 12.0f);
		if (!detail.IsEmpty)
			AddLabel(content, detail, 10.5f, true);
		let row = new ToggleButton();
		row.SetContent(content);
		row.SetStyle(.Padding, Thickness(6.0f, 4.0f));
		row.IsChecked.SetSilent(selected);
		let none = Color(0, 0, 0, 0);
		let look = new StateListDrawable();
		look.Set(.Normal, new RoundedRectDrawable(none, 4.0f));
		look.Set(.Hover, new RoundedRectDrawable(Color(1, 1, 1, 0.05f), 4.0f));
		look.Set(.Checked, new RoundedRectDrawable(Color(cAccent.R, cAccent.G, cAccent.B, 0.28f), 4.0f));
		look.Set(.Checked | .Hover, new RoundedRectDrawable(Color(cAccent.R, cAccent.G, cAccent.B, 0.34f), 4.0f));
		// A checked toggle draws its CheckedBackground (the theme's accent) first: this look too.
		look.AddRef();
		row.SetStyle(.Background, look);
		row.SetStyle(.CheckedBackground, look);
		row.OnClick.Add(new [=onClick](b) => { onClick(); } ~ delete onClick);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		list.AddView(row, match);
	}

	// ==== The editors ==========================================================================

	private void BuildSetFields(FlexLayout column, int s)
	{
		let set = mMap.Sets[s];
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		AddHeading(column, "Action set");
		{
			let row = Row();
			AddLabel(row, "Name", 12.0f, true, cLabelWidth);
			AddNameField(row, set.Name, new [=this, =s](value) => { RenameSet(s, value); });
			column.AddView(row, match);
		}
		{
			let row = Row();
			AddPriority(row, s, set.Priority);
			column.AddView(row, match);
		}
		AddNote(column, "A game turns sets on and off together (gameplay, a menu). When two active sets bind the same input, the one with the higher priority takes it.");
		AddNote(column, scope $"{set.Actions.Count} actions: pick one on the left to edit it.");
	}

	private void BuildActionHeader(FlexLayout column, int s, int a)
	{
		let action = mMap.Sets[s].Actions[a];
		let row = Row(8.0f);
		let name = AddNameField(row, action.Name, new [=this, =s, =a](value) =>
			{
				let renamed = new String(value);
				MutateAction(s, a, new [=renamed](x) => { x.Name.Set(renamed); } ~ delete renamed);
			}, 180.0f);
		name.SetStyle(.FontSize, 14.0f);
		AddSpacer(row);

		StringView[3] kinds = .(InputMapEdit.KindTitle(.Button), InputMapEdit.KindTitle(.Axis1D), InputMapEdit.KindTitle(.Axis2D));
		let kind = AddChoice(row, kinds, (int32)action.Kind, 100.0f, new [=s, =a](m, index) =>
			{
				if (let x = InputMapEdit.ActionAt(m, s, a))
					x.Kind = (ActionKind)index;
			});
		kind.TooltipText.Set("What the action reports: pressed or not, one axis, or two");
		StringView[4] interactions = .("On press", "Hold", "Tap", "Double tap");
		let interaction = AddChoice(row, interactions, (int32)action.Interaction.Kind, 110.0f, new [=s, =a](m, index) =>
			{
				if (let x = InputMapEdit.ActionAt(m, s, a))
					x.Interaction.Kind = (InteractionKind)index;
			});
		interaction.TooltipText.Set("When it fires: as soon as pressed, after a hold, on a quick tap, or on two");
		if (action.Interaction.Kind != .None)
		{
			// What a hold, tap or double tap's seconds mean, before the field.
			AddNumber(row, (action.Interaction.Kind == .Hold) ? "for" : "within", "Seconds", action.Interaction.Seconds, 0.0, 10.0, 2,
				scope $"seconds/{s}/{a}", new [=s, =a](m, v) =>
				{
					if (let x = InputMapEdit.ActionAt(m, s, a))
						x.Interaction.Seconds = (float)v;
				});
			AddLabel(row, "s", 12.0f, true);
		}
		AddIcon(row, EditorIcons.Remove, "Remove the action", new [=this, =s, =a]() => { Mutate(new [=s, =a](m) => { RemoveActionFrom(m, s, a); }); });
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(row, match);
	}

	private void BuildBindings(FlexLayout column, int s, int a)
	{
		let action = mMap.Sets[s].Actions[a];
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		{
			let head = Row(8.0f);
			AddLabel(head, "Bindings", 12.0f, true);
			AddSpacer(head);
			let add = new Button("Add Binding...");
			add.FontSize.Value = 11.0f;
			add.TooltipText.Set("Bind another input: the sources this kind of action takes");
			add.OnClick.Add(new [=this, =add, =s, =a](b) => { ShowAddBindingMenu(add, s, a); });
			var centred = LayoutStyle();
			centred.AlignSelf = .Center;
			head.AddView(add, centred);
			column.AddView(head, match);
		}
		if (action.Bindings.IsEmpty)
			AddNote(column, "No bindings: nothing triggers this action yet.");
		for (int b < action.Bindings.Count)
			BuildBindingCard(column, s, a, b);
	}

	private void ShowAddBindingMenu(View anchor, int s, int a)
	{
		let action = InputMapEdit.ActionAt(mMap, s, a);
		if ((action == null) || (anchor.Context == null))
			return;
		let valid = scope List<BindingSource>();
		BindingNames.ValidSources(action.Kind, valid);
		let menu = new ContextMenu();
		for (let source in valid)
			menu.AddItem(InputMapEdit.SourceTitle(source), new [=this, =s, =a, =source]() => { AddBinding(s, a, source); });
		let at = anchor.LocalToScreen(.(0.0f, anchor.Height));
		menu.Show(anchor.Context, at.X, at.Y);
		menu.ReleaseRef();
	}

	private void BuildBindingCard(FlexLayout column, int s, int a, int b)
	{
		let action = mMap.Sets[s].Actions[a];
		let binding = action.Bindings[b];
		let inner = Column(6.0f);
		inner.Padding = .(10, 8);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();

		let top = Row(8.0f);
		AddLabel(top, InputMapEdit.SourceTitle(binding.Source), 11.5f, true, 110.0f);
		if (binding.Source == .Composite2D)
		{
			// The four keys as they sit on a keyboard: up over left, down, right.
			let cross = Column(3.0f);
			let upper = Row(3.0f);
			let lower = Row(3.0f);
			var cell = LayoutStyle();
			cell.Width = SizeSpec.Fixed(Unit.Dp(46.0f));
			upper.AddView(new View(), cell);
			AddKeycap(upper, BindingNames.KeyName(binding.PosY, .. scope .()), s, a, b, 3, 46.0f);
			AddKeycap(lower, BindingNames.KeyName(binding.NegX, .. scope .()), s, a, b, 0, 46.0f);
			AddKeycap(lower, BindingNames.KeyName(binding.NegY, .. scope .()), s, a, b, 2, 46.0f);
			AddKeycap(lower, BindingNames.KeyName(binding.PosX, .. scope .()), s, a, b, 1, 46.0f);
			cross.AddView(upper);
			cross.AddView(lower);
			top.AddView(cross);
		}
		else
			AddKeycap(top, BindingNames.DescribeBinding(binding, .. scope .()), s, a, b, -1, 96.0f);
		AddSpacer(top);
		AddIcon(top, EditorIcons.Remove, "Remove the binding", new [=this, =s, =a, =b]() =>
			{
				Mutate(new [=s, =a, =b](m) =>
					{
						if (InputMapEdit.HasBinding(m, s, a, b))
							InputMapEdit.ActionAt(m, s, a).Bindings.RemoveAt(b);
					});
			});
		inner.AddView(top, match);

		if (!InputMapEdit.SourceFitsKind(action.Kind, binding.Source))
		{
			let warning = new Label(scope $"A {InputMapEdit.KindTitle(action.Kind)} does not take a {InputMapEdit.SourceTitle(binding.Source)} binding: remove it, or change the action's kind.");
			warning.FontSize.Value = 11.0f;
			warning.WordWrap.Value = true;
			warning.TextColor.Value = cWarningText;
			inner.AddView(warning, match);
		}
		BuildBindingSettings(inner, s, a, b);
		column.AddView(Card(inner, 0.05f), match);
	}

	private void BuildBindingSettings(FlexLayout column, int s, int a, int b)
	{
		let binding = mMap.Sets[s].Actions[a].Bindings[b];
		let source = binding.Source;
		let hasDeadZone = (source == .MouseAxis) || (source == .GamepadAxis) || (source == .GamepadStick) || (source == .TouchStick);
		let hasScale = source != .TouchButton;
		let hasInvert = (source == .MouseAxis) || (source == .MouseDelta) || (source == .GamepadAxis) || (source == .GamepadStick) || (source == .TouchStick) || (source == .Composite2D);
		let hasDevice = (source == .GamepadButton) || (source == .GamepadAxis) || (source == .GamepadStick);
		let hasRegion = (source == .TouchButton) || (source == .TouchStick);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();

		let row = Row(14.0f);
		row.Padding = .(118, 0, 0, 0); // under the input, past the source's name
		if (hasDeadZone)
		{
			AddNumber(row, "Dead zone", "Movement smaller than this reads as none", binding.DeadZone, 0.0, 1.0, 2, scope $"deadZone/{s}/{a}/{b}",
				new [=s, =a, =b](m, v) => { if (let x = BindingAt(m, s, a, b)) x.DeadZone = (float)v; });
		}
		if (hasScale)
		{
			AddNumber(row, "Scale", "Multiplies what the input reports (negative flips it)", binding.Scale, -100.0, 100.0, 2, scope $"scale/{s}/{a}/{b}",
				new [=s, =a, =b](m, v) => { if (let x = BindingAt(m, s, a, b)) x.Scale = (float)v; });
		}
		if (hasInvert)
			AddCheck(row, "Invert", "Flip the direction", binding.Invert, new [=s, =a, =b](m, v) => { if (let x = BindingAt(m, s, a, b)) x.Invert = v; });
		if (source == .Composite2D)
			AddCheck(row, "Normalize", "Diagonals as long as straight moves", binding.Normalize, new [=s, =a, =b](m, v) => { if (let x = BindingAt(m, s, a, b)) x.Normalize = v; });
		if (hasDevice)
		{
			AddLabel(row, "Gamepad", 11.5f, true);
			StringView[5] pads = .("Any", "1", "2", "3", "4");
			let pad = AddChoice(row, pads, Math.Clamp(binding.Device + 1, 0, 4), 70.0f,
				new [=s, =a, =b](m, index) => { if (let x = BindingAt(m, s, a, b)) x.Device = index - 1; });
			pad.TooltipText.Set("Which connected gamepad: any, or one by its number");
		}
		if (row.ChildCount > 0)
			column.AddView(row, match);
		else
			row.ReleaseRef();
		if (hasRegion)
		{
			let region = Row(14.0f);
			region.Padding = .(118, 0, 0, 0);
			AddLabel(region, "Screen area", 11.5f, true);
			StringView[4] names = .("X", "Y", "Width", "Height");
			float[4] values = .(binding.RegionX, binding.RegionY, binding.RegionW, binding.RegionH);
			for (int i < 4)
			{
				AddNumber(region, names[i], "A fraction of the screen, 0 to 1", values[i], 0.0, 1.0, 2, scope $"{names[i]}/{s}/{a}/{b}",
					new [=s, =a, =b, =i](m, v) =>
					{
						if (let x = BindingAt(m, s, a, b))
						{
							switch (i)
							{
							case 0: x.RegionX = (float)v;
							case 1: x.RegionY = (float)v;
							case 2: x.RegionW = (float)v;
							default: x.RegionH = (float)v;
							}
						}
					});
			}
			if (source == .TouchStick)
			{
				AddNumber(region, "Radius", "How far the stick reaches, in pixels", binding.StickRadius, 0.0, 1000.0, 0, scope $"radius/{s}/{a}/{b}",
					new [=s, =a, =b](m, v) => { if (let x = BindingAt(m, s, a, b)) x.StickRadius = (float)v; });
			}
			column.AddView(region, match);
		}
	}

	private void BuildProcessing(FlexLayout column, int s, int a)
	{
		let action = mMap.Sets[s].Actions[a];
		if (action.Kind == .Button)
			return; // a button reports pressed or not: nothing to shape
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		{
			let head = Row(8.0f); // at the left, as "Bindings" is (a label alone in a column centres)
			AddLabel(head, "Processing", 12.0f, true);
			column.AddView(head, match);
		}
		let row = Row(14.0f);
		AddNumber(row, "Sensitivity", "Above 0, a key-driven axis ramps toward its value at this rate a second", action.Processors.Sensitivity, 0.0, 100.0, 2,
			scope $"sensitivity/{s}/{a}", new [=s, =a](m, v) => { if (let x = InputMapEdit.ActionAt(m, s, a)) x.Processors.Sensitivity = (float)v; });
		AddNumber(row, "Gravity", "Above 0, the rate a second it returns to rest once released", action.Processors.Gravity, 0.0, 100.0, 2,
			scope $"gravity/{s}/{a}", new [=s, =a](m, v) => { if (let x = InputMapEdit.ActionAt(m, s, a)) x.Processors.Gravity = (float)v; });
		AddNumber(row, "Curve", "Shapes an analog input: the value to this power (1 is straight)", action.Processors.ResponseExponent, 0.1, 5.0, 2,
			scope $"curve/{s}/{a}", new [=s, =a](m, v) => { if (let x = InputMapEdit.ActionAt(m, s, a)) x.Processors.ResponseExponent = (float)v; });
		column.AddView(row, match);
		let flags = Row(14.0f);
		AddCheck(flags, "Snap on reverse", "Jump to zero first when the direction flips", action.Processors.Snap,
			new [=s, =a](m, v) => { if (let x = InputMapEdit.ActionAt(m, s, a)) x.Processors.Snap = v; });
		AddCheck(flags, "Scale with time", "Multiply by the game's time scale, once there is one", action.Processors.TimeScale,
			new [=s, =a](m, v) => { if (let x = InputMapEdit.ActionAt(m, s, a)) x.Processors.TimeScale = v; });
		column.AddView(flags, match);
	}

	// ==== The map edits the verbs share ========================================================

	private static void AddSetTo(InputMap map)
	{
		let set = new ActionSet();
		set.Name.Set("NewSet");
		map.Sets.Add(set);
	}

	private static void RemoveSetFrom(InputMap map, int s)
	{
		if (let target = InputMapEdit.SetAt(map, s))
		{
			delete target;
			map.Sets.RemoveAt(s);
		}
	}

	private static void AddActionTo(InputMap map, int s)
	{
		if (let target = InputMapEdit.SetAt(map, s))
		{
			let action = new InputAction();
			action.Name.Set("NewAction");
			target.Actions.Add(action);
		}
	}

	private static void RemoveActionFrom(InputMap map, int s, int a)
	{
		if (let target = InputMapEdit.ActionAt(map, s, a))
		{
			delete target;
			map.Sets[s].Actions.RemoveAt(a);
		}
	}

	private void RenameSet(int s, StringView value)
	{
		if (value.IsEmpty)
			return;
		let renamed = new String(value);
		Mutate(new [=s, =renamed](m) =>
			{
				if (let target = InputMapEdit.SetAt(m, s))
					target.Name.Set(renamed);
			} ~ delete renamed);
	}

	private void AddPriority(FlexLayout row, int s, int32 priority)
	{
		AddNumber(row, "Priority", "When two active sets bind the same input, the higher priority takes it", priority, -100.0, 100.0, 0,
			scope $"priority/{s}", new [=s](m, v) =>
			{
				if (let target = InputMapEdit.SetAt(m, s))
					target.Priority = (int32)v;
			});
	}

	// ==== Small pieces =========================================================================

	private ScrollView MakeScroll()
	{
		let scroll = new ScrollView();
		scroll.VScrollBarPolicy.Value = .Auto;
		scroll.HScrollBarPolicy.Value = .Never;
		return scroll;
	}

	private static FlexLayout Row(float spacing = 8.0f)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = spacing;
		row.AlignItems = .Center;
		return row;
	}

	private static FlexLayout Column(float spacing = 6.0f)
	{
		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = spacing;
		return column;
	}

	private static void AddSpacer(FlexLayout row)
	{
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		row.AddView(new View(), grow);
	}

	private static Label AddLabel(FlexLayout row, StringView text, float size = 12.0f, bool dim = false, float width = 0.0f)
	{
		let label = new Label(text);
		label.FontSize.Value = size;
		if (dim)
			label.TextColor.Value = cDimText;
		var style = LayoutStyle();
		if (width > 0.0f)
			style.Width = SizeSpec.Fixed(Unit.Dp(width));
		style.AlignSelf = .Center;
		row.AddView(label, style);
		return label;
	}

	private static void AddHeading(FlexLayout column, StringView text)
	{
		let label = new Label(text);
		label.FontSize.Value = 15.0f;
		column.AddView(label);
	}

	private static void AddNote(FlexLayout column, StringView text)
	{
		let note = new Label(text);
		note.FontSize.Value = 11.0f;
		note.WordWrap.Value = true;
		note.TextColor.Value = cDimText;
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(note, match);
	}

	/// A rounded panel around `content` (a binding, an action in the outline), which it takes.
	private static Panel Card(View content, float fill = 0.035f)
	{
		let panel = new Panel();
		panel.SetStyle(.Background, new RoundedRectDrawable(Color(1, 1, 1, fill), 6.0f, Color(1, 1, 1, 0.09f), 1.0f));
		panel.AddView(content);
		return panel;
	}

	/// A name, committed when it is not empty. `commit` is consumed.
	private EditText AddNameField(FlexLayout row, StringView value, delegate void(StringView) commit, float width = 0.0f)
	{
		let field = new EditText();
		field.SetText(value);
		field.OnCommit.Add(new [=commit](edit) =>
			{
				if (!edit.Text.IsEmpty)
					commit(edit.Text);
			} ~ delete commit);
		var style = LayoutStyle();
		if (width > 0.0f)
			style.Width = SizeSpec.Fixed(Unit.Dp(width));
		else
			style.FlexGrow = 1.0f;
		style.AlignSelf = .Center;
		row.AddView(field, style);
		return field;
	}

	/// A labelled number. Its edits are the field's (`field`, the merge key): quiet, and one
	/// undo step however many a drag makes. `apply` is consumed.
	private NumericField AddNumber(FlexLayout row, StringView label, StringView tooltip, double value, double least, double most, int32 decimals,
		StringView field, delegate void(InputMap map, double value) apply)
	{
		let pair = Row(5.0f);
		AddLabel(pair, label, 11.5f, true);
		let number = new NumericField();
		number.SetDecimalPlaces(decimals);
		number.SetMin(least);
		number.SetMax(most);
		number.SetStep((decimals == 0) ? 1.0 : 0.05);
		number.SetValue(value);
		number.TooltipText.Set(tooltip);
		let key = new String(field);
		number.OnValueChanged.Add(new [=this, =key, =apply](numeric, v) =>
			{
				MutateField(key, new [=apply, =v](m) => { apply(m, v); });
			} ~ { delete key; delete apply; });
		var fixedWidth = LayoutStyle();
		fixedWidth.Width = SizeSpec.Fixed(Unit.Dp(64.0f));
		fixedWidth.AlignSelf = .Center;
		pair.AddView(number, fixedWidth);
		row.AddView(pair);
		return number;
	}

	/// `apply` is consumed.
	private CheckBox AddCheck(FlexLayout row, StringView label, StringView tooltip, bool value, delegate void(InputMap map, bool value) apply)
	{
		let check = new CheckBox(label, value);
		check.FontSize.Value = 11.5f;
		check.TooltipText.Set(tooltip);
		check.OnCheckedChanged.Add(new [=this, =apply](control, v) =>
			{
				Mutate(new [=apply, =v](m) => { apply(m, v); });
			} ~ delete apply);
		var centred = LayoutStyle();
		centred.AlignSelf = .Center;
		row.AddView(check, centred);
		return check;
	}

	/// `apply` is consumed.
	private ComboBox AddChoice(FlexLayout row, Span<StringView> items, int32 selected, float width, delegate void(InputMap map, int32 index) apply)
	{
		let combo = new ComboBox();
		for (let item in items)
			combo.AddItem(item);
		combo.SetSelectedIndex(selected);
		combo.OnSelectionChanged.Add(new [=this, =apply](control, index) =>
			{
				Mutate(new [=apply, =index](m) => { apply(m, index); });
			} ~ delete apply);
		var fixedWidth = LayoutStyle();
		fixedWidth.Width = SizeSpec.Fixed(Unit.Dp(width));
		fixedWidth.AlignSelf = .Center;
		row.AddView(combo, fixedWidth);
		return combo;
	}

	/// A key cap showing an input: click it, then press the new input. `direction` at or above
	/// zero is one key of a four-key composite.
	private Button AddKeycap(FlexLayout row, StringView text, int s, int a, int b, int direction, float minWidth = 0.0f)
	{
		let listening = mListening && (mListenSet == s) && (mListenAction == a) && (mListenBinding == b) && (mListenDirection == direction);
		let cap = new Button(listening ? "Press..." : text);
		cap.FontSize.Value = 12.0f;
		cap.SetStyle(.Padding, Thickness(8.0f, 3.0f));
		cap.TooltipText.Set(listening ? "Press the new input, or click to cancel" : "Click, then press the new input");
		let fill = listening ? Color(cAccent.R, cAccent.G, cAccent.B, 0.35f) : Color(1, 1, 1, 0.07f);
		let edge = listening ? cAccent : Color(1, 1, 1, 0.22f);
		let look = new StateListDrawable();
		look.Set(.Normal, new RoundedRectDrawable(fill, 4.0f, edge, 1.0f));
		look.Set(.Hover, new RoundedRectDrawable(Color(fill.R, fill.G, fill.B, fill.A + 0.06f), 4.0f, edge, 1.0f));
		look.Set(.Pressed, new RoundedRectDrawable(Color(fill.R, fill.G, fill.B, fill.A + 0.10f), 4.0f, edge, 1.0f));
		cap.SetStyle(.Background, look);
		cap.OnClick.Add(new [=this, =s, =a, =b, =direction](button) => { BeginListen(s, a, b, direction); });
		var style = LayoutStyle();
		style.AlignSelf = .Center;
		if (minWidth > 0.0f)
			style.MinWidth = Unit.Dp(minWidth);
		row.AddView(cap, style);
		return cap;
	}

	/// An add or remove verb, as the icon every editor list uses. `onClick` is consumed.
	private static IconButton AddIcon(FlexLayout row, SVGDrawable icon, StringView tooltip, delegate void() onClick, float size = 14.0f)
	{
		let button = new IconButton(icon, size);
		button.TooltipText.Set(tooltip);
		button.OnClick.Add(new [=onClick](b) => { onClick(); } ~ delete onClick);
		var style = LayoutStyle();
		style.AlignSelf = .Center;
		row.AddView(button, style);
		return button;
	}

	private void RefreshStatus()
	{
		if (mListening)
		{
			mStatus.SetText("Listening: press the new input (click the key cap again to cancel)");
			mStatus.TextColor.Value = cAccent;
			return;
		}
		let error = scope String();
		if (!InputMapValidation.Validate(mMap, error))
		{
			mStatus.SetText(scope $"Cannot save yet: {error}");
			mStatus.TextColor.Value = cWarningText;
			return;
		}
		int actions = 0;
		int bindings = 0;
		for (let set in mMap.Sets)
		{
			actions += set.Actions.Count;
			for (let action in set.Actions)
				bindings += action.Bindings.Count;
		}
		mStatus.SetText(scope $"{mMap.Sets.Count} sets · {actions} actions · {bindings} bindings");
		mStatus.TextColor.Value = cDimText;
	}
}
