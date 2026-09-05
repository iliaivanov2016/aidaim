function addhref(url, text)
{
document.write('<a href="'+url+'">'+text+'</a>');
}

function addhrefblank(url, text)
{
document.write('<a href="'+url+'" target=_blank>'+text+'</a>');
}

function addmail(domain, name, text, prm)
{
document.write('<a href=mailto:"'+name+'@'+domain+'" '+prm+'>'+text+'</a>');
}

function addaidaimmail(name, text)
{
document.write('<a href="mailto:'+name+'@'+'aidaim.com">'+text+'</a>');
}

function addaidaimparammail(name, text, param)
{
document.write('<a href="mailto:'+name+'@'+'aidaim.com" '+param+'>'+text+'</a>');
}

function addaidaimparam2mail(name, text, param, param1, param2)
{
document.write(param1+'<a href="mailto:'+name+'@'+'aidaim.com" '+param+'>'+text+'</a>'+param2);
}

function addaidaimfootermail(name, text)
{
document.write('<b><a href="mailto:'+name+'@'+'aidaim.com" class="btm">'+text+'</a></b>');
}
