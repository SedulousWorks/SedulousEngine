namespace Sedulous.Script;

/// Which marked types a surface root takes.
enum ScriptSurfaceClosure
{
	/// Every [Scriptable] type in the root's dependency closure: the editor's and the
	/// pipeline's surface, where the engine's own types are the point.
	case Dependencies;
	/// The facades and what they reach: the scene and service facades, the global static
	/// blocks, the Scene, and transitively every type their members name. The runtime's
	/// surface, a layer of its own over the engine, so a component or a manager marked for
	/// the editor does not become a script contract by being linked.
	case Facades;
}
