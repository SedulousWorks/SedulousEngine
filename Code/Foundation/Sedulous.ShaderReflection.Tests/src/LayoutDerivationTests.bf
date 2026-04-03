namespace Sedulous.ShaderReflection.Tests;

using System;
using System.Collections;
using Sedulous.RHI;

/// Phase 6: Layout derivation tests.
class LayoutDerivationTests
{
	[Test]
	public static void TestMergeVertexAndFragmentBindings()
	{
		// Use mock shaders to test merge logic (real SPIR-V binding layout is DXC-version-dependent)
		let vs = new ReflectedShader();
		vs.Stage = .Vertex;
		vs.Bindings.Add(.() { Set = 0, Binding = 0, Type = .UniformBuffer, Stages = .Vertex, Count = 1, Name = "Scene" });
		vs.Bindings.Add(.() { Set = 1, Binding = 0, Type = .SampledTexture, Stages = .Vertex, Count = 1, Name = "Tex" });

		let ps = new ReflectedShader();
		ps.Stage = .Fragment;
		ps.Bindings.Add(.() { Set = 0, Binding = 0, Type = .UniformBuffer, Stages = .Fragment, Count = 1, Name = "Scene" });
		ps.Bindings.Add(.() { Set = 1, Binding = 0, Type = .SampledTexture, Stages = .Fragment, Count = 1, Name = "Tex" });
		ps.Bindings.Add(.() { Set = 1, Binding = 1, Type = .Sampler, Stages = .Fragment, Count = 1, Name = "Samp" });

		defer { delete vs; delete ps; }

		ReflectedShader[2] shaders = .(vs, ps);
		let layouts = new List<List<BindGroupLayoutEntry>>();
		defer { DeleteContainerAndItems!(layouts); }

		let result = ReflectionUtils.DeriveBindGroupLayouts(shaders, layouts);
		Test.Assert(result case .Ok, "DeriveBindGroupLayouts should succeed");

		Test.Assert(layouts.Count == 2, scope String()..AppendF("Expected 2 sets, got {}", layouts.Count));

		// Set 0: 1 merged UB with Vertex|Fragment
		Test.Assert(layouts[0].Count == 1, "Set 0 should have 1 merged entry");
		Test.Assert(layouts[0][0].Visibility == (.Vertex | .Fragment), "UB visibility should be merged");

		// Set 1: texture (merged) + sampler (PS only) = 2 entries
		Test.Assert(layouts[1].Count == 2, scope String()..AppendF("Set 1 should have 2 entries, got {}", layouts[1].Count));
	}

	[Test]
	public static void TestMergedStageVisibility()
	{
		// Create two mock reflected shaders that share a binding
		let vsShader = new ReflectedShader();
		vsShader.Stage = .Vertex;
		vsShader.Bindings.Add(.()
		{
			Set = 0, Binding = 0,
			Type = .UniformBuffer,
			Stages = .Vertex,
			Count = 1,
			Name = "SharedUB"
		});

		let psShader = new ReflectedShader();
		psShader.Stage = .Fragment;
		psShader.Bindings.Add(.()
		{
			Set = 0, Binding = 0,
			Type = .UniformBuffer,
			Stages = .Fragment,
			Count = 1,
			Name = "SharedUB"
		});

		defer { delete vsShader; delete psShader; }

		ReflectedShader[2] shaders = .(vsShader, psShader);
		let layouts = new List<List<BindGroupLayoutEntry>>();
		defer { DeleteContainerAndItems!(layouts); }

		let result = ReflectionUtils.DeriveBindGroupLayouts(shaders, layouts);
		Test.Assert(result case .Ok, "Should succeed");
		Test.Assert(layouts.Count == 1, "Should have 1 set");
		Test.Assert(layouts[0].Count == 1, "Set 0 should have 1 merged entry");

		let entry = layouts[0][0];
		Test.Assert(entry.Visibility == (.Vertex | .Fragment),
			scope String()..AppendF("Merged visibility should be Vertex|Fragment, got {}", entry.Visibility));
	}

	[Test]
	public static void TestBindingConflictDetection()
	{
		let shader1 = new ReflectedShader();
		shader1.Stage = .Vertex;
		shader1.Bindings.Add(.()
		{
			Set = 0, Binding = 0,
			Type = .UniformBuffer,
			Stages = .Vertex,
			Count = 1
		});

		let shader2 = new ReflectedShader();
		shader2.Stage = .Fragment;
		shader2.Bindings.Add(.()
		{
			Set = 0, Binding = 0,
			Type = .SampledTexture, // Conflict!
			Stages = .Fragment,
			Count = 1
		});

		defer { delete shader1; delete shader2; }

		ReflectedShader[2] shaders = .(shader1, shader2);
		let layouts = new List<List<BindGroupLayoutEntry>>();
		defer { DeleteContainerAndItems!(layouts); }

		let result = ReflectionUtils.DeriveBindGroupLayouts(shaders, layouts);
		Test.Assert(result case .Err, "Should detect binding conflict");
	}

