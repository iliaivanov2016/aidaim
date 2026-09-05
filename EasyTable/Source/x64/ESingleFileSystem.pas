//==============================================================================
// Product name: ESingleFileSystem
// Copyright 2001-2015 AidAim Software.
// Description:
//  Single file system.
// Version: 1.13
// Date: 06/20/2002
//==============================================================================

unit ESingleFileSystem;

{DEFINE FULL_VERSION}
{$DEFINE NAG_SCREEN}
{DEFINE DEBUG_FLAG}

interface
{$I ESFSVer.inc}

uses classes, sysutils, windows, dialogs,
     ESFSEngine,
     {$IFDEF NAG_SCREEN}
     Registry,
     {$ENDIF}
     {$IFDEF DEBUG_LOG}
     ESFSDebug,
     {$ENDIF}
     ESFSPassword;

{$IFDEF X64_ON}
const ESFS_X64 = true;
{$ELSE}
const ESFS_X64 = false;
{$ENDIF}

type
 TESingleFileSystem = class;

 TESFSCompressionLevel = (esfsNone, zlibFastest, zlibNormal, ppmNormal, ppmMax,
                         zlibMax, ppmFastest, bzipFastest, bzipNormal, bzipMax);

 TESFSOverwriteMode = (omAlways,omNever,omPrompt);

{$IFDEF FULL_VERSION}
  // user file stream
  TESFSUserFileStream = class(TStream)
  private
    FESFSHandle: TESingleFileSystem;
    FFileName:  AnsiString;
    FOnProgress:    TESFSNoCancelProgressEvent; // progress for bulk operations
    // returns true if stream is encrypted
    function GetEncrypted: Boolean;
    // on progress
    procedure DoOnProgress(Progress : Real);
  protected
    FHandle: Integer;
    procedure SetSize(NewSize: LongInt);
    {$IFDEF D6H}
      overload;
    {$ENDIF}
      override;
    {$IFDEF D6H}
    procedure SetSize(const NewSize: Int64); overload; override;
    {$ENDIF}
  public
    constructor Create(
           ESingleFileSystem: TESingleFileSystem;
    			 const FileName: AnsiString; Mode: Word;
           Password: AnsiString = '';
           Question: AnsiString = '';
           Answer: AnsiString = ''
           );
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: LongInt; Origin: Word): Integer;
    {$IFDEF D6H}
            overload;
    {$ENDIF}
      override;
    {$IFDEF D6H}
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; overload; override;
    {$ENDIF}
    procedure SaveToStream(Stream: TStream);
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToFile(const FileName: AnsiString);
    procedure LoadFromFile(const FileName: AnsiString);
    property Handle: Integer read FHandle;
   public
    // Progress Event
    property OnProgress : TESFSNoCancelProgressEvent read FOnProgress write FOnProgress;
    // file system
    property ESFSHandle: TESingleFileSystem read FESFSHandle;
    // file name
    property FileName: AnsiString read FFileName;
    // encrypted
    property Encrypted: Boolean read GetEncrypted;
  end;

 // ESFS file stream supporing compression
 TESFSAdvancedFileStream = class(TStream)
 private
    FBlockSize:			Integer;
    FProgress:      Extended;
    FProgressMax:   Extended;
    headers:        TESFSHeadersArray;
    FTrueSize:      Int64;
    FPackedSize:    Int64;
    FCurrentHeader: Integer;
    FCurrentPos:    Int64;
    FCompressionLevel: TESFSCompressionLevel;
    FOnProgress:    TESFSNoCancelProgressEvent; // progress for bulk operations
    FCompressionRate: Real;
    FNoProgress:    Boolean;
    FFileName:      AnsiString;
    FESFSHandle:     TObject; // TESingleFileSystem
    // true for ESFS 2.60 and lower
    FIsESFSRelativeOffsets: Boolean;
 protected
    FFile:          TESFSUserFileStream;
    FHeader:        TESFSFileStreamHeader;
    // returns true if stream is encrypted
    function GetEncrypted: Boolean;
    // returns ESFSHandle
    function GetESFSHandle: TESingleFileSystem;
   // sets new size of the stream
    procedure SetSize(NewSize: Longint);
    {$IFDEF D6H}
      overload;
    {$ENDIF}
      override;
    {$IFDEF D6H}
    procedure SetSize(const NewSize: Int64); overload; override;
    {$ENDIF}
    // gets FFile.size
    function GetPackedSize: Integer;
    // returns compression rate (100.0 if there is no compression)
    function GetCompressionRate: Real;
 private
    // on progress
    procedure DoOnProgress(Progress : Real);
    // calculates rate
    procedure CalculateRate;
    // create
    procedure InternalCreate(bCreate: Boolean);
    // returns handle
    function GetHandle: Integer;
 private
    // load all headers
    procedure LoadHeaders;
    // save stream header
    procedure SaveHeader;
   // prepares buffer for writing (compresses, fills header structure, calculates crc)
    procedure PrepareBufferForWriting(inBuf: PAnsiChar; inSize: Integer;
                         var outBuf: PAnsiChar; var hdr: TESFSHeader);
    // load block from file, decompress it and checks crc
    procedure LoadBlock(curHeader: Integer;
                        var outBuf: PAnsiChar);
 public
    // if compressionLevel not specified, ESFS.CompressionLevel will be used
    constructor Create(
						           ESingleFileSystem: TESingleFileSystem;
					  	  			 const FileName: AnsiString; Mode: Word;
						           Password: AnsiString = '';
						           Question: AnsiString = '';
						           Answer: AnsiString = '';
                       compressLevel: TESFSCompressionLevel = esfsNone
                       );
    // destructor
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint;
    {$IFDEF D6H}
            overload;
    {$ENDIF}
      override;
    {$IFDEF D6H}
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; overload; override;
    {$ENDIF}
    procedure SaveToStream(Stream: TStream);
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToFile(const FileName: AnsiString);
    procedure LoadFromFile(const FileName: AnsiString);
   public
    // Progress Event
    property OnProgress : TESFSNoCancelProgressEvent read FOnProgress write FOnProgress;
    // compression rate = 1 - [compressed size] / [decompressed size] * 100%
    // example: compressed size = 350 bytes, decompressed size = 1000,
    //          CompressionRate = 35.0;
    property CompressionRate: Real read GetCompressionRate;
    // compression level
    property CompressionLevel: TESFSCompressionLevel read FCompressionLevel;
    // Packed size
    property PackedSize: Integer read GetPackedSize;
    // handle
    property Handle: Integer read GetHandle;
    // ESFSHandle
    property ESFSHandle: TESingleFileSystem read GetESFSHandle;
    // file name
    property FileName: AnsiString read FFileName;
    // encrypted
    property Encrypted: Boolean read GetEncrypted;
end; //TESFSAdvancedFileStream

 TESFSFileStream = class(TStream)
 private
  	cStream:        TESFSAdvancedFileStream;
    FOnProgress:    TESFSNoCancelProgressEvent; // progress for bulk operations
    FMode:          Word;
    FFileName:      AnsiString;
    FPassword:      AnsiString;
    bReadOnly:      Boolean;
    // returns Handle
    function GetHandle: Integer;
    // returns ESFSHandle
    function GetESFSHandle: TESingleFileSystem;
    // returns compression level
    function GetCompressionLevel: TESFSCompressionLevel;
    // changes compression level, counts progress
    procedure SetCompressionLevel(newCompressLevel: TESFSCompressionLevel);
   public
    // sets new encryption mode
    // if newPassword = '' then encryption will be removed
    procedure ChangeEncryption(
                              newPassword: AnsiString = '';
                              newQuestion: AnsiString = '';
                              newAnswer: AnsiString = ''
                              );
   private
	  // returns packed size
    function GetPackedSize: Integer;
    // returns compression rate (100.0 if there is no compression)
    function GetCompressionRate: Real;
    // returns true if stream is encrypted
    function GetEncrypted: Boolean;
 protected
    // sets new size of the stream
    procedure SetSize(NewSize: Longint);
    {$IFDEF D6H}
      overload;
    {$ENDIF}
      override;
    {$IFDEF D6H}
    procedure SetSize(const NewSize: Int64); overload; override;
    {$ENDIF}
 public
    // if compressionLevel not specified, ESFS.CompressionLevel will be used
    constructor Create(
						           ESingleFileSystem: TESingleFileSystem;
					  	  			 const FileName: AnsiString; Mode: Word;
						           Password: AnsiString = '';
						           Question: AnsiString = '';
						           Answer: AnsiString = '';
                       compressLevel: TESFSCompressionLevel = esfsNone
                       );
    // destructor
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; 
    {$IFDEF D6H}
            overload;
    {$ENDIF}
      override;
    {$IFDEF D6H}
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; overload; override;
    {$ENDIF}
    procedure SaveToStream(Stream: TStream);
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToFile(const FileName: AnsiString);
    procedure LoadFromFile(const FileName: AnsiString);
 public
     // Progress Event
    property OnProgress : TESFSNoCancelProgressEvent read FOnProgress write FOnProgress;
    // compression rate = [compressed size] / [decompressed size] * 100%
    // example: compressed size = 350 bytes, decompressed size = 1000,
    //          CompressionRate = 35.0;
    property CompressionRate: Real read GetCompressionRate;
    // compression level
    property CompressionLevel: TESFSCompressionLevel read GetCompressionLevel
    					write SetCompressionLevel;
    // Packed size
    property PackedSize: Integer read GetPackedSize;
    // file name
    property FileName: AnsiString read FFileName;
    // encrypted
    property Encrypted: Boolean read GetEncrypted;
    // password
    property Password: AnsiString read FPassword;
    // ESFSHandle
    property ESFSHandle: TESingleFileSystem read GetESFSHandle;
    // Handle
    property Handle: Integer read GetHandle;
 end;

{$ENDIF}

 // Single file system
 TESingleFileSystem = class(TObject)
 protected
  PFMHandle:            TPageFileManager; // page file manager
  DMHandle:             TDIRManager; // directory manager
  FSMHandle:            TFreeSpaceManager; // free space manager
  UFMHandle:            TUserFilePageMapManager; // page file manager
  FFileHandles:         TSortedPtrArray; // dynamic array of handles to opened files in Single file
  FReadOnly:            Boolean;
  FExclusive:           Boolean;
  FCancel:    		      Boolean;
  FPassword:						AnsiString;
  FFileName:            AnsiString;
  FOpenMode:            Word;
  FIsESFSRelativeOffsets:   Boolean;
 // get password header
  function GetPasswordHeader(FileName: AnsiString; var passHeader: TPasswordHeader): Boolean;
  // set password header
  procedure SetPasswordHeader(FileName: AnsiString; passHeader: TPasswordHeader);
  // returns encrypted
  function GetEncrypted: Boolean;
  // returns control question
  function PGetControlQuestion: AnsiString;
 private
  FProgress:          Extended;
  FProgressMax:       Extended;
  FOnProgress:        TESFSProgressEvent; // progress for bulk operations
  FOnFileProgress:    TESFSFileProgressEvent; // progress for bulk operations for current file
  FOnOverwritePrompt: TESFSOverwritePromptEvent; // overwrite prompt
  FOnDiskFull:        TESFSDiskFullEvent; // not enough space
  FOnPassword:        TESFSOnPasswordEvent; // occurs when password needed

	FInMemory:			Boolean;
{$IFDEF FULL_VERSION}
  FCurrentFileName:   AnsiString;
{$ENDIF}
  // closes all opened files
  procedure CloseAllFiles;
  // create all internal objects
  procedure InternalCreate;

  // on progress
  procedure DoOnProgress(Progress : Real);
  // not enough space
  procedure DoOnDiskFull(
                         Sender: TObject
                        );
  // occurs when password needed
  procedure DoOnPassword(
                           FileName: AnsiString;
                           var NewPassword: AnsiString;
                           var SkipFile: Boolean
  );
{$IFDEF FULL_VERSION}
  // on overwrite prompt
  procedure DoOnOverwritePrompt(
            ExistingFileName,
            NewFileName: AnsiString;
            var bOverwrite: Boolean);

  // file progress
  procedure DoOnFileProgress(
                              Sender: TObject;
                              PercentDone:  Real
                             		);
  // reloads all data from disk
  procedure InternalReopen(Stream: TStream);
  // sets current dir
  procedure PSetCurrentDir(const Dir: AnsiString);
  // returns default compression level
  function GetCompressionLevel: TESFSCompressionLevel;
  // sets default compression level
  procedure SetCompressionLevel(newLevel: TESFSCompressionLevel);
{$ENDIF}
  // sets in-memory or disk mode
  procedure SetInMemory(value: boolean);
 public
  FLastError:						Integer;
  property IsESFSRelativeOffsets: Boolean read FIsESFSRelativeOffsets;

  // default constructor
  constructor Create(FileName: AnsiString; Mode: Word;
  						Password: AnsiString = '';
  						Question: AnsiString = '';
   						Answer: AnsiString = '';
              DefaultCompressionLevel: TESFSCompressionLevel = esfsNone
             ); overload;
  // advanced constructor
  constructor Create(FileName: AnsiString; Mode: Word;
              InMemoryMode: Boolean;
   						Password: AnsiString = '';
  						Question: AnsiString = '';
  						Answer: AnsiString = '';
              DefaultCompressionLevel: TESFSCompressionLevel = esfsNone;
              PageSize: Integer = DEFAULT_PAGE_SIZE;
              ExtentPageCount: Integer = DEFAULT_EXTENT_PAGE_COUNT;
              PartFileSize: Int64 = -1
              ); overload;

  // destructor
  destructor Destroy; override;
  //--------------------- SingleFile specific interface --------------------------
  // repairs file, returns true if repair is successful
  // if some errors were found, source file will have same name + '.bak'
  // if result = false then source file is unchanged, repair failed
  // if DeleteCorruptedFiles = true it means that all files with errors will be deleted,
  // otherwise they will be rewritten with correct CRC, but with damaged data
  function InternalRepair(
                          var log: AnsiString; DeleteCorruptedFiles: Boolean = false;
                          ChangeEncryption: Boolean = false;
                          newPassword: AnsiString = '';
                          newQuestion: AnsiString = '';
                          newAnswer: AnsiString = ''
                          ): Boolean;
  // public repair
  function Repair(var log: AnsiString; DeleteCorruptedFiles: Boolean = false): Boolean;
  //--------------------- user interface for files -----------------------------
  // returns true and restores password if control answer is valid
  function RestorePasswordByControlAnswer(FileName: AnsiString; Answer: AnsiString; var Password: AnsiString): Boolean;
  // returns true if Single file password is valid
  function IsPasswordValid(FileName: AnsiString; Password: AnsiString): Boolean;
  // returns control question
  function GetControlQuestion(FileName: AnsiString): AnsiString;

  // returns true if file is encrypted by its own password
  function IsFileEncrypted(FileName: AnsiString): boolean;

  // creates file
  function FileCreate(const FileName: AnsiString;
						 Password: AnsiString = '';
						 Question: AnsiString = '';
						 Answer: AnsiString = ''
             ): Integer;
  // open file
  function FileOpen(const FileName: AnsiString; Mode: LongWord;
						 Password: AnsiString = '';
						 Question: AnsiString = '';
						 Answer: AnsiString = ''
             ): Integer;
  // file close
  procedure FileClose(Handle: Integer);
  // read from file
  function FileRead(Handle: Integer; var Buffer; Count: Integer): Integer;
  // write to file
  function FileWrite(Handle: Integer; const Buffer; Count: Integer): Integer;
  // seek in file
  function FileSeek(Handle: Integer; const Offset: Int64; Origin: Integer): Int64;
  // flsuh file buffers
  procedure FlushFileBuffers(Handle: Integer);
  // sets file size
  function FileSetSize(Handle: Integer; Size: Int64): Int64;
  // delete file
  function DeleteFile(const FileName: AnsiString): Boolean;
  // rename file
  function RenameFile(const OldName, NewName: AnsiString): Boolean;
{$IFDEF FULL_VERSION}
  // copy file
  function CopyFile(const OldName, NewName: AnsiString; Password: AnsiString = ''): Boolean;
  // move file
  function MoveFile(const OldName, NewName: AnsiString; Password: AnsiString = ''): Boolean;
{$ENDIF}
  // is file exists
  function FileExists(const FileName: AnsiString): Boolean;
  // returns file attributes
  function FileGetAttr(const FileName: AnsiString): Integer;
  // set attributes, FileSetAttr returns zero if the function was successful.
  function FileSetAttr(const FileName: AnsiString; Attr: Integer): Integer;
  // Returns the date-and-time stamp of a specified file.
  function FileAge(const FileName: AnsiString): Integer;
  // Returns a DOS date-time stamp for a specified file.
  function FileGetDate(Handle: Integer): Integer;
  // Sets the DOS time stamp for a specified file.
  function FileSetDate(Handle: Integer; Age: Integer): Integer;
 public
   // find file by pattern using '*', '?'
   function FindFirst(const Path: AnsiString; Attr: Integer; var F: TSearchRec): Integer;
   function FindNext(var F: TSearchRec): Integer;
   procedure FindClose(var F: TSearchRec);
   // sets new encryption mode
   // if newPassword = '' then encryption will be removed
   function ChangeEncryption(
                              newPassword: AnsiString = '';
                              newQuestion: AnsiString = '';
                              newAnswer: AnsiString = ''
                              ): Boolean;
{$IFDEF FULL_VERSION}
   function ChangeFilesEncryption(
                              FileMask: AnsiString;
                              oldPassword: AnsiString = '';
                              newPassword: AnsiString = '';
                              newQuestion: AnsiString = '';
                              newAnswer: AnsiString = ''
                              ): Boolean;
{$ENDIF}
  //--------------------- user interface for folders -----------------------------
   // returns size of Single file
   function DiskSize: Int64;
{$IFDEF FULL_VERSION}
   // returns current directory name ('\' if root directory )
   function GetCurrentDir: AnsiString;
   // return value set to True if directory successfully changed
   function SetCurrentDir(const Dir: AnsiString): Boolean;
   // removes directory
   function RemoveDir(const Dir: AnsiString): Boolean;
   // creates directory
   function CreateDir(const Dir: AnsiString): Boolean;
   // returns free space in Single file
   function DiskFree: Int64;
   // imports files from SourcePath to DestPath
   // SourcePath allows to use wildcards * and ?
   // returns number of files imported
   function ImportFiles(
                         SourcePath:    AnsiString;
                         DestPath:      AnsiString = ''; // current dir
                         Attr:          Integer = faAnyFile;
                         bRecursive:    Boolean = true;
                         OverwriteMode: TESFSOverwriteMode = omPrompt;
                         EncryptFiles:  Boolean = False
                         ): Integer;
   // imports folder with all its content from SourcePath to DestPath
   // returns number of files imported
   function ImportFolder(
                         SourcePath:    AnsiString;
                         DestPath:      AnsiString = ''; // current dir
                         bRecursive:    Boolean = true;
                         OverwriteMode: TESFSOverwriteMode = omPrompt;
                         EncryptFiles:  Boolean = False
                         ): Integer;
   // exports files from SourcePath to current DestPath
   // SourcePath allows to use wildcards * and ?
   // returns number of files exported
   function ExportFiles(
                         SourcePath:    AnsiString;
                         DestPath:      AnsiString = ''; // current dir
                         Attr:          Integer = faAnyFile;
                         bRecursive:    Boolean = true;
                         OverwriteMode: TESFSOverwriteMode = omPrompt
                         ): Integer;
   // exports folder with all its content to DestPath
   // returns number of files exported
   function ExportFolder(
                         SourcePath:    AnsiString;
                         DestPath:      AnsiString = ''; // current dir
                         bRecursive:    Boolean = true;
                         OverwriteMode: TESFSOverwriteMode = omPrompt
                         ): Integer;
   // returns true if directory is empty
   function IsFolderEmpty(Dir: AnsiString): Boolean;
   // deletes files from Path to current DestPath
   // Path allows to use wildcards * and ?
   // returns number of files deleted
   function DeleteFiles(
                         Path:    AnsiString;
                         Attr:    Integer = faAnyFile;
                         bRecursive: Boolean = true
                        ): Integer;
   // deletes folder with all its content to DestPath
   // returns number of files exported
   function DeleteFolder(
                         Dir:    AnsiString
                         ): Integer;

   // runs application stored inside the ESFS file
   function RunApplication(FileName: AnsiString; Parameters: String='';
                           Directory: String='';
                           ShowCmd: Integer=SW_SHOWNORMAL): Boolean;

   // runs application stored inside the ESFS file
   function LoadLibrary(FileName: AnsiString): Integer;

   procedure LoadFromStream(Stream: TStream);
   procedure LoadFromFile(const FileName: AnsiString);
{$ENDIF}
   procedure SaveToStream(Stream: TStream);
   procedure SaveToFile(const FileName: AnsiString);

 protected
{$IFDEF FULL_VERSION}
 public
{$ENDIF}
   // Creates all the directories along a directory path if they do not already exist
   function ForceDirectories(Dir: AnsiString): Boolean;
   // determines whether a specified directory exists.
   function DirectoryExists(Name: AnsiString): Boolean;
 public
   // Progress Event for current file
   property OnFileProgress : TESFSFileProgressEvent read FOnFileProgress write FOnFileProgress;
   // Progress Event
   property OnProgress : TESFSProgressEvent read FOnProgress write FOnProgress;
   // overwrite prompt
   property OnOverwritePrompt : TESFSOverwritePromptEvent read FOnOverwritePrompt write FOnOverwritePrompt;
   // disk full
   property OnDiskFull: TESFSDiskFullEvent read FOnDiskFull write FOnDiskFull;
   // On password needed Event
   property OnPassword: TESFSOnPasswordEvent read FOnPassword write FOnPassword;
   // Ecnrypted;
   property Encrypted: Boolean read GetEncrypted;
   // password;
   property Password: AnsiString read FPassword;
   // control question;
   property ControlQuestion: AnsiString read PGetControlQuestion;
{$IFDEF FULL_VERSION}
   // file size
   property Size: Int64 read DiskSize;
{$ENDIF}
   // in memory mode
   property InMemory: Boolean read FInMemory write SetInMemory;
{$IFDEF FULL_VERSION}
   // file name
   property FileName: AnsiString read FFileName;
   // current directory
   property CurrentDir: AnsiString read GetCurrentDir write PSetCurrentDir;
   // default compression level
   property DefaultCompressionLevel: TESFSCompressionLevel read GetCompressionLevel
   					write SetCompressionLevel;
{$ENDIF}
 end;// TESingleFileSystem



 //----------------------- ESFS control routines -----------------------
 // rename esfs files
 function RenameESFS(const OldName, NewName: AnsiString): Boolean;
 // copy esfs files
 function CopyESFS(const OldName, NewName: AnsiString): Boolean;
 // delete esfs files
 function DeleteESFS(const FileName: AnsiString): Boolean;
 // returns true if this file is a ESFS file
 function IsESFSFile(const FileName: AnsiString): Boolean;
 // makes SFX from ESFS file
 procedure MakeSFX(ESFSFileName, SFXStubFileName, SFXFileName: AnsiString);

 //----------------------- single file encryption routines -----------------------
 // returns true and restores password if control answer is valid
 function RestorePasswordByControlAnswer(FileName: AnsiString; Answer: AnsiString; var Password: AnsiString): Boolean;
 // returns true if Single file password is valid
 function IsPasswordValid(FileName: AnsiString; Password: AnsiString): Boolean;
 // returns control question
 function GetControlQuestion(FileName: AnsiString): AnsiString;
 // returns true if file is encrypted by its own password
 function IsSingleFileEncrypted(FileName: AnsiString): boolean;
 // returns temporary directory
 function GetTemporaryDirectory: AnsiString;


