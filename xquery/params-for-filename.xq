import module namespace cascade = "http://transpect.io/cascade" at "cascade.xqm";

declare namespace c = "http://www.w3.org/ns/xproc-step";

declare option output:indent 'yes';

declare variable $filename as xs:string external;

cascade:params-for-filename($filename) (:=> cascade:subdir-for-ext-from-params() :)