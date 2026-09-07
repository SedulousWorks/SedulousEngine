using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Shaders;

namespace Sedulous.Shaders.Tests;

/// The cooked pack: what a shipped build reads instead of compiling.
class CookedShaderPackTests
{
	/// Add, serialize, reload, look up. The round trip is what a shipped build depends on,
	/// so it is checked end to end rather than only in memory.
	[Test]
	public static void APackSerializesAndReloads()
	{
		uint8[4] vertexSpirv = .(1, 2, 3, 4);
		uint8[4] fragmentWgsl = .((uint8)'w', (uint8)'g', (uint8)'s', (uint8)'l');

		let pack = scope CookedShaderPack();
		pack.Add("forward", .Vertex, .None, .SpirV, vertexSpirv);
		pack.Add("forward", .Fragment, .GBuffer, .Wgsl, fragmentWgsl);
		pack.AddDeclaredMask("forward", .Fragment, .AlphaTest | .GBuffer);
		Test.Assert(pack.Count == 2);

		let buffer = scope MemoryStream();
		Test.Assert(pack.Write(buffer) case .Ok);

		Test.Assert(buffer.Seek(0, .Begin) == 0);
		let loaded = scope CookedShaderPack();
		Test.Assert(loaded.Read(buffer) case .Ok, "the serialized pack reloads");
		Test.Assert(loaded.Count == 2);

		Test.Assert(loaded.Find("forward", .Vertex, .None, .SpirV) case .Ok(let vertexBlob));
		Test.Assert(vertexBlob.Length == 4);
		Test.Assert(vertexBlob[0] == 1);

		Test.Assert(loaded.Find("forward", .Fragment, .GBuffer, .Wgsl) case .Ok(let fragmentBlob));
		Test.Assert(fragmentBlob[0] == (uint8)'w');

		// A wrong variant, format or stage is a MISS, which at runtime is a cook coverage
		// bug rather than something to paper over with a fallback.
		Test.Assert(loaded.Find("forward", .Fragment, .None, .Wgsl) case .Err);
		Test.Assert(loaded.Find("forward", .Fragment, .GBuffer, .SpirV) case .Err);
		Test.Assert(loaded.Find("nope", .Vertex, .None, .SpirV) case .Err);

		let names = scope List<String>();
		loaded.CollectNames(names);
		defer { ClearAndDeleteItems!(names); }
		Test.Assert(names.Count == 1, "one distinct name");
		Test.Assert(names[0] == "forward");

		// The declared mask has to survive, because it is what a shipped runtime
		// canonicalizes with.
		Test.Assert(loaded.DeclaredMask("forward", .Fragment) == (ShaderFlags.AlphaTest
			| ShaderFlags.GBuffer));
		Test.Assert(loaded.DeclaredMask("forward", .Vertex) == .None,
			"a stage that declared none reports none");
	}

	/// Re-adding a variant overwrites in place. A pushed duplicate would sit orphaned in the
	/// entry list and be serialized, and counted, twice.
	[Test]
	public static void ReAddingAVariantOverwritesInPlace()
	{
		uint8[1] one = .(1);
		uint8[1] two = .(2);

		let pack = scope CookedShaderPack();
		pack.Add("dup", .Vertex, .None, .SpirV, one);
		pack.Add("dup", .Vertex, .None, .SpirV, two);

		Test.Assert(pack.Count == 1, "the second add replaced the first");
		Test.Assert(pack.Find("dup", .Vertex, .None, .SpirV) case .Ok(let blob));
		Test.Assert(blob[0] == 2, "and the newer blob is what is stored");
	}

