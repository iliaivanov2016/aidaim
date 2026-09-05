unit ACRBTree;

{$I ACRVer.inc}

interface

uses SysUtils, Classes, Math,

{$DEFINE INDEX_NAVIGATION_OPTIMIZATION}
// Accuracer units
     {$IFDEF MSWINDOWS}
     Windows,
     {$ENDIF}
     ACRConverts,

     {$IFDEF DEBUG_LOG}
     ACRDebug,
     {$ENDIF}
     ACRPage,
     ACRBaseEngine,
     ACRExcept,
     ACRBase,
     ACRTypes,
     ACRVariant,
     ACRCriticalSection,
     ACRConst;

const ACRMaxKeyPathItemNo = 31;
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

  TACRBTreeLeafController = class;
  TACRBTreeNodeController = class;
  TACRBTreeIndex = class;

  // BTree PageHeader  
  TACRBTreePageHeader = packed record
     IsRoot:           Boolean;
     IsLeaf:           Boolean;
     LeftPageNo:       TACRPageNo;
     RightPageNo:      TACRPageNo;
     HasKeys:          Boolean;
     HasSuffixes:      Boolean;
     KeyPrefixSize:    Word;
     EntryCount:         Word;
     PagePrefixSize:   Word;
  end;
  PACRBTreePageHeader = ^TACRBTreePageHeader;

  TACRKeyPathItem = record
    PageNo:       TACRPageNo;
    EntryNo:      Integer;
    EntryCount:   Integer;
  end;

////////////////////////////////////////////////////////////////////////////////
//
// TACRBTreeKeyPath
//
////////////////////////////////////////////////////////////////////////////////


{$IFDEF INDEX_NAVIGATION_OPTIMIZATION}
  // keypath optimization
  TACRKeyPath = class;
  TACRKeyPathCacheItem = record
   SessionID:     TACRSessionID;
   RecordID:      TACRRecordID;
   KeyPath:       TACRKeyPath;
  end;
  PACRKeyPathCacheItem = ^TACRKeyPathCacheItem;

  TACRKeyPathCache = class(TObject)
   private
    FItems: TList;
   public
    constructor Create;
    destructor Destroy; override;
    procedure Clear(SessionID: TACRSessionID = INVALID_OBJECT_ID);
    function GetKeyPath(SessionID: TACRSessionID; RecordID: TACRRecordID; Clear: Boolean): TACRKeyPath;
    procedure SetKeyPath(SessionID: TACRSessionID; RecordID: TACRRecordID; KeyPath: TACRKeyPath);
  end;
{$ENDIF}

  // key path position
  TACRKeyPathPosition = (
    kppUnknown,
    kppOnKey,
    kppBeforeKey,
    kppAfterKey,
    kppBOF,
    kppEOF);
  PACRKeyPathPosition = ^TACRKeyPathPosition;

  TACRKeyPath = class (TObject)
   public
    Items: array [0..ACRMaxKeyPathItemNo] of TACRKeyPathItem;
    Count: Integer;
    ItemNo: Integer;
    PositionType: TACRKeyPathPosition;
    IndexState: Integer;

    constructor Create;
    procedure Clear;
    procedure AddItem(aPageNo: TACRPageNo; aEntryNo, aEntryCount: Integer);
    procedure DeleteLastItem;
    procedure IncLevel;
    procedure DecLevel;
    function GetCurrentPageNo: TACRPageNo;
    procedure SetCurrentPageNo(Value: TACRPageNo);
    function PageExists(aPageNo: TACRPageNo): Boolean;
    // return 0, 1, -1 if (Self = aKeyPath), (Self > aKeyPath), (Self < aKeyPath)
    function Compare(aKeyPath: TACRKeyPath): Integer;
    function GetApproxRecNoInPercents: double;
    procedure Assign(Source: TACRKeyPath);

    property  CurrentPageNo: TACRPageNo read GetCurrentPageNo write SetCurrentPageNo;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRBTreeKeyRef
//
////////////////////////////////////////////////////////////////////////////////

  TACRKeyPart = record
   OffsetInKeyBuffer:      Integer;
   OffsetInRecordBuffer:   Integer; // optional
   FieldNo:                Integer;  // optional
   Size:                   Integer;
   DataType:               TACRBaseFieldType;
   Descending:             Boolean;
   CaseInsensitive:        Boolean;
  end;

  TACRBTreeKeyRef = class (TObject)
   private
     FKeySize:            Integer;
     FReferenceSize:      Word;
     FKeyIsReference:     Boolean;
     FCompareFieldCount:  Integer;

     function GetPartCount: Integer;
     procedure SetPartCount(Value: Integer);

   public
     Parts: array of TACRKeyPart;

     constructor Create;
     procedure Assign(IndexDef: TACRIndexDef; aTableData: Pointer);
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
// TACRBTreePage
//
////////////////////////////////////////////////////////////////////////////////

  TACRBTreePage = class(TACRPageController)
   private
     FLeafController:       TACRBTreeLeafController;
     FNodeController:       TACRBTreeNodeController;
     FKeyRef:               TACRBTreeKeyRef;
     LBTreeIndex:           TACRBTreeIndex;

     function GetIsRoot: Boolean;
     procedure SetIsRoot(Value: Boolean);
     function GetIsLeaf: Boolean;
     procedure SetIsLeaf(Value: Boolean);
     function GetLeftPageNo: TACRPageNo;
     procedure SetLeftPageNo(Value: TACRPageNo);
     function GetRightPageNo: TACRPageNo;
     procedure SetRightPageNo(Value: TACRPageNo);
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
     constructor Create(BTreeIndex: TACRBTreeIndex; Page: TACRPage);
     destructor Destroy; override;
     procedure Init;
     procedure InitAsRoot;
     procedure CopyFrom(Source: TACRBTreePage; StartNo, Count: Integer);
     procedure AppendFrom(Source: TACRBTreePage; StartNo, Count: Integer);
     procedure InsertFrom(Source: TACRBTreePage; StartNo, Count: Integer);
     procedure InsertLeafEntry(SessionID: TACRSessionID; Key, Reference: PAnsiChar; KeyPath: TACRKeyPath);
     procedure InsertNodeEntry(SessionID: TACRSessionID; Key, Reference: PAnsiChar; KeyPath: TACRKeyPath);
     function DeleteLeafEntry(SessionID: TACRSessionID; Key, Reference: PAnsiChar; KeyPath: TACRKeyPath): Boolean;
     procedure DeleteNodeEntry(
                        SessionID:     TACRSessionID;
                        KeyPath:       TACRKeyPath;
                        MergeWithLeft: Boolean
                              );
     function FindEntry(
                        SessionID: TACRSessionID;
                        Key:       PAnsiChar;
                        Reference: PAnsiChar;
                        Position:  TACRKeyPath
                       ): Boolean;
     function GetFirstPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean;
     function GetLastPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean;
     function FindByCondition(
                              SessionID: TACRSessionID;
                              First:     Boolean; // if False => Last
                              Key:       PAnsiChar;
                              Operator:  TACRSearchCondition;
                              Position:  TACRKeyPath
                             ): Boolean;

     procedure FreeAllPages(SessionID: TACRSessionID; RootPageNo: TACRPageNo = INVALID_PAGE_NO);
     procedure CheckIntegrity(SessionID: TACRSessionID; KeyPath: TACRKeyPath);
     function GetPKey(KeyPosition: Integer): PAnsiChar;
     function GetPReference(RefPosition: Integer): PAnsiChar;
     procedure GetFirstKey(SessionID: TACRSessionID; Key: PAnsiChar);
     procedure GetLastKey(SessionID: TACRSessionID; Key: PAnsiChar);
     procedure UpdateKey(Position: Integer; Key: PAnsiChar);

     //--- BTree page header ---
     property IsRoot: Boolean read GetIsRoot write SetIsRoot;
     property IsLeaf: Boolean read GetIsLeaf write SetIsLeaf;
     property LeftPageNo: TACRPageNo read GetLeftPageNo write SetLeftPageNo;
     property RightPageNo: TACRPageNo read GetRightPageNo write SetRightPageNo;
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

     property KeyRef: TACRBTreeKeyRef read FKeyRef write FKeyRef;
  end;



////////////////////////////////////////////////////////////////////////////////
//
// TACRBTreePageController
//
////////////////////////////////////////////////////////////////////////////////


  TACRBTreePageController = class(TObject)
   protected
     FPage:                  TACRBTreePage;
     LTableData:             TACRTableData;

     function GetKeyRef: TACRBTreeKeyRef;
     function CanAddEntry: Boolean;
     function IsOverflow: Boolean;
     function CanUnderflow: Boolean;
     function CanMergeWithPage(Page: TACRBTreePage): Boolean;
     procedure EnlargePageBuffer;
     function CompareKeys(Key1: PAnsiChar; Key2Index: Word): Integer; overload;
     function CompareKeys(Key1, Key2: PAnsiChar; KeyRef: TACRBTreeKeyRef): Integer; overload;
     function CompareReferences(Reference1: PAnsiChar; Reference2Index: Word): Boolean;
     function GetKeyPosition(
                       Key: PAnsiChar;
                       StartPosition: Integer = 0;
                       PositionType: PACRKeyPathPosition = nil;
                       SearchType: TACRKeySearchType = kstAny
                             ): Word;
     procedure InsertEntry(Key, Reference: PAnsiChar; Position: Integer);
     procedure DeleteEntry(Position: Integer);
     procedure RootSplit(SessionID: TACRSessionID; KeyPath: TACRKeyPath);
     procedure NonRootSplit(SessionID: TACRSessionID; KeyPath: TACRKeyPath);
     function TryMergeWithPage(
                        SessionID: TACRSessionID;
                        MergePageNo: TACRPageNo;
                        KeyPath: TACRKeyPath
                               ): Boolean;
     function TryMerge(SessionID: TACRSessionID; KeyPath: TACRKeyPath): Boolean;
     procedure MergeWithLeftPage(
                        SessionID: TACRSessionID;
                        LeftPage: TACRBTreePage;
                        KeyPath: TACRKeyPath
                                );
     procedure MergeWithRightPage(
                        SessionID: TACRSessionID;
                        RightPage: TACRBTreePage;
                        KeyPath: TACRKeyPath
                                );
   public
     constructor Create(
                        aPage:        TACRBTreePage;
                        aTableData:   TACRTableData
                       );
     procedure InsertLeafEntry(SessionID: TACRSessionID; Key, Reference: PAnsiChar; KeyPath: TACRKeyPath); virtual; abstract;
     function DeleteLeafEntry(SessionID: TACRSessionID; Key, Reference: PAnsiChar; KeyPath: TACRKeyPath): Boolean; virtual; abstract;
     procedure FreeAllPages(SessionID: TACRSessionID; RootPageNo: TACRPageNo = INVALID_PAGE_NO); virtual; abstract;
     procedure CheckIntegrity(SessionID: TACRSessionID; KeyPath: TACRKeyPath); virtual; abstract;
     function FindEntry(
                        SessionID: TACRSessionID;
                        Key:       PAnsiChar;
                        Reference: PAnsiChar;
                        Position:  TACRKeyPath
                       ): Boolean; virtual; abstract;
     function GetFirstPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean; virtual; abstract;
     function GetLastPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean; virtual; abstract;
     function FindByCondition(
                              SessionID: TACRSessionID;
                              First:     Boolean; // if False => Last
                              Key:       PAnsiChar;
                              Operator:  TACRSearchCondition;
                              Position:  TACRKeyPath
                             ): Boolean; virtual; abstract;
     function GetPKey(KeyPosition: Integer): PAnsiChar;
     function GetPReference(RefPosition: Integer): PAnsiChar;
     procedure GetFirstKey(SessionID: TACRSessionID; Key: PAnsiChar); virtual; abstract;
     procedure GetLastKey(SessionID: TACRSessionID; Key: PAnsiChar); virtual; abstract;
     procedure Split(SessionID: TACRSessionID; KeyPath: TACRKeyPath);
     function KeyMatch(
                          KeyPosition:     Integer;
                          SearchKey:       PAnsiChar;
                          SearchCondition: TACRSearchCondition
                      ): Boolean;

     property KeyRef: TACRBTreeKeyRef read GetKeyRef;
  end;// TACRBTreePageController



