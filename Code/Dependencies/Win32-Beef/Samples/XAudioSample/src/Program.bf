using Win32.Foundation;
using Win32.System.Com;
using Win32;
using System;
using Win32;
using Win32.Media.Audio.XAudio2;
using Win32.Media.Audio;
using Win32.Storage.FileSystem;
using System.Collections;
using Common;

namespace XAudioSample;

// https://learn.microsoft.com/en-us/windows/win32/xaudio2/xaudio2-apis-portal


class Program
{
	private static String fileName = "media/CantinaBand60.wav";

	public static void Main()
	{
		/*
		HRESULT hr = CoInitializeEx(null, .COINIT_MULTITHREADED);
		if (FAILED(hr))
		{
			Runtime.FatalError("Failed to initialize COM.");
		}
		*/

		HRESULT hr = S_OK;

		ComPtr<IXAudio2> pXAudio2 = default;
		defer pXAudio2.Dispose();

		hr = XAudio2CreateWithVersionInfo(pXAudio2.GetAddressOf(), 0, XAUDIO2_DEFAULT_PROCESSOR, 0);

		if (FAILED(hr))
		{
			Runtime.FatalError("Failed to create XAudio2 instance.");
		}

		IXAudio2MasteringVoice* pMasterVoice = null;
		if (FAILED(hr = pXAudio2->CreateMasteringVoice(&pMasterVoice, 0, 0, 0, null, null, .AudioCategory_Other)))
			Runtime.FatalError("Failed to Mastering Voice.");

		WAVEFORMATEX wfx = .();
		XAUDIO2_BUFFER buffer = .();



		HANDLE fileHandle = CreateFile((.)fileName.CStr(), .FILE_GENERIC_READ, .FILE_SHARE_READ, null, .OPEN_EXISTING, 0, 0);
		if (fileHandle == INVALID_HANDLE_VALUE)
		{
			hr = (.)GetLastError();
			Runtime.FatalError("Failed to create file.");
		}

		if (INVALID_SET_FILE_POINTER  == SetFilePointer(fileHandle, 0, null, .FILE_BEGIN))
		{
			hr = (.)GetLastError();
			Runtime.FatalError("Failed to set file pointer.");
		}

		DWORD dwChunkSize = 0;
		DWORD dwChunkPosition = 0;
		//check the file type, should be fourccWAVE or 'XWMA'
		FindChunk(fileHandle, fourccRIFF, ref dwChunkSize, ref dwChunkPosition);

		DWORD filetype = 0;
		ReadChunkData(fileHandle, &filetype, sizeof(DWORD), dwChunkPosition);
		if (filetype != fourccWAVE)
			Runtime.FatalError(scope $"File {fileName} is not a WAVE file.");

		FindChunk(fileHandle, fourccFMT, ref dwChunkSize, ref dwChunkPosition);
		ReadChunkData(fileHandle, &wfx, dwChunkSize, dwChunkPosition);


		//fill out the audio data buffer with the contents of the fourccDATA chunk
		FindChunk(fileHandle, fourccDATA, ref dwChunkSize, ref dwChunkPosition);
		List<uint8> pDataBuffer = new .(){ Count = dwChunkSize};
		defer delete pDataBuffer;
		ReadChunkData(fileHandle, pDataBuffer.Ptr, dwChunkSize, dwChunkPosition);

		buffer.AudioBytes = dwChunkSize; //size of the audio buffer in bytes
		buffer.pAudioData = pDataBuffer.Ptr; //buffer containing audio data
		buffer.Flags = XAUDIO2_END_OF_STREAM; // tell the source voice not to expect any data after this buffer

		IXAudio2SourceVoice* pSourceVoice = null;
		if (FAILED(hr = pXAudio2->CreateSourceVoice(&pSourceVoice, (WAVEFORMATEX*)&wfx, 0, XAUDIO2_MAX_FREQ_RATIO, null, null, null)))
			Runtime.FatalError("Failed to create source voice.");

		if (FAILED(hr = pSourceVoice.SubmitSourceBuffer(&buffer, null)))
			Runtime.FatalError("Failed to submit source buffer.");

		if (FAILED(hr = pSourceVoice.Start(0, 0)))
			Runtime.FatalError("Failed to start voice.");

		Console.Write("Press [Enter] to exit ");
		Console.Read();

		pSourceVoice.Stop(0, 0);
		pSourceVoice.FlushSourceBuffers();
	}
}