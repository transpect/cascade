<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tr="http://transpect.io"
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  exclude-result-prefixes="xs tr"
  version="3.0">
  
  <xsl:variable name="transpect-conf" as="document-node(element(tr:conf))" 
    select="doc('http://this.transpect.io/conf/transpect-conf.xml')"/>
  
  <!--<xsl:template match="/c:filenames">
    <xsl:sequence select="."/>
  </xsl:template>-->
  
  <xsl:template match="/c:filenames">
    <c:results>
      <xsl:apply-templates select="c:file/@name"/>
    </c:results>
  </xsl:template>
  
  <xsl:template match="c:file/@name">
    <xsl:sequence select="transform(map{
                                        'source-node': $transpect-conf,
                                        'stylesheet-location': $transpect-conf/tr:conf/@paths-xsl-uri,
                                        'stylesheet-params': map{
                                                                  xs:QName('collection-uri'): 'http://transpect.io/cascade/xquery/collection.catalog.xml',
                                                                  xs:QName('file'): .
                                                                }
                                        })?output"/>
  </xsl:template>
  
</xsl:stylesheet>