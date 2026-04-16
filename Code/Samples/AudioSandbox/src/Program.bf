namespace AudioSandbox;

using System;
using System.Collections;
using System.IO;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.Runtime;
using Sedulous.GUI;
using Sedulous.GUI.Runtime;
using Sedulous.Fonts;
using Sedulous.Audio;
using Sedulous.Audio.SDL3;
using Sedulous.Audio.Decoders;

/// Audio track info.
class AudioTrack
{
	public String Name ~ delete _;
	public String Path ~ delete _;
	public AudioClip Clip;

	public this(StringView name, StringView path)
	{
		Name = new String(name);
		Path = new String(path);
	}
}

/// Audio Sandbox - Audio Player with GUI.
class AudioSandboxApp : Application
{
	// Audio system
	private SDL3AudioSystem mAudioSystem ~ delete _;
	private AudioDecoderFactory mDecoderFactory ~ delete _;
	private IAudioSource mCurrentSource;
	private List<AudioTrack> mTracks = new .() ~ DeleteContainerAndItems!(_);
	private int mCurrentTrackIndex = -1;
	private float mVolume = 0.7f;
	private bool mIsPlaying = false;

	// GUI system (handles rendering, input, fonts internally)
	private GUISubsystem mUISubsystem;
	private DockPanel mUIRoot;

	// UI Elements (for updating)
	private TextBlock mNowPlayingLabel;
	private TextBlock mVolumeLabel;
	private StackPanel mTrackList;
	private Button mPlayPauseButton;

	public this() : base()
	{
	}

	protected override void OnInitialize(Context context)
	{
		// Initialize audio
		if (!InitializeAudio())
			return;

		// Initialize GUI subsystem
		mUISubsystem = new GUISubsystem();
		context.RegisterSubsystem(mUISubsystem);

		String shaderPath = scope .();
		GetAssetPath("shaders", shaderPath);
		if (mUISubsystem.InitializeRendering(mDevice, mSwapChain.Format, (int32)mSwapChain.BufferCount, mShell, mWindow, scope StringView[](shaderPath)) case .Err)
		{
			Console.WriteLine("Failed to initialize UI rendering");
			return;
		}

		// Load font
		String fontPath = scope .();
		GetAssetPath("fonts/roboto/Roboto-Regular.ttf", fontPath);
		FontLoadOptions fontOptions = .ExtendedLatin;
		fontOptions.PixelHeight = 16;
		mUISubsystem.LoadFont("Roboto", fontPath, fontOptions);

		// Build UI
		BuildUI();

		// Load audio tracks
		LoadAudioTracks();
	}

	private bool InitializeAudio()
	{
		Console.WriteLine("Initializing audio system...");

		mAudioSystem = new SDL3AudioSystem();
		if (!mAudioSystem.IsInitialized)
		{
			Console.WriteLine("ERROR: Failed to initialize audio system!");
			return false;
		}

		mDecoderFactory = new AudioDecoderFactory();
		mDecoderFactory.RegisterDefaultDecoders();

		Console.WriteLine($"Audio system initialized. Decoders: {mDecoderFactory.DecoderCount}");
		return true;
	}

