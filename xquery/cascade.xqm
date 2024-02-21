module namespace cascade = "http://transpect.io/cascade";

import module namespace svn = 'io.transpect.basex.extensions.subversion.XSvnApi';

declare namespace c = "http://www.w3.org/ns/xproc-step";
declare namespace jats = "http://jats.nlm.nih.gov";

declare function cascade:load-cascaded-xml($param-set as element(c:param-set), $relative-path) as document-node()? {
  let $paths as element(c:param) := $param-set/c:param[matches(@name, '^s9y\d')],
      $sorted as element(c:param) := sort($paths, (), function($param) { $param/@name})
  return cascade:load-most-specific-xml($sorted, $relative-path)
};

declare function cascade:load-most-specific-xml($path-params as element(c:param)*, $relative-path) as document-node()? {
  if (empty($path-params))
  then ()
  else if (file:exists($path-params[1] || $relative-path))
       then doc($path-params[1] || $relative-path)
       else cascade:load-most-specific-xml(tail($path-params), $relative-path)
};

declare function cascade:params-for-filenames($filenames as xs:string+) as element(c:results) {
  let $filename-xml := document{<c:filenames>{
    for $fn in tokenize($filenames)
    return <c:file name="{$fn}"/>
  }</c:filenames>}
  return xslt:transform($filename-xml, 'param-set.xsl')/*
};

declare function cascade:params-for-filename($filename as xs:string) as element(c:param-set) {
  let $param-set := cascade:params-for-filenames($filename)/c:param-set
  return 
    if ($param-set/c:param[@name = 'matching-clades']/@value = '1')
    then $param-set
    else if ($param-set/c:param[@name = 'matching-clades']/@value = '0')
         then error(xs:QName('cascade:ERR-params-01'), 'No matching clade found for ' || $filename, $param-set)
         else error(xs:QName('cascade:ERR-params-02'), 'Multiple matching clades found for ' || $filename, $param-set)
};

declare function cascade:ensure-versionability(
    $filename as xs:string, 
    $svnuser as xs:string, $svnpass as xs:string,
    $helper-functions as map(xs:string, function(*)),
    $fire as xs:boolean
  ) as xs:string {
  let $svnauth := map{'username':$svnuser,'cert-path':'', 'password': $svnpass},
      $params-for-filename := 
        try {cascade:params-for-filename($filename) }
        catch cascade:ERR-params-01 { 
          prof:dump($err:value),
          error($err:code, $err:description)
        },
      $repo-url as xs:string := string($params-for-filename/c:param[@name='content-repo-location']/@value),
      $repo-info := cascade:svn-info($repo-url, $svnauth),
      $repo-layout := string($params-for-filename/c:param[@name='content-repo-layout']/@value)
   return $helper-functions($repo-layout)($params-for-filename, $repo-info, $svnauth, $helper-functions, $fire)
};

declare function cascade:ensure-versionability-multi-article (
  $params-for-filename as element(c:param-set),
  $repo-info as element(c:param-set),
  $svnauth as map(xs:string, xs:string),
  $helper-functions as map(xs:string, function(*)),
  $fire as xs:boolean
) as xs:string {
  (: It is expected that there is a specificity role called 'volume-type' that can assume
     the values 'Vol' or 'ahead-of-print' (unassigned to a specific journal volume/issue yet) :)
  let $volume-type as xs:string := cascade:s9y-lookup($params-for-filename, 'volume-type', ''),
      $ms-wc-dir as xs:string := cascade:s9y-lookup($params-for-filename, 'ms', '-path'),
      $ms-parent-dir := file:parent($ms-wc-dir)
  return $ms-parent-dir
};

declare function cascade:s9y-lookup (
    $paths as element(c:param-set), 
    $role as xs:string,
    $target-suffix as xs:string
  ) as xs:string {
  let $s9y-role as xs:string := $paths/c:param[matches(@name, '^s9y\d-role$')][@value = $role]/@name ! string(.)
  return $paths/c:param[@name = replace($s9y-role, '-role$', $target-suffix)]/@value ! string(.)
};

declare function cascade:update-svn-wc ($dir as xs:string, $svnauth as map(xs:string, xs:string)) as xs:string {
  if (not(file:exists($dir)))
  then let $parent as xs:string? := file:parent($dir)
       return if ($parent)
              then cascade:update-svn-wc($parent, $svnauth)
              else error(xs:QName('cascade:ERR-svn-01'), 'Cannot find svn working copy at ' || $dir)
  else let $svn-info := cascade:svn-info($dir, $svnauth)
       return $dir
};

declare function cascade:svn-info($repo-url as xs:string, $svnauth as map(xs:string, xs:string)) as element(c:param-set) {
  let $repo-info :=
    try { svn:info($repo-url, $svnauth) }
    catch err:XPTY0004 {(: an error 'java.lang.NullPointerException: Cannot invoke "String.length()" because "string" is null. 
      Caused by: io.transpect.basex.extensions.subversion.XSvnApi:info(String, map(xs:string, xs:string)).' 
      will be thrown for still-empty repos :)
      <c:param-set>
        <c:param name="rev" value="0"/>
        <c:param name="root-url" value="https://hobotssvn.hogrefe.com/BookTagSet/werke/101024_a000750"/>
        <c:param name="nodekind" value="dir"/>
        <c:param name="url" value="https://hobotssvn.hogrefe.com/BookTagSet/werke/101024_a000750"/>
      </c:param-set>}
  return 
    if ($repo-info/self::c:errors)
    then error(xs:QName('cascade:ERR-EV-01'), 
               'Error accessing a repo at ' || $repo-url 
               || '. Maybe it needs to be created first.', $repo-info)
    else $repo-info 
};