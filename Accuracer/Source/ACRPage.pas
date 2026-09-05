//------------------------------------------------------------------------------
//
// All engines - diks, memory, temporary
// Cache management and
// main classes of paged system - TACRPageManager, TACRPage, TACRPageController
//
//------------------------------------------------------------------------------

unit ACRPage;

{$I ACRVer.inc}

interface

uses Classes, SysUtils,
{$IFDEF MSWINDOWS}
     Windows,
{$ENDIF}
{$IFDEF LINUX}
     Libc,
{$ENDIF}
     Math,

// Accuracer units
     ACRCriticalSection,
     {$IFDEF DEBUG_LOG}
     ACRDebug,
     {$ENDIF}
{$IFNDEF D6H}
     ACRD4Routines,
{$ENDIF} 
     ACRExcept,
     ACRCompression,
     ACRConst,
     ACRTypes;

type

  TACRPageManager = class;
  TACRCache = class;
  TACRDatabaseCache = class;
  TACRTableCache = class;
  TACRPage = class;


////////////////////////////////////////////////////////////////////////////////
//
// TACRSortedPageArray
// from Single File System
// used for storing pages in TACRCache with sorting by PageNo
// array raises exception on attempt to add duplicate page
//
////////////////////////////////////////////////////////////////////////////////


 TACRSortedPageArray = class(TObject)
  private
   KeyItems: array of TACRPageNo;
   ValueItems: array of TACRPage;
   ItemCount: Integer;
   AllocBy: Integer;
   deAllocBy: Integer;
   MaxAllocBy: Integer;
   AllocItemCount: Integer;

   function FindPositionForInsert(key: TACRPageNo) : Integer;
   function FindPosition(key: TACRPageNo): Integer;
   procedure InsertByPosition(ItemNo: Integer; key: TACRPageNo; value: TACRPage);
   procedure DeleteByPosition(ItemNo: Integer);
   function GetKey(ItemIndex: Integer): TACRPageNo;
   procedure SetKey(ItemIndex: Integer; Key: TACRPageNo);
   function GetValue(ItemIndex: Integer): TACRPage;
   procedure SetValue(ItemIndex: Integer; Value: TACRPage);
  public
   constructor Create(size: Integer = 0; DefaultAllocBy: Integer = 10; MaximumAllocBy: Integer = 1000);
   destructor Destroy; override;
   procedure SetSize(newSize: Integer);
   function Find(key: TACRPageNo; out value: TACRPage) : Integer;
   procedure Insert(key: TACRPageNo; value: TACRPage);
   procedure Delete(key: TACRPageNo; IgnoreErrors: Boolean = False);
  public
   property Count: Integer read ItemCount;
   property Keys[ItemIndex: Integer]: TACRPageNo read GetKey write SetKey;
   property Values[ItemIndex: Integer]: TACRPage read GetValue write SetValue;
 end; // TACRSortedPageArray


////////////////////////////////////////////////////////////////////////////////
//
// TACRPageArray
// used for storing pages in TACRCache without sorting
// array raises exception on attempt to add duplicate page
//
////////////////////////////////////////////////////////////////////////////////


 TACRPageArray = class(TObject)
   private
     FItems:          array of TACRPageNo;
     FItemCount:      Integer;
     AllocBy:         Integer;
     deAllocBy:       Integer;
     MaxAllocBy:      Integer;
     AllocItemCount:  Integer;
   protected
     function GetItem(ItemIndex: Integer): TACRPageNo;
     procedure SetItem(ItemIndex: Integer; PageNo: TACRPageNo);
   public
     constructor Create(
      size: Integer = 0;
      DefaultAllocBy: Integer = 1;
      MaximumAllocBy: Integer = 100
     );
     destructor Destroy; override;
     procedure Assign(v: TACRPageArray);
     function AppendFrom(v: TACRPageArray; NumPagesToAdd: Cardinal = 0): Cardinal;
     function MoveFrom(v: TACRPageArray; NumPagesToAdd: Cardinal = 0): Cardinal;
     procedure SetSize(newSize: Integer);
     function Insert(value: TACRPageNo; InsertIfNotExist: Boolean = False): Integer;
     procedure DeleteByPosition(pos: Integer);
     procedure Delete(value: TACRPageNo);
     function Find(value: TACRPageNo): Integer;
   public
     property Count: Integer read FItemCount;
     property Items[ItemIndex: Integer]: TACRPageNo read GetItem write SetItem;
 end; // TACRPageArray


////////////////////////////////////////////////////////////////////////////////
//
// TACRPage
//
////////////////////////////////////////////////////////////////////////////////

  TACRPage = class(TObject)
   private
     LPageManager:          TACRPageManager;
     LCache:                TACRCache;
     LParent:               TACRSortedPageArray;
     FPageNo:               TACRPageNo;
     FPageBuffer:           TACRPageBuffer;
     FOwnBuffer:            Boolean;
//     FIsDirty:              Boolean;
     FUpdated:              Boolean; // true if page was updated
     FDeleted:              Boolean; // indexes can delete pages before calling PutPage
     FUseCount:             Integer;
     FParentList:           TList;
     FSessionID:            TACRSessionID;
     FState:                Cardinal;
     FPageHeaderSize:       Integer;
     FPageSize:             Integer;
     FStateType:            TACRDBStateType;
     FThreadSync:           TACRReadWriteThreadSyncBySingleCriticalSection;
     FLastAccessTime:       Cardinal;
     FTableID:              TACRTableID; // ID of the table that read/write this page
                                          // INVALID_OBJECT_ID if not a table

     function GetPageHeader: PACRDiskPageHeader;
     function GetPageHeaderSize: Integer;
     function GetPageData: TACRPageBuffer;
     function GetPageDataSize: Integer;
     function GetPageSize: Integer;

     procedure InitHeader;
   public
     constructor Create(aPageManager: TACRPageManager; aCache: TACRCache = nil);
     destructor Destroy; override;
     procedure ClearPageBuffer;
     procedure AllocPageBuffer;
     procedure FreeAndNilPageBuffer;
     procedure EnlargePageBuffer(NewSize: Integer);
     procedure Lock;
     procedure Unlock;
     function IsHeaderCorrupted: Boolean;

   public
     property Cache: TACRCache read LCache write LCache;
     property Updated: Boolean read FUpdated write FUpdated;
     property Deleted: Boolean read FDeleted write FDeleted;
     property Parent: TACRSortedPageArray read LParent write LParent;
     property LastAccessTime: Cardinal read FLastAccessTime write FLastAccessTime;

     property PageNo: TACRPageNo read FPageNo write FPageNo;
     property PageSize: Integer read GetPageSize;
     property PageBuffer: TACRPageBuffer read FPageBuffer write FPageBuffer;
     property OwnBuffer: Boolean read FOwnBuffer write FOwnBuffer;
     property UseCount: Integer read FUseCount write FUseCount;
     property PageManager: TACRPageManager read LPageManager;
     property PageHeader: PACRDiskPageHeader read GetPageHeader;
     property PageHeaderSize: Integer read GetPageHeaderSize;
     property PageData: TACRPageBuffer read GetPageData;
     property PageDataSize: Integer read GetPageDataSize;
     property ParentList: TList read FParentList write FParentList;
     property SessionID: TACRSessionID read FSessionID write FSessionID;
     property State: Cardinal read FState write FState;
     property StateType: TACRDBStateType read FStateType write FStateType;
     property TableID: TACRTableID read FTableID write FTableID;
end;// TACRPage


////////////////////////////////////////////////////////////////////////////////
//
// TACRPageController
//
////////////////////////////////////////////////////////////////////////////////

  TACRPageController = class(TObject)
   private
    LPage:  TACRPage;
   protected
     procedure SetPageNo(Value: TACRPageNo);
     function GetPageNo: TACRPageNo;
     function GetPageSize: Integer;
     procedure SetPageBuffer(Value: TACRPageBuffer);
     function GetPageBuffer: TACRPageBuffer;
     procedure SetOwnBuffer(Value: Boolean);
     function GetOwnBuffer: Boolean;
     procedure SetUseCount(Value: Integer);
     function GetUseCount: Integer;
     function GetPageManager: TACRPageManager;
   public
     constructor Create(Page: TACRPage);
     procedure EnlargePageBuffer(NewSize: Integer);

     property Page: TACRPage read LPage;
     property PageNo: TACRPageNo read GetPageNo write SetPageNo;
     property PageSize: Integer read GetPageSize;
     property PageBuffer: TACRPageBuffer read GetPageBuffer write SetPageBuffer;
     property OwnBuffer: Boolean read GetOwnBuffer write SetOwnBuffer;
     property UseCount: Integer read GetUseCount write SetUseCount;
     property PageManager: TACRPageManager read GetPageManager;
  end;// TACRPageController


////////////////////////////////////////////////////////////////////////////////
//
// TACRPageManager
//
////////////////////////////////////////////////////////////////////////////////

  TACRPageManager = class (TObject)
   private
     FCache:               TACRDatabaseCache;

   protected
     FDiskPageManager:     Boolean;
     FPageSize:            Word;
     FPageHeaderSize:      Word;
     FPageDataSize:        Word;
     FPageCount:           TACRPageNo;
     FExclusive:           Boolean;
   	 FReadOnly:            Boolean;

     function GetPageCount: TACRPageNo; virtual;
   public
     procedure LoadFromStream(Stream: TStream); virtual;
     procedure SaveToStream(Stream: TStream); virtual;
{$IFNDEF DEBUG_LOG}
    protected
{$ENDIF}
     // for disk and memory engine only
     function DirectAddPage: TACRPageNo; virtual;
     procedure InitPage(aPage: TACRPage); virtual;
     // add multiple pages
     procedure DirectAddPages(
                              // place page numbers of new allocated pages at the end of the array
                              Pages:                  TACRPageArray;
                              // how much pages to add
                              const NumPagesToAdd:    Cardinal;
                              // pages must be in consecutive order (n,n+1,n+2...)
                              const ConsecutiveOrder: Boolean
                             ); virtual;
     // remove all pages in the array by single operation
     procedure DirectRemovePages(Pages: TACRPageArray; NumPagesFromEnd: Cardinal = 0); virtual;
     procedure InternalAddPage(aPage: TACRPage); virtual; abstract;
     procedure InternalRemovePage(PageNo: TACRPageNo); virtual; abstract;
     procedure InternalReadPage(aPage: TACRPage); virtual; abstract;
     procedure InternalWritePage(aPage: TACRPage); virtual; abstract;
     function IsSystemPage(PageNo: TACRPageNo): Boolean; virtual;
    public
     constructor Create;
     destructor Destroy; override;

