using System;

namespace Sedulous.GUI;

// ModelIndex + ModelRole: the address of a cell in a Model, and the aspect a view asks for.
// Modeled on eepp's Models::ModelIndex / ModelRole (role only): a row and a column, and for a tree
// model the node's opaque id (InternalId) that locates it under its parent.

/// Which aspect of a cell a view is requesting (display text, a sort key, an icon, ...).
enum ModelRole
{
	Display,
	Sort,
	Icon,
	Custom
}

struct ModelIndex : IEquatable<ModelIndex>
{
	/// -1 = invalid.
	public int32 Row = -1;
	public int32 Column = 0;
	/// Opaque node identity a tree model uses to locate the node.
	public int64 InternalId = -1;

	public this() { }

	public this(int32 row, int32 column, int64 internalId)
	{
		Row = row;
		Column = column;
		InternalId = internalId;
	}

	public bool IsValid => (Row >= 0) && (Column >= 0);

	public bool Equals(ModelIndex other) => this == other;

	[Commutable]
	public static bool operator==(ModelIndex a, ModelIndex b) =>
		(a.Row == b.Row) && (a.Column == b.Column) && (a.InternalId == b.InternalId);
}

static
{
	public static ModelIndex MakeModelIndex(int32 row, int32 column = 0, int64 internalId = -1) => .(row, column, internalId);
}
