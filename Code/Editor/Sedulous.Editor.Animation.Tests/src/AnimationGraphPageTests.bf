using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Animation;
using Sedulous.Animation.Resource;
using Sedulous.Animation.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Project;
using Sedulous.Pipeline.Core;

namespace Sedulous.Editor.Animation.Tests;

/// The animation graph page over its markup (Data/Editor/AnimationGraphPage.gml) and a scratch project,
/// without a host (no preview): the layers and parameters as lists, the chosen layer on the graph view,
/// the grid showing what is chosen (a layer, a parameter, a state, a transition) with each row where
/// what it is uses it, each edit one undo step; a parameter added by its type and removed, a layer
/// added and removed; the preview's parameters a section of the page's own, never the graph's. And the
/// graph's data as the page writes it: the seed, the nested edit model over the flat source and its
/// structural edits, the layout squared to the states, the asset's round trip through the serializer
/// its undo snapshots ride, and the creator.
class AnimationGraphPageTests
{
	// The whole asset through the binary serializer (the undo snapshot's path), into `outAsset`.
	private static void RoundTrip(AnimationGraphAsset asset, AnimationGraphAsset outAsset)
	{
		let stream = scope Sedulous.Core.IO.MemoryStream();
		{
			let ar = scope BinarySerializer(stream, .Write);
			ISerializable serializable = asset;
			serializable.Serialize(ar);
		}
		stream.Seek(0, .Begin);
		let ar = scope BinarySerializer(stream, .Read);
		ISerializable serializable = outAsset;
		serializable.Serialize(ar);
	}

	/// The domain's "Animation Graph" creator, as File > New runs it. Leaks nothing: the registry is
	/// static to the test class.
	private static AssetCreatorRegistry sCreators = null ~ delete _;
	private static AssetCreator Creator()
	{
		if (sCreators == null)
		{
			sCreators = new .();
			AnimationCreators.Register(sCreators);
		}
		return sCreators.FindByLabel("Animation Graph");
	}

	[Test]
	public static void TheDefaultSeedIsOneLayerWithAnIdleDefaultAndASpeedParam()
	{
		let asset = scope AnimationGraphAsset();
		AnimationCreators.SeedDefaultGraph(asset);
		let s = asset.Source;
		Test.Assert((s.ParamName.Count == 1) && (s.ParamName[0] == "Speed") && (s.ParamType[0] == 0));
		Test.Assert((s.LayerName.Count == 1) && (s.LayerName[0] == "Base"));
		Test.Assert((s.StateName.Count == 1) && (s.StateName[0] == "Idle"));
		Test.Assert((s.StateNodeKind[0] == 0) && (s.LayerDefaultState[0] == 0));
		Test.Assert(s.TransitionSource.IsEmpty);
		Test.Assert((asset.LayerLayouts.Count == 1) && (asset.LayerLayouts[0].StatePositions.Count == 1));
		Test.Assert(asset.LayerLayouts[0].AnyStatePosition.Y == 40.0f);
	}

