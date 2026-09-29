using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

/// The side panels: the layer and parameter list on the left, and the inspector for the
/// selected layer, parameter, state or transition on the right.
extension AnimationGraphEditorPage
{
	private static readonly StringView[2] cBlendModes = .("Override", "Additive");
	private static readonly StringView[4] cParamTypes = .("Float", "Int", "Bool", "Trigger");
	private static readonly StringView[6] cCompareOps = .("==", "!=", ">", "<", ">=", "<=");

	private void RebuildLeftPanel()
	{
		mLeftRows.RemoveAllViews();
		if (mAsset == null)
			return;

		AddLeftHeader("Layers", "Add layer", new [=this]() =>
			{
				QueueStructural("add-layer", new [=this]() =>
					{
						mDoc.AddLayer(scope $"Layer {mDoc.Layers.Count}");
						mSelectedLayer = (int32)mDoc.Layers.Count - 1;
					}, .(.Layer, 0, 0));
			});
		for (int32 l < (int32)mDoc.Layers.Count)
		{
			let layerIndex = l;
			let text = scope String(mDoc.Layers[l].Name);
			if (layerIndex == mSelectedLayer)
				text.Append("  <");
			AddLeftRow(text, new [=this, =layerIndex]() =>
				{
					mSelectedLayer = layerIndex;
					Select(.(.Layer, layerIndex, layerIndex));
					if (let ctx = Ctx)
					{
						ctx.MutationQueue.QueueAction(new [=this]() =>
							{
								RebuildLeftPanel();
								RebuildCanvas();
							});
					}
				}, layerIndex == mSelectedLayer,
				(mDoc.Layers.Count > 1) ? new [=this, =layerIndex]() => { DeleteLayer(layerIndex); } : null);
		}

		AddLeftHeader("Parameters", "Add parameter", new [=this]() =>
			{
				QueueStructural("add-param", new [=this]() => { mDoc.AddParam(scope $"Param{mDoc.Params.Count}", 0); }, .(.Parameter, 0, GraphSel.Last));
			});
		for (int32 p < (int32)mDoc.Params.Count)
		{
			let paramIndex = p;
			AddLeftRow(mDoc.Params[p].Name, new [=this, =paramIndex]() => { Select(.(.Parameter, 0, paramIndex)); },
				(mSelected.Kind == .Parameter) && (mSelected.Index == paramIndex),
				new [=this, =paramIndex]() => { DeleteParam(paramIndex); });
		}
	}

	/// A list's header: its title, and its add icon on the right. `onAdd` is consumed.
	private void AddLeftHeader(StringView text, StringView addTooltip, delegate void() onAdd)
	{
		mLeftRows.AddView(new ListHeader(text, addTooltip, onAdd), ListHeader.RowStyle());
	}

	/// A list row: a click selects it, and a right click offers Delete when `onDelete` is set.
	/// Both callbacks are consumed.
	private void AddLeftRow(StringView text, delegate void() onClick, bool emphasized, delegate void() onDelete = null)
	{
		let button = new LeftRow(text, onDelete);
		if (emphasized)
			button.AddClass("accent");
		button.OnClick.Add(new [=onClick](btn) => { onClick(); } ~ delete onClick);
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		style.Height = SizeSpec.Fixed(Unit.Dp(24.0f));
		mLeftRows.AddView(button, style);
	}

	/// A left panel row whose right click opens its context menu.
	private class LeftRow : Button
	{
		private delegate void() mOnDelete ~ delete _;

		public this(StringView text, delegate void() onDelete) : base(text) { mOnDelete = onDelete; }

		public override void OnMouseDown(MouseEventArgs e)
		{
			if ((e.Button != .Right) || (mOnDelete == null) || (Context == null))
			{
				base.OnMouseDown(e);
				return;
			}
			let menu = new ContextMenu();
			defer menu.ReleaseRef();
			menu.AddItem("Delete", new [=this]() => { mOnDelete(); });
			let at = LocalToScreen(.(e.X, e.Y));
			menu.Show(Context, at.X, at.Y);
			e.Handled = true;
		}
	}

	/// The remove icon for a section's header. `action` is consumed.
	private static View RemoveIcon(StringView tooltip, delegate void() action)
	{
		let remove = new IconButton(EditorIcons.Remove, 18.0f);
		remove.TooltipText.Set(tooltip);
		remove.OnClick.Add(new [=action](b) => { action(); } ~ delete action);
		return remove;
	}

