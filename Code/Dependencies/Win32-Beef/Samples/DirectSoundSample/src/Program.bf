using Win32.Media.Audio.DirectSound;
using Common;
using Win32;
using Win32.Foundation;
using Win32.Media.Audio;
using Win32.Storage.FileSystem;
using System;
using Win32.System.WindowsProgramming;
using Win32.System.Threading;
using Win32.UI.WindowsAndMessaging;

namespace DirectSoundSample;

// https://stackoverflow.com/questions/65749997/directsound-api-explanation

class Program
{
	private static String fileName = "media/CantinaBand60.wav";

	private static ComPtr<IDirectSound8>         directSound = default;
	private static ComPtr<IDirectSoundBuffer>    primaryBuffer = default;
	private static ComPtr<IDirectSoundBuffer8>   secondaryBuffer = default;
	private static uint8*                  dataBuffer = null;
	private static DWORD                   dataBufferSize = 0;
	private static DWORD                   averageBytesPerSecond = 0;

	private static bool Initialise()
	{
		HRESULT result;
		DSBUFFERDESC bufferDesc;
		WAVEFORMATEX waveFormat;

		// Initialize the direct sound interface pointer for the default sound device.
		result = DirectSoundCreate8(null, directSound.GetAddressOf(), null);
		if (FAILED(result))
		{
			return false;
		}

		// Set the cooperative level to priority so the format of the primary sound buffer can be modified.
		// We use the handle of the desktop window since we are a console application.  If you do write a 
		// graphical application, you should use the HWnd of the graphical application.
		result = directSound->SetCooperativeLevel(GetDesktopWindow(), DSSCL_PRIORITY);
		if (FAILED(result))
		{
			return false;
		}

		// Setup the primary buffer description.
		bufferDesc.dwSize = sizeof(DSBUFFERDESC);
		bufferDesc.dwFlags = DSBCAPS_PRIMARYBUFFER | DSBCAPS_CTRLVOLUME;
		bufferDesc.dwBufferBytes = 0;
		bufferDesc.dwReserved = 0;
		bufferDesc.lpwfxFormat = null;
		bufferDesc.guid3DAlgorithm = Guid.Empty;

		// Get control of the primary sound buffer on the default sound device.
		result = directSound->CreateSoundBuffer(&bufferDesc, primaryBuffer.GetAddressOf(), null);
		if (FAILED(result))
		{
			return false;
		}

		// Setup the format of the primary sound bufffer.
		// In this case it is a .WAV file recorded at 44,100 samples per second in 16-bit stereo (cd audio format).
		// Really, we should set this up from the wave file format loaded from the file.
		waveFormat.wFormatTag = WAVE_FORMAT_PCM;
		waveFormat.nSamplesPerSec = 44100;
		waveFormat.wBitsPerSample = 16;
		waveFormat.nChannels = 2;
		waveFormat.nBlockAlign = (waveFormat.wBitsPerSample / 8) * waveFormat.nChannels;
		waveFormat.nAvgBytesPerSec = waveFormat.nSamplesPerSec * waveFormat.nBlockAlign;
		waveFormat.cbSize = 0;

		// Set the primary buffer to be the wave format specified.
		result = primaryBuffer->SetFormat(&waveFormat);
		if (FAILED(result))
		{
			return false;
		}
		return true;
	}

	public static void Shutdown()
	{
		// Destroy the data buffer
		if (dataBuffer != null)
		{
			delete dataBuffer;
			dataBuffer = null;
		}

		// Release the primary sound buffer pointer.
		if (primaryBuffer.Get() != null)
		{
			primaryBuffer.Dispose();
			primaryBuffer = null;
		}

		// Release the direct sound interface pointer.
		if (directSound.Get() != null)
		{
			directSound.Dispose();
			directSound = null;
		}
	}

	// Load the wave file into memory and setup the secondary buffer.

