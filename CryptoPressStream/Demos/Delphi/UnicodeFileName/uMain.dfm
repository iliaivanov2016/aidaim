object Form1: TForm1
  Left = 289
  Top = 103
  Width = 696
  Height = 480
  Caption = 
    'UnicodeFileName demo. (c) AidAim Software, 2009. http://www.aida' +
    'im.com'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object CPSManager1: TCPSManager
    CurrentVersion = '2.00 '
    CompressionAlgorithm = caZLIB
    CompressionMode = 9
    BlockSize = 1048576
    NumCachedBlocks = 1
    MaxTempBufferSize = 10485760
    CryptoParams.CryptoAlgorithm = craNone
    CryptoParams.CryptoMode = acmCTS
    CryptoParams.KeySize = 56
    CryptoParams.Password = 'CPSpassword'
    CryptoParams.UseInitVector = False
    CryptoParams.InitVectorSize = 0
    TempDirAnsi = 'C:\Documents and Settings\leo\Local Settings\Temp'
    TempDirUnicode = 'C:\Documents and Settings\leo\Local Settings\Temp'
    TempDir = 'C:\Documents and Settings\leo\Local Settings\Temp'
    Left = 160
    Top = 144
  end
end
