using Win32.Foundation;
using Win32.System.Com;
using Win32.Graphics.Gdi;
using System;

namespace Win32.Media.WindowsMediaFormat;

#region Constants
public static
{
	public const uint32 WMT_VIDEOIMAGE_SAMPLE_INPUT_FRAME = 1;
	public const uint32 WMT_VIDEOIMAGE_SAMPLE_OUTPUT_FRAME = 2;
	public const uint32 WMT_VIDEOIMAGE_SAMPLE_USES_CURRENT_INPUT_FRAME = 4;
	public const uint32 WMT_VIDEOIMAGE_SAMPLE_USES_PREVIOUS_INPUT_FRAME = 8;
	public const uint32 WMT_VIDEOIMAGE_SAMPLE_MOTION = 1;
	public const uint32 WMT_VIDEOIMAGE_SAMPLE_ROTATION = 2;
	public const uint32 WMT_VIDEOIMAGE_SAMPLE_BLENDING = 4;
	public const uint32 WMT_VIDEOIMAGE_SAMPLE_ADV_BLENDING = 8;
	public const int32 WMT_VIDEOIMAGE_INTEGER_DENOMINATOR = 65536;
	public const uint32 WMT_VIDEOIMAGE_MAGIC_NUMBER = 491406834;
	public const uint32 WMT_VIDEOIMAGE_MAGIC_NUMBER_2 = 491406835;
	public const uint32 WMT_VIDEOIMAGE_TRANSITION_BOW_TIE = 11;
	public const uint32 WMT_VIDEOIMAGE_TRANSITION_CIRCLE = 12;
	public const uint32 WMT_VIDEOIMAGE_TRANSITION_CROSS_FADE = 13;
	public const uint32 WMT_VIDEOIMAGE_TRANSITION_DIAGONAL = 14;
	public const uint32 WMT_VIDEOIMAGE_TRANSITION_DIAMOND = 15;
	public const uint32 WMT_VIDEOIMAGE_TRANSITION_FADE_TO_COLOR = 16;
	public const uint32 WMT_VIDEOIMAGE_TRANSITION_FILLED_V = 17;
	public const uint32 WMT_VIDEOIMAGE_TRANSITION_FLIP = 18;
	public const uint32 WMT_VIDEOIMAGE_TRANSITION_INSET = 19;
	public const uint32 WMT_VIDEOIMAGE_TRANSITION_IRIS = 20;
	public const uint32 WMT_VIDEOIMAGE_TRANSITION_PAGE_ROLL = 21;
	public const uint32 WMT_VIDEOIMAGE_TRANSITION_RECTANGLE = 23;
	public const uint32 WMT_VIDEOIMAGE_TRANSITION_REVEAL = 24;
	public const uint32 WMT_VIDEOIMAGE_TRANSITION_SLIDE = 27;
	public const uint32 WMT_VIDEOIMAGE_TRANSITION_SPLIT = 29;
	public const uint32 WMT_VIDEOIMAGE_TRANSITION_STAR = 30;
	public const uint32 WMT_VIDEOIMAGE_TRANSITION_WHEEL = 31;
	public const uint32 WM_SampleExtension_ContentType_Size = 1;
	public const uint32 WM_SampleExtension_PixelAspectRatio_Size = 2;
	public const uint32 WM_SampleExtension_Timecode_Size = 14;
	public const uint32 WM_SampleExtension_SampleDuration_Size = 2;
	public const uint32 WM_SampleExtension_ChromaLocation_Size = 1;
	public const uint32 WM_SampleExtension_ColorSpaceInfo_Size = 3;
	public const uint32 WM_CT_REPEAT_FIRST_FIELD = 16;
	public const uint32 WM_CT_BOTTOM_FIELD_FIRST = 32;
	public const uint32 WM_CT_TOP_FIELD_FIRST = 64;
	public const uint32 WM_CT_INTERLACED = 128;
	public const uint32 WM_CL_INTERLACED420 = 0;
	public const uint32 WM_CL_PROGRESSIVE420 = 1;
	public const uint32 WM_MAX_VIDEO_STREAMS = 63;
	public const uint32 WM_MAX_STREAMS = 63;
	public const uint32 WMDRM_IMPORT_INIT_STRUCT_DEFINED = 1;
	public const uint32 DRM_OPL_TYPES = 1;
	public const uint32 g_dwWMSpecialAttributes = 20;
	public const String g_wszWMDuration = "Duration";
	public const String g_wszWMBitrate = "Bitrate";
	public const String g_wszWMSeekable = "Seekable";
	public const String g_wszWMStridable = "Stridable";
	public const String g_wszWMBroadcast = "Broadcast";
	public const String g_wszWMProtected = "Is_Protected";
	public const String g_wszWMTrusted = "Is_Trusted";
	public const String g_wszWMSignature_Name = "Signature_Name";
	public const String g_wszWMHasAudio = "HasAudio";
	public const String g_wszWMHasImage = "HasImage";
	public const String g_wszWMHasScript = "HasScript";
	public const String g_wszWMHasVideo = "HasVideo";
	public const String g_wszWMCurrentBitrate = "CurrentBitrate";
	public const String g_wszWMOptimalBitrate = "OptimalBitrate";
	public const String g_wszWMHasAttachedImages = "HasAttachedImages";
	public const String g_wszWMSkipBackward = "Can_Skip_Backward";
	public const String g_wszWMSkipForward = "Can_Skip_Forward";
	public const String g_wszWMNumberOfFrames = "NumberOfFrames";
	public const String g_wszWMFileSize = "FileSize";
	public const String g_wszWMHasArbitraryDataStream = "HasArbitraryDataStream";
	public const String g_wszWMHasFileTransferStream = "HasFileTransferStream";
	public const String g_wszWMContainerFormat = "WM/ContainerFormat";
	public const uint32 g_dwWMContentAttributes = 5;
	public const String g_wszWMTitle = "Title";
	public const String g_wszWMTitleSort = "TitleSort";
	public const String g_wszWMAuthor = "Author";
	public const String g_wszWMAuthorSort = "AuthorSort";
	public const String g_wszWMDescription = "Description";
	public const String g_wszWMRating = "Rating";
	public const String g_wszWMCopyright = "Copyright";
	public const String g_wszWMUse_DRM = "Use_DRM";
	public const String g_wszWMDRM_Flags = "DRM_Flags";
	public const String g_wszWMDRM_Level = "DRM_Level";
	public const String g_wszWMUse_Advanced_DRM = "Use_Advanced_DRM";
	public const String g_wszWMDRM_KeySeed = "DRM_KeySeed";
	public const String g_wszWMDRM_KeyID = "DRM_KeyID";
	public const String g_wszWMDRM_ContentID = "DRM_ContentID";
	public const String g_wszWMDRM_SourceID = "DRM_SourceID";
	public const String g_wszWMDRM_IndividualizedVersion = "DRM_IndividualizedVersion";
	public const String g_wszWMDRM_LicenseAcqURL = "DRM_LicenseAcqURL";
	public const String g_wszWMDRM_V1LicenseAcqURL = "DRM_V1LicenseAcqURL";
	public const String g_wszWMDRM_HeaderSignPrivKey = "DRM_HeaderSignPrivKey";
	public const String g_wszWMDRM_LASignaturePrivKey = "DRM_LASignaturePrivKey";
	public const String g_wszWMDRM_LASignatureCert = "DRM_LASignatureCert";
	public const String g_wszWMDRM_LASignatureLicSrvCert = "DRM_LASignatureLicSrvCert";
	public const String g_wszWMDRM_LASignatureRootCert = "DRM_LASignatureRootCert";
	public const String g_wszWMAlbumTitle = "WM/AlbumTitle";
	public const String g_wszWMAlbumTitleSort = "WM/AlbumTitleSort";
	public const String g_wszWMTrack = "WM/Track";
	public const String g_wszWMPromotionURL = "WM/PromotionURL";
	public const String g_wszWMAlbumCoverURL = "WM/AlbumCoverURL";
	public const String g_wszWMGenre = "WM/Genre";
	public const String g_wszWMYear = "WM/Year";
	public const String g_wszWMGenreID = "WM/GenreID";
	public const String g_wszWMMCDI = "WM/MCDI";
	public const String g_wszWMComposer = "WM/Composer";
	public const String g_wszWMComposerSort = "WM/ComposerSort";
	public const String g_wszWMLyrics = "WM/Lyrics";
	public const String g_wszWMTrackNumber = "WM/TrackNumber";
	public const String g_wszWMToolName = "WM/ToolName";
	public const String g_wszWMToolVersion = "WM/ToolVersion";
	public const String g_wszWMIsVBR = "IsVBR";
	public const String g_wszWMAlbumArtist = "WM/AlbumArtist";
	public const String g_wszWMAlbumArtistSort = "WM/AlbumArtistSort";
	public const String g_wszWMBannerImageType = "BannerImageType";
	public const String g_wszWMBannerImageData = "BannerImageData";
	public const String g_wszWMBannerImageURL = "BannerImageURL";
	public const String g_wszWMCopyrightURL = "CopyrightURL";
	public const String g_wszWMAspectRatioX = "AspectRatioX";
	public const String g_wszWMAspectRatioY = "AspectRatioY";
	public const String g_wszASFLeakyBucketPairs = "ASFLeakyBucketPairs";
	public const uint32 g_dwWMNSCAttributes = 5;
	public const String g_wszWMNSCName = "NSC_Name";
	public const String g_wszWMNSCAddress = "NSC_Address";
	public const String g_wszWMNSCPhone = "NSC_Phone";
	public const String g_wszWMNSCEmail = "NSC_Email";
	public const String g_wszWMNSCDescription = "NSC_Description";
	public const String g_wszWMWriter = "WM/Writer";
	public const String g_wszWMConductor = "WM/Conductor";
	public const String g_wszWMProducer = "WM/Producer";
	public const String g_wszWMDirector = "WM/Director";
	public const String g_wszWMContentGroupDescription = "WM/ContentGroupDescription";
	public const String g_wszWMSubTitle = "WM/SubTitle";
	public const String g_wszWMPartOfSet = "WM/PartOfSet";
	public const String g_wszWMProtectionType = "WM/ProtectionType";
	public const String g_wszWMVideoHeight = "WM/VideoHeight";
	public const String g_wszWMVideoWidth = "WM/VideoWidth";
	public const String g_wszWMVideoFrameRate = "WM/VideoFrameRate";
	public const String g_wszWMMediaClassPrimaryID = "WM/MediaClassPrimaryID";
	public const String g_wszWMMediaClassSecondaryID = "WM/MediaClassSecondaryID";
	public const String g_wszWMPeriod = "WM/Period";
	public const String g_wszWMCategory = "WM/Category";
	public const String g_wszWMPicture = "WM/Picture";
	public const String g_wszWMLyrics_Synchronised = "WM/Lyrics_Synchronised";
	public const String g_wszWMOriginalLyricist = "WM/OriginalLyricist";
	public const String g_wszWMOriginalArtist = "WM/OriginalArtist";
	public const String g_wszWMOriginalAlbumTitle = "WM/OriginalAlbumTitle";
	public const String g_wszWMOriginalReleaseYear = "WM/OriginalReleaseYear";
	public const String g_wszWMOriginalFilename = "WM/OriginalFilename";
	public const String g_wszWMPublisher = "WM/Publisher";
	public const String g_wszWMEncodedBy = "WM/EncodedBy";
	public const String g_wszWMEncodingSettings = "WM/EncodingSettings";
	public const String g_wszWMEncodingTime = "WM/EncodingTime";
	public const String g_wszWMAuthorURL = "WM/AuthorURL";
	public const String g_wszWMUserWebURL = "WM/UserWebURL";
	public const String g_wszWMAudioFileURL = "WM/AudioFileURL";
	public const String g_wszWMAudioSourceURL = "WM/AudioSourceURL";
	public const String g_wszWMLanguage = "WM/Language";
	public const String g_wszWMParentalRating = "WM/ParentalRating";
	public const String g_wszWMBeatsPerMinute = "WM/BeatsPerMinute";
	public const String g_wszWMInitialKey = "WM/InitialKey";
	public const String g_wszWMMood = "WM/Mood";
	public const String g_wszWMText = "WM/Text";
	public const String g_wszWMDVDID = "WM/DVDID";
	public const String g_wszWMWMContentID = "WM/WMContentID";
	public const String g_wszWMWMCollectionID = "WM/WMCollectionID";
	public const String g_wszWMWMCollectionGroupID = "WM/WMCollectionGroupID";
	public const String g_wszWMUniqueFileIdentifier = "WM/UniqueFileIdentifier";
	public const String g_wszWMModifiedBy = "WM/ModifiedBy";
	public const String g_wszWMRadioStationName = "WM/RadioStationName";
	public const String g_wszWMRadioStationOwner = "WM/RadioStationOwner";
	public const String g_wszWMPlaylistDelay = "WM/PlaylistDelay";
	public const String g_wszWMCodec = "WM/Codec";
	public const String g_wszWMDRM = "WM/DRM";
	public const String g_wszWMISRC = "WM/ISRC";
	public const String g_wszWMProvider = "WM/Provider";
	public const String g_wszWMProviderRating = "WM/ProviderRating";
	public const String g_wszWMProviderStyle = "WM/ProviderStyle";
	public const String g_wszWMContentDistributor = "WM/ContentDistributor";
	public const String g_wszWMSubscriptionContentID = "WM/SubscriptionContentID";
	public const String g_wszWMWMADRCPeakReference = "WM/WMADRCPeakReference";
	public const String g_wszWMWMADRCPeakTarget = "WM/WMADRCPeakTarget";
	public const String g_wszWMWMADRCAverageReference = "WM/WMADRCAverageReference";
	public const String g_wszWMWMADRCAverageTarget = "WM/WMADRCAverageTarget";
	public const String g_wszWMStreamTypeInfo = "WM/StreamTypeInfo";
	public const String g_wszWMPeakBitrate = "WM/PeakBitrate";
	public const String g_wszWMASFPacketCount = "WM/ASFPacketCount";
	public const String g_wszWMASFSecurityObjectsSize = "WM/ASFSecurityObjectsSize";
	public const String g_wszWMSharedUserRating = "WM/SharedUserRating";
	public const String g_wszWMSubTitleDescription = "WM/SubTitleDescription";
	public const String g_wszWMMediaCredits = "WM/MediaCredits";
	public const String g_wszWMParentalRatingReason = "WM/ParentalRatingReason";
	public const String g_wszWMOriginalReleaseTime = "WM/OriginalReleaseTime";
	public const String g_wszWMMediaStationCallSign = "WM/MediaStationCallSign";
	public const String g_wszWMMediaStationName = "WM/MediaStationName";
	public const String g_wszWMMediaNetworkAffiliation = "WM/MediaNetworkAffiliation";
	public const String g_wszWMMediaOriginalChannel = "WM/MediaOriginalChannel";
	public const String g_wszWMMediaOriginalBroadcastDateTime = "WM/MediaOriginalBroadcastDateTime";
	public const String g_wszWMMediaIsStereo = "WM/MediaIsStereo";
	public const String g_wszWMVideoClosedCaptioning = "WM/VideoClosedCaptioning";
	public const String g_wszWMMediaIsRepeat = "WM/MediaIsRepeat";
	public const String g_wszWMMediaIsLive = "WM/MediaIsLive";
	public const String g_wszWMMediaIsTape = "WM/MediaIsTape";
	public const String g_wszWMMediaIsDelay = "WM/MediaIsDelay";
	public const String g_wszWMMediaIsSubtitled = "WM/MediaIsSubtitled";
	public const String g_wszWMMediaIsPremiere = "WM/MediaIsPremiere";
	public const String g_wszWMMediaIsFinale = "WM/MediaIsFinale";
	public const String g_wszWMMediaIsSAP = "WM/MediaIsSAP";
	public const String g_wszWMProviderCopyright = "WM/ProviderCopyright";
	public const String g_wszWMISAN = "WM/ISAN";
	public const String g_wszWMADID = "WM/ADID";
	public const String g_wszWMWMShadowFileSourceFileType = "WM/WMShadowFileSourceFileType";
	public const String g_wszWMWMShadowFileSourceDRMType = "WM/WMShadowFileSourceDRMType";
	public const String g_wszWMWMCPDistributor = "WM/WMCPDistributor";
	public const String g_wszWMWMCPDistributorID = "WM/WMCPDistributorID";
	public const String g_wszWMSeasonNumber = "WM/SeasonNumber";
	public const String g_wszWMEpisodeNumber = "WM/EpisodeNumber";
	public const String g_wszEarlyDataDelivery = "EarlyDataDelivery";
	public const String g_wszJustInTimeDecode = "JustInTimeDecode";
	public const String g_wszSingleOutputBuffer = "SingleOutputBuffer";
	public const String g_wszSoftwareScaling = "SoftwareScaling";
	public const String g_wszDeliverOnReceive = "DeliverOnReceive";
	public const String g_wszScrambledAudio = "ScrambledAudio";
	public const String g_wszDedicatedDeliveryThread = "DedicatedDeliveryThread";
	public const String g_wszEnableDiscreteOutput = "EnableDiscreteOutput";
	public const String g_wszSpeakerConfig = "SpeakerConfig";
	public const String g_wszDynamicRangeControl = "DynamicRangeControl";
	public const String g_wszAllowInterlacedOutput = "AllowInterlacedOutput";
	public const String g_wszVideoSampleDurations = "VideoSampleDurations";
	public const String g_wszStreamLanguage = "StreamLanguage";
	public const String g_wszEnableWMAProSPDIFOutput = "EnableWMAProSPDIFOutput";
	public const String g_wszDeinterlaceMode = "DeinterlaceMode";
	public const String g_wszInitialPatternForInverseTelecine = "InitialPatternForInverseTelecine";
	public const String g_wszJPEGCompressionQuality = "JPEGCompressionQuality";
	public const String g_wszWatermarkCLSID = "WatermarkCLSID";
	public const String g_wszWatermarkConfig = "WatermarkConfig";
	public const String g_wszInterlacedCoding = "InterlacedCoding";
	public const String g_wszFixedFrameRate = "FixedFrameRate";
	public const String g_wszOriginalSourceFormatTag = "_SOURCEFORMATTAG";
	public const String g_wszOriginalWaveFormat = "_ORIGINALWAVEFORMAT";
	public const String g_wszEDL = "_EDL";
	public const String g_wszComplexity = "_COMPLEXITYEX";
	public const String g_wszDecoderComplexityRequested = "_DECODERCOMPLEXITYPROFILE";
	public const String g_wszReloadIndexOnSeek = "ReloadIndexOnSeek";
	public const String g_wszStreamNumIndexObjects = "StreamNumIndexObjects";
	public const String g_wszFailSeekOnError = "FailSeekOnError";
	public const String g_wszPermitSeeksBeyondEndOfStream = "PermitSeeksBeyondEndOfStream";
	public const String g_wszUsePacketAtSeekPoint = "UsePacketAtSeekPoint";
	public const String g_wszSourceBufferTime = "SourceBufferTime";
	public const String g_wszSourceMaxBytesAtOnce = "SourceMaxBytesAtOnce";
	public const String g_wszVBREnabled = "_VBRENABLED";
	public const String g_wszVBRQuality = "_VBRQUALITY";
	public const String g_wszVBRBitrateMax = "_RMAX";
	public const String g_wszVBRBufferWindowMax = "_BMAX";
	public const String g_wszVBRPeak = "VBR Peak";
	public const String g_wszBufferAverage = "Buffer Average";
	public const String g_wszComplexityMax = "_COMPLEXITYEXMAX";
	public const String g_wszComplexityOffline = "_COMPLEXITYEXOFFLINE";
	public const String g_wszComplexityLive = "_COMPLEXITYEXLIVE";
	public const String g_wszIsVBRSupported = "_ISVBRSUPPORTED";
	public const String g_wszNumPasses = "_PASSESUSED";
	public const String g_wszMusicSpeechClassMode = "MusicSpeechClassMode";
	public const String g_wszMusicClassMode = "MusicClassMode";
	public const String g_wszSpeechClassMode = "SpeechClassMode";
	public const String g_wszMixedClassMode = "MixedClassMode";
	public const String g_wszSpeechCaps = "SpeechFormatCap";
	public const String g_wszPeakValue = "PeakValue";
	public const String g_wszAverageLevel = "AverageLevel";
	public const String g_wszFold6To2Channels3 = "Fold6To2Channels3";
	public const String g_wszFoldToChannelsTemplate = "Fold%luTo%luChannels%lu";
	public const String g_wszDeviceConformanceTemplate = "DeviceConformanceTemplate";
	public const String g_wszEnableFrameInterpolation = "EnableFrameInterpolation";
	public const String g_wszNeedsPreviousSample = "NeedsPreviousSample";
	public const String g_wszWMIsCompilation = "WM/IsCompilation";
	public const Guid WMMEDIASUBTYPE_Base = .(0x00000000, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIATYPE_Video = .(0x73646976, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_RGB1 = .(0xe436eb78, 0x524f, 0x11ce, 0x9f, 0x53, 0x00, 0x20, 0xaf, 0x0b, 0xa7, 0x70);
	public const Guid WMMEDIASUBTYPE_RGB4 = .(0xe436eb79, 0x524f, 0x11ce, 0x9f, 0x53, 0x00, 0x20, 0xaf, 0x0b, 0xa7, 0x70);
	public const Guid WMMEDIASUBTYPE_RGB8 = .(0xe436eb7a, 0x524f, 0x11ce, 0x9f, 0x53, 0x00, 0x20, 0xaf, 0x0b, 0xa7, 0x70);
	public const Guid WMMEDIASUBTYPE_RGB565 = .(0xe436eb7b, 0x524f, 0x11ce, 0x9f, 0x53, 0x00, 0x20, 0xaf, 0x0b, 0xa7, 0x70);
	public const Guid WMMEDIASUBTYPE_RGB555 = .(0xe436eb7c, 0x524f, 0x11ce, 0x9f, 0x53, 0x00, 0x20, 0xaf, 0x0b, 0xa7, 0x70);
	public const Guid WMMEDIASUBTYPE_RGB24 = .(0xe436eb7d, 0x524f, 0x11ce, 0x9f, 0x53, 0x00, 0x20, 0xaf, 0x0b, 0xa7, 0x70);
	public const Guid WMMEDIASUBTYPE_RGB32 = .(0xe436eb7e, 0x524f, 0x11ce, 0x9f, 0x53, 0x00, 0x20, 0xaf, 0x0b, 0xa7, 0x70);
	public const Guid WMMEDIASUBTYPE_I420 = .(0x30323449, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_IYUV = .(0x56555949, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_YV12 = .(0x32315659, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_YUY2 = .(0x32595559, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_P422 = .(0x32323450, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_UYVY = .(0x59565955, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_YVYU = .(0x55595659, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_YVU9 = .(0x39555659, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_VIDEOIMAGE = .(0x1d4a45f2, 0xe5f6, 0x4b44, 0x83, 0x88, 0xf0, 0xae, 0x5c, 0x0e, 0x0c, 0x37);
	public const Guid WMMEDIASUBTYPE_MP43 = .(0x3334504d, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_MP4S = .(0x5334504d, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_M4S2 = .(0x3253344d, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_WMV1 = .(0x31564d57, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_WMV2 = .(0x32564d57, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_MSS1 = .(0x3153534d, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_MPEG2_VIDEO = .(0xe06d8026, 0xdb46, 0x11cf, 0xb4, 0xd1, 0x00, 0x80, 0x5f, 0x6c, 0xbb, 0xea);
	public const Guid WMMEDIATYPE_Audio = .(0x73647561, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_PCM = .(0x00000001, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_DRM = .(0x00000009, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_WMAudioV9 = .(0x00000162, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_WMAudio_Lossless = .(0x00000163, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_MSS2 = .(0x3253534d, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_WMSP1 = .(0x0000000a, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_WMSP2 = .(0x0000000b, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_WMV3 = .(0x33564d57, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_WMVP = .(0x50564d57, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_WVP2 = .(0x32505657, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_WMVA = .(0x41564d57, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_WVC1 = .(0x31435657, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_WMAudioV8 = .(0x00000161, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_WMAudioV7 = .(0x00000161, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_WMAudioV2 = .(0x00000161, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_ACELPnet = .(0x00000130, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_MP3 = .(0x00000055, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIASUBTYPE_WebStream = .(0x776257d4, 0xc627, 0x41cb, 0x8f, 0x81, 0x7a, 0xc7, 0xff, 0x1c, 0x40, 0xcc);
	public const Guid WMMEDIATYPE_Script = .(0x73636d64, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid WMMEDIATYPE_Image = .(0x34a50fd8, 0x8aa5, 0x4386, 0x81, 0xfe, 0xa0, 0xef, 0xe0, 0x48, 0x8e, 0x31);
	public const Guid WMMEDIATYPE_FileTransfer = .(0xd9e47579, 0x930e, 0x4427, 0xad, 0xfc, 0xad, 0x80, 0xf2, 0x90, 0xe4, 0x70);
	public const Guid WMMEDIATYPE_Text = .(0x9bba1ea7, 0x5ab2, 0x4829, 0xba, 0x57, 0x09, 0x40, 0x20, 0x9b, 0xcf, 0x3e);
	public const Guid WMFORMAT_VideoInfo = .(0x05589f80, 0xc356, 0x11ce, 0xbf, 0x01, 0x00, 0xaa, 0x00, 0x55, 0x59, 0x5a);
	public const Guid WMFORMAT_MPEG2Video = .(0xe06d80e3, 0xdb46, 0x11cf, 0xb4, 0xd1, 0x00, 0x80, 0x5f, 0x6c, 0xbb, 0xea);
	public const Guid WMFORMAT_WaveFormatEx = .(0x05589f81, 0xc356, 0x11ce, 0xbf, 0x01, 0x00, 0xaa, 0x00, 0x55, 0x59, 0x5a);
	public const Guid WMFORMAT_Script = .(0x5c8510f2, 0xdebe, 0x4ca7, 0xbb, 0xa5, 0xf0, 0x7a, 0x10, 0x4f, 0x8d, 0xff);
	public const Guid WMFORMAT_WebStream = .(0xda1e6b13, 0x8359, 0x4050, 0xb3, 0x98, 0x38, 0x8e, 0x96, 0x5b, 0xf0, 0x0c);
	public const Guid WMSCRIPTTYPE_TwoStrings = .(0x82f38a70, 0xc29f, 0x11d1, 0x97, 0xad, 0x00, 0xa0, 0xc9, 0x5e, 0xa8, 0x50);
	public const Guid WM_SampleExtensionGUID_OutputCleanPoint = .(0xf72a3c6f, 0x6eb4, 0x4ebc, 0xb1, 0x92, 0x09, 0xad, 0x97, 0x59, 0xe8, 0x28);
	public const Guid WM_SampleExtensionGUID_Timecode = .(0x399595ec, 0x8667, 0x4e2d, 0x8f, 0xdb, 0x98, 0x81, 0x4c, 0xe7, 0x6c, 0x1e);
	public const Guid WM_SampleExtensionGUID_ChromaLocation = .(0x4c5acca0, 0x9276, 0x4b2c, 0x9e, 0x4c, 0xa0, 0xed, 0xef, 0xdd, 0x21, 0x7e);
	public const Guid WM_SampleExtensionGUID_ColorSpaceInfo = .(0xf79ada56, 0x30eb, 0x4f2b, 0x9f, 0x7a, 0xf2, 0x4b, 0x13, 0x9a, 0x11, 0x57);
	public const Guid WM_SampleExtensionGUID_UserDataInfo = .(0x732bb4fa, 0x78be, 0x4549, 0x99, 0xbd, 0x02, 0xdb, 0x1a, 0x55, 0xb7, 0xa8);
	public const Guid WM_SampleExtensionGUID_FileName = .(0xe165ec0e, 0x19ed, 0x45d7, 0xb4, 0xa7, 0x25, 0xcb, 0xd1, 0xe2, 0x8e, 0x9b);
	public const Guid WM_SampleExtensionGUID_ContentType = .(0xd590dc20, 0x07bc, 0x436c, 0x9c, 0xf7, 0xf3, 0xbb, 0xfb, 0xf1, 0xa4, 0xdc);
	public const Guid WM_SampleExtensionGUID_PixelAspectRatio = .(0x1b1ee554, 0xf9ea, 0x4bc8, 0x82, 0x1a, 0x37, 0x6b, 0x74, 0xe4, 0xc4, 0xb8);
	public const Guid WM_SampleExtensionGUID_SampleDuration = .(0xc6bd9450, 0x867f, 0x4907, 0x83, 0xa3, 0xc7, 0x79, 0x21, 0xb7, 0x33, 0xad);
	public const Guid WM_SampleExtensionGUID_SampleProtectionSalt = .(0x5403deee, 0xb9ee, 0x438f, 0xaa, 0x83, 0x38, 0x04, 0x99, 0x7e, 0x56, 0x9d);
	public const Guid CLSID_WMMUTEX_Language = .(0xd6e22a00, 0x35da, 0x11d1, 0x90, 0x34, 0x00, 0xa0, 0xc9, 0x03, 0x49, 0xbe);
	public const Guid CLSID_WMMUTEX_Bitrate = .(0xd6e22a01, 0x35da, 0x11d1, 0x90, 0x34, 0x00, 0xa0, 0xc9, 0x03, 0x49, 0xbe);
	public const Guid CLSID_WMMUTEX_Presentation = .(0xd6e22a02, 0x35da, 0x11d1, 0x90, 0x34, 0x00, 0xa0, 0xc9, 0x03, 0x49, 0xbe);
	public const Guid CLSID_WMMUTEX_Unknown = .(0xd6e22a03, 0x35da, 0x11d1, 0x90, 0x34, 0x00, 0xa0, 0xc9, 0x03, 0x49, 0xbe);
	public const Guid CLSID_WMBandwidthSharing_Exclusive = .(0xaf6060aa, 0x5197, 0x11d2, 0xb6, 0xaf, 0x00, 0xc0, 0x4f, 0xd9, 0x08, 0xe9);
	public const Guid CLSID_WMBandwidthSharing_Partial = .(0xaf6060ab, 0x5197, 0x11d2, 0xb6, 0xaf, 0x00, 0xc0, 0x4f, 0xd9, 0x08, 0xe9);
	public const Guid WMT_DMOCATEGORY_AUDIO_WATERMARK = .(0x65221c5a, 0xfa75, 0x4b39, 0xb5, 0x0c, 0x06, 0xc3, 0x36, 0xb6, 0xa3, 0xef);
	public const Guid WMT_DMOCATEGORY_VIDEO_WATERMARK = .(0x187cc922, 0x8efc, 0x4404, 0x9d, 0xaf, 0x63, 0xf4, 0x83, 0x0d, 0xf1, 0xbc);
	public const Guid CLSID_ClientNetManager = .(0xcd12a3ce, 0x9c42, 0x11d2, 0xbe, 0xed, 0x00, 0x60, 0x08, 0x2f, 0x20, 0x54);
}
#endregion

#region Enums

[AllowDuplicates]
public enum _AM_ASFWRITERCONFIG_PARAM : int32
{
	AM_CONFIGASFWRITER_PARAM_AUTOINDEX = 1,
	AM_CONFIGASFWRITER_PARAM_MULTIPASS = 2,
	AM_CONFIGASFWRITER_PARAM_DONTCOMPRESS = 3,
}


[AllowDuplicates]
public enum WEBSTREAM_SAMPLE_TYPE : int32
{
	WEBSTREAM_SAMPLE_TYPE_FILE = 1,
	WEBSTREAM_SAMPLE_TYPE_RENDER = 2,
}


[AllowDuplicates]
public enum WM_SF_TYPE : int32
{
	WM_SF_CLEANPOINT = 1,
	WM_SF_DISCONTINUITY = 2,
	WM_SF_DATALOSS = 4,
}


[AllowDuplicates]
public enum WM_SFEX_TYPE : int32
{
	WM_SFEX_NOTASYNCPOINT = 2,
	WM_SFEX_DATALOSS = 4,
}


[AllowDuplicates]
public enum WMT_STATUS : int32
{
	WMT_ERROR = 0,
	WMT_OPENED = 1,
	WMT_BUFFERING_START = 2,
	WMT_BUFFERING_STOP = 3,
	WMT_EOF = 4,
	WMT_END_OF_FILE = 4,
	WMT_END_OF_SEGMENT = 5,
	WMT_END_OF_STREAMING = 6,
	WMT_LOCATING = 7,
	WMT_CONNECTING = 8,
	WMT_NO_RIGHTS = 9,
	WMT_MISSING_CODEC = 10,
	WMT_STARTED = 11,
	WMT_STOPPED = 12,
	WMT_CLOSED = 13,
	WMT_STRIDING = 14,
	WMT_TIMER = 15,
	WMT_INDEX_PROGRESS = 16,
	WMT_SAVEAS_START = 17,
	WMT_SAVEAS_STOP = 18,
	WMT_NEW_SOURCEFLAGS = 19,
	WMT_NEW_METADATA = 20,
	WMT_BACKUPRESTORE_BEGIN = 21,
	WMT_SOURCE_SWITCH = 22,
	WMT_ACQUIRE_LICENSE = 23,
	WMT_INDIVIDUALIZE = 24,
	WMT_NEEDS_INDIVIDUALIZATION = 25,
	WMT_NO_RIGHTS_EX = 26,
	WMT_BACKUPRESTORE_END = 27,
	WMT_BACKUPRESTORE_CONNECTING = 28,
	WMT_BACKUPRESTORE_DISCONNECTING = 29,
	WMT_ERROR_WITHURL = 30,
	WMT_RESTRICTED_LICENSE = 31,
	WMT_CLIENT_CONNECT = 32,
	WMT_CLIENT_DISCONNECT = 33,
	WMT_NATIVE_OUTPUT_PROPS_CHANGED = 34,
	WMT_RECONNECT_START = 35,
	WMT_RECONNECT_END = 36,
	WMT_CLIENT_CONNECT_EX = 37,
	WMT_CLIENT_DISCONNECT_EX = 38,
	WMT_SET_FEC_SPAN = 39,
	WMT_PREROLL_READY = 40,
	WMT_PREROLL_COMPLETE = 41,
	WMT_CLIENT_PROPERTIES = 42,
	WMT_LICENSEURL_SIGNATURE_STATE = 43,
	WMT_INIT_PLAYLIST_BURN = 44,
	WMT_TRANSCRYPTOR_INIT = 45,
	WMT_TRANSCRYPTOR_SEEKED = 46,
	WMT_TRANSCRYPTOR_READ = 47,
	WMT_TRANSCRYPTOR_CLOSED = 48,
	WMT_PROXIMITY_RESULT = 49,
	WMT_PROXIMITY_COMPLETED = 50,
	WMT_CONTENT_ENABLER = 51,
}


[AllowDuplicates]
public enum WMT_STREAM_SELECTION : int32
{
	WMT_OFF = 0,
	WMT_CLEANPOINT_ONLY = 1,
	WMT_ON = 2,
}


[AllowDuplicates]
public enum WMT_IMAGE_TYPE : int32
{
	WMT_IT_NONE = 0,
	WMT_IT_BITMAP = 1,
	WMT_IT_JPEG = 2,
	WMT_IT_GIF = 3,
}


[AllowDuplicates]
public enum WMT_ATTR_DATATYPE : int32
{
	WMT_TYPE_DWORD = 0,
	WMT_TYPE_STRING = 1,
	WMT_TYPE_BINARY = 2,
	WMT_TYPE_BOOL = 3,
	WMT_TYPE_QWORD = 4,
	WMT_TYPE_WORD = 5,
	WMT_TYPE_GUID = 6,
}


[AllowDuplicates]
public enum WMT_ATTR_IMAGETYPE : int32
{
	WMT_IMAGETYPE_BITMAP = 1,
	WMT_IMAGETYPE_JPEG = 2,
	WMT_IMAGETYPE_GIF = 3,
}


[AllowDuplicates]
public enum WMT_VERSION : int32
{
	WMT_VER_4_0 = 262144,
	WMT_VER_7_0 = 458752,
	WMT_VER_8_0 = 524288,
	WMT_VER_9_0 = 589824,
}


[AllowDuplicates]
public enum WMT_STORAGE_FORMAT : int32
{
	WMT_Storage_Format_MP3 = 0,
	WMT_Storage_Format_V1 = 1,
}


[AllowDuplicates]
public enum WMT_DRMLA_TRUST : int32
{
	WMT_DRMLA_UNTRUSTED = 0,
	WMT_DRMLA_TRUSTED = 1,
	WMT_DRMLA_TAMPERED = 2,
}


[AllowDuplicates]
public enum WMT_TRANSPORT_TYPE : int32
{
	WMT_Transport_Type_Unreliable = 0,
	WMT_Transport_Type_Reliable = 1,
}


[AllowDuplicates]
public enum WMT_NET_PROTOCOL : int32
{
	WMT_PROTOCOL_HTTP = 0,
}


[AllowDuplicates]
public enum WMT_PLAY_MODE : int32
{
	WMT_PLAY_MODE_AUTOSELECT = 0,
	WMT_PLAY_MODE_LOCAL = 1,
	WMT_PLAY_MODE_DOWNLOAD = 2,
	WMT_PLAY_MODE_STREAMING = 3,
}


[AllowDuplicates]
public enum WMT_PROXY_SETTINGS : int32
{
	WMT_PROXY_SETTING_NONE = 0,
	WMT_PROXY_SETTING_MANUAL = 1,
	WMT_PROXY_SETTING_AUTO = 2,
	WMT_PROXY_SETTING_BROWSER = 3,
	WMT_PROXY_SETTING_MAX = 4,
}


[AllowDuplicates]
public enum WMT_CODEC_INFO_TYPE : int32
{
	WMT_CODECINFO_AUDIO = 0,
	WMT_CODECINFO_VIDEO = 1,
	WMT_CODECINFO_UNKNOWN = -1,
}


[AllowDuplicates]
public enum WM_DM_INTERLACED_TYPE : int32
{
	WM_DM_NOTINTERLACED = 0,
	WM_DM_DEINTERLACE_NORMAL = 1,
	WM_DM_DEINTERLACE_HALFSIZE = 2,
	WM_DM_DEINTERLACE_HALFSIZEDOUBLERATE = 3,
	WM_DM_DEINTERLACE_INVERSETELECINE = 4,
	WM_DM_DEINTERLACE_VERTICALHALFSIZEDOUBLERATE = 5,
}


[AllowDuplicates]
public enum WM_DM_IT_FIRST_FRAME_COHERENCY : int32
{
	WM_DM_IT_DISABLE_COHERENT_MODE = 0,
	WM_DM_IT_FIRST_FRAME_IN_CLIP_IS_AA_TOP = 1,
	WM_DM_IT_FIRST_FRAME_IN_CLIP_IS_BB_TOP = 2,
	WM_DM_IT_FIRST_FRAME_IN_CLIP_IS_BC_TOP = 3,
	WM_DM_IT_FIRST_FRAME_IN_CLIP_IS_CD_TOP = 4,
	WM_DM_IT_FIRST_FRAME_IN_CLIP_IS_DD_TOP = 5,
	WM_DM_IT_FIRST_FRAME_IN_CLIP_IS_AA_BOTTOM = 6,
	WM_DM_IT_FIRST_FRAME_IN_CLIP_IS_BB_BOTTOM = 7,
	WM_DM_IT_FIRST_FRAME_IN_CLIP_IS_BC_BOTTOM = 8,
	WM_DM_IT_FIRST_FRAME_IN_CLIP_IS_CD_BOTTOM = 9,
	WM_DM_IT_FIRST_FRAME_IN_CLIP_IS_DD_BOTTOM = 10,
}


[AllowDuplicates]
public enum WMT_OFFSET_FORMAT : int32
{
	WMT_OFFSET_FORMAT_100NS = 0,
	WMT_OFFSET_FORMAT_FRAME_NUMBERS = 1,
	WMT_OFFSET_FORMAT_PLAYLIST_OFFSET = 2,
	WMT_OFFSET_FORMAT_TIMECODE = 3,
	WMT_OFFSET_FORMAT_100NS_APPROXIMATE = 4,
}


[AllowDuplicates]
public enum WMT_INDEXER_TYPE : int32
{
	WMT_IT_PRESENTATION_TIME = 0,
	WMT_IT_FRAME_NUMBERS = 1,
	WMT_IT_TIMECODE = 2,
}


[AllowDuplicates]
public enum WMT_INDEX_TYPE : int32
{
	WMT_IT_NEAREST_DATA_UNIT = 1,
	WMT_IT_NEAREST_OBJECT = 2,
	WMT_IT_NEAREST_CLEAN_POINT = 3,
}


[AllowDuplicates]
public enum WMT_FILESINK_MODE : int32
{
	WMT_FM_SINGLE_BUFFERS = 1,
	WMT_FM_FILESINK_DATA_UNITS = 2,
	WMT_FM_FILESINK_UNBUFFERED = 4,
}


[AllowDuplicates]
public enum WMT_MUSICSPEECH_CLASS_MODE : int32
{
	WMT_MS_CLASS_MUSIC = 0,
	WMT_MS_CLASS_SPEECH = 1,
	WMT_MS_CLASS_MIXED = 2,
}


[AllowDuplicates]
public enum WMT_WATERMARK_ENTRY_TYPE : int32
{
	WMT_WMETYPE_AUDIO = 1,
	WMT_WMETYPE_VIDEO = 2,
}


[AllowDuplicates]
public enum WM_PLAYBACK_DRC_LEVEL : int32
{
	WM_PLAYBACK_DRC_HIGH = 0,
	WM_PLAYBACK_DRC_MEDIUM = 1,
	WM_PLAYBACK_DRC_LOW = 2,
}


[AllowDuplicates]
public enum WMT_TIMECODE_FRAMERATE : int32
{
	WMT_TIMECODE_FRAMERATE_30 = 0,
	WMT_TIMECODE_FRAMERATE_30DROP = 1,
	WMT_TIMECODE_FRAMERATE_25 = 2,
	WMT_TIMECODE_FRAMERATE_24 = 3,
}


[AllowDuplicates]
public enum WMT_CREDENTIAL_FLAGS : int32
{
	WMT_CREDENTIAL_SAVE = 1,
	WMT_CREDENTIAL_DONT_CACHE = 2,
	WMT_CREDENTIAL_CLEAR_TEXT = 4,
	WMT_CREDENTIAL_PROXY = 8,
	WMT_CREDENTIAL_ENCRYPT = 16,
}


[AllowDuplicates]
public enum WM_AETYPE : int32
{
	WM_AETYPE_INCLUDE = 105,
	WM_AETYPE_EXCLUDE = 101,
}


[AllowDuplicates]
public enum WMT_RIGHTS : int32
{
	WMT_RIGHT_PLAYBACK = 1,
	WMT_RIGHT_COPY_TO_NON_SDMI_DEVICE = 2,
	WMT_RIGHT_COPY_TO_CD = 8,
	WMT_RIGHT_COPY_TO_SDMI_DEVICE = 16,
	WMT_RIGHT_ONE_TIME = 32,
	WMT_RIGHT_SAVE_STREAM_PROTECTED = 64,
	WMT_RIGHT_COPY = 128,
	WMT_RIGHT_COLLABORATIVE_PLAY = 256,
	WMT_RIGHT_SDMI_TRIGGER = 65536,
	WMT_RIGHT_SDMI_NOMORECOPIES = 131072,
}


[AllowDuplicates]
public enum NETSOURCE_URLCREDPOLICY_SETTINGS : int32
{
	NETSOURCE_URLCREDPOLICY_SETTING_SILENTLOGONOK = 0,
	NETSOURCE_URLCREDPOLICY_SETTING_MUSTPROMPTUSER = 1,
	NETSOURCE_URLCREDPOLICY_SETTING_ANONYMOUSONLY = 2,
}

#endregion


#region Structs
[CRepr]
public struct AM_WMT_EVENT_DATA
{
	public HRESULT hrStatus;
	public void* pData;
}

[CRepr, Packed(2)]
public struct WM_STREAM_PRIORITY_RECORD
{
	public uint16 wStreamNumber;
	public BOOL fMandatory;
}

[CRepr]
public struct WM_WRITER_STATISTICS
{
	public uint64 qwSampleCount;
	public uint64 qwByteCount;
	public uint64 qwDroppedSampleCount;
	public uint64 qwDroppedByteCount;
	public uint32 dwCurrentBitrate;
	public uint32 dwAverageBitrate;
	public uint32 dwExpectedBitrate;
	public uint32 dwCurrentSampleRate;
	public uint32 dwAverageSampleRate;
	public uint32 dwExpectedSampleRate;
}

[CRepr]
public struct WM_WRITER_STATISTICS_EX
{
	public uint32 dwBitratePlusOverhead;
	public uint32 dwCurrentSampleDropRateInQueue;
	public uint32 dwCurrentSampleDropRateInCodec;
	public uint32 dwCurrentSampleDropRateInMultiplexer;
	public uint32 dwTotalSampleDropsInQueue;
	public uint32 dwTotalSampleDropsInCodec;
	public uint32 dwTotalSampleDropsInMultiplexer;
}

[CRepr]
public struct WM_READER_STATISTICS
{
	public uint32 cbSize;
	public uint32 dwBandwidth;
	public uint32 cPacketsReceived;
	public uint32 cPacketsRecovered;
	public uint32 cPacketsLost;
	public uint16 wQuality;
}

[CRepr]
public struct WM_READER_CLIENTINFO
{
	public uint32 cbSize;
	public PWSTR wszLang;
	public PWSTR wszBrowserUserAgent;
	public PWSTR wszBrowserWebPage;
	public uint64 qwReserved;
	public LPARAM* pReserved;
	public PWSTR wszHostExe;
	public uint64 qwHostVersion;
	public PWSTR wszPlayerUserAgent;
}

[CRepr]
public struct WM_CLIENT_PROPERTIES
{
	public uint32 dwIPAddress;
	public uint32 dwPort;
}

[CRepr]
public struct WM_CLIENT_PROPERTIES_EX
{
	public uint32 cbSize;
	public PWSTR pwszIPAddress;
	public PWSTR pwszPort;
	public PWSTR pwszDNSName;
}

[CRepr]
public struct WM_PORT_NUMBER_RANGE
{
	public uint16 wPortBegin;
	public uint16 wPortEnd;
}

[CRepr]
public struct WMT_BUFFER_SEGMENT
{
	public INSSBuffer* pBuffer;
	public uint32 cbOffset;
	public uint32 cbLength;
}

[CRepr]
public struct WMT_PAYLOAD_FRAGMENT
{
	public uint32 dwPayloadIndex;
	public WMT_BUFFER_SEGMENT segmentData;
}

[CRepr]
public struct WMT_FILESINK_DATA_UNIT
{
	public WMT_BUFFER_SEGMENT packetHeaderBuffer;
	public uint32 cPayloads;
	public WMT_BUFFER_SEGMENT* pPayloadHeaderBuffers;
	public uint32 cPayloadDataFragments;
	public WMT_PAYLOAD_FRAGMENT* pPayloadDataFragments;
}

[CRepr]
public struct WMT_WEBSTREAM_FORMAT
{
	public uint16 cbSize;
	public uint16 cbSampleHeaderFixedData;
	public uint16 wVersion;
	public uint16 wReserved;
}

[CRepr]
public struct WMT_WEBSTREAM_SAMPLE_HEADER
{
	public uint16 cbLength;
	public uint16 wPart;
	public uint16 cTotalParts;
	public uint16 wSampleType;
	public char16* wszURL mut => &wszURL_impl;
	private char16[ANYSIZE_ARRAY] wszURL_impl;
}

[CRepr]
public struct WM_ADDRESS_ACCESSENTRY
{
	public uint32 dwIPAddress;
	public uint32 dwMask;
}

[CRepr, Packed(1)]
public struct WM_PICTURE
{
	public PWSTR pwszMIMEType;
	public uint8 bPictureType;
	public PWSTR pwszDescription;
	public uint32 dwDataLen;
	public uint8* pbData;
}

[CRepr, Packed(1)]
public struct WM_SYNCHRONISED_LYRICS
{
	public uint8 bTimeStampFormat;
	public uint8 bContentType;
	public PWSTR pwszContentDescriptor;
	public uint32 dwLyricsLen;
	public uint8* pbLyrics;
}

[CRepr, Packed(1)]
public struct WM_USER_WEB_URL
{
	public PWSTR pwszDescription;
	public PWSTR pwszURL;
}

[CRepr, Packed(1)]
public struct WM_USER_TEXT
{
	public PWSTR pwszDescription;
	public PWSTR pwszText;
}

[CRepr, Packed(1)]
public struct WM_LEAKY_BUCKET_PAIR
{
	public uint32 dwBitrate;
	public uint32 msBufferWindow;
}

[CRepr, Packed(1)]
public struct WM_STREAM_TYPE_INFO
{
	public Guid guidMajorType;
	public uint32 cbFormat;
}

[CRepr]
public struct WMT_WATERMARK_ENTRY
{
	public WMT_WATERMARK_ENTRY_TYPE wmetType;
	public Guid clsid;
	public uint32 cbDisplayName;
	public PWSTR pwszDisplayName;
}

[CRepr]
public struct WMT_VIDEOIMAGE_SAMPLE
{
	public uint32 dwMagic;
	public uint32 cbStruct;
	public uint32 dwControlFlags;
	public uint32 dwInputFlagsCur;
	public int32 lCurMotionXtoX;
	public int32 lCurMotionYtoX;
	public int32 lCurMotionXoffset;
	public int32 lCurMotionXtoY;
	public int32 lCurMotionYtoY;
	public int32 lCurMotionYoffset;
	public int32 lCurBlendCoef1;
	public int32 lCurBlendCoef2;
	public uint32 dwInputFlagsPrev;
	public int32 lPrevMotionXtoX;
	public int32 lPrevMotionYtoX;
	public int32 lPrevMotionXoffset;
	public int32 lPrevMotionXtoY;
	public int32 lPrevMotionYtoY;
	public int32 lPrevMotionYoffset;
	public int32 lPrevBlendCoef1;
	public int32 lPrevBlendCoef2;
}

[CRepr]
public struct WMT_VIDEOIMAGE_SAMPLE2
{
	public uint32 dwMagic;
	public uint32 dwStructSize;
	public uint32 dwControlFlags;
	public uint32 dwViewportWidth;
	public uint32 dwViewportHeight;
	public uint32 dwCurrImageWidth;
	public uint32 dwCurrImageHeight;
	public float fCurrRegionX0;
	public float fCurrRegionY0;
	public float fCurrRegionWidth;
	public float fCurrRegionHeight;
	public float fCurrBlendCoef;
	public uint32 dwPrevImageWidth;
	public uint32 dwPrevImageHeight;
	public float fPrevRegionX0;
	public float fPrevRegionY0;
	public float fPrevRegionWidth;
	public float fPrevRegionHeight;
	public float fPrevBlendCoef;
	public uint32 dwEffectType;
	public uint32 dwNumEffectParas;
	public float fEffectPara0;
	public float fEffectPara1;
	public float fEffectPara2;
	public float fEffectPara3;
	public float fEffectPara4;
	public BOOL bKeepPrevImage;
}

[CRepr]
public struct WM_MEDIA_TYPE
{
	public Guid majortype;
	public Guid subtype;
	public BOOL bFixedSizeSamples;
	public BOOL bTemporalCompression;
	public uint32 lSampleSize;
	public Guid formattype;
	public IUnknown* pUnk;
	public uint32 cbFormat;
	public uint8* pbFormat;
}

[CRepr]
public struct WMVIDEOINFOHEADER
{
	public RECT rcSource;
	public RECT rcTarget;
	public uint32 dwBitRate;
	public uint32 dwBitErrorRate;
	public int64 AvgTimePerFrame;
	public BITMAPINFOHEADER bmiHeader;
}

[CRepr]
public struct WMVIDEOINFOHEADER2
{
	public RECT rcSource;
	public RECT rcTarget;
	public uint32 dwBitRate;
	public uint32 dwBitErrorRate;
	public int64 AvgTimePerFrame;
	public uint32 dwInterlaceFlags;
	public uint32 dwCopyProtectFlags;
	public uint32 dwPictAspectRatioX;
	public uint32 dwPictAspectRatioY;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
	public BITMAPINFOHEADER bmiHeader;
}

[CRepr]
public struct WMMPEG2VIDEOINFO
{
	public WMVIDEOINFOHEADER2 hdr;
	public uint32 dwStartTimeCode;
	public uint32 cbSequenceHeader;
	public uint32 dwProfile;
	public uint32 dwLevel;
	public uint32 dwFlags;
	public uint32* dwSequenceHeader mut => &dwSequenceHeader_impl;
	private uint32[ANYSIZE_ARRAY] dwSequenceHeader_impl;
}

[CRepr]
public struct WMSCRIPTFORMAT
{
	public Guid scriptType;
}

[CRepr]
public struct WMT_COLORSPACEINFO_EXTENSION_DATA
{
	public uint8 ucColorPrimaries;
	public uint8 ucColorTransferChar;
	public uint8 ucColorMatrixCoef;
}

[CRepr, Packed(2)]
public struct WMT_TIMECODE_EXTENSION_DATA
{
	public uint16 wRange;
	public uint32 dwTimecode;
	public uint32 dwUserbits;
	public uint32 dwAmFlags;
}

[CRepr]
public struct DRM_VAL16
{
	public uint8[16] val;
}

[CRepr]
public struct WMDRM_IMPORT_INIT_STRUCT
{
	public uint32 dwVersion;
	public uint32 cbEncryptedSessionKeyMessage;
	public uint8* pbEncryptedSessionKeyMessage;
	public uint32 cbEncryptedKeyMessage;
	public uint8* pbEncryptedKeyMessage;
}

[CRepr]
public struct DRM_MINIMUM_OUTPUT_PROTECTION_LEVELS
{
	public uint16 wCompressedDigitalVideo;
	public uint16 wUncompressedDigitalVideo;
	public uint16 wAnalogVideo;
	public uint16 wCompressedDigitalAudio;
	public uint16 wUncompressedDigitalAudio;
}

[CRepr]
public struct DRM_OPL_OUTPUT_IDS
{
	public uint16 cIds;
	public Guid* rgIds;
}

[CRepr]
public struct DRM_OUTPUT_PROTECTION
{
	public Guid guidId;
	public uint8 bConfigData;
}

[CRepr]
public struct DRM_VIDEO_OUTPUT_PROTECTION_IDS
{
	public uint16 cEntries;
	public DRM_OUTPUT_PROTECTION* rgVop;
}

[CRepr]
public struct DRM_PLAY_OPL
{
	public DRM_MINIMUM_OUTPUT_PROTECTION_LEVELS minOPL;
	public DRM_OPL_OUTPUT_IDS oplIdReserved;
	public DRM_VIDEO_OUTPUT_PROTECTION_IDS vopi;
}

[CRepr]
public struct DRM_COPY_OPL
{
	public uint16 wMinimumCopyLevel;
	public DRM_OPL_OUTPUT_IDS oplIdIncludes;
	public DRM_OPL_OUTPUT_IDS oplIdExcludes;
}

#endregion

#region COM Types
[CRepr]struct INSSBuffer : IUnknown
{
	public new const Guid IID = .(0xe1cd3524, 0x03d7, 0x11d2, 0x9e, 0xed, 0x00, 0x60, 0x97, 0xd2, 0xd7, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwLength) GetLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLength) SetLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwLength) GetMaxLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** ppdwBuffer) GetBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** ppdwBuffer, uint32* pdwLength) GetBufferAndLength;
	}


	public HRESULT GetLength(uint32* pdwLength) mut => VT.[Friend]GetLength(&this, pdwLength);

	public HRESULT SetLength(uint32 dwLength) mut => VT.[Friend]SetLength(&this, dwLength);

	public HRESULT GetMaxLength(uint32* pdwLength) mut => VT.[Friend]GetMaxLength(&this, pdwLength);

	public HRESULT GetBuffer(uint8** ppdwBuffer) mut => VT.[Friend]GetBuffer(&this, ppdwBuffer);

	public HRESULT GetBufferAndLength(uint8** ppdwBuffer, uint32* pdwLength) mut => VT.[Friend]GetBufferAndLength(&this, ppdwBuffer, pdwLength);
}

[CRepr]struct INSSBuffer2 : INSSBuffer
{
	public new const Guid IID = .(0x4f528693, 0x1035, 0x43fe, 0xb4, 0x28, 0x75, 0x75, 0x61, 0xad, 0x3a, 0x68);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : INSSBuffer.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbProperties, uint8* pbProperties) GetSampleProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbProperties, uint8* pbProperties) SetSampleProperties;
	}


	public HRESULT GetSampleProperties(uint32 cbProperties, uint8* pbProperties) mut => VT.[Friend]GetSampleProperties(&this, cbProperties, pbProperties);

	public HRESULT SetSampleProperties(uint32 cbProperties, uint8* pbProperties) mut => VT.[Friend]SetSampleProperties(&this, cbProperties, pbProperties);
}

[CRepr]struct INSSBuffer3 : INSSBuffer2
{
	public new const Guid IID = .(0xc87ceaaf, 0x75be, 0x4bc4, 0x84, 0xeb, 0xac, 0x27, 0x98, 0x50, 0x76, 0x72);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : INSSBuffer2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid guidBufferProperty, void* pvBufferProperty, uint32 dwBufferPropertySize) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid guidBufferProperty, void* pvBufferProperty, uint32* pdwBufferPropertySize) GetProperty;
	}


	public HRESULT SetProperty(Guid guidBufferProperty, void* pvBufferProperty, uint32 dwBufferPropertySize) mut => VT.[Friend]SetProperty(&this, guidBufferProperty, pvBufferProperty, dwBufferPropertySize);

	public HRESULT GetProperty(Guid guidBufferProperty, void* pvBufferProperty, uint32* pdwBufferPropertySize) mut => VT.[Friend]GetProperty(&this, guidBufferProperty, pvBufferProperty, pdwBufferPropertySize);
}

[CRepr]struct INSSBuffer4 : INSSBuffer3
{
	public new const Guid IID = .(0xb6b8fd5a, 0x32e2, 0x49d4, 0xa9, 0x10, 0xc2, 0x6c, 0xc8, 0x54, 0x65, 0xed);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : INSSBuffer3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcBufferProperties) GetPropertyCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwBufferPropertyIndex, Guid* pguidBufferProperty, void* pvBufferProperty, uint32* pdwBufferPropertySize) GetPropertyByIndex;
	}


	public HRESULT GetPropertyCount(uint32* pcBufferProperties) mut => VT.[Friend]GetPropertyCount(&this, pcBufferProperties);

	public HRESULT GetPropertyByIndex(uint32 dwBufferPropertyIndex, Guid* pguidBufferProperty, void* pvBufferProperty, uint32* pdwBufferPropertySize) mut => VT.[Friend]GetPropertyByIndex(&this, dwBufferPropertyIndex, pguidBufferProperty, pvBufferProperty, pdwBufferPropertySize);
}

[CRepr]struct IWMSBufferAllocator : IUnknown
{
	public new const Guid IID = .(0x61103ca4, 0x2033, 0x11d2, 0x9e, 0xf1, 0x00, 0x60, 0x97, 0xd2, 0xd7, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMaxBufferSize, INSSBuffer** ppBuffer) AllocateBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMaxBufferSize, INSSBuffer** ppBuffer) AllocatePageSizeBuffer;
	}


	public HRESULT AllocateBuffer(uint32 dwMaxBufferSize, INSSBuffer** ppBuffer) mut => VT.[Friend]AllocateBuffer(&this, dwMaxBufferSize, ppBuffer);

	public HRESULT AllocatePageSizeBuffer(uint32 dwMaxBufferSize, INSSBuffer** ppBuffer) mut => VT.[Friend]AllocatePageSizeBuffer(&this, dwMaxBufferSize, ppBuffer);
}

[CRepr]struct IWMMediaProps : IUnknown
{
	public new const Guid IID = .(0x96406bce, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidType) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WM_MEDIA_TYPE* pType, uint32* pcbType) GetMediaType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WM_MEDIA_TYPE* pType) SetMediaType;
	}


	public HRESULT GetType(Guid* pguidType) mut => VT.[Friend]COM_GetType(&this, pguidType);

	public HRESULT GetMediaType(WM_MEDIA_TYPE* pType, uint32* pcbType) mut => VT.[Friend]GetMediaType(&this, pType, pcbType);

	public HRESULT SetMediaType(WM_MEDIA_TYPE* pType) mut => VT.[Friend]SetMediaType(&this, pType);
}

[CRepr]struct IWMVideoMediaProps : IWMMediaProps
{
	public new const Guid IID = .(0x96406bcf, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMMediaProps.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64* pllTime) GetMaxKeyFrameSpacing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64 llTime) SetMaxKeyFrameSpacing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwQuality) GetQuality;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwQuality) SetQuality;
	}


	public HRESULT GetMaxKeyFrameSpacing(int64* pllTime) mut => VT.[Friend]GetMaxKeyFrameSpacing(&this, pllTime);

	public HRESULT SetMaxKeyFrameSpacing(int64 llTime) mut => VT.[Friend]SetMaxKeyFrameSpacing(&this, llTime);

	public HRESULT GetQuality(uint32* pdwQuality) mut => VT.[Friend]GetQuality(&this, pdwQuality);

	public HRESULT SetQuality(uint32 dwQuality) mut => VT.[Friend]SetQuality(&this, dwQuality);
}

[CRepr]struct IWMWriter : IUnknown
{
	public new const Guid IID = .(0x96406bd4, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidProfile) SetProfileByID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMProfile* pProfile) SetProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszFilename) SetOutputFilename;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcInputs) GetInputCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputNum, IWMInputMediaProps** ppInput) GetInputProps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputNum, IWMInputMediaProps* pInput) SetInputProps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputNumber, uint32* pcFormats) GetInputFormatCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputNumber, uint32 dwFormatNumber, IWMInputMediaProps** pProps) GetInputFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BeginWriting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndWriting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSampleSize, INSSBuffer** ppSample) AllocateSample;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputNum, uint64 cnsSampleTime, uint32 dwFlags, INSSBuffer* pSample) WriteSample;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Flush;
	}


	public HRESULT SetProfileByID(in Guid guidProfile) mut => VT.[Friend]SetProfileByID(&this, guidProfile);

	public HRESULT SetProfile(IWMProfile* pProfile) mut => VT.[Friend]SetProfile(&this, pProfile);

	public HRESULT SetOutputFilename(PWSTR pwszFilename) mut => VT.[Friend]SetOutputFilename(&this, pwszFilename);

	public HRESULT GetInputCount(uint32* pcInputs) mut => VT.[Friend]GetInputCount(&this, pcInputs);

	public HRESULT GetInputProps(uint32 dwInputNum, IWMInputMediaProps** ppInput) mut => VT.[Friend]GetInputProps(&this, dwInputNum, ppInput);

	public HRESULT SetInputProps(uint32 dwInputNum, IWMInputMediaProps* pInput) mut => VT.[Friend]SetInputProps(&this, dwInputNum, pInput);

	public HRESULT GetInputFormatCount(uint32 dwInputNumber, uint32* pcFormats) mut => VT.[Friend]GetInputFormatCount(&this, dwInputNumber, pcFormats);

	public HRESULT GetInputFormat(uint32 dwInputNumber, uint32 dwFormatNumber, IWMInputMediaProps** pProps) mut => VT.[Friend]GetInputFormat(&this, dwInputNumber, dwFormatNumber, pProps);

	public HRESULT BeginWriting() mut => VT.[Friend]BeginWriting(&this);

	public HRESULT EndWriting() mut => VT.[Friend]EndWriting(&this);

	public HRESULT AllocateSample(uint32 dwSampleSize, INSSBuffer** ppSample) mut => VT.[Friend]AllocateSample(&this, dwSampleSize, ppSample);

	public HRESULT WriteSample(uint32 dwInputNum, uint64 cnsSampleTime, uint32 dwFlags, INSSBuffer* pSample) mut => VT.[Friend]WriteSample(&this, dwInputNum, cnsSampleTime, dwFlags, pSample);

	public HRESULT Flush() mut => VT.[Friend]Flush(&this);
}

[CRepr]struct IWMDRMWriter : IUnknown
{
	public new const Guid IID = .(0xd6ea5dd0, 0x12a0, 0x43f4, 0x90, 0xab, 0xa3, 0xfd, 0x45, 0x1e, 0x6a, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszKeySeed, uint32* pcwchLength) GenerateKeySeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszKeyID, uint32* pcwchLength) GenerateKeyID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszPrivKey, uint32* pcwchPrivKeyLength, char16* pwszPubKey, uint32* pcwchPubKeyLength) GenerateSigningKeyPair;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, PWSTR pszName, WMT_ATTR_DATATYPE Type, uint8* pValue, uint16 cbLength) SetDRMAttribute;
	}


	public HRESULT GenerateKeySeed(char16* pwszKeySeed, uint32* pcwchLength) mut => VT.[Friend]GenerateKeySeed(&this, pwszKeySeed, pcwchLength);

	public HRESULT GenerateKeyID(char16* pwszKeyID, uint32* pcwchLength) mut => VT.[Friend]GenerateKeyID(&this, pwszKeyID, pcwchLength);

	public HRESULT GenerateSigningKeyPair(char16* pwszPrivKey, uint32* pcwchPrivKeyLength, char16* pwszPubKey, uint32* pcwchPubKeyLength) mut => VT.[Friend]GenerateSigningKeyPair(&this, pwszPrivKey, pcwchPrivKeyLength, pwszPubKey, pcwchPubKeyLength);

	public HRESULT SetDRMAttribute(uint16 wStreamNum, PWSTR pszName, WMT_ATTR_DATATYPE Type, uint8* pValue, uint16 cbLength) mut => VT.[Friend]SetDRMAttribute(&this, wStreamNum, pszName, Type, pValue, cbLength);
}

