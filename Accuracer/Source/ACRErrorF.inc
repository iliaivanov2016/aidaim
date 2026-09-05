const

  NextErrorFCode = 50034;

resourcestring

  ErrorFLockByTimeoutFailed = 'Error - cannot lock FreeSpaceManager, RetryCount = %d, Delay = %d';
  ErrorFUnlockFailed = 'Error - cannot unlock FreeSpaceManager';
  ErrorFFreePFSMap = 'Error - cannot free PFS page, pageNo = %d';
  ErrorFInvalidBitNo = 'Error - invalid BitNo = %d, PageDataSize = %d';
  ErrorFNilPointer = 'Error - nil pointer occurred';
  ErrorFUnknownPageType = 'Error - unknown FSM page type = %d';
  ErrorFInvalidPage = 'Error - invalid FSM page, pageNo = %d, page type = %d'; 
  ErrorFInvalidExtPageCount = 'Error - Too small ExtentPageCount: < 4'; 
  ErrorFOperationCanBePerformedOnlyOnDiskDatabase = 'Operation can be performed only on disk database';