//------------------------------------------------------------------------------
// PM v.5
     // AddPage, RemovePage, PutPage remains same prototypes
     // read existing page from cache or from PageManager (disk / memory / temporary)
     function GetPage(
                      SessionID:  TACRSessionID;
                      PageNo:     TACRPageNo;
                      // state type of the locked object that calls this method
                      StateType:  TACRDBStateType;
                      // current state of the locked object that calls this method
                      State:      TACRState;
                      // read current page data from page manager if not in cache
                      ReadPage:   Boolean = true;
                      // this page will be updated
                      UpdatePage: Boolean = false;
                      // the page should be updated and original will be copied to shared pages
                      MakeCopy:   Boolean = false
                     ): TACRPage;
    // put page
    procedure PutPage(aPage: TACRPage);
    // must be called before updating page data
    procedure UpdatePage(
                          SessionID: TACRSessionID;
                          Page: TACRPage;
                          // state type of the locked object that calls this method
                          StateType:  TACRDBStateType;
                          // current state of the locked object that calls this method
                          State:      TACRState;
                          // the page should be updated and original will be copied to shared pages
                          MakeCopy:   Boolean = false
                         );
     procedure ApplyChanges(
                      // current state of the locked object that calls this method
                      State1:      TACRState;
                      // StateType2 is for table metadata state only
                      StateType2:  TACRDBStateType = dbstNone;
                      // State2 is for table metadata state only
                      State2:      TACRState = 0
                           );
     procedure CancelChanges;
//------------------------------------------------------------------------------

     procedure FlushFileBuffers; virtual;
     procedure ClearCache;
     // read page directly without any cache
     procedure DirectReadPage(aPage: TACRPage); virtual;
     // write page directly without any cache
     procedure DirectWritePage(aPage: TACRPage); virtual;
     // remove page directly without any cache
     procedure DirectRemovePage(PageNo: TACRPageNo); virtual;
    public
     property PageSize: Word read FPageSize;
     property PageHeaderSize: Word read FPageHeaderSize;
     property PageDataSize: Word read FPageDataSize;
     property PageCount: TACRPageNo read GetPageCount;
     property Exclusive: Boolean read FExclusive write FExclusive;
     property Cache: TACRDatabaseCache read FCache;
     property ReadOnly: Boolean read FReadOnly;
  end; // TACRPageManager


////////////////////////////////////////////////////////////////////////////////
//
// TACRMemoryPageManager
//
////////////////////////////////////////////////////////////////////////////////


  TACRMemoryPageManager = class (TACRPageManager)
   private
     FAllocatedPageMap:    TACRBitsArray;
     FAllocatedPageCount:  TACRPageNo;
     FAllocateBy:          Integer;
     LastAllocatedPageNo:  TACRPageNo;
     FDataPtrs:            array of PAnsiChar;
     FThreadSync:          TACRReadWriteThreadSyncByCriticalSections;
   protected
     procedure Lock(bExclusive: Boolean);
     procedure Unlock;
   public
     procedure LoadFromStream(Stream: TStream); override;
     procedure SaveToStream(Stream: TStream); override;
     procedure InitPage(aPage: TACRPage); override;
     function DirectAddPage: TACRPageNo; override;
   protected
     procedure InternalAddPage(aPage: TACRPage); override;
     procedure InternalRemovePage(PageNo: TACRPageNo); override;
     procedure InternalReadPage(aPage: TACRPage); override;
     procedure InternalWritePage(aPage: TACRPage); override;
   public
     constructor Create;
     destructor Destroy; override;
  end; // TACRMemoryPageManager


////////////////////////////////////////////////////////////////////////////////
//
// TACRTemporaryPageManager
//
////////////////////////////////////////////////////////////////////////////////
  TACRTemporaryPageManager = class (TACRPageManager)
   private
     FAllocatedPageMap:    TACRBitsArray;
     FAllocatedPageCount:  TACRPageNo;
     FTempPageFile:        TACRTemporaryStream;
     FMaxMemoryPageCount:  TACRPageNo;
     FMemoryPageManager:   TACRPageManager;
   protected
     procedure InitPage(aPage: TACRPage); override;
     function DirectAddPage: TACRPageNo; override;
   public
     procedure InternalAddPage(aPage: TACRPage); override;
     procedure InternalRemovePage(PageNo: TACRPageNo); override;
     procedure InternalReadPage(aPage: TACRPage); override;
     procedure InternalWritePage(aPage: TACRPage); override;

     constructor Create;
     destructor Destroy; override;
     procedure LoadFromStream(Stream: TStream); override;
     procedure SaveToStream(Stream: TStream); override;
  end; // TACRMemoryPageManager


////////////////////////////////////////////////////////////////////////////////
//
// TACRCache
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
// It is allowed to remove page before calling PutPage - for TACRBTreeIndex 
//
////////////////////////////////////////////////////////////////////////////////


  TACRCache = class(TObject)
{$IFDEF RELEASE_BUILD}
   private
{$ELSE}
   public
{$ENDIF}
    FSharedPages:     TACRSortedPageArray; // pages shared to all sessions
    FSharedSync:      TACRReadWriteThreadSyncByCriticalSections; // for FSharedPages
    LPageManager:     TACRPageManager;

    // members for managing page modifications made by active session
    FActiveSessionID: TACRSessionID;
    FAddedPages:      TACRPageArray; // added page numbers (value[i] = nil)
    FDeletedPages:    TACRPageArray; // deleted page numbers (value[i] = nil)
    FUpdatedPages:    TACRSortedPageArray; // updated pages
    FActiveSync:      TACRReadWriteThreadSyncByCriticalSections; // for all these stuff
    FState1,FState2:  Cardinal; // FState2 is for TableMetadata
    LParentCache:     TACRCache;
   protected
    procedure LockShared(Exclusive: Boolean);
    procedure UnlockShared;
    procedure LockActive(Exclusive: Boolean);
    procedure UnlockActive;
    function CreatePage(
                      PageNo:     TACRPageNo;
                      // state type of the locked object that calls this method
                      StateType:  TACRDBStateType;
                      // current state of the locked object that calls this method
                      State:      TACRState;
                      Parent:     TACRSortedPageArray
                       ): TACRPage; virtual;
    procedure RereadPage(
                          Page: TACRPage;
                          // state type of the locked object that calls this method
                          StateType:  TACRDBStateType;
                          // current state of the locked object that calls this method
                          State:      TACRState
                        );
    procedure StartDataModification(
                                    SessionID:  TACRSessionID;
                                    StateType:  TACRDBStateType;
                                    State:      TACRState
                                   );
    procedure CopyPage(Source: TACRPage; Dest: TACRPage);
    procedure PrepareUpdatedPage(Page: TACRPage);
    function SetPageState(
                            Page: TACRPage;
                            // current state of the locked object that calls this method
                            State1:      TACRState;
                            // additional state type of the locked object that calls this method
                            StateType2:  TACRDBStateType = dbstNone;
                            // additional current state of the locked object that calls this method
                            State2:      TACRState = 0
                          ): Boolean;
    // return true if not used page must be destroy and removed from shared cache
    function IsPageMustBeDestroyed(p: TACRPage): Boolean;
   public
    constructor Create(PageManager: TACRPageManager);
    destructor Destroy; override;
    // destroy all pages stored in the cache and clear it
    procedure ClearAllSharedPages;
    // analyzes memory usage and clear not used pages if needed
    procedure ClearSharedCache;
    // add page
    function AddPage(
                      SessionID: TACRSessionID;
                      // state type of the locked object that calls this method
                      StateType:  TACRDBStateType;
                      // current state of the locked object that calls this method
                      State:      TACRState;
                      // if true - page will not be used without calling GetPage
                      DoNotUse:   Boolean = False
                    ): TACRPage;
    // delete page
    procedure RemovePage(
                      SessionID:      TACRSessionID;
                      PageNo:         TACRPageNo;
                      StateType:      TACRDBStateType;
                      State:          TACRState
                        );
    // add multiple pages to cache - add page numbers to added pages lits 
    procedure AddPages(
                      // place page numbers of new allocated pages at the end of the array
                      Pages:                TACRPageArray;
                      // how much pages to add
                      NumPagesToAdd:        Cardinal;
                      // pages must be in consecutive order (n,n+1,n+2...)
                      ConsecutiveOrder:     Boolean;
                      SessionID:            TACRSessionID;
                      // state type of the locked object that calls this method
                      StateType:            TACRDBStateType;
                      // current state of the locked object that calls this method
                      State:                TACRState;
                      // if true - page will not be used without calling GetPage
                      DoNotUse:   Boolean = False
                    );
    // mark page as deleted - move to deleted pages list of the cache
    procedure RemovePages(
                      Pages:            TACRPageArray;
                      SessionID:        TACRSessionID;
                      // state type of the locked object that calls this method
                      StateType:            TACRDBStateType;
                      State:            TACRState;
                      NumPagesFromEnd:  Cardinal = 0
                          );
    // read existing page from cache or from PageManager (disk / memory / temporary)
    function GetPage(
                      SessionID:  TACRSessionID;
                      PageNo:     TACRPageNo;
                      // state type of the locked object that calls this method
                      StateType:  TACRDBStateType;
                      // current state of the locked object that calls this method
                      State:      TACRState;
                      // read current page data from page manager if not in cache
                      ReadPage:   Boolean = true;
                      // this page will be updated
                      UpdatePage: Boolean = false;
                      // the page should be updated and original will be copied to shared pages
                      MakeCopy:   Boolean = false
                     ): TACRPage;
    // page is read or updated
    procedure PutPage(Page: TACRPage);
    // must be called before updating page data
    procedure UpdatePage(
                      SessionID: TACRSessionID;
                      Page: TACRPage;
                      // state type of the locked object that calls this method
                      StateType:  TACRDBStateType;
                      // current state of the locked object that calls this method
                      State:      TACRState;
                      // the page should be updated and original will be copied to shared pages
                      MakeCopy:   Boolean = false
                         );
    // apply all changes made by active session
    procedure ApplyChanges(
                      // current state of the locked object that calls this method
                      State1:      TACRState;
                      // StateType2 is for table metadata state only
                      StateType2:  TACRDBStateType = dbstNone;
                      // State2 is for table metadata state only
                      State2:      TACRState = 0
                          );
    // cancel all changes made by active session
    procedure CancelChanges;
  end; // TACRCache


