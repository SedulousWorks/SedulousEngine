using Win32.Foundation;
using Win32.System.Com;
using Win32.System.Registry;
using Win32.Media.Audio;
using Win32.System.Com.Urlmon;
using System;

namespace Win32.Media.Speech;

#region Constants
public static
{
	public const String SPDUI_EngineProperties = "EngineProperties";
	public const String SPDUI_AddRemoveWord = "AddRemoveWord";
	public const String SPDUI_UserTraining = "UserTraining";
	public const String SPDUI_MicTraining = "MicTraining";
	public const String SPDUI_RecoProfileProperties = "RecoProfileProperties";
	public const String SPDUI_AudioProperties = "AudioProperties";
	public const String SPDUI_AudioVolume = "AudioVolume";
	public const String SPDUI_UserEnrollment = "UserEnrollment";
	public const String SPDUI_ShareData = "ShareData";
	public const String SPDUI_Tutorial = "Tutorial";
	public const String SPREG_USER_ROOT = "HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Speech";
	public const String SPREG_LOCAL_MACHINE_ROOT = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Speech";
	public const String SPCAT_AUDIOOUT = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Speech\\AudioOutput";
	public const String SPCAT_AUDIOIN = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Speech\\AudioInput";
	public const String SPCAT_VOICES = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Speech\\Voices";
	public const String SPCAT_RECOGNIZERS = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Speech\\Recognizers";
	public const String SPCAT_APPLEXICONS = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Speech\\AppLexicons";
	public const String SPCAT_PHONECONVERTERS = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Speech\\PhoneConverters";
	public const String SPCAT_TEXTNORMALIZERS = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Speech\\TextNormalizers";
	public const String SPCAT_RECOPROFILES = "HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Speech\\RecoProfiles";
	public const String SPMMSYS_AUDIO_IN_TOKEN_ID = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Speech\\AudioInput\\TokenEnums\\MMAudioIn\\";
	public const String SPMMSYS_AUDIO_OUT_TOKEN_ID = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Speech\\AudioOutput\\TokenEnums\\MMAudioOut\\";
	public const String SPCURRENT_USER_LEXICON_TOKEN_ID = "HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Speech\\CurrentUserLexicon";
	public const String SPCURRENT_USER_SHORTCUT_TOKEN_ID = "HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Speech\\CurrentUserShortcut";
	public const String SPTOKENVALUE_CLSID = "CLSID";
	public const String SPTOKENKEY_FILES = "Files";
	public const String SPTOKENKEY_UI = "UI";
	public const String SPTOKENKEY_ATTRIBUTES = "Attributes";
	public const String SPTOKENKEY_RETAINEDAUDIO = "SecondsPerRetainedAudioEvent";
	public const String SPTOKENKEY_AUDIO_LATENCY_WARNING = "LatencyWarningThreshold";
	public const String SPTOKENKEY_AUDIO_LATENCY_TRUNCATE = "LatencyTruncateThreshold";
	public const String SPTOKENKEY_AUDIO_LATENCY_UPDATE_INTERVAL = "LatencyUpdateInterval";
	public const String SPVOICECATEGORY_TTSRATE = "DefaultTTSRate";
	public const String SPPROP_RESOURCE_USAGE = "ResourceUsage";
	public const String SPPROP_HIGH_CONFIDENCE_THRESHOLD = "HighConfidenceThreshold";
	public const String SPPROP_NORMAL_CONFIDENCE_THRESHOLD = "NormalConfidenceThreshold";
	public const String SPPROP_LOW_CONFIDENCE_THRESHOLD = "LowConfidenceThreshold";
	public const String SPPROP_RESPONSE_SPEED = "ResponseSpeed";
	public const String SPPROP_COMPLEX_RESPONSE_SPEED = "ComplexResponseSpeed";
	public const String SPPROP_ADAPTATION_ON = "AdaptationOn";
	public const String SPPROP_PERSISTED_BACKGROUND_ADAPTATION = "PersistedBackgroundAdaptation";
	public const String SPPROP_PERSISTED_LANGUAGE_MODEL_ADAPTATION = "PersistedLanguageModelAdaptation";
	public const String SPPROP_UX_IS_LISTENING = "UXIsListening";
	public const String SPTOPIC_SPELLING = "Spelling";
	public const String SPWILDCARD = "...";
	public const String SPDICTATION = "*";
	public const String SPINFDICTATION = "*+";
	public const String SPREG_SAFE_USER_TOKENS = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Speech\\UserTokens";
	public const int32 SP_LOW_CONFIDENCE = -1;
	public const uint32 SP_NORMAL_CONFIDENCE = 0;
	public const uint32 DEFAULT_WEIGHT = 1;
	public const uint32 SP_MAX_WORD_LENGTH = 128;
	public const uint32 SP_MAX_PRON_LENGTH = 384;
	public const uint32 SP_EMULATE_RESULT = 1073741824;
	public const uint32 SP_STREAMPOS_ASAP = 0;
	public const int32 SP_STREAMPOS_REALTIME = -1;
	public const uint32 SPRP_NORMAL = 0;
	public const uint32 SP_MAX_LANGIDS = 20;
	public const String SPRECOEXTENSION = "RecoExtension";
	public const String SPALTERNATESCLSID = "AlternatesCLSID";
	public const String SR_LOCALIZED_DESCRIPTION = "Description";
	public const uint32 SAPI_ERROR_BASE = 20480;
	public const float Speech_Default_Weight = 1f;
	public const int32 Speech_Max_Word_Length = 128;
	public const int32 Speech_Max_Pron_Length = 384;
	public const int32 Speech_StreamPos_Asap = 0;
	public const int32 Speech_StreamPos_RealTime = -1;
	public const int32 SpeechAllElements = -1;
}
#endregion

#region Enums

[AllowDuplicates]
public enum SPDATAKEYLOCATION : int32
{
	SPDKL_DefaultLocation = 0,
	SPDKL_CurrentUser = 1,
	SPDKL_LocalMachine = 2,
	SPDKL_CurrentConfig = 5,
}


[AllowDuplicates]
public enum SPSTREAMFORMAT : int32
{
	SPSF_Default = -1,
	SPSF_NoAssignedFormat = 0,
	SPSF_Text = 1,
	SPSF_NonStandardFormat = 2,
	SPSF_ExtendedAudioFormat = 3,
	SPSF_8kHz8BitMono = 4,
	SPSF_8kHz8BitStereo = 5,
	SPSF_8kHz16BitMono = 6,
	SPSF_8kHz16BitStereo = 7,
	SPSF_11kHz8BitMono = 8,
	SPSF_11kHz8BitStereo = 9,
	SPSF_11kHz16BitMono = 10,
	SPSF_11kHz16BitStereo = 11,
	SPSF_12kHz8BitMono = 12,
	SPSF_12kHz8BitStereo = 13,
	SPSF_12kHz16BitMono = 14,
	SPSF_12kHz16BitStereo = 15,
	SPSF_16kHz8BitMono = 16,
	SPSF_16kHz8BitStereo = 17,
	SPSF_16kHz16BitMono = 18,
	SPSF_16kHz16BitStereo = 19,
	SPSF_22kHz8BitMono = 20,
	SPSF_22kHz8BitStereo = 21,
	SPSF_22kHz16BitMono = 22,
	SPSF_22kHz16BitStereo = 23,
	SPSF_24kHz8BitMono = 24,
	SPSF_24kHz8BitStereo = 25,
	SPSF_24kHz16BitMono = 26,
	SPSF_24kHz16BitStereo = 27,
	SPSF_32kHz8BitMono = 28,
	SPSF_32kHz8BitStereo = 29,
	SPSF_32kHz16BitMono = 30,
	SPSF_32kHz16BitStereo = 31,
	SPSF_44kHz8BitMono = 32,
	SPSF_44kHz8BitStereo = 33,
	SPSF_44kHz16BitMono = 34,
	SPSF_44kHz16BitStereo = 35,
	SPSF_48kHz8BitMono = 36,
	SPSF_48kHz8BitStereo = 37,
	SPSF_48kHz16BitMono = 38,
	SPSF_48kHz16BitStereo = 39,
	SPSF_TrueSpeech_8kHz1BitMono = 40,
	SPSF_CCITT_ALaw_8kHzMono = 41,
	SPSF_CCITT_ALaw_8kHzStereo = 42,
	SPSF_CCITT_ALaw_11kHzMono = 43,
	SPSF_CCITT_ALaw_11kHzStereo = 44,
	SPSF_CCITT_ALaw_22kHzMono = 45,
	SPSF_CCITT_ALaw_22kHzStereo = 46,
	SPSF_CCITT_ALaw_44kHzMono = 47,
	SPSF_CCITT_ALaw_44kHzStereo = 48,
	SPSF_CCITT_uLaw_8kHzMono = 49,
	SPSF_CCITT_uLaw_8kHzStereo = 50,
	SPSF_CCITT_uLaw_11kHzMono = 51,
	SPSF_CCITT_uLaw_11kHzStereo = 52,
	SPSF_CCITT_uLaw_22kHzMono = 53,
	SPSF_CCITT_uLaw_22kHzStereo = 54,
	SPSF_CCITT_uLaw_44kHzMono = 55,
	SPSF_CCITT_uLaw_44kHzStereo = 56,
	SPSF_ADPCM_8kHzMono = 57,
	SPSF_ADPCM_8kHzStereo = 58,
	SPSF_ADPCM_11kHzMono = 59,
	SPSF_ADPCM_11kHzStereo = 60,
	SPSF_ADPCM_22kHzMono = 61,
	SPSF_ADPCM_22kHzStereo = 62,
	SPSF_ADPCM_44kHzMono = 63,
	SPSF_ADPCM_44kHzStereo = 64,
	SPSF_GSM610_8kHzMono = 65,
	SPSF_GSM610_11kHzMono = 66,
	SPSF_GSM610_22kHzMono = 67,
	SPSF_GSM610_44kHzMono = 68,
	SPSF_NUM_FORMATS = 69,
}


[AllowDuplicates]
public enum SPEVENTLPARAMTYPE : int32
{
	SPET_LPARAM_IS_UNDEFINED = 0,
	SPET_LPARAM_IS_TOKEN = 1,
	SPET_LPARAM_IS_OBJECT = 2,
	SPET_LPARAM_IS_POINTER = 3,
	SPET_LPARAM_IS_STRING = 4,
}


[AllowDuplicates]
public enum SPEVENTENUM : int32
{
	SPEI_UNDEFINED = 0,
	SPEI_START_INPUT_STREAM = 1,
	SPEI_END_INPUT_STREAM = 2,
	SPEI_VOICE_CHANGE = 3,
	SPEI_TTS_BOOKMARK = 4,
	SPEI_WORD_BOUNDARY = 5,
	SPEI_PHONEME = 6,
	SPEI_SENTENCE_BOUNDARY = 7,
	SPEI_VISEME = 8,
	SPEI_TTS_AUDIO_LEVEL = 9,
	SPEI_TTS_PRIVATE = 15,
	SPEI_MIN_TTS = 1,
	SPEI_MAX_TTS = 15,
	SPEI_END_SR_STREAM = 34,
	SPEI_SOUND_START = 35,
	SPEI_SOUND_END = 36,
	SPEI_PHRASE_START = 37,
	SPEI_RECOGNITION = 38,
	SPEI_HYPOTHESIS = 39,
	SPEI_SR_BOOKMARK = 40,
	SPEI_PROPERTY_NUM_CHANGE = 41,
	SPEI_PROPERTY_STRING_CHANGE = 42,
	SPEI_FALSE_RECOGNITION = 43,
	SPEI_INTERFERENCE = 44,
	SPEI_REQUEST_UI = 45,
	SPEI_RECO_STATE_CHANGE = 46,
	SPEI_ADAPTATION = 47,
	SPEI_START_SR_STREAM = 48,
	SPEI_RECO_OTHER_CONTEXT = 49,
	SPEI_SR_AUDIO_LEVEL = 50,
	SPEI_SR_RETAINEDAUDIO = 51,
	SPEI_SR_PRIVATE = 52,
	SPEI_RESERVED4 = 53,
	SPEI_RESERVED5 = 54,
	SPEI_RESERVED6 = 55,
	SPEI_MIN_SR = 34,
	SPEI_MAX_SR = 55,
	SPEI_RESERVED1 = 30,
	SPEI_RESERVED2 = 33,
	SPEI_RESERVED3 = 63,
}


[AllowDuplicates]
public enum SPINTERFERENCE : int32
{
	SPINTERFERENCE_NONE = 0,
	SPINTERFERENCE_NOISE = 1,
	SPINTERFERENCE_NOSIGNAL = 2,
	SPINTERFERENCE_TOOLOUD = 3,
	SPINTERFERENCE_TOOQUIET = 4,
	SPINTERFERENCE_TOOFAST = 5,
	SPINTERFERENCE_TOOSLOW = 6,
	SPINTERFERENCE_LATENCY_WARNING = 7,
	SPINTERFERENCE_LATENCY_TRUNCATE_BEGIN = 8,
	SPINTERFERENCE_LATENCY_TRUNCATE_END = 9,
}


[AllowDuplicates]
public enum SPENDSRSTREAMFLAGS : int32
{
	SPESF_NONE = 0,
	SPESF_STREAM_RELEASED = 1,
	SPESF_EMULATED = 2,
}


[AllowDuplicates]
public enum SPVFEATURE : int32
{
	SPVFEATURE_STRESSED = 1,
	SPVFEATURE_EMPHASIS = 2,
}


[AllowDuplicates]
public enum SPVISEMES : int32
{
	SP_VISEME_0 = 0,
	SP_VISEME_1 = 1,
	SP_VISEME_2 = 2,
	SP_VISEME_3 = 3,
	SP_VISEME_4 = 4,
	SP_VISEME_5 = 5,
	SP_VISEME_6 = 6,
	SP_VISEME_7 = 7,
	SP_VISEME_8 = 8,
	SP_VISEME_9 = 9,
	SP_VISEME_10 = 10,
	SP_VISEME_11 = 11,
	SP_VISEME_12 = 12,
	SP_VISEME_13 = 13,
	SP_VISEME_14 = 14,
	SP_VISEME_15 = 15,
	SP_VISEME_16 = 16,
	SP_VISEME_17 = 17,
	SP_VISEME_18 = 18,
	SP_VISEME_19 = 19,
	SP_VISEME_20 = 20,
	SP_VISEME_21 = 21,
}


[AllowDuplicates]
public enum SPFILEMODE : int32
{
	SPFM_OPEN_READONLY = 0,
	SPFM_OPEN_READWRITE = 1,
	SPFM_CREATE = 2,
	SPFM_CREATE_ALWAYS = 3,
	SPFM_NUM_MODES = 4,
}


[AllowDuplicates]
public enum SPAUDIOSTATE : int32
{
	SPAS_CLOSED = 0,
	SPAS_STOP = 1,
	SPAS_PAUSE = 2,
	SPAS_RUN = 3,
}


[AllowDuplicates]
public enum SPDISPLAYATTRIBUTES : int32
{
	SPAF_ONE_TRAILING_SPACE = 2,
	SPAF_TWO_TRAILING_SPACES = 4,
	SPAF_CONSUME_LEADING_SPACES = 8,
	SPAF_BUFFER_POSITION = 16,
	SPAF_ALL = 31,
	SPAF_USER_SPECIFIED = 128,
}


[AllowDuplicates]
public enum SPPHRASEPROPERTYUNIONTYPE : int32
{
	SPPPUT_UNUSED = 0,
	SPPPUT_ARRAY_INDEX = 1,
}


[AllowDuplicates]
public enum SPSEMANTICFORMAT : int32
{
	SPSMF_SAPI_PROPERTIES = 0,
	SPSMF_SRGS_SEMANTICINTERPRETATION_MS = 1,
	SPSMF_SRGS_SAPIPROPERTIES = 2,
	SPSMF_UPS = 4,
	SPSMF_SRGS_SEMANTICINTERPRETATION_W3C = 8,
}


[AllowDuplicates]
public enum SPVALUETYPE : int32
{
	SPDF_PROPERTY = 1,
	SPDF_REPLACEMENT = 2,
	SPDF_RULE = 4,
	SPDF_DISPLAYTEXT = 8,
	SPDF_LEXICALFORM = 16,
	SPDF_PRONUNCIATION = 32,
	SPDF_AUDIO = 64,
	SPDF_ALTERNATES = 128,
	SPDF_ALL = 255,
}


[AllowDuplicates]
public enum SPPHRASERNG : int32
{
	SPPR_ALL_ELEMENTS = -1,
}


[AllowDuplicates]
public enum SPRECOEVENTFLAGS : int32
{
	SPREF_AutoPause = 1,
	SPREF_Emulated = 2,
	SPREF_SMLTimeout = 4,
	SPREF_ExtendableParse = 8,
	SPREF_ReSent = 16,
	SPREF_Hypothesis = 32,
	SPREF_FalseRecognition = 64,
}


[AllowDuplicates]
public enum SPPARTOFSPEECH : int32
{
	SPPS_NotOverriden = -1,
	SPPS_Unknown = 0,
	SPPS_Noun = 4096,
	SPPS_Verb = 8192,
	SPPS_Modifier = 12288,
	SPPS_Function = 16384,
	SPPS_Interjection = 20480,
	SPPS_Noncontent = 24576,
	SPPS_LMA = 28672,
	SPPS_SuppressWord = 61440,
}


[AllowDuplicates]
public enum SPLEXICONTYPE : int32
{
	eLEXTYPE_USER = 1,
	eLEXTYPE_APP = 2,
	eLEXTYPE_VENDORLEXICON = 4,
	eLEXTYPE_LETTERTOSOUND = 8,
	eLEXTYPE_MORPHOLOGY = 16,
	eLEXTYPE_RESERVED4 = 32,
	eLEXTYPE_USER_SHORTCUT = 64,
	eLEXTYPE_RESERVED6 = 128,
	eLEXTYPE_RESERVED7 = 256,
	eLEXTYPE_RESERVED8 = 512,
	eLEXTYPE_RESERVED9 = 1024,
	eLEXTYPE_RESERVED10 = 2048,
	eLEXTYPE_PRIVATE1 = 4096,
	eLEXTYPE_PRIVATE2 = 8192,
	eLEXTYPE_PRIVATE3 = 16384,
	eLEXTYPE_PRIVATE4 = 32768,
	eLEXTYPE_PRIVATE5 = 65536,
	eLEXTYPE_PRIVATE6 = 131072,
	eLEXTYPE_PRIVATE7 = 262144,
	eLEXTYPE_PRIVATE8 = 524288,
	eLEXTYPE_PRIVATE9 = 1048576,
	eLEXTYPE_PRIVATE10 = 2097152,
	eLEXTYPE_PRIVATE11 = 4194304,
	eLEXTYPE_PRIVATE12 = 8388608,
	eLEXTYPE_PRIVATE13 = 16777216,
	eLEXTYPE_PRIVATE14 = 33554432,
	eLEXTYPE_PRIVATE15 = 67108864,
	eLEXTYPE_PRIVATE16 = 134217728,
	eLEXTYPE_PRIVATE17 = 268435456,
	eLEXTYPE_PRIVATE18 = 536870912,
	eLEXTYPE_PRIVATE19 = 1073741824,
	eLEXTYPE_PRIVATE20 = -2147483648,
}


[AllowDuplicates]
public enum SPWORDTYPE : int32
{
	eWORDTYPE_ADDED = 1,
	eWORDTYPE_DELETED = 2,
}


[AllowDuplicates]
public enum SPPRONUNCIATIONFLAGS : int32
{
	ePRONFLAG_USED = 1,
}


[AllowDuplicates]
public enum SPSHORTCUTTYPE : int32
{
	SPSHT_NotOverriden = -1,
	SPSHT_Unknown = 0,
	SPSHT_EMAIL = 4096,
	SPSHT_OTHER = 8192,
	SPPS_RESERVED1 = 12288,
	SPPS_RESERVED2 = 16384,
	SPPS_RESERVED3 = 20480,
	SPPS_RESERVED4 = 61440,
}


[AllowDuplicates]
public enum SPVACTIONS : int32
{
	SPVA_Speak = 0,
	SPVA_Silence = 1,
	SPVA_Pronounce = 2,
	SPVA_Bookmark = 3,
	SPVA_SpellOut = 4,
	SPVA_Section = 5,
	SPVA_ParseUnknownTag = 6,
}


[AllowDuplicates]
public enum SPRUNSTATE : int32
{
	SPRS_DONE = 1,
	SPRS_IS_SPEAKING = 2,
}


[AllowDuplicates]
public enum SPVLIMITS : int32
{
	SPMIN_VOLUME = 0,
	SPMAX_VOLUME = 100,
	SPMIN_RATE = -10,
	SPMAX_RATE = 10,
}


[AllowDuplicates]
public enum SPVPRIORITY : int32
{
	SPVPRI_NORMAL = 0,
	SPVPRI_ALERT = 1,
	SPVPRI_OVER = 2,
}


[AllowDuplicates]
public enum SPEAKFLAGS : int32
{
	SPF_DEFAULT = 0,
	SPF_ASYNC = 1,
	SPF_PURGEBEFORESPEAK = 2,
	SPF_IS_FILENAME = 4,
	SPF_IS_XML = 8,
	SPF_IS_NOT_XML = 16,
	SPF_PERSIST_XML = 32,
	SPF_NLP_SPEAK_PUNC = 64,
	SPF_PARSE_SAPI = 128,
	SPF_PARSE_SSML = 256,
	SPF_PARSE_AUTODETECT = 0,
	SPF_NLP_MASK = 64,
	SPF_PARSE_MASK = 384,
	SPF_VOICE_MASK = 511,
	SPF_UNUSED_FLAGS = -512,
}


[AllowDuplicates]
public enum SPXMLRESULTOPTIONS : int32
{
	SPXRO_SML = 0,
	SPXRO_Alternates_SML = 1,
}


[AllowDuplicates]
public enum SPCOMMITFLAGS : int32
{
	SPCF_NONE = 0,
	SPCF_ADD_TO_USER_LEXICON = 1,
	SPCF_DEFINITE_CORRECTION = 2,
}


[AllowDuplicates]
public enum SPWORDPRONOUNCEABLE : int32
{
	SPWP_UNKNOWN_WORD_UNPRONOUNCEABLE = 0,
	SPWP_UNKNOWN_WORD_PRONOUNCEABLE = 1,
	SPWP_KNOWN_WORD_PRONOUNCEABLE = 2,
}


[AllowDuplicates]
public enum SPGRAMMARSTATE : int32
{
	SPGS_DISABLED = 0,
	SPGS_ENABLED = 1,
	SPGS_EXCLUSIVE = 3,
}


[AllowDuplicates]
public enum SPCONTEXTSTATE : int32
{
	SPCS_DISABLED = 0,
	SPCS_ENABLED = 1,
}


[AllowDuplicates]
public enum SPRULESTATE : int32
{
	SPRS_INACTIVE = 0,
	SPRS_ACTIVE = 1,
	SPRS_ACTIVE_WITH_AUTO_PAUSE = 3,
	SPRS_ACTIVE_USER_DELIMITED = 4,
}


[AllowDuplicates]
public enum SPGRAMMARWORDTYPE : int32
{
	SPWT_DISPLAY = 0,
	SPWT_LEXICAL = 1,
	SPWT_PRONUNCIATION = 2,
	SPWT_LEXICAL_NO_SPECIAL_CHARS = 3,
}


[AllowDuplicates]
public enum SPCFGRULEATTRIBUTES : int32
{
	SPRAF_TopLevel = 1,
	SPRAF_Active = 2,
	SPRAF_Export = 4,
	SPRAF_Import = 8,
	SPRAF_Interpreter = 16,
	SPRAF_Dynamic = 32,
	SPRAF_Root = 64,
	SPRAF_AutoPause = 65536,
	SPRAF_UserDelimited = 131072,
}


[AllowDuplicates]
public enum SPLOADOPTIONS : int32
{
	SPLO_STATIC = 0,
	SPLO_DYNAMIC = 1,
}


[AllowDuplicates]
public enum SPMATCHINGMODE : int32
{
	AllWords = 0,
	Subsequence = 1,
	OrderedSubset = 3,
	SubsequenceContentRequired = 5,
	OrderedSubsetContentRequired = 7,
}


[AllowDuplicates]
public enum PHONETICALPHABET : int32
{
	PA_Ipa = 0,
	PA_Ups = 1,
	PA_Sapi = 2,
}


[AllowDuplicates]
public enum SPBOOKMARKOPTIONS : int32
{
	SPBO_NONE = 0,
	SPBO_PAUSE = 1,
	SPBO_AHEAD = 2,
	SPBO_TIME_UNITS = 4,
}


[AllowDuplicates]
public enum SPAUDIOOPTIONS : int32
{
	SPAO_NONE = 0,
	SPAO_RETAIN_AUDIO = 1,
}


[AllowDuplicates]
public enum SPGRAMMAROPTIONS : int32
{
	SPGO_SAPI = 1,
	SPGO_SRGS = 2,
	SPGO_UPS = 4,
	SPGO_SRGS_MS_SCRIPT = 8,
	SPGO_SRGS_W3C_SCRIPT = 256,
	SPGO_SRGS_STG_SCRIPT = 512,
	SPGO_SRGS_SCRIPT = 778,
	SPGO_FILE = 16,
	SPGO_HTTP = 32,
	SPGO_RES = 64,
	SPGO_OBJECT = 128,
	SPGO_DEFAULT = 1019,
	SPGO_ALL = 1023,
}


[AllowDuplicates]
public enum SPADAPTATIONSETTINGS : int32
{
	SPADS_Default = 0,
	SPADS_CurrentRecognizer = 1,
	SPADS_RecoProfile = 2,
	SPADS_Immediate = 4,
	SPADS_Reset = 8,
	SPADS_HighVolumeDataSource = 16,
}


[AllowDuplicates]
public enum SPADAPTATIONRELEVANCE : int32
{
	SPAR_Unknown = 0,
	SPAR_Low = 1,
	SPAR_Medium = 2,
	SPAR_High = 3,
}


[AllowDuplicates]
public enum SPSTREAMFORMATTYPE : int32
{
	SPWF_INPUT = 0,
	SPWF_SRENGINE = 1,
}


[AllowDuplicates]
public enum SPRECOSTATE : int32
{
	SPRST_INACTIVE = 0,
	SPRST_ACTIVE = 1,
	SPRST_ACTIVE_ALWAYS = 2,
	SPRST_INACTIVE_WITH_PURGE = 3,
	SPRST_NUM_STATES = 4,
}


[AllowDuplicates]
public enum DISPID_SpeechDataKey : int32
{
	DISPID_SDKSetBinaryValue = 1,
	DISPID_SDKGetBinaryValue = 2,
	DISPID_SDKSetStringValue = 3,
	DISPID_SDKGetStringValue = 4,
	DISPID_SDKSetLongValue = 5,
	DISPID_SDKGetlongValue = 6,
	DISPID_SDKOpenKey = 7,
	DISPID_SDKCreateKey = 8,
	DISPID_SDKDeleteKey = 9,
	DISPID_SDKDeleteValue = 10,
	DISPID_SDKEnumKeys = 11,
	DISPID_SDKEnumValues = 12,
}


[AllowDuplicates]
public enum DISPID_SpeechObjectToken : int32
{
	DISPID_SOTId = 1,
	DISPID_SOTDataKey = 2,
	DISPID_SOTCategory = 3,
	DISPID_SOTGetDescription = 4,
	DISPID_SOTSetId = 5,
	DISPID_SOTGetAttribute = 6,
	DISPID_SOTCreateInstance = 7,
	DISPID_SOTRemove = 8,
	DISPID_SOTGetStorageFileName = 9,
	DISPID_SOTRemoveStorageFileName = 10,
	DISPID_SOTIsUISupported = 11,
	DISPID_SOTDisplayUI = 12,
	DISPID_SOTMatchesAttributes = 13,
}


[AllowDuplicates]
public enum SpeechDataKeyLocation : int32
{
	SDKLDefaultLocation = 0,
	SDKLCurrentUser = 1,
	SDKLLocalMachine = 2,
	SDKLCurrentConfig = 5,
}


[AllowDuplicates]
public enum SpeechTokenContext : uint32
{
	STCInprocServer = 1,
	STCInprocHandler = 2,
	STCLocalServer = 4,
	STCRemoteServer = 16,
	STCAll = 23,
}


[AllowDuplicates]
public enum SpeechTokenShellFolder : int32
{
	STSF_AppData = 26,
	STSF_LocalAppData = 28,
	STSF_CommonAppData = 35,
	STSF_FlagCreate = 32768,
}


[AllowDuplicates]
public enum DISPID_SpeechObjectTokens : int32
{
	DISPID_SOTsCount = 1,
	DISPID_SOTsItem = 0,
	DISPID_SOTs_NewEnum = -4,
}


[AllowDuplicates]
public enum DISPID_SpeechObjectTokenCategory : int32
{
	DISPID_SOTCId = 1,
	DISPID_SOTCDefault = 2,
	DISPID_SOTCSetId = 3,
	DISPID_SOTCGetDataKey = 4,
	DISPID_SOTCEnumerateTokens = 5,
}


