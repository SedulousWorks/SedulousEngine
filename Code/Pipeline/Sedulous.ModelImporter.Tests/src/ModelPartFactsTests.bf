using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.ModelImporter;
using Sedulous.VFS;

namespace Sedulous.ModelImporter.Tests;

/// A part's facts in the import window: read from the model the importer's worker read, a part
/// matched to the model by the name its plan gives it; nothing without that read.
class ModelPartFactsTests
{
	private static StringView FactOf(List<ImportPartFact> facts, StringView label)
	{
		for (let fact in facts)
		{
			if (fact.Label == label)
				return fact.Value;
		}
		return default;
	}

	private static ImportPlanEntry EntryOf(ImportPlan plan, ImportResourceKind kind)
	{
		for (let entry in plan.Entries)
		{
			if (entry.Kind == kind)
				return entry;
		}
		return null;
	}

	[Test]
	public static void APartsFactsComeFromTheImportersReadOfTheFile()
	{
		let root = FindDataRoot(.. scope .());
		Test.Assert(!root.IsEmpty);
		let fox = DataPath(root, "Tests/Models/FoxNested/glTF/Fox.gltf", .. scope .());
		let importer = scope ModelFileImporter();
		let prepared = importer.PrepareOnWorker(fox);
		Test.Assert(prepared != null);
		defer delete prepared;
		let options = importer.CreateOptions();
		defer delete options;
		let plan = scope ImportPlan();
		importer.DescribeImport(fox, options, prepared, plan);
		let texture = EntryOf(plan, .Texture);
		let material = EntryOf(plan, .Material);
		let mesh = EntryOf(plan, .Mesh);
		let skeleton = EntryOf(plan, .Skeleton);
		let clip = EntryOf(plan, .AnimationClip);
		Test.Assert((texture != null) && (material != null) && (mesh != null) && (skeleton != null) && (clip != null));

		let facts = scope List<ImportPartFact>();
		defer { ClearAndDeleteItems!(facts); }
		importer.DescribePart(fox, options, prepared, texture, facts);
		Test.Assert(FactOf(facts, "Size") == "1024 × 1024");
		Test.Assert(FactOf(facts, "Used by") == scope String()..AppendF("{} (base colour)", material.SourceName));

		ClearAndDeleteItems!(facts);
		importer.DescribePart(fox, options, prepared, material, facts);
		Test.Assert(FactOf(facts, "Shading") == "PBR, metallic and roughness");
		Test.Assert(FactOf(facts, "Textures") == scope String()..AppendF("{} (base colour)", texture.SourceName));
		Test.Assert(FactOf(facts, "Used by") == scope String()..AppendF("{}, part 1", mesh.SourceName));

		ClearAndDeleteItems!(facts);
		importer.DescribePart(fox, options, prepared, mesh, facts);
		Test.Assert(FactOf(facts, "Skinned") == "Yes");
		Test.Assert(FactOf(facts, "Parts") == "1");
		Test.Assert(FactOf(facts, "Part 1") == scope String()..AppendF("{}, 576 triangles", material.SourceName));
		Test.Assert(FactOf(facts, "Triangles") == "576");

		ClearAndDeleteItems!(facts);
		importer.DescribePart(fox, options, prepared, skeleton, facts);
		Test.Assert(FactOf(facts, "Bones") == "24");

		ClearAndDeleteItems!(facts);
		importer.DescribePart(fox, options, prepared, clip, facts);
		Test.Assert(FactOf(facts, "Length").EndsWith(" s"));

		// Without the read there is nothing to say, rather than a second read of the file.
		ClearAndDeleteItems!(facts);
		importer.DescribePart(fox, options, null, mesh, facts);
		Test.Assert(facts.IsEmpty);
	}

	[Test]
	public static void ACountIsGroupedByThousands()
	{
		Test.Assert(ModelFileImporter.Grouped(0, .. scope .()) == "0");
		Test.Assert(ModelFileImporter.Grouped(576, .. scope .()) == "576");
		Test.Assert(ModelFileImporter.Grouped(4992, .. scope .()) == "4,992");
		Test.Assert(ModelFileImporter.Grouped(1234567, .. scope .()) == "1,234,567");
	}
}
