using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Audio;
using Sedulous.Audio.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Audio.Tests;

/// The audio editor's registration, the bus layout edits and tree, the sound cue snapshot
/// and the clip thumbnail.
class AudioEditorTests
{
	[Test]
	public static void RegisteringRoutesTheThreeAssets()
	{
		let context = scope EditorContext();
		AudioEditor.Register(context, null);
		Test.Assert(context.Pages.FindFactory(typeof(AudioClipAsset)) != null);
		Test.Assert(context.Pages.FindFactory(typeof(SoundCueAsset)) != null);
		Test.Assert(context.Pages.FindFactory(typeof(AudioBusLayoutAsset)) != null);
	}

	[Test]
	public static void WouldCycleCatchesDirectAndTransitiveCycles()
	{
		let asset = scope AudioBusLayoutAsset();
		asset.Custom[0].Name.Set("A");
		asset.Custom[0].Parent.Set("B");
		asset.Custom[1].Name.Set("B");
		asset.Custom[1].Parent.Set("C");
		asset.Custom[2].Name.Set("C");
		asset.Custom[2].Parent.Set("Master");
		Test.Assert(AudioBusLayoutEdit.WouldCycle(asset, 2, "A"));
		Test.Assert(AudioBusLayoutEdit.WouldCycle(asset, 2, "B"));
		Test.Assert(!AudioBusLayoutEdit.WouldCycle(asset, 2, "Effects"));
		Test.Assert(!AudioBusLayoutEdit.WouldCycle(asset, 2, "Master"));
		Test.Assert(AudioBusLayoutEdit.WouldCycle(asset, 0, "A"));
		Test.Assert(!AudioBusLayoutEdit.WouldCycle(asset, 0, "Nope"));
	}

	[Test]
	public static void TheBusTreeFollowsParentsAndTheEditsKeepItConsistent()
	{
		let asset = scope AudioBusLayoutAsset();
		Test.Assert(AudioBusLayoutEdit.AddBus(asset) == 0);
		Test.Assert((asset.Custom[0].Name == "Bus1") && (asset.Custom[0].Parent == "Master"));
		Test.Assert(AudioBusLayoutEdit.AddBus(asset) == 1);
		asset.Custom[1].Parent.Set("Bus1");
		asset.Custom[2].Name.Set("Ambience");
		asset.Custom[2].Parent.Set("effects"); // case insensitive
		asset.Custom[3].Name.Set("Lost");
		asset.Custom[3].Parent.Set("Nowhere"); // unknown: under Master

		let tree = scope BusTreeSnapshot();
		tree.Rebuild(asset);
		// Four fixed plus four named slots.
		Test.Assert(tree.Nodes.Count == 8);
		Test.Assert(tree.Roots.Count == 1);
		Test.Assert(tree.Nodes[0].Children.Count == 5); // Effects, Music, UI, Bus1, Lost
		Test.Assert(tree.Nodes[1].Children.Count == 1); // Ambience under Effects
		Test.Assert(tree.Label(asset, tree.Nodes[1].Children[0]) == "Ambience");
		let bus1 = tree.Nodes[0].Children[3];
		Test.Assert((tree.Label(asset, bus1) == "Bus1") && (tree.Nodes[bus1].Children.Count == 1));
		Test.Assert(tree.Nodes[tree.Nodes[bus1].Children[0]].Depth == 2);
		Test.Assert(BusTreeSnapshot.BusOf(asset, tree.Nodes[2]) === asset.Music);
		Test.Assert(BusTreeSnapshot.BusOf(asset, tree.Nodes[bus1]) === asset.Custom[0].Bus);

		// A rename follows the children; a fixed or taken name is refused.
		Test.Assert(!AudioBusLayoutEdit.RenameBus(asset, 0, "Music"));
		Test.Assert(!AudioBusLayoutEdit.RenameBus(asset, 0, "Ambience"));
		Test.Assert(AudioBusLayoutEdit.RenameBus(asset, 0, "Drums"));
		Test.Assert(asset.Custom[1].Parent == "Drums");
		// A removal re-parents the children to Master and empties the slot.
		asset.Custom[0].Bus.Volume = 0.5f;
		Test.Assert(AudioBusLayoutEdit.RemoveBus(asset, 0));
		Test.Assert(asset.Custom[0].Name.IsEmpty && (asset.Custom[0].Bus.Volume == 1.0f));
		Test.Assert(asset.Custom[1].Parent == "Master");
		tree.Rebuild(null);
		Test.Assert(tree.Nodes.IsEmpty);
	}

