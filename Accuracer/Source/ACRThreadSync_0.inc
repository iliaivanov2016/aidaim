FThreadSync:          TACRReadWriteThreadSync;
(*
{$IFDEF READ_WRITE_THREAD_SYNC}
 {$IFDEF READ_WRITE_THREAD_SYNC_BY_SEMAPHORE}
    FThreadSync:          TACRReadWriteThreadSyncBySemaphore;
 {$ELSE}
    FThreadSync:          TACRReadWriteThreadSyncByCriticalSections;
 {$ENDIF}
{$ELSE}
    FCSect:               TRTLCriticalSection;
{$ENDIF}
*)
