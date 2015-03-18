(*  Title:       Deriving class instances for datatypes
    Author:      Christian Sternagel and René Thiemann  <christian.sternagel|rene.thiemann@uibk.ac.at>
    Maintainer:  Christian Sternagel and René Thiemann 
    License:     LGPL
*)
section \<open>Generating Comparators\<close>

theory Comparator_Generator
imports
  "../Generator_Aux"
  "../Derive_Manager"
  Comparator
begin

typedecl ('a,'b,'c,'z)type

text \<open>In the following, we define a generator which for a given datatype @{typ "('a,'b,'c,'z)type"}
  constructs a comparator of type 
  @{typ "'a comparator \<Rightarrow> 'b comparator \<Rightarrow> 'c comparator \<Rightarrow> 'z comparator \<Rightarrow> ('a,'b,'c,'z)type"}.
  To this end, we first compare the index of the constructors, then for equal constructors, we
  compare the arguments recursively and combine the results lexicographically.\<close>

hide_type "type"

subsection \<open>Lexicographic combination of @{typ order}\<close>

fun comp_lex :: "order list \<Rightarrow> order"
where
  "comp_lex (c # cs) = (case c of Eq \<Rightarrow> comp_lex cs | _ \<Rightarrow> c)" |
  "comp_lex [] = Eq"

subsection \<open>Improved code for non-lazy languages\<close>

text \<open>The following equations will eliminate all occurrences of @{term comp_lex}
  in the generated code of the comparators.\<close>

lemma comp_lex_unfolds: 
  "comp_lex [] = Eq"
  "comp_lex [c] = c"
  "comp_lex (c # d # cs) = (case c of Eq \<Rightarrow> comp_lex (d # cs) | Lt \<Rightarrow> Lt | Gt \<Rightarrow> Gt)"
  by (cases c, auto)+

subsection \<open>Pointwise properties for equality, symmetry, and transitivity\<close> 


text \<open>The pointwise properties are important during inductive proofs of soundness of comparators.
  They are defined in a way that are combinable with @{const comp_lex}.\<close>

lemma comp_lex_eq: "comp_lex os = Eq \<longleftrightarrow> (\<forall> ord \<in> set os. ord = Eq)" 
  by (induct os) (auto split: order.splits)
  
definition trans_order :: "order \<Rightarrow> order \<Rightarrow> order \<Rightarrow> bool" where
  "trans_order x y z \<longleftrightarrow> x \<noteq> Gt \<longrightarrow> y \<noteq> Gt \<longrightarrow> z \<noteq> Gt \<and> ((x = Lt \<or> y = Lt) \<longrightarrow> z = Lt)"

lemma trans_orderI:
  "(x \<noteq> Gt \<Longrightarrow> y \<noteq> Gt \<Longrightarrow> z \<noteq> Gt \<and> ((x = Lt \<or> y = Lt) \<longrightarrow> z = Lt)) \<Longrightarrow> trans_order x y z"
  by (simp add: trans_order_def)

lemma trans_orderD:
  assumes "trans_order x y z" and "x \<noteq> Gt" and "y \<noteq> Gt"
  shows "z \<noteq> Gt" and "x = Lt \<or> y = Lt \<Longrightarrow> z = Lt"
  using assms by (auto simp: trans_order_def)

lemma All_less_Suc:
  "(\<forall>i < Suc x. P i) \<longleftrightarrow> P 0 \<and> (\<forall>i < x. P (Suc i))"
  using less_Suc_eq_0_disj by force

lemma comp_lex_trans:
  assumes "length xs = length ys"
    and "length ys = length zs"
    and "\<forall> i < length zs. trans_order (xs ! i) (ys ! i) (zs ! i)"
  shows "trans_order (comp_lex xs) (comp_lex ys) (comp_lex zs)"
using assms
proof (induct xs ys zs rule: list_induct3)
  case (Cons x xs y ys z zs)
  then show ?case
    by (intro trans_orderI)
       (cases x y z rule: order.exhaust [case_product order.exhaust order.exhaust],
        auto simp: All_less_Suc dest: trans_orderD)
qed (simp add: trans_order_def)

