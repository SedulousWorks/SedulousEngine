using System;

namespace Sedulous.Editor.Scene;

/// The graph page's selection: a layer, a parameter, or a state or transition of a layer.
struct GraphSel : IEquatable<GraphSel>
{
	/// A structural edit may ask for "the last one", resolved once the edit has run.
	public const int32 Last = -2;

	public GraphSelKind Kind = .None;
	/// The owning layer for a layer, state or transition.
	public int32 Layer = 0;
	/// The parameter, state or transition index.
	public int32 Index = -1;

	public this() {}

	public this(GraphSelKind kind, int32 layer, int32 index)
	{
		Kind = kind;
		Layer = layer;
		Index = index;
	}

	public static GraphSel None => .();

	public bool Equals(GraphSel other) => (Kind == other.Kind) && (Layer == other.Layer) && (Index == other.Index);

	[Commutable]
	public static bool operator==(GraphSel a, GraphSel b) => a.Equals(b);
}