implementation



uses
{$IFDEF FULL_VERSION}
ESFSCompress,
{$ENDIF}
ESFSFileCtrl;

{$IFDEF FULL_VERSION}
Function ShellExecute(hWnd:HWND;lpOperation:PAnsiChar;lpFile:PAnsiChar;lpParameter:PAnsiChar;
                      lpDirectory:PAnsiChar;nShowCmd:Integer):Thandle; Stdcall;
External 'Shell32.Dll' name 'ShellExecuteA';



{$IFDEF D5H}

function aaIncludeTrailingBackslash(const S: AnsiString): AnsiString;
begin
  Result := SysUtils.IncludeTrailingBackslash(s);
end;

function aaExcludeTrailingBackslash(const S: AnsiString): AnsiString;
begin
  Result := SysUtils.ExcludeTrailingBackslash(s);
end;

{$ELSE}

function aaIncludeTrailingBackslash(const S: AnsiString): AnsiString;
begin
  Result := S;
  if not IsPathDelimiter(Result, Length(Result)) then Result := Result + '\';
end;

function aaExcludeTrailingBackslash(const S: AnsiString): AnsiString;
begin
  Result := S;
  if IsPathDelimiter(Result, Length(Result)) then
    SetLength(Result, Length(Result)-1);
end;

{$ENDIF}

{$IFDEF D6H}
function aaDirectoryExists(const Name: AnsiString): Boolean;
begin
 result := SysUtils.DirectoryExists(Name);
end;

function aaForceDirectories(Dir: AnsiString): Boolean;
begin
 result := SysUtils.ForceDirectories(Dir);
end;
{$ELSE}
function aaDirectoryExists(const Name: AnsiString): Boolean;
var
  Code: Integer;
begin
  Code := GetFileAttributes(PAnsiChar(Name));
  Result := (Code <> -1) and (FILE_ATTRIBUTE_DIRECTORY and Code <> 0);
end;


function aaForceDirectories(Dir: AnsiString): Boolean;
begin
  Result := True;
  if Length(Dir) = 0 then
    raise Exception.Create('Unable to create directory');
  Dir := aaExcludeTrailingBackslash(Dir);
  if (Length(Dir) < 3) or aaDirectoryExists(Dir)
    or (ExtractFilePath(Dir) = Dir) then Exit; // avoid 'xyz:\' problem.
  Result := aaForceDirectories(ExtractFilePath(Dir)) and CreateDir(Dir);
end;

{$ENDIF}

////////////////////////////////////////////////////////////////////////////////
//
//   TESFSUserFileStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// returns true if stream is encrypted
//------------------------------------------------------------------------------
function TESFSUserFileStream.GetEncrypted: Boolean;
begin
 result := FESFSHandle.IsFileEncrypted(FFileName);
end;


//------------------------------------------------------------------------------
// on progress
//------------------------------------------------------------------------------
procedure TESFSUserFileStream.DoOnProgress(Progress : Real);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Self,Progress);
end; // on progress


//------------------------------------------------------------------------------
// set size
//------------------------------------------------------------------------------
procedure TESFSUserFileStream.SetSize(NewSize: LongInt);
begin
 ESFSHandle.FileSetSize(FHandle,NewSize);
end; //


{$IFDEF D6H}
procedure TESFSUserFileStream.SetSize(const NewSize: Int64);
begin
 ESFSHandle.FileSetSize(FHandle,NewSize);
end; //
{$ENDIF}


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TESFSUserFileStream.Create(ESingleFileSystem: TESingleFileSystem;
    			 const FileName: AnsiString; Mode: Word;
           Password: AnsiString = '';
           Question: AnsiString = '';
           Answer: AnsiString = ''
            );
begin
 FFileName := FileName;
 if (ESingleFileSystem = nil) then
  raise Exception.Create('TESFSUserFileStream.Create - Single file system = nil!');
 FESFSHandle := ESingleFileSystem;
{$IFDEF ENCRYPTION_ON}
 FHandle := ESFSHandle.FileOpen(FileName,Mode,Password,Question,Answer);
{$ELSE}
 FHandle := ESFSHandle.FileOpen(FileName,Mode,'','','');
{$ENDIF}
 if (FHandle <= None) then
  raise Exception.Create('TESFSUserFileStream.Create - unable to open file '+
  	AnsiQuotedStr(FileName,'"'));
end; //


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TESFSUserFileStream.Destroy;
begin
 ESFSHandle.FileClose(FHandle);
 inherited Destroy;
end; //


//------------------------------------------------------------------------------
// read
//------------------------------------------------------------------------------
function TESFSUserFileStream.Read(var Buffer; Count: Longint): Longint;
begin
 result := ESFSHandle.FileRead(FHandle,Buffer,Count);
end; //


//------------------------------------------------------------------------------
// write
//------------------------------------------------------------------------------
function TESFSUserFileStream.Write(const Buffer; Count: Longint): Longint;
begin
 result := ESFSHandle.FileWrite(FHandle,Buffer,Count);
end; //


//------------------------------------------------------------------------------
// seek
//------------------------------------------------------------------------------
function TESFSUserFileStream.Seek(Offset: LongInt; Origin: Word): Integer;
begin
 result := ESFSHandle.FileSeek(FHandle,Offset,Origin);
end; //

{$IFDEF D6H}
function TESFSUserFileStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
 result := ESFSHandle.FileSeek(FHandle,Offset,Integer(Origin));
end; //
{$ENDIF}

procedure TESFSUserFileStream.SaveToStream(Stream: TStream);
var outBytes,oldPos,oldPos1,inSize:	Int64;
    outSize:					Integer;
    buf:            	PAnsiChar;
    FProgress:      	Extended;
    FProgressMax:   	Extended;
begin
 oldPos := Position;
 oldPos1 := Stream.Position;
 Position := 0;
 outBytes := 0;
 DoOnProgress(0);
 inSize := Size;
 buf := AllocMem(DefaultMaxBlockSize);
 while outBytes < inSize do
  begin
   if (inSize - outBytes > DefaultMaxBlockSize) then
    outSize := DefaultMaxBlockSize
   else
    outSize := Size - outBytes;
   ReadBuffer(buf^,outSize);
   Stream.WriteBuffer(buf^,outSize);
   outBytes := outBytes + outSize;
   FProgressMax := Size;
   FProgress := outBytes;
   DoOnProgress(FProgress/FProgressMax*100.0);
  end;
 FreeMem(buf);
 Position := oldPos;
 Stream.Position := oldPos1;
 DoOnProgress(100.0);
end; // SaveToStream


procedure TESFSUserFileStream.LoadFromStream(Stream: TStream);
var oldPos,oldPos1:	Int64;
    outSize:					Integer;
    buf:            	PAnsiChar;
    FProgress:      	Extended;
    FProgressMax:   	Extended;
begin
 oldPos := Position;
 oldPos1 := Stream.Position;
 Stream.Position := 0;
 Size := 0;
 Position := 0;
 DoOnProgress(0);
 buf := AllocMem(DefaultMaxBlockSize);
 while Stream.Position < Stream.Size do
  begin
   if (Stream.Size - Stream.Position > DefaultMaxBlockSize) then
    outSize := DefaultMaxBlockSize
   else
    outSize := Stream.Size - Stream.Position;
   Stream.ReadBuffer(buf^,outSize);
   WriteBuffer(buf^,outSize);
   FProgressMax := Stream.Size;
   FProgress := Stream.Position;
   DoOnProgress(FProgress/FProgressMax*100.0);
  end;
 FreeMem(buf);
 Position := oldPos;
 Stream.Position := oldPos1;
 DoOnProgress(100.0);
end; // LoadFromStream


procedure TESFSUserFileStream.SaveToFile(const FileName: AnsiString);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
end; //SaveToFile


procedure TESFSUserFileStream.LoadFromFile(const FileName: AnsiString);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, sysUtils.fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end; //LoadFromFile


////////////////////////////////////////////////////////////////////////////////
//
//   TESFSAdvancedFileStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// returns true if stream is encrypted
//------------------------------------------------------------------------------
function TESFSAdvancedFileStream.GetEncrypted: Boolean;
begin
{$IFDEF ENCRYPTION_ON}
  Result := FFile.Encrypted;
{$ELSE}
  Result := ''
{$ENDIF}
end;


//------------------------------------------------------------------------------
// returns ESFSHandle
//------------------------------------------------------------------------------
function TESFSAdvancedFileStream.GetESFSHandle: TESingleFileSystem;
begin
 result := FFile.ESFSHandle;
end;


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
procedure TESFSAdvancedFileStream.SetSize(NewSize: Longint);
var buf,outBuf:           PAnsiChar;
    extSize:              Int64;
    curHdr,numBlocks:     Integer;
begin
 if (FCompressionLevel = esfsNone) then
  begin
   FFile.Size := NewSize;
   Exit;
  end;
 if (newSize = FTrueSize) then
   Exit
 else
  if (newSize > FTrueSize) then
   begin
    Seek(0,soFromEnd);
    extSize := NewSize - FTrueSize;
    buf := AllocMem(extSize);
    FNoProgress := true;
    if (Write(buf^,extSize) <> extSize) then
     begin
      FNoProgress := false;
      FreeMem(buf);
      raise Exception.Create('TESFSAdvancedFileStream.SetSize - error extending file. '+
        'NewSize = '+inttostr(newSize)+
        ', extSize = '+inttostr(extSize)
        );
     end;
    FNoProgress := false;
    FreeMem(buf);
   end // newSize > Size - extend
  else
   begin
    // cutting file
    // extSize < 0
    curHdr := NewSize div FHeader.blockSize;
    numBlocks := curHdr;
    extSize := NewSize mod FHeader.blockSize;
    if (extSize > 0) then
     begin
      inc(numBlocks);
      LoadBlock(curHdr,buf);
      PrepareBufferForWriting(buf,extSize,outBuf,headers.Items[curHdr]);
      FreeMem(buf);
     end;
    FHeader.NumBlocks := numBlocks;
    headers.SetSize(numBlocks);
    SaveHeader;
    if (extSize > 0) then
     begin
      FFile.Size := headers.Positions[curHdr];
      FFile.Seek(0,soFromEnd);
      if (FIsESFSRelativeOffsets) then
       begin
        // >= 2.70
        headers.Items[curHdr].nextHeaderNo :=
          Integer(headers.Items[curHdr].packedSize) + ESFSCompressedHeaderSize;
       end
      else
       begin
        // <= 2.60
        headers.Items[curHdr].nextHeaderNo := FFile.Position +
          Integer(headers.Items[curHdr].packedSize) + ESFSCompressedHeaderSize;
       end;
      headers.Positions[curHdr] := FFile.Position;
      FFile.WriteBuffer(headers.Items[curHdr], ESFSCompressedHeaderSize);
      FFile.WriteBuffer(outBuf^,headers.Items[curHdr].packedSize);
      FreeMem(outBuf);
     end;
    FTrueSize := NewSize;
    if (FCurrentPos > FTrueSize) then
     Seek(0,soFromEnd);
    CalculateRate;
   end; // newSize < Size - cut
end; // SetSize


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
{$IFDEF D6H}
procedure TESFSAdvancedFileStream.SetSize(const NewSize: Int64);
var buf,outBuf:           PAnsiChar;
    extSize:              Int64;
    curHdr:               Integer;
begin
 if (FCompressionLevel = esfsNone) then
  begin
   FFile.Size := NewSize;
   Exit;
  end;
 if (newSize = FTrueSize) then
   Exit
 else
  if (newSize > FTrueSize) then
   begin
    Seek(0,soFromEnd);
    extSize := NewSize - FTrueSize;
    buf := AllocMem(extSize);
    FNoProgress := true;
    if (Write(buf^,extSize) <> extSize) then
     begin
      FNoProgress := false;
      FreeMem(buf);
      raise Exception.Create('TESFSAdvancedFileStream.SetSize - error extending file. '+
        'NewSize = '+inttostr(newSize)+
        ', extSize = '+inttostr(extSize)
        );
     end;
    FNoProgress := false;
    FreeMem(buf);
   end // newSize > Size - extend
  else
   begin
    // cutting file
    // extSize < 0
    curHdr := NewSize div FHeader.blockSize;
    extSize := NewSize mod FHeader.blockSize;
    if (extSize > 0) then
     begin
      LoadBlock(curHdr,buf);
      PrepareBufferForWriting(buf,extSize,outBuf,headers.Items[curHdr]);
      FreeMem(buf);
     end;
    headers.SetSize(curHdr+1);
    FHeader.NumBlocks := curHdr+1;
    SaveHeader;
    FFile.Size := headers.Positions[curHdr];
    FFile.Seek(0,soFromEnd);
    if (extSize > 0) then
     begin
      headers.Items[curHdr].nextHeaderNo := FFile.Position +
        Integer(headers.Items[curHdr].packedSize) + ESFSCompressedHeaderSize;
      headers.Positions[curHdr] := FFile.Position;
      FFile.WriteBuffer(headers.Items[curHdr], ESFSCompressedHeaderSize);
      FFile.WriteBuffer(outBuf^,headers.Items[curHdr].packedSize);
      FreeMem(outBuf);
     end;
    FTrueSize := NewSize;
    if (FCurrentPos > FTrueSize) then
     Seek(0,soFromEnd);
    CalculateRate;
   end; // newSize < Size - cut
end; // SetSize
{$ENDIF}


//------------------------------------------------------------------------------
// gets FFile.size
//------------------------------------------------------------------------------
function TESFSAdvancedFileStream.GetPackedSize: Integer;
begin
  result := FFile.Size;
end; // GetPackedSize


//------------------------------------------------------------------------------
// returns compression rate (100.0 if there is no compression)
//------------------------------------------------------------------------------
function TESFSAdvancedFileStream.GetCompressionRate: Real;
begin
 CalculateRate;
 Result := FCompressionRate;
end;


//------------------------------------------------------------------------------
// on progress
//------------------------------------------------------------------------------
procedure TESFSAdvancedFileStream.DoOnProgress(Progress : Real);
begin
  if Assigned(FOnProgress) and (not FNoProgress) then
    FOnProgress(Self,Progress);
end; // on progress


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
procedure TESFSAdvancedFileStream.CalculateRate;
var i: 		Integer;
    f,f1:	Extended;
begin
 FPackedSize := 0;
 for i := 0 to headers.ItemCount-1 do
  FPackedSize := FPackedSize + headers.Items[i].packedSize;
 f1 := FTrueSize;
 f := FPackedSize;
 if (FCompressionLevel = esfsNone) then
  begin
   FPackedSize := FTrueSize;
   FCompressionRate := 0;
   FHeader.BlockSize := DefaultMaxBlockSize;
   Exit;
  end;
 if (FTrueSize <= 0) then
  begin
   FPackedSize := FTrueSize;
   FCompressionRate := 0;
   Exit;
  end;
 FCompressionRate := (1 - f / f1) * 100.0;
