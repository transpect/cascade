<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tr="http://transpect.io"
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  exclude-result-prefixes="xs tr"
  version="3.0">
  
  <!-- Invocation either by submitting a c:filenames document (see below) as input and processing it in default mode
       (this kind of invocation is necessitated by the JAXP interface that BaseX still uses)
       or by supplying the filename parameter and calling the initial template 'params-for-filename'. -->
  
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
    <xsl:variable name="_filename" as="xs:string" select="if ($filename) then $filename else string(.)" />
    <xsl:sequence select="transform(map{
                                        'source-node': $transpect-conf,
                                        'stylesheet-location': $transpect-conf/tr:conf/@paths-xsl-uri,
                                        'stylesheet-params': map{
                                                                  xs:QName('collection-uri'): $collection-uri,
                                                                  xs:QName('file'): $_filename
                                                                }
                                        })?output"/>
  </xsl:template>
  
</xsl:stylesheet>