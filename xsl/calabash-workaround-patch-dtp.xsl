<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  exclude-result-prefixes="xs"
  version="2.0">
  
  <xsl:template match="@* | *">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="/p:declare-step/p:output[@port = 'result']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:attribute name="sequence" select="'true'"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="/p:declare-step/p:output[@port = 'report']"/>

  <xsl:template match="/p:declare-step[p:output[@port = 'result']]">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
      <xsl:variable name="result-connection" as="element(*)*" 
        select="p:output[@port = ('result', 'report')]/(p:pipe | p:inline)"/>
      <xsl:if test="not(p:output[@port = 'result']/(p:pipe | p:inline))">
        <p:identity name="__I_D_E_N_T_I_T_Y__"/>
      </xsl:if>
      <p:identity>
        <p:input port="source">
          <p:pipe port="result" step="__I_D_E_N_T_I_T_Y__"/>
          <xsl:copy-of select="$result-connection"/>
        </p:input>
      </p:identity>
      <p:wrap-sequence wrapper="c:wrapper"/>
      
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>