////////////////////////////////////////////////////////////////////////////////
//
// TACRBTreeLeafController
//
////////////////////////////////////////////////////////////////////////////////


  TACRBTreeLeafController = class(TACRBTreePageController)
   private
     function FindEntryOnPage(Key, Reference: PAnsiChar; var EntryNo: Integer): Boolean;
     function FindFirstByCondition(
                                    Key:       PAnsiChar;
                                    Operator:  TACRSearchCondition;
                                    Position:  TACRKeyPath
                                  ): Boolean;
     function FindLastByCondition(
                                    Key:       PAnsiChar;
                                    Operator:  TACRSearchCondition;
                                    Position:  TACRKeyPath
                                  ): Boolean;
   public
     procedure InsertLeafEntry(SessionID: TACRSessionID; Key, Reference: PAnsiChar; KeyPath: TACRKeyPath); override;
     function DeleteLeafEntry(SessionID: TACRSessionID; Key, Reference: PAnsiChar; KeyPath: TACRKeyPath): Boolean; override;
     procedure GetFirstKey(SessionID: TACRSessionID; Key: PAnsiChar); override;
     procedure GetLastKey(SessionID: TACRSessionID; Key: PAnsiChar); override;
     function FindEntry(
                          SessionID: TACRSessionID;
                          Key:       PAnsiChar;
                          Reference: PAnsiChar;
                          Position:  TACRKeyPath
                       ): Boolean; override;
     function GetFirstPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean; override;
     function GetLastPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean; override;
     function FindByCondition(
                              SessionID: TACRSessionID;
                              First:     Boolean; // if False => Last
                              Key:       PAnsiChar;
                              Operator:  TACRSearchCondition;
                              Position:  TACRKeyPath
                             ): Boolean; override;
     procedure FreeAllPages(SessionID: TACRSessionID; RootPageNo: TACRPageNo = INVALID_PAGE_NO); override;
     procedure CheckIntegrity(SessionID: TACRSessionID; KeyPath: TACRKeyPath); override;
  end;// TACRBTreeLeafController



////////////////////////////////////////////////////////////////////////////////
//
// TACRBTreeNodeController
//
////////////////////////////////////////////////////////////////////////////////


  TACRBTreeNodeController = class(TACRBTreePageController)
   private
    function FindByConditionOnOneOfPages(
                                    SessionID:    TACRSessionID;
                                    First:        Boolean; // if False => Last
                                    StartEntryNo: Integer;
                                    EndEntryNo:   Integer;
                                    Key:          PAnsiChar;
                                    Operator:     TACRSearchCondition;
                                    Position:     TACRKeyPath
                                  ): Boolean;
    function FindEntryOnOneOfPages(
                                    SessionID:    TACRSessionID;
                                    StartEntryNo: Integer;
                                    EndEntryNo:   Integer;
                                    Key:          PAnsiChar;
                                    Reference:    PAnsiChar;
                                    Position:     TACRKeyPath
                                  ): Boolean;
    procedure GetChildPagesToCheck(
                          Key:               PAnsiChar;
                          SearchCondition:   TACRSearchCondition;
                          var StartEntryNo:  Integer;
                          var EndEntryNo:    Integer
                                    );
     procedure DecreaseTreeDepth(SessionID: TACRSessionID);

   public
     procedure InsertLeafEntry(SessionID: TACRSessionID; Key, Reference: PAnsiChar; KeyPath: TACRKeyPath); override;
     procedure InsertNodeEntry(SessionID: TACRSessionID; Key, Reference: PAnsiChar; KeyPath: TACRKeyPath);
     function DeleteLeafEntry(SessionID: TACRSessionID; Key, Reference: PAnsiChar; KeyPath: TACRKeyPath): Boolean; override;
     procedure DeleteNodeEntry(
                        SessionID:     TACRSessionID;
                        KeyPath:       TACRKeyPath;
                        MergeWithLeft: Boolean
                              );
     procedure GetFirstKey(SessionID: TACRSessionID; Key: PAnsiChar); override;
     procedure GetLastKey(SessionID: TACRSessionID; Key: PAnsiChar); override;
     function FindEntry(
                          SessionID: TACRSessionID;
                          Key:       PAnsiChar;
                          Reference: PAnsiChar;
                          Position:  TACRKeyPath
                       ): Boolean; override;
     function GetFirstPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean; override;
     function GetLastPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean; override;
     function FindByCondition(
                              SessionID: TACRSessionID;
                              First:     Boolean; // if False => Last
                              Key:       PAnsiChar;
                              Operator:  TACRSearchCondition;
                              Position:  TACRKeyPath
                             ): Boolean; override;
     procedure FreeAllPages(SessionID: TACRSessionID; RootPageNo: TACRPageNo = INVALID_PAGE_NO); override;
     procedure CheckIntegrity(SessionID: TACRSessionID; KeyPath: TACRKeyPath); override;
  end;// TACRBTreeNodeController



////////////////////////////////////////////////////////////////////////////////
//
// TACRBTreeIndex
//
////////////////////////////////////////////////////////////////////////////////

  TACRBTreeSearchInfo = packed record
     GoForward:       Boolean;
     IsFilled:        Boolean;
     EndKeyPath:      TACRKeyPath;
     CurrentKeyPath:  TACRKeyPath;
  end;
  PACRBTreeSearchInfo = ^TACRBTreeSearchInfo;

  { TODO -oLeo :
Indexes are not thread safe - parallel search by multiple threads is impossible
Fix in v.5 }
  TACRBTreeIndex = class (TACRIndex)
   private
    FRootPage:          TACRBTreePage;
    FKeyRef:            TACRBTreeKeyRef;
    FThreadSync:        TACRReadWriteThreadSyncBySingleCriticalSection;
{$IFDEF INDEX_NAVIGATION_OPTIMIZATION}
// keypath cache
    FKeyPathCache:      TACRKeyPathCache;
{$ENDIF}
    // lock
    procedure Lock(WriteMode: Boolean = false);
    // unlock
    procedure Unlock;
    function AddIndexPage(SessionID: TACRSessionID): TACRBTreePage;
    procedure RemoveIndexPage(SessionID: TACRSessionID; PageNo: TACRPageNo);
    function GetIndexPage(SessionID: TACRSessionID; PageNo: TACRPageNo): TACRBTreePage;
    procedure PutIndexPage(Page: TACRBTreePage);

    function GetRecordID(SessionID: TACRSessionID; Position: TACRKeyPath): TACRRecordID;
    function GetFirstPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean;
    function GetLastPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean;
    function GetNextPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean;
    function GetPriorPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean;
    function GetPosition(SessionID: TACRSessionID; Restart, GoForward: Boolean; Position: TACRKeyPath): Boolean;

   public
    constructor Create(aIndexManager: TACRBaseIndexManager);
    destructor Destroy; override;

    // clear index cache (INVALID_OBJECT_ID means all sessions)
    procedure ClearIndexCache(SessionID: TACRSessionID = INVALID_OBJECT_ID); override;
    procedure CreateIndex(Cursor: TACRCursor; aIndexDef: TACRIndexDef); overload; override;
    procedure CreateIndex(SessionID: TACRSessionID; pageNo: TACRPageNo; aIndexDef: TACRIndexDef); overload; override;
    procedure DropIndex(SessionID: TACRSessionID; EmptyIndex: Boolean = False); override;
    procedure OpenIndex(aIndexDef: TACRIndexDef); override;

    procedure GetRecordBuffer(
                               SessionID:          TACRSessionID;
                               var NavigationInfo: TACRNavigationInfo
                             ); override;
    function CreateIndexPosition: TACRIndexPosition; override;
    procedure FreeIndexPosition(var IndexPosition: TACRIndexPosition); override;
    function GetIndexPosition(
                               SessionID:      TACRSessionID;
                               RecordID:       TACRRecordID;
                               RecordBuffer:   TACRRecordBuffer;
                               IndexPosition:  TACRIndexPosition
                             ): Boolean; override;
    // return 0, 1, -1 if (Pos1 = Pos2), (Pos1 > Pos2), (Pos1 < Pos2)
    function CompareRecordPositionsInIndex(
                        RecordPosition1: TACRIndexPosition;
                        RecordPosition2: TACRIndexPosition
                                          ): Integer; override;
    function GetRecNoByRecordID(
                                SessionID:      TACRSessionID;
                                RecordID:       TACRRecordID;
                                RecordBuffer:   TACRRecordBuffer;
                                Bitmap:         TACRRecordBitmap
                               ): TACRRecordNo; override;
    function GetRecordIDByRecNo(
                                SessionID:      TACRSessionID;
                                RecNo:          TACRRecordNo;
                                Bitmap:         TACRRecordBitmap
                               ): TACRRecordID; override;
    function CreateSearchInfo: TACRSearchInfo; override;
    procedure FreeSearchInfo(SearchInfo: TACRSearchInfo); override;
   private
    function GetCurrentPosition(
                                 SessionID:           TACRSessionID;
                                 Restart:             Boolean;
                                 GoForward:           Boolean;
                                 StartScanCondition:  TACRScanSearchCondition;
                                 RecordBuffer:        TACRRecordBuffer;
                                 RecordID:            TACRRecordID;
                                 SearchInfo:          TACRSearchInfo
                               ): Boolean;
    function GetEndPosition(
                                 SessionID:           TACRSessionID;
                                 GoForward:           Boolean;
                                 StartScanCondition:  TACRScanSearchCondition;
                                 EndScanCondition:    TACRScanSearchCondition;
                                 SearchInfo:          TACRSearchInfo
                               ): Boolean;
   public
    function FindRecord(
                       SessionID:           TACRSessionID;
                       Restart:             Boolean;
                       GoForward:           Boolean;
                       StartScanCondition:  TACRScanSearchCondition;
                       EndScanCondition:    TACRScanSearchCondition;
                       RecordBuffer:        TACRRecordBuffer;
                       var RecordID:        TACRRecordID;
                       SearchInfo:          TACRSearchInfo
                       ): Boolean; override;
    // return 0 if record buffers are equal in this index
    // return 1 if Buffer1 is higher than Buffer 2 (Pos1 > Pos2)
    // return -1 if Buffer1 is lower than Buffer 2 (Pos1 < Pos2)
    function CompareRecordBuffersByIndex(
                        Buffer1: TACRRecordBuffer;
                        Buffer2: TACRRecordBuffer;
                        IndexFieldCount: Integer
                                        ): Integer; override;

    // return 0 if conditions are equal in this index
    // return 1 if Condition1 is higher than Condition2
    // return -1 if Condition1 is lower than Condition2
    function CompareConditions(
                    Condition1:   TACRScanSearchCondition;
                    Condition2:   TACRScanSearchCondition
                              ): Integer; override;
    // approximate record count between range conditions
    function GetApproxRangeRecordCount(
                    SessionID:         TACRSessionID;
                    TableRecordCount:  TACRRecordNo;
                    RangeCondition1:   TACRScanSearchCondition;
                    RangeCondition2:   TACRScanSearchCondition
                                      ): TACRRecordNo; override;

    function CanInsertRecord(
                    SessionID:      TACRSessionID;
                    RecordBuffer:   TACRRecordBuffer
                            ): Boolean; override;
    function CanUpdateRecord(
                    SessionID:                        TACRSessionID;
                    OldRecordBuffer, NewRecordBuffer: TACRRecordBuffer
                            ): Boolean; override;
    procedure InsertRecord(Cursor: TACRCursor); override;
    procedure UpdateRecord(Cursor: TACRCursor); override;
    procedure DeleteRecord(Cursor: TACRCursor); override;

    property KeyRef: TACRBTreeKeyRef read FKeyRef;
  end; // TACRBTreeIndex



