using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.GUI;

namespace Samples.GUISandbox;

/// One of the Toolkit page's node graphs and the page's history of its changes.
class GraphHistory
{
	public GraphSet Set ~ delete _;
	public List<GraphChange> Undo = new .() ~ DeleteContainerAndItems!(_);
	public List<GraphChange> Redo = new .() ~ DeleteContainerAndItems!(_);
	/// Told each change and each step back or on (null: none).
	public delegate void() Changed ~ delete _;
}

/// A change of the reflected cameras and the cameras it was made on (0, 1, or 2 for both).
class CameraStep
{
	public ReflectedChange Change = new .() ~ delete _;
	public int Selection = 0;
}

// The Toolkit page (T0 to T7 of Raptor's gui-lab-evolution-3.md): its tool bars' commands and the
// status bar, a property grid over three lamps (LampSource), a reflected camera rig's grid, a clip
// of the lamps' values in a dopesheet and a curve view, a dataflow graph and a lamp's state
// machine, breadcrumb bars, and toasts. The undo of each is the page's (an application's), never
// the widget's. What the page's widgets read (the sources, the models, the formats) outlives them:
// ReleaseToolkit frees it after the trees have gone.
extension GUISandboxApp
{
	// The Toolkit page's edit history: changes left to save, to undo and to redo.
	private int32 mToolkitUnsaved = 0;
	private int32 mToolkitDone = 0;
	private int32 mToolkitUndone = 0;
	/// BORROWED: the tool bars' frame, in the page.
	private Node mToolkitFrame = null;

	// The property grid's lamps (T1).
	private LampSource mLamps = null;
	// The clip (T5): tracks of the lamps' values, its axis (a reference: the views hold theirs), and
	// the page's history of its changes.
	private CurveSet mClip = null;
	private TimeAxis mClipAxis = null;
	private List<CurveChange> mClipUndo = null;
	private List<CurveChange> mClipRedo = null;
	// The node graphs (T6): a dataflow graph and a lamp's state machine, the format their copies are
	// written in, and the state machine's active state.
	private GraphHistory mFlow = null;
	private GraphHistory mStates = null;
	private XmlTextFormat mGraphFormat = null;
	private GraphId mLampState = 0;
	// The toasts (T7): the Progress toast's percentage, and what was posted and closed.
	private int32 mCookPercent = 0;
	private uint32 mToastsPosted = 0;
	private uint32 mToastsClosed = 0;
	// The reflected cameras (T3), their source and its format, and the page's history of the
	// source's changes (each with the cameras it was made on).
	private CameraRig[2] mCameras = .(null, null);
	private XmlTextFormat mCameraFormat = null;
	private ReflectedPropertySource mReflected = null;
	private List<CameraStep> mCameraUndo = null;
	private List<CameraStep> mCameraRedo = null;
	private int mCameraSelection = 0;
	/// BORROWED, all three: in the page.
	private Label mCameraSaid = null;
	private Button mCameraUndoButton = null;
	private Button mCameraRedoButton = null;

	/// Frees what the Toolkit page's widgets read. After the trees have gone: a view leaves its
	/// source as it goes, so the source must still be there.
	private void ReleaseToolkit()
	{
		DeleteAndNullify!(mLamps);
		if (mClipAxis != null)
		{
			mClipAxis.SetOnPlayheadChanged(null);
			mClipAxis.ReleaseRef(); // the page's; the views let theirs go with the tree
			mClipAxis = null;
		}
		DeleteAndNullify!(mClip);
		DeleteListAndNullify(ref mClipUndo);
		DeleteListAndNullify(ref mClipRedo);
		DeleteAndNullify!(mFlow);
		DeleteAndNullify!(mStates);
		DeleteAndNullify!(mGraphFormat);
		// The source before the cameras it borrows.
		DeleteAndNullify!(mReflected);
		for (int i < 2)
			DeleteAndNullify!(mCameras[i]);
		DeleteAndNullify!(mCameraFormat);
		DeleteListAndNullify(ref mCameraUndo);
		DeleteListAndNullify(ref mCameraRedo);
		mCameraSaid = null;
		mCameraUndoButton = null;
		mCameraRedoButton = null;
		mToolkitFrame = null;
	}

	private static void DeleteListAndNullify<T>(ref List<T> list) where T : class, delete
	{
		if (list == null)
			return;
		DeleteContainerAndItems!(list);
		list = null;
	}

	// === Tool bars and the status bar (T0) ===

