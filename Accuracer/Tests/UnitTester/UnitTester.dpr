program UnitTester;

{$I UTConfig.inc}

{$IFDEF CONSOLE}
{$APPTYPE CONSOLE}
{$ENDIF}

{$I ACRVer.inc}
{$O-}
{$R+}
{$Q+}

uses

//  ExceptionLog,
  ExceptionLog,
  Forms,
  MainForm in 'MainForm.pas' {Form1},
{$IFDEF DEBUG_MEMCHECK}
  MemCheck,
{$ENDIF}  
  SysUtils,
  DB in 'DB.pas',
  ACRConst,
  uTestList in 'uTestList.pas'

  ,utTemporaryTableEngine in 'utTemporaryTableEngine.pas'
  ,utAcrTypesRoutines in 'utAcrTypesRoutines.pas'
  ,utStrUtils in 'utStrUtils.pas'
  ,utBasicComponentsTest in 'utBasicComponentsTest.pas'
  ,utCompareDataValues in 'utCompareDataValues.pas'
  ,utConstraints in 'utConstraints.pas'
  ,utReferentialIntegrity in 'utReferentialIntegrity.pas'
  ,utConvertDateTime in 'utConvertDateTime.pas'
  ,utDefaultValue in 'utDefaultValue.pas'
  ,utDefs in 'utDefs.pas'
  ,utDistinctAndProjection in 'utDistinctAndProjection.pas'
  ,utExportImportTable in 'utExportImportTable.pas'
  ,utKeyAndRange in 'utKeyAndRange.pas'
  ,utLoadSaveMemoryTable in 'utLoadSaveMemoryTable.pas'
  ,utLoadSaveTemporaryTable in 'utLoadSaveTemporaryTable.pas'
  ,utMasterDetail in 'utMasterDetail.pas'
  ,utMemoryManager in 'utMemoryManager.pas'
  ,utMemoryTableEngine in 'utMemoryTableEngine.pas'
  ,utSearchAndFilter in 'utSearchAndFilter.pas'
  ,utFilteredRecNoAndRecordCount in 'utFilteredRecNoAndRecordCount.pas'
  ,utRecNoAndRecordCount in 'utRecNoAndRecordCount.pas'
  ,utRestructure in 'utRestructure.pas'


  ,utAutoInc in 'utAutoInc.pas'
  ,utDatabaseOptions in 'utDatabaseOptions.pas'
  ,utDiskDatabase in 'utDiskDatabase.pas'
  ,utDiskTableEngine in 'utDiskTableEngine.pas'
  ,utTransactions in 'utTransactions.pas'
  ,utDBFile in 'utDBFile.pas'
  ,utRandomAndTempNames in 'utRandomAndTempNames.pas'
  ,utIndexTest in 'utIndexTest.pas'
  ,utIndexTestd4 in 'utIndexTestd4.pas'
  ,utBLOBSystem in 'utBLOBSystem.pas'
  ,utStringTest in 'utStringTest.pas'
  ,utSharedTables in 'utSharedTables.pas'
  ,utLoadSaveMemoryDatabases in 'utLoadSaveMemoryDatabases.pas'
  ,utMemoryDatabases in 'utMemoryDatabases.pas'
  ,utParams in 'utParams.pas'

  ,utACRQuery in 'utACRQuery.pas'

  {$IFNDEF NO_NETWORK}
  ,utEvents in 'utEvents.pas'
  ,utDisconnect in 'utDisconnect.pas'
{$IFDEF ACR6H}
  ,utNetworkTCP in 'utNetworkTCP.pas'
  ,utNetworkUDP in 'utNetworkUDP.pas'
{$ENDIF}
  ,utNetwork in 'utNetwork.pas'
  ,utConnection in 'utConnection.pas'
  ,utCSDatabase in 'utCSDatabase.pas'
  ,utServerCommands in 'utServerCommands.pas'
  {$ENDIF}
  {$IFDEF ACR5H}
  ,utStoredProcedures in 'utStoredProcedures.pas'
  ,utComments in 'utComments.pas'
  ,utWideStringList in 'utWideStringList.pas'
  {$ENDIF}
{$IFDEF ACR6H}
  ,utViews in 'utViews.pas'
{$ENDIF}
  ,utEncryption in 'utEncryption.pas'
  ,utACRSQLPerformance in 'utACRSQLPerformance.pas'

  ;

{$IFNDEF CONSOLE}
{$R *.res}
{$ENDIF}

begin
  {$IFDEF DEBUG_MEMCHECK}
  MemChk;
  {$ENDIF}
{$IFNDEF CONSOLE}
  Application.Initialize;
//  Application.CreateForm(TForm1, Form1);
  Form1 := TForm1.Create(Nil);
  Form1.Show;
  Application.Run;
{$ENDIF}

