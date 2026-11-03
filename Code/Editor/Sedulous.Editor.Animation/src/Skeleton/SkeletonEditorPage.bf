using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Animation;
using Sedulous.Animation.Pipeline;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Animation;

/// What a skeleton is, as the page's read-only rows say it: its bones, roots and deepest chain.
struct SkeletonFacts
{
	public int32 Bones = 0;
	public int32 Roots = 0;
	/// Bones below its deepest root, along the longest chain.
	public int32 Depth = 0;

	public this() { }

	public static SkeletonFacts Of(Skeleton skeleton)
	{
		var facts = SkeletonFacts();
		facts.Bones = skeleton.BoneCount;
		for (int32 i < skeleton.BoneCount)
		{
			let bone = skeleton.GetBone(i);
			if (bone == null)
				continue;
			if (bone.ParentIndex < 0)
				facts.Roots++;
			int32 depth = 0;
			var walk = bone;
			while ((walk != null) && (walk.ParentIndex >= 0) && (depth < skeleton.BoneCount))
			{
				depth++;
				walk = skeleton.GetBone(walk.ParentIndex);
			}
			facts.Depth = Math.Max(facts.Depth, depth);
		}
		return facts;
	}
}

/// A skeleton on the GUI from its markup (Data/Editor/SkeletonPage.xml; Raptor's editor-gui spec,
/// 5.4, layer 10, part 3). A viewer: a skeleton comes from its model's import and nothing here edits
/// it. Its bones are a tree (each under its parent), with a search that keeps a bone whose name holds
/// it and the bones above it, so where it hangs still shows; a bone the user folds stays folded.
/// Beside it the bind pose, drawn from the asset itself (it shows before a cook), the chosen bone
/// drawn apart. The grid has the chosen bone's facts (its name, index, parent, children and bind
/// position, rotation and scale) and the skeleton's (its bones, roots and deepest chain), all read
/// only.
class SkeletonEditorPage : AssetObjectPage
{
	public const String cMarkupPath = "Editor/SkeletonPage.xml";
	private static readonly StringView[6] cBoneRowsAfterName = .("index", "parent", "children", "position", "rotation", "scale");