[AllowDuplicates]
public enum SpeechAudioFormatType : int32
{
	SAFTDefault = -1,
	SAFTNoAssignedFormat = 0,
	SAFTText = 1,
	SAFTNonStandardFormat = 2,
	SAFTExtendedAudioFormat = 3,
	SAFT8kHz8BitMono = 4,
	SAFT8kHz8BitStereo = 5,
	SAFT8kHz16BitMono = 6,
	SAFT8kHz16BitStereo = 7,
	SAFT11kHz8BitMono = 8,
	SAFT11kHz8BitStereo = 9,
	SAFT11kHz16BitMono = 10,
	SAFT11kHz16BitStereo = 11,
	SAFT12kHz8BitMono = 12,
	SAFT12kHz8BitStereo = 13,
	SAFT12kHz16BitMono = 14,
	SAFT12kHz16BitStereo = 15,
	SAFT16kHz8BitMono = 16,
	SAFT16kHz8BitStereo = 17,
	SAFT16kHz16BitMono = 18,
	SAFT16kHz16BitStereo = 19,
	SAFT22kHz8BitMono = 20,
	SAFT22kHz8BitStereo = 21,
	SAFT22kHz16BitMono = 22,
	SAFT22kHz16BitStereo = 23,
	SAFT24kHz8BitMono = 24,
	SAFT24kHz8BitStereo = 25,
	SAFT24kHz16BitMono = 26,
	SAFT24kHz16BitStereo = 27,
	SAFT32kHz8BitMono = 28,
	SAFT32kHz8BitStereo = 29,
	SAFT32kHz16BitMono = 30,
	SAFT32kHz16BitStereo = 31,
	SAFT44kHz8BitMono = 32,
	SAFT44kHz8BitStereo = 33,
	SAFT44kHz16BitMono = 34,
	SAFT44kHz16BitStereo = 35,
	SAFT48kHz8BitMono = 36,
	SAFT48kHz8BitStereo = 37,
	SAFT48kHz16BitMono = 38,
	SAFT48kHz16BitStereo = 39,
	SAFTTrueSpeech_8kHz1BitMono = 40,
	SAFTCCITT_ALaw_8kHzMono = 41,
	SAFTCCITT_ALaw_8kHzStereo = 42,
	SAFTCCITT_ALaw_11kHzMono = 43,
	SAFTCCITT_ALaw_11kHzStereo = 44,
	SAFTCCITT_ALaw_22kHzMono = 45,
	SAFTCCITT_ALaw_22kHzStereo = 46,
	SAFTCCITT_ALaw_44kHzMono = 47,
	SAFTCCITT_ALaw_44kHzStereo = 48,
	SAFTCCITT_uLaw_8kHzMono = 49,
	SAFTCCITT_uLaw_8kHzStereo = 50,
	SAFTCCITT_uLaw_11kHzMono = 51,
	SAFTCCITT_uLaw_11kHzStereo = 52,
	SAFTCCITT_uLaw_22kHzMono = 53,
	SAFTCCITT_uLaw_22kHzStereo = 54,
	SAFTCCITT_uLaw_44kHzMono = 55,
	SAFTCCITT_uLaw_44kHzStereo = 56,
	SAFTADPCM_8kHzMono = 57,
	SAFTADPCM_8kHzStereo = 58,
	SAFTADPCM_11kHzMono = 59,
	SAFTADPCM_11kHzStereo = 60,
	SAFTADPCM_22kHzMono = 61,
	SAFTADPCM_22kHzStereo = 62,
	SAFTADPCM_44kHzMono = 63,
	SAFTADPCM_44kHzStereo = 64,
	SAFTGSM610_8kHzMono = 65,
	SAFTGSM610_11kHzMono = 66,
	SAFTGSM610_22kHzMono = 67,
	SAFTGSM610_44kHzMono = 68,
}


[AllowDuplicates]
public enum DISPID_SpeechAudioFormat : int32
{
	DISPID_SAFType = 1,
	DISPID_SAFGuid = 2,
	DISPID_SAFGetWaveFormatEx = 3,
	DISPID_SAFSetWaveFormatEx = 4,
}


[AllowDuplicates]
public enum DISPID_SpeechBaseStream : int32
{
	DISPID_SBSFormat = 1,
	DISPID_SBSRead = 2,
	DISPID_SBSWrite = 3,
	DISPID_SBSSeek = 4,
}


[AllowDuplicates]
public enum SpeechStreamSeekPositionType : uint32
{
	SSSPTRelativeToStart = 0,
	SSSPTRelativeToCurrentPosition = 1,
	SSSPTRelativeToEnd = 2,
}


[AllowDuplicates]
public enum DISPID_SpeechAudio : int32
{
	DISPID_SAStatus = 200,
	DISPID_SABufferInfo = 201,
	DISPID_SADefaultFormat = 202,
	DISPID_SAVolume = 203,
	DISPID_SABufferNotifySize = 204,
	DISPID_SAEventHandle = 205,
	DISPID_SASetState = 206,
}


[AllowDuplicates]
public enum SpeechAudioState : int32
{
	SASClosed = 0,
	SASStop = 1,
	SASPause = 2,
	SASRun = 3,
}


[AllowDuplicates]
public enum DISPID_SpeechMMSysAudio : int32
{
	DISPID_SMSADeviceId = 300,
	DISPID_SMSALineId = 301,
	DISPID_SMSAMMHandle = 302,
}


[AllowDuplicates]
public enum DISPID_SpeechFileStream : int32
{
	DISPID_SFSOpen = 100,
	DISPID_SFSClose = 101,
}


[AllowDuplicates]
public enum SpeechStreamFileMode : int32
{
	SSFMOpenForRead = 0,
	SSFMOpenReadWrite = 1,
	SSFMCreate = 2,
	SSFMCreateForWrite = 3,
}


[AllowDuplicates]
public enum DISPID_SpeechCustomStream : int32
{
	DISPID_SCSBaseStream = 100,
}


[AllowDuplicates]
public enum DISPID_SpeechMemoryStream : int32
{
	DISPID_SMSSetData = 100,
	DISPID_SMSGetData = 101,
}


[AllowDuplicates]
public enum DISPID_SpeechAudioStatus : int32
{
	DISPID_SASFreeBufferSpace = 1,
	DISPID_SASNonBlockingIO = 2,
	DISPID_SASState = 3,
	DISPID_SASCurrentSeekPosition = 4,
	DISPID_SASCurrentDevicePosition = 5,
}


[AllowDuplicates]
public enum DISPID_SpeechAudioBufferInfo : int32
{
	DISPID_SABIMinNotification = 1,
	DISPID_SABIBufferSize = 2,
	DISPID_SABIEventBias = 3,
}


[AllowDuplicates]
public enum DISPID_SpeechWaveFormatEx : int32
{
	DISPID_SWFEFormatTag = 1,
	DISPID_SWFEChannels = 2,
	DISPID_SWFESamplesPerSec = 3,
	DISPID_SWFEAvgBytesPerSec = 4,
	DISPID_SWFEBlockAlign = 5,
	DISPID_SWFEBitsPerSample = 6,
	DISPID_SWFEExtraData = 7,
}


[AllowDuplicates]
public enum DISPID_SpeechVoice : int32
{
	DISPID_SVStatus = 1,
	DISPID_SVVoice = 2,
	DISPID_SVAudioOutput = 3,
	DISPID_SVAudioOutputStream = 4,
	DISPID_SVRate = 5,
	DISPID_SVVolume = 6,
	DISPID_SVAllowAudioOuputFormatChangesOnNextSet = 7,
	DISPID_SVEventInterests = 8,
	DISPID_SVPriority = 9,
	DISPID_SVAlertBoundary = 10,
	DISPID_SVSyncronousSpeakTimeout = 11,
	DISPID_SVSpeak = 12,
	DISPID_SVSpeakStream = 13,
	DISPID_SVPause = 14,
	DISPID_SVResume = 15,
	DISPID_SVSkip = 16,
	DISPID_SVGetVoices = 17,
	DISPID_SVGetAudioOutputs = 18,
	DISPID_SVWaitUntilDone = 19,
	DISPID_SVSpeakCompleteEvent = 20,
	DISPID_SVIsUISupported = 21,
	DISPID_SVDisplayUI = 22,
}


[AllowDuplicates]
public enum SpeechVoicePriority : int32
{
	SVPNormal = 0,
	SVPAlert = 1,
	SVPOver = 2,
}


[AllowDuplicates]
public enum SpeechVoiceSpeakFlags : int32
{
	SVSFDefault = 0,
	SVSFlagsAsync = 1,
	SVSFPurgeBeforeSpeak = 2,
	SVSFIsFilename = 4,
	SVSFIsXML = 8,
	SVSFIsNotXML = 16,
	SVSFPersistXML = 32,
	SVSFNLPSpeakPunc = 64,
	SVSFParseSapi = 128,
	SVSFParseSsml = 256,
	SVSFParseAutodetect = 0,
	SVSFNLPMask = 64,
	SVSFParseMask = 384,
	SVSFVoiceMask = 511,
	SVSFUnusedFlags = -512,
}


[AllowDuplicates]
public enum SpeechVoiceEvents : int32
{
	SVEStartInputStream = 2,
	SVEEndInputStream = 4,
	SVEVoiceChange = 8,
	SVEBookmark = 16,
	SVEWordBoundary = 32,
	SVEPhoneme = 64,
	SVESentenceBoundary = 128,
	SVEViseme = 256,
	SVEAudioLevel = 512,
	SVEPrivate = 32768,
	SVEAllEvents = 33790,
}


[AllowDuplicates]
public enum DISPID_SpeechVoiceStatus : int32
{
	DISPID_SVSCurrentStreamNumber = 1,
	DISPID_SVSLastStreamNumberQueued = 2,
	DISPID_SVSLastResult = 3,
	DISPID_SVSRunningState = 4,
	DISPID_SVSInputWordPosition = 5,
	DISPID_SVSInputWordLength = 6,
	DISPID_SVSInputSentencePosition = 7,
	DISPID_SVSInputSentenceLength = 8,
	DISPID_SVSLastBookmark = 9,
	DISPID_SVSLastBookmarkId = 10,
	DISPID_SVSPhonemeId = 11,
	DISPID_SVSVisemeId = 12,
}


[AllowDuplicates]
public enum SpeechRunState : int32
{
	SRSEDone = 1,
	SRSEIsSpeaking = 2,
}


[AllowDuplicates]
public enum SpeechVisemeType : int32
{
	SVP_0 = 0,
	SVP_1 = 1,
	SVP_2 = 2,
	SVP_3 = 3,
	SVP_4 = 4,
	SVP_5 = 5,
	SVP_6 = 6,
	SVP_7 = 7,
	SVP_8 = 8,
	SVP_9 = 9,
	SVP_10 = 10,
	SVP_11 = 11,
	SVP_12 = 12,
	SVP_13 = 13,
	SVP_14 = 14,
	SVP_15 = 15,
	SVP_16 = 16,
	SVP_17 = 17,
	SVP_18 = 18,
	SVP_19 = 19,
	SVP_20 = 20,
	SVP_21 = 21,
}


[AllowDuplicates]
public enum SpeechVisemeFeature : int32
{
	SVF_None = 0,
	SVF_Stressed = 1,
	SVF_Emphasis = 2,
}


[AllowDuplicates]
public enum DISPID_SpeechVoiceEvent : int32
{
	DISPID_SVEStreamStart = 1,
	DISPID_SVEStreamEnd = 2,
	DISPID_SVEVoiceChange = 3,
	DISPID_SVEBookmark = 4,
	DISPID_SVEWord = 5,
	DISPID_SVEPhoneme = 6,
	DISPID_SVESentenceBoundary = 7,
	DISPID_SVEViseme = 8,
	DISPID_SVEAudioLevel = 9,
	DISPID_SVEEnginePrivate = 10,
}


[AllowDuplicates]
public enum DISPID_SpeechRecognizer : int32
{
	DISPID_SRRecognizer = 1,
	DISPID_SRAllowAudioInputFormatChangesOnNextSet = 2,
	DISPID_SRAudioInput = 3,
	DISPID_SRAudioInputStream = 4,
	DISPID_SRIsShared = 5,
	DISPID_SRState = 6,
	DISPID_SRStatus = 7,
	DISPID_SRProfile = 8,
	DISPID_SREmulateRecognition = 9,
	DISPID_SRCreateRecoContext = 10,
	DISPID_SRGetFormat = 11,
	DISPID_SRSetPropertyNumber = 12,
	DISPID_SRGetPropertyNumber = 13,
	DISPID_SRSetPropertyString = 14,
	DISPID_SRGetPropertyString = 15,
	DISPID_SRIsUISupported = 16,
	DISPID_SRDisplayUI = 17,
	DISPID_SRGetRecognizers = 18,
	DISPID_SVGetAudioInputs = 19,
	DISPID_SVGetProfiles = 20,
}


[AllowDuplicates]
public enum SpeechRecognizerState : int32
{
	SRSInactive = 0,
	SRSActive = 1,
	SRSActiveAlways = 2,
	SRSInactiveWithPurge = 3,
}


[AllowDuplicates]
public enum SpeechDisplayAttributes : int32
{
	SDA_No_Trailing_Space = 0,
	SDA_One_Trailing_Space = 2,
	SDA_Two_Trailing_Spaces = 4,
	SDA_Consume_Leading_Spaces = 8,
}


[AllowDuplicates]
public enum SpeechFormatType : int32
{
	SFTInput = 0,
	SFTSREngine = 1,
}


[AllowDuplicates]
public enum SpeechEmulationCompareFlags : int32
{
	SECFIgnoreCase = 1,
	SECFIgnoreKanaType = 65536,
	SECFIgnoreWidth = 131072,
	SECFNoSpecialChars = 536870912,
	SECFEmulateResult = 1073741824,
	SECFDefault = 196609,
}


[AllowDuplicates]
public enum DISPID_SpeechRecognizerStatus : int32
{
	DISPID_SRSAudioStatus = 1,
	DISPID_SRSCurrentStreamPosition = 2,
	DISPID_SRSCurrentStreamNumber = 3,
	DISPID_SRSNumberOfActiveRules = 4,
	DISPID_SRSClsidEngine = 5,
	DISPID_SRSSupportedLanguages = 6,
}


[AllowDuplicates]
public enum DISPID_SpeechRecoContext : int32
{
	DISPID_SRCRecognizer = 1,
	DISPID_SRCAudioInInterferenceStatus = 2,
	DISPID_SRCRequestedUIType = 3,
	DISPID_SRCVoice = 4,
	DISPID_SRAllowVoiceFormatMatchingOnNextSet = 5,
	DISPID_SRCVoicePurgeEvent = 6,
	DISPID_SRCEventInterests = 7,
	DISPID_SRCCmdMaxAlternates = 8,
	DISPID_SRCState = 9,
	DISPID_SRCRetainedAudio = 10,
	DISPID_SRCRetainedAudioFormat = 11,
	DISPID_SRCPause = 12,
	DISPID_SRCResume = 13,
	DISPID_SRCCreateGrammar = 14,
	DISPID_SRCCreateResultFromMemory = 15,
	DISPID_SRCBookmark = 16,
	DISPID_SRCSetAdaptationData = 17,
}


[AllowDuplicates]
public enum SpeechRetainedAudioOptions : int32
{
	SRAONone = 0,
	SRAORetainAudio = 1,
}


[AllowDuplicates]
public enum SpeechBookmarkOptions : int32
{
	SBONone = 0,
	SBOPause = 1,
}


[AllowDuplicates]
public enum SpeechInterference : int32
{
	SINone = 0,
	SINoise = 1,
	SINoSignal = 2,
	SITooLoud = 3,
	SITooQuiet = 4,
	SITooFast = 5,
	SITooSlow = 6,
}


[AllowDuplicates]
public enum SpeechRecoEvents : int32
{
	SREStreamEnd = 1,
	SRESoundStart = 2,
	SRESoundEnd = 4,
	SREPhraseStart = 8,
	SRERecognition = 16,
	SREHypothesis = 32,
	SREBookmark = 64,
	SREPropertyNumChange = 128,
	SREPropertyStringChange = 256,
	SREFalseRecognition = 512,
	SREInterference = 1024,
	SRERequestUI = 2048,
	SREStateChange = 4096,
	SREAdaptation = 8192,
	SREStreamStart = 16384,
	SRERecoOtherContext = 32768,
	SREAudioLevel = 65536,
	SREPrivate = 262144,
	SREAllEvents = 393215,
}


[AllowDuplicates]
public enum SpeechRecoContextState : int32
{
	SRCS_Disabled = 0,
	SRCS_Enabled = 1,
}


[AllowDuplicates]
public enum DISPIDSPRG : int32
{
	DISPID_SRGId = 1,
	DISPID_SRGRecoContext = 2,
	DISPID_SRGState = 3,
	DISPID_SRGRules = 4,
	DISPID_SRGReset = 5,
	DISPID_SRGCommit = 6,
	DISPID_SRGCmdLoadFromFile = 7,
	DISPID_SRGCmdLoadFromObject = 8,
	DISPID_SRGCmdLoadFromResource = 9,
	DISPID_SRGCmdLoadFromMemory = 10,
	DISPID_SRGCmdLoadFromProprietaryGrammar = 11,
	DISPID_SRGCmdSetRuleState = 12,
	DISPID_SRGCmdSetRuleIdState = 13,
	DISPID_SRGDictationLoad = 14,
	DISPID_SRGDictationUnload = 15,
	DISPID_SRGDictationSetState = 16,
	DISPID_SRGSetWordSequenceData = 17,
	DISPID_SRGSetTextSelection = 18,
	DISPID_SRGIsPronounceable = 19,
}


[AllowDuplicates]
public enum SpeechLoadOption : int32
{
	SLOStatic = 0,
	SLODynamic = 1,
}


[AllowDuplicates]
public enum SpeechWordPronounceable : int32
{
	SWPUnknownWordUnpronounceable = 0,
	SWPUnknownWordPronounceable = 1,
	SWPKnownWordPronounceable = 2,
}


[AllowDuplicates]
public enum SpeechGrammarState : int32
{
	SGSEnabled = 1,
	SGSDisabled = 0,
	SGSExclusive = 3,
}


[AllowDuplicates]
public enum SpeechRuleState : int32
{
	SGDSInactive = 0,
	SGDSActive = 1,
	SGDSActiveWithAutoPause = 3,
	SGDSActiveUserDelimited = 4,
}


[AllowDuplicates]
public enum SpeechRuleAttributes : int32
{
	SRATopLevel = 1,
	SRADefaultToActive = 2,
	SRAExport = 4,
	SRAImport = 8,
	SRAInterpreter = 16,
	SRADynamic = 32,
	SRARoot = 64,
}


[AllowDuplicates]
public enum SpeechGrammarWordType : int32
{
	SGDisplay = 0,
	SGLexical = 1,
	SGPronounciation = 2,
	SGLexicalNoSpecialChars = 3,
}


[AllowDuplicates]
public enum DISPID_SpeechRecoContextEvents : int32
{
	DISPID_SRCEStartStream = 1,
	DISPID_SRCEEndStream = 2,
	DISPID_SRCEBookmark = 3,
	DISPID_SRCESoundStart = 4,
	DISPID_SRCESoundEnd = 5,
	DISPID_SRCEPhraseStart = 6,
	DISPID_SRCERecognition = 7,
	DISPID_SRCEHypothesis = 8,
	DISPID_SRCEPropertyNumberChange = 9,
	DISPID_SRCEPropertyStringChange = 10,
	DISPID_SRCEFalseRecognition = 11,
	DISPID_SRCEInterference = 12,
	DISPID_SRCERequestUI = 13,
	DISPID_SRCERecognizerStateChange = 14,
	DISPID_SRCEAdaptation = 15,
	DISPID_SRCERecognitionForOtherContext = 16,
	DISPID_SRCEAudioLevel = 17,
	DISPID_SRCEEnginePrivate = 18,
}


[AllowDuplicates]
public enum SpeechRecognitionType : int32
{
	SRTStandard = 0,
	SRTAutopause = 1,
	SRTEmulated = 2,
	SRTSMLTimeout = 4,
	SRTExtendableParse = 8,
	SRTReSent = 16,
}


[AllowDuplicates]
public enum DISPID_SpeechGrammarRule : int32
{
	DISPID_SGRAttributes = 1,
	DISPID_SGRInitialState = 2,
	DISPID_SGRName = 3,
	DISPID_SGRId = 4,
	DISPID_SGRClear = 5,
	DISPID_SGRAddResource = 6,
	DISPID_SGRAddState = 7,
}


[AllowDuplicates]
public enum DISPID_SpeechGrammarRules : int32
{
	DISPID_SGRsCount = 1,
	DISPID_SGRsDynamic = 2,
	DISPID_SGRsAdd = 3,
	DISPID_SGRsCommit = 4,
	DISPID_SGRsCommitAndSave = 5,
	DISPID_SGRsFindRule = 6,
	DISPID_SGRsItem = 0,
	DISPID_SGRs_NewEnum = -4,
}


[AllowDuplicates]
public enum DISPID_SpeechGrammarRuleState : int32
{
	DISPID_SGRSRule = 1,
	DISPID_SGRSTransitions = 2,
	DISPID_SGRSAddWordTransition = 3,
	DISPID_SGRSAddRuleTransition = 4,
	DISPID_SGRSAddSpecialTransition = 5,
}


[AllowDuplicates]
public enum SpeechSpecialTransitionType : int32
{
	SSTTWildcard = 1,
	SSTTDictation = 2,
	SSTTTextBuffer = 3,
}


[AllowDuplicates]
public enum DISPID_SpeechGrammarRuleStateTransitions : int32
{
	DISPID_SGRSTsCount = 1,
	DISPID_SGRSTsItem = 0,
	DISPID_SGRSTs_NewEnum = -4,
}


[AllowDuplicates]
public enum DISPID_SpeechGrammarRuleStateTransition : int32
{
	DISPID_SGRSTType = 1,
	DISPID_SGRSTText = 2,
	DISPID_SGRSTRule = 3,
	DISPID_SGRSTWeight = 4,
	DISPID_SGRSTPropertyName = 5,
	DISPID_SGRSTPropertyId = 6,
	DISPID_SGRSTPropertyValue = 7,
	DISPID_SGRSTNextState = 8,
}


[AllowDuplicates]
public enum SpeechGrammarRuleStateTransitionType : int32
{
	SGRSTTEpsilon = 0,
	SGRSTTWord = 1,
	SGRSTTRule = 2,
	SGRSTTDictation = 3,
	SGRSTTWildcard = 4,
	SGRSTTTextBuffer = 5,
}


[AllowDuplicates]
public enum DISPIDSPTSI : int32
{
	DISPIDSPTSI_ActiveOffset = 1,
	DISPIDSPTSI_ActiveLength = 2,
	DISPIDSPTSI_SelectionOffset = 3,
	DISPIDSPTSI_SelectionLength = 4,
}


[AllowDuplicates]
public enum DISPID_SpeechRecoResult : int32
{
	DISPID_SRRRecoContext = 1,
	DISPID_SRRTimes = 2,
	DISPID_SRRAudioFormat = 3,
	DISPID_SRRPhraseInfo = 4,
	DISPID_SRRAlternates = 5,
	DISPID_SRRAudio = 6,
	DISPID_SRRSpeakAudio = 7,
	DISPID_SRRSaveToMemory = 8,
	DISPID_SRRDiscardResultInfo = 9,
}


[AllowDuplicates]
public enum SpeechDiscardType : int32
{
	SDTProperty = 1,
	SDTReplacement = 2,
	SDTRule = 4,
	SDTDisplayText = 8,
	SDTLexicalForm = 16,
	SDTPronunciation = 32,
	SDTAudio = 64,
	SDTAlternates = 128,
	SDTAll = 255,
}


[AllowDuplicates]
public enum DISPID_SpeechXMLRecoResult : int32
{
	DISPID_SRRGetXMLResult = 10,
	DISPID_SRRGetXMLErrorInfo = 11,
}


[AllowDuplicates]
public enum DISPID_SpeechRecoResult2 : int32
{
	DISPID_SRRSetTextFeedback = 12,
}


[AllowDuplicates]
public enum DISPID_SpeechPhraseBuilder : int32
{
	DISPID_SPPBRestorePhraseFromMemory = 1,
}


[AllowDuplicates]
public enum DISPID_SpeechRecoResultTimes : int32
{
	DISPID_SRRTStreamTime = 1,
	DISPID_SRRTLength = 2,
	DISPID_SRRTTickCount = 3,
	DISPID_SRRTOffsetFromStart = 4,
}


[AllowDuplicates]
public enum DISPID_SpeechPhraseAlternate : int32
{
	DISPID_SPARecoResult = 1,
	DISPID_SPAStartElementInResult = 2,
	DISPID_SPANumberOfElementsInResult = 3,
	DISPID_SPAPhraseInfo = 4,
	DISPID_SPACommit = 5,
}


[AllowDuplicates]
public enum DISPID_SpeechPhraseAlternates : int32
{
	DISPID_SPAsCount = 1,
	DISPID_SPAsItem = 0,
	DISPID_SPAs_NewEnum = -4,
}


[AllowDuplicates]
public enum DISPID_SpeechPhraseInfo : int32
{
	DISPID_SPILanguageId = 1,
	DISPID_SPIGrammarId = 2,
	DISPID_SPIStartTime = 3,
	DISPID_SPIAudioStreamPosition = 4,
	DISPID_SPIAudioSizeBytes = 5,
	DISPID_SPIRetainedSizeBytes = 6,
	DISPID_SPIAudioSizeTime = 7,
	DISPID_SPIRule = 8,
	DISPID_SPIProperties = 9,
	DISPID_SPIElements = 10,
	DISPID_SPIReplacements = 11,
	DISPID_SPIEngineId = 12,
	DISPID_SPIEnginePrivateData = 13,
	DISPID_SPISaveToMemory = 14,
	DISPID_SPIGetText = 15,
	DISPID_SPIGetDisplayAttributes = 16,
}


[AllowDuplicates]
public enum DISPID_SpeechPhraseElement : int32
{
	DISPID_SPEAudioTimeOffset = 1,
	DISPID_SPEAudioSizeTime = 2,
	DISPID_SPEAudioStreamOffset = 3,
	DISPID_SPEAudioSizeBytes = 4,
	DISPID_SPERetainedStreamOffset = 5,
	DISPID_SPERetainedSizeBytes = 6,
	DISPID_SPEDisplayText = 7,
	DISPID_SPELexicalForm = 8,
	DISPID_SPEPronunciation = 9,
	DISPID_SPEDisplayAttributes = 10,
	DISPID_SPERequiredConfidence = 11,
	DISPID_SPEActualConfidence = 12,
	DISPID_SPEEngineConfidence = 13,
}


[AllowDuplicates]
public enum SpeechEngineConfidence : int32
{
	SECLowConfidence = -1,
	SECNormalConfidence = 0,
	SECHighConfidence = 1,
}


[AllowDuplicates]
public enum DISPID_SpeechPhraseElements : int32
{
	DISPID_SPEsCount = 1,
	DISPID_SPEsItem = 0,
	DISPID_SPEs_NewEnum = -4,
}


[AllowDuplicates]
public enum DISPID_SpeechPhraseReplacement : int32
{
	DISPID_SPRDisplayAttributes = 1,
	DISPID_SPRText = 2,
	DISPID_SPRFirstElement = 3,
	DISPID_SPRNumberOfElements = 4,
}


[AllowDuplicates]
public enum DISPID_SpeechPhraseReplacements : int32
{
	DISPID_SPRsCount = 1,
	DISPID_SPRsItem = 0,
	DISPID_SPRs_NewEnum = -4,
}


[AllowDuplicates]
public enum DISPID_SpeechPhraseProperty : int32
{
	DISPID_SPPName = 1,
	DISPID_SPPId = 2,
	DISPID_SPPValue = 3,
	DISPID_SPPFirstElement = 4,
	DISPID_SPPNumberOfElements = 5,
	DISPID_SPPEngineConfidence = 6,
	DISPID_SPPConfidence = 7,
	DISPID_SPPParent = 8,
	DISPID_SPPChildren = 9,
}


[AllowDuplicates]
public enum DISPID_SpeechPhraseProperties : int32
{
	DISPID_SPPsCount = 1,
	DISPID_SPPsItem = 0,
	DISPID_SPPs_NewEnum = -4,
}


[AllowDuplicates]
public enum DISPID_SpeechPhraseRule : int32
{
	DISPID_SPRuleName = 1,
	DISPID_SPRuleId = 2,
	DISPID_SPRuleFirstElement = 3,
	DISPID_SPRuleNumberOfElements = 4,
	DISPID_SPRuleParent = 5,
	DISPID_SPRuleChildren = 6,
	DISPID_SPRuleConfidence = 7,
	DISPID_SPRuleEngineConfidence = 8,
}


[AllowDuplicates]
public enum DISPID_SpeechPhraseRules : int32
{
	DISPID_SPRulesCount = 1,
	DISPID_SPRulesItem = 0,
	DISPID_SPRules_NewEnum = -4,
}


[AllowDuplicates]
public enum DISPID_SpeechLexicon : int32
{
	DISPID_SLGenerationId = 1,
	DISPID_SLGetWords = 2,
	DISPID_SLAddPronunciation = 3,
	DISPID_SLAddPronunciationByPhoneIds = 4,
	DISPID_SLRemovePronunciation = 5,
	DISPID_SLRemovePronunciationByPhoneIds = 6,
	DISPID_SLGetPronunciations = 7,
	DISPID_SLGetGenerationChange = 8,
}


[AllowDuplicates]
public enum SpeechLexiconType : int32
{
	SLTUser = 1,
	SLTApp = 2,
}


[AllowDuplicates]
public enum SpeechPartOfSpeech : int32
{
	SPSNotOverriden = -1,
	SPSUnknown = 0,
	SPSNoun = 4096,
	SPSVerb = 8192,
	SPSModifier = 12288,
	SPSFunction = 16384,
	SPSInterjection = 20480,
	SPSLMA = 28672,
	SPSSuppressWord = 61440,
}


[AllowDuplicates]
public enum DISPID_SpeechLexiconWords : int32
{
	DISPID_SLWsCount = 1,
	DISPID_SLWsItem = 0,
	DISPID_SLWs_NewEnum = -4,
}


[AllowDuplicates]
public enum SpeechWordType : int32
{
	SWTAdded = 1,
	SWTDeleted = 2,
}


[AllowDuplicates]
public enum DISPID_SpeechLexiconWord : int32
{
	DISPID_SLWLangId = 1,
	DISPID_SLWType = 2,
	DISPID_SLWWord = 3,
	DISPID_SLWPronunciations = 4,
}


[AllowDuplicates]
public enum DISPID_SpeechLexiconProns : int32
{
	DISPID_SLPsCount = 1,
	DISPID_SLPsItem = 0,
	DISPID_SLPs_NewEnum = -4,
}


[AllowDuplicates]
public enum DISPID_SpeechLexiconPronunciation : int32
{
	DISPID_SLPType = 1,
	DISPID_SLPLangId = 2,
	DISPID_SLPPartOfSpeech = 3,
	DISPID_SLPPhoneIds = 4,
	DISPID_SLPSymbolic = 5,
}


[AllowDuplicates]
public enum DISPID_SpeechPhoneConverter : int32
{
	DISPID_SPCLangId = 1,
	DISPID_SPCPhoneToId = 2,
	DISPID_SPCIdToPhone = 3,
}

#endregion

#region Function Pointers
public function void SPNOTIFYCALLBACK(WPARAM wParam, LPARAM lParam);

#endregion

#region Structs
[CRepr]
public struct SPEVENT
{
	public int32 _bitfield;
	public uint32 ulStreamNum;
	public uint64 ullAudioStreamOffset;
	public WPARAM wParam;
	public LPARAM lParam;
}

[CRepr]
public struct SPSERIALIZEDEVENT
{
	public int32 _bitfield;
	public uint32 ulStreamNum;
	public uint64 ullAudioStreamOffset;
	public uint32 SerializedwParam;
	public int32 SerializedlParam;
}

[CRepr]
public struct SPSERIALIZEDEVENT64
{
	public int32 _bitfield;
	public uint32 ulStreamNum;
	public uint64 ullAudioStreamOffset;
	public uint64 SerializedwParam;
	public int64 SerializedlParam;
}

