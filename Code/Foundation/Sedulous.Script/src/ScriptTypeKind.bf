namespace Sedulous.Script;

/// What a surface type is to a script.
enum ScriptTypeKind
{
	/// A reference type: an object handle in the script.
	case Class;
	/// A value type, copied across the boundary.
	case Struct;
	case Enum;
	/// A namespace's static block: free functions, exposed at the script's global scope.
	case Global;
}