end; //CalculateRate


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
procedure TESFSAdvancedFileStream.InternalCreate(bCreate: Boolean);
begin
 FBlockSize := DefaultMaxBlockSize;
 FNoProgress := false;
 FTrueSize := FFile.Size;
 FFile.Position := 0;

 headers := TESFSHeadersArray.Create;
 if (bCreate) and (FCompressionLevel = esfsNone) then
  Exit;
 if (bCreate) then
  begin
   FHeader.signature := ESFSStreamSignature;
   FHeader.BlockSize := ESFSInternalGetBlockSize(TESFSCompressionLevel1(FCompressionLevel));
   FHeader.NumBlocks := 0;
   FHeader.version := ESFSCompressCurrentVersion;
   FHeader.CompressionLevel := Byte(FCompressionLevel);
   FHeader.CrcMode := 0;
   FHeader.CrcMode := 0;
   FFile.Seek(0,soFromBeginning);
   if (FFile.Write(FHeader,sizeof(FHeader)) <> sizeof(FHeader)) then
    raise Exception.Create('TESFSAdvancedFileStream.Create - error writing to data stream. May be data stream in read only mode.');
   FFile.Size := sizeof(FHeader);
  end;
 FFile.Position := 0;
 FTrueSize := 0;
// FCompressionLevel := esfsNone;
 LoadHeaders; // loading headers
// FCompressionLevel := TESFSCompressionLevel(FHeader.CompressionLevel);
 FCurrentHeader := 0;
 FCurrentPos := 0;
 FNoProgress := false;
 FFile.Position := 0;
end;


//------------------------------------------------------------------------------
// returns handle
//------------------------------------------------------------------------------
function TESFSAdvancedFileStream.GetHandle: Integer;
begin
 result := FFile.Handle;
end;


//------------------------------------------------------------------------------
// load block headers
//------------------------------------------------------------------------------
procedure TESFSAdvancedFileStream.LoadHeaders;
var cHeader:  TESFSHeader;
    pos:      Int64;
    oldPos:		Int64;
    i:        Integer;
begin
 oldPos := FFile.Position;
 FPackedSize := 0;
 FFile.Seek(0,soFrombeginning);
 if (FFile.Size < sizeof(FHeader)) then
  begin
   FTrueSize := FFile.Size;
   FFile.Position := oldPos;
   FCompressionLevel := esfsNone;
   CalculateRate;
   Exit;
  end;
 FFile.ReadBuffer(FHeader,sizeof(FHeader));
 if (FHeader.signature <> ESFSStreamSignature) then
  begin
   FTrueSize := FFile.Size;
   FFile.Position := oldPos;
   FCompressionLevel := esfsNone;
   CalculateRate;
   Exit;
  end;
// FFile.Seek(FHeader.CustomHeaderSize,soFromCurrent);
 FFile.Position := FFile.Position + FHeader.CustomHeaderSize;
{
 if (FHeader.version - 0.001 > ESFSCompressCurrentVersion) then
  raise Exception.Create('TESFSAdvancedFileStream.LoadHeaders - invalid stream version, currentVersion = '+
        FloatToStr(ESFSCompressCurrentVersion)+
        ', FHeader.version = '+
        FloatToStr(FHeader.version));
}
 headers.SetSize(0);
 FCompressionLevel := TESFSCompressionLevel(FHeader.CompressionLevel);
 FTrueSize := 0;

 for i:= 0 to FHeader.NumBlocks-1 do
  begin
   pos := FFile.Position;
   if (FFile.Size - FFile.Position < ESFSCompressedHeaderSize) then
    begin
     // cut compressed file (end of file was cut)
     // repair this error
     FFile.Size := FFile.Position;
     FHeader.NumBlocks := i;
     headers.SetSize(i);
     SaveHeader;
     break;
    end;
   FFile.ReadBuffer(cHeader,ESFSCompressedHeaderSize);
   FTrueSize := FTrueSize + cHeader.trueSize;
   FPackedSize := FPackedSize + cHeader.packedSize;
   headers.AppendItem(cHeader,pos);
//   FFile.Seek(cHeader.nextHeaderNo, soFromBeginning)
   if (FIsESFSRelativeOffsets) then
     begin
      // >= 2.70
       FFile.Position := pos + Int64(cHeader.nextHeaderNo);
     end
   else
     begin
      // <= 2.60
       FFile.Position := cHeader.nextHeaderNo;
     end;
  end;
 FFile.Position := oldPos;
 FBlockSize := FHeader.BlockSize;
 CalculateRate;
end; //LoadHeaders


//------------------------------------------------------------------------------
// save stream header
//------------------------------------------------------------------------------
procedure TESFSAdvancedFileStream.SaveHeader;
begin
 FFile.Seek(0,soFromBeginning);
 FFile.WriteBuffer(FHeader,sizeof(FHeader));
end; //SaveHeader


//------------------------------------------------------------------------------
// prepare buffer for writing
//------------------------------------------------------------------------------
procedure TESFSAdvancedFileStream.PrepareBufferForWriting(inBuf: PAnsiChar; inSize: Integer;
                         var outBuf: PAnsiChar; var hdr: TESFSHeader);
begin
  outBuf := nil;
  hdr.trueSize := inSize;
  hdr.crc32 := CountCRC(inBuf,LongWord(inSize),crcFull);
  if (not ESFSInternalCompressBuffer(inBuf,inSize,outBuf,
          Integer(hdr.packedSize),TESFSCompressionLevel1(FCompressionLevel))) then
   begin
    if (outBuf <> nil) then
     FreeMem(outBuf);
    raise Exception.Create('TESFSAdvancedFileStream.PrepareBufferForWriting - compression error in PrepareBuffer.');
   end;
end; //PrepareBuffer;


//------------------------------------------------------------------------------
// load block from file, decompress it and checks crc
//------------------------------------------------------------------------------
procedure TESFSAdvancedFileStream.LoadBlock(curHeader: Integer;
                                      var outBuf: PAnsiChar);

var size,rSize,pSize: Cardinal;
    inBuf:            pAnsiChar;
begin
   pSize := headers.Items[curHeader].packedSize;
   inBuf := AllocMem(pSize);
   if (inBuf = nil) then
    Exit;
//   FFile.Seek(headers.Positions[curHeader]
//      +ESFSCompressedHeaderSize,soFromBeginning);
   FFile.Position := headers.Positions[curHeader] + Int64(ESFSCompressedHeaderSize);
   rSize := Cardinal(FFile.Read(inBuf^,pSize));
   if (rSize <> Integer(pSize)) then
    begin
     FreeMem(inBuf);
     raise Exception.Create('TESFSAdvancedFileStream.LoadBlock - block read error. rSize = '+IntToStr(rSize)+', pSize = '+IntToStr(pSize));
     Exit;
    end;

   size := headers.Items[curHeader].trueSize;
   if (not ESFSInternalDecompressBuffer(inBuf,pSize,outBuf,Integer(size),
            TESFSCompressionLevel1(FCompressionLevel))) then
    begin
     // decompression error
     FreeMem(inBuf);
     raise Exception.Create('TESFSAdvancedFileStream.LoadBlock - decompression error.');
    end;
   if (headers.Items[curHeader].trueSize <> size) then
    begin
     FreeMem(inBuf);
     FreeMem(outBuf);
     raise Exception.Create('TESFSAdvancedFileStream.LoadBlock - decompression error, invalid size.');
    end;
   // check crc
   if (headers.Items[curHeader].crc32 <>
        CountCRC(pAnsiChar(outBuf),LongWord(size),crcFull)) then
    begin
    // decompression crc error
     FreeMem(inBuf);
     FreeMem(outBuf);
     raise Exception.Create('TESFSAdvancedFileStream.LoadBlock - decompression crc error.');
    end;
 FreeMem(inBuf);
end;


//------------------------------------------------------------------------------
// to create new compressed stream pass bCreate = true to constructor
//------------------------------------------------------------------------------
constructor TESFSAdvancedFileStream.Create(
						           ESingleFileSystem: TESingleFileSystem;
					  	  			 const FileName: AnsiString; Mode: Word;
						           Password: AnsiString = '';
						           Question: AnsiString = '';
						           Answer: AnsiString = '';
                       compressLevel: TESFSCompressionLevel = esfsNone
                       );
begin
 FESFSHandle := ESingleFileSystem;
 // true for ESFS 2.60 and lower
 FIsESFSRelativeOffsets := ESingleFileSystem.IsESFSRelativeOffsets;
 FFileName := FileName;
 if (ESingleFileSystem = nil) then
  raise Exception.Create('TESFSAdvancedFileStream.Create - ESingleFileSystem = nil.');
{$IFDEF ENCRYPTION_ON}
 FFile := TESFSUserFileStream.Create(ESingleFileSystem,FileName,Mode,
 					Password,Question,Answer);
{$ELSE}
 FFile := TESFSUserFileStream.Create(ESingleFileSystem,FileName,Mode,
 					'','','');
{$ENDIF}
 if (FFile = nil) then
    raise Exception.Create('TESFSAdvancedFileStream.Create - error creating user file stream, fileName = '+
    	AnsiQuotedStr(FileName,'"')+'.');
 FCompressionLevel := compressLevel;
 if (FCompressionLevel = esfsNone) then
    FCompressionLevel := ESingleFileSystem.DefaultCompressionLevel;
   InternalCreate(mode = fmCreate);
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TESFSAdvancedFileStream.Destroy;
begin
 FFile.Free;
 headers.Free;
 FESFSHandle := nil;
end; // Destroy


//------------------------------------------------------------------------------
// read from compressed stream
//------------------------------------------------------------------------------
function TESFSAdvancedFileStream.Read(var Buffer; Count: Longint): Longint;
var size:   Int64;
    outBuf: PAnsiChar;
begin
 DoOnProgress(0);
 if (FCompressionLevel = esfsNone) then
  begin
   result := FFile.Read(Buffer,Count);
   DoOnProgress(100.0);
   Exit;
  end;
 Result := 0;
 FProgress := 0;
 // invalid operation - read from not existing position beyond end of the file
 if (FCurrentPos > FTrueSize) then
  Exit;
 if (FCurrentPos < FTrueSize) then
  FCurrentHeader := FCurrentPos div FHeader.BlockSize;

 FProgressMax := headers.ItemCount - FCurrentHeader;
 while (FCurrentPos < FTrueSize) and (Result < Count) do
  begin
   DoOnProgress(FProgress);
   LoadBlock(FCurrentHeader,outBuf);
   size := FHeader.blockSize - ((FCurrentPos + FHeader.blockSize) mod Integer(FHeader.blockSize));
   if (Result + size > Count) then
    size := Count - Result;
//bug fix: loading only till EOF
   if (FCurrentPos + size >= FTrueSize) then
    size := FTrueSize-FCurrentPos;
//bugs
   Move(pAnsiChar(outBuf+((FCurrentPos + FHeader.blockSize) mod FHeader.blockSize))^,
        pAnsiChar(pAnsiChar(@Buffer)+Result)^,size);
   FreeMem(outBuf);
   inc(Result,Size);
   if (Result < Count) then
    inc(FCurrentHeader);
   FCurrentPos := FCurrentPos + Size;
   FProgress := FProgress + 100.0 / FProgressMax;
  end;
 DoOnProgress(100.0);
end; // Read


//------------------------------------------------------------------------------
// write to compressed stream
//------------------------------------------------------------------------------
function TESFSAdvancedFileStream.Write(const Buffer; Count: Longint): Longint;
var startHeaderNo, endHeaderNo, startPos, endPos:     Int64;
    oldLastHeaderNo, pSize,  curPos: Int64;
    i, j, d, offset, sPos, tSize:    Integer;
    dd:                              Int64;
    packedBuffers:                   TList;
    buf,outBuf:                      pAnsiChar;
    bRewriteEnd:                     Boolean;
begin
 DoOnProgress(0);
 if (FCompressionLevel = esfsNone) then
  begin
   result := FFile.Write(Buffer,Count);
   DoOnProgress(100.0);
   Exit;
  end;
 Result := 0;
 if (Count <= 0) then
  Exit;
 // write beyond end of the file
 if (FCurrentPos > FTrueSize) then
  begin
   dd := FCurrentPos;
   Position := 0;
   SetSize(dd);
   Position := dd;
   if (FCurrentPos <> dd) then
     Exit;
  end;

 // intializing variables
 packedBuffers := TList.Create;
 startPos := FCurrentPos;
 endPos := FCurrentPos + Count - 1;
 startHeaderNo := Integer(Int64(startPos) div Int64(FHeader.blockSize));
 endHeaderNo := Integer(Int64(endPos) div Int64(FHeader.blockSize));
 oldLastHeaderNo := headers.ItemCount-1;
 bRewriteEnd := false;
 if (endHeaderNo > oldLastHeaderNo) then
  begin
   bRewriteEnd := true;
   headers.SetSize(endHeaderNo+1);
  end;
 // changed in 2.70
 if (startHeaderNo = 0) then
  headers.Positions[0] := ESFSFileStreamHeaderSize + FHeader.CustomHeaderSize;
 FProgress := 0;
 FProgressMax := (headers.ItemCount - FCurrentHeader) ;
 curPos := FCurrentPos;
 if (FCurrentPos + Count > FTrueSize) then
  begin
   FTrueSize := FCurrentPos + Count;
  end;
 FCurrentPos := FCurrentPos + Count;
 // i = current header number
 i := startHeaderNo;
 // read buffers, otherwrite data if it is needed
 // and prepare compressed buffers for writing
 // after this loop i will be equal to number of last prepared header
 while (i <= headers.ItemCount-1)  do
  begin
   if ((not bRewriteEnd) and (i > endHeaderNo)) then
    break;
   DoOnProgress(FProgress);
   if (bRewriteEnd and (i <= oldLastHeaderNo)) or ((not bRewriteEnd) and (i <= endHeaderNo))  then
    begin
     // read old data
     LoadBlock(i,buf);
     ReallocMem(buf,FHeader.blockSize);
    end
   else
    begin
     // prepare new block
     buf := AllocMem(FHeader.blockSize);
    end;
   // move part of user buffer to current block
   if (i <= endHeaderNo) then
    begin
     // calculate start position
     sPos := Integer(Int64(curPos + Int64(FHeader.blockSize)) mod
                     Int64(FHeader.blockSize));
     if (i = endHeaderNo) then
      tSize := Integer(Integer(Int64(endPos) mod Int64(FHeader.blockSize)) - (sPos-1))
     else
      tSize := FHeader.blockSize - sPos;
     offset := Integer(curPos - startPos);
     Move(PAnsiChar(PAnsiChar(@Buffer) + offset)^,PAnsiChar(buf+sPos)^,tSize);
    end;
   // backup old packed size
   pSize := headers.Items[i].packedSize;
   // calcaulate true size of new block
   if (i = headers.itemCount-1) then
    begin
     if (FTrueSize mod FHeader.blockSize > 0) then
      headers.Items[i].trueSize := FTrueSize mod FHeader.blockSize
     else
      headers.Items[i].trueSize := FHeader.blockSize;
    end
   else
    begin
     headers.Items[i].trueSize := FHeader.blockSize;
    end;
   // pack user buffer
   PrepareBufferForWriting(buf,headers.Items[i].trueSize,outBuf,headers.Items[i]);
   packedBuffers.Add(outBuf);
   // this is a pointer to the end of last block in stream
   if (not FIsESFSRelativeOffsets) then
    if (i = headers.itemCount-1) then
     begin
      // <= 2.60
      if (i = 0) then
        // changed in 2.70
        headers.Items[i].nextHeaderNo := headers.Positions[0] +
          headers.Items[i].packedSize + ESFSCompressedHeaderSize
      else
        headers.Items[i].nextHeaderNo := headers.Items[i-1].nextHeaderNo +
          headers.Items[i].packedSize + ESFSCompressedHeaderSize;
     end;

   FreeMem(buf);
   if (pSize < Integer(headers.Items[i].packedSize)) then
    begin
     bRewriteEnd := true;
    end;
   if (FIsESFSRelativeOffsets) then
    begin
     // >= 2.70
     if (bRewriteEnd) then
      headers.Items[i].nextHeaderNo := headers.Items[i].packedSize +
        ESFSCompressedHeaderSize;
     if (i > 0) then
      headers.Positions[i] := headers.Positions[i-1] +
        Int64(headers.Items[i-1].nextHeaderNo);
    end
   else
    begin
     // <= 2.60
     if (bRewriteEnd) and (i < headers.ItemCount-1) then
      begin
         if (i > 0) then
          headers.Items[i].nextHeaderNo := headers.Items[i-1].nextHeaderNo
            + headers.Items[i].packedSize+ESFSCompressedHeaderSize
         else
          headers.Items[i].nextHeaderNo := headers.Positions[0]
            + headers.Items[i].packedSize+ESFSCompressedHeaderSize;
      end;
    end;
   inc(i);
   curPos := Int64(i) * Int64(FHeader.blockSize);
   FProgress := FProgress + 100.0 / FProgressMax;
  end;
 dec(i);
 // update positions
 // <= 2.60
 if (not FIsESFSRelativeOffsets) then
   if (bRewriteEnd) then
    for d := 1 to headers.ItemCount -1 do
      headers.Positions[d] := headers.Items[d-1].nextHeaderNo;
 // write prepared buffers to disk
 d := 0;
 for j := startHeaderNo to i do
  begin
   DoOnProgress(FProgress);
//   FFile.Seek(headers.Positions[j],soFromBeginning);
   FFile.Position := headers.Positions[j];
   FFile.WriteBuffer(headers.Items[j], ESFSCompressedHeaderSize);
   FFile.WriteBuffer(pAnsiChar(packedBuffers.Items[d])^,headers.Items[j].packedSize);
   inc(d);
  end;
 // save header
 FHeader.NumBlocks := headers.ItemCount;
 SaveHeader;
 // free memory

 while (packedBuffers.Count > 0) do
  begin
   FreeMem(packedBuffers.Items[0]);
   packedBuffers.Items[0] := nil;
   packedBuffers.Remove(packedBuffers.Items[0]);
  end;
 packedBuffers.Free;
 Result := Count;

 CalculateRate;
 DoOnProgress(100.0);
end; // Write


//------------------------------------------------------------------------------
// seek in compressed stream
//------------------------------------------------------------------------------
function TESFSAdvancedFileStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
 if (FCompressionLevel = esfsNone) then
  begin
   result := FFile.Seek(Offset,Origin);
   Exit;
  end;
 case Origin of
  soFromBeginning: FCurrentPos := Offset;
  soFromEnd: FCurrentPos := FTrueSize + Offset;
  soFromCurrent: FCurrentPos := FCurrentPos + Offset;
 end;
 if (FCurrentPos <= 0)  then
  begin
   FCurrentPos := 0;
   FCurrentHeader := 0;
  end
 else
  begin
   if (FTrueSize = 0) then
    FCurrentHeader := 0
   else
    FCurrentHeader := headers.FindPosition(FCurrentPos);
  end;
 result := FCurrentPos;
end; // Seek


{$IFDEF D6H}
function TESFSAdvancedFileStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
 if (FCompressionLevel = esfsNone) then
  begin
   result := FFile.Seek(Offset,Origin);
   Exit;
  end;
 case Origin of
  soBeginning: FCurrentPos := Offset;
  soEnd: FCurrentPos := FTrueSize + Offset;
  soCurrent: FCurrentPos := FCurrentPos + Offset;
 end;
 if (FCurrentPos <= 0)  then
  begin
   FCurrentPos := 0;
   FCurrentHeader := 0;
  end
 else
  begin
   if (FTrueSize = 0) then
    FCurrentHeader := 0
   else
    FCurrentHeader := headers.FindPosition(FCurrentPos);
  end;
 result := FCurrentPos;
end; // Seek
{$ENDIF}

procedure TESFSAdvancedFileStream.SaveToStream(Stream: TStream);
var outBytes,oldPos,oldPos1,inSize:	Int64;
    outSize:					Integer;
    buf:            	PAnsiChar;
    FProgress:      	Extended;
    FProgressMax:   	Extended;