[CRepr]
public struct SPEVENTEX
{
	public int32 _bitfield;
	public uint32 ulStreamNum;
	public uint64 ullAudioStreamOffset;
	public WPARAM wParam;
	public LPARAM lParam;
	public uint64 ullAudioTimeOffset;
}

[CRepr]
public struct SPEVENTSOURCEINFO
{
	public uint64 ullEventInterest;
	public uint64 ullQueuedInterest;
	public uint32 ulCount;
}

[CRepr]
public struct SPAUDIOSTATUS
{
	public int32 cbFreeBuffSpace;
	public uint32 cbNonBlockingIO;
	public SPAUDIOSTATE State;
	public uint64 CurSeekPos;
	public uint64 CurDevicePos;
	public uint32 dwAudioLevel;
	public uint32 dwReserved2;
}

[CRepr]
public struct SPAUDIOBUFFERINFO
{
	public uint32 ulMsMinNotification;
	public uint32 ulMsBufferSize;
	public uint32 ulMsEventBias;
}

[CRepr]
public struct SPPHRASEELEMENT
{
	public uint32 ulAudioTimeOffset;
	public uint32 ulAudioSizeTime;
	public uint32 ulAudioStreamOffset;
	public uint32 ulAudioSizeBytes;
	public uint32 ulRetainedStreamOffset;
	public uint32 ulRetainedSizeBytes;
	public PWSTR pszDisplayText;
	public PWSTR pszLexicalForm;
	public uint16* pszPronunciation;
	public uint8 bDisplayAttributes;
	public int8 RequiredConfidence;
	public int8 ActualConfidence;
	public uint8 Reserved;
	public float SREngineConfidence;
}

[CRepr]
public struct SPPHRASERULE
{
	public PWSTR pszName;
	public uint32 ulId;
	public uint32 ulFirstElement;
	public uint32 ulCountOfElements;
	public SPPHRASERULE* pNextSibling;
	public SPPHRASERULE* pFirstChild;
	public float SREngineConfidence;
	public int8 Confidence;
}

[CRepr]
public struct SPPHRASEPROPERTY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 bType;
			public uint8 bReserved;
			public uint16 usArrayIndex;
		}
		public uint32 ulId;
		public using _Anonymous_e__Struct Anonymous;
	}
	public PWSTR pszName;
	public using _Anonymous_e__Union Anonymous;
	public PWSTR pszValue;
	public VARIANT vValue;
	public uint32 ulFirstElement;
	public uint32 ulCountOfElements;
	public SPPHRASEPROPERTY* pNextSibling;
	public SPPHRASEPROPERTY* pFirstChild;
	public float SREngineConfidence;
	public int8 Confidence;
}

[CRepr]
public struct SPPHRASEREPLACEMENT
{
	public uint8 bDisplayAttributes;
	public PWSTR pszReplacementText;
	public uint32 ulFirstElement;
	public uint32 ulCountOfElements;
}

[CRepr]
public struct SPSEMANTICERRORINFO
{
	public uint32 ulLineNumber;
	public PWSTR pszScriptLine;
	public PWSTR pszSource;
	public PWSTR pszDescription;
	public HRESULT hrResultCode;
}

[CRepr]
public struct SPPHRASE_50
{
	public uint32 cbSize;
	public uint16 LangID;
	public uint16 wHomophoneGroupId;
	public uint64 ullGrammarID;
	public uint64 ftStartTime;
	public uint64 ullAudioStreamPosition;
	public uint32 ulAudioSizeBytes;
	public uint32 ulRetainedSizeBytes;
	public uint32 ulAudioSizeTime;
	public SPPHRASERULE Rule;
	public SPPHRASEPROPERTY* pProperties;
	public SPPHRASEELEMENT* pElements;
	public uint32 cReplacements;
	public SPPHRASEREPLACEMENT* pReplacements;
	public Guid SREngineID;
	public uint32 ulSREnginePrivateDataSize;
	public uint8* pSREnginePrivateData;
}

[CRepr]
public struct SPPHRASE
{
	public SPPHRASE_50 Base;
	public PWSTR pSML;
	public SPSEMANTICERRORINFO* pSemanticErrorInfo;
}

[CRepr]
public struct SPSERIALIZEDPHRASE
{
	public uint32 ulSerializedSize;
}

[CRepr]
public struct SPRULE
{
	public PWSTR pszRuleName;
	public uint32 ulRuleId;
	public uint32 dwAttributes;
}

[CRepr]
public struct SPBINARYGRAMMAR
{
	public uint32 ulTotalSerializedSize;
}

[CRepr]
public struct SPSTATEHANDLE__
{
	public int32 unused;
}

[CRepr]
public struct SPWORDPRONUNCIATION
{
	public SPWORDPRONUNCIATION* pNextWordPronunciation;
	public SPLEXICONTYPE eLexiconType;
	public uint16 LangID;
	public uint16 wPronunciationFlags;
	public SPPARTOFSPEECH ePartOfSpeech;
	public uint16* szPronunciation mut => &szPronunciation_impl;
	private uint16[ANYSIZE_ARRAY] szPronunciation_impl;
}

[CRepr]
public struct SPWORDPRONUNCIATIONLIST
{
	public uint32 ulSize;
	public uint8* pvBuffer;
	public SPWORDPRONUNCIATION* pFirstWordPronunciation;
}

[CRepr]
public struct SPWORD
{
	public SPWORD* pNextWord;
	public uint16 LangID;
	public uint16 wReserved;
	public SPWORDTYPE eWordType;
	public PWSTR pszWord;
	public SPWORDPRONUNCIATION* pFirstWordPronunciation;
}

[CRepr]
public struct SPWORDLIST
{
	public uint32 ulSize;
	public uint8* pvBuffer;
	public SPWORD* pFirstWord;
}

[CRepr]
public struct SPSHORTCUTPAIR
{
	public SPSHORTCUTPAIR* pNextSHORTCUTPAIR;
	public uint16 LangID;
	public SPSHORTCUTTYPE shType;
	public PWSTR pszDisplay;
	public PWSTR pszSpoken;
}

[CRepr]
public struct SPSHORTCUTPAIRLIST
{
	public uint32 ulSize;
	public uint8* pvBuffer;
	public SPSHORTCUTPAIR* pFirstShortcutPair;
}

[CRepr]
public struct SPVPITCH
{
	public int32 MiddleAdj;
	public int32 RangeAdj;
}

[CRepr]
public struct SPVCONTEXT
{
	public PWSTR pCategory;
	public PWSTR pBefore;
	public PWSTR pAfter;
}

[CRepr]
public struct SPVSTATE
{
	public SPVACTIONS eAction;
	public uint16 LangID;
	public uint16 wReserved;
	public int32 EmphAdj;
	public int32 RateAdj;
	public uint32 Volume;
	public SPVPITCH PitchAdj;
	public uint32 SilenceMSecs;
	public uint16* pPhoneIds;
	public SPPARTOFSPEECH ePartOfSpeech;
	public SPVCONTEXT Context;
}

[CRepr]
public struct SPVOICESTATUS
{
	public uint32 ulCurrentStream;
	public uint32 ulLastStreamQueued;
	public HRESULT hrLastResult;
	public uint32 dwRunningState;
	public uint32 ulInputWordPos;
	public uint32 ulInputWordLen;
	public uint32 ulInputSentPos;
	public uint32 ulInputSentLen;
	public int32 lBookmarkId;
	public uint16 PhonemeId;
	public SPVISEMES VisemeId;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
}

[CRepr]
public struct SPRECORESULTTIMES
{
	public FILETIME ftStreamTime;
	public uint64 ullLength;
	public uint32 dwTickCount;
	public uint64 ullStart;
}

[CRepr]
public struct SPSERIALIZEDRESULT
{
	public uint32 ulSerializedSize;
}

[CRepr]
public struct SPTEXTSELECTIONINFO
{
	public uint32 ulStartActiveOffset;
	public uint32 cchActiveChars;
	public uint32 ulStartSelection;
	public uint32 cchSelection;
}

[CRepr]
public struct SPPROPERTYINFO
{
	public PWSTR pszName;
	public uint32 ulId;
	public PWSTR pszValue;
	public VARIANT vValue;
}

[CRepr]
public struct SPRECOCONTEXTSTATUS
{
	public SPINTERFERENCE eInterference;
	public char16[255] szRequestTypeOfUI;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
}

[CRepr]
public struct SPRECOGNIZERSTATUS
{
	public SPAUDIOSTATUS AudioStatus;
	public uint64 ullRecognitionStreamPos;
	public uint32 ulStreamNumber;
	public uint32 ulNumActive;
	public Guid clsidEngine;
	public uint32 cLangIDs;
	public uint16[20] aLangID;
	public uint64 ullRecognitionStreamTime;
}

[CRepr]
public struct SPNORMALIZATIONLIST
{
	public uint32 ulSize;
	public uint16** ppszzNormalizedList;
}

[CRepr]
public struct SPDISPLAYTOKEN
{
	public PWSTR pszLexical;
	public PWSTR pszDisplay;
	public uint8 bDisplayAttributes;
}

[CRepr]
public struct SPDISPLAYPHRASE
{
	public uint32 ulNumTokens;
	public SPDISPLAYTOKEN* pTokens;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_SpNotifyTranslator = .(0xe2ae5372, 0x5d40, 0x11d2, 0x96, 0x0e, 0x00, 0xc0, 0x4f, 0x8e, 0xe6, 0x28);


	public const Guid CLSID_SpObjectTokenCategory = .(0xa910187f, 0x0c7a, 0x45ac, 0x92, 0xcc, 0x59, 0xed, 0xaf, 0xb7, 0x7b, 0x53);


	public const Guid CLSID_SpObjectToken = .(0xef411752, 0x3736, 0x4cb4, 0x9c, 0x8c, 0x8e, 0xf4, 0xcc, 0xb5, 0x8e, 0xfe);


	public const Guid CLSID_SpResourceManager = .(0x96749373, 0x3391, 0x11d2, 0x9e, 0xe3, 0x00, 0xc0, 0x4f, 0x79, 0x73, 0x96);


	public const Guid CLSID_SpStreamFormatConverter = .(0x7013943a, 0xe2ec, 0x11d2, 0xa0, 0x86, 0x00, 0xc0, 0x4f, 0x8e, 0xf9, 0xb5);


	public const Guid CLSID_SpMMAudioEnum = .(0xab1890a0, 0xe91f, 0x11d2, 0xbb, 0x91, 0x00, 0xc0, 0x4f, 0x8e, 0xe6, 0xc0);


	public const Guid CLSID_SpMMAudioIn = .(0xcf3d2e50, 0x53f2, 0x11d2, 0x96, 0x0c, 0x00, 0xc0, 0x4f, 0x8e, 0xe6, 0x28);


	public const Guid CLSID_SpMMAudioOut = .(0xa8c680eb, 0x3d32, 0x11d2, 0x9e, 0xe7, 0x00, 0xc0, 0x4f, 0x79, 0x73, 0x96);


	public const Guid CLSID_SpStream = .(0x715d9c59, 0x4442, 0x11d2, 0x96, 0x05, 0x00, 0xc0, 0x4f, 0x8e, 0xe6, 0x28);


	public const Guid CLSID_SpVoice = .(0x96749377, 0x3391, 0x11d2, 0x9e, 0xe3, 0x00, 0xc0, 0x4f, 0x79, 0x73, 0x96);


	public const Guid CLSID_SpSharedRecoContext = .(0x47206204, 0x5eca, 0x11d2, 0x96, 0x0f, 0x00, 0xc0, 0x4f, 0x8e, 0xe6, 0x28);


	public const Guid CLSID_SpInprocRecognizer = .(0x41b89b6b, 0x9399, 0x11d2, 0x96, 0x23, 0x00, 0xc0, 0x4f, 0x8e, 0xe6, 0x28);


	public const Guid CLSID_SpSharedRecognizer = .(0x3bee4890, 0x4fe9, 0x4a37, 0x8c, 0x1e, 0x5e, 0x7e, 0x12, 0x79, 0x1c, 0x1f);


	public const Guid CLSID_SpLexicon = .(0x0655e396, 0x25d0, 0x11d3, 0x9c, 0x26, 0x00, 0xc0, 0x4f, 0x8e, 0xf8, 0x7c);


	public const Guid CLSID_SpUnCompressedLexicon = .(0xc9e37c15, 0xdf92, 0x4727, 0x85, 0xd6, 0x72, 0xe5, 0xee, 0xb6, 0x99, 0x5a);


	public const Guid CLSID_SpCompressedLexicon = .(0x90903716, 0x2f42, 0x11d3, 0x9c, 0x26, 0x00, 0xc0, 0x4f, 0x8e, 0xf8, 0x7c);


	public const Guid CLSID_SpShortcut = .(0x0d722f1a, 0x9fcf, 0x4e62, 0x96, 0xd8, 0x6d, 0xf8, 0xf0, 0x1a, 0x26, 0xaa);


	public const Guid CLSID_SpPhoneConverter = .(0x9185f743, 0x1143, 0x4c28, 0x86, 0xb5, 0xbf, 0xf1, 0x4f, 0x20, 0xe5, 0xc8);


	public const Guid CLSID_SpPhoneticAlphabetConverter = .(0x4f414126, 0xdfe3, 0x4629, 0x99, 0xee, 0x79, 0x79, 0x78, 0x31, 0x7e, 0xad);


	public const Guid CLSID_SpNullPhoneConverter = .(0x455f24e9, 0x7396, 0x4a16, 0x97, 0x15, 0x7c, 0x0f, 0xdb, 0xe3, 0xef, 0xe3);


	public const Guid CLSID_SpTextSelectionInformation = .(0x0f92030a, 0xcbfd, 0x4ab8, 0xa1, 0x64, 0xff, 0x59, 0x85, 0x54, 0x7f, 0xf6);


	public const Guid CLSID_SpPhraseInfoBuilder = .(0xc23fc28d, 0xc55f, 0x4720, 0x8b, 0x32, 0x91, 0xf7, 0x3c, 0x2b, 0xd5, 0xd1);


	public const Guid CLSID_SpAudioFormat = .(0x9ef96870, 0xe160, 0x4792, 0x82, 0x0d, 0x48, 0xcf, 0x06, 0x49, 0xe4, 0xec);


	public const Guid CLSID_SpWaveFormatEx = .(0xc79a574c, 0x63be, 0x44b9, 0x80, 0x1f, 0x28, 0x3f, 0x87, 0xf8, 0x98, 0xbe);


	public const Guid CLSID_SpInProcRecoContext = .(0x73ad6842, 0xace0, 0x45e8, 0xa4, 0xdd, 0x87, 0x95, 0x88, 0x1a, 0x2c, 0x2a);


	public const Guid CLSID_SpCustomStream = .(0x8dbef13f, 0x1948, 0x4aa8, 0x8c, 0xf0, 0x04, 0x8e, 0xeb, 0xed, 0x95, 0xd8);


	public const Guid CLSID_SpFileStream = .(0x947812b3, 0x2ae1, 0x4644, 0xba, 0x86, 0x9e, 0x90, 0xde, 0xd7, 0xec, 0x91);


	public const Guid CLSID_SpMemoryStream = .(0x5fb7ef7d, 0xdff4, 0x468a, 0xb6, 0xb7, 0x2f, 0xcb, 0xd1, 0x88, 0xf9, 0x94);


}
#endregion

#region COM Types
[CRepr]struct ISpNotifyCallback
{
	public VTable* VT { get => (.)mVT; }

	protected VTable* mVT;

	[CRepr]public struct VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WPARAM wParam, LPARAM lParam) NotifyCallback;
	}


	public HRESULT NotifyCallback(WPARAM wParam, LPARAM lParam) mut => VT.[Friend]NotifyCallback(&this, wParam, lParam);
}

[CRepr]struct ISpNotifySource : IUnknown
{
	public new const Guid IID = .(0x5eff4aef, 0x8487, 0x11d2, 0x96, 0x1c, 0x00, 0xc0, 0x4f, 0x8e, 0xe6, 0x28);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpNotifySink* pNotifySink) SetNotifySink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWnd, uint32 Msg, WPARAM wParam, LPARAM lParam) SetNotifyWindowMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPNOTIFYCALLBACK* pfnCallback, WPARAM wParam, LPARAM lParam) SetNotifyCallbackFunction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpNotifyCallback* pSpCallback, WPARAM wParam, LPARAM lParam) SetNotifyCallbackInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetNotifyWin32Event;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMilliseconds) WaitForNotifyEvent;
		protected new function [CallingConvention(.Stdcall)] HANDLE(SelfOuter* self) GetNotifyEventHandle;
	}


	public HRESULT SetNotifySink(ISpNotifySink* pNotifySink) mut => VT.[Friend]SetNotifySink(&this, pNotifySink);

	public HRESULT SetNotifyWindowMessage(HWND hWnd, uint32 Msg, WPARAM wParam, LPARAM lParam) mut => VT.[Friend]SetNotifyWindowMessage(&this, hWnd, Msg, wParam, lParam);

	public HRESULT SetNotifyCallbackFunction(SPNOTIFYCALLBACK* pfnCallback, WPARAM wParam, LPARAM lParam) mut => VT.[Friend]SetNotifyCallbackFunction(&this, pfnCallback, wParam, lParam);

	public HRESULT SetNotifyCallbackInterface(ISpNotifyCallback* pSpCallback, WPARAM wParam, LPARAM lParam) mut => VT.[Friend]SetNotifyCallbackInterface(&this, pSpCallback, wParam, lParam);

	public HRESULT SetNotifyWin32Event() mut => VT.[Friend]SetNotifyWin32Event(&this);

	public HRESULT WaitForNotifyEvent(uint32 dwMilliseconds) mut => VT.[Friend]WaitForNotifyEvent(&this, dwMilliseconds);

	public HANDLE GetNotifyEventHandle() mut => VT.[Friend]GetNotifyEventHandle(&this);
}

[CRepr]struct ISpNotifySink : IUnknown
{
	public new const Guid IID = .(0x259684dc, 0x37c3, 0x11d2, 0x96, 0x03, 0x00, 0xc0, 0x4f, 0x8e, 0xe6, 0x28);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Notify;
	}


	public HRESULT Notify() mut => VT.[Friend]Notify(&this);
}

[CRepr]struct ISpNotifyTranslator : ISpNotifySink
{
	public new const Guid IID = .(0xaca16614, 0x5d3d, 0x11d2, 0x96, 0x0e, 0x00, 0xc0, 0x4f, 0x8e, 0xe6, 0x28);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpNotifySink.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWnd, uint32 Msg, WPARAM wParam, LPARAM lParam) InitWindowMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPNOTIFYCALLBACK* pfnCallback, WPARAM wParam, LPARAM lParam) InitCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpNotifyCallback* pSpCallback, WPARAM wParam, LPARAM lParam) InitSpNotifyCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hEvent, BOOL fCloseHandleOnRelease) InitWin32Event;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMilliseconds) Wait;
		protected new function [CallingConvention(.Stdcall)] HANDLE(SelfOuter* self) GetEventHandle;
	}


	public HRESULT InitWindowMessage(HWND hWnd, uint32 Msg, WPARAM wParam, LPARAM lParam) mut => VT.[Friend]InitWindowMessage(&this, hWnd, Msg, wParam, lParam);

	public HRESULT InitCallback(SPNOTIFYCALLBACK* pfnCallback, WPARAM wParam, LPARAM lParam) mut => VT.[Friend]InitCallback(&this, pfnCallback, wParam, lParam);

	public HRESULT InitSpNotifyCallback(ISpNotifyCallback* pSpCallback, WPARAM wParam, LPARAM lParam) mut => VT.[Friend]InitSpNotifyCallback(&this, pSpCallback, wParam, lParam);

	public HRESULT InitWin32Event(HANDLE hEvent, BOOL fCloseHandleOnRelease) mut => VT.[Friend]InitWin32Event(&this, hEvent, fCloseHandleOnRelease);

	public HRESULT Wait(uint32 dwMilliseconds) mut => VT.[Friend]Wait(&this, dwMilliseconds);

	public HANDLE GetEventHandle() mut => VT.[Friend]GetEventHandle(&this);
}

[CRepr]struct ISpDataKey : IUnknown
{
	public new const Guid IID = .(0x14056581, 0xe16c, 0x11d2, 0xbb, 0x90, 0x00, 0xc0, 0x4f, 0x8e, 0xe6, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszValueName, uint32 cbData, uint8* pData) SetData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszValueName, uint32* pcbData, uint8* pData) GetData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszValueName, PWSTR pszValue) SetStringValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszValueName, PWSTR* ppszValue) GetStringValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszValueName, uint32 dwValue) SetDWORD;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszValueName, uint32* pdwValue) GetDWORD;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSubKeyName, ISpDataKey** ppSubKey) OpenKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSubKey, ISpDataKey** ppSubKey) CreateKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSubKey) DeleteKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszValueName) DeleteValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Index, PWSTR* ppszSubKeyName) EnumKeys;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Index, PWSTR* ppszValueName) EnumValues;
	}


	public HRESULT SetData(PWSTR pszValueName, uint32 cbData, uint8* pData) mut => VT.[Friend]SetData(&this, pszValueName, cbData, pData);

	public HRESULT GetData(PWSTR pszValueName, uint32* pcbData, uint8* pData) mut => VT.[Friend]GetData(&this, pszValueName, pcbData, pData);

	public HRESULT SetStringValue(PWSTR pszValueName, PWSTR pszValue) mut => VT.[Friend]SetStringValue(&this, pszValueName, pszValue);

	public HRESULT GetStringValue(PWSTR pszValueName, PWSTR* ppszValue) mut => VT.[Friend]GetStringValue(&this, pszValueName, ppszValue);

	public HRESULT SetDWORD(PWSTR pszValueName, uint32 dwValue) mut => VT.[Friend]SetDWORD(&this, pszValueName, dwValue);

	public HRESULT GetDWORD(PWSTR pszValueName, uint32* pdwValue) mut => VT.[Friend]GetDWORD(&this, pszValueName, pdwValue);

	public HRESULT OpenKey(PWSTR pszSubKeyName, ISpDataKey** ppSubKey) mut => VT.[Friend]OpenKey(&this, pszSubKeyName, ppSubKey);

	public HRESULT CreateKey(PWSTR pszSubKey, ISpDataKey** ppSubKey) mut => VT.[Friend]CreateKey(&this, pszSubKey, ppSubKey);

	public HRESULT DeleteKey(PWSTR pszSubKey) mut => VT.[Friend]DeleteKey(&this, pszSubKey);

	public HRESULT DeleteValue(PWSTR pszValueName) mut => VT.[Friend]DeleteValue(&this, pszValueName);

	public HRESULT EnumKeys(uint32 Index, PWSTR* ppszSubKeyName) mut => VT.[Friend]EnumKeys(&this, Index, ppszSubKeyName);

	public HRESULT EnumValues(uint32 Index, PWSTR* ppszValueName) mut => VT.[Friend]EnumValues(&this, Index, ppszValueName);
}

[CRepr]struct ISpRegDataKey : ISpDataKey
{
	public new const Guid IID = .(0x92a66e2b, 0xc830, 0x4149, 0x83, 0xdf, 0x6f, 0xc2, 0xba, 0x1e, 0x7a, 0x5b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpDataKey.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HKEY hkey, BOOL fReadOnly) SetKey;
	}


	public HRESULT SetKey(HKEY hkey, BOOL fReadOnly) mut => VT.[Friend]SetKey(&this, hkey, fReadOnly);
}

[CRepr]struct ISpObjectTokenCategory : ISpDataKey
{
	public new const Guid IID = .(0x2d3d3845, 0x39af, 0x4850, 0xbb, 0xf9, 0x40, 0xb4, 0x97, 0x80, 0x01, 0x1d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpDataKey.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszCategoryId, BOOL fCreateIfNotExist) SetId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszCoMemCategoryId) GetId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPDATAKEYLOCATION spdkl, ISpDataKey** ppDataKey) GetDataKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pzsReqAttribs, PWSTR pszOptAttribs, IEnumSpObjectTokens** ppEnum) EnumTokens;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTokenId) SetDefaultTokenId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszCoMemTokenId) GetDefaultTokenId;
	}


	public HRESULT SetId(PWSTR pszCategoryId, BOOL fCreateIfNotExist) mut => VT.[Friend]SetId(&this, pszCategoryId, fCreateIfNotExist);

	public HRESULT GetId(PWSTR* ppszCoMemCategoryId) mut => VT.[Friend]GetId(&this, ppszCoMemCategoryId);

	public HRESULT GetDataKey(SPDATAKEYLOCATION spdkl, ISpDataKey** ppDataKey) mut => VT.[Friend]GetDataKey(&this, spdkl, ppDataKey);

	public HRESULT EnumTokens(PWSTR pzsReqAttribs, PWSTR pszOptAttribs, IEnumSpObjectTokens** ppEnum) mut => VT.[Friend]EnumTokens(&this, pzsReqAttribs, pszOptAttribs, ppEnum);

	public HRESULT SetDefaultTokenId(PWSTR pszTokenId) mut => VT.[Friend]SetDefaultTokenId(&this, pszTokenId);

	public HRESULT GetDefaultTokenId(PWSTR* ppszCoMemTokenId) mut => VT.[Friend]GetDefaultTokenId(&this, ppszCoMemTokenId);
}

[CRepr]struct ISpObjectToken : ISpDataKey
{
	public new const Guid IID = .(0x14056589, 0xe16c, 0x11d2, 0xbb, 0x90, 0x00, 0xc0, 0x4f, 0x8e, 0xe6, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpDataKey.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszCategoryId, PWSTR pszTokenId, BOOL fCreateIfNotExist) SetId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszCoMemTokenId) GetId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpObjectTokenCategory** ppTokenCategory) GetCategory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, uint32 dwClsContext, in Guid riid, void** ppvObject) CreateInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsidCaller, PWSTR pszValueName, PWSTR pszFileNameSpecifier, uint32 nFolder, PWSTR* ppszFilePath) GetStorageFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsidCaller, PWSTR pszKeyName, BOOL fDeleteFile) RemoveStorageFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pclsidCaller) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTypeOfUI, void* pvExtraData, uint32 cbExtraData, IUnknown* punkObject, BOOL* pfSupported) IsUISupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, PWSTR pszTitle, PWSTR pszTypeOfUI, void* pvExtraData, uint32 cbExtraData, IUnknown* punkObject) DisplayUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAttributes, BOOL* pfMatches) MatchesAttributes;
	}


	public HRESULT SetId(PWSTR pszCategoryId, PWSTR pszTokenId, BOOL fCreateIfNotExist) mut => VT.[Friend]SetId(&this, pszCategoryId, pszTokenId, fCreateIfNotExist);

	public HRESULT GetId(PWSTR* ppszCoMemTokenId) mut => VT.[Friend]GetId(&this, ppszCoMemTokenId);

	public HRESULT GetCategory(ISpObjectTokenCategory** ppTokenCategory) mut => VT.[Friend]GetCategory(&this, ppTokenCategory);

	public HRESULT CreateInstance(IUnknown* pUnkOuter, uint32 dwClsContext, in Guid riid, void** ppvObject) mut => VT.[Friend]CreateInstance(&this, pUnkOuter, dwClsContext, riid, ppvObject);

	public HRESULT GetStorageFileName(in Guid clsidCaller, PWSTR pszValueName, PWSTR pszFileNameSpecifier, uint32 nFolder, PWSTR* ppszFilePath) mut => VT.[Friend]GetStorageFileName(&this, clsidCaller, pszValueName, pszFileNameSpecifier, nFolder, ppszFilePath);

	public HRESULT RemoveStorageFileName(in Guid clsidCaller, PWSTR pszKeyName, BOOL fDeleteFile) mut => VT.[Friend]RemoveStorageFileName(&this, clsidCaller, pszKeyName, fDeleteFile);

	public HRESULT Remove(Guid* pclsidCaller) mut => VT.[Friend]Remove(&this, pclsidCaller);

	public HRESULT IsUISupported(PWSTR pszTypeOfUI, void* pvExtraData, uint32 cbExtraData, IUnknown* punkObject, BOOL* pfSupported) mut => VT.[Friend]IsUISupported(&this, pszTypeOfUI, pvExtraData, cbExtraData, punkObject, pfSupported);

	public HRESULT DisplayUI(HWND hwndParent, PWSTR pszTitle, PWSTR pszTypeOfUI, void* pvExtraData, uint32 cbExtraData, IUnknown* punkObject) mut => VT.[Friend]DisplayUI(&this, hwndParent, pszTitle, pszTypeOfUI, pvExtraData, cbExtraData, punkObject);

	public HRESULT MatchesAttributes(PWSTR pszAttributes, BOOL* pfMatches) mut => VT.[Friend]MatchesAttributes(&this, pszAttributes, pfMatches);
}

[CRepr]struct ISpObjectTokenInit : ISpObjectToken
{
	public new const Guid IID = .(0xb8aab0cf, 0x346f, 0x49d8, 0x94, 0x99, 0xc8, 0xb0, 0x3f, 0x16, 0x1d, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpObjectToken.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszCategoryId, PWSTR pszTokenId, ISpDataKey* pDataKey) InitFromDataKey;
	}


	public HRESULT InitFromDataKey(PWSTR pszCategoryId, PWSTR pszTokenId, ISpDataKey* pDataKey) mut => VT.[Friend]InitFromDataKey(&this, pszCategoryId, pszTokenId, pDataKey);
}

[CRepr]struct IEnumSpObjectTokens : IUnknown
{
	public new const Guid IID = .(0x06b64f9e, 0x7fda, 0x11d2, 0xb4, 0xf2, 0x00, 0xc0, 0x4f, 0x79, 0x73, 0x96);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, ISpObjectToken** pelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSpObjectTokens** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Index, ISpObjectToken** ppToken) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCount) GetCount;
	}


	public HRESULT Next(uint32 celt, ISpObjectToken** pelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, pelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumSpObjectTokens** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Item(uint32 Index, ISpObjectToken** ppToken) mut => VT.[Friend]Item(&this, Index, ppToken);

	public HRESULT GetCount(uint32* pCount) mut => VT.[Friend]GetCount(&this, pCount);
}

[CRepr]struct ISpObjectWithToken : IUnknown
{
	public new const Guid IID = .(0x5b559f40, 0xe952, 0x11d2, 0xbb, 0x91, 0x00, 0xc0, 0x4f, 0x8e, 0xe6, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpObjectToken* pToken) SetObjectToken;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpObjectToken** ppToken) GetObjectToken;
	}


	public HRESULT SetObjectToken(ISpObjectToken* pToken) mut => VT.[Friend]SetObjectToken(&this, pToken);

	public HRESULT GetObjectToken(ISpObjectToken** ppToken) mut => VT.[Friend]GetObjectToken(&this, ppToken);
}

