using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Scene;
using Sedulous.Graphics;
using Sedulous.Runtime.Client;
using Sedulous.Particles;
using Sedulous.Particles.Resource;
using Sedulous.Particles.Pipeline;
using Sedulous.Engine.Render;
using Sedulous.Engine.Particles;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.Particles;

/// A row of the page's tree: what it stands for.
enum ParticleRowKind : uint8
{
	System,
	Emitter,
	Initializers,
	Behaviors,
	Initializer,
	Behavior,
	/// A system's sub-emitters, after its modules.
	SubEmitters,
	SubEmitter
}

struct ParticleTreeRow : IEquatable<ParticleTreeRow>
{
	public ParticleRowKind Kind = .System;
	public int32 System = -1;
	/// An initializer's, a behavior's or a sub-emitter's index (-1: not one).
	public int32 Module = -1;

	public this() { }

	public this(ParticleRowKind kind, int32 system, int32 module)
	{
		Kind = kind;
		System = system;
		Module = module;
	}

	public bool Equals(ParticleTreeRow other) => (Kind == other.Kind) && (System == other.System) && (Module == other.Module);

	public static bool operator==(ParticleTreeRow a, ParticleTreeRow b) => a.Equals(b);
}

/// The tree's model: a system's row renamed in place (F2, or Rename on its menu).
class ParticleTreeModel : TreeModel
{
	private delegate bool(int32 node) mEditable ~ delete _;
	private delegate bool(int32 node, StringView name) mRename ~ delete _;

	/// TAKES OWNERSHIP of both.
	public this(delegate bool(int32 node) editable, delegate bool(int32 node, StringView name) rename)
	{
		mEditable = editable;
		mRename = rename;
	}

	public override bool IsEditable(ModelIndex index) => (mEditable != null) && mEditable((int32)index.InternalId);

	public override bool SetData(ModelIndex index, Sedulous.GUI.Variant value)
	{
		let name = value.ToString(.. scope .());
		return (mRename != null) && !name.IsEmpty && mRename((int32)index.InternalId, name);
	}
}

/// A particle effect on the GUI from its markup (Data/Editor/ParticleEffectPage.xml; Raptor's
/// editor-gui spec, 5.4, layer 8). The effect's systems a tree (each its emitter, its initializers
/// and its behaviors), the live preview beside it, and the grid showing the chosen system by its
/// fields (FieldPropertySource, the user's ruling): its options, each shown where its render mode
/// uses it, its emitter, and its modules as the grid's lists, an add choosing the module's type among
/// those deriving from the list's base, so the page names no module type. A module chosen in the
/// tree opens in place there. Curves and gradients are the toolkit's editors over the particle curve
/// types, registered with the field source. Each system's sub-emitters (the old page had none) are
/// its own, a folder in the tree beside its modules and a list in its rows: each spawns, on this
/// system's particles' births or deaths, into another system it names (a choice of the others by
/// name), named in a line by what sets it off and where it spawns ("On death into Sparks"). The
/// tree's bar adds a system and removes the chosen system (while another remains), module or
/// sub-emitter. Every edit is one undo step: a row's value its own step (the
/// running preview keeps going), a list's change, a system added or removed the whole asset.
///
/// The preview simulates the authored effect itself, so an edit shows at once; when the modules or
/// the systems change it starts again over them, and when what they draw with changes (a texture, a
/// mesh, a material) it binds them again. Its transport plays, pauses and clears it and never writes
/// the effect: the old page's Stop and Play set every system emitting (a sub-emitter's child too,
/// which emits only when spawned) and so changed what was saved. Its speed is the page's alone.
class ParticleEffectEditorPage : AssetObjectPage, IPlaybackPage
{
	public const String cMarkupPath = "Editor/ParticleEffectPage.xml";
	/// The grid's section the chosen system's rows are in: its paths are "system/" and the system's own.
	public const String cSystemSection = "system";

	/// The system's own path of a grid row's ("system/Emitter.Mode" is "Emitter.Mode").
	public static StringView SystemPath(StringView gridPath)
	{
		let skip = cSystemSection.Length + 1; // "system/"
		if (gridPath.StartsWith(cSystemSection) && (gridPath.Length >= skip) && (gridPath[skip - 1] == '/'))
			return gridPath.Substring(skip);
		return gridPath;
	}

	/// The chosen system's rows; the base's sections let go of them first.
	private FieldPropertySource mValues = null;
	private ParticleTreeModel mModel ~ delete _;
	/// A tree row's menu (a reference of ours).
	private Sedulous.GUI.Menu mRowMenu = null ~ _?.ReleaseRef();
	private uint32 mTreeMenuListener = 0;
	/// The markup's: the tree holds it.
	private TreeView mTree = null;
	/// The tree's rows, by node id.
	private List<ParticleTreeRow> mRows = new .() ~ delete _;
	private int32 mSystem = -1;
	private ParticleTreeRow mChosen = .();
	/// Choosing from code: not the user's.
	private bool mShowing = false;

