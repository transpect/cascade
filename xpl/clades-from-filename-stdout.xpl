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
    as separated tokens.
  </p:documentation>
  
  <p:input port="conf">
    <p:document href="http://this.transpect.io/conf/transpect-conf.xml"/>
    <p:documentation>
      Expects a transpect configuration file
    </p:documentation>
  </p:input>
  
  <p:output port="result" sequence="true"/>
  
  <p:serialization port="result" method="text" indent="false"/>
  
  <p:option name="filename">
    <p:documentation>
      Expects a path or a filename which matches the clades configuration.
    </p:documentation>
  </p:option>
  
  <p:option name="separator" select="'&#xa;'">
    <p:documentation>
      A character used to separate the clades in stdout. For example set
      to '&#xa;' if you want to get the 2nd output line with "$ sed -n 2p"
    </p:documentation>
  </p:option>
  
  <p:option name="get-full-path" select="'no'">
    <p:documentation>
      Option to get the full path of the clade. Permitted values: yes|no
    </p:documentation>
  </p:option>
  
  <p:option name="order" select="'ascending'">
    <p:documentation>
      Option to order the clades. Permitted values are 'ascending' and 'descending'.
    </p:documentation>
  </p:option>
  
  <p:option name="exclude-filter" select="''">
    <p:documentation>
      Expects a whitespace-separated list of clade names to be excluded from 
      the output. This can be necessary if you want to skip a specific clade.
    </p:documentation>
  </p:option>
  
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
          
          <xsl:param name="separator"      as="xs:string"/>
          <xsl:param name="get-full-path"  as="xs:string"/>
          <xsl:param name="order"          as="xs:string"/>
          <xsl:param name="exclude-filter" as="xs:string"/>
          
          <xsl:variable name="param-regex" 
                        select="if($get-full-path eq 'yes')
                                then '^s9y(\d)-path$'
                                else '^s9y(\d)$'"/>
          
          <xsl:template match="c:param-set">
            <c:data>
              <xsl:apply-templates select="c:param[matches(@name, $param-regex)]">
                <xsl:sort order="{$order}" select="replace(@name, $param-regex, '$1')"/>
              </xsl:apply-templates>
            </c:data>
          </xsl:template>
          
          <xsl:template match="c:param[matches(@name, $param-regex)]">
            <xsl:variable name="clade-name" as="xs:string" 
                          select="tokenize(@value, '/')[. ne ''][last()]"/>
            <xsl:if test="not($clade-name = tokenize($exclude-filter, '\s'))">
              <xsl:value-of select="concat(replace(@value, '^file://', ''),
  				                                 $separator)"/>
            </xsl:if>
          </xsl:template>
          
        </xsl:stylesheet>
      </p:inline>
    </p:input>
    <p:with-param name="separator" select="$separator"/>
    <p:with-param name="get-full-path" select="$get-full-path"/>
    <p:with-param name="order" select="$order"/>
    <p:with-param name="exclude-filter" select="$exclude-filter"/>
  </p:xslt>
  
</p:declare-step>