[CRepr]struct ISpResourceManager : IServiceProvider
{
	public new const Guid IID = .(0x93384e18, 0x5014, 0x43d5, 0xad, 0xbb, 0xa7, 0x8e, 0x05, 0x59, 0x26, 0xbd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IServiceProvider.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidServiceId, IUnknown* pUnkObject) SetObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidServiceId, in Guid ObjectCLSID, in Guid ObjectIID, BOOL fReleaseWhenLastExternalRefReleased, void** ppObject) GetObject;
	}


	public HRESULT SetObject(in Guid guidServiceId, IUnknown* pUnkObject) mut => VT.[Friend]SetObject(&this, guidServiceId, pUnkObject);

	public HRESULT GetObject(in Guid guidServiceId, in Guid ObjectCLSID, in Guid ObjectIID, BOOL fReleaseWhenLastExternalRefReleased, void** ppObject) mut => VT.[Friend]GetObject(&this, guidServiceId, ObjectCLSID, ObjectIID, fReleaseWhenLastExternalRefReleased, ppObject);
}

[CRepr]struct ISpEventSource : ISpNotifySource
{
	public new const Guid IID = .(0xbe7a9cce, 0x5f9e, 0x11d2, 0x96, 0x0f, 0x00, 0xc0, 0x4f, 0x8e, 0xe6, 0x28);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpNotifySource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 ullEventInterest, uint64 ullQueuedInterest) SetInterest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, SPEVENT* pEventArray, uint32* pulFetched) GetEvents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPEVENTSOURCEINFO* pInfo) GetInfo;
	}


	public HRESULT SetInterest(uint64 ullEventInterest, uint64 ullQueuedInterest) mut => VT.[Friend]SetInterest(&this, ullEventInterest, ullQueuedInterest);

	public HRESULT GetEvents(uint32 ulCount, SPEVENT* pEventArray, uint32* pulFetched) mut => VT.[Friend]GetEvents(&this, ulCount, pEventArray, pulFetched);

	public HRESULT GetInfo(SPEVENTSOURCEINFO* pInfo) mut => VT.[Friend]GetInfo(&this, pInfo);
}

[CRepr]struct ISpEventSource2 : ISpEventSource
{
	public new const Guid IID = .(0x2373a435, 0x6a4b, 0x429e, 0xa6, 0xac, 0xd4, 0x23, 0x1a, 0x61, 0x97, 0x5b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpEventSource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, SPEVENTEX* pEventArray, uint32* pulFetched) GetEventsEx;
	}


	public HRESULT GetEventsEx(uint32 ulCount, SPEVENTEX* pEventArray, uint32* pulFetched) mut => VT.[Friend]GetEventsEx(&this, ulCount, pEventArray, pulFetched);
}

[CRepr]struct ISpEventSink : IUnknown
{
	public new const Guid IID = .(0xbe7a9cc9, 0x5f9e, 0x11d2, 0x96, 0x0f, 0x00, 0xc0, 0x4f, 0x8e, 0xe6, 0x28);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPEVENT* pEventArray, uint32 ulCount) AddEvents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pullEventInterest) GetEventInterest;
	}


	public HRESULT AddEvents(SPEVENT* pEventArray, uint32 ulCount) mut => VT.[Friend]AddEvents(&this, pEventArray, ulCount);

	public HRESULT GetEventInterest(uint64* pullEventInterest) mut => VT.[Friend]GetEventInterest(&this, pullEventInterest);
}

[CRepr]struct ISpStreamFormat : IStream
{
	public new const Guid IID = .(0xbed530be, 0x2606, 0x4f4d, 0xa1, 0xc0, 0x54, 0xc5, 0xcd, 0xa5, 0x56, 0x6f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IStream.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidFormatId, WAVEFORMATEX** ppCoMemWaveFormatEx) GetFormat;
	}


	public HRESULT GetFormat(Guid* pguidFormatId, WAVEFORMATEX** ppCoMemWaveFormatEx) mut => VT.[Friend]GetFormat(&this, pguidFormatId, ppCoMemWaveFormatEx);
}

[CRepr]struct ISpStream : ISpStreamFormat
{
	public new const Guid IID = .(0x12e3cca9, 0x7518, 0x44c5, 0xa5, 0xe7, 0xba, 0x5a, 0x79, 0xcb, 0x92, 0x9e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpStreamFormat.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStream, in Guid rguidFormat, WAVEFORMATEX* pWaveFormatEx) SetBaseStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** ppStream) GetBaseStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFileName, SPFILEMODE eMode, Guid* pFormatId, WAVEFORMATEX* pWaveFormatEx, uint64 ullEventInterest) BindToFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
	}


	public HRESULT SetBaseStream(IStream* pStream, in Guid rguidFormat, WAVEFORMATEX* pWaveFormatEx) mut => VT.[Friend]SetBaseStream(&this, pStream, rguidFormat, pWaveFormatEx);

	public HRESULT GetBaseStream(IStream** ppStream) mut => VT.[Friend]GetBaseStream(&this, ppStream);

	public HRESULT BindToFile(PWSTR pszFileName, SPFILEMODE eMode, Guid* pFormatId, WAVEFORMATEX* pWaveFormatEx, uint64 ullEventInterest) mut => VT.[Friend]BindToFile(&this, pszFileName, eMode, pFormatId, pWaveFormatEx, ullEventInterest);

	public HRESULT Close() mut => VT.[Friend]Close(&this);
}

[CRepr]struct ISpStreamFormatConverter : ISpStreamFormat
{
	public new const Guid IID = .(0x678a932c, 0xea71, 0x4446, 0x9b, 0x41, 0x78, 0xfd, 0xa6, 0x28, 0x0a, 0x29);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpStreamFormat.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpStreamFormat* pStream, BOOL fSetFormatToBaseStreamFormat, BOOL fWriteToBaseStream) SetBaseStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpStreamFormat** ppStream) GetBaseStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguidFormatIdOfConvertedStream, WAVEFORMATEX* pWaveFormatExOfConvertedStream) SetFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResetSeekPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 ullOffsetConvertedStream, uint64* pullOffsetBaseStream) ScaleConvertedToBaseOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 ullOffsetBaseStream, uint64* pullOffsetConvertedStream) ScaleBaseToConvertedOffset;
	}


	public HRESULT SetBaseStream(ISpStreamFormat* pStream, BOOL fSetFormatToBaseStreamFormat, BOOL fWriteToBaseStream) mut => VT.[Friend]SetBaseStream(&this, pStream, fSetFormatToBaseStreamFormat, fWriteToBaseStream);

	public HRESULT GetBaseStream(ISpStreamFormat** ppStream) mut => VT.[Friend]GetBaseStream(&this, ppStream);

	public HRESULT SetFormat(in Guid rguidFormatIdOfConvertedStream, WAVEFORMATEX* pWaveFormatExOfConvertedStream) mut => VT.[Friend]SetFormat(&this, rguidFormatIdOfConvertedStream, pWaveFormatExOfConvertedStream);

	public HRESULT ResetSeekPosition() mut => VT.[Friend]ResetSeekPosition(&this);

	public HRESULT ScaleConvertedToBaseOffset(uint64 ullOffsetConvertedStream, uint64* pullOffsetBaseStream) mut => VT.[Friend]ScaleConvertedToBaseOffset(&this, ullOffsetConvertedStream, pullOffsetBaseStream);

	public HRESULT ScaleBaseToConvertedOffset(uint64 ullOffsetBaseStream, uint64* pullOffsetConvertedStream) mut => VT.[Friend]ScaleBaseToConvertedOffset(&this, ullOffsetBaseStream, pullOffsetConvertedStream);
}

[CRepr]struct ISpAudio : ISpStreamFormat
{
	public new const Guid IID = .(0xc05c768f, 0xfae8, 0x4ec2, 0x8e, 0x07, 0x33, 0x83, 0x21, 0xc1, 0x24, 0x52);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpStreamFormat.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPAUDIOSTATE NewState, uint64 ullReserved) SetState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguidFmtId, WAVEFORMATEX* pWaveFormatEx) SetFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPAUDIOSTATUS* pStatus) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPAUDIOBUFFERINFO* pBuffInfo) SetBufferInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPAUDIOBUFFERINFO* pBuffInfo) GetBufferInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pFormatId, WAVEFORMATEX** ppCoMemWaveFormatEx) GetDefaultFormat;
		protected new function [CallingConvention(.Stdcall)] HANDLE(SelfOuter* self) EventHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pLevel) GetVolumeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Level) SetVolumeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcbSize) GetBufferNotifySize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbSize) SetBufferNotifySize;
	}


	public HRESULT SetState(SPAUDIOSTATE NewState, uint64 ullReserved) mut => VT.[Friend]SetState(&this, NewState, ullReserved);

	public HRESULT SetFormat(in Guid rguidFmtId, WAVEFORMATEX* pWaveFormatEx) mut => VT.[Friend]SetFormat(&this, rguidFmtId, pWaveFormatEx);

	public HRESULT GetStatus(SPAUDIOSTATUS* pStatus) mut => VT.[Friend]GetStatus(&this, pStatus);

	public HRESULT SetBufferInfo(SPAUDIOBUFFERINFO* pBuffInfo) mut => VT.[Friend]SetBufferInfo(&this, pBuffInfo);

	public HRESULT GetBufferInfo(SPAUDIOBUFFERINFO* pBuffInfo) mut => VT.[Friend]GetBufferInfo(&this, pBuffInfo);

	public HRESULT GetDefaultFormat(Guid* pFormatId, WAVEFORMATEX** ppCoMemWaveFormatEx) mut => VT.[Friend]GetDefaultFormat(&this, pFormatId, ppCoMemWaveFormatEx);

	public HANDLE EventHandle() mut => VT.[Friend]EventHandle(&this);

	public HRESULT GetVolumeLevel(uint32* pLevel) mut => VT.[Friend]GetVolumeLevel(&this, pLevel);

	public HRESULT SetVolumeLevel(uint32 Level) mut => VT.[Friend]SetVolumeLevel(&this, Level);

	public HRESULT GetBufferNotifySize(uint32* pcbSize) mut => VT.[Friend]GetBufferNotifySize(&this, pcbSize);

	public HRESULT SetBufferNotifySize(uint32 cbSize) mut => VT.[Friend]SetBufferNotifySize(&this, cbSize);
}

[CRepr]struct ISpMMSysAudio : ISpAudio
{
	public new const Guid IID = .(0x15806f6e, 0x1d70, 0x4b48, 0x98, 0xe6, 0x3b, 0x1a, 0x00, 0x75, 0x09, 0xab);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpAudio.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puDeviceId) GetDeviceId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uDeviceId) SetDeviceId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void** pHandle) GetMMHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puLineId) GetLineId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uLineId) SetLineId;
	}


	public HRESULT GetDeviceId(uint32* puDeviceId) mut => VT.[Friend]GetDeviceId(&this, puDeviceId);

	public HRESULT SetDeviceId(uint32 uDeviceId) mut => VT.[Friend]SetDeviceId(&this, uDeviceId);

	public HRESULT GetMMHandle(void** pHandle) mut => VT.[Friend]GetMMHandle(&this, pHandle);

	public HRESULT GetLineId(uint32* puLineId) mut => VT.[Friend]GetLineId(&this, puLineId);

	public HRESULT SetLineId(uint32 uLineId) mut => VT.[Friend]SetLineId(&this, uLineId);
}

[CRepr]struct ISpTranscript : IUnknown
{
	public new const Guid IID = .(0x10f63bce, 0x201a, 0x11d3, 0xac, 0x70, 0x00, 0xc0, 0x4f, 0x8e, 0xe6, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszTranscript) GetTranscript;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTranscript) AppendTranscript;
	}


	public HRESULT GetTranscript(PWSTR* ppszTranscript) mut => VT.[Friend]GetTranscript(&this, ppszTranscript);

	public HRESULT AppendTranscript(PWSTR pszTranscript) mut => VT.[Friend]AppendTranscript(&this, pszTranscript);
}

[CRepr]struct ISpLexicon : IUnknown
{
	public new const Guid IID = .(0xda41a7c2, 0x5383, 0x4db2, 0x91, 0x6b, 0x6c, 0x17, 0x19, 0xe3, 0xdb, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszWord, uint16 LangID, uint32 dwFlags, SPWORDPRONUNCIATIONLIST* pWordPronunciationList) GetPronunciations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszWord, uint16 LangID, SPPARTOFSPEECH ePartOfSpeech, uint16* pszPronunciation) AddPronunciation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszWord, uint16 LangID, SPPARTOFSPEECH ePartOfSpeech, uint16* pszPronunciation) RemovePronunciation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwGeneration) GetGeneration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, uint32* pdwGeneration, SPWORDLIST* pWordList) GetGenerationChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, uint32* pdwGeneration, uint32* pdwCookie, SPWORDLIST* pWordList) GetWords;
	}


	public HRESULT GetPronunciations(PWSTR pszWord, uint16 LangID, uint32 dwFlags, SPWORDPRONUNCIATIONLIST* pWordPronunciationList) mut => VT.[Friend]GetPronunciations(&this, pszWord, LangID, dwFlags, pWordPronunciationList);

	public HRESULT AddPronunciation(PWSTR pszWord, uint16 LangID, SPPARTOFSPEECH ePartOfSpeech, uint16* pszPronunciation) mut => VT.[Friend]AddPronunciation(&this, pszWord, LangID, ePartOfSpeech, pszPronunciation);

	public HRESULT RemovePronunciation(PWSTR pszWord, uint16 LangID, SPPARTOFSPEECH ePartOfSpeech, uint16* pszPronunciation) mut => VT.[Friend]RemovePronunciation(&this, pszWord, LangID, ePartOfSpeech, pszPronunciation);

	public HRESULT GetGeneration(uint32* pdwGeneration) mut => VT.[Friend]GetGeneration(&this, pdwGeneration);

	public HRESULT GetGenerationChange(uint32 dwFlags, uint32* pdwGeneration, SPWORDLIST* pWordList) mut => VT.[Friend]GetGenerationChange(&this, dwFlags, pdwGeneration, pWordList);

	public HRESULT GetWords(uint32 dwFlags, uint32* pdwGeneration, uint32* pdwCookie, SPWORDLIST* pWordList) mut => VT.[Friend]GetWords(&this, dwFlags, pdwGeneration, pdwCookie, pWordList);
}

[CRepr]struct ISpContainerLexicon : ISpLexicon
{
	public new const Guid IID = .(0x8565572f, 0xc094, 0x41cc, 0xb5, 0x6e, 0x10, 0xbd, 0x9c, 0x3f, 0xf0, 0x44);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpLexicon.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpLexicon* pAddLexicon, uint32 dwFlags) AddLexicon;
	}


	public HRESULT AddLexicon(ISpLexicon* pAddLexicon, uint32 dwFlags) mut => VT.[Friend]AddLexicon(&this, pAddLexicon, dwFlags);
}

[CRepr]struct ISpShortcut : IUnknown
{
	public new const Guid IID = .(0x3df681e2, 0xea56, 0x11d9, 0x8b, 0xde, 0xf6, 0x6b, 0xad, 0x1e, 0x3f, 0x3a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszDisplay, uint16 LangID, PWSTR pszSpoken, SPSHORTCUTTYPE shType) AddShortcut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszDisplay, uint16 LangID, PWSTR pszSpoken, SPSHORTCUTTYPE shType) RemoveShortcut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 LangID, SPSHORTCUTPAIRLIST* pShortcutpairList) GetShortcuts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwGeneration) GetGeneration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwGeneration, SPWORDLIST* pWordList) GetWordsFromGenerationChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwGeneration, uint32* pdwCookie, SPWORDLIST* pWordList) GetWords;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwGeneration, uint32* pdwCookie, SPSHORTCUTPAIRLIST* pShortcutpairList) GetShortcutsForGeneration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwGeneration, SPSHORTCUTPAIRLIST* pShortcutpairList) GetGenerationChange;
	}


	public HRESULT AddShortcut(PWSTR pszDisplay, uint16 LangID, PWSTR pszSpoken, SPSHORTCUTTYPE shType) mut => VT.[Friend]AddShortcut(&this, pszDisplay, LangID, pszSpoken, shType);

	public HRESULT RemoveShortcut(PWSTR pszDisplay, uint16 LangID, PWSTR pszSpoken, SPSHORTCUTTYPE shType) mut => VT.[Friend]RemoveShortcut(&this, pszDisplay, LangID, pszSpoken, shType);

	public HRESULT GetShortcuts(uint16 LangID, SPSHORTCUTPAIRLIST* pShortcutpairList) mut => VT.[Friend]GetShortcuts(&this, LangID, pShortcutpairList);

	public HRESULT GetGeneration(uint32* pdwGeneration) mut => VT.[Friend]GetGeneration(&this, pdwGeneration);

	public HRESULT GetWordsFromGenerationChange(uint32* pdwGeneration, SPWORDLIST* pWordList) mut => VT.[Friend]GetWordsFromGenerationChange(&this, pdwGeneration, pWordList);

	public HRESULT GetWords(uint32* pdwGeneration, uint32* pdwCookie, SPWORDLIST* pWordList) mut => VT.[Friend]GetWords(&this, pdwGeneration, pdwCookie, pWordList);

	public HRESULT GetShortcutsForGeneration(uint32* pdwGeneration, uint32* pdwCookie, SPSHORTCUTPAIRLIST* pShortcutpairList) mut => VT.[Friend]GetShortcutsForGeneration(&this, pdwGeneration, pdwCookie, pShortcutpairList);

	public HRESULT GetGenerationChange(uint32* pdwGeneration, SPSHORTCUTPAIRLIST* pShortcutpairList) mut => VT.[Friend]GetGenerationChange(&this, pdwGeneration, pShortcutpairList);
}

[CRepr]struct ISpPhoneConverter : ISpObjectWithToken
{
	public new const Guid IID = .(0x8445c581, 0x0cac, 0x4a38, 0xab, 0xfe, 0x9b, 0x2c, 0xe2, 0x82, 0x64, 0x55);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpObjectWithToken.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPhone, uint16* pId) PhoneToId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pId, PWSTR pszPhone) IdToPhone;
	}


	public HRESULT PhoneToId(PWSTR pszPhone, uint16* pId) mut => VT.[Friend]PhoneToId(&this, pszPhone, pId);

	public HRESULT IdToPhone(uint16* pId, PWSTR pszPhone) mut => VT.[Friend]IdToPhone(&this, pId, pszPhone);
}

[CRepr]struct ISpPhoneticAlphabetConverter : IUnknown
{
	public new const Guid IID = .(0x133adcd4, 0x19b4, 0x4020, 0x9f, 0xdc, 0x84, 0x2e, 0x78, 0x25, 0x3b, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pLangID) GetLangId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 LangID) SetLangId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pszSAPIId, uint16* pszUPSId, uint32 cMaxLength) SAPI2UPS;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pszUPSId, uint16* pszSAPIId, uint32 cMaxLength) UPS2SAPI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cSrcLength, BOOL bSAPI2UPS, uint32* pcMaxDestLength) GetMaxConvertLength;
	}


	public HRESULT GetLangId(uint16* pLangID) mut => VT.[Friend]GetLangId(&this, pLangID);

	public HRESULT SetLangId(uint16 LangID) mut => VT.[Friend]SetLangId(&this, LangID);

	public HRESULT SAPI2UPS(uint16* pszSAPIId, uint16* pszUPSId, uint32 cMaxLength) mut => VT.[Friend]SAPI2UPS(&this, pszSAPIId, pszUPSId, cMaxLength);

	public HRESULT UPS2SAPI(uint16* pszUPSId, uint16* pszSAPIId, uint32 cMaxLength) mut => VT.[Friend]UPS2SAPI(&this, pszUPSId, pszSAPIId, cMaxLength);

	public HRESULT GetMaxConvertLength(uint32 cSrcLength, BOOL bSAPI2UPS, uint32* pcMaxDestLength) mut => VT.[Friend]GetMaxConvertLength(&this, cSrcLength, bSAPI2UPS, pcMaxDestLength);
}

[CRepr]struct ISpPhoneticAlphabetSelection : IUnknown
{
	public new const Guid IID = .(0xb2745efd, 0x42ce, 0x48ca, 0x81, 0xf1, 0xa9, 0x6e, 0x02, 0x53, 0x8a, 0x90);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfIsUPS) IsAlphabetUPS;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fForceUPS) SetAlphabetToUPS;
	}


	public HRESULT IsAlphabetUPS(BOOL* pfIsUPS) mut => VT.[Friend]IsAlphabetUPS(&this, pfIsUPS);

	public HRESULT SetAlphabetToUPS(BOOL fForceUPS) mut => VT.[Friend]SetAlphabetToUPS(&this, fForceUPS);
}

[CRepr]struct ISpVoice : ISpEventSource
{
	public new const Guid IID = .(0x6c44df74, 0x72b9, 0x4992, 0xa1, 0xec, 0xef, 0x99, 0x6e, 0x04, 0x22, 0xd4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpEventSource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOutput, BOOL fAllowFormatChanges) SetOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpObjectToken** ppObjectToken) GetOutputObjectToken;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpStreamFormat** ppStream) GetOutputStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpObjectToken* pToken) SetVoice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpObjectToken** ppToken) GetVoice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcs, uint32 dwFlags, uint32* pulStreamNumber) Speak;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStream, uint32 dwFlags, uint32* pulStreamNumber) SpeakStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPVOICESTATUS* pStatus, PWSTR* ppszLastBookmark) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pItemType, int32 lNumItems, uint32* pulNumSkipped) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPVPRIORITY ePriority) SetPriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPVPRIORITY* pePriority) GetPriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPEVENTENUM eBoundary) SetAlertBoundary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPEVENTENUM* peBoundary) GetAlertBoundary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 RateAdjust) SetRate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRateAdjust) GetRate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 usVolume) SetVolume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pusVolume) GetVolume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 msTimeout) WaitUntilDone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 msTimeout) SetSyncSpeakTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pmsTimeout) GetSyncSpeakTimeout;
		protected new function [CallingConvention(.Stdcall)] HANDLE(SelfOuter* self) SpeakCompleteEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTypeOfUI, void* pvExtraData, uint32 cbExtraData, BOOL* pfSupported) IsUISupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, PWSTR pszTitle, PWSTR pszTypeOfUI, void* pvExtraData, uint32 cbExtraData) DisplayUI;
	}


	public HRESULT SetOutput(IUnknown* pUnkOutput, BOOL fAllowFormatChanges) mut => VT.[Friend]SetOutput(&this, pUnkOutput, fAllowFormatChanges);

	public HRESULT GetOutputObjectToken(ISpObjectToken** ppObjectToken) mut => VT.[Friend]GetOutputObjectToken(&this, ppObjectToken);

	public HRESULT GetOutputStream(ISpStreamFormat** ppStream) mut => VT.[Friend]GetOutputStream(&this, ppStream);

	public HRESULT Pause() mut => VT.[Friend]Pause(&this);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);

	public HRESULT SetVoice(ISpObjectToken* pToken) mut => VT.[Friend]SetVoice(&this, pToken);

	public HRESULT GetVoice(ISpObjectToken** ppToken) mut => VT.[Friend]GetVoice(&this, ppToken);

	public HRESULT Speak(PWSTR pwcs, uint32 dwFlags, uint32* pulStreamNumber) mut => VT.[Friend]Speak(&this, pwcs, dwFlags, pulStreamNumber);

	public HRESULT SpeakStream(IStream* pStream, uint32 dwFlags, uint32* pulStreamNumber) mut => VT.[Friend]SpeakStream(&this, pStream, dwFlags, pulStreamNumber);

	public HRESULT GetStatus(SPVOICESTATUS* pStatus, PWSTR* ppszLastBookmark) mut => VT.[Friend]GetStatus(&this, pStatus, ppszLastBookmark);

	public HRESULT Skip(PWSTR pItemType, int32 lNumItems, uint32* pulNumSkipped) mut => VT.[Friend]Skip(&this, pItemType, lNumItems, pulNumSkipped);

	public HRESULT SetPriority(SPVPRIORITY ePriority) mut => VT.[Friend]SetPriority(&this, ePriority);

	public HRESULT GetPriority(SPVPRIORITY* pePriority) mut => VT.[Friend]GetPriority(&this, pePriority);

	public HRESULT SetAlertBoundary(SPEVENTENUM eBoundary) mut => VT.[Friend]SetAlertBoundary(&this, eBoundary);

	public HRESULT GetAlertBoundary(SPEVENTENUM* peBoundary) mut => VT.[Friend]GetAlertBoundary(&this, peBoundary);

	public HRESULT SetRate(int32 RateAdjust) mut => VT.[Friend]SetRate(&this, RateAdjust);

	public HRESULT GetRate(int32* pRateAdjust) mut => VT.[Friend]GetRate(&this, pRateAdjust);

	public HRESULT SetVolume(uint16 usVolume) mut => VT.[Friend]SetVolume(&this, usVolume);

	public HRESULT GetVolume(uint16* pusVolume) mut => VT.[Friend]GetVolume(&this, pusVolume);

	public HRESULT WaitUntilDone(uint32 msTimeout) mut => VT.[Friend]WaitUntilDone(&this, msTimeout);

	public HRESULT SetSyncSpeakTimeout(uint32 msTimeout) mut => VT.[Friend]SetSyncSpeakTimeout(&this, msTimeout);

	public HRESULT GetSyncSpeakTimeout(uint32* pmsTimeout) mut => VT.[Friend]GetSyncSpeakTimeout(&this, pmsTimeout);

	public HANDLE SpeakCompleteEvent() mut => VT.[Friend]SpeakCompleteEvent(&this);

	public HRESULT IsUISupported(PWSTR pszTypeOfUI, void* pvExtraData, uint32 cbExtraData, BOOL* pfSupported) mut => VT.[Friend]IsUISupported(&this, pszTypeOfUI, pvExtraData, cbExtraData, pfSupported);

	public HRESULT DisplayUI(HWND hwndParent, PWSTR pszTitle, PWSTR pszTypeOfUI, void* pvExtraData, uint32 cbExtraData) mut => VT.[Friend]DisplayUI(&this, hwndParent, pszTitle, pszTypeOfUI, pvExtraData, cbExtraData);
}

[CRepr]struct ISpPhrase : IUnknown
{
	public new const Guid IID = .(0x1a5c0354, 0xb621, 0x4b5a, 0x87, 0x91, 0xd3, 0x06, 0xed, 0x37, 0x9e, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPPHRASE** ppCoMemPhrase) GetPhrase;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPSERIALIZEDPHRASE** ppCoMemPhrase) GetSerializedPhrase;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulStart, uint32 ulCount, BOOL fUseTextReplacements, PWSTR* ppszCoMemText, uint8* pbDisplayAttributes) GetText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwValueTypes) Discard;
	}


	public HRESULT GetPhrase(SPPHRASE** ppCoMemPhrase) mut => VT.[Friend]GetPhrase(&this, ppCoMemPhrase);

	public HRESULT GetSerializedPhrase(SPSERIALIZEDPHRASE** ppCoMemPhrase) mut => VT.[Friend]GetSerializedPhrase(&this, ppCoMemPhrase);

	public HRESULT GetText(uint32 ulStart, uint32 ulCount, BOOL fUseTextReplacements, PWSTR* ppszCoMemText, uint8* pbDisplayAttributes) mut => VT.[Friend]GetText(&this, ulStart, ulCount, fUseTextReplacements, ppszCoMemText, pbDisplayAttributes);

	public HRESULT Discard(uint32 dwValueTypes) mut => VT.[Friend]Discard(&this, dwValueTypes);
}

[CRepr]struct ISpPhraseAlt : ISpPhrase
{
	public new const Guid IID = .(0x8fcebc98, 0x4e49, 0x4067, 0x9c, 0x6c, 0xd8, 0x6a, 0x0e, 0x09, 0x2e, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpPhrase.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpPhrase** ppParent, uint32* pulStartElementInParent, uint32* pcElementsInParent, uint32* pcElementsInAlt) GetAltInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Commit;
	}


	public HRESULT GetAltInfo(ISpPhrase** ppParent, uint32* pulStartElementInParent, uint32* pcElementsInParent, uint32* pcElementsInAlt) mut => VT.[Friend]GetAltInfo(&this, ppParent, pulStartElementInParent, pcElementsInParent, pcElementsInAlt);

	public HRESULT Commit() mut => VT.[Friend]Commit(&this);
}

[CRepr]struct ISpPhrase2 : ISpPhrase
{
	public new const Guid IID = .(0xf264da52, 0xe457, 0x4696, 0xb8, 0x56, 0xa7, 0x37, 0xb7, 0x17, 0xaf, 0x79);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpPhrase.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszCoMemXMLResult, SPXMLRESULTOPTIONS Options) GetXMLResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPSEMANTICERRORINFO* pSemanticErrorInfo) GetXMLErrorInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulStartElement, uint32 cElements, ISpStreamFormat** ppStream) GetAudio;
	}


	public HRESULT GetXMLResult(PWSTR* ppszCoMemXMLResult, SPXMLRESULTOPTIONS Options) mut => VT.[Friend]GetXMLResult(&this, ppszCoMemXMLResult, Options);

	public HRESULT GetXMLErrorInfo(SPSEMANTICERRORINFO* pSemanticErrorInfo) mut => VT.[Friend]GetXMLErrorInfo(&this, pSemanticErrorInfo);

	public HRESULT GetAudio(uint32 ulStartElement, uint32 cElements, ISpStreamFormat** ppStream) mut => VT.[Friend]GetAudio(&this, ulStartElement, cElements, ppStream);
}

[CRepr]struct ISpRecoResult : ISpPhrase
{
	public new const Guid IID = .(0x20b053be, 0xe235, 0x43cd, 0x9a, 0x2a, 0x8d, 0x17, 0xa4, 0x8b, 0x78, 0x42);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpPhrase.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPRECORESULTTIMES* pTimes) GetResultTimes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulStartElement, uint32 cElements, uint32 ulRequestCount, ISpPhraseAlt** ppPhrases, uint32* pcPhrasesReturned) GetAlternates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulStartElement, uint32 cElements, ISpStreamFormat** ppStream) GetAudio;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulStartElement, uint32 cElements, uint32 dwFlags, uint32* pulStreamNumber) SpeakAudio;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPSERIALIZEDRESULT** ppCoMemSerializedResult) Serialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pAudioFormatId, WAVEFORMATEX* pWaveFormatEx) ScaleAudio;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpRecoContext** ppRecoContext) GetRecoContext;
	}


	public HRESULT GetResultTimes(SPRECORESULTTIMES* pTimes) mut => VT.[Friend]GetResultTimes(&this, pTimes);

	public HRESULT GetAlternates(uint32 ulStartElement, uint32 cElements, uint32 ulRequestCount, ISpPhraseAlt** ppPhrases, uint32* pcPhrasesReturned) mut => VT.[Friend]GetAlternates(&this, ulStartElement, cElements, ulRequestCount, ppPhrases, pcPhrasesReturned);

	public HRESULT GetAudio(uint32 ulStartElement, uint32 cElements, ISpStreamFormat** ppStream) mut => VT.[Friend]GetAudio(&this, ulStartElement, cElements, ppStream);

	public HRESULT SpeakAudio(uint32 ulStartElement, uint32 cElements, uint32 dwFlags, uint32* pulStreamNumber) mut => VT.[Friend]SpeakAudio(&this, ulStartElement, cElements, dwFlags, pulStreamNumber);

	public HRESULT Serialize(SPSERIALIZEDRESULT** ppCoMemSerializedResult) mut => VT.[Friend]Serialize(&this, ppCoMemSerializedResult);

	public HRESULT ScaleAudio(in Guid pAudioFormatId, WAVEFORMATEX* pWaveFormatEx) mut => VT.[Friend]ScaleAudio(&this, pAudioFormatId, pWaveFormatEx);

	public HRESULT GetRecoContext(ISpRecoContext** ppRecoContext) mut => VT.[Friend]GetRecoContext(&this, ppRecoContext);
}