	[Test]
	public static void TestSetGapsFilled()
	{
		// Shader uses set 0 and set 2 (gap at set 1)
		let shader = new ReflectedShader();
		shader.Stage = .Vertex;
		shader.Bindings.Add(.() { Set = 0, Binding = 0, Type = .UniformBuffer, Stages = .Vertex, Count = 1 });
		shader.Bindings.Add(.() { Set = 2, Binding = 0, Type = .SampledTexture, Stages = .Vertex, Count = 1 });
		defer delete shader;

		ReflectedShader[1] shaders = .(shader);
		let layouts = new List<List<BindGroupLayoutEntry>>();
		defer { DeleteContainerAndItems!(layouts); }

		let result = ReflectionUtils.DeriveBindGroupLayouts(shaders, layouts);
		Test.Assert(result case .Ok, "Should succeed");
		Test.Assert(layouts.Count == 3, scope String()..AppendF("Expected 3 sets (0,1,2), got {}", layouts.Count));
		Test.Assert(layouts[1].Count == 0, "Set 1 should be empty (gap)");
		Test.Assert(layouts[0].Count == 1, "Set 0 should have 1 entry");
		Test.Assert(layouts[2].Count == 1, "Set 2 should have 1 entry");
	}

	[Test]
	public static void TestDeriveVertexAttributes()
	{
		let bytecode = TestHelper.LoadShader("test_bindings_vs.spv");
		Test.Assert(bytecode != null, "Failed to load shader");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode, "VSMain");
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		let attrs = scope List<VertexAttribute>();
		ReflectionUtils.DeriveVertexAttributes(shader, attrs);

		// 3 vertex inputs: Position (float3), TexCoord (float2), BoneIds (uint4)
		Test.Assert(attrs.Count == 3, scope String()..AppendF("Expected 3 attributes, got {}", attrs.Count));

		// Sorted by location, sequential offsets
		Test.Assert(attrs[0].ShaderLocation == 0, "First attr should be location 0");
		Test.Assert(attrs[0].Format == .Float32x3, "Position should be Float32x3");
		Test.Assert(attrs[0].Offset == 0, "First attr offset should be 0");

		Test.Assert(attrs[1].ShaderLocation == 1, "Second attr should be location 1");
		Test.Assert(attrs[1].Format == .Float32x2, "TexCoord should be Float32x2");
		Test.Assert(attrs[1].Offset == 12, scope String()..AppendF("Second attr offset should be 12, got {}", attrs[1].Offset));

		Test.Assert(attrs[2].ShaderLocation == 2, "Third attr should be location 2");
		Test.Assert(attrs[2].Format == .Uint32x4, "BoneIds should be Uint32x4");
		Test.Assert(attrs[2].Offset == 20, scope String()..AppendF("Third attr offset should be 20, got {}", attrs[2].Offset));
	}

	[Test]
	public static void TestDerivePushConstantRanges()
	{
		let vs = new ReflectedShader();
		vs.Stage = .Vertex;
		vs.PushConstants.Add(.() { Offset = 0, Size = 64, Stages = .Vertex });

		let ps = new ReflectedShader();
		ps.Stage = .Fragment;
		ps.PushConstants.Add(.() { Offset = 0, Size = 64, Stages = .Fragment });

		defer { delete vs; delete ps; }

		ReflectedShader[2] shaders = .(vs, ps);
		let ranges = scope List<PushConstantRange>();
		ReflectionUtils.DerivePushConstantRanges(shaders, ranges);

		// Same offset+size should be merged
		Test.Assert(ranges.Count == 1, scope String()..AppendF("Expected 1 merged range, got {}", ranges.Count));
		Test.Assert(ranges[0].Stages == (.Vertex | .Fragment), "Stages should be merged");
		Test.Assert(ranges[0].Size == 64, "Size should be 64");
	}

	[Test]
	public static void TestFormatByteSize()
	{
		Test.Assert(ReflectionUtils.FormatByteSize(.Float32) == 4);
		Test.Assert(ReflectionUtils.FormatByteSize(.Float32x2) == 8);
		Test.Assert(ReflectionUtils.FormatByteSize(.Float32x3) == 12);
		Test.Assert(ReflectionUtils.FormatByteSize(.Float32x4) == 16);
		Test.Assert(ReflectionUtils.FormatByteSize(.Uint32x4) == 16);
		Test.Assert(ReflectionUtils.FormatByteSize(.Sint32) == 4);
		Test.Assert(ReflectionUtils.FormatByteSize(.Uint8x4) == 4);
		Test.Assert(ReflectionUtils.FormatByteSize(.Float16x2) == 4);
		Test.Assert(ReflectionUtils.FormatByteSize(.Float16x4) == 8);
	}
}