{$IFDEF CONSOLE}
  writeln('Unit Tester - Accuracer version: '+FloatToStrF(ACRVersion,ffFixed,3,2) + ' ' + ACRVersionText);
  writeln('Run Tests.');
{$ELSE}
  Form1.MainLog.Lines.Add('Unit Tester - Accuracer version: '+FloatToStrF(ACRVersion,ffFixed,3,2) + ' ' + ACRVersionText);
  Form1.MainLog.Lines.Add('Run Tests.');
{$ENDIF}
 try
  try

//   UnitTestComments.TestAll;
//   UnitTestViews.TestExceptions;
//exit;
   UnitTestViews.TestShort;
   exit;
//   UnitTestDiskTableEngine.TestShort;
//   exit;
//    UnitTestLoadSaveMemoryDatabases.TestShort;
//      UnitTestReferentialIntegrity.TestShort;
//    exit;
//   UnitTestWideStringList.TestShort;
//   exit;
//    UnitTestAutoinc.TestShort;
//    UnitTestStoredProcedures.TestShort;
//    exit;
//  UnitTestReferentialIntegrity.TestShort;
//    UnitTestReferentialIntegrity.TestExceptions;
//    UnitTestReferentialIntegrity.TestAll;
//   UnitTestStringTest.TestShort;
//UnitTestACRQuery.TestShort;
//  UnitTestACRQuery.TestExceptions;
//exit;
//   UnitTestLoadSaveTemporaryTable.TestShort;
//   exit;
//   UnitTestMasterDetail.TestShort;
//   exit;
//    UnitTestEncryption.TestShort;
//    UnitTestEncryption.TestShort;
//   UnitTestRandomAndTempNames.TestAll;
//  exit;
//   UnitTestACRQuery.TestShort;
//   UnitTestACRQuery.TestAll;

//   UnitTestACRQuery.TestExceptions;
//   exit;
//   UnitTestACRQuery.TestExceptions;
//   UnitTestMemoryTableEngine.TestShort;
// exit;
//   UnitTestLoadSaveMemoryDatabases.TestAll;
//   UnitTestMemoryDatabases.TestShort;
//   UnitTestComments.TestShort;
//   exit;
//     UnitTestParams.TestShort;
//     exit;
//     UnitTestParams.TestAll;
//     UnitTestCSDatabase.TestShort;
//     UnitTestCSDatabase.TestAll;
//     UnitTestConnection.TestShort;
//     UnitTestConnection.TestExceptions;
//     UnitTestConnection.TestAll;
//     exit;
//   UnitTestSearchAndFilter.TestShort;
//   exit;
//     UnitTestIndexTest.TestAll;
//     UnitTestIndexTest.TestShort;
//    UnitTestTransactions.TestAll;
//    UnitTestTransactions.TestExceptions;
//    UnitTestTransactions.TestShort;
//   UnitTestDiskDatabase.TestAll;
//   UnitTestDatabaseOptions.TestShort;
//   UnitTestDiskDatabase.TestExceptions;
//   UnitTestDiskTableEngine.TestAll;
//   UnitTestDiskTableEngine.TestShort;
//   exit;
//  UnitTest
//    UnitTestAutoinc.TestShort;
//   UnitTestComments.TestAll;
//   exit;
//   UnitTestDiskTableEngine.TestAll;
//   UnitTestMemoryTableEngine.TestShort;
//   UnitTestTemporaryTableEngine.TestAll;
//   UnitTestTemporaryTableEngine.TestShort;
//   exit;
//     UnitTestMemoryDatabases.TestAll;
//     UnitTestParams.TestAll;
//     exit;
//     UnitTestIndexTest.TestShort;
//    UnitTestCompareDataValues.TestShort;
// UnitTestBLOBSystem.TestShort;
//    exit;
//   UnitTestACRSQLPerformance.TestShort;
//     UnitTestLockManager.TestShort;
//  UnitTestMemoryTableEngine.TestExceptions;
//  UnitTestMemoryTableEngine.TestExceptions;
//  UnitTestMemoryTableEngine.TestShort;
//  UnitTestDiskTableEngine.TestExceptions;
//  exit;
{
   UnitTestTemporaryTableEngine.TestAll;
//   UnitTestImportExportTable.TestAll;
//  exit;
//   UnitTestSharedTables.TestShort;
  UnitTestDiskTableEngine.TestShort;
   UnitTestACRQuery.TestAll;
 }
//  UnitTestTransactions.TestShort;
//  UnitTestTransactions.TestAll;
// exit;

