{$IFDEF READ_WRITE_THREAD_SYNC}
 {$IFDEF READ_WRITE_THREAD_SYNC_BY_SEMAPHORE}
    FThreadSync := TACRReadWriteThreadSyncBySemaphore.Create;
 {$ELSE}
    FThreadSync := TACRReadWriteThreadSyncByCriticalSections.Create;
 {$ENDIF}
{$ELSE}
 FThreadSync := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
// InitializeCriticalSection(FCSect);
{$ENDIF}
 FThreadSync.Owner := Self;

