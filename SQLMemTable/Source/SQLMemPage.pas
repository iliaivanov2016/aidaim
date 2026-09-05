//------------------------------------------------------------------------------
//
// All engines - diks, memory, temporary
// Cache management and
// main classes of paged system - TSQLMemPageManager, TSQLMemPage, TSQLMemPageController
//
//------------------------------------------------------------------------------

unit SQLMemPage;

{$I SQLMemVer.inc}

interface

uses Classes, SysUtils,
{$IFDEF MSWINDOWS}
     Windows,
{$ENDIF}
{$IFDEF LINUX}
     Libc,
{$ENDIF}
     Math,

// SQLMemTable units
     SQLMemCriticalSection,
     {$IFDEF DEBUG_LOG}
     SQLMemDebug,
     {$ENDIF}
{$IFNDEF D6H}
     SQLMemD4Routines,
{$ENDIF} 
     SQLMemExcept,
     SQLMemCompression,
     SQLMemConst,
     SQLMemTypes;

type

  TSQLMemPageManager = class;
  TSQLMemCache = class;
  TSQLMemDatabaseCache = class;
  TSQLMemTableCache = class;
  TSQLMemPage = class;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSortedPageArray
// from Single File System
// used for storing pages in TSQLMemCache with sorting by PageNo
// array raises exception on attempt to add duplicate page
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemSortedPageArray = class(TObject)
  private
   KeyItems: array of TSQLMemPageNo;
   ValueItems: array of TSQLMemPage;
   ItemCount: Integer;
   AllocBy: Integer;
   deAllocBy: Integer;
   MaxAllocBy: Integer;
   AllocItemCount: Integer;

   function FindPositionForInsert(key: TSQLMemPageNo) : Integer;
   function FindPosition(key: TSQLMemPageNo): Integer;
   procedure InsertByPosition(ItemNo: Integer; key: TSQLMemPageNo; value: TSQLMemPage);
   procedure DeleteByPosition(ItemNo: Integer);
   function GetKey(ItemIndex: Integer): TSQLMemPageNo;
   procedure SetKey(ItemIndex: Integer; Key: TSQLMemPageNo);
   function GetValue(ItemIndex: Integer): TSQLMemPage;
   procedure SetValue(ItemIndex: Integer; Value: TSQLMemPage);
  public
   constructor Create(size: Integer = 0; DefaultAllocBy: Integer = 10; MaximumAllocBy: Integer = 1000);
   destructor Destroy; override;
   procedure SetSize(newSize: Integer);
   function Find(key: TSQLMemPageNo; out value: TSQLMemPage) : Integer;
   procedure Insert(key: TSQLMemPageNo; value: TSQLMemPage);
   procedure Delete(key: TSQLMemPageNo; IgnoreErrors: Boolean = False);
  public
   property Count: Integer read ItemCount;
   property Keys[ItemIndex: Integer]: TSQLMemPageNo read GetKey write SetKey;
   property Values[ItemIndex: Integer]: TSQLMemPage read GetValue write SetValue;
 end; // TSQLMemSortedPageArray


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemPageArray
// used for storing pages in TSQLMemCache without sorting
// array raises exception on attempt to add duplicate page
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemPageArray = class(TObject)
   private
     FItems:          array of TSQLMemPageNo;
     FItemCount:      Integer;
     AllocBy:         Integer;
     deAllocBy:       Integer;
     MaxAllocBy:      Integer;
     AllocItemCount:  Integer;
   protected
     function GetItem(ItemIndex: Integer): TSQLMemPageNo;
     procedure SetItem(ItemIndex: Integer; PageNo: TSQLMemPageNo);
   public
     constructor Create(
      size: Integer = 0;
      DefaultAllocBy: Integer = 1;
      MaximumAllocBy: Integer = 100
     );
     destructor Destroy; override;
     procedure Assign(v: TSQLMemPageArray);
     function AppendFrom(v: TSQLMemPageArray; NumPagesToAdd: Cardinal = 0): Cardinal;
     function MoveFrom(v: TSQLMemPageArray; NumPagesToAdd: Cardinal = 0): Cardinal;
     procedure SetSize(newSize: Integer);
     function Insert(value: TSQLMemPageNo; InsertIfNotExist: Boolean = False): Integer;
     procedure DeleteByPosition(pos: Integer);
     procedure Delete(value: TSQLMemPageNo);
     function Find(value: TSQLMemPageNo): Integer;
   public
     property Count: Integer read FItemCount;
     property Items[ItemIndex: Integer]: TSQLMemPageNo read GetItem write SetItem;
 end; // TSQLMemPageArray


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemPage
//
////////////////////////////////////////////////////////////////////////////////

  TSQLMemPage = class(TObject)
   private
     LPageManager:          TSQLMemPageManager;
     LCache:                TSQLMemCache;
     LParent:               TSQLMemSortedPageArray;
     FPageNo:               TSQLMemPageNo;
     FPageBuffer:           TSQLMemPageBuffer;
     FOwnBuffer:            Boolean;
//     FIsDirty:              Boolean;
     FUpdated:              Boolean; // true if page was updated
     FDeleted:              Boolean; // indexes can delete pages before calling PutPage
     FUseCount:             Integer;
     FParentList:           TList;
     FSessionID:            TSQLMemSessionID;
     FState:                Cardinal;
     FPageHeaderSize:       Integer;
     FPageSize:             Integer;
     FStateType:            TSQLMemDBStateType;
     FThreadSync:           TSQLMemReadWriteThreadSyncBySingleCriticalSection;
     FLastAccessTime:       Cardinal;
     FTableID:              TSQLMemTableID; // ID of the table that read/write this page
                                          // INVALID_OBJECT_ID if not a table

     function GetPageHeader: PSQLMemDiskPageHeader;
     function GetPageHeaderSize: Integer;
     function GetPageData: TSQLMemPageBuffer;
     function GetPageDataSize: Integer;
     function GetPageSize: Integer;

     procedure InitHeader;
   public
     constructor Create(aPageManager: TSQLMemPageManager; aCache: TSQLMemCache = nil);
     destructor Destroy; override;
     procedure ClearPageBuffer;
     procedure AllocPageBuffer;
     procedure FreeAndNilPageBuffer;
     procedure EnlargePageBuffer(NewSize: Integer);
     procedure Lock;
     procedure Unlock;
     function IsHeaderCorrupted: Boolean;

   public
     property Cache: TSQLMemCache read LCache write LCache;
     property Updated: Boolean read FUpdated write FUpdated;
     property Deleted: Boolean read FDeleted write FDeleted;
     property Parent: TSQLMemSortedPageArray read LParent write LParent;
     property LastAccessTime: Cardinal read FLastAccessTime write FLastAccessTime;

     property PageNo: TSQLMemPageNo read FPageNo write FPageNo;
     property PageSize: Integer read GetPageSize;
     property PageBuffer: TSQLMemPageBuffer read FPageBuffer write FPageBuffer;
     property OwnBuffer: Boolean read FOwnBuffer write FOwnBuffer;
     property UseCount: Integer read FUseCount write FUseCount;
     property PageManager: TSQLMemPageManager read LPageManager;
     property PageHeader: PSQLMemDiskPageHeader read GetPageHeader;
     property PageHeaderSize: Integer read GetPageHeaderSize;
     property PageData: TSQLMemPageBuffer read GetPageData;
     property PageDataSize: Integer read GetPageDataSize;
     property ParentList: TList read FParentList write FParentList;
     property SessionID: TSQLMemSessionID read FSessionID write FSessionID;
     property State: Cardinal read FState write FState;
     property StateType: TSQLMemDBStateType read FStateType write FStateType;
     property TableID: TSQLMemTableID read FTableID write FTableID;
end;// TSQLMemPage


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemPageController
//
////////////////////////////////////////////////////////////////////////////////

  TSQLMemPageController = class(TObject)
   private
    LPage:  TSQLMemPage;
   protected
     procedure SetPageNo(Value: TSQLMemPageNo);
     function GetPageNo: TSQLMemPageNo;
     function GetPageSize: Integer;
     procedure SetPageBuffer(Value: TSQLMemPageBuffer);
     function GetPageBuffer: TSQLMemPageBuffer;
     procedure SetOwnBuffer(Value: Boolean);
     function GetOwnBuffer: Boolean;
     procedure SetUseCount(Value: Integer);
     function GetUseCount: Integer;
     function GetPageManager: TSQLMemPageManager;
   public
     constructor Create(Page: TSQLMemPage);
     procedure EnlargePageBuffer(NewSize: Integer);

     property Page: TSQLMemPage read LPage;
     property PageNo: TSQLMemPageNo read GetPageNo write SetPageNo;
     property PageSize: Integer read GetPageSize;
     property PageBuffer: TSQLMemPageBuffer read GetPageBuffer write SetPageBuffer;
     property OwnBuffer: Boolean read GetOwnBuffer write SetOwnBuffer;
     property UseCount: Integer read GetUseCount write SetUseCount;
     property PageManager: TSQLMemPageManager read GetPageManager;
  end;// TSQLMemPageController


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemPageManager
//
////////////////////////////////////////////////////////////////////////////////

  TSQLMemPageManager = class (TObject)
   private
     FCache:               TSQLMemDatabaseCache;

   protected
     FDiskPageManager:     Boolean;
     FPageSize:            Word;
     FPageHeaderSize:      Word;
     FPageDataSize:        Word;
     FPageCount:           TSQLMemPageNo;
     FExclusive:           Boolean;
   	 FReadOnly:            Boolean;

     function GetPageCount: TSQLMemPageNo; virtual;
   public
     procedure LoadFromStream(Stream: TStream); virtual;
     procedure SaveToStream(Stream: TStream); virtual;
{$IFNDEF DEBUG_LOG}
    protected
{$ENDIF}
     // for disk and memory engine only
     function DirectAddPage: TSQLMemPageNo; virtual;
     procedure InitPage(aPage: TSQLMemPage); virtual;
     // add multiple pages
     procedure DirectAddPages(
                              // place page numbers of new allocated pages at the end of the array
                              Pages:                  TSQLMemPageArray;
                              // how much pages to add
                              const NumPagesToAdd:    Cardinal;
                              // pages must be in consecutive order (n,n+1,n+2...)
                              const ConsecutiveOrder: Boolean
                             ); virtual;
     // remove all pages in the array by single operation
     procedure DirectRemovePages(Pages: TSQLMemPageArray; NumPagesFromEnd: Cardinal = 0); virtual;
     procedure InternalAddPage(aPage: TSQLMemPage); virtual; abstract;
     procedure InternalRemovePage(PageNo: TSQLMemPageNo); virtual; abstract;
     procedure InternalReadPage(aPage: TSQLMemPage); virtual; abstract;
     procedure InternalWritePage(aPage: TSQLMemPage); virtual; abstract;
     function IsSystemPage(PageNo: TSQLMemPageNo): Boolean; virtual;
    public
     constructor Create;
     destructor Destroy; override;

//------------------------------------------------------------------------------
// PM v.5
     // AddPage, RemovePage, PutPage remains same prototypes
     // read existing page from cache or from PageManager (disk / memory / temporary)
     function GetPage(
                      SessionID:  TSQLMemSessionID;
                      PageNo:     TSQLMemPageNo;
                      // state type of the locked object that calls this method
                      StateType:  TSQLMemDBStateType;
                      // current state of the locked object that calls this method
                      State:      TSQLMemState;
                      // read current page data from page manager if not in cache
                      ReadPage:   Boolean = true;
                      // this page will be updated
                      UpdatePage: Boolean = false;
                      // the page should be updated and original will be copied to shared pages
                      MakeCopy:   Boolean = false
                     ): TSQLMemPage;
    // put page
    procedure PutPage(aPage: TSQLMemPage);
    // must be called before updating page data
    procedure UpdatePage(
                          SessionID: TSQLMemSessionID;
                          Page: TSQLMemPage;
                          // state type of the locked object that calls this method
                          StateType:  TSQLMemDBStateType;
                          // current state of the locked object that calls this method
                          State:      TSQLMemState;
                          // the page should be updated and original will be copied to shared pages
                          MakeCopy:   Boolean = false
                         );
     procedure ApplyChanges(
                      // current state of the locked object that calls this method
                      State1:      TSQLMemState;
                      // StateType2 is for table metadata state only
                      StateType2:  TSQLMemDBStateType = dbstNone;
                      // State2 is for table metadata state only
                      State2:      TSQLMemState = 0
                           );
     procedure CancelChanges;
