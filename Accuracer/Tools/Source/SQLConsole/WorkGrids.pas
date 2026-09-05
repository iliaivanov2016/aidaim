unit WorkGrids;

interface

uses Grids;

 procedure FillGrid(Grid:TStringGrid; s:string);
 function GetString(Grid:TStringGrid):string;
 procedure EmptyGrid(Grid:TStringGrid);

implementation

procedure FillGrid(Grid:TStringGrid; s:string);
 var temp : string;
    Row,Col : integer;
begin
 temp := s;
 Row := 0;
 Col := 0;
 while length(temp) > 0 do
  begin
   Grid.Cells[Col,Row] := temp[1]+temp[2];
   Delete(temp,1,2);
   Col := Col + 1;
   if Col = 8 then
    begin
     Row := Row+1;
     Col := 0;
    end;
  end;
end;

function GetString(Grid:TStringGrid):string;
var temp : string;
    Row,Col : integer;
begin
 temp := '';
 for Row := 0 to Grid.RowCount do
  for Col := 0 to Grid.ColCount do
    if length(Grid.Cells[Col,Row]) = 1 then
     temp := temp + '0' + Grid.Cells[Col,Row]
    else
     temp := temp + Grid.Cells[Col,Row];
 Result := temp;
end;

procedure EmptyGrid(Grid:TStringGrid);
var Row,Col : integer;
begin
 for Row := 0 to Grid.RowCount do
  for Col := 0 to Grid.ColCount do
    Grid.Cells[Col,Row] := '';
end;

end.
 