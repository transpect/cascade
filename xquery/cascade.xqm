module namespace cascade = "http://transpect.io/cascade";

declare namespace c = "http://www.w3.org/ns/xproc-step";

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
    then error('TRCSC01', 'No matching clade found for ' || $filename, $param-set)
    else error('TRCSC02', 'Multiple matching clades found for ' || $filename, $param-set)
};