//------------------------------------------------------------------------------

     procedure FlushFileBuffers; virtual;
     procedure ClearCache;
     // read page directly without any cache
     procedure DirectReadPage(aPage: TSQLMemPage); virtual;
     // write page directly without any cache
     procedure DirectWritePage(aPage: TSQLMemPage); virtual;
     // remove page directly without any cache
     procedure DirectRemovePage(PageNo: TSQLMemPageNo); virtual;
    public
     property PageSize: Word read FPageSize;
     property PageHeaderSize: Word read FPageHeaderSize;
     property PageDataSize: Word read FPageDataSize;
     property PageCount: TSQLMemPageNo read GetPageCount;
     property Exclusive: Boolean read FExclusive write FExclusive;
     property Cache: TSQLMemDatabaseCache read FCache;
     property ReadOnly: Boolean read FReadOnly;
  end; // TSQLMemPageManager


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemMemoryPageManager
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemMemoryPageManager = class (TSQLMemPageManager)
   private
     FAllocatedPageMap:    TSQLMemBitsArray;
     FAllocatedPageCount:  TSQLMemPageNo;
     FAllocateBy:          Integer;
     LastAllocatedPageNo:  TSQLMemPageNo;
     FDataPtrs:            array of PAnsiChar;
     FThreadSync:          TSQLMemReadWriteThreadSyncByCriticalSections;
   protected
     procedure Lock(bExclusive: Boolean);
     procedure Unlock;
   public
     procedure LoadFromStream(Stream: TStream); override;
     procedure SaveToStream(Stream: TStream); override;
     procedure InitPage(aPage: TSQLMemPage); override;
     function DirectAddPage: TSQLMemPageNo; override;
   protected
     procedure InternalAddPage(aPage: TSQLMemPage); override;
     procedure InternalRemovePage(PageNo: TSQLMemPageNo); override;
     procedure InternalReadPage(aPage: TSQLMemPage); override;
     procedure InternalWritePage(aPage: TSQLMemPage); override;
   public
     constructor Create;
     destructor Destroy; override;
  end; // TSQLMemMemoryPageManager


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemTemporaryPageManager
//
////////////////////////////////////////////////////////////////////////////////
  TSQLMemTemporaryPageManager = class (TSQLMemPageManager)
   private
     FAllocatedPageMap:    TSQLMemBitsArray;
     FAllocatedPageCount:  TSQLMemPageNo;
     FTempPageFile:        TSQLMemTemporaryStream;
     FMaxMemoryPageCount:  TSQLMemPageNo;
     FMemoryPageManager:   TSQLMemPageManager;
   protected
     procedure InitPage(aPage: TSQLMemPage); override;
     function DirectAddPage: TSQLMemPageNo; override;
   public
     procedure InternalAddPage(aPage: TSQLMemPage); override;
     procedure InternalRemovePage(PageNo: TSQLMemPageNo); override;
     procedure InternalReadPage(aPage: TSQLMemPage); override;
     procedure InternalWritePage(aPage: TSQLMemPage); override;

     constructor Create;
     destructor Destroy; override;
     procedure LoadFromStream(Stream: TStream); override;
     procedure SaveToStream(Stream: TStream); override;
  end; // TSQLMemMemoryPageManager


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemCache
// Base cache class.
// It can be used by different threads and
// must provide none-blocking parallel reading access.
// only 1 active session (that modifies data) supported - it can add, remove and update pages
// all other sessions must only read pages
// Any session that updates page data MUST CALL UpdatePage
// The following operations sets FActiveSession if it was not set before:
// UpdatePage, AddPage, RemovePage, GetPage with UpdatePage = true
// When active session started the current object state is stored
// when ApplyChanges is called, the new state is passed for updating state
// of all cached pages that were modified by the active session
// or had the state equal to the state on starting modifications (were actual)
//
// It is possible to re-use deleted pages before ApplyChanges
//
// It is allowed to remove page before calling PutPage - for TSQLMemBTreeIndex 
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemCache = class(TObject)
{$IFDEF RELEASE_BUILD}
   private
{$ELSE}
   public
{$ENDIF}
    FSharedPages:     TSQLMemSortedPageArray; // pages shared to all sessions
    FSharedSync:      TSQLMemReadWriteThreadSyncByCriticalSections; // for FSharedPages
    LPageManager:     TSQLMemPageManager;

    // members for managing page modifications made by active session
    FActiveSessionID: TSQLMemSessionID;
    FAddedPages:      TSQLMemPageArray; // added page numbers (value[i] = nil)
    FDeletedPages:    TSQLMemPageArray; // deleted page numbers (value[i] = nil)
    FUpdatedPages:    TSQLMemSortedPageArray; // updated pages
    FActiveSync:      TSQLMemReadWriteThreadSyncByCriticalSections; // for all these stuff
    FState1,FState2:  Cardinal; // FState2 is for TableMetadata
    LParentCache:     TSQLMemCache;
   protected
    procedure LockShared(Exclusive: Boolean);
    procedure UnlockShared;
    procedure LockActive(Exclusive: Boolean);
    procedure UnlockActive;
    function CreatePage(
                      PageNo:     TSQLMemPageNo;
                      // state type of the locked object that calls this method
                      StateType:  TSQLMemDBStateType;
                      // current state of the locked object that calls this method
                      State:      TSQLMemState;
                      Parent:     TSQLMemSortedPageArray
                       ): TSQLMemPage; virtual;
    procedure RereadPage(
                          Page: TSQLMemPage;
                          // state type of the locked object that calls this method
                          StateType:  TSQLMemDBStateType;
                          // current state of the locked object that calls this method
                          State:      TSQLMemState
                        );
    procedure StartDataModification(
                                    SessionID:  TSQLMemSessionID;
                                    StateType:  TSQLMemDBStateType;
                                    State:      TSQLMemState
                                   );
    procedure CopyPage(Source: TSQLMemPage; Dest: TSQLMemPage);
    procedure PrepareUpdatedPage(Page: TSQLMemPage);
    function SetPageState(
                            Page: TSQLMemPage;
                            // current state of the locked object that calls this method
                            State1:      TSQLMemState;
                            // additional state type of the locked object that calls this method
                            StateType2:  TSQLMemDBStateType = dbstNone;
                            // additional current state of the locked object that calls this method
                            State2:      TSQLMemState = 0
                          ): Boolean;
    // return true if not used page must be destroy and removed from shared cache
    function IsPageMustBeDestroyed(p: TSQLMemPage): Boolean;
   public
    constructor Create(PageManager: TSQLMemPageManager);
    destructor Destroy; override;
    // destroy all pages stored in the cache and clear it
    procedure ClearAllSharedPages;
    // analyzes memory usage and clear not used pages if needed
    procedure ClearSharedCache;
    // add page
    function AddPage(
                      SessionID: TSQLMemSessionID;
                      // state type of the locked object that calls this method
                      StateType:  TSQLMemDBStateType;
                      // current state of the locked object that calls this method
                      State:      TSQLMemState;
                      // if true - page will not be used without calling GetPage
                      DoNotUse:   Boolean = False
                    ): TSQLMemPage;
    // delete page
    procedure RemovePage(
                      SessionID:      TSQLMemSessionID;
                      PageNo:         TSQLMemPageNo;
                      StateType:      TSQLMemDBStateType;
                      State:          TSQLMemState
                        );
    // add multiple pages to cache - add page numbers to added pages lits 
    procedure AddPages(
                      // place page numbers of new allocated pages at the end of the array
                      Pages:                TSQLMemPageArray;
                      // how much pages to add
                      NumPagesToAdd:        Cardinal;
                      // pages must be in consecutive order (n,n+1,n+2...)
                      ConsecutiveOrder:     Boolean;
                      SessionID:            TSQLMemSessionID;
                      // state type of the locked object that calls this method
                      StateType:            TSQLMemDBStateType;
                      // current state of the locked object that calls this method
                      State:                TSQLMemState;
                      // if true - page will not be used without calling GetPage
                      DoNotUse:   Boolean = False
                    );
    // mark page as deleted - move to deleted pages list of the cache
    procedure RemovePages(
                      Pages:            TSQLMemPageArray;
                      SessionID:        TSQLMemSessionID;
                      // state type of the locked object that calls this method
                      StateType:            TSQLMemDBStateType;
                      State:            TSQLMemState;
                      NumPagesFromEnd:  Cardinal = 0
                          );
    // read existing page from cache or from PageManager (disk / memory / temporary)
    function GetPage(
                      SessionID:  TSQLMemSessionID;
                      PageNo:     TSQLMemPageNo;
                      // state type of the locked object that calls this method
                      StateType:  TSQLMemDBStateType;
                      // current state of the locked object that calls this method
                      State:      TSQLMemState;
                      // read current page data from page manager if not in cache
                      ReadPage:   Boolean = true;
                      // this page will be updated
                      UpdatePage: Boolean = false;
                      // the page should be updated and original will be copied to shared pages
                      MakeCopy:   Boolean = false
                     ): TSQLMemPage;
    // page is read or updated
    procedure PutPage(Page: TSQLMemPage);
    // must be called before updating page data
    procedure UpdatePage(
                      SessionID: TSQLMemSessionID;
                      Page: TSQLMemPage;
                      // state type of the locked object that calls this method
                      StateType:  TSQLMemDBStateType;
                      // current state of the locked object that calls this method
                      State:      TSQLMemState;
                      // the page should be updated and original will be copied to shared pages
                      MakeCopy:   Boolean = false
                         );
    // apply all changes made by active session
    procedure ApplyChanges(
                      // current state of the locked object that calls this method
                      State1:      TSQLMemState;
                      // StateType2 is for table metadata state only
                      StateType2:  TSQLMemDBStateType = dbstNone;
                      // State2 is for table metadata state only
                      State2:      TSQLMemState = 0
                          );
    // cancel all changes made by active session
    procedure CancelChanges;
  end; // TSQLMemCache


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDatabaseCache
// Database cache class.
// Used for caching TSQLMemFreeSpaceManager pages as well as for storing
// cached pages from recently closed TSQLMemTableData
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemDatabaseCache = class (TSQLMemCache)
   private
    FChildren: TList; // list of children table caches
    FChildrenSync:      TSQLMemReadWriteThreadSyncBySingleCriticalSection;
   protected
    procedure LockChildren;
    procedure UnlockChildren;
   public
    constructor Create(PageManager:  TSQLMemPageManager);
    destructor Destroy; override;
    procedure AddChildren(Cache: TSQLMemTableCache);
    procedure DeleteChildren(Cache: TSQLMemTableCache);
  end; // TSQLMemDatabaseCache


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemTableCache
// Table cache class.
// Used for caching all pages related to current table:
// FSharedPages - pages that can be read by all reading sessions (S lock)
//
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemTableCache = class (TSQLMemCache)
   private
    FTableID:             TSQLMemTableID;
    FAddedToParentCache:  Boolean;
   protected
    function CreatePage(
                      PageNo:     TSQLMemPageNo;
                      // state type of the locked object that calls this method
                      StateType:  TSQLMemDBStateType;
                      // current state of the locked object that calls this method
                      State:      TSQLMemState;
                      Parent:     TSQLMemSortedPageArray
                       ): TSQLMemPage; override;
   public
    constructor Create(
                          PageManager:  TSQLMemPageManager;
                          ParentCache:  TSQLMemCache
                      );
    destructor Destroy; override;
    procedure ImportPagesFromParent;
    procedure ExportPagesToParent;
   public
    property TableID: TSQLMemTableID read FTableID write FTableID;
  end; // TSQLMemTableCache


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemCacheManagerThread
// Manages cache list and keep memory usage in specified limits
// if total amount of allocated memory more then high bound
// cache manager will destroy all not used shared pages in all caches
// if total amount of allocated memory more then low bound then
// cache manager will destroy all not used shared pages in database caches only
// if page was not used more then max page store time it will be removed from shared cache
//
////////////////////////////////////////////////////////////////////////////////

  TSQLMemCacheManagerThread = class(TThread)
   private
    FDatabaseCacheList:   TList;
    FTableCacheList:      TList;
    FDatabaseThreadSync:  TSQLMemReadWriteThreadSync;
    FTableThreadSync:     TSQLMemReadWriteThreadSync;
   protected
    procedure LockDatabaseList(Exclusive: Boolean);
    procedure UnlockDatabaseList;
    procedure LockTableList(Exclusive: Boolean);
    procedure UnlockTableList;
    procedure ClearDatabases;
    procedure ClearTables;
   public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;
    procedure Execute; override;
    procedure AddCache(Cache: TSQLMemCache);
    procedure RemoveCache(Cache: TSQLMemCache);
  end; // TSQLMemCacheManagerThread

var
    CacheManager:           TSQLMemCacheManagerThread = nil;
    CacheManagerThreadSync: TSQLMemReadWriteThreadSyncBySingleCriticalSection;

implementation

uses SQLMemBTree, SQLMemBaseEngine,
     SQLMemMemory                // last

;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSortedPageArray
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Finds position for insert element
//------------------------------------------------------------------------------
function TSQLMemSortedPageArray.FindPositionForInsert(key: TSQLMemPageNo): Integer;
var i,dx,f,
    oldRes,res : Integer;
begin
 i := itemCount shr 1;
 dx := i;
 Result := itemCount;
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
end; // FindPositionForInsert


//------------------------------------------------------------------------------
// Finds position for insert element
// returns -1 if element was not found
//------------------------------------------------------------------------------
function TSQLMemSortedPageArray.FindPosition(key: Integer): Integer;
begin
 Result := FindPositionForInsert(key);
 if (Result >= itemCount) or (Result < 0) then
  Result := -1
 else
  if (KeyItems[Result] <> key) then
   Result := -1;
end; // FindPosition


//------------------------------------------------------------------------------
// Insert an element into specified position
//------------------------------------------------------------------------------
procedure TSQLMemSortedPageArray.InsertByPosition(ItemNo: Integer; key: TSQLMemPageNo; value: TSQLMemPage);
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
        (itemCount - itemNo-1) * sizeOf(Integer));
    Move(ValueItems[itemNo],ValueItems[itemNo+1],
        (itemCount - itemNo-1) * sizeOf(TSQLMemPage));
    KeyItems[itemNo] := key;
    ValueItems[itemNo] := value;
   end;
end; // InsertByPosition


//------------------------------------------------------------------------------
// Delete an element at specified position
//------------------------------------------------------------------------------
procedure TSQLMemSortedPageArray.DeleteByPosition(ItemNo: Integer);
begin
 if (itemNo < itemCount-1) then
  begin
   Move(KeyItems[itemNo+1],KeyItems[itemNo],
       (itemCount - itemNo-1) * sizeOf(Integer));
   Move(ValueItems[itemNo+1],ValueItems[itemNo],
       (itemCount - itemNo-1) * sizeOf(TSQLMemPage));
  end;
 Dec(ItemCount);
 SetSize(ItemCount);
end; // DeleteByPosition


//------------------------------------------------------------------------------
// get key if index valid
//------------------------------------------------------------------------------
function TSQLMemSortedPageArray.GetKey(ItemIndex: Integer): Integer;
begin
  if ((ItemIndex >= 0) and (ItemIndex < ItemCount)) then
    Result := KeyItems[ItemIndex]
  else
    Result := INVALID_PAGE_NO;
end; // GetKey


//------------------------------------------------------------------------------
// set key if index valid
//------------------------------------------------------------------------------
procedure TSQLMemSortedPageArray.SetKey(ItemIndex: Integer; Key: Integer);
begin
  if ((ItemIndex >= 0) and (ItemIndex < ItemCount)) then
    KeyItems[ItemIndex] := Key;
end; // SetKey


//------------------------------------------------------------------------------
// get value if index valid
//------------------------------------------------------------------------------
function TSQLMemSortedPageArray.GetValue(ItemIndex: Integer): TSQLMemPage;
begin
  if ((ItemIndex >= 0) and (ItemIndex < ItemCount)) then
    Result := ValueItems[ItemIndex]
  else
    Result := nil;
end; // GetValue


//------------------------------------------------------------------------------
// set value if index valid
//------------------------------------------------------------------------------
procedure TSQLMemSortedPageArray.SetValue(ItemIndex: Integer; Value: TSQLMemPage);
begin
  if ((ItemIndex >= 0) and (ItemIndex < ItemCount)) then
    ValueItems[ItemIndex] := Value;
end; // SetValue


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TSQLMemSortedPageArray.Create(size: Integer; DefaultAllocBy: Integer; MaximumAllocBy: Integer);
begin
 AllocBy := DefaultAllocBy; // default alloc
 deAllocBy := DefaultAllocBy; // default dealloc
 MaxAllocBy := MaximumAllocBy; // max alloc
 AllocItemCount := 0;
 SetSize(size);
end; // Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemSortedPageArray.Destroy;
begin
  KeyItems := nil;
  ValueItems := nil;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Delete an element by specified key
//------------------------------------------------------------------------------
procedure TSQLMemSortedPageArray.Delete(key: Integer; IgnoreErrors: Boolean);
var pos : Integer;
begin
 if (IgnoreErrors) then
  begin
   if (itemCount > 0) then
    begin
     if ((itemCount = 1) and (KeyItems[0] = key)) then
      DeleteByPosition(0)
     else
      begin
       pos := FindPosition(key);
       if (pos >= 0) then
         DeleteByPosition(pos);
      end;
    end; // some items exists
  end // ignore errors if item with this key value does not exist
 else
  begin
   if (itemCount <= 0) then
    raise ESQLMemException.Create(11799,ErrorLInvalidItemCount,[itemCount]);
   if ((itemCount = 1) and (KeyItems[0] = key)) then
    DeleteByPosition(0)
   else
    begin
     pos := FindPosition(key);
     if (pos < 0) then
       raise ESQLMemException.Create(11800,ErrorLElementNotFound,[key,itemCount]);
     DeleteByPosition(pos);
    end;
  end; // raise exception if key not found
end; // Delete


//------------------------------------------------------------------------------
// Finds value for specified key
// returns -1 if element was not found
//------------------------------------------------------------------------------
function TSQLMemSortedPageArray.Find(key: Integer; out value: TSQLMemPage): Integer;
begin
 value := nil;
 Result := -1;
 if (ItemCount > 0) then
   begin
     Result := FindPositionForInsert(key);
     if (Result >= itemCount) or (Result < 0) then
      Result := -1
     else
      if (KeyItems[Result] <> key) then
       Result := -1
     else
      begin
       value := ValueItems[Result];
      end;
   end;
