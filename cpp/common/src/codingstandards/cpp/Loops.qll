/**
 * Provides a library for working with for loops.
 */

import cpp
import Operator

/**
 * Gets an iteration variable as identified by the initialization statement for the loop.
 */
Variable getAnIterationVariable(ForStmt forLoop) {
  // This differs from the `ForStmt.getAnIterationVariable` definition because MISRA has a looser
  // definition of iteration variables.
  result = forLoop.getInitialization().(DeclStmt).getADeclaration()
  or
  result.getAnAssignment() = forLoop.getInitialization().(ExprStmt).getExpr()
}

/**
 * Holds if for loop `forLoop` contains more than one loop counter.
 * M6-5-1 and A6-5-2
 */
predicate isForLoopWithMulipleCounters(ForStmt forLoop) {
  count(LoopCounter c | c.getALoop() = forLoop) > 1
}

/**
 * Holds if for loop `forLoop` contains floating-point type counters.
 * M6-5-1 and A6-5-2
 */
predicate isForLoopWithFloatingPointCounters(ForStmt forLoop, Variable v) {
  v = getAnIterationVariable(forLoop) and
  v.getType() instanceof FloatingPointType
}

class NCrementOperation extends Expr {
  VariableAccess operand;

  NCrementOperation() {
    this.(CrementOperation).getOperand() = operand
    or
    this.(Call).getTarget() instanceof UserCrementOperator and
    this.(Call).getQualifier() = operand
    or
    this.(AssignArithmeticOperation).getLValue() = operand
    or
    this.(Call).getTarget() instanceof UserAssignArithmeticOperator and
    this.(Call).getQualifier() = operand
  }

  VariableAccess getOperand() { result = operand }
}

/**
 * Holds if for loop `forLoop` contains an invalid for loop incrementation.
 * M6-5-2
 */
predicate isInvalidForLoopIncrementation(ForStmt forLoop, Variable v, VariableAccess modification) {
  v = getAnIterationVariable(forLoop) and
  modification = v.getAnAccess() and
  modification = forLoop.getUpdate().getAChild*() and
  any(NCrementOperation cop).getOperand() = modification and
  not exists(CrementOperation cop | cop.getOperand() = modification) and
  not exists(Call c |
    c.getQualifier() = modification and c.getTarget() instanceof UserCrementOperator
  ) and
  exists(VariableAccess va | va = forLoop.getCondition().getAChild*() and va = v.getAnAccess() |
    exists(EqualityOperation eop | eop.getAnOperand() = va)
    or
    exists(Call call |
      call.getTarget() instanceof UserEqualityOperator and call.getQualifier() = va
    )
  )
}

/**
 * Holds if for loop `forLoop` modifies loop counters inside the condition.
 * M6-5-3
 */
predicate isLoopCounterModifiedInCondition(ForStmt forLoop, VariableAccess loopCounterAccess) {
  loopCounterAccess = forLoop.getCondition().getAChild+() and
  loopCounterAccess = getAnIterationVariable(forLoop).getAnAccess() and
  (
    loopCounterAccess.isModified() or
    loopCounterAccess.isAddressOfAccess()
  )
}

/**
 * Holds if for loop `forLoop` that have had loop counters modified inside the statement.
 * M6-5-3
 */
predicate isLoopCounterModifiedInStatement(
  ForStmt forLoop, Variable loopCounter, VariableAccess loopCounterAccess
) {
  loopCounter = getAnIterationVariable(forLoop) and
  loopCounterAccess = loopCounter.getAnAccess() and
  (
    loopCounterAccess.isModified() or
    loopCounterAccess.isAddressOfAccess()
  ) and
  forLoop.getStmt().getChildStmt*() = loopCounterAccess.getEnclosingStmt()
}

/**
 * Holds if for loop `forLoop` terminates nondeterministically.
 * M6-5-4
 */
predicate isIrregularLoopCounterModification(
  ForStmt forLoop, Variable loopCounter, VariableAccess loopCounterAccess
) {
  // get a loop counter of Integer type
  loopCounter = getAnIterationVariable(forLoop) and
  loopCounter.getType() instanceof IntegralType and
  loopCounter.getAnAccess() = loopCounterAccess and
  // match any modified loop counter access in the update of a for loop
  loopCounterAccess = forLoop.getUpdate().getAChild*() and
  loopCounterAccess.isModified() and
  // exclude crement operations
  not loopCounterAccess = any(CrementOperation co).getOperand() and
  // exclude += n and -= n, provided n is constant
  not exists(AssignArithmeticOperation aop |
    (aop instanceof AssignSubExpr or aop instanceof AssignAddExpr) and
    aop.getLValue() = loopCounterAccess
  |
    aop.getRValue().isConstant()
    or
    exists(Variable n |
      aop.getRValue() = n.getAnAccess() and
      not exists(VariableAccess na |
        na = n.getAnAccess() and
        na.isModified()
      |
        // n is not constant if n is updated in the body, condition or update of the for loop
        forLoop.getStmt().getAChild*() = na.getEnclosingStmt()
        or
        forLoop.getCondition().getAChild*() = na
        or
        forLoop.getUpdate().getAChild*() = na
      )
    )
  )
}

