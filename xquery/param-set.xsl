<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tr="http://transpect.io"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:cascade="http://transpect.io/cascade"  
  exclude-result-prefixes="xs tr map cascade"
  version="3.0">
  
  <!-- Invocation either by submitting a c:filenames document (see below) as input and processing it in default mode
       (this kind of invocation is necessitated by the JAXP interface that BaseX still uses)
       or by supplying the filename parameter and calling the initial template 'params-for-filename'. 
       A third way is to call the result-caching function cascade:params-for-filename($fn). Calling it
       instead of the named template will probably speed things up when multiple invocations for the
       same filename occure. We particularly hope that filename parsing will only be performed once
       in the XSLT that is invoked from Oxygen’s cc_config.xml.
  -->
  
  <xsl:param name="collection-uri" as="xs:string" select="'http://transpect.io/cascade/xquery/collection.catalog.xml'">
    <!-- Historically, paths.xsl refers to the default collection in order to find an optional collection()/c:param-set 
         with command line parameters, a collection()/tr:conf with the transpect configuration, and an optional
         collection()/info with svn info of the current project.
         http://transpect.io/cascade/xquery/collection.catalog.xml contains a Saxon collection catalog that contains
         the relative location of the transpect configuration. If it resides somewhere else, don’t change the Saxon
         collection catalog in this repo. Instead, supply your own using a different $collection-uri.
    -->
  </xsl:param>

  <xsl:param name="filename" as="xs:string?">
    <!-- Only needed for invocation by named template -->
  </xsl:param>
  
  <xsl:param name="debug-bool" as="xs:boolean?"/>
  
  <xsl:variable name="transpect-conf" as="document-node(element(tr:conf))" 
    select="doc('http://this.transpect.io/conf/transpect-conf.xml')"/>
  
  <xsl:template match="/c:filenames">
    <!-- The input document is like 
         <c:filenames>
           <c:file name="my_parsable_filename.xml"/>
         </c:filenames>
         with a single c:file entry. -->
    <c:results>
      <xsl:apply-templates select="c:file/@name"/>
    </c:results>
  </xsl:template>
  
  <xsl:template match="c:file/@name" name="params-for-filename">
    <xsl:param name="include-parsed-tokens-in-param-set" as="xs:boolean" select="true()"/>
    <xsl:param name="filename" as="xs:string?" select="$filename"/>
    <xsl:param name="content-base-uri" as="xs:string?"/>
    <xsl:param name="debug" as="xs:boolean?" select="$debug-bool"/>

    <xsl:variable name="_filename" as="xs:string" select="if ($filename) then $filename else string(.)" />
    <xsl:variable name="result" as="map(*)"
      select="transform(map{
                          'source-node': $transpect-conf,
                          'stylesheet-location': $transpect-conf/tr:conf/@paths-xsl-uri,
                          'stylesheet-params': map{
                                                    xs:QName('collection-uri'): $collection-uri,
                                                    xs:QName('file'): $_filename,
                                                    xs:QName('all-atts-as-params'): $include-parsed-tokens-in-param-set,
                                                    xs:QName('content-base-uri'): $content-base-uri
                                                  }
                          })"/>
    <xsl:if test="$debug">
      <xsl:message select="'cascade/1_prequalify-matching-clades.xml', 
                           map:keys($result)[ends-with(., 'cascade/1_prequalify-matching-clades.xml')] ! map:get($result, .)"/>
    </xsl:if>
    <xsl:sequence select="$result?output"/>
  </xsl:template>
  
  <xsl:function name="cascade:params-for-filename" as="document-node(element(c:param-set))?" cache="yes">
    <xsl:param name="fn-or-uri" as="xs:string">
      <!-- hierarchical URIs or Unix paths that end in a filename are permitted -->
    </xsl:param>
    <xsl:call-template name="params-for-filename">
      <xsl:with-param name="filename" select="$fn-or-uri"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:call-template>
  </xsl:function>
  
</xsl:stylesheet>
