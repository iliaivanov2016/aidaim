unit SQLMemBTree;

{$I SQLMemVer.inc}

interface

uses SysUtils, Classes, Math,

{$DEFINE INDEX_NAVIGATION_OPTIMIZATION}
// SQLMemTable units
     {$IFDEF MSWINDOWS}
     Windows,
     {$ENDIF}
     SQLMemConverts,

     {$IFDEF DEBUG_LOG}
     SQLMemDebug,
     {$ENDIF}
     SQLMemPage,
     SQLMemBaseEngine,
     SQLMemExcept,
     SQLMemBase,
     SQLMemTypes,
     SQLMemVariant,
     SQLMemCriticalSection,
     SQLMemConst;

const SQLMemMaxKeyPathItemNo = 31;
  //===============================================
  // B-tree page structure
  //===============================================
  // +--------------------------------------------+
  // | PageHeader                                 |
  // +--------------------------------------------+
  // | BTree PageHeader                           |
  // +--------------------------------------------+
  // | Page Prefix (optional)                     |
  // +--------------------------------------------+
  // | Entries                                    |
  // +--------------------------------------------+
  // | Empty space                                |
  // +--------------------------------------------+

  //===============================================
  // Entry structure
  //===============================================
  // +--------------------------------------------+
  // | KeyPrefix | Suffix (opt) | Reference (opt) |
  // +--------------------------------------------+

  //===============================================
  // Key Prefix structure
  //===============================================
  // +--------------------------------------------------------+
  // | Field1IsNull (byte) | Field1 data | Field2IsNull | ... |
  // +--------------------------------------------------------+


type

  TSQLMemBTreeLeafController = class;
  TSQLMemBTreeNodeController = class;
  TSQLMemBTreeIndex = class;

  // BTree PageHeader  
  TSQLMemBTreePageHeader = packed record
     IsRoot:           Boolean;
     IsLeaf:           Boolean;
     LeftPageNo:       TSQLMemPageNo;
     RightPageNo:      TSQLMemPageNo;
     HasKeys:          Boolean;
     HasSuffixes:      Boolean;
     KeyPrefixSize:    Word;
     EntryCount:         Word;
     PagePrefixSize:   Word;
  end;
  PSQLMemBTreePageHeader = ^TSQLMemBTreePageHeader;

  TSQLMemKeyPathItem = record
    PageNo:       TSQLMemPageNo;
    EntryNo:      Integer;
    EntryCount:   Integer;
  end;

////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBTreeKeyPath
//
////////////////////////////////////////////////////////////////////////////////


{$IFDEF INDEX_NAVIGATION_OPTIMIZATION}
  // keypath optimization
  TSQLMemKeyPath = class;
  TSQLMemKeyPathCacheItem = record
   SessionID:     TSQLMemSessionID;
   RecordID:      TSQLMemRecordID;
   KeyPath:       TSQLMemKeyPath;
  end;
  PSQLMemKeyPathCacheItem = ^TSQLMemKeyPathCacheItem;

  TSQLMemKeyPathCache = class(TObject)
   private
    FItems: TList;
   public
    constructor Create;
    destructor Destroy; override;
    procedure Clear(SessionID: TSQLMemSessionID = INVALID_OBJECT_ID);
    function GetKeyPath(SessionID: TSQLMemSessionID; RecordID: TSQLMemRecordID; Clear: Boolean): TSQLMemKeyPath;
    procedure SetKeyPath(SessionID: TSQLMemSessionID; RecordID: TSQLMemRecordID; KeyPath: TSQLMemKeyPath);
  end;
{$ENDIF}

  // key path position
  TSQLMemKeyPathPosition = (
    kppUnknown,
    kppOnKey,
    kppBeforeKey,
    kppAfterKey,
    kppBOF,
    kppEOF);
  PSQLMemKeyPathPosition = ^TSQLMemKeyPathPosition;

  TSQLMemKeyPath = class (TObject)
   public
    Items: array [0..SQLMemMaxKeyPathItemNo] of TSQLMemKeyPathItem;
    Count: Integer;
    ItemNo: Integer;
    PositionType: TSQLMemKeyPathPosition;
    IndexState: Integer;

    constructor Create;
    procedure Clear;
    procedure AddItem(aPageNo: TSQLMemPageNo; aEntryNo, aEntryCount: Integer);
    procedure DeleteLastItem;
    procedure IncLevel;
    procedure DecLevel;
    function GetCurrentPageNo: TSQLMemPageNo;
    procedure SetCurrentPageNo(Value: TSQLMemPageNo);
    function PageExists(aPageNo: TSQLMemPageNo): Boolean;
    // return 0, 1, -1 if (Self = aKeyPath), (Self > aKeyPath), (Self < aKeyPath)
    function Compare(aKeyPath: TSQLMemKeyPath): Integer;
    function GetApproxRecNoInPercents: double;
    procedure Assign(Source: TSQLMemKeyPath);

    property  CurrentPageNo: TSQLMemPageNo read GetCurrentPageNo write SetCurrentPageNo;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBTreeKeyRef
//
////////////////////////////////////////////////////////////////////////////////

  TSQLMemKeyPart = record
   OffsetInKeyBuffer:      Integer;
   OffsetInRecordBuffer:   Integer; // optional
   FieldNo:                Integer;  // optional
   Size:                   Integer;
   DataType:               TSQLMemBaseFieldType;
   Descending:             Boolean;
   CaseInsensitive:        Boolean;
  end;

  TSQLMemBTreeKeyRef = class (TObject)
   private
     FKeySize:            Integer;
     FReferenceSize:      Word;
     FKeyIsReference:     Boolean;
     FCompareFieldCount:  Integer;

     function GetPartCount: Integer;
     procedure SetPartCount(Value: Integer);

   public
     Parts: array of TSQLMemKeyPart;

     constructor Create;
     procedure Assign(IndexDef: TSQLMemIndexDef; aTableData: Pointer);
     function AllocKeyBuffer: PAnsiChar;
     procedure FreeAndNilKeyBuffer(var Buffer: PAnsiChar);
     procedure MakeKeyFromRecordBuffer(RecordBuffer: PAnsiChar; KeyBuffer: PAnsiChar);
     function CompareKeys(KeyBuffer1, KeyBuffer2: PAnsiChar): Integer;
     function CompareReferences(Reference1, Reference2: PAnsiChar; Size: Integer): Boolean;

     property PartCount: Integer read GetPartCount write SetPartCount;
     property KeySize: Integer read FKeySize;
     property ReferenceSize: Word read FReferenceSize write FReferenceSize;
     property KeyIsReference: Boolean read FKeyIsReference write FKeyIsReference;
     property CompareFieldCount: Integer read FCompareFieldCount write FCompareFieldCount;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBTreePage
//
////////////////////////////////////////////////////////////////////////////////

  TSQLMemBTreePage = class(TSQLMemPageController)
   private
     FLeafController:       TSQLMemBTreeLeafController;
     FNodeController:       TSQLMemBTreeNodeController;
     FKeyRef:               TSQLMemBTreeKeyRef;
     LBTreeIndex:           TSQLMemBTreeIndex;

     function GetIsRoot: Boolean;
     procedure SetIsRoot(Value: Boolean);
     function GetIsLeaf: Boolean;
     procedure SetIsLeaf(Value: Boolean);
     function GetLeftPageNo: TSQLMemPageNo;
     procedure SetLeftPageNo(Value: TSQLMemPageNo);
     function GetRightPageNo: TSQLMemPageNo;
     procedure SetRightPageNo(Value: TSQLMemPageNo);
     function GetHasKeys: Boolean;
     procedure SetHasKeys(Value: Boolean);
     function GetHasSuffixes: Boolean;
     procedure SetHasSuffixes(Value: Boolean);
     function GetKeyPrefixSize: Word;
     procedure SetKeyPrefixSize(Value: Word);
     function GetEntryCount: Integer;
     procedure SetEntryCount(Value: Integer);
     function GetPagePrefixSize: Word;
     procedure SetPagePrefixSize(Value: Word);
     //-------------------------------------
     function GetEntrySize: Integer;
     function GetReferenceSize: Integer;
     function GetEntriesOffset: Integer;
     function GetSuffixPtrSize: Integer;

   public
     constructor Create(BTreeIndex: TSQLMemBTreeIndex; Page: TSQLMemPage);
     destructor Destroy; override;
     procedure Init;
     procedure InitAsRoot;
     procedure CopyFrom(Source: TSQLMemBTreePage; StartNo, Count: Integer);
     procedure AppendFrom(Source: TSQLMemBTreePage; StartNo, Count: Integer);
     procedure InsertFrom(Source: TSQLMemBTreePage; StartNo, Count: Integer);
     procedure InsertLeafEntry(SessionID: TSQLMemSessionID; Key, Reference: PAnsiChar; KeyPath: TSQLMemKeyPath);
     procedure InsertNodeEntry(SessionID: TSQLMemSessionID; Key, Reference: PAnsiChar; KeyPath: TSQLMemKeyPath);
     function DeleteLeafEntry(SessionID: TSQLMemSessionID; Key, Reference: PAnsiChar; KeyPath: TSQLMemKeyPath): Boolean;
     procedure DeleteNodeEntry(
                        SessionID:     TSQLMemSessionID;
                        KeyPath:       TSQLMemKeyPath;
                        MergeWithLeft: Boolean
                              );
     function FindEntry(
                        SessionID: TSQLMemSessionID;
                        Key:       PAnsiChar;
                        Reference: PAnsiChar;
                        Position:  TSQLMemKeyPath
                       ): Boolean;
     function GetFirstPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean;
     function GetLastPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean;
     function FindByCondition(
                              SessionID: TSQLMemSessionID;
                              First:     Boolean; // if False => Last
                              Key:       PAnsiChar;
                              Operator:  TSQLMemSearchCondition;
                              Position:  TSQLMemKeyPath
                             ): Boolean;

     procedure FreeAllPages(SessionID: TSQLMemSessionID; RootPageNo: TSQLMemPageNo = INVALID_PAGE_NO);
     procedure CheckIntegrity(SessionID: TSQLMemSessionID; KeyPath: TSQLMemKeyPath);
     function GetPKey(KeyPosition: Integer): PAnsiChar;
     function GetPReference(RefPosition: Integer): PAnsiChar;
     procedure GetFirstKey(SessionID: TSQLMemSessionID; Key: PAnsiChar);
     procedure GetLastKey(SessionID: TSQLMemSessionID; Key: PAnsiChar);
     procedure UpdateKey(Position: Integer; Key: PAnsiChar);

     //--- BTree page header ---
     property IsRoot: Boolean read GetIsRoot write SetIsRoot;
     property IsLeaf: Boolean read GetIsLeaf write SetIsLeaf;
     property LeftPageNo: TSQLMemPageNo read GetLeftPageNo write SetLeftPageNo;
     property RightPageNo: TSQLMemPageNo read GetRightPageNo write SetRightPageNo;
     property HasKeys: Boolean read GetHasKeys write SetHasKeys;
     property HasSuffixes: Boolean read GetHasSuffixes write SetHasSuffixes;
     property KeyPrefixSize: Word read GetKeyPrefixSize write SetKeyPrefixSize;
     property EntryCount: Integer read GetEntryCount write SetEntryCount;
     property PagePrefixSize: Word read GetPagePrefixSize write SetPagePrefixSize;
     // calculated
     property EntrySize:     Integer read GetEntrySize;
     property ReferenceSize: Integer read GetReferenceSize;
     property EntriesOffset: Integer read GetEntriesOffset;
     property SuffixPtrSize: Integer read GetSuffixPtrSize;

     property KeyRef: TSQLMemBTreeKeyRef read FKeyRef write FKeyRef;
  end;



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBTreePageController
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemBTreePageController = class(TObject)
   protected
     FPage:                  TSQLMemBTreePage;
     LTableData:             TSQLMemTableData;

     function GetKeyRef: TSQLMemBTreeKeyRef;
     function CanAddEntry: Boolean;
     function IsOverflow: Boolean;
     function CanUnderflow: Boolean;
     function CanMergeWithPage(Page: TSQLMemBTreePage): Boolean;
     procedure EnlargePageBuffer;
     function CompareKeys(Key1: PAnsiChar; Key2Index: Word): Integer; overload;
     function CompareKeys(Key1, Key2: PAnsiChar; KeyRef: TSQLMemBTreeKeyRef): Integer; overload;
     function CompareReferences(Reference1: PAnsiChar; Reference2Index: Word): Boolean;
     function GetKeyPosition(
                       Key: PAnsiChar;
                       StartPosition: Integer = 0;
                       PositionType: PSQLMemKeyPathPosition = nil;
                       SearchType: TSQLMemKeySearchType = kstAny
                             ): Word;
     procedure InsertEntry(Key, Reference: PAnsiChar; Position: Integer);
     procedure DeleteEntry(Position: Integer);
     procedure RootSplit(SessionID: TSQLMemSessionID; KeyPath: TSQLMemKeyPath);
     procedure NonRootSplit(SessionID: TSQLMemSessionID; KeyPath: TSQLMemKeyPath);
     function TryMergeWithPage(
                        SessionID: TSQLMemSessionID;
                        MergePageNo: TSQLMemPageNo;
                        KeyPath: TSQLMemKeyPath
                               ): Boolean;
     function TryMerge(SessionID: TSQLMemSessionID; KeyPath: TSQLMemKeyPath): Boolean;
     procedure MergeWithLeftPage(
                        SessionID: TSQLMemSessionID;
                        LeftPage: TSQLMemBTreePage;
                        KeyPath: TSQLMemKeyPath
                                );
     procedure MergeWithRightPage(
                        SessionID: TSQLMemSessionID;
                        RightPage: TSQLMemBTreePage;
                        KeyPath: TSQLMemKeyPath
                                );
   public
     constructor Create(
                        aPage:        TSQLMemBTreePage;
                        aTableData:   TSQLMemTableData
                       );
     procedure InsertLeafEntry(SessionID: TSQLMemSessionID; Key, Reference: PAnsiChar; KeyPath: TSQLMemKeyPath); virtual; abstract;
     function DeleteLeafEntry(SessionID: TSQLMemSessionID; Key, Reference: PAnsiChar; KeyPath: TSQLMemKeyPath): Boolean; virtual; abstract;
     procedure FreeAllPages(SessionID: TSQLMemSessionID; RootPageNo: TSQLMemPageNo = INVALID_PAGE_NO); virtual; abstract;
     procedure CheckIntegrity(SessionID: TSQLMemSessionID; KeyPath: TSQLMemKeyPath); virtual; abstract;
     function FindEntry(
                        SessionID: TSQLMemSessionID;
                        Key:       PAnsiChar;
                        Reference: PAnsiChar;
                        Position:  TSQLMemKeyPath
                       ): Boolean; virtual; abstract;
     function GetFirstPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean; virtual; abstract;
     function GetLastPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean; virtual; abstract;
     function FindByCondition(
                              SessionID: TSQLMemSessionID;
                              First:     Boolean; // if False => Last
                              Key:       PAnsiChar;
                              Operator:  TSQLMemSearchCondition;
                              Position:  TSQLMemKeyPath
                             ): Boolean; virtual; abstract;
     function GetPKey(KeyPosition: Integer): PAnsiChar;
     function GetPReference(RefPosition: Integer): PAnsiChar;
     procedure GetFirstKey(SessionID: TSQLMemSessionID; Key: PAnsiChar); virtual; abstract;
     procedure GetLastKey(SessionID: TSQLMemSessionID; Key: PAnsiChar); virtual; abstract;
     procedure Split(SessionID: TSQLMemSessionID; KeyPath: TSQLMemKeyPath);
     function KeyMatch(
                          KeyPosition:     Integer;
                          SearchKey:       PAnsiChar;
                          SearchCondition: TSQLMemSearchCondition
                      ): Boolean;

     property KeyRef: TSQLMemBTreeKeyRef read GetKeyRef;
  end;// TSQLMemBTreePageController



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBTreeLeafController
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemBTreeLeafController = class(TSQLMemBTreePageController)
   private
     function FindEntryOnPage(Key, Reference: PAnsiChar; var EntryNo: Integer): Boolean;
     function FindFirstByCondition(
                                    Key:       PAnsiChar;
                                    Operator:  TSQLMemSearchCondition;
                                    Position:  TSQLMemKeyPath
                                  ): Boolean;
     function FindLastByCondition(
                                    Key:       PAnsiChar;
                                    Operator:  TSQLMemSearchCondition;
                                    Position:  TSQLMemKeyPath
                                  ): Boolean;
   public
     procedure InsertLeafEntry(SessionID: TSQLMemSessionID; Key, Reference: PAnsiChar; KeyPath: TSQLMemKeyPath); override;
     function DeleteLeafEntry(SessionID: TSQLMemSessionID; Key, Reference: PAnsiChar; KeyPath: TSQLMemKeyPath): Boolean; override;
     procedure GetFirstKey(SessionID: TSQLMemSessionID; Key: PAnsiChar); override;
     procedure GetLastKey(SessionID: TSQLMemSessionID; Key: PAnsiChar); override;
     function FindEntry(
                          SessionID: TSQLMemSessionID;
                          Key:       PAnsiChar;
                          Reference: PAnsiChar;
                          Position:  TSQLMemKeyPath
                       ): Boolean; override;
     function GetFirstPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean; override;
     function GetLastPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean; override;
     function FindByCondition(
                              SessionID: TSQLMemSessionID;
                              First:     Boolean; // if False => Last
                              Key:       PAnsiChar;
                              Operator:  TSQLMemSearchCondition;
                              Position:  TSQLMemKeyPath
                             ): Boolean; override;
     procedure FreeAllPages(SessionID: TSQLMemSessionID; RootPageNo: TSQLMemPageNo = INVALID_PAGE_NO); override;
     procedure CheckIntegrity(SessionID: TSQLMemSessionID; KeyPath: TSQLMemKeyPath); override;
  end;// TSQLMemBTreeLeafController



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBTreeNodeController
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemBTreeNodeController = class(TSQLMemBTreePageController)
   private
    function FindByConditionOnOneOfPages(
                                    SessionID:    TSQLMemSessionID;
                                    First:        Boolean; // if False => Last
                                    StartEntryNo: Integer;
                                    EndEntryNo:   Integer;
                                    Key:          PAnsiChar;
                                    Operator:     TSQLMemSearchCondition;
                                    Position:     TSQLMemKeyPath
                                  ): Boolean;
    function FindEntryOnOneOfPages(
                                    SessionID:    TSQLMemSessionID;
                                    StartEntryNo: Integer;
                                    EndEntryNo:   Integer;
                                    Key:          PAnsiChar;
                                    Reference:    PAnsiChar;
                                    Position:     TSQLMemKeyPath
                                  ): Boolean;
    procedure GetChildPagesToCheck(
                          Key:               PAnsiChar;
                          SearchCondition:   TSQLMemSearchCondition;
                          var StartEntryNo:  Integer;
                          var EndEntryNo:    Integer
                                    );
     procedure DecreaseTreeDepth(SessionID: TSQLMemSessionID);

   public
     procedure InsertLeafEntry(SessionID: TSQLMemSessionID; Key, Reference: PAnsiChar; KeyPath: TSQLMemKeyPath); override;
     procedure InsertNodeEntry(SessionID: TSQLMemSessionID; Key, Reference: PAnsiChar; KeyPath: TSQLMemKeyPath);
     function DeleteLeafEntry(SessionID: TSQLMemSessionID; Key, Reference: PAnsiChar; KeyPath: TSQLMemKeyPath): Boolean; override;
     procedure DeleteNodeEntry(
                        SessionID:     TSQLMemSessionID;
                        KeyPath:       TSQLMemKeyPath;
                        MergeWithLeft: Boolean
                              );
     procedure GetFirstKey(SessionID: TSQLMemSessionID; Key: PAnsiChar); override;
     procedure GetLastKey(SessionID: TSQLMemSessionID; Key: PAnsiChar); override;
     function FindEntry(
                          SessionID: TSQLMemSessionID;
                          Key:       PAnsiChar;
                          Reference: PAnsiChar;
                          Position:  TSQLMemKeyPath
                       ): Boolean; override;
     function GetFirstPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean; override;
     function GetLastPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean; override;
     function FindByCondition(
                              SessionID: TSQLMemSessionID;
                              First:     Boolean; // if False => Last
                              Key:       PAnsiChar;
                              Operator:  TSQLMemSearchCondition;
                              Position:  TSQLMemKeyPath
                             ): Boolean; override;
     procedure FreeAllPages(SessionID: TSQLMemSessionID; RootPageNo: TSQLMemPageNo = INVALID_PAGE_NO); override;
     procedure CheckIntegrity(SessionID: TSQLMemSessionID; KeyPath: TSQLMemKeyPath); override;
  end;// TSQLMemBTreeNodeController



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBTreeIndex
//
////////////////////////////////////////////////////////////////////////////////

  TSQLMemBTreeSearchInfo = packed record
     GoForward:       Boolean;
     IsFilled:        Boolean;
     EndKeyPath:      TSQLMemKeyPath;
     CurrentKeyPath:  TSQLMemKeyPath;
  end;
  PSQLMemBTreeSearchInfo = ^TSQLMemBTreeSearchInfo;

  { TODO -oLeo :
Indexes are not thread safe - parallel search by multiple threads is impossible
Fix in v.5 }
  TSQLMemBTreeIndex = class (TSQLMemIndex)
   private
    FRootPage:          TSQLMemBTreePage;
    FKeyRef:            TSQLMemBTreeKeyRef;
    FThreadSync:        TSQLMemReadWriteThreadSyncBySingleCriticalSection;
{$IFDEF INDEX_NAVIGATION_OPTIMIZATION}
// keypath cache
    FKeyPathCache:      TSQLMemKeyPathCache;
{$ENDIF}
    // lock
    procedure Lock(WriteMode: Boolean = false);
    // unlock
    procedure Unlock;
    function AddIndexPage(SessionID: TSQLMemSessionID): TSQLMemBTreePage;
    procedure RemoveIndexPage(SessionID: TSQLMemSessionID; PageNo: TSQLMemPageNo);
    function GetIndexPage(SessionID: TSQLMemSessionID; PageNo: TSQLMemPageNo): TSQLMemBTreePage;
    procedure PutIndexPage(Page: TSQLMemBTreePage);

    function GetRecordID(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): TSQLMemRecordID;
    function GetFirstPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean;
    function GetLastPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean;
    function GetNextPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean;
    function GetPriorPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean;
    function GetPosition(SessionID: TSQLMemSessionID; Restart, GoForward: Boolean; Position: TSQLMemKeyPath): Boolean;

   public
    constructor Create(aIndexManager: TSQLMemBaseIndexManager);
    destructor Destroy; override;

    // clear index cache (INVALID_OBJECT_ID means all sessions)
    procedure ClearIndexCache(SessionID: TSQLMemSessionID = INVALID_OBJECT_ID); override;
    procedure CreateIndex(Cursor: TSQLMemCursor; aIndexDef: TSQLMemIndexDef); overload; override;
    procedure CreateIndex(SessionID: TSQLMemSessionID; pageNo: TSQLMemPageNo; aIndexDef: TSQLMemIndexDef); overload; override;
    procedure DropIndex(SessionID: TSQLMemSessionID; EmptyIndex: Boolean = False); override;
    procedure OpenIndex(aIndexDef: TSQLMemIndexDef); override;

    procedure GetRecordBuffer(
                               SessionID:          TSQLMemSessionID;
                               var NavigationInfo: TSQLMemNavigationInfo
                             ); override;
    function CreateIndexPosition: TSQLMemIndexPosition; override;
    procedure FreeIndexPosition(var IndexPosition: TSQLMemIndexPosition); override;
    function GetIndexPosition(
                               SessionID:      TSQLMemSessionID;
                               RecordID:       TSQLMemRecordID;
                               RecordBuffer:   TSQLMemRecordBuffer;
                               IndexPosition:  TSQLMemIndexPosition
                             ): Boolean; override;
    // return 0, 1, -1 if (Pos1 = Pos2), (Pos1 > Pos2), (Pos1 < Pos2)
    function CompareRecordPositionsInIndex(
                        RecordPosition1: TSQLMemIndexPosition;
                        RecordPosition2: TSQLMemIndexPosition
                                          ): Integer; override;
    function GetRecNoByRecordID(
                                SessionID:      TSQLMemSessionID;
                                RecordID:       TSQLMemRecordID;
                                RecordBuffer:   TSQLMemRecordBuffer;
                                Bitmap:         TSQLMemRecordBitmap
                               ): TSQLMemRecordNo; override;
    function GetRecordIDByRecNo(
                                SessionID:      TSQLMemSessionID;
                                RecNo:          TSQLMemRecordNo;
                                Bitmap:         TSQLMemRecordBitmap
                               ): TSQLMemRecordID; override;
    function CreateSearchInfo: TSQLMemSearchInfo; override;
    procedure FreeSearchInfo(SearchInfo: TSQLMemSearchInfo); override;
   private
    function GetCurrentPosition(
                                 SessionID:           TSQLMemSessionID;
                                 Restart:             Boolean;
                                 GoForward:           Boolean;
                                 StartScanCondition:  TSQLMemScanSearchCondition;
                                 RecordBuffer:        TSQLMemRecordBuffer;
                                 RecordID:            TSQLMemRecordID;
                                 SearchInfo:          TSQLMemSearchInfo
                               ): Boolean;
    function GetEndPosition(
                                 SessionID:           TSQLMemSessionID;
                                 GoForward:           Boolean;
                                 StartScanCondition:  TSQLMemScanSearchCondition;
                                 EndScanCondition:    TSQLMemScanSearchCondition;
                                 SearchInfo:          TSQLMemSearchInfo
                               ): Boolean;
   public
    function FindRecord(
                       SessionID:           TSQLMemSessionID;
                       Restart:             Boolean;
                       GoForward:           Boolean;
                       StartScanCondition:  TSQLMemScanSearchCondition;
                       EndScanCondition:    TSQLMemScanSearchCondition;
                       RecordBuffer:        TSQLMemRecordBuffer;
                       var RecordID:        TSQLMemRecordID;
                       SearchInfo:          TSQLMemSearchInfo
                       ): Boolean; override;
    // return 0 if record buffers are equal in this index
    // return 1 if Buffer1 is higher than Buffer 2 (Pos1 > Pos2)
    // return -1 if Buffer1 is lower than Buffer 2 (Pos1 < Pos2)
    function CompareRecordBuffersByIndex(
                        Buffer1: TSQLMemRecordBuffer;
                        Buffer2: TSQLMemRecordBuffer;
                        IndexFieldCount: Integer
                                        ): Integer; override;

    // return 0 if conditions are equal in this index
    // return 1 if Condition1 is higher than Condition2
    // return -1 if Condition1 is lower than Condition2
    function CompareConditions(
                    Condition1:   TSQLMemScanSearchCondition;
                    Condition2:   TSQLMemScanSearchCondition
                              ): Integer; override;
    // approximate record count between range conditions
    function GetApproxRangeRecordCount(
                    SessionID:         TSQLMemSessionID;
                    TableRecordCount:  TSQLMemRecordNo;
                    RangeCondition1:   TSQLMemScanSearchCondition;
                    RangeCondition2:   TSQLMemScanSearchCondition
                                      ): TSQLMemRecordNo; override;

    function CanInsertRecord(
                    SessionID:      TSQLMemSessionID;
                    RecordBuffer:   TSQLMemRecordBuffer
                            ): Boolean; override;
    function CanUpdateRecord(
                    SessionID:                        TSQLMemSessionID;
                    OldRecordBuffer, NewRecordBuffer: TSQLMemRecordBuffer
                            ): Boolean; override;
    procedure InsertRecord(Cursor: TSQLMemCursor); override;
    procedure UpdateRecord(Cursor: TSQLMemCursor); override;
    procedure DeleteRecord(Cursor: TSQLMemCursor); override;

    property KeyRef: TSQLMemBTreeKeyRef read FKeyRef;
  end; // TSQLMemBTreeIndex