////////////////////////////////////////////////////////////////////////////////
//
// TACRDatabaseCache
// Database cache class.
// Used for caching TACRFreeSpaceManager pages as well as for storing
// cached pages from recently closed TACRTableData
//
////////////////////////////////////////////////////////////////////////////////


  TACRDatabaseCache = class (TACRCache)
   private
    FChildren: TList; // list of children table caches
    FChildrenSync:      TACRReadWriteThreadSyncBySingleCriticalSection;
   protected
    procedure LockChildren;
    procedure UnlockChildren;
   public
    constructor Create(PageManager:  TACRPageManager);
    destructor Destroy; override;
    procedure AddChildren(Cache: TACRTableCache);
    procedure DeleteChildren(Cache: TACRTableCache);
  end; // TACRDatabaseCache


////////////////////////////////////////////////////////////////////////////////
//
// TACRTableCache
// Table cache class.
// Used for caching all pages related to current table:
// FSharedPages - pages that can be read by all reading sessions (S lock)
//
//
////////////////////////////////////////////////////////////////////////////////


  TACRTableCache = class (TACRCache)
   private
    FTableID:             TACRTableID;
    FAddedToParentCache:  Boolean;
   protected
    function CreatePage(
                      PageNo:     TACRPageNo;
                      // state type of the locked object that calls this method
                      StateType:  TACRDBStateType;
                      // current state of the locked object that calls this method
                      State:      TACRState;
                      Parent:     TACRSortedPageArray
                       ): TACRPage; override;
   public
    constructor Create(
                          PageManager:  TACRPageManager;
                          ParentCache:  TACRCache
                      );
    destructor Destroy; override;
    procedure ImportPagesFromParent;
    procedure ExportPagesToParent;
   public
    property TableID: TACRTableID read FTableID write FTableID;
  end; // TACRTableCache


////////////////////////////////////////////////////////////////////////////////
//
// TACRCacheManagerThread
// Manages cache list and keep memory usage in specified limits
// if total amount of allocated memory more then high bound
// cache manager will destroy all not used shared pages in all caches
// if total amount of allocated memory more then low bound then
// cache manager will destroy all not used shared pages in database caches only
// if page was not used more then max page store time it will be removed from shared cache
//
////////////////////////////////////////////////////////////////////////////////

  TACRCacheManagerThread = class(TThread)
   private
    FDatabaseCacheList:   TList;
    FTableCacheList:      TList;
    FDatabaseThreadSync:  TACRReadWriteThreadSync;
    FTableThreadSync:     TACRReadWriteThreadSync;
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
    procedure AddCache(Cache: TACRCache);
    procedure RemoveCache(Cache: TACRCache);
  end; // TACRCacheManagerThread

var
    CacheManager:           TACRCacheManagerThread = nil;
    CacheManagerThreadSync: TACRReadWriteThreadSyncBySingleCriticalSection;

implementation

uses ACRBTree, ACRBaseEngine,
     ACRMemory                // last

;


////////////////////////////////////////////////////////////////////////////////
//
// TACRSortedPageArray
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Finds position for insert element
//------------------------------------------------------------------------------
function TACRSortedPageArray.FindPositionForInsert(key: TACRPageNo): Integer;
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
function TACRSortedPageArray.FindPosition(key: Integer): Integer;
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
procedure TACRSortedPageArray.InsertByPosition(ItemNo: Integer; key: TACRPageNo; value: TACRPage);
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
        (itemCount - itemNo-1) * sizeOf(TACRPage));
    KeyItems[itemNo] := key;
    ValueItems[itemNo] := value;
   end;
end; // InsertByPosition


//------------------------------------------------------------------------------
// Delete an element at specified position
//------------------------------------------------------------------------------
procedure TACRSortedPageArray.DeleteByPosition(ItemNo: Integer);
begin
 if (itemNo < itemCount-1) then
  begin
   Move(KeyItems[itemNo+1],KeyItems[itemNo],
       (itemCount - itemNo-1) * sizeOf(Integer));
   Move(ValueItems[itemNo+1],ValueItems[itemNo],
       (itemCount - itemNo-1) * sizeOf(TACRPage));
  end;
 Dec(ItemCount);
 SetSize(ItemCount);
end; // DeleteByPosition


//------------------------------------------------------------------------------
// get key if index valid
//------------------------------------------------------------------------------
function TACRSortedPageArray.GetKey(ItemIndex: Integer): Integer;
begin
  if ((ItemIndex >= 0) and (ItemIndex < ItemCount)) then
    Result := KeyItems[ItemIndex]
  else
    Result := INVALID_PAGE_NO;
end; // GetKey


//------------------------------------------------------------------------------
// set key if index valid
//------------------------------------------------------------------------------
procedure TACRSortedPageArray.SetKey(ItemIndex: Integer; Key: Integer);
begin
  if ((ItemIndex >= 0) and (ItemIndex < ItemCount)) then
    KeyItems[ItemIndex] := Key;
end; // SetKey


//------------------------------------------------------------------------------
// get value if index valid
//------------------------------------------------------------------------------
function TACRSortedPageArray.GetValue(ItemIndex: Integer): TACRPage;
begin
  if ((ItemIndex >= 0) and (ItemIndex < ItemCount)) then
    Result := ValueItems[ItemIndex]
  else
    Result := nil;
end; // GetValue


//------------------------------------------------------------------------------
// set value if index valid
//------------------------------------------------------------------------------
procedure TACRSortedPageArray.SetValue(ItemIndex: Integer; Value: TACRPage);
begin
  if ((ItemIndex >= 0) and (ItemIndex < ItemCount)) then
    ValueItems[ItemIndex] := Value;
end; // SetValue


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TACRSortedPageArray.Create(size: Integer; DefaultAllocBy: Integer; MaximumAllocBy: Integer);
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
destructor TACRSortedPageArray.Destroy;
begin
  KeyItems := nil;
  ValueItems := nil;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Delete an element by specified key
//------------------------------------------------------------------------------
procedure TACRSortedPageArray.Delete(key: Integer; IgnoreErrors: Boolean);
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
    raise EACRException.Create(11799,ErrorLInvalidItemCount,[itemCount]);
   if ((itemCount = 1) and (KeyItems[0] = key)) then
    DeleteByPosition(0)
   else
    begin
     pos := FindPosition(key);
     if (pos < 0) then
       raise EACRException.Create(11800,ErrorLElementNotFound,[key,itemCount]);
     DeleteByPosition(pos);
    end;
  end; // raise exception if key not found
end; // Delete


//------------------------------------------------------------------------------
// Finds value for specified key
// returns -1 if element was not found
//------------------------------------------------------------------------------
function TACRSortedPageArray.Find(key: Integer; out value: TACRPage): Integer;
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
procedure TACRSortedPageArray.Insert(key: TACRPageNo; value: TACRPage);
var pos : Integer;
begin
 if (itemCount <= 0) then
  InsertByPosition(0,key,value)
 else
  if (itemCount = 1) then
   begin
    if (KeyItems[0] = key) then
     raise EACRException.Create(11802,ErrorLDuplicatePage,[key,0])
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
       raise EACRException.Create(11803,ErrorLDuplicatePage,[key,pos]);
    InsertByPosition(pos,key,value);
   end;
end; // Insert


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TACRSortedPageArray.SetSize(newSize: Integer);
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
// TACRPageArray
// used for storing pages in TACRCache without sorting
// array raises exception on attempt to add duplicate page
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return item if exists
//------------------------------------------------------------------------------
function TACRPageArray.GetItem(ItemIndex: Integer): TACRPageNo;
begin
  if (ItemIndex >= 0) and (ItemIndex < FItemCount) then
   Result := FItems[ItemIndex]
  else
   Result := INVALID_PAGE_NO;
end; // GetItem


//------------------------------------------------------------------------------
// set item if exists
//------------------------------------------------------------------------------
procedure TACRPageArray.SetItem(ItemIndex: Integer; PageNo: TACRPageNo);
begin
  if (ItemIndex >= 0) and (ItemIndex < FItemCount) then
   FItems[ItemIndex] := PageNo;