[CRepr]struct IWMDRMWriter2 : IWMDRMWriter
{
	public new const Guid IID = .(0x38ee7a94, 0x40e2, 0x4e10, 0xaa, 0x3f, 0x33, 0xfd, 0x32, 0x10, 0xed, 0x5b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMDRMWriter.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fSamplesEncrypted, uint8* pbKeyID, uint32 cbKeyID) SetWMDRMNetEncryption;
	}


	public HRESULT SetWMDRMNetEncryption(BOOL fSamplesEncrypted, uint8* pbKeyID, uint32 cbKeyID) mut => VT.[Friend]SetWMDRMNetEncryption(&this, fSamplesEncrypted, pbKeyID, cbKeyID);
}

[CRepr]struct IWMDRMWriter3 : IWMDRMWriter2
{
	public new const Guid IID = .(0xa7184082, 0xa4aa, 0x4dde, 0xac, 0x9c, 0xe7, 0x5d, 0xbd, 0x11, 0x17, 0xce);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMDRMWriter2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDRM_IMPORT_INIT_STRUCT* pImportInitStruct) SetProtectStreamSamples;
	}


	public HRESULT SetProtectStreamSamples(WMDRM_IMPORT_INIT_STRUCT* pImportInitStruct) mut => VT.[Friend]SetProtectStreamSamples(&this, pImportInitStruct);
}

