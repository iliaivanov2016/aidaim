unit ESFSEngine;

{$I ESFSVer.inc}

interface

{DEFINE DEBUG_FLAG}

uses sysutils,classes, windows,
{$IFNDEF X64_ON}
     ESFSStrFunc,
{$ENDIF}
     ESFSPassword,ESFSDECUtil,ESFSCipher,ESFSCipher1,
     ESFSFileCtrl
{$IFDEF D12H}
     ,ESFS_d12h
{$ENDIF}
{$IFDEF DEBUG_LOG}
,ESFSDebug
{$ENDIF}
     ;

const
      crlf = #13#10;
      ESingleFileSystemSignature = 'AASFSSGN';
			ESFSStreamSignature = 'AACS';
      SignatureSize = 8;
      ESFSCurrentVersion = 12.00;
      FormatVersion = 1.00;
      DEFAULT_PAGE_SIZE = 4*1024; // size of one page in bytes
      DEFAULT_EXTENT_PAGE_COUNT = 8; // number of Pages per one extent
      // page types
      DIRPage  = 1; // directory
      GAMPage  = 2; // global allocation map
      SGAMPage = 3; // shared global allocation map
      PFSPage  = 4; // page free space
      UFPMPage = 5; // user file page map
      UFPage   = 6; // user file
      // root id
      rootID = -1;
      // error codes
      erOk = 0;
      erInvalidPath = -2;
      erInvalidCurrentDir = -3;
      erInvalidSearchRec = -4;
      erFileNotFound = -5;
      erInvalidHandle = -6;
			erReadPageHeaderError = -7;
			erWritePageHeaderError = -8;
			erReadPageError = -9;
			erWritePageError = -10;
			erCRCError = -11;
			erDecodeError = -12;
			erEncodeError = -13;
      erNoMemory = -14;
   		erRenameFileError = -15;
   		erFileNotDeleted = -16;
      erDiskFull = -17;
      erInvalidUFMap = -18;
      erReadPageFailed = -19;
      // no - no link, no element, etc.
      None = -1;
      // Encryption modes
      encNone = 0;
      encRijndael = 1;

      SPasswordTitle = 'Password for "%s"';
      SPasswordPrompt = 'Enter password: ';

var   UNIFORM_MIN_PAGE_COUNT : Integer = DEFAULT_EXTENT_PAGE_COUNT;
var   debugFlag: Boolean = false;

const WildCardMultipleChar = '*';
const WildCardSingleChar = '?';
const WildCardAnyFile = '*.*';

type
// TFileStoreMode = (fsmDisk, fsmInMemory);

      pByte = ^Byte;

      TSingleFileHeader = packed record
       Signature:         array [0..7] of AnsiChar;
       CRC:               Cardinal; // check sum for other fields in header
       Version:           Single;  // format version
       PageSize:          Integer; // size in bytes
       ExtentPageCount:   Integer; // extent size in pages
       HDRPageCount:      Integer; // number of pages occupied by HEADER, usually 1
       GAMPageCount:      Integer; // number of pages occupied by GAM
       PFSPageCount:      Integer; // number of pages occupied by PFS
       DIRPageCount:      Integer; // number of pages occupied by DIRECTORY
       DIRFirstPageNo:    Integer; // No of first page occupied by DIRECTORY
       DIRElementsCount:  Integer;// DIR elements quantity = files and folders qty
       TOTALPageCount:    Integer;// number of pages in file
       PasswordHeader:		TPasswordHeader; // password header
       EncMethod:					Byte; // 0 - none, 1 - Rijndael
       CompressionLevel:	Byte; // default compression level
       Reserved:					array [0..29] of Byte;
      end;

      TPageHeader = packed record
       NextPageNo:    Integer;  // used for building page chains
       CRC:         	Cardinal; // check sum for page
       PageType:      Byte; // header, dir, ... page
       EncType:       Byte; // 0 - None, 1-Rijndael, ...
       CrcType:       Byte; // 0 - Fast, 1- Full
       reserved1:     Byte;  // for future extension
       reserved2:     array [0..19] of Byte;  // for future extending
      end;

      TFFPage = packed record
       PageHeader:    TPageHeader; // header of page
       pData:         Pointer; // pointer to data stored in page
      end;

     // this is Single-file directory element
     // user-defined folders not supported yet
     // compression, CRC protection and encryption not supported yet
     // last access and last modified times will supported later
     // if IsCrcProtected not specified,
     //  if IsEncrypted specified - in FileCRC will be stored
     //   only first page check sum.
     TDirectoryElement = packed record
       FirstMapPageNo:  Integer;   // number of first file map page no
       FileSize:        Int64;  // file size in bytes
       CreationTime:    TFileTime; // creation time
       LastModifiedTime:TFileTime; // last modification time
       LastAccessTime:  TFileTime; // last access time
       Attributes:      LongWord;   // file id (unique number)
       ParentID:        Integer;   // id of parent folder
                                   // -1 - root
       FileCRC:       	Cardinal;  // file check sum (not used)
       PasswordHeader:	TPasswordHeader; // password         172 bytes
       IsFolder:        Byte;      // 0 - no, 1 - yes
       IsDeleted:       Byte;      // 0 - no, 1 - yes
       EncMethod:  		  Byte;      // 0 - none, 1 - Rijndael
			 Reserved1:  			Byte;      //

       FileName:        array[0..MAX_PATH - 1] of AnsiChar;  // file name (0-terminated)
       Reserved2:       array [0..6] of Integer; //
      end;
     pDirectoryElement = ^TDirectoryElement;

      TEmptyPageElement = packed record
       pageNo:    Integer; // start block of empty area
       pageCount: Integer; // number of pages in this area
      end;

      TUserFileHandle = packed record
       FileID:     	Integer; // ID of Directory Element for this file
       Position:    Int64;  // currentPosition
       Mode:				LongWord; // open mode
       Key:					String;
      end;
      pUserFileHandle = ^TUserFileHandle;

const
 // maximum block size for stream classes, LoadFromStream / SaveToStream
 DefaultMaxBlockSize = 1024 * 1024; // 1.0 Mb for eclNone
 BlockSizeForFastest = 512 * 1024; // 0.5 Mb for fastest modes
 BlockSizeForNormal = 1024 * 1024; // 1.0 Mb for normal modes
 BlockSizeForMax = 1536 * 1024; // 1.5 Mb for max modes
 DefaultCopyBlockSize = 100 * 1024; // block size for copy operation

 PPM_FASTEST_MO = 3;
 PPM_FASTEST_SA = 10; // Mb
 PPM_NORMAL_MO = 5;
 PPM_NORMAL_SA = 25; // Mb
 PPM_MAX_MO = 13;
 PPM_MAX_SA = 50; // Mb

 CRC32_checksum = 1;

 DefaultCompressionLevel = 1;
 Default_Crc_Method = CRC32_checksum;

 ESFSCompressCurrentVersion = 2.0;
 ESFSDirectoryElementSize = sizeof(TDirectoryElement);
 ESFSPageHeaderSize = sizeof(TPageHeader);
 // commented by Leo Martin, Ezt 5.40
// MIN_PAGE_SIZE = ESFSDirectoryElementSize + ESFSPageHeaderSize; // minimum size of one page in Kbytes
//var MIN_PAGE_SIZE: Integer = 2 * 1024;
var MIN_PAGE_SIZE: Integer = ESFSDirectoryElementSize + ESFSPageHeaderSize;

type
 TESFSFileStreamHeader = packed record
       signature:       array [0..3] of AnsiChar; // signature
       BlockSize:       Integer; // block size
       Crc32:           LongInt;  // crc of control block
       NumBlocks:       Integer;  // number of blocks
       version:         Single;   // version
       compressionLevel: Byte; // compression level
       CrcMode:         Byte; // check sum method
       EncMethod:       Byte; // encryption algorithm
       CustomHeaderSize:Integer;	// size of custom header
       reserved:        array [0..0] of AnsiChar; // reserved
       controlBlock:	  array [0..99] of AnsiChar; // control for encryption
 end;

 TESFSHeader = packed record
       packedSize:    Cardinal; // packed block size
       trueSize:      Cardinal; // unpacked block size
       Crc32:         Cardinal; // check sum for this block page
// FIsESFSRelativeOffsets = true
// 2.70 and higher:
       nextHeaderNo:  Cardinal; // offset from the prior block
                                // to the beginning of this block
// FIsESFSRelativeOffsets = false
// 2.60 and earlier:
//       nextHeaderNo:  Cardinal; // offset from beginning of compressed file
//                                // to next block header
 end;

const
 ESFSCompressedHeaderSize = sizeof(TESFSHeader); // size in bytes (16)
 ESFSFileStreamHeaderSize = sizeof(TESFSFileStreamHeader); // size in bytes (16)

type

 TESFSHeadersArray = class
    private
     AllocBy:             integer;
     DeAllocBy:           integer;
     MaxAllocBy:          integer;
     AllocItemCount:      integer;
    public
     Items:               array of TESFSHeader;
     Positions:           array of Int64; // block positions
     ItemCount:           integer; // all files quantity (including deleted files)
    public
     constructor Create;
     destructor Destroy; override;
     procedure SetSize(newSize: integer);
     procedure AppendItem(value: TESFSHeader; pos: Int64);
     function FindPosition(pos: Int64) : Integer;
   end; // TESFSHeadersArray

 // progress event
 TESFSProgressEvent = procedure 	(
                              Sender      : TObject;
                              PercentDone : Real;
                              var Cancel: Boolean
                             		)  of object;

 // progress event
 TESFSNoCancelProgressEvent = procedure 	(
                              Sender      : TObject;
                              PercentDone : Real
                             		)  of object;

 // progress event
 TESFSFileProgressEvent = procedure 	(
                              Sender:       TObject;
                              PercentDone:  Real;
                              // including relative path
                              FileName:   AnsiString
                             		)  of object;
 // progress event
 TESFSOverwritePromptEvent = procedure 	(
                              Sender:   TObject;
                              // file being overwritten
                              ExistsingFileName: AnsiString;
                              // with:
                              NewFileName: AnsiString;
                              // set to true to overwrite
                              var bOverwrite: Boolean
                             		)  of object;

 // disk full event
 TESFSDiskFullEvent = procedure 	(
                              Sender: TObject
                             		)  of object;

 // occurs when password needed
 TESFSOnPasswordEvent = procedure(
                           Sender: TObject;
                           FileName: AnsiString;
                           var NewPassword: AnsiString;
                           var SkipFile: Boolean
                           ) of object;

   TIntegerArray=class
    public
     Items: array of integer;
     ItemCount: integer;
     CurrentItem: integer; // used by findnext
     AllocBy: integer;
     deAllocBy: integer;
     MaxAllocBy: integer;
     AllocItemCount: integer;

    constructor Create(size: integer=0;
                defaultAllocBy: Integer = 1000; defaultMaxAllocBy: Integer = 10000);
     destructor Destroy; override;
     procedure SetSize(newSize: integer);
     procedure Append(value: integer);
     procedure Insert(ItemNo: integer; value: integer);
     procedure Delete(ItemNo: integer);
     procedure MoveTo(itemNo, newItemNo : integer);
     procedure CopyTo(var ar : array of Integer;
                    itemNo,iCount : integer);
     procedure Sort(Ascending: Boolean);
   end;

   TSortedPtrArray=class
    private
     uniqueKeyValue: Integer;
     AllocBy: integer;
     deAllocBy: integer;
     MaxAllocBy: integer;
     AllocItemCount: integer;

     function FindPositionForInsert(key: Integer) : Integer;
     function FindPosition(key: Integer): Integer;
     procedure InsertByPosition(ItemNo: integer; key: integer; value: Pointer);
     procedure DeleteByPosition(ItemNo: integer);

    public
     KeyItems: array of integer;
     ValueItems: array of Pointer;
     ItemCount: integer;

    constructor Create(size: integer=0;
                defaultAllocBy: Integer = 1000; defaultMaxAllocBy: Integer = 10000);
     destructor Destroy; override;
     procedure 	SetSize(newSize: integer);
     function 	Find(key: Integer) : Pointer;
     procedure 	Insert(key: integer; value: Pointer);
     procedure 	Delete(key: integer);
     function 	GetNextKeyValue: Integer;
   end;

   TDIRArray = class
    private
     AllocBy:             integer;
     MaxAllocBy:          integer;
     AllocItemCount:      integer;
    public
     FoundItems:          array of TIntegerArray;
     Items:               array of TDirectoryElement;
     NameIndex:           TIntegerArray;
     ParentIndex:         TIntegerArray;
     FoundItemCount:      integer; // number of foundItems arrays
     ItemCount:           integer; // all files quantity (including deleted files)
     IndexElementsCount:  integer; // double files qunatity (excluding deleted)

     procedure BuildIndexes;
    public
     constructor Create(size: integer=0;
            			     defaultAllocBy: Integer = 2; defaultMaxAllocBy: Integer = 200);
     destructor Destroy; override;
     procedure SetSize(newSize: integer);
     function FindPositionForInsert(value: TDirectoryElement;
                   bByName: Boolean = true;
                   bFirst:  Boolean = false;
                   bInsert: Boolean = true
                   ) : Integer;
     // Find file by name (with path)
     // returns -1 if root directory found
     // returns <-1 if file not found
     // >= 0 - directory element number if fili found
     function FindFileByName(FileName: PAnsiChar; startDir: Integer = rootID): Integer;
     // returns full file path (form root, '\folder1\folder2')
     function GetFullFilePath(ItemNo: Integer): AnsiString;
     // prepares searchRec
     procedure PrepareSearchRecord(ItemNo: Integer; var F: TSearchRec);
     // find file by pattern using '*', '?'
     // returns 0 if file was found, otherwise returns error code
     function FindFirst(const Path: AnsiString; Attr: Integer; var F: TSearchRec;
              currentDir: Integer = rootID): Integer;
     function FindNext(var F: TSearchRec): Integer;
     procedure FindClose(var F: TSearchRec);
     // edit / read items
     procedure AppendItem(value: TDirectoryElement);
     procedure UpdateItem(value: TDirectoryElement; position: Integer);
     function  ReadItem(position: integer): TDirectoryElement;
   end;

 // Page manager
 TPageFileManager = class (TObject)
	public
   ESFSFile:    TESFSHugeFile;   // Single file
	private
   // calc offset by page no
   function PageNoToOffset(PageNo: integer): Int64;

   // encode buffer
   function EncodeBuffer(buffer: PAnsiChar; Size: LongInt;
                         EncType: byte; Password: AnsiString): boolean;
  public

   // decode buffer
   function DecodeBuffer(buffer: PAnsiChar; Size: LongInt;
                         EncType: byte; Password: AnsiString): boolean;

   // attempt to load Single file header from specified offset
   function InternalLoadHeader(FileOffset: Int64): boolean;

   // returns page data size without header
   function GetPageDataSize: LongInt;

   // set in-memory or disk mode
   procedure SetInMemory(Value: boolean);

  public
   FFileName:            AnsiString;  // Single file name with full path and extension
   FInMemory:            boolean; // in memory file or disk file?
   FHeader:              TSingleFileHeader;  // Single file header
   FReadOnly:            Boolean;
   FExclusive:           Boolean;
   FKey:						 		 AnsiString;
   FLastError:					 Integer; // error code for last operation
   FPassword:            AnsiString;
   // constructor
   constructor Create(const FileName: AnsiString; Mode: Word;
               Password: AnsiString = '';
               Question: AnsiString = '';
               Answer: AnsiString = '';
               IsInMemory: boolean = false;
               PageSize: Integer = DEFAULT_PAGE_SIZE;
               ExtentPageCount: Integer = DEFAULT_EXTENT_PAGE_COUNT;
               PartFileSize: Int64 = -1
               );

   // destructor
   destructor Destroy; override;

   // load Single file header
   procedure LoadSFHeader;

   // save Single file  header
   procedure SaveSFHeader;

   // allocate and init page
   procedure AllocPageBuffer(var FFPage: TFFPage);

   // free page
   procedure FreePageBuffer(FFPage: TFFPage);

   // read page
   function ReadPage(var buffer: TFFPage; PageNo: Integer;
                     Size: Integer = -1;
                     Password: string='';
                     bIgnoreEncrypted: Boolean = false
                     ): boolean;

   // write page
   function WritePage(var buffer: TFFPage; PageNo: Integer;
                      Size: Integer = -1;
                      Password: string=''): boolean;

   // append pages to the end of file
   function AppendPages(qty: Integer): Boolean;

   // deletes pages from end of file
//   procedure DeletePagesFromEOF(qty: Integer);

   // rename file
   function RenameFile(NewName: AnsiString): Boolean;

   // delete file
   function DeleteFile: Boolean;

   // flush file buffers
   procedure FlushFileBuffers;

   // load data from stream
   procedure LoadFromStream(Stream: TStream);

   // free space on disk
   function DiskFree: Int64;

  public
   property PageDataSize: LongInt read GetPageDataSize;
   // in memory mode
   property InMemory: Boolean read FInMemory write SetInMemory;
 end;

 // free space manager
 TFreeSpaceManager = class
  public
   PFMHandle:  TPageFileManager; // page manager
  private
   PFS:         PAnsiChar; // Page Free Space bits (all pages)
   GAM:         PAnsiChar; // Global Allocation Map bits (all pages)
   SGAM:        PAnsiChar; // Shared Global Allocation Map bits (all pages)
   PFSPageMap:  TIntegerArray; // PFS page map
   GAMPageMap:  TIntegerArray; // GAM page map
   FPageSize:   Integer;  // double page size (FHeader.PageSize - sizeof(TPageHeader)
   FGAMPageSize:        Integer; // GAM page size in bytes (only used by bitmap)
   FGAMExtentsPerPage:  Integer; // numer of extents per 1 page (maximum)
   FPFSExtentsPerPage:  Integer; // numer of extents per 1 page (maximum)
   FPFSPageSize:        Integer; // PFS page size in bytes (only used by bitmap)
   FExtentPageCount:  Integer; // number of pages per one extent
   FFreeExtentCount:  Integer; // number of free extents
   FMixedExtentCount: Integer; // number of mixed extents
   FExtentCount:      Integer; // number of existing extents
   FPageCount:        Integer; // number of pages in PFS
  private
{$IFDEF DEBUG_FLAG}
procedure WriteMemoryUsage;
{$ENDIF}

   // load procedures
   procedure LoadPFS;
   procedure LoadGAM;
   // save PFS pages
   procedure SavePFS(pages: TIntegerArray);
   // save GAM pages
   procedure SaveGAM(pages: TIntegerArray);
   // returns number of GAM page
   function GetGAMPageNo(extentNo: Integer): Integer;
   // returns number of PFS page
   function GetPFSPageNo(extentNo: Integer): Integer;
  public
   // constructor
   constructor Create(PageFileManager: TPageFileManager);
   // destructor
   destructor Destroy; override;
   // get pages sequence
   function GetPages(PageCount, StartPageNo: Integer; bUniform: Boolean;
                     var pages: TIntegerArray): Boolean;
   // free pages sequence
   procedure FreePages(var pages: TIntegerArray);
   // returns free page count
   function GetFreePageCount: Int64;
 end;


 // directory manager
 TDIRManager = class
  private
   FSMHandle:  TFreeSpaceManager; // space manager
   DIRPageMap: TIntegerArray;
   FDIRElementsPerPage: Integer;
   FDIRPageSize:        Integer;
{$IFDEF DEBUG_FLAG}
procedure WriteMemoryUsage;
{$ENDIF}
  public
   PFMHandle:  TPageFileManager; // page manager
public
// protected
   FDIR:       		TDirArray;
   FOpenedFiles:  TIntegerArray; // each element in this array corresponds number of
                             // opened file handles for this file
                             // default value = 0
   FLastError: Integer; // code of last error
//  private
   // load dir
   procedure Load;
   // appends element to DIR
   // if it was unable to Append this element - returns false
   function AddItem(item: TDirectoryElement): Boolean;
   // read item
   procedure ReadItem(ItemNo: Integer; var item: TDirectoryElement);
   // write item
   procedure WriteItem(ItemNo: Integer; item: TDirectoryElement);
