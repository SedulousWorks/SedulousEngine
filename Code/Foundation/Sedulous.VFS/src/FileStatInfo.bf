namespace Sedulous.VFS;

/// Size and last-write time of one entry.
struct FileStatInfo
{
	public int64 Size;
	/// Platform ticks, as Core reports them. Raptor stores whole seconds, which cannot
	/// distinguish two edits within the same second, and that is exactly what a sweep is
	/// looking for.
	public int64 ModifiedTicks;
}