	public static bool LoadWaveFile(char8* filename)
	{
		WAVEFORMATEXTENSIBLE wfx = .();
		WAVEFORMATEX waveFormat;
		DSBUFFERDESC bufferDesc;
		HRESULT result;
		ComPtr<IDirectSoundBuffer> tempBuffer = default;

		DWORD chunkSize = 0;
		DWORD chunkPosition = 0;
		DWORD filetype = 0;

		// Open the wave file
		HANDLE fileHandle = CreateFile((uint8*)filename, .FILE_GENERIC_READ, .FILE_SHARE_READ, null, .OPEN_EXISTING, 0, 0);
		if (fileHandle == INVALID_HANDLE_VALUE)
		{
			return false;
		}
		if (SetFilePointer(fileHandle, 0, null, .FILE_BEGIN) == INVALID_SET_FILE_POINTER)
		{
			return false;
		}
		// Make sure we have a RIFF wave file
		FindChunk(fileHandle, fourccRIFF, ref chunkSize, ref chunkPosition);
		ReadChunkData(fileHandle, &filetype, sizeof(DWORD), chunkPosition);
		if (filetype != fourccWAVE)
		{
			return false;
		}
		// Locate the 'fmt ' chunk, and copy its contents into a WAVEFORMATEXTENSIBLE structure.
		FindChunk(fileHandle, fourccFMT, ref chunkSize, ref chunkPosition);
		ReadChunkData(fileHandle, &wfx, chunkSize, chunkPosition);
		// Find the audio data chunk
		FindChunk(fileHandle, fourccDATA, ref chunkSize, ref chunkPosition);
		dataBufferSize = chunkSize;
		// Read the audio data from the 'data' chunk.  This is the data that needs to be copied into
		// the secondary buffer for playing
		dataBuffer = new uint8[dataBufferSize]*;
		ReadChunkData(fileHandle, dataBuffer, dataBufferSize, chunkPosition);
		CloseHandle(fileHandle);

		// Set the wave format of the secondary buffer that this wave file will be loaded onto.
		// The value of wfx.Format.nAvgBytesPerSec will be very useful to you since it gives you
		// an approximate value for how many bytes it takes to hold one second of audio data.
		waveFormat.wFormatTag =  wfx.Format.wFormatTag;
		waveFormat.nSamplesPerSec = wfx.Format.nSamplesPerSec;
		waveFormat.wBitsPerSample = wfx.Format.wBitsPerSample;
		waveFormat.nChannels = wfx.Format.nChannels;
		waveFormat.nBlockAlign = wfx.Format.nBlockAlign;
		waveFormat.nAvgBytesPerSec = wfx.Format.nAvgBytesPerSec;
		waveFormat.cbSize = 0;

		// Set the buffer description of the secondary sound buffer that the wave file will be loaded onto. 

		// In this example, we setup a buffer the same size as that of the audio data.  For the assignment, 
		// your secondary buffer should only be large enough to hold approximately four seconds of data.
		bufferDesc.dwSize = sizeof(DSBUFFERDESC);
		bufferDesc.dwFlags = DSBCAPS_CTRLVOLUME | DSBCAPS_GLOBALFOCUS | DSBCAPS_CTRLPOSITIONNOTIFY;
		bufferDesc.dwBufferBytes = dataBufferSize;
		bufferDesc.dwReserved = 0;
		bufferDesc.lpwfxFormat = &waveFormat;
		bufferDesc.guid3DAlgorithm = Guid.Empty;

		// Create a temporary sound buffer with the specific buffer settings.
		result = directSound->CreateSoundBuffer(&bufferDesc, tempBuffer.GetAddressOf(), null);
		if (FAILED(result))
		{
			return false;
		}

		// Test the buffer format against the direct sound 8 interface and create the secondary buffer.
		result = tempBuffer->QueryInterface(IDirectSoundBuffer8.IID, (void**)&secondaryBuffer);
		if (FAILED(result))
		{
			return false;
		}

		// Release the temporary buffer.
		tempBuffer.Dispose();
		tempBuffer = null;

		return true;
	}

	private static void ReleaseSecondaryBuffer()
	{
	// Release the secondary sound buffer.
		if (secondaryBuffer.Get() != null)
		{
			secondaryBuffer.Dispose();
			secondaryBuffer = null;
		}
	}

