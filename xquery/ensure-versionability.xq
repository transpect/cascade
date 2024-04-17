import module namespace cascade = "http://transpect.io/cascade" at "cascade.xqm";
import module namespace svn = 'io.transpect.basex.extensions.subversion.XSvnApi';

declare namespace c = "http://www.w3.org/ns/xproc-step";

declare variable $filename as xs:string external;
declare variable $svnuser as xs:string external;
declare variable $svnpass as xs:string external;
declare variable $svnauth := map{'username':$svnuser,'cert-path':'', 'password': $svnpass};        
declare variable $fire as xs:boolean external := false();

cascade:ensure-versionability(
  $filename,
  $svnuser, $svnpass,
  map{'multi-article-repos': cascade:ensure-versionability-multi-article#5 },
  $fire
)