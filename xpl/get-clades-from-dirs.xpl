<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:tr="http://transpect.io"
  version="1.0" 
  name="get-clades-from-dirs" 
  type="tr:get-clades-from-dirs">

  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    This step converts a transpect clades document from the output
    of <code>tr:directory-loop</code>. The clades document can be used
    as input for the <code>tr:paths</code> step. 
  </p:documentation>
  
  
  <p:input port="params">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>The initial params document. It's base URI is taken to iterate over 
        the subdirectories and construct the clade document.</p>
    </p:documentation>
  </p:input>
  
  <p:output port="result" primary="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>The clades document</p>
    </p:documentation>
  </p:output>
  
  <p:output port="directory-param-sets" primary="false">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>Listing of directories including expanded parameter-sets.</p>
    </p:documentation>
  </p:output>
  
  <p:option name="debug" select="'yes'"/>
  <p:option name="debug-dir-uri" select="'debug'"/>  
  <p:option name="status-dir-uri" select="concat($debug-dir-uri, '/status')"/>
  
  <p:import href="directory-loop.xpl"/>
  <p:import href="http://transpect.io/xproc-util/simple-progress-msg/xpl/simple-progress-msg.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
    
  <tr:simple-progress-msg file="trdemo-paths.txt">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Read configuration from file system</c:message>
          <c:message xml:lang="de">Lese Konfiguration vom Dateisystem</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>
  
  <!--  *
        * the locaction of the parameter document is the initial point of the cascade.
        * -->
  
  <tr:directory-loop>
    <p:with-option name="path" select="replace(base-uri(/c:param-set), '^(.+)/.+$', '$1')"/>
    <p:with-option name="exclude-filter" select="/c:param-set/c:param[@name eq 'exclude-filter']/@value"/>
  </tr:directory-loop>
  
  <tr:store-debug pipeline-step="cascade/dirs-and-params">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <p:xslt>
    <p:input port="stylesheet">
      <p:document href="../xsl/dirs-to-clades.xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:pipe port="params" step="get-clades-from-dirs"/>
    </p:input>
  </p:xslt>
  
  <tr:store-debug pipeline-step="cascade/clades-from-dirs">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
</p:declare-step>
