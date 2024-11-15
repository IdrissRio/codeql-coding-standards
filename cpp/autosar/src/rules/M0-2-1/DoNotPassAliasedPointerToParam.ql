/**
 * @id cpp/autosar/do-not-pass-aliased-pointer-to-param
 * @name M0-2-1: Do not pass aliased pointers as parameters of functions where it is undefined behaviour for those pointers to overlap
 * @description Passing a aliased pointers as parameters of certain functions is undefined behavior.
 * @kind problem
 * @precision medium
 * @problem.severity error
 * @tags external/autosar/id/m0-2-1
 *       correctness
 *       external/autosar/allocated-target/implementation
 *       external/autosar/enforcement/automated
 *       external/autosar/obligation/required
 */

import cpp
import codingstandards.cpp.autosar
import codingstandards.cpp.rules.donotpassaliasedpointertorestrictqualifiedparamshared.DoNotPassAliasedPointerToRestrictQualifiedParamShared

class DoNotPassAliasedPointerToRestrictQualifiedParamQuery extends DoNotPassAliasedPointerToRestrictQualifiedParamSharedSharedQuery
{
  DoNotPassAliasedPointerToRestrictQualifiedParamQuery() {
    this = RepresentationPackage::doNotPassAliasedPointerToParamQuery()
  }
}