	// The commands: Save, Undo and Redo disabled until there is something to do, with the reason a
	// tooltip shows; Grid and Snap checked; Play and Add saying what they did on the status bar;
	// Narrow showing the tool bar's overflow.
	private void FillToolkit(Node frame)
	{
		mToolkitFrame = frame;
		(StringView id, StringView label, StringView keys)[14] commands = .(
			("toolkit.new", "New", "ctrl-n"), ("toolkit.open", "Open", "ctrl-o"),
			("toolkit.save", "Save", "ctrl-s"), ("toolkit.undo", "Undo", "ctrl-z"),
			("toolkit.redo", "Redo", "ctrl-y"), ("toolkit.grid", "Grid", ""),
			("toolkit.snap", "Snap", ""), ("toolkit.play", "Play", "f5"),
			("toolkit.play-here", "Play from here", ""), ("toolkit.play-window", "Play in a window", ""),
			("toolkit.add-cube", "Cube", ""), ("toolkit.add-sphere", "Sphere", ""),
			("toolkit.add-light", "Light", ""), ("toolkit.settings", "Settings", ""));
		for (let named in commands)
		{
			mGui.DefineCommand(named.id).Label = named.label;
			if (named.keys.Length != 0)
				mGui.Keymap.Bind(named.keys, named.id, "toolkit"); // while the focus is in the frame
		}
		mGui.DefineCommand("toolkit.grid").Checked = true;
		// The canvas takes the focus a click gives it, as an editor's view does: the frame's keys
		// run while the focus is in it.
		if (let canvas = FindById(frame, "toolkit-canvas"))
			canvas.TabFocusable = true;

		UpdateToolkitCommands();
		mRoot.OnCommand("toolkit.change", new (e) =>
			{
				++mToolkitUnsaved;
				++mToolkitDone;
				mToolkitUndone = 0;
				UpdateToolkitCommands();
				ToolkitStatus("Changed the scene");
			});
		mRoot.OnCommand("toolkit.save", new (e) =>
			{
				mToolkitUnsaved = 0;
				UpdateToolkitCommands();
				ToolkitStatus("Saved");
			});
		mRoot.OnCommand("toolkit.undo", new (e) =>
			{
				--mToolkitDone;
				++mToolkitUndone;
				++mToolkitUnsaved;
				UpdateToolkitCommands();
				ToolkitStatus("Undid the change");
			});
		mRoot.OnCommand("toolkit.redo", new (e) =>
			{
				--mToolkitUndone;
				++mToolkitDone;
				++mToolkitUnsaved;
				UpdateToolkitCommands();
				ToolkitStatus("Redid the change");
			});
		mRoot.OnCommand("toolkit.new", new (e) => { ToolkitStatus("A new scene"); });
		mRoot.OnCommand("toolkit.open", new (e) => { ToolkitStatus("Opened a scene"); });
		mRoot.OnCommand("toolkit.settings", new (e) => { ToolkitStatus("Settings would open here"); });
		mRoot.OnCommand("toolkit.grid", new (e) =>
			{
				let grid = mGui.DefineCommand("toolkit.grid");
				grid.Checked = !grid.Checked;
				if (let label = FindById(mToolkitFrame, "toolkit-grid-state") as Label)
					label.Text = grid.Checked ? "Grid on" : "Grid off";
				ToolkitStatus(grid.Checked ? "The grid shows" : "The grid hides");
			});
		mRoot.OnCommand("toolkit.snap", new (e) =>
			{
				let snap = mGui.DefineCommand("toolkit.snap");
				snap.Checked = !snap.Checked;
				ToolkitStatus(snap.Checked ? "Snapping to the grid" : "Not snapping");
			});
		mRoot.OnCommand("toolkit.play", new (e) => { ToolkitStatus("Playing"); });
		mRoot.OnCommand("toolkit.play-here", new (e) => { ToolkitStatus("Playing from here"); });
		mRoot.OnCommand("toolkit.play-window", new (e) => { ToolkitStatus("Playing in a window"); });
		mRoot.OnCommand("toolkit.add-cube", new (e) => { ToolkitStatus("Added a cube"); });
		mRoot.OnCommand("toolkit.add-sphere", new (e) => { ToolkitStatus("Added a sphere"); });
		mRoot.OnCommand("toolkit.add-light", new (e) => { ToolkitStatus("Added a light"); });
		mRoot.OnCommand("toolkit.narrow", new (e) =>
			{
				let holder = mToolkitFrame as UIWidget;
				if (holder == null)
					return;
				let narrow = !holder.HasClass("narrow");
				if (narrow)
					holder.AddClass("narrow");
				else
					holder.RemoveClass("narrow");
				let section = mToolkitFrame.Parent;
				if (let button = (section != null) ? (FindById(section, "toolkit-narrow") as Button) : null)
					button.Text = narrow ? "Widen the tool bar" : "Narrow the tool bar";
			});
	}

	// Save, Undo and Redo over the page's edit history of counts.
	private void UpdateToolkitCommands()
	{
		let save = mGui.DefineCommand("toolkit.save");
		save.Enabled = mToolkitUnsaved > 0;
		save.DisabledReason = "Nothing to save: make a change first";
		let undo = mGui.DefineCommand("toolkit.undo");
		undo.Enabled = mToolkitDone > 0;
		undo.DisabledReason = "Nothing to undo";
		let redo = mGui.DefineCommand("toolkit.redo");
		redo.Enabled = mToolkitUndone > 0;
		redo.DisabledReason = "Nothing to redo";
	}

	// A message on the frame's status bar for three seconds.
	private void ToolkitStatus(StringView text)
	{
		if (let bar = (mToolkitFrame != null) ? (FindById(mToolkitFrame, "toolkit-status") as StatusBar) : null)
			bar.ShowMessage(text, 3.0f);
	}

	// === The property grid (T1, T2) ===

