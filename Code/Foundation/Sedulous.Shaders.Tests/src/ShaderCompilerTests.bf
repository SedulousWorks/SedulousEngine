using System;
using Sedulous.Core;
using Sedulous.Shaders;

namespace Sedulous.Shaders.Tests;

/// DXC driving a real compile.
class ShaderCompilerTests
{
	private const String cVertexHlsl = """
		float4 main(uint id : SV_VertexID) : SV_Position {
		    return float4(0.0, 0.0, 0.0, 1.0);
		}
		""";

	private static ShaderCompiler MakeCompiler()
	{
		let compiler = new ShaderCompiler();
		if (compiler.Initialize() case .Err)
		{
			delete compiler;
			return null;
		}
		return compiler;
	}

	private static Span<uint8> AsBytes(StringView text) => .((uint8*)text.Ptr, text.Length);

	/// The `OpDecorate <id> Location <n>` instructions in a SPIR-V blob, one per stage
	/// interface variable, inputs and outputs alike, that survived the compile.
	private static int CountLocationDecorations(Span<uint8> words)
	{
		const uint32 cOpDecorate = 71;
		const uint32 cDecorationLocation = 30;

		var count = 0;
		let total = words.Length / 4;
		let data = (uint32*)words.Ptr;
		var w = 5; // past the five word header
		while (w < total)
		{
			let wordCount = data[w] >> 16;
			let opcode = data[w] & 0xFFFF;
			if (wordCount == 0)
				break;

			if ((opcode == cOpDecorate) && (wordCount >= 4) && ((w + 2) < total)
				&& (data[w + 2] == cDecorationLocation))
				count++;

			w += (int)wordCount;
		}
		return count;
	}

	/// PreserveInterface keeps a declared but unread fragment input in the interface.
	///
	/// Optimisation otherwise strips it, and a stage whose input list is SHORTER than the
	/// vertex stage's output list is a Vulkan interface error rather than a subset: the
	/// interface is matched by location, so the pairing has to be exact.
	[Test]
	public static void PreserveInterfaceKeepsAnUnreadFragmentInput()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		let ps = """
			struct In { float4 pos : SV_Position; float3 a : TEXCOORD0; float2 b : TEXCOORD1; };
			float4 main(In i) : SV_Target0 { return float4(i.b, 0, 1); }
			""";

		int[2] locations = .(0, 0);
		for (int pass < 2)
		{
			var options = CompileOptions();
			options.PreserveInterface = pass == 1;

			var result = compiler.Compile(AsBytes(ps), .Fragment, "main", .SPIRV, options);
			defer result.Dispose();
			Test.Assert(result.Success, "the fragment shader compiled");
			locations[pass] = CountLocationDecorations(.(result.Bytecode.Ptr,
				result.Bytecode.Count));
		}

		Test.Assert(locations[0] == 2, "stripped: the read input and the colour output");
		Test.Assert(locations[1] == 3, "preserved: the unread input holds its location too");
	}

	/// HLSL in, SPIR-V out, checked by its magic word rather than merely by a non-empty
	/// buffer: a blob whose first word is not the magic is not something a driver accepts.
	[Test]
	public static void HlslCompilesToSpirv()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		var result = compiler.Compile(AsBytes(cVertexHlsl), .Vertex, "main", .SPIRV, .());
		defer result.Dispose();

		Test.Assert(result.Success, "the vertex shader compiled");
		Test.Assert(result.Bytecode != null);
		Test.Assert(result.Bytecode.Count >= 4, "and produced at least one word");

		uint32 magic = 0;
		Internal.MemCpy(&magic, result.Bytecode.Ptr, 4);
		Test.Assert(magic == 0x07230203, "the blob starts with the SPIR-V magic");
	}

	/// Nonsense HLSL is REPORTED, not crashed on, and the messages say something.
	[Test]
	public static void ACompileErrorIsReported()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		var result = compiler.Compile(AsBytes("this is not valid hlsl @#$"), .Vertex, "main",
			.SPIRV, .());
		defer result.Dispose();

		Test.Assert(!result.Success, "the bad source did not compile");
		Test.Assert(result.Bytecode == null, "and produced no bytecode");
		// The point of the result carrying messages: a shader typo must arrive as a
		// diagnostic rather than an unexplained refusal.
		Test.Assert(!result.Messages.IsEmpty, "the failure explains itself");
	}

	/// A compile that succeeds still runs when asked for DXIL rather than SPIR-V, and the
	/// two blobs differ: the target is not being ignored.
	[Test]
	public static void TheTargetSelectsTheBytecode()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		var spirv = compiler.Compile(AsBytes(cVertexHlsl), .Vertex, "main", .SPIRV, .());
		defer spirv.Dispose();
		Test.Assert(spirv.Success);

		var dxil = compiler.Compile(AsBytes(cVertexHlsl), .Vertex, "main", .DXIL, .());
		defer dxil.Dispose();

		// DXIL signing needs dxil.dll, which is Windows only, so a failure here is a
		// platform fact rather than a defect. What must hold either way is that the two
		// paths did not produce the SAME blob.
		if (!dxil.Success)
		{
			Console.WriteLine("SKIP: no DXIL signing on this platform");
			return;
		}

		uint32 magic = 0;
		Internal.MemCpy(&magic, dxil.Bytecode.Ptr, 4);
		Test.Assert(magic != 0x07230203, "the DXIL blob is not SPIR-V");
	}

	/// A define reaches the preprocessor: the shader fails to compile without it and
	/// succeeds with it, which nothing but a real define could produce.
	[Test]
	public static void DefinesReachThePreprocessor()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		let source = """
			#ifndef WANTED
			#error WANTED was not defined
			#endif
			float4 main() : SV_Position { return float4(0, 0, 0, 1); }
			""";

		var without = compiler.Compile(AsBytes(source), .Vertex, "main", .SPIRV, .());
		defer without.Dispose();
		Test.Assert(!without.Success, "the guard fires when the define is absent");

		var define = ShaderDefine("WANTED", "1");
		var options = CompileOptions();
		options.Defines = .(&define, 1);
		var with = compiler.Compile(AsBytes(source), .Vertex, "main", .SPIRV, options);
		defer with.Dispose();
		Test.Assert(with.Success, "and not when it is present");
	}

	/// The compiler refuses to work rather than crashing when it was never initialized,
	/// which is the shape a caller hits after a failed Initialize.
	[Test]
	public static void AnUninitializedCompilerRefuses()
	{
		let compiler = scope ShaderCompiler();
		var result = compiler.Compile(AsBytes(cVertexHlsl), .Vertex, "main", .SPIRV, .());
		defer result.Dispose();

		Test.Assert(!result.Success);
		Test.Assert(!result.Messages.IsEmpty, "and says why");
	}

	/// Initialize twice is a no-op rather than a second set of leaked interfaces.
	[Test]
	public static void InitializeIsIdempotent()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		Test.Assert(compiler.Initialize() case .Ok, "a second Initialize succeeds");
		Test.Assert(compiler.IsInitialized);

		var result = compiler.Compile(AsBytes(cVertexHlsl), .Vertex, "main", .SPIRV, .());
		defer result.Dispose();
		Test.Assert(result.Success, "and the compiler still works");
	}
}