[CRepr]struct ISpRecoResult2 : ISpRecoResult
{
	public new const Guid IID = .(0x27cac6c4, 0x88f2, 0x41f2, 0x88, 0x17, 0x0c, 0x95, 0xe5, 0x9f, 0x1e, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpRecoResult.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpPhraseAlt* pPhraseAlt, ISpRecoResult** ppNewResult) CommitAlternate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulStartElement, uint32 cElements, PWSTR pszCorrectedData, uint32 eCommitFlags) CommitText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFeedback, BOOL fSuccessful) SetTextFeedback;
	}


	public HRESULT CommitAlternate(ISpPhraseAlt* pPhraseAlt, ISpRecoResult** ppNewResult) mut => VT.[Friend]CommitAlternate(&this, pPhraseAlt, ppNewResult);

	public HRESULT CommitText(uint32 ulStartElement, uint32 cElements, PWSTR pszCorrectedData, uint32 eCommitFlags) mut => VT.[Friend]CommitText(&this, ulStartElement, cElements, pszCorrectedData, eCommitFlags);

	public HRESULT SetTextFeedback(PWSTR pszFeedback, BOOL fSuccessful) mut => VT.[Friend]SetTextFeedback(&this, pszFeedback, fSuccessful);
}

[CRepr]struct ISpXMLRecoResult : ISpRecoResult
{
	public new const Guid IID = .(0xae39362b, 0x45a8, 0x4074, 0x9b, 0x9e, 0xcc, 0xf4, 0x9a, 0xa2, 0xd0, 0xb6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpRecoResult.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszCoMemXMLResult, SPXMLRESULTOPTIONS Options) GetXMLResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPSEMANTICERRORINFO* pSemanticErrorInfo) GetXMLErrorInfo;
	}


	public HRESULT GetXMLResult(PWSTR* ppszCoMemXMLResult, SPXMLRESULTOPTIONS Options) mut => VT.[Friend]GetXMLResult(&this, ppszCoMemXMLResult, Options);

	public HRESULT GetXMLErrorInfo(SPSEMANTICERRORINFO* pSemanticErrorInfo) mut => VT.[Friend]GetXMLErrorInfo(&this, pSemanticErrorInfo);
}

[CRepr]struct ISpGrammarBuilder : IUnknown
{
	public new const Guid IID = .(0x8137828f, 0x591a, 0x4a42, 0xbe, 0x58, 0x49, 0xea, 0x7e, 0xba, 0xac, 0x68);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 NewLanguage) ResetGrammar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszRuleName, uint32 dwRuleId, uint32 dwAttributes, BOOL fCreateIfNotExist, SPSTATEHANDLE__** phInitialState) GetRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPSTATEHANDLE__* hState) ClearRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPSTATEHANDLE__* hState, SPSTATEHANDLE__** phState) CreateNewState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPSTATEHANDLE__* hFromState, SPSTATEHANDLE__* hToState, PWSTR psz, PWSTR pszSeparators, SPGRAMMARWORDTYPE eWordType, float Weight, SPPROPERTYINFO* pPropInfo) AddWordTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPSTATEHANDLE__* hFromState, SPSTATEHANDLE__* hToState, SPSTATEHANDLE__* hRule, float Weight, SPPROPERTYINFO* pPropInfo) AddRuleTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPSTATEHANDLE__* hRuleState, PWSTR pszResourceName, PWSTR pszResourceValue) AddResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwReserved) Commit;
	}


	public HRESULT ResetGrammar(uint16 NewLanguage) mut => VT.[Friend]ResetGrammar(&this, NewLanguage);

	public HRESULT GetRule(PWSTR pszRuleName, uint32 dwRuleId, uint32 dwAttributes, BOOL fCreateIfNotExist, SPSTATEHANDLE__** phInitialState) mut => VT.[Friend]GetRule(&this, pszRuleName, dwRuleId, dwAttributes, fCreateIfNotExist, phInitialState);

	public HRESULT ClearRule(SPSTATEHANDLE__* hState) mut => VT.[Friend]ClearRule(&this, hState);

	public HRESULT CreateNewState(SPSTATEHANDLE__* hState, SPSTATEHANDLE__** phState) mut => VT.[Friend]CreateNewState(&this, hState, phState);

	public HRESULT AddWordTransition(SPSTATEHANDLE__* hFromState, SPSTATEHANDLE__* hToState, PWSTR psz, PWSTR pszSeparators, SPGRAMMARWORDTYPE eWordType, float Weight, SPPROPERTYINFO* pPropInfo) mut => VT.[Friend]AddWordTransition(&this, hFromState, hToState, psz, pszSeparators, eWordType, Weight, pPropInfo);

	public HRESULT AddRuleTransition(SPSTATEHANDLE__* hFromState, SPSTATEHANDLE__* hToState, SPSTATEHANDLE__* hRule, float Weight, SPPROPERTYINFO* pPropInfo) mut => VT.[Friend]AddRuleTransition(&this, hFromState, hToState, hRule, Weight, pPropInfo);

	public HRESULT AddResource(SPSTATEHANDLE__* hRuleState, PWSTR pszResourceName, PWSTR pszResourceValue) mut => VT.[Friend]AddResource(&this, hRuleState, pszResourceName, pszResourceValue);

	public HRESULT Commit(uint32 dwReserved) mut => VT.[Friend]Commit(&this, dwReserved);
}

[CRepr]struct ISpRecoGrammar : ISpGrammarBuilder
{
	public new const Guid IID = .(0x2177db29, 0x7f45, 0x47d0, 0x85, 0x54, 0x06, 0x7e, 0x91, 0xc8, 0x05, 0x02);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpGrammarBuilder.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pullGrammarId) GetGrammarId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpRecoContext** ppRecoCtxt) GetRecoContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFileName, SPLOADOPTIONS Options) LoadCmdFromFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rcid, PWSTR pszGrammarName, SPLOADOPTIONS Options) LoadCmdFromObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HINSTANCE hModule, PWSTR pszResourceName, PWSTR pszResourceType, uint16 wLanguage, SPLOADOPTIONS Options) LoadCmdFromResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPBINARYGRAMMAR* pGrammar, SPLOADOPTIONS Options) LoadCmdFromMemory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguidParam, PWSTR pszStringParam, void* pvDataPrarm, uint32 cbDataSize, SPLOADOPTIONS Options) LoadCmdFromProprietaryGrammar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, void* pReserved, SPRULESTATE NewState) SetRuleState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulRuleId, SPRULESTATE NewState) SetRuleIdState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTopicName, SPLOADOPTIONS Options) LoadDictation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UnloadDictation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPRULESTATE NewState) SetDictationState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pText, uint32 cchText, SPTEXTSELECTIONINFO* pInfo) SetWordSequenceData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPTEXTSELECTIONINFO* pInfo) SetTextSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszWord, SPWORDPRONOUNCEABLE* pWordPronounceable) IsPronounceable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPGRAMMARSTATE eGrammarState) SetGrammarState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStream, PWSTR* ppszCoMemErrorText) SaveCmd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPGRAMMARSTATE* peGrammarState) GetGrammarState;
	}


	public HRESULT GetGrammarId(uint64* pullGrammarId) mut => VT.[Friend]GetGrammarId(&this, pullGrammarId);

	public HRESULT GetRecoContext(ISpRecoContext** ppRecoCtxt) mut => VT.[Friend]GetRecoContext(&this, ppRecoCtxt);

	public HRESULT LoadCmdFromFile(PWSTR pszFileName, SPLOADOPTIONS Options) mut => VT.[Friend]LoadCmdFromFile(&this, pszFileName, Options);

	public HRESULT LoadCmdFromObject(in Guid rcid, PWSTR pszGrammarName, SPLOADOPTIONS Options) mut => VT.[Friend]LoadCmdFromObject(&this, rcid, pszGrammarName, Options);

	public HRESULT LoadCmdFromResource(HINSTANCE hModule, PWSTR pszResourceName, PWSTR pszResourceType, uint16 wLanguage, SPLOADOPTIONS Options) mut => VT.[Friend]LoadCmdFromResource(&this, hModule, pszResourceName, pszResourceType, wLanguage, Options);

	public HRESULT LoadCmdFromMemory(SPBINARYGRAMMAR* pGrammar, SPLOADOPTIONS Options) mut => VT.[Friend]LoadCmdFromMemory(&this, pGrammar, Options);

	public HRESULT LoadCmdFromProprietaryGrammar(in Guid rguidParam, PWSTR pszStringParam, void* pvDataPrarm, uint32 cbDataSize, SPLOADOPTIONS Options) mut => VT.[Friend]LoadCmdFromProprietaryGrammar(&this, rguidParam, pszStringParam, pvDataPrarm, cbDataSize, Options);

	public HRESULT SetRuleState(PWSTR pszName, void* pReserved, SPRULESTATE NewState) mut => VT.[Friend]SetRuleState(&this, pszName, pReserved, NewState);

	public HRESULT SetRuleIdState(uint32 ulRuleId, SPRULESTATE NewState) mut => VT.[Friend]SetRuleIdState(&this, ulRuleId, NewState);

	public HRESULT LoadDictation(PWSTR pszTopicName, SPLOADOPTIONS Options) mut => VT.[Friend]LoadDictation(&this, pszTopicName, Options);

	public HRESULT UnloadDictation() mut => VT.[Friend]UnloadDictation(&this);

	public HRESULT SetDictationState(SPRULESTATE NewState) mut => VT.[Friend]SetDictationState(&this, NewState);

	public HRESULT SetWordSequenceData(char16* pText, uint32 cchText, SPTEXTSELECTIONINFO* pInfo) mut => VT.[Friend]SetWordSequenceData(&this, pText, cchText, pInfo);

	public HRESULT SetTextSelection(SPTEXTSELECTIONINFO* pInfo) mut => VT.[Friend]SetTextSelection(&this, pInfo);

	public HRESULT IsPronounceable(PWSTR pszWord, SPWORDPRONOUNCEABLE* pWordPronounceable) mut => VT.[Friend]IsPronounceable(&this, pszWord, pWordPronounceable);

	public HRESULT SetGrammarState(SPGRAMMARSTATE eGrammarState) mut => VT.[Friend]SetGrammarState(&this, eGrammarState);

	public HRESULT SaveCmd(IStream* pStream, PWSTR* ppszCoMemErrorText) mut => VT.[Friend]SaveCmd(&this, pStream, ppszCoMemErrorText);

	public HRESULT GetGrammarState(SPGRAMMARSTATE* peGrammarState) mut => VT.[Friend]GetGrammarState(&this, peGrammarState);
}

[CRepr]struct ISpGrammarBuilder2 : IUnknown
{
	public new const Guid IID = .(0x8ab10026, 0x20cc, 0x4b20, 0x8c, 0x22, 0xa4, 0x9c, 0x9b, 0xa7, 0x8f, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPSTATEHANDLE__* hFromState, SPSTATEHANDLE__* hToState, PWSTR psz, SPMATCHINGMODE eMatchMode) AddTextSubset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PHONETICALPHABET phoneticALphabet) SetPhoneticAlphabet;
	}


	public HRESULT AddTextSubset(SPSTATEHANDLE__* hFromState, SPSTATEHANDLE__* hToState, PWSTR psz, SPMATCHINGMODE eMatchMode) mut => VT.[Friend]AddTextSubset(&this, hFromState, hToState, psz, eMatchMode);

	public HRESULT SetPhoneticAlphabet(PHONETICALPHABET phoneticALphabet) mut => VT.[Friend]SetPhoneticAlphabet(&this, phoneticALphabet);
}

[CRepr]struct ISpRecoGrammar2 : IUnknown
{
	public new const Guid IID = .(0x4b37bc9e, 0x9ed6, 0x44a3, 0x93, 0xd3, 0x18, 0xf0, 0x22, 0xb7, 0x9e, 0xc3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPRULE** ppCoMemRules, uint32* puNumRules) GetRules;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFileName, SPLOADOPTIONS Options, PWSTR pszSharingUri, PWSTR pszBaseUri) LoadCmdFromFile2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPBINARYGRAMMAR* pGrammar, SPLOADOPTIONS Options, PWSTR pszSharingUri, PWSTR pszBaseUri) LoadCmdFromMemory2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszRuleName, uint32 ulRuleId, int32 nRulePriority) SetRulePriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszRuleName, uint32 ulRuleId, float flWeight) SetRuleWeight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float flWeight) SetDictationWeight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechResourceLoader* pLoader) SetGrammarLoader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInternetSecurityManager* pSMLSecurityManager) SetSMLSecurityManager;
	}


	public HRESULT GetRules(SPRULE** ppCoMemRules, uint32* puNumRules) mut => VT.[Friend]GetRules(&this, ppCoMemRules, puNumRules);

	public HRESULT LoadCmdFromFile2(PWSTR pszFileName, SPLOADOPTIONS Options, PWSTR pszSharingUri, PWSTR pszBaseUri) mut => VT.[Friend]LoadCmdFromFile2(&this, pszFileName, Options, pszSharingUri, pszBaseUri);

	public HRESULT LoadCmdFromMemory2(SPBINARYGRAMMAR* pGrammar, SPLOADOPTIONS Options, PWSTR pszSharingUri, PWSTR pszBaseUri) mut => VT.[Friend]LoadCmdFromMemory2(&this, pGrammar, Options, pszSharingUri, pszBaseUri);

	public HRESULT SetRulePriority(PWSTR pszRuleName, uint32 ulRuleId, int32 nRulePriority) mut => VT.[Friend]SetRulePriority(&this, pszRuleName, ulRuleId, nRulePriority);

	public HRESULT SetRuleWeight(PWSTR pszRuleName, uint32 ulRuleId, float flWeight) mut => VT.[Friend]SetRuleWeight(&this, pszRuleName, ulRuleId, flWeight);

	public HRESULT SetDictationWeight(float flWeight) mut => VT.[Friend]SetDictationWeight(&this, flWeight);

	public HRESULT SetGrammarLoader(ISpeechResourceLoader* pLoader) mut => VT.[Friend]SetGrammarLoader(&this, pLoader);

	public HRESULT SetSMLSecurityManager(IInternetSecurityManager* pSMLSecurityManager) mut => VT.[Friend]SetSMLSecurityManager(&this, pSMLSecurityManager);
}

[CRepr]struct ISpeechResourceLoader : IDispatch
{
	public new const Guid IID = .(0xb9ac5783, 0xfcd0, 0x4b21, 0xb1, 0x19, 0xb4, 0xf8, 0xda, 0x8f, 0xd2, 0xc3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrResourceUri, int16 fAlwaysReload, IUnknown** pStream, BSTR* pbstrMIMEType, int16* pfModified, BSTR* pbstrRedirectUrl) LoadResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrResourceUri, BSTR* pbstrLocalPath, BSTR* pbstrMIMEType, BSTR* pbstrRedirectUrl) GetLocalCopy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR pbstrLocalPath) ReleaseLocalCopy;
	}


	public HRESULT LoadResource(BSTR bstrResourceUri, int16 fAlwaysReload, IUnknown** pStream, BSTR* pbstrMIMEType, int16* pfModified, BSTR* pbstrRedirectUrl) mut => VT.[Friend]LoadResource(&this, bstrResourceUri, fAlwaysReload, pStream, pbstrMIMEType, pfModified, pbstrRedirectUrl);

	public HRESULT GetLocalCopy(BSTR bstrResourceUri, BSTR* pbstrLocalPath, BSTR* pbstrMIMEType, BSTR* pbstrRedirectUrl) mut => VT.[Friend]GetLocalCopy(&this, bstrResourceUri, pbstrLocalPath, pbstrMIMEType, pbstrRedirectUrl);

	public HRESULT ReleaseLocalCopy(BSTR pbstrLocalPath) mut => VT.[Friend]ReleaseLocalCopy(&this, pbstrLocalPath);
}

[CRepr]struct ISpRecoContext : ISpEventSource
{
	public new const Guid IID = .(0xf740a62f, 0x7c15, 0x489e, 0x82, 0x34, 0x94, 0x0a, 0x33, 0xd9, 0x27, 0x2d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpEventSource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpRecognizer** ppRecognizer) GetRecognizer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 ullGrammarId, ISpRecoGrammar** ppGrammar) CreateGrammar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPRECOCONTEXTSTATUS* pStatus) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcAlternates) GetMaxAlternates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cAlternates) SetMaxAlternates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPAUDIOOPTIONS Options, in Guid pAudioFormatId, WAVEFORMATEX* pWaveFormatEx) SetAudioOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPAUDIOOPTIONS* pOptions, Guid* pAudioFormatId, WAVEFORMATEX** ppCoMemWFEX) GetAudioOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPSERIALIZEDRESULT* pSerializedResult, ISpRecoResult** ppResult) DeserializeResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPBOOKMARKOPTIONS Options, uint64 ullStreamPosition, LPARAM lparamEvent) Bookmark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pAdaptationData, uint32 cch) SetAdaptationData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwReserved) Pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwReserved) Resume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpVoice* pVoice, BOOL fAllowFormatChanges) SetVoice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpVoice** ppVoice) GetVoice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 ullEventInterest) SetVoicePurgeEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pullEventInterest) GetVoicePurgeEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPCONTEXTSTATE eContextState) SetContextState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPCONTEXTSTATE* peContextState) GetContextState;
	}


	public HRESULT GetRecognizer(ISpRecognizer** ppRecognizer) mut => VT.[Friend]GetRecognizer(&this, ppRecognizer);

	public HRESULT CreateGrammar(uint64 ullGrammarId, ISpRecoGrammar** ppGrammar) mut => VT.[Friend]CreateGrammar(&this, ullGrammarId, ppGrammar);

	public HRESULT GetStatus(SPRECOCONTEXTSTATUS* pStatus) mut => VT.[Friend]GetStatus(&this, pStatus);

	public HRESULT GetMaxAlternates(uint32* pcAlternates) mut => VT.[Friend]GetMaxAlternates(&this, pcAlternates);

	public HRESULT SetMaxAlternates(uint32 cAlternates) mut => VT.[Friend]SetMaxAlternates(&this, cAlternates);

	public HRESULT SetAudioOptions(SPAUDIOOPTIONS Options, in Guid pAudioFormatId, WAVEFORMATEX* pWaveFormatEx) mut => VT.[Friend]SetAudioOptions(&this, Options, pAudioFormatId, pWaveFormatEx);

	public HRESULT GetAudioOptions(SPAUDIOOPTIONS* pOptions, Guid* pAudioFormatId, WAVEFORMATEX** ppCoMemWFEX) mut => VT.[Friend]GetAudioOptions(&this, pOptions, pAudioFormatId, ppCoMemWFEX);

	public HRESULT DeserializeResult(SPSERIALIZEDRESULT* pSerializedResult, ISpRecoResult** ppResult) mut => VT.[Friend]DeserializeResult(&this, pSerializedResult, ppResult);

	public HRESULT Bookmark(SPBOOKMARKOPTIONS Options, uint64 ullStreamPosition, LPARAM lparamEvent) mut => VT.[Friend]Bookmark(&this, Options, ullStreamPosition, lparamEvent);

	public HRESULT SetAdaptationData(PWSTR pAdaptationData, uint32 cch) mut => VT.[Friend]SetAdaptationData(&this, pAdaptationData, cch);

	public HRESULT Pause(uint32 dwReserved) mut => VT.[Friend]Pause(&this, dwReserved);

	public HRESULT Resume(uint32 dwReserved) mut => VT.[Friend]Resume(&this, dwReserved);

	public HRESULT SetVoice(ISpVoice* pVoice, BOOL fAllowFormatChanges) mut => VT.[Friend]SetVoice(&this, pVoice, fAllowFormatChanges);

	public HRESULT GetVoice(ISpVoice** ppVoice) mut => VT.[Friend]GetVoice(&this, ppVoice);

	public HRESULT SetVoicePurgeEvent(uint64 ullEventInterest) mut => VT.[Friend]SetVoicePurgeEvent(&this, ullEventInterest);

	public HRESULT GetVoicePurgeEvent(uint64* pullEventInterest) mut => VT.[Friend]GetVoicePurgeEvent(&this, pullEventInterest);

	public HRESULT SetContextState(SPCONTEXTSTATE eContextState) mut => VT.[Friend]SetContextState(&this, eContextState);

	public HRESULT GetContextState(SPCONTEXTSTATE* peContextState) mut => VT.[Friend]GetContextState(&this, peContextState);
}

[CRepr]struct ISpRecoContext2 : IUnknown
{
	public new const Guid IID = .(0xbead311c, 0x52ff, 0x437f, 0x94, 0x64, 0x6b, 0x21, 0x05, 0x4c, 0xa7, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 eGrammarOptions) SetGrammarOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* peGrammarOptions) GetGrammarOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pAdaptationData, uint32 cch, PWSTR pTopicName, uint32 eAdaptationSettings, SPADAPTATIONRELEVANCE eRelevance) SetAdaptationData2;
	}


	public HRESULT SetGrammarOptions(uint32 eGrammarOptions) mut => VT.[Friend]SetGrammarOptions(&this, eGrammarOptions);

	public HRESULT GetGrammarOptions(uint32* peGrammarOptions) mut => VT.[Friend]GetGrammarOptions(&this, peGrammarOptions);

	public HRESULT SetAdaptationData2(PWSTR pAdaptationData, uint32 cch, PWSTR pTopicName, uint32 eAdaptationSettings, SPADAPTATIONRELEVANCE eRelevance) mut => VT.[Friend]SetAdaptationData2(&this, pAdaptationData, cch, pTopicName, eAdaptationSettings, eRelevance);
}

[CRepr]struct ISpProperties : IUnknown
{
	public new const Guid IID = .(0x5b4fb971, 0xb115, 0x4de1, 0xad, 0x97, 0xe4, 0x82, 0xe3, 0xbf, 0x6e, 0xe4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pName, int32 lValue) SetPropertyNum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pName, int32* plValue) GetPropertyNum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pName, PWSTR pValue) SetPropertyString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pName, PWSTR* ppCoMemValue) GetPropertyString;
	}


	public HRESULT SetPropertyNum(PWSTR pName, int32 lValue) mut => VT.[Friend]SetPropertyNum(&this, pName, lValue);

	public HRESULT GetPropertyNum(PWSTR pName, int32* plValue) mut => VT.[Friend]GetPropertyNum(&this, pName, plValue);

	public HRESULT SetPropertyString(PWSTR pName, PWSTR pValue) mut => VT.[Friend]SetPropertyString(&this, pName, pValue);

	public HRESULT GetPropertyString(PWSTR pName, PWSTR* ppCoMemValue) mut => VT.[Friend]GetPropertyString(&this, pName, ppCoMemValue);
}

[CRepr]struct ISpRecognizer : ISpProperties
{
	public new const Guid IID = .(0xc2b5f241, 0xdaa0, 0x4507, 0x9e, 0x16, 0x5a, 0x1e, 0xaa, 0x2b, 0x7a, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpProperties.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpObjectToken* pRecognizer) SetRecognizer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpObjectToken** ppRecognizer) GetRecognizer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkInput, BOOL fAllowFormatChanges) SetInput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpObjectToken** ppToken) GetInputObjectToken;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpStreamFormat** ppStream) GetInputStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpRecoContext** ppNewCtxt) CreateRecoContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpObjectToken** ppToken) GetRecoProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpObjectToken* pToken) SetRecoProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsSharedInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPRECOSTATE* pState) GetRecoState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPRECOSTATE NewState) SetRecoState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPRECOGNIZERSTATUS* pStatus) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPSTREAMFORMATTYPE WaveFormatType, Guid* pFormatId, WAVEFORMATEX** ppCoMemWFEX) GetFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTypeOfUI, void* pvExtraData, uint32 cbExtraData, BOOL* pfSupported) IsUISupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, PWSTR pszTitle, PWSTR pszTypeOfUI, void* pvExtraData, uint32 cbExtraData) DisplayUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpPhrase* pPhrase) EmulateRecognition;
	}


	public HRESULT SetRecognizer(ISpObjectToken* pRecognizer) mut => VT.[Friend]SetRecognizer(&this, pRecognizer);

	public HRESULT GetRecognizer(ISpObjectToken** ppRecognizer) mut => VT.[Friend]GetRecognizer(&this, ppRecognizer);

	public HRESULT SetInput(IUnknown* pUnkInput, BOOL fAllowFormatChanges) mut => VT.[Friend]SetInput(&this, pUnkInput, fAllowFormatChanges);

	public HRESULT GetInputObjectToken(ISpObjectToken** ppToken) mut => VT.[Friend]GetInputObjectToken(&this, ppToken);

	public HRESULT GetInputStream(ISpStreamFormat** ppStream) mut => VT.[Friend]GetInputStream(&this, ppStream);

	public HRESULT CreateRecoContext(ISpRecoContext** ppNewCtxt) mut => VT.[Friend]CreateRecoContext(&this, ppNewCtxt);

	public HRESULT GetRecoProfile(ISpObjectToken** ppToken) mut => VT.[Friend]GetRecoProfile(&this, ppToken);

	public HRESULT SetRecoProfile(ISpObjectToken* pToken) mut => VT.[Friend]SetRecoProfile(&this, pToken);

	public HRESULT IsSharedInstance() mut => VT.[Friend]IsSharedInstance(&this);

	public HRESULT GetRecoState(SPRECOSTATE* pState) mut => VT.[Friend]GetRecoState(&this, pState);

	public HRESULT SetRecoState(SPRECOSTATE NewState) mut => VT.[Friend]SetRecoState(&this, NewState);

	public HRESULT GetStatus(SPRECOGNIZERSTATUS* pStatus) mut => VT.[Friend]GetStatus(&this, pStatus);

	public HRESULT GetFormat(SPSTREAMFORMATTYPE WaveFormatType, Guid* pFormatId, WAVEFORMATEX** ppCoMemWFEX) mut => VT.[Friend]GetFormat(&this, WaveFormatType, pFormatId, ppCoMemWFEX);

	public HRESULT IsUISupported(PWSTR pszTypeOfUI, void* pvExtraData, uint32 cbExtraData, BOOL* pfSupported) mut => VT.[Friend]IsUISupported(&this, pszTypeOfUI, pvExtraData, cbExtraData, pfSupported);

	public HRESULT DisplayUI(HWND hwndParent, PWSTR pszTitle, PWSTR pszTypeOfUI, void* pvExtraData, uint32 cbExtraData) mut => VT.[Friend]DisplayUI(&this, hwndParent, pszTitle, pszTypeOfUI, pvExtraData, cbExtraData);

	public HRESULT EmulateRecognition(ISpPhrase* pPhrase) mut => VT.[Friend]EmulateRecognition(&this, pPhrase);
}

[CRepr]struct ISpSerializeState : IUnknown
{
	public new const Guid IID = .(0x21b501a0, 0x0ec7, 0x46c9, 0x92, 0xc3, 0xa2, 0xbc, 0x78, 0x4c, 0x54, 0xb9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** ppbData, uint32* pulSize, uint32 dwReserved) GetSerializedState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbData, uint32 ulSize, uint32 dwReserved) SetSerializedState;
	}


	public HRESULT GetSerializedState(uint8** ppbData, uint32* pulSize, uint32 dwReserved) mut => VT.[Friend]GetSerializedState(&this, ppbData, pulSize, dwReserved);

	public HRESULT SetSerializedState(uint8* pbData, uint32 ulSize, uint32 dwReserved) mut => VT.[Friend]SetSerializedState(&this, pbData, ulSize, dwReserved);
}

[CRepr]struct ISpRecognizer2 : IUnknown
{
	public new const Guid IID = .(0x8fc6d974, 0xc81e, 0x4098, 0x93, 0xc5, 0x01, 0x47, 0xf6, 0x1e, 0xd4, 0xd3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpPhrase* pPhrase, uint32 dwCompareFlags) EmulateRecognitionEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fDoingTraining, BOOL fAdaptFromTrainingData) SetTrainingState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResetAcousticModelAdaptation;
	}


	public HRESULT EmulateRecognitionEx(ISpPhrase* pPhrase, uint32 dwCompareFlags) mut => VT.[Friend]EmulateRecognitionEx(&this, pPhrase, dwCompareFlags);

	public HRESULT SetTrainingState(BOOL fDoingTraining, BOOL fAdaptFromTrainingData) mut => VT.[Friend]SetTrainingState(&this, fDoingTraining, fAdaptFromTrainingData);

	public HRESULT ResetAcousticModelAdaptation() mut => VT.[Friend]ResetAcousticModelAdaptation(&this);
}

[CRepr]struct ISpEnginePronunciation : IUnknown
{
	public new const Guid IID = .(0xc360ce4b, 0x76d1, 0x4214, 0xad, 0x68, 0x52, 0x65, 0x7d, 0x50, 0x83, 0xda);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszWord, PWSTR pszLeftContext, PWSTR pszRightContext, uint16 LangID, SPNORMALIZATIONLIST* pNormalizationList) Normalize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszWord, PWSTR pszLeftContext, PWSTR pszRightContext, uint16 LangID, SPWORDPRONUNCIATIONLIST* pEnginePronunciationList) GetPronunciations;
	}


	public HRESULT Normalize(PWSTR pszWord, PWSTR pszLeftContext, PWSTR pszRightContext, uint16 LangID, SPNORMALIZATIONLIST* pNormalizationList) mut => VT.[Friend]Normalize(&this, pszWord, pszLeftContext, pszRightContext, LangID, pNormalizationList);

	public HRESULT GetPronunciations(PWSTR pszWord, PWSTR pszLeftContext, PWSTR pszRightContext, uint16 LangID, SPWORDPRONUNCIATIONLIST* pEnginePronunciationList) mut => VT.[Friend]GetPronunciations(&this, pszWord, pszLeftContext, pszRightContext, LangID, pEnginePronunciationList);
}

