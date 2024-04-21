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
  ) as item()* {
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
) as item()* {
  (: It is expected that there is a specificity role called 'volume-type' that can assume
     the values 'Vol' or 'ahead-of-print' (unassigned to a specific journal volume/issue yet) :)
  let $volume-type as xs:string := cascade:s9y-lookup($params-for-filename, 'volume-type', ''),
      $ms-wc-dir as xs:string := cascade:s9y-lookup($params-for-filename, 'ms', '-path'),
      $ms-external-mountpoint as xs:string := ($ms-wc-dir => tokenize('/'))[normalize-space()][last()],
      $ms-external-url as xs:string := string-join(
                                           (string($params-for-filename/c:param[@name='content-repo-location']/@value),
                                            $ms-external-mountpoint),
                                           '/'),
      $ms-parent-dir := file:parent($ms-wc-dir),
      $missing-wc-dirs as xs:string* := cascade:update-svn-wc($ms-parent-dir, $svnauth, (), $fire)
  return (
    for $d in $missing-wc-dirs
    return cascade:svn-mkdir-if-inexistent($d, $svnauth, true(), $fire),
    cascade:svn-mkdir-if-inexistent($ms-external-url, $svnauth, false(), $fire),
    cascade:ensure-external-exists($ms-parent-dir, $ms-external-url, $ms-external-mountpoint, $svnauth, $fire)
  )
};

declare function cascade:ensure-external-exists (
    $wc-path as xs:string,
    $external-url as xs:string,
    $mountpoint as xs:string,
    $svnauth as map(xs:string, xs:string),
    $fire as xs:boolean
  ) as item()* {
  let $current-externals as element(external)* := cascade:get-svn-externals($wc-path, ())
  return cascade:merge-svn-externals(
           $wc-path, 
           ($current-externals, <external url="{$external-url}" mount="{$mountpoint}"/>), 
           $svnauth,
           $fire
         )
};

declare function cascade:merge-svn-externals (
  (: when the same @mount occurs repeatedly, the last one will prevail :)
    $dir as xs:string,
    $externals as element(external)+,
    $svnauth as map(xs:string, xs:string)?,
    $fire as xs:boolean
  ) as item()* {
  let $ordered := document {$externals},
      $prop := string-join(
                 $ordered/external[not(@mount = following-sibling::external/@mount)] 
                   ! (string-join((@url, @rev), '@') || ' ' || @mount),
                 '&#xa;'
               )
  return (prof:dump('Setting externals to ' || $prop || ' on ' || $dir),
  cascade:svn-propset('svn:externals', $prop, $dir, $svnauth, $fire))
};


declare function cascade:get-svn-externals (
  $dir as xs:string, 
  $svnauth as map(xs:string, xs:string)?
) as element(external)* {
  try {
    (:svn:propget($ms-parent-dir, $svnauth, 'svn:externals', 'HEAD') doesn’t work on local paths :)
    cascade:svn-propget('svn:externals', 
                         $dir, 
                         ('--username', $svnauth?username, '--password', $svnauth?password)[exists($svnauth)]
                        ) => cascade:parse-svn-externals-prop()
  } catch cascade:ERR-svn-propget-01 {
    ()
  }
};

declare function cascade:s9y-lookup (
    $paths as element(c:param-set), 
    $role as xs:string,
    $target-suffix as xs:string
  ) as xs:string {
  let $s9y-role as xs:string := $paths/c:param[matches(@name, '^s9y\d-role$')][@value = $role]/@name ! string(.)
  return $paths/c:param[@name = replace($s9y-role, '-role$', $target-suffix)]/@value ! string(.)
};

declare function cascade:update-svn-wc (
    $dir as xs:string, 
    $svnauth as map(xs:string, xs:string),
    $svn-mkdirs-todo as xs:string*,
    $fire as xs:boolean
  ) as xs:string* {
  (: returns the missing intermediate dirs in the order that they need to be created :)
  prof:dump('cascade:update-svn-wc(): Trying ' || $dir),
  if (not(file:exists($dir)))
  then let $parent as xs:string? := file:parent($dir)
       return if ($parent)
              then cascade:update-svn-wc($parent, $svnauth, ($dir, $svn-mkdirs-todo), $fire)
              else error(xs:QName('cascade:ERR-svn-01'), 'Cannot find svn working copy at ' || $dir)
  else 
    try {
      let $svn-info as element(c:param-set) := cascade:svn-info($dir, $svnauth)
      return (
        prof:dump('  got it: ' || serialize($svn-info)),
        for $u in svn:update($svnauth, $dir, 'HEAD') return prof:dump('  updated: ' || serialize($u)),
        $svn-mkdirs-todo
      )
    }
    catch cascade:ERR-EV-02 {
      (: it has been added, but not committed yet. We can add externals before we commit if $fire = false().
         If §fire = true(), newly created directories need to be committed because we don’t know later which was
         the top directory that needs to be committed :)
      if (not($fire))
      then (
             prof:dump('Ignored since $fire is false: ' || $err:description),
             $svn-mkdirs-todo
           )
      else error($err:code, $err:description, $err:value)
    }
};