	// Three lamps behind a selection, a search, and the page's undo.
	private void FillProperties(PropertyGrid grid)
	{
		mLamps = new LampSource();
		grid.Source = mLamps;
		let section = grid.Parent;
		if (section == null)
			return;
		let undo = FindById(section, "props-undo") as Button;
		let redo = FindById(section, "props-redo") as Button;
		let said = FindById(section, "props-said") as Label;
		let lamps = mLamps;
		ShowLampHistory(undo, redo);
		lamps.SetOnHistoryChanged(new (words) =>
			{
				ShowLampHistory(undo, redo);
				if (said != null)
					said.Text = words;
			});
		if (undo != null)
			undo.SetOnClick(new () => { lamps.Undo(); });
		if (redo != null)
			redo.SetOnClick(new () => { lamps.Redo(); });
		grid.SetOnMessage(new (message) => // why a paste was refused
			{
				if (said != null)
					said.Text = message;
			});
		if (let search = FindById(section, "props-search") as TextField)
			search.SetOnTextChanging(new (text) => { grid.Filter = text; });
		if (let objects = FindById(section, "props-objects") as ComboBox)
		{
			objects.SetOnSelectionChanged(new (index) =>
				{
					if (index >= 0)
						lamps.SetSelection(index);
				});
		}
	}

	private void ShowLampHistory(Button undo, Button redo)
	{
		if (undo != null)
			undo.Enabled = mLamps.CanUndo;
		if (redo != null)
			redo.Enabled = mLamps.CanRedo;
	}

	// === The reflected grid (T3) ===

	// Two camera rigs, one or both edited, the source's changes kept here for Undo and Redo.
	private void FillReflected(PropertyGrid grid)
	{
		StringView[2] names = .("Camera A", "Camera B");
		for (int i < 2)
		{
			mCameras[i] = new CameraRig();
			mCameras[i].Name = names[i];
			mCameras[i].SetSerial(7001 + (uint32)i);
		}
		// The second differs, so both show mixed.
		mCameras[1].FieldOfView = 45.0f;
		var position = mCameras[1].Position;
		position.X = 3.0f;
		mCameras[1].Position = position;
		// Still in RaptorCode: the second camera's Bloom effect (a reflected list of effects).
		mCameraFormat = new XmlTextFormat();
		mCameraUndo = new .();
		mCameraRedo = new .();
		mReflected = new ReflectedPropertySource();
		mReflected.TextFormat = mCameraFormat;
		// The sky is the GUI's ColorGradient, which the source shows as a gradient by its type: no
		// registration, as Raptor's RegisterGradientType makes for Core's fixed arrays.
		SelectCameras(0);
		grid.Source = mReflected;

		let section = grid.Parent;
		if (section == null)
			return;
		mCameraSaid = FindById(section, "reflected-said") as Label;
		mCameraUndoButton = FindById(section, "reflected-undo") as Button;
		mCameraRedoButton = FindById(section, "reflected-redo") as Button;
		ShowCameraHistory();
		mReflected.SetOnChange(new (change) =>
			{
				let step = new CameraStep();
				step.Change.Set(change); // the source's is its own: kept as a copy
				step.Selection = mCameraSelection;
				mCameraUndo.Add(step);
				ClearAndDeleteItems!(mCameraRedo);
				ShowCameraHistory();
				if (mCameraSaid != null)
					mCameraSaid.Text = change.Words;
			});
		if (mCameraUndoButton != null)
			mCameraUndoButton.SetOnClick(new () => { StepCameras(true); ShowCameraHistory(); });
		if (mCameraRedoButton != null)
			mCameraRedoButton.SetOnClick(new () => { StepCameras(false); ShowCameraHistory(); });
		grid.SetOnMessage(new (message) =>
			{
				if (mCameraSaid != null)
					mCameraSaid.Text = message;
			});
		if (let search = FindById(section, "reflected-search") as TextField)
			search.SetOnTextChanging(new (text) => { grid.Filter = text; });
		if (let objects = FindById(section, "reflected-objects") as ComboBox)
		{
			objects.SetOnSelectionChanged(new (index) =>
				{
					if (index >= 0)
						SelectCameras(index);
				});
		}
	}

	private void ShowCameraHistory()
	{
		if (mCameraUndoButton != null)
			mCameraUndoButton.Enabled = !mCameraUndo.IsEmpty;
		if (mCameraRedoButton != null)
			mCameraRedoButton.Enabled = !mCameraRedo.IsEmpty;
	}

	// Camera A (0), Camera B (1) or both (2) in the reflected grid.
	private void SelectCameras(int which)
	{
		mCameraSelection = which;
		Object[2] objects = .(null, null);
		int count = 0;
		for (int i < 2)
		{
			if ((which == i) || (which >= 2))
				objects[count++] = mCameras[i];
		}
		mReflected.SetObjects(Span<Object>(&objects[0], count), CameraRig.StaticGuiType);
	}

	// A change back (undo) or again (redo), on the cameras it was made on.
	private void StepCameras(bool undo)
	{
		let from = undo ? mCameraUndo : mCameraRedo;
		let to = undo ? mCameraRedo : mCameraUndo;
		if (from.IsEmpty)
			return;
		let step = from.PopBack();
		if (step.Selection != mCameraSelection)
			SelectCameras(step.Selection);
		mReflected.Restore(step.Change, undo);
		if (mCameraSaid != null)
			mCameraSaid.Text = scope String()..AppendF(undo ? "Undid: {}" : "Redid: {}", step.Change.Words);
		to.Add(step);
	}