//  protected
   // find by name, returns element number or erFileNotFound if no element were found
   function FindByName(FileName: AnsiString): Integer;
	 // returns full file path (form root, '\folder1\folder2')
   function GetFullFilePath(ItemNo: Integer): AnsiString;
   // creates file, returns returns erFileNotFound if file can not be created;
   // if file created successfully return value will be index of directory element
   function FileCreate(const FileName: AnsiString;
						 Password: AnsiString = '';
						 Question: AnsiString = '';
						 Answer: AnsiString = ''
		         ): Integer;
   // open file if it is possible; returns erFileNotFound if file does not exists
   // returns Key if file is encrypted
   function FileOpen(const FileName: AnsiString; Password: AnsiString;
    					var Key: AnsiString): Integer;
   // file close (itemNo - index of directory element for the file)
   procedure FileClose(ItemNo: Integer);
	 // renames file
	 function RenameFile(const OldName, NewName: AnsiString): Boolean;
   // returns number of opened files for specified directory element
   function GetOpenFiles(ItemNo: Integer): Integer;
   // returns true and restores password if control answer is valid
   function RestorePasswordByControlAnswer(FileName: AnsiString; Answer: AnsiString; var Password: AnsiString): Boolean;
   // returns true if Single file password is valid
   function IsPasswordValid(FileName: AnsiString; Password: AnsiString): Boolean;
   // returns control question
	 function GetControlQuestion(FileName: AnsiString): AnsiString;
   // returns password header
	 function GetPasswordHeader(FileName: AnsiString; var passHeader: TPasswordHeader): Boolean;
   // sets password header
	 procedure SetPasswordHeader(FileName: AnsiString; passHeader: TPasswordHeader);
   // returns true if file is encrypted by its own password
	 function IsFileEncrypted(FileName: AnsiString): boolean;
  public
   CurrentPath: AnsiString;
   CurrentDir:  integer;
   // constructor
   constructor Create(PageFileManager: TPageFileManager;
                      FreeSpaceManager: TFreeSpaceManager);
   // destructor
   destructor Destroy; override;
   //----------------------- User Interface ----------------------------------
   // find file by pattern using '*', '?'
   function FindFirst(const Path: AnsiString; Attr: Integer; var F: TSearchRec): Integer;
   function FindNext(var F: TSearchRec): Integer;
   procedure FindClose(var F: TSearchRec);
   // returns current directory name ('\' if root directory )
   function GetCurrentDir: AnsiString;
   // return value set to True if directory successfully changed
   function SetCurrentDir(const Dir: AnsiString): Boolean;
   // removes directory
   function RemoveDir(const Dir: AnsiString): Boolean;
   // creates directory
   function CreateDir(const Dir: AnsiString): Boolean;
   // Creates all the directories along a directory path if they do not already exist
   function ForceDirectories(Dir: AnsiString): Boolean;
   // determines whether a specified directory exists.
   function DirectoryExists(Name: AnsiString): Boolean;
 end;

 // User Files Page Maps
 TUserFilePageMapManager = class(TObject)
  public
   PFMHandle:  TPageFileManager; // page manager
   FLastError: Integer; // error No
 private
  FSMHandle:        TFreeSpaceManager; // free space manager
  UFPMMaps:         TSortedPtrArray;   // pointers to UFPM map
  UFMaps:           TSortedPtrArray;   // pointers to user files maps
  PagesPerMapPage:  Integer;           // how many user file pages are addressed by one map page
  TempPages:        TIntegerArray;         // internal temp array

{$IFDEF DEBUG_FLAG}
procedure WriteMemoryUsage;
{$ENDIF}
  // get quantity of pages covering specified size
  function GetCoverPageCount(Size: Int64): integer;
  // get file maps - find or load (file is indentified by FirstMapPageNo)
  procedure GetMaps(var FileRec: TDirectoryElement; var UFPMMap: TIntegerArray; var UFMap: TIntegerArray);
  // append pages to the end of file (file is indentified by FirstMapPageNo)
  function AppendPages(var FileRec: TDirectoryElement; PageCount: integer; bWriteAppendedPages: boolean): Boolean;
  // delete pages from the end of file (file is indentified by FirstMapPageNo)
  procedure DeletePagesFromEOF(var FileRec: TDirectoryElement; PageCount: integer);
  // save UFPM pages
  procedure SaveMapPages(ItemNo, ItemCount: integer; UFPMMap, UFMap: TIntegerArray);

 public
  // constructor
  constructor Create(PFMHandle1: TPageFileManager; FSMHandle1: TFreeSpaceManager);
  // destructor
  destructor Destroy; override;
  // get pages from file (FirstMapPageNo) starting from Offset to cover Size
  // can allocate additional pages, returns list of FF pages
  // FirstMapPageNo=-1 corresponds to the new created file
  function GetPages(var FileRec: TDirectoryElement; Offset, Size: Int64;
                     IsAllocateAllowed: boolean; var pages: TIntegerArray): Boolean;
  // set size of file (FirstMapPageNo)
  // FirstMapPageNo=-1 corresponds to the new created file
  function SetSize(var FileRec: TDirectoryElement; NewSize: Int64; bWriteAppendedPages: boolean=True): Boolean;
 end;

	// checks if AnsiString matches pattern
	function IsStrMatchPattern(StrPtr: PAnsiChar; PatternPtr: PAnsiChar; bIgnoreCase:boolean = true): Boolean;
	// extracts path and pattern
	function ExtractPathAndPattern(InPath: PAnsiChar; var OutPath, Pattern: PAnsiChar): Boolean;
	// writes current time to filetime field in TDirectoryElement
	procedure SetCurrentTime(var fTime: TFileTime);
	// writes filename and alternateFileName to TDirectoryElement
	procedure SetFileName(FileName: AnsiString; var el: TDirectoryElement);
	//initialization of directory element
	procedure InitDirectoryElement(var el: TDirectoryElement);

const
      SingleFileHeaderSize = sizeof(TSingleFileHeader); // size in bytes (256)
      PageHeaderSize  = sizeof(TPageHeader); // size in bytes (32)
      DirElementSize = sizeof(TDirectoryElement); // size in bytes (512)
      UserFileHandleSize = sizeof(TUserFileHandle); // size in bytes (16)

 // set bit in bit map
 // bit = 1 if bSet = true, otherwise bit = 0
 procedure SetBit(BitMap: PAnsiChar; BitNo: Integer; bSet: Boolean);
 // get bit from bitmap, returns true if bit = 1, otherwise returns false
 function GetBit(BitMap: PAnsiChar; BitNo: Integer): Boolean;

implementation


////////////////////////////////////////////////////////////////////////////////
//
// TESFSHeadersArray
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TESFSHeadersArray.Create;
begin
 AllocBy := 100; // default alloc
 DeAllocBy := 100; // default alloc
 MaxAllocBy := 10000; // max alloc
 AllocItemCount := 0;
 ItemCount := 0;
 SetSize(0);
end; // Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TESFSHeadersArray.Destroy;
begin
 SetSize(0);
 inherited Destroy;
end;//Destroy;


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TESFSHeadersArray.SetSize(newSize: integer);
begin
 if (newSize = 0) then
  begin
   ItemCount := 0;
   allocItemCount := 0;
   Items := nil;
   Positions := nil;
   Exit;
  end;

 if (newSize > allocItemCount) then
  begin
     AllocBy := AllocBy * 2;
     if (AllocBy > MaxAllocBy) then
      AllocBy := MaxAllocBy;
     if (allocItemCount + AllocBy > newSize) then
      allocItemCount := allocItemCount + AllocBy
     else
      allocItemCount := newSize;
     SetLength(Items,allocItemCount);
     SetLength(Positions,allocItemCount);
  end
 else
  if (newSize < ItemCount) then
   if (allocItemCount-newSize > deAllocBy) then
    begin
     deAllocBy := deAllocBy * 2;
     if (deAllocBy > MaxAllocBy) then
      deAllocBy := MaxAllocBy;
     SetLength(Items,newSize);
     SetLength(Positions,newSize);
     allocItemCount := newSize;
    end;
 ItemCount := newSize;
end;// SetSize


//------------------------------------------------------------------------------
// Finds block containing specified position in user data
//------------------------------------------------------------------------------
function TESFSHeadersArray.FindPosition(pos: Int64) : Integer;
var i,dx,f,
    oldRes,res : Integer;

 function Compare: Integer;
 begin
  //---------------------------- start of compare -----------------------------------
       // by parent
       if (Positions[i] = pos) then
        Result := 0
       else
        if (Positions[i] < pos) then
         Result := 1
        else
         Result := -1;
  //---------------------------- end of compare -----------------------------------
 end;

begin

 i := ItemCount shr 1;
 dx := i;
 result := 0;
 if (ItemCount <= 0) then
  begin
   result := 0;
   Exit;
  end;
  f := 0;
  res := 2;
  while (true) do
   begin
    dx := dx shr 1;
    if (dx < 1) then dx := 1;
     oldRes := res;
     // compare, ascending
     res := Compare;
    if (res < 0) then
     begin
      //  element, specified by value should be higher then current element (+->0)
      i := i - dx;
     end
    else
    if (res > 0) then
     begin
      //  element, specified by value should be lower then current element (+->0)
      i := i + dx;
     end
    else
     begin
      // values are equal
      Result := i;
      break;
     end;
    if  (i < 0) and (dx = 1) then
     begin
      // equal not found
      result := 0;
      break;
     end;
    if  (i > ItemCount-1) and (dx = 1) then
     begin
      // equal not found
      result := ItemCount;
      break;
     end;

    if  (i > ItemCount-1) then
     i := ItemCount-1;
    if  i < 0 then
     i := 0;

    if (dx = 1) and (f > 1) then
     begin
      // dx minimum
      // compare, ascending
      res := Compare;
      if (res < 0) and (oldRes > 0) then
       Result := i;
      if (res > 0) and (oldRes < 0) then
       Result := i+1;
      if (res = oldRes) then
       continue;
      break;
     end;// last step
    if (res <> oldRes) and (dx = 1) and (oldRes <> 2) then
     inc(f);
  end;//while dx
 if (result >= ItemCount) then
     Result := ItemCount-1;
 if (result > 0) then
  if (Positions[result] > pos) then
   dec(result);
 if (result < 0) then
   Result := 0;
end; //FindPosition


//------------------------------------------------------------------------------
// Insert an element into specified position
//------------------------------------------------------------------------------
procedure TESFSHeadersArray.AppendItem(value: TESFSHeader;  pos: Int64);
begin
 inc(ItemCount);
 SetSize(ItemCount);
 Items[ItemCount-1] := value;
 Positions[ItemCount-1] := pos;
end; // AppendItem



////////////////////////////////////////////////////////////////////////////////
//
// TIntegerArray
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TIntegerArray.Create(size: integer=0;
            defaultAllocBy: Integer = 1000; defaultMaxAllocBy: Integer = 10000);
begin
 AllocBy := defaultAllocBy; // default alloc
 deAllocBy := defaultAllocBy; // default dealloc
 MaxAllocBy := defaultMaxAllocBy; // max alloc
 AllocItemCount := 0;
 SetSize(size);
end;//TIntegerArray.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TIntegerArray.Destroy;
begin
 Items := nil;
 inherited Destroy;
end;//TIntegerArray.Destroy;


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TIntegerArray.SetSize(newSize: integer);
begin
{
 ItemCount := newSize;
 if (ItemCount > 0) then
  SetLength(Items,ItemCount)
 else
  Items := nil;
Exit;
}
 if (newSize = 0) then
  begin
   ItemCount := 0;
   allocItemCount := 0;
   Items := nil;
   Exit;
  end;

 if (newSize > allocItemCount) then
  begin
     AllocBy := AllocBy * 2;
     if (AllocBy > MaxAllocBy) then
      AllocBy := MaxAllocBy;
     if (allocItemCount + AllocBy > newSize) then
      allocItemCount := allocItemCount + AllocBy
     else
      allocItemCount := newSize;
     SetLength(Items,allocItemCount);
  end
 else
  if (newSize < ItemCount) then
   if (allocItemCount-newSize > deAllocBy) then
    begin
     deAllocBy := deAllocBy * 2;
     if (deAllocBy > MaxAllocBy) then
      deAllocBy := MaxAllocBy;
     SetLength(Items,newSize);
     allocItemCount := newSize;
    end;

 ItemCount := newSize;
end;//TIntegerArray.SetSize


//------------------------------------------------------------------------------
// inserts an element to the end of items array
//------------------------------------------------------------------------------
procedure TIntegerArray.Append(value: integer);
begin
 SetSize(itemCount + 1);
 Items[itemCount-1] := value;
end;//TIntegerArray.Append


//------------------------------------------------------------------------------
// Insert an element into specified position
//------------------------------------------------------------------------------
procedure TIntegerArray.Insert(itemNo: integer; value: integer);
begin
 inc(ItemCount);
 SetSize(ItemCount);

//aaStartTime;
 if (itemCount <= 1) then
  items[0] := value
 else
 if (itemNo >= itemCount-1)
  then
   items[itemCount-1] := value
  else
   begin
    Move(items[itemNo],items[itemNo+1],
        (itemCount - itemNo-1) * sizeOf(integer));
    items[itemNo] := value;
   end;
//aaStopTime;
end;//TIntegerArray.Insert


//------------------------------------------------------------------------------
// Delete an element at specified position
//------------------------------------------------------------------------------
procedure TIntegerArray.Delete(itemNo: integer);
begin
 if (itemNo < itemCount-1) then
  Move(items[itemNo+1],items[itemNo],
      (itemCount - itemNo-1) * sizeOf(integer));
 dec(ItemCount);
 SetSize(ItemCount);
end;//TIntegerArray.Delete


//------------------------------------------------------------------------------
// moves element to new position
//------------------------------------------------------------------------------

procedure TIntegerArray.MoveTo(itemNo, newItemNo : integer);
var value : Integer;
begin
 if (itemNo = newItemNo) then
  Exit;
 if (itemNo - newItemNo = 1) or (newItemNo-itemNo = 1) then
  begin
   value := items[itemNo];
   items[itemNo] := items[newItemNo];
   items[newItemNo] := value;
   Exit;
  end;
 if (itemNo > newItemNo) then
  begin
   value := items[itemNo];
   Move(items[newItemNo],items[newItemNo+1],
        (itemNo-newItemNo) * sizeof(Integer));
   items[newItemNo] := value;
  end
 else
  begin
     value := items[ItemNo];
     Move(items[ItemNo+1],items[ItemNo],
        (newItemNo-ItemNo-1) * sizeof(Integer));
     items[newItemNo-1] := value;
  end;
(*
var value : integer;
begin
 if (itemNo = newItemNo) then
  Exit;
 if (itemNo - newItemNo = 1) or (newItemNo-itemNo = 1) then
  begin
   value := items[itemNo];
   items[itemNo] := items[newItemNo];
   items[newItemNo] := value;
   Exit;
  end;
 if (itemNo > newItemNo) then
  begin
   value := items[itemNo];
   Move(PAnsiChar(items[newItemNo]),PAnsiChar(items[newItemNo+1]),
        (itemNo-newItemNo) * sizeof(integer));
   items[newItemNo] := value;
  end
 else
  begin
     value := items[ItemNo];
     Move(PAnsiChar(items[ItemNo+1]),PAnsiChar(items[ItemNo]),
        (newItemNo-ItemNo-1) * sizeof(integer));
     items[newItemNo-1] := value;
  end;
*)
end; //MoveTo(itemNo, newItemNo : integer);


//------------------------------------------------------------------------------
// copies itemCount elements to ar from ItmeNo
//------------------------------------------------------------------------------
procedure TIntegerArray.CopyTo(var ar : array of Integer;
                      itemNo,iCount : integer);
begin
(*
 if (itemCount > 0) then
  Move (pAnsiChar(items[itemNo]),pAnsiChar(ar[0]),sizeOf(integer)*iCount);
*)
if (itemCount > 0) then
  Move (items[itemNo],ar[0],sizeOf(Integer)*iCount);
end; //CopyTo(ar : array of Integer; itemNo,itemCount : integer);


//------------------------------------------------------------------------------
// sort array
//------------------------------------------------------------------------------
procedure TIntegerArray.Sort(Ascending: Boolean);
var
 aLo, aHi : Integer;

 function Compare(num1,num2: Integer): Integer;
 begin
  if (num1 = num2) then
   Result := 0
  else
  if (num1 > num2) then
   Result := 1
  else
   Result := -1;
  if (not Ascending) then
   Result := - Result; 
 end; // Compare

 procedure QuickSort (
                    var iLo, iHi : Integer
                    );
  var
    Lo, Hi, Mid, T: Integer;
  begin
    Lo := iLo;
    Hi := iHi;
    Mid := Items[(Lo + Hi) shr 1];
    repeat
     while (Compare(Items[Lo],Mid) < 0) and (Lo < iHi) do
      Inc(Lo);
     while (Compare(Items[Hi],Mid) > 0) and (Hi > 0) do
       Dec(Hi);
      if (Lo <= Hi) then
       begin
        T := Items[Lo];
        Items[Lo] := Items[Hi];
        Items[Hi] := T;
        Inc(Lo);
        Dec(Hi);
       end;
    until (Lo > Hi);
    if (Hi > iLo) then
     begin
      // check infinite recurse
      if (iHi = Hi) then
       raise Exception.Create('ESFSEngine - Sorting error in TIntegerArray');
      QuickSort(iLo, Hi);
     end;
    if (Lo < iHi) then
      QuickSort(Lo, iHi);
  end; //QuickSort
begin
  if (ItemCount > 1) then
   begin
    aLo := 0;
    aHi := ItemCount-1;
    QuickSort (aLo, aHi);
   end;
end; // Sort


////////////////////////////////////////////////////////////////////////////////
//
// TSortedPtrArray
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TSortedPtrArray.Create(size: integer=0;
                defaultAllocBy: Integer = 1000; defaultMaxAllocBy: Integer = 10000);
begin
 uniqueKeyValue := -1;
 AllocBy := defaultAllocBy; // default alloc
 deAllocBy := defaultAllocBy; // default dealloc
 MaxAllocBy := defaultMaxAllocBy; // max alloc
 AllocItemCount := 0;
 SetSize(size);
end;//TSortedPtrArray.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TSortedPtrArray.Destroy;
begin
 KeyItems := nil;
 ValueItems := nil;
 inherited Destroy;
end;//TSortedPtrArray.Destroy;


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TSortedPtrArray.SetSize(newSize: integer);
begin
 if (newSize = 0) then
  begin
   ItemCount := 0;
   allocItemCount := 0;
   KeyItems := nil;
   ValueItems := nil;
   Exit;
  end;

 if (newSize > allocItemCount) then
  begin
     AllocBy := AllocBy * 2;
     if (AllocBy > MaxAllocBy) then
      AllocBy := MaxAllocBy;
     if (allocItemCount + AllocBy > newSize) then
      allocItemCount := allocItemCount + AllocBy
     else
      allocItemCount := newSize;
     SetLength(KeyItems,allocItemCount);
     SetLength(ValueItems,allocItemCount);
  end
 else
  if (newSize < ItemCount) then
   if (allocItemCount-newSize > deAllocBy) then
    begin
     deAllocBy := deAllocBy * 2;
     if (deAllocBy > MaxAllocBy) then
      deAllocBy := MaxAllocBy;
     SetLength(KeyItems,newSize);
     SetLength(ValueItems,newSize);
     allocItemCount := newSize;
    end;

 ItemCount := newSize;
end;//TSortedPtrArray.SetSize


//------------------------------------------------------------------------------
// Finds position for insert element
//------------------------------------------------------------------------------
function TSortedPtrArray.FindPositionForInsert(key: Integer) : Integer;
var i,dx,f,
    oldRes,res : Integer;
begin
 result := 0;
 if (ItemCount <= 0) then
  Exit;

 i := itemCount shr 1;
 dx := i;
 result := itemCount;
 if (itemCount > 0) then
 begin
  f := 0;
  res := 2;
  while (true) do
   begin
    dx := dx shr 1;
    if (dx < 1) then dx := 1;
     oldRes := res;
     // compare, ascending
     if (KeyItems[i] = key) then
      res := 0
     else
      if (KeyItems[i] < key) then
       res := 1
      else
       res := -1;
    if (res < 0) then
     begin
      //  element, specified by value should be higher then current element (+->0)
      i := i - dx;
     end
    else
    if (res > 0) then
     begin
      //  element, specified by value should be lower then current element (+->0)
      i := i + dx;
     end
    else // values are equal
     begin
      Result := i;
      break;
     end;
    if  (i < 0) and (dx = 1) then
     begin
      Result := 0;
      break;
     end;
    if  (i > itemCount-1) and (dx = 1) then
     begin
      Result := itemCount;
      break;
     end;

    if  (i > itemCount-1) then
     i := itemCount-1;
    if  i < 0 then
     i := 0;

    if (dx = 1) and (f > 1) then
     begin
      // dx minimum
      // compare, ascending
      if (KeyItems[i] = key) then
       res := 0
      else
       if (KeyItems[i] < key) then
        res := 1
       else
        res := -1;

      if (res < 0) and (oldRes > 0) then
       Result := i;
      if (res > 0) and (oldRes < 0) then
       Result := i+1;
      if (res = oldRes) then
       continue;
      break;
     end;// last step
    if (res <> oldRes) and (dx = 1) and (oldRes <> 2) then
     inc(f);
  end;//while dx
 end; // if itemCount > 0