	private void DeleteLayer(int32 layerIndex)
	{
		QueueStructural("del-layer", new [=this, =layerIndex]() =>
			{
				if (mDoc.RemoveLayer(layerIndex) && (layerIndex < mAsset.LayerLayouts.Count))
				{
					delete mAsset.LayerLayouts[layerIndex];
					mAsset.LayerLayouts.RemoveAt(layerIndex);
				}
			}, .(.Layer, 0, 0));
	}

	private void DeleteParam(int32 paramIndex)
	{
		QueueStructural("del-param", new [=this, =paramIndex]() => { mDoc.RemoveParam(paramIndex); }, .None);
	}

	private void RebuildInspector()
	{
		mGrid.Clear();
		if (mAsset == null)
		{
			mInspectorTitle.SetText("(no asset)");
			return;
		}
		switch (mSelected.Kind)
		{
		case .Layer:
			mInspectorTitle.SetText("Layer");
			BuildLayerInspector(mSelected.Index);
		case .Parameter:
			mInspectorTitle.SetText("Parameter");
			BuildParameterInspector(mSelected.Index);
		case .State:
			mInspectorTitle.SetText("State");
			BuildStateInspector(mSelected.Layer, mSelected.Index);
		case .Transition:
			mInspectorTitle.SetText("Transition");
			BuildTransitionInspector(mSelected.Layer, mSelected.Index);
		default:
			mInspectorTitle.SetText("");
		}
	}

	private void BuildLayerInspector(int32 layerIndex)
	{
		let layer = mDoc.Layer(layerIndex);
		if (layer == null)
			return;
		let g = mGrid;
		let cat = "Layer";

		InPlaceRows.Text(g, "Name", layer.Name, cat, mCommit);
		InPlaceRows.Enum(g, "Blend Mode", layer.BlendMode, cBlendModes, new [=this, =layer](v) =>
			{
				layer.BlendMode = (uint8)v;
				CommitEdit("layer-blend");
			}, cat);
		InPlaceRows.Float(g, "Weight", &layer.Weight, cat, mCommit, 0.0, 1.0, 0.01);
		if (!layer.States.IsEmpty)
		{
			let items = scope List<StringView>();
			for (let s in layer.States)
				items.Add(s.Name);
			InPlaceRows.Enum(g, "Default State", Math.Clamp(layer.DefaultState, 0, (int32)items.Count - 1), items, new [=this, =layerIndex](v) =>
				{
					QueueStructural("layer-default", new [=this, =layerIndex, =v]() =>
						{
							if (let l = mDoc.Layer(layerIndex))
								l.DefaultState = v;
						}, .(.Layer, layerIndex, layerIndex));
				}, cat);
		}
		if (mDoc.Layers.Count > 1)
			g.SetCategoryHeaderActions(cat, RemoveIcon("Delete layer", new [=this, =layerIndex]() => { DeleteLayer(layerIndex); }));
	}

	private void BuildParameterInspector(int32 paramIndex)
	{
		if (!mDoc.HasParam(paramIndex))
			return;
		let param = mDoc.Params[paramIndex];
		let g = mGrid;
		let cat = "Parameter";

		InPlaceRows.Text(g, "Name", param.Name, cat, mCommit);
		InPlaceRows.Enum(g, "Type", param.Type, cParamTypes, new [=this, =param](v) =>
			{
				param.Type = (uint8)v;
				CommitEdit("param-type");
				QueueInspectorRebuild();
			}, cat);
		if (param.Type == 0)
			InPlaceRows.Float(g, "Default", &param.FloatValue, cat, mCommit);
		else if (param.Type == 1)
			InPlaceRows.Int(g, "Default", &param.IntValue, cat, mCommit, -1000000, 1000000);
		else
			InPlaceRows.Bool(g, "Default", &param.BoolValue, cat, mCommit);

		if (mPlayer != null)
		{
			let liveCat = "Live (preview)";
			let pi = paramIndex;
			if (param.Type == 0)
				g.AddProperty(new FloatEditor("Value", mPlayer.GetFloat(pi), -1e6, 1e6, 0.02, 3, new [=this, =pi](v) => { if (mPlayer != null) mPlayer.SetFloat(pi, (float)v); }, liveCat));
			else if (param.Type == 1)
				g.AddProperty(new IntEditor("Value", mPlayer.GetInt(pi), -1000000, 1000000, new [=this, =pi](v) => { if (mPlayer != null) mPlayer.SetInt(pi, (int32)v); }, liveCat));
			else if (param.Type == 2)
				g.AddProperty(new BoolEditor("Value", mPlayer.GetBool(pi), new [=this, =pi](v) => { if (mPlayer != null) mPlayer.SetBool(pi, v); }, liveCat));
			else
				InPlaceRows.Button(g, "Fire Trigger", liveCat, new [=this, =pi]() => { if (mPlayer != null) mPlayer.SetTrigger(pi); });
		}

		g.SetCategoryHeaderActions(cat, RemoveIcon("Delete parameter", new [=this, =paramIndex]() => { DeleteParam(paramIndex); }));
	}

