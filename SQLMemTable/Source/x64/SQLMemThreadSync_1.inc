{$IFDEF READ_WRITE_THREAD_SYNC}
 {$IFDEF READ_WRITE_THREAD_SYNC_BY_SEMAPHORE}
    FThreadSync := TSQLMemReadWriteThreadSyncBySemaphore.Create;
 {$ELSE}
    FThreadSync := TSQLMemReadWriteThreadSyncByCriticalSections.Create;
 {$ENDIF}
{$ELSE}
 FThreadSync := TSQLMemReadWriteThreadSyncBySingleCriticalSection.Create;
// InitializeCriticalSection(FCSect);
{$ENDIF}
 FThreadSync.Owner := Self;

