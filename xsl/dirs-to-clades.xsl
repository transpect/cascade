<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns="http://transpect.io"
  exclude-result-prefixes="xs c"
  version="2.0">
  
  <xsl:strip-space elements="*"/>
  
  <xsl:variable name="exclude-filter" select="/c:directory/c:param-set/c:param[@name eq 'exclude-filter']/@value" as="xs:string?"/>
  <xsl:variable name="exclude-filter-names" select="if($exclude-filter) 
    then tokenize(replace($exclude-filter, '[\(\)'']', ''), '\|')
    else ''" as="xs:string*"/>
  
  <xsl:template match="/">
    <xsl:processing-instruction name="xml-model">href="http://transpect.io/cascade/schema/cascade.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
    <xsl:processing-instruction name="xml-model">href="http://transpect.io/cascade/schema/cascade.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction>
    <conf>
      <xsl:variable name="content-base-uri-attribute" select="c:directory/c:param-set/c:param[@name eq 'content-base-uri']" as="element(c:param)?"/>
      <xsl:variable name="paths-xsl-uri-attribute" select="c:directory/c:param-set/c:param[@name eq 'paths-xsl-uri']" as="element(c:param)?"/>
      <xsl:if test="$content-base-uri-attribute">
        <xsl:attribute name="content-base-uri" select="$content-base-uri-attribute/@value"/>
      </xsl:if>
      <xsl:if test="$paths-xsl-uri-attribute">
        <xsl:attribute name="paths-xsl-uri" select="$paths-xsl-uri-attribute/@value"/>
      </xsl:if>
      <cascade>
        <!-- the following directory names are excluded from the cascade iteration -->
        <xsl:for-each select="$exclude-filter-names">
          <reserved name="{.}"/>
        </xsl:for-each>
        <xsl:apply-templates/>
      </cascade>
    </conf>
  </xsl:template>
  
  <xsl:template match="c:directory[not(@name = $exclude-filter-names)]">
    <clade name="{@name}">
      <xsl:variable name="inherited-clade-role-attribute" select="(c:param-set/c:param[@name eq 'clade-role'], 
        ancestor::c:directory[c:param-set/c:param[@name eq 'role']]/c:param-set/c:param[@name eq 'clade-role'][1])[1]" as="element(c:param)?"/>
      <xsl:attribute name="role" select="if($inherited-clade-role-attribute) then $inherited-clade-role-attribute/@value else 'default'"/>
      <!-- unfortunately, content element is necessary for paths.xsl -->
      <content role="work"/>
      <xsl:apply-templates/>
    </clade>
  </xsl:template>
  
  <xsl:template match="c:param">
    <param name="{@name}" value="{@value}"/>
  </xsl:template>
  
</xsl:stylesheet>