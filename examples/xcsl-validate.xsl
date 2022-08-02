<xsl:transform version="3.0" exclude-result-prefixes="#all"
               xmlns:xs="http://www.w3.org/2001/XMLSchema"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:param name="schema"   as="xs:string" required="true"/>
  <xsl:param name="document" as="xs:string" required="true"/>

  <xsl:include href="xcsl.xsl"/>

  <xsl:template name="validate">
    <xsl:variable name="compiled-schema" as="element(xsl:stylesheet)">
      <xsl:apply-templates select="doc($schema)"/>
    </xsl:variable>
    <xsl:variable name="result" as="map(*)" select="transform(map{'stylesheet-node': $compiled-schema, 'source-node': doc($document)})"/>
    <xsl:sequence select="$result?output"/>
  </xsl:template>

</xsl:transform>