implementation

uses ACRLocalEngine,
     ACRMemory        // last
;


{$IFDEF INDEX_NAVIGATION_OPTIMIZATION}
////////////////////////////////////////////////////////////////////////////////
//
// TACRBTreeKeyPathCache
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRKeyPathCache.Create;
begin
 inherited;
 FItems := TList.Create;
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TACRKeyPathCache.Destroy;
begin
 Clear;
 FItems.Free;
 inherited Destroy;
end; // Create


//------------------------------------------------------------------------------
// clear index cache (INVALID_OBJECT_ID means all sessions)
//------------------------------------------------------------------------------
procedure TACRKeyPathCache.Clear(SessionID: TACRSessionID);
var i: Integer;
begin
 i := 0;
 while (i <= FItems.Count-1) do
  begin
   if (SessionID = INVALID_OBJECT_ID) or (SessionID = PACRKeyPathCacheItem(FItems.Items[i])^.SessionID) then
    begin
     PACRKeyPathCacheItem(FItems.Items[i])^.KeyPath.Free;
     Dispose(PACRKeyPathCacheItem(FItems.Items[i]));
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
function TACRKeyPathCache.GetKeyPath(SessionID: TACRSessionID; RecordID: TACRRecordID; Clear: Boolean): TACRKeyPath;
var CacheItem: PACRKeyPathCacheItem;
    i: Integer;
begin
 Result := TACRKeyPath.Create;
 try
   for i := 0 to FItems.Count-1 do
    if (PACRKeyPathCacheItem(FItems.Items[i])^.SessionID = SessionID) then
     begin
      CacheItem := PACRKeyPathCacheItem(FItems.Items[i]);
      if (Clear) or
         ((PACRKeyPathCacheItem(FItems.Items[i])^.RecordID.PageNo <> RecordID.PageNo)
           or
          (PACRKeyPathCacheItem(FItems.Items[i])^.RecordID.PageItemNo <> RecordID.PageItemNo))  then
       begin
        CacheItem.KeyPath.Clear;
        Exit;
       end;
      Exit;
     end;
   New(CacheItem);
   CacheItem.SessionID := SessionID;
   CacheItem.RecordID := RecordID;
   CacheItem.KeyPath := TACRKeyPath.Create;
   FItems.Add(CacheItem);
 finally
   Result.Assign(CacheItem^.KeyPath);
 end;
end; // GetKeyPath


//------------------------------------------------------------------------------
// set key path
//------------------------------------------------------------------------------
procedure TACRKeyPathCache.SetKeyPath(SessionID: TACRSessionID; RecordID: TACRRecordID; KeyPath: TACRKeyPath);
var CacheItem: PACRKeyPathCacheItem;
    i: Integer;
begin
   for i := 0 to FItems.Count-1 do
    if (PACRKeyPathCacheItem(FItems.Items[i])^.SessionID = SessionID) then
     begin
      CacheItem := PACRKeyPathCacheItem(FItems.Items[i]);
      CacheItem^.RecordID := RecordID;
      CacheItem^.KeyPath.Assign(KeyPath);
      Exit;
     end;
   raise EACRException.Create(11630,ErrorLIndexErrorCannotFindKeyPath,[SessionID,RecordID.PageNo,RecordID.PageItemNo,FItems.Count]);
end;