lemma comp_lex_sym:
  assumes "length xs = length ys"
    and "\<forall> i < length ys. sym_order (xs ! i) = ys ! i"
  shows "sym_order (comp_lex xs) = comp_lex ys"
  using assms by (induct xs ys rule: list_induct2, simp, case_tac x) fastforce+

declare comp_lex.simps [simp del]

definition eq_pcomp :: "'a comparator \<Rightarrow> 'a \<Rightarrow> bool"
where
  "eq_pcomp acomp x \<longleftrightarrow> (\<forall> y. acomp x y = Eq \<longleftrightarrow> x = y)"

lemma eq_pcompD: "eq_pcomp acomp x \<Longrightarrow> acomp x y = Eq \<longleftrightarrow> x = y"
  unfolding eq_pcomp_def by auto

lemma eq_pcompI: "(\<And> y. acomp x y = Eq \<longleftrightarrow> x = y) \<Longrightarrow> eq_pcomp acomp x"
  unfolding eq_pcomp_def by auto

definition sym_pcomp :: "'a comparator \<Rightarrow> 'a \<Rightarrow> bool" where
  "sym_pcomp acomp x \<longleftrightarrow> (\<forall> y. sym_order (acomp x y) = (acomp y x))"

lemma sym_pcompD:
  assumes "sym_pcomp acomp x"
  shows "sym_order (acomp x y) = (acomp y x)"
  using assms unfolding sym_pcomp_def by blast+

lemma sym_pcompI:
  assumes "\<And> y. sym_order (acomp x y) = (acomp y x)"
  shows "sym_pcomp acomp x"
  using assms unfolding sym_pcomp_def by blast


definition trans_pcomp :: "'a comparator \<Rightarrow> 'a \<Rightarrow> bool" where
  "trans_pcomp acomp x \<longleftrightarrow> (\<forall> y z. trans_order (acomp x y) (acomp y z) (acomp x z))"

lemma trans_pcompD:
  assumes "trans_pcomp acomp x"
  shows "trans_order (acomp x y) (acomp y z) (acomp x z)"
  using assms unfolding trans_pcomp_def by blast+

lemma trans_pcompI:
  assumes "\<And> y z. trans_order (acomp x y) (acomp y z) (acomp x z)"
  shows "trans_pcomp acomp x"
  using assms unfolding trans_pcomp_def by blast

subsection \<open>Separate properties of comparators\<close>

definition eq_comp :: "'a comparator \<Rightarrow> bool" where
  "eq_comp acomp \<longleftrightarrow> (\<forall> x. eq_pcomp acomp x)"

lemma eq_compD2: "eq_comp acomp \<Longrightarrow> eq_pcomp acomp x"
  unfolding eq_comp_def by blast

lemma eq_compI2: "(\<And> x. eq_pcomp acomp x) \<Longrightarrow> eq_comp acomp" 
  unfolding eq_comp_def by blast
    
definition trans_comp :: "'a comparator \<Rightarrow> bool" where
  "trans_comp acomp \<longleftrightarrow> (\<forall> x. trans_pcomp acomp x)"
  
lemma trans_compD2: "trans_comp acomp \<Longrightarrow> trans_pcomp acomp x"
  unfolding trans_comp_def by blast

lemma trans_compI2: "(\<And> x. trans_pcomp acomp x) \<Longrightarrow> trans_comp acomp" 
  unfolding trans_comp_def by blast

  
definition sym_comp :: "'a comparator \<Rightarrow> bool" where
  "sym_comp acomp \<longleftrightarrow> (\<forall> x. sym_pcomp acomp x)"

lemma sym_compD2:
  "sym_comp acomp \<Longrightarrow> sym_pcomp acomp x"
  unfolding sym_comp_def by blast

lemma sym_compI2: "(\<And> x. sym_pcomp acomp x) \<Longrightarrow> sym_comp acomp" 
  unfolding sym_comp_def by blast

lemma eq_compD: "eq_comp acomp \<Longrightarrow> acomp x y = Eq \<longleftrightarrow> x = y"
  by (rule eq_pcompD[OF eq_compD2])

