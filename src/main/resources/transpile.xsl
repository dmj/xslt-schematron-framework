<?xml version="1.0" encoding="utf-8"?>
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

Bibliography

[JELLIFFE 1999] Jelliffe, Rick. 1999. Schematron-Basic: A Mimimal Concept Demonstration Generating Simple Text. XSLT
1.0. [online](https://web.archive.org/web/20000127022540/http://www.ascc.net/xml/resource/schematron/schematron-basic.html).

[MAUS 2019] Maus, David. 2019. “Ex-Post Rule Match Selection: A Novel Approach to XSLT-Based Schematron Validation.” In
XML Prague 2019 Conference Proceedings, 57–65. Prague, Czech Republic.

-->
<xsl:transform version="3.0" expand-text="yes"
               default-mode="sf:transpile"
               xmlns:alias="http://www.w3.org/1999/XSL/TransformAlias"
               xmlns:sf="https://doi.org/10.5281/zenodo.4834190#"
               xmlns:xs="http://www.w3.org/2001/XMLSchema"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output indent="yes"/>

  <xsl:namespace-alias result-prefix="xsl" stylesheet-prefix="alias"/>

  <xsl:mode name="sf:transpile" on-no-match="shallow-copy"/>

  <!-- Remove, maybe? -->
  <xsl:template match="*[sf:constraint]" as="element()*" mode="sf:transpile">
    <xsl:param name="sf:validation-style" as="xs:string" required="yes"/>
    <xsl:param name="sf:streamable" as="xs:boolean" select="false()"/>
    <xsl:param name="sf:burst" as="xs:string?" select="()"/>
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:apply-templates select="node() except sf:constraint" mode="sf:transpile"/>
      <xsl:choose>
        <xsl:when test="$sf:validation-style = 'template-modes'">
          <xsl:call-template name="sf:transpile.template-modes">
            <xsl:with-param name="constraint" as="element(sf:constraint)*" select="sf:constraint"/>
            <xsl:with-param name="streamable" as="xs:boolean" select="$sf:streamable"/>
            <xsl:with-param name="burst" as="xs:string?" select="$sf:burst"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="$sf:validation-style = 'next-match'">
          <xsl:call-template name="sf:transpile.next-match">
            <xsl:with-param name="constraint" as="element(sf:constraint)*" select="sf:constraint"/>
            <xsl:with-param name="streamable" as="xs:boolean" select="$sf:streamable"/>
            <xsl:with-param name="burst" as="xs:string?" select="$sf:burst"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="$sf:validation-style = 'accumulator'">
          <xsl:call-template name="sf:transpile.accumulator">
            <xsl:with-param name="constraint" as="element(sf:constraint)*" select="sf:constraint"/>
            <xsl:with-param name="streamable" as="xs:boolean" select="$sf:streamable"/>
            <xsl:with-param name="burst" as="xs:string?" select="$sf:burst"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message terminate="yes">Unknown or unsupported validation style: '{$sf:validation-style}'</xsl:message>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <!-- Transpile to template rules, constraints implemented as modes ([JELLIFFE 1999]) -->
  <xsl:template name="sf:transpile.template-modes" as="element()*">
    <xsl:param name="constraint" as="element(sf:constraint)*" required="yes"/>
    <xsl:param name="streamable" as="xs:boolean" select="false()"/>
    <xsl:param name="burst" as="xs:string?" select="()"/>

    <alias:mode name="sf:validate" on-no-match="shallow-skip" streamable="{$streamable}"/>

    <alias:template match="/ | node()" mode="sf:validate">
      <xsl:choose>
        <xsl:when test="$streamable">
          <alias:fork>
            <xsl:for-each select="$constraint">
              <alias:sequence>
                <alias:apply-templates mode="sf:validate.{generate-id(.)}" select="."/>
              </alias:sequence>
            </xsl:for-each>
          </alias:fork>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="$constraint">
            <alias:apply-templates mode="sf:validate.{generate-id(.)}" select="."/>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </alias:template>

    <xsl:for-each select="$constraint">

      <!-- Declare one mode per constraint. -->
      <alias:mode name="sf:validate.{generate-id(.)}" streamable="{$streamable}" on-no-match="shallow-skip"/>
      <xsl:if test="$burst">
        <alias:mode name="sf:burst.{generate-id(.)}" on-no-match="shallow-skip"/>
      </xsl:if>

      <xsl:for-each select="sf:context">

        <xsl:if test="$burst">
          <alias:template match="{@match}" priority="{last() - position()}" mode="sf:validate.{generate-id(..)}">
            <alias:apply-templates select="{$burst}(.)" mode="sf:burst.{generate-id(..)}"/>
          </alias:template>
        </xsl:if>

        <alias:template match="{@match}" priority="{last() - position()}" mode="sf:{if ($burst) then 'burst' else 'validate'}.{generate-id(..)}">
          <xsl:apply-templates mode="sf:transpile"/>
        </alias:template>

      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <!-- Transpile to template rules chained by calls to next-match ([Maus 2019]) -->
  <xsl:template name="sf:transpile.next-match" as="element()*">
    <xsl:param name="constraint" as="element(sf:constraint)*" required="yes"/>
    <xsl:param name="streamable" as="xs:boolean" select="false()"/>
    <xsl:param name="burst" as="xs:string?" select="()"/>

    <alias:mode name="sf:validate" on-no-match="shallow-skip" streamable="{$streamable and not($burst)}"/>
    <xsl:if test="$burst">
      <alias:mode name="sf:burst" on-no-match="shallow-skip" streamable="{$streamable}"/>
    </xsl:if>

    <!-- When using burst mode validation we have two templates:
         The validation template mode=sf:validate that kicks of
         the burst-validation mode=sf:burst). -->
    <xsl:if test="$burst">
      <alias:template match="{@match}" mode="sf:validate">
        <alias:apply-templates select="{$burst}(.)" mode="sf:burst"/>
      </alias:template>
    </xsl:if>

    <!-- Chained templater rules (see: [MAUS 2019]) use a sequence
         of pattern identifiers to check if a node was already
         matched in the same pattern. We need default template
         rules to reset the sequence for new nodes. -->
    <alias:template match="* | /" mode="sf:validate" priority="-10">
      <alias:apply-templates select="@*" mode="#current"/>
      <alias:apply-templates select="node()" mode="#current"/>
    </alias:template>

    <xsl:for-each select="$constraint/sf:context">
      <alias:template match="{@match}" priority="{last() - position()}" mode="sf:{if ($burst) then 'burst' else 'validate'}">
        <alias:param name="sf:constraints" as="xs:string*"/>

        <xsl:apply-templates select="node() except sf:assert" mode="sf:transpile"/>

        <alias:choose>
          <alias:when test="$sf:constraints[. = '{generate-id(..)}']">
            <alias:next-match>
              <alias:with-param name="sf:constraints" as="xs:string*" select="$sf:constraints"/>
            </alias:next-match>
          </alias:when>
          <alias:otherwise>
            <xsl:apply-templates select="sf:assert" mode="sf:transpile"/>
            <alias:next-match>
              <alias:with-param name="sf:constraints" as="xs:string*" select="($sf:constraints, '{generate-id(..)}')"/>
            </alias:next-match>
          </alias:otherwise>
        </alias:choose>
      </alias:template>
    </xsl:for-each>

  </xsl:template>

  <!-- Transpile to accumulators -->
  <xsl:template name="sf:transpile.accumulator" as="element()*">
    <xsl:param name="constraint" as="element(sf:constraint)*" required="yes"/>
    <xsl:param name="streamable" as="xs:boolean" select="false()"/>
    <xsl:param name="burst" as="xs:string?" select="()"/>

    <!-- No support for burst mode validation. -->
    <xsl:if test="$burst">
      <xsl:message terminate="yes">This validation style does not support burst mode validation</xsl:message>
    </xsl:if>

    <alias:mode on-no-match="shallow-skip" name="sf:validate" streamable="{$streamable}" use-accumulators="{for $c in $constraint return concat('sf:validate.', generate-id($c)) => string-join(' ')}"/>

    <xsl:for-each select="$constraint">

      <!-- One accumulator per constraint -->
      <alias:accumulator name="sf:validate.{generate-id()}" initial-value="()" streamable="{$streamable}">
        <xsl:for-each select="reverse(sf:context)">
          <alias:accumulator-rule match="{@match}">
            <xsl:apply-templates mode="sf:transpile"/>
          </alias:accumulator-rule>
        </xsl:for-each>
      </alias:accumulator>

    </xsl:for-each>

  </xsl:template>

  <!-- This is always the right thing: An sf:assert is a xsl:if with negated test expression. -->
  <xsl:template match="sf:assert" as="element(xsl:if)" mode="sf:transpile">
    <alias:if test="not({@test})">
      <xsl:sequence select="node()"/>
    </alias:if>
  </xsl:template>

</xsl:transform>