	private PreviewPane mPane = null;
	private EntityHandle mEmitter = .Invalid;
	/// The effect's references bound, for the preview's drawing (the component borrows it).
	private ParticleEffectResource mPreviewResource = null;
	private SerializerFactory mSerializers = (new (stream, mode) => new BinarySerializerContext(stream, mode)) ~ delete _;
	/// The systems and modules the preview runs over, and what they draw with, as last seen.
	private List<void*> mShape = new .() ~ delete _;
	private List<Guid> mBindings = new .() ~ delete _;
	private int mRestarts = 0;
	private bool mPaused = false;
	private bool mStopped = false;
	/// The markup's.
	private Sedulous.GUI.Label mCount = null;

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(ParticleEffectAsset), cMarkupPath)
	{
		ParticleEditor.RegisterRowTypes(); // the modules' types for the lists' adds, the curves as one value
		HideAssetRows(); // the effect's rows are the chosen system's, beside the tree
		mModel = new .(new [=this] (node) => (node >= 0) && (node < mRows.Count) && (mRows[node].Kind == .System),
			new [=this] (node, name) => (node >= 0) && (node < mRows.Count) && RenameSystem(mRows[node].System, name));
		mTree = Find<TreeView>("particle-tree");
		if (let add = Find<ButtonBase>("particle-add-system"))
			add.SetOnClick(new [=this] () => { AddSystem(); });
		if (let remove = Find<ButtonBase>("particle-remove"))
			remove.SetOnClick(new [=this] () => { RemoveChosen(); });
		if (mTree != null)
		{
			mTree.Model = mModel;
			mTree.SetOnSelectionChanged(new [=this] (index) =>
				{
					if (mShowing || !index.IsValid)
						return;
					let node = (int)index.InternalId;
					if ((node >= 0) && (node < mRows.Count))
						Choose(mRows[node]);
				});
			// A row's menu (the old page's): what adds, moves, renames or removes there.
			mTreeMenuListener = mTree.AddEventListener(.ContextMenu, new [=this] (e) =>
				{
					let at = ((MouseEvent)e).Position;
					let item = mTree.ItemAt(at);
					let node = (item >= 0) ? (int)mTree.GetItemIndex(item).InternalId : mRows.Count;
					if ((node < 0) || (node >= mRows.Count))
						return;
					ShowRowMenu(mRows[node], mTree, at);
					e.Handled = true;
				});
		}

		// The chosen system's rows: its fields', its curves and gradients the toolkit's; a value's edit
		// its own step, a list's the whole asset.
		mValues = new FieldPropertySource(typeof(ParticleSystem), 1,
			new [=this] (object) =>
			{
				let system = SystemAt(mSystem);
				return (system != null) ? Internal.UnsafeCastToPtr(system) : null;
			},
			new [=this] (apply) => { Commit(mSystem, apply); }, context.Resources);
		mValues.SetOnDescribe(new [=this] (path, info) => { DescribeRow(path, info); });
		AddSection(cSystemSection, "System", mValues);

		if (Content != null)
		{
			mPane = new PreviewPane(Content, Services, "particle.preview");
			mPane.OnFrame = new [=this] () => { FramePreview(); };
			BindAction(Find<ButtonBase>("particle-restart"), "playback.restart");
			BindAction(Find<ButtonBase>("particle-play"), "playback.play");
			BindAction(Find<ButtonBase>("particle-stop"), "playback.stop");
			mCount = Find<Sedulous.GUI.Label>("particle-count");
			if (let speed = Find<Slider>("particle-speed"))
			{
				speed.SetOnValueChanging(new [=this] (value) =>
					{
						if ((mPane != null) && (mPane.Viewport != null))
							mPane.Viewport.SetTimeScale((float)value);
					});
			}
			BuildPreviewScene();
		}
		let effect = Effect;
		Choose(.(.System, ((effect != null) && (effect.SystemCount > 0)) ? 0 : -1, -1));
		FollowEffect();
		ShowFacts();
	}

	public ~this()
	{
		if ((mRowMenu != null) && mRowMenu.IsOpen)
			mRowMenu.Close();
		if (mTree != null)
		{
			mTree.RemoveEventListener(mTreeMenuListener);
			mTree.Model = null;
		}
		DetachPreview();
		DeleteAndNullify!(mPane);
		delete mPreviewResource;
		// The grid's sections let go of the rows before they go (the base's outlive these).
		ClearSections();
		delete mValues;
	}

	/// The system the grid shows (-1: none, an empty effect).
	public int32 ChosenSystem => mSystem;

	/// The effect the page edits; null when the asset did not read.
	public ParticleEffect Effect
	{
		get
		{
			let asset = ObjectAs<ParticleEffectAsset>();
			return (asset != null) ? asset.Effect : null;
		}
	}

	/// The chosen system's rows.
	public IPropertySource SystemRows => mValues;
	/// How many times the preview started again over a changed set of modules or systems.
	public int PreviewRestarts => mRestarts;

	/// What the tree has chosen: its system shown, and the place it names opened in the grid.
	public void Choose(ParticleTreeRow row)
	{
		let effect = Effect;
		mSystem = ((effect != null) && (row.System >= 0) && (row.System < effect.SystemCount)) ? row.System : -1;
		mChosen = (mSystem >= 0) ? row : .();
		mValues.Refresh();
		// The place it names opened in place (a list's row: its list, then it) and brought into view.
		let place = PlaceOf(mChosen, .. scope .());
		if ((Grid != null) && !place.IsEmpty)
		{
			if (mChosen.Module >= 0)
			{
				let list = PlaceOf(.(FolderOf(mChosen.Kind), mChosen.System, -1), .. scope .());
				Grid.SetOpen(Sections.PathIn(cSystemSection, list, .. scope .()), true);
			}
			let path = Sections.PathIn(cSystemSection, place, .. scope .());
			Grid.SetOpen(path, true);
			let found = Grid.FindRow(path);
			if (found >= 0)
				Grid.ScrollToItem(found, .Start);
		}
		ShowTree();
	}

	/// A system added after the others (the new asset's default one), chosen.
	public void AddSystem()
	{
		if (Effect == null)
			return;
		EditWhole("edit_particle", scope (object) => { ParticleCreators.AddDefaultSystem(((ParticleEffectAsset)object).Effect); });
		Choose(.(.System, Effect.SystemCount - 1, -1));
	}

	/// A system's name, one undo step (its tree row renamed in place, or its Name row).
	public bool RenameSystem(int32 system, StringView name)
	{
		let effect = Effect;
		if ((effect == null) || (system < 0) || (system >= effect.SystemCount) || name.IsEmpty)
			return false;
		Choose(.(.System, system, -1));
		mValues.BeginEdit("Name");
		mValues.CommitEdit("Name", PropertyWrite(Sedulous.GUI.Variant(name))); // one step, as the grid's Name row
		return true;
	}

	/// Its tree row's name to type (F2; Rename on its menu).
	public bool BeginRename(int32 system)
	{
		if (mTree == null)
			return false;
		for (int32 item = 0; item < (int32)mTree.GetItemCount(); item++)
		{
			let node = (int)mTree.GetItemIndex(item).InternalId;
			if ((node >= 0) && (node < mRows.Count) && (mRows[node].Kind == .System) && (mRows[node].System == system))
				return mTree.BeginEdit(item);
		}
		return false;
	}

	/// What the Initializers' or Behaviors' folder adds, by type name, appended.
	public void ModuleTypes(ParticleRowKind folder, List<String> outTypes)
	{
		if ((folder != .Initializers) && (folder != .Behaviors))
			return;
		let list = (folder == .Initializers) ? "mInitializers" : "mBehaviors";
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		mValues.GetProperties("", rows);
		for (let info in rows)
		{
			if (info.Name == list)
			{
				for (let type in info.ElementTypes)
					outTypes.Add(new String(type));
			}
		}
	}

	/// A module of `type` added at the end of `folder`'s list, chosen; one step.
	public bool AddModule(ParticleTreeRow folder, StringView type)
	{
		if ((folder.Kind != .Initializers) && (folder.Kind != .Behaviors))
			return false;
		Choose(folder);
		let system = SystemAt(folder.System);
		if (system == null)
			return false;
		let index = (folder.Kind == .Initializers) ? system.InitializerCount : system.BehaviorCount;
		let edit = scope ListEdit(.Insert, index);
		edit.ElementType.Set(type);
		let kind = (folder.Kind == .Initializers) ? ParticleRowKind.Initializer : ParticleRowKind.Behavior;
		if (!mValues.EditList(PlaceOf(folder, .. scope .()), edit))
			return false;
		Choose(.(kind, folder.System, index)); // the new module opened
		return true;
	}

	/// A module, or a sub-emitter link, moved `by` places in its list, still chosen; one step.
	public bool MoveModule(ParticleTreeRow row, int32 by)
	{
		if ((row.Module < 0) || (row.Kind == .System))
			return false;
		let system = SystemAt(row.System);
		if (system == null)
			return false;
		let count = (row.Kind == .Initializer) ? system.InitializerCount : ((row.Kind == .Behavior) ? system.BehaviorCount : (int32)system.SubEmitters.Count);
		let to = row.Module + by;
		if ((to < 0) || (to >= count))
			return false;
		Choose(row);
		if (!mValues.EditList(PlaceOf(.(FolderOf(row.Kind), row.System, -1), .. scope .()), scope ListEdit(.Move, row.Module, to)))
			return false;
		Choose(.(row.Kind, row.System, to)); // it stays chosen where it went
		return true;
	}

	/// The tree row's menu at `at` over `owner`: a system's Add System, Rename and Delete; a
	/// folder's modules to add by type; a module's Move Up, Move Down and Delete.
	public void ShowRowMenu(ParticleTreeRow row, Node owner, Float2 at)
	{
		if (mRowMenu != null)
		{
			if (mRowMenu.IsOpen)
				mRowMenu.Close();
			mRowMenu.ReleaseRef();
		}
		mRowMenu = new Sedulous.GUI.Menu();
		let effect = Effect;
		let systems = (effect != null) ? effect.SystemCount : 0;
		switch (row.Kind)
		{
		case .System:
			mRowMenu.AddItem("Add System", new [=this] () => { AddSystem(); });
			mRowMenu.AddItem("Rename", new [=this, =row] () => { BeginRename(row.System); }).Shortcut = "F2";
			mRowMenu.AddSeparator();
			mRowMenu.AddItem("Delete System", new [=this, =row] () =>
				{
					Choose(row);
					RemoveChosen();
				}).Enabled = systems > 1; // an effect keeps a system
		case .Initializers, .Behaviors:
			let types = scope List<String>();
			defer { ClearAndDeleteItems!(types); }
			ModuleTypes(row.Kind, types);
			for (let type in types)
			{
				let named = new String(type);
				mRowMenu.AddItem(scope $"Add {type}", new [=this, =row, =named] () => { AddModule(row, named); } ~ delete named);
			}
		case .Initializer, .Behavior, .SubEmitter:
			mRowMenu.AddItem("Move Up", new [=this, =row] () => { MoveModule(row, -1); });
			mRowMenu.AddItem("Move Down", new [=this, =row] () => { MoveModule(row, 1); });
			mRowMenu.AddSeparator();
			mRowMenu.AddItem("Delete", new [=this, =row] () =>
				{
					Choose(row);
					RemoveChosen();
				});
		case .Emitter, .SubEmitters:
			return; // the emitter is the system's own; a link is added in the grid, where its child is chosen
		}
		mRowMenu.Open(owner, owner.RootNode.ConvertToNodeSpace(at)); // `at` is a pointer's, in world space
	}

	/// The tree row's menu, while it is open.
	public Sedulous.GUI.Menu RowMenu => ((mRowMenu != null) && mRowMenu.IsOpen) ? mRowMenu : null;

	/// The tree's chosen row taken out: a module or a sub-emitter, or a system while another remains.
	public bool RemoveChosen()
	{
		let effect = Effect;
		if ((effect == null) || (mChosen.System < 0) || (mChosen.System >= effect.SystemCount))
			return false;
		let row = mChosen;
		if (row.Module >= 0)
		{
			// Through the rows, as the grid's own remove: one step.
			mChosen = .(FolderOf(row.Kind), row.System, -1);
			return mValues.EditList(PlaceOf(mChosen, .. scope .()), scope ListEdit(.Remove, row.Module));
		}
		if ((row.Kind != .System) || (effect.SystemCount < 2))
			return false; // an effect keeps a system; the emitter and the lists are the system's rows'
		let index = row.System;
		EditWhole("edit_particle", scope (object) => { ((ParticleEffectAsset)object).Effect.RemoveSystem(index); });
		Choose(.(.System, Math.Min(index, Effect.SystemCount - 1), -1));
		return true;
	}

	// === For tests ===

	/// The tree's rows, indented ("Sparks\n  Emitter\n  Initializers\n    Lifetime"), into `outText`.
	public void Tree(String outText)
	{
		let effect = Effect;
		for (let row in mRows)
		{
			if (!outText.IsEmpty)
				outText.Append('\n');
			let system = effect.GetSystem(row.System);
			switch (row.Kind)
			{
			case .System: SystemName(system, row.System, outText);
			case .Emitter: outText.Append("  Emitter");
			case .Initializers: outText.Append("  Initializers");
			case .Behaviors: outText.Append("  Behaviors");
			case .Initializer: outText.Append("    "); ModuleName(system.GetInitializer(row.Module), outText);
			case .Behavior: outText.Append("    "); ModuleName(system.GetBehavior(row.Module), outText);
			case .SubEmitters: outText.Append("  Sub-emitters");
			case .SubEmitter: outText.Append("    "); LinkName(effect, system.SubEmitters[row.Module], outText);
			}
		}
	}

	// === IPlaybackPage: the preview's transport, the preview's alone, never the effect's ===

	public bool CanPlay => PreviewInstance != null;
	public bool IsPlaying => !mPaused && !mStopped;

	public void Play()
	{
		let instance = PreviewInstance;
		if (instance == null)
			return;
		if (mStopped)
			instance.Reset(); // from the start
		mPaused = false;
		mStopped = false;
		instance.IsActive = true;
	}

	public void Pause()
	{
		let instance = PreviewInstance;
		if ((instance == null) || mStopped)
			return;
		mPaused = true;
		instance.IsActive = false;
	}

	public void Stop()
	{
		let instance = PreviewInstance;
		if (instance == null)
			return;
		instance.Reset(); // its particles gone
		instance.IsActive = false;
		mPaused = false;
		mStopped = true;
	}

	public void Restart()
	{
		let instance = PreviewInstance;
		if (instance == null)
			return;
		instance.Reset();
		mPaused = false;
		mStopped = false;
		instance.IsActive = true;
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		base.OnUpdate(host, dt);
		ShowTransport();
		DrawEmissionShape();
		if (mPane != null)
			mPane.Update(dt);
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (mPane != null)
			mPane.Render(ref frame);
	}

	public override void OnClose()
	{
		if (mPane != null)
			mPane.Close();
	}

	protected override void OnObjectChanged()
	{
		// A whole edit, or its undo: the system may be gone, and its address moved; the asset read
		// again (written outside the page): the effect itself is another, which the rows find through
		// their resolvers and the preview follows.
		let effect = Effect;
		let count = (effect != null) ? effect.SystemCount : 0;
		if (mSystem >= count)
			mSystem = count - 1;
		if (mChosen.System != mSystem)
			mChosen = .(.System, mSystem, -1);
		Changed();
	}

	/// After any edit, its undo or its redo: a name, a module added or taken away, a render mode, a
	/// link: the rows, the tree, the facts, the links' names, the preview.
	public void Changed()
	{
		mValues.Refresh();
		let effect = Effect;
		if ((effect != null) && (mChosen.Module >= 0))
		{
			let system = effect.GetSystem(mChosen.System);
			var count = 0;
			if (system != null)
			{
				switch (mChosen.Kind)
				{
				case .Initializer: count = system.InitializerCount;
				case .Behavior: count = system.BehaviorCount;
				default: count = system.SubEmitters.Count;
				}
			}
			if (mChosen.Module >= count)
				mChosen = .(FolderOf(mChosen.Kind), mChosen.System, -1);
		}
		ShowTree();
		ShowFacts();
		FollowEffect();
	}

	// === Rows ===

	// The rows' commit: a value edited (the grid's edit open) is a step of its own over that row, so
	// the preview runs on; a list changed, a paste or a revert is the whole asset's.
	private void Commit(int32 system, delegate void(int object, void* value) apply)
	{
		let path = mValues.EditPath;
		if (path.IsEmpty)
		{
			EditWhole("edit_particle", scope [&] (object) =>
				{
					if (let target = ((ParticleEffectAsset)object).Effect.GetSystem(system))
						apply(0, Internal.UnsafeCastToPtr(target));
				});
			return;
		}
		// The row's value before (the source put its originals back) and after.
		let target = SystemAt(system);
		if (target == null)
			return;
		var before = mValues.GetValue(path, 0);
		defer before.Dispose();
		apply(0, Internal.UnsafeCastToPtr(target));
		var after = mValues.GetValue(path, 0);
		defer after.Dispose();
		Commands.Execute(new ParticleRowEditCommand(this, system, path, before, after));
	}

	/// A row's value written into system `system`, and the page told: what a row's step does and
	/// undoes.
	public void WriteRow(int32 system, StringView path, Sedulous.GUI.Variant value)
	{
		let target = SystemAt(system);
		if (target == null)
			return;
		let rows = scope FieldPropertySource(typeof(ParticleSystem), 1,
			new (object) => Internal.UnsafeCastToPtr(target), new (apply) => { apply(0, Internal.UnsafeCastToPtr(target)); },
			Context.Resources);
		String[1] paths = .(scope String(path));
		Sedulous.GUI.Variant[1] values = .(value);
		rows.WriteValues(0, paths, values);
		MarkDirty();
		Changed();
	}

	// A row as the page says it: a mesh's materials by their slots, the first the whole mesh's; a
	// sub-emitter named by what sets it off and where it spawns, where a choice of the other systems
	// by name (its index alone says nothing).
	private void DescribeRow(StringView path, PropertyInfo info)
	{
		let materials = "MaterialRefs.";
		if (path.StartsWith(materials))
		{
			if (int.Parse(path.Substring(materials.Length)) case .Ok(let slot))
			{
				info.DisplayName.Clear();
				if (slot == 0)
					info.DisplayName.Append("Slot 1 (whole mesh)");
				else
					info.DisplayName.AppendF("Slot {}", slot + 1);
			}
			return;
		}
		let effect = Effect;
		let system = SystemAt(mSystem);
		let links = "SubEmitters.";
		if ((system == null) || !path.StartsWith(links))
			return;
		let rest = path.Substring(links.Length);
		var dot = rest.IndexOf('.');
		if (dot < 0)
			dot = rest.Length;
		if (!(int.Parse(rest.Substring(0, dot)) case .Ok(let index)) || (index < 0) || (index >= system.SubEmitters.Count))
			return;
		if (dot == rest.Length)
		{
			info.DisplayName.Clear();
			LinkName(effect, system.SubEmitters[index], info.DisplayName);
			return;
		}
		if (rest.Substring(dot + 1) != "ChildSystemIndex")
			return;
		info.Kind = .Enum;
		info.HasRange = false;
		info.Hint.Clear();
		ClearAndDeleteItems!(info.Choices);
		info.AddChoice("Nothing", -1);
		for (int32 s < effect.SystemCount)
		{
			if (s != mSystem) // never into itself
				info.AddChoice(SystemName(effect.GetSystem(s), s, .. scope .()), s);
		}
	}

	// A sub-emitter as a line: what sets it off and where it spawns ("On death into Sparks").
	private static void LinkName(ParticleEffect effect, SubEmitterLink link, String outText)
	{
		outText.Append((link.Trigger == .OnDeath) ? "On death into " : "On birth into ");
		if (let child = effect.GetSystem(link.ChildSystemIndex))
			SystemName(child, link.ChildSystemIndex, outText);
		else
			outText.Append("nothing");
	}

	// The folder a list's row is in (an initializer's Initializers).
	private static ParticleRowKind FolderOf(ParticleRowKind kind)
	{
		switch (kind)
		{
		case .Initializer: return .Initializers;
		case .Behavior: return .Behaviors;
		case .SubEmitter: return .SubEmitters;
		default: return kind;
		}
	}

	private ParticleSystem SystemAt(int32 index)
	{
		let effect = Effect;
		return (effect != null) ? effect.GetSystem(index) : null;
	}

	// The grid's place a tree row names in its system (empty: the system's top).
	private static void PlaceOf(ParticleTreeRow row, String outPath)
	{
		switch (row.Kind)
		{
		case .Emitter: outPath.Append("Emitter");
		case .Initializers: outPath.Append("mInitializers");
		case .Behaviors: outPath.Append("mBehaviors");
		case .Initializer: outPath.AppendF("mInitializers.{}", row.Module);
		case .Behavior: outPath.AppendF("mBehaviors.{}", row.Module);
		case .SubEmitters: outPath.Append("SubEmitters");
		case .SubEmitter: outPath.AppendF("SubEmitters.{}", row.Module);
		case .System:
		}
	}

	private static void SystemName(ParticleSystem system, int32 index, String outText)
	{
		if ((system == null) || system.Name.IsEmpty)
			outText.AppendF("System {}", index + 1);
		else
			outText.Append(system.Name);
	}

	// A module as the tree names it: its type's [DisplayName], else its name.
	private static void ModuleName(Object module, String outText)
	{
		if (module == null)
			return;
		let type = module.GetType();
		if (type.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let shown))
			outText.Append(shown.Name);
		else
			type.GetName(outText);
	}

	private void ShowTree()
	{
		let effect = Effect;
		if (effect == null)
			return;
		mShowing = true;
		// What the user folded stays folded through the rebuild (a choice, an edit); a row new to the
		// tree opens.
		let folded = scope List<ParticleTreeRow>();
		if (mTree != null)
		{
			for (int node < mRows.Count)
			{
				if ((mRows[node].Module < 0) && !mTree.IsIdExpanded((ItemId)node))
					folded.Add(mRows[node]);
			}
		}
		mModel.Clear();
		mRows.Clear();
		int32 chosen = -1;
		let text = scope String();
		for (int32 s < effect.SystemCount)
		{
			let system = effect.GetSystem(s);
			text.Clear();
			SystemName(system, s, text);
			let systemNode = AddRow(TreeModel.Root, text, .(.System, s, -1), ref chosen);
			mModel.SetIcon(systemNode, "Editor/Icons/Types/ParticleEffectAsset.svg", "cat-rendering");
			mModel.SetIcon(AddRow(systemNode, "Emitter", .(.Emitter, s, -1), ref chosen), "Editor/Icons/particles.svg");
			let initializers = AddRow(systemNode, "Initializers", .(.Initializers, s, -1), ref chosen);
			mModel.SetIcon(initializers, "Editor/Icons/folder.svg");
			for (int32 i < system.InitializerCount)
			{
				text.Clear();
				ModuleName(system.GetInitializer(i), text);
				AddRow(initializers, text, .(.Initializer, s, i), ref chosen);
			}
			let behaviors = AddRow(systemNode, "Behaviors", .(.Behaviors, s, -1), ref chosen);
			mModel.SetIcon(behaviors, "Editor/Icons/folder.svg");
			for (int32 b < system.BehaviorCount)
			{
				text.Clear();
				ModuleName(system.GetBehavior(b), text);
				AddRow(behaviors, text, .(.Behavior, s, b), ref chosen);
			}
			let links = AddRow(systemNode, "Sub-emitters", .(.SubEmitters, s, -1), ref chosen);
			mModel.SetIcon(links, "Editor/Icons/hierarchy.svg");
			for (int32 l < (int32)system.SubEmitters.Count)
			{
				text.Clear();
				LinkName(effect, system.SubEmitters[l], text);
				AddRow(links, text, .(.SubEmitter, s, l), ref chosen);
			}
		}
		if (mTree != null)
		{
			for (int node < mRows.Count)
			{
				if (mRows[node].Module < 0)
					mTree.SetIdExpanded((ItemId)node, !folded.Contains(mRows[node]));
			}
			if (chosen >= 0)
			{
				ItemId[1] id = .((ItemId)chosen);
				mTree.SetSelectedIds(id);
			}
		}
		mShowing = false;
	}

	private int32 AddRow(int32 parent, StringView text, ParticleTreeRow row, ref int32 chosen)
	{
		let node = mModel.AddNode(parent, text);
		mRows.Add(row);
		if (row == mChosen)
			chosen = node;
		return node;
	}

	private void ShowFacts()
	{
		let effect = Effect;
		if (effect == null)
			return;
		int budget = 0;
		for (int32 s < effect.SystemCount)
			budget += effect.GetSystem(s).MaxParticles;
		SetFact("Systems", scope String()..AppendF("{}", effect.SystemCount));
		SetFact("Particle Budget", scope String()..AppendF("{}", budget));
	}

	// === The preview ===

	private Sedulous.Scene.Scene PreviewScene => ((mPane != null) && (mPane.Viewport != null)) ? mPane.Viewport.Scene : null;

	private void BuildPreviewScene()
	{
		let scene = PreviewScene;
		if ((scene == null) || (Effect == null))
			return;
		mPane.Viewport.SetSimulationEnabled(true); // particles simulate to show at all
		mEmitter = scene.CreateEntity("Emitter");
		if (let effects = scene.GetSystem<ParticleEffectComponentManager>())
			effects.Add(mEmitter); // given the effect by FollowEffect
		let sun = scene.CreateEntity("Sun");
		var t = Transform();
		t.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.35f) * Quaternion.FromAxisAngle(.(1, 0, 0), -1.05f);
		scene.SetLocalTransform(sun, t);
		if (let lights = scene.GetSystem<LightComponentManager>())
		{
			let light = lights.Add(sun);
			light.CastsShadows = false;
		}
		FramePreview();
		mPane.Show();
	}

	private ParticleEffectComponent* PreviewComponent
	{
		get
		{
			let scene = PreviewScene;
			let effects = (scene != null) ? scene.GetSystem<ParticleEffectComponentManager>() : null;
			return ((effects != null) && mEmitter.IsAssigned) ? effects.Get(mEmitter) : null;
		}
	}

	private ParticleEffectInstance PreviewInstance
	{
		get
		{
			let component = PreviewComponent;
			return (component != null) ? component.Instance : null;
		}
	}

	// The preview follows the effect: started again when its modules or systems changed, what they
	// draw with bound again when that changed.
	private void FollowEffect()
	{
		let effect = Effect;
		if (effect == null)
			return;
		// The effect itself (the asset read again is another), each system and each module by itself
		// and its type (a whole edit remakes them in place, where a new one may land at an old one's
		// address).
		let shape = scope List<void*>();
		let bindings = scope List<Guid>();
		shape.Add(Internal.UnsafeCastToPtr(effect));
		for (int32 s < effect.SystemCount)
		{
			let system = effect.GetSystem(s);
			shape.Add(Internal.UnsafeCastToPtr(system));
			for (int32 i < system.InitializerCount)
			{
				shape.Add(Internal.UnsafeCastToPtr(system.GetInitializer(i)));
				shape.Add(Internal.UnsafeCastToPtr(system.GetInitializer(i).GetType()));
			}
			shape.Add(null); // the initializers' end
			for (int32 b < system.BehaviorCount)
			{
				shape.Add(Internal.UnsafeCastToPtr(system.GetBehavior(b)));
				shape.Add(Internal.UnsafeCastToPtr(system.GetBehavior(b).GetType()));
			}
			shape.Add(null); // a system's end
			bindings.Add(system.TextureRef);
			bindings.Add(system.MeshRef);
			bindings.AddRange(system.MaterialRefs);
			bindings.Add(Guid((uint32)system.MaterialRefs.Count, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)); // a system's end
		}
		let reshaped = !Same(shape, mShape);
		let rebound = reshaped || !Same(bindings, mBindings);
		mShape.Clear();
		mShape.AddRange(shape);
		mBindings.Clear();
		mBindings.AddRange(bindings);

		let scene = PreviewScene;
		let effects = (scene != null) ? scene.GetSystem<ParticleEffectComponentManager>() : null;
		let component = PreviewComponent;
		if (reshaped)
		{
			mRestarts++;
			// A module put straight into a list (the grid's add) has its streams before it runs.
			for (int32 s < effect.SystemCount)
				effect.GetSystem(s).DeclareModuleStreams();
			if ((effects != null) && (component != null))
			{
				// Over the authored effect itself (a value edited shows at once); a new instance, its
				// systems' modules being new. It keeps the transport's state.
				effects.SetEffect(mEmitter, effect);
				if (let instance = PreviewInstance)
					instance.IsActive = IsPlaying;
			}
		}
		if (rebound && (component != null))
			RebindPreviewResources();
	}

	private static bool Same(List<Guid> a, List<Guid> b)
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

	private static bool Same(List<void*> a, List<void*> b)
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

	// The effect's references bound as the cook's factory binds them, for drawing alone: the
	// simulation keeps the authored effect.
	private void RebindPreviewResources()
	{
		let component = PreviewComponent;
		let resources = Context.Resources;
		if ((component == null) || (Effect == null))
			return;
		let previous = mPreviewResource;
		if (resources == null)
		{
			component.AttachedResource = null;
			mPreviewResource = null;
			delete previous;
			return;
		}
		let bound = new ParticleEffectResource();
		ParticleEffectSerialization.CloneEffect(Effect, bound.Effect, mSerializers).IgnoreError();
		bound.ResolveReferences(resources);
		component.AttachedResource = bound;
		mPreviewResource = bound;
		delete previous;
	}

	// Unhooks the borrowed effect and resource ahead of the page's own teardown.
	private void DetachPreview()
	{
		if (let component = PreviewComponent)
		{
			component.AttachedResource = null;
			DeleteAndNullify!(component.Instance);
			component.Effect = null;
		}
	}

	private void FramePreview()
	{
		if ((mPane == null) || (mPane.Viewport == null))
			return;
		let preview = mPane.Viewport;
		preview.Camera.Position = .(0.0f, 2.0f, 6.0f);
		preview.Camera.LookAt(.(0.0f, 1.0f, 0.0f));
	}

	// Where the chosen system spawns: its first position initializer's shape.
	private void DrawEmissionShape()
	{
		let preview = (mPane != null) ? mPane.Viewport : null;
		let system = SystemAt(mSystem);
		if ((preview == null) || !preview.IsValid || (system == null))
			return;
		EmissionShape* shape = null;
		for (int32 i < system.InitializerCount)
		{
			if (let position = system.GetInitializer(i) as PositionInitializer)
			{
				shape = &position.Shape;
				break;
			}
		}
		if (shape == null)
			return;
		let lines = preview.SceneDebugDraw;
		let color = Color(0.30f, 0.85f, 1.0f, 1.0f);
		let at = system.Position;
		let up = Float3(0.0f, 1.0f, 0.0f);
		let radius = Math.Max(shape.Radius, 0.01f);
		switch (shape.Type)
		{
		case .Sphere, .Hemisphere:
			lines.DrawWireSphere(at, radius, color);
		case .Box:
			lines.DrawWireBoxCenter(at, shape.Extents, color);
		case .Cone:
			lines.DrawCone(at, up, Math.Max(shape.Radius, 0.5f), Math.Max(shape.Angle, 0.01f), color);
		case .Ring, .Circle:
			lines.DrawCircleNormal(at, radius, up, color);
		case .Edge:
			lines.DrawLine(at - Float3(radius, 0.0f, 0.0f), at + Float3(radius, 0.0f, 0.0f), color);
		default:
			lines.DrawCross(at, 0.15f, color);
		}
	}

	private void ShowTransport()
	{
		if (mCount == null)
			return;
		let effect = Effect;
		int alive = 0;
		int most = 0;
		for (int32 s = 0; (effect != null) && (s < effect.SystemCount); s++)
		{
			alive += effect.GetSystem(s).AliveCount;
			most += effect.GetSystem(s).MaxParticles;
		}
		let state = mStopped ? "stopped" : (mPaused ? "paused" : "playing");
		// Its width fixed by the sheet; paused says so by its colour, as the Play button does by its
		// icon (a running count beside a word grew and shrank, moving what follows it).
		let text = scope String();
		if (mStopped)
			text.Append("Stopped");
		else
			text.AppendF("{} of {}", alive, most);
		if (mCount.Text != text)
			mCount.Text = text;
		for (let name in StringView[3]("stopped", "paused", "playing"))
		{
			if (name == state)
				mCount.AddClass(name);
			else
				mCount.RemoveClass(name);
		}
	}
}

/// One row's value edited on the particle page: its value before and after, written back by undo
/// and redo through the page, which follows (the tree, the facts, the preview).
class ParticleRowEditCommand : EditorCommand
{
	/// Borrowed: the page owns its command stack.
	private ParticleEffectEditorPage mPage;
	private int32 mSystem;
	private String mPath = new .() ~ delete _;
	private Sedulous.GUI.Variant mBefore = .() ~ _.Dispose();
	private Sedulous.GUI.Variant mAfter = .() ~ _.Dispose();

	/// The values are copied.
	public this(ParticleEffectEditorPage page, int32 system, StringView path, Sedulous.GUI.Variant before, Sedulous.GUI.Variant after)
	{
		mPage = page;
		mSystem = system;
		mPath.Set(path);
		mBefore = before.Copy();
		mAfter = after.Copy();
	}

	public override bool Execute()
	{
		mPage.WriteRow(mSystem, mPath, mAfter);
		return true;
	}

	public override void Undo()
	{
		mPage.WriteRow(mSystem, mPath, mBefore);
	}

	public override StringView TypeId => "edit_particle";
}