	// === The clip (T5) ===

	// Eight tracks of the lamps' values ("Lamp A.intensity", "Lamp A.position.y" and the rest, the
	// dopesheet folding them by lamp and property, more rows than it shows at once), a ruler, a
	// dopesheet and a curve view on one axis. Scrubbing plays the tracks into the lamps, so the grid
	// above follows; each edit of the clip is a step of its Undo.
	private void FillClip(Node section)
	{
		if (mLamps == null)
			return;
		mClip = new CurveSet();
		mClipUndo = new .();
		mClipRedo = new .();
		AddTrack("Lamp A.intensity", .(0.95f, 0.75f, 0.3f, 1.0f), (0.0f, 5.0f), (1.0f, 14.0f), (2.5f, 3.0f), (4.0f, 5.0f));
		AddTrack("Lamp A.range", .(0.45f, 0.8f, 0.55f, 1.0f), (0.0f, 10.0f), (2.0f, 16.0f), (4.0f, 10.0f));
		AddTrack("Lamp B.intensity", .(0.45f, 0.65f, 1.0f, 1.0f), (0.0f, 12.5f), (1.5f, 4.0f), (3.0f, 12.5f));
		AddTrack("Lamp C.intensity", .(0.9f, 0.45f, 0.6f, 1.0f), (0.5f, 5.0f), (2.0f, 18.0f), (3.5f, 5.0f));
		AddTrack("Lamp A.position.y", .(0.7f, 0.55f, 0.95f, 1.0f), (0.0f, 3.0f), (2.0f, 6.0f), (4.0f, 3.0f));
		AddTrack("Lamp B.range", .(0.4f, 0.85f, 0.85f, 1.0f), (0.0f, 10.0f), (1.0f, 7.0f), (3.0f, 15.0f), (4.0f, 10.0f));
		AddTrack("Lamp B.position.y", .(0.85f, 0.85f, 0.45f, 1.0f), (0.5f, 3.0f), (2.5f, 1.0f), (4.0f, 3.0f));
		AddTrack("Lamp C.range", .(0.95f, 0.6f, 0.4f, 1.0f), (0.0f, 10.0f), (2.0f, 4.0f), (4.0f, 10.0f));
		mClipAxis = new TimeAxis();
		mClipAxis.Duration = 4.0f;
		mClipAxis.PixelsPerSecond = 100.0f;
		mClipAxis.FrameRate = 30.0f;
		let ruler = FindById(section, "clip-ruler") as TimeRuler;
		let sheet = FindById(section, "clip-sheet") as Dopesheet;
		let curves = FindById(section, "clip-curves") as CurveView;
		if (ruler != null)
			ruler.TimeAxis = mClipAxis;
		if (sheet != null)
		{
			sheet.TimeAxis = mClipAxis;
			sheet.Source = mClip;
		}
		if (curves != null)
		{
			curves.TimeAxis = mClipAxis;
			curves.SetValueRange(-1.0f, 21.0f);
			curves.Source = mClip;
		}
		let said = FindById(section, "clip-said") as Label;
		let undo = FindById(section, "clip-undo") as Button;
		let redo = FindById(section, "clip-redo") as Button;
		ShowClipHistory(undo, redo);
		mClipAxis.SetOnPlayheadChanged(new (seconds) =>
			{
				PlayClip(seconds);
				if (said != null)
				{
					let at = FormatStepped(seconds, 0.01f, .. scope String());
					said.Text = scope String()..AppendF("At frame {} ({} s): the lamps above show the tracks there.", (int64)Math.Round(seconds * 30.0f), at);
				}
			});
		mClip.SetOnCommit(new (change) =>
			{
				mClipUndo.Add(CopyCurveChange(change)); // the set's is its own: kept as a copy
				ClearAndDeleteItems!(mClipRedo);
				ShowClipHistory(undo, redo);
				PlayClip(mClipAxis.Playhead);
				if (said != null)
					said.Text = scope String()..AppendF("Changed {} track(s).", change.Curves.Count);
			});
		if (undo != null)
			undo.SetOnClick(new () => { StepClip(true, undo, redo, said); });
		if (redo != null)
			redo.SetOnClick(new () => { StepClip(false, undo, redo, said); });
		if (let frame = FindById(section, "clip-frame") as Button)
		{
			frame.SetOnClick(new () =>
				{
					if (curves != null)
						curves.FrameAll();
				});
		}
	}

	// A track of the clip: cubic keys, their tangents automatic, values kept between 0 and 20.
	private void AddTrack(StringView path, Color stroke, params (float time, float value)[] keys)
	{
		let info = scope CurveInfo(path);
		info.StrokeColor = stroke;
		info.HasRange = true;
		info.Min = 0.0f;
		info.Max = 20.0f;
		let made = scope List<CurveKey>();
		for (let key in keys)
		{
			var k = CurveKey(key.time, key.value, .Cubic);
			k.TangentMode = .Auto;
			made.Add(k);
		}
		ApplyCurveTangentModes(made);
		mClip.AddCurve(info, made);
	}