	[Test]
	public static void TheDocumentRoundTripsTheFlatSourceWithBlendTreesAndTransitions()
	{
		AnimationPipeline.RegisterAll();
		let a = scope AnimationGraphAsset();
		AnimationCreators.SeedDefaultGraph(a);
		let doc = scope GraphDocument();
		doc.Load(a.Source);
		Test.Assert((doc.Params.Count == 1) && (doc.Layers.Count == 1) && (doc.Layers[0].States.Count == 1));

		let layer = doc.Layers[0];
		let run = layer.AddState("Run", 1);
		run.ParamIndex = 0;
		run.EntryClips.Add(Guid(0xAB, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x12));
		run.EntryThresholds.Add(0.5f);
		let t = layer.AddTransition(0, 1);
		t.Duration = 0.15f;
		let c = new GraphCondition();
		c.ParamIndex = 0;
		c.Op = 2; // greater
		c.Threshold = 0.1f;
		t.Conditions.Add(c);
		layer.MaskWeights.Add(1.0f);
		layer.MaskWeights.Add(0.5f);
		doc.AddLayer("Upper").Weight = 0.5f;
		doc.Store(a.Source);
		AnimationGraphEdits.SquareLayout(a, doc);
		a.LayerLayouts[0].StatePositions[1] = .(420.0f, 200.0f);
		a.LayerLayouts[0].AnyStatePosition = .(25.0f, 75.0f);

		// The flat runs are laid out in order.
		let s = a.Source;
		Test.Assert((s.LayerStateStart[0] == 0) && (s.LayerStateCount[0] == 2));
		Test.Assert((s.LayerStateStart[1] == 2) && (s.LayerStateCount[1] == 0));
		Test.Assert((s.LayerMaskStart[0] == 0) && (s.LayerMaskCount[0] == 2) && (s.MaskWeight.Count == 2));
		Test.Assert((s.StateEntryStart[1] == 0) && (s.StateEntryCount[1] == 1));
		Test.Assert((s.TransitionConditionStart[0] == 0) && (s.TransitionConditionCount[0] == 1));

		// Through the serializer, the undo blob path, and back into a fresh model.
		let b = scope AnimationGraphAsset();
		RoundTrip(a, b);
		let back = scope GraphDocument();
		back.Load(b.Source);
		Test.Assert(back.Layers.Count == 2);
		let l = back.Layers[0];
		Test.Assert(l.States.Count == 2);
		Test.Assert((l.States[1].Name == "Run") && (l.States[1].NodeKind == 1) && (l.States[1].ParamIndex == 0));
		Test.Assert((l.States[1].EntryClips.Count == 1) && (l.States[1].EntryClips[0] == run.EntryClips[0]));
		Test.Assert(Math.Abs(l.States[1].EntryThresholds[0] - 0.5f) < 1e-6f);
		Test.Assert((l.Transitions.Count == 1) && (l.Transitions[0].Src == 0) && (l.Transitions[0].Dst == 1));
		Test.Assert(Math.Abs(l.Transitions[0].Duration - 0.15f) < 1e-6f);
		Test.Assert((l.Transitions[0].Conditions.Count == 1) && (l.Transitions[0].Conditions[0].Op == 2));
		Test.Assert(Math.Abs(l.Transitions[0].Conditions[0].Threshold - 0.1f) < 1e-6f);
		Test.Assert((l.MaskWeights.Count == 2) && (l.MaskWeights[1] == 0.5f));
		Test.Assert((back.Layers[1].Name == "Upper") && (back.Layers[1].Weight == 0.5f));
		Test.Assert(b.LayerLayouts.Count == 2);
		Test.Assert(b.LayerLayouts[0].StatePositions[1].X == 420.0f);
		Test.Assert(b.LayerLayouts[0].AnyStatePosition.Y == 75.0f);
	}

	[Test]
	public static void DeletingAStateRepointsTransitionsAndTheDefault()
	{
		let doc = scope GraphDocument();
		let layer = doc.AddLayer("Base");
		layer.AddState("Idle", 0);
		layer.AddState("Walk", 0);
		layer.AddState("Run", 0);
		layer.DefaultState = 2;
		layer.AddTransition(-1, 1); // any -> walk
		layer.AddTransition(0, 1);  // idle -> walk
		layer.AddTransition(1, 2);  // walk -> run
		layer.AddTransition(0, 2);  // idle -> run

		Test.Assert(!layer.DeleteState(5));
		Test.Assert(layer.DeleteState(1));
		Test.Assert((layer.States.Count == 2) && (layer.States[1].Name == "Run"));
		// Everything touching Walk went; the rest slid down; the default followed Run.
		Test.Assert(layer.Transitions.Count == 1);
		Test.Assert((layer.Transitions[0].Src == 0) && (layer.Transitions[0].Dst == 1));
		Test.Assert(layer.DefaultState == 1);
		Test.Assert(layer.DeleteState(1));
		Test.Assert((layer.DefaultState == 0) && layer.Transitions.IsEmpty);
		Test.Assert(layer.StateLabel(-1) == "Any State");
		Test.Assert(layer.StateLabel(9) == "?");
	}

