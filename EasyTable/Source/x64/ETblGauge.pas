{$I ETblVer.inc}

Unit ETblGauge;

{
  TTETGauge v1.05 by Doodu Ohana  11/98

  This gauge is filled with solid vertical gradient bar,
  marking the % area already done. You can also add text.

  Properties:
   Gradient colors - start (on top) & end (on bottom) colors;
   Background color;
   Min, Max & Progress values;
   Caption;
   Hint;
   AutoText (new) - auto change text to template "progress / max";
   Mouse events;

   Methods:
    Inc (new) - increase progress by 1;
    Dec (new) - decrease progress by 1;

   Vertical gradient is better than horizontal in two ways:
   - It looks better - you can see the gradient also when the
     bar is not full.
   - It's faster (I hope).

   Solid bar is better then non-solid (cubes) because you see text
   better on it.

   This component is absolute FREEWARE. It's a result of my work on
   a project, so it fits my needs and not very customizable. Change
   it as you like and please send me the results. I hope it is bug
   free.

   I decided to release this component (and others) to the public as
   a contribute to the Delphi programmers community, since I have used
   many other's components in my project.


   Contact me: oohana@ort.org.il
   }



Interface

Uses
  Windows, Messages, Sysutils,
  Classes, Graphics, Controls, Forms, Dialogs;

 Const
   Arc1 = 10;

 Type
   TTETGauge = Class(Tgraphiccontrol)
   Private
   Fbmp: TBitmap;
   Fbgcolor, Fscolor, Fecolor: Tcolor;
   Fprogress, Fmax, Fmin : Integer;
   Fautocap: Boolean;
   Text: AnsiString;

   Protected
   Procedure Setcolor1 (Value: Tcolor);
   Procedure Setcolor2 (Value: Tcolor);
   Procedure Setbgcolor (Value: Tcolor);
   Procedure Setmin (Value: Integer);
   Procedure Setmax (Value: Integer);
   Procedure Setprogress (Value: Integer);
   Procedure Settext (Value: AnsiString);
   Procedure Setautocap (Value: Boolean);
   Procedure Gradfill(Clr1, Clr2: Tcolor; Thebitmap: TBitmap);
   Procedure Paint; Override;
   Public
   Constructor Create(Aowner: Tcomponent); Override;
   Destructor Destroy; Override;
   procedure inc;
   procedure dec;
  Published
    Property Backcolor:    Tcolor Read Fbgcolor Write Setbgcolor;
    Property Color1:       Tcolor Read Fscolor Write Setcolor1;
    Property Color2:       Tcolor Read Fecolor Write Setcolor2;
    Property Min:          Integer Read Fmin Write Setmin;
    Property Max:          Integer Read Fmax Write Setmax;
    Property Progress:     Integer Read Fprogress Write Setprogress; 
    Property Caption:      AnsiString Read Text Write Settext; 
    Property Autocaption:  Boolean Read Fautocap Write Setautocap;
  End; 
	
Implementation
Var 
  Percent, Rp: Integer;
  R: TRect; 
  Refreshcap: Boolean;
 
Constructor TTETGauge.Create(Aowner: Tcomponent);
Begin 
  Inherited Create(Aowner); 
  { default values } 
  Width := 200;
  Height := 40;
  Fmin := 1;
  Fmax := 100; 
  Fprogress := Fmin; 
 
  Fscolor := Clwhite;
  Fecolor := Clyellow; 
  Fbgcolor := Clwhite;
	
  Fbmp := TBitmap.Create; 
  Fbmp.Width := Width;
  Fbmp.Height := Height- 5; 
  Gradfill (Fscolor, Fecolor, Fbmp);
 
  Text := 'TETGauge'; 
	
End; 
	
Destructor TTETGauge.Destroy; 
Begin
  Inherited Destroy;
  Fbmp.Free; 
End;
	
{This procedure draws the gradient colors onto the bitmap
 Taken & slightly changed from WordCap by Warren F. Young - 10x ! }
