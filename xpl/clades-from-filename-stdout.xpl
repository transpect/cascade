<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:tr="http://transpect.io"
  version="1.0"
  name="clades-from-filename-stdout"
  type="tr:clades-from-filename-stdout">
  
  <p:documentation>
    This step provides the clades of one filename 
    as whitespace separated list.
  </p:documentation>
  
  <p:input port="conf">
    <p:document href="http://this.transpect.io/conf/transpect-conf.xml"/>
  </p:input>
  
  <p:output port="result" sequence="true"/>
  
  <p:serialization port="result" method="text" indent="false"/>
  
  <p:option name="filename"/>
  <p:option name="separator" select="'&#x20;'"/>
  
  <p:option name="debug" select="'yes'"/>
  <p:option name="debug-dir-uri" select="'debug'"/>
  <p:option name="status-dir-uri" select="'status'"/>
  
  <p:import href="http://transpect.io/cascade/xpl/paths.xpl"/>
  
  <p:load name="import-paths-xsl">
    <p:with-option name="href" select="(/*/@paths-xsl-uri, 'http://transpect.io/cascade/xsl/paths.xsl')[1]">
      <p:pipe port="conf" step="clades-from-filename-stdout"/>
    </p:with-option>
  </p:load>
  
  <p:sink/>
  
  <tr:paths name="paths">
    <p:with-option name="pipeline" select="'paths-for-files.xpl'"/>
    <p:with-option name="file" select="$filename">
      <p:pipe port="result" step="import-paths-xsl"/>
    </p:with-option>
    <p:with-option name="debug" select="$debug"/>  
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
    <p:input port="conf">
        <p:pipe port="conf" step="clades-from-filename-stdout"/>
    </p:input>
    <p:input port="stylesheet">
      <p:pipe port="result" step="import-paths-xsl"/>
    </p:input>
    <p:input port="params">
      <p:empty/>
    </p:input>
  </tr:paths>
  
  <p:xslt name="generate-output">
    <p:input port="stylesheet">
      <p:inline>
        <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                        xmlns:xs="http://www.w3.org/2001/XMLSchema"
          version="2.0">
          
          <xsl:param name="separator" as="xs:string"/>
          
          <xsl:template match="c:param-set">
            <c:data>
              <xsl:apply-templates select="c:param[matches(@name, '^s9y\d$')]">
                <xsl:sort order="descending" select="replace(@name, '^s9y(\d)$', '$1')"/>
              </xsl:apply-templates>
            </c:data>
          </xsl:template>
          
          <xsl:template match="c:param[matches(@name, '^s9y\d$')]">
            <xsl:value-of select="concat(@value, '&#xa;')"/>
          </xsl:template>
          
        </xsl:stylesheet>
      </p:inline>
    </p:input>
    <p:with-param name="separator" select="$separator"/>
  </p:xslt>
  
</p:declare-step>