	private static CurveChange CopyCurveChange(CurveChange change)
	{
		let copy = new CurveChange();
		for (let edit in change.Curves)
		{
			let kept = new CurveEdit();
			kept.Curve = edit.Curve;
			kept.Before.AddRange(edit.Before);
			kept.After.AddRange(edit.After);
			copy.Curves.Add(kept);
		}
		return copy;
	}

	private void ShowClipHistory(Button undo, Button redo)
	{
		if (undo != null)
			undo.Enabled = !mClipUndo.IsEmpty;
		if (redo != null)
			redo.Enabled = !mClipRedo.IsEmpty;
	}

	private void StepClip(bool back, Button undo, Button redo, Label said)
	{
		let from = back ? mClipUndo : mClipRedo;
		let to = back ? mClipRedo : mClipUndo;
		if (from.IsEmpty)
			return;
		let change = from.PopBack();
		mClip.Apply(change, back);
		to.Add(change);
		ShowClipHistory(undo, redo);
		PlayClip(mClipAxis.Playhead);
		if (said != null)
			said.Text = back ? "Undid a clip change." : "Redid a clip change.";
	}

	// The clip's tracks at `time` played into the lamps they name ("Lamp B.intensity": Lamp B's
	// intensity).
	private void PlayClip(float time)
	{
		if ((mClip == null) || (mLamps == null))
			return;
		for (int c < mClip.CurveCount)
		{
			let path = scope String();
			mClip.GetChannelPath(c, path);
			let dot = path.IndexOf('.');
			if (dot < 0)
				continue;
			let lamp = mLamps.FindLamp(path.Substring(0, dot));
			let keys = mClip.GetKeys(c);
			if (!keys.IsEmpty)
				mLamps.SetAnimatedValue(lamp, path.Substring(dot + 1), (double)EvaluateCurve(keys, time));
		}
	}

	// === The node graphs (T6) ===

	// A graph of the page and its controls ("<prefix>-graph", "-undo", "-redo", "-frame", "-said"):
	// each change the graph tells goes on its Undo, and `changed` (owned; null: none) hears it and
	// each step back or on.
	private void WireGraph(GraphHistory graph, Node section, StringView prefix, delegate void() changed)
	{
		Node ById(StringView suffix) => FindById(section, scope String()..AppendF("{}{}", prefix, suffix));
		let view = ById("-graph") as GraphView;
		let undo = ById("-undo") as Button;
		let redo = ById("-redo") as Button;
		let frame = ById("-frame") as Button;
		let said = ById("-said") as Label;
		graph.Set.TextFormat = mGraphFormat;
		if (view != null)
		{
			view.Source = graph.Set;
			view.FrameAll();
		}
		delete graph.Changed;
		graph.Changed = changed;
		ShowGraphHistory(graph, undo, redo);
		graph.Set.SetOnChange(new (change) =>
			{
				let kept = new GraphChange();
				kept.Set(change); // the set's is its own: kept as a copy
				graph.Undo.Add(kept);
				ClearAndDeleteItems!(graph.Redo);
				ShowGraphHistory(graph, undo, redo);
				if (said != null)
					said.Text = scope String()..AppendF("{}.", change.Words);
				if (graph.Changed != null)
					graph.Changed();
			});
		if (undo != null)
			undo.SetOnClick(new () => { StepGraph(graph, true, undo, redo, said); });
		if (redo != null)
			redo.SetOnClick(new () => { StepGraph(graph, false, undo, redo, said); });
		if (frame != null)
		{
			frame.SetOnClick(new () =>
				{
					if (view != null)
						view.FrameAll();
				});
		}
	}

	private static void ShowGraphHistory(GraphHistory graph, Button undo, Button redo)
	{
		if (undo != null)
			undo.Enabled = !graph.Undo.IsEmpty;
		if (redo != null)
			redo.Enabled = !graph.Redo.IsEmpty;
	}

	private static void StepGraph(GraphHistory graph, bool back, Button undo, Button redo, Label said)
	{
		let from = back ? graph.Undo : graph.Redo;
		let to = back ? graph.Redo : graph.Undo;
		if (from.IsEmpty)
			return;
		let change = from.PopBack();
		graph.Set.Apply(change, back);
		if (said != null)
			said.Text = scope String()..AppendF(back ? "Undid: {}." : "Redid: {}.", change.Words);
		to.Add(change);
		ShowGraphHistory(graph, undo, redo);
		if (graph.Changed != null)
			graph.Changed();
	}

