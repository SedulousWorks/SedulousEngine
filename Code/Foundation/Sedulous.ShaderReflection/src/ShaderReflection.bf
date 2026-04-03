namespace Sedulous.ShaderReflection;

using System;
using System.Collections;
using System.Diagnostics;

/// Factory registry for shader reflection backends.
/// Backends register themselves via static constructors when their project is included as a dependency.
static class ShaderReflection
{
	static Dictionary<ShaderFormat, IReflectionBackend> sBackends = new .() ~ delete _;

	/// Called by backend libraries in their static constructors.
	public static void RegisterBackend(IReflectionBackend backend)
	{
		sBackends[backend.Format] = backend;
	}

	/// Creates a reflected shader from bytecode.
	/// The appropriate backend is selected based on format.
	/// Caller owns the returned ReflectedShader and must delete it.
	public static Result<ReflectedShader> Reflect(ShaderFormat format,
		Span<uint8> bytecode, StringView entryPoint = default)
	{
		if (!sBackends.TryGetValue(format, let backend))
		{
			Debug.WriteLine("ShaderReflection: no backend registered for format");
			return .Err;
		}
		return backend.Reflect(bytecode, entryPoint);
	}

	/// Checks whether a backend is available for the given format.
	public static bool IsFormatSupported(ShaderFormat format)
	{
		return sBackends.ContainsKey(format);
	}
}
