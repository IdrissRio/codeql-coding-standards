/**
 * @id cpp/autosar/operands-of-a-logical-and-or-not-parenthesized
 * @name A5-2-6: The operands of a logical && or || shall be parenthesized if the operands contain binary operators
 * @description The operands of a logical && or || shall be parenthesized if the operands contain
 *              binary operators to make the expressions more readable.
 * @kind problem
 * @precision very-high
 * @problem.severity warning
 * @tags external/autosar/id/a5-2-6
 *       correctness
 *       readability
 *       external/autosar/allocated-target/implementation
 *       external/autosar/enforcement/automated
 *       external/autosar/obligation/required
 */

import cpp
import codingstandards.cpp.autosar

from BinaryLogicalOperation op, BinaryOperation binop, string leftOrRight
where
  not isExcluded(op, OrderOfEvaluationPackage::operandsOfALogicalAndOrNotParenthesizedQuery()) and
  (
    op.getLeftOperand() = binop and
    leftOrRight = "Left"
    or
    op.getRightOperand() = binop and
    leftOrRight = "Right"
  ) and
  // Ignore cases with the same operator
  not op.getOperator() = binop.getOperator() and
  not exists(ParenthesisExpr p | p = binop.getFullyConverted()) and
  // Exclude binary operations expanded by a macro.
  not binop.isInMacroExpansion()
select op, "$@ of logical operation " + op.getOperator() + " is not parenthesized.", binop,
  leftOrRight + " operand " + binop.getOperator()
