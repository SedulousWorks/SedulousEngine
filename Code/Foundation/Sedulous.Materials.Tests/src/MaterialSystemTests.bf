using System;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.RHI;

namespace Sedulous.Materials.Tests;

/// Inferring a bind group layout from a material's declarations, and building an instance's
/// GPU resources from it.
class MaterialSystemTests
{
	private static Material Lit()
	{
		let builder = scope MaterialBuilder("lit");
		return builder
			..Shader("forward")
			..Color("tint", .(1, 1, 1, 1))
			..Texture("albedoMap")
			..Sampler("samp")
			.Build();
	}

	/// The fallbacks an unbound texture slot needs, chosen by intent.
	[Test]
	public static void InitialisingCreatesTheNeutralFallbacks()
	{
		let fixture = scope MaterialSystemFixture();
		Test.Assert(fixture.System.Device == fixture.Device);
		Test.Assert(fixture.System.DefaultSampler != null);
		Test.Assert(fixture.System.WhiteTexture != null);
		Test.Assert(fixture.System.NormalTexture != null);
		Test.Assert(fixture.System.BlackTexture != null);
	}

	[Test]
	public static void TheLayoutIsInferredAndCached()
	{
		let fixture = scope MaterialSystemFixture();
		let material = Lit();
		defer delete material;

		let first = fixture.System.GetOrCreateLayout(material);
		let second = fixture.System.GetOrCreateLayout(material);
		Test.Assert(first != null);
		Test.Assert(first == second, "the same property shape gives the same layout");
	}

	/// Cached by CONTENT, so two materials that declare the same shape share one layout
	/// rather than each making its own.
	[Test]
	public static void TwoMaterialsWithTheSameShapeShareALayout()
	{
		let fixture = scope MaterialSystemFixture();

		let first = Lit();
		defer delete first;
		let secondBuilder = scope MaterialBuilder("other");
		let second = secondBuilder
			..Shader("different")
			..Color("colour", .(0, 0, 0, 1))
			..Texture("map")
			..Sampler("s")
			.Build();
		defer delete second;

		Test.Assert(fixture.System.GetOrCreateLayout(first)
			== fixture.System.GetOrCreateLayout(second), "same shape, same layout");
	}

	/// And a different shape gets a different one.
	[Test]
	public static void ADifferentShapeGetsADifferentLayout()
	{
		let fixture = scope MaterialSystemFixture();

		let lit = Lit();
		defer delete lit;
		let plainBuilder = scope MaterialBuilder("plain");
		let plain = plainBuilder..Shader("s")..Float("value").Build();
		defer delete plain;

		Test.Assert(fixture.System.GetOrCreateLayout(lit) != fixture.System.GetOrCreateLayout(plain));
	}

	/// A material declaring nothing has no layout to make. Not a failure: it binds nothing.
	[Test]
	public static void AMaterialDeclaringNothingHasNoLayout()
	{
		let fixture = scope MaterialSystemFixture();
		let builder = scope MaterialBuilder("empty");
		let material = builder.Shader("s").Build();
		defer delete material;

		Test.Assert(fixture.System.GetOrCreateLayout(material) == null);
	}

	[Test]
	public static void PreparingAnInstanceBuildsItsBindGroupAndClearsItsDirtyFlags()
	{
		let fixture = scope MaterialSystemFixture();
		let material = Lit();
		defer delete material;
		let layout = fixture.System.GetOrCreateLayout(material);

		let instance = scope MaterialInstance(material);
		Test.Assert(instance.IsUniformDirty, "nothing on the GPU yet");
		Test.Assert(instance.IsBindGroupDirty);

		let group = fixture.System.PrepareInstance(instance);
		Test.Assert(group != null);
		Test.Assert(instance.BindGroupLayout == layout);
		Test.Assert(!instance.IsUniformDirty);
		Test.Assert(!instance.IsBindGroupDirty);
		Test.Assert(fixture.System.GetBindGroup(instance) == group);
	}