[CRepr]struct IWMInputMediaProps : IWMMediaProps
{
	public new const Guid IID = .(0x96406bd5, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMMediaProps.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszName, uint16* pcchName) GetConnectionName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszName, uint16* pcchName) GetGroupName;
	}


	public HRESULT GetConnectionName(char16* pwszName, uint16* pcchName) mut => VT.[Friend]GetConnectionName(&this, pwszName, pcchName);

	public HRESULT GetGroupName(char16* pwszName, uint16* pcchName) mut => VT.[Friend]GetGroupName(&this, pwszName, pcchName);
}

[CRepr]struct IWMPropertyVault : IUnknown
{
	public new const Guid IID = .(0x72995a79, 0x5090, 0x42a4, 0x9c, 0x8c, 0xd9, 0xd0, 0xb6, 0xd3, 0x4b, 0xe5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCount) GetPropertyCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint32* pdwSize) GetPropertyByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, WMT_ATTR_DATATYPE pType, uint8* pValue, uint32 dwSize) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, char16* pszName, uint32* pdwNameLen, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint32* pdwSize) GetPropertyByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPropertyVault* pIWMPropertyVault) CopyPropertiesFrom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
	}


	public HRESULT GetPropertyCount(uint32* pdwCount) mut => VT.[Friend]GetPropertyCount(&this, pdwCount);

	public HRESULT GetPropertyByName(PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint32* pdwSize) mut => VT.[Friend]GetPropertyByName(&this, pszName, pType, pValue, pdwSize);

	public HRESULT SetProperty(PWSTR pszName, WMT_ATTR_DATATYPE pType, uint8* pValue, uint32 dwSize) mut => VT.[Friend]SetProperty(&this, pszName, pType, pValue, dwSize);

	public HRESULT GetPropertyByIndex(uint32 dwIndex, char16* pszName, uint32* pdwNameLen, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint32* pdwSize) mut => VT.[Friend]GetPropertyByIndex(&this, dwIndex, pszName, pdwNameLen, pType, pValue, pdwSize);

	public HRESULT CopyPropertiesFrom(IWMPropertyVault* pIWMPropertyVault) mut => VT.[Friend]CopyPropertiesFrom(&this, pIWMPropertyVault);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);
}

[CRepr]struct IWMIStreamProps : IUnknown
{
	public new const Guid IID = .(0x6816dad3, 0x2b4b, 0x4c8e, 0x81, 0x49, 0x87, 0x4c, 0x34, 0x83, 0xa7, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint32* pdwSize) GetProperty;
	}


	public HRESULT GetProperty(PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint32* pdwSize) mut => VT.[Friend]GetProperty(&this, pszName, pType, pValue, pdwSize);
}

[CRepr]struct IWMReader : IUnknown
{
	public new const Guid IID = .(0x96406bd6, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszURL, IWMReaderCallback* pCallback, void* pvContext) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcOutputs) GetOutputCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, IWMOutputMediaProps** ppOutput) GetOutputProps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, IWMOutputMediaProps* pOutput) SetOutputProps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNumber, uint32* pcFormats) GetOutputFormatCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNumber, uint32 dwFormatNumber, IWMOutputMediaProps** ppProps) GetOutputFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 cnsStart, uint64 cnsDuration, float fRate, void* pvContext) Start;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
	}


	public HRESULT Open(PWSTR pwszURL, IWMReaderCallback* pCallback, void* pvContext) mut => VT.[Friend]Open(&this, pwszURL, pCallback, pvContext);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT GetOutputCount(uint32* pcOutputs) mut => VT.[Friend]GetOutputCount(&this, pcOutputs);

	public HRESULT GetOutputProps(uint32 dwOutputNum, IWMOutputMediaProps** ppOutput) mut => VT.[Friend]GetOutputProps(&this, dwOutputNum, ppOutput);

	public HRESULT SetOutputProps(uint32 dwOutputNum, IWMOutputMediaProps* pOutput) mut => VT.[Friend]SetOutputProps(&this, dwOutputNum, pOutput);

	public HRESULT GetOutputFormatCount(uint32 dwOutputNumber, uint32* pcFormats) mut => VT.[Friend]GetOutputFormatCount(&this, dwOutputNumber, pcFormats);

	public HRESULT GetOutputFormat(uint32 dwOutputNumber, uint32 dwFormatNumber, IWMOutputMediaProps** ppProps) mut => VT.[Friend]GetOutputFormat(&this, dwOutputNumber, dwFormatNumber, ppProps);

	public HRESULT Start(uint64 cnsStart, uint64 cnsDuration, float fRate, void* pvContext) mut => VT.[Friend]Start(&this, cnsStart, cnsDuration, fRate, pvContext);

	public HRESULT Stop() mut => VT.[Friend]Stop(&this);

	public HRESULT Pause() mut => VT.[Friend]Pause(&this);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);
}

[CRepr]struct IWMSyncReader : IUnknown
{
	public new const Guid IID = .(0x9397f121, 0x7705, 0x4dc9, 0xb0, 0x49, 0x98, 0xb6, 0x98, 0x18, 0x84, 0x14);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszFilename) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 cnsStartTime, int64 cnsDuration) SetRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, uint64 qwFrameNumber, int64 cFramesToRead) SetRangeByFrame;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, INSSBuffer** ppSample, uint64* pcnsSampleTime, uint64* pcnsDuration, uint32* pdwFlags, uint32* pdwOutputNum, uint16* pwStreamNum) GetNextSample;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 cStreamCount, uint16* pwStreamNumbers, WMT_STREAM_SELECTION* pSelections) SetStreamsSelected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, WMT_STREAM_SELECTION* pSelection) GetStreamSelected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, BOOL fCompressed) SetReadStreamSamples;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, BOOL* pfCompressed) GetReadStreamSamples;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint16* pcbLength) GetOutputSetting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, PWSTR pszName, WMT_ATTR_DATATYPE Type, uint8* pValue, uint16 cbLength) SetOutputSetting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcOutputs) GetOutputCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, IWMOutputMediaProps** ppOutput) GetOutputProps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, IWMOutputMediaProps* pOutput) SetOutputProps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, uint32* pcFormats) GetOutputFormatCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, uint32 dwFormatNum, IWMOutputMediaProps** ppProps) GetOutputFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, uint32* pdwOutputNum) GetOutputNumberForStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, uint16* pwStreamNum) GetStreamNumberForOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutput, uint32* pcbMax) GetMaxOutputSampleSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStream, uint32* pcbMax) GetMaxStreamSampleSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStream) OpenStream;
	}


	public HRESULT Open(PWSTR pwszFilename) mut => VT.[Friend]Open(&this, pwszFilename);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT SetRange(uint64 cnsStartTime, int64 cnsDuration) mut => VT.[Friend]SetRange(&this, cnsStartTime, cnsDuration);

	public HRESULT SetRangeByFrame(uint16 wStreamNum, uint64 qwFrameNumber, int64 cFramesToRead) mut => VT.[Friend]SetRangeByFrame(&this, wStreamNum, qwFrameNumber, cFramesToRead);

	public HRESULT GetNextSample(uint16 wStreamNum, INSSBuffer** ppSample, uint64* pcnsSampleTime, uint64* pcnsDuration, uint32* pdwFlags, uint32* pdwOutputNum, uint16* pwStreamNum) mut => VT.[Friend]GetNextSample(&this, wStreamNum, ppSample, pcnsSampleTime, pcnsDuration, pdwFlags, pdwOutputNum, pwStreamNum);

	public HRESULT SetStreamsSelected(uint16 cStreamCount, uint16* pwStreamNumbers, WMT_STREAM_SELECTION* pSelections) mut => VT.[Friend]SetStreamsSelected(&this, cStreamCount, pwStreamNumbers, pSelections);

	public HRESULT GetStreamSelected(uint16 wStreamNum, WMT_STREAM_SELECTION* pSelection) mut => VT.[Friend]GetStreamSelected(&this, wStreamNum, pSelection);

	public HRESULT SetReadStreamSamples(uint16 wStreamNum, BOOL fCompressed) mut => VT.[Friend]SetReadStreamSamples(&this, wStreamNum, fCompressed);

	public HRESULT GetReadStreamSamples(uint16 wStreamNum, BOOL* pfCompressed) mut => VT.[Friend]GetReadStreamSamples(&this, wStreamNum, pfCompressed);

	public HRESULT GetOutputSetting(uint32 dwOutputNum, PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint16* pcbLength) mut => VT.[Friend]GetOutputSetting(&this, dwOutputNum, pszName, pType, pValue, pcbLength);

	public HRESULT SetOutputSetting(uint32 dwOutputNum, PWSTR pszName, WMT_ATTR_DATATYPE Type, uint8* pValue, uint16 cbLength) mut => VT.[Friend]SetOutputSetting(&this, dwOutputNum, pszName, Type, pValue, cbLength);

	public HRESULT GetOutputCount(uint32* pcOutputs) mut => VT.[Friend]GetOutputCount(&this, pcOutputs);

	public HRESULT GetOutputProps(uint32 dwOutputNum, IWMOutputMediaProps** ppOutput) mut => VT.[Friend]GetOutputProps(&this, dwOutputNum, ppOutput);

	public HRESULT SetOutputProps(uint32 dwOutputNum, IWMOutputMediaProps* pOutput) mut => VT.[Friend]SetOutputProps(&this, dwOutputNum, pOutput);

	public HRESULT GetOutputFormatCount(uint32 dwOutputNum, uint32* pcFormats) mut => VT.[Friend]GetOutputFormatCount(&this, dwOutputNum, pcFormats);

	public HRESULT GetOutputFormat(uint32 dwOutputNum, uint32 dwFormatNum, IWMOutputMediaProps** ppProps) mut => VT.[Friend]GetOutputFormat(&this, dwOutputNum, dwFormatNum, ppProps);

	public HRESULT GetOutputNumberForStream(uint16 wStreamNum, uint32* pdwOutputNum) mut => VT.[Friend]GetOutputNumberForStream(&this, wStreamNum, pdwOutputNum);

	public HRESULT GetStreamNumberForOutput(uint32 dwOutputNum, uint16* pwStreamNum) mut => VT.[Friend]GetStreamNumberForOutput(&this, dwOutputNum, pwStreamNum);

	public HRESULT GetMaxOutputSampleSize(uint32 dwOutput, uint32* pcbMax) mut => VT.[Friend]GetMaxOutputSampleSize(&this, dwOutput, pcbMax);

	public HRESULT GetMaxStreamSampleSize(uint16 wStream, uint32* pcbMax) mut => VT.[Friend]GetMaxStreamSampleSize(&this, wStream, pcbMax);

	public HRESULT OpenStream(IStream* pStream) mut => VT.[Friend]OpenStream(&this, pStream);
}

[CRepr]struct IWMSyncReader2 : IWMSyncReader
{
	public new const Guid IID = .(0xfaed3d21, 0x1b6b, 0x4af7, 0x8c, 0xb6, 0x3e, 0x18, 0x9b, 0xbc, 0x18, 0x7b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMSyncReader.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, WMT_TIMECODE_EXTENSION_DATA* pStart, WMT_TIMECODE_EXTENSION_DATA* pEnd) SetRangeByTimecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, uint64 qwFrameNumber, int64 cFramesToRead, uint64* pcnsStartTime) SetRangeByFrameEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, IWMReaderAllocatorEx* pAllocator) SetAllocateForOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, IWMReaderAllocatorEx** ppAllocator) GetAllocateForOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, IWMReaderAllocatorEx* pAllocator) SetAllocateForStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 dwSreamNum, IWMReaderAllocatorEx** ppAllocator) GetAllocateForStream;
	}


	public HRESULT SetRangeByTimecode(uint16 wStreamNum, WMT_TIMECODE_EXTENSION_DATA* pStart, WMT_TIMECODE_EXTENSION_DATA* pEnd) mut => VT.[Friend]SetRangeByTimecode(&this, wStreamNum, pStart, pEnd);

	public HRESULT SetRangeByFrameEx(uint16 wStreamNum, uint64 qwFrameNumber, int64 cFramesToRead, uint64* pcnsStartTime) mut => VT.[Friend]SetRangeByFrameEx(&this, wStreamNum, qwFrameNumber, cFramesToRead, pcnsStartTime);

	public HRESULT SetAllocateForOutput(uint32 dwOutputNum, IWMReaderAllocatorEx* pAllocator) mut => VT.[Friend]SetAllocateForOutput(&this, dwOutputNum, pAllocator);

	public HRESULT GetAllocateForOutput(uint32 dwOutputNum, IWMReaderAllocatorEx** ppAllocator) mut => VT.[Friend]GetAllocateForOutput(&this, dwOutputNum, ppAllocator);

	public HRESULT SetAllocateForStream(uint16 wStreamNum, IWMReaderAllocatorEx* pAllocator) mut => VT.[Friend]SetAllocateForStream(&this, wStreamNum, pAllocator);

	public HRESULT GetAllocateForStream(uint16 dwSreamNum, IWMReaderAllocatorEx** ppAllocator) mut => VT.[Friend]GetAllocateForStream(&this, dwSreamNum, ppAllocator);
}

[CRepr]struct IWMOutputMediaProps : IWMMediaProps
{
	public new const Guid IID = .(0x96406bd7, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMMediaProps.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszName, uint16* pcchName) GetStreamGroupName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszName, uint16* pcchName) GetConnectionName;
	}


	public HRESULT GetStreamGroupName(char16* pwszName, uint16* pcchName) mut => VT.[Friend]GetStreamGroupName(&this, pwszName, pcchName);

	public HRESULT GetConnectionName(char16* pwszName, uint16* pcchName) mut => VT.[Friend]GetConnectionName(&this, pwszName, pcchName);
}

[CRepr]struct IWMStatusCallback : IUnknown
{
	public new const Guid IID = .(0x6d7cdc70, 0x9888, 0x11d3, 0x8e, 0xdc, 0x00, 0xc0, 0x4f, 0x61, 0x09, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMT_STATUS Status, HRESULT hr, WMT_ATTR_DATATYPE dwType, uint8* pValue, void* pvContext) OnStatus;
	}


	public HRESULT OnStatus(WMT_STATUS Status, HRESULT hr, WMT_ATTR_DATATYPE dwType, uint8* pValue, void* pvContext) mut => VT.[Friend]OnStatus(&this, Status, hr, dwType, pValue, pvContext);
}