	private void BuildUI()
	{
		if (mUISubsystem?.GUIContext == null)
			return;

		mUIRoot = new DockPanel();
		mUIRoot.Background = Color(25, 25, 35, 255);

		// Header
		let header = new Border();
		header.Background = Color(40, 40, 55, 255);
		header.Padding = Thickness(20, 15, 20, 15);
		DockPanelProperties.SetDock(header, .Top);

		let headerContent = new StackPanel();
		headerContent.Orientation = .Vertical;
		headerContent.Spacing = 5;
		header.Child = headerContent;

		let title = new TextBlock();
		title.Text = "Audio Player";
		title.Foreground = Color.White;
		title.FontSize = 20;
		headerContent.AddChild(title);

		mNowPlayingLabel = new TextBlock();
		mNowPlayingLabel.Text = "No track selected";
		mNowPlayingLabel.Foreground = Color(150, 150, 160);
		headerContent.AddChild(mNowPlayingLabel);

		mUIRoot.AddChild(header);

		// Controls bar
		let controlsBar = new Border();
		controlsBar.Background = Color(35, 35, 50, 255);
		controlsBar.Padding = Thickness(20, 10, 20, 10);
		DockPanelProperties.SetDock(controlsBar, .Bottom);

		let controls = new StackPanel();
		controls.Orientation = .Horizontal;
		controls.Spacing = 15;
		controls.HorizontalAlignment = .Center;
		controlsBar.Child = controls;

		// Play/Pause button
		mPlayPauseButton = new Button("Play");
		mPlayPauseButton.Padding = Thickness(20, 8, 20, 8);
		mPlayPauseButton.Click.Subscribe(new (sender) => TogglePlayPause());
		controls.AddChild(mPlayPauseButton);

		// Stop button
		let stopBtn = new Button("Stop");
		stopBtn.Padding = Thickness(20, 8, 20, 8);
		stopBtn.Click.Subscribe(new (sender) => StopPlayback());
		controls.AddChild(stopBtn);

		// Separator
		let sep = new Border();
		sep.Width = 20;
		controls.AddChild(sep);

		// Volume down
		let volDown = new Button("-");
		volDown.Padding = Thickness(12, 8, 12, 8);
		volDown.Click.Subscribe(new (sender) => AdjustVolume(-0.1f));
		controls.AddChild(volDown);

		// Volume label
		mVolumeLabel = new TextBlock();
		mVolumeLabel.Text = "70%";
		mVolumeLabel.Foreground = Color.White;
		mVolumeLabel.VerticalAlignment = .Center;
		mVolumeLabel.Width = 50;
		mVolumeLabel.TextAlignment = .Center;
		controls.AddChild(mVolumeLabel);

		// Volume up
		let volUp = new Button("+");
		volUp.Padding = Thickness(12, 8, 12, 8);
		volUp.Click.Subscribe(new (sender) => AdjustVolume(0.1f));
		controls.AddChild(volUp);

		mUIRoot.AddChild(controlsBar);

		// Track list
		let scrollViewer = new ScrollViewer();
		scrollViewer.Padding = Thickness(10);

		mTrackList = new StackPanel();
		mTrackList.Orientation = .Vertical;
		mTrackList.Spacing = 2;
		scrollViewer.Content = mTrackList;

		mUIRoot.AddChild(scrollViewer);

		mUISubsystem.GUIContext.RootElement = mUIRoot;
	}

	private void LoadAudioTracks()
	{
		String audioDir = scope .();
		GetAssetPath("samples/audio/kenney_rpg-audio/Audio", audioDir);

		Console.WriteLine($"Loading audio from: {audioDir}");

		if (!Directory.Exists(audioDir))
		{
			Console.WriteLine("Audio directory not found!");
			return;
		}

		for (let entry in Directory.EnumerateFiles(audioDir, "*.ogg"))
		{
			String fileName = scope .();
			entry.GetFileName(fileName);

			String fullPath = scope .();
			entry.GetFilePath(fullPath);

			let track = new AudioTrack(fileName, fullPath);
			mTracks.Add(track);
		}

		Console.WriteLine($"Found {mTracks.Count} audio files");

		for (int i = 0; i < mTracks.Count; i++)
		{
			let track = mTracks[i];
			let trackIndex = i;

			let trackBtn = new Button(track.Name);
			trackBtn.Padding = Thickness(10, 6, 10, 6);
			trackBtn.HorizontalAlignment = .Stretch;
			trackBtn.Click.Subscribe(new (sender) => { this.SelectTrack(trackIndex); });

			mTrackList.AddChild(trackBtn);
		}
	}

	// ==================== Audio Controls ====================

	private void SelectTrack(int index)
	{
		if (index < 0 || index >= mTracks.Count)
			return;

		mCurrentTrackIndex = index;
		let track = mTracks[index];

		Console.WriteLine($"Selected: {track.Name}");

		if (track.Clip == null)
		{
			Console.WriteLine($"Decoding: {track.Path}");
			if (mDecoderFactory.DecodeFile(track.Path) case .Ok(let clip))
			{
				track.Clip = clip;
				Console.WriteLine($"Decoded: {clip.Duration:F2}s, {clip.SampleRate}Hz, {clip.Channels}ch");
			}
			else
			{
				Console.WriteLine("Failed to decode audio file!");
				return;
			}
		}

		mNowPlayingLabel.Text = track.Name;
		PlayCurrentTrack();
	}

