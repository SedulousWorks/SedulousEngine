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

/// The input map page: sets over actions over bindings as rows of buttons and editable
/// labels, every change a deep copy command, and Listen capturing the next input from the
/// shell into a binding or one composite direction. Save validates the map first.
class InputMapEditorPage : UIEditorPage
{
	/// Borrowed.
	private EditorContext mContext;
	private String mTitle = new .() ~ delete _;
	/// The map being edited, owned.
	private InputMap mMap = new .() ~ delete _;

	/// Borrowed: the content owns them.
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private ScrollView mScroll = null;
	private FlexLayout mRows = null;
	private Label mStatus = null;

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
		column.Padding = .(8, 6);
		mStatus = new Label("");
		mStatus.FontSize.Value = 12.0f;
		var statusStyle = LayoutStyle();
		statusStyle.Width = SizeSpec.Match();
		statusStyle.Height = SizeSpec.Fixed(Unit.Dp(20));
		column.AddView(mStatus, statusStyle);
		mScroll = new ScrollView();
		mRows = new FlexLayout();
		mRows.Direction = .Vertical;
		mRows.Spacing = 2.0f;
		mScroll.AddView(mRows);
		var growMatch = LayoutStyle();
		growMatch.Width = SizeSpec.Match();
		growMatch.FlexGrow = 1.0f;
		column.AddView(mScroll, growMatch);
		mContent = column;
		Rebuild();
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public InputMap Map => mMap;
	public bool IsListening => mListening;

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
		if (!mListening)
			return;
		let shellInput = (host.Shell != null) ? host.Shell.Input : null;
		if (shellInput == null)
			return;
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

	/// The undo and redo path: the command's copy becomes the map and the rows rebuild.
	public void ApplyMap(InputMap map)
	{
		map.CopyTo(mMap);
		RequestRebuild();
	}

	/// Runs `edit` on a copy and records before and after as one command, whose execute
	/// installs the result. `edit` is consumed.
	public void Mutate(delegate void(InputMap map) edit)
	{
		defer delete edit;
		let after = scope InputMap();
		mMap.CopyTo(after);
		edit(after);
		Commands.Execute(new InputMapEditCommand(this, mMap, after));
	}

	private void MutateAction(int s, int a, delegate void(InputAction action) apply)
	{
		Mutate(new [=s, =a, =apply](m) =>
			{
				if (let action = InputMapEdit.ActionAt(m, s, a))
					apply(action);
			} ~ delete apply);
	}

	private void MutateBinding(int s, int a, int b, delegate void(Binding* binding) apply)
	{
		Mutate(new [=s, =a, =b, =apply](m) =>
			{
				if (!InputMapEdit.HasBinding(m, s, a, b))
					return;
				let action = InputMapEdit.ActionAt(m, s, a);
				var binding = action.Bindings[b];
				apply(&binding);
				action.Bindings[b] = binding;
			} ~ delete apply);
	}

	/// `onClick` is consumed.
	private Button MakeButton(FlexLayout row, StringView label, float width, delegate void() onClick)
	{
		let button = new Button(label);
		button.FontSize.Value = 11.0f;
		button.OnClick.Add(new [=onClick](btn) => { onClick(); } ~ delete onClick);
		var style = LayoutStyle();
		style.Width = SizeSpec.Fixed(Unit.Dp(width));
		style.Height = SizeSpec.Match();
		row.AddView(button, style);
		return button;
	}

