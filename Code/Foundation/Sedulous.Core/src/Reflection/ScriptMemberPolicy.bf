namespace Sedulous.Core;

/// How [[ScriptableAttribute]] treats the members of the type it is on.
enum ScriptMemberPolicy
{
	/// Only members carrying [Scriptable] are exposed. THE DEFAULT, so writing nothing gets
	/// the safe answer: a member added later joins the script surface when someone says so
	/// and not before.
	///
	/// What an asset or a component wants. Their public members are a mix of API and of
	/// bookkeeping the engine needs, and the distinction is not visible from the outside.
	MarkedOnly,

	/// Every public FIELD AND PROPERTY is exposed, and [[HiddenAttribute]] withholds one.
	///
	/// Data only. A method is never swept in, and always needs its own [Scriptable], because
	/// the public methods on a data type are mostly the engine's own contract with it -
	/// Serialize, ResolveResources - and handing a script Serialize is not a surface, it is
	/// an accident.
	///
	/// What a closed VALUE TYPE wants. Float3's public surface is x, y, z, five constants and
	/// its free functions, all of which are the API by construction: marking each one says
	/// nothing the type does not already say, and the mark that gets forgotten when a
	/// component is added is a silent hole rather than a silent leak.
	///
	/// Reserve it for types whose shape is the point. A type that grows members for internal
	/// reasons is the wrong shape for this and should stay MarkedOnly.
	///
	/// REACHES THE TYPE'S OWN MEMBERS AND NOTHING ELSE. The maths types keep Dot, Cross and
	/// the rest in a namespace level static block beside the struct, the way Raptor keeps them
	/// as free functions, and a block is not a member of anything: those carry their own
	/// [Scriptable] whatever the type says.
	AllPublic
}
