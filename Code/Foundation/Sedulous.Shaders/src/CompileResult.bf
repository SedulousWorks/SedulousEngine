using System;

namespace Sedulous.Shaders;

/// What a compile produced: bytecode, diagnostics, or both.
///
/// Messages are populated even on SUCCESS, because a compile that warns still warns. The
/// arrays are owned by the result and released by Dispose.
struct CompileResult : IDisposable
{
	public uint8[] Bytecode = null;
	public String Messages = null;
	public bool Success = false;

	public this() {}

	public void Dispose() mut
	{
		delete Bytecode;
		Bytecode = null;
		delete Messages;
		Messages = null;
		Success = false;
	}
}
