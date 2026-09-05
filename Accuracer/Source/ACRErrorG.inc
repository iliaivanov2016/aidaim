const  LastErrorGCode = 30402
;

resourcestring

  ErrorGNotImplementedYet = 'Not implemented yet';


  // TACRMemoryManager
  ErrorGInvalidPointer = 'Invalid pointer';
  ErrorGMemoryOverrunDetected = 'Memory overrun detected';
  ErrorGMemoryLeakFound = 'Memory Leak Found. Lost %d byte(s)';
  ErrorGMemoryLimitExceeded = 'Memory limit exceeded (Limit = %d bytes)';
  ErrorGGetMemError = 'GetMem error: %s';
  ErrorGReallocMemError = 'ReallocMem error: %s';
  ErrorGFreeMemError = 'FreeAndNillMem error: %s';
  ErrorGCannotAllocateZeroBytes = 'Cannot alocate 0 bytes';
  ErrorGUnknownGetMemType = 'Unknown GetMem method type: %d';

  ErrorGUnsupportedDataType = 'Unsuported data type ''%s''';
  ErrorGSequenceOverflow = 'Sequence ''%s'' overflow';
  ErrorGSequenceIdNotFound = 'Sequence #%d not found';
  ErrorGSequenceLastValueFailed = 'No SequenceLastValue in session for sequence ''%s''. Call GetNextVal first';
  ErrorGWrongDataType = 'Wrong DataType. Wanted type is ''%s'' But realy type is ''%s''';
  ErrorGValueIsNull = 'Value is Null';
  ErrorGConstraintViolated = 'Constraint Error: %s';
  ErrorGFieldWithObjectIdNotFound = 'Field #%d not found';
  ErrorGFieldWithNameNotFound = 'Field ''%s'' not found';
  ErrorGConstraintNotNull = 'Constraint ''%s'' violated. Value in field ''%s'' cannot be null';
  ErrorGConstraintCheckMinViolated = 'Constraint ''%s'' violated. Value in field ''%s'' cannot be lower then ''%s''';
  ErrorGConstraintCheckMaxViolated = 'Constraint ''%s'' violated. Value in field ''%s'' cannot be greater then ''%s''';
  ErrorGConstraintPrimaryKeyViolated = 'Primary Key constraint ''%s'' violated. Duplicate found.';
  ErrorGConstraintUniqueViolated = 'Constraint unique ''%s'' violated. Duplicate found.';
  ErrorGCatnnotCompareIncompatibleDataTypes = 'Cannot compare Incompatible DataTypes: ''%s'' and ''%s''';
  ErrorGUnknownReturnCode = 'Unknown return code: %d';
  ErrorGUnknownDataType = 'Unknown DataType: ''%s''';
  ErrorGCastError = 'Cannot cast from ''%s'' to ''%s''';
  ErrorGCannotCopyDataIntoNewMemory = 'Cannot copy data into new memory';
  ErrorGMissingRightParenthesis = 'Missing symbol '')'' at line %d, column %d';
  ErrorGUnexpectedRightParenthesis = 'Unexpected symbol '')'' found at line %d, column %d';
  ErrorGUnterminatedString = 'Unterminated string at line %d, column %d';
  ErrorGInvalidNumericSymbol = 'Invalid numeric symbol ''%s'' at line %d, column %d';
  ErrorGUnexpectedToken = 'Unexpected token ''%s'' found at line %d, column %d';
  ErrorGUnexpectedEndOfCommand = 'Unexpected end of SQL command found at line %d, column %d';
  ErrorGBooleanExpressionExpected = 'Boolean expression expected, but ''%s'' found at line %d, column %d';
  ErrorGOtherTokenExpected = 'Token ''%s'' expected, but ''%s'' found at line %d, column %d';
  ErrorGArgumentExpected = 'Argument expected for function ''%s'' at line %d, column %d';
  ErrorGNotApplicableCastType = 'Cannot convert an expression to specified type: ''%s''';
  ErrorGTableNameExpected = 'Table name expected, but ''%s'' found at line %d, column %d';
  ErrorGViewNameExpected = 'View name expected, but ''%s'' found at line %d, column %d';
  ErrorGQuotedPasswordDataExpected = 'Quoted password expected (for PASSWORD "passwordData"), but ''%s'' found at line %d, column %d';
  ErrorGStringArgumentExpected = 'String argument expected for function ''%s'', but ''%s'' found at line %d, column %d';
  ErrorGConstDateFormatExpected = 'Const DateFormat string expected, but ''%s'' found at line %d, column %d';
  ErrorGNotEqualCountsOfFieldNamesAndKeyValues = 'Count of FieldNames (%d) not equal counts of KeyValues (%d)';
  ErrorGUnsupportedVariantType = 'Unsupported Variant Type %s';
  ErrorGUnknownOperator = 'Unknown operator: ''%s''';
  ErrorGBlankSqlCommand = 'Blank SQL command';
  ErrorGNotStringArgument = 'Not string argument in function ''%s''';
  ErrorGNotNumericDataType = 'Not numeric argument in numeric operator ''%s''';
  ErrorGCannotInvertValue = 'Cannot invert value with not numeric type ''%s''';
  ErrorGDivisionError = 'Division error: %s';
  ErrorGAmPmExpected = 'AM/PM word expected, but ''%s'' found';

  ErorrGDataSetOpen = 'Cannot perform this operation on an open dataset';
  ErorrGEmptySQLStatement = 'No SQL statement available';
  ErorrGNotApplicableCondition = 'Search condition is not applicable';
  ErorrGObjectTypeKeywordExpected = 'Object type keyword expected, but ''%s'' found at line %d, column %d';
  ErrorGSQLCommandExpected = 'SQL token expected, but ''%s'' found at line %d, column %d';
  ErrorGIntegerExpected = 'Integer expected, but ''%s'' found at line %d, column %d';
  ErrorGExpressionExpected = 'Expression expected, but ''%s'' found at line %d, column %d';
  ErrorGFieldPseudonymExpected = 'Field pseudonym expected, but ''%s'' found at line %d, column %d';
  ErrorGFieldNameExpected = 'Field name expected, but ''%s'' found at line %d, column %d';
  ErrorGFieldListExpected = 'Field list expected, but ''%s'' found at line %d, column %d';
  ErrorGSortSpecificationExpected = 'Sort specification expected, but ''%s'' found at line %d, column %d';
  ErrorGColumnFromOrderByNotFound = 'Column ''%s'' from ORDER BY clause not found';
  ErrorGDatasetAndAONotAssigned = 'Dataset and AO not assigned';
  ErrorGCannotFindField = 'Field ''%s'' not found';
  ErrorGFieldAlreadyExists = 'Field by name ''%s'' already exists';
  ErrorGNodeIsNotField = 'Node is not field';
  ErrorGRightParenthesisOrCommaExpected = ''')'' or '','' symbol expected, but ''%s'' found at line %d, column %d';
  ErrorGLeftParenthesisExpected = '''('' symbol expected, but ''%s'' found at line %d, column %d';
  ErrorGRightParenthesisExpected = ''')'' symbol expected, but ''%s'' found at line %d, column %d';
  ErrorGFieldTypeExpected = 'Field type expected, but ''%s'' found at line %d, column %d';
  ErrorGUnknownFieldType = 'Unknown field type ''%s'' at line %d, column %d';
  ErrorGDecimalConstantExpected = 'Decimal constant expected, but ''%s'' found at line %d, column %d';
  ErrorGNullKeywordExpected = '''NULL'' expected (for NOT NULL), but ''%s'' found at line %d, column %d';
  ErrorGBlobCompressionLevelValueExpected = 'Blob Compression Level value expected, but ''%s'' found at line %d, column %d';
  ErrorGTableAlreadyExists = 'Cannot create table. Table ''%s'' already exists';
  ErrorGErrorCreatingTable = 'Error creating table: ''%s''';
  ErrorGDroppingTable = 'Error dropping table: ''%s''';
  ErrorGErrorAlteringTable = 'Error altering teble: ''%s''';
  ErrorGAddOrDropOrModifyKeywordExpected = 'ADD, DROP or ALTER keyword expected, but ''%s'' found at line %d, column %d';
  ErrorGIndexKeywordExpected = '''INDEX'' keyword expected, but ''%s'' found at line %d, column %d';
  ErrorGIndexNameExpected = 'index name expected, but ''%s'' found at line %d, column %d';
  ErrorGOnKeywordExpected = '''ON'' keyword expected, but ''%s'' found at line %d, column %d';
  ErrorGCannotDetermineExpressionType = 'Cannot determine expression type';
  ErrorGUnsupportedAutoincDataType = 'Unsupported Autoinc DataType (%s) found at line %d, column %d';
  ErrorGDefaultValueReDeclared = 'default value for column ''%s'' declared twice';
  ErrorGUnknownConstrainType = 'Unknown Constraint Type: ''%d''';
  ErrorGIndexNameNotFound = 'Index ''%s'' not found';
  ErrorGMethodNotOverrided = 'The method ''%s'' not overrided in class ''%s''';
  ErrorGCannotRenameField = 'Cannot rename field ''%s''. Field ''%s'' already exists';

  ErrorGrestructureTableError = 'Restructure table error: ''%s''';
  ErrorGParameterValueUndefined = 'Parameter Value undefined (FieldName=''%s'', Type=''%s'')';
  ErrorGParseParameterError = 'Error parsing parameter ''%s'' at line %d, column %d';
  ErrorGParameterValueNotFound = 'Value for parameter ''%s'' not found';

  // TACRDatabaseFile
  ErrorGFileIsClosed = 'Cannot perform this operation (%s) on a closed file';
  ErrorGFileIsOpened = 'Cannot perform this operation (%s) on a opened file';
  ErrorGCreateOpenedFile = 'Cannot create file because file already opened';
  ErrorGCreateFileError = 'Cannot create file: ''%s'' Error code: %d. ErrorMessage: %s';
  ErrorGDeleteFileError = 'Cannot delete file: ''%s'' Error code: %d. ErrorMessage: %s';
  ErrorGRenameFileError = 'Cannot rename file ''%s'' to ''%s'' ErrorCode:%d. ErrorMessage: %s';
  ErrorGOpenFileError = 'Cannot open file:''%s'' Error code: %d. ErrorMessage: %s';
  ErrorGCloseFileError = 'Cannot close file:''%s'' Error code: %d. ErrorMessage: %s';
  ErrorGFileAlreadyOpened = 'File ''%s'' already opened';
  ErrorGFileAlreadyClosed = 'File ''%s'' already closed';
  ErrorGUnknownAccessMode = 'Unknown Access mode: ''%d''';
  ErrorGUnknownShareMode = 'Unknown Share mode: ''%d''';
  ErrorGCannotSetFilePosition = 'Cannot Set File Position to %d. FileName=''%s''. FilePosition = %d, FileSize = %d';
  ErrorGCannotGetFilePosition = 'Cannot Get File Position. FileName=''%s'' ErrorCode:%d. ErrorMessage: %s';
  ErrorGReadFileError = 'Cannot Read from file: ''%s'' Position = %d, Count = %d, FilePosition = %d, FileSize = %d, ErrorCode:%d. ErrorMessage: %s';
  ErrorGWriteFileError = 'Cannot Write to file: ''%s'' Position = %d, Count = %d, FilePosition = %d, FileSize = %d, ErrorCode:%d. ErrorMessage: %s';
  ErrorGCannotTruncateFile = 'Cannot Truncate File ''%s'' to %d bytes. ErrorCode:%d. ErrorMessage: %s';
  ErrorGCannotGetFileSize = 'Cannot Get File Size for file: ''%s''. ErrorCode:%d. ErrorMessage: %s';
  ErrorGBlankFileName = 'Cannot create file with blank FileName';
  ErrorGFlushFileBufferError = 'Cannot flush file buffers for file: ''%s''. ErrorCode:%d. ErrorMessage: %s';

  ErrorGIncorrectSystemDirectoryPageNo = 'Incorrect SystemDirectoryPageNo (DirPageNo=%d, DirPage.PageNo=%d)';

  // Pages
  ErrorGUnknownPageType = 'Unknown Page Type: (%d)';
  ErrorGWrongPageType = 'Wrong page type. Found ''%s'', but wonted: ''%s''';
  ErrorGInvalidPageType = 'Invalid PageType found: %d but wonted: %d';

  ErrorGSystemDirInvalidFirstPageNo = 'Error Creating SystemDirectory. SystemDirectoryPageNo=%d. Real PageNo=%d.';

  