[CRepr]struct ISpDisplayAlternates : IUnknown
{
	public new const Guid IID = .(0xc8d7c7e2, 0x0dde, 0x44b7, 0xaf, 0xe3, 0xb0, 0xc9, 0x91, 0xfb, 0xeb, 0x5e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPDISPLAYPHRASE* pPhrase, uint32 cRequestCount, SPDISPLAYPHRASE** ppCoMemPhrases, uint32* pcPhrasesReturned) GetDisplayAlternates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulTrailSpace) SetFullStopTrailSpace;
	}


	public HRESULT GetDisplayAlternates(SPDISPLAYPHRASE* pPhrase, uint32 cRequestCount, SPDISPLAYPHRASE** ppCoMemPhrases, uint32* pcPhrasesReturned) mut => VT.[Friend]GetDisplayAlternates(&this, pPhrase, cRequestCount, ppCoMemPhrases, pcPhrasesReturned);

	public HRESULT SetFullStopTrailSpace(uint32 ulTrailSpace) mut => VT.[Friend]SetFullStopTrailSpace(&this, ulTrailSpace);
}

[CRepr]struct ISpeechDataKey : IDispatch
{
	public new const Guid IID = .(0xce17c09b, 0x4efa, 0x44d5, 0xa4, 0xc9, 0x59, 0xd9, 0x58, 0x5a, 0xb0, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ValueName, VARIANT Value) SetBinaryValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ValueName, VARIANT* Value) GetBinaryValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ValueName, BSTR Value) SetStringValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ValueName, BSTR* Value) GetStringValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ValueName, int32 Value) SetLongValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ValueName, int32* Value) GetLongValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR SubKeyName, ISpeechDataKey** SubKey) OpenKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR SubKeyName, ISpeechDataKey** SubKey) CreateKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR SubKeyName) DeleteKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ValueName) DeleteValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, BSTR* SubKeyName) EnumKeys;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, BSTR* ValueName) EnumValues;
	}


	public HRESULT SetBinaryValue(BSTR ValueName, VARIANT Value) mut => VT.[Friend]SetBinaryValue(&this, ValueName, Value);

	public HRESULT GetBinaryValue(BSTR ValueName, VARIANT* Value) mut => VT.[Friend]GetBinaryValue(&this, ValueName, Value);

	public HRESULT SetStringValue(BSTR ValueName, BSTR Value) mut => VT.[Friend]SetStringValue(&this, ValueName, Value);

	public HRESULT GetStringValue(BSTR ValueName, BSTR* Value) mut => VT.[Friend]GetStringValue(&this, ValueName, Value);

	public HRESULT SetLongValue(BSTR ValueName, int32 Value) mut => VT.[Friend]SetLongValue(&this, ValueName, Value);

	public HRESULT GetLongValue(BSTR ValueName, int32* Value) mut => VT.[Friend]GetLongValue(&this, ValueName, Value);

	public HRESULT OpenKey(BSTR SubKeyName, ISpeechDataKey** SubKey) mut => VT.[Friend]OpenKey(&this, SubKeyName, SubKey);

	public HRESULT CreateKey(BSTR SubKeyName, ISpeechDataKey** SubKey) mut => VT.[Friend]CreateKey(&this, SubKeyName, SubKey);

	public HRESULT DeleteKey(BSTR SubKeyName) mut => VT.[Friend]DeleteKey(&this, SubKeyName);

	public HRESULT DeleteValue(BSTR ValueName) mut => VT.[Friend]DeleteValue(&this, ValueName);

	public HRESULT EnumKeys(int32 Index, BSTR* SubKeyName) mut => VT.[Friend]EnumKeys(&this, Index, SubKeyName);

	public HRESULT EnumValues(int32 Index, BSTR* ValueName) mut => VT.[Friend]EnumValues(&this, Index, ValueName);
}

[CRepr]struct ISpeechObjectToken : IDispatch
{
	public new const Guid IID = .(0xc74a3adc, 0xb727, 0x4500, 0xa8, 0x4a, 0xb5, 0x26, 0x72, 0x1c, 0x8b, 0x8c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* ObjectId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechDataKey** DataKey) get_DataKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechObjectTokenCategory** Category) get_Category;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Locale, BSTR* Description) GetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Id, BSTR CategoryID, int16 CreateIfNotExist) SetId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR AttributeName, BSTR* AttributeValue) GetAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, SpeechTokenContext ClsContext, IUnknown** Object) CreateInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ObjectStorageCLSID) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ObjectStorageCLSID, BSTR KeyName, BSTR FileName, SpeechTokenShellFolder Folder, BSTR* FilePath) GetStorageFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ObjectStorageCLSID, BSTR KeyName, int16 DeleteFile) RemoveStorageFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR TypeOfUI, VARIANT* ExtraData, IUnknown* Object, int16* Supported) IsUISupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 hWnd, BSTR Title, BSTR TypeOfUI, VARIANT* ExtraData, IUnknown* Object) DisplayUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Attributes, int16* Matches) MatchesAttributes;
	}


	public HRESULT get_Id(BSTR* ObjectId) mut => VT.[Friend]get_Id(&this, ObjectId);

	public HRESULT get_DataKey(ISpeechDataKey** DataKey) mut => VT.[Friend]get_DataKey(&this, DataKey);

	public HRESULT get_Category(ISpeechObjectTokenCategory** Category) mut => VT.[Friend]get_Category(&this, Category);

	public HRESULT GetDescription(int32 Locale, BSTR* Description) mut => VT.[Friend]GetDescription(&this, Locale, Description);

	public HRESULT SetId(BSTR Id, BSTR CategoryID, int16 CreateIfNotExist) mut => VT.[Friend]SetId(&this, Id, CategoryID, CreateIfNotExist);

	public HRESULT GetAttribute(BSTR AttributeName, BSTR* AttributeValue) mut => VT.[Friend]GetAttribute(&this, AttributeName, AttributeValue);

	public HRESULT CreateInstance(IUnknown* pUnkOuter, SpeechTokenContext ClsContext, IUnknown** Object) mut => VT.[Friend]CreateInstance(&this, pUnkOuter, ClsContext, Object);

	public HRESULT Remove(BSTR ObjectStorageCLSID) mut => VT.[Friend]Remove(&this, ObjectStorageCLSID);

	public HRESULT GetStorageFileName(BSTR ObjectStorageCLSID, BSTR KeyName, BSTR FileName, SpeechTokenShellFolder Folder, BSTR* FilePath) mut => VT.[Friend]GetStorageFileName(&this, ObjectStorageCLSID, KeyName, FileName, Folder, FilePath);

	public HRESULT RemoveStorageFileName(BSTR ObjectStorageCLSID, BSTR KeyName, int16 DeleteFile) mut => VT.[Friend]RemoveStorageFileName(&this, ObjectStorageCLSID, KeyName, DeleteFile);

	public HRESULT IsUISupported(BSTR TypeOfUI, VARIANT* ExtraData, IUnknown* Object, int16* Supported) mut => VT.[Friend]IsUISupported(&this, TypeOfUI, ExtraData, Object, Supported);

	public HRESULT DisplayUI(int32 hWnd, BSTR Title, BSTR TypeOfUI, VARIANT* ExtraData, IUnknown* Object) mut => VT.[Friend]DisplayUI(&this, hWnd, Title, TypeOfUI, ExtraData, Object);

	public HRESULT MatchesAttributes(BSTR Attributes, int16* Matches) mut => VT.[Friend]MatchesAttributes(&this, Attributes, Matches);
}

[CRepr]struct ISpeechObjectTokens : IDispatch
{
	public new const Guid IID = .(0x9285b776, 0x2e7b, 0x4bc0, 0xb5, 0x3e, 0x58, 0x0e, 0xb6, 0xfa, 0x96, 0x7f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ISpeechObjectToken** Token) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnumVARIANT) get__NewEnum;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT Item(int32 Index, ISpeechObjectToken** Token) mut => VT.[Friend]Item(&this, Index, Token);

	public HRESULT get__NewEnum(IUnknown** ppEnumVARIANT) mut => VT.[Friend]get__NewEnum(&this, ppEnumVARIANT);
}

[CRepr]struct ISpeechObjectTokenCategory : IDispatch
{
	public new const Guid IID = .(0xca7eac50, 0x2d01, 0x4145, 0x86, 0xd4, 0x5a, 0xe7, 0xd7, 0x0f, 0x44, 0x69);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Id) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR TokenId) put_Default;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* TokenId) get_Default;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Id, int16 CreateIfNotExist) SetId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechDataKeyLocation Location, ISpeechDataKey** DataKey) GetDataKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR RequiredAttributes, BSTR OptionalAttributes, ISpeechObjectTokens** Tokens) EnumerateTokens;
	}


	public HRESULT get_Id(BSTR* Id) mut => VT.[Friend]get_Id(&this, Id);

	public HRESULT put_Default(BSTR TokenId) mut => VT.[Friend]put_Default(&this, TokenId);

	public HRESULT get_Default(BSTR* TokenId) mut => VT.[Friend]get_Default(&this, TokenId);

	public HRESULT SetId(BSTR Id, int16 CreateIfNotExist) mut => VT.[Friend]SetId(&this, Id, CreateIfNotExist);

	public HRESULT GetDataKey(SpeechDataKeyLocation Location, ISpeechDataKey** DataKey) mut => VT.[Friend]GetDataKey(&this, Location, DataKey);

	public HRESULT EnumerateTokens(BSTR RequiredAttributes, BSTR OptionalAttributes, ISpeechObjectTokens** Tokens) mut => VT.[Friend]EnumerateTokens(&this, RequiredAttributes, OptionalAttributes, Tokens);
}

[CRepr]struct ISpeechAudioBufferInfo : IDispatch
{
	public new const Guid IID = .(0x11b103d8, 0x1142, 0x4edf, 0xa0, 0x93, 0x82, 0xfb, 0x39, 0x15, 0xf8, 0xcc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* MinNotification) get_MinNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 MinNotification) put_MinNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* BufferSize) get_BufferSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 BufferSize) put_BufferSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* EventBias) get_EventBias;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 EventBias) put_EventBias;
	}


	public HRESULT get_MinNotification(int32* MinNotification) mut => VT.[Friend]get_MinNotification(&this, MinNotification);

	public HRESULT put_MinNotification(int32 MinNotification) mut => VT.[Friend]put_MinNotification(&this, MinNotification);

	public HRESULT get_BufferSize(int32* BufferSize) mut => VT.[Friend]get_BufferSize(&this, BufferSize);

	public HRESULT put_BufferSize(int32 BufferSize) mut => VT.[Friend]put_BufferSize(&this, BufferSize);

	public HRESULT get_EventBias(int32* EventBias) mut => VT.[Friend]get_EventBias(&this, EventBias);

	public HRESULT put_EventBias(int32 EventBias) mut => VT.[Friend]put_EventBias(&this, EventBias);
}

[CRepr]struct ISpeechAudioStatus : IDispatch
{
	public new const Guid IID = .(0xc62d9c91, 0x7458, 0x47f6, 0x86, 0x2d, 0x1e, 0xf8, 0x6f, 0xb0, 0xb2, 0x78);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* FreeBufferSpace) get_FreeBufferSpace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* NonBlockingIO) get_NonBlockingIO;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechAudioState* State) get_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* CurrentSeekPosition) get_CurrentSeekPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* CurrentDevicePosition) get_CurrentDevicePosition;
	}


	public HRESULT get_FreeBufferSpace(int32* FreeBufferSpace) mut => VT.[Friend]get_FreeBufferSpace(&this, FreeBufferSpace);

	public HRESULT get_NonBlockingIO(int32* NonBlockingIO) mut => VT.[Friend]get_NonBlockingIO(&this, NonBlockingIO);

	public HRESULT get_State(SpeechAudioState* State) mut => VT.[Friend]get_State(&this, State);

	public HRESULT get_CurrentSeekPosition(VARIANT* CurrentSeekPosition) mut => VT.[Friend]get_CurrentSeekPosition(&this, CurrentSeekPosition);

	public HRESULT get_CurrentDevicePosition(VARIANT* CurrentDevicePosition) mut => VT.[Friend]get_CurrentDevicePosition(&this, CurrentDevicePosition);
}

[CRepr]struct ISpeechAudioFormat : IDispatch
{
	public new const Guid IID = .(0xe6e9c590, 0x3e18, 0x40e3, 0x82, 0x99, 0x06, 0x1f, 0x98, 0xbd, 0xe7, 0xc7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechAudioFormatType* AudioFormat) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechAudioFormatType AudioFormat) put_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Guid) get_Guid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Guid) put_Guid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechWaveFormatEx** SpeechWaveFormatEx) GetWaveFormatEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechWaveFormatEx* SpeechWaveFormatEx) SetWaveFormatEx;
	}


	public HRESULT get_Type(SpeechAudioFormatType* AudioFormat) mut => VT.[Friend]get_Type(&this, AudioFormat);

	public HRESULT put_Type(SpeechAudioFormatType AudioFormat) mut => VT.[Friend]put_Type(&this, AudioFormat);

	public HRESULT get_Guid(BSTR* Guid) mut => VT.[Friend]get_Guid(&this, Guid);

	public HRESULT put_Guid(BSTR Guid) mut => VT.[Friend]put_Guid(&this, Guid);

	public HRESULT GetWaveFormatEx(ISpeechWaveFormatEx** SpeechWaveFormatEx) mut => VT.[Friend]GetWaveFormatEx(&this, SpeechWaveFormatEx);

	public HRESULT SetWaveFormatEx(ISpeechWaveFormatEx* SpeechWaveFormatEx) mut => VT.[Friend]SetWaveFormatEx(&this, SpeechWaveFormatEx);
}

[CRepr]struct ISpeechWaveFormatEx : IDispatch
{
	public new const Guid IID = .(0x7a1ef0d5, 0x1581, 0x4741, 0x88, 0xe4, 0x20, 0x9a, 0x49, 0xf1, 0x1a, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* FormatTag) get_FormatTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 FormatTag) put_FormatTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Channels) get_Channels;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Channels) put_Channels;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* SamplesPerSec) get_SamplesPerSec;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 SamplesPerSec) put_SamplesPerSec;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* AvgBytesPerSec) get_AvgBytesPerSec;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 AvgBytesPerSec) put_AvgBytesPerSec;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* BlockAlign) get_BlockAlign;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 BlockAlign) put_BlockAlign;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* BitsPerSample) get_BitsPerSample;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 BitsPerSample) put_BitsPerSample;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* ExtraData) get_ExtraData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT ExtraData) put_ExtraData;
	}


	public HRESULT get_FormatTag(int16* FormatTag) mut => VT.[Friend]get_FormatTag(&this, FormatTag);

	public HRESULT put_FormatTag(int16 FormatTag) mut => VT.[Friend]put_FormatTag(&this, FormatTag);

	public HRESULT get_Channels(int16* Channels) mut => VT.[Friend]get_Channels(&this, Channels);

	public HRESULT put_Channels(int16 Channels) mut => VT.[Friend]put_Channels(&this, Channels);

	public HRESULT get_SamplesPerSec(int32* SamplesPerSec) mut => VT.[Friend]get_SamplesPerSec(&this, SamplesPerSec);

	public HRESULT put_SamplesPerSec(int32 SamplesPerSec) mut => VT.[Friend]put_SamplesPerSec(&this, SamplesPerSec);

	public HRESULT get_AvgBytesPerSec(int32* AvgBytesPerSec) mut => VT.[Friend]get_AvgBytesPerSec(&this, AvgBytesPerSec);

	public HRESULT put_AvgBytesPerSec(int32 AvgBytesPerSec) mut => VT.[Friend]put_AvgBytesPerSec(&this, AvgBytesPerSec);

	public HRESULT get_BlockAlign(int16* BlockAlign) mut => VT.[Friend]get_BlockAlign(&this, BlockAlign);

	public HRESULT put_BlockAlign(int16 BlockAlign) mut => VT.[Friend]put_BlockAlign(&this, BlockAlign);

	public HRESULT get_BitsPerSample(int16* BitsPerSample) mut => VT.[Friend]get_BitsPerSample(&this, BitsPerSample);

	public HRESULT put_BitsPerSample(int16 BitsPerSample) mut => VT.[Friend]put_BitsPerSample(&this, BitsPerSample);

	public HRESULT get_ExtraData(VARIANT* ExtraData) mut => VT.[Friend]get_ExtraData(&this, ExtraData);

	public HRESULT put_ExtraData(VARIANT ExtraData) mut => VT.[Friend]put_ExtraData(&this, ExtraData);
}

[CRepr]struct ISpeechBaseStream : IDispatch
{
	public new const Guid IID = .(0x6450336f, 0x7d49, 0x4ced, 0x80, 0x97, 0x49, 0xd6, 0xde, 0xe3, 0x72, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechAudioFormat** AudioFormat) get_Format;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechAudioFormat* AudioFormat) putref_Format;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Buffer, int32 NumberOfBytes, int32* BytesRead) Read;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Buffer, int32* BytesWritten) Write;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Position, SpeechStreamSeekPositionType Origin, VARIANT* NewPosition) Seek;
	}


	public HRESULT get_Format(ISpeechAudioFormat** AudioFormat) mut => VT.[Friend]get_Format(&this, AudioFormat);

	public HRESULT putref_Format(ISpeechAudioFormat* AudioFormat) mut => VT.[Friend]putref_Format(&this, AudioFormat);

	public HRESULT Read(VARIANT* Buffer, int32 NumberOfBytes, int32* BytesRead) mut => VT.[Friend]Read(&this, Buffer, NumberOfBytes, BytesRead);

	public HRESULT Write(VARIANT Buffer, int32* BytesWritten) mut => VT.[Friend]Write(&this, Buffer, BytesWritten);

	public HRESULT Seek(VARIANT Position, SpeechStreamSeekPositionType Origin, VARIANT* NewPosition) mut => VT.[Friend]Seek(&this, Position, Origin, NewPosition);
}

[CRepr]struct ISpeechFileStream : ISpeechBaseStream
{
	public new const Guid IID = .(0xaf67f125, 0xab39, 0x4e93, 0xb4, 0xa2, 0xcc, 0x2e, 0x66, 0xe1, 0x82, 0xa7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpeechBaseStream.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR FileName, SpeechStreamFileMode FileMode, int16 DoEvents) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
	}


	public HRESULT Open(BSTR FileName, SpeechStreamFileMode FileMode, int16 DoEvents) mut => VT.[Friend]Open(&this, FileName, FileMode, DoEvents);

	public HRESULT Close() mut => VT.[Friend]Close(&this);
}

[CRepr]struct ISpeechMemoryStream : ISpeechBaseStream
{
	public new const Guid IID = .(0xeeb14b68, 0x808b, 0x4abe, 0xa5, 0xea, 0xb5, 0x1d, 0xa7, 0x58, 0x80, 0x08);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpeechBaseStream.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Data) SetData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pData) GetData;
	}


	public HRESULT SetData(VARIANT Data) mut => VT.[Friend]SetData(&this, Data);

	public HRESULT GetData(VARIANT* pData) mut => VT.[Friend]GetData(&this, pData);
}

[CRepr]struct ISpeechCustomStream : ISpeechBaseStream
{
	public new const Guid IID = .(0x1a9e9f4f, 0x104f, 0x4db8, 0xa1, 0x15, 0xef, 0xd7, 0xfd, 0x0c, 0x97, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpeechBaseStream.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppUnkStream) get_BaseStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkStream) putref_BaseStream;
	}


	public HRESULT get_BaseStream(IUnknown** ppUnkStream) mut => VT.[Friend]get_BaseStream(&this, ppUnkStream);

	public HRESULT putref_BaseStream(IUnknown* pUnkStream) mut => VT.[Friend]putref_BaseStream(&this, pUnkStream);
}

[CRepr]struct ISpeechAudio : ISpeechBaseStream
{
	public new const Guid IID = .(0xcff8e175, 0x019e, 0x11d3, 0xa0, 0x8e, 0x00, 0xc0, 0x4f, 0x8e, 0xf9, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpeechBaseStream.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechAudioStatus** Status) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechAudioBufferInfo** BufferInfo) get_BufferInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechAudioFormat** StreamFormat) get_DefaultFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Volume) get_Volume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Volume) put_Volume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* BufferNotifySize) get_BufferNotifySize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 BufferNotifySize) put_BufferNotifySize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* EventHandle) get_EventHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechAudioState State) SetState;
	}


	public HRESULT get_Status(ISpeechAudioStatus** Status) mut => VT.[Friend]get_Status(&this, Status);

	public HRESULT get_BufferInfo(ISpeechAudioBufferInfo** BufferInfo) mut => VT.[Friend]get_BufferInfo(&this, BufferInfo);

	public HRESULT get_DefaultFormat(ISpeechAudioFormat** StreamFormat) mut => VT.[Friend]get_DefaultFormat(&this, StreamFormat);

	public HRESULT get_Volume(int32* Volume) mut => VT.[Friend]get_Volume(&this, Volume);

	public HRESULT put_Volume(int32 Volume) mut => VT.[Friend]put_Volume(&this, Volume);

	public HRESULT get_BufferNotifySize(int32* BufferNotifySize) mut => VT.[Friend]get_BufferNotifySize(&this, BufferNotifySize);

	public HRESULT put_BufferNotifySize(int32 BufferNotifySize) mut => VT.[Friend]put_BufferNotifySize(&this, BufferNotifySize);

	public HRESULT get_EventHandle(int32* EventHandle) mut => VT.[Friend]get_EventHandle(&this, EventHandle);

	public HRESULT SetState(SpeechAudioState State) mut => VT.[Friend]SetState(&this, State);
}

[CRepr]struct ISpeechMMSysAudio : ISpeechAudio
{
	public new const Guid IID = .(0x3c76af6d, 0x1fd7, 0x4831, 0x81, 0xd1, 0x3b, 0x71, 0xd5, 0xa1, 0x3c, 0x44);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpeechAudio.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* DeviceId) get_DeviceId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 DeviceId) put_DeviceId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* LineId) get_LineId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 LineId) put_LineId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Handle) get_MMHandle;
	}


	public HRESULT get_DeviceId(int32* DeviceId) mut => VT.[Friend]get_DeviceId(&this, DeviceId);

	public HRESULT put_DeviceId(int32 DeviceId) mut => VT.[Friend]put_DeviceId(&this, DeviceId);

	public HRESULT get_LineId(int32* LineId) mut => VT.[Friend]get_LineId(&this, LineId);

	public HRESULT put_LineId(int32 LineId) mut => VT.[Friend]put_LineId(&this, LineId);

	public HRESULT get_MMHandle(int32* Handle) mut => VT.[Friend]get_MMHandle(&this, Handle);
}

[CRepr]struct ISpeechVoice : IDispatch
{
	public new const Guid IID = .(0x269316d8, 0x57bd, 0x11d2, 0x9e, 0xee, 0x00, 0xc0, 0x4f, 0x79, 0x73, 0x96);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechVoiceStatus** Status) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechObjectToken** Voice) get_Voice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechObjectToken* Voice) putref_Voice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechObjectToken** AudioOutput) get_AudioOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechObjectToken* AudioOutput) putref_AudioOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechBaseStream** AudioOutputStream) get_AudioOutputStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechBaseStream* AudioOutputStream) putref_AudioOutputStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Rate) get_Rate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Rate) put_Rate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Volume) get_Volume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Volume) put_Volume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Allow) put_AllowAudioOutputFormatChangesOnNextSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Allow) get_AllowAudioOutputFormatChangesOnNextSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechVoiceEvents* EventInterestFlags) get_EventInterests;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechVoiceEvents EventInterestFlags) put_EventInterests;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechVoicePriority Priority) put_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechVoicePriority* Priority) get_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechVoiceEvents Boundary) put_AlertBoundary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechVoiceEvents* Boundary) get_AlertBoundary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 msTimeout) put_SynchronousSpeakTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* msTimeout) get_SynchronousSpeakTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Text, SpeechVoiceSpeakFlags Flags, int32* StreamNumber) Speak;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechBaseStream* Stream, SpeechVoiceSpeakFlags Flags, int32* StreamNumber) SpeakStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Type, int32 NumItems, int32* NumSkipped) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR RequiredAttributes, BSTR OptionalAttributes, ISpeechObjectTokens** ObjectTokens) GetVoices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR RequiredAttributes, BSTR OptionalAttributes, ISpeechObjectTokens** ObjectTokens) GetAudioOutputs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 msTimeout, int16* Done) WaitUntilDone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Handle) SpeakCompleteEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR TypeOfUI, VARIANT* ExtraData, int16* Supported) IsUISupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 hWndParent, BSTR Title, BSTR TypeOfUI, VARIANT* ExtraData) DisplayUI;
	}


	public HRESULT get_Status(ISpeechVoiceStatus** Status) mut => VT.[Friend]get_Status(&this, Status);

	public HRESULT get_Voice(ISpeechObjectToken** Voice) mut => VT.[Friend]get_Voice(&this, Voice);

	public HRESULT putref_Voice(ISpeechObjectToken* Voice) mut => VT.[Friend]putref_Voice(&this, Voice);

	public HRESULT get_AudioOutput(ISpeechObjectToken** AudioOutput) mut => VT.[Friend]get_AudioOutput(&this, AudioOutput);

	public HRESULT putref_AudioOutput(ISpeechObjectToken* AudioOutput) mut => VT.[Friend]putref_AudioOutput(&this, AudioOutput);

	public HRESULT get_AudioOutputStream(ISpeechBaseStream** AudioOutputStream) mut => VT.[Friend]get_AudioOutputStream(&this, AudioOutputStream);

	public HRESULT putref_AudioOutputStream(ISpeechBaseStream* AudioOutputStream) mut => VT.[Friend]putref_AudioOutputStream(&this, AudioOutputStream);

	public HRESULT get_Rate(int32* Rate) mut => VT.[Friend]get_Rate(&this, Rate);

	public HRESULT put_Rate(int32 Rate) mut => VT.[Friend]put_Rate(&this, Rate);

	public HRESULT get_Volume(int32* Volume) mut => VT.[Friend]get_Volume(&this, Volume);

	public HRESULT put_Volume(int32 Volume) mut => VT.[Friend]put_Volume(&this, Volume);

	public HRESULT put_AllowAudioOutputFormatChangesOnNextSet(int16 Allow) mut => VT.[Friend]put_AllowAudioOutputFormatChangesOnNextSet(&this, Allow);

	public HRESULT get_AllowAudioOutputFormatChangesOnNextSet(int16* Allow) mut => VT.[Friend]get_AllowAudioOutputFormatChangesOnNextSet(&this, Allow);

	public HRESULT get_EventInterests(SpeechVoiceEvents* EventInterestFlags) mut => VT.[Friend]get_EventInterests(&this, EventInterestFlags);

	public HRESULT put_EventInterests(SpeechVoiceEvents EventInterestFlags) mut => VT.[Friend]put_EventInterests(&this, EventInterestFlags);

	public HRESULT put_Priority(SpeechVoicePriority Priority) mut => VT.[Friend]put_Priority(&this, Priority);

	public HRESULT get_Priority(SpeechVoicePriority* Priority) mut => VT.[Friend]get_Priority(&this, Priority);

	public HRESULT put_AlertBoundary(SpeechVoiceEvents Boundary) mut => VT.[Friend]put_AlertBoundary(&this, Boundary);

	public HRESULT get_AlertBoundary(SpeechVoiceEvents* Boundary) mut => VT.[Friend]get_AlertBoundary(&this, Boundary);

	public HRESULT put_SynchronousSpeakTimeout(int32 msTimeout) mut => VT.[Friend]put_SynchronousSpeakTimeout(&this, msTimeout);

	public HRESULT get_SynchronousSpeakTimeout(int32* msTimeout) mut => VT.[Friend]get_SynchronousSpeakTimeout(&this, msTimeout);

	public HRESULT Speak(BSTR Text, SpeechVoiceSpeakFlags Flags, int32* StreamNumber) mut => VT.[Friend]Speak(&this, Text, Flags, StreamNumber);

	public HRESULT SpeakStream(ISpeechBaseStream* Stream, SpeechVoiceSpeakFlags Flags, int32* StreamNumber) mut => VT.[Friend]SpeakStream(&this, Stream, Flags, StreamNumber);

	public HRESULT Pause() mut => VT.[Friend]Pause(&this);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);

	public HRESULT Skip(BSTR Type, int32 NumItems, int32* NumSkipped) mut => VT.[Friend]Skip(&this, Type, NumItems, NumSkipped);

	public HRESULT GetVoices(BSTR RequiredAttributes, BSTR OptionalAttributes, ISpeechObjectTokens** ObjectTokens) mut => VT.[Friend]GetVoices(&this, RequiredAttributes, OptionalAttributes, ObjectTokens);

	public HRESULT GetAudioOutputs(BSTR RequiredAttributes, BSTR OptionalAttributes, ISpeechObjectTokens** ObjectTokens) mut => VT.[Friend]GetAudioOutputs(&this, RequiredAttributes, OptionalAttributes, ObjectTokens);

	public HRESULT WaitUntilDone(int32 msTimeout, int16* Done) mut => VT.[Friend]WaitUntilDone(&this, msTimeout, Done);

	public HRESULT SpeakCompleteEvent(int32* Handle) mut => VT.[Friend]SpeakCompleteEvent(&this, Handle);

	public HRESULT IsUISupported(BSTR TypeOfUI, VARIANT* ExtraData, int16* Supported) mut => VT.[Friend]IsUISupported(&this, TypeOfUI, ExtraData, Supported);

	public HRESULT DisplayUI(int32 hWndParent, BSTR Title, BSTR TypeOfUI, VARIANT* ExtraData) mut => VT.[Friend]DisplayUI(&this, hWndParent, Title, TypeOfUI, ExtraData);
}

