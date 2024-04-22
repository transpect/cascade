import module namespace cascade = "http://transpect.io/cascade" at "cascade.xqm";
import module namespace svn = 'io.transpect.basex.extensions.subversion.XSvnApi';

declare namespace c = "http://www.w3.org/ns/xproc-step";

declare variable $filename as xs:string external;
declare variable $svnuser as xs:string external;
declare variable $svnpass as xs:string external;
declare variable $svnauth := map{'username':$svnuser,'cert-path':'', 'password': $svnpass};        
declare variable $fire as xs:boolean external := false();

(: $filename is expected to be a local file with a path relative to the current working directory
or with an absolute path. It will be copied to the svn working copy :)

cascade:ensure-versionability(
  $filename,
  $svnuser, $svnpass,
  map{'multi-article-repos': cascade:ensure-versionability-multi-article#5,
      'ext-to-subdir': cascade:subdir-for-ext-from-params#2,
      'image-subdir': cascade:simple-image-subdir-for-ext-from-params#2
     },
  $fire
)