Procedure TTETGauge.Gradfill(Clr1, Clr2: Tcolor; Thebitmap: TBitmap);
Var 
  Rgbfrom: Array[0..2] Of Byte;    { from RGB values                     }
  Rgbdiff: Array[0..2] Of Integer; { difference of from/to RGB values    }
  Colorband: TRect;                  { color band rectangular coordinates  }
  I: Integer;                { color band index                    }
  R: Byte;                   { a color band's R value              } 
  G: Byte;                   { a color band's G value              }
  B: Byte;                   { a color band's B value              } 
Begin
  { extract from RGB values}
  Rgbfrom[0] := GetRValue(Colortorgb(Clr1));
  Rgbfrom[1] := GetGValue(Colortorgb(Clr1));
  Rgbfrom[2] := GetBValue(Colortorgb(Clr1)); 
  { calculate difference of from and to RGB values}
  Rgbdiff[0] := GetRValue(Colortorgb(Clr2)) - Rgbfrom[0]; 
  Rgbdiff[1] := GetGValue(Colortorgb(Clr2)) - Rgbfrom[1]; 
  Rgbdiff[2] := GetBValue(Colortorgb(Clr2)) - Rgbfrom[2];
  { set pen sytle and mode} 
  Thebitmap.Canvas.Pen.Style:= Pssolid; 
  Thebitmap.Canvas.Pen.Mode:= Pmcopy;
  { set color band's left and right coordinates}
  Colorband.Left:= 0;
  Colorband.Right:= Thebitmap.Width; 
  For I := 0 To $Ff Do
  Begin 
    { calculate color band's top and bottom coordinates} 
    Colorband.Top:= MulDiv (I, Thebitmap.Height, $100);
    Colorband.Bottom:= MulDiv (I + 1, Thebitmap.Height, $100); 
    { calculate color band color}
    R := Rgbfrom[0] + MulDiv(I, Rgbdiff[0], $Ff); 
    G := Rgbfrom[1] + MulDiv(I, Rgbdiff[1], $Ff); 
    B := Rgbfrom[2] + MulDiv(I, Rgbdiff[2], $Ff); 
    { select brush and paint color band} 
    Thebitmap.Canvas.Brush.Color := RGB(R, G, B);
    Thebitmap.Canvas.Fillrect(Colorband);
  End; 
End;
 
Procedure TTETGauge.Paint;
Begin 
  If Not Visible Then Exit; 
  Canvas.Pen.Width := 2;
  Canvas.Pen.Color := Clblack;
  Canvas.Pen.Style := Pssolid;
  Canvas.Brush.Style := Bsclear; 
  Canvas.Rectangle(1, 1, Width, Height);
	
  Percent := Round(((Fprogress- Fmin) / (Fmax- Fmin)) * 100); 
  Rp := Percent * (Width - 3) Div 100; 
 
  If Rp<> 0 Then
    Canvas.Copyrect (Rect(2, 2, 1+ Rp, Height- 2),
      Fbmp.Canvas,
      Rect(0, 0, Fbmp.Width, Fbmp.Height));
 
  If Percent < 100 Then Begin
    Canvas.Brush.Color := Fbgcolor; 
    Canvas.Brush.Style := Bssolid; 
    Canvas.Pen.Style := Psclear; 
    Canvas.Pen.Width := 1;
    Canvas.Rectangle (2+ Rp, 2, Width- 2, Height- 2); 
  End; 
	
  R := Rect (0, 0, Width, Height); 
  Canvas.Brush.Style := Bsclear;
  Canvas.Font := Font;
  Drawtext(Canvas.Handle, PAnsiChar(Text), Length(Text), R, Dt_Center Or Dt_Vcenter Or Dt_Singleline);
End;
	
Procedure TTETGauge.Setbgcolor(Value:  Tcolor);
Begin 
  If Value <> Fbgcolor Then 
  Begin 
    Fbgcolor := Value; 
    Invalidate;
  End;
End;
 
Procedure TTETGauge.Setcolor1(Value:  Tcolor); 
Begin 
  If Value <> Fscolor Then 
  Begin
    Fscolor := Value; 
    Gradfill (Fscolor, Fecolor, Fbmp);
    Invalidate; 
  End;
End;

Procedure TTETGauge.Setcolor2(Value:  Tcolor);
Begin
  If Value <> Fecolor Then
  Begin
    Fecolor := Value;
    Gradfill (Fscolor, Fecolor, Fbmp);
    Invalidate;
  End;
End;

Procedure TTETGauge.Settext (Value: AnsiString);
 Begin
   If (Value <> Text) Then
   Begin
     Text := Value;
     Paint;
   End;
 End;

Procedure TTETGauge.Setmin(Value:  Integer);
Begin
  If (Value <> Fmin) And (Value< Fmax) Then
  Begin
    Fmin := Value;
    If (Fprogress< Fmin) Then  Fprogress:= Fmin;
    Invalidate;
  End;
End;

Procedure TTETGauge.Setmax(Value:  Integer);
Begin
  If (Value <> Fmax) And (Fmin< Value)  Then
  Begin
    Fmax := Value;
    If (Fprogress> Fmax) Then  begin
     Fprogress:= Fmax;
    end;
    If Fautocap Then Begin
      Refreshcap := True;
      Setprogress (Fprogress);
    End;
    Invalidate;
  End;
End;

Procedure TTETGauge.Setprogress(Value:  Integer);
Begin
  If (Value <> Fprogress) And (Value<= Fmax) And (Value >= Fmin) Or Refreshcap Then
  Begin
    Fprogress := Value;
    Text := Inttostr (Fprogress) + '/' + Inttostr(Fmax);
    Refreshcap := false;
    Paint;
  End;
End;

Procedure TTETGauge.Setautocap (Value:  Boolean);
Begin
  If (Value <> Fautocap)  Then
  Begin
    Fautocap := Value;
    If Fautocap Then Begin
      Refreshcap := True;
      Setprogress (Fprogress);
    End;
    Invalidate;
  End;
End;

   procedure TTETGauge.inc;
   begin
    setprogress (fprogress+1);
   end;

   procedure TTETGauge.dec;
   begin
    setprogress (fprogress-1);
   end;

End.