end; // Find


//------------------------------------------------------------------------------
// Insert an element into specified position
//------------------------------------------------------------------------------
procedure TSQLMemSortedPageArray.Insert(key: TSQLMemPageNo; value: TSQLMemPage);
var pos : Integer;
begin
 if (itemCount <= 0) then
  InsertByPosition(0,key,value)
 else
  if (itemCount = 1) then
   begin
    if (KeyItems[0] = key) then
     raise ESQLMemException.Create(11802,ErrorLDuplicatePage,[key,0])
    else
    if (KeyItems[0] < key) then
     InsertByPosition(1,key,value)
    else
     InsertByPosition(0,key,value);
   end
  else
   begin
    pos := FindPositionForInsert(key);
    if ((pos >= 0) and (pos < ItemCount)) then
     if (KeyItems[pos] = key) then
       raise ESQLMemException.Create(11803,ErrorLDuplicatePage,[key,pos]);
    InsertByPosition(pos,key,value);
   end;
end; // Insert


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TSQLMemSortedPageArray.SetSize(newSize: Integer);
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
end; // SetSize


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemPageArray
// used for storing pages in TSQLMemCache without sorting
// array raises exception on attempt to add duplicate page
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return item if exists
//------------------------------------------------------------------------------
function TSQLMemPageArray.GetItem(ItemIndex: Integer): TSQLMemPageNo;
begin
  if (ItemIndex >= 0) and (ItemIndex < FItemCount) then
   Result := FItems[ItemIndex]
  else
   Result := INVALID_PAGE_NO;
end; // GetItem


//------------------------------------------------------------------------------
// set item if exists
//------------------------------------------------------------------------------
procedure TSQLMemPageArray.SetItem(ItemIndex: Integer; PageNo: TSQLMemPageNo);
begin
  if (ItemIndex >= 0) and (ItemIndex < FItemCount) then
   FItems[ItemIndex] := PageNo;
end; // GetItem


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TSQLMemPageArray.Create(
  size: Integer;
  DefaultAllocBy: Integer;
  MaximumAllocBy: Integer
  );
begin
 AllocBy := DefaultAllocBy; // default alloc
 deAllocBy := DefaultAllocBy; // default dealloc
 MaxAllocBy := MaximumAllocBy; // max alloc
 AllocItemCount := 0;
 SetSize(size);
end; // TSQLMemPageArray.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TSQLMemPageArray.Destroy;
begin
 FItems := nil;
 inherited Destroy;
end; // TSQLMemPageArray.Destroy;


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TSQLMemPageArray.Assign(v: TSQLMemPageArray);
var  i,n: Integer;
begin
  n := v.Count;
  SetSize(n);
  if (n > 0) then
   Move(v.FItems[0],FItems[0],n * sizeOf(TSQLMemPageNo));
end; // Assign


//------------------------------------------------------------------------------
// append pages from end, if NumPagesToAdd = 0 then append all pages from source array
//------------------------------------------------------------------------------
function TSQLMemPageArray.AppendFrom(v: TSQLMemPageArray; NumPagesToAdd: Cardinal): Cardinal;
var n,vc,start: Cardinal;
begin
  Result := 0;
  vc := v.Count;
  if (vc > 0) then
   begin
     n := FItemCount;
     if ((NumPagesToAdd > 0) and (NumPagesToAdd < vc)) then
      begin
       Result := NumPagesToAdd;
       start := vc - NumPagesToAdd;
      end
     else
      begin
       Result := vc;
       start := 0;
      end;
     SetSize(FItemCount+Result);
     Move(v.FItems[start],FItems[n],Result * SizeOf(TSQLMemPageNo));
   end;
end; // AppendFrom


//------------------------------------------------------------------------------
// move pages from end, if NumPagesToAdd = 0 then move all pages from source array
//------------------------------------------------------------------------------
function TSQLMemPageArray.MoveFrom(v: TSQLMemPageArray; NumPagesToAdd: Cardinal): Cardinal;
var n,vc,i: Cardinal;
begin
  Result := 0;
  vc := v.Count;
  if (vc > 0) then
   begin
     n := FItemCount;
     if ((NumPagesToAdd > 0) and (NumPagesToAdd < vc)) then
      Result := NumPagesToAdd
     else
      Result := vc;
     SetSize(FItemCount+Result);
     i := vc - Result;
     // copy elemnts from end of source array
     Move(v.FItems[i],FItems[n],Result * SizeOf(TSQLMemPageNo));
     // cut the source array
     v.SetSize(i);
   end;
end; // AppendFrom


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TSQLMemPageArray.SetSize(newSize: Integer);
begin
 if (newSize = 0) then
  begin
   FItemCount := 0;
   allocItemCount := 0;
   FItems := nil;
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
     SetLength(FItems,allocItemCount);
  end
 else
  if (newSize < FItemCount) then
   if (allocItemCount-newSize > deAllocBy) then
    begin
     deAllocBy := deAllocBy * 2;
     if (deAllocBy > MaxAllocBy) then
      deAllocBy := MaxAllocBy;
     SetLength(FItems,newSize);
     allocItemCount := newSize;
    end;
 FItemCount := newSize;
end; // SetSize


//------------------------------------------------------------------------------
// Insert an element into specified position
//------------------------------------------------------------------------------
function TSQLMemPageArray.Insert(value: TSQLMemPageNo; InsertIfNotExist: Boolean): Integer;
var ItemIndex: Integer;
begin
 ItemIndex := Find(value);
 if (ItemIndex >= 0) then
  if (InsertIfNotExist) then
   begin
    // modified in v.5.30 - if insert failed, as the page already exists - return -1
    Result := -1;
    Exit;
   end
  else
    raise ESQLMemException.Create(11812,ErrorLDuplicatePage,[value,ItemIndex]);
 Inc(FItemCount);
 SetSize(FItemCount);
 Result := FItemCount-1;
 FItems[Result] := value;
end; // Insert


//------------------------------------------------------------------------------
// delete by position in array
//------------------------------------------------------------------------------
procedure TSQLMemPageArray.DeleteByPosition(pos: Integer);
var n:  Integer;
begin
 n := FItemCount-1;
 if (pos < n) then
  Move(FItems[pos+1],FItems[pos],
      (n - pos) * sizeOf(TSQLMemPageNo));
 Dec(FItemCount);
 SetSize(FItemCount);
end; // DeleteByPosition


//------------------------------------------------------------------------------
// Delete an element at specified position
//------------------------------------------------------------------------------
procedure TSQLMemPageArray.Delete(value: TSQLMemPageNo);
var ItemIndex: Integer;
begin
 ItemIndex := Find(value);
 if (ItemIndex >= 0) then
  DeleteByPosition(ItemIndex);
end; // Delete


//------------------------------------------------------------------------------
// returns index in Items or -1 if not found
//------------------------------------------------------------------------------
function TSQLMemPageArray.Find(value: TSQLMemPageNo): Integer;
var i: Integer;
begin
 Result := -1;
 for i := 0 to FItemCount-1 do
  if FItems[i] = value then
   begin
    Result := i;
    break;
   end;
end; // Find


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemPage
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// GetPageHEader
//------------------------------------------------------------------------------
function TSQLMemPage.GetPageHeader: PSQLMemDiskPageHeader;
begin
  Result := PSQLMemDiskPageHeader(FPageBuffer);
end; // GetPageHeader


//------------------------------------------------------------------------------
// GetPageData
//------------------------------------------------------------------------------
function TSQLMemPage.GetPageHeaderSize: Integer;
begin
  Result := FPageHeaderSize;
end;//GetPageHeaderSize


//------------------------------------------------------------------------------
// GetPageData
//------------------------------------------------------------------------------
function TSQLMemPage.GetPageData: TSQLMemPageBuffer;
begin
  Result := TSQLMemPageBuffer(FPageBuffer + PageHeaderSize);
end;//GetPageData


//------------------------------------------------------------------------------
// GetPageDataSize
//------------------------------------------------------------------------------
function TSQLMemPage.GetPageDataSize: Integer;
begin
  Result := PageSize - PageHeaderSize;
end;//GetPageDataSize


//------------------------------------------------------------------------------
// GetPageSize
//------------------------------------------------------------------------------
function TSQLMemPage.GetPageSize: Integer;
begin
  Result := FPageSize;
end;// GetPageSize


//------------------------------------------------------------------------------
// InitHeader
//------------------------------------------------------------------------------
procedure TSQLMemPage.InitHeader;
begin
  PageHeader.Signature := SQLMemDiskPageSignature;
  PageHeader.PageType := SQLMemPageTypeIDUnknown;
  PageHeader.NextPageNo := INVALID_PAGE_NO;
  PageHeader.CRC32 := 0;
  PageHeader.CRCType := 0;
  PageHeader.CipherType := 0;
  PageHeader.ObjectID := INVALID_OBJECT_ID;
end;//InitHeader


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TSQLMemPage.Create(aPageManager: TSQLMemPageManager; aCache: TSQLMemCache);
begin
  if (aPageManager = nil) then
   raise ESQLMemException.Create(11867,ErrorLNilPointer);
  LPageManager := aPageManager;
  LCache := aCache;
  LParent := nil;
  FPageBuffer := nil;
  FPageNo := INVALID_PAGE_NO;
  FOwnBuffer := True;
  FDeleted := False;
  FUpdated := False;
  FUseCount := 0;
  FPageHeaderSize := PageManager.PageHeaderSize;
  FPageSize := PageManager.PageSize;
  FStateType := dbstData;
  FState := 0;
  FThreadSync := TSQLMemReadWriteThreadSyncBySingleCriticalSection.Create;
  FLastAccessTime := aaGetTickCount;
  FTableID := INVALID_OBJECT_ID;
end;// Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TSQLMemPage.Destroy;
begin
  if (FOwnBuffer) then
    FreeAndNilPageBuffer;
  FThreadSync.Free;
end;// Destroy


//------------------------------------------------------------------------------
// ClearPageBuffer
//------------------------------------------------------------------------------
procedure TSQLMemPage.ClearPageBuffer;
begin
  FillChar(FPageBuffer^,PageSize,00);
end;// ClearPageBuffer


//------------------------------------------------------------------------------
// AllocPageBuffer
//------------------------------------------------------------------------------
procedure TSQLMemPage.AllocPageBuffer;
begin
  FPageBuffer := MemoryManager.AllocMem(PageSize);
  InitHeader;
end;// AllocPageBuffer


//------------------------------------------------------------------------------
// FreeAndNilPageBuffer
//------------------------------------------------------------------------------
procedure TSQLMemPage.FreeAndNilPageBuffer;
begin
  if (FPageBuffer <> nil) then
   begin
    if (SQLMem_ENCRYPTED_DB_USED) then
     FillChar(FPageBuffer^,FPageSize,$00);
    MemoryManager.FreeAndNilMem(FPageBuffer);
   end;
end;// FreeAndNilPageBuffer


//------------------------------------------------------------------------------
// EnlargePageBuffer
//------------------------------------------------------------------------------
procedure TSQLMemPage.EnlargePageBuffer(NewSize: Integer);
var
  NewBuffer: PAnsiChar;
begin
  if (FPageBuffer = nil) then
   raise ESQLMemException.Create(20038, ErrorAInvalidPageBuffer);
  if (NewSize < PageSize) then
   raise ESQLMemException.Create(20039, ErrorAInvalidPageModification);

  if (FOwnBuffer) then
    MemoryManager.ReallocMem(FPageBuffer, NewSize)
  else
   begin
     NewBuffer := MemoryManager.AllocMem(NewSize);
     Move(FPageBuffer^, NewBuffer^, PageSize);
     FPageBuffer := NewBuffer;
     FOwnBuffer := True;
   end;
end;// EnlargePageBuffer


//------------------------------------------------------------------------------
// lock page - used in TSQLMemCache.RereadPage
//------------------------------------------------------------------------------
procedure TSQLMemPage.Lock;
begin
  FThreadSync.Lock(True);
end; // Lock


//------------------------------------------------------------------------------
// unlock page - used in TSQLMemCache.RereadPage
//------------------------------------------------------------------------------
procedure TSQLMemPage.Unlock;
begin
  FThreadSync.Unlock;
end; // Unlock


//------------------------------------------------------------------------------
// return true if page header has invalid signatur and the pages is not from index system
//------------------------------------------------------------------------------
function TSQLMemPage.IsHeaderCorrupted: Boolean;
var bSkip: Boolean;
begin
  if (FPageBuffer = nil) then
   Result := True
  else
   begin
    bSkip := (FStateType = dbstIndex);
    if (LPageManager.IsSystemPage(FPageNo)) then
     bSkip := False;
    if (bSkip) then
     Result := False
    else
    begin
     Result := (
               (Byte(PageHeader.Signature[0]) <> Byte(SQLMemDiskPageSignature[1]))
               or
               (Byte(PageHeader.Signature[1]) <> Byte(SQLMemDiskPageSignature[2]))
               or
               (Byte(PageHeader.Signature[2]) <> Byte(SQLMemDiskPageSignature[3]))
               or
               (Byte(PageHeader.Signature[3]) <> Byte(SQLMemDiskPageSignature[4]))
               );
    end;
   end;
end; // IsHeaderCorrupted




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemPageController
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// SetPageNo
//------------------------------------------------------------------------------
procedure TSQLMemPageController.SetPageNo(Value: TSQLMemPageNo);
begin
  LPage.PageNo := Value;
end;// SetPageNo


//------------------------------------------------------------------------------
// GetPageNo
//------------------------------------------------------------------------------
function TSQLMemPageController.GetPageNo: TSQLMemPageNo;
begin
  Result := LPage.PageNo;
end;// GetPageNo


//------------------------------------------------------------------------------
// GetPageSize
//------------------------------------------------------------------------------
function TSQLMemPageController.GetPageSize: Integer;
begin
  Result := LPage.PageSize;
end;// GetPageSize


//------------------------------------------------------------------------------
// SetPageBuffer
//------------------------------------------------------------------------------
procedure TSQLMemPageController.SetPageBuffer(Value: TSQLMemPageBuffer);
begin
  LPage.PageBuffer := Value;
end;// SetPageBuffer


//------------------------------------------------------------------------------
// GetPageBuffer
//------------------------------------------------------------------------------
function TSQLMemPageController.GetPageBuffer: TSQLMemPageBuffer;
begin
  Result := LPage.PageBuffer;
end;// GetPageBuffer


//------------------------------------------------------------------------------
// SetOwnBuffer
//------------------------------------------------------------------------------
procedure TSQLMemPageController.SetOwnBuffer(Value: Boolean);
begin
  LPage.OwnBuffer := Value;
end;// SetOwnBuffer


//------------------------------------------------------------------------------
// GetOwnBuffer
//------------------------------------------------------------------------------
function TSQLMemPageController.GetOwnBuffer: Boolean;
begin
  Result := LPage.OwnBuffer;
end;// GetOwnBuffer


//------------------------------------------------------------------------------
// SetUseCount
//------------------------------------------------------------------------------
procedure TSQLMemPageController.SetUseCount(Value: Integer);
begin
  LPage.UseCount := Value;
end;// SetUseCount


