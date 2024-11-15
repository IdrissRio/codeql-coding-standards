/**
 * @id c/misra/language-extensions-should-not-be-used
 * @name RULE-1-2: Language extensions should not be used
 * @description Language extensions are not portable to other compilers and should not be used.
 * @kind problem
 * @precision high
 * @problem.severity error
 * @tags external/misra/id/rule-1-2
 *       maintainability
 *       readability
 *       external/misra/c/2012/third-edition-first-revision
 *       external/misra/obligation/advisory
 */

import cpp
import codingstandards.c.misra
import codingstandards.cpp.AlertReporting
import codingstandards.c.Extensions

from CCompilerExtension e
where not isExcluded(e, Language3Package::languageExtensionsShouldNotBeUsedQuery())
select MacroUnwrapper<CCompilerExtension>::unwrapElement(e), e.getMessage()
