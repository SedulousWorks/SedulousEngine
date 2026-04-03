namespace Sedulous.ShaderReflection;

using System;

/// Shader bytecode format.
enum ShaderFormat
{
	SPIRV,
	DXIL,
}

/// Interface implemented by reflection backends (SPIR-V, DXIL).
/// Each backend handles one ShaderFormat and knows how to extract
/// metadata from compiled shader bytecode.
interface IReflectionBackend
{
	/// The shader bytecode format this backend handles.
	ShaderFormat Format { get; }

	/// Reflect a compiled shader module.
	/// bytecode: raw shader bytecode (DXIL or SPIR-V).
	/// entryPoint: entry point name (default = "main").
	/// Caller owns the returned ReflectedShader and must delete it.
	Result<ReflectedShader> Reflect(Span<uint8> bytecode, StringView entryPoint = default);
}
