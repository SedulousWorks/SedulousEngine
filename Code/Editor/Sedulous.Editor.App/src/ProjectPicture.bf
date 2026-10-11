using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.UI;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

/// The picture a project is shown by, in the launcher and on the Project page.
static class ProjectPicture
{
	/// The picture of the project named `name` in `projectDirectory`, `w` x `h` with corners of
	/// `radius`: its thumbnail when one reads (an empty directory never does), else its initial.
	/// The image a thumbnail view borrows is added to `keep`, which must outlive the view. The
	/// caller's view.
	public static View Make(StringView projectDirectory, StringView name, float w, float h, float radius, List<Image> keep)
	{
		var size = LayoutStyle();
		size.Width = SizeSpec.Fixed(Unit.Dp(w));
		size.Height = SizeSpec.Fixed(Unit.Dp(h));
		let frame = new FlexLayout();
		let image = new Image();
		if (!projectDirectory.IsEmpty && (ImageIO.LoadImage(EditorProject.ThumbnailPath(projectDirectory, .. scope .()), image) case .Ok))
		{
			keep.Add(image); // the view borrows it
			let view = new ImageView(image);
			view.ScaleType.Value = .CenterCrop;
			view.CornerRadius.Value = .(radius);
			frame.AddView(view, size);
			return frame;
		}
		delete image;
		// No picture yet: the project's initial on a quiet tile.
		let tile = new Panel();
		tile.SetStyle(.Background, new RoundedRectDrawable(Color(1, 1, 1, 0.05f), radius, Color(1, 1, 1, 0.08f), 1.0f));
		let initial = scope String();
		for (let c in name.DecodedChars)
		{
			initial.Append(c);
			break;
		}
		if (initial.IsEmpty)
			initial.Append('?');
		let letter = new Label(initial);
		letter.FontSize.Value = h * 0.42f;
		letter.TextColor.Value = Color(1, 1, 1, 0.35f);
		letter.HAlign.Value = .Center;
		letter.VAlign.Value = .Middle;
		tile.AddView(letter);
		frame.AddView(tile, size);
		return frame;
	}
}