//------------------------------------------------------------------------------
// GetUseCount
//------------------------------------------------------------------------------
function TSQLMemPageController.GetUseCount: Integer;
begin
  Result := LPage.UseCount;
end;// GetUseCount


//------------------------------------------------------------------------------
// GetPageManager
//------------------------------------------------------------------------------
function TSQLMemPageController.GetPageManager: TSQLMemPageManager;
begin
  Result := LPage.PageManager;
end;// GetPageManager


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TSQLMemPageController.Create(Page: TSQLMemPage);
begin
  LPage := Page;
end;// Create


//------------------------------------------------------------------------------
// EnlargePageBuffer
//------------------------------------------------------------------------------
procedure TSQLMemPageController.EnlargePageBuffer(NewSize: Integer);
begin
  LPage.EnlargePageBuffer(NewSize);
end;// EnlargePageBuffer



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemPageManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return page count
//------------------------------------------------------------------------------
function TSQLMemPageManager.GetPageCount: TSQLMemPageNo;
begin
  Result := FPageCount;
end; // GetPageCount


//------------------------------------------------------------------------------
// LoadFromStream
//------------------------------------------------------------------------------
procedure TSQLMemPageManager.LoadFromStream(Stream: TStream);
begin
;
end; // LoadFromStream


//------------------------------------------------------------------------------
// SaveToStream
//------------------------------------------------------------------------------
procedure TSQLMemPageManager.SaveToStream(Stream: TStream);
begin
;
end; // SaveToStream


//------------------------------------------------------------------------------
// direct add page
//------------------------------------------------------------------------------
function TSQLMemPageManager.DirectAddPage: TSQLMemPageNo;
begin
  Result := INVALID_PAGE_NO;
end; // DirectAddPage



//------------------------------------------------------------------------------
// InitPage
//------------------------------------------------------------------------------
procedure TSQLMemPageManager.InitPage(aPage: TSQLMemPage);
begin
end; // InitPage


//------------------------------------------------------------------------------
// add multiple pages
//------------------------------------------------------------------------------
procedure TSQLMemPageManager.DirectAddPages(
                          // place page numbers of new allocated pages at the end of the array
                          Pages:                  TSQLMemPageArray;
                          // how much pages to add
                          const NumPagesToAdd:    Cardinal;
                          // pages must be in consecutive order (n,n+1,n+2...)
                          const ConsecutiveOrder: Boolean
                         );
var i:        Cardinal;
    PageNo:   TSQLMemPageNo;
    page:     TSQLMemPage;
begin
// for memory / temporary engines
{ TODO -oLeo : implement it correctly }
  page := TSQLMemPage.Create(Self,nil);
  try
    i := 0;
    while (i < NumPagesToAdd) do
     begin
      page.PageNo := INVALID_PAGE_NO;
      InternalAddPage(page);
      PageNo := page.PageNo;
      Pages.Insert(PageNo);
      Inc(i);
     end;
  finally
    page.Free;
  end;
end; // DirectAddPages


//------------------------------------------------------------------------------
// remove all pages in the array by single operation
//------------------------------------------------------------------------------
procedure TSQLMemPageManager.DirectRemovePages(Pages: TSQLMemPageArray; NumPagesFromEnd: Cardinal);
var i:        Integer;
    n:        Cardinal;
    PageNo:   TSQLMemPageNo;
begin
 i := Pages.Count-1;
 n := 0;
 while (i >= 0) and ((NumPagesFromEnd = 0) or (n < NumPagesFromEnd)) do
  begin
   PageNo := Pages.Items[i];
   InternalRemovePage(PageNo);
   Dec(i);
   Inc(n);
  end;
end; // DirectRemovePages


//------------------------------------------------------------------------------
// return true if the page is system page
//------------------------------------------------------------------------------
function TSQLMemPageManager.IsSystemPage(PageNo: TSQLMemPageNo): Boolean;
begin
  Result := False;
end; // IsSystemPage


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TSQLMemPageManager.Create;
begin
  FExclusive := False;
  FReadOnly := False;
  FDiskPageManager := False;
  FCache := TSQLMemDatabaseCache.Create(Self);
end;// Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TSQLMemPageManager.Destroy;
begin
  FCache.Free;
  inherited;
end;// Destroy


//------------------------------------------------------------------------------
//
// PM v.5
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// read existing page from cache or from PageManager (disk / memory / temporary)
//------------------------------------------------------------------------------
function TSQLMemPageManager.GetPage(
                SessionID:  TSQLMemSessionID;
                PageNo:     TSQLMemPageNo;
                // state type of the locked object that calls this method
                StateType:  TSQLMemDBStateType;
                // current state of the locked object that calls this method
                State:      TSQLMemState;
                // read current page data from page manager if not in cache
                ReadPage:   Boolean = true;
                // this page will be updated
                UpdatePage: Boolean = false;
                // the page should be updated and original will be copied to shared pages
                MakeCopy:   Boolean = false
               ): TSQLMemPage;
begin
  Result := FCache.GetPage(SessionID,PageNo,StateType,State,ReadPage,UpdatePage,MakeCopy);
end; // GetPage


//------------------------------------------------------------------------------
// put page
//------------------------------------------------------------------------------
procedure TSQLMemPageManager.PutPage(aPage: TSQLMemPage);
begin
  FCache.PutPage(aPage);
end; // PutPage


//------------------------------------------------------------------------------
// must be called before updating page data
//------------------------------------------------------------------------------
procedure TSQLMemPageManager.UpdatePage(
                      SessionID: TSQLMemSessionID;
                      Page: TSQLMemPage;
                      // state type of the locked object that calls this method
                      StateType:  TSQLMemDBStateType;
                      // current state of the locked object that calls this method
                      State:      TSQLMemState;
                      // the page should be updated and original will be copied to shared pages
                      MakeCopy:   Boolean = false
                     );
begin
  FCache.UpdatePage(SessionID,Page,StateType,State,MakeCopy);
end; // UpdatePage


//------------------------------------------------------------------------------
// apply changes
//------------------------------------------------------------------------------
procedure TSQLMemPageManager.ApplyChanges(
                      // current state of the locked object that calls this method
                      State1:      TSQLMemState;
                      // StateType2 is for table metadata state only
                      StateType2:  TSQLMemDBStateType = dbstNone;
                      // State2 is for table metadata state only
                      State2:      TSQLMemState = 0
                                      );
begin
  FCache.ApplyChanges(State1,StateType2,State2);
end; // ApplyChanges


//------------------------------------------------------------------------------
// cancel changes
//------------------------------------------------------------------------------
procedure TSQLMemPageManager.CancelChanges;
begin
  FCache.CancelChanges;
end; // CancelChanges


//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// flush file buffer
//------------------------------------------------------------------------------
procedure TSQLMemPageManager.FlushFileBuffers;
begin
;
end; // FlushFileBuffers


//------------------------------------------------------------------------------
// clear cache
//------------------------------------------------------------------------------
procedure TSQLMemPageManager.ClearCache;
begin
  FCache.ClearAllSharedPages;
end; // ClearCache


//------------------------------------------------------------------------------
// read page directly without any cache
//------------------------------------------------------------------------------
procedure TSQLMemPageManager.DirectReadPage(aPage: TSQLMemPage);
begin
  if (aPage = nil) then raise ESQLMemException.Create(11868,ErrorLNilPointer);
  if (aPage.PageBuffer = nil) then raise ESQLMemException.Create(11869,ErrorLNilPointer);
  InternalReadPage(aPage);
end; // DirectGetPage


//------------------------------------------------------------------------------
// write page directly without any cache
//------------------------------------------------------------------------------
procedure TSQLMemPageManager.DirectWritePage(aPage: TSQLMemPage);
begin
  if (aPage = nil) then raise ESQLMemException.Create(11870,ErrorLNilPointer);
  if (aPage.PageBuffer = nil) then raise ESQLMemException.Create(11871,ErrorLNilPointer);
  InternalWritePage(aPage);
end; // DirectWritePage


//------------------------------------------------------------------------------
// remove page directly without any cache
//------------------------------------------------------------------------------
procedure TSQLMemPageManager.DirectRemovePage(PageNo: TSQLMemPageNo);
begin
  InternalRemovePage(PageNo);
end; // DirectRemovePage


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemMemoryPageManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TSQLMemMemoryPageManager.Lock(bExclusive: Boolean);
begin
  FThreadSync.Lock(bExclusive);
end; // Lock


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TSQLMemMemoryPageManager.Unlock;
begin
  FThreadSync.Unlock;
end; // Unlock


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TSQLMemMemoryPageManager.LoadFromStream(Stream: TStream);
var i: Integer;
begin
 Lock(True);
 try
  LoadDataFromStream(FAllocatedPageCount,Sizeof(FAllocatedPageCount),Stream,10369);
  LoadDataFromStream(LastAllocatedPageNo,Sizeof(LastAllocatedPageNo),Stream,10370);
  LoadDataFromStream(FAllocateBy,Sizeof(FAllocateBy),Stream,10371);
  LoadDataFromStream(FPageSize,Sizeof(FPageSize),Stream,10372);
  LoadDataFromStream(FPageHeaderSize,Sizeof(FPageHeaderSize),Stream,10373);
  LoadDataFromStream(FPageCount,Sizeof(FPageCount),Stream,10374);
  FAllocatedPageMap.LoadFromStream(Stream);
  SetLength(FDataPtrs,FAllocatedPageCount);
  for i := 0 to Integer(FAllocatedPageCount) - 1 do
   begin
     FDataPtrs[i] := MemoryManager.AllocMem(FPageSize);
     LoadDataFromStream(FDataPtrs[i]^,FPageSize,Stream,10375);
   end;
 finally
   Unlock;
 end;
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TSQLMemMemoryPageManager.SaveToStream(Stream: TStream);
var i: Integer;
begin
 Lock(False);
 try
  SaveDataToStream(FAllocatedPageCount,Sizeof(FAllocatedPageCount),Stream,10362);
  SaveDataToStream(LastAllocatedPageNo,Sizeof(LastAllocatedPageNo),Stream,10363);
  SaveDataToStream(FAllocateBy,Sizeof(FAllocateBy),Stream,10364);
  SaveDataToStream(FPageSize,Sizeof(FPageSize),Stream,10365);
  SaveDataToStream(FPageHeaderSize,Sizeof(FPageHeaderSize),Stream,10366);
  SaveDataToStream(FPageCount,Sizeof(FPageCount),Stream,10367);
  FAllocatedPageMap.SaveToStream(Stream);
  for i := 0 to Integer(FAllocatedPageCount) - 1 do
    SaveDataToStream(FDataPtrs[i]^,FPageSize,Stream,10368);
 finally
  Unlock;
 end;
end; // SaveToStream


//------------------------------------------------------------------------------
// init page
//------------------------------------------------------------------------------
procedure TSQLMemMemoryPageManager.InitPage(aPage: TSQLMemPage);
begin
 Lock(False);
 try
  aPage.OwnBuffer := False;
  aPage.PageBuffer := FDataPtrs[aPage.PageNo];
 finally
  Unlock;
 end;
end; // InitPage


//------------------------------------------------------------------------------
// add page
//------------------------------------------------------------------------------
function TSQLMemMemoryPageManager.DirectAddPage: TSQLMemPageNo;
var
  OldLength: Integer;
  i:         Integer;
begin
 Lock(True);
 try
  Result := 0;
  if (not FAllocatedPageMap.Find(False, Result)) then
   begin
    if (FAllocatedPageCount <> 0) then
     Result := LastAllocatedPageNo+1
    else
     Result := 0;
    if (Result >= FAllocatedPageCount) then
      begin
        Inc(FAllocatedPageCount, FAllocateBy);
        FAllocatedPageMap.Size := FAllocatedPageCount;
      end;
   end;
  Inc(FPageCount);
  if (Result < FPageCount -1) then
   if (FAllocatedPageMap.GetBit(Result)) then
    raise ESQLMemException.Create(20037, ErrorANotReleasedPageIsAllocated);
  FAllocatedPageMap.SetBit(Result, True);

  if (Length(FDataPtrs) <= Result) then
   begin
    OldLength := Length(FDataPtrs);
    SetLength(FDataPtrs, max(Result+1, OldLength+FAllocateBy));
    for i := OldLength to Length(FDataPtrs)-1 do
     FDataPtrs[i] := MemoryManager.AllocMem(FPageSize);
   end;
  if (Result > LastAllocatedPageNo) then
    LastAllocatedPageNo := Result;
 finally
   Unlock;
 end;
end; // DirectAddPage


//------------------------------------------------------------------------------
// InternalAddPage
//------------------------------------------------------------------------------
procedure TSQLMemMemoryPageManager.InternalAddPage(aPage: TSQLMemPage);
var
  PageNo: TSQLMemPageNo;
begin
  PageNo := DirectAddPage;
  aPage.PageNo := PageNo;
  InitPage(aPage);
end;// InternalAddPage


//------------------------------------------------------------------------------
// InternalRemovePage
//------------------------------------------------------------------------------
procedure TSQLMemMemoryPageManager.InternalRemovePage(PageNo: TSQLMemPageNo);
begin
 Lock(True);
 try
  Dec(FPageCount);
  FAllocatedPageMap.SetBit(PageNo, False);
 finally
  Unlock;
 end;
end;// InternalRemovePage


//------------------------------------------------------------------------------
// InternalReadPage
//------------------------------------------------------------------------------
procedure TSQLMemMemoryPageManager.InternalReadPage(aPage: TSQLMemPage);
begin
  if (not FAllocatedPageMap.GetBit(aPage.PageNo)) then
   raise ESQLMemException.Create(10392, ErrorANotReleasedPageIsAllocated);
  if (aPage.OwnBuffer) then
   aPage.FreeAndNilPageBuffer;
  InitPage(aPage);
end;// InternalReadPage


//------------------------------------------------------------------------------
// InternalWritePage
//------------------------------------------------------------------------------
procedure TSQLMemMemoryPageManager.InternalWritePage(aPage: TSQLMemPage);
begin
  if (aPage = nil) then
    raise ESQLMemException.Create(12294,ErrorLNilPointer);
  if (aPage.IsHeaderCorrupted) then
    raise ESQLMemException.Create(12295,ErrorLPageHeaderIsCorrupted,
      [aPage.PageNo,Integer(aPage.StateType),Self.ClassName,IntToHex(Integer(Self),8)]);
  if (not FAllocatedPageMap.GetBit(aPage.PageNo)) then
   raise ESQLMemException.Create(10393, ErrorANotReleasedPageIsAllocated);
  Lock(False);
  try
    if (aPage.OwnBuffer) then
     Move(aPage.PageBuffer^, FDataPtrs[aPage.PageNo]^, FPageSize);
  finally
    Unlock;
  end;
end;// InternalWritePage


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemMemoryPageManager.Create;
begin
  inherited Create;
  FAllocatedPageMap := TSQLMemBitsArray.Create;
  SetLength(FDataPtrs, 0);
  FAllocatedPageCount := 0;
  FPageCount := 0;
  FPageHeaderSize := 0;
  FPageSize := SQLMemDefaultMemoryPageSize;
  FPageDataSize := FPageSize;
  FAllocateBy := 50;
  FThreadSync := TSQLMemReadWriteThreadSyncByCriticalSections.Create(False,Self);
end;// Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemMemoryPageManager.Destroy;
var
  i: Integer;