	/// A parameter chooser: "(none)" then every parameter, the setter given the index or -1.
	/// `setIndex` is consumed.
	private void ParamPickRow(StringView name, int32 current, delegate void(int32) setIndex, StringView cat)
	{
		let items = scope List<StringView>();
		items.Add("(none)");
		for (let p in mDoc.Params)
			items.Add(p.Name);
		InPlaceRows.Enum(mGrid, name, current + 1, items, new [=setIndex](v) => { setIndex(v - 1); } ~ delete setIndex, cat);
	}

	private void QueueInspectorRebuild()
	{
		if (let ctx = Ctx)
			ctx.MutationQueue.QueueAction(new [=this]() => { RebuildInspector(); });
		else
			RebuildInspector();
	}

	private void BuildStateInspector(int32 layerIndex, int32 stateIndex)
	{
		let state = mDoc.State(layerIndex, stateIndex);
		if (state == null)
			return;
		let g = mGrid;
		let cat = "State";
		let li = layerIndex;
		let si = stateIndex;

		// The name shows on the canvas too, so it goes through the structural path.
		g.AddProperty(new StringEditor("Name", state.Name, new [=this, =li, =si](v) =>
			{
				let name = new String(v);
				QueueStructural("state-name", new [=this, =li, =si, =name]() =>
					{
						if (let s = mDoc.State(li, si))
							s.Name.Set(name);
					} ~ delete name, .(.State, li, si));
			}, cat));
		InPlaceRows.Float(g, "Speed", &state.Speed, cat, mCommit, -10.0, 10.0, 0.05);
		InPlaceRows.Bool(g, "Loop", &state.Loop, cat, mCommit);

		let kindCat = AnimationGraphEdit.NodeKindLabel(state.NodeKind);
		if (state.NodeKind == 0)
		{
			let clip = new ResourceRefEditor("Clip", "(none)", kindCat, scope StringView[]("AnimationClipAsset"));
			clip.BindAsset(mContext, new [=this, =li, =si]() =>
				{
					let s = mDoc.State(li, si);
					return (s != null) ? s.ClipRef : Guid();
				},
				new [=this, =li, =si](picked) =>
				{
					if (let s = mDoc.State(li, si))
					{
						s.ClipRef = picked;
						CommitEdit("state-clip");
						Select(.(.State, li, si));
					}
				});
			g.AddProperty(clip);
			return;
		}

		if (state.NodeKind == 1)
			ParamPickRow("Parameter", state.ParamIndex, new [=this, =state](v) => { state.ParamIndex = v; CommitEdit("blend-param"); }, kindCat);
		else
		{
			ParamPickRow("Parameter X", state.ParamIndexX, new [=this, =state](v) => { state.ParamIndexX = v; CommitEdit("blend-param-x"); }, kindCat);
			ParamPickRow("Parameter Y", state.ParamIndexY, new [=this, =state](v) => { state.ParamIndexY = v; CommitEdit("blend-param-y"); }, kindCat);
		}

		// The entries are a section list: the header's add icon, and each entry a section with
		// its remove icon.
		state.NormalizeEntries();
		let entries = new ContainerListEditor("Entries", kindCat);
		entries.ElementsAsSections = true;
		for (let clipId in state.EntryClips)
			entries.SlotNames.Add(mContext.AssetNameFor(clipId, .. new .()));
		entries.OnAdd = new [=this, =li, =si]() =>
		{
			QueueStructural("add-entry", new [=this, =li, =si]() =>
				{
					if (let s = mDoc.State(li, si))
						s.AddEntry();
				}, .(.State, li, si));
		};
		g.AddProperty(entries);
		for (int e < state.EntryClips.Count)
		{
			let entryCat = scope $"Entry {e + 1}";
			g.SetCategoryParent(entryCat, kindCat);
			let entryIdx = e;
			g.SetCategoryHeaderActions(entryCat, ContainerListEditor.ElementActions(e, state.EntryClips.Count, null,
				new [=this, =li, =si](i) =>
				{
					QueueStructural("del-entry", new [=this, =li, =si, =i]() =>
						{
							if (let s = mDoc.State(li, si))
								s.RemoveEntry(i);
						}, .(.State, li, si));
				}));
			if (state.NodeKind == 1)
				InPlaceRows.Float(g, "Threshold", &state.EntryThresholds[e], entryCat, mCommit);
			else
				InPlaceRows.Float2(g, "Position", &state.EntryPositions[e], entryCat, mCommit, -1000.0f, 1000.0f, 0.05f);
			let entryClip = new ResourceRefEditor("Clip", "(none)", entryCat, scope StringView[]("AnimationClipAsset"));
			entryClip.BindAsset(mContext, new [=this, =li, =si, =entryIdx]() =>
				{
					let s = mDoc.State(li, si);
					return ((s != null) && (entryIdx < s.EntryClips.Count)) ? s.EntryClips[entryIdx] : Guid();
				},
				new [=this, =li, =si, =entryIdx](picked) =>
				{
					let s = mDoc.State(li, si);
					if ((s != null) && (entryIdx < s.EntryClips.Count))
					{
						s.EntryClips[entryIdx] = picked;
						CommitEdit("entry-clip");
						Select(.(.State, li, si));
					}
				});
			g.AddProperty(entryClip);
		}
	}