end; // GetItem


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TACRPageArray.Create(
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
end; // TACRPageArray.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TACRPageArray.Destroy;
begin
 FItems := nil;
 inherited Destroy;
end; // TACRPageArray.Destroy;


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TACRPageArray.Assign(v: TACRPageArray);
var  i,n: Integer;
begin
  n := v.Count;
  SetSize(n);
  if (n > 0) then
   Move(v.FItems[0],FItems[0],n * sizeOf(TACRPageNo));
end; // Assign


//------------------------------------------------------------------------------
// append pages from end, if NumPagesToAdd = 0 then append all pages from source array
//------------------------------------------------------------------------------
function TACRPageArray.AppendFrom(v: TACRPageArray; NumPagesToAdd: Cardinal): Cardinal;
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
     Move(v.FItems[start],FItems[n],Result * SizeOf(TACRPageNo));
   end;
end; // AppendFrom


//------------------------------------------------------------------------------
// move pages from end, if NumPagesToAdd = 0 then move all pages from source array
//------------------------------------------------------------------------------
function TACRPageArray.MoveFrom(v: TACRPageArray; NumPagesToAdd: Cardinal): Cardinal;
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
     Move(v.FItems[i],FItems[n],Result * SizeOf(TACRPageNo));
     // cut the source array
     v.SetSize(i);
   end;
end; // AppendFrom


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TACRPageArray.SetSize(newSize: Integer);
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
function TACRPageArray.Insert(value: TACRPageNo; InsertIfNotExist: Boolean): Integer;
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
    raise EACRException.Create(11812,ErrorLDuplicatePage,[value,ItemIndex]);
 Inc(FItemCount);
 SetSize(FItemCount);
 Result := FItemCount-1;
 FItems[Result] := value;
end; // Insert


//------------------------------------------------------------------------------
// delete by position in array
//------------------------------------------------------------------------------
procedure TACRPageArray.DeleteByPosition(pos: Integer);
var n:  Integer;
begin
 n := FItemCount-1;
 if (pos < n) then
  Move(FItems[pos+1],FItems[pos],
      (n - pos) * sizeOf(TACRPageNo));
 Dec(FItemCount);
 SetSize(FItemCount);
end; // DeleteByPosition


//------------------------------------------------------------------------------
// Delete an element at specified position
//------------------------------------------------------------------------------
procedure TACRPageArray.Delete(value: TACRPageNo);
var ItemIndex: Integer;
begin
 ItemIndex := Find(value);
 if (ItemIndex >= 0) then
  DeleteByPosition(ItemIndex);
end; // Delete


//------------------------------------------------------------------------------
// returns index in Items or -1 if not found
//------------------------------------------------------------------------------
function TACRPageArray.Find(value: TACRPageNo): Integer;
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
// TACRPage
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// GetPageHEader
//------------------------------------------------------------------------------
function TACRPage.GetPageHeader: PACRDiskPageHeader;
begin
  Result := PACRDiskPageHeader(FPageBuffer);
end; // GetPageHeader


//------------------------------------------------------------------------------
// GetPageData
//------------------------------------------------------------------------------
function TACRPage.GetPageHeaderSize: Integer;
begin
  Result := FPageHeaderSize;
end;//GetPageHeaderSize


//------------------------------------------------------------------------------
// GetPageData
//------------------------------------------------------------------------------
function TACRPage.GetPageData: TACRPageBuffer;
begin
  Result := TACRPageBuffer(FPageBuffer + PageHeaderSize);
end;//GetPageData


//------------------------------------------------------------------------------
// GetPageDataSize
//------------------------------------------------------------------------------
function TACRPage.GetPageDataSize: Integer;
begin
  Result := PageSize - PageHeaderSize;
end;//GetPageDataSize


//------------------------------------------------------------------------------
// GetPageSize
//------------------------------------------------------------------------------
function TACRPage.GetPageSize: Integer;
begin
  Result := FPageSize;
end;// GetPageSize


//------------------------------------------------------------------------------
// InitHeader
//------------------------------------------------------------------------------
procedure TACRPage.InitHeader;
begin
  PageHeader.Signature := ACRDiskPageSignature;
  PageHeader.PageType := ACRPageTypeIDUnknown;
  PageHeader.NextPageNo := INVALID_PAGE_NO;
  PageHeader.CRC32 := 0;
  PageHeader.CRCType := 0;
  PageHeader.CipherType := 0;
  PageHeader.ObjectID := INVALID_OBJECT_ID;
end;//InitHeader


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRPage.Create(aPageManager: TACRPageManager; aCache: TACRCache);
begin
  if (aPageManager = nil) then
   raise EACRException.Create(11867,ErrorLNilPointer);
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
  FThreadSync := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
  FLastAccessTime := aaGetTickCount;
  FTableID := INVALID_OBJECT_ID;
end;// Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TACRPage.Destroy;
begin
  if (FOwnBuffer) then
    FreeAndNilPageBuffer;
  FThreadSync.Free;
end;// Destroy


//------------------------------------------------------------------------------
// ClearPageBuffer
//------------------------------------------------------------------------------
procedure TACRPage.ClearPageBuffer;
begin
  FillChar(FPageBuffer^,PageSize,00);
end;// ClearPageBuffer


//------------------------------------------------------------------------------
// AllocPageBuffer
//------------------------------------------------------------------------------
procedure TACRPage.AllocPageBuffer;
begin
  FPageBuffer := MemoryManager.AllocMem(PageSize);
  InitHeader;
end;// AllocPageBuffer


//------------------------------------------------------------------------------
// FreeAndNilPageBuffer
//------------------------------------------------------------------------------
procedure TACRPage.FreeAndNilPageBuffer;
begin
  if (FPageBuffer <> nil) then
   begin
    if (ACR_ENCRYPTED_DB_USED) then
     FillChar(FPageBuffer^,FPageSize,$00);
    MemoryManager.FreeAndNilMem(FPageBuffer);
   end;
end;// FreeAndNilPageBuffer


//------------------------------------------------------------------------------
// EnlargePageBuffer
//------------------------------------------------------------------------------
procedure TACRPage.EnlargePageBuffer(NewSize: Integer);
var
  NewBuffer: PAnsiChar;
begin
  if (FPageBuffer = nil) then
   raise EACRException.Create(20038, ErrorAInvalidPageBuffer);
  if (NewSize < PageSize) then
   raise EACRException.Create(20039, ErrorAInvalidPageModification);

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
// lock page - used in TACRCache.RereadPage
//------------------------------------------------------------------------------
procedure TACRPage.Lock;
begin
  FThreadSync.Lock(True);
end; // Lock


//------------------------------------------------------------------------------
// unlock page - used in TACRCache.RereadPage
//------------------------------------------------------------------------------
procedure TACRPage.Unlock;
begin
  FThreadSync.Unlock;
end; // Unlock


//------------------------------------------------------------------------------
// return true if page header has invalid signatur and the pages is not from index system
//------------------------------------------------------------------------------
function TACRPage.IsHeaderCorrupted: Boolean;
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
               (Byte(PageHeader.Signature[0]) <> Byte(ACRDiskPageSignature[1]))
               or
               (Byte(PageHeader.Signature[1]) <> Byte(ACRDiskPageSignature[2]))
               or
               (Byte(PageHeader.Signature[2]) <> Byte(ACRDiskPageSignature[3]))
               or
               (Byte(PageHeader.Signature[3]) <> Byte(ACRDiskPageSignature[4]))
               );
    end;
   end;
end; // IsHeaderCorrupted




////////////////////////////////////////////////////////////////////////////////
//
// TACRPageController
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// SetPageNo
//------------------------------------------------------------------------------
procedure TACRPageController.SetPageNo(Value: TACRPageNo);
begin
  LPage.PageNo := Value;
end;// SetPageNo


//------------------------------------------------------------------------------
// GetPageNo
//------------------------------------------------------------------------------
function TACRPageController.GetPageNo: TACRPageNo;
begin
  Result := LPage.PageNo;
end;// GetPageNo


//------------------------------------------------------------------------------
// GetPageSize
//------------------------------------------------------------------------------
function TACRPageController.GetPageSize: Integer;
begin
  Result := LPage.PageSize;
end;// GetPageSize


//------------------------------------------------------------------------------
// SetPageBuffer
//------------------------------------------------------------------------------
procedure TACRPageController.SetPageBuffer(Value: TACRPageBuffer);
begin
  LPage.PageBuffer := Value;
end;// SetPageBuffer


//------------------------------------------------------------------------------
// GetPageBuffer
//------------------------------------------------------------------------------
function TACRPageController.GetPageBuffer: TACRPageBuffer;
begin
  Result := LPage.PageBuffer;
end;// GetPageBuffer


//------------------------------------------------------------------------------
// SetOwnBuffer
//------------------------------------------------------------------------------
procedure TACRPageController.SetOwnBuffer(Value: Boolean);
begin
  LPage.OwnBuffer := Value;
end;// SetOwnBuffer


//------------------------------------------------------------------------------
// GetOwnBuffer
//------------------------------------------------------------------------------
function TACRPageController.GetOwnBuffer: Boolean;
begin
  Result := LPage.OwnBuffer;
end;// GetOwnBuffer


//------------------------------------------------------------------------------
// SetUseCount
//------------------------------------------------------------------------------
procedure TACRPageController.SetUseCount(Value: Integer);
begin
  LPage.UseCount := Value;
end;// SetUseCount


//------------------------------------------------------------------------------
// GetUseCount
//------------------------------------------------------------------------------
function TACRPageController.GetUseCount: Integer;
begin
  Result := LPage.UseCount;
end;// GetUseCount


//------------------------------------------------------------------------------
// GetPageManager
//------------------------------------------------------------------------------
function TACRPageController.GetPageManager: TACRPageManager;
begin
  Result := LPage.PageManager;
end;// GetPageManager


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRPageController.Create(Page: TACRPage);
begin
  LPage := Page;
end;// Create


//------------------------------------------------------------------------------
// EnlargePageBuffer
//------------------------------------------------------------------------------
procedure TACRPageController.EnlargePageBuffer(NewSize: Integer);
begin
  LPage.EnlargePageBuffer(NewSize);
end;// EnlargePageBuffer



////////////////////////////////////////////////////////////////////////////////
//
// TACRPageManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return page count
//------------------------------------------------------------------------------
function TACRPageManager.GetPageCount: TACRPageNo;
begin
  Result := FPageCount;
end; // GetPageCount


//------------------------------------------------------------------------------
// LoadFromStream
//------------------------------------------------------------------------------
procedure TACRPageManager.LoadFromStream(Stream: TStream);
begin
;
end; // LoadFromStream


//------------------------------------------------------------------------------
// SaveToStream
//------------------------------------------------------------------------------
procedure TACRPageManager.SaveToStream(Stream: TStream);
begin
;
end; // SaveToStream


//------------------------------------------------------------------------------
// direct add page
//------------------------------------------------------------------------------
function TACRPageManager.DirectAddPage: TACRPageNo;
begin
  Result := INVALID_PAGE_NO;
end; // DirectAddPage



//------------------------------------------------------------------------------
// InitPage
//------------------------------------------------------------------------------
procedure TACRPageManager.InitPage(aPage: TACRPage);
begin
end; // InitPage


//------------------------------------------------------------------------------
// add multiple pages
//------------------------------------------------------------------------------
procedure TACRPageManager.DirectAddPages(
                          // place page numbers of new allocated pages at the end of the array
                          Pages:                  TACRPageArray;
                          // how much pages to add
                          const NumPagesToAdd:    Cardinal;
                          // pages must be in consecutive order (n,n+1,n+2...)
                          const ConsecutiveOrder: Boolean
                         );
var i:        Cardinal;
    PageNo:   TACRPageNo;
    page:     TACRPage;
begin
// for memory / temporary engines
{ TODO -oLeo : implement it correctly }
  page := TACRPage.Create(Self,nil);
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
procedure TACRPageManager.DirectRemovePages(Pages: TACRPageArray; NumPagesFromEnd: Cardinal);
var i:        Integer;
    n:        Cardinal;
    PageNo:   TACRPageNo;
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
function TACRPageManager.IsSystemPage(PageNo: TACRPageNo): Boolean;
begin
  Result := False;
end; // IsSystemPage


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRPageManager.Create;
begin
  FExclusive := False;
  FReadOnly := False;
  FDiskPageManager := False;
  FCache := TACRDatabaseCache.Create(Self);
