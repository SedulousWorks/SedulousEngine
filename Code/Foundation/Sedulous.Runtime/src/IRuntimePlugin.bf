using System;

namespace Sedulous.Runtime;

/// A unit of engine functionality delivered separately from the executable.
///
/// A plugin registers its subsystems and services into the context on load and removes
/// them on unload. It may be linked in and handed to the host directly, or loaded from a
/// shared library at runtime.
///
/// A plugin OWNS the subsystems it registers: it registers them non owningly and tears
/// them down in OnUnload, which runs while its library is still open.
interface IRuntimePlugin
{
	/// For logs and diagnostics.
	StringView Name { get; }

	/// Register subsystems and services into the context.
	void OnLoad(Context context);

	/// Remove what OnLoad added.
	///
	/// Called BEFORE the backing library is closed, so touching plugin defined types and
	/// destroying subsystems here is safe. After the close, none of that code exists.
	void OnUnload(Context context);
}