	private void BuildTransitionInspector(int32 layerIndex, int32 transitionIndex)
	{
		let layer = mDoc.Layer(layerIndex);
		let transition = mDoc.Transition(layerIndex, transitionIndex);
		if ((layer == null) || (transition == null))
			return;
		let g = mGrid;
		let cat = "Transition";
		let li = layerIndex;
		let ti = transitionIndex;

		mInspectorTitle.SetText(scope $"{layer.StateLabel(transition.Src)}  ->  {layer.StateLabel(transition.Dst)}");

		InPlaceRows.Float(g, "Duration (s)", &transition.Duration, cat, mCommit, 0.0, 10.0, 0.01);
		InPlaceRows.Bool(g, "Has Exit Time", &transition.HasExitTime, cat, mCommit);
		InPlaceRows.Float(g, "Exit Time", &transition.ExitTime, cat, mCommit, 0.0, 1.0, 0.01);
		InPlaceRows.Int(g, "Priority", &transition.Priority, cat, mCommit, -100, 100);

		// The conditions are a section list, all of them required, so their order means
		// nothing: the header's add icon, and each condition a section with its remove icon.
		let conditions = new ContainerListEditor("Conditions", cat);
		conditions.ElementsAsSections = true;
		for (let condition in transition.Conditions)
			conditions.SlotNames.Add(new String(mDoc.HasParam(condition.ParamIndex) ? StringView(mDoc.Params[condition.ParamIndex].Name) : "(none)"));
		conditions.OnAdd = new [=this, =li, =ti]() =>
		{
			QueueStructural("add-cond", new [=this, =li, =ti]() =>
				{
					if (let t = mDoc.Transition(li, ti))
						t.Conditions.Add(new GraphCondition());
				}, .(.Transition, li, ti));
		};
		g.AddProperty(conditions);
		for (int c < transition.Conditions.Count)
		{
			let condition = transition.Conditions[c];
			let condCat = scope $"Condition {c + 1}";
			g.SetCategoryParent(condCat, cat);
			g.SetCategoryHeaderActions(condCat, ContainerListEditor.ElementActions(c, transition.Conditions.Count, null,
				new [=this, =li, =ti](i) =>
				{
					QueueStructural("del-cond", new [=this, =li, =ti, =i]() =>
						{
							let t = mDoc.Transition(li, ti);
							if ((t != null) && (i < t.Conditions.Count))
							{
								delete t.Conditions[i];
								t.Conditions.RemoveAt(i);
							}
						}, .(.Transition, li, ti));
				}));
			ParamPickRow("Parameter", condition.ParamIndex, new [=this, =condition](v) => { condition.ParamIndex = v; CommitEdit("cond-param"); }, condCat);
			InPlaceRows.Enum(g, "Compare", condition.Op, cCompareOps, new [=this, =condition](v) =>
				{
					condition.Op = (uint8)v;
					CommitEdit("cond-op");
				}, condCat);
			InPlaceRows.Float(g, "Threshold", &condition.Threshold, condCat, mCommit);
		}
	}
}