begin
  for i := 0 to Length(FDataPtrs)-1 do
  try
    MemoryManager.FreeAndNilMem(FDataPtrs[i]);
  except
{$IFDEF DEBUG_ONERROR}
on e: Exception do
begin
aaWriteToLog('TSQLMemMemoryPageManager.Destroy Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message);
end;
{$ENDIF}
  end;
  try
    FAllocatedPageMap.Free;
    FThreadSync.Free;
    inherited Destroy;
  except
{$IFDEF DEBUG_ONERROR}
on e: Exception do
begin
aaWriteToLog('TSQLMemMemoryPageManager.Destroy Error#2 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message);
end;
{$ENDIF}
  end;
  if (FPageCount > 0) then
   raise ESQLMemException.Create(20023, ErrorAIndexPagesNotReleased);
end;// Destroy



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemTemporaryPageManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// init page
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryPageManager.InitPage(aPage: TSQLMemPage);
begin
  if (aPage.PageNo < FMaxMemoryPageCount) then
   begin
    FMemoryPageManager.InitPage(aPage);
   end
  else
   begin
    aPage.OwnBuffer := True;
    aPage.AllocPageBuffer;
   end;
end; // InitPage


//------------------------------------------------------------------------------
// direct add page
//------------------------------------------------------------------------------
function TSQLMemTemporaryPageManager.DirectAddPage: TSQLMemPageNo;
begin
  Result := FAllocatedPageCount;
  if (Result < FMaxMemoryPageCount) then
   Result := FMemoryPageManager.DirectAddPage
  else
   begin
    Inc(FAllocatedPageCount);
    FAllocatedPageMap.Size := FAllocatedPageCount;
    Inc(FPageCount);
    FAllocatedPageMap.SetBit(Result, True);
    if (FTempPageFile = nil) then
     FTempPageFile := TSQLMemTemporaryStream.Create;
    FTempPageFile.Size := 0;
   end;
  FAllocatedPageCount := Result +1;
  FAllocatedPageMap.Size := FAllocatedPageCount;
  FAllocatedPageMap.SetBit(Result, True);
end; // DirectAddPage


//------------------------------------------------------------------------------
// InternalAddPage
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryPageManager.InternalAddPage(aPage: TSQLMemPage);
var
  PageNo: TSQLMemPageNo;
begin
  PageNo := FAllocatedPageCount;
  if (PageNo < FMaxMemoryPageCount) then
   begin
    FMemoryPageManager.InternalAddPage(aPage);
    if (aPage.PageNo >= FAllocatedPageCount) then
     begin
      FAllocatedPageCount := aPage.PageNo +1;
      FAllocatedPageMap.Size := FAllocatedPageCount;
     end;
    FAllocatedPageMap.SetBit(aPage.PageNo, True);
    Inc(FPageCount);
   end
  else
   begin
    Inc(FAllocatedPageCount);
    FAllocatedPageMap.Size := FAllocatedPageCount;
    Inc(FPageCount);
    FAllocatedPageMap.SetBit(PageNo, True);
    if (FTempPageFile = nil) then
     FTempPageFile := TSQLMemTemporaryStream.Create;
    FTempPageFile.Size := 0;
    aPage.PageNo := PageNo;
    if ((not aPage.OwnBuffer) or (aPage.PageBuffer = nil)) then
     begin
       aPage.AllocPageBuffer;
       aPage.OwnBuffer := True;
     end;
   end;
end;// InternalAddPage


//------------------------------------------------------------------------------
// InternalRemovePage
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryPageManager.InternalRemovePage(PageNo: TSQLMemPageNo);
begin
  Dec(FPageCount);
  FAllocatedPageMap.SetBit(PageNo, False);
  if (PageNo < FMaxMemoryPageCount) then
   FMemoryPageManager.InternalRemovePage(PageNo)
end;// InternalRemovePage


//------------------------------------------------------------------------------
// InternalReadPage
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryPageManager.InternalReadPage(aPage: TSQLMemPage);
begin
  if (not FAllocatedPageMap.GetBit(aPage.PageNo)) then
   raise ESQLMemException.Create(10396, ErrorANotReleasedPageIsAllocated);
  if (aPage.PageNo < FMaxMemoryPageCount) then
   FMemoryPageManager.InternalReadPage(aPage)
  else
   begin
    if ((not aPage.OwnBuffer) or (aPage.PageBuffer = nil)) then
     begin
      aPage.AllocPageBuffer;
      aPage.OwnBuffer := True;
     end;
    FTempPageFile.Position := (aPage.PageNo - FMaxMemoryPageCount) * FPageSize;
    FTempPageFile.ReadBuffer(aPage.PageBuffer^, FPageSize);
   end;
end;// InternalReadPage


//------------------------------------------------------------------------------
// InternalWritePage
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryPageManager.InternalWritePage(aPage: TSQLMemPage);
begin
  if (aPage = nil) then
    raise ESQLMemException.Create(12292,ErrorLNilPointer);
  if (aPage.IsHeaderCorrupted) then
    raise ESQLMemException.Create(12293,ErrorLPageHeaderIsCorrupted,
      [aPage.PageNo,Integer(aPage.StateType),Self.ClassName,IntToHex(Integer(Self),8)]);
  if (not FAllocatedPageMap.GetBit(aPage.PageNo)) then
   raise ESQLMemException.Create(10397, ErrorANotReleasedPageIsAllocated);
  if (aPage.PageNo < FMaxMemoryPageCount) then
   FMemoryPageManager.InternalWritePage(aPage)
  else
   begin
    if (FTempPageFile = nil) then
     FTempPageFile := TSQLMemTemporaryStream.Create;
    FTempPageFile.Position := (aPage.PageNo - FMaxMemoryPageCount) * FPageSize;
    FTempPageFile.WriteBuffer(aPage.PageBuffer^, FPageSize);
   end;
end;// InternalWritePage


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemTemporaryPageManager.Create;
begin
  inherited Create;
  FAllocatedPageMap := TSQLMemBitsArray.Create;
  FAllocatedPageCount := 0;
  FPageCount := 0;
  FPageHeaderSize := 0;
  FPageSize := SQLMemDefaultTemporaryPageSize;
  FPageDataSize := FPageSize;
  FMaxMemoryPageCount := SQLMemTempPageManagerMaxMemoryPageCount;
  FTempPageFile := nil;
  FMemoryPageManager := TSQLMemMemoryPageManager.Create;
end;// Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemTemporaryPageManager.Destroy;
begin
  if (FPageCount > 0) then
   raise ESQLMemException.Create(20036, ErrorAIndexPagesNotReleased);
  FAllocatedPageMap.Free;
  if (FTempPageFile <> nil) then
   begin
    FTempPageFile.Free;
    FTempPageFile := nil;
   end;
  FMemoryPageManager.Free;
  inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// LoadFromStream
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryPageManager.LoadFromStream(Stream: TStream);
var Size: Int64;
begin
  FMemoryPageManager.LoadFromStream(Stream);
  FAllocatedPageMap.LoadFromStream(Stream);
  LoadDataFromStream(FAllocatedPageCount,Sizeof(FAllocatedPageCount),Stream,11202);
  LoadDataFromStream(FMaxMemoryPageCount,Sizeof(FMaxMemoryPageCount),Stream,11203);
  LoadDataFromStream(FPageSize,Sizeof(FPageSize),Stream,11204);
  LoadDataFromStream(FPageHeaderSize,Sizeof(FPageHeaderSize),Stream,11205);
  LoadDataFromStream(FPageCount,Sizeof(FPageCount),Stream,11206);
  LoadDataFromStream(Size,Sizeof(Size),Stream,11207);

  if (Size > 0) then
   begin
    if (FTempPageFile = nil) then
     FTempPageFile := TSQLMemTemporaryStream.Create
    else
     FTempPageFile.Size := 0;
    FTempPageFile.LoadFromStreamWithPosition(Stream,Stream.Position,Size)
   end;
end; // LoadFromStream


//------------------------------------------------------------------------------
// SaveToStream
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryPageManager.SaveToStream(Stream: TStream);
var Size: Int64;
begin
  FMemoryPageManager.SaveToStream(Stream);
  FAllocatedPageMap.SaveToStream(Stream);
  SaveDataToStream(FAllocatedPageCount,Sizeof(FAllocatedPageCount),Stream,11196);
  SaveDataToStream(FMaxMemoryPageCount,Sizeof(FMaxMemoryPageCount),Stream,111197);
  SaveDataToStream(FPageSize,Sizeof(FPageSize),Stream,11198);
  SaveDataToStream(FPageHeaderSize,Sizeof(FPageHeaderSize),Stream,11199);
  SaveDataToStream(FPageCount,Sizeof(FPageCount),Stream,11200);
  if (FTempPageFile = nil) then
   Size := 0
  else
   Size := FTempPageFile.Size;
  SaveDataToStream(Size,Sizeof(Size),Stream,11201);
  if (Size > 0) then
   FTempPageFile.SaveToStream(Stream);
end; // SaveToStream




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemCache
// Base cache class.
// It can be used by different threads and
// must provide none-blocking parallel reading access.
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// lock shared pages
//------------------------------------------------------------------------------
procedure TSQLMemCache.LockShared(Exclusive: Boolean);
begin
  FSharedSync.Lock(Exclusive);
end; // LockShared


//------------------------------------------------------------------------------
// unlock shared pages
//------------------------------------------------------------------------------
procedure TSQLMemCache.UnlockShared;
begin
  FSharedSync.Unlock;
end; // UnlockShared


//------------------------------------------------------------------------------
// lock active
//------------------------------------------------------------------------------
procedure TSQLMemCache.LockActive(Exclusive: Boolean);
begin
  if (FActiveSync = nil) then
    raise ESQLMemException.Create(11804,ErrorLNilPointer);
  FActiveSync.Lock(Exclusive);
end; // LockActive


//------------------------------------------------------------------------------
// unlock active
//------------------------------------------------------------------------------
procedure TSQLMemCache.UnlockActive;
begin
  if (FActiveSync = nil) then
    raise ESQLMemException.Create(11805,ErrorLNilPointer);
  FActiveSync.Unlock;
end; // UnlockActive


//------------------------------------------------------------------------------
// create new page
//------------------------------------------------------------------------------
function TSQLMemCache.CreatePage(
                  PageNo:     TSQLMemPageNo;
                  // state type of the locked object that calls this method
                  StateType:  TSQLMemDBStateType;
                  // current state of the locked object that calls this method
                  State:      TSQLMemState;
                  Parent:     TSQLMemSortedPageArray
                   ): TSQLMemPage;
begin
  Result := TSQLMemPage.Create(LPageManager,Self);
  Result.PageNo := PageNo;
  LPageManager.InitPage(Result);
  Result.State := State;
  Result.StateType := StateType;
  Result.Parent := Parent;
  Result.TableID := INVALID_OBJECT_ID;
  if (Parent <> FSharedPages) then
   begin
    Result.Updated := True;
   end;
end; // CreatePage


//------------------------------------------------------------------------------
// re-read page - state was changed since last use
//------------------------------------------------------------------------------
procedure TSQLMemCache.RereadPage(
                      Page: TSQLMemPage;
                      // state type of the locked object that calls this method
                      StateType:  TSQLMemDBStateType;
                      // current state of the locked object that calls this method
                      State:      TSQLMemState
                    );
begin
  if (Page <> nil) then
   begin
    Page.Lock;
    try
      LPageManager.DirectReadPage(Page);
    finally
      Page.Unlock;
    end;
   end;
end; // RereadPage


//------------------------------------------------------------------------------
// start data modification
//------------------------------------------------------------------------------
procedure TSQLMemCache.StartDataModification(
                                    SessionID:  TSQLMemSessionID;
                                    StateType:  TSQLMemDBStateType;
                                    State:      TSQLMemState
                                         );
begin
  if ((FActiveSessionID <> INVALID_SESSION_ID) and (FActiveSessionID <> SessionID)) then
   raise ESQLMemException.Create(11828,ErrorLDataModificationAlreadyStarted,
    [SessionID,FActiveSessionID,Integer(StateType),State,Self.ClassName,IntToHex(Integer(Self),8)]);
  if (FActiveSessionID = INVALID_SESSION_ID) then
   begin
    FActiveSessionID := SessionID;
    // if first modification - create all necessary objects
    if (FActiveSync = nil) then
     begin
      FActiveSync := TSQLMemReadWriteThreadSyncByCriticalSections.Create(False,Self,'ActiveSync');
      FAddedPages := TSQLMemPageArray.Create;
      FDeletedPages := TSQLMemPageArray.Create;
      FUpdatedPages := TSQLMemSortedPageArray.Create;
     end;
   end;
  // table cache has separate state for table metadata
  if (StateType = dbstTableMetaData) then
    FState2 := State
  else
    FState1 := State;
end; // StartDataModification


//------------------------------------------------------------------------------
// copy page
//------------------------------------------------------------------------------
procedure TSQLMemCache.CopyPage(Source: TSQLMemPage; Dest: TSQLMemPage);
begin
  // copy page content
  Source.Lock;
  try
    Move(Source.PageBuffer^,Dest.PageBuffer^,Source.PageSize);
    Dest.State := Source.State;
    Dest.StateType := Source.StateType;
    Dest.LastAccessTime := aaGetTickCount;
  finally
    Source.Unlock;
  end;
end; // CopyPage


//------------------------------------------------------------------------------
// prepare updated page for use in shared pages list - called from ApplyChanges
//------------------------------------------------------------------------------
procedure TSQLMemCache.PrepareUpdatedPage(Page: TSQLMemPage);
begin
  Page.LastAccessTime := aaGetTickCount;
  Page.UseCount := 0;
  Page.Updated := false;
  Page.Parent := FSharedPages;
end; // PrepareUpdatedPage


//------------------------------------------------------------------------------
// set page state in ApplyChanges
//------------------------------------------------------------------------------
function TSQLMemCache.SetPageState(
                        Page: TSQLMemPage;
                        // current state of the locked object that calls this method
                        State1:      TSQLMemState;
                        // additional state type of the locked object that calls this method
                        StateType2:  TSQLMemDBStateType = dbstNone;
                        // additional current state of the locked object that calls this method
                        State2:      TSQLMemState = 0
                      ): Boolean;
begin
  Result := True;
  if ((StateType2 <> dbstNone) and (page.StateType = StateType2)) then
   begin
     // metadata state changed by the operation that called ApplyChanges
     if (page.Updated) then
      page.State := State2
     else
      begin
       // check if metadata page is obsolete in shared cache
       if ((page.State = State2) or (page.State = FState2)) then
        page.State := State2
       else
        Result := false;
      end;
   end
  else
   begin
     if (page.Updated) then
      page.State := State1
     else
      begin
       // check if page is obsolete in shared cache
       if ((page.State = State1) or (page.State = FState1)) then
        page.State := State1
       else
        Result := false;
      end;
   end;
end; // SetPageState


//------------------------------------------------------------------------------
// return true if not used page must be destroy and removed from shared cache
//------------------------------------------------------------------------------
function TSQLMemCache.IsPageMustBeDestroyed(p: TSQLMemPage): Boolean;
var AllocatedRAM: Int64;
begin
  Result := (p.UseCount = 0);
  if (Result) then
   begin
    Result := (SQLMemGetTickCountDiff(aaGetTickCount,p.LastAccessTime) >
               SQLMemCacheManagerThreadMaxPageStoreTime);
    if (not Result) then
     begin
      AllocatedRAM := MemoryManager.TotalMemAllocated;
      Result := (AllocatedRAM >= SQLMemCacheManagerThreadRAMLowBound) or
                ((Self is TSQLMemDatabaseCache) and
                 (AllocatedRAM >= SQLMemCacheManagerThreadRAMLowBound));
     end;
   end;
end; // IsPageMustBeDestroyed


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TSQLMemCache.Create(PageManager: TSQLMemPageManager);
begin
  inherited Create;
{$IFDEF TSQLMemCacheManagerThread_ON}
  if (CacheManager = nil) then
   begin
    CacheManagerThreadSync.Lock(True);
    try
      if (CacheManager = nil) then
       CacheManager := TSQLMemCacheManagerThread.Create(False);
      CacheManager.AddCache(Self);
    finally
      CacheManagerThreadSync.Unlock;
    end;
   end
  else
   CacheManager.AddCache(Self);
{$ENDIF}
  LParentCache := nil;
  FSharedPages := TSQLMemSortedPageArray.Create;
  FSharedSync := TSQLMemReadWriteThreadSyncByCriticalSections.Create(False,Self,'SharedSync');
  LPageManager := PageManager;
  FActiveSessionID := INVALID_SESSION_ID;
  FActiveSync := nil;
  FAddedPages := nil;
  FDeletedPages := nil;
  FUpdatedPages := nil;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TSQLMemCache.Destroy;
begin
{$IFDEF TSQLMemCacheManagerThread_ON}
  CacheManager.RemoveCache(Self);
{$ENDIF}
  ClearAllSharedPages;
  CancelChanges;
  FreeAndNil(FSharedPages);
  if (FActiveSync <> nil) then
   begin
    FreeAndNil(FActiveSync);
    FreeAndNil(FAddedPages);
    FreeAndNil(FDeletedPages);
    FreeAndNil(FUpdatedPages);
   end;
  FreeAndNil(FSharedSync);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// destroy all pages stored in the cache and clear it
//------------------------------------------------------------------------------
procedure TSQLMemCache.ClearAllSharedPages;
var i: Integer;
    p: TSQLMemPage;
begin
  LockShared(True);
  try
    for i := 0 to FSharedPages.Count-1 do
     begin
      try
        p := FSharedPages.Values[i];
        if (p <> nil) then
          TSQLMemPage(p).Free;
      except
{$IFDEF DEBUG_ONERROR}
on e: Exception do
begin
aaWriteToLog('TSQLMemCache.ClearAllSharedPages Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message);
end;
{$ENDIF}
      end;
     end;
    FSharedPages.SetSize(0);
  finally
    UnlockShared;
  end;
end; // ClearAllSharedPages


//------------------------------------------------------------------------------
// analyzes memory usage and clear not used pages if needed
//------------------------------------------------------------------------------
procedure TSQLMemCache.ClearSharedCache;
var i: Integer;
    p: TSQLMemPage;
begin
{$IFDEF DEBUG_TRACE_TSQLMemCache_ClearSharedCache}
aaWriteToLog('> TSQLMemCache.ClearSharedCache');
try
{$ENDIF}
  LockShared(True);
  try
    i := 0;
{$IFDEF DEBUG_TRACE_TSQLMemCache_ClearSharedCache}
aaWriteToLog('1. TSQLMemCache.ClearSharedCache, FSharedPages.Count = '+IntToStr(FSharedPages.Count));
{$ENDIF}
    while (i < FSharedPages.Count) do
     begin
      try
{$IFDEF DEBUG_TRACE_TSQLMemCache_ClearSharedCache}
aaWriteToLog('2. TSQLMemCache.ClearSharedCache, i = '+IntToStr(i));
{$ENDIF}
        p := FSharedPages.Values[i];
{$IFDEF DEBUG_TRACE_TSQLMemCache_ClearSharedCache}
aaWriteToLog('3. TSQLMemCache.ClearSharedCache, p = '+IntToHex(Integer(p),8));
{$ENDIF}
        if (p = nil) then
         FSharedPages.Delete(i)
        else
        if (IsPageMustBeDestroyed(p)) then
          begin
{$IFDEF DEBUG_TRACE_TSQLMemCache_ClearSharedCache}
aaWriteToLog('4. TSQLMemCache.ClearSharedCache, i = '+IntToStr(i));
{$ENDIF}
            TSQLMemPage(p).Free;
{$IFDEF DEBUG_TRACE_TSQLMemCache_ClearSharedCache}
aaWriteToLog('5. TSQLMemCache.ClearSharedCache, i = '+IntToStr(i));
{$ENDIF}
            FSharedPages.DeleteByPosition(i);
          end
        else
         Inc(i);
{$IFDEF DEBUG_TRACE_TSQLMemCache_ClearSharedCache}
aaWriteToLog('6. TSQLMemCache.ClearSharedCache, i = '+IntToStr(i));
{$ENDIF}
      except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.ClearSharedCache Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
aaWriteToLog('i = '+IntToStr(i));
Inc(i);
aaWriteToLog('FSharedPages.Count = '+IntToStr(FSharedPages.Count));
{$ENDIF}
end;
      end;
     end;
  finally
    UnlockShared;
  end;
{$IFDEF DEBUG_TRACE_TSQLMemCache_ClearSharedCache}
aaWriteToLog('< TSQLMemCache.ClearSharedCache');
except
 on e: Exception do
  begin
    aaWriteToLog('Error in TSQLMemCache.ClearSharedCache'+#13#10+e.Message);
    raise;
  end;
end;
{$ENDIF}
end; // ClearSharedCache


//------------------------------------------------------------------------------
// add page to the page manager
//------------------------------------------------------------------------------
function TSQLMemCache.AddPage(
                      SessionID: TSQLMemSessionID;
                      // state type of the locked object that calls this method
                      StateType:  TSQLMemDBStateType;
                      // current state of the locked object that calls this method
                      State:      TSQLMemState;
                      DoNotUse:   Boolean = False
                    ): TSQLMemPage;
var i,n:        Integer;
    pageNo:     TSQLMemPageNo;
    pageIndex:  Integer;
    page:       TSQLMemPage;
begin
  Result := nil;
  StartDataModification(SessionID,StateType,State);
  LockActive(True);
  try
    n := FDeletedPages.Count-1;
    // try to use deleted pages (removed by prior operations inside transaction)
    while (n >= 0) do
     begin
       pageNo := FDeletedPages.Items[n];
       // if page is in FUpdatedPages - some index still use it, we cannot re-use it
       pageIndex := FUpdatedPages.Find(pageNo,Result);
       if (pageIndex < 0) then
        begin
         Result := CreatePage(pageNo,StateType,State,FUpdatedPages);
         FDeletedPages.DeleteByPosition(n);
         break;
        end
       else
         Dec(n);
     end;
    if (Result = nil) then
     begin
       pageNo := LPageManager.DirectAddPage;
       FAddedPages.Insert(pageNo);
     end;
    if (Result = nil) then
      Result := CreatePage(pageNo,StateType,State,FUpdatedPages);
    if (DoNotUse) then
      Result.UseCount := 0
    else
      Result.UseCount := 1;
    Result.SessionID := SessionID;
    Result.Updated := True;
    FUpdatedPages.Insert(pageNo,Result);
  finally
    UnlockActive;
  end;
end; // AddPage


//------------------------------------------------------------------------------
// delete page in the page manager
//------------------------------------------------------------------------------
procedure TSQLMemCache.RemovePage(
                      SessionID:      TSQLMemSessionID;
                      PageNo:         TSQLMemPageNo;
                      StateType:      TSQLMemDBStateType;
                      State:          TSQLMemState
                              );
var i,n:        Integer;
    pageIndex:  Integer;
    page:       TSQLMemPage;
begin
  StartDataModification(SessionID,StateType,State);
  LockActive(True);
  try
    pageIndex := FDeletedPages.Find(PageNo);
    if (pageIndex >= 0) then
     raise ESQLMemException.Create(11807,ErrorLDuplicatePage,[PageNo,pageIndex]);
    // check if active session already modified this page - destroy it
    pageIndex := FUpdatedPages.Find(PageNo,page);
    if (pageIndex >= 0) then
     begin
      try
        // indexes can delete pages before calling PutPage
        if (page.UseCount > 0) then
         page.Deleted := True
        else
         begin
          page.Free;
          FUpdatedPages.DeleteByPosition(pageIndex);
         end;
        // delete if it was added before
        FAddedPages.Delete(PageNo);
      except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.RemovePage Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
aaWriteToLog('PageNo = '+IntToStr(PageNo));
{$ENDIF}
end;
      end;
     end;
    FDeletedPages.Insert(PageNo);
  finally
    UnlockActive;
  end;
end; // RemovePage


//------------------------------------------------------------------------------
// add pages to the page manager
//------------------------------------------------------------------------------
procedure TSQLMemCache.AddPages(
                  // place page numbers of new allocated pages at the end of the array
                  Pages:                TSQLMemPageArray;
                  // how much pages to add
                  NumPagesToAdd:        Cardinal;
                  // pages must be in consecutive order (n,n+1,n+2...)
                  ConsecutiveOrder:     Boolean;
                  SessionID:            TSQLMemSessionID;
                  // state type of the locked object that calls this method
                  StateType:            TSQLMemDBStateType;
                  // current state of the locked object that calls this method
                  State:                TSQLMemState;
                  DoNotUse:             Boolean = False
                );

procedure SetupPage(page: TSQLMemPage);
begin
  if (DoNotUse) then
    page.UseCount := 0
  else
    page.UseCount := 1;
  page.SessionID := SessionID;
  page.Updated := True;
  FUpdatedPages.Insert(page.PageNo,page);
end;

var i,k,n,j,count:  Cardinal;
    pageNo:         TSQLMemPageNo;
    pageIndex:      Integer;
    page:           TSQLMemPage;
begin
  count := 0;
  StartDataModification(SessionID,StateType,State);
  LockActive(True);
  try
    n := FDeletedPages.Count;
    // try to use deleted pages (removed by prior operations inside transaction)
    if ((n > 0) and (not ConsecutiveOrder)) then
     begin
      k := Pages.Count;
      count := Pages.MoveFrom(FDeletedPages,NumPagesToAdd);
      i := 0;
      try
        while (i < count) do
         begin
          j := k+i;
          pageNo := Pages.Items[j];
          // check if the page was deleted by indexes and still in use
          pageIndex := FUpdatedPages.Find(pageNo,page);
          if (pageIndex >= 0) then
           begin
            // move it back to FDeletedPages
            Dec(count);
            FDeletedPages.Insert(pageNo);
            Pages.DeleteByPosition(j);
           end
          else
           begin
            page := CreatePage(pageNo,StateType,State,FUpdatedPages);
            SetupPage(page);
            Inc(i);
           end;
         end;
      except
on e: Exception do
begin
          // cancel using deleted pages
          try
            FDeletedPages.MoveFrom(Pages,count);
          except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.AddPages Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
aaWriteToLog('NumPagesToAdd = '+IntToStr(NumPagesToAdd));
{$ENDIF}
end;
          end;
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.AddPages Error#2 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
aaWriteToLog('NumPagesToAdd = '+IntToStr(NumPagesToAdd));
{$ENDIF}
          raise;
end;
      end;
      n := count;
     end // try to use deleted pages
    else
     n := 0;
   count := NumPagesToAdd - count;
   if (count > 0) then
    begin
     // create all remaining pages
     try
       k := Pages.Count;
       LPageManager.DirectAddPages(Pages,count,ConsecutiveOrder);
       i := 0;
       while (i < count) do
         begin
          pageNo := Pages.Items[k+i];
          page := CreatePage(pageNo,StateType,State,FUpdatedPages);
          SetupPage(page);
          Inc(i);
         end;
       FAddedPages.AppendFrom(Pages,count);
     except
on e: Exception do
begin
        // cancel using deleted pages
        if (n > 0) then
          try
           FDeletedPages.MoveFrom(Pages,n);
          except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.AddPages Error#3 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
aaWriteToLog('NumPagesToAdd = '+IntToStr(NumPagesToAdd));
{$ENDIF}
end;
          end;
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.AddPages Error#4 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
aaWriteToLog('NumPagesToAdd = '+IntToStr(NumPagesToAdd));
{$ENDIF}
       raise;
end;
     end;
    end;
  finally
    UnlockActive;
  end;
end; // AddPages


//------------------------------------------------------------------------------
// delete pages in the page manager
//------------------------------------------------------------------------------
procedure TSQLMemCache.RemovePages(
                  Pages:            TSQLMemPageArray;
                  SessionID:        TSQLMemSessionID;
                  // state type of the locked object that calls this method
                  StateType:        TSQLMemDBStateType;
                  State:            TSQLMemState;
                  NumPagesFromEnd:  Cardinal = 0
                                );
var i,n,start:  Cardinal;
    pageIndex:  Integer;
    page:       TSQLMemPage;
    pageNo:     TSQLMemPageNo;
begin
  if (Pages.Count <= 0) then Exit;
  StartDataModification(SessionID,StateType,State);
  LockActive(True);
  try
   if (NumPagesFromEnd = 0) then
    start := 0
   else
    start := Pages.Count-NumPagesFromEnd;
   n := Pages.Count-1;
   for i := start to n do
    begin
      pageNo := Pages.Items[i];
      pageIndex := FDeletedPages.Find(PageNo);
      if (pageIndex >= 0) then
       raise ESQLMemException.Create(11846,ErrorLDuplicatePage,[PageNo,pageIndex]);
    end; // scan all pages
   for i := start to n do
    begin
      pageNo := Pages.Items[i];
      // check if active session already modified this page - destroy it
      pageIndex := FUpdatedPages.Find(pageNo,page);
      if (pageIndex >= 0) then
       begin
        try
          // indexes can delete pages before calling PutPage
          if (page.UseCount > 0) then
           page.Deleted := True
          else
           begin
            page.Free;
            FUpdatedPages.DeleteByPosition(pageIndex);
           end;
          // delete if it was added before
          FAddedPages.Delete(pageNo);
        except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.RemovePages Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
aaWriteToLog('PageNo = '+IntToStr(pageNo));
{$ENDIF}
end;
        end;
       end;
    end; // scan all pages
   // add all pages to deleted pages
   FDeletedPages.AppendFrom(Pages,NumPagesFromEnd);
  finally
    UnlockActive;
  end;
end; // RemovePages


//------------------------------------------------------------------------------
// read existing page from cache or from PageManager (disk / memory / temporary)
//------------------------------------------------------------------------------
function TSQLMemCache.GetPage(
                  SessionID:  TSQLMemSessionID;
                  PageNo:     TSQLMemPageNo;
                  // state type of the locked object that calls this method
                  StateType:  TSQLMemDBStateType;
                  // current state of the locked object that calls this method
                  State:      TSQLMemState;
                  // read current page data from page manager if not in cache
                  ReadPage:   Boolean;
                  // this page will be updated
                  UpdatePage: Boolean;
                  // the page should be updated and original will be copied to shared pages
                  MakeCopy:   Boolean
                  ): TSQLMemPage;
var page:       TSQLMemPage;
    pageIndex:  Integer;
begin
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage}
aaWriteToLog('> TSQLMemCache.GetPage - ClassName = '+Self.ClassName
+#13#10+'SessionID = '+IntToStr(SessionID)
+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID)
+#13#10+'PageNo = '+IntToStr(PageNo)
+#13#10+'StateType = '+IntToStr(Integer(StateType))
+#13#10+'State = '+IntToStr(State)
+#13#10+'ReadPage = '+BoolToStr(ReadPage,True)
+#13#10+'UpdatePage = '+BoolToStr(UpdatePage,True)
+#13#10+'MakeCopy = '+BoolToStr(MakeCopy,True)
);
try
{$ENDIF}

{$IFDEF DEBUG_DECRYPTION_TIME}
aaIncCounter(counter7);
aaStartTime(time7);
try
{$ENDIF}
  pageIndex := -1; // not found
  Result := nil;
  if (UpdatePage) then
    StartDataModification(SessionID,StateType,State);
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('1. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
  if (((not UpdatePage) and (MakeCopy)) or (SessionID = INVALID_SESSION_ID)) then
   raise ESQLMemException.Create(11801,ErrorLGetPageInvalidParams,[PageNo,SessionID]);
  if (FActiveSessionID = SessionID) then
   begin
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('2. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
    // active session - search in updated pages at first
    LockActive(False);
    try
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('3. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      pageIndex := FUpdatedPages.Find(PageNo,Result);
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('4. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID)+#13#10+'pageIndex = '+IntToStr(pageIndex));
{$ENDIF}
    finally
      UnlockActive;
    end;
   end;
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('5. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
  // page was not found in active cache
  if (Result = nil) then
   begin
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('6. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
    // read page
    LockShared(False);
    try
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('7. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      // add to shared pages
      pageIndex := FSharedPages.Find(PageNo,Result);
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('8. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID)+#13#10+'pageIndex = '+IntToStr(pageIndex));
{$ENDIF}
    finally
      UnlockShared;
    end;
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('9. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
    if (Result <> nil) then
     begin
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('10. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      Result.Parent := FSharedPages;
      if (ReadPage) then
       if ((Result.State <> State) or (Result.StateType <> StateType)) then
        try
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('11. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
          RereadPage(Result,StateType,State);
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('12. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
        except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.GetPage Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
aaWriteToLog('PageNo = '+IntToStr(pageNo));
{$ENDIF}
          Result.Free;
          Result := nil;
          raise;
end;
        end;
     end; // page found in shared pages
   end; // search in cache and reread page if state is not equal current state

{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('13. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
  // page was not found in cache - add it
  if (Result = nil) then
   begin
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('14. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
    // page was not found in cache - add it
    if (UpdatePage) then
      Result := CreatePage(PageNo,StateType,State,FUpdatedPages)
    else
      Result := CreatePage(PageNo,StateType,State,FSharedPages);
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('15. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
    if (ReadPage) then
     try
{$IFDEF DEBUG_DECRYPTION_TIME}
aaIncCounter(counter6);
aaStartTime(time6);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('16. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      LPageManager.DirectReadPage(Result);
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('17. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
{$IFDEF DEBUG_DECRYPTION_TIME}
aaStopTime(time6);
{$ENDIF}
     except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.GetPage Error#2 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
aaWriteToLog('PageNo = '+IntToStr(pageNo));
{$ENDIF}
      Result.Free;
      Result := nil;
      raise;
end;
     end;
    if (UpdatePage) then
     begin
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('18. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      // insert new page to updated pages
      LockActive(True);
      try
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('19. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
        FUpdatedPages.Insert(PageNo,Result);
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('20. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
        Result.SessionID := SessionID;
        if (MakeCopy) then
         begin
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('21. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
          // copy current page to shared pages, result to updated pages
          LockShared(True);
          try
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('22. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
            Page := CreatePage(PageNo,StateType,State,FSharedPages);
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('23. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
            try
              CopyPage(Result,Page);
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('24. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
              FSharedPages.Insert(PageNo,Page);
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('25. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
            except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.GetPage Error#3 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
aaWriteToLog('PageNo = '+IntToStr(pageNo));
{$ENDIF}
              Page.Free;
              Result.Free;
              raise;
end;
            end;
          finally
            UnlockShared;
          end;
         end;
      finally
        UnlockActive;
      end;
     end
    else
     begin
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('26. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      // insert new page to shared pages
      LockShared(True);
      try
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('27. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
        FSharedPages.Insert(PageNo,Result);
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('28. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      finally
        UnlockShared;
      end;
     end;
   end // page was not found in cache
  else
  if (UpdatePage and (Result.Parent <> FUpdatedPages)) then
   begin
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('29. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
    Result.Updated := True;
    // update page was found in shared cache - we should move it to updated pages
    if (MakeCopy) then
     begin
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('30. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      // shared cache
      Page := Result;
      Result := CreatePage(PageNo,StateType,State,FUpdatedPages);
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('31. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      try
        CopyPage(Page,Result);
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('32. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.GetPage Error#4 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
aaWriteToLog('PageNo = '+IntToStr(pageNo));
{$ENDIF}
        Result.Free;
        Result := nil;
        raise;
end;
      end;
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('33. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      Page.Parent := FSharedPages;
      // insert new page to updated pages
      LockActive(True);
      try
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('34. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
        FUpdatedPages.Insert(PageNo,Result);
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('35. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
        Result.SessionID := SessionID;
      finally
        UnlockActive;
      end;
     end
    else
     begin
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('36. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      LockActive(True);
      try
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('37. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
        FUpdatedPages.Insert(PageNo,Result);
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('38. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
        Result.Parent := FUpdatedPages;
        Result.SessionID := SessionID;
      finally
        UnlockActive;
      end;
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('39. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      // delete page from shared pages
      LockShared(True);
      try
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('40. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
        FSharedPages.Delete(PageNo,True);
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('41. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      finally
        UnlockShared;
      end;
     end;
   end; // update page was found in shared cache - we should move it to updated pages
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage_FULL}
aaWriteToLog('42. TSQLMemCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
  Inc(Result.FUseCount);
  Result.LastAccessTime := aaGetTickCount;
{$IFDEF DEBUG_DECRYPTION_TIME}
finally
aaStopTime(time7);
end;
{$ENDIF}
{$IFDEF DEBUG_TRACE_TSQLMemCache_GetPage}
aaWriteToLog('< TSQLMemCache.GetPage - ClassName = '+Self.ClassName
+#13#10+'SessionID = '+IntToStr(SessionID)
+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID)
+#13#10+'PageNo = '+IntToStr(PageNo)
+#13#10+'StateType = '+IntToStr(Integer(StateType))
+#13#10+'State = '+IntToStr(State)
+#13#10+'ReadPage = '+BoolToStr(ReadPage,True)
+#13#10+'UpdatePage = '+BoolToStr(UpdatePage,True)
+#13#10+'MakeCopy = '+BoolToStr(MakeCopy,True)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
);
except
 on e: Exception do
  begin
aaWriteToLog('Error in TSQLMemCache.GetPage - ClassName = '+Self.ClassName
+#13#10+'SessionID = '+IntToStr(SessionID)
+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID)
+#13#10+'PageNo = '+IntToStr(PageNo)
+#13#10+'StateType = '+IntToStr(Integer(StateType))
+#13#10+'State = '+IntToStr(State)
+#13#10+'ReadPage = '+BoolToStr(ReadPage,True)
+#13#10+'UpdatePage = '+BoolToStr(UpdatePage,True)
+#13#10+'MakeCopy = '+BoolToStr(MakeCopy,True)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+e.Message
);
   raise;
  end;
end;
{$ENDIF}
end; // GetPage


//------------------------------------------------------------------------------
// page is read or updated
//------------------------------------------------------------------------------
procedure TSQLMemCache.PutPage(Page: TSQLMemPage);
begin
  if (Page.FUseCount > 0) then
   Dec(Page.FUseCount);
  Page.LastAccessTime := aaGetTickCount;
  if ((Page.Deleted) and (Page.UseCount = 0)) then
   begin
    LockActive(True);
    try
      FUpdatedPages.Delete(Page.PageNo,True);
      try
        Page.Free;
      except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.PutPage Error#3 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
{$ENDIF}
end;
      end;
    finally
      UnlockActive;
    end;
   end;
end; // PutPage


//------------------------------------------------------------------------------
// must be called before updating page data
//------------------------------------------------------------------------------
procedure TSQLMemCache.UpdatePage(
                      SessionID: TSQLMemSessionID;
                      Page: TSQLMemPage;
                      // state type of the locked object that calls this method
                      StateType:  TSQLMemDBStateType;
                      // current state of the locked object that calls this method
                      State:      TSQLMemState;
                      // the page should be updated and original will be copied to shared pages
                      MakeCopy:   Boolean = false
                     );
var pageIndex: Integer;
    oldPage:   TSQLMemPage;
    tempPage:  TSQLMemPage;
begin
  StartDataModification(SessionID,StateType,State);
  if (Page.Parent <> FUpdatedPages) then
   begin
    if (MakeCopy) then
     begin
      oldPage := CreatePage(Page.PageNo,StateType,State,FSharedPages);
      try
        CopyPage(Page,oldPage);
      except
        oldPage.Free;
        raise;
      end;
      // update shared
      LockShared(True);
      try
        pageIndex := FSharedPages.Find(Page.PageNo,tempPage);
        if (pageIndex < 0) then
         begin
           FSharedPages.Insert(Page.PageNo,oldPage);
         end
        else
         begin
           // active session uses new page with UseCount = 1
           // all other sessions - UseCount-1
           if (Page.UseCount > 0) then
            oldPage.UseCount := Page.UseCount-1;
           FSharedPages.Values[pageIndex] := oldPage;
         end;
      finally
        UnlockShared;
      end;
      // add to updated pages
      LockActive(True);
      try
        FUpdatedPages.Insert(Page.PageNo,Page);
        Page.SessionID := SessionID;
      finally
        UnlockActive;
      end;
     end
    else
     begin
      // add to updated pages
      LockActive(True);
      try
        FUpdatedPages.Insert(Page.PageNo,Page);
        Page.SessionID := SessionID;
      finally
        UnlockActive;
      end;
      // remove from shared pages
      LockShared(True);
      try
        FSharedPages.Delete(Page.PageNo,True);
      finally
        UnlockShared;
      end;
     end;
//    Page.UseCount := 1;
    Page.Updated := True;
    Page.Parent := FUpdatedPages;
   end; // page was in shared pages
end; // UpdatePage


//------------------------------------------------------------------------------
// apply changes
//------------------------------------------------------------------------------
procedure TSQLMemCache.ApplyChanges(
                      // current state of the locked object that calls this method
                      State1:      TSQLMemState;
                      // StateType2 is for table metadata state only
                      StateType2:  TSQLMemDBStateType = dbstNone;
                      // State2 is for table metadata state only
                      State2:      TSQLMemState = 0
                                );
var i,n:        Integer;
    page:       TSQLMemPage;
    pageNo:     TSQLMemPageNo;
    tempPage:   TSQLMemPage;
    pageIndex:  Integer;
    t:          Cardinal;
    State:      TSQLMemState;
begin
  if (FActiveSessionID = INVALID_SESSION_ID) then
   Exit;
  LockActive(True);
  try
    LockShared(True);
    try
{$IFDEF DEBUG_TIMES_INSERT}
aaStartTime(time15);
aaIncCounter(counter1,FUpdatedPages.Count);
aaIncCounter(counter2,FDeletedPages.Count);
aaIncCounter(counter3,FAddedPages.Count);
{$ENDIF}
      i := 0;
      while (i < FUpdatedPages.Count) do
       begin
        page := FUpdatedPages.Values[i];
        if (page.Deleted) then
         begin
          FUpdatedPages.Delete(page.PageNo,True);
          try
            page.Free;
          except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.ApplyChanges Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
{$ENDIF}
end;
          end;
         end
        else
         begin
          // write modified page
{$IFDEF DEBUG_TIMES_INSERT}
aaStartTime(time16);
{$ENDIF}
          LPageManager.DirectWritePage(page);
{$IFDEF DEBUG_TIMES_INSERT}
aaStopTime(time16);
{$ENDIF}
          SetPageState(Page,State1,StateType2,State2);
          PrepareUpdatedPage(page);
          pageIndex := FSharedPages.Find(page.PageNo,tempPage);
          if ((pageIndex >= 0) and (tempPage <> nil)) then
           begin
            try
              tempPage.Free;
            except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.ApplyChanges Error#2 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
{$ENDIF}
end;
            end;
            FSharedPages.Values[pageIndex] := page;
           end
          else
           FSharedPages.Insert(page.PageNo,page);
          Inc(i);
         end;
       end; // scan updated pages
      FUpdatedPages.SetSize(0);

      i := 0;
      n := FDeletedPages.Count;
      try
        if (n > 0) then
         LPageManager.DirectRemovePages(FDeletedPages);
      except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.ApplyChanges Error#3 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
{$ENDIF}
end;
      end;
      while (i < n) do
       begin
        // get page from deleted list
        pageNo := FDeletedPages.Items[i];
        pageIndex := FSharedPages.Find(pageNo,tempPage);
        if ((pageIndex >= 0) and (tempPage <> nil)) then
         begin
          try
           FSharedPages.DeleteByPosition(pageIndex);
           tempPage.Free;
          except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.ApplyChanges Error#4 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
{$ENDIF}
end;
          end;
         end;
        Inc(i);
       end; // scan deleted pages
       FDeletedPages.SetSize(0);
       FAddedPages.SetSize(0);
       // update states in shared cache and remove all "old pages"
       i := 0;
       n := FSharedPages.Count;
       while (i < n) do
        begin
         page := FSharedPages.Values[i];
         if (SetPageState(Page,State1,StateType2,State2)) then
          begin
           // update state
           page.UseCount := 0;
           page.Updated := false;
           Inc(i);
          end
         else
          begin
           Dec(n);
           FSharedPages.DeleteByPosition(i);
           try
             // page is obsolete - remove it from cache
             page.Free;
           except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.ApplyChanges Error#5 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
{$ENDIF}
end;
           end;
          end;
        end;
{$IFDEF DEBUG_TIMES_INSERT}
aaStopTime(time15);
{$ENDIF}
      FActiveSessionID := INVALID_SESSION_ID;
    finally
      UnlockShared;
    end;
  finally
    UnlockActive;
  end;
end; // ApplyChanges


//------------------------------------------------------------------------------
// cancel changes
//------------------------------------------------------------------------------
procedure TSQLMemCache.CancelChanges;
var i,n:        Integer;
    page:       TSQLMemPage;
    pageNo:     TSQLMemPageNo;
    tempPage:   TSQLMemPage;
    pageIndex:  Integer;
begin
  if (FActiveSessionID = INVALID_SESSION_ID) then
   Exit;
  LockActive(True);
  try
    LockShared(True);
    try
      FActiveSessionID := INVALID_SESSION_ID;
      i := 0;
      n := FAddedPages.Count;
      try
        if (n > 0) then
          LPageManager.DirectRemovePages(FAddedPages);
      except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.CancelChanges Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
{$ENDIF}
end;
      end;
      FAddedPages.SetSize(0);
      FDeletedPages.SetSize(0);
      i := 0;
      n := FUpdatedPages.ItemCount;
      while (i < n) do
       begin
        // get page from updated list
        page := FUpdatedPages.Values[i];
        try
          page.Free;
        except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemCache.CancelChanges Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
{$ENDIF}
end;
        end;
        Inc(i);
       end;
      FUpdatedPages.SetSize(0);
    finally
      UnlockShared;
    end;
  finally
    UnlockActive;
  end;
end; // CancelChanges


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDatabaseCache
// Database cache class.
// Used for caching TSQLMemFreeSpaceManager pages as well as for storing
// cached pages from recently closed TSQLMemTableData
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// lock children
//------------------------------------------------------------------------------
procedure TSQLMemDatabaseCache.LockChildren;
begin
  FChildrenSync.Lock(True);
end; // LockChildren


//------------------------------------------------------------------------------
// lock children
//------------------------------------------------------------------------------
procedure TSQLMemDatabaseCache.UnlockChildren;
begin
  FChildrenSync.Unlock;
end; // UnlockChildren


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemDatabaseCache.Create(PageManager:  TSQLMemPageManager);
begin
  inherited Create(PageManager);
  FChildrenSync := TSQLMemReadWriteThreadSyncBySingleCriticalSection.Create;
  FChildren := TList.Create;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemDatabaseCache.Destroy;
begin
  FreeAndNil(FChildrenSync);
  FreeAndNil(FChildren);
  inherited Destroy;
end; // Destroy


//------------------------------------------------------------------------------
// add children cache
//------------------------------------------------------------------------------
procedure TSQLMemDatabaseCache.AddChildren(Cache: TSQLMemTableCache);
begin
  LockChildren;
  try
   try
    FChildren.Add(Cache);
   except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemDatabaseCache.AddChildren Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
{$ENDIF}
end;
   end;
  finally
    UnlockChildren;
  end;
end; // AddChildren


//------------------------------------------------------------------------------
// delete children from cache
//------------------------------------------------------------------------------
procedure TSQLMemDatabaseCache.DeleteChildren(Cache: TSQLMemTableCache);
begin
  LockChildren;
  try
   try
    FChildren.Remove(Cache);
   except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemDatabaseCache.DeleteChildren Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
{$ENDIF}
end;
   end;
  finally
    UnlockChildren;
  end;
end; // DeleteChildren


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemTableCache
// Table cache class.
// Used for caching all pages related to current table:
// FSharedPages - pages that can be read by all reading sessions (S lock)
//
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create new page
//------------------------------------------------------------------------------
function TSQLMemTableCache.CreatePage(
                  PageNo:     TSQLMemPageNo;
                  // state type of the locked object that calls this method
                  StateType:  TSQLMemDBStateType;
                  // current state of the locked object that calls this method
                  State:      TSQLMemState;
                  Parent:     TSQLMemSortedPageArray
                   ): TSQLMemPage;
begin
  Result := inherited CreatePage(PageNo,StateType,State,Parent);
  Result.TableID := FTableID;
end; // CreatePage


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TSQLMemTableCache.Create(
                      PageManager:  TSQLMemPageManager;
                      ParentCache:  TSQLMemCache
                  );
begin
  inherited Create(PageManager);
  LParentCache := ParentCache;
  FTableID := TSQLMemTableID(INVALID_OBJECT_ID);
  FAddedToParentCache := False;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TSQLMemTableCache.Destroy;
begin
  if (FActiveSessionID <> INVALID_SESSION_ID) then
   try
    CancelChanges;
   except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemTableCache.Destroy Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
{$ENDIF}
end;
   end;
  try
//   if (FSharedPages.ItemCount > 0) then
    ExportPagesToParent;
  except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemTableCache.Destroy Error#2 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
{$ENDIF}
end;
  end;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// import pages from parent cache
//------------------------------------------------------------------------------
procedure TSQLMemTableCache.ImportPagesFromParent;
var i:    Integer;
    page: TSQLMemPage;
begin
{ TODO :
check if optimizations needed, like recreate SharedPages in parent cache or
just copy references instead of move }
  if (LParentCache = nil) then
   Exit;
  if (FTableID = INVALID_OBJECT_ID) then
    raise ESQLMemException.Create(11865,ErrorLInvalidTableID,[FTableID]);
  LockShared(True);
  if (LParentCache <> nil) then
   if (LParentCache is TSQLMemDatabaseCache) then
    begin
      TSQLMemDatabaseCache(LParentCache).AddChildren(Self);
      FAddedToParentCache := True;
    end;
  try
    LParentCache.LockShared(True);
    try
      i := 0;
      while (i < LParentCache.FSharedPages.Count) do
       begin
        page := LParentCache.FSharedPages.Values[i];
        if (page.TableID = FTableID) then
         begin
          FSharedPages.Insert(page.PageNo,page);
          LParentCache.FSharedPages.DeleteByPosition(i);
         end
        else
         Inc(i);
       end;
    finally
      LParentCache.UnlockShared;
    end;
  finally
    UnlockShared;
  end;
end; // ImportPagesFromParent


//------------------------------------------------------------------------------
// export pages to parent cache
//------------------------------------------------------------------------------
procedure TSQLMemTableCache.ExportPagesToParent;
var i,n:   Integer;
    page:  TSQLMemPage;
    tPage: TSQLMemPage;
begin
  if (LParentCache = nil) then
   Exit;
  if (FTableID = INVALID_OBJECT_ID) then
    Exit;
  if (FAddedToParentCache) then
   if (LParentCache <> nil) then
    if (LParentCache is TSQLMemDatabaseCache) then
     begin
       TSQLMemDatabaseCache(LParentCache).DeleteChildren(Self);
       FAddedToParentCache := False;
     end;
  LockShared(True);
  try
    LParentCache.LockShared(True);
    try
      i := 0;
      while (i < FSharedPages.Count) do
       begin
        page := FSharedPages.Values[i];
        n := LParentCache.FSharedPages.Find(page.PageNo,tPage);
        if (n >= 0) then
         begin
          try
           // delete old copy of page from cache
           LParentCache.FSharedPages.DeleteByPosition(n);
           tPage.Free;
          except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TSQLMemTableCache.Destroy Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
{$ENDIF}
end;
          end;
         end;
        LParentCache.FSharedPages.Insert(page.PageNo,page);
        Inc(i);
       end;
      FSharedPages.SetSize(0);
    finally
      LParentCache.UnlockShared;
    end;
  finally
    UnlockShared;
  end;
end; // ExportPagesToParent




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemCacheManagerThread
// Manages cache list and keep memory usage in specified limits
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// lock database cache list
//------------------------------------------------------------------------------
procedure TSQLMemCacheManagerThread.LockDatabaseList(Exclusive: Boolean);
begin
  FDatabaseThreadSync.Lock(Exclusive);
end; // Lock


//------------------------------------------------------------------------------
// unlock database cache list
//------------------------------------------------------------------------------
procedure TSQLMemCacheManagerThread.UnlockDatabaseList;
begin
  FDatabaseThreadSync.Unlock;
end; // Unlock


//------------------------------------------------------------------------------
// lock table cache list
//------------------------------------------------------------------------------
procedure TSQLMemCacheManagerThread.LockTableList(Exclusive: Boolean);
begin
  FTableThreadSync.Lock(Exclusive);
end; // Lock


//------------------------------------------------------------------------------
// unlock table cache list
//------------------------------------------------------------------------------
procedure TSQLMemCacheManagerThread.UnlockTableList;
begin
  FTableThreadSync.Unlock;
end; // Unlock


//------------------------------------------------------------------------------
// clear databases
//------------------------------------------------------------------------------
procedure TSQLMemCacheManagerThread.ClearDatabases;
var i:        Integer;
    dCache:   TSQLMemDatabaseCache;
begin
{$IFDEF DEBUG_TRACE_TSQLMemCacheManagerThread}
aaWriteToLog('> TSQLMemCacheManagerThread.ClearDatabases');
try
{$ENDIF}
  LockDatabaseList(False);
  try
    for i := 0 to FDatabaseCacheList.Count-1 do
     begin
       dCache := TSQLMemDatabaseCache(FDatabaseCacheList.Items[i]);
       if (dCache <> nil) then
         dCache.ClearSharedCache;
     end;
  finally
    UnlockDatabaseList;
  end;
{$IFDEF DEBUG_TRACE_TSQLMemCacheManagerThread}
aaWriteToLog('< TSQLMemCacheManagerThread.ClearDatabases');
except
  on e: Exception do
   begin
    aaWriteToLog('Error in TSQLMemCacheManagerThread.ClearDatabases'+#13#10+e.Message);
    raise;
   end;
end;
{$ENDIF}
end; // ClearDatabases


//------------------------------------------------------------------------------
// clear tables
//------------------------------------------------------------------------------
procedure TSQLMemCacheManagerThread.ClearTables;
var i:        Integer;
    tCache:   TSQLMemTableCache;
begin
{$IFDEF DEBUG_TRACE_TSQLMemCacheManagerThread}
aaWriteToLog('> TSQLMemCacheManagerThread.ClearTables');
try
{$ENDIF}
  LockTableList(False);
  try
{$IFDEF DEBUG_TRACE_TSQLMemCacheManagerThread}
aaWriteToLog('1. TSQLMemCacheManagerThread.ClearTables FTableCacheList.Count = '+IntToStr(FTableCacheList.Count));
{$ENDIF}
    for i := 0 to FTableCacheList.Count-1 do
     begin
{$IFDEF DEBUG_TRACE_TSQLMemCacheManagerThread}
aaWriteToLog('1. TSQLMemCacheManagerThread.ClearTables i = '+IntToStr(i));
{$ENDIF}
       tCache := TSQLMemTableCache(FTableCacheList.Items[i]);
{$IFDEF DEBUG_TRACE_TSQLMemCacheManagerThread}
aaWriteToLog('2. TSQLMemCacheManagerThread.ClearTables tCache = '+IntToHex(Integer(tCache),8));
{$ENDIF}
       if (tCache <> nil) then
        tCache.ClearSharedCache;
{$IFDEF DEBUG_TRACE_TSQLMemCacheManagerThread}
aaWriteToLog('3. TSQLMemCacheManagerThread.');
{$ENDIF}
     end;
  finally
    UnlockTableList;
  end;
{$IFDEF DEBUG_TRACE_TSQLMemCacheManagerThread}
aaWriteToLog('< TSQLMemCacheManagerThread.ClearTables');
except
  on e: Exception do
   begin
    aaWriteToLog('Error in TSQLMemCacheManagerThread.ClearTables'+#13#10+e.Message);
    raise;
   end;
end;
{$ENDIF}
end; // ClearTables


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemCacheManagerThread.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FDatabaseCacheList := TList.Create;
  FTableCacheList := TList.Create;
  FDatabaseThreadSync := TSQLMemReadWriteThreadSyncByCriticalSections.Create(False,Self,'DatabaseSync');
  FTableThreadSync := TSQLMemReadWriteThreadSyncByCriticalSections.Create(False,Self,'TableSync');
//  FDatabaseThreadSync := TSQLMemReadWriteThreadSyncBySingleCriticalSection.Create;
//  FTableThreadSync := TSQLMemReadWriteThreadSyncBySingleCriticalSection.Create;
  FreeOnTerminate := True;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemCacheManagerThread.Destroy;
begin
  Terminate;  
  FDatabaseCacheList.Free;
  FTableCacheList.Free;
  FDatabaseThreadSync.Free;
  FTableThreadSync.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// execute
//------------------------------------------------------------------------------
procedure TSQLMemCacheManagerThread.Execute;
var t: Cardinal;
begin
 t := aaGetTickCount;
 while (not Terminated) do
  begin
    if (SQLMemGetTickCountDiff(aaGetTickCount,t) > SQLMemCacheManagerThreadSleep) then
     begin
      ClearTables;
      ClearDatabases;
      t := aaGetTickCount;
     end;
    // sleep  
    Sleep(SQLMemCacheManagerThreadMinimumSleep);
  end;
end; // Execute


//------------------------------------------------------------------------------
// add cache
//------------------------------------------------------------------------------
procedure TSQLMemCacheManagerThread.AddCache(Cache: TSQLMemCache);
begin
{$IFDEF DEBUG_TRACE_TSQLMemCacheManagerThread}
aaWriteToLog('> TSQLMemCacheManagerThread.AddCache, Cache.ClassName = '+Cache.ClassName);
try
{$ENDIF}
 if (not Terminated) then
  if (Cache is TSQLMemDatabaseCache) then
   begin
    LockDatabaseList(True);
    try
      FDatabaseCacheList.Add(Cache);
    finally
      UnlockDatabaseList;
    end;
   end
  else
   begin
    LockTableList(True);
    try
      FTableCacheList.Add(Cache);
    finally
      UnlockTableList;
    end;
   end;
{$IFDEF DEBUG_TRACE_TSQLMemCacheManagerThread}
aaWriteToLog('< TSQLMemCacheManagerThread.AddCache, Cache.ClassName = '+Cache.ClassName);
except
  on e: Exception do
   begin
    aaWriteToLog('Error in TSQLMemCacheManagerThread.AddCache, Cache.ClassName = '+Cache.ClassName+#13#10+e.Message);
    raise;
   end;
end;
{$ENDIF}
end; // AddCache


//------------------------------------------------------------------------------
// remove cache
//------------------------------------------------------------------------------
procedure TSQLMemCacheManagerThread.RemoveCache(Cache: TSQLMemCache);
begin
{$IFDEF DEBUG_TRACE_TSQLMemCacheManagerThread}
aaWriteToLog('> TSQLMemCacheManagerThread.RemoveCache, Cache.ClassName = '+Cache.ClassName);
try
{$ENDIF}
 if (not Terminated) then
  if (Cache is TSQLMemDatabaseCache) then
   begin
    LockDatabaseList(True);
    try
      FDatabaseCacheList.Remove(Cache);
    finally
      UnlockDatabaseList;
    end;
   end
  else
   begin
    LockTableList(True);
    try
      FTableCacheList.Remove(Cache);
    finally
      UnlockTableList;
    end;
   end;
{$IFDEF DEBUG_TRACE_TSQLMemCacheManagerThread}
aaWriteToLog('< TSQLMemCacheManagerThread.RemoveCache, Cache.ClassName = '+Cache.ClassName);
except
  on e: Exception do
   begin
    aaWriteToLog('Error in TSQLMemCacheManagerThread.RemoveCache, Cache.ClassName = '+Cache.ClassName+#13#10+e.Message);
    raise;
   end;
end;
{$ENDIF}
end; // RemoveCache


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('>SQLMemPage initialization');
{$ENDIF}
  SQLMemMemoryIncUseCount;

{$IFDEF TSQLMemCacheManagerThread_ON}
  CacheManagerThreadSync := TSQLMemReadWriteThreadSyncBySingleCriticalSection.Create;
{$ENDIF}

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('<SQLMemPage> initialization');
{$ENDIF}


finalization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('>SQLMemPage finalization');
{$ENDIF}

{$IFDEF TSQLMemCacheManagerThread_ON}
  CacheManagerThreadSync.Lock(True);
  try
   if (CacheManager <> nil) then
    begin
     CacheManager.Terminate;
     Sleep(SQLMemCacheManagerThreadMinimumSleep+1);
     CacheManager := nil;
    end;
  finally
    CacheManagerThreadSync.Unlock;
  end;
  if (CacheManagerThreadSync <> nil) then
   FreeAndNil(CacheManagerThreadSync);
{$ENDIF}

  SQLMemMemoryDecUseCount;
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('<SQLMemPage finalization');
{$ENDIF}

end.