//     UnitTestACRQuery.TestShort;
//     exit;
//     UnitTestACRQuery.TestAll;
//     UnitTestStringTest.TestShort;
//   exit;
{
     UnitTestEvents.TestAll;
     UnitTestNetwork.TestAll;
     UnitTestConnection.TestAll;
     UnitTestCSDatabase.TestAll;
     UnitTestEncryption.TestAll;
//     UnitTestCSDatabase.TestShort;
     exit;
}
//     UnitTestConnection.TestShort;
//     UnitTestCSDatabase.TestAll;
//     exit;
  {
     UnitTestParams.TestAll;
     UnitTestACRQuery.TestAll;

     UnitTestConnection.TestAll;
     UnitTestCSDatabase.TestAll;
     exit;

     UnitTestACRQuery.TestAll;
     UnitTestParams.TestAll;
}
//     exit;
//    UnitTestCSDatabase.TestShort;
//   UnitTestACRSQLPerformance.TestShort;
//    UnitTestCSDatabase.TestShort;
//    UnitTestCSDatabase.TestExceptions;
//     UnitTestReferentialIntegrity.TestShort;
//     exit;
//     UnitTestReferentialIntegrity.TestAll;
//     UnitTestRestructure.TestAll;
//     UnitTestParams.TestShort;
//     exit;
{
    UnitTestConnection.TestShort;
    UnitTestConnection.TestExceptions;
    UnitTestCSDatabase.TestExceptions;
     Exit;
    UnitTestCSDatabase.TestShort;
    UnitTestCSDatabase.TestExceptions;
     UnitTestTemporaryTableEngine.TestAll;
     UnitTestDiskTableEngine.TestAll;


//     UnitTestConnection.TestAll;

     UnitTestLockManager.TestAll;
     UnitTestDBFile.TestAll;
     UnitTestParams.TestAll;
     UnitTestDiskDatabase.TestAll;
     UnitTestACRQuery.TestAll;
     UnitTestDistinctAndProjection.TestAll;
     UnitTestAutoinc.TestAll;
     UnitTestStringTest.TestAll;
     UnitTestDatabaseOptions.TestAll;
}

//   exit;
// UnitTestParams.TestShort;
//  UnitTestEvents.TestAll;
//     UnitTestReferentialIntegrity.TestShort;
// exit;
//  UnitTestKeyAndRange.TestShort;
//  UnitTestStringTest.TestShort;
//    UnitTestLoadSaveTemporaryTable.TestShort;
//    UnitTestCSDatabase.TestShort;
//    UnitTestCSDatabase.TestExceptions;
// exit;
//     UnitTestReferentialIntegrity.TestShort;
//     UnitTestReferentialIntegrity.TestExceptions;
//    UnitTestConnection.TestShort;
//    UnitTestConnection.TestExceptions;
//     UnitTestReferentialIntegrity.TestExceptions;
//  UnitTestRestructure.TestShort;
//    UnitTestNetwork.TestShort;
//    UnitTestACRQuery.TestShort;
//    exit;
//    UnitTestACRQuery.TestShort;
//    UnitTestACRQuery.TestExceptions;
//exit;
//    UnitTestDiskTableEngine.TestShort;
{
    UnitTestDiskTableEngine.TestShort;
    UnitTestACRQuery.TestShort;
    UnitTestDiskDatabase.TestShort;
    UnitTestDiskTableEngine.TestShort;
}
{
    UnitTestNetwork.TestShort;

    UnitTestConnection.TestShort;
    UnitTestConnection.TestExceptions;
exit;
}
//    UnitTestCSDatabase.TestShort;
//    UnitTestCSDatabase.TestExceptions;
//    UnitTestConnection.TestShort;
//    UnitTestConnection.TestExceptions;
 // UnitTestACRQuery.TestShort;
//  UnitTestACRQuery.TestAll;
//  exit;
// UnitTestMemoryDatabases.TestShort;
//  UnitTestRestructure.TestShort;
//    UnitTestFilteredRecNoAndRecordCount.TestShort;
//    UnitTestRecNoAndRecordCount.TestShort;
//    UnitTestT.TestShort;
// UnitTestParams.TestShort;
//  UnitTestTransactions.TestShort;
//  UnitTestTransactions.TestAll;
// UnitTestConstraints.TestShort;
// UnitTestConstraints.TestExceptions;
//// UnitTestSearchAndFilter.TestShort;
/// exit;
//  UnitTestStringTest.TestShort;
//  UnitTestDefaultValue.TestShort;
//  UnitTestDefaultValue.TestExceptions;
//  exit;
//    UnitTestFilteredRecNoAndRecordCount.TestShort;
// UnitTestTransactions.TestExceptions;
// exit;
// UnitTestLoadSaveMemoryTable.TestShort;
// UnitTestSearchAndFilter.TestShort;
// UnitTestRandomAndTempNames.TestAll;
//   UnitTestFilteredRecNoAndRecordCount.TestShort;
//exit;
   UnitTestList.TestShort;
   UnitTestList.TestExceptions;

  except
    on e:Exception do
{$IFDEF CONSOLE}
   writeln(#13#10'Error: ' + e.Message);
{$ELSE}
      Form1.MainLog.Lines.Add(#13#10'Error: ' + e.Message);
{$ENDIF}
  end;
{$IFDEF CONSOLE}
 finally
  writeln('All Done.');
 end;
{$ELSE}
 finally
    Form1.MainLog.Lines.Add('All Done.');
    repeat
      Application.ProcessMessages;
    until not Form1.Visible;
 end;
{$ENDIF}
end.
