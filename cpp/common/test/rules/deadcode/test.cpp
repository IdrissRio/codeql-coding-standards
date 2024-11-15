// NOTICE: THE TEST CASES BELOW ARE ALSO INCLUDED IN THE C TEST CASE AND CHANGES
//         SHOULD BE REFLECTED THERE AS WELL.

int may_have_side_effects();
int no_side_effects(int x) { return 1 + 2; }
int no_side_effects_nondeterministic();

int test_dead_code(int x) {
  int live1 = may_have_side_effects(),
      live2 = may_have_side_effects(); // COMPLIANT
  int live3 = 0,
      live4 = may_have_side_effects(); // COMPLIANT
  int live5 = 0, live6 = 0;            // COMPLIANT
  live5 = 1;                           // COMPLIANT
  live6 = 2;                           // COMPLIANT

  int dead1 = 0, dead2 = 0; // NON_COMPLIANT
  dead1 = 1;                // NON_COMPLIANT - useless assignment
  dead2 = 1;                // NON_COMPLIANT - useless assignment

  if (false) {  // NON_COMPLIANT
    dead2 = 10; // Only used in dead or unreachable code
  }

  if (true) { // COMPLIANT
    may_have_side_effects();
  }

  if (may_have_side_effects()) { // COMPLIANT
    may_have_side_effects();
  }

  if (true) { // NON_COMPLIANT
  }

  {} // NON_COMPLIANT
  {  // NON_COMPLIANT
    1 + 2;
  }

  { // COMPLIANT
    may_have_side_effects();
  }

  do { // COMPLIANT
    may_have_side_effects();
  } while (may_have_side_effects());

  do { // COMPLIANT
    may_have_side_effects();
  } while (may_have_side_effects());

  do { // NON_COMPLIANT
  } while (no_side_effects_nondeterministic());

  while (may_have_side_effects()) { // COMPLIANT
    may_have_side_effects();
  }

  while (may_have_side_effects()) { // COMPLIANT
    may_have_side_effects();
  }

  while (no_side_effects_nondeterministic()) { // NON_COMPLIANT
  }

  may_have_side_effects(); // COMPLIANT
  1 + 2;                   // NON_COMPLIANT

  no_side_effects(x); // NON_COMPLIANT

  try {           // NON_COMPLIANT
  } catch (...) { // NON_COMPLIANT
  }

  try {
    may_have_side_effects();
  } catch (int i) { // COMPLIANT
  } catch (...) {   // NON_COMPLIANT
  }

  static_assert(1); // COMPLIANT

  constexpr int constexpr_array_size{6};    // COMPLIANT
  int unused_array[constexpr_array_size]{}; // NON_COMPLIANT

  constexpr int unused_int{2}; // NON_COMPLIANT

  constexpr int constexpr_used_array[]{3, 4, 5};   // COMPLIANT
  constexpr int constexpr_unused_array[]{0, 1, 2}; // NON_COMPLIANT

  return live5 + live6 + constexpr_used_array[1]; // COMPLIANT
}

class Foo {
public:
  void bar() { may_have_side_effects(); }
};

class Baz {
public:
  void bar() {} // No side effects
};

#define FULL_STMT_NO_SIDE_EFFECTS no_side_effects(1);
#define PART_STMT_NO_SIDE_EFFECTS no_side_effects(1)
#define BLOCK_SOME_SIDE_EFFECTS                                                \
  {                                                                            \
    may_have_side_effects();                                                   \
    no_side_effects(1);                                                        \
  }

template <typename T> void test_template() {
  T t;
  t.bar();                       // COMPLIANT
  no_side_effects(1);            // NON_COMPLIANT
  FULL_STMT_NO_SIDE_EFFECTS      // NON_COMPLIANT
      PART_STMT_NO_SIDE_EFFECTS; // NON_COMPLIANT
  BLOCK_SOME_SIDE_EFFECTS;       // COMPLIANT - cannot determine loc for
                                 // no_side_effects(1)
}

template <typename T> void test_variant_side_effects() {
  T t;
  t.bar(); // COMPLIANT - not dead in at least one instance
}

template <typename T> void test_unused_template() {
  T t;
  t.bar(); // COMPLIANT
  no_side_effects(
      1); // NON_COMPLIANT[FALSE_NEGATIVE] - unused templates are not extracted
}

void test() {
  test_template<Foo>();
  test_template<Baz>();
  test_variant_side_effects<Foo>(); // COMPLIANT
  test_variant_side_effects<Baz>(); // NON_COMPLIANT - no effect in this
                                    // instantiation
}