implementation

uses SQLMemLocalEngine,
     SQLMemMemory        // last
;


{$IFDEF INDEX_NAVIGATION_OPTIMIZATION}
////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBTreeKeyPathCache
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TSQLMemKeyPathCache.Create;
begin
 inherited;
 FItems := TList.Create;
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TSQLMemKeyPathCache.Destroy;
begin
 Clear;
 FItems.Free;
 inherited Destroy;
end; // Create


//------------------------------------------------------------------------------
// clear index cache (INVALID_OBJECT_ID means all sessions)
//------------------------------------------------------------------------------
procedure TSQLMemKeyPathCache.Clear(SessionID: TSQLMemSessionID);
var i: Integer;
begin
 i := 0;
 while (i <= FItems.Count-1) do
  begin
   if (SessionID = INVALID_OBJECT_ID) or (SessionID = PSQLMemKeyPathCacheItem(FItems.Items[i])^.SessionID) then
    begin
     PSQLMemKeyPathCacheItem(FItems.Items[i])^.KeyPath.Free;
     Dispose(PSQLMemKeyPathCacheItem(FItems.Items[i]));
     if (SessionID <> INVALID_OBJECT_ID) then
      begin
       FItems.Delete(i);
       continue;
      end;
    end;
   Inc(i);
  end;
 if (SessionID = INVALID_OBJECT_ID) then
   FItems.Clear;
end; // Clear


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
function TSQLMemKeyPathCache.GetKeyPath(SessionID: TSQLMemSessionID; RecordID: TSQLMemRecordID; Clear: Boolean): TSQLMemKeyPath;
var CacheItem: PSQLMemKeyPathCacheItem;
    i: Integer;
begin
 Result := TSQLMemKeyPath.Create;
 try
   for i := 0 to FItems.Count-1 do
    if (PSQLMemKeyPathCacheItem(FItems.Items[i])^.SessionID = SessionID) then
     begin
      CacheItem := PSQLMemKeyPathCacheItem(FItems.Items[i]);
      if (Clear) or
         ((PSQLMemKeyPathCacheItem(FItems.Items[i])^.RecordID.PageNo <> RecordID.PageNo)
           or
          (PSQLMemKeyPathCacheItem(FItems.Items[i])^.RecordID.PageItemNo <> RecordID.PageItemNo))  then
       begin
        CacheItem.KeyPath.Clear;
        Exit;
       end;
      Exit;
     end;
   New(CacheItem);
   CacheItem.SessionID := SessionID;
   CacheItem.RecordID := RecordID;
   CacheItem.KeyPath := TSQLMemKeyPath.Create;
   FItems.Add(CacheItem);
 finally
   Result.Assign(CacheItem^.KeyPath);
 end;
end; // GetKeyPath


//------------------------------------------------------------------------------
// set key path
//------------------------------------------------------------------------------
procedure TSQLMemKeyPathCache.SetKeyPath(SessionID: TSQLMemSessionID; RecordID: TSQLMemRecordID; KeyPath: TSQLMemKeyPath);
var CacheItem: PSQLMemKeyPathCacheItem;
    i: Integer;
begin
   for i := 0 to FItems.Count-1 do
    if (PSQLMemKeyPathCacheItem(FItems.Items[i])^.SessionID = SessionID) then
     begin
      CacheItem := PSQLMemKeyPathCacheItem(FItems.Items[i]);
      CacheItem^.RecordID := RecordID;
      CacheItem^.KeyPath.Assign(KeyPath);
      Exit;
     end;
   raise ESQLMemException.Create(11630,ErrorLIndexErrorCannotFindKeyPath,[SessionID,RecordID.PageNo,RecordID.PageItemNo,FItems.Count]);
end;

