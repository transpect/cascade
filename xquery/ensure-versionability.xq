import module namespace cascade = "http://transpect.io/cascade" at "cascade.xqm";
import module namespace svn = 'io.transpect.basex.extensions.subversion.XSvnApi';

(: This is an example script for journals that you may use as a template for your own customization’s XQuery file. 
 It might be necessary to add more helper function hooks in cascade.xqm. Please file pull requests. :)

declare namespace c = "http://www.w3.org/ns/xproc-step";
declare namespace hobots = "http://www.hogrefe.com/namespace/hobots";

declare variable $filename as xs:string external;
declare variable $svnuser as xs:string? external := '';
declare variable $svnpass as xs:string? external := '';
declare variable $realmstring-regex as xs:string? external := ();
declare variable $fire as xs:boolean external := false();

(: $filename is expected to be a local file with a path relative to the current working directory
or with an absolute path. It will be copied to the svn working copy :)

declare function hobots:xml-subdir (
  $params-for-filename as element(c:param-set),
  $helper-functions as map(xs:string, function(*))
) as xs:string { 'hojots'};

let $svnauth := if ($realmstring-regex) then cascade:scan-svn-simple-auth($realmstring-regex)[1]
                                          else map{'username':$svnuser,'cert-path':'', 'password': $svnpass}
return
cascade:ensure-versionability(
  $filename,
  $svnauth,
  map{'multi-article-repos': cascade:ensure-versionability-multi-article#5,
      'ext-to-subdir': cascade:subdir-for-ext-from-params#2,
      'image-subdir': cascade:simple-image-subdir-for-ext-from-params#2,
      'xml-subdir': hobots:xml-subdir#2
     },
  $fire
)