	private FlexLayout MakeRow(float indent, float height = 24.0f)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 4.0f;
		row.Padding = .(indent, 0);
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		style.Height = SizeSpec.Fixed(Unit.Dp(height));
		mRows.AddView(row, style);
		return row;
	}

	private void AddLabel(FlexLayout row, StringView text, float grow = 0.0f, float width = 0.0f)
	{
		let label = new Label(text);
		label.FontSize.Value = 12.0f;
		var style = LayoutStyle();
		if (grow > 0.0f)
			style.FlexGrow = grow;
		else if (width > 0.0f)
			style.Width = SizeSpec.Fixed(Unit.Dp(width));
		style.Height = SizeSpec.Match();
		row.AddView(label, style);
	}

	/// A labelled number, committed on rename when it parses. `commit` is consumed.
	private void AddFloatField(FlexLayout row, StringView label, float value, delegate void(float) commit, float width = 46.0f)
	{
		AddLabel(row, label, 0.0f, (float)label.Length * 7.0f + 6.0f);
		let field = new EditableLabel();
		field.SetText(scope $"{value}");
		field.FontSize.Value = 12.0f;
		field.OnRenameCommitted.Add(new [=commit](editable, committed) =>
			{
				if (committed.IsEmpty)
					return;
				if (float.Parse(committed) case .Ok(let parsed))
					commit(parsed);
			} ~ delete commit);
		var style = LayoutStyle();
		style.Width = SizeSpec.Fixed(Unit.Dp(width));
		style.Height = SizeSpec.Match();
		row.AddView(field, style);
	}

	/// A "name:on"/"name:off" button flipping the flag. `commit` is consumed.
	private void AddToggle(FlexLayout row, StringView label, bool value, delegate void(bool) commit)
	{
		let text = scope $"{label}{value ? ":on" : ":off"}";
		MakeButton(row, text, (float)text.Length * 7.0f + 14.0f, new [=commit, =value]() => { commit(!value); } ~ delete commit);
	}

	/// `commit` is consumed.
	private void AddNameEditor(FlexLayout row, StringView name, delegate void(StringView) commit)
	{
		let label = new EditableLabel();
		label.SetText(name);
		label.FontSize.Value = 12.0f;
		label.OnRenameCommitted.Add(new [=commit](editable, value) =>
			{
				if (!value.IsEmpty)
					commit(value);
			} ~ delete commit);
		var style = LayoutStyle();
		style.FlexGrow = 1.0f;
		style.Height = SizeSpec.Match();
		row.AddView(label, style);
	}

	/// Deferred while attached, since a rebuild tears down the row that asked for it.
	private void RequestRebuild()
	{
		let ctx = (mRows != null) ? mRows.Context : null;
		if (ctx == null)
		{
			Rebuild();
			return;
		}
		ctx.MutationQueue.QueueAction(new [=this]() => { Rebuild(); });
	}

	private void Rebuild()
	{
		mRows.RemoveAllViews();
		for (int s < mMap.Sets.Count)
		{
			let set = mMap.Sets[s];
			let header = MakeRow(0.0f, 26.0f);
			AddNameEditor(header, set.Name, new [=this, =s](value) =>
				{
					let name = new String(value);
					Mutate(new [=s, =name](m) =>
						{
							if (let target = InputMapEdit.SetAt(m, s))
								target.Name.Set(name);
						} ~ delete name);
				});
			AddLabel(header, scope $"prio {set.Priority}", 0.0f, 52.0f);
			MakeButton(header, "+", 22.0f, new [=this, =s]() => { Mutate(new [=s](m) => { if (let target = InputMapEdit.SetAt(m, s)) target.Priority += 1; }); });
			MakeButton(header, "-", 22.0f, new [=this, =s]() => { Mutate(new [=s](m) => { if (let target = InputMapEdit.SetAt(m, s)) target.Priority -= 1; }); });
			MakeButton(header, "+ Action", 70.0f, new [=this, =s]() =>
				{
					Mutate(new [=s](m) =>
						{
							if (let target = InputMapEdit.SetAt(m, s))
							{
								let action = new InputAction();
								action.Name.Set("NewAction");
								target.Actions.Add(action);
							}
						});
				});
			MakeButton(header, "x", 22.0f, new [=this, =s]() =>
				{
					Mutate(new [=s](m) =>
						{
							if (let target = InputMapEdit.SetAt(m, s))
							{
								delete target;
								m.Sets.RemoveAt(s);
							}
						});
				});

			for (int a < set.Actions.Count)
			{
				let action = set.Actions[a];
				let row = MakeRow(18.0f);
				AddNameEditor(row, action.Name, new [=this, =s, =a](value) =>
					{
						let name = new String(value);
						MutateAction(s, a, new [=name](x) => { x.Name.Set(name); } ~ delete name);
					});
				MakeButton(row, BindingNames.KindName(action.Kind), 60.0f, new [=this, =s, =a]() =>
					{
						MutateAction(s, a, new (x) => { x.Kind = (ActionKind)(((uint8)x.Kind + 1) % 3); });
					});
				MakeButton(row, BindingNames.InteractionName(action.Interaction.Kind), 80.0f, new [=this, =s, =a]() =>
					{
						MutateAction(s, a, new (x) => { x.Interaction.Kind = (InteractionKind)(((uint8)x.Interaction.Kind + 1) % 4); });
					});
				MakeButton(row, "+ Binding", 74.0f, new [=this, =s, =a]() =>
					{
						MutateAction(s, a, new (x) => { x.Bindings.Add(InputMapEdit.FreshBinding(x.Kind)); });
					});
				MakeButton(row, "x", 22.0f, new [=this, =s, =a]() =>
					{
						Mutate(new [=s, =a](m) =>
							{
								if (let target = InputMapEdit.ActionAt(m, s, a))
								{
									delete target;
									m.Sets[s].Actions.RemoveAt(a);
								}
							});
					});

				for (int b < action.Bindings.Count)
				{
					let binding = action.Bindings[b];
					let bindingRow = MakeRow(40.0f, 22.0f);
					let isListening = mListening && (mListenSet == s) && (mListenAction == a) && (mListenBinding == b);
					MakeButton(bindingRow, BindingNames.SourceName(binding.Source), 76.0f, new [=this, =s, =a, =b]() =>
						{
							Mutate(new [=s, =a, =b](m) =>
								{
									if (!InputMapEdit.HasBinding(m, s, a, b))
										return;
									let target = InputMapEdit.ActionAt(m, s, a);
									target.Bindings[b] = InputMapEdit.CycleSource(target.Kind, target.Bindings[b]);
								});
						});
					AddLabel(bindingRow, isListening ? "<press an input...>" : BindingNames.DescribeBinding(binding, .. scope .()), 1.0f);
					let listenLabel = (isListening && (mListenDirection == -1)) ? "Cancel" : "Listen";
					MakeButton(bindingRow, listenLabel, 54.0f, new [=this, =s, =a, =b]() => { BeginListen(s, a, b); });
					MakeButton(bindingRow, "x", 22.0f, new [=this, =s, =a, =b]() =>
						{
							Mutate(new [=s, =a, =b](m) =>
								{
									if (InputMapEdit.HasBinding(m, s, a, b))
										InputMapEdit.ActionAt(m, s, a).Bindings.RemoveAt(b);
								});
						});
					BuildBindingDetail(s, a, b, binding);
				}

				let proc = MakeRow(40.0f, 20.0f);
				if (action.Interaction.Kind != .None)
					AddFloatField(proc, "sec", action.Interaction.Seconds, new [=this, =s, =a](v) => { MutateAction(s, a, new [=v](x) => { x.Interaction.Seconds = v; }); });
				if (action.Kind != .Button)
				{
					AddFloatField(proc, "sens", action.Processors.Sensitivity, new [=this, =s, =a](v) => { MutateAction(s, a, new [=v](x) => { x.Processors.Sensitivity = v; }); });
					AddFloatField(proc, "grav", action.Processors.Gravity, new [=this, =s, =a](v) => { MutateAction(s, a, new [=v](x) => { x.Processors.Gravity = v; }); });
					AddToggle(proc, "snap", action.Processors.Snap, new [=this, =s, =a](v) => { MutateAction(s, a, new [=v](x) => { x.Processors.Snap = v; }); });
					AddFloatField(proc, "curve", action.Processors.ResponseExponent, new [=this, =s, =a](v) => { MutateAction(s, a, new [=v](x) => { x.Processors.ResponseExponent = v; }); });
					AddToggle(proc, "tScale", action.Processors.TimeScale, new [=this, =s, =a](v) => { MutateAction(s, a, new [=v](x) => { x.Processors.TimeScale = v; }); });
				}
			}
		}
		let footer = MakeRow(0.0f, 26.0f);
		MakeButton(footer, "+ Add Set", 90.0f, new [=this]() =>
			{
				Mutate(new (m) =>
					{
						let set = new ActionSet();
						set.Name.Set("NewSet");
						m.Sets.Add(set);
					});
			});
		RefreshStatus();
		mContent.Invalidate();
	}

	/// Starts, or on the same slot cancels, a capture into a binding or one composite
	/// direction.
	private void BeginListen(int set, int action, int binding, int compositeDirection = -1)
	{
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
		RequestRebuild();
	}

	private void BuildBindingDetail(int s, int a, int b, Binding binding)
	{
		let source = binding.Source;
		let hasDeadZone = (source == .MouseAxis) || (source == .GamepadAxis) || (source == .GamepadStick) || (source == .TouchStick);
		let hasScale = source != .TouchButton;
		let hasInvert = (source == .MouseAxis) || (source == .MouseDelta) || (source == .GamepadAxis) || (source == .GamepadStick) || (source == .TouchStick) || (source == .Composite2D);
		let hasDevice = (source == .GamepadButton) || (source == .GamepadAxis) || (source == .GamepadStick);
		let hasRegion = (source == .TouchButton) || (source == .TouchStick);
		let detail = MakeRow(62.0f, 20.0f);
		if (hasDeadZone)
			AddFloatField(detail, "dz", binding.DeadZone, new [=this, =s, =a, =b](v) => { MutateBinding(s, a, b, new [=v](x) => { x.DeadZone = v; }); });
		if (hasScale)
			AddFloatField(detail, "scale", binding.Scale, new [=this, =s, =a, =b](v) => { MutateBinding(s, a, b, new [=v](x) => { x.Scale = v; }); });
		if (hasInvert)
			AddToggle(detail, "inv", binding.Invert, new [=this, =s, =a, =b](v) => { MutateBinding(s, a, b, new [=v](x) => { x.Invert = v; }); });
		if (hasDevice)
			AddFloatField(detail, "pad", (float)binding.Device, new [=this, =s, =a, =b](v) => { MutateBinding(s, a, b, new [=v](x) => { x.Device = (int32)v; }); });
		if (source == .Composite2D)
		{
			AddToggle(detail, "norm", binding.Normalize, new [=this, =s, =a, =b](v) => { MutateBinding(s, a, b, new [=v](x) => { x.Normalize = v; }); });
			StringView[4] labels = .("-X", "+X", "-Y", "+Y");
			for (int d < 4)
			{
				let code = (d == 0) ? binding.NegX : (d == 1) ? binding.PosX : (d == 2) ? binding.NegY : binding.PosY;
				let text = scope String(labels[d]);
				text.Append(" ");
				BindingNames.KeyName(code, text);
				let listeningDir = mListening && (mListenSet == s) && (mListenAction == a) && (mListenBinding == b) && (mListenDirection == d);
				MakeButton(detail, listeningDir ? "Cancel" : text, 74.0f, new [=this, =s, =a, =b, =d]() => { BeginListen(s, a, b, d); });
			}
		}
		if (hasRegion)
		{
			AddFloatField(detail, "rx", binding.RegionX, new [=this, =s, =a, =b](v) => { MutateBinding(s, a, b, new [=v](x) => { x.RegionX = v; }); });
			AddFloatField(detail, "ry", binding.RegionY, new [=this, =s, =a, =b](v) => { MutateBinding(s, a, b, new [=v](x) => { x.RegionY = v; }); });
			AddFloatField(detail, "rw", binding.RegionW, new [=this, =s, =a, =b](v) => { MutateBinding(s, a, b, new [=v](x) => { x.RegionW = v; }); });
			AddFloatField(detail, "rh", binding.RegionH, new [=this, =s, =a, =b](v) => { MutateBinding(s, a, b, new [=v](x) => { x.RegionH = v; }); });
		}
		if (source == .TouchStick)
			AddFloatField(detail, "radius", binding.StickRadius, new [=this, =s, =a, =b](v) => { MutateBinding(s, a, b, new [=v](x) => { x.StickRadius = v; }); });
	}

	private void RefreshStatus()
	{
		if (mListening)
		{
			mStatus.SetText("Listening... press the new input (Esc cancels)");
			return;
		}
		let error = scope String();
		if (!InputMapValidation.Validate(mMap, error))
			mStatus.SetText(scope $"Invalid: {error}");
		else
			mStatus.SetText("Sets > actions > bindings. Click names to rename; Listen rebinds.");
	}
}