{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemKeyPath
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TSQLMemKeyPath.Create;
begin
//aaIncCounter(counter7);
//aaStartTime(time6);
  Clear;
//aaStopTime(time6);
end;// Create


//------------------------------------------------------------------------------
// Clear
//------------------------------------------------------------------------------
procedure TSQLMemKeyPath.Clear;
begin
  Count := 0;
  ItemNo := 0;
end;// Clear


//------------------------------------------------------------------------------
// AddItem
//------------------------------------------------------------------------------
procedure TSQLMemKeyPath.AddItem(aPageNo: TSQLMemPageNo; aEntryNo, aEntryCount: Integer);
begin
//aaIncCounter(counter6);
//aaStartTime(time3);
  if (ItemNo < 0) or (ItemNo > SQLMemMaxKeyPathItemNo) then
   raise ESQLMemException.Create(11660,ErrorLInvalidKeyPathItemNo,[ItemNo,aPageNo,aEntryNo,aEntryCount]);
  Items[ItemNo].PageNo := aPageNo;
  Items[ItemNo].EntryNo := aEntryNo;
  Items[ItemNo].EntryCount := aEntryCount;
  Inc(ItemNo);
  Inc(Count);
//aaStopTime(time3);
end;// AddItem


//------------------------------------------------------------------------------
// DeleteLastItem
//------------------------------------------------------------------------------
procedure TSQLMemKeyPath.DeleteLastItem;
begin
  Dec(ItemNo);
  Dec(Count);
end;// DeleteLastItem


//------------------------------------------------------------------------------
// IncLevel
//------------------------------------------------------------------------------
procedure TSQLMemKeyPath.IncLevel;
begin
  Inc(ItemNo);
end;// IncLevel


//------------------------------------------------------------------------------
// DecLevel
//------------------------------------------------------------------------------
procedure TSQLMemKeyPath.DecLevel;
begin
  Dec(ItemNo);
end;// DecLevel

//------------------------------------------------------------------------------
// GetCurrentPageNo
//------------------------------------------------------------------------------
function TSQLMemKeyPath.GetCurrentPageNo: TSQLMemPageNo;
begin
  Result := Items[ItemNo].PageNo;
end;// GetCurrentPageNo


//------------------------------------------------------------------------------
// SetCurrentPageNo
//------------------------------------------------------------------------------
procedure TSQLMemKeyPath.SetCurrentPageNo(Value: TSQLMemPageNo);
begin
  Items[ItemNo].PageNo := Value;
end;// SetCurrentPageNo


//------------------------------------------------------------------------------
// PageExists
//------------------------------------------------------------------------------
function TSQLMemKeyPath.PageExists(aPageNo: TSQLMemPageNo): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to Count-1 do
   if (Items[i].PageNo = aPageNo) then
    begin
     Result := True;
     break;
    end;
end;// PageExists


//------------------------------------------------------------------------------
// return 0, 1, -1 if (Self = aKeyPath), (Self > aKeyPath), (Self < aKeyPath)
//------------------------------------------------------------------------------
function TSQLMemKeyPath.Compare(aKeyPath: TSQLMemKeyPath): Integer;
var
  i: Integer;
begin
  if (Count <> aKeyPath.Count) then
   raise ESQLMemException.Create(20051, ErrorAInvalidIndexKeyPath);
  Result := 0;
  for i := 0 to Count-1 do
   begin
     if (Items[i].PageNo <> aKeyPath.Items[i].PageNo) then
      raise ESQLMemException.Create(20052, ErrorAInvalidIndexKeyPath);
     if (Items[i].EntryNo < aKeyPath.Items[i].EntryNo) then
      begin
       Result := -1;
       break;
      end
     else
      if (Items[i].EntryNo > aKeyPath.Items[i].EntryNo) then
       begin
        Result := 1;
        break;
       end;
   end;
end;// Compare


//------------------------------------------------------------------------------
// GetApproxRecNoInPercents
//------------------------------------------------------------------------------
function TSQLMemKeyPath.GetApproxRecNoInPercents: double;
var
  i:               Integer;
  ApproxRecNo:     TSQLMemRecordNo;
  ApproxRecCount:  TSQLMemRecordNo;
begin
  ApproxRecNo := 0;
  ApproxRecCount := 1;
  for i := Count-1 downto 0 do
   begin
     ApproxRecNo := Items[i].EntryNo * ApproxRecCount + ApproxRecNo;
     ApproxRecCount := Items[i].EntryCount * ApproxRecCount;
   end;
  Result := ApproxRecNo / ApproxRecCount;
end;// GetApproxRecNoInPercents


//------------------------------------------------------------------------------
// assign key path
//------------------------------------------------------------------------------
procedure TSQLMemKeyPath.Assign(Source: TSQLMemKeyPath);
var i: Integer;
begin
  Count := Source.Count;
  ItemNo := Source.ItemNo;
  for i := 0 to Source.Count-1 do
   Items[i] := Source.Items[i];
end; // Assign


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBTreeKeyRef
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// get count of key parts
//------------------------------------------------------------------------------
function TSQLMemBTreeKeyRef.GetPartCount: Integer;
begin
  Result := Length(Parts);
end;// GetPartCount


//------------------------------------------------------------------------------
// set size of array
//------------------------------------------------------------------------------
procedure TSQLMemBTreeKeyRef.SetPartCount(Value: Integer);
begin
  SetLength(Parts, Value);
end;// SetPartCount


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TSQLMemBTreeKeyRef.Create;
begin
  PartCount := 0;
  FKeySize := 0;
  FKeyIsReference := False;
  FReferenceSize := 0;
  FCompareFieldCount := 0;
end;// Create


//------------------------------------------------------------------------------
// assign IndexDef
//------------------------------------------------------------------------------
procedure TSQLMemBTreeKeyRef.Assign(IndexDef: TSQLMemIndexDef; aTableData: Pointer);
var
  i: Integer;
  OffsetInKeyBuffer: Integer;
  TableData: TSQLMemTableData;
  FieldDef: TSQLMemFieldDef;
begin
  TableData := TSQLMemTableData(aTableData);
  PartCount := IndexDef.ColumnCount;
  FCompareFieldCount := PartCount;
  OffsetInKeyBuffer := 0;
  FKeySize := 0;
  if (TableData.FieldManager = nil) then
    raise ESQLMemException.Create(20044, ErrorANilPointer);
  if (TableData.FieldManager.FieldDefs = nil) then
    raise ESQLMemException.Create(20045, ErrorANilPointer);
  for i := 0 to IndexDef.ColumnCount-1 do
   begin
    Parts[i].OffsetInKeyBuffer := OffsetInKeyBuffer;
    FieldDef := TableData.FieldManager.FieldDefs.GetFieldDefByName(
                         IndexDef.Columns[i].FieldName
                                                                   );
    if (FieldDef = nil) then
     raise ESQLMemException.Create(20043, ErrorACannotFindIndexField,
                                [IndexDef.Columns[i].FieldName]);

    Parts[i].OffsetInRecordBuffer := FieldDef.MemoryOffset;
    Parts[i].FieldNo := TableData.FieldManager.FieldDefs.GetDefNumberByName(
          IndexDef.Columns[i].FieldName);
    Parts[i].Size := FieldDef.MemoryDataSize+BTreeNullFlagSize;
    OffsetInKeyBuffer := OffsetInKeyBuffer + Parts[i].Size;
    FKeySize := FKeySize + Parts[i].Size;
    Parts[i].DataType := FieldDef.BaseFieldType;
    Parts[i].Descending := IndexDef.Columns[i].Descending;
    Parts[i].CaseInsensitive := IndexDef.Columns[i].CaseInsensitive;
   end;
end;// Assign


//------------------------------------------------------------------------------
// allocate buffer for key
//------------------------------------------------------------------------------
function TSQLMemBTreeKeyRef.AllocKeyBuffer: PAnsiChar;
begin
  Result := MemoryManager.AllocMem(FKeySize);
end;// AllocKeyBuffer


//------------------------------------------------------------------------------
// free key buffer
//------------------------------------------------------------------------------
procedure TSQLMemBTreeKeyRef.FreeAndNilKeyBuffer(var Buffer: PAnsiChar);
begin
  MemoryManager.FreeAndNilMem(Buffer);
end;// FreeAndNilKeyBuffer


//------------------------------------------------------------------------------
// MakeKeyFromRecordBuffer
//------------------------------------------------------------------------------
procedure TSQLMemBTreeKeyRef.MakeKeyFromRecordBuffer(RecordBuffer: PAnsiChar; KeyBuffer: PAnsiChar);
var i: Integer;
{$I SQLMem_check_null_flag_var.inc}
begin
{$IFDEF DEBUG_TRACE_TSQLMemBTreeKeyRef_MakeKeyFromRecordBuffer}
aaWriteToLog('TSQLMemBTreeKeyRef.MakeKeyFromRecordBuffer '+#13#10+
'PartCount = '+IntTostr(PartCount));
{$ENDIF}
  CHECK_NULL_FLAG_NullFlags := RecordBuffer;
  for i := 0 to PartCount-1 do
   begin
    CHECK_NULL_FLAG_BitNo := Parts[i].FieldNo;
    {$I SQLMem_check_null_flag.inc}
    if (CHECK_NULL_FLAG_Result) then
     begin
{$IFDEF DEBUG_TRACE_TSQLMemBTreeKeyRef_MakeKeyFromRecordBuffer}
aaWriteToLog('TSQLMemBTreeKeyRef.MakeKeyFromRecordBuffer '+#13#10+
'i = '+IntToStr(i)+' - Key value: NULL');
{$ENDIF}
      (KeyBuffer+Parts[i].OffsetInKeyBuffer)^ := BTreeKeyIsNull;
     end
    else
     begin
      (KeyBuffer+Parts[i].OffsetInKeyBuffer)^ := BTreeKeyIsNotNull;
      Move((RecordBuffer+Parts[i].OffsetInRecordBuffer)^,
           (KeyBuffer+Parts[i].OffsetInKeyBuffer+BTreeNullFlagSize)^,
           Parts[i].Size-BTreeNullFlagSize);
{$IFDEF DEBUG_TRACE_TSQLMemBTreeKeyRef_MakeKeyFromRecordBuffer}
aaWriteToLog('TSQLMemBTreeKeyRef.MakeKeyFromRecordBuffer '+#13#10+
'i = '+IntToStr(i)
//+' - Key value: '
);
//aaWriteBufferToLog(RecordBuffer+Parts[i].OffsetInRecordBuffer,Parts[i].Size-BTreeNullFlagSize);
if ((Parts[i].Size-BTreeNullFlagSize) = 4) then
 aaWriteToLog('KeyValue.AsInteger = '+IntToStr(pInteger(RecordBuffer+Parts[i].OffsetInRecordBuffer)^));
{$ENDIF}
     end;
   end;
end;// MakeKeyFromRecordBuffer


//------------------------------------------------------------------------------
// compare two keys in index order sense
//------------------------------------------------------------------------------
function TSQLMemBTreeKeyRef.CompareKeys(KeyBuffer1, KeyBuffer2: PAnsiChar): Integer;
var
  i: Integer;
  {$I SQLMem_cmp_buffers_var.inc}
begin
  Result := 0;
  CMP_BUF_PartialCompareLength := -1;
{$IFDEF MSWINDOWS}
  CMP_BUF_LocaleID := LOCALE_USER_DEFAULT;
{$ENDIF}
  for i := 0 to CompareFieldCount-1 do
   begin
    // optimized in v.5.60
    CMP_BUF_Buffer1 := KeyBuffer1 + Parts[i].OffsetInKeyBuffer + BTreeNullFlagSize;
    CMP_BUF_Buffer2 := KeyBuffer2 + Parts[i].OffsetInKeyBuffer + BTreeNullFlagSize;
    CMP_BUF_BaseFieldType1 := Parts[i].DataType;
    CMP_BUF_BaseFieldType2 := CMP_BUF_BaseFieldType1;
    CMP_BUF_IsField1Null := ((KeyBuffer1 + Parts[i].OffsetInKeyBuffer)^ = BTreeKeyIsNull);
    CMP_BUF_IsField2Null := ((KeyBuffer2 + Parts[i].OffsetInKeyBuffer)^ = BTreeKeyIsNull);
    CMP_BUF_IgnoreCase := Parts[i].CaseInsensitive;
    {$I SQLMem_cmp_buffers.inc}
    case CMP_BUF_Result of
     cmprBothNull, cmprEqual:    Result := 0;
     cmprLeftNull, cmprLower:    Result := -1;
     cmprRightNull, cmprGreater: Result := 1;
    else
     Result := 0;
    end;

    if (Parts[i].Descending) then
     Result := -Result;
    if (Result <> 0) then
     break;
   end;
end;// CompareKeys


//------------------------------------------------------------------------------
// CompareReferences
//------------------------------------------------------------------------------
function TSQLMemBTreeKeyRef.CompareReferences(Reference1, Reference2: PAnsiChar; Size: Integer): Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 0 to Size-1 do
   if ((Reference1+i)^ <> (Reference2+i)^) then
    begin
     Result := False;
     break;
    end;
end;// CompareReferences




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBTreePageController
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// get IsRoot
//------------------------------------------------------------------------------
function TSQLMemBTreePage.GetIsRoot: Boolean;
begin
  Result := PSQLMemBTreePageHeader(PageBuffer)^.IsRoot;
end;// GetIsRoot


//------------------------------------------------------------------------------
// set IsRoot
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.SetIsRoot(Value: Boolean);
begin
  PSQLMemBTreePageHeader(PageBuffer)^.IsRoot := Value;
end;// SetIsRoot


//------------------------------------------------------------------------------
// get IsLeaf
//------------------------------------------------------------------------------
function TSQLMemBTreePage.GetIsLeaf: Boolean;
begin
  Result := PSQLMemBTreePageHeader(PageBuffer)^.IsLeaf;
end;// GetIsLeaf


//------------------------------------------------------------------------------
// set IsLeaf
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.SetIsLeaf(Value: Boolean);
begin
  PSQLMemBTreePageHeader(PageBuffer)^.IsLeaf := Value;
end;// SetIsLeaf


//------------------------------------------------------------------------------
// get Left page No
//------------------------------------------------------------------------------
function TSQLMemBTreePage.GetLeftPageNo: TSQLMemPageNo;
begin
  Result := PSQLMemBTreePageHeader(PageBuffer)^.LeftPageNo;
end;// GetLeftPageNo


//------------------------------------------------------------------------------
// set LeftPageNo
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.SetLeftPageNo(Value: TSQLMemPageNo);
begin
  PSQLMemBTreePageHeader(PageBuffer)^.LeftPageNo := Value;
end;// SetLeft


//------------------------------------------------------------------------------
// get right PageNo
//------------------------------------------------------------------------------
function TSQLMemBTreePage.GetRightPageNo: TSQLMemPageNo;
begin
  Result := PSQLMemBTreePageHeader(PageBuffer)^.RightPageNo;
end;// GetRightPageNo


//------------------------------------------------------------------------------
// set Right PageNo
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.SetRightPageNo(Value: TSQLMemPageNo);
begin
  PSQLMemBTreePageHeader(PageBuffer)^.RightPageNo := Value;
end;// SetRightPageNo


//------------------------------------------------------------------------------
// get (page has keys or only references?)
//------------------------------------------------------------------------------
function TSQLMemBTreePage.GetHasKeys: Boolean;
begin
  Result := PSQLMemBTreePageHeader(PageBuffer)^.HasKeys;
end;// GetHasKeys


//------------------------------------------------------------------------------
// set HasKeys
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.SetHasKeys(Value: Boolean);
begin
  PSQLMemBTreePageHeader(PageBuffer)^.HasKeys := Value;
end;// SetHasKeys


//------------------------------------------------------------------------------
// get (key has suffix?)
//------------------------------------------------------------------------------
function TSQLMemBTreePage.GetHasSuffixes: Boolean;
begin
  Result := PSQLMemBTreePageHeader(PageBuffer)^.HasSuffixes;
end;// GetHasSuffixes


//------------------------------------------------------------------------------
// set KeyHasSuffix
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.SetHasSuffixes(Value: Boolean);
begin
  PSQLMemBTreePageHeader(PageBuffer)^.HasSuffixes := Value;
end;// SetHasSuffixes


//------------------------------------------------------------------------------
// get key prefix size
//------------------------------------------------------------------------------
function TSQLMemBTreePage.GetKeyPrefixSize: Word;
begin
  Result := PSQLMemBTreePageHeader(PageBuffer)^.KeyPrefixSize;
end;// GetKeyPrefixSize


//------------------------------------------------------------------------------
// set key prefix size
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.SetKeyPrefixSize(Value: Word);
begin
  PSQLMemBTreePageHeader(PageBuffer)^.KeyPrefixSize := Value;
end;// SetKeyPrefixSize


//------------------------------------------------------------------------------
// get entry count
//------------------------------------------------------------------------------
function TSQLMemBTreePage.GetEntryCount: Integer;
begin
  Result := PSQLMemBTreePageHeader(PageBuffer)^.EntryCount;
end;// GetEntryCount


//------------------------------------------------------------------------------
// set Entry count
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.SetEntryCount(Value: Integer);
begin
  PSQLMemBTreePageHeader(PageBuffer)^.EntryCount := Value;
end;// SetEntryCount


//------------------------------------------------------------------------------
// get page prefix size
//------------------------------------------------------------------------------
function TSQLMemBTreePage.GetPagePrefixSize: Word;
begin
  Result := PSQLMemBTreePageHeader(PageBuffer)^.PagePrefixSize;
end;// GetPagePrefixSize


//------------------------------------------------------------------------------
// set page prefix size
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.SetPagePrefixSize(Value: Word);
begin
  PSQLMemBTreePageHeader(PageBuffer)^.PagePrefixSize := Value;
end;// GetPagePrefixSize


//------------------------------------------------------------------------------
// GetEntrySize
//------------------------------------------------------------------------------
function TSQLMemBTreePage.GetEntrySize: Integer;
begin
  Result := KeyPrefixSize + ReferenceSize;
  if (HasSuffixes) then
    Result := Result + SuffixPtrSize;
end;// GetEntrySize


//------------------------------------------------------------------------------
// GetReferenceSize
//------------------------------------------------------------------------------
function TSQLMemBTreePage.GetReferenceSize: Integer;
begin
  if (IsLeaf) then
   Result := FKeyRef.ReferenceSize
  else
   Result := sizeof(TSQLMemPageNo);
end;// GetReferenceSize


//------------------------------------------------------------------------------
// GetEntriesOffset
//------------------------------------------------------------------------------
function TSQLMemBTreePage.GetEntriesOffset: Integer;
begin
  Result := sizeof(TSQLMemBTreePageHeader) + PagePrefixSize;
end;// GetEntriesOffset


//------------------------------------------------------------------------------
// GetSuffixPtrSize
//------------------------------------------------------------------------------
function TSQLMemBTreePage.GetSuffixPtrSize: Integer;
begin
  Result := sizeof(TSQLMemRecordID);
end;// GetSuffixPtrSize


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemBTreePage.Create(BTreeIndex: TSQLMemBTreeIndex; Page: TSQLMemPage);
begin
  inherited Create(Page);
  LBTreeIndex := BTreeIndex;
  FKeyRef := BTreeIndex.KeyRef;
  FLeafController := TSQLMemBTreeLeafController.Create(Self,LBTreeIndex.LTableData);
  FNodeController := TSQLMemBTreeNodeController.Create(Self,LBTreeIndex.LTableData);
end;// Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TSQLMemBTreePage.Destroy;
begin
  FLeafController.Free;
  FNodeController.Free;
  inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// init data
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.Init;
begin
  IsRoot := False;
  IsLeaf := False;
  LeftPageNo := INVALID_PAGE_NO;
  RightPageNo := INVALID_PAGE_NO;
  HasKeys := False;
  HasSuffixes := False;
  KeyPrefixSize := 0;
  EntryCount := 0;
  PagePrefixSize := 0;
end;// Init


//------------------------------------------------------------------------------
// init as root leaf
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.InitAsRoot;
begin
  Init;
  IsRoot := True;
  IsLeaf := True;
  HasKeys := True;
  HasSuffixes := False;
  PagePrefixSize := 0;
  KeyPrefixSize := FKeyRef.KeySize;
end;// InitAsRoot


//------------------------------------------------------------------------------
// CopyFrom
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.CopyFrom(Source: TSQLMemBTreePage; StartNo, Count: Integer);
begin
  Move(
       Source.PageBuffer^,
       PageBuffer^,
       Source.EntriesOffset);
  Move((Source.PageBuffer+Source.EntriesOffset+StartNo*Source.EntrySize)^,
       (PageBuffer+Source.EntriesOffset)^,
       Source.EntrySize * Count);
  EntryCount := Count;
end;// CopyFrom


//------------------------------------------------------------------------------
// AppendFrom
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.AppendFrom(Source: TSQLMemBTreePage; StartNo, Count: Integer);
begin
  Move((Source.PageBuffer+Source.EntriesOffset+StartNo*Source.EntrySize)^,
       (PageBuffer+EntriesOffset+EntryCount*EntrySize)^,
       Source.EntrySize*Count);
  EntryCount := EntryCount + Count;
end;// AppendFrom


//------------------------------------------------------------------------------
// InsertFrom
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.InsertFrom(Source: TSQLMemBTreePage; StartNo, Count: Integer);
begin
  SQLMemMove(
          (PageBuffer + EntriesOffset)^,
          (PageBuffer + EntriesOffset + Count * EntrySize)^,
          EntrySize * EntryCount
         );

  Move((Source.PageBuffer+Source.EntriesOffset+StartNo*Source.EntrySize)^,
       (PageBuffer+EntriesOffset)^,
       Source.EntrySize*Count);
  EntryCount := EntryCount + Count;
end;// InsertFrom


//------------------------------------------------------------------------------
// InsertLeafEntry
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.InsertLeafEntry(SessionID: TSQLMemSessionID; Key, Reference: PAnsiChar; KeyPath: TSQLMemKeyPath);
begin
  if (IsLeaf) then
    FLeafController.InsertLeafEntry(SessionID, Key, Reference, KeyPath)
  else
    FNodeController.InsertLeafEntry(SessionID, Key, Reference, KeyPath);
end;// InsertLeafEntry


//------------------------------------------------------------------------------
// InsertNodeEntry
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.InsertNodeEntry(SessionID: TSQLMemSessionID; Key, Reference: PAnsiChar; KeyPath: TSQLMemKeyPath);
begin
  if (IsLeaf) then
    raise ESQLMemException.Create(20020, ErrorABTreeInvalidCall)
  else
    FNodeController.InsertNodeEntry(SessionID, Key, Reference, KeyPath);
end;// InsertNodeEntry


//------------------------------------------------------------------------------
// DeleteLeafEntry
//------------------------------------------------------------------------------
function TSQLMemBTreePage.DeleteLeafEntry(SessionID: TSQLMemSessionID; Key, Reference: PAnsiChar; KeyPath: TSQLMemKeyPath): Boolean;
begin
  if (IsLeaf) then
    Result := FLeafController.DeleteLeafEntry(SessionID, Key, Reference, KeyPath)
  else
    Result := FNodeController.DeleteLeafEntry(SessionID, Key, Reference, KeyPath);
end;// DeleteLeafEntry


//------------------------------------------------------------------------------
// DeleteNodeEntry
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.DeleteNodeEntry(
                  SessionID:     TSQLMemSessionID;
                  KeyPath:       TSQLMemKeyPath;
                  MergeWithLeft: Boolean
                        );
begin
  if (IsLeaf) then
    raise ESQLMemException.Create(20024, ErrorABTreeInvalidCall)
  else
    FNodeController.DeleteNodeEntry(SessionID, KeyPath, MergeWithLeft);
end;// DeleteNodeEntry


//------------------------------------------------------------------------------
// FindEntry
//------------------------------------------------------------------------------
function TSQLMemBTreePage.FindEntry(
                          SessionID: TSQLMemSessionID;
                          Key:       PAnsiChar;
                          Reference: PAnsiChar;
                          Position:  TSQLMemKeyPath
                         ): Boolean;
begin
//aaIncCounter(counter4);
  if (IsLeaf) then
   begin
    Result := FLeafController.FindEntry(SessionID, Key, Reference, Position);
   end
  else
   begin
    Result := FNodeController.FindEntry(SessionID, Key, Reference, Position);
   end;
end;// FindEntry


//------------------------------------------------------------------------------
// GetFirstPosition
//------------------------------------------------------------------------------
function TSQLMemBTreePage.GetFirstPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean;
begin
  if (IsLeaf) then
    Result := FLeafController.GetFirstPosition(SessionID, Position)
  else
    Result := FNodeController.GetFirstPosition(SessionID, Position);
end;// GetFirstPosition


//------------------------------------------------------------------------------
// GetLastPosition
//------------------------------------------------------------------------------
function TSQLMemBTreePage.GetLastPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean;
begin
  if (IsLeaf) then
    Result := FLeafController.GetLastPosition(SessionID, Position)
  else
    Result := FNodeController.GetLastPosition(SessionID, Position);
end;// Last


//------------------------------------------------------------------------------
// FindByCondition
//------------------------------------------------------------------------------
function TSQLMemBTreePage.FindByCondition(
                              SessionID: TSQLMemSessionID;
                              First:     Boolean; // if False => Last
                              Key:       PAnsiChar;
                              Operator:  TSQLMemSearchCondition;
                              Position:  TSQLMemKeyPath
                             ): Boolean;
begin
  if (EntryCount = 0) then
    Result := False
  else
   if (IsLeaf) then
     Result := FLeafController.FindByCondition(SessionID, First, Key, Operator, Position)
   else
     Result := FNodeController.FindByCondition(SessionID, First, Key, Operator, Position);
end;// FindByCondition


//------------------------------------------------------------------------------
// FreeAllPages
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.FreeAllPages(SessionID: TSQLMemSessionID; RootPageNo: TSQLMemPageNo);
begin
  if (IsLeaf) then
    FLeafController.FreeAllPages(SessionID,RootPageNo)
  else
    FNodeController.FreeAllPages(SessionID,RootPageNo);
end;// FreeAllPages


//------------------------------------------------------------------------------
// CheckIntegrity
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.CheckIntegrity(SessionID: TSQLMemSessionID; KeyPath: TSQLMemKeyPath);
begin
  if (IsLeaf) then
    FLeafController.CheckIntegrity(SessionID, KeyPath)
  else
    FNodeController.CheckIntegrity(SessionID, KeyPath);
end;// CheckIntegrity


//------------------------------------------------------------------------------
// GetPKey
//------------------------------------------------------------------------------
function TSQLMemBTreePage.GetPKey(KeyPosition: Integer): PAnsiChar;
begin
  Result := PageBuffer+EntriesOffset+KeyPosition*EntrySize;
end;// GetPKey


//------------------------------------------------------------------------------
// GetPReference
//------------------------------------------------------------------------------
function TSQLMemBTreePage.GetPReference(RefPosition: Integer): PAnsiChar;
begin
  Result := GetPKey(RefPosition) + KeyPrefixSize;
end;// GetPReference


//------------------------------------------------------------------------------
// GetFirstKey
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.GetFirstKey(SessionID: TSQLMemSessionID; Key: PAnsiChar);
begin
  if (IsLeaf) then
    FLeafController.GetFirstKey(SessionID, Key)
  else
    FNodeController.GetFirstKey(SessionID, Key);
end;// GetFirstKey


//------------------------------------------------------------------------------
// GetLastKey
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.GetLastKey(SessionID: TSQLMemSessionID; Key: PAnsiChar);
begin
  if (IsLeaf) then
    FLeafController.GetLastKey(SessionID, Key)
  else
    FNodeController.GetLastKey(SessionID, Key);
end;// GetLastKey


//------------------------------------------------------------------------------
// UpdateKey
//------------------------------------------------------------------------------
procedure TSQLMemBTreePage.UpdateKey(Position: Integer; Key: PAnsiChar);
begin
  Move(Key^, GetPKey(Position)^, KeyPrefixSize);
end;// UpdateKey





////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBTreePageController
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// GetKeyRef
//------------------------------------------------------------------------------
function TSQLMemBTreePageController.GetKeyRef: TSQLMemBTreeKeyRef;
begin
  Result := FPage.KeyRef;
end;// GetKeyRef


//------------------------------------------------------------------------------
// Can Add Entry?
//------------------------------------------------------------------------------
function TSQLMemBTreePageController.CanAddEntry: Boolean;
begin
  if (FPage.PageSize >= sizeof(TSQLMemBTreePageHeader) + FPage.PagePrefixSize +
                       (FPage.EntryCount+1)*FPage.EntrySize) then
    Result := True
  else
    Result := False;
end;// CanAddEntry


//------------------------------------------------------------------------------
// IsOverflow
//------------------------------------------------------------------------------
function TSQLMemBTreePageController.IsOverflow: Boolean;
begin
  if (FPage.PageSize < sizeof(TSQLMemBTreePageHeader) + FPage.PagePrefixSize +
                       FPage.EntryCount*FPage.EntrySize) then
    Result := True
  else
    Result := False;
end;// IsOverflow


//------------------------------------------------------------------------------
// CanUnderflow
//------------------------------------------------------------------------------
function TSQLMemBTreePageController.CanUnderflow: Boolean;
begin
  if ((not FPage.IsRoot) and
      ((FPage.PageSize - sizeof(TSQLMemBTreePageHeader) - FPage.PagePrefixSize) div 2 >
                       FPage.EntryCount*FPage.EntrySize)) then
    Result := True
  else
    Result := False;
end;// CanUnderflow


//------------------------------------------------------------------------------
// CanMergeWithPage
//------------------------------------------------------------------------------
function TSQLMemBTreePageController.CanMergeWithPage(Page: TSQLMemBTreePage): Boolean;
begin
  Result := (Page.PageSize >
             FPage.EntriesOffset + (FPage.EntryCount+Page.EntryCount)*FPage.EntrySize);
end;// CanMergeWithPage


//------------------------------------------------------------------------------
// EnlargePageBuffer
//------------------------------------------------------------------------------
procedure TSQLMemBTreePageController.EnlargePageBuffer;
begin
  FPage.EnlargePageBuffer(FPage.PageSize + FPage.EntrySize);
end;// EnlargePageBuffer


//------------------------------------------------------------------------------
// Compare Keys
//------------------------------------------------------------------------------
function TSQLMemBTreePageController.CompareKeys(Key1: PAnsiChar; Key2Index: Word): Integer;
begin
  Result := KeyRef.CompareKeys(Key1, GetPKey(Key2Index));
end;// CompareKeys


//------------------------------------------------------------------------------
// Compare Keys
//------------------------------------------------------------------------------
function TSQLMemBTreePageController.CompareKeys(Key1, Key2: PAnsiChar; KeyRef: TSQLMemBTreeKeyRef): Integer;
begin
  Result := KeyRef.CompareKeys(Key1, Key2);
end; // CompareKeys


//------------------------------------------------------------------------------
// CompareReferences
//------------------------------------------------------------------------------
function TSQLMemBTreePageController.CompareReferences(
                             Reference1: PAnsiChar; Reference2Index: Word): Boolean;
begin
  Result := KeyRef.CompareReferences(Reference1,
                                     GetPReference(Reference2Index),
                                     FPage.ReferenceSize);
end;// CompareReferences


//------------------------------------------------------------------------------
// get key position for insert (binary search)
//------------------------------------------------------------------------------
function TSQLMemBTreePageController.GetKeyPosition(
                       Key: PAnsiChar;
                       StartPosition: Integer = 0;
                       PositionType: PSQLMemKeyPathPosition = nil;
                       SearchType: TSQLMemKeySearchType = kstAny
                                ): Word;
var
  Lb, Ub, M: Integer;
  CmpRes, Pos, Delta: integer;
begin
  Pos := -1;
  Delta := 0;
  if (FPage.EntryCount = 0) then
   begin
    Result := 0;
    if (PositionType <> nil) then
     PositionType^ := kppEOF;
   end
  else
   begin
    Lb := StartPosition;
    Ub := FPage.EntryCount-1;
    repeat
      M := (Lb + Ub) div 2;
      CmpRes := CompareKeys(Key, M);
      if (CmpRes < 0) then
        Ub := M - 1
      else if (CmpRes > 0) then
        Lb := M + 1
      else
       begin
        Pos := M;
        if (PositionType <> nil) then
         PositionType^ := kppOnKey;
        case (SearchType) of
         kstFirst:
          Delta := -1;
         kstLast:
          Delta := 1;
         kstAny:
          Delta := 0;
         end;
        if (Delta <> 0) then
         repeat
          M := M + Delta;
          if ((M < StartPosition) or
              (M > FPage.EntryCount-1)) then
           break;
          CmpRes := CompareKeys(Key, M);
          if (CmpRes = 0) then
           Pos := M
         until (CmpRes <> 0);
        break;
       end;
      if (Lb > Ub) then
       begin
         Pos := Lb;
         if (PositionType <> nil) then
          PositionType^ := kppBeforeKey;
         break;
       end;
    until False;
    Result := Pos;
   end;
end;// GetKeyPosition


//------------------------------------------------------------------------------
// InsertEntry
//------------------------------------------------------------------------------
procedure TSQLMemBTreePageController.InsertEntry(
                  Key, Reference: PAnsiChar;
                  Position: Integer
                                              );
begin
  if (not CanAddEntry ) then
   EnlargePageBuffer;
  SQLMemMove(
           GetPKey(Position)^,
           GetPKey(Position+1)^,
           (FPage.EntryCount - Position) * FPage.EntrySize
         );
  FillChar(GetPKey(Position)^, FPage.KeyPrefixSize, #0);
  if (Key <> nil) then
   Move(Key^, GetPKey(Position)^, FPage.KeyPrefixSize);
  Move(Reference^, GetPReference(Position)^, FPage.ReferenceSize);
  FPage.EntryCount := FPage.EntryCount + 1;
end;// InsertEntry


//------------------------------------------------------------------------------
// DeleteEntry
//------------------------------------------------------------------------------
procedure TSQLMemBTreePageController.DeleteEntry(Position: Integer);
begin
  if (FPage.EntryCount > 0) then
   begin
    SQLMemMove(
            GetPKey(Position+1)^,
            GetPKey(Position)^,
            (FPage.EntryCount-1 - Position) * FPage.EntrySize
           );
    FPage.EntryCount := FPage.EntryCount - 1;
   end
  else
   raise ESQLMemException.Create(20025, ErrorABTreeEmptyPage);
end;// DeleteEntry


//------------------------------------------------------------------------------
// RootSplit
//------------------------------------------------------------------------------
procedure TSQLMemBTreePageController.RootSplit(SessionID: TSQLMemSessionID; KeyPath: TSQLMemKeyPath);
var
  MiddleEntryNo: Integer;
  LeftPage, RightPage: TSQLMemBTreePage;
  LeftPageNo, RightPageNo: Integer;
begin
  LeftPage := FPage.LBTreeIndex.AddIndexPage(SessionID);
  RightPage := FPage.LBTreeIndex.AddIndexPage(SessionID);
  try
   MiddleEntryNo := FPage.EntryCount div 2;
   LeftPage.CopyFrom(FPage, 0, MiddleEntryNo);
   RightPage.CopyFrom(FPage, MiddleEntryNo, FPage.EntryCount-MiddleEntryNo);
   LeftPage.IsRoot := False;
   RightPage.IsRoot := False;
   LeftPage.RightPageNo := RightPage.PageNo;
   RightPage.LeftPageNo := LeftPage.PageNo;

   FPage.IsLeaf := False;
   FPage.EntryCount := 0;
   LeftPageNo := LeftPage.PageNo;
   FPage.InsertNodeEntry(
            SessionID,
            nil,
            @LeftPageNo,
            KeyPath);
   LeftPage.PageNo := LeftPageNo;
   RightPageNo := RightPage.PageNo;
   FPage.InsertNodeEntry(
            SessionID,
            RightPage.GetPKey(0),
            @RightPageNo,
            KeyPath);
   RightPage.PageNo := RightPageNo;
   // FPage.IsDirty := True;
   LTableData.UpdatePage(SessionID,FPage.Page,dbstIndex,
                         LTableData.TableState.TableState,False);

  finally
   FPage.LBTreeIndex.PutIndexPage(LeftPage);
   FPage.LBTreeIndex.PutIndexPage(RightPage);
  end;
end;// RootSplit


//------------------------------------------------------------------------------
// NonRootSplit
//------------------------------------------------------------------------------
procedure TSQLMemBTreePageController.NonRootSplit(SessionID: TSQLMemSessionID; KeyPath: TSQLMemKeyPath);
var
  MiddleEntryNo: Integer;
  ParentPage, NewRightPage, PrevRightPage: TSQLMemBTreePage;
  RightPageNo: Integer;
begin
  ParentPage := nil;
  PrevRightPage := nil;
  NewRightPage := FPage.LBTreeIndex.AddIndexPage(SessionID);
  try
   MiddleEntryNo := FPage.EntryCount div 2;
   NewRightPage.CopyFrom(FPage, MiddleEntryNo, FPage.EntryCount-MiddleEntryNo);
   NewRightPage.RightPageNo := FPage.RightPageNo;
   NewRightPage.LeftPageNo := FPage.PageNo;
//   NewRightPage.IsDirty := True;
   LTableData.UpdatePage(SessionID,NewRightPage.Page,dbstIndex,
                         LTableData.TableState.TableState,False);
   if (NewRightPage.RightPageNo <> INVALID_PAGE_NO) then
    begin
     PrevRightPage := FPage.LBTreeIndex.GetIndexPage(SessionID, NewRightPage.RightPageNo);
     PrevRightPage.LeftPageNo := NewRightPage.PageNo;
//     PrevRightPage.IsDirty := True;
     LTableData.UpdatePage(SessionID,PrevRightPage.Page,dbstIndex,
                         LTableData.TableState.TableState,False);
    end;
   FPage.RightPageNo := NewRightPage.PageNo;
   FPage.EntryCount := MiddleEntryNo;
   LTableData.UpdatePage(SessionID,FPage.Page,dbstIndex,
                         LTableData.TableState.TableState,False);
//   FPage.IsDirty := True;

   KeyPath.DecLevel;
   ParentPage := FPage.LBTreeIndex.GetIndexPage(SessionID, KeyPath.CurrentPageNo);
   RightPageNo := NewRightPage.PageNo;
   ParentPage.InsertNodeEntry(
            SessionID,
            NewRightPage.GetPKey(0),
            @RightPageNo,
            KeyPath);
   NewRightPage.PageNo := RightPageNo;
   LTableData.UpdatePage(SessionID,ParentPage.Page,dbstIndex,
                         LTableData.TableState.TableState,False);
//   ParentPage.IsDirty := True;
   KeyPath.IncLevel;
  finally
   if (NewRightPage <> nil) then
    FPage.LBTreeIndex.PutIndexPage(NewRightPage);
   if (PrevRightPage <> nil) then
    FPage.LBTreeIndex.PutIndexPage(PrevRightPage);
   if (ParentPage <> nil) then
    FPage.LBTreeIndex.PutIndexPage(ParentPage);
  end;
end;// NonRootSplit


//------------------------------------------------------------------------------
// TryMergeWithPage
//------------------------------------------------------------------------------
function TSQLMemBTreePageController.TryMergeWithPage(
                        SessionID:   TSQLMemSessionID;
                        MergePageNo: TSQLMemPageNo;
                        KeyPath:     TSQLMemKeyPath
                                                  ): Boolean;
var
  MergePage: TSQLMemBTreePage;
begin
  MergePage := nil;
  try
    MergePage := FPage.LBTreeIndex.GetIndexPage(SessionID, MergePageNo);
    Result := CanMergeWithPage(MergePage);
    if (Result) then
     begin
       if (MergePageNo = FPage.LeftPageNo) then
        MergeWithLeftPage(SessionID, MergePage, KeyPath)
       else
        MergeWithRightPage(SessionID, MergePage, KeyPath);
       FPage.LBTreeIndex.RemoveIndexPage(SessionID, FPage.PageNo);
     end;
  finally
   if (MergePage <> nil) then
    FPage.LBTreeIndex.PutIndexPage(MergePage);
  end;
end;// TryMergeWithPage


//------------------------------------------------------------------------------
// TryMerge
//------------------------------------------------------------------------------
function TSQLMemBTreePageController.TryMerge(SessionID: TSQLMemSessionID; KeyPath: TSQLMemKeyPath): Boolean;
begin
  Result := False;
  if (not FPage.IsRoot) then
   begin
     if (FPage.LeftPageNo <> INVALID_PAGE_NO) then
      Result := TryMergeWithPage(SessionID, FPage.LeftPageNo, KeyPath);
     if (not Result) then
      if (FPage.RightPageNo <> INVALID_PAGE_NO) then
       Result := TryMergeWithPage(SessionID, FPage.RightPageNo, KeyPath);
   end;
end;// TryMerge


//------------------------------------------------------------------------------
// MergeWithLeftPage
//------------------------------------------------------------------------------
procedure TSQLMemBTreePageController.MergeWithLeftPage(
                        SessionID: TSQLMemSessionID;
                        LeftPage: TSQLMemBTreePage;
                        KeyPath: TSQLMemKeyPath
                                );
var
  ParentPage: TSQLMemBTreePage;
  RightPage:  TSQLMemBTreePage;
  ChildPage:  TSQLMemBTreePage;
begin
  ParentPage := nil;
  RightPage := nil;
  ChildPage := nil;
  try
    if (FPage.RightPageNo <> INVALID_PAGE_NO) then
     begin
       RightPage := FPage.LBTreeIndex.GetIndexPage(SessionID, FPage.RightPageNo);
       RightPage.LeftPageNo := FPage.LeftPageNo;
       LTableData.UpdatePage(SessionID,RightPage.Page,dbstIndex,
                             LTableData.TableState.TableState,False);
//       RightPage.IsDirty := True;
     end;

    KeyPath.DecLevel;
    ParentPage := FPage.LBTreeIndex.GetIndexPage(SessionID, KeyPath.CurrentPageNo);
    if (not FPage.IsLeaf) then
      GetFirstKey(SessionID, GetPKey(0));
    LeftPage.AppendFrom(FPage, 0, FPage.EntryCount);
    LeftPage.RightPageNo := FPage.RightPageNo;
//    LeftPage.IsDirty := True;
    LTableData.UpdatePage(SessionID,LeftPage.Page,dbstIndex,
                         LTableData.TableState.TableState,False);
    ParentPage.DeleteNodeEntry(SessionID, KeyPath, True);
  finally
   if (ParentPage <> nil) then
    FPage.LBTreeIndex.PutIndexPage(ParentPage);
   if (RightPage <> nil) then
    FPage.LBTreeIndex.PutIndexPage(RightPage);
   if (ChildPage <> nil) then
    FPage.LBTreeIndex.PutIndexPage(ChildPage);
  end;
end;// MergeWithLeftPage


//------------------------------------------------------------------------------
// MergeWithRightPage
//------------------------------------------------------------------------------
procedure TSQLMemBTreePageController.MergeWithRightPage(
                        SessionID: TSQLMemSessionID;
                        RightPage: TSQLMemBTreePage;
                        KeyPath: TSQLMemKeyPath
                                );
var
  ParentPage: TSQLMemBTreePage;
  LeftPage:  TSQLMemBTreePage;
begin
  ParentPage := nil;
  try
    if (FPage.LeftPageNo <> INVALID_PAGE_NO) then
     begin
       LeftPage := FPage.LBTreeIndex.GetIndexPage(SessionID, FPage.LeftPageNo);
       LeftPage.RightPageNo := FPage.RightPageNo;
//       LeftPage.IsDirty := True;
       LTableData.UpdatePage(SessionID,LeftPage.Page,dbstIndex,
                             LTableData.TableState.TableState,False);
       FPage.LBTreeIndex.PutIndexPage(LeftPage);
     end;

    KeyPath.DecLevel;
    ParentPage := FPage.LBTreeIndex.GetIndexPage(SessionID, KeyPath.CurrentPageNo);
    if (not FPage.IsLeaf) then
      RightPage.GetFirstKey(SessionID, RightPage.GetPKey(0));
    RightPage.InsertFrom(FPage, 0, FPage.EntryCount);
    RightPage.LeftPageNo := FPage.LeftPageNo;
    LTableData.UpdatePage(SessionID,RightPage.Page,dbstIndex,
                          LTableData.TableState.TableState,False);
//    RightPage.IsDirty := True;
    ParentPage.DeleteNodeEntry(SessionID, KeyPath, False);
  finally
   if (ParentPage <> nil) then
    FPage.LBTreeIndex.PutIndexPage(ParentPage);
  end;
end;// MergeWithRightPage


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TSQLMemBTreePageController.Create(
                        aPage:        TSQLMemBTreePage;
                        aTableData:   TSQLMemTableData
                       );
begin
  FPage := aPage;
  LTableData := aTableData;
end;// Create


//------------------------------------------------------------------------------
// GetPKey
//------------------------------------------------------------------------------
function TSQLMemBTreePageController.GetPKey(KeyPosition: Integer): PAnsiChar;
begin
  Result := FPage.GetPKey(KeyPosition);
end;// GetPKey


//------------------------------------------------------------------------------
// GetPReference
//------------------------------------------------------------------------------
function TSQLMemBTreePageController.GetPReference(RefPosition: Integer): PAnsiChar;
begin
  Result := FPage.GetPReference(RefPosition);
end;// GetPReference


//------------------------------------------------------------------------------
// Split
//------------------------------------------------------------------------------
procedure TSQLMemBTreePageController.Split(SessionID: TSQLMemSessionID; KeyPath: TSQLMemKeyPath);
begin
  if (FPage.IsRoot) then
   RootSplit(SessionID, KeyPath)
  else
   NonRootSplit(SessionID, KeyPath);
end;// Split


//------------------------------------------------------------------------------
// KeyMatch
//------------------------------------------------------------------------------
function TSQLMemBTreePageController.KeyMatch(
                          KeyPosition:     Integer;
                          SearchKey:       PAnsiChar;
                          SearchCondition: TSQLMemSearchCondition
                      ): Boolean;
begin
  Result := True;
  case SearchCondition of
    scEqual:
      Result := (CompareKeys(SearchKey, KeyPosition) = 0);
    scLower:
      Result := (CompareKeys(SearchKey, KeyPosition) > 0);
    scGreater:
      Result := (CompareKeys(SearchKey, KeyPosition) < 0);
    scLowerEqual:
      Result := (CompareKeys(SearchKey, KeyPosition) >= 0);
    scGreaterEqual:
      Result := (CompareKeys(SearchKey, KeyPosition) <= 0);
  end;
end;// KeyMatch




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBTreeLeafController
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// FindEntry
//------------------------------------------------------------------------------
function TSQLMemBTreeLeafController.FindEntryOnPage(
                                           Key, Reference: PAnsiChar;
                                           var EntryNo: Integer
                                          ): Boolean;
var
  Position: Integer;
  PositionType: TSQLMemKeyPathPosition;
begin
//aaIncCounter(counter3);
  Result := False;
  EntryNo := -1;
  if (Key <> nil) then
    begin
      Position := GetKeyPosition(Key, 0, @PositionType, kstFirst);
      if (PositionType = kppOnKey) then
       begin
         repeat
           if (CompareReferences(Reference, Position)) then
            begin
              EntryNo := Position;
              Result := True;
              break;
            end
           else
            Inc(Position);
           if (Position >= FPage.EntryCount) then
            break;
         until (CompareKeys(Key, Position) <> 0);
       end;
    end
  else
   begin
     Position := 0;
     repeat
       if (CompareReferences(Reference, Position)) then
        begin
          EntryNo := Position;
          Result := True;
          break;
        end
       else
        Inc(Position);
       if (Position >= FPage.EntryCount) then
        break;
     until (False);
   end;
end;// FindEntryOnPage


//------------------------------------------------------------------------------
// FindFirstByCondition
//------------------------------------------------------------------------------
function TSQLMemBTreeLeafController.FindFirstByCondition(
                              Key:       PAnsiChar;
                              Operator:  TSQLMemSearchCondition;
                              Position:  TSQLMemKeyPath
                            ): Boolean;
var
  PositionType: TSQLMemKeyPathPosition;
  EntryNo:     Integer;
begin
  EntryNo := 0;
  Result := True;
  case Operator of
    scEqual:
      begin
        EntryNo := GetKeyPosition(Key, 0, @PositionType, kstFirst);
        if (PositionType = kppOnKey) then
          Result := True
        else
          Result := False;
      end;
    scLower:
      begin
        EntryNo := GetKeyPosition(Key, 0, @PositionType, kstFirst);
        if ((PositionType = kppOnKey) or (PositionType = kppBeforeKey)) then
          Dec(EntryNo);
        if (EntryNo >= 0) then
          begin
            EntryNo := 0;
            Result := True;
          end
        else
          Result := False;
      end;
    scGreater:
      begin
        EntryNo := GetKeyPosition(Key, 0, @PositionType, kstLast);
        if (PositionType = kppOnKey) then
          Inc(EntryNo);
        if (EntryNo < FPage.EntryCount) then
          Result := True
        else
          Result := False;
      end;
    scLowerEqual:
      begin
        EntryNo := GetKeyPosition(Key, 0, @PositionType, kstFirst);
        if (PositionType = kppBeforeKey) then
          Dec(EntryNo);
        if (EntryNo >= 0) then
          begin
            EntryNo := 0;
            Result := True;
          end
        else
          Result := False;
      end;
    scGreaterEqual:
      begin
        EntryNo := GetKeyPosition(Key, 0, @PositionType, kstFirst);
        if (EntryNo < FPage.EntryCount) then
          Result := True
        else
          Result := False;
      end;
  end;// case

  if (Result) then
    Position.AddItem(FPage.PageNo, EntryNo, FPage.EntryCount);
end;// FindFirstByCondition


//------------------------------------------------------------------------------
// FindLastByCondition
//------------------------------------------------------------------------------
function TSQLMemBTreeLeafController.FindLastByCondition(
                              Key:       PAnsiChar;
                              Operator:  TSQLMemSearchCondition;
                              Position:  TSQLMemKeyPath
                            ): Boolean;
var
  PositionType: TSQLMemKeyPathPosition;
  EntryNo:     Integer;
begin
  EntryNo := 0;
  Result := False;
  case Operator of
    scNone:
      begin
        EntryNo := FPage.EntryCount-1;
        Result := True;
      end;
    scEqual:
      begin
        EntryNo := GetKeyPosition(Key, 0, @PositionType, kstLast);
        if (PositionType = kppOnKey) then
          Result := True
        else
          Result := False;
      end;
    scLower:
      begin
        EntryNo := GetKeyPosition(Key, 0, @PositionType, kstFirst);
        if ((PositionType = kppOnKey) or (PositionType = kppBeforeKey)) then
          Dec(EntryNo);
        if (EntryNo >= 0) then
          Result := True
        else
          Result := False;
      end;
    scGreater:
      begin
        EntryNo := GetKeyPosition(Key, 0, @PositionType, kstLast);
        if (PositionType = kppOnKey) then
          Inc(EntryNo);
        if (EntryNo < FPage.EntryCount) then
          begin
            EntryNo := FPage.EntryCount-1;
            Result := True;
          end
        else
          Result := False;
      end;
    scLowerEqual:
      begin
        EntryNo := GetKeyPosition(Key, 0, @PositionType, kstLast);
        if (PositionType = kppBeforeKey) then
          Dec(EntryNo);
        if (EntryNo >= 0) then
          Result := True
        else
          Result := False;
      end;
    scGreaterEqual:
      begin
        EntryNo := GetKeyPosition(Key, 0, @PositionType, kstAny);
        if (EntryNo < FPage.EntryCount) then
          begin
            EntryNo := FPage.EntryCount-1;
            Result := True;
          end
        else
          Result := False;
      end;
  end;// case

  if (Result) then
    Position.AddItem(FPage.PageNo, EntryNo, FPage.EntryCount);
end;// FindLastByCondition


//------------------------------------------------------------------------------
// Add Leaf Entry (key, ref)
//------------------------------------------------------------------------------
procedure TSQLMemBTreeLeafController.InsertLeafEntry(
                     SessionID: TSQLMemSessionID;
                     Key, Reference: PAnsiChar;
                     KeyPath: TSQLMemKeyPath
                                               );
var
  Pos: Word;
begin
  Pos := GetKeyPosition(Key);
  InsertEntry(Key, Reference, Pos);
  if (not IsOverflow) then
   begin
//    FPage.IsDirty := True
    LTableData.UpdatePage(SessionID,FPage.Page,dbstIndex,
                          LTableData.TableState.TableState,False);

   end
  else
    Split(SessionID, KeyPath);
end;// InsertLeafEntry


//------------------------------------------------------------------------------
// DeleteLeafEntry
//------------------------------------------------------------------------------
function TSQLMemBTreeLeafController.DeleteLeafEntry(
                      SessionID: TSQLMemSessionID;
                      Key, Reference: PAnsiChar;
                      KeyPath: TSQLMemKeyPath
                                                ): Boolean;
var
  EntryNo: Integer;
begin
  if (FindEntryOnPage(Key, Reference, EntryNo)) then
   begin
      DeleteEntry(EntryNo);
      if (not CanUnderflow) then
       begin
//        FPage.IsDirty := True
        LTableData.UpdatePage(SessionID,FPage.Page,dbstIndex,
                              LTableData.TableState.TableState,False);
       end
      else
       if (not TryMerge(SessionID, KeyPath)) then
        begin
//        FPage.IsDirty := True;
          LTableData.UpdatePage(SessionID,FPage.Page,dbstIndex,
                                LTableData.TableState.TableState,False);
        end;
      Result := True;
   end
  else
   Result := False;
end;// DeleteLeafEntry


//------------------------------------------------------------------------------
// GetFirstKey
//------------------------------------------------------------------------------
procedure TSQLMemBTreeLeafController.GetFirstKey(SessionID: TSQLMemSessionID; Key: PAnsiChar);
begin
  Move(GetPKey(0)^, Key^, FPage.KeyPrefixSize);
end;// GetFirstKey


//------------------------------------------------------------------------------
// GetLastKey
//------------------------------------------------------------------------------
procedure TSQLMemBTreeLeafController.GetLastKey(SessionID: TSQLMemSessionID; Key: PAnsiChar);
begin
  Move(GetPKey(FPage.EntryCount-1)^, Key^, FPage.KeyPrefixSize);
end;// GetLastKey


//------------------------------------------------------------------------------
// FindEntry
//------------------------------------------------------------------------------
function TSQLMemBTreeLeafController.FindEntry(
                    SessionID: TSQLMemSessionID;
                    Key:       PAnsiChar;
                    Reference: PAnsiChar;
                    Position:  TSQLMemKeyPath
                   ): Boolean;
var
  EntryNo: Integer;
begin
  Result := FindEntryOnPage(Key, Reference, EntryNo);
  if (Result) then
   Position.AddItem(FPage.PageNo, EntryNo, FPage.EntryCount);
end;// FindEntry


//------------------------------------------------------------------------------
// GetFirstPosition
//------------------------------------------------------------------------------
function TSQLMemBTreeLeafController.GetFirstPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean;
begin
  Result := (FPage.EntryCount > 0);
  if (Result) then
    Position.AddItem(FPage.PageNo, 0, FPage.EntryCount);
end;// GetFirstPosition


//------------------------------------------------------------------------------
// GetLastPosition
//------------------------------------------------------------------------------
function TSQLMemBTreeLeafController.GetLastPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean;
begin
  Result := (FPage.EntryCount > 0);
  if (Result) then
   Position.AddItem(FPage.PageNo, FPage.EntryCount-1, FPage.EntryCount);
end;// GetLastPosition


//------------------------------------------------------------------------------
// FindByCondition
//------------------------------------------------------------------------------
function TSQLMemBTreeLeafController.FindByCondition(
                        SessionID: TSQLMemSessionID;
                        First:     Boolean; // if False => Last
                        Key:       PAnsiChar;
                        Operator:  TSQLMemSearchCondition;
                        Position:  TSQLMemKeyPath
                                                ): Boolean;
begin
  if (First) then
    Result := FindFirstByCondition(Key, Operator, Position)
  else
    Result := FindLastByCondition(Key, Operator, Position);
end;// FindByCondition


//------------------------------------------------------------------------------
// FreeAllPages
//------------------------------------------------------------------------------
procedure TSQLMemBTreeLeafController.FreeAllPages(SessionID: TSQLMemSessionID; RootPageNo: TSQLMemPageNo);
begin
 if (FPage.PageNo <> RootPageNo) then
  FPage.LBTreeIndex.RemoveIndexPage(SessionID, FPage.PageNo);
end;// FreeAllPages


//------------------------------------------------------------------------------
// CheckIntegrity
//------------------------------------------------------------------------------
procedure TSQLMemBTreeLeafController.CheckIntegrity(SessionID: TSQLMemSessionID; KeyPath: TSQLMemKeyPath);
var
  i: Integer;
begin
  for i := 0 to FPage.EntryCount-2 do
   begin
    if (CompareKeys(GetPKey(i), i+1) > 0) then
    if (CompareKeys(GetPKey(i), i+1) > 0) then
     raise ESQLMemException.Create(20028 ,ErrorAIndexIntegrityViolated, [FPage.PageNo, i]);
   end;
end;// CheckIntegrity



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBTreeNodeController
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// FindByConditionOnOneOfPages
//------------------------------------------------------------------------------
function TSQLMemBTreeNodeController.FindByConditionOnOneOfPages(
                                    SessionID:    TSQLMemSessionID;
                                    First:        Boolean; // if False => Last
                                    StartEntryNo: Integer;
                                    EndEntryNo:   Integer;
                                    Key:          PAnsiChar;
                                    Operator:     TSQLMemSearchCondition;
                                    Position:     TSQLMemKeyPath
                                                      ): Boolean;
var
  Pos, Step, MinPos, MaxPos: Integer;
  ChildPage:                 TSQLMemBTreePage;
begin
  Result := False;
  Pos := StartEntryNo;
  if (EndEntryNo >= StartEntryNo) then
   Step := 1
  else
   Step := -1;
  MinPos := Min(StartEntryNo, EndEntryNo);
  MaxPos := Max(StartEntryNo, EndEntryNo);
  while ((Pos >= MinPos) and (Pos <= MaxPos)) do
    begin
      ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PSQLMemPageNo(GetPReference(Pos))^);
      Position.AddItem(FPage.PageNo, Pos, FPage.EntryCount);
      Result := ChildPage.FindByCondition(SessionID, First, Key, Operator, Position);
      FPage.LBTreeIndex.PutIndexPage(ChildPage);
      if (Result) then
        break
      else
        Position.DeleteLastItem;
      Pos := Pos + Step;
    end;
end;// FindByConditionOnOneOfPages


//------------------------------------------------------------------------------
// FindEntryOnOneOfPages
//------------------------------------------------------------------------------
function TSQLMemBTreeNodeController.FindEntryOnOneOfPages(
                                    SessionID:    TSQLMemSessionID;
                                    StartEntryNo: Integer;
                                    EndEntryNo:   Integer;
                                    Key:          PAnsiChar;
                                    Reference:    PAnsiChar;
                                    Position:     TSQLMemKeyPath
                                  ): Boolean;
var
  Pos, Step, MinPos, MaxPos: Integer;
  ChildPage:                 TSQLMemBTreePage;
begin
//aaStartTime(time7);
  Result := False;
  Pos := StartEntryNo;
  if (EndEntryNo >= StartEntryNo) then
   Step := 1
  else
   Step := -1;
  MinPos := Min(StartEntryNo, EndEntryNo);
  MaxPos := Max(StartEntryNo, EndEntryNo);
//aaStartTime(time5);
  while ((Pos >= MinPos) and (Pos <= MaxPos)) do
    begin
      ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PSQLMemPageNo(GetPReference(Pos))^);
      Position.AddItem(FPage.PageNo, Pos, FPage.EntryCount);