[CRepr]struct ISpeechVoiceStatus : IDispatch
{
	public new const Guid IID = .(0x8be47b07, 0x57f6, 0x11d2, 0x9e, 0xee, 0x00, 0xc0, 0x4f, 0x79, 0x73, 0x96);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* StreamNumber) get_CurrentStreamNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* StreamNumber) get_LastStreamNumberQueued;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* HResult) get_LastHResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechRunState* State) get_RunningState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Position) get_InputWordPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Length) get_InputWordLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Position) get_InputSentencePosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Length) get_InputSentenceLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Bookmark) get_LastBookmark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* BookmarkId) get_LastBookmarkId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* PhoneId) get_PhonemeId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* VisemeId) get_VisemeId;
	}


	public HRESULT get_CurrentStreamNumber(int32* StreamNumber) mut => VT.[Friend]get_CurrentStreamNumber(&this, StreamNumber);

	public HRESULT get_LastStreamNumberQueued(int32* StreamNumber) mut => VT.[Friend]get_LastStreamNumberQueued(&this, StreamNumber);

	public HRESULT get_LastHResult(int32* HResult) mut => VT.[Friend]get_LastHResult(&this, HResult);

	public HRESULT get_RunningState(SpeechRunState* State) mut => VT.[Friend]get_RunningState(&this, State);

	public HRESULT get_InputWordPosition(int32* Position) mut => VT.[Friend]get_InputWordPosition(&this, Position);

	public HRESULT get_InputWordLength(int32* Length) mut => VT.[Friend]get_InputWordLength(&this, Length);

	public HRESULT get_InputSentencePosition(int32* Position) mut => VT.[Friend]get_InputSentencePosition(&this, Position);

	public HRESULT get_InputSentenceLength(int32* Length) mut => VT.[Friend]get_InputSentenceLength(&this, Length);

	public HRESULT get_LastBookmark(BSTR* Bookmark) mut => VT.[Friend]get_LastBookmark(&this, Bookmark);

	public HRESULT get_LastBookmarkId(int32* BookmarkId) mut => VT.[Friend]get_LastBookmarkId(&this, BookmarkId);

	public HRESULT get_PhonemeId(int16* PhoneId) mut => VT.[Friend]get_PhonemeId(&this, PhoneId);

	public HRESULT get_VisemeId(int16* VisemeId) mut => VT.[Friend]get_VisemeId(&this, VisemeId);
}

[CRepr]struct _ISpeechVoiceEvents : IDispatch
{
	public new const Guid IID = .(0xa372acd1, 0x3bef, 0x4bbd, 0x8f, 0xfb, 0xcb, 0x3e, 0x2b, 0x41, 0x6a, 0xf8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct ISpeechRecognizer : IDispatch
{
	public new const Guid IID = .(0x2d5f1c0c, 0xbd75, 0x4b08, 0x94, 0x78, 0x3b, 0x11, 0xfe, 0xa2, 0x58, 0x6c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechObjectToken* Recognizer) putref_Recognizer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechObjectToken** Recognizer) get_Recognizer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Allow) put_AllowAudioInputFormatChangesOnNextSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Allow) get_AllowAudioInputFormatChangesOnNextSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechObjectToken* AudioInput) putref_AudioInput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechObjectToken** AudioInput) get_AudioInput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechBaseStream* AudioInputStream) putref_AudioInputStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechBaseStream** AudioInputStream) get_AudioInputStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Shared) get_IsShared;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechRecognizerState State) put_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechRecognizerState* State) get_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechRecognizerStatus** Status) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechObjectToken* Profile) putref_Profile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechObjectToken** Profile) get_Profile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT TextElements, VARIANT* ElementDisplayAttributes, int32 LanguageId) EmulateRecognition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechRecoContext** NewContext) CreateRecoContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechFormatType Type, ISpeechAudioFormat** Format) GetFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Name, int32 Value, int16* Supported) SetPropertyNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Name, int32* Value, int16* Supported) GetPropertyNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Name, BSTR Value, int16* Supported) SetPropertyString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Name, BSTR* Value, int16* Supported) GetPropertyString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR TypeOfUI, VARIANT* ExtraData, int16* Supported) IsUISupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 hWndParent, BSTR Title, BSTR TypeOfUI, VARIANT* ExtraData) DisplayUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR RequiredAttributes, BSTR OptionalAttributes, ISpeechObjectTokens** ObjectTokens) GetRecognizers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR RequiredAttributes, BSTR OptionalAttributes, ISpeechObjectTokens** ObjectTokens) GetAudioInputs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR RequiredAttributes, BSTR OptionalAttributes, ISpeechObjectTokens** ObjectTokens) GetProfiles;
	}


	public HRESULT putref_Recognizer(ISpeechObjectToken* Recognizer) mut => VT.[Friend]putref_Recognizer(&this, Recognizer);

	public HRESULT get_Recognizer(ISpeechObjectToken** Recognizer) mut => VT.[Friend]get_Recognizer(&this, Recognizer);

	public HRESULT put_AllowAudioInputFormatChangesOnNextSet(int16 Allow) mut => VT.[Friend]put_AllowAudioInputFormatChangesOnNextSet(&this, Allow);

	public HRESULT get_AllowAudioInputFormatChangesOnNextSet(int16* Allow) mut => VT.[Friend]get_AllowAudioInputFormatChangesOnNextSet(&this, Allow);

	public HRESULT putref_AudioInput(ISpeechObjectToken* AudioInput) mut => VT.[Friend]putref_AudioInput(&this, AudioInput);

	public HRESULT get_AudioInput(ISpeechObjectToken** AudioInput) mut => VT.[Friend]get_AudioInput(&this, AudioInput);

	public HRESULT putref_AudioInputStream(ISpeechBaseStream* AudioInputStream) mut => VT.[Friend]putref_AudioInputStream(&this, AudioInputStream);

	public HRESULT get_AudioInputStream(ISpeechBaseStream** AudioInputStream) mut => VT.[Friend]get_AudioInputStream(&this, AudioInputStream);

	public HRESULT get_IsShared(int16* Shared) mut => VT.[Friend]get_IsShared(&this, Shared);

	public HRESULT put_State(SpeechRecognizerState State) mut => VT.[Friend]put_State(&this, State);

	public HRESULT get_State(SpeechRecognizerState* State) mut => VT.[Friend]get_State(&this, State);

	public HRESULT get_Status(ISpeechRecognizerStatus** Status) mut => VT.[Friend]get_Status(&this, Status);

	public HRESULT putref_Profile(ISpeechObjectToken* Profile) mut => VT.[Friend]putref_Profile(&this, Profile);

	public HRESULT get_Profile(ISpeechObjectToken** Profile) mut => VT.[Friend]get_Profile(&this, Profile);

	public HRESULT EmulateRecognition(VARIANT TextElements, VARIANT* ElementDisplayAttributes, int32 LanguageId) mut => VT.[Friend]EmulateRecognition(&this, TextElements, ElementDisplayAttributes, LanguageId);

	public HRESULT CreateRecoContext(ISpeechRecoContext** NewContext) mut => VT.[Friend]CreateRecoContext(&this, NewContext);

	public HRESULT GetFormat(SpeechFormatType Type, ISpeechAudioFormat** Format) mut => VT.[Friend]GetFormat(&this, Type, Format);

	public HRESULT SetPropertyNumber(BSTR Name, int32 Value, int16* Supported) mut => VT.[Friend]SetPropertyNumber(&this, Name, Value, Supported);

	public HRESULT GetPropertyNumber(BSTR Name, int32* Value, int16* Supported) mut => VT.[Friend]GetPropertyNumber(&this, Name, Value, Supported);

	public HRESULT SetPropertyString(BSTR Name, BSTR Value, int16* Supported) mut => VT.[Friend]SetPropertyString(&this, Name, Value, Supported);

	public HRESULT GetPropertyString(BSTR Name, BSTR* Value, int16* Supported) mut => VT.[Friend]GetPropertyString(&this, Name, Value, Supported);

	public HRESULT IsUISupported(BSTR TypeOfUI, VARIANT* ExtraData, int16* Supported) mut => VT.[Friend]IsUISupported(&this, TypeOfUI, ExtraData, Supported);

	public HRESULT DisplayUI(int32 hWndParent, BSTR Title, BSTR TypeOfUI, VARIANT* ExtraData) mut => VT.[Friend]DisplayUI(&this, hWndParent, Title, TypeOfUI, ExtraData);

	public HRESULT GetRecognizers(BSTR RequiredAttributes, BSTR OptionalAttributes, ISpeechObjectTokens** ObjectTokens) mut => VT.[Friend]GetRecognizers(&this, RequiredAttributes, OptionalAttributes, ObjectTokens);

	public HRESULT GetAudioInputs(BSTR RequiredAttributes, BSTR OptionalAttributes, ISpeechObjectTokens** ObjectTokens) mut => VT.[Friend]GetAudioInputs(&this, RequiredAttributes, OptionalAttributes, ObjectTokens);

	public HRESULT GetProfiles(BSTR RequiredAttributes, BSTR OptionalAttributes, ISpeechObjectTokens** ObjectTokens) mut => VT.[Friend]GetProfiles(&this, RequiredAttributes, OptionalAttributes, ObjectTokens);
}

[CRepr]struct ISpeechRecognizerStatus : IDispatch
{
	public new const Guid IID = .(0xbff9e781, 0x53ec, 0x484e, 0xbb, 0x8a, 0x0e, 0x1b, 0x55, 0x51, 0xe3, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechAudioStatus** AudioStatus) get_AudioStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pCurrentStreamPos) get_CurrentStreamPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* StreamNumber) get_CurrentStreamNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* NumberOfActiveRules) get_NumberOfActiveRules;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* ClsidEngine) get_ClsidEngine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* SupportedLanguages) get_SupportedLanguages;
	}


	public HRESULT get_AudioStatus(ISpeechAudioStatus** AudioStatus) mut => VT.[Friend]get_AudioStatus(&this, AudioStatus);

	public HRESULT get_CurrentStreamPosition(VARIANT* pCurrentStreamPos) mut => VT.[Friend]get_CurrentStreamPosition(&this, pCurrentStreamPos);

	public HRESULT get_CurrentStreamNumber(int32* StreamNumber) mut => VT.[Friend]get_CurrentStreamNumber(&this, StreamNumber);

	public HRESULT get_NumberOfActiveRules(int32* NumberOfActiveRules) mut => VT.[Friend]get_NumberOfActiveRules(&this, NumberOfActiveRules);

	public HRESULT get_ClsidEngine(BSTR* ClsidEngine) mut => VT.[Friend]get_ClsidEngine(&this, ClsidEngine);

	public HRESULT get_SupportedLanguages(VARIANT* SupportedLanguages) mut => VT.[Friend]get_SupportedLanguages(&this, SupportedLanguages);
}

[CRepr]struct ISpeechRecoContext : IDispatch
{
	public new const Guid IID = .(0x580aa49d, 0x7e1e, 0x4809, 0xb8, 0xe2, 0x57, 0xda, 0x80, 0x61, 0x04, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechRecognizer** Recognizer) get_Recognizer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechInterference* Interference) get_AudioInputInterferenceStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* UIType) get_RequestedUIType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechVoice* Voice) putref_Voice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechVoice** Voice) get_Voice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Allow) put_AllowVoiceFormatMatchingOnNextSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pAllow) get_AllowVoiceFormatMatchingOnNextSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechRecoEvents EventInterest) put_VoicePurgeEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechRecoEvents* EventInterest) get_VoicePurgeEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechRecoEvents EventInterest) put_EventInterests;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechRecoEvents* EventInterest) get_EventInterests;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 MaxAlternates) put_CmdMaxAlternates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* MaxAlternates) get_CmdMaxAlternates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechRecoContextState State) put_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechRecoContextState* State) get_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechRetainedAudioOptions Option) put_RetainedAudio;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechRetainedAudioOptions* Option) get_RetainedAudio;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechAudioFormat* Format) putref_RetainedAudioFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechAudioFormat** Format) get_RetainedAudioFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT GrammarId, ISpeechRecoGrammar** Grammar) CreateGrammar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* ResultBlock, ISpeechRecoResult** Result) CreateResultFromMemory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechBookmarkOptions Options, VARIANT StreamPos, VARIANT BookmarkId) Bookmark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR AdaptationString) SetAdaptationData;
	}


	public HRESULT get_Recognizer(ISpeechRecognizer** Recognizer) mut => VT.[Friend]get_Recognizer(&this, Recognizer);

	public HRESULT get_AudioInputInterferenceStatus(SpeechInterference* Interference) mut => VT.[Friend]get_AudioInputInterferenceStatus(&this, Interference);

	public HRESULT get_RequestedUIType(BSTR* UIType) mut => VT.[Friend]get_RequestedUIType(&this, UIType);

	public HRESULT putref_Voice(ISpeechVoice* Voice) mut => VT.[Friend]putref_Voice(&this, Voice);

	public HRESULT get_Voice(ISpeechVoice** Voice) mut => VT.[Friend]get_Voice(&this, Voice);

	public HRESULT put_AllowVoiceFormatMatchingOnNextSet(int16 Allow) mut => VT.[Friend]put_AllowVoiceFormatMatchingOnNextSet(&this, Allow);

	public HRESULT get_AllowVoiceFormatMatchingOnNextSet(int16* pAllow) mut => VT.[Friend]get_AllowVoiceFormatMatchingOnNextSet(&this, pAllow);

	public HRESULT put_VoicePurgeEvent(SpeechRecoEvents EventInterest) mut => VT.[Friend]put_VoicePurgeEvent(&this, EventInterest);

	public HRESULT get_VoicePurgeEvent(SpeechRecoEvents* EventInterest) mut => VT.[Friend]get_VoicePurgeEvent(&this, EventInterest);

	public HRESULT put_EventInterests(SpeechRecoEvents EventInterest) mut => VT.[Friend]put_EventInterests(&this, EventInterest);

	public HRESULT get_EventInterests(SpeechRecoEvents* EventInterest) mut => VT.[Friend]get_EventInterests(&this, EventInterest);

	public HRESULT put_CmdMaxAlternates(int32 MaxAlternates) mut => VT.[Friend]put_CmdMaxAlternates(&this, MaxAlternates);

	public HRESULT get_CmdMaxAlternates(int32* MaxAlternates) mut => VT.[Friend]get_CmdMaxAlternates(&this, MaxAlternates);

	public HRESULT put_State(SpeechRecoContextState State) mut => VT.[Friend]put_State(&this, State);

	public HRESULT get_State(SpeechRecoContextState* State) mut => VT.[Friend]get_State(&this, State);

	public HRESULT put_RetainedAudio(SpeechRetainedAudioOptions Option) mut => VT.[Friend]put_RetainedAudio(&this, Option);

	public HRESULT get_RetainedAudio(SpeechRetainedAudioOptions* Option) mut => VT.[Friend]get_RetainedAudio(&this, Option);

	public HRESULT putref_RetainedAudioFormat(ISpeechAudioFormat* Format) mut => VT.[Friend]putref_RetainedAudioFormat(&this, Format);

	public HRESULT get_RetainedAudioFormat(ISpeechAudioFormat** Format) mut => VT.[Friend]get_RetainedAudioFormat(&this, Format);

	public HRESULT Pause() mut => VT.[Friend]Pause(&this);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);

	public HRESULT CreateGrammar(VARIANT GrammarId, ISpeechRecoGrammar** Grammar) mut => VT.[Friend]CreateGrammar(&this, GrammarId, Grammar);

	public HRESULT CreateResultFromMemory(VARIANT* ResultBlock, ISpeechRecoResult** Result) mut => VT.[Friend]CreateResultFromMemory(&this, ResultBlock, Result);

	public HRESULT Bookmark(SpeechBookmarkOptions Options, VARIANT StreamPos, VARIANT BookmarkId) mut => VT.[Friend]Bookmark(&this, Options, StreamPos, BookmarkId);

	public HRESULT SetAdaptationData(BSTR AdaptationString) mut => VT.[Friend]SetAdaptationData(&this, AdaptationString);
}

[CRepr]struct ISpeechRecoGrammar : IDispatch
{
	public new const Guid IID = .(0xb6d6f79f, 0x2158, 0x4e50, 0xb5, 0xbc, 0x9a, 0x9c, 0xcd, 0x85, 0x2a, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Id) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechRecoContext** RecoContext) get_RecoContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechGrammarState State) put_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechGrammarState* State) get_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechGrammarRules** Rules) get_Rules;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NewLanguage) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR FileName, SpeechLoadOption LoadOption) CmdLoadFromFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ClassId, BSTR GrammarName, SpeechLoadOption LoadOption) CmdLoadFromObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 hModule, VARIANT ResourceName, VARIANT ResourceType, int32 LanguageId, SpeechLoadOption LoadOption) CmdLoadFromResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT GrammarData, SpeechLoadOption LoadOption) CmdLoadFromMemory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ProprietaryGuid, BSTR ProprietaryString, VARIANT ProprietaryData, SpeechLoadOption LoadOption) CmdLoadFromProprietaryGrammar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Name, SpeechRuleState State) CmdSetRuleState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 RuleId, SpeechRuleState State) CmdSetRuleIdState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR TopicName, SpeechLoadOption LoadOption) DictationLoad;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DictationUnload;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechRuleState State) DictationSetState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Text, int32 TextLength, ISpeechTextSelectionInformation* Info) SetWordSequenceData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechTextSelectionInformation* Info) SetTextSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Word, SpeechWordPronounceable* WordPronounceable) IsPronounceable;
	}


	public HRESULT get_Id(VARIANT* Id) mut => VT.[Friend]get_Id(&this, Id);

	public HRESULT get_RecoContext(ISpeechRecoContext** RecoContext) mut => VT.[Friend]get_RecoContext(&this, RecoContext);

	public HRESULT put_State(SpeechGrammarState State) mut => VT.[Friend]put_State(&this, State);

	public HRESULT get_State(SpeechGrammarState* State) mut => VT.[Friend]get_State(&this, State);

	public HRESULT get_Rules(ISpeechGrammarRules** Rules) mut => VT.[Friend]get_Rules(&this, Rules);

	public HRESULT Reset(int32 NewLanguage) mut => VT.[Friend]Reset(&this, NewLanguage);

	public HRESULT CmdLoadFromFile(BSTR FileName, SpeechLoadOption LoadOption) mut => VT.[Friend]CmdLoadFromFile(&this, FileName, LoadOption);

	public HRESULT CmdLoadFromObject(BSTR ClassId, BSTR GrammarName, SpeechLoadOption LoadOption) mut => VT.[Friend]CmdLoadFromObject(&this, ClassId, GrammarName, LoadOption);

	public HRESULT CmdLoadFromResource(int32 hModule, VARIANT ResourceName, VARIANT ResourceType, int32 LanguageId, SpeechLoadOption LoadOption) mut => VT.[Friend]CmdLoadFromResource(&this, hModule, ResourceName, ResourceType, LanguageId, LoadOption);

	public HRESULT CmdLoadFromMemory(VARIANT GrammarData, SpeechLoadOption LoadOption) mut => VT.[Friend]CmdLoadFromMemory(&this, GrammarData, LoadOption);

	public HRESULT CmdLoadFromProprietaryGrammar(BSTR ProprietaryGuid, BSTR ProprietaryString, VARIANT ProprietaryData, SpeechLoadOption LoadOption) mut => VT.[Friend]CmdLoadFromProprietaryGrammar(&this, ProprietaryGuid, ProprietaryString, ProprietaryData, LoadOption);

	public HRESULT CmdSetRuleState(BSTR Name, SpeechRuleState State) mut => VT.[Friend]CmdSetRuleState(&this, Name, State);

	public HRESULT CmdSetRuleIdState(int32 RuleId, SpeechRuleState State) mut => VT.[Friend]CmdSetRuleIdState(&this, RuleId, State);

	public HRESULT DictationLoad(BSTR TopicName, SpeechLoadOption LoadOption) mut => VT.[Friend]DictationLoad(&this, TopicName, LoadOption);

	public HRESULT DictationUnload() mut => VT.[Friend]DictationUnload(&this);

	public HRESULT DictationSetState(SpeechRuleState State) mut => VT.[Friend]DictationSetState(&this, State);

	public HRESULT SetWordSequenceData(BSTR Text, int32 TextLength, ISpeechTextSelectionInformation* Info) mut => VT.[Friend]SetWordSequenceData(&this, Text, TextLength, Info);

	public HRESULT SetTextSelection(ISpeechTextSelectionInformation* Info) mut => VT.[Friend]SetTextSelection(&this, Info);

	public HRESULT IsPronounceable(BSTR Word, SpeechWordPronounceable* WordPronounceable) mut => VT.[Friend]IsPronounceable(&this, Word, WordPronounceable);
}

[CRepr]struct _ISpeechRecoContextEvents : IDispatch
{
	public new const Guid IID = .(0x7b8fcb42, 0x0e9d, 0x4f00, 0xa0, 0x48, 0x7b, 0x04, 0xd6, 0x17, 0x9d, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct ISpeechGrammarRule : IDispatch
{
	public new const Guid IID = .(0xafe719cf, 0x5dd1, 0x44f2, 0x99, 0x9c, 0x7a, 0x39, 0x9f, 0x1c, 0xfc, 0xcc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechRuleAttributes* Attributes) get_Attributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechGrammarRuleState** State) get_InitialState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Id) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ResourceName, BSTR ResourceValue) AddResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechGrammarRuleState** State) AddState;
	}


	public HRESULT get_Attributes(SpeechRuleAttributes* Attributes) mut => VT.[Friend]get_Attributes(&this, Attributes);

	public HRESULT get_InitialState(ISpeechGrammarRuleState** State) mut => VT.[Friend]get_InitialState(&this, State);

	public HRESULT get_Name(BSTR* Name) mut => VT.[Friend]get_Name(&this, Name);

	public HRESULT get_Id(int32* Id) mut => VT.[Friend]get_Id(&this, Id);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT AddResource(BSTR ResourceName, BSTR ResourceValue) mut => VT.[Friend]AddResource(&this, ResourceName, ResourceValue);

	public HRESULT AddState(ISpeechGrammarRuleState** State) mut => VT.[Friend]AddState(&this, State);
}

[CRepr]struct ISpeechGrammarRules : IDispatch
{
	public new const Guid IID = .(0x6ffa3b44, 0xfc2d, 0x40d1, 0x8a, 0xfc, 0x32, 0x91, 0x1c, 0x7f, 0x1a, 0xd1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT RuleNameOrId, ISpeechGrammarRule** Rule) FindRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ISpeechGrammarRule** Rule) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** EnumVARIANT) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Dynamic) get_Dynamic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR RuleName, SpeechRuleAttributes Attributes, int32 RuleId, ISpeechGrammarRule** Rule) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* ErrorText, VARIANT* SaveStream) CommitAndSave;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT FindRule(VARIANT RuleNameOrId, ISpeechGrammarRule** Rule) mut => VT.[Friend]FindRule(&this, RuleNameOrId, Rule);

	public HRESULT Item(int32 Index, ISpeechGrammarRule** Rule) mut => VT.[Friend]Item(&this, Index, Rule);

	public HRESULT get__NewEnum(IUnknown** EnumVARIANT) mut => VT.[Friend]get__NewEnum(&this, EnumVARIANT);

	public HRESULT get_Dynamic(int16* Dynamic) mut => VT.[Friend]get_Dynamic(&this, Dynamic);

	public HRESULT Add(BSTR RuleName, SpeechRuleAttributes Attributes, int32 RuleId, ISpeechGrammarRule** Rule) mut => VT.[Friend]Add(&this, RuleName, Attributes, RuleId, Rule);

	public HRESULT Commit() mut => VT.[Friend]Commit(&this);

	public HRESULT CommitAndSave(BSTR* ErrorText, VARIANT* SaveStream) mut => VT.[Friend]CommitAndSave(&this, ErrorText, SaveStream);
}

[CRepr]struct ISpeechGrammarRuleState : IDispatch
{
	public new const Guid IID = .(0xd4286f2c, 0xee67, 0x45ae, 0xb9, 0x28, 0x28, 0xd6, 0x95, 0x36, 0x2e, 0xda);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechGrammarRule** Rule) get_Rule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechGrammarRuleStateTransitions** Transitions) get_Transitions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechGrammarRuleState* DestState, BSTR Words, BSTR Separators, SpeechGrammarWordType Type, BSTR PropertyName, int32 PropertyId, VARIANT* PropertyValue, float Weight) AddWordTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechGrammarRuleState* DestinationState, ISpeechGrammarRule* Rule, BSTR PropertyName, int32 PropertyId, VARIANT* PropertyValue, float Weight) AddRuleTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechGrammarRuleState* DestinationState, SpeechSpecialTransitionType Type, BSTR PropertyName, int32 PropertyId, VARIANT* PropertyValue, float Weight) AddSpecialTransition;
	}


	public HRESULT get_Rule(ISpeechGrammarRule** Rule) mut => VT.[Friend]get_Rule(&this, Rule);

	public HRESULT get_Transitions(ISpeechGrammarRuleStateTransitions** Transitions) mut => VT.[Friend]get_Transitions(&this, Transitions);

	public HRESULT AddWordTransition(ISpeechGrammarRuleState* DestState, BSTR Words, BSTR Separators, SpeechGrammarWordType Type, BSTR PropertyName, int32 PropertyId, VARIANT* PropertyValue, float Weight) mut => VT.[Friend]AddWordTransition(&this, DestState, Words, Separators, Type, PropertyName, PropertyId, PropertyValue, Weight);

	public HRESULT AddRuleTransition(ISpeechGrammarRuleState* DestinationState, ISpeechGrammarRule* Rule, BSTR PropertyName, int32 PropertyId, VARIANT* PropertyValue, float Weight) mut => VT.[Friend]AddRuleTransition(&this, DestinationState, Rule, PropertyName, PropertyId, PropertyValue, Weight);

	public HRESULT AddSpecialTransition(ISpeechGrammarRuleState* DestinationState, SpeechSpecialTransitionType Type, BSTR PropertyName, int32 PropertyId, VARIANT* PropertyValue, float Weight) mut => VT.[Friend]AddSpecialTransition(&this, DestinationState, Type, PropertyName, PropertyId, PropertyValue, Weight);
}

[CRepr]struct ISpeechGrammarRuleStateTransition : IDispatch
{
	public new const Guid IID = .(0xcafd1db1, 0x41d1, 0x4a06, 0x98, 0x63, 0xe2, 0xe8, 0x1d, 0xa1, 0x7a, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechGrammarRuleStateTransitionType* Type) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Text) get_Text;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechGrammarRule** Rule) get_Rule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Weight) get_Weight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* PropertyName) get_PropertyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* PropertyId) get_PropertyId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* PropertyValue) get_PropertyValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechGrammarRuleState** NextState) get_NextState;
	}


	public HRESULT get_Type(SpeechGrammarRuleStateTransitionType* Type) mut => VT.[Friend]get_Type(&this, Type);

	public HRESULT get_Text(BSTR* Text) mut => VT.[Friend]get_Text(&this, Text);

	public HRESULT get_Rule(ISpeechGrammarRule** Rule) mut => VT.[Friend]get_Rule(&this, Rule);

	public HRESULT get_Weight(VARIANT* Weight) mut => VT.[Friend]get_Weight(&this, Weight);

	public HRESULT get_PropertyName(BSTR* PropertyName) mut => VT.[Friend]get_PropertyName(&this, PropertyName);

	public HRESULT get_PropertyId(int32* PropertyId) mut => VT.[Friend]get_PropertyId(&this, PropertyId);

	public HRESULT get_PropertyValue(VARIANT* PropertyValue) mut => VT.[Friend]get_PropertyValue(&this, PropertyValue);

	public HRESULT get_NextState(ISpeechGrammarRuleState** NextState) mut => VT.[Friend]get_NextState(&this, NextState);
}

[CRepr]struct ISpeechGrammarRuleStateTransitions : IDispatch
{
	public new const Guid IID = .(0xeabce657, 0x75bc, 0x44a2, 0xaa, 0x7f, 0xc5, 0x64, 0x76, 0x74, 0x29, 0x63);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ISpeechGrammarRuleStateTransition** Transition) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** EnumVARIANT) get__NewEnum;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT Item(int32 Index, ISpeechGrammarRuleStateTransition** Transition) mut => VT.[Friend]Item(&this, Index, Transition);

	public HRESULT get__NewEnum(IUnknown** EnumVARIANT) mut => VT.[Friend]get__NewEnum(&this, EnumVARIANT);
}

[CRepr]struct ISpeechTextSelectionInformation : IDispatch
{
	public new const Guid IID = .(0x3b9c7e7a, 0x6eee, 0x4ded, 0x90, 0x92, 0x11, 0x65, 0x72, 0x79, 0xad, 0xbe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 ActiveOffset) put_ActiveOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* ActiveOffset) get_ActiveOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 ActiveLength) put_ActiveLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* ActiveLength) get_ActiveLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 SelectionOffset) put_SelectionOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* SelectionOffset) get_SelectionOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 SelectionLength) put_SelectionLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* SelectionLength) get_SelectionLength;
	}


	public HRESULT put_ActiveOffset(int32 ActiveOffset) mut => VT.[Friend]put_ActiveOffset(&this, ActiveOffset);

	public HRESULT get_ActiveOffset(int32* ActiveOffset) mut => VT.[Friend]get_ActiveOffset(&this, ActiveOffset);

	public HRESULT put_ActiveLength(int32 ActiveLength) mut => VT.[Friend]put_ActiveLength(&this, ActiveLength);

	public HRESULT get_ActiveLength(int32* ActiveLength) mut => VT.[Friend]get_ActiveLength(&this, ActiveLength);

	public HRESULT put_SelectionOffset(int32 SelectionOffset) mut => VT.[Friend]put_SelectionOffset(&this, SelectionOffset);

	public HRESULT get_SelectionOffset(int32* SelectionOffset) mut => VT.[Friend]get_SelectionOffset(&this, SelectionOffset);

	public HRESULT put_SelectionLength(int32 SelectionLength) mut => VT.[Friend]put_SelectionLength(&this, SelectionLength);

	public HRESULT get_SelectionLength(int32* SelectionLength) mut => VT.[Friend]get_SelectionLength(&this, SelectionLength);
}

[CRepr]struct ISpeechRecoResult : IDispatch
{
	public new const Guid IID = .(0xed2879cf, 0xced9, 0x4ee6, 0xa5, 0x34, 0xde, 0x01, 0x91, 0xd5, 0x46, 0x8d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechRecoContext** RecoContext) get_RecoContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechRecoResultTimes** Times) get_Times;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechAudioFormat* Format) putref_AudioFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechAudioFormat** Format) get_AudioFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechPhraseInfo** PhraseInfo) get_PhraseInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 RequestCount, int32 StartElement, int32 Elements, ISpeechPhraseAlternates** Alternates) Alternates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 StartElement, int32 Elements, ISpeechMemoryStream** Stream) Audio;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 StartElement, int32 Elements, SpeechVoiceSpeakFlags Flags, int32* StreamNumber) SpeakAudio;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* ResultBlock) SaveToMemory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechDiscardType ValueTypes) DiscardResultInfo;
	}


	public HRESULT get_RecoContext(ISpeechRecoContext** RecoContext) mut => VT.[Friend]get_RecoContext(&this, RecoContext);

	public HRESULT get_Times(ISpeechRecoResultTimes** Times) mut => VT.[Friend]get_Times(&this, Times);

	public HRESULT putref_AudioFormat(ISpeechAudioFormat* Format) mut => VT.[Friend]putref_AudioFormat(&this, Format);

	public HRESULT get_AudioFormat(ISpeechAudioFormat** Format) mut => VT.[Friend]get_AudioFormat(&this, Format);

	public HRESULT get_PhraseInfo(ISpeechPhraseInfo** PhraseInfo) mut => VT.[Friend]get_PhraseInfo(&this, PhraseInfo);

	public HRESULT Alternates(int32 RequestCount, int32 StartElement, int32 Elements, ISpeechPhraseAlternates** Alternates) mut => VT.[Friend]Alternates(&this, RequestCount, StartElement, Elements, Alternates);

	public HRESULT Audio(int32 StartElement, int32 Elements, ISpeechMemoryStream** Stream) mut => VT.[Friend]Audio(&this, StartElement, Elements, Stream);

	public HRESULT SpeakAudio(int32 StartElement, int32 Elements, SpeechVoiceSpeakFlags Flags, int32* StreamNumber) mut => VT.[Friend]SpeakAudio(&this, StartElement, Elements, Flags, StreamNumber);

	public HRESULT SaveToMemory(VARIANT* ResultBlock) mut => VT.[Friend]SaveToMemory(&this, ResultBlock);

	public HRESULT DiscardResultInfo(SpeechDiscardType ValueTypes) mut => VT.[Friend]DiscardResultInfo(&this, ValueTypes);
}