	// A dataflow graph: two Numbers mixed into a lamp's intensity and a Colour tinted into its
	// colour, its kinds of node under Values, Maths, Colour and Output, a pin's colour its type's (a
	// float's green, a colour's amber), a link only between pins of one type. And the lamp's state
	// machine: Off, On and Flicker and the transitions between them (node links), a double click
	// making a state the lamp's, which it and its transitions out show highlighted.
	private void FillGraphs(Node section)
	{
		mGraphFormat = new XmlTextFormat();
		let values = Color(0.27f, 0.47f, 0.73f, 1.0f);
		let maths = Color(0.36f, 0.55f, 0.36f, 1.0f);
		let colour = Color(0.66f, 0.45f, 0.22f, 1.0f);
		let output = Color(0.6f, 0.3f, 0.35f, 1.0f);

		mFlow = new GraphHistory();
		mFlow.Set = new GraphSet();
		let flow = mFlow.Set;
		let number = GraphNode("number", "Number", values, .. scope .());
		AddGraphPin(number, "value", .Output, "float");
		let tone = GraphNode("colour", "Colour", values, .. scope .());
		AddGraphPin(tone, "color", .Output, "color");
		let mix = GraphNode("mix", "Mix", maths, .. scope .());
		AddGraphPin(mix, "a", .Input, "float");
		AddGraphPin(mix, "b", .Input, "float");
		AddGraphPin(mix, "amount", .Input, "float");
		AddGraphPin(mix, "result", .Output, "float");
		let multiply = GraphNode("multiply", "Multiply", maths, .. scope .());
		AddGraphPin(multiply, "a", .Input, "float");
		AddGraphPin(multiply, "b", .Input, "float");
		AddGraphPin(multiply, "result", .Output, "float");
		let tint = GraphNode("tint", "Tint", colour, .. scope .());
		AddGraphPin(tint, "color", .Input, "color");
		AddGraphPin(tint, "amount", .Input, "float");
		AddGraphPin(tint, "color", .Output, "color");
		let lamp = GraphNode("lamp", "Lamp", output, .. scope .());
		lamp.Subtitle.Set("Lamp A");
		AddGraphPin(lamp, "intensity", .Input, "float");
		AddGraphPin(lamp, "color", .Input, "color");
		lamp.Deletable = false;
		flow.AddNodeType(scope GraphNodeType("number", "Number", "Values"), number);
		flow.AddNodeType(scope GraphNodeType("colour", "Colour", "Values"), tone);
		flow.AddNodeType(scope GraphNodeType("mix", "Mix", "Maths"), mix);
		flow.AddNodeType(scope GraphNodeType("multiply", "Multiply", "Maths"), multiply);
		flow.AddNodeType(scope GraphNodeType("tint", "Tint", "Colour"), tint);
		let low = PlaceNode(flow, number, 0.0f, 0.0f, "5");
		let high = PlaceNode(flow, number, 0.0f, 112.0f, "14");
		let mixed = PlaceNode(flow, mix, 224.0f, 32.0f, default);
		let warm = PlaceNode(flow, tone, 224.0f, 208.0f, "warm white");
		let tinted = PlaceNode(flow, tint, 432.0f, 192.0f, default);
		let lit = PlaceNode(flow, lamp, 640.0f, 96.0f, default);
		LinkPins(flow, low, "value", mixed, "a");
		LinkPins(flow, high, "value", mixed, "b");
		LinkPins(flow, mixed, "result", lit, "intensity");
		LinkPins(flow, warm, "color", tinted, "color");
		LinkPins(flow, tinted, "color", lit, "color");
		WireGraph(mFlow, section, "flow", null);

		// The lamp's states.
		mStates = new GraphHistory();
		mStates.Set = new GraphSet();
		let states = mStates.Set;
		states.NodeLinks = true;
		let state = GraphNode("state", "State", .(0.4f, 0.42f, 0.5f, 1.0f), .. scope .());
		states.AddNodeType(scope GraphNodeType("state", "State", "States"), state);
		let off = PlaceNode(states, GraphNode("state", "Off", .(0.32f, 0.34f, 0.4f, 1.0f), .. scope .()), 0.0f, 64.0f, "intensity 0");
		let on = PlaceNode(states, GraphNode("state", "On", .(0.75f, 0.6f, 0.25f, 1.0f), .. scope .()), 256.0f, 0.0f, "steady");
		let flicker = PlaceNode(states, GraphNode("state", "Flicker", .(0.7f, 0.4f, 0.2f, 1.0f), .. scope .()), 256.0f, 160.0f, "its Flicker curve");
		LinkNodes(states, off, on);
		LinkNodes(states, on, off);
		LinkNodes(states, on, flicker);
		LinkNodes(states, flicker, on);
		mLampState = on;
		let view = FindById(section, "states-graph") as GraphView;
		let said = FindById(section, "states-said") as Label;
		WireGraph(mStates, section, "states", new () => { ShowLampState(view); });
		ShowLampState(view);
		if (view != null)
		{
			view.SetOnNodeDoubleClick(new (chosen) =>
				{
					let info = mStates.Set.GetNode(chosen);
					if (info == null)
						return;
					mLampState = chosen;
					ShowLampState(view);
					if (said != null)
						said.Text = scope String()..AppendF("The lamp is {}.", info.Title);
				});
		}
	}

	// The active state and its transitions out, highlighted.
	private void ShowLampState(GraphView view)
	{
		if (view == null)
			return;
		let active = mStates.Set.GetNode(mLampState);
		if (active == null)
			mLampState = 0;
		view.SetHighlightedNodes(Span<GraphId>(&mLampState, (active != null) ? 1 : 0));
		let leaving = scope List<GraphId>();
		for (let at in mStates.Set.State.Links)
		{
			if ((at.Kind == .Nodes) && (at.FromNode == mLampState))
				leaving.Add(at.Id);
		}
		view.SetHighlightedLinks(leaving);
	}

