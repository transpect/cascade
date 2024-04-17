import module namespace cascade = "http://transpect.io/cascade" at "cascade.xqm";

declare namespace c = "http://www.w3.org/ns/xproc-step";

declare variable $filename as xs:string external;

cascade:params-for-filename($filename)