[CRepr]struct IWMReaderCallback : IWMStatusCallback
{
	public new const Guid IID = .(0x96406bd8, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMStatusCallback.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, uint64 cnsSampleTime, uint64 cnsSampleDuration, uint32 dwFlags, INSSBuffer* pSample, void* pvContext) OnSample;
	}


	public HRESULT OnSample(uint32 dwOutputNum, uint64 cnsSampleTime, uint64 cnsSampleDuration, uint32 dwFlags, INSSBuffer* pSample, void* pvContext) mut => VT.[Friend]OnSample(&this, dwOutputNum, cnsSampleTime, cnsSampleDuration, dwFlags, pSample, pvContext);
}

[CRepr]struct IWMCredentialCallback : IUnknown
{
	public new const Guid IID = .(0x342e0eb7, 0xe651, 0x450c, 0x97, 0x5b, 0x2a, 0xce, 0x2c, 0x90, 0xc4, 0x8e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszRealm, PWSTR pwszSite, char16* pwszUser, uint32 cchUser, char16* pwszPassword, uint32 cchPassword, HRESULT hrStatus, uint32* pdwFlags) AcquireCredentials;
	}


	public HRESULT AcquireCredentials(PWSTR pwszRealm, PWSTR pwszSite, char16* pwszUser, uint32 cchUser, char16* pwszPassword, uint32 cchPassword, HRESULT hrStatus, uint32* pdwFlags) mut => VT.[Friend]AcquireCredentials(&this, pwszRealm, pwszSite, pwszUser, cchUser, pwszPassword, cchPassword, hrStatus, pdwFlags);
}

[CRepr]struct IWMMetadataEditor : IUnknown
{
	public new const Guid IID = .(0x96406bd9, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszFilename) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Flush;
	}


	public HRESULT Open(PWSTR pwszFilename) mut => VT.[Friend]Open(&this, pwszFilename);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT Flush() mut => VT.[Friend]Flush(&this);
}

[CRepr]struct IWMMetadataEditor2 : IWMMetadataEditor
{
	public new const Guid IID = .(0x203cffe3, 0x2e18, 0x4fdf, 0xb5, 0x9d, 0x6e, 0x71, 0x53, 0x05, 0x34, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMMetadataEditor.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszFilename, uint32 dwDesiredAccess, uint32 dwShareMode) OpenEx;
	}


	public HRESULT OpenEx(PWSTR pwszFilename, uint32 dwDesiredAccess, uint32 dwShareMode) mut => VT.[Friend]OpenEx(&this, pwszFilename, dwDesiredAccess, dwShareMode);
}

[CRepr]struct IWMDRMEditor : IUnknown
{
	public new const Guid IID = .(0xff130ebc, 0xa6c3, 0x42a6, 0xb4, 0x01, 0xc3, 0x38, 0x2c, 0x3e, 0x08, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwstrName, WMT_ATTR_DATATYPE* pdwType, uint8* pValue, uint16* pcbLength) GetDRMProperty;
	}


	public HRESULT GetDRMProperty(PWSTR pwstrName, WMT_ATTR_DATATYPE* pdwType, uint8* pValue, uint16* pcbLength) mut => VT.[Friend]GetDRMProperty(&this, pwstrName, pdwType, pValue, pcbLength);
}

[CRepr]struct IWMHeaderInfo : IUnknown
{
	public new const Guid IID = .(0x96406bda, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, uint16* pcAttributes) GetAttributeCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wIndex, uint16* pwStreamNum, char16* pwszName, uint16* pcchNameLen, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint16* pcbLength) GetAttributeByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwStreamNum, PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint16* pcbLength) GetAttributeByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, PWSTR pszName, WMT_ATTR_DATATYPE Type, uint8* pValue, uint16 cbLength) SetAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pcMarkers) GetMarkerCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wIndex, char16* pwszMarkerName, uint16* pcchMarkerNameLen, uint64* pcnsMarkerTime) GetMarker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszMarkerName, uint64 cnsMarkerTime) AddMarker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wIndex) RemoveMarker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pcScripts) GetScriptCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wIndex, char16* pwszType, uint16* pcchTypeLen, char16* pwszCommand, uint16* pcchCommandLen, uint64* pcnsScriptTime) GetScript;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszType, PWSTR pwszCommand, uint64 cnsScriptTime) AddScript;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wIndex) RemoveScript;
	}


	public HRESULT GetAttributeCount(uint16 wStreamNum, uint16* pcAttributes) mut => VT.[Friend]GetAttributeCount(&this, wStreamNum, pcAttributes);

	public HRESULT GetAttributeByIndex(uint16 wIndex, uint16* pwStreamNum, char16* pwszName, uint16* pcchNameLen, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint16* pcbLength) mut => VT.[Friend]GetAttributeByIndex(&this, wIndex, pwStreamNum, pwszName, pcchNameLen, pType, pValue, pcbLength);

	public HRESULT GetAttributeByName(uint16* pwStreamNum, PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint16* pcbLength) mut => VT.[Friend]GetAttributeByName(&this, pwStreamNum, pszName, pType, pValue, pcbLength);

	public HRESULT SetAttribute(uint16 wStreamNum, PWSTR pszName, WMT_ATTR_DATATYPE Type, uint8* pValue, uint16 cbLength) mut => VT.[Friend]SetAttribute(&this, wStreamNum, pszName, Type, pValue, cbLength);

	public HRESULT GetMarkerCount(uint16* pcMarkers) mut => VT.[Friend]GetMarkerCount(&this, pcMarkers);

	public HRESULT GetMarker(uint16 wIndex, char16* pwszMarkerName, uint16* pcchMarkerNameLen, uint64* pcnsMarkerTime) mut => VT.[Friend]GetMarker(&this, wIndex, pwszMarkerName, pcchMarkerNameLen, pcnsMarkerTime);

	public HRESULT AddMarker(PWSTR pwszMarkerName, uint64 cnsMarkerTime) mut => VT.[Friend]AddMarker(&this, pwszMarkerName, cnsMarkerTime);

	public HRESULT RemoveMarker(uint16 wIndex) mut => VT.[Friend]RemoveMarker(&this, wIndex);

	public HRESULT GetScriptCount(uint16* pcScripts) mut => VT.[Friend]GetScriptCount(&this, pcScripts);

	public HRESULT GetScript(uint16 wIndex, char16* pwszType, uint16* pcchTypeLen, char16* pwszCommand, uint16* pcchCommandLen, uint64* pcnsScriptTime) mut => VT.[Friend]GetScript(&this, wIndex, pwszType, pcchTypeLen, pwszCommand, pcchCommandLen, pcnsScriptTime);

	public HRESULT AddScript(PWSTR pwszType, PWSTR pwszCommand, uint64 cnsScriptTime) mut => VT.[Friend]AddScript(&this, pwszType, pwszCommand, cnsScriptTime);

	public HRESULT RemoveScript(uint16 wIndex) mut => VT.[Friend]RemoveScript(&this, wIndex);
}

[CRepr]struct IWMHeaderInfo2 : IWMHeaderInfo
{
	public new const Guid IID = .(0x15cf9781, 0x454e, 0x482e, 0xb3, 0x93, 0x85, 0xfa, 0xe4, 0x87, 0xa8, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMHeaderInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcCodecInfos) GetCodecInfoCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 wIndex, uint16* pcchName, char16* pwszName, uint16* pcchDescription, char16* pwszDescription, WMT_CODEC_INFO_TYPE* pCodecType, uint16* pcbCodecInfo, uint8* pbCodecInfo) GetCodecInfo;
	}


	public HRESULT GetCodecInfoCount(uint32* pcCodecInfos) mut => VT.[Friend]GetCodecInfoCount(&this, pcCodecInfos);

	public HRESULT GetCodecInfo(uint32 wIndex, uint16* pcchName, char16* pwszName, uint16* pcchDescription, char16* pwszDescription, WMT_CODEC_INFO_TYPE* pCodecType, uint16* pcbCodecInfo, uint8* pbCodecInfo) mut => VT.[Friend]GetCodecInfo(&this, wIndex, pcchName, pwszName, pcchDescription, pwszDescription, pCodecType, pcbCodecInfo, pbCodecInfo);
}

[CRepr]struct IWMHeaderInfo3 : IWMHeaderInfo2
{
	public new const Guid IID = .(0x15cc68e3, 0x27cc, 0x4ecd, 0xb2, 0x22, 0x3f, 0x5d, 0x02, 0xd8, 0x0b, 0xd5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMHeaderInfo2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, uint16* pcAttributes) GetAttributeCountEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, PWSTR pwszName, uint16* pwLangIndex, uint16* pwIndices, uint16* pwCount) GetAttributeIndices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, uint16 wIndex, char16* pwszName, uint16* pwNameLen, WMT_ATTR_DATATYPE* pType, uint16* pwLangIndex, uint8* pValue, uint32* pdwDataLength) GetAttributeByIndexEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, uint16 wIndex, WMT_ATTR_DATATYPE Type, uint16 wLangIndex, uint8* pValue, uint32 dwLength) ModifyAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, PWSTR pszName, uint16* pwIndex, WMT_ATTR_DATATYPE Type, uint16 wLangIndex, uint8* pValue, uint32 dwLength) AddAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, uint16 wIndex) DeleteAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszName, PWSTR pwszDescription, WMT_CODEC_INFO_TYPE codecType, uint16 cbCodecInfo, uint8* pbCodecInfo) AddCodecInfo;
	}


	public HRESULT GetAttributeCountEx(uint16 wStreamNum, uint16* pcAttributes) mut => VT.[Friend]GetAttributeCountEx(&this, wStreamNum, pcAttributes);

	public HRESULT GetAttributeIndices(uint16 wStreamNum, PWSTR pwszName, uint16* pwLangIndex, uint16* pwIndices, uint16* pwCount) mut => VT.[Friend]GetAttributeIndices(&this, wStreamNum, pwszName, pwLangIndex, pwIndices, pwCount);

	public HRESULT GetAttributeByIndexEx(uint16 wStreamNum, uint16 wIndex, char16* pwszName, uint16* pwNameLen, WMT_ATTR_DATATYPE* pType, uint16* pwLangIndex, uint8* pValue, uint32* pdwDataLength) mut => VT.[Friend]GetAttributeByIndexEx(&this, wStreamNum, wIndex, pwszName, pwNameLen, pType, pwLangIndex, pValue, pdwDataLength);

	public HRESULT ModifyAttribute(uint16 wStreamNum, uint16 wIndex, WMT_ATTR_DATATYPE Type, uint16 wLangIndex, uint8* pValue, uint32 dwLength) mut => VT.[Friend]ModifyAttribute(&this, wStreamNum, wIndex, Type, wLangIndex, pValue, dwLength);

	public HRESULT AddAttribute(uint16 wStreamNum, PWSTR pszName, uint16* pwIndex, WMT_ATTR_DATATYPE Type, uint16 wLangIndex, uint8* pValue, uint32 dwLength) mut => VT.[Friend]AddAttribute(&this, wStreamNum, pszName, pwIndex, Type, wLangIndex, pValue, dwLength);

	public HRESULT DeleteAttribute(uint16 wStreamNum, uint16 wIndex) mut => VT.[Friend]DeleteAttribute(&this, wStreamNum, wIndex);

	public HRESULT AddCodecInfo(PWSTR pwszName, PWSTR pwszDescription, WMT_CODEC_INFO_TYPE codecType, uint16 cbCodecInfo, uint8* pbCodecInfo) mut => VT.[Friend]AddCodecInfo(&this, pwszName, pwszDescription, codecType, cbCodecInfo, pbCodecInfo);
}

[CRepr]struct IWMProfileManager : IUnknown
{
	public new const Guid IID = .(0xd16679f2, 0x6ca0, 0x472d, 0x8d, 0x31, 0x2f, 0x5d, 0x55, 0xae, 0xe1, 0x55);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMT_VERSION dwVersion, IWMProfile** ppProfile) CreateEmptyProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidProfile, IWMProfile** ppProfile) LoadProfileByID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszProfile, IWMProfile** ppProfile) LoadProfileByData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMProfile* pIWMProfile, PWSTR pwszProfile, uint32* pdwLength) SaveProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcProfiles) GetSystemProfileCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwProfileIndex, IWMProfile** ppProfile) LoadSystemProfile;
	}


	public HRESULT CreateEmptyProfile(WMT_VERSION dwVersion, IWMProfile** ppProfile) mut => VT.[Friend]CreateEmptyProfile(&this, dwVersion, ppProfile);

	public HRESULT LoadProfileByID(in Guid guidProfile, IWMProfile** ppProfile) mut => VT.[Friend]LoadProfileByID(&this, guidProfile, ppProfile);

	public HRESULT LoadProfileByData(PWSTR pwszProfile, IWMProfile** ppProfile) mut => VT.[Friend]LoadProfileByData(&this, pwszProfile, ppProfile);

	public HRESULT SaveProfile(IWMProfile* pIWMProfile, PWSTR pwszProfile, uint32* pdwLength) mut => VT.[Friend]SaveProfile(&this, pIWMProfile, pwszProfile, pdwLength);

	public HRESULT GetSystemProfileCount(uint32* pcProfiles) mut => VT.[Friend]GetSystemProfileCount(&this, pcProfiles);

	public HRESULT LoadSystemProfile(uint32 dwProfileIndex, IWMProfile** ppProfile) mut => VT.[Friend]LoadSystemProfile(&this, dwProfileIndex, ppProfile);
}

[CRepr]struct IWMProfileManager2 : IWMProfileManager
{
	public new const Guid IID = .(0x7a924e51, 0x73c1, 0x494d, 0x80, 0x19, 0x23, 0xd3, 0x7e, 0xd9, 0xb8, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMProfileManager.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMT_VERSION* pdwVersion) GetSystemProfileVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMT_VERSION dwVersion) SetSystemProfileVersion;
	}


	public HRESULT GetSystemProfileVersion(WMT_VERSION* pdwVersion) mut => VT.[Friend]GetSystemProfileVersion(&this, pdwVersion);

	public HRESULT SetSystemProfileVersion(WMT_VERSION dwVersion) mut => VT.[Friend]SetSystemProfileVersion(&this, dwVersion);
}

[CRepr]struct IWMProfileManagerLanguage : IUnknown
{
	public new const Guid IID = .(0xba4dcc78, 0x7ee0, 0x4ab8, 0xb2, 0x7a, 0xdb, 0xce, 0x8b, 0xc5, 0x14, 0x54);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* wLangID) GetUserLanguageID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wLangID) SetUserLanguageID;
	}


	public HRESULT GetUserLanguageID(uint16* wLangID) mut => VT.[Friend]GetUserLanguageID(&this, wLangID);

	public HRESULT SetUserLanguageID(uint16 wLangID) mut => VT.[Friend]SetUserLanguageID(&this, wLangID);
}

[CRepr]struct IWMProfile : IUnknown
{
	public new const Guid IID = .(0x96406bdb, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMT_VERSION* pdwVersion) GetVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszName, uint32* pcchName) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszName) SetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszDescription, uint32* pcchDescription) GetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszDescription) SetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcStreams) GetStreamCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwStreamIndex, IWMStreamConfig** ppConfig) GetStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, IWMStreamConfig** ppConfig) GetStreamByNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMStreamConfig* pConfig) RemoveStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum) RemoveStreamByNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMStreamConfig* pConfig) AddStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMStreamConfig* pConfig) ReconfigStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidStreamType, IWMStreamConfig** ppConfig) CreateNewStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcME) GetMutualExclusionCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMEIndex, IWMMutualExclusion** ppME) GetMutualExclusion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMMutualExclusion* pME) RemoveMutualExclusion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMMutualExclusion* pME) AddMutualExclusion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMMutualExclusion** ppME) CreateNewMutualExclusion;
	}


	public HRESULT GetVersion(WMT_VERSION* pdwVersion) mut => VT.[Friend]GetVersion(&this, pdwVersion);

	public HRESULT GetName(char16* pwszName, uint32* pcchName) mut => VT.[Friend]GetName(&this, pwszName, pcchName);

	public HRESULT SetName(PWSTR pwszName) mut => VT.[Friend]SetName(&this, pwszName);

	public HRESULT GetDescription(char16* pwszDescription, uint32* pcchDescription) mut => VT.[Friend]GetDescription(&this, pwszDescription, pcchDescription);

	public HRESULT SetDescription(PWSTR pwszDescription) mut => VT.[Friend]SetDescription(&this, pwszDescription);

	public HRESULT GetStreamCount(uint32* pcStreams) mut => VT.[Friend]GetStreamCount(&this, pcStreams);

	public HRESULT GetStream(uint32 dwStreamIndex, IWMStreamConfig** ppConfig) mut => VT.[Friend]GetStream(&this, dwStreamIndex, ppConfig);

	public HRESULT GetStreamByNumber(uint16 wStreamNum, IWMStreamConfig** ppConfig) mut => VT.[Friend]GetStreamByNumber(&this, wStreamNum, ppConfig);

	public HRESULT RemoveStream(IWMStreamConfig* pConfig) mut => VT.[Friend]RemoveStream(&this, pConfig);

	public HRESULT RemoveStreamByNumber(uint16 wStreamNum) mut => VT.[Friend]RemoveStreamByNumber(&this, wStreamNum);

	public HRESULT AddStream(IWMStreamConfig* pConfig) mut => VT.[Friend]AddStream(&this, pConfig);

	public HRESULT ReconfigStream(IWMStreamConfig* pConfig) mut => VT.[Friend]ReconfigStream(&this, pConfig);

	public HRESULT CreateNewStream(in Guid guidStreamType, IWMStreamConfig** ppConfig) mut => VT.[Friend]CreateNewStream(&this, guidStreamType, ppConfig);

	public HRESULT GetMutualExclusionCount(uint32* pcME) mut => VT.[Friend]GetMutualExclusionCount(&this, pcME);

	public HRESULT GetMutualExclusion(uint32 dwMEIndex, IWMMutualExclusion** ppME) mut => VT.[Friend]GetMutualExclusion(&this, dwMEIndex, ppME);

	public HRESULT RemoveMutualExclusion(IWMMutualExclusion* pME) mut => VT.[Friend]RemoveMutualExclusion(&this, pME);

	public HRESULT AddMutualExclusion(IWMMutualExclusion* pME) mut => VT.[Friend]AddMutualExclusion(&this, pME);

	public HRESULT CreateNewMutualExclusion(IWMMutualExclusion** ppME) mut => VT.[Friend]CreateNewMutualExclusion(&this, ppME);
}

[CRepr]struct IWMProfile2 : IWMProfile
{
	public new const Guid IID = .(0x07e72d33, 0xd94e, 0x4be7, 0x88, 0x43, 0x60, 0xae, 0x5f, 0xf7, 0xe5, 0xf5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMProfile.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidID) GetProfileID;
	}


	public HRESULT GetProfileID(Guid* pguidID) mut => VT.[Friend]GetProfileID(&this, pguidID);
}

[CRepr]struct IWMProfile3 : IWMProfile2
{
	public new const Guid IID = .(0x00ef96cc, 0xa461, 0x4546, 0x8b, 0xcd, 0xc9, 0xa2, 0x8f, 0x0e, 0x06, 0xf5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMProfile2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMT_STORAGE_FORMAT* pnStorageFormat) GetStorageFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMT_STORAGE_FORMAT nStorageFormat) SetStorageFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcBS) GetBandwidthSharingCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwBSIndex, IWMBandwidthSharing** ppBS) GetBandwidthSharing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMBandwidthSharing* pBS) RemoveBandwidthSharing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMBandwidthSharing* pBS) AddBandwidthSharing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMBandwidthSharing** ppBS) CreateNewBandwidthSharing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMStreamPrioritization** ppSP) GetStreamPrioritization;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMStreamPrioritization* pSP) SetStreamPrioritization;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveStreamPrioritization;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMStreamPrioritization** ppSP) CreateNewStreamPrioritization;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 msDuration, uint64* pcPackets) GetExpectedPacketCount;
	}


	public HRESULT GetStorageFormat(WMT_STORAGE_FORMAT* pnStorageFormat) mut => VT.[Friend]GetStorageFormat(&this, pnStorageFormat);

	public HRESULT SetStorageFormat(WMT_STORAGE_FORMAT nStorageFormat) mut => VT.[Friend]SetStorageFormat(&this, nStorageFormat);

	public HRESULT GetBandwidthSharingCount(uint32* pcBS) mut => VT.[Friend]GetBandwidthSharingCount(&this, pcBS);

	public HRESULT GetBandwidthSharing(uint32 dwBSIndex, IWMBandwidthSharing** ppBS) mut => VT.[Friend]GetBandwidthSharing(&this, dwBSIndex, ppBS);

	public HRESULT RemoveBandwidthSharing(IWMBandwidthSharing* pBS) mut => VT.[Friend]RemoveBandwidthSharing(&this, pBS);

	public HRESULT AddBandwidthSharing(IWMBandwidthSharing* pBS) mut => VT.[Friend]AddBandwidthSharing(&this, pBS);

	public HRESULT CreateNewBandwidthSharing(IWMBandwidthSharing** ppBS) mut => VT.[Friend]CreateNewBandwidthSharing(&this, ppBS);

	public HRESULT GetStreamPrioritization(IWMStreamPrioritization** ppSP) mut => VT.[Friend]GetStreamPrioritization(&this, ppSP);

	public HRESULT SetStreamPrioritization(IWMStreamPrioritization* pSP) mut => VT.[Friend]SetStreamPrioritization(&this, pSP);

	public HRESULT RemoveStreamPrioritization() mut => VT.[Friend]RemoveStreamPrioritization(&this);

	public HRESULT CreateNewStreamPrioritization(IWMStreamPrioritization** ppSP) mut => VT.[Friend]CreateNewStreamPrioritization(&this, ppSP);

	public HRESULT GetExpectedPacketCount(uint64 msDuration, uint64* pcPackets) mut => VT.[Friend]GetExpectedPacketCount(&this, msDuration, pcPackets);
}

[CRepr]struct IWMStreamConfig : IUnknown
{
	public new const Guid IID = .(0x96406bdc, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidStreamType) GetStreamType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwStreamNum) GetStreamNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum) SetStreamNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszStreamName, uint16* pcchStreamName) GetStreamName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszStreamName) SetStreamName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszInputName, uint16* pcchInputName) GetConnectionName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszInputName) SetConnectionName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwBitrate) GetBitrate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 pdwBitrate) SetBitrate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pmsBufferWindow) GetBufferWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 msBufferWindow) SetBufferWindow;
	}


	public HRESULT GetStreamType(Guid* pguidStreamType) mut => VT.[Friend]GetStreamType(&this, pguidStreamType);

	public HRESULT GetStreamNumber(uint16* pwStreamNum) mut => VT.[Friend]GetStreamNumber(&this, pwStreamNum);

	public HRESULT SetStreamNumber(uint16 wStreamNum) mut => VT.[Friend]SetStreamNumber(&this, wStreamNum);

	public HRESULT GetStreamName(char16* pwszStreamName, uint16* pcchStreamName) mut => VT.[Friend]GetStreamName(&this, pwszStreamName, pcchStreamName);

	public HRESULT SetStreamName(PWSTR pwszStreamName) mut => VT.[Friend]SetStreamName(&this, pwszStreamName);

	public HRESULT GetConnectionName(char16* pwszInputName, uint16* pcchInputName) mut => VT.[Friend]GetConnectionName(&this, pwszInputName, pcchInputName);

	public HRESULT SetConnectionName(PWSTR pwszInputName) mut => VT.[Friend]SetConnectionName(&this, pwszInputName);

	public HRESULT GetBitrate(uint32* pdwBitrate) mut => VT.[Friend]GetBitrate(&this, pdwBitrate);

	public HRESULT SetBitrate(uint32 pdwBitrate) mut => VT.[Friend]SetBitrate(&this, pdwBitrate);

	public HRESULT GetBufferWindow(uint32* pmsBufferWindow) mut => VT.[Friend]GetBufferWindow(&this, pmsBufferWindow);

	public HRESULT SetBufferWindow(uint32 msBufferWindow) mut => VT.[Friend]SetBufferWindow(&this, msBufferWindow);
}

[CRepr]struct IWMStreamConfig2 : IWMStreamConfig
{
	public new const Guid IID = .(0x7688d8cb, 0xfc0d, 0x43bd, 0x94, 0x59, 0x5a, 0x8d, 0xec, 0x20, 0x0c, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMStreamConfig.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMT_TRANSPORT_TYPE* pnTransportType) GetTransportType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMT_TRANSPORT_TYPE nTransportType) SetTransportType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid guidExtensionSystemID, uint16 cbExtensionDataSize, uint8* pbExtensionSystemInfo, uint32 cbExtensionSystemInfo) AddDataUnitExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pcDataUnitExtensions) GetDataUnitExtensionCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wDataUnitExtensionNumber, Guid* pguidExtensionSystemID, uint16* pcbExtensionDataSize, uint8* pbExtensionSystemInfo, uint32* pcbExtensionSystemInfo) GetDataUnitExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveAllDataUnitExtensions;
	}


	public HRESULT GetTransportType(WMT_TRANSPORT_TYPE* pnTransportType) mut => VT.[Friend]GetTransportType(&this, pnTransportType);

	public HRESULT SetTransportType(WMT_TRANSPORT_TYPE nTransportType) mut => VT.[Friend]SetTransportType(&this, nTransportType);

	public HRESULT AddDataUnitExtension(Guid guidExtensionSystemID, uint16 cbExtensionDataSize, uint8* pbExtensionSystemInfo, uint32 cbExtensionSystemInfo) mut => VT.[Friend]AddDataUnitExtension(&this, guidExtensionSystemID, cbExtensionDataSize, pbExtensionSystemInfo, cbExtensionSystemInfo);

	public HRESULT GetDataUnitExtensionCount(uint16* pcDataUnitExtensions) mut => VT.[Friend]GetDataUnitExtensionCount(&this, pcDataUnitExtensions);

	public HRESULT GetDataUnitExtension(uint16 wDataUnitExtensionNumber, Guid* pguidExtensionSystemID, uint16* pcbExtensionDataSize, uint8* pbExtensionSystemInfo, uint32* pcbExtensionSystemInfo) mut => VT.[Friend]GetDataUnitExtension(&this, wDataUnitExtensionNumber, pguidExtensionSystemID, pcbExtensionDataSize, pbExtensionSystemInfo, pcbExtensionSystemInfo);

	public HRESULT RemoveAllDataUnitExtensions() mut => VT.[Friend]RemoveAllDataUnitExtensions(&this);
}

[CRepr]struct IWMStreamConfig3 : IWMStreamConfig2
{
	public new const Guid IID = .(0xcb164104, 0x3aa9, 0x45a7, 0x9a, 0xc9, 0x4d, 0xae, 0xe1, 0x31, 0xd6, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMStreamConfig2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszLanguageString, uint16* pcchLanguageStringLength) GetLanguage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszLanguageString) SetLanguage;
	}


	public HRESULT GetLanguage(char16* pwszLanguageString, uint16* pcchLanguageStringLength) mut => VT.[Friend]GetLanguage(&this, pwszLanguageString, pcchLanguageStringLength);

	public HRESULT SetLanguage(PWSTR pwszLanguageString) mut => VT.[Friend]SetLanguage(&this, pwszLanguageString);
}

