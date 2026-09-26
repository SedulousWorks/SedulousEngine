namespace Sedulous.Script;

/// Which marked types a surface root takes.
enum ScriptSurfaceClosure
{
	/// Every [Scriptable] type in the root's dependency closure: the editor's and the
	/// pipeline's surface, where the engine's own types are the point.
	case Dependencies;
	/// The runtime's surface: the facades and what they reach, meaning the scene and service
	/// facades, the global static blocks, the Scene, and transitively every type their
	/// members name. A layer of its own over the engine, so a component or a manager marked
	/// for the editor does not become a script contract by being linked.
	case Runtime;
	/// The runtime closure, plus every marked type of the root's other allowed domains and
	/// what those name: the pipeline's surface, engine and pipeline. What a game script
	/// compiles against is exactly the runtime's, so a check made here never passes code the
	/// game rejects, and the domain's own types ride on top.
	case RuntimeAndDomains;
}
