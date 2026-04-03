namespace Sedulous.ShaderReflection.Tests;

using System;
using System.Collections;
using System.IO;
using System.Diagnostics;

/// Helper utilities for shader reflection tests.
static class TestHelper
{
	static Sedulous.ShaderReflection.SPIRV.SPIRVReflectionBackend sSpirvBackend = new .() ~ delete _;
	static Sedulous.ShaderReflection.DXIL.DXILReflectionBackend sDxilBackend = new .() ~ delete _;

	/// Explicitly register backends for the test project.
	/// In normal applications, the Register classes in each backend project handle this
	/// via static constructors, but test projects need explicit registration.
	static this()
	{
		ShaderReflection.RegisterBackend(sSpirvBackend);
		ShaderReflection.RegisterBackend(sDxilBackend);
	}

	/// Loads a shader bytecode file. Tries several paths relative to
	/// likely working directories (workspace root, project dir).
	/// Returns null on failure. Caller must delete the result.
	public static List<uint8> LoadShader(StringView filename)
	{
		// Try several candidate paths
		String[4] candidates = .(
			scope:: String()..AppendF("shaders/{}", filename),
			scope:: String()..AppendF("Foundation/Sedulous.ShaderReflection.Tests/shaders/{}", filename),
			scope:: String()..AppendF("../Foundation/Sedulous.ShaderReflection.Tests/shaders/{}", filename),
			scope:: String()..AppendF("../../Foundation/Sedulous.ShaderReflection.Tests/shaders/{}", filename)
		);

		for (let path in candidates)
		{
			if (File.Exists(path))
			{
				let data = new List<uint8>();
				if (File.ReadAll(path, data) case .Ok)
					return data;
				delete data;
			}
		}

		// Log CWD for debugging
		let cwd = scope String();
		Directory.GetCurrentDirectory(cwd);
		Debug.WriteLine(scope String()..AppendF("TestHelper.LoadShader: '{}' not found. CWD={}", filename, cwd));
		return null;
	}

	/// Finds a binding by name in the reflected shader.
	public static ReflectedBinding? FindBinding(ReflectedShader shader, StringView name)
	{
		for (let b in shader.Bindings)
			if (b.Name == name)
				return b;
		return null;
	}

	/// Finds a vertex input by name in the reflected shader.
	public static ReflectedVertexInput? FindVertexInput(ReflectedShader shader, StringView name)
	{
		for (let v in shader.VertexInputs)
			if (v.Name == name)
				return v;
		return null;
	}

	/// Finds a vertex input by location in the reflected shader.
	public static ReflectedVertexInput? FindVertexInputByLocation(ReflectedShader shader, uint32 location)
	{
		for (let v in shader.VertexInputs)
			if (v.Location == location)
				return v;
		return null;
	}
}
