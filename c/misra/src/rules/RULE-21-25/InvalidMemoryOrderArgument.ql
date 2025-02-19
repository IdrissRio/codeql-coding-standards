/**
 * @id c/misra/invalid-memory-order-argument
 * @name RULE-21-25: All memory synchronization operations shall be executed in sequentially consistent order
 * @description Only the memory ordering of 'memory_order_seq_cst' is fully portable and consistent.
 * @kind path-problem
 * @precision very-high
 * @problem.severity error
 * @tags external/misra/id/rule-21-25
 *       external/misra/c/2012/amendment4
 *       correctness
 *       concurrency
 *       external/misra/obligation/required
 */

import cpp
import codingstandards.c.misra
import semmle.code.cpp.dataflow.new.DataFlow

/* A member of the set of memory orders defined in the `memory_order` enum */
class MemoryOrder extends EnumConstant {
  MemoryOrder() { getDeclaringEnum().getName() = "memory_order" }

  int getIntValue() { result = getValue().toInt() }
}

/* This is the only standardized memory order, allowed by RULE-21-25. */
class AllowedMemoryOrder extends MemoryOrder {
  AllowedMemoryOrder() { getName() = "memory_order_seq_cst" }
}

/* An expression referring to a memory order */
class MemoryOrderConstantAccess extends EnumConstantAccess {
  MemoryOrderConstantAccess() { getTarget() instanceof MemoryOrder }

  predicate isAllowedOrder() { getTarget() instanceof AllowedMemoryOrder }
}

/* An expression with a constant value that equals a `MemoryOrder` constant */
class MemoryOrderConstantExpr extends Expr {
  MemoryOrder ord;

  MemoryOrderConstantExpr() {
    if this instanceof MemoryOrderConstantAccess
    then ord = this.(MemoryOrderConstantAccess).getTarget()
    else ord.getIntValue() = getValue().toInt()
  }

  /* Get the name of the `MemoryOrder` this expression is valued as. */
  string getMemoryOrderString() { result = ord.getName() }
}

/**
 * A `stdatomic.h` function which accepts a `memory_order` value as a parameter.
 */
class MemoryOrderedStdAtomicFunction extends Function {
  int orderParamIdx;

  MemoryOrderedStdAtomicFunction() {
    exists(int baseParamIdx, int baseParams, string prefix, string regex, string basename |
      regex = "__(c11_)?atomic_([a-z_]+)" and
      prefix = getName().regexpCapture(regex, 1) and
      basename = "atomic_" + getName().regexpCapture(regex, 2) + ["", "_explicit"] and
      (
        basename in ["atomic_thread_fence", "atomic_signal_fence"] and
        baseParamIdx = 0 and
        baseParams = 1
        or
        basename in ["atomic_load", "atomic_flag_clear", "atomic_flag_test_and_set"] and
        baseParamIdx = 1 and
        baseParams = 2
        or
        basename in [
            "atomic_store", "atomic_fetch_" + ["add", "sub", "or", "xor", "and"], "atomic_exchange"
          ] and
        baseParamIdx = 2 and
        baseParams = 3
        or
        basename in ["atomic_compare_exchange_" + ["strong", "weak"]] and
        baseParamIdx = [3, 4] and
        baseParams = 5
      ) and
      (
        // GCC case, may have one or two inserted parameters, e.g.:
        // __atomic_load(8, &repr->a, &desired, order)
        // or
        // __atomic_load_8(&repr->a, &desired, order)
        prefix = "" and
        exists(int extraParams |
          extraParams = getNumberOfParameters() - baseParams and
          extraParams >= 0 and
          orderParamIdx = baseParamIdx + extraParams
        )
        or
        // Clang case, no inserted parameters:
        // __c11_atomic_load(object, order)
        prefix = "c11_" and
        orderParamIdx = baseParamIdx
      )
    )
  }

  int getOrderParameterIdx() { result = orderParamIdx }
}

module MemoryOrderFlowConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node node) {
    // Direct usage of memory order constant
    exists(MemoryOrderConstantAccess constant |
      node.asExpr() = constant and
      not constant.isAllowedOrder()
    )
    or
    // A literal with a disallowed constant integer value
    exists(Literal literal |
      node.asExpr() = literal and
      not literal.getValue().toInt() = any(AllowedMemoryOrder a).getValue().toInt()
    )
  }

  predicate isSink(DataFlow::Node node) {
    exists(FunctionCall fc |
      node.asExpr() =
        fc.getArgument(fc.getTarget().(MemoryOrderedStdAtomicFunction).getOrderParameterIdx())
    )
  }
}

module MemoryOrderFlow = DataFlow::Global<MemoryOrderFlowConfig>;

import MemoryOrderFlow::PathGraph

/**
 * If the node is a memory order constant, or shares a value with a memory order constant, then
 * return the name of that constant. Otherwise, simply print the node.
 */
string describeMemoryOrderNode(DataFlow::Node node) {
  if node.asExpr() instanceof MemoryOrderConstantExpr
  then result = node.asExpr().(MemoryOrderConstantExpr).getMemoryOrderString()
  else result = node.toString()
}

from
  Expr argument, Function function, string value, MemoryOrderFlow::PathNode source,
  MemoryOrderFlow::PathNode sink
where
  not isExcluded(argument, Concurrency6Package::invalidMemoryOrderArgumentQuery()) and
  MemoryOrderFlow::flowPath(source, sink) and
  argument = sink.getNode().asExpr() and
  value = describeMemoryOrderNode(source.getNode()) and
  // Double check that we didn't find flow from something equivalent to the allowed value.
  not value = any(AllowedMemoryOrder e).getName() and
  function.getACallToThisFunction().getAnArgument() = argument
select argument, source, sink, "Invalid memory order '$@' in call to function '$@'.", value, value,
  function, function.getName()