	[Test]
	public static void RemovingAParameterRemapsEveryReference()
	{
		let doc = scope GraphDocument();
		doc.AddParam("Speed", 0);
		doc.AddParam("Jump", 3);
		doc.AddParam("Dir", 0);
		let layer = doc.AddLayer("Base");
		let blend = layer.AddState("Move", 2);
		blend.ParamIndexX = 0;
		blend.ParamIndexY = 2;
		let one = layer.AddState("Turn", 1);
		one.ParamIndex = 1;
		let t = layer.AddTransition(0, 1);
		for (int32 i < 3)
		{
			let c = new GraphCondition();
			c.ParamIndex = i;
			t.Conditions.Add(c);
		}

		Test.Assert(!doc.RemoveParam(3));
		Test.Assert(doc.RemoveParam(1));
		Test.Assert((doc.Params.Count == 2) && (doc.Params[1].Name == "Dir"));
		Test.Assert((blend.ParamIndexX == 0) && (blend.ParamIndexY == 1));
		Test.Assert(one.ParamIndex == -1);
		Test.Assert(t.Conditions.Count == 2);
		Test.Assert((t.Conditions[0].ParamIndex == 0) && (t.Conditions[1].ParamIndex == 1));

		// The last layer never goes.
		Test.Assert(!doc.RemoveLayer(0));
		doc.AddLayer("Extra");
		Test.Assert(doc.RemoveLayer(1) && (doc.Layers.Count == 1));
	}

	[Test]
	public static void LayoutsFollowTheModelAndNewStatesLandOnAGrid()
	{
		let asset = scope AnimationGraphAsset();
		let doc = scope GraphDocument();
		let layer = doc.AddLayer("Base");
		for (int i < 7)
			layer.AddState(scope $"S{i}", 0);
		doc.AddLayer("Upper");
		AnimationGraphEdits.SquareLayout(asset, doc);
		Test.Assert(asset.LayerLayouts.Count == 2);
		Test.Assert(asset.LayerLayouts[0].StatePositions.Count == 7);
		// Five per row, then the next row down.
		Test.Assert(asset.LayerLayouts[0].StatePositions[0] == Float2(240.0f, 90.0f));
		Test.Assert(asset.LayerLayouts[0].StatePositions[1] == Float2(440.0f, 90.0f));
		Test.Assert(asset.LayerLayouts[0].StatePositions[5] == Float2(240.0f, 200.0f));
		Test.Assert(asset.LayerLayouts[1].StatePositions.IsEmpty);

		// Removing trims; the kept positions stay put.
		asset.LayerLayouts[0].StatePositions[0] = .(1.0f, 2.0f);
		Test.Assert(layer.DeleteState(6));
		Test.Assert(doc.RemoveLayer(1));
		AnimationGraphEdits.SquareLayout(asset, doc);
		Test.Assert((asset.LayerLayouts.Count == 1) && (asset.LayerLayouts[0].StatePositions.Count == 6));
		Test.Assert(asset.LayerLayouts[0].StatePositions[0] == Float2(1.0f, 2.0f));
	}

	[Test]
	public static void TheCreatorRoundTripsThroughARealProject()
	{
		AnimationPipeline.RegisterAll();
		let dir = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "scratch_editor_graph_creator_test", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;

		Test.Assert(Creator().Create(null, null, "") == null);

		let instance = Creator().Create(null, project.SourceDb.RootGroup, "");
		Test.Assert(instance != null);
		Test.Assert(instance.GetPath(.. scope .()) == "Animation/AnimationGraph");
		Test.Assert(AssetTypeNames.Matches(instance.TypeName, "AnimationGraphAsset"));
		let object = instance.ReadObject();
		Test.Assert(object != null);
		defer delete object;
		let readBack = object as AnimationGraphAsset;
		Test.Assert(readBack != null);
		Test.Assert(readBack.Source.LayerName.Count == 1);
		Test.Assert(readBack.LayerLayouts.Count == 1);
		let doc = scope GraphDocument();
		doc.Load(readBack.Source);
		Test.Assert((doc.Layers[0].States.Count == 1) && (doc.Layers[0].States[0].Name == "Idle"));
	}

