//---------------------------------------------------------------------------
#ifndef BkThreadH
#define BkThreadH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <EasyTable.hpp>
//---------------------------------------------------------------------------
class TQueryThread : public TThread
{
private:
    TEasySession* Session;
    TEasyDatabase* Database;
    TEasyQuery* Query;

    void __fastcall UpdateGrid();

protected:
        void __fastcall Execute();
public:
        __fastcall TQueryThread(bool CreateSuspended);
};
//---------------------------------------------------------------------------
#endif
