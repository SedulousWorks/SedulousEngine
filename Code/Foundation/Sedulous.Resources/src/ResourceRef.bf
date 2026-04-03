namespace Sedulous.Resources;

using System;

/// Serializable reference to a resource: GUID for identity + path for file resolution.
/// The Path string is owned by this struct. Call Dispose() to free it.
[Reflect(.NonStaticFields)]
struct ResourceRef : IDisposable
{
	public Guid Id;
	public String Path; // Owned, heap-allocated

	/// Creates an empty (invalid) resource reference.
	public this()
	{
		Id = .();
		Path = null;
	}

	/// Creates a resource reference with both ID and path.
	public this(Guid id, StringView path)
	{
		Id = id;
		Path = new String(path);
	}

	/// Creates a resource reference from an existing resource and a known path.
	public this(IResource resource, StringView path)
	{
		Id = resource.Id;
		Path = new String(path);
	}

	/// Returns true if this reference has at least an ID or a path.
	public bool IsValid => Id != Guid() || (Path != null && Path.Length > 0);

	/// Returns true if this reference has a GUID.
	public bool HasId => Id != Guid();

	/// Returns true if this reference has a path.
	public bool HasPath => Path != null && Path.Length > 0;

	/// Disposes the owned path string.
	public void Dispose() mut
	{
		delete Path;
		Path = null;
	}
}