end; //FindPositionForInsert


//------------------------------------------------------------------------------
// Finds position for insert element
// returns -1 if element was not found
//------------------------------------------------------------------------------
function TSortedPtrArray.FindPosition(key: Integer): Integer;
begin
 Result := FindPositionForInsert(key);
 if (Result >= itemCount) or (Result < 0) then
  Result := -1
 else
  if (KeyItems[Result] <> key) then
   Result := -1;
end;// TSortedPtrArray.FindPosition


//------------------------------------------------------------------------------
// Finds value for specified key
// returns nil if element was not found
//------------------------------------------------------------------------------
function TSortedPtrArray.Find(key: Integer): Pointer;
var
  pos: integer;
begin
 pos := FindPositionForInsert(key);
 if (pos >= itemCount) or (pos < 0) then
  Result := nil
 else
  if (KeyItems[pos] <> key) then
   Result := nil
 else
  Result := ValueItems[pos];
end; //Find(value : Integer) : Integer;


//------------------------------------------------------------------------------
// Insert an element into specified position
//------------------------------------------------------------------------------
procedure TSortedPtrArray.InsertByPosition(itemNo: integer; key: integer; value: Pointer);
begin
 inc(ItemCount);
 SetSize(ItemCount);

 if (itemCount <= 1) then
  begin
   KeyItems[0] := key;
   ValueItems[0] := value;
  end
 else
 if (itemNo >= itemCount-1)
  then
   begin
    KeyItems[itemCount-1] := key;
    ValueItems[itemCount-1] := value;
   end
  else
   begin
    Move(KeyItems[itemNo],KeyItems[itemNo+1],
        (itemCount - itemNo-1) * sizeOf(integer));
    Move(ValueItems[itemNo],ValueItems[itemNo+1],
        (itemCount - itemNo-1) * sizeOf(integer));
    KeyItems[itemNo] := key;
    ValueItems[itemNo] := value;
   end;
end;//TSortedPtrArray.InsertByPosition


//------------------------------------------------------------------------------
// Insert an element into specified position
//------------------------------------------------------------------------------
procedure TSortedPtrArray.Insert(key: integer; value: Pointer);
var pos : Integer;
begin
 if (itemCount <= 0) then
  InsertByPosition(0,key,value)
 else
  if (itemCount = 1) then
   begin
    if (KeyItems[0] <= key) then
     InsertByPosition(1,key,value)
    else
     InsertByPosition(0,key,value);
   end
  else
   begin
    pos := FindPositionForInsert(key);
    InsertByPosition(pos,key,value);
   end;
end;


//------------------------------------------------------------------------------
// Delete an element at specified position
//------------------------------------------------------------------------------
procedure TSortedPtrArray.DeleteByPosition(itemNo: integer);
begin
 if (itemNo < itemCount-1) then
  begin
   Move(KeyItems[itemNo+1],KeyItems[itemNo],
       (itemCount - itemNo-1) * sizeOf(integer));
   Move(ValueItems[itemNo+1],ValueItems[itemNo],
       (itemCount - itemNo-1) * sizeOf(Pointer));
  end;
 dec(ItemCount);
 SetSize(ItemCount);
end;//TSortedPtrArray.DeleteByPosition


//------------------------------------------------------------------------------
// Delete an element by specified key
//------------------------------------------------------------------------------
procedure TSortedPtrArray.Delete(key: integer);
var pos : Integer;
begin
 if (itemCount <= 0) then
  raise Exception.Create('TSortedPtrArray.Delete - no elements in array!');
 if (itemCount = 1) then
  DeleteByPosition(0)
 else
  begin
   pos := FindPosition(key);
   if (pos < 0) then
     raise Exception.Create('TSortedPtrArray.Delete - element not found, key = '+
      InttoStr(key)+', itemCount = '+InttoStr(itemCount)+'!');
   DeleteByPosition(pos);
  end;
end;//TSortedPtrArray.Delete


function TSortedPtrArray.GetNextKeyValue: Integer;
begin
 inc(uniqueKeyValue);
 result := uniqueKeyValue;
end; // GetNextKeyValue



////////////////////////////////////////////////////////////////////////////////
//
// TDIRArray
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TDIRArray.Create(size: integer=0;
                defaultAllocBy: Integer = 2;
                defaultMaxAllocBy: Integer = 200);

begin
 AllocBy := defaultAllocBy; // default alloc
 MaxAllocBy := defaultMaxAllocBy; // max alloc
 AllocItemCount := 0;
// memory optimization by Leo
// original:
// NameIndex := TIntegerArray.Create;
// ParentIndex := TIntegerArray.Create;
// optimized:
 NameIndex := TIntegerArray.Create(0,10,100);
 ParentIndex := TIntegerArray.Create(0,10,100);

 FoundItemCount := 0;
 ItemCount := 0;
 SetSize(0);
end;//TDIRArray.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TDIRArray.Destroy;
begin
 SetSize(0);
 FoundItems := nil;
 Items := nil;
 NameIndex.Free;
 ParentIndex.Free;
 inherited Destroy;
end;//TDIRArray.Destroy;


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TDIRArray.SetSize(newSize: integer);
var i: integer;
begin
 if (newSize = 0) then
  begin
   for i := 0 to FoundItemCount-1 do
    if (FoundItems[i] <> nil) then
     begin
      FoundItems[i].Free;
      FoundItems[i] := nil;
     end;
   ItemCount := 0;
   FoundItemCount := 0;
   IndexElementsCount := 0;
   allocItemCount := 0;
   Items := nil;
   FoundItems := nil;
   NameIndex.SetSize(0);
   ParentIndex.SetSize(0);
   Exit;
  end;

 if (newSize > allocItemCount) then
  begin
     AllocBy := AllocBy * 2;
     if (AllocBy > MaxAllocBy) then
      AllocBy := MaxAllocBy;
     if (allocItemCount + AllocBy > newSize) then
      allocItemCount := allocItemCount + AllocBy
     else
      allocItemCount := newSize;
     SetLength(Items,allocItemCount);
  end
 else
  if (newSize < ItemCount) then
   raise Exception.Create('TDIRArray.SetSize - newSize < itemCount error. '+
        ' newSize = '+inttostr(newsize)+
        ' itemCount = '+inttostr(ItemCount));
 ItemCount := newSize;
end;//TDIRArray.SetSize


procedure TDIRArray.BuildIndexes;
var bByName:  Boolean;
    k:        Integer;
// compare
 function Compare(i,j: Integer): Integer;
 begin
  //---------------------------- start of compare -----------------------------------
     if (bByName) then
      begin
       // by Name
        {$IFDEF X64_ON}
        result := -AnsiStrIComp(
          pAnsiChar(@Items[NameIndex.Items[i]].filename),
          pAnsiChar(@Items[NameIndex.Items[j]].filename)
          );
        {$ELSE}
        result := -Q_AnsiPCompText(
          pAnsiChar(@Items[NameIndex.Items[i]].filename),
          pAnsiChar(@Items[NameIndex.Items[j]].filename)
          );
        {$ENDIF}
      end
     else
      begin
       // by parent
       if (Items[ParentIndex.Items[i]].parentID =
           Items[ParentIndex.Items[j]].parentID) then
        Result := 0
       else
        if (Items[ParentIndex.Items[i]].parentID <
            Items[ParentIndex.Items[j]].parentID) then
         Result := 1
        else
         Result := -1;
      end; // compare by parentID
  //---------------------------- end of compare -----------------------------------
 end;

 procedure QuickSort(iLo, iHi: Integer);
 var
    Lo, Hi, Mid, T: Integer;
  begin
   Lo := iLo;
   Hi := iHi;
   Mid := (Lo + Hi) div 2;
   repeat
     while (Compare(Lo,Mid) > 0) do
        Inc(Lo);
     while (Compare(Hi,Mid) < 0)  do
        Dec(Hi);
     if Lo <= Hi then
      begin
       if (bByName) then
        begin
         T := NameIndex.Items[Lo];
         NameIndex.Items[Lo] := NameIndex.Items[Hi];
         NameIndex.Items[Hi] := T;
        end
       else
        begin
         T := ParentIndex.Items[Lo];
         ParentIndex.Items[Lo] := ParentIndex.Items[Hi];
         ParentIndex.Items[Hi] := T;
        end;
       Inc(Lo);
       Dec(Hi);
     end;
   until Lo > Hi;
   if Hi > iLo then
    QuickSort(iLo, Hi);
   if Lo < iHi then
    QuickSort(Lo, iHi);
  end;

//BuildIndexes
begin

 NameIndex.SetSize(0);
 ParentIndex.SetSize(0);
 for k := 0 to ItemCount-1 do
  if (Items[k].IsDeleted = 0) then
    begin
     NameIndex.Append(k);
     ParentIndex.Append(k);
    end;
 if (NameIndex.ItemCount <= 0) then
  Exit;
 k := NameIndex.ItemCount-1;
 bByName := true;


 QuickSort(0,k);
{
 // simple sort - commented in 2.30
 for i := 0 to k do
  for j := i to k do
   if (Compare(i,j) < 0) then
    begin
         T := NameIndex.Items[i];
         NameIndex.Items[i] := NameIndex.Items[j];
         NameIndex.Items[j] := T;
    end;
}    
 bByName := false;
 QuickSort(0,k);
end; // BuildIndexes


//------------------------------------------------------------------------------
// Finds position for insert element in specified index
// bFirst means that it will first of all equal items
// returns 0 or indexElementsCount if there is no equal values if
// bInsert specified;
// if bInsert = false returns -1 if there is no equal values
//------------------------------------------------------------------------------
function TDIRArray.FindPositionForInsert(value: TDirectoryElement;
                   bByName: Boolean = true;
                   bFirst:  Boolean = false;
                   bInsert: Boolean = true
                   ) : Integer;
var i,dx,f,
    oldRes,res : Integer;
    str: AnsiString;
    parentId: integer;
// compare
 function Compare: Integer;
 begin
  //---------------------------- start of compare -----------------------------------
     if (bByName) then
      begin
       // by Name
{$IFDEF X64_ON}
result := -AnsiStrIComp(
{$ELSE}
result := -Q_AnsiPCompText(
{$ENDIF}
pAnsiChar(@Items[NameIndex.Items[i]].filename),
                        pAnsiChar(str));
if (result > 0) then
 result := 1
else
if (result < 0) then
 result := -1
      end
     else
      begin
       // by parent
       if (Items[ParentIndex.Items[i]].parentID = parentID) then
        Result := 0
       else
        if (Items[ParentIndex.Items[i]].parentID < parentID) then
         Result := 1
        else
         Result := -1;
      end; // compare by parentID
  //---------------------------- end of compare -----------------------------------
 end;

begin

// str := AnsiStrLower(pAnsiChar(@value.FileName));
 str := value.FileName;
 parentId := value.parentID;
 i := IndexElementsCount shr 1;
 dx := i;
 result := 0;
 if (IndexElementsCount <= 0) then
  begin
   if (bInsert) then
    result := 0
   else
    result := -1;
   Exit;
  end;
//aaStartTime;
  f := 0;
res := 20000000;
  while (true) do
   begin
    dx := dx shr 1;
    if (dx < 1) then dx := 1;
    oldRes := res;
     // compare, ascending
    res := Compare;
    if (res < 0) then
     begin
      //  element, specified by value should be higher then current element (+->0)
      i := i - dx;
     end
    else
    if (res > 0) then
     begin
      //  element, specified by value should be lower then current element (+->0)
      i := i + dx;
     end
    else
     begin
      // values are equal
      Result := i;
      break;
     end;
    if  (i < 0) and (dx = 1) then
     begin
      // equal not found
      result := 0;
      break;
     end;
    if  (i > IndexElementsCount-1) and (dx = 1) then
     begin
      // equal not found
      result := IndexElementsCount;
      break;
     end;

    if  (i > IndexElementsCount-1) then
     i := IndexElementsCount-1;
    if  i < 0 then
     i := 0;

    if (dx = 1) and (f > 1) then
     begin
      // dx minimum
      // compare, ascending
      res := Compare;
      if (res < 0) and (oldRes > 0) then
       Result := i;
      if (res > 0) and (oldRes < 0) then
       Result := i+1;
      if (res = oldRes) then
       continue;
      break;
     end;// last step
//    if (sign(res) <> sign(oldRes)) and (dx = 1) and (oldRes <> 20000000) then
    if (res <> oldRes) and (dx = 1) and (oldRes <> 20000000) then
     inc(f);
  end;//while dx

 if (result >= IndexElementsCount) and (not bInsert) then
     Result := -1;
 if (result < 0) then
  begin
   if (bInsert) then
    Result := 0
   else
    Result := -1;
  end;
 if (not bInsert) and (result >= 0) then
  begin
   i := result;
   // compare, ascending
   res := Compare;
   if (res <> 0) then
    result := -1;
  end;

 if (bFirst and (not bInsert) and (result > 0) and (res = 0)) then
  begin
   // searching first equal value
   repeat
    dec(result);
    i := result;
    res := Compare;
    if (res <> 0) then
     begin
      inc(result);
      break;
     end;
   until (result <= 0);
  end;
//aaStopTime;
end; //FindPositionForInsert


//------------------------------------------------------------------------------
// Find file by name (with path)
// returns -1 if root directory found
// returns <-1 if file not found
// >= 0 - directory element number if fili found
//------------------------------------------------------------------------------
function TDIRArray.FindFileByName(FileName: PAnsiChar; startDir: Integer = rootID): Integer;
var sLen: Integer;
// recursive function for path finding
 function FindFile(currentDir: Integer; startSymbol: integer = 0): Integer;
 var i,curDir,l:Integer;
     el:        TDirectoryElement;
     bOk:       Boolean;
     pos:       Integer;
 begin
  if (startSymbol >= sLen) then
   begin
    Result := currentDir;
    Exit;
   end;
  i := startSymbol;
  while (startSymbol < sLen) and
        (pAnsiChar(fileName+startSymbol)^ <> '/') and
        (pAnsiChar(fileName+startSymbol)^ <> '\') do
   inc(startSymbol);
  if (i = startSymbol) and (startSymbol <> 0) then
   begin
    // this means something like 'folder1\\folder2' - invalid path
    result := erInvalidPath;
    Exit;
   end
  else
   if (i = startSymbol) then
    begin
     curDir := -1;
    end
   else
    begin
     // some file or folder found
     // checing '..'
     if (startSymbol - i = 2) and (pAnsiChar(filename+i)^ = '.')
        and
        (pAnsiChar(filename+i+1)^ = '.') then
      begin
       // 'cd ..'
       if (currentDir >= ItemCount) then
        begin
         // invalid current dir
         result := erInvalidCurrentDir;
         Exit;
        end
       else
       if (currentDir < 0) then
        curDir := 0
       else
        curDir := Items[currentDir].ParentID;
      end
     else
      begin
       // find file by name
       l := startSymbol - i;
       if (l >= 260) then
        l := 259;
       Move(pAnsiChar(fileName+i)^,pAnsiChar(@el.FileName)^,l);
       el.FileName[l] := #0;
       el.ParentID := CurrentDir;
//aaStartTime;
       pos := FindPositionForInsert(el,true,true,false);
//aaStopTime;
       if (pos < 0) then
        begin
         // invalid path
         result := erInvalidPath;
         Exit;
        end;
       // find by parent id
       bOk := false;
       while (pos < IndexElementsCount) do
        begin
         if (Items[NameIndex.Items[pos]].ParentID = CurrentDir) then
{$IFDEF X64_ON}
          if (AnsiStrIComp(Items[NameIndex.Items[pos]].FileName, el.FileName) = 0) then
{$ELSE}
          if (Q_AnsiPCompText(Items[NameIndex.Items[pos]].FileName, el.FileName) = 0) then
{$ENDIF}
           begin
            bOk := true;
            break;
           end
          else
           break;
         inc(pos);
        end;
       if (not bOk) then
        begin
         // invalid current dir
         result := erInvalidCurrentDir;
         Exit;
        end;
       CurDir := NameIndex.Items[pos];
      end; // find file by name and currentDir
    end;
  inc(startSymbol);
  Result := FindFile(curDir,startSymbol);
 end;// FindFile
// FindFileByName
begin
 result := erInvalidPath;
 if (FileName = nil) then
  Exit
 else
  if (FileName^ = #0) then
   Exit;
 if (FileName = '') or (startDir < -1) or (startDir >= ItemCount) then
  Exit;
 if (FileName = '\') or (FileName = '/') then
  begin
   // root directory found - for SetCurrentDirectory it is correct value
   result := rootID;
   Exit;
  end;
 sLen := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}fileName);
 result := FindFile(startDir);
end; //FindFileByName


//------------------------------------------------------------------------------
// returns full file path (form root, '\folder1\folder2')
//------------------------------------------------------------------------------
function TDIRArray.GetFullFilePath(ItemNo: Integer): AnsiString;
var i: Integer;
    str: PAnsiChar;
begin
 result := '\';
 if (ItemNo < 0) or (ItemNo >= ItemCount) then
  Exit;
 result := '';
 i := ItemNo;
 str := AllocMem(MAX_PATH);
 repeat
   Move(Items[i].FileName,str^,MAX_PATH);
   result := '\'+str+result;
   if (i <> Items[i].ParentID) then
     i := Items[i].ParentID
   else
     i := rootID;
 until (i <= rootID) or (i >= ItemCount);
 FreeMem(str);
end;


//------------------------------------------------------------------------------
// prepares searchRec
//------------------------------------------------------------------------------
procedure TDIRArray.PrepareSearchRecord(ItemNo: Integer; var F: TSearchRec);
var
 LocalFileTime: TFileTime;
begin
 // prepare find structure ...
 F.Attr := Items[itemNo].Attributes;
 FileTimeToLocalFileTime(Items[itemNo].LastModifiedTime, LocalFileTime);
 FileTimeToDosDateTime(LocalFileTime, LongRec(F.Time).Hi,
      LongRec(F.Time).Lo);
 F.Size := Items[itemNo].FileSize;
 F.Name := Items[itemNo].FileName;
 // finddata
 F.FindData.dwFileAttributes := F.Attr;
 F.FindData.ftCreationTime := Items[itemNo].CreationTime;
 F.FindData.ftLastAccessTime := Items[itemNo].LastAccessTime;
 F.FindData.ftLastWriteTime := Items[itemNo].LastModifiedTime;
 Move(Items[itemNo].FileSize,F.FindData.nFileSizeLow,4);
 Move(pInteger(PAnsiChar(@Items[itemNo].FileSize)+4)^,F.FindData.nFileSizeHigh,4);
// F.FindData.nFileSizeHigh := 0;
// F.FindData.nFileSizeLow := Items[itemNo].FileSize ;
 Move(Items[itemNo].FileName,F.FindData.cFileName,MAX_PATH);
// Move(Items[itemNo].ShortFileName,F.FindData.cAlternateFileName,14);
end; // PrepareSearchRecord


//------------------------------------------------------------------------------
// find file by pattern using '*', '?'
// returns 0 if file was found, otherwise returns error code
// prepares searchRec structure
//------------------------------------------------------------------------------
function TDIRArray.FindFirst(const Path: AnsiString; Attr: Integer; var F: TSearchRec;
         currentDir: Integer = rootID): Integer;
const
  faSpecial = faHidden or faSysFile or faVolumeID or faDirectory;
var i,id,itemID,curDir: Integer;
    Pattern, FilePath:  PAnsiChar;
    el:                 TDirectoryElement;
    bOk:                Boolean;
begin
 result := erOK;
 // extracting path and pattern
 FilePath := nil;
 Pattern := nil;
 F.FindHandle := Cardinal(-1);
 // prepare find structure ..
 id := -1;
 for i := 0 to FoundItemCount-1 do
  if (FoundItems[i] = nil) then
   begin
    id := i;
    break;
   end;
 if (id < 0) then
 begin
  id := FoundItemCount;
  inc(FoundItemCount);
  SetLength(FoundItems,FoundItemCount);
 end;
 // bugs were here

// memory optimization by Leo
// original:
// FoundItems[id] := TIntegerArray.Create;
// optimzied:
 FoundItems[id] := TIntegerArray.Create(0,10,10);

 FoundItems[id].CurrentItem := 0;
 F.FindHandle := Cardinal(id);
 F.ExcludeAttr := not Attr and faSpecial;
 // searching file...
//aaStartTime;
 if (not ExtractPathAndPattern(PAnsiChar(Path),FilePath,Pattern)) then
  begin
   i := Length(Path);
   Pattern := AllocMem(i+1);
   Move(pAnsiChar(Path)^,Pattern^,i);
   if (currentDir = rootID) then
    begin
     FilePath := AllocMem(2);
     FilePath^ := '\';
    end
   else
    begin
     FilePath := AllocMem(MAX_PATH+1);
     Move(Items[currentDir].FileName,FilePath^,MAX_PATH);
    end;

   i := 0;
  end
 else
  i := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}FilePath);
