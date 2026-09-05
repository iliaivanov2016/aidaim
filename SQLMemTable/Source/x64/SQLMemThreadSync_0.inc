FThreadSync:          TSQLMemReadWriteThreadSync;
(*
{$IFDEF READ_WRITE_THREAD_SYNC}
 {$IFDEF READ_WRITE_THREAD_SYNC_BY_SEMAPHORE}
    FThreadSync:          TSQLMemReadWriteThreadSyncBySemaphore;
 {$ELSE}
    FThreadSync:          TSQLMemReadWriteThreadSyncByCriticalSections;
 {$ENDIF}
{$ELSE}
    FCSect:               TRTLCriticalSection;
{$ENDIF}
*)