[CRepr]struct IWMPacketSize : IUnknown
{
	public new const Guid IID = .(0xcdfb97ab, 0x188f, 0x40b3, 0xb6, 0x43, 0x5b, 0x79, 0x03, 0x97, 0x5c, 0x59);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMaxPacketSize) GetMaxPacketSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMaxPacketSize) SetMaxPacketSize;
	}


	public HRESULT GetMaxPacketSize(uint32* pdwMaxPacketSize) mut => VT.[Friend]GetMaxPacketSize(&this, pdwMaxPacketSize);

	public HRESULT SetMaxPacketSize(uint32 dwMaxPacketSize) mut => VT.[Friend]SetMaxPacketSize(&this, dwMaxPacketSize);
}

[CRepr]struct IWMPacketSize2 : IWMPacketSize
{
	public new const Guid IID = .(0x8bfc2b9e, 0xb646, 0x4233, 0xa8, 0x77, 0x1c, 0x6a, 0x07, 0x96, 0x69, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPacketSize.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMinPacketSize) GetMinPacketSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMinPacketSize) SetMinPacketSize;
	}


	public HRESULT GetMinPacketSize(uint32* pdwMinPacketSize) mut => VT.[Friend]GetMinPacketSize(&this, pdwMinPacketSize);

	public HRESULT SetMinPacketSize(uint32 dwMinPacketSize) mut => VT.[Friend]SetMinPacketSize(&this, dwMinPacketSize);
}

[CRepr]struct IWMStreamList : IUnknown
{
	public new const Guid IID = .(0x96406bdd, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwStreamNumArray, uint16* pcStreams) GetStreams;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum) AddStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum) RemoveStream;
	}


	public HRESULT GetStreams(uint16* pwStreamNumArray, uint16* pcStreams) mut => VT.[Friend]GetStreams(&this, pwStreamNumArray, pcStreams);

	public HRESULT AddStream(uint16 wStreamNum) mut => VT.[Friend]AddStream(&this, wStreamNum);

	public HRESULT RemoveStream(uint16 wStreamNum) mut => VT.[Friend]RemoveStream(&this, wStreamNum);
}

[CRepr]struct IWMMutualExclusion : IWMStreamList
{
	public new const Guid IID = .(0x96406bde, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMStreamList.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidType) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidType) SetType;
	}


	public HRESULT GetType(Guid* pguidType) mut => VT.[Friend]COM_GetType(&this, pguidType);

	public HRESULT SetType(in Guid guidType) mut => VT.[Friend]SetType(&this, guidType);
}

[CRepr]struct IWMMutualExclusion2 : IWMMutualExclusion
{
	public new const Guid IID = .(0x0302b57d, 0x89d1, 0x4ba2, 0x85, 0xc9, 0x16, 0x6f, 0x2c, 0x53, 0xeb, 0x91);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMMutualExclusion.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszName, uint16* pcchName) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszName) SetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwRecordCount) GetRecordCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AddRecord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wRecordNumber) RemoveRecord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wRecordNumber, char16* pwszRecordName, uint16* pcchRecordName) GetRecordName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wRecordNumber, PWSTR pwszRecordName) SetRecordName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wRecordNumber, uint16* pwStreamNumArray, uint16* pcStreams) GetStreamsForRecord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wRecordNumber, uint16 wStreamNumber) AddStreamForRecord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wRecordNumber, uint16 wStreamNumber) RemoveStreamForRecord;
	}


	public HRESULT GetName(char16* pwszName, uint16* pcchName) mut => VT.[Friend]GetName(&this, pwszName, pcchName);

	public HRESULT SetName(PWSTR pwszName) mut => VT.[Friend]SetName(&this, pwszName);

	public HRESULT GetRecordCount(uint16* pwRecordCount) mut => VT.[Friend]GetRecordCount(&this, pwRecordCount);

	public HRESULT AddRecord() mut => VT.[Friend]AddRecord(&this);

	public HRESULT RemoveRecord(uint16 wRecordNumber) mut => VT.[Friend]RemoveRecord(&this, wRecordNumber);

	public HRESULT GetRecordName(uint16 wRecordNumber, char16* pwszRecordName, uint16* pcchRecordName) mut => VT.[Friend]GetRecordName(&this, wRecordNumber, pwszRecordName, pcchRecordName);

	public HRESULT SetRecordName(uint16 wRecordNumber, PWSTR pwszRecordName) mut => VT.[Friend]SetRecordName(&this, wRecordNumber, pwszRecordName);

	public HRESULT GetStreamsForRecord(uint16 wRecordNumber, uint16* pwStreamNumArray, uint16* pcStreams) mut => VT.[Friend]GetStreamsForRecord(&this, wRecordNumber, pwStreamNumArray, pcStreams);

	public HRESULT AddStreamForRecord(uint16 wRecordNumber, uint16 wStreamNumber) mut => VT.[Friend]AddStreamForRecord(&this, wRecordNumber, wStreamNumber);

	public HRESULT RemoveStreamForRecord(uint16 wRecordNumber, uint16 wStreamNumber) mut => VT.[Friend]RemoveStreamForRecord(&this, wRecordNumber, wStreamNumber);
}

[CRepr]struct IWMBandwidthSharing : IWMStreamList
{
	public new const Guid IID = .(0xad694af1, 0xf8d9, 0x42f8, 0xbc, 0x47, 0x70, 0x31, 0x1b, 0x0c, 0x4f, 0x9e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMStreamList.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidType) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidType) SetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwBitrate, uint32* pmsBufferWindow) GetBandwidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwBitrate, uint32 msBufferWindow) SetBandwidth;
	}


	public HRESULT GetType(Guid* pguidType) mut => VT.[Friend]COM_GetType(&this, pguidType);

	public HRESULT SetType(in Guid guidType) mut => VT.[Friend]SetType(&this, guidType);

	public HRESULT GetBandwidth(uint32* pdwBitrate, uint32* pmsBufferWindow) mut => VT.[Friend]GetBandwidth(&this, pdwBitrate, pmsBufferWindow);

	public HRESULT SetBandwidth(uint32 dwBitrate, uint32 msBufferWindow) mut => VT.[Friend]SetBandwidth(&this, dwBitrate, msBufferWindow);
}

[CRepr]struct IWMStreamPrioritization : IUnknown
{
	public new const Guid IID = .(0x8c1c6090, 0xf9a8, 0x4748, 0x8e, 0xc3, 0xdd, 0x11, 0x08, 0xba, 0x1e, 0x77);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WM_STREAM_PRIORITY_RECORD* pRecordArray, uint16* pcRecords) GetPriorityRecords;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WM_STREAM_PRIORITY_RECORD* pRecordArray, uint16 cRecords) SetPriorityRecords;
	}


	public HRESULT GetPriorityRecords(WM_STREAM_PRIORITY_RECORD* pRecordArray, uint16* pcRecords) mut => VT.[Friend]GetPriorityRecords(&this, pRecordArray, pcRecords);

	public HRESULT SetPriorityRecords(WM_STREAM_PRIORITY_RECORD* pRecordArray, uint16 cRecords) mut => VT.[Friend]SetPriorityRecords(&this, pRecordArray, cRecords);
}

[CRepr]struct IWMWriterAdvanced : IUnknown
{
	public new const Guid IID = .(0x96406be3, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcSinks) GetSinkCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSinkNum, IWMWriterSink** ppSink) GetSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMWriterSink* pSink) AddSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMWriterSink* pSink) RemoveSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, uint64 cnsSampleTime, uint32 msSampleSendTime, uint64 cnsSampleDuration, uint32 dwFlags, INSSBuffer* pSample) WriteStreamSample;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fIsLiveSource) SetLiveSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfRealTime) IsRealTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pcnsCurrentTime) GetWriterTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, WM_WRITER_STATISTICS* pStats) GetStatistics;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 msWindow) SetSyncTolerance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pmsWindow) GetSyncTolerance;
	}


	public HRESULT GetSinkCount(uint32* pcSinks) mut => VT.[Friend]GetSinkCount(&this, pcSinks);

	public HRESULT GetSink(uint32 dwSinkNum, IWMWriterSink** ppSink) mut => VT.[Friend]GetSink(&this, dwSinkNum, ppSink);

	public HRESULT AddSink(IWMWriterSink* pSink) mut => VT.[Friend]AddSink(&this, pSink);

	public HRESULT RemoveSink(IWMWriterSink* pSink) mut => VT.[Friend]RemoveSink(&this, pSink);

	public HRESULT WriteStreamSample(uint16 wStreamNum, uint64 cnsSampleTime, uint32 msSampleSendTime, uint64 cnsSampleDuration, uint32 dwFlags, INSSBuffer* pSample) mut => VT.[Friend]WriteStreamSample(&this, wStreamNum, cnsSampleTime, msSampleSendTime, cnsSampleDuration, dwFlags, pSample);

	public HRESULT SetLiveSource(BOOL fIsLiveSource) mut => VT.[Friend]SetLiveSource(&this, fIsLiveSource);

	public HRESULT IsRealTime(BOOL* pfRealTime) mut => VT.[Friend]IsRealTime(&this, pfRealTime);

	public HRESULT GetWriterTime(uint64* pcnsCurrentTime) mut => VT.[Friend]GetWriterTime(&this, pcnsCurrentTime);

	public HRESULT GetStatistics(uint16 wStreamNum, WM_WRITER_STATISTICS* pStats) mut => VT.[Friend]GetStatistics(&this, wStreamNum, pStats);

	public HRESULT SetSyncTolerance(uint32 msWindow) mut => VT.[Friend]SetSyncTolerance(&this, msWindow);

	public HRESULT GetSyncTolerance(uint32* pmsWindow) mut => VT.[Friend]GetSyncTolerance(&this, pmsWindow);
}

[CRepr]struct IWMWriterAdvanced2 : IWMWriterAdvanced
{
	public new const Guid IID = .(0x962dc1ec, 0xc046, 0x4db8, 0x9c, 0xc7, 0x26, 0xce, 0xae, 0x50, 0x08, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMWriterAdvanced.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputNum, PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint16* pcbLength) GetInputSetting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputNum, PWSTR pszName, WMT_ATTR_DATATYPE Type, uint8* pValue, uint16 cbLength) SetInputSetting;
	}


	public HRESULT GetInputSetting(uint32 dwInputNum, PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint16* pcbLength) mut => VT.[Friend]GetInputSetting(&this, dwInputNum, pszName, pType, pValue, pcbLength);

	public HRESULT SetInputSetting(uint32 dwInputNum, PWSTR pszName, WMT_ATTR_DATATYPE Type, uint8* pValue, uint16 cbLength) mut => VT.[Friend]SetInputSetting(&this, dwInputNum, pszName, Type, pValue, cbLength);
}

[CRepr]struct IWMWriterAdvanced3 : IWMWriterAdvanced2
{
	public new const Guid IID = .(0x2cd6492d, 0x7c37, 0x4e76, 0x9d, 0x3b, 0x59, 0x26, 0x11, 0x83, 0xa2, 0x2e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMWriterAdvanced2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, WM_WRITER_STATISTICS_EX* pStats) GetStatisticsEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetNonBlocking;
	}


	public HRESULT GetStatisticsEx(uint16 wStreamNum, WM_WRITER_STATISTICS_EX* pStats) mut => VT.[Friend]GetStatisticsEx(&this, wStreamNum, pStats);

	public HRESULT SetNonBlocking() mut => VT.[Friend]SetNonBlocking(&this);
}

[CRepr]struct IWMWriterPreprocess : IUnknown
{
	public new const Guid IID = .(0xfc54a285, 0x38c4, 0x45b5, 0xaa, 0x23, 0x85, 0xb9, 0xf7, 0xcb, 0x42, 0x4b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputNum, uint32 dwFlags, uint32* pdwMaxNumPasses) GetMaxPreprocessingPasses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputNum, uint32 dwFlags, uint32 dwNumPasses) SetNumPreprocessingPasses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputNum, uint32 dwFlags) BeginPreprocessingPass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputNum, uint64 cnsSampleTime, uint32 dwFlags, INSSBuffer* pSample) PreprocessSample;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputNum, uint32 dwFlags) EndPreprocessingPass;
	}


	public HRESULT GetMaxPreprocessingPasses(uint32 dwInputNum, uint32 dwFlags, uint32* pdwMaxNumPasses) mut => VT.[Friend]GetMaxPreprocessingPasses(&this, dwInputNum, dwFlags, pdwMaxNumPasses);

	public HRESULT SetNumPreprocessingPasses(uint32 dwInputNum, uint32 dwFlags, uint32 dwNumPasses) mut => VT.[Friend]SetNumPreprocessingPasses(&this, dwInputNum, dwFlags, dwNumPasses);

	public HRESULT BeginPreprocessingPass(uint32 dwInputNum, uint32 dwFlags) mut => VT.[Friend]BeginPreprocessingPass(&this, dwInputNum, dwFlags);

	public HRESULT PreprocessSample(uint32 dwInputNum, uint64 cnsSampleTime, uint32 dwFlags, INSSBuffer* pSample) mut => VT.[Friend]PreprocessSample(&this, dwInputNum, cnsSampleTime, dwFlags, pSample);

	public HRESULT EndPreprocessingPass(uint32 dwInputNum, uint32 dwFlags) mut => VT.[Friend]EndPreprocessingPass(&this, dwInputNum, dwFlags);
}

[CRepr]struct IWMWriterPostViewCallback : IWMStatusCallback
{
	public new const Guid IID = .(0xd9d6549d, 0xa193, 0x4f24, 0xb3, 0x08, 0x03, 0x12, 0x3d, 0x9b, 0x7f, 0x8d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMStatusCallback.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNumber, uint64 cnsSampleTime, uint64 cnsSampleDuration, uint32 dwFlags, INSSBuffer* pSample, void* pvContext) OnPostViewSample;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, uint32 cbBuffer, INSSBuffer** ppBuffer, void* pvContext) AllocateForPostView;
	}


	public HRESULT OnPostViewSample(uint16 wStreamNumber, uint64 cnsSampleTime, uint64 cnsSampleDuration, uint32 dwFlags, INSSBuffer* pSample, void* pvContext) mut => VT.[Friend]OnPostViewSample(&this, wStreamNumber, cnsSampleTime, cnsSampleDuration, dwFlags, pSample, pvContext);

	public HRESULT AllocateForPostView(uint16 wStreamNum, uint32 cbBuffer, INSSBuffer** ppBuffer, void* pvContext) mut => VT.[Friend]AllocateForPostView(&this, wStreamNum, cbBuffer, ppBuffer, pvContext);
}

[CRepr]struct IWMWriterPostView : IUnknown
{
	public new const Guid IID = .(0x81e20ce4, 0x75ef, 0x491a, 0x80, 0x04, 0xfc, 0x53, 0xc4, 0x5b, 0xdc, 0x3e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMWriterPostViewCallback* pCallback, void* pvContext) SetPostViewCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, BOOL fReceivePostViewSamples) SetReceivePostViewSamples;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, BOOL* pfReceivePostViewSamples) GetReceivePostViewSamples;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNumber, IWMMediaProps** ppOutput) GetPostViewProps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNumber, IWMMediaProps* pOutput) SetPostViewProps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNumber, uint32* pcFormats) GetPostViewFormatCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNumber, uint32 dwFormatNumber, IWMMediaProps** ppProps) GetPostViewFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNumber, BOOL fAllocate) SetAllocateForPostView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNumber, BOOL* pfAllocate) GetAllocateForPostView;
	}


	public HRESULT SetPostViewCallback(IWMWriterPostViewCallback* pCallback, void* pvContext) mut => VT.[Friend]SetPostViewCallback(&this, pCallback, pvContext);

	public HRESULT SetReceivePostViewSamples(uint16 wStreamNum, BOOL fReceivePostViewSamples) mut => VT.[Friend]SetReceivePostViewSamples(&this, wStreamNum, fReceivePostViewSamples);

	public HRESULT GetReceivePostViewSamples(uint16 wStreamNum, BOOL* pfReceivePostViewSamples) mut => VT.[Friend]GetReceivePostViewSamples(&this, wStreamNum, pfReceivePostViewSamples);

	public HRESULT GetPostViewProps(uint16 wStreamNumber, IWMMediaProps** ppOutput) mut => VT.[Friend]GetPostViewProps(&this, wStreamNumber, ppOutput);

	public HRESULT SetPostViewProps(uint16 wStreamNumber, IWMMediaProps* pOutput) mut => VT.[Friend]SetPostViewProps(&this, wStreamNumber, pOutput);

	public HRESULT GetPostViewFormatCount(uint16 wStreamNumber, uint32* pcFormats) mut => VT.[Friend]GetPostViewFormatCount(&this, wStreamNumber, pcFormats);

	public HRESULT GetPostViewFormat(uint16 wStreamNumber, uint32 dwFormatNumber, IWMMediaProps** ppProps) mut => VT.[Friend]GetPostViewFormat(&this, wStreamNumber, dwFormatNumber, ppProps);

	public HRESULT SetAllocateForPostView(uint16 wStreamNumber, BOOL fAllocate) mut => VT.[Friend]SetAllocateForPostView(&this, wStreamNumber, fAllocate);

	public HRESULT GetAllocateForPostView(uint16 wStreamNumber, BOOL* pfAllocate) mut => VT.[Friend]GetAllocateForPostView(&this, wStreamNumber, pfAllocate);
}

[CRepr]struct IWMWriterSink : IUnknown
{
	public new const Guid IID = .(0x96406be4, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INSSBuffer* pHeader) OnHeader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfRealTime) IsRealTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbDataUnit, INSSBuffer** ppDataUnit) AllocateDataUnit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INSSBuffer* pDataUnit) OnDataUnit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnEndWriting;
	}


	public HRESULT OnHeader(INSSBuffer* pHeader) mut => VT.[Friend]OnHeader(&this, pHeader);

	public HRESULT IsRealTime(BOOL* pfRealTime) mut => VT.[Friend]IsRealTime(&this, pfRealTime);

	public HRESULT AllocateDataUnit(uint32 cbDataUnit, INSSBuffer** ppDataUnit) mut => VT.[Friend]AllocateDataUnit(&this, cbDataUnit, ppDataUnit);

	public HRESULT OnDataUnit(INSSBuffer* pDataUnit) mut => VT.[Friend]OnDataUnit(&this, pDataUnit);

	public HRESULT OnEndWriting() mut => VT.[Friend]OnEndWriting(&this);
}

[CRepr]struct IWMRegisterCallback : IUnknown
{
	public new const Guid IID = .(0xcf4b1f99, 0x4de2, 0x4e49, 0xa3, 0x63, 0x25, 0x27, 0x40, 0xd9, 0x9b, 0xc1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMStatusCallback* pCallback, void* pvContext) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMStatusCallback* pCallback, void* pvContext) Unadvise;
	}


	public HRESULT Advise(IWMStatusCallback* pCallback, void* pvContext) mut => VT.[Friend]Advise(&this, pCallback, pvContext);

	public HRESULT Unadvise(IWMStatusCallback* pCallback, void* pvContext) mut => VT.[Friend]Unadvise(&this, pCallback, pvContext);
}

[CRepr]struct IWMWriterFileSink : IWMWriterSink
{
	public new const Guid IID = .(0x96406be5, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMWriterSink.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszFilename) Open;
	}


	public HRESULT Open(PWSTR pwszFilename) mut => VT.[Friend]Open(&this, pwszFilename);
}

[CRepr]struct IWMWriterFileSink2 : IWMWriterFileSink
{
	public new const Guid IID = .(0x14282ba7, 0x4aef, 0x4205, 0x8c, 0xe5, 0xc2, 0x29, 0x03, 0x5a, 0x05, 0xbc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMWriterFileSink.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 cnsStartTime) Start;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 cnsStopTime) Stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfStopped) IsStopped;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pcnsDuration) GetFileDuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pcbFile) GetFileSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfClosed) IsClosed;
	}


	public HRESULT Start(uint64 cnsStartTime) mut => VT.[Friend]Start(&this, cnsStartTime);

	public HRESULT Stop(uint64 cnsStopTime) mut => VT.[Friend]Stop(&this, cnsStopTime);

	public HRESULT IsStopped(BOOL* pfStopped) mut => VT.[Friend]IsStopped(&this, pfStopped);

	public HRESULT GetFileDuration(uint64* pcnsDuration) mut => VT.[Friend]GetFileDuration(&this, pcnsDuration);

	public HRESULT GetFileSize(uint64* pcbFile) mut => VT.[Friend]GetFileSize(&this, pcbFile);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT IsClosed(BOOL* pfClosed) mut => VT.[Friend]IsClosed(&this, pfClosed);
}

[CRepr]struct IWMWriterFileSink3 : IWMWriterFileSink2
{
	public new const Guid IID = .(0x3fea4feb, 0x2945, 0x47a7, 0xa1, 0xdd, 0xc5, 0x3a, 0x8f, 0xc4, 0xc4, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMWriterFileSink2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fDoAutoIndexing) SetAutoIndexing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfAutoIndexing) GetAutoIndexing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNumber, BOOL fShouldControlStartAndStop) SetControlStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFileSinkMode) GetMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMT_FILESINK_DATA_UNIT* pFileSinkDataUnit) OnDataUnitEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fUnbufferedIO, BOOL fRestrictMemUsage) SetUnbufferedIO;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfUnbufferedIO) GetUnbufferedIO;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CompleteOperations;
	}


	public HRESULT SetAutoIndexing(BOOL fDoAutoIndexing) mut => VT.[Friend]SetAutoIndexing(&this, fDoAutoIndexing);

	public HRESULT GetAutoIndexing(BOOL* pfAutoIndexing) mut => VT.[Friend]GetAutoIndexing(&this, pfAutoIndexing);

	public HRESULT SetControlStream(uint16 wStreamNumber, BOOL fShouldControlStartAndStop) mut => VT.[Friend]SetControlStream(&this, wStreamNumber, fShouldControlStartAndStop);

	public HRESULT GetMode(uint32* pdwFileSinkMode) mut => VT.[Friend]GetMode(&this, pdwFileSinkMode);

	public HRESULT OnDataUnitEx(WMT_FILESINK_DATA_UNIT* pFileSinkDataUnit) mut => VT.[Friend]OnDataUnitEx(&this, pFileSinkDataUnit);

	public HRESULT SetUnbufferedIO(BOOL fUnbufferedIO, BOOL fRestrictMemUsage) mut => VT.[Friend]SetUnbufferedIO(&this, fUnbufferedIO, fRestrictMemUsage);

	public HRESULT GetUnbufferedIO(BOOL* pfUnbufferedIO) mut => VT.[Friend]GetUnbufferedIO(&this, pfUnbufferedIO);

	public HRESULT CompleteOperations() mut => VT.[Friend]CompleteOperations(&this);
}

[CRepr]struct IWMWriterNetworkSink : IWMWriterSink
{
	public new const Guid IID = .(0x96406be7, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMWriterSink.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMaxClients) SetMaximumClients;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMaxClients) GetMaximumClients;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMT_NET_PROTOCOL protocol) SetNetworkProtocol;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMT_NET_PROTOCOL* pProtocol) GetNetworkProtocol;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszURL, uint32* pcchURL) GetHostURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwPortNum) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Disconnect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
	}


	public HRESULT SetMaximumClients(uint32 dwMaxClients) mut => VT.[Friend]SetMaximumClients(&this, dwMaxClients);

	public HRESULT GetMaximumClients(uint32* pdwMaxClients) mut => VT.[Friend]GetMaximumClients(&this, pdwMaxClients);

	public HRESULT SetNetworkProtocol(WMT_NET_PROTOCOL protocol) mut => VT.[Friend]SetNetworkProtocol(&this, protocol);

	public HRESULT GetNetworkProtocol(WMT_NET_PROTOCOL* pProtocol) mut => VT.[Friend]GetNetworkProtocol(&this, pProtocol);

	public HRESULT GetHostURL(PWSTR pwszURL, uint32* pcchURL) mut => VT.[Friend]GetHostURL(&this, pwszURL, pcchURL);

	public HRESULT Open(uint32* pdwPortNum) mut => VT.[Friend]Open(&this, pdwPortNum);

	public HRESULT Disconnect() mut => VT.[Friend]Disconnect(&this);

	public HRESULT Close() mut => VT.[Friend]Close(&this);
}

[CRepr]struct IWMClientConnections : IUnknown
{
	public new const Guid IID = .(0x73c66010, 0xa299, 0x41df, 0xb1, 0xf0, 0xcc, 0xf0, 0x3b, 0x09, 0xc1, 0xc6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcClients) GetClientCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwClientNum, WM_CLIENT_PROPERTIES* pClientProperties) GetClientProperties;
	}


	public HRESULT GetClientCount(uint32* pcClients) mut => VT.[Friend]GetClientCount(&this, pcClients);

	public HRESULT GetClientProperties(uint32 dwClientNum, WM_CLIENT_PROPERTIES* pClientProperties) mut => VT.[Friend]GetClientProperties(&this, dwClientNum, pClientProperties);
}

[CRepr]struct IWMClientConnections2 : IWMClientConnections
{
	public new const Guid IID = .(0x4091571e, 0x4701, 0x4593, 0xbb, 0x3d, 0xd5, 0xf5, 0xf0, 0xc7, 0x42, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMClientConnections.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwClientNum, char16* pwszNetworkAddress, uint32* pcchNetworkAddress, char16* pwszPort, uint32* pcchPort, char16* pwszDNSName, uint32* pcchDNSName) GetClientInfo;
	}


	public HRESULT GetClientInfo(uint32 dwClientNum, char16* pwszNetworkAddress, uint32* pcchNetworkAddress, char16* pwszPort, uint32* pcchPort, char16* pwszDNSName, uint32* pcchDNSName) mut => VT.[Friend]GetClientInfo(&this, dwClientNum, pwszNetworkAddress, pcchNetworkAddress, pwszPort, pcchPort, pwszDNSName, pcchDNSName);
}