declare function cascade:svn-mkdir-if-inexistent(
  $dir as xs:string, 
  $svnauth as map(xs:string, xs:string),
  $is-wc as xs:boolean,
  $fire as xs:boolean
) as element(*)+ {
  if (not(file:exists($dir)))
  then prof:dump('cascade:svn-mkdir-if-inexistent: ' || $dir || ' inexistent'),
       try { cascade:svn-info($dir, $svnauth) }
       catch cascade:ERR-EV-01 { (prof:dump('  need to create it'),
                                  cascade:svn-mkdir($dir, $svnauth, 'created by svn-mkdir-if-inexistent in cascade.xqm'[not($is-wc)]),
                                  if ($fire and $is-wc) 
                                  then (prof:dump('  and commit it.'),
                                        svn:commit($svnauth, $dir, 'svn-mkdir-if-inexistent autocommit')) ) }
  
};

declare function cascade:svn-info($repo-url as xs:string, $svnauth as map(xs:string, xs:string)) as element(c:param-set) {
  (: $repo-url may also be local directory :)
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
    then (
          prof:dump($repo-info),
          if (starts-with($repo-info/c:error, 'svn: E195002:'))
          then error(xs:QName('cascade:ERR-EV-02'), 
                     'The working copy at ' || $repo-url 
                     || ' seems to contain uncommited changes. Please commit them first'
                     || ' or delete the topmost directory added and apply an svn revert --depth infinity to its path.', $repo-info)
          else
          error(xs:QName('cascade:ERR-EV-01'), 
               'Error accessing a repo at ' || $repo-url 
               || '. Maybe it needs to be created first.', $repo-info)
         )
    else $repo-info 
};

declare function cascade:svn-mkdir($dir as xs:string, $svnauth as map(xs:string, xs:string), $message as xs:string?) {
  proc:execute('svn', ('mkdir', $dir, '--username', $svnauth?username, '--password', $svnauth?password,
                        ('-m', $message)[$message]))
};

declare function cascade:svn-update($path as xs:string, $svnauth as map(xs:string, xs:string)) {
  proc:execute('svn', ('update', $path, '--username', $svnauth?username, '--password', $svnauth?password))
};

declare function cascade:svn-propget($propname as xs:string, $path as xs:string, $svnauth as map(xs:string, xs:string)?) 
  as element(property)* {
  let $result := proc:execute('svn', ('propget', '--xml', $propname, $path, 
                               ('--username', $svnauth?username, '--password', $svnauth?password)[exists($svnauth)]))
  return if ($result/code = '0')
         then parse-xml($result/output/text())/properties/target/property
         else error(xs:QName('cascade:ERR-svn-propget-01'), string($result/error))
};

declare function cascade:svn-propset(
  $propname as xs:string, 
  $propval as xs:string, 
  $path as xs:string, 
  $svnauth as map(xs:string, xs:string)?,
  $fire as xs:boolean
) 
  as element(*)* (: element(property) from cascade:svn-propget, element(c:param-set) from svn:commit() :) {
    (: probably need to supply a commit message when $path points to a repo :)
  let $result := proc:execute('svn', ('propset', $propname, $propval, $path, 
                                         ('--username', $svnauth?username, '--password', $svnauth?password)[exists($svnauth)]))
  return if ($result/code = '0')
         then (
                if ($fire)
                then (prof:dump('committing the properties of ' || $path),
                      svn:commit($svnauth, $path, 'add/merge external autocommit')
                     ),
                cascade:svn-propget($propname, $path, $svnauth)
            )
         else error(xs:QName('cascade:ERR-svn-propset-01'), string($result/error))
};


declare function cascade:parse-svn-externals-prop($prop as xs:string) as element(external)* {
  for $line in ($prop => tokenize('[&#xa;&#xd;]+'))[normalize-space()]
  return <external> {
    let $tokens as xs:string+ := $line => tokenize('\s+'),
        $url-plus-rev := $tokens[matches(., '^https?:')],
        $mount as xs:string* := $tokens[not(matches(., '^https?:'))],
        $rev as xs:string* := ($url-plus-rev[contains(., '@')] => tokenize('@'))[last()],
        $url := replace($url-plus-rev, '^(.+?)(@\d+)$', '$1')
    return (attribute url { $url },
            if(exists($rev)) then attribute rev { $rev } else (),
            attribute mount { $mount })
  }</external>
};
