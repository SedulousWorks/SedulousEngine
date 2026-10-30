using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Generic.Tests;

/// The generic page from its markup (Data/Editor/AssetForm.gml) over the probe asset in a project:
/// its rows by their keys (an array's folded under its key, a blob read only, a guid a reference),
/// an edit and its undo, a change of shape, Save, and an asset that does not read.
class GenericPageTests
{
	/// The data root, found up from the working directory.
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

	/// Markup under the data root: a node with one reference, the caller's.
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

	/// A project holding the probe ("Probe", two weights) and an asset with nothing written
	/// ("Unread"), the page over either from its markup.
	class Bed
	{
		public String Dir = new .("scratch_generic_page_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public Instance Probe;
		public Instance Unread;

		public this()
		{
			// The probe read back by its type, as an asset type registers itself.
			let typeName = typeof(FormProbeAsset).GetFullName(.. scope .());
			GlobalSerializableRegistry.Register(TypeIdOf(typeName), () => (ISerializable)new FormProbeAsset());
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			let top = Project.SourceDb.RootGroup;
			Probe = top.CreateInstance("Probe", typeName);
			Unread = top.CreateInstance("Unread", typeName);
			Test.Assert((Probe != null) && (Unread != null));
			let asset = scope FormProbeAsset();
			asset.Weights.Add(1.0f);
			asset.Weights.Add(2.0f);
			Test.Assert(Probe.WriteObject(asset) case .Ok);
		}

		public ~this()
		{
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The page over `instance`; the caller deletes it.
		public GenericAssetEditorPage Open(Instance instance)
		{
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			return new GenericAssetEditorPage(Context, services, instance);
		}
	}

	static int FieldIndex(GenericAssetEditorPage page, StringView label)
	{
		let index = AssetForm.IndexOf(page.Fields, label);
		return (index >= 0) ? index : page.Fields.Count;
	}

	static StringView PathOf(GenericAssetEditorPage page, StringView label) => page.PathOf(FieldIndex(page, label));

	static bool Near(double a, double b) => Math.Abs(a - b) < 1e-5;

	[Test]
	public static void TheFieldsAsRowsByTheirKeysAnArraysFoldedUnderItsKeyABlobReadOnlyAGuidAReference()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Probe);
		defer delete page;
		Test.Assert(!page.LoadFailed);
		Test.Assert(page.Content != null);
		// The kit's bar: save, undo, redo, discard, cook, rebuild.
		Test.Assert((page.Bar != null) && (page.Bar.Count == 6));
		Test.Assert(page.Grid != null);
		Test.Assert(page.Bag != null);
		Test.Assert(page.Grid.Source == page.Bag);
		let kind = page.Content.FindElement("form-kind") as Sedulous.GUI.Label;
		Test.Assert(kind != null);
		Test.Assert(kind.Text == "Form Probe", "its display name, not its type's");
		Test.Assert(!page.Content.FindElement("form-state").Displayed);

		let bag = page.Bag;
		let friction = PathOf(page, "friction");
		Test.Assert(!friction.IsEmpty);
		Test.Assert(bag.FindInfo(friction).Kind == .Float);
		Test.Assert(bag.FindInfo(friction).ShownName == "Friction");
		Test.Assert(bag.FindInfo(friction).Description == "friction", "the key as saved");
		let group = PathOf(page, "group");
		Test.Assert(bag.FindInfo(group).Kind == .Integer);
		Test.Assert(bag.FindInfo(group).HasRange);
		Test.Assert(bag.FindInfo(PathOf(page, "enabled")).Kind == .Bool);
		Test.Assert(bag.FindInfo(PathOf(page, "note")).Kind == .String);

		// The guid: one reference row, its id as text.
		let mesh = PathOf(page, "mesh");
		Test.Assert(bag.FindInfo(mesh).Kind == .Reference);
		var meshValue = bag.GetValue(mesh, 0);
		defer meshValue.Dispose();
		Test.Assert(!meshValue.AsString.IsEmpty);

		// The blob: its size, read only.
		let blob = PathOf(page, "blob");
		Test.Assert(bag.FindInfo(blob).ReadOnly);
		var blobValue = bag.GetValue(blob, 0);
		defer blobValue.Dispose();
		Test.Assert(blobValue.AsString == "4 bytes");

		// The array: its elements under one group named by its key, folded; its count no row, nor
		// the version envelope's entries.
		let first = PathOf(page, "weights[0]");
		let second = PathOf(page, "weights[1]");
		let parent = ParentPropertyPath(first);
		Test.Assert(!parent.IsEmpty);
		Test.Assert(ParentPropertyPath(second) == parent);
		Test.Assert(bag.FindInfo(parent).Kind == .Group);
		Test.Assert(bag.FindInfo(parent).ShownName == "Weights");
		Test.Assert(!page.Grid.IsOpen(parent));
		Test.Assert(page.PathOf(FieldIndex(page, "weights")).IsEmpty);
		Test.Assert(page.PathOf(FieldIndex(page, "version")).IsEmpty, "the envelope's: structural");
		page.OnClose();
	}

	[Test]
	public static void AnEditIsOneUndoStepAFlippedBranchBuildsTheRowsAgainAndSaveWritesTheAsset()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Probe);
		defer delete page;
		let friction = scope String(PathOf(page, "friction"));
		page.Edit(friction, .(0.25));
		Test.Assert(page.IsDirty);
		Test.Assert(Near(page.Fields[FieldIndex(page, "friction")].FloatValue, 0.25));
		page.Commands.Undo();
		page.Refresh();
		Test.Assert(Near(page.Fields[FieldIndex(page, "friction")].FloatValue, 0.5));
		var shown = page.Bag.GetValue(friction, 0);
		Test.Assert(Near(shown.AsFloat, 0.5));
		shown.Dispose();
		page.Commands.Redo();
		page.Refresh();
		shown = page.Bag.GetValue(friction, 0);
		Test.Assert(Near(shown.AsFloat, 0.25));
		shown.Dispose();

		// A guid that is not one leaves the field as it was.
		let mesh = scope String(PathOf(page, "mesh"));
		var before = page.Bag.GetValue(mesh, 0);
		defer before.Dispose();
		page.Edit(mesh, .("not a guid"));
		page.Refresh();
		var after = page.Bag.GetValue(mesh, 0);
		defer after.Dispose();
		Test.Assert(after.AsString == before.AsString);

		// hasExtra on: Serialize writes `extra` now, so the rows are built again with it.
		Test.Assert(page.PathOf(FieldIndex(page, "extra")).IsEmpty);
		page.Edit(scope String(PathOf(page, "hasExtra")), .(true));
		page.Refresh();
		Test.Assert(!PathOf(page, "extra").IsEmpty);
		Test.Assert(page.Grid.Source == page.Bag);

		Test.Assert(page.Save() case .Ok);
		Test.Assert(!page.IsDirty);
		let saved = bed.Probe.ReadObject();
		defer delete saved;
		let probe = saved as FormProbeAsset;
		Test.Assert(probe != null);
		Test.Assert(Near(probe.Friction, 0.25));
		Test.Assert(probe.HasExtra);
		page.OnClose();
	}

	[Test]
	public static void AnAssetThatDoesNotReadSaysSoInPlaceOfTheRows()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Unread);
		defer delete page;
		Test.Assert(page.LoadFailed);
		Test.Assert(page.Content != null);
		Test.Assert(page.Content.FindElement("form-state").Displayed);
		Test.Assert(!page.Grid.Displayed);
		Test.Assert(page.Fields.IsEmpty);
		Test.Assert(page.Save() case .Err);
		page.OnClose();
	}
}