//aaIncCounter(counter5);
//aaStartTime(time8);
      Result := ChildPage.FindEntry(SessionID, Key, Reference, Position);
//aaStopTime(time8);
//aaStartTime(time10);
      FPage.LBTreeIndex.PutIndexPage(ChildPage);
      if (Result) then
        break
      else
        Position.DeleteLastItem;
      Pos := Pos + Step;
//aaStopTime(time10);
    end;
//aaStopTime(time10);
//aaStopTime(time5);
//aaStopTime(time7);
end;// FindEntryOnOneOfPages


//------------------------------------------------------------------------------
// GetChildPagessToCheck
//------------------------------------------------------------------------------
procedure TSQLMemBTreeNodeController.GetChildPagesToCheck(
                          Key:               PAnsiChar;
                          SearchCondition:   TSQLMemSearchCondition;
                          var StartEntryNo:  Integer;
                          var EndEntryNo:    Integer
                                                      );
var
  PositionType: TSQLMemKeyPathPosition;
begin
  if (Key = nil) then
   begin
     StartEntryNo := 0;
     EndEntryNo := FPage.EntryCount-1;
   end
  else
    case SearchCondition of
      scEqual:
        begin
          StartEntryNo := GetKeyPosition(Key, 1, @PositionType, kstFirst);
          if (PositionType <> kppOnKey) then
           begin
             if (PositionType = kppBeforeKey) then
              Dec(StartEntryNo);
             EndEntryNo := StartEntryNo;
           end
          else
           begin
             Dec(StartEntryNo);
             if (StartEntryNo < 0) then
              StartEntryNo := 0;
             EndEntryNo := GetKeyPosition(Key, 1, @PositionType, kstLast);
           end;
        end;

      scLower:
        begin
          StartEntryNo := 0;
          EndEntryNo := GetKeyPosition(Key, 1, @PositionType, kstFirst);
          if ((PositionType = kppBeforeKey) or (PositionType = kppOnKey)) then
            Dec(EndEntryNo);
        end;

      scGreater:
        begin
          EndEntryNo := FPage.EntryCount-1;
          StartEntryNo := GetKeyPosition(Key, 1, @PositionType, kstLast);
          if (PositionType = kppBeforeKey) then
            Dec(StartEntryNo);
        end;

      scLowerEqual:
        begin
          StartEntryNo := 0;
          EndEntryNo := GetKeyPosition(Key, 1, @PositionType, kstLast);
          if (PositionType = kppBeforeKey) then
            Dec(EndEntryNo);
        end;

      scGreaterEqual:
        begin
          EndEntryNo := FPage.EntryCount-1;
          StartEntryNo := GetKeyPosition(Key, 1, @PositionType, kstFirst);
          if ((PositionType = kppBeforeKey) or (PositionType = kppOnKey)) then
            Dec(StartEntryNo);
        end;
    end;