lemma eq_compI: "(\<And> x y. acomp x y = Eq \<longleftrightarrow> x = y) \<Longrightarrow> eq_comp acomp"
  by (intro eq_compI2 eq_pcompI)

lemma trans_compD: "trans_comp acomp \<Longrightarrow> trans_order (acomp x y) (acomp y z) (acomp x z)"
  by (rule trans_pcompD[OF trans_compD2])

lemma trans_compI: "(\<And> x y z. trans_order (acomp x y) (acomp y z) (acomp x z)) \<Longrightarrow> trans_comp acomp"
  by (intro trans_compI2 trans_pcompI)

lemma sym_compD:
  "sym_comp acomp \<Longrightarrow> sym_order (acomp x y) = (acomp y x)" 
  by (rule sym_pcompD[OF sym_compD2])
  
lemma sym_compI: "(\<And> x y. sym_order (acomp x y) = (acomp y x)) \<Longrightarrow> sym_comp acomp"
  by (intro sym_compI2 sym_pcompI)

lemma eq_sym_trans_imp_comparator:
  assumes "eq_comp acomp" and "sym_comp acomp" and "trans_comp acomp"
  shows "comparator acomp"
proof
  fix x y z
  show "sym_order (acomp x y) = acomp y x"
    using sym_compD [OF `sym_comp acomp`] .
  {
    assume "acomp x y = Eq"
    with eq_compD [OF `eq_comp acomp`]
    show "x = y" by blast
  }
  {
    assume "acomp x y = Lt" and "acomp y z = Lt"
    with trans_orderD [OF trans_compD [OF `trans_comp acomp`], of x y z]
    show "acomp x z = Lt" by auto
  }
qed

lemma comparator_imp_eq_sym_trans:
  assumes "comparator acomp"
  shows "eq_comp acomp" "sym_comp acomp" "trans_comp acomp" 
proof -
  interpret comparator acomp by fact
  show "eq_comp acomp" using eq by (intro eq_compI, auto)
  show "sym_comp acomp" using sym by (intro sym_compI, auto)
  show "trans_comp acomp"
  proof (intro trans_compI trans_orderI)
    fix x y z
    assume "acomp x y \<noteq> Gt" "acomp y z \<noteq> Gt"
    thus "acomp x z \<noteq> Gt \<and> (acomp x y = Lt \<or> acomp y z = Lt \<longrightarrow> acomp x z = Lt)"
      using trans [of x y z] and eq [of x y] and eq [of y z]
      by (cases "acomp x y" "acomp y z" rule: order.exhaust [case_product order.exhaust]) auto
  qed
qed

context
  fixes acomp :: "'a comparator"
  assumes c: "comparator acomp"
begin
lemma comp_to_sym_pcomp: "sym_pcomp acomp x"
  using comparator_imp_eq_sym_trans[OF c]
  by (intro sym_compD2)

lemma comp_to_eq_pcomp: "eq_pcomp acomp x" 
  using comparator_imp_eq_sym_trans [OF c] 
  by (intro eq_compD2)
  
lemma comp_to_trans_pcomp: "trans_pcomp acomp x" 
  using comparator_imp_eq_sym_trans [OF c] 
  by (intro trans_compD2)
end

subsection \<open>Auxiliary Lemmas for Comparator Generator\<close>

lemma forall_finite: "(\<forall> i < (0 :: nat). P i) = True"
   "(\<forall> i < Suc 0. P i) = P 0"
   "(\<forall> i < Suc (Suc x). P i) = (P 0 \<and> (\<forall> i < Suc x. P (Suc i)))"
  by (auto, case_tac i, auto)
  
lemma trans_order_different:
  "trans_order a b Lt"
  "trans_order Gt b c"
  "trans_order a Gt c"
  by (intro trans_orderI, auto)+

lemma length_nth_simps: 
  "length [] = 0" "length (x # xs) = Suc (length xs)" 
  "(x # xs) ! 0 = x" "(x # xs) ! (Suc n) = xs ! n" by auto

subsection \<open>The Comparator Generator\<close>

ML_file "comparator_generator.ML"
                 
end