	private static bool PlayWaveFile()
	{
		HRESULT result = S_OK;
		char8* bufferPtr1 = null;
		uint32   bufferSize1 = 0;
		char8* bufferPtr2 = null;
		uint32   bufferSize2 = 0;
		//uint8* dataBufferPtr = dataBuffer;
		//DWORD soundBytesOutput = 0;
		//bool fillFirstHalf = true;
		ComPtr<IDirectSoundNotify> directSoundNotify = default;
		DSBPOSITIONNOTIFY[2] positionNotify;

		// Set position of playback at the beginning of the sound buffer.
		result = secondaryBuffer->SetCurrentPosition(0);
		if (FAILED(result))
		{
			return false;
		}

		// Set volume of the buffer to 100%.
		result = secondaryBuffer->SetVolume(DSBVOLUME_MAX);
		if (FAILED(result))
		{
			return false;
		}

		// Create an event for notification that playing has stopped.  This is only useful
		// when your audio file fits in the entire secondary buffer (as in this example).  
		// For the assignment, you are going to need notifications when the playback has reached the 
		// first quarter of the buffer or the third quarter of the buffer so that you know when 
		// you should copy more data into the secondary buffer.
		HANDLE[1] playEventHandles = .();
		playEventHandles[0] = CreateEvent(null, FALSE, FALSE, null);

		result = secondaryBuffer->QueryInterface(IDirectSoundNotify.IID, (void**)&directSoundNotify);
		if (FAILED(result))
		{
			return false;
		}
		// This notification is used to indicate that we have finished playing the buffer of audio. In
		// the assignment, you will need two different notifications as mentioned above.
		positionNotify[0].dwOffset = DSBPN_OFFSETSTOP;
		positionNotify[0].hEventNotify = playEventHandles[0];
		directSoundNotify->SetNotificationPositions(1, &positionNotify);
		directSoundNotify->Release();

		// Now we can fill our secondary buffer and play it.  In the assignment, you will not be able to fill
		// the buffer all at once since the secondary buffer will not be large enough.  Instead, you will need to
		// loop through the data that you have retrieved from the server, filling different sections of the 
		// secondary buffer as you receive notifications.

		// Lock the first part of the secondary buffer to write wave data into it. In this case, we lock the entire
		// buffer, but for the assignment, you will only want to lock the half of the buffer that is not being played.
		// You will definately want to look up the methods for the IDIRECTSOUNDBUFFER8 interface to see what these
		// methods do and what the parameters are used for.
		result = secondaryBuffer->Lock(0, dataBufferSize, (void**)&bufferPtr1, (DWORD*)&bufferSize1, (void**)&bufferPtr2, (DWORD*)&bufferSize2, 0);
		if (FAILED(result))
		{
			return false;
		}
		// Copy the wave data into the buffer. If you need to insert some silence into the buffer, insert values of 0.
		Internal.MemCpy(bufferPtr1, dataBuffer, bufferSize1);
		if (bufferPtr2 != null)
		{
			Internal.MemCpy(bufferPtr2, dataBuffer, bufferSize2);
		}
		// Unlock the secondary buffer after the data has been written to it.
		result = secondaryBuffer->Unlock((void*)bufferPtr1, bufferSize1, (void*)bufferPtr2, bufferSize2);
		if (FAILED(result))
		{
			return false;
		}
		// Play the contents of the secondary sound buffer. If you want play to go back to the start of the buffer
		// again, set the last parameter to DSBPLAY_LOOPING instead of 0.  If play is already in progress, then 
		// play will just continue.
		result = secondaryBuffer->Play(0, 0, 0);
		if (FAILED(result))
		{
			return false;
		}
		// Wait for notifications.  In this case, we only have one notification so we could use WaitForSingleObject,
		// but for the assignment you will need more than one notification, so you will need WaitForMultipleObjects
		result = (int32)WaitForMultipleObjects(1, &playEventHandles, (.)FALSE, INFINITE);
		// In this case, we have been notified that playback has finished so we can just finish. In the assignment,
		// you should use the appropriate notification to determine which part of the secondary buffer needs to be
		// filled and handle it accordingly.
		CloseHandle(playEventHandles[0]);
		return true;
	}

	public static void Main()
	{
		defer Shutdown();
		if(!Initialise()){
			Runtime.FatalError("Failed to initialize DIrectSound.");
		}

		if(!LoadWaveFile(fileName))
			Runtime.FatalError(scope $"Failed to load file '{fileName}'.");

		PlayWaveFile();

		ReleaseSecondaryBuffer();
	}
}