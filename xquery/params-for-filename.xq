import module namespace cascade = "http://transpect.io/cascade" at "cascade.xqm";

declare namespace c = "http://www.w3.org/ns/xproc-step";

declare option output:indent 'yes';

declare variable $filename as xs:string external;

(: sample invocation:
basex/bin/basex -b svnuser=gimsieke -b svnpass=******* -b filename="suc_3-24_a000878.pdf" cascade/xquery/params-for-filename.xq
:)

cascade:params-for-filename($filename) (:=> cascade:subdir-for-ext-from-params() :)