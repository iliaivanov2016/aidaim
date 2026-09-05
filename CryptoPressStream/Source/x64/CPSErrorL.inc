const

  NextErrorLCode = 10101;

resourcestring

  // TCPSMemoryManager
  ErrorLMemoryOverrunDetected = 'Memory overrun detected';
  ErrorLMemoryLeakFound = 'Memory Leak Found. Lost %d byte(s)';
  ErrorLMemoryLimitExceeded = 'Memory limit exceeded (Limit = %d bytes)';
  ErrorLGetMemError = 'GetMem error: %s';
  ErrorLReallocMemError = 'ReallocMem error: %s';
  ErrorLFreeMemError = 'FreeAndNillMem error: %s';
  ErrorLCannotAllocateZeroBytes = 'Cannot alocate 0 bytes';
  ErrorLUnknownGetMemType = 'Unknown GetMem method type: %d';
  ErrorLInvalidPointer = 'Invalid pointer';

  ErrorLFlushFileBuffers = 'Cannot flush file buffers for file: ''%s''. ErrorCode:%d. ErrorMessage: %s';
  ErrorLCannotSetNewSize = 'Cannot set new size of file handle #%d. Old size %d bytes, new size %d bytes. System error code: %d. System error message: %s';
  ErrorLInvalidVectorIndex = 'Error setting InitVector, invalid index = %d. Index should be >= 0 and < %d';
  ErrorLInvalidKeyIndex = 'Error setting Key, invalid index = %d. Index should be >= 0 and < %d';
  ErrorLInvalidKeySize = 'Error setting Key, invalid KeySize = %d. KeySize should be >= 0 and < %d';
  ErrorLInvalidCryptoKeyInfo = 'Error - invalid encryption key or password';
  ErrorLEncryptionIsSwitchedOff = 'Error - encryption is switched off in CPSVer.Inc';
  ErrorLUnknownCryptoMode = 'Error - unknown crypto mode = %d';
  ErrorLUnknownCryptoAlgorithm = 'Error - unknown crypto algorithm = %d';

  ErrorLZeroBlockSizeIsNotAllowed = 'Stream block size = 0 is not allowed';
  ErrorLNilPointer = 'Nil pointer occured';

  ErrorLCannotSetPosition = 'Cannot set stream position to %d. Position = %d, Size = %d';
  ErrorLStreamSizeTooSmall = 'Stream size = %d too small. Should be at least = %d';
  ErrorLCannotChangeStreamSize = 'Cannot change stream size. NewSize = %d, Current size = %d';
  ErrorLCompressBufferFailed = 'Compress buffer failed. CompAlg = %d, CompMode = %d, InSize = %d, OutSize = %d';
  ErrorLCannotReadFromStream = 'Cannot read from stream. Position = %d, Stream size = %d, Block size = %d, Bytes Read = %d';
  ErrorLCannotWriteToStream = 'Cannot write to stream. Position = %d, Stream size = %d, Block size = %d, Bytes Write = %d';
  ErrorLDecompressBufferFailed = 'Decompress buffer failed. CompAlg = %d, InSize = %d, OutSize = %d';
  ErrorLDecompressBufferFailedInvalidSize = 'Decompress buffer failed. UncompSize = %d, Header.UncompSize = %d';
  ErrorLDecompressBufferFailedInvalidCRC = 'Decompress buffer failed. CheckSum = %d, Header.Crc32 = %d';
  ErrorLCannotReadFromStreamInvalidReadSize = 'Cannot read from stream. ReadSize = %d';
  ErrorLInvalidStreamSize = 'Invalid stream size = %d. Should be = %d';
  ErrorLCannotCreateFile = 'Cannot create or open file. FileName = %s, mode = %d, GetLastError = %d';
  ErrorLCannotOpenFile = 'Cannot open file. FileName = %s, Mode = %d';
  ErrorLInvalidSignature = 'Invalid signature = %s. Should be %s';
  ErrorLInvalidVersion = 'Invalid version number = %f. Should be %f';
  ErrorLInvalidStream = 'Invalid stream - stream header not found';
  ErrorLInvalidOutSize = 'Invalid outSize = %d, should be <= %d';
  ErrorLInvalidBlockNumber = 'Invalid number of block = %d, count = %d';
  ErrorLInvalidBufferSize = 'Invalid buffer size = %d';
  ErrorLReadOnly = 'Cannot perform this operation in read only mode';
  ErrorLCannotGetTempFileName =  'Cannot get temporary file name';
  ErrorLNotCompressedStream = 'Error - stream is not compressed';
  ErrorLInvalidMaxSize = 'Error - compressed stream write failed: MaxSize = %d, LastBlockNo = %d, Headers.ItemCount = %d';
  ErrorLInvalidLastBlockNo = 'Error - compressed stream write failed: LastBlockNo = %d, Headers.ItemCount = %d';
  ErrorLOperationIsNotSupported = 'Error - operation is not supported';
  ErrorLCannotRenameFile = 'Error - cannot rename file "%s" to "%s"';
  ErrorLCannotDeleteFile = 'Error - cannot delete file "%s"';
  ErrorLCannotDecryptCPS1Data = 'Error - cannot decrypt data saved by CryptoPressStream version 1.';
  ErrorLCannotLoadData = 'Cannot load data from stream. Stream = %s, Stream.ClassName = %s, Position = %d, Stream size = %d, DataSize = %d, Bytes Read = %d.'+#13#10+'%s';
  ErrorLCannotSaveData = 'Cannot save data to stream. Stream = %s, Stream.ClassName = %s, Position = %d, Stream size = %d, DataSize = %d, Bytes Write = %d.'+#13#10+'%s';