[CRepr]struct IWMReaderAdvanced : IUnknown
{
	public new const Guid IID = .(0x96406bea, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fUserClock) SetUserProvidedClock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfUserClock) GetUserProvidedClock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 cnsTime) DeliverTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fSelection) SetManualStreamSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfSelection) GetManualStreamSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 cStreamCount, uint16* pwStreamNumbers, WMT_STREAM_SELECTION* pSelections) SetStreamsSelected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, WMT_STREAM_SELECTION* pSelection) GetStreamSelected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fGetCallbacks) SetReceiveSelectionCallbacks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfGetCallbacks) GetReceiveSelectionCallbacks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, BOOL fReceiveStreamSamples) SetReceiveStreamSamples;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, BOOL* pfReceiveStreamSamples) GetReceiveStreamSamples;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, BOOL fAllocate) SetAllocateForOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, BOOL* pfAllocate) GetAllocateForOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, BOOL fAllocate) SetAllocateForStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 dwSreamNum, BOOL* pfAllocate) GetAllocateForStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WM_READER_STATISTICS* pStatistics) GetStatistics;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WM_READER_CLIENTINFO* pClientInfo) SetClientInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutput, uint32* pcbMax) GetMaxOutputSampleSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStream, uint32* pcbMax) GetMaxStreamSampleSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 cnsLateness) NotifyLateDelivery;
	}


	public HRESULT SetUserProvidedClock(BOOL fUserClock) mut => VT.[Friend]SetUserProvidedClock(&this, fUserClock);

	public HRESULT GetUserProvidedClock(BOOL* pfUserClock) mut => VT.[Friend]GetUserProvidedClock(&this, pfUserClock);

	public HRESULT DeliverTime(uint64 cnsTime) mut => VT.[Friend]DeliverTime(&this, cnsTime);

	public HRESULT SetManualStreamSelection(BOOL fSelection) mut => VT.[Friend]SetManualStreamSelection(&this, fSelection);

	public HRESULT GetManualStreamSelection(BOOL* pfSelection) mut => VT.[Friend]GetManualStreamSelection(&this, pfSelection);

	public HRESULT SetStreamsSelected(uint16 cStreamCount, uint16* pwStreamNumbers, WMT_STREAM_SELECTION* pSelections) mut => VT.[Friend]SetStreamsSelected(&this, cStreamCount, pwStreamNumbers, pSelections);

	public HRESULT GetStreamSelected(uint16 wStreamNum, WMT_STREAM_SELECTION* pSelection) mut => VT.[Friend]GetStreamSelected(&this, wStreamNum, pSelection);

	public HRESULT SetReceiveSelectionCallbacks(BOOL fGetCallbacks) mut => VT.[Friend]SetReceiveSelectionCallbacks(&this, fGetCallbacks);

	public HRESULT GetReceiveSelectionCallbacks(BOOL* pfGetCallbacks) mut => VT.[Friend]GetReceiveSelectionCallbacks(&this, pfGetCallbacks);

	public HRESULT SetReceiveStreamSamples(uint16 wStreamNum, BOOL fReceiveStreamSamples) mut => VT.[Friend]SetReceiveStreamSamples(&this, wStreamNum, fReceiveStreamSamples);

	public HRESULT GetReceiveStreamSamples(uint16 wStreamNum, BOOL* pfReceiveStreamSamples) mut => VT.[Friend]GetReceiveStreamSamples(&this, wStreamNum, pfReceiveStreamSamples);

	public HRESULT SetAllocateForOutput(uint32 dwOutputNum, BOOL fAllocate) mut => VT.[Friend]SetAllocateForOutput(&this, dwOutputNum, fAllocate);

	public HRESULT GetAllocateForOutput(uint32 dwOutputNum, BOOL* pfAllocate) mut => VT.[Friend]GetAllocateForOutput(&this, dwOutputNum, pfAllocate);

	public HRESULT SetAllocateForStream(uint16 wStreamNum, BOOL fAllocate) mut => VT.[Friend]SetAllocateForStream(&this, wStreamNum, fAllocate);

	public HRESULT GetAllocateForStream(uint16 dwSreamNum, BOOL* pfAllocate) mut => VT.[Friend]GetAllocateForStream(&this, dwSreamNum, pfAllocate);

	public HRESULT GetStatistics(WM_READER_STATISTICS* pStatistics) mut => VT.[Friend]GetStatistics(&this, pStatistics);

	public HRESULT SetClientInfo(WM_READER_CLIENTINFO* pClientInfo) mut => VT.[Friend]SetClientInfo(&this, pClientInfo);

	public HRESULT GetMaxOutputSampleSize(uint32 dwOutput, uint32* pcbMax) mut => VT.[Friend]GetMaxOutputSampleSize(&this, dwOutput, pcbMax);

	public HRESULT GetMaxStreamSampleSize(uint16 wStream, uint32* pcbMax) mut => VT.[Friend]GetMaxStreamSampleSize(&this, wStream, pcbMax);

	public HRESULT NotifyLateDelivery(uint64 cnsLateness) mut => VT.[Friend]NotifyLateDelivery(&this, cnsLateness);
}

[CRepr]struct IWMReaderAdvanced2 : IWMReaderAdvanced
{
	public new const Guid IID = .(0xae14a945, 0xb90c, 0x4d0d, 0x91, 0x27, 0x80, 0xd6, 0x65, 0xf7, 0xd7, 0x3e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMReaderAdvanced.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMT_PLAY_MODE Mode) SetPlayMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMT_PLAY_MODE* pMode) GetPlayMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwPercent, uint64* pcnsBuffering) GetBufferProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwPercent, uint64* pqwBytesDownloaded, uint64* pcnsDownload) GetDownloadProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwPercent) GetSaveAsProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszFilename) SaveFileAs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszProtocol, uint32* pcchProtocol) GetProtocolName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wMarkerIndex, uint64 cnsDuration, float fRate, void* pvContext) StartAtMarker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint16* pcbLength) GetOutputSetting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, PWSTR pszName, WMT_ATTR_DATATYPE Type, uint8* pValue, uint16 cbLength) SetOutputSetting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 cnsStart, uint64 cnsDuration, float fRate) Preroll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fLogClientID) SetLogClientID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfLogClientID) GetLogClientID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StopBuffering;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStream, IWMReaderCallback* pCallback, void* pvContext) OpenStream;
	}


	public HRESULT SetPlayMode(WMT_PLAY_MODE Mode) mut => VT.[Friend]SetPlayMode(&this, Mode);

	public HRESULT GetPlayMode(WMT_PLAY_MODE* pMode) mut => VT.[Friend]GetPlayMode(&this, pMode);

	public HRESULT GetBufferProgress(uint32* pdwPercent, uint64* pcnsBuffering) mut => VT.[Friend]GetBufferProgress(&this, pdwPercent, pcnsBuffering);

	public HRESULT GetDownloadProgress(uint32* pdwPercent, uint64* pqwBytesDownloaded, uint64* pcnsDownload) mut => VT.[Friend]GetDownloadProgress(&this, pdwPercent, pqwBytesDownloaded, pcnsDownload);

	public HRESULT GetSaveAsProgress(uint32* pdwPercent) mut => VT.[Friend]GetSaveAsProgress(&this, pdwPercent);

	public HRESULT SaveFileAs(PWSTR pwszFilename) mut => VT.[Friend]SaveFileAs(&this, pwszFilename);

	public HRESULT GetProtocolName(char16* pwszProtocol, uint32* pcchProtocol) mut => VT.[Friend]GetProtocolName(&this, pwszProtocol, pcchProtocol);

	public HRESULT StartAtMarker(uint16 wMarkerIndex, uint64 cnsDuration, float fRate, void* pvContext) mut => VT.[Friend]StartAtMarker(&this, wMarkerIndex, cnsDuration, fRate, pvContext);

	public HRESULT GetOutputSetting(uint32 dwOutputNum, PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint16* pcbLength) mut => VT.[Friend]GetOutputSetting(&this, dwOutputNum, pszName, pType, pValue, pcbLength);

	public HRESULT SetOutputSetting(uint32 dwOutputNum, PWSTR pszName, WMT_ATTR_DATATYPE Type, uint8* pValue, uint16 cbLength) mut => VT.[Friend]SetOutputSetting(&this, dwOutputNum, pszName, Type, pValue, cbLength);

	public HRESULT Preroll(uint64 cnsStart, uint64 cnsDuration, float fRate) mut => VT.[Friend]Preroll(&this, cnsStart, cnsDuration, fRate);

	public HRESULT SetLogClientID(BOOL fLogClientID) mut => VT.[Friend]SetLogClientID(&this, fLogClientID);

	public HRESULT GetLogClientID(BOOL* pfLogClientID) mut => VT.[Friend]GetLogClientID(&this, pfLogClientID);

	public HRESULT StopBuffering() mut => VT.[Friend]StopBuffering(&this);

	public HRESULT OpenStream(IStream* pStream, IWMReaderCallback* pCallback, void* pvContext) mut => VT.[Friend]OpenStream(&this, pStream, pCallback, pvContext);
}

[CRepr]struct IWMReaderAdvanced3 : IWMReaderAdvanced2
{
	public new const Guid IID = .(0x5dc0674b, 0xf04b, 0x4a4e, 0x9f, 0x2a, 0xb1, 0xaf, 0xde, 0x2c, 0x81, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMReaderAdvanced2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StopNetStreaming;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, void* pvOffsetStart, void* pvDuration, WMT_OFFSET_FORMAT dwOffsetFormat, float fRate, void* pvContext) StartAtPosition;
	}


	public HRESULT StopNetStreaming() mut => VT.[Friend]StopNetStreaming(&this);

	public HRESULT StartAtPosition(uint16 wStreamNum, void* pvOffsetStart, void* pvDuration, WMT_OFFSET_FORMAT dwOffsetFormat, float fRate, void* pvContext) mut => VT.[Friend]StartAtPosition(&this, wStreamNum, pvOffsetStart, pvDuration, dwOffsetFormat, fRate, pvContext);
}

[CRepr]struct IWMReaderAdvanced4 : IWMReaderAdvanced3
{
	public new const Guid IID = .(0x945a76a2, 0x12ae, 0x4d48, 0xbd, 0x3c, 0xcd, 0x1d, 0x90, 0x39, 0x9b, 0x85);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMReaderAdvanced3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, uint16* pwLanguageCount) GetLanguageCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, uint16 wLanguage, char16* pwszLanguageString, uint16* pcchLanguageStringLength) GetLanguage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdblFactor) GetMaxSpeedFactor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfUsingFastCache) IsUsingFastCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszNameSpace, PWSTR wszName, PWSTR wszValue) AddLogParam;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SendLogParams;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfCanSave) CanSaveFileAs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelSaveFileAs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszURL, uint32* pcchURL) GetURL;
	}


	public HRESULT GetLanguageCount(uint32 dwOutputNum, uint16* pwLanguageCount) mut => VT.[Friend]GetLanguageCount(&this, dwOutputNum, pwLanguageCount);

	public HRESULT GetLanguage(uint32 dwOutputNum, uint16 wLanguage, char16* pwszLanguageString, uint16* pcchLanguageStringLength) mut => VT.[Friend]GetLanguage(&this, dwOutputNum, wLanguage, pwszLanguageString, pcchLanguageStringLength);

	public HRESULT GetMaxSpeedFactor(double* pdblFactor) mut => VT.[Friend]GetMaxSpeedFactor(&this, pdblFactor);

	public HRESULT IsUsingFastCache(BOOL* pfUsingFastCache) mut => VT.[Friend]IsUsingFastCache(&this, pfUsingFastCache);

	public HRESULT AddLogParam(PWSTR wszNameSpace, PWSTR wszName, PWSTR wszValue) mut => VT.[Friend]AddLogParam(&this, wszNameSpace, wszName, wszValue);

	public HRESULT SendLogParams() mut => VT.[Friend]SendLogParams(&this);

	public HRESULT CanSaveFileAs(BOOL* pfCanSave) mut => VT.[Friend]CanSaveFileAs(&this, pfCanSave);

	public HRESULT CancelSaveFileAs() mut => VT.[Friend]CancelSaveFileAs(&this);

	public HRESULT GetURL(char16* pwszURL, uint32* pcchURL) mut => VT.[Friend]GetURL(&this, pwszURL, pcchURL);
}

[CRepr]struct IWMReaderAdvanced5 : IWMReaderAdvanced4
{
	public new const Guid IID = .(0x24c44db0, 0x55d1, 0x49ae, 0xa5, 0xcc, 0xf1, 0x38, 0x15, 0xe3, 0x63, 0x63);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMReaderAdvanced4.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, IWMPlayerHook* pHook) SetPlayerHook;
	}


	public HRESULT SetPlayerHook(uint32 dwOutputNum, IWMPlayerHook* pHook) mut => VT.[Friend]SetPlayerHook(&this, dwOutputNum, pHook);
}

[CRepr]struct IWMReaderAdvanced6 : IWMReaderAdvanced5
{
	public new const Guid IID = .(0x18a2e7f8, 0x428f, 0x4acd, 0x8a, 0x00, 0xe6, 0x46, 0x39, 0xbc, 0x93, 0xde);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMReaderAdvanced5.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbCertificate, uint32 cbCertificate, uint32 dwCertificateType, uint32 dwFlags, uint8* pbInitializationVector, uint32* pcbInitializationVector) SetProtectStreamSamples;
	}


	public HRESULT SetProtectStreamSamples(uint8* pbCertificate, uint32 cbCertificate, uint32 dwCertificateType, uint32 dwFlags, uint8* pbInitializationVector, uint32* pcbInitializationVector) mut => VT.[Friend]SetProtectStreamSamples(&this, pbCertificate, cbCertificate, dwCertificateType, dwFlags, pbInitializationVector, pcbInitializationVector);
}

[CRepr]struct IWMPlayerHook : IUnknown
{
	public new const Guid IID = .(0xe5b7ca9a, 0x0f1c, 0x4f66, 0x90, 0x02, 0x74, 0xec, 0x50, 0xd8, 0xb3, 0x04);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) PreDecode;
	}


	public HRESULT PreDecode() mut => VT.[Friend]PreDecode(&this);
}

[CRepr]struct IWMReaderAllocatorEx : IUnknown
{
	public new const Guid IID = .(0x9f762fa7, 0xa22e, 0x428d, 0x93, 0xc9, 0xac, 0x82, 0xf3, 0xaa, 0xfe, 0x5a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, uint32 cbBuffer, INSSBuffer** ppBuffer, uint32 dwFlags, uint64 cnsSampleTime, uint64 cnsSampleDuration, void* pvContext) AllocateForStreamEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, uint32 cbBuffer, INSSBuffer** ppBuffer, uint32 dwFlags, uint64 cnsSampleTime, uint64 cnsSampleDuration, void* pvContext) AllocateForOutputEx;
	}


	public HRESULT AllocateForStreamEx(uint16 wStreamNum, uint32 cbBuffer, INSSBuffer** ppBuffer, uint32 dwFlags, uint64 cnsSampleTime, uint64 cnsSampleDuration, void* pvContext) mut => VT.[Friend]AllocateForStreamEx(&this, wStreamNum, cbBuffer, ppBuffer, dwFlags, cnsSampleTime, cnsSampleDuration, pvContext);

	public HRESULT AllocateForOutputEx(uint32 dwOutputNum, uint32 cbBuffer, INSSBuffer** ppBuffer, uint32 dwFlags, uint64 cnsSampleTime, uint64 cnsSampleDuration, void* pvContext) mut => VT.[Friend]AllocateForOutputEx(&this, dwOutputNum, cbBuffer, ppBuffer, dwFlags, cnsSampleTime, cnsSampleDuration, pvContext);
}

[CRepr]struct IWMReaderTypeNegotiation : IUnknown
{
	public new const Guid IID = .(0xfdbe5592, 0x81a1, 0x41ea, 0x93, 0xbd, 0x73, 0x5c, 0xad, 0x1a, 0xdc, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, IWMOutputMediaProps* pOutput) TryOutputProps;
	}


	public HRESULT TryOutputProps(uint32 dwOutputNum, IWMOutputMediaProps* pOutput) mut => VT.[Friend]TryOutputProps(&this, dwOutputNum, pOutput);
}

[CRepr]struct IWMReaderCallbackAdvanced : IUnknown
{
	public new const Guid IID = .(0x96406beb, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, uint64 cnsSampleTime, uint64 cnsSampleDuration, uint32 dwFlags, INSSBuffer* pSample, void* pvContext) OnStreamSample;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 cnsCurrentTime, void* pvContext) OnTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamCount, uint16* pStreamNumbers, WMT_STREAM_SELECTION* pSelections, void* pvContext) OnStreamSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, WM_MEDIA_TYPE* pMediaType, void* pvContext) OnOutputPropsChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, uint32 cbBuffer, INSSBuffer** ppBuffer, void* pvContext) AllocateForStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, uint32 cbBuffer, INSSBuffer** ppBuffer, void* pvContext) AllocateForOutput;
	}


	public HRESULT OnStreamSample(uint16 wStreamNum, uint64 cnsSampleTime, uint64 cnsSampleDuration, uint32 dwFlags, INSSBuffer* pSample, void* pvContext) mut => VT.[Friend]OnStreamSample(&this, wStreamNum, cnsSampleTime, cnsSampleDuration, dwFlags, pSample, pvContext);

	public HRESULT OnTime(uint64 cnsCurrentTime, void* pvContext) mut => VT.[Friend]OnTime(&this, cnsCurrentTime, pvContext);

	public HRESULT OnStreamSelection(uint16 wStreamCount, uint16* pStreamNumbers, WMT_STREAM_SELECTION* pSelections, void* pvContext) mut => VT.[Friend]OnStreamSelection(&this, wStreamCount, pStreamNumbers, pSelections, pvContext);

	public HRESULT OnOutputPropsChanged(uint32 dwOutputNum, WM_MEDIA_TYPE* pMediaType, void* pvContext) mut => VT.[Friend]OnOutputPropsChanged(&this, dwOutputNum, pMediaType, pvContext);

	public HRESULT AllocateForStream(uint16 wStreamNum, uint32 cbBuffer, INSSBuffer** ppBuffer, void* pvContext) mut => VT.[Friend]AllocateForStream(&this, wStreamNum, cbBuffer, ppBuffer, pvContext);

	public HRESULT AllocateForOutput(uint32 dwOutputNum, uint32 cbBuffer, INSSBuffer** ppBuffer, void* pvContext) mut => VT.[Friend]AllocateForOutput(&this, dwOutputNum, cbBuffer, ppBuffer, pvContext);
}

[CRepr]struct IWMDRMReader : IUnknown
{
	public new const Guid IID = .(0xd2827540, 0x3ee7, 0x432c, 0xb1, 0x4c, 0xdc, 0x17, 0xf0, 0x85, 0xd3, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) AcquireLicense;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelLicenseAcquisition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) Individualize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelIndividualization;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) MonitorLicenseAcquisition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelMonitorLicenseAcquisition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwstrName, WMT_ATTR_DATATYPE dwType, uint8* pValue, uint16 cbLength) SetDRMProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwstrName, WMT_ATTR_DATATYPE* pdwType, uint8* pValue, uint16* pcbLength) GetDRMProperty;
	}


	public HRESULT AcquireLicense(uint32 dwFlags) mut => VT.[Friend]AcquireLicense(&this, dwFlags);

	public HRESULT CancelLicenseAcquisition() mut => VT.[Friend]CancelLicenseAcquisition(&this);

	public HRESULT Individualize(uint32 dwFlags) mut => VT.[Friend]Individualize(&this, dwFlags);

	public HRESULT CancelIndividualization() mut => VT.[Friend]CancelIndividualization(&this);

	public HRESULT MonitorLicenseAcquisition() mut => VT.[Friend]MonitorLicenseAcquisition(&this);

	public HRESULT CancelMonitorLicenseAcquisition() mut => VT.[Friend]CancelMonitorLicenseAcquisition(&this);

	public HRESULT SetDRMProperty(PWSTR pwstrName, WMT_ATTR_DATATYPE dwType, uint8* pValue, uint16 cbLength) mut => VT.[Friend]SetDRMProperty(&this, pwstrName, dwType, pValue, cbLength);

	public HRESULT GetDRMProperty(PWSTR pwstrName, WMT_ATTR_DATATYPE* pdwType, uint8* pValue, uint16* pcbLength) mut => VT.[Friend]GetDRMProperty(&this, pwstrName, pdwType, pValue, pcbLength);
}

[CRepr]struct IWMDRMReader2 : IWMDRMReader
{
	public new const Guid IID = .(0xbefe7a75, 0x9f1d, 0x4075, 0xb9, 0xd9, 0xa3, 0xc3, 0x7b, 0xda, 0x49, 0xa0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMDRMReader.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEvaluate) SetEvaluateOutputLevelLicenses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DRM_PLAY_OPL* pPlayOPL, uint32* pcbLength, uint32* pdwMinAppComplianceLevel) GetPlayOutputLevels;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DRM_COPY_OPL* pCopyOPL, uint32* pcbLength, uint32* pdwMinAppComplianceLevel) GetCopyOutputLevels;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) TryNextLicense;
	}


	public HRESULT SetEvaluateOutputLevelLicenses(BOOL fEvaluate) mut => VT.[Friend]SetEvaluateOutputLevelLicenses(&this, fEvaluate);

	public HRESULT GetPlayOutputLevels(DRM_PLAY_OPL* pPlayOPL, uint32* pcbLength, uint32* pdwMinAppComplianceLevel) mut => VT.[Friend]GetPlayOutputLevels(&this, pPlayOPL, pcbLength, pdwMinAppComplianceLevel);

	public HRESULT GetCopyOutputLevels(DRM_COPY_OPL* pCopyOPL, uint32* pcbLength, uint32* pdwMinAppComplianceLevel) mut => VT.[Friend]GetCopyOutputLevels(&this, pCopyOPL, pcbLength, pdwMinAppComplianceLevel);

	public HRESULT TryNextLicense() mut => VT.[Friend]TryNextLicense(&this);
}

[CRepr]struct IWMDRMReader3 : IWMDRMReader2
{
	public new const Guid IID = .(0xe08672de, 0xf1e7, 0x4ff4, 0xa0, 0xa3, 0xfc, 0x4b, 0x08, 0xe4, 0xca, 0xf8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMDRMReader2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid** ppGuids, uint32* pcGuids) GetInclusionList;
	}


	public HRESULT GetInclusionList(Guid** ppGuids, uint32* pcGuids) mut => VT.[Friend]GetInclusionList(&this, ppGuids, pcGuids);
}

[CRepr]struct IWMReaderPlaylistBurn : IUnknown
{
	public new const Guid IID = .(0xf28c0300, 0x9baa, 0x4477, 0xa8, 0x46, 0x17, 0x44, 0xd9, 0xcb, 0xf5, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cFiles, PWSTR* ppwszFilenames, IWMStatusCallback* pCallback, void* pvContext) InitPlaylistBurn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cFiles, HRESULT* phrStati) GetInitResults;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrBurnResult) EndPlaylistBurn;
	}


	public HRESULT InitPlaylistBurn(uint32 cFiles, PWSTR* ppwszFilenames, IWMStatusCallback* pCallback, void* pvContext) mut => VT.[Friend]InitPlaylistBurn(&this, cFiles, ppwszFilenames, pCallback, pvContext);

	public HRESULT GetInitResults(uint32 cFiles, HRESULT* phrStati) mut => VT.[Friend]GetInitResults(&this, cFiles, phrStati);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);

	public HRESULT EndPlaylistBurn(HRESULT hrBurnResult) mut => VT.[Friend]EndPlaylistBurn(&this, hrBurnResult);
}

[CRepr]struct IWMReaderNetworkConfig : IUnknown
{
	public new const Guid IID = .(0x96406bec, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pcnsBufferingTime) GetBufferingTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 cnsBufferingTime) SetBufferingTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WM_PORT_NUMBER_RANGE* pRangeArray, uint32* pcRanges) GetUDPPortRanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WM_PORT_NUMBER_RANGE* pRangeArray, uint32 cRanges) SetUDPPortRanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszProtocol, WMT_PROXY_SETTINGS* pProxySetting) GetProxySettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszProtocol, WMT_PROXY_SETTINGS ProxySetting) SetProxySettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszProtocol, char16* pwszHostName, uint32* pcchHostName) GetProxyHostName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszProtocol, PWSTR pwszHostName) SetProxyHostName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszProtocol, uint32* pdwPort) GetProxyPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszProtocol, uint32 dwPort) SetProxyPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszProtocol, char16* pwszExceptionList, uint32* pcchExceptionList) GetProxyExceptionList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszProtocol, PWSTR pwszExceptionList) SetProxyExceptionList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszProtocol, BOOL* pfBypassForLocal) GetProxyBypassForLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszProtocol, BOOL fBypassForLocal) SetProxyBypassForLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfForceRerunDetection) GetForceRerunAutoProxyDetection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fForceRerunDetection) SetForceRerunAutoProxyDetection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfEnableMulticast) GetEnableMulticast;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnableMulticast) SetEnableMulticast;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfEnableHTTP) GetEnableHTTP;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnableHTTP) SetEnableHTTP;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfEnableUDP) GetEnableUDP;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnableUDP) SetEnableUDP;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfEnableTCP) GetEnableTCP;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnableTCP) SetEnableTCP;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResetProtocolRollover;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwConnectionBandwidth) GetConnectionBandwidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwConnectionBandwidth) SetConnectionBandwidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcProtocols) GetNumProtocolsSupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwProtocolNum, char16* pwszProtocolName, uint32* pcchProtocolName) GetSupportedProtocolName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszUrl) AddLoggingUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, char16* pwszUrl, uint32* pcchUrl) GetLoggingUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwUrlCount) GetLoggingUrlCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResetLoggingUrlList;
	}


	public HRESULT GetBufferingTime(uint64* pcnsBufferingTime) mut => VT.[Friend]GetBufferingTime(&this, pcnsBufferingTime);

	public HRESULT SetBufferingTime(uint64 cnsBufferingTime) mut => VT.[Friend]SetBufferingTime(&this, cnsBufferingTime);

	public HRESULT GetUDPPortRanges(WM_PORT_NUMBER_RANGE* pRangeArray, uint32* pcRanges) mut => VT.[Friend]GetUDPPortRanges(&this, pRangeArray, pcRanges);

	public HRESULT SetUDPPortRanges(WM_PORT_NUMBER_RANGE* pRangeArray, uint32 cRanges) mut => VT.[Friend]SetUDPPortRanges(&this, pRangeArray, cRanges);

	public HRESULT GetProxySettings(PWSTR pwszProtocol, WMT_PROXY_SETTINGS* pProxySetting) mut => VT.[Friend]GetProxySettings(&this, pwszProtocol, pProxySetting);

	public HRESULT SetProxySettings(PWSTR pwszProtocol, WMT_PROXY_SETTINGS ProxySetting) mut => VT.[Friend]SetProxySettings(&this, pwszProtocol, ProxySetting);

	public HRESULT GetProxyHostName(PWSTR pwszProtocol, char16* pwszHostName, uint32* pcchHostName) mut => VT.[Friend]GetProxyHostName(&this, pwszProtocol, pwszHostName, pcchHostName);

	public HRESULT SetProxyHostName(PWSTR pwszProtocol, PWSTR pwszHostName) mut => VT.[Friend]SetProxyHostName(&this, pwszProtocol, pwszHostName);

	public HRESULT GetProxyPort(PWSTR pwszProtocol, uint32* pdwPort) mut => VT.[Friend]GetProxyPort(&this, pwszProtocol, pdwPort);

	public HRESULT SetProxyPort(PWSTR pwszProtocol, uint32 dwPort) mut => VT.[Friend]SetProxyPort(&this, pwszProtocol, dwPort);

	public HRESULT GetProxyExceptionList(PWSTR pwszProtocol, char16* pwszExceptionList, uint32* pcchExceptionList) mut => VT.[Friend]GetProxyExceptionList(&this, pwszProtocol, pwszExceptionList, pcchExceptionList);

	public HRESULT SetProxyExceptionList(PWSTR pwszProtocol, PWSTR pwszExceptionList) mut => VT.[Friend]SetProxyExceptionList(&this, pwszProtocol, pwszExceptionList);

	public HRESULT GetProxyBypassForLocal(PWSTR pwszProtocol, BOOL* pfBypassForLocal) mut => VT.[Friend]GetProxyBypassForLocal(&this, pwszProtocol, pfBypassForLocal);

	public HRESULT SetProxyBypassForLocal(PWSTR pwszProtocol, BOOL fBypassForLocal) mut => VT.[Friend]SetProxyBypassForLocal(&this, pwszProtocol, fBypassForLocal);

	public HRESULT GetForceRerunAutoProxyDetection(BOOL* pfForceRerunDetection) mut => VT.[Friend]GetForceRerunAutoProxyDetection(&this, pfForceRerunDetection);

	public HRESULT SetForceRerunAutoProxyDetection(BOOL fForceRerunDetection) mut => VT.[Friend]SetForceRerunAutoProxyDetection(&this, fForceRerunDetection);

	public HRESULT GetEnableMulticast(BOOL* pfEnableMulticast) mut => VT.[Friend]GetEnableMulticast(&this, pfEnableMulticast);

	public HRESULT SetEnableMulticast(BOOL fEnableMulticast) mut => VT.[Friend]SetEnableMulticast(&this, fEnableMulticast);

	public HRESULT GetEnableHTTP(BOOL* pfEnableHTTP) mut => VT.[Friend]GetEnableHTTP(&this, pfEnableHTTP);

	public HRESULT SetEnableHTTP(BOOL fEnableHTTP) mut => VT.[Friend]SetEnableHTTP(&this, fEnableHTTP);

	public HRESULT GetEnableUDP(BOOL* pfEnableUDP) mut => VT.[Friend]GetEnableUDP(&this, pfEnableUDP);

	public HRESULT SetEnableUDP(BOOL fEnableUDP) mut => VT.[Friend]SetEnableUDP(&this, fEnableUDP);

	public HRESULT GetEnableTCP(BOOL* pfEnableTCP) mut => VT.[Friend]GetEnableTCP(&this, pfEnableTCP);

	public HRESULT SetEnableTCP(BOOL fEnableTCP) mut => VT.[Friend]SetEnableTCP(&this, fEnableTCP);

	public HRESULT ResetProtocolRollover() mut => VT.[Friend]ResetProtocolRollover(&this);

	public HRESULT GetConnectionBandwidth(uint32* pdwConnectionBandwidth) mut => VT.[Friend]GetConnectionBandwidth(&this, pdwConnectionBandwidth);

	public HRESULT SetConnectionBandwidth(uint32 dwConnectionBandwidth) mut => VT.[Friend]SetConnectionBandwidth(&this, dwConnectionBandwidth);

	public HRESULT GetNumProtocolsSupported(uint32* pcProtocols) mut => VT.[Friend]GetNumProtocolsSupported(&this, pcProtocols);

	public HRESULT GetSupportedProtocolName(uint32 dwProtocolNum, char16* pwszProtocolName, uint32* pcchProtocolName) mut => VT.[Friend]GetSupportedProtocolName(&this, dwProtocolNum, pwszProtocolName, pcchProtocolName);

	public HRESULT AddLoggingUrl(PWSTR pwszUrl) mut => VT.[Friend]AddLoggingUrl(&this, pwszUrl);

	public HRESULT GetLoggingUrl(uint32 dwIndex, char16* pwszUrl, uint32* pcchUrl) mut => VT.[Friend]GetLoggingUrl(&this, dwIndex, pwszUrl, pcchUrl);

	public HRESULT GetLoggingUrlCount(uint32* pdwUrlCount) mut => VT.[Friend]GetLoggingUrlCount(&this, pdwUrlCount);

	public HRESULT ResetLoggingUrlList() mut => VT.[Friend]ResetLoggingUrlList(&this);
}

