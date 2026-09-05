unit ACRDiskEngine;

interface

{$I ACRVer.inc}

uses SysUtils, Classes,
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
{$IFDEF LINUX}
  Types,
  Libc,
{$ENDIF}
  Math,

  // Accuracer units
{$IFDEF DEBUG_LOG}
  ACRDebug,
{$ENDIF}
{$IFDEF LINUX}
  ACRLinux,
{$ENDIF}
{$IFNDEF D6H}
  ACRD4Routines,
{$ENDIF}
{$IFDEF D12H}
  ACR_d12h,
{$ENDIF}
  ACRDatabaseFile,
  ACRCriticalSection,
  ACRCrypto,
  ACRExcept,
  ACRBase,
  ACRBaseEngine,
  ACRExpressions,
  ACRPage,
  ACRCompression,
  ACRTypes,
  ACRConverts,
  ACRVariant,
  ACRLexer, // for stored functions
  ACRConst,
  ACRStoredFunctions;

type

  // forward decls
  TACRTableLockFile = class;
  TACRDiskPageManager = class;
  TACRDiskTableData = class;
  TACRSystemDirectory = class;
  TACRActiveSessionFile = class;
  TACRTableListFile = class;
  TACRInternalDBFile = class;
  TACRDiskStoredFunctionManager = class;

////////////////////////////////////////////////////////////////////////////////
//
// TACRDiskDatabaseData
// changed in v.5
//
////////////////////////////////////////////////////////////////////////////////

  TACRDiskDatabaseData = class(TACRDatabaseData)
  private
    FSystemDir: TACRSystemDirectory;
    FActiveSessionsFile: TACRActiveSessionFile;
    FTableListFile: TACRTableListFile;
    FOptions: TACROptions;
    FCryptoParams: TACRCryptoParams;

    procedure OpenDatabase(Session: TACRBaseSession);
    procedure CloseDatabase(Session: TACRBaseSession);
  public
    constructor Create;
    destructor Destroy; override;
    // database operations
    procedure CreateDatabase(Session: TACRBaseSession); override;
    procedure ConnectSession(Session: TACRBaseSession); override;
    procedure DisconnectSession(Session: TACRBaseSession); override;
    procedure FreeIfNoSessionsConnected; override;
    // find or create table data
    function CreateTableData(Cursor: TACRCursor): TACRTableData; override;
    // database operations
    procedure GetTablesList(Session: TACRBaseSession; List: TACRWideStringList); override;
    function GetTablesInfo(SortByTableName: Boolean = True): TACRTableInfoArray; override;
    function GetTableState(TableName: WideString): TACRTableState; override;
    function GetTableItemIfExists(TableNameCRC: Cardinal; TableName: WideString;
                                  var TableItem: TACRTableListItem): Boolean;  overload;
    function GetTableItemIfExists(TableNameCRC: Cardinal; TableName: WideString;
                                  var TableItem: TACRTableListItem; var Comment: WideString): Boolean; overload;
    function GetTableItemIfExists(TableNameCRC: Cardinal; TableName: WideString;
                                  var TableItem: TACRTableListItem; out ItemIndex: Integer): Boolean; overload;
    procedure UpdateTableItem(const ItemIndex: Integer; const TableItem: TACRTableListItem;
                              const Comment: WideString);
    function TableExists(Session: TACRBaseSession; TableName: WideString): Boolean; override;
    // lock tables (virtual object)
    function InternalLockTableList(Exclusive: Boolean): Boolean;
    // unlock tables (virtual object)
    function InternalUnlockTableList: Boolean;
    // flush file buffers
    procedure FlushFileBuffers; override;
    // return database format version
    function GetFormatVersion(Session: TACRBaseSession): Double; override;
    // return total number of pages
    function GetTotalPageCount(Session: TACRBaseSession): Integer; override;
    // return number of free pages
    function GetFreePageCount(Session: TACRBaseSession): Integer; override;
    // return true if database is encrypted
    function IsDatabaseEncrypted(Session: TACRBaseSession): Boolean; override;
    // return true if database is encrypted by password or by key
    function IsDatabaseEncryptedByPassword(Session: TACRBaseSession): Boolean;
      override;
    // makes Exe database from edb file
    procedure MakeExeDatabase(Session: TACRBaseSession; ExeFileName, ExeDatabaseFileName: WideString); override;
    // removes database file from executable database file
    procedure RemoveDatabaseFromExe(Session: TACRBaseSession); override;
    // returns true if this file is an Accuracer database
    function IsAccuracerDatabaseFile(Session: TACRBaseSession): Boolean; override;
    // return true if CryptoParams are valid
    function IsCryptoParamsValid(Session: TACRBaseSession): Boolean; override;
    // load table state
    function LoadTableState(const TableItem: TACRTableListItem): TACRTableState;
    // save table state
    procedure SaveTableState(const TableItem: TACRTableListItem; const TableState: TACRTableState);
    // return table comment if table exists, otherwise empty string
    function GetTableComment(TableName: WideString): WideString; override;
    // set table comment
    procedure SetTableComment(TableName, Comment: WideString); override;
    //------------------------- VIEWS - added in v.6.00 ------------------------
    // create view
    procedure CreateView(
                         Session:           TACRBaseSession;
                         ViewName:          WideString;
                         ViewDef:           TACRViewDef
                        ); override;
    // drop view
    procedure DropView(
                         Session:           TACRBaseSession;
                         ViewName:          WideString;
                         bCascade:          Boolean = True
                      ); override;
    // return nil if not found, otherwise return view definition
    function FindView(
                         Session:           TACRBaseSession;
                         ViewName:          WideString
                     ): TACRViewDef; override;
    //--------------------- END OF VIEWS - added in v.6.00 ---------------------
  public
    property Options: TACROptions read FOptions write FOptions;
    property CryptoParams : TACRCryptoParams read FCryptoParams write FCryptoParams;
  end; // TACRDiskDatabaseData



////////////////////////////////////////////////////////////////////////////////
//
// TACRTablePageMapsManager
// stored in TACRTableMostUpdatedFile
//
////////////////////////////////////////////////////////////////////////////////

  TACRTablePageMapsManager = class(TObject)
  private
    LTableData: TACRDiskTableData;
    FPFSItemsPerPage: Word;
    FPageTypeOffset: Word;
    FRandomSearchRetryCount: Integer;
    // PFSMap file parameters:
    // the number of pages that is currently addressed by PFS map
    FPageCount: Integer;
    // number of PFS pages
    FTablePFSPageCount: Integer;
    // map of the PFS pages
    FTablePFSPageMapItems: array of TACRTablePFSPageMapItem;

  private
    procedure AddPFSPage(SessionID: TACRSessionID; PageNo: TACRPageNo);
    procedure SetPageType(SessionID: TACRSessionID; PageNo: TACRPageNo;
      TablePageType: TACRTablePageType);
    procedure SetPageRecordCount(SessionID: TACRSessionID; PageNo: TACRPageNo;
      PageRecordCount: Word; PageType: TACRTablePageType);
    function InternalGetPageType(PFSPage: TACRPage;
      RelativePageNo: TACRPageNo): TACRTablePageType;

    function GetPageRecordCount(SessionID: TACRSessionID;
      PageNo: TACRPageNo): Word;

    // find page in PFS page map
    function FindPageInPFSPage(PageData: PAnsiChar; MaxRelativePageNo: Integer;
      TablePageType: TACRTablePageType; Size: Word;
      out RelativePageNo: Integer; out PageRecordCount: Word): Boolean;
  public
    constructor Create(aTableData: TACRTableData;
      aRandomSearchRetryCount: Integer);
    destructor Destroy; override;
    function AddPage(SessionID: TACRSessionID;
      TablePageType: TACRTablePageType): TACRPage;
    procedure RemovePage(SessionID: TACRSessionID; PageNo: TACRPageNo;
      TablePageType: TACRTablePageType);
    // try to find a page for adding a small amount of data (< 1 page)
    // if failed performs add page
    function GetPageForAddingNewData(SessionID: TACRSessionID;
      TablePageType: TACRTablePageType; Size: Word; out PageRecordCount: Word)
      : TACRPage;

    function GetFirstRowBeginPageNo(SessionID: TACRSessionID): TACRPageNo;
    function GetLastRowBeginPageNo(SessionID: TACRSessionID): TACRPageNo;
    function GetNextRowBeginPageNo(SessionID: TACRSessionID;
      PageNo: TACRPageNo): TACRPageNo;
    function GetPriorRowBeginPageNo(SessionID: TACRSessionID;
      PageNo: TACRPageNo): TACRPageNo;

    function GetRecNoByRecordID(SessionID: TACRSessionID;
      RecordID: TACRRecordID): TACRRecordNo;
    function GetRecordIDByRecNo(SessionID: TACRSessionID;
      RecNo: TACRRecordNo): TACRRecordID;
    function GetRecordCount: TACRRecordNo;

    procedure Empty(SessionID: TACRSessionID);
    procedure LoadFileFromStream(Stream: TACRStream);
    procedure SaveFileToStream(Stream: TACRStream);

    procedure GetPageTypeAndRecordCount(SessionID: TACRSessionID;
      PageNo: TACRPageNo; out TablePageType: TACRTablePageType;
      out PageRecordCount: Word);
  public
    property PFSItemsPerPage: Word read FPFSItemsPerPage;
  end; // TACRTablePageMapsManager

////////////////////////////////////////////////////////////////////////////////
  //
  // TACRDiskRecordManager
  //
////////////////////////////////////////////////////////////////////////////////

  { TODO -oLeo :
    RecordManager is not thread safe - parallel use by multiple threads is impossible
    Fix in v.5 }

  { TODO : delete last record does not reset PFS map to empty }
  TACRDiskRecordManager = class(TACRBaseRecordManager)
  private
    FDiskRecordBuffer: TACRRecordBuffer;
    FTablePageMapsManager: TACRTablePageMapsManager;
    // LPageManager:          TACRDiskPageManager;
    LTableData: TACRDiskTableData;
    FDiskRecordBufferSize: Integer;
    FLargeRows: Boolean;
    FRecordsPerPage: Integer;
    FPageDataSize: TACRPageItemID;

    function LoadDataItemsMapFromPage(ErrorCode: Integer; Page: TACRPage;
      var ItemCount: Word): TACRDataItemsMap;

    procedure SaveDataItemsMapToPage(Page: TACRPage;
      ItemsMap: TACRDataItemsMap; ItemCount: Word);

    function GetFirstRecordOnPage(Page: TACRPage): TACRPageItemID;
    function GetLastRecordOnPage(Page: TACRPage): TACRPageItemID;
    function GetNextRecordOnPage(Page: TACRPage;
      PageItemNo: TACRPageItemID): TACRPageItemID;
    function GetPriorRecordOnPage(Page: TACRPage;
      PageItemNo: TACRPageItemID): TACRPageItemID;

    // return result for attempt of getting record relatively to first position
    // and set RecordID to new record ID
    function GetRecordFromFirstPosition(SessionID: TACRSessionID;
      GetRecordMode: TACRGetRecordMode; var RecordID: TACRRecordID)
      : TACRGetRecordResult;
    // return result for attempt of getting record relatively to last position
    // and set RecordID to new record ID
    function GetRecordFromLastPosition(SessionID: TACRSessionID;
      GetRecordMode: TACRGetRecordMode; var RecordID: TACRRecordID)
      : TACRGetRecordResult;
    // return result for attempt of getting record relatively any position
    // and set RecordID to new record ID
    function GetRecordFromAnyPosition(SessionID: TACRSessionID;
      GetRecordMode: TACRGetRecordMode; var RecordID: TACRRecordID)
      : TACRGetRecordResult;

    // convert data in the memory to disk record buffer
    // including varchars and blobs
    procedure GetDiskRecordBufferFromRecordBuffer(SessionID: TACRSessionID;
      RecordBuffer: TACRRecordBuffer);

    // copy data from disk record buffer to memory record buffer
    // including varchars and blobs
    procedure CopyDataFromDiskRecordBufferToMemoryRecordBuffer
      (SessionID: TACRSessionID; RecordBuffer: TACRRecordBuffer);

    procedure InternalWriteBLOBOrVarcharValue(SessionID: TACRSessionID;
      BLOBDescriptor: TACRPartialTemporaryBLOBDescriptor; PData: PAnsiChar;
      IsVarchar: Boolean; out RecordID: TACRRecordID);

    procedure WriteBLOBOrVarcharValue(SessionID: TACRSessionID;
      FieldDef: TACRFieldDef; RecordBuffer: TACRRecordBuffer);

    procedure InternalReadBLOBOrVarcharValue(SessionID: TACRSessionID;
      RecordID: TACRRecordID; IsVarchar: Boolean;
      var BLOBDescriptor: TACRPartialTemporaryBLOBDescriptor;
      var PData: PAnsiChar; out DataSize: Integer);

    procedure ReadBLOBOrVarcharValue(SessionID: TACRSessionID;
      FieldDef: TACRFieldDef; RecordBuffer: TACRRecordBuffer);

    procedure DeleteBLOBOrVarcharValue(SessionID: TACRSessionID;
      FieldDef: TACRFieldDef);

    // load record from disk into new allocated buffer
    procedure LoadDiskRecord(SessionID: TACRSessionID; RecordID: TACRRecordID;
      DiskRecordBuffer: TACRRecordBuffer);

    // load record from disk into new allocated buffer
    procedure InternalLoadDiskRecordLarge(SessionID: TACRSessionID;
      RecordID: TACRRecordID; DiskRecordBuffer: TACRRecordBuffer);

    // load record from disk into new allocated buffer
    procedure InternalLoadDiskRecordSmall(SessionID: TACRSessionID;
      RecordID: TACRRecordID; DiskRecordBuffer: TACRRecordBuffer);

    // return true if record exists
    function InternalIsRecordExistsLarge(SessionID: TACRSessionID;
      var RecordID: TACRRecordID): Boolean;

    // return true if record exists
    function InternalIsRecordExistsSmall(SessionID: TACRSessionID;
      var RecordID: TACRRecordID): Boolean;

    // add record and return its number (RecordSize > PageDataSize div 2)
    procedure InternalAddRecordLarge(RecordBuffer: TACRRecordBuffer;
      var RecordID: TACRRecordID;
      SessionID: TACRSessionID = INVALID_SESSION_ID);

    // add record and return its number (RecordSize <= PageDataSize div 2)
    procedure InternalAddRecordSmall(RecordBuffer: TACRRecordBuffer;
      var RecordID: TACRRecordID;
      SessionID: TACRSessionID = INVALID_SESSION_ID);
    // delete record (RecordSize <= PageDataSize div 2)
    procedure InternalDeleteRecordSmall(var RecordID: TACRRecordID;
      SessionID: TACRSessionID = INVALID_SESSION_ID);
    // delete record (RecordSize > PageDataSize div 2)
    procedure InternalDeleteRecordLarge(var RecordID: TACRRecordID;
      SessionID: TACRSessionID = INVALID_SESSION_ID);
    // update record (RecordSize > PageDataSize div 2)
    procedure InternalUpdateRecordLarge(RecordBuffer: TACRRecordBuffer;
      var RecordID: TACRRecordID;
      SessionID: TACRSessionID = INVALID_SESSION_ID);
    // update record (RecordSize <= PageDataSize div 2)
    procedure InternalUpdateRecordSmall(RecordBuffer: TACRRecordBuffer;
      var RecordID: TACRRecordID;
      SessionID: TACRSessionID = INVALID_SESSION_ID);
  public
    constructor Create(RecordBufferSize: Integer;
      DiskRecordBufferSize: Integer; aTableData: TACRDiskTableData);
    destructor Destroy; override;
    function GetRecordCount: TACRRecordNo; override;
    // empty table (delete all records)
    procedure Empty(SessionID: TACRSessionID = INVALID_SESSION_ID); override;
    // add record and return its number
    function AddRecord(RecordBuffer: TACRRecordBuffer;
      var RecordID: TACRRecordID;
      SessionID: TACRSessionID = INVALID_SESSION_ID)
      : Boolean; override;
    // update record, return true if record was updated, false if record was deleted
    function UpdateRecord(RecordBuffer: TACRRecordBuffer;
      RecordID: TACRRecordID;
      SessionID: TACRSessionID = INVALID_SESSION_ID): Boolean; override;
    // delete record, return true if record was deleted, false if record was deleted earlier
    function DeleteRecord(var RecordID: TACRRecordID;
      SessionID: TACRSessionID = INVALID_SESSION_ID): Boolean; override;
    // return true if record exists
    function IsRecordExists(var RecordID: TACRRecordID;
      SessionID: TACRSessionID = INVALID_SESSION_ID): Boolean;
      override;
    procedure GetRecordBuffer(var NavigationInfo: TACRNavigationInfo); override;
    // return record no
    function GetApproximateRecNo(RecordID: TACRRecordID;
      SessionID: TACRSessionID): TACRRecordNo; override;
    function GetRecNoByRecordID(RecordID: TACRRecordID;
      SessionID: TACRSessionID): TACRRecordNo;
    function GetRecordIDByRecNo(RecNo: TACRRecordNo;
      SessionID: TACRSessionID): TACRRecordID;
    procedure LoadTablePFSMapFromStream(Stream: TACRStream);
    procedure SaveTablePFSMapToStream(Stream: TACRStream);

  public
    property RecordsPerPage: Integer read FRecordsPerPage;
  end; // TACRDiskRecordManager

////////////////////////////////////////////////////////////////////////////////
  //
  // TACRDiskTableData
  // changed in v.5
  //
////////////////////////////////////////////////////////////////////////////////

  TACRDiskTableData = class(TACRAdvancedTableData)
  private
    FRandomSearchRetryCount: Integer;
    // FTableID is in FTableItem
    FTableItem: TACRTableListItem;
    LPageManager: TACRDiskPageManager;
    LDiskDatabaseData: TACRDiskDatabaseData;
    // Table MetaData and MostUpdatedData files
    FTableMetaDataFile: TACRInternalDBFile;
    FTableMostUpdatedFile: TACRInternalDBFile;
    FTableLockFile: TACRTableLockFile;

  protected
    function GetTableID: TACRObjectID; override;
    function GetPageManager: TACRPageManager; override;
  public
    // load table state
    function LoadTableState: TACRTableState; override;
  protected
    // save table state
    procedure SaveTableState; override;
    procedure CreateRecordManager; override;
    procedure CreateTableFiles;
    procedure DeleteTableFiles;
  protected
    procedure ReadTableMetadata(SessionID: TACRSessionID);
    procedure WriteTableMetadata(SessionID: TACRSessionID); override;
    procedure ReadMostUpdatedData(SessionID: TACRSessionID); override;
    procedure WriteMostUpdatedData(SessionID: TACRSessionID); override;

    procedure InternalRecreateTable(Cursor: TACRCursor;
      FieldDefs: TACRFieldDefs; IndexDefs: TACRIndexDefs;
      ConstraintDefs: TACRConstraintDefs);
  protected
    function CreateForeignKeyAction(Cursor: TACRCursor;
      ConstraintDef: TACRConstraintDefForeignKey;
      ReferencedTableName: WideString; ReferencedTableObjectID: TACRObjectID)
      : TACRConstraintDefForeignKeyAction; override;
  public
    procedure FreeIfNoSessionsConnected; override;
    constructor Create(aDiskDatabaseData: TACRDiskDatabaseData);
    destructor Destroy; override;

    function GetRecordSize: Integer;
    // table operations
    procedure CreateTable(Cursor: TACRCursor; FieldDefs: TACRFieldDefs;
      IndexDefs: TACRIndexDefs; ConstraintDefs: TACRConstraintDefs); override;
    procedure DeleteTable(Session: TACRBaseSession; Cascade: Boolean;
      DesignMode: Boolean = False); override;
    procedure AddForeignKey(Cursor: TACRCursor;
      ConstraintDef: TACRConstraintDefForeignKey); override;
    procedure DeleteConstraint(Cursor: TACRCursor; Name: WideString;
      Cascade: Boolean; FKPartialDelete: Boolean); override;
    procedure RenameReferenceTableName(Cursor: TACRCursor;
      OldName, NewName: WideString); override;

    procedure EmptyTable(Cursor: TACRCursor; SkipFKCheck: Boolean = False);
      override;
    procedure RenameTable(Cursor: TACRCursor; NewTableName: WideString);
      override;
    procedure LoadTableFromStream(Cursor: TACRCursor; Stream: TStream);
      override;
    procedure SaveTableToStream(Stream: TStream;
      CompressionAlgorithm: TACRCompressionAlgorithm = acaNone;
      CompressionMode: Byte = 0; BlockSize: Integer = 0;
      SkipCheckIsTableOpened: Boolean = False); override;
  private
    procedure OpenLocksFile;
    procedure InternalOpenTable(aSessionID: TACRSessionID);
    procedure InternalCloseTable(aSessionID: TACRSessionID);
  public
    procedure OpenTable(Cursor: TACRCursor); override;
    procedure CloseTable(Cursor: TACRCursor); override;

    // Rename Field by Field Index in FieldDefs
    procedure RenameField(Cursor: TACRCursor;
      FieldName, NewFieldName: WideString); override;

    procedure AddIndex(IndexDef: TACRIndexDef; Cursor: TACRCursor); override;
    procedure DeleteIndex(IndexID: TACRObjectID; Cursor: TACRCursor); override;
    procedure DeleteAllIndexes(Cursor: TACRCursor); override;

    //--------------------- not exclusive operations with records --------------

    // return 0 if id1 = id2, 1 if id1>id2, -1 if id1<id2
    function CompareRecordID(const RecordID1: TACRRecordID;
      const RecordID2: TACRRecordID): Integer; override;
    function InternalCreateBlobStream(Cursor: TACRCursor; ToInsert: Boolean;
      FieldNo: Integer; OpenMode: TACRBLOBOpenMode): TACRStream; override;
    procedure ClearBLOBFieldInRecordBuffer(var RecordBuffer: TACRRecordBuffer;
      FieldNo: Integer); override;
    // move cursor to specified position and set current record id in cursor
    procedure InternalSetRecNo(Cursor: TACRCursor; RecNo: TACRRecordNo);
      override;
    // get current record position from cursor
    function InternalGetRecNo(Cursor: TACRCursor): TACRRecordNo; override;
    // return size of the bitmap
    // function GetBitmapSize(Session: TACRSessionID): TACRRecordNo; override;
    // return filter bitmap rec no by record id
    function GetBitmapRecNoByRecordID(RecordID: TACRRecordID): TACRRecordNo;
      override;
    // return filter bitmap rec no by record id
    function GetRecordIDByBitmapRecNo(RecordNo: TACRRecordNo): TACRRecordID;
      override;
    //--------------------- not exclusive operations with records --------------
  end; // TACRDiskTableData


  ////////////////////////////////////////////////////////////////////////////////
  //
  // TACRDatabaseFreeSpaceManager
  // completely rewritten in v.5
  //
  ////////////////////////////////////////////////////////////////////////////////

  //------------------------------------------------------------------------------
  // | PFS | GAM | SGAM | Data | ... | PFS | Data | ... | PFS | GAM | SGAM | Data |
  //------------------------------------------------------------------------------
  // |  0  |  1  |   2  |   3  | ... | FHeader.TotalPageCount-1                   |
  //------------------------------------------------------------------------------

  // 1 extent = DBHeader.ExtentPageCount pages
  // PFS:  1 bit == 1 page,   bit 0 - empty page, 1 - used page
  // GAM:  1 bit == 1 extent, bit 0 - empty extent, 1 - used extent (fully or partially filled)
  // SGAM: 1 bit == 1 extent, bit 0 - mixed extent (partially filled), 1 - uniform extent
  // uniform extent - fully empty or fully filled
  // mixed extent - partially filled extent
  // SGAM always after GAM
  // GAM always after PFS

  TACRFreeSpaceManagerPageType = (fsmPFS, fsmGAM, fsmSGAM);

  TACRDatabaseFreeSpaceManager = class(TObject)
  private
    LPageManager: TACRDiskPageManager;
    FLockParams: TACRLockParams;
    FHeader: TACRFSMHeader;
    PFS: PAnsiChar; // Page Free Space bits
    GAM: PAnsiChar; // Global Allocation Map bits
    SGAM: PAnsiChar; // Shared Global Allocation Map bits
    // pointers to data buffe of the loaded pages
    PFSPage: TACRPage;
    GAMPage: TACRPage;
    SGAMPage: TACRPage;
    // number of pages addressed by single GAM page
    PagePerExt: TACRPageNo;
    // number of pages addressed by single PFS page
    PagePerPFSPage: TACRPageNo;
    PFSCount: TACRPageNo;
    GAMCount: TACRPageNo;
    ExtentPageCount: Word;
  public
    constructor Create(aPageManager: TACRDiskPageManager;
      aLockParams: TACRLockParams);
    destructor Destroy; override;
    procedure CreateFreeSpaceManager;
  private
    function IsFSMPage(PageNo: TACRPageNo): Boolean;
    procedure FindGAMPage(const PageNo: TACRPageNo; // page number to find GAM
      out GAMPageNo: TACRPageNo; // GAM page number
      out GAMBitNo: TACRPageNo // bit number inside GAM
      );
    procedure FindPFSPage(const PageNo: TACRPageNo; // page number to find PFS
      out PFSPageNo: TACRPageNo; // PFS page number
      out PFSBitNo: TACRPageNo // bit number inside PFS
      );
    procedure PutPages;
    procedure LoadPage(PageNo: TACRPageNo;
      PageType: TACRFreeSpaceManagerPageType; ReadPage: Boolean;
      UpdatePage: Boolean);
    function AppendNewPage: TACRPageNo;
    procedure CheckShrinking;
    function InternalGetPage: TACRPageNo;
    procedure InternalFreePage(PageNo: TACRPageNo);
    procedure InternalGetPages(
      // place page numbers of new allocated pages at the end of the array
      Pages: TACRPageArray;
      // how much pages to add
      const NumPagesToAdd: Cardinal;
      // pages must be in consecutive order (n,n+1,n+2...)
      const ConsecutiveOrder: Boolean);
    // remove all pages in the array by single operation
    procedure InternalFreePages(Pages: TACRPageArray;
      NumPagesFromEnd: Cardinal);
  public
    function GetPage: TACRPageNo;
    procedure FreePage(PageNo: TACRPageNo);
    // add multiple pages
    procedure GetPages(
      // place page numbers of new allocated pages at the end of the array
      Pages: TACRPageArray;
      // how much pages to add
      const NumPagesToAdd: Cardinal;
      // pages must be in consecutive order (n,n+1,n+2...)
      const ConsecutiveOrder: Boolean);
    // remove all pages in the array by single operation
    procedure FreePages(Pages: TACRPageArray; NumPagesFromEnd: Cardinal = 0);
  public
    property LockParams: TACRLockParams read FLockParams write FLockParams;
    property Header: TACRFSMHeader read FHeader write FHeader;
  end; // TACRDatabaseFreeSpaceManager

////////////////////////////////////////////////////////////////////////////////
  //
  // TACRDiskPageManager
  //
////////////////////////////////////////////////////////////////////////////////

  TACRDiskPageManager = class(TACRPageManager)
  private
    FDatabaseFileThreadSync: TACRReadWriteThreadSync;
    // FreeSpaceManager synchronization in exclusive multi-threaded mode
    FFSMThreadSync: TACRReadWriteThreadSync;
    // TableList synchronization in exclusive multi-threaded mode
    FTLThreadSync: TACRReadWriteThreadSync;
    FDatabaseFreeSpaceManager: TACRDatabaseFreeSpaceManager;
    FDatabaseFile: TACRDatabaseFile;
    FDBHeader: TACRDBHeader;
    // offsets in the physical order of the database file
    FOffsetToDBHeader: Int64;
    FOffsetToFSMHeader: Int64;
    FOffsetToTLHeader: Int64;
    FOffsetToSFMHeader: Int64; // -1 - if no Stored Function Manager
    FOffsetToLockedBytes: Int64;
    FOffsetToFirstPage: Int64;

    FLockParams: TACRLockParams;
    FCryptoInfo: TACRCryptoInfo;
{$IFDEF DEBUG_LOG}
    FTempPage: TACRPage;
{$ENDIF}
  private
    procedure InitDBHeader;
    procedure LoadDBHeader;
    procedure SaveDBHeader;
    procedure LoadFSMHeader(var FSMHeader: TACRFSMHeader);
    procedure SaveFSMHeader(var FSMHeader: TACRFSMHeader);
    procedure LoadTLHeader(var TLHeader: TACRTLHeader);
    procedure SaveTLHeader(var TLHeader: TACRTLHeader);
    procedure LoadSFMHeader(var SFMHeader: TACRSFMHeader);
    procedure SaveSFMHeader(var SFMHeader: TACRSFMHeader);
    function GetIsOpened: Boolean;
    function GetPageOffset(PageNo: TACRPageNo): Int64;
    function GetDatabaseFileName: WideString;
  protected
    procedure CheckFileSize;
    function GetPageCount: TACRPageNo; override;
    // lock
    procedure LockDatabaseFile;
    // unlock
    procedure UnlockDatabaseFile;
    procedure ReadPageRegion(var Buffer; PageNo: TACRPageNo;
      Offset, Count: Integer; DoNotEncrypt: Boolean);
    procedure WritePageRegion(const Buffer; PageNo: TACRPageNo;
      Offset, Count: Integer; DoNotEncrypt: Boolean);
    // Read Buffer
    procedure DirectReadBuffer(var Buffer; const Count: Int64;
      const Pos: Int64; ErrorCode: Integer);
    // Write Buffer
    procedure DirectWriteBuffer(const Buffer; const Count: Int64;
      const Pos: Int64; ErrorCode: Integer);
    function DirectIsRegionLocked(Offset: Int64; Count: Integer): Boolean;
    function DirectAddPage: TACRPageNo; override;
    // add multiple pages
    procedure DirectAddPages(
      // place page numbers of new allocated pages at the end of the array
      Pages: TACRPageArray;
      // how much pages to add
      const NumPagesToAdd: Cardinal;
      // pages must be in consecutive order (n,n+1,n+2...)
      const ConsecutiveOrder: Boolean); override;
    // remove all pages in the array by single operation
    procedure DirectRemovePages(Pages: TACRPageArray;
      NumPagesFromEnd: Cardinal = 0); override;

    procedure InitPage(aPage: TACRPage); override;
    procedure InternalAddPage(aPage: TACRPage); override;
    procedure InternalRemovePage(PageNo: TACRPageNo); override;
    // return true if page must not be encrypted even if database is encrypted
    function IsPageMustNotBeEncrypted(aPage: TACRPage): Boolean;
    procedure InternalReadPage(aPage: TACRPage); override;
    procedure InternalWritePage(aPage: TACRPage); override;

    function IsSystemPage(PageNo: TACRPageNo): Boolean; override;
    // lock Free Space Manager
    function LockFreeSpaceManager(Exclusive: Boolean): Boolean;
    // unlock Free Space Manager
    function UnlockFreeSpaceManager: Boolean;
    // lock Tables byte
    function InternalLockTableList(Exclusive: Boolean): Boolean;
    // unlock Tables byte
    function InternalUnlockTableList: Boolean;
    // lock Stored Function Manager
    function LockStoredFunctionManager(Exclusive: Boolean): Boolean;
    // unlock Stored Function Manager
    function UnlockStoredFunctionManager: Boolean;
    // Lock Byte (return TRUE if success)
    function LockPageByte(PageNo: TACRPageNo; Offset: Word;
      Exclusive: Boolean = True): Boolean;
    // Unlock Byte
    function UnlockPageByte(PageNo: TACRPageNo; Offset: Word;
      Exclusive: Boolean = True): Boolean;
    // return True if byte is locked
    function IsPageByteLocked(PageNo: TACRPageNo; Offset: Word): Boolean;
    // return True if any byte of region is locked
    function IsPageRegionLocked(PageNo: TACRPageNo; Offset: Word;
      Count: Word): Boolean;
  public
    constructor Create(aLockParams: TACRLockParams);
    destructor Destroy; override;
    procedure CreateAndOpenDatabase(DatabaseFileName: AnsiString;
      DatabaseFileNameUnicode: WideString; MaxSessionCount: Cardinal;
      PageSize: Word = ACRDefaultPageSize;
      ExtentPageCount: Word = ACRDefaultExtentPageCount;
      UnicodeNames: ByteBool = True);
    procedure OpenDatabase(DatabaseFileName: AnsiString;
      DatabaseFileNameUnicode: WideString;
      var aReadOnly: Boolean; aExclusive: Boolean = False;
      DoNotCheckPassword: Boolean = False);
    procedure CloseDatabase;
    procedure FlushFileBuffers; override;
    // extend file by number of pages specified by PageCount

    function GetOffsetToDBHeader: Int64;
    // returns true if this file is an Accuracer database
    function IsAccuracerDatabaseFile(DatabaseFileName: AnsiString;
      DatabaseFileNameUnicode: WideString): Boolean;
    procedure RemoveDatabaseFromExe(DatabaseFileName: AnsiString;
      DatabaseFileNameUnicode: WideString);
    function GetTotalPageCount: Integer;
    // return number of free pages
    function GetFreePageCount: Integer;
{$IFDEF DEBUG_PM_Test_State}
    function TestLoadState(PageNo: TACRPageNo; StateOnly: Boolean): Cardinal;
    procedure TestSaveState(PageNo: TACRPageNo; State: Cardinal;
      StateOnly: Boolean);
{$ENDIF}
  protected
    property DatabaseFileName: WideString read GetDatabaseFileName;
    property DBHeader: TACRDBHeader read FDBHeader;
    property IsOpened: Boolean read GetIsOpened;
    property OffsetToFirstPage: Int64 read FOffsetToFirstPage;
    property OffsetToLockedBytes: Int64 read FOffsetToLockedBytes;
    property OffsetToDBHeader: Int64 read FOffsetToDBHeader;
    property OffsetToSFMHeader: Int64 read FOffsetToSFMHeader;
    property LockParams: TACRLockParams read FLockParams write FLockParams;
    property CryptoInfo: TACRCryptoInfo read FCryptoInfo write FCryptoInfo;
  end; // TACRDiskPageManager

////////////////////////////////////////////////////////////////////////////////
  //
  // TACRInternalDBFile
  // class for managing internal data files
  // has no thread synchronization mechanisms
  // thread locking must be applied on higher level
  // files can be optionally compressed and read/write using DataStream property
  // files with direct access does not use DataStream
  // once file created it always has at least 1 page with file header
  // for external links
  //
////////////////////////////////////////////////////////////////////////////////

  TACRInternalDBFile = class(TObject)
  private
    LPageManager: TACRDiskPageManager;
    LCache: TACRCache;
    FDataStream: TACRMemoryStream;
    FStartPageNo: TACRPageNo;
    FPageTypeID: TACRPageTypeID;
    FObjectID: TACRObjectID; // reference to parent table (TableID) or INVALID_OBJECT_ID for database object
    FDirectAccess: Boolean;
    // if true file will be compressed when its size is larger than ACRMaxInternalFileNotCompressedSize
    FCompressed: Boolean;
    FPage: TACRPage; // temp page - used only when LCache = nil
    FExclusiveLock: Boolean;
    FPages: TACRPageArray;
    FSize: Cardinal; // size of [compressed] data stored inside file
    FTotalSize: Cardinal; // size of the data stored plus size of file header
    // for read / write compression
    FCryptoInfo: TACRCryptoInfo;
    // determines compression algorithm and mode
    FCompressionAlgorithm: TACRCompressionAlgorithm;
    FCompressionMode: Byte;
    FFileRead: Boolean; // size properties and pages array are set correctly
    FTempBuffer: PAnsiChar;
    FTempSize: Integer;
  private
    function GetPageOffset(Position: Int64): Word;
    function GetPageNo(Position: Int64): Integer;
    function InternalLockFile(Exclusive: Boolean = True): Boolean;
    function InternalUnlockFile(Exclusive: Boolean = True): Boolean;
    procedure CreatePage(var aPage: TACRPage);
    procedure PutPage(var aPage: TACRPage);
    procedure CompressDataStream;
    procedure DecompressDataStream;
    procedure CompressDataStreamFinish;
    procedure SetSize(NewSize: Cardinal; SessionID: TACRSessionID;
      // state type of the locked object that calls this method
      StateType: TACRDBStateType;
      // current state of the locked object that calls this method
      State: TACRState);
    procedure InitPageHeader(FirstPage: Boolean; NextPageNo: TACRPageNo);
  public
    // Constructor
    constructor Create(PageManager: TACRDiskPageManager;
      PageTypeID: TACRPageTypeID; ObjectID: TACRObjectID;
      // if true - direct access mode, FDataStream = nil
      bDirectAccess: Boolean;
      // if true and file size > PageDataSize -> data will be compressed
      bCompressed: Boolean;
      // if nil passed - LPageManager used in direct access mode
      // else Cache used for reading / writing data
      Cache: TACRCache);
    // Destructor
    destructor Destroy; override;
    // Create file and set FStartPageNo, FSize, FTotalSize, etc.
    procedure CreateFile(FileSize: Cardinal; SessionID: TACRSessionID;
      // state type of the locked object that calls this method
      StateType: TACRDBStateType;
      // current state of the locked object that calls this method
      State: TACRState);
    // Delete file. And free all file pages
    procedure DeleteFile(SessionID: TACRSessionID;
      // state type of the locked object that calls this method
      StateType: TACRDBStateType;
      // current state of the locked object that calls this method
      State: TACRState);
    // Open file (reading file header)
    procedure OpenFile(StartPageNo: TACRPageNo);
    procedure ReadFile(SessionID: TACRSessionID = INVALID_SESSION_ID;
      // state type of the locked object that calls this method
      StateType: TACRDBStateType = dbstNone;
      // current state of the locked object that calls this method
      State: TACRState = 0);
    procedure WriteFile(SessionID: TACRSessionID = INVALID_SESSION_ID;
      // state type of the locked object that calls this method
      StateType: TACRDBStateType = dbstNone;
      // current state of the locked object that calls this method
      State: TACRState = 0);
    procedure EmptyFile(SessionID: TACRSessionID = INVALID_SESSION_ID;
      // state type of the locked object that calls this method
      StateType: TACRDBStateType = dbstNone;
      // current state of the locked object that calls this method
      State: TACRState = 0);

    //------------------- lock functions ---------------------------------------
    // direct (without sessions and transactions) Read buffer from file
    procedure DirectReadBuffer(var Buffer; const Count: Integer;
      const Position: Integer; const DoNotEncrypt: Boolean);
    // direct (without sessions and transactions) Write buffer from file
    procedure DirectWriteBuffer(const Buffer; const Count: Integer;
      const Position: Integer; const DoNotEncrypt: Boolean);
    function LockFile(Exclusive: Boolean = True): Boolean;
    function UnlockFile(Exclusive: Boolean = True): Boolean;
    function LockByte(ByteNo: Integer): Boolean;
    function UnlockByte(ByteNo: Integer): Boolean;
    function IsByteLocked(ByteNo: Integer): Boolean;
    function IsRegionLocked(const Position: Integer;
      const Count: Integer): Boolean;
  public
    property Cache: TACRCache read LCache;
    property PageManager: TACRDiskPageManager read LPageManager;
    property StartPageNo: TACRPageNo read FStartPageNo;
    property Compressed: Boolean read FCompressed;
    property DataStream: TACRMemoryStream read FDataStream;
    property FileRead: Boolean read FFileRead write FFileRead;
    property Size: Cardinal read FSize write FSize;
    property TotalSize: Cardinal read FTotalSize write FTotalSize;
  end; // TACRInternalDBFile

////////////////////////////////////////////////////////////////////////////////
  //
  // TACRActiveSessionFile
  //
////////////////////////////////////////////////////////////////////////////////

  TACRActiveSessionFile = class(TObject)
  private
    LPageManager: TACRDiskPageManager;
    FHandle: TACRInternalDBFile;
    FLockParams: TACRLockParams;

  public
    constructor Create(PageManager: TACRPageManager;
      aLockParams: TACRLockParams);
    destructor Destroy; override;
    function CreateFile(aMaxSessionCount: Integer): TACRPageNo;
    procedure OpenFile(aStartPageNo: TACRPageNo);
    procedure CloseFile;
    function Connect: TACRSessionID;
    procedure Disconnect(SessionID: TACRSessionID);
    function IsAnySessionConnected: Boolean;
  public
    property LockParams: TACRLockParams read FLockParams write FLockParams;
    property Handle: TACRInternalDBFile read FHandle;
  end; // TACRActiveSessionFile

////////////////////////////////////////////////////////////////////////////////
  //
  // TACRTableListFile
  // rewritten in v.5
  //
////////////////////////////////////////////////////////////////////////////////

  // version 5:
  // table name is saved as a Unicode string
  // TableID on create table is the number of tables plus 1
  TACRTableListFile = class(TObject)
  private
    LPageManager: TACRDiskPageManager;
    FHandle: TACRInternalDBFile;
    FHeader: TACRTLHeader;
    FTableList: array of TACRTableListItem;
    FState: Cardinal; // last loaded state
    FNotLoaded: Boolean;
    // to protect FTableList
    FThreadSync: TACRReadWriteThreadSyncBySingleCriticalSection;
    // vairable for table state management
    FStatesPerPage: TACRPageItemID; // number of table states stored in 1 page
    FStateMapBytesPerPage: TACRPageItemID; // size in bytes of PFS map to address 1 page
    FStateMapSize: Cardinal; // size in bytes
    FStatePages: TACRPageArray; // numbers of pages of states map
    FStateMap: PAnsiChar; // 1 bit = 1 state for all state pages
    // bit 0 - not used
    // bit 1 - used
    FNames:     TACRObjectNameArray;
    FComments:  TACRObjectNameArray;
    FViews:     TACRViewDefs; // added in v.6.00;
  private
    function IndexOf(TableNameCRC: Cardinal; TableName: WideString; bIncludeViews: Boolean): Integer;
    procedure Lock;
    procedure Unlock;
{$IFDEF DEBUG_LOG}
    procedure WriteTableListToLog;
{$ENDIF}
    procedure SetStateMapSize;
    procedure CreateTableState(var TableItem: TACRTableListItem;
      const TableState: TACRTableState);
    procedure FreeTableState(var TableItem: TACRTableListItem);
    procedure LoadStateMap(Repair: Boolean = False);
    procedure Repair(numElements: Cardinal);
  public
    procedure Load;
    procedure Save;
    constructor Create(PageManager: TACRDiskPageManager);
    destructor Destroy; override;

    function CreateFile: TACRPageNo;
    procedure OpenFile(aStartPageNo: TACRPageNo);

    function GetTableItemIfExists(
                                  TableNameCRC:   Cardinal;
                                  TableName:      WideString;
                                  var TableItem:  TACRTableListItem
                                 ): Boolean; overload;
    function GetTableItemIfExists(
                                  TableNameCRC:     Cardinal;
                                  TableName:        WideString;
                                  var TableItem:    TACRTableListItem;
                                  var Comment:      WideString
                                 ): Boolean; overload;
    function GetTableItemIfExists(
                                  TableNameCRC:   Cardinal;
                                  TableName:      WideString;
                                  var TableItem:  TACRTableListItem;
                                  out ItemIndex:  Integer
                                 ): Boolean; overload;
    procedure UpdateTableItem(
                              const ItemIndex:    Integer;
                              const TableItem:    TACRTableListItem;
                              const Comment:      WideString
                             );
    procedure CreateTable(
                          var TableItem:        TACRTableListItem;
                          const TableState:     TACRTableState;
                          TableName, Comment:   WideString
                         );
    procedure DeleteTable(TableNameCRC: Cardinal; TableName: WideString);
    procedure RenameTable(OldTableName, NewTableName: WideString);
    procedure GetTablesList(List: TACRWideStringList);
    function GetTablesInfo(SortByTableName: Boolean = True): TACRTableInfoArray;
    function GetNewTableID: TACRTableID;
    procedure SaveTableState(
                              const TableItem:  TACRTableListItem;
                              const TableState: TACRTableState
                            );
    function LoadTableState(const TableItem: TACRTableListItem): TACRTableState;
    // return table comment if table exists, otherwise empty string
    function GetTableComment(TableName: WideString): WideString;
    // set table comment
    procedure SetTableComment(TableName, Comment: WideString);
    // create view (added in v.6.00)
    procedure CreateView(
                         ViewName:          WideString;
                         ViewDef:           TACRViewDef
                        );
    // return nil if not found, otherwise return view definition (added in v.6.00)
    function FindView(ViewName: WideString): TACRViewDef;
    // return false if not found, otherwise return true
    function ViewExists(ViewName: WideString): Boolean;
    // drop view if has no problems with RESTRICT | CASCADE
    procedure DropView(ViewName: WideString; Cascade: Boolean);
    // deletes all views referencing this table (view) if Cascade = TRUE
    // otherwise raises an exception if there is some views referencing the table
    procedure DeleteViewsByTable(TableName: WideString; Cascade: Boolean);
    // added in v.6.00 - return true if view or table exists
    function TableExists(TableName: WideString): Boolean;
  public
    property Header: TACRTLHeader read FHeader write FHeader;
  end; // TACRTableListFile




////////////////////////////////////////////////////////////////////////////////
//
// TACRDiskStoredFunctionManager
// added in v.5.10
//
////////////////////////////////////////////////////////////////////////////////

  TACRDiskStoredFunctionManager = class(TACRStoredFunctionManager)
  private
    FHandle: TACRInternalDBFile;
    LPageManager: TACRDiskPageManager;
    FNotLoaded: Boolean;
    FState: Cardinal; // last loaded state
  protected
    procedure Load(bLockSFMManager, bLockSFM: Boolean); overload;
    procedure Save; overload;
    procedure InternalCreateStoredFunction(StoredFunction: TACRStoredFunction;
      SQLScript: WideString); override;
    procedure InternalDropStoredFunction(FunctionName: WideString); override;
    // ALTER stored function - modify script
    procedure InternalAlterStoredFunction(Session: TACRBaseSession;
      FunctionName, NewSQLScript: WideString); override;
    // ALTER stored function - rename
    procedure InternalAlterStoredFunctionRename(Session: TACRBaseSession;
      FunctionName, NewFunctionName: WideString); override;
  public
    constructor Create(DatabaseData: TACRDatabaseData; bCreate: Boolean; var StartPageNo: TACRPageNo);
    destructor Destroy; override;
    // for calls from TACRDatabase.ExecuteStoredFunction
    // execute stored function - return false if function does not exist
    // if function has no result (procedure) ResultValue will be set to nil
    // params - list of TACRSQLParam
    function ExecuteStoredFunction(Session: TACRBaseSession;
      FunctionName: WideString; ResultValue: TACRVariant;
      Params: TACRSQLParams): Boolean; override;
    // return empty string if function not found; otherwise return SQL script (CREATE FUNCTION...)
    // return SQL script that created this function (CREATE FUNCTION ...)
    function FindStoredFunction(FunctionName: WideString): WideString; override;
    // return the stored function object if it exists in stored function manager associated with
    // the atabase opened by this session
    // used by TACRExprNodeStoredFunction
    function GetStoredFunctionByName(FunctionName: WideString; Session: TACRBaseSession): TObject; override;
    // parse for execute - from SQL engine (EXECUTE FUNCTION / expression, like FunctionName(Params))
    // return stored function object (TACRStoredFunction) if found or nil
    // params - list of TACRExpression
    function ParseStoredFunctionParams(Session: TACRBaseSession;
      Lexer: TACRLexer; parentFunction: TObject; var Token: TToken;
      out Params: TObject): TObject; override;
    // return list of stored function names (optionally SQL scripts for their creation)
    procedure GetStoredFunctions(FunctionNames: TStrings;
      FunctionSQLScripts: TStrings = nil;
      SortNamesByAlphabet: Boolean = True); overload; override;
    // return list of stored function names (optionally SQL scripts for their creation)
    procedure GetStoredFunctions(FunctionNames: TACRWideStringList;
      FunctionSQLScripts: TACRWideStringList = nil;
      SortNamesByAlphabet: Boolean = True); overload; override;
    // export all stored functions to SQL
    procedure ExportStoredFunctionsToSQL(var SQL: WideString); override;
  end; // TACRDiskStoredFunctionManager

////////////////////////////////////////////////////////////////////////////////
  //
  // TACRTableLockFile
  //
  // LockX:               Byte;     // reserved to lock byte
  // LockIRW:             Byte;     // reserved to lock byte
  // LockRW:              Byte;     // reserved to lock byte
  // TACRTableLockFileHeader = packed record
  // MaxSessionID:        TACRSessionID; // for fast lock check
  // MinSessionID:        TACRSessionID; // for fast lock check
  // IRWMaxWaitLevel:     Byte;
  // RWMaxWaitLevel:      Byte;
  // SMaxWaitLevel:       Byte;
  // end;
  // +----------+---------+---------+-------------------+------------+
  // | IS locks | S locks | U locks | U max wait levels | U RecordID |
  // +----------+---------+---------+-------------------+------------+
  //
////////////////////////////////////////////////////////////////////////////////

  TACRTableLockFile = class(TObject)
  private
    LPageManager: TACRDiskPageManager;
    FHandle: TACRInternalDBFile;
    FMaxSessionCount: Cardinal;
    FLastSessionNo: Cardinal;
    FHeader: TACRTableLockFileHeader;
    FHeaderOffset: Cardinal;
    FMaxWaitTime: Cardinal;

    function GetStartPageNo: TACRPageNo;
    function GetMaxSessionCount: Cardinal;
    function GetFileSize(MaxSessionCount: Cardinal): Cardinal;
    function GetByteNo(SessionID: TACRSessionID; LockType: TACRLockType;
      bRecordID: Boolean = False; bWaitLockU: Boolean = False): Cardinal;
    procedure LoadHeader;
    procedure SaveHeader;
    procedure FillDataForLockU;
    // return true if we cannot lock table because of more priority sessions
    // already locked it in the current process
    function IsMorePriorityLockExists(PSessionLockInfo: PACRSessionLockInfo;
      WaitLevel: Byte): Boolean;
    function InternalLockX(PSessionLockInfo: PACRSessionLockInfo): Boolean;
    function InternalLockIS(PSessionLockInfo: PACRSessionLockInfo): Boolean;
    function InternalLockS(PSessionLockInfo: PACRSessionLockInfo): Boolean;
    function InternalLockIRW(PSessionLockInfo: PACRSessionLockInfo): Boolean;
    function InternalLockRW(PSessionLockInfo: PACRSessionLockInfo): Boolean;
    function InternalLockU(PSessionLockInfo: PACRSessionLockInfo): Boolean;
{$IFDEF DEBUG_LOG}
    procedure WriteHeaderToLog(Caption: AnsiString = '');
{$ENDIF}
  public
    constructor Create(PageManager: TACRPageManager; Cache: TACRCache;
      TableID: TACRTableID; MaxWaitTime: Cardinal);
    destructor Destroy; override;
    procedure OpenFile(aStartPageNo: TACRPageNo);
    function CreateFile(SessionID: TACRSessionID; State: TACRState): TACRPageNo;
    // open and delete all pages
    procedure DeleteFile(aStartPageNo: TACRPageNo; SessionID: TACRSessionID;
      State: TACRState);

    //------------------- new locking methods for TableLocksManager ------------------
    function LockTable(PSessionLockInfo: PACRSessionLockInfo): Boolean;
    function UnlockTable(PSessionLockInfo: PACRSessionLockInfo): Boolean;
    procedure ClearWaitLevel(PSessionLockInfo: PACRSessionLockInfo);
  public
    property StartPageNo: TACRPageNo read GetStartPageNo;
    property MaxSessionCount: Cardinal read FMaxSessionCount;
  end; // TACRTableLocksFile

////////////////////////////////////////////////////////////////////////////////
  //
  // TACRSystemDirectory
  //
////////////////////////////////////////////////////////////////////////////////

  TACRSystemDirectory = class(TObject)
  private
    LPageManager: TACRDiskPageManager;
    FHandle: TACRInternalDBFile;
    FFileList: array of TACRSystemDirectoryListItem;
  public
    constructor Create(PageManager: TACRDiskPageManager);
    destructor Destroy; override;
    procedure CreateDirectory;
    procedure LoadDirectory;
    procedure SaveDirectory;
    procedure CreateFile(FileType: TACRDBFileType; FirstPageNo: TACRPageNo);
    function GetFileFirstPageNo(FileType: TACRDBFileType): TACRPageNo;
  public
    property PageManager: TACRDiskPageManager read LPageManager;
  end; // TACRSystemDirectory

type
  TBooleanFunctionForTimeOutCall = function: Boolean of object;
  TBooleanFunctionForTimeOutCallWithRetryNo = function
    (const CurrentRetryNo: Integer): Boolean of object;
  TBooleanFunctionForTimeOutCallWithExclusive = function(Exclusive: Boolean)
    : Boolean of object;

  // convert PageTypeID to AnsiString (for exceptions messages)
function PageTypeToStr(PageType: TACRPageTypeID): AnsiString;
function TryUsingTimeOutWithExclusive(Func:
    TBooleanFunctionForTimeOutCallWithExclusive; LockParams: TACRLockParams;
  Exclusive: Boolean): Boolean;

implementation

uses ACRLocalEngine,
  ACRMemory // last
  ;

///////////////////////////////////////////////////////////////////////////////
//
// TACRDiskDatabaseData
//
///////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// OpenDatabase
//------------------------------------------------------------------------------
procedure TACRDiskDatabaseData.OpenDatabase(Session: TACRBaseSession);
var
  ReadOnly: Boolean;
  SFMPageNo: TACRPageNo;
begin
  FLockParams := Session.LockParams;
  FDatabaseName := Session.DatabaseFileName;
  FDatabaseNameUnicode := Session.DatabaseFileNameUnicode;
  FCryptoParams := Session.CryptoParams;
  if (FPageManager <> nil) then
    raise EACRException.Create(10498, ErrorLDatabaseFileIsInUse,
      [FDatabaseName]);
  FPageManager := TACRDiskPageManager.Create(FLockParams);
  try
    TACRDiskPageManager(FPageManager).CryptoInfo := FCryptoParams;
    ReadOnly := Session.ReadOnly;
    TACRDiskPageManager(FPageManager).OpenDatabase(FDatabaseName,
      FDatabaseNameUnicode, ReadOnly, Session.Exclusive);
    Session.ReadOnly := ReadOnly;
    FCryptoParams := TACRDiskPageManager(FPageManager).CryptoInfo;
    if (FCryptoParams.CryptoAlgorithm = ACR_Cipher_None) then
      FCryptoParams.CryptoMode := ACR_Cipher_Mode_CTS;
    FSystemDir := TACRSystemDirectory.Create(TACRDiskPageManager(FPageManager));
    FSystemDir.LoadDirectory;
    FActiveSessionsFile := TACRActiveSessionFile.Create(FPageManager,
      FLockParams);
    FActiveSessionsFile.OpenFile(FSystemDir.GetFileFirstPageNo
        (dbftActiveSessionsList));
    FTableListFile := TACRTableListFile.Create
      (TACRDiskPageManager(FPageManager));
    FTableListFile.OpenFile(FSystemDir.GetFileFirstPageNo(dbftTablesList));

    // added in v.5.10
    SFMPageNo := FSystemDir.GetFileFirstPageNo(dbftStoredFunctionManager);
    if ((SFMPageNo <> INVALID_PAGE_NO) and (TACRDiskPageManager(FPageManager)
          .OffsetToSFMHeader > 0)) then
      FStoredFunctionsManager := TACRDiskStoredFunctionManager.Create(Self,
        False, SFMPageNo)
    else if (FStoredFunctionsManager <> nil) then
      FreeAndNil(FStoredFunctionsManager);

    FOptions.MaxSessionCount := TACRDiskPageManager(FPageManager)
      .FDBHeader.MaxSessionCount;
    FOptions.PageSize := TACRDiskPageManager(FPageManager).FDBHeader.PageSize;
    FOptions.ExtentPageCount := TACRDiskPageManager(FPageManager)
      .FDBHeader.ExtentPageCount;
    FOptions.RandomSearchRetryCount := Session.Options.RandomSearchRetryCount;
  except
    if (FSystemDir <> nil) then
      FreeAndNil(FSystemDir);
    if (FActiveSessionsFile <> nil) then
      FreeAndNil(FActiveSessionsFile);
    if (FTableListFile <> nil) then
      FreeAndNil(FTableListFile);
    FreeAndNil(FPageManager);
    raise ;
  end;
end; // OpenDatabase

//------------------------------------------------------------------------------
// CloseDatabase
//------------------------------------------------------------------------------
procedure TACRDiskDatabaseData.CloseDatabase(Session: TACRBaseSession);
var
  i: Integer;
begin
  DeleteAllTables;
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog(
    'TACRDiskDatabaseData.CloseDatabase starting - free FTableLocksManager...'
      + ', SessionID = ' + IntToStr(Session.SessionID)
      + ', DatabaseName = ' + IntToStr(Integer(FDatabaseName)) + #13#10);
{$ENDIF}
  if (FActiveSessionsFile <> nil) then
  begin
    FActiveSessionsFile.Free;
    FActiveSessionsFile := nil;
  end;
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog('TACRDiskDatabaseData.CloseDatabase closing table list file...'
      + ', SessionID = ' + IntToStr(Session.SessionID)
      + ', DatabaseName = ' + IntToStr(Integer(FDatabaseName)) + #13#10);
{$ENDIF}
  if (FTableListFile <> nil) then
  begin
    FTableListFile.Free;
    FTableListFile := nil;
  end;
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog
    ('TACRDiskDatabaseData.CloseDatabase closing table system dir...' + ', SessionID = ' + IntToStr(Session.SessionID) + ', DatabaseName = ' + IntToStr(Integer(FDatabaseName)) + #13#10);
{$ENDIF}
  if (FSystemDir <> nil) then
  begin
    FSystemDir.Free;
    FSystemDir := nil;
  end;
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog('TACRDiskDatabaseData.CloseDatabase closing page manager' +
      ', SessionID = ' + IntToStr(Session.SessionID)
      + ', DatabaseName = ' + IntToStr(Integer(FDatabaseName)) + #13#10);
{$ENDIF}
  if (FPageManager <> nil) then
  begin
    TACRDiskPageManager(FPageManager).CloseDatabase;
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
    aaWriteToLog('TACRDiskDatabaseData.CloseDatabase destroying page manager' +
        ', SessionID = ' + IntToStr(Session.SessionID)
        + ', DatabaseName = ' + IntToStr(Integer(FDatabaseName)) + #13#10);
{$ENDIF}
    FPageManager.Free;
    FPageManager := nil;
  end;
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog('TACRDiskDatabaseData.CloseDatabase finished' +
      ', SessionID = ' + IntToStr(Session.SessionID)
      + ', DatabaseName = ' + IntToStr(Integer(FDatabaseName)) + #13#10);
{$ENDIF}
end; // CloseDatabase

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRDiskDatabaseData.Create;
begin
  inherited Create;
  FTemporary := False;
  FInMemory := False;
  FPageManager := nil;
  FSystemDir := nil;
  FActiveSessionsFile := nil;
  FTableListFile := nil;
end; // Create

//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRDiskDatabaseData.Destroy;
var
  DBDatas: TList;
  i: Integer;
begin
  if (FPageManager <> nil) then
    raise EACRException.Create(10499, ErrorLDatabaseFileIsNotClosed);
  DBDatas := DBDataList.LockList;
  try
    for i := 0 to DBDatas.Count - 1 do
      if (DBDatas.Items[i] = Self) then
      begin
        DBDatas.Delete(i);
        break;
      end;
  finally
    DBDataList.UnlockList;
  end;
  if (Length(FCryptoParams.Password) > 0) then
    FillChar(FCryptoParams.Password[1], Length(FCryptoParams.Password), $00);
  FCryptoParams.Password := '';
  FillChar(FCryptoParams, SizeOf(FCryptoParams), $00);
  inherited Destroy;
end; // Destroy

//------------------------------------------------------------------------------
// CreateDatabase
//------------------------------------------------------------------------------
procedure TACRDiskDatabaseData.CreateDatabase(Session: TACRBaseSession);
var
  SFMPageNo: TACRPageNo;
begin
  FLockParams := Session.LockParams;
  FCryptoParams := Session.CryptoParams;
  FOptions := Session.Options;
  FPageManager := TACRDiskPageManager.Create(FLockParams);
  FDatabaseName := Session.DatabaseFileName;
  FDatabaseNameUnicode := Session.DatabaseFileNameUnicode;
  try
    TACRDiskPageManager(FPageManager).CryptoInfo := FCryptoParams;
    TACRDiskPageManager(FPageManager).CreateAndOpenDatabase(FDatabaseName,
      FDatabaseNameUnicode, FOptions.MaxSessionCount, FOptions.PageSize,
      FOptions.ExtentPageCount);
    FSystemDir := TACRSystemDirectory.Create(TACRDiskPageManager(FPageManager));
    FActiveSessionsFile := TACRActiveSessionFile.Create(FPageManager,
      FLockParams);
    FTableListFile := TACRTableListFile.Create
      (TACRDiskPageManager(FPageManager));
    FSystemDir.CreateDirectory;
    try
      FSystemDir.CreateFile(dbftActiveSessionsList,
        FActiveSessionsFile.CreateFile(Options.MaxSessionCount));
      FSystemDir.CreateFile(dbftTablesList, FTableListFile.CreateFile);
      // added in v.5.10
      FStoredFunctionsManager := TACRDiskStoredFunctionManager.Create(Self,
        True, SFMPageNo);
      try
        FSystemDir.CreateFile(dbftStoredFunctionManager, SFMPageNo);
        FSystemDir.SaveDirectory;
        TACRDiskPageManager(FPageManager).FlushFileBuffers;
      finally
        FreeAndNil(FStoredFunctionsManager);
      end;
    finally
      FTableListFile.Free;
      FTableListFile := nil;
      FActiveSessionsFile.Free;
      FActiveSessionsFile := nil;
      FSystemDir.Free;
      FSystemDir := nil;
    end;
  finally
    TACRDiskPageManager(FPageManager).CloseDatabase;
    FPageManager.Free;
    FPageManager := nil;
  end;
end; // CreateDatabase

//------------------------------------------------------------------------------
// ConnectSession
//------------------------------------------------------------------------------
procedure TACRDiskDatabaseData.ConnectSession(Session: TACRBaseSession);
var
  opt: TACROptions;
  MaxCount: Cardinal;
  bFirstOpen: Boolean;
begin
  // avoid parallel opening by multiple threads
  Lock(True);
  try
    bFirstOpen := (FPageManager = nil);
    if (bFirstOpen) then
      OpenDatabase(Session);
  finally
    Unlock;
  end;
  try
{$IFDEF FILE_SERVER_VERSION}
    if (not FPageManager.Exclusive) then
      Session.SessionID := FActiveSessionsFile.Connect
    else
      Session.SessionID := GetNewSessionID;
{$ELSE}
    Session.SessionID := GetNewSessionID;
{$ENDIF}
    opt.RandomSearchRetryCount := Session.Options.RandomSearchRetryCount;
{$IFDEF FILE_SERVER_VERSION}
    if (not FPageManager.Exclusive) then
      MaxCount := TACRDiskPageManager(FPageManager).FDBHeader.MaxSessionCount
    else
      MaxCount := ACRMaxSingleUserConnections;
    // fixed in v.5.90 to enable 5 connections in trial client-server
    if (not FPageManager.Exclusive) then
     if (MaxCount > ACRMaxSessionCount) then
       MaxCount := ACRMaxSessionCount;
{$ELSE}
    MaxCount := ACRMaxSingleUserConnections;
{$ENDIF}
    opt.PageSize := FPageManager.PageSize;
    opt.ExtentPageCount := TACRDiskPageManager(FPageManager)
      .FDBHeader.ExtentPageCount;
    opt.MaxSessionCount := TACRDiskPageManager(FPageManager)
      .FDBHeader.MaxSessionCount;
    opt.PageSize := TACRDiskPageManager(FPageManager).FDBHeader.PageSize;
    Session.Options := opt;
    Session.CryptoParams := FCryptoParams;
    if (GetSessionsCount >= MaxCount) then
      raise EACRException.Create(10843, ErrorLMaximumSessionCountExceeded,
        [MaxCount]);
    if (Session.SessionID > MaxCount) then
      raise EACRException.Create(11334, ErrorLMaximumSessionCountExceeded,
        [MaxCount]);
    inherited ConnectSession(Session);
  except
    if (bFirstOpen) then
      CloseDatabase(Session);
    raise ;
  end;
end; // ConnectSession

//------------------------------------------------------------------------------
// DisconnectSession
//------------------------------------------------------------------------------
procedure TACRDiskDatabaseData.DisconnectSession(Session: TACRBaseSession);
begin
  inherited DisconnectSession(Session);
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog(
    'TACRDiskDatabaseData.DisconnectSession disconnecting from active sessions file...'
      + ', SessionID = ' + IntToStr(Session.SessionID)
      + ', DatabaseName = ' + IntToStr(Integer(FDatabaseName)) + #13#10);
{$ENDIF}
{$IFDEF FILE_SERVER_VERSION}
  if (FPageManager <> nil) then
    if (not FPageManager.Exclusive) then
      FActiveSessionsFile.Disconnect(Session.SessionID);
{$ENDIF}
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog(
    'TACRDiskDatabaseData.DisconnectSession closing database if needed...' +
      ', FSessionList.Count = ' + IntToStr(FSessionList.Count)
      + ', SessionID = ' + IntToStr(Session.SessionID)
      + ', DatabaseName = ' + IntToStr(Integer(FDatabaseName)) + #13#10);
{$ENDIF}
  if (GetSessionsCount <= 0) then
    CloseDatabase(Session);
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog(
    'TACRDiskDatabaseData.DisconnectSession closing database if needed...OK' +
      ', FSessionList.Count = ' + IntToStr(FSessionList.Count)
      + ', SessionID = ' + IntToStr(Session.SessionID)
      + ', DatabaseName = ' + IntToStr(Integer(FDatabaseName)) + #13#10);
{$ENDIF}
end; // DisconnectSession

//------------------------------------------------------------------------------
// TACRDiskDatabaseData
//------------------------------------------------------------------------------
procedure TACRDiskDatabaseData.FreeIfNoSessionsConnected;
var
  DestroyIt: Boolean;
begin
  DestroyIt := (GetSessionsCount = 0);
  if (DestroyIt) then
    Free;
end; // FreeIfNoSessionsConnected

//------------------------------------------------------------------------------
// CreateTableData
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.CreateTableData(Cursor: TACRCursor)
  : TACRTableData;
begin
  Result := TACRDiskTableData.Create(Self);
  Result.TableName := Cursor.TableName;
  AddTableData(Result);
end; // CreateTableData

//------------------------------------------------------------------------------
// get list of all tables in the database file
//------------------------------------------------------------------------------
procedure TACRDiskDatabaseData.GetTablesList(Session: TACRBaseSession;
  List: TACRWideStringList);
begin
  if (not InternalLockTableList(False)) then
    raise EACRException.Create(11798, ErrorLCannotLockTables, [FDatabaseName]);
  try
    FTableListFile.Load;
    FTableListFile.GetTablesList(List);
  finally
    if (not InternalUnlockTableList) then
      raise EACRException.Create(10613, ErrorLCannotUnlockTables,
        [FDatabaseName]);
  end;
end; // GetTablesList

//------------------------------------------------------------------------------
// return information about all tables
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.GetTablesInfo(SortByTableName: Boolean)
  : TACRTableInfoArray;
var
  nameCRC: Cardinal;
  TableItem: TACRTableListItem;
begin
  if (not InternalLockTableList(False)) then
    raise EACRException.Create(11927, ErrorLCannotLockTables, [FDatabaseName]);
  try
    FTableListFile.Load;
    Result := FTableListFile.GetTablesInfo(SortByTableName);
  finally
    if (not InternalUnlockTableList) then
      raise EACRException.Create(11928, ErrorLCannotUnlockTables,
        [FDatabaseName]);
  end;
end; // GetTableInfo


//------------------------------------------------------------------------------
// return current table state or 0 if not found
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.GetTableState(TableName: WideString)
  : TACRTableState;
var
  nameCRC: Cardinal;
  TableItem: TACRTableListItem;
begin
  if (not InternalLockTableList(False)) then
    raise EACRException.Create(11929, ErrorLCannotLockTables, [FDatabaseName]);
  try
    nameCRC := GetTableNameCRC(TableName);
    FTableListFile.Load;
    if (FTableListFile.GetTableItemIfExists(nameCRC, TableName, TableItem)) then
    begin
      Result := LoadTableState(TableItem);
    end
    else
      FillChar(Result, SizeOf(Result), $00);
  finally
    if (not InternalUnlockTableList) then
      raise EACRException.Create(11930, ErrorLCannotUnlockTables,
        [FDatabaseName]);
  end;
end; // GetTableState


//------------------------------------------------------------------------------
// return true if item exists
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.GetTableItemIfExists(TableNameCRC: Cardinal;
  TableName: WideString; var TableItem: TACRTableListItem): Boolean;
begin
  Result := FTableListFile.GetTableItemIfExists(TableNameCRC, TableName,
    TableItem);
end; // GetTableItemIfExists


//------------------------------------------------------------------------------
// return true if item exists
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.GetTableItemIfExists(TableNameCRC: Cardinal;
  TableName: WideString; var TableItem: TACRTableListItem;
  var Comment: WideString): Boolean;
begin
  Result := FTableListFile.GetTableItemIfExists(TableNameCRC, TableName,
    TableItem, Comment);
end; // GetTableItemIfExists


//------------------------------------------------------------------------------
// return true if item exists
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.GetTableItemIfExists(TableNameCRC: Cardinal;
  TableName: WideString; var TableItem: TACRTableListItem;
  out ItemIndex: Integer): Boolean;
begin
  Result := FTableListFile.GetTableItemIfExists(TableNameCRC, TableName,
    TableItem, ItemIndex);
end; // GetTableItemIfExists


//------------------------------------------------------------------------------
// update table item
//------------------------------------------------------------------------------
procedure TACRDiskDatabaseData.UpdateTableItem(const ItemIndex: Integer;
  const TableItem: TACRTableListItem; const Comment: WideString);
begin
  FTableListFile.UpdateTableItem(ItemIndex, TableItem, Comment);
end; // UpdateTableItem

//------------------------------------------------------------------------------
// table exists
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.TableExists(Session: TACRBaseSession; TableName: WideString): Boolean;
begin
{$IFDEF DEBUG_TRACE_TACRDiskDatabaseData_TableExists}
  aaWriteToLog('> TACRDiskDatabaseData.TableExists. SessionID = ' + IntToStr
      (Session.SessionID) + ', TableName = ' + TableName);
{$ENDIF}
  if (not InternalLockTableList(False)) then
    raise EACRException.Create(10614, ErrorLCannotLockTables, [FDatabaseName]);
  try
    FTableListFile.Load;
    Result := FTableListFile.TableExists(TableName);
  finally
    if (not InternalUnlockTableList) then
      raise EACRException.Create(10615, ErrorLCannotUnlockTables,
        [FDatabaseName]);
  end;
{$IFDEF DEBUG_TRACE_TACRDiskDatabaseData_TableExists}
  aaWriteToLog('< TACRDiskDatabaseData.TableExists. SessionID = ' + IntToStr
      (Session.SessionID) + ', TableName = ' + TableName + #13#10 +
      'Result = ' + BoolToStr(Result, True));
{$ENDIF}
end; // TableExists

//------------------------------------------------------------------------------
// Lock All Tables
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.InternalLockTableList(Exclusive: Boolean)
  : Boolean;
begin
  Result := TACRDiskPageManager(FPageManager).InternalLockTableList(Exclusive);
end; // InternalLockTables

//------------------------------------------------------------------------------
// Unlock All Tables
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.InternalUnlockTableList: Boolean;
begin
  Result := TACRDiskPageManager(FPageManager).InternalUnlockTableList;
end; // InternalUnlockTables

//------------------------------------------------------------------------------
// flush file buffers
//------------------------------------------------------------------------------
procedure TACRDiskDatabaseData.FlushFileBuffers;
begin
  TACRDiskPageManager(FPageManager).FlushFileBuffers;
end; // FlushFileBuffers

//------------------------------------------------------------------------------
// return database format version
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.GetFormatVersion(Session: TACRBaseSession)
  : Double;
var
  PageManagerNil: Boolean;
  ReadOnly: Boolean;
begin
  PageManagerNil := (FPageManager = nil);
  if (PageManagerNil) then
  begin
    FPageManager := TACRDiskPageManager.Create(FLockParams);
    ReadOnly := True;
    TACRDiskPageManager(FPageManager).OpenDatabase(Session.DatabaseFileName,
      Session.DatabaseFileNameUnicode, ReadOnly, False, True);
  end;
  try
    TACRDiskPageManager(FPageManager).LoadDBHeader;
    Result := TACRDiskPageManager(FPageManager).DBHeader.Version;
  finally
    if (PageManagerNil) then
      FreeAndNil(FPageManager);
  end;
end; // GetFormatVersion

//------------------------------------------------------------------------------
// get number of free pages
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.GetFreePageCount(Session: TACRBaseSession)
  : Integer;
var
  PageManagerNil: Boolean;
  ReadOnly: Boolean;
begin
  PageManagerNil := (FPageManager = nil);
  if (PageManagerNil) then
  begin
    FPageManager := TACRDiskPageManager.Create(FLockParams);
    ReadOnly := True;
    TACRDiskPageManager(FPageManager).OpenDatabase(Session.DatabaseFileName,
      Session.DatabaseFileNameUnicode, ReadOnly, False, True);
  end;
  try
    Result := TACRDiskPageManager(FPageManager).GetFreePageCount;
  finally
    if (PageManagerNil) then
      FreeAndNil(FPageManager);
  end;
end; // GetFreePageCount

//------------------------------------------------------------------------------
// get total number of pages
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.GetTotalPageCount(Session: TACRBaseSession)
  : Integer;
var
  PageManagerNil: Boolean;
  ReadOnly: Boolean;
begin
  PageManagerNil := (FPageManager = nil);
  if (PageManagerNil) then
  begin
    FPageManager := TACRDiskPageManager.Create(FLockParams);
    ReadOnly := True;
    TACRDiskPageManager(FPageManager).OpenDatabase(Session.DatabaseFileName,
      Session.DatabaseFileNameUnicode, ReadOnly, False, True);
  end;
  try
    Result := TACRDiskPageManager(FPageManager).GetTotalPageCount;
  finally
    if (PageManagerNil) then
      FreeAndNil(FPageManager);
  end;
end; // GetTotalPageCount

//------------------------------------------------------------------------------
// return true if database is encrypted
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.IsDatabaseEncrypted(Session: TACRBaseSession)
  : Boolean;
var
  PageManagerNil: Boolean;
  ReadOnly: Boolean;
begin
  PageManagerNil := (FPageManager = nil);
  if (PageManagerNil) then
  begin
    FPageManager := TACRDiskPageManager.Create(FLockParams);
    try
      ReadOnly := True;
      TACRDiskPageManager(FPageManager).OpenDatabase(Session.DatabaseFileName,
        Session.DatabaseFileNameUnicode, ReadOnly, False, True);
    except
      Result := False;
      Exit;
    end;
  end;
  try
    TACRDiskPageManager(FPageManager).LoadDBHeader;
    Result := (TACRDiskPageManager(FPageManager)
        .DBHeader.CryptoHeader.CryptoAlgorithm <> ACR_Cipher_None);
  finally
    if (PageManagerNil) then
      FreeAndNil(FPageManager);
  end;
end; // IsDatabaseEncrypted

//------------------------------------------------------------------------------
// return true if database is encrypted by password or by key
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.IsDatabaseEncryptedByPassword
  (Session: TACRBaseSession): Boolean;
var
  PageManagerNil: Boolean;
  ReadOnly: Boolean;
begin
  PageManagerNil := (FPageManager = nil);
  if (PageManagerNil) then
  begin
    FPageManager := TACRDiskPageManager.Create(FLockParams);
    try
      ReadOnly := True;
      TACRDiskPageManager(FPageManager).OpenDatabase(Session.DatabaseFileName,
        Session.DatabaseFileNameUnicode, ReadOnly, False, True);
    except
      Result := False;
      Exit;
    end;
  end;
  try
    TACRDiskPageManager(FPageManager).LoadDBHeader;
    Result := (TACRDiskPageManager(FPageManager)
        .DBHeader.CryptoHeader.CryptoAskPassword = 1);
  finally
    if (PageManagerNil) then
      FreeAndNil(FPageManager);
  end;
end; // IsDatabaseEncryptedByPassword

//------------------------------------------------------------------------------
// makes Exe database from edb file
//------------------------------------------------------------------------------
procedure TACRDiskDatabaseData.MakeExeDatabase(Session: TACRBaseSession;
  ExeFileName, ExeDatabaseFileName: WideString);
var
  StubStream, ExeDatabaseStream, DatabaseStream: TACRFileStream;
begin
  // open stub
  ExeDatabaseStream := TACRFileStream.Create(ExeDatabaseFileName, fmCreate);
  try
    StubStream := TACRFileStream.Create(ExeFileName,
      fmOpenRead or fmShareDenyNone);
    try
      StubStream.SaveToStream(ExeDatabaseStream);
    finally
      StubStream.Free;
    end;
    ExeDatabaseStream.Position := ExeDatabaseStream.Size;
    // fixed in v.5.60
    if (Length(Session.DatabaseFileName) > 0) then
      DatabaseStream := TACRFileStream.Create(Session.DatabaseFileName,
        fmOpenRead or fmShareDenyWrite)
    else
      DatabaseStream := TACRFileStream.Create(Session.DatabaseFileNameUnicode,
        fmOpenRead or fmShareDenyWrite);
    try
      DatabaseStream.SaveToStream(ExeDatabaseStream);
    finally
      DatabaseStream.Free;
    end;
  finally
    ExeDatabaseStream.Free;
  end;
end; // MakeExeDatabase

//------------------------------------------------------------------------------
// removes database file from executable database file
//------------------------------------------------------------------------------
procedure TACRDiskDatabaseData.RemoveDatabaseFromExe(Session: TACRBaseSession);
var
  PageManagerNil: Boolean;
begin
  PageManagerNil := (FPageManager = nil);
  if (PageManagerNil) then
    FPageManager := TACRDiskPageManager.Create(FLockParams);
  try
    TACRDiskPageManager(FPageManager).RemoveDatabaseFromExe
      (Session.DatabaseFileName, Session.DatabaseFileNameUnicode);
  finally
    if (PageManagerNil) then
      FreeAndNil(FPageManager);
  end;
end; // RemoveDatabaseFromExe

//------------------------------------------------------------------------------
// returns true if this file is an Accuracer database
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.IsAccuracerDatabaseFile(Session: TACRBaseSession)
  : Boolean;
var
  PageManagerNil: Boolean;
begin
  Result := ACRFileExists(Session.DatabaseFileName,
    Session.DatabaseFileNameUnicode);
  if (Result) then
  begin
    PageManagerNil := (FPageManager = nil);
    if (PageManagerNil) then
      FPageManager := TACRDiskPageManager.Create(FLockParams);
    try
      if (PageManagerNil) then
        Result := TACRDiskPageManager(FPageManager).IsAccuracerDatabaseFile
          (Session.DatabaseFileName, Session.DatabaseFileNameUnicode)
      else
        Result := True; // file already opened
    finally
      if (PageManagerNil) then
        FreeAndNil(FPageManager);
    end;
  end;
end; // IsAccuracerDatabaseFile

//------------------------------------------------------------------------------
// return true if CryptoParams are valid
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.IsCryptoParamsValid(Session: TACRBaseSession)
  : Boolean;
var
  PageManagerNil: Boolean;
  ReadOnly: Boolean;
begin
  PageManagerNil := (FPageManager = nil);
  if (PageManagerNil) then
  begin
    FPageManager := TACRDiskPageManager.Create(FLockParams);
    try
      ReadOnly := True;
      TACRDiskPageManager(FPageManager).OpenDatabase(Session.DatabaseFileName,
        Session.DatabaseFileNameUnicode, ReadOnly, False, True);
    except
      try
       FreeAndNil(FPageManager);
      except on E: Exception do
      end;
      Result := True;
      Exit;
    end;
    FCryptoParams := TACRDiskPageManager(FPageManager).CryptoInfo;
    FCryptoParams.KeyInfo := Session.CryptoParams.KeyInfo;
    FCryptoParams.Password := Session.CryptoParams.Password;
    FCryptoParams.UseInitVector := Session.CryptoParams.UseInitVector;
    FCryptoParams.InitVector := Session.CryptoParams.InitVector;
    Session.CryptoParams := FCryptoParams;
  end;
  try
    TACRDiskPageManager(FPageManager).LoadDBHeader;
    if (TACRDiskPageManager(FPageManager)
        .DBHeader.CryptoHeader.CryptoAlgorithm =
        ACR_Cipher_None) then
      Result := True
    else
    begin
      Result := ACRIsKeyValid(TACRDiskPageManager(FPageManager)
          .DBHeader.CryptoHeader, Session.CryptoParams);
    end;
  finally
    if (PageManagerNil) then
      FreeAndNil(FPageManager);
  end;
end; // IsCryptoParamsValid

//------------------------------------------------------------------------------
// load table state
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.LoadTableState(const TableItem: TACRTableListItem)
  : TACRTableState;
begin
  Result := FTableListFile.LoadTableState(TableItem);
end; // SaveTableState

//------------------------------------------------------------------------------
// save table state
//------------------------------------------------------------------------------
procedure TACRDiskDatabaseData.SaveTableState
  (const TableItem: TACRTableListItem;
  const TableState: TACRTableState);
begin
  FTableListFile.SaveTableState(TableItem, TableState);
end; // SaveTableState

//------------------------------------------------------------------------------
// return table comment if table exists, otherwise empty string
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.GetTableComment(TableName: WideString)
  : WideString;
begin
  if (not InternalLockTableList(False)) then
    raise EACRException.Create(11965, ErrorLCannotLockTables, [FDatabaseName]);
  try
    FTableListFile.Load;
    Result := FTableListFile.GetTableComment(TableName);
  finally
    if (not InternalUnlockTableList) then
      raise EACRException.Create(11966, ErrorLCannotUnlockTables,
        [FDatabaseName]);
  end;
end; // GetTableComment

//------------------------------------------------------------------------------
// set table comment
//------------------------------------------------------------------------------
procedure TACRDiskDatabaseData.SetTableComment(TableName, Comment: WideString);
begin
  if (not InternalLockTableList(True)) then
    raise EACRException.Create(11967, ErrorLCannotLockTables, [FDatabaseName]);
  try
    FTableListFile.Load;
    FTableListFile.SetTableComment(TableName, Comment);
    FTableListFile.Save;
  finally
    if (not InternalUnlockTableList) then
      raise EACRException.Create(11968, ErrorLCannotUnlockTables,
        [FDatabaseName]);
  end;
end; // SetTableComment


//--------------------------- VIEWS - added in v.6.00 --------------------------


//------------------------------------------------------------------------------
// create view
//------------------------------------------------------------------------------
procedure TACRDiskDatabaseData.CreateView(
                         Session:           TACRBaseSession;
                         ViewName:          WideString;
                         ViewDef:           TACRViewDef
                                          );
begin
{$IFDEF DEBUG_TRACE_TACRDiskDatabaseData_CreateView}
aaWriteToLog('> TACRDiskDatabaseData.CreateView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
try
{$ENDIF}
  if (not InternalLockTableList(True)) then
    raise EACRException.Create(12567, ErrorLCannotLockTables, [FDatabaseName]);
  try
   try
    FTableListFile.Load;
   except
    FTableListFile.FNotLoaded := True;
    raise;
   end;
   if (FTableListFile.IndexOf(GetTableNameCRC(ViewName), ViewName, True) >= 0) then
      raise EACRException.Create(12568,ErrorLTableExists,[ViewName]);
   try
    FTableListFile.CreateView(ViewName,ViewDef);
    FTableListFile.Save;
   except
    FTableListFile.FNotLoaded := True;
    raise;
   end;
  finally
    if (not InternalUnlockTableList) then
      raise EACRException.Create(12569, ErrorLCannotUnlockTables,
        [FDatabaseName]);
  end;
{$IFDEF DEBUG_TRACE_TACRDiskDatabaseData_TableExists}
aaWriteToLog('< TACRDiskDatabaseData.CreateView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
except
 on e: Exception
 begin
aaWriteToLog('Error in TACRDiskDatabaseData.CreateView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
  raise;
 end;
end;
{$ENDIF}
end; // CreateView


//------------------------------------------------------------------------------
// drop view
//------------------------------------------------------------------------------
procedure TACRDiskDatabaseData.DropView(
                     Session:           TACRBaseSession;
                     ViewName:          WideString;
                     bCascade:          Boolean
                  );
begin
{$IFDEF DEBUG_TRACE_TACRDiskDatabaseData_DropView}
aaWriteToLog('> TACRDiskDatabaseData.DropView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
try
{$ENDIF}
  if (not InternalLockTableList(True)) then
    raise EACRException.Create(12581, ErrorLCannotLockTables, [FDatabaseName]);
  try
   try
    FTableListFile.Load;
   except
    FTableListFile.FNotLoaded := True;
    raise;
   end;
   FTableListFile.DropView(ViewName,bCascade);
   try
    FTableListFile.Save;
   except
    FTableListFile.FNotLoaded := True;
    raise;
   end;
  finally
    if (not InternalUnlockTableList) then
      raise EACRException.Create(12582, ErrorLCannotUnlockTables,
        [FDatabaseName]);
  end;
{$IFDEF DEBUG_TRACE_TACRDiskDatabaseData_TableExists}
aaWriteToLog('< TACRDiskDatabaseData.DropView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
except
 on e: Exception
 begin
aaWriteToLog('Error in TACRDiskDatabaseData.DropView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
  raise;
 end;
end;
{$ENDIF}
end; // DropView


//------------------------------------------------------------------------------
// return nil if not found, otherwise return view definition
//------------------------------------------------------------------------------
function TACRDiskDatabaseData.FindView(
                     Session:           TACRBaseSession;
                     ViewName:          WideString
                                  ): TACRViewDef;
begin
{$IFDEF DEBUG_TRACE_TACRDiskDatabaseData_CreateView}
aaWriteToLog('> TACRDiskDatabaseData.FindView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
try
{$ENDIF}
  if (not InternalLockTableList(True)) then
    raise EACRException.Create(12572, ErrorLCannotLockTables, [FDatabaseName]);
  try
   try
    FTableListFile.Load;
    Result := FTableListFile.FindView(ViewName);
   except
    FTableListFile.FNotLoaded := True;
    raise;
   end;
  finally
    if (not InternalUnlockTableList) then
      raise EACRException.Create(12573, ErrorLCannotUnlockTables,
        [FDatabaseName]);
  end;
{$IFDEF DEBUG_TRACE_TACRDiskDatabaseData_TableExists}
aaWriteToLog('< TACRDiskDatabaseData.FindView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName+', Result = '+BoolToStr(Result,True));
except
 on e: Exception
 begin
aaWriteToLog('Error in TACRDiskDatabaseData.CreateView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
  raise;
 end;
end;
{$ENDIF}
end; // FindView


//------------------------ END OF VIEWS - added in v.6.00 ----------------------




////////////////////////////////////////////////////////////////////////////////
//
// TACRTablePageMapsManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// add PFS page
//------------------------------------------------------------------------------
procedure TACRTablePageMapsManager.AddPFSPage(SessionID: TACRSessionID;
  PageNo: TACRPageNo);
var
  x: TACRPageNo;
  i: Integer;
begin
  x := INVALID_PAGE_NO;
  if (FTablePFSPageCount < 0) then
    raise EACRException.Create(10703, ErrorLInvalidPageNo,
      [FTablePFSPageCount]);
  for i := 0 to FTablePFSPageCount - 1 do
    if (FTablePFSPageMapItems[i].PageNo = PageNo) then
      raise EACRException.Create(10480, ErrorLCannotAddTablePFSPage,
        [FTablePFSPageCount, i, FTablePFSPageMapItems[i].PageNo, PageNo])
    else if (FTablePFSPageMapItems[i].PageNo > PageNo) then
    begin
      x := i;
      break;
    end;
  Inc(FTablePFSPageCount);
  if (x = INVALID_PAGE_NO) then
  begin
    x := FTablePFSPageCount - 1;
    SetLength(FTablePFSPageMapItems, FTablePFSPageCount);
  end
  else
  begin
    SetLength(FTablePFSPageMapItems, FTablePFSPageCount);
    Move(FTablePFSPageMapItems[x], FTablePFSPageMapItems[x + 1],
      (FTablePFSPageCount - x) * SizeOf(TACRTablePFSPageMapItem));
  end;
  FTablePFSPageMapItems[x].PageNo := PageNo;
  FTablePFSPageMapItems[x].PageRecordCount := 0;
end; // AddPFSPage

//------------------------------------------------------------------------------
// set page type
//------------------------------------------------------------------------------
procedure TACRTablePageMapsManager.SetPageType(SessionID: TACRSessionID;
  PageNo: TACRPageNo; TablePageType: TACRTablePageType);
var
  PFSPage: TACRPage;
  PFSPageNo: TACRPageNo;
  aPageNo: TACRPageNo;
  OldType: pByte;
begin
  // mark new page in accordance with page type
  PFSPageNo := PageNo div FPFSItemsPerPage;
  if (PFSPageNo >= FTablePFSPageCount) then
    raise EACRException.Create(10512, ErrorLInvalidPageCount, [PFSPageNo,
      FTablePFSPageCount]);
  PFSPageNo := FTablePFSPageMapItems[PFSPageNo].PageNo;
  PFSPage := LTableData.GetPage(SessionID, PFSPageNo, dbstTablePFS,
    LTableData.TableState.TableState, True, True, False);
  try
    aPageNo := PageNo mod FPFSItemsPerPage;
    // each page type size = 2 bits
    OldType := pByte(PFSPage.PageData + FPageTypeOffset + (aPageNo div 4));
    case aPageNo mod 4 of
      0:
        OldType^ := (OldType^ and $FC) or (Byte(TablePageType) and $03);
      1:
        OldType^ := (OldType^ and $F3) or ((Byte(TablePageType) and $03) shl 2);
      2:
        OldType^ := (OldType^ and $CF) or ((Byte(TablePageType) and $03) shl 4);
      3:
        OldType^ := (OldType^ and $3F) or ((Byte(TablePageType) and $03) shl 6);
    end;
  finally
    LTableData.PutPage(PFSPage);
  end;
end; // SetPageType

//------------------------------------------------------------------------------
// set PageRecordCount or PageFreeSpace
//------------------------------------------------------------------------------
procedure TACRTablePageMapsManager.SetPageRecordCount(SessionID: TACRSessionID;
  PageNo: TACRPageNo; PageRecordCount: Word; PageType: TACRTablePageType);
var
  PFSPage: TACRPage;
  PFSItemNo: Integer;
  PFSPageNo: TACRPageNo;
  aPageNo: TACRPageNo;
  Delta: Integer;
  PPageSize: PWord;
begin
  // mark new page in accordance with page type
  PFSItemNo := PageNo div FPFSItemsPerPage;
  if (PFSItemNo >= FTablePFSPageCount) then
    raise EACRException.Create(10513, ErrorLInvalidPageCount, [PFSItemNo,
      FTablePFSPageCount]);
  PFSPageNo := FTablePFSPageMapItems[PFSItemNo].PageNo;
  PFSPage := LTableData.GetPage(SessionID, PFSPageNo, dbstTablePFS,
    LTableData.TableState.TableState, True, True, False);
  try
    aPageNo := PageNo mod FPFSItemsPerPage;
    PPageSize := PWord(PFSPage.PageData + aPageNo * SizeOf(Word));
    // if page was row_start then calculate new page record count
    if (PageType = tptRowStart) then
    begin
      Delta := 0;
      if (PPageSize^ = INVALID_PAGE_RECORD_NO) then
      begin
        if (PageRecordCount <> INVALID_PAGE_RECORD_NO) then
          Delta := PageRecordCount;
      end
      else
      begin
        if (PageRecordCount <> INVALID_PAGE_RECORD_NO) then
          Delta := (Integer(PageRecordCount) - Integer(PPageSize^))
        else
          Delta := -Integer(PPageSize^);
      end;
      Inc(FTablePFSPageMapItems[PFSItemNo].PageRecordCount, Delta);
      {
        if (PageType = tptRowStart) then
        aaWriteToLog('TACRTablePageMapsManager.SetPageRecordCount after inc'+#13#10+
        'SessionID = '+IntToStr(SessionID)+#13#10+
        'PageNo = '+IntToStr(PageNo)+#13#10+
        'PFSItemNo = '+IntToStr(PFSItemNo)+#13#10+
        'Delta = '+IntToStr(Delta)+#13#10+
        'Integer(PageRecordCount) = '+IntToStr(Integer(PageRecordCount))+#13#10+
        'Integer(PPageSize^) = '+IntToStr(Integer(PPageSize^))+#13#10+
        'FTablePFSMapFile.TablePFSPageMapItems[PFSItemNo].PageRecordCount = '+
        IntToStr(FTablePFSMapFile.TablePFSPageMapItems[PFSItemNo].PageRecordCount));
        }
    end;
    Move(PageRecordCount, PPageSize^, SizeOf(Word));
  finally
    LTableData.PutPage(PFSPage);
  end;
end; // SetPageRecordCount

//------------------------------------------------------------------------------
// return PageType
//------------------------------------------------------------------------------
function TACRTablePageMapsManager.InternalGetPageType(PFSPage: TACRPage;
  RelativePageNo: TACRPageNo): TACRTablePageType;
var
  b: Byte;
begin
  b := pByte(PFSPage.PageData + FPageTypeOffset + (RelativePageNo div 4))^;
  case RelativePageNo mod 4 of
    0:
      Result := TACRTablePageType(b and $03);
    1:
      Result := TACRTablePageType((b shr 2) and $03);
    2:
      Result := TACRTablePageType((b shr 4) and $03);
    3:
      Result := TACRTablePageType((b shr 6) and $03);
  end;
end; // InternalGetPageType

//------------------------------------------------------------------------------
// return PageRecordCount or PageFreeSpace
//------------------------------------------------------------------------------
function TACRTablePageMapsManager.GetPageRecordCount(SessionID: TACRSessionID;
  PageNo: TACRPageNo): Word;
var
  PFSPage: TACRPage;
  PFSPageNo: TACRPageNo;
  aPageNo: TACRPageNo;
begin
  // mark new page in accordance with page type
  PFSPageNo := PageNo div FPFSItemsPerPage;
  if (PFSPageNo >= FTablePFSPageCount) then
    raise EACRException.Create(10515, ErrorLInvalidPageCount, [PFSPageNo,
      FTablePFSPageCount]);
  PFSPageNo := FTablePFSPageMapItems[PFSPageNo].PageNo;
  PFSPage := LTableData.GetPage(SessionID, PFSPageNo, dbstTablePFS,
    LTableData.TableState.TableState, True, False, False);
  try
    aPageNo := PageNo mod FPFSItemsPerPage;
    Move(PWord(PFSPage.PageData + aPageNo * SizeOf(Word))^, Result,
      SizeOf(Word));
  finally
    LTableData.PutPage(PFSPage);
  end;
end; // GetPageRecordCount

//------------------------------------------------------------------------------
// find page in PFS page map
//------------------------------------------------------------------------------
function TACRTablePageMapsManager.FindPageInPFSPage(PageData: PAnsiChar;
  MaxRelativePageNo: Integer; TablePageType: TACRTablePageType; Size: Word;
  out RelativePageNo: Integer; out PageRecordCount: Word): Boolean;
var
  i, imod4: Integer;
  PPageSize: PWord;
  bRowStart: Boolean;
  bOK: Boolean;
  PType: pByte;
  pt0, pt1, pt2, pt3: Byte;
begin
  i := 0;
  imod4 := 0;
  pt0 := Byte(TablePageType);
  pt1 := Byte(TablePageType) shl 2;
  pt2 := Byte(TablePageType) shl 4;
  pt3 := Byte(TablePageType) shl 6;
  PPageSize := PWord(PageData);
  PType := pByte(PageData + FPageTypeOffset);
  bRowStart := (TablePageType = tptRowStart);
  Result := False;
  while (i <= MaxRelativePageNo) do
  begin
    if (PPageSize^ <> INVALID_PAGE_RECORD_NO) then
    begin
      if (bRowStart) then
        bOK := (PPageSize^ < Size)
      else
        bOK := (PPageSize^ >= Size);
      if (bOK) then
      begin
        case imod4 of
          0:
            bOK := (((PType^ and $03) xor pt0) = 0);
          1:
            bOK := (((PType^ and $0C) xor pt1) = 0);
          2:
            bOK := (((PType^ and $30) xor pt2) = 0);
          3:
            bOK := (((PType^ and $C0) xor pt3) = 0);
        end;
        if (bOK) then
        begin
          Result := True;
          RelativePageNo := i;
          PageRecordCount := PPageSize^;
          break;
        end;
      end;
    end;
    Inc(PPageSize);
    Inc(i);
    Inc(imod4);
    if (imod4 >= 4) then
    begin
      imod4 := 0;
      Inc(PType);
    end;
  end;
end; // FindPageInPFSPage

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRTablePageMapsManager.Create(aTableData: TACRTableData;
  aRandomSearchRetryCount: Integer);
begin
  LTableData := TACRDiskTableData(aTableData);
  if (LTableData = nil) then
    raise EACRException.Create(10500, ErrorLNilPointer);
  if (LTableData.DatabaseData = nil) then
    raise EACRException.Create(10501, ErrorLNilPointer);
  if (LTableData.DatabaseData.PageManager = nil) then
    raise EACRException.Create(10502, ErrorLNilPointer);
  FPFSItemsPerPage := ((LTableData.PageManager.PageDataSize * 8)
      div ACRTablePFSItemSize);
  FPageTypeOffset := FPFSItemsPerPage * 2;
  FRandomSearchRetryCount := aRandomSearchRetryCount;
end; // Create

//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRTablePageMapsManager.Destroy;
begin
  FTablePFSPageMapItems := nil;
  inherited;
end; // Destroy

//------------------------------------------------------------------------------
// add page
//------------------------------------------------------------------------------
function TACRTablePageMapsManager.AddPage(SessionID: TACRSessionID;
  TablePageType: TACRTablePageType): TACRPage;
var
  NewPageCount: Integer;
  i, NumPagesToAdd: Integer;
  NewPage: TACRPage;
  Pages: TACRPageArray;
  StateType: TACRDBStateType;

  procedure FillPFSPage;
  begin
    NewPage.PageHeader.ObjectID := LTableData.TableID;
    NewPage.PageHeader.PageType := ACRPageTypeIDTablePFS;
    AddPFSPage(SessionID, NewPage.PageNo);
    // mark all items in new pfs page as empty pages
    FillChar(NewPage.PageData^, (FPFSItemsPerPage * SizeOf(Word)), $FF);
  end;

begin
  if (TablePageType = tptVarchar) then
    StateType := dbstVarchar
  else if (TablePageType = tptBLOB) then
    StateType := dbstBLOB
  else
    StateType := dbstRow;
  Result := LTableData.AddPage(SessionID, StateType,
    LTableData.TableState.TableState, False);
  if (Result.PageNo >= FPageCount) then
  begin
    // need to extend table page map
    NewPageCount := Result.PageNo + 1;

    if (FTablePFSPageCount * FPFSItemsPerPage < NewPageCount) then
    begin
      NumPagesToAdd := NewPageCount div FPFSItemsPerPage + Integer
        (NewPageCount mod FPFSItemsPerPage > 0)
        - FTablePFSPageCount;
      if (NumPagesToAdd > 1) then
      begin
        Pages := TACRPageArray.Create;
        try
          LTableData.AddPages(Pages, NumPagesToAdd, False, SessionID,
            dbstTablePFS, LTableData.TableState.TableState, True);
          for i := 0 to Pages.Count - 1 do
          begin
            NewPage := LTableData.GetPage(SessionID, Pages.Items[i],
              dbstTablePFS, LTableData.TableState.TableState, False, True,
              False);
            try
              FillPFSPage;
            except
            end;
            LTableData.PutPage(NewPage);
          end;
        finally
          Pages.Free;
        end;
      end // add multiple pages
      else
      begin
        NewPage := LTableData.AddPage(SessionID, dbstTablePFS,
          LTableData.TableState.TableState, True);
        try
          FillPFSPage;
        except
        end;
        LTableData.PutPage(NewPage);
      end; // add single page
    end;
    FPageCount := NewPageCount;
  end;
  SetPageType(SessionID, Result.PageNo, TablePageType);
end; // AddPage

//------------------------------------------------------------------------------
// remove page
//------------------------------------------------------------------------------
procedure TACRTablePageMapsManager.RemovePage(SessionID: TACRSessionID;
  PageNo: TACRPageNo; TablePageType: TACRTablePageType);
begin
  SetPageRecordCount(SessionID, PageNo, INVALID_PAGE_RECORD_NO, TablePageType);
end; // RemovePage

//------------------------------------------------------------------------------
// try to find a page for adding a small amount of data (< 1 page)
// if failed performs add page
//------------------------------------------------------------------------------
function TACRTablePageMapsManager.GetPageForAddingNewData
  (SessionID: TACRSessionID; TablePageType: TACRTablePageType; Size: Word;
  out PageRecordCount: Word): TACRPage;
var
  j, k, PFSItemNo: Integer;
  PFSPageCount: Integer;
  PFSPageNo, PageNo: TACRPageNo;
  PFSPage: TACRPage;
  ScannedPFSPages: TACRPagesArray;
  bLow: Boolean;
  StateType: TACRDBStateType;
begin
  if (TablePageType = tptVarchar) then
    StateType := dbstVarchar
  else if (TablePageType = tptBLOB) then
    StateType := dbstBLOB
  else
    StateType := dbstRow;
  Result := nil;
  PFSPageCount := FTablePFSPageCount;
  bLow := (PFSPageCount <= FRandomSearchRetryCount);
  if (not bLow) then
    ScannedPFSPages := TACRPagesArray.Create(0, FRandomSearchRetryCount);
  try
    if (PFSPageCount > 0) then
    begin
      j := 0;
      while (j < FRandomSearchRetryCount) do
      begin
        // modified in v.5 - scan last page first by default
        // because if no records were deleted it is the only way to get the space
        { TODO -oLeo :
          think about dividing PFS pages to groups - only records / only varchar/blobs
          in this case we can know exactly how many records already addressed by pfs page
          and compare it with maximum value - it it is equal no need to get this page -
          it's full
          }
        if (j = 0) then
          PFSItemNo := PFSPageCount - 1
        else
        begin
          if (bLow) then
          begin
            if (j >= PFSPageCount) then
              break
            else
              PFSItemNo := PFSPageCount - j - 1;
          end
          else
            PFSItemNo := Random(MaxInt) mod PFSPageCount;
        end;
        // end of modifications in v.5
        PFSPageNo := FTablePFSPageMapItems[PFSItemNo].PageNo;
        Inc(j);
        if (not bLow) then
        begin
          if (ScannedPFSPages.IsValueExists(PFSPageNo)) then
            continue
          else
            ScannedPFSPages.Append(PFSPageNo);
        end;
        PFSPage := LTableData.GetPage(SessionID, PFSPageNo, dbstTablePFS,
          LTableData.TableState.TableState, True, False, False);
        try
          // search desired page inside the random PFS page
          if (PFSItemNo = PFSPageCount - 1) then
            k := (FPageCount - 1) mod FPFSItemsPerPage
          else
            k := FPFSItemsPerPage - 1;
          if (FindPageInPFSPage(PFSPage.PageData, k, TablePageType, Size,
              PageNo, PageRecordCount)) then
            Result := LTableData.GetPage(SessionID,
              (PFSItemNo * FPFSItemsPerPage + PageNo), StateType,
              LTableData.TableState.TableState, True, True, False);
        finally
          LTableData.PutPage(PFSPage);
        end;
        if (Result <> nil) then
          break;
      end; // random search loop
    end; // page Count
    if (Result = nil) then
    begin
      Result := AddPage(SessionID, TablePageType);
      PageRecordCount := INVALID_PAGE_RECORD_NO; // empty page was found
    end;
  finally
    if (not bLow) then
      ScannedPFSPages.Free;
  end;
end; // GetPageForAddingNewData

//------------------------------------------------------------------------------
// return PageNo where first row begin if row count > 0, otherwise return INVALID_PAGE_NO
//------------------------------------------------------------------------------
function TACRTablePageMapsManager.GetFirstRowBeginPageNo
  (SessionID: TACRSessionID): TACRPageNo;
var
  i, j, k: Integer;
  PFSPage: TACRPage;
  PFSPageNo: TACRPageNo;
begin
  Result := INVALID_PAGE_NO;
  if (FTablePFSPageCount > 0) then
  begin
    for j := 0 to FTablePFSPageCount - 1 do
      if (FTablePFSPageMapItems[j].PageRecordCount > 0) then
      begin
        PFSPageNo := FTablePFSPageMapItems[j].PageNo;
        PFSPage := LTableData.GetPage(SessionID, PFSPageNo, dbstTablePFS,
          LTableData.TableState.TableState, True, False, False);
        try
          if (j = FTablePFSPageCount - 1) then
            k := (FPageCount - 1) mod FPFSItemsPerPage
          else
            k := FPFSItemsPerPage - 1;
          for i := 0 to k do
            if (PWord(PFSPage.PageData + i * SizeOf(Word))
                ^ <> INVALID_PAGE_RECORD_NO) then
              if (InternalGetPageType(PFSPage, i) = tptRowStart) then
              begin
                Result := j * FPFSItemsPerPage + i;
                break;
              end;
        finally
          LTableData.PutPage(PFSPage);
        end;
        if (Result <> INVALID_PAGE_NO) then
          break;
      end;
  end;
end; // GetFirstRowBeginPageNo

//------------------------------------------------------------------------------
// return page where last row begin if row count > 0, otherwise return nil
//------------------------------------------------------------------------------
function TACRTablePageMapsManager.GetLastRowBeginPageNo
  (SessionID: TACRSessionID): TACRPageNo;
var
  i, j, k: Integer;
  PFSPage: TACRPage;
  PFSPageNo: TACRPageNo;
begin
  Result := INVALID_PAGE_NO;
  if (FTablePFSPageCount > 0) then
  begin
    for j := FTablePFSPageCount - 1 downto 0 do
      if (FTablePFSPageMapItems[j].PageRecordCount > 0) then
      begin
        PFSPageNo := FTablePFSPageMapItems[j].PageNo;
        PFSPage := LTableData.GetPage(SessionID, PFSPageNo, dbstTablePFS,
          LTableData.TableState.TableState, True, False, False);
        try
          if (j = FTablePFSPageCount - 1) then
            k := (FPageCount - 1) mod FPFSItemsPerPage
          else
            k := FPFSItemsPerPage - 1;
          for i := k downto 0 do
            if (PWord(PFSPage.PageData + i * SizeOf(Word))
                ^ <> INVALID_PAGE_RECORD_NO) then
              if (InternalGetPageType(PFSPage, i) = tptRowStart) then
              begin
                Result := j * FPFSItemsPerPage + i;
                break;
              end;
        finally
          LTableData.PutPage(PFSPage);
        end;
        if (Result <> INVALID_PAGE_NO) then
          break;
      end;
  end;
end; // GetLastRowBeginPageNo

//------------------------------------------------------------------------------
// return page where next row begin if row count > 0, otherwise return nil
//------------------------------------------------------------------------------
function TACRTablePageMapsManager.GetNextRowBeginPageNo
  (SessionID: TACRSessionID; PageNo: TACRPageNo): TACRPageNo;
var
  i, j, k, n, m: Integer;
  PFSPage: TACRPage;
  PFSPageNo: TACRPageNo;
begin
  Result := INVALID_PAGE_NO;
  if (FTablePFSPageCount > 0) then
  begin
    n := PageNo div FPFSItemsPerPage;
    for j := n to FTablePFSPageCount - 1 do
      if (FTablePFSPageMapItems[j].PageRecordCount > 0) then
      begin
        PFSPageNo := FTablePFSPageMapItems[j].PageNo;
        PFSPage := LTableData.GetPage(SessionID, PFSPageNo, dbstTablePFS,
          LTableData.TableState.TableState, True, False, False);
        try
          if (j = FTablePFSPageCount - 1) then
            k := (FPageCount - 1) mod FPFSItemsPerPage
          else
            k := FPFSItemsPerPage - 1;
          if (j = n) then
            m := PageNo mod FPFSItemsPerPage + 1
          else
            m := 0;
          for i := m to k do
            if (PWord(PFSPage.PageData + i * SizeOf(Word))
                ^ <> INVALID_PAGE_RECORD_NO) then
              if (InternalGetPageType(PFSPage, i) = tptRowStart) then
              begin
                Result := j * FPFSItemsPerPage + i;
                break;
              end;
        finally
          LTableData.PutPage(PFSPage);
        end;
        if (Result <> INVALID_PAGE_NO) then
          break;
      end;
  end;
end; // GetNextRowBeginPageNo

//------------------------------------------------------------------------------
// return page where prior row begin if row count > 0, otherwise return nil
//------------------------------------------------------------------------------
function TACRTablePageMapsManager.GetPriorRowBeginPageNo
  (SessionID: TACRSessionID; PageNo: TACRPageNo): TACRPageNo;
var
  i, j, k, n, m: Integer;
  PFSPage: TACRPage;
  PFSPageNo: TACRPageNo;
begin
  Result := INVALID_PAGE_NO;
  if (FTablePFSPageCount > 0) then
  begin
    n := PageNo div FPFSItemsPerPage;
    for j := n downto 0 do
      if (FTablePFSPageMapItems[j].PageRecordCount > 0) then
      begin
        PFSPageNo := FTablePFSPageMapItems[j].PageNo;
        PFSPage := LTableData.GetPage(SessionID, PFSPageNo, dbstTablePFS,
          LTableData.TableState.TableState, True, False, False);
        try
          if (j = FTablePFSPageCount - 1) then
            k := (FPageCount - 1) mod FPFSItemsPerPage
          else
            k := FPFSItemsPerPage - 1;
          if (j = n) then
            m := PageNo mod FPFSItemsPerPage - 1
          else
            m := k;
          for i := m downto 0 do
            if (PWord(PFSPage.PageData + i * SizeOf(Word))
                ^ <> INVALID_PAGE_RECORD_NO) then
              if (InternalGetPageType(PFSPage, i) = tptRowStart) then
              begin
                Result := j * FPFSItemsPerPage + i;
                break;
              end;
        finally
          LTableData.PutPage(PFSPage);
        end;
        if (Result <> INVALID_PAGE_NO) then
          break;
      end;
  end;
end; // GetPriorRowBeginPageNo

//------------------------------------------------------------------------------
// return RecNo of the specified record in physical records order
//------------------------------------------------------------------------------
function TACRTablePageMapsManager.GetRecNoByRecordID(SessionID: TACRSessionID;
  RecordID: TACRRecordID): TACRRecordNo;
var
  i, j, k: Integer;
  PFSPage: TACRPage;
  PFSPageNo: TACRPageNo;
  RecCount: TACRRecordNo;
begin
  Result := -1;
  if (FTablePFSPageCount > 0) then
  begin
    k := RecordID.PageNo div FPFSItemsPerPage;
    if (k < FTablePFSPageCount) then
    begin
      Result := 0;
      for j := 0 to k - 1 do
      begin
        RecCount := FTablePFSPageMapItems[j].PageRecordCount;
        Inc(Result, RecCount);
      end;
      PFSPageNo := FTablePFSPageMapItems[k].PageNo;
      PFSPage := LTableData.GetPage(SessionID, PFSPageNo, dbstTablePFS,
        LTableData.TableState.TableState, True, False, False);
      try
        k := RecordID.PageNo mod FPFSItemsPerPage;
        for i := 0 to k - 1 do
          if (PWord(PFSPage.PageData + i * SizeOf(Word))
              ^ <> INVALID_PAGE_RECORD_NO) then
            if (InternalGetPageType(PFSPage, i) = tptRowStart) then
              Inc(Result, Integer(PWord(PFSPage.PageData + i * 2)^));
      finally
        LTableData.PutPage(PFSPage);
      end;
    end; // Page found
  end; // record count > 0
end; // GetRecNoByRecordID

//------------------------------------------------------------------------------
// return RecordID of the record with specified RecNo in physical order
// RecNo is 0-based
//------------------------------------------------------------------------------
function TACRTablePageMapsManager.GetRecordIDByRecNo(SessionID: TACRSessionID;
  RecNo: TACRRecordNo): TACRRecordID;
var
  i, j, k: Integer;
  PFSPage: TACRPage;
  PFSPageNo: TACRPageNo;
  CurRecNo, RecCount: TACRRecordNo;
begin
  Result.PageNo := INVALID_PAGE_NO;
  CurRecNo := 0;
  PFSPageNo := INVALID_PAGE_NO;
  if (FTablePFSPageCount > 0) then
  begin
    for j := 0 to FTablePFSPageCount - 1 do
    begin
      RecCount := FTablePFSPageMapItems[j].PageRecordCount;
      if (CurRecNo + RecCount > RecNo) then
      begin
        PFSPageNo := FTablePFSPageMapItems[j].PageNo;
        break;
      end;
      Inc(CurRecNo, RecCount);
    end;
    if (PFSPageNo <> INVALID_PAGE_NO) then
    begin
      PFSPage := LTableData.GetPage(SessionID, PFSPageNo, dbstTablePFS,
        LTableData.TableState.TableState, True, False, False);
      try
        if (j = FTablePFSPageCount - 1) then
          k := (FPageCount - 1) mod FPFSItemsPerPage
        else
          k := FPFSItemsPerPage - 1;
        for i := 0 to k do
          if (PWord(PFSPage.PageData + i * SizeOf(Word))
              ^ <> INVALID_PAGE_RECORD_NO) then
            if (InternalGetPageType(PFSPage, i) = tptRowStart) then
            begin
              RecCount := PWord(PFSPage.PageData + i * SizeOf(Word))^;
              if (CurRecNo + RecCount > RecNo) then
              begin
                Result.PageNo := j * FPFSItemsPerPage + i;
                // relative page item no
                // real page item no is a number of PageItemNo bit = 0
                // in delete rows of this page
                Result.PageItemNo := RecNo - CurRecNo;
                break;
              end;
              Inc(CurRecNo, RecCount);
            end;
      finally
        LTableData.PutPage(PFSPage);
      end;
    end;
  end; // record count > 0
end; // GetRecordIDByRecNo

//------------------------------------------------------------------------------
// return number of physical records in the table
//------------------------------------------------------------------------------
function TACRTablePageMapsManager.GetRecordCount: TACRRecordNo;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to FTablePFSPageCount - 1 do
    Inc(Result, FTablePFSPageMapItems[i].PageRecordCount);
end; // GetRecordCount

//------------------------------------------------------------------------------
// empty all table pages with rows, varchars and blobs
//------------------------------------------------------------------------------
procedure TACRTablePageMapsManager.Empty(SessionID: TACRSessionID);
var
  i, j, k: Integer;
  PFSPage: TACRPage;
  PFSPageNo: TACRPageNo;
  Pages: TACRPageArray;
begin
  if (FTablePFSPageCount > 0) then
  begin
    Pages := TACRPageArray.Create;
    try
      for j := 0 to FTablePFSPageCount - 1 do
      begin
        PFSPageNo := FTablePFSPageMapItems[j].PageNo;
        PFSPage := LTableData.GetPage(SessionID, PFSPageNo, dbstTablePFS,
          LTableData.TableState.TableState, True, False, False);
        try
          if (PFSPageNo = FTablePFSPageCount - 1) then
            k := (FPageCount - 1) mod FPFSItemsPerPage
          else
            k := FPFSItemsPerPage - 1;
          // removing rows, varchars and blob pages of the table
          for i := 0 to k do
            if (PWord(PFSPage.PageData + i * 2)^ <> INVALID_PAGE_RECORD_NO) then
              Pages.Insert(j * FPFSItemsPerPage + i, True);
        finally
          LTableData.PutPage(PFSPage);
        end;
        // remove table pfs map page
        Pages.Insert(PFSPageNo, True);
      end;
      LTableData.RemovePages(Pages, SessionID, dbstData,
        LTableData.TableState.TableState, 0);
    finally
      Pages.Free;
    end;
    FTablePFSPageMapItems := nil;
    FTablePFSPageCount := 0;
    FPageCount := 0;
  end; // table not empty
end; // Empty

//------------------------------------------------------------------------------
// load file from stream
//------------------------------------------------------------------------------
procedure TACRTablePageMapsManager.LoadFileFromStream(Stream: TACRStream);
var
  DataSize: Integer;
begin
  LoadDataFromStream(FPageCount, SizeOf(FPageCount), Stream, 11773);
  LoadDataFromStream(FTablePFSPageCount, SizeOf(FTablePFSPageCount), Stream,
    11774);
  SetLength(FTablePFSPageMapItems, FTablePFSPageCount);
  DataSize := FTablePFSPageCount * SizeOf(TACRTablePFSPageMapItem);
  if (DataSize > 0) then
    LoadDataFromStream(FTablePFSPageMapItems[0], DataSize, Stream, 11775);
end; // LoadFileFromStream

//------------------------------------------------------------------------------
// save file to stream
//------------------------------------------------------------------------------
procedure TACRTablePageMapsManager.SaveFileToStream(Stream: TACRStream);
var
  DataSize: Integer;
begin
  SaveDataToStream(FPageCount, SizeOf(FPageCount), Stream, 11770);
  SaveDataToStream(FTablePFSPageCount, SizeOf(FTablePFSPageCount), Stream,
    11771);
  DataSize := FTablePFSPageCount * SizeOf(TACRTablePFSPageMapItem);
  if (DataSize > 0) then
    SaveDataToStream(FTablePFSPageMapItems[0], DataSize, Stream, 11772);
end; // SaveFileToStream

//------------------------------------------------------------------------------
// get page type and record count
//------------------------------------------------------------------------------
procedure TACRTablePageMapsManager.GetPageTypeAndRecordCount
  (SessionID: TACRSessionID; PageNo: TACRPageNo;
  out TablePageType: TACRTablePageType; out PageRecordCount: Word);
var
  PFSPage: TACRPage;
  PFSPageNo: TACRPageNo;
  aPageNo: TACRPageNo;
begin
  // mark new page in accordance with page type
  PFSPageNo := PageNo div FPFSItemsPerPage;
  if (PFSPageNo >= FTablePFSPageCount) then
    raise EACRException.Create(10515, ErrorLInvalidPageCount, [PFSPageNo,
      FTablePFSPageCount]);
  PFSPageNo := FTablePFSPageMapItems[PFSPageNo].PageNo;
  PFSPage := LTableData.GetPage(SessionID, PFSPageNo, dbstTablePFS,
    LTableData.TableState.TableState, True, False, False);
  try
    aPageNo := PageNo mod FPFSItemsPerPage;
    Move(PWord(PFSPage.PageData + aPageNo * SizeOf(Word))^, PageRecordCount,
      SizeOf(Word));
    TablePageType := InternalGetPageType(PFSPage, aPageNo);
  finally
    LTableData.PutPage(PFSPage);
  end;
end; // GetPageTypeAndRecordCount

///////////////////////////////////////////////////////////////////////////////
//
// TACRDiskRecordManager
//
///////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// load data items map from page
//------------------------------------------------------------------------------
function TACRDiskRecordManager.LoadDataItemsMapFromPage(ErrorCode: Integer;
  Page: TACRPage; var ItemCount: Word): TACRDataItemsMap;
var
  Size: Word;
  Count: Integer;
begin
  Move(PAnsiChar(Page.PageData + Page.PageDataSize - SizeOf(Word))^, ItemCount,
    SizeOf(Word));
  if (ItemCount = 0) then
  begin
    LTableData.PutPage(Page);
    raise EACRException.Create(ErrorCode, ErrorLInvalidItemCount, [ItemCount]);
  end;
  Count := ItemCount;
  SetLength(Result, Count);
  Size := SizeOf(TACRDataItem) * ItemCount;
  Move(PAnsiChar(Page.PageData + Page.PageDataSize - Size - SizeOf(Word))^,
    Result[0], Size);
end; // LoadDataItemsMapFromPage

//------------------------------------------------------------------------------
// save data items map to page
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.SaveDataItemsMapToPage(Page: TACRPage;
  ItemsMap: TACRDataItemsMap; ItemCount: Word);
var
  Size: Integer;
  Offset: Integer;
begin
  Size := SizeOf(TACRDataItem) * ItemCount;
  Offset := Page.PageDataSize - Size - SizeOf(Word);
  Move(ItemsMap[0], PAnsiChar(Page.PageData + Offset)^, Size);
  Move(ItemCount, PAnsiChar(Page.PageData + Page.PageDataSize - SizeOf(Word))^,
    SizeOf(Word));
end; // LoadDataItemsMapFromPage

//------------------------------------------------------------------------------
// return INVALID_PAGE_RECORD_NO if failed, otherwise return RecordNo
//------------------------------------------------------------------------------
function TACRDiskRecordManager.GetFirstRecordOnPage(Page: TACRPage)
  : TACRPageItemID;
var
{$I ACR_check_null_flag_var.inc}
begin
  Result := INVALID_PAGE_RECORD_NO;
  CHECK_NULL_FLAG_NullFlags := Page.PageData;
  for CHECK_NULL_FLAG_BitNo := 0 to FRecordsPerPage - 1 do
  begin
{$I ACR_check_null_flag.inc}
    if (not CHECK_NULL_FLAG_Result) then
    begin
      Result := CHECK_NULL_FLAG_BitNo;
      break;
    end;
  end;
end; // GetFirstRecordOnPage

//------------------------------------------------------------------------------
// return INVALID_PAGE_RECORD_NO if failed, otherwise return RecordNo
//------------------------------------------------------------------------------
function TACRDiskRecordManager.GetLastRecordOnPage(Page: TACRPage)
  : TACRPageItemID;
var
{$I ACR_check_null_flag_var.inc}
begin
  Result := INVALID_PAGE_RECORD_NO;
  CHECK_NULL_FLAG_NullFlags := Page.PageData;
  for CHECK_NULL_FLAG_BitNo := FRecordsPerPage - 1 downto 0 do
  begin
{$I ACR_check_null_flag.inc}
    if (not CHECK_NULL_FLAG_Result) then
    begin
      Result := CHECK_NULL_FLAG_BitNo;
      break;
    end;
  end;
end; // GetLastRecordOnPage

//------------------------------------------------------------------------------
// return INVALID_PAGE_RECORD_NO if failed, otherwise return RecordNo
//------------------------------------------------------------------------------
function TACRDiskRecordManager.GetNextRecordOnPage(Page: TACRPage;
  PageItemNo: TACRPageItemID): TACRPageItemID;
var
{$I ACR_check_null_flag_var.inc}
begin
  Result := INVALID_PAGE_RECORD_NO;
  CHECK_NULL_FLAG_NullFlags := Page.PageData;
  for CHECK_NULL_FLAG_BitNo := PageItemNo + 1 to FRecordsPerPage - 1 do
  begin
{$I ACR_check_null_flag.inc}
    if (not CHECK_NULL_FLAG_Result) then
    begin
      Result := CHECK_NULL_FLAG_BitNo;
      break;
    end;
  end;
end; // GetNextRecordOnPage

//------------------------------------------------------------------------------
// return INVALID_PAGE_RECORD_NO if failed, otherwise return RecordNo
//------------------------------------------------------------------------------
function TACRDiskRecordManager.GetPriorRecordOnPage(Page: TACRPage;
  PageItemNo: TACRPageItemID): TACRPageItemID;
var
{$I ACR_check_null_flag_var.inc}
begin
  Result := INVALID_PAGE_RECORD_NO;
  CHECK_NULL_FLAG_NullFlags := Page.PageData;
  for CHECK_NULL_FLAG_BitNo := PageItemNo - 1 downto 0 do
  begin
{$I ACR_check_null_flag.inc}
    if (not CHECK_NULL_FLAG_Result) then
    begin
      Result := CHECK_NULL_FLAG_BitNo;
      break;
    end;
  end;
end; // GetPriorRecordOnPage

//------------------------------------------------------------------------------
// return result for attempt of getting record relatively to first position
// and set RecordID to new record ID
//------------------------------------------------------------------------------
function TACRDiskRecordManager.GetRecordFromFirstPosition
  (SessionID: TACRSessionID; GetRecordMode: TACRGetRecordMode;
  var RecordID: TACRRecordID): TACRGetRecordResult;
var
  Page: TACRPage;
begin
  case GetRecordMode of
    grmPrior:
      begin
        Result := grrBOF;
      end;
    grmCurrent:
      begin
        Result := grrError;
      end;
    grmNext:
      begin
        Result := grrOk;
        RecordID.PageNo := FTablePageMapsManager.GetFirstRowBeginPageNo
          (SessionID);
        if (RecordID.PageNo = INVALID_PAGE_NO) then
          Result := grrEOF
        else
        begin
          if (FLargeRows) then
            RecordID.PageItemNo := 0
          else
          begin
            // find first record page item no in the page
            RecordID.PageItemNo := INVALID_PAGE_RECORD_NO;
            Result := grrOk;
            try
              Page := LTableData.GetPage(SessionID, RecordID.PageNo, dbstRow,
                LTableData.TableState.TableState, True, False, False);
            except
              Result := grrError;
            end;
            if (Result = grrError) then
              Exit;
            try
              RecordID.PageItemNo := GetFirstRecordOnPage(Page);
            finally
              LTableData.PutPage(Page);
            end;
            if (RecordID.PageItemNo = INVALID_PAGE_RECORD_NO) then
              Result := grrError;
          end;
        end; // record found
      end; // next
  end; // GetRecordMode
end; // GetRecordFromFirstPosition

//------------------------------------------------------------------------------
// return result for attempt of getting record relatively to last position
// and set RecordID to new record ID
//------------------------------------------------------------------------------
function TACRDiskRecordManager.GetRecordFromLastPosition
  (SessionID: TACRSessionID; GetRecordMode: TACRGetRecordMode;
  var RecordID: TACRRecordID): TACRGetRecordResult;
var
  Page: TACRPage;
begin
  Result := grrError;
  case GetRecordMode of
    grmPrior:
      begin
        Result := grrOk;
        RecordID.PageNo := FTablePageMapsManager.GetLastRowBeginPageNo
          (SessionID);
        if (RecordID.PageNo = INVALID_PAGE_NO) then
          Result := grrBOF
        else
        begin
          if (FLargeRows) then
            RecordID.PageItemNo := 0
          else
          begin
            // find first record page item no in the page
            Result := grrOk;
            try
              Page := LTableData.GetPage(SessionID, RecordID.PageNo, dbstRow,
                LTableData.TableState.TableState, True, False, False);
            except
              Result := grrError;
            end;
            if (Result = grrError) then
              Exit;
            try
              RecordID.PageItemNo := GetLastRecordOnPage(Page);
            finally
              LTableData.PutPage(Page);
            end;
            if (RecordID.PageItemNo = INVALID_PAGE_RECORD_NO) then
              Result := grrError;
          end;
        end; // record found
      end;
    grmCurrent:
      begin
        Result := grrError;
      end;
    grmNext:
      begin
        Result := grrEOF;
      end;
  end; // GetRecordMode
end; // GetRecordFromLastPosition

//------------------------------------------------------------------------------
// return result for attempt of getting record relatively any position
// and set RecordID to new record ID
//------------------------------------------------------------------------------
function TACRDiskRecordManager.GetRecordFromAnyPosition
  (SessionID: TACRSessionID; GetRecordMode: TACRGetRecordMode;
  var RecordID: TACRRecordID): TACRGetRecordResult;
var
  Page: TACRPage;
  NewRecordID: TACRRecordID;
begin
  Result := grrError;
  NewRecordID := RecordID;
  case GetRecordMode of
    grmPrior:
      begin
        NewRecordID.PageItemNo := INVALID_PAGE_RECORD_NO;
        if (not FLargeRows) then
        begin
          // try to find prior record on this page
          Result := grrOk;
          try
            Page := LTableData.GetPage(SessionID, NewRecordID.PageNo, dbstRow,
              LTableData.TableState.TableState, True, False, False);
          except
            Result := grrError;
          end;
          if (Result = grrError) then
            Exit;
          try
            NewRecordID.PageItemNo := GetPriorRecordOnPage(Page,
              RecordID.PageItemNo);
          finally
            LTableData.PutPage(Page);
          end;
        end;
        // if prior record was not found on this page
        if (NewRecordID.PageItemNo = INVALID_PAGE_RECORD_NO) then
        begin
          NewRecordID.PageNo := FTablePageMapsManager.GetPriorRowBeginPageNo
            (SessionID, RecordID.PageNo);
          if (NewRecordID.PageNo = INVALID_PAGE_NO) then
          begin
            Result := grrBOF;
            Exit;
          end
          else
          begin
            if (FLargeRows) then
              NewRecordID.PageItemNo := 0
            else
            begin
              // try to find page item no
              Result := grrOk;
              try
                Page := LTableData.GetPage(SessionID, NewRecordID.PageNo,
                  dbstRow, LTableData.TableState.TableState, True, False,
                  False);
              except
                Result := grrError;
              end;
              if (Result = grrError) then
                Exit;
              try
                NewRecordID.PageItemNo := GetLastRecordOnPage(Page);
              finally
                LTableData.PutPage(Page);
              end;
              if (NewRecordID.PageItemNo = INVALID_PAGE_RECORD_NO) then
              begin
                Result := grrError;
                Exit;
              end;
            end;
          end; // prior record page was found
        end; // new record id found
        Result := grrOk;
      end; // go to prior record
    grmCurrent:
      begin
        Result := grrOk;
      end; // go to current record
    grmNext:
      begin
        NewRecordID.PageItemNo := INVALID_PAGE_RECORD_NO;
        if (not FLargeRows) then
        begin
          // try to find prior record on this page
          Result := grrOk;
          try
            Page := LTableData.GetPage(SessionID, NewRecordID.PageNo, dbstRow,
              LTableData.TableState.TableState, True, False, False);
          except
            Result := grrError;
          end;
          if (Result = grrError) then
            Exit;
          try
            NewRecordID.PageItemNo := GetNextRecordOnPage(Page,
              RecordID.PageItemNo);
          finally
            LTableData.PutPage(Page);
          end;
        end;
        // if prior record was not found on this page
        if (NewRecordID.PageItemNo = INVALID_PAGE_RECORD_NO) then
        begin
          NewRecordID.PageNo := FTablePageMapsManager.GetNextRowBeginPageNo
            (SessionID, RecordID.PageNo);
          if (NewRecordID.PageNo = INVALID_PAGE_NO) then
          begin
            Result := grrEOF;
            Exit;
          end
          else
          begin
            if (FLargeRows) then
              NewRecordID.PageItemNo := 0
            else
            begin
              // try to find page item no
              Result := grrOk;
              try
{$IFDEF DEBUG_DECRYPTION_TIME}
                aaIncCounter(counter5);
                aaStartTime(time5);
{$ENDIF}
                Page := LTableData.GetPage(SessionID, NewRecordID.PageNo,
                  dbstRow, LTableData.TableState.TableState, True, False,
                  False);
{$IFDEF DEBUG_DECRYPTION_TIME}
                aaStopTime(time5);
{$ENDIF}
              except
                Result := grrError;
              end;
              if (Result = grrError) then
                Exit;
              try
                NewRecordID.PageItemNo := GetFirstRecordOnPage(Page);
              finally
                LTableData.PutPage(Page);
              end;
              if (NewRecordID.PageItemNo = INVALID_PAGE_RECORD_NO) then
              begin
                Result := grrError;
                Exit;
              end;
            end;
          end; // next record page was found
        end; // new record id found
        Result := grrOk;
      end; // go to next record
  end;
  if (Result = grrOk) then
    RecordID := NewRecordID;
end; // GetRecordFromAnyPosition

//------------------------------------------------------------------------------
// convert data in the memory to disk record buffer
// varchar and blobs links are not set
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.GetDiskRecordBufferFromRecordBuffer
  (SessionID: TACRSessionID; RecordBuffer: TACRRecordBuffer);
var
{$I ACR_check_null_flag_var.inc}
begin
  // copy null flags
  CHECK_NULL_FLAG_BitNo := LTableData.FFieldManager.FieldDefs.Count div 8 +
    Integer((LTableData.FFieldManager.FieldDefs.Count mod 8) > 0);
  Move(RecordBuffer^, FDiskRecordBuffer^, CHECK_NULL_FLAG_BitNo);
  CHECK_NULL_FLAG_NullFlags := RecordBuffer;
  for CHECK_NULL_FLAG_BitNo := 0 to LTableData.FFieldManager.FieldDefs.Count -
    1 do
  begin
{$I ACR_check_null_flag.inc}
    // if not null
    if (not CHECK_NULL_FLAG_Result) then
    begin
      if ((IsBLOBFieldType(LTableData.FFieldManager.FieldDefs
              [CHECK_NULL_FLAG_BitNo].BaseFieldType)) or
          (IsVarcharFieldType(LTableData.FFieldManager.FieldDefs
              [CHECK_NULL_FLAG_BitNo].BaseFieldType))) then
      begin
        // process varchar and blob pages
        WriteBLOBOrVarcharValue(SessionID,
          LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo],
          RecordBuffer);
      end
      else
      begin
        if (LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]
            .MemoryDataSize <> LTableData.FFieldManager.FieldDefs
            [CHECK_NULL_FLAG_BitNo].DiskDataSize) then
          raise EACRException.Create(10517, ErrorLInvalidFieldDataSize,
            [LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].Name,
            Integer(LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]
                .BaseFieldType),
            Integer(LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]
                .AdvancedFieldType),
            LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]
              .MemoryDataSize,
            LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]
              .DiskDataSize]);
        Move(PAnsiChar(RecordBuffer + LTableData.FFieldManager.FieldDefs
              [CHECK_NULL_FLAG_BitNo].MemoryOffset)^,
          PAnsiChar(FDiskRecordBuffer + LTableData.FFieldManager.FieldDefs
              [CHECK_NULL_FLAG_BitNo].DiskOffset)^,
          LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]
            .MemoryDataSize);
      end;
    end; // Bit = 0
  end;
end; // GetDiskRecordBufferFromRecordBuffer

//------------------------------------------------------------------------------
// copy data from disk record buffer to memory record buffer
// including varchars and blobs
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.CopyDataFromDiskRecordBufferToMemoryRecordBuffer
  (SessionID: TACRSessionID; RecordBuffer: TACRRecordBuffer);
var
{$I ACR_check_null_flag_var.inc}
{$I ACR_set_null_flag_var.inc}
begin
  // copy null flags
  CHECK_NULL_FLAG_BitNo := LTableData.FFieldManager.FieldDefs.Count div 8 +
    Integer((LTableData.FFieldManager.FieldDefs.Count mod 8) > 0);
  Move(FDiskRecordBuffer^, RecordBuffer^, CHECK_NULL_FLAG_BitNo);
  CHECK_NULL_FLAG_NullFlags := RecordBuffer;
  for CHECK_NULL_FLAG_BitNo := 0 to LTableData.FFieldManager.FieldDefs.Count -
    1 do
  begin
{$I ACR_check_null_flag.inc}
    // if not null
    if (not CHECK_NULL_FLAG_Result) then
    begin
      if (IsVarcharFieldType(LTableData.FFieldManager.FieldDefs
            [CHECK_NULL_FLAG_BitNo].BaseFieldType)) then
      begin
        try
          // process varchar and blob pages
          ReadBLOBOrVarcharValue(SessionID,
            LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo],
            RecordBuffer);
        except
          if (not FRepair) then
            raise
          else
          begin
            SET_NULL_FLAG_ToSet := True;
            SET_NULL_FLAG_NullFlags := RecordBuffer;
            SET_NULL_FLAG_BitNo := CHECK_NULL_FLAG_BitNo;
{$I ACR_set_null_flag.inc}
          end;
        end;
      end
      else
      begin
        if (not IsBLOBFieldType(LTableData.FFieldManager.FieldDefs
              [CHECK_NULL_FLAG_BitNo].BaseFieldType)) then
        begin
          if (LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]
              .MemoryDataSize <> LTableData.FFieldManager.FieldDefs
              [CHECK_NULL_FLAG_BitNo].DiskDataSize) then
            raise EACRException.Create(10520, ErrorLInvalidFieldDataSize,
              [LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].Name,
              Integer(LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]
                  .BaseFieldType),
              Integer(LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]
                  .AdvancedFieldType),
              LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]
                .MemoryDataSize,
              LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]
                .DiskDataSize]);
        end
        else
          LTableData.SetBLOBModified(False, RecordBuffer,
            LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]);
        Move(PAnsiChar(FDiskRecordBuffer + LTableData.FFieldManager.FieldDefs
              [CHECK_NULL_FLAG_BitNo].DiskOffset)^,
          PAnsiChar(RecordBuffer + LTableData.FFieldManager.FieldDefs
              [CHECK_NULL_FLAG_BitNo].MemoryOffset)^,
          LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]
            .DiskDataSize);
      end;
    end; // if field is not Null
  end; // for
end; // CopyDataFromDiskRecordBufferToMemoryRecordBuffer

//------------------------------------------------------------------------------
// write blob value to pages
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.InternalWriteBLOBOrVarcharValue
  (SessionID: TACRSessionID;
  BLOBDescriptor
    : TACRPartialTemporaryBLOBDescriptor; PData: PAnsiChar;
  IsVarchar: Boolean; out RecordID: TACRRecordID);
var
  DataPage: TACRPage;
  NextDataPage: TACRPage;
  DataSize: Int64;
  Size: Word;
  PageFreeSpaceSize: Word;
  PageType: TACRTablePageType;
  i, PageCount, Offset: Integer;
  ItemCount: Word;
  ItemsMap: TACRDataItemsMap;
  ItemID: Word;
  bOK: Boolean;
begin
  if (IsVarchar) then
    PageType := tptVarchar
  else
    PageType := tptBLOB;
  PageFreeSpaceSize := INVALID_PAGE_RECORD_NO;
  DataSize := BLOBDescriptor.CompressedSize + SizeOf(BLOBDescriptor);
  if (DataSize < Int64(FPageDataSize - SizeOf(TACRDataItem) - SizeOf(Word)))
    then
  begin
    Size := Word(DataSize) + SizeOf(TACRDataItem);
    DataPage := FTablePageMapsManager.GetPageForAddingNewData(SessionID,
      PageType, Size, PageFreeSpaceSize);
  end // try to find small page
  else
    DataPage := FTablePageMapsManager.AddPage(SessionID, PageType);
  if (DataPage = nil) then
    raise EACRException.Create(11878, ErrorLNilPointer);
  try
    RecordID.PageNo := DataPage.PageNo;
    if ((PageFreeSpaceSize = INVALID_PAGE_RECORD_NO) and
        (DataSize >= Int64(FPageDataSize - SizeOf(TACRDataItem) - SizeOf(Word))
        )) then
    begin
      // write large blob or varchar item
      RecordID.PageItemNo := 0;
      Offset := 0;
      PageCount := DataSize div FPageDataSize + Integer
        ((DataSize mod FPageDataSize) > 0);
      for i := 1 to PageCount do
      begin
        DataPage.PageHeader.ObjectID := LTableData.TableID;
        DataPage.PageHeader.PageType := ACRPageTypeIDTableDataLarge;
        if (i = 1) then
        begin
          Move(BLOBDescriptor, DataPage.PageData^, SizeOf(BLOBDescriptor));
          if (FPageDataSize <= DataSize) then
            Size := FPageDataSize - SizeOf(BLOBDescriptor)
          else
            Size := BLOBDescriptor.CompressedSize;
          Move(PData^, PAnsiChar(DataPage.PageData + SizeOf(BLOBDescriptor))^,
            Size);
        end
        else
        begin
          if (FPageDataSize <= DataSize - Offset - SizeOf(BLOBDescriptor)) then
            Size := FPageDataSize
          else
            Size := DataSize - Offset - SizeOf(BLOBDescriptor);
          Move(PAnsiChar(PData + Offset)^, DataPage.PageData^, Size);
        end;
        FTablePageMapsManager.SetPageRecordCount(SessionID, DataPage.PageNo, 0,
          PageType);
        if (i = PageCount) then
        begin
          NextDataPage := nil;
          DataPage.PageHeader.NextPageNo := INVALID_PAGE_NO;
        end
        else
        begin
          NextDataPage := FTablePageMapsManager.AddPage(SessionID, PageType);
          DataPage.PageHeader.NextPageNo := NextDataPage.PageNo;
        end;
        LTableData.PutPage(DataPage);
        DataPage := NextDataPage;
        Inc(Offset, Size);
      end; // write pages
    end // write large blob or varchar item
    else
    begin
      Offset := 0; // offset to new data in DataPage
      if (PageFreeSpaceSize = INVALID_PAGE_RECORD_NO) then
      begin
        DataPage.PageHeader.NextPageNo := INVALID_PAGE_NO;
        DataPage.PageHeader.PageType := ACRPageTypeIDTableDataSmall;
        DataPage.PageHeader.ObjectID := LTableData.TableID;
        ItemCount := 1;
        SetLength(ItemsMap, ItemCount);
        ItemsMap[0].ItemID := 0;
        ItemsMap[0].DataSize := Word(DataSize);
        RecordID.PageItemNo := 0;
        PageFreeSpaceSize := Word(DataPage.PageDataSize - SizeOf(Word) - SizeOf
            (ItemsMap[0]) - Integer(DataSize));
      end // new page
      else
      begin
        ItemsMap := LoadDataItemsMapFromPage(10535, DataPage, ItemCount);
        SetLength(ItemsMap, ItemCount + 1);
        ItemID := 0;
        repeat
          bOK := True;
          for i := 0 to ItemCount - 1 do
            if (ItemsMap[i].ItemID = ItemID) then
            begin
              bOK := False;
              Inc(ItemID);
              break;
            end;
        until (bOK);
        for i := 0 to ItemCount - 1 do
          Inc(Offset, ItemsMap[i].DataSize);
        ItemsMap[ItemCount].ItemID := ItemID;
        ItemsMap[ItemCount].DataSize := Word(DataSize);
        RecordID.PageItemNo := ItemID;
        Inc(ItemCount);
        Dec(PageFreeSpaceSize, (Word(DataSize) + SizeOf(TACRDataItem)));
      end; // existing page
      // write data to page
      Move(BLOBDescriptor, PAnsiChar(DataPage.PageData + Offset)^,
        SizeOf(BLOBDescriptor));
      Inc(Offset, SizeOf(BLOBDescriptor));
      Move(PData^, PAnsiChar(DataPage.PageData + Offset)^,
        DataSize - SizeOf(BLOBDescriptor));
      SaveDataItemsMapToPage(DataPage, ItemsMap, ItemCount);
      FTablePageMapsManager.SetPageRecordCount(SessionID, DataPage.PageNo,
        PageFreeSpaceSize, PageType);
      ItemsMap := nil;
    end; // write small blob or varchar item
  finally
    if (DataPage <> nil) then
      LTableData.PutPage(DataPage);
  end;
end; // InternalWriteBLOBOrVarcharValue

//------------------------------------------------------------------------------
// write blob or varchar value
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.WriteBLOBOrVarcharValue
  (SessionID: TACRSessionID; FieldDef: TACRFieldDef;
  RecordBuffer: TACRRecordBuffer);
var
  RecordID: TACRRecordID;
  BLOBDescriptor: TACRPartialTemporaryBLOBDescriptor;
  InSize, OutSize: Integer;
  PData: PAnsiChar;
  IsVarchar: Boolean;
begin
  if (IsVarcharFieldType(FieldDef.BaseFieldType)) then
  begin
    IsVarchar := True;
    BLOBDescriptor.NumBlocks := -1;
    InSize := GetStrLength(PAnsiChar(RecordBuffer + FieldDef.MemoryOffset),
      FieldDef.AdvancedFieldType);
    if (FieldDef.BaseFieldType = bftVarchar) then
      Inc(InSize)
    else
      Inc(InSize, 2);
    BLOBDescriptor.UncompressedSize := InSize;
    if (FieldDef.BLOBCompressionAlgorithm <> acaNone) then
    begin
      ACRInternalCompressBuffer(FieldDef.BLOBCompressionAlgorithm,
        FieldDef.BLOBCompressionMode,
        PAnsiChar(RecordBuffer + FieldDef.MemoryOffset), InSize, PData,
        OutSize);
      BLOBDescriptor.CompressedSize := OutSize;
    end // compression
    else
    begin
      BLOBDescriptor.CompressedSize := InSize;
      PData := PAnsiChar(RecordBuffer + FieldDef.MemoryOffset);
    end; // no compression
    InternalWriteBLOBOrVarcharValue(SessionID, BLOBDescriptor, PData,
      IsVarchar, RecordID);
    Move(RecordID, PAnsiChar(FDiskRecordBuffer + FieldDef.DiskOffset)^,
      SizeOf(RecordID));
    if (FieldDef.BLOBCompressionAlgorithm <> acaNone) then
      FreeMem(PData);
  end // VarChar
  else
  begin
    IsVarchar := False;
    if (LTableData.IsBLOBModified(RecordBuffer, FieldDef)) then
    begin
      {$IFDEF X64_ON}
      NativeUint(PData) := PNativeUint(RecordBuffer + FieldDef.MemoryOffset)^;
      {$ELSE}
      Cardinal(PData) := PCardinal(RecordBuffer + FieldDef.MemoryOffset)^;
      {$ENDIF}
      BLOBDescriptor.CompressedSize := MemoryManager.GetMemoryBufferSize(PData)
        - SizeOf(TACRPartialBLOBDescriptor);
      BLOBDescriptor.NumBlocks := PACRPartialBLOBDescriptor(PData)^.NumBlocks;
      BLOBDescriptor.UncompressedSize := PACRPartialBLOBDescriptor(PData)
        ^.UncompressedSize;
      PData := PAnsiChar(PData + SizeOf(TACRPartialBLOBDescriptor));
      InternalWriteBLOBOrVarcharValue(SessionID, BLOBDescriptor, PData,
        IsVarchar, RecordID);
      // free memory with new blob value
      {$IFDEF X64_ON}
      NativeUint(PData) := PNativeUint(RecordBuffer + FieldDef.MemoryOffset)^;
      {$ELSE}
      Cardinal(PData) := PCardinal(RecordBuffer + FieldDef.MemoryOffset)^;
      {$ENDIF}
      MemoryManager.FreeAndNilMem(PData);
      // mark this record bufer as not modified to avoid destroying it once more
      Move(RecordID, PAnsiChar(RecordBuffer + FieldDef.MemoryOffset)^,
        SizeOf(RecordID));
      LTableData.SetBLOBModified(False, RecordBuffer, FieldDef);

      Move(RecordID, PAnsiChar(FDiskRecordBuffer + FieldDef.DiskOffset)^,
        SizeOf(RecordID));
    end
    else
      Move(PAnsiChar(RecordBuffer + FieldDef.MemoryOffset)^,
        PAnsiChar(FDiskRecordBuffer + FieldDef.DiskOffset)^,
        FieldDef.DiskDataSize);
  end; // BLOB
end; // WriteBLOBOrVarcharValue

//------------------------------------------------------------------------------
// read BLOB or Varchar value from disk
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.InternalReadBLOBOrVarcharValue
  (SessionID: TACRSessionID; RecordID: TACRRecordID; IsVarchar: Boolean;
  var BLOBDescriptor: TACRPartialTemporaryBLOBDescriptor;
  var PData: PAnsiChar; out DataSize: Integer);
var
  DataPage: TACRPage;
  ItemsMap: TACRDataItemsMap;
  ItemCount: Word;
  i, Size: Integer;
  bOK: Boolean;
  Offset: Integer;
  PageNo: TACRPageNo;
  ItemSize: Int64;
  StateType: TACRDBStateType;
begin
  if (IsVarchar) then
    StateType := dbstVarchar
  else
    StateType := dbstBLOB;
  if (FRepair) then
    if ((RecordID.PageNo < 0) or (RecordID.PageNo >= TACRDiskPageManager
          (LTableData.PageManager).GetTotalPageCount)) then
      raise EACRException.Create(10248, ErrorLInvalidPageNo, [PageNo]);
  DataPage := LTableData.GetPage(SessionID, RecordID.PageNo, StateType,
    LTableData.TableState.TableState, True, False, False);
  try
    if ((DataPage.PageHeader.PageType <> ACRPageTypeIDTableDataSmall) and
        (DataPage.PageHeader.PageType <> ACRPageTypeIDTableDataLarge)) then
      raise EACRException.Create(10536, ErrorLInvalidPageType,
        [DataPage.PageHeader.PageType, LTableData.TableName, RecordID.PageNo]);
    if (DataPage.PageHeader.PageType = ACRPageTypeIDTableDataSmall) then
    begin
      ItemsMap := LoadDataItemsMapFromPage(10537, DataPage, ItemCount);
      bOK := False;
      Offset := 0;
      for i := 0 to ItemCount - 1 do
        if (ItemsMap[i].ItemID = RecordID.PageItemNo) then
        begin
          bOK := True;
          ItemSize := ItemsMap[i].DataSize;
          break;
        end
        else
          Inc(Offset, ItemsMap[i].DataSize);
      if (not bOK) then
        raise EACRException.Create(10549, ErrorLLoadingRecord,
          [LTableData.TableName, SessionID, RecordID.PageNo,
          RecordID.PageItemNo]);
      if (PData = nil) then
        PData := MemoryManager.GetMem(ItemSize - SizeOf(BLOBDescriptor));
      Move(PAnsiChar(DataPage.PageData + Offset)^, BLOBDescriptor,
        SizeOf(BLOBDescriptor));
      Inc(Offset, SizeOf(BLOBDescriptor));
      Move(PAnsiChar(DataPage.PageData + Offset)^, PData^,
        ItemSize - SizeOf(BLOBDescriptor));
      DataSize := ItemSize - SizeOf(BLOBDescriptor);
    end // small page (multiple items)
    else
    begin
      Move(DataPage.PageData^, BLOBDescriptor, SizeOf(BLOBDescriptor));
      if (PData = nil) then
        PData := MemoryManager.GetMem(BLOBDescriptor.CompressedSize);
      Offset := SizeOf(BLOBDescriptor);
      if (BLOBDescriptor.CompressedSize + Offset <= DataPage.PageDataSize) then
        Size := BLOBDescriptor.CompressedSize
      else
        Size := DataPage.PageDataSize - Offset;
      Move(PAnsiChar(DataPage.PageData + Offset)^, PData^, Size);
      DataSize := Size;
      PageNo := DataPage.PageHeader.NextPageNo;
      LTableData.PutPage(DataPage);
      DataPage := nil;
      while ((PageNo <> INVALID_PAGE_NO) and
          (DataSize < BLOBDescriptor.CompressedSize)) do
      begin
        if (FRepair) then
          if ((PageNo < 0) or (PageNo >= TACRDiskPageManager
                (LTableData.PageManager).GetTotalPageCount)) then
            raise EACRException.Create(10247, ErrorLInvalidPageNo, [PageNo]);
        DataPage := LTableData.GetPage(SessionID, PageNo, StateType,
          LTableData.TableState.TableState, True, False, False);
        try
          if (BLOBDescriptor.CompressedSize - DataSize < DataPage.PageDataSize)
            then
            Size := BLOBDescriptor.CompressedSize - DataSize
          else
            Size := DataPage.PageDataSize;
          Move(DataPage.PageData^, PAnsiChar(PData + DataSize)^, Size);
          Inc(DataSize, Size);
          PageNo := DataPage.PageHeader.NextPageNo;
        finally
          LTableData.PutPage(DataPage);
          DataPage := nil;
        end;
      end; // read all pages
      if (DataSize <> BLOBDescriptor.CompressedSize) then
        raise EACRException.Create(10538, ErrorLInvalidDataSize,
          [DataSize, BLOBDescriptor.CompressedSize, LTableData.TableName,
          RecordID.PageNo]);
    end; // large page (single items)
  finally
    if (DataPage <> nil) then
      LTableData.PutPage(DataPage);
  end;
end; // InternalReadBLOBOrVarcharValue

//------------------------------------------------------------------------------
// read blob or varchar value
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.ReadBLOBOrVarcharValue
  (SessionID: TACRSessionID; FieldDef: TACRFieldDef;
  RecordBuffer: TACRRecordBuffer);
var
  RecordID: TACRRecordID;
  BLOBDescriptor: TACRPartialTemporaryBLOBDescriptor;
  InSize, OutSize: Integer;
  PData, NewPData: PAnsiChar;
  IsVarchar: Boolean;
  x: Cardinal;
begin
  Move(PAnsiChar(FDiskRecordBuffer + FieldDef.DiskOffset)^, RecordID,
    SizeOf(RecordID));
  if (IsBLOBFieldType(FieldDef.BaseFieldType)) then
  begin
    IsVarchar := False;
    PData := nil;
  end // blob
  else
  begin
    IsVarchar := True;
    if (FieldDef.BLOBCompressionAlgorithm = acaNone) then
      PData := PAnsiChar(RecordBuffer + FieldDef.MemoryOffset)
    else
      PData := nil;
  end; // VarChar
  InternalReadBLOBOrVarcharValue(SessionID, RecordID, IsVarchar,
    BLOBDescriptor, PData, InSize);
  if (IsVarchar) then
  begin
    if (FieldDef.BLOBCompressionAlgorithm <> acaNone) then
    begin
      OutSize := BLOBDescriptor.UncompressedSize;
      ACRInternalDecompressBuffer(FieldDef.BLOBCompressionAlgorithm, PData,
        InSize, NewPData, OutSize);
      Move(NewPData^, PAnsiChar(RecordBuffer + FieldDef.MemoryOffset)^,
        OutSize);
      MemoryManager.FreeAndNilMem(PData);
      FreeMem(NewPData);
    end;
  end // VarChar
  else
  begin
    NewPData := MemoryManager.GetMem(BLOBDescriptor.CompressedSize + SizeOf
        (TACRPartialBLOBDescriptor));
    Move(PData^, PAnsiChar(NewPData + SizeOf(TACRPartialBLOBDescriptor))^,
      InSize);
    MemoryManager.FreeAndNilMem(PData);
    PACRPartialBLOBDescriptor(NewPData)^.NumBlocks := BLOBDescriptor.NumBlocks;
    PACRPartialBLOBDescriptor(NewPData)^.UncompressedSize :=
      BLOBDescriptor.UncompressedSize;
    x := Cardinal(NewPData);
    Move(x, PAnsiChar(RecordBuffer + FieldDef.MemoryOffset)^, SizeOf(Cardinal));
  end; // blob
end; // ReadBLOBOrVarcharValue

//------------------------------------------------------------------------------
// delete blob or varchar value
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.DeleteBLOBOrVarcharValue
  (SessionID: TACRSessionID; FieldDef: TACRFieldDef);
var
  RecordID: TACRRecordID;
  DataPage: TACRPage;
  PageNo, NextPageNo: TACRPageNo;
  Offset, i, ItemNo, Size, DataSize, OverallSize: Integer;
  ItemCount: Word;
  ItemsMap: TACRDataItemsMap;
  PageType: TACRTablePageType;
  StateType: TACRDBStateType;
begin
  if (IsVarcharFieldType(FieldDef.BaseFieldType)) then
  begin
    PageType := tptVarchar;
    StateType := dbstVarchar;
  end
  else
  begin
    PageType := tptBLOB;
    StateType := dbstBLOB;
  end;
  Move(PAnsiChar(FDiskRecordBuffer + FieldDef.DiskOffset)^, RecordID,
    SizeOf(RecordID));
  PageNo := RecordID.PageNo;
  DataPage := LTableData.GetPage(SessionID, PageNo, StateType,
    LTableData.TableState.TableState, True, False, False);
  try
    if ((DataPage.PageHeader.PageType <> ACRPageTypeIDTableDataSmall) and
        (DataPage.PageHeader.PageType <> ACRPageTypeIDTableDataLarge)) then
      raise EACRException.Create(10544, ErrorLInvalidPageType,
        [DataPage.PageHeader.PageType, LTableData.TableName, PageNo]);
    if (DataPage.PageHeader.PageType = ACRPageTypeIDTableDataSmall) then
    begin
      ItemsMap := LoadDataItemsMapFromPage(10545, DataPage, ItemCount);
      try
        if (ItemCount = 1) then
        begin
          FTablePageMapsManager.RemovePage(SessionID, PageNo, PageType);
          LTableData.PutPage(DataPage);
          DataPage := nil;
          LTableData.RemovePage(SessionID, PageNo, StateType,
            LTableData.TableState.TableState);
        end // delete last item and page
        else
        begin
          Offset := 0;
          Size := 0;
          DataSize := 0;
          OverallSize := 0;
          ItemNo := -1;
          for i := 0 to ItemCount - 1 do
          begin
            if (ItemsMap[i].ItemID <> RecordID.PageItemNo) then
              Inc(OverallSize, ItemsMap[i].DataSize);
            // if (ItemsMap[i].ItemID <= RecordID.PageItemNo) then
            if (ItemNo = -1) then
              Inc(Offset, ItemsMap[i].DataSize);
            // if (ItemsMap[i].ItemID > RecordID.PageItemNo) then
            if (ItemsMap[i].ItemID = RecordID.PageItemNo) then
            begin
              ItemNo := i;
              DataSize := ItemsMap[i].DataSize;
            end
            else if (ItemNo <> -1) then
              Inc(Size, ItemsMap[i].DataSize);
          end; // search item in the map
          if (ItemNo = -1) then
            raise EACRException.Create(10546,
              ErrorLDeleteRecordInvalidDataItem, [LTableData.TableName,
              FieldDef.Name, RecordID.PageNo, RecordID.PageItemNo, ItemCount]);
          if (DataSize = 0) then
            raise EACRException.Create(10546,
              ErrorLDeleteRecordInvalidDataItem, [LTableData.TableName,
              FieldDef.Name, RecordID.PageNo, RecordID.PageItemNo, ItemCount]);
          Move(PAnsiChar(DataPage.PageData + Offset)^,
            PAnsiChar(DataPage.PageData + Offset - DataSize)^, Size);
          if (ItemNo < ItemCount - 1) then
            Move(ItemsMap[ItemNo + 1], ItemsMap[ItemNo],
              SizeOf(TACRDataItem) * (ItemCount - 1 - ItemNo));
          Dec(ItemCount);
          SaveDataItemsMapToPage(DataPage, ItemsMap, ItemCount);
          LTableData.UpdatePage(SessionID, DataPage, StateType,
            LTableData.TableState.TableState, False);
          Inc(OverallSize, SizeOf(TACRDataItem) * ItemCount + SizeOf(Word));
          FTablePageMapsManager.SetPageRecordCount(SessionID, PageNo,
            (DataPage.PageDataSize - OverallSize), PageType);
        end; // delete this item from the page
      finally
        ItemsMap := nil;
      end;
    end // small page (multiple items on page)
    else
    begin
      repeat
        FTablePageMapsManager.RemovePage(SessionID, PageNo, PageType);
        NextPageNo := DataPage.PageHeader.NextPageNo;
        LTableData.PutPage(DataPage);
        DataPage := nil;
        LTableData.RemovePage(SessionID, PageNo, StateType,
          LTableData.TableState.TableState);
        PageNo := NextPageNo;
        if (PageNo <> INVALID_PAGE_NO) then
          DataPage := LTableData.GetPage(SessionID, PageNo, StateType,
            LTableData.TableState.TableState, True, False, False);
      until (PageNo = INVALID_PAGE_NO);
    end; // large page (single item on page)
  finally
    if (DataPage <> nil) then
      LTableData.PutPage(DataPage);
  end;
end; // DeleteBLOBOrVarcharValue

//------------------------------------------------------------------------------
// load record from disk into new allocated buffer
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.LoadDiskRecord(SessionID: TACRSessionID;
  RecordID: TACRRecordID; DiskRecordBuffer: TACRRecordBuffer);
begin
  if (FLargeRows) then
    InternalLoadDiskRecordLarge(SessionID, RecordID, DiskRecordBuffer)
  else
    InternalLoadDiskRecordSmall(SessionID, RecordID, DiskRecordBuffer);
end; // LoadDiskRecord

//------------------------------------------------------------------------------
// load record from disk into new allocated buffer
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.InternalLoadDiskRecordLarge
  (SessionID: TACRSessionID; RecordID: TACRRecordID;
  DiskRecordBuffer: TACRRecordBuffer);
var
  Offset, Size: Integer;
  RowPage: TACRPage;
  PageNo: TACRPageNo;
begin
  PageNo := RecordID.PageNo;
  Offset := 0;
  repeat
    RowPage := LTableData.GetPage(SessionID, PageNo, dbstRow,
      LTableData.TableState.TableState, True, False, False);
    try
      PageNo := RowPage.PageHeader.NextPageNo;
      if (PageNo = INVALID_PAGE_NO) then
        Size := FDiskRecordBufferSize - Offset
      else
        Size := RowPage.PageDataSize;
      if (Offset + Size > FDiskRecordBufferSize) then
        raise EACRException.Create(10524, ErrorLInvalidDiskRecordSize,
          [LTableData.TableName, Offset, Size, FDiskRecordBufferSize,
          RowPage.PageNo, PageNo]);
      Move(RowPage.PageData^, PAnsiChar(DiskRecordBuffer + Offset)^, Size);
      Inc(Offset, Size);
    finally
      LTableData.PutPage(RowPage);
    end;
  until (PageNo = INVALID_PAGE_NO);
end; // LoadDiskRecordLarge

//------------------------------------------------------------------------------
// load record from disk into new allocated buffer
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.InternalLoadDiskRecordSmall
  (SessionID: TACRSessionID; RecordID: TACRRecordID;
  DiskRecordBuffer: TACRRecordBuffer);
var
  Offset: Integer;
  RowPage: TACRPage;
{$I ACR_check_null_flag_var.inc}
begin
{$IFDEF DEBUG_TRACE_TACRDiskRecordManager_InternalLoadDiskRecordSmall}
  aaWriteToLog('> TACRDiskRecordManager.InternalLoadDiskRecordSmall' + #13#10 +
      'SessionID = ' + IntToStr(SessionID) + #13#10 + 'RecordID.PageNo = ' +
      IntToStr(RecordID.PageNo) + #13#10 + 'RecordID.PageItemNo = ' + IntToStr
      (RecordID.PageItemNo) + #13#10 + 'DiskRecordBuffer = ' + IntToHex
      (Integer(DiskRecordBuffer), 8));
{$ENDIF}
  RowPage := LTableData.GetPage(SessionID, RecordID.PageNo, dbstRow,
    LTableData.TableState.TableState, True, False, False);
{$IFDEF DEBUG_TRACE_TACRDiskRecordManager_InternalLoadDiskRecordSmall}
  aaWriteToLog('RowPage = ' + IntToHex(Integer(RowPage), 8));
  aaWriteToLog('RowPage.PageData = ' + IntToHex(Integer(RowPage.PageData), 8));
  aaWriteToLog('TACRDiskRecordManager.InternalLoadDiskRecordSmall' + #13#10 +
      'SessionID = ' + IntToStr(SessionID) + #13#10 + 'RowPage.PageNo = ' +
      IntToStr(RowPage.PageNo) + #13#10 + 'RecordID.PageNo = ' + IntToStr
      (RecordID.PageNo) + #13#10 + 'RecordID.PageItemNo = ' + IntToStr
      (RecordID.PageItemNo) + #13#10 + 'DiskRecordBuffer = ' + IntToHex
      (Integer(DiskRecordBuffer), 8));
  if (RowPage <> nil) then
    if (RowPage.PageData <> nil) then
      aaWriteToLog('First 4 bytes of page data: ' + #9 + IntToHex
          (pInteger(RowPage.PageData)^, 8));
{$ENDIF}
  try
    CHECK_NULL_FLAG_BitNo := RecordID.PageItemNo;
    CHECK_NULL_FLAG_NullFlags := RowPage.PageData;
{$I ACR_check_null_flag.inc}
    if (CHECK_NULL_FLAG_Result) then
      raise EACRException.Create(10525, ErrorLDiskRecordIsDeleted,
        [LTableData.TableName, RecordID.PageNo, RecordID.PageItemNo]);
    Offset := FRecordsPerPage div 8 + Integer((FRecordsPerPage mod 8) > 0)
      + RecordID.PageItemNo * FDiskRecordBufferSize;
    if (Offset + FDiskRecordBufferSize > RowPage.PageDataSize) then
      raise EACRException.Create(10526, ErrorLInvalidDiskRecordSize,
        [LTableData.TableName, Offset, FDiskRecordBufferSize,
        RowPage.PageDataSize, RecordID.PageNo, RecordID.PageItemNo]);
    Move(PAnsiChar(RowPage.PageData + Offset)^, DiskRecordBuffer^,
      FDiskRecordBufferSize);
{$IFDEF DEBUG_TRACE_TACRDiskRecordManager_InternalLoadDiskRecordSmall}
    aaWriteToLog('< TACRDiskRecordManager.InternalLoadDiskRecordSmall' +
        #13#10 + 'SessionID = ' + IntToStr(SessionID)
        + #13#10 + 'RecordID.PageNo = ' + IntToStr(RecordID.PageNo)
        + #13#10 + 'RecordID.PageItemNo = ' + IntToStr(RecordID.PageItemNo)
        + #13#10 + 'DiskRecordBuffer = ' + IntToHex(Integer(DiskRecordBuffer),
        8));
{$ENDIF}
  finally
    LTableData.PutPage(RowPage);
{$IFDEF DEBUG_TRACE_TACRDiskRecordManager_InternalLoadDiskRecordSmall}
    aaWriteToLog('<< TACRDiskRecordManager.InternalLoadDiskRecordSmall' +
        #13#10 + 'SessionID = ' + IntToStr(SessionID)
        + #13#10 + 'RecordID.PageNo = ' + IntToStr(RecordID.PageNo)
        + #13#10 + 'RecordID.PageItemNo = ' + IntToStr(RecordID.PageItemNo)
        + #13#10 + 'DiskRecordBuffer = ' + IntToHex(Integer(DiskRecordBuffer),
        8));
{$ENDIF}
  end;
end; // LoadDiskRecordSmall

//------------------------------------------------------------------------------
// return true if record exists
//------------------------------------------------------------------------------
function TACRDiskRecordManager.InternalIsRecordExistsLarge
  (SessionID: TACRSessionID; var RecordID: TACRRecordID): Boolean;
var
  PageRecordCount: Word;
  TablePageType: TACRTablePageType;
begin
  FTablePageMapsManager.GetPageTypeAndRecordCount(SessionID, RecordID.PageNo,
    TablePageType, PageRecordCount);
  if (TablePageType <> tptRowStart) then
    Result := False
  else
    Result := (PageRecordCount = 1); // in large mode only 1 record can be in the page
end; // InternalIsRecordExistsLarge

//------------------------------------------------------------------------------
// return true if record exists
//------------------------------------------------------------------------------
function TACRDiskRecordManager.InternalIsRecordExistsSmall
  (SessionID: TACRSessionID; var RecordID: TACRRecordID): Boolean;
var
  PageRecordCount: Word;
  TablePageType: TACRTablePageType;
  RowPage: TACRPage;
{$I ACR_check_null_flag_var.inc}
begin
  Result := False;
  FTablePageMapsManager.GetPageTypeAndRecordCount(SessionID, RecordID.PageNo,
    TablePageType, PageRecordCount);
  if ((TablePageType = tptRowStart) and (PageRecordCount <
        INVALID_PAGE_RECORD_NO) and (PageRecordCount > 0)) then
  begin
    RowPage := LTableData.GetPage(SessionID, RecordID.PageNo, dbstRow,
      LTableData.TableState.TableState, True, False, False);
    try
      CHECK_NULL_FLAG_BitNo := RecordID.PageItemNo;
      CHECK_NULL_FLAG_NullFlags := RowPage.PageData;
{$I ACR_check_null_flag.inc}
      Result := not CHECK_NULL_FLAG_Result;
    finally
      LTableData.PutPage(RowPage);
    end;
  end; // there are some records in this page
end; // InternalIsRecordExistsSmall

//------------------------------------------------------------------------------
// add record and return its number (RecordSize > PageDataSize div 2)
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.InternalAddRecordLarge
  (RecordBuffer: TACRRecordBuffer; var RecordID: TACRRecordID;
  SessionID: TACRSessionID);
var
  i, PageCount, Size, Offset: Integer;
  RowPage: TACRPage;
  NextRowPage: TACRPage;
begin
  GetDiskRecordBufferFromRecordBuffer(SessionID, RecordBuffer);
  // write row to pages
  PageCount := FDiskRecordBufferSize div FPageDataSize + Integer
    ((FDiskRecordBufferSize mod FPageDataSize) > 0);
  Offset := 0;
  for i := 1 to PageCount do
  begin
    if (i = 1) then
    begin
      RowPage := FTablePageMapsManager.AddPage(SessionID, tptRowStart);
      RecordID.PageNo := RowPage.PageNo;
      RecordID.PageItemNo := 0;
    end;
    if (Offset + FPageDataSize <= FDiskRecordBufferSize) then
      Size := FPageDataSize
    else
      Size := FDiskRecordBufferSize - Offset;
    Move(PAnsiChar(FDiskRecordBuffer + Offset)^, RowPage.PageData^, Size);
    if (i = 1) then
      FTablePageMapsManager.SetPageRecordCount(SessionID, RowPage.PageNo, 1,
        tptRowStart)
    else
      FTablePageMapsManager.SetPageRecordCount(SessionID, RowPage.PageNo, 0,
        tptRowContinue);
    if (i = PageCount) then
    begin
      NextRowPage := nil;
      RowPage.PageHeader.NextPageNo := INVALID_PAGE_NO;
    end
    else
    begin
      NextRowPage := FTablePageMapsManager.AddPage(SessionID, tptRowContinue);
      RowPage.PageHeader.NextPageNo := NextRowPage.PageNo;
    end;
    RowPage.PageHeader.ObjectID := LTableData.TableID;
    RowPage.PageHeader.PageType := ACRPageTypeIDTableRows;
    if (not RowPage.Updated) then
      raise EACRException.Create(11879, ErrorLPageIsNotUpdated,
        [RowPage.PageNo]);
    LTableData.PutPage(RowPage);
    RowPage := NextRowPage;
    Inc(Offset, Size);
  end;
end; // InternalAddRecordLarge

//------------------------------------------------------------------------------
// add record and return its number (RecordSize <= PageDataSize div 2)
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.InternalAddRecordSmall
  (RecordBuffer: TACRRecordBuffer; var RecordID: TACRRecordID;
  SessionID: TACRSessionID);
var
  Size, Offset: Integer;
  RowPage: TACRPage;
  PageRecordCount: Word;
{$I ACR_check_null_flag_var.inc}
{$I ACR_set_null_flag_var.inc}
begin
{$IFDEF DEBUG_TRACE_TACRDiskRecordManager_InternalAddRecordSmall}
  aaWriteToLog('> TACRDiskRecordManager.InternalAddRecordSmall' + #13#10 +
      'SessionID = ' + IntToStr(SessionID) + #13#10 + 'RecordBuffer = ' +
      IntToHex(Integer(RecordBuffer), 8));
{$ENDIF}
  GetDiskRecordBufferFromRecordBuffer(SessionID, RecordBuffer);
  // write row to page
  RowPage := FTablePageMapsManager.GetPageForAddingNewData(SessionID,
    tptRowStart, FRecordsPerPage, PageRecordCount);
  if (not RowPage.Updated) then
    raise EACRException.Create(11880, ErrorLPageIsNotUpdated, [RowPage.PageNo]);
  try
{$IFDEF DEBUG_TRACE_TACRDiskRecordManager_InternalAddRecordSmall}
    aaWriteToLog('TACRDiskRecordManager.InternalAddRecordSmall' + #13#10 +
        'SessionID = ' + IntToStr(SessionID) + #13#10 + 'RowPage.PageNo = ' +
        IntToStr(RowPage.PageNo) + #13#10 + 'RecordBuffer = ' + IntToHex
        (Integer(RecordBuffer), 8));
{$ENDIF}
    Size := FRecordsPerPage div 8 + Integer((FRecordsPerPage mod 8) > 0);
    if (PageRecordCount = INVALID_PAGE_RECORD_NO) then
    begin
      // mark all records as empty
      FillChar(RowPage.PageData^, Size, $FF);
    end;
    RowPage.PageHeader.ObjectID := LTableData.TableID;
    RowPage.PageHeader.PageType := ACRPageTypeIDTableRows;
    RecordID.PageNo := RowPage.PageNo;
    RecordID.PageItemNo := INVALID_PAGE_RECORD_NO;
    CHECK_NULL_FLAG_NullFlags := RowPage.PageData;
    for CHECK_NULL_FLAG_BitNo := 0 to FRecordsPerPage - 1 do
    begin
{$I ACR_check_null_flag.inc}
      if (CHECK_NULL_FLAG_Result) then
      begin
        RecordID.PageItemNo := CHECK_NULL_FLAG_BitNo;
        break;
      end;
    end;
    if (RecordID.PageItemNo = INVALID_PAGE_RECORD_NO) then
    begin
      LTableData.PutPage(RowPage);
      raise EACRException.Create(10527, ErrorLCannotAddDiskRecordSmall,
        [LTableData.TableName, RecordID.PageNo]);
    end;
    if ((PageRecordCount <> INVALID_PAGE_RECORD_NO) and
        (PageRecordCount >= FRecordsPerPage)) then
    begin
      LTableData.PutPage(RowPage);
      raise EACRException.Create(10529, ErrorLInvalidPageRecordCount,
        [LTableData.TableName, PageRecordCount, FRecordsPerPage]);
    end;
    RowPage.PageHeader.NextPageNo := INVALID_PAGE_NO;
    if (PageRecordCount = INVALID_PAGE_RECORD_NO) then
    begin
      // new empty page was allocated
      PageRecordCount := 1;
    end
    else
      Inc(PageRecordCount);

    SET_NULL_FLAG_ToSet := False;
    SET_NULL_FLAG_BitNo := RecordID.PageItemNo;
    SET_NULL_FLAG_NullFlags := RowPage.PageData;
{$I ACR_set_null_flag.inc}
    Offset := Size + RecordID.PageItemNo * FDiskRecordBufferSize;
    if (Offset + FDiskRecordBufferSize > RowPage.PageDataSize) then
      raise EACRException.Create(10528, ErrorLInvalidDiskRecordSize,
        [LTableData.TableName, Offset, RowPage.PageDataSize,
        FDiskRecordBufferSize, RowPage.PageNo, RowPage.PageHeader.NextPageNo]);
    Move(FDiskRecordBuffer^, PAnsiChar(RowPage.PageData + Offset)^,
      FDiskRecordBufferSize);
    FTablePageMapsManager.SetPageRecordCount(SessionID, RowPage.PageNo,
      PageRecordCount, tptRowStart);
{$IFDEF DEBUG_TRACE_TACRDiskRecordManager_InternalAddRecordSmall}
    aaWriteToLog('< TACRDiskRecordManager.InternalAddRecordSmall' + #13#10 +
        'SessionID = ' + IntToStr(SessionID)
        + #13#10 + 'First 4 bytes = ' + #9 + IntToHex
        (pInteger(RowPage.PageData)^,
        8) + #13#10 + 'RowPage.PageNo = ' + IntToStr(RowPage.PageNo)
        + #13#10 + 'PageRecordCount = ' + IntToStr(PageRecordCount)
        + #13#10 + 'RecordID.PageNo = ' + IntToStr(RecordID.PageNo)
        + #13#10 + 'RecordID.PageItemNo = ' + IntToStr(RecordID.PageItemNo)
        + #13#10 + 'RecordBuffer = ' + IntToHex(Integer(RecordBuffer), 8));
{$ENDIF}
  finally
    LTableData.PutPage(RowPage);
  end;
end; // InternalAddRecordSmall

//------------------------------------------------------------------------------
// delete record, return true if record was deleted, false if record was deleted earlier
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.InternalDeleteRecordSmall
  (var RecordID: TACRRecordID; SessionID: TACRSessionID);
var
  RowPage: TACRPage;
  RecordCount: Word;
{$I ACR_set_null_flag_var.inc}
begin
  RecordCount := FTablePageMapsManager.GetPageRecordCount(SessionID,
    RecordID.PageNo);
  if (RecordCount = 0) then
    raise EACRException.Create(10539, ErrorLInvalidPageRecordCount,
      [LTableData.TableName, RecordCount, FRecordsPerPage]);
  if (RecordCount = INVALID_PAGE_RECORD_NO) then
    raise EACRException.Create(10540, ErrorLInvalidPageRecordCount,
      [LTableData.TableName, RecordCount, FRecordsPerPage]);
  if (RecordCount = 1) then
  begin
    FTablePageMapsManager.RemovePage(SessionID, RecordID.PageNo, tptRowStart);
    LTableData.RemovePage(SessionID, RecordID.PageNo, dbstRow,
      LTableData.TableState.TableState);
  end // last record will be deleted - empty page
  else
  begin
    FTablePageMapsManager.SetPageRecordCount(SessionID, RecordID.PageNo,
      (RecordCount - 1), tptRowStart);
    RowPage := LTableData.GetPage(SessionID, RecordID.PageNo, dbstRow,
      LTableData.TableState.TableState, True, True, False);
    try
      SET_NULL_FLAG_ToSet := True;
      SET_NULL_FLAG_BitNo := RecordID.PageItemNo;
      SET_NULL_FLAG_NullFlags := RowPage.PageData;
{$I ACR_set_null_flag.inc}
    finally
      LTableData.PutPage(RowPage);
    end;
  end;
end; // InternalDeleteRecordSmall

//------------------------------------------------------------------------------
// delete record, return true if record was deleted, false if record was deleted earlier
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.InternalDeleteRecordLarge
  (var RecordID: TACRRecordID; SessionID: TACRSessionID);
var
  PageNo: TACRPageNo;
  RecordCount: Word;
  RowPage: TACRPage;
  NextPageNo: TACRPageNo;
  DataSize: Integer;
begin
  RecordCount := FTablePageMapsManager.GetPageRecordCount(SessionID,
    RecordID.PageNo);
  if (RecordCount <> 1) then
    raise EACRException.Create(10541, ErrorLInvalidPageRecordCount,
      [LTableData.TableName, RecordCount, FRecordsPerPage]);
  PageNo := RecordID.PageNo;
  DataSize := 0;
  while (PageNo <> INVALID_PAGE_NO) do
  begin
    if (DataSize > FDiskRecordBufferSize) then
      raise EACRException.Create(10542, ErrorLInvalidDataSize,
        [LTableData.TableName, RecordID.PageNo, PageNo]);
    try
      RowPage := LTableData.GetPage(SessionID, PageNo, dbstRow,
        LTableData.TableState.TableState, True, False, False);
    except
      raise EACRException.Create(10543, ErrorLDeleteRecordInvalidDataSize,
        [LTableData.TableName, RecordID.PageNo, PageNo, DataSize,
        FDiskRecordBufferSize]);
    end;
    try
      if (PageNo = RecordID.PageNo) then
        FTablePageMapsManager.RemovePage(SessionID, PageNo, tptRowStart)
      else
        FTablePageMapsManager.RemovePage(SessionID, PageNo, tptRowContinue);
      NextPageNo := RowPage.PageHeader.NextPageNo;
      Inc(DataSize, RowPage.PageDataSize);
    finally
      LTableData.PutPage(RowPage);
    end;
    LTableData.RemovePage(SessionID, PageNo, dbstRow,
      LTableData.TableState.TableState);
    PageNo := NextPageNo;
  end;
end; // InternalDeleteRecordLarge

//------------------------------------------------------------------------------
// update record (RecordSize > PageDataSize div 2)
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.InternalUpdateRecordLarge
  (RecordBuffer: TACRRecordBuffer; var RecordID: TACRRecordID;
  SessionID: TACRSessionID);
var
  RowPage: TACRPage;
  PageNo: TACRPageNo;
  Offset: Integer;
  Size: Integer;
begin
  GetDiskRecordBufferFromRecordBuffer(SessionID, RecordBuffer);
  PageNo := RecordID.PageNo;
  Offset := 0;
  while (Offset < FDiskRecordBufferSize) do
  begin
    RowPage := LTableData.GetPage(SessionID, PageNo, dbstRow,
      LTableData.TableState.TableState, True, True, False);
    try
      PageNo := RowPage.PageHeader.NextPageNo;
      if ((FDiskRecordBufferSize - Offset) < RowPage.PageDataSize) then
        Size := FDiskRecordBufferSize - Offset
      else
        Size := RowPage.PageDataSize;
      Move(PAnsiChar(FDiskRecordBuffer + Offset)^, RowPage.PageData^, Size);
    finally
      LTableData.PutPage(RowPage);
    end;
    Inc(Offset, Size);
  end;
end; // InternalUpdateRecordLarge

//------------------------------------------------------------------------------
// update record (RecordSize <= PageDataSize div 2)
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.InternalUpdateRecordSmall
  (RecordBuffer: TACRRecordBuffer; var RecordID: TACRRecordID;
  SessionID: TACRSessionID);
var
  RowPage: TACRPage;
  Offset: Integer;
begin
  GetDiskRecordBufferFromRecordBuffer(SessionID, RecordBuffer);
  RowPage := LTableData.GetPage(SessionID, RecordID.PageNo, dbstRow,
    LTableData.TableState.TableState, True, True, False);
  try
    Offset := FRecordsPerPage div 8 + Integer((FRecordsPerPage mod 8) > 0)
      + RecordID.PageItemNo * FDiskRecordBufferSize;
    if (Offset + FDiskRecordBufferSize > RowPage.PageDataSize) then
      raise EACRException.Create(10547, ErrorLInvalidDiskRecordSize,
        [LTableData.TableName, Offset, FDiskRecordBufferSize,
        RecordID.PageNo, INVALID_PAGE_NO]);
    Move(FDiskRecordBuffer^, PAnsiChar(RowPage.PageData + Offset)^,
      FDiskRecordBufferSize);
  finally
    LTableData.PutPage(RowPage);
  end;
end; // InternalUpdateRecordSmall

//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRDiskRecordManager.Create(RecordBufferSize: Integer;
  DiskRecordBufferSize: Integer; aTableData: TACRDiskTableData);
begin
  if (aTableData = nil) then
    raise EACRException.Create(11876, ErrorLNilPointer);
  if (aTableData.PageManager = nil) then
    raise EACRException.Create(11877, ErrorLNilPointer);
  FRepair := False;
  FRecordBufferSize := RecordBufferSize;
  FDiskRecordBufferSize := DiskRecordBufferSize;
  FDiskRecordBuffer := MemoryManager.GetMem(DiskRecordBufferSize);
  LTableData := aTableData;
  FPageDataSize := LTableData.PageManager.PageDataSize;
  FTablePageMapsManager := TACRTablePageMapsManager.Create(LTableData,
    LTableData.FRandomSearchRetryCount);
  FLargeRows := (FDiskRecordBufferSize > ((FPageDataSize - 1) div 2));
  if (FLargeRows) then
    FRecordsPerPage := 1
  else
  begin
    FRecordsPerPage := FPageDataSize div FDiskRecordBufferSize;
    while (FRecordsPerPage * FDiskRecordBufferSize + ((FRecordsPerPage div 8)
          + Integer((FRecordsPerPage mod 8) > 0)) > FPageDataSize) do
      Dec(FRecordsPerPage);
    if (FRecordsPerPage <= 1) then
      raise EACRException.Create(10522, ErrorLCannotCalculateRecordsPerPage,
        [FRecordsPerPage, FDiskRecordBufferSize, FPageDataSize]);
  end;
end; // Create;

//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRDiskRecordManager.Destroy;
begin
  if (FTablePageMapsManager <> nil) then
  begin
    FTablePageMapsManager.Free;
    FTablePageMapsManager := nil;
  end;
  MemoryManager.FreeAndNilMem(FDiskRecordBuffer);
  inherited Destroy;
end; // Destroy

//------------------------------------------------------------------------------
// return record count
//------------------------------------------------------------------------------
function TACRDiskRecordManager.GetRecordCount: TACRRecordNo;
begin
  Result := FTablePageMapsManager.GetRecordCount;
end; // GetRecordCount

//------------------------------------------------------------------------------
// empty table (delete all records)
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.Empty(SessionID: TACRSessionID);
begin
  FTablePageMapsManager.Empty(SessionID);
end; // Empty

//------------------------------------------------------------------------------
// add record and return its number
//------------------------------------------------------------------------------
function TACRDiskRecordManager.AddRecord(RecordBuffer: TACRRecordBuffer;
  var RecordID: TACRRecordID; SessionID: TACRSessionID): Boolean;
begin
  Result := True;
  try
    if (FLargeRows) then
      InternalAddRecordLarge(RecordBuffer, RecordID, SessionID)
    else
      InternalAddRecordSmall(RecordBuffer, RecordID, SessionID);
  except
    raise ;
  end;
end; // AddRecord

//------------------------------------------------------------------------------
// update record, return true if record was updated, false if record was deleted
//------------------------------------------------------------------------------
function TACRDiskRecordManager.UpdateRecord(RecordBuffer: TACRRecordBuffer;
  RecordID: TACRRecordID; SessionID: TACRSessionID): Boolean;
var
{$I ACR_check_null_flag_var.inc}
begin
  Result := True;
  try
    if (LTableData.FieldManager.FieldDefs.VarcharOrBLOBFieldsExists) then
    begin
      LoadDiskRecord(SessionID, RecordID, FDiskRecordBuffer);
      // delete old blob values
      CHECK_NULL_FLAG_NullFlags := FDiskRecordBuffer;
      for CHECK_NULL_FLAG_BitNo :=
        0 to LTableData.FieldManager.FieldDefs.Count - 1 do
      begin
{$I ACR_check_null_flag.inc}
        if (not CHECK_NULL_FLAG_Result) then
        begin
          if (IsBLOBFieldType(LTableData.FFieldManager.FieldDefs
                [CHECK_NULL_FLAG_BitNo].BaseFieldType)) then
            if (LTableData.IsBLOBModified(RecordBuffer,
                LTableData.FFieldManager.FieldDefs
                  [CHECK_NULL_FLAG_BitNo])) then
              DeleteBLOBOrVarcharValue(SessionID,
                LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]);
          if (IsVarcharFieldType(LTableData.FFieldManager.FieldDefs
                [CHECK_NULL_FLAG_BitNo].BaseFieldType)) then
            DeleteBLOBOrVarcharValue(SessionID,
              LTableData.FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]);
        end;
      end;
    end; // delete old blob and varchar values
    if (FLargeRows) then
      InternalUpdateRecordLarge(RecordBuffer, RecordID, SessionID)
    else
      InternalUpdateRecordSmall(RecordBuffer, RecordID, SessionID);
  except
    raise ;
  end;
end; // UpdateRecord

//------------------------------------------------------------------------------
// delete record, return true if record was deleted, false if record was deleted earlier
//------------------------------------------------------------------------------
function TACRDiskRecordManager.DeleteRecord(var RecordID: TACRRecordID;
  SessionID: TACRSessionID): Boolean;
var
{$I ACR_check_null_flag_var.inc}
begin
  Result := True;
  try
    if (LTableData.FieldManager.FieldDefs.VarcharOrBLOBFieldsExists) then
    begin
      LoadDiskRecord(SessionID, RecordID, FDiskRecordBuffer);
      CHECK_NULL_FLAG_NullFlags := FDiskRecordBuffer;
      for CHECK_NULL_FLAG_BitNo :=
        0 to LTableData.FieldManager.FieldDefs.Count - 1 do
      begin
{$I ACR_check_null_flag.inc}
        if (not CHECK_NULL_FLAG_Result) then
          if ((IsBLOBFieldType(LTableData.FFieldManager.FieldDefs
                  [CHECK_NULL_FLAG_BitNo].BaseFieldType)) or
              (IsVarcharFieldType(LTableData.FFieldManager.FieldDefs
                  [CHECK_NULL_FLAG_BitNo].BaseFieldType))) then
            DeleteBLOBOrVarcharValue(SessionID,
              LTableData.FieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]);
      end;
    end; // delete varchar and blobs
    if (FLargeRows) then
      InternalDeleteRecordLarge(RecordID, SessionID)
    else
      InternalDeleteRecordSmall(RecordID, SessionID);
  except
    raise ;
  end;
end; // DeleteRecord

//------------------------------------------------------------------------------
// return true if record exists
//------------------------------------------------------------------------------
function TACRDiskRecordManager.IsRecordExists(var RecordID: TACRRecordID;
  SessionID: TACRSessionID): Boolean;
begin
  Result := False;
  if (GetRecordCount > 0) then
  begin
    if (FLargeRows) then
      Result := InternalIsRecordExistsLarge(SessionID, RecordID)
    else
      Result := InternalIsRecordExistsSmall(SessionID, RecordID);
  end;
end; // IsRecordExists

//------------------------------------------------------------------------------
// get record
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.GetRecordBuffer
  (var NavigationInfo: TACRNavigationInfo);
begin
{$IFDEF DEBUG_LOCATE_TIME}
  aaIncCounter(counter24);
  aaStartTime(time24);
{$ENDIF}
{$IFDEF DEBUG_SQL_TIME}
  aaStartTime(time7);
{$ENDIF}
{$IFDEF DEBUG_DECRYPTION_TIME}
  aaStartTime(time4);
  aaIncCounter(counter4);
{$ENDIF}
  // get record relatively to the first position
  if (NavigationInfo.FirstPosition) then
  begin
    NavigationInfo.GetRecordResult := GetRecordFromFirstPosition
      (NavigationInfo.SessionID, NavigationInfo.GetRecordMode,
      NavigationInfo.RecordID);
    if (NavigationInfo.GetRecordResult = grrOk) then
      NavigationInfo.FirstPosition := False;
  end
  else
  // get record relatively to the last position
    if (NavigationInfo.LastPosition) then
  begin
    NavigationInfo.GetRecordResult := GetRecordFromLastPosition
      (NavigationInfo.SessionID, NavigationInfo.GetRecordMode,
      NavigationInfo.RecordID);
    if (NavigationInfo.GetRecordResult = grrOk) then
      NavigationInfo.LastPosition := False;
  end
  else
    NavigationInfo.GetRecordResult := GetRecordFromAnyPosition
      (NavigationInfo.SessionID, NavigationInfo.GetRecordMode,
      NavigationInfo.RecordID);
  if (NavigationInfo.GetRecordResult = grrOk) then
  begin
    if (not LTableData.FieldManager.FieldDefs.VarcharOrBLOBFieldsExists) then
    begin
      // disk record buffer is equal to memory record buffer - load it directly
      try
        LoadDiskRecord(NavigationInfo.SessionID, NavigationInfo.RecordID,
          NavigationInfo.RecordBuffer);
      except
        raise EACRException.Create(10518, ErrorLLoadingRecord,
          [LTableData.TableName, NavigationInfo.SessionID,
          NavigationInfo.RecordID.PageNo, NavigationInfo.RecordID.PageItemNo])
      end;
    end
    else
      try
        LoadDiskRecord(NavigationInfo.SessionID, NavigationInfo.RecordID,
          FDiskRecordBuffer);
        CopyDataFromDiskRecordBufferToMemoryRecordBuffer
          (NavigationInfo.SessionID, NavigationInfo.RecordBuffer);
      except
        raise EACRException.Create(10519, ErrorLLoadingRecord,
          [LTableData.TableName, NavigationInfo.SessionID,
          NavigationInfo.RecordID.PageNo, NavigationInfo.RecordID.PageItemNo])
      end;
  end; // record retrieved successfully
{$IFDEF DEBUG_DECRYPTION_TIME}
  aaStopTime(time4);
{$ENDIF}
{$IFDEF DEBUG_SQL_TIME}
  aaStopTime(time7);
{$ENDIF}
{$IFDEF DEBUG_LOCATE_TIME}
  aaStopTime(time24);
{$ENDIF}
end; // GetRecordBuffer

//------------------------------------------------------------------------------
// return approximate record no
//------------------------------------------------------------------------------
function TACRDiskRecordManager.GetApproximateRecNo(RecordID: TACRRecordID;
  SessionID: TACRSessionID): TACRRecordNo;
begin
  Result := FTablePageMapsManager.GetRecNoByRecordID(SessionID, RecordID) + 1;
end; // GetApproximateRecNo

//------------------------------------------------------------------------------
// return exact RecNo
//------------------------------------------------------------------------------
function TACRDiskRecordManager.GetRecNoByRecordID(RecordID: TACRRecordID;
  SessionID: TACRSessionID): TACRRecordNo;
var
  RowPage: TACRPage;
  k: Integer;
{$I ACR_check_null_flag_var.inc}
begin
  Result := FTablePageMapsManager.GetRecNoByRecordID(SessionID, RecordID);
  if (Result > -1) and (FLargeRows) then
    Inc(Result)
  else if (Result > -1) and (not FLargeRows) then
  begin
    RowPage := LTableData.GetPage(SessionID, RecordID.PageNo, dbstRow,
      LTableData.TableState.TableState, True, False, False);
    try
      k := 0;
      CHECK_NULL_FLAG_NullFlags := RowPage.PageData;
      for CHECK_NULL_FLAG_BitNo := 0 to FRecordsPerPage - 1 do
      begin
{$I ACR_check_null_flag.inc}
        if (not CHECK_NULL_FLAG_Result) then
        begin
          Inc(k);
          if (CHECK_NULL_FLAG_BitNo >= RecordID.PageItemNo) then
            break;
        end;
      end;
      Inc(Result, k);
    finally
      LTableData.PutPage(RowPage);
    end;
  end;
end; // GetRecNoByRecordID

//------------------------------------------------------------------------------
// return record ID
//------------------------------------------------------------------------------
function TACRDiskRecordManager.GetRecordIDByRecNo(RecNo: TACRRecordNo;
  SessionID: TACRSessionID): TACRRecordID;
var
  ItemNo: TACRPageItemID;
  RowPage: TACRPage;
  k: Integer;
{$I ACR_check_null_flag_var.inc}
begin
  Result := FTablePageMapsManager.GetRecordIDByRecNo(SessionID, RecNo - 1);
  if (Result.PageNo <> INVALID_PAGE_NO) and (not FLargeRows) then
  begin
    ItemNo := Result.PageItemNo;
    RowPage := LTableData.GetPage(SessionID, Result.PageNo, dbstRow,
      LTableData.TableState.TableState, True, False, False);
    try
      Result.PageItemNo := INVALID_PAGE_RECORD_NO;
      k := 0;
      CHECK_NULL_FLAG_NullFlags := RowPage.PageData;
      for CHECK_NULL_FLAG_BitNo := 0 to FRecordsPerPage - 1 do
      begin
{$I ACR_check_null_flag.inc}
        if (not CHECK_NULL_FLAG_Result) then
        begin
          Inc(k);
          if (k > ItemNo) then
          begin
            Result.PageItemNo := TACRPageItemID(CHECK_NULL_FLAG_BitNo);
            break;
          end;
        end;
      end;
      if (Result.PageItemNo = INVALID_PAGE_RECORD_NO) then
        Result.PageNo := INVALID_PAGE_NO;
    finally
      LTableData.PutPage(RowPage);
    end;
  end;
end; // GetRecordIDByRecNo

//------------------------------------------------------------------------------
// load table pfs map from stream
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.LoadTablePFSMapFromStream(Stream: TACRStream);
begin
  FTablePageMapsManager.LoadFileFromStream(Stream);
end; // LoadTablePFSMapFromStream

//------------------------------------------------------------------------------
// save table pfs map to stream
//------------------------------------------------------------------------------
procedure TACRDiskRecordManager.SaveTablePFSMapToStream(Stream: TACRStream);
begin
  FTablePageMapsManager.SaveFileToStream(Stream);
end; // SaveTablePFSMapToStream

///////////////////////////////////////////////////////////////////////////////
//
// TACRDiskTableData
//
///////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// get table id
//------------------------------------------------------------------------------
function TACRDiskTableData.GetTableID: TACRObjectID;
begin
  Result := FTableItem.TableID;
end; // GetTableID

//------------------------------------------------------------------------------
// GetPageManager
//------------------------------------------------------------------------------
function TACRDiskTableData.GetPageManager: TACRPageManager;
begin
  Result := LPageManager;
end; // GetPageManager

//------------------------------------------------------------------------------
// load table state
//------------------------------------------------------------------------------
function TACRDiskTableData.LoadTableState: TACRTableState;
begin
  Result := LDiskDatabaseData.LoadTableState(FTableItem);
end; // LoadTableState

//------------------------------------------------------------------------------
// save table state
//------------------------------------------------------------------------------
procedure TACRDiskTableData.SaveTableState;
begin
  LDiskDatabaseData.SaveTableState(FTableItem, FTableState);
end; // SaveTableState

//------------------------------------------------------------------------------
// create RecordManager
//------------------------------------------------------------------------------
procedure TACRDiskTableData.CreateRecordManager;
begin
  if (FRecordManager <> nil) then
    FRecordManager.Free;
  FRecordManager := TACRDiskRecordManager.Create(GetRecordBufferSize,
    GetRecordSize, Self);
end; // CreateRecordManager

//------------------------------------------------------------------------------
// create table files;
//------------------------------------------------------------------------------
procedure TACRDiskTableData.CreateTableFiles;
begin
{$IFDEF TACRDiskTableData_CreateTable}
  aaWriteToLog('> TACRDiskTableData.CreateTableFiles');
{$ENDIF}
  FTableMetaDataFile := TACRInternalDBFile.Create(LPageManager,
    ACRPageTypeIDTableMetaData, TACRObjectID(FTableItem.TableID), False, False,
    FCache);
  // FTableItem.TableID,False,True,FCache);
{$IFDEF TACRDiskTableData_CreateTable}
  aaWriteToLog('1. TACRDiskTableData.CreateTableFiles');
{$ENDIF}
  FTableMostUpdatedFile := TACRInternalDBFile.Create(LPageManager,
    ACRPageTypeIDTableMostUpdatedData, TACRObjectID(FTableItem.TableID), False,
    False, FCache);
  // FTableItem.TableID,False,True,FCache);
{$IFDEF TACRDiskTableData_CreateTable}
  aaWriteToLog('< TACRDiskTableData.CreateTableFiles');
{$ENDIF}
end; // CreateTableFiles

//------------------------------------------------------------------------------
// delete table files
//------------------------------------------------------------------------------
procedure TACRDiskTableData.DeleteTableFiles;
begin
  if (FTableMetaDataFile <> nil) then
    FreeAndNil(FTableMetaDataFile);
  if (FTableMostUpdatedFile <> nil) then
    FreeAndNil(FTableMostUpdatedFile);
  if (FTableLockFile <> nil) then
    FreeAndNil(FTableLockFile);
end; // DeleteTableFiles

//------------------------------------------------------------------------------
// ReadTableMetadata
//------------------------------------------------------------------------------
procedure TACRDiskTableData.ReadTableMetadata(SessionID: TACRSessionID);
var
  i: Integer;
begin
  // rewritten in v.5
{$IFDEF DEBUG_TRACE_TACRDiskTableData_ReadTableMetadata}
  aaWriteToLog('> TACRDiskTableData.ReadTableMetadata' + #13#10 +
      'SessionID = ' + IntToStr(SessionID)
      + #13#10 + 'MetadataPageNo = ' + IntToStr
      (FTableItem.TableMetaDataFilePageNo));
{$ENDIF}
  FTableMetaDataFile.ReadFile(SessionID, dbstTableMetaData,
    FTableState.TableMetaDataState);
{$IFDEF DEBUG_TRACE_TACRDiskTableData_ReadTableMetadata}
  aaWriteToLog('1. TACRDiskTableData.ReadTableMetadata' + #13#10 +
      'SessionID = ' + IntToStr(SessionID) + #13#10 + 'MetadataPageNo = ' +
      IntToStr(FTableItem.TableMetaDataFilePageNo)
      + #13#10 + 'ms.Size = ' + IntToStr(ms.Size)
      + #13#10 + 'ms.Position = ' + IntToStr(ms.Position));
{$ENDIF}
  FFieldManager.EngineVersion := TACRDiskPageManager(FDatabaseData.PageManager)
    .DBHeader.Version;
  FFieldManager.LoadFromStream(FTableMetaDataFile.DataStream);
  FFieldManager.FieldDefs.RecalcFieldOffsets;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_ReadTableMetadata}
  aaWriteToLog('2.1 TACRDiskTableData.ReadTableMetadata' + #13#10 +
      'SessionID = ' + IntToStr(SessionID) + #13#10 + 'MetadataPageNo = ' +
      IntToStr(FTableItem.TableMetaDataFilePageNo)
      + #13#10 + 'FieldDefs.Count = ' + IntToStr(FFieldManager.FieldDefs.Count)
    );
{$ENDIF}
  FIndexManager.LoadFromStream(FTableMetaDataFile.DataStream);
{$IFDEF DEBUG_TRACE_TACRDiskTableData_ReadTableMetadata}
  aaWriteToLog('2. TACRDiskTableData.ReadTableMetadata' + #13#10 +
      'SessionID = ' + IntToStr(SessionID) + #13#10 + 'MetadataPageNo = ' +
      IntToStr(FTableItem.TableMetaDataFilePageNo)
      + #13#10 + 'FieldDefs.Count = ' + IntToStr(FFieldManager.FieldDefs.Count)
    );
{$ENDIF}
  FConstraintManager.LoadFromStream(FTableMetaDataFile.DataStream);
{$IFDEF DEBUG_TRACE_TACRDiskTableData_ReadTableMetadata}
  aaWriteToLog('3. TACRDiskTableData.ReadTableMetadata' + #13#10 +
      'SessionID = ' + IntToStr(SessionID) + #13#10 + 'MetadataPageNo = ' +
      IntToStr(FTableItem.TableMetaDataFilePageNo)
      + #13#10 + 'FieldDefs.Count = ' + IntToStr(FFieldManager.FieldDefs.Count)
    );
{$ENDIF}
  FBLOBFieldsPresent := False;
  for i := 0 to FFieldManager.FieldDefs.Count - 1 do
    if (IsBLOBFieldType(FFieldManager.FieldDefs[i].BaseFieldType)) then
    begin
      FBLOBFieldsPresent := True;
      break;
    end;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_ReadTableMetadata}
  aaWriteToLog('< TACRDiskTableData.ReadTableMetadata' + #13#10 +
      'SessionID = ' + IntToStr(SessionID)
      + #13#10 + 'MetadataPageNo = ' + IntToStr
      (FTableItem.TableMetaDataFilePageNo));
{$ENDIF}
end; // ReadTableMetadata

//------------------------------------------------------------------------------
// WriteTableMetadata
//------------------------------------------------------------------------------
procedure TACRDiskTableData.WriteTableMetadata(SessionID: TACRSessionID);
begin
  // rewritten in v.5
  FTableMetaDataFile.DataStream.Reset;
  FFieldManager.EngineVersion := TACRDiskPageManager(FDatabaseData.PageManager)
    .DBHeader.Version;
  FFieldManager.SaveToStream(FTableMetaDataFile.DataStream);
  FIndexManager.SaveToStream(FTableMetaDataFile.DataStream);
  FConstraintManager.SaveToStream(FTableMetaDataFile.DataStream);
  FTableMetaDataFile.WriteFile(SessionID, dbstTableMetaData,
    FTableState.TableState);
end; // WriteTableMetadata

//------------------------------------------------------------------------------
// Read data from TableMostUpdatedFile
//------------------------------------------------------------------------------
procedure TACRDiskTableData.ReadMostUpdatedData(SessionID: TACRSessionID);
var
  DataSize: Integer;
begin
{$IFDEF DEBUG_TRACE_TACRDiskTableData_ReadMostUpdatedData}
  aaWriteToLog('> TACRDiskTableData.ReadMostUpdatedData, FTableName = ' +
      FTableName + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,
      True) + #13#10 + 'Self =' + IntToHex(Integer(Self),
      8) + #13#10 + 'SessionID = ' + IntToStr(SessionID) + #13#10 +
      'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
      + #13#10 + 'FTransactionMUD = ' + BoolToStr(FTransactionMUD,
      True) + #13#10 + 'FMUDLoaded = ' + BoolToStr(FMUDLoaded,
      True) + #13#10 + 'FTableState.TableState = ' + IntToStr
      (FTableState.TableState) + #13#10 + 'FMUDState = ' + IntToStr(FMUDState)
    );
{$ENDIF}
  // rewritten in v.5
  FTableMostUpdatedFile.ReadFile(SessionID, dbstTableMostUpdatedData,
    FTableState.TableState);
  LoadSequencesFromStream(FTableMostUpdatedFile.DataStream);
  // added in v.5 - PFS and MUD are now in MUD file both as it usually fits in 1 page
  TACRDiskRecordManager(FRecordManager).LoadTablePFSMapFromStream
    (FTableMostUpdatedFile.DataStream);
  FMUDState := FTableState.TableState;
  FMUDLoaded := True;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_ReadMostUpdatedData}
  aaWriteToLog('< TACRDiskTableData.ReadMostUpdatedData, FTableName = ' +
      FTableName + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,
      True) + #13#10 + 'Self =' + IntToHex(Integer(Self),
      8) + #13#10 + 'SessionID = ' + IntToStr(SessionID) + #13#10 +
      'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
      + #13#10 + 'FTransactionMUD = ' + BoolToStr(FTransactionMUD,
      True) + #13#10 + 'FMUDLoaded = ' + BoolToStr(FMUDLoaded,
      True) + #13#10 + 'FTableState.TableState = ' + IntToStr
      (FTableState.TableState) + #13#10 + 'FMUDState = ' + IntToStr(FMUDState)
    );
{$ENDIF}
end; // ReadMostUpdatedData

//------------------------------------------------------------------------------
// write data into TableMostUpdatedFile
//------------------------------------------------------------------------------
procedure TACRDiskTableData.WriteMostUpdatedData(SessionID: TACRSessionID);
var
  DataSize: Integer;
begin
{$IFDEF DEBUG_TRACE_TACRDiskTableData_WriteMostUpdatedData}
  aaWriteToLog('> TACRDiskTableData.WriteMostUpdatedData, FTableName = ' +
      FTableName + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,
      True) + #13#10 + 'Self =' + IntToHex(Integer(Self),
      8) + #13#10 + 'SessionID = ' + IntToStr(SessionID) + #13#10 +
      'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
      + #13#10 + 'FTransactionMUD = ' + BoolToStr(FTransactionMUD,
      True) + #13#10 + 'FMUDLoaded = ' + BoolToStr(FMUDLoaded,
      True) + #13#10 + 'FTableState.TableState = ' + IntToStr
      (FTableState.TableState) + #13#10 + 'FMUDState = ' + IntToStr(FMUDState)
    );
{$ENDIF}
{$IFDEF DEBUG_LOCK_TIMES}
  aaIncCounter(counter2);
  aaStartTime(time2);
{$ENDIF}
  // rewritten in v.5
  FTableMostUpdatedFile.DataStream.Reset;
  SaveSequencesToStream(FTableMostUpdatedFile.DataStream);
  // added in v.5 - PFS and MUD are now in MUD file both as it usually fits in 1 page
  TACRDiskRecordManager(FRecordManager).SaveTablePFSMapToStream
    (FTableMostUpdatedFile.DataStream);
  FTableMostUpdatedFile.WriteFile(SessionID, dbstTableMostUpdatedData,
    FTableState.TableState);
{$IFDEF DEBUG_LOCK_TIMES}
  aaStopTime(time2);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRDiskTableData_WriteMostUpdatedData}
  aaWriteToLog('< TACRDiskTableData.WriteMostUpdatedData, FTableName = ' +
      FTableName + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,
      True) + #13#10 + 'Self =' + IntToHex(Integer(Self),
      8) + #13#10 + 'SessionID = ' + IntToStr(SessionID) + #13#10 +
      'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
      + #13#10 + 'FTransactionMUD = ' + BoolToStr(FTransactionMUD,
      True) + #13#10 + 'FMUDLoaded = ' + BoolToStr(FMUDLoaded,
      True) + #13#10 + 'FTableState.TableState = ' + IntToStr
      (FTableState.TableState) + #13#10 + 'FMUDState = ' + IntToStr(FMUDState)
    );
{$ENDIF}
end; // WriteMostUpdatedData

//------------------------------------------------------------------------------
// recreates table with new structure if table already exists
//------------------------------------------------------------------------------
procedure TACRDiskTableData.InternalRecreateTable(Cursor: TACRCursor;
  FieldDefs: TACRFieldDefs; IndexDefs: TACRIndexDefs;
  ConstraintDefs: TACRConstraintDefs);
var
  SessionID: TACRSessionID;
begin
  FExclusive := True;
  SessionID := Cursor.Session.SessionID;
  InternalOpenTable(SessionID);
  try
    // Free all pages used by table rows, PFS, index, BLOBs, varchars
    inherited DeleteTable(Cursor.Session, True, False);
    if (FIndexManager.IndexDefs.Count > 0) then
      FIndexManager.EmptyAllIndexes(SessionID);
    FRecordManager.Empty(SessionID);
    // init objects
    CreateSequenceManager;
    CreateFieldManager(FieldDefs);
    CreateIndexManager(IndexDefs);
    CreateConstraintManager(ConstraintDefs);
    BuildSequences;
    CreateRecordManager;
    InitCursor(Cursor);
    if (FConstraintManager.ConstraintDefs.ForeignKeysExists) then
      CheckForeignKeyDefinitionsAndCreateForeignKeyActions(Cursor);
    // write data into TableMetadataFile
    WriteTableMetadata(SessionID);
    WriteMostUpdatedData(SessionID);
    FTableState.TableState := GenerateTableState;
    FTableState.TableMetaDataState := GenerateTableMetadataState;
    FTableState.TableFailureFlags := 0;
    FTableState.LastTableOperation := ltoCreateTable;
    // Flush changes
    ApplyChanges(FTableState.TableState, dbstTableMetaData,
      FTableState.TableMetaDataState);
    FTableState.LastModificationDate := Now;
    LDiskDatabaseData.SaveTableState(FTableItem, FTableState);
    // LPageManager.FlushFileBuffers;
  finally
    InternalCloseTable(SessionID);
  end;
end; // InternalRecreateTable

//------------------------------------------------------------------------------
// create foreign key action (table is opened exclusively)
//------------------------------------------------------------------------------
function TACRDiskTableData.CreateForeignKeyAction(Cursor: TACRCursor;
  ConstraintDef: TACRConstraintDefForeignKey; ReferencedTableName: WideString;
  ReferencedTableObjectID: TACRObjectID): TACRConstraintDefForeignKeyAction;
begin
  if ((not FIsTableOpened) or (not FExclusive)) then
    raise EACRException.Create(11874, ErrorLTableIsOpenedInExclusiveMode,
      [FTableName]);
  try
    Result := inherited CreateForeignKeyAction(Cursor, ConstraintDef,
      ReferencedTableName, ReferencedTableObjectID);
    WriteTableMetadata(Cursor.Session.SessionID);
    ApplyChanges(FTableState.TableState, dbstTableMetaData,
      FTableState.TableMetaDataState);
    SaveTableState;
  except
    FCache.CancelChanges;
    FTableState := LoadTableState;
    raise ;
  end;
end; // CreateForeignKeyAction

//------------------------------------------------------------------------------
// free if no sessions connected
//------------------------------------------------------------------------------
procedure TACRDiskTableData.FreeIfNoSessionsConnected;
begin
  if (not FIsTableOpened) then
    if (FTransactionCount <= 0) then
      Free;
end; // FreeIfNoSessionsConnected

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRDiskTableData.Create(aDiskDatabaseData: TACRDiskDatabaseData);
begin
  inherited Create(aDiskDatabaseData);
  FSequenceManager := nil;
  FRandomSearchRetryCount := aDiskDatabaseData.Options.RandomSearchRetryCount;
  FExclusive := False;
  LDiskDatabaseData := aDiskDatabaseData;
  LPageManager := TACRDiskPageManager(aDiskDatabaseData.FPageManager);
  FTableMetaDataFile := nil;
  FTableMostUpdatedFile := nil;
  FTableLockFile := nil;
  FInMemory := False;
  FTemporary := False;
  FTransactionSessionID := INVALID_SESSION_ID;
{$IFDEF FILE_SERVER_VERSION}
  if (LPageManager.DBHeader.MaxSessionCount > 0) then
    FLockManager := TACRTableLockManager.Create(Self,
      (not LPageManager.Exclusive));
{$ENDIF}
  if (FLockManager = nil) then
    FLockManager := TACRTableLockManager.Create(Self, False);
end; // Create;

//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TACRDiskTableData.Destroy;
begin
  if (FSequenceManager <> nil) then
  begin
    FSequenceManager.Free;
    FSequenceManager := nil;
  end;
  DeleteTableFiles;
  inherited Destroy;
end; // Destroy

//------------------------------------------------------------------------------
// return size of the record on disk
//------------------------------------------------------------------------------
function TACRDiskTableData.GetRecordSize: Integer;
begin
  if (FFieldManager.FieldDefs.Count <= 0) then
    raise EACRException.Create(10515, ErrorLNoFields);
  Result := FFieldManager.FieldDefs[FFieldManager.FieldDefs.Count - 1]
    .DiskOffset + FFieldManager.FieldDefs[FFieldManager.FieldDefs.Count - 1]
    .DiskDataSize;
end; // GetRecordSize

//------------------------------------------------------------------------------
// create table
//------------------------------------------------------------------------------
procedure TACRDiskTableData.CreateTable(Cursor: TACRCursor;
  FieldDefs: TACRFieldDefs; IndexDefs: TACRIndexDefs;
  ConstraintDefs: TACRConstraintDefs);
var
  TableExists: Boolean;
  SessionID: TACRSessionID;
  ItemIndex: Integer;
begin
{$IFDEF TACRDiskTableData_CreateTable}
  aaWriteToLog('> TACRDiskTableData.CreateTable. SessionID = ' + IntToStr
      (SessionID) + #13#10 + 'TableName = ' + Cursor.TableName);
  try
{$ENDIF}
    TableExists := False;
    SessionID := Cursor.Session.SessionID;
    FExclusive := True;
    Lock(True);
    try
      if (FieldDefs.Count <= 0) then
        raise EACRException.Create(10025, ErrorLNoFields);
      CheckFieldDefinitions(FieldDefs);
      CheckIndexDefinitions(IndexDefs);
      CheckConstraintDefinitions(ConstraintDefs);
      if (FIsTableOpened) then
        raise EACRException.Create(10779, ErrorLTableIsInUse, [FTableName]);
      if (not LDiskDatabaseData.InternalLockTableList(True)) then
        raise EACRException.Create(10616, ErrorLCannotLockTables,
          [LDiskDatabaseData.DatabaseName]);
      try
        LDiskDatabaseData.FTableListFile.Load;
        TableExists := LDiskDatabaseData.GetTableItemIfExists(FTableNameCRC,
          FTableName, FTableItem, ItemIndex);
      finally
        // we must close it as if the table does not exist
        // if it will check foreign keys it must be able to open other tables
        if (not LDiskDatabaseData.InternalUnlockTableList) then
          raise EACRException.Create(10617, ErrorLCannotUnlockTables,
            [LDiskDatabaseData.DatabaseName]);
      end; // unlock table list
{$IFDEF TACRDiskTableData_CreateTable}
      aaWriteToLog('1. TACRDiskTableData.CreateTable. SessionID = ' + IntToStr
          (SessionID) + #13#10 + 'TableName = ' + FTableName + #13#10 +
          'TableNameCRC = ' + IntToHex(FTableNameCRC,
          8) + #13#10 + 'TableExists = ' + BoolToStr(TableExists, True));
{$ENDIF}
      // try to perform all operations - cancel if failed
      try
        if (TableExists) then
        begin
          // the table item remains the same so we do not need to update table list
          InternalRecreateTable(Cursor, FieldDefs, IndexDefs, ConstraintDefs);
          if (not LDiskDatabaseData.InternalLockTableList(True)) then
            raise EACRException.Create(12385, ErrorLCannotLockTables,
              [LDiskDatabaseData.DatabaseName]);
          // try to perform all operations - cancel if failed
          try
            LDiskDatabaseData.FTableListFile.Load;
            FTableItem.CreationDate := Now;
            LDiskDatabaseData.UpdateTableItem(ItemIndex, FTableItem, FComment);
            LDiskDatabaseData.FTableListFile.Save;
          finally
            // we must close it as if the table does not exist
            // if it will check foreign keys it must be able to open other tables
            if (not LDiskDatabaseData.InternalUnlockTableList) then
              raise EACRException.Create(12386, ErrorLCannotUnlockTables,
                [LDiskDatabaseData.DatabaseName]);
          end; // unlock table list
        end // table already exists - recreate it
        else
        begin
          FTableState.TableState := GenerateTableState;
          FTableState.TableMetaDataState := GenerateTableMetadataState;
          FTableState.TableFailureFlags := 0;
          FTableState.LastTableOperation := ltoCreateTable;
          // table does not exist
          // InternalDeleteTable(Cursor.Session,True,True);
{$IFDEF TACRDiskTableData_CreateTable}
          aaWriteToLog('2. TACRDiskTableData.CreateTable. SessionID = ' +
              IntToStr(SessionID) + #13#10 + 'TableName = ' + Cursor.TableName);
{$ENDIF}
          // setup new table item
          FTableName := Cursor.FTableName;
          FComment := Cursor.FComment;
          FTableItem.TableNameCRC := GetTableNameCRC(FTableName);
          // table level encryption is not supported
          // FTableItem.CryptoHeader.CryptoAlgorithm := ACR_Cipher_None;
          FTableItem.TableID := LDiskDatabaseData.FTableListFile.GetNewTableID;
{$IFDEF TACRDiskTableData_CreateTable}
          aaWriteToLog('2.1 TACRDiskTableData.CreateTable. SessionID = ' +
              IntToStr(SessionID) + #13#10 + 'TableName = ' +
              Cursor.TableName + #13#10 + 'TableID = ' + IntToStr
              (FTableItem.TableID));
{$ENDIF}
          FCache.TableID := FTableItem.TableID;
{$IFDEF TACRDiskTableData_CreateTable}
          aaWriteToLog('2.2. TACRDiskTableData.CreateTable. SessionID = ' +
              IntToStr(SessionID) + #13#10 + 'TableName = ' +
              Cursor.TableName + #13#10 + 'TableID = ' + IntToStr
              (FTableItem.TableID) + #13#10 + 'FCache.TableID = ' + IntToStr
              (FCache.TableID));
{$ENDIF}
          DeleteTableFiles;
{$IFDEF TACRDiskTableData_CreateTable}
          aaWriteToLog('2.3. TACRDiskTableData.CreateTable. SessionID = ' +
              IntToStr(SessionID) + #13#10 + 'TableName = ' +
              Cursor.TableName + #13#10 + 'TableID = ' + IntToStr
              (FTableItem.TableID) + #13#10 + 'FCache.TableID = ' + IntToStr
              (FCache.TableID));
{$ENDIF}
          CreateTableFiles;
{$IFDEF TACRDiskTableData_CreateTable}
          aaWriteToLog('2.4. TACRDiskTableData.CreateTable. SessionID = ' +
              IntToStr(SessionID) + #13#10 + 'TableName = ' +
              Cursor.TableName + #13#10 + 'TableID = ' + IntToStr
              (FTableItem.TableID) + #13#10 + 'FCache.TableID = ' + IntToStr
              (FCache.TableID));
{$ENDIF}
          FTableLockFile := TACRTableLockFile.Create(LPageManager, FCache,
            FTableItem.TableID, FLockManager.MaxWaitLockTime);
{$IFDEF TACRDiskTableData_CreateTable}
          aaWriteToLog('2.5. TACRDiskTableData.CreateTable. SessionID = ' +
              IntToStr(SessionID) + #13#10 + 'TableName = ' +
              Cursor.TableName + #13#10 + 'TableID = ' + IntToStr
              (FTableItem.TableID) + #13#10 + 'FCache.TableID = ' + IntToStr
              (FCache.TableID));
{$ENDIF}
          // init objects
          CreateSequenceManager;
          CreateFieldManager(FieldDefs);
          CreateIndexManager(IndexDefs);
          CreateConstraintManager(ConstraintDefs);
          BuildSequences;
          CreateRecordManager;
          try
            InitCursor(Cursor);
{$IFDEF TACRDiskTableData_CreateTable}
            aaWriteToLog('2.6. TACRDiskTableData.CreateTable. SessionID = ' +
                IntToStr(SessionID)
                + #13#10 + 'TableName = ' + Cursor.TableName +
                #13#10 + 'TableID = ' + IntToStr(FTableItem.TableID)
                + #13#10 + 'FCache.TableID = ' + IntToStr(FCache.TableID));
{$ENDIF}
            if (FConstraintManager.ConstraintDefs.ForeignKeysExists) then
              CheckForeignKeyDefinitionsAndCreateForeignKeyActions(Cursor);
{$IFDEF TACRDiskTableData_CreateTable}
            aaWriteToLog('2.7. TACRDiskTableData.CreateTable. SessionID = ' +
                IntToStr(SessionID)
                + #13#10 + 'TableName = ' + Cursor.TableName +
                #13#10 + 'TableID = ' + IntToStr(FTableItem.TableID)
                + #13#10 + 'FCache.TableID = ' + IntToStr(FCache.TableID));
{$ENDIF}
            FIndexManager.CreateAllIndexes(SessionID);
            // create table files
            // create table metadata file
            FTableMetaDataFile.CreateFile(0, SessionID, dbstTableMetaData,
              FTableState.TableMetaDataState);
            FTableItem.MetaDataFilePageNo := FTableMetaDataFile.StartPageNo;
            // create table most updated data file
            FTableMostUpdatedFile.CreateFile(0, SessionID,
              dbstTableMostUpdatedData, FTableState.TableState);
            FTableItem.MostUpdatedDataFilePageNo :=
              FTableMostUpdatedFile.StartPageNo;
            // create LockFile
            FTableItem.LockFilePageNo := FTableLockFile.CreateFile(SessionID,
              FTableState.TableState);
            FTableItem.CreationDate := Now;
{$IFDEF TACRDiskTableData_CreateTable}
            aaWriteToLog('2.8. TACRDiskTableData.CreateTable. SessionID = ' +
                IntToStr(SessionID)
                + #13#10 + 'TableName = ' + Cursor.TableName +
                #13#10 + 'TableID = ' + IntToStr(FTableItem.TableID)
                + #13#10 + 'FCache.TableID = ' + IntToStr(FCache.TableID));
{$ENDIF}
            // write data into TableMetadataFile
            WriteTableMetadata(SessionID);
{$IFDEF TACRDiskTableData_CreateTable}
            aaWriteToLog('2.9. TACRDiskTableData.CreateTable. SessionID = ' +
                IntToStr(SessionID)
                + #13#10 + 'TableName = ' + Cursor.TableName +
                #13#10 + 'TableID = ' + IntToStr(FTableItem.TableID)
                + #13#10 + 'FCache.TableID = ' + IntToStr(FCache.TableID));
{$ENDIF}
            // write data into TableMostUpdatedFile
            WriteMostUpdatedData(SessionID);
          finally
            FreeAndNil(FRecordManager);
            FreeAndNil(FFieldManager);
            FreeAndNil(FSequenceManager);
            FreeAndNil(FIndexManager);
            FreeAndNil(FConstraintManager);
            DeleteTableFiles;
          end;
{$IFDEF TACRDiskTableData_CreateTable}
          aaWriteToLog('3. TACRDiskTableData.CreateTable. SessionID = ' +
              IntToStr(SessionID) + #13#10 + 'TableName = ' +
              Cursor.TableName + #13#10 + 'TableID = ' + IntToStr
              (FTableItem.TableID) + #13#10 + 'FCache.TableID = ' + IntToStr
              (FCache.TableID));
{$ENDIF}
          // Flush changes
          ApplyChanges(FTableState.TableState, dbstTableMetaData,
            FTableState.TableMetaDataState);
          // create new record in table list
{$IFDEF TACRDiskTableData_CreateTable}
          aaWriteToLog('4. TACRDiskTableData.CreateTable. SessionID = ' +
              IntToStr(SessionID) + #13#10 + 'TableName = ' +
              Cursor.TableName + #13#10 + 'TableNameCRC = ' + IntToStr
              (FTableItem.TableNameCRC) + #13#10 + 'TableID = ' + IntToStr
              (FTableItem.TableID));
{$ENDIF}
          FTableState.LastModificationDate := Now;
          if (not LDiskDatabaseData.InternalLockTableList(True)) then
            raise EACRException.Create(12387, ErrorLCannotLockTables,
              [LDiskDatabaseData.DatabaseName]);
          try
            LDiskDatabaseData.FTableListFile.Load;
            LDiskDatabaseData.FTableListFile.CreateTable(FTableItem,
              FTableState, FTableName, FComment);
{$IFDEF TACRDiskTableData_CreateTable}
            aaWriteToLog('4.2. TACRDiskTableData.CreateTable. SessionID = ' +
                IntToStr(SessionID)
                + #13#10 + 'TableName = ' + Cursor.TableName +
                #13#10 + 'TableNameCRC = ' + IntToStr(FTableItem.TableNameCRC)
                + #13#10 + 'TableID = ' + IntToStr(FTableItem.TableID));
{$ENDIF}
            LDiskDatabaseData.FTableListFile.Save;
{$IFDEF TACRDiskTableData_CreateTable}
            aaWriteToLog('4.3. TACRDiskTableData.CreateTable. SessionID = ' +
                IntToStr(SessionID)
                + #13#10 + 'TableName = ' + Cursor.TableName +
                #13#10 + 'TableNameCRC = ' + IntToStr(FTableItem.TableNameCRC)
                + #13#10 + 'TableID = ' + IntToStr(FTableItem.TableID));
{$ENDIF}
            LDiskDatabaseData.SaveTableState(FTableItem, FTableState);
          finally
            // we must close it as if the table does not exist
            // if it will check foreign keys it must be able to open other tables
            if (not LDiskDatabaseData.InternalUnlockTableList) then
              raise EACRException.Create(12388, ErrorLCannotUnlockTables,
                [LDiskDatabaseData.DatabaseName]);
          end; // unlock table list
{$IFDEF TACRDiskTableData_CreateTable}
          aaWriteToLog('5. TACRDiskTableData.CreateTable. SessionID = ' +
              IntToStr(SessionID) + #13#10 + 'TableName = ' +
              Cursor.TableName + #13#10 + 'TableNameCRC = ' + IntToStr
              (FTableItem.TableNameCRC) + #13#10 + 'TableID = ' + IntToStr
              (FTableItem.TableID));
{$ENDIF}
        end; // table does not exist
      except
        try
          FCache.CancelChanges;
          LDiskDatabaseData.FTableListFile.FNotLoaded := True;
        except
        end;
        raise ;
      end; // try to perform all necessary operations - cancel changes if failed
      // move table pages to parent cache - probably table will be opened soon
{$IFDEF TACRDiskTableData_CreateTable}
      aaWriteToLog('6. TACRDiskTableData.CreateTable. SessionID = ' + IntToStr
          (SessionID) + #13#10 + 'TableName = ' + Cursor.TableName + #13#10 +
          'TableNameCRC = ' + IntToStr(FTableItem.TableNameCRC)
          + #13#10 + 'TableID = ' + IntToStr(FTableItem.TableID));
{$ENDIF}
      FCache.ExportPagesToParent;
{$IFDEF TACRDiskTableData_CreateTable}
      aaWriteToLog('7. TACRDiskTableData.CreateTable. SessionID = ' + IntToStr
          (SessionID) + #13#10 + 'TableName = ' + Cursor.TableName + #13#10 +
          'TableNameCRC = ' + IntToStr(FTableItem.TableNameCRC)
          + #13#10 + 'TableID = ' + IntToStr(FTableItem.TableID));
{$ENDIF}
    finally
      Unlock;
    end;
{$IFDEF TACRDiskTableData_CreateTable}
    aaWriteToLog('< TACRDiskTableData.CreateTable. SessionID = ' + IntToStr
        (SessionID) + #13#10 + 'TableName = ' + Cursor.TableName + #13#10 +
        'TableNameCRC = ' + IntToStr(FTableItem.TableNameCRC)
        + #13#10 + 'TableID = ' + IntToStr(FTableItem.TableID));
  except
    on e: Exception do
    begin
      aaWriteToLog('Error in TACRDiskTableData.CreateTable. SessionID = ' +
          IntToStr(SessionID) + #13#10 + 'TableName = ' + Cursor.TableName +
          #13#10 + 'TableNameCRC = ' + IntToStr(FTableItem.TableNameCRC)
          + #13#10 + 'TableID = ' + IntToStr(FTableItem.TableID)
          + #13#10 + e.Message);
      raise ;
    end;
  end;
{$ENDIF}
end; // CreateTable

//------------------------------------------------------------------------------
// DeleteTable
//------------------------------------------------------------------------------
procedure TACRDiskTableData.DeleteTable(Session: TACRBaseSession;
  Cascade: Boolean; DesignMode: Boolean = False);
var
  SessionID: TACRSessionID;
begin
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
  aaWriteToLog('> TACRDiskTableData.DeleteTable, TableName = ' + FTableName);
  try
{$ENDIF}
    Lock(True);
    try
      FExclusive := True;
      SessionID := Session.SessionID;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
      aaWriteToLog('1. TACRDiskTableData.DeleteTable, TableName = ' +
          FTableName + #13#10 + 'SessionID = ' + IntToStr(SessionID)
          + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened, True));
{$ENDIF}
      if (FIsTableOpened) then
        raise EACRException.Create(10782, ErrorLTableIsInUse, [FTableName]);
      LDiskDatabaseData.InternalLockTableList(True);
      try
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
        aaWriteToLog('2. TACRDiskTableData.DeleteTable, TableName = ' +
            FTableName + #13#10 + 'SessionID = ' + IntToStr(SessionID)
            + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened,
            True));
{$ENDIF}
        try
          LDiskDatabaseData.FTableListFile.Load;
        except
          LDiskDatabaseData.FTableListFile.FNotLoaded := True;
          raise ;
        end;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
        aaWriteToLog('3. TACRDiskTableData.DeleteTable, TableName = ' +
            FTableName + #13#10 + 'SessionID = ' + IntToStr(SessionID)
            + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened,
            True));
{$ENDIF}
        if (not LDiskDatabaseData.GetTableItemIfExists(FTableNameCRC,
            FTableName, FTableItem)) then
        begin
          if (LDiskDatabaseData.FTableListFile.ViewExists(FTableName)) then
          begin
           // delete view
           LDiskDatabaseData.FTableListFile.DropView(FTableName,Cascade);
           try
            LDiskDatabaseData.FTableListFile.Save;
           except
            LDiskDatabaseData.FTableListFile.FNotLoaded := True;
            raise ;
           end;
           // all done
           Exit;
          end
          else
          raise EACRException.Create(10780, ErrorLTableDoesNotExists,
            [FTableName, LDiskDatabaseData.DatabaseName]);
        end;

        // check views
        LDiskDatabaseData.FTableListFile.DeleteViewsByTable(FTableName,Cascade);
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
        aaWriteToLog('4. TACRDiskTableData.DeleteTable, TableName = ' +
            FTableName + #13#10 + 'SessionID = ' + IntToStr(SessionID)
            + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened,
            True));
{$ENDIF}
        OpenLocksFile;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
        aaWriteToLog('5. TACRDiskTableData.DeleteTable, TableName = ' +
            FTableName + #13#10 + 'SessionID = ' + IntToStr(SessionID)
            + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened,
            True));
{$ENDIF}
        if (not TryToLockTableX(SessionID)) then
          raise EACRException.Create(11891, ErrorLTableIsNotOpenedExclusively,
            [FTableName]);
        try
          try
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
            aaWriteToLog('11. TACRDiskTableData.DeleteTable, TableName = ' +
                FTableName + #13#10 + 'SessionID = ' + IntToStr(SessionID)
                + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened,
                True));
{$ENDIF}
            LDiskDatabaseData.FTableListFile.DeleteTable(FTableNameCRC,
              FTableName);
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
            aaWriteToLog('13. TACRDiskTableData.DeleteTable, TableName = ' +
                FTableName + #13#10 + 'SessionID = ' + IntToStr(SessionID)
                + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened,
                True));
{$ENDIF}
            LDiskDatabaseData.FTableListFile.Save;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
            aaWriteToLog('14. TACRDiskTableData.DeleteTable, TableName = ' +
                FTableName + #13#10 + 'SessionID = ' + IntToStr(SessionID)
                + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened,
                True));
{$ENDIF}
          except
            LDiskDatabaseData.FTableListFile.FNotLoaded := True;
            raise ;
          end;
        finally
          TryToUnlockTableX(SessionID);
        end;
      finally
        if (not LDiskDatabaseData.InternalUnlockTableList) then
          raise EACRException.Create(12171, ErrorLCannotUnlockTables,
            [LDiskDatabaseData.DatabaseName]);
      end;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
      aaWriteToLog('6. TACRDiskTableData.DeleteTable, TableName = ' +
          FTableName + #13#10 + 'SessionID = ' + IntToStr(SessionID)
          + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened, True));
{$ENDIF}
      InternalOpenTable(SessionID);
      try
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
        aaWriteToLog('7. TACRDiskTableData.DeleteTable, TableName = ' +
            FTableName + #13#10 + 'SessionID = ' + IntToStr(SessionID)
            + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened,
            True));
{$ENDIF}
        try
          inherited DeleteTable(Session, Cascade, False);
        except
          // undo delete table
          try
            LDiskDatabaseData.InternalLockTableList(True);
            try
              LDiskDatabaseData.FTableListFile.Load;
              LDiskDatabaseData.FTableListFile.CreateTable(FTableItem,
                FTableState, FTableName, FComment);
            finally
              LDiskDatabaseData.InternalUnlockTableList;
            end;
          except
          end;
          raise ;
        end;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
        aaWriteToLog('8. TACRDiskTableData.DeleteTable, TableName = ' +
            FTableName + #13#10 + 'SessionID = ' + IntToStr(SessionID)
            + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened,
            True));
{$ENDIF}
        // Free all pages used by table rows, PFS, index, BLOBs, varchars
        if (FIndexManager.IndexDefs.Count > 0) then
          try
            FIndexManager.DropAllIndexes(SessionID);
          except
          end;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
        aaWriteToLog('9. TACRDiskTableData.DeleteTable, TableName = ' +
            FTableName + #13#10 + 'SessionID = ' + IntToStr(SessionID)
            + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened,
            True));
{$ENDIF}
        try
          FRecordManager.Empty(SessionID);
        except
        end;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
        aaWriteToLog('10. TACRDiskTableData.DeleteTable, TableName = ' +
            FTableName + #13#10 + 'SessionID = ' + IntToStr(SessionID)
            + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened,
            True));
{$ENDIF}
      finally
        InternalCloseTable(SessionID);
      end;
      try
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
        aaWriteToLog('15. TACRDiskTableData.DeleteTable, TableName = ' +
            FTableName + #13#10 + 'SessionID = ' + IntToStr(SessionID)
            + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened,
            True));
{$ENDIF}
        // Delete table files
        FTableMetaDataFile.DeleteFile(SessionID, dbstTableMetaData,
          FTableState.TableMetaDataState);
        FTableMostUpdatedFile.DeleteFile(SessionID, dbstTableMostUpdatedData,
          FTableState.TableState);
        if (FTableLockFile <> nil) then
          FreeAndNil(FTableLockFile);
        FTableLockFile := TACRTableLockFile.Create(LPageManager, FCache,
          FTableItem.TableID, FLockManager.MaxWaitLockTime);
        FTableLockFile.DeleteFile(FTableItem.LockFilePageNo, SessionID,
          FTableState.TableState);
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
        aaWriteToLog('16. TACRDiskTableData.DeleteTable, TableName = ' +
            FTableName + #13#10 + 'SessionID = ' + IntToStr(SessionID)
            + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened,
            True));
{$ENDIF}
        ApplyChanges(FTableState.TableState);
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
        aaWriteToLog('17. TACRDiskTableData.DeleteTable, TableName = ' +
            FTableName + #13#10 + 'SessionID = ' + IntToStr(SessionID)
            + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened,
            True));
{$ENDIF}
        FCache.ClearSharedCache;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
        aaWriteToLog('18. TACRDiskTableData.DeleteTable, TableName = ' +
            FTableName + #13#10 + 'SessionID = ' + IntToStr(SessionID)
            + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened,
            True));
{$ENDIF}
      except
        try
          FCache.CancelChanges;
        except
        end;
        raise ;
      end;
    finally
      Unlock;
    end;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_DeleteTable}
    aaWriteToLog('< TACRDiskTableData.DeleteTable, TableName = ' + FTableName +
        #13#10 + 'SessionID = ' + IntToStr(SessionID)
        + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened, True));
  except
    on e: Exception do
    begin
      aaWriteToLog('Error in TACRDiskTableData.DeleteTable, TableName = ' +
          FTableName + #13#10 + 'SessionID = ' + IntToStr(SessionID)
          + #13#10 + 'FIsTableOpened = ' + BoolToStr(FIsTableOpened,
          True) + #13#10 + e.Message);
      raise ;
    end;
  end;
{$ENDIF}
end; // DeleteTable

//------------------------------------------------------------------------------
// delete constraint (FK,FKAction or PK) and write changes to MetaData file
//------------------------------------------------------------------------------
procedure TACRDiskTableData.DeleteConstraint(Cursor: TACRCursor;
  Name: WideString; Cascade: Boolean; FKPartialDelete: Boolean);
begin
  Lock(True);
  try
    try
      inherited DeleteConstraint(Cursor, Name, Cascade, FKPartialDelete);
      WriteTableMetadata(Cursor.Session.SessionID);
      // WriteMostUpdatedData(Cursor.Session.SessionID);
      ApplyChanges(FTableState.TableState, dbstTableMetaData,
        FTableState.TableMetaDataState);
      SaveTableState;
    except
      FCache.CancelChanges;
      FTableState := LoadTableState;
      raise ;
    end;
  finally
    Unlock;
  end;
end; // DeleteConstraint

//------------------------------------------------------------------------------
// add foreign key
//------------------------------------------------------------------------------
procedure TACRDiskTableData.AddForeignKey(Cursor: TACRCursor;
  ConstraintDef: TACRConstraintDefForeignKey);
begin
  Lock(True);
  try
    try
      inherited;
      WriteTableMetadata(Cursor.Session.SessionID);
      // WriteMostUpdatedData(Cursor.Session.SessionID);
      ApplyChanges(FTableState.TableState, dbstTableMetaData,
        FTableState.TableMetaDataState);
      SaveTableState;
    except
      FCache.CancelChanges;
      FTableState := LoadTableState;
      raise ;
    end;
  finally
    Unlock;
  end;
end; // AddForeignKey

//------------------------------------------------------------------------------
// delete constraint (FK,FKAction or PK) and write changes to MetaData file
//------------------------------------------------------------------------------
procedure TACRDiskTableData.RenameReferenceTableName(Cursor: TACRCursor;
  OldName, NewName: WideString);
begin
  try
    inherited;
    WriteTableMetadata(Cursor.Session.SessionID);
    ApplyChanges(FTableState.TableState, dbstTableMetaData,
      FTableState.TableMetaDataState);
    SaveTableState;
  except
    FCache.CancelChanges;
    FTableState := LoadTableState;
    raise ;
  end;
end; // RenameReferenceTableName

//------------------------------------------------------------------------------
// EmptyTable
//------------------------------------------------------------------------------
procedure TACRDiskTableData.EmptyTable(Cursor: TACRCursor;
  SkipFKCheck: Boolean);
var
  FSessionID: TACRSessionID;
begin
  Lock(True);
  try
    if (FIsTableOpened) then
      raise EACRException.Create(10785, ErrorLTableIsInUse, [FTableName]);
    if (Cursor.Session.InTransaction) then
      raise EACRException.Create(10836,
        ErrorLCannotPerformThisOperationInsideATransaction);
    OpenTable(Cursor);
    try
      FSessionID := Cursor.Session.SessionID;
      if (not SkipFKCheck) then
        if (FConstraintManager.ConstraintDefs.ForeignKeysActionsDeleteExists)
          then
          raise EACRException.Create(11493,
            ErrorLCannotEmptyTableWithForeignKeyActionsDelete, [FTableName]);
      try
        EmptyAllIndexes(FSessionID);
        FRecordManager.Empty(FSessionID);
        UpdateTableState(ltoEmpty);
        WriteMostUpdatedData(FSessionID);
        ApplyChanges(FTableState.TableState);
        SaveTableState;
      except
        FCache.CancelChanges;
        FTableState := LoadTableState;
        raise ;
      end;
    finally
      CloseTable(Cursor);
    end;
  finally
    Unlock;
  end;
end; // EmptyTable

//------------------------------------------------------------------------------
// RenameTable
//------------------------------------------------------------------------------
procedure TACRDiskTableData.RenameTable(Cursor: TACRCursor;
  NewTableName: WideString);
var
  OldTableName: WideString;
  FSessionID: TACRSessionID;
  NewTableNameCRC: Cardinal;
begin
  // rewritten in v.5.10 to avoid locking in renaming table in foreign keys
  Lock(True);
  try
    if (Cursor = nil) then
      raise EACRException.Create(11506, ErrorLNilPointer);
    FSessionID := Cursor.Session.SessionID;
    FExclusive := True;
    OldTableName := FTableName;
    NewTableNameCRC := GetTableNameCRC(NewTableName);
    if (FIsTableOpened) then
      raise EACRException.Create(10789, ErrorLTableIsInUse, [FTableName]);
    if (not LDiskDatabaseData.InternalLockTableList(False)) then
      raise EACRException.Create(10790, ErrorLCannotLockTables,
        [LDiskDatabaseData.DatabaseName]);
    try
      LDiskDatabaseData.FTableListFile.Load;
      if (LDiskDatabaseData.GetTableItemIfExists(NewTableNameCRC, NewTableName,
          FTableItem)) then
        raise EACRException.Create(11490, ErrorLCannotRenameTableAlreadyExists,
          [FTableName, NewTableName]);
      if (not LDiskDatabaseData.GetTableItemIfExists(FTableNameCRC, FTableName,
          FTableItem)) then
        raise EACRException.Create(10791, ErrorLTableDoesNotExists,
          [FTableName, LDiskDatabaseData.DatabaseName]);
      InternalOpenTable(FSessionID);
    finally
      if (not LDiskDatabaseData.InternalUnlockTableList) then
        raise EACRException.Create(10794, ErrorLCannotUnlockTables,
          [LDiskDatabaseData.DatabaseName]);
    end;
    try
      inherited RenameTable(Cursor, NewTableName);
      if (not LDiskDatabaseData.InternalLockTableList(True)) then
        raise EACRException.Create(12169, ErrorLCannotLockTables,
          [LDiskDatabaseData.DatabaseName]);
      try
        try
          LDiskDatabaseData.FTableListFile.Load;
          FTableName := OldTableName;
          FTableNameCRC := GetTableNameCRC(FTableName);
          LDiskDatabaseData.FTableListFile.RenameTable(FTableName,
            NewTableName);
          WriteTableMetadata(FSessionID);
          ApplyChanges(FTableState.TableState, dbstTableMetaData,
            FTableState.TableMetaDataState);
          LDiskDatabaseData.FTableListFile.Save;
          SaveTableState;
          FTableName := NewTableName;
          FTableNameCRC := NewTableNameCRC;
        except
          FCache.CancelChanges;
          FTableState := LoadTableState;
          raise ;
        end;
      finally
        if (not LDiskDatabaseData.InternalUnlockTableList) then
          raise EACRException.Create(12170, ErrorLCannotUnlockTables,
            [LDiskDatabaseData.DatabaseName]);
      end;
    finally
      InternalCloseTable(FSessionID);
    end;
  finally
    Unlock;
  end;
end; // RenameTable

//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TACRDiskTableData.LoadTableFromStream(Cursor: TACRCursor;
  Stream: TStream);
begin
  raise EACRException.Create(11668, ErrorLOperationIsNotSupported);
end; // LoadTableFromStream

//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TACRDiskTableData.SaveTableToStream(Stream: TStream;
  CompressionAlgorithm: TACRCompressionAlgorithm; CompressionMode: Byte;
  BlockSize: Integer; SkipCheckIsTableOpened: Boolean);
begin
  raise EACRException.Create(11669, ErrorLOperationIsNotSupported);
end; // SaveTableToStream

//------------------------------------------------------------------------------
// open locks file
//------------------------------------------------------------------------------
procedure TACRDiskTableData.OpenLocksFile;
begin
  if (FLockManager.FileServer) then
  begin
    if (FTableLockFile <> nil) then
      FreeAndNil(FTableLockFile);
    FTableLockFile := TACRTableLockFile.Create(LPageManager, nil,
      FTableItem.TableID, FLockManager.MaxWaitLockTime);
    FLockManager.LockTableInFileServer := FTableLockFile.LockTable;
    FLockManager.UnlockTableInFileServer := FTableLockFile.UnlockTable;
    FLockManager.ClearWaitLevelInFileServer := FTableLockFile.ClearWaitLevel;
    FTableLockFile.OpenFile(FTableItem.LockFilePageNo);
  end;
end; // OpenLocksFile

//------------------------------------------------------------------------------
// open table
//------------------------------------------------------------------------------
procedure TACRDiskTableData.InternalOpenTable(aSessionID: TACRSessionID);
begin
{$IFDEF DEBUG_TRACE_TACRDiskTableData_InternalOpenTable}
  aaWriteToLog('> TACRDiskTableData.InternalOpenTable, FTableName = ' +
      FTableName + #13#10 + 'aSessionID = ' + IntToStr(aSessionID)
      + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,
      True) + #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount));
{$ENDIF}
  FCache.TableID := FTableItem.TableID;
  if (FTransactionSessionID = INVALID_SESSION_ID) then
    FCache.ImportPagesFromParent;
  // read metadata
  if (FConstraintManager = nil) then
    FConstraintManager := TACRBaseConstraintManager.Create(Self);
  if (FSequenceManager = nil) then
    FSequenceManager := TACRBaseSequenceManager.Create(LDiskDatabaseData);
  if (FFieldManager = nil) then
    FFieldManager := TACRBaseFieldManager.Create(Self, FSequenceManager);
  if (FIndexManager <> nil) then
    FreeAndNil(FIndexManager);
  FIndexManager := TACRBaseIndexManager.Create(Self);
{$IFDEF DEBUG_TRACE_TACRDiskTableData_InternalOpenTable}
  aaWriteToLog('TACRDiskTableData.InternalOpenTable reading TableMetaData...');
{$ENDIF}
  CreateTableFiles;
  // load state directly - only on first open
  FTableState := LDiskDatabaseData.LoadTableState(FTableItem);
  FTableMetaDataFile.OpenFile(FTableItem.MetaDataFilePageNo);
  ReadTableMetadata(aSessionID);
{$IFDEF DEBUG_TRACE_TACRDiskTableData_InternalOpenTable}
  aaWriteToLog
    ('TACRDiskTableData.InternalOpenTable reading TableMetaData...OK');
{$ENDIF}
  // create record manager
  CreateRecordManager;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_InternalOpenTable}
  aaWriteToLog('TACRDiskTableData.InternalOpenTable RecordManager created.');
{$ENDIF}
  // Read data from TableMostUpdatedFile
  FTableMostUpdatedFile.OpenFile(FTableItem.MostUpdatedDataFilePageNo);
  // if (FExclusive) then
  begin
    FTableState := LoadTableState;
    ReadMostUpdatedData(aSessionID);
    FMUDLoaded := True;
    FMUDState := FTableState.TableState;
    FTransactionMUD := (aSessionID = FTransactionSessionID);
  end;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_InternalOpenTable}
  aaWriteToLog('< TACRDiskTableData.InternalOpenTable, FTableName = ' +
      FTableName + ', SessionID = ' + IntToStr(aSessionID));
{$ENDIF}
  FIsTableOpened := True;
end; // InternalOpenTable

//------------------------------------------------------------------------------
// close table
//------------------------------------------------------------------------------
procedure TACRDiskTableData.InternalCloseTable(aSessionID: TACRSessionID);
begin
  FreeAndNil(FRecordManager);
  FreeAndNil(FSequenceManager);
  FreeAndNil(FIndexManager);
  FreeAndNil(FConstraintManager);
  FreeAndNil(FFieldManager);
  FMUDLoaded := False;
  FIsTableOpened := False;
  // close only if not in transaction
  if (FTransactionSessionID = INVALID_SESSION_ID) then
    FCache.ExportPagesToParent;
end; // InternalCloseTable

//------------------------------------------------------------------------------
// OpenTable
//------------------------------------------------------------------------------
procedure TACRDiskTableData.OpenTable(Cursor: TACRCursor);
var
  FSessionID: TACRSessionID;
begin
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
  aaWriteToLog('> TACRDiskTableData.OpenTable. Cursor = ' + IntToHex
      (Integer(Cursor), 8) + #13#10 + 'TableName = ' + FTableName);
{$ENDIF}
  Lock(True);
  try
    FSessionID := Cursor.Session.SessionID;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
    aaWriteToLog('TACRDiskTableData.OpenTable. SessionID = ' + IntToStr
        (FSessionID) + #13#10 + 'FIsTableOpened = ' + BoolToStr
        (FIsTableOpened, True) + #13#10 + 'FExclusive = ' + BoolToStr
        (FExclusive, True) + #13#10 + 'Cursor.Exclusive = ' + BoolToStr
        (Cursor.Exclusive, True) + #13#10 + 'FCursorList.Count = ' + IntToStr
        (FCursorList.Count));
{$ENDIF}
    if (FSessionID < 0) then
      raise EACRException.Create(10669, ErrorLInvalidSessionID, [FSessionID]);
    // aaStartTime(time7);
    if (not FIsTableOpened) then
    begin
      DeleteTableFiles;
      { TODO -oLeo : foreign keys should do it only first time!!! }
      // if (not Cursor.SkipTableExistsCheck) then
      // begin
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
      aaWriteToLog('1. TACRDiskTableData.OpenTable. Cursor = ' + IntToHex
          (Integer(Cursor), 8) + #13#10 + 'TableName = ' + FTableName);
{$ENDIF}
      if (not LDiskDatabaseData.InternalLockTableList(False)) then
        raise EACRException.Create(10796, ErrorLCannotLockTables,
          [LDiskDatabaseData.DatabaseName]);
      try
        // aaStartTime(time8);
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
        aaWriteToLog('2. TACRDiskTableData.OpenTable. Cursor = ' + IntToHex
            (Integer(Cursor), 8) + #13#10 + 'TableName = ' + FTableName);
{$ENDIF}
        LDiskDatabaseData.FTableListFile.Load;
        if (not LDiskDatabaseData.GetTableItemIfExists(FTableNameCRC,
            FTableName, FTableItem, FComment)) then
          raise EACRException.Create(10797, ErrorLTableDoesNotExists,
            [FTableName, LDiskDatabaseData.DatabaseName]);
        // aaStopTime(time8);
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
        aaWriteToLog('3. TACRDiskTableData.OpenTable. Cursor = ' + IntToHex
            (Integer(Cursor), 8) + #13#10 + 'TableName = ' + FTableName);
{$ENDIF}
      finally
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
        aaWriteToLog('4. TACRDiskTableData.OpenTable. Cursor = ' + IntToHex
            (Integer(Cursor), 8) + #13#10 + 'TableName = ' + FTableName);
{$ENDIF}
        if (not LDiskDatabaseData.InternalUnlockTableList) then
          raise EACRException.Create(10798, ErrorLCannotUnlockTables,
            [LDiskDatabaseData.DatabaseName]);
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
        aaWriteToLog('5. TACRDiskTableData.OpenTable. Cursor = ' + IntToHex
            (Integer(Cursor), 8) + #13#10 + 'TableName = ' + FTableName);
{$ENDIF}
      end;
      // end;
      FTableName := Cursor.TableName;
      FTableNameCRC := GetTableNameCRC(FTableName);
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
      aaWriteToLog('6. TACRDiskTableData.OpenTable. Cursor = ' + IntToHex
          (Integer(Cursor), 8) + #13#10 + 'TableName = ' + FTableName);
{$ENDIF}
    end // table is not opened
    else
    // fixed in v.5.10
      if (CheckCannotOpenExclusive(Cursor)) then
      raise EACRException.Create(10810, ErrorLTableIsOpenedInExclusiveMode,
        [FTableName]);
    // aaStopTime(time7);
    // lock table in IS or X
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
    aaWriteToLog('6.1 TACRDiskTableData.OpenTable. Cursor = ' + IntToHex
        (Integer(Cursor), 8) + #13#10 + 'TableName = ' + FTableName);
{$ENDIF}
    if (FLockManager.FileServer) then
      if (FTableLockFile = nil) then
        OpenLocksFile;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
    aaWriteToLog('6.2 TACRDiskTableData.OpenTable. Cursor = ' + IntToHex
        (Integer(Cursor), 8) + #13#10 + 'TableName = ' + FTableName);
{$ENDIF}
    if (Cursor.Exclusive) then
    begin
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
      aaWriteToLog('6.3 TACRDiskTableData.OpenTable. Cursor = ' + IntToHex
          (Integer(Cursor), 8) + #13#10 + 'TableName = ' + FTableName);
{$ENDIF}
      if (not TryToLockTableX(FSessionID)) then
        raise EACRException.Create(10799, ErrorLCannotLockTable,
          ['X', FTableName, FSessionID]);
      FExclusive := True;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
      aaWriteToLog('6.4 TACRDiskTableData.OpenTable. Cursor = ' + IntToHex
          (Integer(Cursor), 8) + #13#10 + 'TableName = ' + FTableName);
{$ENDIF}
    end // lock in X
    else
    begin
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
      aaWriteToLog('7. TACRDiskTableData.OpenTable. Cursor = ' + IntToHex
          (Integer(Cursor), 8) + #13#10 + 'TableName = ' + FTableName);
{$ENDIF}
      if (not TryToLockTableIS(FSessionID)) then
        raise EACRException.Create(10800, ErrorLCannotLockTable,
          ['IS', FTableName, FSessionID]);
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
      aaWriteToLog('8. TACRDiskTableData.OpenTable. Cursor = ' + IntToHex
          (Integer(Cursor), 8) + #13#10 + 'TableName = ' + FTableName);
{$ENDIF}
    end; // lock in IS
    {
      aaWriteToLog('8.1 TACRDiskTableData.OpenTable. SessionID = '+IntToStr(FSessionID)
      +#13#10+'FIsTableOpened = '+BoolToStr(FIsTableOpened,True));
      if (not FIsTableOpened) then
      begin
      FTransactionCount := 0;
      FActiveTransactionSessionID := INVALID_SESSION_ID;
      aaWriteToLog('8.2 TACRDiskTableData.OpenTable. SessionID = '+IntToStr(FSessionID)
      +#13#10+'FIsTableOpened = '+BoolToStr(FIsTableOpened,True));
      InternalOpenTable(FSessionID);
      aaWriteToLog('8.3 TACRDiskTableData.OpenTable. SessionID = '+IntToStr(FSessionID)
      +#13#10+'FIsTableOpened = '+BoolToStr(FIsTableOpened,True));
      if (Cursor.Session.InTransaction) then
      StartTransaction(FSessionID);
      end;
      }
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
    aaWriteToLog('9. TACRDiskTableData.OpenTable. Cursor = ' + IntToHex
        (Integer(Cursor), 8) + #13#10 + 'TableName = ' + FTableName);
{$ENDIF}
    LockCursorList;
    try
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
      aaWriteToLog('8.1 TACRDiskTableData.OpenTable. SessionID = ' + IntToStr
          (FSessionID) + #13#10 + 'FIsTableOpened = ' + BoolToStr
          (FIsTableOpened, True));
{$ENDIF}
      if (not FIsTableOpened) then
      begin
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
        aaWriteToLog('8.2 TACRDiskTableData.OpenTable. SessionID = ' + IntToStr
            (FSessionID) + #13#10 + 'FIsTableOpened = ' + BoolToStr
            (FIsTableOpened, True));
{$ENDIF}
        FExclusive := Cursor.Exclusive;
        InternalOpenTable(FSessionID);
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
        aaWriteToLog('8.3 TACRDiskTableData.OpenTable. SessionID = ' + IntToStr
            (FSessionID) + #13#10 + 'FIsTableOpened = ' + BoolToStr
            (FIsTableOpened, True));
{$ENDIF}
      end;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
      aaWriteToLog('10. TACRDiskTableData.OpenTable. Cursor = ' + IntToHex
          (Integer(Cursor), 8) + #13#10 + 'TableName = ' + FTableName);
{$ENDIF}
      inherited;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
      aaWriteToLog('11. TACRDiskTableData.OpenTable. Cursor = ' + IntToHex
          (Integer(Cursor), 8) + #13#10 + 'TableName = ' + FTableName);
{$ENDIF}
    finally
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
      aaWriteToLog('12. TACRDiskTableData.OpenTable. Cursor = ' + IntToHex
          (Integer(Cursor), 8) + #13#10 + 'TableName = ' + FTableName);
{$ENDIF}
      UnlockCursorList;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_OpenTable}
      aaWriteToLog('< TACRDiskTableData.OpenTable. Cursor = ' + IntToHex
          (Integer(Cursor), 8) + #13#10 + 'TableName = ' + FTableName);
{$ENDIF}
    end;
  finally
    Unlock;
  end;
end; // OpenTable

//------------------------------------------------------------------------------
// CloseTable
//------------------------------------------------------------------------------
procedure TACRDiskTableData.CloseTable(Cursor: TACRCursor);
var
  SkipUnlock: Boolean;
  FSessionID: TACRSessionID;
begin
  if (not FIsTableOpened) then
    Exit;
  SkipUnlock := False;
  if (Cursor is TACRLocalCursor) then
    if (TACRLocalCursor(Cursor).DoNotUnlockTable) then
      SkipUnlock := True;
  FSessionID := Cursor.Session.SessionID;
  LockCursorList;
  try
    if (FCursorList.IndexOf(Cursor) < 0) then
      Exit;
    inherited CloseTable(Cursor);
    if (FCursorList.Count = 0) then
    begin
      InternalCloseTable(FSessionID);
    end;
  finally
    UnlockCursorList;
  end;
  if (FSessionID < 0) then
    raise EACRException.Create(10801, ErrorLInvalidSessionID, [FSessionID]);
  if (Cursor.FExclusive) then
  begin
    if (not SkipUnlock) then
      TryToUnlockTableX(FSessionID);
  end
  else
  begin
    if (not SkipUnlock) then
      TryToUnlockTableIS(FSessionID);
  end;
end; // CloseTable

//------------------------------------------------------------------------------
// Rename Field by Field Index in FieldDefs
//------------------------------------------------------------------------------
procedure TACRDiskTableData.RenameField(Cursor: TACRCursor;
  FieldName, NewFieldName: WideString);
var
  FSessionID: TACRSessionID;
begin
  Lock(True);
  try
    FSessionID := Cursor.Session.SessionID;
    if (not FIsTableOpened) or (not FExclusive) then
      raise EACRException.Create(10804, ErrorLTableIsNotOpenedExclusively,
        [FTableName]);
    if (Cursor.Session.InTransaction) then
      raise EACRException.Create(10837,
        ErrorLCannotPerformThisOperationInsideATransaction);
    try
      inherited RenameField(Cursor, FieldName, NewFieldName);
      WriteTableMetadata(FSessionID);
      ApplyChanges(FTableState.TableState, dbstTableMetaData,
        FTableState.TableMetaDataState);
      SaveTableState;
    except
      FCache.CancelChanges;
      FTableState := LoadTableState;
      raise ;
    end;
  finally
    Unlock;
  end;
end; // RenameField

//------------------------------------------------------------------------------
// add index
//------------------------------------------------------------------------------
procedure TACRDiskTableData.AddIndex(IndexDef: TACRIndexDef;
  Cursor: TACRCursor);
var
  FSessionID: TACRSessionID;
begin
  Lock(True);
  try
    FSessionID := Cursor.Session.SessionID;
    if (not Cursor.Exclusive) then
      raise EACRException.Create(10609, ErrorLTableIsNotOpenedExclusively,
        [FTableName]);
    if (FTransactionSessionID <> INVALID_SESSION_ID) then
      raise EACRException.Create(10834,
        ErrorLCannotPerformThisOperationInsideATransaction);
    try
      LockCursorList;
      try
        inherited AddIndex(IndexDef, Cursor);
      finally
        UnlockCursorList;
      end;
      WriteTableMetadata(FSessionID);
      WriteMostUpdatedData(FSessionID);
      ApplyChanges(FTableState.TableState, dbstTableMetaData,
        FTableState.TableMetaDataState);
      SaveTableState;
    except
      FCache.CancelChanges;
      FTableState := LoadTableState;
      raise ;
    end;
  finally
    Unlock;
  end;
end; // AddIndex

//------------------------------------------------------------------------------
// delete index
//------------------------------------------------------------------------------
procedure TACRDiskTableData.DeleteIndex(IndexID: TACRObjectID;
  Cursor: TACRCursor);
var
  FSessionID: TACRSessionID;
begin
  Lock(True);
  try
    FSessionID := Cursor.Session.SessionID;
    if (not Cursor.Exclusive) then
      raise EACRException.Create(10610, ErrorLTableIsNotOpenedExclusively,
        [FTableName]);
    if (FTransactionSessionID <> INVALID_SESSION_ID) then
      raise EACRException.Create(10835,
        ErrorLCannotPerformThisOperationInsideATransaction);
    try
      LockCursorList;
      try
        inherited DeleteIndex(IndexID, Cursor);
      finally
        UnlockCursorList;
      end;
      WriteTableMetadata(FSessionID);
      WriteMostUpdatedData(FSessionID);
      ApplyChanges(FTableState.TableState, dbstTableMetaData,
        FTableState.TableMetaDataState);
      SaveTableState;
    except
      FCache.CancelChanges;
      FTableState := LoadTableState;
      raise ;
    end;
  finally
    Unlock;
  end;
end; // DeleteIndex

//------------------------------------------------------------------------------
// delete all indexes
//------------------------------------------------------------------------------
procedure TACRDiskTableData.DeleteAllIndexes(Cursor: TACRCursor);
var
  FSessionID: TACRSessionID;
begin
  Lock(True);
  try
    FSessionID := Cursor.Session.SessionID;
    if (not Cursor.Exclusive) then
      raise EACRException.Create(10611, ErrorLTableIsNotOpenedExclusively,
        [FTableName]);
    try
      LockCursorList;
      try
        inherited DeleteAllIndexes(Cursor);
      finally
        UnlockCursorList;
      end;
      WriteTableMetadata(FSessionID);
      WriteMostUpdatedData(FSessionID);
      ApplyChanges(FTableState.TableState, dbstTableMetaData,
        FTableState.TableMetaDataState);
      SaveTableState;
    except
      FCache.CancelChanges;
      FTableState := LoadTableState;
      raise ;
    end;
  finally
    Unlock;
  end;
end; // DeleteAllIndexes

//------------------------------------------------------------------------------
// return 0 if id1 = id2, 1 if id1>id2, -1 if id1<id2
//------------------------------------------------------------------------------
function TACRDiskTableData.CompareRecordID(const RecordID1: TACRRecordID;
  const RecordID2: TACRRecordID): Integer;
begin
  if ((RecordID1.PageNo = RecordID2.PageNo) and
      (RecordID1.PageItemNo = RecordID2.PageItemNo)) then
    Result := 0
  else if (RecordID1.PageNo > RecordID2.PageNo) then
    Result := 1
  else if (RecordID1.PageNo < RecordID2.PageNo) then
    Result := -1
  else if (RecordID1.PageItemNo > RecordID2.PageItemNo) then
    Result := 1
  else
    Result := -1
end; // CompareRecordID

//------------------------------------------------------------------------------
// create blob stream
//------------------------------------------------------------------------------
function TACRDiskTableData.InternalCreateBlobStream(Cursor: TACRCursor;
  ToInsert: Boolean; FieldNo: Integer;
  OpenMode: TACRBLOBOpenMode): TACRStream;
var
  TempStream: TACRTemporaryStream;
  CompressedStream: TACRCompressedBLOBStream;
  Buffer: PAnsiChar;
  Offset, BufferSize: Integer;
  BLOBDescriptor: TACRBLOBDescriptor;
  TempDescriptor: TACRPartialTemporaryBLOBDescriptor;
  FSessionID: TACRSessionID;
  FRecordID: TACRRecordID;
{$I ACR_check_null_flag_var.inc}
begin
  // fixed in v.5.70
  if (Cursor.CurrentRecordBuffer <> nil) then
  begin
    CHECK_NULL_FLAG_BitNo := FieldNo;
    CHECK_NULL_FLAG_NullFlags := Cursor.CurrentRecordBuffer;
{$I ACR_check_null_flag.inc}
  end
  else
    CHECK_NULL_FLAG_Result := True;
  if ((ToInsert and (OpenMode = bomWrite)) or (OpenMode = bomWrite) or
      (Cursor.CurrentRecordBuffer = nil) or CHECK_NULL_FLAG_Result) then
  begin
    Result := inherited InternalCreateBlobStream(Cursor, ToInsert, FieldNo,
      OpenMode);
  end
  else if (IsBLOBModified(Cursor.CurrentRecordBuffer,
      FieldManager.FieldDefs[FieldNo])) then
  begin
    Result := inherited InternalCreateBlobStream(Cursor, ToInsert, FieldNo,
      OpenMode);
  end
  else
  begin
    // read blob value from disk
    Result := nil;
    BLOBDescriptor.CompressionAlgorithm := Byte
      (FieldManager.FieldDefs[FieldNo].BLOBCompressionAlgorithm);
    BLOBDescriptor.CompressionMode := FieldManager.FieldDefs[FieldNo]
      .BLOBCompressionMode;
    BLOBDescriptor.BlockSize := FieldManager.FieldDefs[FieldNo].BLOBBlockSize;
    if (BLOBDescriptor.BlockSize = 0) then
      raise EACRException.Create(10628, ErrorLZeroBlockSizeIsNotAllowed);
    BLOBDescriptor.StartPosition := 0;
    TempStream := TACRTemporaryStream.Create;
    // create new compressed stream
    // copy value from TableData
    Offset := FieldManager.FieldDefs[FieldNo].MemoryOffset;
    FSessionID := Cursor.Session.SessionID;
    LockTable(False, Cursor.Session, 10629);
    try
      Move(PAnsiChar(Cursor.CurrentRecordBuffer + Offset)^, FRecordID,
        SizeOf(FRecordID));
      Buffer := nil;
      // read blob value from disk
      Lock(True);
      try
        TACRDiskRecordManager(FRecordManager).InternalReadBLOBOrVarcharValue
          (FSessionID, FRecordID, False, TempDescriptor, Buffer, BufferSize);
      finally
        Unlock;
      end;
      if (Buffer = nil) then
        raise EACRException.Create(10631, ErrorLNilPointer);
      try
        // copy partial blob descriptor
        BLOBDescriptor.NumBlocks := TempDescriptor.NumBlocks;
        BLOBDescriptor.UncompressedSize := TempDescriptor.UncompressedSize;
        TempStream.Write(Buffer^, BufferSize);
        TempStream.Position := 0;
        CompressedStream := TACRCompressedBLOBStream.Create(TempStream,
          BLOBDescriptor, False);
        Result := TACRLocalBLOBStream.Create(CompressedStream, Cursor,
          OpenMode, FieldNo);
      finally
        MemoryManager.FreeAndNilMem(Buffer);
      end;
    finally
      UnlockTable(False, Cursor.Session);
    end;
  end;
end; // InternalCreateBlobStream

//------------------------------------------------------------------------------
// clear blob field
//------------------------------------------------------------------------------
procedure TACRDiskTableData.ClearBLOBFieldInRecordBuffer
  (var RecordBuffer: TACRRecordBuffer; FieldNo: Integer);
var
  Buffer: PAnsiChar;
  sz: Integer;
begin
  if (FBLOBFieldsPresent) then
  begin
    // check null
    if (not((pByte(RecordBuffer + (FieldNo div 8))^) and (1 shl (FieldNo mod 8)
          ) <> 0)) then
    begin
      if (IsBLOBModified(RecordBuffer, FieldManager.FieldDefs[FieldNo])) then
      begin
        Move(PAnsiChar(RecordBuffer + FieldManager.FieldDefs[FieldNo]
              .MemoryOffset)^, Buffer, SizeOf(Buffer));
        if (Buffer = nil) then
          raise EACRException.Create(10118, ErrorLNilPointer);
        if (ACR_ENCRYPTED_DB_USED) then
        begin
          try
            sz := MemoryManager.GetMemoryBufferSize(Buffer);
            FillChar(Buffer^, sz, $00);
          except
          end;
        end;
        MemoryManager.FreeAndNilMem(Buffer);
      end;

      // set null
      pByte(RecordBuffer + (FieldNo div 8))^ := pByte
        (RecordBuffer + (FieldNo div 8))^ or (1 shl (FieldNo mod 8));
    end;
  end;
end; // ClearBLOBFieldInRecordBuffer

//------------------------------------------------------------------------------
// move cursor to specified position and set current record id in cursor
//------------------------------------------------------------------------------
procedure TACRDiskTableData.InternalSetRecNo(Cursor: TACRCursor;
  RecNo: TACRRecordNo);
var
  RecordID: TACRRecordID;
  FSessionID: TACRSessionID;
begin
  if (FRecordManager = nil) then
    raise EACRException.Create(10566, ErrorLNilPointer);
  FSessionID := Cursor.Session.SessionID;
  RecordID := TACRDiskRecordManager(FRecordManager).GetRecordIDByRecNo(RecNo,
    FSessionID);
  if (RecordID.PageNo = INVALID_PAGE_NO) then
    raise EACRException.Create(10580, ErrorLCannotSetRecNo,
      [RecNo, FTableName]);
  Cursor.CurrentRecordID := RecordID;
end; // SetRecNo

//------------------------------------------------------------------------------
// get current record position from cursor
//------------------------------------------------------------------------------
function TACRDiskTableData.InternalGetRecNo(Cursor: TACRCursor): TACRRecordNo;
var
  FSessionID: TACRSessionID;
begin
  if (FRecordManager = nil) then
    raise EACRException.Create(10567, ErrorLNilPointer);
  FSessionID := Cursor.Session.SessionID;
  Result := TACRDiskRecordManager(FRecordManager).GetRecNoByRecordID
    (Cursor.CurrentRecordID, FSessionID);
end; // GetRecNo

//------------------------------------------------------------------------------
// return filter bitmap rec no by record id
//------------------------------------------------------------------------------
function TACRDiskTableData.GetBitmapRecNoByRecordID(RecordID: TACRRecordID)
  : TACRRecordNo;
var
  BitSize, i, k, mask: Integer;
begin
  k := TACRDiskRecordManager(FRecordManager).RecordsPerPage;
  BitSize := 0;
  for i := 0 to (SizeOf(TACRPageItemID) * 8 - 1) do
    if (((1 shl i) and k) <> 0) then
      BitSize := i + 1;
  mask := 0;
  for i := 0 to BitSize - 1 do
    mask := mask or (1 shl i);
  Result := (RecordID.PageNo shl BitSize) or (mask and RecordID.PageItemNo);
end; // GetBitmapRecNoByRecordID

//------------------------------------------------------------------------------
// return filter bitmap rec no by record id
//------------------------------------------------------------------------------
function TACRDiskTableData.GetRecordIDByBitmapRecNo(RecordNo: TACRRecordNo)
  : TACRRecordID;
var
  BitSize, i, k, mask: Integer;
begin
  k := TACRDiskRecordManager(FRecordManager).RecordsPerPage;
  BitSize := 0;
  for i := 0 to (SizeOf(TACRPageItemID) * 8 - 1) do
    if (((1 shl i) and k) <> 0) then
      BitSize := i + 1;
  mask := 0;
  for i := 0 to BitSize - 1 do
    mask := mask or (1 shl i);
  Result.PageNo := TACRPageNo(RecordNo shr BitSize);
  Result.PageItemNo := TACRPageItemID(mask and RecordNo);
end; // GetRecordIDByBitmapRecNo

///////////////////////////////////////////////////////////////////////////////
//
// TACRDatabaseFreeSpaceManager
// modified in v.5 - FHeader added, locking method changed, caching added
//
///////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRDatabaseFreeSpaceManager.Create
  (aPageManager: TACRDiskPageManager; aLockParams: TACRLockParams);
begin
  LPageManager := aPageManager;
  LockParams := aLockParams;
  GAM := nil;
  SGAM := nil;
  PFS := nil;
  FHeader.TotalPageCount := 0;
  FHeader.FreePageCount := 0;
  FHeader.State := 0;
  PFSPage := nil;
  GAMPage := nil;
  SGAMPage := nil;
  ExtentPageCount := LPageManager.DBHeader.ExtentPageCount;
  PagePerPFSPage := LPageManager.PageDataSize * 8;
  PagePerExt := PagePerPFSPage * ExtentPageCount;
end; // Create

//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRDatabaseFreeSpaceManager.Destroy;
begin
  {
    if (GAM <> nil) then
    MemoryManager.FreeAndNilMem(GAM);
    if (SGAM <> nil) then
    MemoryManager.FreeAndNilMem(SGAM);
    if (PFS <> nil) then
    MemoryManager.FreeAndNilMem(PFS);
    }
  PutPages;
  inherited;
end; // Destroy

//------------------------------------------------------------------------------
// CreateFreeSpaceManager
//------------------------------------------------------------------------------
procedure TACRDatabaseFreeSpaceManager.CreateFreeSpaceManager;
var
{$I ACR_set_null_flag_var.inc}
begin
  if LPageManager.FDBHeader.ExtentPageCount < ACRMinExtentPageCount then
    raise EACRException.Create(50028, ErrorFInvalidExtPageCount);
  PutPages;
  FHeader.TotalPageCount := 3;
  FHeader.FreePageCount := 0;
  FHeader.State := 0;
  GAMPage := LPageManager.GetPage(FSM_SESSION_ID, ACRFirstPageNoGAM,
    dbstFreeSpaceManager, FHeader.State, False, True, False);
  SGAMPage := LPageManager.GetPage(FSM_SESSION_ID, ACRFirstPageNoSGAM,
    dbstFreeSpaceManager, FHeader.State, False, True, False);
  PFSPage := LPageManager.GetPage(FSM_SESSION_ID, ACRFirstPageNoPFS,
    dbstFreeSpaceManager, FHeader.State, False, True, False);
  GAM := GAMPage.PageData;
  SGAM := SGAMPage.PageData;
  PFS := PFSPage.PageData;
  FillChar(GAM^, LPageManager.PageDataSize, 0);
  FillChar(SGAM^, LPageManager.PageDataSize, 0);
  FillChar(PFS^, LPageManager.PageDataSize, 0);
  // Set initial bits
  SET_NULL_FLAG_ToSet := True;
  SET_NULL_FLAG_NullFlags := PFS;
  for SET_NULL_FLAG_BitNo := 0 to 2 do
  begin
{$I ACR_set_null_flag.inc}
  end;
  SET_NULL_FLAG_BitNo := 0;
  SET_NULL_FLAG_NullFlags := GAM;
{$I ACR_set_null_flag.inc}
  LPageManager.CheckFileSize;
  // Write maps to file
  PutPages;
  LPageManager.ApplyChanges(FHeader.State);
  LPageManager.SaveFSMHeader(FHeader);
end; // CreateFreeSpaceManager

//------------------------------------------------------------------------------
// return true if page is a system page: GAM/SGAM/PFS
//------------------------------------------------------------------------------
function TACRDatabaseFreeSpaceManager.IsFSMPage(PageNo: TACRPageNo): Boolean;
var
  pn: TACRPageNo;
begin
  // check PFS
  pn := PageNo div PagePerPFSPage;
  pn := pn * PagePerPFSPage;
  Result := (pn = PageNo);
  if (not Result) then
  begin
    // check GAM/SGAM
    pn := PageNo div PagePerExt;
    pn := pn * PagePerExt;
    Result := ((PageNo >= (pn + 1)) and (PageNo <= (pn + 2)));
  end;
end; // IsFSMPage

//------------------------------------------------------------------------------
// find GAM page
//------------------------------------------------------------------------------
procedure TACRDatabaseFreeSpaceManager.FindGAMPage(const PageNo: TACRPageNo;
  // page number to find GAM
  out GAMPageNo: TACRPageNo; // GAM page number
  out GAMBitNo: TACRPageNo // bit number inside GAM
  );
var
  n: TACRPageNo;
begin
  n := PageNo mod PagePerExt;
  GAMBitNo := n div ExtentPageCount;
  GAMPageNo := PageNo - n + ACRFirstPageNoGAM;
end; // FindGAMPage

//------------------------------------------------------------------------------
// find PFS page
//------------------------------------------------------------------------------
procedure TACRDatabaseFreeSpaceManager.FindPFSPage(const PageNo: TACRPageNo;
  // page number to find PFS
  out PFSPageNo: TACRPageNo; // PFS page number
  out PFSBitNo: TACRPageNo // bit number inside PFS
  );
begin
  PFSBitNo := PageNo mod PagePerPFSPage;
  PFSPageNo := PageNo - PFSBitNo + ACRFirstPageNoPFS;
end; // FindPFSPage

//------------------------------------------------------------------------------
// put pages
//------------------------------------------------------------------------------
procedure TACRDatabaseFreeSpaceManager.PutPages;
begin
  if (PFSPage <> nil) then
  begin
    LPageManager.PutPage(PFSPage);
    PFSPage := nil;
  end;
  if (GAMPage <> nil) then
  begin
    LPageManager.PutPage(GAMPage);
    GAMPage := nil;
  end;
  if (SGAMPage <> nil) then
  begin
    LPageManager.PutPage(SGAMPage);
    SGAMPage := nil;
  end;
end; // PutPages

//------------------------------------------------------------------------------
// LoadPage (0=PFS 1=GAM 2=SGAM)
//------------------------------------------------------------------------------
procedure TACRDatabaseFreeSpaceManager.LoadPage(PageNo: TACRPageNo;
  PageType: TACRFreeSpaceManagerPageType; ReadPage: Boolean;
  UpdatePage: Boolean);
var
  msg: AnsiString;
begin
{$IFDEF DEBUG_TRACE_FreeSpaceManager_LoadPage}
  aaWriteToLog('> TACRDatabaseFreeSpaceManager.LoadPage' + #13#10 +
      'PageNo = ' + IntToStr(PageNo)
      + #13#10 + 'PageType = ' + IntToStr(Integer(PageType))
      + #13#10 + 'ReadPage = ' + BoolToStr(ReadPage,
      True) + #13#10 + 'UpdatePage = ' + BoolToStr(UpdatePage, True));
  try
{$ENDIF}
    msg := '';
    case PageType of
      fsmPFS:
        begin
          if (PFSPage <> nil) then
            LPageManager.PutPage(PFSPage);
          PFSPage := nil;
          try
            PFSPage := LPageManager.GetPage(FSM_SESSION_ID, PageNo,
              dbstFreeSpaceManager, FHeader.State, ReadPage, UpdatePage);
            if (PFSPage <> nil) then
              PFS := PFSPage.PageData;
          except
            on e: Exception do
            begin
              msg := e.Message;
              PFSPage := nil;
            end;
          end;
          if (PFSPage = nil) then
            raise EACRException.Create(11809, ErrorLFSMGetPageFailed,
              [PageNo, 'PFS', msg]);
        end;
      fsmGAM:
        begin
          if (GAMPage <> nil) then
            LPageManager.PutPage(GAMPage);
          GAMPage := nil;
          try
            GAMPage := LPageManager.GetPage(FSM_SESSION_ID, PageNo,
              dbstFreeSpaceManager, FHeader.State, ReadPage, UpdatePage);
            if (GAMPage <> nil) then
              GAM := GAMPage.PageData;
          except
            on e: Exception do
            begin
              msg := e.Message;
              GAMPage := nil;
            end;
          end;
          if (GAMPage = nil) then
            raise EACRException.Create(11809, ErrorLFSMGetPageFailed,
              [PageNo, 'GAM', msg]);
        end;
      fsmSGAM:
        begin
          if (SGAMPage <> nil) then
            LPageManager.PutPage(SGAMPage);
          SGAMPage := nil;
          try
            SGAMPage := LPageManager.GetPage(FSM_SESSION_ID, PageNo,
              dbstFreeSpaceManager, FHeader.State, ReadPage, UpdatePage);
            if (SGAMPage <> nil) then
              SGAM := SGAMPage.PageData;
          except
            on e: Exception do
            begin
              msg := e.Message;
              SGAMPage := nil;
            end;
          end;
          if (SGAMPage = nil) then
            raise EACRException.Create(11809, ErrorLFSMGetPageFailed,
              [PageNo, 'SGAM', msg]);
        end;
    end;
{$IFDEF DEBUG_TRACE_FreeSpaceManager_LoadPage}
    aaWriteToLog('< TACRDatabaseFreeSpaceManager.LoadPage' + #13#10 +
        'PageNo = ' + IntToStr(PageNo) + #13#10 + 'PageType = ' + IntToStr
        (Integer(PageType)) + #13#10 + 'ReadPage = ' + BoolToStr(ReadPage,
        True) + #13#10 + 'UpdatePage = ' + BoolToStr(UpdatePage, True));
  except
    on e: Exception do
    begin
      aaWriteToLog('Error in  TACRDatabaseFreeSpaceManager.LoadPage' + #13#10 +
          'PageNo = ' + IntToStr(PageNo) + #13#10 + 'PageType = ' + IntToStr
          (Integer(PageType)) + #13#10 + 'ReadPage = ' + BoolToStr(ReadPage,
          True) + #13#10 + 'UpdatePage = ' + BoolToStr(UpdatePage,
          True) + #13#10 + e.Message);
      raise ;
    end;
  end;
{$ENDIF}
end; // LoadPage

//------------------------------------------------------------------------------
// Append New Page
//------------------------------------------------------------------------------
function TACRDatabaseFreeSpaceManager.AppendNewPage: TACRPageNo;
var
  BitNo, GAMPageNo, PageNo, PFSNo, PFSPageNo, i: TACRPageNo;
  GAMNeed, PFSNeed, bLoadGAM, bLoadPFS: Boolean;
{$I ACR_set_null_flag_var.inc}
begin
  PFSNeed := ((PFSCount * PagePerPFSPage) = FHeader.TotalPageCount);
  GAMNeed := ((GAMCount * PagePerExt) = FHeader.TotalPageCount);
  PageNo := FHeader.TotalPageCount;
  SET_NULL_FLAG_ToSet := True;
  if (GAMNeed) then
  begin
    // Create new GAM/SGAM/PFS pages
    // create new PFS page
    PutPages;
    LoadPage(PageNo, fsmPFS, False, True);
    LoadPage(PageNo + 1, fsmGAM, False, True);
    LoadPage(PageNo + 2, fsmSGAM, False, True);
    FillChar(GAM^, LPageManager.PageDataSize, 0);
    FillChar(SGAM^, LPageManager.PageDataSize, 0);
    FillChar(PFS^, LPageManager.PageDataSize, 0);
    SET_NULL_FLAG_NullFlags := PFS;
    for SET_NULL_FLAG_BitNo := 0 to 3 do
    begin
{$I ACR_set_null_flag.inc}
    end;
    SET_NULL_FLAG_BitNo := 0;
    SET_NULL_FLAG_NullFlags := GAM;
{$I ACR_set_null_flag.inc}
    // min extent page count - mark extent full
    if (LPageManager.FDBHeader.ExtentPageCount = 4) then
    begin
      SET_NULL_FLAG_NullFlags := SGAM;
{$I ACR_set_null_flag.inc}
    end;
    Inc(GAMCount);
    Inc(PFSCount);
    Inc(FHeader.TotalPageCount, 4);
    // LPageManager.CheckFileSize;
    Result := PageNo + 3;
  end
  else if PFSNeed then
  begin
    PutPages;
    // create new PFS page
    FindGAMPage(PageNo, GAMPageNo, BitNo);
    LoadPage(PageNo, fsmPFS, False, True);
    LoadPage(GAMPageNo, fsmGAM, True, True);
    // only PFS page must be added (GAM/SGAM addresses it and new page)
    FillChar(PFS^, LPageManager.PageDataSize, 0);
    SET_NULL_FLAG_NullFlags := PFS;
    for SET_NULL_FLAG_BitNo := 0 to 1 do
    begin
{$I ACR_set_null_flag.inc}
    end;
    // mark this extent as used
    SET_NULL_FLAG_NullFlags := GAM;
    SET_NULL_FLAG_BitNo := Integer(BitNo);
{$I ACR_set_null_flag.inc}
    Inc(PFSCount);
    // LPageManager.ExtendFile(2);
    Inc(FHeader.TotalPageCount, 2);
    Result := PageNo + 1;
  end
  else if (not PFSNeed) and (not GAMNeed) then
  begin
    FindPFSPage(PageNo, PFSPageNo, BitNo);
    bLoadPFS := (PFSPage = nil);
    if (not bLoadPFS) then
      bLoadPFS := (PFSPage.PageNo <> PFSPageNo);
    if (bLoadPFS) then
      LoadPage(PFSPageNo, fsmPFS, True, True);
    // set bit in PFS - mark the page as used page
    if (not PFSPage.Updated) then
      LPageManager.UpdatePage(FSM_SESSION_ID, PFSPage, dbstFreeSpaceManager,
        FHeader.State, False);
    SET_NULL_FLAG_NullFlags := PFS;
    SET_NULL_FLAG_BitNo := Integer(BitNo);
{$I ACR_set_null_flag.inc}
    // set bit to 1 in GAM if the page is first in the extent - mark it as used extent
    i := PageNo mod ExtentPageCount;
    if (i = 0) then
    begin
      // set bit to 1 in GAM if the page is first page in the extent - mark it as used extent
      FindGAMPage(PageNo, GAMPageNo, BitNo);
      bLoadGAM := (GAMPage = nil);
      if (not bLoadGAM) then
        bLoadGAM := (GAMPage.PageNo <> GAMPageNo);
      if (bLoadGAM) then
        LoadPage(GAMPageNo, fsmGAM, True, True);
      if (not GAMPage.Updated) then
        LPageManager.UpdatePage(FSM_SESSION_ID, GAMPage, dbstFreeSpaceManager,
          FHeader.State, False);
      SET_NULL_FLAG_NullFlags := GAM;
      SET_NULL_FLAG_BitNo := Integer(BitNo);
{$I ACR_set_null_flag.inc}
    end;
    if (i = (ExtentPageCount - 1)) then
    begin
      // set bit to 1 in SGAM if the page is last page in the extent - mark it as uniform extent
      FindGAMPage(PageNo, GAMPageNo, BitNo);
      Inc(GAMPageNo);
      bLoadGAM := (GAMPage = nil);
      if (not bLoadGAM) then
        bLoadGAM := (SGAMPage.PageNo <> GAMPageNo);
      if (bLoadGAM) then
        LoadPage(GAMPageNo, fsmSGAM, True, True);
      if (not SGAMPage.Updated) then
        LPageManager.UpdatePage(FSM_SESSION_ID, SGAMPage, dbstFreeSpaceManager,
          FHeader.State, False);
      SET_NULL_FLAG_NullFlags := SGAM;
      SET_NULL_FLAG_BitNo := Integer(BitNo);
{$I ACR_set_null_flag.inc}
    end;
    Inc(FHeader.TotalPageCount);
    // LPageManager.ExtendFile(1);
    Result := PageNo;
  end;
end; // AppendNewPage


//------------------------------------------------------------------------------
// checks if there are some empty pages at the end of file and cut file if found
//------------------------------------------------------------------------------
procedure TACRDatabaseFreeSpaceManager.CheckShrinking;
var
  PFSPageNo, PFSBitNo, PageNo, LastUsedPageNo, fpc: TACRPageNo;
  bEOFFound: Boolean;
{$I ACR_check_null_flag_var.inc}
begin
  PageNo := FHeader.TotalPageCount - 1;
  LastUsedPageNo := PageNo;
  FindPFSPage(PageNo, PFSPageNo, PFSBitNo);
  if (PFSBitNo < 0) or (PFSBitNo >= PagePerPFSPage) then
    raise EACRException.Create(11831, ErrorFInvalidBitNo,
      [PFSBitNo, LPageManager.PageDataSize]);
  // new free page count
  fpc := 0;
  if (PFSBitNo > 0) then
  begin
    bEOFFound := False;
    // fixed in v.5.90 - shrinking of used pages without exiting first loop
    while (not bEOFFound) do
    begin
      LoadPage(PFSPageNo, fsmPFS, True, False);
      try
        // bitNo=0 - PFS page itself
        while (PFSBitNo >= 0) do
        begin
          CHECK_NULL_FLAG_BitNo := Integer(PFSBitNo);
          CHECK_NULL_FLAG_NullFlags := PFS;
{$I ACR_check_null_flag.inc}
          if (CHECK_NULL_FLAG_Result) then
          begin
            if ((PFSPageNo = ACRFirstPageNoPFS) and
                (PFSBitNo <= ACRFirstPageNoSGAM)) or
                (not IsFSMPage(PFSPageNo + PFSBitNo)) then
            begin
              bEOFFound := True;
              break;
            end;
          end
          else
            Inc(fpc);
          Dec(LastUsedPageNo);
          Dec(PFSBitNo);
        end; // scan pfs page
      finally
        LPageManager.PutPage(PFSPage);
        PFSPage := nil;
      end;
      PFSBitNo := PagePerPFSPage - 1;
      if (PFSPageNo >= PagePerPFSPage) then
        PFSPageNo := PFSPageNo - PagePerPFSPage
      else
        break;
    end; // scan all pfs
    // shrinking
    if (LastUsedPageNo < PageNo) then
    begin
      FHeader.TotalPageCount := LastUsedPageNo + 1;
      if (FHeader.FreePageCount >= fpc) then
        Dec(FHeader.FreePageCount, fpc);
    end;
  end;
end; // CheckShrinkning


//------------------------------------------------------------------------------
// get new single page - with full scan of free pages if they exists
//------------------------------------------------------------------------------
function TACRDatabaseFreeSpaceManager.InternalGetPage: TACRPageNo;
var
  CurGAM, k: Integer;
  EmptyExt, EmptyPage, PageNo, PFSPageNo, rpn: TACRPageNo;
  FirstPage, LastPage, LastUsedExt, PFSBitNo, Mic: TACRPageNo;
{$I ACR_check_null_flag_var.inc}
{$I ACR_set_null_flag_var.inc}
begin
{$IFDEF DEBUG_TACRDatabaseFreeSpaceManager_GetPage}
  aaIncCounter(counter1);
  aaStartTime(time1);
  try
{$ENDIF}
    CurGAM := 0;
    PFSCount := ((FHeader.TotalPageCount - 1) div PagePerPFSPage) + 1;
    GAMCount := ((FHeader.TotalPageCount - 1) div PagePerExt) + 1;
    // check if there are no free pages inside - added in v.5
    if (FHeader.FreePageCount <= 0) then
      Result := AppendNewPage
    else
      repeat
        LoadPage(ACRFirstPageNoSGAM + CurGAM * PagePerExt, fsmSGAM, True,
          False);
        LoadPage(ACRFirstPageNoGAM + CurGAM * PagePerExt, fsmGAM, True, False);
        // Last existing extent in the GAM block
        Mic := (FHeader.TotalPageCount - (GAMCount - 1) * PagePerExt);
        if CurGAM = GAMCount - 1 then
          LastUsedExt := Mic div ExtentPageCount
        else
          LastUsedExt := PagePerPFSPage - 1;
        if (LastUsedExt >= PagePerPFSPage) then
          raise EACRException.Create(11825, ErrorFInvalidBitNo,
            [LastUsedExt, LPageManager.PageDataSize]);
        // Search mixed extent
        EmptyExt := -1;
        CHECK_NULL_FLAG_BitNo := 0;
        CHECK_NULL_FLAG_NullFlags := SGAM;
        while (CHECK_NULL_FLAG_BitNo <= LastUsedExt) do
        begin
{$I ACR_check_null_flag.inc}
          if (not CHECK_NULL_FLAG_Result) then
          begin
            EmptyExt := CHECK_NULL_FLAG_BitNo;
            break;
          end;
          Inc(CHECK_NULL_FLAG_BitNo);
        end;
        if (EmptyExt <> -1) then
        begin
          // MIXED or empty extent found - search empty page inside it
          PageNo := EmptyExt * ExtentPageCount + CurGAM * PagePerExt;
          FindPFSPage(PageNo, PFSPageNo, PFSBitNo);
          LoadPage(PFSPageNo, fsmPFS, True, False);
          // The first page of found extent inside PFS page (1 bit == 1 page)
          FirstPage := PageNo - PFSPageNo;
          // The last page of found extent inside PFS page (1 bit == 1 page)
          LastPage := FirstPage + ExtentPageCount - 1;
          if (FirstPage < 0) or (FirstPage >= LPageManager.PageDataSize * 8)
            then
            raise EACRException.Create(11826, ErrorFInvalidBitNo,
              [FirstPage, LPageManager.PageDataSize]);
          if (LastPage < 0) or (LastPage >= LPageManager.PageDataSize * 8) then
            raise EACRException.Create(11827, ErrorFInvalidBitNo,
              [LastPage, LPageManager.PageDataSize]);
          // Search of empty page
          // optimized in v.4.40 by Leo Martin
          // k - number of filled pages inside curent extent
          k := 0;
          // EmptyPage - absolute number of the empty page found in the extent
          EmptyPage := -1;
          CHECK_NULL_FLAG_NullFlags := PFS;
          for CHECK_NULL_FLAG_BitNo := FirstPage to LastPage do
          begin
{$I ACR_check_null_flag.inc}
            if (CHECK_NULL_FLAG_Result) then
              Inc(k)
            else if (EmptyPage = -1) then
              EmptyPage := PageNo + (CHECK_NULL_FLAG_BitNo - FirstPage);
          end;
          // changed in 4.60 as EmptyPage is now absolute
          if (((EmptyPage = -1) or (EmptyPage >= FHeader.TotalPageCount)) and
              (CurGAM + 1 = GAMCount)) then
          begin
            // Create new empty page in the end of file - should never happens
            Result := AppendNewPage;
            break;
          end
          else
          // Mark empty page as not empty and write PFS, GAM and SGAM pages to file
          begin
            // relative page no
            rpn := EmptyPage - PFSPageNo;
            // check if empty page is not addressed by the PFS page
            if (EmptyPage < 0) or (rpn >= PagePerPFSPage) then
              raise EACRException.Create(50026, ErrorFInvalidBitNo,
                [EmptyPage, LPageManager.PageDataSize]);
            // check if found extent is not adressed by current GAM/SGAM
            if (EmptyExt < 0) or (EmptyExt >= LPageManager.PageDataSize * 8)
              then
              raise EACRException.Create(50027, ErrorFInvalidBitNo,
                [EmptyExt, LPageManager.PageDataSize]);

            // mark page as filled in PFS
            LPageManager.UpdatePage(FSM_SESSION_ID, PFSPage,
              dbstFreeSpaceManager, FHeader.State, False);
            SET_NULL_FLAG_ToSet := True;
            SET_NULL_FLAG_BitNo := Integer(rpn);
            SET_NULL_FLAG_NullFlags := PFS;
{$I ACR_set_null_flag.inc}
            // mark extent as filled in GAM (fully or partially) if it was empty
            if (k <= 0) then
            begin
              CHECK_NULL_FLAG_NullFlags := GAM;
              CHECK_NULL_FLAG_BitNo := Integer(EmptyExt);
{$I ACR_check_null_flag.inc}
              if (not CHECK_NULL_FLAG_Result) then
              begin
                LPageManager.UpdatePage(FSM_SESSION_ID, GAMPage,
                  dbstFreeSpaceManager, FHeader.State, False);
                SET_NULL_FLAG_BitNo := Integer(EmptyExt);
                SET_NULL_FLAG_NullFlags := GAM;
{$I ACR_set_null_flag.inc}
              end;
            end; // k <= 0
            // if k >= ExtentPAgeCount-1 then
            // modified in v.4.40 by Leo Martin
            // the extent is 100% full - mark it as uniform to prevent searching inside it
            // k - was not incremented for using found page, so -1
            if (k >= (ExtentPageCount - 1)) then
            begin
              CHECK_NULL_FLAG_BitNo := Integer(EmptyExt);
              CHECK_NULL_FLAG_NullFlags := SGAM;
{$I ACR_check_null_flag.inc}
              if (not CHECK_NULL_FLAG_Result) then
              begin
                LPageManager.UpdatePage(FSM_SESSION_ID, SGAMPage,
                  dbstFreeSpaceManager, FHeader.State, False);
                SET_NULL_FLAG_BitNo := Integer(EmptyExt);
                SET_NULL_FLAG_NullFlags := SGAM;
{$I ACR_set_null_flag.inc}
              end;
            end;
            Result := EmptyPage;
            // the empty page is used now, so decrease number of free pages by 1
            if (FHeader.FreePageCount > 0) then
              Dec(FHeader.FreePageCount)
            else
              FHeader.FreePageCount := 0;
            break;
          end; // Mark empty page as not empty and write PFS, GAM and SGAM pages to file
        end
        else
        begin
          // mixed extent was not found in current SGAM - should never happens
          if (CurGAM = GAMCount - 1) then
          begin
            // extend file
            Result := AppendNewPage;
            break;
          end
          else
            // search in next GAM/SGAM page
            Inc(CurGAM);
        end;
        PutPages;
      until (False); // scan FSM pages to find empty pages
      PutPages;
{$IFDEF DEBUG_TACRDatabaseFreeSpaceManager_GetPage}
  finally
    aaStopTime(time1);
  end;
{$ENDIF}
end; // InternalGetPage

//------------------------------------------------------------------------------
// internal free page - mark the page as empty
//------------------------------------------------------------------------------
procedure TACRDatabaseFreeSpaceManager.InternalFreePage(PageNo: TACRPageNo);
var
  PFSPageNo, ExtNo, GAMPageNo, StartPage, EndPage, PFSBitNo, GAMBitNo, i,
    k: TACRPageNo;
  bCheckShrinking: Boolean;
{$I ACR_check_null_flag_var.inc}
{$I ACR_set_null_flag_var.inc}
begin
  if (IsFSMPage(PageNo)) then
    raise EACRException.Create(11818, ErrorLInvalidPageNoSystem,
      [PageNo, FHeader.TotalPageCount, PagePerExt, PagePerPFSPage]);
{$IFDEF DEBUG_TACRDatabaseFreeSpaceManager_FreePage}
  aaIncCounter(counter2);
  aaStartTime(time2);
  try
{$ENDIF}
    if ((PageNo < 0) or (PageNo >= FHeader.TotalPageCount)) then
      raise EACRException.Create(11816, ErrorLInvalidPageNoTotal,
        [PageNo, FHeader.TotalPageCount]);
    FindPFSPage(PageNo, PFSPageNo, PFSBitNo);
    LoadPage(PFSPageNo, fsmPFS, True, True);
    CHECK_NULL_FLAG_BitNo := Integer(PFSBitNo);
    CHECK_NULL_FLAG_NullFlags := PFS;
{$I ACR_check_null_flag.inc}
    if (CHECK_NULL_FLAG_Result) then
    begin
      bCheckShrinking := False;
      // mark page empty in PFS
      SET_NULL_FLAG_ToSet := False;
      SET_NULL_FLAG_BitNo := Integer(PFSBitNo);
      SET_NULL_FLAG_NullFlags := PFS;
{$I ACR_set_null_flag.inc}
      CHECK_NULL_FLAG_BitNo := PFSBitNo + 1;
      CHECK_NULL_FLAG_NullFlags := PFS;
      // check if next page is empty too
      if (CHECK_NULL_FLAG_BitNo < PagePerPFSPage) then
      begin
{$I ACR_check_null_flag.inc}
        if (not CHECK_NULL_FLAG_Result) then
          bCheckShrinking := True;
      end;
      // update SGAM/GAM - check if the current extent is free
      ExtNo := PageNo div ExtentPageCount;
      StartPage := ExtNo * ExtentPageCount - PFSPageNo;
      EndPage := StartPage + ExtentPageCount - 1;
      if (StartPage < 0) or (StartPage >= PagePerPFSPage) then
        raise EACRException.Create(50006, ErrorFInvalidBitNo,
          [StartPage, LPageManager.PageDataSize]);
      if (EndPage < 0) or (EndPage >= PagePerPFSPage) then
        raise EACRException.Create(50007, ErrorFInvalidBitNo,
          [EndPage, LPageManager.PageDataSize]);
      k := 0;
      for CHECK_NULL_FLAG_BitNo := StartPage to EndPage do
      begin
{$I ACR_check_null_flag.inc}
        if (CHECK_NULL_FLAG_Result) then
          Inc(k);
      end;
      // Set bit 0 in GAM - free extent
      if (k = 0) then
      begin
        FindGAMPage(PageNo, GAMPageNo, GAMBitNo);
        if (GAMBitNo < 0) or (GAMBitNo >= PagePerPFSPage) then
          raise EACRException.Create(11829, ErrorFInvalidBitNo,
            [GAMBitNo, LPageManager.PageDataSize]);
        LoadPage(GAMPageNo, fsmGAM, True, True);
        SET_NULL_FLAG_ToSet := False;
        SET_NULL_FLAG_BitNo := Integer(GAMBitNo);
        SET_NULL_FLAG_NullFlags := GAM;
{$I ACR_set_null_flag.inc}
      end;
      // Set bit 0 in SGAM - mixed extent
      if (k = (ExtentPageCount - 1)) then
      begin
        FindGAMPage(PageNo, GAMPageNo, GAMBitNo);
        // SGAM
        Inc(GAMPageNo);
        LoadPage(GAMPageNo, fsmSGAM, True, True);
        if (GAMBitNo < 0) or (GAMBitNo >= PagePerPFSPage) then
          raise EACRException.Create(11830, ErrorFInvalidBitNo,
            [GAMBitNo, LPageManager.PageDataSize]);
        SET_NULL_FLAG_ToSet := False;
        SET_NULL_FLAG_BitNo := Integer(GAMBitNo);
        SET_NULL_FLAG_NullFlags := SGAM;
{$I ACR_set_null_flag.inc}
      end;
      PutPages;
      Inc(FHeader.FreePageCount);
      if ((PageNo = TACRPageNo(FHeader.TotalPageCount - 1)) or bCheckShrinking)
        then
        CheckShrinking;
    end
    else
    begin
      // page already deleted
      raise EACRException.Create(11817, ErrorLPageIsAlreadDeleted, [PageNo]);
    end;
{$IFDEF DEBUG_TACRDatabaseFreeSpaceManager_FreePage}
  finally
    aaStopTime(time2);
  end;
{$ENDIF}
end; // InternalFreePage

//------------------------------------------------------------------------------
// get multiple pages (optionally in consecutive order)
//------------------------------------------------------------------------------
procedure TACRDatabaseFreeSpaceManager.InternalGetPages(
  // place page numbers of new allocated pages at the end of the array
  Pages: TACRPageArray;
  // how much pages to add
  const NumPagesToAdd: Cardinal;
  // pages must be in consecutive order (n,n+1,n+2...)
  const ConsecutiveOrder: Boolean);
var
  i: Cardinal;
  PageNo: TACRPageNo;
begin
  { TODO -oLeo : implement it correctly }
  i := 0;
  while (i < NumPagesToAdd) do
  begin
    if (ConsecutiveOrder) then
      PageNo := AppendNewPage
    else
      PageNo := InternalGetPage;
    Pages.Insert(PageNo);
    Inc(i);
  end;
  PutPages;
end; // InternalGetPages

//------------------------------------------------------------------------------
// remove all pages in the array by single operation
//------------------------------------------------------------------------------
procedure TACRDatabaseFreeSpaceManager.InternalFreePages(Pages: TACRPageArray;
  NumPagesFromEnd: Cardinal);
var
  i: Integer;
  n: Cardinal;
  PageNo: TACRPageNo;
begin
  { TODO -oLeo : implement it correctly }
  i := Pages.Count - 1;
  n := 0;
  while ((i >= 0) and ((NumPagesFromEnd = 0) or (n < NumPagesFromEnd))) do
  begin
    PageNo := Pages.Items[i];
    InternalFreePage(PageNo);
    Dec(i);
    Inc(n);
  end;
  PutPages;
end; // InternalFreePages

//------------------------------------------------------------------------------
// Get page
//------------------------------------------------------------------------------
function TACRDatabaseFreeSpaceManager.GetPage: TACRPageNo;
begin
{$IFDEF DEBUG_TRACE_FreeSpaceManager_GetPage}
  aaWriteToLog('> TACRDatabaseFreeSpaceManager.GetPage' + #13#10 +
      'PFSPage = ' + IntToHex(Integer(PFSPage),
      8) + #13#10 + 'GAMPage = ' + IntToHex(Integer(GAMPage),
      8) + #13#10 + 'SGAMPage = ' + IntToHex(Integer(SGAMPage), 8));
  try
{$ENDIF}
    if (not LPageManager.LockFreeSpaceManager(True)) then
      raise EACRException.Create(11808, ErrorLCannotLockFreeSpaceManager,
        [LPageManager.DatabaseFileName]);
    try
      if (PFSPage <> nil) then
        raise EACRException.Create(11813, ErrorLFSMPageIsNotFree);
      if (GAMPage <> nil) then
        raise EACRException.Create(11814, ErrorLFSMPageIsNotFree);
      if (SGAMPage <> nil) then
        raise EACRException.Create(11815, ErrorLFSMPageIsNotFree);
      try
        Result := InternalGetPage;
        Inc(FHeader.State);
        LPageManager.ApplyChanges(FHeader.State);
        LPageManager.SaveFSMHeader(FHeader);
      except
        try
          LPageManager.LoadFSMHeader(FHeader);
          PutPages;
          LPageManager.CancelChanges;
        except
        end;
        // re-raise exception
        raise ;
      end;
    finally
      if (not LPageManager.UnlockFreeSpaceManager) then
        raise EACRException.Create(11707, ErrorLCannotUnlockFreeSpaceManager,
          [LPageManager.DatabaseFileName]);
    end;
{$IFDEF DEBUG_TRACE_FreeSpaceManager_GetPage}
    aaWriteToLog('< TACRDatabaseFreeSpaceManager.GetPage' + #13#10 +
        'PFSPage = ' + IntToHex(Integer(PFSPage),
        8) + #13#10 + 'GAMPage = ' + IntToHex(Integer(GAMPage),
        8) + #13#10 + 'SGAMPage = ' + IntToHex(Integer(SGAMPage), 8));
  except
    on e: Exception do
    begin
      aaWriteToLog('Error in TACRDatabaseFreeSpaceManager.GetPage' + #13#10 +
          'PFSPage = ' + IntToHex(Integer(PFSPage),
          8) + #13#10 + 'GAMPage = ' + IntToHex(Integer(GAMPage),
          8) + #13#10 + 'SGAMPage = ' + IntToHex(Integer(SGAMPage),
          8) + #13#10 + e.Message);
      raise ;
    end;
  end;
{$ENDIF}
end; // GetPage

//------------------------------------------------------------------------------
// Free page
//------------------------------------------------------------------------------
procedure TACRDatabaseFreeSpaceManager.FreePage(PageNo: TACRPageNo);
begin
  if (not LPageManager.LockFreeSpaceManager(True)) then
    raise EACRException.Create(11708, ErrorLCannotLockFreeSpaceManager,
      [LPageManager.DatabaseFileName]);
  try
    if (PFSPage <> nil) then
      raise EACRException.Create(11819, ErrorLFSMPageIsNotFree);
    if (GAMPage <> nil) then
      raise EACRException.Create(11820, ErrorLFSMPageIsNotFree);
    if (SGAMPage <> nil) then
      raise EACRException.Create(11821, ErrorLFSMPageIsNotFree);
    try
      InternalFreePage(PageNo);
      Inc(FHeader.State);
      LPageManager.ApplyChanges(FHeader.State);
      LPageManager.SaveFSMHeader(FHeader);
    except
      try
        PutPages;
        LPageManager.CancelChanges;
        LPageManager.LoadFSMHeader(FHeader);
      except
      end;
      // re-raise exception
      raise ;
    end;
  finally
    if (not LPageManager.UnlockFreeSpaceManager) then
      raise EACRException.Create(11709, ErrorLCannotUnlockFreeSpaceManager,
        [LPageManager.DatabaseFileName]);
  end;
end; // FreePage

//------------------------------------------------------------------------------
// add multiple pages
//------------------------------------------------------------------------------
procedure TACRDatabaseFreeSpaceManager.GetPages(
  // place page numbers of new allocated pages at the end of the array
  Pages: TACRPageArray;
  // how much pages to add
  const NumPagesToAdd: Cardinal;
  // pages must be in consecutive order (n,n+1,n+2...)
  const ConsecutiveOrder: Boolean);
begin
{$IFDEF DEBUG_TRACE_FreeSpaceManager_GetPages}
  aaWriteToLog('> TACRDatabaseFreeSpaceManager.GetPages' + #13#10 +
      'PFSPage = ' + IntToHex(Integer(PFSPage),
      8) + #13#10 + 'GAMPage = ' + IntToHex(Integer(GAMPage),
      8) + #13#10 + 'SGAMPage = ' + IntToHex(Integer(SGAMPage), 8));
  try
{$ENDIF}
    if (not LPageManager.LockFreeSpaceManager(True)) then
      raise EACRException.Create(11839, ErrorLCannotLockFreeSpaceManager,
        [LPageManager.DatabaseFileName]);
    try
      if (PFSPage <> nil) then
        raise EACRException.Create(11836, ErrorLFSMPageIsNotFree);
      if (GAMPage <> nil) then
        raise EACRException.Create(11837, ErrorLFSMPageIsNotFree);
      if (SGAMPage <> nil) then
        raise EACRException.Create(11838, ErrorLFSMPageIsNotFree);
      try
        InternalGetPages(Pages, NumPagesToAdd, ConsecutiveOrder);
        Inc(FHeader.State);
        LPageManager.ApplyChanges(FHeader.State);
        LPageManager.SaveFSMHeader(FHeader);
      except
        try
          PutPages;
          LPageManager.CancelChanges;
          LPageManager.LoadFSMHeader(FHeader);
        except
        end;
        // re-raise exception
        raise ;
      end;
    finally
      if (not LPageManager.UnlockFreeSpaceManager) then
        raise EACRException.Create(11840, ErrorLCannotUnlockFreeSpaceManager,
          [LPageManager.DatabaseFileName]);
    end;
{$IFDEF DEBUG_TRACE_FreeSpaceManager_GetPages}
    aaWriteToLog('< TACRDatabaseFreeSpaceManager.GetPages' + #13#10 +
        'PFSPage = ' + IntToHex(Integer(PFSPage),
        8) + #13#10 + 'GAMPage = ' + IntToHex(Integer(GAMPage),
        8) + #13#10 + 'SGAMPage = ' + IntToHex(Integer(SGAMPage), 8));
  except
    on e: Exception do
    begin
      aaWriteToLog('Error in TACRDatabaseFreeSpaceManager.GetPages' + #13#10 +
          'PFSPage = ' + IntToHex(Integer(PFSPage),
          8) + #13#10 + 'GAMPage = ' + IntToHex(Integer(GAMPage),
          8) + #13#10 + 'SGAMPage = ' + IntToHex(Integer(SGAMPage),
          8) + #13#10 + e.Message);
      raise ;
    end;
  end;
{$ENDIF}
end; // GetPages

//------------------------------------------------------------------------------
// remove all pages in the array by single operation
//------------------------------------------------------------------------------
procedure TACRDatabaseFreeSpaceManager.FreePages(Pages: TACRPageArray;
  NumPagesFromEnd: Cardinal);
begin
  if (Pages = nil) then
    Exit;
  if (Pages.Count <= 0) then
    Exit;
  if (not LPageManager.LockFreeSpaceManager(True)) then
    raise EACRException.Create(11844, ErrorLCannotLockFreeSpaceManager,
      [LPageManager.DatabaseFileName]);
  try
    if (PFSPage <> nil) then
      raise EACRException.Create(11841, ErrorLFSMPageIsNotFree);
    if (GAMPage <> nil) then
      raise EACRException.Create(11842, ErrorLFSMPageIsNotFree);
    if (SGAMPage <> nil) then
      raise EACRException.Create(11843, ErrorLFSMPageIsNotFree);
    try
      InternalFreePages(Pages, NumPagesFromEnd);
      Inc(FHeader.State);
      LPageManager.ApplyChanges(FHeader.State);
      LPageManager.SaveFSMHeader(FHeader);
    except
      try
        PutPages;
        LPageManager.CancelChanges;
        LPageManager.LoadFSMHeader(FHeader);
      except
      end;
      // re-raise exception
      raise ;
    end;
  finally
    if (not LPageManager.UnlockFreeSpaceManager) then
      raise EACRException.Create(11845, ErrorLCannotUnlockFreeSpaceManager,
        [LPageManager.DatabaseFileName]);
  end;
end; // FreePages

///////////////////////////////////////////////////////////////////////////////
//
// TACRDiskPageManager
//
///////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// init DBHeader
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.InitDBHeader;
begin
  // for create database file
  FDBHeader.Signature := ACRDiskSignature;
  FDBHeader.Version := ACRVersion;
  FDBHeader.CryptoHeader.CryptoAlgorithm := ACR_Cipher_None;
  FDBHeader.HeaderSize := SizeOf(FDBHeader);
  FDBHeader.ReservedSize := ACRDefaultDBHeaderReserved;
  FDBHeader.FSMHeaderSize := SizeOf(TACRFSMHeader);
  FDBHeader.TLHeaderSize := SizeOf(TACRTLHeader);
  FDBHeader.LockedBytesCount := ACRDatabaseFileLockedBytesCount;
  FDBHeader.MaxSessionCount := 1;
  FOffsetToDBHeader := 0;
  FOffsetToFSMHeader := FOffsetToDBHeader + FDBHeader.HeaderSize;
  FOffsetToTLHeader := FOffsetToFSMHeader + FDBHeader.FSMHeaderSize;
  FOffsetToSFMHeader := FOffsetToTLHeader + FDBHeader.TLHeaderSize;
  FOffsetToLockedBytes := FOffsetToSFMHeader + SizeOf(TACRSFMHeader);
  FOffsetToFirstPage := FOffsetToLockedBytes + FDBHeader.ReservedSize +
    ACRDatabaseFileLockedBytesCount;
end; // InitDBHeader

//------------------------------------------------------------------------------
// load DBHeader
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.LoadDBHeader;
var
  Position: Int64;
begin
  if (not FDatabaseFile.IsOpened) then
    raise EACRException.Create(10459, ErrorLDatabaseFileIsNotOpened);
  FDatabaseFile.ReadBuffer(FDBHeader, SizeOf(FDBHeader), FOffsetToDBHeader,
    10464);
end; // LoadDBHeader

//------------------------------------------------------------------------------
// save DBHeader
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.SaveDBHeader;
var
  Position: Int64;
begin
  // version 5 can write database header only on create
  if ((FReadOnly and (not FExclusive)) or (not FDatabaseFile.IsOpened)) then
    Exit;
  LockDatabaseFile;
  try
    FDatabaseFile.WriteBuffer(FDBHeader, SizeOf(FDBHeader), FOffsetToDBHeader,
      10462);
  finally
    UnlockDatabaseFile;
  end;
end; // SaveDBHeader

//------------------------------------------------------------------------------
// load FreeSpaceManager header
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.LoadFSMHeader(var FSMHeader: TACRFSMHeader);
begin
  LockDatabaseFile;
  try
    FDatabaseFile.ReadBuffer(FSMHeader, SizeOf(FSMHeader), FOffsetToFSMHeader,
      11780);
  finally
    UnlockDatabaseFile;
  end;
end; // LoadFSMHeader

//------------------------------------------------------------------------------
// save FreeSpaceManager header
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.SaveFSMHeader(var FSMHeader: TACRFSMHeader);
begin
  LockDatabaseFile;
  try
    FDatabaseFile.WriteBuffer(FSMHeader, SizeOf(FSMHeader), FOffsetToFSMHeader,
      11781);
  finally
    UnlockDatabaseFile;
  end;
end; // SaveFSMHeader

//------------------------------------------------------------------------------
// load TableList header
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.LoadTLHeader(var TLHeader: TACRTLHeader);
begin
  LockDatabaseFile;
  try
    FDatabaseFile.ReadBuffer(TLHeader, SizeOf(TLHeader), FOffsetToTLHeader,
      11782);
  finally
    UnlockDatabaseFile;
  end;
end; // LoadTLHeader

//------------------------------------------------------------------------------
// save TableList header
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.SaveTLHeader(var TLHeader: TACRTLHeader);
begin
  LockDatabaseFile;
  try
    FDatabaseFile.WriteBuffer(TLHeader, SizeOf(TLHeader), FOffsetToTLHeader,
      11783);
  finally
    UnlockDatabaseFile;
  end;
end; // SaveTLHeader

//------------------------------------------------------------------------------
// LoadSFMHeader
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.LoadSFMHeader(var SFMHeader: TACRSFMHeader);
begin
  if (FOffsetToSFMHeader > 0) then
  begin
    LockDatabaseFile;
    try
      FDatabaseFile.ReadBuffer(SFMHeader, SizeOf(SFMHeader),
        FOffsetToSFMHeader, 12173);
    finally
      UnlockDatabaseFile;
    end;
  end;
end; // LoadSFMHeader

//------------------------------------------------------------------------------
// SaveSFMHeader
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.SaveSFMHeader(var SFMHeader: TACRSFMHeader);
begin
  if (FOffsetToSFMHeader > 0) then
  begin
    LockDatabaseFile;
    try
      FDatabaseFile.WriteBuffer(SFMHeader, SizeOf(SFMHeader),
        FOffsetToSFMHeader, 12174);
    finally
      UnlockDatabaseFile;
    end;
  end;
end; // SaveSFMHeader

//------------------------------------------------------------------------------
// return true if database file is opened
//------------------------------------------------------------------------------
function TACRDiskPageManager.GetIsOpened: Boolean;
begin
  Result := FDatabaseFile.IsOpened;
end; // GetIsOpened

//------------------------------------------------------------------------------
// return offset to beginning of the page in the file
//------------------------------------------------------------------------------
function TACRDiskPageManager.GetPageOffset(PageNo: TACRPageNo): Int64;
begin
  if (PageNo = INVALID_PAGE_NO) then
    raise EACRException.Create(10471, ErrorLInvalidPageNo, [PageNo]);
  Result := Int64(FOffsetToFirstPage) + Int64(PageNo) * Int64(FPageSize);
end; // GetPageOffset

//------------------------------------------------------------------------------
// return database file name
//------------------------------------------------------------------------------
function TACRDiskPageManager.GetDatabaseFileName: WideString;
begin
  Result := WideString(FDatabaseFile.FileName) + FDatabaseFile.FileNameUnicode;
end; // GetDatabaseFileName

//------------------------------------------------------------------------------
// extend file by number of pages specified by PageCount
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.CheckFileSize;
var
  NewSize: Int64;
begin
  if (FDatabaseFile.IsOpened and (FOffsetToDBHeader >= 0)) then
    if (FDatabaseFile.AccessMode <> amReadOnly) then
    begin
      LockDatabaseFile;
      try
        NewSize := FOffsetToFirstPage + Int64
          (FDatabaseFreeSpaceManager.FHeader.TotalPageCount) * Int64
          (FPageSize);
        if (FDatabaseFile.Size <> NewSize) then
          FDatabaseFile.Size := NewSize;
      finally
        UnlockDatabaseFile;
      end;
    end;
end; // CheckFileSize

//------------------------------------------------------------------------------
// return page count
//------------------------------------------------------------------------------
function TACRDiskPageManager.GetPageCount: TACRPageNo;
begin
  Result := GetTotalPageCount;
end; // GetPageCount

//------------------------------------------------------------------------------
// lock database file
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.LockDatabaseFile;
begin
  FDatabaseFileThreadSync.WaitAndLockForWrite
end; // LockDatabaseFile

//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.UnlockDatabaseFile;
begin
  FDatabaseFileThreadSync.Unlock;
end; // UnlockDatabaseFile

//------------------------------------------------------------------------------
// read page region (offset is relative to the beginning of page)
// used for reading table states - directly, without encryption, without page header
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.ReadPageRegion(var Buffer; PageNo: TACRPageNo;
  Offset, Count: Integer; DoNotEncrypt: Boolean);
begin
  if (Offset + Count > FPageSize) then
    raise EACRException.Create(10476, ErrorLInvalidPageOffset,
      [Offset + Count, FPageSize]);
  LockDatabaseFile;
  try
    if ((CryptoInfo.CryptoAlgorithm <> ACR_Cipher_None) and (not DoNotEncrypt))
      then
    begin
      FDatabaseFile.ReadBuffer(PAnsiChar(Buffer), Count,
        GetPageOffset(PageNo) + Int64(Offset), 10724);
      ACRDecryptBuffer(CryptoInfo, PAnsiChar(@Buffer), Count);
    end
    else
      FDatabaseFile.ReadBuffer(PAnsiChar(Buffer), Count,
        GetPageOffset(PageNo) + Int64(Offset), 10474);
  finally
    UnlockDatabaseFile;
  end;
end; // ReadPageRegion

//------------------------------------------------------------------------------
// write page region (offset is relative to the beginning of page)
// used for writing table states - directly, without encryption, without page header
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.WritePageRegion(const Buffer; PageNo: TACRPageNo;
  Offset, Count: Integer; DoNotEncrypt: Boolean);
var
  NewBuffer: PAnsiChar;
begin
  if (Offset + Count > FPageSize) then
    raise EACRException.Create(10477, ErrorLInvalidPageOffset,
      [Offset + Count, FPageSize]);
  LockDatabaseFile;
  try
    if ((CryptoInfo.CryptoAlgorithm <> ACR_Cipher_None) and (not DoNotEncrypt))
      then
    begin
      NewBuffer := MemoryManager.GetMem(Count);
      try
        Move(PAnsiChar(@Buffer)^, NewBuffer^, Count);
        ACREncryptBuffer(CryptoInfo, NewBuffer, Count);
        FDatabaseFile.WriteBuffer(NewBuffer^, Count,
          GetPageOffset(PageNo) + Int64(Offset), 10725);
      finally
        MemoryManager.FreeAndNilMem(NewBuffer);
      end;
    end
    else
      FDatabaseFile.WriteBuffer(PAnsiChar(Buffer), Count,
        GetPageOffset(PageNo) + Int64(Offset), 10475);
  finally
    UnlockDatabaseFile;
  end;
end; // WritePageRegion

//------------------------------------------------------------------------------
// Read Buffer
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.DirectReadBuffer(var Buffer; const Count: Int64;
  const Pos: Int64; ErrorCode: Integer);
begin
  LockDatabaseFile;
  try
    FDatabaseFile.ReadBuffer(Buffer, Count, Pos, ErrorCode, True);
  finally
    UnlockDatabaseFile;
  end;
end; // DirectReadBuffer

//------------------------------------------------------------------------------
// Write Buffer
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.DirectWriteBuffer(const Buffer;
  const Count: Int64; const Pos: Int64; ErrorCode: Integer);
begin
  LockDatabaseFile;
  try
    FDatabaseFile.WriteBuffer(Buffer, Count, Pos, ErrorCode, True);
  finally
    UnlockDatabaseFile;
  end;
end; // DirectWriteBuffer

//------------------------------------------------------------------------------
// return true if region is locked
//------------------------------------------------------------------------------
function TACRDiskPageManager.DirectIsRegionLocked(Offset: Int64;
  Count: Integer): Boolean;
begin
  Result := FDatabaseFile.IsRegionLocked(Offset, Count);
end; // DirectIsRegionLocked

//------------------------------------------------------------------------------
// direct add page
//------------------------------------------------------------------------------
function TACRDiskPageManager.DirectAddPage: TACRPageNo;
begin
  Result := FDatabaseFreeSpaceManager.GetPage;
  if ((Result = INVALID_PAGE_NO) or
      (Result >= FDatabaseFreeSpaceManager.Header.TotalPageCount)) then
    raise EACRException.Create(10707, ErrorLInvalidPageNo, [Result]);
end; // DirectAddPage

//------------------------------------------------------------------------------
// add multiple pages
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.DirectAddPages(
  // place page numbers of new allocated pages at the end of the array
  Pages: TACRPageArray;
  // how much pages to add
  const NumPagesToAdd: Cardinal;
  // pages must be in consecutive order (n,n+1,n+2...)
  const ConsecutiveOrder: Boolean);
begin
  FDatabaseFreeSpaceManager.GetPages(Pages, NumPagesToAdd, ConsecutiveOrder);
end; // DirectAddPages

//------------------------------------------------------------------------------
// remove all pages in the array by single operation
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.DirectRemovePages(Pages: TACRPageArray;
  NumPagesFromEnd: Cardinal);
begin
  FDatabaseFreeSpaceManager.FreePages(Pages, NumPagesFromEnd);
end; // DirectRemovePages

//------------------------------------------------------------------------------
// internal init page
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.InitPage(aPage: TACRPage);
var
  b: Byte;
begin
  aPage.AllocPageBuffer;
  aPage.OwnBuffer := True;
  if (CryptoInfo.CryptoAlgorithm <> ACR_Cipher_None) then
  begin
{$IFDEF DEBUG_DECRYPTION_TIME}
    aaIncCounter(counter8);
    aaStartTime(time8);
{$ENDIF}
    // fixed in v.5.40 - too slow
    // ACRGenerateRandomBuffer(aPage.PageBuffer,FPageSize);
    b := Byte(Cardinal(Random(MaxInt)) xor aaGetTickCount);
    FillChar(aPage.PageBuffer^, FPageSize, b);
{$IFDEF DEBUG_DECRYPTION_TIME}
    aaStopTime(time8);
{$ENDIF}
  end;
  aPage.PageHeader.Signature := ACRDiskPageSignature;
  aPage.PageHeader.PageType := ACRPageTypeIDEmpty;
  aPage.PageHeader.NextPageNo := INVALID_PAGE_NO;
  aPage.PageHeader.ObjectID := ACRObjectIDUnknown;
end; // InternalInitPage

//------------------------------------------------------------------------------
// internal add page
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.InternalAddPage(aPage: TACRPage);
begin
{$IFDEF DEBUG_TRACE_PAGE_MANAGER}
  aaWriteToLog('0. add page...');
{$ENDIF}
  aPage.PageNo := DirectAddPage;
  InitPage(aPage);
{$IFDEF DEBUG_TRACE_PAGE_MANAGER}
  aaWriteToLog('1. add page ' + IntToStr(aPage.PageNo));
{$ENDIF}
end; // InternalAddPage

//------------------------------------------------------------------------------
// internal remove page
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.InternalRemovePage(PageNo: TACRPageNo);
begin
{$IFDEF DEBUG_TRACE_PAGE_MANAGER}
  aaWriteToLog('0. remove page ' + IntToStr(PageNo));
{$ENDIF}
  FDatabaseFreeSpaceManager.FreePage(PageNo);
{$IFDEF DEBUG_TRACE_PAGE_MANAGER}
  aaWriteToLog('1. remove page ' + IntToStr(PageNo));
{$ENDIF}
end; // InternalRemovePage

//------------------------------------------------------------------------------
// return true if page must not be encrypted even if database is encrypted
//------------------------------------------------------------------------------
function TACRDiskPageManager.IsPageMustNotBeEncrypted(aPage: TACRPage): Boolean;
begin
  // 1 - FreeSpaceManager - for performance reasons
  // 2 - TableLocksFile - for performance reasons
  // 3 - ActiveSessionFile - for performance reasons

  Result := ((aPage.StateType = dbstFreeSpaceManager) or
      (aPage.StateType = dbstTableLockFile));
  if (not Result) then
    if (aPage.PageHeader <> nil) then
      if ((aPage.PageHeader.PageType = ACRPageTypeIDActiveSessionList) or
          (aPage.PageHeader.PageType = ACRPageTypeIDTableLocksFile)) then
        Result := True;
end; // IsPageMustNotBeEncrypted

//------------------------------------------------------------------------------
// read page data
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.InternalReadPage(aPage: TACRPage);
var
  Buffer: PAnsiChar;
begin
{$IFDEF DEBUG_LOCK_TIMES}
  aaIncCounter(counter7);
  aaStartTime(time7);
  try
{$ENDIF}
{$IFDEF DEBUG_DECRYPTION_TIME}
    aaIncCounter(counter3);
    aaStartTime(time3);
{$ENDIF}
    LockDatabaseFile;
    try
      if (aPage.PageBuffer = nil) then
        aPage.AllocPageBuffer;
      if ((CryptoInfo.CryptoAlgorithm <> ACR_Cipher_None) and
          (not IsPageMustNotBeEncrypted(aPage))) then
      begin
        Buffer := MemoryManager.GetMem(PageSize);
        try
          FDatabaseFile.ReadBuffer(Buffer^, PageSize,
            GetPageOffset(aPage.PageNo), 10716);
          ACRDecryptBuffer(CryptoInfo, Buffer, PageSize);
          Move(Buffer^, aPage.PageBuffer^, PageSize);
        finally
          MemoryManager.FreeAndNilMem(Buffer);
        end;
      end
      else
      begin
        FDatabaseFile.ReadBuffer(aPage.PageBuffer^, FPageSize,
          GetPageOffset(aPage.PageNo), 10466);
      end;
{$IFDEF DEBUG_TRACE_PAGE_MANAGER}
      aaWriteToLog('read page ' + IntToStr(aPage.PageNo) + ' type = ' + IntToStr
          (aPage.PageHeader.PageType));
{$ENDIF}
    finally
      UnlockDatabaseFile;
    end;
{$IFDEF DEBUG_DECRYPTION_TIME}
    aaStopTime(time3);
{$ENDIF}
{$IFDEF DEBUG_LOCK_TIMES}
  finally
    aaStopTime(time7);
  end;
{$ENDIF}
end; // InternalReadPage

//------------------------------------------------------------------------------
// write page data
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.InternalWritePage(aPage: TACRPage);
var
  Buffer: PAnsiChar;
begin
{$IFDEF DEBUG_LOCK_TIMES}
  aaIncCounter(counter8);
  aaStartTime(time8);
  try
{$ENDIF}
    if (aPage = nil) then
      raise EACRException.Create(12290, ErrorLNilPointer);
    if (aPage.IsHeaderCorrupted) then
      raise EACRException.Create(12291, ErrorLPageHeaderIsCorrupted,
        [aPage.PageNo, Integer(aPage.StateType), Self.ClassName,
        IntToHex(Integer(Self), 8)]);
    LockDatabaseFile;
    try
      if ((CryptoInfo.CryptoAlgorithm <> ACR_Cipher_None) and
          (not IsPageMustNotBeEncrypted(aPage))) then
      begin
        Buffer := MemoryManager.GetMem(PageSize);
        try
          Move(aPage.PageBuffer^, Buffer^, PageSize);
          ACREncryptBuffer(CryptoInfo, Buffer, PageSize);
          FDatabaseFile.WriteBuffer(Buffer^, PageSize,
            GetPageOffset(aPage.PageNo), 10715);
        finally
          MemoryManager.FreeAndNilMem(Buffer);
        end;
      end
      else
      begin
        FDatabaseFile.WriteBuffer(aPage.PageBuffer^, FPageSize,
          GetPageOffset(aPage.PageNo), 10469);
      end;
{$IFDEF DEBUG_TRACE_PAGE_MANAGER}
      aaWriteToLog('write page ' + IntToStr(aPage.PageNo)
          + ' type = ' + IntToStr(aPage.PageHeader.PageType));
{$ENDIF}
    finally
      UnlockDatabaseFile;
    end;
{$IFDEF DEBUG_LOCK_TIMES}
  finally
    aaStopTime(time8);
  end;
{$ENDIF}
end; // InternalWritePage

//------------------------------------------------------------------------------
// return true if page is system page
//------------------------------------------------------------------------------
function TACRDiskPageManager.IsSystemPage(PageNo: TACRPageNo): Boolean;
begin
  if (FDBHeader.Version >= (ACRStoredFunctionManagerFirstVersion - 0.000000001)) then
   Result := (PageNo <= ACR_MAX_DISK_SYSTEM_PAGE_NO)
  else
   Result := (PageNo <= ACR_MAX_DISK_SYSTEM_PAGE_NO_50);
end; // IsSystemPage

//------------------------------------------------------------------------------
// lock FreeSpaceManager
//------------------------------------------------------------------------------
function TACRDiskPageManager.LockFreeSpaceManager(Exclusive: Boolean): Boolean;
var
  t, m: Cardinal;
begin
  if (not FExclusive) then
  begin
    m := ACRGetMaxWaitTime(FLockParams);
    if (m < ACRSystemWaitTime) then
      m := ACRSystemWaitTime;
    t := aaGetTickCount;
  end;
  Result := True;
  if (not FExclusive) then
  begin
    repeat
      Result := FDatabaseFile.LockByte(FOffsetToLockedBytes +
          OffsetToFreeSpaceManagerLockByte);
    until ((Result) or (ACRGetTickCountDiff(GetTickCount, t) > m));
    if (Result) then
    begin
      FFSMThreadSync.Lock(Exclusive);
      LoadFSMHeader(FDatabaseFreeSpaceManager.FHeader);
    end;
  end
  else
    FFSMThreadSync.Lock(Exclusive);
end; // LockFreeSpaceManager

//------------------------------------------------------------------------------
// unlock Free Space Manager byte
//------------------------------------------------------------------------------
function TACRDiskPageManager.UnlockFreeSpaceManager: Boolean;
begin
  Result := True;
  if (not FExclusive) then
    Result := FDatabaseFile.UnlockByte(FOffsetToLockedBytes +
        OffsetToFreeSpaceManagerLockByte);
  FFSMThreadSync.Unlock;
end; // UnockFreeSpaceManager

//------------------------------------------------------------------------------
// lock Tables byte
//------------------------------------------------------------------------------
function TACRDiskPageManager.InternalLockTableList(Exclusive: Boolean): Boolean;
var
  t, m: Cardinal;
begin
{$IFDEF DEBUG_LOCK_TABLE_LIST}
  aaWriteToLog(
    '> TACRDiskPageManager.InternalLockTableList - locked in FS. Offset = ' +
      IntToStr(FOffsetToLockedBytes + OffsetToTablesLockByte)
      + #13#10 + 'Exclusive = ' + BoolToStr(Exclusive, True));
{$ENDIF}
  if (not FExclusive) then
  begin
    m := ACRGetMaxWaitTime(FLockParams);
    if (m < ACRSystemWaitTime) then
      m := ACRSystemWaitTime;
    t := aaGetTickCount;
  end;
  Result := True;
  if (not FExclusive) then
  begin
    repeat
{$IFDEF DEBUG_LOCK_TABLE_LIST}
      aaWriteToLog(
        '1. TACRDiskPageManager.InternalLockTableList - locked in FS. Offset = '
          + IntToStr(FOffsetToLockedBytes + OffsetToTablesLockByte)
          + #13#10 + 'Exclusive = ' + BoolToStr(Exclusive,
          True) + #13#10 + 'Result = ' + BoolToStr(Result,
          True) + #13#10 + 'm = ' + IntToStr(m) + #13#10 + 't = ' + IntToStr
          (t) + #13#10 + 'ACRGetTickCountDiff(GetTickCount, t) = ' + IntToStr
          (ACRGetTickCountDiff(GetTickCount, t)));
{$ENDIF}
      Result := FDatabaseFile.LockByte
        (FOffsetToLockedBytes + OffsetToTablesLockByte, 1, Exclusive);
{$IFDEF DEBUG_LOCK_TABLE_LIST}
      aaWriteToLog(
        '2. TACRDiskPageManager.InternalLockTableList - locked in FS. Offset = '
          + IntToStr(FOffsetToLockedBytes + OffsetToTablesLockByte)
          + #13#10 + 'Exclusive = ' + BoolToStr(Exclusive,
          True) + #13#10 + 'Result = ' + BoolToStr(Result,
          True) + #13#10 + 'm = ' + IntToStr(m) + #13#10 + 't = ' + IntToStr
          (t) + #13#10 + 'ACRGetTickCountDiff(GetTickCount, t) = ' + IntToStr
          (ACRGetTickCountDiff(GetTickCount, t)));
{$ENDIF}
    until ((Result) or (ACRGetTickCountDiff(GetTickCount, t) > m));
{$IFDEF DEBUG_LOCK_TABLE_LIST}
    if (Result) then
      aaWriteToLog(
        'TACRDiskPageManager.InternalLockTableList - locked in FS. Offset = ' +
          IntToStr(FOffsetToLockedBytes + OffsetToTablesLockByte)
          + #13#10 + 'Exclusive = ' + BoolToStr(Exclusive, True));
{$ENDIF}
    if (Result) then
      FTLThreadSync.Lock(Exclusive);
  end
  else
    FTLThreadSync.Lock(Exclusive);
{$IFDEF DEBUG_LOCK_TABLE_LIST}
  aaWriteToLog(
    '< TACRDiskPageManager.InternalLockTableList - locked in FS. Offset = ' +
      IntToStr(FOffsetToLockedBytes + OffsetToTablesLockByte)
      + #13#10 + 'Exclusive = ' + BoolToStr(Exclusive,
      True) + #13#10 + 'Result = ' + BoolToStr(Result,
      True) + #13#10 + 'm = ' + IntToStr(m) + #13#10 + 't = ' + IntToStr
      (t) + #13#10 + 'ACRGetTickCountDiff(GetTickCount, t) = ' + IntToStr
      (ACRGetTickCountDiff(GetTickCount, t)));
{$ENDIF}
end; // InternalLockTableList

//------------------------------------------------------------------------------
// unlock Tables byte
//------------------------------------------------------------------------------
function TACRDiskPageManager.InternalUnlockTableList: Boolean;
begin
  Result := True;
  if (not FExclusive) then
    Result := FDatabaseFile.UnlockByte
      (FOffsetToLockedBytes + OffsetToTablesLockByte, 1, Exclusive);
  FTLThreadSync.Unlock;
{$IFDEF DEBUG_LOCK_TABLE_LIST}
  aaWriteToLog(
    'TACRDiskPageManager.InternalUnlockTableList - unlocked in FS. Offset = ' +
      IntToStr(FOffsetToLockedBytes + OffsetToTablesLockByte)
      + #13#10 + 'Exclusive = ' + BoolToStr(Exclusive,
      True) + #13#10 + 'Result = ' + BoolToStr(Result, True));
{$ENDIF}
end; // InternalUnlockTableList

//------------------------------------------------------------------------------
// lock Stored Function Manager
//------------------------------------------------------------------------------
function TACRDiskPageManager.LockStoredFunctionManager(Exclusive: Boolean)
  : Boolean;
var
  t, m: Cardinal;
begin
  Result := True;
  if (not FExclusive) then
  begin
    m := ACRGetMaxWaitTime(FLockParams);
    if (m < ACRSystemWaitTime) then
      m := ACRSystemWaitTime;
    t := aaGetTickCount;
    repeat
      Result := FDatabaseFile.LockByte(FOffsetToLockedBytes +
          OffsetToStoredFunctionManagerLockByte);
    until ((Result) or (ACRGetTickCountDiff(GetTickCount, t) > m));
  end;
end; // LockStoredFunctionManager

//------------------------------------------------------------------------------
// unlock Stored Function Manager
//------------------------------------------------------------------------------
function TACRDiskPageManager.UnlockStoredFunctionManager: Boolean;
begin
  Result := True;
  if (not FExclusive) then
    Result := FDatabaseFile.UnlockByte(FOffsetToLockedBytes +
        OffsetToStoredFunctionManagerLockByte);
end; // UnlockStoredFunctionManager

//------------------------------------------------------------------------------
// Lock Byte (return TRUE if success)
//------------------------------------------------------------------------------
function TACRDiskPageManager.LockPageByte(PageNo: TACRPageNo; Offset: Word;
  Exclusive: Boolean): Boolean;
begin
  Result := FDatabaseFile.LockByte(GetPageOffset(PageNo) + Int64(Offset), 1,
    Exclusive);
end; // LockPageByte

//------------------------------------------------------------------------------
// Unlock Byte
//------------------------------------------------------------------------------
function TACRDiskPageManager.UnlockPageByte(PageNo: TACRPageNo; Offset: Word;
  Exclusive: Boolean): Boolean;
begin
  Result := FDatabaseFile.UnlockByte(GetPageOffset(PageNo) + Int64(Offset), 1,
    Exclusive);
end; // UnlockPageByte

//------------------------------------------------------------------------------
// return True if byte is locked
//------------------------------------------------------------------------------
function TACRDiskPageManager.IsPageByteLocked(PageNo: TACRPageNo;
  Offset: Word): Boolean;
begin
  Result := FDatabaseFile.IsByteLocked(GetPageOffset(PageNo) + Int64(Offset));
end; // IsPageByteLocked

//------------------------------------------------------------------------------
// return True if any byte of region is locked
//------------------------------------------------------------------------------
function TACRDiskPageManager.IsPageRegionLocked(PageNo: TACRPageNo;
  Offset: Word; Count: Word): Boolean;
begin
  Result := FDatabaseFile.IsRegionLocked(GetPageOffset(PageNo) + Int64(Offset),
    Count);
end; // IsPageRegionLocked

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRDiskPageManager.Create(aLockParams: TACRLockParams);
begin
  inherited Create;
  FDiskPageManager := True;
  FDatabaseFreeSpaceManager := nil;
  FDatabaseFile := TACRDatabaseFile.Create;
  LockParams := aLockParams;
  // FreeSpaceManager synchronization in exclusive multi-threaded mode
  FFSMThreadSync := TACRReadWriteThreadSyncByCriticalSections.Create(False,
    Self, 'FreeSpaceManager');
  // FFSMThreadSync.WriteToLog := True;
  // TableList synchronization in exclusive multi-threaded mode
  FTLThreadSync := TACRReadWriteThreadSyncByCriticalSections.Create(False,
    Self, 'TablesList');
  FDatabaseFileThreadSync :=
    TACRReadWriteThreadSyncBySingleCriticalSection.Create;
{$IFDEF DEBUG_LOG}
  FTempPage := nil;
{$ENDIF}
end; // Create

//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TACRDiskPageManager.Destroy;
begin
{$IFDEF DEBUG_LOG}
  if (FTempPage <> nil) then
    FreeAndNil(FTempPage);
{$ENDIF}
  CloseDatabase;
  FreeAndNil(FDatabaseFile);
  if (Length(FCryptoInfo.Password) > 0) then
    FillChar(FCryptoInfo.Password[1], Length(FCryptoInfo.Password), $00);
  FCryptoInfo.Password := '';
  FillChar(FCryptoInfo, SizeOf(FCryptoInfo), $00);
  FDatabaseFileThreadSync.Free;
  FFSMThreadSync.Free;
  FTLThreadSync.Free;
  inherited;
end; // Destroy

//------------------------------------------------------------------------------
// CreateAndOpenDatabase
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.CreateAndOpenDatabase
  (DatabaseFileName: AnsiString; DatabaseFileNameUnicode: WideString;
  MaxSessionCount: Cardinal; PageSize: Word; ExtentPageCount: Word;
  UnicodeNames: ByteBool);
begin
  if (FDatabaseFile.IsOpened) then
    raise EACRException.Create(10461, ErrorLDatabaseFileIsInUse,
      [FDatabaseFile.FileName]);
  FDatabaseFile.CreateAndOpenFile(DatabaseFileName, DatabaseFileNameUnicode);
  try
    InitDBHeader;
    FDBHeader.FUnicodeNames := UnicodeNames;
    FDBHeader.MaxSessionCount := Word(MaxSessionCount);
    FDBHeader.PageSize := PageSize;
    FDBHeader.ExtentPageCount := ExtentPageCount;
    FDBHeader.CryptoHeader := ACRCreateCryptoHeader(FCryptoInfo);
    FPageSize := FDBHeader.PageSize;
    FPageDataSize := FDBHeader.PageSize - SizeOf(TACRDiskPageHeader);
    FPageHeaderSize := SizeOf(TACRDiskPageHeader);
    SaveDBHeader;
    FDatabaseFreeSpaceManager := TACRDatabaseFreeSpaceManager.Create(Self,
      LockParams);
    FDatabaseFreeSpaceManager.CreateFreeSpaceManager;
    FReadOnly := False;
    FExclusive := True;
  except
    FDatabaseFile.DeleteFile();
    raise ;
  end;
end; // CreateAndOpenDatabase

//------------------------------------------------------------------------------
// Open database
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.OpenDatabase(DatabaseFileName: AnsiString;
  DatabaseFileNameUnicode: WideString; var aReadOnly: Boolean;
  aExclusive: Boolean = False; DoNotCheckPassword: Boolean = False);
var
  AccessMode: TACRAccessMode;
  ShareMode: TACRShareMode;
begin
  FExclusive := aExclusive;
  FReadOnly := aReadOnly;
  if (FDatabaseFile.IsOpened) then
    raise EACRException.Create(10462, ErrorLDatabaseFileIsInUse,
      [FDatabaseFile.FileName]);
  if (FReadOnly) then
    AccessMode := amReadOnly
  else
    AccessMode := amReadWrite;
  if (FExclusive) then
    ShareMode := smExclusive
  else
    ShareMode := smShared;
  FDatabaseFile.OpenFile(DatabaseFileName, DatabaseFileNameUnicode, AccessMode,
    ShareMode, False);
  aReadOnly := (AccessMode = amReadOnly);
  FReadOnly := aReadOnly;
  FOffsetToDBHeader := GetOffsetToDBHeader;
  if (FOffsetToDBHeader < 0) then
    raise EACRException.Create(11289, ErrorLInvalidDatabaseFile,
      [DatabaseFileName]);
  LoadDBHeader;
  FOffsetToFSMHeader := FOffsetToDBHeader + FDBHeader.HeaderSize;
  FOffsetToTLHeader := FOffsetToFSMHeader + FDBHeader.FSMHeaderSize;
  if (FDBHeader.Version >= (ACRStoredFunctionManagerFirstVersion - 0.000000001)) then
  begin
    // stored function manager exists
    FOffsetToSFMHeader := FOffsetToTLHeader + FDBHeader.TLHeaderSize;
    FOffsetToLockedBytes := FOffsetToSFMHeader + SizeOf(TACRSFMHeader);
  end
  else
  begin
    // stored function manager exists
    FOffsetToSFMHeader := -1;
    FOffsetToLockedBytes := FOffsetToTLHeader + FDBHeader.TLHeaderSize;
  end;
  FOffsetToFirstPage := FOffsetToLockedBytes + FDBHeader.LockedBytesCount +
    FDBHeader.ReservedSize;
  FPageSize := FDBHeader.PageSize;
  FPageDataSize := FDBHeader.PageSize - SizeOf(TACRDiskPageHeader);
  FPageHeaderSize := SizeOf(TACRDiskPageHeader);
  FCryptoInfo.CryptoAlgorithm := FDBHeader.CryptoHeader.CryptoAlgorithm;
  FCryptoInfo.CryptoMode := FDBHeader.CryptoHeader.CryptoMode;
  if (FDBHeader.Signature <> ACRDiskSignature) then
    raise EACRException.Create(10470, ErrorLInvalidSignature,
      [FDBHeader.Signature, ACRDiskSignature]);
  if ((DBHeader.Version < ACRMinVersion) or (DBHeader.Version > ACRMaxVersion))
    then
    raise EACRException.Create(10637, ErrorLInvalidVersion, [DBHeader.Version,
      ACRVersion]);
  if (not DoNotCheckPassword) then
  begin
    if (not ACRIsKeyValid(FDBHeader.CryptoHeader, FCryptoInfo)) then
      raise EACRException.Create(10712, ErrorLInvalidCryptoKeyInfo,
        [FDatabaseFile.FileName + FDatabaseFile.FileNameUnicode]);
    ACR_ENCRYPTED_DB_USED := (FCryptoInfo.CryptoAlgorithm <> ACR_Cipher_None);
  end;
  FDatabaseFreeSpaceManager := TACRDatabaseFreeSpaceManager.Create(Self,
    LockParams);
  if (FExclusive) then
    LoadFSMHeader(FDatabaseFreeSpaceManager.FHeader);
  if (not LockFreeSpaceManager(True)) then
    raise EACRException.Create(12297, ErrorLCannotLockFreeSpaceManager,
      [FDatabaseFile.FileName]);
  try
    CheckFileSize;
  finally
    UnlockFreeSpaceManager;
  end;
end; // OpenDatabase

//------------------------------------------------------------------------------
// Close database
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.CloseDatabase;
begin
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog('TACRDiskPageManager.CloseDatabase starting ...' +
      ', FDatabaseFile = ' + IntToStr(Integer(FDatabaseFile)));
  if (FDatabaseFile <> nil) then
    aaWriteToLog('TACRDiskPageManager.CloseDatabase starting ...' +
        ', FDatabaseFile.IsOpened = ' + BoolToStr(FDatabaseFile.IsOpened,
        True));
{$ENDIF}
  if (FDatabaseFile.IsOpened and (FOffsetToDBHeader >= 0)) then
  begin
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
    aaWriteToLog('TACRDiskPageManager.CloseDatabase flushing buffes...');
{$ENDIF}
    if (not LockFreeSpaceManager(True)) then
      raise EACRException.Create(12298, ErrorLCannotLockFreeSpaceManager,
        [FDatabaseFile.FileName]);
    try
      CheckFileSize;
    finally
      UnlockFreeSpaceManager;
    end;
    try
      // FlushFileBuffers;
    except
    end;
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
    aaWriteToLog('TACRDiskPageManager.CloseDatabase closing database file ...');
{$ENDIF}
    FDatabaseFile.CloseFile;
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
    aaWriteToLog(
      'TACRDiskPageManager.CloseDatabase closing database file ... OK');
{$ENDIF}
  end;
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog(
    'TACRDiskPageManager.CloseDatabase destroy free space manager ...' +
      ', FDatabaseFreeSpaceManager = ' + IntToStr
      (Integer(FDatabaseFreeSpaceManager)));
{$ENDIF}
  if (FDatabaseFreeSpaceManager <> nil) then
    FreeAndNil(FDatabaseFreeSpaceManager);
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog(
    'TACRDiskPageManager.CloseDatabase destroy free space manager ... OK. Finished'
      + ', FDatabaseFreeSpaceManager = ' + IntToStr
      (Integer(FDatabaseFreeSpaceManager)));
{$ENDIF}
end; // CloseDatabase

//------------------------------------------------------------------------------
// flush file buffers
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.FlushFileBuffers;
begin
  if (not FReadOnly) then
    FDatabaseFile.FlushFileBuffers;
end; // FlushFileBuffers

//------------------------------------------------------------------------------
// return offset from beginning of the file to DBHeader's signature, or -1 if no signature inthe file
//------------------------------------------------------------------------------
function TACRDiskPageManager.GetOffsetToDBHeader: Int64;
begin
  Result := FDatabaseFile.GetOffsetToSignature(ACRDiskSignature);
end; // GetOffsetToDBHeader

//------------------------------------------------------------------------------
// return true if this file is an Accuracer Database File
//------------------------------------------------------------------------------
function TACRDiskPageManager.IsAccuracerDatabaseFile
  (DatabaseFileName: AnsiString; DatabaseFileNameUnicode: WideString): Boolean;
var
  bOpened: Boolean;
  AccessMode: TACRAccessMode;
  ShareMode: TACRShareMode;
begin
  bOpened := FDatabaseFile.IsOpened;
  if (bOpened and (FDatabaseFile.FileName <> DatabaseFileName) and
      (FDatabaseFile.FileNameUnicode <> DatabaseFileNameUnicode)) then
    raise EACRException.Create(11296, ErrorLInvalidDatabaseFileName,
      [WideString(DatabaseFileName) + DatabaseFileNameUnicode,
      FDatabaseFile.FileName]);
  if (not bOpened) then
  begin
    Result := ACRFileExists(DatabaseFileName, DatabaseFileNameUnicode);
    if (not Result) then
      Exit;
    AccessMode := amReadWrite;
    ShareMode := smShared;
    try
      FDatabaseFile.OpenFile(DatabaseFileName, DatabaseFileNameUnicode,
        AccessMode, ShareMode, True);
      Result := (GetOffsetToDBHeader >= 0);
      FDatabaseFile.CloseFile;
    except
      Result := False;
      if (FDatabaseFile.IsOpened) then
        try
          FDatabaseFile.CloseFile;
        except
        end;
    end;
  end
  else
    Result := True;
end; // IsAccuracerDatabaseFile

//------------------------------------------------------------------------------
// remove database from exe file
//------------------------------------------------------------------------------
procedure TACRDiskPageManager.RemoveDatabaseFromExe
  (DatabaseFileName: AnsiString; DatabaseFileNameUnicode: WideString);
var
  bOpened: Boolean;
  AccessMode: TACRAccessMode;
  ShareMode: TACRShareMode;

begin
  bOpened := FDatabaseFile.IsOpened;
  if (bOpened) then
    raise EACRException.Create(11832, ErrorLDatabaseFileIsInUse,
      [DatabaseFileName + DatabaseFileNameUnicode])
  else
  begin
    if (not ACRFileExists(DatabaseFileName, DatabaseFileNameUnicode)) then
      Exit;
    AccessMode := amReadWrite;
    ShareMode := smExclusive;
    try
      FDatabaseFile.OpenFile(DatabaseFileName, DatabaseFileNameUnicode,
        AccessMode, ShareMode, True);
      FOffsetToDBHeader := GetOffsetToDBHeader;
      if (FOffsetToDBHeader >= 0) then
        FDatabaseFile.Size := FOffsetToDBHeader;
      FDatabaseFile.CloseFile;
    except
      if (FDatabaseFile.IsOpened) then
        try
          FDatabaseFile.CloseFile;
        except
        end;
      raise ;
    end;
  end;
end; // RemoveDatabaseFromExe

//------------------------------------------------------------------------------
// get total number of pages
//------------------------------------------------------------------------------
function TACRDiskPageManager.GetTotalPageCount: Integer;
begin
  if (not IsOpened) then
    raise EACRException.Create(11778, ErrorLDatabaseIsNotOpened);
  if (not LockFreeSpaceManager(False)) then
    raise EACRException.Create(12299, ErrorLCannotLockFreeSpaceManager,
      [FDatabaseFile.FileName]);
  try
    Result := FDatabaseFreeSpaceManager.FHeader.TotalPageCount;
  finally
    UnlockFreeSpaceManager;
  end;
end; // GetTotalPageCount

//------------------------------------------------------------------------------
// return number of free pages
//------------------------------------------------------------------------------
function TACRDiskPageManager.GetFreePageCount: Integer;
begin
  if (not IsOpened) then
    raise EACRException.Create(11779, ErrorLDatabaseIsNotOpened);
  if (not LockFreeSpaceManager(False)) then
    raise EACRException.Create(12300, ErrorLCannotLockFreeSpaceManager,
      [FDatabaseFile.FileName]);
  try
    Result := FDatabaseFreeSpaceManager.FHeader.FreePageCount;
  finally
    UnlockFreeSpaceManager;
  end;
end; // GetFreePageCount
{$IFDEF DEBUG_PM_Test_State}

function TACRDiskPageManager.TestLoadState(PageNo: TACRPageNo;
  StateOnly: Boolean): Cardinal;
begin
  if (StateOnly) then
  begin
    ReadPageRegion(Result, PageNo, 4, 4, True);
  end
  else
  begin
    if (FTempPage = nil) then
      FTempPage := TACRPage.Create(Self);
    FTempPage.PageNo := PageNo;
    DirectReadPage(FTempPage);
    Move(PAnsiChar(FTempPage.PageData + 4)^, Result, 4);
  end;
end; // TestLoadState

procedure TACRDiskPageManager.TestSaveState(PageNo: TACRPageNo;
  State: Cardinal; StateOnly: Boolean);
begin
  if (StateOnly) then
  begin
    WritePageRegion(State, PageNo, 4, 4, True);
  end
  else
  begin
    if (FTempPage = nil) then
      FTempPage := TACRPage.Create(Self);
    FTempPage.PageNo := PageNo;
    Move(State, PAnsiChar(FTempPage.PageData + 4)^, 4);
    DirectWritePage(FTempPage);
  end;
end; // TestSaveState
{$ENDIF}
///////////////////////////////////////////////////////////////////////////////
//
// TACRInternalDBFile
//
///////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// return page offset
//------------------------------------------------------------------------------
function TACRInternalDBFile.GetPageOffset(Position: Int64): Word;
begin
  Result := Word(Int64(Position + SizeOf(TACRInternalFileHeader))
      mod LPageManager.PageDataSize);
end; // GetPageOffset

//------------------------------------------------------------------------------
// return page no
//------------------------------------------------------------------------------
function TACRInternalDBFile.GetPageNo(Position: Int64): Integer;
begin
{$IFDEF DEBUG_TRACE_TACRInternalDBFile_GetPageNo}
  aaWriteToLog('> TACRInternalDBFile.GetPageNo, Position = ' + IntToStr
      (Position));
  aaWriteToLog('LPageMangaer  = ' + IntToHex(Integer(LPageManager), 8));
  aaWriteToLog('LPageManager.PageDataSize  = ' + IntToStr
      (LPageManager.PageDataSize));
  aaWriteToLog('Pos  = ' + IntToStr(Integer(Int64(Position + SizeOf
            (TACRInternalFileHeader)))));
  try
{$ENDIF}
    if (LPageManager = nil) then
      Result := INVALID_PAGE_NO
    else if (LPageManager.PageDataSize = 0) then
      Result := INVALID_PAGE_NO
    else
      Result := Integer(Int64(Position + SizeOf(TACRInternalFileHeader))
          div LPageManager.PageDataSize);
{$IFDEF DEBUG_TRACE_TACRInternalDBFile_GetPageNo}
    aaWriteToLog('< TACRInternalDBFile.GetPageNo, Position = ' + IntToStr
        (Position) + #9 + ',Result = ' + IntToStr(Result));
  except
    on e: Exception do
    begin
      aaWriteToLog('Error in TACRInternalDBFile.GetPageNo, Position = ' +
          IntToStr(Position) + #9 + ',Result = ' + IntToStr(Result)
          + ':' + #13#10 + e.Message);
      raise ;
    end;
  end;
{$ENDIF}
end; // GetPageNo

//------------------------------------------------------------------------------
// LockFile (Lock byte in 1-st page header
//------------------------------------------------------------------------------
function TACRInternalDBFile.InternalLockFile(Exclusive: Boolean): Boolean;
begin
  Result := LPageManager.LockPageByte(FStartPageNo, 0, Exclusive);
end; // LockFile

//------------------------------------------------------------------------------
// UnockFile
//------------------------------------------------------------------------------
function TACRInternalDBFile.InternalUnlockFile(Exclusive: Boolean): Boolean;
begin
  Result := LPageManager.UnlockPageByte(FStartPageNo, 0, Exclusive);
end; // UnlockFile

//------------------------------------------------------------------------------
// create and initialize page
//------------------------------------------------------------------------------
procedure TACRInternalDBFile.CreatePage(var aPage: TACRPage);
begin
  if (aPage = nil) then
  begin
    aPage := TACRPage.Create(LPageManager, nil);
    LPageManager.InitPage(aPage);
  end;
end; // CreatePage

//------------------------------------------------------------------------------
// put modified page to cache
//------------------------------------------------------------------------------
procedure TACRInternalDBFile.PutPage(var aPage: TACRPage);
begin
  if (LCache <> nil) then
  begin
    LCache.PutPage(aPage);
    aPage := nil;
  end
  else
  begin
    LPageManager.DirectWritePage(aPage);
  end;
end; // PutPage

//------------------------------------------------------------------------------
// compress data stream
//------------------------------------------------------------------------------
procedure TACRInternalDBFile.CompressDataStream;
var
  buf: PAnsiChar;
  BufSize: Integer;
begin
{$IFDEF DEBUG_TACRInternalDBFile_CompressDataStream}
  aaWriteToLog('> TACRInternalDBFile.CompressDataStream.' + #13#10 +
      'Compressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'Size = ' + IntToStr(FDataStream.Size));
{$ENDIF}
  FTempBuffer := nil;
  if (FDirectAccess) then
    raise EACRException.Create(11859, ErrorLOperationIsNotSupported);
  if ((FCompressed) and (FDataStream.Size > ACRMaxInternalFileNotCompressedSize)
    ) then
  begin
    FCompressionAlgorithm := acaZLIB;
    FCompressionMode := 1;
{$IFDEF DEBUG_TACRInternalDBFile_CompressDataStream}
    aaWriteToLog('1 TACRInternalDBFile.CompressDataStream.' + #13#10 +
        'CompAlg = ' + IntToStr(Byte(FCompressionAlgorithm))
        + #13#10 + 'CompMode = ' + IntToStr(FCompressionMode)
        + #13#10 + 'Size = ' + IntToStr(FDataStream.Size));
{$ENDIF}
    CompressAndEncryptBuffer(FCryptoInfo, Byte(FCompressionAlgorithm),
      FCompressionMode, FDataStream.Buffer, FDataStream.Size, buf, BufSize);
    // FDataStream.Reset;
    FTempBuffer := FDataStream.Buffer;
    FTempSize := FDataStream.BufferSize;
    FDataStream.SetBuffer(buf, BufSize);
{$IFDEF DEBUG_TACRInternalDBFile_CompressDataStream}
    aaWriteToLog('2 TACRInternalDBFile.CompressDataStream.' + #13#10 +
        'CompAlg = ' + IntToStr(Byte(FCompressionAlgorithm))
        + #13#10 + 'CompMode = ' + IntToStr(FCompressionMode)
        + #13#10 + 'Stream.Size = ' + IntToStr(FDataStream.Size)
        + #13#10 + 'BufSize = ' + IntToStr(BufSize));
    DataStream.SaveToFile(IncludeTrailingBackslash
        (ExtractFilePath(aaGetLogFileName)) + 'comp.dat');
{$ENDIF}
  end
  else
  begin
    FCompressionAlgorithm := acaNone;
    FCompressionMode := 0;
    FDataStream.Position := 0;
  end;
{$IFDEF DEBUG_TACRInternalDBFile_CompressDataStream}
  aaWriteToLog('< TACRInternalDBFile.CompressDataStream.' + #13#10 +
      'CompAlg = ' + IntToStr(Byte(FCompressionAlgorithm))
      + #13#10 + 'CompMode = ' + IntToStr(FCompressionMode)
      + #13#10 + 'Size = ' + IntToStr(FDataStream.Size));
{$ENDIF}
end; // CompressDataStream

//------------------------------------------------------------------------------
// decompress data stream
//------------------------------------------------------------------------------
procedure TACRInternalDBFile.DecompressDataStream;
var
  buf: PAnsiChar;
  BufSize: Integer;
begin
{$IFDEF DEBUG_TACRInternalDBFile_DecompressDataStream}
  aaWriteToLog('> TACRInternalDBFile.DecompressDataStream.' + #13#10 +
      'CompAlg = ' + IntToStr(Byte(FCompressionAlgorithm))
      + #13#10 + 'CompMode = ' + IntToStr(FCompressionMode)
      + #13#10 + 'Size = ' + IntToStr(FDataStream.Size));
{$ENDIF}
  if (FDirectAccess) then
    raise EACRException.Create(11860, ErrorLOperationIsNotSupported);
  if (FCompressionAlgorithm <> acaNone) then
  begin
    buf := FDataStream.Buffer;
    BufSize := FDataStream.Size;
    if (BufSize <= 0) then
      raise EACRException.Create(11872, ErrorLInvalidStreamSize,
        [BufSize, FSize]);
{$IFDEF DEBUG_TACRInternalDBFile_DecompressDataStream}
    aaWriteToLog('1 TACRInternalDBFile.DecompressDataStream.' + #13#10 +
        'CompAlg = ' + IntToStr(Byte(FCompressionAlgorithm))
        + #13#10 + 'CompMode = ' + IntToStr(FCompressionMode)
        + #13#10 + 'Size = ' + IntToStr(FDataStream.Size));
    DataStream.SaveToFile(IncludeTrailingBackslash
        (ExtractFilePath(aaGetLogFileName)) + 'decomp.dat');
{$ENDIF}
    DecompressAndDecryptBuffer(FCryptoInfo, Byte(FCompressionAlgorithm),
      FCompressionMode, buf, BufSize);
{$IFDEF DEBUG_TACRInternalDBFile_DecompressDataStream}
    aaWriteToLog('2 TACRInternalDBFile.DecompressDataStream.' + #13#10 +
        'CompAlg = ' + IntToStr(Byte(FCompressionAlgorithm))
        + #13#10 + 'CompMode = ' + IntToStr(FCompressionMode)
        + #13#10 + 'BufSize = ' + IntToStr(BufSize));
{$ENDIF}
    if (BufSize <= 0) then
      raise EACRException.Create(11873, ErrorLDecompressBufferFailed,
        [Byte(FCompressionAlgorithm), FSize, BufSize]);
    FDataStream.SetBuffer(buf, BufSize);
  end
  else
  begin
    FDataStream.Position := 0;
  end;
{$IFDEF DEBUG_TACRInternalDBFile_DecompressDataStream}
  aaWriteToLog('< TACRInternalDBFile.DecompressDataStream.' + #13#10 +
      'CompAlg = ' + IntToStr(Byte(FCompressionAlgorithm))
      + #13#10 + 'CompMode = ' + IntToStr(FCompressionMode)
      + #13#10 + 'Size = ' + IntToStr(FDataStream.Size));
{$ENDIF}
end; // DecompressDataStream

//------------------------------------------------------------------------------
//
//------------------------------------------------------------------------------
procedure TACRInternalDBFile.CompressDataStreamFinish;
begin
  if (FTempBuffer <> nil) then
  begin
    FDataStream.SetBuffer(FTempBuffer, FTempSize);
    FTempBuffer := nil;
  end;
end; // CompressDataStreamFinish

//------------------------------------------------------------------------------
// SetSize
//------------------------------------------------------------------------------
procedure TACRInternalDBFile.SetSize(NewSize: Cardinal;
  SessionID: TACRSessionID;
  // state type of the locked object that calls this method
  StateType: TACRDBStateType;
  // current state of the locked object that calls this method
  State: TACRState);
var
  Count, oldPageCount, fs, ft, NewPageCount, deltaPageCount: Cardinal;
  PageNo: TACRPageNo;
  Page: TACRPage;
begin
  oldPageCount := FPages.Count;
  fs := NewSize;
  ft := NewSize + SizeOf(TACRInternalFileHeader);
  NewPageCount := ft div LPageManager.PageDataSize;
  if (NewPageCount * LPageManager.PageDataSize < ft) then
    Inc(NewPageCount);
  if (NewPageCount <> oldPageCount) then
  begin
    if (NewPageCount > oldPageCount) then
    begin
      // extend file
      deltaPageCount := NewPageCount - oldPageCount;
      if (LCache = nil) then
      begin
        // direct mode - using page manager
        try
          if (deltaPageCount = 1) then
          begin
            PageNo := LPageManager.DirectAddPage;
            FPages.Insert(PageNo);
          end
          else
          begin
            LPageManager.DirectAddPages(FPages, deltaPageCount,
              (not FDirectAccess));
          end;
        except
          FPages.SetSize(oldPageCount);
          raise ;
        end;
      end
      else
      begin
        // using cache
        Page := nil;
        try
          if (deltaPageCount = 1) then
          begin
            // add single page
            Page := LCache.AddPage(SessionID, StateType, State, True);
            FPages.Insert(Page.PageNo);
          end
          else
          begin
            // add multiple pages
            LCache.AddPages(FPages, deltaPageCount, (not FDirectAccess),
              SessionID, StateType, State, True);
          end;
        except
          FPages.SetSize(oldPageCount);
          raise ;
        end;
      end;
    end // extend file
    else
    begin
      // shrink file
      deltaPageCount := oldPageCount - NewPageCount;
      if (LCache = nil) then
      begin
        // direct mode - using page manager
        try
          if (deltaPageCount = 1) then
          begin
            // delete single page
            Count := FPages.Count - 1;
            PageNo := FPages.Items[Count];
            LPageManager.DirectRemovePage(PageNo);
            FPages.SetSize(Count);
          end
          else
          begin
            // delete multiple pages
            LPageManager.DirectRemovePages(FPages, deltaPageCount);
          end;
        except
          FPages.SetSize(oldPageCount);
          raise ;
        end;
      end
      else
      begin
        // using cache
        Page := nil;
        try
          if (deltaPageCount = 1) then
          begin
            Page := LCache.AddPage(SessionID, StateType, State, True);
            FPages.Insert(Page.PageNo);
          end
          else
          begin
            LCache.AddPages(FPages, deltaPageCount, (not FDirectAccess),
              SessionID, StateType, State, True);
          end;
        except
          FPages.SetSize(oldPageCount);
          raise ;
        end;
      end;
    end;
  end; // shrink file
  FSize := fs;
  FTotalSize := ft;
  FStartPageNo := FPages.Items[0];
end; // SetSize

//------------------------------------------------------------------------------
// init file header
//------------------------------------------------------------------------------
procedure TACRInternalDBFile.InitPageHeader(FirstPage: Boolean;
  NextPageNo: TACRPageNo);
begin
  FPage.PageHeader.PageType := FPageTypeID;
  FPage.PageHeader.ObjectID := FObjectID;
  FPage.PageHeader.NextPageNo := NextPageNo;
  if (FirstPage) then
  begin
    // Init File Header
    PACRInternalFileHeader(FPage.PageData).Signature :=
      ACRInternalDBFileSignature;
    PACRInternalFileHeader(FPage.PageData).FileSize := FSize;
    PACRInternalFileHeader(FPage.PageData).CompressionAlgortihm := Byte
      (FCompressionAlgorithm);
    PACRInternalFileHeader(FPage.PageData).CompressionMode := Byte
      (FCompressionMode);
  end;
end; // InitFileHeader

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRInternalDBFile.Create(PageManager: TACRDiskPageManager;
  PageTypeID: TACRPageTypeID; ObjectID: TACRObjectID;
  // if true - direct access mode, FDataStream = nil
  bDirectAccess: Boolean;
  // if true and file size > PageDataSize -> data will be compressed
  bCompressed: Boolean;
  // if nil passed - LPageManager used in direct access mode
  // else Cache used for reading / writing data
  Cache: TACRCache);
begin
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('> TACRInternalDBFile.Create, Self = ' + IntToHex(Integer(Self),
      8) + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
      + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead, True));
{$ENDIF}
  FCompressed := bCompressed;
  FSize := 0;
  FTotalSize := 0;
  LPageManager := PageManager;
  LCache := Cache;
  FDirectAccess := bDirectAccess;
  FPageTypeID := PageTypeID;
  FObjectID := ObjectID;
  FStartPageNo := INVALID_PAGE_NO;
  FPage := nil;
  FExclusiveLock := False;
  FPages := TACRPageArray.Create;
  if (not FDirectAccess) then
    FDataStream := TACRMemoryStream.Create
  else
    FDataStream := nil;
  FFileRead := False;
  // init for read / write compression
  FCryptoInfo.CryptoAlgorithm := ACR_Cipher_None;
  FTempBuffer := nil;
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('< TACRInternalDBFile.Create, Self = ' + IntToHex(Integer(Self),
      8) + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
      + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead, True));
{$ENDIF}
end; // Create

//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TACRInternalDBFile.Destroy;
begin
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('> TACRInternalDBFile.Destroy, Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
      + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead, True));
{$ENDIF}
  if (FPages <> nil) then
    FreeAndNil(FPages);
  if (FDataStream <> nil) then
    FreeAndNil(FDataStream);
  if (LCache = nil) then
    if (FPage <> nil) then
      FreeAndNil(FPage);
  inherited;
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('< TACRInternalDBFile.Destroy, Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
      + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead, True));
{$ENDIF}
end; // Destroy

//------------------------------------------------------------------------------
// Create file
//------------------------------------------------------------------------------
procedure TACRInternalDBFile.CreateFile(FileSize: Cardinal;
  SessionID: TACRSessionID;
  // state type of the locked object that calls this method
  StateType: TACRDBStateType;
  // current state of the locked object that calls this method
  State: TACRState);
var
  i, n: Cardinal;
  PageNo: TACRPageNo;
  NextPageNo: TACRPageNo;
begin
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('> TACRInternalDBFile.CreateFile, Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
      + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead, True)

      + #13#10 + 'FileSize = ' + IntToStr(FileSize)
      + #13#10 + 'SessionID = ' + IntToStr(SessionID)
      + #13#10 + 'StateType = ' + IntToStr(Integer(StateType))
      + #13#10 + 'State = ' + IntToStr(Integer(State)));
{$ENDIF}
  // if (FStartPageNo = INVALID_PAGE_NO) then
  // raise EACRException.Create(11848,ErrorLFileIsNotOpened,[FPageTypeID]);
  if (not FDirectAccess) then
    FDataStream.Reset;
  FCompressionAlgorithm := acaNone;
  FCompressionMode := 0;
  SetSize(FileSize, SessionID, StateType, State);
  n := FPages.Count - 1;
  i := 0;
  if (LCache = nil) then
    CreatePage(FPage);
  while (i <= n) do
  begin
    PageNo := FPages.Items[i];
    if (i = n) then
      NextPageNo := INVALID_PAGE_NO
    else
      NextPageNo := FPages.Items[i + 1];
    if (LCache = nil) then
      FPage.PageNo := PageNo
    else
      FPage := LCache.GetPage(SessionID, PageNo, StateType, State, False, True,
        False);
    InitPageHeader((i = 0), NextPageNo);
    if (LCache = nil) then
    begin
      if (FDirectAccess) then
      begin
        if (i = 0) then
          LPageManager.WritePageRegion(FPage.PageBuffer^, PageNo, 0,
            FPage.PageHeaderSize + SizeOf(TACRInternalFileHeader), True)
        else
          LPageManager.WritePageRegion(FPage.PageBuffer^, PageNo, 0,
            FPage.PageHeaderSize, True)
      end
      else
        LPageManager.DirectWritePage(FPage);
    end
    else
      LCache.PutPage(FPage);
    Inc(i);
  end; // scan all pages and write header there
  if (LCache <> nil) then
    FPage := nil;
  FFileRead := True;
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('< TACRInternalDBFile.CreateFile, Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
      + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead, True)

      + #13#10 + 'FileSize = ' + IntToStr(FileSize)
      + #13#10 + 'SessionID = ' + IntToStr(SessionID)
      + #13#10 + 'StateType = ' + IntToStr(Integer(StateType))
      + #13#10 + 'State = ' + IntToStr(Integer(State)));
{$ENDIF}
end; // CreateFile

//------------------------------------------------------------------------------
// Delete file. And free all file pages
//------------------------------------------------------------------------------
procedure TACRInternalDBFile.DeleteFile(SessionID: TACRSessionID;
  // state type of the locked object that calls this method
  StateType: TACRDBStateType;
  // current state of the locked object that calls this method
  State: TACRState);
var
  i, n: Cardinal;
begin
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('> TACRInternalDBFile.DeleteFile, Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
      + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead, True)

      + #13#10 + 'SessionID = ' + IntToStr(SessionID)
      + #13#10 + 'StateType = ' + IntToStr(Integer(StateType))
      + #13#10 + 'State = ' + IntToStr(Integer(State)));
{$ENDIF}
  if (not FFileRead) then
    raise EACRException.Create(11835, ErrorLFileIsNotRead, [FPageTypeID]);
  if (FPage <> nil) then
    FreeAndNil(FPage);
  i := 0;
  n := FPages.Count - 1;
  if (n >= 0) then
  begin
    if (LCache = nil) then
    begin
      LPageManager.DirectRemovePages(FPages, n);
    end
    else
    begin
      LCache.RemovePages(FPages, SessionID, StateType, State, n);
    end;
  end;
  if (LCache <> nil) then
    FPage := nil;
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('< TACRInternalDBFile.DeleteFile, Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
      + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead, True)

      + #13#10 + 'SessionID = ' + IntToStr(SessionID)
      + #13#10 + 'StateType = ' + IntToStr(Integer(StateType))
      + #13#10 + 'State = ' + IntToStr(Integer(State)));
{$ENDIF}
end; // DeleteFile

//------------------------------------------------------------------------------
// Open file (reading file header)
//------------------------------------------------------------------------------
procedure TACRInternalDBFile.OpenFile(StartPageNo: TACRPageNo);
begin
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('> TACRInternalDBFile.OpenFile, Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
      + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead, True)

      + #13#10 + 'StartPageNo = ' + IntToStr(StartPageNo));
{$ENDIF}
  FStartPageNo := StartPageNo;
  if (FStartPageNo < ACRFirstPageNoSystemDirectory) then
    raise EACRException.Create(10698, ErrorLCannotOpenFileInvalidStartPage,
      [FPageTypeID, FStartPageNo]);
  FPages.SetSize(1);
  FPages.Items[0] := FStartPageNo;
  FSize := 0;
  FTotalSize := SizeOf(TACRInternalFileHeader);
  if (not FDirectAccess) then
    FDataStream.Reset;
  FFileRead := False;
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('< TACRInternalDBFile.OpenFile, Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
      + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead,
      True) + #13#10 + 'FStartPageNo = ' + IntToStr(FStartPageNo));
{$ENDIF}
end; // OpenFile

//------------------------------------------------------------------------------
// Read File Data
//------------------------------------------------------------------------------
procedure TACRInternalDBFile.ReadFile(SessionID: TACRSessionID;
  // state type of the locked object that calls this method
  StateType: TACRDBStateType;
  // current state of the locked object that calls this method
  State: TACRState);
var
  i, Offset: Cardinal;
  Count, sz: Integer;
  PageNo: TACRPageNo;
begin
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('> TACRInternalDBFile.ReadFile, Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
      + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead,
      True) + #13#10 + 'FStartPageNo = ' + IntToStr(FStartPageNo)

      + #13#10 + 'SessionID = ' + IntToStr(SessionID)
      + #13#10 + 'StateType = ' + IntToStr(Integer(StateType))
      + #13#10 + 'State = ' + IntToStr(Integer(State)));
{$ENDIF}
  if (FStartPageNo = INVALID_PAGE_NO) then
    raise EACRException.Create(11849, ErrorLFileIsNotOpened, [FPageTypeID]);
  FPages.SetSize(1);
  FPages.Items[0] := FStartPageNo;
  if (LCache = nil) then
    CreatePage(FPage);
  // read first page
  i := 0;
  PageNo := FStartPageNo;
  if (not FDirectAccess) then
    FDataStream.Reset;
  Count := 0;
  repeat
    if (LCache = nil) then
    begin
      FPage.PageNo := PageNo;
      if (FDirectAccess) then
      begin
        if (i = 0) then
          LPageManager.ReadPageRegion(FPage.PageBuffer^, PageNo, 0,
            FPage.PageHeaderSize + SizeOf(TACRInternalFileHeader), True)
        else
          LPageManager.ReadPageRegion(FPage.PageBuffer^, PageNo, 0,
            FPage.PageHeaderSize, True)
      end
      else
        LPageManager.DirectReadPage(FPage);
    end
    else
      FPage := LCache.GetPage(SessionID, PageNo, StateType, State, True, False,
        False);
    try
      if (i = 0) then
      begin
        // Read File Header from first page
        if (PACRInternalFileHeader(FPage.PageData).Signature <>
            ACRInternalDBFileSignature) then
          raise EACRException.Create(11847, ErrorLInvalidSignature,
            [PACRInternalFileHeader(FPage.PageData).Signature,
            ACRInternalDBFileSignature]);
        FSize := PACRInternalFileHeader(FPage.PageData).FileSize;
        FTotalSize := FSize + SizeOf(TACRInternalFileHeader);
        FCompressionAlgorithm := TACRCompressionAlgorithm
          (PACRInternalFileHeader(FPage.PageData)
            .CompressionAlgortihm);
        FCompressionMode := PACRInternalFileHeader(FPage.PageData)
          .CompressionMode;
        Offset := SizeOf(TACRInternalFileHeader);
      end
      else
        Offset := 0;
      if (not FDirectAccess) then
      begin
        if ((FTotalSize - Count) < FPage.PageDataSize) then
          sz := FTotalSize - Count - Offset
        else
          sz := FPage.PageDataSize - Offset;
        FDataStream.WriteBuffer(PAnsiChar(FPage.PageData + Offset)^, sz);
        Inc(Count, (sz + Offset));
      end;
      if (i > 0) then
        FPages.Insert(PageNo);
      PageNo := FPage.PageHeader.NextPageNo;
      Inc(i);
    finally
      if (LCache <> nil) then
        LCache.PutPage(FPage);
    end;
  until (PageNo = INVALID_PAGE_NO);
  if (not FDirectAccess) then
    DecompressDataStream;
  if (LCache <> nil) then
    FPage := nil;
  FFileRead := True;
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('< TACRInternalDBFile.ReadFile, Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
      + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead,
      True) + #13#10 + 'FStartPageNo = ' + IntToStr(FStartPageNo)

      + #13#10 + 'SessionID = ' + IntToStr(SessionID)
      + #13#10 + 'StateType = ' + IntToStr(Integer(StateType))
      + #13#10 + 'State = ' + IntToStr(Integer(State)));
{$ENDIF}
end; // ReadFile

//------------------------------------------------------------------------------
// Write File
//------------------------------------------------------------------------------
procedure TACRInternalDBFile.WriteFile
  (SessionID: TACRSessionID = INVALID_SESSION_ID;
  // state type of the locked object that calls this method
  StateType: TACRDBStateType = dbstNone;
  // current state of the locked object that calls this method
  State: TACRState = 0);
var
  i, Offset, n: Cardinal;
  Count, sz: Integer;
  PageNo: TACRPageNo;
  NextPageNo: TACRPageNo;
begin
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('> TACRInternalDBFile.WriteFile, Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'FPageTypeID = ' + IntToStr
      (FPageTypeID) + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead,
      True) + #13#10 + 'FStartPageNo = ' + IntToStr(FStartPageNo)

      + #13#10 + 'SessionID = ' + IntToStr(SessionID)
      + #13#10 + 'StateType = ' + IntToStr(Integer(StateType))
      + #13#10 + 'State = ' + IntToStr(Integer(State)));
{$ENDIF}
  if (not FFileRead) then
    raise EACRException.Create(11850, ErrorLFileIsNotRead, [FPageTypeID]);
  if (FDirectAccess) then
    raise EACRException.Create(11851, ErrorLOperationIsNotSupported);
  CompressDataStream;
  try
    SetSize(DataStream.Size, SessionID, StateType, State);
    if (LCache = nil) then
      CreatePage(FPage);
    i := 0;
    Count := 0;
    n := FPages.Count - 1;
    while (i <= n) do
    begin
      PageNo := FPages.Items[i];
      if (LCache = nil) then
        FPage.PageNo := PageNo
      else
        FPage := LCache.GetPage(SessionID, PageNo, StateType, State, False,
          True, False);
      if (i = n) then
        NextPageNo := INVALID_OBJECT_ID
      else
        NextPageNo := FPages.Items[i + 1];
      InitPageHeader((i = 0), NextPageNo);
      if (i = 0) then
        Offset := SizeOf(TACRInternalFileHeader)
      else
        Offset := 0;
      if ((FTotalSize - Count) < FPage.PageDataSize) then
        sz := FTotalSize - Count - Offset
      else
        sz := FPage.PageDataSize - Offset;
      FDataStream.ReadBuffer(PAnsiChar(FPage.PageData + Offset)^, sz);
      Inc(Count, (sz + Offset));
      if (LCache = nil) then
        LPageManager.DirectWritePage(FPage)
      else
        LCache.PutPage(FPage);
      Inc(i);
    end; // write all pages
    if (LCache <> nil) then
      FPage := nil;
  finally
    CompressDataStreamFinish;
  end;
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('< TACRInternalDBFile.WriteFile, Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'FPageTypeID = ' + IntToStr
      (FPageTypeID) + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead,
      True) + #13#10 + 'FStartPageNo = ' + IntToStr(FStartPageNo)

      + #13#10 + 'SessionID = ' + IntToStr(SessionID)
      + #13#10 + 'StateType = ' + IntToStr(Integer(StateType))
      + #13#10 + 'State = ' + IntToStr(Integer(State)));
{$ENDIF}
end; // WriteFile

//------------------------------------------------------------------------------
// EmptyFile
//------------------------------------------------------------------------------
procedure TACRInternalDBFile.EmptyFile
  (SessionID: TACRSessionID = INVALID_SESSION_ID;
  // state type of the locked object that calls this method
  StateType: TACRDBStateType = dbstNone;
  // current state of the locked object that calls this method
  State: TACRState = 0);
begin
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('> TACRInternalDBFile.EmptyFile, Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'FPageTypeID = ' + IntToStr
      (FPageTypeID) + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead,
      True) + #13#10 + 'FStartPageNo = ' + IntToStr(FStartPageNo)

      + #13#10 + 'SessionID = ' + IntToStr(SessionID)
      + #13#10 + 'StateType = ' + IntToStr(Integer(StateType))
      + #13#10 + 'State = ' + IntToStr(Integer(State)));
{$ENDIF}
  if (not FFileRead) then
    raise EACRException.Create(11852, ErrorLFileIsNotRead, [FPageTypeID]);
  SetSize(0, SessionID, StateType, State);
  if (LCache = nil) then
  begin
    CreatePage(FPage);
    FPage.PageNo := FStartPageNo;
  end
  else
    FPage := LCache.GetPage(SessionID, FStartPageNo, StateType, State, False,
      True, False);
  InitPageHeader(True, INVALID_PAGE_NO);
  if (LCache = nil) then
    LPageManager.DirectWritePage(FPage)
  else
    LCache.PutPage(FPage);
  if (LCache <> nil) then
    FPage := nil;
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('< TACRInternalDBFile.EmptyFile, Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'FPageTypeID = ' + IntToStr
      (FPageTypeID) + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead,
      True) + #13#10 + 'FStartPageNo = ' + IntToStr(FStartPageNo)

      + #13#10 + 'SessionID = ' + IntToStr(SessionID)
      + #13#10 + 'StateType = ' + IntToStr(Integer(StateType))
      + #13#10 + 'State = ' + IntToStr(Integer(State)));
{$ENDIF}
end; // EmptyFile

//------------------------------------------------------------------------------
// direct (without sessions, cache and transactions) Read buffer from DB file
//------------------------------------------------------------------------------
procedure TACRInternalDBFile.DirectReadBuffer(var Buffer; const Count: Integer;
  const Position: Integer; const DoNotEncrypt: Boolean);
var
  i: Integer;
  FirstPageNo: Integer;
  LastPageNo: Integer;
  PageNo: TACRPageNo;
  DBFileSize, Offset: Word;
  DBFilePos: Int64;
  BytesRead: Integer;
begin
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('> TACRInternalDBFile.DirectReadBuffer, Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
      + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead,
      True) + #13#10 + 'FStartPageNo = ' + IntToStr(FStartPageNo)

      + #13#10 + 'Count = ' + IntToStr(Count)
      + #13#10 + 'Position = ' + IntToStr(Position));
{$ENDIF}
  if (not FFileRead) then
    raise EACRException.Create(11853, ErrorLFileIsNotRead, [FPageTypeID]);
  FirstPageNo := GetPageNo(Position);
  if (FirstPageNo >= FPages.Count) then
    raise EACRException.Create(10647, ErrorLCannotReadFromFile,
      [Position, Count, FPages.Count, FSize]);
  LastPageNo := GetPageNo(Count + Position);
  if (LastPageNo >= FPages.Count) then
    raise EACRException.Create(10648, ErrorLCannotReadFromFile,
      [Position, Count, FPages.Count, FSize]);
  if (Position + Count > FSize) then
    raise EACRException.Create(10649, ErrorLCannotReadFromFile,
      [Position, Count, FPages.Count, FSize]);
  BytesRead := 0;

  for i := FirstPageNo to LastPageNo do
  begin
    PageNo := FPages.Items[i];
    DBFilePos := LPageManager.GetPageOffset(PageNo)
      + LPageManager.PageHeaderSize;
    DBFileSize := LPageManager.PageDataSize;
    if ((i = FirstPageNo) or (i = LastPageNo)) then
    begin
      if (i = FirstPageNo) then
      begin
        Offset := GetPageOffset(Position);
        Inc(DBFilePos, Offset);
        Dec(DBFileSize, Offset);
      end;
      if (i = LastPageNo) then
      begin
        Offset := GetPageOffset(Position + Count);
        Dec(DBFileSize, (LPageManager.PageDataSize - Offset));
      end;
    end;
    LPageManager.DirectReadBuffer(PAnsiChar(PAnsiChar(@Buffer) + BytesRead)^,
      DBFileSize, DBFilePos, 10650);
    {
      LPageManager.DatabaseFile.ReadBuffer
      (PAnsiChar(PAnsiChar(@Buffer) + BytesRead)^, DBFileSize, DBFilePos,
      10650);
      }
    Inc(BytesRead, DBFileSize);
  end;
  if ((not DoNotEncrypt) and
      (LPageManager.DBHeader.CryptoHeader.CryptoAlgorithm <>
        ACR_Cipher_None)) then
    ACRDecryptBuffer(LPageManager.CryptoInfo, PAnsiChar(@Buffer), Count);
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('< TACRInternalDBFile.DirectReadBuffer, Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
      + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead,
      True) + #13#10 + 'FStartPageNo = ' + IntToStr(FStartPageNo)

      + #13#10 + 'Count = ' + IntToStr(Count)
      + #13#10 + 'Position = ' + IntToStr(Position));
{$ENDIF}
end; // DirectReadBuffer

//------------------------------------------------------------------------------
// direct (without sessions, cache and transactions) Write buffer to DB file
//------------------------------------------------------------------------------
procedure TACRInternalDBFile.DirectWriteBuffer(const Buffer;
  const Count: Integer; const Position: Integer; const DoNotEncrypt: Boolean);
var
  i: Integer;
  FirstPageNo: Integer;
  LastPageNo: Integer;
  PageNo: TACRPageNo;
  DBFileSize, Offset: Word;
  DBFilePos: Int64;
  BytesRead: Integer;
  NewBuffer: PAnsiChar;
begin
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('> TACRInternalDBFile.DirectWriteBuffer, Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
      + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead,
      True) + #13#10 + 'FStartPageNo = ' + IntToStr(FStartPageNo)

      + #13#10 + 'Count = ' + IntToStr(Count)
      + #13#10 + 'Position = ' + IntToStr(Position));
{$ENDIF}
  if (not FFileRead) then
    raise EACRException.Create(11854, ErrorLFileIsNotRead, [FPageTypeID]);
  if ((not DoNotEncrypt) and
      (LPageManager.DBHeader.CryptoHeader.CryptoAlgorithm <>
        ACR_Cipher_None)) then
  begin
    NewBuffer := MemoryManager.GetMem(Count);
    Move(Buffer, NewBuffer^, Count);
    ACREncryptBuffer(LPageManager.CryptoInfo, NewBuffer, Count);
  end
  else
    NewBuffer := @Buffer;

  FirstPageNo := GetPageNo(Position);
  if (FirstPageNo >= FPages.Count) then
    raise EACRException.Create(10651, ErrorLCannotReadFromFile,
      [Position, Count, FPages.Count, FSize]);
  LastPageNo := GetPageNo(Count + Position);
  if (LastPageNo >= FPages.Count) then
    raise EACRException.Create(10652, ErrorLCannotReadFromFile,
      [Position, Count, FPages.Count, FSize]);
  if (Position + Count > FSize) then
    raise EACRException.Create(10653, ErrorLCannotReadFromFile,
      [Position, Count, FPages.Count, FSize]);
  BytesRead := 0;

  for i := FirstPageNo to LastPageNo do
  begin
    PageNo := FPages.Items[i];
    DBFilePos := LPageManager.GetPageOffset(PageNo)
      + LPageManager.PageHeaderSize;
    DBFileSize := LPageManager.PageDataSize;
    if ((i = FirstPageNo) or (i = LastPageNo)) then
    begin
      if (i = FirstPageNo) then
      begin
        Offset := GetPageOffset(Position);
        Inc(DBFilePos, Offset);
        Dec(DBFileSize, Offset);
      end;
      if (i = LastPageNo) then
      begin
        Offset := GetPageOffset(Position + Count);
        Dec(DBFileSize, (LPageManager.PageDataSize - Offset));
      end;
    end;
    LPageManager.DirectWriteBuffer(PAnsiChar(PAnsiChar(NewBuffer) + BytesRead)
        ^, DBFileSize, DBFilePos, 10654);
    {
      LPageManager.DatabaseFile.WriteBuffer
      (PAnsiChar(PAnsiChar(NewBuffer) + BytesRead)^, DBFileSize, DBFilePos,
      10654);
      }
    Inc(BytesRead, DBFileSize);
  end;
  if ((not DoNotEncrypt) and
      (LPageManager.DBHeader.CryptoHeader.CryptoAlgorithm <>
        ACR_Cipher_None)) then
    MemoryManager.FreeAndNilMem(NewBuffer);
{$IFDEF DEBUG_TRACE_TACRInternalDBFile}
  aaWriteToLog('< TACRInternalDBFile.DirectWriteBuffer, Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
      + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'LPageManager = ' + IntToHex(Integer(LPageManager),
      8) + #13#10 + 'LCache = ' + IntToHex(Integer(LCache),
      8) + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
      True) + #13#10 + 'FCompressed = ' + BoolToStr(FCompressed,
      True) + #13#10 + 'FFileRead = ' + BoolToStr(FFileRead,
      True) + #13#10 + 'FStartPageNo = ' + IntToStr(FStartPageNo)

      + #13#10 + 'Count = ' + IntToStr(Count)
      + #13#10 + 'Position = ' + IntToStr(Position));
{$ENDIF}
end; // DirectWriteBuffer

//------------------------------------------------------------------------------
// LockFile (Lock byte in 1-st page header
//------------------------------------------------------------------------------
function TACRInternalDBFile.LockFile(Exclusive: Boolean): Boolean;
begin
  // CheckFileOpened('LockFile');
  repeat
    Result := InternalLockFile(Exclusive);
    // retry to avoid 100% cpu usage
    if (not Result) then
      Sleep(1);
    FExclusiveLock := (Exclusive and Result);
  until (Result);
end; // LockFile

//------------------------------------------------------------------------------
// UnockFile
//------------------------------------------------------------------------------
function TACRInternalDBFile.UnlockFile(Exclusive: Boolean): Boolean;
begin
  // CheckFileOpened('UnlockFile');
  Result := InternalUnlockFile(Exclusive);
  if (Exclusive) then
    FExclusiveLock := False;
end; // UnlockFile

//------------------------------------------------------------------------------
// LockByte
//------------------------------------------------------------------------------
function TACRInternalDBFile.LockByte(ByteNo: Integer): Boolean;
var
  PageOffset: Word;
  PageNo: Integer;
begin
  // CheckFileOpened('LockByte');
{$IFDEF DEBUG_LOCKING_BYTES}
  aaWriteToLog('TACRInternalDBFile.LockByte #0, ByteNo = ' + IntToStr(ByteNo));
{$ENDIF}
  PageNo := GetPageNo(ByteNo);
{$IFDEF DEBUG_LOCKING_BYTES}
  aaWriteToLog('TACRInternalDBFile.LockByte #1, PageNo = ' + IntToStr(PageNo)
      + #13#10 + 'FSize = ' + IntToStr(FSize)
      + #13#10 + 'FPages.ItemCount = ' + IntToStr
      (FPages.Count));
{$ENDIF}
  if (PageNo >= FPages.Count) or (ByteNo >= FSize) then
    raise EACRException.Create(10655, ErrorLCannotAccessByteInFile,
      [ByteNo, 1, FPages.Count, FSize]);
  PageOffset := GetPageOffset(ByteNo) + LPageManager.PageHeaderSize;
{$IFDEF DEBUG_LOCKING_BYTES}
  aaWriteToLog('TACRInternalDBFile.LockByte #2, PageOffset = ' + IntToStr
      (PageOffset) + #13#10 + 'FPages.Items[PageNo] = ' + IntToStr
      (FPages.Items[PageNo]) + #13#10 + 'Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'ClassName = ' + Self.ClassName + #13#10 +
      'FStartPageNo = ' + IntToStr(FStartPageNo));
{$ENDIF}
  Result := LPageManager.LockPageByte(FPages.Items[PageNo], PageOffset);
{$IFDEF DEBUG_LOCKING_BYTES}
  aaWriteToLog('TACRInternalDBFile.LockByte #3, Result = ' + BoolToStr(Result,
      True));
{$ENDIF}
end; // LockByte

//------------------------------------------------------------------------------
// UnlockByte
//------------------------------------------------------------------------------
function TACRInternalDBFile.UnlockByte(ByteNo: Integer): Boolean;
var
  PageOffset: Word;
  PageNo: Integer;
begin
  // CheckFileOpened('UnlockByte');
{$IFDEF DEBUG_LOCKING_BYTES}
  aaWriteToLog('TACRInternalDBFile.UnlockByte #0, ByteNo = ' + IntToStr(ByteNo)
    );
{$ENDIF}
  PageNo := GetPageNo(ByteNo);
{$IFDEF DEBUG_LOCKING_BYTES}
  aaWriteToLog('TACRInternalDBFile.UnlockByte #1, PageNo = ' + IntToStr(PageNo)
      + #13#10 + 'FSize = ' + IntToStr(FSize)
      + #13#10 + 'FPages.ItemCount = ' + IntToStr(FPages.Count));
{$ENDIF}
  if (PageNo >= FPages.Count) then
    raise EACRException.Create(10656, ErrorLCannotAccessByteInFile,
      [ByteNo, 1, FPages.Count, FSize]);
  PageOffset := GetPageOffset(ByteNo) + LPageManager.PageHeaderSize;
{$IFDEF DEBUG_LOCKING_BYTES}
  aaWriteToLog('TACRInternalDBFile.UnlockByte #2, PageOffset = ' + IntToStr
      (PageOffset) + #13#10 + 'FPages.Items[PageNo] = ' + IntToStr
      (FPages.Items[PageNo]) + #13#10 + 'Self = ' + IntToHex
      (Integer(Self), 8) + #13#10 + 'ClassName = ' + Self.ClassName + #13#10 +
      'FStartPageNo = ' + IntToStr(FStartPageNo));
{$ENDIF}
  Result := LPageManager.UnlockPageByte(FPages.Items[PageNo], PageOffset);
{$IFDEF DEBUG_LOCKING_BYTES}
  aaWriteToLog('TACRInternalDBFile.UnlockByte #3, Result = ' + BoolToStr
      (Result, True));
{$ENDIF}
end; // UnlockByte

//------------------------------------------------------------------------------
// IsByteLocked
//------------------------------------------------------------------------------
function TACRInternalDBFile.IsByteLocked(ByteNo: Integer): Boolean;
var
  PageOffset: Word;
  PageNo: Integer;
begin
  // CheckFileOpened('IsByteLocked');
  PageNo := GetPageNo(ByteNo);
  if (PageNo >= FPages.Count) then
    raise EACRException.Create(10657, ErrorLCannotAccessByteInFile,
      [ByteNo, 1, FPages.Count, FSize]);
  PageOffset := GetPageOffset(ByteNo) + LPageManager.PageHeaderSize;
  Result := LPageManager.IsPageByteLocked(FPages.Items[PageNo], PageOffset);
end; // IsByteLocked

//------------------------------------------------------------------------------
// IsRegionLocked
//------------------------------------------------------------------------------
function TACRInternalDBFile.IsRegionLocked(const Position: Integer;
  const Count: Integer): Boolean;
var
  i: Integer;
  FirstPageNo: Integer;
  LastPageNo: Integer;
  PageNo: TACRPageNo;
  DBFileSize, Offset: Word;
  DBFilePos: Int64;
begin
{$IFDEF DEBUG_TRACE_TACRInternalDBFile_IsRegionLocked}
  aaWriteToLog('> TACRInternalDBFile.IsRegionLocked. Position = ' + IntToStr
      (Position) + ', Count = ' + IntToStr(Count)
      + #13#10 + 'FStartPageNo = ' + IntToStr(FStartPageNo)
      + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
      + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
      + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess, True));
  try
{$ENDIF}
    // CheckFileOpened('IsRegionLocked');
    if (Count <= 0) then
      raise EACRException.Create(10729, ErrorLInvalidItemCount, [Count]);
    Result := False;
    FirstPageNo := GetPageNo(Position);
    if (FirstPageNo >= FPages.Count) then
      raise EACRException.Create(10658, ErrorLCannotReadFromFile,
        [Position, Count, FPages.Count, FSize]);
    LastPageNo := GetPageNo(Count + Position);
    if (LastPageNo >= FPages.Count) then
      raise EACRException.Create(10659, ErrorLCannotReadFromFile,
        [Position, Count, FPages.Count, FSize]);
    if (Position + Count > FSize) then
      raise EACRException.Create(10660, ErrorLCannotReadFromFile,
        [Position, Count, FPages.Count, FSize]);

    for i := FirstPageNo to LastPageNo do
    begin
      PageNo := FPages.Items[i];
      DBFilePos := LPageManager.GetPageOffset(PageNo)
        + LPageManager.PageHeaderSize;
      DBFileSize := LPageManager.PageDataSize;
      if ((i = FirstPageNo) or (i = LastPageNo)) then
      begin
        if (i = FirstPageNo) then
        begin
          Offset := GetPageOffset(Position);
          Inc(DBFilePos, Offset);
          Dec(DBFileSize, Offset);
        end;
        if (i = LastPageNo) then
        begin
          Offset := GetPageOffset(Position + Count);
          Dec(DBFileSize, (LPageManager.PageDataSize - Offset));
        end;
      end;
      Result := LPageManager.DirectIsRegionLocked(DBFilePos, DBFileSize);
      if (Result) then
        break;
    end;
{$IFDEF DEBUG_TRACE_TACRInternalDBFile_IsRegionLocked}
    aaWriteToLog('< TACRInternalDBFile.IsRegionLocked. Position = ' + IntToStr
        (Position) + ', Count = ' + IntToStr(Count)
        + #13#10 + 'Result = ' + BoolToStr(Result,
        True) + #13#10 + 'FStartPageNo = ' + IntToStr(FStartPageNo)
        + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
        + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
        + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess, True));
  except
    on e: Exception do
    begin
      aaWriteToLog('Error in TACRInternalDBFile.IsRegionLocked. Position = ' +
          IntToStr(Position) + ', Count = ' + IntToStr(Count)
          + #13#10 + 'Result = ' + BoolToStr(Result,
          True) + #13#10 + 'FStartPageNo = ' + IntToStr(FStartPageNo)
          + #13#10 + 'FPageTypeID = ' + IntToStr(FPageTypeID)
          + #13#10 + 'FObjectID = ' + IntToStr(FObjectID)
          + #13#10 + 'FDirectAccess = ' + BoolToStr(FDirectAccess,
          True) + #13#10 + e.Message);
      raise ;
    end;
  end;
{$ENDIF}
end; // IsRegionLocked

///////////////////////////////////////////////////////////////////////////////
//
// TACRActiveSessionFile
//
///////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRActiveSessionFile.Create(PageManager: TACRPageManager;
  aLockParams: TACRLockParams);
begin
  LPageManager := TACRDiskPageManager(PageManager);
  FHandle := nil;
  LockParams := aLockParams;
end; // Create

//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRActiveSessionFile.Destroy;
begin
  CloseFile;
  inherited;
end; // Destroy

//------------------------------------------------------------------------------
// CreateFile
//------------------------------------------------------------------------------
function TACRActiveSessionFile.CreateFile(aMaxSessionCount: Integer)
  : TACRPageNo;
begin
  CloseFile;
  FHandle := TACRInternalDBFile.Create(LPageManager,
    ACRPageTypeIDActiveSessionList, INVALID_OBJECT_ID, True, False, nil);
  FHandle.CreateFile(aMaxSessionCount, INVALID_SESSION_ID, dbstNone, 0);
  Result := FHandle.StartPageNo;
  CloseFile;
end; // CreateFile

//------------------------------------------------------------------------------
// OpenFile
//------------------------------------------------------------------------------
procedure TACRActiveSessionFile.OpenFile(aStartPageNo: TACRPageNo);
begin
  CloseFile;
  FHandle := TACRInternalDBFile.Create(LPageManager,
    ACRPageTypeIDActiveSessionList, INVALID_OBJECT_ID, True, False, nil);
  FHandle.OpenFile(aStartPageNo);
  FHandle.ReadFile;
end; // OpenFile

//------------------------------------------------------------------------------
// CloseFile
//------------------------------------------------------------------------------
procedure TACRActiveSessionFile.CloseFile;
begin
  if (FHandle <> nil) then
    FreeAndNil(FHandle);
end; // CloseFile

//------------------------------------------------------------------------------
// Connect
//------------------------------------------------------------------------------
function TACRActiveSessionFile.Connect: TACRSessionID;
var
  i: Cardinal;
{$IFDEF DEBUG_LOCKING_BYTES}
  b: Boolean;
{$ENDIF}
begin
  // commented in v.4.60 - do not needed
  Result := INVALID_SESSION_ID;
{$IFDEF DEBUG_LOCKING_BYTES}
  aaWriteToLog('TACRActiveSessionFile.Connect #0, FHandle = ' + IntToHex
      (Integer(FHandle), 4) + #13#10 +
      'TACRActiveSessionFile.Connect #1, FHandle.Size = ' + IntToStr
      (FHandle.Size));
  i := 0;
  while (i < LPageManager.FDBHeader.MaxSessionCount) do
  begin
    try
      aaWriteToLog('TACRActiveSessionFile.Connect locking byte #' + IntToStr(i)
          + ' ...');
      b := FHandle.LockByte(i);
    except
      on e: Exception do
      begin
        b := False;
        aaWriteToLog('TACRActiveSessionFile.Connect locking byte #' + IntToStr
            (i) + ' ... Failed, error: ' + #13#10 + e.Message);
        raise ;
      end
      else
      begin
        b := False;
        aaWriteToLog('TACRActiveSessionFile.Connect locking byte #' + IntToStr
            (i) + ' ... Failed, unknown error');
        raise ;
      end;
    end;
    if (b) then
    begin
      Result := i;
      aaWriteToLog('TACRActiveSessionFile.Connect locking byte #' + IntToStr(i)
          + ' ... Result = True');
      break;
    end
    else
      aaWriteToLog('TACRActiveSessionFile.Connect locking byte #' + IntToStr(i)
          + ' ... Result = False');
    Inc(i);
  end; // while loop
{$ELSE}
  i := 0;
  while (i < LPageManager.FDBHeader.MaxSessionCount) do
  begin
    if (FHandle.LockByte(i)) then
    begin
      Result := i;
      break;
    end;
    Inc(i);
  end; // while loop
{$ENDIF}
  if (Result = INVALID_SESSION_ID) then
    raise EACRException.Create(10842, ErrorLMaximumSessionCountExceeded,
      [LPageManager.FDBHeader.MaxSessionCount]);
end; // Connect

//------------------------------------------------------------------------------
// Disconnect
//------------------------------------------------------------------------------
procedure TACRActiveSessionFile.Disconnect(SessionID: TACRSessionID);
begin
{$IFDEF DEBUG_LOCKING_BYTES}
  aaWriteToLog('TACRActiveSessionFile.Disconnect #0, SessionID = ' + IntToStr
      (SessionID));
  if (not FHandle.UnlockByte(SessionID)) then
  begin
    aaWriteToLog('TACRActiveSessionFile.Disconnect failed, SessionID = ' +
        IntToStr(SessionID));
    raise EACRException.Create(20095, ErrorACannotDisconnectSession);
  end
  else
    aaWriteToLog('TACRActiveSessionFile.Disconnect OK, SessionID = ' + IntToStr
        (SessionID));
{$ELSE}
  if (not FHandle.UnlockByte(SessionID)) then
    raise EACRException.Create(20095, ErrorACannotDisconnectSession);
{$ENDIF}
end; // Disconnect

//------------------------------------------------------------------------------
// return ture if any asession already connected
//------------------------------------------------------------------------------
function TACRActiveSessionFile.IsAnySessionConnected: Boolean;
begin
  Result := FHandle.IsRegionLocked(0, LPageManager.FDBHeader.MaxSessionCount);
end; // IsAnySessionConnected


///////////////////////////////////////////////////////////////////////////////
//
// TACRTableListFile
// rewritten in v.5
//
///////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return -1 if not found or index starting from 0
//------------------------------------------------------------------------------
function TACRTableListFile.IndexOf(TableNameCRC: Cardinal;  TableName: WideString; bIncludeViews: Boolean): Integer;
var
  i, n, crc: Cardinal;
begin
  Result := -1;
  n := FHeader.TableCount;
  if (n = 0) then
  begin
    if (bIncludeViews) then
     Result := FViews.GetDefNumberByCRC(TableNameCRC);
    Exit;
  end;
  i := 0;
  while (i < n) do
  begin
    if (FTableList[i].TableNameCRC = TableNameCRC) then
    begin
      if (WideUpperCase(FNames[i]) = WideUpperCase(TableName)) then
      begin
        Result := i;
        break;
      end;
    end;
    Inc(i);
  end;
  if (bIncludeViews and (Result < 0)) then
   Result := FViews.GetDefNumberByCRC(TableNameCRC);
end; // IndexOf


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TACRTableListFile.Lock;
begin
  FThreadSync.Lock(True);
end; // Lock


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TACRTableListFile.Unlock;
begin
  FThreadSync.Unlock;
end; // Unlock


{$IFDEF DEBUG_LOG}
//------------------------------------------------------------------------------
// write table list to log
//------------------------------------------------------------------------------
procedure TACRTableListFile.WriteTableListToLog;
var
  i, n: Cardinal;
begin
  i := 0;
  n := FHeader.TableCount;
  aaWriteToLog('TACRTableListFile.WriteTableListToLog - FHeader.TableCount = '
    + IntToStr(FHeader.TableCount) + #13#10 + 'FHeader.State = ' + IntToStr
    (FHeader.State) + #13#10 + 'FState = ' + IntToStr(FState)
    + #13#10 + 'FNotLoaded = ' + BoolToStr(FNotLoaded,
    True) + #13#10 + 'FHeader.StatePageCount = ' + IntToStr
    (FHeader.StatePageCount) + #13#10 + 'FStatesPerPage = ' + IntToStr
    (FStatesPerPage) + #13#10 + 'FStateMapBytesPerPage = ' + IntToStr
    (FStateMapBytesPerPage) + #13#10 + 'FStateMapSize = ' + IntToStr
    (FStateMapSize) + #13#10 + 'FStateMap = ' + IntToHex(Integer(FStateMap),
    8) + #13#10 + 'FStatePages.Count = ' + IntToStr(FStatePages.Count));
  while (i < n) do
  begin
    aaWriteToLog(FNames[i] + #9 + IntToHex(FTableList[i].TableNameCRC,8) + #9 + IntToStr(FTableList[i].TableID)+ #9 + 'Comment: ' + #13#10 + FComments[i]);
    Inc(i);
  end;
  i := 0;
  n := FStatePages.Count;
  while (i < n) do
  begin
    aaWriteToLog('FStatePages.Items[' + IntToStr(i) + '] = ' + IntToStr(FStatePages.Items[i]));
    Inc(i);
  end;
  i := 0;
  n := FStateMapSize;
  while (i < n) do
  begin
    aaWriteToLog('FStateMap[' + IntToStr(i) + '] = ' + IntToHex(pByte(FStateMap + i)^, 2));
    Inc(i);
  end;
end; // WriteTableListToLog
{$ENDIF}


//------------------------------------------------------------------------------
// set new state map size
//------------------------------------------------------------------------------
procedure TACRTableListFile.SetStateMapSize;
var
  NewSize: Cardinal;
begin
  NewSize := FHeader.StatePageCount * FStateMapBytesPerPage;
  if (NewSize <> FStateMapSize) then
  begin
    if (FStateMapSize = 0) then
    begin
      FStateMap := MemoryManager.AllocMem(NewSize);
    end
    else
    begin
      MemoryManager.ReallocMem(FStateMap, NewSize, True);
    end;
    FStateMapSize := NewSize;
  end;
end; // SetStateMapSize


//------------------------------------------------------------------------------
// create table state
//------------------------------------------------------------------------------
procedure TACRTableListFile.CreateTableState(
                                              var TableItem:    TACRTableListItem;
                                              const TableState: TACRTableState
                                            );
var
  Page:           TACRPage;
  bNotFound:      Boolean;
  n, d:           Cardinal;
  priorAddress:   TACRRecordID;
  newAddress:     TACRRecordID;
  newMap:         PAnsiChar;
{$I ACR_check_null_flag_var.inc}
{$I ACR_set_null_flag_var.inc}
begin
{$IFDEF DEBUG_TRACE_TACRTableListFile_CreateTableState}
  aaWriteToLog('> TACRTableListFile.CreateTableState, tables count = ' +
      IntToStr(FHeader.TableCount));
  try
{$ENDIF}
    n := FHeader.TableCount;
    if (n = 0) then
      raise EACRException.Create(11858, ErrorLInvalidTableCount, [n]);
    if (n = 1) then
    begin
      FHeader.StatePageCount := 1;
      // add new state page
      TableItem.TableStateAddress.PageNo := LPageManager.DirectAddPage;
      TableItem.TableStateAddress.PageItemNo := 0;
{$IFDEF DEBUG_TRACE_TACRTableListFile_CreateTableState}
      aaWriteToLog('1. TACRTableListFile.CreateTableState PageNo = ' + IntToStr
          (TableItem.TableStateAddress.PageNo) + ', PageItemNo = ' + IntToStr
          (TableItem.TableStateAddress.PageItemNo));
{$ENDIF}
      FStatePages.Insert(TableItem.TableStateAddress.PageNo);
{$IFDEF DEBUG_TRACE_TACRTableListFile_CreateTableState}
      aaWriteToLog('2. TACRTableListFile.CreateTableState');
{$ENDIF}
      SetStateMapSize;
{$IFDEF DEBUG_TRACE_TACRTableListFile_CreateTableState}
      aaWriteToLog('3. TACRTableListFile.CreateTableState');
{$ENDIF}
      // first item
      SET_NULL_FLAG_ToSet := True;
      SET_NULL_FLAG_BitNo := 0;
      SET_NULL_FLAG_NullFlags := FStateMap;
{$I ACR_set_null_flag.inc}
{$IFDEF DEBUG_TRACE_TACRTableListFile_CreateTableState}
      aaWriteToLog('4. TACRTableListFile.CreateTableState');
{$ENDIF}
    end // first table
    else
    begin
      // d - index of table state page in FStatePages
      d := 0;
      n := FStateMapSize * 8;
      bNotFound := True;
{$IFDEF DEBUG_TRACE_TACRTableListFile_CreateTableState}
      aaWriteToLog('5. TACRTableListFile.CreateTableState');
{$ENDIF}
      CHECK_NULL_FLAG_NullFlags := FStateMap;
      CHECK_NULL_FLAG_BitNo := 0;
      while (CHECK_NULL_FLAG_BitNo < n) do
      begin
{$I ACR_check_null_flag.inc}
        if (not CHECK_NULL_FLAG_Result) then
        begin
          bNotFound := False;
          break;
        end;
        Inc(CHECK_NULL_FLAG_BitNo);
        if ((CHECK_NULL_FLAG_BitNo mod FStatesPerPage) = 0) then
          Inc(d);
      end;
{$IFDEF DEBUG_TRACE_TACRTableListFile_CreateTableState}
      aaWriteToLog('6. TACRTableListFile.CreateTableState, d = ' + IntToStr(d)
          + ', CHECK_NULL_FLAG_BitNo = ' + IntToStr(CHECK_NULL_FLAG_BitNo));
{$ENDIF}
      if (bNotFound) then
      begin
        // add new state page
        Inc(FHeader.StatePageCount);
        TableItem.TableStateAddress.PageNo := LPageManager.DirectAddPage;
        TableItem.TableStateAddress.PageItemNo := 0;
{$IFDEF DEBUG_TRACE_TACRTableListFile_CreateTableState}
        aaWriteToLog('7. TACRTableListFile.CreateTableState PageNo = ' +
            IntToStr(TableItem.TableStateAddress.PageNo)
            + ', PageItemNo = ' + IntToStr
            (TableItem.TableStateAddress.PageItemNo));
{$ENDIF}
        d := FStatePages.Insert(TableItem.TableStateAddress.PageNo, True);
{$IFDEF DEBUG_TRACE_TACRTableListFile_CreateTableState}
        aaWriteToLog('8. TACRTableListFile.CreateTableState');
{$ENDIF}
        SetStateMapSize;
{$IFDEF DEBUG_TRACE_TACRTableListFile_CreateTableState}
        aaWriteToLog('9. TACRTableListFile.CreateTableState');
{$ENDIF}
      end
      else
      begin
        TableItem.TableStateAddress.PageNo := FStatePages.Items[d];
        n := (CHECK_NULL_FLAG_BitNo mod FStatesPerPage);
        TableItem.TableStateAddress.PageItemNo := n * SizeOf(TACRTableState);
{$IFDEF DEBUG_TRACE_TACRTableListFile_CreateTableState}
        aaWriteToLog('10. TACRTableListFile.CreateTableState PageNo = ' +
            IntToStr(TableItem.TableStateAddress.PageNo)
            + ', PageItemNo = ' + IntToStr
            (TableItem.TableStateAddress.PageItemNo)
            + #13#10 + 'n = ' + IntToStr(n));
{$ENDIF}
      end;
      SET_NULL_FLAG_ToSet := True;
      SET_NULL_FLAG_BitNo := CHECK_NULL_FLAG_BitNo;
      SET_NULL_FLAG_NullFlags := FStateMap;
{$I ACR_set_null_flag.inc}
    end; // not first table
{$IFDEF DEBUG_TRACE_TACRTableListFile_CreateTableState}
aaWriteToLog('< TACRTableListFile.CreateTableState' + #13#10 +
'TableItem.TableStateAddress.PageNo = ' + IntToStr
(TableItem.TableStateAddress.PageNo) + #13#10 +
'TableItem.TableStateAddress.PageItemNo = ' + IntToStr
(TableItem.TableStateAddress.PageItemNo) + #13#10 +
'FHeader.TableCount = ' + IntToStr(FHeader.TableCount)
+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
+ #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'FStatePages = ' + IntToStr
(FStatePages.Count) + #13#10 + 'FStatesPerPage = ' + IntToStr
(FStatesPerPage) + #13#10 + 'FStateMapSize = ' + IntToStr
(FStateMapSize) + #13#10 + 'FStateMapBytesPerPage = ' +
IntToStr(FStateMapBytesPerPage));
  except
    on e: Exception do
    begin
aaWriteToLog('Error in  TACRTableListFile.CreateTableState' + #13#10 +
'TableItem.TableStateAddress.PageNo = ' + IntToStr
(TableItem.TableStateAddress.PageNo) + #13#10 +
'TableItem.TableStateAddress.PageItemNo = ' + IntToStr
(TableItem.TableStateAddress.PageItemNo) + #13#10 +
'FHeader.TableCount = ' + IntToStr(FHeader.TableCount)
+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
+ #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'FStatePages = ' + IntToStr
(FStatePages.Count) + #13#10 + 'FStatesPerPage = ' + IntToStr
(FStatesPerPage) + #13#10 + 'FStateMapSize = ' + IntToStr
(FStateMapSize) + #13#10 + 'FStateMapBytesPerPage = ' + IntToStr
(FStateMapBytesPerPage) + #13#10 + e.Message);
      raise ;
    end;
  end;
{$ENDIF}
end; // CreateTableState


//------------------------------------------------------------------------------
// free table state
//------------------------------------------------------------------------------
procedure TACRTableListFile.FreeTableState(var TableItem: TACRTableListItem);
var
    i:                      Integer;
  start, finish, n, k, l:   Cardinal;
  bFreePage:                Boolean;
  newMap:                   PAnsiChar;
{$I ACR_check_null_flag_var.inc}
{$I ACR_set_null_flag_var.inc}
begin
{$IFDEF DEBUG_TRACE_TACRTableListFile_FreeTableState}
aaWriteToLog('> TACRTableListFile.FreeTableState, tables count = ' + IntToStr(FHeader.TableCount));
  try
{$ENDIF}
    i := FStatePages.Find(TableItem.TableStateAddress.PageNo);
{$IFDEF DEBUG_TRACE_TACRTableListFile_FreeTableState}
aaWriteToLog('1. TACRTableListFile.FreeTableState, i = ' + IntToStr(i)+ #13#10 + 'TableItem.TableStateAddress.PageNo = ' + IntToStr(TableItem.TableStateAddress.PageNo));
{$ENDIF}
    if (i < 0) then
      raise EACRException.Create(11861, ErrorLPageIsNotFound,
        [TableItem.TableStateAddress.PageNo, FStatePages.Count]);
    n := (i * FStatesPerPage) +
      (TableItem.TableStateAddress.PageItemNo div SizeOf(TACRTableState));
{$IFDEF DEBUG_TRACE_TACRTableListFile_FreeTableState}
    aaWriteToLog('2. TACRTableListFile.FreeTableState, n = ' + IntToStr(n)
        + #13#10 + 'TableItem.TableStateAddress.PageNo = ' + IntToStr
        (TableItem.TableStateAddress.PageNo) + #13#10 +
        'TableItem.TableStateAddress.PageItemNo = ' + IntToStr
        (TableItem.TableStateAddress.PageItemNo) + #13#10 +
        'FHeader.TableCount = ' + IntToStr(FHeader.TableCount)
        + #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
        + #13#10 + 'FHeader.StatePageCount = ' + IntToStr
        (FHeader.StatePageCount) + #13#10 + 'FStatePages = ' + IntToStr
        (FStatePages.Count) + #13#10 + 'FStatesPerPage = ' + IntToStr
        (FStatesPerPage) + #13#10 + 'FStateMapSize = ' + IntToStr
        (FStateMapSize) + #13#10 + 'FStateMapBytesPerPage = ' +
        IntToStr(FStateMapBytesPerPage) + #13#10 +
        'SizeOf(TACRTableState) = ' + IntToStr(SizeOf(TACRTableState)));
{$ENDIF}
    if (n >= FStateMapSize * 8) then
      raise EACRException.Create(11862, ErrorLInvalidBitNo,
        [n, FStateMapSize * 8]);
    SET_NULL_FLAG_ToSet := False;
    SET_NULL_FLAG_BitNo := Integer(n);
    SET_NULL_FLAG_NullFlags := FStateMap;
{$I ACR_set_null_flag.inc}
{$IFDEF DEBUG_TRACE_TACRTableListFile_FreeTableState}
    aaWriteToLog('3. TACRTableListFile.FreeTableState');
{$ENDIF}
    // check if page is not used for any other states
    start := i * FStatesPerPage;
    finish := (i + 1) * FStatesPerPage - 1;
{$IFDEF DEBUG_TRACE_TACRTableListFile_FreeTableState}
    aaWriteToLog('4. TACRTableListFile.FreeTableState' + #13#10 + 'start = ' +
        IntToStr(start) + #13#10 + 'finish = ' + IntToStr(finish));
{$ENDIF}
    if (finish >= FStateMapSize * 8) then
      raise EACRException.Create(11863, ErrorLInvalidBitNo,
        [n, FStateMapSize * 8]);
    bFreePage := True;
    CHECK_NULL_FLAG_NullFlags := FStateMap;
    for CHECK_NULL_FLAG_BitNo := Integer(start) to Integer(finish) do
    begin
{$I ACR_check_null_flag.inc}
      if (CHECK_NULL_FLAG_Result) then
      begin
        bFreePage := False;
        break;
      end;
    end;
{$IFDEF DEBUG_TRACE_TACRTableListFile_FreeTableState}
    aaWriteToLog('5. TACRTableListFile.FreeTableState, bFreePage = ' + BoolToStr
        (bFreePage, True));
{$ENDIF}
    if (bFreePage) then
    begin
      LPageManager.DirectRemovePage(TableItem.TableStateAddress.PageNo);
      n := FStatePages.Count;
{$IFDEF DEBUG_TRACE_TACRTableListFile_FreeTableState}
      aaWriteToLog('6. TACRTableListFile.FreeTableState, n = ' + IntToStr(n));
{$ENDIF}
      if (n > 1) then
      begin
        Dec(n);
        k := n * FStateMapBytesPerPage;
{$IFDEF DEBUG_TRACE_TACRTableListFile_FreeTableState}
        aaWriteToLog('7. TACRTableListFile.FreeTableState, k = ' + IntToStr(k));
{$ENDIF}
        newMap := MemoryManager.GetMem(k);
{$IFDEF DEBUG_TRACE_TACRTableListFile_FreeTableState}
        aaWriteToLog('8. TACRTableListFile.FreeTableState');
{$ENDIF}
        if (i = 0) then
          Move(PAnsiChar(FStateMap + FStateMapBytesPerPage)^, newMap^, k)
        else if (i = n) then
          Move(FStateMap^, newMap^, k)
        else
        begin
          finish := i * FStateMapBytesPerPage;
{$IFDEF DEBUG_TRACE_TACRTableListFile_FreeTableState}
          aaWriteToLog('9. TACRTableListFile.FreeTableState finish = ' +
              IntToStr(finish));
{$ENDIF}
          Move(FStateMap^, newMap^, finish);
          start := (i + 1) * FStateMapBytesPerPage;
          // fix in v.5.60
          l := (n - i) * FStateMapBytesPerPage;
{$IFDEF DEBUG_TRACE_TACRTableListFile_FreeTableState}
          aaWriteToLog('10. TACRTableListFile.FreeTableState start = ' +
              IntToStr(start) + #13#10 + 'l = ' + IntToStr(l));
{$ENDIF}
          Move(PAnsiChar(FStateMap + start)^, PAnsiChar(newMap + finish)^, l)
        end;
{$IFDEF DEBUG_TRACE_TACRTableListFile_FreeTableState}
        aaWriteToLog('11. TACRTableListFile.FreeTableState');
{$ENDIF}
        MemoryManager.FreeAndNilMem(FStateMap);
{$IFDEF DEBUG_TRACE_TACRTableListFile_FreeTableState}
        aaWriteToLog('12. TACRTableListFile.FreeTableState');
{$ENDIF}
        FStateMap := newMap;
        FStateMapSize := k;
      end
      else
      begin
        // last page deleted - no tables
{$IFDEF DEBUG_TRACE_TACRTableListFile_FreeTableState}
        aaWriteToLog('13. TACRTableListFile.FreeTableState');
{$ENDIF}
        MemoryManager.FreeAndNilMem(FStateMap);
{$IFDEF DEBUG_TRACE_TACRTableListFile_FreeTableState}
        aaWriteToLog('14. TACRTableListFile.FreeTableState');
{$ENDIF}
        FStateMapSize := 0;
      end;
{$IFDEF DEBUG_TRACE_TACRTableListFile_FreeTableState}
      aaWriteToLog('15. TACRTableListFile.FreeTableState');
{$ENDIF}
      FStatePages.DeleteByPosition(i);
{$IFDEF DEBUG_TRACE_TACRTableListFile_FreeTableState}
      aaWriteToLog('16. TACRTableListFile.FreeTableState');
{$ENDIF}
      FHeader.StatePageCount := FStatePages.Count;
    end; // delete state page - there are no tables uses it
{$IFDEF DEBUG_TRACE_TACRTableListFile_FreeTableState}
aaWriteToLog('< TACRTableListFile.FreeTableState' + #13#10 +
'FHeader.TableCount = ' + IntToStr(FHeader.TableCount)
+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
+ #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'FStatePages = ' + IntToStr
(FStatePages.Count) + #13#10 + 'FStatesPerPage = ' + IntToStr
(FStatesPerPage) + #13#10 + 'FStateMapSize = ' + IntToStr
(FStateMapSize) + #13#10 + 'FStateMapBytesPerPage = ' +
IntToStr(FStateMapBytesPerPage));
  except
    on e: Exception do
    begin
aaWriteToLog('Error in  TACRTableListFile.FreeTableState' + #13#10 +
'FHeader.TableCount = ' + IntToStr(FHeader.TableCount)
+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
+ #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'FStatePages = ' + IntToStr
(FStatePages.Count) + #13#10 + 'FStatesPerPage = ' + IntToStr
(FStatesPerPage) + #13#10 + 'FStateMapSize = ' + IntToStr
(FStateMapSize) + #13#10 + 'FStateMapBytesPerPage = ' + IntToStr
(FStateMapBytesPerPage) + #13#10 + e.Message);
      raise ;
    end;
  end;
{$ENDIF}
end; // FreeTableState


//------------------------------------------------------------------------------
// load state map
//------------------------------------------------------------------------------
procedure TACRTableListFile.LoadStateMap(Repair: Boolean);
var
  i, j:         Cardinal;
  PageNo:       TACRPageNo;
  stateOffset:  Cardinal;
  pageIndex:    Integer;
{$I ACR_set_null_flag_var.inc}
begin
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('> TACRTableListFile.LoadStateMap, Repair = ' + BoolToStr(Repair, True));
{$ENDIF}
  SetStateMapSize;
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('1 TACRTableListFile.LoadStateMap, Repair = ' + BoolToStr(Repair, True));
{$ENDIF}
  i := 0;
  FStatePages.SetSize(0);
  while (i < FHeader.TableCount) do
  begin
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('2 TACRTableListFile.LoadStateMap, Repair = ' + BoolToStr(Repair, True) + #13#10 + 'i = ' + IntToStr(i));
{$ENDIF}
    PageNo := FTableList[i].TableStateAddress.PageNo;
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('3 TACRTableListFile.LoadStateMap, Repair = ' + BoolToStr(Repair, True) + #13#10 + 'i = ' + IntToStr(i));
{$ENDIF}
    // fixed in v.5.70
    pageIndex := FStatePages.Find(PageNo);
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('4 TACRTableListFile.LoadStateMap, Repair = ' + BoolToStr(Repair, True) + #13#10 + 'i = ' + IntToStr(i)+ #13#10 + 'pageIndex = ' + IntToStr(pageIndex)+ #13#10 + 'PageNo = ' + IntToStr(PageNo));
{$ENDIF}
    if (pageIndex < 0) then
    begin
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('5 TACRTableListFile.LoadStateMap, Repair = ' + BoolToStr(Repair, True) + #13#10 + 'i = ' + IntToStr(i)+ #13#10 + 'pageIndex = ' + IntToStr(pageIndex)+ #13#10 + 'PageNo = ' + IntToStr(PageNo));
{$ENDIF}
      pageIndex := FStatePages.Insert(PageNo);
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('6 TACRTableListFile.LoadStateMap, Repair = ' + BoolToStr(Repair, True) + #13#10 + 'i = ' + IntToStr(i)+ #13#10 + 'pageIndex = ' + IntToStr(pageIndex)+ #13#10 + 'PageNo = ' + IntToStr(PageNo));
{$ENDIF}
      if (Repair) then
      begin
        Inc(FHeader.StatePageCount);
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('7 TACRTableListFile.LoadStateMap, Repair = ' + BoolToStr(Repair, True) + #13#10 + 'i = ' + IntToStr(i)+ #13#10 + 'pageIndex = ' + IntToStr(pageIndex)+ #13#10 + 'PageNo = ' + IntToStr(PageNo));
{$ENDIF}
        SetStateMapSize;
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('8 TACRTableListFile.LoadStateMap, Repair = ' + BoolToStr(Repair, True) + #13#10 + 'i = ' + IntToStr(i)+ #13#10 + 'pageIndex = ' + IntToStr(pageIndex)+ #13#10 + 'PageNo = ' + IntToStr(PageNo));
{$ENDIF}
      end;
    end;
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('9 TACRTableListFile.LoadStateMap, Repair = ' + BoolToStr(Repair, True) + #13#10 + 'i = ' + IntToStr(i)+ #13#10 + 'pageIndex = ' + IntToStr(pageIndex)+ #13#10 + 'PageNo = ' + IntToStr(PageNo));
{$ENDIF}
    stateOffset := Cardinal(pageIndex * FStateMapBytesPerPage);
    j := Cardinal(FTableList[i].TableStateAddress.PageItemNo div SizeOf
        (TACRTableState));
    SET_NULL_FLAG_ToSet := True;
    SET_NULL_FLAG_BitNo := j;
    SET_NULL_FLAG_NullFlags := PAnsiChar(FStateMap + stateOffset);
{$I ACR_set_null_flag.inc}
    Inc(i);
  end;
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('< TACRTableListFile.LoadStateMap, Repair = ' + BoolToStr(Repair, True) + #13#10 + 'i = ' + IntToStr(i)+ #13#10 + 'pageIndex = ' + IntToStr(pageIndex)+ #13#10 + 'PageNo = ' + IntToStr(PageNo));
{$ENDIF}
end; // LoadStateMap


//------------------------------------------------------------------------------
// repair table list / header
//------------------------------------------------------------------------------
procedure TACRTableListFile.Repair(numElements: Cardinal);
begin
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('> TACRTableListFile.Repair, numElements = ' + IntToStr(numElements));
{$ENDIF}
  SetLength(FTableList, numElements);
  FHeader.TableCount := numElements;
  FHeader.State := 0;
  FHeader.StatePageCount := 0;
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('1 TACRTableListFile.Repair, numElements = ' + IntToStr(numElements));
{$ENDIF}
  if (numElements > 0) then
    LoadDataFromStream(FTableList[0], SizeOf(TACRTableListItem) * numElements,
      FHandle.DataStream, 12338);
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('2 TACRTableListFile.Repair, numElements = ' + IntToStr(numElements));
{$ENDIF}
  LoadStateMap(True);
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('< TACRTableListFile.Repair, numElements = ' + IntToStr(numElements));
{$ENDIF}
end; // Repair


//------------------------------------------------------------------------------
// Load Table List
//------------------------------------------------------------------------------
procedure TACRTableListFile.Load;
var
  n, k:           Cardinal;
  crc:            Cardinal;
  buf:            PAnsiChar;
  BufSize:        Integer;
  TempStream:     TACRMemoryStream;
  numElements:    Cardinal;
begin
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
  aaStartTime(time1);
  aaIncCounter(counter1);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
  aaWriteToLog('> TACRTableListFile.Load. ');
  try
{$ENDIF}
    // rewritten in v.5.80
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('1. TACRTableListFile.Load. ' + #13#10 + 'FNotLoaded = ' + BoolToStr(FNotLoaded, True) + #13#10 + 'FState = ' + IntToStr(FState));
{$ENDIF}
    Lock;
    try
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('2. TACRTableListFile.Load. ' + #13#10 + 'FNotLoaded = ' +BoolToStr(FNotLoaded, True) + #13#10 + 'FState = ' + IntToStr(FState)        );
{$ENDIF}
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
      aaIncCounter(counter2);
      aaStartTime(time2);
{$ENDIF}
      TACRDiskPageManager(LPageManager).LoadTLHeader(FHeader);
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
      aaStopTime(time2);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('3. TACRTableListFile.Load. ' + #13#10 + 'FNotLoaded = ' +BoolToStr(FNotLoaded, True) + #13#10 + 'FState = ' + IntToStr(FState)+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)+ #13#10 + 'FHeader.StatePageCount = ' + IntToStr(FHeader.StatePageCount) + #13#10 + 'TableCount = ' + IntToStr(FHeader.TableCount));
{$ENDIF}
      if (FNotLoaded or (FState <> FHeader.State)) then
      begin
        // load file
        // header already loaded by the TACRDiskDatabaseData
        n := FHeader.TableCount;
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('4. TACRTableListFile.Load. ' + #13#10 + 'FNotLoaded = ' +BoolToStr(FNotLoaded, True) + #13#10 + 'FState = ' + IntToStr(FState) + #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State) + #13#10 + 'FHeader.StatePageCount = ' + IntToStr(FHeader.StatePageCount) + #13#10 + 'TableCount = ' + IntToStr(FHeader.TableCount));
{$ENDIF}
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
        aaIncCounter(counter3);
        aaStartTime(time3);
{$ENDIF}
        FHandle.ReadFile;
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
        aaStopTime(time3);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('5. TACRTableListFile.Load. ' + #13#10 + 'FNotLoaded = ' +BoolToStr(FNotLoaded, True) + #13#10 + 'FState = ' + IntToStr(FState) + #13#10 + 'FHeader.State = ' + IntToStr
(FHeader.State) + #13#10 + 'FHeader.StatePageCount = ' + IntToStr(FHeader.StatePageCount) + #13#10 + 'TableCount = ' + IntToStr
(FHeader.TableCount) + #13#10 + 'FHandle.DataStream.Size = ' +IntToStr(FHandle.DataStream.Size) + #13#10 +'FHandle.DataStream.Position = ' + IntToStr(FHandle.DataStream.Position));
{$ENDIF}
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
        aaStartTime(time4);
{$ENDIF}
        if (n > 0) then
          FNames.LoadFromStream(FHandle.DataStream)
        else
          FNames.Clear;
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
        aaStopTime(time4);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('6. TACRTableListFile.Load. ' + #13#10 + 'FNotLoaded = ' +
BoolToStr(FNotLoaded, True) + #13#10 + 'FState = ' + IntToStr
(FState) + #13#10 + 'FHeader.State = ' + IntToStr
(FHeader.State) + #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'TableCount = ' + IntToStr
(FHeader.TableCount) + #13#10 + 'FHandle.DataStream.Size = ' +
IntToStr(FHandle.DataStream.Size) + #13#10 +
'FHandle.DataStream.Position = ' + IntToStr
(FHandle.DataStream.Position));
{$ENDIF}
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
        aaStartTime(time5);
{$ENDIF}
        if (n > 0) then
          FComments.LoadFromStream(FHandle.DataStream)
        else
          FComments.Clear;

{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
        aaStopTime(time5);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('7. TACRTableListFile.Load. ' + #13#10 + 'FNotLoaded = ' +
BoolToStr(FNotLoaded, True) + #13#10 + 'FState = ' + IntToStr
(FState) + #13#10 + 'FHeader.State = ' + IntToStr
(FHeader.State) + #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'TableCount = ' + IntToStr
(FHeader.TableCount) + #13#10 + 'FHandle.DataStream.Size = ' +
IntToStr(FHandle.DataStream.Size) + #13#10 +
'FHandle.DataStream.Position = ' + IntToStr
(FHandle.DataStream.Position));
{$ENDIF}
        numElements := Cardinal
          (Int64(FHandle.DataStream.Size - FHandle.DataStream.Position)
            div SizeOf(TACRTableListItem));
        // changed in v.6.00 for views (written after table elements)
        if (numElements * SizeOf(TACRTableListItem) >= TACRDiskPageManager(LPageManager).FDatabaseFile.Size) then
        begin
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog
('8. TACRTableListFile.Load. ' + #13#10 +
'FNotLoaded = ' + BoolToStr(FNotLoaded,
True) + #13#10 + 'FState = ' + IntToStr(FState)
+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
+ #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'TableCount = ' + IntToStr
(FHeader.TableCount) + #13#10 + 'FHandle.DataStream.Size = ' +
IntToStr(FHandle.DataStream.Size) + #13#10 +
'FHandle.DataStream.Position = ' + IntToStr
(FHandle.DataStream.Position)
+ #13#10 + 'numElements = ' + IntToStr(numElements));
{$ENDIF}
          // added in v.5.30 to avoid problems with too high dummy values in FHeader
          Repair(numElements);
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog
('9. TACRTableListFile.Load. ' + #13#10 +
'FNotLoaded = ' + BoolToStr(FNotLoaded,
True) + #13#10 + 'FState = ' + IntToStr(FState)
+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
+ #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'TableCount = ' + IntToStr
(FHeader.TableCount) + #13#10 + 'FHandle.DataStream.Size = ' +
IntToStr(FHandle.DataStream.Size) + #13#10 +
'FHandle.DataStream.Position = ' + IntToStr
(FHandle.DataStream.Position)
+ #13#10 + 'numElements = ' + IntToStr(numElements));
{$ENDIF}
        end // repair data
        else
        begin
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog
('10. TACRTableListFile.Load. ' + #13#10 +
'FNotLoaded = ' + BoolToStr(FNotLoaded,
True) + #13#10 + 'FState = ' + IntToStr(FState)
+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
+ #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'TableCount = ' + IntToStr
(FHeader.TableCount) + #13#10 + 'FHandle.DataStream.Size = ' +
IntToStr(FHandle.DataStream.Size) + #13#10 +
'FHandle.DataStream.Position = ' + IntToStr
(FHandle.DataStream.Position) + 'numElements = ' + IntToStr
(numElements));
{$ENDIF}
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
          aaStartTime(time6);
{$ENDIF}
          SetLength(FTableList, n);
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
          aaStopTime(time6);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog
('11. TACRTableListFile.Load. ' + #13#10 +
'FNotLoaded = ' + BoolToStr(FNotLoaded,
True) + #13#10 + 'FState = ' + IntToStr(FState)
+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
+ #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'TableCount = ' + IntToStr
(FHeader.TableCount) + #13#10 + 'FHandle.DataStream.Size = ' +
IntToStr(FHandle.DataStream.Size) + #13#10 +
'FHandle.DataStream.Position = ' + IntToStr
(FHandle.DataStream.Position) + 'numElements = ' + IntToStr
(numElements));
{$ENDIF}
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
          aaStartTime(time7);
{$ENDIF}
          if (n > 0) then
            LoadDataFromStream(FTableList[0], SizeOf(TACRTableListItem) * n,
              FHandle.DataStream, 11957);
          // load views if exists - added in v.6.00
          if (FHandle.DataStream.Position <= (FHandle.DataStream.Size-4)) then
           try
            FViews.LoadFromStream(FHandle.DataStream);
           except
             FViews.Clear;
           end
          else
           FViews.Clear;
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
          aaStopTime(time7);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('12. TACRTableListFile.Load. ' + #13#10 +
'FNotLoaded = ' + BoolToStr(FNotLoaded,
True) + #13#10 + 'FState = ' + IntToStr(FState)
+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
+ #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'TableCount = ' + IntToStr
(FHeader.TableCount) + #13#10 + 'FHandle.DataStream.Size = ' +
IntToStr(FHandle.DataStream.Size) + #13#10 +
'FHandle.DataStream.Position = ' + IntToStr
(FHandle.DataStream.Position) + 'numElements = ' + IntToStr
(numElements));
{$ENDIF}
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
          aaStartTime(time8);
{$ENDIF}
          LoadStateMap;
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
          aaStopTime(time8);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('13. TACRTableListFile.Load. ' + #13#10 +
'FNotLoaded = ' + BoolToStr(FNotLoaded,
True) + #13#10 + 'FState = ' + IntToStr(FState)
+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
+ #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'TableCount = ' + IntToStr
(FHeader.TableCount) + #13#10 + 'FHandle.DataStream.Size = ' +
IntToStr(FHandle.DataStream.Size) + #13#10 +
'FHandle.DataStream.Position = ' + IntToStr
(FHandle.DataStream.Position) + 'numElements = ' + IntToStr
(numElements));
{$ENDIF}
        end; // load data
        FState := FHeader.State;
        FNotLoaded := False;
      end; // load file
      FHandle.FileRead := True;
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('14. TACRTableListFile.Load. ' + #13#10 + 'FNotLoaded = ' +
BoolToStr(FNotLoaded, True) + #13#10 + 'FState = ' + IntToStr(FState)
+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
+ #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'TableCount = ' + IntToStr
(FHeader.TableCount) + #13#10 + 'FHandle.DataStream.Size = ' +
IntToStr(FHandle.DataStream.Size) + #13#10 +
'FHandle.DataStream.Position = ' + IntToStr
(FHandle.DataStream.Position) + 'numElements = ' + IntToStr(numElements));
{$ENDIF}
    finally
      Unlock;
    end;
{$IFDEF DEBUG_TRACE_TABLE_LIST_LOAD}
aaWriteToLog('< TACRTableListFile.Load. ' + #13#10 + 'FNotLoaded = ' +
BoolToStr(FNotLoaded, True) + #13#10 + 'FState = ' + IntToStr(FState)
+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
+ #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'TableCount = ' + IntToStr
(FHeader.TableCount) + #13#10 + 'FHandle.DataStream.Size = ' + IntToStr
(FHandle.DataStream.Size) + #13#10 + 'FHandle.DataStream.Position = ' +
IntToStr(FHandle.DataStream.Position) + 'numElements = ' + IntToStr
(numElements));
  except
    on e: Exception do
    begin
aaWriteToLog('Error in TACRTableListFile.Load. ' + #13#10 +
'FNotLoaded = ' + BoolToStr(FNotLoaded,
True) + #13#10 + 'FState = ' + IntToStr(FState)
+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
+ #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'TableCount = ' + IntToStr
(FHeader.TableCount) + #13#10 + 'FHandle.DataStream.Size = ' +
IntToStr(FHandle.DataStream.Size) + #13#10 +
'FHandle.DataStream.Position = ' + IntToStr
(FHandle.DataStream.Position) + 'numElements = ' + IntToStr
(numElements) + #13#10 + e.Message);
      raise ;
    end;
  end;
{$ENDIF}
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
  aaStopTime(time1);
{$ENDIF}
end; // Load


//------------------------------------------------------------------------------
// Save Table List - directly, no caching
//------------------------------------------------------------------------------
procedure TACRTableListFile.Save;
var
  i, n:       Cardinal;
  buf:        PAnsiChar;
  BufSize:    Integer;
  oldSize:    Int64;
begin
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
aaStartTime(time4);
aaIncCounter(counter4);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TABLE_LIST_SAVE}
  aaWriteToLog('> TACRTableListFile.Save. ');
  try
{$ENDIF}
    Lock;
    try
      n := FHeader.TableCount;
{$IFDEF DEBUG_TRACE_TABLE_LIST_SAVE}
aaWriteToLog('1. TACRTableListFile.Save. TableCount = ' + IntToStr(n)
+ #13#10 + 'FState = ' + IntToStr(FState)
+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
+ #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'FNotLoaded = ' + BoolToStr
(FNotLoaded, True));
{$ENDIF}
      if (n > 0) then
      begin
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
        aaStartTime(time5);
{$ENDIF}
        BufSize := FNames.SaveToStream(nil, True) + FComments.SaveToStream(nil,
          True);
        i := n * SizeOf(TACRTableListItem);
        Inc(BufSize, i);
        FHandle.DataStream.Size := BufSize;
        FHandle.DataStream.Position := 0;
        FNames.SaveToStream(FHandle.DataStream);
        FComments.SaveToStream(FHandle.DataStream);
        SaveDataToStream(FTableList[0], i, FHandle.DataStream, 11958);
        // save views - added in v.6.00
        FViews.SaveToStream(FHandle.DataStream);
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
        aaStopTime(time5);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TABLE_LIST_SAVE}
aaWriteToLog('2. TACRTableListFile.Save. TableCount = ' + IntToStr(n)
+ #13#10 + 'FState = ' + IntToStr(FState)
+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
+ #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'FNotLoaded = ' + BoolToStr
(FNotLoaded, True));
{$ENDIF}
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
        aaStartTime(time6);
{$ENDIF}
        FHandle.WriteFile;
{$IFDEF DEBUG_TRACE_TABLE_LIST_SAVE}
aaWriteToLog('3. TACRTableListFile.Save.');
{$ENDIF}
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
aaStopTime(time6);
{$ENDIF}
      end
      else
      begin
{$IFDEF DEBUG_TRACE_TABLE_LIST_SAVE}
aaWriteToLog('4. TACRTableListFile.Save.');
{$ENDIF}
        FHandle.EmptyFile;
{$IFDEF DEBUG_TRACE_TABLE_LIST_SAVE}
aaWriteToLog('5. TACRTableListFile.Save.');
{$ENDIF}
      end;
      Inc(FHeader.State);
      FState := FHeader.State;
{$IFDEF DEBUG_TRACE_TABLE_LIST_SAVE}
aaWriteToLog('6. TACRTableListFile.Save. TableCount = ' + IntToStr(n)
+ #13#10 + 'FState = ' + IntToStr(FState)
+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
+ #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'FNotLoaded = ' + BoolToStr
(FNotLoaded, True));
{$ENDIF}
      LPageManager.SaveTLHeader(FHeader);
    finally
      Unlock;
    end;
{$IFDEF DEBUG_TRACE_TABLE_LIST_SAVE}
aaWriteToLog('< TACRTableListFile.Save. TableCount = ' + IntToStr(n)
+ #13#10 + 'FState = ' + IntToStr(FState)
+ #13#10 + 'FHeader.State = ' + IntToStr
(FHeader.State) + #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'FNotLoaded = ' + BoolToStr
(FNotLoaded, True));
  except
    on e: Exception do
    begin
aaWriteToLog('Error in TACRTableListFile.Save. TableCount = ' + IntToStr
(n) + #13#10 + 'FState = ' + IntToStr(FState)
+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
+ #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'FNotLoaded = ' + BoolToStr
(FNotLoaded, True) + #13#10 + e.Message);
      raise ;
    end;
  end;
{$ENDIF}
{$IFDEF DEBUG_TIME_TABLE_LIST_LOADSAVE}
  aaStopTime(time4);
{$ENDIF}
end; // Save


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRTableListFile.Create(PageManager: TACRDiskPageManager);
begin
  if (PageManager = nil) then
    raise EACRException.Create(11857, ErrorLNilPointer);
  LPageManager := PageManager;
  FHandle := TACRInternalDBFile.Create(LPageManager, ACRPageTypeIDTableList,
    INVALID_OBJECT_ID, False, False, nil);
  FTableList := nil;
  FNotLoaded := True;
  FState := 0;
  FThreadSync := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
  FStatesPerPage := LPageManager.PageSize div SizeOf(TACRTableState);
  FStateMapBytesPerPage := FStatesPerPage div 8;
  if (FStatesPerPage mod 8 > 0) then
    Inc(FStateMapBytesPerPage);
  FStateMap := nil;
  FStatePages := TACRPageArray.Create;
  FStateMapSize := 0;
  FNames := TACRObjectNameArray.Create;
  FComments := TACRObjectNameArray.Create;
  FViews := TACRViewDefs.Create;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRTableListFile.Destroy;
begin
  if (FStateMap <> nil) then
    MemoryManager.FreeAndNilMem(FStateMap);
  if (FHandle <> nil) then
    FreeAndNil(FHandle);
  if (FStatePages <> nil) then
    FreeAndNil(FStatePages);
  if (FNames <> nil) then
    FreeAndNil(FNames);
  if (FComments <> nil) then
    FreeAndNil(FComments);
  if (FViews <> nil) then
    FreeAndNil(FViews);
  if (FThreadSync <> nil) then
    FreeAndNil(FThreadSync);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// CreateFile
//------------------------------------------------------------------------------
function TACRTableListFile.CreateFile: TACRPageNo;
begin
  FHandle.CreateFile(0, INVALID_SESSION_ID, dbstNone, 0);
  Result := FHandle.StartPageNo;
  FHeader.TableCount := 0;
  FHeader.State := 0;
  FHeader.StatePageCount := 0;
end; // CreateFile


//------------------------------------------------------------------------------
// OpenFile
//------------------------------------------------------------------------------
procedure TACRTableListFile.OpenFile(aStartPageNo: TACRPageNo);
begin
  FHandle.OpenFile(aStartPageNo);
end; // OpenFile


//------------------------------------------------------------------------------
// GetTableItemIfExists
//------------------------------------------------------------------------------
function TACRTableListFile.GetTableItemIfExists(
                  TableNameCRC:     Cardinal;
                  TableName:        WideString;
                  var TableItem:    TACRTableListItem
                                                ): Boolean;
var
  i: Integer;
begin
  i := IndexOf(TableNameCRC, TableName, False);
  if (i >= 0) then
  begin
    TableItem := FTableList[i];
    Result := True;
  end
  else
    Result := False;
end; // GetTableItemIfExists


//------------------------------------------------------------------------------
// GetTableItemIfExists
//------------------------------------------------------------------------------
function TACRTableListFile.GetTableItemIfExists(
                    TableNameCRC:     Cardinal;
                    TableName:        WideString;
                    var TableItem:    TACRTableListItem;
                    var Comment:      WideString
                                               ): Boolean;
var
  i: Integer;
begin
  i := IndexOf(TableNameCRC, TableName, False);
  if (i >= 0) then
  begin
    TableItem := FTableList[i];
    Comment := FComments[i];
    Result := True;
  end
  else
  begin
    Comment := '';
    Result := False;
  end;
end; // GetTableItemIfExists


//------------------------------------------------------------------------------
// get table item
//------------------------------------------------------------------------------
function TACRTableListFile.GetTableItemIfExists(
                        TableNameCRC:     Cardinal;
                        TableName:        WideString;
                        var TableItem:    TACRTableListItem;
                        out ItemIndex:    Integer
                                               ): Boolean;
begin
  ItemIndex := IndexOf(TableNameCRC, TableName, False);
  if (ItemIndex >= 0) then
    Move(FTableList[ItemIndex], TableItem, SizeOf(TableItem));
  Result := (ItemIndex >= 0);
end; // GetTableItemIfExists


//------------------------------------------------------------------------------
// update table item
//------------------------------------------------------------------------------
procedure TACRTableListFile.UpdateTableItem(
                          const ItemIndex: Integer;
                          const TableItem: TACRTableListItem;
                          const Comment: WideString
                                           );
begin
  if (Cardinal(ItemIndex) < FHeader.TableCount) then
  begin
    Move(TableItem, FTableList[ItemIndex], SizeOf(TableItem));
    FComments.Strings[ItemIndex] := Comment;
  end;
end; // UpdateTableItem


//------------------------------------------------------------------------------
// CreateTable
//------------------------------------------------------------------------------
procedure TACRTableListFile.CreateTable(
                                        var     TableItem:  TACRTableListItem;
                                        const   TableState: TACRTableState;
                                        TableName, Comment: WideString
                                       );
var
  Len, i, id, crc: Cardinal;
begin
{$IFDEF DEBUG_TRACE_TABLE_LIST_CREATE}
aaWriteToLog('> TACRTableListFile.CreateTable. TableName = ' + TableName +
#13#10 + 'TableNameCRC = ' + IntToHex(TableItem.TableNameCRC,
8) + #13#10 + 'TableNameCRC2 = ' + IntToHex
(GetTableNameCRC(TableName),
8) + #13#10 + 'Comment = ' + Comment + #13#10 + 'TableID = ' + IntToStr
(TableItem.TableID) + #13#10 + 'FHeader.TableCount = ' + IntToStr
(FHeader.TableCount) + #13#10 + 'FHeader.State = ' + IntToStr
(FHeader.State) + #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'FState = ' + IntToStr(FState)
+ #13#10 + 'FNotLoaded = ' + BoolToStr(FNotLoaded, True));
{$IFDEF DEBUG_TRACE_TABLE_LIST_CREATE_WRITE_TABLE_LIST}
  WriteTableListToLog;
{$ENDIF}
  try
{$ENDIF}
    if (IndexOf(TableItem.TableNameCRC, TableName, True) >= 0) then
      raise EACRException.Create(30394, ErrorGTableAlreadyExists, [TableName]);
    Len := FHeader.TableCount;
    Inc(Len);
    FHeader.TableCount := Len;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_CreateTable}
    aaWriteToLog('Before SetLength FTableList... Len = ' + IntToStr(Len));
{$ENDIF}
    SetLength(FTableList, Len);
{$IFDEF DEBUG_TRACE_TACRDiskTableData_CreateTable}
    aaWriteToLog('Before create state...');
{$ENDIF}
    CreateTableState(TableItem, TableState);
{$IFDEF DEBUG_TRACE_TACRDiskTableData_CreateTable}
    aaWriteToLog('After create state');
{$ENDIF}
    FTableList[Len - 1] := TableItem;
{$IFDEF DEBUG_TRACE_TACRDiskTableData_CreateTable}
    aaWriteToLog('Before add name');
{$ENDIF}
    FNames.Add(TableName);
{$IFDEF DEBUG_TRACE_TACRDiskTableData_CreateTable}
    aaWriteToLog('Before add comment');
{$ENDIF}
    FComments.Add(Comment);
{$IFDEF DEBUG_TRACE_TABLE_LIST_CREATE}
aaWriteToLog('< TACRTableListFile.CreateTable. TableName = ' + TableName +
#13#10 + 'TableNameCRC = ' + IntToHex(TableItem.TableNameCRC,
8) + #13#10 + 'TableNameCRC2 = ' + IntToHex
(GetTableNameCRC(TableName),
8) + #13#10 + 'Comment = ' + Comment + #13#10 + 'TableID = ' + IntToStr
(TableItem.TableID) + #13#10 + 'FHeader.TableCount = ' + IntToStr
(FHeader.TableCount) + #13#10 + 'FHeader.State = ' + IntToStr
(FHeader.State) + #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'FState = ' + IntToStr(FState)
+ #13#10 + 'FNotLoaded = ' + BoolToStr(FNotLoaded, True));
{$IFDEF DEBUG_TRACE_TABLE_LIST_CREATE_WRITE_TABLE_LIST}
    WriteTableListToLog;
{$ENDIF}
  except
    on e: Exception do
    begin
aaWriteToLog('Error in  TACRTableListFile.CreateTable. TableName = ' +
TableName + #13#10 + 'TableNameCRC = ' + IntToHex
(TableItem.TableNameCRC, 8) + #13#10 + 'TableNameCRC2 = ' + IntToHex
(GetTableNameCRC(TableName),
8) + #13#10 + 'Comment = ' + Comment + #13#10 + 'TableID = ' +
IntToStr(TableItem.TableID) + #13#10 + 'FHeader.TableCount = ' +
IntToStr(FHeader.TableCount) + #13#10 + 'FHeader.State = ' + IntToStr
(FHeader.State) + #13#10 + 'FHeader.StatePageCount = ' + IntToStr
(FHeader.StatePageCount) + #13#10 + 'FState = ' + IntToStr(FState)
+ #13#10 + 'FNotLoaded = ' + BoolToStr(FNotLoaded,
True) + #13#10 + e.Message);
{$IFDEF DEBUG_TRACE_TABLE_LIST_CREATE_WRITE_TABLE_LIST}
      WriteTableListToLog;
{$ENDIF}
      raise ;
    end;
  end;
{$ENDIF}
end; // CreateTable


//------------------------------------------------------------------------------
// DeleteTable
//------------------------------------------------------------------------------
procedure TACRTableListFile.DeleteTable(TableNameCRC: Cardinal;  TableName: WideString);
var
  Len: Cardinal;
  i, j: Integer;
begin
{$IFDEF DEBUG_TRACE_TABLE_LIST_DELETE}
aaWriteToLog('> TACRTableListFile.DeleteTable. TableName = ' + TableName +
#13#10 + 'TableNameCRC = ' + IntToHex(TableNameCRC,
8) + #13#10 + 'TableNameCRC2 = ' + IntToHex(GetTableNameCRC(TableName),
8) + #13#10 + 'FHeader.TableCount = ' + IntToStr(FHeader.TableCount)
+ #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State) + #13#10 +
'FHeader.StatePageCount = ' + IntToStr(FHeader.StatePageCount)
+ #13#10 + 'FState = ' + IntToStr(FState)
+ #13#10 + 'FNotLoaded = ' + BoolToStr(FNotLoaded, True));
{$IFDEF DEBUG_TRACE_TABLE_LIST_CREATE_WRITE_TABLE_LIST}
WriteTableListToLog;
{$ENDIF}
  try
{$ENDIF}
    i := IndexOf(TableNameCRC, TableName, False);
{$IFDEF DEBUG_TRACE_TABLE_LIST_DELETE}
    aaWriteToLog('1. TACRTableListFile.DeleteTable i = ' + IntToStr(i));
{$ENDIF}
    if (i >= 0) then
    begin
      FreeTableState(FTableList[i]);
{$IFDEF DEBUG_TRACE_TABLE_LIST_DELETE}
      aaWriteToLog('2. TACRTableListFile.DeleteTable i = ' + IntToStr(i));
{$ENDIF}
      Len := FHeader.TableCount;
      if (Cardinal(i) < Len - 1) then
      begin
{$IFDEF DEBUG_TRACE_TABLE_LIST_DELETE}
        aaWriteToLog('3. TACRTableListFile.DeleteTable i = ' + IntToStr(i));
{$ENDIF}
        for j := i to Integer(Len) - 2 do
        begin
          FTableList[j].TableNameCRC := FTableList[j + 1].TableNameCRC;
          FTableList[j].TableID := FTableList[j + 1].TableID;
          FTableList[j].MetaDataFilePageNo := FTableList[j + 1].MetaDataFilePageNo;
          FTableList[j].MostUpdatedDataFilePageNo := FTableList[j + 1].MostUpdatedDataFilePageNo;
          FTableList[j].LockFilePageNo := FTableList[j + 1].LockFilePageNo;
          FTableList[j].TableStateAddress := FTableList[j + 1].TableStateAddress;
        end;
{$IFDEF DEBUG_TRACE_TABLE_LIST_DELETE}
        aaWriteToLog('4. TACRTableListFile.DeleteTable i = ' + IntToStr(i));
{$ENDIF}
      end;
      Dec(Len);
{$IFDEF DEBUG_TRACE_TABLE_LIST_DELETE}
      aaWriteToLog('5. TACRTableListFile.DeleteTable');
{$ENDIF}
      FNames.Delete(i);
{$IFDEF DEBUG_TRACE_TABLE_LIST_DELETE}
      aaWriteToLog('6. TACRTableListFile.DeleteTable');
{$ENDIF}
      FComments.Delete(i);
{$IFDEF DEBUG_TRACE_TABLE_LIST_DELETE}
      aaWriteToLog('7. TACRTableListFile.DeleteTable');
{$ENDIF}
      FHeader.TableCount := Len;
{$IFDEF DEBUG_TRACE_TABLE_LIST_DELETE}
      aaWriteToLog('8. TACRTableListFile.DeleteTable');
{$ENDIF}
      SetLength(FTableList, Len);
{$IFDEF DEBUG_TRACE_TABLE_LIST_DELETE}
      aaWriteToLog('9. TACRTableListFile.DeleteTable');
{$ENDIF}
    end
    else
      raise EACRException.Create(40003, ErrorLTableDoesNotExist, [TableName]);
{$IFDEF DEBUG_TRACE_TABLE_LIST_DELETE}
aaWriteToLog('< TACRTableListFile.DeleteTable TableName = ' + TableName +
'TableNameCRC = ' + IntToStr(TableNameCRC));
{$IFDEF DEBUG_TRACE_TABLE_LIST_DELETE_WRITE_TABLE_LIST}
    WriteTableListToLog;
{$ENDIF}
  except
    on e: Exception do
    begin
aaWriteToLog('Error in TACRTableListFile.DeleteTable TableName = ' +
TableName + 'TableNameCRC = ' + IntToStr(TableNameCRC)+ #13#10 + e.Message);
{$IFDEF DEBUG_TRACE_TABLE_LIST_DELETE_WRITE_TABLE_LIST}
      WriteTableListToLog;
{$ENDIF}
      raise ;
    end;
  end;
{$ENDIF}
end; // DeleteTable


//------------------------------------------------------------------------------
// RenameTable
//------------------------------------------------------------------------------
procedure TACRTableListFile.RenameTable(OldTableName, NewTableName: WideString);
var
    i:    Integer;
    crc:  Cardinal;
begin
  i := IndexOf(GetTableNameCRC(OldTableName), OldTableName, False);
  if (i >= 0) then
  begin
    FNames[i] := NewTableName;
    crc := GetTableNameCRC(NewTableName);
    FTableList[i].TableNameCRC := crc;
  end
  else
    raise EACRException.Create(40003, ErrorLTableDoesNotExist, [OldTableName]);
end; // RenameTable


//------------------------------------------------------------------------------
// GetTablesList
//------------------------------------------------------------------------------
procedure TACRTableListFile.GetTablesList(List: TACRWideStringList);
var
  i, n: Cardinal;
  j:    Integer;
begin
  i := 0;
  n := FHeader.TableCount;
  while (i < n) do
  begin
    List.Add(FNames[i]);
    Inc(i);
  end;
  // added in v.6.00 - viewa
  for j := 0 to FViews.Count-1 do
   List.Add(FViews.Items[j].Name);
end; // GetTablesList


//------------------------------------------------------------------------------
// return info about all table in the list
// if SortByTableName then sort by table name ascending, case insensitive, else
// sort by physical order (like by creation date ascending)
//------------------------------------------------------------------------------
function TACRTableListFile.GetTablesInfo(SortByTableName: Boolean): TACRTableInfoArray;
var
    i, n: Cardinal;
    j:    Integer;
begin
  i := 0;
  n := FHeader.TableCount;
  SetLength(Result, Integer(n) + FViews.Count);
  while (i < n) do
  begin
    Result[i].TableName := FNames[i];
    Result[i].Comment := FComments[i];
    Result[i].TableState := LoadTableState(FTableList[i]);
    Result[i].CreationDate := FTableList[i].CreationDate;
    Inc(i);
  end;
  // added in v.6.00 - views
  for j := 0 to FViews.Count-1 do
  begin
    Result[i].TableName := TACRViewDef(FViews[j]).Name;
    Result[i].Comment := TACRViewDef(FViews[j]).Comment;
    Result[i].TableState.TableState := 0;
    Result[i].TableState.TableMetaDataState := 0;
    Result[i].TableState.TableFailureFlags := 0;
    Result[i].TableState.LastTableOperation := ltoCreateView;
    Result[i].TableState.LastModificationDate := TACRViewDef(FViews[j]).CreationDate;
    Result[i].CreationDate := TACRViewDef(FViews[j]).CreationDate;
    Inc(i);
  end;
  if ((Length(Result)>0) and SortByTableName) then
  begin
    ACRSortTableInfo(Result, 0, High(Result));
  end;
end; // GetTablesInfo


//------------------------------------------------------------------------------
// return number of tables
//------------------------------------------------------------------------------
function TACRTableListFile.GetNewTableID: TACRTableID;
var
  i, n: Cardinal;
  bOK: Boolean;
begin
{$IFDEF DEBUG_TRACE_TACRTableListFile_GetNewTableID}
  aaWriteToLog('> TACRTableListFile.GetNewTableID');
  try
{$ENDIF}
    repeat
      bOK := True;
      // random unqiue identifier to prevent from cache bug if we have closed table
      // and other process in file-server re-created it
      // new table will have another TableID, so its pages will be read directly
{$IFDEF DEBUG_TRACE_TACRTableListFile_GetNewTableID}
      aaWriteToLog('1 TACRTableListFile.GetNewTableID');
{$ENDIF}
      Result := TACRTableID(ACRGenerateRandomCardinal);
{$IFDEF DEBUG_TRACE_TACRTableListFile_GetNewTableID}
      aaWriteToLog('2 TACRTableListFile.GetNewTableID, Result = ' + IntToStr
          (Result) + #13#10 + 'TableCount = ' + IntToStr(FHeader.TableCount));
{$ENDIF}
      // check if
      i := 0;
      n := FHeader.TableCount;
      while (i < n) do
      begin
{$IFDEF DEBUG_TRACE_TACRTableListFile_GetNewTableID}
        aaWriteToLog('3 TACRTableListFile.GetNewTableID, Result = ' + IntToStr
            (Result) + #13#10 + 'i = ' + IntToStr(i) + ', n = ' + IntToStr(n)
            + #13#10 + 'TableList[i].TableID = ' + IntToStr
            (FTableList[i].TableID));
{$ENDIF}
        if (FTableList[i].TableID = Result) then
        begin
          bOK := False;
          break;
        end
        else
          Inc(i);
      end;
    until (bOK);
{$IFDEF DEBUG_TRACE_TACRTableListFile_GetNewTableID}
    aaWriteToLog('< TACRTableListFile.GetNewTableID, Result = ' + IntToStr
        (Result));
  except
    on e: Exception do
    begin
{$IFDEF DEBUG_TRACE_TACRTableListFile_GetNewTableID}
      aaWriteToLog('TACRTableListFile.GetNewTableID Error: ' + #13#10 +
          e.Message);
{$ENDIF}
      raise ;
    end;
  end;
{$ENDIF}
end; // GetNewTableID


//------------------------------------------------------------------------------
// load table state
//------------------------------------------------------------------------------
function TACRTableListFile.LoadTableState(const TableItem: TACRTableListItem): TACRTableState;
begin
{$IFDEF DEBUG_LOCK_TIMES}
  aaStartTime(time13);
  aaIncCounter(counter13);
  try
{$ENDIF}
    LPageManager.ReadPageRegion(Result, TableItem.TableStateAddress.PageNo,
      TableItem.TableStateAddress.PageItemNo, SizeOf(Result), True);
{$IFDEF DEBUG_LOCK_TIMES}
  finally
    aaStopTime(time13);
  end;
{$ENDIF}
end; // LoadTableState


//------------------------------------------------------------------------------
// save table state
//------------------------------------------------------------------------------
procedure TACRTableListFile.SaveTableState(
                                            const TableItem: TACRTableListItem;
                                            const TableState: TACRTableState
                                          );
begin
  LPageManager.WritePageRegion(TableState, TableItem.TableStateAddress.PageNo,
    TableItem.TableStateAddress.PageItemNo, SizeOf(TableState), True);
end; // SaveTableState


//------------------------------------------------------------------------------
// return table comment if table exists, otherwise empty string
//------------------------------------------------------------------------------
function TACRTableListFile.GetTableComment(TableName: WideString): WideString;
var
    i:    Integer;
    crc:  Cardinal;
begin
  Result := '';
  crc := GetTableNameCRC(TableName);
  i := IndexOf(crc, TableName, False);
  if (i >= 0) then
    Result := FComments[i]
  else
  begin
   i := FViews.GetDefNumberByCRC(crc);
   if (i >= 0) then
    Result := TACRViewDef(FViews.Items[i]).Comment;
  end;
end; // GetTableComment


//------------------------------------------------------------------------------
// set table comment
//------------------------------------------------------------------------------
procedure TACRTableListFile.SetTableComment(TableName, Comment: WideString);
var
    i:    Integer;
    crc:  Cardinal;
begin
  i := IndexOf(GetTableNameCRC(TableName), TableName, False);
  if (i >= 0) then
    FComments[i] := Comment
  else
  begin
   i := FViews.GetDefNumberByCRC(crc);
   if (i >= 0) then
    TACRViewDef(FViews.Items[i]).Comment := Comment
   else
    raise EACRException.Create(11964, ErrorLTableDoesNotExist, [TableName]);
  end;
end; // SetTableComment


//------------------------------------------------------------------------------
// create view (added in v.6.00)
//------------------------------------------------------------------------------
procedure TACRTableListFile.CreateView(
                     ViewName:          WideString;
                     ViewDef:           TACRViewDef
                    );
begin
  ViewDef.CreationDate := Now;
  FViews.Add(ViewDef);
end; // CreateView


//------------------------------------------------------------------------------
// return nil if not found, otherwise return view definition (added in v.6.00)
//------------------------------------------------------------------------------
function TACRTableListFile.FindView(ViewName: WideString): TACRViewDef;
var viewDef: TACRViewDef;
begin
  Result := TACRViewDef(FViews.GetDefByName(ViewName));
  if (Result <> nil) then
  begin
   // copy view definition to use it safely after releasing disk lock
   viewDef := Result;
   Result := TACRViewDef.Create;
   Result.Assign(viewDef);
  end;
end; // FindView


//------------------------------------------------------------------------------
// return false if not found, otherwise return true
//------------------------------------------------------------------------------
function TACRTableListFile.ViewExists(ViewName: WideString): Boolean;
begin
  Result := (FViews.GetDefNumberByName(ViewName) >= 0);
end; // ViewExists


//------------------------------------------------------------------------------
// drop view if has no problems with RESTRICT | CASCADE
//------------------------------------------------------------------------------
procedure TACRTableListFile.DropView(ViewName: WideString; Cascade: Boolean);
var idx: Integer;
begin
//  if (idx < 0) then
//   raise EACRException.Create(12584,ErrorLCannotDropViewItDoesNotExist,[ViewName]);
  if (Cascade) then
   FViews.DeleteChildren(ViewName)
  else
  if (FViews.FindChildren(ViewName)) then
   raise EACRException.Create(12583,ErrorLCannotDeleteViewOtherViewsExists,[ViewName]);
  idx := FViews.GetDefNumberByName(ViewName);
  if (idx >= 0) then
   FViews.Delete(idx);
end; // DropView


//------------------------------------------------------------------------------
// deletes all views referencing this table (view) if Cascade = TRUE
// otherwise raises an exception if there is some views referencing the table
//------------------------------------------------------------------------------
procedure TACRTableListFile.DeleteViewsByTable(TableName: WideString; Cascade: Boolean);
begin
  if (Cascade) then
   FViews.DeleteChildren(TableName)
  else
  if (FViews.FindChildren(TableName)) then
   raise EACRException.Create(12580,ErrorLCannotDeleteTableViewsExists,[TableName]);
end; // DeleteViewsByTable


//------------------------------------------------------------------------------
// added in v.6.00 - return true if view or table exists
//------------------------------------------------------------------------------
function TACRTableListFile.TableExists(TableName: WideString): Boolean;
begin
  Result := (IndexOf(GetTableNameCRC(TableName,True), TableName, True) >= 0);
end; // TableExists




///////////////////////////////////////////////////////////////////////////////
//
// TACRDiskStoredFunctionManager
// added in v.5.10
//
///////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// load stored function manager
//------------------------------------------------------------------------------
procedure TACRDiskStoredFunctionManager.Load(bLockSFMManager,  bLockSFM: Boolean);
begin
{$IFDEF DEBUG_TRACE_TACRDiskStoredFunctionManager_Load}
  aaWriteToLog('> TACRDiskStoredFunctionManager.Load' + #13#10 +
      'bLockSFMManager = ' + BoolToStr(bLockSFMManager,
      True) + #13#10 + 'bLockSFM = ' + BoolToStr(bLockSFM, True));
  try
{$ENDIF}
    if (bLockSFM) then
      Lock(True);
    try
      if (bLockSFMManager) then
        if (not LPageManager.LockStoredFunctionManager(True)) then
          raise EACRException.Create(12300,
            ErrorLCannotLockStoredFunctionManager,
            [LPageManager.DatabaseFileName]);
      try
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Load}
        aaWriteToLog('2 TACRDiskStoredFunctionManager.Load');
{$ENDIF}
        TACRDiskPageManager(LPageManager).LoadSFMHeader(FHeader);
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Load}
        aaWriteToLog('3 TACRDiskStoredFunctionManager.Load' + #13#10 +
            'FHeader.Count = ' + IntToStr(FHeader.Count)
            + #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
            + #13#10 + 'FNotLoaded = ' + BoolToStr(FNotLoaded,
            True) + #13#10 + 'FState = ' + IntToStr(FState));
{$ENDIF}
        // fixed in v.5.80
        if (FNotLoaded or (FState <> FHeader.State)) and (FHeader.Count > 0)
          then
        begin
          FHandle.ReadFile;
          Load(FHandle.DataStream, True);
        end;
        FHandle.FileRead := True;
        FState := FHeader.State;
        FNotLoaded := False;
      finally
        if (bLockSFMManager) then
          LPageManager.UnlockStoredFunctionManager;
      end;
    finally
      if (bLockSFM) then
        Unlock;
    end;
{$IFDEF DEBUG_TRACE_TACRDiskStoredFunctionManager_Load}
    aaWriteToLog('< TACRDiskStoredFunctionManager.Load' + #13#10 +
        'FHeader.Count = ' + IntToStr(FHeader.Count)
        + #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
        + #13#10 + 'FNotLoaded = ' + BoolToStr(FNotLoaded,
        True) + #13#10 + 'FState = ' + IntToStr(FState));
  except
    on e: Exception do
    begin
      aaWriteToLog('Error in TACRDiskStoredFunctionManager.Load:' + #13#10 +
          e.Message);
      raise ;
    end;
  end;
{$ENDIF}
end; // Load

//------------------------------------------------------------------------------
// save stored function manager
//------------------------------------------------------------------------------
procedure TACRDiskStoredFunctionManager.Save;
begin
{$IFDEF DEBUG_TRACE_TACRDiskStoredFunctionManager_Save}
  aaWriteToLog('> TACRDiskStoredFunctionManager.Save');
  try
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRDiskStoredFunctionManager_Save}
    aaWriteToLog('1 TACRDiskStoredFunctionManager.Save' + #13#10 +
        'FHeader.Count = ' + IntToStr(FHeader.Count)
        + #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
        + #13#10 + 'FNotLoaded = ' + BoolToStr(FNotLoaded,
        True) + #13#10 + 'FState = ' + IntToStr(FState));
{$ENDIF}
    FState := FHeader.State;
    FNotLoaded := False;
    LPageManager.SaveSFMHeader(FHeader);
{$IFDEF DEBUG_TRACE_TACRDiskStoredFunctionManager_Save}
    aaWriteToLog('2 TACRDiskStoredFunctionManager.Save' + #13#10 +
        'FHeader.Count = ' + IntToStr(FHeader.Count)
        + #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
        + #13#10 + 'FNotLoaded = ' + BoolToStr(FNotLoaded,
        True) + #13#10 + 'FState = ' + IntToStr(FState));
{$ENDIF}
    if (FHeader.Count > 0) then
    begin
      Save(FHandle.DataStream, True);
      FHandle.WriteFile;
    end
    else
      FHandle.EmptyFile;
{$IFDEF DEBUG_TRACE_TACRDiskStoredFunctionManager_Save}
    aaWriteToLog('< TACRDiskStoredFunctionManager.Save' + #13#10 +
        'FHeader.Count = ' + IntToStr(FHeader.Count)
        + #13#10 + 'FHeader.State = ' + IntToStr(FHeader.State)
        + #13#10 + 'FNotLoaded = ' + BoolToStr(FNotLoaded,
        True) + #13#10 + 'FState = ' + IntToStr(FState));
  except
    on e: Exception do
    begin
      aaWriteToLog('Error in TACRDiskStoredFunctionManager.Save:' + #13#10 +
          e.Message);
      raise ;
    end;
  end;
{$ENDIF}
end; // Save

//------------------------------------------------------------------------------
// create stored function
//------------------------------------------------------------------------------
procedure TACRDiskStoredFunctionManager.InternalCreateStoredFunction
  (StoredFunction: TACRStoredFunction; SQLScript: WideString);
begin
  try
    if (not LPageManager.LockStoredFunctionManager(True)) then
      raise EACRException.Create(12301, ErrorLCannotLockStoredFunctionManager,
        [LPageManager.DatabaseFileName]);
    try
      Load(False, False);
      inherited InternalCreateStoredFunction(StoredFunction, SQLScript);
      Save;
    finally
      LPageManager.UnlockStoredFunctionManager;
    end;
  except
    FNotLoaded := True;
    raise ;
  end;
end; // InternalCreateStoredFunction

//------------------------------------------------------------------------------
// drop stored function
//------------------------------------------------------------------------------
procedure TACRDiskStoredFunctionManager.InternalDropStoredFunction
  (FunctionName: WideString);
begin
  if (not LPageManager.LockStoredFunctionManager(True)) then
    raise EACRException.Create(12302, ErrorLCannotLockStoredFunctionManager,
      [LPageManager.DatabaseFileName]);
  try
    try
      Load(False, False);
    except
      FNotLoaded := True;
      raise ;
    end;
    inherited InternalDropStoredFunction(FunctionName);
    try
      Save;
    except
      FNotLoaded := True;
      raise ;
    end;
  finally
    LPageManager.UnlockStoredFunctionManager;
  end;
end; // InternalDropStoredFunction

//------------------------------------------------------------------------------
// ALTER stored function
//------------------------------------------------------------------------------
procedure TACRDiskStoredFunctionManager.InternalAlterStoredFunction
  (Session: TACRBaseSession; FunctionName, NewSQLScript: WideString);
begin
  if (not LPageManager.LockStoredFunctionManager(True)) then
    raise EACRException.Create(12303, ErrorLCannotLockStoredFunctionManager,
      [LPageManager.DatabaseFileName]);
  try
    try
      Load(False, False);
    except
      FNotLoaded := True;
      raise ;
    end;
    inherited InternalAlterStoredFunction(Session, FunctionName, NewSQLScript);
    try
      Save;
    except
      FNotLoaded := True;
      raise ;
    end;
  finally
    LPageManager.UnlockStoredFunctionManager;
  end;
end; // InternalAlterStoredFunction

//------------------------------------------------------------------------------
// ALTER stored function - rename
//------------------------------------------------------------------------------
procedure TACRDiskStoredFunctionManager.InternalAlterStoredFunctionRename
  (Session: TACRBaseSession; FunctionName, NewFunctionName: WideString);
begin
  if (not LPageManager.LockStoredFunctionManager(True)) then
    raise EACRException.Create(12304, ErrorLCannotLockStoredFunctionManager,
      [LPageManager.DatabaseFileName]);
  try
    try
      Load(False, False);
    except
      FNotLoaded := True;
      raise ;
    end;
    inherited InternalAlterStoredFunctionRename(Session, FunctionName,
      NewFunctionName);
    try
      Save;
    except
      FNotLoaded := True;
      raise ;
    end;
  finally
    LPageManager.UnlockStoredFunctionManager;
  end;
end; // InternalAlterStoredFunctionRename

//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRDiskStoredFunctionManager.Create
  (DatabaseData: TACRDatabaseData; bCreate: Boolean;
  var StartPageNo: TACRPageNo);
begin
  inherited Create(DatabaseData);
  LPageManager := TACRDiskPageManager(TACRDiskDatabaseData(LDatabaseData)
      .PageManager);
  FHandle := TACRInternalDBFile.Create(LPageManager,
    ACRPageTypeIDStoredFunctionManager, INVALID_OBJECT_ID, False, False, nil);
  if (bCreate) then
  begin
    FHandle.CreateFile(0, INVALID_SESSION_ID, dbstNone, 0);
    LPageManager.SaveSFMHeader(FHeader);
    StartPageNo := FHandle.StartPageNo;
    FNotLoaded := False;
  end
  else
  begin
    FHandle.OpenFile(StartPageNo);
    FNotLoaded := True;
  end;
end; // Create

//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRDiskStoredFunctionManager.Destroy;
begin
  if (FHandle <> nil) then
    try
      FreeAndNil(FHandle);
    except
    end;
  inherited;
end; // Destroy

//------------------------------------------------------------------------------
// for calls from TACRDatabase.ExecuteStoredFunction
// execute stored function - return false if function does not exist
// if function has no result (procedure) ResultValue will be set to nil
// params - list of TACRSQLParam
//------------------------------------------------------------------------------
function TACRDiskStoredFunctionManager.ExecuteStoredFunction
  (Session: TACRBaseSession; FunctionName: WideString;
  ResultValue: TACRVariant; Params: TACRSQLParams): Boolean;
begin
  // modified in v.5.80 to avoid problems with nested functions
  if (FNotLoaded) then
    Load(True, True);
  Result := inherited ExecuteStoredFunction(Session, FunctionName, ResultValue,
    Params);
end; // ExecuteStoredFunction


//------------------------------------------------------------------------------
// return empty string if function not found; otherwise return SQL script (CREATE FUNCTION...)
// return SQL script that created this function (CREATE FUNCTION ...)
//------------------------------------------------------------------------------
function TACRDiskStoredFunctionManager.FindStoredFunction(FunctionName: WideString): WideString;
begin
  Load(True, True);
  Result := inherited FindStoredFunction(FunctionName);
end; // FindStoredFunction


//------------------------------------------------------------------------------
// return the stored function object if it exists in stored function manager associated with
// the atabase opened by this session
// used by TACRExprNodeStoredFunction
//------------------------------------------------------------------------------
function TACRDiskStoredFunctionManager.GetStoredFunctionByName(FunctionName: WideString; Session: TACRBaseSession): TObject;
begin
  if (FNotLoaded) then
    Load(True, True);
  Result := inherited GetStoredFunctionByName(FunctionName,Session);
end; // GetStoredFunctionByName


//------------------------------------------------------------------------------
// parse for execute - from SQL engine (EXECUTE FUNCTION / expression, like FunctionName(Params))
// return stored function object (TACRStoredFunction) if found or nil
// params - list of TACRExpression
//------------------------------------------------------------------------------
function TACRDiskStoredFunctionManager.ParseStoredFunctionParams(
                Session: TACRBaseSession; Lexer: TACRLexer; parentFunction: TObject;
                var Token: TToken; out Params: TObject
                                                                ): TObject;
begin
  // modified in v.5.80 to avoid problems with nested functions
  if (FNotLoaded) then
    Load(True, True);
  Result := inherited ParseStoredFunctionParams(Session, Lexer, parentFunction,
    Token, Params);
end; // ParseStoredFunctionParams


//------------------------------------------------------------------------------
// return list of stored function names (optionally SQL scripts for their creation)
//------------------------------------------------------------------------------
procedure TACRDiskStoredFunctionManager.GetStoredFunctions(FunctionNames: TStrings; FunctionSQLScripts: TStrings = nil;
  SortNamesByAlphabet: Boolean = True);
begin
  Load(True, True);
  inherited GetStoredFunctions(FunctionNames, FunctionSQLScripts,
    SortNamesByAlphabet);
end; // GetStoredFunctions

//------------------------------------------------------------------------------
// return list of stored function names (optionally SQL scripts for their creation)
//------------------------------------------------------------------------------
procedure TACRDiskStoredFunctionManager.GetStoredFunctions
  (FunctionNames: TACRWideStringList;
  FunctionSQLScripts: TACRWideStringList = nil;
  SortNamesByAlphabet: Boolean = True);
begin
  Load(True, True);
  inherited GetStoredFunctions(FunctionNames, FunctionSQLScripts,
    SortNamesByAlphabet);
end; // GetStoredFunctions

//------------------------------------------------------------------------------
// export all stored functions to SQL
//------------------------------------------------------------------------------
procedure TACRDiskStoredFunctionManager.ExportStoredFunctionsToSQL
  (var SQL: WideString);
begin
  Load(True, True);
  inherited ExportStoredFunctionsToSQL(SQL);
end; // ExportStoredFunctionsToSQL

///////////////////////////////////////////////////////////////////////////////
//
// TACRTableLockFile
//
// LockX:               Byte;     // reserved to lock byte
// LockIRW:             Byte;     // reserved to lock byte
// LockRW:              Byte;     // reserved to lock byte
// TACRTableLockFileHeader = packed record
// MaxSessionID:        Cardinal; // for fast lock check
// IRWMaxWaitLevel:     Byte;
// RWMaxWaitLevel:      Byte;
// SMaxWaitLevel:       Byte;
// end;
// +----------+---------+---------+-------------------+------------+
// | IS locks | S locks | U locks | U max wait levels | U RecordID |
// +----------+---------+---------+-------------------+------------+
//
///////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// return number of start page
//------------------------------------------------------------------------------
function TACRTableLockFile.GetStartPageNo: TACRPageNo;
begin
  if (FHandle = nil) then
    raise EACRException.Create(10483, ErrorLNilPointer);
  Result := FHandle.StartPageNo;
end; // GetStartPageNo

//------------------------------------------------------------------------------
// return Max Sessions Count
//------------------------------------------------------------------------------
function TACRTableLockFile.GetMaxSessionCount: Cardinal;
begin
  // 3 bytes per table  - X, IRW, RW - only single session per table
  // 4 bytes per each session - IS, S, U, U wait level
  Result := Cardinal
    ((FHandle.Size - SizeOf(FHeader) - ACRTableLockedBytesCount) div
      (4 + SizeOf(TACRRecordID)));
end; // GetMaxSessionCount

//------------------------------------------------------------------------------
// return file size to create
//------------------------------------------------------------------------------
function TACRTableLockFile.GetFileSize(MaxSessionCount: Cardinal): Cardinal;
begin
  // n bytes per table  - X, IRW, RW - only single session per table
  // 4 bytes per each session - IS, S, U, U wait level
  Result := Cardinal(SizeOf(FHeader) + ACRTableLockedBytesCount +
      FMaxSessionCount * (4 + SizeOf(TACRRecordID)));
end; // GetFileSize

//------------------------------------------------------------------------------
// return number of byte for lock / unlock /is locked operations
//------------------------------------------------------------------------------
function TACRTableLockFile.GetByteNo(SessionID: TACRSessionID;
  LockType: TACRLockType; bRecordID: Boolean = False;
  bWaitLockU: Boolean = False): Cardinal;
begin
  case LockType of
    ltX:
      Result := 0;
    ltIRW:
      Result := 1;
    ltRW:
      Result := 2;
    ltIS:
      Result := FHeaderOffset + SizeOf(FHeader) + SessionID;
    ltS:
      Result := FHeaderOffset + SizeOf(FHeader) + FMaxSessionCount + SessionID;
  else
    begin
      // ltU
      if (bRecordID) then
        // offset to RecordID
        Result := FHeaderOffset + SizeOf(FHeader)
          + 4 * FMaxSessionCount + SessionID * SizeOf(TACRRecordID)
      else if (bWaitLockU) then
        // offset to max wait level for ltU
        Result := FHeaderOffset + SizeOf(FHeader)
          + 3 * FMaxSessionCount + SessionID
      else
        // offset to lock byet for ltU
        Result := FHeaderOffset + SizeOf(FHeader)
          + 2 * FMaxSessionCount + SessionID;
    end;
  end;
end; // GetByteNo

//------------------------------------------------------------------------------
// load header
//------------------------------------------------------------------------------
procedure TACRTableLockFile.LoadHeader;
begin
  if (LPageManager.ReadOnly) then
  begin
    // scan
    FHeader.MinSessionID := 0;
    FHeader.MaxSessionID := LPageManager.DBHeader.MaxSessionCount - 1;
  end
  else
    FHandle.DirectReadBuffer(FHeader, SizeOf(FHeader), FHeaderOffset, True)
end; // LoadHeader

//------------------------------------------------------------------------------
// save header
//------------------------------------------------------------------------------
procedure TACRTableLockFile.SaveHeader;
begin
  if (not LPageManager.ReadOnly) then
    FHandle.DirectWriteBuffer(FHeader, SizeOf(FHeader), FHeaderOffset, True);
end; // SaveHeader

//------------------------------------------------------------------------------
// fill data for U lock
//------------------------------------------------------------------------------
procedure TACRTableLockFile.FillDataForLockU;
var
  n: Cardinal;
  buf: PAnsiChar;
begin
  if (not LPageManager.ReadOnly) then
  begin
    n := FMaxSessionCount * (SizeOf(TACRRecordID) + 1);
    // fill wait level for ltU with $00
    buf := MemoryManager.AllocMem(n);
    try
      // fill RecordID for ltU with $FF
      FillChar(PAnsiChar(buf + FMaxSessionCount)^, (n - FMaxSessionCount), $FF);
      FHandle.DirectWriteBuffer(buf^, n, GetByteNo(0, ltU, False, True), True);
    finally
      MemoryManager.FreeAndNilMem(buf);
    end;
  end;
end; // FillDataForLockU

//------------------------------------------------------------------------------
// return true if we cannot lock table because of more priority sessions
// are already waiiting it
//------------------------------------------------------------------------------
function TACRTableLockFile.IsMorePriorityLockExists
  (PSessionLockInfo: PACRSessionLockInfo; WaitLevel: Byte): Boolean;
var
  n: Cardinal;
  CurWaitLevel: Byte;
  RecordID: TACRRecordID;
begin
{$IFDEF DEBUG_TRACE_TACRTableLockFile_IsMorePriorityLockExists}
  aaWriteToLog('> TACRTableLockFile.IsMorePriorityLockExists' + #13#10 +
      'WaitLevel = ' + IntToStr(WaitLevel) + #13#10 + 'Result = ' + BoolToStr
      (Result, True));
{$ENDIF}
  Result := (FHeader.RWMaxWaitLevel > WaitLevel);
  if (not Result) then
  begin
    // changed in v.5.60 - if we already applied any lock we should not check other sessions priority
    if (PSessionLockInfo^.WaitLockType = ltRW) then
      Result := (PSessionLockInfo^.NumLocksIRW = 0) and
        (PSessionLockInfo^.NumLocksS = 0) and
        ((FHeader.RWMaxWaitLevel > WaitLevel) or
          (FHeader.IRWMaxWaitLevel > WaitLevel) or
          (FHeader.SMaxWaitLevel > WaitLevel))
    else if (PSessionLockInfo^.WaitLockType = ltIRW) then
      Result := (PSessionLockInfo^.NumLocksIRW = 0) and
        (PSessionLockInfo^.NumLocksS = 0) and
        ((FHeader.RWMaxWaitLevel > WaitLevel) or
          (FHeader.IRWMaxWaitLevel > WaitLevel))
    else if (PSessionLockInfo^.WaitLockType = ltS) then
      Result := (PSessionLockInfo^.NumLocksIRW = 0) and
        (PSessionLockInfo^.NumLocksS = 0) and
        (FHeader.RWMaxWaitLevel > WaitLevel)
    else if (PSessionLockInfo^.WaitLockType = ltU) then
    begin
      for n := FHeader.MinSessionID to FHeader.MaxSessionID do
        if (TACRSessionID(n) <> PSessionLockInfo^.SessionID) then
        begin
          FHandle.DirectReadBuffer(CurWaitLevel, SizeOf(CurWaitLevel),
            GetByteNo(TACRSessionID(n), ltU, False, True), True);
          if (CurWaitLevel > WaitLevel) then
          begin
            FHandle.DirectReadBuffer(RecordID, SizeOf(RecordID),
              GetByteNo(TACRSessionID(n), ltU, True, False), True);
            if ((RecordID.PageNo = PSessionLockInfo^.LockedRecordID.PageNo) and
                (RecordID.PageItemNo =
                  PSessionLockInfo^.LockedRecordID.PageItemNo)) then
            begin
              Result := True;
              break;
            end;
          end;
        end; // if n <> PSessionLockInfo^.SessionID
    end;
  end;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_IsMorePriorityLockExists}
  aaWriteToLog('< TACRTableLockFile.IsMorePriorityLockExists' + #13#10 +
      'Result = ' + BoolToStr(Result, True));
{$ENDIF}
end; // IsMorePriorityLockExists
{$IFDEF NEW_FILE_SERVER_LOCKING}

//------------------------------------------------------------------------------
// lock X
//------------------------------------------------------------------------------
function TACRTableLockFile.InternalLockX(PSessionLockInfo: PACRSessionLockInfo)
  : Boolean;
begin
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockX}
  aaWriteToLog('> TACRTableLockFile.InternalLockX');
  ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
  try
{$ENDIF}
    if (PSessionLockInfo^.NumLocksIS = 0) then
    begin
      Result := not FHandle.IsRegionLocked(GetByteNo(0, ltIS),
        Integer(FMaxSessionCount));
    end
    else
    begin
      if (PSessionLockInfo^.SessionID = 0) then
        Result := not FHandle.IsRegionLocked(GetByteNo(1, ltIS),
          Integer(FLastSessionNo))
      else if (PSessionLockInfo^.SessionID = FLastSessionNo) then
        Result := not FHandle.IsRegionLocked(GetByteNo(0, ltIS),
          Integer(FLastSessionNo))
      else
      begin
        Result := not FHandle.IsRegionLocked(GetByteNo(0, ltIS),
          Integer(PSessionLockInfo^.SessionID));
        if (Result) then
          Result := not FHandle.IsRegionLocked
            (GetByteNo(PSessionLockInfo^.SessionID + 1, ltIS),
            Integer(FLastSessionNo) - Integer(PSessionLockInfo^.SessionID));
      end;
    end;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockX}
    aaWriteToLog('1. TACRTableLockFile.InternalLockX FMaxSessionCount = ' +
        IntToStr(FMaxSessionCount) + #13#10 + 'Result = ' + BoolToStr(Result,
        True));
{$ENDIF}
    if (Result) then
    begin
      Result := FHandle.LockByte(GetByteNo(0, ltX));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockX}
      aaWriteToLog('2. Result = ' + BoolToStr(Result, True));
{$ENDIF}
    end;
    if (Result) then
    begin
      // reset all locks - first opening in X
      FillChar(FHeader, SizeOf(FHeader), $00);
      FHeader.MaxSessionID := Cardinal(INVALID_SESSION_ID);
      FHeader.MinSessionID := Cardinal(INVALID_SESSION_ID);
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockX}
      aaWriteToLog('3');
{$ENDIF}
      SaveHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockX}
      aaWriteToLog('4');
{$ENDIF}
      FillDataForLockU;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockX}
      aaWriteToLog('5');
{$ENDIF}
    end;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockX}
    WriteHeaderToLog('< TACRTableLockFile.InternalLockX, Result = ' + BoolToStr
        (Result, True));
    ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
  except
    on e: Exception do
    begin
      WriteHeaderToLog('Error in TACRTableLockFile.InternalLockX:' + #13#10 +
          e.Message);
      ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
    end;
  end;
{$ENDIF}
end; // InternalLockX

//------------------------------------------------------------------------------
// lock IS
//------------------------------------------------------------------------------
function TACRTableLockFile.InternalLockIS(PSessionLockInfo: PACRSessionLockInfo)
  : Boolean;
begin
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
  aaWriteToLog('> TACRTableLockFile.InternalLockIS - FHandle = ' + IntToHex
      (Integer(FHandle), 8));
  ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
  try
{$ENDIF}
    Result := not FHandle.IsByteLocked(GetByteNo(0, ltX));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
    aaWriteToLog('1. TACRTableLockFile.InternalLockIS Result = ' + BoolToStr
        (Result, True));
{$ENDIF}
    if (Result) then
    begin
      Result := FHandle.LockByte(GetByteNo(PSessionLockInfo^.SessionID, ltIS));
    end;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
    aaWriteToLog('2. TACRTableLockFile.InternalLockIS Result = ' + BoolToStr
        (Result, True));
{$ENDIF}
    if (Result) then
    begin
      LoadHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
      aaWriteToLog('3. TACRTableLockFile.InternalLockIS');
{$ENDIF}
      if ((PSessionLockInfo^.SessionID > TACRSessionID(FHeader.MaxSessionID))
          or (PSessionLockInfo^.SessionID < TACRSessionID
            (FHeader.MinSessionID)) or
          (TACRSessionID(FHeader.MinSessionID) > TACRSessionID
            (FHeader.MaxSessionID)) or (TACRSessionID(FHeader.MinSessionID)
            = INVALID_SESSION_ID) or (TACRSessionID(FHeader.MaxSessionID)
            = INVALID_SESSION_ID)) then
      begin
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
        aaWriteToLog('4. TACRTableLockFile.InternalLockIS');
{$ENDIF}
        if ((TACRSessionID(FHeader.MinSessionID) > TACRSessionID
              (FHeader.MaxSessionID)) or (TACRSessionID(FHeader.MinSessionID)
              = INVALID_SESSION_ID) or (TACRSessionID(FHeader.MinSessionID)
              = INVALID_SESSION_ID)) then
        begin
          // first open of the table
          FillChar(FHeader, SizeOf(FHeader), $00);
          FHeader.MinSessionID := PSessionLockInfo^.SessionID;
          FHeader.MaxSessionID := PSessionLockInfo^.SessionID;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
          aaWriteToLog('5. TACRTableLockFile.InternalLockIS');
{$ENDIF}
          FillDataForLockU;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
          aaWriteToLog('6. TACRTableLockFile.InternalLockIS');
{$ENDIF}
        end
        else
        begin
          if (PSessionLockInfo^.SessionID > TACRSessionID(FHeader.MaxSessionID)
            ) then
            FHeader.MaxSessionID := PSessionLockInfo^.SessionID;
          if (PSessionLockInfo^.SessionID < TACRSessionID(FHeader.MinSessionID)
            ) then
            FHeader.MinSessionID := PSessionLockInfo^.SessionID;
        end;
        SaveHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
        aaWriteToLog('8. TACRTableLockFile.InternalLockIS');
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
        aaWriteToLog('5. TACRTableLockFile.InternalLockIS');
{$ENDIF}
      end; // update header
    end; // Result = true
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
    WriteHeaderToLog('< TACRTableLockFile.InternalLockIS, Result = ' + BoolToStr
        (Result, True));
    ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
  except
    on e: Exception do
    begin
      WriteHeaderToLog
        ('Error in TACRTableLockFile.InternalLockIS:' + #13#10 + e.Message);
      ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
    end;
  end;
{$ENDIF}
end; // InternalLockIS

//------------------------------------------------------------------------------
// lock S
//------------------------------------------------------------------------------
function TACRTableLockFile.InternalLockS(PSessionLockInfo: PACRSessionLockInfo)
  : Boolean;
var
  WaitLevel: Byte;
begin
{$IFDEF DEBUG_LOCK_TIMES}
  aaStartTime(time17);
  aaIncCounter(counter17);
  try
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
    aaWriteToLog('> TACRTableLockFile.InternalLockS - FHandle = ' + IntToHex
        (Integer(FHandle), 8));
    ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
    try
{$ENDIF}
      LoadHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
      WriteHeaderToLog('0. TACRTableLockFile.InternalLockS - LoadHeader:');
{$ENDIF}
      WaitLevel := ACRGetWaitLevel(PSessionLockInfo^.WaitTime, FMaxWaitTime);
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
      aaWriteToLog('1. TACRTableLockFile.InternalLockS - WaitLevel = ' +
          IntToStr(WaitLevel));
{$ENDIF}
      Result := not IsMorePriorityLockExists(PSessionLockInfo, WaitLevel);
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
      aaWriteToLog('2. TACRTableLockFile.InternalLockS - Result = ' + BoolToStr
          (Result, True));
{$ENDIF}
      if (Result) then
        Result := not FHandle.IsByteLocked(GetByteNo(0, ltRW));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
      aaWriteToLog('3. TACRTableLockFile.InternalLockS - Result = ' + BoolToStr
          (Result, True));
{$ENDIF}
      if (Result) then
        Result := FHandle.LockByte(GetByteNo(PSessionLockInfo^.SessionID, ltS));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
      aaWriteToLog('4. TACRTableLockFile.InternalLockS - Result = ' + BoolToStr
          (Result, True));
{$ENDIF}
      if (Result) then
      begin
        if (FHeader.SMaxWaitLevel > 0) then
        begin
          FHeader.SMaxWaitLevel := 0;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
          aaWriteToLog('5. TACRTableLockFile.InternalLockS - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
          SaveHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
          aaWriteToLog('6. TACRTableLockFile.InternalLockS - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
        end;
      end
      else
      begin
        if (WaitLevel > FHeader.SMaxWaitLevel) then
        begin
          FHeader.SMaxWaitLevel := WaitLevel;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
          aaWriteToLog('7. TACRTableLockFile.InternalLockS - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
          SaveHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
          aaWriteToLog('8. TACRTableLockFile.InternalLockS - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
        end;
      end;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
      WriteHeaderToLog('< TACRTableLockFile.InternalLockS, Result = ' +
          BoolToStr(Result, True));
      ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
    except
      on e: Exception do
      begin
        WriteHeaderToLog
          ('Error in TACRTableLockFile.InternalLockS:' + #13#10 + e.Message);
        ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
      end;
    end;
{$ENDIF}
{$IFDEF DEBUG_LOCK_TIMES}
  finally
    // if (not Result) then
    // aaIncCounter(counter19);
    aaStopTime(time17);
  end;
{$ENDIF}
end; // InternalLockS

//------------------------------------------------------------------------------
// lock IRW
//------------------------------------------------------------------------------
function TACRTableLockFile.InternalLockIRW
  (PSessionLockInfo: PACRSessionLockInfo): Boolean;
var
  WaitLevel: Byte;
begin
{$IFDEF DEBUG_LOCK_TIMES}
  aaStartTime(time16);
  aaIncCounter(counter16);
  try
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
    aaWriteToLog('> TACRTableLockFile.InternalLockIRW - FHandle = ' + IntToHex
        (Integer(FHandle), 8));
    ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
    try
{$ENDIF}
      LoadHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
      WriteHeaderToLog('0. TACRTableLockFile.InternalLockIRW - LoadHeader:');
{$ENDIF}
      WaitLevel := ACRGetWaitLevel(PSessionLockInfo^.WaitTime, FMaxWaitTime);
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
      aaWriteToLog('1. TACRTableLockFile.InternalLockIRW - WaitLevel = ' +
          IntToStr(WaitLevel));
{$ENDIF}
      Result := not IsMorePriorityLockExists(PSessionLockInfo, WaitLevel);
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
      aaWriteToLog('2. TACRTableLockFile.InternalLockIRW - Result = ' +
          BoolToStr(Result, True));
{$ENDIF}
      if (Result) then
        Result := not FHandle.IsByteLocked(GetByteNo(0, ltRW));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
      aaWriteToLog('3. TACRTableLockFile.InternalLockIRW - Result = ' +
          BoolToStr(Result, True));
{$ENDIF}
      if (Result) then
        Result := not FHandle.IsByteLocked(GetByteNo(0, ltIRW));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
      aaWriteToLog('4. TACRTableLockFile.InternalLockIRW - Result = ' +
          BoolToStr(Result, True));
{$ENDIF}
      if (Result and (PSessionLockInfo^.NumLocksIRW = 0)) then
        Result := FHandle.LockByte(GetByteNo(0, ltIRW));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
      aaWriteToLog('5. TACRTableLockFile.InternalLockIRW - Result = ' +
          BoolToStr(Result, True));
{$ENDIF}
      if (Result) then
      begin
        if (FHeader.IRWMaxWaitLevel > 0) then
        begin
          FHeader.IRWMaxWaitLevel := 0;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
          aaWriteToLog('6. TACRTableLockFile.InternalLockIRW - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
          SaveHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
          aaWriteToLog('7. TACRTableLockFile.InternalLockIRW - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
        end;
      end
      else
      begin
        if (WaitLevel > FHeader.IRWMaxWaitLevel) then
        begin
          FHeader.IRWMaxWaitLevel := WaitLevel;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
          aaWriteToLog('8. TACRTableLockFile.InternalLockIRW - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
          SaveHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
          aaWriteToLog('9. TACRTableLockFile.InternalLockIRW - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
        end;
      end;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
      WriteHeaderToLog('< TACRTableLockFile.InternalLockIRW, Result = ' +
          BoolToStr(Result, True));
      ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
    except
      on e: Exception do
      begin
        WriteHeaderToLog
          ('Error in TACRTableLockFile.InternalLockIRW:' + #13#10 +
            e.Message);
        ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
      end;
    end;
{$ENDIF}
{$IFDEF DEBUG_LOCK_TIMES}
  finally
    if (not Result) then
      aaIncCounter(counter1);
    aaStopTime(time16);
  end;
{$ENDIF}
end; // InternalLockIRW

//------------------------------------------------------------------------------
// lock RW
//------------------------------------------------------------------------------
function TACRTableLockFile.InternalLockRW(PSessionLockInfo: PACRSessionLockInfo)
  : Boolean;
var
  WaitLevel: Byte;
begin
{$IFDEF DEBUG_LOCK_TIMES}
  aaStartTime(time15);
  aaIncCounter(counter15);
  try
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
    aaWriteToLog('> TACRTableLockFile.InternalLockRW - FHandle = ' + IntToHex
        (Integer(FHandle), 8));
    ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
    try
{$ENDIF}
      LoadHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
      WriteHeaderToLog('0. TACRTableLockFile.InternalLockRW - LoadHeader:');
{$ENDIF}
      WaitLevel := ACRGetWaitLevel(PSessionLockInfo^.WaitTime, FMaxWaitTime);
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
      aaWriteToLog('1. TACRTableLockFile.InternalLockRW - WaitLevel = ' +
          IntToStr(WaitLevel));
{$ENDIF}
      Result := not IsMorePriorityLockExists(PSessionLockInfo, WaitLevel);
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
      aaWriteToLog('2. TACRTableLockFile.InternalLockRW - Result = ' + BoolToStr
          (Result, True));
{$ENDIF}
      if (Result) then
        Result := not FHandle.IsByteLocked(GetByteNo(0, ltRW));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
      aaWriteToLog('3. TACRTableLockFile.InternalLockRW - Result = ' + BoolToStr
          (Result, True));
{$ENDIF}
      if (Result and (PSessionLockInfo^.NumLocksIRW = 0)) then
        Result := not FHandle.IsByteLocked(GetByteNo(0, ltIRW));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
      aaWriteToLog('4. TACRTableLockFile.InternalLockRW - Result = ' + BoolToStr
          (Result, True));
{$ENDIF}
      if (Result) then
      begin
        // check S lock
        if (FHeader.MinSessionID = FHeader.MaxSessionID) then
        begin
          // single session connected
          Result := (FHeader.MinSessionID = PSessionLockInfo^.SessionID);
        end
        else if (PSessionLockInfo^.NumLocksS = 0) then
        begin
          // the session has no own S locks - check all range
          Result := not FHandle.IsRegionLocked(GetByteNo(FHeader.MinSessionID,
              ltS), Integer(FHeader.MaxSessionID) - Integer
              (FHeader.MinSessionID) + 1);
        end
        else if (PSessionLockInfo^.SessionID = FHeader.MinSessionID) then
        begin
          Result := not FHandle.IsRegionLocked
            (GetByteNo(FHeader.MinSessionID + 1, ltS),
            Integer(FHeader.MaxSessionID) - Integer(FHeader.MinSessionID));
        end
        else if (PSessionLockInfo^.SessionID = FHeader.MaxSessionID) then
        begin
          Result := not FHandle.IsRegionLocked(GetByteNo(FHeader.MinSessionID,
              ltS), Integer(FHeader.MaxSessionID) - Integer
              (FHeader.MinSessionID));
        end
        else
        begin
          // MinSessionID ... SessionID ... MaxSessionID
          Result := not FHandle.IsRegionLocked(GetByteNo(FHeader.MinSessionID,
              ltS), Integer(PSessionLockInfo^.SessionID) - Integer
              (FHeader.MinSessionID));
          if (Result) then
          begin
            Result := not FHandle.IsRegionLocked
              (GetByteNo(PSessionLockInfo^.SessionID + 1, ltS),
              Integer(FHeader.MaxSessionID) - Integer
                (PSessionLockInfo^.SessionID));
          end;
        end;
      end; // check S lock
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
      aaWriteToLog('5. TACRTableLockFile.InternalLockRW - Result = ' + BoolToStr
          (Result, True));
{$ENDIF}
      if (Result) then
        Result := FHandle.LockByte(GetByteNo(0, ltRW));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
      aaWriteToLog('6. TACRTableLockFile.InternalLockRW - Result = ' + BoolToStr
          (Result, True));
{$ENDIF}
      if (Result) then
      begin
        if (FHeader.RWMaxWaitLevel > 0) then
        begin
          FHeader.RWMaxWaitLevel := 0;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
          aaWriteToLog('7. TACRTableLockFile.InternalLockRW - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
          SaveHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
          aaWriteToLog('8. TACRTableLockFile.InternalLockRW - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
        end;
      end
      else
      begin
        if (WaitLevel > FHeader.RWMaxWaitLevel) then
        begin
          FHeader.RWMaxWaitLevel := WaitLevel;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
          aaWriteToLog('9. TACRTableLockFile.InternalLockRW - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
          SaveHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
          aaWriteToLog('10. TACRTableLockFile.InternalLockRW - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
        end;
      end;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
      WriteHeaderToLog('< TACRTableLockFile.InternalLockRW, Result = ' +
          BoolToStr(Result, True));
      ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
    except
      on e: Exception do
      begin
        WriteHeaderToLog
          ('Error in TACRTableLockFile.InternalLockRW:' + #13#10 + e.Message);
        ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
      end;
    end;
{$ENDIF}
{$IFDEF DEBUG_LOCK_TIMES}
  finally
    if (not Result) then
      aaIncCounter(counter18);
    aaStopTime(time15);
  end;
{$ENDIF}
end; // InternalLockRW
{$ELSE}

//------------------------------------------------------------------------------
// lock X
//------------------------------------------------------------------------------
function TACRTableLockFile.InternalLockX(PSessionLockInfo: PACRSessionLockInfo)
  : Boolean;
var
  n: Cardinal;
begin
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockX}
  aaWriteToLog('> TACRTableLockFile.InternalLockX');
  ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
  try
{$ENDIF}
    for n := 0 to FLastSessionNo do
    begin
      if (n = PSessionLockInfo^.SessionID) then
        continue;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockX}
      aaWriteToLog('2.1 TACRTableLockFile.InternalLockX FLastSessionNo = ' +
          IntToStr(FLastSessionNo) + ', n = ' + IntToStr(n));
{$ENDIF}
      Result := not FHandle.IsByteLocked(GetByteNo(TACRSessionID(n), ltIS));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockX}
      aaWriteToLog('2.2 TACRTableLockFile.InternalLockX FLastSessionNo = ' +
          IntToStr(FLastSessionNo) + ', n = ' + IntToStr(n)
          + #13#10 + 'Result = ' + BoolToStr(Result, True));
{$ENDIF}
      if (not Result) then
        Exit;
    end;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockX}
    aaWriteToLog('1');
{$ENDIF}
    Result := FHandle.LockByte(GetByteNo(0, ltX));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockX}
    aaWriteToLog('2. Result = ' + BoolToStr(Result, True));
{$ENDIF}
    if (Result) then
    begin
      // reset all wait levels - first opening in X
      FillChar(FHeader, SizeOf(FHeader), $00);
      // FHeader.MaxSessionID := PSessionLockInfo^.SessionID;
      // FHeader.MinSessionID := PSessionLockInfo^.SessionID;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockX}
      aaWriteToLog('3');
{$ENDIF}
      SaveHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockX}
      aaWriteToLog('4');
{$ENDIF}
      FillDataForLockU;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockX}
      aaWriteToLog('5');
{$ENDIF}
    end;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockX}
    WriteHeaderToLog('< TACRTableLockFile.InternalLockX, Result = ' + BoolToStr
        (Result, True));
    ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
  except
    on e: Exception do
    begin
      WriteHeaderToLog('Error in TACRTableLockFile.InternalLockX:' + #13#10 +
          e.Message);
      ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
    end;
  end;
{$ENDIF}
end; // InternalLockX

//------------------------------------------------------------------------------
// lock IS
//------------------------------------------------------------------------------
function TACRTableLockFile.InternalLockIS(PSessionLockInfo: PACRSessionLockInfo)
  : Boolean;
var
  n: Cardinal;
  MaxSessionID: TACRSessionID;
  MinSessionID: TACRSessionID;
  bExists, bSave: Boolean;
begin
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
  aaWriteToLog('> TACRTableLockFile.InternalLockIS - FHandle = ' + IntToHex
      (Integer(FHandle), 8));
  ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
  try
{$ENDIF}
    Result := not FHandle.IsByteLocked(GetByteNo(0, ltX));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
    aaWriteToLog('1. TACRTableLockFile.InternalLockIS Result = ' + BoolToStr
        (Result, True));
{$ENDIF}
    MaxSessionID := PSessionLockInfo^.SessionID;
    MinSessionID := MaxSessionID;
    if (Result) then
      Result := FHandle.LockByte(GetByteNo(MaxSessionID, ltIS));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
    aaWriteToLog('2. TACRTableLockFile.InternalLockIS Result = ' + BoolToStr
        (Result, True));
{$ENDIF}
    if (Result) then
    begin
      bExists := False;
      for n := 0 to FLastSessionNo do
      begin
        if (n = PSessionLockInfo^.SessionID) then
          continue;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
        aaWriteToLog('2.1 TACRTableLockFile.InternalLockIS FLastSessionNo = ' +
            IntToStr(FLastSessionNo) + ', n = ' + IntToStr(n));
{$ENDIF}
        Result := FHandle.IsByteLocked(GetByteNo(TACRSessionID(n), ltIS));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
        aaWriteToLog('2.2 TACRTableLockFile.InternalLockIS FLastSessionNo = ' +
            IntToStr(FLastSessionNo) + ', n = ' + IntToStr(n)
            + #13#10 + 'Result = ' + BoolToStr(Result, True));
{$ENDIF}
        if (Result and (not bExists)) then
          bExists := True;
        if (Result) then
        begin
          if (n > MaxSessionID) then
            MaxSessionID := n;
          if (n < MinSessionID) then
            MinSessionID := n;
        end;
      end;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
      aaWriteToLog('3. TACRTableLockFile.InternalLockIS');
{$ENDIF}
      if (bExists) then
      begin
        LoadHeader;
        bSave := False;
        if (MaxSessionID > FHeader.MaxSessionID) then
        begin
          FHeader.MaxSessionID := MaxSessionID;
          bSave := True;
        end;
        if (MinSessionID < FHeader.MinSessionID) then
        begin
          FHeader.MinSessionID := MinSessionID;
          bSave := True;
        end;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
        aaWriteToLog('4. TACRTableLockFile.InternalLockIS');
{$ENDIF}
        if (bSave) then
          SaveHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
        aaWriteToLog('5. TACRTableLockFile.InternalLockIS');
{$ENDIF}
      end
      else
      begin
        // reset all wait levels - first opening in IS
        FillChar(FHeader, SizeOf(FHeader), $00);
        FHeader.MaxSessionID := MaxSessionID;
        FHeader.MinSessionID := MinSessionID;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
        aaWriteToLog('6. TACRTableLockFile.InternalLockIS');
{$ENDIF}
        SaveHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
        aaWriteToLog('7. TACRTableLockFile.InternalLockIS');
{$ENDIF}
        FillDataForLockU;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
        aaWriteToLog('8. TACRTableLockFile.InternalLockIS');
{$ENDIF}
      end;
      Result := True;
    end; // Result
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIS}
    WriteHeaderToLog('< TACRTableLockFile.InternalLockIS, Result = ' + BoolToStr
        (Result, True));
    ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
  except
    on e: Exception do
    begin
      WriteHeaderToLog
        ('Error in TACRTableLockFile.InternalLockIS:' + #13#10 + e.Message);
      ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
    end;
  end;
{$ENDIF}
end; // InternalLockIS

//------------------------------------------------------------------------------
// lock S
//------------------------------------------------------------------------------
function TACRTableLockFile.InternalLockS(PSessionLockInfo: PACRSessionLockInfo)
  : Boolean;
var
  WaitLevel: Byte;
begin
{$IFDEF DEBUG_LOCK_TIMES}
  aaStartTime(time17);
  aaIncCounter(counter17);
  try
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
    aaWriteToLog('> TACRTableLockFile.InternalLockS - FHandle = ' + IntToHex
        (Integer(FHandle), 8));
    ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
    try
{$ENDIF}
      LoadHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
      WriteHeaderToLog('0. TACRTableLockFile.InternalLockS - LoadHeader:');
{$ENDIF}
      WaitLevel := ACRGetWaitLevel(PSessionLockInfo^.WaitTime, FMaxWaitTime);
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
      aaWriteToLog('1. TACRTableLockFile.InternalLockS - WaitLevel = ' +
          IntToStr(WaitLevel));
{$ENDIF}
      Result := not IsMorePriorityLockExists(PSessionLockInfo, WaitLevel);
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
      aaWriteToLog('2. TACRTableLockFile.InternalLockS - Result = ' + BoolToStr
          (Result, True));
{$ENDIF}
      if (Result) then
        Result := not FHandle.IsByteLocked(GetByteNo(0, ltRW));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
      aaWriteToLog('3. TACRTableLockFile.InternalLockS - Result = ' + BoolToStr
          (Result, True));
{$ENDIF}
      if (Result) then
        Result := FHandle.LockByte(GetByteNo(PSessionLockInfo^.SessionID, ltS));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
      aaWriteToLog('4. TACRTableLockFile.InternalLockS - Result = ' + BoolToStr
          (Result, True));
{$ENDIF}
      if (Result) then
      begin
        if (WaitLevel >= FHeader.SMaxWaitLevel) and (WaitLevel > 0) then
        begin
          FHeader.SMaxWaitLevel := 0;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
          aaWriteToLog('5. TACRTableLockFile.InternalLockS - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
          SaveHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
          aaWriteToLog('6. TACRTableLockFile.InternalLockS - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
        end;
      end
      else
      begin
        if (WaitLevel > FHeader.SMaxWaitLevel) then
        begin
          FHeader.SMaxWaitLevel := WaitLevel;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
          aaWriteToLog('7. TACRTableLockFile.InternalLockS - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
          SaveHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
          aaWriteToLog('8. TACRTableLockFile.InternalLockS - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
        end;
      end;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockS}
      WriteHeaderToLog('< TACRTableLockFile.InternalLockS, Result = ' +
          BoolToStr(Result, True));
      ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
    except
      on e: Exception do
      begin
        WriteHeaderToLog
          ('Error in TACRTableLockFile.InternalLockS:' + #13#10 + e.Message);
        ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
      end;
    end;
{$ENDIF}
{$IFDEF DEBUG_LOCK_TIMES}
  finally
    // if (not Result) then
    // aaIncCounter(counter19);
    aaStopTime(time17);
  end;
{$ENDIF}
end; // InternalLockS

//------------------------------------------------------------------------------
// lock IRW
//------------------------------------------------------------------------------
function TACRTableLockFile.InternalLockIRW
  (PSessionLockInfo: PACRSessionLockInfo): Boolean;
var
  WaitLevel: Byte;
begin
{$IFDEF DEBUG_LOCK_TIMES}
  aaStartTime(time16);
  aaIncCounter(counter16);
  try
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
    aaWriteToLog('> TACRTableLockFile.InternalLockIRW - FHandle = ' + IntToHex
        (Integer(FHandle), 8));
    ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
    try
{$ENDIF}
      LoadHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
      WriteHeaderToLog('0. TACRTableLockFile.InternalLockIRW - LoadHeader:');
{$ENDIF}
      WaitLevel := ACRGetWaitLevel(PSessionLockInfo^.WaitTime, FMaxWaitTime);
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
      aaWriteToLog('1. TACRTableLockFile.InternalLockIRW - WaitLevel = ' +
          IntToStr(WaitLevel));
{$ENDIF}
      Result := not IsMorePriorityLockExists(PSessionLockInfo, WaitLevel);
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
      aaWriteToLog('2. TACRTableLockFile.InternalLockIRW - Result = ' +
          BoolToStr(Result, True));
{$ENDIF}
      if (Result) then
        Result := not FHandle.IsByteLocked(GetByteNo(0, ltRW));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
      aaWriteToLog('3. TACRTableLockFile.InternalLockIRW - Result = ' +
          BoolToStr(Result, True));
{$ENDIF}
      if (Result) then
        Result := not FHandle.IsByteLocked(GetByteNo(0, ltIRW));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
      aaWriteToLog('4. TACRTableLockFile.InternalLockIRW - Result = ' +
          BoolToStr(Result, True));
{$ENDIF}
      if (Result) then
        Result := FHandle.LockByte(GetByteNo(0, ltIRW));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
      aaWriteToLog('5. TACRTableLockFile.InternalLockIRW - Result = ' +
          BoolToStr(Result, True));
{$ENDIF}
      if (Result) then
      begin
        if (WaitLevel >= FHeader.IRWMaxWaitLevel) and (WaitLevel > 0) then
        begin
          FHeader.IRWMaxWaitLevel := 0;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
          aaWriteToLog('6. TACRTableLockFile.InternalLockIRW - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
          SaveHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
          aaWriteToLog('7. TACRTableLockFile.InternalLockIRW - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
        end;
      end
      else
      begin
        if (WaitLevel > FHeader.IRWMaxWaitLevel) then
        begin
          FHeader.IRWMaxWaitLevel := WaitLevel;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
          aaWriteToLog('8. TACRTableLockFile.InternalLockIRW - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
          SaveHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
          aaWriteToLog('9. TACRTableLockFile.InternalLockIRW - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
        end;
      end;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockIRW}
      WriteHeaderToLog('< TACRTableLockFile.InternalLockIRW, Result = ' +
          BoolToStr(Result, True));
      ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
    except
      on e: Exception do
      begin
        WriteHeaderToLog
          ('Error in TACRTableLockFile.InternalLockIRW:' + #13#10 +
            e.Message);
        ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
      end;
    end;
{$ENDIF}
{$IFDEF DEBUG_LOCK_TIMES}
  finally
    if (not Result) then
      aaIncCounter(counter1);
    aaStopTime(time16);
  end;
{$ENDIF}
end; // InternalLockIRW

//------------------------------------------------------------------------------
// lock RW
//------------------------------------------------------------------------------
function TACRTableLockFile.InternalLockRW(PSessionLockInfo: PACRSessionLockInfo)
  : Boolean;
var
  WaitLevel: Byte;
  start, n: Cardinal;
begin
{$IFDEF DEBUG_LOCK_TIMES}
  aaStartTime(time15);
  aaIncCounter(counter15);
  try
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
    aaWriteToLog('> TACRTableLockFile.InternalLockRW - FHandle = ' + IntToHex
        (Integer(FHandle), 8));
    ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
    try
{$ENDIF}
      LoadHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
      WriteHeaderToLog('0. TACRTableLockFile.InternalLockRW - LoadHeader:');
{$ENDIF}
      WaitLevel := ACRGetWaitLevel(PSessionLockInfo^.WaitTime, FMaxWaitTime);
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
      aaWriteToLog('1. TACRTableLockFile.InternalLockRW - WaitLevel = ' +
          IntToStr(WaitLevel));
{$ENDIF}
      Result := not IsMorePriorityLockExists(PSessionLockInfo, WaitLevel);
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
      aaWriteToLog('2. TACRTableLockFile.InternalLockRW - Result = ' + BoolToStr
          (Result, True));
{$ENDIF}
      if (Result) then
        Result := not FHandle.IsByteLocked(GetByteNo(0, ltRW));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
      aaWriteToLog('3. TACRTableLockFile.InternalLockRW - Result = ' + BoolToStr
          (Result, True));
{$ENDIF}
      if (Result and (PSessionLockInfo^.NumLocksIRW = 0)) then
        Result := not FHandle.IsByteLocked(GetByteNo(0, ltIRW));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
      aaWriteToLog('4. TACRTableLockFile.InternalLockRW - Result = ' + BoolToStr
          (Result, True));
{$ENDIF}
      if (Result) then
      begin
        // check S lock
        if (FHeader.MinSessionID = FHeader.MaxSessionID) then
        begin
          // single session connected
          Result := (FHeader.MinSessionID = PSessionLockInfo^.SessionID);
        end
        else if (PSessionLockInfo^.NumLocksS = 0) then
        begin
          // the session has no own S locks - check all range
          Result := not FHandle.IsRegionLocked(GetByteNo(FHeader.MinSessionID,
              ltS), FHeader.MaxSessionID - FHeader.MinSessionID + 1);
        end
        else if (PSessionLockInfo^.SessionID = FHeader.MinSessionID) then
        begin
          start := FHeader.MinSessionID + 1;
          n := FHeader.MaxSessionID - start + 1;
          Result := not FHandle.IsRegionLocked(GetByteNo(start, ltS), n);
        end
        else if (PSessionLockInfo^.SessionID = FHeader.MaxSessionID) then
        begin
          start := FHeader.MinSessionID;
          n := FHeader.MaxSessionID - start;
          Result := not FHandle.IsRegionLocked(GetByteNo(start, ltS), n);
        end
        else
        begin
          // MinSessionID ... SessionID ... MaxSessionID
          start := FHeader.MinSessionID;
          n := PSessionLockInfo^.SessionID - start;
          Result := not FHandle.IsRegionLocked(GetByteNo(start, ltS), n);
          if (Result) then
          begin
            start := PSessionLockInfo^.SessionID + 1;
            n := FHeader.MaxSessionID - start;
            Result := not FHandle.IsRegionLocked(GetByteNo(start, ltS), n);
          end;
        end;
      end; // check S lock
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
      aaWriteToLog('5. TACRTableLockFile.InternalLockRW - Result = ' + BoolToStr
          (Result, True));
{$ENDIF}
      if (Result) then
        Result := FHandle.LockByte(GetByteNo(0, ltRW));
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
      aaWriteToLog('6. TACRTableLockFile.InternalLockRW - Result = ' + BoolToStr
          (Result, True));
{$ENDIF}
      if (Result) then
      begin
        if (WaitLevel >= FHeader.RWMaxWaitLevel) and (WaitLevel > 0) then
        begin
          FHeader.RWMaxWaitLevel := 0;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
          aaWriteToLog('7. TACRTableLockFile.InternalLockRW - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
          SaveHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
          aaWriteToLog('8. TACRTableLockFile.InternalLockRW - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
        end;
      end
      else
      begin
        if (WaitLevel > FHeader.RWMaxWaitLevel) then
        begin
          FHeader.RWMaxWaitLevel := WaitLevel;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
          aaWriteToLog('9. TACRTableLockFile.InternalLockRW - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
          SaveHeader;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
          aaWriteToLog('10. TACRTableLockFile.InternalLockRW - Result = ' +
              BoolToStr(Result, True));
{$ENDIF}
        end;
      end;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_InternalLockRW}
      WriteHeaderToLog('< TACRTableLockFile.InternalLockRW, Result = ' +
          BoolToStr(Result, True));
      ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
    except
      on e: Exception do
      begin
        WriteHeaderToLog
          ('Error in TACRTableLockFile.InternalLockRW:' + #13#10 + e.Message);
        ACRWriteSessionLockInfo(PSessionLockInfo, FMaxWaitTime);
      end;
    end;
{$ENDIF}
{$IFDEF DEBUG_LOCK_TIMES}
  finally
    if (not Result) then
      aaIncCounter(counter18);
    aaStopTime(time15);
  end;
{$ENDIF}
end; // InternalLockRW
{$ENDIF}

//------------------------------------------------------------------------------
// lock U
//------------------------------------------------------------------------------
function TACRTableLockFile.InternalLockU(PSessionLockInfo: PACRSessionLockInfo)
  : Boolean;
var
  WaitLevel: Byte;
  CurWaitLevel: Byte;
  n: Cardinal;
  RecordID: TACRRecordID;
begin
  LoadHeader;
  WaitLevel := ACRGetWaitLevel(PSessionLockInfo^.WaitTime, FMaxWaitTime);
  // fixed in v.12.10
//  if (Result) then
  Result := not IsMorePriorityLockExists(PSessionLockInfo, WaitLevel);
  if (Result) then
  begin
    // check U lock
    for n := FHeader.MinSessionID to FHeader.MaxSessionID do
    begin
      if (n = PSessionLockInfo^.SessionID) then
        continue;
      if (FHandle.IsByteLocked(GetByteNo(TACRSessionID(n), ltU, False, False)))
        then
      begin
        FHandle.DirectReadBuffer(RecordID, SizeOf(RecordID),
          GetByteNo(n, ltU, True, False), True);
        if ((RecordID.PageNo = PSessionLockInfo^.LockedRecordID.PageNo) and
            (RecordID.PageItemNo = PSessionLockInfo^.LockedRecordID.PageItemNo)
          ) then
        begin
          Result := False;
          break;
        end;
      end;
    end;
  end;
  if (Result) then
    Result := FHandle.LockByte(GetByteNo(PSessionLockInfo^.SessionID, ltU,
        False, False));
  if (Result) then
  begin
    // save RecordID
    FHandle.DirectWriteBuffer(PSessionLockInfo^.LockedRecordID,
      SizeOf(TACRRecordID), GetByteNo(PSessionLockInfo^.SessionID, ltU, True,
        False), True);
    // reset wait level
    WaitLevel := 0;
    FHandle.DirectWriteBuffer(WaitLevel, SizeOf(WaitLevel),
      GetByteNo(PSessionLockInfo^.SessionID, ltU, False, True), True);
  end
  else
  begin
    FHandle.DirectReadBuffer(CurWaitLevel, SizeOf(WaitLevel),
      GetByteNo(PSessionLockInfo^.SessionID, ltU, False, True), True);
    if (WaitLevel > CurWaitLevel) then
      FHandle.DirectWriteBuffer(WaitLevel, SizeOf(WaitLevel),
        GetByteNo(PSessionLockInfo^.SessionID, ltU, False, True), True);
  end;
end; // InternalLockU
{$IFDEF DEBUG_LOG}

procedure TACRTableLockFile.WriteHeaderToLog(Caption: AnsiString);
begin
  aaWriteToLog(Caption + #13#10 + 'MinSessionID = ' + IntToStr
      (FHeader.MinSessionID) + #13#10 + 'MaxSessionID = ' + IntToStr
      (FHeader.MaxSessionID) + #13#10 + 'IRWMaxWaitLevel = ' + IntToStr
      (FHeader.IRWMaxWaitLevel) + #13#10 + 'RWMaxWaitLevel = ' + IntToStr
      (FHeader.RWMaxWaitLevel) + #13#10 + 'SMaxWaitLevel = ' + IntToStr
      (FHeader.SMaxWaitLevel) + #13#10 + 'FHandle = ' + IntToHex
      (Integer(FHandle), 8));
end; // WriteHeaderToLog
{$ENDIF}

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRTableLockFile.Create(PageManager: TACRPageManager;
  Cache: TACRCache; TableID: TACRTableID; MaxWaitTime: Cardinal);
begin
  LPageManager := TACRDiskPageManager(PageManager);
  FHandle := TACRInternalDBFile.Create(LPageManager,
    ACRPageTypeIDTableLocksFile,
    TACRObjectID(TableID), (Cache = nil), False, Cache);
  FMaxWaitTime := MaxWaitTime;
  FHeaderOffset := ACRTableLockedBytesCount;
  FillChar(FHeader, SizeOf(FHeader), $00);
end; // Create

//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRTableLockFile.Destroy;
begin
  if (FHandle <> nil) then
    FreeAndNil(FHandle);
  inherited;
end; // Destroy

//------------------------------------------------------------------------------
// OpenFile
//------------------------------------------------------------------------------
procedure TACRTableLockFile.OpenFile(aStartPageNo: TACRPageNo);
begin
{$IFDEF DEBUG_TRACE_TACRTableLockFile_OpenFile}
  aaWriteToLog('> TACRTableLockFile.OpenFile, StartPageNo = ' + IntToStr
      (aStartPageNo) + #13#10 + 'FHandle = ' + IntToHex(Integer(FHandle), 8));
{$ENDIF}
  FHandle.OpenFile(aStartPageNo);
  FHandle.LockFile(True);
  try
{$IFDEF DEBUG_TRACE_TACRTableLockFile_OpenFile}
    aaWriteToLog('1 TACRTableLockFile.OpenFile, StartPageNo = ' + IntToStr
        (aStartPageNo) + #13#10 + 'FHandle = ' + IntToHex(Integer(FHandle),
        8));
{$ENDIF}
    FHandle.ReadFile;
    FMaxSessionCount := GetMaxSessionCount;
    if (FMaxSessionCount = 0) then
      raise EACRException.Create(11890, ErrorLInvalidMaxSessionsCount,
        [FMaxSessionCount]);
    FLastSessionNo := FMaxSessionCount - 1;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_OpenFile}
    aaWriteToLog('2 TACRTableLockFile.OpenFile, StartPageNo = ' + IntToStr
        (aStartPageNo) + #13#10 + 'FHandle = ' + IntToHex(Integer(FHandle),
        8) + #13#10 + 'FHandle.Size = ' + IntToStr(FHandle.Size)
        + #13#10 + 'FMaxSessionCount = ' + IntToStr(FMaxSessionCount)
        + #13#10 + 'FLastSessionNo = ' + IntToStr(FLastSessionNo));
{$ENDIF}
  finally
    FHandle.UnlockFile(True);
  end;
{$IFDEF DEBUG_TRACE_TACRTableLockFile_OpenFile}
  aaWriteToLog('< TACRTableLockFile.OpenFile, StartPageNo = ' + IntToStr
      (aStartPageNo) + #13#10 + 'FHandle = ' + IntToHex(Integer(FHandle), 8));
{$ENDIF}
end; // OpenFile

//------------------------------------------------------------------------------
// CreateFile
//------------------------------------------------------------------------------
function TACRTableLockFile.CreateFile(SessionID: TACRSessionID;
  State: TACRState): TACRPageNo;
var
  FSize: Cardinal;
begin
  FMaxSessionCount := LPageManager.DBHeader.MaxSessionCount;
  if (FMaxSessionCount = 0) then
    raise EACRException.Create(11889, ErrorLInvalidMaxSessionsCount,
      [FMaxSessionCount]);
  FLastSessionNo := FMaxSessionCount - 1;
  FHandle.FStartPageNo := -1;
  FHandle.CreateFile(GetFileSize(FMaxSessionCount), SessionID, dbstNone, State);
  // create is in cache mode
  FSize := GetFileSize(FMaxSessionCount);
  FHandle.DataStream.Size := FSize;
  FHandle.DataStream.Position := 0;
  FillChar(FHandle.DataStream.Buffer^, FSize, $00);
  FHandle.WriteFile(SessionID, dbstTableLockFile, State);
  // FHandle.DirectWriteBuffer(Buf,SizeOf(Buf),0,True);
  // FHandle.
  // SaveHeader;
  Result := FHandle.StartPageNo;
end; // CreateFile

//------------------------------------------------------------------------------
// open and delete all pages
//------------------------------------------------------------------------------
procedure TACRTableLockFile.DeleteFile(aStartPageNo: TACRPageNo;
  SessionID: TACRSessionID; State: TACRState);
begin
  FHandle.OpenFile(aStartPageNo);
  FHandle.ReadFile(SessionID, dbstTableLockFile, State);
  FHandle.DeleteFile(SessionID, dbstTableLockFile, State);
end; // DeleteFile

//------------------------------------------------------------------------------
// lock table
//------------------------------------------------------------------------------
function TACRTableLockFile.LockTable(PSessionLockInfo: PACRSessionLockInfo)
  : Boolean;
begin
{$IFDEF DEBUG_LOCK_TIMES}
  aaStartTime(time9);
  aaIncCounter(counter9);
  try
{$ENDIF}
    Result := True;
    FHandle.LockFile(True);
    try
      case PSessionLockInfo^.WaitLockType of
        ltX:
          Result := InternalLockX(PSessionLockInfo);
        ltIS:
          Result := InternalLockIS(PSessionLockInfo);
        ltS:
          Result := InternalLockS(PSessionLockInfo);
        ltIRW:
          Result := InternalLockIRW(PSessionLockInfo);
        ltRW:
          Result := InternalLockRW(PSessionLockInfo);
      else
        // ltU:
        Result := InternalLockU(PSessionLockInfo);
      end;
    finally
      FHandle.UnlockFile(True);
    end;
{$IFDEF DEBUG_LOCK_TIMES}
  finally
    if (not Result) then
      aaIncCounter(counter19);
    aaStopTime(time9);
  end;
{$ENDIF}
end; // LockTable
{$IFDEF NEW_FILE_SERVER_LOCKING}

//------------------------------------------------------------------------------
// unlock table
//------------------------------------------------------------------------------
function TACRTableLockFile.UnlockTable(PSessionLockInfo: PACRSessionLockInfo)
  : Boolean;
begin
  FHandle.LockFile(True);
  try
    case PSessionLockInfo^.WaitLockType of
      ltX:
        Result := FHandle.UnlockByte(GetByteNo(0, ltX));
      ltIS:
        begin
          Result := FHandle.UnlockByte(GetByteNo(PSessionLockInfo^.SessionID,
              ltIS));
          if (FHeader.MinSessionID >= FHeader.MaxSessionID) then
          begin
            // disconnect of the last session
            FillChar(FHeader, SizeOf(FHeader), $00);
            FHeader.MinSessionID := Cardinal(INVALID_SESSION_ID);
            FHeader.MaxSessionID := Cardinal(INVALID_SESSION_ID);
            FillDataForLockU;
            SaveHeader;
          end
        end;
      ltS:
        Result := FHandle.UnlockByte(GetByteNo(PSessionLockInfo^.SessionID,
            ltS));
      ltIRW:
        Result := FHandle.UnlockByte(GetByteNo(0, ltIRW));
      ltRW:
        Result := FHandle.UnlockByte(GetByteNo(0, ltRW));
    else
      begin
        // ltU
        Result := FHandle.UnlockByte(GetByteNo(PSessionLockInfo^.SessionID,
            ltU));
      end;
    end;
  finally
    FHandle.UnlockFile(True);
  end;
end; // UnlockTable
{$ELSE}

//------------------------------------------------------------------------------
// unlock table
//------------------------------------------------------------------------------
function TACRTableLockFile.UnlockTable(PSessionLockInfo: PACRSessionLockInfo)
  : Boolean;
begin
  FHandle.LockFile(True);
  try
    case PSessionLockInfo^.WaitLockType of
      ltX:
        Result := FHandle.UnlockByte(GetByteNo(0, ltX));
      ltIS:
        Result := FHandle.UnlockByte(GetByteNo(PSessionLockInfo^.SessionID,
            ltIS));
      ltS:
        Result := FHandle.UnlockByte(GetByteNo(PSessionLockInfo^.SessionID,
            ltS));
      ltIRW:
        Result := FHandle.UnlockByte(GetByteNo(0, ltIRW));
      ltRW:
        Result := FHandle.UnlockByte(GetByteNo(0, ltRW));
    else
      begin
        // ltU
        Result := FHandle.UnlockByte(GetByteNo(PSessionLockInfo^.SessionID,
            ltU));
      end;
    end;
  finally
    FHandle.UnlockFile(True);
  end;
end; // UnlockTable
{$ENDIF}

//------------------------------------------------------------------------------
// clear wait level - lock failed as max wait time exceeded
//------------------------------------------------------------------------------
procedure TACRTableLockFile.ClearWaitLevel
  (PSessionLockInfo: PACRSessionLockInfo);
const
  b: Byte = 0;
begin
  case PSessionLockInfo^.WaitLockType of
    ltS:
      begin
        FHandle.LockFile(True);
        try
          LoadHeader;
          FHeader.SMaxWaitLevel := 0;
          SaveHeader;
        finally
          FHandle.UnlockFile(True);
        end;
      end;
    ltIRW:
      begin
        FHandle.LockFile(True);
        try
          LoadHeader;
          FHeader.IRWMaxWaitLevel := 0;
          SaveHeader;
        finally
          FHandle.UnlockFile(True);
        end;
      end;
    ltRW:
      begin
        FHandle.LockFile(True);
        try
          LoadHeader;
          FHeader.RWMaxWaitLevel := 0;
          SaveHeader;
        finally
          FHandle.UnlockFile(True);
        end;
      end;
    ltU:
      begin
        FHandle.LockFile(True);
        try
          FHandle.DirectWriteBuffer(b, SizeOf(b),
            GetByteNo(PSessionLockInfo^.SessionID, ltU, False, True), True);
        finally
          FHandle.UnlockFile(True);
        end;
      end;
  end;
end; // ClearWaitLevel

///////////////////////////////////////////////////////////////////////////////
//
// TACRSystemDirectory
//
///////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRSystemDirectory.Create(PageManager: TACRDiskPageManager);
begin
  LPageManager := PageManager;
  FHandle := TACRInternalDBFile.Create(LPageManager,
    ACRPageTypeIDFileSystemDirectory, INVALID_OBJECT_ID, False, True, nil);
end; // Create

//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TACRSystemDirectory.Destroy;
begin
  FreeAndNil(FHandle);
end; // Destroy

//------------------------------------------------------------------------------
// Create SystemDirectory
//------------------------------------------------------------------------------
procedure TACRSystemDirectory.CreateDirectory;
begin
  FHandle.CreateFile(0, 0, dbstNone, 0);
  if (FHandle.StartPageNo <> ACRFirstPageNoSystemDirectory) then
    raise EACRException.Create(30392, ErrorGSystemDirInvalidFirstPageNo,
      [FHandle.StartPageNo, ACRFirstPageNoSystemDirectory]);
end; // CreateDirectory

//------------------------------------------------------------------------------
// Load SystemDirectory
//------------------------------------------------------------------------------
procedure TACRSystemDirectory.LoadDirectory;
var
  Count: Integer;
begin
  FHandle.OpenFile(ACRFirstPageNoSystemDirectory);
  FHandle.ReadFile;
  Count := FHandle.DataStream.Size div SizeOf(TACRSystemDirectoryListItem);
  if (Count < ACRMinSystemFilesCount) then
    raise EACRException.Create(10633, ErrorLInvalidSystemDirectoryFilesCount,
      [Count, ACRFirstPageNoSystemDirectory]);
  SetLength(FFileList, Count);
  LoadDataFromStream(FFileList[0], FHandle.DataStream.Size, FHandle.DataStream,
    11833);
end; // LoadDirectory

//------------------------------------------------------------------------------
// Save SystemDirectory
//------------------------------------------------------------------------------
procedure TACRSystemDirectory.SaveDirectory;
begin
  FHandle.DataStream.Reset;
  SaveDataToStream(FFileList[0], Length(FFileList) * SizeOf
      (TACRSystemDirectoryListItem), FHandle.DataStream, 11834);
  FHandle.WriteFile;
end; // SaveDirectory

//------------------------------------------------------------------------------
// CreateFile
//------------------------------------------------------------------------------
procedure TACRSystemDirectory.CreateFile(FileType: TACRDBFileType;
  FirstPageNo: TACRPageNo);
var
  Count: Integer;
begin
  Count := Length(FFileList);
  SetLength(FFileList, Count + 1);
  FFileList[Count].FileID := FileType;
  FFileList[Count].FirstPageNo := FirstPageNo;
end; // CreateFile

//------------------------------------------------------------------------------
// GetFileFirstPageNo
//------------------------------------------------------------------------------
function TACRSystemDirectory.GetFileFirstPageNo(FileType: TACRDBFileType)
  : TACRPageNo;
var
  i: Integer;
begin
  Result := INVALID_PAGE_NO;
  for i := 0 to Length(FFileList) - 1 do
    if (FFileList[i].FileID = FileType) then
    begin
      Result := FFileList[i].FirstPageNo;
      break;
    end;
end; // GetFileFirstPageNo

//------------------------------------------------------------------------------
// convert PageTypeID to AnsiString (for exceptions messages)
//------------------------------------------------------------------------------
function PageTypeToStr(PageType: TACRPageTypeID): AnsiString;
begin
  if PageType > High(ACRPageTypeNames) then
    raise EACRException.Create(30382, ErrorGUnknownPageType, [PageType]);
  Result := ACRPageTypeNames[PageType];
end; // PageTypeToStr

//------------------------------------------------------------------------------
// retrun delay in ms
//------------------------------------------------------------------------------
function GetDelay(const Delay: Integer; const CurrentRetryNo,
  RetryCount: Integer): Integer;
begin
  Result := Delay;
end; // GetDelay

//------------------------------------------------------------------------------
// Try call Func before Success or TimeOut off
//------------------------------------------------------------------------------
function TryUsingTimeOutWithExclusive(Func:
    TBooleanFunctionForTimeOutCallWithExclusive; LockParams: TACRLockParams;
  Exclusive: Boolean): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 1 to LockParams.RetryCount do
    if Func(Exclusive) then
    begin
      Result := True;
      break;
    end
    else
    begin
      Sleep(GetDelay(LockParams.Delay, i, LockParams.RetryCount));
    end;
end; // TryUsingTimeOutWithExclusive

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRDiskEngine> initialized');
{$ENDIF}
ACRMemoryIncUseCount;

finalization

ACRMemoryDecUseCount;

end.