//   Result := erInvalidPath;
//   Exit;
 if (i = 0) then
  begin
   if (Path[1] = '/') or (Path[1] = '\') then
    curDir := rootID
   else
    curDir := currentDir;
  end
 else
  curDir := FindFileByName(FilePath,currentDir);
//aaStopTime;
{
 else
 if (pAnsiChar(FilePath)^ = '/') or (pAnsiChar(FilePath)^ = '\') then
  begin
   Move(pAnsiChar(FilePath+1)^,pAnsiChar(FilePath)^,i);
   curDir := FindFileByName(FilePath,rootID);
  end
}
 if (curDir <= erInvalidPath) then
  Result := erInvalidPath
 else
  begin
   el.ParentID := curDir;
//aaStartTime;
   i := FindPositionForInsert(el,false,true,false);
//aaStopTime;
   if (i < 0) then
    Result := erFileNotFound
   else
    begin
     // some files may be found
     repeat
      // get element
      itemID := ParentIndex.Items[i];
      if (Items[itemID].ParentID <> curDir) then
       break;
      // check element
      if (Items[itemID].Attributes and F.ExcludeAttr <> 0) then
       bOk := false
      else
       bOk := IsStrMatchPattern(Items[itemId].FileName,Pattern,true);
      if (bOk) then
        FoundItems[id].Append(itemID);
      inc(i);
     until (i >= IndexElementsCount);
     if (FoundItems[id].ItemCount > 0) then
      PrepareSearchRecord(FoundItems[id].Items[0],F)
     else
      Result := erFileNotFound;
    end;
  end; // path Ok
 FreeMem(Pattern);
 FreeMem(FilePath);
end; // FindFirst


//------------------------------------------------------------------------------
// finds next file
//------------------------------------------------------------------------------
function TDIRArray.FindNext(var F: TSearchRec): Integer;
begin
 Result := erOk;
 if (F.FindHandle >= Cardinal(FoundItemCount)) then
  begin
   Result := erFileNotFound;
   Exit;
  end;
 if (FoundItems[F.FindHandle] = nil) then
  Result := erInvalidSearchRec
 else
  if (FoundItems[F.FindHandle].CurrentItem >= FoundItems[F.FindHandle].ItemCount-1) then
   Result := erFileNotFound
  else
   begin
    inc(FoundItems[F.FindHandle].CurrentItem);
    PrepareSearchRecord(FoundItems[F.FindHandle].Items[
        FoundItems[F.FindHandle].CurrentItem],F);
   end;
end; // FindNext


//------------------------------------------------------------------------------
// finalisez findFirst/findNext sequence
//------------------------------------------------------------------------------
procedure TDIRArray.FindClose(var F: TSearchRec);
begin
 if (F.FindHandle < Cardinal(FoundItemCount)) then
  if (FoundItems[F.FindHandle] <> nil) then
   begin
    FoundItems[F.FindHandle].Free;
    FoundItems[F.FindHandle] := nil;
   end;
end; // findClose


//------------------------------------------------------------------------------
// Insert an element into specified position
//------------------------------------------------------------------------------
procedure TDIRArray.AppendItem(value: TDirectoryElement);
var i: integer;
begin
 inc(ItemCount);
 SetSize(ItemCount);
 Items[ItemCount-1] := value;
 // deleted files will not be added to indexes
 if (value.isDeleted = 0) then
  begin
   // update filename index
   i := FindPositionForInsert(value,true,false,true);
   NameIndex.Insert(i,ItemCount-1);
   // update filename index
   i := FindPositionForInsert(value,false,false,true);
   ParentIndex.Insert(i,ItemCount-1);
   inc(IndexElementsCount);
  end;
 // here will be writing new element to disk
end;


//------------------------------------------------------------------------------
// Update an element into specified position
//------------------------------------------------------------------------------
procedure TDIRArray.UpdateItem(value: TDirectoryElement; position: Integer);
var oldNamePos,oldParentPos: integer;
    newNamePos,newParentPos:   integer;
    oldValue:                  TDirectoryElement;
    bOk:                       Boolean;
begin
 if (position < 0) or (position >= ItemCount) then
  raise Exception.Create('TDIRArray.UpdateItem - invalid itemNo = '+IntToStr(position));
 oldValue := Items[position];
 Items[position] := value;
 // both new and old element are deleted
 if (value.Isdeleted <> 0) and (oldValue.isDeleted <> 0) then
  Exit;
 oldNamePos := -1;
 newNamePos := -1;
 oldParentPos := -1;
 newParentPos := -1;
 if (oldValue.isDeleted = 0) then
  begin
   // find old position in name index
   oldNamePos := FindPositionForInsert(oldValue,true,true,false);
   bOk := false;
   while (oldNamePos < IndexElementsCount) do
    begin
     if (NameIndex.Items[oldNamePos] = position) then
      begin
       bOk := true;
       break;
      end;
     inc(oldNamePos);
    end;
   if (not bOk) then
    raise Exception.Create('TDIRArray.UpdateItem - old name position not found. '+
      'Position = '+inttostr(position)+
      ', ItemCount = '+inttostr(ItemCount)+
      ', FileName = '+AnsiQuotedStr(pAnsiChar(@oldValue.FileName),'"'));
   // find old position in name index
   oldParentPos := FindPositionForInsert(oldValue,false,true,false);
   bOk := false;
   while (oldParentPos < IndexElementsCount) do
    begin
     if (ParentIndex.Items[oldParentPos] = position) then
      begin
       bOk := true;
       break;
      end;
     inc(oldParentPos);
    end;
   if (not bOk) then
    raise Exception.Create('TDIRArray.UpdateItem - old parentID position not found. '+
      'Position = '+inttostr(position)+
      ', ItemCount = '+inttostr(ItemCount)+
      ', ParentID = '+inttostr(oldValue.ParentID));
  end;

 // deleted files will not be added to indexes
 if (value.isDeleted = 0) then
  begin
   // find new value position in name index
   newNamePos := FindPositionForInsert(value,true,false,true);
   // find new value position parentID index
   newParentPos := FindPositionForInsert(value,false,false,true);
  end;
 if (oldValue.IsDeleted <> 0) then
  begin
   // new element is not deleted, old element is deleted
   // inserting into indexes
   NameIndex.Insert(newNamePos,position);
   ParentIndex.Insert(newParentPos,position);
   inc(IndexElementsCount);
  end
 else
  if (value.IsDeleted <> 0) then
   begin
    // old element is not deleted, new element is deleted
    // deleteing from indexes
    NameIndex.Delete(oldNamePos);
    ParentIndex.Delete(oldParentPos);
    dec(IndexElementsCount);
   end
  else
   begin
    // both new and old element are not deleted
    // updating indexes
    if (newNamePos <> oldNamePos) and
       (newNamePos <> (oldNamePos+1)) then
     NameIndex.MoveTo(oldNamePos,newNamePos);
    if (newParentPos <> oldParentPos) and
       (newParentPos <> (oldParentPos+1)) then
     ParentIndex.MoveTo(oldParentPos,newParentPos);
   end;
 // here will be writing new element to disk
end; // UpdateItem


//------------------------------------------------------------------------------
// Read directory element from specified position
//------------------------------------------------------------------------------
function TDIRArray.ReadItem(position: integer): TDirectoryElement;
begin
 // in multi-user version
 // here will be read from disk of specified element
 if (position < 0) or (position >= ItemCount) then
  raise Exception.Create('TDIRArray.ReadItem - invalid itemNo = '+IntToStr(position));
 result := Items[position];
end;



////////////////////////////////////////////////////////////////////////////////
//
//   TPageFileManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TPageFileManager.Create(const FileName: AnsiString; Mode: Word;
               Password: AnsiString = '';
               Question: AnsiString = '';
               Answer: AnsiString = '';
               IsInMemory: boolean = false;
               PageSize: Integer = DEFAULT_PAGE_SIZE;
               ExtentPageCount: Integer = DEFAULT_EXTENT_PAGE_COUNT;
               PartFileSize: Int64 = -1
               );
var DatabaseName:       AnsiString; //path to Single file
begin
 if (PageSize < MIN_PAGE_SIZE) then
   raise Exception.Create('TPageFileManager.Create - page size should be >= '+
    IntToStr(MIN_PAGE_SIZE)+'bytes .');
 if (ExtentPageCount <= 0) then
   raise Exception.Create('TPageFileManager.Create - extent page count should be >= 1 Page.');
 FFileName := FileName;
 FInMemory := IsInMemory;
 DatabaseName := ExtractFilePath(FileName);
 FReadOnly := false;
 FPassword := Password;
 if (Mode and 3 = fmOpenRead) then
  FReadOnly := true;
 FExclusive := false;
 if (Mode and fmShareExclusive = fmShareExclusive) then
  FExclusive := true;

 if (Mode = fmCreate) then
  begin
   // fixed in 2.80
   FReadOnly := False;
   FExclusive := True;
   // create Single file
   ESFSFile := TESFSHugeFile.Create(FileName, FReadOnly, FExclusive, FInMemory,
                                  PartFileSize);
   ESFSFile.Open(true);
   FillChar(FHeader,sizeof(FHeader),$00);
   FHeader.Signature := ESingleFileSystemSignature;
   FHeader.Version := ESFSCurrentVersion;
   FHeader.PageSize := PageSize; // since v.2.10 - to allow 600 bytes pages
//   FHeader.PageSize := PageSize * 1024;
   FHeader.ExtentPageCount := ExtentPageCount;
//   FHeader.PageSize := 600;
//   FHeader.ExtentPageCount := 2;
   
   FHeader.HDRPageCount := 1;
   FHeader.TOTALPageCount := 1;
   FHeader.EncMethod := EncNone;
   if (Password <> '') then
    begin
     FHeader.EncMethod := EncRijndael;
     CreatePasswordHeader(FHeader.PasswordHeader,Password,Question,Answer);
    end;
   SaveSFHeader;
  end
 else
  begin
   if (not SysUtils.FileExists(FileName)) then
    raise Exception.Create('File '''+FileName+''' not found');
   ESFSFile := TESFSHugeFile.Create(FileName, FReadOnly, FExclusive, FInMemory);
   // open file and ignore corruption errors
   if (not ESFSFile.Open(false, true)) then
    begin
      ESFSFile.Free;
      ESFSFile := nil;
      raise Exception.Create('File '+ExtractFileName(FileName)+' has corrupted header.');
    end;
   LoadSFHeader;
  end;
 // decode default key for user files
 if (FHeader.EncMethod <> encNone) then
   CheckPassword(FHeader.PasswordHeader,Password,FKey)
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TPageFileManager.Destroy;
begin
 if (ESFSFile <> nil) then
  ESFSFile.Free;
 ESFSFile := nil;
 inherited Destroy;
end; // Destroy;


//------------------------------------------------------------------------------
// calc offset by page no
//------------------------------------------------------------------------------
function TPageFileManager.PageNoToOffset(PageNo: integer): Int64;
begin
 result := Int64(PageNo)*Int64(FHeader.PageSize);
end;// PageNoToOffset


//------------------------------------------------------------------------------
// encode buffer
//------------------------------------------------------------------------------
function TPageFileManager.EncodeBuffer(buffer: PAnsiChar; Size: LongInt;
                         EncType: byte; Password: AnsiString): boolean;
var
  cr: TCipher_Rijndael;
  bUnknownEncType: boolean;
begin
  bUnknownEncType := false;
  result := true;
  try
    case EncType of
      0: ;// no encoding
      1: begin
          // Rijndael
           cr := TCipher_Rijndael.Create(Password, nil);
           cr.EncodeBuffer(buffer^, buffer^, Size);
           cr.Free;
         end;
    else
      bUnknownEncType := true;
    end;
  except
    result := false;
  end;
  // unknown type?
  if (bUnknownEncType) then
   raise Exception.Create('TPageFileManager.EncodeBuffer - Unknown encryption type');
end;// EncodeBuffer


//------------------------------------------------------------------------------
// decode buffer
//------------------------------------------------------------------------------
function TPageFileManager.DecodeBuffer(buffer: PAnsiChar; Size: LongInt;
                         EncType: byte; Password: AnsiString): boolean;
var
  cr: TCipher_Rijndael;
  bUnknownEncType: boolean;
begin
  bUnknownEncType := false;
  result := true;
  try
    case EncType of
      0: ;// no encoding
      1: begin
          // Rijndael
           cr := TCipher_Rijndael.Create(Password, nil);
           cr.DecodeBuffer(buffer^, buffer^, Size);
           cr.Free;
         end;
    else
      bUnknownEncType := true;
    end;
  except
    result := false;
  end;
  // unknown type?
  if (bUnknownEncType) then
   result := false;
//   raise Exception.Create('TPageFileManager.DecodeBuffer - Unknown encryption type');
end;// DecodeBuffer


//------------------------------------------------------------------------------
// attempt to load Single file header from specified offset
//------------------------------------------------------------------------------
function TPageFileManager.InternalLoadHeader(FileOffset: Int64): boolean;
var
  bOK: boolean;
  CRC: Cardinal;
  size: Integer;
begin
  bOK := true;
//  ESFSFile.Seek(FileOffset,soFromBeginning);
  ESFSFile.Position := FileOffset;
  ESFSFile.ReadBuffer(FHeader,SingleFileHeaderSize);
  // check signature
  if (FHeader.Signature <> ESingleFileSystemSignature) then
    bOK := false
  else
   begin
    // check crc
    size := SingleFileHeaderSize-sizeof(FHeader.Signature)-sizeof(Cardinal);
    CRC := CountCRC(@FHeader.Version, size, 0);
    if (FHeader.CRC <> CRC) then
      bOK := false;
   end;
  result := bOK;
end;// InternalLoadHeader


//------------------------------------------------------------------------------
// returns page data size without header
//------------------------------------------------------------------------------
function TPageFileManager.GetPageDataSize: LongInt;
begin
 result := FHeader.PageSize - PageHeaderSize;
end; //GetPageDataSize;


//------------------------------------------------------------------------------
// set in-memory or disk mode
//------------------------------------------------------------------------------
procedure TPageFileManager.SetInMemory(Value: boolean);
begin
 ESFSFile.InMemory := Value;
end;// SetInMemory


//------------------------------------------------------------------------------
// load Single file header
//------------------------------------------------------------------------------
procedure TPageFileManager.LoadSFHeader;
begin
 // try to open header (it is always placed at the beginning of Single file)
 if (not InternalLoadHeader(0)) then
  raise Exception.Create('TESingleFileSystem.LoadHeader - Invalid ESFS file, header is corrupted.');
end; //LoadSFHeader


//------------------------------------------------------------------------------
// save Single file header
//------------------------------------------------------------------------------
procedure TPageFileManager.SaveSFHeader;
var
  size : Integer;
begin
 if (FReadOnly) then
  Exit;
 // count header crc
 size := SingleFileHeaderSize-sizeof(FHeader.Signature)-sizeof(Cardinal);
 FHeader.CRC := CountCRC(@FHeader.Version, size, 0);
 // seek to beginnig of header
 ESFSFile.Seek(0,soFromBeginning);
 // write primary Single file header
 ESFSFile.WriteBuffer(FHeader,SingleFileHeaderSize);
// ESFSFile.FlushBuffers;
end; //SaveSFHeader


//------------------------------------------------------------------------------
// allocate and init page
//------------------------------------------------------------------------------
procedure TPageFileManager.AllocPageBuffer(var FFPage: TFFPage);
begin
  FFPage.PageHeader.NextPageNo := -1; // no next page
  FFPage.PageHeader.EncType := 0; // no encryption
  FFPage.PageHeader.CrcType := 0; // fast CRC
  FFPage.pData := AllocMem(PageDataSize);
end;// AllocPageBuffer


//------------------------------------------------------------------------------
// free page
//------------------------------------------------------------------------------
procedure TPageFileManager.FreePageBuffer(FFPage: TFFPage);
begin
  FreeMem(FFPage.pData);
end;// FreePageBuffer


//------------------------------------------------------------------------------
// read page
//------------------------------------------------------------------------------
function TPageFileManager.ReadPage(var buffer: TFFPage; PageNo: Integer;
              Size: Integer = -1;
              Password: string='';
              bIgnoreEncrypted: Boolean = false
              ): boolean;
var
  Offset: Int64;
  Res:    Integer;
  Key:		AnsiString;
begin
{$IFDEF DEBUG_TRACE_TPageFileManager_READPAGE}
try
{$ENDIF}
	FLastError := erOk;
  if (Password <> '') then
   Key := Password
  else
   Key := FKey;
  if (size < 0) then
   size := PageDataSize;
  // calc offset
  Offset := PageNoToOffset(PageNo);
  // seek
//  ESFSFile.Seek(Offset, soFromBeginning);
  ESFSFile.Position := Offset;
  // read page header
  Res := ESFSFile.Read(buffer.PageHeader, PageHeaderSize);
{$IFDEF DEBUG_TRACE_TPageFileManager_READPAGE}
aaWriteToLog('0 TPageFileManager.ReadPage. PageNo = '+IntToStr(pageNo)+#9+'Size = '+IntToStr(Size)+#9+'Res = '+IntToStr(Res)+#9+'PageHeaderSize = '+IntToStr(PageHeaderSize)+#9+'Offset = '+IntToStr(Offset));
{$ENDIF}
  Result := (Res = PageHeaderSize);
  if (not result) then
   begin
    FLastError := erReadPageHeaderError;
    Exit;
   end;
  // read header only
  if (size = 0) then
   Exit;
  // if OK
  if (buffer.pData = nil) then
   raise Exception.Create('TPageFileManager.ReadPage - pData is nil.');
  Res := ESFSFile.Read(buffer.pData^, Size);
  Result := (Res = Size);
{$IFDEF DEBUG_TRACE_TPageFileManager_READPAGE}
aaWriteToLog('1 TPageFileManager.ReadPage. PageNo = '+IntToStr(pageNo)+#9+'Size = '+IntToStr(Size)+#9+'Res = '+IntToStr(Res));
{$ENDIF}
  if (not result) then
   begin
    FLastError := erReadPageError;
    Exit;
   end;
  // check CRC
  result := CheckCRC(buffer.pData, Size,
                   buffer.PageHeader.CrcType, buffer.PageHeader.CRC);
{$IFDEF SKIP_CRC_CHECK}
 result := true;
 exit;
{$ELSE}
  if (not result) then
   begin
    FLastError := erCRCError;
    Exit;
   end;
{$ENDIF}
  // decrypt if necessary
  if (not bIgnoreEncrypted) then
   result := DecodeBuffer(buffer.pData, Size,
                              buffer.PageHeader.EncType, Key);
  if (not result) then
    FLastError := erDecodeError;
{$IFDEF DEBUG_TRACE_TPageFileManager_READPAGE}
finally
 aaWriteToLog('2 TPageFileManager.ReadPage. PageNo = '+IntToStr(pageNo)+#9+'Size = '+IntToStr(Size)+#9+'Result = '+BoolToStr(Result,True)+#9+'LastError = '+IntToStr(FLastError));
 if (not Result) then
  begin
   try
    aaWriteBufferToLog(PAnsiChar(@buffer.PageHeader),Integer(PageHeaderSize));
    aaWriteBufferToLog(buffer.pData,Size);
   except
   end;
  end;
end;
{$ENDIF}
end;// ReadPage


//------------------------------------------------------------------------------
// write page
// if buffer.pData = nil - only page header is written
//------------------------------------------------------------------------------
function TPageFileManager.WritePage(var buffer: TFFPage; PageNo: Integer;
              Size: Integer = -1;
              Password: string=''): boolean;
var
  Offset: Int64;
  Res:    Integer;
  Key:		AnsiString;
begin
{$IFDEF DEBUG_TRACE_TPageFileManager_WRITEPAGE}
try
{$ENDIF}
	FLastError := erOk;
  if (Password <> '') then
   Key := Password
  else
   Key := FKey;
  if (size < 0) then
   size := PageDataSize;
  // page data presents?
  if (buffer.pData <> nil) and (size > 0) then
   begin
     // encrypt
     result := EncodeBuffer(buffer.pData, Size,
                   buffer.PageHeader.EncType, Key);
	  if (not result) then
	   begin
	    FLastError := erEncodeError;
	    Exit;
     end;
     // calc CRC
     buffer.PageHeader.CRC := CountCRC(buffer.pData, Size, buffer.PageHeader.CrcType);
   end;
  // calc offset
  Offset := PageNoToOffset(PageNo);
//if (debugFlag) then
// aaStartTime;
  // seek
//  ESFSFile.Seek(Offset, soFromBeginning);
  ESFSFile.Position := Offset;
  // write page header
  Res := ESFSFile.Write(buffer.PageHeader, PageHeaderSize);
{$IFDEF DEBUG_TRACE_TPageFileManager_WRITEPAGE}
aaWriteToLog('0 TPageFileManager.WritePage. PageNo = '+IntToStr(pageNo)+#9+'Size = '+IntToStr(Size)+#9+'Res = '+IntToStr(Res)+#9+'PageHeaderSize = '+IntToStr(PageHeaderSize)+#9+'Offset = '+IntToStr(Offset));
{$ENDIF}
  result := (Res = PageHeaderSize);
//if (debugFlag) then
// aaStopTime;


  if (not result) then
   begin
    FLastError := erWritePageHeaderError;
	  Exit;
   end;
  // if buffer.pData <> nil - write page data

//if (debugFlag) then
// aaStartTime;
  if (buffer.pData <> nil) and (size > 0) then
   begin
    Res := ESFSFile.Write(buffer.pData^, Size);
{$IFDEF DEBUG_TRACE_TPageFileManager_WRITEPAGE}
aaWriteToLog('1 TPageFileManager.WritePage. PageNo = '+IntToStr(pageNo)+#9+'Size = '+IntToStr(Size)+#9+'Res = '+IntToStr(Res));
{$ENDIF}
    result := (Res = Size);
   end;
//if (debugFlag) then
// aaStopTime;


  if (not result) then
    FLastError := erWritePageError;
{$IFDEF DEBUG_TRACE_TPageFileManager_WRITEPAGE}
finally
 aaWriteToLog('2 TPageFileManager.WritePage. PageNo = '+IntToStr(pageNo)+#9+'Size = '+IntToStr(Size)+#9+'Result = '+BoolToStr(Result,True)+#9+'LastError = '+IntToStr(FLastError));
 if (not Result) then
  begin
   try
    aaWriteBufferToLog(PAnsiChar(@buffer.PageHeader),Integer(PageHeaderSize));
    aaWriteBufferToLog(buffer.pData,Size);
   except
   end;
  end;
end;
{$ENDIF}
end;// WritePage


//------------------------------------------------------------------------------
// append pages to the end of file
//------------------------------------------------------------------------------
function TPageFileManager.AppendPages(qty: Integer): Boolean;
begin
 result := false;
 // 32-bit size limit check
// x := (Int64(qty) + Int64(FHeader.TOTALPageCount)) * Int64(FHeader.PageSize);
// if (x > Int64(MAXINT)) then
//  Exit;
 // add pages to total pages
  // resize file
 try
  ESFSFile.Size := Int64(FHeader.TOTALPageCount+qty) * Int64(FHeader.PageSize);
  if (ESFSFile.Size = Int64(FHeader.TOTALPageCount+qty) * Int64(FHeader.PageSize)) then
   result := True;
 except
   result := False;
 end;
 if (Result) then
  begin
   inc(FHeader.TOTALPageCount,qty);
   SaveSFHeader;
  end;
end; // AppendPages

{
//------------------------------------------------------------------------------
// deletes pages from end of file
//------------------------------------------------------------------------------
procedure TPageFileManager.DeletePagesFromEOF(qty: Integer);
var
  FileSize: Int64;
  PageCount: integer;
begin
  // file size
  FileSize := ESFSFile.Size;
  // get total pages count in file
  PageCount := FileSize div Int64(FHeader.PageSize);
  if ((FileSize mod Int64(FHeader.PageSize)) > 0) then
   inc(PageCount);
  // calc new file size
  FileSize := Int64(PageCount-qty) * Int64(FHeader.PageSize);
  if (PageCount < qty) then
   raise Exception.Create('TPageFileManager.DeletePagesFromEOF - attempt to delete more pages than exists.');
  // resize file
  ESFSFile.Size := FileSize;
end; // DeletePagesFromEOF
}

//------------------------------------------------------------------------------
// rename file
//------------------------------------------------------------------------------
function TPageFileManager.RenameFile(NewName: AnsiString): Boolean;
begin
  Result := ESFSFile.RenameFile(NewName);
end;// RenameFile


//------------------------------------------------------------------------------
// delete file
//------------------------------------------------------------------------------
function TPageFileManager.DeleteFile: Boolean;
begin
  Result := ESFSFile.DeleteFile;
end;// DeleteFile


//------------------------------------------------------------------------------
// flush file buffers
//------------------------------------------------------------------------------
procedure TPageFileManager.FlushFileBuffers;
begin
 ESFSFile.FlushBuffers;
end;// FlushFileBuffers;


//------------------------------------------------------------------------------
// load data from stream
//------------------------------------------------------------------------------
procedure TPageFileManager.LoadFromStream(Stream: TStream);
begin
 if (ESFSFile = nil) then
  raise Exception.Create('TPageFileManager.LoadFromStream - ESFSFile = nil');
 ESFSFile.LoadFromStream(Stream);
 LoadSFHeader;
 // decode default key for user files
 if (FHeader.EncMethod <> encNone) then
   CheckPassword(FHeader.PasswordHeader,FPassword,FKey)
end;// LoadFromStream


//------------------------------------------------------------------------------
// free space on disk
//------------------------------------------------------------------------------
function TPageFileManager.DiskFree: Int64;
var
 s: THeapStatus;
{$IFDEF D12H}
 drv: WideString;
{$ELSE}
 drv: AnsiString;
{$ENDIF}
 TotalSpace, FreeSpaceAvailable: Int64;
begin
 TotalSpace := 0;
 FreeSpaceAvailable := 0;
 if (FInMemory) then
  begin
   s := GetHeapStatus;
   Result := s.TotalFree;
  end
 else
  begin
{$IFDEF D12H}
   drv := ExtractFileDrive(FFileName) + #0#0;
   if drv <> ''#0#0 then
     GetDiskFreeSpaceExW(@drv[1], FreeSpaceAvailable, TotalSpace, nil)
   else
     GetDiskFreeSpaceExW(nil, FreeSpaceAvailable, TotalSpace, nil);
{$ELSE}
   drv := ExtractFileDrive(FFileName) + #0;
   if drv <> ''#0 then
     GetDiskFreeSpaceExA(@drv[1], FreeSpaceAvailable, TotalSpace, nil)
   else
     GetDiskFreeSpaceExA(nil, FreeSpaceAvailable, TotalSpace, nil);
{$ENDIF}
   Result := FreeSpaceAvailable;
  end;
end;// DiskFree



////////////////////////////////////////////////////////////////////////////////
//
//   TFreeSpaceManager
//
////////////////////////////////////////////////////////////////////////////////


{$IFDEF DEBUG_FLAG}
procedure TFreeSpaceManager.WriteMemoryUsage;
var x,y,a,b,c: cardinal;
begin
 x := Length(PFSPageMap.Items) * sizeof(Integer);
 aaWriteToLog('TFreeSpaceManager.GAMPageMap = '+IntToStr(x));

 y := Length(PFSPageMap.Items) * sizeof(Integer);
 aaWriteToLog('TFreeSpaceManager.PFSPageMap = '+IntToStr(y));

 a := PFMHandle.FHeader.GAMPageCount * FGAMPageSize;
 aaWriteToLog('TFreeSpaceManager.GAM = '+IntToStr(a));

 b := PFMHandle.FHeader.GAMPageCount * FGAMPageSize;
 aaWriteToLog('TFreeSpaceManager.SGAM = '+IntToStr(b));

 c := PFMHandle.FHeader.PFSPageCount * FPFSPageSize;
 aaWriteToLog('TFreeSpaceManager.PFS = '+IntToStr(c));

 aaWriteToLog('TFreeSpaceManager.Total = '+IntToStr((x+a+b+c+y) div 1024)+#13#10);
end;

{$ENDIF}
//------------------------------------------------------------------------------
// load procedures
//------------------------------------------------------------------------------
procedure TFreeSpaceManager.LoadPFS;
var i,CurPage,PageCount: Integer;
    buf:  TFFPage;
begin
 PFSPageMap.SetSize(0);
 PFS := nil;
 pageCount := PFMHandle.FHeader.PFSPageCount;
 if (PageCount <= 0) then
  Exit;
 PFS := AllocMem(PageCount * FPFSPageSize);
 i := 0;
 CurPage := 1;
 while i < PageCount do
  begin
   PFSPageMap.Append(CurPage);
   buf.pData := pAnsiChar(PFS + i * FPFSPageSize);
   if (not PFMHandle.ReadPage(buf,CurPage,FPFSPageSize)) then
    raise Exception.Create('TFreeSpaceManager.LoadPFS - can not load page, pageNo = '+
          IntToStr(CurPage));
   inc(CurPage,FPFSExtentsPerPage * FExtentPageCount);
   inc(i);
  end;
end; // LoadPFS


procedure TFreeSpaceManager.LoadGAM;
var i,CurPage,PageCount: Integer;
    buf:  TFFPage;
begin
 GAMPageMap.SetSize(0);
 GAM := nil;
 pageCount := PFMHandle.FHeader.GAMPageCount;
 if (PageCount <= 0) then
  Exit;
 GAM := AllocMem(PageCount * FGAMPageSize);
 SGAM := AllocMem(PageCount * FGAMPageSize);
 i := 0;
 CurPage := 2;
 while i < PageCount do
  begin
   GAMPageMap.Append(CurPage);
   buf.pData := pAnsiChar(GAM + i * FGAMPageSize);
   if (not PFMHandle.ReadPage(buf,CurPage,FGAMPageSize)) then
    raise Exception.Create('TFreeSpaceManager.LoadGAM - can not load page, pageNo = '+
          IntToStr(CurPage));
   buf.pData := pAnsiChar(SGAM + i * FGAMPageSize);
   if (not PFMHandle.ReadPage(buf,CurPage+1,FGAMPageSize)) then
    raise Exception.Create('TFreeSpaceManager.LoadGAM - can not load SGAM page, pageNo = '+
          IntToStr(CurPage));
   inc(CurPage,FGAMExtentsPerPage * FExtentPageCount);
   inc(i);
  end;
end; // LoadGAM


//------------------------------------------------------------------------------
// save PFS pages
//------------------------------------------------------------------------------
procedure TFreeSpaceManager.SavePFS(pages: TIntegerArray);
var buf:      TFFPage;
    CurPage:  Integer;
    i:        Integer;
begin
 if (pages.ItemCount <> PFSPageMap.ItemCount) then
  raise Exception.Create('TFreeSpaceManager.SavePFS - pages.ItemCount <> PFSPageMap.ItemCount!');
 buf.PageHeader.PageType := PFSPage;
 buf.PageHeader.EncType := 0;
 buf.PageHeader.CrcType := 0;
 for i := 0 to pages.ItemCount-1 do
  begin
   if (pages.Items[i] <> 1) then
    continue;
   CurPage := PFSPageMap.Items[i];
   buf.pData := pAnsiChar(PFS + i * FPFSPageSize);
   if (not PFMHandle.WritePage(buf,CurPage,FPFSPageSize)) then
    raise Exception.Create('TFreeSpaceManager.SavePFS - can not save page, pageNo = '+
        IntToStr(CurPage));
  end;
end; // SavePFS


//------------------------------------------------------------------------------
// save GAM pages
//------------------------------------------------------------------------------
procedure TFreeSpaceManager.SaveGAM(pages: TIntegerArray);
var buf:      TFFPage;
    CurPage:  Integer;
    i:        Integer;
begin
 if (pages.ItemCount <> GAMPageMap.ItemCount) then
  raise Exception.Create('TFreeSpaceManager.SaveGAM - pages.ItemCount <> GAMPageMap.ItemCount!');
 buf.PageHeader.EncType := 0;
 buf.PageHeader.CrcType := 0;
 for i := 0 to pages.ItemCount-1 do
  begin
   if (pages.Items[i] <> 1) then
    continue;
   CurPage := GAMPageMap.Items[i];
   buf.PageHeader.PageType := GAMPage;
   buf.pData := pAnsiChar(GAM + i * FGAMPageSize);
   if (not PFMHandle.WritePage(buf,CurPage,FGAMPageSize)) then
    raise Exception.Create('TFreeSpaceManager.SaveGAM - can not save page, pageNo = '+
        IntToStr(CurPage));
   buf.pData := pAnsiChar(SGAM + i * FGAMPageSize);
   buf.PageHeader.PageType := SGAMPage;
   if (not PFMHandle.WritePage(buf,CurPage+1,FGAMPageSize)) then
     raise Exception.Create('TFreeSpaceManager.SaveGAM - can not save SGAM page, pageNo = '+
        IntToStr(CurPage));
  end;
end; // SaveGAM


//------------------------------------------------------------------------------
// returns number of GAM page
//------------------------------------------------------------------------------
function TFreeSpaceManager.GetGAMPageNo(extentNo: Integer): Integer;
begin
 result := extentNo div FGAMExtentsPerPage;
end; // GetGAMPageNo


//------------------------------------------------------------------------------
// returns number of PFS page
//------------------------------------------------------------------------------
function TFreeSpaceManager.GetPFSPageNo(extentNo: Integer): Integer;
begin
 result := extentNo div FPFSExtentsPerPage;
end; // GetPFSPageNo


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TFreeSpaceManager.Create(PageFileManager: TPageFileManager);
var segment,offset: Integer;
    x: Byte;
begin
 PFMHandle := PageFileManager;
 FPageSize := PFMHandle.PageDataSize;
 FExtentPageCount := PFMHandle.FHeader.ExtentPageCount;
 // total number of pages
 FPageCount := PFMHandle.FHeader.TOTALPageCount - PFMHandle.FHeader.HDRPageCount;
 // total number of extents in file
 // extents does not contain GAM,SGAM,PFS,HDR pages
 FExtentCount := (PFMHandle.FHeader.TOTALPageCount -
                 PFMHandle.FHeader.HDRPageCount) div FExtentPageCount;
 FPFSPageSize := (FPageSize * 8 - (FPageSize * 8) mod FExtentPageCount) div 8;
 FPFSExtentsPerPage := FPFSPageSize * 8 div FExtentPageCount;
 FGAMPageSize := (FPageSize * 8 - (FPageSize * 8) mod FPFSExtentsPerPage) div 8;
 FGAMExtentsPerPage := FGAMPageSize * 8;
 // check some data
 if (PFMHandle.FHeader.PFSPageCount * FPFSExtentsPerPage < FExtentCount) then
  raise Exception.Create('TFreeSpaceManager.Create - PFSPageCount * FPageSize < FExtentCount!');
 if (PFMHandle.FHeader.GAMPageCount * FGAMExtentsPerPage < FExtentCount) then
  raise Exception.Create('TFreeSpaceManager.Create - GAMPageCount * FPageSize < FExtentCount!');

// memory optimization by Leo
// original:
// PFSPageMap := TIntegerArray.Create;
// GAMPageMap := TIntegerArray.Create;
// optimized:
 PFSPageMap := TIntegerArray.Create(0,10,10);
 GAMPageMap := TIntegerArray.Create(0,10,10);

 LoadPFS;
 LoadGAM;
 FMixedExtentCount := 0;
 FFreeExtentCount := 0;
 segment := 0;
 offset := 0;
 x := 1;
 while (segment * 8 + offset) < FExtentCount do
  begin
   if ((pByte(GAM + segment)^ and x) <> 0) then
    inc(FFreeExtentCount);
   if ((pByte(SGAM + segment)^ and x) <> 0) then
    inc(FMixedExtentCount);
   inc(offset);
   if (offset = 8) then
    begin
     inc(segment);
     offset := 0;
     x := 1;
    end
   else
    x := x shl 1; 
  end;
end; //Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TFreeSpaceManager.Destroy;
begin
{$IFDEF DEBUG_FLAG}
WriteMemoryUsage;
{$ENDIF}

 PFSPageMap.Free;
 GAMPageMap.Free;
 if (PFMHandle.FHeader.PFSPageCount > 0) then
  FreeMem(PFS);
 if (PFMHandle.FHeader.GAMPageCount > 0) then
  FreeMem(GAM);
 if (PFMHandle.FHeader.GAMPageCount > 0) then
  FreeMem(SGAM);
end; //


//------------------------------------------------------------------------------
// get pages sequence
//------------------------------------------------------------------------------
function TFreeSpaceManager.GetPages(PageCount, StartPageNo: Integer; bUniform: Boolean;
                     var pages: TIntegerArray): Boolean;
var
    CurPage,CurExtent,i,k:Integer;
    PFSPages, GAMpages:   TIntegerArray;
    bPFS,bGAM:            Boolean;
    restPages:	Integer;
    oldPages,newPages,oldExtents,newExtents: Integer;

 // this procedure uses current extent pages, if it is possible
 procedure UseExtent;
 begin
  CurPage := CurExtent * FExtentPageCount;
  k := CurPage;
  while (k < CurPage+FExtentPageCount) and (pages.ItemCount < PageCount) do
   begin
    if (GetBit(PFS,k)) then
     begin
      PFSPages.Items[GetPFSPageNo(CurExtent)] := 1;
      SetBit(PFS,k,false);
      pages.Append(k+PFMHandle.FHeader.HDRPageCount);
      // extent was free
      if (k = CurPage) then
       begin
        if (FFreeExtentCount > 0) and
           (GetBit(GAM,CurExtent)) and
           (not GetBit(SGAM,CurExtent)) then
         dec(FFreeExtentCount);
        if (bUniform) then
         begin
          // mark Current extent as uniform
          SetBit(GAM,CurExtent,false);
          SetBit(SGAM,CurExtent,false);
         end
        else
         begin
          // mark Current extent as mixed
          SetBit(GAM,CurExtent,false);
          SetBit(SGAM,CurExtent,true);
          inc(FMixedExtentCount);
         end;
        GAMPages.Items[GetGAMPageNo(CurExtent)] := 1;
       end; // fee extent marked as mixed or uniform
      // extent full
      if (k = CurPage+FExtentPageCount-1) then
       begin
        if (GetBit(SGAM,CurExtent)) then
         dec(FMixedExtentCount);
        // mark Current extent as full
        SetBit(GAM,CurExtent,false);
        SetBit(SGAM,CurExtent,false);
        GAMPages.Items[GetGAMPageNo(CurExtent)] := 1;
       end; // extent marked as full
     end; // GetBit = 1, free page found
    inc(k);
   end; // while
 end; // UseExtent


 // adds extents to file
 procedure AddExtents;
 var NumInternalPages, NumInternalExtents, InternalExtent: Integer;
 begin
  oldPages := PFMHandle.FHeader.TOTALPageCount-PFMHandle.FHeader.HDRPageCount;
  oldExtents := FExtentCount;
  newPages := 0;
  newExtents := 0;
  while (newPages < restPages) do
   begin
    bPFS := false;
    bGAM := false;
    if (newExtents + oldExtents =
        FPFSExtentsPerPage * PFMHandle.FHeader.PFSPageCount) then
     bPFS := true;
    if (newExtents + oldExtents =
        FGAMExtentsPerPage * PFMHandle.FHeader.GAMPageCount) then
     bGAM := true;
    if (bGAM or bPFS) then
     begin
      inc(PFMHandle.FHeader.PFSPageCount);
      reallocMem(PFS,PFMHandle.FHeader.PFSPageCount * FPFSPageSize);
      // mark all pages in new pfs page as free
      FillChar(pAnsiChar(PFS+(PFMHandle.FHeader.PFSPageCount-1) * FPFSPageSize)^,
                 FPFSPageSize,$FF);

      if (PFSPageMap.ItemCount > 0) then
        i := PFSPageMap.Items[PFSPageMap.ItemCount-1] +
            FPFSExtentsPerPage * FExtentPageCount
      else
      // first PFS page number = 1
       i := 1;
      PFSPageMap.Append(i);
      // new allocated page will be saved
      PFSPages.Append(1);
      // mark new pfs page as full
      i := (oldExtents+newExtents)*FExtentPageCount;
      SetBit(PFS,i,false);
      if (bGAM) then
       begin
        inc(PFMHandle.FHeader.GAMPageCount);
        reallocMem(GAM,PFMHandle.FHeader.GAMPageCount * FGAMPageSize);
        reallocMem(SGAM,PFMHandle.FHeader.GAMPageCount * FGAMPageSize);
        // mark all extents in new GAM/SGAM page as free extents
        FillChar(pAnsiChar(GAM+(PFMHandle.FHeader.GAMPageCount-1) * FGAMPageSize)^,
                 FGAMPageSize,$FF);
        FillChar(pAnsiChar(SGAM+(PFMHandle.FHeader.GAMPageCount-1) * FGAMPageSize)^,
                 FGAMPageSize,$00);
        // mark new extent as mixed
//        SetBit(GAM,oldExtents+newExtents,false);
//        SetBit(SGAM,oldExtents+newExtents,true);
        // mark new GAM page as full
        SetBit(PFS,i+1,false);
        // mark new SGAM page as full
        SetBit(PFS,i+2,false);
        if (GAMPageMap.ItemCount > 0) then
          i := GAMPageMap.Items[GAMPageMap.ItemCount-1] +
              FGAMExtentsPerPage * FExtentPageCount
        else
        // first GAM page number = 2
         i := 2;
        GAMPageMap.Append(i);
        // new allocated page will be saved
        GAMPages.Append(1);
       end; // GAM and SGAM
      NumInternalPages := 0;
      if (bPFS) then
       Inc(NumInternalPages); // PFS page
      if (bGAM) then
       Inc(NumInternalPages,2); // GAM and SGAM pages
      NumInternalExtents := NumInternalPages div FExtentPageCount;
      if (NumInternalPages mod FExtentPageCount > 0) then
       Inc(NumInternalExtents);
      for InternalExtent := oldExtents+newExtents to
        oldExtents+newExtents + NumInternalExtents-2 do
       begin
        SetBit(GAM,InternalExtent,False);
        SetBit(SGAM,InternalExtent,False);
       end;
      InternalExtent := oldExtents+newExtents + NumInternalExtents-1;
      if (NumInternalPages mod FExtentPageCount > 0) then
       begin
        Inc(FMixedExtentCount);
        if (not bUniform) then
         newPages := newPages + FExtentPageCount - (NumInternalPages mod FExtentPageCount);
        SetBit(GAM,InternalExtent,False);
        SetBit(SGAM,InternalExtent,True);
       end // last internal extent is mixed
      else
       begin
        SetBit(GAM,InternalExtent,False);
        SetBit(SGAM,InternalExtent,False);
       end; // last internal extent is full
      Inc(newExtents,NumInternalExtents);
     end // GAM or PFS extension
    else
     begin
      // add pages of new free extent
      inc(newPages,FExtentPageCount);
      inc(FFreeExtentCount);
      inc(newExtents);
     end;
   end; // while newPages < PageCount
  FExtentCount := oldExtents + newExtents;
 end; // AddExtents

// GetPages
begin
 result := true;
// pages := TIntegerArray.Create(0,PageCount,PageCount);
 pages.SetSize(0);
 PFSPages := TIntegerArray.Create(PFSPageMap.ItemCount,1,10);
 GAMPages := TIntegerArray.Create(GAMPageMap.ItemCount,1,10);
 // clear save pages flags
 for i := 0 to PFSPages.ItemCount-1 do
  PFSPages.Items[i] := 0;
 for i := 0 to GAMPages.ItemCount-1 do
  GAMPages.Items[i] := 0;
 // check Current extent for free pages
 CurPage := StartPageNo - PFMHandle.FHeader.HDRPageCount;
 CurExtent := CurPage div FEXtentPageCount;
 //if not existing page is specified
 if (CurExtent < FExtentCount) then
  UseExtent
 else
  CurExtent := 0;
 // try to use existing free pages
 if (bUniform and (FFreeExtentCount > 0))
    or
   ((not bUniform) and ((FMixedExtentCount > 0) or (FFreeExtentCount > 0))) then
  begin
   CurExtent := 0;
   while (CurExtent < FExtentCount) and (pages.ItemCount < PageCount) do
    begin
     // if extent is free or mixed try to use it
     if (GetBit(GAM,CurExtent) or (GetBit(SGAM,CurExtent) and (not bUniform))) then
      UseExtent;
     inc(CurExtent);
    end;
  end;
 // if some pages must be added
 if (pages.ItemCount < PageCount) then
  begin
   // calculate rest number of extents
   // these extents will be added as free to the file
   restPages := PageCount - pages.ItemCount;
   // add extents to the file
   AddExtents;
   if (newExtents <= 0) then
    raise Exception.Create('TFreeSpaceManager.GetPages - AddExtents does not append any extents.');
   result := PFMHandle.AppendPages(newExtents * FExtentPageCount);
   if (result) then
    begin
     while (CurExtent < FExtentCount) and (pages.ItemCount < PageCount) do
      begin
       // if extent is free or mixed try to use it
       if (GetBit(GAM,CurExtent) or (GetBit(SGAM,CurExtent) and (not bUniform))) then
        UseExtent;
       inc(CurExtent);
      end;
     if (pages.ItemCount < PageCount) then
      raise Exception.Create('TFreeSpaceManager.GetPages - AddExtents appends too small pages.');
    end;
  end;
 if (result) then
  begin
   // try to extend file
   k := 0;
   for i:=0 to pages.ItemCount-1 do
    if (pages.Items[i] > k) then
     k := pages.Items[i];

   if (k > PFMHandle.FHeader.TOTALPageCount-1) then
     Result := PFMHandle.AppendPages(k - PFMHandle.FHeader.TOTALPageCount+1);
   if (Result) then
    begin
     SaveGAM(GAMPages);
     SavePFS(PFSPages);
    end;
  end;
 GAMPages.Free;
 PFSPages.Free;
end; // GetPages


//------------------------------------------------------------------------------
// free pages sequence
//------------------------------------------------------------------------------
procedure TFreeSpaceManager.FreePages(var pages: TIntegerArray);
var freeExtents:             TIntegerArray;
    CurPage,CurExtent,i,k: Integer;
    bFree:                   Boolean;
    PFSPages, GAMpages:      TIntegerArray;
    LastPageNo:              Integer;
    OldLastPageNo:           Integer;
    NewSize:                 Int64;

 // this procedure frees current extent, if it is not used
 procedure FreeExtent;
 begin
  k := CurExtent * FExtentPageCount;
  CurPage := k;
  bFree := true;
  while (k < CurPage+FExtentPageCount) do
   begin
    if (not GetBit(PFS,k)) then
     begin
      bFree := false;
      break;
     end;
    inc(k);
   end; // while
  if (bFree) then
   begin
    if (GetBit(SGAM,CurExtent)) then
     dec(FMixedExtentCount);
    // mark Current extent as uniform
    SetBit(GAM,CurExtent,true);
    SetBit(SGAM,CurExtent,false);
    GAMPages.Items[GetGAMPageNo(CurExtent)] := 1;
    inc(FFreeExtentCount);
   end;
 end; // FreeExtent

 function GetLastUsedPageNo: Integer;
 var i: Integer;
 begin
  Result := 0;
  for i := PFMHandle.FHeader.TOTALPageCount - PFMHandle.FHeader.HDRPageCount - 1 downto 0 do
   if (not GetBit(PFS,i)) then
    begin
     Result := i + PFMHandle.FHeader.HDRPageCount;
     break;
    end;
 end; // GetLastUsedPageNo


begin
 // this is an array of extent flags
 // each extent flag = 1 if any page belonging this extent was marked as free
 freeExtents := TIntegerArray.Create(FExtentCount,1,10);
 // clear used extents flags
 for i := 0 to freeExtents.ItemCount-1 do
  freeExtents.Items[i] := 0;
 PFSPages := TIntegerArray.Create(PFSPageMap.ItemCount,1,10);
 GAMPages := TIntegerArray.Create(GAMPageMap.ItemCount,1,10);
 // clear save pages flags
 for i := 0 to PFSPages.ItemCount-1 do
  PFSPages.Items[i] := 0;
 for i := 0 to GAMPages.ItemCount-1 do
  GAMPages.Items[i] := 0;
// LastPageNo := PFMHandle.FHeader.TOTALPageCount-1;
 LastPageNo := GetLastUsedPageNo;
 OldLastPageNo := LastPageNo;
 pages.Sort(False);
 // free pages
 for i := 0 to pages.ItemCount-1 do
  begin
   CurPage := pages.Items[i];
   if (CurPage >= LastPageNo) then
     LastPageNo := CurPage-1;
   // if this page does not exists
   if (CurPage >= PFMHandle.FHeader.TOTALPageCount) then
    continue;
   // dec not addressed page count
   dec(CurPage,PFMHandle.FHeader.HDRPageCount);
   // mark current page as free
   SetBit(PFS,CurPage,true);
   // set extent flag
   CurExtent := CurPage div FExtentPageCount;
   freeExtents.Items[CurExtent] := 1;
   // mark PFS page for saving
   PFSPages.Items[GetPFSPageNo(CurExtent)] := 1;
  end;
 // free extents
 for i := 0 to freeExtents.ItemCount-1 do
  begin
   if (freeExtents.Items[i] <> 1) then
    continue;
   curExtent := i;
   FreeExtent;
  end;
 SaveGAM(GAMPages);
 SavePFS(PFSPages);
 GAMPages.Free;
 PFSPages.Free;
 freeExtents.Free;
 if (LastPageNo < OldLastPageNo) then
  begin
   NewSize := Int64(LastPageNo+1) * Int64(PFMHandle.FHeader.PageSize);
   PFMHandle.ESFSFile.Size := NewSize;
  end;
//  PFMHandle.DeletePagesFromEOF((PFMHandle.FHeader.TOTALPageCount - 1) - LastPageNo);
// pages.Free;
end; // FreePages


//------------------------------------------------------------------------------
// returns free page count
//------------------------------------------------------------------------------
function TFreeSpaceManager.GetFreePageCount: Int64;
begin
 result := FFreeExtentCount * FExtentPageCount * FPageSize;
end;


////////////////////////////////////////////////////////////////////////////////
//
//   TDIRManager
//
////////////////////////////////////////////////////////////////////////////////


{$IFDEF DEBUG_FLAG}
procedure TDIRManager.WriteMemoryUsage;
var x,y,z: cardinal;
i: integer;
begin
 x := Length(FDIR.Items) * sizeof(TDirectoryElement);
 aaWriteToLog('DirManager.FDIRArray.Items - '+IntToStr(x));

 y := Length(FDIR.NameIndex.Items) * sizeof(integer) +
      Length(FDIR.ParentIndex.Items) * sizeof(integer);
 aaWriteToLog('DirManager.FDIRArray.Indexes - '+IntToStr(y));

 z := 0;
 if (FDir.FoundItems <> nil) then
  for i := 0 to FDir.FoundItemCount-1 do
   if (FDir.FoundItems[i] <> nil) then
    inc(z,Length(FDir.FoundItems[i].Items) * sizeof(integer));
 aaWriteToLog('DirManager.FDIRArray.FoundItems - '+IntToStr(z));
 aaWriteToLog('DirManager.Total - '+IntToStr((x+y+z) div 1024)+#13#10);
end;

{$ENDIF}
//------------------------------------------------------------------------------
// load DIR
//------------------------------------------------------------------------------
procedure TDIRManager.Load;
var i, curPage,Size:Integer;
    buf:            TFFPage;
    buffer:         PAnsiChar;
begin
 buf.PageHeader.PageType := DIRPage;
 buf.PageHeader.CrcType := 0;
 buf.PageHeader.EncType := PFMHandle.FHeader.EncMethod;

 buffer := AllocMem(PFMHandle.FHeader.DIRPageCount * FDIRElementsPerPage *
        DirElementSize);

 i := 0;
 DIRPageMap.SetSize(0);
 curPage := PFMHandle.FHeader.DIRFirstPageNo;
 while i < PFMHandle.FHeader.DIRPageCount do
  begin
   DIRPageMap.Append(curPage);
//   buf.pData := @(FDIR.Items[i * FDIRElementsPerPage]);
{
   if (i < PFMHandle.FHeader.DIRPageCount-1) then
    Size := FDIRPageSize
   else
    Size := (PFMHandle.FHeader.DIRElementsCount mod FDIRElementsPerPage) *
            DIRElementSize;
   if (Size = 0) then
}
    Size := FDIRPageSize;
   buf.pData := pAnsiChar(buffer + i * FDIRElementsPerPage * DIRElementSize);
   if (not PFMHandle.ReadPage(buf,CurPage,Size)) then
    begin
     if (i <= 1) then
      PFMHandle.FHeader.DIRPageCount := 0
     else
      PFMHandle.FHeader.DIRPageCount := i-1;
     PFMHandle.FHeader.DIRElementsCount := PFMHandle.FHeader.DIRPageCount * FDIRElementsPerPage;
//     break;

    raise Exception.Create('TDIRManager.Load - can not load page, pageNo = '+
          IntToStr(CurPage));

    end;
   CurPage := buf.PageHeader.NextPageNo;
   inc(i);
  end;

 FDIR.SetSize(0);
 FOpenedFiles.SetSize(0);
 for i := 0 to PFMHandle.FHeader.DIRElementsCount-1 do
  begin
   FDIR.AppendItem(pDirectoryElement(buffer+i*DIRElementSize)^);
   FOpenedFiles.Append(0);
  end;
 FreeMem(buffer);
end; // Load


//------------------------------------------------------------------------------
// appends element to DIR
// if it was unable to Append this element - returns false
//------------------------------------------------------------------------------
function TDIRManager.AddItem(item: TDirectoryElement): Boolean;
var i, curPage,Size:Integer;
    buf:            TFFPage;
    pages:          TIntegerArray;
    bUniform:       Boolean;
    StartPage:      Integer;
    el:							TDirectoryElement;
begin
 result := true;
 // search for deleted directory elements
 for i := 0 to FDIR.ItemCount-1 do
  begin
   el := FDIR.ReadItem(i);
   if (el.IsDeleted <> 0) then
    begin
     // deleted element found
     WriteItem(i,item);
     Exit;
    end;
  end;

 buf.PageHeader.PageType := DIRPage;
 buf.PageHeader.CrcType := 0;
 buf.PageHeader.EncType := PFMHandle.FHeader.EncMethod;
 buf.pData := nil;
 if (PFMHandle.FHeader.DIRPageCount * FDIRElementsPerPage =
     PFMHandle.FHeader.DIRElementsCount) then
  begin
   // try to add page
   bUniform := false;
   if (PFMHandle.FHeader.DIRPageCount = 0) then
    begin
     StartPage := PFMHandle.FHeader.HDRPageCount;
    end
   else
    begin
     if (PFMHandle.FHeader.DIRPageCount > UNIFORM_MIN_PAGE_COUNT) then
      bUniform := true;
     StartPage := DIRPageMap.Items[DIRPageMap.ItemCount-1];
    end;
   pages := TIntegerArray.Create(1,1,1);
   if (not FSMHandle.GetPages(1,StartPage,bUniform,pages)) then
    begin
     FLastError := erDiskFull;
     pages.Free;
     result := false;
     Exit;
    end;
   // Appending new page
   if (PFMHandle.FHeader.DIRPageCount = 0) then
    begin
     curPage := pages.Items[0];
     PFMHandle.FHeader.DIRFirstPageNo := curPage;
    end
   else
    begin
     // load last page header
     curPage := DIRPageMap.Items[DIRPageMap.ItemCount-1];
     if (not PFMHandle.ReadPage(buf,curPage,0)) then
      raise Exception.Create('TDIRManager.AddItem - can not load last page, pageNo = '+
          IntToStr(CurPage));
     buf.PageHeader.NextPageNo := pages.Items[0];
     if (not PFMHandle.WritePage(buf,curPage,0)) then
      raise Exception.Create('TDIRManager.AddItem - can not save last page, pageNo = '+
          IntToStr(CurPage));
    end;
   curPage := pages.Items[0];
   pages.Free;
   // append new page
   DIRPageMap.Append(curPage);
   inc(PFMHandle.FHeader.DIRPageCount);
  end; // appending new page
 // save last page
 inc(PFMHandle.FHeader.DIRElementsCount);
 FDIR.AppendItem(item);
 FOpenedFiles.Append(0);
 i := (PFMHandle.FHeader.DIRElementsCount-1) div FDIRElementsPerPage;
 curPage := DIRPageMap.Items[DIRPageMap.ItemCount-1];
 if ((PFMHandle.FHeader.DIRElementsCount-1) mod FDIRElementsPerPage <> 0) then
  if (not PFMHandle.ReadPage(buf,curPage,0)) then
    raise Exception.Create('TDIRManager.AddItem - can not load  page, pageNo = '+
          IntToStr(CurPage));

 Size := FDIRPageSize;
 buf.pData := AllocMem(Size);
 Move(FDIR.Items[i * FDIRElementsPerPage],buf.pData^,Size);
{
 buf.pData := @FDIR.Items[(FDIR.ItemCount-1) -
                          (FDIR.ItemCount-1) mod FDIRElementsPerPage];
}
{
 Size := (PFMHandle.FHeader.DIRElementsCount mod FDIRElementsPerPage) *
            DIRElementSize;
 if (Size = 0) then
}
 if (not PFMHandle.WritePage(buf,curPage,Size)) then
      raise Exception.Create('TDIRManager.AddItem - can not save page, pageNo = '+
          IntToStr(CurPage));
 FreeMem(buf.pData);
 PFMHandle.SaveSFHeader;
end; //


//------------------------------------------------------------------------------
// read item
//------------------------------------------------------------------------------
procedure TDIRManager.ReadItem(ItemNo: Integer; var item: TDirectoryElement);
begin
 item := FDIR.ReadItem(itemNo);
end; //


//------------------------------------------------------------------------------
// write item
//------------------------------------------------------------------------------
procedure TDIRManager.WriteItem(ItemNo: Integer; item: TDirectoryElement);
var i, curPage,Size:Integer;
    buf:            TFFPage;
begin
 FDIR.UpdateItem(item,ItemNo);
 // if file deleted it means that it is closed
 if (item.IsDeleted <> 0) then
  FOpenedFiles.Items[itemNo] := 0;
 // save current page
 i := itemNo div FDIRElementsPerPage;
 curPage := DIRPageMap.Items[i];
 if (not PFMHandle.ReadPage(buf,curPage,0)) then
    raise Exception.Create('TDIRManager.WriteItem - can not load  page, pageNo = '+
          IntToStr(CurPage));

 Size := FDIRPageSize;
 buf.pData := AllocMem(Size);
 Move(FDIR.Items[i * FDIRElementsPerPage],buf.pData^,Size);
{
 if (i = PFMHandle.FHeader.DIRPageCount - 1) then
  Size := (PFMHandle.FHeader.DIRElementsCount mod FDIRElementsPerPage) *
            DIRElementSize
 else
  Size := FDIRPageSize;
 if (Size = 0) then
}
 if (not PFMHandle.WritePage(buf,curPage,Size)) then
      raise Exception.Create('TDIRManager.WriteItem - can not save page, pageNo = '+
          IntToStr(CurPage));
 FreeMem(buf.pData);
end; // WriteItem


//------------------------------------------------------------------------------
// find by name, returns element number or erFileNotFound if no element were found
//------------------------------------------------------------------------------
function TDIRManager.FindByName(FileName: AnsiString): Integer;
begin
 result := FDIR.FindFileByName(pAnsiChar(FileName),CurrentDir);
end; //


//------------------------------------------------------------------------------
// returns full file path (form root, '\folder1\folder2')
//------------------------------------------------------------------------------
function TDIRManager.GetFullFilePath(ItemNo: Integer): AnsiString;
begin
 result := FDIR.GetFullFilePath(ItemNo);
end; // GetFullFilePath


//------------------------------------------------------------------------------
// creates file, returns returns erFileNotFound if file can not be created;
// if file created successfully return value will be index of directory element
//------------------------------------------------------------------------------
function TDIRManager.FileCreate(const FileName: AnsiString;
				 Password: AnsiString = '';
				 Question: AnsiString = '';
				 Answer: AnsiString = ''
         ): Integer;
var el:           TDirectoryElement;
    path,dirName: PAnsiChar;
    dirID:        Integer;
begin
 result := None;
 if (FileName = '') then
  Exit;
 if (FileName = '\') or (FileName = '/') then
  Exit;
 InitDirectoryElement(el);
 if (not ExtractPathAndPattern(pAnsiChar(FileName),path,dirName)) then
  begin
   dirID := currentDir;
   ESFSEngine.SetFileName(FileName,el);
  end
 else
  begin
   if (path^ = #0) then
    dirID := currentDir
   else
    dirID := FDIR.FindFileByName(path,currentDir);
   ESFSEngine.SetFileName(dirName,el);
   FreeMem(path);
   FreeMem(dirName);
  end;

 if (dirID <= erInvalidPath) then
  Exit;
 // filling new file structure
 el.ParentID := dirID;
 if (Password <> '') then
  begin
	 el.EncMethod := EncRijndael;
   CreatePasswordHeader(el.PasswordHeader,Password,Question,Answer);
  end;

 el.FirstMapPageNo := None;
 el.FileSize := 0;
 SetCurrentTime(el.CreationTime);
 el.LastModifiedTime := el.CreationTime;
 el.LastAccessTime := el.CreationTime;
 el.Attributes := 0;
 el.IsFolder := 0;
 if (AddItem(el)) then
  result := FDIR.ItemCount-1;
end; // FileCreate


//------------------------------------------------------------------------------
// open file if it is possible; returns erFileNotFound if file does not exists
//------------------------------------------------------------------------------
function TDIRManager.FileOpen(const FileName: AnsiString; Password: AnsiString;
					var Key: AnsiString): Integer;
var el: TDirectoryElement;
begin
 // find existing file or folder
 result := FindByName(FileName);
 if (result <= None) then
  begin
   result := None;
   Exit;
  end
 else
  // if folder was found return error
  el := FDIR.ReadItem(result);
  if (el.IsFolder <> 0) then
  begin
   result := None;
   Exit;
  end;
 // inc number of opened file handles
 inc(FOpenedFiles.Items[result]);
 // prepare key value for read/write pages
 Key := '';
 if (el.EncMethod <> EncNone) then
  CheckPassword(el.PasswordHeader,Password,Key);
 if (not PFMHandle.FReadOnly) then
  begin
   ESFSEngine.SetCurrentTime(el.LastAccessTime);
   WriteItem(result,el);
  end;
end; // FileOpen


//------------------------------------------------------------------------------
// file close (itemNo - index of directory element for the file)
//------------------------------------------------------------------------------
procedure TDIRManager.FileClose(ItemNo: Integer);
begin
 // dec number of opened file handles
 if (itemNo >= 0) and (itemNo < FOpenedFiles.ItemCount) then
  dec(FOpenedFiles.Items[itemNo]);
end; // FileClose


//------------------------------------------------------------------------------
// renames file
//------------------------------------------------------------------------------
function TDIRManager.RenameFile(const OldName, NewName: AnsiString): Boolean;
var el:	TDirectoryElement;
    FileID,dirID: Integer;
    path,dirName:	PAnsiChar;
    name:					AnsiString;
begin
 result := false;
 // check if file exists
 FileID := FindByName(NewName);
 if (FileID >= erOk) and (AnsiLowerCase(OldName) <> AnsiLowerCase(NewName)) then
  Exit;

 FileID := FindByName(OldName);
 if (FileID <= None) then
  Exit;
 if (GetOpenFiles(FileID) > 0) then
  Exit;

 if (not ExtractPathAndPattern(PAnsiChar(NewName),path,dirName)) then
  begin
   dirID := currentDir;
   name := NewName;
  end
 else
  begin
   dirID := FDIR.FindFileByName(path,currentDir);
   SetLength(name,Length(dirName)+1);
   StrCopy(pAnsiChar(name),dirName);
	 if (dirID <= erInvalidPath) then
    begin
     if (not ForceDirectories(path)) then
      Exit;
     dirID := FDIR.FindFileByName(path,currentDir);
  	 if (dirID <= erInvalidPath) then
      Exit;
    end;
   FreeMem(path);
   FreeMem(dirName);
  end;
 // mark old file as deleted
 ReadItem(FileID,el);
 el.IsDeleted := 1;
 WriteItem(FileID,el);
 // filling new file structure
 el.ParentID := dirID;
 el.IsDeleted := 0;
 ESFSEngine.SetFileName(Name,el);
 SetCurrentTime(el.LastModifiedTime);
 el.LastAccessTime := el.LastModifiedTime;
 // write new element
 WriteItem(FileID,el);
 result := true;
end; // RenameFile


//------------------------------------------------------------------------------
// returns number of opened files for specified directory element
//------------------------------------------------------------------------------
function TDIRManager.GetOpenFiles(ItemNo: Integer): Integer;
begin
 if (ItemNo >= 0) and (ItemNo < FOpenedFiles.ItemCount) then
  result := FOpenedFiles.Items[ItemNo]
 else
  result := None;
end; // GetOpenFiles


//------------------------------------------------------------------------------
// returns true and restores password if control answer is valid
//------------------------------------------------------------------------------
function TDIRManager.RestorePasswordByControlAnswer(FileName: AnsiString; Answer: AnsiString; var Password: AnsiString): Boolean;
var FileID: Integer;
	  el: TDirectoryElement;
begin
 result := false;
 FileID := FindByName(FileName);
 if (FileID < erOk) or (FileID >= FDIR.ItemCount) then
  Exit;
 result := true;

 el := FDIR.ReadItem(FileID);
 if (el.EncMethod <> EncNone) then
  if (not CheckAnswer(el.PasswordHeader,Answer,Password)) then
   result := false;
end; // RestorePasswordByControlAnswer


//------------------------------------------------------------------------------
// returns true if Single file password is valid
//------------------------------------------------------------------------------
function TDIRManager.IsPasswordValid(FileName: AnsiString; Password: AnsiString): Boolean;
var FileID: Integer;
    Key: AnsiString;
	  el: TDirectoryElement;
begin
 result := false;
 FileID := FindByName(FileName);
 if (FileID < erOk) or (FileID >= FDIR.ItemCount) then
  Exit;
 result := true;
 el := FDIR.ReadItem(FileID);
 if (el.EncMethod <> EncNone) then
  if (not CheckPassword(el.PasswordHeader,Password,Key)) then
   result := false;
end; //IsPasswordValid


//------------------------------------------------------------------------------
// returns control question
//------------------------------------------------------------------------------
function TDIRManager.GetControlQuestion(FileName: AnsiString): AnsiString;
var FileID: Integer;
	  el: TDirectoryElement;
begin
 result := '';
 FileID := FindByName(FileName);
 if (FileID < erOk) or (FileID >= FDIR.ItemCount) then
  Exit;
 el := FDIR.ReadItem(FileID);
 if (el.EncMethod <> EncNone) then
   result := DecryptQuestion(el.PasswordHeader);
end; //GetControlQuestion


//------------------------------------------------------------------------------
// returns password header
//------------------------------------------------------------------------------
function TDIRManager.GetPasswordHeader(FileName: AnsiString; var passHeader: TPasswordHeader): Boolean;
var FileID: Integer;
	  el: TDirectoryElement;
begin
 result := false;
 FileID := FindByName(FileName);
 if (FileID < erOk) or (FileID >= FDIR.ItemCount) then
  Exit;
 el := FDIR.ReadItem(FileID);
 passHeader := el.PasswordHeader;
 result := true;
end;


//------------------------------------------------------------------------------
// sets password header
//------------------------------------------------------------------------------
procedure TDIRManager.SetPasswordHeader(FileName: AnsiString; passHeader: TPasswordHeader);
var FileID: Integer;
	  el: TDirectoryElement;
begin
 FileID := FindByName(FileName);
 if (FileID < erOk) or (FileID >= FDIR.ItemCount) then
  Exit;
 el := FDIR.ReadItem(FileID);
 el.PasswordHeader := passHeader;
 WriteItem(FileID,el);
end;


//------------------------------------------------------------------------------
// returns true if file is encrypted by its own password
//------------------------------------------------------------------------------
function TDIRManager.IsFileEncrypted(FileName: AnsiString): boolean;
var FileID: Integer;
	  el: TDirectoryElement;
begin
 result := false;
 FileID := FindByName(FileName);
 if (FileID < erOk) or (FileID >= FDIR.ItemCount) then
  Exit;
 el := FDIR.ReadItem(FileID);
 if (el.EncMethod <> EncNone) then
   result := true;
end; // IsFileEncrypted


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TDIRManager.Create(PageFileManager: TPageFileManager;
                               FreeSpaceManager: TFreeSpaceManager);
begin
 //
 PFMHandle := PageFileManager;
 FSMHandle := FreeSpaceManager;

// memory optimization by Leo
// original:
// DIRPageMap := TIntegerArray.Create;
// optimized:
 DIRPageMap := TIntegerArray.Create(0,10,100);

 CurrentDIR := -1; // root
 CurrentPath := '\';
 FDIRElementsPerPage := PFMHandle.PageDataSize div DIRElementSize;
 FDIRPageSize := FDIRElementsPerPage * DIRElementSize;
 FDIR := TDIRArray.Create(0,FDIRElementsPerPage,
                          FDIRElementsPerPage * 10);
// memory optimization by Leo
// original:
// FOpenedFiles := TIntegerArray.Create(0,10,1000);
// optimized:
 FOpenedFiles := TIntegerArray.Create(0,10,100);
 Load;
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TDIRManager.Destroy;
begin
{$IFDEF DEBUG_FLAG}
WriteMemoryUsage;
{$ENDIF}
 DIRPageMap.Free;
 FDIR.Free;
 FOpenedFiles.Free;
 inherited Destroy;
end; // Destroy


//----------------------- User Interface ----------------------------------
// find file by pattern using '*', '?'
//------------------------------------------------------------------------------
function TDIRManager.FindFirst(const Path: AnsiString; Attr: Integer; var F: TSearchRec): Integer;
begin
 if (Path[1] = '\') or (Path[1] = '/') then
  result := FDIR.FindFirst(Path,Attr,F,rootID)
 else
  result := FDIR.FindFirst(Path,Attr,F,CurrentDir);
end; // FindFirst


//------------------------------------------------------------------------------
// find next file
//------------------------------------------------------------------------------
function TDIRManager.FindNext(var F: TSearchRec): Integer;
begin
 result := FDIR.FindNext(F);
end; // FindNext


//------------------------------------------------------------------------------
// closes find structure
//------------------------------------------------------------------------------
procedure TDIRManager.FindClose(var F: TSearchRec);
begin
 FDIR.FindClose(F);
end; // FindClose


//------------------------------------------------------------------------------
// returns current directory name ('\' if root directory )
//------------------------------------------------------------------------------
function TDIRManager.GetCurrentDir: AnsiString;
begin
 result := CurrentPath;
end; // GetCurrentDir


//------------------------------------------------------------------------------
// return value set to True if directory successfully changed
//------------------------------------------------------------------------------
function TDIRManager.SetCurrentDir(const Dir: AnsiString): Boolean;
var res: Integer;
begin
 Result := false;
 if (Dir = '') then
  Exit;
 res := FDir.FindFileByName(pAnsiChar(Dir),CurrentDir);
 if (res <= erInvalidPath) then
  Exit;
 CurrentDir := res;
 CurrentPath := FDIR.GetFullFilePath(CurrentDir);
 Result := true;
end; // SetCurrentDir


//------------------------------------------------------------------------------
// removes directory
//------------------------------------------------------------------------------
function TDIRManager.RemoveDir(const Dir: AnsiString): Boolean;
var  res,dirID:    Integer;
     el:           TDirectoryElement;
     sr:					 TSearchRec;
     Name:				 AnsiString;
begin
 result := false;
 dirID := FDIR.FindFileByName(pAnsiChar(Dir),currentDir);
 if (dirID <= erInvalidPath) then
  Exit;
 // check if is not empty
 if (pAnsiChar(pAnsiChar(Dir)+Length(Dir)-1)^ = '\') or (pAnsiChar(pAnsiChar(Dir)+Length(Dir)-1)^ = '/') then
  Name := Dir + '*.*'
 else
  Name := Dir + '\*.*';

 if (Dir[1] = '/') or (Dir[1] = '\') then
  res := FDIR.FindFirst(Name,faAnyFile,sr,rootID)
 else
  res := FDIR.FindFirst(Name,faAnyFile,sr,currentDir);
 FDIR.FindClose(sr);
 if (res = erOk) then
  begin
   Exit;
  end;

 el := FDIR.ReadItem(dirID);
 if (el.IsFolder <> 1) then
  Exit;
 el.IsDeleted := 1;
 SetCurrentTime(el.LastModifiedTime);
 el.LastAccessTime := el.LastModifiedTime;
 WriteItem(dirID,el);
 result := true;
end; // RemoveDir


//------------------------------------------------------------------------------
// creates directory
//------------------------------------------------------------------------------
function TDIRManager.CreateDir(const Dir: AnsiString): Boolean;
var el:           TDirectoryElement;
    path,dirName: PAnsiChar;
    dirID:        Integer;
begin

 result := false;
 if (Dir = '') then
  Exit;
 if (Dir = '\') or (Dir = '/') then
  Exit;

 if (DirectoryExists(Dir)) then
  Exit;

//aaStartTime;
 InitDirectoryElement(el);

 if (not ExtractPathAndPattern(pAnsiChar(Dir),path,dirName)) then
  begin
   dirID := currentDir;
   ESFSEngine.SetFileName(dir,el);
  end
 else
  begin
   dirID := FDIR.FindFileByName(path,currentDir);
   ESFSEngine.SetFileName(dirName,el);
   FreeMem(path);
   FreeMem(dirName);
  end;

 if (dirID <= erInvalidPath) then
  Exit;
// result := true;
 // filling directory structure
 el.ParentID := dirID;
 el.FirstMapPageNo := None;
 SetCurrentTime(el.CreationTime);
 el.LastModifiedTime := el.CreationTime;
 el.LastAccessTime := el.CreationTime;
 el.Attributes := faDirectory;
 el.IsFolder := 1;

 Result := AddItem(el);
//aaStopTime;
end; // CreateDir


//------------------------------------------------------------------------------
// Creates all the directories along a directory path if they do not already exist
//------------------------------------------------------------------------------
function TDIRManager.ForceDirectories(Dir: AnsiString): Boolean;
var
    path,dirName: PAnsiChar;
begin
 result := false;
 if (Dir = '') then
  Exit;

 if (not ExtractPathAndPattern(pAnsiChar(Dir),path,dirName)) then
  begin
   result := true;
   if (not DirectoryExists(Dir)) then
    result := CreateDir(Dir);
   Exit;
  end
 else
 if ({$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}path) = 0) then
  begin
   result := true;
   if (not DirectoryExists(Dir)) then
    result := CreateDir(Dir);
   FreeMem(path);
   FreeMem(dirName);
   Exit;
  end;

 if (not DirectoryExists(path)) then
  if (not ForceDirectories(path)) then
   raise Exception.Create('TDIRManager.ForceDirectories - ForceDirectories error!');
 result := true;
 if (not DirectoryExists(AnsiString(path)+'\'+AnsiString(dirName))) then
  result := CreateDir(AnsiString(path)+'\'+AnsiString(dirName));
 FreeMem(path);
 FreeMem(dirName);
end; // ForceDirectories


//------------------------------------------------------------------------------
// determines whether a specified directory exists.
//------------------------------------------------------------------------------
function TDIRManager.DirectoryExists(Name: AnsiString): Boolean;
var res: Integer;
    sr:  TSearchRec;
begin
 // if check for root folder - it always exists
 if ((Name = '\') or (Name = '/') or (Name = '.')) then
  begin
   result := true;
   exit;
  end;
//aaStartTime;
 if (Name[1] = '\') or (Name[1] = '/') then
  res := FDIR.FindFirst(Name,faDirectory,sr,rootID)
 else
  res := FDIR.FindFirst(Name,faDirectory,sr,currentDir);
 if ((res = 0) and ((faDirectory and sr.Attr) <> 0)) then
  Result := true
 else
  Result := false; 

//aaStopTime;
 FDIR.FindClose(sr);
end; // DirectoryExists



////////////////////////////////////////////////////////////////////////////////
//
//   TUserFilePageMapManager
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TUserFilePageMapManager.Create(PFMHandle1: TPageFileManager; FSMHandle1: TFreeSpaceManager);
begin
  PFMHandle := PFMHandle1; // page file manager
  FSMHandle := FSMHandle1; // free space manager

// memory optimization by Leo
// original:
  // pointers to UFPM map
//  UFPMMaps := TSortedPtrArray.Create(0,10,100);
  // pointers to file page map
//  UFMaps := TSortedPtrArray.Create(0,10,100);
// optimized:
  // pointers to UFPM map
  UFPMMaps := TSortedPtrArray.Create(0,10,25);
  // pointers to file page map
  UFMaps := TSortedPtrArray.Create(0,10,25);
  // how many user file pages are addressed by one map page
  PagesPerMapPage := PFMHandle.PageDataSize div sizeof(integer);
  // temp array
// memory optimization by Leo
// original:
//  TempPages := TIntegerArray.Create(0, 10, 1000);
// optimized:
  TempPages := TIntegerArray.Create(0, 10, 100);
end;// Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TUserFilePageMapManager.Destroy;
var
  i: integer;
begin
{$IFDEF DEBUG_FLAG}
WriteMemoryUsage;
{$ENDIF}
  for i:=0 to UFPMMaps.ItemCount-1 do
   if (UFPMMaps.ValueItems[i] <> nil) then
    TIntegerArray(UFPMMaps.ValueItems[i]).Free;
  UFPMMaps.Free;
  for i:=0 to UFMaps.ItemCount-1 do
   if (UFMaps.ValueItems[i] <> nil) then
    TIntegerArray(UFMaps.ValueItems[i]).Free;
  UFMaps.Free;
  TempPages.Free;
end;// Destroy


{$IFDEF DEBUG_FLAG}
procedure TUserFilePageMapManager.WriteMemoryUsage;
var z,x,y,x1,y1: cardinal;
    i: integer;
begin
 x := Length(UFMaps.KeyItems) * sizeof(Integer)+
      Length(UFMaps.ValueItems) * sizeof(Integer);
 aaWriteToLog('TUserFilePageMapManager.UFMaps = '+IntToStr(x));

 y := Length(UFPMMaps.KeyItems) * sizeof(Integer)+
      Length(UFPMMaps.ValueItems) * sizeof(Integer);
 aaWriteToLog('TUserFilePageMapManager.UFPMMaps = '+IntToStr(y));

 y1 := 0;
 for i:=0 to UFMaps.ItemCount-1 do
   if (UFMaps.ValueItems[i] <> nil) then
    inc(y1,Length(TIntegerArray(UFMaps.ValueItems[i]).Items) * sizeof (integer));
 x1 := 0;
 for i:=0 to UFPMMaps.ItemCount-1 do
   if (UFPMMaps.ValueItems[i] <> nil) then
    inc(x1,Length(TIntegerArray(UFPMMaps.ValueItems[i]).Items) * sizeof (integer));
 aaWriteToLog('TUserFilePageMapManager.UFPMMaps integer arrays = '+IntToStr(x1));
 aaWriteToLog('TUserFilePageMapManager.UFMaps integer arrays = '+IntToStr(y1));

 z := Length(TempPages.Items) * sizeof(integer);
 aaWriteToLog('TUserFilePageMapManager.TempPages = '+IntToStr(z));

 aaWriteToLog('TUserFilePageMapManager.Total = '+IntToStr((x+z+x1+y1+y) div 1024)+#13#10);
end;

{$ENDIF}

//------------------------------------------------------------------------------
// get quantity of pages covering specified size
//------------------------------------------------------------------------------
function TUserFilePageMapManager.GetCoverPageCount(Size: Int64): integer;
begin
     Result := Size div Int64(PFMHandle.PageDataSize);
     if ((Size mod Int64(PFMHandle.PageDataSize)) <> 0) then
      inc(Result);
end;// GetCoverPageCount


//------------------------------------------------------------------------------
// get file maps - find or load (file is indentified by FirstMapPageNo)
//------------------------------------------------------------------------------
procedure TUserFilePageMapManager.GetMaps(var FileRec: TDirectoryElement; var UFPMMap: TIntegerArray; var UFMap: TIntegerArray);
var
  FFPage: TFFPage;
  i, j, FilePageCount, FilePageNo, MapPageNo, MapPageCount: integer;
begin
  if (FileRec.FirstMapPageNo = None) then
   raise Exception.Create('TUserFilePageMapManager.GetMaps - Invalid parameter FileRec.FirstMapPageNo');

  // check for maps oferflow
  if (UFPMMaps.ItemCount > 100) then
   begin
    for i:=0 to UFPMMaps.ItemCount-1 do
     if (UFPMMaps.ValueItems[i] <> nil) then
      TIntegerArray(UFPMMaps.ValueItems[i]).Free;
    UFPMMaps.SetSize(0);
   end;
  if (UFMaps.ItemCount > 100) then
   begin
    for i:=0 to UFMaps.ItemCount-1 do
     if (UFMaps.ValueItems[i] <> nil) then
      TIntegerArray(UFMaps.ValueItems[i]).Free;
    UFMaps.SetSize(0);
   end;

  // try to find existing maps (UFPMMap, UFMap)
  UFPMMap := UFPMMaps.Find(FileRec.FirstMapPageNo);
  UFMap := UFMaps.Find(FileRec.FirstMapPageNo);
  // if not found - try to load
  if (UFPMMap = nil) then
   begin
    try
// memory optimization by Leo
// original:
//      UFPMMap := TIntegerArray.Create(0,10,1000);
//      UFMap := TIntegerArray.Create(0,10,1000);
// optimized:
      UFPMMap := TIntegerArray.Create(0,10,25);
      UFMap := TIntegerArray.Create(0,10,25);

      // allocate buffer for page
      PFMHandle.AllocPageBuffer(FFPage);
      // quantity of file pages
      FilePageCount := GetCoverPageCount(FileRec.FileSize);
      // quantity of map pages
      MapPageCount := FilePageCount div PagesPerMapPage;
      if ((FilePageCount mod PagesPerMapPage) <> 0) then
        Inc(MapPageCount);
      // starting from first map page No
      MapPageNo := FileRec.FirstMapPageNo;
      // load all map pages
      FilePageNo := 0;
      if (MapPageCount = 0) then
        UFPMMap.Append(MapPageNo)
      else
      for i := 0 to MapPageCount-1 do
       begin
        // read page
        if (not PFMHandle.ReadPage(FFPage, MapPageNo)) then
         raise Exception.Create('TUserFilePageMapManager.GetMaps - Error on reading map page.');
        // store map page No
        UFPMMap.Append(MapPageNo);
        // store file pages No
        for j := 0 to PagesPerMapPage-1 do
         begin
          if (FilePageNo < FilePageCount) then
           UFMap.Append(pInteger(PAnsiChar(FFPage.pData)+j*sizeof(integer))^);
          Inc(FilePageNo);
         end;
        // get No of next map page
        MapPageNo := FFPage.PageHeader.NextPageNo;
        if (FilePageNo < FilePageCount) and (MapPageNo = None) then
         raise Exception.Create('TUserFilePageMapManager.GetMaps - Invalid page No in map chain.');
       end;
      // add maps to global list of maps
      UFPMMaps.Insert(FileRec.FirstMapPageNo, UFPMMap);
      UFMaps.Insert(FileRec.FirstMapPageNo, UFMap);
      // free page buffer
      PFMHandle.FreePageBuffer(FFPage);
    except
      UFPMMap.Free;
      UFMap.Free;
      raise;
    end;
   end;
  if (UFPMMap = nil) then
    raise Exception.Create('TUserFilePageMapManager.GetMaps - Cannot find UFPM page map');
  if (UFMap = nil) then
    raise Exception.Create('TUserFilePageMapManager.GetMaps - Cannot find user file page map');
  if (UFPMMap.Items[0] <> FileRec.FirstMapPageNo) then
    raise Exception.Create('TUserFilePageMapManager.GetMaps - UFPMMap.Items[0] <> FirstMapPageNo');
end;// GetMaps


//------------------------------------------------------------------------------
// append pages to the end of file (file is indentified by FirstMapPageNo)
//------------------------------------------------------------------------------
function TUserFilePageMapManager.AppendPages(var FileRec: TDirectoryElement; PageCount: integer; bWriteAppendedPages: boolean): Boolean;
var
  MapPageCount: integer;
  i: integer;
  UFPMMap: TIntegerArray;
  UFMap: TIntegerArray;
  SaveItemNo, SaveItemCount: integer;
  pc, DesiredPageNo: integer;
  IsUniform: boolean;
  FFPage: TFFPage;
begin
  Result := True;
  if (PageCount <= 0) then
   raise Exception.Create('TUserFilePageMapManager.AppendPages - PageCount <= 0.');
  // is new file (no pages in map at all)
  if (FileRec.FirstMapPageNo = None) then
   begin
     // calc map pages count required for the appended pages
     MapPageCount := PageCount div PagesPerMapPage;
     if ((PageCount mod PagesPerMapPage) <> 0) then
      inc(MapPageCount);
     // allocate pages for map extension
// memory optimization by Leo
// orignial:
//     UFPMMap := TIntegerArray.Create(0,10,100);
// optimized:
     UFPMMap := TIntegerArray.Create(0,10,25);
     if (not FSMHandle.GetPages(MapPageCount, 1, false, UFPMMap)) then
      begin
       UFPMMap.Free;
//       raise Exception.Create('TUserFilePageMapManager.AppendPages - Not enough  free pages.');
       FLastError := erDiskFull;
       Result := False;
       Exit;
      end;
     // set first map page No
     FileRec.FirstMapPageNo := UFPMMap.Items[0];
     // add new UFPM page map
     UFPMMaps.Insert(FileRec.FirstMapPageNo, UFPMMap);
// memory optimization by Leo
// original:
//     UFMap := TIntegerArray.Create(0,100,1000);
// optimized:
     UFMap := TIntegerArray.Create(0,10,25);
     // add new user file page map
     UFMaps.Insert(FileRec.FirstMapPageNo, UFMap);
     // set what map pages will be saved
     SaveItemNo := 0;
     SaveItemCount := UFPMMap.ItemCount;
   end
  else
   begin
     // find or load maps
     GetMaps(FileRec,UFPMMap, UFMap);
     // calc count of additional required map pages
     pc := ((UFMap.ItemCount+PageCount) div PagesPerMapPage) - UFPMMap.ItemCount;
     if (((UFMap.ItemCount+PageCount) mod PagesPerMapPage) <> 0) then
      Inc(pc);
     if (pc > 0) then
      begin
       // allocate pages for map extension near the last map page
       if (not FSMHandle.GetPages(pc, UFPMMap.Items[UFPMMap.ItemCount-1]+1, false, TempPages)) then
//        raise Exception.Create('TUserFilePageMapManager.AppendPages - Not enough  free pages.');
        begin
         FLastError := erDiskFull;
         Result := False;
         Exit;
        end;
       // extend UFPM in memory
       for i:=0 to TempPages.ItemCount-1 do
        UFPMMap.Append(TempPages.Items[i]);
       // always save last map page (as it has link to the next page)
       SaveItemNo := UFPMMap.ItemCount-pc-1;
       SaveItemCount := pc+1;
      end
     else
      begin
        // no additional map pages required - save only last page
        SaveItemNo := UFPMMap.ItemCount-1;
        SaveItemCount := 1;
      end;
   end;

 // desired start page is next to the EOF page
 if (UFMap.ItemCount > 0) then
   DesiredPageNo := UFMap.Items[UFMap.ItemCount-1]+1
 else
   DesiredPageNo := 1;
 // allocate uniform extent?
 if (UFMap.ItemCount+PageCount > PFMHandle.FHeader.ExtentPageCount) then
  IsUniform := true
 else
  IsUniform := false;
 // allocate pages for user file map extension
 if (not FSMHandle.GetPages(PageCount, DesiredPageNo, IsUniform, TempPages)) then
//   raise Exception.Create('TUserFilePageMapManager.AppendPages - Not enough free pages to extend.');
  begin
    FLastError := erDiskFull;
    Result := False;
    Exit;
  end;
 // extend user file map in memory
 for i:=0 to TempPages.ItemCount-1 do
   UFMap.Append(TempPages.Items[i]);

 // save map pages
 SaveMapPages(SaveItemNo, SaveItemCount, UFPMMap, UFMap);

 // if specified - save empty headers for appended pages
 if (bWriteAppendedPages) then
  begin
   // allocate buffer for page
   PFMHandle.AllocPageBuffer(FFPage);
   FFPage.PageHeader.PageType := UFPage;
   FFPage.PageHeader.EncType := 0; // none
   FFPage.PageHeader.CrcType := 0; // fast
   // write appended pages with trash
   for i:=0 to TempPages.ItemCount-1 do
     PFMHandle.WritePage(FFPage, TempPages.Items[i]);
   // free page buffer
   PFMHandle.FreePageBuffer(FFPage);
  end;
end;// AppendPages


//------------------------------------------------------------------------------
// delete pages from the end of file (file is indentified by FirstMapPageNo)
//------------------------------------------------------------------------------
procedure TUserFilePageMapManager.DeletePagesFromEOF(var FileRec: TDirectoryElement; PageCount: integer);
var
  UFPMMap: TIntegerArray;
  UFMap: TIntegerArray;
  i, NewMapPageCount: integer;
begin
  if (FileRec.FirstMapPageNo = None) then
    raise Exception.Create('TUserFilePageMapManager.DeletePagesFromEOF - File map not exists.');

  // find or load maps
  GetMaps(FileRec,UFPMMap, UFMap);

  // get new map pages count
  NewMapPageCount := (UFMap.ItemCount-PageCount) div PagesPerMapPage;
  if ((UFMap.ItemCount-PageCount) mod PagesPerMapPage > 0) then
    Inc(NewMapPageCount);

  // init array of pages to free
  TempPages.SetSize(0);

  // if map pages count decreased
  if (NewMapPageCount < UFPMMap.ItemCount) then
   begin
    // fill map pages to free
    for i := NewMapPageCount to UFPMMap.ItemCount-1 do
     TempPages.Append(UFPMMap.Items[i]);
    // remove pages from memory array
    UFPMMap.SetSize(NewMapPageCount);
   end;

   //--- free user file pages ---
   // fill pages to free
   for i := UFMap.ItemCount-PageCount to UFMap.ItemCount-1 do
     TempPages.Append(UFMap.Items[i]);
   // remove pages from memory array
   UFMap.SetSize(UFMap.ItemCount-PageCount);

   // free pages
   FSMHandle.FreePages(TempPages);

  // save last map page if size > 0
  if (NewMapPageCount > 0) then
    SaveMapPages(NewMapPageCount-1,1, UFPMMap, UFMap)
  else
   begin
    // file becomes of zero size - delete maps
    UFPMMap.Free;
    UFMap.Free;
    UFPMMaps.Delete(FileRec.FirstMapPageNo);
    UFMaps.Delete(FileRec.FirstMapPageNo);
    FileRec.FirstMapPageNo := None;
   end;
end;// DeletePagesFromEOF


//------------------------------------------------------------------------------
// save UFPM pages
//------------------------------------------------------------------------------
procedure TUserFilePageMapManager.SaveMapPages(ItemNo, ItemCount: integer; UFPMMap, UFMap: TIntegerArray);
var
  i, UsedBytes: integer;
  FFPage: TFFPage;
begin
  // allocate buffer for page
  PFMHandle.AllocPageBuffer(FFPage);

  FFPage.PageHeader.PageType := UFPMPage;
  FFPage.PageHeader.EncType := 0; // none
  FFPage.PageHeader.CrcType := 0; // fast
  // save all map pages
  for i:=ItemNo to ItemNo+ItemCount-1 do
   begin
     if (i+1 < UFPMMap.ItemCount) then
      FFPage.PageHeader.NextPageNo := UFPMMap.Items[i+1]
     else
      FFPage.PageHeader.NextPageNo := -1;
     // copy data from TIntegerArray to FF page
     if ((i+1)*PagesPerMapPage <= UFMap.ItemCount) then
      UsedBytes := PagesPerMapPage*sizeof(integer)
     else
      UsedBytes := (UFMap.ItemCount-i*PagesPerMapPage)*sizeof(integer);
     Move(UFMap.Items[i*PagesPerMapPage], PAnsiChar(FFPage.pData)^, UsedBytes);
     // write page
     PFMHandle.WritePage(FFPage, UFPMMap.Items[i]);
   end;

  // free page buffer
  PFMHandle.FreePageBuffer(FFPage);
end;// SaveMapPages


//------------------------------------------------------------------------------
// get pages from file (FirstMapPageNo) starting from Offset to cover Size
// can allocate additional pages, returns list of FF pages
// FirstMapPageNo=-1 corresponds to the new created file
//------------------------------------------------------------------------------
function TUserFilePageMapManager.GetPages(var FileRec: TDirectoryElement; Offset, Size: Int64;
                     IsAllocateAllowed: boolean; var pages: TIntegerArray): Boolean;
var
  i, StartPageNo, EndPageNo: integer;
  UFPMMap,UFMap: TIntegerArray;
begin
  Result := True;
  //--- append if necessary ---
  // new file?
  if (FileRec.FirstMapPageNo = None) then
   begin
     // append pages allowed?
     if (IsAllocateAllowed) then
      begin
//       SetSize(FileRec, Offset, True);
//       SetSize(FileRec, Offset+Size, False);
       Result := SetSize(FileRec, Offset+Size, True);
       // find or load page maps
       if (Result) then
        GetMaps(FileRec, UFPMMap, UFMap);
      end;
   end
  else
   begin
    // find or load page maps
    GetMaps(FileRec, UFPMMap, UFMap);
   end;
   
  // if new size exceeds alocated pages summary size - append pages
  if ((Offset+Size > FileRec.FileSize) and (IsAllocateAllowed)) then
//       SetSize(FileRec, Offset+Size, False);
       Result := SetSize(FileRec, Offset+Size, True);

  if (not Result) then
   Exit;

  // clear pages parameter items
  pages.SetSize(0);
  // if file exists
  if (FileRec.FirstMapPageNo <> None) then
   begin
    StartPageNo := Offset div Int64(PFMHandle.PageDataSize);
    EndPageNo := (Offset+Size) div Int64(PFMHandle.PageDataSize);
    // build requested pages list
    i := StartPageNo;
    while ((i <= EndPageNo) and (i < UFMap.ItemCount)) do
     begin
      pages.Append(UFMap.Items[i]);
      inc(i);
     end;
   end;
end;// GetPages


//------------------------------------------------------------------------------
// set size of file
//------------------------------------------------------------------------------
function TUserFilePageMapManager.SetSize(var FileRec: TDirectoryElement; NewSize: Int64; bWriteAppendedPages: boolean=True): Boolean;
var
  AppendPageCount, DeletePageCount, NewPageCount: integer;
  UFPMMap,UFMap: TIntegerArray;
begin
  Result := True;
  //--- append if necessary ---
  // new file?
  if (FileRec.FirstMapPageNo = None) then
   begin
     if (NewSize <> 0) then
      begin
       AppendPageCount := GetCoverPageCount(NewSize);
       Result := AppendPages(FileRec, AppendPageCount, bWriteAppendedPages);
      end;
   end// zero size file
  else
   begin
    // find or load page maps
    GetMaps(FileRec, UFPMMap, UFMap);
    // new file page count
    NewPageCount := GetCoverPageCount(NewSize);
    // append or delete?
    if (NewSize > FileRec.FileSize) then
     begin
      // append
      AppendPageCount := NewPageCount - UFMap.ItemCount;
      if (AppendPageCount > 0) then
         Result := AppendPages(FileRec, AppendPageCount, bWriteAppendedPages);
     end
    else
    if (NewSize < FileRec.FileSize) then
     begin
      // delete
      DeletePageCount := UFMap.ItemCount - NewPageCount;
      if (DeletePageCount > 0) then
         DeletePagesFromEOF(FileRec, DeletePageCount);
     end;
   end;// non-empty file
end;// SetSize


//------------------------------------------------------------------------------
// checks if AnsiString matches pattern
//------------------------------------------------------------------------------
function IsStrMatchPattern(StrPtr: PAnsiChar; PatternPtr: PAnsiChar; bIgnoreCase:boolean = true): Boolean;
var i : integer;
    delta : byte;
begin
  if (StrComp(PatternPtr,WildCardAnyFile) = 0) then
       begin
         Result:=True;
         exit;
       end;
  repeat
      if (StrComp(PatternPtr,WildCardMultipleChar) = 0) then
       begin
         Result:=True;
         exit;
       end
      else if (StrPtr^=#0) and (PatternPtr^ <> #0) then
       begin
         Result:=False;
         exit;
       end
      else if (StrPtr^=#0) then
       begin
         Result:=True;
         exit;
       end
      else
         begin
           case PatternPtr^ of
            WildCardMultipleChar:
               begin
                for i:=0 to Length(StrPtr)-1 do
                 begin
                  if IsStrMatchPattern(StrPtr+i,PatternPtr+1,bIgnoreCase) then
                   begin
                    Result := True;
                    exit;
                   end;
                 end;
                Result := False;
                exit;
               end;
            WildCardSingleChar:
               begin
                inc(StrPtr);
                inc(PatternPtr);
               end;
            else
               begin
                delta := byte(abs(byte(StrPtr^)-byte(PatternPtr^)));
//                if (delta=0) or
//                   (delta=byte(abs(byte('A')-byte('a')))) and (bIgnoreCase) then
                if (delta = 0) or
                   ((delta = byte(abs(byte('A') - byte('a')))) and
                   (bIgnoreCase) and
                   ((byte(StrPtr^) and (byte(PatternPtr^)) >=byte('A')))) then
                 begin
                  inc(StrPtr);
                  inc(PatternPtr);
                 end
                else
                 begin
                  Result:=False;
                  exit;
                 end;
               end;
           end; // case
         end; // non-simple cases
  until false;
end;//IsStrMatchPattern


//------------------------------------------------------------------------------
// extracts path and pattern
//------------------------------------------------------------------------------
function ExtractPathAndPattern(InPath: PAnsiChar; var OutPath, Pattern: PAnsiChar): Boolean;
var i,k,len:  Integer;
begin
 Result := false;
 if (InPath = '') then
  Exit;
//aaStartTime;
 len := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}InPath);
 k := -1;
 for i := len-2 downto 0 do
  if (pAnsiChar(InPath+i)^ = '/') or (pAnsiChar(InPath+i)^ = '\') then
   begin
    k := i;
    break;
   end;
//aaStopTime;
 if (k < 0) then
  Exit;
 // check pattern
//aaStartTime;
 OutPath := AllocMem(k+2);
 Pattern := AllocMem(len-k);
 if (k = 0) then
  pAnsiChar(OutPath)^ := '\' // root path
//  pAnsiChar(OutPath)^ := #0
 else
  Move(pAnsiChar(InPath)^,OutPath^,k);
 if (pAnsiChar(InPath+len-1)^ = '/') or (pAnsiChar(InPath+len-1)^ = '\') then
  dec(len);
 Move(pAnsiChar(InPath+k+1)^,Pattern^,len-k-1);
 Result := true;
//aaStopTime;
end; // ExtractPathAndPattern

//------------------------------------------------------------------------------
// writes current time to filetime field in TDirectoryElement
//------------------------------------------------------------------------------
procedure SetCurrentTime(var fTime: TFileTime);
var dt: TDateTime;
    time: Integer;
begin
 dt := Now;
 time := DateTimeToFileDate(dt);
 DosDateTimeToFileTime(LongRec(time).Hi,LongRec(time).Lo,fTime);
 LocalFileTimeToFileTime(fTime,fTime);
end; //SetCurrentTime


//------------------------------------------------------------------------------
// writes filename and alternateFileName to TDirectoryElement
//------------------------------------------------------------------------------
procedure SetFileName(FileName: AnsiString; var el: TDirectoryElement);
var l: integer;
begin
 l := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}pAnsiChar(FileName));
 if (l > MAX_PATH) then
  l := MAX_PATH-1;
 Move(pAnsiChar(FileName)^,el.FileName,l);
 el.FileName[l] := #0;
// el.ShortFileName := '';
(*
 str := ExtractShortPathName(FileName);
 l := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}pAnsiChar(str));
 if (l > 14) then
  l := 14;
 Move(pAnsiChar(str)^,el.ShortFileName,l);
*)
end;

//------------------------------------------------------------------------------
//initialization of directory element
//------------------------------------------------------------------------------
procedure InitDirectoryElement(var el: TDirectoryElement);
begin
 FillChar(el,DirElementSize,$00);
end;


//------------------------------------------------------------------------------
// set bit in bit map
// bit = 1 if bSet = true, otherwise bit = 0
//------------------------------------------------------------------------------
procedure SetBit(BitMap: PAnsiChar; BitNo: Integer; bSet: Boolean);
var offset,segment: Integer;
begin
 segment := BitNo div 8;
 offset := BitNo Mod 8;
 if (bSet) then
  pByte(BitMap + segment)^ := pByte(BitMap + segment)^ or
   (1 shl offset)
 else
  pByte(BitMap + segment)^ := pByte(BitMap + segment)^ and
   (not (1 shl offset));
end; //SetBit


//------------------------------------------------------------------------------
// get bit from bitmap, returns true if bit = 1, otherwise returns false
//------------------------------------------------------------------------------
function GetBit(BitMap: PAnsiChar; BitNo: Integer): Boolean;
var offset,segment: Integer;
begin
 segment := BitNo div 8;
 offset := BitNo Mod 8;
 Result := (pByte(BitMap + segment)^ and
   (1 shl offset)) <> 0;
end; //GetBit


end.