end;// Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TACRPageManager.Destroy;
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
function TACRPageManager.GetPage(
                SessionID:  TACRSessionID;
                PageNo:     TACRPageNo;
                // state type of the locked object that calls this method
                StateType:  TACRDBStateType;
                // current state of the locked object that calls this method
                State:      TACRState;
                // read current page data from page manager if not in cache
                ReadPage:   Boolean = true;
                // this page will be updated
                UpdatePage: Boolean = false;
                // the page should be updated and original will be copied to shared pages
                MakeCopy:   Boolean = false
               ): TACRPage;
begin
  Result := FCache.GetPage(SessionID,PageNo,StateType,State,ReadPage,UpdatePage,MakeCopy);
end; // GetPage


//------------------------------------------------------------------------------
// put page
//------------------------------------------------------------------------------
procedure TACRPageManager.PutPage(aPage: TACRPage);
begin
  FCache.PutPage(aPage);
end; // PutPage


//------------------------------------------------------------------------------
// must be called before updating page data
//------------------------------------------------------------------------------
procedure TACRPageManager.UpdatePage(
                      SessionID: TACRSessionID;
                      Page: TACRPage;
                      // state type of the locked object that calls this method
                      StateType:  TACRDBStateType;
                      // current state of the locked object that calls this method
                      State:      TACRState;
                      // the page should be updated and original will be copied to shared pages
                      MakeCopy:   Boolean = false
                     );
begin
  FCache.UpdatePage(SessionID,Page,StateType,State,MakeCopy);
end; // UpdatePage


//------------------------------------------------------------------------------
// apply changes
//------------------------------------------------------------------------------
procedure TACRPageManager.ApplyChanges(
                      // current state of the locked object that calls this method
                      State1:      TACRState;
                      // StateType2 is for table metadata state only
                      StateType2:  TACRDBStateType = dbstNone;
                      // State2 is for table metadata state only
                      State2:      TACRState = 0
                                      );
begin
  FCache.ApplyChanges(State1,StateType2,State2);
end; // ApplyChanges


//------------------------------------------------------------------------------
// cancel changes
//------------------------------------------------------------------------------
procedure TACRPageManager.CancelChanges;
begin
  FCache.CancelChanges;
end; // CancelChanges


//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// flush file buffer
//------------------------------------------------------------------------------
procedure TACRPageManager.FlushFileBuffers;
begin
;
end; // FlushFileBuffers


//------------------------------------------------------------------------------
// clear cache
//------------------------------------------------------------------------------
procedure TACRPageManager.ClearCache;
begin
  FCache.ClearAllSharedPages;
end; // ClearCache


//------------------------------------------------------------------------------
// read page directly without any cache
//------------------------------------------------------------------------------
procedure TACRPageManager.DirectReadPage(aPage: TACRPage);
begin
  if (aPage = nil) then raise EACRException.Create(11868,ErrorLNilPointer);
  if (aPage.PageBuffer = nil) then raise EACRException.Create(11869,ErrorLNilPointer);
  InternalReadPage(aPage);
end; // DirectGetPage


//------------------------------------------------------------------------------
// write page directly without any cache
//------------------------------------------------------------------------------
procedure TACRPageManager.DirectWritePage(aPage: TACRPage);
begin
  if (aPage = nil) then raise EACRException.Create(11870,ErrorLNilPointer);
  if (aPage.PageBuffer = nil) then raise EACRException.Create(11871,ErrorLNilPointer);
  InternalWritePage(aPage);
end; // DirectWritePage


//------------------------------------------------------------------------------
// remove page directly without any cache
//------------------------------------------------------------------------------
procedure TACRPageManager.DirectRemovePage(PageNo: TACRPageNo);
begin
  InternalRemovePage(PageNo);
end; // DirectRemovePage


////////////////////////////////////////////////////////////////////////////////
//
// TACRMemoryPageManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TACRMemoryPageManager.Lock(bExclusive: Boolean);
begin
  FThreadSync.Lock(bExclusive);
end; // Lock


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TACRMemoryPageManager.Unlock;
begin
  FThreadSync.Unlock;
end; // Unlock


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TACRMemoryPageManager.LoadFromStream(Stream: TStream);
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
procedure TACRMemoryPageManager.SaveToStream(Stream: TStream);
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
procedure TACRMemoryPageManager.InitPage(aPage: TACRPage);
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
function TACRMemoryPageManager.DirectAddPage: TACRPageNo;
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
    raise EACRException.Create(20037, ErrorANotReleasedPageIsAllocated);
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
procedure TACRMemoryPageManager.InternalAddPage(aPage: TACRPage);
var
  PageNo: TACRPageNo;
begin
  PageNo := DirectAddPage;
  aPage.PageNo := PageNo;
  InitPage(aPage);
end;// InternalAddPage


//------------------------------------------------------------------------------
// InternalRemovePage
//------------------------------------------------------------------------------
procedure TACRMemoryPageManager.InternalRemovePage(PageNo: TACRPageNo);
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
procedure TACRMemoryPageManager.InternalReadPage(aPage: TACRPage);
begin
  if (not FAllocatedPageMap.GetBit(aPage.PageNo)) then
   raise EACRException.Create(10392, ErrorANotReleasedPageIsAllocated);
  if (aPage.OwnBuffer) then
   aPage.FreeAndNilPageBuffer;
  InitPage(aPage);
end;// InternalReadPage


//------------------------------------------------------------------------------
// InternalWritePage
//------------------------------------------------------------------------------
procedure TACRMemoryPageManager.InternalWritePage(aPage: TACRPage);
begin
  if (aPage = nil) then
    raise EACRException.Create(12294,ErrorLNilPointer);
  if (aPage.IsHeaderCorrupted) then
    raise EACRException.Create(12295,ErrorLPageHeaderIsCorrupted,
      [aPage.PageNo,Integer(aPage.StateType),Self.ClassName,IntToHex(Integer(Self),8)]);
  if (not FAllocatedPageMap.GetBit(aPage.PageNo)) then
   raise EACRException.Create(10393, ErrorANotReleasedPageIsAllocated);
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
constructor TACRMemoryPageManager.Create;
begin
  inherited Create;
  FAllocatedPageMap := TACRBitsArray.Create;
  SetLength(FDataPtrs, 0);
  FAllocatedPageCount := 0;
  FPageCount := 0;
  FPageHeaderSize := 0;
  FPageSize := ACRDefaultMemoryPageSize;
  FPageDataSize := FPageSize;
  FAllocateBy := 50;
  FThreadSync := TACRReadWriteThreadSyncByCriticalSections.Create(False,Self);
