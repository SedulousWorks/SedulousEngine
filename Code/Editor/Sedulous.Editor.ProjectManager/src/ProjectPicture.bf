using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image.IO;
using Sedulous.GUI;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

/// The picture a project is shown by: the thumbnail the editor keeps in the project's editor
/// folder (ProjectThumbnail.PathOf), else the project's initial on a quiet tile. Its size and
/// corners are the sheet's (`.project-picture`, and a class of the caller's: the home's header, a
/// manager's row).
static class ProjectPicture
{
	/// The picture of the project named `name` in `projectDirectory`, with the class `size` (the
	/// sheet's size for where it shows): its thumbnail when one reads (an empty directory never
	/// does), else its initial. The image a thumbnail shows is added to `keep`, which must outlive
	/// the picture. A node with one reference, the caller's.
	public static Node Make(StringView projectDirectory, StringView name, StringView size, List<Sedulous.Image.Image> keep)
	{
		let image = new Sedulous.Image.Image();
		if (!projectDirectory.IsEmpty && (ImageIO.LoadImage(ProjectThumbnail.PathOf(projectDirectory, .. scope .()), image) case .Ok))
		{
			keep.Add(image); // the picture borrows it
			let picture = new Sedulous.GUI.Image();
			picture.AddClass("project-picture");
			picture.AddClass(size);
			picture.Fit = .Cover;
			let drawable = new ImageDrawable(image);
			defer drawable.ReleaseRef(); // the picture takes its own
			picture.SetDrawable(drawable);
			return picture;
		}
		delete image;
		// No picture yet: the project's initial on a quiet tile.
		let tile = new Sedulous.GUI.Panel();
		tile.AddClass("project-picture");
		tile.AddClass("project-initial");
		tile.AddClass(size);
		let initial = scope String();
		for (let c in name.DecodedChars)
		{
			initial.Append(c);
			break;
		}
		if (initial.IsEmpty)
			initial.Append('?');
		let letter = new Sedulous.GUI.Label();
		defer letter.ReleaseRef(); // the tile holds it
		letter.Text = initial;
		tile.AddChild(letter);
		return tile;
	}
}