begin
 oldPos := Position;
 oldPos1 := Stream.Position;
 Position := 0;
 outBytes := 0;
 FNoProgress := false;
 DoOnProgress(0);
 inSize := Size;
 buf := AllocMem(FBlockSize);
 try
   while outBytes < inSize do
    begin
     if ((inSize - outBytes) > Int64(FBlockSize)) then
      outSize := FBlockSize
     else
      outSize := inSize - outBytes;
     FNoProgress := true;
     ReadBuffer(buf^,outSize);
     Stream.WriteBuffer(buf^,outSize);
     FNoProgress := false;
     outBytes := outBytes + outSize;
     FProgressMax := Size;
     FProgress := outBytes;
     DoOnProgress(FProgress/FProgressMax*100.0);
    end;
 finally
  FreeMem(buf);
 end;
 Position := oldPos;
 Stream.Position := oldPos1;
 DoOnProgress(100.0);
end; // SaveToStream


procedure TESFSAdvancedFileStream.LoadFromStream(Stream: TStream);
var oldPos,oldPos1:	Int64;
    outSize:					Integer;
    buf:            	PAnsiChar;
    FProgress:      	Extended;
    FProgressMax:   	Extended;
begin
 oldPos := Position;
 oldPos1 := Stream.Position;
 Stream.Position := 0;
 Size := 0;
 Position := 0;
 FNoProgress := false;
 DoOnProgress(0);
 buf := AllocMem(FBlockSize);
 while Stream.Position < Stream.Size do
  begin
   if (Stream.Size - Stream.Position > FBlockSize) then
    outSize := FBlockSize
   else
    outSize := Stream.Size - Stream.Position;
   FNoProgress := true;
   Stream.ReadBuffer(buf^,outSize);
   WriteBuffer(buf^,outSize);
   FNoProgress := false;
   FProgressMax := Stream.Size;
   FProgress := Stream.Position;
   DoOnProgress(FProgress/FProgressMax*100.0);
  end;
 FreeMem(buf);
 Position := oldPos;
 Stream.Position := oldPos1;
 DoOnProgress(100.0);
end; // LoadFromStream


procedure TESFSAdvancedFileStream.SaveToFile(const FileName: AnsiString);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
end;


procedure TESFSAdvancedFileStream.LoadFromFile(const FileName: AnsiString);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, sysUtils.fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;


////////////////////////////////////////////////////////////////////////////////
//
//   TESFSFileStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// returns Handle
//------------------------------------------------------------------------------
function TESFSFileStream.GetHandle: Integer;
begin
 result := cStream.Handle;
end;


//------------------------------------------------------------------------------
// returns ESFSHandle
//------------------------------------------------------------------------------
function TESFSFileStream.GetESFSHandle: TESingleFileSystem;
begin
 result := cStream.ESFSHandle;
end;


//------------------------------------------------------------------------------
// returns compression level
//------------------------------------------------------------------------------
function TESFSFileStream.GetCompressionLevel: TESFSCompressionLevel;
begin
  result := cStream.CompressionLevel;
end;


//------------------------------------------------------------------------------
// changes compression level, counts progress
//------------------------------------------------------------------------------
procedure TESFSFileStream.SetCompressionLevel(newCompressLevel: TESFSCompressionLevel);
var
    cs:         TESFSAdvancedFileStream;
    esfs:        TESingleFileSystem;
    attr:       word;
    passHeader: TPasswordHeader;
begin
  esfs := cStream.ESFSHandle;
 	if (newCompressLevel = CompressionLevel) then
  	Exit;
 	if (FMode = sysUtils.fmOpenRead) then
  	Exit;
  // change compression mode
  cStream.Free;
  // save file attributes
  attr := esfs.FileGetAttr(FFileName);
  // save file password header
  if (not esfs.GetPasswordHeader(FFileName,passHeader)) then
   raise Exception.Create('TESFSFileStream.SetCompressionLevel - can not retreive password header. Probably file does not exists.'+
   'File name = "'+FFileName+'"');
  esfs.RenameFile(FFileName,FFileName+'.bak');
  cs := TESFSAdvancedFileStream.Create(esfs,FFileName+'.bak',SysUtils.fmOpenRead,
        FPassword);
  cStream := TESFSAdvancedFileStream.Create(esfs,FFileName,fmCreate,
              FPassword,'','',newCompressLevel);
  cStream.Free;
  // restore old password header
  esfs.SetPasswordHeader(FFileName,passHeader);
  // restore file attributes
  esfs.FileSetAttr(FFileName,attr);
  cStream := TESFSAdvancedFileStream.Create(esfs,FFileName,fmOpenWrite,FPassword);
  cStream.OnProgress := FOnProgress;
  cStream.LoadFromStream(cs);
  cs.Free;
  cStream.Free;
  cStream := TESFSAdvancedFileStream.Create(esfs,FFileName,FMode,FPassword);
	esfs.DeleteFile(FFileName+'.bak');
end; // SetCompressionLevel


//------------------------------------------------------------------------------
// sets new encryption mode
// if newPassword = '' then encryption will be removed
//------------------------------------------------------------------------------
procedure TESFSFileStream.ChangeEncryption(
                              newPassword: AnsiString = '';
                              newQuestion: AnsiString = '';
                              newAnswer: AnsiString = ''
                              );
var
    cs:         TESFSAdvancedFileStream;
    esfs:        TESingleFileSystem;
    attr:       word;
    CompressLevel:  TESFSCompressionLevel;
begin
{$IFNDEF ENCRYPTION_ON}
Exit;
{$ENDIF}
  esfs := cStream.ESFSHandle;
 	if (FMode = sysUtils.fmOpenRead) then
  	Exit;
  // save compression level
  CompressLevel := cStream.CompressionLevel;
  // change compression mode
  cStream.Free;
  // save file attributes
  attr := esfs.FileGetAttr(FFileName);
  esfs.RenameFile(FFileName,FFileName+'.bak');
  cs := TESFSAdvancedFileStream.Create(esfs,FFileName+'.bak',SysUtils.fmOpenRead,
        FPassword);
  // creating new file
  cStream := TESFSAdvancedFileStream.Create(esfs,FFileName,fmCreate,
              newPassword,newQuestion,newAnswer,CompressLevel);
  cStream.Free;
  FPassword := newPassword;
  // restore file attributes
  esfs.FileSetAttr(FFileName,attr);
  // reopening new file
  cStream := TESFSAdvancedFileStream.Create(esfs,FFileName,fmOpenWrite,newPassword);
  cStream.OnProgress := FOnProgress;
  cStream.LoadFromStream(cs);
  cs.Free;
  cStream.Free;
  cStream := TESFSAdvancedFileStream.Create(esfs,FFileName,FMode,FPassword);
	esfs.DeleteFile(FFileName+'.bak');
end; // SetEncrypted


//------------------------------------------------------------------------------
// returns packed size
//------------------------------------------------------------------------------
function TESFSFileStream.GetPackedSize: Integer;
begin
 Result := cStream.PackedSize;
end; //GetPackedSize


//------------------------------------------------------------------------------
// returns compression rate (100.0 if there is no compression)
//------------------------------------------------------------------------------
function TESFSFileStream.GetCompressionRate: Real;
begin
  Result := cStream.CompressionRate;
end; // GetCompressionRate


//------------------------------------------------------------------------------
// returns true if stream is encrypted
//------------------------------------------------------------------------------
function TESFSFileStream.GetEncrypted: Boolean;
begin
{$IFDEF ENCRYPTION_ON}
 Result := cStream.Encrypted;
{$ELSE}
 Result := False;
{$ENDIF}
end; //GetEncrypted


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TESFSFileStream.SetSize(NewSize: Longint);
begin
 if (bReadOnly) then
  raise Exception.Create('TESFSFileStream.SetSize - file is in read only mode.');
 cStream.Size := NewSize;
end;


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
{$IFDEF D6H}
procedure TESFSFileStream.SetSize(const NewSize: Int64);
begin
 if (bReadOnly) then
  raise Exception.Create('TESFSFileStream.SetSize - file is in read only mode.');
 cStream.Size := NewSize;
end;
{$ENDIF}


//------------------------------------------------------------------------------
// if compressionLevel not specified, ESFS.CompressionLevel will be used
//------------------------------------------------------------------------------
constructor TESFSFileStream.Create(
						           ESingleFileSystem: TESingleFileSystem;
					  	  			 const FileName: AnsiString; Mode: Word;
						           Password: AnsiString = '';
						           Question: AnsiString = '';
						           Answer: AnsiString = '';
                       compressLevel: TESFSCompressionLevel = esfsNone
                       );
begin
 FFileName := FileName;
 bReadOnly := false;
 if (Mode <> fmCreate) and (Mode and $0003 = 0) then
 	bReadOnly := true;
{$IFDEF ENCRYPTION_ON}
 FPassword := Password;
 if (Mode = fmCreate) then
  cStream := TESFSAdvancedFileStream.Create(ESingleFileSystem,
             FileName,Mode,Password,Question,Answer,compressLevel)
 else
 // auto-detect compression level
 cStream := TESFSAdvancedFileStream.Create(ESingleFileSystem,
             FileName,Mode,Password);
{$ELSE}
 FPassword := ;;;
 if (Mode = fmCreate) then
  cStream := TESFSAdvancedFileStream.Create(ESingleFileSystem,
             FileName,Mode,'','','',compressLevel)
 else
 // auto-detect compression level
 cStream := TESFSAdvancedFileStream.Create(ESingleFileSystem,
             FileName,Mode,'');
{$ENDIF}
 cStream.OnProgress := FOnProgress;
 FMode := Mode;
end;


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TESFSFileStream.Destroy;
begin
 if (cStream <> nil) then
  begin
   cStream.Free;
   cStream := nil;
  end;
end;


//------------------------------------------------------------------------------
// read buffer
//------------------------------------------------------------------------------
function TESFSFileStream.Read(var Buffer; Count: Longint): Longint;
begin
 cStream.OnProgress := FOnProgress;
 result := cStream.Read(Buffer,Count);
end; // Read


//------------------------------------------------------------------------------
// write buffer
//------------------------------------------------------------------------------
function TESFSFileStream.Write(const Buffer; Count: Longint): Longint;
begin
 if (bReadOnly) then
  raise Exception.Create('TESFSFileStream.Write - file is in read only mode.');
 cStream.OnProgress := FOnProgress;
 result := cStream.Write(Buffer,Count);
end; // Write


//------------------------------------------------------------------------------
// seek
//------------------------------------------------------------------------------
function TESFSFileStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
 result := cStream.Seek(Offset,Origin);
end; // Seek


{$IFDEF D6H}
function TESFSFileStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
 result := cStream.Seek(Offset,Origin);
end; // Seek
{$ENDIF}


//------------------------------------------------------------------------------
// save data to stream
//------------------------------------------------------------------------------
procedure TESFSFileStream.SaveToStream(Stream: TStream);
begin
 cStream.OnProgress := FOnProgress;
 cStream.SaveToStream(Stream);
end; // SaveToStream


//------------------------------------------------------------------------------
// load data from stream
//------------------------------------------------------------------------------
procedure TESFSFileStream.LoadFromStream(Stream: TStream);
begin
 if (bReadOnly) then
  raise Exception.Create('TESFSFileStream.LoadFromStream - file is in read only mode.');
 cStream.OnProgress := FOnProgress;
 cStream.LoadFromStream(Stream);
end; // LoadFromStream


//------------------------------------------------------------------------------
// save data to file
//------------------------------------------------------------------------------
procedure TESFSFileStream.SaveToFile(const FileName: AnsiString);
begin
 cStream.OnProgress := FOnProgress;
 cStream.SaveToFile(FileName);
end; // SaveToFile


//------------------------------------------------------------------------------
// load data from file
//------------------------------------------------------------------------------
procedure TESFSFileStream.LoadFromFile(const FileName: AnsiString);
begin
 cStream.OnProgress := FOnProgress;
 cStream.LoadFromFile(FileName);
end; // LoadFromFile




{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
//
//   TESingleFileSystem
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// on progress
//------------------------------------------------------------------------------
procedure TESingleFileSystem.DoOnProgress(Progress : Real);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Self,Progress,FCancel);
end; // on progress


//------------------------------------------------------------------------------
// closes all opened files
//------------------------------------------------------------------------------
procedure TESingleFileSystem.CloseAllFiles;
var i: Integer;
begin
 if (FFileHandles <> nil) then
 for i := 0 to FFileHandles.ItemCount -1 do
  begin
   if (FFileHandles.ValueItems[i] <> nil) then
    dispose(FFileHandles.ValueItems[i]);
  end;
end; //CloseAllFiles


//------------------------------------------------------------------------------
// create all internal objects
//------------------------------------------------------------------------------
procedure TESingleFileSystem.InternalCreate;
begin
 FSMHandle := TFreeSpaceManager.Create(PFMHandle);
 DMHandle := TDIRManager.Create(PFMHandle,FSMHandle);
 UFMHandle := TUserFilePageMapManager.Create(PFMHandle,FSMHandle);
 FFileHandles := TSortedPtrArray.Create(0,10,1000);
 FReadOnly := PFMHandle.FReadOnly;
 FExclusive := PFMHandle.FExclusive;
 if (not Encrypted) then
  FPassword := '';
end; //InternalCreate


//------------------------------------------------------------------------------
// not enough space
//------------------------------------------------------------------------------
procedure TESingleFileSystem.DoOnDiskFull(
                         Sender: TObject
                        );
begin
  if Assigned(FOnDiskFull) then
    FOnDiskFull(self);
end;// DoOnDiskFull


//------------------------------------------------------------------------------
// occurs when password needed
//------------------------------------------------------------------------------
procedure TESingleFileSystem.DoOnPassword(
                           FileName: AnsiString;
                           var NewPassword: AnsiString;
                           var SkipFile: Boolean
                           );
{$IFDEF D12H}
var s: String;
{$ENDIF}
begin
  if Assigned(FOnPassword) then
   FOnPassword(Self, FileName, NewPassword, SkipFile)
  else
   begin
{$IFDEF D12H}
    s := NewPassword;
    SkipFile := (not InputQuery(Format(SPasswordTitle, [FileName]),SPasswordPrompt, s));
    NewPassword := s;
{$ELSE}
    SkipFile := (not InputQuery(Format(SPasswordTitle, [FileName]),SPasswordPrompt, NewPassword));
{$ENDIF}
   end;
end;// DoOnPassword


{$IFDEF FULL_VERSION}
//------------------------------------------------------------------------------
// on overwrite prompt
//------------------------------------------------------------------------------
procedure TESingleFileSystem.DoOnOverwritePrompt(
            ExistingFileName,
            NewFileName: AnsiString;
            var bOverwrite: Boolean);
begin
  if Assigned(FOnOverwritePrompt) then
    FOnOverwritePrompt(self,ExistingFileName,NewFileName,bOverwrite);
end;


//------------------------------------------------------------------------------
// file progress
//------------------------------------------------------------------------------
procedure TESingleFileSystem.DoOnFileProgress(
                              Sender: TObject;
                              PercentDone:  Real
                             		);
begin
 if (Assigned(FOnFileProgress)) then
   FOnFileProgress(Self,PercentDone,FCurrentFileName);
end; // DoOnFileProgress


//------------------------------------------------------------------------------
// reloads all data from disk
//------------------------------------------------------------------------------
procedure TESingleFileSystem.InternalReopen(Stream: TStream);
begin
//free handles
 UFMHandle.Free;
 DMHandle.Free;
 FSMHandle.Free;
 PFMHandle.Free;
 FFileHandles.Free;
 // updating handles to PageFileManager
 if (not FInMemory) then
  if (FOpenMode = fmCreate) then
    FOpenMode := fmOpenReadWrite or fmShareExclusive;
 PFMHandle := TPageFileManager.Create(FFileName,FOpenMode,FPassword,'','',FInMemory);
 PFMHandle.LoadFromStream(Stream);
 InternalCreate;
 DMHandle.Load;
end; // InternalReopen


//------------------------------------------------------------------------------
// returns default compression level
//------------------------------------------------------------------------------
function TESingleFileSystem.GetCompressionLevel: TESFSCompressionLevel;
begin
 result := TESFSCompressionLevel(PFMHandle.FHeader.CompressionLevel);
end;


//------------------------------------------------------------------------------
// sets default compression level
//------------------------------------------------------------------------------
procedure TESingleFileSystem.SetCompressionLevel(newLevel: TESFSCompressionLevel);
begin
 PFMHandle.FHeader.CompressionLevel := Byte(newLevel);
 PFMHandle.SaveSFHeader;
end;
{$ENDIF}


//------------------------------------------------------------------------------
// sets in-memory or disk mode
//------------------------------------------------------------------------------
procedure TESingleFileSystem.SetInMemory(value: boolean);
begin
 PFMHandle.InMemory := value;
end;// SetInMemory


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TESingleFileSystem.Create(FileName: AnsiString; Mode: Word;
  						Password: AnsiString = '';
  						Question: AnsiString = '';
  						Answer: AnsiString = '';
              DefaultCompressionLevel: TESFSCompressionLevel = esfsNone
						 );
begin
 if (Mode <> fmCreate) then
  begin
   if (not ESingleFileSystem.IsPasswordValid(FileName,Password)) then
    raise Exception.Create('TESingleFileSystem.Create - invalid password specified, file name = '+
			    AnsiQuotedStr(FileName,'"'));
  end;
 FOpenMode := Mode;
 FFileName := FileName;
{$IFDEF ENCRYPTION_ON}
 PFMHandle := TPageFileManager.Create(Filename,Mode,Password,Question,Answer);
 FPassword := Password;
{$ELSE}
 PFMHandle := TPageFileManager.Create(Filename,Mode,'','','');
 FPassword := '';
{$ENDIF}
 FIsESFSRelativeOffsets := (PFMHandle.FHeader.Version > 2.601);
{$IFDEF FULL_VERSION}
 if (mode = fmCreate) then
  SetCompressionLevel(DefaultCompressionLevel);
{$ENDIF}
 InternalCreate;
end; // Create


//------------------------------------------------------------------------------
// advanced constructor
//------------------------------------------------------------------------------
constructor TESingleFileSystem.Create(FileName: AnsiString; Mode: Word;
               InMemoryMode: Boolean;
      				 Password: AnsiString = '';
   						 Question: AnsiString = '';
  						 Answer: AnsiString = '';
               DefaultCompressionLevel: TESFSCompressionLevel = esfsNone;
               PageSize: Integer = DEFAULT_PAGE_SIZE;
               ExtentPageCount: Integer = DEFAULT_EXTENT_PAGE_COUNT;
               PartFileSize: Int64 = -1
              );
begin
 FInMemory := InMemoryMode;
 FFileName := FileName;
 FOpenMode := Mode;
 // try to open in-memory copy of disk file
 if (FInMemory and (Mode = fmCreate)) then
  if (SysUtils.FileExists(FileName)) then
   Mode := fmOpenReadWrite;

 if (Mode <> fmCreate) then
  begin
   if (not ESingleFileSystem.IsPasswordValid(FileName,Password)) then
    raise Exception.Create('TESingleFileSystem.Create - invalid password specified, file name = '+
			    AnsiQuotedStr(FileName,'"'));
  end;
{$IFDEF ENCRYPTION_ON}
 PFMHandle := TPageFileManager.Create(Filename,Mode,Password,Question,Answer,
 							FInMemory,PageSize,ExtentPageCount, PartFileSize);
 FPassword := Password;
{$ELSE}
 PFMHandle := TPageFileManager.Create(Filename,Mode,'','','',
 							FInMemory,PageSize,ExtentPageCount, PartFileSize);
 FPassword := '';
{$ENDIF}
 FIsESFSRelativeOffsets := (PFMHandle.FHeader.Version > 2.601);
{$IFDEF FULL_VERSION}
 if (mode = fmCreate) then
  SetCompressionLevel(DefaultCompressionLevel);
{$ENDIF}
 InternalCreate;
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TESingleFileSystem.Destroy;
begin
 // close all opened files
 CloseAllFiles;
 // flush buffers (for removable devices)
 if (PFMHandle <> nil) then
  PFMHandle.FlushFileBuffers;
 // free memory
 UFMHandle.Free;
 DMHandle.Free;
 FSMHandle.Free;
 PFMHandle.Free;
 FFileHandles.Free;
 inherited Destroy;
