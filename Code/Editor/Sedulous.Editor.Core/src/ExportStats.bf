namespace Sedulous.Editor.Core;

/// The cook, stage and pack totals of one export.
class ExportStats
{
	public int Cooked = 0;
	public int CookFailed = 0;
	public int ScenesStaged = 0;
	public int FilesPacked = 0;

	public void CopyTo(ExportStats other)
	{
		other.Cooked = Cooked;
		other.CookFailed = CookFailed;
		other.ScenesStaged = ScenesStaged;
		other.FilesPacked = FilesPacked;
	}
}