{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
//
// TACRKeyPath
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRKeyPath.Create;
begin
//aaIncCounter(counter7);
//aaStartTime(time6);
  Clear;
//aaStopTime(time6);
end;// Create


//------------------------------------------------------------------------------
// Clear
//------------------------------------------------------------------------------
procedure TACRKeyPath.Clear;
begin
  Count := 0;
  ItemNo := 0;
end;// Clear


//------------------------------------------------------------------------------
// AddItem
//------------------------------------------------------------------------------
procedure TACRKeyPath.AddItem(aPageNo: TACRPageNo; aEntryNo, aEntryCount: Integer);
begin
//aaIncCounter(counter6);
//aaStartTime(time3);
  if (ItemNo < 0) or (ItemNo > ACRMaxKeyPathItemNo) then
   raise EACRException.Create(11660,ErrorLInvalidKeyPathItemNo,[ItemNo,aPageNo,aEntryNo,aEntryCount]);
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
procedure TACRKeyPath.DeleteLastItem;
begin
  Dec(ItemNo);
  Dec(Count);
end;// DeleteLastItem


//------------------------------------------------------------------------------
// IncLevel
//------------------------------------------------------------------------------
procedure TACRKeyPath.IncLevel;
begin
  Inc(ItemNo);
end;// IncLevel


//------------------------------------------------------------------------------
// DecLevel
//------------------------------------------------------------------------------
procedure TACRKeyPath.DecLevel;
begin
  Dec(ItemNo);
end;// DecLevel

//------------------------------------------------------------------------------
// GetCurrentPageNo
//------------------------------------------------------------------------------
function TACRKeyPath.GetCurrentPageNo: TACRPageNo;
begin
  Result := Items[ItemNo].PageNo;
end;// GetCurrentPageNo


//------------------------------------------------------------------------------
// SetCurrentPageNo
//------------------------------------------------------------------------------
procedure TACRKeyPath.SetCurrentPageNo(Value: TACRPageNo);
begin
  Items[ItemNo].PageNo := Value;
end;// SetCurrentPageNo


//------------------------------------------------------------------------------
// PageExists
//------------------------------------------------------------------------------
function TACRKeyPath.PageExists(aPageNo: TACRPageNo): Boolean;
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
function TACRKeyPath.Compare(aKeyPath: TACRKeyPath): Integer;
var
  i: Integer;
begin
  if (Count <> aKeyPath.Count) then
   raise EACRException.Create(20051, ErrorAInvalidIndexKeyPath);
  Result := 0;
  for i := 0 to Count-1 do
   begin
     if (Items[i].PageNo <> aKeyPath.Items[i].PageNo) then
      raise EACRException.Create(20052, ErrorAInvalidIndexKeyPath);
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
function TACRKeyPath.GetApproxRecNoInPercents: double;
var
  i:               Integer;
  ApproxRecNo:     TACRRecordNo;
  ApproxRecCount:  TACRRecordNo;
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
procedure TACRKeyPath.Assign(Source: TACRKeyPath);
var i: Integer;
begin
  Count := Source.Count;
  ItemNo := Source.ItemNo;
  for i := 0 to Source.Count-1 do
   Items[i] := Source.Items[i];
end; // Assign


////////////////////////////////////////////////////////////////////////////////
//
// TACRBTreeKeyRef
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// get count of key parts
//------------------------------------------------------------------------------
function TACRBTreeKeyRef.GetPartCount: Integer;
begin
  Result := Length(Parts);
end;// GetPartCount


//------------------------------------------------------------------------------
// set size of array
//------------------------------------------------------------------------------
procedure TACRBTreeKeyRef.SetPartCount(Value: Integer);
begin
  SetLength(Parts, Value);
end;// SetPartCount


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRBTreeKeyRef.Create;
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
procedure TACRBTreeKeyRef.Assign(IndexDef: TACRIndexDef; aTableData: Pointer);
var
  i: Integer;
  OffsetInKeyBuffer: Integer;
  TableData: TACRTableData;
  FieldDef: TACRFieldDef;
begin
  TableData := TACRTableData(aTableData);
  PartCount := IndexDef.ColumnCount;
  FCompareFieldCount := PartCount;
  OffsetInKeyBuffer := 0;
  FKeySize := 0;
  if (TableData.FieldManager = nil) then
    raise EACRException.Create(20044, ErrorANilPointer);
  if (TableData.FieldManager.FieldDefs = nil) then
    raise EACRException.Create(20045, ErrorANilPointer);
  for i := 0 to IndexDef.ColumnCount-1 do
   begin
    Parts[i].OffsetInKeyBuffer := OffsetInKeyBuffer;
    FieldDef := TableData.FieldManager.FieldDefs.GetFieldDefByName(
                         IndexDef.Columns[i].FieldName
                                                                   );
    if (FieldDef = nil) then
     raise EACRException.Create(20043, ErrorACannotFindIndexField,
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
function TACRBTreeKeyRef.AllocKeyBuffer: PAnsiChar;
begin
  Result := MemoryManager.AllocMem(FKeySize);
end;// AllocKeyBuffer


//------------------------------------------------------------------------------
// free key buffer
//------------------------------------------------------------------------------
procedure TACRBTreeKeyRef.FreeAndNilKeyBuffer(var Buffer: PAnsiChar);
begin
  MemoryManager.FreeAndNilMem(Buffer);
end;// FreeAndNilKeyBuffer


//------------------------------------------------------------------------------
// MakeKeyFromRecordBuffer
//------------------------------------------------------------------------------
procedure TACRBTreeKeyRef.MakeKeyFromRecordBuffer(RecordBuffer: PAnsiChar; KeyBuffer: PAnsiChar);
var i: Integer;
{$I ACR_check_null_flag_var.inc}
begin
{$IFDEF DEBUG_TRACE_TACRBTreeKeyRef_MakeKeyFromRecordBuffer}
aaWriteToLog('TACRBTreeKeyRef.MakeKeyFromRecordBuffer '+#13#10+
'PartCount = '+IntTostr(PartCount));
{$ENDIF}
  CHECK_NULL_FLAG_NullFlags := RecordBuffer;
  for i := 0 to PartCount-1 do
   begin
    CHECK_NULL_FLAG_BitNo := Parts[i].FieldNo;
    {$I ACR_check_null_flag.inc}
    if (CHECK_NULL_FLAG_Result) then
     begin
{$IFDEF DEBUG_TRACE_TACRBTreeKeyRef_MakeKeyFromRecordBuffer}
aaWriteToLog('TACRBTreeKeyRef.MakeKeyFromRecordBuffer '+#13#10+
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
{$IFDEF DEBUG_TRACE_TACRBTreeKeyRef_MakeKeyFromRecordBuffer}
aaWriteToLog('TACRBTreeKeyRef.MakeKeyFromRecordBuffer '+#13#10+
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
function TACRBTreeKeyRef.CompareKeys(KeyBuffer1, KeyBuffer2: PAnsiChar): Integer;
var
  i: Integer;
  {$I ACR_cmp_buffers_var.inc}
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
    {$I ACR_cmp_buffers.inc}
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
function TACRBTreeKeyRef.CompareReferences(Reference1, Reference2: PAnsiChar; Size: Integer): Boolean;
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
// TACRBTreePageController
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// get IsRoot
//------------------------------------------------------------------------------
function TACRBTreePage.GetIsRoot: Boolean;
begin
  Result := PACRBTreePageHeader(PageBuffer)^.IsRoot;
end;// GetIsRoot


//------------------------------------------------------------------------------
// set IsRoot
//------------------------------------------------------------------------------
procedure TACRBTreePage.SetIsRoot(Value: Boolean);
begin
  PACRBTreePageHeader(PageBuffer)^.IsRoot := Value;
end;// SetIsRoot


//------------------------------------------------------------------------------
// get IsLeaf
//------------------------------------------------------------------------------
function TACRBTreePage.GetIsLeaf: Boolean;
begin
  Result := PACRBTreePageHeader(PageBuffer)^.IsLeaf;
end;// GetIsLeaf


//------------------------------------------------------------------------------
// set IsLeaf
//------------------------------------------------------------------------------
procedure TACRBTreePage.SetIsLeaf(Value: Boolean);
begin
  PACRBTreePageHeader(PageBuffer)^.IsLeaf := Value;
end;// SetIsLeaf


//------------------------------------------------------------------------------
// get Left page No
//------------------------------------------------------------------------------
function TACRBTreePage.GetLeftPageNo: TACRPageNo;
begin
  Result := PACRBTreePageHeader(PageBuffer)^.LeftPageNo;
end;// GetLeftPageNo


//------------------------------------------------------------------------------
// set LeftPageNo
//------------------------------------------------------------------------------
procedure TACRBTreePage.SetLeftPageNo(Value: TACRPageNo);
begin
  PACRBTreePageHeader(PageBuffer)^.LeftPageNo := Value;
end;// SetLeft


//------------------------------------------------------------------------------
// get right PageNo
//------------------------------------------------------------------------------
function TACRBTreePage.GetRightPageNo: TACRPageNo;
begin
  Result := PACRBTreePageHeader(PageBuffer)^.RightPageNo;
end;// GetRightPageNo


//------------------------------------------------------------------------------
// set Right PageNo
//------------------------------------------------------------------------------
procedure TACRBTreePage.SetRightPageNo(Value: TACRPageNo);
begin
  PACRBTreePageHeader(PageBuffer)^.RightPageNo := Value;
end;// SetRightPageNo


//------------------------------------------------------------------------------
// get (page has keys or only references?)
//------------------------------------------------------------------------------
function TACRBTreePage.GetHasKeys: Boolean;
begin
  Result := PACRBTreePageHeader(PageBuffer)^.HasKeys;
end;// GetHasKeys


//------------------------------------------------------------------------------
// set HasKeys
//------------------------------------------------------------------------------
procedure TACRBTreePage.SetHasKeys(Value: Boolean);
begin
  PACRBTreePageHeader(PageBuffer)^.HasKeys := Value;
end;// SetHasKeys


//------------------------------------------------------------------------------
// get (key has suffix?)
//------------------------------------------------------------------------------
function TACRBTreePage.GetHasSuffixes: Boolean;
begin
  Result := PACRBTreePageHeader(PageBuffer)^.HasSuffixes;
end;// GetHasSuffixes


//------------------------------------------------------------------------------
// set KeyHasSuffix
//------------------------------------------------------------------------------
procedure TACRBTreePage.SetHasSuffixes(Value: Boolean);
begin
  PACRBTreePageHeader(PageBuffer)^.HasSuffixes := Value;
end;// SetHasSuffixes


//------------------------------------------------------------------------------
// get key prefix size
//------------------------------------------------------------------------------
function TACRBTreePage.GetKeyPrefixSize: Word;
begin
  Result := PACRBTreePageHeader(PageBuffer)^.KeyPrefixSize;
end;// GetKeyPrefixSize


//------------------------------------------------------------------------------
// set key prefix size
//------------------------------------------------------------------------------
procedure TACRBTreePage.SetKeyPrefixSize(Value: Word);
begin
  PACRBTreePageHeader(PageBuffer)^.KeyPrefixSize := Value;
end;// SetKeyPrefixSize


//------------------------------------------------------------------------------
// get entry count
//------------------------------------------------------------------------------
function TACRBTreePage.GetEntryCount: Integer;
begin
  Result := PACRBTreePageHeader(PageBuffer)^.EntryCount;
end;// GetEntryCount


//------------------------------------------------------------------------------
// set Entry count
//------------------------------------------------------------------------------
procedure TACRBTreePage.SetEntryCount(Value: Integer);
begin
  PACRBTreePageHeader(PageBuffer)^.EntryCount := Value;
end;// SetEntryCount


//------------------------------------------------------------------------------
// get page prefix size
//------------------------------------------------------------------------------
function TACRBTreePage.GetPagePrefixSize: Word;
begin
  Result := PACRBTreePageHeader(PageBuffer)^.PagePrefixSize;
end;// GetPagePrefixSize


//------------------------------------------------------------------------------
// set page prefix size
//------------------------------------------------------------------------------
procedure TACRBTreePage.SetPagePrefixSize(Value: Word);
begin
  PACRBTreePageHeader(PageBuffer)^.PagePrefixSize := Value;
end;// GetPagePrefixSize


//------------------------------------------------------------------------------
// GetEntrySize
//------------------------------------------------------------------------------
function TACRBTreePage.GetEntrySize: Integer;
begin
  Result := KeyPrefixSize + ReferenceSize;
  if (HasSuffixes) then
    Result := Result + SuffixPtrSize;
end;// GetEntrySize


//------------------------------------------------------------------------------
// GetReferenceSize
//------------------------------------------------------------------------------
function TACRBTreePage.GetReferenceSize: Integer;
begin
  if (IsLeaf) then
   Result := FKeyRef.ReferenceSize
  else
   Result := sizeof(TACRPageNo);
end;// GetReferenceSize


//------------------------------------------------------------------------------
// GetEntriesOffset
//------------------------------------------------------------------------------
function TACRBTreePage.GetEntriesOffset: Integer;
begin
  Result := sizeof(TACRBTreePageHeader) + PagePrefixSize;
end;// GetEntriesOffset


//------------------------------------------------------------------------------
// GetSuffixPtrSize
//------------------------------------------------------------------------------
function TACRBTreePage.GetSuffixPtrSize: Integer;
begin
  Result := sizeof(TACRRecordID);
end;// GetSuffixPtrSize


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRBTreePage.Create(BTreeIndex: TACRBTreeIndex; Page: TACRPage);
begin
  inherited Create(Page);
  LBTreeIndex := BTreeIndex;
  FKeyRef := BTreeIndex.KeyRef;
  FLeafController := TACRBTreeLeafController.Create(Self,LBTreeIndex.LTableData);
  FNodeController := TACRBTreeNodeController.Create(Self,LBTreeIndex.LTableData);
end;// Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TACRBTreePage.Destroy;
begin
  FLeafController.Free;
  FNodeController.Free;
  inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// init data
//------------------------------------------------------------------------------
procedure TACRBTreePage.Init;
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
procedure TACRBTreePage.InitAsRoot;
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
procedure TACRBTreePage.CopyFrom(Source: TACRBTreePage; StartNo, Count: Integer);
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
procedure TACRBTreePage.AppendFrom(Source: TACRBTreePage; StartNo, Count: Integer);
begin
  Move((Source.PageBuffer+Source.EntriesOffset+StartNo*Source.EntrySize)^,
       (PageBuffer+EntriesOffset+EntryCount*EntrySize)^,
       Source.EntrySize*Count);
  EntryCount := EntryCount + Count;
end;// AppendFrom


//------------------------------------------------------------------------------
// InsertFrom
//------------------------------------------------------------------------------
procedure TACRBTreePage.InsertFrom(Source: TACRBTreePage; StartNo, Count: Integer);
begin
  ACRMove(
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
procedure TACRBTreePage.InsertLeafEntry(SessionID: TACRSessionID; Key, Reference: PAnsiChar; KeyPath: TACRKeyPath);
begin
  if (IsLeaf) then
    FLeafController.InsertLeafEntry(SessionID, Key, Reference, KeyPath)
  else
    FNodeController.InsertLeafEntry(SessionID, Key, Reference, KeyPath);
end;// InsertLeafEntry


//------------------------------------------------------------------------------
// InsertNodeEntry
//------------------------------------------------------------------------------
procedure TACRBTreePage.InsertNodeEntry(SessionID: TACRSessionID; Key, Reference: PAnsiChar; KeyPath: TACRKeyPath);
begin
  if (IsLeaf) then
    raise EACRException.Create(20020, ErrorABTreeInvalidCall)
  else
    FNodeController.InsertNodeEntry(SessionID, Key, Reference, KeyPath);
end;// InsertNodeEntry


//------------------------------------------------------------------------------
// DeleteLeafEntry
//------------------------------------------------------------------------------
function TACRBTreePage.DeleteLeafEntry(SessionID: TACRSessionID; Key, Reference: PAnsiChar; KeyPath: TACRKeyPath): Boolean;
begin
  if (IsLeaf) then
    Result := FLeafController.DeleteLeafEntry(SessionID, Key, Reference, KeyPath)
  else
    Result := FNodeController.DeleteLeafEntry(SessionID, Key, Reference, KeyPath);
end;// DeleteLeafEntry


//------------------------------------------------------------------------------
// DeleteNodeEntry
//------------------------------------------------------------------------------
procedure TACRBTreePage.DeleteNodeEntry(
                  SessionID:     TACRSessionID;
                  KeyPath:       TACRKeyPath;
                  MergeWithLeft: Boolean
                        );
begin
  if (IsLeaf) then
    raise EACRException.Create(20024, ErrorABTreeInvalidCall)
  else
    FNodeController.DeleteNodeEntry(SessionID, KeyPath, MergeWithLeft);
end;// DeleteNodeEntry


//------------------------------------------------------------------------------
// FindEntry
//------------------------------------------------------------------------------
function TACRBTreePage.FindEntry(
                          SessionID: TACRSessionID;
                          Key:       PAnsiChar;
                          Reference: PAnsiChar;
                          Position:  TACRKeyPath
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
function TACRBTreePage.GetFirstPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean;
begin
  if (IsLeaf) then
    Result := FLeafController.GetFirstPosition(SessionID, Position)
  else
    Result := FNodeController.GetFirstPosition(SessionID, Position);
end;// GetFirstPosition


//------------------------------------------------------------------------------
// GetLastPosition
//------------------------------------------------------------------------------
function TACRBTreePage.GetLastPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean;
begin
  if (IsLeaf) then
    Result := FLeafController.GetLastPosition(SessionID, Position)
  else
    Result := FNodeController.GetLastPosition(SessionID, Position);
end;// Last


//------------------------------------------------------------------------------
// FindByCondition
//------------------------------------------------------------------------------
function TACRBTreePage.FindByCondition(
                              SessionID: TACRSessionID;
                              First:     Boolean; // if False => Last
                              Key:       PAnsiChar;
                              Operator:  TACRSearchCondition;
                              Position:  TACRKeyPath
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
procedure TACRBTreePage.FreeAllPages(SessionID: TACRSessionID; RootPageNo: TACRPageNo);
begin
  if (IsLeaf) then
    FLeafController.FreeAllPages(SessionID,RootPageNo)
  else
    FNodeController.FreeAllPages(SessionID,RootPageNo);
end;// FreeAllPages


//------------------------------------------------------------------------------
// CheckIntegrity
//------------------------------------------------------------------------------
procedure TACRBTreePage.CheckIntegrity(SessionID: TACRSessionID; KeyPath: TACRKeyPath);
begin
  if (IsLeaf) then
    FLeafController.CheckIntegrity(SessionID, KeyPath)
  else
    FNodeController.CheckIntegrity(SessionID, KeyPath);
end;// CheckIntegrity


//------------------------------------------------------------------------------
// GetPKey
//------------------------------------------------------------------------------
function TACRBTreePage.GetPKey(KeyPosition: Integer): PAnsiChar;
begin
  Result := PageBuffer+EntriesOffset+KeyPosition*EntrySize;
end;// GetPKey


//------------------------------------------------------------------------------
// GetPReference
//------------------------------------------------------------------------------
function TACRBTreePage.GetPReference(RefPosition: Integer): PAnsiChar;
begin
  Result := GetPKey(RefPosition) + KeyPrefixSize;
end;// GetPReference


//------------------------------------------------------------------------------
// GetFirstKey
//------------------------------------------------------------------------------
procedure TACRBTreePage.GetFirstKey(SessionID: TACRSessionID; Key: PAnsiChar);
begin
  if (IsLeaf) then
    FLeafController.GetFirstKey(SessionID, Key)
  else
    FNodeController.GetFirstKey(SessionID, Key);
end;// GetFirstKey


//------------------------------------------------------------------------------
// GetLastKey
//------------------------------------------------------------------------------
procedure TACRBTreePage.GetLastKey(SessionID: TACRSessionID; Key: PAnsiChar);
begin
  if (IsLeaf) then
    FLeafController.GetLastKey(SessionID, Key)
  else
    FNodeController.GetLastKey(SessionID, Key);
end;// GetLastKey


//------------------------------------------------------------------------------
// UpdateKey
//------------------------------------------------------------------------------
procedure TACRBTreePage.UpdateKey(Position: Integer; Key: PAnsiChar);
begin
  Move(Key^, GetPKey(Position)^, KeyPrefixSize);
end;// UpdateKey





////////////////////////////////////////////////////////////////////////////////
//
// TACRBTreePageController
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// GetKeyRef
//------------------------------------------------------------------------------
function TACRBTreePageController.GetKeyRef: TACRBTreeKeyRef;
begin
  Result := FPage.KeyRef;
end;// GetKeyRef


//------------------------------------------------------------------------------
// Can Add Entry?
//------------------------------------------------------------------------------
function TACRBTreePageController.CanAddEntry: Boolean;
begin
  if (FPage.PageSize >= sizeof(TACRBTreePageHeader) + FPage.PagePrefixSize +
                       (FPage.EntryCount+1)*FPage.EntrySize) then
    Result := True
  else
    Result := False;
end;// CanAddEntry


//------------------------------------------------------------------------------
// IsOverflow
//------------------------------------------------------------------------------
function TACRBTreePageController.IsOverflow: Boolean;
begin
  if (FPage.PageSize < sizeof(TACRBTreePageHeader) + FPage.PagePrefixSize +
                       FPage.EntryCount*FPage.EntrySize) then
    Result := True
  else
    Result := False;
end;// IsOverflow


//------------------------------------------------------------------------------
// CanUnderflow
//------------------------------------------------------------------------------
function TACRBTreePageController.CanUnderflow: Boolean;
begin
  if ((not FPage.IsRoot) and
      ((FPage.PageSize - sizeof(TACRBTreePageHeader) - FPage.PagePrefixSize) div 2 >
                       FPage.EntryCount*FPage.EntrySize)) then
    Result := True
  else
    Result := False;
end;// CanUnderflow


//------------------------------------------------------------------------------
// CanMergeWithPage
//------------------------------------------------------------------------------
function TACRBTreePageController.CanMergeWithPage(Page: TACRBTreePage): Boolean;
begin
  Result := (Page.PageSize >
             FPage.EntriesOffset + (FPage.EntryCount+Page.EntryCount)*FPage.EntrySize);
end;// CanMergeWithPage


//------------------------------------------------------------------------------
// EnlargePageBuffer
//------------------------------------------------------------------------------
procedure TACRBTreePageController.EnlargePageBuffer;
begin
  FPage.EnlargePageBuffer(FPage.PageSize + FPage.EntrySize);
end;// EnlargePageBuffer


//------------------------------------------------------------------------------
// Compare Keys
//------------------------------------------------------------------------------
function TACRBTreePageController.CompareKeys(Key1: PAnsiChar; Key2Index: Word): Integer;
begin
  Result := KeyRef.CompareKeys(Key1, GetPKey(Key2Index));
end;// CompareKeys


//------------------------------------------------------------------------------
// Compare Keys
//------------------------------------------------------------------------------
function TACRBTreePageController.CompareKeys(Key1, Key2: PAnsiChar; KeyRef: TACRBTreeKeyRef): Integer;
begin
  Result := KeyRef.CompareKeys(Key1, Key2);
end; // CompareKeys


//------------------------------------------------------------------------------
// CompareReferences
//------------------------------------------------------------------------------
function TACRBTreePageController.CompareReferences(
                             Reference1: PAnsiChar; Reference2Index: Word): Boolean;
begin
  Result := KeyRef.CompareReferences(Reference1,
                                     GetPReference(Reference2Index),
                                     FPage.ReferenceSize);
end;// CompareReferences


//------------------------------------------------------------------------------
// get key position for insert (binary search)
//------------------------------------------------------------------------------
function TACRBTreePageController.GetKeyPosition(
                       Key: PAnsiChar;
                       StartPosition: Integer = 0;
                       PositionType: PACRKeyPathPosition = nil;
                       SearchType: TACRKeySearchType = kstAny
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
procedure TACRBTreePageController.InsertEntry(
                  Key, Reference: PAnsiChar;
                  Position: Integer
                                              );
begin
  if (not CanAddEntry ) then
   EnlargePageBuffer;
  ACRMove(
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
procedure TACRBTreePageController.DeleteEntry(Position: Integer);
begin
  if (FPage.EntryCount > 0) then
   begin
    ACRMove(
            GetPKey(Position+1)^,
            GetPKey(Position)^,
            (FPage.EntryCount-1 - Position) * FPage.EntrySize
           );
    FPage.EntryCount := FPage.EntryCount - 1;
   end
  else
   raise EACRException.Create(20025, ErrorABTreeEmptyPage);
end;// DeleteEntry


//------------------------------------------------------------------------------
// RootSplit
//------------------------------------------------------------------------------
procedure TACRBTreePageController.RootSplit(SessionID: TACRSessionID; KeyPath: TACRKeyPath);
var
  MiddleEntryNo: Integer;
  LeftPage, RightPage: TACRBTreePage;
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
procedure TACRBTreePageController.NonRootSplit(SessionID: TACRSessionID; KeyPath: TACRKeyPath);
var
  MiddleEntryNo: Integer;
  ParentPage, NewRightPage, PrevRightPage: TACRBTreePage;
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
function TACRBTreePageController.TryMergeWithPage(
                        SessionID:   TACRSessionID;
                        MergePageNo: TACRPageNo;
                        KeyPath:     TACRKeyPath
                                                  ): Boolean;
var
  MergePage: TACRBTreePage;
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
function TACRBTreePageController.TryMerge(SessionID: TACRSessionID; KeyPath: TACRKeyPath): Boolean;
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
procedure TACRBTreePageController.MergeWithLeftPage(
                        SessionID: TACRSessionID;
                        LeftPage: TACRBTreePage;
                        KeyPath: TACRKeyPath
                                );
var
  ParentPage: TACRBTreePage;
  RightPage:  TACRBTreePage;
  ChildPage:  TACRBTreePage;
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
procedure TACRBTreePageController.MergeWithRightPage(
                        SessionID: TACRSessionID;
                        RightPage: TACRBTreePage;
                        KeyPath: TACRKeyPath
                                );
var
  ParentPage: TACRBTreePage;
  LeftPage:  TACRBTreePage;
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
constructor TACRBTreePageController.Create(
                        aPage:        TACRBTreePage;
                        aTableData:   TACRTableData
                       );
begin
  FPage := aPage;
  LTableData := aTableData;
end;// Create


//------------------------------------------------------------------------------
// GetPKey
//------------------------------------------------------------------------------
function TACRBTreePageController.GetPKey(KeyPosition: Integer): PAnsiChar;
begin
  Result := FPage.GetPKey(KeyPosition);
end;// GetPKey


//------------------------------------------------------------------------------
// GetPReference
//------------------------------------------------------------------------------
function TACRBTreePageController.GetPReference(RefPosition: Integer): PAnsiChar;
begin
  Result := FPage.GetPReference(RefPosition);
end;// GetPReference


//------------------------------------------------------------------------------
// Split
//------------------------------------------------------------------------------
procedure TACRBTreePageController.Split(SessionID: TACRSessionID; KeyPath: TACRKeyPath);
begin
  if (FPage.IsRoot) then
   RootSplit(SessionID, KeyPath)
  else
   NonRootSplit(SessionID, KeyPath);
end;// Split


//------------------------------------------------------------------------------
// KeyMatch
//------------------------------------------------------------------------------
function TACRBTreePageController.KeyMatch(
                          KeyPosition:     Integer;
                          SearchKey:       PAnsiChar;
                          SearchCondition: TACRSearchCondition
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
// TACRBTreeLeafController
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// FindEntry
//------------------------------------------------------------------------------
function TACRBTreeLeafController.FindEntryOnPage(
                                           Key, Reference: PAnsiChar;
                                           var EntryNo: Integer
                                          ): Boolean;
var
  Position: Integer;
  PositionType: TACRKeyPathPosition;
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
function TACRBTreeLeafController.FindFirstByCondition(
                              Key:       PAnsiChar;
                              Operator:  TACRSearchCondition;
                              Position:  TACRKeyPath
                            ): Boolean;
var
  PositionType: TACRKeyPathPosition;
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
function TACRBTreeLeafController.FindLastByCondition(
                              Key:       PAnsiChar;
                              Operator:  TACRSearchCondition;
                              Position:  TACRKeyPath
                            ): Boolean;
var
  PositionType: TACRKeyPathPosition;
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
procedure TACRBTreeLeafController.InsertLeafEntry(
                     SessionID: TACRSessionID;
                     Key, Reference: PAnsiChar;
                     KeyPath: TACRKeyPath
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
function TACRBTreeLeafController.DeleteLeafEntry(
                      SessionID: TACRSessionID;
                      Key, Reference: PAnsiChar;
                      KeyPath: TACRKeyPath
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
procedure TACRBTreeLeafController.GetFirstKey(SessionID: TACRSessionID; Key: PAnsiChar);
begin
  Move(GetPKey(0)^, Key^, FPage.KeyPrefixSize);
end;// GetFirstKey


//------------------------------------------------------------------------------
// GetLastKey
//------------------------------------------------------------------------------
procedure TACRBTreeLeafController.GetLastKey(SessionID: TACRSessionID; Key: PAnsiChar);
begin
  Move(GetPKey(FPage.EntryCount-1)^, Key^, FPage.KeyPrefixSize);
end;// GetLastKey


//------------------------------------------------------------------------------
// FindEntry
//------------------------------------------------------------------------------
function TACRBTreeLeafController.FindEntry(
                    SessionID: TACRSessionID;
                    Key:       PAnsiChar;
                    Reference: PAnsiChar;
                    Position:  TACRKeyPath
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
function TACRBTreeLeafController.GetFirstPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean;
begin
  Result := (FPage.EntryCount > 0);
  if (Result) then
    Position.AddItem(FPage.PageNo, 0, FPage.EntryCount);
end;// GetFirstPosition


//------------------------------------------------------------------------------
// GetLastPosition
//------------------------------------------------------------------------------
function TACRBTreeLeafController.GetLastPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean;
begin
  Result := (FPage.EntryCount > 0);
  if (Result) then
   Position.AddItem(FPage.PageNo, FPage.EntryCount-1, FPage.EntryCount);
end;// GetLastPosition


//------------------------------------------------------------------------------
// FindByCondition
//------------------------------------------------------------------------------
function TACRBTreeLeafController.FindByCondition(
                        SessionID: TACRSessionID;
                        First:     Boolean; // if False => Last
                        Key:       PAnsiChar;
                        Operator:  TACRSearchCondition;
                        Position:  TACRKeyPath
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
procedure TACRBTreeLeafController.FreeAllPages(SessionID: TACRSessionID; RootPageNo: TACRPageNo);
begin
 if (FPage.PageNo <> RootPageNo) then
  FPage.LBTreeIndex.RemoveIndexPage(SessionID, FPage.PageNo);
end;// FreeAllPages


//------------------------------------------------------------------------------
// CheckIntegrity
//------------------------------------------------------------------------------
procedure TACRBTreeLeafController.CheckIntegrity(SessionID: TACRSessionID; KeyPath: TACRKeyPath);
var
  i: Integer;
begin
  for i := 0 to FPage.EntryCount-2 do
   begin
    if (CompareKeys(GetPKey(i), i+1) > 0) then
    if (CompareKeys(GetPKey(i), i+1) > 0) then
     raise EACRException.Create(20028 ,ErrorAIndexIntegrityViolated, [FPage.PageNo, i]);
   end;
end;// CheckIntegrity



////////////////////////////////////////////////////////////////////////////////
//
// TACRBTreeNodeController
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// FindByConditionOnOneOfPages
//------------------------------------------------------------------------------
function TACRBTreeNodeController.FindByConditionOnOneOfPages(
                                    SessionID:    TACRSessionID;
                                    First:        Boolean; // if False => Last
                                    StartEntryNo: Integer;
                                    EndEntryNo:   Integer;
                                    Key:          PAnsiChar;
                                    Operator:     TACRSearchCondition;
                                    Position:     TACRKeyPath
                                                      ): Boolean;
var
  Pos, Step, MinPos, MaxPos: Integer;
  ChildPage:                 TACRBTreePage;
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
      ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PACRPageNo(GetPReference(Pos))^);
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
function TACRBTreeNodeController.FindEntryOnOneOfPages(
                                    SessionID:    TACRSessionID;
                                    StartEntryNo: Integer;
                                    EndEntryNo:   Integer;
                                    Key:          PAnsiChar;
                                    Reference:    PAnsiChar;
                                    Position:     TACRKeyPath
                                  ): Boolean;
var
  Pos, Step, MinPos, MaxPos: Integer;
  ChildPage:                 TACRBTreePage;
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
      ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PACRPageNo(GetPReference(Pos))^);
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
procedure TACRBTreeNodeController.GetChildPagesToCheck(
                          Key:               PAnsiChar;
                          SearchCondition:   TACRSearchCondition;
                          var StartEntryNo:  Integer;
                          var EndEntryNo:    Integer
                                                      );
var
  PositionType: TACRKeyPathPosition;
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
procedure TACRBTreeNodeController.DecreaseTreeDepth(SessionID: TACRSessionID);
var
  ChildPage: TACRBTreePage;
begin
  ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PACRPageNo(GetPReference(0))^);
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
procedure TACRBTreeNodeController.InsertLeafEntry(
                        SessionID: TACRSessionID;
                        Key, Reference: PAnsiChar;
                        KeyPath: TACRKeyPath
                                               );
var
  PositionType: TACRKeyPathPosition;
  Pos:          Word;
  ChildPage:    TACRBTreePage;
begin
  Pos := GetKeyPosition(Key, 1, @PositionType);
  if (PositionType = kppBeforeKey) then
   Dec(Pos);
  KeyPath.AddItem(FPage.PageNo, Pos, FPage.EntryCount);
  ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PACRPageNo(GetPReference(Pos))^);
  try
   ChildPage.InsertLeafEntry(SessionID, Key, Reference, KeyPath);
  finally
   FPage.LBTreeIndex.PutIndexPage(ChildPage);
  end;
end;// InsertLeafEntry


//------------------------------------------------------------------------------
// InsertNodeEntry
//------------------------------------------------------------------------------
procedure TACRBTreeNodeController.InsertNodeEntry(
                        SessionID: TACRSessionID;
                        Key, Reference: PAnsiChar;
                        KeyPath: TACRKeyPath
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
function TACRBTreeNodeController.DeleteLeafEntry(
                        SessionID: TACRSessionID;
                        Key, Reference: PAnsiChar;
                        KeyPath: TACRKeyPath
                                                 ): Boolean;
var
  StartPosition, EndPosition, Pos: Integer;
  ChildPage: TACRBTreePage;
begin
  Result := False;
  GetChildPagesToCheck(Key, scEqual, StartPosition, EndPosition);
  for Pos := StartPosition to EndPosition do
    begin
      ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PACRPageNo(GetPReference(Pos))^);
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
procedure TACRBTreeNodeController.DeleteNodeEntry(
                        SessionID:     TACRSessionID;
                        KeyPath:       TACRKeyPath;
                        MergeWithLeft: Boolean
                                                );
var
  ParentPage: TACRBTreePage;
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
procedure TACRBTreeNodeController.GetFirstKey(SessionID: TACRSessionID; Key: PAnsiChar);
var
  ChildPage: TACRBTreePage;
begin
  ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PACRPageNo(GetPReference(0))^);
  ChildPage.GetFirstKey(SessionID, Key);
  FPage.LBTreeIndex.PutIndexPage(ChildPage);
end;// GetFirstKey


//------------------------------------------------------------------------------
// GetLastKey
//------------------------------------------------------------------------------
procedure TACRBTreeNodeController.GetLastKey(SessionID: TACRSessionID; Key: PAnsiChar);
var
  ChildPage: TACRBTreePage;
begin
  ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PACRPageNo(GetPReference(FPage.EntryCount-1))^);
  ChildPage.GetLastKey(SessionID, Key);
  FPage.LBTreeIndex.PutIndexPage(ChildPage);
end;// GetLastKey


//------------------------------------------------------------------------------
// FindEntry
//------------------------------------------------------------------------------
function TACRBTreeNodeController.FindEntry(
                          SessionID: TACRSessionID;
                          Key:       PAnsiChar;
                          Reference: PAnsiChar;
                          Position:  TACRKeyPath
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
function TACRBTreeNodeController.GetFirstPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean;
var
  ChildPage: TACRBTreePage;
begin
  ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PACRPageNo(GetPReference(0))^);
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
function TACRBTreeNodeController.GetLastPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean;
var
  ChildPage: TACRBTreePage;
begin
  ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PACRPageNo(GetPReference(FPage.EntryCount-1))^);
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
function TACRBTreeNodeController.FindByCondition(
                              SessionID: TACRSessionID;
                              First:     Boolean; // if False => Last
                              Key:       PAnsiChar;
                              Operator:  TACRSearchCondition;
                              Position:  TACRKeyPath
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
procedure TACRBTreeNodeController.FreeAllPages(SessionID: TACRSessionID; RootPageNo: TACRPageNo = INVALID_PAGE_NO);
var  i:           Integer;
     ChildPage:   TACRBTreePage;
begin
  if (FPage.PageNo <> INVALID_PAGE_NO) then
   begin
     for i := 0 to FPage.EntryCount-1 do
       begin
         ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PACRPageNo(GetPReference(i))^);
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
procedure TACRBTreeNodeController.CheckIntegrity(SessionID: TACRSessionID; KeyPath: TACRKeyPath);
var
  i:         Integer;
  ChildPage: TACRBTreePage;
  KeyBuffer: PAnsiChar;
begin
  KeyBuffer := KeyRef.AllocKeyBuffer;
  try
    for i := 0 to FPage.EntryCount-1 do
     begin
       if (KeyPath.PageExists(FPage.PageNo)) then
        raise EACRException.Create(20032 ,ErrorAIndexIntegrityCircularLinks, [FPage.PageNo, i]);

       KeyPath.AddItem(FPage.PageNo, i, FPage.EntryCount);
       ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PACRPageNo(GetPReference(i))^);
       if (i > 0) then
        if (ChildPage.LeftPageNo <> PACRPageNo(GetPReference(i-1))^) then
         raise EACRException.Create(20033, ErrorAIndexIntegrityLeafLinks, [FPage.PageNo, i]);
       if (i < FPage.EntryCount-1) then
        if (ChildPage.RightPageNo <> PACRPageNo(GetPReference(i+1))^) then
         raise EACRException.Create(20034, ErrorAIndexIntegrityLeafLinks, [FPage.PageNo, i]);

       ChildPage.CheckIntegrity(SessionID, KeyPath);
       FPage.LBTreeIndex.PutIndexPage(ChildPage);
       KeyPath.DeleteLastItem;
     end;
    for i := 1 to FPage.EntryCount-2 do
     begin
       if (CompareKeys(GetPKey(i), i+1) > 0) then
        raise EACRException.Create(20029 ,ErrorAIndexIntegrityViolated, [FPage.PageNo, i]);
       ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PACRPageNo(GetPReference(i-1))^);
       ChildPage.GetLastKey(SessionID, KeyBuffer);
       if (CompareKeys(KeyBuffer, i) > 0) then
        raise EACRException.Create(20030 ,ErrorAIndexIntegrityViolated, [FPage.PageNo, i]);
       FPage.LBTreeIndex.PutIndexPage(ChildPage);
       ChildPage := FPage.LBTreeIndex.GetIndexPage(SessionID, PACRPageNo(GetPReference(i+1))^);
       ChildPage.GetFirstKey(SessionID, KeyBuffer);
       if (CompareKeys(KeyBuffer, i+1) < 0) then
        raise EACRException.Create(20031 ,ErrorAIndexIntegrityViolated, [FPage.PageNo, i]);
       FPage.LBTreeIndex.PutIndexPage(ChildPage);
     end;
  finally
    KeyRef.FreeAndNilKeyBuffer(KeyBuffer);
  end;
end;// CheckIntegrity


////////////////////////////////////////////////////////////////////////////////
//
// TACRBTreeIndex
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TACRBTreeIndex.Lock(WriteMode: Boolean);
begin
 //
end;// Lock


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TACRBTreeIndex.Unlock;
begin
 //{$I ACRThreadSync_4.inc}
end;// Unlock


//------------------------------------------------------------------------------
// AddIndexPage
//------------------------------------------------------------------------------
function TACRBTreeIndex.AddIndexPage(SessionID: TACRSessionID): TACRBTreePage;
var
  Page: TACRPage;
begin
  Page := LTableData.AddPage(SessionID,dbstIndex,LTableData.TableState.TableState,False);
  Result := TACRBTreePage.Create(Self, Page);
end;// AddIndexPage


//------------------------------------------------------------------------------
// RemoveIndexPage
//------------------------------------------------------------------------------
procedure TACRBTreeIndex.RemoveIndexPage(SessionID: TACRSessionID; PageNo: TACRPageNo);
begin
  LTableData.RemovePage(SessionID,PageNo,dbstIndex,LTableData.TableState.TableState);
end;// RemoveIndexPage


//------------------------------------------------------------------------------
// GetIndexPage
//------------------------------------------------------------------------------
function TACRBTreeIndex.GetIndexPage(SessionID: TACRSessionID; PageNo: TACRPageNo): TACRBTreePage;
var
  Page: TACRPage;
begin
  Page := LTableData.GetPage(SessionID,PageNo,dbstIndex,LTableData.TableState.TableState,
      True,False,False);
  Result := TACRBTreePage.Create(Self, Page);
end;// GetIndexPage


//------------------------------------------------------------------------------
// PutIndexPage
//------------------------------------------------------------------------------
procedure TACRBTreeIndex.PutIndexPage(Page: TACRBTreePage);
begin
  LTableData.PutPage(Page.Page);
  Page.Free;
end;// PutIndexPage


//------------------------------------------------------------------------------
// GetRecordID
//------------------------------------------------------------------------------
function TACRBTreeIndex.GetRecordID(SessionID: TACRSessionID; Position: TACRKeyPath): TACRRecordID;
var
  Page: TACRBTreePage;
begin
  if (Position.Count = 0) then
   raise EACRException.Create(20068, ErrorABTreeInvalidPosition);
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
function TACRBTreeIndex.GetFirstPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean;
var
  Page: TACRBTreePage;
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
function TACRBTreeIndex.GetLastPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean;
var
  Page: TACRBTreePage;
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
function TACRBTreeIndex.GetNextPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean;
var
  i:            Integer;
  CurrentLevel: Integer;
  Page:         TACRBTreePage;
  NextPageNo:   TACRPageNo;
begin
  if (Position.Count = 0) then
   raise EACRException.Create(20069, ErrorABTreeInvalidPosition);
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
          raise EACRException.Create(20070, ErrorABTreeInvalidPage);
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
function TACRBTreeIndex.GetPriorPosition(SessionID: TACRSessionID; Position: TACRKeyPath): Boolean;
var
  i:            Integer;
  CurrentLevel: Integer;
  Page:         TACRBTreePage;
  PriorPageNo:   TACRPageNo;
begin
  if (Position.Count = 0) then
   raise EACRException.Create(20069, ErrorABTreeInvalidPosition);
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
          raise EACRException.Create(20071, ErrorABTreeInvalidPage);
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
function TACRBTreeIndex.GetPosition(SessionID: TACRSessionID; Restart, GoForward: Boolean; Position: TACRKeyPath): Boolean;
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
constructor TACRBTreeIndex.Create(aIndexManager: TACRBaseIndexManager);
begin
  inherited Create(aIndexManager);
  FRootPage := nil;
  FKeyRef := nil;
  FThreadSync := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
{$IFDEF INDEX_NAVIGATION_OPTIMIZATION}
  FKeyPathCache := TACRKeyPathCache.Create;
{$ENDIF}
end;// Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRBTreeIndex.Destroy;
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
procedure TACRBTreeIndex.ClearIndexCache(SessionID: TACRSessionID = INVALID_OBJECT_ID);
begin
{$IFDEF INDEX_NAVIGATION_OPTIMIZATION}
  FKeyPathCache.Clear(SessionID);
{$ENDIF}
end; // ClearIndexCache


//------------------------------------------------------------------------------
// create index
//------------------------------------------------------------------------------
procedure TACRBTreeIndex.CreateIndex(Cursor: TACRCursor; aIndexDef: TACRIndexDef);
var
  RecordBuffer:   TACRRecordBuffer;
  TmpCursor:         TACRLocalCursor;
begin
  inherited CreateIndex(Cursor, aIndexDef);

  FKeyRef := TACRBTreeKeyRef.Create;
  FKeyRef.Assign(IndexDef, IndexManager.TableData);
  FKeyRef.ReferenceSize := sizeof(TACRRecordID);

  FRootPage := AddIndexPage(Cursor.Session.SessionID);
  try
    FRootPage.InitAsRoot;
    aIndexDef.RootPageNo := FRootPage.PageNo;
    IndexDef.RootPageNo := aIndexDef.RootPageNo;
  finally
    PutIndexPage(FRootPage);
  end;
  TmpCursor := TACRLocalCursor.Create;
  TmpCursor.Session := Cursor.Session;
  TmpCursor.InMemory := Cursor.InMemory;
  TmpCursor.FTableName := Cursor.FTableName;
  try
   TACRLocalCursor(TmpCursor).OpenTable(IndexManager.TableData);
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
procedure TACRBTreeIndex.CreateIndex(SessionID: TACRSessionID; pageNo: TACRPageNo; aIndexDef: TACRIndexDef);
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
procedure TACRBTreeIndex.DropIndex(SessionID: TACRSessionID; EmptyIndex: Boolean);
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
procedure TACRBTreeIndex.OpenIndex(aIndexDef: TACRIndexDef);
begin
  inherited OpenIndex(aIndexDef);

  FKeyRef := TACRBTreeKeyRef.Create;
  FKeyRef.Assign(IndexDef, IndexManager.TableData);
  FKeyRef.ReferenceSize := sizeof(TACRRecordID);
end;// OpenIndex


//------------------------------------------------------------------------------
// GetRecordBuffer
//------------------------------------------------------------------------------
procedure TACRBTreeIndex.GetRecordBuffer(
                               SessionID:          TACRSessionID;
                               var NavigationInfo: TACRNavigationInfo
                                         );
var
  KeyPath:            TACRKeyPath;
  Res1:               Boolean;
  Res2:               Boolean;
  GetRecordMode:      TACRGetRecordMode;
{$IFDEF DEBUG_INDEXES_GET_RECORD}
  i:                  Integer;
{$ENDIF}
begin
  if (NavigationInfo.GetRecordMode = grmCurrent) then
   raise EACRException.Create(20053, ErrorAInvalidIndexGetRecordMode);
{$IFDEF DEBUG_INDEXES_GET_RECORD}
aaWriteToLog(#13#10);
aaWriteToLog('> TACRBTreeIndex.GetRecordBuffer. SessionID = '+IntToStr(SessionID));
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
      KeyPath := TACRKeyPath.Create;
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
aaWriteToLog('< TACRBTreeIndex.GetRecordBuffer. SessionID = '+IntToStr(SessionID));
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
function TACRBTreeIndex.CreateIndexPosition: TACRIndexPosition;
begin
  Result := TACRKeyPath.Create;
end;// CreateIndexPosition


//------------------------------------------------------------------------------
// FreeIndexPosition
//------------------------------------------------------------------------------
procedure TACRBTreeIndex.FreeIndexPosition(var IndexPosition: TACRIndexPosition);
begin
  if (IndexPosition <> nil) then
   TACRKeyPath(IndexPosition).Free;
  IndexPosition := nil;
end;// FreeIndexPosition


//------------------------------------------------------------------------------
// GetIndexPosition
//------------------------------------------------------------------------------
function TACRBTreeIndex.GetIndexPosition(
                                         SessionID:     TACRSessionID;
                                         RecordID:      TACRRecordID;
                                         RecordBuffer:  TACRRecordBuffer;
                                         IndexPosition: TACRIndexPosition
                                        ): Boolean;
var
  Page:       TACRBTreePage;
  KeyBuffer:  PAnsiChar;
begin
//aaStartTime(time2);
  if (IndexDef.RootPageNo <> INVALID_PAGE_NO) then
    begin
      TACRKeyPath(IndexPosition).Clear;
      Page := GetIndexPage(SessionID, IndexDef.RootPageNo);
      KeyBuffer := FKeyRef.AllocKeyBuffer;
      try
        FKeyRef.MakeKeyFromRecordBuffer(RecordBuffer, KeyBuffer);
//aaStartTime(time4);
//aaIncCounter;
        Result := Page.FindEntry(SessionID, KeyBuffer, @RecordID, TACRKeyPath(IndexPosition));
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
function TACRBTreeIndex.CompareRecordPositionsInIndex(
                    RecordPosition1: TACRIndexPosition;
                    RecordPosition2: TACRIndexPosition
                                      ): Integer;
begin
 if (RecordPosition1 = nil) then
  raise EACRException.Create(10384,ErrorLNilPointer);
 if (RecordPosition2 = nil) then
  raise EACRException.Create(10385,ErrorLNilPointer);
 Result := TACRKeyPath(RecordPosition1).Compare(TACRKeyPath(RecordPosition2));
end; // CompareRecordPositionsInIndex


//------------------------------------------------------------------------------
// GetRecNoByRecordID
//------------------------------------------------------------------------------
function TACRBTreeIndex.GetRecNoByRecordID(
                                SessionID:      TACRSessionID;
                                RecordID:       TACRRecordID;
                                RecordBuffer:   TACRRecordBuffer;
                                Bitmap:         TACRRecordBitmap
                               ): TACRRecordNo;
var
  Position:       TACRKeyPath;
  ScanPage:       TACRBTreePage;
  ScanPageNo:     TACRPageNo;
  ScanEntryCount: Integer;
  i:              Integer;
begin
  Position := TACRKeyPath.Create;
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
                if (TACRRecordBitmap(Bitmap).IsRecordVisible(
                           PACRRecordID(ScanPage.GetPReference(i))^)) then
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
function TACRBTreeIndex.GetRecordIDByRecNo(
                                SessionID:      TACRSessionID;
                                RecNo:          TACRRecordNo;
                                Bitmap:         TACRRecordBitmap
                               ): TACRRecordID;
var
  Position:       TACRKeyPath;
  ScanPage:       TACRBTreePage;
  ScanPageNo:     TACRPageNo;
  i:              Integer;
  RecNoCounter:   TACRRecordNo;
  Found:          Boolean;
begin
  Position := TACRKeyPath.Create;
  try
    if (not GetFirstPosition(SessionID, Position)) then
     raise EACRException.Create(20074, ErrorACannotRetreiveRecordFromEmptyIndex)
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
                if (TACRRecordBitmap(Bitmap).IsRecordVisible(
                           PACRRecordID(ScanPage.GetPReference(i))^)) then
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
        raise EACRException.Create(20075, ErrorACannotSetRecNoGreaterThanRecordCount);
     end;
  finally
    Position.Free;
  end;
end;// GetRecordIDByRecNo


//------------------------------------------------------------------------------
// CreateSearchInfo
//------------------------------------------------------------------------------
function TACRBTreeIndex.CreateSearchInfo: TACRSearchInfo;
begin
  New(PACRBTreeSearchInfo(Result));
  PACRBTreeSearchInfo(Result)^.IsFilled := False;
  PACRBTreeSearchInfo(Result)^.CurrentKeyPath := TACRKeyPath.Create;
  PACRBTreeSearchInfo(Result)^.EndKeyPath := nil;
end;// CreateSearchInfo


//------------------------------------------------------------------------------
// FreeSearchInfo
//------------------------------------------------------------------------------
procedure TACRBTreeIndex.FreeSearchInfo(SearchInfo: TACRSearchInfo);
begin
  if (PACRBTreeSearchInfo(SearchInfo)^.CurrentKeyPath <> nil) then
    PACRBTreeSearchInfo(SearchInfo)^.CurrentKeyPath.Free;
  if (PACRBTreeSearchInfo(SearchInfo)^.EndKeyPath <> nil) then
   PACRBTreeSearchInfo(SearchInfo)^.EndKeyPath.Free;
  Dispose(PACRBTreeSearchInfo(SearchInfo));
end;// FreeSearchInfo


//------------------------------------------------------------------------------
// GetCurrentPosition
//------------------------------------------------------------------------------
function TACRBTreeIndex.GetCurrentPosition(
                             SessionID:           TACRSessionID;
                             Restart:             Boolean;
                             GoForward:           Boolean;
                             StartScanCondition:  TACRScanSearchCondition;
                             RecordBuffer:        TACRRecordBuffer;
                             RecordID:            TACRRecordID;
                             SearchInfo:          TACRSearchInfo
                                          ): Boolean;
var
  Page:        TACRBTreePage;
  KeyBuffer:  PAnsiChar;
  Pos:                           TACRKeyPath;
  Res:                           Integer;
  TakeFindFirstInsteadOfCurrent: Boolean;
begin
    if (StartScanCondition = nil) then
   if (Restart) then
     Result := GetPosition(SessionID, Restart, GoForward,
                           PACRBTreeSearchInfo(SearchInfo)^.CurrentKeyPath)
   else
     Result := GetIndexPosition(SessionID, RecordID, RecordBuffer,
                                PACRBTreeSearchInfo(SearchInfo)^.CurrentKeyPath)
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
                              PACRBTreeSearchInfo(SearchInfo)^.CurrentKeyPath
                                        );
        finally
          FKeyRef.FreeAndNilKeyBuffer(KeyBuffer);
          FKeyRef.CompareFieldCount := FKeyRef.PartCount;
          PutIndexPage(Page);
        end;

      if (Result and (not Restart)) then
        begin
          Pos := TACRKeyPath.Create;
          TakeFindFirstInsteadOfCurrent := False;
          try
            Result := GetIndexPosition(SessionID, RecordID, RecordBuffer, Pos);
            if (Result) then
             begin
               Res := CompareRecordPositionsInIndex(
                                       Pos,
                                       PACRBTreeSearchInfo(SearchInfo)^.CurrentKeyPath
                                                     );
               if (GoForward) then
                 TakeFindFirstInsteadOfCurrent := (Res < 0)
               else
                 TakeFindFirstInsteadOfCurrent := (Res > 0);
               if (not TakeFindFirstInsteadOfCurrent) then
                begin
                  PACRBTreeSearchInfo(SearchInfo)^.CurrentKeyPath.Free;
                  PACRBTreeSearchInfo(SearchInfo)^.CurrentKeyPath := Pos;
                end
               else
                 Result := GetPriorPosition(SessionID, PACRBTreeSearchInfo(SearchInfo)^.CurrentKeyPath);
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
function TACRBTreeIndex.GetEndPosition(
                             SessionID:           TACRSessionID;
                             GoForward:           Boolean;
                             StartScanCondition:  TACRScanSearchCondition;
                             EndScanCondition:    TACRScanSearchCondition;
                             SearchInfo:          TACRSearchInfo
                                      ): Boolean;
var
  Page:    TACRBTreePage;
  EndCond: TACRScanSearchCondition;
  KeyBuffer:  PAnsiChar;
begin
  if (StartScanCondition <> nil) then
    begin
      KeyBuffer := FKeyRef.AllocKeyBuffer;
      Page := GetIndexPage(SessionID, IndexDef.RootPageNo);
      try
        PACRBTreeSearchInfo(SearchInfo)^.EndKeyPath := TACRKeyPath.Create;
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
                        PACRBTreeSearchInfo(SearchInfo)^.EndKeyPath
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
function TACRBTreeIndex.FindRecord(
                   SessionID:           TACRSessionID;
                   Restart:             Boolean;
                   GoForward:           Boolean;
                   StartScanCondition:  TACRScanSearchCondition;
                   EndScanCondition:    TACRScanSearchCondition;
                   RecordBuffer:        TACRRecordBuffer;
                   var RecordID:        TACRRecordID;
                   SearchInfo:          TACRSearchInfo
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
    raise EACRException.Create(20077, ErrorANilPointer);
  if ((Restart) and (PACRBTreeSearchInfo(SearchInfo)^.IsFilled)) then
    raise EACRException.Create(20078, ErrorABTreeInvalidParams);

  Result := True;
{$IFDEF DEBUG_BTREE_INDEX_FIND_RECORD_TIME}
aaStartTime(time25);
{$ENDIF}
  if (Restart or (not PACRBTreeSearchInfo(SearchInfo)^.IsFilled)) then
    Result := GetCurrentPosition(SessionID, Restart, GoForward, StartScanCondition,
                                 RecordBuffer, RecordID, SearchInfo);
{$IFDEF DEBUG_BTREE_INDEX_FIND_RECORD_TIME}
aaStopTime(time25);
aaStartTime(time26);
{$ENDIF}
  if (Result and (not PACRBTreeSearchInfo(SearchInfo)^.IsFilled)) then
    if (not GetEndPosition(SessionID, GoForward, StartScanCondition, EndScanCondition, SearchInfo)) then
     begin
{$IFDEF DEBUG_BTREE_INDEX_FIND_RECORD_TIME}
aaStopTime(time26);
{$ENDIF}
      // changed in 4.60
      //raise EACRException.Create(20079, ErrorABTreeInvalidParams);
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
                          PACRBTreeSearchInfo(SearchInfo)^.CurrentKeyPath);
    if (Result and (PACRBTreeSearchInfo(SearchInfo)^.EndKeyPath <> nil)) then
     begin
       Res := CompareRecordPositionsInIndex(
                               PACRBTreeSearchInfo(SearchInfo)^.CurrentKeyPath,
                               PACRBTreeSearchInfo(SearchInfo)^.EndKeyPath);
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
      RecordID := GetRecordID(SessionID, PACRBTreeSearchInfo(SearchInfo)^.CurrentKeyPath);
      if (not PACRBTreeSearchInfo(SearchInfo)^.IsFilled) then
       begin
        PACRBTreeSearchInfo(SearchInfo)^.GoForward := GoForward;
        PACRBTreeSearchInfo(SearchInfo)^.IsFilled := True;
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
function TACRBTreeIndex.CompareRecordBuffersByIndex(
                        Buffer1: TACRRecordBuffer;
                        Buffer2: TACRRecordBuffer;
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
function TACRBTreeIndex.CompareConditions(
                Condition1:   TACRScanSearchCondition;
                Condition2:   TACRScanSearchCondition
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
function TACRBTreeIndex.GetApproxRangeRecordCount(
                SessionID:         TACRSessionID;
                TableRecordCount:  TACRRecordNo;
                RangeCondition1:   TACRScanSearchCondition;
                RangeCondition2:   TACRScanSearchCondition
                                  ): TACRRecordNo;
var
  FKeyBuffer:             PAnsiChar;
  KeyPath:                TACRKeyPath;
  RangeStartCondition:    TACRScanSearchCondition;
  RangeEndCondition:      TACRScanSearchCondition;
  ApproxRecNo1InPercents: Double;
  ApproxRecNo2InPercents: Double;
  CompareCount:           Integer;
  bFind:                  Boolean;
begin
{$IFDEF DEBUG_TRACE_TACRBTreeIndex_GetApproxRangeRecordCount}
aaWriteToLog('> TACRBTreeIndex.GetApproxRangeRecordCount'
+#13#10+'SessionID = '+IntToStr(SessionID)
+#13#10+'TableRecordCount = '+IntToStr(TableRecordCount)
);
aaWriteToLog('TACRBTreeIndex.GetApproxRangeRecordCount. RootPageNo = '+IntToStr(IndexDef.RootPageNo));
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
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStartTime(time12);
{$ENDIF}

  if (IndexDef.RootPageNo <> INVALID_PAGE_NO) then
   begin
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStartTime(time13);
{$ENDIF}
    CompareCount := CompareConditions(RangeCondition1, RangeCondition2);
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
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
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStartTime(time14);
{$ENDIF}
    FKeyBuffer := FKeyRef.AllocKeyBuffer;
    KeyPath := TACRKeyPath.Create;
    FRootPage := nil;
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time14);
{$ENDIF}
    try
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStartTime(time15);
{$ENDIF}
     FKeyRef.MakeKeyFromRecordBuffer(RangeStartCondition.KeyRecordBuffer, FKeyBuffer);
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time15);
aaStartTime(time16);
{$ENDIF}
     FRootPage := GetIndexPage(SessionID, IndexDef.RootPageNo);
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time16);
aaStartTime(time17);
{$ENDIF}
     FKeyRef.CompareFieldCount := RangeStartCondition.KeyFieldCount;
     bFind := FRootPage.FindByCondition(SessionID, True, FKeyBuffer,
                                   RangeStartCondition.Condition, KeyPath);
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time17);
aaStartTime(time18);
{$ENDIF}
     if (not bFind) then
       Result := 0
     else
      begin
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStartTime(time19);
{$ENDIF}
         ApproxRecNo1InPercents := KeyPath.GetApproxRecNoInPercents;
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time19);
aaStartTime(time20);
{$ENDIF}
         KeyPath.Clear;
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time20);
aaStartTime(time21);
{$ENDIF}
         FKeyRef.MakeKeyFromRecordBuffer(RangeEndCondition.KeyRecordBuffer, FKeyBuffer);
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time21);
aaStartTime(time22);
{$ENDIF}
         bFind := FRootPage.FindByCondition(SessionID, False, FKeyBuffer,
                                       RangeStartCondition.Condition, KeyPath);
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time22);
{$ENDIF}
         if (not bFind) then
           Result := 0
         else
           begin
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStartTime(time23);
{$ENDIF}
             ApproxRecNo2InPercents := KeyPath.GetApproxRecNoInPercents;
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time23);
{$ENDIF}
             Result := Round((ApproxRecNo2InPercents -
                              ApproxRecNo1InPercents) * TableRecordCount);
           end;
      end;
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time18);
{$ENDIF}
    finally
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStartTime(time24);
{$ENDIF}
     if (FRootPage <> nil) then
      begin
        PutIndexPage(FRootPage);
      end;
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time24);
{$ENDIF}
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStartTime(time25);
{$ENDIF}
     KeyPath.Free;
     FKeyRef.FreeAndNilKeyBuffer(FKeyBuffer);
     FKeyRef.CompareFieldCount := FKeyRef.PartCount;
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
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
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time12);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRBTreeIndex_GetApproxRangeRecordCount}
aaWriteToLog('< TACRBTreeIndex.GetApproxRangeRecordCount. Result = '+IntToStr(Result));
{$ENDIF}
end;// GetApproxRangeRecordCount