[CRepr]struct IWMReaderNetworkConfig2 : IWMReaderNetworkConfig
{
	public new const Guid IID = .(0xd979a853, 0x042b, 0x4050, 0x83, 0x87, 0xc9, 0x39, 0xdb, 0x22, 0x01, 0x3f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMReaderNetworkConfig.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfEnableContentCaching) GetEnableContentCaching;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnableContentCaching) SetEnableContentCaching;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfEnableFastCache) GetEnableFastCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnableFastCache) SetEnableFastCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pcnsAccelDuration) GetAcceleratedStreamingDuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 cnsAccelDuration) SetAcceleratedStreamingDuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwAutoReconnectLimit) GetAutoReconnectLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAutoReconnectLimit) SetAutoReconnectLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfEnableResends) GetEnableResends;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnableResends) SetEnableResends;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfEnableThinning) GetEnableThinning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnableThinning) SetEnableThinning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMaxNetPacketSize) GetMaxNetPacketSize;
	}


	public HRESULT GetEnableContentCaching(BOOL* pfEnableContentCaching) mut => VT.[Friend]GetEnableContentCaching(&this, pfEnableContentCaching);

	public HRESULT SetEnableContentCaching(BOOL fEnableContentCaching) mut => VT.[Friend]SetEnableContentCaching(&this, fEnableContentCaching);

	public HRESULT GetEnableFastCache(BOOL* pfEnableFastCache) mut => VT.[Friend]GetEnableFastCache(&this, pfEnableFastCache);

	public HRESULT SetEnableFastCache(BOOL fEnableFastCache) mut => VT.[Friend]SetEnableFastCache(&this, fEnableFastCache);

	public HRESULT GetAcceleratedStreamingDuration(uint64* pcnsAccelDuration) mut => VT.[Friend]GetAcceleratedStreamingDuration(&this, pcnsAccelDuration);

	public HRESULT SetAcceleratedStreamingDuration(uint64 cnsAccelDuration) mut => VT.[Friend]SetAcceleratedStreamingDuration(&this, cnsAccelDuration);

	public HRESULT GetAutoReconnectLimit(uint32* pdwAutoReconnectLimit) mut => VT.[Friend]GetAutoReconnectLimit(&this, pdwAutoReconnectLimit);

	public HRESULT SetAutoReconnectLimit(uint32 dwAutoReconnectLimit) mut => VT.[Friend]SetAutoReconnectLimit(&this, dwAutoReconnectLimit);

	public HRESULT GetEnableResends(BOOL* pfEnableResends) mut => VT.[Friend]GetEnableResends(&this, pfEnableResends);

	public HRESULT SetEnableResends(BOOL fEnableResends) mut => VT.[Friend]SetEnableResends(&this, fEnableResends);

	public HRESULT GetEnableThinning(BOOL* pfEnableThinning) mut => VT.[Friend]GetEnableThinning(&this, pfEnableThinning);

	public HRESULT SetEnableThinning(BOOL fEnableThinning) mut => VT.[Friend]SetEnableThinning(&this, fEnableThinning);

	public HRESULT GetMaxNetPacketSize(uint32* pdwMaxNetPacketSize) mut => VT.[Friend]GetMaxNetPacketSize(&this, pdwMaxNetPacketSize);
}

[CRepr]struct IWMReaderStreamClock : IUnknown
{
	public new const Guid IID = .(0x96406bed, 0x2b2b, 0x11d3, 0xb3, 0x6b, 0x00, 0xc0, 0x4f, 0x61, 0x08, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pcnsNow) GetTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 cnsWhen, void* pvParam, uint32* pdwTimerId) SetTimer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwTimerId) KillTimer;
	}


	public HRESULT GetTime(uint64* pcnsNow) mut => VT.[Friend]GetTime(&this, pcnsNow);

	public HRESULT SetTimer(uint64 cnsWhen, void* pvParam, uint32* pdwTimerId) mut => VT.[Friend]SetTimer(&this, cnsWhen, pvParam, pdwTimerId);

	public HRESULT KillTimer(uint32 dwTimerId) mut => VT.[Friend]KillTimer(&this, dwTimerId);
}

[CRepr]struct IWMIndexer : IUnknown
{
	public new const Guid IID = .(0x6d7cdc71, 0x9888, 0x11d3, 0x8e, 0xdc, 0x00, 0xc0, 0x4f, 0x61, 0x09, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszURL, IWMStatusCallback* pCallback, void* pvContext) StartIndexing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
	}


	public HRESULT StartIndexing(PWSTR pwszURL, IWMStatusCallback* pCallback, void* pvContext) mut => VT.[Friend]StartIndexing(&this, pwszURL, pCallback, pvContext);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);
}

[CRepr]struct IWMIndexer2 : IWMIndexer
{
	public new const Guid IID = .(0xb70f1e42, 0x6255, 0x4df0, 0xa6, 0xb9, 0x02, 0xb2, 0x12, 0xd9, 0xe2, 0xbb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMIndexer.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, WMT_INDEXER_TYPE nIndexerType, void* pvInterval, void* pvIndexType) Configure;
	}


	public HRESULT Configure(uint16 wStreamNum, WMT_INDEXER_TYPE nIndexerType, void* pvInterval, void* pvIndexType) mut => VT.[Friend]Configure(&this, wStreamNum, nIndexerType, pvInterval, pvIndexType);
}

[CRepr]struct IWMLicenseBackup : IUnknown
{
	public new const Guid IID = .(0x05e5ac9f, 0x3fb6, 0x4508, 0xbb, 0x43, 0xa4, 0x06, 0x7b, 0xa1, 0xeb, 0xe8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IWMStatusCallback* pCallback) BackupLicenses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelLicenseBackup;
	}


	public HRESULT BackupLicenses(uint32 dwFlags, IWMStatusCallback* pCallback) mut => VT.[Friend]BackupLicenses(&this, dwFlags, pCallback);

	public HRESULT CancelLicenseBackup() mut => VT.[Friend]CancelLicenseBackup(&this);
}

[CRepr]struct IWMLicenseRestore : IUnknown
{
	public new const Guid IID = .(0xc70b6334, 0xa22e, 0x4efb, 0xa2, 0x45, 0x15, 0xe6, 0x5a, 0x00, 0x4a, 0x13);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IWMStatusCallback* pCallback) RestoreLicenses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelLicenseRestore;
	}


	public HRESULT RestoreLicenses(uint32 dwFlags, IWMStatusCallback* pCallback) mut => VT.[Friend]RestoreLicenses(&this, dwFlags, pCallback);

	public HRESULT CancelLicenseRestore() mut => VT.[Friend]CancelLicenseRestore(&this);
}

[CRepr]struct IWMBackupRestoreProps : IUnknown
{
	public new const Guid IID = .(0x3c8e0da6, 0x996f, 0x4ff3, 0xa1, 0xaf, 0x48, 0x38, 0xf9, 0x37, 0x7e, 0x2e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pcProps) GetPropCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wIndex, char16* pwszName, uint16* pcchNameLen, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint16* pcbLength) GetPropByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint16* pcbLength) GetPropByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, WMT_ATTR_DATATYPE Type, uint8* pValue, uint16 cbLength) SetProp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pcwszName) RemoveProp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveAllProps;
	}


	public HRESULT GetPropCount(uint16* pcProps) mut => VT.[Friend]GetPropCount(&this, pcProps);

	public HRESULT GetPropByIndex(uint16 wIndex, char16* pwszName, uint16* pcchNameLen, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint16* pcbLength) mut => VT.[Friend]GetPropByIndex(&this, wIndex, pwszName, pcchNameLen, pType, pValue, pcbLength);

	public HRESULT GetPropByName(PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint16* pcbLength) mut => VT.[Friend]GetPropByName(&this, pszName, pType, pValue, pcbLength);

	public HRESULT SetProp(PWSTR pszName, WMT_ATTR_DATATYPE Type, uint8* pValue, uint16 cbLength) mut => VT.[Friend]SetProp(&this, pszName, Type, pValue, cbLength);

	public HRESULT RemoveProp(PWSTR pcwszName) mut => VT.[Friend]RemoveProp(&this, pcwszName);

	public HRESULT RemoveAllProps() mut => VT.[Friend]RemoveAllProps(&this);
}

[CRepr]struct IWMCodecInfo : IUnknown
{
	public new const Guid IID = .(0xa970f41e, 0x34de, 0x4a98, 0xb3, 0xba, 0xe4, 0xb3, 0xca, 0x75, 0x28, 0xf0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidType, uint32* pcCodecs) GetCodecInfoCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidType, uint32 dwCodecIndex, uint32* pcFormat) GetCodecFormatCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidType, uint32 dwCodecIndex, uint32 dwFormatIndex, IWMStreamConfig** ppIStreamConfig) GetCodecFormat;
	}


	public HRESULT GetCodecInfoCount(in Guid guidType, uint32* pcCodecs) mut => VT.[Friend]GetCodecInfoCount(&this, guidType, pcCodecs);

	public HRESULT GetCodecFormatCount(in Guid guidType, uint32 dwCodecIndex, uint32* pcFormat) mut => VT.[Friend]GetCodecFormatCount(&this, guidType, dwCodecIndex, pcFormat);

	public HRESULT GetCodecFormat(in Guid guidType, uint32 dwCodecIndex, uint32 dwFormatIndex, IWMStreamConfig** ppIStreamConfig) mut => VT.[Friend]GetCodecFormat(&this, guidType, dwCodecIndex, dwFormatIndex, ppIStreamConfig);
}

[CRepr]struct IWMCodecInfo2 : IWMCodecInfo
{
	public new const Guid IID = .(0xaa65e273, 0xb686, 0x4056, 0x91, 0xec, 0xdd, 0x76, 0x8d, 0x4d, 0xf7, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMCodecInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidType, uint32 dwCodecIndex, char16* wszName, uint32* pcchName) GetCodecName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidType, uint32 dwCodecIndex, uint32 dwFormatIndex, IWMStreamConfig** ppIStreamConfig, char16* wszDesc, uint32* pcchDesc) GetCodecFormatDesc;
	}


	public HRESULT GetCodecName(in Guid guidType, uint32 dwCodecIndex, char16* wszName, uint32* pcchName) mut => VT.[Friend]GetCodecName(&this, guidType, dwCodecIndex, wszName, pcchName);

	public HRESULT GetCodecFormatDesc(in Guid guidType, uint32 dwCodecIndex, uint32 dwFormatIndex, IWMStreamConfig** ppIStreamConfig, char16* wszDesc, uint32* pcchDesc) mut => VT.[Friend]GetCodecFormatDesc(&this, guidType, dwCodecIndex, dwFormatIndex, ppIStreamConfig, wszDesc, pcchDesc);
}

[CRepr]struct IWMCodecInfo3 : IWMCodecInfo2
{
	public new const Guid IID = .(0x7e51f487, 0x4d93, 0x4f98, 0x8a, 0xb4, 0x27, 0xd0, 0x56, 0x5a, 0xdc, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMCodecInfo2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidType, uint32 dwCodecIndex, uint32 dwFormatIndex, PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint32* pdwSize) GetCodecFormatProp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidType, uint32 dwCodecIndex, PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint32* pdwSize) GetCodecProp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidType, uint32 dwCodecIndex, PWSTR pszName, WMT_ATTR_DATATYPE Type, uint8* pValue, uint32 dwSize) SetCodecEnumerationSetting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidType, uint32 dwCodecIndex, PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint32* pdwSize) GetCodecEnumerationSetting;
	}


	public HRESULT GetCodecFormatProp(in Guid guidType, uint32 dwCodecIndex, uint32 dwFormatIndex, PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint32* pdwSize) mut => VT.[Friend]GetCodecFormatProp(&this, guidType, dwCodecIndex, dwFormatIndex, pszName, pType, pValue, pdwSize);

	public HRESULT GetCodecProp(in Guid guidType, uint32 dwCodecIndex, PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint32* pdwSize) mut => VT.[Friend]GetCodecProp(&this, guidType, dwCodecIndex, pszName, pType, pValue, pdwSize);

	public HRESULT SetCodecEnumerationSetting(in Guid guidType, uint32 dwCodecIndex, PWSTR pszName, WMT_ATTR_DATATYPE Type, uint8* pValue, uint32 dwSize) mut => VT.[Friend]SetCodecEnumerationSetting(&this, guidType, dwCodecIndex, pszName, Type, pValue, dwSize);

	public HRESULT GetCodecEnumerationSetting(in Guid guidType, uint32 dwCodecIndex, PWSTR pszName, WMT_ATTR_DATATYPE* pType, uint8* pValue, uint32* pdwSize) mut => VT.[Friend]GetCodecEnumerationSetting(&this, guidType, dwCodecIndex, pszName, pType, pValue, pdwSize);
}

[CRepr]struct IWMLanguageList : IUnknown
{
	public new const Guid IID = .(0xdf683f00, 0x2d49, 0x4d8e, 0x92, 0xb7, 0xfb, 0x19, 0xf6, 0xa0, 0xdc, 0x57);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwCount) GetLanguageCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wIndex, char16* pwszLanguageString, uint16* pcchLanguageStringLength) GetLanguageDetails;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszLanguageString, uint16* pwIndex) AddLanguageByRFC1766String;
	}


	public HRESULT GetLanguageCount(uint16* pwCount) mut => VT.[Friend]GetLanguageCount(&this, pwCount);

	public HRESULT GetLanguageDetails(uint16 wIndex, char16* pwszLanguageString, uint16* pcchLanguageStringLength) mut => VT.[Friend]GetLanguageDetails(&this, wIndex, pwszLanguageString, pcchLanguageStringLength);

	public HRESULT AddLanguageByRFC1766String(PWSTR pwszLanguageString, uint16* pwIndex) mut => VT.[Friend]AddLanguageByRFC1766String(&this, pwszLanguageString, pwIndex);
}

[CRepr]struct IWMWriterPushSink : IWMWriterSink
{
	public new const Guid IID = .(0xdc10e6a5, 0x072c, 0x467d, 0xbf, 0x57, 0x63, 0x30, 0xa9, 0xdd, 0xe1, 0x2a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMWriterSink.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszURL, PWSTR pwszTemplateURL, BOOL fAutoDestroy) Connect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Disconnect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndSession;
	}


	public HRESULT Connect(PWSTR pwszURL, PWSTR pwszTemplateURL, BOOL fAutoDestroy) mut => VT.[Friend]Connect(&this, pwszURL, pwszTemplateURL, fAutoDestroy);

	public HRESULT Disconnect() mut => VT.[Friend]Disconnect(&this);

	public HRESULT EndSession() mut => VT.[Friend]EndSession(&this);
}

[CRepr]struct IWMDeviceRegistration : IUnknown
{
	public new const Guid IID = .(0xf6211f03, 0x8d21, 0x4e94, 0x93, 0xe6, 0x85, 0x10, 0x80, 0x5f, 0x2d, 0x99);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwRegisterType, uint8* pbCertificate, uint32 cbCertificate, DRM_VAL16 SerialNumber, IWMRegisteredDevice** ppDevice) RegisterDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwRegisterType, uint8* pbCertificate, uint32 cbCertificate, DRM_VAL16 SerialNumber) UnregisterDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwRegisterType, uint32* pcRegisteredDevices) GetRegistrationStats;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwRegisterType, IWMRegisteredDevice** ppDevice) GetFirstRegisteredDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMRegisteredDevice** ppDevice) GetNextRegisteredDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwRegisterType, uint8* pbCertificate, uint32 cbCertificate, DRM_VAL16 SerialNumber, IWMRegisteredDevice** ppDevice) GetRegisteredDeviceByID;
	}


	public HRESULT RegisterDevice(uint32 dwRegisterType, uint8* pbCertificate, uint32 cbCertificate, DRM_VAL16 SerialNumber, IWMRegisteredDevice** ppDevice) mut => VT.[Friend]RegisterDevice(&this, dwRegisterType, pbCertificate, cbCertificate, SerialNumber, ppDevice);

	public HRESULT UnregisterDevice(uint32 dwRegisterType, uint8* pbCertificate, uint32 cbCertificate, DRM_VAL16 SerialNumber) mut => VT.[Friend]UnregisterDevice(&this, dwRegisterType, pbCertificate, cbCertificate, SerialNumber);

	public HRESULT GetRegistrationStats(uint32 dwRegisterType, uint32* pcRegisteredDevices) mut => VT.[Friend]GetRegistrationStats(&this, dwRegisterType, pcRegisteredDevices);

	public HRESULT GetFirstRegisteredDevice(uint32 dwRegisterType, IWMRegisteredDevice** ppDevice) mut => VT.[Friend]GetFirstRegisteredDevice(&this, dwRegisterType, ppDevice);

	public HRESULT GetNextRegisteredDevice(IWMRegisteredDevice** ppDevice) mut => VT.[Friend]GetNextRegisteredDevice(&this, ppDevice);

	public HRESULT GetRegisteredDeviceByID(uint32 dwRegisterType, uint8* pbCertificate, uint32 cbCertificate, DRM_VAL16 SerialNumber, IWMRegisteredDevice** ppDevice) mut => VT.[Friend]GetRegisteredDeviceByID(&this, dwRegisterType, pbCertificate, cbCertificate, SerialNumber, ppDevice);
}

[CRepr]struct IWMRegisteredDevice : IUnknown
{
	public new const Guid IID = .(0xa4503bec, 0x5508, 0x4148, 0x97, 0xac, 0xbf, 0xa7, 0x57, 0x60, 0xa7, 0x0d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DRM_VAL16* pSerialNumber) GetDeviceSerialNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INSSBuffer** ppCertificate) GetDeviceCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwType) GetDeviceType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcAttributes) GetAttributeCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, BSTR* pbstrName, BSTR* pbstrValue) GetAttributeByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BSTR* pbstrValue) GetAttributeByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BSTR bstrValue) SetAttributeByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fApprove) Approve;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfValid) IsValid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfApproved) IsApproved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfCompliant) IsWmdrmCompliant;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfOpened) IsOpened;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
	}


	public HRESULT GetDeviceSerialNumber(DRM_VAL16* pSerialNumber) mut => VT.[Friend]GetDeviceSerialNumber(&this, pSerialNumber);

	public HRESULT GetDeviceCertificate(INSSBuffer** ppCertificate) mut => VT.[Friend]GetDeviceCertificate(&this, ppCertificate);

	public HRESULT GetDeviceType(uint32* pdwType) mut => VT.[Friend]GetDeviceType(&this, pdwType);

	public HRESULT GetAttributeCount(uint32* pcAttributes) mut => VT.[Friend]GetAttributeCount(&this, pcAttributes);

	public HRESULT GetAttributeByIndex(uint32 dwIndex, BSTR* pbstrName, BSTR* pbstrValue) mut => VT.[Friend]GetAttributeByIndex(&this, dwIndex, pbstrName, pbstrValue);

	public HRESULT GetAttributeByName(BSTR bstrName, BSTR* pbstrValue) mut => VT.[Friend]GetAttributeByName(&this, bstrName, pbstrValue);

	public HRESULT SetAttributeByName(BSTR bstrName, BSTR bstrValue) mut => VT.[Friend]SetAttributeByName(&this, bstrName, bstrValue);

	public HRESULT Approve(BOOL fApprove) mut => VT.[Friend]Approve(&this, fApprove);

	public HRESULT IsValid(BOOL* pfValid) mut => VT.[Friend]IsValid(&this, pfValid);

	public HRESULT IsApproved(BOOL* pfApproved) mut => VT.[Friend]IsApproved(&this, pfApproved);

	public HRESULT IsWmdrmCompliant(BOOL* pfCompliant) mut => VT.[Friend]IsWmdrmCompliant(&this, pfCompliant);

	public HRESULT IsOpened(BOOL* pfOpened) mut => VT.[Friend]IsOpened(&this, pfOpened);

	public HRESULT Open() mut => VT.[Friend]Open(&this);

	public HRESULT Close() mut => VT.[Friend]Close(&this);
}

[CRepr]struct IWMProximityDetection : IUnknown
{
	public new const Guid IID = .(0x6a9fd8ee, 0xb651, 0x4bf0, 0xb8, 0x49, 0x7d, 0x4e, 0xce, 0x79, 0xa2, 0xb1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbRegistrationMsg, uint32 cbRegistrationMsg, uint8* pbLocalAddress, uint32 cbLocalAddress, uint32 dwExtraPortsAllowed, INSSBuffer** ppRegistrationResponseMsg, IWMStatusCallback* pCallback, void* pvContext) StartDetection;
	}


	public HRESULT StartDetection(uint8* pbRegistrationMsg, uint32 cbRegistrationMsg, uint8* pbLocalAddress, uint32 cbLocalAddress, uint32 dwExtraPortsAllowed, INSSBuffer** ppRegistrationResponseMsg, IWMStatusCallback* pCallback, void* pvContext) mut => VT.[Friend]StartDetection(&this, pbRegistrationMsg, cbRegistrationMsg, pbLocalAddress, cbLocalAddress, dwExtraPortsAllowed, ppRegistrationResponseMsg, pCallback, pvContext);
}

[CRepr]struct IWMDRMMessageParser : IUnknown
{
	public new const Guid IID = .(0xa73a0072, 0x25a0, 0x4c99, 0xb4, 0xa5, 0xed, 0xe8, 0x10, 0x1a, 0x6c, 0x39);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbRegistrationReqMsg, uint32 cbRegistrationReqMsg, INSSBuffer** ppDeviceCert, DRM_VAL16* pDeviceSerialNumber) ParseRegistrationReqMsg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbLicenseRequestMsg, uint32 cbLicenseRequestMsg, INSSBuffer** ppDeviceCert, DRM_VAL16* pDeviceSerialNumber, BSTR* pbstrAction) ParseLicenseRequestMsg;
	}


	public HRESULT ParseRegistrationReqMsg(uint8* pbRegistrationReqMsg, uint32 cbRegistrationReqMsg, INSSBuffer** ppDeviceCert, DRM_VAL16* pDeviceSerialNumber) mut => VT.[Friend]ParseRegistrationReqMsg(&this, pbRegistrationReqMsg, cbRegistrationReqMsg, ppDeviceCert, pDeviceSerialNumber);

	public HRESULT ParseLicenseRequestMsg(uint8* pbLicenseRequestMsg, uint32 cbLicenseRequestMsg, INSSBuffer** ppDeviceCert, DRM_VAL16* pDeviceSerialNumber, BSTR* pbstrAction) mut => VT.[Friend]ParseLicenseRequestMsg(&this, pbLicenseRequestMsg, cbLicenseRequestMsg, ppDeviceCert, pDeviceSerialNumber, pbstrAction);
}

[CRepr]struct IWMDRMTranscryptor : IUnknown
{
	public new const Guid IID = .(0x69059850, 0x6e6f, 0x4bb2, 0x80, 0x6f, 0x71, 0x86, 0x3d, 0xdf, 0xc4, 0x71);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFileName, uint8* pbLicenseRequestMsg, uint32 cbLicenseRequestMsg, INSSBuffer** ppLicenseResponseMsg, IWMStatusCallback* pCallback, void* pvContext) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 hnsTime) Seek;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbData, uint32* pcbData) Read;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
	}


	public HRESULT Initialize(BSTR bstrFileName, uint8* pbLicenseRequestMsg, uint32 cbLicenseRequestMsg, INSSBuffer** ppLicenseResponseMsg, IWMStatusCallback* pCallback, void* pvContext) mut => VT.[Friend]Initialize(&this, bstrFileName, pbLicenseRequestMsg, cbLicenseRequestMsg, ppLicenseResponseMsg, pCallback, pvContext);

	public HRESULT Seek(uint64 hnsTime) mut => VT.[Friend]Seek(&this, hnsTime);

	public HRESULT Read(uint8* pbData, uint32* pcbData) mut => VT.[Friend]Read(&this, pbData, pcbData);

	public HRESULT Close() mut => VT.[Friend]Close(&this);
}

