using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Toolkit.Tests.ToolkitFixtures;

namespace Sedulous.GUI.Toolkit.Tests;

/// Counts what a source tells it.
class CountingSourceClient : IPropertySourceClient
{
	public int Properties = 0;
	public int Values = 0;

	public void OnPropertiesChanged()
	{
		++Properties;
	}

	public void OnValuesChanged()
	{
		++Values;
	}
}

/// A bag's commits, kept (each value its own copy).
class KeptCommits
{
	public List<Sedulous.GUI.PropertyBag.Commit> Commits = new .() ~ DeleteContainerAndItems!(_);

	public void Keep(Sedulous.GUI.PropertyBag.Commit commit)
	{
		let copy = new Sedulous.GUI.PropertyBag.Commit();
		copy.Path.Set(commit.Path);
		for (let value in commit.Before)
			copy.Before.Add(value.Copy());
		for (let value in commit.After)
			copy.After.Add(value.Copy());
		Commits.Add(copy);
	}
}

/// The property source: properties by path, each object's value and the mixed state read over them,
/// flags mixed per bit, and an edit as a gesture (previewed on every object, committed once from the
/// originals, or cancelled back to them).
class PropertySourceTests
{
	[Test]
	public static void PathsJoinAndPartAndABagListsThePropertiesUnderAPath()
	{
		Test.Assert(JoinPropertyPath("", "position", .. scope String()) == "position");
		Test.Assert(JoinPropertyPath("position", "x", .. scope String()) == "position.x");
		Test.Assert(ParentPropertyPath("position.x") == "position");
		Test.Assert(ParentPropertyPath("position").Length == 0);

		let bag = scope Sedulous.GUI.PropertyBag();
		bag.Add("name", .String, Sedulous.GUI.Variant("Lamp"));
		bag.Add("position", .Group);
		bag.Add("position.x", .Float, Sedulous.GUI.Variant(1.0));
		bag.Add("position.y", .Float, Sedulous.GUI.Variant(2.0)).DisplayName.Set("Y");

		let top = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(top); }
		bag.GetProperties("", top);
		Test.Assert(top.Count == 2);
		Test.Assert(top[0].Name == "name");
		Test.Assert(top[1].Kind == .Group);
		let parts = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(parts); }
		bag.GetProperties("position", parts);
		Test.Assert(parts.Count == 2);
		Test.Assert(parts[0].Name == "x");
		Test.Assert(parts[0].ShownName == "x");
		Test.Assert(parts[1].ShownName == "Y");
		CheckNear(FloatOf(bag, "position.y", 0), 2.0);
	}

	[Test]
	public static void AValueOverSeveralObjectsIsMixedWhenAnyDiffersFlagsPerBit()
	{
		let bag = scope Sedulous.GUI.PropertyBag(3);
		bag.Add("speed", .Float, Sedulous.GUI.Variant(1.0));
		bag.Add("layers", .Flags, Sedulous.GUI.Variant((int64)0b0101));
		Test.Assert(!IsMixed(bag, "speed", .Float));

		bag.SetValue("speed", 2, Sedulous.GUI.Variant(3.0));
		var speed = ReadPropertyValue(bag, "speed", .Float);
		defer speed.Dispose();
		Test.Assert(speed.Mixed);
		CheckNear(speed.Value.AsFloat, 1.0); // the first object's

		bag.SetValue("layers", 1, Sedulous.GUI.Variant((int64)0b0111));
		var layers = ReadPropertyValue(bag, "layers", .Flags);
		defer layers.Dispose();
		Test.Assert(layers.Mixed);
		Test.Assert(layers.MixedBits == 0b0010);

		// A flag set on all of them leaves the bit they differ in as each had it.
		bag.BeginEdit("layers");
		bag.CommitEdit("layers", PropertyWrite(Sedulous.GUI.Variant((int64)0b1000), (uint64)0b1000));
		Test.Assert(IntOf(bag, "layers", 0) == 0b1101);
		Test.Assert(IntOf(bag, "layers", 1) == 0b1111);
		var after = ReadPropertyValue(bag, "layers", .Flags);
		defer after.Dispose();
		Test.Assert(after.MixedBits == 0b0010);
	}

	[Test]
	public static void AnEditPreviewsOnEveryObjectCommitsOnceFromTheOriginalsOrCancelsBack()
	{
		let bag = scope Sedulous.GUI.PropertyBag(2);
		let client = scope CountingSourceClient();
		bag.Client = client;
		bag.Add("size", .Float, Sedulous.GUI.Variant(1.0));
		Test.Assert(client.Properties == 1);
		bag.SetValue("size", 1, Sedulous.GUI.Variant(4.0));
		let kept = scope KeptCommits();
		bag.SetOnCommit(new (commit) => { kept.Keep(commit); });
		let commits = kept.Commits;

		bag.BeginEdit("size");
		Test.Assert(bag.OpenEdits == 1);
		bag.PreviewEdit("size", PropertyWrite(Sedulous.GUI.Variant(2.0)));
		bag.PreviewEdit("size", PropertyWrite(Sedulous.GUI.Variant(3.0)));
		CheckNear(FloatOf(bag, "size", 0), 3.0);
		CheckNear(FloatOf(bag, "size", 1), 3.0);
		Test.Assert(commits.IsEmpty); // previews are not edits of their own
		bag.CommitEdit("size", PropertyWrite(Sedulous.GUI.Variant(5.0)));
		Test.Assert(bag.OpenEdits == 0);
		Test.Assert(commits.Count == 1);
		CheckNear(commits[0].Before[0].AsFloat, 1.0); // from before the previews
		CheckNear(commits[0].Before[1].AsFloat, 4.0);
		CheckNear(commits[0].After[1].AsFloat, 5.0);

		bag.BeginEdit("size");
		bag.PreviewEdit("size", PropertyWrite(Sedulous.GUI.Variant(9.0)));
		let before = client.Values;
		bag.CancelEdit("size");
		Test.Assert(client.Values == before + 1);
		CheckNear(FloatOf(bag, "size", 0), 5.0);
		Test.Assert(commits.Count == 1);

		// Read only: nothing written.
		bag.FindInfo("size").ReadOnly = true;
		bag.BeginEdit("size");
		bag.PreviewEdit("size", PropertyWrite(Sedulous.GUI.Variant(7.0)));
		bag.CommitEdit("size", PropertyWrite(Sedulous.GUI.Variant(7.0)));
		CheckNear(FloatOf(bag, "size", 1), 5.0);
		Test.Assert(bag.OpenEdits == 0);
		bag.Client = null;
	}

	[Test]
	public static void AListsElementsAreItsChildrenByIndexChangedInEachObjectByOneCall()
	{
		let bag = scope Sedulous.GUI.PropertyBag(2);
		let info = bag.AddList("tags", .String, Sedulous.GUI.Variant("new"), 2);
		info.MaxCount = 3;
		bag.SetValue("tags.0", 0, Sedulous.GUI.Variant("a"));
		bag.SetValue("tags.1", 0, Sedulous.GUI.Variant("b"));
		Test.Assert(IntOf(bag, "tags", 0) == 2); // a list's value is its count
		let elements = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(elements); }
		bag.GetProperties("tags", elements);
		Test.Assert(elements.Count == 2);
		Test.Assert(elements[1].Name == "1");
		Test.Assert(elements[1].Kind == .String);

		// An element edits as any property does.
		bag.BeginEdit("tags.1");
		bag.CommitEdit("tags.1", PropertyWrite(Sedulous.GUI.Variant("c")));
		Test.Assert(TextIs(bag, "tags.1", 1, "c"));

		let move = scope ListEdit();
		move.Kind = .Move;
		move.Index = 1;
		move.To = 0;
		Test.Assert(bag.EditList("tags", move));
		Test.Assert(TextIs(bag, "tags.0", 0, "c"));
		let insert = scope ListEdit();
		insert.Kind = .Insert;
		insert.Index = 9; // past the end: at the end
		Test.Assert(bag.EditList("tags", insert));
		Test.Assert(TextIs(bag, "tags.2", 1, "new"));
		Test.Assert(!bag.EditList("tags", insert)); // at its most
		let remove = scope ListEdit();
		remove.Kind = .Remove;
		remove.Index = 0;
		Test.Assert(bag.EditList("tags", remove));
		Test.Assert(bag.ElementCount("tags", 0) == 2);

		info.ListOps = PropertyListAdd; // may only add
		Test.Assert(!bag.EditList("tags", remove));
	}

	[Test]
	public static void EachObjectsOwnDefaultAndARevertOfAPathAndWhatIsUnderIt()
	{
		let bag = scope Sedulous.GUI.PropertyBag(2);
		bag.Add("offset", .Group);
		bag.Add("offset.x", .Float, Sedulous.GUI.Variant(5.0));
		bag.Add("offset.y", .Float, Sedulous.GUI.Variant(6.0));
		bag.SetDefault("offset.x", Sedulous.GUI.Variant(0.0));
		bag.SetDefault("offset.y", Sedulous.GUI.Variant(1.0), 0); // the objects' defaults differ (two prefabs)
		bag.SetDefault("offset.y", Sedulous.GUI.Variant(2.0), 1);
		CheckNear(DefaultFloatOf(bag, "offset.y", 1), 2.0);
		Test.Assert(HasNoDefault(bag, "offset", 0));
		int reverts = 0;
		bag.SetOnReverted(new [&] (path) => { ++reverts; });

		Test.Assert(bag.Revert("offset"));
		CheckNear(FloatOf(bag, "offset.x", 1), 0.0);
		CheckNear(FloatOf(bag, "offset.y", 0), 1.0);
		CheckNear(FloatOf(bag, "offset.y", 1), 2.0);
		Test.Assert(reverts == 1);
		Test.Assert(!bag.Revert("offset")); // nothing left to put back
		Test.Assert(reverts == 1);
		Test.Assert(bag.GetRevertText("offset", .. scope String()) == "Revert to default");
	}

	// What no Raptor test covers: copying a value as its text, pasting a number in, a paste refused
	// with its reason, and a flags write applied to an old value.
	[Test]
	public static void ABagCopiesAValueAsTextPastesOneBackAndRefusesTextOfAnotherKind()
	{
		let bag = scope Sedulous.GUI.PropertyBag(2);
		bag.Add("count", .Integer, Sedulous.GUI.Variant((int64)3));
		Test.Assert(bag.CopyValue("count", .. scope String()) == "3");
		let reason = scope String();
		Test.Assert(bag.PasteValue("count", " 12 ", reason));
		Test.Assert(IntOf(bag, "count", 1) == 12);
		Test.Assert(!bag.PasteValue("count", "twelve", reason));
		Test.Assert(reason == "\"twelve\" is no integer");

		var bits = ApplyPropertyWrite(Sedulous.GUI.Variant((int64)0b1100), PropertyWrite(Sedulous.GUI.Variant((int64)0b0011), (uint64)0b0110));
		Test.Assert(bits.AsInt == 0b1010);
		bits.Dispose();
	}
}
