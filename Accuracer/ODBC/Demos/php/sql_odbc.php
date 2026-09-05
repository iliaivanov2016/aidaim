<?php

////////////////////////////////////////////////////////////////////////////////
//
// Functions
//
////////////////////////////////////////////////////////////////////////////////

function SQLConnect()
{
// $dsn = "acr_DBDemos";
 $dsn = "acr";
// $user = "";
// $password = "";
  $link = odbc_connect($dsn,$user,$password)
  or die ('I cannot connect to the database because: ' . @odbc_errormsg())
  ;
 return $link;
}

function IsEmpty($str)
{
 return (strlen($str) <= 0) ?  true : false;
}

function ParamToSQL($str)
{
 if (IsEmpty($str)) return "";
 $s=str_replace("<br>","\r\n",$str);
 $s=str_replace("\\\"","&quot;",$s);
 $s=str_replace("\\\'","&quot;",$s);
 $s=str_replace("\"","&quot;",$s);
 $s=str_replace("\'","&quot;",$s);
 return $s;
}

function microtime_float()
{
    list($usec, $sec) = explode(" ", microtime());
    return ((float)$usec + (float)$sec);
}

function GetNextQuery($query, &$pos)
{
 $res = false;
 if ($pos==-1)
  return $res;
 $l = strlen($query);
 if ($l > 0)
 {
  $p=strpos($query,";\r\n",$pos);
  if ($p === false)
   $p=strpos($query,";\n",$pos);

//echo("l=".$l."<br>"."p=".$p."<br>");
  if ($p === false)
  {
   $res=substr($query,$pos,$l-$pos);
   $l=strlen($res);
   if ($l > 0)
    if ($res[$l-1] == ';')
     $res[$l-1] = ' ';
   $pos=-1;
  }
  else
  {
   $res=substr($query,$pos,$p-$pos);
   $pos=$p+3;
  }
 }
//echo("res=".nl2br($res)."<br>pos=".$pos."<br><br>");
 return $res;
}

function RunQuery($db,$query, &$ra, &$qr)
{
 $qr = SQLQuery($db,$query);
 if ($qr)
 {
  $ra += SQLRowsAffected($qr);
  return "";
 }
 else
  return "Error executing SQL script: <br>".SQLError(false)."<br>SQL: <br>".$query;
}

function SQLRowsAffected($query)
{
 return @odbc_num_rows($query);
}


function SQLError($db)
{
 $s = @odbc_errormsg($db);
 return $s;
}

function SQLQuery($db,$sql)
{
  $r_time=microtime_float();
  $res=@odbc_exec($db,$sql);
  $r_time=microtime_float()-$r_time;
  @$sql_q=$sql."\r\nURL=".urldecode($_SERVER['REQUEST_URI']);
  return $res;
}

function SQLGetRow($query)
{
 $row=@odbc_fetch_row($query);
 if (!$row)
  return false;
 $n=SQLNumFields($query);
 $res = Array();
 for ($i = 1; $i <= $n; $i++)
  @array_push($res,odbc_result($query,$i));
 return $res;
}

function SQLNumRows($query)
{
 return @odbc_num_rows($query);
}

function SQLNumFields($query)
{
 return @odbc_num_fields($query);
}

function SQLFieldName($query, $field_offset)
{
 return @odbc_field_name($query, $field_offset);
}


////////////////////////////////////////////////////////////////////////////////
//
// Main PHP code
//
////////////////////////////////////////////////////////////////////////////////
$HttpProtocol=($_SERVER["HTTPS"] == "on") ? "https://" : "http://";
$Host=strtolower($HttpProtocol.$_SERVER["HTTP_HOST"]);
$ServerAddr=strtolower($_SERVER["SERVER_ADDR"]);
define("BASE_HOST_URL",$Host);

 $db=SQLConnect();
 $err="";
 $ra=0;
 $r_time=0;
 $ls="";
 $query=$_POST["query"];
 $sql=stripslashes($query);
 $pos=0;
//echo "<br>SQL = <br>".$sql."<br>IsEmpty(sql)=".IsEmpty($sql)."<br>Query = <br>".$query;
 if (!IsEmpty($query))
 {
  while ($q=GetNextQuery($sql,$pos))
  {
   $ls="";
   $s_time=microtime_float();
//echo("q=<br>".nl2br($q)."<br>---------------<br>");
   $err_msg = RunQuery($db,$q,$ra,$qr);
//continue;
   $s_time=microtime_float()-$s_time;
   $r_time+=$s_time;
   if (!IsEmpty($err_msg))
    $err.="<br>".$err_msg;
   else
   {
    $num_rows=SQLNumRows($qr);
    $ls.=sprintf("<br>Script execution time = %01.3f seconds<br>",$r_time);
    $ls.="<br>Rows affected = ".$ra."<br>";
    $ls.="<br>Record count = ".$num_rows."<br>";
    if ((strpos(strtoupper($q),"SELECT")!==false) ||
        (strpos(strtoupper($q),"SHOW")!==false) ||
        (strpos(strtoupper($q),"DESCRIBE")!==false)
        )
    {
     $ls.="<br><TABLE border=2>";
     $ls.="<TR>\r\n";
     for ($i=0; $i < SQLNumFields($qr); $i++)
      $ls.="<TH>".SQLFieldName($qr,$i+1)."</TH>";

     $ls.="\r\n</TR>\r\n";
     if ($num_rows > 0)
      while($row=SQLGetRow($qr))
      {
       $ls.="<TR>";
       $field=0;
       foreach ($row as $value)
       {
        $fieldValue = IsEmpty($value) ? "&nbsp;" : $value;
        $ls.="\r\n<TD>".$fieldValue."</TD>";
        $field++;
       }
       $ls.="</TR>";
      }
     $ls.="</TABLE>";
    }
   }
  }
 }
 else
 {
//  $err = "Empty query";
  $query = "select * from Table1";
 }

////////////////////////////////////////////////////////////////////////////////
//
// HTML
//
////////////////////////////////////////////////////////////////////////////////

?>



<HTML>
<HEAD>
<TITLE>SQL ODBC console</TITLE>
<META http-equiv="Content-Type" content="text/html;">
</HEAD>
<BODY>
<?
 if (!IsEmpty($err))
 {
  echo "<font color = \"red\">".$err."</font><br><br>";
 }
?>
<FORM name = "SQL form" action="<? echo BASE_HOST_URL."/sql_odbc.php"; ?>" method="post">
SQL script:<br>
<TEXTAREA rows="10" name="query" cols="100"><? echo ParamToSQL($query); ?>
</TEXTAREA>
<br>
<INPUT type = "submit" value = "Execute SQL Script">
<?

?>
</FORM>
<br>
<?
  echo $ls;
?>
</BODY>
</HTML>