	// A node's template: its type, title and header colour, into `outInfo`.
	private static void GraphNode(StringView type, StringView title, Color header, GraphNodeInfo outInfo)
	{
		outInfo.Type.Set(type);
		outInfo.Title.Set(title);
		outInfo.HeaderColor = header;
	}

	// A pin, its colour its type's (a colour's amber, a float's green); an output takes many links.
	private static void AddGraphPin(GraphNodeInfo node, StringView name, GraphPinDirection direction, StringView type)
	{
		let pin = scope GraphPinInfo(name, direction, type, direction == .Output);
		pin.TypeColor = (type == "color") ? Color(0.95f, 0.72f, 0.3f, 1.0f) : Color(0.55f, 0.85f, 0.45f, 1.0f);
		node.AddPin(pin);
	}

	// A copy of `template` added at (x, y) with its own subtitle (empty: the template's); its id.
	private static GraphId PlaceNode(GraphSet graph, GraphNodeInfo template, float x, float y, StringView subtitle)
	{
		let info = scope GraphNodeInfo();
		info.Set(template);
		info.Position = .(x, y);
		if (subtitle.Length != 0)
			info.Subtitle.Set(subtitle);
		return graph.AddNode(info);
	}

	private static void LinkPins(GraphSet graph, GraphId from, StringView output, GraphId to, StringView input)
	{
		GraphLinkInfo made = .();
		made.FromNode = from;
		made.FromPin = graph.FindPin(from, output, .Output);
		made.ToNode = to;
		made.ToPin = graph.FindPin(to, input, .Input);
		graph.AddLink(made);
	}

	// A transition of the state machine: a link from node to node.
	private static void LinkNodes(GraphSet graph, GraphId from, GraphId to)
	{
		GraphLinkInfo made = .();
		made.Kind = .Nodes;
		made.FromNode = from;
		made.ToNode = to;
		graph.AddLink(made);
	}

	// === Breadcrumbs (T7) ===

	private static StringView[18] sCrumbFolders = .(
		"Content",
		"Content/Models",
		"Content/Models/Characters",
		"Content/Models/Characters/Fox",
		"Content/Models/Characters/Robot",
		"Content/Models/Props",
		"Content/Models/Props/Crate",
		"Content/Models/Props/Lamp",
		"Content/Textures",
		"Content/Textures/Wood",
		"Content/Textures/Stone",
		"Content/Audio",
		"Content/Audio/Music",
		"Content/Audio/Effects",
		"Content/Audio/Effects/Footsteps",
		"Content/Scenes",
		"Content/Scenes/Town",
		"Content/Scenes/Forest");

	// Two breadcrumb bars over an invented asset tree, a path not in it answered by a toast.
	private void FillCrumbs(Node section)
	{
		let wide = FindById(section, "crumbs-bar") as BreadcrumbBar;
		let narrow = FindById(section, "crumbs-narrow") as BreadcrumbBar;
		let said = FindById(section, "crumbs-said") as Label;
		if ((wide == null) || (narrow == null))
			return;
		BreadcrumbBar[2] bars = .(wide, narrow);
		for (let bar in bars)
		{
			bar.SetOnNavigate(new (item) => { GoToCrumb(wide, narrow, said, item.Id); });
			bar.SetOnChildren(new (item, children) =>
				{
					let at = StringView(item.Id);
					for (let path in sCrumbFolders)
					{
						if ((path.Length <= at.Length + 1) || (path.Substring(0, at.Length) != at) || (path[at.Length] != '/'))
							continue;
						let name = path.Substring(at.Length + 1);
						if (name.IndexOf('/') < 0) // a direct child
							children.Add(new BreadcrumbItem(path, name, path));
					}
				});
			bar.SetSegmentDropTypes("asset");
			bar.SetOnSegmentDrop(new (item, payload, effect) =>
				{
					if (said != null)
						said.Text = scope String()..AppendF("Moved {} into {}.", payload.Label, item.Id);
				});
		}
		wide.IsPathEditable = true;
		wide.SetOnPathSubmitted(new (typed) =>
			{
				let path = scope String(typed);
				path.Trim();
				while ((path.Length > 1) && path.EndsWith('/'))
					path.RemoveFromEnd(1);
				if (CrumbFolderExists(path))
				{
					GoToCrumb(wide, narrow, said, path);
					return;
				}
				let request = scope ToastRequest();
				request.Severity = .Warning;
				request.Title = "No such folder";
				request.Message = scope String()..AppendF("{} is not in the asset tree.", path);
				request.Key = "crumbs-path";
				mToasts.Post(request);
			});
		GoToCrumb(wide, narrow, said, "Content/Models/Characters/Fox");
		if (let up = FindById(section, "crumbs-up") as Button)
		{
			up.SetOnClick(new () =>
				{
					if (wide.ItemCount > 1)
						GoToCrumb(wide, narrow, said, scope String(wide.ItemAt(wide.ItemCount - 2).Id));
				});
		}
		if (let chip = FindById(section, "crumbs-chip"))
		{
			chip.SetDragSource(new (request) =>
				{
					request.Payload.Type.Set("asset");
					request.Payload.Label.Set("fox.glb");
					return true;
				});
		}
	}