	// === The page ===

	static bool DataRoot(String outPath)
	{
		var dir = GetCurrentDirectory(.. scope .());
		for (int i < 8)
		{
			let data = PathJoin(dir, "Data", .. scope .());
			if (DirectoryExists(PathJoin(data, "Editor", .. scope .())))
			{
				outPath.Set(data);
				return true;
			}
			let parent = PathParent(dir, .. scope .());
			if (parent == dir)
				break;
			dir.Set(parent);
		}
		return false;
	}

	static Node LoadMarkup(StringView relative)
	{
		let data = scope String();
		Test.Assert(DataRoot(data));
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(PathJoin(data, relative, .. scope .()), text) case .Ok);
		RegisterGuiElements();
		RegisterToolkitElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	/// A scratch project holding one graph: the seed (Base, Idle, Speed) and a Run state.
	private class Bed
	{
		public String Dir = new .("scratch_graph_page_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public AnimationGraphEditorPage Page;

		public this()
		{
			AnimationPipeline.RegisterAll();
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			let instance = Project.SourceDb.RootGroup.CreateInstance("Hero", typeof(AnimationGraphAsset).GetFullName(.. scope .()));
			Test.Assert(instance != null);
			let asset = scope AnimationGraphAsset();
			AnimationCreators.SeedDefaultGraph(asset);
			AnimationGraphEdits.AddState(asset, 0, "Run", .Clip, .(500.0f, 120.0f));
			Test.Assert(instance.WriteObject(asset) case .Ok);
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			Page = new AnimationGraphEditorPage(Context, services, instance);
			Test.Assert(!Page.LoadFailed);
		}

		public ~this()
		{
			delete Page;
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The graph as the page holds it now.
		public GraphDocument Doc => Page.Doc;

		public static void Edit(Sedulous.GUI.PropertyBag rows, StringView path, Sedulous.GUI.Variant value)
		{
			rows.BeginEdit(path);
			rows.CommitEdit(path, PropertyWrite(value));
		}

		/// The row `name` under `parent`, into `outInfo`; false when there is none.
		public static bool Info(Sedulous.GUI.PropertyBag rows, StringView parent, StringView name, PropertyInfo outInfo)
		{
			let found = scope List<PropertyInfo>();
			defer { ClearAndDeleteItems!(found); }
			rows.GetProperties(parent, found);
			for (let info in found)
			{
				if (info.Name == name)
				{
					outInfo.Set(info);
					return true;
				}
			}
			return false;
		}

		public static bool Shown(Sedulous.GUI.PropertyBag rows, StringView parent, StringView name)
		{
			let info = scope PropertyInfo();
			Test.Assert(Info(rows, parent, name, info), scope String()..AppendF("no row {}", name));
			return info.Visible;
		}

		/// `rows`' value at `path` as text (its owned copy let go).
		public static void Text(Sedulous.GUI.PropertyBag rows, StringView path, String outText)
		{
			var value = rows.GetValue(path, 0);
			defer value.Dispose();
			outText.Append(value.AsString);
		}

		public String Layers(String outText)
		{
			Page.LayerList(outText);
			return outText;
		}

		public String Parameters(String outText)
		{
			Page.ParameterList(outText);
			return outText;
		}

		public String Fact(StringView name, String outText)
		{
			Page.Fact(name, outText);
			return outText;
		}
	}

	[Test]
	public static void TheLayersAndParametersAsListsTheChosenLayerOnTheViewALayersRows()
	{
		let bed = scope Bed();
		Test.Assert(bed.Layers(.. scope .()) == "Base");
		Test.Assert(bed.Parameters(.. scope .()) == "Speed  Float");
		Test.Assert(bed.Fact("States", .. scope .()) == "2");
		Test.Assert(bed.Page.Chosen.Kind == .Layer);
		let nodes = scope List<GraphId>();
		bed.Page.States.GetNodes(nodes);
		Test.Assert(nodes.Count == 3, "Any State, Idle, Run");

		Test.Assert(Bed.Text(bed.Page.LayerRows, "name", .. scope .()) == "Base");
		let start = scope PropertyInfo();
		Test.Assert(Bed.Info(bed.Page.LayerRows, "", "start", start));
		Test.Assert(start.Choices.Count == 2, "the layer's states by name");
		Test.Assert(start.Choices[1].Name == "Run");
		Bed.Edit(bed.Page.LayerRows, "start", .((int64)1));
		Test.Assert(bed.Doc.Layers[0].DefaultState == 1);
		bed.Page.Commands.Undo();
		Test.Assert(bed.Doc.Layers[0].DefaultState == 0);
	}

	[Test]
	public static void AStatesRowsShownWhereWhatItPlaysUsesThemItsEntriesAListOneStepEach()
	{
		let bed = scope Bed();
		bed.Page.Choose(.(.State, 1));
		Test.Assert(Bed.Text(bed.Page.StateRows, "name", .. scope .()) == "Run");
		Test.Assert(Bed.Shown(bed.Page.StateRows, "", "clip"));
		Test.Assert(!Bed.Shown(bed.Page.StateRows, "", "driver"));
		Test.Assert(!Bed.Shown(bed.Page.StateRows, "", "entries"));

		// A blend by one parameter: its driver and entries, each at a threshold.
		Bed.Edit(bed.Page.StateRows, "kind", .((int64)1));
		Test.Assert(bed.Doc.Layers[0].States[1].NodeKind == 1);
		Test.Assert(!Bed.Shown(bed.Page.StateRows, "", "clip"));
		let driver = scope PropertyInfo();
		Test.Assert(Bed.Info(bed.Page.StateRows, "", "driver", driver));
		Test.Assert(driver.Visible);
		Test.Assert(driver.Choices.Count == 2, "Nothing, Speed");
		Test.Assert(driver.Choices[1].Name == "Speed");
		Bed.Edit(bed.Page.StateRows, "driver", .((int64)0));
		Test.Assert(bed.Page.StateRows.EditList("entries", scope ListEdit(.Insert, 0)));
		Test.Assert(bed.Page.StateRows.EditList("entries", scope ListEdit(.Insert, 1)));
		let state = bed.Doc.Layers[0].States[1];
		Test.Assert(state.EntryClips.Count == 2);
		Test.Assert(Math.Abs(state.EntryThresholds[1] - 1.0f) < 1e-5f, "a step past the last");
		Bed.Edit(bed.Page.StateRows, "entries.1.threshold", .(4.0));
		Test.Assert(Math.Abs(bed.Doc.Layers[0].States[1].EntryThresholds[1] - 4.0f) < 1e-5f);
		Test.Assert(Bed.Shown(bed.Page.StateRows, "entries.0", "threshold"));
		Test.Assert(!Bed.Shown(bed.Page.StateRows, "entries.0", "x"));

		for (int i < 5)
			bed.Page.Commands.Undo();
		Test.Assert(bed.Doc.Layers[0].States[1].NodeKind == 0);
		Test.Assert(bed.Doc.Layers[0].States[1].EntryClips.IsEmpty);
	}

	[Test]
	public static void ATransitionMadeOnTheViewIsOneStepItsConditionsAListReadAsWhatTheySay()
	{
		let bed = scope Bed();
		var link = GraphLinkInfo();
		link.Kind = .Nodes;
		link.FromNode = bed.Page.States.StateId(0);
		link.ToNode = bed.Page.States.StateId(1);
		let made = bed.Page.States.Connect(link);
		Test.Assert(made != 0);
		Test.Assert(bed.Doc.Layers[0].Transitions.Count == 1);
		Test.Assert(bed.Page.Commands.CanUndo);

		bed.Page.Choose(.(.Transition, 0));
		Test.Assert(Bed.Text(bed.Page.TransitionRows, "from", .. scope .()) == "Idle");
		Test.Assert(Bed.Text(bed.Page.TransitionRows, "to", .. scope .()) == "Run");
		Test.Assert(!Bed.Shown(bed.Page.TransitionRows, "", "exitTime"));
		Bed.Edit(bed.Page.TransitionRows, "exit", .(true));
		Test.Assert(Bed.Shown(bed.Page.TransitionRows, "", "exitTime"));
		Test.Assert(bed.Page.TransitionRows.EditList("conditions", scope ListEdit(.Insert, 0)));
		Bed.Edit(bed.Page.TransitionRows, "conditions.0.compare", .((int64)2));
		Bed.Edit(bed.Page.TransitionRows, "conditions.0.value", .(0.5));
		let condition = bed.Doc.Layers[0].Transitions[0].Conditions[0];
		Test.Assert(condition.ParamIndex == 0);
		Test.Assert(condition.Op == 2);
		Test.Assert(Math.Abs(condition.Threshold - 0.5f) < 1e-5f);
		let closed = scope PropertyInfo();
		Test.Assert(Bed.Info(bed.Page.TransitionRows, "conditions", "0", closed));
		Test.Assert(closed.Summary == "Speed is above 0.5", closed.Summary);

		for (int i < 4)
			bed.Page.Commands.Undo();
		Test.Assert(bed.Doc.Layers[0].Transitions[0].Conditions.IsEmpty);
		bed.Page.Commands.Undo(); // the transition itself
		Test.Assert(bed.Doc.Layers[0].Transitions.IsEmpty);
		Test.Assert(bed.Page.Chosen.Kind == .Layer, "what was chosen went with it");
	}

	[Test]
	public static void ParametersAddedByTypeAndRemovedLayersAddedAndRemovedThePreviewsParametersItsOwn()
	{
		let bed = scope Bed();
		bed.Page.AddParameter(.Trigger);
		Test.Assert(bed.Parameters(.. scope .()) == "Speed  Float\nTrigger  Trigger");
		Test.Assert(bed.Page.Chosen.Kind == .Parameter);
		Test.Assert(bed.Page.Chosen.Index == 1);
		Test.Assert(!Bed.Shown(bed.Page.ParameterRows, "", "float"), "a trigger has no default");
		let fire = scope PropertyInfo();
		Test.Assert(Bed.Info(bed.Page.LiveRows, "", "p1", fire));
		Test.Assert(fire.DisplayName == "Fire Trigger");

		// The preview's values are never the graph's.
		let canUndo = bed.Page.Commands.CanUndo;
		let dirty = bed.Page.IsDirty;
		bed.Page.SetLive(0, 0.75);
		Bed.Edit(bed.Page.LiveRows, "p0", .(0.5));
		Test.Assert(bed.Doc.Params[0].FloatValue == 0.0f);
		Test.Assert((bed.Page.Commands.CanUndo == canUndo) && (bed.Page.IsDirty == dirty));
		bed.Page.Commands.Undo();
		Test.Assert(bed.Parameters(.. scope .()) == "Speed  Float", "the last step was the parameter added");
		bed.Page.Commands.Redo();

		bed.Page.Choose(.(.Parameter, 0));
		Test.Assert(bed.Page.RemoveParameter());
		Test.Assert(bed.Parameters(.. scope .()) == "Trigger  Trigger");
		Test.Assert(!Bed.Info(bed.Page.LiveRows, "", "p1", scope PropertyInfo()), "made again for one parameter");

		bed.Page.AddLayer();
		Test.Assert(bed.Layers(.. scope .()) == "Base\nLayer");
		Test.Assert(bed.Page.Layer == 1);
		Test.Assert(bed.Page.RemoveLayer());
		Test.Assert(bed.Layers(.. scope .()) == "Base");
		Test.Assert(!bed.Page.RemoveLayer(), "the last stays");
	}
}