[CRepr]struct IWMDRMTranscryptor2 : IWMDRMTranscryptor
{
	public new const Guid IID = .(0xe0da439f, 0xd331, 0x496a, 0xbe, 0xce, 0x18, 0xe5, 0xba, 0xc5, 0xdd, 0x23);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMDRMTranscryptor.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 cnsStartTime, uint64 cnsDuration, float flRate, BOOL fIncludeFileHeader) SeekEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnable) ZeroAdjustTimestamps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pcnsTime) GetSeekStartTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pcnsDuration) GetDuration;
	}


	public HRESULT SeekEx(uint64 cnsStartTime, uint64 cnsDuration, float flRate, BOOL fIncludeFileHeader) mut => VT.[Friend]SeekEx(&this, cnsStartTime, cnsDuration, flRate, fIncludeFileHeader);

	public HRESULT ZeroAdjustTimestamps(BOOL fEnable) mut => VT.[Friend]ZeroAdjustTimestamps(&this, fEnable);

	public HRESULT GetSeekStartTime(uint64* pcnsTime) mut => VT.[Friend]GetSeekStartTime(&this, pcnsTime);

	public HRESULT GetDuration(uint64* pcnsDuration) mut => VT.[Friend]GetDuration(&this, pcnsDuration);
}

[CRepr]struct IWMDRMTranscryptionManager : IUnknown
{
	public new const Guid IID = .(0xb1a887b2, 0xa4f0, 0x407a, 0xb0, 0x2e, 0xef, 0xbd, 0x23, 0xbb, 0xec, 0xdf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMDRMTranscryptor** ppTranscryptor) CreateTranscryptor;
	}


	public HRESULT CreateTranscryptor(IWMDRMTranscryptor** ppTranscryptor) mut => VT.[Friend]CreateTranscryptor(&this, ppTranscryptor);
}

[CRepr]struct IWMWatermarkInfo : IUnknown
{
	public new const Guid IID = .(0x6f497062, 0xf2e2, 0x4624, 0x8e, 0xa7, 0x9d, 0xd4, 0x0d, 0x81, 0xfc, 0x8d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMT_WATERMARK_ENTRY_TYPE wmetType, uint32* pdwCount) GetWatermarkEntryCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMT_WATERMARK_ENTRY_TYPE wmetType, uint32 dwEntryNum, WMT_WATERMARK_ENTRY* pEntry) GetWatermarkEntry;
	}


	public HRESULT GetWatermarkEntryCount(WMT_WATERMARK_ENTRY_TYPE wmetType, uint32* pdwCount) mut => VT.[Friend]GetWatermarkEntryCount(&this, wmetType, pdwCount);

	public HRESULT GetWatermarkEntry(WMT_WATERMARK_ENTRY_TYPE wmetType, uint32 dwEntryNum, WMT_WATERMARK_ENTRY* pEntry) mut => VT.[Friend]GetWatermarkEntry(&this, wmetType, dwEntryNum, pEntry);
}

[CRepr]struct IWMReaderAccelerator : IUnknown
{
	public new const Guid IID = .(0xbddc4d08, 0x944d, 0x4d52, 0xa6, 0x12, 0x46, 0xc3, 0xfd, 0xa0, 0x7d, 0xd4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, in Guid riid, void** ppvCodecInterface) GetCodecInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputNum, WM_MEDIA_TYPE* pSubtype) Notify;
	}


	public HRESULT GetCodecInterface(uint32 dwOutputNum, in Guid riid, void** ppvCodecInterface) mut => VT.[Friend]GetCodecInterface(&this, dwOutputNum, riid, ppvCodecInterface);

	public HRESULT Notify(uint32 dwOutputNum, WM_MEDIA_TYPE* pSubtype) mut => VT.[Friend]Notify(&this, dwOutputNum, pSubtype);
}

[CRepr]struct IWMReaderTimecode : IUnknown
{
	public new const Guid IID = .(0xf369e2f0, 0xe081, 0x4fe6, 0x84, 0x50, 0xb8, 0x10, 0xb2, 0xf4, 0x10, 0xd1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, uint16* pwRangeCount) GetTimecodeRangeCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wStreamNum, uint16 wRangeNum, uint32* pStartTimecode, uint32* pEndTimecode) GetTimecodeRangeBounds;
	}


	public HRESULT GetTimecodeRangeCount(uint16 wStreamNum, uint16* pwRangeCount) mut => VT.[Friend]GetTimecodeRangeCount(&this, wStreamNum, pwRangeCount);

	public HRESULT GetTimecodeRangeBounds(uint16 wStreamNum, uint16 wRangeNum, uint32* pStartTimecode, uint32* pEndTimecode) mut => VT.[Friend]GetTimecodeRangeBounds(&this, wStreamNum, wRangeNum, pStartTimecode, pEndTimecode);
}

[CRepr]struct IWMAddressAccess : IUnknown
{
	public new const Guid IID = .(0xbb3c6389, 0x1633, 0x4e92, 0xaf, 0x14, 0x9f, 0x31, 0x73, 0xba, 0x39, 0xd0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WM_AETYPE aeType, uint32* pcEntries) GetAccessEntryCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WM_AETYPE aeType, uint32 dwEntryNum, WM_ADDRESS_ACCESSENTRY* pAddrAccessEntry) GetAccessEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WM_AETYPE aeType, WM_ADDRESS_ACCESSENTRY* pAddrAccessEntry) AddAccessEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WM_AETYPE aeType, uint32 dwEntryNum) RemoveAccessEntry;
	}


	public HRESULT GetAccessEntryCount(WM_AETYPE aeType, uint32* pcEntries) mut => VT.[Friend]GetAccessEntryCount(&this, aeType, pcEntries);

	public HRESULT GetAccessEntry(WM_AETYPE aeType, uint32 dwEntryNum, WM_ADDRESS_ACCESSENTRY* pAddrAccessEntry) mut => VT.[Friend]GetAccessEntry(&this, aeType, dwEntryNum, pAddrAccessEntry);

	public HRESULT AddAccessEntry(WM_AETYPE aeType, WM_ADDRESS_ACCESSENTRY* pAddrAccessEntry) mut => VT.[Friend]AddAccessEntry(&this, aeType, pAddrAccessEntry);

	public HRESULT RemoveAccessEntry(WM_AETYPE aeType, uint32 dwEntryNum) mut => VT.[Friend]RemoveAccessEntry(&this, aeType, dwEntryNum);
}

[CRepr]struct IWMAddressAccess2 : IWMAddressAccess
{
	public new const Guid IID = .(0x65a83fc2, 0x3e98, 0x4d4d, 0x81, 0xb5, 0x2a, 0x74, 0x28, 0x86, 0xb3, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMAddressAccess.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WM_AETYPE aeType, uint32 dwEntryNum, BSTR* pbstrAddress, BSTR* pbstrMask) GetAccessEntryEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WM_AETYPE aeType, BSTR bstrAddress, BSTR bstrMask) AddAccessEntryEx;
	}


	public HRESULT GetAccessEntryEx(WM_AETYPE aeType, uint32 dwEntryNum, BSTR* pbstrAddress, BSTR* pbstrMask) mut => VT.[Friend]GetAccessEntryEx(&this, aeType, dwEntryNum, pbstrAddress, pbstrMask);

	public HRESULT AddAccessEntryEx(WM_AETYPE aeType, BSTR bstrAddress, BSTR bstrMask) mut => VT.[Friend]AddAccessEntryEx(&this, aeType, bstrAddress, bstrMask);
}

[CRepr]struct IWMImageInfo : IUnknown
{
	public new const Guid IID = .(0x9f0aa3b6, 0x7267, 0x4d89, 0x88, 0xf2, 0xba, 0x91, 0x5a, 0xa5, 0xc4, 0xc6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcImages) GetImageCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 wIndex, uint16* pcchMIMEType, char16* pwszMIMEType, uint16* pcchDescription, char16* pwszDescription, uint16* pImageType, uint32* pcbImageData, uint8* pbImageData) GetImage;
	}


	public HRESULT GetImageCount(uint32* pcImages) mut => VT.[Friend]GetImageCount(&this, pcImages);

	public HRESULT GetImage(uint32 wIndex, uint16* pcchMIMEType, char16* pwszMIMEType, uint16* pcchDescription, char16* pwszDescription, uint16* pImageType, uint32* pcbImageData, uint8* pbImageData) mut => VT.[Friend]GetImage(&this, wIndex, pcchMIMEType, pwszMIMEType, pcchDescription, pwszDescription, pImageType, pcbImageData, pbImageData);
}

[CRepr]struct IWMLicenseRevocationAgent : IUnknown
{
	public new const Guid IID = .(0x6967f2c9, 0x4e26, 0x4b57, 0x88, 0x94, 0x79, 0x98, 0x80, 0xf7, 0xac, 0x7b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pMachineID, uint32 dwMachineIDLength, uint8* pChallenge, uint32 dwChallengeLength, uint8* pChallengeOutput, uint32* pdwChallengeOutputLength) GetLRBChallenge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pSignedLRB, uint32 dwSignedLRBLength, uint8* pSignedACK, uint32* pdwSignedACKLength) ProcessLRB;
	}


	public HRESULT GetLRBChallenge(uint8* pMachineID, uint32 dwMachineIDLength, uint8* pChallenge, uint32 dwChallengeLength, uint8* pChallengeOutput, uint32* pdwChallengeOutputLength) mut => VT.[Friend]GetLRBChallenge(&this, pMachineID, dwMachineIDLength, pChallenge, dwChallengeLength, pChallengeOutput, pdwChallengeOutputLength);

	public HRESULT ProcessLRB(uint8* pSignedLRB, uint32 dwSignedLRBLength, uint8* pSignedACK, uint32* pdwSignedACKLength) mut => VT.[Friend]ProcessLRB(&this, pSignedLRB, dwSignedLRBLength, pSignedACK, pdwSignedACKLength);
}

[CRepr]struct IWMAuthorizer : IUnknown
{
	public new const Guid IID = .(0xd9b67d36, 0xa9ad, 0x4eb4, 0xba, 0xef, 0xdb, 0x28, 0x4e, 0xf5, 0x50, 0x4c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcCerts) GetCertCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, uint8** ppbCertData) GetCert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCertIndex, uint8* pbSharedData, uint8* pbCert, uint8** ppbSharedData) GetSharedData;
	}


	public HRESULT GetCertCount(uint32* pcCerts) mut => VT.[Friend]GetCertCount(&this, pcCerts);

	public HRESULT GetCert(uint32 dwIndex, uint8** ppbCertData) mut => VT.[Friend]GetCert(&this, dwIndex, ppbCertData);

	public HRESULT GetSharedData(uint32 dwCertIndex, uint8* pbSharedData, uint8* pbCert, uint8** ppbSharedData) mut => VT.[Friend]GetSharedData(&this, dwCertIndex, pbSharedData, pbCert, ppbSharedData);
}

[CRepr]struct IWMSecureChannel : IWMAuthorizer
{
	public new const Guid IID = .(0x2720598a, 0xd0f2, 0x4189, 0xbd, 0x10, 0x91, 0xc4, 0x6e, 0xf0, 0x93, 0x6f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMAuthorizer.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMAuthorizer* pCert) WMSC_AddCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbCertSig, uint32 cbCertSig) WMSC_AddSignature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMSecureChannel* pOtherSide) WMSC_Connect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfIsConnected) WMSC_IsConnected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) WMSC_Disconnect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** ppbCertificate, uint32* pdwSignature) WMSC_GetValidCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbData, uint32 cbData) WMSC_Encrypt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbData, uint32 cbData) WMSC_Decrypt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) WMSC_Lock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) WMSC_Unlock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCertIndex, uint8* pbSharedData) WMSC_SetSharedData;
	}


	public HRESULT WMSC_AddCertificate(IWMAuthorizer* pCert) mut => VT.[Friend]WMSC_AddCertificate(&this, pCert);

	public HRESULT WMSC_AddSignature(uint8* pbCertSig, uint32 cbCertSig) mut => VT.[Friend]WMSC_AddSignature(&this, pbCertSig, cbCertSig);

	public HRESULT WMSC_Connect(IWMSecureChannel* pOtherSide) mut => VT.[Friend]WMSC_Connect(&this, pOtherSide);

	public HRESULT WMSC_IsConnected(BOOL* pfIsConnected) mut => VT.[Friend]WMSC_IsConnected(&this, pfIsConnected);

	public HRESULT WMSC_Disconnect() mut => VT.[Friend]WMSC_Disconnect(&this);

	public HRESULT WMSC_GetValidCertificate(uint8** ppbCertificate, uint32* pdwSignature) mut => VT.[Friend]WMSC_GetValidCertificate(&this, ppbCertificate, pdwSignature);

	public HRESULT WMSC_Encrypt(uint8* pbData, uint32 cbData) mut => VT.[Friend]WMSC_Encrypt(&this, pbData, cbData);

	public HRESULT WMSC_Decrypt(uint8* pbData, uint32 cbData) mut => VT.[Friend]WMSC_Decrypt(&this, pbData, cbData);

	public HRESULT WMSC_Lock() mut => VT.[Friend]WMSC_Lock(&this);

	public HRESULT WMSC_Unlock() mut => VT.[Friend]WMSC_Unlock(&this);

	public HRESULT WMSC_SetSharedData(uint32 dwCertIndex, uint8* pbSharedData) mut => VT.[Friend]WMSC_SetSharedData(&this, dwCertIndex, pbSharedData);
}

[CRepr]struct IWMGetSecureChannel : IUnknown
{
	public new const Guid IID = .(0x94bc0598, 0xc3d2, 0x11d3, 0xbe, 0xdf, 0x00, 0xc0, 0x4f, 0x61, 0x29, 0x86);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMSecureChannel** ppPeer) GetPeerSecureChannelInterface;
	}


	public HRESULT GetPeerSecureChannelInterface(IWMSecureChannel** ppPeer) mut => VT.[Friend]GetPeerSecureChannelInterface(&this, ppPeer);
}

[CRepr]struct INSNetSourceCreator : IUnknown
{
	public new const Guid IID = .(0x0c0e4080, 0x9081, 0x11d2, 0xbe, 0xec, 0x00, 0x60, 0x08, 0x2f, 0x20, 0x54);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszStreamName, IUnknown* pMonitor, uint8* pData, IUnknown* pUserContext, IUnknown* pCallback, uint64 qwContext) CreateNetSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszStreamName, IUnknown** ppPropertiesNode) GetNetSourceProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppSharedNamespace) GetNetSourceSharedNamespace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszStreamName, VARIANT* pVal) GetNetSourceAdminInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcProtocols) GetNumProtocolsSupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwProtocolNum, PWSTR pwszProtocolName, uint16* pcchProtocolName) GetProtocolName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Shutdown;
	}


	public HRESULT Initialize() mut => VT.[Friend]Initialize(&this);

	public HRESULT CreateNetSource(PWSTR pszStreamName, IUnknown* pMonitor, uint8* pData, IUnknown* pUserContext, IUnknown* pCallback, uint64 qwContext) mut => VT.[Friend]CreateNetSource(&this, pszStreamName, pMonitor, pData, pUserContext, pCallback, qwContext);

	public HRESULT GetNetSourceProperties(PWSTR pszStreamName, IUnknown** ppPropertiesNode) mut => VT.[Friend]GetNetSourceProperties(&this, pszStreamName, ppPropertiesNode);

	public HRESULT GetNetSourceSharedNamespace(IUnknown** ppSharedNamespace) mut => VT.[Friend]GetNetSourceSharedNamespace(&this, ppSharedNamespace);

	public HRESULT GetNetSourceAdminInterface(PWSTR pszStreamName, VARIANT* pVal) mut => VT.[Friend]GetNetSourceAdminInterface(&this, pszStreamName, pVal);

	public HRESULT GetNumProtocolsSupported(uint32* pcProtocols) mut => VT.[Friend]GetNumProtocolsSupported(&this, pcProtocols);

	public HRESULT GetProtocolName(uint32 dwProtocolNum, PWSTR pwszProtocolName, uint16* pcchProtocolName) mut => VT.[Friend]GetProtocolName(&this, dwProtocolNum, pwszProtocolName, pcchProtocolName);

	public HRESULT Shutdown() mut => VT.[Friend]Shutdown(&this);
}

[CRepr]struct IWMPlayerTimestampHook : IUnknown
{
	public new const Guid IID = .(0x28580dda, 0xd98e, 0x48d0, 0xb7, 0xae, 0x69, 0xe4, 0x73, 0xa0, 0x28, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64 rtIn, int64* prtOut) MapTimestamp;
	}


	public HRESULT MapTimestamp(int64 rtIn, int64* prtOut) mut => VT.[Friend]MapTimestamp(&this, rtIn, prtOut);
}

[CRepr]struct IWMSInternalAdminNetSource : IUnknown
{
	public new const Guid IID = .(0x8bb23e5f, 0xd127, 0x4afb, 0x8d, 0x02, 0xae, 0x5b, 0x66, 0xd5, 0x4c, 0x78);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pSharedNamespace, IUnknown* pNamespaceNode, INSNetSourceCreator* pNetSourceCreator, BOOL fEmbeddedInServer) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INSNetSourceCreator** ppNetSourceCreator) GetNetSourceCreator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRealm, BSTR bstrName, BSTR bstrPassword, BOOL fPersist, BOOL fConfirmedGood) SetCredentials;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRealm, BSTR* pbstrName, BSTR* pbstrPassword, BOOL* pfConfirmedGood) GetCredentials;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRealm) DeleteCredentials;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* lpdwFlags) GetCredentialFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) SetCredentialFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProtocol, BSTR bstrHost, BOOL* pfProxyEnabled, BSTR* pbstrProxyServer, uint32* pdwProxyPort, uint32* pdwProxyContext) FindProxyForURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrParam, uint32 dwProxyContext) RegisterProxyFailure;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwProxyContext) ShutdownProxyContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwProxyContext, BOOL* pfIsUsingIE) IsUsingIE;
	}


	public HRESULT Initialize(IUnknown* pSharedNamespace, IUnknown* pNamespaceNode, INSNetSourceCreator* pNetSourceCreator, BOOL fEmbeddedInServer) mut => VT.[Friend]Initialize(&this, pSharedNamespace, pNamespaceNode, pNetSourceCreator, fEmbeddedInServer);

	public HRESULT GetNetSourceCreator(INSNetSourceCreator** ppNetSourceCreator) mut => VT.[Friend]GetNetSourceCreator(&this, ppNetSourceCreator);

	public HRESULT SetCredentials(BSTR bstrRealm, BSTR bstrName, BSTR bstrPassword, BOOL fPersist, BOOL fConfirmedGood) mut => VT.[Friend]SetCredentials(&this, bstrRealm, bstrName, bstrPassword, fPersist, fConfirmedGood);

	public HRESULT GetCredentials(BSTR bstrRealm, BSTR* pbstrName, BSTR* pbstrPassword, BOOL* pfConfirmedGood) mut => VT.[Friend]GetCredentials(&this, bstrRealm, pbstrName, pbstrPassword, pfConfirmedGood);

	public HRESULT DeleteCredentials(BSTR bstrRealm) mut => VT.[Friend]DeleteCredentials(&this, bstrRealm);

	public HRESULT GetCredentialFlags(uint32* lpdwFlags) mut => VT.[Friend]GetCredentialFlags(&this, lpdwFlags);

	public HRESULT SetCredentialFlags(uint32 dwFlags) mut => VT.[Friend]SetCredentialFlags(&this, dwFlags);

	public HRESULT FindProxyForURL(BSTR bstrProtocol, BSTR bstrHost, BOOL* pfProxyEnabled, BSTR* pbstrProxyServer, uint32* pdwProxyPort, uint32* pdwProxyContext) mut => VT.[Friend]FindProxyForURL(&this, bstrProtocol, bstrHost, pfProxyEnabled, pbstrProxyServer, pdwProxyPort, pdwProxyContext);

	public HRESULT RegisterProxyFailure(HRESULT hrParam, uint32 dwProxyContext) mut => VT.[Friend]RegisterProxyFailure(&this, hrParam, dwProxyContext);

	public HRESULT ShutdownProxyContext(uint32 dwProxyContext) mut => VT.[Friend]ShutdownProxyContext(&this, dwProxyContext);

	public HRESULT IsUsingIE(uint32 dwProxyContext, BOOL* pfIsUsingIE) mut => VT.[Friend]IsUsingIE(&this, dwProxyContext, pfIsUsingIE);
}

[CRepr]struct IWMSInternalAdminNetSource2 : IUnknown
{
	public new const Guid IID = .(0xe74d58c3, 0xcf77, 0x4b51, 0xaf, 0x17, 0x74, 0x46, 0x87, 0xc4, 0x3e, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRealm, BSTR bstrUrl, BOOL fProxy, BSTR bstrName, BSTR bstrPassword, BOOL fPersist, BOOL fConfirmedGood) SetCredentialsEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRealm, BSTR bstrUrl, BOOL fProxy, NETSOURCE_URLCREDPOLICY_SETTINGS* pdwUrlPolicy, BSTR* pbstrName, BSTR* pbstrPassword, BOOL* pfConfirmedGood) GetCredentialsEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRealm, BSTR bstrUrl, BOOL fProxy) DeleteCredentialsEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProtocol, BSTR bstrHost, BSTR bstrUrl, BOOL* pfProxyEnabled, BSTR* pbstrProxyServer, uint32* pdwProxyPort, uint32* pdwProxyContext) FindProxyForURLEx;
	}


	public HRESULT SetCredentialsEx(BSTR bstrRealm, BSTR bstrUrl, BOOL fProxy, BSTR bstrName, BSTR bstrPassword, BOOL fPersist, BOOL fConfirmedGood) mut => VT.[Friend]SetCredentialsEx(&this, bstrRealm, bstrUrl, fProxy, bstrName, bstrPassword, fPersist, fConfirmedGood);

	public HRESULT GetCredentialsEx(BSTR bstrRealm, BSTR bstrUrl, BOOL fProxy, NETSOURCE_URLCREDPOLICY_SETTINGS* pdwUrlPolicy, BSTR* pbstrName, BSTR* pbstrPassword, BOOL* pfConfirmedGood) mut => VT.[Friend]GetCredentialsEx(&this, bstrRealm, bstrUrl, fProxy, pdwUrlPolicy, pbstrName, pbstrPassword, pfConfirmedGood);

	public HRESULT DeleteCredentialsEx(BSTR bstrRealm, BSTR bstrUrl, BOOL fProxy) mut => VT.[Friend]DeleteCredentialsEx(&this, bstrRealm, bstrUrl, fProxy);

	public HRESULT FindProxyForURLEx(BSTR bstrProtocol, BSTR bstrHost, BSTR bstrUrl, BOOL* pfProxyEnabled, BSTR* pbstrProxyServer, uint32* pdwProxyPort, uint32* pdwProxyContext) mut => VT.[Friend]FindProxyForURLEx(&this, bstrProtocol, bstrHost, bstrUrl, pfProxyEnabled, pbstrProxyServer, pdwProxyPort, pdwProxyContext);
}

[CRepr]struct IWMSInternalAdminNetSource3 : IWMSInternalAdminNetSource2
{
	public new const Guid IID = .(0x6b63d08e, 0x4590, 0x44af, 0x9e, 0xb3, 0x57, 0xff, 0x1e, 0x73, 0xbf, 0x80);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMSInternalAdminNetSource2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppNetSourceCreator) GetNetSourceCreator2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProtocol, BSTR bstrHost, BSTR bstrUrl, BOOL* pfProxyEnabled, BSTR* pbstrProxyServer, uint32* pdwProxyPort, uint64* pqwProxyContext) FindProxyForURLEx2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrParam, uint64 qwProxyContext) RegisterProxyFailure2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 qwProxyContext) ShutdownProxyContext2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 qwProxyContext, BOOL* pfIsUsingIE) IsUsingIE2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRealm, BSTR bstrUrl, BOOL fProxy, BSTR bstrName, BSTR bstrPassword, BOOL fPersist, BOOL fConfirmedGood, BOOL fClearTextAuthentication) SetCredentialsEx2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRealm, BSTR bstrUrl, BOOL fProxy, BOOL fClearTextAuthentication, NETSOURCE_URLCREDPOLICY_SETTINGS* pdwUrlPolicy, BSTR* pbstrName, BSTR* pbstrPassword, BOOL* pfConfirmedGood) GetCredentialsEx2;
	}


	public HRESULT GetNetSourceCreator2(IUnknown** ppNetSourceCreator) mut => VT.[Friend]GetNetSourceCreator2(&this, ppNetSourceCreator);

	public HRESULT FindProxyForURLEx2(BSTR bstrProtocol, BSTR bstrHost, BSTR bstrUrl, BOOL* pfProxyEnabled, BSTR* pbstrProxyServer, uint32* pdwProxyPort, uint64* pqwProxyContext) mut => VT.[Friend]FindProxyForURLEx2(&this, bstrProtocol, bstrHost, bstrUrl, pfProxyEnabled, pbstrProxyServer, pdwProxyPort, pqwProxyContext);

	public HRESULT RegisterProxyFailure2(HRESULT hrParam, uint64 qwProxyContext) mut => VT.[Friend]RegisterProxyFailure2(&this, hrParam, qwProxyContext);

	public HRESULT ShutdownProxyContext2(uint64 qwProxyContext) mut => VT.[Friend]ShutdownProxyContext2(&this, qwProxyContext);

	public HRESULT IsUsingIE2(uint64 qwProxyContext, BOOL* pfIsUsingIE) mut => VT.[Friend]IsUsingIE2(&this, qwProxyContext, pfIsUsingIE);

	public HRESULT SetCredentialsEx2(BSTR bstrRealm, BSTR bstrUrl, BOOL fProxy, BSTR bstrName, BSTR bstrPassword, BOOL fPersist, BOOL fConfirmedGood, BOOL fClearTextAuthentication) mut => VT.[Friend]SetCredentialsEx2(&this, bstrRealm, bstrUrl, fProxy, bstrName, bstrPassword, fPersist, fConfirmedGood, fClearTextAuthentication);

	public HRESULT GetCredentialsEx2(BSTR bstrRealm, BSTR bstrUrl, BOOL fProxy, BOOL fClearTextAuthentication, NETSOURCE_URLCREDPOLICY_SETTINGS* pdwUrlPolicy, BSTR* pbstrName, BSTR* pbstrPassword, BOOL* pfConfirmedGood) mut => VT.[Friend]GetCredentialsEx2(&this, bstrRealm, bstrUrl, fProxy, fClearTextAuthentication, pdwUrlPolicy, pbstrName, pbstrPassword, pfConfirmedGood);
}

#endregion

#region Functions
public static
{
	[Import("WMVCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WMIsContentProtected(PWSTR pwszFileName, BOOL* pfIsProtected);

	[Import("WMVCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WMCreateWriter(IUnknown* pUnkCert, IWMWriter** ppWriter);

	[Import("WMVCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WMCreateReader(IUnknown* pUnkCert, uint32 dwRights, IWMReader** ppReader);

	[Import("WMVCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WMCreateSyncReader(IUnknown* pUnkCert, uint32 dwRights, IWMSyncReader** ppSyncReader);

	[Import("WMVCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WMCreateEditor(IWMMetadataEditor** ppEditor);

	[Import("WMVCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WMCreateIndexer(IWMIndexer** ppIndexer);

	[Import("WMVCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WMCreateBackupRestorer(IUnknown* pCallback, IWMLicenseBackup** ppBackup);

	[Import("WMVCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WMCreateProfileManager(IWMProfileManager** ppProfileManager);

	[Import("WMVCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WMCreateWriterFileSink(IWMWriterFileSink** ppSink);

	[Import("WMVCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WMCreateWriterNetworkSink(IWMWriterNetworkSink** ppSink);

	[Import("WMVCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WMCreateWriterPushSink(IWMWriterPushSink** ppSink);

}
#endregion
