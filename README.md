# XSLT Schematron Framework

XSLT Schematron Framework is copyright (c) 2021,2022 by David Maus &lt;dmaus@dmaus.name&gt; and released under the terms
of the MIT license.

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4834190.svg)](https://doi.org/10.5281/zenodo.4834190)

## About

The XSLT Schematron Framework is an XSLT-based Schematron-like system [JELLIFFE 2002]. It implements rule-based
validation as a thin abstraction layer over XSLT. A rule is a set of truth statements about selected nodes of a
document. The document is valid if all statements are true, it is invalid otherwise.

A rule based validation engine requires a mechanism to select nodes and a mechanism to evaluate a truth statement. The
XSLT Schematron Framework uses XPath to both, select nodes and test the truthness of a statement. More specifically it
uses XSLT's matching capabilities to select nodes and the effective boolean value of XPath expressions to test
statements.

The framework defines the following elements:

The assertion element ```assert``` has a ```@test``` attribute with an XPath expression that tests if the assertion is
satisfied. The content of the element is used by the validation stylesheet when the assertion fails. The assertion
element is transpiled to an ```if``` instruction.

The context selector element ```context``` groups assertions and has a ```@match``` attribute with an XPath expression
that defines the nodes to which all contained assertions apply. It is transpiled to a template or accumulator rule,
depending on the selected validation style.

The constraint specification element ```constraint``` defines a sequence of context selector elements that acts as a
if-then-else or switch statement. The transpiler expects a constraint specification to be a top-level XSLT element.

The framework *does not* define elements for declaring variables, functions, indexes and the like. The transpiler only
handles framework elements and copies everything else.

## Validation styles

The XSLT Schematron Framework defines different validation styles.

#### Validation style: template-mode

Transpile to template rules, constraints implemented as modes ([JELLIFFE 1999]).

#### Validation style: next-match

Transpile to template rules chained by calls to next-match ([Maus 2019])

#### Validation style: accumulator

Transpile to accumulators.

## XSLT Schematron Framework and other rule-based validation languages

The framework can be used to implement other rule-based validation languages by pre- and postprocessing the schema
document and the validation stylesheet respectively. This repository provides an example for the XML Constraints
Specification Language (XCSL) [JACINTO 2003].

## Authors

David Maus &lt;dmaus@dmaus.name&gt;

## Bibliography

[ISO 2020] Information technology — Document Schema Definition Languages (DSDL) — Part 3: Rule-based validation,
Schematron, International Standard ISO/IEC 19757-3, Geneva, Switzerland : ISO

[OPOCENSKA 2008] Opočensk, Kateřina, und Michal Kopecký. 2008. „Incox - A Language for XML Integrity Constraints
Description“. In DATESO 2008, 1–12. Desná.

[JACINTO 2003] Jacinto, Marta Henriques, Giovani Rubert Librelotto, José Carlos Ramalho, and Pedro
R. Henriques. 2003. “XCSL: The XML Constraint Language.” CLEI Electronic Journal 6
(1). [online](http://www2.clei.org/cleiej/paper.php?id=76).

[JELLIFFE 1999] Jelliffe, Rick. 1999. Schematron-Basic: A Mimimal Concept Demonstration Generating Simple Text. XSLT
1.0. [online](https://web.archive.org/web/20000127022540/http://www.ascc.net/xml/resource/schematron/schematron-basic.html).

[JELLIFFE 2002] Jelliffe, Rick. 2002. “The Schematron Assertion Language 1.6.”
[online](https://web.archive.org/web/20061230150144/http://xml.ascc.net:80/resource/schematron/Schematron2000.html).

[MARCONI 2004] Marconi, Michael, and Christian Nentwich, eds. 2004. “CLiX Language Specification Version 1.0.”
https://web.archive.org/web/20040323060710/http://www.clixml.org/clix/1.0/.

[MAUS 2019] Maus, David. 2019. “Ex-Post Rule Match Selection: A Novel Approach to XSLT-Based Schematron Validation.” In
XML Prague 2019 Conference Proceedings, 57–65. Prague, Czech Republic.

[XSLT 3.0] Kay, Michael, ed. 2017. “XSL Transformations (XSLT) Version 3.0.” World Wide Web
Consortium. [online](https://www.w3.org/TR/2017/REC-xslt-30-20170608/).