	private void PlayCurrentTrack()
	{
		if (mCurrentTrackIndex < 0 || mCurrentTrackIndex >= mTracks.Count)
			return;

		let track = mTracks[mCurrentTrackIndex];
		if (track.Clip == null)
			return;

		StopPlayback();

		mCurrentSource = mAudioSystem.CreateSource();
		if (mCurrentSource != null)
		{
			mCurrentSource.Volume = mVolume;
			mCurrentSource.Play(track.Clip);
			mIsPlaying = true;
			if (let textBlock = mPlayPauseButton.Content as TextBlock) textBlock.Text = "Pause";
		}
	}

	private void TogglePlayPause()
	{
		if (mCurrentSource == null)
		{
			if (mCurrentTrackIndex >= 0)
				PlayCurrentTrack();
			return;
		}

		if (mIsPlaying)
		{
			mCurrentSource.Pause();
			mIsPlaying = false;
			if (let textBlock = mPlayPauseButton.Content as TextBlock) textBlock.Text = "Play";
		}
		else
		{
			mCurrentSource.Resume();
			mIsPlaying = true;
			if (let textBlock = mPlayPauseButton.Content as TextBlock) textBlock.Text = "Pause";
		}
	}

	private void StopPlayback()
	{
		if (mCurrentSource != null)
		{
			mCurrentSource.Stop();
			mAudioSystem.DestroySource(mCurrentSource);
			mCurrentSource = null;
		}
		mIsPlaying = false;
		if (mPlayPauseButton != null)
			if (let textBlock = mPlayPauseButton.Content as TextBlock) textBlock.Text = "Play";
	}

	private void AdjustVolume(float delta)
	{
		mVolume = Math.Clamp(mVolume + delta, 0.0f, 1.0f);

		if (mCurrentSource != null)
			mCurrentSource.Volume = mVolume;

		let pct = (int)(mVolume * 100);
		mVolumeLabel.Text = scope:: $"{pct}%";
	}

	// ==================== Lifecycle ====================

	protected override void OnUpdate(FrameContext frame)
	{
		// Update audio system
		mAudioSystem.Update();

		// Check if track finished
		if (mCurrentSource != null && mCurrentSource.State == .Stopped && mIsPlaying)
		{
			mIsPlaying = false;
			if (let textBlock = mPlayPauseButton.Content as TextBlock) textBlock.Text = "Play";
		}

		// Spacebar for play/pause
		if (mShell.InputManager.Keyboard.IsKeyPressed(.Space))
			TogglePlayPause();
	}

	protected override bool OnRenderFrame(RenderContext render)
	{
		// Clear the swapchain first (no 3D scene, just GUI)
		ColorAttachment[1] clearAttachments = .(.()
		{
			View = render.CurrentTextureView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = ClearColor(render.ClearColor.R / 255.0f, render.ClearColor.G / 255.0f, render.ClearColor.B / 255.0f, render.ClearColor.A / 255.0f)
		});
		RenderPassDesc clearPass = .() { ColorAttachments = .(clearAttachments) };
		let rp = render.Encoder.BeginRenderPass(clearPass);
		if (rp != null)
			rp.End();

		// Render GUI overlay
		mUISubsystem?.Render(render.Encoder, render.CurrentTextureView,
			render.SwapChain.Width, render.SwapChain.Height,
			render.Frame.FrameIndex);

		return true;
	}

	protected override void OnResize(int32 width, int32 height)
	{
		mUISubsystem?.GUIContext?.SetViewportSize((float)width, (float)height);
	}

	protected override void OnShutdown()
	{
		StopPlayback();

		// Delete UI root before context shutdown
		DeleteAndNullify!(mUIRoot);

		// Clean up tracks (clips are owned by tracks)
		for (let track in mTracks)
		{
			if (track.Clip != null)
				delete track.Clip;
		}
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope AudioSandboxApp();
		return app.Run(.()
		{
			Title = "Audio Sandbox",
			Width = 800, Height = 600,
			EnableDepth = false
		});
	}
}
