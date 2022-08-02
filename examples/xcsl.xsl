<!-- 

MIT License

Copyright (c) 2021,2022 David Maus <dmaus@dmaus.name>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
-->
<!--

This transformation takes an XCSL schema as input and returns a
validating XSLT stylesheet. It uses the parameter 'validation-style'
to define to desired validation style used by the XSLT Schematron
Framework transpiler.

The transformation consists of three steps:

First, the XCSL schema is transformed in an XSLT stylesheet with XSLT
Schematron Framework elements expressing the rules and a template rule
matching the root node that starts the validation.

This stylesheet is fed to the XSLT Schematon Framework transpiler. The
transpiler returns an XSLT stylesheet with the XSLT Schematron
Framework elements replaced by XSLT instructions depending on the
selected validation style.

-->

<xsl:transform version="3.0" exclude-result-prefixes="#all"
               xmlns:alias="http://www.w3.org/1999/XSL/TransformAlias"
               xmlns:fn="urn:uuid:4fcdfee3-0111-494b-92b3-c2243b0aeb03"
               xmlns:sf="https://doi.org/10.5281/zenodo.4834190#"
               xmlns:xs="http://www.w3.org/2001/XMLSchema"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:include href="../src/main/resources/transpile.xsl"/>

  <xsl:output indent="yes"/>
  <xsl:param name="validation-style" as="xs:string" select="'template-modes'"/>

  <xsl:namespace-alias stylesheet-prefix="alias" result-prefix="xsl"/>

  <xsl:mode on-no-match="shallow-skip"/>
  <xsl:mode name="postprocess" on-no-match="shallow-copy"/>

  <xsl:template match="cs">
    <xsl:variable name="schema-pass-0" as="element(xsl:stylesheet)">
      <alias:stylesheet version="3.0">
        <xsl:apply-templates/>
        <alias:template match="/">
          <doc-status>
            <alias:apply-templates mode="Q{{https://doi.org/10.5281/zenodo.4834190#}}validate"/>
          </doc-status>
        </alias:template>
      </alias:stylesheet>
    </xsl:variable>
    <xsl:variable name="schema-pass-1" as="element(xsl:stylesheet)">
      <xsl:apply-templates select="$schema-pass-0" mode="sf:transpile">
        <xsl:with-param name="sf:validation-style" as="xs:string" select="$validation-style"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:apply-templates select="$schema-pass-1" mode="postprocess"/>
  </xsl:template>

  <xsl:template match="xsl:stylesheet" mode="postprocess">
    <xsl:choose>
      <xsl:when test="$validation-style eq 'accumulator'">
        <xsl:variable name="accumulators" as="xs:string*" select="tokenize(xsl:mode[@name = 'sf:validate']/@use-accumulators, '\s+')"/>
        <xsl:copy>
          <xsl:sequence select="@*"/>
          <xsl:sequence select="node()"/>
          <alias:mode use-accumulators="#all"/>
          <alias:template match="*" mode="Q{{https://doi.org/10.5281/zenodo.4834190#}}validate">
            <xsl:namespace name="sf">https://doi.org/10.5281/zenodo.4834190#</xsl:namespace>
            <xsl:for-each select="$accumulators">
              <alias:sequence select="accumulator-after('{.}')"/>
            </xsl:for-each>
          </alias:template>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="constraint">
    <sf:constraint>
      <sf:context match="{selector/@selexp}{cc/variable/@selexp ! fn:expr-to-predicate(.)}">
        <xsl:apply-templates select="let"/>
        <sf:assert test="{cc}">
          <xsl:apply-templates select="action"/>
        </sf:assert>
      </sf:context>
    </sf:constraint>
  </xsl:template>

  <xsl:template match="let">
    <alias:variable name="{@name}" select="{@value}"/>
  </xsl:template>

  <xsl:template match="message">
    <err-message>
      <xsl:sequence select="@xml:lang"/>
      <xsl:apply-templates/>
    </err-message>
  </xsl:template>

  <xsl:template match="message/text()">
    <xsl:sequence select="."/>
  </xsl:template>

  <xsl:template match="value">
    <alias:value-of select="{@selexp}"/>
  </xsl:template>

  <xsl:function name="fn:expr-to-predicate" as="xs:string">
    <xsl:param name="expr" as="xs:string"/>
    <xsl:value-of select="concat('[', $expr, ']')"/>
  </xsl:function>

</xsl:transform>