/**
 * Holds if for loop `forLoop`'s loop-control-variables `loopControlVariable` is modified in the loop condition through access `loopControlVariableAccess`.
 * M6-5-5
 */
predicate isLoopControlVarModifiedInLoopCondition(
  ForStmt forLoop, LoopControlVariable loopControlVariable, VariableAccess loopControlVariableAccess
) {
  loopControlVariableAccess = loopControlVariable.getVariableAccessInLoop(forLoop) and
  not loopControlVariable = getAnIterationVariable(forLoop) and
  loopControlVariableAccess = forLoop.getCondition().getAChild+() and
  (
    loopControlVariableAccess.isModified() or
    loopControlVariableAccess.isAddressOfAccess()
  )
}

/**
 * Holds if for loop `forLoop`'s loop-control-variables `loopControlVariable` is modified in the loop expression through access `loopControlVariableAccess`
 * M6-5-5
 */
predicate isLoopControlVarModifiedInLoopExpr(
  ForStmt forLoop, LoopControlVariable loopControlVariable, VariableAccess loopControlVariableAccess
) {
  loopControlVariableAccess = loopControlVariable.getVariableAccessInLoop(forLoop) and
  not loopControlVariable = getAnIterationVariable(forLoop) and
  loopControlVariableAccess = forLoop.getUpdate().getAChild() and
  (
    loopControlVariableAccess.isModified() or
    loopControlVariableAccess.isAddressOfAccess()
  )
}

/**
 * Holds if for loop `forLoops`'s loop control variable `loopControlVariable` modified in a statement through access `loopControlVariableAccess` and
 * the type of the control variable is not a boolean.
 * M6-5-6
 */
predicate isNonBoolLoopControlVar(
  ForStmt forLoop, LoopControlVariable loopControlVariable, VariableAccess loopControlVariableAccess
) {
  exists(Variable loopCounter, ComparisonOperation terminationCheck |
    loopCounter = getAnIterationVariable(forLoop) and
    forLoop.getCondition() = terminationCheck.getParent*()
  |
    // get a loop control variable that is not a loop counter
    loopControlVariableAccess = loopControlVariable.getVariableAccessInLoop(forLoop) and
    not loopControlVariable = getAnIterationVariable(forLoop) and
    // filter only loop control variables that are modified
    (
      loopControlVariableAccess.isModified() or
      loopControlVariableAccess.isAddressOfAccess()
    ) and
    // check if the variable type is anything but bool
    not loopControlVariable.getType() instanceof BoolType and
    // check if the control variable is part of the termination check, but is not compared to the loop counter
    terminationCheck.getAnOperand() = loopControlVariable.getAnAccess().getParent*() and
    not terminationCheck.getAnOperand() = loopCounter.getAnAccess().getParent*()
  )
}

predicate isInvalidLoop(ForStmt forLoop) { isInvalidLoop(forLoop, _, _, _) }

predicate isInvalidLoop(ForStmt forLoop, string reason, Locatable reasonLocation, string reasonLabel) {
  exists(Variable loopCounter |
    isInvalidForLoopIncrementation(forLoop, loopCounter, reasonLocation) and
    reason =
      "it $@ its loop counter '" + loopCounter.getName() +
        "' with an operation that is not an increment or decrement" and
    reasonLabel = "updates"
  )
  or
  isForLoopWithMulipleCounters(forLoop) and
  reason = "it uses multiple loop counters$@" and
  reasonLabel = "" and
  reasonLocation.getLocation() instanceof UnknownExprLocation
  or
  isForLoopWithFloatingPointCounters(forLoop, reasonLocation) and
  reason = "it uses a loop counter '$@' of type floating-point" and
  reasonLabel = reasonLocation.(Variable).getName()
  or
  isLoopCounterModifiedInCondition(forLoop, reasonLocation) and
  reason =
    "it $@ the loop counter '" + reasonLocation.(VariableAccess).getTarget().getName() +
      "' in the condition" and
  reasonLabel = "updates"
  or
  exists(Variable loopCounter |
    isLoopCounterModifiedInStatement(forLoop, loopCounter, reasonLocation) and
    reason = "it $@ the loop counter '" + loopCounter.getName() + "' in the body of the loop" and
    reasonLabel = "updates"
  )
  or
  exists(Variable loopCounter |
    isIrregularLoopCounterModification(forLoop, loopCounter, reasonLocation) and
    reason = "it $@ the loop counter '" + loopCounter.getName() + "' irregularly" and
    reasonLabel = "updates"
  )
  or
  exists(Variable loopControlVariable |
    isLoopControlVarModifiedInLoopExpr(forLoop, loopControlVariable, reasonLocation) and
    reason =
      "it updates $@, a loop control variable other than the loop counter, in the update expression of the loop" and
    reasonLabel = loopControlVariable.getName()
  )
  or
  isNonBoolLoopControlVar(forLoop, reasonLocation, _) and
  reason = "its $@ is not a boolean" and
  reasonLabel = "loop control variable"
}
