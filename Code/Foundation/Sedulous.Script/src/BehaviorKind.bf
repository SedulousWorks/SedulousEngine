using System;

namespace Sedulous.Script;

/// The three kinds of class the engine runs, by the scope each lives in: a RunBehavior for the
/// run, a SceneBehavior for a scene, an EntityBehavior for an entity. A class declares its kind by
/// deriving from one, in every language; each language names the kinds as the base types listed
/// here, and a cook records the kind it found.
enum BehaviorKind : uint8
{
	/// Not a behavior: a module of helpers, or a class deriving from no kind.
	case None;
	/// Lives for the run, across scene loads; constructed with nothing.
	case Run;
	/// One per scene; constructed with its scene.
	case Scene;
	/// One per attached slot on an entity; constructed with its entity.
	case Entity;
}

static class BehaviorKinds
{
	/// Every kind a class can declare, in the order Run, Scene, Entity.
	public static readonly BehaviorKind[3] All = .(.Run, .Scene, .Entity);

	/// The base type a class derives from to be of `kind`, as every language names it
	/// ("RunBehavior"); empty for None.
	public static StringView TypeName(BehaviorKind kind)
	{
		switch (kind)
		{
		case .Run: return "RunBehavior";
		case .Scene: return "SceneBehavior";
		case .Entity: return "EntityBehavior";
		case .None: return default;
		}
	}

	/// The kind whose base type is named `typeName`; None when no kind is.
	public static BehaviorKind FromTypeName(StringView typeName)
	{
		for (let kind in All)
		{
			if (TypeName(kind) == typeName)
				return kind;
		}
		return .None;
	}
}
