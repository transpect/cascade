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
      <xsl:variable name="report-connection" as="element(*)*" 
        select="p:output[@port = 'report']/(p:pipe | p:inline)"/>
      <xsl:variable name="result-connection" as="element(*)*" 
        select="p:output[@port = 'result']/(p:pipe | p:inline)"/>
      <xsl:if test="not($result-connection)"><!-- last step’s output was primary output -->
        <p:identity name="__I_D_E_N_T_I_T_Y__"/>
        <p:sink/>
      </xsl:if>
      <p:identity>
        <p:input port="source">
          <xsl:if test="not($result-connection)">
            <p:pipe port="result" step="__I_D_E_N_T_I_T_Y__"/>
          </xsl:if>
          <xsl:copy-of select="$result-connection"/>
          <xsl:copy-of select="$report-connection"/>
        </p:input>
      </p:identity>
      <p:wrap-sequence wrapper="c:wrapper"/>
      <p:add-attribute attribute-name="xml:base" match="/*/*[1]">
        <p:with-option name="attribute-value" select="base-uri()">
          <xsl:choose>
            <xsl:when test="$result-connection">
              <xsl:sequence select="$result-connection"/>
            </xsl:when>
            <xsl:otherwise>
              <p:pipe port="result" step="__I_D_E_N_T_I_T_Y__"/>
              <!--
              <xsl:variable name="primary-input" select="(p:input[@primary = 'true'], p:input[1])[1]" as="element(p:input)"/>
              <p:pipe port="{$primary-input/@port}" step="{@name}"/>-->
            </xsl:otherwise>
          </xsl:choose>
        </p:with-option>
      </p:add-attribute>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>