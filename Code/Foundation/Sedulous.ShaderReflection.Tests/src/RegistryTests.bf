namespace Sedulous.ShaderReflection.Tests;

using System;
using Sedulous.RHI;

/// Phase 1: Registry and format dispatch tests.
class RegistryTests
{
	[Test]
	public static void TestSPIRVBackendRegistered()
	{
		Test.Assert(ShaderReflection.IsFormatSupported(.SPIRV), "SPIR-V backend should be registered");
	}

	[Test]
	public static void TestDXILBackendRegistered()
	{
		Test.Assert(ShaderReflection.IsFormatSupported(.DXIL), "DXIL backend should be registered");
	}

	[Test]
	public static void TestReflectEmptyBytecodeReturnsErr()
	{
		let result = ShaderReflection.Reflect(.SPIRV, Span<uint8>());
		Test.Assert(result case .Err, "Empty bytecode should return Err");
	}

	[Test]
	public static void TestReflectInvalidBytecodeReturnsErr()
	{
		uint8[4] garbage = .(0xDE, 0xAD, 0xBE, 0xEF);
		let result = ShaderReflection.Reflect(.SPIRV, garbage);
		Test.Assert(result case .Err, "Invalid bytecode should return Err");
	}
}