end; //destroy


//------------------------------------------------------------------------------
// repairs file
//------------------------------------------------------------------------------
function TESingleFileSystem.InternalRepair(
                          var log: AnsiString; DeleteCorruptedFiles: Boolean = false;
                          ChangeEncryption: Boolean = false;
                          newPassword: AnsiString = '';
                          newQuestion: AnsiString = '';
                          newAnswer: AnsiString = ''
                          ): Boolean;

var UFHandle:    pUserFileHandle;
    FRHandle:	   Integer;
    FWHandle:	   Integer;
    i,j,size:	   Integer;
    FileID,k:	   Integer;
    PageSize:    Integer;
    MinPageSize: Integer;
//    FileStoreMode: TFileStoreMode;
    NewName,s: AnsiString;
    FullPath:	 AnsiString;
    NewFile:	 TESingleFileSystem;
    buf:			 PAnsiChar;
    PageCount: Integer;
    el,newEl:	 TDirectoryElement;
    oldDir:    AnsiString;
    aDiskFree: Int64;

	//------------------------------------------------------------------------------
  // opens file for safe read
	//------------------------------------------------------------------------------
  function InternalFileOpen(FileID: Integer): Integer;
	var UFHandle: pUserFileHandle;
	begin
	 // inc number of opened file handles
	 inc(DMHandle.FOpenedFiles.Items[FileID]);
	 // allocate new handle
	 new(UFHandle);
	 UFHandle.FileID := FileID;
	 UFHandle.Position := 0;
	 UFHandle.Key := '';
	 UFHandle.Mode := fmOpenRead;
	 // returns file handle
	 result := FFileHandles.GetNextKeyValue;
	 FFileHandles.Insert(result,UFHandle);
  end; // InternalFileOpen


	//------------------------------------------------------------------------------
  // safe read from file
	//------------------------------------------------------------------------------
  function InternalFileRead(Handle: Integer; var Buffer; Count: Integer): Integer;
	var UFHandle: pUserFileHandle;
    pages:		TIntegerArray;
//    el1:			TDirectoryElement;
    size,i:		Integer;
    buf:			TFFPage;
    s:        AnsiString;
    bIgnore:  Boolean;
    bError:   Boolean;
	begin
	 result := 0;
	 UFHandle := FFileHandles.Find(Handle);
	 if (UFHandle = nil) then
	  Exit;
//	 DMHandle.ReadItem(UFHandle^.FileID,el);
	 if (UFHandle^.Position + Count >= el.FileSize) then
	  size := el.FileSize - UFHandle^.Position
	 else
	  size := Count;
	 if (size <= 0) then
	  Exit;
	 pages := TIntegerArray.Create(0,1,100);
   try
  	UFMHandle.GetPages(el,UFHandle^.Position,size,false,pages);
   except
    if (DeleteCorruptedFiles) then
     begin
      result := 0;
      FLastError := erInvalidUFMap;
      pages.Free;
      Exit;
     end
    else
     raise;
   end;
	 if (pages.ItemCount <= 0) then
    begin
     pages.Free;
     Exit;
    end;
	 buf.pData := AllocMem(PFMHandle.PageDataSize);
	 buf.PageHeader.PageType := UFPage;
	 buf.PageHeader.CrcType := crcFast;
   if (ChangeEncryption) and
      (Encrypted) and
      (el.EncMethod = 0) then
    begin
     s := '';
     bIgnore := false;
     //buf.PageHeader.EncType := 1;
    end
   else
    begin
     // read without decoding file
     //buf.PageHeader.EncType := 0;
     s := '';
     bIgnore := true;
    end;
	 // reading data from file
	 for i := 0 to pages.ItemCount - 1 do
	  begin
	   if (Count - result > PFMHandle.PageDataSize) then
	    size := PFMHandle.PageDataSize
	   else
	    size := Count - result;
     try
       bError := not PFMHandle.ReadPage(buf,pages.Items[i],PFMHandle.PageDataSize,s,bIgnore);
       if (bError) then
         FLastError := PFMHandle.FLastError;
     except
       if (DeleteCorruptedFiles) then
        begin
         bError := True;
         FLastError := erReadPageFailed;
        end
       else
        raise;
     end;
	   if (bError) then
      if (DeleteCorruptedFiles) then
       begin
        result := 0;
		    FreeMem(buf.pData);
	   	  pages.Free;
        Exit;
       end;
	   Move(pAnsiChar(buf.pData)^,pAnsiChar(pAnsiChar(@Buffer)+result)^,size);
	   inc(result,size);
	  end;
   UFHandle^.Position := UFHandle^.Position + Int64(result);
	 FreeMem(buf.pData);
	 pages.Free;
  end; // InternalFileRead


	//------------------------------------------------------------------------------
	// safe write to file
	//------------------------------------------------------------------------------
	function InternalFileWrite(Handle: Integer; const Buffer; Count: Integer): Integer;
	var UFHandle: pUserFileHandle;
    pages:		 TIntegerArray;
    el1: 			 TDirectoryElement;
    size,i:		 Integer;
    buf:			 TFFPage;
    s:         AnsiString;
	begin
   FLastError := erOk;
	 result := 0;
	 if (Count <= 0) then
	  Exit;
	 UFHandle := NewFile.FFileHandles.Find(Handle);
	 if (UFHandle = nil) then
	  Exit;
	 NewFile.DMHandle.ReadItem(UFHandle^.FileID,el1);
	 pages := TIntegerArray.Create(0,1,100);
   try
 	  NewFile.UFMHandle.GetPages(el1,UFHandle^.Position,Count,true,pages);
   except
    pages.Free;
    Exit;
   end;
	 if (pages.ItemCount <= 0) then
	  begin
	   pages.Free;
	   Exit;
	  end;
	 buf.pData := AllocMem(NewFile.PFMHandle.PageDataSize);
	 buf.PageHeader.PageType := UFPage;
	 buf.PageHeader.CrcType := crcFast;
	 // reading data from file
	 for i := 0 to pages.ItemCount - 1 do
	  begin
{
//size bugs
   offset := 0;
   if (i = 0) then
    begin
     offset := (UFHandle^.Position+PFMHandle.PageDataSize) mod NewFile.PFMHandle.PageDataSize;
    end;

	   if (Count - result > NewFile.PFMHandle.PageDataSize - offset) then
	    size := NewFile.PFMHandle.PageDataSize - offset
	   else
	    size := Count - result;

   if (not NewFile.PFMHandle.ReadPage(buf,pages.Items[i],NewFile.PFMHandle.PageDataSize,'')) then
    begin
     FLastError := PFMHandle.FLastError;
     break;
    end;
 }
	   if (Count - result > NewFile.PFMHandle.PageDataSize) then
	    size := NewFile.PFMHandle.PageDataSize
	   else
	    size := Count - result;

	   Move(pAnsiChar(pAnsiChar(@Buffer)+result)^,pAnsiChar(buf.pData)^,PFMHandle.PageDataSize);

///////////////////////////////////////////////////////////
//PFMHandle.DecodeBuffer(buf.pData, PFMHandle.PageDataSize,1, PFMHandle.FKey);

//	   Move(pAnsiChar(pAnsiChar(@Buffer)+result)^,pAnsiChar(buf.pData)^,size);

     // write without encoding
     if (ChangeEncryption) and
        (el.EncMethod = 0) and
        (newPassword <> '') then
      begin
  	   buf.PageHeader.EncType := 1;
       s := '';
      end
     else
      begin
  	   buf.PageHeader.EncType := 0;
       s := '';
      end;
	   if (not NewFile.PFMHandle.WritePage(buf,pages.Items[i],
          NewFile.PFMHandle.PageDataSize,s)) then
      begin
       FLastError := NewFile.PFMHandle.FLastError;
       break;
      end;
     // set enc type to the page header
     if (el1.EncMethod <> 0) then
  	   buf.PageHeader.EncType := el1.EncMethod
      else
  	   buf.PageHeader.EncType := NewFile.PFMHandle.FHeader.EncMethod;
	   if (not NewFile.PFMHandle.WritePage(buf,pages.Items[i],0,'')) then
      begin
       FLastError := NewFile.PFMHandle.FLastError;
       break;
      end;
 	   inc(result,size);
	  end;
	 UFHandle^.Position := UFHandle^.Position + Int64(result);
	 FreeMem(buf.pData);
	 if (UFHandle^.Position > el1.FileSize) or (el1.FileSize = 0) then
	   el1.FileSize := UFHandle^.Position;
//	 ESFSEngine.SetCurrentTime(el.LastModifiedTime);
	 NewFile.DMHandle.WriteItem(UFHandle^.FileID,el1);
	 pages.Free;
	end; // FileWrite

begin
 oldDir := GetCurrentDir;
 log := '';
 result := false;
 FCancel := false;
 if (FInMemory) then
  Exit;
 aDiskFree := PFMHandle.DiskFree;
 if ((aDiskFree > 0) and (aDiskFree < Self.DiskSize)) then
  begin
    log := 'Not enough space.';
    try
     DoOnDiskFull(Self);
    except
    end;
    exit;
  end;
 FLastError := erOk;
 NewName := PFMHandle.FFileName + '_new';
 MinPageSize := MIN_PAGE_SIZE;
 PageSize := PFMHandle.FHeader.PageSize;
 // to avoid exception
 if (MIN_PAGE_SIZE > PageSize) then
  MIN_PAGE_SIZE := PageSize;
 try
   // if change ecnryption
   if (ChangeEncryption) then
    begin
     NewFile := TESingleFileSystem.Create(NewName,fmCreate,FInMemory,
                newPassword,newQuestion,newAnswer,
                TESFSCompressionLevel(DefaultCompressionLevel),
                PageSize,
                PFMHandle.FHeader.ExtentPageCount
                );
     if (NewFile = nil) then
      Exit;
    end
   else
    begin
     NewFile := TESingleFileSystem.Create(NewName,fmCreate,FInMemory,
                FPassword,'','',
                TESFSCompressionLevel(DefaultCompressionLevel),
                PageSize,
                PFMHandle.FHeader.ExtentPageCount
                );
  //NewFile.Free;
  //NewFile := TESingleFileSystem.Create(NewName,fmOpenReadWrite,FInMemory,FPassword);
     if (NewFile = nil) then
      Exit;
     NewFile.PFMHandle.FHeader.PasswordHeader := PFMHandle.FHeader.PasswordHeader;
     NewFile.PFMHandle.FHeader.EncMethod := PFMHandle.FHeader.EncMethod;
     NewFile.PFMHandle.FKey := PFMHandle.FKey;
    end;

 finally
  MIN_PAGE_SIZE := MinPageSize;
 end;

 // save old file params
// NewFile.PFMHandle.FHeader.PageSize := PFMHandle.FHeader.PageSize;
// NewFile.PFMHandle.FHeader.ExtentPageCount := PFMHandle.FHeader.ExtentPageCount;
 buf := AllocMem(PFMHandle.PageDataSize);
 size := PFMHandle.PageDataSize;
 if (buf = nil) then
  begin
   FLastError := erNoMemory;
   Exit;
  end;
try
 NewFile.PFMHandle.SaveSFHeader;
 FProgressMax := DMHandle.FDIR.ItemCount;
 FProgress := 0;
 // try to rewrite all files to new file
 for i := 0 to DMHandle.FDIR.ItemCount-1 do
  begin

   DoOnProgress(FProgress/FProgressMax*100.0);
   if (FCancel) then
    begin
     NewFile.PFMHandle.ESFSFile.Close;
     NewFile.PFMHandle.ESFSFile.DeleteFile;
     NewFile.Free;
     log := log + 'RepairFile cancelled. Original file restored.'+#13#10;
     result := false;
     Exit;
    end;

   FProgress := i+1;

   // READ el
   DMHandle.ReadItem(i,el);
   if (el.IsDeleted <> 0) then
    continue;
   if (el.IsFolder <> 0) then
    begin
     try
      // folder
 	    FullPath := DMHandle.GetFullFilePath(i);
      // create all neccessary directories
      NewFile.ForceDirectories(FullPath);
     except
      on e: Exception do
       begin
        log := log + 'Directory #'+IntToStr(i)+': '+AnsiQuotedStr(FullPath,'"')+
                ' deleted. Error: '+crlf+e.Message+crlf;
        continue;
       end;
     end;
     if (not NewFile.DirectoryExists(FullPath)) then
      begin
       log := log + 'Directory '+AnsiQuotedStr(FullPath,'"')+' deleted. '+crlf;
       continue;
      end;
    end // repair folder
   else
    begin
     try
       // get full path to parent folder
       FullPath := DMHandle.GetFullFilePath(el.ParentID);
       // create all neccessary directories
       NewFile.ForceDirectories(FullPath);
     except
      on e: Exception do
       begin
        log := log + 'Directory #'+IntToStr(el.ParentID)+': '+AnsiQuotedStr(FullPath,'"')+
                ' deleted. Error: '+crlf+e.Message+crlf;
        continue;
       end;
     end;
     if (not NewFile.DirectoryExists(FullPath)) then
      begin
       log := log + 'Directory '+AnsiQuotedStr(FullPath,'"')+' deleted. '+crlf;
       continue;
      end;
	   FullPath := DMHandle.GetFullFilePath(i);
     FRHandle := InternalFileOpen(i);
     if (FRHandle <= None) then
      begin
       log := log + 'File '+AnsiQuotedStr(FullPath,'"')+' deleted. '+crlf;
       continue;
      end;
     FWHandle := NewFile.FileOpen(FullPath,fmCreate);
		 UFHandle := NewFile.FFileHandles.Find(FWHandle);
		 if (UFHandle = nil) then
		  begin
       log := log + 'File '+AnsiQuotedStr(FullPath,'"')+' deleted. '+crlf;
       continue;
      end;
     FileID := UFHandle^.FileID;
     // update file information
     NewFile.DMHandle.ReadItem(FileID,newEl);
     newEl.PasswordHeader := el.PasswordHeader;
     newEl.EncMethod := el.EncMethod;
     newEl.Attributes := el.Attributes;
     newEl.CreationTime := el.CreationTime;
     newEl.LastModifiedTime := el.LastModifiedTime;
     newEl.LastAccessTime := el.LastAccessTime;
     NewFile.DMHandle.WriteItem(FileID,newEl);
     // detect page count for file data
     PageCount := Integer(el.FileSize div Int64(size));
     if (el.FileSize mod Int64(size) <> 0) then
      inc(PageCount);
     FLastError := erOK; 
     for j := 0 to PageCount-1 do
      begin
       FillChar(buf^,size,$00);
//       k := InternalFileRead(FRHandle,buf^,size);
 k := InternalFileRead(FRHandle,buf^,PFMHandle.PageDataSize);
       if (DeleteCorruptedFiles) then
        begin
         // delete bad file if errors occured
         // or invalid size was read
         if (FLastError <> erOk) or
            (
             (k <> size) and
             (not((j = PageCount-1) and (k = el.FileSize mod Int64(size))))
            ) then
          begin
	         log := log + 'File '+AnsiQuotedStr(FullPath,'"')+' deleted. '+crlf;
	         break;
          end;
        end; // bad files check
       if (j < PageCount-1) then
        k := size
       else
        k := el.FileSize mod Int64(size);
       if (k = 0) then
        k := size;
       if (InternalFileWrite(FWHandle,buf^,k) <> k) then
        begin
         try
          DoOnDiskFull(Self);
         except
         end;
         raise Exception.Create('Not enough space');
        end;
//       InternalFileWrite(FWHandle,buf^,PFMHandle.PageDataSize);
      end; // write file data
     if (FLastError <> erOK) then
      begin
       FLastError := erOK;
       NewFile.FileClose(FWHandle);
       NewFile.DeleteFile(FullPath);
      end
     else
      begin
        NewFile.DMHandle.ReadItem(FileID,newEl);
        // in any normal case sizes must be the same
        if (DeleteCorruptedFiles) then
          if (el.FileSize <> newEl.FileSize) then
           raise Exception.Create('');
        NewFile.FileClose(FWHandle);
      end;
     // close files
     FileClose(FRHandle);
    end; // repair file
  end; // for all files and folders
 FreeMem(buf);
except
 on E: Exception do
  begin
   log := log + 'Critical error occured. Original file restored.'+#13#10+
          E.Message;
   NewFile.PFMHandle.ESFSFile.Close;
   NewFile.PFMHandle.ESFSFile.DeleteFile;
   NewFile.Free;
   result := false;
   Exit;
  end;
end;
 // swap old file and new file
// NewFile.Free;
 NewFile.PFMHandle.ESFSFile.Close;
 PFMHandle.ESFSFile.Close;
{ PFMHandle.ESFSFile.Free;
 PFMHandle.ESFSFile := nil;}
 FullPath := PFMHandle.FFileName;
 i := 0;
 s := FullPath+IntToStr(i);
 repeat
	 while (SysUtils.FileExists(s)) do
	  begin
	   inc(i);
	   s := FullPath+IntToStr(i);
	  end;
 until PFMHandle.RenameFile(s);
 if (not NewFile.PFMHandle.RenameFile(FullPath)) then
  begin
   PFMHandle.RenameFile(FullPath);
   PFMHandle.ESFSFile.Open(false, true);
   NewFile.Free;
   FLastError := erRenameFileError;
   result := false;
   Exit;
  end;
 PFMHandle.DeleteFile;
// PFMHandle.Free;

// NewFile.DMHandle.ReadItem(1,el);
// NewFile.DMHandle.ReadItem(2,el);

//free handles
 UFMHandle.Free;
 DMHandle.Free;
 FSMHandle.Free;
 PFMHandle.Free;
 FFileHandles.Free;

 NewFile.Free;
// if (FReadOnly) then
//  k := fmOpenRead
// else
  k := fmOpenReadWrite;
 if (ChangeEncryption) then
  FPassword := newPassword;


 // updating handles to PageFileManager
 PFMHandle := TPageFileManager.Create(FullPath,k,FPassword,'','',FInMemory);
 InternalCreate;
 DMHandle.Load;
// DMHandle := TDIRManager.Create(PFMHandle,FSM);
 result := true;
// DMHandle.ReadItem(1,el);
// DMHandle.ReadItem(2,el);
 DoOnProgress(100.0);
 SetCurrentDir(oldDir);
end; // InternalRepair


function TESingleFileSystem.Repair(var log: AnsiString; DeleteCorruptedFiles: Boolean = false): Boolean;
begin
 result := false;
 if (FReadOnly) then
  Exit;
 result := InternalRepair(log,DeleteCorruptedFiles,false);
end; // Repair


//------------------------------------------------------------------------------
// returns true and restores password if control answer is valid
//------------------------------------------------------------------------------
function TESingleFileSystem.RestorePasswordByControlAnswer(FileName: AnsiString; Answer: AnsiString; var Password: AnsiString): Boolean;
begin
 result := DMHandle.RestorePasswordByControlAnswer(FileName,Answer,Password);
