//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "uHistory.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TfmHistory *fmHistory;
//---------------------------------------------------------------------------
__fastcall TfmHistory::TfmHistory(TComponent* Owner)
  : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TfmHistory::ShowHistory(TDataSet *ds)
{
  int i,row;

  gbMessages->Caption = " Messages found: "+IntToStr(ds->RecordCount)+" ";
  ds->First();
  row = 1;
  sgHistory->RowCount = 2;
  sgHistory->FixedRows = 1;
  for (i = 0; i < sgHistory->ColCount;i++)
   sgHistory->Cells[i][1] = "";
  while (!ds->Eof)
   {
    if (row >= sgHistory->RowCount) 
     sgHistory->RowCount = sgHistory->RowCount+1;
    sgHistory->Cells[0][row] = DateToStr(ds->FieldByName("SendingDate")->AsDateTime);
    sgHistory->Cells[1][row] = TimeToStr(ds->FieldByName("SendingDate")->AsDateTime);
    if (rgMessageType->ItemIndex == 2)
     sgHistory->Cells[2][row] = IntToStr(ds->FieldByName("RecipientID")->AsInteger);
    else
     sgHistory->Cells[2][row] = IntToStr(ds->FieldByName("SenderID")->AsInteger);
    sgHistory->Cells[3][row] = ds->FieldByName("MessageText")->AsString;
    ds->Next();
    row++;
   }
}
void __fastcall TfmHistory::bnCancelClick(TObject *Sender)
{
 FClose = true;
}
//---------------------------------------------------------------------------
void __fastcall TfmHistory::FormShow(TObject *Sender)
{
 FClose = False;
 gbMessages->Caption = " Messages found: 0 ";  
}
//---------------------------------------------------------------------------
void __fastcall TfmHistory::FormClose(TObject *Sender,
      TCloseAction &Action)
{
 if (! FClose) 
  Action = Forms::caNone;  
}
//---------------------------------------------------------------------------
void __fastcall TfmHistory::FormCreate(TObject *Sender)
{
  dtpFrom->Date = Now();
  dtpTo->Date = Now();
  sgHistory->ColCount = 4;
  sgHistory->RowCount = 2;
  sgHistory->FixedRows = 1;
  sgHistory->Cells[0][0] = "Date";
  sgHistory->Cells[1][0] = "Time";
  sgHistory->Cells[2][0] = "Sender";
  sgHistory->Cells[3][0] = "Message";
  sgHistory->ColWidths[0] = 70;
  sgHistory->ColWidths[1] = 70;
  sgHistory->ColWidths[2] = 100;
  sgHistory->ColWidths[3] = 200;
  cbMessage->ItemIndex = 0;
}
//---------------------------------------------------------------------------
void __fastcall TfmHistory::cbFromClick(TObject *Sender)
{
  dtpFrom->Enabled = cbFrom->Checked;
}
//---------------------------------------------------------------------------
void __fastcall TfmHistory::cbToClick(TObject *Sender)
{
  dtpTo->Enabled = cbTo->Checked;
}
//---------------------------------------------------------------------------
void __fastcall TfmHistory::bnShowHistoryClick(TObject *Sender)
{
    TMsgTextComparison mc,mc1;
    TMsgDateComparison sd,dd;
    TDataSet *ds;
    int code;
    unsigned int SenderID,RecipientID;
 memset(&mc,0x00,sizeof(mc));
 memset(&mc1,0x00,sizeof(mc1));
 memset(&sd,0x00,sizeof(sd));
 memset(&dd,0x00,sizeof(dd));
 if (rgMessageType->ItemIndex == 1)
  {
   SenderID = MSG_INVALID_USER_ID;
   RecipientID = fmMain->MsgClient1->UserID;
  }
 else
 if (rgMessageType->ItemIndex == 2)
  {
   SenderID = fmMain->MsgClient1->UserID;
   RecipientID = MSG_INVALID_USER_ID;
  }
 else
  {
   SenderID = fmMain->MsgClient1->UserID;
   RecipientID = fmMain->MsgClient1->UserID;
  }
 if (eMessage->Text != "")
  {
   switch (cbMessage->ItemIndex)
   {
    case 1: mc.Comparison = mscmpStarts; break;
    case 2: mc.Comparison = mscmpContains; break;
    default: mc.Comparison = mscmpExact;
   }
   mc.CaseInsensitive = chbIgnoreCase->Checked;
  }
 if (cbFrom->Checked)
   {
    sd.DateTime1 = dtpFrom->Date;
    sd.Comparison1 = mcmpopGreaterEqual;
   }
 if (cbTo->Checked) 
   {
    sd.DateTime2 = dtpTo->Date+1;
    sd.Comparison2 = mcmpopLower;
   }
 code = fmMain->MsgClient1->FindMessages(ds,cbLocal->Checked,
                        mc,mc1,sd,dd,False,True,
                        eMessage->Text,"",
                        SenderID,RecipientID,Msgtypes::aamtText,
                        -1, false, "", 0
                          );
 if (code == MSG_COMMAND_OK)
  try
  {
    if (rgMessageType->ItemIndex == 2)
     sgHistory->Cells[2][1] = "Sender";
    else
     sgHistory->Cells[2][1] = "Recipient";
    ShowHistory(ds);
  }
  __finally
  {
    delete ds;
  }
 else
   ShowMessage("Cannot find messages. Error code = "+IntToStr(code));
}
//---------------------------------------------------------------------------
void __fastcall TfmHistory::sgHistoryMouseMove(TObject *Sender,
      TShiftState Shift, int X, int Y)
{
  int ARow, ACol;
  sgHistory->ShowHint = False;
  sgHistory->MouseToCell(X,Y,ACol,ARow);
  if ((ACol >= 0) && (ARow >= 0) &&
      (ACol < sgHistory->ColCount) &&
      (ARow < sgHistory->RowCount))
   {
    sgHistory->Hint = sgHistory->Cells[ACol][ARow];
    sgHistory->ShowHint = true;
   }
}
//---------------------------------------------------------------------------
