using Win32.Foundation;
using Win32.System.Diagnostics.Debug;
using Win32.System.Com;
using Win32.Graphics.Gdi;
using Win32.Security;
using Win32.System.JobObjects;
using System;

namespace Win32.System.SystemServices;

#region Constants
public static
{
	public const uint32 _MM_HINT_T0 = 1;
	public const uint32 _MM_HINT_T1 = 2;
	public const uint32 _MM_HINT_T2 = 3;
	public const uint32 _MM_HINT_NTA = 0;
	public const uint32 ANYSIZE_ARRAY = 1;
	public const uint32 MEMORY_ALLOCATION_ALIGNMENT = 16;
	public const uint32 X86_CACHE_ALIGNMENT_SIZE = 64;
	public const uint32 ARM_CACHE_ALIGNMENT_SIZE = 128;
	public const uint32 SYSTEM_CACHE_ALIGNMENT_SIZE = 64;
	public const uint32 PRAGMA_DEPRECATED_DDK = 1;
	public const uint32 UCSCHAR_INVALID_CHARACTER = 4294967295;
	public const uint32 MIN_UCSCHAR = 0;
	public const uint32 MAX_UCSCHAR = 1114111;
	public const uint32 ALL_PROCESSOR_GROUPS = 65535;
	public const uint32 MAXIMUM_PROC_PER_GROUP = 64;
	public const uint32 MAXIMUM_PROCESSORS = 64;
	public const uint32 APPLICATION_ERROR_MASK = 536870912;
	public const uint32 ERROR_SEVERITY_SUCCESS = 0;
	public const uint32 ERROR_SEVERITY_INFORMATIONAL = 1073741824;
	public const uint32 ERROR_SEVERITY_WARNING = 2147483648;
	public const uint32 ERROR_SEVERITY_ERROR = 3221225472;
	public const uint64 MAXLONGLONG = 9223372036854775807;
	public const uint32 UNICODE_STRING_MAX_CHARS = 32767;
	public const uint32 MINCHAR = 128;
	public const uint32 MAXCHAR = 127;
	public const uint32 MINSHORT = 32768;
	public const uint32 MAXSHORT = 32767;
	public const uint32 MINLONG = 2147483648;
	public const uint32 MAXLONG = 2147483647;
	public const uint32 MAXBYTE = 255;
	public const uint32 MAXWORD = 65535;
	public const uint32 MAXDWORD = 4294967295;
	public const uint32 ENCLAVE_SHORT_ID_LENGTH = 16;
	public const uint32 ENCLAVE_LONG_ID_LENGTH = 32;
	public const uint32 VER_SERVER_NT = 2147483648;
	public const uint32 VER_WORKSTATION_NT = 1073741824;
	public const uint32 VER_SUITE_SMALLBUSINESS = 1;
	public const uint32 VER_SUITE_ENTERPRISE = 2;
	public const uint32 VER_SUITE_BACKOFFICE = 4;
	public const uint32 VER_SUITE_COMMUNICATIONS = 8;
	public const uint32 VER_SUITE_TERMINAL = 16;
	public const uint32 VER_SUITE_SMALLBUSINESS_RESTRICTED = 32;
	public const uint32 VER_SUITE_EMBEDDEDNT = 64;
	public const uint32 VER_SUITE_DATACENTER = 128;
	public const uint32 VER_SUITE_SINGLEUSERTS = 256;
	public const uint32 VER_SUITE_PERSONAL = 512;
	public const uint32 VER_SUITE_BLADE = 1024;
	public const uint32 VER_SUITE_EMBEDDED_RESTRICTED = 2048;
	public const uint32 VER_SUITE_SECURITY_APPLIANCE = 4096;
	public const uint32 VER_SUITE_STORAGE_SERVER = 8192;
	public const uint32 VER_SUITE_COMPUTE_SERVER = 16384;
	public const uint32 VER_SUITE_WH_SERVER = 32768;
	public const uint32 VER_SUITE_MULTIUSERTS = 131072;
	public const uint32 PRODUCT_STANDARD_SERVER_CORE = 13;
	public const uint32 PRODUCT_SOLUTION_EMBEDDEDSERVER_CORE = 57;
	public const uint32 PRODUCT_PROFESSIONAL_EMBEDDED = 58;
	public const uint32 PRODUCT_EMBEDDED = 65;
	public const uint32 PRODUCT_EMBEDDED_AUTOMOTIVE = 85;
	public const uint32 PRODUCT_EMBEDDED_INDUSTRY_A = 86;
	public const uint32 PRODUCT_THINPC = 87;
	public const uint32 PRODUCT_EMBEDDED_A = 88;
	public const uint32 PRODUCT_EMBEDDED_INDUSTRY = 89;
	public const uint32 PRODUCT_EMBEDDED_E = 90;
	public const uint32 PRODUCT_EMBEDDED_INDUSTRY_E = 91;
	public const uint32 PRODUCT_EMBEDDED_INDUSTRY_A_E = 92;
	public const uint32 PRODUCT_CORE_ARM = 97;
	public const uint32 PRODUCT_EMBEDDED_INDUSTRY_EVAL = 105;
	public const uint32 PRODUCT_EMBEDDED_INDUSTRY_E_EVAL = 106;
	public const uint32 PRODUCT_EMBEDDED_EVAL = 107;
	public const uint32 PRODUCT_EMBEDDED_E_EVAL = 108;
	public const uint32 PRODUCT_NANO_SERVER = 109;
	public const uint32 PRODUCT_CLOUD_STORAGE_SERVER = 110;
	public const uint32 PRODUCT_CORE_CONNECTED = 111;
	public const uint32 PRODUCT_PROFESSIONAL_STUDENT = 112;
	public const uint32 PRODUCT_CORE_CONNECTED_N = 113;
	public const uint32 PRODUCT_PROFESSIONAL_STUDENT_N = 114;
	public const uint32 PRODUCT_CORE_CONNECTED_SINGLELANGUAGE = 115;
	public const uint32 PRODUCT_CORE_CONNECTED_COUNTRYSPECIFIC = 116;
	public const uint32 PRODUCT_CONNECTED_CAR = 117;
	public const uint32 PRODUCT_INDUSTRY_HANDHELD = 118;
	public const uint32 PRODUCT_PPI_PRO = 119;
	public const uint32 PRODUCT_ARM64_SERVER = 120;
	public const uint32 PRODUCT_CLOUD_HOST_INFRASTRUCTURE_SERVER = 124;
	public const uint32 PRODUCT_PROFESSIONAL_S = 127;
	public const uint32 PRODUCT_PROFESSIONAL_S_N = 128;
	public const uint32 PRODUCT_HOLOGRAPHIC = 135;
	public const uint32 PRODUCT_HOLOGRAPHIC_BUSINESS = 136;
	public const uint32 PRODUCT_PRO_SINGLE_LANGUAGE = 138;
	public const uint32 PRODUCT_PRO_CHINA = 139;
	public const uint32 PRODUCT_ENTERPRISE_SUBSCRIPTION = 140;
	public const uint32 PRODUCT_ENTERPRISE_SUBSCRIPTION_N = 141;
	public const uint32 PRODUCT_DATACENTER_NANO_SERVER = 143;
	public const uint32 PRODUCT_STANDARD_NANO_SERVER = 144;
	public const uint32 PRODUCT_DATACENTER_WS_SERVER_CORE = 147;
	public const uint32 PRODUCT_STANDARD_WS_SERVER_CORE = 148;
	public const uint32 PRODUCT_UTILITY_VM = 149;
	public const uint32 PRODUCT_DATACENTER_EVALUATION_SERVER_CORE = 159;
	public const uint32 PRODUCT_STANDARD_EVALUATION_SERVER_CORE = 160;
	public const uint32 PRODUCT_PRO_FOR_EDUCATION = 164;
	public const uint32 PRODUCT_PRO_FOR_EDUCATION_N = 165;
	public const uint32 PRODUCT_AZURE_SERVER_CORE = 168;
	public const uint32 PRODUCT_AZURE_NANO_SERVER = 169;
	public const uint32 PRODUCT_ENTERPRISEG = 171;
	public const uint32 PRODUCT_ENTERPRISEGN = 172;
	public const uint32 PRODUCT_SERVERRDSH = 175;
	public const uint32 PRODUCT_CLOUD = 178;
	public const uint32 PRODUCT_CLOUDN = 179;
	public const uint32 PRODUCT_HUBOS = 180;
	public const uint32 PRODUCT_ONECOREUPDATEOS = 182;
	public const uint32 PRODUCT_CLOUDE = 183;
	public const uint32 PRODUCT_IOTOS = 185;
	public const uint32 PRODUCT_CLOUDEN = 186;
	public const uint32 PRODUCT_IOTEDGEOS = 187;
	public const uint32 PRODUCT_IOTENTERPRISE = 188;
	public const uint32 PRODUCT_LITE = 189;
	public const uint32 PRODUCT_IOTENTERPRISES = 191;
	public const uint32 PRODUCT_XBOX_SYSTEMOS = 192;
	public const uint32 PRODUCT_XBOX_NATIVEOS = 193;
	public const uint32 PRODUCT_XBOX_GAMEOS = 194;
	public const uint32 PRODUCT_XBOX_ERAOS = 195;
	public const uint32 PRODUCT_XBOX_DURANGOHOSTOS = 196;
	public const uint32 PRODUCT_XBOX_SCARLETTHOSTOS = 197;
	public const uint32 PRODUCT_AZURE_SERVER_CLOUDHOST = 199;
	public const uint32 PRODUCT_AZURE_SERVER_CLOUDMOS = 200;
	public const uint32 PRODUCT_CLOUDEDITIONN = 202;
	public const uint32 PRODUCT_CLOUDEDITION = 203;
	public const uint32 PRODUCT_AZURESTACKHCI_SERVER_CORE = 406;
	public const uint32 PRODUCT_DATACENTER_SERVER_AZURE_EDITION = 407;
	public const uint32 PRODUCT_DATACENTER_SERVER_CORE_AZURE_EDITION = 408;
	public const uint32 PRODUCT_UNLICENSED = 2882382797;
	public const uint32 LANG_NEUTRAL = 0;
	public const uint32 LANG_INVARIANT = 127;
	public const uint32 LANG_AFRIKAANS = 54;
	public const uint32 LANG_ALBANIAN = 28;
	public const uint32 LANG_ALSATIAN = 132;
	public const uint32 LANG_AMHARIC = 94;
	public const uint32 LANG_ARABIC = 1;
	public const uint32 LANG_ARMENIAN = 43;
	public const uint32 LANG_ASSAMESE = 77;
	public const uint32 LANG_AZERI = 44;
	public const uint32 LANG_AZERBAIJANI = 44;
	public const uint32 LANG_BANGLA = 69;
	public const uint32 LANG_BASHKIR = 109;
	public const uint32 LANG_BASQUE = 45;
	public const uint32 LANG_BELARUSIAN = 35;
	public const uint32 LANG_BENGALI = 69;
	public const uint32 LANG_BRETON = 126;
	public const uint32 LANG_BOSNIAN = 26;
	public const uint32 LANG_BOSNIAN_NEUTRAL = 30746;
	public const uint32 LANG_BULGARIAN = 2;
	public const uint32 LANG_CATALAN = 3;
	public const uint32 LANG_CENTRAL_KURDISH = 146;
	public const uint32 LANG_CHEROKEE = 92;
	public const uint32 LANG_CHINESE = 4;
	public const uint32 LANG_CHINESE_SIMPLIFIED = 4;
	public const uint32 LANG_CHINESE_TRADITIONAL = 31748;
	public const uint32 LANG_CORSICAN = 131;
	public const uint32 LANG_CROATIAN = 26;
	public const uint32 LANG_CZECH = 5;
	public const uint32 LANG_DANISH = 6;
	public const uint32 LANG_DARI = 140;
	public const uint32 LANG_DIVEHI = 101;
	public const uint32 LANG_DUTCH = 19;
	public const uint32 LANG_ENGLISH = 9;
	public const uint32 LANG_ESTONIAN = 37;
	public const uint32 LANG_FAEROESE = 56;
	public const uint32 LANG_FARSI = 41;
	public const uint32 LANG_FILIPINO = 100;
	public const uint32 LANG_FINNISH = 11;
	public const uint32 LANG_FRENCH = 12;
	public const uint32 LANG_FRISIAN = 98;
	public const uint32 LANG_FULAH = 103;
	public const uint32 LANG_GALICIAN = 86;
	public const uint32 LANG_GEORGIAN = 55;
	public const uint32 LANG_GERMAN = 7;
	public const uint32 LANG_GREEK = 8;
	public const uint32 LANG_GREENLANDIC = 111;
	public const uint32 LANG_GUJARATI = 71;
	public const uint32 LANG_HAUSA = 104;
	public const uint32 LANG_HAWAIIAN = 117;
	public const uint32 LANG_HEBREW = 13;
	public const uint32 LANG_HINDI = 57;
	public const uint32 LANG_HUNGARIAN = 14;
	public const uint32 LANG_ICELANDIC = 15;
	public const uint32 LANG_IGBO = 112;
	public const uint32 LANG_INDONESIAN = 33;
	public const uint32 LANG_INUKTITUT = 93;
	public const uint32 LANG_IRISH = 60;
	public const uint32 LANG_ITALIAN = 16;
	public const uint32 LANG_JAPANESE = 17;
	public const uint32 LANG_KANNADA = 75;
	public const uint32 LANG_KASHMIRI = 96;
	public const uint32 LANG_KAZAK = 63;
	public const uint32 LANG_KHMER = 83;
	public const uint32 LANG_KICHE = 134;
	public const uint32 LANG_KINYARWANDA = 135;
	public const uint32 LANG_KONKANI = 87;
	public const uint32 LANG_KOREAN = 18;
	public const uint32 LANG_KYRGYZ = 64;
	public const uint32 LANG_LAO = 84;
	public const uint32 LANG_LATVIAN = 38;
	public const uint32 LANG_LITHUANIAN = 39;
	public const uint32 LANG_LOWER_SORBIAN = 46;
	public const uint32 LANG_LUXEMBOURGISH = 110;
	public const uint32 LANG_MACEDONIAN = 47;
	public const uint32 LANG_MALAY = 62;
	public const uint32 LANG_MALAYALAM = 76;
	public const uint32 LANG_MALTESE = 58;
	public const uint32 LANG_MANIPURI = 88;
	public const uint32 LANG_MAORI = 129;
	public const uint32 LANG_MAPUDUNGUN = 122;
	public const uint32 LANG_MARATHI = 78;
	public const uint32 LANG_MOHAWK = 124;
	public const uint32 LANG_MONGOLIAN = 80;
	public const uint32 LANG_NEPALI = 97;
	public const uint32 LANG_NORWEGIAN = 20;
	public const uint32 LANG_OCCITAN = 130;
	public const uint32 LANG_ODIA = 72;
	public const uint32 LANG_ORIYA = 72;
	public const uint32 LANG_PASHTO = 99;
	public const uint32 LANG_PERSIAN = 41;
	public const uint32 LANG_POLISH = 21;
	public const uint32 LANG_PORTUGUESE = 22;
	public const uint32 LANG_PULAR = 103;
	public const uint32 LANG_PUNJABI = 70;
	public const uint32 LANG_QUECHUA = 107;
	public const uint32 LANG_ROMANIAN = 24;
	public const uint32 LANG_ROMANSH = 23;
	public const uint32 LANG_RUSSIAN = 25;
	public const uint32 LANG_SAKHA = 133;
	public const uint32 LANG_SAMI = 59;
	public const uint32 LANG_SANSKRIT = 79;
	public const uint32 LANG_SCOTTISH_GAELIC = 145;
	public const uint32 LANG_SERBIAN = 26;
	public const uint32 LANG_SERBIAN_NEUTRAL = 31770;
	public const uint32 LANG_SINDHI = 89;
	public const uint32 LANG_SINHALESE = 91;
	public const uint32 LANG_SLOVAK = 27;
	public const uint32 LANG_SLOVENIAN = 36;
	public const uint32 LANG_SOTHO = 108;
	public const uint32 LANG_SPANISH = 10;
	public const uint32 LANG_SWAHILI = 65;
	public const uint32 LANG_SWEDISH = 29;
	public const uint32 LANG_SYRIAC = 90;
	public const uint32 LANG_TAJIK = 40;
	public const uint32 LANG_TAMAZIGHT = 95;
	public const uint32 LANG_TAMIL = 73;
	public const uint32 LANG_TATAR = 68;
	public const uint32 LANG_TELUGU = 74;
	public const uint32 LANG_THAI = 30;
	public const uint32 LANG_TIBETAN = 81;
	public const uint32 LANG_TIGRIGNA = 115;
	public const uint32 LANG_TIGRINYA = 115;
	public const uint32 LANG_TSWANA = 50;
	public const uint32 LANG_TURKISH = 31;
	public const uint32 LANG_TURKMEN = 66;
	public const uint32 LANG_UIGHUR = 128;
	public const uint32 LANG_UKRAINIAN = 34;
	public const uint32 LANG_UPPER_SORBIAN = 46;
	public const uint32 LANG_URDU = 32;
	public const uint32 LANG_UZBEK = 67;
	public const uint32 LANG_VALENCIAN = 3;
	public const uint32 LANG_VIETNAMESE = 42;
	public const uint32 LANG_WELSH = 82;
	public const uint32 LANG_WOLOF = 136;
	public const uint32 LANG_XHOSA = 52;
	public const uint32 LANG_YAKUT = 133;
	public const uint32 LANG_YI = 120;
	public const uint32 LANG_YORUBA = 106;
	public const uint32 LANG_ZULU = 53;
	public const uint32 SUBLANG_NEUTRAL = 0;
	public const uint32 SUBLANG_DEFAULT = 1;
	public const uint32 SUBLANG_SYS_DEFAULT = 2;
	public const uint32 SUBLANG_CUSTOM_DEFAULT = 3;
	public const uint32 SUBLANG_CUSTOM_UNSPECIFIED = 4;
	public const uint32 SUBLANG_UI_CUSTOM_DEFAULT = 5;
	public const uint32 SUBLANG_AFRIKAANS_SOUTH_AFRICA = 1;
	public const uint32 SUBLANG_ALBANIAN_ALBANIA = 1;
	public const uint32 SUBLANG_ALSATIAN_FRANCE = 1;
	public const uint32 SUBLANG_AMHARIC_ETHIOPIA = 1;
	public const uint32 SUBLANG_ARABIC_SAUDI_ARABIA = 1;
	public const uint32 SUBLANG_ARABIC_IRAQ = 2;
	public const uint32 SUBLANG_ARABIC_EGYPT = 3;
	public const uint32 SUBLANG_ARABIC_LIBYA = 4;
	public const uint32 SUBLANG_ARABIC_ALGERIA = 5;
	public const uint32 SUBLANG_ARABIC_MOROCCO = 6;
	public const uint32 SUBLANG_ARABIC_TUNISIA = 7;
	public const uint32 SUBLANG_ARABIC_OMAN = 8;
	public const uint32 SUBLANG_ARABIC_YEMEN = 9;
	public const uint32 SUBLANG_ARABIC_SYRIA = 10;
	public const uint32 SUBLANG_ARABIC_JORDAN = 11;
	public const uint32 SUBLANG_ARABIC_LEBANON = 12;
	public const uint32 SUBLANG_ARABIC_KUWAIT = 13;
	public const uint32 SUBLANG_ARABIC_UAE = 14;
	public const uint32 SUBLANG_ARABIC_BAHRAIN = 15;
	public const uint32 SUBLANG_ARABIC_QATAR = 16;
	public const uint32 SUBLANG_ARMENIAN_ARMENIA = 1;
	public const uint32 SUBLANG_ASSAMESE_INDIA = 1;
	public const uint32 SUBLANG_AZERI_LATIN = 1;
	public const uint32 SUBLANG_AZERI_CYRILLIC = 2;
	public const uint32 SUBLANG_AZERBAIJANI_AZERBAIJAN_LATIN = 1;
	public const uint32 SUBLANG_AZERBAIJANI_AZERBAIJAN_CYRILLIC = 2;
	public const uint32 SUBLANG_BANGLA_INDIA = 1;
	public const uint32 SUBLANG_BANGLA_BANGLADESH = 2;
	public const uint32 SUBLANG_BASHKIR_RUSSIA = 1;
	public const uint32 SUBLANG_BASQUE_BASQUE = 1;
	public const uint32 SUBLANG_BELARUSIAN_BELARUS = 1;
	public const uint32 SUBLANG_BENGALI_INDIA = 1;
	public const uint32 SUBLANG_BENGALI_BANGLADESH = 2;
	public const uint32 SUBLANG_BOSNIAN_BOSNIA_HERZEGOVINA_LATIN = 5;
	public const uint32 SUBLANG_BOSNIAN_BOSNIA_HERZEGOVINA_CYRILLIC = 8;
	public const uint32 SUBLANG_BRETON_FRANCE = 1;
	public const uint32 SUBLANG_BULGARIAN_BULGARIA = 1;
	public const uint32 SUBLANG_CATALAN_CATALAN = 1;
	public const uint32 SUBLANG_CENTRAL_KURDISH_IRAQ = 1;
	public const uint32 SUBLANG_CHEROKEE_CHEROKEE = 1;
	public const uint32 SUBLANG_CHINESE_TRADITIONAL = 1;
	public const uint32 SUBLANG_CHINESE_SIMPLIFIED = 2;
	public const uint32 SUBLANG_CHINESE_HONGKONG = 3;
	public const uint32 SUBLANG_CHINESE_SINGAPORE = 4;
	public const uint32 SUBLANG_CHINESE_MACAU = 5;
	public const uint32 SUBLANG_CORSICAN_FRANCE = 1;
	public const uint32 SUBLANG_CZECH_CZECH_REPUBLIC = 1;
	public const uint32 SUBLANG_CROATIAN_CROATIA = 1;
	public const uint32 SUBLANG_CROATIAN_BOSNIA_HERZEGOVINA_LATIN = 4;
	public const uint32 SUBLANG_DANISH_DENMARK = 1;
	public const uint32 SUBLANG_DARI_AFGHANISTAN = 1;
	public const uint32 SUBLANG_DIVEHI_MALDIVES = 1;
	public const uint32 SUBLANG_DUTCH = 1;
	public const uint32 SUBLANG_DUTCH_BELGIAN = 2;
	public const uint32 SUBLANG_ENGLISH_US = 1;
	public const uint32 SUBLANG_ENGLISH_UK = 2;
	public const uint32 SUBLANG_ENGLISH_AUS = 3;
	public const uint32 SUBLANG_ENGLISH_CAN = 4;
	public const uint32 SUBLANG_ENGLISH_NZ = 5;
	public const uint32 SUBLANG_ENGLISH_EIRE = 6;
	public const uint32 SUBLANG_ENGLISH_SOUTH_AFRICA = 7;
	public const uint32 SUBLANG_ENGLISH_JAMAICA = 8;
	public const uint32 SUBLANG_ENGLISH_CARIBBEAN = 9;
	public const uint32 SUBLANG_ENGLISH_BELIZE = 10;
	public const uint32 SUBLANG_ENGLISH_TRINIDAD = 11;
	public const uint32 SUBLANG_ENGLISH_ZIMBABWE = 12;
	public const uint32 SUBLANG_ENGLISH_PHILIPPINES = 13;
	public const uint32 SUBLANG_ENGLISH_INDIA = 16;
	public const uint32 SUBLANG_ENGLISH_MALAYSIA = 17;
	public const uint32 SUBLANG_ENGLISH_SINGAPORE = 18;
	public const uint32 SUBLANG_ESTONIAN_ESTONIA = 1;
	public const uint32 SUBLANG_FAEROESE_FAROE_ISLANDS = 1;
	public const uint32 SUBLANG_FILIPINO_PHILIPPINES = 1;
	public const uint32 SUBLANG_FINNISH_FINLAND = 1;
	public const uint32 SUBLANG_FRENCH = 1;
	public const uint32 SUBLANG_FRENCH_BELGIAN = 2;
	public const uint32 SUBLANG_FRENCH_CANADIAN = 3;
	public const uint32 SUBLANG_FRENCH_SWISS = 4;
	public const uint32 SUBLANG_FRENCH_LUXEMBOURG = 5;
	public const uint32 SUBLANG_FRENCH_MONACO = 6;
	public const uint32 SUBLANG_FRISIAN_NETHERLANDS = 1;
	public const uint32 SUBLANG_FULAH_SENEGAL = 2;
	public const uint32 SUBLANG_GALICIAN_GALICIAN = 1;
	public const uint32 SUBLANG_GEORGIAN_GEORGIA = 1;
	public const uint32 SUBLANG_GERMAN = 1;
	public const uint32 SUBLANG_GERMAN_SWISS = 2;
	public const uint32 SUBLANG_GERMAN_AUSTRIAN = 3;
	public const uint32 SUBLANG_GERMAN_LUXEMBOURG = 4;
	public const uint32 SUBLANG_GERMAN_LIECHTENSTEIN = 5;
	public const uint32 SUBLANG_GREEK_GREECE = 1;
	public const uint32 SUBLANG_GREENLANDIC_GREENLAND = 1;
	public const uint32 SUBLANG_GUJARATI_INDIA = 1;
	public const uint32 SUBLANG_HAUSA_NIGERIA_LATIN = 1;
	public const uint32 SUBLANG_HAWAIIAN_US = 1;
	public const uint32 SUBLANG_HEBREW_ISRAEL = 1;
	public const uint32 SUBLANG_HINDI_INDIA = 1;
	public const uint32 SUBLANG_HUNGARIAN_HUNGARY = 1;
	public const uint32 SUBLANG_ICELANDIC_ICELAND = 1;
	public const uint32 SUBLANG_IGBO_NIGERIA = 1;
	public const uint32 SUBLANG_INDONESIAN_INDONESIA = 1;
	public const uint32 SUBLANG_INUKTITUT_CANADA = 1;
	public const uint32 SUBLANG_INUKTITUT_CANADA_LATIN = 2;
	public const uint32 SUBLANG_IRISH_IRELAND = 2;
	public const uint32 SUBLANG_ITALIAN = 1;
	public const uint32 SUBLANG_ITALIAN_SWISS = 2;
	public const uint32 SUBLANG_JAPANESE_JAPAN = 1;
	public const uint32 SUBLANG_KANNADA_INDIA = 1;
	public const uint32 SUBLANG_KASHMIRI_SASIA = 2;
	public const uint32 SUBLANG_KASHMIRI_INDIA = 2;
	public const uint32 SUBLANG_KAZAK_KAZAKHSTAN = 1;
	public const uint32 SUBLANG_KHMER_CAMBODIA = 1;
	public const uint32 SUBLANG_KICHE_GUATEMALA = 1;
	public const uint32 SUBLANG_KINYARWANDA_RWANDA = 1;
	public const uint32 SUBLANG_KONKANI_INDIA = 1;
	public const uint32 SUBLANG_KOREAN = 1;
	public const uint32 SUBLANG_KYRGYZ_KYRGYZSTAN = 1;
	public const uint32 SUBLANG_LAO_LAO = 1;
	public const uint32 SUBLANG_LATVIAN_LATVIA = 1;
	public const uint32 SUBLANG_LITHUANIAN = 1;
	public const uint32 SUBLANG_LOWER_SORBIAN_GERMANY = 2;
	public const uint32 SUBLANG_LUXEMBOURGISH_LUXEMBOURG = 1;
	public const uint32 SUBLANG_MACEDONIAN_MACEDONIA = 1;
	public const uint32 SUBLANG_MALAY_MALAYSIA = 1;
	public const uint32 SUBLANG_MALAY_BRUNEI_DARUSSALAM = 2;
	public const uint32 SUBLANG_MALAYALAM_INDIA = 1;
	public const uint32 SUBLANG_MALTESE_MALTA = 1;
	public const uint32 SUBLANG_MAORI_NEW_ZEALAND = 1;
	public const uint32 SUBLANG_MAPUDUNGUN_CHILE = 1;
	public const uint32 SUBLANG_MARATHI_INDIA = 1;
	public const uint32 SUBLANG_MOHAWK_MOHAWK = 1;
	public const uint32 SUBLANG_MONGOLIAN_CYRILLIC_MONGOLIA = 1;
	public const uint32 SUBLANG_MONGOLIAN_PRC = 2;
	public const uint32 SUBLANG_NEPALI_INDIA = 2;
	public const uint32 SUBLANG_NEPALI_NEPAL = 1;
	public const uint32 SUBLANG_NORWEGIAN_BOKMAL = 1;
	public const uint32 SUBLANG_NORWEGIAN_NYNORSK = 2;
	public const uint32 SUBLANG_OCCITAN_FRANCE = 1;
	public const uint32 SUBLANG_ODIA_INDIA = 1;
	public const uint32 SUBLANG_ORIYA_INDIA = 1;
	public const uint32 SUBLANG_PASHTO_AFGHANISTAN = 1;
	public const uint32 SUBLANG_PERSIAN_IRAN = 1;
	public const uint32 SUBLANG_POLISH_POLAND = 1;
	public const uint32 SUBLANG_PORTUGUESE = 2;
	public const uint32 SUBLANG_PORTUGUESE_BRAZILIAN = 1;
	public const uint32 SUBLANG_PULAR_SENEGAL = 2;
	public const uint32 SUBLANG_PUNJABI_INDIA = 1;
	public const uint32 SUBLANG_PUNJABI_PAKISTAN = 2;
	public const uint32 SUBLANG_QUECHUA_BOLIVIA = 1;
	public const uint32 SUBLANG_QUECHUA_ECUADOR = 2;
	public const uint32 SUBLANG_QUECHUA_PERU = 3;
	public const uint32 SUBLANG_ROMANIAN_ROMANIA = 1;
	public const uint32 SUBLANG_ROMANSH_SWITZERLAND = 1;
	public const uint32 SUBLANG_RUSSIAN_RUSSIA = 1;
	public const uint32 SUBLANG_SAKHA_RUSSIA = 1;
	public const uint32 SUBLANG_SAMI_NORTHERN_NORWAY = 1;
	public const uint32 SUBLANG_SAMI_NORTHERN_SWEDEN = 2;
	public const uint32 SUBLANG_SAMI_NORTHERN_FINLAND = 3;
	public const uint32 SUBLANG_SAMI_LULE_NORWAY = 4;
	public const uint32 SUBLANG_SAMI_LULE_SWEDEN = 5;
	public const uint32 SUBLANG_SAMI_SOUTHERN_NORWAY = 6;
	public const uint32 SUBLANG_SAMI_SOUTHERN_SWEDEN = 7;
	public const uint32 SUBLANG_SAMI_SKOLT_FINLAND = 8;
	public const uint32 SUBLANG_SAMI_INARI_FINLAND = 9;
	public const uint32 SUBLANG_SANSKRIT_INDIA = 1;
	public const uint32 SUBLANG_SCOTTISH_GAELIC = 1;
	public const uint32 SUBLANG_SERBIAN_BOSNIA_HERZEGOVINA_LATIN = 6;
	public const uint32 SUBLANG_SERBIAN_BOSNIA_HERZEGOVINA_CYRILLIC = 7;
	public const uint32 SUBLANG_SERBIAN_MONTENEGRO_LATIN = 11;
	public const uint32 SUBLANG_SERBIAN_MONTENEGRO_CYRILLIC = 12;
	public const uint32 SUBLANG_SERBIAN_SERBIA_LATIN = 9;
	public const uint32 SUBLANG_SERBIAN_SERBIA_CYRILLIC = 10;
	public const uint32 SUBLANG_SERBIAN_CROATIA = 1;
	public const uint32 SUBLANG_SERBIAN_LATIN = 2;
	public const uint32 SUBLANG_SERBIAN_CYRILLIC = 3;
	public const uint32 SUBLANG_SINDHI_INDIA = 1;
	public const uint32 SUBLANG_SINDHI_PAKISTAN = 2;
	public const uint32 SUBLANG_SINDHI_AFGHANISTAN = 2;
	public const uint32 SUBLANG_SINHALESE_SRI_LANKA = 1;
	public const uint32 SUBLANG_SOTHO_NORTHERN_SOUTH_AFRICA = 1;
	public const uint32 SUBLANG_SLOVAK_SLOVAKIA = 1;
	public const uint32 SUBLANG_SLOVENIAN_SLOVENIA = 1;
	public const uint32 SUBLANG_SPANISH = 1;
	public const uint32 SUBLANG_SPANISH_MEXICAN = 2;
	public const uint32 SUBLANG_SPANISH_MODERN = 3;
	public const uint32 SUBLANG_SPANISH_GUATEMALA = 4;
	public const uint32 SUBLANG_SPANISH_COSTA_RICA = 5;
	public const uint32 SUBLANG_SPANISH_PANAMA = 6;
	public const uint32 SUBLANG_SPANISH_DOMINICAN_REPUBLIC = 7;
	public const uint32 SUBLANG_SPANISH_VENEZUELA = 8;
	public const uint32 SUBLANG_SPANISH_COLOMBIA = 9;
	public const uint32 SUBLANG_SPANISH_PERU = 10;
	public const uint32 SUBLANG_SPANISH_ARGENTINA = 11;
	public const uint32 SUBLANG_SPANISH_ECUADOR = 12;
	public const uint32 SUBLANG_SPANISH_CHILE = 13;
	public const uint32 SUBLANG_SPANISH_URUGUAY = 14;
	public const uint32 SUBLANG_SPANISH_PARAGUAY = 15;
	public const uint32 SUBLANG_SPANISH_BOLIVIA = 16;
	public const uint32 SUBLANG_SPANISH_EL_SALVADOR = 17;
	public const uint32 SUBLANG_SPANISH_HONDURAS = 18;
	public const uint32 SUBLANG_SPANISH_NICARAGUA = 19;
	public const uint32 SUBLANG_SPANISH_PUERTO_RICO = 20;
	public const uint32 SUBLANG_SPANISH_US = 21;
	public const uint32 SUBLANG_SWAHILI_KENYA = 1;
	public const uint32 SUBLANG_SWEDISH = 1;
	public const uint32 SUBLANG_SWEDISH_FINLAND = 2;
	public const uint32 SUBLANG_SYRIAC_SYRIA = 1;
	public const uint32 SUBLANG_TAJIK_TAJIKISTAN = 1;
	public const uint32 SUBLANG_TAMAZIGHT_ALGERIA_LATIN = 2;
	public const uint32 SUBLANG_TAMAZIGHT_MOROCCO_TIFINAGH = 4;
	public const uint32 SUBLANG_TAMIL_INDIA = 1;
	public const uint32 SUBLANG_TAMIL_SRI_LANKA = 2;
	public const uint32 SUBLANG_TATAR_RUSSIA = 1;
	public const uint32 SUBLANG_TELUGU_INDIA = 1;
	public const uint32 SUBLANG_THAI_THAILAND = 1;
	public const uint32 SUBLANG_TIBETAN_PRC = 1;
	public const uint32 SUBLANG_TIGRIGNA_ERITREA = 2;
	public const uint32 SUBLANG_TIGRINYA_ERITREA = 2;
	public const uint32 SUBLANG_TIGRINYA_ETHIOPIA = 1;
	public const uint32 SUBLANG_TSWANA_BOTSWANA = 2;
	public const uint32 SUBLANG_TSWANA_SOUTH_AFRICA = 1;
	public const uint32 SUBLANG_TURKISH_TURKEY = 1;
	public const uint32 SUBLANG_TURKMEN_TURKMENISTAN = 1;
	public const uint32 SUBLANG_UIGHUR_PRC = 1;
	public const uint32 SUBLANG_UKRAINIAN_UKRAINE = 1;
	public const uint32 SUBLANG_UPPER_SORBIAN_GERMANY = 1;
	public const uint32 SUBLANG_URDU_PAKISTAN = 1;
	public const uint32 SUBLANG_URDU_INDIA = 2;
	public const uint32 SUBLANG_UZBEK_LATIN = 1;
	public const uint32 SUBLANG_UZBEK_CYRILLIC = 2;
	public const uint32 SUBLANG_VALENCIAN_VALENCIA = 2;
	public const uint32 SUBLANG_VIETNAMESE_VIETNAM = 1;
	public const uint32 SUBLANG_WELSH_UNITED_KINGDOM = 1;
	public const uint32 SUBLANG_WOLOF_SENEGAL = 1;
	public const uint32 SUBLANG_XHOSA_SOUTH_AFRICA = 1;
	public const uint32 SUBLANG_YAKUT_RUSSIA = 1;
	public const uint32 SUBLANG_YI_PRC = 1;
	public const uint32 SUBLANG_YORUBA_NIGERIA = 1;
	public const uint32 SUBLANG_ZULU_SOUTH_AFRICA = 1;
	public const uint32 SORT_DEFAULT = 0;
	public const uint32 SORT_INVARIANT_MATH = 1;
	public const uint32 SORT_JAPANESE_XJIS = 0;
	public const uint32 SORT_JAPANESE_UNICODE = 1;
	public const uint32 SORT_JAPANESE_RADICALSTROKE = 4;
	public const uint32 SORT_CHINESE_BIG5 = 0;
	public const uint32 SORT_CHINESE_PRCP = 0;
	public const uint32 SORT_CHINESE_UNICODE = 1;
	public const uint32 SORT_CHINESE_PRC = 2;
	public const uint32 SORT_CHINESE_BOPOMOFO = 3;
	public const uint32 SORT_CHINESE_RADICALSTROKE = 4;
	public const uint32 SORT_KOREAN_KSC = 0;
	public const uint32 SORT_KOREAN_UNICODE = 1;
	public const uint32 SORT_GERMAN_PHONE_BOOK = 1;
	public const uint32 SORT_HUNGARIAN_DEFAULT = 0;
	public const uint32 SORT_HUNGARIAN_TECHNICAL = 1;
	public const uint32 SORT_GEORGIAN_TRADITIONAL = 0;
	public const uint32 SORT_GEORGIAN_MODERN = 1;
	public const uint32 NLS_VALID_LOCALE_MASK = 1048575;
	public const uint32 LOCALE_NAME_MAX_LENGTH = 85;
	public const uint32 LOCALE_TRANSIENT_KEYBOARD1 = 8192;
	public const uint32 LOCALE_TRANSIENT_KEYBOARD2 = 9216;
	public const uint32 LOCALE_TRANSIENT_KEYBOARD3 = 10240;
	public const uint32 LOCALE_TRANSIENT_KEYBOARD4 = 11264;
	public const uint32 MAXIMUM_WAIT_OBJECTS = 64;
	public const uint32 MAXIMUM_SUSPEND_COUNT = 127;
	public const uint32 PF_TEMPORAL_LEVEL_1 = 1;
	public const uint32 PF_TEMPORAL_LEVEL_2 = 2;
	public const uint32 PF_TEMPORAL_LEVEL_3 = 3;
	public const uint32 PF_NON_TEMPORAL_LEVEL_ALL = 0;
	public const uint32 EXCEPTION_READ_FAULT = 0;
	public const uint32 EXCEPTION_WRITE_FAULT = 1;
	public const uint32 EXCEPTION_EXECUTE_FAULT = 8;
	public const int32 CONTEXT_AMD64 = 1048576;
	public const int32 CONTEXT_KERNEL_DEBUGGER = 67108864;
	public const int32 CONTEXT_EXCEPTION_ACTIVE = 134217728;
	public const int32 CONTEXT_SERVICE_ACTIVE = 268435456;
	public const int32 CONTEXT_EXCEPTION_REQUEST = 1073741824;
	public const int32 CONTEXT_EXCEPTION_REPORTING = -2147483648;
	public const uint32 CONTEXT_UNWOUND_TO_CALL = 536870912;
	public const uint32 INITIAL_MXCSR = 8064;
	public const uint32 INITIAL_FPCSR = 639;
	public const uint32 RUNTIME_FUNCTION_INDIRECT = 1;
	public const uint32 UNW_FLAG_NO_EPILOGUE = 2147483648;
	public const uint32 UNWIND_CHAIN_LIMIT = 32;
	public const String OUT_OF_PROCESS_FUNCTION_TABLE_CALLBACK_EXPORT_NAME = "OutOfProcessFunctionTableCallback";
	public const int32 CONTEXT_ARM = 2097152;
	public const uint32 INITIAL_CPSR = 16;
	public const uint32 INITIAL_FPSCR = 0;
	public const uint32 ARM_MAX_BREAKPOINTS = 8;
	public const uint32 ARM_MAX_WATCHPOINTS = 1;
	public const uint32 ARM64_PREFETCH_PLD = 0;
	public const uint32 ARM64_PREFETCH_PLI = 8;
	public const uint32 ARM64_PREFETCH_PST = 16;
	public const uint32 ARM64_PREFETCH_L1 = 0;
	public const uint32 ARM64_PREFETCH_L2 = 2;
	public const uint32 ARM64_PREFETCH_L3 = 4;
	public const uint32 ARM64_PREFETCH_KEEP = 0;
	public const uint32 ARM64_PREFETCH_STRM = 1;
	public const uint32 ARM64_MULT_INTRINSICS_SUPPORTED = 1;
	public const int32 CONTEXT_ARM64 = 4194304;
	public const uint32 CONTEXT_ARM64_UNWOUND_TO_CALL = 536870912;
	public const uint32 CONTEXT_ARM64_RET_TO_GUEST = 67108864;
	public const uint32 CONTEXT_RET_TO_GUEST = 67108864;
	public const uint32 ARM64_MAX_BREAKPOINTS = 8;
	public const uint32 ARM64_MAX_WATCHPOINTS = 2;
	public const uint32 NONVOL_INT_NUMREG_ARM64 = 11;
	public const uint32 NONVOL_FP_NUMREG_ARM64 = 8;
	public const uint32 BREAK_DEBUG_BASE = 524288;
	public const uint32 ASSERT_BREAKPOINT = 524291;
	public const uint32 SIZE_OF_80387_REGISTERS = 80;
	public const int32 CONTEXT_i386 = 65536;
	public const int32 CONTEXT_i486 = 65536;
	public const uint32 MAXIMUM_SUPPORTED_EXTENSION = 512;
	public const uint32 EXCEPTION_NONCONTINUABLE = 1;
	public const uint32 EXCEPTION_UNWINDING = 2;
	public const uint32 EXCEPTION_EXIT_UNWIND = 4;
	public const uint32 EXCEPTION_STACK_INVALID = 8;
	public const uint32 EXCEPTION_NESTED_CALL = 16;
	public const uint32 EXCEPTION_TARGET_UNWIND = 32;
	public const uint32 EXCEPTION_COLLIDED_UNWIND = 64;
	public const uint32 EXCEPTION_SOFTWARE_ORIGINATE = 128;
	public const uint32 EXCEPTION_MAXIMUM_PARAMETERS = 15;
	public const uint32 ACCESS_SYSTEM_SECURITY = 16777216;
	public const uint32 MAXIMUM_ALLOWED = 33554432;
	public const uint32 GENERIC_READ = 2147483648;
	public const uint32 GENERIC_WRITE = 1073741824;
	public const uint32 GENERIC_EXECUTE = 536870912;
	public const uint32 GENERIC_ALL = 268435456;
	public const uint32 SID_REVISION = 1;
	public const uint32 SID_MAX_SUB_AUTHORITIES = 15;
	public const uint32 SID_RECOMMENDED_SUB_AUTHORITIES = 1;
	public const uint32 SID_HASH_SIZE = 32;
	public const int32 SECURITY_NULL_RID = 0;
	public const int32 SECURITY_WORLD_RID = 0;
	public const int32 SECURITY_LOCAL_RID = 0;
	public const int32 SECURITY_LOCAL_LOGON_RID = 1;
	public const int32 SECURITY_CREATOR_OWNER_RID = 0;
	public const int32 SECURITY_CREATOR_GROUP_RID = 1;
	public const int32 SECURITY_CREATOR_OWNER_SERVER_RID = 2;
	public const int32 SECURITY_CREATOR_GROUP_SERVER_RID = 3;
	public const int32 SECURITY_CREATOR_OWNER_RIGHTS_RID = 4;
	public const int32 SECURITY_DIALUP_RID = 1;
	public const int32 SECURITY_NETWORK_RID = 2;
	public const int32 SECURITY_BATCH_RID = 3;
	public const int32 SECURITY_INTERACTIVE_RID = 4;
	public const int32 SECURITY_LOGON_IDS_RID = 5;
	public const int32 SECURITY_LOGON_IDS_RID_COUNT = 3;
	public const int32 SECURITY_SERVICE_RID = 6;
	public const int32 SECURITY_ANONYMOUS_LOGON_RID = 7;
	public const int32 SECURITY_PROXY_RID = 8;
	public const int32 SECURITY_ENTERPRISE_CONTROLLERS_RID = 9;
	public const int32 SECURITY_SERVER_LOGON_RID = 9;
	public const int32 SECURITY_PRINCIPAL_SELF_RID = 10;
	public const int32 SECURITY_AUTHENTICATED_USER_RID = 11;
	public const int32 SECURITY_RESTRICTED_CODE_RID = 12;
	public const int32 SECURITY_TERMINAL_SERVER_RID = 13;
	public const int32 SECURITY_REMOTE_LOGON_RID = 14;
	public const int32 SECURITY_THIS_ORGANIZATION_RID = 15;
	public const int32 SECURITY_IUSER_RID = 17;
	public const int32 SECURITY_LOCAL_SYSTEM_RID = 18;
	public const int32 SECURITY_LOCAL_SERVICE_RID = 19;
	public const int32 SECURITY_NETWORK_SERVICE_RID = 20;
	public const int32 SECURITY_NT_NON_UNIQUE = 21;
	public const int32 SECURITY_NT_NON_UNIQUE_SUB_AUTH_COUNT = 3;
	public const int32 SECURITY_ENTERPRISE_READONLY_CONTROLLERS_RID = 22;
	public const int32 SECURITY_BUILTIN_DOMAIN_RID = 32;
	public const int32 SECURITY_WRITE_RESTRICTED_CODE_RID = 33;
	public const int32 SECURITY_PACKAGE_BASE_RID = 64;
	public const int32 SECURITY_PACKAGE_RID_COUNT = 2;
	public const int32 SECURITY_PACKAGE_NTLM_RID = 10;
	public const int32 SECURITY_PACKAGE_SCHANNEL_RID = 14;
	public const int32 SECURITY_PACKAGE_DIGEST_RID = 21;
	public const int32 SECURITY_CRED_TYPE_BASE_RID = 65;
	public const int32 SECURITY_CRED_TYPE_RID_COUNT = 2;
	public const int32 SECURITY_CRED_TYPE_THIS_ORG_CERT_RID = 1;
	public const int32 SECURITY_MIN_BASE_RID = 80;
	public const int32 SECURITY_SERVICE_ID_BASE_RID = 80;
	public const int32 SECURITY_SERVICE_ID_RID_COUNT = 6;
	public const int32 SECURITY_RESERVED_ID_BASE_RID = 81;
	public const int32 SECURITY_APPPOOL_ID_BASE_RID = 82;
	public const int32 SECURITY_APPPOOL_ID_RID_COUNT = 6;
	public const int32 SECURITY_VIRTUALSERVER_ID_BASE_RID = 83;
	public const int32 SECURITY_VIRTUALSERVER_ID_RID_COUNT = 6;
	public const int32 SECURITY_USERMODEDRIVERHOST_ID_BASE_RID = 84;
	public const int32 SECURITY_USERMODEDRIVERHOST_ID_RID_COUNT = 6;
	public const int32 SECURITY_CLOUD_INFRASTRUCTURE_SERVICES_ID_BASE_RID = 85;
	public const int32 SECURITY_CLOUD_INFRASTRUCTURE_SERVICES_ID_RID_COUNT = 6;
	public const int32 SECURITY_WMIHOST_ID_BASE_RID = 86;
	public const int32 SECURITY_WMIHOST_ID_RID_COUNT = 6;
	public const int32 SECURITY_TASK_ID_BASE_RID = 87;
	public const int32 SECURITY_NFS_ID_BASE_RID = 88;
	public const int32 SECURITY_COM_ID_BASE_RID = 89;
	public const int32 SECURITY_WINDOW_MANAGER_BASE_RID = 90;
	public const int32 SECURITY_RDV_GFX_BASE_RID = 91;
	public const int32 SECURITY_DASHOST_ID_BASE_RID = 92;
	public const int32 SECURITY_DASHOST_ID_RID_COUNT = 6;
	public const int32 SECURITY_USERMANAGER_ID_BASE_RID = 93;
	public const int32 SECURITY_USERMANAGER_ID_RID_COUNT = 6;
	public const int32 SECURITY_WINRM_ID_BASE_RID = 94;
	public const int32 SECURITY_WINRM_ID_RID_COUNT = 6;
	public const int32 SECURITY_CCG_ID_BASE_RID = 95;
	public const int32 SECURITY_UMFD_BASE_RID = 96;
	public const int32 SECURITY_VIRTUALACCOUNT_ID_RID_COUNT = 6;
	public const int32 SECURITY_MAX_BASE_RID = 111;
	public const int32 SECURITY_MAX_ALWAYS_FILTERED = 999;
	public const int32 SECURITY_MIN_NEVER_FILTERED = 1000;
	public const int32 SECURITY_OTHER_ORGANIZATION_RID = 1000;
	public const int32 SECURITY_WINDOWSMOBILE_ID_BASE_RID = 112;
	public const uint32 SECURITY_INSTALLER_GROUP_CAPABILITY_BASE = 32;
	public const uint32 SECURITY_INSTALLER_GROUP_CAPABILITY_RID_COUNT = 9;
	public const uint32 SECURITY_INSTALLER_CAPABILITY_RID_COUNT = 10;
	public const int32 SECURITY_LOCAL_ACCOUNT_RID = 113;
	public const int32 SECURITY_LOCAL_ACCOUNT_AND_ADMIN_RID = 114;
	public const int32 DOMAIN_GROUP_RID_AUTHORIZATION_DATA_IS_COMPOUNDED = 496;
	public const int32 DOMAIN_GROUP_RID_AUTHORIZATION_DATA_CONTAINS_CLAIMS = 497;
	public const int32 DOMAIN_GROUP_RID_ENTERPRISE_READONLY_DOMAIN_CONTROLLERS = 498;
	public const int32 FOREST_USER_RID_MAX = 499;
	public const int32 DOMAIN_USER_RID_ADMIN = 500;
	public const int32 DOMAIN_USER_RID_GUEST = 501;
	public const int32 DOMAIN_USER_RID_KRBTGT = 502;
	public const int32 DOMAIN_USER_RID_DEFAULT_ACCOUNT = 503;
	public const int32 DOMAIN_USER_RID_WDAG_ACCOUNT = 504;
	public const int32 DOMAIN_USER_RID_MAX = 999;
	public const int32 DOMAIN_GROUP_RID_ADMINS = 512;
	public const int32 DOMAIN_GROUP_RID_USERS = 513;
	public const int32 DOMAIN_GROUP_RID_GUESTS = 514;
	public const int32 DOMAIN_GROUP_RID_COMPUTERS = 515;
	public const int32 DOMAIN_GROUP_RID_CONTROLLERS = 516;
	public const int32 DOMAIN_GROUP_RID_CERT_ADMINS = 517;
	public const int32 DOMAIN_GROUP_RID_SCHEMA_ADMINS = 518;
	public const int32 DOMAIN_GROUP_RID_ENTERPRISE_ADMINS = 519;
	public const int32 DOMAIN_GROUP_RID_POLICY_ADMINS = 520;
	public const int32 DOMAIN_GROUP_RID_READONLY_CONTROLLERS = 521;
	public const int32 DOMAIN_GROUP_RID_CLONEABLE_CONTROLLERS = 522;
	public const int32 DOMAIN_GROUP_RID_CDC_RESERVED = 524;
	public const int32 DOMAIN_GROUP_RID_PROTECTED_USERS = 525;
	public const int32 DOMAIN_GROUP_RID_KEY_ADMINS = 526;
	public const int32 DOMAIN_GROUP_RID_ENTERPRISE_KEY_ADMINS = 527;
	public const int32 DOMAIN_ALIAS_RID_ADMINS = 544;
	public const int32 DOMAIN_ALIAS_RID_USERS = 545;
	public const int32 DOMAIN_ALIAS_RID_GUESTS = 546;
	public const int32 DOMAIN_ALIAS_RID_POWER_USERS = 547;
	public const int32 DOMAIN_ALIAS_RID_ACCOUNT_OPS = 548;
	public const int32 DOMAIN_ALIAS_RID_SYSTEM_OPS = 549;
	public const int32 DOMAIN_ALIAS_RID_PRINT_OPS = 550;
	public const int32 DOMAIN_ALIAS_RID_BACKUP_OPS = 551;
	public const int32 DOMAIN_ALIAS_RID_REPLICATOR = 552;
	public const int32 DOMAIN_ALIAS_RID_RAS_SERVERS = 553;
	public const int32 DOMAIN_ALIAS_RID_PREW2KCOMPACCESS = 554;
	public const int32 DOMAIN_ALIAS_RID_REMOTE_DESKTOP_USERS = 555;
	public const int32 DOMAIN_ALIAS_RID_NETWORK_CONFIGURATION_OPS = 556;
	public const int32 DOMAIN_ALIAS_RID_INCOMING_FOREST_TRUST_BUILDERS = 557;
	public const int32 DOMAIN_ALIAS_RID_MONITORING_USERS = 558;
	public const int32 DOMAIN_ALIAS_RID_LOGGING_USERS = 559;
	public const int32 DOMAIN_ALIAS_RID_AUTHORIZATIONACCESS = 560;
	public const int32 DOMAIN_ALIAS_RID_TS_LICENSE_SERVERS = 561;
	public const int32 DOMAIN_ALIAS_RID_DCOM_USERS = 562;
	public const int32 DOMAIN_ALIAS_RID_IUSERS = 568;
	public const int32 DOMAIN_ALIAS_RID_CRYPTO_OPERATORS = 569;
	public const int32 DOMAIN_ALIAS_RID_CACHEABLE_PRINCIPALS_GROUP = 571;
	public const int32 DOMAIN_ALIAS_RID_NON_CACHEABLE_PRINCIPALS_GROUP = 572;
	public const int32 DOMAIN_ALIAS_RID_EVENT_LOG_READERS_GROUP = 573;
	public const int32 DOMAIN_ALIAS_RID_CERTSVC_DCOM_ACCESS_GROUP = 574;
	public const int32 DOMAIN_ALIAS_RID_RDS_REMOTE_ACCESS_SERVERS = 575;
	public const int32 DOMAIN_ALIAS_RID_RDS_ENDPOINT_SERVERS = 576;
	public const int32 DOMAIN_ALIAS_RID_RDS_MANAGEMENT_SERVERS = 577;
	public const int32 DOMAIN_ALIAS_RID_HYPER_V_ADMINS = 578;
	public const int32 DOMAIN_ALIAS_RID_ACCESS_CONTROL_ASSISTANCE_OPS = 579;
	public const int32 DOMAIN_ALIAS_RID_REMOTE_MANAGEMENT_USERS = 580;
	public const int32 DOMAIN_ALIAS_RID_DEFAULT_ACCOUNT = 581;
	public const int32 DOMAIN_ALIAS_RID_STORAGE_REPLICA_ADMINS = 582;
	public const int32 DOMAIN_ALIAS_RID_DEVICE_OWNERS = 583;
	public const int32 SECURITY_APP_PACKAGE_BASE_RID = 2;
	public const int32 SECURITY_BUILTIN_APP_PACKAGE_RID_COUNT = 2;
	public const int32 SECURITY_APP_PACKAGE_RID_COUNT = 8;
	public const int32 SECURITY_CAPABILITY_BASE_RID = 3;
	public const uint64 SECURITY_CAPABILITY_APP_RID = 1024;
	public const int32 SECURITY_BUILTIN_CAPABILITY_RID_COUNT = 2;
	public const int32 SECURITY_CAPABILITY_RID_COUNT = 5;
	public const int32 SECURITY_PARENT_PACKAGE_RID_COUNT = 8;
	public const int32 SECURITY_CHILD_PACKAGE_RID_COUNT = 12;
	public const int32 SECURITY_BUILTIN_PACKAGE_ANY_PACKAGE = 1;
	public const int32 SECURITY_BUILTIN_PACKAGE_ANY_RESTRICTED_PACKAGE = 2;
	public const int32 SECURITY_CAPABILITY_INTERNET_CLIENT = 1;
	public const int32 SECURITY_CAPABILITY_INTERNET_CLIENT_SERVER = 2;
	public const int32 SECURITY_CAPABILITY_PRIVATE_NETWORK_CLIENT_SERVER = 3;
	public const int32 SECURITY_CAPABILITY_PICTURES_LIBRARY = 4;
	public const int32 SECURITY_CAPABILITY_VIDEOS_LIBRARY = 5;
	public const int32 SECURITY_CAPABILITY_MUSIC_LIBRARY = 6;
	public const int32 SECURITY_CAPABILITY_DOCUMENTS_LIBRARY = 7;
	public const int32 SECURITY_CAPABILITY_ENTERPRISE_AUTHENTICATION = 8;
	public const int32 SECURITY_CAPABILITY_SHARED_USER_CERTIFICATES = 9;
	public const int32 SECURITY_CAPABILITY_REMOVABLE_STORAGE = 10;
	public const int32 SECURITY_CAPABILITY_APPOINTMENTS = 11;
	public const int32 SECURITY_CAPABILITY_CONTACTS = 12;
	public const int32 SECURITY_CAPABILITY_INTERNET_EXPLORER = 4096;
	public const int32 SECURITY_MANDATORY_UNTRUSTED_RID = 0;
	public const int32 SECURITY_MANDATORY_LOW_RID = 4096;
	public const int32 SECURITY_MANDATORY_MEDIUM_RID = 8192;
	public const uint32 SECURITY_MANDATORY_MEDIUM_PLUS_RID = 8448;
	public const int32 SECURITY_MANDATORY_HIGH_RID = 12288;
	public const int32 SECURITY_MANDATORY_SYSTEM_RID = 16384;
	public const int32 SECURITY_MANDATORY_PROTECTED_PROCESS_RID = 20480;
	public const int32 SECURITY_MANDATORY_MAXIMUM_USER_RID = 16384;
	public const int32 SECURITY_AUTHENTICATION_AUTHORITY_RID_COUNT = 1;
	public const int32 SECURITY_AUTHENTICATION_AUTHORITY_ASSERTED_RID = 1;
	public const int32 SECURITY_AUTHENTICATION_SERVICE_ASSERTED_RID = 2;
	public const int32 SECURITY_AUTHENTICATION_FRESH_KEY_AUTH_RID = 3;
	public const int32 SECURITY_AUTHENTICATION_KEY_TRUST_RID = 4;
	public const int32 SECURITY_AUTHENTICATION_KEY_PROPERTY_MFA_RID = 5;
	public const int32 SECURITY_AUTHENTICATION_KEY_PROPERTY_ATTESTATION_RID = 6;
	public const int32 SECURITY_PROCESS_TRUST_AUTHORITY_RID_COUNT = 2;
	public const int32 SECURITY_PROCESS_PROTECTION_TYPE_FULL_RID = 1024;
	public const int32 SECURITY_PROCESS_PROTECTION_TYPE_LITE_RID = 512;
	public const int32 SECURITY_PROCESS_PROTECTION_TYPE_NONE_RID = 0;
	public const int32 SECURITY_PROCESS_PROTECTION_LEVEL_WINTCB_RID = 8192;
	public const int32 SECURITY_PROCESS_PROTECTION_LEVEL_WINDOWS_RID = 4096;
	public const int32 SECURITY_PROCESS_PROTECTION_LEVEL_APP_RID = 2048;
	public const int32 SECURITY_PROCESS_PROTECTION_LEVEL_ANTIMALWARE_RID = 1536;
	public const int32 SECURITY_PROCESS_PROTECTION_LEVEL_AUTHENTICODE_RID = 1024;
	public const int32 SECURITY_PROCESS_PROTECTION_LEVEL_NONE_RID = 0;
	public const uint32 SECURITY_TRUSTED_INSTALLER_RID1 = 956008885;
	public const uint32 SECURITY_TRUSTED_INSTALLER_RID2 = 3418522649;
	public const uint32 SECURITY_TRUSTED_INSTALLER_RID3 = 1831038044;
	public const uint32 SECURITY_TRUSTED_INSTALLER_RID4 = 1853292631;
	public const uint32 SECURITY_TRUSTED_INSTALLER_RID5 = 2271478464;
	public const int32 SE_GROUP_MANDATORY = 1;
	public const int32 SE_GROUP_ENABLED_BY_DEFAULT = 2;
	public const int32 SE_GROUP_ENABLED = 4;
	public const int32 SE_GROUP_OWNER = 8;
	public const int32 SE_GROUP_USE_FOR_DENY_ONLY = 16;
	public const int32 SE_GROUP_INTEGRITY = 32;
	public const int32 SE_GROUP_INTEGRITY_ENABLED = 64;
	public const int32 SE_GROUP_LOGON_ID = -1073741824;
	public const int32 SE_GROUP_RESOURCE = 536870912;
	public const uint32 ACL_REVISION1 = 1;
	public const uint32 ACL_REVISION2 = 2;
	public const uint32 ACL_REVISION3 = 3;
	public const uint32 ACL_REVISION4 = 4;
	public const uint32 MAX_ACL_REVISION = 4;
	public const uint32 ACCESS_MIN_MS_ACE_TYPE = 0;
	public const uint32 ACCESS_ALLOWED_ACE_TYPE = 0;
	public const uint32 ACCESS_DENIED_ACE_TYPE = 1;
	public const uint32 SYSTEM_AUDIT_ACE_TYPE = 2;
	public const uint32 SYSTEM_ALARM_ACE_TYPE = 3;
	public const uint32 ACCESS_MAX_MS_V2_ACE_TYPE = 3;
	public const uint32 ACCESS_ALLOWED_COMPOUND_ACE_TYPE = 4;
	public const uint32 ACCESS_MAX_MS_V3_ACE_TYPE = 4;
	public const uint32 ACCESS_MIN_MS_OBJECT_ACE_TYPE = 5;
	public const uint32 ACCESS_ALLOWED_OBJECT_ACE_TYPE = 5;
	public const uint32 ACCESS_DENIED_OBJECT_ACE_TYPE = 6;
	public const uint32 SYSTEM_AUDIT_OBJECT_ACE_TYPE = 7;
	public const uint32 SYSTEM_ALARM_OBJECT_ACE_TYPE = 8;
	public const uint32 ACCESS_MAX_MS_OBJECT_ACE_TYPE = 8;
	public const uint32 ACCESS_MAX_MS_V4_ACE_TYPE = 8;
	public const uint32 ACCESS_MAX_MS_ACE_TYPE = 8;
	public const uint32 ACCESS_ALLOWED_CALLBACK_ACE_TYPE = 9;
	public const uint32 ACCESS_DENIED_CALLBACK_ACE_TYPE = 10;
	public const uint32 ACCESS_ALLOWED_CALLBACK_OBJECT_ACE_TYPE = 11;
	public const uint32 ACCESS_DENIED_CALLBACK_OBJECT_ACE_TYPE = 12;
	public const uint32 SYSTEM_AUDIT_CALLBACK_ACE_TYPE = 13;
	public const uint32 SYSTEM_ALARM_CALLBACK_ACE_TYPE = 14;
	public const uint32 SYSTEM_AUDIT_CALLBACK_OBJECT_ACE_TYPE = 15;
	public const uint32 SYSTEM_ALARM_CALLBACK_OBJECT_ACE_TYPE = 16;
	public const uint32 SYSTEM_MANDATORY_LABEL_ACE_TYPE = 17;
	public const uint32 SYSTEM_RESOURCE_ATTRIBUTE_ACE_TYPE = 18;
	public const uint32 SYSTEM_SCOPED_POLICY_ID_ACE_TYPE = 19;
	public const uint32 SYSTEM_PROCESS_TRUST_LABEL_ACE_TYPE = 20;
	public const uint32 SYSTEM_ACCESS_FILTER_ACE_TYPE = 21;
	public const uint32 ACCESS_MAX_MS_V5_ACE_TYPE = 21;
	public const uint32 VALID_INHERIT_FLAGS = 31;
	public const uint32 CRITICAL_ACE_FLAG = 32;
	public const uint32 TRUST_PROTECTED_FILTER_ACE_FLAG = 64;
	public const uint32 SYSTEM_MANDATORY_LABEL_NO_WRITE_UP = 1;
	public const uint32 SYSTEM_MANDATORY_LABEL_NO_READ_UP = 2;
	public const uint32 SYSTEM_MANDATORY_LABEL_NO_EXECUTE_UP = 4;
	public const uint32 SYSTEM_PROCESS_TRUST_LABEL_VALID_MASK = 16777215;
	public const uint32 SYSTEM_PROCESS_TRUST_NOCONSTRAINT_MASK = 4294967295;
	public const uint32 SYSTEM_ACCESS_FILTER_VALID_MASK = 16777215;
	public const uint32 SYSTEM_ACCESS_FILTER_NOCONSTRAINT_MASK = 4294967295;
	public const uint32 SECURITY_DESCRIPTOR_REVISION = 1;
	public const uint32 SECURITY_DESCRIPTOR_REVISION1 = 1;
	public const uint32 SE_OWNER_DEFAULTED = 1;
	public const uint32 SE_GROUP_DEFAULTED = 2;
	public const uint32 SE_DACL_PRESENT = 4;
	public const uint32 SE_DACL_DEFAULTED = 8;
	public const uint32 SE_SACL_PRESENT = 16;
	public const uint32 SE_SACL_DEFAULTED = 32;
	public const uint32 SE_DACL_AUTO_INHERIT_REQ = 256;
	public const uint32 SE_SACL_AUTO_INHERIT_REQ = 512;
	public const uint32 SE_DACL_AUTO_INHERITED = 1024;
	public const uint32 SE_SACL_AUTO_INHERITED = 2048;
	public const uint32 SE_DACL_PROTECTED = 4096;
	public const uint32 SE_SACL_PROTECTED = 8192;
	public const uint32 SE_RM_CONTROL_VALID = 16384;
	public const uint32 SE_SELF_RELATIVE = 32768;
	public const uint32 ACCESS_OBJECT_GUID = 0;
	public const uint32 ACCESS_PROPERTY_SET_GUID = 1;
	public const uint32 ACCESS_PROPERTY_GUID = 2;
	public const uint32 ACCESS_MAX_LEVEL = 4;
	public const uint32 AUDIT_ALLOW_NO_PRIVILEGE = 1;
	public const String ACCESS_DS_SOURCE_A = "DS";
	public const String ACCESS_DS_SOURCE_W = "DS";
	public const String ACCESS_DS_OBJECT_TYPE_NAME_A = "Directory Service Object";
	public const String ACCESS_DS_OBJECT_TYPE_NAME_W = "Directory Service Object";
	public const uint32 PRIVILEGE_SET_ALL_NECESSARY = 1;
	public const uint32 ACCESS_REASON_TYPE_MASK = 16711680;
	public const uint32 ACCESS_REASON_DATA_MASK = 65535;
	public const uint32 ACCESS_REASON_STAGING_MASK = 2147483648;
	public const uint32 ACCESS_REASON_EXDATA_MASK = 2130706432;
	public const uint32 SE_SECURITY_DESCRIPTOR_FLAG_NO_OWNER_ACE = 1;
	public const uint32 SE_SECURITY_DESCRIPTOR_FLAG_NO_LABEL_ACE = 2;
	public const uint32 SE_SECURITY_DESCRIPTOR_FLAG_NO_ACCESS_FILTER_ACE = 4;
	public const uint32 SE_SECURITY_DESCRIPTOR_VALID_FLAGS = 7;
	public const uint32 SE_ACCESS_CHECK_FLAG_NO_LEARNING_MODE_LOGGING = 8;
	public const uint32 SE_ACCESS_CHECK_VALID_FLAGS = 8;
	public const String SE_CREATE_TOKEN_NAME = "SeCreateTokenPrivilege";
	public const String SE_ASSIGNPRIMARYTOKEN_NAME = "SeAssignPrimaryTokenPrivilege";
	public const String SE_LOCK_MEMORY_NAME = "SeLockMemoryPrivilege";
	public const String SE_INCREASE_QUOTA_NAME = "SeIncreaseQuotaPrivilege";
	public const String SE_UNSOLICITED_INPUT_NAME = "SeUnsolicitedInputPrivilege";
	public const String SE_MACHINE_ACCOUNT_NAME = "SeMachineAccountPrivilege";
	public const String SE_TCB_NAME = "SeTcbPrivilege";
	public const String SE_SECURITY_NAME = "SeSecurityPrivilege";
	public const String SE_TAKE_OWNERSHIP_NAME = "SeTakeOwnershipPrivilege";
	public const String SE_LOAD_DRIVER_NAME = "SeLoadDriverPrivilege";
	public const String SE_SYSTEM_PROFILE_NAME = "SeSystemProfilePrivilege";
	public const String SE_SYSTEMTIME_NAME = "SeSystemtimePrivilege";
	public const String SE_PROF_SINGLE_PROCESS_NAME = "SeProfileSingleProcessPrivilege";
	public const String SE_INC_BASE_PRIORITY_NAME = "SeIncreaseBasePriorityPrivilege";
	public const String SE_CREATE_PAGEFILE_NAME = "SeCreatePagefilePrivilege";
	public const String SE_CREATE_PERMANENT_NAME = "SeCreatePermanentPrivilege";
	public const String SE_BACKUP_NAME = "SeBackupPrivilege";
	public const String SE_RESTORE_NAME = "SeRestorePrivilege";
	public const String SE_SHUTDOWN_NAME = "SeShutdownPrivilege";
	public const String SE_DEBUG_NAME = "SeDebugPrivilege";
	public const String SE_AUDIT_NAME = "SeAuditPrivilege";
	public const String SE_SYSTEM_ENVIRONMENT_NAME = "SeSystemEnvironmentPrivilege";
	public const String SE_CHANGE_NOTIFY_NAME = "SeChangeNotifyPrivilege";
	public const String SE_REMOTE_SHUTDOWN_NAME = "SeRemoteShutdownPrivilege";
	public const String SE_UNDOCK_NAME = "SeUndockPrivilege";
	public const String SE_SYNC_AGENT_NAME = "SeSyncAgentPrivilege";
	public const String SE_ENABLE_DELEGATION_NAME = "SeEnableDelegationPrivilege";
	public const String SE_MANAGE_VOLUME_NAME = "SeManageVolumePrivilege";
	public const String SE_IMPERSONATE_NAME = "SeImpersonatePrivilege";
	public const String SE_CREATE_GLOBAL_NAME = "SeCreateGlobalPrivilege";
	public const String SE_TRUSTED_CREDMAN_ACCESS_NAME = "SeTrustedCredManAccessPrivilege";
	public const String SE_RELABEL_NAME = "SeRelabelPrivilege";
	public const String SE_INC_WORKING_SET_NAME = "SeIncreaseWorkingSetPrivilege";
	public const String SE_TIME_ZONE_NAME = "SeTimeZonePrivilege";
	public const String SE_CREATE_SYMBOLIC_LINK_NAME = "SeCreateSymbolicLinkPrivilege";
	public const String SE_DELEGATE_SESSION_USER_IMPERSONATE_NAME = "SeDelegateSessionUserImpersonatePrivilege";
	public const String SE_ACTIVATE_AS_USER_CAPABILITY = "activateAsUser";
	public const String SE_CONSTRAINED_IMPERSONATION_CAPABILITY = "constrainedImpersonation";
	public const String SE_SESSION_IMPERSONATION_CAPABILITY = "sessionImpersonation";
	public const String SE_MUMA_CAPABILITY = "muma";
	public const String SE_DEVELOPMENT_MODE_NETWORK_CAPABILITY = "developmentModeNetwork";
	public const String SE_PERMISSIVE_LEARNING_MODE_CAPABILITY = "permissiveLearningMode";
	public const uint32 POLICY_AUDIT_SUBCATEGORY_COUNT = 59;
	public const uint32 TOKEN_SOURCE_LENGTH = 8;
	public const uint32 CLAIM_SECURITY_ATTRIBUTE_TYPE_INVALID = 0;
	public const uint32 CLAIM_SECURITY_ATTRIBUTE_CUSTOM_FLAGS = 4294901760;
	public const uint32 CLAIM_SECURITY_ATTRIBUTES_INFORMATION_VERSION_V1 = 1;
	public const uint32 CLAIM_SECURITY_ATTRIBUTES_INFORMATION_VERSION = 1;
	public const int32 PROCESS_TRUST_LABEL_SECURITY_INFORMATION = 128;
	public const int32 ACCESS_FILTER_SECURITY_INFORMATION = 256;
	public const uint32 SE_SIGNING_LEVEL_UNCHECKED = 0;
	public const uint32 SE_SIGNING_LEVEL_UNSIGNED = 1;
	public const uint32 SE_SIGNING_LEVEL_ENTERPRISE = 2;
	public const uint32 SE_SIGNING_LEVEL_CUSTOM_1 = 3;
	public const uint32 SE_SIGNING_LEVEL_DEVELOPER = 3;
	public const uint32 SE_SIGNING_LEVEL_AUTHENTICODE = 4;
	public const uint32 SE_SIGNING_LEVEL_CUSTOM_2 = 5;
	public const uint32 SE_SIGNING_LEVEL_STORE = 6;
	public const uint32 SE_SIGNING_LEVEL_CUSTOM_3 = 7;
	public const uint32 SE_SIGNING_LEVEL_ANTIMALWARE = 7;
	public const uint32 SE_SIGNING_LEVEL_MICROSOFT = 8;
	public const uint32 SE_SIGNING_LEVEL_CUSTOM_4 = 9;
	public const uint32 SE_SIGNING_LEVEL_CUSTOM_5 = 10;
	public const uint32 SE_SIGNING_LEVEL_DYNAMIC_CODEGEN = 11;
	public const uint32 SE_SIGNING_LEVEL_WINDOWS = 12;
	public const uint32 SE_SIGNING_LEVEL_CUSTOM_7 = 13;
	public const uint32 SE_SIGNING_LEVEL_WINDOWS_TCB = 14;
	public const uint32 SE_SIGNING_LEVEL_CUSTOM_6 = 15;
	public const uint32 SE_LEARNING_MODE_FLAG_PERMISSIVE = 1;
	public const uint32 JOB_OBJECT_ASSIGN_PROCESS = 1;
	public const uint32 JOB_OBJECT_SET_ATTRIBUTES = 2;
	public const uint32 JOB_OBJECT_QUERY = 4;
	public const uint32 JOB_OBJECT_TERMINATE = 8;
	public const uint32 JOB_OBJECT_SET_SECURITY_ATTRIBUTES = 16;
	public const uint32 JOB_OBJECT_IMPERSONATE = 32;
	public const uint32 FLS_MAXIMUM_AVAILABLE = 4080;
	public const uint32 TLS_MINIMUM_AVAILABLE = 64;
	public const uint32 THREAD_DYNAMIC_CODE_ALLOW = 1;
	public const uint32 THREAD_BASE_PRIORITY_LOWRT = 15;
	public const uint32 THREAD_BASE_PRIORITY_MAX = 2;
	public const int32 THREAD_BASE_PRIORITY_MIN = -2;
	public const int32 THREAD_BASE_PRIORITY_IDLE = -15;
	public const uint32 COMPONENT_KTM = 1;
	public const uint32 COMPONENT_VALID_FLAGS = 1;
	public const uint32 MEMORY_PRIORITY_LOWEST = 0;
	public const uint32 DYNAMIC_EH_CONTINUATION_TARGET_ADD = 1;
	public const uint32 DYNAMIC_EH_CONTINUATION_TARGET_PROCESSED = 2;
	public const uint32 DYNAMIC_ENFORCED_ADDRESS_RANGE_ADD = 1;
	public const uint32 DYNAMIC_ENFORCED_ADDRESS_RANGE_PROCESSED = 2;
	public const uint32 QUOTA_LIMITS_HARDWS_MIN_ENABLE = 1;
	public const uint32 QUOTA_LIMITS_HARDWS_MIN_DISABLE = 2;
	public const uint32 QUOTA_LIMITS_HARDWS_MAX_ENABLE = 4;
	public const uint32 QUOTA_LIMITS_HARDWS_MAX_DISABLE = 8;
	public const uint32 QUOTA_LIMITS_USE_DEFAULT_LIMITS = 16;
	public const uint32 MAX_HW_COUNTERS = 16;
	public const uint32 THREAD_PROFILING_FLAG_DISPATCH = 1;
	public const uint32 JOB_OBJECT_NET_RATE_CONTROL_MAX_DSCP_TAG = 64;
	public const uint32 JOB_OBJECT_MSG_END_OF_JOB_TIME = 1;
	public const uint32 JOB_OBJECT_MSG_END_OF_PROCESS_TIME = 2;
	public const uint32 JOB_OBJECT_MSG_ACTIVE_PROCESS_LIMIT = 3;
	public const uint32 JOB_OBJECT_MSG_ACTIVE_PROCESS_ZERO = 4;
	public const uint32 JOB_OBJECT_MSG_NEW_PROCESS = 6;
	public const uint32 JOB_OBJECT_MSG_EXIT_PROCESS = 7;
	public const uint32 JOB_OBJECT_MSG_ABNORMAL_EXIT_PROCESS = 8;
	public const uint32 JOB_OBJECT_MSG_PROCESS_MEMORY_LIMIT = 9;
	public const uint32 JOB_OBJECT_MSG_JOB_MEMORY_LIMIT = 10;
	public const uint32 JOB_OBJECT_MSG_NOTIFICATION_LIMIT = 11;
	public const uint32 JOB_OBJECT_MSG_JOB_CYCLE_TIME_LIMIT = 12;
	public const uint32 JOB_OBJECT_MSG_SILO_TERMINATED = 13;
	public const uint32 JOB_OBJECT_MSG_MINIMUM = 1;
	public const uint32 JOB_OBJECT_MSG_MAXIMUM = 13;
	public const uint32 JOB_OBJECT_UILIMIT_ALL = 255;
	public const uint32 JOB_OBJECT_UI_VALID_FLAGS = 255;
	public const uint32 MEMORY_PARTITION_QUERY_ACCESS = 1;
	public const uint32 MEMORY_PARTITION_MODIFY_ACCESS = 2;
	public const uint32 MUTANT_QUERY_STATE = 1;
	public const uint32 TIME_ZONE_ID_UNKNOWN = 0;
	public const uint32 TIME_ZONE_ID_STANDARD = 1;
	public const uint32 TIME_ZONE_ID_DAYLIGHT = 2;
	public const uint32 LTP_PC_SMT = 1;
	public const uint32 CACHE_FULLY_ASSOCIATIVE = 255;
	public const uint32 PROCESSOR_INTEL_386 = 386;
	public const uint32 PROCESSOR_INTEL_486 = 486;
	public const uint32 PROCESSOR_INTEL_PENTIUM = 586;
	public const uint32 PROCESSOR_INTEL_IA64 = 2200;
	public const uint32 PROCESSOR_AMD_X8664 = 8664;
	public const uint32 PROCESSOR_MIPS_R4000 = 4000;
	public const uint32 PROCESSOR_ALPHA_21064 = 21064;
	public const uint32 PROCESSOR_PPC_601 = 601;
	public const uint32 PROCESSOR_PPC_603 = 603;
	public const uint32 PROCESSOR_PPC_604 = 604;
	public const uint32 PROCESSOR_PPC_620 = 620;
	public const uint32 PROCESSOR_HITACHI_SH3 = 10003;
	public const uint32 PROCESSOR_HITACHI_SH3E = 10004;
	public const uint32 PROCESSOR_HITACHI_SH4 = 10005;
	public const uint32 PROCESSOR_MOTOROLA_821 = 821;
	public const uint32 PROCESSOR_SHx_SH3 = 103;
	public const uint32 PROCESSOR_SHx_SH4 = 104;
	public const uint32 PROCESSOR_STRONGARM = 2577;
	public const uint32 PROCESSOR_ARM720 = 1824;
	public const uint32 PROCESSOR_ARM820 = 2080;
	public const uint32 PROCESSOR_ARM920 = 2336;
	public const uint32 PROCESSOR_ARM_7TDMI = 70001;
	public const uint32 PROCESSOR_OPTIL = 18767;
	public const uint32 PROCESSOR_ARCHITECTURE_MIPS = 1;
	public const uint32 PROCESSOR_ARCHITECTURE_ALPHA = 2;
	public const uint32 PROCESSOR_ARCHITECTURE_PPC = 3;
	public const uint32 PROCESSOR_ARCHITECTURE_SHX = 4;
	public const uint32 PROCESSOR_ARCHITECTURE_ALPHA64 = 7;
	public const uint32 PROCESSOR_ARCHITECTURE_MSIL = 8;
	public const uint32 PROCESSOR_ARCHITECTURE_IA32_ON_WIN64 = 10;
	public const uint32 PROCESSOR_ARCHITECTURE_NEUTRAL = 11;
	public const uint32 PROCESSOR_ARCHITECTURE_ARM64 = 12;
	public const uint32 PROCESSOR_ARCHITECTURE_ARM32_ON_WIN64 = 13;
	public const uint32 PROCESSOR_ARCHITECTURE_IA32_ON_ARM64 = 14;
	public const uint32 PF_PPC_MOVEMEM_64BIT_OK = 4;
	public const uint32 PF_ALPHA_BYTE_INSTRUCTIONS = 5;
	public const uint32 PF_SSE_DAZ_MODE_AVAILABLE = 11;
	public const uint32 PF_ARM_NEON_INSTRUCTIONS_AVAILABLE = 19;
	public const uint32 PF_RDRAND_INSTRUCTION_AVAILABLE = 28;
	public const uint32 PF_RDTSCP_INSTRUCTION_AVAILABLE = 32;
	public const uint32 PF_RDPID_INSTRUCTION_AVAILABLE = 33;
	public const uint32 PF_MONITORX_INSTRUCTION_AVAILABLE = 35;
	public const uint32 PF_SSSE3_INSTRUCTIONS_AVAILABLE = 36;
	public const uint32 PF_SSE4_1_INSTRUCTIONS_AVAILABLE = 37;
	public const uint32 PF_SSE4_2_INSTRUCTIONS_AVAILABLE = 38;
	public const uint32 PF_AVX_INSTRUCTIONS_AVAILABLE = 39;
	public const uint32 PF_AVX2_INSTRUCTIONS_AVAILABLE = 40;
	public const uint32 PF_AVX512F_INSTRUCTIONS_AVAILABLE = 41;
	public const uint32 PF_ERMS_AVAILABLE = 42;
	public const uint32 PF_ARM_V82_DP_INSTRUCTIONS_AVAILABLE = 43;
	public const uint32 PF_ARM_V83_JSCVT_INSTRUCTIONS_AVAILABLE = 44;
	public const uint32 XSTATE_LEGACY_FLOATING_POINT = 0;
	public const uint32 XSTATE_LEGACY_SSE = 1;
	public const uint32 XSTATE_GSSE = 2;
	public const uint32 XSTATE_AVX = 2;
	public const uint32 XSTATE_MPX_BNDREGS = 3;
	public const uint32 XSTATE_MPX_BNDCSR = 4;
	public const uint32 XSTATE_AVX512_KMASK = 5;
	public const uint32 XSTATE_AVX512_ZMM_H = 6;
	public const uint32 XSTATE_AVX512_ZMM = 7;
	public const uint32 XSTATE_IPT = 8;
	public const uint32 XSTATE_PASID = 10;
	public const uint32 XSTATE_CET_U = 11;
	public const uint32 XSTATE_CET_S = 12;
	public const uint32 XSTATE_AMX_TILE_CONFIG = 17;
	public const uint32 XSTATE_AMX_TILE_DATA = 18;
	public const uint32 XSTATE_LWP = 62;
	public const uint32 MAXIMUM_XSTATE_FEATURES = 64;
	public const uint32 XSTATE_COMPACTION_ENABLE = 63;
	public const uint32 XSTATE_ALIGN_BIT = 1;
	public const uint32 XSTATE_XFD_BIT = 2;
	public const uint32 XSTATE_CONTROLFLAG_XSAVEOPT_MASK = 1;
	public const uint32 XSTATE_CONTROLFLAG_XSAVEC_MASK = 2;
	public const uint32 XSTATE_CONTROLFLAG_XFD_MASK = 4;
	public const uint32 CFG_CALL_TARGET_VALID = 1;
	public const uint32 CFG_CALL_TARGET_PROCESSED = 2;
	public const uint32 CFG_CALL_TARGET_CONVERT_EXPORT_SUPPRESSED_TO_VALID = 4;
	public const uint32 CFG_CALL_TARGET_VALID_XFG = 8;
	public const uint32 CFG_CALL_TARGET_CONVERT_XFG_TO_CFG = 16;
	public const uint32 SESSION_QUERY_ACCESS = 1;
	public const uint32 SESSION_MODIFY_ACCESS = 2;
	public const uint32 MEM_TOP_DOWN = 1048576;
	public const uint32 MEM_WRITE_WATCH = 2097152;
	public const uint32 MEM_PHYSICAL = 4194304;
	public const uint32 MEM_ROTATE = 8388608;
	public const uint32 MEM_DIFFERENT_IMAGE_BASE_OK = 8388608;
	public const uint32 MEM_4MB_PAGES = 2147483648;
	public const uint32 MEM_COALESCE_PLACEHOLDERS = 1;
	public const uint32 MEM_EXTENDED_PARAMETER_GRAPHICS = 1;
	public const uint32 MEM_EXTENDED_PARAMETER_NONPAGED = 2;
	public const uint32 MEM_EXTENDED_PARAMETER_ZERO_PAGES_OPTIONAL = 4;
	public const uint32 MEM_EXTENDED_PARAMETER_NONPAGED_LARGE = 8;
	public const uint32 MEM_EXTENDED_PARAMETER_NONPAGED_HUGE = 16;
	public const uint32 MEM_EXTENDED_PARAMETER_SOFT_FAULT_PAGES = 32;
	public const uint32 MEM_EXTENDED_PARAMETER_EC_CODE = 64;
	public const uint32 MEM_EXTENDED_PARAMETER_TYPE_BITS = 8;
	public const uint32 SEC_HUGE_PAGES = 131072;
	public const uint32 WRITE_WATCH_FLAG_RESET = 1;
	public const uint32 ENCLAVE_TYPE_SGX = 1;
	public const uint32 ENCLAVE_TYPE_SGX2 = 2;
	public const uint32 ENCLAVE_TYPE_VBS = 16;
	public const uint32 ENCLAVE_VBS_FLAG_DEBUG = 1;
	public const uint32 ENCLAVE_TYPE_VBS_BASIC = 17;
	public const uint32 VBS_BASIC_PAGE_MEASURED_DATA = 1;
	public const uint32 VBS_BASIC_PAGE_UNMEASURED_DATA = 2;
	public const uint32 VBS_BASIC_PAGE_ZERO_FILL = 3;
	public const uint32 VBS_BASIC_PAGE_THREAD_DESCRIPTOR = 4;
	public const uint32 VBS_BASIC_PAGE_SYSTEM_CALL = 5;
	public const uint32 DEDICATED_MEMORY_CACHE_ELIGIBLE = 1;
	public const uint32 TREE_CONNECT_ATTRIBUTE_PRIVACY = 16384;
	public const uint32 TREE_CONNECT_ATTRIBUTE_INTEGRITY = 32768;
	public const uint32 TREE_CONNECT_ATTRIBUTE_GLOBAL = 4;
	public const uint32 TREE_CONNECT_ATTRIBUTE_PINNED = 2;
	public const uint32 FILE_ATTRIBUTE_STRICTLY_SEQUENTIAL = 536870912;
	public const uint32 MAILSLOT_NO_MESSAGE = 4294967295;
	public const uint32 MAILSLOT_WAIT_FOREVER = 4294967295;
	public const uint32 FILE_CASE_SENSITIVE_SEARCH = 1;
	public const uint32 FILE_CASE_PRESERVED_NAMES = 2;
	public const uint32 FILE_UNICODE_ON_DISK = 4;
	public const uint32 FILE_PERSISTENT_ACLS = 8;
	public const uint32 FILE_FILE_COMPRESSION = 16;
	public const uint32 FILE_VOLUME_QUOTAS = 32;
	public const uint32 FILE_SUPPORTS_SPARSE_FILES = 64;
	public const uint32 FILE_SUPPORTS_REPARSE_POINTS = 128;
	public const uint32 FILE_SUPPORTS_REMOTE_STORAGE = 256;
	public const uint32 FILE_RETURNS_CLEANUP_RESULT_INFO = 512;
	public const uint32 FILE_SUPPORTS_POSIX_UNLINK_RENAME = 1024;
	public const uint32 FILE_SUPPORTS_BYPASS_IO = 2048;
	public const uint32 FILE_VOLUME_IS_COMPRESSED = 32768;
	public const uint32 FILE_SUPPORTS_OBJECT_IDS = 65536;
	public const uint32 FILE_SUPPORTS_ENCRYPTION = 131072;
	public const uint32 FILE_NAMED_STREAMS = 262144;
	public const uint32 FILE_READ_ONLY_VOLUME = 524288;
	public const uint32 FILE_SEQUENTIAL_WRITE_ONCE = 1048576;
	public const uint32 FILE_SUPPORTS_TRANSACTIONS = 2097152;
	public const uint32 FILE_SUPPORTS_HARD_LINKS = 4194304;
	public const uint32 FILE_SUPPORTS_EXTENDED_ATTRIBUTES = 8388608;
	public const uint32 FILE_SUPPORTS_OPEN_BY_FILE_ID = 16777216;
	public const uint32 FILE_SUPPORTS_USN_JOURNAL = 33554432;
	public const uint32 FILE_SUPPORTS_INTEGRITY_STREAMS = 67108864;
	public const uint32 FILE_SUPPORTS_BLOCK_REFCOUNTING = 134217728;
	public const uint32 FILE_SUPPORTS_SPARSE_VDL = 268435456;
	public const uint32 FILE_DAX_VOLUME = 536870912;
	public const uint32 FILE_SUPPORTS_GHOSTING = 1073741824;
	public const uint32 FILE_CS_FLAG_CASE_SENSITIVE_DIR = 1;
	public const uint32 FLUSH_FLAGS_FILE_DATA_ONLY = 1;
	public const uint32 FLUSH_FLAGS_NO_SYNC = 2;
	public const uint32 FLUSH_FLAGS_FILE_DATA_SYNC_ONLY = 4;
	public const uint32 IO_REPARSE_TAG_RESERVED_ZERO = 0;
	public const uint32 IO_REPARSE_TAG_RESERVED_ONE = 1;
	public const uint32 IO_REPARSE_TAG_RESERVED_TWO = 2;
	public const uint32 IO_REPARSE_TAG_RESERVED_RANGE = 2;
	public const uint32 IO_REPARSE_TAG_MOUNT_POINT = 2684354563;
	public const uint32 IO_REPARSE_TAG_HSM = 3221225476;
	public const uint32 IO_REPARSE_TAG_HSM2 = 2147483654;
	public const uint32 IO_REPARSE_TAG_SIS = 2147483655;
	public const uint32 IO_REPARSE_TAG_WIM = 2147483656;
	public const uint32 IO_REPARSE_TAG_CSV = 2147483657;
	public const uint32 IO_REPARSE_TAG_DFS = 2147483658;
	public const uint32 IO_REPARSE_TAG_SYMLINK = 2684354572;
	public const uint32 IO_REPARSE_TAG_DFSR = 2147483666;
	public const uint32 IO_REPARSE_TAG_DEDUP = 2147483667;
	public const uint32 IO_REPARSE_TAG_NFS = 2147483668;
	public const uint32 IO_REPARSE_TAG_FILE_PLACEHOLDER = 2147483669;
	public const uint32 IO_REPARSE_TAG_WOF = 2147483671;
	public const uint32 IO_REPARSE_TAG_WCI = 2147483672;
	public const uint32 IO_REPARSE_TAG_WCI_1 = 2415923224;
	public const uint32 IO_REPARSE_TAG_GLOBAL_REPARSE = 2684354585;
	public const uint32 IO_REPARSE_TAG_CLOUD = 2415919130;
	public const uint32 IO_REPARSE_TAG_CLOUD_1 = 2415923226;
	public const uint32 IO_REPARSE_TAG_CLOUD_2 = 2415927322;
	public const uint32 IO_REPARSE_TAG_CLOUD_3 = 2415931418;
	public const uint32 IO_REPARSE_TAG_CLOUD_4 = 2415935514;
	public const uint32 IO_REPARSE_TAG_CLOUD_5 = 2415939610;
	public const uint32 IO_REPARSE_TAG_CLOUD_6 = 2415943706;
	public const uint32 IO_REPARSE_TAG_CLOUD_7 = 2415947802;
	public const uint32 IO_REPARSE_TAG_CLOUD_8 = 2415951898;
	public const uint32 IO_REPARSE_TAG_CLOUD_9 = 2415955994;
	public const uint32 IO_REPARSE_TAG_CLOUD_A = 2415960090;
	public const uint32 IO_REPARSE_TAG_CLOUD_B = 2415964186;
	public const uint32 IO_REPARSE_TAG_CLOUD_C = 2415968282;
	public const uint32 IO_REPARSE_TAG_CLOUD_D = 2415972378;
	public const uint32 IO_REPARSE_TAG_CLOUD_E = 2415976474;
	public const uint32 IO_REPARSE_TAG_CLOUD_F = 2415980570;
	public const uint32 IO_REPARSE_TAG_CLOUD_MASK = 61440;
	public const uint32 IO_REPARSE_TAG_APPEXECLINK = 2147483675;
	public const uint32 IO_REPARSE_TAG_PROJFS = 2415919132;
	public const uint32 IO_REPARSE_TAG_STORAGE_SYNC = 2147483678;
	public const uint32 IO_REPARSE_TAG_WCI_TOMBSTONE = 2684354591;
	public const uint32 IO_REPARSE_TAG_UNHANDLED = 2147483680;
	public const uint32 IO_REPARSE_TAG_ONEDRIVE = 2147483681;
	public const uint32 IO_REPARSE_TAG_PROJFS_TOMBSTONE = 2684354594;
	public const uint32 IO_REPARSE_TAG_AF_UNIX = 2147483683;
	public const uint32 IO_REPARSE_TAG_WCI_LINK = 2684354599;
	public const uint32 IO_REPARSE_TAG_WCI_LINK_1 = 2684358695;
	public const uint32 IO_REPARSE_TAG_DATALESS_CIM = 2684354600;
	public const uint32 SCRUB_DATA_INPUT_FLAG_RESUME = 1;
	public const uint32 SCRUB_DATA_INPUT_FLAG_SKIP_IN_SYNC = 2;
	public const uint32 SCRUB_DATA_INPUT_FLAG_SKIP_NON_INTEGRITY_DATA = 4;
	public const uint32 SCRUB_DATA_INPUT_FLAG_IGNORE_REDUNDANCY = 8;
	public const uint32 SCRUB_DATA_INPUT_FLAG_SKIP_DATA = 16;
	public const uint32 SCRUB_DATA_INPUT_FLAG_SCRUB_BY_OBJECT_ID = 32;
	public const uint32 SCRUB_DATA_INPUT_FLAG_OPLOCK_NOT_ACQUIRED = 64;
	public const uint32 SCRUB_DATA_OUTPUT_FLAG_INCOMPLETE = 1;
	public const uint32 SCRUB_DATA_OUTPUT_FLAG_NON_USER_DATA_RANGE = 65536;
	public const uint32 SCRUB_DATA_OUTPUT_FLAG_PARITY_EXTENT_DATA_RETURNED = 131072;
	public const uint32 SCRUB_DATA_OUTPUT_FLAG_RESUME_CONTEXT_LENGTH_SPECIFIED = 262144;
	public const uint32 SHUFFLE_FILE_FLAG_SKIP_INITIALIZING_NEW_CLUSTERS = 1;
	public const uint32 IO_COMPLETION_MODIFY_STATE = 2;
	public const String SMB_CCF_APP_INSTANCE_EA_NAME = "ClusteredApplicationInstance";
	public const uint32 NETWORK_APP_INSTANCE_CSV_FLAGS_VALID_ONLY_IF_CSV_COORDINATOR = 1;
	public const Guid GUID_MAX_POWER_SAVINGS = .(0xa1841308, 0x3541, 0x4fab, 0xbc, 0x81, 0xf7, 0x15, 0x56, 0xf2, 0x0b, 0x4a);
	public const Guid GUID_MIN_POWER_SAVINGS = .(0x8c5e7fda, 0xe8bf, 0x4a96, 0x9a, 0x85, 0xa6, 0xe2, 0x3a, 0x8c, 0x63, 0x5c);
	public const Guid GUID_TYPICAL_POWER_SAVINGS = .(0x381b4222, 0xf694, 0x41f0, 0x96, 0x85, 0xff, 0x5b, 0xb2, 0x60, 0xdf, 0x2e);
	public const Guid NO_SUBGROUP_GUID = .(0xfea3413e, 0x7e05, 0x4911, 0x9a, 0x71, 0x70, 0x03, 0x31, 0xf1, 0xc2, 0x94);
	public const Guid ALL_POWERSCHEMES_GUID = .(0x68a1e95e, 0x13ea, 0x41e1, 0x80, 0x11, 0x0c, 0x49, 0x6c, 0xa4, 0x90, 0xb0);
	public const Guid GUID_POWERSCHEME_PERSONALITY = .(0x245d8541, 0x3943, 0x4422, 0xb0, 0x25, 0x13, 0xa7, 0x84, 0xf6, 0x79, 0xb7);
	public const Guid GUID_ACTIVE_POWERSCHEME = .(0x31f9f286, 0x5084, 0x42fe, 0xb7, 0x20, 0x2b, 0x02, 0x64, 0x99, 0x37, 0x63);
	public const Guid GUID_IDLE_RESILIENCY_SUBGROUP = .(0x2e601130, 0x5351, 0x4d9d, 0x8e, 0x04, 0x25, 0x29, 0x66, 0xba, 0xd0, 0x54);
	public const Guid GUID_IDLE_RESILIENCY_PERIOD = .(0xc42b79aa, 0xaa3a, 0x484b, 0xa9, 0x8f, 0x2c, 0xf3, 0x2a, 0xa9, 0x0a, 0x28);
	public const Guid GUID_DEEP_SLEEP_ENABLED = .(0xd502f7ee, 0x1dc7, 0x4efd, 0xa5, 0x5d, 0xf0, 0x4b, 0x6f, 0x5c, 0x05, 0x45);
	public const Guid GUID_DEEP_SLEEP_PLATFORM_STATE = .(0xd23f2fb8, 0x9536, 0x4038, 0x9c, 0x94, 0x1c, 0xe0, 0x2e, 0x5c, 0x21, 0x52);
	public const Guid GUID_DISK_COALESCING_POWERDOWN_TIMEOUT = .(0xc36f0eb4, 0x2988, 0x4a70, 0x8e, 0xee, 0x08, 0x84, 0xfc, 0x2c, 0x24, 0x33);
	public const Guid GUID_EXECUTION_REQUIRED_REQUEST_TIMEOUT = .(0x3166bc41, 0x7e98, 0x4e03, 0xb3, 0x4e, 0xec, 0x0f, 0x5f, 0x2b, 0x21, 0x8e);
	public const Guid GUID_VIDEO_SUBGROUP = .(0x7516b95f, 0xf776, 0x4464, 0x8c, 0x53, 0x06, 0x16, 0x7f, 0x40, 0xcc, 0x99);
	public const Guid GUID_VIDEO_POWERDOWN_TIMEOUT = .(0x3c0bc021, 0xc8a8, 0x4e07, 0xa9, 0x73, 0x6b, 0x14, 0xcb, 0xcb, 0x2b, 0x7e);
	public const Guid GUID_VIDEO_ANNOYANCE_TIMEOUT = .(0x82dbcf2d, 0xcd67, 0x40c5, 0xbf, 0xdc, 0x9f, 0x1a, 0x5c, 0xcd, 0x46, 0x63);
	public const Guid GUID_VIDEO_ADAPTIVE_PERCENT_INCREASE = .(0xeed904df, 0xb142, 0x4183, 0xb1, 0x0b, 0x5a, 0x11, 0x97, 0xa3, 0x78, 0x64);
	public const Guid GUID_VIDEO_DIM_TIMEOUT = .(0x17aaa29b, 0x8b43, 0x4b94, 0xaa, 0xfe, 0x35, 0xf6, 0x4d, 0xaa, 0xf1, 0xee);
	public const Guid GUID_VIDEO_ADAPTIVE_POWERDOWN = .(0x90959d22, 0xd6a1, 0x49b9, 0xaf, 0x93, 0xbc, 0xe8, 0x85, 0xad, 0x33, 0x5b);
	public const Guid GUID_MONITOR_POWER_ON = .(0x02731015, 0x4510, 0x4526, 0x99, 0xe6, 0xe5, 0xa1, 0x7e, 0xbd, 0x1a, 0xea);
	public const Guid GUID_DEVICE_POWER_POLICY_VIDEO_BRIGHTNESS = .(0xaded5e82, 0xb909, 0x4619, 0x99, 0x49, 0xf5, 0xd7, 0x1d, 0xac, 0x0b, 0xcb);
	public const Guid GUID_DEVICE_POWER_POLICY_VIDEO_DIM_BRIGHTNESS = .(0xf1fbfde2, 0xa960, 0x4165, 0x9f, 0x88, 0x50, 0x66, 0x79, 0x11, 0xce, 0x96);
	public const Guid GUID_VIDEO_CURRENT_MONITOR_BRIGHTNESS = .(0x8ffee2c6, 0x2d01, 0x46be, 0xad, 0xb9, 0x39, 0x8a, 0xdd, 0xc5, 0xb4, 0xff);
	public const Guid GUID_VIDEO_ADAPTIVE_DISPLAY_BRIGHTNESS = .(0xfbd9aa66, 0x9553, 0x4097, 0xba, 0x44, 0xed, 0x6e, 0x9d, 0x65, 0xea, 0xb8);
	public const Guid GUID_CONSOLE_DISPLAY_STATE = .(0x6fe69556, 0x704a, 0x47a0, 0x8f, 0x24, 0xc2, 0x8d, 0x93, 0x6f, 0xda, 0x47);
	public const Guid GUID_ALLOW_DISPLAY_REQUIRED = .(0xa9ceb8da, 0xcd46, 0x44fb, 0xa9, 0x8b, 0x02, 0xaf, 0x69, 0xde, 0x46, 0x23);
	public const Guid GUID_VIDEO_CONSOLE_LOCK_TIMEOUT = .(0x8ec4b3a5, 0x6868, 0x48c2, 0xbe, 0x75, 0x4f, 0x30, 0x44, 0xbe, 0x88, 0xa7);
	public const Guid GUID_ADVANCED_COLOR_QUALITY_BIAS = .(0x684c3e69, 0xa4f7, 0x4014, 0x87, 0x54, 0xd4, 0x51, 0x79, 0xa5, 0x61, 0x67);
	public const Guid GUID_ADAPTIVE_POWER_BEHAVIOR_SUBGROUP = .(0x8619b916, 0xe004, 0x4dd8, 0x9b, 0x66, 0xda, 0xe8, 0x6f, 0x80, 0x66, 0x98);
	public const Guid GUID_NON_ADAPTIVE_INPUT_TIMEOUT = .(0x5adbbfbc, 0x074e, 0x4da1, 0xba, 0x38, 0xdb, 0x8b, 0x36, 0xb2, 0xc8, 0xf3);
	public const Guid GUID_ADAPTIVE_INPUT_CONTROLLER_STATE = .(0x0e98fae9, 0xf45a, 0x4de1, 0xa7, 0x57, 0x60, 0x31, 0xf1, 0x97, 0xf6, 0xea);
	public const Guid GUID_DISK_SUBGROUP = .(0x0012ee47, 0x9041, 0x4b5d, 0x9b, 0x77, 0x53, 0x5f, 0xba, 0x8b, 0x14, 0x42);
	public const Guid GUID_DISK_MAX_POWER = .(0x51dea550, 0xbb38, 0x4bc4, 0x99, 0x1b, 0xea, 0xcf, 0x37, 0xbe, 0x5e, 0xc8);
	public const Guid GUID_DISK_POWERDOWN_TIMEOUT = .(0x6738e2c4, 0xe8a5, 0x4a42, 0xb1, 0x6a, 0xe0, 0x40, 0xe7, 0x69, 0x75, 0x6e);
	public const Guid GUID_DISK_IDLE_TIMEOUT = .(0x58e39ba8, 0xb8e6, 0x4ef6, 0x90, 0xd0, 0x89, 0xae, 0x32, 0xb2, 0x58, 0xd6);
	public const Guid GUID_DISK_BURST_IGNORE_THRESHOLD = .(0x80e3c60e, 0xbb94, 0x4ad8, 0xbb, 0xe0, 0x0d, 0x31, 0x95, 0xef, 0xc6, 0x63);
	public const Guid GUID_DISK_ADAPTIVE_POWERDOWN = .(0x396a32e1, 0x499a, 0x40b2, 0x91, 0x24, 0xa9, 0x6a, 0xfe, 0x70, 0x76, 0x67);
	public const Guid GUID_DISK_NVME_NOPPME = .(0xfc7372b6, 0xab2d, 0x43ee, 0x87, 0x97, 0x15, 0xe9, 0x84, 0x1f, 0x2c, 0xca);
	public const Guid GUID_SLEEP_SUBGROUP = .(0x238c9fa8, 0x0aad, 0x41ed, 0x83, 0xf4, 0x97, 0xbe, 0x24, 0x2c, 0x8f, 0x20);
	public const Guid GUID_SLEEP_IDLE_THRESHOLD = .(0x81cd32e0, 0x7833, 0x44f3, 0x87, 0x37, 0x70, 0x81, 0xf3, 0x8d, 0x1f, 0x70);
	public const Guid GUID_STANDBY_TIMEOUT = .(0x29f6c1db, 0x86da, 0x48c5, 0x9f, 0xdb, 0xf2, 0xb6, 0x7b, 0x1f, 0x44, 0xda);
	public const Guid GUID_UNATTEND_SLEEP_TIMEOUT = .(0x7bc4a2f9, 0xd8fc, 0x4469, 0xb0, 0x7b, 0x33, 0xeb, 0x78, 0x5a, 0xac, 0xa0);
	public const Guid GUID_HIBERNATE_TIMEOUT = .(0x9d7815a6, 0x7ee4, 0x497e, 0x88, 0x88, 0x51, 0x5a, 0x05, 0xf0, 0x23, 0x64);
	public const Guid GUID_HIBERNATE_FASTS4_POLICY = .(0x94ac6d29, 0x73ce, 0x41a6, 0x80, 0x9f, 0x63, 0x63, 0xba, 0x21, 0xb4, 0x7e);
	public const Guid GUID_CRITICAL_POWER_TRANSITION = .(0xb7a27025, 0xe569, 0x46c2, 0xa5, 0x04, 0x2b, 0x96, 0xca, 0xd2, 0x25, 0xa1);
	public const Guid GUID_SYSTEM_AWAYMODE = .(0x98a7f580, 0x01f7, 0x48aa, 0x9c, 0x0f, 0x44, 0x35, 0x2c, 0x29, 0xe5, 0xc0);
	public const Guid GUID_ALLOW_AWAYMODE = .(0x25dfa149, 0x5dd1, 0x4736, 0xb5, 0xab, 0xe8, 0xa3, 0x7b, 0x5b, 0x81, 0x87);
	public const Guid GUID_USER_PRESENCE_PREDICTION = .(0x82011705, 0xfb95, 0x4d46, 0x8d, 0x35, 0x40, 0x42, 0xb1, 0xd2, 0x0d, 0xef);
	public const Guid GUID_STANDBY_BUDGET_GRACE_PERIOD = .(0x60c07fe1, 0x0556, 0x45cf, 0x99, 0x03, 0xd5, 0x6e, 0x32, 0x21, 0x02, 0x42);
	public const Guid GUID_STANDBY_BUDGET_PERCENT = .(0x9fe527be, 0x1b70, 0x48da, 0x93, 0x0d, 0x7b, 0xcf, 0x17, 0xb4, 0x49, 0x90);
	public const Guid GUID_STANDBY_RESERVE_GRACE_PERIOD = .(0xc763ee92, 0x71e8, 0x4127, 0x84, 0xeb, 0xf6, 0xed, 0x04, 0x3a, 0x3e, 0x3d);
	public const Guid GUID_STANDBY_RESERVE_TIME = .(0x468fe7e5, 0x1158, 0x46ec, 0x88, 0xbc, 0x5b, 0x96, 0xc9, 0xe4, 0x4f, 0xd0);
	public const Guid GUID_STANDBY_RESET_PERCENT = .(0x49cb11a5, 0x56e2, 0x4afb, 0x9d, 0x38, 0x3d, 0xf4, 0x78, 0x72, 0xe2, 0x1b);
	public const Guid GUID_HUPR_ADAPTIVE_DISPLAY_TIMEOUT = .(0x0a7d6ab6, 0xac83, 0x4ad1, 0x82, 0x82, 0xec, 0xa5, 0xb5, 0x83, 0x08, 0xf3);
	public const Guid GUID_ALLOW_STANDBY_STATES = .(0xabfc2519, 0x3608, 0x4c2a, 0x94, 0xea, 0x17, 0x1b, 0x0e, 0xd5, 0x46, 0xab);
	public const Guid GUID_ALLOW_RTC_WAKE = .(0xbd3b718a, 0x0680, 0x4d9d, 0x8a, 0xb2, 0xe1, 0xd2, 0xb4, 0xac, 0x80, 0x6d);
	public const Guid GUID_LEGACY_RTC_MITIGATION = .(0x1a34bdc3, 0x7e6b, 0x442e, 0xa9, 0xd0, 0x64, 0xb6, 0xef, 0x37, 0x8e, 0x84);
	public const Guid GUID_ALLOW_SYSTEM_REQUIRED = .(0xa4b195f5, 0x8225, 0x47d8, 0x80, 0x12, 0x9d, 0x41, 0x36, 0x97, 0x86, 0xe2);
	public const Guid GUID_POWER_SAVING_STATUS = .(0xe00958c0, 0xc213, 0x4ace, 0xac, 0x77, 0xfe, 0xcc, 0xed, 0x2e, 0xee, 0xa5);
	public const Guid GUID_ENERGY_SAVER_SUBGROUP = .(0xde830923, 0xa562, 0x41af, 0xa0, 0x86, 0xe3, 0xa2, 0xc6, 0xba, 0xd2, 0xda);
	public const Guid GUID_ENERGY_SAVER_BATTERY_THRESHOLD = .(0xe69653ca, 0xcf7f, 0x4f05, 0xaa, 0x73, 0xcb, 0x83, 0x3f, 0xa9, 0x0a, 0xd4);
	public const Guid GUID_ENERGY_SAVER_BRIGHTNESS = .(0x13d09884, 0xf74e, 0x474a, 0xa8, 0x52, 0xb6, 0xbd, 0xe8, 0xad, 0x03, 0xa8);
	public const Guid GUID_ENERGY_SAVER_POLICY = .(0x5c5bb349, 0xad29, 0x4ee2, 0x9d, 0x0b, 0x2b, 0x25, 0x27, 0x0f, 0x7a, 0x81);
	public const Guid GUID_SYSTEM_BUTTON_SUBGROUP = .(0x4f971e89, 0xeebd, 0x4455, 0xa8, 0xde, 0x9e, 0x59, 0x04, 0x0e, 0x73, 0x47);
	public const uint32 POWERBUTTON_ACTION_INDEX_NOTHING = 0;
	public const uint32 POWERBUTTON_ACTION_INDEX_SLEEP = 1;
	public const uint32 POWERBUTTON_ACTION_INDEX_HIBERNATE = 2;
	public const uint32 POWERBUTTON_ACTION_INDEX_SHUTDOWN = 3;
	public const uint32 POWERBUTTON_ACTION_INDEX_TURN_OFF_THE_DISPLAY = 4;
	public const uint32 POWERBUTTON_ACTION_VALUE_NOTHING = 0;
	public const uint32 POWERBUTTON_ACTION_VALUE_SLEEP = 2;
	public const uint32 POWERBUTTON_ACTION_VALUE_HIBERNATE = 3;
	public const uint32 POWERBUTTON_ACTION_VALUE_SHUTDOWN = 6;
	public const uint32 POWERBUTTON_ACTION_VALUE_TURN_OFF_THE_DISPLAY = 8;
	public const Guid GUID_POWERBUTTON_ACTION = .(0x7648efa3, 0xdd9c, 0x4e3e, 0xb5, 0x66, 0x50, 0xf9, 0x29, 0x38, 0x62, 0x80);
	public const Guid GUID_SLEEPBUTTON_ACTION = .(0x96996bc0, 0xad50, 0x47ec, 0x92, 0x3b, 0x6f, 0x41, 0x87, 0x4d, 0xd9, 0xeb);
	public const Guid GUID_USERINTERFACEBUTTON_ACTION = .(0xa7066653, 0x8d6c, 0x40a8, 0x91, 0x0e, 0xa1, 0xf5, 0x4b, 0x84, 0xc7, 0xe5);
	public const Guid GUID_LIDCLOSE_ACTION = .(0x5ca83367, 0x6e45, 0x459f, 0xa2, 0x7b, 0x47, 0x6b, 0x1d, 0x01, 0xc9, 0x36);
	public const Guid GUID_LIDOPEN_POWERSTATE = .(0x99ff10e7, 0x23b1, 0x4c07, 0xa9, 0xd1, 0x5c, 0x32, 0x06, 0xd7, 0x41, 0xb4);
	public const Guid GUID_BATTERY_SUBGROUP = .(0xe73a048d, 0xbf27, 0x4f12, 0x97, 0x31, 0x8b, 0x20, 0x76, 0xe8, 0x89, 0x1f);
	public const Guid GUID_BATTERY_DISCHARGE_ACTION_0 = .(0x637ea02f, 0xbbcb, 0x4015, 0x8e, 0x2c, 0xa1, 0xc7, 0xb9, 0xc0, 0xb5, 0x46);
	public const Guid GUID_BATTERY_DISCHARGE_LEVEL_0 = .(0x9a66d8d7, 0x4ff7, 0x4ef9, 0xb5, 0xa2, 0x5a, 0x32, 0x6c, 0xa2, 0xa4, 0x69);
	public const Guid GUID_BATTERY_DISCHARGE_FLAGS_0 = .(0x5dbb7c9f, 0x38e9, 0x40d2, 0x97, 0x49, 0x4f, 0x8a, 0x0e, 0x9f, 0x64, 0x0f);
	public const Guid GUID_BATTERY_DISCHARGE_ACTION_1 = .(0xd8742dcb, 0x3e6a, 0x4b3c, 0xb3, 0xfe, 0x37, 0x46, 0x23, 0xcd, 0xcf, 0x06);
	public const Guid GUID_BATTERY_DISCHARGE_LEVEL_1 = .(0x8183ba9a, 0xe910, 0x48da, 0x87, 0x69, 0x14, 0xae, 0x6d, 0xc1, 0x17, 0x0a);
	public const Guid GUID_BATTERY_DISCHARGE_FLAGS_1 = .(0xbcded951, 0x187b, 0x4d05, 0xbc, 0xcc, 0xf7, 0xe5, 0x19, 0x60, 0xc2, 0x58);
	public const Guid GUID_BATTERY_DISCHARGE_ACTION_2 = .(0x421cba38, 0x1a8e, 0x4881, 0xac, 0x89, 0xe3, 0x3a, 0x8b, 0x04, 0xec, 0xe4);
	public const Guid GUID_BATTERY_DISCHARGE_LEVEL_2 = .(0x07a07ca2, 0xadaf, 0x40d7, 0xb0, 0x77, 0x53, 0x3a, 0xad, 0xed, 0x1b, 0xfa);
	public const Guid GUID_BATTERY_DISCHARGE_FLAGS_2 = .(0x7fd2f0c4, 0xfeb7, 0x4da3, 0x81, 0x17, 0xe3, 0xfb, 0xed, 0xc4, 0x65, 0x82);
	public const Guid GUID_BATTERY_DISCHARGE_ACTION_3 = .(0x80472613, 0x9780, 0x455e, 0xb3, 0x08, 0x72, 0xd3, 0x00, 0x3c, 0xf2, 0xf8);
	public const Guid GUID_BATTERY_DISCHARGE_LEVEL_3 = .(0x58afd5a6, 0xc2dd, 0x47d2, 0x9f, 0xbf, 0xef, 0x70, 0xcc, 0x5c, 0x59, 0x65);
	public const Guid GUID_BATTERY_DISCHARGE_FLAGS_3 = .(0x73613ccf, 0xdbfa, 0x4279, 0x83, 0x56, 0x49, 0x35, 0xf6, 0xbf, 0x62, 0xf3);
	public const Guid GUID_PROCESSOR_SETTINGS_SUBGROUP = .(0x54533251, 0x82be, 0x4824, 0x96, 0xc1, 0x47, 0xb6, 0x0b, 0x74, 0x0d, 0x00);
	public const Guid GUID_PROCESSOR_THROTTLE_POLICY = .(0x57027304, 0x4af6, 0x4104, 0x92, 0x60, 0xe3, 0xd9, 0x52, 0x48, 0xfc, 0x36);
	public const uint32 PERFSTATE_POLICY_CHANGE_IDEAL = 0;
	public const uint32 PERFSTATE_POLICY_CHANGE_SINGLE = 1;
	public const uint32 PERFSTATE_POLICY_CHANGE_ROCKET = 2;
	public const uint32 PERFSTATE_POLICY_CHANGE_IDEAL_AGGRESSIVE = 3;
	public const uint32 PERFSTATE_POLICY_CHANGE_DECREASE_MAX = 2;
	public const uint32 PERFSTATE_POLICY_CHANGE_INCREASE_MAX = 3;
	public const Guid GUID_PROCESSOR_THROTTLE_MAXIMUM = .(0xbc5038f7, 0x23e0, 0x4960, 0x96, 0xda, 0x33, 0xab, 0xaf, 0x59, 0x35, 0xec);
	public const Guid GUID_PROCESSOR_THROTTLE_MAXIMUM_1 = .(0xbc5038f7, 0x23e0, 0x4960, 0x96, 0xda, 0x33, 0xab, 0xaf, 0x59, 0x35, 0xed);
	public const Guid GUID_PROCESSOR_THROTTLE_MINIMUM = .(0x893dee8e, 0x2bef, 0x41e0, 0x89, 0xc6, 0xb5, 0x5d, 0x09, 0x29, 0x96, 0x4c);
	public const Guid GUID_PROCESSOR_THROTTLE_MINIMUM_1 = .(0x893dee8e, 0x2bef, 0x41e0, 0x89, 0xc6, 0xb5, 0x5d, 0x09, 0x29, 0x96, 0x4d);
	public const Guid GUID_PROCESSOR_FREQUENCY_LIMIT = .(0x75b0ae3f, 0xbce0, 0x45a7, 0x8c, 0x89, 0xc9, 0x61, 0x1c, 0x25, 0xe1, 0x00);
	public const Guid GUID_PROCESSOR_FREQUENCY_LIMIT_1 = .(0x75b0ae3f, 0xbce0, 0x45a7, 0x8c, 0x89, 0xc9, 0x61, 0x1c, 0x25, 0xe1, 0x01);
	public const Guid GUID_PROCESSOR_ALLOW_THROTTLING = .(0x3b04d4fd, 0x1cc7, 0x4f23, 0xab, 0x1c, 0xd1, 0x33, 0x78, 0x19, 0xc4, 0xbb);
	public const uint32 PROCESSOR_THROTTLE_DISABLED = 0;
	public const uint32 PROCESSOR_THROTTLE_ENABLED = 1;
	public const uint32 PROCESSOR_THROTTLE_AUTOMATIC = 2;
	public const Guid GUID_PROCESSOR_IDLESTATE_POLICY = .(0x68f262a7, 0xf621, 0x4069, 0xb9, 0xa5, 0x48, 0x74, 0x16, 0x9b, 0xe2, 0x3c);
	public const Guid GUID_PROCESSOR_PERFSTATE_POLICY = .(0xbbdc3814, 0x18e9, 0x4463, 0x8a, 0x55, 0xd1, 0x97, 0x32, 0x7c, 0x45, 0xc0);
	public const Guid GUID_PROCESSOR_PERF_INCREASE_THRESHOLD = .(0x06cadf0e, 0x64ed, 0x448a, 0x89, 0x27, 0xce, 0x7b, 0xf9, 0x0e, 0xb3, 0x5d);
	public const Guid GUID_PROCESSOR_PERF_INCREASE_THRESHOLD_1 = .(0x06cadf0e, 0x64ed, 0x448a, 0x89, 0x27, 0xce, 0x7b, 0xf9, 0x0e, 0xb3, 0x5e);
	public const Guid GUID_PROCESSOR_PERF_DECREASE_THRESHOLD = .(0x12a0ab44, 0xfe28, 0x4fa9, 0xb3, 0xbd, 0x4b, 0x64, 0xf4, 0x49, 0x60, 0xa6);
	public const Guid GUID_PROCESSOR_PERF_DECREASE_THRESHOLD_1 = .(0x12a0ab44, 0xfe28, 0x4fa9, 0xb3, 0xbd, 0x4b, 0x64, 0xf4, 0x49, 0x60, 0xa7);
	public const Guid GUID_PROCESSOR_PERF_INCREASE_POLICY = .(0x465e1f50, 0xb610, 0x473a, 0xab, 0x58, 0x00, 0xd1, 0x07, 0x7d, 0xc4, 0x18);
	public const Guid GUID_PROCESSOR_PERF_INCREASE_POLICY_1 = .(0x465e1f50, 0xb610, 0x473a, 0xab, 0x58, 0x00, 0xd1, 0x07, 0x7d, 0xc4, 0x19);
	public const Guid GUID_PROCESSOR_PERF_DECREASE_POLICY = .(0x40fbefc7, 0x2e9d, 0x4d25, 0xa1, 0x85, 0x0c, 0xfd, 0x85, 0x74, 0xba, 0xc6);
	public const Guid GUID_PROCESSOR_PERF_DECREASE_POLICY_1 = .(0x40fbefc7, 0x2e9d, 0x4d25, 0xa1, 0x85, 0x0c, 0xfd, 0x85, 0x74, 0xba, 0xc7);
	public const Guid GUID_PROCESSOR_PERF_INCREASE_TIME = .(0x984cf492, 0x3bed, 0x4488, 0xa8, 0xf9, 0x42, 0x86, 0xc9, 0x7b, 0xf5, 0xaa);
	public const Guid GUID_PROCESSOR_PERF_INCREASE_TIME_1 = .(0x984cf492, 0x3bed, 0x4488, 0xa8, 0xf9, 0x42, 0x86, 0xc9, 0x7b, 0xf5, 0xab);
	public const Guid GUID_PROCESSOR_PERF_DECREASE_TIME = .(0xd8edeb9b, 0x95cf, 0x4f95, 0xa7, 0x3c, 0xb0, 0x61, 0x97, 0x36, 0x93, 0xc8);
	public const Guid GUID_PROCESSOR_PERF_DECREASE_TIME_1 = .(0xd8edeb9b, 0x95cf, 0x4f95, 0xa7, 0x3c, 0xb0, 0x61, 0x97, 0x36, 0x93, 0xc9);
	public const Guid GUID_PROCESSOR_PERF_TIME_CHECK = .(0x4d2b0152, 0x7d5c, 0x498b, 0x88, 0xe2, 0x34, 0x34, 0x53, 0x92, 0xa2, 0xc5);
	public const Guid GUID_PROCESSOR_PERF_BOOST_POLICY = .(0x45bcc044, 0xd885, 0x43e2, 0x86, 0x05, 0xee, 0x0e, 0xc6, 0xe9, 0x6b, 0x59);
	public const uint32 PROCESSOR_PERF_BOOST_POLICY_DISABLED = 0;
	public const uint32 PROCESSOR_PERF_BOOST_POLICY_MAX = 100;
	public const Guid GUID_PROCESSOR_PERF_BOOST_MODE = .(0xbe337238, 0x0d82, 0x4146, 0xa9, 0x60, 0x4f, 0x37, 0x49, 0xd4, 0x70, 0xc7);
	public const uint32 PROCESSOR_PERF_BOOST_MODE_DISABLED = 0;
	public const uint32 PROCESSOR_PERF_BOOST_MODE_ENABLED = 1;
	public const uint32 PROCESSOR_PERF_BOOST_MODE_AGGRESSIVE = 2;
	public const uint32 PROCESSOR_PERF_BOOST_MODE_EFFICIENT_ENABLED = 3;
	public const uint32 PROCESSOR_PERF_BOOST_MODE_EFFICIENT_AGGRESSIVE = 4;
	public const uint32 PROCESSOR_PERF_BOOST_MODE_AGGRESSIVE_AT_GUARANTEED = 5;
	public const uint32 PROCESSOR_PERF_BOOST_MODE_EFFICIENT_AGGRESSIVE_AT_GUARANTEED = 6;
	public const uint32 PROCESSOR_PERF_BOOST_MODE_MAX = 6;
	public const Guid GUID_PROCESSOR_PERF_AUTONOMOUS_MODE = .(0x8baa4a8a, 0x14c6, 0x4451, 0x8e, 0x8b, 0x14, 0xbd, 0xbd, 0x19, 0x75, 0x37);
	public const uint32 PROCESSOR_PERF_AUTONOMOUS_MODE_DISABLED = 0;
	public const uint32 PROCESSOR_PERF_AUTONOMOUS_MODE_ENABLED = 1;
	public const Guid GUID_PROCESSOR_PERF_ENERGY_PERFORMANCE_PREFERENCE = .(0x36687f9e, 0xe3a5, 0x4dbf, 0xb1, 0xdc, 0x15, 0xeb, 0x38, 0x1c, 0x68, 0x63);
	public const Guid GUID_PROCESSOR_PERF_ENERGY_PERFORMANCE_PREFERENCE_1 = .(0x36687f9e, 0xe3a5, 0x4dbf, 0xb1, 0xdc, 0x15, 0xeb, 0x38, 0x1c, 0x68, 0x64);
	public const uint32 PROCESSOR_PERF_PERFORMANCE_PREFERENCE = 255;
	public const uint32 PROCESSOR_PERF_ENERGY_PREFERENCE = 0;
	public const Guid GUID_PROCESSOR_PERF_AUTONOMOUS_ACTIVITY_WINDOW = .(0xcfeda3d0, 0x7697, 0x4566, 0xa9, 0x22, 0xa9, 0x08, 0x6c, 0xd4, 0x9d, 0xfa);
	public const uint32 PROCESSOR_PERF_MINIMUM_ACTIVITY_WINDOW = 0;
	public const uint32 PROCESSOR_PERF_MAXIMUM_ACTIVITY_WINDOW = 1270000000;
	public const Guid GUID_PROCESSOR_DUTY_CYCLING = .(0x4e4450b3, 0x6179, 0x4e91, 0xb8, 0xf1, 0x5b, 0xb9, 0x93, 0x8f, 0x81, 0xa1);
	public const uint32 PROCESSOR_DUTY_CYCLING_DISABLED = 0;
	public const uint32 PROCESSOR_DUTY_CYCLING_ENABLED = 1;
	public const Guid GUID_PROCESSOR_IDLE_ALLOW_SCALING = .(0x6c2993b0, 0x8f48, 0x481f, 0xbc, 0xc6, 0x00, 0xdd, 0x27, 0x42, 0xaa, 0x06);
	public const Guid GUID_PROCESSOR_IDLE_DISABLE = .(0x5d76a2ca, 0xe8c0, 0x402f, 0xa1, 0x33, 0x21, 0x58, 0x49, 0x2d, 0x58, 0xad);
	public const Guid GUID_PROCESSOR_IDLE_STATE_MAXIMUM = .(0x9943e905, 0x9a30, 0x4ec1, 0x9b, 0x99, 0x44, 0xdd, 0x3b, 0x76, 0xf7, 0xa2);
	public const Guid GUID_PROCESSOR_IDLE_TIME_CHECK = .(0xc4581c31, 0x89ab, 0x4597, 0x8e, 0x2b, 0x9c, 0x9c, 0xab, 0x44, 0x0e, 0x6b);
	public const Guid GUID_PROCESSOR_IDLE_DEMOTE_THRESHOLD = .(0x4b92d758, 0x5a24, 0x4851, 0xa4, 0x70, 0x81, 0x5d, 0x78, 0xae, 0xe1, 0x19);
	public const Guid GUID_PROCESSOR_IDLE_PROMOTE_THRESHOLD = .(0x7b224883, 0xb3cc, 0x4d79, 0x81, 0x9f, 0x83, 0x74, 0x15, 0x2c, 0xbe, 0x7c);
	public const Guid GUID_PROCESSOR_CORE_PARKING_INCREASE_THRESHOLD = .(0xdf142941, 0x20f3, 0x4edf, 0x9a, 0x4a, 0x9c, 0x83, 0xd3, 0xd7, 0x17, 0xd1);
	public const Guid GUID_PROCESSOR_CORE_PARKING_DECREASE_THRESHOLD = .(0x68dd2f27, 0xa4ce, 0x4e11, 0x84, 0x87, 0x37, 0x94, 0xe4, 0x13, 0x5d, 0xfa);
	public const Guid GUID_PROCESSOR_CORE_PARKING_INCREASE_POLICY = .(0xc7be0679, 0x2817, 0x4d69, 0x9d, 0x02, 0x51, 0x9a, 0x53, 0x7e, 0xd0, 0xc6);
	public const uint32 CORE_PARKING_POLICY_CHANGE_IDEAL = 0;
	public const uint32 CORE_PARKING_POLICY_CHANGE_SINGLE = 1;
	public const uint32 CORE_PARKING_POLICY_CHANGE_ROCKET = 2;
	public const uint32 CORE_PARKING_POLICY_CHANGE_MULTISTEP = 3;
	public const uint32 CORE_PARKING_POLICY_CHANGE_MAX = 3;
	public const Guid GUID_PROCESSOR_CORE_PARKING_DECREASE_POLICY = .(0x71021b41, 0xc749, 0x4d21, 0xbe, 0x74, 0xa0, 0x0f, 0x33, 0x5d, 0x58, 0x2b);
	public const Guid GUID_PROCESSOR_CORE_PARKING_MAX_CORES = .(0xea062031, 0x0e34, 0x4ff1, 0x9b, 0x6d, 0xeb, 0x10, 0x59, 0x33, 0x40, 0x28);
	public const Guid GUID_PROCESSOR_CORE_PARKING_MAX_CORES_1 = .(0xea062031, 0x0e34, 0x4ff1, 0x9b, 0x6d, 0xeb, 0x10, 0x59, 0x33, 0x40, 0x29);
	public const Guid GUID_PROCESSOR_CORE_PARKING_MIN_CORES = .(0x0cc5b647, 0xc1df, 0x4637, 0x89, 0x1a, 0xde, 0xc3, 0x5c, 0x31, 0x85, 0x83);
	public const Guid GUID_PROCESSOR_CORE_PARKING_MIN_CORES_1 = .(0x0cc5b647, 0xc1df, 0x4637, 0x89, 0x1a, 0xde, 0xc3, 0x5c, 0x31, 0x85, 0x84);
	public const Guid GUID_PROCESSOR_CORE_PARKING_INCREASE_TIME = .(0x2ddd5a84, 0x5a71, 0x437e, 0x91, 0x2a, 0xdb, 0x0b, 0x8c, 0x78, 0x87, 0x32);
	public const Guid GUID_PROCESSOR_CORE_PARKING_DECREASE_TIME = .(0xdfd10d17, 0xd5eb, 0x45dd, 0x87, 0x7a, 0x9a, 0x34, 0xdd, 0xd1, 0x5c, 0x82);
	public const Guid GUID_PROCESSOR_CORE_PARKING_AFFINITY_HISTORY_DECREASE_FACTOR = .(0x8f7b45e3, 0xc393, 0x480a, 0x87, 0x8c, 0xf6, 0x7a, 0xc3, 0xd0, 0x70, 0x82);
	public const Guid GUID_PROCESSOR_CORE_PARKING_AFFINITY_HISTORY_THRESHOLD = .(0x5b33697b, 0xe89d, 0x4d38, 0xaa, 0x46, 0x9e, 0x7d, 0xfb, 0x7c, 0xd2, 0xf9);
	public const Guid GUID_PROCESSOR_CORE_PARKING_AFFINITY_WEIGHTING = .(0xe70867f1, 0xfa2f, 0x4f4e, 0xae, 0xa1, 0x4d, 0x8a, 0x0b, 0xa2, 0x3b, 0x20);
	public const Guid GUID_PROCESSOR_CORE_PARKING_OVER_UTILIZATION_HISTORY_DECREASE_FACTOR = .(0x1299023c, 0xbc28, 0x4f0a, 0x81, 0xec, 0xd3, 0x29, 0x5a, 0x8d, 0x81, 0x5d);
	public const Guid GUID_PROCESSOR_CORE_PARKING_OVER_UTILIZATION_HISTORY_THRESHOLD = .(0x9ac18e92, 0xaa3c, 0x4e27, 0xb3, 0x07, 0x01, 0xae, 0x37, 0x30, 0x71, 0x29);
	public const Guid GUID_PROCESSOR_CORE_PARKING_OVER_UTILIZATION_WEIGHTING = .(0x8809c2d8, 0xb155, 0x42d4, 0xbc, 0xda, 0x0d, 0x34, 0x56, 0x51, 0xb1, 0xdb);
	public const Guid GUID_PROCESSOR_CORE_PARKING_OVER_UTILIZATION_THRESHOLD = .(0x943c8cb6, 0x6f93, 0x4227, 0xad, 0x87, 0xe9, 0xa3, 0xfe, 0xec, 0x08, 0xd1);
	public const Guid GUID_PROCESSOR_PARKING_CORE_OVERRIDE = .(0xa55612aa, 0xf624, 0x42c6, 0xa4, 0x43, 0x73, 0x97, 0xd0, 0x64, 0xc0, 0x4f);
	public const Guid GUID_PROCESSOR_PARKING_PERF_STATE = .(0x447235c7, 0x6a8d, 0x4cc0, 0x8e, 0x24, 0x9e, 0xaf, 0x70, 0xb9, 0x6e, 0x2b);
	public const Guid GUID_PROCESSOR_PARKING_PERF_STATE_1 = .(0x447235c7, 0x6a8d, 0x4cc0, 0x8e, 0x24, 0x9e, 0xaf, 0x70, 0xb9, 0x6e, 0x2c);
	public const Guid GUID_PROCESSOR_PARKING_CONCURRENCY_THRESHOLD = .(0x2430ab6f, 0xa520, 0x44a2, 0x96, 0x01, 0xf7, 0xf2, 0x3b, 0x51, 0x34, 0xb1);
	public const Guid GUID_PROCESSOR_PARKING_HEADROOM_THRESHOLD = .(0xf735a673, 0x2066, 0x4f80, 0xa0, 0xc5, 0xdd, 0xee, 0x0c, 0xf1, 0xbf, 0x5d);
	public const Guid GUID_PROCESSOR_PARKING_DISTRIBUTION_THRESHOLD = .(0x4bdaf4e9, 0xd103, 0x46d7, 0xa5, 0xf0, 0x62, 0x80, 0x12, 0x16, 0x16, 0xef);
	public const Guid GUID_PROCESSOR_SOFT_PARKING_LATENCY = .(0x97cfac41, 0x2217, 0x47eb, 0x99, 0x2d, 0x61, 0x8b, 0x19, 0x77, 0xc9, 0x07);
	public const Guid GUID_PROCESSOR_PERF_HISTORY = .(0x7d24baa7, 0x0b84, 0x480f, 0x84, 0x0c, 0x1b, 0x07, 0x43, 0xc0, 0x0f, 0x5f);
	public const Guid GUID_PROCESSOR_PERF_HISTORY_1 = .(0x7d24baa7, 0x0b84, 0x480f, 0x84, 0x0c, 0x1b, 0x07, 0x43, 0xc0, 0x0f, 0x60);
	public const Guid GUID_PROCESSOR_PERF_INCREASE_HISTORY = .(0x99b3ef01, 0x752f, 0x46a1, 0x80, 0xfb, 0x77, 0x30, 0x01, 0x1f, 0x23, 0x54);
	public const Guid GUID_PROCESSOR_PERF_DECREASE_HISTORY = .(0x0300f6f8, 0xabd6, 0x45a9, 0xb7, 0x4f, 0x49, 0x08, 0x69, 0x1a, 0x40, 0xb5);
	public const Guid GUID_PROCESSOR_PERF_CORE_PARKING_HISTORY = .(0x77d7f282, 0x8f1a, 0x42cd, 0x85, 0x37, 0x45, 0x45, 0x0a, 0x83, 0x9b, 0xe8);
	public const Guid GUID_PROCESSOR_PERF_LATENCY_HINT = .(0x0822df31, 0x9c83, 0x441c, 0xa0, 0x79, 0x0d, 0xe4, 0xcf, 0x00, 0x9c, 0x7b);
	public const Guid GUID_PROCESSOR_PERF_LATENCY_HINT_PERF = .(0x619b7505, 0x003b, 0x4e82, 0xb7, 0xa6, 0x4d, 0xd2, 0x9c, 0x30, 0x09, 0x71);
	public const Guid GUID_PROCESSOR_PERF_LATENCY_HINT_PERF_1 = .(0x619b7505, 0x003b, 0x4e82, 0xb7, 0xa6, 0x4d, 0xd2, 0x9c, 0x30, 0x09, 0x72);
	public const Guid GUID_PROCESSOR_LATENCY_HINT_MIN_UNPARK = .(0x616cdaa5, 0x695e, 0x4545, 0x97, 0xad, 0x97, 0xdc, 0x2d, 0x1b, 0xdd, 0x88);
	public const Guid GUID_PROCESSOR_LATENCY_HINT_MIN_UNPARK_1 = .(0x616cdaa5, 0x695e, 0x4545, 0x97, 0xad, 0x97, 0xdc, 0x2d, 0x1b, 0xdd, 0x89);
	public const Guid GUID_PROCESSOR_DISTRIBUTE_UTILITY = .(0xe0007330, 0xf589, 0x42ed, 0xa4, 0x01, 0x5d, 0xdb, 0x10, 0xe7, 0x85, 0xd3);
	public const Guid GUID_PROCESSOR_HETEROGENEOUS_POLICY = .(0x7f2f5cfa, 0xf10c, 0x4823, 0xb5, 0xe1, 0xe9, 0x3a, 0xe8, 0x5f, 0x46, 0xb5);
	public const Guid GUID_PROCESSOR_HETERO_DECREASE_TIME = .(0x7f2492b6, 0x60b1, 0x45e5, 0xae, 0x55, 0x77, 0x3f, 0x8c, 0xd5, 0xca, 0xec);
	public const Guid GUID_PROCESSOR_HETERO_INCREASE_TIME = .(0x4009efa7, 0xe72d, 0x4cba, 0x9e, 0xdf, 0x91, 0x08, 0x4e, 0xa8, 0xcb, 0xc3);
	public const Guid GUID_PROCESSOR_HETERO_DECREASE_THRESHOLD = .(0xf8861c27, 0x95e7, 0x475c, 0x86, 0x5b, 0x13, 0xc0, 0xcb, 0x3f, 0x9d, 0x6b);
	public const Guid GUID_PROCESSOR_HETERO_INCREASE_THRESHOLD = .(0xb000397d, 0x9b0b, 0x483d, 0x98, 0xc9, 0x69, 0x2a, 0x60, 0x60, 0xcf, 0xbf);
	public const Guid GUID_PROCESSOR_CLASS0_FLOOR_PERF = .(0xfddc842b, 0x8364, 0x4edc, 0x94, 0xcf, 0xc1, 0x7f, 0x60, 0xde, 0x1c, 0x80);
	public const Guid GUID_PROCESSOR_CLASS1_INITIAL_PERF = .(0x1facfc65, 0xa930, 0x4bc5, 0x9f, 0x38, 0x50, 0x4e, 0xc0, 0x97, 0xbb, 0xc0);
	public const Guid GUID_PROCESSOR_THREAD_SCHEDULING_POLICY = .(0x93b8b6dc, 0x0698, 0x4d1c, 0x9e, 0xe4, 0x06, 0x44, 0xe9, 0x00, 0xc8, 0x5d);
	public const Guid GUID_PROCESSOR_SHORT_THREAD_SCHEDULING_POLICY = .(0xbae08b81, 0x2d5e, 0x4688, 0xad, 0x6a, 0x13, 0x24, 0x33, 0x56, 0x65, 0x4b);
	public const Guid GUID_PROCESSOR_SHORT_THREAD_RUNTIME_THRESHOLD = .(0xd92998c2, 0x6a48, 0x49ca, 0x85, 0xd4, 0x8c, 0xce, 0xec, 0x29, 0x45, 0x70);
	public const Guid GUID_SYSTEM_COOLING_POLICY = .(0x94d3a615, 0xa899, 0x4ac5, 0xae, 0x2b, 0xe4, 0xd8, 0xf6, 0x34, 0x36, 0x7f);
	public const Guid GUID_PROCESSOR_RESPONSIVENESS_DISABLE_THRESHOLD = .(0x38b8383d, 0xcce0, 0x4c79, 0x9e, 0x3e, 0x56, 0xa4, 0xf1, 0x7c, 0xc4, 0x80);
	public const Guid GUID_PROCESSOR_RESPONSIVENESS_DISABLE_THRESHOLD_1 = .(0x38b8383d, 0xcce0, 0x4c79, 0x9e, 0x3e, 0x56, 0xa4, 0xf1, 0x7c, 0xc4, 0x81);
	public const Guid GUID_PROCESSOR_RESPONSIVENESS_ENABLE_THRESHOLD = .(0x3d44e256, 0x7222, 0x4415, 0xa9, 0xed, 0x9c, 0x45, 0xfa, 0x3d, 0xd8, 0x30);
	public const Guid GUID_PROCESSOR_RESPONSIVENESS_ENABLE_THRESHOLD_1 = .(0x3d44e256, 0x7222, 0x4415, 0xa9, 0xed, 0x9c, 0x45, 0xfa, 0x3d, 0xd8, 0x31);
	public const Guid GUID_PROCESSOR_RESPONSIVENESS_DISABLE_TIME = .(0xf565999f, 0x3fb0, 0x411a, 0xa2, 0x26, 0x3f, 0x01, 0x98, 0xde, 0xc1, 0x30);
	public const Guid GUID_PROCESSOR_RESPONSIVENESS_DISABLE_TIME_1 = .(0xf565999f, 0x3fb0, 0x411a, 0xa2, 0x26, 0x3f, 0x01, 0x98, 0xde, 0xc1, 0x31);
	public const Guid GUID_PROCESSOR_RESPONSIVENESS_ENABLE_TIME = .(0x3d915188, 0x7830, 0x49ae, 0xa7, 0x9a, 0x0f, 0xb0, 0xa1, 0xe5, 0xa2, 0x00);
	public const Guid GUID_PROCESSOR_RESPONSIVENESS_ENABLE_TIME_1 = .(0x3d915188, 0x7830, 0x49ae, 0xa7, 0x9a, 0x0f, 0xb0, 0xa1, 0xe5, 0xa2, 0x01);
	public const Guid GUID_PROCESSOR_RESPONSIVENESS_EPP_CEILING = .(0x4427c73b, 0x9756, 0x4a5c, 0xb8, 0x4b, 0xc7, 0xbd, 0xa7, 0x9c, 0x73, 0x20);
	public const Guid GUID_PROCESSOR_RESPONSIVENESS_EPP_CEILING_1 = .(0x4427c73b, 0x9756, 0x4a5c, 0xb8, 0x4b, 0xc7, 0xbd, 0xa7, 0x9c, 0x73, 0x21);
	public const Guid GUID_PROCESSOR_RESPONSIVENESS_PERF_FLOOR = .(0xce8e92ee, 0x6a86, 0x4572, 0xbf, 0xe0, 0x20, 0xc2, 0x1d, 0x03, 0xcd, 0x40);
	public const Guid GUID_PROCESSOR_RESPONSIVENESS_PERF_FLOOR_1 = .(0xce8e92ee, 0x6a86, 0x4572, 0xbf, 0xe0, 0x20, 0xc2, 0x1d, 0x03, 0xcd, 0x41);
	public const Guid GUID_LOCK_CONSOLE_ON_WAKE = .(0x0e796bdb, 0x100d, 0x47d6, 0xa2, 0xd5, 0xf7, 0xd2, 0xda, 0xa5, 0x1f, 0x51);
	public const Guid GUID_DEVICE_IDLE_POLICY = .(0x4faab71a, 0x92e5, 0x4726, 0xb5, 0x31, 0x22, 0x45, 0x59, 0x67, 0x2d, 0x19);
	public const uint32 POWER_DEVICE_IDLE_POLICY_PERFORMANCE = 0;
	public const uint32 POWER_DEVICE_IDLE_POLICY_CONSERVATIVE = 1;
	public const Guid GUID_CONNECTIVITY_IN_STANDBY = .(0xf15576e8, 0x98b7, 0x4186, 0xb9, 0x44, 0xea, 0xfa, 0x66, 0x44, 0x02, 0xd9);
	public const uint32 POWER_CONNECTIVITY_IN_STANDBY_DISABLED = 0;
	public const uint32 POWER_CONNECTIVITY_IN_STANDBY_ENABLED = 1;
	public const uint32 POWER_CONNECTIVITY_IN_STANDBY_SYSTEM_MANAGED = 2;
	public const Guid GUID_DISCONNECTED_STANDBY_MODE = .(0x68afb2d9, 0xee95, 0x47a8, 0x8f, 0x50, 0x41, 0x15, 0x08, 0x80, 0x73, 0xb1);
	public const uint32 POWER_DISCONNECTED_STANDBY_MODE_NORMAL = 0;
	public const uint32 POWER_DISCONNECTED_STANDBY_MODE_AGGRESSIVE = 1;
	public const Guid GUID_ACDC_POWER_SOURCE = .(0x5d3e9a59, 0xe9d5, 0x4b00, 0xa6, 0xbd, 0xff, 0x34, 0xff, 0x51, 0x65, 0x48);
	public const Guid GUID_LIDSWITCH_STATE_CHANGE = .(0xba3e0f4d, 0xb817, 0x4094, 0xa2, 0xd1, 0xd5, 0x63, 0x79, 0xe6, 0xa0, 0xf3);
	public const Guid GUID_LIDSWITCH_STATE_RELIABILITY = .(0xae4c4ff1, 0xd361, 0x43f4, 0x80, 0xaa, 0xbb, 0xb6, 0xeb, 0x03, 0xde, 0x94);
	public const Guid GUID_BATTERY_PERCENTAGE_REMAINING = .(0xa7ad8041, 0xb45a, 0x4cae, 0x87, 0xa3, 0xee, 0xcb, 0xb4, 0x68, 0xa9, 0xe1);
	public const Guid GUID_BATTERY_COUNT = .(0x7d263f15, 0xfca4, 0x49e5, 0x85, 0x4b, 0xa9, 0xf2, 0xbf, 0xbd, 0x5c, 0x24);
	public const Guid GUID_GLOBAL_USER_PRESENCE = .(0x786e8a1d, 0xb427, 0x4344, 0x92, 0x07, 0x09, 0xe7, 0x0b, 0xdc, 0xbe, 0xa9);
	public const Guid GUID_SESSION_DISPLAY_STATUS = .(0x2b84c20e, 0xad23, 0x4ddf, 0x93, 0xdb, 0x05, 0xff, 0xbd, 0x7e, 0xfc, 0xa5);
	public const Guid GUID_SESSION_USER_PRESENCE = .(0x3c0f4548, 0xc03f, 0x4c4d, 0xb9, 0xf2, 0x23, 0x7e, 0xde, 0x68, 0x63, 0x76);
	public const Guid GUID_IDLE_BACKGROUND_TASK = .(0x515c31d8, 0xf734, 0x163d, 0xa0, 0xfd, 0x11, 0xa0, 0x8c, 0x91, 0xe8, 0xf1);
	public const Guid GUID_BACKGROUND_TASK_NOTIFICATION = .(0xcf23f240, 0x2a54, 0x48d8, 0xb1, 0x14, 0xde, 0x15, 0x18, 0xff, 0x05, 0x2e);
	public const Guid GUID_APPLAUNCH_BUTTON = .(0x1a689231, 0x7399, 0x4e9a, 0x8f, 0x99, 0xb7, 0x1f, 0x99, 0x9d, 0xb3, 0xfa);
	public const Guid GUID_PCIEXPRESS_SETTINGS_SUBGROUP = .(0x501a4d13, 0x42af, 0x4429, 0x9f, 0xd1, 0xa8, 0x21, 0x8c, 0x26, 0x8e, 0x20);
	public const Guid GUID_PCIEXPRESS_ASPM_POLICY = .(0xee12f906, 0xd277, 0x404b, 0xb6, 0xda, 0xe5, 0xfa, 0x1a, 0x57, 0x6d, 0xf5);
	public const Guid GUID_ENABLE_SWITCH_FORCED_SHUTDOWN = .(0x833a6b62, 0xdfa4, 0x46d1, 0x82, 0xf8, 0xe0, 0x9e, 0x34, 0xd0, 0x29, 0xd6);
	public const Guid GUID_INTSTEER_SUBGROUP = .(0x48672f38, 0x7a9a, 0x4bb2, 0x8b, 0xf8, 0x3d, 0x85, 0xbe, 0x19, 0xde, 0x4e);
	public const Guid GUID_INTSTEER_MODE = .(0x2bfc24f9, 0x5ea2, 0x4801, 0x82, 0x13, 0x3d, 0xba, 0xe0, 0x1a, 0xa3, 0x9d);
	public const Guid GUID_INTSTEER_LOAD_PER_PROC_TRIGGER = .(0x73cde64d, 0xd720, 0x4bb2, 0xa8, 0x60, 0xc7, 0x55, 0xaf, 0xe7, 0x7e, 0xf2);
	public const Guid GUID_INTSTEER_TIME_UNPARK_TRIGGER = .(0xd6ba4903, 0x386f, 0x4c2c, 0x8a, 0xdb, 0x5c, 0x21, 0xb3, 0x32, 0x8d, 0x25);
	public const Guid GUID_GRAPHICS_SUBGROUP = .(0x5fb4938d, 0x1ee8, 0x4b0f, 0x9a, 0x3c, 0x50, 0x36, 0xb0, 0xab, 0x99, 0x5c);
	public const Guid GUID_GPU_PREFERENCE_POLICY = .(0xdd848b2a, 0x8a5d, 0x4451, 0x9a, 0xe2, 0x39, 0xcd, 0x41, 0x65, 0x8f, 0x6c);
	public const Guid GUID_MIXED_REALITY_MODE = .(0x1e626b4e, 0xcf04, 0x4f8d, 0x9c, 0xc7, 0xc9, 0x7c, 0x5b, 0x0f, 0x23, 0x91);
	public const Guid GUID_SPR_ACTIVE_SESSION_CHANGE = .(0x0e24ce38, 0xc393, 0x4742, 0xbd, 0xb1, 0x74, 0x4f, 0x4b, 0x9e, 0xe0, 0x8e);
	public const uint32 POWER_SYSTEM_MAXIMUM = 7;
	public const uint32 DIAGNOSTIC_REASON_VERSION = 0;
	public const uint32 DIAGNOSTIC_REASON_SIMPLE_STRING = 1;
	public const uint32 DIAGNOSTIC_REASON_DETAILED_STRING = 2;
	public const uint32 DIAGNOSTIC_REASON_NOT_SPECIFIED = 2147483648;
	public const uint32 POWER_REQUEST_CONTEXT_VERSION = 0;
	public const uint32 PDCAP_D0_SUPPORTED = 1;
	public const uint32 PDCAP_D1_SUPPORTED = 2;
	public const uint32 PDCAP_D2_SUPPORTED = 4;
	public const uint32 PDCAP_D3_SUPPORTED = 8;
	public const uint32 PDCAP_WAKE_FROM_D0_SUPPORTED = 16;
	public const uint32 PDCAP_WAKE_FROM_D1_SUPPORTED = 32;
	public const uint32 PDCAP_WAKE_FROM_D2_SUPPORTED = 64;
	public const uint32 PDCAP_WAKE_FROM_D3_SUPPORTED = 128;
	public const uint32 PDCAP_WARM_EJECT_SUPPORTED = 256;
	public const uint32 POWER_SETTING_VALUE_VERSION = 1;
	public const uint32 PROC_IDLE_BUCKET_COUNT = 6;
	public const uint32 PROC_IDLE_BUCKET_COUNT_EX = 16;
	public const uint32 ACPI_PPM_SOFTWARE_ALL = 252;
	public const uint32 ACPI_PPM_SOFTWARE_ANY = 253;
	public const uint32 ACPI_PPM_HARDWARE_ALL = 254;
	public const uint32 MS_PPM_SOFTWARE_ALL = 1;
	public const uint32 PPM_FIRMWARE_ACPI1C2 = 1;
	public const uint32 PPM_FIRMWARE_ACPI1C3 = 2;
	public const uint32 PPM_FIRMWARE_ACPI1TSTATES = 4;
	public const uint32 PPM_FIRMWARE_CST = 8;
	public const uint32 PPM_FIRMWARE_CSD = 16;
	public const uint32 PPM_FIRMWARE_PCT = 32;
	public const uint32 PPM_FIRMWARE_PSS = 64;
	public const uint32 PPM_FIRMWARE_XPSS = 128;
	public const uint32 PPM_FIRMWARE_PPC = 256;
	public const uint32 PPM_FIRMWARE_PSD = 512;
	public const uint32 PPM_FIRMWARE_PTC = 1024;
	public const uint32 PPM_FIRMWARE_TSS = 2048;
	public const uint32 PPM_FIRMWARE_TPC = 4096;
	public const uint32 PPM_FIRMWARE_TSD = 8192;
	public const uint32 PPM_FIRMWARE_PCCH = 16384;
	public const uint32 PPM_FIRMWARE_PCCP = 32768;
	public const uint32 PPM_FIRMWARE_OSC = 65536;
	public const uint32 PPM_FIRMWARE_PDC = 131072;
	public const uint32 PPM_FIRMWARE_CPC = 262144;
	public const uint32 PPM_FIRMWARE_LPI = 524288;
	public const uint32 PPM_PERFORMANCE_IMPLEMENTATION_NONE = 0;
	public const uint32 PPM_PERFORMANCE_IMPLEMENTATION_PSTATES = 1;
	public const uint32 PPM_PERFORMANCE_IMPLEMENTATION_PCCV1 = 2;
	public const uint32 PPM_PERFORMANCE_IMPLEMENTATION_CPPC = 3;
	public const uint32 PPM_PERFORMANCE_IMPLEMENTATION_PEP = 4;
	public const uint32 PPM_IDLE_IMPLEMENTATION_NONE = 0;
	public const uint32 PPM_IDLE_IMPLEMENTATION_CSTATES = 1;
	public const uint32 PPM_IDLE_IMPLEMENTATION_PEP = 2;
	public const uint32 PPM_IDLE_IMPLEMENTATION_MICROPEP = 3;
	public const uint32 PPM_IDLE_IMPLEMENTATION_LPISTATES = 4;
	public const Guid PPM_PERFSTATE_CHANGE_GUID = .(0xa5b32ddd, 0x7f39, 0x4abc, 0xb8, 0x92, 0x90, 0x0e, 0x43, 0xb5, 0x9e, 0xbb);
	public const Guid PPM_PERFSTATE_DOMAIN_CHANGE_GUID = .(0x995e6b7f, 0xd653, 0x497a, 0xb9, 0x78, 0x36, 0xa3, 0x0c, 0x29, 0xbf, 0x01);
	public const Guid PPM_IDLESTATE_CHANGE_GUID = .(0x4838fe4f, 0xf71c, 0x4e51, 0x9e, 0xcc, 0x84, 0x30, 0xa7, 0xac, 0x4c, 0x6c);
	public const Guid PPM_PERFSTATES_DATA_GUID = .(0x5708cc20, 0x7d40, 0x4bf4, 0xb4, 0xaa, 0x2b, 0x01, 0x33, 0x8d, 0x01, 0x26);
	public const Guid PPM_IDLESTATES_DATA_GUID = .(0xba138e10, 0xe250, 0x4ad7, 0x86, 0x16, 0xcf, 0x1a, 0x7a, 0xd4, 0x10, 0xe7);
	public const Guid PPM_IDLE_ACCOUNTING_GUID = .(0xe2a26f78, 0xae07, 0x4ee0, 0xa3, 0x0f, 0xce, 0x54, 0xf5, 0x5a, 0x94, 0xcd);
	public const Guid PPM_IDLE_ACCOUNTING_EX_GUID = .(0xd67abd39, 0x81f8, 0x4a5e, 0x81, 0x52, 0x72, 0xe3, 0x1e, 0xc9, 0x12, 0xee);
	public const Guid PPM_THERMALCONSTRAINT_GUID = .(0xa852c2c8, 0x1a4c, 0x423b, 0x8c, 0x2c, 0xf3, 0x0d, 0x82, 0x93, 0x1a, 0x88);
	public const Guid PPM_PERFMON_PERFSTATE_GUID = .(0x7fd18652, 0x0cfe, 0x40d2, 0xb0, 0xa1, 0x0b, 0x06, 0x6a, 0x87, 0x75, 0x9e);
	public const Guid PPM_THERMAL_POLICY_CHANGE_GUID = .(0x48f377b8, 0x6880, 0x4c7b, 0x8b, 0xdc, 0x38, 0x01, 0x76, 0xc6, 0x65, 0x4d);
	public const uint32 POWER_ACTION_QUERY_ALLOWED = 1;
	public const uint32 POWER_ACTION_UI_ALLOWED = 2;
	public const uint32 POWER_ACTION_OVERRIDE_APPS = 4;
	public const uint32 POWER_ACTION_HIBERBOOT = 8;
	public const uint32 POWER_ACTION_USER_NOTIFY = 16;
	public const uint32 POWER_ACTION_DOZE_TO_HIBERNATE = 32;
	public const uint32 POWER_ACTION_ACPI_CRITICAL = 16777216;
	public const uint32 POWER_ACTION_ACPI_USER_NOTIFY = 33554432;
	public const uint32 POWER_ACTION_DIRECTED_DRIPS = 67108864;
	public const uint32 POWER_ACTION_PSEUDO_TRANSITION = 134217728;
	public const uint32 POWER_ACTION_LIGHTEST_FIRST = 268435456;
	public const uint32 POWER_ACTION_LOCK_CONSOLE = 536870912;
	public const uint32 POWER_ACTION_DISABLE_WAKES = 1073741824;
	public const uint32 POWER_ACTION_CRITICAL = 2147483648;
	public const uint32 POWER_USER_NOTIFY_FORCED_SHUTDOWN = 32;
	public const uint32 BATTERY_DISCHARGE_FLAGS_EVENTCODE_MASK = 7;
	public const uint32 BATTERY_DISCHARGE_FLAGS_ENABLE = 2147483648;
	public const uint32 NUM_DISCHARGE_POLICIES = 4;
	public const uint32 DISCHARGE_POLICY_CRITICAL = 0;
	public const uint32 DISCHARGE_POLICY_LOW = 1;
	public const uint32 PROCESSOR_IDLESTATE_POLICY_COUNT = 3;
	public const uint32 PO_THROTTLE_NONE = 0;
	public const uint32 PO_THROTTLE_CONSTANT = 1;
	public const uint32 PO_THROTTLE_DEGRADE = 2;
	public const uint32 PO_THROTTLE_ADAPTIVE = 3;
	public const uint32 PO_THROTTLE_MAXIMUM = 4;
	public const uint32 HIBERFILE_TYPE_NONE = 0;
	public const uint32 HIBERFILE_TYPE_REDUCED = 1;
	public const uint32 HIBERFILE_TYPE_FULL = 2;
	public const uint32 HIBERFILE_TYPE_MAX = 3;
	public const uint16 IMAGE_DOS_SIGNATURE = 23117;
	public const uint16 IMAGE_OS2_SIGNATURE = 17742;
	public const uint16 IMAGE_OS2_SIGNATURE_LE = 17740;
	public const uint16 IMAGE_VXD_SIGNATURE = 17740;
	public const uint32 IMAGE_NT_SIGNATURE = 17744;
	public const uint32 IMAGE_SIZEOF_FILE_HEADER = 20;
	public const uint32 IMAGE_NUMBEROF_DIRECTORY_ENTRIES = 16;
	public const uint32 IMAGE_SIZEOF_SHORT_NAME = 8;
	public const uint32 IMAGE_SIZEOF_SECTION_HEADER = 40;
	public const uint32 IMAGE_SIZEOF_SYMBOL = 18;
	public const uint32 IMAGE_SYM_SECTION_MAX = 65279;
	public const uint32 IMAGE_SYM_SECTION_MAX_EX = 2147483647;
	public const uint32 IMAGE_SYM_TYPE_NULL = 0;
	public const uint32 IMAGE_SYM_TYPE_VOID = 1;
	public const uint32 IMAGE_SYM_TYPE_CHAR = 2;
	public const uint32 IMAGE_SYM_TYPE_SHORT = 3;
	public const uint32 IMAGE_SYM_TYPE_INT = 4;
	public const uint32 IMAGE_SYM_TYPE_LONG = 5;
	public const uint32 IMAGE_SYM_TYPE_FLOAT = 6;
	public const uint32 IMAGE_SYM_TYPE_DOUBLE = 7;
	public const uint32 IMAGE_SYM_TYPE_STRUCT = 8;
	public const uint32 IMAGE_SYM_TYPE_UNION = 9;
	public const uint32 IMAGE_SYM_TYPE_ENUM = 10;
	public const uint32 IMAGE_SYM_TYPE_MOE = 11;
	public const uint32 IMAGE_SYM_TYPE_BYTE = 12;
	public const uint32 IMAGE_SYM_TYPE_WORD = 13;
	public const uint32 IMAGE_SYM_TYPE_UINT = 14;
	public const uint32 IMAGE_SYM_TYPE_DWORD = 15;
	public const uint32 IMAGE_SYM_TYPE_PCODE = 32768;
	public const uint32 IMAGE_SYM_DTYPE_NULL = 0;
	public const uint32 IMAGE_SYM_DTYPE_POINTER = 1;
	public const uint32 IMAGE_SYM_DTYPE_FUNCTION = 2;
	public const uint32 IMAGE_SYM_DTYPE_ARRAY = 3;
	public const uint32 IMAGE_SYM_CLASS_NULL = 0;
	public const uint32 IMAGE_SYM_CLASS_AUTOMATIC = 1;
	public const uint32 IMAGE_SYM_CLASS_EXTERNAL = 2;
	public const uint32 IMAGE_SYM_CLASS_STATIC = 3;
	public const uint32 IMAGE_SYM_CLASS_REGISTER = 4;
	public const uint32 IMAGE_SYM_CLASS_EXTERNAL_DEF = 5;
	public const uint32 IMAGE_SYM_CLASS_LABEL = 6;
	public const uint32 IMAGE_SYM_CLASS_UNDEFINED_LABEL = 7;
	public const uint32 IMAGE_SYM_CLASS_MEMBER_OF_STRUCT = 8;
	public const uint32 IMAGE_SYM_CLASS_ARGUMENT = 9;
	public const uint32 IMAGE_SYM_CLASS_STRUCT_TAG = 10;
	public const uint32 IMAGE_SYM_CLASS_MEMBER_OF_UNION = 11;
	public const uint32 IMAGE_SYM_CLASS_UNION_TAG = 12;
	public const uint32 IMAGE_SYM_CLASS_TYPE_DEFINITION = 13;
	public const uint32 IMAGE_SYM_CLASS_UNDEFINED_STATIC = 14;
	public const uint32 IMAGE_SYM_CLASS_ENUM_TAG = 15;
	public const uint32 IMAGE_SYM_CLASS_MEMBER_OF_ENUM = 16;
	public const uint32 IMAGE_SYM_CLASS_REGISTER_PARAM = 17;
	public const uint32 IMAGE_SYM_CLASS_BIT_FIELD = 18;
	public const uint32 IMAGE_SYM_CLASS_FAR_EXTERNAL = 68;
	public const uint32 IMAGE_SYM_CLASS_BLOCK = 100;
	public const uint32 IMAGE_SYM_CLASS_FUNCTION = 101;
	public const uint32 IMAGE_SYM_CLASS_END_OF_STRUCT = 102;
	public const uint32 IMAGE_SYM_CLASS_FILE = 103;
	public const uint32 IMAGE_SYM_CLASS_SECTION = 104;
	public const uint32 IMAGE_SYM_CLASS_WEAK_EXTERNAL = 105;
	public const uint32 IMAGE_SYM_CLASS_CLR_TOKEN = 107;
	public const uint32 N_BTMASK = 15;
	public const uint32 N_TMASK = 48;
	public const uint32 N_TMASK1 = 192;
	public const uint32 N_TMASK2 = 240;
	public const uint32 N_BTSHFT = 4;
	public const uint32 N_TSHIFT = 2;
	public const uint32 IMAGE_COMDAT_SELECT_NODUPLICATES = 1;
	public const uint32 IMAGE_COMDAT_SELECT_ANY = 2;
	public const uint32 IMAGE_COMDAT_SELECT_SAME_SIZE = 3;
	public const uint32 IMAGE_COMDAT_SELECT_EXACT_MATCH = 4;
	public const uint32 IMAGE_COMDAT_SELECT_ASSOCIATIVE = 5;
	public const uint32 IMAGE_COMDAT_SELECT_LARGEST = 6;
	public const uint32 IMAGE_COMDAT_SELECT_NEWEST = 7;
	public const uint32 IMAGE_WEAK_EXTERN_SEARCH_NOLIBRARY = 1;
	public const uint32 IMAGE_WEAK_EXTERN_SEARCH_LIBRARY = 2;
	public const uint32 IMAGE_WEAK_EXTERN_SEARCH_ALIAS = 3;
	public const uint32 IMAGE_WEAK_EXTERN_ANTI_DEPENDENCY = 4;
	public const uint32 IMAGE_REL_I386_ABSOLUTE = 0;
	public const uint32 IMAGE_REL_I386_DIR16 = 1;
	public const uint32 IMAGE_REL_I386_REL16 = 2;
	public const uint32 IMAGE_REL_I386_DIR32 = 6;
	public const uint32 IMAGE_REL_I386_DIR32NB = 7;
	public const uint32 IMAGE_REL_I386_SEG12 = 9;
	public const uint32 IMAGE_REL_I386_SECTION = 10;
	public const uint32 IMAGE_REL_I386_SECREL = 11;
	public const uint32 IMAGE_REL_I386_TOKEN = 12;
	public const uint32 IMAGE_REL_I386_SECREL7 = 13;
	public const uint32 IMAGE_REL_I386_REL32 = 20;
	public const uint32 IMAGE_REL_MIPS_ABSOLUTE = 0;
	public const uint32 IMAGE_REL_MIPS_REFHALF = 1;
	public const uint32 IMAGE_REL_MIPS_REFWORD = 2;
	public const uint32 IMAGE_REL_MIPS_JMPADDR = 3;
	public const uint32 IMAGE_REL_MIPS_REFHI = 4;
	public const uint32 IMAGE_REL_MIPS_REFLO = 5;
	public const uint32 IMAGE_REL_MIPS_GPREL = 6;
	public const uint32 IMAGE_REL_MIPS_LITERAL = 7;
	public const uint32 IMAGE_REL_MIPS_SECTION = 10;
	public const uint32 IMAGE_REL_MIPS_SECREL = 11;
	public const uint32 IMAGE_REL_MIPS_SECRELLO = 12;
	public const uint32 IMAGE_REL_MIPS_SECRELHI = 13;
	public const uint32 IMAGE_REL_MIPS_TOKEN = 14;
	public const uint32 IMAGE_REL_MIPS_JMPADDR16 = 16;
	public const uint32 IMAGE_REL_MIPS_REFWORDNB = 34;
	public const uint32 IMAGE_REL_MIPS_PAIR = 37;
	public const uint32 IMAGE_REL_ALPHA_ABSOLUTE = 0;
	public const uint32 IMAGE_REL_ALPHA_REFLONG = 1;
	public const uint32 IMAGE_REL_ALPHA_REFQUAD = 2;
	public const uint32 IMAGE_REL_ALPHA_GPREL32 = 3;
	public const uint32 IMAGE_REL_ALPHA_LITERAL = 4;
	public const uint32 IMAGE_REL_ALPHA_LITUSE = 5;
	public const uint32 IMAGE_REL_ALPHA_GPDISP = 6;
	public const uint32 IMAGE_REL_ALPHA_BRADDR = 7;
	public const uint32 IMAGE_REL_ALPHA_HINT = 8;
	public const uint32 IMAGE_REL_ALPHA_INLINE_REFLONG = 9;
	public const uint32 IMAGE_REL_ALPHA_REFHI = 10;
	public const uint32 IMAGE_REL_ALPHA_REFLO = 11;
	public const uint32 IMAGE_REL_ALPHA_PAIR = 12;
	public const uint32 IMAGE_REL_ALPHA_MATCH = 13;
	public const uint32 IMAGE_REL_ALPHA_SECTION = 14;
	public const uint32 IMAGE_REL_ALPHA_SECREL = 15;
	public const uint32 IMAGE_REL_ALPHA_REFLONGNB = 16;
	public const uint32 IMAGE_REL_ALPHA_SECRELLO = 17;
	public const uint32 IMAGE_REL_ALPHA_SECRELHI = 18;
	public const uint32 IMAGE_REL_ALPHA_REFQ3 = 19;
	public const uint32 IMAGE_REL_ALPHA_REFQ2 = 20;
	public const uint32 IMAGE_REL_ALPHA_REFQ1 = 21;
	public const uint32 IMAGE_REL_ALPHA_GPRELLO = 22;
	public const uint32 IMAGE_REL_ALPHA_GPRELHI = 23;
	public const uint32 IMAGE_REL_PPC_ABSOLUTE = 0;
	public const uint32 IMAGE_REL_PPC_ADDR64 = 1;
	public const uint32 IMAGE_REL_PPC_ADDR32 = 2;
	public const uint32 IMAGE_REL_PPC_ADDR24 = 3;
	public const uint32 IMAGE_REL_PPC_ADDR16 = 4;
	public const uint32 IMAGE_REL_PPC_ADDR14 = 5;
	public const uint32 IMAGE_REL_PPC_REL24 = 6;
	public const uint32 IMAGE_REL_PPC_REL14 = 7;
	public const uint32 IMAGE_REL_PPC_TOCREL16 = 8;
	public const uint32 IMAGE_REL_PPC_TOCREL14 = 9;
	public const uint32 IMAGE_REL_PPC_ADDR32NB = 10;
	public const uint32 IMAGE_REL_PPC_SECREL = 11;
	public const uint32 IMAGE_REL_PPC_SECTION = 12;
	public const uint32 IMAGE_REL_PPC_IFGLUE = 13;
	public const uint32 IMAGE_REL_PPC_IMGLUE = 14;
	public const uint32 IMAGE_REL_PPC_SECREL16 = 15;
	public const uint32 IMAGE_REL_PPC_REFHI = 16;
	public const uint32 IMAGE_REL_PPC_REFLO = 17;
	public const uint32 IMAGE_REL_PPC_PAIR = 18;
	public const uint32 IMAGE_REL_PPC_SECRELLO = 19;
	public const uint32 IMAGE_REL_PPC_SECRELHI = 20;
	public const uint32 IMAGE_REL_PPC_GPREL = 21;
	public const uint32 IMAGE_REL_PPC_TOKEN = 22;
	public const uint32 IMAGE_REL_PPC_TYPEMASK = 255;
	public const uint32 IMAGE_REL_PPC_NEG = 256;
	public const uint32 IMAGE_REL_PPC_BRTAKEN = 512;
	public const uint32 IMAGE_REL_PPC_BRNTAKEN = 1024;
	public const uint32 IMAGE_REL_PPC_TOCDEFN = 2048;
	public const uint32 IMAGE_REL_SH3_ABSOLUTE = 0;
	public const uint32 IMAGE_REL_SH3_DIRECT16 = 1;
	public const uint32 IMAGE_REL_SH3_DIRECT32 = 2;
	public const uint32 IMAGE_REL_SH3_DIRECT8 = 3;
	public const uint32 IMAGE_REL_SH3_DIRECT8_WORD = 4;
	public const uint32 IMAGE_REL_SH3_DIRECT8_LONG = 5;
	public const uint32 IMAGE_REL_SH3_DIRECT4 = 6;
	public const uint32 IMAGE_REL_SH3_DIRECT4_WORD = 7;
	public const uint32 IMAGE_REL_SH3_DIRECT4_LONG = 8;
	public const uint32 IMAGE_REL_SH3_PCREL8_WORD = 9;
	public const uint32 IMAGE_REL_SH3_PCREL8_LONG = 10;
	public const uint32 IMAGE_REL_SH3_PCREL12_WORD = 11;
	public const uint32 IMAGE_REL_SH3_STARTOF_SECTION = 12;
	public const uint32 IMAGE_REL_SH3_SIZEOF_SECTION = 13;
	public const uint32 IMAGE_REL_SH3_SECTION = 14;
	public const uint32 IMAGE_REL_SH3_SECREL = 15;
	public const uint32 IMAGE_REL_SH3_DIRECT32_NB = 16;
	public const uint32 IMAGE_REL_SH3_GPREL4_LONG = 17;
	public const uint32 IMAGE_REL_SH3_TOKEN = 18;
	public const uint32 IMAGE_REL_SHM_PCRELPT = 19;
	public const uint32 IMAGE_REL_SHM_REFLO = 20;
	public const uint32 IMAGE_REL_SHM_REFHALF = 21;
	public const uint32 IMAGE_REL_SHM_RELLO = 22;
	public const uint32 IMAGE_REL_SHM_RELHALF = 23;
	public const uint32 IMAGE_REL_SHM_PAIR = 24;
	public const uint32 IMAGE_REL_SH_NOMODE = 32768;
	public const uint32 IMAGE_REL_ARM_ABSOLUTE = 0;
	public const uint32 IMAGE_REL_ARM_ADDR32 = 1;
	public const uint32 IMAGE_REL_ARM_ADDR32NB = 2;
	public const uint32 IMAGE_REL_ARM_BRANCH24 = 3;
	public const uint32 IMAGE_REL_ARM_BRANCH11 = 4;
	public const uint32 IMAGE_REL_ARM_TOKEN = 5;
	public const uint32 IMAGE_REL_ARM_GPREL12 = 6;
	public const uint32 IMAGE_REL_ARM_GPREL7 = 7;
	public const uint32 IMAGE_REL_ARM_BLX24 = 8;
	public const uint32 IMAGE_REL_ARM_BLX11 = 9;
	public const uint32 IMAGE_REL_ARM_SECTION = 14;
	public const uint32 IMAGE_REL_ARM_SECREL = 15;
	public const uint32 IMAGE_REL_ARM_MOV32A = 16;
	public const uint32 IMAGE_REL_ARM_MOV32 = 16;
	public const uint32 IMAGE_REL_ARM_MOV32T = 17;
	public const uint32 IMAGE_REL_THUMB_MOV32 = 17;
	public const uint32 IMAGE_REL_ARM_BRANCH20T = 18;
	public const uint32 IMAGE_REL_THUMB_BRANCH20 = 18;
	public const uint32 IMAGE_REL_ARM_BRANCH24T = 20;
	public const uint32 IMAGE_REL_THUMB_BRANCH24 = 20;
	public const uint32 IMAGE_REL_ARM_BLX23T = 21;
	public const uint32 IMAGE_REL_THUMB_BLX23 = 21;
	public const uint32 IMAGE_REL_AM_ABSOLUTE = 0;
	public const uint32 IMAGE_REL_AM_ADDR32 = 1;
	public const uint32 IMAGE_REL_AM_ADDR32NB = 2;
	public const uint32 IMAGE_REL_AM_CALL32 = 3;
	public const uint32 IMAGE_REL_AM_FUNCINFO = 4;
	public const uint32 IMAGE_REL_AM_REL32_1 = 5;
	public const uint32 IMAGE_REL_AM_REL32_2 = 6;
	public const uint32 IMAGE_REL_AM_SECREL = 7;
	public const uint32 IMAGE_REL_AM_SECTION = 8;
	public const uint32 IMAGE_REL_AM_TOKEN = 9;
	public const uint32 IMAGE_REL_ARM64_ABSOLUTE = 0;
	public const uint32 IMAGE_REL_ARM64_ADDR32 = 1;
	public const uint32 IMAGE_REL_ARM64_ADDR32NB = 2;
	public const uint32 IMAGE_REL_ARM64_BRANCH26 = 3;
	public const uint32 IMAGE_REL_ARM64_PAGEBASE_REL21 = 4;
	public const uint32 IMAGE_REL_ARM64_REL21 = 5;
	public const uint32 IMAGE_REL_ARM64_PAGEOFFSET_12A = 6;
	public const uint32 IMAGE_REL_ARM64_PAGEOFFSET_12L = 7;
	public const uint32 IMAGE_REL_ARM64_SECREL = 8;
	public const uint32 IMAGE_REL_ARM64_SECREL_LOW12A = 9;
	public const uint32 IMAGE_REL_ARM64_SECREL_HIGH12A = 10;
	public const uint32 IMAGE_REL_ARM64_SECREL_LOW12L = 11;
	public const uint32 IMAGE_REL_ARM64_TOKEN = 12;
	public const uint32 IMAGE_REL_ARM64_SECTION = 13;
	public const uint32 IMAGE_REL_ARM64_ADDR64 = 14;
	public const uint32 IMAGE_REL_ARM64_BRANCH19 = 15;
	public const uint32 IMAGE_REL_AMD64_ABSOLUTE = 0;
	public const uint32 IMAGE_REL_AMD64_ADDR64 = 1;
	public const uint32 IMAGE_REL_AMD64_ADDR32 = 2;
	public const uint32 IMAGE_REL_AMD64_ADDR32NB = 3;
	public const uint32 IMAGE_REL_AMD64_REL32 = 4;
	public const uint32 IMAGE_REL_AMD64_REL32_1 = 5;
	public const uint32 IMAGE_REL_AMD64_REL32_2 = 6;
	public const uint32 IMAGE_REL_AMD64_REL32_3 = 7;
	public const uint32 IMAGE_REL_AMD64_REL32_4 = 8;
	public const uint32 IMAGE_REL_AMD64_REL32_5 = 9;
	public const uint32 IMAGE_REL_AMD64_SECTION = 10;
	public const uint32 IMAGE_REL_AMD64_SECREL = 11;
	public const uint32 IMAGE_REL_AMD64_SECREL7 = 12;
	public const uint32 IMAGE_REL_AMD64_TOKEN = 13;
	public const uint32 IMAGE_REL_AMD64_SREL32 = 14;
	public const uint32 IMAGE_REL_AMD64_PAIR = 15;
	public const uint32 IMAGE_REL_AMD64_SSPAN32 = 16;
	public const uint32 IMAGE_REL_AMD64_EHANDLER = 17;
	public const uint32 IMAGE_REL_AMD64_IMPORT_BR = 18;
	public const uint32 IMAGE_REL_AMD64_IMPORT_CALL = 19;
	public const uint32 IMAGE_REL_AMD64_CFG_BR = 20;
	public const uint32 IMAGE_REL_AMD64_CFG_BR_REX = 21;
	public const uint32 IMAGE_REL_AMD64_CFG_CALL = 22;
	public const uint32 IMAGE_REL_AMD64_INDIR_BR = 23;
	public const uint32 IMAGE_REL_AMD64_INDIR_BR_REX = 24;
	public const uint32 IMAGE_REL_AMD64_INDIR_CALL = 25;
	public const uint32 IMAGE_REL_AMD64_INDIR_BR_SWITCHTABLE_FIRST = 32;
	public const uint32 IMAGE_REL_AMD64_INDIR_BR_SWITCHTABLE_LAST = 47;
	public const uint32 IMAGE_REL_IA64_ABSOLUTE = 0;
	public const uint32 IMAGE_REL_IA64_IMM14 = 1;
	public const uint32 IMAGE_REL_IA64_IMM22 = 2;
	public const uint32 IMAGE_REL_IA64_IMM64 = 3;
	public const uint32 IMAGE_REL_IA64_DIR32 = 4;
	public const uint32 IMAGE_REL_IA64_DIR64 = 5;
	public const uint32 IMAGE_REL_IA64_PCREL21B = 6;
	public const uint32 IMAGE_REL_IA64_PCREL21M = 7;
	public const uint32 IMAGE_REL_IA64_PCREL21F = 8;
	public const uint32 IMAGE_REL_IA64_GPREL22 = 9;
	public const uint32 IMAGE_REL_IA64_LTOFF22 = 10;
	public const uint32 IMAGE_REL_IA64_SECTION = 11;
	public const uint32 IMAGE_REL_IA64_SECREL22 = 12;
	public const uint32 IMAGE_REL_IA64_SECREL64I = 13;
	public const uint32 IMAGE_REL_IA64_SECREL32 = 14;
	public const uint32 IMAGE_REL_IA64_DIR32NB = 16;
	public const uint32 IMAGE_REL_IA64_SREL14 = 17;
	public const uint32 IMAGE_REL_IA64_SREL22 = 18;
	public const uint32 IMAGE_REL_IA64_SREL32 = 19;
	public const uint32 IMAGE_REL_IA64_UREL32 = 20;
	public const uint32 IMAGE_REL_IA64_PCREL60X = 21;
	public const uint32 IMAGE_REL_IA64_PCREL60B = 22;
	public const uint32 IMAGE_REL_IA64_PCREL60F = 23;
	public const uint32 IMAGE_REL_IA64_PCREL60I = 24;
	public const uint32 IMAGE_REL_IA64_PCREL60M = 25;
	public const uint32 IMAGE_REL_IA64_IMMGPREL64 = 26;
	public const uint32 IMAGE_REL_IA64_TOKEN = 27;
	public const uint32 IMAGE_REL_IA64_GPREL32 = 28;
	public const uint32 IMAGE_REL_IA64_ADDEND = 31;
	public const uint32 IMAGE_REL_CEF_ABSOLUTE = 0;
	public const uint32 IMAGE_REL_CEF_ADDR32 = 1;
	public const uint32 IMAGE_REL_CEF_ADDR64 = 2;
	public const uint32 IMAGE_REL_CEF_ADDR32NB = 3;
	public const uint32 IMAGE_REL_CEF_SECTION = 4;
	public const uint32 IMAGE_REL_CEF_SECREL = 5;
	public const uint32 IMAGE_REL_CEF_TOKEN = 6;
	public const uint32 IMAGE_REL_CEE_ABSOLUTE = 0;
	public const uint32 IMAGE_REL_CEE_ADDR32 = 1;
	public const uint32 IMAGE_REL_CEE_ADDR64 = 2;
	public const uint32 IMAGE_REL_CEE_ADDR32NB = 3;
	public const uint32 IMAGE_REL_CEE_SECTION = 4;
	public const uint32 IMAGE_REL_CEE_SECREL = 5;
	public const uint32 IMAGE_REL_CEE_TOKEN = 6;
	public const uint32 IMAGE_REL_M32R_ABSOLUTE = 0;
	public const uint32 IMAGE_REL_M32R_ADDR32 = 1;
	public const uint32 IMAGE_REL_M32R_ADDR32NB = 2;
	public const uint32 IMAGE_REL_M32R_ADDR24 = 3;
	public const uint32 IMAGE_REL_M32R_GPREL16 = 4;
	public const uint32 IMAGE_REL_M32R_PCREL24 = 5;
	public const uint32 IMAGE_REL_M32R_PCREL16 = 6;
	public const uint32 IMAGE_REL_M32R_PCREL8 = 7;
	public const uint32 IMAGE_REL_M32R_REFHALF = 8;
	public const uint32 IMAGE_REL_M32R_REFHI = 9;
	public const uint32 IMAGE_REL_M32R_REFLO = 10;
	public const uint32 IMAGE_REL_M32R_PAIR = 11;
	public const uint32 IMAGE_REL_M32R_SECTION = 12;
	public const uint32 IMAGE_REL_M32R_SECREL32 = 13;
	public const uint32 IMAGE_REL_M32R_TOKEN = 14;
	public const uint32 IMAGE_REL_EBC_ABSOLUTE = 0;
	public const uint32 IMAGE_REL_EBC_ADDR32NB = 1;
	public const uint32 IMAGE_REL_EBC_REL32 = 2;
	public const uint32 IMAGE_REL_EBC_SECTION = 3;
	public const uint32 IMAGE_REL_EBC_SECREL = 4;
	public const uint32 EMARCH_ENC_I17_IMM7B_INST_WORD_X = 3;
	public const uint32 EMARCH_ENC_I17_IMM7B_SIZE_X = 7;
	public const uint32 EMARCH_ENC_I17_IMM7B_INST_WORD_POS_X = 4;
	public const uint32 EMARCH_ENC_I17_IMM7B_VAL_POS_X = 0;
	public const uint32 EMARCH_ENC_I17_IMM9D_INST_WORD_X = 3;
	public const uint32 EMARCH_ENC_I17_IMM9D_SIZE_X = 9;
	public const uint32 EMARCH_ENC_I17_IMM9D_INST_WORD_POS_X = 18;
	public const uint32 EMARCH_ENC_I17_IMM9D_VAL_POS_X = 7;
	public const uint32 EMARCH_ENC_I17_IMM5C_INST_WORD_X = 3;
	public const uint32 EMARCH_ENC_I17_IMM5C_SIZE_X = 5;
	public const uint32 EMARCH_ENC_I17_IMM5C_INST_WORD_POS_X = 13;
	public const uint32 EMARCH_ENC_I17_IMM5C_VAL_POS_X = 16;
	public const uint32 EMARCH_ENC_I17_IC_INST_WORD_X = 3;
	public const uint32 EMARCH_ENC_I17_IC_SIZE_X = 1;
	public const uint32 EMARCH_ENC_I17_IC_INST_WORD_POS_X = 12;
	public const uint32 EMARCH_ENC_I17_IC_VAL_POS_X = 21;
	public const uint32 EMARCH_ENC_I17_IMM41a_INST_WORD_X = 1;
	public const uint32 EMARCH_ENC_I17_IMM41a_SIZE_X = 10;
	public const uint32 EMARCH_ENC_I17_IMM41a_INST_WORD_POS_X = 14;
	public const uint32 EMARCH_ENC_I17_IMM41a_VAL_POS_X = 22;
	public const uint32 EMARCH_ENC_I17_IMM41b_INST_WORD_X = 1;
	public const uint32 EMARCH_ENC_I17_IMM41b_SIZE_X = 8;
	public const uint32 EMARCH_ENC_I17_IMM41b_INST_WORD_POS_X = 24;
	public const uint32 EMARCH_ENC_I17_IMM41b_VAL_POS_X = 32;
	public const uint32 EMARCH_ENC_I17_IMM41c_INST_WORD_X = 2;
	public const uint32 EMARCH_ENC_I17_IMM41c_SIZE_X = 23;
	public const uint32 EMARCH_ENC_I17_IMM41c_INST_WORD_POS_X = 0;
	public const uint32 EMARCH_ENC_I17_IMM41c_VAL_POS_X = 40;
	public const uint32 EMARCH_ENC_I17_SIGN_INST_WORD_X = 3;
	public const uint32 EMARCH_ENC_I17_SIGN_SIZE_X = 1;
	public const uint32 EMARCH_ENC_I17_SIGN_INST_WORD_POS_X = 27;
	public const uint32 EMARCH_ENC_I17_SIGN_VAL_POS_X = 63;
	public const uint32 X3_OPCODE_INST_WORD_X = 3;
	public const uint32 X3_OPCODE_SIZE_X = 4;
	public const uint32 X3_OPCODE_INST_WORD_POS_X = 28;
	public const uint32 X3_OPCODE_SIGN_VAL_POS_X = 0;
	public const uint32 X3_I_INST_WORD_X = 3;
	public const uint32 X3_I_SIZE_X = 1;
	public const uint32 X3_I_INST_WORD_POS_X = 27;
	public const uint32 X3_I_SIGN_VAL_POS_X = 59;
	public const uint32 X3_D_WH_INST_WORD_X = 3;
	public const uint32 X3_D_WH_SIZE_X = 3;
	public const uint32 X3_D_WH_INST_WORD_POS_X = 24;
	public const uint32 X3_D_WH_SIGN_VAL_POS_X = 0;
	public const uint32 X3_IMM20_INST_WORD_X = 3;
	public const uint32 X3_IMM20_SIZE_X = 20;
	public const uint32 X3_IMM20_INST_WORD_POS_X = 4;
	public const uint32 X3_IMM20_SIGN_VAL_POS_X = 0;
	public const uint32 X3_IMM39_1_INST_WORD_X = 2;
	public const uint32 X3_IMM39_1_SIZE_X = 23;
	public const uint32 X3_IMM39_1_INST_WORD_POS_X = 0;
	public const uint32 X3_IMM39_1_SIGN_VAL_POS_X = 36;
	public const uint32 X3_IMM39_2_INST_WORD_X = 1;
	public const uint32 X3_IMM39_2_SIZE_X = 16;
	public const uint32 X3_IMM39_2_INST_WORD_POS_X = 16;
	public const uint32 X3_IMM39_2_SIGN_VAL_POS_X = 20;
	public const uint32 X3_P_INST_WORD_X = 3;
	public const uint32 X3_P_SIZE_X = 4;
	public const uint32 X3_P_INST_WORD_POS_X = 0;
	public const uint32 X3_P_SIGN_VAL_POS_X = 0;
	public const uint32 X3_TMPLT_INST_WORD_X = 0;
	public const uint32 X3_TMPLT_SIZE_X = 4;
	public const uint32 X3_TMPLT_INST_WORD_POS_X = 0;
	public const uint32 X3_TMPLT_SIGN_VAL_POS_X = 0;
	public const uint32 X3_BTYPE_QP_INST_WORD_X = 2;
	public const uint32 X3_BTYPE_QP_SIZE_X = 9;
	public const uint32 X3_BTYPE_QP_INST_WORD_POS_X = 23;
	public const uint32 X3_BTYPE_QP_INST_VAL_POS_X = 0;
	public const uint32 X3_EMPTY_INST_WORD_X = 1;
	public const uint32 X3_EMPTY_SIZE_X = 2;
	public const uint32 X3_EMPTY_INST_WORD_POS_X = 14;
	public const uint32 X3_EMPTY_INST_VAL_POS_X = 0;
	public const uint32 IMAGE_REL_BASED_ABSOLUTE = 0;
	public const uint32 IMAGE_REL_BASED_HIGH = 1;
	public const uint32 IMAGE_REL_BASED_LOW = 2;
	public const uint32 IMAGE_REL_BASED_HIGHLOW = 3;
	public const uint32 IMAGE_REL_BASED_HIGHADJ = 4;
	public const uint32 IMAGE_REL_BASED_MACHINE_SPECIFIC_5 = 5;
	public const uint32 IMAGE_REL_BASED_RESERVED = 6;
	public const uint32 IMAGE_REL_BASED_MACHINE_SPECIFIC_7 = 7;
	public const uint32 IMAGE_REL_BASED_MACHINE_SPECIFIC_8 = 8;
	public const uint32 IMAGE_REL_BASED_MACHINE_SPECIFIC_9 = 9;
	public const uint32 IMAGE_REL_BASED_DIR64 = 10;
	public const uint32 IMAGE_REL_BASED_IA64_IMM64 = 9;
	public const uint32 IMAGE_REL_BASED_MIPS_JMPADDR = 5;
	public const uint32 IMAGE_REL_BASED_MIPS_JMPADDR16 = 9;
	public const uint32 IMAGE_REL_BASED_ARM_MOV32 = 5;
	public const uint32 IMAGE_REL_BASED_THUMB_MOV32 = 7;
	public const uint32 IMAGE_ARCHIVE_START_SIZE = 8;
	public const String IMAGE_ARCHIVE_START = "!<arch>\n";
	public const String IMAGE_ARCHIVE_END = "`\n";
	public const String IMAGE_ARCHIVE_PAD = "\n";
	public const String IMAGE_ARCHIVE_LINKER_MEMBER = "/               ";
	public const String IMAGE_ARCHIVE_LONGNAMES_MEMBER = "//              ";
	public const String IMAGE_ARCHIVE_HYBRIDMAP_MEMBER = "/<HYBRIDMAP>/   ";
	public const uint32 IMAGE_SIZEOF_ARCHIVE_MEMBER_HDR = 60;
	public const uint64 IMAGE_ORDINAL_FLAG64 = 9223372036854775808;
	public const uint32 IMAGE_ORDINAL_FLAG32 = 2147483648;
	public const uint64 IMAGE_ORDINAL_FLAG = 9223372036854775808;
	public const uint32 IMAGE_RESOURCE_NAME_IS_STRING = 2147483648;
	public const uint32 IMAGE_RESOURCE_DATA_IS_DIRECTORY = 2147483648;
	public const uint32 IMAGE_DYNAMIC_RELOCATION_GUARD_RF_PROLOGUE = 1;
	public const uint32 IMAGE_DYNAMIC_RELOCATION_GUARD_RF_EPILOGUE = 2;
	public const uint32 IMAGE_DYNAMIC_RELOCATION_GUARD_IMPORT_CONTROL_TRANSFER = 3;
	public const uint32 IMAGE_DYNAMIC_RELOCATION_GUARD_INDIR_CONTROL_TRANSFER = 4;
	public const uint32 IMAGE_DYNAMIC_RELOCATION_GUARD_SWITCHTABLE_BRANCH = 5;
	public const uint32 IMAGE_HOT_PATCH_BASE_OBLIGATORY = 1;
	public const uint32 IMAGE_HOT_PATCH_BASE_CAN_ROLL_BACK = 2;
	public const uint32 IMAGE_HOT_PATCH_CHUNK_INVERSE = 2147483648;
	public const uint32 IMAGE_HOT_PATCH_CHUNK_OBLIGATORY = 1073741824;
	public const uint32 IMAGE_HOT_PATCH_CHUNK_RESERVED = 1072705536;
	public const uint32 IMAGE_HOT_PATCH_CHUNK_TYPE = 1032192;
	public const uint32 IMAGE_HOT_PATCH_CHUNK_SOURCE_RVA = 32768;
	public const uint32 IMAGE_HOT_PATCH_CHUNK_TARGET_RVA = 16384;
	public const uint32 IMAGE_HOT_PATCH_CHUNK_SIZE = 4095;
	public const uint32 IMAGE_HOT_PATCH_NONE = 0;
	public const uint32 IMAGE_HOT_PATCH_FUNCTION = 114688;
	public const uint32 IMAGE_HOT_PATCH_ABSOLUTE = 180224;
	public const uint32 IMAGE_HOT_PATCH_REL32 = 245760;
	public const uint32 IMAGE_HOT_PATCH_CALL_TARGET = 278528;
	public const uint32 IMAGE_HOT_PATCH_INDIRECT = 376832;
	public const uint32 IMAGE_HOT_PATCH_NO_CALL_TARGET = 409600;
	public const uint32 IMAGE_HOT_PATCH_DYNAMIC_VALUE = 491520;
	public const uint32 IMAGE_GUARD_CF_INSTRUMENTED = 256;
	public const uint32 IMAGE_GUARD_CFW_INSTRUMENTED = 512;
	public const uint32 IMAGE_GUARD_CF_FUNCTION_TABLE_PRESENT = 1024;
	public const uint32 IMAGE_GUARD_SECURITY_COOKIE_UNUSED = 2048;
	public const uint32 IMAGE_GUARD_PROTECT_DELAYLOAD_IAT = 4096;
	public const uint32 IMAGE_GUARD_DELAYLOAD_IAT_IN_ITS_OWN_SECTION = 8192;
	public const uint32 IMAGE_GUARD_CF_EXPORT_SUPPRESSION_INFO_PRESENT = 16384;
	public const uint32 IMAGE_GUARD_CF_ENABLE_EXPORT_SUPPRESSION = 32768;
	public const uint32 IMAGE_GUARD_CF_LONGJUMP_TABLE_PRESENT = 65536;
	public const uint32 IMAGE_GUARD_RF_INSTRUMENTED = 131072;
	public const uint32 IMAGE_GUARD_RF_ENABLE = 262144;
	public const uint32 IMAGE_GUARD_RF_STRICT = 524288;
	public const uint32 IMAGE_GUARD_RETPOLINE_PRESENT = 1048576;
	public const uint32 IMAGE_GUARD_EH_CONTINUATION_TABLE_PRESENT = 4194304;
	public const uint32 IMAGE_GUARD_XFG_ENABLED = 8388608;
	public const uint32 IMAGE_GUARD_CF_FUNCTION_TABLE_SIZE_MASK = 4026531840;
	public const uint32 IMAGE_GUARD_CF_FUNCTION_TABLE_SIZE_SHIFT = 28;
	public const uint32 IMAGE_GUARD_FLAG_FID_SUPPRESSED = 1;
	public const uint32 IMAGE_GUARD_FLAG_EXPORT_SUPPRESSED = 2;
	public const uint32 IMAGE_GUARD_FLAG_FID_LANGEXCPTHANDLER = 4;
	public const uint32 IMAGE_GUARD_FLAG_FID_XFG = 8;
	public const uint32 IMAGE_ENCLAVE_LONG_ID_LENGTH = 32;
	public const uint32 IMAGE_ENCLAVE_SHORT_ID_LENGTH = 16;
	public const uint32 IMAGE_ENCLAVE_POLICY_DEBUGGABLE = 1;
	public const uint32 IMAGE_ENCLAVE_FLAG_PRIMARY_IMAGE = 1;
	public const uint32 IMAGE_ENCLAVE_IMPORT_MATCH_NONE = 0;
	public const uint32 IMAGE_ENCLAVE_IMPORT_MATCH_UNIQUE_ID = 1;
	public const uint32 IMAGE_ENCLAVE_IMPORT_MATCH_AUTHOR_ID = 2;
	public const uint32 IMAGE_ENCLAVE_IMPORT_MATCH_FAMILY_ID = 3;
	public const uint32 IMAGE_ENCLAVE_IMPORT_MATCH_IMAGE_ID = 4;
	public const uint32 IMAGE_DEBUG_TYPE_OMAP_TO_SRC = 7;
	public const uint32 IMAGE_DEBUG_TYPE_OMAP_FROM_SRC = 8;
	public const uint32 IMAGE_DEBUG_TYPE_RESERVED10 = 10;
	public const uint32 IMAGE_DEBUG_TYPE_CLSID = 11;
	public const uint32 IMAGE_DEBUG_TYPE_VC_FEATURE = 12;
	public const uint32 IMAGE_DEBUG_TYPE_POGO = 13;
	public const uint32 IMAGE_DEBUG_TYPE_ILTCG = 14;
	public const uint32 IMAGE_DEBUG_TYPE_MPX = 15;
	public const uint32 IMAGE_DEBUG_TYPE_REPRO = 16;
	public const uint32 IMAGE_DEBUG_TYPE_EX_DLLCHARACTERISTICS = 20;
	public const uint32 FRAME_FPO = 0;
	public const uint32 FRAME_TRAP = 1;
	public const uint32 FRAME_TSS = 2;
	public const uint32 FRAME_NONFPO = 3;
	public const uint32 SIZEOF_RFPO_DATA = 16;
	public const uint32 IMAGE_DEBUG_MISC_EXENAME = 1;
	public const uint32 IMAGE_SEPARATE_DEBUG_SIGNATURE = 18756;
	public const uint32 NON_PAGED_DEBUG_SIGNATURE = 18766;
	public const uint32 IMAGE_SEPARATE_DEBUG_FLAGS_MASK = 32768;
	public const uint32 IMAGE_SEPARATE_DEBUG_MISMATCH = 32768;
	public const uint32 IMPORT_OBJECT_HDR_SIG2 = 65535;
	public const uint32 UNWIND_HISTORY_TABLE_SIZE = 12;
	public const uint32 RTL_RUN_ONCE_CHECK_ONLY = 1;
	public const uint32 RTL_RUN_ONCE_ASYNC = 2;
	public const uint32 RTL_RUN_ONCE_INIT_FAILED = 4;
	public const uint32 RTL_RUN_ONCE_CTX_RESERVED_BITS = 2;
	public const uint32 FAST_FAIL_LEGACY_GS_VIOLATION = 0;
	public const uint32 FAST_FAIL_VTGUARD_CHECK_FAILURE = 1;
	public const uint32 FAST_FAIL_STACK_COOKIE_CHECK_FAILURE = 2;
	public const uint32 FAST_FAIL_CORRUPT_LIST_ENTRY = 3;
	public const uint32 FAST_FAIL_INCORRECT_STACK = 4;
	public const uint32 FAST_FAIL_INVALID_ARG = 5;
	public const uint32 FAST_FAIL_GS_COOKIE_INIT = 6;
	public const uint32 FAST_FAIL_FATAL_APP_EXIT = 7;
	public const uint32 FAST_FAIL_RANGE_CHECK_FAILURE = 8;
	public const uint32 FAST_FAIL_UNSAFE_REGISTRY_ACCESS = 9;
	public const uint32 FAST_FAIL_GUARD_ICALL_CHECK_FAILURE = 10;
	public const uint32 FAST_FAIL_GUARD_WRITE_CHECK_FAILURE = 11;
	public const uint32 FAST_FAIL_INVALID_FIBER_SWITCH = 12;
	public const uint32 FAST_FAIL_INVALID_SET_OF_CONTEXT = 13;
	public const uint32 FAST_FAIL_INVALID_REFERENCE_COUNT = 14;
	public const uint32 FAST_FAIL_INVALID_JUMP_BUFFER = 18;
	public const uint32 FAST_FAIL_MRDATA_MODIFIED = 19;
	public const uint32 FAST_FAIL_CERTIFICATION_FAILURE = 20;
	public const uint32 FAST_FAIL_INVALID_EXCEPTION_CHAIN = 21;
	public const uint32 FAST_FAIL_CRYPTO_LIBRARY = 22;
	public const uint32 FAST_FAIL_INVALID_CALL_IN_DLL_CALLOUT = 23;
	public const uint32 FAST_FAIL_INVALID_IMAGE_BASE = 24;
	public const uint32 FAST_FAIL_DLOAD_PROTECTION_FAILURE = 25;
	public const uint32 FAST_FAIL_UNSAFE_EXTENSION_CALL = 26;
	public const uint32 FAST_FAIL_DEPRECATED_SERVICE_INVOKED = 27;
	public const uint32 FAST_FAIL_INVALID_BUFFER_ACCESS = 28;
	public const uint32 FAST_FAIL_INVALID_BALANCED_TREE = 29;
	public const uint32 FAST_FAIL_INVALID_NEXT_THREAD = 30;
	public const uint32 FAST_FAIL_GUARD_ICALL_CHECK_SUPPRESSED = 31;
	public const uint32 FAST_FAIL_APCS_DISABLED = 32;
	public const uint32 FAST_FAIL_INVALID_IDLE_STATE = 33;
	public const uint32 FAST_FAIL_MRDATA_PROTECTION_FAILURE = 34;
	public const uint32 FAST_FAIL_UNEXPECTED_HEAP_EXCEPTION = 35;
	public const uint32 FAST_FAIL_INVALID_LOCK_STATE = 36;
	public const uint32 FAST_FAIL_GUARD_JUMPTABLE = 37;
	public const uint32 FAST_FAIL_INVALID_LONGJUMP_TARGET = 38;
	public const uint32 FAST_FAIL_INVALID_DISPATCH_CONTEXT = 39;
	public const uint32 FAST_FAIL_INVALID_THREAD = 40;
	public const uint32 FAST_FAIL_INVALID_SYSCALL_NUMBER = 41;
	public const uint32 FAST_FAIL_INVALID_FILE_OPERATION = 42;
	public const uint32 FAST_FAIL_LPAC_ACCESS_DENIED = 43;
	public const uint32 FAST_FAIL_GUARD_SS_FAILURE = 44;
	public const uint32 FAST_FAIL_LOADER_CONTINUITY_FAILURE = 45;
	public const uint32 FAST_FAIL_GUARD_EXPORT_SUPPRESSION_FAILURE = 46;
	public const uint32 FAST_FAIL_INVALID_CONTROL_STACK = 47;
	public const uint32 FAST_FAIL_SET_CONTEXT_DENIED = 48;
	public const uint32 FAST_FAIL_INVALID_IAT = 49;
	public const uint32 FAST_FAIL_HEAP_METADATA_CORRUPTION = 50;
	public const uint32 FAST_FAIL_PAYLOAD_RESTRICTION_VIOLATION = 51;
	public const uint32 FAST_FAIL_LOW_LABEL_ACCESS_DENIED = 52;
	public const uint32 FAST_FAIL_ENCLAVE_CALL_FAILURE = 53;
	public const uint32 FAST_FAIL_UNHANDLED_LSS_EXCEPTON = 54;
	public const uint32 FAST_FAIL_ADMINLESS_ACCESS_DENIED = 55;
	public const uint32 FAST_FAIL_UNEXPECTED_CALL = 56;
	public const uint32 FAST_FAIL_CONTROL_INVALID_RETURN_ADDRESS = 57;
	public const uint32 FAST_FAIL_UNEXPECTED_HOST_BEHAVIOR = 58;
	public const uint32 FAST_FAIL_FLAGS_CORRUPTION = 59;
	public const uint32 FAST_FAIL_VEH_CORRUPTION = 60;
	public const uint32 FAST_FAIL_ETW_CORRUPTION = 61;
	public const uint32 FAST_FAIL_RIO_ABORT = 62;
	public const uint32 FAST_FAIL_INVALID_PFN = 63;
	public const uint32 FAST_FAIL_GUARD_ICALL_CHECK_FAILURE_XFG = 64;
	public const uint32 FAST_FAIL_CAST_GUARD = 65;
	public const uint32 FAST_FAIL_HOST_VISIBILITY_CHANGE = 66;
	public const uint32 FAST_FAIL_KERNEL_CET_SHADOW_STACK_ASSIST = 67;
	public const uint32 FAST_FAIL_PATCH_CALLBACK_FAILED = 68;
	public const uint32 FAST_FAIL_NTDLL_PATCH_FAILED = 69;
	public const uint32 FAST_FAIL_INVALID_FLS_DATA = 70;
	public const uint32 FAST_FAIL_INVALID_FAST_FAIL_CODE = 4294967295;
	public const uint32 IS_TEXT_UNICODE_DBCS_LEADBYTE = 1024;
	public const uint32 IS_TEXT_UNICODE_UTF8 = 2048;
	public const uint32 COMPRESSION_FORMAT_NONE = 0;
	public const uint32 COMPRESSION_FORMAT_DEFAULT = 1;
	public const uint32 COMPRESSION_FORMAT_LZNT1 = 2;
	public const uint32 COMPRESSION_FORMAT_XPRESS = 3;
	public const uint32 COMPRESSION_FORMAT_XPRESS_HUFF = 4;
	public const uint32 COMPRESSION_FORMAT_XP10 = 5;
	public const uint32 COMPRESSION_ENGINE_STANDARD = 0;
	public const uint32 COMPRESSION_ENGINE_MAXIMUM = 256;
	public const uint32 COMPRESSION_ENGINE_HIBER = 512;
	public const uint32 SEF_AI_USE_EXTRA_PARAMS = 2048;
	public const uint32 SEF_FORCE_USER_MODE = 8192;
	public const uint32 MESSAGE_RESOURCE_UNICODE = 1;
	public const uint32 MESSAGE_RESOURCE_UTF8 = 2;
	public const uint32 VER_EQUAL = 1;
	public const uint32 VER_GREATER = 2;
	public const uint32 VER_GREATER_EQUAL = 3;
	public const uint32 VER_LESS = 4;
	public const uint32 VER_LESS_EQUAL = 5;
	public const uint32 VER_AND = 6;
	public const uint32 VER_OR = 7;
	public const uint32 VER_CONDITION_MASK = 7;
	public const uint32 VER_NUM_BITS_PER_CONDITION_MASK = 3;
	public const uint32 VER_NT_WORKSTATION = 1;
	public const uint32 VER_NT_DOMAIN_CONTROLLER = 2;
	public const uint32 VER_NT_SERVER = 3;
	public const uint32 RTL_UMS_VERSION = 256;
	public const uint32 VRL_PREDEFINED_CLASS_BEGIN = 1;
	public const uint32 VRL_CUSTOM_CLASS_BEGIN = 256;
	public const uint32 VRL_ENABLE_KERNEL_BREAKS = 2147483648;
	public const uint32 CTMF_INCLUDE_APPCONTAINER = 1;
	public const uint32 CTMF_INCLUDE_LPAC = 2;
	public const uint32 FLUSH_NV_MEMORY_IN_FLAG_NO_DRAIN = 1;
	public const uint32 WRITE_NV_MEMORY_FLAG_FLUSH = 1;
	public const uint32 WRITE_NV_MEMORY_FLAG_NON_TEMPORAL = 2;
	public const uint32 WRITE_NV_MEMORY_FLAG_NO_DRAIN = 256;
	public const uint32 FILL_NV_MEMORY_FLAG_FLUSH = 1;
	public const uint32 FILL_NV_MEMORY_FLAG_NON_TEMPORAL = 2;
	public const uint32 FILL_NV_MEMORY_FLAG_NO_DRAIN = 256;
	public const uint32 IMAGE_POLICY_METADATA_VERSION = 1;
	public const String IMAGE_POLICY_SECTION_NAME = ".tPolicy";
	public const uint32 RTL_VIRTUAL_UNWIND2_VALIDATE_PAC = 1;
	public const uint32 RTL_CRITICAL_SECTION_FLAG_NO_DEBUG_INFO = 16777216;
	public const uint32 RTL_CRITICAL_SECTION_FLAG_DYNAMIC_SPIN = 33554432;
	public const uint32 RTL_CRITICAL_SECTION_FLAG_STATIC_INIT = 67108864;
	public const uint32 RTL_CRITICAL_SECTION_FLAG_RESOURCE_TYPE = 134217728;
	public const uint32 RTL_CRITICAL_SECTION_FLAG_FORCE_DEBUG_INFO = 268435456;
	public const uint32 RTL_CRITICAL_SECTION_ALL_FLAG_BITS = 4278190080;
	public const uint32 RTL_CRITICAL_SECTION_DEBUG_FLAG_STATIC_INIT = 1;
	public const uint32 RTL_CONDITION_VARIABLE_LOCKMODE_SHARED = 1;
	public const uint32 HEAP_OPTIMIZE_RESOURCES_CURRENT_VERSION = 1;
	public const uint32 WT_EXECUTEINUITHREAD = 2;
	public const uint32 WT_EXECUTEINPERSISTENTIOTHREAD = 64;
	public const uint32 WT_EXECUTEINLONGTHREAD = 16;
	public const uint32 WT_EXECUTEDELETEWAIT = 8;
	public const uint32 ACTIVATION_CONTEXT_PATH_TYPE_NONE = 1;
	public const uint32 ACTIVATION_CONTEXT_PATH_TYPE_WIN32_FILE = 2;
	public const uint32 ACTIVATION_CONTEXT_PATH_TYPE_URL = 3;
	public const uint32 ACTIVATION_CONTEXT_PATH_TYPE_ASSEMBLYREF = 4;
	public const uint32 CREATE_BOUNDARY_DESCRIPTOR_ADD_APPCONTAINER_SID = 1;
	public const uint32 PERFORMANCE_DATA_VERSION = 1;
	public const uint32 READ_THREAD_PROFILING_FLAG_DISPATCHING = 1;
	public const uint32 READ_THREAD_PROFILING_FLAG_HARDWARE_COUNTERS = 2;
	public const String UNIFIEDBUILDREVISION_KEY = "\\Registry\\Machine\\Software\\Microsoft\\Windows NT\\CurrentVersion";
	public const String UNIFIEDBUILDREVISION_VALUE = "UBR";
	public const uint32 UNIFIEDBUILDREVISION_MIN = 0;
	public const String DEVICEFAMILYDEVICEFORM_KEY = "\\Registry\\Machine\\Software\\Microsoft\\Windows NT\\CurrentVersion\\OEM";
	public const String DEVICEFAMILYDEVICEFORM_VALUE = "DeviceForm";
	public const uint32 DLL_PROCESS_ATTACH = 1;
	public const uint32 DLL_THREAD_ATTACH = 2;
	public const uint32 DLL_THREAD_DETACH = 3;
	public const uint32 DLL_PROCESS_DETACH = 0;
	public const uint32 EVENTLOG_FORWARDS_READ = 4;
	public const uint32 EVENTLOG_BACKWARDS_READ = 8;
	public const uint32 EVENTLOG_START_PAIRED_EVENT = 1;
	public const uint32 EVENTLOG_END_PAIRED_EVENT = 2;
	public const uint32 EVENTLOG_END_ALL_PAIRED_EVENTS = 4;
	public const uint32 EVENTLOG_PAIRED_EVENT_ACTIVE = 8;
	public const uint32 EVENTLOG_PAIRED_EVENT_INACTIVE = 16;
	public const uint32 MAXLOGICALLOGNAMESIZE = 256;
	public const int32 REG_REFRESH_HIVE = 2;
	public const int32 REG_NO_LAZY_FLUSH = 4;
	public const int32 REG_APP_HIVE = 16;
	public const int32 REG_PROCESS_PRIVATE = 32;
	public const int32 REG_START_JOURNAL = 64;
	public const int32 REG_HIVE_EXACT_FILE_GROWTH = 128;
	public const int32 REG_HIVE_NO_RM = 256;
	public const int32 REG_HIVE_SINGLE_LOG = 512;
	public const int32 REG_BOOT_HIVE = 1024;
	public const int32 REG_LOAD_HIVE_OPEN_HANDLE = 2048;
	public const int32 REG_FLUSH_HIVE_FILE_GROWTH = 4096;
	public const int32 REG_OPEN_READ_ONLY = 8192;
	public const int32 REG_IMMUTABLE = 16384;
	public const int32 REG_NO_IMPERSONATION_FALLBACK = 32768;
	public const int32 REG_APP_HIVE_OPEN_READ_ONLY = 8192;
	public const uint32 REG_FORCE_UNLOAD = 1;
	public const uint32 REG_UNLOAD_LEGAL_FLAGS = 1;
	public const uint32 SERVICE_USER_SERVICE = 64;
	public const uint32 SERVICE_USERSERVICE_INSTANCE = 128;
	public const uint32 SERVICE_INTERACTIVE_PROCESS = 256;
	public const uint32 SERVICE_PKG_SERVICE = 512;
	public const uint32 CM_SERVICE_NETWORK_BOOT_LOAD = 1;
	public const uint32 CM_SERVICE_VIRTUAL_DISK_BOOT_LOAD = 2;
	public const uint32 CM_SERVICE_USB_DISK_BOOT_LOAD = 4;
	public const uint32 CM_SERVICE_SD_DISK_BOOT_LOAD = 8;
	public const uint32 CM_SERVICE_USB3_DISK_BOOT_LOAD = 16;
	public const uint32 CM_SERVICE_MEASURED_BOOT_LOAD = 32;
	public const uint32 CM_SERVICE_VERIFIER_BOOT_LOAD = 64;
	public const uint32 CM_SERVICE_WINPE_BOOT_LOAD = 128;
	public const uint32 CM_SERVICE_RAM_DISK_BOOT_LOAD = 256;
	public const int32 TAPE_PSEUDO_LOGICAL_POSITION = 2;
	public const int32 TAPE_PSEUDO_LOGICAL_BLOCK = 3;
	public const uint32 TAPE_DRIVE_FIXED = 1;
	public const uint32 TAPE_DRIVE_SELECT = 2;
	public const uint32 TAPE_DRIVE_INITIATOR = 4;
	public const uint32 TAPE_DRIVE_ERASE_SHORT = 16;
	public const uint32 TAPE_DRIVE_ERASE_LONG = 32;
	public const uint32 TAPE_DRIVE_ERASE_BOP_ONLY = 64;
	public const uint32 TAPE_DRIVE_ERASE_IMMEDIATE = 128;
	public const uint32 TAPE_DRIVE_TAPE_CAPACITY = 256;
	public const uint32 TAPE_DRIVE_TAPE_REMAINING = 512;
	public const uint32 TAPE_DRIVE_FIXED_BLOCK = 1024;
	public const uint32 TAPE_DRIVE_VARIABLE_BLOCK = 2048;
	public const uint32 TAPE_DRIVE_WRITE_PROTECT = 4096;
	public const uint32 TAPE_DRIVE_EOT_WZ_SIZE = 8192;
	public const uint32 TAPE_DRIVE_ECC = 65536;
	public const uint32 TAPE_DRIVE_COMPRESSION = 131072;
	public const uint32 TAPE_DRIVE_PADDING = 262144;
	public const uint32 TAPE_DRIVE_REPORT_SMKS = 524288;
	public const uint32 TAPE_DRIVE_GET_ABSOLUTE_BLK = 1048576;
	public const uint32 TAPE_DRIVE_GET_LOGICAL_BLK = 2097152;
	public const uint32 TAPE_DRIVE_SET_EOT_WZ_SIZE = 4194304;
	public const uint32 TAPE_DRIVE_EJECT_MEDIA = 16777216;
	public const uint32 TAPE_DRIVE_CLEAN_REQUESTS = 33554432;
	public const uint32 TAPE_DRIVE_SET_CMP_BOP_ONLY = 67108864;
	public const uint32 TAPE_DRIVE_RESERVED_BIT = 2147483648;
	public const uint32 TAPE_DRIVE_FORMAT = 2684354560;
	public const uint32 TAPE_DRIVE_FORMAT_IMMEDIATE = 3221225472;
	public const uint32 TAPE_DRIVE_HIGH_FEATURES = 2147483648;
	public const int32 TAPE_QUERY_DRIVE_PARAMETERS = 0;
	public const int32 TAPE_QUERY_MEDIA_CAPACITY = 1;
	public const int32 TAPE_CHECK_FOR_DRIVE_PROBLEM = 2;
	public const int32 TAPE_QUERY_IO_ERROR_DATA = 3;
	public const int32 TAPE_QUERY_DEVICE_ERROR_DATA = 4;
	public const uint32 TRANSACTIONMANAGER_QUERY_INFORMATION = 1;
	public const uint32 TRANSACTIONMANAGER_SET_INFORMATION = 2;
	public const uint32 TRANSACTIONMANAGER_RECOVER = 4;
	public const uint32 TRANSACTIONMANAGER_RENAME = 8;
	public const uint32 TRANSACTIONMANAGER_CREATE_RM = 16;
	public const uint32 TRANSACTIONMANAGER_BIND_TRANSACTION = 32;
	public const uint32 TRANSACTION_QUERY_INFORMATION = 1;
	public const uint32 TRANSACTION_SET_INFORMATION = 2;
	public const uint32 TRANSACTION_ENLIST = 4;
	public const uint32 TRANSACTION_COMMIT = 8;
	public const uint32 TRANSACTION_ROLLBACK = 16;
	public const uint32 TRANSACTION_PROPAGATE = 32;
	public const uint32 TRANSACTION_RIGHT_RESERVED1 = 64;
	public const uint32 RESOURCEMANAGER_QUERY_INFORMATION = 1;
	public const uint32 RESOURCEMANAGER_SET_INFORMATION = 2;
	public const uint32 RESOURCEMANAGER_RECOVER = 4;
	public const uint32 RESOURCEMANAGER_ENLIST = 8;
	public const uint32 RESOURCEMANAGER_GET_NOTIFICATION = 16;
	public const uint32 RESOURCEMANAGER_REGISTER_PROTOCOL = 32;
	public const uint32 RESOURCEMANAGER_COMPLETE_PROPAGATION = 64;
	public const uint32 ENLISTMENT_QUERY_INFORMATION = 1;
	public const uint32 ENLISTMENT_SET_INFORMATION = 2;
	public const uint32 ENLISTMENT_RECOVER = 4;
	public const uint32 ENLISTMENT_SUBORDINATE_RIGHTS = 8;
	public const uint32 ENLISTMENT_SUPERIOR_RIGHTS = 16;
	public const uint32 PcTeb = 24;
	public const uint32 ACTIVATION_CONTEXT_SECTION_ASSEMBLY_INFORMATION = 1;
	public const uint32 ACTIVATION_CONTEXT_SECTION_DLL_REDIRECTION = 2;
	public const uint32 ACTIVATION_CONTEXT_SECTION_WINDOW_CLASS_REDIRECTION = 3;
	public const uint32 ACTIVATION_CONTEXT_SECTION_COM_SERVER_REDIRECTION = 4;
	public const uint32 ACTIVATION_CONTEXT_SECTION_COM_INTERFACE_REDIRECTION = 5;
	public const uint32 ACTIVATION_CONTEXT_SECTION_COM_TYPE_LIBRARY_REDIRECTION = 6;
	public const uint32 ACTIVATION_CONTEXT_SECTION_COM_PROGID_REDIRECTION = 7;
	public const uint32 ACTIVATION_CONTEXT_SECTION_GLOBAL_OBJECT_RENAME_TABLE = 8;
	public const uint32 ACTIVATION_CONTEXT_SECTION_CLR_SURROGATES = 9;
	public const uint32 ACTIVATION_CONTEXT_SECTION_APPLICATION_SETTINGS = 10;
	public const uint32 ACTIVATION_CONTEXT_SECTION_COMPATIBILITY_INFO = 11;
	public const uint32 ACTIVATION_CONTEXT_SECTION_WINRT_ACTIVATABLE_CLASSES = 12;
	public const uint32 BSF_MSGSRV32ISOK = 2147483648;
	public const uint32 BSF_MSGSRV32ISOK_BIT = 31;
	public const uint32 DBT_APPYBEGIN = 0;
	public const uint32 DBT_APPYEND = 1;
	public const uint32 DBT_DEVNODES_CHANGED = 7;
	public const uint32 DBT_QUERYCHANGECONFIG = 23;
	public const uint32 DBT_CONFIGCHANGED = 24;
	public const uint32 DBT_CONFIGCHANGECANCELED = 25;
	public const uint32 DBT_MONITORCHANGE = 27;
	public const uint32 DBT_SHELLLOGGEDON = 32;
	public const uint32 DBT_CONFIGMGAPI32 = 34;
	public const uint32 DBT_VXDINITCOMPLETE = 35;
	public const uint32 DBT_VOLLOCKQUERYLOCK = 32833;
	public const uint32 DBT_VOLLOCKLOCKTAKEN = 32834;
	public const uint32 DBT_VOLLOCKLOCKFAILED = 32835;
	public const uint32 DBT_VOLLOCKQUERYUNLOCK = 32836;
	public const uint32 DBT_VOLLOCKLOCKRELEASED = 32837;
	public const uint32 DBT_VOLLOCKUNLOCKFAILED = 32838;
	public const uint32 LOCKP_ALLOW_WRITES = 1;
	public const uint32 LOCKP_FAIL_WRITES = 0;
	public const uint32 LOCKP_FAIL_MEM_MAPPING = 2;
	public const uint32 LOCKP_ALLOW_MEM_MAPPING = 0;
	public const uint32 LOCKP_USER_MASK = 3;
	public const uint32 LOCKP_LOCK_FOR_FORMAT = 4;
	public const uint32 LOCKF_LOGICAL_LOCK = 0;
	public const uint32 LOCKF_PHYSICAL_LOCK = 1;
	public const uint32 DBT_NO_DISK_SPACE = 71;
	public const uint32 DBT_LOW_DISK_SPACE = 72;
	public const uint32 DBT_CONFIGMGPRIVATE = 32767;
	public const uint32 DBT_DEVICEARRIVAL = 32768;
	public const uint32 DBT_DEVICEQUERYREMOVE = 32769;
	public const uint32 DBT_DEVICEQUERYREMOVEFAILED = 32770;
	public const uint32 DBT_DEVICEREMOVEPENDING = 32771;
	public const uint32 DBT_DEVICEREMOVECOMPLETE = 32772;
	public const uint32 DBT_DEVICETYPESPECIFIC = 32773;
	public const uint32 DBT_CUSTOMEVENT = 32774;
	public const uint32 DBT_DEVTYP_DEVNODE = 1;
	public const uint32 DBT_DEVTYP_NET = 4;
	public const uint32 DBTF_RESOURCE = 1;
	public const uint32 DBTF_XPORT = 2;
	public const uint32 DBTF_SLOWNET = 4;
	public const uint32 DBT_VPOWERDAPI = 33024;
	public const uint32 DBT_USERDEFINED = 65535;
	public const Guid GUID_IO_VOLUME_CHANGE = .(0x7373654a, 0x812a, 0x11d0, 0xbe, 0xc7, 0x08, 0x00, 0x2b, 0xe2, 0x09, 0x2f);
	public const Guid GUID_IO_VOLUME_DISMOUNT = .(0xd16a55e8, 0x1059, 0x11d2, 0x8f, 0xfd, 0x00, 0xa0, 0xc9, 0xa0, 0x6d, 0x32);
	public const Guid GUID_IO_VOLUME_DISMOUNT_FAILED = .(0xe3c5b178, 0x105d, 0x11d2, 0x8f, 0xfd, 0x00, 0xa0, 0xc9, 0xa0, 0x6d, 0x32);
	public const Guid GUID_IO_VOLUME_MOUNT = .(0xb5804878, 0x1a96, 0x11d2, 0x8f, 0xfd, 0x00, 0xa0, 0xc9, 0xa0, 0x6d, 0x32);
	public const Guid GUID_IO_VOLUME_LOCK = .(0x50708874, 0xc9af, 0x11d1, 0x8f, 0xef, 0x00, 0xa0, 0xc9, 0xa0, 0x6d, 0x32);
	public const Guid GUID_IO_VOLUME_LOCK_FAILED = .(0xae2eed10, 0x0ba8, 0x11d2, 0x8f, 0xfb, 0x00, 0xa0, 0xc9, 0xa0, 0x6d, 0x32);
	public const Guid GUID_IO_VOLUME_UNLOCK = .(0x9a8c3d68, 0xd0cb, 0x11d1, 0x8f, 0xef, 0x00, 0xa0, 0xc9, 0xa0, 0x6d, 0x32);
	public const Guid GUID_IO_VOLUME_NAME_CHANGE = .(0x2de97f83, 0x4c06, 0x11d2, 0xa5, 0x32, 0x00, 0x60, 0x97, 0x13, 0x05, 0x5a);
	public const Guid GUID_IO_VOLUME_NEED_CHKDSK = .(0x799a0960, 0x0a0b, 0x4e03, 0xad, 0x88, 0x2f, 0xa7, 0xc6, 0xce, 0x74, 0x8a);
	public const Guid GUID_IO_VOLUME_WORM_NEAR_FULL = .(0xf3bfff82, 0xf3de, 0x48d2, 0xaf, 0x95, 0x45, 0x7f, 0x80, 0xb7, 0x63, 0xf2);
	public const Guid GUID_IO_VOLUME_WEARING_OUT = .(0x873113ca, 0x1486, 0x4508, 0x82, 0xac, 0xc3, 0xb2, 0xe5, 0x29, 0x7a, 0xaa);
	public const Guid GUID_IO_VOLUME_FORCE_CLOSED = .(0x411ad84f, 0x433e, 0x4dc2, 0xa5, 0xae, 0x4a, 0x2d, 0x1a, 0x2d, 0xe6, 0x54);
	public const Guid GUID_IO_VOLUME_INFO_MAKE_COMPAT = .(0x3ab9a0d2, 0xef80, 0x45cf, 0x8c, 0xdc, 0xcb, 0xe0, 0x2a, 0x21, 0x29, 0x06);
	public const Guid GUID_IO_VOLUME_PREPARING_EJECT = .(0xc79eb16e, 0x0dac, 0x4e7a, 0xa8, 0x6c, 0xb2, 0x5c, 0xee, 0xaa, 0x88, 0xf6);
	public const Guid GUID_IO_VOLUME_BACKGROUND_FORMAT = .(0xa2e5fc86, 0xd5cd, 0x4038, 0xb2, 0xe3, 0x44, 0x45, 0x06, 0x5c, 0x23, 0x77);
	public const Guid GUID_IO_VOLUME_PHYSICAL_CONFIGURATION_CHANGE = .(0x2de97f84, 0x4c06, 0x11d2, 0xa5, 0x32, 0x00, 0x60, 0x97, 0x13, 0x05, 0x5a);
	public const Guid GUID_IO_VOLUME_UNIQUE_ID_CHANGE = .(0xaf39da42, 0x6622, 0x41f5, 0x97, 0x0b, 0x13, 0x9d, 0x09, 0x2f, 0xa3, 0xd9);
	public const Guid GUID_IO_VOLUME_FVE_STATUS_CHANGE = .(0x062998b2, 0xee1f, 0x4b6a, 0xb8, 0x57, 0xe7, 0x6c, 0xbb, 0xe9, 0xa6, 0xda);
	public const Guid GUID_IO_VOLUME_DEVICE_INTERFACE = .(0x53f5630d, 0xb6bf, 0x11d0, 0x94, 0xf2, 0x00, 0xa0, 0xc9, 0x1e, 0xfb, 0x8b);
	public const Guid GUID_IO_VOLUME_CHANGE_SIZE = .(0x3a1625be, 0xad03, 0x49f1, 0x8e, 0xf8, 0x6b, 0xba, 0xc1, 0x82, 0xd1, 0xfd);
	public const Guid GUID_IO_MEDIA_ARRIVAL = .(0xd07433c0, 0xa98e, 0x11d2, 0x91, 0x7a, 0x00, 0xa0, 0xc9, 0x06, 0x8f, 0xf3);
	public const Guid GUID_IO_MEDIA_REMOVAL = .(0xd07433c1, 0xa98e, 0x11d2, 0x91, 0x7a, 0x00, 0xa0, 0xc9, 0x06, 0x8f, 0xf3);
	public const Guid GUID_IO_CDROM_EXCLUSIVE_LOCK = .(0xbc56c139, 0x7a10, 0x47ee, 0xa2, 0x94, 0x4c, 0x6a, 0x38, 0xf0, 0x14, 0x9a);
	public const Guid GUID_IO_CDROM_EXCLUSIVE_UNLOCK = .(0xa3b6d27d, 0x5e35, 0x4885, 0x81, 0xe5, 0xee, 0x18, 0xc0, 0x0e, 0xd7, 0x79);
	public const Guid GUID_IO_DEVICE_BECOMING_READY = .(0xd07433f0, 0xa98e, 0x11d2, 0x91, 0x7a, 0x00, 0xa0, 0xc9, 0x06, 0x8f, 0xf3);
	public const Guid GUID_IO_DEVICE_EXTERNAL_REQUEST = .(0xd07433d0, 0xa98e, 0x11d2, 0x91, 0x7a, 0x00, 0xa0, 0xc9, 0x06, 0x8f, 0xf3);
	public const Guid GUID_IO_MEDIA_EJECT_REQUEST = .(0xd07433d1, 0xa98e, 0x11d2, 0x91, 0x7a, 0x00, 0xa0, 0xc9, 0x06, 0x8f, 0xf3);
	public const Guid GUID_IO_DRIVE_REQUIRES_CLEANING = .(0x7207877c, 0x90ed, 0x44e5, 0xa0, 0x00, 0x81, 0x42, 0x8d, 0x4c, 0x79, 0xbb);
	public const Guid GUID_IO_TAPE_ERASE = .(0x852d11eb, 0x4bb8, 0x4507, 0x9d, 0x9b, 0x41, 0x7c, 0xc2, 0xb1, 0xb4, 0x38);
	public const Guid GUID_DEVICE_EVENT_RBC = .(0xd0744792, 0xa98e, 0x11d2, 0x91, 0x7a, 0x00, 0xa0, 0xc9, 0x06, 0x8f, 0xf3);
	public const Guid GUID_IO_DISK_CLONE_ARRIVAL = .(0x6a61885b, 0x7c39, 0x43dd, 0x9b, 0x56, 0xb8, 0xac, 0x22, 0xa5, 0x49, 0xaa);
	public const Guid GUID_IO_DISK_LAYOUT_CHANGE = .(0x11dff54c, 0x8469, 0x41f9, 0xb3, 0xde, 0xef, 0x83, 0x64, 0x87, 0xc5, 0x4a);
	public const Guid GUID_IO_DISK_HEALTH_NOTIFICATION = .(0x0f1bd644, 0x3916, 0x49c5, 0xb0, 0x63, 0x99, 0x19, 0x40, 0x11, 0x8f, 0xb2);
	public const uint32 D3DNTHAL_NUMCLIPVERTICES = 20;
	public const int32 D3DNTHAL_SCENE_CAPTURE_START = 0;
	public const int32 D3DNTHAL_SCENE_CAPTURE_END = 1;
	public const int64 D3DNTHAL_CONTEXT_BAD = 512;
	public const int64 D3DNTHAL_OUTOFCONTEXTS = 513;
	public const int32 D3DNTHAL2_CB32_SETRENDERTARGET = 1;
	public const uint32 D3DHAL_STATESETBEGIN = 0;
	public const uint32 D3DHAL_STATESETEND = 1;
	public const uint32 D3DHAL_STATESETDELETE = 2;
	public const uint32 D3DHAL_STATESETEXECUTE = 3;
	public const uint32 D3DHAL_STATESETCAPTURE = 4;
	public const int32 D3DNTHALDP2_USERMEMVERTICES = 1;
	public const int32 D3DNTHALDP2_EXECUTEBUFFER = 2;
	public const int32 D3DNTHALDP2_SWAPVERTEXBUFFER = 4;
	public const int32 D3DNTHALDP2_SWAPCOMMANDBUFFER = 8;
	public const int32 D3DNTHALDP2_REQVERTEXBUFSIZE = 16;
	public const int32 D3DNTHALDP2_REQCOMMANDBUFSIZE = 32;
	public const int32 D3DNTHALDP2_VIDMEMVERTEXBUF = 64;
	public const int32 D3DNTHALDP2_VIDMEMCOMMANDBUF = 128;
	public const int32 D3DNTHAL3_CB32_CLEAR2 = 1;
	public const int32 D3DNTHAL3_CB32_RESERVED = 2;
	public const int32 D3DNTHAL3_CB32_VALIDATETEXTURESTAGESTATE = 4;
	public const int32 D3DNTHAL3_CB32_DRAWPRIMITIVES2 = 8;
	public const uint32 D3DNTHAL_TSS_RENDERSTATEBASE = 256;
	public const uint32 D3DNTHAL_TSS_MAXSTAGES = 8;
	public const uint32 D3DNTHAL_TSS_STATESPERSTAGE = 64;
	public const uint32 D3DTSS_TEXTUREMAP = 0;
	public const uint32 D3DHAL_SAMPLER_MAXSAMP = 16;
	public const uint32 D3DHAL_SAMPLER_MAXVERTEXSAMP = 4;
	public const int32 D3DPMISCCAPS_LINEPATTERNREP = 4;
	public const uint32 D3DRS_MAXVERTEXSHADERINST = 196;
	public const uint32 D3DRS_MAXPIXELSHADERINST = 197;
	public const uint32 D3DRENDERSTATE_EVICTMANAGEDTEXTURES = 61;
	public const uint32 D3DRENDERSTATE_SCENECAPTURE = 62;
	public const uint32 _NT_D3DRS_DELETERTPATCH = 169;
	public const uint32 D3DINFINITEINSTRUCTIONS = 4294967295;
	public const uint32 D3DNTHAL_STATESETCREATE = 5;
	public const int32 D3DNTCLEAR_COMPUTERECTS = 8;
	public const int32 _NT_RTPATCHFLAG_HASSEGS = 1;
	public const int32 _NT_RTPATCHFLAG_HASINFO = 2;
	public const uint32 D3DNTHAL_ROW_WEIGHTS = 1;
	public const uint32 D3DNTHAL_COL_WEIGHTS = 2;
	public const int32 DP2BLT_POINT = 1;
	public const int32 DP2BLT_LINEAR = 2;
	public const int32 DDBLT_EXTENDED_PRESENTATION_STRETCHFACTOR = 16;
	public const uint32 _NT_D3DGDI2_MAGIC = 4294967295;
	public const uint32 _NT_D3DGDI2_TYPE_GETD3DCAPS8 = 1;
	public const uint32 _NT_D3DGDI2_TYPE_GETFORMATCOUNT = 2;
	public const uint32 _NT_D3DGDI2_TYPE_GETFORMAT = 3;
	public const uint32 _NT_D3DGDI2_TYPE_DXVERSION = 4;
	public const uint32 _NT_D3DGDI2_TYPE_DEFERRED_AGP_AWARE = 24;
	public const uint32 _NT_D3DGDI2_TYPE_FREE_DEFERRED_AGP = 25;
	public const uint32 _NT_D3DGDI2_TYPE_DEFER_AGP_FREES = 32;
	public const uint32 _NT_D3DGDI2_TYPE_GETD3DCAPS9 = 16;
	public const uint32 _NT_D3DGDI2_TYPE_GETEXTENDEDMODECOUNT = 17;
	public const uint32 _NT_D3DGDI2_TYPE_GETEXTENDEDMODE = 18;
	public const uint32 _NT_D3DGDI2_TYPE_GETADAPTERGROUP = 19;
	public const uint32 _NT_D3DGDI2_TYPE_GETMULTISAMPLEQUALITYLEVELS = 22;
	public const uint32 _NT_D3DGDI2_TYPE_GETD3DQUERYCOUNT = 33;
	public const uint32 _NT_D3DGDI2_TYPE_GETD3DQUERY = 34;
	public const uint32 _NT_D3DGDI2_TYPE_GETDDIVERSION = 35;
	public const uint32 DX9_DDI_VERSION = 4;
	public const int32 _NT_D3DDEVCAPS_HWVERTEXBUFFER = 33554432;
	public const int32 _NT_D3DDEVCAPS_HWINDEXBUFFER = 67108864;
	public const int32 _NT_D3DDEVCAPS_SUBVOLUMELOCK = 134217728;
	public const int32 _NT_D3DPMISCCAPS_FOGINFVF = 8192;
	public const int32 _NT_D3DFVF_FOG = 8192;
	public const int32 D3DPRASTERCAPS_STRETCHBLTMULTISAMPLE = 8388608;
	public const uint32 _NT_D3DVS_MAXINSTRUCTIONCOUNT_V1_1 = 128;
	public const uint32 _NT_D3DVS_LABEL_MAX_V3_0 = 2048;
	public const uint32 _NT_D3DVS_TCRDOUTREG_MAX_V1_1 = 8;
	public const uint32 _NT_D3DVS_TCRDOUTREG_MAX_V2_0 = 8;
	public const uint32 _NT_D3DVS_TCRDOUTREG_MAX_V2_1 = 8;
	public const uint32 _NT_D3DVS_OUTPUTREG_MAX_V3_0 = 12;
	public const uint32 _NT_D3DVS_OUTPUTREG_MAX_SW_DX9 = 16;
	public const uint32 _NT_D3DVS_ATTROUTREG_MAX_V1_1 = 2;
	public const uint32 _NT_D3DVS_ATTROUTREG_MAX_V2_0 = 2;
	public const uint32 _NT_D3DVS_ATTROUTREG_MAX_V2_1 = 2;
	public const uint32 _NT_D3DVS_INPUTREG_MAX_V1_1 = 16;
	public const uint32 _NT_D3DVS_INPUTREG_MAX_V2_0 = 16;
	public const uint32 _NT_D3DVS_INPUTREG_MAX_V2_1 = 16;
	public const uint32 _NT_D3DVS_INPUTREG_MAX_V3_0 = 16;
	public const uint32 _NT_D3DVS_TEMPREG_MAX_V1_1 = 12;
	public const uint32 _NT_D3DVS_TEMPREG_MAX_V2_0 = 12;
	public const uint32 _NT_D3DVS_TEMPREG_MAX_V2_1 = 32;
	public const uint32 _NT_D3DVS_TEMPREG_MAX_V3_0 = 32;
	public const uint32 _NT_D3DVS_CONSTREG_MAX_V1_1 = 96;
	public const uint32 _NT_D3DVS_CONSTREG_MAX_V2_0 = 8192;
	public const uint32 _NT_D3DVS_CONSTREG_MAX_V2_1 = 8192;
	public const uint32 _NT_D3DVS_CONSTREG_MAX_V3_0 = 8192;
	public const uint32 _NT_D3DVS_CONSTINTREG_MAX_SW_DX9 = 2048;
	public const uint32 _NT_D3DVS_CONSTINTREG_MAX_V2_0 = 16;
	public const uint32 _NT_D3DVS_CONSTINTREG_MAX_V2_1 = 16;
	public const uint32 _NT_D3DVS_CONSTINTREG_MAX_V3_0 = 16;
	public const uint32 _NT_D3DVS_CONSTBOOLREG_MAX_SW_DX9 = 2048;
	public const uint32 _NT_D3DVS_CONSTBOOLREG_MAX_V2_0 = 16;
	public const uint32 _NT_D3DVS_CONSTBOOLREG_MAX_V2_1 = 16;
	public const uint32 _NT_D3DVS_CONSTBOOLREG_MAX_V3_0 = 16;
	public const uint32 _NT_D3DVS_ADDRREG_MAX_V1_1 = 1;
	public const uint32 _NT_D3DVS_ADDRREG_MAX_V2_0 = 1;
	public const uint32 _NT_D3DVS_ADDRREG_MAX_V2_1 = 1;
	public const uint32 _NT_D3DVS_ADDRREG_MAX_V3_0 = 1;
	public const uint32 _NT_D3DVS_MAXLOOPSTEP_V2_0 = 128;
	public const uint32 _NT_D3DVS_MAXLOOPSTEP_V2_1 = 128;
	public const uint32 _NT_D3DVS_MAXLOOPSTEP_V3_0 = 128;
	public const uint32 _NT_D3DVS_MAXLOOPINITVALUE_V2_0 = 255;
	public const uint32 _NT_D3DVS_MAXLOOPINITVALUE_V2_1 = 255;
	public const uint32 _NT_D3DVS_MAXLOOPINITVALUE_V3_0 = 255;
	public const uint32 _NT_D3DVS_MAXLOOPITERATIONCOUNT_V2_0 = 255;
	public const uint32 _NT_D3DVS_MAXLOOPITERATIONCOUNT_V2_1 = 255;
	public const uint32 _NT_D3DVS_MAXLOOPITERATIONCOUNT_V3_0 = 255;
	public const uint32 _NT_D3DVS_PREDICATE_MAX_V2_1 = 1;
	public const uint32 _NT_D3DVS_PREDICATE_MAX_V3_0 = 1;
	public const uint32 _NT_D3DPS_INPUTREG_MAX_V1_1 = 2;
	public const uint32 _NT_D3DPS_INPUTREG_MAX_V1_2 = 2;
	public const uint32 _NT_D3DPS_INPUTREG_MAX_V1_3 = 2;
	public const uint32 _NT_D3DPS_INPUTREG_MAX_V1_4 = 2;
	public const uint32 _NT_D3DPS_INPUTREG_MAX_V2_0 = 2;
	public const uint32 _NT_D3DPS_INPUTREG_MAX_V2_1 = 2;
	public const uint32 _NT_D3DPS_INPUTREG_MAX_V3_0 = 12;
	public const uint32 _NT_D3DPS_TEMPREG_MAX_V1_1 = 2;
	public const uint32 _NT_D3DPS_TEMPREG_MAX_V1_2 = 2;
	public const uint32 _NT_D3DPS_TEMPREG_MAX_V1_3 = 2;
	public const uint32 _NT_D3DPS_TEMPREG_MAX_V1_4 = 6;
	public const uint32 _NT_D3DPS_TEMPREG_MAX_V2_0 = 12;
	public const uint32 _NT_D3DPS_TEMPREG_MAX_V2_1 = 32;
	public const uint32 _NT_D3DPS_TEMPREG_MAX_V3_0 = 32;
	public const uint32 _NT_D3DPS_TEXTUREREG_MAX_V1_1 = 4;
	public const uint32 _NT_D3DPS_TEXTUREREG_MAX_V1_2 = 4;
	public const uint32 _NT_D3DPS_TEXTUREREG_MAX_V1_3 = 4;
	public const uint32 _NT_D3DPS_TEXTUREREG_MAX_V1_4 = 6;
	public const uint32 _NT_D3DPS_TEXTUREREG_MAX_V2_0 = 8;
	public const uint32 _NT_D3DPS_TEXTUREREG_MAX_V2_1 = 8;
	public const uint32 _NT_D3DPS_TEXTUREREG_MAX_V3_0 = 0;
	public const uint32 _NT_D3DPS_COLOROUT_MAX_V2_0 = 4;
	public const uint32 _NT_D3DPS_COLOROUT_MAX_V2_1 = 4;
	public const uint32 _NT_D3DPS_COLOROUT_MAX_V3_0 = 4;
	public const uint32 _NT_D3DPS_PREDICATE_MAX_V2_1 = 1;
	public const uint32 _NT_D3DPS_PREDICATE_MAX_V3_0 = 1;
	public const uint32 _NT_D3DPS_CONSTREG_MAX_SW_DX9 = 8192;
	public const uint32 _NT_D3DPS_CONSTREG_MAX_V1_1 = 8;
	public const uint32 _NT_D3DPS_CONSTREG_MAX_V1_2 = 8;
	public const uint32 _NT_D3DPS_CONSTREG_MAX_V1_3 = 8;
	public const uint32 _NT_D3DPS_CONSTREG_MAX_V1_4 = 8;
	public const uint32 _NT_D3DPS_CONSTREG_MAX_V2_0 = 32;
	public const uint32 _NT_D3DPS_CONSTREG_MAX_V2_1 = 32;
	public const uint32 _NT_D3DPS_CONSTREG_MAX_V3_0 = 224;
	public const uint32 _NT_D3DPS_CONSTBOOLREG_MAX_SW_DX9 = 2048;
	public const uint32 _NT_D3DPS_CONSTBOOLREG_MAX_V2_1 = 16;
	public const uint32 _NT_D3DPS_CONSTBOOLREG_MAX_V3_0 = 16;
	public const uint32 _NT_D3DPS_CONSTINTREG_MAX_SW_DX9 = 2048;
	public const uint32 _NT_D3DPS_CONSTINTREG_MAX_V2_1 = 16;
	public const uint32 _NT_D3DPS_CONSTINTREG_MAX_V3_0 = 16;
	public const uint32 _NT_D3DPS_MAXLOOPSTEP_V2_1 = 128;
	public const uint32 _NT_D3DPS_MAXLOOPSTEP_V3_0 = 128;
	public const uint32 _NT_D3DPS_MAXLOOPINITVALUE_V2_1 = 255;
	public const uint32 _NT_D3DPS_MAXLOOPINITVALUE_V3_0 = 255;
	public const uint32 _NT_D3DPS_MAXLOOPITERATIONCOUNT_V2_1 = 255;
	public const uint32 _NT_D3DPS_MAXLOOPITERATIONCOUNT_V3_0 = 255;
	public const uint32 _NT_D3DPS_INPUTREG_MAX_DX8 = 8;
	public const uint32 _NT_D3DPS_TEMPREG_MAX_DX8 = 8;
	public const uint32 _NT_D3DPS_CONSTREG_MAX_DX8 = 8;
	public const uint32 _NT_D3DPS_TEXTUREREG_MAX_DX8 = 8;
	public const uint32 D3DVSDT_FLOAT1 = 0;
	public const uint32 D3DVSDT_FLOAT2 = 1;
	public const uint32 D3DVSDT_FLOAT3 = 2;
	public const uint32 D3DVSDT_FLOAT4 = 3;
	public const uint32 D3DVSDT_D3DCOLOR = 4;
	public const uint32 D3DVSDT_UBYTE4 = 5;
	public const uint32 D3DVSDT_SHORT2 = 6;
	public const uint32 D3DVSDT_SHORT4 = 7;
	public const uint32 D3DVSDE_POSITION = 0;
	public const uint32 D3DVSDE_BLENDWEIGHT = 1;
	public const uint32 D3DVSDE_BLENDINDICES = 2;
	public const uint32 D3DVSDE_NORMAL = 3;
	public const uint32 D3DVSDE_PSIZE = 4;
	public const uint32 D3DVSDE_DIFFUSE = 5;
	public const uint32 D3DVSDE_SPECULAR = 6;
	public const uint32 D3DVSDE_TEXCOORD0 = 7;
	public const uint32 D3DVSDE_TEXCOORD1 = 8;
	public const uint32 D3DVSDE_TEXCOORD2 = 9;
	public const uint32 D3DVSDE_TEXCOORD3 = 10;
	public const uint32 D3DVSDE_TEXCOORD4 = 11;
	public const uint32 D3DVSDE_TEXCOORD5 = 12;
	public const uint32 D3DVSDE_TEXCOORD6 = 13;
	public const uint32 D3DVSDE_TEXCOORD7 = 14;
	public const uint32 D3DVSDE_POSITION2 = 15;
	public const uint32 D3DVSDE_NORMAL2 = 16;
	public const uint32 D3DVSD_TOKENTYPESHIFT = 29;
	public const uint32 D3DVSD_STREAMNUMBERSHIFT = 0;
	public const uint32 D3DVSD_DATALOADTYPESHIFT = 28;
	public const uint32 D3DVSD_DATATYPESHIFT = 16;
	public const uint32 D3DVSD_SKIPCOUNTSHIFT = 16;
	public const uint32 D3DVSD_VERTEXREGSHIFT = 0;
	public const uint32 D3DVSD_VERTEXREGINSHIFT = 20;
	public const uint32 D3DVSD_CONSTCOUNTSHIFT = 25;
	public const uint32 D3DVSD_CONSTADDRESSSHIFT = 0;
	public const uint32 D3DVSD_CONSTRSSHIFT = 16;
	public const uint32 D3DVSD_EXTCOUNTSHIFT = 24;
	public const uint32 D3DVSD_EXTINFOSHIFT = 0;
	public const uint32 D3DVSD_STREAMTESSSHIFT = 28;
	public const uint32 DIRECT3D_VERSION = 1792;
	public const int32 D3DTRANSFORMCAPS_CLIP = 1;
	public const int32 D3DLIGHTINGMODEL_RGB = 1;
	public const int32 D3DLIGHTINGMODEL_MONO = 2;
	public const int32 D3DLIGHTCAPS_POINT = 1;
	public const int32 D3DLIGHTCAPS_SPOT = 2;
	public const int32 D3DLIGHTCAPS_DIRECTIONAL = 4;
	public const int32 D3DLIGHTCAPS_PARALLELPOINT = 8;
	public const int32 D3DLIGHTCAPS_GLSPOT = 16;
	public const int32 D3DPMISCCAPS_MASKPLANES = 1;
	public const int32 D3DPMISCCAPS_MASKZ = 2;
	public const int32 D3DPMISCCAPS_CONFORMANT = 8;
	public const int32 D3DPMISCCAPS_CULLNONE = 16;
	public const int32 D3DPMISCCAPS_CULLCW = 32;
	public const int32 D3DPMISCCAPS_CULLCCW = 64;
	public const int32 D3DPRASTERCAPS_DITHER = 1;
	public const int32 D3DPRASTERCAPS_ROP2 = 2;
	public const int32 D3DPRASTERCAPS_XOR = 4;
	public const int32 D3DPRASTERCAPS_PAT = 8;
	public const int32 D3DPRASTERCAPS_ZTEST = 16;
	public const int32 D3DPRASTERCAPS_SUBPIXEL = 32;
	public const int32 D3DPRASTERCAPS_SUBPIXELX = 64;
	public const int32 D3DPRASTERCAPS_FOGVERTEX = 128;
	public const int32 D3DPRASTERCAPS_FOGTABLE = 256;
	public const int32 D3DPRASTERCAPS_STIPPLE = 512;
	public const int32 D3DPRASTERCAPS_ANTIALIASSORTDEPENDENT = 1024;
	public const int32 D3DPRASTERCAPS_ANTIALIASSORTINDEPENDENT = 2048;
	public const int32 D3DPRASTERCAPS_ANTIALIASEDGES = 4096;
	public const int32 D3DPRASTERCAPS_MIPMAPLODBIAS = 8192;
	public const int32 D3DPRASTERCAPS_ZBIAS = 16384;
	public const int32 D3DPRASTERCAPS_ZBUFFERLESSHSR = 32768;
	public const int32 D3DPRASTERCAPS_FOGRANGE = 65536;
	public const int32 D3DPRASTERCAPS_ANISOTROPY = 131072;
	public const int32 D3DPRASTERCAPS_WBUFFER = 262144;
	public const int32 D3DPRASTERCAPS_TRANSLUCENTSORTINDEPENDENT = 524288;
	public const int32 D3DPRASTERCAPS_WFOG = 1048576;
	public const int32 D3DPRASTERCAPS_ZFOG = 2097152;
	public const int32 D3DPCMPCAPS_NEVER = 1;
	public const int32 D3DPCMPCAPS_LESS = 2;
	public const int32 D3DPCMPCAPS_EQUAL = 4;
	public const int32 D3DPCMPCAPS_LESSEQUAL = 8;
	public const int32 D3DPCMPCAPS_GREATER = 16;
	public const int32 D3DPCMPCAPS_NOTEQUAL = 32;
	public const int32 D3DPCMPCAPS_GREATEREQUAL = 64;
	public const int32 D3DPCMPCAPS_ALWAYS = 128;
	public const int32 D3DPBLENDCAPS_ZERO = 1;
	public const int32 D3DPBLENDCAPS_ONE = 2;
	public const int32 D3DPBLENDCAPS_SRCCOLOR = 4;
	public const int32 D3DPBLENDCAPS_INVSRCCOLOR = 8;
	public const int32 D3DPBLENDCAPS_SRCALPHA = 16;
	public const int32 D3DPBLENDCAPS_INVSRCALPHA = 32;
	public const int32 D3DPBLENDCAPS_DESTALPHA = 64;
	public const int32 D3DPBLENDCAPS_INVDESTALPHA = 128;
	public const int32 D3DPBLENDCAPS_DESTCOLOR = 256;
	public const int32 D3DPBLENDCAPS_INVDESTCOLOR = 512;
	public const int32 D3DPBLENDCAPS_SRCALPHASAT = 1024;
	public const int32 D3DPBLENDCAPS_BOTHSRCALPHA = 2048;
	public const int32 D3DPBLENDCAPS_BOTHINVSRCALPHA = 4096;
	public const int32 D3DPSHADECAPS_COLORFLATMONO = 1;
	public const int32 D3DPSHADECAPS_COLORFLATRGB = 2;
	public const int32 D3DPSHADECAPS_COLORGOURAUDMONO = 4;
	public const int32 D3DPSHADECAPS_COLORGOURAUDRGB = 8;
	public const int32 D3DPSHADECAPS_COLORPHONGMONO = 16;
	public const int32 D3DPSHADECAPS_COLORPHONGRGB = 32;
	public const int32 D3DPSHADECAPS_SPECULARFLATMONO = 64;
	public const int32 D3DPSHADECAPS_SPECULARFLATRGB = 128;
	public const int32 D3DPSHADECAPS_SPECULARGOURAUDMONO = 256;
	public const int32 D3DPSHADECAPS_SPECULARGOURAUDRGB = 512;
	public const int32 D3DPSHADECAPS_SPECULARPHONGMONO = 1024;
	public const int32 D3DPSHADECAPS_SPECULARPHONGRGB = 2048;
	public const int32 D3DPSHADECAPS_ALPHAFLATBLEND = 4096;
	public const int32 D3DPSHADECAPS_ALPHAFLATSTIPPLED = 8192;
	public const int32 D3DPSHADECAPS_ALPHAGOURAUDBLEND = 16384;
	public const int32 D3DPSHADECAPS_ALPHAGOURAUDSTIPPLED = 32768;
	public const int32 D3DPSHADECAPS_ALPHAPHONGBLEND = 65536;
	public const int32 D3DPSHADECAPS_ALPHAPHONGSTIPPLED = 131072;
	public const int32 D3DPSHADECAPS_FOGFLAT = 262144;
	public const int32 D3DPSHADECAPS_FOGGOURAUD = 524288;
	public const int32 D3DPSHADECAPS_FOGPHONG = 1048576;
	public const int32 D3DPTEXTURECAPS_PERSPECTIVE = 1;
	public const int32 D3DPTEXTURECAPS_POW2 = 2;
	public const int32 D3DPTEXTURECAPS_ALPHA = 4;
	public const int32 D3DPTEXTURECAPS_TRANSPARENCY = 8;
	public const int32 D3DPTEXTURECAPS_BORDER = 16;
	public const int32 D3DPTEXTURECAPS_SQUAREONLY = 32;
	public const int32 D3DPTEXTURECAPS_TEXREPEATNOTSCALEDBYSIZE = 64;
	public const int32 D3DPTEXTURECAPS_ALPHAPALETTE = 128;
	public const int32 D3DPTEXTURECAPS_NONPOW2CONDITIONAL = 256;
	public const int32 D3DPTEXTURECAPS_PROJECTED = 1024;
	public const int32 D3DPTEXTURECAPS_CUBEMAP = 2048;
	public const int32 D3DPTEXTURECAPS_COLORKEYBLEND = 4096;
	public const int32 D3DPTFILTERCAPS_NEAREST = 1;
	public const int32 D3DPTFILTERCAPS_LINEAR = 2;
	public const int32 D3DPTFILTERCAPS_MIPNEAREST = 4;
	public const int32 D3DPTFILTERCAPS_MIPLINEAR = 8;
	public const int32 D3DPTFILTERCAPS_LINEARMIPNEAREST = 16;
	public const int32 D3DPTFILTERCAPS_LINEARMIPLINEAR = 32;
	public const int32 D3DPTFILTERCAPS_MINFPOINT = 256;
	public const int32 D3DPTFILTERCAPS_MINFLINEAR = 512;
	public const int32 D3DPTFILTERCAPS_MINFANISOTROPIC = 1024;
	public const int32 D3DPTFILTERCAPS_MIPFPOINT = 65536;
	public const int32 D3DPTFILTERCAPS_MIPFLINEAR = 131072;
	public const int32 D3DPTFILTERCAPS_MAGFPOINT = 16777216;
	public const int32 D3DPTFILTERCAPS_MAGFLINEAR = 33554432;
	public const int32 D3DPTFILTERCAPS_MAGFANISOTROPIC = 67108864;
	public const int32 D3DPTFILTERCAPS_MAGFAFLATCUBIC = 134217728;
	public const int32 D3DPTFILTERCAPS_MAGFGAUSSIANCUBIC = 268435456;
	public const int32 D3DPTBLENDCAPS_DECAL = 1;
	public const int32 D3DPTBLENDCAPS_MODULATE = 2;
	public const int32 D3DPTBLENDCAPS_DECALALPHA = 4;
	public const int32 D3DPTBLENDCAPS_MODULATEALPHA = 8;
	public const int32 D3DPTBLENDCAPS_DECALMASK = 16;
	public const int32 D3DPTBLENDCAPS_MODULATEMASK = 32;
	public const int32 D3DPTBLENDCAPS_COPY = 64;
	public const int32 D3DPTBLENDCAPS_ADD = 128;
	public const int32 D3DPTADDRESSCAPS_WRAP = 1;
	public const int32 D3DPTADDRESSCAPS_MIRROR = 2;
	public const int32 D3DPTADDRESSCAPS_CLAMP = 4;
	public const int32 D3DPTADDRESSCAPS_BORDER = 8;
	public const int32 D3DPTADDRESSCAPS_INDEPENDENTUV = 16;
	public const int32 D3DSTENCILCAPS_KEEP = 1;
	public const int32 D3DSTENCILCAPS_ZERO = 2;
	public const int32 D3DSTENCILCAPS_REPLACE = 4;
	public const int32 D3DSTENCILCAPS_INCRSAT = 8;
	public const int32 D3DSTENCILCAPS_DECRSAT = 16;
	public const int32 D3DSTENCILCAPS_INVERT = 32;
	public const int32 D3DSTENCILCAPS_INCR = 64;
	public const int32 D3DSTENCILCAPS_DECR = 128;
	public const int32 D3DTEXOPCAPS_DISABLE = 1;
	public const int32 D3DTEXOPCAPS_SELECTARG1 = 2;
	public const int32 D3DTEXOPCAPS_SELECTARG2 = 4;
	public const int32 D3DTEXOPCAPS_MODULATE = 8;
	public const int32 D3DTEXOPCAPS_MODULATE2X = 16;
	public const int32 D3DTEXOPCAPS_MODULATE4X = 32;
	public const int32 D3DTEXOPCAPS_ADD = 64;
	public const int32 D3DTEXOPCAPS_ADDSIGNED = 128;
	public const int32 D3DTEXOPCAPS_ADDSIGNED2X = 256;
	public const int32 D3DTEXOPCAPS_SUBTRACT = 512;
	public const int32 D3DTEXOPCAPS_ADDSMOOTH = 1024;
	public const int32 D3DTEXOPCAPS_BLENDDIFFUSEALPHA = 2048;
	public const int32 D3DTEXOPCAPS_BLENDTEXTUREALPHA = 4096;
	public const int32 D3DTEXOPCAPS_BLENDFACTORALPHA = 8192;
	public const int32 D3DTEXOPCAPS_BLENDTEXTUREALPHAPM = 16384;
	public const int32 D3DTEXOPCAPS_BLENDCURRENTALPHA = 32768;
	public const int32 D3DTEXOPCAPS_PREMODULATE = 65536;
	public const int32 D3DTEXOPCAPS_MODULATEALPHA_ADDCOLOR = 131072;
	public const int32 D3DTEXOPCAPS_MODULATECOLOR_ADDALPHA = 262144;
	public const int32 D3DTEXOPCAPS_MODULATEINVALPHA_ADDCOLOR = 524288;
	public const int32 D3DTEXOPCAPS_MODULATEINVCOLOR_ADDALPHA = 1048576;
	public const int32 D3DTEXOPCAPS_BUMPENVMAP = 2097152;
	public const int32 D3DTEXOPCAPS_BUMPENVMAPLUMINANCE = 4194304;
	public const int32 D3DTEXOPCAPS_DOTPRODUCT3 = 8388608;
	public const int32 D3DFVFCAPS_TEXCOORDCOUNTMASK = 65535;
	public const int32 D3DFVFCAPS_DONOTSTRIPELEMENTS = 524288;
	public const int32 D3DDD_COLORMODEL = 1;
	public const int32 D3DDD_DEVCAPS = 2;
	public const int32 D3DDD_TRANSFORMCAPS = 4;
	public const int32 D3DDD_LIGHTINGCAPS = 8;
	public const int32 D3DDD_BCLIPPING = 16;
	public const int32 D3DDD_LINECAPS = 32;
	public const int32 D3DDD_TRICAPS = 64;
	public const int32 D3DDD_DEVICERENDERBITDEPTH = 128;
	public const int32 D3DDD_DEVICEZBUFFERBITDEPTH = 256;
	public const int32 D3DDD_MAXBUFFERSIZE = 512;
	public const int32 D3DDD_MAXVERTEXCOUNT = 1024;
	public const int32 D3DDEVCAPS_FLOATTLVERTEX = 1;
	public const int32 D3DDEVCAPS_SORTINCREASINGZ = 2;
	public const int32 D3DDEVCAPS_SORTDECREASINGZ = 4;
	public const int32 D3DDEVCAPS_SORTEXACT = 8;
	public const int32 D3DDEVCAPS_EXECUTESYSTEMMEMORY = 16;
	public const int32 D3DDEVCAPS_EXECUTEVIDEOMEMORY = 32;
	public const int32 D3DDEVCAPS_TLVERTEXSYSTEMMEMORY = 64;
	public const int32 D3DDEVCAPS_TLVERTEXVIDEOMEMORY = 128;
	public const int32 D3DDEVCAPS_TEXTURESYSTEMMEMORY = 256;
	public const int32 D3DDEVCAPS_TEXTUREVIDEOMEMORY = 512;
	public const int32 D3DDEVCAPS_DRAWPRIMTLVERTEX = 1024;
	public const int32 D3DDEVCAPS_CANRENDERAFTERFLIP = 2048;
	public const int32 D3DDEVCAPS_TEXTURENONLOCALVIDMEM = 4096;
	public const int32 D3DDEVCAPS_DRAWPRIMITIVES2 = 8192;
	public const int32 D3DDEVCAPS_SEPARATETEXTUREMEMORIES = 16384;
	public const int32 D3DDEVCAPS_DRAWPRIMITIVES2EX = 32768;
	public const int32 D3DDEVCAPS_HWTRANSFORMANDLIGHT = 65536;
	public const int32 D3DDEVCAPS_CANBLTSYSTONONLOCAL = 131072;
	public const int32 D3DDEVCAPS_HWRASTERIZATION = 524288;
	public const int32 D3DVTXPCAPS_TEXGEN = 1;
	public const int32 D3DVTXPCAPS_MATERIALSOURCE7 = 2;
	public const int32 D3DVTXPCAPS_VERTEXFOG = 4;
	public const int32 D3DVTXPCAPS_DIRECTIONALLIGHTS = 8;
	public const int32 D3DVTXPCAPS_POSITIONALLIGHTS = 16;
	public const int32 D3DVTXPCAPS_LOCALVIEWER = 32;
	public const int32 D3DFDS_COLORMODEL = 1;
	public const int32 D3DFDS_GUID = 2;
	public const int32 D3DFDS_HARDWARE = 4;
	public const int32 D3DFDS_TRIANGLES = 8;
	public const int32 D3DFDS_LINES = 16;
	public const int32 D3DFDS_MISCCAPS = 32;
	public const int32 D3DFDS_RASTERCAPS = 64;
	public const int32 D3DFDS_ZCMPCAPS = 128;
	public const int32 D3DFDS_ALPHACMPCAPS = 256;
	public const int32 D3DFDS_SRCBLENDCAPS = 512;
	public const int32 D3DFDS_DSTBLENDCAPS = 1024;
	public const int32 D3DFDS_SHADECAPS = 2048;
	public const int32 D3DFDS_TEXTURECAPS = 4096;
	public const int32 D3DFDS_TEXTUREFILTERCAPS = 8192;
	public const int32 D3DFDS_TEXTUREBLENDCAPS = 16384;
	public const int32 D3DFDS_TEXTUREADDRESSCAPS = 32768;
	public const int32 D3DDEB_BUFSIZE = 1;
	public const int32 D3DDEB_CAPS = 2;
	public const int32 D3DDEB_LPDATA = 4;
	public const int32 D3DDEBCAPS_SYSTEMMEMORY = 1;
	public const int32 D3DDEBCAPS_VIDEOMEMORY = 2;
	public const uint32 D3DMAXUSERCLIPPLANES = 32;
	public const uint32 D3DCLIPPLANE0 = 1;
	public const uint32 D3DCLIPPLANE1 = 2;
	public const uint32 D3DCLIPPLANE2 = 4;
	public const uint32 D3DCLIPPLANE3 = 8;
	public const uint32 D3DCLIPPLANE4 = 16;
	public const uint32 D3DCLIPPLANE5 = 32;
	public const int32 D3DCLIP_LEFT = 1;
	public const int32 D3DCLIP_RIGHT = 2;
	public const int32 D3DCLIP_TOP = 4;
	public const int32 D3DCLIP_BOTTOM = 8;
	public const int32 D3DCLIP_FRONT = 16;
	public const int32 D3DCLIP_BACK = 32;
	public const int32 D3DCLIP_GEN0 = 64;
	public const int32 D3DCLIP_GEN1 = 128;
	public const int32 D3DCLIP_GEN2 = 256;
	public const int32 D3DCLIP_GEN3 = 512;
	public const int32 D3DCLIP_GEN4 = 1024;
	public const int32 D3DCLIP_GEN5 = 2048;
	public const int32 D3DSTATUS_CLIPUNIONLEFT = 1;
	public const int32 D3DSTATUS_CLIPUNIONRIGHT = 2;
	public const int32 D3DSTATUS_CLIPUNIONTOP = 4;
	public const int32 D3DSTATUS_CLIPUNIONBOTTOM = 8;
	public const int32 D3DSTATUS_CLIPUNIONFRONT = 16;
	public const int32 D3DSTATUS_CLIPUNIONBACK = 32;
	public const int32 D3DSTATUS_CLIPUNIONGEN0 = 64;
	public const int32 D3DSTATUS_CLIPUNIONGEN1 = 128;
	public const int32 D3DSTATUS_CLIPUNIONGEN2 = 256;
	public const int32 D3DSTATUS_CLIPUNIONGEN3 = 512;
	public const int32 D3DSTATUS_CLIPUNIONGEN4 = 1024;
	public const int32 D3DSTATUS_CLIPUNIONGEN5 = 2048;
	public const int32 D3DSTATUS_CLIPINTERSECTIONLEFT = 4096;
	public const int32 D3DSTATUS_CLIPINTERSECTIONRIGHT = 8192;
	public const int32 D3DSTATUS_CLIPINTERSECTIONTOP = 16384;
	public const int32 D3DSTATUS_CLIPINTERSECTIONBOTTOM = 32768;
	public const int32 D3DSTATUS_CLIPINTERSECTIONFRONT = 65536;
	public const int32 D3DSTATUS_CLIPINTERSECTIONBACK = 131072;
	public const int32 D3DSTATUS_CLIPINTERSECTIONGEN0 = 262144;
	public const int32 D3DSTATUS_CLIPINTERSECTIONGEN1 = 524288;
	public const int32 D3DSTATUS_CLIPINTERSECTIONGEN2 = 1048576;
	public const int32 D3DSTATUS_CLIPINTERSECTIONGEN3 = 2097152;
	public const int32 D3DSTATUS_CLIPINTERSECTIONGEN4 = 4194304;
	public const int32 D3DSTATUS_CLIPINTERSECTIONGEN5 = 8388608;
	public const int32 D3DSTATUS_ZNOTVISIBLE = 16777216;
	public const int32 D3DTRANSFORM_CLIPPED = 1;
	public const int32 D3DTRANSFORM_UNCLIPPED = 2;
	public const uint32 D3DLIGHT_ACTIVE = 1;
	public const uint32 D3DLIGHT_NO_SPECULAR = 2;
	public const uint32 D3DCOLOR_MONO = 1;
	public const uint32 D3DCOLOR_RGB = 2;
	public const int32 D3DCLEAR_TARGET = 1;
	public const int32 D3DCLEAR_ZBUFFER = 2;
	public const int32 D3DCLEAR_STENCIL = 4;
	public const uint32 D3DSTATE_OVERRIDE_BIAS = 256;
	public const uint32 D3DRENDERSTATE_WRAPBIAS = 128;
	public const int32 D3DWRAP_U = 1;
	public const int32 D3DWRAP_V = 2;
	public const int32 D3DWRAPCOORD_0 = 1;
	public const int32 D3DWRAPCOORD_1 = 2;
	public const int32 D3DWRAPCOORD_2 = 4;
	public const int32 D3DWRAPCOORD_3 = 8;
	public const int32 D3DPROCESSVERTICES_TRANSFORMLIGHT = 0;
	public const int32 D3DPROCESSVERTICES_TRANSFORM = 1;
	public const int32 D3DPROCESSVERTICES_COPY = 2;
	public const int32 D3DPROCESSVERTICES_OPMASK = 7;
	public const int32 D3DPROCESSVERTICES_UPDATEEXTENTS = 8;
	public const int32 D3DPROCESSVERTICES_NOCOLOR = 16;
	public const uint32 D3DTSS_TCI_PASSTHRU = 0;
	public const uint32 D3DTSS_TCI_CAMERASPACENORMAL = 65536;
	public const uint32 D3DTSS_TCI_CAMERASPACEPOSITION = 131072;
	public const uint32 D3DTSS_TCI_CAMERASPACEREFLECTIONVECTOR = 196608;
	public const uint32 D3DTA_SELECTMASK = 15;
	public const uint32 D3DTA_DIFFUSE = 0;
	public const uint32 D3DTA_CURRENT = 1;
	public const uint32 D3DTA_TEXTURE = 2;
	public const uint32 D3DTA_TFACTOR = 3;
	public const uint32 D3DTA_SPECULAR = 4;
	public const uint32 D3DTA_COMPLEMENT = 16;
	public const uint32 D3DTA_ALPHAREPLICATE = 32;
	public const int32 D3DTRIFLAG_START = 0;
	public const int32 D3DTRIFLAG_ODD = 30;
	public const int32 D3DTRIFLAG_EVEN = 31;
	public const int32 D3DTRIFLAG_EDGEENABLE1 = 256;
	public const int32 D3DTRIFLAG_EDGEENABLE2 = 512;
	public const int32 D3DTRIFLAG_EDGEENABLE3 = 1024;
	public const int32 D3DSETSTATUS_STATUS = 1;
	public const int32 D3DSETSTATUS_EXTENTS = 2;
	public const int32 D3DCLIPSTATUS_STATUS = 1;
	public const int32 D3DCLIPSTATUS_EXTENTS2 = 2;
	public const int32 D3DCLIPSTATUS_EXTENTS3 = 4;
	public const int32 D3DEXECUTE_CLIPPED = 1;
	public const int32 D3DEXECUTE_UNCLIPPED = 2;
	public const uint32 D3DPAL_FREE = 0;
	public const uint32 D3DPAL_READONLY = 64;
	public const uint32 D3DPAL_RESERVED = 128;
	public const int32 D3DVBCAPS_SYSTEMMEMORY = 2048;
	public const int32 D3DVBCAPS_WRITEONLY = 65536;
	public const int32 D3DVBCAPS_OPTIMIZED = -2147483648;
	public const int32 D3DVBCAPS_DONOTCLIP = 1;
	public const uint32 D3DVOP_LIGHT = 1024;
	public const uint32 D3DVOP_TRANSFORM = 1;
	public const uint32 D3DVOP_CLIP = 4;
	public const uint32 D3DVOP_EXTENTS = 8;
	public const uint32 D3DPV_DONOTCOPYDATA = 1;
	public const uint32 D3DFVF_RESERVED0 = 1;
	public const uint32 D3DFVF_POSITION_MASK = 14;
	public const uint32 D3DFVF_XYZ = 2;
	public const uint32 D3DFVF_XYZRHW = 4;
	public const uint32 D3DFVF_XYZB1 = 6;
	public const uint32 D3DFVF_XYZB2 = 8;
	public const uint32 D3DFVF_XYZB3 = 10;
	public const uint32 D3DFVF_XYZB4 = 12;
	public const uint32 D3DFVF_XYZB5 = 14;
	public const uint32 D3DFVF_NORMAL = 16;
	public const uint32 D3DFVF_RESERVED1 = 32;
	public const uint32 D3DFVF_DIFFUSE = 64;
	public const uint32 D3DFVF_SPECULAR = 128;
	public const uint32 D3DFVF_TEXCOUNT_MASK = 3840;
	public const uint32 D3DFVF_TEXCOUNT_SHIFT = 8;
	public const uint32 D3DFVF_TEX0 = 0;
	public const uint32 D3DFVF_TEX1 = 256;
	public const uint32 D3DFVF_TEX2 = 512;
	public const uint32 D3DFVF_TEX3 = 768;
	public const uint32 D3DFVF_TEX4 = 1024;
	public const uint32 D3DFVF_TEX5 = 1280;
	public const uint32 D3DFVF_TEX6 = 1536;
	public const uint32 D3DFVF_TEX7 = 1792;
	public const uint32 D3DFVF_TEX8 = 2048;
	public const uint32 D3DFVF_RESERVED2 = 61440;
	public const uint32 D3DDP_MAXTEXCOORD = 8;
	public const uint32 D3DVIS_INSIDE_FRUSTUM = 0;
	public const uint32 D3DVIS_INTERSECT_FRUSTUM = 1;
	public const uint32 D3DVIS_OUTSIDE_FRUSTUM = 2;
	public const uint32 D3DVIS_INSIDE_LEFT = 0;
	public const uint32 D3DVIS_INTERSECT_LEFT = 4;
	public const uint32 D3DVIS_OUTSIDE_LEFT = 8;
	public const uint32 D3DVIS_INSIDE_RIGHT = 0;
	public const uint32 D3DVIS_INTERSECT_RIGHT = 16;
	public const uint32 D3DVIS_OUTSIDE_RIGHT = 32;
	public const uint32 D3DVIS_INSIDE_TOP = 0;
	public const uint32 D3DVIS_INTERSECT_TOP = 64;
	public const uint32 D3DVIS_OUTSIDE_TOP = 128;
	public const uint32 D3DVIS_INSIDE_BOTTOM = 0;
	public const uint32 D3DVIS_INTERSECT_BOTTOM = 256;
	public const uint32 D3DVIS_OUTSIDE_BOTTOM = 512;
	public const uint32 D3DVIS_INSIDE_NEAR = 0;
	public const uint32 D3DVIS_INTERSECT_NEAR = 1024;
	public const uint32 D3DVIS_OUTSIDE_NEAR = 2048;
	public const uint32 D3DVIS_INSIDE_FAR = 0;
	public const uint32 D3DVIS_INTERSECT_FAR = 4096;
	public const uint32 D3DVIS_OUTSIDE_FAR = 8192;
	public const uint32 D3DVIS_MASK_FRUSTUM = 3;
	public const uint32 D3DVIS_MASK_LEFT = 12;
	public const uint32 D3DVIS_MASK_RIGHT = 48;
	public const uint32 D3DVIS_MASK_TOP = 192;
	public const uint32 D3DVIS_MASK_BOTTOM = 768;
	public const uint32 D3DVIS_MASK_NEAR = 3072;
	public const uint32 D3DVIS_MASK_FAR = 12288;
	public const uint32 D3DDEVINFOID_TEXTUREMANAGER = 1;
	public const uint32 D3DDEVINFOID_D3DTEXTUREMANAGER = 2;
	public const uint32 D3DDEVINFOID_TEXTURING = 3;
	public const uint32 D3DFVF_TEXTUREFORMAT2 = 0;
	public const uint32 D3DFVF_TEXTUREFORMAT1 = 3;
	public const uint32 D3DFVF_TEXTUREFORMAT3 = 1;
	public const uint32 D3DFVF_TEXTUREFORMAT4 = 2;
	public const uint32 ROT_COMPARE_MAX = 2048;
	public const uint32 WDT_INPROC_CALL = 1215587415;
	public const uint32 WDT_REMOTE_CALL = 1383359575;
	public const uint32 WDT_INPROC64_CALL = 1349805143;
	public const uint32 PROCESS_HEAP_REGION = 1;
	public const uint32 PROCESS_HEAP_UNCOMMITTED_RANGE = 2;
	public const uint32 PROCESS_HEAP_ENTRY_BUSY = 4;
	public const uint32 PROCESS_HEAP_SEG_ALLOC = 8;
	public const uint32 PROCESS_HEAP_ENTRY_MOVEABLE = 16;
	public const uint32 PROCESS_HEAP_ENTRY_DDESHARE = 32;
	public const uint32 LMEM_NOCOMPACT = 16;
	public const uint32 LMEM_NODISCARD = 32;
	public const uint32 LMEM_MODIFY = 128;
	public const uint32 LMEM_DISCARDABLE = 3840;
	public const uint32 LMEM_VALID_FLAGS = 3954;
	public const uint32 LMEM_INVALID_HANDLE = 32768;
	public const uint32 LMEM_DISCARDED = 16384;
	public const uint32 LMEM_LOCKCOUNT = 255;
	public const uint32 NUMA_NO_PREFERRED_NODE = 4294967295;
	public const uint32 REDBOOK_DIGITAL_AUDIO_EXTRACTION_INFO_VERSION = 1;
	public const uint32 FACILITY_MCA_ERROR_CODE = 5;
	public const NTSTATUS IO_ERR_INSUFFICIENT_RESOURCES = -1073479678;
	public const NTSTATUS IO_ERR_DRIVER_ERROR = -1073479676;
	public const NTSTATUS IO_ERR_SEEK_ERROR = -1073479674;
	public const NTSTATUS IO_ERR_BAD_BLOCK = -1073479673;
	public const NTSTATUS IO_ERR_TIMEOUT = -1073479671;
	public const NTSTATUS IO_ERR_CONTROLLER_ERROR = -1073479669;
	public const NTSTATUS IO_ERR_NOT_READY = -1073479665;
	public const NTSTATUS IO_ERR_INVALID_REQUEST = -1073479664;
	public const NTSTATUS IO_ERR_RESET = -1073479661;
	public const NTSTATUS IO_ERR_BAD_FIRMWARE = -1073479655;
	public const NTSTATUS IO_WRN_BAD_FIRMWARE = -2147221478;
	public const NTSTATUS IO_WRITE_CACHE_ENABLED = -2147221472;
	public const NTSTATUS IO_RECOVERED_VIA_ECC = -2147221471;
	public const NTSTATUS IO_WRITE_CACHE_DISABLED = -2147221470;
	public const NTSTATUS IO_WARNING_PAGING_FAILURE = -2147221453;
	public const NTSTATUS IO_WRN_FAILURE_PREDICTED = -2147221452;
	public const NTSTATUS IO_WARNING_ALLOCATION_FAILED = -2147221448;
	public const NTSTATUS IO_WARNING_DUPLICATE_SIGNATURE = -2147221446;
	public const NTSTATUS IO_WARNING_DUPLICATE_PATH = -2147221445;
	public const NTSTATUS IO_WARNING_WRITE_FUA_PROBLEM = -2147221372;
	public const NTSTATUS IO_WARNING_VOLUME_LOST_DISK_EXTENT = -2147221362;
	public const NTSTATUS IO_WARNING_DEVICE_HAS_INTERNAL_DUMP = -2147221361;
	public const NTSTATUS IO_WARNING_SOFT_THRESHOLD_REACHED = -2147221360;
	public const NTSTATUS IO_WARNING_SOFT_THRESHOLD_REACHED_EX = -2147221359;
	public const NTSTATUS IO_WARNING_SOFT_THRESHOLD_REACHED_EX_LUN_LUN = -2147221358;
	public const NTSTATUS IO_WARNING_SOFT_THRESHOLD_REACHED_EX_LUN_POOL = -2147221357;
	public const NTSTATUS IO_WARNING_SOFT_THRESHOLD_REACHED_EX_POOL_LUN = -2147221356;
	public const NTSTATUS IO_WARNING_SOFT_THRESHOLD_REACHED_EX_POOL_POOL = -2147221355;
	public const NTSTATUS IO_ERROR_DISK_RESOURCES_EXHAUSTED = -1073479530;
	public const NTSTATUS IO_WARNING_DISK_CAPACITY_CHANGED = -2147221353;
	public const NTSTATUS IO_WARNING_DISK_PROVISIONING_TYPE_CHANGED = -2147221352;
	public const NTSTATUS IO_WARNING_IO_OPERATION_RETRIED = -2147221351;
	public const NTSTATUS IO_ERROR_IO_HARDWARE_ERROR = -1073479526;
	public const NTSTATUS IO_WARNING_COMPLETION_TIME = -2147221349;
	public const NTSTATUS IO_WARNING_DISK_SURPRISE_REMOVED = -2147221347;
	public const NTSTATUS IO_WARNING_REPEATED_DISK_GUID = -2147221346;
	public const NTSTATUS IO_WARNING_DISK_FIRMWARE_UPDATED = 1074004127;
	public const NTSTATUS IO_ERR_RETRY_SUCCEEDED = 262145;
	public const NTSTATUS IO_DUMP_CREATION_SUCCESS = 262306;
	public const NTSTATUS IO_FILE_QUOTA_THRESHOLD = 1074004004;
	public const NTSTATUS IO_FILE_QUOTA_LIMIT = 1074004005;
	public const NTSTATUS IO_FILE_QUOTA_STARTED = 1074004006;
	public const NTSTATUS IO_FILE_QUOTA_SUCCEEDED = 1074004007;
	public const NTSTATUS IO_INFO_THROTTLE_COMPLETE = 1074004087;
	public const NTSTATUS IO_CDROM_EXCLUSIVE_LOCK = 1074004101;
	public const NTSTATUS IO_WARNING_ADAPTER_FIRMWARE_UPDATED = 1074004128;
	public const NTSTATUS IO_FILE_QUOTA_FAILED = -2147221464;
	public const NTSTATUS IO_LOST_DELAYED_WRITE = -2147221454;
	public const NTSTATUS IO_WARNING_INTERRUPT_STILL_PENDING = -2147221451;
	public const NTSTATUS IO_DRIVER_CANCEL_TIMEOUT = -2147221450;
	public const NTSTATUS IO_WARNING_LOG_FLUSH_FAILED = -2147221447;
	public const NTSTATUS IO_WARNING_BUS_RESET = -2147221386;
	public const NTSTATUS IO_WARNING_RESET = -2147221375;
	public const NTSTATUS IO_LOST_DELAYED_WRITE_NETWORK_DISCONNECTED = -2147221365;
	public const NTSTATUS IO_LOST_DELAYED_WRITE_NETWORK_SERVER_ERROR = -2147221364;
	public const NTSTATUS IO_LOST_DELAYED_WRITE_NETWORK_LOCAL_DISK_ERROR = -2147221363;
	public const NTSTATUS IO_WARNING_DUMP_DISABLED_DEVICE_GONE = -2147221348;
	public const NTSTATUS IO_ERR_CONFIGURATION_ERROR = -1073479677;
	public const NTSTATUS IO_ERR_PARITY = -1073479675;
	public const NTSTATUS IO_ERR_OVERRUN_ERROR = -1073479672;
	public const NTSTATUS IO_ERR_SEQUENCE = -1073479670;
	public const NTSTATUS IO_ERR_INTERNAL_ERROR = -1073479668;
	public const NTSTATUS IO_ERR_INCORRECT_IRQL = -1073479667;
	public const NTSTATUS IO_ERR_INVALID_IOBASE = -1073479666;
	public const NTSTATUS IO_ERR_VERSION = -1073479663;
	public const NTSTATUS IO_ERR_LAYERED_FAILURE = -1073479662;
	public const NTSTATUS IO_ERR_PROTOCOL = -1073479660;
	public const NTSTATUS IO_ERR_MEMORY_CONFLICT_DETECTED = -1073479659;
	public const NTSTATUS IO_ERR_PORT_CONFLICT_DETECTED = -1073479658;
	public const NTSTATUS IO_ERR_DMA_CONFLICT_DETECTED = -1073479657;
	public const NTSTATUS IO_ERR_IRQ_CONFLICT_DETECTED = -1073479656;
	public const NTSTATUS IO_ERR_DMA_RESOURCE_CONFLICT = -1073479653;
	public const NTSTATUS IO_ERR_INTERRUPT_RESOURCE_CONFLICT = -1073479652;
	public const NTSTATUS IO_ERR_MEMORY_RESOURCE_CONFLICT = -1073479651;
	public const NTSTATUS IO_ERR_PORT_RESOURCE_CONFLICT = -1073479650;
	public const NTSTATUS IO_BAD_BLOCK_WITH_NAME = -1073479649;
	public const NTSTATUS IO_FILE_SYSTEM_CORRUPT = -1073479639;
	public const NTSTATUS IO_FILE_QUOTA_CORRUPT = -1073479638;
	public const NTSTATUS IO_SYSTEM_SLEEP_FAILED = -1073479637;
	public const NTSTATUS IO_DUMP_POINTER_FAILURE = -1073479636;
	public const NTSTATUS IO_DUMP_DRIVER_LOAD_FAILURE = -1073479635;
	public const NTSTATUS IO_DUMP_INITIALIZATION_FAILURE = -1073479634;
	public const NTSTATUS IO_DUMP_DUMPFILE_CONFLICT = -1073479633;
	public const NTSTATUS IO_DUMP_DIRECT_CONFIG_FAILED = -1073479632;
	public const NTSTATUS IO_DUMP_PAGE_CONFIG_FAILED = -1073479631;
	public const NTSTATUS IO_FILE_SYSTEM_CORRUPT_WITH_NAME = -1073479625;
	public const NTSTATUS IO_ERR_THREAD_STUCK_IN_DEVICE_DRIVER = -1073479572;
	public const NTSTATUS IO_ERR_PORT_TIMEOUT = -1073479563;
	public const NTSTATUS IO_ERROR_DUMP_CREATION_ERROR = -1073479519;
	public const NTSTATUS IO_DUMP_CALLBACK_EXCEPTION = -1073479517;
	public const NTSTATUS MCA_INFO_CPU_THERMAL_THROTTLING_REMOVED = 1074069616;
	public const NTSTATUS MCA_INFO_NO_MORE_CORRECTED_ERROR_LOGS = 1074069619;
	public const NTSTATUS MCA_INFO_MEMORY_PAGE_MARKED_BAD = 1074069620;
	public const NTSTATUS MCA_WARNING_CACHE = -2147155908;
	public const NTSTATUS MCA_WARNING_TLB = -2147155906;
	public const NTSTATUS MCA_WARNING_CPU_BUS = -2147155904;
	public const NTSTATUS MCA_WARNING_REGISTER_FILE = -2147155902;
	public const NTSTATUS MCA_WARNING_MAS = -2147155900;
	public const NTSTATUS MCA_WARNING_MEM_UNKNOWN = -2147155898;
	public const NTSTATUS MCA_WARNING_MEM_1_2 = -2147155896;
	public const NTSTATUS MCA_WARNING_MEM_1_2_5 = -2147155894;
	public const NTSTATUS MCA_WARNING_MEM_1_2_5_4 = -2147155892;
	public const NTSTATUS MCA_WARNING_SYSTEM_EVENT = -2147155890;
	public const NTSTATUS MCA_WARNING_PCI_BUS_PARITY = -2147155888;
	public const NTSTATUS MCA_WARNING_PCI_BUS_PARITY_NO_INFO = -2147155886;
	public const NTSTATUS MCA_WARNING_PCI_BUS_SERR = -2147155884;
	public const NTSTATUS MCA_WARNING_PCI_BUS_SERR_NO_INFO = -2147155882;
	public const NTSTATUS MCA_WARNING_PCI_BUS_MASTER_ABORT = -2147155880;
	public const NTSTATUS MCA_WARNING_PCI_BUS_MASTER_ABORT_NO_INFO = -2147155878;
	public const NTSTATUS MCA_WARNING_PCI_BUS_TIMEOUT = -2147155876;
	public const NTSTATUS MCA_WARNING_PCI_BUS_TIMEOUT_NO_INFO = -2147155874;
	public const NTSTATUS MCA_WARNING_PCI_BUS_UNKNOWN = -2147155872;
	public const NTSTATUS MCA_WARNING_PCI_DEVICE = -2147155870;
	public const NTSTATUS MCA_WARNING_SMBIOS = -2147155868;
	public const NTSTATUS MCA_WARNING_PLATFORM_SPECIFIC = -2147155866;
	public const NTSTATUS MCA_WARNING_UNKNOWN = -2147155864;
	public const NTSTATUS MCA_WARNING_UNKNOWN_NO_CPU = -2147155862;
	public const NTSTATUS MCA_WARNING_CMC_THRESHOLD_EXCEEDED = -2147155859;
	public const NTSTATUS MCA_WARNING_CPE_THRESHOLD_EXCEEDED = -2147155858;
	public const NTSTATUS MCA_WARNING_CPU_THERMAL_THROTTLED = -2147155857;
	public const NTSTATUS MCA_WARNING_CPU = -2147155855;
	public const NTSTATUS MCA_ERROR_CACHE = -1073414083;
	public const NTSTATUS MCA_ERROR_TLB = -1073414081;
	public const NTSTATUS MCA_ERROR_CPU_BUS = -1073414079;
	public const NTSTATUS MCA_ERROR_REGISTER_FILE = -1073414077;
	public const NTSTATUS MCA_ERROR_MAS = -1073414075;
	public const NTSTATUS MCA_ERROR_MEM_UNKNOWN = -1073414073;
	public const NTSTATUS MCA_ERROR_MEM_1_2 = -1073414071;
	public const NTSTATUS MCA_ERROR_MEM_1_2_5 = -1073414069;
	public const NTSTATUS MCA_ERROR_MEM_1_2_5_4 = -1073414067;
	public const NTSTATUS MCA_ERROR_SYSTEM_EVENT = -1073414065;
	public const NTSTATUS MCA_ERROR_PCI_BUS_PARITY = -1073414063;
	public const NTSTATUS MCA_ERROR_PCI_BUS_PARITY_NO_INFO = -1073414061;
	public const NTSTATUS MCA_ERROR_PCI_BUS_SERR = -1073414059;
	public const NTSTATUS MCA_ERROR_PCI_BUS_SERR_NO_INFO = -1073414057;
	public const NTSTATUS MCA_ERROR_PCI_BUS_MASTER_ABORT = -1073414055;
	public const NTSTATUS MCA_ERROR_PCI_BUS_MASTER_ABORT_NO_INFO = -1073414053;
	public const NTSTATUS MCA_ERROR_PCI_BUS_TIMEOUT = -1073414051;
	public const NTSTATUS MCA_ERROR_PCI_BUS_TIMEOUT_NO_INFO = -1073414049;
	public const NTSTATUS MCA_ERROR_PCI_BUS_UNKNOWN = -1073414047;
	public const NTSTATUS MCA_ERROR_PCI_DEVICE = -1073414045;
	public const NTSTATUS MCA_ERROR_SMBIOS = -1073414043;
	public const NTSTATUS MCA_ERROR_PLATFORM_SPECIFIC = -1073414041;
	public const NTSTATUS MCA_ERROR_UNKNOWN = -1073414039;
	public const NTSTATUS MCA_ERROR_UNKNOWN_NO_CPU = -1073414037;
	public const NTSTATUS MCA_ERROR_CPU = -1073414030;
	public const NTSTATUS MCA_MEMORYHIERARCHY_ERROR = -1073414024;
	public const NTSTATUS MCA_TLB_ERROR = -1073414023;
	public const NTSTATUS MCA_BUS_ERROR = -1073414022;
	public const NTSTATUS MCA_BUS_TIMEOUT_ERROR = -1073414021;
	public const NTSTATUS MCA_INTERNALTIMER_ERROR = -1073414020;
	public const NTSTATUS MCA_MICROCODE_ROM_PARITY_ERROR = -1073414018;
	public const NTSTATUS MCA_EXTERNAL_ERROR = -1073414017;
	public const NTSTATUS MCA_FRC_ERROR = -1073414016;
	public const NTSTATUS VOLMGR_KSR_ERROR = -2143813631;
	public const NTSTATUS VOLMGR_KSR_READ_ERROR = -2143813630;
	public const NTSTATUS VOLMGR_KSR_BYPASS = -2143813629;
	public const Guid GUID_DEVINTERFACE_DMR = .(0xd0875fb4, 0x2196, 0x4c7a, 0xa6, 0x3d, 0xe4, 0x16, 0xad, 0xdd, 0x60, 0xa1);
	public const Guid GUID_DEVINTERFACE_DMP = .(0x25b4e268, 0x2a05, 0x496e, 0x80, 0x3b, 0x26, 0x68, 0x37, 0xfb, 0xda, 0x4b);
	public const Guid GUID_DEVINTERFACE_DMS = .(0xc96037ae, 0xa558, 0x4470, 0xb4, 0x32, 0x11, 0x5a, 0x31, 0xb8, 0x55, 0x53);
}
#endregion

#region Enums

[AllowDuplicates]
public enum ALERT_SYSTEM_SEV : uint32
{
	ALERT_SYSTEM_INFORMATIONAL = 1,
	ALERT_SYSTEM_WARNING = 2,
	ALERT_SYSTEM_ERROR = 3,
	ALERT_SYSTEM_QUERY = 4,
	ALERT_SYSTEM_CRITICAL = 5,
}


[AllowDuplicates]
public enum APPCOMMAND_ID : uint32
{
	APPCOMMAND_BROWSER_BACKWARD = 1,
	APPCOMMAND_BROWSER_FORWARD = 2,
	APPCOMMAND_BROWSER_REFRESH = 3,
	APPCOMMAND_BROWSER_STOP = 4,
	APPCOMMAND_BROWSER_SEARCH = 5,
	APPCOMMAND_BROWSER_FAVORITES = 6,
	APPCOMMAND_BROWSER_HOME = 7,
	APPCOMMAND_VOLUME_MUTE = 8,
	APPCOMMAND_VOLUME_DOWN = 9,
	APPCOMMAND_VOLUME_UP = 10,
	APPCOMMAND_MEDIA_NEXTTRACK = 11,
	APPCOMMAND_MEDIA_PREVIOUSTRACK = 12,
	APPCOMMAND_MEDIA_STOP = 13,
	APPCOMMAND_MEDIA_PLAY_PAUSE = 14,
	APPCOMMAND_LAUNCH_MAIL = 15,
	APPCOMMAND_LAUNCH_MEDIA_SELECT = 16,
	APPCOMMAND_LAUNCH_APP1 = 17,
	APPCOMMAND_LAUNCH_APP2 = 18,
	APPCOMMAND_BASS_DOWN = 19,
	APPCOMMAND_BASS_BOOST = 20,
	APPCOMMAND_BASS_UP = 21,
	APPCOMMAND_TREBLE_DOWN = 22,
	APPCOMMAND_TREBLE_UP = 23,
	APPCOMMAND_MICROPHONE_VOLUME_MUTE = 24,
	APPCOMMAND_MICROPHONE_VOLUME_DOWN = 25,
	APPCOMMAND_MICROPHONE_VOLUME_UP = 26,
	APPCOMMAND_HELP = 27,
	APPCOMMAND_FIND = 28,
	APPCOMMAND_NEW = 29,
	APPCOMMAND_OPEN = 30,
	APPCOMMAND_CLOSE = 31,
	APPCOMMAND_SAVE = 32,
	APPCOMMAND_PRINT = 33,
	APPCOMMAND_UNDO = 34,
	APPCOMMAND_REDO = 35,
	APPCOMMAND_COPY = 36,
	APPCOMMAND_CUT = 37,
	APPCOMMAND_PASTE = 38,
	APPCOMMAND_REPLY_TO_MAIL = 39,
	APPCOMMAND_FORWARD_MAIL = 40,
	APPCOMMAND_SEND_MAIL = 41,
	APPCOMMAND_SPELL_CHECK = 42,
	APPCOMMAND_DICTATE_OR_COMMAND_CONTROL_TOGGLE = 43,
	APPCOMMAND_MIC_ON_OFF_TOGGLE = 44,
	APPCOMMAND_CORRECTION_LIST = 45,
	APPCOMMAND_MEDIA_PLAY = 46,
	APPCOMMAND_MEDIA_PAUSE = 47,
	APPCOMMAND_MEDIA_RECORD = 48,
	APPCOMMAND_MEDIA_FAST_FORWARD = 49,
	APPCOMMAND_MEDIA_REWIND = 50,
	APPCOMMAND_MEDIA_CHANNEL_UP = 51,
	APPCOMMAND_MEDIA_CHANNEL_DOWN = 52,
	APPCOMMAND_DELETE = 53,
	APPCOMMAND_DWM_FLIP3D = 54,
}


[AllowDuplicates]
public enum ATF_FLAGS : uint32
{
	ATF_TIMEOUTON = 1,
	ATF_ONOFFFEEDBACK = 2,
}


[AllowDuplicates]
public enum CLIPBOARD_FORMATS : uint32
{
	CF_TEXT = 1,
	CF_BITMAP = 2,
	CF_METAFILEPICT = 3,
	CF_SYLK = 4,
	CF_DIF = 5,
	CF_TIFF = 6,
	CF_OEMTEXT = 7,
	CF_DIB = 8,
	CF_PALETTE = 9,
	CF_PENDATA = 10,
	CF_RIFF = 11,
	CF_WAVE = 12,
	CF_UNICODETEXT = 13,
	CF_ENHMETAFILE = 14,
	CF_HDROP = 15,
	CF_LOCALE = 16,
	CF_DIBV5 = 17,
	CF_MAX = 18,
	CF_OWNERDISPLAY = 128,
	CF_DSPTEXT = 129,
	CF_DSPBITMAP = 130,
	CF_DSPMETAFILEPICT = 131,
	CF_DSPENHMETAFILE = 142,
	CF_PRIVATEFIRST = 512,
	CF_PRIVATELAST = 767,
	CF_GDIOBJFIRST = 768,
	CF_GDIOBJLAST = 1023,
}


[AllowDuplicates]
public enum GESTURECONFIG_FLAGS : uint32
{
	GC_ALLGESTURES = 1,
	GC_ZOOM = 1,
	GC_PAN = 1,
	GC_PAN_WITH_SINGLE_FINGER_VERTICALLY = 2,
	GC_PAN_WITH_SINGLE_FINGER_HORIZONTALLY = 4,
	GC_PAN_WITH_GUTTER = 8,
	GC_PAN_WITH_INERTIA = 16,
	GC_ROTATE = 1,
	GC_TWOFINGERTAP = 1,
	GC_PRESSANDTAP = 1,
	GC_ROLLOVER = 1,
}


[AllowDuplicates]
public enum CFE_UNDERLINE : uint32
{
	CFU_CF1UNDERLINE = 255,
	CFU_INVERT = 254,
	CFU_UNDERLINETHICKLONGDASH = 18,
	CFU_UNDERLINETHICKDOTTED = 17,
	CFU_UNDERLINETHICKDASHDOTDOT = 16,
	CFU_UNDERLINETHICKDASHDOT = 15,
	CFU_UNDERLINETHICKDASH = 14,
	CFU_UNDERLINELONGDASH = 13,
	CFU_UNDERLINEHEAVYWAVE = 12,
	CFU_UNDERLINEDOUBLEWAVE = 11,
	CFU_UNDERLINEHAIRLINE = 10,
	CFU_UNDERLINETHICK = 9,
	CFU_UNDERLINEWAVE = 8,
	CFU_UNDERLINEDASHDOTDOT = 7,
	CFU_UNDERLINEDASHDOT = 6,
	CFU_UNDERLINEDASH = 5,
	CFU_UNDERLINEDOTTED = 4,
	CFU_UNDERLINEDOUBLE = 3,
	CFU_UNDERLINEWORD = 2,
	CFU_UNDERLINE = 1,
	CFU_UNDERLINENONE = 0,
}


[AllowDuplicates]
public enum IGP_ID : uint32
{
	IGP_GETIMEVERSION = 4294967292,
	IGP_PROPERTY = 4,
	IGP_CONVERSION = 8,
	IGP_SENTENCE = 12,
	IGP_UI = 16,
	IGP_SETCOMPSTR = 20,
	IGP_SELECT = 24,
}


[AllowDuplicates]
public enum SECTION_FLAGS : uint32
{
	SECTION_ALL_ACCESS = 983071,
	SECTION_QUERY = 1,
	SECTION_MAP_WRITE = 2,
	SECTION_MAP_READ = 4,
	SECTION_MAP_EXECUTE = 8,
	SECTION_EXTEND_SIZE = 16,
	SECTION_MAP_EXECUTE_EXPLICIT = 32,
}


[AllowDuplicates]
public enum TAPE_GET_DRIVE_PARAMETERS_FEATURES_HIGH : uint32
{
	TAPE_DRIVE_ABS_BLK_IMMED = 2147491840,
	TAPE_DRIVE_ABSOLUTE_BLK = 2147487744,
	TAPE_DRIVE_END_OF_DATA = 2147549184,
	TAPE_DRIVE_FILEMARKS = 2147745792,
	TAPE_DRIVE_LOAD_UNLOAD = 2147483649,
	TAPE_DRIVE_LOAD_UNLD_IMMED = 2147483680,
	TAPE_DRIVE_LOCK_UNLOCK = 2147483652,
	TAPE_DRIVE_LOCK_UNLK_IMMED = 2147483776,
	TAPE_DRIVE_LOG_BLK_IMMED = 2147516416,
	TAPE_DRIVE_LOGICAL_BLK = 2147500032,
	TAPE_DRIVE_RELATIVE_BLKS = 2147614720,
	TAPE_DRIVE_REVERSE_POSITION = 2151677952,
	TAPE_DRIVE_REWIND_IMMEDIATE = 2147483656,
	TAPE_DRIVE_SEQUENTIAL_FMKS = 2148007936,
	TAPE_DRIVE_SEQUENTIAL_SMKS = 2149580800,
	TAPE_DRIVE_SET_BLOCK_SIZE = 2147483664,
	TAPE_DRIVE_SET_COMPRESSION = 2147484160,
	TAPE_DRIVE_SET_ECC = 2147483904,
	TAPE_DRIVE_SET_PADDING = 2147484672,
	TAPE_DRIVE_SET_REPORT_SMKS = 2147485696,
	TAPE_DRIVE_SETMARKS = 2148532224,
	TAPE_DRIVE_SPACE_IMMEDIATE = 2155872256,
	TAPE_DRIVE_TENSION = 2147483650,
	TAPE_DRIVE_TENSION_IMMED = 2147483712,
	TAPE_DRIVE_WRITE_FILEMARKS = 2181038080,
	TAPE_DRIVE_WRITE_LONG_FMKS = 2281701376,
	TAPE_DRIVE_WRITE_MARK_IMMED = 2415919104,
	TAPE_DRIVE_WRITE_SETMARKS = 2164260864,
	TAPE_DRIVE_WRITE_SHORT_FMKS = 2214592512,
}


[AllowDuplicates]
public enum DEV_BROADCAST_HDR_DEVICE_TYPE : uint32
{
	DBT_DEVTYP_DEVICEINTERFACE = 5,
	DBT_DEVTYP_HANDLE = 6,
	DBT_DEVTYP_OEM = 0,
	DBT_DEVTYP_PORT = 3,
	DBT_DEVTYP_VOLUME = 2,
}


[AllowDuplicates]
public enum DEV_BROADCAST_VOLUME_FLAGS : uint16
{
	DBTF_MEDIA = 1,
	DBTF_NET = 2,
}


[AllowDuplicates]
public enum MODIFIERKEYS_FLAGS : uint32
{
	MK_LBUTTON = 1,
	MK_RBUTTON = 2,
	MK_SHIFT = 4,
	MK_CONTROL = 8,
	MK_MBUTTON = 16,
	MK_XBUTTON1 = 32,
	MK_XBUTTON2 = 64,
}


[AllowDuplicates]
public enum STATIC_STYLES : uint32
{
	SS_LEFT = 0,
	SS_CENTER = 1,
	SS_RIGHT = 2,
	SS_ICON = 3,
	SS_BLACKRECT = 4,
	SS_GRAYRECT = 5,
	SS_WHITERECT = 6,
	SS_BLACKFRAME = 7,
	SS_GRAYFRAME = 8,
	SS_WHITEFRAME = 9,
	SS_USERITEM = 10,
	SS_SIMPLE = 11,
	SS_LEFTNOWORDWRAP = 12,
	SS_OWNERDRAW = 13,
	SS_BITMAP = 14,
	SS_ENHMETAFILE = 15,
	SS_ETCHEDHORZ = 16,
	SS_ETCHEDVERT = 17,
	SS_ETCHEDFRAME = 18,
	SS_TYPEMASK = 31,
	SS_REALSIZECONTROL = 64,
	SS_NOPREFIX = 128,
	SS_NOTIFY = 256,
	SS_CENTERIMAGE = 512,
	SS_RIGHTJUST = 1024,
	SS_REALSIZEIMAGE = 2048,
	SS_SUNKEN = 4096,
	SS_EDITCONTROL = 8192,
	SS_ENDELLIPSIS = 16384,
	SS_PATHELLIPSIS = 32768,
	SS_WORDELLIPSIS = 49152,
	SS_ELLIPSISMASK = 49152,
}


[AllowDuplicates]
public enum RECO_FLAGS : uint32
{
	RECO_PASTE = 0,
	RECO_DROP = 1,
	RECO_COPY = 2,
	RECO_CUT = 3,
	RECO_DRAG = 4,
}


[AllowDuplicates]
public enum SFGAO_FLAGS : uint64
{
	SFGAO_CANCOPY = 1,
	SFGAO_CANMOVE = 2,
	SFGAO_CANLINK = 4,
	SFGAO_STORAGE = 8,
	SFGAO_CANRENAME = 16,
	SFGAO_CANDELETE = 32,
	SFGAO_HASPROPSHEET = 64,
	SFGAO_DROPTARGET = 256,
	SFGAO_CAPABILITYMASK = 375,
	SFGAO_PLACEHOLDER = 2048,
	SFGAO_SYSTEM = 4096,
	SFGAO_ENCRYPTED = 8192,
	SFGAO_ISSLOW = 16384,
	SFGAO_GHOSTED = 32768,
	SFGAO_LINK = 65536,
	SFGAO_SHARE = 131072,
	SFGAO_READONLY = 262144,
	SFGAO_HIDDEN = 524288,
	SFGAO_DISPLAYATTRMASK = 1032192,
	SFGAO_FILESYSANCESTOR = 268435456,
	SFGAO_FOLDER = 536870912,
	SFGAO_FILESYSTEM = 1073741824,
	SFGAO_HASSUBFOLDER = 2147483648,
	SFGAO_CONTENTSMASK = 2147483648,
	SFGAO_VALIDATE = 16777216,
	SFGAO_REMOVABLE = 33554432,
	SFGAO_COMPRESSED = 67108864,
	SFGAO_BROWSABLE = 134217728,
	SFGAO_NONENUMERATED = 1048576,
	SFGAO_NEWCONTENT = 2097152,
	SFGAO_CANMONIKER = 4194304,
	SFGAO_HASSTORAGE = 4194304,
	SFGAO_STREAM = 4194304,
	SFGAO_STORAGEANCESTOR = 8388608,
	SFGAO_STORAGECAPMASK = 1891958792,
	SFGAO_PKEYSFGAOMASK = 2164539392,
}


[AllowDuplicates]
public enum DESKTOP_ACCESS_FLAGS : uint32
{
	DESKTOP_READOBJECTS = 1,
	DESKTOP_CREATEWINDOW = 2,
	DESKTOP_CREATEMENU = 4,
	DESKTOP_HOOKCONTROL = 8,
	DESKTOP_JOURNALRECORD = 16,
	DESKTOP_JOURNALPLAYBACK = 32,
	DESKTOP_ENUMERATE = 64,
	DESKTOP_WRITEOBJECTS = 128,
	DESKTOP_SWITCHDESKTOP = 256,
}


[AllowDuplicates]
public enum ACCESS_REASON_TYPE : int32
{
	AccessReasonNone = 0,
	AccessReasonAllowedAce = 65536,
	AccessReasonDeniedAce = 131072,
	AccessReasonAllowedParentAce = 196608,
	AccessReasonDeniedParentAce = 262144,
	AccessReasonNotGrantedByCape = 327680,
	AccessReasonNotGrantedByParentCape = 393216,
	AccessReasonNotGrantedToAppContainer = 458752,
	AccessReasonMissingPrivilege = 1048576,
	AccessReasonFromPrivilege = 2097152,
	AccessReasonIntegrityLevel = 3145728,
	AccessReasonOwnership = 4194304,
	AccessReasonNullDacl = 5242880,
	AccessReasonEmptyDacl = 6291456,
	AccessReasonNoSD = 7340032,
	AccessReasonNoGrant = 8388608,
	AccessReasonTrustLabel = 9437184,
	AccessReasonFilterAce = 10485760,
}


[AllowDuplicates]
public enum SE_IMAGE_SIGNATURE_TYPE : int32
{
	SeImageSignatureNone = 0,
	SeImageSignatureEmbedded = 1,
	SeImageSignatureCache = 2,
	SeImageSignatureCatalogCached = 3,
	SeImageSignatureCatalogNotCached = 4,
	SeImageSignatureCatalogHint = 5,
	SeImageSignaturePackageCatalog = 6,
	SeImageSignaturePplMitigated = 7,
}


[AllowDuplicates]
public enum SE_LEARNING_MODE_DATA_TYPE : int32
{
	SeLearningModeInvalidType = 0,
	SeLearningModeSettings = 1,
	SeLearningModeMax = 2,
}


[AllowDuplicates]
public enum SERVERSILO_STATE : int32
{
	SERVERSILO_INITING = 0,
	SERVERSILO_STARTED = 1,
	SERVERSILO_SHUTTING_DOWN = 2,
	SERVERSILO_TERMINATING = 3,
	SERVERSILO_TERMINATED = 4,
}


[AllowDuplicates]
public enum MEM_DEDICATED_ATTRIBUTE_TYPE : int32
{
	MemDedicatedAttributeReadBandwidth = 0,
	MemDedicatedAttributeReadLatency = 1,
	MemDedicatedAttributeWriteBandwidth = 2,
	MemDedicatedAttributeWriteLatency = 3,
	MemDedicatedAttributeMax = 4,
}


[AllowDuplicates]
public enum MEM_SECTION_EXTENDED_PARAMETER_TYPE : int32
{
	MemSectionExtendedParameterInvalidType = 0,
	MemSectionExtendedParameterUserPhysicalFlags = 1,
	MemSectionExtendedParameterNumaNode = 2,
	MemSectionExtendedParameterSigningLevel = 3,
	MemSectionExtendedParameterMax = 4,
}


[AllowDuplicates]
public enum SharedVirtualDiskSupportType : int32
{
	SharedVirtualDisksUnsupported = 0,
	SharedVirtualDisksSupported = 1,
	SharedVirtualDiskSnapshotsSupported = 3,
	SharedVirtualDiskCDPSnapshotsSupported = 7,
}


[AllowDuplicates]
public enum SharedVirtualDiskHandleState : int32
{
	SharedVirtualDiskHandleStateNone = 0,
	SharedVirtualDiskHandleStateFileShared = 1,
	SharedVirtualDiskHandleStateHandleShared = 3,
}


[AllowDuplicates]
public enum MONITOR_DISPLAY_STATE : int32
{
	PowerMonitorOff = 0,
	PowerMonitorOn = 1,
	PowerMonitorDim = 2,
}


[AllowDuplicates]
public enum USER_ACTIVITY_PRESENCE : int32
{
	PowerUserPresent = 0,
	PowerUserNotPresent = 1,
	PowerUserInactive = 2,
	PowerUserMaximum = 3,
	PowerUserInvalid = 3,
}


[AllowDuplicates]
public enum POWER_USER_PRESENCE_TYPE : int32
{
	UserNotPresent = 0,
	UserPresent = 1,
	UserUnknown = 255,
}


[AllowDuplicates]
public enum POWER_MONITOR_REQUEST_REASON : int32
{
	MonitorRequestReasonUnknown = 0,
	MonitorRequestReasonPowerButton = 1,
	MonitorRequestReasonRemoteConnection = 2,
	MonitorRequestReasonScMonitorpower = 3,
	MonitorRequestReasonUserInput = 4,
	MonitorRequestReasonAcDcDisplayBurst = 5,
	MonitorRequestReasonUserDisplayBurst = 6,
	MonitorRequestReasonPoSetSystemState = 7,
	MonitorRequestReasonSetThreadExecutionState = 8,
	MonitorRequestReasonFullWake = 9,
	MonitorRequestReasonSessionUnlock = 10,
	MonitorRequestReasonScreenOffRequest = 11,
	MonitorRequestReasonIdleTimeout = 12,
	MonitorRequestReasonPolicyChange = 13,
	MonitorRequestReasonSleepButton = 14,
	MonitorRequestReasonLid = 15,
	MonitorRequestReasonBatteryCountChange = 16,
	MonitorRequestReasonGracePeriod = 17,
	MonitorRequestReasonPnP = 18,
	MonitorRequestReasonDP = 19,
	MonitorRequestReasonSxTransition = 20,
	MonitorRequestReasonSystemIdle = 21,
	MonitorRequestReasonNearProximity = 22,
	MonitorRequestReasonThermalStandby = 23,
	MonitorRequestReasonResumePdc = 24,
	MonitorRequestReasonResumeS4 = 25,
	MonitorRequestReasonTerminal = 26,
	MonitorRequestReasonPdcSignal = 27,
	MonitorRequestReasonAcDcDisplayBurstSuppressed = 28,
	MonitorRequestReasonSystemStateEntered = 29,
	MonitorRequestReasonWinrt = 30,
	MonitorRequestReasonUserInputKeyboard = 31,
	MonitorRequestReasonUserInputMouse = 32,
	MonitorRequestReasonUserInputTouchpad = 33,
	MonitorRequestReasonUserInputPen = 34,
	MonitorRequestReasonUserInputAccelerometer = 35,
	MonitorRequestReasonUserInputHid = 36,
	MonitorRequestReasonUserInputPoUserPresent = 37,
	MonitorRequestReasonUserInputSessionSwitch = 38,
	MonitorRequestReasonUserInputInitialization = 39,
	MonitorRequestReasonPdcSignalWindowsMobilePwrNotif = 40,
	MonitorRequestReasonPdcSignalWindowsMobileShell = 41,
	MonitorRequestReasonPdcSignalHeyCortana = 42,
	MonitorRequestReasonPdcSignalHolographicShell = 43,
	MonitorRequestReasonPdcSignalFingerprint = 44,
	MonitorRequestReasonDirectedDrips = 45,
	MonitorRequestReasonDim = 46,
	MonitorRequestReasonBuiltinPanel = 47,
	MonitorRequestReasonDisplayRequiredUnDim = 48,
	MonitorRequestReasonBatteryCountChangeSuppressed = 49,
	MonitorRequestReasonResumeModernStandby = 50,
	MonitorRequestReasonTerminalInit = 51,
	MonitorRequestReasonPdcSignalSensorsHumanPresence = 52,
	MonitorRequestReasonBatteryPreCritical = 53,
	MonitorRequestReasonUserInputTouch = 54,
	MonitorRequestReasonMax = 55,
}


[AllowDuplicates]
public enum POWER_MONITOR_REQUEST_TYPE : int32
{
	MonitorRequestTypeOff = 0,
	MonitorRequestTypeOnAndPresent = 1,
	MonitorRequestTypeToggleOn = 2,
}


[AllowDuplicates]
public enum POWER_SETTING_ALTITUDE : int32
{
	ALTITUDE_GROUP_POLICY = 0,
	ALTITUDE_USER = 1,
	ALTITUDE_RUNTIME_OVERRIDE = 2,
	ALTITUDE_PROVISIONING = 3,
	ALTITUDE_OEM_CUSTOMIZATION = 4,
	ALTITUDE_INTERNAL_OVERRIDE = 5,
	ALTITUDE_OS_DEFAULT = 6,
}


[AllowDuplicates]
public enum HIBERFILE_BUCKET_SIZE : int32
{
	HiberFileBucket1GB = 0,
	HiberFileBucket2GB = 1,
	HiberFileBucket4GB = 2,
	HiberFileBucket8GB = 3,
	HiberFileBucket16GB = 4,
	HiberFileBucket32GB = 5,
	HiberFileBucketUnlimited = 6,
	HiberFileBucketMax = 7,
}


[AllowDuplicates]
public enum IMAGE_AUX_SYMBOL_TYPE : int32
{
	IMAGE_AUX_SYMBOL_TYPE_TOKEN_DEF = 1,
}


[AllowDuplicates]
public enum ARM64_FNPDATA_FLAGS : int32
{
	PdataRefToFullXdata = 0,
	PdataPackedUnwindFunction = 1,
	PdataPackedUnwindFragment = 2,
}


[AllowDuplicates]
public enum ARM64_FNPDATA_CR : int32
{
	PdataCrUnchained = 0,
	PdataCrUnchainedSavedLr = 1,
	PdataCrChainedWithPac = 2,
	PdataCrChained = 3,
}


[AllowDuplicates]
public enum IMPORT_OBJECT_TYPE : int32
{
	IMPORT_OBJECT_CODE = 0,
	IMPORT_OBJECT_DATA = 1,
	IMPORT_OBJECT_CONST = 2,
}


[AllowDuplicates]
public enum IMPORT_OBJECT_NAME_TYPE : int32
{
	IMPORT_OBJECT_ORDINAL = 0,
	IMPORT_OBJECT_NAME = 1,
	IMPORT_OBJECT_NAME_NO_PREFIX = 2,
	IMPORT_OBJECT_NAME_UNDECORATE = 3,
	IMPORT_OBJECT_NAME_EXPORTAS = 4,
}


[AllowDuplicates]
public enum ReplacesCorHdrNumericDefines : int32
{
	COMIMAGE_FLAGS_ILONLY = 1,
	COMIMAGE_FLAGS_32BITREQUIRED = 2,
	COMIMAGE_FLAGS_IL_LIBRARY = 4,
	COMIMAGE_FLAGS_STRONGNAMESIGNED = 8,
	COMIMAGE_FLAGS_NATIVE_ENTRYPOINT = 16,
	COMIMAGE_FLAGS_TRACKDEBUGDATA = 65536,
	COMIMAGE_FLAGS_32BITPREFERRED = 131072,
	COR_VERSION_MAJOR_V2 = 2,
	COR_VERSION_MAJOR = 2,
	COR_VERSION_MINOR = 5,
	COR_DELETED_NAME_LENGTH = 8,
	COR_VTABLEGAP_NAME_LENGTH = 8,
	NATIVE_TYPE_MAX_CB = 1,
	COR_ILMETHOD_SECT_SMALL_MAX_DATASIZE = 255,
	IMAGE_COR_MIH_METHODRVA = 1,
	IMAGE_COR_MIH_EHRVA = 2,
	IMAGE_COR_MIH_BASICBLOCK = 8,
	COR_VTABLE_32BIT = 1,
	COR_VTABLE_64BIT = 2,
	COR_VTABLE_FROM_UNMANAGED = 4,
	COR_VTABLE_FROM_UNMANAGED_RETAIN_APPDOMAIN = 8,
	COR_VTABLE_CALL_MOST_DERIVED = 16,
	IMAGE_COR_EATJ_THUNK_SIZE = 32,
	MAX_CLASS_NAME = 1024,
	MAX_PACKAGE_NAME = 1024,
}


[AllowDuplicates]
public enum RTL_UMS_SCHEDULER_REASON : int32
{
	UmsSchedulerStartup = 0,
	UmsSchedulerThreadBlocked = 1,
	UmsSchedulerThreadYield = 2,
}


[AllowDuplicates]
public enum IMAGE_POLICY_ENTRY_TYPE : int32
{
	ImagePolicyEntryTypeNone = 0,
	ImagePolicyEntryTypeBool = 1,
	ImagePolicyEntryTypeInt8 = 2,
	ImagePolicyEntryTypeUInt8 = 3,
	ImagePolicyEntryTypeInt16 = 4,
	ImagePolicyEntryTypeUInt16 = 5,
	ImagePolicyEntryTypeInt32 = 6,
	ImagePolicyEntryTypeUInt32 = 7,
	ImagePolicyEntryTypeInt64 = 8,
	ImagePolicyEntryTypeUInt64 = 9,
	ImagePolicyEntryTypeAnsiString = 10,
	ImagePolicyEntryTypeUnicodeString = 11,
	ImagePolicyEntryTypeOverride = 12,
	ImagePolicyEntryTypeMaximum = 13,
}


[AllowDuplicates]
public enum IMAGE_POLICY_ID : int32
{
	ImagePolicyIdNone = 0,
	ImagePolicyIdEtw = 1,
	ImagePolicyIdDebug = 2,
	ImagePolicyIdCrashDump = 3,
	ImagePolicyIdCrashDumpKey = 4,
	ImagePolicyIdCrashDumpKeyGuid = 5,
	ImagePolicyIdParentSd = 6,
	ImagePolicyIdParentSdRev = 7,
	ImagePolicyIdSvn = 8,
	ImagePolicyIdDeviceId = 9,
	ImagePolicyIdCapability = 10,
	ImagePolicyIdScenarioId = 11,
	ImagePolicyIdMaximum = 12,
}


[AllowDuplicates]
public enum ACTIVATION_CONTEXT_INFO_CLASS : int32
{
	ActivationContextBasicInformation = 1,
	ActivationContextDetailedInformation = 2,
	AssemblyDetailedInformationInActivationContext = 3,
	FileInformationInAssemblyOfAssemblyInActivationContext = 4,
	RunlevelInformationInActivationContext = 5,
	CompatibilityInformationInActivationContext = 6,
	ActivationContextManifestResourceName = 7,
	MaxActivationContextInfoClass = 8,
	AssemblyDetailedInformationInActivationContxt = 3,
	FileInformationInAssemblyOfAssemblyInActivationContxt = 4,
}


[AllowDuplicates]
public enum SERVICE_NODE_TYPE : int32
{
	DriverType = 1,
	FileSystemType = 2,
	Win32ServiceOwnProcess = 16,
	Win32ServiceShareProcess = 32,
	AdapterType = 4,
	RecognizerType = 8,
}


[AllowDuplicates]
public enum SERVICE_LOAD_TYPE : int32
{
	BootLoad = 0,
	SystemLoad = 1,
	AutoLoad = 2,
	DemandLoad = 3,
	DisableLoad = 4,
}


[AllowDuplicates]
public enum SERVICE_ERROR_TYPE : int32
{
	IgnoreError = 0,
	NormalError = 1,
	SevereError = 2,
	CriticalError = 3,
}


[AllowDuplicates]
public enum TAPE_DRIVE_PROBLEM_TYPE : int32
{
	TapeDriveProblemNone = 0,
	TapeDriveReadWriteWarning = 1,
	TapeDriveReadWriteError = 2,
	TapeDriveReadWarning = 3,
	TapeDriveWriteWarning = 4,
	TapeDriveReadError = 5,
	TapeDriveWriteError = 6,
	TapeDriveHardwareError = 7,
	TapeDriveUnsupportedMedia = 8,
	TapeDriveScsiConnectionError = 9,
	TapeDriveTimetoClean = 10,
	TapeDriveCleanDriveNow = 11,
	TapeDriveMediaLifeExpired = 12,
	TapeDriveSnappedTape = 13,
}


[AllowDuplicates]
public enum TRANSACTION_STATE : int32
{
	TransactionStateNormal = 1,
	TransactionStateIndoubt = 2,
	TransactionStateCommittedNotify = 3,
}


[AllowDuplicates]
public enum TRANSACTION_INFORMATION_CLASS : int32
{
	TransactionBasicInformation = 0,
	TransactionPropertiesInformation = 1,
	TransactionEnlistmentInformation = 2,
	TransactionSuperiorEnlistmentInformation = 3,
	TransactionBindInformation = 4,
	TransactionDTCPrivateInformation = 5,
}


[AllowDuplicates]
public enum TRANSACTIONMANAGER_INFORMATION_CLASS : int32
{
	TransactionManagerBasicInformation = 0,
	TransactionManagerLogInformation = 1,
	TransactionManagerLogPathInformation = 2,
	TransactionManagerRecoveryInformation = 4,
	TransactionManagerOnlineProbeInformation = 3,
	TransactionManagerOldestTransactionInformation = 5,
}


[AllowDuplicates]
public enum RESOURCEMANAGER_INFORMATION_CLASS : int32
{
	ResourceManagerBasicInformation = 0,
	ResourceManagerCompletionInformation = 1,
}


[AllowDuplicates]
public enum ENLISTMENT_INFORMATION_CLASS : int32
{
	EnlistmentBasicInformation = 0,
	EnlistmentRecoveryInformation = 1,
	EnlistmentCrmInformation = 2,
}


[AllowDuplicates]
public enum KTMOBJECT_TYPE : int32
{
	KTMOBJECT_TRANSACTION = 0,
	KTMOBJECT_TRANSACTION_MANAGER = 1,
	KTMOBJECT_RESOURCE_MANAGER = 2,
	KTMOBJECT_ENLISTMENT = 3,
	KTMOBJECT_INVALID = 4,
}

#endregion

#region Function Pointers
public function void PUMS_SCHEDULER_ENTRY_POINT(RTL_UMS_SCHEDULER_REASON Reason, uint ActivationPayload, void* SchedulerParam);

#if BF_ARM_64
public function void PTERMINATION_HANDLER(BOOLEAN _abnormal_termination, uint64 EstablisherFrame);
#endif

#if BF_ARM_64
public function uint32 POUT_OF_PROCESS_FUNCTION_TABLE_CALLBACK(HANDLE Process, void* TableAddress, uint32* Entries, IMAGE_ARM64_RUNTIME_FUNCTION_ENTRY** Functions);
#endif

#if BF_64_BIT
public function uint32 POUT_OF_PROCESS_FUNCTION_TABLE_CALLBACK(HANDLE Process, void* TableAddress, uint32* Entries, IMAGE_RUNTIME_FUNCTION_ENTRY** Functions);
#endif

#if BF_64_BIT || BF_ARM_64
public function int32 PEXCEPTION_FILTER(EXCEPTION_POINTERS* ExceptionPointers, void* EstablisherFrame);
#endif

#if BF_64_BIT
public function void PTERMINATION_HANDLER(BOOLEAN _abnormal_termination, void* EstablisherFrame);
#endif

public function void PIMAGE_TLS_CALLBACK(void* DllHandle, uint32 Reason, void* Reserved);

public function void WORKERCALLBACKFUNC(void* param0);

public function void APC_CALLBACK_FUNCTION(uint32 param0, void* param1, void* param2);

#endregion

#region Structs
[CRepr]
public struct TP_POOL
{
}

[CRepr]
public struct TP_CLEANUP_GROUP
{
}

[CRepr]
public struct TEB
{
}

[CRepr]
public struct RemHGLOBAL
{
	public int32 fNullHGlobal;
	public uint32 cbData;
	public uint8* data mut => &data_impl;
	private uint8[ANYSIZE_ARRAY] data_impl;
}

[CRepr]
public struct RemHMETAFILEPICT
{
	public int32 mm;
	public int32 xExt;
	public int32 yExt;
	public uint32 cbData;
	public uint8* data mut => &data_impl;
	private uint8[ANYSIZE_ARRAY] data_impl;
}

[CRepr]
public struct RemHENHMETAFILE
{
	public uint32 cbData;
	public uint8* data mut => &data_impl;
	private uint8[ANYSIZE_ARRAY] data_impl;
}

[CRepr]
public struct RemHBITMAP
{
	public uint32 cbData;
	public uint8* data mut => &data_impl;
	private uint8[ANYSIZE_ARRAY] data_impl;
}

[CRepr]
public struct RemHPALETTE
{
	public uint32 cbData;
	public uint8* data mut => &data_impl;
	private uint8[ANYSIZE_ARRAY] data_impl;
}

[CRepr]
public struct RemHBRUSH
{
	public uint32 cbData;
	public uint8* data mut => &data_impl;
	private uint8[ANYSIZE_ARRAY] data_impl;
}

[CRepr]
public struct userCLIPFORMAT
{
	[CRepr, Union]
	public struct _u_e__Struct
	{
		public uint32 dwValue;
		public PWSTR pwszName;
	}
	public int32 fContext;
	public _u_e__Struct u;
}

[CRepr]
public struct GDI_NONREMOTE
{
	[CRepr, Union]
	public struct _u_e__Struct
	{
		public int32 hInproc;
		public DWORD_BLOB* hRemote;
	}
	public int32 fContext;
	public _u_e__Struct u;
}

[CRepr]
public struct userHGLOBAL
{
	[CRepr, Union]
	public struct _u_e__Struct
	{
		public int32 hInproc;
		public FLAGGED_BYTE_BLOB* hRemote;
		public int64 hInproc64;
	}
	public int32 fContext;
	public _u_e__Struct u;
}

[CRepr]
public struct userHMETAFILE
{
	[CRepr, Union]
	public struct _u_e__Struct
	{
		public int32 hInproc;
		public BYTE_BLOB* hRemote;
		public int64 hInproc64;
	}
	public int32 fContext;
	public _u_e__Struct u;
}

[CRepr]
public struct remoteMETAFILEPICT
{
	public int32 mm;
	public int32 xExt;
	public int32 yExt;
	public userHMETAFILE* hMF;
}

[CRepr]
public struct userHMETAFILEPICT
{
	[CRepr, Union]
	public struct _u_e__Struct
	{
		public int32 hInproc;
		public remoteMETAFILEPICT* hRemote;
		public int64 hInproc64;
	}
	public int32 fContext;
	public _u_e__Struct u;
}

[CRepr]
public struct userHENHMETAFILE
{
	[CRepr, Union]
	public struct _u_e__Struct
	{
		public int32 hInproc;
		public BYTE_BLOB* hRemote;
		public int64 hInproc64;
	}
	public int32 fContext;
	public _u_e__Struct u;
}

[CRepr]
public struct userBITMAP
{
	public int32 bmType;
	public int32 bmWidth;
	public int32 bmHeight;
	public int32 bmWidthBytes;
	public uint16 bmPlanes;
	public uint16 bmBitsPixel;
	public uint32 cbSize;
	public uint8* pBuffer mut => &pBuffer_impl;
	private uint8[ANYSIZE_ARRAY] pBuffer_impl;
}

[CRepr]
public struct userHBITMAP
{
	[CRepr, Union]
	public struct _u_e__Struct
	{
		public int32 hInproc;
		public userBITMAP* hRemote;
		public int64 hInproc64;
	}
	public int32 fContext;
	public _u_e__Struct u;
}

[CRepr]
public struct userHPALETTE
{
	[CRepr, Union]
	public struct _u_e__Struct
	{
		public int32 hInproc;
		public LOGPALETTE* hRemote;
		public int64 hInproc64;
	}
	public int32 fContext;
	public _u_e__Struct u;
}

[CRepr]
public struct RemotableHandle
{
	[CRepr, Union]
	public struct _u_e__Struct
	{
		public int32 hInproc;
		public int32 hRemote;
	}
	public int32 fContext;
	public _u_e__Struct u;
}

[CRepr]
public struct DEVICE_EVENT_MOUNT
{
	public uint32 Version;
	public uint32 Flags;
	public uint32 FileSystemNameLength;
	public uint32 FileSystemNameOffset;
}

[CRepr]
public struct DEVICE_EVENT_BECOMING_READY
{
	public uint32 Version;
	public uint32 Reason;
	public uint32 Estimated100msToReady;
}

[CRepr]
public struct DEVICE_EVENT_EXTERNAL_REQUEST
{
	public uint32 Version;
	public uint32 DeviceClass;
	public uint16 ButtonStatus;
	public uint16 Request;
	public LARGE_INTEGER SystemTime;
}

[CRepr]
public struct DEVICE_EVENT_GENERIC_DATA
{
	public uint32 EventNumber;
}

[CRepr]
public struct DEVICE_EVENT_RBC_DATA
{
	public uint32 EventNumber;
	public uint8 SenseQualifier;
	public uint8 SenseCode;
	public uint8 SenseKey;
	public uint8 Reserved;
	public uint32 Information;
}

[CRepr]
public struct GUID_IO_DISK_CLONE_ARRIVAL_INFORMATION
{
	public uint32 DiskNumber;
}

[CRepr]
public struct DISK_HEALTH_NOTIFICATION_DATA
{
	public Guid DeviceGuid;
}

[CRepr]
public struct REDBOOK_DIGITAL_AUDIO_EXTRACTION_INFO
{
	public uint32 Version;
	public uint32 Accurate;
	public uint32 Supported;
	public uint32 AccurateMask0;
}

[CRepr]
public struct DEV_BROADCAST_HDR
{
	public uint32 dbch_size;
	public DEV_BROADCAST_HDR_DEVICE_TYPE dbch_devicetype;
	public uint32 dbch_reserved;
}

[CRepr]
public struct VolLockBroadcast
{
	public DEV_BROADCAST_HDR vlb_dbh;
	public uint32 vlb_owner;
	public uint8 vlb_perms;
	public uint8 vlb_lockType;
	public uint8 vlb_drive;
	public uint8 vlb_flags;
}

[CRepr]
public struct _DEV_BROADCAST_HEADER
{
	public uint32 dbcd_size;
	public uint32 dbcd_devicetype;
	public uint32 dbcd_reserved;
}

[CRepr]
public struct DEV_BROADCAST_OEM
{
	public uint32 dbco_size;
	public uint32 dbco_devicetype;
	public uint32 dbco_reserved;
	public uint32 dbco_identifier;
	public uint32 dbco_suppfunc;
}

[CRepr]
public struct DEV_BROADCAST_DEVNODE
{
	public uint32 dbcd_size;
	public uint32 dbcd_devicetype;
	public uint32 dbcd_reserved;
	public uint32 dbcd_devnode;
}

[CRepr]
public struct DEV_BROADCAST_VOLUME
{
	public uint32 dbcv_size;
	public uint32 dbcv_devicetype;
	public uint32 dbcv_reserved;
	public uint32 dbcv_unitmask;
	public DEV_BROADCAST_VOLUME_FLAGS dbcv_flags;
}

[CRepr]
public struct DEV_BROADCAST_PORT_A
{
	public uint32 dbcp_size;
	public uint32 dbcp_devicetype;
	public uint32 dbcp_reserved;
	public CHAR* dbcp_name mut => &dbcp_name_impl;
	private CHAR[ANYSIZE_ARRAY] dbcp_name_impl;
}

[CRepr]
public struct DEV_BROADCAST_PORT_W
{
	public uint32 dbcp_size;
	public uint32 dbcp_devicetype;
	public uint32 dbcp_reserved;
	public char16* dbcp_name mut => &dbcp_name_impl;
	private char16[ANYSIZE_ARRAY] dbcp_name_impl;
}

[CRepr]
public struct DEV_BROADCAST_NET
{
	public uint32 dbcn_size;
	public uint32 dbcn_devicetype;
	public uint32 dbcn_reserved;
	public uint32 dbcn_resource;
	public uint32 dbcn_flags;
}

[CRepr]
public struct DEV_BROADCAST_DEVICEINTERFACE_A
{
	public uint32 dbcc_size;
	public uint32 dbcc_devicetype;
	public uint32 dbcc_reserved;
	public Guid dbcc_classguid;
	public CHAR* dbcc_name mut => &dbcc_name_impl;
	private CHAR[ANYSIZE_ARRAY] dbcc_name_impl;
}

[CRepr]
public struct DEV_BROADCAST_DEVICEINTERFACE_W
{
	public uint32 dbcc_size;
	public uint32 dbcc_devicetype;
	public uint32 dbcc_reserved;
	public Guid dbcc_classguid;
	public char16* dbcc_name mut => &dbcc_name_impl;
	private char16[ANYSIZE_ARRAY] dbcc_name_impl;
}

[CRepr]
public struct DEV_BROADCAST_HANDLE
{
	public uint32 dbch_size;
	public uint32 dbch_devicetype;
	public uint32 dbch_reserved;
	public HANDLE dbch_handle;
	public void* dbch_hdevnotify;
	public Guid dbch_eventguid;
	public int32 dbch_nameoffset;
	public uint8* dbch_data mut => &dbch_data_impl;
	private uint8[ANYSIZE_ARRAY] dbch_data_impl;
}

[CRepr]
public struct DEV_BROADCAST_HANDLE32
{
	public uint32 dbch_size;
	public uint32 dbch_devicetype;
	public uint32 dbch_reserved;
	public uint32 dbch_handle;
	public uint32 dbch_hdevnotify;
	public Guid dbch_eventguid;
	public int32 dbch_nameoffset;
	public uint8* dbch_data mut => &dbch_data_impl;
	private uint8[ANYSIZE_ARRAY] dbch_data_impl;
}

[CRepr]
public struct DEV_BROADCAST_HANDLE64
{
	public uint32 dbch_size;
	public uint32 dbch_devicetype;
	public uint32 dbch_reserved;
	public uint64 dbch_handle;
	public uint64 dbch_hdevnotify;
	public Guid dbch_eventguid;
	public int32 dbch_nameoffset;
	public uint8* dbch_data mut => &dbch_data_impl;
	private uint8[ANYSIZE_ARRAY] dbch_data_impl;
}

[CRepr]
public struct _DEV_BROADCAST_USERDEFINED
{
	public DEV_BROADCAST_HDR dbud_dbh;
	public CHAR* dbud_szName mut => &dbud_szName_impl;
	private CHAR[ANYSIZE_ARRAY] dbud_szName_impl;
}

[CRepr]
public struct AtlThunkData_t
{
}

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct REARRANGE_FILE_DATA32
{
	public uint64 SourceStartingOffset;
	public uint64 TargetOffset;
	public uint32 SourceFileHandle;
	public uint32 Length;
	public uint32 Flags;
}
#endif

[CRepr]
public struct XSAVE_CET_U_FORMAT
{
	public uint64 Ia32CetUMsr;
	public uint64 Ia32Pl3SspMsr;
}

[CRepr]
public struct KERNEL_CET_CONTEXT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint16 _bitfield;
		}
		public uint16 AllFlags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint64 Ssp;
	public uint64 Rip;
	public uint16 SegCs;
	public using _Anonymous_e__Union Anonymous;
	public uint16[2] Fill;
}

[CRepr]
public struct SCOPE_TABLE_AMD64
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint32 BeginAddress;
		public uint32 EndAddress;
		public uint32 HandlerAddress;
		public uint32 JumpTarget;
	}
	public uint32 Count;
	public _Anonymous_e__Struct* ScopeRecord mut => &ScopeRecord_impl;
	private _Anonymous_e__Struct[ANYSIZE_ARRAY] ScopeRecord_impl;
}

[CRepr]
public struct SCOPE_TABLE_ARM
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint32 BeginAddress;
		public uint32 EndAddress;
		public uint32 HandlerAddress;
		public uint32 JumpTarget;
	}
	public uint32 Count;
	public _Anonymous_e__Struct* ScopeRecord mut => &ScopeRecord_impl;
	private _Anonymous_e__Struct[ANYSIZE_ARRAY] ScopeRecord_impl;
}

[CRepr]
public struct SCOPE_TABLE_ARM64
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint32 BeginAddress;
		public uint32 EndAddress;
		public uint32 HandlerAddress;
		public uint32 JumpTarget;
	}
	public uint32 Count;
	public _Anonymous_e__Struct* ScopeRecord mut => &ScopeRecord_impl;
	private _Anonymous_e__Struct[ANYSIZE_ARRAY] ScopeRecord_impl;
}

[CRepr, Union]
public struct DISPATCHER_CONTEXT_NONVOLREG_ARM64
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint64[11] GpNvRegs;
		public double[8] FpNvRegs;
	}
	public uint8[152] Buffer;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr]
public struct SECURITY_DESCRIPTOR_RELATIVE
{
	public uint8 Revision;
	public uint8 Sbz1;
	public uint16 Control;
	public uint32 Owner;
	public uint32 Group;
	public uint32 Sacl;
	public uint32 Dacl;
}

[CRepr]
public struct SECURITY_OBJECT_AI_PARAMS
{
	public uint32 Size;
	public uint32 ConstraintMask;
}

[CRepr]
public struct SE_TOKEN_USER
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public SID Sid;
		public uint8[68] Buffer;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public TOKEN_USER TokenUser;
		public SID_AND_ATTRIBUTES User;
	}
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
}

[CRepr]
public struct TOKEN_SID_INFORMATION
{
	public PSID Sid;
}

[CRepr]
public struct TOKEN_BNO_ISOLATION_INFORMATION
{
	public PWSTR IsolationPrefix;
	public BOOLEAN IsolationEnabled;
}

[CRepr]
public struct NT_TIB32
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 FiberData;
		public uint32 Version;
	}
	public uint32 ExceptionList;
	public uint32 StackBase;
	public uint32 StackLimit;
	public uint32 SubSystemTib;
	public using _Anonymous_e__Union Anonymous;
	public uint32 ArbitraryUserPointer;
	public uint32 Self;
}

[CRepr]
public struct NT_TIB64
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint64 FiberData;
		public uint32 Version;
	}
	public uint64 ExceptionList;
	public uint64 StackBase;
	public uint64 StackLimit;
	public uint64 SubSystemTib;
	public using _Anonymous_e__Union Anonymous;
	public uint64 ArbitraryUserPointer;
	public uint64 Self;
}

[CRepr]
public struct UMS_CREATE_THREAD_ATTRIBUTES
{
	public uint32 UmsVersion;
	public void* UmsContext;
	public void* UmsCompletionList;
}

[CRepr]
public struct COMPONENT_FILTER
{
	public uint32 ComponentFlags;
}

[CRepr, Union]
public struct RATE_QUOTA_LIMIT
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint32 _bitfield;
	}
	public uint32 RateData;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr]
public struct QUOTA_LIMITS_EX
{
	public uint PagedPoolLimit;
	public uint NonPagedPoolLimit;
	public uint MinimumWorkingSetSize;
	public uint MaximumWorkingSetSize;
	public uint PagefileLimit;
	public LARGE_INTEGER TimeLimit;
	public uint WorkingSetLimit;
	public uint Reserved2;
	public uint Reserved3;
	public uint Reserved4;
	public uint32 Flags;
	public RATE_QUOTA_LIMIT CpuRateLimit;
}

[CRepr]
public struct PROCESS_MITIGATION_ASLR_POLICY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Flags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PROCESS_MITIGATION_DEP_POLICY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Flags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
	public BOOLEAN Permanent;
}

[CRepr]
public struct PROCESS_MITIGATION_STRICT_HANDLE_CHECK_POLICY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Flags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PROCESS_MITIGATION_SYSTEM_CALL_DISABLE_POLICY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Flags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PROCESS_MITIGATION_EXTENSION_POINT_DISABLE_POLICY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Flags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PROCESS_MITIGATION_DYNAMIC_CODE_POLICY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Flags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PROCESS_MITIGATION_CONTROL_FLOW_GUARD_POLICY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Flags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PROCESS_MITIGATION_BINARY_SIGNATURE_POLICY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Flags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PROCESS_MITIGATION_FONT_DISABLE_POLICY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Flags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PROCESS_MITIGATION_IMAGE_LOAD_POLICY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Flags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PROCESS_MITIGATION_SYSTEM_CALL_FILTER_POLICY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Flags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PROCESS_MITIGATION_PAYLOAD_RESTRICTION_POLICY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Flags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PROCESS_MITIGATION_CHILD_PROCESS_POLICY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Flags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PROCESS_MITIGATION_SIDE_CHANNEL_ISOLATION_POLICY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Flags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PROCESS_MITIGATION_USER_SHADOW_STACK_POLICY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Flags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PROCESS_MITIGATION_REDIRECTION_TRUST_POLICY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Flags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct JOBOBJECT_IO_RATE_CONTROL_INFORMATION_NATIVE_V1
{
	public int64 MaxIops;
	public int64 MaxBandwidth;
	public int64 ReservationIops;
	public PWSTR VolumeName;
	public uint32 BaseIoSize;
	public JOB_OBJECT_IO_RATE_CONTROL_FLAGS ControlFlags;
	public uint16 VolumeNameLength;
}

[CRepr]
public struct SILOOBJECT_BASIC_INFORMATION
{
	public uint32 SiloId;
	public uint32 SiloParentId;
	public uint32 NumberOfProcesses;
	public BOOLEAN IsInServerSilo;
	public uint8[3] Reserved;
}

[CRepr]
public struct SERVERSILO_BASIC_INFORMATION
{
	public uint32 ServiceSessionId;
	public SERVERSILO_STATE State;
	public uint32 ExitStatus;
	public BOOLEAN IsDownlevelContainer;
	public void* ApiSetSchema;
	public void* HostApiSetSchema;
}

[CRepr]
public struct MEMORY_PARTITION_DEDICATED_MEMORY_ATTRIBUTE
{
	public MEM_DEDICATED_ATTRIBUTE_TYPE Type;
	public uint32 Reserved;
	public uint64 Value;
}

[CRepr]
public struct MEMORY_PARTITION_DEDICATED_MEMORY_INFORMATION
{
	public uint32 NextEntryOffset;
	public uint32 SizeOfInformation;
	public uint32 Flags;
	public uint32 AttributesOffset;
	public uint32 AttributeCount;
	public uint32 Reserved;
	public uint64 TypeId;
}

[CRepr]
public struct SCRUB_DATA_INPUT
{
	public uint32 Size;
	public uint32 Flags;
	public uint32 MaximumIos;
	public uint32[4] ObjectId;
	public uint32[41] Reserved;
	public uint8[1040] ResumeContext;
}

[CRepr]
public struct SCRUB_PARITY_EXTENT
{
	public int64 Offset;
	public uint64 Length;
}

[CRepr]
public struct SCRUB_PARITY_EXTENT_DATA
{
	public uint16 Size;
	public uint16 Flags;
	public uint16 NumberOfParityExtents;
	public uint16 MaximumNumberOfParityExtents;
	public SCRUB_PARITY_EXTENT* ParityExtents mut => &ParityExtents_impl;
	private SCRUB_PARITY_EXTENT[ANYSIZE_ARRAY] ParityExtents_impl;
}

[CRepr]
public struct SCRUB_DATA_OUTPUT
{
	public uint32 Size;
	public uint32 Flags;
	public uint32 Status;
	public uint64 ErrorFileOffset;
	public uint64 ErrorLength;
	public uint64 NumberOfBytesRepaired;
	public uint64 NumberOfBytesFailed;
	public uint64 InternalFileReference;
	public uint16 ResumeContextLength;
	public uint16 ParityExtentDataOffset;
	public uint32[9] Reserved;
	public uint64 NumberOfMetadataBytesProcessed;
	public uint64 NumberOfDataBytesProcessed;
	public uint64 TotalNumberOfMetadataBytesInUse;
	public uint64 TotalNumberOfDataBytesInUse;
	public uint64 DataBytesSkippedDueToNoAllocation;
	public uint64 DataBytesSkippedDueToInvalidRun;
	public uint64 DataBytesSkippedDueToIntegrityStream;
	public uint64 DataBytesSkippedDueToRegionBeingClean;
	public uint64 DataBytesSkippedDueToLockConflict;
	public uint64 DataBytesSkippedDueToNoScrubDataFlag;
	public uint64 DataBytesSkippedDueToNoScrubNonIntegrityStreamFlag;
	public uint64 DataBytesScrubbed;
	public uint8[1040] ResumeContext;
}

[CRepr]
public struct SHARED_VIRTUAL_DISK_SUPPORT
{
	public SharedVirtualDiskSupportType SharedVirtualDiskSupport;
	public SharedVirtualDiskHandleState HandleState;
}

[CRepr]
public struct REARRANGE_FILE_DATA
{
	public uint64 SourceStartingOffset;
	public uint64 TargetOffset;
	public HANDLE SourceFileHandle;
	public uint32 Length;
	public uint32 Flags;
}

[CRepr]
public struct SHUFFLE_FILE_DATA
{
	public int64 StartingOffset;
	public int64 Length;
	public uint32 Flags;
}

[CRepr]
public struct NETWORK_APP_INSTANCE_EA
{
	public Guid AppInstanceID;
	public uint32 CsvFlags;
}

[CRepr]
public struct POWER_USER_PRESENCE
{
	public POWER_USER_PRESENCE_TYPE UserPresence;
}

[CRepr]
public struct POWER_SESSION_CONNECT
{
	public BOOLEAN Connected;
	public BOOLEAN Console;
}

[CRepr]
public struct POWER_SESSION_TIMEOUTS
{
	public uint32 InputTimeout;
	public uint32 DisplayTimeout;
}

[CRepr]
public struct POWER_SESSION_RIT_STATE
{
	public BOOLEAN Active;
	public uint64 LastInputTime;
}

[CRepr]
public struct POWER_SESSION_WINLOGON
{
	public uint32 SessionId;
	public BOOLEAN Console;
	public BOOLEAN Locked;
}

[CRepr]
public struct POWER_SESSION_ALLOW_EXTERNAL_DMA_DEVICES
{
	public BOOLEAN IsAllowed;
}

[CRepr]
public struct POWER_IDLE_RESILIENCY
{
	public uint32 CoalescingTimeout;
	public uint32 IdleResiliencyPeriod;
}

[CRepr]
public struct POWER_MONITOR_INVOCATION
{
	public BOOLEAN Console;
	public POWER_MONITOR_REQUEST_REASON RequestReason;
}

[CRepr]
public struct RESUME_PERFORMANCE
{
	public uint32 PostTimeMs;
	public uint64 TotalResumeTimeMs;
	public uint64 ResumeCompleteTimestamp;
}

[CRepr]
public struct NOTIFY_USER_POWER_SETTING
{
	public Guid Guid;
}

[CRepr]
public struct APPLICATIONLAUNCH_SETTING_VALUE
{
	public LARGE_INTEGER ActivationTime;
	public uint32 Flags;
	public uint32 ButtonInstanceID;
}

[CRepr]
public struct POWER_PLATFORM_INFORMATION
{
	public BOOLEAN AoAc;
}

[CRepr]
public struct PPM_WMI_LEGACY_PERFSTATE
{
	public uint32 Frequency;
	public uint32 Flags;
	public uint32 PercentFrequency;
}

[CRepr]
public struct PPM_WMI_IDLE_STATE
{
	public uint32 Latency;
	public uint32 Power;
	public uint32 TimeCheck;
	public uint8 PromotePercent;
	public uint8 DemotePercent;
	public uint8 StateType;
	public uint8 Reserved;
	public uint32 StateFlags;
	public uint32 Context;
	public uint32 IdleHandler;
	public uint32 Reserved1;
}

[CRepr]
public struct PPM_WMI_IDLE_STATES
{
	public uint32 Type;
	public uint32 Count;
	public uint32 TargetState;
	public uint32 OldState;
	public uint64 TargetProcessors;
	public PPM_WMI_IDLE_STATE* State mut => &State_impl;
	private PPM_WMI_IDLE_STATE[ANYSIZE_ARRAY] State_impl;
}

[CRepr]
public struct PPM_WMI_IDLE_STATES_EX
{
	public uint32 Type;
	public uint32 Count;
	public uint32 TargetState;
	public uint32 OldState;
	public void* TargetProcessors;
	public PPM_WMI_IDLE_STATE* State mut => &State_impl;
	private PPM_WMI_IDLE_STATE[ANYSIZE_ARRAY] State_impl;
}

[CRepr]
public struct PPM_WMI_PERF_STATE
{
	public uint32 Frequency;
	public uint32 Power;
	public uint8 PercentFrequency;
	public uint8 IncreaseLevel;
	public uint8 DecreaseLevel;
	public uint8 Type;
	public uint32 IncreaseTime;
	public uint32 DecreaseTime;
	public uint64 Control;
	public uint64 Status;
	public uint32 HitCount;
	public uint32 Reserved1;
	public uint64 Reserved2;
	public uint64 Reserved3;
}

[CRepr]
public struct PPM_WMI_PERF_STATES
{
	public uint32 Count;
	public uint32 MaxFrequency;
	public uint32 CurrentState;
	public uint32 MaxPerfState;
	public uint32 MinPerfState;
	public uint32 LowestPerfState;
	public uint32 ThermalConstraint;
	public uint8 BusyAdjThreshold;
	public uint8 PolicyType;
	public uint8 Type;
	public uint8 Reserved;
	public uint32 TimerInterval;
	public uint64 TargetProcessors;
	public uint32 PStateHandler;
	public uint32 PStateContext;
	public uint32 TStateHandler;
	public uint32 TStateContext;
	public uint32 FeedbackHandler;
	public uint32 Reserved1;
	public uint64 Reserved2;
	public PPM_WMI_PERF_STATE* State mut => &State_impl;
	private PPM_WMI_PERF_STATE[ANYSIZE_ARRAY] State_impl;
}

[CRepr]
public struct PPM_WMI_PERF_STATES_EX
{
	public uint32 Count;
	public uint32 MaxFrequency;
	public uint32 CurrentState;
	public uint32 MaxPerfState;
	public uint32 MinPerfState;
	public uint32 LowestPerfState;
	public uint32 ThermalConstraint;
	public uint8 BusyAdjThreshold;
	public uint8 PolicyType;
	public uint8 Type;
	public uint8 Reserved;
	public uint32 TimerInterval;
	public void* TargetProcessors;
	public uint32 PStateHandler;
	public uint32 PStateContext;
	public uint32 TStateHandler;
	public uint32 TStateContext;
	public uint32 FeedbackHandler;
	public uint32 Reserved1;
	public uint64 Reserved2;
	public PPM_WMI_PERF_STATE* State mut => &State_impl;
	private PPM_WMI_PERF_STATE[ANYSIZE_ARRAY] State_impl;
}

[CRepr]
public struct PPM_IDLE_STATE_ACCOUNTING
{
	public uint32 IdleTransitions;
	public uint32 FailedTransitions;
	public uint32 InvalidBucketIndex;
	public uint64 TotalTime;
	public uint32[6] IdleTimeBuckets;
}

[CRepr]
public struct PPM_IDLE_ACCOUNTING
{
	public uint32 StateCount;
	public uint32 TotalTransitions;
	public uint32 ResetCount;
	public uint64 StartTime;
	public PPM_IDLE_STATE_ACCOUNTING* State mut => &State_impl;
	private PPM_IDLE_STATE_ACCOUNTING[ANYSIZE_ARRAY] State_impl;
}

[CRepr]
public struct PPM_IDLE_STATE_BUCKET_EX
{
	public uint64 TotalTimeUs;
	public uint32 MinTimeUs;
	public uint32 MaxTimeUs;
	public uint32 Count;
}

[CRepr]
public struct PPM_IDLE_STATE_ACCOUNTING_EX
{
	public uint64 TotalTime;
	public uint32 IdleTransitions;
	public uint32 FailedTransitions;
	public uint32 InvalidBucketIndex;
	public uint32 MinTimeUs;
	public uint32 MaxTimeUs;
	public uint32 CancelledTransitions;
	public PPM_IDLE_STATE_BUCKET_EX[16] IdleTimeBuckets;
}

[CRepr]
public struct PPM_IDLE_ACCOUNTING_EX
{
	public uint32 StateCount;
	public uint32 TotalTransitions;
	public uint32 ResetCount;
	public uint32 AbortCount;
	public uint64 StartTime;
	public PPM_IDLE_STATE_ACCOUNTING_EX* State mut => &State_impl;
	private PPM_IDLE_STATE_ACCOUNTING_EX[ANYSIZE_ARRAY] State_impl;
}

[CRepr]
public struct PPM_PERFSTATE_EVENT
{
	public uint32 State;
	public uint32 Status;
	public uint32 Latency;
	public uint32 Speed;
	public uint32 Processor;
}

[CRepr]
public struct PPM_PERFSTATE_DOMAIN_EVENT
{
	public uint32 State;
	public uint32 Latency;
	public uint32 Speed;
	public uint64 Processors;
}

[CRepr]
public struct PPM_IDLESTATE_EVENT
{
	public uint32 NewState;
	public uint32 OldState;
	public uint64 Processors;
}

[CRepr]
public struct PPM_THERMALCHANGE_EVENT
{
	public uint32 ThermalConstraint;
	public uint64 Processors;
}

[CRepr]
public struct PPM_THERMAL_POLICY_EVENT
{
	public uint8 Mode;
	public uint64 Processors;
}

[CRepr]
public struct PROCESSOR_IDLESTATE_INFO
{
	public uint32 TimeCheck;
	public uint8 DemotePercent;
	public uint8 PromotePercent;
	public uint8[2] Spare;
}

[CRepr]
public struct PROCESSOR_IDLESTATE_POLICY
{
	[CRepr, Union]
	public struct _Flags_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint16 _bitfield;
		}
		public uint16 AsWORD;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint16 Revision;
	public _Flags_e__Union Flags;
	public uint32 PolicyCount;
	public PROCESSOR_IDLESTATE_INFO[3] Policy;
}

[CRepr]
public struct PROCESSOR_PERFSTATE_POLICY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr, Union]
		public struct _Flags_e__Union
		{
			[CRepr]
			public struct _Anonymous_e__Struct
			{
				public uint8 _bitfield;
			}
			public uint8 AsBYTE;
			public using _Anonymous_e__Struct Anonymous;
		}
		public uint8 Spare;
		public _Flags_e__Union Flags;
	}
	public uint32 Revision;
	public uint8 MaxThrottle;
	public uint8 MinThrottle;
	public uint8 BusyAdjThreshold;
	public using _Anonymous_e__Union Anonymous;
	public uint32 TimeCheck;
	public uint32 IncreaseTime;
	public uint32 DecreaseTime;
	public uint32 IncreasePercent;
	public uint32 DecreasePercent;
}

[CRepr]
public struct HIBERFILE_BUCKET
{
	public uint64 MaxPhysicalMemory;
	public uint32[3] PhysicalMemoryPercent;
}

[CRepr, Packed(2)]
public struct IMAGE_DOS_HEADER
{
	public uint16 e_magic;
	public uint16 e_cblp;
	public uint16 e_cp;
	public uint16 e_crlc;
	public uint16 e_cparhdr;
	public uint16 e_minalloc;
	public uint16 e_maxalloc;
	public uint16 e_ss;
	public uint16 e_sp;
	public uint16 e_csum;
	public uint16 e_ip;
	public uint16 e_cs;
	public uint16 e_lfarlc;
	public uint16 e_ovno;
	public uint16[4] e_res;
	public uint16 e_oemid;
	public uint16 e_oeminfo;
	public uint16[10] e_res2;
	public int32 e_lfanew;
}

[CRepr, Packed(2)]
public struct IMAGE_OS2_HEADER
{
	public uint16 ne_magic;
	public CHAR ne_ver;
	public CHAR ne_rev;
	public uint16 ne_enttab;
	public uint16 ne_cbenttab;
	public int32 ne_crc;
	public uint16 ne_flags;
	public uint16 ne_autodata;
	public uint16 ne_heap;
	public uint16 ne_stack;
	public int32 ne_csip;
	public int32 ne_sssp;
	public uint16 ne_cseg;
	public uint16 ne_cmod;
	public uint16 ne_cbnrestab;
	public uint16 ne_segtab;
	public uint16 ne_rsrctab;
	public uint16 ne_restab;
	public uint16 ne_modtab;
	public uint16 ne_imptab;
	public int32 ne_nrestab;
	public uint16 ne_cmovent;
	public uint16 ne_align;
	public uint16 ne_cres;
	public uint8 ne_exetyp;
	public uint8 ne_flagsothers;
	public uint16 ne_pretthunks;
	public uint16 ne_psegrefbytes;
	public uint16 ne_swaparea;
	public uint16 ne_expver;
}

[CRepr, Packed(2)]
public struct IMAGE_VXD_HEADER
{
	public uint16 e32_magic;
	public uint8 e32_border;
	public uint8 e32_worder;
	public uint32 e32_level;
	public uint16 e32_cpu;
	public uint16 e32_os;
	public uint32 e32_ver;
	public uint32 e32_mflags;
	public uint32 e32_mpages;
	public uint32 e32_startobj;
	public uint32 e32_eip;
	public uint32 e32_stackobj;
	public uint32 e32_esp;
	public uint32 e32_pagesize;
	public uint32 e32_lastpagesize;
	public uint32 e32_fixupsize;
	public uint32 e32_fixupsum;
	public uint32 e32_ldrsize;
	public uint32 e32_ldrsum;
	public uint32 e32_objtab;
	public uint32 e32_objcnt;
	public uint32 e32_objmap;
	public uint32 e32_itermap;
	public uint32 e32_rsrctab;
	public uint32 e32_rsrccnt;
	public uint32 e32_restab;
	public uint32 e32_enttab;
	public uint32 e32_dirtab;
	public uint32 e32_dircnt;
	public uint32 e32_fpagetab;
	public uint32 e32_frectab;
	public uint32 e32_impmod;
	public uint32 e32_impmodcnt;
	public uint32 e32_impproc;
	public uint32 e32_pagesum;
	public uint32 e32_datapage;
	public uint32 e32_preload;
	public uint32 e32_nrestab;
	public uint32 e32_cbnrestab;
	public uint32 e32_nressum;
	public uint32 e32_autodata;
	public uint32 e32_debuginfo;
	public uint32 e32_debuglen;
	public uint32 e32_instpreload;
	public uint32 e32_instdemand;
	public uint32 e32_heapsize;
	public uint8[12] e32_res3;
	public uint32 e32_winresoff;
	public uint32 e32_winreslen;
	public uint16 e32_devid;
	public uint16 e32_ddkver;
}

[CRepr]
public struct ANON_OBJECT_HEADER
{
	public uint16 Sig1;
	public uint16 Sig2;
	public uint16 Version;
	public uint16 Machine;
	public uint32 TimeDateStamp;
	public Guid ClassID;
	public uint32 SizeOfData;
}

[CRepr]
public struct ANON_OBJECT_HEADER_V2
{
	public uint16 Sig1;
	public uint16 Sig2;
	public uint16 Version;
	public uint16 Machine;
	public uint32 TimeDateStamp;
	public Guid ClassID;
	public uint32 SizeOfData;
	public uint32 Flags;
	public uint32 MetaDataSize;
	public uint32 MetaDataOffset;
}

[CRepr]
public struct ANON_OBJECT_HEADER_BIGOBJ
{
	public uint16 Sig1;
	public uint16 Sig2;
	public uint16 Version;
	public uint16 Machine;
	public uint32 TimeDateStamp;
	public Guid ClassID;
	public uint32 SizeOfData;
	public uint32 Flags;
	public uint32 MetaDataSize;
	public uint32 MetaDataOffset;
	public uint32 NumberOfSections;
	public uint32 PointerToSymbolTable;
	public uint32 NumberOfSymbols;
}

[CRepr, Packed(2)]
public struct IMAGE_SYMBOL
{
	[CRepr, Union, Packed(2)]
	public struct _N_e__Union
	{
		[CRepr, Packed(2)]
		public struct _Name_e__Struct
		{
			public uint32 Short;
			public uint32 Long;
		}
		public uint8[8] ShortName;
		public _Name_e__Struct Name;
		public uint32[2] LongName;
	}
	public _N_e__Union N;
	public uint32 Value;
	public int16 SectionNumber;
	public uint16 Type;
	public uint8 StorageClass;
	public uint8 NumberOfAuxSymbols;
}

[CRepr, Packed(2)]
public struct IMAGE_SYMBOL_EX
{
	[CRepr, Union, Packed(2)]
	public struct _N_e__Union
	{
		[CRepr, Packed(2)]
		public struct _Name_e__Struct
		{
			public uint32 Short;
			public uint32 Long;
		}
		public uint8[8] ShortName;
		public _Name_e__Struct Name;
		public uint32[2] LongName;
	}
	public _N_e__Union N;
	public uint32 Value;
	public int32 SectionNumber;
	public uint16 Type;
	public uint8 StorageClass;
	public uint8 NumberOfAuxSymbols;
}

[CRepr, Packed(2)]
public struct IMAGE_AUX_SYMBOL_TOKEN_DEF
{
	public uint8 bAuxType;
	public uint8 bReserved;
	public uint32 SymbolTableIndex;
	public uint8[12] rgbReserved;
}

[CRepr, Union]
public struct IMAGE_AUX_SYMBOL
{
	[CRepr, Packed(2)]
	public struct _CRC_e__Struct
	{
		public uint32 crc;
		public uint8[14] rgbReserved;
	}
	[CRepr]
	public struct _File_e__Struct
	{
		public uint8[18] Name;
	}
	[CRepr, Packed(2)]
	public struct _Sym_e__Struct
	{
		[CRepr, Union]
		public struct _FcnAry_e__Union
		{
			[CRepr]
			public struct _Array_e__Struct
			{
				public uint16[4] Dimension;
			}
			[CRepr, Packed(2)]
			public struct _Function_e__Struct
			{
				public uint32 PointerToLinenumber;
				public uint32 PointerToNextFunction;
			}
			public _Function_e__Struct Function;
			public _Array_e__Struct Array;
		}
		[CRepr, Union, Packed(2)]
		public struct _Misc_e__Union
		{
			[CRepr]
			public struct _LnSz_e__Struct
			{
				public uint16 Linenumber;
				public uint16 Size;
			}
			public _LnSz_e__Struct LnSz;
			public uint32 TotalSize;
		}
		public uint32 TagIndex;
		public _Misc_e__Union Misc;
		public _FcnAry_e__Union FcnAry;
		public uint16 TvIndex;
	}
	[CRepr, Packed(2)]
	public struct _Section_e__Struct
	{
		public uint32 Length;
		public uint16 NumberOfRelocations;
		public uint16 NumberOfLinenumbers;
		public uint32 CheckSum;
		public int16 Number;
		public uint8 Selection;
		public uint8 bReserved;
		public int16 HighNumber;
	}
	public _Sym_e__Struct Sym;
	public _File_e__Struct File;
	public _Section_e__Struct Section;
	public IMAGE_AUX_SYMBOL_TOKEN_DEF TokenDef;
	public _CRC_e__Struct CRC;
}

[CRepr, Union]
public struct IMAGE_AUX_SYMBOL_EX
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public IMAGE_AUX_SYMBOL_TOKEN_DEF TokenDef;
		public uint8[2] rgbReserved;
	}
	[CRepr]
	public struct _File_e__Struct
	{
		public uint8[20] Name;
	}
	[CRepr, Packed(2)]
	public struct _CRC_e__Struct
	{
		public uint32 crc;
		public uint8[16] rgbReserved;
	}
	[CRepr, Packed(2)]
	public struct _Sym_e__Struct
	{
		public uint32 WeakDefaultSymIndex;
		public uint32 WeakSearchType;
		public uint8[12] rgbReserved;
	}
	[CRepr, Packed(2)]
	public struct _Section_e__Struct
	{
		public uint32 Length;
		public uint16 NumberOfRelocations;
		public uint16 NumberOfLinenumbers;
		public uint32 CheckSum;
		public int16 Number;
		public uint8 Selection;
		public uint8 bReserved;
		public int16 HighNumber;
		public uint8[2] rgbReserved;
	}
	public _Sym_e__Struct Sym;
	public _File_e__Struct File;
	public _Section_e__Struct Section;
	public using _Anonymous_e__Struct Anonymous;
	public _CRC_e__Struct CRC;
}

[CRepr, Packed(2)]
public struct IMAGE_RELOCATION
{
	[CRepr, Union, Packed(2)]
	public struct _Anonymous_e__Union
	{
		public uint32 VirtualAddress;
		public uint32 RelocCount;
	}
	public using _Anonymous_e__Union Anonymous;
	public uint32 SymbolTableIndex;
	public uint16 Type;
}

[CRepr]
public struct IMAGE_LINENUMBER
{
	[CRepr, Union, Packed(2)]
	public struct _Type_e__Union
	{
		public uint32 SymbolTableIndex;
		public uint32 VirtualAddress;
	}
	public _Type_e__Union Type;
	public uint16 Linenumber;
}

[CRepr]
public struct IMAGE_BASE_RELOCATION
{
	public uint32 VirtualAddress;
	public uint32 SizeOfBlock;
}

[CRepr]
public struct IMAGE_ARCHIVE_MEMBER_HEADER
{
	public uint8[16] Name;
	public uint8[12] Date;
	public uint8[6] UserID;
	public uint8[6] GroupID;
	public uint8[8] Mode;
	public uint8[10] Size;
	public uint8[2] EndHeader;
}

[CRepr]
public struct IMAGE_EXPORT_DIRECTORY
{
	public uint32 Characteristics;
	public uint32 TimeDateStamp;
	public uint16 MajorVersion;
	public uint16 MinorVersion;
	public uint32 Name;
	public uint32 Base;
	public uint32 NumberOfFunctions;
	public uint32 NumberOfNames;
	public uint32 AddressOfFunctions;
	public uint32 AddressOfNames;
	public uint32 AddressOfNameOrdinals;
}

[CRepr]
public struct IMAGE_IMPORT_BY_NAME
{
	public uint16 Hint;
	public CHAR* Name mut => &Name_impl;
	private CHAR[ANYSIZE_ARRAY] Name_impl;
}

[CRepr, Packed(4)]
public struct IMAGE_TLS_DIRECTORY64
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Characteristics;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint64 StartAddressOfRawData;
	public uint64 EndAddressOfRawData;
	public uint64 AddressOfIndex;
	public uint64 AddressOfCallBacks;
	public uint32 SizeOfZeroFill;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct IMAGE_TLS_DIRECTORY32
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Characteristics;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint32 StartAddressOfRawData;
	public uint32 EndAddressOfRawData;
	public uint32 AddressOfIndex;
	public uint32 AddressOfCallBacks;
	public uint32 SizeOfZeroFill;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct IMAGE_IMPORT_DESCRIPTOR
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 Characteristics;
		public uint32 OriginalFirstThunk;
	}
	public using _Anonymous_e__Union Anonymous;
	public uint32 TimeDateStamp;
	public uint32 ForwarderChain;
	public uint32 Name;
	public uint32 FirstThunk;
}

[CRepr]
public struct IMAGE_BOUND_IMPORT_DESCRIPTOR
{
	public uint32 TimeDateStamp;
	public uint16 OffsetModuleName;
	public uint16 NumberOfModuleForwarderRefs;
}

[CRepr]
public struct IMAGE_BOUND_FORWARDER_REF
{
	public uint32 TimeDateStamp;
	public uint16 OffsetModuleName;
	public uint16 Reserved;
}

[CRepr]
public struct IMAGE_RESOURCE_DIRECTORY
{
	public uint32 Characteristics;
	public uint32 TimeDateStamp;
	public uint16 MajorVersion;
	public uint16 MinorVersion;
	public uint16 NumberOfNamedEntries;
	public uint16 NumberOfIdEntries;
}

[CRepr]
public struct IMAGE_RESOURCE_DIRECTORY_ENTRY
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 OffsetToData;
		public using _Anonymous_e__Struct Anonymous;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint32 Name;
		public uint16 Id;
	}
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
}

[CRepr]
public struct IMAGE_RESOURCE_DIRECTORY_STRING
{
	public uint16 Length;
	public CHAR* NameString mut => &NameString_impl;
	private CHAR[ANYSIZE_ARRAY] NameString_impl;
}

[CRepr]
public struct IMAGE_RESOURCE_DIR_STRING_U
{
	public uint16 Length;
	public char16* NameString mut => &NameString_impl;
	private char16[ANYSIZE_ARRAY] NameString_impl;
}

[CRepr]
public struct IMAGE_RESOURCE_DATA_ENTRY
{
	public uint32 OffsetToData;
	public uint32 Size;
	public uint32 CodePage;
	public uint32 Reserved;
}

[CRepr]
public struct IMAGE_DYNAMIC_RELOCATION_TABLE
{
	public uint32 Version;
	public uint32 Size;
}

[CRepr, Packed(1)]
public struct IMAGE_DYNAMIC_RELOCATION32
{
	public uint32 Symbol;
	public uint32 BaseRelocSize;
}

[CRepr, Packed(1)]
public struct IMAGE_DYNAMIC_RELOCATION64
{
	public uint64 Symbol;
	public uint32 BaseRelocSize;
}

[CRepr, Packed(1)]
public struct IMAGE_DYNAMIC_RELOCATION32_V2
{
	public uint32 HeaderSize;
	public uint32 FixupInfoSize;
	public uint32 Symbol;
	public uint32 SymbolGroup;
	public uint32 Flags;
}

[CRepr, Packed(1)]
public struct IMAGE_DYNAMIC_RELOCATION64_V2
{
	public uint32 HeaderSize;
	public uint32 FixupInfoSize;
	public uint64 Symbol;
	public uint32 SymbolGroup;
	public uint32 Flags;
}

[CRepr]
public struct IMAGE_PROLOGUE_DYNAMIC_RELOCATION_HEADER
{
	public uint8 PrologueByteCount;
}

[CRepr, Packed(1)]
public struct IMAGE_EPILOGUE_DYNAMIC_RELOCATION_HEADER
{
	public uint32 EpilogueCount;
	public uint8 EpilogueByteCount;
	public uint8 BranchDescriptorElementSize;
	public uint16 BranchDescriptorCount;
}

[CRepr, Packed(1)]
public struct IMAGE_IMPORT_CONTROL_TRANSFER_DYNAMIC_RELOCATION
{
	public uint32 _bitfield;
}

[CRepr, Packed(1)]
public struct IMAGE_INDIR_CONTROL_TRANSFER_DYNAMIC_RELOCATION
{
	public uint16 _bitfield;
}

[CRepr, Packed(1)]
public struct IMAGE_SWITCHTABLE_BRANCH_DYNAMIC_RELOCATION
{
	public uint16 _bitfield;
}

[CRepr]
public struct IMAGE_HOT_PATCH_INFO
{
	public uint32 Version;
	public uint32 Size;
	public uint32 SequenceNumber;
	public uint32 BaseImageList;
	public uint32 BaseImageCount;
	public uint32 BufferOffset;
	public uint32 ExtraPatchSize;
}

[CRepr]
public struct IMAGE_HOT_PATCH_BASE
{
	public uint32 SequenceNumber;
	public uint32 Flags;
	public uint32 OriginalTimeDateStamp;
	public uint32 OriginalCheckSum;
	public uint32 CodeIntegrityInfo;
	public uint32 CodeIntegritySize;
	public uint32 PatchTable;
	public uint32 BufferOffset;
}

[CRepr]
public struct IMAGE_HOT_PATCH_HASHES
{
	public uint8[32] SHA256;
	public uint8[20] SHA1;
}

[CRepr]
public struct IMAGE_CE_RUNTIME_FUNCTION_ENTRY
{
	public uint32 FuncStart;
	public uint32 _bitfield;
}

[CRepr]
public struct IMAGE_ARM_RUNTIME_FUNCTION_ENTRY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 UnwindData;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint32 BeginAddress;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr, Union]
public struct IMAGE_ARM64_RUNTIME_FUNCTION_ENTRY_XDATA
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint32 _bitfield;
	}
	public uint32 HeaderData;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Packed(4)]
public struct IMAGE_ALPHA64_RUNTIME_FUNCTION_ENTRY
{
	public uint64 BeginAddress;
	public uint64 EndAddress;
	public uint64 ExceptionHandler;
	public uint64 HandlerData;
	public uint64 PrologEndAddress;
}

[CRepr]
public struct IMAGE_ALPHA_RUNTIME_FUNCTION_ENTRY
{
	public uint32 BeginAddress;
	public uint32 EndAddress;
	public uint32 ExceptionHandler;
	public uint32 HandlerData;
	public uint32 PrologEndAddress;
}

[CRepr]
public struct IMAGE_DEBUG_MISC
{
	public uint32 DataType;
	public uint32 Length;
	public BOOLEAN Unicode;
	public uint8[3] Reserved;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct IMAGE_SEPARATE_DEBUG_HEADER
{
	public uint16 Signature;
	public uint16 Flags;
	public uint16 Machine;
	public uint16 Characteristics;
	public uint32 TimeDateStamp;
	public uint32 CheckSum;
	public uint32 ImageBase;
	public uint32 SizeOfImage;
	public uint32 NumberOfSections;
	public uint32 ExportedNamesSize;
	public uint32 DebugDirectorySize;
	public uint32 SectionAlignment;
	public uint32[2] Reserved;
}

[CRepr, Packed(4)]
public struct NON_PAGED_DEBUG_INFO
{
	public uint16 Signature;
	public uint16 Flags;
	public uint32 Size;
	public uint16 Machine;
	public uint16 Characteristics;
	public uint32 TimeDateStamp;
	public uint32 CheckSum;
	public uint32 SizeOfImage;
	public uint64 ImageBase;
}

[CRepr]
public struct IMAGE_ARCHITECTURE_HEADER
{
	public uint32 _bitfield;
	public uint32 FirstEntryRVA;
}

[CRepr]
public struct IMAGE_ARCHITECTURE_ENTRY
{
	public uint32 FixupInstRVA;
	public uint32 NewInst;
}

[CRepr]
public struct IMPORT_OBJECT_HEADER
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint16 Ordinal;
		public uint16 Hint;
	}
	public uint16 Sig1;
	public uint16 Sig2;
	public uint16 Version;
	public uint16 Machine;
	public uint32 TimeDateStamp;
	public uint32 SizeOfData;
	public using _Anonymous_e__Union Anonymous;
	public uint16 _bitfield;
}

[CRepr]
public struct IMAGE_POLICY_ENTRY
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		public void* None;
		public BOOLEAN BoolValue;
		public int8 Int8Value;
		public uint8 UInt8Value;
		public int16 Int16Value;
		public uint16 UInt16Value;
		public int32 Int32Value;
		public uint32 UInt32Value;
		public int64 Int64Value;
		public uint64 UInt64Value;
		public PSTR AnsiStringValue;
		public PWSTR UnicodeStringValue;
	}
	public IMAGE_POLICY_ENTRY_TYPE Type;
	public IMAGE_POLICY_ID PolicyId;
	public _u_e__Union u;
}

[CRepr]
public struct IMAGE_POLICY_METADATA
{
	public uint8 Version;
	public uint8[7] Reserved0;
	public uint64 ApplicationId;
	public IMAGE_POLICY_ENTRY* Policies mut => &Policies_impl;
	private IMAGE_POLICY_ENTRY[ANYSIZE_ARRAY] Policies_impl;
}

[CRepr]
public struct HEAP_OPTIMIZE_RESOURCES_INFORMATION
{
	public uint32 Version;
	public uint32 Flags;
}

[CRepr]
public struct SUPPORTED_OS_INFO
{
	public uint16 MajorVersion;
	public uint16 MinorVersion;
}

[CRepr]
public struct MAXVERSIONTESTED_INFO
{
	public uint64 MaxVersionTested;
}

[CRepr]
public struct PACKEDEVENTINFO
{
	public uint32 ulSize;
	public uint32 ulNumEventsForLogFile;
	public uint32* ulOffsets mut => &ulOffsets_impl;
	private uint32[ANYSIZE_ARRAY] ulOffsets_impl;
}

[CRepr]
public struct TAPE_GET_DRIVE_PARAMETERS
{
	public BOOLEAN ECC;
	public BOOLEAN Compression;
	public BOOLEAN DataPadding;
	public BOOLEAN ReportSetmarks;
	public uint32 DefaultBlockSize;
	public uint32 MaximumBlockSize;
	public uint32 MinimumBlockSize;
	public uint32 MaximumPartitionCount;
	public uint32 FeaturesLow;
	public TAPE_GET_DRIVE_PARAMETERS_FEATURES_HIGH FeaturesHigh;
	public uint32 EOTWarningZoneSize;
}

[CRepr]
public struct TAPE_SET_DRIVE_PARAMETERS
{
	public BOOLEAN ECC;
	public BOOLEAN Compression;
	public BOOLEAN DataPadding;
	public BOOLEAN ReportSetmarks;
	public uint32 EOTWarningZoneSize;
}

[CRepr]
public struct TAPE_GET_MEDIA_PARAMETERS
{
	public LARGE_INTEGER Capacity;
	public LARGE_INTEGER Remaining;
	public uint32 BlockSize;
	public uint32 PartitionCount;
	public BOOLEAN WriteProtected;
}

[CRepr]
public struct TAPE_SET_MEDIA_PARAMETERS
{
	public uint32 BlockSize;
}

[CRepr]
public struct TAPE_CREATE_PARTITION
{
	public uint32 Method;
	public uint32 Count;
	public uint32 Size;
}

[CRepr]
public struct TAPE_WMI_OPERATIONS
{
	public uint32 Method;
	public uint32 DataBufferSize;
	public void* DataBuffer;
}

[CRepr]
public struct TRANSACTION_BASIC_INFORMATION
{
	public Guid TransactionId;
	public uint32 State;
	public uint32 Outcome;
}

[CRepr]
public struct TRANSACTIONMANAGER_BASIC_INFORMATION
{
	public Guid TmIdentity;
	public LARGE_INTEGER VirtualClock;
}

[CRepr]
public struct TRANSACTIONMANAGER_LOG_INFORMATION
{
	public Guid LogIdentity;
}

[CRepr]
public struct TRANSACTIONMANAGER_LOGPATH_INFORMATION
{
	public uint32 LogPathLength;
	public char16* LogPath mut => &LogPath_impl;
	private char16[ANYSIZE_ARRAY] LogPath_impl;
}

[CRepr]
public struct TRANSACTIONMANAGER_RECOVERY_INFORMATION
{
	public uint64 LastRecoveredLsn;
}

[CRepr]
public struct TRANSACTIONMANAGER_OLDEST_INFORMATION
{
	public Guid OldestTransactionGuid;
}

[CRepr]
public struct TRANSACTION_PROPERTIES_INFORMATION
{
	public uint32 IsolationLevel;
	public uint32 IsolationFlags;
	public LARGE_INTEGER Timeout;
	public uint32 Outcome;
	public uint32 DescriptionLength;
	public char16* Description mut => &Description_impl;
	private char16[ANYSIZE_ARRAY] Description_impl;
}

[CRepr]
public struct TRANSACTION_BIND_INFORMATION
{
	public HANDLE TmHandle;
}

[CRepr]
public struct TRANSACTION_ENLISTMENT_PAIR
{
	public Guid EnlistmentId;
	public Guid ResourceManagerId;
}

[CRepr]
public struct TRANSACTION_ENLISTMENTS_INFORMATION
{
	public uint32 NumberOfEnlistments;
	public TRANSACTION_ENLISTMENT_PAIR* EnlistmentPair mut => &EnlistmentPair_impl;
	private TRANSACTION_ENLISTMENT_PAIR[ANYSIZE_ARRAY] EnlistmentPair_impl;
}

[CRepr]
public struct TRANSACTION_SUPERIOR_ENLISTMENT_INFORMATION
{
	public TRANSACTION_ENLISTMENT_PAIR SuperiorEnlistmentPair;
}

[CRepr]
public struct RESOURCEMANAGER_BASIC_INFORMATION
{
	public Guid ResourceManagerId;
	public uint32 DescriptionLength;
	public char16* Description mut => &Description_impl;
	private char16[ANYSIZE_ARRAY] Description_impl;
}

[CRepr]
public struct RESOURCEMANAGER_COMPLETION_INFORMATION
{
	public HANDLE IoCompletionPortHandle;
	public uint CompletionKey;
}

[CRepr]
public struct ENLISTMENT_BASIC_INFORMATION
{
	public Guid EnlistmentId;
	public Guid TransactionId;
	public Guid ResourceManagerId;
}

[CRepr]
public struct ENLISTMENT_CRM_INFORMATION
{
	public Guid CrmTransactionManagerId;
	public Guid CrmResourceManagerId;
	public Guid CrmEnlistmentId;
}

[CRepr]
public struct TRANSACTION_LIST_ENTRY
{
	public Guid UOW;
}

[CRepr]
public struct TRANSACTION_LIST_INFORMATION
{
	public uint32 NumberOfTransactions;
	public TRANSACTION_LIST_ENTRY* TransactionInformation mut => &TransactionInformation_impl;
	private TRANSACTION_LIST_ENTRY[ANYSIZE_ARRAY] TransactionInformation_impl;
}

[CRepr]
public struct KTMOBJECT_CURSOR
{
	public Guid LastQuery;
	public uint32 ObjectIdCount;
	public Guid* ObjectIds mut => &ObjectIds_impl;
	private Guid[ANYSIZE_ARRAY] ObjectIds_impl;
}

#endregion

#region Functions
public static
{
	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnregisterDeviceNotification(void* Handle);

}
#endregion