end; // RestorePasswordByControlAnswer


//------------------------------------------------------------------------------
// returns true if Single file password is valid
//------------------------------------------------------------------------------
function TESingleFileSystem.IsPasswordValid(FileName: AnsiString; Password: AnsiString): Boolean;
begin
 result := DMHandle.IsPasswordValid(FileName,Password);
end; // IsPasswordValid


//------------------------------------------------------------------------------
// returns control question
//------------------------------------------------------------------------------
function TESingleFileSystem.GetControlQuestion(FileName: AnsiString): AnsiString;
begin
 result := DMHandle.GetControlQuestion(FileName);
end; // GetControlQuestion

//------------------------------------------------------------------------------
// get password header
//------------------------------------------------------------------------------
function TESingleFileSystem.GetPasswordHeader(FileName: AnsiString; var passHeader: TPasswordHeader): Boolean;
begin
 result := DMHandle.GetPasswordHeader(FileName,passHeader);
end;


//------------------------------------------------------------------------------
// set password header
//------------------------------------------------------------------------------
procedure TESingleFileSystem.SetPasswordHeader(FileName: AnsiString; passHeader: TPasswordHeader);
begin
  DMHandle.SetPasswordHeader(FileName,passHeader);
end;


//------------------------------------------------------------------------------
// returns encrypted
//------------------------------------------------------------------------------
function TESingleFileSystem.GetEncrypted: Boolean;
begin
 result := PFMHandle.FHeader.EncMethod <> EncNone;
end;


//------------------------------------------------------------------------------
// returns control question
//------------------------------------------------------------------------------
function TESingleFileSystem.PGetControlQuestion: AnsiString;
begin
 if (PFMHandle.FHeader.EncMethod <> EncNone) then
   result := DecryptQuestion(PFMHandle.FHeader.PasswordHeader)
 else
  result := PFMHandle.FHeader.PasswordHeader.Question;
end;


//------------------------------------------------------------------------------
// returns true if file is encrypted by its own password
//------------------------------------------------------------------------------
function TESingleFileSystem.IsFileEncrypted(FileName: AnsiString): boolean;
begin
 result := DMHandle.IsFileEncrypted(FileName);
end; // IsFileEncrypted


//------------------------------------------------------------------------------
// creates file
//------------------------------------------------------------------------------
function TESingleFileSystem.FileCreate(const FileName: AnsiString;
						 Password: AnsiString = '';
						 Question: AnsiString = '';
						 Answer: AnsiString = ''
             ): Integer;
begin
 // creating file
 if (FileExists(FileName)) then
  if (not DeleteFile(FileName)) then
   begin
    result := erFileNotDeleted;
    Exit;
   end;
{$IFDEF ENCRYPTION_ON}
 result := DMHandle.FileCreate(FileName,Password,Question,Answer);
{$ELSE}
 result := DMHandle.FileCreate(FileName,'','','');
{$ENDIF}
 if (result < 0) then
  FLastError := DMHandle.FLastError;
 if ((result < 0) and (FLastError = erDiskFull)) then
  DoOnDiskFull(Self);
end; // FileCreate


//------------------------------------------------------------------------------
// open file
//------------------------------------------------------------------------------
function TESingleFileSystem.FileOpen(const FileName: AnsiString; Mode: LongWord;
						 Password: AnsiString = '';
						 Question: AnsiString = '';
						 Answer: AnsiString = ''
             ): Integer;
var
    UFHandle: pUserFileHandle;
    Key: AnsiString;
    bSkipFile, bOK: Boolean;
begin
{$IFNDEF ENCRYPTION_ON}
Password := '';
Question := '';
Answer := '';
{$ENDIF}
 if (Mode = fmCreate) then
  begin
   FileCreate(FileName,Password,Question,Answer)
  end
 else
  if (FileExists(FileName)) then
   if (not DMHandle.IsPasswordValid(FileName,Password)) then
    begin
     // passwords retry loop
     bSkipFile := True;
     repeat
      DoOnPassword(FileName, Password, bSkipFile);
      bOK := DMHandle.IsPasswordValid(FileName,Password);
      if (bSkipFile) then
       break;
     until (bOK);

     // file skipped?
     if (not bOK) then
      begin
       // invalid password
       result := None;
       Exit;
      end;
    end;
 result := DMHandle.FileOpen(FileName,Password,Key);
 if (result <= None) then
  Exit;
 // allocate new handle
 new(UFHandle);
 UFHandle.FileID := result;
 UFHandle.Position := 0;
 UFHandle.Key := Key;
 UFHandle.Mode := Mode;
 // returns file handle
 result := FFileHandles.GetNextKeyValue;
 FFileHandles.Insert(result,UFHandle);
end; // FileOpen


//------------------------------------------------------------------------------
// file close
//------------------------------------------------------------------------------
procedure TESingleFileSystem.FileClose(Handle: Integer);
var UFHandle: pUserFileHandle;
begin
 UFHandle := FFileHandles.Find(Handle);
 if (UFHandle <> nil) then
  begin
   DMHandle.FileClose(UFHandle.FileID);
   dispose(UFHandle);
   FFileHandles.Delete(Handle);
  end;
end; // FileClose


//------------------------------------------------------------------------------
// read from file
//------------------------------------------------------------------------------
function TESingleFileSystem.FileRead(Handle: Integer; var Buffer; Count: Integer): Integer;
var UFHandle: pUserFileHandle;
    pages:		TIntegerArray;
    el:				TDirectoryElement;
    size,i:		Integer;
    offset:		Integer;
    buf:			TFFPage;
    Key:			AnsiString;