	/// A renderer with its own fixed layout can still source its packed uniform data from
	/// here, which is what the buffer accessor is for.
	[Test]
	public static void TheUniformBufferCanBeTakenWithoutTheBindGroup()
	{
		let fixture = scope MaterialSystemFixture();
		let material = Lit();
		defer delete material;

		let instance = scope MaterialInstance(material);
		let buffer = fixture.System.EnsureUniformBuffer(instance);
		Test.Assert(buffer != null);
		Test.Assert(!instance.IsUniformDirty);
		Test.Assert(instance.IsBindGroupDirty, "only the buffer was asked for");
	}

	/// A material with no uniforms has no buffer to make, which is not a failure.
	[Test]
	public static void AMaterialWithNoUniformsHasNoBuffer()
	{
		let fixture = scope MaterialSystemFixture();
		let builder = scope MaterialBuilder("maps");
		let material = builder..Shader("s")..Texture("t")..Sampler("s0").Build();
		defer delete material;

		let instance = scope MaterialInstance(material);
		Test.Assert(fixture.System.EnsureUniformBuffer(instance) == null);
		// It still preps: the textures and sampler are the whole bind group.
		Test.Assert(fixture.System.PrepareInstance(instance) != null);
	}

	/// A sampler combination is cached, so a thousand materials wanting repeat and linear
	/// share one.
	[Test]
	public static void SamplersAreCachedByCombination()
	{
		let fixture = scope MaterialSystemFixture();

		let wrapping = fixture.System.GetOrCreateSampler(.Repeat, .Repeat);
		Test.Assert(wrapping != null);
		Test.Assert(fixture.System.GetOrCreateSampler(.Repeat, .Repeat) == wrapping);

		Test.Assert(fixture.System.GetOrCreateSampler(.ClampToEdge, .Repeat) != wrapping);
		Test.Assert(fixture.System.GetOrCreateSampler(.Repeat, .Repeat, .Nearest) != wrapping);
	}

	/// Detaching hands the resources over WITHOUT destroying them, so a caller can retire
	/// them once in flight frames are done. Both halves are needed together: freeing the
	/// bind group while its buffer is still bound is what a validating backend complains
	/// about on every hot reload.
	[Test]
	public static void DetachingHandsOverBothHalves()
	{
		let fixture = scope MaterialSystemFixture();
		let material = Lit();
		defer delete material;

		let instance = scope MaterialInstance(material);
		let group = fixture.System.PrepareInstance(instance);
		Test.Assert(group != null);

		Test.Assert(fixture.System.DetachBindGroup(instance) == group);
		Test.Assert(fixture.System.GetBindGroup(instance) == null, "the system let go of it");

		let buffer = fixture.System.DetachUniformBuffer(instance);
		Test.Assert(buffer != null);

		// Nothing left to detach twice.
		Test.Assert(fixture.System.DetachBindGroup(instance) == null);
		Test.Assert(fixture.System.DetachUniformBuffer(instance) == null);

		// Retiring BOTH, which is what the contract above says and what this test was only
		// half doing: the buffer came back owned by nobody and was dropped on the floor.
		// The group goes first, since freeing it while its buffer is still bound is the
		// complaint a validating backend makes.
		var doomedGroup = group;
		fixture.Device.DestroyBindGroup(ref doomedGroup);

		var doomedBuffer = buffer;
		fixture.Device.DestroyBuffer(ref doomedBuffer);
	}

	/// A replaced bind group is retired rather than freed, because an in flight frame may
	/// still be binding it. It survives the ticks until the ring has cycled past.
	[Test]
	public static void AReplacedBindGroupIsRetiredRatherThanFreed()
	{
		let fixture = scope MaterialSystemFixture();
		let material = Lit();
		defer delete material;

		let instance = scope MaterialInstance(material);
		let first = fixture.System.PrepareInstance(instance);
		Test.Assert(first != null);

		instance.SetTexture("albedoMap", fixture.System.WhiteTexture);
		let second = fixture.System.PrepareInstance(instance);
		Test.Assert(second != null);
		Test.Assert(second != first, "a new group, the old one retired");

		// Ticking past the ring frees it, and ticking again is harmless.
		for (int i = 0; i < 5; i++)
			fixture.System.TickRetired();
	}
}
