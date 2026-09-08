using System;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.RHI;

namespace Sedulous.Materials.Tests;

/// Per use overrides, and the dirty notification that keeps the per frame pass
/// proportional to what changed.
class MaterialInstanceTests
{
	private static Material Lit()
	{
		let builder = scope MaterialBuilder("lit");
		return builder
			..Shader("forward")
			..Float("roughness", 0.5f)
			..Texture("albedoMap")
			.Build();
	}

	private static float FirstFloat(Span<uint8> data) => *(float*)data.Ptr;

	/// An instance starts as a copy of the material's defaults, so one that overrides
	/// nothing still draws what the material says.
	[Test]
	public static void AnInstanceStartsFromTheMaterialsDefaults()
	{
		let material = Lit();
		defer delete material;
		let instance = scope MaterialInstance(material);

		Test.Assert(instance.Material == material);
		Test.Assert(FirstFloat(instance.UniformData) == 0.5f);
		Test.Assert(!instance.IsOverridden(0));
	}

	[Test]
	public static void AnOverrideNotifiesOnceAndTheDrainRePreps()
	{
		let fixture = scope MaterialSystemFixture();
		let material = Lit();
		defer delete material;

		let instance = scope MaterialInstance(material);
		Test.Assert(fixture.System.PrepareInstance(instance) != null, "registers the sink");

		instance.SetFloat("roughness", 0.9f);
		Test.Assert(instance.IsUniformDirty);
		// A second set while already queued must NOT enqueue it again.
		instance.SetFloat("roughness", 0.8f);

		fixture.System.PrepareDirtyInstances();
		Test.Assert(!instance.IsUniformDirty, "drained and re-prepped");

		// One float, rounded to sixteen.
		Test.Assert(instance.UniformData.Length == 16);
		Test.Assert(FirstFloat(instance.UniformData) == 0.8f, "the override, not the default");
		Test.Assert(instance.IsOverridden(0));
	}

	[Test]
	public static void ResettingRestoresTheMaterialsDefault()
	{
		let fixture = scope MaterialSystemFixture();
		let material = Lit();
		defer delete material;

		let instance = scope MaterialInstance(material);
		fixture.System.PrepareInstance(instance);

		instance.SetFloat("roughness", 0.9f);
		fixture.System.PrepareDirtyInstances();
		Test.Assert(FirstFloat(instance.UniformData) == 0.9f);

		instance.ResetProperty("roughness");
		fixture.System.PrepareDirtyInstances();
		Test.Assert(FirstFloat(instance.UniformData) == 0.5f);
		Test.Assert(!instance.IsOverridden(0), "and the override is gone, not merely equal");
	}

	/// A texture override reads back as the effective value, and resetting falls through
	/// to the material's default again.
	[Test]
	public static void ATextureOverrideWinsUntilItIsReset()
	{
		let fixture = scope MaterialSystemFixture();
		let material = Lit();
		defer delete material;
		material.SetDefaultTexture("albedoMap", fixture.System.WhiteTexture);

		let instance = scope MaterialInstance(material);
		let albedo = material.GetPropertyIndex("albedoMap");
		Test.Assert(instance.GetTexture(albedo) == fixture.System.WhiteTexture);

		instance.SetTexture("albedoMap", fixture.System.BlackTexture);
		Test.Assert(instance.GetTexture(albedo) == fixture.System.BlackTexture);
		Test.Assert(instance.IsBindGroupDirty);

		instance.ResetProperty("albedoMap");
		Test.Assert(instance.GetTexture(albedo) == fixture.System.WhiteTexture);
	}

	/// Setting an unknown property, or one of the wrong kind, does nothing. Importers walk
	/// whatever a source file declared, and a property this shader does not have is the
	/// source being generous rather than an error.
	[Test]
	public static void SettingSomethingTheMaterialHasNotIsIgnored()
	{
		let material = Lit();
		defer delete material;
		let instance = scope MaterialInstance(material);

		instance.SetFloat("missing", 1.0f);
		instance.SetTexture("missing", null);
		instance.SetTexture("roughness", null);
		instance.SetSampler("albedoMap", null);
		instance.ResetProperty("missing");

		Test.Assert(FirstFloat(instance.UniformData) == 0.5f, "nothing was touched");
		Test.Assert(!instance.IsOverridden(0));
	}

	/// A set of the WRONG SIZE is refused rather than writing past the property: a float2
	/// into a float slot would overwrite whatever follows it.
	[Test]
	public static void AnOversizedWriteIsRefused()
	{
		// Four tightly packed scalars, so a four component write into the LAST one runs
		// twelve bytes past the end of the buffer.
		let builder = scope MaterialBuilder("packed");
		let packed = builder..Shader("s")..Float("a")..Float("b")..Float("c")..Float("d").Build();
		defer delete packed;
		let tight = scope MaterialInstance(packed);

		tight.SetFloat4("d", .(1, 2, 3, 4));
		Test.Assert(!tight.IsOverridden(3), "twelve bytes past the end of a four byte slot");
	}

	/// Dropping an instance takes its GPU resources with it, and takes it out of the dirty
	/// list so the next drain does not walk a dead reference.
	[Test]
	public static void DroppingAnInstanceReleasesItFromTheSystem()
	{
		let fixture = scope MaterialSystemFixture();
		let material = Lit();
		defer delete material;

		{
			let instance = scope MaterialInstance(material);
			Test.Assert(fixture.System.PrepareInstance(instance) != null);
			// Dirty and queued when it dies, which is the case that would otherwise leave
			// a dangling entry behind.
			instance.SetFloat("roughness", 0.1f);
			Test.Assert(instance.IsInDirtyList);
		}

		// The drain must survive the instance having gone.
		fixture.System.PrepareDirtyInstances();
	}

	/// The mask is what makes "is this overridden" a shift and a test rather than a search.
	[Test]
	public static void TheOverrideMaskSpansBothWords()
	{
		var mask = PropertyOverrideMask();
		Test.Assert(!mask.HasAny);

		mask.Set(0);
		mask.Set(63);
		mask.Set(64);
		mask.Set(127);
		Test.Assert(mask.HasAny);
		Test.Assert(mask.IsSet(0) && mask.IsSet(63) && mask.IsSet(64) && mask.IsSet(127));
		Test.Assert(!mask.IsSet(1) && !mask.IsSet(62) && !mask.IsSet(65));

		mask.Clear(63);
		Test.Assert(!mask.IsSet(63));
		Test.Assert(mask.IsSet(64), "clearing the last bit of the low word left the high one");

		// Past the end reads as not overridden, so it falls back to the material default.
		mask.Set(128);
		Test.Assert(!mask.IsSet(128));
		Test.Assert(!mask.IsSet(-1));

		mask.Reset();
		Test.Assert(!mask.HasAny);
	}
}
