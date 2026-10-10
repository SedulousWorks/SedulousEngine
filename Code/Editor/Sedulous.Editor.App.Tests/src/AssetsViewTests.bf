using System;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Pipeline.Core;
using Sedulous.UI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The Assets panel's group tree.
static class AssetsViewTests
{
	/// Each folder's name is indented by the tree's own inset for its depth.
	///
	/// The rows set a literal (depth + 1) * 18 while the tree draws each chevron in its
	/// IndentWidth column (20), so a name fell 2 px further behind its chevron at every level
	/// and the gap before the chevrons shrank with depth.
	[Test]
	public static void EachFolderIsIndentedByTheTreesInsetForItsDepth()
	{
		let dir = "scratch_assets_view_tree";
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "Tree") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;

		// Content/A/B/C: a folder at every depth from nought to three.
		let root = project.SourceDb.RootGroup;
		let a = root.CreateGroup("A");
		let b = a.CreateGroup("B");
		let c = b.CreateGroup("C");

		let context = scope EditorContext();
		context.SetProject(project);
		let builders = scope BuilderRegistry();
		let cook = scope EditorCookService();
		cook.Initialize(project, builders);
		defer cook.Shutdown();

		let view = new AssetsView(context, cook);
		defer view.ReleaseRef();
		let tree = view.GroupTree;
		let adapter = tree.TreeAdapter as GroupTreeAdapter;
		Test.Assert(adapter != null);

		Group[4] groups = .(root, a, b, c);
		for (int32 depth < 4)
		{
			var nodeId = (int32)-1;
			for (int32 i < (int32)adapter.Count)
			{
				if (adapter.GroupAt(i) === groups[depth])
					nodeId = i;
			}
			Test.Assert(nodeId >= 0, "the folder is in the tree");
			Test.Assert(adapter.GetDepth(nodeId) == depth);

			let row = adapter.CreateView(0);
			defer row.ReleaseRef();
			adapter.BindView(row, nodeId, depth, true);
			let label = row as AssetNameLabel;
			Test.Assert(label != null);
			Test.Assert(label.TextOffsetX.Value == tree.ContentInset(depth),
				scope $"depth {depth}: text at {label.TextOffsetX.Value}, inset {tree.ContentInset(depth)}");
		}
	}
}