//------------------------------------------------------------------------------
// CanInsertRecord
//------------------------------------------------------------------------------
function TACRBTreeIndex.CanInsertRecord(
                                 SessionID:      TACRSessionID;
                                 RecordBuffer:   TACRRecordBuffer
                                 ): Boolean;
var
  KeyBuffer:             PAnsiChar;
  KeyPath:               TACRKeyPath;
begin
  if ((IndexDef.RootPageNo <> INVALID_PAGE_NO) and
      ((IndexDef.Primary) or (IndexDef.Unique))) then
   begin
    KeyBuffer := FKeyRef.AllocKeyBuffer;
    KeyPath := TACRKeyPath.Create;
    FRootPage := nil;
    try
{$IFDEF DEBUG_TRACE_TACRBTreeIndex_CanInsertRecord}
aaWriteToLog('TACRBTreeIndex.CanInsertRecord '+#13#10+
'Index name = '+IndexDef.Name+', RootPageNo = '+IntTostr(IndexDef.RootPageNo));
{$ENDIF}
      FRootPage := GetIndexPage(SessionID, IndexDef.RootPageNo);
      FKeyRef.MakeKeyFromRecordBuffer(RecordBuffer, KeyBuffer);
      Result := (not FRootPage.FindByCondition(SessionID, True, KeyBuffer, scEqual, KeyPath));
{$IFDEF DEBUG_TRACE_TACRBTreeIndex_CanInsertRecord}
aaWriteToLog('TACRBTreeIndex.CanInsertRecord '+#13#10+
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
function TACRBTreeIndex.CanUpdateRecord(
                     SessionID:                        TACRSessionID;
                     OldRecordBuffer, NewRecordBuffer: TACRRecordBuffer
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
procedure TACRBTreeIndex.InsertRecord(Cursor: TACRCursor);
var
  FKeyBuffer: PAnsiChar;
  KeyPath: TACRKeyPath;
begin
  FKeyBuffer := FKeyRef.AllocKeyBuffer;
  KeyPath := TACRKeyPath.Create;
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
procedure TACRBTreeIndex.UpdateRecord(Cursor: TACRCursor);
var
  FOldKeyBuffer: PAnsiChar;
  FNewKeyBuffer: PAnsiChar;
  KeyPath:       TACRKeyPath;
begin
  FOldKeyBuffer := FKeyRef.AllocKeyBuffer;
  FNewKeyBuffer := FKeyRef.AllocKeyBuffer;
  KeyPath := TACRKeyPath.Create;
  FRootPage := nil;
  try
   FKeyRef.MakeKeyFromRecordBuffer(Cursor.EditRecordBuffer, FOldKeyBuffer);
   FKeyRef.MakeKeyFromRecordBuffer(Cursor.CurrentRecordBuffer, FNewKeyBuffer);
   if (FKeyRef.CompareKeys(FOldKeyBuffer, FNewKeyBuffer) <> 0) then
     begin
       FRootPage := GetIndexPage(Cursor.Session.SessionID, IndexDef.RootPageNo);
       if (not FRootPage.DeleteLeafEntry(Cursor.Session.SessionID, FOldKeyBuffer, @Cursor.CurrentRecordID, KeyPath)) then
         raise EACRException.Create(20027, ErrorABTreeDeleteEntryNotFound);

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
procedure TACRBTreeIndex.DeleteRecord(Cursor: TACRCursor);
var
  FKeyBuffer: PAnsiChar;
  KeyPath: TACRKeyPath;
begin
  FKeyBuffer := FKeyRef.AllocKeyBuffer;
  KeyPath := TACRKeyPath.Create;
  FRootPage := nil;
  try
   FKeyRef.MakeKeyFromRecordBuffer(Cursor.CurrentRecordBuffer, FKeyBuffer);
   FRootPage := GetIndexPage(Cursor.Session.SessionID, IndexDef.RootPageNo);
   if (not FRootPage.DeleteLeafEntry(Cursor.Session.SessionID, FKeyBuffer, @Cursor.CurrentRecordID, KeyPath)) then
     raise EACRException.Create(20027, ErrorABTreeDeleteEntryNotFound);

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
aaWriteToLog('ACRBTree> initialized');
{$ENDIF}
  ACRMemoryIncUseCount;

finalization

  ACRMemoryDecUseCount;


end.