	/// Every variant of a name and stage can be listed, which is what the runtime miss path
	/// reports so a coverage gap shows its shape.
	[Test]
	public static void EveryVariantOfAStageCanBeListed()
	{
		uint8[1] blob = .(7);
		let pack = scope CookedShaderPack();
		pack.Add("lit", .Fragment, .None, .SpirV, blob);
		pack.Add("lit", .Fragment, .AlphaTest, .SpirV, blob);
		pack.Add("lit", .Fragment, .None, .Dxil, blob);
		// A different stage must not be swept up.
		pack.Add("lit", .Vertex, .None, .SpirV, blob);

		int seen = 0;
		bool sawDxil = false;
		pack.ForEachVariant(ShaderFlagNames.ShaderNameHash("lit"), .Fragment,
			scope [&] (flags, format) =>
			{
				seen++;
				if (format == .Dxil)
					sawDxil = true;
			});

		Test.Assert(seen == 3, "the three fragment variants, and not the vertex one");
		Test.Assert(sawDxil, "including the other format");
	}

	/// A corrupt count must fail cleanly rather than attempting an enormous allocation on a
	/// garbage length.
	[Test]
	public static void ACorruptCountFailsCleanly()
	{
		uint8[1] blob = .(9);
		let valid = scope CookedShaderPack();
		valid.Add("x", .Vertex, .None, .SpirV, blob);

		let buffer = scope MemoryStream();
		Test.Assert(valid.Write(buffer) case .Ok);

		// The name count sits at byte 8, after the magic and the version.
		Test.Assert(buffer.Seek(8, .Begin) == 8);
		uint32 huge = 0x7FFFFFFF;
		Test.Assert(buffer.Write(.((uint8*)&huge, sizeof(uint32))) == sizeof(uint32));
		Test.Assert(buffer.Seek(0, .Begin) == 0);

		let loaded = scope CookedShaderPack();
		Test.Assert(loaded.Read(buffer) case .Err, "a count past the stream's end is refused");
	}

	/// A stream cut short is refused rather than read into whatever follows.
	[Test]
	public static void ATruncatedStreamFailsCleanly()
	{
		uint8[1] blob = .(9);
		let valid = scope CookedShaderPack();
		valid.Add("x", .Vertex, .None, .SpirV, blob);

		let full = scope MemoryStream();
		Test.Assert(valid.Write(full) case .Ok);
		Test.Assert(full.Seek(0, .Begin) == 0);

		uint8[16] head = default;
		Test.Assert(full.Read(head) == 16);

		let truncated = scope MemoryStream();
		Test.Assert(truncated.Write(head) == 16);
		Test.Assert(truncated.Seek(0, .Begin) == 0);

		let loaded = scope CookedShaderPack();
		Test.Assert(loaded.Read(truncated) case .Err);
	}

	/// A wrong magic or version is refused: a pack from another build is not silently read
	/// as though its layout still matched.
	[Test]
	public static void AForeignPackIsRefused()
	{
		let buffer = scope MemoryStream();
		uint32 wrongMagic = 0xDEADBEEF;
		uint32 version = 2;
		buffer.Write(.((uint8*)&wrongMagic, sizeof(uint32)));
		buffer.Write(.((uint8*)&version, sizeof(uint32)));
		Test.Assert(buffer.Seek(0, .Begin) == 0);

		let loaded = scope CookedShaderPack();
		Test.Assert(loaded.Read(buffer) case .Err);
	}

	/// Reading into a pack that already holds entries REPLACES them, so a reload does not
	/// leave the previous contents behind.
	[Test]
	public static void ReadingReplacesWhatWasThere()
	{
		uint8[1] blob = .(3);
		let source = scope CookedShaderPack();
		source.Add("fresh", .Vertex, .None, .SpirV, blob);

		let buffer = scope MemoryStream();
		Test.Assert(source.Write(buffer) case .Ok);
		Test.Assert(buffer.Seek(0, .Begin) == 0);

		let target = scope CookedShaderPack();
		target.Add("stale", .Compute, .Emissive, .Dxil, blob);
		Test.Assert(target.Read(buffer) case .Ok);

		Test.Assert(target.Count == 1);
		Test.Assert(target.Find("fresh", .Vertex, .None, .SpirV) case .Ok);
		Test.Assert(target.Find("stale", .Compute, .Emissive, .Dxil) case .Err,
			"the previous contents are gone");
	}
}