end;// GetChildPagesToCheck


//------------------------------------------------------------------------------
// DecreaseTreeDepth
//------------------------------------------------------------------------------
procedure TSQLMemBTreeNodeController.DecreaseTreeDepth(SessionID: TSQLMemSessionID);
var
  ChildPage: TSQLMemBTreePage;
begin
  ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PSQLMemPageNo(GetPReference(0))^);
  FPage.CopyFrom(ChildPage, 0, ChildPage.EntryCount);
  FPage.IsRoot := True;
//  FPage.IsDirty := True;
  LTableData.UpdatePage(SessionID,FPage.Page,dbstIndex,
                        LTableData.TableState.TableState,False);
  ChildPage.LBTreeIndex.RemoveIndexPage(SessionID, ChildPage.PageNo);
  FPage.LBTreeIndex.PutIndexPage(ChildPage);
end;// DecreaseTreeDepth


//------------------------------------------------------------------------------
// InsertLeafEntry
//------------------------------------------------------------------------------
procedure TSQLMemBTreeNodeController.InsertLeafEntry(
                        SessionID: TSQLMemSessionID;
                        Key, Reference: PAnsiChar;
                        KeyPath: TSQLMemKeyPath
                                               );
var
  PositionType: TSQLMemKeyPathPosition;
  Pos:          Word;
  ChildPage:    TSQLMemBTreePage;
begin
  Pos := GetKeyPosition(Key, 1, @PositionType);
  if (PositionType = kppBeforeKey) then
   Dec(Pos);
  KeyPath.AddItem(FPage.PageNo, Pos, FPage.EntryCount);
  ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PSQLMemPageNo(GetPReference(Pos))^);
  try
   ChildPage.InsertLeafEntry(SessionID, Key, Reference, KeyPath);
  finally
   FPage.LBTreeIndex.PutIndexPage(ChildPage);
  end;
end;// InsertLeafEntry


//------------------------------------------------------------------------------
// InsertNodeEntry
//------------------------------------------------------------------------------
procedure TSQLMemBTreeNodeController.InsertNodeEntry(
                        SessionID: TSQLMemSessionID;
                        Key, Reference: PAnsiChar;
                        KeyPath: TSQLMemKeyPath
                                               );
var
  Pos: Word;
begin
  if (FPage.EntryCount < 2) then
    Pos := FPage.EntryCount
  else
    Pos := KeyPath.Items[KeyPath.ItemNo].EntryNo+1;

  InsertEntry(Key, Reference, Pos);
  if (not IsOverflow) then
   begin
//   FPage.IsDirty := True
    LTableData.UpdatePage(SessionID,FPage.Page,dbstIndex,
                          LTableData.TableState.TableState,False);
   end
  else
   Split(SessionID, KeyPath);
end;// InsertNodeEntry


//------------------------------------------------------------------------------
// DeleteLeafEntry
//------------------------------------------------------------------------------
function TSQLMemBTreeNodeController.DeleteLeafEntry(
                        SessionID: TSQLMemSessionID;
                        Key, Reference: PAnsiChar;
                        KeyPath: TSQLMemKeyPath
                                                 ): Boolean;
var
  StartPosition, EndPosition, Pos: Integer;
  ChildPage: TSQLMemBTreePage;
begin
  Result := False;
  GetChildPagesToCheck(Key, scEqual, StartPosition, EndPosition);
  for Pos := StartPosition to EndPosition do
    begin
      ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PSQLMemPageNo(GetPReference(Pos))^);
      try
       KeyPath.AddItem(FPage.PageNo, Pos, FPage.EntryCount);
       Result := ChildPage.DeleteLeafEntry(SessionID, Key, Reference, KeyPath);
      finally
       FPage.LBTreeIndex.PutIndexPage(ChildPage);
      end;
      if (Result) then
        break
      else
        KeyPath.DeleteLastItem;
    end;
end;// DeleteLeafEntry


//------------------------------------------------------------------------------
// DeleteNodeEntry
//------------------------------------------------------------------------------
procedure TSQLMemBTreeNodeController.DeleteNodeEntry(
                        SessionID:     TSQLMemSessionID;
                        KeyPath:       TSQLMemKeyPath;
                        MergeWithLeft: Boolean
                                                );
var
  ParentPage: TSQLMemBTreePage;
  EntryNo:    Integer;
  CurLevel:   Integer;
begin
  if (MergeWithLeft) then
   begin
     CurLevel := KeyPath.ItemNo;
     while ((KeyPath.Items[CurLevel].EntryNo = 0) and
         (CurLevel > 0)) do
      begin
        Dec(CurLevel);
        if (KeyPath.Items[CurLevel].EntryNo > 0) then
         begin
          ParentPage := FPage.LBTreeIndex.GetIndexPage(SessionID, KeyPath.Items[CurLevel].PageNo);
          ParentPage.UpdateKey(
                          KeyPath.Items[CurLevel].EntryNo,
                          GetPKey(1));
//          ParentPage.IsDirty := True;
          LTableData.UpdatePage(SessionID,ParentPage.Page,dbstIndex,
                                LTableData.TableState.TableState,False);
          FPage.LBTreeIndex.PutIndexPage(ParentPage);
          break;
         end;
      end;
   end
  else
   begin
     CurLevel := KeyPath.ItemNo;
     while (CurLevel >= 0) do
       begin
        if (KeyPath.Items[CurLevel].EntryNo = KeyPath.Items[CurLevel].EntryCount-1) then
          Dec(CurLevel);
        if (CurLevel >= 0) then
          if (KeyPath.Items[CurLevel].EntryNo <
              KeyPath.Items[CurLevel].EntryCount-1) then
            begin
              EntryNo := KeyPath.Items[CurLevel].EntryNo+1;
              ParentPage := FPage.LBTreeIndex.GetIndexPage(SessionID, KeyPath.Items[CurLevel].PageNo);
              ParentPage.UpdateKey(
                                   EntryNo,
                                   GetPKey(KeyPath.Items[KeyPath.ItemNo].EntryNo));
//              ParentPage.IsDirty := True;
              LTableData.UpdatePage(SessionID,ParentPage.Page,dbstIndex,
                                    LTableData.TableState.TableState,False);
              FPage.LBTreeIndex.PutIndexPage(ParentPage);
              break;
            end;
       end;
   end;
  DeleteEntry(KeyPath.Items[KeyPath.ItemNo].EntryNo);
  if (not CanUnderflow) then
    begin
//    FPage.IsDirty := True
      LTableData.UpdatePage(SessionID,FPage.Page,dbstIndex,
                            LTableData.TableState.TableState,False);
    end
   else
     if (not TryMerge(SessionID, KeyPath)) then
      begin
        if (not FPage.IsRoot) then
         begin
//          FPage.IsDirty := True
          LTableData.UpdatePage(SessionID,FPage.Page,dbstIndex,
                                LTableData.TableState.TableState,False);
         end
        else
         if (FPage.EntryCount = 1) then
           DecreaseTreeDepth(SessionID);
      end;
end;// DeleteNodeEntry


//------------------------------------------------------------------------------
// GetFirstKey
//------------------------------------------------------------------------------
procedure TSQLMemBTreeNodeController.GetFirstKey(SessionID: TSQLMemSessionID; Key: PAnsiChar);
var
  ChildPage: TSQLMemBTreePage;
