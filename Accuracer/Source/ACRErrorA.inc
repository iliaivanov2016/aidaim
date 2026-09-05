const

  LastErrorACode = 20098;

resourcestring

  ErrorANilPointer = 'Pointer is nil';
  ErrorAHandleError = 'Error creating table handle';
  ErrorAInvalidSessionName = 'Invalid session name ''%s''';
  ErrorASessionActive = 'Cannot perform this operation on an active session';
  ErrorAAutoSessionActive = 'Cannot modify SessionName while AutoSessionName is enabled';
  ErrorABlankDatabaseFileName = 'DatabaseFileName property is blank';
  ErrorACannotDeleteConnectedDatabse = 'DeleteDatabase error. Database is connected';
  ErrorACannotRenameConnectedDatabse = 'RenameDatabase error. Database is connected';
  ErrorADuplicateSessionName = 'Duplicate session name ''%s''';
  ErrorASessionNameMissing = 'Session name missing';
  ErrorAEngineNotInitialized = 'Database Engine is not initialized';
  ErrorAAutoSessionExclusive = 'Cannot enable AutoSessionName property with more than one session on a form or data-module';
  ErrorAAutoSessionExists = 'Cannot add a session to the form or data-module while session ''%s'' has AutoSessionName enabled';
  ErrorADatabaseHandleSet = 'Database handle owned by a different session';
  ErrorADatabaseOpen = 'Cannot perform this operation on an open database';
  ErrorADatabaseCreate = 'Cannot create database';
  ErrorADatabaseNameMissing = 'Database name missing';
  ErrorADatabaseOpenError = 'Database open error';
  ErrorANoTableName = 'Missing TableName property';
  ErrorACannotDeleteBusyTable = 'Cannot delete table ''%s''. Table is open by another dataset';
  ErrorAIndexNotFound = 'Index not found';
  ErrorANotIndexField = 'Field %s is not in the current index';
  ErrorABTreeInvalidCall = 'Internal index error';
  ErrorABTreeEmptyPage = 'Index error: page is empty';
  ErrorABTreeInvalidPage = 'Index error: invalid page number';
  ErrorABTreeInvalidParams = 'Index error: invalid params';
  ErrorABTreeInvalidPosition = 'Index error: invalid position';
  ErrorABTreeDeleteEntryNotFound = 'Index error: cannot delete entry. Entry not found';
  ErrorACannotDeleteIndex = 'Cannot delete index ''%s''. Index not found';
  ErrorAIndexAlreadyExists = 'Cannot create index ''%s''. Index already exists';
  ErrorAIndexPagesNotReleased = 'Index pages are not released';
  ErrorAIndexIntegrityViolated = 'Index integrity violated. PageNo=%d EntryNo=%d';
  ErrorAIndexIntegrityCircularLinks = 'Index integrity violated. Circular links. PageNo=%d EntryNo=%d';
  ErrorAIndexIntegrityLeafLinks = 'Index integrity violated. Invlaid leaf link. PageNo=%d EntryNo=%d';
  ErrorAEmptySQLStatement = 'No SQL statement available';
  ErrorACircularDataLink = 'Circular datalinks are not allowed';
  ErrorANotReleasedPageIsAllocated = 'Not released page is allocated';
  ErrorAInvalidPageBuffer = 'Invalid page buffer. Buffer is Nil';
  ErrorAInvalidPageNo = 'Invalid page number';
  ErrorAInvalidPageModification = 'Invalid page modification';
  ErrorAUsedPageWasReleased = 'Used page was released too early';
  ErrorACannotRemoveUsedPage = 'Cannot remove used page';
  ErrorACannotWriteUsedPage = 'Cannot write used page';
  ErrorACannotFindIndexField = 'Cannot find index field ''%s''';
  ErrorAInvalidIndexName = 'Invalid index name ''%s''';
  ErrorAInvalidIndexKeyPath = 'Invalid index key path';
  ErrorAInvalidIndexGetRecordMode = 'Invalid get record mode for index: grmCurrent';
  ErrorABufferSizeExceeded = 'Buffer size exceeded';
  ErrorAInvalidIndexForSearch = 'Invalid index for search';
  ErrorAInvalidIndexOfNo = 'Invalid index No (IndexOf)';
  ErrorACannotRetreiveRecordFromEmptyIndex = 'Cannot retreive record from empty index';
  ErrorACannotSetRecNoGreaterThanRecordCount = 'Cannot set RecNo greater than RecordCount';
  ErrorAInvalidIndexPage = 'Invalid index page';
  ErrorAPageIsUsedByOtherSession = 'Page is used by other session';
  ErrorADatabaseAlreadyOpen = 'Cannot create database. Database is already open';
  ErrorACannotUnlockSessionsFile = 'Cannot unlock sessions file';
  ErrorACannotConnectSession = 'Cannot connect session. Maximum sessions quantity exceeded';
  ErrorACannotDisconnectSession = 'Cannot disconnect session';
  ErrorAUncommitedPages = 'Cannot free not commited pages, page manager classname = %s';

