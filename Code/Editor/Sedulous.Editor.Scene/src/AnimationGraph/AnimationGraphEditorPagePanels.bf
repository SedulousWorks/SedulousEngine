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

		AddLeftHeader("Layers");
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
				}, layerIndex == mSelectedLayer);
		}
		AddLeftRow("+ Add Layer", new [=this]() =>
			{
				QueueStructural("add-layer", new [=this]() =>
					{
						mDoc.AddLayer(scope $"Layer {mDoc.Layers.Count}");
						mSelectedLayer = (int32)mDoc.Layers.Count - 1;
					}, .(.Layer, 0, 0));
			}, false);

		AddLeftHeader("Parameters");
		for (int32 p < (int32)mDoc.Params.Count)
		{
			let paramIndex = p;
			AddLeftRow(mDoc.Params[p].Name, new [=this, =paramIndex]() => { Select(.(.Parameter, 0, paramIndex)); },
				(mSelected.Kind == .Parameter) && (mSelected.Index == paramIndex));
		}
		AddLeftRow("+ Add Parameter", new [=this]() =>
			{
				QueueStructural("add-param", new [=this]() => { mDoc.AddParam(scope $"Param{mDoc.Params.Count}", 0); }, .(.Parameter, 0, GraphSel.Last));
			}, false);
	}

	private void AddLeftHeader(StringView text)
	{
		let label = new Label(text);
		label.FontSize.Value = 12.0f;
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		style.Height = SizeSpec.Fixed(Unit.Dp(22.0f));
		mLeftRows.AddView(label, style);
	}

	/// `onClick` is consumed.
	private void AddLeftRow(StringView text, delegate void() onClick, bool emphasized)
	{
		let button = new Button(text);
		if (emphasized)
			button.AddClass("accent");
		button.OnClick.Add(new [=onClick](btn) => { onClick(); } ~ delete onClick);
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		style.Height = SizeSpec.Fixed(Unit.Dp(24.0f));
		mLeftRows.AddView(button, style);
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
		{
			InPlaceRows.Button(g, "Delete Layer", cat, new [=this, =layerIndex]() =>
				{
					QueueStructural("del-layer", new [=this, =layerIndex]() =>
						{
							if (mDoc.RemoveLayer(layerIndex) && (layerIndex < mAsset.LayerLayouts.Count))
							{
								delete mAsset.LayerLayouts[layerIndex];
								mAsset.LayerLayouts.RemoveAt(layerIndex);
							}
						}, .(.Layer, 0, 0));
				});
		}
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

		InPlaceRows.Button(g, "Delete Parameter", cat, new [=this, =paramIndex]() =>
			{
				QueueStructural("del-param", new [=this, =paramIndex]() => { mDoc.RemoveParam(paramIndex); }, .None);
			});
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

	private void AssetLabel(Guid id, String outLabel)
	{
		if (id.IsNil)
		{
			outLabel.Append("(none)");
			return;
		}
		if (mContext.Project != null)
		{
			if (let inst = mContext.Project.SourceDb.GetInstance(id))
			{
				outLabel.Append(inst.Name);
				return;
			}
		}
		outLabel.Append("(missing)");
	}

	/// Opens the clip picker; `onPicked` is consumed.
	private void PickClip(delegate void(Guid) onPicked)
	{
		let ctx = Ctx;
		if ((ctx == null) || (mContext.Project == null))
		{
			delete onPicked;
			return;
		}
		let dialog = new AssetPickerDialog(mContext, scope StringView[]("AnimationClipAsset"));
		dialog.OnPicked = onPicked;
		dialog.Show(ctx);
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
			let label = scope String("Clip: ");
			AssetLabel(state.ClipRef, label);
			InPlaceRows.Button(g, label, kindCat, new [=this, =li, =si]() =>
				{
					PickClip(new [=this, =li, =si](picked) =>
						{
							if (let s = mDoc.State(li, si))
							{
								s.ClipRef = picked;
								CommitEdit("state-clip");
								Select(.(.State, li, si));
							}
						});
				});
			return;
		}

		if (state.NodeKind == 1)
			ParamPickRow("Parameter", state.ParamIndex, new [=this, =state](v) => { state.ParamIndex = v; CommitEdit("blend-param"); }, kindCat);
		else
		{
			ParamPickRow("Parameter X", state.ParamIndexX, new [=this, =state](v) => { state.ParamIndexX = v; CommitEdit("blend-param-x"); }, kindCat);
			ParamPickRow("Parameter Y", state.ParamIndexY, new [=this, =state](v) => { state.ParamIndexY = v; CommitEdit("blend-param-y"); }, kindCat);
		}

		state.NormalizeEntries();
		for (int e < state.EntryClips.Count)
		{
			let entryCat = scope $"Entry {e}";
			let entryIdx = e;
			if (state.NodeKind == 1)
				InPlaceRows.Float(g, "Threshold", &state.EntryThresholds[e], entryCat, mCommit);
			else
				InPlaceRows.Float2(g, "Position", &state.EntryPositions[e], entryCat, mCommit, -1000.0f, 1000.0f, 0.05f);
			let clipLabel = scope String("Clip: ");
			AssetLabel(state.EntryClips[e], clipLabel);
			InPlaceRows.Button(g, clipLabel, entryCat, new [=this, =li, =si, =entryIdx]() =>
				{
					PickClip(new [=this, =li, =si, =entryIdx](picked) =>
						{
							let s = mDoc.State(li, si);
							if ((s != null) && (entryIdx < s.EntryClips.Count))
							{
								s.EntryClips[entryIdx] = picked;
								CommitEdit("entry-clip");
								Select(.(.State, li, si));
							}
						});
				});
			InPlaceRows.Button(g, "Remove Entry", entryCat, new [=this, =li, =si, =entryIdx]() =>
				{
					QueueStructural("del-entry", new [=this, =li, =si, =entryIdx]() =>
						{
							if (let s = mDoc.State(li, si))
								s.RemoveEntry(entryIdx);
						}, .(.State, li, si));
				});
		}
		InPlaceRows.Button(g, "+ Add Entry", kindCat, new [=this, =li, =si]() =>
			{
				QueueStructural("add-entry", new [=this, =li, =si]() =>
					{
						if (let s = mDoc.State(li, si))
							s.AddEntry();
					}, .(.State, li, si));
			});
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

		for (int c < transition.Conditions.Count)
		{
			let condition = transition.Conditions[c];
			let condCat = scope $"Condition {c}";
			let condIdx = c;
			ParamPickRow("Parameter", condition.ParamIndex, new [=this, =condition](v) => { condition.ParamIndex = v; CommitEdit("cond-param"); }, condCat);
			InPlaceRows.Enum(g, "Compare", condition.Op, cCompareOps, new [=this, =condition](v) =>
				{
					condition.Op = (uint8)v;
					CommitEdit("cond-op");
				}, condCat);
			InPlaceRows.Float(g, "Threshold", &condition.Threshold, condCat, mCommit);
			InPlaceRows.Button(g, "Remove Condition", condCat, new [=this, =li, =ti, =condIdx]() =>
				{
					QueueStructural("del-cond", new [=this, =li, =ti, =condIdx]() =>
						{
							let t = mDoc.Transition(li, ti);
							if ((t != null) && (condIdx < t.Conditions.Count))
							{
								delete t.Conditions[condIdx];
								t.Conditions.RemoveAt(condIdx);
							}
						}, .(.Transition, li, ti));
				});
		}
		InPlaceRows.Button(g, "+ Add Condition", cat, new [=this, =li, =ti]() =>
			{
				QueueStructural("add-cond", new [=this, =li, =ti]() =>
					{
						if (let t = mDoc.Transition(li, ti))
							t.Conditions.Add(new GraphCondition());
					}, .(.Transition, li, ti));
			});
	}
}