begin
  ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PSQLMemPageNo(GetPReference(0))^);
  ChildPage.GetFirstKey(SessionID, Key);
  FPage.LBTreeIndex.PutIndexPage(ChildPage);
end;// GetFirstKey


//------------------------------------------------------------------------------
// GetLastKey
//------------------------------------------------------------------------------
procedure TSQLMemBTreeNodeController.GetLastKey(SessionID: TSQLMemSessionID; Key: PAnsiChar);
var
  ChildPage: TSQLMemBTreePage;
begin
  ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PSQLMemPageNo(GetPReference(FPage.EntryCount-1))^);
  ChildPage.GetLastKey(SessionID, Key);
  FPage.LBTreeIndex.PutIndexPage(ChildPage);
end;// GetLastKey


//------------------------------------------------------------------------------
// FindEntry
//------------------------------------------------------------------------------
function TSQLMemBTreeNodeController.FindEntry(
                          SessionID: TSQLMemSessionID;
                          Key:       PAnsiChar;
                          Reference: PAnsiChar;
                          Position:  TSQLMemKeyPath
                         ): Boolean;
var
  StartEntryNo, EndEntryNo: Integer;
begin
//aaIncCounter(counter2);
  GetChildPagesToCheck(Key, scEqual, StartEntryNo, EndEntryNo);
  Result := FindEntryOnOneOfPages(
                SessionID,
                StartEntryNo,
                EndEntryNo,
                Key,
                Reference,
                Position
                                      );
end;// FindEntry


//------------------------------------------------------------------------------
// GetFirstPosition
//------------------------------------------------------------------------------
function TSQLMemBTreeNodeController.GetFirstPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean;
var
  ChildPage: TSQLMemBTreePage;
begin
  ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PSQLMemPageNo(GetPReference(0))^);
  try
   Position.AddItem(FPage.PageNo, 0, FPage.EntryCount);
   Result := ChildPage.GetFirstPosition(SessionID, Position);
  finally
   FPage.LBTreeIndex.PutIndexPage(ChildPage);
  end;
end;// GetFirstPosition


//------------------------------------------------------------------------------
// GetLastPosition
//------------------------------------------------------------------------------
function TSQLMemBTreeNodeController.GetLastPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean;
var
  ChildPage: TSQLMemBTreePage;
begin
  ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PSQLMemPageNo(GetPReference(FPage.EntryCount-1))^);
  try
   Position.AddItem(FPage.PageNo, FPage.EntryCount-1, FPage.EntryCount);
   Result := ChildPage.GetLastPosition(SessionID, Position);
  finally
   FPage.LBTreeIndex.PutIndexPage(ChildPage);
  end;
end;// GetLastPosition


//------------------------------------------------------------------------------
// FindByCondition
//------------------------------------------------------------------------------
function TSQLMemBTreeNodeController.FindByCondition(
                              SessionID: TSQLMemSessionID;
                              First:     Boolean; // if False => Last
                              Key:       PAnsiChar;
                              Operator:  TSQLMemSearchCondition;
                              Position:  TSQLMemKeyPath
                             ): Boolean;
var
  StartEntryNo, EndEntryNo: Integer;
begin
  GetChildPagesToCheck(Key, Operator, StartEntryNo, EndEntryNo);
  if (First) then
    Result := FindByConditionOnOneOfPages(SessionID, First, StartEntryNo, EndEntryNo, Key, Operator, Position)
  else
    Result := FindByConditionOnOneOfPages(SessionID, First, EndEntryNo, StartEntryNo, Key, Operator, Position);
end;// FindByCondition


//------------------------------------------------------------------------------
// FreeAllPages
//------------------------------------------------------------------------------
procedure TSQLMemBTreeNodeController.FreeAllPages(SessionID: TSQLMemSessionID; RootPageNo: TSQLMemPageNo = INVALID_PAGE_NO);
var  i:           Integer;
     ChildPage:   TSQLMemBTreePage;
begin
  if (FPage.PageNo <> INVALID_PAGE_NO) then
   begin
     for i := 0 to FPage.EntryCount-1 do
       begin
         ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PSQLMemPageNo(GetPReference(i))^);
         try
           ChildPage.FreeAllPages(SessionID);
         finally
           FPage.LBTreeIndex.PutIndexPage(ChildPage);
         end;
       end;
     if (FPage.PageNo <> RootPageNo) then
      FPage.LBTreeIndex.RemoveIndexPage(SessionID, FPage.PageNo);
   end;
end;// FreeAllPages


//------------------------------------------------------------------------------
// CheckIntegrity
//------------------------------------------------------------------------------
procedure TSQLMemBTreeNodeController.CheckIntegrity(SessionID: TSQLMemSessionID; KeyPath: TSQLMemKeyPath);
var
  i:         Integer;
  ChildPage: TSQLMemBTreePage;
  KeyBuffer: PAnsiChar;
begin
  KeyBuffer := KeyRef.AllocKeyBuffer;
  try
    for i := 0 to FPage.EntryCount-1 do
     begin
       if (KeyPath.PageExists(FPage.PageNo)) then
        raise ESQLMemException.Create(20032 ,ErrorAIndexIntegrityCircularLinks, [FPage.PageNo, i]);

       KeyPath.AddItem(FPage.PageNo, i, FPage.EntryCount);
       ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PSQLMemPageNo(GetPReference(i))^);
       if (i > 0) then
        if (ChildPage.LeftPageNo <> PSQLMemPageNo(GetPReference(i-1))^) then
         raise ESQLMemException.Create(20033, ErrorAIndexIntegrityLeafLinks, [FPage.PageNo, i]);
       if (i < FPage.EntryCount-1) then
        if (ChildPage.RightPageNo <> PSQLMemPageNo(GetPReference(i+1))^) then
         raise ESQLMemException.Create(20034, ErrorAIndexIntegrityLeafLinks, [FPage.PageNo, i]);

       ChildPage.CheckIntegrity(SessionID, KeyPath);
       FPage.LBTreeIndex.PutIndexPage(ChildPage);
       KeyPath.DeleteLastItem;
     end;
    for i := 1 to FPage.EntryCount-2 do
     begin
       if (CompareKeys(GetPKey(i), i+1) > 0) then
        raise ESQLMemException.Create(20029 ,ErrorAIndexIntegrityViolated, [FPage.PageNo, i]);
       ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PSQLMemPageNo(GetPReference(i-1))^);
       ChildPage.GetLastKey(SessionID, KeyBuffer);
       if (CompareKeys(KeyBuffer, i) > 0) then
        raise ESQLMemException.Create(20030 ,ErrorAIndexIntegrityViolated, [FPage.PageNo, i]);
       FPage.LBTreeIndex.PutIndexPage(ChildPage);
       ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PSQLMemPageNo(GetPReference(i+1))^);
       ChildPage.GetFirstKey(SessionID, KeyBuffer);
       if (CompareKeys(KeyBuffer, i+1) < 0) then
        raise ESQLMemException.Create(20031 ,ErrorAIndexIntegrityViolated, [FPage.PageNo, i]);
       FPage.LBTreeIndex.PutIndexPage(ChildPage);
     end;
  finally
    KeyRef.FreeAndNilKeyBuffer(KeyBuffer);
  end;
end;// CheckIntegrity


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBTreeIndex
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TSQLMemBTreeIndex.Lock(WriteMode: Boolean);
begin
 //
end;// Lock


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TSQLMemBTreeIndex.Unlock;
begin
 //{$I SQLMemThreadSync_4.inc}
end;// Unlock


//------------------------------------------------------------------------------
// AddIndexPage
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.AddIndexPage(SessionID: TSQLMemSessionID): TSQLMemBTreePage;
var
  Page: TSQLMemPage;
begin
  Page := LTableData.AddPage(SessionID,dbstIndex,LTableData.TableState.TableState,False);
  Result := TSQLMemBTreePage.Create(Self, Page);
end;// AddIndexPage


//------------------------------------------------------------------------------
// RemoveIndexPage
//------------------------------------------------------------------------------
procedure TSQLMemBTreeIndex.RemoveIndexPage(SessionID: TSQLMemSessionID; PageNo: TSQLMemPageNo);
begin
  LTableData.RemovePage(SessionID,PageNo,dbstIndex,LTableData.TableState.TableState);
end;// RemoveIndexPage


//------------------------------------------------------------------------------
// GetIndexPage
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.GetIndexPage(SessionID: TSQLMemSessionID; PageNo: TSQLMemPageNo): TSQLMemBTreePage;
var
  Page: TSQLMemPage;
begin
  Page := LTableData.GetPage(SessionID,PageNo,dbstIndex,LTableData.TableState.TableState,
      True,False,False);
  Result := TSQLMemBTreePage.Create(Self, Page);
end;// GetIndexPage


//------------------------------------------------------------------------------
// PutIndexPage
//------------------------------------------------------------------------------
procedure TSQLMemBTreeIndex.PutIndexPage(Page: TSQLMemBTreePage);
begin
  LTableData.PutPage(Page.Page);
  Page.Free;
end;// PutIndexPage


//------------------------------------------------------------------------------
// GetRecordID
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.GetRecordID(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): TSQLMemRecordID;
var
  Page: TSQLMemBTreePage;
begin
  if (Position.Count = 0) then
   raise ESQLMemException.Create(20068, ErrorABTreeInvalidPosition);
  Page := GetIndexPage(SessionID, Position.Items[Position.Count-1].PageNo);
  try
    Move(
      Page.GetPReference(Position.Items[Position.Count-1].EntryNo)^,
      Result,
      Page.ReferenceSize
        );
  finally
    PutIndexPage(Page);
  end;
end;// GetRecordID


//------------------------------------------------------------------------------
// GetFirstPosition
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.GetFirstPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean;
var
  Page: TSQLMemBTreePage;
begin
  if (IndexDef.RootPageNo <> INVALID_PAGE_NO) then
    begin
      Position.Clear;
      Page := GetIndexPage(SessionID, IndexDef.RootPageNo);
      try
        Result := Page.GetFirstPosition(SessionID, Position);
      finally
        PutIndexPage(Page);
      end;
    end
  else
    Result := False;
end;// GetFirstPosition


//------------------------------------------------------------------------------
// GetLastPosition
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.GetLastPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean;
var
  Page: TSQLMemBTreePage;
begin
  if (IndexDef.RootPageNo <> INVALID_PAGE_NO) then
    begin
      Position.Clear;
      Page := GetIndexPage(SessionID, IndexDef.RootPageNo);
      try
        Result := Page.GetLastPosition(SessionID, Position);
      finally
        PutIndexPage(Page);
      end;
    end
  else
    Result := False;
end;// GetLastPosition


//------------------------------------------------------------------------------
// GetNextPosition
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.GetNextPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean;
var
  i:            Integer;
  CurrentLevel: Integer;
  Page:         TSQLMemBTreePage;
  NextPageNo:   TSQLMemPageNo;
begin
  if (Position.Count = 0) then
   raise ESQLMemException.Create(20069, ErrorABTreeInvalidPosition);
  CurrentLevel := Position.Count-1;
  Result := False;

  repeat
    if (Position.Items[CurrentLevel].EntryNo <
        Position.Items[CurrentLevel].EntryCount-1) then
     begin
      Inc(Position.Items[CurrentLevel].EntryNo);
      Result := True;
      break;
     end
    else
     Dec(CurrentLevel);
  until (CurrentLevel < 0);

  if (Result) then
    for i := CurrentLevel+1 to Position.Count-1 do
      begin
        Page := GetIndexPage(SessionID, Position.Items[i].PageNo);
        NextPageNo := Page.RightPageNo;
        PutIndexPage(Page);
        if (NextPageNo = INVALID_PAGE_NO) then
          raise ESQLMemException.Create(20070, ErrorABTreeInvalidPage);
        Page := GetIndexPage(SessionID, NextPageNo);
        try
          Position.Items[i].PageNo := NextPageNo;
          Position.Items[i].EntryNo := 0;
          Position.Items[i].EntryCount := Page.EntryCount;
        finally
          PutIndexPage(Page);
        end;
      end;
end;// GetNextPosition


//------------------------------------------------------------------------------
// GetPriorPosition
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.GetPriorPosition(SessionID: TSQLMemSessionID; Position: TSQLMemKeyPath): Boolean;
var
  i:            Integer;
  CurrentLevel: Integer;
  Page:         TSQLMemBTreePage;
  PriorPageNo:   TSQLMemPageNo;
begin
  if (Position.Count = 0) then
   raise ESQLMemException.Create(20069, ErrorABTreeInvalidPosition);
  CurrentLevel := Position.Count-1;
  Result := False;

  repeat
    if (Position.Items[CurrentLevel].EntryNo > 0) then
     begin
      Dec(Position.Items[CurrentLevel].EntryNo);
      Result := True;
      break;
     end
    else
     Dec(CurrentLevel);
  until (CurrentLevel < 0);

  if (Result) then
    for i := CurrentLevel+1 to Position.Count-1 do
      begin
        Page := GetIndexPage(SessionID, Position.Items[i].PageNo);
        PriorPageNo := Page.LeftPageNo;
        PutIndexPage(Page);
        if (PriorPageNo = INVALID_PAGE_NO) then
          raise ESQLMemException.Create(20071, ErrorABTreeInvalidPage);
        Page := GetIndexPage(SessionID, PriorPageNo);
        try
          Position.Items[i].PageNo := PriorPageNo;
          Position.Items[i].EntryNo := Page.EntryCount-1;
          Position.Items[i].EntryCount := Page.EntryCount;
        finally
          PutIndexPage(Page);
        end;
      end;
end;// GetPriorPosition


//------------------------------------------------------------------------------
// GetPosition
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.GetPosition(SessionID: TSQLMemSessionID; Restart, GoForward: Boolean; Position: TSQLMemKeyPath): Boolean;
begin
  if (Restart) then
    if (GoForward) then
      Result := GetFirstPosition(SessionID, Position)
    else
      Result := GetLastPosition(SessionID, Position)
  else
    if (GoForward) then
      Result := GetNextPosition(SessionID, Position)
    else
      Result := GetPriorPosition(SessionID, Position);
end;// GetPosition


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemBTreeIndex.Create(aIndexManager: TSQLMemBaseIndexManager);
begin
  inherited Create(aIndexManager);
  FRootPage := nil;
  FKeyRef := nil;
  FThreadSync := TSQLMemReadWriteThreadSyncBySingleCriticalSection.Create;
{$IFDEF INDEX_NAVIGATION_OPTIMIZATION}
  FKeyPathCache := TSQLMemKeyPathCache.Create;
{$ENDIF}
end;// Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemBTreeIndex.Destroy;
begin
  if (FKeyRef <> nil) then
   begin
     FKeyRef.Free;
     FKeyRef := nil;
   end;
  if (FThreadSync <> nil) then
   begin
    FThreadSync.Free;
    FThreadSync := nil;
   end;
{$IFDEF INDEX_NAVIGATION_OPTIMIZATION}
  FKeyPathCache.Free;
{$ENDIF}
  inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// clear index cache (INVALID_OBJECT_ID means all sessions)
//------------------------------------------------------------------------------
procedure TSQLMemBTreeIndex.ClearIndexCache(SessionID: TSQLMemSessionID = INVALID_OBJECT_ID);
begin
{$IFDEF INDEX_NAVIGATION_OPTIMIZATION}
  FKeyPathCache.Clear(SessionID);
{$ENDIF}
end; // ClearIndexCache


//------------------------------------------------------------------------------
// create index
//------------------------------------------------------------------------------
procedure TSQLMemBTreeIndex.CreateIndex(Cursor: TSQLMemCursor; aIndexDef: TSQLMemIndexDef);
var
  RecordBuffer:   TSQLMemRecordBuffer;
  TmpCursor:         TSQLMemLocalCursor;
begin
  inherited CreateIndex(Cursor, aIndexDef);

  FKeyRef := TSQLMemBTreeKeyRef.Create;
  FKeyRef.Assign(IndexDef, IndexManager.TableData);
  FKeyRef.ReferenceSize := sizeof(TSQLMemRecordID);

  FRootPage := AddIndexPage(Cursor.Session.SessionID);
  try
    FRootPage.InitAsRoot;
    aIndexDef.RootPageNo := FRootPage.PageNo;
    IndexDef.RootPageNo := aIndexDef.RootPageNo;
  finally
    PutIndexPage(FRootPage);
  end;
  TmpCursor := TSQLMemLocalCursor.Create;
  TmpCursor.Session := Cursor.Session;
  TmpCursor.InMemory := Cursor.InMemory;
  TmpCursor.FTableName := Cursor.FTableName;
  try
   TSQLMemLocalCursor(TmpCursor).OpenTable(IndexManager.TableData);
   TmpCursor.CurrentRecordBuffer := TmpCursor.AllocateRecordBuffer;
   while (TmpCursor.GetRecordBuffer(grmNext) = grrOK) do
     InsertRecord(TmpCursor);
  finally
   RecordBuffer := TmpCursor.CurrentRecordBuffer;
   TmpCursor.FreeRecordBuffer(RecordBuffer);
   TmpCursor.CurrentRecordBuffer := nil;
   TmpCursor.Free;
  end;
end;// CreateIndex


//------------------------------------------------------------------------------
// create index from specified page
//------------------------------------------------------------------------------
procedure TSQLMemBTreeIndex.CreateIndex(SessionID: TSQLMemSessionID; pageNo: TSQLMemPageNo; aIndexDef: TSQLMemIndexDef);
begin
  inherited CreateIndex(SessionID, pageNo, aIndexDef);
  FRootPage := GetIndexPage(SessionID,pageNo);
  try
    FRootPage.InitAsRoot;
    aIndexDef.RootPageNo := FRootPage.PageNo;
    IndexDef.RootPageNo := aIndexDef.RootPageNo;
  finally
    PutIndexPage(FRootPage);
  end;
end; // CreateIndex


//------------------------------------------------------------------------------
// DropIndex
//------------------------------------------------------------------------------
procedure TSQLMemBTreeIndex.DropIndex(SessionID: TSQLMemSessionID; EmptyIndex: Boolean);
begin
  if (IndexDef.RootPageNo <> INVALID_PAGE_NO) then
   begin
    FRootPage := GetIndexPage(SessionID, IndexDef.RootPageNo);
    try
     if (EmptyIndex) then
      begin
       FRootPage.FreeAllPages(SessionID,IndexDef.RootPageNo);
       LTableData.UpdatePage(SessionID,FRootPage.Page,dbstIndex,LTableData.TableState.TableState,False);
       FRootPage.InitAsRoot;
      end
     else
      FRootPage.FreeAllPages(SessionID,INVALID_PAGE_NO);
    finally
     PutIndexPage(FRootPage);
    end; 
   end;
end;// DropIndex


//------------------------------------------------------------------------------
// open index
//------------------------------------------------------------------------------
procedure TSQLMemBTreeIndex.OpenIndex(aIndexDef: TSQLMemIndexDef);
begin
  inherited OpenIndex(aIndexDef);

  FKeyRef := TSQLMemBTreeKeyRef.Create;
  FKeyRef.Assign(IndexDef, IndexManager.TableData);
  FKeyRef.ReferenceSize := sizeof(TSQLMemRecordID);
end;// OpenIndex


//------------------------------------------------------------------------------
// GetRecordBuffer
//------------------------------------------------------------------------------
procedure TSQLMemBTreeIndex.GetRecordBuffer(
                               SessionID:          TSQLMemSessionID;
                               var NavigationInfo: TSQLMemNavigationInfo
                                         );