	// Both bars at `path`. `path` is copied first: it may be a view of a bar's own item, which
	// SetPath replaces.
	private static void GoToCrumb(BreadcrumbBar wide, BreadcrumbBar narrow, Label said, StringView path)
	{
		let at = scope String(path);
		wide.SetPath(at);
		narrow.SetPath(at);
		if (said != null)
			said.Text = scope String()..AppendF("In {}.", at);
	}

	private static bool CrumbFolderExists(StringView path)
	{
		for (let folder in sCrumbFolders)
		{
			if (folder == path)
				return true;
		}
		return false;
	}

	// === Toasts (T7) ===

	// Buttons posting each kind of toast to the shell's host (the core's, over the whole window).
	private void FillToasts(Node section)
	{
		let toastSaid = FindById(section, "toast-said") as Label;
		mToasts.SetOnPosted(new (id, card) =>
			{
				++mToastsPosted;
				TellToasts(toastSaid);
			});
		mToasts.SetOnDismissed(new (id, byUser) =>
			{
				if (byUser)
					++mToastsClosed;
				TellToasts(toastSaid);
			});
		void OnButton(StringView id, delegate void() click)
		{
			if (let found = FindById(section, id) as Button)
				found.SetOnClick(click);
			else
				delete click;
		}
		OnButton("toast-info", new () => { PostToast(.Info, "", "Autosaved the scene."); });
		OnButton("toast-success", new () =>
			{
				let request = scope ToastRequest();
				request.Severity = .Success;
				request.Title = "Exported";
				request.Message = "Town exported to Dist/Town.";
				request.Actions.Add(new ToastAction("reveal", "Reveal", ""));
				mToasts.Post(request, new (action) =>
					{
						if (toastSaid != null)
							toastSaid.Text = "Revealed Dist/Town (the toast's action).";
					});
			});
		OnButton("toast-warning", new () => { PostToast(.Warning, "Large textures", "3 textures are larger than 4096 pixels."); });
		OnButton("toast-error", new () =>
			{
				let request = scope ToastRequest();
				request.Severity = .Error;
				request.Title = "Cook failed";
				request.Message = "Models/Fox.glb: the material [b]fur[/b] is missing.";
				request.Rich = true;
				mToasts.Post(request);
			});
		OnButton("toast-repeat", new () =>
			{
				let request = scope ToastRequest();
				request.Severity = .Warning;
				request.Message = "Shader compiled with a warning.";
				request.Key = "shader";
				mToasts.Post(request);
			});
		OnButton("toast-progress", new () =>
			{
				mCookPercent = (mCookPercent >= 100) ? 20 : mCookPercent + 20;
				let done = mCookPercent >= 100;
				let request = scope ToastRequest();
				request.Severity = done ? .Success : .Info;
				request.Title = done ? "Cooked" : "Cooking";
				if (done)
					request.Message = "Every asset is cooked.";
				else
				{
					request.Message = scope String()..AppendF("{}% of the assets, click again to go on.", mCookPercent);
					request.Duration = 0.0f; // until it is done
				}
				request.Key = "cook";
				mToasts.Post(request);
			});
		OnButton("toast-widget", new () =>
			{
				let content = new Panel();
				content.EditLayoutStyle(scope (s) =>
					{
						s.Direction = .Column;
						s.RowGap = 6.0f;
					});
				let label = new Label();
				label.Text = "Baking the lights of Town";
				let bar = new ProgressBar();
				bar.AddClass("toast-progress");
				bar.Value = 0.6;
				content.AddChild(label);
				label.ReleaseRef(); // the panel's keeps it
				content.AddChild(bar);
				bar.ReleaseRef();
				content.AccessLabel = "Baking the lights of Town, 60 percent";
				let request = scope ToastRequest();
				request.Content = content;
				content.ReleaseRef(); // the request's keeps it, and the toast takes its own
				mToasts.Post(request);
			});
		OnButton("toast-bare", new () =>
			{
				let banner = new Label();
				banner.AddClass("achievement");
				banner.Text = "Achievement: First steps";
				let request = scope ToastRequest();
				request.Content = banner;
				banner.ReleaseRef(); // the request's keeps it
				request.Bare = true;
				request.Announcement = "Achievement unlocked: First steps";
				mToasts.Post(request);
			});
		OnButton("toast-thread", new () =>
			{
				let host = mToasts;
				let worker = scope Thread(new () =>
					{
						let request = scope ToastRequest();
						request.Title = "From a worker";
						request.Message = "Posted from another thread, shown on the GUI's next frame.";
						host.PostFromAnyThread(request);
					});
				worker.Start(false);
				worker.Join();
			});
		OnButton("toast-clear", new () => { mToasts.DismissAll(); });
	}

	private void PostToast(ToastSeverity severity, StringView title, StringView message)
	{
		let request = scope ToastRequest();
		request.Severity = severity;
		request.Title = title;
		request.Message = message;
		mToasts.Post(request);
	}

	private void TellToasts(Label said)
	{
		if (said != null)
		{
			said.Text = scope String()..AppendF("{} posted, {} closed by you, {} showing, {} waiting.", mToastsPosted, mToastsClosed,
				mToasts.ShownCount, mToasts.WaitingCount);
		}
	}
}