	[Test]
	public static void TheBusLayoutSnapshotRoundTripsBusesAndSlots()
	{
		AudioPipeline.RegisterAll();
		let a = scope AudioBusLayoutAsset();
		a.Music.Volume = 0.3f;
		a.Effects.LowpassHz = 1500.0f;
		a.Custom[0].Name.Set("drums");
		a.Custom[0].Parent.Set("Effects");
		a.Custom[0].Bus.LowpassHz = 1200.0f;
		a.Custom[0].Bus.ReverbWet = 0.4f;
		let blob = scope List<uint8>();
		AudioBusLayoutEdit.Snapshot(a, blob);
		let b = scope AudioBusLayoutAsset();
		Test.Assert(AudioBusLayoutEdit.Apply(b, blob));
		Test.Assert((b.Music.Volume == 0.3f) && (b.Effects.LowpassHz == 1500.0f));
		Test.Assert((b.Custom[0].Name == "drums") && (b.Custom[0].Parent == "Effects"));
		Test.Assert((b.Custom[0].Bus.LowpassHz == 1200.0f) && (b.Custom[0].Bus.ReverbWet == 0.4f));
		Test.Assert(!AudioBusLayoutEdit.Apply(b, blob));
	}

	[Test]
	public static void TheSoundCueSnapshotRoundTripsSlotsAndJitter()
	{
		AudioPipeline.RegisterAll();
		let a = scope SoundCueAsset();
		a.Slots[0].ClipId = Guid(0x11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x22);
		a.Slots[2].ClipId = Guid(0x33, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x44);
		a.Slots[0].Weight = 2.5f;
		a.Slots[2].Weight = 0.5f;
		a.Mode = 2;
		a.PitchMin = 0.9f;
		a.PitchMax = 1.1f;
		a.VolumeMin = 0.8f;
		a.VolumeMax = 1.0f;
		let b = scope SoundCueAsset();
		SoundCueAssetEdit.CopyTo(a, b);
		Test.Assert(b.Slots[0].ClipId == a.Slots[0].ClipId);
		Test.Assert(b.Slots[1].ClipId.IsNil);
		Test.Assert(b.Slots[2].ClipId == a.Slots[2].ClipId);
		Test.Assert((b.Slots[0].Weight == 2.5f) && (b.Slots[2].Weight == 0.5f));
		Test.Assert((b.Mode == 2) && (b.PitchMin == 0.9f) && (b.VolumeMax == 1.0f));
		Test.Assert(SoundCueAssetEdit.HasAnyClip(b));
		Test.Assert(SoundCueAssetEdit.ModeLabel(2) == "Mode: Sequential");
		Test.Assert(SoundCueAssetEdit.ModeLabel(0) == "Mode: Random (no repeat)");
		let empty = scope SoundCueAsset();
		Test.Assert(!SoundCueAssetEdit.HasAnyClip(empty));
	}

	private static int BarHeight(Image tile, int x)
	{
		let px = tile.PixelData;
		int rows = 0;
		for (int y < (int)tile.Height)
		{
			let p = (y * (int)tile.Width + x) * 4;
			if (px[p + 1] > 150) // the teal's green channel
				rows++;
		}
		return rows;
	}

	[Test]
	public static void TheThumbnailWaveformTracksTheClipsEnvelope()
	{
		const uint32 rate = 8000;
		let samples = scope List<int16>();
		samples.Resize(rate);
		for (uint32 i < rate)
		{
			let loud = (i >= rate / 3) && (i < (rate * 2) / 3);
			samples[i] = loud ? (((i % 8) < 4) ? (int16)28000 : (int16)-28000) : (int16)0;
		}
		let wav = scope List<uint8>();
		Test.Assert(AudioCodec.EncodeWav(samples, 1, rate, wav));
		let generator = scope AudioClipThumbnailGenerator();
		let tile = scope Image();
		Test.Assert(generator.Generate(wav, tile) case .Ok);
		Test.Assert(tile.Width == ThumbnailService.cThumbnailSize);
		Test.Assert(BarHeight(tile, 64) > 80); // the loud middle fills most of the strip
		Test.Assert(BarHeight(tile, 4) <= 4); // the silent edges keep only the survival midline
		Test.Assert(BarHeight(tile, 124) <= 4);

		let junk = scope uint8[16];
		Test.Assert(generator.Generate(junk, tile) case .Err);
	}
}