var
  KeyPath:            TSQLMemKeyPath;
  Res1:               Boolean;
  Res2:               Boolean;
  GetRecordMode:      TSQLMemGetRecordMode;
{$IFDEF DEBUG_INDEXES_GET_RECORD}
  i:                  Integer;
{$ENDIF}
begin
  if (NavigationInfo.GetRecordMode = grmCurrent) then
   raise ESQLMemException.Create(20053, ErrorAInvalidIndexGetRecordMode);
{$IFDEF DEBUG_INDEXES_GET_RECORD}
aaWriteToLog(#13#10);
aaWriteToLog('> TSQLMemBTreeIndex.GetRecordBuffer. SessionID = '+IntToStr(SessionID));
if (NavigationInfo.GetRecordMode = grmCurrent) then  aaWriteToLog('Mode = Current');
if (NavigationInfo.GetRecordMode = grmNext) then  aaWriteToLog('Mode = Next');
if (NavigationInfo.GetRecordMode = grmPrior) then  aaWriteToLog('Mode = Prior');
if (NavigationInfo.FirstPosition) then  aaWriteToLog('First Position');
if (NavigationInfo.LastPosition) then  aaWriteToLog('Last Position');
aaWriteToLog('RecordID.PageNo = '+IntToStr(NavigationInfo.RecordID.PageNo));
aaWriteToLog('RecordID.PageItemNo = '+IntToStr(NavigationInfo.RecordID.PageItemNo));
{$ENDIF}
  if (IndexDef.RootPageNo = INVALID_PAGE_NO) then
   begin
    NavigationInfo.GetRecordResult := grrEOF;
{$IFDEF DEBUG_INDEXES_GET_RECORD}
aaWriteToLog('No root page - EOF');
{$ENDIF}
   end
  else
    begin
{$IFDEF INDEX_NAVIGATION_OPTIMIZATION}
      KeyPath := FKeyPathCache.GetKeyPath(SessionID,NavigationInfo.RecordID,(NavigationInfo.FirstPosition or NavigationInfo.LastPosition));
      try
{$IFDEF DEBUG_INDEXES_GET_RECORD}
aaWriteToLog('First KeyPath');
aaWriteToLog('KeyPath.Count = '+IntToStr(KeyPath.Count));
for i := 0 to KeyPath.Count-1 do
 begin
aaWriteToLog(#13#10);
aaWriteToLog('KeyPath ItemNo = '+IntToStr(i));
aaWriteToLog('KeyPath PageNo = '+IntToStr(KeyPath.Items[i].PageNo));
aaWriteToLog('KeyPath EntryNo = '+IntToStr(KeyPath.Items[i].EntryNo));
aaWriteToLog('KeyPath EntryCount = '+IntToStr(KeyPath.Items[i].EntryCount));
 end;
aaWriteToLog(#13#10);
{$ENDIF}
        Res2 := True;
        if (NavigationInfo.FirstPosition) then
         begin
          Res1 := GetFirstPosition(SessionID, KeyPath);
         end
        else
         if (NavigationInfo.LastPosition) then
          begin
           Res1 := GetLastPosition(SessionID, KeyPath);
          end
         else
          begin
           if (KeyPath.Count <= 0) then
            begin
             Res1 := GetIndexPosition(
                                  SessionID,
                                  NavigationInfo.RecordID,
                                  NavigationInfo.RecordBuffer,
                                  KeyPath
                                 );
            end
           else
            Res1 := True;
{$ELSE}
      KeyPath := TSQLMemKeyPath.Create;
      try
{$IFDEF DEBUG_INDEXES_GET_RECORD}
aaWriteToLog('First KeyPath');
aaWriteToLog('KeyPath.Count = '+IntToStr(KeyPath.Count));
for i := 0 to KeyPath.Count-1 do
 begin
aaWriteToLog(#13#10);
aaWriteToLog('KeyPath ItemNo = '+IntToStr(i));
aaWriteToLog('KeyPath PageNo = '+IntToStr(KeyPath.Items[i].PageNo));
aaWriteToLog('KeyPath EntryNo = '+IntToStr(KeyPath.Items[i].EntryNo));
aaWriteToLog('KeyPath EntryCount = '+IntToStr(KeyPath.Items[i].EntryCount));
 end;
aaWriteToLog(#13#10);
{$ENDIF}
        Res2 := True;
        if (NavigationInfo.FirstPosition) then
         begin
          Res1 := GetFirstPosition(SessionID, KeyPath);
         end
        else
         if (NavigationInfo.LastPosition) then
          begin
           Res1 := GetLastPosition(SessionID, KeyPath);
          end
         else
          begin
           Res1 := GetIndexPosition(
                                  SessionID,
                                  NavigationInfo.RecordID,
                                  NavigationInfo.RecordBuffer,
                                  KeyPath
                                 );
{$ENDIF}
{$IFDEF DEBUG_INDEXES_GET_RECORD}
aaWriteToLog('Res1 = '+BoolToStr(Res1,True));
aaWriteToLog('KeyPath.Count = '+IntToStr(KeyPath.Count));
for i := 0 to KeyPath.Count-1 do
 begin
aaWriteToLog(#13#10);
aaWriteToLog('KeyPath ItemNo = '+IntToStr(i));
aaWriteToLog('KeyPath PageNo = '+IntToStr(KeyPath.Items[i].PageNo));
aaWriteToLog('KeyPath EntryNo = '+IntToStr(KeyPath.Items[i].EntryNo));
aaWriteToLog('KeyPath EntryCount = '+IntToStr(KeyPath.Items[i].EntryCount));
 end;
aaWriteToLog(#13#10);
{$ENDIF}
           if (Res1) then
            if (NavigationInfo.GetRecordMode = grmNext) then
             begin
              Res2 := GetNextPosition(SessionID, KeyPath);
             end
            else
            if (NavigationInfo.GetRecordMode = grmPrior) then
             begin
              Res2 := GetPriorPosition(SessionID, KeyPath);
             end
            else
              Res2 := True;
          end;

        if (not Res1) then
         NavigationInfo.GetRecordResult := grrError
        else
          if (not Res2) then
           if (NavigationInfo.GetRecordMode = grmNext) then
            begin
              NavigationInfo.GetRecordResult := grrEOF;
              NavigationInfo.FirstPosition := False;
              NavigationInfo.LastPosition := True;
            end
           else
            begin
              NavigationInfo.GetRecordResult := grrBOF;
              NavigationInfo.FirstPosition := True;
              NavigationInfo.LastPosition := False;
            end
          else
           begin
             NavigationInfo.GetRecordResult := grrOK;
             NavigationInfo.FirstPosition := False;
             NavigationInfo.LastPosition := False;
             NavigationInfo.RecordID := GetRecordID(SessionID, KeyPath);
             GetRecordMode := NavigationInfo.GetRecordMode;
             NavigationInfo.GetRecordMode := grmCurrent;
             IndexManager.TableData.
                 RecordManager.GetRecordBuffer(NavigationInfo);
             NavigationInfo.GetRecordMode := GetRecordMode;
{$IFDEF INDEX_NAVIGATION_OPTIMIZATION}
            FKeyPathCache.SetKeyPath(SessionID,NavigationInfo.RecordID, KeyPath);
{$IFDEF DEBUG_INDEXES_GET_RECORD}
aaWriteToLog('Saved KeyPath');
aaWriteToLog('KeyPath.Count = '+IntToStr(KeyPath.Count));
for i := 0 to KeyPath.Count-1 do
 begin
aaWriteToLog(#13#10);
aaWriteToLog('KeyPath ItemNo = '+IntToStr(i));
aaWriteToLog('KeyPath PageNo = '+IntToStr(KeyPath.Items[i].PageNo));
aaWriteToLog('KeyPath EntryNo = '+IntToStr(KeyPath.Items[i].EntryNo));
aaWriteToLog('KeyPath EntryCount = '+IntToStr(KeyPath.Items[i].EntryCount));
 end;
aaWriteToLog(#13#10);
{$ENDIF}

{$ENDIF}
           end;
      finally
{IFNDEF INDEX_NAVIGATION_OPTIMIZATION}
        KeyPath.Free;
{ENDIF}
      end;
    end;
{$IFDEF DEBUG_INDEXES_GET_RECORD}
aaWriteToLog('< TSQLMemBTreeIndex.GetRecordBuffer. SessionID = '+IntToStr(SessionID));
if (NavigationInfo.GetRecordResult = grrEOF) then  aaWriteToLog('Result = EOF');
if (NavigationInfo.GetRecordResult = grrBOF) then  aaWriteToLog('Result = BOF');
if (NavigationInfo.GetRecordResult = grrOK) then  aaWriteToLog('Result = OK');
if (NavigationInfo.GetRecordResult = grrError) then  aaWriteToLog('Result = Error');
if (NavigationInfo.FirstPosition) then  aaWriteToLog('First Position');
if (NavigationInfo.LastPosition) then  aaWriteToLog('Last Position');
aaWriteToLog('Result RecordID.PageNo = '+IntToStr(NavigationInfo.RecordID.PageNo));
aaWriteToLog('Result RecordID.PageItemNo = '+IntToStr(NavigationInfo.RecordID.PageItemNo));
aaWriteToLog(#13#10);
{$ENDIF}
end;// GetRecordBuffer


//------------------------------------------------------------------------------
// CreateIndexPosition
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.CreateIndexPosition: TSQLMemIndexPosition;
begin
  Result := TSQLMemKeyPath.Create;
end;// CreateIndexPosition


//------------------------------------------------------------------------------
// FreeIndexPosition
//------------------------------------------------------------------------------
procedure TSQLMemBTreeIndex.FreeIndexPosition(var IndexPosition: TSQLMemIndexPosition);
begin
  if (IndexPosition <> nil) then
   TSQLMemKeyPath(IndexPosition).Free;
  IndexPosition := nil;
end;// FreeIndexPosition


//------------------------------------------------------------------------------
// GetIndexPosition
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.GetIndexPosition(
                                         SessionID:     TSQLMemSessionID;
                                         RecordID:      TSQLMemRecordID;
                                         RecordBuffer:  TSQLMemRecordBuffer;
                                         IndexPosition: TSQLMemIndexPosition
                                        ): Boolean;
var
  Page:       TSQLMemBTreePage;
  KeyBuffer:  PAnsiChar;
begin
//aaStartTime(time2);
  if (IndexDef.RootPageNo <> INVALID_PAGE_NO) then
    begin
      TSQLMemKeyPath(IndexPosition).Clear;
      Page := GetIndexPage(SessionID, IndexDef.RootPageNo);
      KeyBuffer := FKeyRef.AllocKeyBuffer;
      try
        FKeyRef.MakeKeyFromRecordBuffer(RecordBuffer, KeyBuffer);
//aaStartTime(time4);
//aaIncCounter;
        Result := Page.FindEntry(SessionID, KeyBuffer, @RecordID, TSQLMemKeyPath(IndexPosition));
//aaStopTime(time4);
      finally
        FKeyRef.FreeAndNilKeyBuffer(KeyBuffer);
        PutIndexPage(Page);
      end;
    end
  else
    Result := False;
//aaStopTime(time2);
end;// GetIndexPosition


//------------------------------------------------------------------------------
// return 0, 1, -1 if (Pos1 = Pos2), (Pos1 > Pos2), (Pos1 < Pos2)
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.CompareRecordPositionsInIndex(
                    RecordPosition1: TSQLMemIndexPosition;
                    RecordPosition2: TSQLMemIndexPosition
                                      ): Integer;
begin
 if (RecordPosition1 = nil) then
  raise ESQLMemException.Create(10384,ErrorLNilPointer);
 if (RecordPosition2 = nil) then
  raise ESQLMemException.Create(10385,ErrorLNilPointer);
 Result := TSQLMemKeyPath(RecordPosition1).Compare(TSQLMemKeyPath(RecordPosition2));
end; // CompareRecordPositionsInIndex


//------------------------------------------------------------------------------
// GetRecNoByRecordID
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.GetRecNoByRecordID(
                                SessionID:      TSQLMemSessionID;
                                RecordID:       TSQLMemRecordID;
                                RecordBuffer:   TSQLMemRecordBuffer;
                                Bitmap:         TSQLMemRecordBitmap
                               ): TSQLMemRecordNo;
var
  Position:       TSQLMemKeyPath;
  ScanPage:       TSQLMemBTreePage;
  ScanPageNo:     TSQLMemPageNo;
  ScanEntryCount: Integer;
  i:              Integer;
begin
  Position := TSQLMemKeyPath.Create;
  try
    if (not GetIndexPosition(SessionID, RecordID, RecordBuffer, Position)) then
     Result := -1
    else
     begin
       Result := 0;
       ScanPageNo := Position.Items[Position.Count-1].PageNo;
       while (ScanPageNo <> INVALID_PAGE_NO) do
        begin
          ScanPage := GetIndexPage(SessionID, ScanPageNo);
          try
            if (ScanPage.PageNo <> Position.Items[Position.Count-1].PageNo) then
             ScanEntryCount := ScanPage.EntryCount
            else
             ScanEntryCount := Position.Items[Position.Count-1].EntryNo+1;
            if ((Bitmap = nil) or (not Bitmap.Active)) then
             Inc(Result, ScanEntryCount)
            else
             begin
               for i := 0 to ScanEntryCount-1 do
                if (TSQLMemRecordBitmap(Bitmap).IsRecordVisible(
                           PSQLMemRecordID(ScanPage.GetPReference(i))^)) then
                 Inc(Result);
             end;
           ScanPageNo := ScanPage.LeftPageNo;
          finally
           PutIndexPage(ScanPage);
          end;
        end;
     end;
  finally
    Position.Free;
  end;
end;// GetRecNoByRecordID


//------------------------------------------------------------------------------
// GetRecordIDByRecNo
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.GetRecordIDByRecNo(
                                SessionID:      TSQLMemSessionID;
                                RecNo:          TSQLMemRecordNo;
                                Bitmap:         TSQLMemRecordBitmap
                               ): TSQLMemRecordID;
var
  Position:       TSQLMemKeyPath;
  ScanPage:       TSQLMemBTreePage;
  ScanPageNo:     TSQLMemPageNo;
  i:              Integer;
  RecNoCounter:   TSQLMemRecordNo;
  Found:          Boolean;
begin
  Position := TSQLMemKeyPath.Create;
  try
    if (not GetFirstPosition(SessionID, Position)) then
     raise ESQLMemException.Create(20074, ErrorACannotRetreiveRecordFromEmptyIndex)
    else
     begin
       RecNoCounter := 0;
       ScanPageNo := Position.Items[Position.Count-1].PageNo;
       Found := False;
       while ((ScanPageNo <> INVALID_PAGE_NO) and (not Found)) do
        begin
          ScanPage := GetIndexPage(SessionID, ScanPageNo);
          try
            if ((Bitmap = nil) or (not Bitmap.Active)) then
              begin
                if (RecNoCounter + ScanPage.EntryCount < RecNo) then
                  Inc(RecNoCounter, ScanPage.EntryCount)
                else
                  begin
                    Found := True;
                    Move(
                         ScanPage.GetPReference(RecNo-1-RecNoCounter)^,
                         Result,
                         ScanPage.ReferenceSize
                        );
                    break;
                  end;
              end
            else
              begin
               for i := 0 to ScanPage.EntryCount-1 do
                if (TSQLMemRecordBitmap(Bitmap).IsRecordVisible(
                           PSQLMemRecordID(ScanPage.GetPReference(i))^)) then
                  begin
                    if (RecNoCounter = RecNo-1) then
                     begin
                       Found := True;
                       Move(
                             ScanPage.GetPReference(i)^,
                             Result,
                             ScanPage.ReferenceSize
                           );
                       break;
                     end
                    else
                     Inc(RecNoCounter);
                  end;
              end;
           ScanPageNo := ScanPage.RightPageNo;
          finally
           PutIndexPage(ScanPage);
          end;
        end;
       if (not Found) then
        raise ESQLMemException.Create(20075, ErrorACannotSetRecNoGreaterThanRecordCount);
     end;
  finally
    Position.Free;
  end;
end;// GetRecordIDByRecNo


//------------------------------------------------------------------------------
// CreateSearchInfo
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.CreateSearchInfo: TSQLMemSearchInfo;
begin
  New(PSQLMemBTreeSearchInfo(Result));
  PSQLMemBTreeSearchInfo(Result)^.IsFilled := False;
  PSQLMemBTreeSearchInfo(Result)^.CurrentKeyPath := TSQLMemKeyPath.Create;
  PSQLMemBTreeSearchInfo(Result)^.EndKeyPath := nil;
end;// CreateSearchInfo


//------------------------------------------------------------------------------
// FreeSearchInfo
//------------------------------------------------------------------------------
procedure TSQLMemBTreeIndex.FreeSearchInfo(SearchInfo: TSQLMemSearchInfo);
begin
  if (PSQLMemBTreeSearchInfo(SearchInfo)^.CurrentKeyPath <> nil) then
    PSQLMemBTreeSearchInfo(SearchInfo)^.CurrentKeyPath.Free;
  if (PSQLMemBTreeSearchInfo(SearchInfo)^.EndKeyPath <> nil) then
   PSQLMemBTreeSearchInfo(SearchInfo)^.EndKeyPath.Free;
  Dispose(PSQLMemBTreeSearchInfo(SearchInfo));
end;// FreeSearchInfo


//------------------------------------------------------------------------------
// GetCurrentPosition
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.GetCurrentPosition(
                             SessionID:           TSQLMemSessionID;
                             Restart:             Boolean;
                             GoForward:           Boolean;
                             StartScanCondition:  TSQLMemScanSearchCondition;
                             RecordBuffer:        TSQLMemRecordBuffer;
                             RecordID:            TSQLMemRecordID;
                             SearchInfo:          TSQLMemSearchInfo
                                          ): Boolean;
var
  Page:        TSQLMemBTreePage;
  KeyBuffer:  PAnsiChar;
  Pos:                           TSQLMemKeyPath;
  Res:                           Integer;
  TakeFindFirstInsteadOfCurrent: Boolean;
begin
    if (StartScanCondition = nil) then
   if (Restart) then
     Result := GetPosition(SessionID, Restart, GoForward,
                           PSQLMemBTreeSearchInfo(SearchInfo)^.CurrentKeyPath)
   else
     Result := GetIndexPosition(SessionID, RecordID, RecordBuffer,
                                PSQLMemBTreeSearchInfo(SearchInfo)^.CurrentKeyPath)
    else
      begin
        KeyBuffer := FKeyRef.AllocKeyBuffer;
        Page := GetIndexPage(SessionID, IndexDef.RootPageNo);
        FKeyRef.CompareFieldCount := StartScanCondition.KeyFieldCount;
        try
          FKeyRef.MakeKeyFromRecordBuffer(StartScanCondition.KeyRecordBuffer, KeyBuffer);
          Result := Page.FindByCondition(
                              SessionID,
                              GoForward,
                              KeyBuffer,
                              StartScanCondition.Condition,
                              PSQLMemBTreeSearchInfo(SearchInfo)^.CurrentKeyPath
                                        );
        finally
          FKeyRef.FreeAndNilKeyBuffer(KeyBuffer);
          FKeyRef.CompareFieldCount := FKeyRef.PartCount;
          PutIndexPage(Page);
        end;

      if (Result and (not Restart)) then
        begin
          Pos := TSQLMemKeyPath.Create;
          TakeFindFirstInsteadOfCurrent := False;
          try
            Result := GetIndexPosition(SessionID, RecordID, RecordBuffer, Pos);
            if (Result) then
             begin
               Res := CompareRecordPositionsInIndex(
                                       Pos,
                                       PSQLMemBTreeSearchInfo(SearchInfo)^.CurrentKeyPath
                                                     );
               if (GoForward) then
                 TakeFindFirstInsteadOfCurrent := (Res < 0)
               else
                 TakeFindFirstInsteadOfCurrent := (Res > 0);
               if (not TakeFindFirstInsteadOfCurrent) then
                begin
                  PSQLMemBTreeSearchInfo(SearchInfo)^.CurrentKeyPath.Free;
                  PSQLMemBTreeSearchInfo(SearchInfo)^.CurrentKeyPath := Pos;
                end
               else
                 Result := GetPriorPosition(SessionID, PSQLMemBTreeSearchInfo(SearchInfo)^.CurrentKeyPath);
             end;
          finally
            if (TakeFindFirstInsteadOfCurrent) then
              Pos.Free;
          end;
        end;
    end;
end;// GetCurrentPosition


//------------------------------------------------------------------------------
// GetEndPosition
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.GetEndPosition(
                             SessionID:           TSQLMemSessionID;
                             GoForward:           Boolean;
                             StartScanCondition:  TSQLMemScanSearchCondition;
                             EndScanCondition:    TSQLMemScanSearchCondition;
                             SearchInfo:          TSQLMemSearchInfo
                                      ): Boolean;
var
  Page:    TSQLMemBTreePage;
  EndCond: TSQLMemScanSearchCondition;
  KeyBuffer:  PAnsiChar;
begin
  if (StartScanCondition <> nil) then
    begin
      KeyBuffer := FKeyRef.AllocKeyBuffer;
      Page := GetIndexPage(SessionID, IndexDef.RootPageNo);
      try
        PSQLMemBTreeSearchInfo(SearchInfo)^.EndKeyPath := TSQLMemKeyPath.Create;
        if (EndScanCondition <> nil) then
          EndCond := EndScanCondition
        else
          EndCond := StartScanCondition;
        FKeyRef.CompareFieldCount := EndCond.KeyFieldCount;
        FKeyRef.MakeKeyFromRecordBuffer(EndCond.KeyRecordBuffer, KeyBuffer);
        Result := Page.FindByCondition(
                        SessionID,
                        not GoForward,
                        KeyBuffer,
                        EndCond.Condition,
                        PSQLMemBTreeSearchInfo(SearchInfo)^.EndKeyPath
                                      );
      finally
        FKeyRef.FreeAndNilKeyBuffer(KeyBuffer);
        FKeyRef.CompareFieldCount := FKeyRef.PartCount;
        PutIndexPage(Page);
      end;
    end
  else
    Result := True;
end;// GetEndPosition


//------------------------------------------------------------------------------
// FindRecord
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.FindRecord(
                   SessionID:           TSQLMemSessionID;
                   Restart:             Boolean;
                   GoForward:           Boolean;
                   StartScanCondition:  TSQLMemScanSearchCondition;
                   EndScanCondition:    TSQLMemScanSearchCondition;
                   RecordBuffer:        TSQLMemRecordBuffer;
                   var RecordID:        TSQLMemRecordID;
                   SearchInfo:          TSQLMemSearchInfo
                                  ): Boolean;
var
  Res:     Integer;
begin
{$IFDEF DEBUG_BTREE_INDEX_FIND_RECORD_TIME}
aaIncCounter(counter30);
aaStartTime(time30);
try
{$ENDIF}
  if (SearchInfo = nil) then
    raise ESQLMemException.Create(20077, ErrorANilPointer);
  if ((Restart) and (PSQLMemBTreeSearchInfo(SearchInfo)^.IsFilled)) then
    raise ESQLMemException.Create(20078, ErrorABTreeInvalidParams);

  Result := True;
{$IFDEF DEBUG_BTREE_INDEX_FIND_RECORD_TIME}
aaStartTime(time25);
{$ENDIF}
  if (Restart or (not PSQLMemBTreeSearchInfo(SearchInfo)^.IsFilled)) then
    Result := GetCurrentPosition(SessionID, Restart, GoForward, StartScanCondition,
                                 RecordBuffer, RecordID, SearchInfo);
{$IFDEF DEBUG_BTREE_INDEX_FIND_RECORD_TIME}
aaStopTime(time25);
aaStartTime(time26);
{$ENDIF}
  if (Result and (not PSQLMemBTreeSearchInfo(SearchInfo)^.IsFilled)) then
    if (not GetEndPosition(SessionID, GoForward, StartScanCondition, EndScanCondition, SearchInfo)) then
     begin
{$IFDEF DEBUG_BTREE_INDEX_FIND_RECORD_TIME}
aaStopTime(time26);
{$ENDIF}
      // changed in 4.60
      //raise ESQLMemException.Create(20079, ErrorABTreeInvalidParams);
      Result := False;
      Exit;
     end;
{$IFDEF DEBUG_BTREE_INDEX_FIND_RECORD_TIME}
aaStopTime(time26);
aaStartTime(time27);
{$ENDIF}
  // modified in 4.70 -
  // bug fix in SetRange on table without records matching conditions
  if (Result) then
   begin
    if (not Restart) then
      Result := GetPosition(SessionID, Restart, GoForward,
                          PSQLMemBTreeSearchInfo(SearchInfo)^.CurrentKeyPath);
    if (Result and (PSQLMemBTreeSearchInfo(SearchInfo)^.EndKeyPath <> nil)) then
     begin
       Res := CompareRecordPositionsInIndex(
                               PSQLMemBTreeSearchInfo(SearchInfo)^.CurrentKeyPath,
                               PSQLMemBTreeSearchInfo(SearchInfo)^.EndKeyPath);
       if (GoForward) then
         Result := (Res <= 0)
       else
         Result := (Res >= 0);
     end; // Result and EndKeyPath exists
   end; // if Result
{$IFDEF DEBUG_BTREE_INDEX_FIND_RECORD_TIME}
aaStopTime(time27);
aaIncCounter(counter28);
aaStartTime(time28);
{$ENDIF}
  if (Result) then
    begin
      RecordID := GetRecordID(SessionID, PSQLMemBTreeSearchInfo(SearchInfo)^.CurrentKeyPath);
      if (not PSQLMemBTreeSearchInfo(SearchInfo)^.IsFilled) then
       begin
        PSQLMemBTreeSearchInfo(SearchInfo)^.GoForward := GoForward;
        PSQLMemBTreeSearchInfo(SearchInfo)^.IsFilled := True;
       end;
    end;
{$IFDEF DEBUG_BTREE_INDEX_FIND_RECORD_TIME}
aaStopTime(time28);
finally aaStopTime(time30); end;
{$ENDIF}
end;// FindRecord


//------------------------------------------------------------------------------
// return 0 if record buffers are equal in this index
// return 1 if Buffer1 is higher than Buffer 2 (Pos1 > Pos2)
// return -1 if Buffer1 is lower than Buffer 2 (Pos1 < Pos2)
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.CompareRecordBuffersByIndex(
                        Buffer1: TSQLMemRecordBuffer;
                        Buffer2: TSQLMemRecordBuffer;
                        IndexFieldCount: Integer
                                    ): Integer;
var KeyBuffer1, KeyBuffer2: PAnsiChar;
begin
 KeyBuffer1 := FKeyRef.AllocKeyBuffer;
 KeyBuffer2 := FKeyRef.AllocKeyBuffer;
 FKeyRef.CompareFieldCount := IndexFieldCount;
 try
   FKeyRef.MakeKeyFromRecordBuffer(Buffer1, KeyBuffer1);
   FKeyRef.MakeKeyFromRecordBuffer(Buffer2, KeyBuffer2);
   Result := FKeyRef.CompareKeys(KeyBuffer1,KeyBuffer2);
 finally
   FKeyRef.CompareFieldCount := FKeyRef.PartCount;
   FKeyRef.FreeAndNilKeyBuffer(KeyBuffer1);
   FKeyRef.FreeAndNilKeyBuffer(KeyBuffer2);
 end;
end; // CompareRecordBuffersByIndex


//------------------------------------------------------------------------------
// return 0 if conditions are equal in this index
// return 1 if Condition1 is higher than Condition2
// return -1 if Condition1 is lower than Condition2
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.CompareConditions(
                Condition1:   TSQLMemScanSearchCondition;
                Condition2:   TSQLMemScanSearchCondition
                          ): Integer;
begin
  if (Condition1.Condition in [scGreater, scGreaterEqual]) then
   Result := -1
  else
   if (Condition1.Condition in [scLower, scLowerEqual]) then
    Result := 1
   else
    Result := 0;
end;// CompareConditions


//------------------------------------------------------------------------------
// approximate record count between range conditions
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.GetApproxRangeRecordCount(
                SessionID:         TSQLMemSessionID;
                TableRecordCount:  TSQLMemRecordNo;
                RangeCondition1:   TSQLMemScanSearchCondition;
                RangeCondition2:   TSQLMemScanSearchCondition
                                  ): TSQLMemRecordNo;
var
  FKeyBuffer:             PAnsiChar;
  KeyPath:                TSQLMemKeyPath;
  RangeStartCondition:    TSQLMemScanSearchCondition;
  RangeEndCondition:      TSQLMemScanSearchCondition;
  ApproxRecNo1InPercents: Double;
  ApproxRecNo2InPercents: Double;
  CompareCount:           Integer;
  bFind:                  Boolean;
begin
{$IFDEF DEBUG_TRACE_TSQLMemBTreeIndex_GetApproxRangeRecordCount}
aaWriteToLog('> TSQLMemBTreeIndex.GetApproxRangeRecordCount'
+#13#10+'SessionID = '+IntToStr(SessionID)
+#13#10+'TableRecordCount = '+IntToStr(TableRecordCount)
);
aaWriteToLog('TSQLMemBTreeIndex.GetApproxRangeRecordCount. RootPageNo = '+IntToStr(IndexDef.RootPageNo));
if (RangeCondition1 <> nil) then
begin
 aaWriteToLog('RangeCondition1: Key Fields Count = '+IntToStr(RangeCondition1.KeyFieldCount));
 aaWriteToLog('RangeCondition1: IndexID = '+IntToStr(RangeCondition1.IndexID));
 aaWriteToLog('RangeCondition1: Expression = '+IntToHex(Integer(RangeCondition1.Expression),8));
end
else
 aaWriteToLog('RangeCondition1: not set');
if (RangeCondition2 <> nil) then
begin
 aaWriteToLog('RangeCondition2: Key Fields Count = '+IntToStr(RangeCondition2.KeyFieldCount));
 aaWriteToLog('RangeCondition2: IndexID = '+IntToStr(RangeCondition2.IndexID));
 aaWriteToLog('RangeCondition2: Expression = '+IntToHex(Integer(RangeCondition2.Expression),8));
end
else
 aaWriteToLog('RangeCondition2: not set');
{$ENDIF}
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStartTime(time12);
{$ENDIF}

  if (IndexDef.RootPageNo <> INVALID_PAGE_NO) then
   begin
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStartTime(time13);
{$ENDIF}
    CompareCount := CompareConditions(RangeCondition1, RangeCondition2);
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStopTime(time13);
{$ENDIF}
    if (CompareCount < 0) then
     begin
       RangeStartCondition := RangeCondition1;
       RangeEndCondition := RangeCondition2;
     end
    else
     begin
       RangeStartCondition := RangeCondition2;
       RangeEndCondition := RangeCondition1;
     end;
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStartTime(time14);
{$ENDIF}
    FKeyBuffer := FKeyRef.AllocKeyBuffer;
    KeyPath := TSQLMemKeyPath.Create;
    FRootPage := nil;
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStopTime(time14);
{$ENDIF}
    try
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStartTime(time15);
{$ENDIF}
     FKeyRef.MakeKeyFromRecordBuffer(RangeStartCondition.KeyRecordBuffer, FKeyBuffer);
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStopTime(time15);
aaStartTime(time16);
{$ENDIF}
     FRootPage := GetIndexPage(SessionID, IndexDef.RootPageNo);
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStopTime(time16);
aaStartTime(time17);
{$ENDIF}
     FKeyRef.CompareFieldCount := RangeStartCondition.KeyFieldCount;
     bFind := FRootPage.FindByCondition(SessionID, True, FKeyBuffer,
                                   RangeStartCondition.Condition, KeyPath);
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStopTime(time17);
aaStartTime(time18);
{$ENDIF}
     if (not bFind) then
       Result := 0
     else
      begin
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStartTime(time19);
{$ENDIF}
         ApproxRecNo1InPercents := KeyPath.GetApproxRecNoInPercents;
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStopTime(time19);
aaStartTime(time20);
{$ENDIF}
         KeyPath.Clear;
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStopTime(time20);
aaStartTime(time21);
{$ENDIF}
         FKeyRef.MakeKeyFromRecordBuffer(RangeEndCondition.KeyRecordBuffer, FKeyBuffer);
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStopTime(time21);
aaStartTime(time22);
{$ENDIF}
         bFind := FRootPage.FindByCondition(SessionID, False, FKeyBuffer,
                                       RangeStartCondition.Condition, KeyPath);
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStopTime(time22);
{$ENDIF}
         if (not bFind) then
           Result := 0
         else
           begin
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStartTime(time23);
{$ENDIF}
             ApproxRecNo2InPercents := KeyPath.GetApproxRecNoInPercents;
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStopTime(time23);
{$ENDIF}
             Result := Round((ApproxRecNo2InPercents -
                              ApproxRecNo1InPercents) * TableRecordCount);
           end;
      end;
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStopTime(time18);
{$ENDIF}
    finally
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStartTime(time24);
{$ENDIF}
     if (FRootPage <> nil) then
      begin
        PutIndexPage(FRootPage);
      end;
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStopTime(time24);
{$ENDIF}
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStartTime(time25);
{$ENDIF}
     KeyPath.Free;
     FKeyRef.FreeAndNilKeyBuffer(FKeyBuffer);
     FKeyRef.CompareFieldCount := FKeyRef.PartCount;
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStopTime(time25);
{$ENDIF}
    end; // try
   end
  else
    Result := 0;
  if (Result < 0) then
   Result := 0;
  if (Result > TableRecordCount) then
   Result := TableRecordCount;
{$IFDEF DEBUG_TSQLMemTableData_ChooseScanConditions_TIME}
aaStopTime(time12);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TSQLMemBTreeIndex_GetApproxRangeRecordCount}
aaWriteToLog('< TSQLMemBTreeIndex.GetApproxRangeRecordCount. Result = '+IntToStr(Result));
{$ENDIF}
end;// GetApproxRangeRecordCount


//------------------------------------------------------------------------------
// CanInsertRecord
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.CanInsertRecord(
                                 SessionID:      TSQLMemSessionID;
                                 RecordBuffer:   TSQLMemRecordBuffer
                                 ): Boolean;
var
  KeyBuffer:             PAnsiChar;
  KeyPath:               TSQLMemKeyPath;
begin
  if ((IndexDef.RootPageNo <> INVALID_PAGE_NO) and
      ((IndexDef.Primary) or (IndexDef.Unique))) then
   begin
    KeyBuffer := FKeyRef.AllocKeyBuffer;
    KeyPath := TSQLMemKeyPath.Create;
    FRootPage := nil;
    try
{$IFDEF DEBUG_TRACE_TSQLMemBTreeIndex_CanInsertRecord}
aaWriteToLog('TSQLMemBTreeIndex.CanInsertRecord '+#13#10+
'Index name = '+IndexDef.Name+', RootPageNo = '+IntTostr(IndexDef.RootPageNo));
{$ENDIF}
      FRootPage := GetIndexPage(SessionID, IndexDef.RootPageNo);
      FKeyRef.MakeKeyFromRecordBuffer(RecordBuffer, KeyBuffer);
      Result := (not FRootPage.FindByCondition(SessionID, True, KeyBuffer, scEqual, KeyPath));
{$IFDEF DEBUG_TRACE_TSQLMemBTreeIndex_CanInsertRecord}
aaWriteToLog('TSQLMemBTreeIndex.CanInsertRecord '+#13#10+
'Index name = '+IndexDef.Name+', RootPageNo = '+IntTostr(IndexDef.RootPageNo)+
#13#10+'Result = '+BoolToStr(Result,True));
{$ENDIF}
    finally
      if (FRootPage <> nil) then
        PutIndexPage(FRootPage);
      KeyPath.Free;
      FKeyRef.FreeAndNilKeyBuffer(KeyBuffer);
    end;
   end
  else
   Result := True;
end;// CanInsertRecord


//------------------------------------------------------------------------------
// CanUpdateRecord
//------------------------------------------------------------------------------
function TSQLMemBTreeIndex.CanUpdateRecord(
                     SessionID:                        TSQLMemSessionID;
                     OldRecordBuffer, NewRecordBuffer: TSQLMemRecordBuffer
                                       ): Boolean;
begin
  if (CompareRecordBuffersByIndex(OldRecordBuffer, NewRecordBuffer,
                                  FKeyRef.PartCount) <> 0) then
    Result := CanInsertRecord(SessionID, NewRecordBuffer)
  else
    Result := True;
end;// CanUpdateRecord


//------------------------------------------------------------------------------
// insert record
//------------------------------------------------------------------------------
procedure TSQLMemBTreeIndex.InsertRecord(Cursor: TSQLMemCursor);
var
  FKeyBuffer: PAnsiChar;
  KeyPath: TSQLMemKeyPath;
begin
  FKeyBuffer := FKeyRef.AllocKeyBuffer;
  KeyPath := TSQLMemKeyPath.Create;
  FRootPage := nil;
  try
   FKeyRef.MakeKeyFromRecordBuffer(Cursor.CurrentRecordBuffer, FKeyBuffer);
   if (IndexDef.RootPageNo = INVALID_PAGE_NO) then
    begin
     FRootPage := AddIndexPage(Cursor.Session.SessionID);
     IndexDef.RootPageNo := FRootPage.PageNo;
     FRootPage.InitAsRoot;
    end
   else
     FRootPage := GetIndexPage(Cursor.Session.SessionID, IndexDef.RootPageNo);
   FRootPage.InsertLeafEntry(Cursor.Session.SessionID, FKeyBuffer, @Cursor.CurrentRecordID, KeyPath);

   {$IFDEF DEBUG_INDEXES}
   KeyPath.Clear;
   FRootPage.CheckIntegrity(Cursor.Session.SessionID,KeyPath);
   {$ENDIF}
  finally
   if (FRootPage <> nil) then
     PutIndexPage(FRootPage);
   FKeyRef.FreeAndNilKeyBuffer(FKeyBuffer);
   KeyPath.Free;
  end;
end;// InsertRecord


//------------------------------------------------------------------------------
// UpdateRecord
//------------------------------------------------------------------------------
procedure TSQLMemBTreeIndex.UpdateRecord(Cursor: TSQLMemCursor);
var
  FOldKeyBuffer: PAnsiChar;
  FNewKeyBuffer: PAnsiChar;
  KeyPath:       TSQLMemKeyPath;
begin
  FOldKeyBuffer := FKeyRef.AllocKeyBuffer;
  FNewKeyBuffer := FKeyRef.AllocKeyBuffer;
  KeyPath := TSQLMemKeyPath.Create;
  FRootPage := nil;
  try
   FKeyRef.MakeKeyFromRecordBuffer(Cursor.EditRecordBuffer, FOldKeyBuffer);
   FKeyRef.MakeKeyFromRecordBuffer(Cursor.CurrentRecordBuffer, FNewKeyBuffer);
   if (FKeyRef.CompareKeys(FOldKeyBuffer, FNewKeyBuffer) <> 0) then
     begin
       FRootPage := GetIndexPage(Cursor.Session.SessionID, IndexDef.RootPageNo);
       if (not FRootPage.DeleteLeafEntry(Cursor.Session.SessionID, FOldKeyBuffer, @Cursor.CurrentRecordID, KeyPath)) then
         raise ESQLMemException.Create(20027, ErrorABTreeDeleteEntryNotFound);

       KeyPath.Clear;
       FRootPage.InsertLeafEntry(Cursor.Session.SessionID, FNewKeyBuffer, @Cursor.CurrentRecordID, KeyPath);

      {$IFDEF DEBUG_INDEXES}
       KeyPath.Clear;
       FRootPage.CheckIntegrity(Cursor.Session.SessionID,KeyPath);
      {$ENDIF}
     end;
  finally
   if (FRootPage <> nil) then
     PutIndexPage(FRootPage);
   FKeyRef.FreeAndNilKeyBuffer(FOldKeyBuffer);
   FKeyRef.FreeAndNilKeyBuffer(FNewKeyBuffer);
   KeyPath.Free;
  end;
end;// UpdateRecord


//------------------------------------------------------------------------------
// DeleteRecord
//------------------------------------------------------------------------------
procedure TSQLMemBTreeIndex.DeleteRecord(Cursor: TSQLMemCursor);
var
  FKeyBuffer: PAnsiChar;
  KeyPath: TSQLMemKeyPath;
begin
  FKeyBuffer := FKeyRef.AllocKeyBuffer;
  KeyPath := TSQLMemKeyPath.Create;
  FRootPage := nil;
  try
   FKeyRef.MakeKeyFromRecordBuffer(Cursor.CurrentRecordBuffer, FKeyBuffer);
   FRootPage := GetIndexPage(Cursor.Session.SessionID, IndexDef.RootPageNo);
   if (not FRootPage.DeleteLeafEntry(Cursor.Session.SessionID, FKeyBuffer, @Cursor.CurrentRecordID, KeyPath)) then
     raise ESQLMemException.Create(20027, ErrorABTreeDeleteEntryNotFound);

   {$IFDEF DEBUG_INDEXES}
   KeyPath.Clear;
   FRootPage.CheckIntegrity(Cursor.Session.SessionID,KeyPath);
  {$ENDIF}
  finally
   if (FRootPage <> nil) then
     PutIndexPage(FRootPage);
   FKeyRef.FreeAndNilKeyBuffer(FKeyBuffer);
   KeyPath.Free;
  end;
end;// DeleteRecord


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('SQLMemBTree> initialized');
{$ENDIF}
  SQLMemMemoryIncUseCount;

finalization

  SQLMemMemoryDecUseCount;


end.
