const

  NextErrorLCode = 11633;

resourcestring


  // MemoryManager
  ErrorLMemoryOverrunDetected = 'Memory overrun detected';
  ErrorLMemoryLeakFound = 'Memory Leak Found. Lost %d byte(s)';
  ErrorLMemoryLimitExceeded = 'Memory limit exceeded (Limit = %d bytes)';
  ErrorLGetMemError = 'GetMem error: %s';
  ErrorLReallocMemError = 'ReallocMem error: %s';
  ErrorLFreeMemError = 'FreeAndNillMem error: %s';
  ErrorLCannotAllocateZeroBytes = 'Cannot alocate 0 bytes';
  ErrorLUnknownGetMemType = 'Unknown GetMem method type: %d';
  ErrorLInvalidPointer = 'Invalid pointer';

  ErrorLClientIsNotConnected = 'Client is not connected to the server';
  ErrorLCannotSetNewSize = 'Cannot set new size of file handle #%d. Old size %d bytes, new size %d bytes. System error code: %d. System error message: %s';
  ErrorLInvalidVectorIndex = 'Error setting InitVector, invalid index = %d. Index should be >= 0 and < %d';
  ErrorLInvalidKeyIndex = 'Error setting Key, invalid index = %d. Index should be >= 0 and < %d';
  ErrorLInvalidKeySize = 'Error setting Key, invalid KeySize = %d. KeySize should be >= 0 and < %d';
  ErrorLInvalidCryptoKeyInfo = 'Error - invalid encryption key or password';
  ErrorLEncryptionIsSwitchedOff = 'Error - encryption is switched off in CPSVer.Inc';
  ErrorLUnknownCryptoMode = 'Error - unknown crypto mode = %d';
  ErrorLUnknownCryptoAlgorithm = 'Error - unknown crypto algorithm = %d';

  ErrorLZeroBlockSizeIsNotAllowed = 'Stream block size = 0 is not allowed';
  ErrorLCannotSetPosition = 'Cannot set stream position to %d. Position = %d, Size = %d';
  ErrorLCannotReadFromStream = 'Cannot read from stream. Position = %d, Stream size = %d, Block size = %d, Bytes Read = %d';
  ErrorLCannotWriteToStream = 'Cannot write to stream. Position = %d, Stream size = %d, Block size = %d, Bytes Write = %d';
  ErrorLInvalidStreamSize = 'Invalid stream size = %d. Should be = %d';
  ErrorLCannotCreateFile = 'Cannot create file. FileName = %s';
  ErrorLCannotOpenFile = 'Cannot open file. FileName = %s, Mode = %d';
  ErrorLUserDoesNotExist = 'Error - user does not exist. User ID = %d';
  ErrorLInvalidSortType = 'Error - invalid sort type = %d';
  ErrorLErrorSoringRecordsByID = 'Sorting error in Users array: Hi = %d, Lo = %d, iHi = %d, iLo = %d, ItemCount = %d, SortBy = %d, Ascending = %d';
  ErrorLDatabaseIsNotAssigned = 'Database is not assigned';
  ErrorLInvalidPassword = 'Invalid password';
  ErrorLUserAlreadyExists = 'User already exists. User ID = %d';
  ErrorLAddUserTransactionFailed = 'Cannot add user to the database - transaction failed. Probably some database objects are locked by other users. User ID = %d, RetryCount = %d, Delay = %d';
  ErrorLRemoveUserTransactionFailed = 'Cannot remove user from the database - transaction failed. Probably some database objects are locked by other users. User ID = %d, RetryCount = %d, Delay = %d';
  ErrorLInvalidUserID = 'Invalid User ID = %d';
  ErrorLChangeUserStatusTransactionFailed = 'Cannot change user status in the database - transaction failed. Probably some database objects are locked by other users. User ID = %d, RetryCount = %d, Delay = %d';
  ErrorLChangeUserInfoTransactionFailed = 'Cannot change user info in the database - transaction failed. Probably some database objects are locked by other users. User ID = %d, RetryCount = %d, Delay = %d';
  ErrorLAddContactTransactionFailed = 'Cannot add user to contact list - transaction failed. Probably some database objects are locked by other users. Owner User ID = %d, Contact User ID = %d, RetryCount = %d, Delay = %d';
  ErrorLUpdateContactTransactionFailed = 'Cannot update user in contact list - transaction failed. Probably some database objects are locked by other users. Owner User ID = %d, Contact User ID = %d, RetryCount = %d, Delay = %d';
  ErrorLRemoveUserFromContactsTransactionFailed = 'Cannot remove user from contact list - transaction failed. Probably some database objects are locked by other users. Owner User ID = %d, Contact User ID = %d, RetryCount = %d, Delay = %d';
  ErrorLSaveMessageFailed = 'Cannot save message - transaction failed. Probably some database objects are locked by other users. Sender ID = %d, Recipient ID = %d, Message Type = %d, Message Text = "%s", Message Size = %d, RetryCount = %d, Delay = %d';
  ErrorLSetMessageDeliveryDateFailed = 'Cannot set message delivery date - transaction failed. Probably some database objects are locked by other users. Message ID = %d, RetryCount = %d, Delay = %d';
  ErrorLFindMessageFailed = 'Cannot find message - query failed. Probably some database objects are locked by other users or SQL syntax is incorrect. Query = '+#13#10+'%s'+#13#10+', RetryCount = %d, Delay = %d';
  ErrorLDeleteMessageFailed = 'Cannot delete message - transaction failed. Probably some database objects are locked by other users. Message ID = %d, RetryCount = %d, Delay = %d';
  ErrorLCannotGetUserInfo = 'Cannot get user info from server. Probably connection is lost. Try to reconnect. UserID = %d, Error Code = %d';
  ErrorLNotAccuracerDataset = 'Not Accuracer dataset passed';
  ErrorLErrorImportingDataset = 'Error importing dataset: %s';
  ErrorLMySQLDatabaseIsNotAssigned = 'MySQL database is not assigned - set Database or SQLConnection property';
  ErrorLCannotConnectDirectly = 'Error - cannot connect directly. UserID = %d, Host = %s, Port = %d.';
  ErrorLClientCannotDisconnectSessionWithServer = 'Client cannot disconnect session with server. ServerID = %d';
  ErrorLClientCannotDisconnectSessionWithUser = 'Client cannot disconnect session with user. UserID = %d';
  ErrorLClientCannotActivate = 'Client cannot activate';
  ErrorLClientCannotDeactivate = 'Client cannot deactivate';
  ErrorLServerCannotDisconnectUser = 'Cannot disconnect the client with UserID = %d. Could be the client application was already abnormally terminated.';
  ErrorLInvalidIndex = 'Invalid index %d, count = %d';
  ErrorLInvalidCapacity = 'Invalid capacity = $d';
  ErrorLUsersContactDoesNotExist = 'Error - user''s contact does not exist. OwnerUserID = %d, ContactgUserID = %d';
  ErrorLRestructureFailed = 'Error - cannot resturecture %s table: '+#13#10+'%s';
  ErrorLCannotCompressBuffer = 'Error - cannot compress buffer. BufferSize = %d, Buffer = %s, CompressionAlgorithm = %d, CompressionMode = %d';