begin
 FLastError := erOk;
 result := 0;
 UFHandle := FFileHandles.Find(Handle);
 if (UFHandle = nil) then
  Exit;
 DMHandle.ReadItem(UFHandle^.FileID,el);
{$IFDEF DEBUG_TRACE_READ}
aaWriteToLog('0 TESingleFileSystem.FileRead. Position = '+IntToStr(UFHandle^.Position)+#9+'Size = '+IntToStr(el.FileSize)+#9+'Count = '+IntToStr(Count));
{$ENDIF}
 if ((UFHandle^.Position + Int64(Count)) >= el.FileSize) then
  size := el.FileSize - UFHandle^.Position
 else
  size := Count;
 if (size <= 0) then
  Exit;
 if (Count > size) then
  Count := size;
 pages := TIntegerArray.Create(0,1,100);
 UFMHandle.GetPages(el,UFHandle^.Position,size,false,pages);
{$IFDEF DEBUG_TRACE_READ}
aaWriteToLog('1 TESingleFileSystem.FileRead. pages.ItemCount = '+IntToStr(Pages.ItemCount));
aaWriteToLog('First map PageNo = '+IntToStr(el.FirstMapPageNo));
{$ENDIF}
 if (pages.ItemCount <= 0) then
  raise Exception.Create('TESingleFileSystem.FileRead - no pages were found by UFM.');
 buf.pData := AllocMem(PFMHandle.PageDataSize);
 buf.PageHeader.PageType := UFPage;
 // if user file is not encrypted and Single file is encrypted then
 // user file will be encrypted as Single file (with its password and method)
 if (el.EncMethod = EncNone) then
  if (PFMHandle.FHeader.EncMethod <> EncNone) then
   buf.PageHeader.EncType := PFMHandle.FHeader.EncMethod;
 buf.PageHeader.CrcType := crcFast;
 Key := '';
 if (el.EncMethod <> EncNone) then
  Key := UFHandle^.Key
 else
  if (PFMHandle.FHeader.EncMethod <> EncNone) then
   Key := PFMHandle.FKey;
 // reading data from file
 for i := 0 to pages.ItemCount - 1 do
  begin
//size bugs
   offset := 0;
   if (i = 0) then
    begin
     offset := (UFHandle^.Position+PFMHandle.PageDataSize) mod PFMHandle.PageDataSize;
    end;

   if (Count - result > PFMHandle.PageDataSize-offset) then
    size := PFMHandle.PageDataSize-offset
   else
    size := Count - result;
{$IFDEF DEBUG_TRACE_READ}
aaWriteToLog('1 TESingleFileSystem.FileRead reading page, pageNo = '+IntToStr(pages.Items[i])+#9+'i = '+IntToStr(i)+#9+'Pos = '+IntToStr(UFHandle^.Position));
{$ENDIF}
   if (not PFMHandle.ReadPage(buf,pages.Items[i],PFMHandle.PageDataSize,Key)) then
    begin
     FLastError := PFMHandle.FLastError;
{$IFDEF DEBUG_TRACE_READ}
aaWriteToLog('2 TESingleFileSystem.FileRead reading page failed! pageNo = '+IntToStr(pages.Items[i])+#9+'i = '+IntToStr(i)+#9+'LastError = '+IntToStr(FLastError));
{$ENDIF}
     break;
    end;
   Move(PAnsiChar(PAnsiChar(buf.pData)+offset)^,PAnsiChar(PAnsiChar(@Buffer)+result)^,size);
   inc(result,size);
  end;
 UFHandle^.Position := UFHandle^.Position + Int64(result);
 FreeMem(buf.pData);
 pages.Free;
end; // FileRead


//------------------------------------------------------------------------------
// write to file
//------------------------------------------------------------------------------
function TESingleFileSystem.FileWrite(Handle: Integer; const Buffer; Count: Integer): Integer;
var UFHandle: pUserFileHandle;
    pages:		TIntegerArray;
    el:				TDirectoryElement;
    size,i:		Integer;
    buf:			TFFPage;
    Key:			AnsiString;
    offset:		Integer;
begin
 FLastError := erOk;
 result := 0;
 if (Count <= 0) then
  Exit;
 UFHandle := FFileHandles.Find(Handle);
 if (UFHandle = nil) then
  Exit;
 if (UFHandle.Mode and SysUtils.fmOpenRead <> 0) then
  Exit;
 DMHandle.ReadItem(UFHandle^.FileID,el);
{$IFDEF DEBUG_TRACE_WRITE}
aaWriteToLog('0 TESingleFileSystem.FileWrite. Position = '+IntToStr(UFHandle^.Position)+#9+'Size = '+IntToStr(el.FileSize)+#9+'Count = '+IntToStr(Count));
aaWriteToLog('First map PageNo = '+IntToStr(el.FirstMapPageNo));
{$ENDIF}
 pages := TIntegerArray.Create(0,1,100);
//aaStartTime;
 if (not UFMHandle.GetPages(el,UFHandle^.Position,Count,true,pages)) then
  begin
   pages.Free;
   if (UFMHandle.FLastError = erDiskFull) then
    DoOnDiskFull(Self);
   FLastError := UFMHandle.FLastError;
   Exit;
  end;
{$IFDEF DEBUG_TRACE_WRITE}
aaWriteToLog('0.1 TESingleFileSystem.FileWrite. pages.ItemCount = '+IntToStr(Pages.ItemCount));
{$ENDIF}

//aaStopTime;
 if (pages.ItemCount <= 0) then
  begin
   pages.Free;
   Exit;
  end;

 // if user file is not encrypted and Single file is encrypted then
 // user file will be encrypted as Single file (with its password and method)
 buf.pData := AllocMem(PFMHandle.PageDataSize);
 buf.PageHeader.PageType := UFPage;
 buf.PageHeader.EncType := el.EncMethod;
 if (el.EncMethod = EncNone) then
  if (PFMHandle.FHeader.EncMethod <> EncNone) then
   buf.PageHeader.EncType := PFMHandle.FHeader.EncMethod;

 buf.PageHeader.CrcType := crcFast;
 Key := '';
 if (el.EncMethod <> EncNone) then
  Key := UFHandle^.Key
 else
  if (PFMHandle.FHeader.EncMethod <> EncNone) then
   Key := PFMHandle.FKey;
 // reading data from file
 for i := 0 to pages.ItemCount - 1 do
  begin
   offset := 0;
   if (i = 0) then
    begin
     offset := (UFHandle^.Position+PFMHandle.PageDataSize) mod PFMHandle.PageDataSize;
    end;
   if (Count - result > PFMHandle.PageDataSize - offset) then
    size := PFMHandle.PageDataSize - offset
   else
    size := Count - result;

  // added by Leo Martin
  // optimization - there is no need in reading page that will be totally rewritten
  if (offset > 0) or (size < PFMHandle.PageDataSize) then
   if (not PFMHandle.ReadPage(buf,pages.Items[i],PFMHandle.PageDataSize,Key)) then
    begin
     FLastError := PFMHandle.FLastError;
     break;
    end;

   Move(PAnsiChar(PAnsiChar(@Buffer)+result)^,PAnsiChar(PAnsiChar(buf.pData)+offset)^,size);
 buf.PageHeader.PageType := UFPage;
 buf.PageHeader.EncType := el.EncMethod;
 if (el.EncMethod = EncNone) then
  if (PFMHandle.FHeader.EncMethod <> EncNone) then
   buf.PageHeader.EncType := PFMHandle.FHeader.EncMethod;

 buf.PageHeader.CrcType := crcFast;

//aaStartTime;
//debugFlag := true;
{$IFDEF DEBUG_TRACE_WRITE}
aaWriteToLog('1 TESingleFileSystem.FileWrite writing page, pageNo = '+IntToStr(pages.Items[i])+#9+'i = '+IntToStr(i)+#9+'Pos = '+IntToStr(UFHandle^.Position));
{$ENDIF}
   if (not PFMHandle.WritePage(buf,pages.Items[i],PFMHandle.PageDataSize,Key)) then
    begin
     FLastError := PFMHandle.FLastError;
{$IFDEF DEBUG_TRACE_READ}
aaWriteToLog('2 TESingleFileSystem.FileWrite writing page failed! pageNo = '+IntToStr(pages.Items[i])+#9+'i = '+IntToStr(i)+#9+'LastError = '+IntToStr(FLastError));
{$ENDIF}
     break;
    end;
//debugFlag := false;
//aaStopTime;
   inc(result,size);
  end;
 UFHandle^.Position := UFHandle^.Position + Int64(result);
 FreeMem(buf.pData);
 if (UFHandle^.Position > el.FileSize) or (el.FileSize = 0) then
  begin
   el.FileSize := UFHandle^.Position;
  end;
 ESFSEngine.SetCurrentTime(el.LastModifiedTime);
 DMHandle.WriteItem(UFHandle^.FileID,el);
 pages.Free;
end; // FileWrite


//------------------------------------------------------------------------------
// seek in file
//------------------------------------------------------------------------------
function TESingleFileSystem.FileSeek(Handle: Integer; const Offset: Int64; Origin: Integer): Int64;
var UFHandle: pUserFileHandle;
    el:				TDirectoryElement;
begin
 result := 0;
 UFHandle := FFileHandles.Find(Handle);
 if (UFHandle = nil) then
  Exit;
 DMHandle.ReadItem(UFHandle^.FileID,el);
 case Origin of
  soFromBeginning: UFHandle^.Position := Offset;
  soFromEnd: UFHandle^.Position := el.FileSize + Offset;
  soFromCurrent: UFHandle^.Position := UFHandle^.Position + Offset;
 end;
 result := UFHandle^.Position;
end; // FileSeek


//------------------------------------------------------------------------------
// flsuh file buffers
//------------------------------------------------------------------------------
procedure TESingleFileSystem.FlushFileBuffers(Handle: Integer);
begin
 PFMHandle.FlushFileBuffers;
end;// FlushFileBuffers


//------------------------------------------------------------------------------
// sets file size
//------------------------------------------------------------------------------
function TESingleFileSystem.FileSetSize(Handle: Integer; Size: Int64): Int64;
var UFHandle: pUserFileHandle;
    el:				TDirectoryElement;
begin
 result := erInvalidHandle;
 UFHandle := FFileHandles.Find(Handle);
 if (UFHandle = nil) then
  Exit;
 if (UFHandle.Mode and SysUtils.fmOpenRead <> 0) then
  Exit;
 DMHandle.ReadItem(UFHandle^.FileID,el);
 if (UFMHandle.SetSize(el,Size,true)) then
  begin
   el.FileSize := Size;
   ESFSEngine.SetCurrentTime(el.LastModifiedTime);
   DMHandle.WriteItem(UFHandle^.FileID,el);
   UFHandle^.Position := Size;
   result := Size;
  end
 else
  begin
   if (UFMHandle.FLastError = erDiskFull) then
    DoOnDiskFull(Self);
   FLastError := UFMHandle.FLastError;
   Result := UFMHandle.FLastError;
  end;
end; // FileSetSize


//------------------------------------------------------------------------------
// delete file
//------------------------------------------------------------------------------
function TESingleFileSystem.DeleteFile(const FileName: AnsiString): Boolean;
var el:				TDirectoryElement;
    FileID:   Integer;
begin
 result := false;
 FileID := DMHandle.FindByName(FileName);
 if (FileID <= None) then
  Exit;
 if (DMHandle.GetOpenFiles(FileID) > 0) then
  Exit;
 DMHandle.ReadItem(FileID,el);
 el.IsDeleted := 1;
 SetCurrentTime(el.LastModifiedTime);
 el.LastAccessTime := el.LastModifiedTime;
 UFMHandle.SetSize(el,0,true);
 el.FileSize := 0;
 DMHandle.WriteItem(FileID,el);
 result := true;
end; // DeleteFile


//------------------------------------------------------------------------------
// rename file
//------------------------------------------------------------------------------
function TESingleFileSystem.RenameFile(const OldName, NewName: AnsiString): Boolean;
begin
 result := DMHandle.RenameFile(OldName,NewName);
end; // RenameFile


{$IFDEF FULL_VERSION}
//------------------------------------------------------------------------------
// copy file
//------------------------------------------------------------------------------
function TESingleFileSystem.CopyFile(const OldName, NewName: AnsiString; Password: AnsiString = ''): Boolean;
var Size1,
    FBlockSize: Integer;
    Count:      Int64;
    Size:       Int64;
    buf:        PAnsiChar;
    FInHandle,
    FOutHandle: Integer;
    PasswordHeader: TPasswordHeader;
    attr:       DWORD;
begin
 FBlockSize := DefaultCopyBlockSize;
 result := false;

 self.GetPasswordHeader(oldName,PasswordHeader);
 self.DeleteFile(NewName);
 FOutHandle := self.FileCreate(NewName,Password);
 if (FOutHandle < 0) then Exit;
 self.FileClose(fOutHandle);

 self.SetPasswordHeader(NewName,PasswordHeader);

 attr := self.FileGetAttr(OldName);
 FileSetAttr(NewName,attr);

 FInHandle := self.FileOpen(OldName,fmOpenRead or fmShareDenyWrite,Password);
 if (FInHandle < 0) then Exit;

 FOutHandle := self.FileOpen(NewName,fmOpenReadWrite or fmShareExclusive,Password);
 if (FOutHandle < 0) then Exit;

 DoOnFileProgress(self,0);
 buf := AllocMem(FBlockSize);
 Count := 0;
 Size := self.FileSeek(FInHandle,0,soFromEnd);
 self.FileSeek(FInHandle,0,soFromBeginning);
 result := true;
 while Count < Size do
  begin
   if (Size - Count > FBlockSize) then
    Size1 := FBlockSize
   else
    Size1 := Size - Count;
   result := false;
   if (self.FileRead(FInHandle,buf^,Size1) <> Size1) then
    break;
   if (self.FileWrite(FOutHandle,buf^,Size1) <> Size1) then
    break;
   result := true;
   Count := Count + Size1;
   FProgressMax := Size;
   FProgress := Count;

   DoOnFileProgress(self,FProgress/FProgressMax*100.0);
  end;

 FreeMem(buf);

 self.FileClose(FInHandle);
 self.FileClose(FOutHandle);

 DoOnFileProgress(self,100.0);
end;


//------------------------------------------------------------------------------
// move file
//------------------------------------------------------------------------------
function TESingleFileSystem.MoveFile(const OldName, NewName: AnsiString; Password: AnsiString = ''): Boolean;
begin
 result := CopyFile(OldName, NewName, Password);
 if (result) then
  result := self.DeleteFile(OldName);
end;
{$ENDIF}


//------------------------------------------------------------------------------
// is file exists
//------------------------------------------------------------------------------
function TESingleFileSystem.FileExists(const FileName: AnsiString): Boolean;
begin
 // check if file exists
 result := DMHandle.FindByName(FileName) >= erOk;
end; // FileExists


//------------------------------------------------------------------------------
// returns file attributes
//------------------------------------------------------------------------------
function TESingleFileSystem.FileGetAttr(const FileName: AnsiString): Integer;
var  FileID:  Integer;
     el:			TDirectoryElement;
begin
 result := 0;
 FileID := DMHandle.FindByName(FileName);
 if (FileID <= None) then
  Exit;
 DMHandle.ReadItem(FileID,el);
 result := el.Attributes;
end; // FileGetAttr


//------------------------------------------------------------------------------
// set attributes, FileSetAttr returns zero if the function was successful.
//------------------------------------------------------------------------------
function TESingleFileSystem.FileSetAttr(const FileName: AnsiString; Attr: Integer): Integer;
var  FileID:  Integer;
     el:			TDirectoryElement;
begin
 result := None;
 FileID := DMHandle.FindByName(FileName);
 if (FileID <= None) then
  Exit;
 DMHandle.ReadItem(FileID,el);
 el.Attributes := Attr;
 DMHandle.WriteItem(FileID,el);
 result := 0;
end; // FileSetAttr


//------------------------------------------------------------------------------
// Returns the date-and-time stamp of a specified file.
//------------------------------------------------------------------------------
function TESingleFileSystem.FileAge(const FileName: AnsiString): Integer;
var  FileID:  Integer;
     el:			TDirectoryElement;
	   LocalFileTime: TFileTime;
begin
 result := None;
 FileID := DMHandle.FindByName(FileName);
 if (FileID <= None) then
  Exit;
 DMHandle.ReadItem(FileID,el);
 FileTimeToLocalFileTime(el.LastModifiedTime, LocalFileTime);
 if FileTimeToDosDateTime(LocalFileTime, LongRec(Result).Hi,
        LongRec(Result).Lo) then Exit;
 result := None;
end; // FileAge


//------------------------------------------------------------------------------
// Returns a DOS date-time stamp for a specified file.
//------------------------------------------------------------------------------
function TESingleFileSystem.FileGetDate(Handle: Integer): Integer;
var UFHandle: pUserFileHandle;
    el:				TDirectoryElement;
    LocalFileTime: TFileTime;
begin
 result := None;
 UFHandle := FFileHandles.Find(Handle);
 if (UFHandle = nil) then
  Exit;
 DMHandle.ReadItem(UFHandle^.FileID,el);
 FileTimeToLocalFileTime(el.LastModifiedTime, LocalFileTime);
 if FileTimeToDosDateTime(LocalFileTime, LongRec(Result).Hi,
        LongRec(Result).Lo) then Exit;
 result := None;
end; // FileGetDate


//------------------------------------------------------------------------------
// Sets the DOS time stamp for a specified file.
//------------------------------------------------------------------------------
function TESingleFileSystem.FileSetDate(Handle: Integer; Age: Integer): Integer;
var UFHandle: pUserFileHandle;
    el:				TDirectoryElement;
	  LocalFileTime, FileTime: TFileTime;
begin
 result := None;
 UFHandle := FFileHandles.Find(Handle);
 if (UFHandle = nil) then
  Exit;
 DMHandle.ReadItem(UFHandle^.FileID,el);
 Result := 0;
 if DosDateTimeToFileTime(LongRec(Age).Hi, LongRec(Age).Lo, LocalFileTime) and
    LocalFileTimeToFileTime(LocalFileTime, FileTime)
    then
  begin
   el.LastModifiedTime := FileTime;
   DMHandle.WriteItem(UFHandle^.FileID,el);
   Exit;
  end;
 result := None;
end; // FileSetDate


//----------------------- User Interface ----------------------------------
// find file by pattern using '*', '?'
//------------------------------------------------------------------------------
function TESingleFileSystem.FindFirst(const Path: AnsiString; Attr: Integer; var F: TSearchRec): Integer;
begin
 result := DMHandle.FindFirst(Path,Attr,F);
end; // FindFirst


//------------------------------------------------------------------------------
// find next file
//------------------------------------------------------------------------------
function TESingleFileSystem.FindNext(var F: TSearchRec): Integer;
begin
 result := DMHandle.FindNext(F);
end; // FindNext


//------------------------------------------------------------------------------
// closes find structure
//------------------------------------------------------------------------------
procedure TESingleFileSystem.FindClose(var F: TSearchRec);
begin
 DMHandle.FindClose(F);
end; // FindClose


//------------------------------------------------------------------------------
// sets new encryption mode
// if newPassword = '' then encryption will be removed
//------------------------------------------------------------------------------
function TESingleFileSystem.ChangeEncryption(
                              newPassword: AnsiString = '';
                              newQuestion: AnsiString = '';
                              newAnswer: AnsiString = ''
                              ): Boolean;
var log: AnsiString;
begin
{$IFNDEF ENCRYPTION_ON}
Exit;
{$ENDIF}
 result := false;
 if (FReadOnly) then
  Exit;
 if (newPassword = FPassword) then
  begin
   DoOnProgress(0);
   CreatePasswordHeader(PFMHandle.FHeader.PasswordHeader,FPassword,
      newQuestion,newAnswer);
   PFMHandle.SaveSFHeader;
   if (PFMHandle.FHeader.EncMethod <> encNone) then
    CheckPassword(PFMHandle.FHeader.PasswordHeader,FPassword,PFMHandle.FKey);
   DoOnProgress(100);
   result := true;
  end
 else
  result := InternalRepair(log,false,true,newPassword,newQuestion,newAnswer);
end; // ChangeEncryption


{$IFDEF FULL_VERSION}
//------------------------------------------------------------------------------
// Change Encryptions for Masked Files
//------------------------------------------------------------------------------
function TESingleFileSystem.ChangeFilesEncryption(FileMask, oldPassword,
  newPassword, newQuestion, newAnswer: AnsiString): Boolean;
var
    sr: TSearchRec;
    ESFStream: TESFSFileStream;
    pwd: AnsiString;
    SkipFile: boolean;
begin
 result := false;
{$IFNDEF ENCRYPTION_ON}
Exit;
{$ENDIF}
 FindFirst(FileMask, faAnyFile-faDirectory, sr);
 repeat
   SkipFile := false;
   pwd := oldPassword;

   while (not Self.IsPasswordValid(sr.Name, pwd)) and not SkipFile do
     DoOnPassword(sr.Name, pwd, SkipFile);

   if not SkipFile then
     begin
       ESFStream := TESFSFileStream.Create(self, sr.Name, fmOpenReadWrite, pwd);
       try
         ESFStream.ChangeEncryption(newPassword, newQuestion, newAnswer);
         result := true;
       finally
         ESFStream.Free;
       end;
    end;

 until FindNext(sr) <> 0;

end;//ChangeFilesEncryption




//------------------------------------------------------------------------------
// returns current directory name ('\' if root directory )
//------------------------------------------------------------------------------
function TESingleFileSystem.GetCurrentDir: AnsiString;
begin
 result := DMHandle.GetCurrentDir;
end; // GetCurrentDir


//------------------------------------------------------------------------------
// for CurrentDir property
//------------------------------------------------------------------------------
procedure TESingleFileSystem.PSetCurrentDir(const Dir: AnsiString);
begin
 SetCurrentDir(Dir);
end;

//------------------------------------------------------------------------------
// return value set to True if directory successfully changed
//------------------------------------------------------------------------------
function TESingleFileSystem.SetCurrentDir(const Dir: AnsiString): Boolean;
begin
 result := DMHandle.SetCurrentDir(Dir);
end; // SetCurrentDir


//------------------------------------------------------------------------------
// removes directory
//------------------------------------------------------------------------------
function TESingleFileSystem.RemoveDir(const Dir: AnsiString): Boolean;
begin
 result := DMHandle.RemoveDir(Dir);
end; // RemoveDir


//------------------------------------------------------------------------------
// creates directory
//------------------------------------------------------------------------------
function TESingleFileSystem.CreateDir(const Dir: AnsiString): Boolean;
begin
 result := DMHandle.CreateDir(Dir);
 if (not result) then
  FLastError := DMHandle.FLastError;
 if ((not result) and (FLastError = erDiskFull)) then
   DoOnDiskFull(Self);
end; // CreateDir
{$ENDIF}

//------------------------------------------------------------------------------
// Creates all the directories along a directory path if they do not already exist
//------------------------------------------------------------------------------
function TESingleFileSystem.ForceDirectories(Dir: AnsiString): Boolean;
begin
 result := DMHandle.ForceDirectories(Dir);
 if (not result) then
  FLastError := DMHandle.FLastError;
 if ((not result) and (FLastError = erDiskFull)) then
   DoOnDiskFull(Self);
end; // ForceDirectories


//------------------------------------------------------------------------------
// determines whether a specified directory exists.
//------------------------------------------------------------------------------
function TESingleFileSystem.DirectoryExists(Name: AnsiString): Boolean;
begin
 result := DMHandle.DirectoryExists(Name);
end; // DirectoryExists


//------------------------------------------------------------------------------
// returns size of Single file
//------------------------------------------------------------------------------
function TESingleFileSystem.DiskSize: Int64;
begin
 result := PFMHandle.ESFSFile.Size;
end; // DiskSize


{$IFDEF FULL_VERSION}
//------------------------------------------------------------------------------
// returns free space in Single file
//------------------------------------------------------------------------------
function TESingleFileSystem.DiskFree: Int64;
begin
 result := FSMHandle.GetFreePageCount;
end; // DiskFree


//------------------------------------------------------------------------------
// imports files from specified path to current directory
//------------------------------------------------------------------------------
function TESingleFileSystem.ImportFiles(
                         SourcePath:    AnsiString;
                         DestPath:      AnsiString = ''; // current dir
                         Attr:          Integer = faAnyFile;
                         bRecursive:    Boolean = true;
                         OverwriteMode: TESFSOverwriteMode = omPrompt;
                         EncryptFiles:  Boolean = False
                         ): Integer;
const
  faSpecial = faHidden or faSysFile or faVolumeID or faDirectory;

 var FileList:  TStringList;
     PathList:  TStringList;
     Mask:      AnsiString;
     StartPath: AnsiString;
     i:         Integer;
     OldPath:   AnsiString;


 // progress event

 procedure ImportFile;
 var fs: TESFSFileStream;
     name, password:  AnsiString;
     bOverwrite, SkipFile:   Boolean;
     Handle: Integer;
 begin
  ForceDirectories(aaExcludeTrailingBackslash(PathList.Strings[i]));
  if (FileList.Strings[i] = '') then
   Exit;
  name := PathList.Strings[i]+FileList.Strings[i];
  bOverwrite := false;
  if (FileExists(name)) then
   begin
    if (OverwriteMode = omNever) then
     Exit;
    if ((OverwriteMode = omPrompt)) then
    begin
     DoOnOverwritePrompt(name,StartPath+name,bOverwrite);
     if (not bOverwrite) then
      Exit;
    end;
   end; // file exists

  FCurrentFileName := name;

  // encrypt file?
  SkipFile := True;
  if (EncryptFiles) then
    DoOnPassword(StartPath+name, Password, SkipFile);
  if (SkipFile) then
   Password := '';

  fs := TESFSFileStream.Create(self, name, fmCreate, password);
  fs.OnProgress := DoOnFileProgress;
  fs.LoadFromFile(StartPath+name);
  FileSetAttr(name,SysUtils.FileGetAttr(StartPath+name));
  fs.Free;
  Handle := FileOpen(Name, fmOpenReadWrite);
  FileSetDate(Handle, SysUtils.FileAge(StartPath + Name));
  FileClose(Handle);
 end; // ImportFile


 // process files
 procedure ProcessFiles(Path: AnsiString);
 var sr: TSearchRec;
{$IFDEF D12H}
     s:  AnsiString;
{$ENDIF}
 begin
  FCancel := false;
  if (SysUtils.FindFirst(Path+Mask,Attr,sr) = 0) then
   begin
    repeat
{$IFDEF D12H}
     s := sr.Name;
{$ENDIF}
     if ((sr.Name = '..') or (sr.Name = '.')) then continue;
      if ((sr.Attr and (not Attr and faSpecial)) = 0) then
{$IFDEF D12H}
       if (IsStrMatchPattern(pAnsiChar(s),pAnsiChar(Mask),true)) then
{$ELSE}
       if (IsStrMatchPattern(pAnsiChar(sr.Name),pAnsiChar(Mask),true)) then
{$ENDIF}
        if ((sr.Attr and faDirectory) = 0) then
         begin
          // file matching search conditions
          inc(result);
          FileList.Add(sr.Name);
          if (Path = StartPath) then
           PathList.Add('')
          else
           PathList.Add(Copy(Path,Length(startPath)+1,Length(Path)-Length(startPath)));
         end;
     // recursive search - directory found
     if ((sr.Attr and faDirectory) <> 0) then
      if (bRecursive) then
       begin
        // directory mathing search conditions
        if (Path = StartPath) then
         PathList.Add(sr.Name+'\')
        else
         PathList.Add(
           Copy(Path,Length(startPath)+1,Length(Path)-Length(startPath))+
           sr.Name+'\'
           );
        FileList.Add('');
        ProcessFiles(Path+sr.Name+'\');
       end;
    until (SysUtils.FindNext(sr) <> 0);
   end;
  SysUtils.FindClose(sr);
 end; // ProcessFiles

begin
 // ImportFiles
 result := 0;
 OldPath := GetCurrentDir;
 if (DestPath <> '') then
  begin
   ForceDirectories(DestPath);
   if (not SetCurrentDir(DestPath)) then
    begin
     SetCurrentDir(OldPath);
     Exit;
    end;
  end;
 FCancel := false;
 FProgress := 0;
 DoOnProgress(0);
 FileList := TStringList.Create;
 PathList := TStringList.Create;
 Mask := ExtractFileName(SourcePath);
 if (Mask = '') then
  Mask := '*.*';
 StartPath := ExtractFilePath(SourcePath);
 if (StartPath <> '') then
  if (not aaDirectoryExists(StartPath)) then
   Exit;
 ProcessFiles(StartPath);
 FProgressMax := FileList.Count;
 for i := 0 to FileList.Count-1 do
  begin
   try
    Result := i+1;
    ImportFile;
   except
    FCancel := True;
   end;
   FProgress := i+1;
   DoOnProgress(Round(FProgress/FProgressMax*100.0));
   if (FCancel) then break;
  end;
 PathList.Free;
 FileList.Free;
 DoOnProgress(100.0);
 if (DestPath <> '') then
  SetCurrentDir(OldPath);
end;// ImportFiles


//------------------------------------------------------------------------------
// import folder with all its content
// returns number of files imported
//------------------------------------------------------------------------------
function TESingleFileSystem.ImportFolder(
                         SourcePath:    AnsiString;
                         DestPath:      AnsiString = ''; // current dir
                         bRecursive:    Boolean = true;
                         OverwriteMode: TESFSOverwriteMode = omPrompt;
                         EncryptFiles:  Boolean = False
                         ): Integer;
var OldPath,s: AnsiString;
begin
 result := 0;
 if (not aaDirectoryExists(SourcePath)) then
  Exit;
 OldPath := GetCurrentDir;
 if (DestPath <> '') then
  begin
   ForceDirectories(DestPath);
   if (not SetCurrentDir(DestPath)) then
    begin
     SetCurrentDir(OldPath);
     Exit;
    end;
  end;

 s := ExtractFileName(aaExcludeTrailingBackslash(SourcePath));
 if (not DirectoryExists(s)) then
  if (not CreateDir(s)) then
   begin
    SetCurrentDir(OldPath);
    Exit;
   end;
 if (not SetCurrentDir(s)) then
  begin
   SetCurrentDir(OldPath);
   Exit;
  end;
 result := ImportFiles(aaIncludeTrailingBackslash(SourcePath)+'*.*',
           '',faAnyFile,bRecursive,OverwriteMode, EncryptFiles);
 SetCurrentDir(OldPath);
end; //ImportFolder


//------------------------------------------------------------------------------
// Exports files from specified path to current directory
//------------------------------------------------------------------------------
function TESingleFileSystem.ExportFiles(
                         SourcePath:    AnsiString;
                         DestPath:      AnsiString = ''; // current dir
                         Attr:          Integer = faAnyFile;
                         bRecursive:    Boolean = true;
                         OverwriteMode: TESFSOverwriteMode = omPrompt
                         ): Integer;
const
  faSpecial = faHidden or faSysFile or faVolumeID or faDirectory;

 var FileList:  TStringList;
     PathList:  TStringList;
     Mask:      AnsiString;
     StartPath: AnsiString;
     i:         Integer;
     OldPath:   AnsiString;


 // progress event

 procedure ExportFile;
 var fs: TESFSFileStream;
     name:  AnsiString;
     bOverwrite:   Boolean;
     Handle: Integer;
 begin
  name := aaIncludeTrailingBackslash(SysUtils.GetCurrentDir)+
                      aaExcludeTrailingBackslash(PathList.Strings[i]);

  aaForceDirectories(name);
  if (FileList.Strings[i] = '') then
   Exit;
  name := PathList.Strings[i]+FileList.Strings[i];
  bOverwrite := false;
  if (SysUtils.FileExists(name)) then
   begin
     if (OverwriteMode = omNever) then
      Exit;
      if (
     //(OverwriteMode = omAlways) or
      (OverwriteMode = omPrompt)) then
    begin
     DoOnOverwritePrompt(name,StartPath+FileList.Strings[i],bOverwrite);
     if (not bOverwrite) then
      Exit;
    end;
    // delete existing read-only files
    SysUtils.FileSetAttr(name, 0);
    SysUtils.DeleteFile(PAnsiChar(name));
   end; // file already exists

  FCurrentFileName := name;
  fs := TESFSFileStream.Create(self,StartPath+name,fmOpenRead, password);
  try
   fs.OnProgress := DoOnFileProgress;
   if (SysUtils.FileExists(name)) then
    SysUtils.DeleteFile(name);

   if (SysUtils.FileExists(name)) then
    raise Exception.Create('Error in TESingleFileSystem.ExportFiles - file '+
     AnsiQuotedStr(SysUtils.GetCurrentDir+'\'+name,'''')+' cannot be overwritten.');
   fs.SaveToFile(name);
   SysUtils.FileSetAttr(name,FileGetAttr(StartPath+name));
   Handle := SysUtils.FileOpen(Name, fmOpenReadWrite);
   SysUtils.FileSetDate(Handle, FileAge(StartPath + Name));
   SysUtils.FileClose(Handle);
  finally
   fs.Free;
  end;
 end; // ExportFile


 // process files
 procedure ProcessFiles(Path: AnsiString);
 var sr: TSearchRec;
{$IFDEF D12H}
     s:  AnsiString;
{$ENDIF}
 begin
  FCancel := false;
  if (FindFirst(Path+Mask,Attr,sr) = 0) then
   try
    repeat
{$IFDEF D12H}
     s := sr.Name;
{$ENDIF}
     if ((sr.Name = '..') or (sr.Name = '.')) then continue;
      if ((sr.Attr and (not Attr and faSpecial)) = 0) then
{$IFDEF D12H}
       if (IsStrMatchPattern(pAnsiChar(s),pAnsiChar(Mask),true)) then
{$ELSE}
       if (IsStrMatchPattern(pAnsiChar(sr.Name),pAnsiChar(Mask),true)) then
{$ENDIF}
        if ((sr.Attr and faDirectory) = 0) then
         begin
          // file matching search conditions
          inc(result);
          FileList.Add(sr.Name);
          if (Path = StartPath) then
           PathList.Add('')
          else
           PathList.Add(Copy(Path,Length(startPath)+1,Length(Path)-Length(startPath)));
         end;
     // recursive search - directory found
     if ((sr.Attr and faDirectory) <> 0) then
      if (bRecursive) then
       begin
        // directory mathing search conditions
        if (Path = StartPath) then
         PathList.Add(sr.Name+'\')
        else
         PathList.Add(
           Copy(Path,Length(startPath)+1,Length(Path)-Length(startPath))+
           sr.Name+'\'
           );
        FileList.Add('');
        ProcessFiles(Path+sr.Name+'\');
       end;
    until (FindNext(sr) <> 0);
   finally
    FindClose(sr);
   end;
 end; // ProcessFiles

begin
 // ExportFiles
 result := 0;
 OldPath := SysUtils.GetCurrentDir;
 if (DestPath <> '') then
  begin
   aaForceDirectories(DestPath);
   if (not SysUtils.SetCurrentDir(DestPath)) then
    begin
     SysUtils.SetCurrentDir(OldPath);
     Exit;
    end;
  end;

 FCancel := false;
 FProgress := 0;
 DoOnProgress(0);
 Mask := ExtractFileName(SourcePath);
 if (Mask = '') then
  Mask := '*.*';
 StartPath := ExtractFilePath(SourcePath);
 if (StartPath <> '') then
  if (not DirectoryExists(aaExcludeTrailingBackslash(StartPath))) then
    Exit;
 FileList := TStringList.Create;
 PathList := TStringList.Create;
 try
  ProcessFiles(StartPath);
  FProgressMax := FileList.Count;
  for i := 0 to FileList.Count-1 do
   begin
    ExportFile;
    FProgress := i+1;
    DoOnProgress(Round(FProgress/FProgressMax*100.0));
    if (FCancel) then break;
   end;
 finally
  PathList.Free;
  FileList.Free;
  if (DestPath <> '') then
   SysUtils.SetCurrentDir(OldPath);
 end;
 DoOnProgress(100.0);
end;// ExportFiles


//------------------------------------------------------------------------------
// Export folder with all its content
// returns number of files Exported
//------------------------------------------------------------------------------
function TESingleFileSystem.ExportFolder(
                         SourcePath:    AnsiString;
                         DestPath:      AnsiString = ''; // current dir
                         bRecursive:    Boolean = true;
                         OverwriteMode: TESFSOverwriteMode = omPrompt
                         ): Integer;
var OldPath,s: AnsiString;
begin
 result := 0;
 if (not DirectoryExists(SourcePath)) then
  Exit;
 OldPath := SysUtils.GetCurrentDir;
 if (DestPath <> '') then
  begin
   aaForceDirectories(DestPath);
   if (not SysUtils.SetCurrentDir(DestPath)) then
    begin
     SysUtils.SetCurrentDir(OldPath);
     Exit;
    end;
  end;

 if (not self.DirectoryExists(SourcePath)) then
   begin
    SysUtils.SetCurrentDir(OldPath);
    Exit;
  end;

 s := ExtractFileName(aaExcludeTrailingBackslash(SourcePath));
 if (s <> '') and (s <> '/') and (s <> '\') then
  if (not aaDirectoryExists(s)) then
    SysUtils.CreateDir(s); 
{
// commented in 2.20 - 29 April 2005
 if (not SysUtils.CreateDir(s)) then
   begin
    SysUtils.SetCurrentDir(OldPath);
    Exit;
  end;
}
 if (not SysUtils.SetCurrentDir(s)) then
  begin
   SysUtils.SetCurrentDir(OldPath);
   Exit;
  end;
 result := ExportFiles(aaIncludeTrailingBackslash(SourcePath)+'*.*',
           '',faAnyFile,bRecursive,OverwriteMode);
 SysUtils.SetCurrentDir(OldPath);
end; //ExportFolder


//------------------------------------------------------------------------------
// returns true if directory is empty
//------------------------------------------------------------------------------
function TESingleFileSystem.IsFolderEmpty(Dir: AnsiString): Boolean;
var OldPath:  AnsiString;
    sr:       TSearchRec;
begin
 result := true;
 OldPath := GetCurrentDir;
 if (SetCurrentDir(Dir)) then
  begin
   if (FindFirst('*.*',faAnyFile,sr) = 0) then
    result := false;
  end;
 SetCurrentDir(OldPath);
end; //IsDirEmpty


//------------------------------------------------------------------------------
// deletes files from Path to current DestPath
// Path allows to use wildcards * and ?
// returns number of files deleted
//------------------------------------------------------------------------------
function TESingleFileSystem.DeleteFiles(
                         Path:    AnsiString;
                         Attr:    Integer = faAnyFile;
                         bRecursive: Boolean = true
                        ): Integer;
const
  faSpecial = faHidden or faSysFile or faVolumeID or faDirectory;

var
    Mask,StartPath,
    SourcePath:     AnsiString;

 procedure ProcessFiles(Path: AnsiString);
 var sr: TSearchRec;
{$IFDEF D12H}
     s:  AnsiString;
{$ENDIF}
 begin
  FCancel := false;
  if (FindFirst(Path+Mask,Attr,sr) = 0) then
   begin
    repeat
      if ((sr.Attr and faDirectory) = 0) then
       begin
        // delete file
        if ((sr.Attr and (not Attr and faSpecial)) = 0) then
        begin
{$IFDEF D12H}
         s := sr.Name;
         if (IsStrMatchPattern(pAnsiChar(s),pAnsiChar(Mask),true)) then
{$ELSE}
         if (IsStrMatchPattern(pAnsiChar(sr.Name),pAnsiChar(Mask),true)) then
{$ENDIF}
          begin
           // file matching search conditions
           inc(result);
           DeleteFile(Path+sr.Name);
          end;
        end;
       end
      else
       begin
        // directories
        if (bRecursive) then
         ProcessFiles(Path+sr.Name+'\');
        if (not RemoveDir(Path+sr.Name)) then
         raise Exception.Create('TESingleFileSystem.DeleteFiles - could not delete directory '''+
         Path+sr.Name+'''');
       end;
    until (FindNext(sr) <> 0);
   end;
  FindClose(sr);
 end; // ProcessFiles

begin
 // DeleteFiles
 result := 0;

 SourcePath := aaExcludeTrailingBackslash(Path);
 StartPath := ExtractFilePath(SourcePath);
 Mask := ExtractFileName(SourcePath);
 if (Mask = '') then
  Mask := '*.*';
 ProcessFiles(StartPath);
end; //DeleteFiles


//------------------------------------------------------------------------------
// deletes folder with all its content to DestPath
// returns number of files exported
//------------------------------------------------------------------------------
function TESingleFileSystem.DeleteFolder(
                         Dir:    AnsiString
                         ): Integer;
var oldPath: AnsiString;
begin
 result := 0;
 if (not DirectoryExists(Dir)) then
  Exit;
 if (IsFolderEmpty(Dir)) then
  begin
   RemoveDir(Dir);
   Exit;
  end;
 oldPath := GetCurrentDir;
 result := DeleteFiles(aaIncludeTrailingBackslash(Dir)+'*.*');
 RemoveDir(Dir);
 SetCurrentDir(oldPath);
end; //DeleteFolder


//------------------------------------------------------------------------------
// runs application stored inside the ESFS file
//------------------------------------------------------------------------------
function TESingleFileSystem.RunApplication(FileName: AnsiString; Parameters: String='';
                                          Directory: String='';
                                          ShowCmd: Integer=SW_SHOWNORMAL): Boolean;
var s1,s: AnsiString;
begin
 Result := false;
 if (not self.FileExists(FileName)) then
  Exit;
 s := GetTemporaryDirectory;
 s1 := s + ExtractFileName(FileName);
 try
 self.ExportFiles(FileName,s,fmCreate,false,omAlways);
 except
   Exit;
 end;
 if (not SysUtils.FileExists(s1)) then
  Exit;
 if (Directory <> '') then
  s := Directory;
 result := ShellExecute(0,'Open',pAnsiChar(s1),PAnsiChar(Parameters),
                        pAnsiChar(s), ShowCmd) <> 0;
end; // RunApplication



//------------------------------------------------------------------------------
// runs application stored inside the ESFS file
//------------------------------------------------------------------------------
function TESingleFileSystem.LoadLibrary(FileName: AnsiString): Integer;
var s1,s: AnsiString;
begin
 Result := 0;
 if (not self.FileExists(FileName)) then
  Exit;
 s := GetTemporaryDirectory;
 s1 := s + ExtractFileName(FileName);
 try
 self.ExportFiles(FileName,s,fmCreate,false,omAlways);
 except
  Exit;
 end;
 if (not SysUtils.FileExists(s1)) then
  Exit;
 result := Windows.LoadLibraryA(PAnsiChar(s1));
end; // LoadDLL


//------------------------------------------------------------------------------
// loads ESFS file from stream
//------------------------------------------------------------------------------
procedure TESingleFileSystem.LoadFromStream(Stream: TStream);
begin
 if (FReadOnly) then
  raise Exception.Create('TESingleFileSystem.LoadFromStream - file is in read only mode!');
 InternalReopen(Stream);
end;


procedure TESingleFileSystem.LoadFromFile(const FileName: AnsiString);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, sysUtils.fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

{$ENDIF}

procedure TESingleFileSystem.SaveToStream(Stream: TStream);
begin
 PFMHandle.ESFSFile.SaveToStream(Stream);
end;


procedure TESingleFileSystem.SaveToFile(const FileName: AnsiString);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
end;


//------------------------------------------------------------------------------
// rename esfs files
//------------------------------------------------------------------------------
function RenameESFS(const OldName, NewName: AnsiString): Boolean;
var
  hf: TESFSHugeFile;
begin
 hf := TESFSHugeFile.Create(OldName, false, true, false);
 hf.Close;
 result := hf.RenameFile(NewName);
 hf.Free;
end;// RenameESFS


//------------------------------------------------------------------------------
// copy esfs files
//------------------------------------------------------------------------------
function CopyESFS(const OldName, NewName: AnsiString): Boolean;
var
  hf: TESFSHugeFile;
begin
 hf := TESFSHugeFile.Create(OldName, false, true, false);
 hf.Close;
// result := true;
 result := hf.CopyFile(NewName);
 hf.Free;
end;// RenameESFS


//------------------------------------------------------------------------------
// delete esfs files
//------------------------------------------------------------------------------
function DeleteESFS(const FileName: AnsiString): Boolean;
var
  hf: TESFSHugeFile;
begin
 hf := TESFSHugeFile.Create(FileName, false, true, false);
 hf.Close;
 result := hf.DeleteFile;
 hf.Free;
end;// DeleteESFS


//------------------------------------------------------------------------------
// returns true if this file is a ESFS file
//------------------------------------------------------------------------------
function IsESFSFile(const FileName: AnsiString): Boolean;
var
  hf: TESFSHugeFile;
begin
// hf := TESFSHugeFile.Create(FileName, false, true, false);
 hf := TESFSHugeFile.Create(FileName, true, false, false);
 result := hf.Open(false,false);
 hf.Close;
 hf.Free;
end; //IsESFSFile


//------------------------------------------------------------------------------
// makes SFX from ESFS file
//------------------------------------------------------------------------------
procedure MakeSFX(ESFSFileName, SFXStubFileName, SFXFileName: AnsiString);
var
 hESFS: TESFSHugeFile;
 StubStream, DestStream: TFileStream;
begin
  if (SFXStubFileName = '') then
   raise Exception.Create('MakeSFX - SFXStub file name is blank');
  if (not FileExists(SFXStubFileName)) then
   raise Exception.Create('MakeSFX - Cannot open file '+SFXStubFileName);
  if (not FileExists(ESFSFileName)) then
   raise Exception.Create('MakeSFX - Cannot open file '+ESFSFileName);

  hESFS := nil;
  StubStream := nil;
  DestStream := nil;
  try
   // open ESFS
   hESFS := TESFSHugeFile.Create(ESFSFileName, true, false, false);
   if (not hESFS.Open(false,false)) then
    raise Exception.Create('MakeSFX - Cannot open file '+ESFSFileName);

   // open stub
   StubStream := TFileStream.Create(SFXStubFileName, fmOpenRead or fmShareDenyNone);
   // open destination SFX
   DestStream := TFileStream.Create(SFXFileName, fmCreate);
   // copy stub
   DestStream.CopyFrom(StubStream, StubStream.Size);
   // append ESFS
   hESFS.SaveToStream(DestStream);
  finally
   if (hESFS <> nil) then
    begin
     hESFS.Close;
     hESFS.Free;
    end;
   StubStream.Free;
   DestStream.Free;
  end;
end; //MakeSFX


//------------------------------------------------------------------------------
// returns true and restores password if control answer is valid
//------------------------------------------------------------------------------
function RestorePasswordByControlAnswer(FileName: AnsiString; Answer: AnsiString; var Password: AnsiString): Boolean;
var PFMHandle: TPageFileManager;
begin
 result := true;
 PFMHandle := TPageFileManager.Create(FileName,fmOpenRead,Password,'','');
 if (PFMHandle.FHeader.EncMethod <> EncNone) then
  if (not CheckAnswer(PFMHandle.FHeader.PasswordHeader,Answer,Password)) then
   result := false;
 PFMHandle.Free;
end; // RestorePasswordByControlAnswer


//------------------------------------------------------------------------------
// returns true if Single file password is valid
//------------------------------------------------------------------------------
function IsPasswordValid(FileName: AnsiString; Password: AnsiString): Boolean;
var PFMHandle: TPageFileManager;
    Key: AnsiString;
begin
 result := true;
 PFMHandle := TPageFileManager.Create(FileName,fmOpenRead,Password);
 if (PFMHandle.FHeader.EncMethod <> EncNone) then
  if (not CheckPassword(PFMHandle.FHeader.PasswordHeader,Password,Key)) then
   result := false;
 PFMHandle.Free;
end; //IsPasswordValid


//------------------------------------------------------------------------------
// returns control question
//------------------------------------------------------------------------------
function GetControlQuestion(FileName: AnsiString): AnsiString;
var PFMHandle: TPageFileManager;
begin
 result := '';
 PFMHandle := TPageFileManager.Create(FileName,fmOpenRead);
 if (PFMHandle.FHeader.EncMethod <> EncNone) then
  if (PFMHandle.FHeader.PasswordHeader.PassCRC <> 0) then
   result := DecryptQuestion(PFMHandle.FHeader.PasswordHeader);
 PFMHandle.Free;
end; //GetControlQuestion


//------------------------------------------------------------------------------
// returns true if file is encrypted by its own password
//------------------------------------------------------------------------------
function IsSingleFileEncrypted(FileName: AnsiString): boolean;
var PFMHandle: TPageFileManager;
begin
 result := false;
 PFMHandle := TPageFileManager.Create(FileName,fmOpenRead);
 if (PFMHandle.FHeader.EncMethod <> EncNone) then
   result := true;
 PFMHandle.Free;
end; //IsFileEncrypted


//------------------------------------------------------------------------------
// returns temporary directory
//------------------------------------------------------------------------------
function GetTemporaryDirectory: AnsiString;
var
  TempPath : array[0..255] of AnsiChar;
begin
  // get temp file name
  Windows.GetTempPathA(255, @TempPath);
  Result := TempPath;
end; // GetTemporaryDirectory


{$IFDEF FULL_VERSION}
{$IFDEF NAG_SCREEN}
//------------------------------------------------------------------------------
// callback function to enumerate all open windows
//------------------------------------------------------------------------------
Function ESFSWindowCallback(WHandle : HWnd; Var Parm : Pointer) : Boolean;
          stdcall;
{This function is called once for each window}
 Var MyString : PAnsiChar;
begin

    {Window text}
    MyString := Allocmem(255);
    GetWindowTextA(WHandle,MyString,255);
    TStringList(Parm).Add(MyString);
    FreeMem(MyString,255);
    Result := True; {Everything's okay. Continue to enumerate windows}
end;

var
    WindowLst: TStringList;
    IsIDERunning: boolean;
    IsDelphiOrBuilderInstalled: boolean;
    i: integer;
    capt,msg: AnsiString;
    Reg: TRegistry;

initialization
  WindowLst := TStringList.Create;
  EnumWindows(@ESFSWindowCallback,Longint(@WindowLst));
  // IDE detection
  IsIDERunning := false;
  for i:=0 to WindowLst.Count-1 do
    if ((Pos('Delphi',WindowLst[i]) = 1) or
        (Pos('Borland',WindowLst[i]) > 0) or
        (Pos('CodeGear',WindowLst[i]) > 0) or
        (Pos('RAD Studio',WindowLst[i]) > 0) or
        (Pos('Embarcadero',WindowLst[i]) > 0) or
        (Pos('Highlander',WindowLst[i]) > 0) or
        (Pos('C++Builder',WindowLst[i]) = 1)) then
       begin
       IsIDERunning := true;
       break;
      end;
  // Delphi/Builder installation detection
  Reg:=TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  if ((Reg.KeyExists('\Software\Borland\Delphi')) or
      (Reg.KeyExists('\Software\Borland\BDS')) or
      (Reg.KeyExists('\Software\Embarcadero\BDS')) or
      (Reg.KeyExists('\Software\CodeGear\BDS')) or
      (Reg.KeyExists('\Software\Borland\C++Builder'))) then
    IsDelphiOrBuilderInstalled := true
  else
    IsDelphiOrBuilderInstalled := false;
  Reg.Free;
  // nag screen
  if ((not IsIDERunning) or (not IsDelphiOrBuilderInstalled)) then
     begin
capt := 'Single File System Trial - v.'+FormatFloat('0.00',ESFSEngine.ESFSCurrentVersion);
msg :=
             'This is the full functional trial version of Single File System by'#13+
             'AidAim Software (c) 2000-2011.'#13#13+
						 'This screen is created to remind you that your free version is'#13+
             'provided to you for evaluation purposes only.'#13+
             'If you don''t want to see this screen any more, or if you intend'#13+
             'to create a commercial product, please, register and download'#13+
             'the appropriate version of this component at https://aidaim.com'#13+
             'Also visit our site for all the new versions of our products.'#13#13+
             'Should you have any questions or problems with our product,'#13+
             'be sure to contact us at https://aidaim.com/help_osticket/';
{$IFDEF D12H}
      MessageBoxW(0,PChar(@msg[1]), PChar(@capt[1]),

{$ELSE}
      MessageBoxA(0,PAnsiChar(@msg[1]), PAnsiChar(@capt[1]),
{$ENDIF}
						 MB_OK+MB_ICONINFORMATION+MB_DEFBUTTON1);
     end;
   WindowLst.Free;
{$ENDIF}
{$ENDIF}


end.

