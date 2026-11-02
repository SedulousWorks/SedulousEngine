using System;

namespace Sedulous.Core;

static
{
	/// A size for a person, appended to `outText`: "412 KB" below a megabyte (at least 1 KB, never
	/// "0 KB"), then "7.2 MB" to a tenth; 1024-based. The project manager's sample sizes and the
	/// import window's file sizes say sizes this way.
	public static void ByteSizeText(uint64 bytes, String outText)
	{
		let tenths = (bytes * 10 + 512 * 1024) / (1024 * 1024);
		if (tenths < 10)
			outText.AppendF("{} KB", Math.Max((uint64)1, (bytes + 512) / 1024));
		else
			outText.AppendF("{}.{} MB", tenths / 10, tenths % 10);
	}
}