end;// Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRMemoryPageManager.Destroy;
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
aaWriteToLog('TACRMemoryPageManager.Destroy Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message);
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
aaWriteToLog('TACRMemoryPageManager.Destroy Error#2 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message);
end;
{$ENDIF}
  end;
  if (FPageCount > 0) then
   raise EACRException.Create(20023, ErrorAIndexPagesNotReleased);
end;// Destroy



////////////////////////////////////////////////////////////////////////////////
//
// TACRTemporaryPageManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// init page
//------------------------------------------------------------------------------
procedure TACRTemporaryPageManager.InitPage(aPage: TACRPage);
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
function TACRTemporaryPageManager.DirectAddPage: TACRPageNo;
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
     FTempPageFile := TACRTemporaryStream.Create;
    FTempPageFile.Size := 0;
   end;
  FAllocatedPageCount := Result +1;
  FAllocatedPageMap.Size := FAllocatedPageCount;
  FAllocatedPageMap.SetBit(Result, True);
end; // DirectAddPage


//------------------------------------------------------------------------------
// InternalAddPage
//------------------------------------------------------------------------------
procedure TACRTemporaryPageManager.InternalAddPage(aPage: TACRPage);
var
  PageNo: TACRPageNo;
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
     FTempPageFile := TACRTemporaryStream.Create;
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
procedure TACRTemporaryPageManager.InternalRemovePage(PageNo: TACRPageNo);
begin
  Dec(FPageCount);
  FAllocatedPageMap.SetBit(PageNo, False);
  if (PageNo < FMaxMemoryPageCount) then
   FMemoryPageManager.InternalRemovePage(PageNo)
end;// InternalRemovePage


//------------------------------------------------------------------------------
// InternalReadPage
//------------------------------------------------------------------------------
procedure TACRTemporaryPageManager.InternalReadPage(aPage: TACRPage);
begin
  if (not FAllocatedPageMap.GetBit(aPage.PageNo)) then
   raise EACRException.Create(10396, ErrorANotReleasedPageIsAllocated);
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
procedure TACRTemporaryPageManager.InternalWritePage(aPage: TACRPage);
begin
  if (aPage = nil) then
    raise EACRException.Create(12292,ErrorLNilPointer);
  if (aPage.IsHeaderCorrupted) then
    raise EACRException.Create(12293,ErrorLPageHeaderIsCorrupted,
      [aPage.PageNo,Integer(aPage.StateType),Self.ClassName,IntToHex(Integer(Self),8)]);
  if (not FAllocatedPageMap.GetBit(aPage.PageNo)) then
   raise EACRException.Create(10397, ErrorANotReleasedPageIsAllocated);
  if (aPage.PageNo < FMaxMemoryPageCount) then
   FMemoryPageManager.InternalWritePage(aPage)
  else
   begin
    if (FTempPageFile = nil) then
     FTempPageFile := TACRTemporaryStream.Create;
    FTempPageFile.Position := (aPage.PageNo - FMaxMemoryPageCount) * FPageSize;
    FTempPageFile.WriteBuffer(aPage.PageBuffer^, FPageSize);
   end;
end;// InternalWritePage


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRTemporaryPageManager.Create;
begin
  inherited Create;
  FAllocatedPageMap := TACRBitsArray.Create;
  FAllocatedPageCount := 0;
  FPageCount := 0;
  FPageHeaderSize := 0;
  FPageSize := ACRDefaultTemporaryPageSize;
  FPageDataSize := FPageSize;
  FMaxMemoryPageCount := ACRTempPageManagerMaxMemoryPageCount;
  FTempPageFile := nil;
  FMemoryPageManager := TACRMemoryPageManager.Create;
end;// Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRTemporaryPageManager.Destroy;
begin
  if (FPageCount > 0) then
   raise EACRException.Create(20036, ErrorAIndexPagesNotReleased);
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
procedure TACRTemporaryPageManager.LoadFromStream(Stream: TStream);
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
     FTempPageFile := TACRTemporaryStream.Create
    else
     FTempPageFile.Size := 0;
    FTempPageFile.LoadFromStreamWithPosition(Stream,Stream.Position,Size)
   end;
end; // LoadFromStream


//------------------------------------------------------------------------------
// SaveToStream
//------------------------------------------------------------------------------
procedure TACRTemporaryPageManager.SaveToStream(Stream: TStream);
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
// TACRCache
// Base cache class.
// It can be used by different threads and
// must provide none-blocking parallel reading access.
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// lock shared pages
//------------------------------------------------------------------------------
procedure TACRCache.LockShared(Exclusive: Boolean);
begin
  FSharedSync.Lock(Exclusive);
end; // LockShared


//------------------------------------------------------------------------------
// unlock shared pages
//------------------------------------------------------------------------------
procedure TACRCache.UnlockShared;
begin
  FSharedSync.Unlock;
end; // UnlockShared


//------------------------------------------------------------------------------
// lock active
//------------------------------------------------------------------------------
procedure TACRCache.LockActive(Exclusive: Boolean);
begin
  if (FActiveSync = nil) then
    raise EACRException.Create(11804,ErrorLNilPointer);
  FActiveSync.Lock(Exclusive);
end; // LockActive


//------------------------------------------------------------------------------
// unlock active
//------------------------------------------------------------------------------
procedure TACRCache.UnlockActive;
begin
  if (FActiveSync = nil) then
    raise EACRException.Create(11805,ErrorLNilPointer);
  FActiveSync.Unlock;
end; // UnlockActive


//------------------------------------------------------------------------------
// create new page
//------------------------------------------------------------------------------
function TACRCache.CreatePage(
                  PageNo:     TACRPageNo;
                  // state type of the locked object that calls this method
                  StateType:  TACRDBStateType;
                  // current state of the locked object that calls this method
                  State:      TACRState;
                  Parent:     TACRSortedPageArray
                   ): TACRPage;
begin
  Result := TACRPage.Create(LPageManager,Self);
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
procedure TACRCache.RereadPage(
                      Page: TACRPage;
                      // state type of the locked object that calls this method
                      StateType:  TACRDBStateType;
                      // current state of the locked object that calls this method
                      State:      TACRState
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
procedure TACRCache.StartDataModification(
                                    SessionID:  TACRSessionID;
                                    StateType:  TACRDBStateType;
                                    State:      TACRState
                                         );
begin
  if ((FActiveSessionID <> INVALID_SESSION_ID) and (FActiveSessionID <> SessionID)) then
   raise EACRException.Create(11828,ErrorLDataModificationAlreadyStarted,
    [SessionID,FActiveSessionID,Integer(StateType),State,Self.ClassName,IntToHex(Integer(Self),8)]);
  if (FActiveSessionID = INVALID_SESSION_ID) then
   begin
    FActiveSessionID := SessionID;
    // if first modification - create all necessary objects
    if (FActiveSync = nil) then
     begin
      FActiveSync := TACRReadWriteThreadSyncByCriticalSections.Create(False,Self,'ActiveSync');
      FAddedPages := TACRPageArray.Create;
      FDeletedPages := TACRPageArray.Create;
      FUpdatedPages := TACRSortedPageArray.Create;
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
procedure TACRCache.CopyPage(Source: TACRPage; Dest: TACRPage);
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
procedure TACRCache.PrepareUpdatedPage(Page: TACRPage);
begin
  Page.LastAccessTime := aaGetTickCount;
  Page.UseCount := 0;
  Page.Updated := false;
  Page.Parent := FSharedPages;
end; // PrepareUpdatedPage


//------------------------------------------------------------------------------
// set page state in ApplyChanges
//------------------------------------------------------------------------------
function TACRCache.SetPageState(
                        Page: TACRPage;
                        // current state of the locked object that calls this method
                        State1:      TACRState;
                        // additional state type of the locked object that calls this method
                        StateType2:  TACRDBStateType = dbstNone;
                        // additional current state of the locked object that calls this method
                        State2:      TACRState = 0
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
function TACRCache.IsPageMustBeDestroyed(p: TACRPage): Boolean;
var AllocatedRAM: Int64;
begin
  Result := (p.UseCount = 0);
  if (Result) then
   begin
    Result := (ACRGetTickCountDiff(aaGetTickCount,p.LastAccessTime) >
               ACRCacheManagerThreadMaxPageStoreTime);
    if (not Result) then
     begin
      AllocatedRAM := MemoryManager.TotalMemAllocated;
      Result := (AllocatedRAM >= ACRCacheManagerThreadRAMLowBound) or
                ((Self is TACRDatabaseCache) and
                 (AllocatedRAM >= ACRCacheManagerThreadRAMLowBound));
     end;
   end;
end; // IsPageMustBeDestroyed


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRCache.Create(PageManager: TACRPageManager);
begin
  inherited Create;
{$IFDEF TACRCacheManagerThread_ON}
  if (CacheManager = nil) then
   begin
    CacheManagerThreadSync.Lock(True);
    try
      if (CacheManager = nil) then
       CacheManager := TACRCacheManagerThread.Create(False);
      CacheManager.AddCache(Self);
    finally
      CacheManagerThreadSync.Unlock;
    end;
   end
  else
   CacheManager.AddCache(Self);
{$ENDIF}
  LParentCache := nil;
  FSharedPages := TACRSortedPageArray.Create;
  FSharedSync := TACRReadWriteThreadSyncByCriticalSections.Create(False,Self,'SharedSync');
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
destructor TACRCache.Destroy;
begin
{$IFDEF TACRCacheManagerThread_ON}
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
procedure TACRCache.ClearAllSharedPages;
var i: Integer;
    p: TACRPage;
begin
  LockShared(True);
  try
    for i := 0 to FSharedPages.Count-1 do
     begin
      try
        p := FSharedPages.Values[i];
        if (p <> nil) then
          TACRPage(p).Free;
      except
{$IFDEF DEBUG_ONERROR}
on e: Exception do
begin
aaWriteToLog('TACRCache.ClearAllSharedPages Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message);
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
procedure TACRCache.ClearSharedCache;
var i: Integer;
    p: TACRPage;
begin
{$IFDEF DEBUG_TRACE_TACRCache_ClearSharedCache}
aaWriteToLog('> TACRCache.ClearSharedCache');
try
{$ENDIF}
  LockShared(True);
  try
    i := 0;
{$IFDEF DEBUG_TRACE_TACRCache_ClearSharedCache}
aaWriteToLog('1. TACRCache.ClearSharedCache, FSharedPages.Count = '+IntToStr(FSharedPages.Count));
{$ENDIF}
    while (i < FSharedPages.Count) do
     begin
      try
{$IFDEF DEBUG_TRACE_TACRCache_ClearSharedCache}
aaWriteToLog('2. TACRCache.ClearSharedCache, i = '+IntToStr(i));
{$ENDIF}
        p := FSharedPages.Values[i];
{$IFDEF DEBUG_TRACE_TACRCache_ClearSharedCache}
aaWriteToLog('3. TACRCache.ClearSharedCache, p = '+IntToHex(Integer(p),8));
{$ENDIF}
        if (p = nil) then
         FSharedPages.Delete(i)
        else
        if (IsPageMustBeDestroyed(p)) then
          begin
{$IFDEF DEBUG_TRACE_TACRCache_ClearSharedCache}
aaWriteToLog('4. TACRCache.ClearSharedCache, i = '+IntToStr(i));
{$ENDIF}
            TACRPage(p).Free;
{$IFDEF DEBUG_TRACE_TACRCache_ClearSharedCache}
aaWriteToLog('5. TACRCache.ClearSharedCache, i = '+IntToStr(i));
{$ENDIF}
            FSharedPages.DeleteByPosition(i);
          end
        else
         Inc(i);
{$IFDEF DEBUG_TRACE_TACRCache_ClearSharedCache}
aaWriteToLog('6. TACRCache.ClearSharedCache, i = '+IntToStr(i));
{$ENDIF}
      except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRCache.ClearSharedCache Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
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
{$IFDEF DEBUG_TRACE_TACRCache_ClearSharedCache}
aaWriteToLog('< TACRCache.ClearSharedCache');
except
 on e: Exception do
  begin
    aaWriteToLog('Error in TACRCache.ClearSharedCache'+#13#10+e.Message);
    raise;
  end;
end;
{$ENDIF}
end; // ClearSharedCache


//------------------------------------------------------------------------------
// add page to the page manager
//------------------------------------------------------------------------------
function TACRCache.AddPage(
                      SessionID: TACRSessionID;
                      // state type of the locked object that calls this method
                      StateType:  TACRDBStateType;
                      // current state of the locked object that calls this method
                      State:      TACRState;
                      DoNotUse:   Boolean = False
                    ): TACRPage;
var i,n:        Integer;
    pageNo:     TACRPageNo;
    pageIndex:  Integer;
    page:       TACRPage;
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
procedure TACRCache.RemovePage(
                      SessionID:      TACRSessionID;
                      PageNo:         TACRPageNo;
                      StateType:      TACRDBStateType;
                      State:          TACRState
                              );
var i,n:        Integer;
    pageIndex:  Integer;
    page:       TACRPage;
begin
  StartDataModification(SessionID,StateType,State);
  LockActive(True);
  try
    pageIndex := FDeletedPages.Find(PageNo);
    if (pageIndex >= 0) then
     raise EACRException.Create(11807,ErrorLDuplicatePage,[PageNo,pageIndex]);
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
aaWriteToLog('TACRCache.RemovePage Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
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
procedure TACRCache.AddPages(
                  // place page numbers of new allocated pages at the end of the array
                  Pages:                TACRPageArray;
                  // how much pages to add
                  NumPagesToAdd:        Cardinal;
                  // pages must be in consecutive order (n,n+1,n+2...)
                  ConsecutiveOrder:     Boolean;
                  SessionID:            TACRSessionID;
                  // state type of the locked object that calls this method
                  StateType:            TACRDBStateType;
                  // current state of the locked object that calls this method
                  State:                TACRState;
                  DoNotUse:             Boolean = False
                );

procedure SetupPage(page: TACRPage);
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
    pageNo:         TACRPageNo;
    pageIndex:      Integer;
    page:           TACRPage;
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
aaWriteToLog('TACRCache.AddPages Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
aaWriteToLog('NumPagesToAdd = '+IntToStr(NumPagesToAdd));
{$ENDIF}
end;
          end;
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRCache.AddPages Error#2 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
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
aaWriteToLog('TACRCache.AddPages Error#3 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
aaWriteToLog('NumPagesToAdd = '+IntToStr(NumPagesToAdd));
{$ENDIF}
end;
          end;
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRCache.AddPages Error#4 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
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
procedure TACRCache.RemovePages(
                  Pages:            TACRPageArray;
                  SessionID:        TACRSessionID;
                  // state type of the locked object that calls this method
                  StateType:        TACRDBStateType;
                  State:            TACRState;
                  NumPagesFromEnd:  Cardinal = 0
                                );
var i,n,start:  Cardinal;
    pageIndex:  Integer;
    page:       TACRPage;
    pageNo:     TACRPageNo;
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
       raise EACRException.Create(11846,ErrorLDuplicatePage,[PageNo,pageIndex]);
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
aaWriteToLog('TACRCache.RemovePages Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
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
function TACRCache.GetPage(
                  SessionID:  TACRSessionID;
                  PageNo:     TACRPageNo;
                  // state type of the locked object that calls this method
                  StateType:  TACRDBStateType;
                  // current state of the locked object that calls this method
                  State:      TACRState;
                  // read current page data from page manager if not in cache
                  ReadPage:   Boolean;
                  // this page will be updated
                  UpdatePage: Boolean;
                  // the page should be updated and original will be copied to shared pages
                  MakeCopy:   Boolean
                  ): TACRPage;
var page:       TACRPage;
    pageIndex:  Integer;
begin
{$IFDEF DEBUG_TRACE_TACRCache_GetPage}
aaWriteToLog('> TACRCache.GetPage - ClassName = '+Self.ClassName
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
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('1. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
  if (((not UpdatePage) and (MakeCopy)) or (SessionID = INVALID_SESSION_ID)) then
   raise EACRException.Create(11801,ErrorLGetPageInvalidParams,[PageNo,SessionID]);
  if (FActiveSessionID = SessionID) then
   begin
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('2. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
    // active session - search in updated pages at first
    LockActive(False);
    try
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('3. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      pageIndex := FUpdatedPages.Find(PageNo,Result);
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('4. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID)+#13#10+'pageIndex = '+IntToStr(pageIndex));
{$ENDIF}
    finally
      UnlockActive;
    end;
   end;
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('5. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
  // page was not found in active cache
  if (Result = nil) then
   begin
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('6. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
    // read page
    LockShared(False);
    try
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('7. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      // add to shared pages
      pageIndex := FSharedPages.Find(PageNo,Result);
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('8. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID)+#13#10+'pageIndex = '+IntToStr(pageIndex));
{$ENDIF}
    finally
      UnlockShared;
    end;
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('9. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
    if (Result <> nil) then
     begin
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('10. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      Result.Parent := FSharedPages;
      if (ReadPage) then
       if ((Result.State <> State) or (Result.StateType <> StateType)) then
        try
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('11. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
          RereadPage(Result,StateType,State);
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('12. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
        except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRCache.GetPage Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
aaWriteToLog('PageNo = '+IntToStr(pageNo));
{$ENDIF}
          Result.Free;
          Result := nil;
          raise;
end;
        end;
     end; // page found in shared pages
   end; // search in cache and reread page if state is not equal current state

{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('13. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
  // page was not found in cache - add it
  if (Result = nil) then
   begin
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('14. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
    // page was not found in cache - add it
    if (UpdatePage) then
      Result := CreatePage(PageNo,StateType,State,FUpdatedPages)
    else
      Result := CreatePage(PageNo,StateType,State,FSharedPages);
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('15. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
    if (ReadPage) then
     try
{$IFDEF DEBUG_DECRYPTION_TIME}
aaIncCounter(counter6);
aaStartTime(time6);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('16. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      LPageManager.DirectReadPage(Result);
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('17. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
{$IFDEF DEBUG_DECRYPTION_TIME}
aaStopTime(time6);
{$ENDIF}
     except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRCache.GetPage Error#2 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
aaWriteToLog('PageNo = '+IntToStr(pageNo));
{$ENDIF}
      Result.Free;
      Result := nil;
      raise;
end;
     end;
    if (UpdatePage) then
     begin
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('18. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      // insert new page to updated pages
      LockActive(True);
      try
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('19. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
        FUpdatedPages.Insert(PageNo,Result);
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('20. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
        Result.SessionID := SessionID;
        if (MakeCopy) then
         begin
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('21. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
          // copy current page to shared pages, result to updated pages
          LockShared(True);
          try
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('22. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
            Page := CreatePage(PageNo,StateType,State,FSharedPages);
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('23. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
            try
              CopyPage(Result,Page);
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('24. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
              FSharedPages.Insert(PageNo,Page);
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('25. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
            except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRCache.GetPage Error#3 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
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
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('26. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      // insert new page to shared pages
      LockShared(True);
      try
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('27. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
        FSharedPages.Insert(PageNo,Result);
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('28. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      finally
        UnlockShared;
      end;
     end;
   end // page was not found in cache
  else
  if (UpdatePage and (Result.Parent <> FUpdatedPages)) then
   begin
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('29. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
    Result.Updated := True;
    // update page was found in shared cache - we should move it to updated pages
    if (MakeCopy) then
     begin
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('30. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      // shared cache
      Page := Result;
      Result := CreatePage(PageNo,StateType,State,FUpdatedPages);
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('31. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      try
        CopyPage(Page,Result);
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('32. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRCache.GetPage Error#4 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
aaWriteToLog('PageNo = '+IntToStr(pageNo));
{$ENDIF}
        Result.Free;
        Result := nil;
        raise;
end;
      end;
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('33. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      Page.Parent := FSharedPages;
      // insert new page to updated pages
      LockActive(True);
      try
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('34. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
        FUpdatedPages.Insert(PageNo,Result);
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('35. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
        Result.SessionID := SessionID;
      finally
        UnlockActive;
      end;
     end
    else
     begin
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('36. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      LockActive(True);
      try
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('37. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
        FUpdatedPages.Insert(PageNo,Result);
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('38. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
        Result.Parent := FUpdatedPages;
        Result.SessionID := SessionID;
      finally
        UnlockActive;
      end;
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('39. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      // delete page from shared pages
      LockShared(True);
      try
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('40. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
        FSharedPages.Delete(PageNo,True);
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('41. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
      finally
        UnlockShared;
      end;
     end;
   end; // update page was found in shared cache - we should move it to updated pages
{$IFDEF DEBUG_TRACE_TACRCache_GetPage_FULL}
aaWriteToLog('42. TACRCache.GetPage - ClassName = '+Self.ClassName+#13#10+'SessionID = '+IntToStr(SessionID)+#13#10+'FActiveSessionID = '+IntToStr(FActiveSessionID));
{$ENDIF}
  Inc(Result.FUseCount);
  Result.LastAccessTime := aaGetTickCount;
{$IFDEF DEBUG_DECRYPTION_TIME}
finally
aaStopTime(time7);
end;
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRCache_GetPage}
aaWriteToLog('< TACRCache.GetPage - ClassName = '+Self.ClassName
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
aaWriteToLog('Error in TACRCache.GetPage - ClassName = '+Self.ClassName
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
procedure TACRCache.PutPage(Page: TACRPage);
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
aaWriteToLog('TACRCache.PutPage Error#3 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
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
procedure TACRCache.UpdatePage(
                      SessionID: TACRSessionID;
                      Page: TACRPage;
                      // state type of the locked object that calls this method
                      StateType:  TACRDBStateType;
                      // current state of the locked object that calls this method
                      State:      TACRState;
                      // the page should be updated and original will be copied to shared pages
                      MakeCopy:   Boolean = false
                     );
var pageIndex: Integer;
    oldPage:   TACRPage;
    tempPage:  TACRPage;
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
procedure TACRCache.ApplyChanges(
                      // current state of the locked object that calls this method
                      State1:      TACRState;
                      // StateType2 is for table metadata state only
                      StateType2:  TACRDBStateType = dbstNone;
                      // State2 is for table metadata state only
                      State2:      TACRState = 0
                                );
var i,n:        Integer;
    page:       TACRPage;
    pageNo:     TACRPageNo;
    tempPage:   TACRPage;
    pageIndex:  Integer;
    t:          Cardinal;
    State:      TACRState;
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
aaWriteToLog('TACRCache.ApplyChanges Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
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
aaWriteToLog('TACRCache.ApplyChanges Error#2 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
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
aaWriteToLog('TACRCache.ApplyChanges Error#3 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
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
aaWriteToLog('TACRCache.ApplyChanges Error#4 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
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
aaWriteToLog('TACRCache.ApplyChanges Error#5 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
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
procedure TACRCache.CancelChanges;
var i,n:        Integer;
    page:       TACRPage;
    pageNo:     TACRPageNo;
    tempPage:   TACRPage;
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
aaWriteToLog('TACRCache.CancelChanges Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
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
aaWriteToLog('TACRCache.CancelChanges Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
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
// TACRDatabaseCache
// Database cache class.
// Used for caching TACRFreeSpaceManager pages as well as for storing
// cached pages from recently closed TACRTableData
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// lock children
//------------------------------------------------------------------------------
procedure TACRDatabaseCache.LockChildren;
begin
  FChildrenSync.Lock(True);
end; // LockChildren


//------------------------------------------------------------------------------
// lock children
//------------------------------------------------------------------------------
procedure TACRDatabaseCache.UnlockChildren;
begin
  FChildrenSync.Unlock;
end; // UnlockChildren


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRDatabaseCache.Create(PageManager:  TACRPageManager);
begin
  inherited Create(PageManager);
  FChildrenSync := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
  FChildren := TList.Create;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRDatabaseCache.Destroy;
begin
  FreeAndNil(FChildrenSync);
  FreeAndNil(FChildren);
  inherited Destroy;
end; // Destroy


//------------------------------------------------------------------------------
// add children cache
//------------------------------------------------------------------------------
procedure TACRDatabaseCache.AddChildren(Cache: TACRTableCache);
begin
  LockChildren;
  try
   try
    FChildren.Add(Cache);
   except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRDatabaseCache.AddChildren Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
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
procedure TACRDatabaseCache.DeleteChildren(Cache: TACRTableCache);
begin
  LockChildren;
  try
   try
    FChildren.Remove(Cache);
   except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRDatabaseCache.DeleteChildren Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
{$ENDIF}
end;
   end;
  finally
    UnlockChildren;
  end;
end; // DeleteChildren


////////////////////////////////////////////////////////////////////////////////
//
// TACRTableCache
// Table cache class.
// Used for caching all pages related to current table:
// FSharedPages - pages that can be read by all reading sessions (S lock)
//
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create new page
//------------------------------------------------------------------------------
function TACRTableCache.CreatePage(
                  PageNo:     TACRPageNo;
                  // state type of the locked object that calls this method
                  StateType:  TACRDBStateType;
                  // current state of the locked object that calls this method
                  State:      TACRState;
                  Parent:     TACRSortedPageArray
                   ): TACRPage;
begin
  Result := inherited CreatePage(PageNo,StateType,State,Parent);
  Result.TableID := FTableID;
end; // CreatePage


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRTableCache.Create(
                      PageManager:  TACRPageManager;
                      ParentCache:  TACRCache
                  );
begin
  inherited Create(PageManager);
  LParentCache := ParentCache;
  FTableID := TACRTableID(INVALID_OBJECT_ID);
  FAddedToParentCache := False;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRTableCache.Destroy;
begin
  if (FActiveSessionID <> INVALID_SESSION_ID) then
   try
    CancelChanges;
   except
on e: Exception do
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRTableCache.Destroy Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
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
aaWriteToLog('TACRTableCache.Destroy Error#2 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
{$ENDIF}
end;
  end;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// import pages from parent cache
//------------------------------------------------------------------------------
procedure TACRTableCache.ImportPagesFromParent;
var i:    Integer;
    page: TACRPage;
begin
{ TODO :
check if optimizations needed, like recreate SharedPages in parent cache or
just copy references instead of move }
  if (LParentCache = nil) then
   Exit;
  if (FTableID = INVALID_OBJECT_ID) then
    raise EACRException.Create(11865,ErrorLInvalidTableID,[FTableID]);
  LockShared(True);
  if (LParentCache <> nil) then
   if (LParentCache is TACRDatabaseCache) then
    begin
      TACRDatabaseCache(LParentCache).AddChildren(Self);
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
procedure TACRTableCache.ExportPagesToParent;
var i,n:   Integer;
    page:  TACRPage;
    tPage: TACRPage;
begin
  if (LParentCache = nil) then
   Exit;
  if (FTableID = INVALID_OBJECT_ID) then
    Exit;
  if (FAddedToParentCache) then
   if (LParentCache <> nil) then
    if (LParentCache is TACRDatabaseCache) then
     begin
       TACRDatabaseCache(LParentCache).DeleteChildren(Self);
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
aaWriteToLog('TACRTableCache.Destroy Error#1 in '+Self.ClassName+', Self = '+IntToHex(Integer(Self),8)+':'+#13#10+e.Message+#13#10);
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
// TACRCacheManagerThread
// Manages cache list and keep memory usage in specified limits
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// lock database cache list
//------------------------------------------------------------------------------
procedure TACRCacheManagerThread.LockDatabaseList(Exclusive: Boolean);
begin
  FDatabaseThreadSync.Lock(Exclusive);
end; // Lock


//------------------------------------------------------------------------------
// unlock database cache list
//------------------------------------------------------------------------------
procedure TACRCacheManagerThread.UnlockDatabaseList;
begin
  FDatabaseThreadSync.Unlock;
end; // Unlock


//------------------------------------------------------------------------------
// lock table cache list
//------------------------------------------------------------------------------
procedure TACRCacheManagerThread.LockTableList(Exclusive: Boolean);
begin
  FTableThreadSync.Lock(Exclusive);
end; // Lock


//------------------------------------------------------------------------------
// unlock table cache list
//------------------------------------------------------------------------------
procedure TACRCacheManagerThread.UnlockTableList;
begin
  FTableThreadSync.Unlock;
end; // Unlock


//------------------------------------------------------------------------------
// clear databases
//------------------------------------------------------------------------------
procedure TACRCacheManagerThread.ClearDatabases;
var i:        Integer;
    dCache:   TACRDatabaseCache;
begin
{$IFDEF DEBUG_TRACE_TACRCacheManagerThread}
aaWriteToLog('> TACRCacheManagerThread.ClearDatabases');
try
{$ENDIF}
  LockDatabaseList(False);
  try
    for i := 0 to FDatabaseCacheList.Count-1 do
     begin
       dCache := TACRDatabaseCache(FDatabaseCacheList.Items[i]);
       if (dCache <> nil) then
         dCache.ClearSharedCache;
     end;
  finally
    UnlockDatabaseList;
  end;
{$IFDEF DEBUG_TRACE_TACRCacheManagerThread}
aaWriteToLog('< TACRCacheManagerThread.ClearDatabases');
except
  on e: Exception do
   begin
    aaWriteToLog('Error in TACRCacheManagerThread.ClearDatabases'+#13#10+e.Message);
    raise;
   end;
end;
{$ENDIF}
end; // ClearDatabases


//------------------------------------------------------------------------------
// clear tables
//------------------------------------------------------------------------------
procedure TACRCacheManagerThread.ClearTables;
var i:        Integer;
    tCache:   TACRTableCache;
begin
{$IFDEF DEBUG_TRACE_TACRCacheManagerThread}
aaWriteToLog('> TACRCacheManagerThread.ClearTables');
try
{$ENDIF}
  LockTableList(False);
  try
{$IFDEF DEBUG_TRACE_TACRCacheManagerThread}
aaWriteToLog('1. TACRCacheManagerThread.ClearTables FTableCacheList.Count = '+IntToStr(FTableCacheList.Count));
{$ENDIF}
    for i := 0 to FTableCacheList.Count-1 do
     begin
{$IFDEF DEBUG_TRACE_TACRCacheManagerThread}
aaWriteToLog('1. TACRCacheManagerThread.ClearTables i = '+IntToStr(i));
{$ENDIF}
       tCache := TACRTableCache(FTableCacheList.Items[i]);
{$IFDEF DEBUG_TRACE_TACRCacheManagerThread}
aaWriteToLog('2. TACRCacheManagerThread.ClearTables tCache = '+IntToHex(Integer(tCache),8));
{$ENDIF}
       if (tCache <> nil) then
        tCache.ClearSharedCache;
{$IFDEF DEBUG_TRACE_TACRCacheManagerThread}
aaWriteToLog('3. TACRCacheManagerThread.');
{$ENDIF}
     end;
  finally
    UnlockTableList;
  end;
{$IFDEF DEBUG_TRACE_TACRCacheManagerThread}
aaWriteToLog('< TACRCacheManagerThread.ClearTables');
except
  on e: Exception do
   begin
    aaWriteToLog('Error in TACRCacheManagerThread.ClearTables'+#13#10+e.Message);
    raise;
   end;
end;
{$ENDIF}
end; // ClearTables


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRCacheManagerThread.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FDatabaseCacheList := TList.Create;
  FTableCacheList := TList.Create;
  FDatabaseThreadSync := TACRReadWriteThreadSyncByCriticalSections.Create(False,Self,'DatabaseSync');
  FTableThreadSync := TACRReadWriteThreadSyncByCriticalSections.Create(False,Self,'TableSync');
//  FDatabaseThreadSync := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
//  FTableThreadSync := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
  FreeOnTerminate := True;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRCacheManagerThread.Destroy;
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
procedure TACRCacheManagerThread.Execute;
var t: Cardinal;
begin
 t := aaGetTickCount;
 while (not Terminated) do
  begin
    if (ACRGetTickCountDiff(aaGetTickCount,t) > ACRCacheManagerThreadSleep) then
     begin
      ClearTables;
      ClearDatabases;
      t := aaGetTickCount;
     end;
    // sleep  
    Sleep(ACRCacheManagerThreadMinimumSleep);
  end;
end; // Execute


//------------------------------------------------------------------------------
// add cache
//------------------------------------------------------------------------------
procedure TACRCacheManagerThread.AddCache(Cache: TACRCache);
begin
{$IFDEF DEBUG_TRACE_TACRCacheManagerThread}
aaWriteToLog('> TACRCacheManagerThread.AddCache, Cache.ClassName = '+Cache.ClassName);
try
{$ENDIF}
 if (not Terminated) then
  if (Cache is TACRDatabaseCache) then
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
{$IFDEF DEBUG_TRACE_TACRCacheManagerThread}
aaWriteToLog('< TACRCacheManagerThread.AddCache, Cache.ClassName = '+Cache.ClassName);
except
  on e: Exception do
   begin
    aaWriteToLog('Error in TACRCacheManagerThread.AddCache, Cache.ClassName = '+Cache.ClassName+#13#10+e.Message);
    raise;
   end;
end;
{$ENDIF}
end; // AddCache


//------------------------------------------------------------------------------
// remove cache
//------------------------------------------------------------------------------
procedure TACRCacheManagerThread.RemoveCache(Cache: TACRCache);
begin
{$IFDEF DEBUG_TRACE_TACRCacheManagerThread}
aaWriteToLog('> TACRCacheManagerThread.RemoveCache, Cache.ClassName = '+Cache.ClassName);
try
{$ENDIF}
 if (not Terminated) then
  if (Cache is TACRDatabaseCache) then
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
{$IFDEF DEBUG_TRACE_TACRCacheManagerThread}
aaWriteToLog('< TACRCacheManagerThread.RemoveCache, Cache.ClassName = '+Cache.ClassName);
except
  on e: Exception do
   begin
    aaWriteToLog('Error in TACRCacheManagerThread.RemoveCache, Cache.ClassName = '+Cache.ClassName+#13#10+e.Message);
    raise;
   end;
end;
{$ENDIF}
end; // RemoveCache


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('>ACRPage initialization');
{$ENDIF}
  ACRMemoryIncUseCount;

{$IFDEF TACRCacheManagerThread_ON}
  CacheManagerThreadSync := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
{$ENDIF}

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('<ACRPage> initialization');
{$ENDIF}


finalization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('>ACRPage finalization');
{$ENDIF}

{$IFDEF TACRCacheManagerThread_ON}
  CacheManagerThreadSync.Lock(True);
  try
   if (CacheManager <> nil) then
    begin
     CacheManager.Terminate;
     Sleep(ACRCacheManagerThreadMinimumSleep+1);
     CacheManager := nil;
    end;
  finally
    CacheManagerThreadSync.Unlock;
  end;
  if (CacheManagerThreadSync <> nil) then
   FreeAndNil(CacheManagerThreadSync);
{$ENDIF}

  ACRMemoryDecUseCount;
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('<ACRPage finalization');
{$ENDIF}

end.