	/// Filled from the asset's source.
	private Skeleton mSkeleton = null ~ delete _;
	private TreeModel mModel = new .() ~ delete _;
	/// The markup's (its tree holds it).
	private TreeView mTree = null;
	/// The bone each tree node stands for, by node id.
	private List<int32> mRows = new .() ~ delete _;
	private String mSearch = new .() ~ delete _;
	private int32 mChosen = -1;
	/// Choosing from code: not the user's.
	private bool mShowing = false;
	/// The rows; the base's sections let go of them first (ClearSections).
	private Sedulous.GUI.PropertyBag mBoneRows = null;
	private PreviewPane mPane = null;
	private List<BoneTransform> mBind = new .() ~ delete _;
	private List<Float4x4> mWorld = new .() ~ delete _;
	private bool mFramed = false;

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(SkeletonAsset), cMarkupPath)
	{
		HideAssetRows(); // its source is its import's: the rows are what it is, read only
		mTree = Find<TreeView>("skeleton-tree");
		if (mTree != null)
		{
			mTree.Model = mModel;
			mTree.SetOnSelectionChanged(new [=this] (index) =>
				{
					if (mShowing || !index.IsValid)
						return;
					let node = (int)index.InternalId;
					if ((node >= 0) && (node < mRows.Count))
						ChooseBone(mRows[node]);
				});
		}
		if (let search = Find<TextField>("skeleton-search"))
			search.SetOnTextChanging(new [=this] (text) => { Search(text); });

		mBoneRows = new Sedulous.GUI.PropertyBag();
		AddFact("name", "Name");
		AddFact("index", "Index");
		AddFact("parent", "Parent");
		AddFact("children", "Children");
		AddFact("position", "Bind position");
		AddFact("rotation", "Bind rotation");
		AddFact("scale", "Bind scale");
		mBoneRows.PropertiesChanged(); // Add told the grid before the rows' names were set
		AddSection("bone", "Bone", mBoneRows);

		if (Content != null)
		{
			mPane = new PreviewPane(Content, Services, "skeleton.preview");
			mPane.OnFrame = new [=this] () => { FramePreview(); };
		}
		BuildSkeleton();
		ChooseBone(((mSkeleton != null) && (mSkeleton.BoneCount > 0)) ? 0 : -1);
	}

	public ~this()
	{
		if (mTree != null)
			mTree.Model = null;
		DeleteAndNullify!(mPane);
		// The grid's sections let go of the rows before they go (the base's outlive these).
		ClearSections();
		DeleteAndNullify!(mBoneRows);
	}

	/// The bone chosen (-1: none): drawn apart, its facts in the grid, its row selected.
	public void ChooseBone(int32 bone)
	{
		mChosen = ((mSkeleton != null) && (bone >= 0) && (bone < mSkeleton.BoneCount)) ? bone : -1;
		ShowBone();
		if (mTree == null)
			return;
		mShowing = true;
		for (int node < mRows.Count)
		{
			if (mRows[node] == mChosen)
			{
				ItemId[1] id = .((ItemId)node);
				mTree.SetSelectedIds(id);
			}
		}
		mShowing = false;
	}

	public int32 ChosenBone => mChosen;

	/// The tree keeps the bones whose names hold `text` and those above them (empty: all).
	public void Search(StringView text)
	{
		var trimmed = text;
		trimmed.Trim();
		mSearch.Set(trimmed);
		ShowTree();
	}

	// === For tests ===

	/// The tree's rows, indented ("Hips\n  Spine\n    Chest"), appended to `outText`.
	public void Tree(String outText)
	{
		// The rows in the model's order, each indented by its depth among the rows shown.
		for (let bone in mRows)
		{
			int32 depth = 0;
			for (var walk = mSkeleton.GetBone(bone).ParentIndex; walk >= 0; walk = mSkeleton.GetBone(walk).ParentIndex)
				depth++;
			if (!outText.IsEmpty)
				outText.Append('\n');
			for (int i < depth)
				outText.Append("  ");
			outText.Append(mSkeleton.GetBone(bone).Name);
		}
	}

	public Sedulous.GUI.PropertyBag BoneRows => mBoneRows;
	public Skeleton ShownSkeleton => mSkeleton;

	/// A rotation as its row says it: degrees about an axis ("90° about 0, 1, 0"; "None"), appended.
	public static void DescribeRotation(Quaternion rotation, String outText)
	{
		var q = rotation;
		let length = Math.Sqrt(q.X * q.X + q.Y * q.Y + q.Z * q.Z + q.W * q.W);
		if (length < 1e-6f)
		{
			outText.Append("None");
			return;
		}
		q = .(q.X / length, q.Y / length, q.Z / length, q.W / length);
		if (q.W < -1e-5f) // the shorter way round (a half turn, w about 0, either way)
			q = .(-q.X, -q.Y, -q.Z, -q.W);
		let angle = 2.0f * (float)Math.Acos((double)Math.Clamp(q.W, -1.0f, 1.0f));
		let degrees = angle * 180.0f / Math.PI_f;
		let s = Math.Sqrt(Math.Max(1.0f - q.W * q.W, 0.0f));
		if ((degrees < 0.05f) || (s < 1e-5f))
		{
			outText.Append("None");
			return;
		}
		Short(degrees, outText);
		outText.Append("° about ");
		Describe(.(q.X / s, q.Y / s, q.Z / s), outText);
	}

	protected override void OnObjectChanged()
	{
		// Read again from its source (a page_reload, a re-import): its bones may be others now.
		BuildSkeleton();
		ChooseBone((mChosen < ((mSkeleton != null) ? mSkeleton.BoneCount : 0)) ? mChosen : -1);
	}

	private void AddFact(StringView path, StringView shown)
	{
		let info = mBoneRows.Add(path, .String, Sedulous.GUI.Variant(""));
		info.DisplayName.Set(shown);
		info.ReadOnly = true;
	}

	private void BuildSkeleton()
	{
		let asset = ObjectAs<SkeletonAsset>();
		delete mSkeleton;
		mSkeleton = new Skeleton();
		if (asset != null)
			asset.Source.FillSkeleton(mSkeleton);
		mFramed = false;
		ShowTree();
		ShowFacts();
	}

	private void ShowFacts()
	{
		if (mSkeleton == null)
			return;
		let facts = SkeletonFacts.Of(mSkeleton);
		SetFact("Bones", scope String()..AppendF("{}", facts.Bones));
		SetFact("Roots", scope String()..AppendF("{}", facts.Roots));
		SetFact("Deepest chain", scope String()..AppendF("{} below its root", facts.Depth));
	}

	private void ShowTree()
	{
		if (mSkeleton == null)
			return;
		mShowing = true;
		// A bone the user folded stays folded through the rebuild (a search, a reload).
		let folded = scope List<int32>();
		if (mTree != null)
		{
			for (int node < mRows.Count)
			{
				if (!mTree.IsIdExpanded((ItemId)node))
					folded.Add(mRows[node]);
			}
		}
		// A search keeps the bones whose names hold it, and every bone above one (where it hangs).
		AnimationPreview.FillBoneTree(mModel, mRows, mSkeleton, mSearch);
		int32 chosen = -1;
		for (int node < mRows.Count)
		{
			if (mRows[node] == mChosen)
				chosen = (int32)node;
		}
		if (mTree != null)
		{
			for (int node < mRows.Count)
				mTree.SetIdExpanded((ItemId)node, !folded.Contains(mRows[node]) || !mSearch.IsEmpty); // a search opens what it found
			if (chosen >= 0)
			{
				ItemId[1] id = .((ItemId)chosen);
				mTree.SetSelectedIds(id);
			}
		}
		mShowing = false;
	}

	private void ShowBone()
	{
		let bone = ((mChosen >= 0) && (mSkeleton != null)) ? mSkeleton.GetBone(mChosen) : null;
		if (bone == null)
		{
			SetRow("name", "None chosen");
			for (let path in cBoneRowsAfterName)
				SetRow(path, "");
			return;
		}
		let parent = (bone.ParentIndex >= 0) ? mSkeleton.GetBone(bone.ParentIndex) : null;
		int32 children = 0;
		for (int32 b < mSkeleton.BoneCount)
		{
			if (mSkeleton.GetBone(b).ParentIndex == mChosen)
				children++;
		}
		SetRow("name", bone.Name);
		SetRow("index", scope String()..AppendF("{}", mChosen));
		SetRow("parent", (parent != null) ? (StringView)parent.Name : "None: a root");
		SetRow("children", scope String()..AppendF("{}", children));
		SetRow("position", Describe(bone.LocalBindPose.Position, .. scope String()));
		SetRow("rotation", DescribeRotation(bone.LocalBindPose.Rotation, .. scope String()));
		SetRow("scale", Describe(bone.LocalBindPose.Scale, .. scope String()));
	}

	private void SetRow(StringView path, StringView value)
	{
		var shown = mBoneRows.GetValue(path, 0); // an owned copy
		defer shown.Dispose();
		if (shown.AsString != value)
			mBoneRows.SetValue(path, 0, Sedulous.GUI.Variant(value));
	}

	// Three decimals, a trailing zero dropped: what a bind pose's numbers need, and no more.
	private static void Short(float value, String outText)
	{
		let rounded = (double)(int64)((double)value * 1000.0 + ((value < 0.0f) ? -0.5 : 0.5)) / 1000.0;
		outText.AppendF("{}", (rounded == 0.0) ? 0.0 : rounded);
	}

	private static void Describe(Float3 v, String outText)
	{
		Short(v.X, outText);
		outText.Append(", ");
		Short(v.Y, outText);
		outText.Append(", ");
		Short(v.Z, outText);
	}

	// === The preview ===

	private void FramePreview()
	{
		if (mPane != null)
			AnimationPreview.FrameBones(mPane, mWorld);
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		base.OnUpdate(host, dt);
		if (mPane == null)
			return;
		let preview = mPane.Viewport;
		let count = (mSkeleton != null) ? mSkeleton.BoneCount : 0;
		if (count <= 0)
			mPane.ShowEmpty("No bones", "This skeleton has none to show.");
		else
			mPane.Show();
		if ((preview != null) && preview.IsValid && (count > 0))
		{
			let draw = preview.SceneDebugDraw;
			draw.DrawGrid(.(0.0f, 0.0f, 0.0f), 4.0f, 8, .(0.25f, 0.25f, 0.28f, 1.0f));
			mBind.Count = count;
			for (int32 b < count)
				mBind[b] = mSkeleton.GetBone(b).LocalBindPose;
			AnimationPreview.DrawSkeletonBones(draw, mSkeleton, mBind, mWorld, .Identity(), mChosen);
			if (!mFramed)
				mFramed = AnimationPreview.FrameBones(mPane, mWorld);
		}
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
}