[CRepr]struct ISpeechRecoResult2 : ISpeechRecoResult
{
	public new const Guid IID = .(0x8e0a246d, 0xd3c8, 0x45de, 0x86, 0x57, 0x04, 0x29, 0x0c, 0x45, 0x8c, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpeechRecoResult.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Feedback, int16 WasSuccessful) SetTextFeedback;
	}


	public HRESULT SetTextFeedback(BSTR Feedback, int16 WasSuccessful) mut => VT.[Friend]SetTextFeedback(&this, Feedback, WasSuccessful);
}

[CRepr]struct ISpeechRecoResultTimes : IDispatch
{
	public new const Guid IID = .(0x62b3b8fb, 0xf6e7, 0x41be, 0xbd, 0xcb, 0x05, 0x6b, 0x1c, 0x29, 0xef, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Time) get_StreamTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Length) get_Length;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* TickCount) get_TickCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* OffsetFromStart) get_OffsetFromStart;
	}


	public HRESULT get_StreamTime(VARIANT* Time) mut => VT.[Friend]get_StreamTime(&this, Time);

	public HRESULT get_Length(VARIANT* Length) mut => VT.[Friend]get_Length(&this, Length);

	public HRESULT get_TickCount(int32* TickCount) mut => VT.[Friend]get_TickCount(&this, TickCount);

	public HRESULT get_OffsetFromStart(VARIANT* OffsetFromStart) mut => VT.[Friend]get_OffsetFromStart(&this, OffsetFromStart);
}

[CRepr]struct ISpeechPhraseAlternate : IDispatch
{
	public new const Guid IID = .(0x27864a2a, 0x2b9f, 0x4cb8, 0x92, 0xd3, 0x0d, 0x27, 0x22, 0xfd, 0x1e, 0x73);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechRecoResult** RecoResult) get_RecoResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* StartElement) get_StartElementInResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* NumberOfElements) get_NumberOfElementsInResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechPhraseInfo** PhraseInfo) get_PhraseInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Commit;
	}


	public HRESULT get_RecoResult(ISpeechRecoResult** RecoResult) mut => VT.[Friend]get_RecoResult(&this, RecoResult);

	public HRESULT get_StartElementInResult(int32* StartElement) mut => VT.[Friend]get_StartElementInResult(&this, StartElement);

	public HRESULT get_NumberOfElementsInResult(int32* NumberOfElements) mut => VT.[Friend]get_NumberOfElementsInResult(&this, NumberOfElements);

	public HRESULT get_PhraseInfo(ISpeechPhraseInfo** PhraseInfo) mut => VT.[Friend]get_PhraseInfo(&this, PhraseInfo);

	public HRESULT Commit() mut => VT.[Friend]Commit(&this);
}

[CRepr]struct ISpeechPhraseAlternates : IDispatch
{
	public new const Guid IID = .(0xb238b6d5, 0xf276, 0x4c3d, 0xa6, 0xc1, 0x29, 0x74, 0x80, 0x1c, 0x3c, 0xc2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ISpeechPhraseAlternate** PhraseAlternate) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** EnumVARIANT) get__NewEnum;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT Item(int32 Index, ISpeechPhraseAlternate** PhraseAlternate) mut => VT.[Friend]Item(&this, Index, PhraseAlternate);

	public HRESULT get__NewEnum(IUnknown** EnumVARIANT) mut => VT.[Friend]get__NewEnum(&this, EnumVARIANT);
}

[CRepr]struct ISpeechPhraseInfo : IDispatch
{
	public new const Guid IID = .(0x961559cf, 0x4e67, 0x4662, 0x8b, 0xf0, 0xd9, 0x3f, 0x1f, 0xcd, 0x61, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* LanguageId) get_LanguageId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* GrammarId) get_GrammarId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* StartTime) get_StartTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* AudioStreamPosition) get_AudioStreamPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pAudioSizeBytes) get_AudioSizeBytes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* RetainedSizeBytes) get_RetainedSizeBytes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* AudioSizeTime) get_AudioSizeTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechPhraseRule** Rule) get_Rule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechPhraseProperties** Properties) get_Properties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechPhraseElements** Elements) get_Elements;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechPhraseReplacements** Replacements) get_Replacements;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* EngineIdGuid) get_EngineId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* PrivateData) get_EnginePrivateData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* PhraseBlock) SaveToMemory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 StartElement, int32 Elements, int16 UseReplacements, BSTR* Text) GetText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 StartElement, int32 Elements, int16 UseReplacements, SpeechDisplayAttributes* DisplayAttributes) GetDisplayAttributes;
	}


	public HRESULT get_LanguageId(int32* LanguageId) mut => VT.[Friend]get_LanguageId(&this, LanguageId);

	public HRESULT get_GrammarId(VARIANT* GrammarId) mut => VT.[Friend]get_GrammarId(&this, GrammarId);

	public HRESULT get_StartTime(VARIANT* StartTime) mut => VT.[Friend]get_StartTime(&this, StartTime);

	public HRESULT get_AudioStreamPosition(VARIANT* AudioStreamPosition) mut => VT.[Friend]get_AudioStreamPosition(&this, AudioStreamPosition);

	public HRESULT get_AudioSizeBytes(int32* pAudioSizeBytes) mut => VT.[Friend]get_AudioSizeBytes(&this, pAudioSizeBytes);

	public HRESULT get_RetainedSizeBytes(int32* RetainedSizeBytes) mut => VT.[Friend]get_RetainedSizeBytes(&this, RetainedSizeBytes);

	public HRESULT get_AudioSizeTime(int32* AudioSizeTime) mut => VT.[Friend]get_AudioSizeTime(&this, AudioSizeTime);

	public HRESULT get_Rule(ISpeechPhraseRule** Rule) mut => VT.[Friend]get_Rule(&this, Rule);

	public HRESULT get_Properties(ISpeechPhraseProperties** Properties) mut => VT.[Friend]get_Properties(&this, Properties);

	public HRESULT get_Elements(ISpeechPhraseElements** Elements) mut => VT.[Friend]get_Elements(&this, Elements);

	public HRESULT get_Replacements(ISpeechPhraseReplacements** Replacements) mut => VT.[Friend]get_Replacements(&this, Replacements);

	public HRESULT get_EngineId(BSTR* EngineIdGuid) mut => VT.[Friend]get_EngineId(&this, EngineIdGuid);

	public HRESULT get_EnginePrivateData(VARIANT* PrivateData) mut => VT.[Friend]get_EnginePrivateData(&this, PrivateData);

	public HRESULT SaveToMemory(VARIANT* PhraseBlock) mut => VT.[Friend]SaveToMemory(&this, PhraseBlock);

	public HRESULT GetText(int32 StartElement, int32 Elements, int16 UseReplacements, BSTR* Text) mut => VT.[Friend]GetText(&this, StartElement, Elements, UseReplacements, Text);

	public HRESULT GetDisplayAttributes(int32 StartElement, int32 Elements, int16 UseReplacements, SpeechDisplayAttributes* DisplayAttributes) mut => VT.[Friend]GetDisplayAttributes(&this, StartElement, Elements, UseReplacements, DisplayAttributes);
}

[CRepr]struct ISpeechPhraseElement : IDispatch
{
	public new const Guid IID = .(0xe6176f96, 0xe373, 0x4801, 0xb2, 0x23, 0x3b, 0x62, 0xc0, 0x68, 0xc0, 0xb4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* AudioTimeOffset) get_AudioTimeOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* AudioSizeTime) get_AudioSizeTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* AudioStreamOffset) get_AudioStreamOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* AudioSizeBytes) get_AudioSizeBytes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* RetainedStreamOffset) get_RetainedStreamOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* RetainedSizeBytes) get_RetainedSizeBytes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* DisplayText) get_DisplayText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* LexicalForm) get_LexicalForm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Pronunciation) get_Pronunciation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechDisplayAttributes* DisplayAttributes) get_DisplayAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechEngineConfidence* RequiredConfidence) get_RequiredConfidence;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechEngineConfidence* ActualConfidence) get_ActualConfidence;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* EngineConfidence) get_EngineConfidence;
	}


	public HRESULT get_AudioTimeOffset(int32* AudioTimeOffset) mut => VT.[Friend]get_AudioTimeOffset(&this, AudioTimeOffset);

	public HRESULT get_AudioSizeTime(int32* AudioSizeTime) mut => VT.[Friend]get_AudioSizeTime(&this, AudioSizeTime);

	public HRESULT get_AudioStreamOffset(int32* AudioStreamOffset) mut => VT.[Friend]get_AudioStreamOffset(&this, AudioStreamOffset);

	public HRESULT get_AudioSizeBytes(int32* AudioSizeBytes) mut => VT.[Friend]get_AudioSizeBytes(&this, AudioSizeBytes);

	public HRESULT get_RetainedStreamOffset(int32* RetainedStreamOffset) mut => VT.[Friend]get_RetainedStreamOffset(&this, RetainedStreamOffset);

	public HRESULT get_RetainedSizeBytes(int32* RetainedSizeBytes) mut => VT.[Friend]get_RetainedSizeBytes(&this, RetainedSizeBytes);

	public HRESULT get_DisplayText(BSTR* DisplayText) mut => VT.[Friend]get_DisplayText(&this, DisplayText);

	public HRESULT get_LexicalForm(BSTR* LexicalForm) mut => VT.[Friend]get_LexicalForm(&this, LexicalForm);

	public HRESULT get_Pronunciation(VARIANT* Pronunciation) mut => VT.[Friend]get_Pronunciation(&this, Pronunciation);

	public HRESULT get_DisplayAttributes(SpeechDisplayAttributes* DisplayAttributes) mut => VT.[Friend]get_DisplayAttributes(&this, DisplayAttributes);

	public HRESULT get_RequiredConfidence(SpeechEngineConfidence* RequiredConfidence) mut => VT.[Friend]get_RequiredConfidence(&this, RequiredConfidence);

	public HRESULT get_ActualConfidence(SpeechEngineConfidence* ActualConfidence) mut => VT.[Friend]get_ActualConfidence(&this, ActualConfidence);

	public HRESULT get_EngineConfidence(float* EngineConfidence) mut => VT.[Friend]get_EngineConfidence(&this, EngineConfidence);
}

[CRepr]struct ISpeechPhraseElements : IDispatch
{
	public new const Guid IID = .(0x0626b328, 0x3478, 0x467d, 0xa0, 0xb3, 0xd0, 0x85, 0x3b, 0x93, 0xdd, 0xa3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ISpeechPhraseElement** Element) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** EnumVARIANT) get__NewEnum;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT Item(int32 Index, ISpeechPhraseElement** Element) mut => VT.[Friend]Item(&this, Index, Element);

	public HRESULT get__NewEnum(IUnknown** EnumVARIANT) mut => VT.[Friend]get__NewEnum(&this, EnumVARIANT);
}

[CRepr]struct ISpeechPhraseReplacement : IDispatch
{
	public new const Guid IID = .(0x2890a410, 0x53a7, 0x4fb5, 0x94, 0xec, 0x06, 0xd4, 0x99, 0x8e, 0x3d, 0x02);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechDisplayAttributes* DisplayAttributes) get_DisplayAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Text) get_Text;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* FirstElement) get_FirstElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* NumberOfElements) get_NumberOfElements;
	}


	public HRESULT get_DisplayAttributes(SpeechDisplayAttributes* DisplayAttributes) mut => VT.[Friend]get_DisplayAttributes(&this, DisplayAttributes);

	public HRESULT get_Text(BSTR* Text) mut => VT.[Friend]get_Text(&this, Text);

	public HRESULT get_FirstElement(int32* FirstElement) mut => VT.[Friend]get_FirstElement(&this, FirstElement);

	public HRESULT get_NumberOfElements(int32* NumberOfElements) mut => VT.[Friend]get_NumberOfElements(&this, NumberOfElements);
}

[CRepr]struct ISpeechPhraseReplacements : IDispatch
{
	public new const Guid IID = .(0x38bc662f, 0x2257, 0x4525, 0x95, 0x9e, 0x20, 0x69, 0xd2, 0x59, 0x6c, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ISpeechPhraseReplacement** Reps) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** EnumVARIANT) get__NewEnum;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT Item(int32 Index, ISpeechPhraseReplacement** Reps) mut => VT.[Friend]Item(&this, Index, Reps);

	public HRESULT get__NewEnum(IUnknown** EnumVARIANT) mut => VT.[Friend]get__NewEnum(&this, EnumVARIANT);
}

[CRepr]struct ISpeechPhraseProperty : IDispatch
{
	public new const Guid IID = .(0xce563d48, 0x961e, 0x4732, 0xa2, 0xe1, 0x37, 0x8a, 0x42, 0xb4, 0x30, 0xbe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Id) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Value) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* FirstElement) get_FirstElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* NumberOfElements) get_NumberOfElements;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* Confidence) get_EngineConfidence;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechEngineConfidence* Confidence) get_Confidence;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechPhraseProperty** ParentProperty) get_Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechPhraseProperties** Children) get_Children;
	}


	public HRESULT get_Name(BSTR* Name) mut => VT.[Friend]get_Name(&this, Name);

	public HRESULT get_Id(int32* Id) mut => VT.[Friend]get_Id(&this, Id);

	public HRESULT get_Value(VARIANT* Value) mut => VT.[Friend]get_Value(&this, Value);

	public HRESULT get_FirstElement(int32* FirstElement) mut => VT.[Friend]get_FirstElement(&this, FirstElement);

	public HRESULT get_NumberOfElements(int32* NumberOfElements) mut => VT.[Friend]get_NumberOfElements(&this, NumberOfElements);

	public HRESULT get_EngineConfidence(float* Confidence) mut => VT.[Friend]get_EngineConfidence(&this, Confidence);

	public HRESULT get_Confidence(SpeechEngineConfidence* Confidence) mut => VT.[Friend]get_Confidence(&this, Confidence);

	public HRESULT get_Parent(ISpeechPhraseProperty** ParentProperty) mut => VT.[Friend]get_Parent(&this, ParentProperty);

	public HRESULT get_Children(ISpeechPhraseProperties** Children) mut => VT.[Friend]get_Children(&this, Children);
}

[CRepr]struct ISpeechPhraseProperties : IDispatch
{
	public new const Guid IID = .(0x08166b47, 0x102e, 0x4b23, 0xa5, 0x99, 0xbd, 0xb9, 0x8d, 0xbf, 0xd1, 0xf4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ISpeechPhraseProperty** Property) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** EnumVARIANT) get__NewEnum;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT Item(int32 Index, ISpeechPhraseProperty** Property) mut => VT.[Friend]Item(&this, Index, Property);

	public HRESULT get__NewEnum(IUnknown** EnumVARIANT) mut => VT.[Friend]get__NewEnum(&this, EnumVARIANT);
}

[CRepr]struct ISpeechPhraseRule : IDispatch
{
	public new const Guid IID = .(0xa7bfe112, 0xa4a0, 0x48d9, 0xb6, 0x02, 0xc3, 0x13, 0x84, 0x3f, 0x69, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Id) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* FirstElement) get_FirstElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* NumberOfElements) get_NumberOfElements;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechPhraseRule** Parent) get_Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechPhraseRules** Children) get_Children;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechEngineConfidence* ActualConfidence) get_Confidence;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* EngineConfidence) get_EngineConfidence;
	}


	public HRESULT get_Name(BSTR* Name) mut => VT.[Friend]get_Name(&this, Name);

	public HRESULT get_Id(int32* Id) mut => VT.[Friend]get_Id(&this, Id);

	public HRESULT get_FirstElement(int32* FirstElement) mut => VT.[Friend]get_FirstElement(&this, FirstElement);

	public HRESULT get_NumberOfElements(int32* NumberOfElements) mut => VT.[Friend]get_NumberOfElements(&this, NumberOfElements);

	public HRESULT get_Parent(ISpeechPhraseRule** Parent) mut => VT.[Friend]get_Parent(&this, Parent);

	public HRESULT get_Children(ISpeechPhraseRules** Children) mut => VT.[Friend]get_Children(&this, Children);

	public HRESULT get_Confidence(SpeechEngineConfidence* ActualConfidence) mut => VT.[Friend]get_Confidence(&this, ActualConfidence);

	public HRESULT get_EngineConfidence(float* EngineConfidence) mut => VT.[Friend]get_EngineConfidence(&this, EngineConfidence);
}

[CRepr]struct ISpeechPhraseRules : IDispatch
{
	public new const Guid IID = .(0x9047d593, 0x01dd, 0x4b72, 0x81, 0xa3, 0xe4, 0xa0, 0xca, 0x69, 0xf4, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ISpeechPhraseRule** Rule) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** EnumVARIANT) get__NewEnum;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT Item(int32 Index, ISpeechPhraseRule** Rule) mut => VT.[Friend]Item(&this, Index, Rule);

	public HRESULT get__NewEnum(IUnknown** EnumVARIANT) mut => VT.[Friend]get__NewEnum(&this, EnumVARIANT);
}

[CRepr]struct ISpeechLexicon : IDispatch
{
	public new const Guid IID = .(0x3da7627a, 0xc7ae, 0x4b23, 0x87, 0x08, 0x63, 0x8c, 0x50, 0x36, 0x2c, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* GenerationId) get_GenerationId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechLexiconType Flags, int32* GenerationID, ISpeechLexiconWords** Words) GetWords;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWord, int32 LangId, SpeechPartOfSpeech PartOfSpeech, BSTR bstrPronunciation) AddPronunciation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWord, int32 LangId, SpeechPartOfSpeech PartOfSpeech, VARIANT* PhoneIds) AddPronunciationByPhoneIds;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWord, int32 LangId, SpeechPartOfSpeech PartOfSpeech, BSTR bstrPronunciation) RemovePronunciation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWord, int32 LangId, SpeechPartOfSpeech PartOfSpeech, VARIANT* PhoneIds) RemovePronunciationByPhoneIds;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWord, int32 LangId, SpeechLexiconType TypeFlags, ISpeechLexiconPronunciations** ppPronunciations) GetPronunciations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* GenerationID, ISpeechLexiconWords** ppWords) GetGenerationChange;
	}


	public HRESULT get_GenerationId(int32* GenerationId) mut => VT.[Friend]get_GenerationId(&this, GenerationId);

	public HRESULT GetWords(SpeechLexiconType Flags, int32* GenerationID, ISpeechLexiconWords** Words) mut => VT.[Friend]GetWords(&this, Flags, GenerationID, Words);

	public HRESULT AddPronunciation(BSTR bstrWord, int32 LangId, SpeechPartOfSpeech PartOfSpeech, BSTR bstrPronunciation) mut => VT.[Friend]AddPronunciation(&this, bstrWord, LangId, PartOfSpeech, bstrPronunciation);

	public HRESULT AddPronunciationByPhoneIds(BSTR bstrWord, int32 LangId, SpeechPartOfSpeech PartOfSpeech, VARIANT* PhoneIds) mut => VT.[Friend]AddPronunciationByPhoneIds(&this, bstrWord, LangId, PartOfSpeech, PhoneIds);

	public HRESULT RemovePronunciation(BSTR bstrWord, int32 LangId, SpeechPartOfSpeech PartOfSpeech, BSTR bstrPronunciation) mut => VT.[Friend]RemovePronunciation(&this, bstrWord, LangId, PartOfSpeech, bstrPronunciation);

	public HRESULT RemovePronunciationByPhoneIds(BSTR bstrWord, int32 LangId, SpeechPartOfSpeech PartOfSpeech, VARIANT* PhoneIds) mut => VT.[Friend]RemovePronunciationByPhoneIds(&this, bstrWord, LangId, PartOfSpeech, PhoneIds);

	public HRESULT GetPronunciations(BSTR bstrWord, int32 LangId, SpeechLexiconType TypeFlags, ISpeechLexiconPronunciations** ppPronunciations) mut => VT.[Friend]GetPronunciations(&this, bstrWord, LangId, TypeFlags, ppPronunciations);

	public HRESULT GetGenerationChange(int32* GenerationID, ISpeechLexiconWords** ppWords) mut => VT.[Friend]GetGenerationChange(&this, GenerationID, ppWords);
}

[CRepr]struct ISpeechLexiconWords : IDispatch
{
	public new const Guid IID = .(0x8d199862, 0x415e, 0x47d5, 0xac, 0x4f, 0xfa, 0xa6, 0x08, 0xb4, 0x24, 0xe6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ISpeechLexiconWord** Word) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** EnumVARIANT) get__NewEnum;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT Item(int32 Index, ISpeechLexiconWord** Word) mut => VT.[Friend]Item(&this, Index, Word);

	public HRESULT get__NewEnum(IUnknown** EnumVARIANT) mut => VT.[Friend]get__NewEnum(&this, EnumVARIANT);
}

[CRepr]struct ISpeechLexiconWord : IDispatch
{
	public new const Guid IID = .(0x4e5b933c, 0xc9be, 0x48ed, 0x88, 0x42, 0x1e, 0xe5, 0x1b, 0xb1, 0xd4, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* LangId) get_LangId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechWordType* WordType) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Word) get_Word;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechLexiconPronunciations** Pronunciations) get_Pronunciations;
	}


	public HRESULT get_LangId(int32* LangId) mut => VT.[Friend]get_LangId(&this, LangId);

	public HRESULT get_Type(SpeechWordType* WordType) mut => VT.[Friend]get_Type(&this, WordType);

	public HRESULT get_Word(BSTR* Word) mut => VT.[Friend]get_Word(&this, Word);

	public HRESULT get_Pronunciations(ISpeechLexiconPronunciations** Pronunciations) mut => VT.[Friend]get_Pronunciations(&this, Pronunciations);
}

[CRepr]struct ISpeechLexiconPronunciations : IDispatch
{
	public new const Guid IID = .(0x72829128, 0x5682, 0x4704, 0xa0, 0xd4, 0x3e, 0x2b, 0xb6, 0xf2, 0xea, 0xd3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ISpeechLexiconPronunciation** Pronunciation) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** EnumVARIANT) get__NewEnum;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT Item(int32 Index, ISpeechLexiconPronunciation** Pronunciation) mut => VT.[Friend]Item(&this, Index, Pronunciation);

	public HRESULT get__NewEnum(IUnknown** EnumVARIANT) mut => VT.[Friend]get__NewEnum(&this, EnumVARIANT);
}

[CRepr]struct ISpeechLexiconPronunciation : IDispatch
{
	public new const Guid IID = .(0x95252c5d, 0x9e43, 0x4f4a, 0x98, 0x99, 0x48, 0xee, 0x73, 0x35, 0x2f, 0x9f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechLexiconType* LexiconType) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* LangId) get_LangId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechPartOfSpeech* PartOfSpeech) get_PartOfSpeech;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* PhoneIds) get_PhoneIds;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Symbolic) get_Symbolic;
	}


	public HRESULT get_Type(SpeechLexiconType* LexiconType) mut => VT.[Friend]get_Type(&this, LexiconType);

	public HRESULT get_LangId(int32* LangId) mut => VT.[Friend]get_LangId(&this, LangId);

	public HRESULT get_PartOfSpeech(SpeechPartOfSpeech* PartOfSpeech) mut => VT.[Friend]get_PartOfSpeech(&this, PartOfSpeech);

	public HRESULT get_PhoneIds(VARIANT* PhoneIds) mut => VT.[Friend]get_PhoneIds(&this, PhoneIds);

	public HRESULT get_Symbolic(BSTR* Symbolic) mut => VT.[Friend]get_Symbolic(&this, Symbolic);
}

[CRepr]struct ISpeechXMLRecoResult : ISpeechRecoResult
{
	public new const Guid IID = .(0xaaec54af, 0x8f85, 0x4924, 0x94, 0x4d, 0xb7, 0x9d, 0x39, 0xd7, 0x2e, 0x19);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpeechRecoResult.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPXMLRESULTOPTIONS Options, BSTR* pResult) GetXMLResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* LineNumber, BSTR* ScriptLine, BSTR* Source, BSTR* Description, int32* ResultCode, int16* IsError) GetXMLErrorInfo;
	}


	public HRESULT GetXMLResult(SPXMLRESULTOPTIONS Options, BSTR* pResult) mut => VT.[Friend]GetXMLResult(&this, Options, pResult);

	public HRESULT GetXMLErrorInfo(int32* LineNumber, BSTR* ScriptLine, BSTR* Source, BSTR* Description, int32* ResultCode, int16* IsError) mut => VT.[Friend]GetXMLErrorInfo(&this, LineNumber, ScriptLine, Source, Description, ResultCode, IsError);
}

[CRepr]struct ISpeechRecoResultDispatch : IDispatch
{
	public new const Guid IID = .(0x6d60eb64, 0xaced, 0x40a6, 0xbb, 0xf3, 0x4e, 0x55, 0x7f, 0x71, 0xde, 0xe2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechRecoContext** RecoContext) get_RecoContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechRecoResultTimes** Times) get_Times;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechAudioFormat* Format) putref_AudioFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechAudioFormat** Format) get_AudioFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpeechPhraseInfo** PhraseInfo) get_PhraseInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 RequestCount, int32 StartElement, int32 Elements, ISpeechPhraseAlternates** Alternates) Alternates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 StartElement, int32 Elements, ISpeechMemoryStream** Stream) Audio;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 StartElement, int32 Elements, SpeechVoiceSpeakFlags Flags, int32* StreamNumber) SpeakAudio;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* ResultBlock) SaveToMemory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SpeechDiscardType ValueTypes) DiscardResultInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPXMLRESULTOPTIONS Options, BSTR* pResult) GetXMLResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* LineNumber, BSTR* ScriptLine, BSTR* Source, BSTR* Description, HRESULT* ResultCode, int16* IsError) GetXMLErrorInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Feedback, int16 WasSuccessful) SetTextFeedback;
	}


	public HRESULT get_RecoContext(ISpeechRecoContext** RecoContext) mut => VT.[Friend]get_RecoContext(&this, RecoContext);

	public HRESULT get_Times(ISpeechRecoResultTimes** Times) mut => VT.[Friend]get_Times(&this, Times);

	public HRESULT putref_AudioFormat(ISpeechAudioFormat* Format) mut => VT.[Friend]putref_AudioFormat(&this, Format);

	public HRESULT get_AudioFormat(ISpeechAudioFormat** Format) mut => VT.[Friend]get_AudioFormat(&this, Format);

	public HRESULT get_PhraseInfo(ISpeechPhraseInfo** PhraseInfo) mut => VT.[Friend]get_PhraseInfo(&this, PhraseInfo);

	public HRESULT Alternates(int32 RequestCount, int32 StartElement, int32 Elements, ISpeechPhraseAlternates** Alternates) mut => VT.[Friend]Alternates(&this, RequestCount, StartElement, Elements, Alternates);

	public HRESULT Audio(int32 StartElement, int32 Elements, ISpeechMemoryStream** Stream) mut => VT.[Friend]Audio(&this, StartElement, Elements, Stream);

	public HRESULT SpeakAudio(int32 StartElement, int32 Elements, SpeechVoiceSpeakFlags Flags, int32* StreamNumber) mut => VT.[Friend]SpeakAudio(&this, StartElement, Elements, Flags, StreamNumber);

	public HRESULT SaveToMemory(VARIANT* ResultBlock) mut => VT.[Friend]SaveToMemory(&this, ResultBlock);

	public HRESULT DiscardResultInfo(SpeechDiscardType ValueTypes) mut => VT.[Friend]DiscardResultInfo(&this, ValueTypes);

	public HRESULT GetXMLResult(SPXMLRESULTOPTIONS Options, BSTR* pResult) mut => VT.[Friend]GetXMLResult(&this, Options, pResult);

	public HRESULT GetXMLErrorInfo(int32* LineNumber, BSTR* ScriptLine, BSTR* Source, BSTR* Description, HRESULT* ResultCode, int16* IsError) mut => VT.[Friend]GetXMLErrorInfo(&this, LineNumber, ScriptLine, Source, Description, ResultCode, IsError);

	public HRESULT SetTextFeedback(BSTR Feedback, int16 WasSuccessful) mut => VT.[Friend]SetTextFeedback(&this, Feedback, WasSuccessful);
}

[CRepr]struct ISpeechPhraseInfoBuilder : IDispatch
{
	public new const Guid IID = .(0x3b151836, 0xdf3a, 0x4e0a, 0x84, 0x6c, 0xd2, 0xad, 0xc9, 0x33, 0x43, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* PhraseInMemory, ISpeechPhraseInfo** PhraseInfo) RestorePhraseFromMemory;
	}


	public HRESULT RestorePhraseFromMemory(VARIANT* PhraseInMemory, ISpeechPhraseInfo** PhraseInfo) mut => VT.[Friend]RestorePhraseFromMemory(&this, PhraseInMemory, PhraseInfo);
}

[CRepr]struct ISpeechPhoneConverter : IDispatch
{
	public new const Guid IID = .(0xc3e4f353, 0x433f, 0x43d6, 0x89, 0xa1, 0x6a, 0x62, 0xa7, 0x05, 0x4c, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* LanguageId) get_LanguageId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 LanguageId) put_LanguageId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Phonemes, VARIANT* IdArray) PhoneToId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT IdArray, BSTR* Phonemes) IdToPhone;
	}


	public HRESULT get_LanguageId(int32* LanguageId) mut => VT.[Friend]get_LanguageId(&this, LanguageId);

	public HRESULT put_LanguageId(int32 LanguageId) mut => VT.[Friend]put_LanguageId(&this, LanguageId);

	public HRESULT PhoneToId(BSTR Phonemes, VARIANT* IdArray) mut => VT.[Friend]PhoneToId(&this, Phonemes, IdArray);

	public HRESULT IdToPhone(VARIANT IdArray, BSTR* Phonemes) mut => VT.[Friend]IdToPhone(&this, IdArray, Phonemes);
}

#endregion
