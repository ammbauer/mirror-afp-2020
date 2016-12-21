(*<*)
theory Basis
imports
  Main
  "~~/src/HOL/Library/While_Combinator"
begin

(*>*)
section\<open> Preliminaries \<close>

(*>*)(*<*)

subsection\<open> HOL Detritus \<close>

(* Much of this is in Isabelle/hg fba08009ff3e (after Isabelle2016). *)

lemma disj_imp: "P \<or> Q \<longleftrightarrow> \<not>P \<longrightarrow> Q" by blast

lemma FieldI1 [intro]:
  assumes "(x, y) \<in> r"
  shows "x \<in> Field r"
unfolding Field_def using assms by blast

lemma Above_union:
  shows "x \<in> Above r (X \<union> Y) \<longleftrightarrow> x \<in> Above r X \<and> x \<in> Above r Y"
unfolding Above_def by blast

lemma Above_Field:
  assumes "x \<in> Above r X"
  shows "x \<in> Field r"
using assms unfolding Above_def by blast

lemma AboveS_Field:
  assumes "x \<in> AboveS r X"
  shows "x \<in> Field r"
using assms unfolding AboveS_def by blast

lemma Above_Linear_singleton:
  assumes "x \<in> Field r"
  assumes "Linear_order r"
  shows "x \<in> Above r {x}"
using assms unfolding Above_def order_on_defs by (force dest: refl_onD)

lemma override_on_insert:
  shows "override_on f g (insert x X) = (override_on f g X)(x:=g x)"
unfolding override_on_def by (simp add: fun_eq_iff)

lemma override_on_insert':
  shows "override_on f g (insert x X) = (override_on (f(x:=g x)) g X)"
unfolding override_on_def by (simp add: fun_eq_iff)

lemma sublists_refl:
  shows "xs \<in> set (sublists xs)"
by (induct xs) (simp_all add: Let_def)

lemma sublists_set:
  assumes "y \<in> set (sublists xs)"
  shows "set y \<subseteq> set xs"
using assms by (metis Pow_iff image_eqI sublists_powset)

lemma subset_sublists:
  shows "X \<subseteq> set xs \<Longrightarrow> X \<in> set ` set (sublists xs)"
unfolding sublists_powset by simp

lemma sublists_Cons_inv:
  assumes "y # ys \<in> set (sublists xs)"
  shows "ys \<in> set (sublists xs)"
using assms by (induct xs) (auto simp: Let_def)

lemma sublists_distinct:
  assumes "ys \<in> set (sublists xs)"
  assumes "distinct xs"
  shows "distinct ys"
using assms
by (induct xs arbitrary: ys) (auto simp: Let_def dest: subsetD[OF sublists_set])

primrec map_of_default :: "'v \<Rightarrow> ('k \<times> 'v) list \<Rightarrow> 'k \<Rightarrow> 'v" where
  "map_of_default v0 [] k = v0"
| "map_of_default v0 (kv # kvs) k = (if k = fst kv then snd kv else map_of_default v0 kvs k)"

lemmas set_elem_equalityI = Set.equalityI[OF Set.subsetI Set.subsetI]

lemma antisym_singleton [iff]:
  "antisym {a}"
by (blast intro: antisymI)

lemma total_on_singleton [iff]:
  "total_on {a} {(a, a)}"
unfolding total_on_def by blast

lemma refl_on_singleton [iff]:
  shows "refl_on {a} {(a, a)}"
by (blast intro: refl_onI)

lemmas total_onI = iffD2[OF total_on_def, rule_format]

lemma squared_Field [iff]:
  shows "Field (x \<times> x) = x"
unfolding Field_def by blast

lemma linear_order_on_singleton [iff]:
  shows "linear_order_on {x} {(x, x)}"
unfolding order_on_defs by simp

lemma linear_order_on_Restr:
  assumes "linear_order_on A r"
  shows "linear_order_on (A \<inter> above r x) (Restr r (above r x))"
using assms unfolding order_on_defs refl_on_def trans_def antisym_def total_on_def
by simp (safe; blast)

lemma partial_order_on_acyclic:
  assumes "partial_order_on A r"
  shows "acyclic (r - Id)"
by (metis acyclic_irrefl assms irrefl_diff_Id partial_order_on_def preorder_on_def trancl_id trans_diff_Id)

lemma linear_order_on_acyclic:
  assumes "linear_order_on A r"
  shows "acyclic (r - Id)"
by (metis acyclic_irrefl assms strict_linear_order_on_def strict_linear_order_on_diff_Id trancl_id)

lemma linear_order_on_well_order_on:
  assumes "finite r"
  shows "linear_order_on A r \<longleftrightarrow> well_order_on A r"
unfolding well_order_on_def
using assms finite_acyclic_wf[OF _ linear_order_on_acyclic, of r] by blast

lemma finite_Linear_order_induct[consumes 3, case_names step]:
  assumes "Linear_order r"
  assumes "x \<in> Field r"
  assumes "finite r"
  assumes step: "\<And>x. \<lbrakk>x \<in> Field r; \<And>y. y \<in> aboveS r x \<Longrightarrow> P y\<rbrakk> \<Longrightarrow> P x"
  shows "P x"
using assms(2)
proof(induct rule: wf_induct[of "r\<inverse> - Id"])
  from assms(1,3) show "wf (r\<inverse> - Id)"
    using linear_order_on_well_order_on linear_order_on_converse
    unfolding well_order_on_def by blast
next
  case (2 x) then show ?case
    by - (rule step; auto simp: aboveS_def intro: FieldI2)
qed

lemma setsum_mono_inv:
  fixes I :: "'z set"
  fixes f :: "'z \<Rightarrow> nat"
  assumes "sum f I = sum g I"
  assumes "\<And>i. i \<in> I \<Longrightarrow> f i \<le> g i"
  assumes "i \<in> I"
  assumes "finite I"
  shows "f i = g i"
using assms by (metis le_neq_trans less_irrefl sum_strict_mono_ex1)

(* From Finite_Set, strengthen: inductive F is a subset of what we started with. *)
lemma finite_subset_induct' [consumes 2, case_names empty insert]:
  assumes "finite F" and "F \<subseteq> A"
    and empty: "P {}"
    and insert: "\<And>a F. \<lbrakk>finite F; a \<in> A; F \<subseteq> A; a \<notin> F; P F \<rbrakk> \<Longrightarrow> P (insert a F)"
  shows "P F"
proof -
  from \<open>finite F\<close>
  have "F \<subseteq> A \<Longrightarrow> ?thesis"
  proof induct
    show "P {}" by fact
  next
    fix x F
    assume "finite F" and "x \<notin> F" and
      P: "F \<subseteq> A \<Longrightarrow> P F" and i: "insert x F \<subseteq> A"
    show "P (insert x F)"
    proof (rule insert)
      from i show "x \<in> A" by blast
      from i have "F \<subseteq> A" by blast
      with P show "P F" .
      show "finite F" by fact
      show "x \<notin> F" by fact
      show "F \<subseteq> A" by fact
    qed
  qed
  with \<open>F \<subseteq> A\<close> show ?thesis by blast
qed

text\<open>

We sometimes want a notion of monotonicity over some set.

\<close>

definition mono_on :: "'a::order set \<Rightarrow> ('a \<Rightarrow> 'b::order) \<Rightarrow> bool" where
  "mono_on A f = (\<forall>x\<in>A. \<forall>y\<in>A. x \<le> y \<longrightarrow> f x \<le> f y)"

lemmas mono_onI = iffD2[OF mono_on_def, rule_format]
lemmas mono_onD = iffD1[OF mono_on_def, rule_format]

lemma mono_onE:
  "\<lbrakk>mono_on A f; x \<in> A; y \<in> A; x \<le> y; f x \<le> f y \<Longrightarrow> thesis\<rbrakk> \<Longrightarrow> thesis"
using mono_onD by blast

lemma mono_on_mono:
  "mono_on UNIV = mono"
by (clarsimp simp: mono_on_def mono_def fun_eq_iff)

lemma funpow_mono_order_aux:
  fixes f :: "'a \<Rightarrow> ('a::order)"
  shows "mono f \<Longrightarrow> A \<le> B \<Longrightarrow> (f ^^ n) A \<le> (f ^^ n) B"
  by (induct n arbitrary: A B)
     (auto simp del: funpow.simps(2) simp add: funpow_Suc_right monoD)

lemma funpow_mono_order:
  assumes "mono f"
  assumes "i \<le> j"
  assumes "x \<le> y"
  assumes "x \<le> f x"
  shows "(f ^^ i) x \<le> (f ^^ j) y"
using assms(2,3)
proof(induct j arbitrary: y)
  case (Suc j) show ?case
  proof(cases "i = Suc j")
    case True with assms(1) Suc show ?thesis
      by (simp del: funpow.simps add: funpow_simps_right monoD funpow_mono_order_aux)
  next
    case False with assms(1,4) Suc show ?thesis
      by (simp del: funpow.simps add: funpow_simps_right le_eq_less_or_eq)
         (simp add: Suc.hyps monoD order_subst1)
  qed
qed simp


subsection\<open> Relate @{const "gfp"} and @{const "while"} \<close>

text\<open>

We adapt and generalise the lemmas relating @{const "lfp"} to @{const
"while"} in \<open>While_Combinator\<close> to an arbitrary finite
complete lattice and play the same game for @{const "gfp"}. This story
could be generalized from finite types to chain-finite lattices.

\<close>

(* Nat, Kleene iteration for gfp. *)
subsection \<open>Kleene iteration\<close>

lemma Kleene_iter_gpfp:
assumes "mono f" and "p \<le> f p" shows "p \<le> (f^^k) (top::'a::order_top)"
proof(induction k)
  case 0 show ?case by simp
next
  case Suc
  from monoD[OF assms(1) Suc] assms(2)
  show ?case by simp
qed

lemma gfp_Kleene_iter: assumes "mono f" and "(f^^Suc k) top = (f^^k) top"
shows "gfp f = (f^^k) top"
proof(rule antisym)
  show "(f^^k) top \<le> gfp f"
  proof(rule gfp_upperbound)
    show "(f^^k) top \<le> f ((f^^k) top)" using assms(2) by simp
  qed
next
  show "gfp f \<le> (f^^k) top"
    using Kleene_iter_gpfp[OF assms(1)] gfp_unfold[OF assms(1)] by simp
qed

(* While_Combinator *)

lemma wf_finite_less:
  assumes "finite (C :: 'a::order set)"
  shows "wf {(x, y). {x, y} \<subseteq> C \<and> x < y}"
by (rule wf_measure[where f="\<lambda>b. card {a. a \<in> C \<and> a < b}", THEN wf_subset])
   (fastforce simp: less_eq assms intro: psubset_card_mono)

lemma wf_finite_greater:
  assumes "finite (C :: 'a::order set)"
  shows "wf {(x, y). {x, y} \<subseteq> C \<and> y < x}"
by (rule wf_measure[where f="\<lambda>b. card {a. a \<in> C \<and> b < a}", THEN wf_subset])
   (fastforce simp: less_eq assms intro: psubset_card_mono)

lemma while_option_finite_increasing_Some:
  fixes f :: "'a::order \<Rightarrow> 'a"
  assumes "mono f" and "finite (UNIV :: 'a set)" and "s \<le> f s"
  shows "\<exists>P. while_option (\<lambda>A. f A \<noteq> A) f s = Some P"
by (rule wf_rel_while_option_Some[where R="{(x, y). y < x}" and P="\<lambda>A. A \<le> f A" and s="s"])
   (auto simp: assms monoD intro: wf_finite_greater[where C="UNIV::'a set", simplified])

lemma lfp_the_while_option:
  fixes f :: "'a::complete_lattice \<Rightarrow> 'a"
  assumes "mono f" and "finite (UNIV :: 'a set)"
  shows "lfp f = the(while_option (\<lambda>A. f A \<noteq> A) f bot)"
proof -
  obtain P where "while_option (\<lambda>A. f A \<noteq> A) f bot = Some P"
    using while_option_finite_increasing_Some[OF assms, where s=bot] by simp blast
  with while_option_stop2[OF this] lfp_Kleene_iter[OF assms(1)]
  show ?thesis by auto
qed

lemma lfp_while:
  fixes f :: "'a::complete_lattice \<Rightarrow> 'a"
  assumes "mono f" and "finite (UNIV :: 'a set)"
  shows "lfp f = while (\<lambda>A. f A \<noteq> A) f bot"
unfolding while_def using assms by (rule lfp_the_while_option)

(* gfp *)

lemma while_option_finite_decreasing_Some:
  fixes f :: "'a::order \<Rightarrow> 'a"
  assumes "mono f" and "finite (UNIV :: 'a set)" and "f s \<le> s"
  shows "\<exists>P. while_option (\<lambda>A. f A \<noteq> A) f s = Some P"
by (rule wf_rel_while_option_Some[where R="{(x, y). x < y}" and P="\<lambda>A. f A \<le> A" and s="s"])
   (auto simp add: assms monoD intro: wf_finite_less[where C="UNIV::'a set", simplified])

lemma gfp_the_while_option:
  fixes f :: "'a::complete_lattice \<Rightarrow> 'a"
  assumes "mono f" and "finite (UNIV :: 'a set)"
  shows "gfp f = the(while_option (\<lambda>A. f A \<noteq> A) f top)"
proof -
  obtain P where "while_option (\<lambda>A. f A \<noteq> A) f top = Some P"
    using while_option_finite_decreasing_Some[OF assms, where s=top] by simp blast
  with while_option_stop2[OF this] gfp_Kleene_iter[OF assms(1)]
  show ?thesis by auto
qed

lemma gfp_while:
  fixes f :: "'a::complete_lattice \<Rightarrow> 'a"
  assumes "mono f" and "finite (UNIV :: 'a set)"
  shows "gfp f = while (\<lambda>A. f A \<noteq> A) f top"
unfolding while_def using assms by (rule gfp_the_while_option)


(*>*)
subsection\<open> MaxR: maximum elements of linear orders \<close>

text\<open>

We generalize the existing @{const "max"} and @{const "Max"} functions
to work on orders defined over sets. See \S\ref{sec:cf-linear} for
choice-function related lemmas.

\<close>

locale MaxR =
  fixes r :: "'a::finite rel"
  assumes r_Linear_order: "Linear_order r"
begin

text\<open>

The basic function chooses the largest of two elements:

\<close>

definition maxR :: "'a \<Rightarrow> 'a \<Rightarrow> 'a" where
  "maxR x y = (if (x, y) \<in> r then y else x)"
(*<*)

lemma maxR_domain:
  shows "{x, y} \<subseteq> A \<Longrightarrow> maxR x y \<in> A"
unfolding maxR_def by simp

lemma maxR_range:
  shows "maxR x y \<in> {x, y}"
unfolding maxR_def by simp

lemma maxR_rangeD:
  "maxR x y \<noteq> x \<Longrightarrow> maxR x y = y"
  "maxR x y \<noteq> y \<Longrightarrow> maxR x y = x"
unfolding maxR_def by auto

lemma maxR_idem:
  shows "maxR x x = x"
unfolding maxR_def by simp

lemma maxR_absorb2:
  shows "(x, y) \<in> r \<Longrightarrow> maxR x y = y"
unfolding maxR_def by simp

lemma maxR_absorb1:
  shows "(y, x) \<in> r \<Longrightarrow> maxR x y = x"
using r_Linear_order unfolding maxR_def by (simp add: order_on_defs antisym_def)

lemma maxR_assoc:
  shows "{x,y,z} \<subseteq> Field r \<Longrightarrow> maxR (maxR x y) z = maxR x (maxR y z)"
using r_Linear_order unfolding maxR_def by simp (metis order_on_defs(1-3) total_on_def trans_def)

lemma maxR_commute:
  shows "{x,y} \<subseteq> Field r \<Longrightarrow> maxR x y = maxR y x"
using r_Linear_order unfolding maxR_def by (fastforce simp: order_on_defs antisym_def total_on_def)

lemmas maxR_simps =
  maxR_idem
  maxR_absorb1
  maxR_absorb2

(*>*)
text\<open>

We hoist this to finite sets using the @{const "Finite_Set.fold"}
combinator. For code generation purposes it seems inevitable that we
need to fuse the fold and filter into a single total recursive
definition.

\<close>

definition MaxR_f :: "'a \<Rightarrow> 'a option \<Rightarrow> 'a option" where
  "MaxR_f x acc = (if x \<in> Field r then Some (case acc of None \<Rightarrow> x | Some y \<Rightarrow> maxR x y) else acc)"

interpretation MaxR_f: comp_fun_idem MaxR_f
using %invisible r_Linear_order
by unfold_locales (fastforce simp: fun_eq_iff maxR_def MaxR_f_def order_on_defs total_on_def antisymD elim: transE split: option.splits)+

definition MaxR_opt :: "'a set \<Rightarrow> 'a option" where
  MaxR_opt_eq_fold': "MaxR_opt A = Finite_Set.fold MaxR_f None A"
(*<*)

lemma empty [simp]:
  shows "MaxR_opt {} = None"
by (simp add: MaxR_opt_eq_fold')

lemma
  shows insert: "MaxR_opt (insert x A) = (if x \<in> Field r then Some (case MaxR_opt A of None \<Rightarrow> x | Some y \<Rightarrow> maxR x y) else MaxR_opt A)"
    and range_Some[rule_format]: "MaxR_opt A = Some a \<longrightarrow> a \<in> A \<inter> Field r"
using finite[of A] by induct (auto simp: MaxR_opt_eq_fold' maxR_def MaxR_f_def split: option.splits)

lemma range_None:
  assumes "MaxR_opt A = None"
  shows "A \<inter> Field r = {}"
using assms by (metis Int_iff insert all_not_in_conv insert_absorb option.simps(3))

lemma domain_empty:
  assumes "A \<inter> Field r = {}"
  shows "MaxR_opt A = None"
using assms by (metis empty_iff option.exhaust range_Some)

lemma domain:
  shows "MaxR_opt (A \<inter> Field r) = MaxR_opt A"
using finite[of A] by induct (simp_all add: insert)

lemmas MaxR_opt_code = MaxR_opt_eq_fold'[where A="set A", unfolded MaxR_f.fold_set_fold] for A

lemma range:
  shows "MaxR_opt A \<in> Some ` (A \<inter> Field r) \<union> {None}"
using range_Some notin_range_Some by fastforce

lemma union:
  shows "MaxR_opt (A \<union> B) = (case MaxR_opt A of None \<Rightarrow> MaxR_opt B | Some mA \<Rightarrow> Some (case MaxR_opt B of None \<Rightarrow> mA | Some mB \<Rightarrow> maxR mA mB))"
using finite[of A] by induct (auto simp: maxR_assoc insert dest!: range_Some split: option.splits)

lemma mono:
  assumes "MaxR_opt A = Some x"
  shows "\<exists>y. MaxR_opt (A \<union> B) = Some y \<and> (x, y) \<in> r"
using finite[of B]
proof induct
  case empty with assms show ?case
    using range_Some underS_incl_iff[OF r_Linear_order] by fastforce
next
  note ins = insert
  case (insert b B) with assms r_Linear_order show ?case
    unfolding order_on_defs total_on_def by (fastforce simp: ins maxR_def elim: transE)
qed

lemma MaxR_opt_is_greatest:
  assumes "MaxR_opt A = Some x"
  assumes "y \<in> A \<inter> Field r"
  shows "(y, x) \<in> r"
using finite[of A] assms
proof(induct arbitrary: x)
  note ins = insert
  case (insert a A) then show ?case
    using r_Linear_order unfolding order_on_defs refl_on_def total_on_def
    by (auto 10 0 simp: maxR_def ins dest!: range_None range_Some split: if_splits option.splits elim: transE)
qed simp

lemma greatest_is_MaxR_opt:
  assumes "x \<in> A \<inter> Field r"
  assumes "\<forall>y \<in> A \<inter> Field r. (y, x) \<in> r"
  shows "MaxR_opt A = Some x"
using finite[of A] assms
proof(induct arbitrary: x)
  note ins = insert
  case (insert a A) then show ?case
    using maxR_absorb1 maxR_absorb2
    by (fastforce simp: maxR_def ins dest: range_None range_Some split: option.splits)
qed simp

lemma subset:
  assumes "set_option (MaxR_opt B) \<subseteq> A"
  assumes "A \<subseteq> B"
  shows "MaxR_opt B = MaxR_opt A"
using union[where A=A and B="B-A"] range[of "B - A"] assms
by (auto simp: Un_absorb1 finite_subset maxR_def split: option.splits)

(*>*)

end

interpretation MaxR_empty: MaxR "{}"
by unfold_locales simp

interpretation MaxR_singleton: MaxR "{(x,x)}" for x
by unfold_locales simp

lemma MaxR_r_domain [iff]:
  assumes "MaxR r"
  shows "MaxR (Restr r A)"
using assms Linear_order_Restr unfolding MaxR_def by blast


subsection\<open> Linear orders from lists \<close>

text\<open>

Often the easiest way to specify a concrete linear order is with a
list. Here these run from greatest to least.

\<close>

primrec linord_of_listP :: "'a \<Rightarrow> 'a \<Rightarrow> 'a list \<Rightarrow> bool" where
  "linord_of_listP x y [] \<longleftrightarrow> False"
| "linord_of_listP x y (z # zs) \<longleftrightarrow> (z = y \<and> x \<in> set (z # zs)) \<or> linord_of_listP x y zs"

definition linord_of_list :: "'a list \<Rightarrow> 'a rel" where
  "linord_of_list xs \<equiv> {(x, y). linord_of_listP x y xs}"

(*<*)

lemma linord_of_list_linord_of_listP:
  shows "xy \<in> linord_of_list xs \<longleftrightarrow> linord_of_listP (fst xy) (snd xy) xs"
unfolding linord_of_list_def split_def by simp

lemma linord_of_listP_linord_of_list:
  shows "linord_of_listP x y xs \<longleftrightarrow> (x, y) \<in> linord_of_list xs"
unfolding linord_of_list_def by simp

lemma linord_of_listP_empty:
  shows "(\<forall>x y. \<not>linord_of_listP x y xs) \<longleftrightarrow> xs = []"
by (metis linord_of_listP.simps list.exhaust list.set_intros(1))

lemma linord_of_listP_domain:
  assumes "linord_of_listP x y xs"
  shows "x \<in> set xs \<and> y \<in> set xs"
using assms by (induct xs) auto

lemma linord_of_list_empty[iff]:
  "linord_of_list [] = {}"
  "linord_of_list xs = {} \<longleftrightarrow> xs = []"
unfolding linord_of_list_def by (simp_all add: linord_of_listP_empty)

lemma linord_of_list_singleton:
  "(x, y) \<in> linord_of_list [z] \<longleftrightarrow> x = z \<and> y = z"
by (force simp: linord_of_list_linord_of_listP)

lemma linord_of_list_range:
  "linord_of_list xs \<subseteq> set xs \<times> set xs"
unfolding linord_of_list_def by (induct xs) auto

lemma linord_of_list_Field [simp]:
  "Field (linord_of_list xs) = set xs"
unfolding linord_of_list_def by (induct xs) (auto simp: Field_def)

lemma linord_of_listP_append:
  "linord_of_listP x y (xs @ ys) \<longleftrightarrow> linord_of_listP x y xs \<or> linord_of_listP x y ys \<or> (y \<in> set xs \<and> x \<in> set ys)"
by (induct xs) auto

lemma linord_of_list_append:
  "(x, y) \<in> linord_of_list (xs @ ys) \<longleftrightarrow> (x, y) \<in> linord_of_list xs \<or> (x, y) \<in> linord_of_list ys \<or> (y \<in> set xs \<and> x \<in> set ys)"
unfolding linord_of_list_def by (simp add: linord_of_listP_append)

lemma linord_of_list_refl_on:
  shows "refl_on (set xs) (linord_of_list xs)"
unfolding linord_of_list_def
by (induct xs) (auto intro!: refl_onI simp: refl_onD1 refl_onD2 dest: refl_onD subsetD[OF linord_of_list_range])

lemma linord_of_list_trans:
  assumes "distinct xs"
  shows "trans (linord_of_list xs)"
using assms unfolding linord_of_list_def
by (induct xs) (auto intro!: transI dest: linord_of_listP_domain elim: transE)

lemma linord_of_list_antisym:
  assumes "distinct xs"
  shows "antisym (linord_of_list xs)"
using assms unfolding linord_of_list_def
by (induct xs) (auto intro!: antisymI dest: linord_of_listP_domain simp: antisymD)

lemma linord_of_list_total_on:
  shows "total_on (set xs) (linord_of_list xs)"
unfolding total_on_def linord_of_list_def by (induct xs) auto

lemma linord_of_list_Restr:
  assumes "x \<notin> C"
  notes in_set_remove1[simp del] (* suppress warning *)
  shows "Restr (linord_of_list (remove1 x xs)) C = Restr (linord_of_list xs) C"
using assms unfolding linord_of_list_def by (induct xs) (auto iff: in_set_remove1)

lemma linord_of_list_nth:
  assumes "(xs ! i, xs ! j) \<in> linord_of_list xs"
  assumes "i < length xs" "j < length xs"
  assumes "distinct xs"
  shows "j \<le> i"
using %invisible assms
proof(induct xs arbitrary: i j)
  case (Cons x xs i j) show ?case
  proof(cases "i < length xs")
    case True with Cons show ?thesis
      by (auto simp: linord_of_list_linord_of_listP nth_equal_first_eq less_Suc_eq_0_disj linord_of_listP_domain)
  next
    case False with Cons show ?thesis by fastforce
  qed
qed simp

(*>*)
text\<open>\<close>

lemma linord_of_list_Linear_order:
  assumes "distinct xs"
  assumes "ys = set xs"
  shows "linear_order_on ys (linord_of_list xs)"
using %invisible assms linord_of_list_range linord_of_list_refl_on linord_of_list_trans linord_of_list_antisym linord_of_list_total_on
unfolding order_on_defs by force

text\<open>

Every finite linear order is generated by a list.

\<close>

(*<*)

inductive sorted_on :: "'a rel \<Rightarrow> 'a list \<Rightarrow> bool" where
  Nil [iff]: "sorted_on r []"
| Cons [intro!]: "\<lbrakk>x \<in> Field r; \<forall>y\<in>set xs. (x, y) \<in> r; sorted_on r xs\<rbrakk> \<Longrightarrow> sorted_on r (x # xs)"

inductive_cases sorted_on_inv[elim!]:
  "sorted_on r []"
  "sorted_on r (x # xs)"

primrec insort_key_on :: "'a rel \<Rightarrow> ('b \<Rightarrow> 'a) \<Rightarrow> 'b \<Rightarrow> 'b list \<Rightarrow> 'b list" where
  "insort_key_on r f x [] = [x]"
| "insort_key_on r f x (y # ys) =
    (if (f x, f y) \<in> r then (x # y # ys) else y # insort_key_on r f x ys)"

definition sort_key_on :: "'a rel \<Rightarrow> ('b \<Rightarrow> 'a) \<Rightarrow> 'b list \<Rightarrow> 'b list" where
  "sort_key_on r f xs = foldr (insort_key_on r f) xs []"

definition insort_insert_key_on :: "'a rel \<Rightarrow> ('b \<Rightarrow> 'a) \<Rightarrow> 'b \<Rightarrow> 'b list \<Rightarrow> 'b list" where
  "insort_insert_key_on r f x xs =
    (if f x \<in> f ` set xs then xs else insort_key_on r f x xs)"

abbreviation "sort_on r \<equiv> sort_key_on r (\<lambda>x. x)"
abbreviation "insort_on r \<equiv> insort_key_on r (\<lambda>x. x)"
abbreviation "insort_insert_on r \<equiv> insort_insert_key_on r (\<lambda>x. x)"

context
  fixes r :: "'a rel"
  assumes "Linear_order r"
begin

lemma sorted_on_single [iff]:
  shows "sorted_on r [x] \<longleftrightarrow> x \<in> Field r"
by (metis empty_iff list.distinct(1) list.set(1) nth_Cons_0 sorted_on.simps)

lemma sorted_on_many:
  assumes "(x, y) \<in> r"
  assumes "sorted_on r (y # zs)"
  shows "sorted_on r (x # y # zs)"
using assms \<open>Linear_order r\<close> unfolding order_on_defs by (auto elim: transE)

lemma sorted_on_Cons:
  shows "sorted_on r (x # xs) \<longleftrightarrow> (x \<in> Field r \<and> sorted_on r xs \<and> (\<forall>y\<in>set xs. (x, y) \<in> r))"
using \<open>Linear_order r\<close> unfolding order_on_defs by (induct xs arbitrary: x) (auto elim: transE)

lemma sorted_on_distinct_set_unique:
  assumes "sorted_on r xs" "distinct xs" "sorted_on r ys" "distinct ys" "set xs = set ys"
  shows "xs = ys"
proof -
  from assms have 1: "length xs = length ys" by (auto dest!: distinct_card)
  from assms show ?thesis
  proof(induct rule: list_induct2[OF 1])
    case (2 x xs y ys) with \<open>Linear_order r\<close> show ?case
      unfolding order_on_defs
        by (simp add: sorted_on_Cons) (metis antisymD insertI1 insert_eq_iff)
  qed simp
qed

lemma set_insort_on:
  shows "set (insort_key_on r f x xs) = insert x (set xs)"
by (induct xs) auto

lemma sort_key_on_simps [simp]:
  shows "sort_key_on r f [] = []"
        "sort_key_on r f (x#xs) = insort_key_on r f x (sort_key_on r f xs)"
by (simp_all add: sort_key_on_def)

lemma set_sort_on [simp]:
  shows "set (sort_key_on r f xs) = set xs"
by (induct xs) (simp_all add: set_insort_on)

lemma distinct_insort_on:
  shows "distinct (insort_key_on r f x xs) = (x \<notin> set xs \<and> distinct xs)"
by(induct xs) (auto simp: set_insort_on)

lemma distinct_sort_on [simp]:
  shows "distinct (sort_key_on r f xs) = distinct xs"
by (induct xs) (simp_all add: distinct_insort_on)

lemma sorted_on_insort_key_on:
  assumes "f ` set (x # xs) \<subseteq> Field r"
  shows "sorted_on r (map f (insort_key_on r f x xs)) = sorted_on r (map f xs)"
using assms
proof(induct xs)
  case (Cons x xs) with \<open>Linear_order r\<close> show ?case
    unfolding order_on_defs
    by (auto 4 4 simp: sorted_on_Cons sorted_on_many set_insort_on refl_on_def total_on_def elim: transE)
qed simp

lemma sorted_on_insort_on:
  assumes "set (x # xs) \<subseteq> Field r"
  shows "sorted_on r (insort_on r x xs) = sorted_on r xs"
using sorted_on_insort_key_on[where f="\<lambda>x. x"] assms by simp

theorem sorted_on_sort_key_on [simp]:
  assumes "f ` set xs \<subseteq> Field r"
  shows "sorted_on r (map f (sort_key_on r f xs))"
using assms by (induct xs) (simp_all add: sorted_on_insort_key_on)

theorem sorted_on_sort_on [simp]:
  assumes "set xs \<subseteq> Field r"
  shows "sorted_on r (sort_on r xs)"
using sorted_on_sort_key_on[where f="\<lambda>x. x"] assms by simp

lemma finite_sorted_on_distinct_unique:
  assumes "A \<subseteq> Field r"
  assumes "finite A"
  shows "\<exists>!xs. set xs = A \<and> sorted_on r xs \<and> distinct xs"
proof -
  from \<open>finite A\<close> obtain xs where "set xs = A \<and> distinct xs"
    using finite_distinct_list by blast
  with \<open>A \<subseteq> Field r\<close> show ?thesis
    by (fastforce intro!: ex1I[where a="sort_on r xs"] simp: sorted_on_distinct_set_unique)
qed

end

lemma sorted_on_linord_of_list_subseteq_r:
  assumes "Linear_order r"
  assumes "sorted_on r xs"
  assumes "distinct xs"
  shows "linord_of_list (rev xs) \<subseteq> r"
using assms
proof(induct xs)
  case (Cons x xs)
  then have "linord_of_list (rev xs) \<subseteq> r" by (simp add: sorted_on_Cons)
  with Cons.prems show ?case
    by (clarsimp simp: linord_of_list_append linord_of_list_singleton sorted_on_Cons)
       (meson contra_subsetD subsetI underS_incl_iff)
qed simp

lemma sorted_on_linord_of_list:
  assumes "Linear_order r"
  assumes "set xs = Field r"
  assumes "sorted_on r xs"
  assumes "distinct xs"
  shows "linord_of_list (rev xs) = r"
proof(rule equalityI)
  from assms show "linord_of_list (rev xs) \<subseteq> r"
    using sorted_on_linord_of_list_subseteq_r by blast
next
  { fix x y assume xy: "(x, y) \<in> r"
    with \<open>Linear_order r\<close> have "(y, x) \<notin> r - Id"
      using Linear_order_in_diff_Id by fastforce
    with linord_of_list_Linear_order[of "rev xs" "Field r"] assms xy
    have "(x, y) \<in> linord_of_list (rev xs)"
      by simp (metis Diff_subset FieldI1 FieldI2 Linear_order_in_diff_Id linord_of_list_Field set_rev sorted_on_linord_of_list_subseteq_r subset_eq) }
  then show "r \<subseteq> linord_of_list (rev xs)" by clarsimp
qed

lemma linord_of_listP_rev:
  assumes "z # zs \<in> set (sublists xs)"
  assumes "y \<in> set zs"
  shows "linord_of_listP z y (rev xs)"
using assms by (induct xs) (auto simp: Let_def linord_of_listP_append dest: sublists_set)

lemma linord_of_list_sorted_on_sublists:
  assumes "ys \<in> set (sublists xs)"
  assumes "distinct xs"
  shows "sorted_on (linord_of_list (rev xs)) ys"
using assms
proof(induct ys)
  case (Cons y ys) then show ?case
    using linord_of_list_Linear_order[where xs="rev xs" and ys="Field (linord_of_list (rev xs))"]
    by (force simp: sublists_Cons_inv sorted_on_Cons linord_of_list_linord_of_listP linord_of_listP_rev dest: sublists_set)
qed simp

lemma linord_of_list_sorted_on:
  assumes "distinct xs"
  shows "sorted_on (linord_of_list (rev xs)) xs"
by (rule linord_of_list_sorted_on_sublists[OF sublists_refl \<open>distinct xs\<close>])

(*>*)

lemma linear_order_on_list:
  assumes "linear_order_on ys r"
  assumes "ys = Field r"
  assumes "finite ys"
  shows "\<exists>!xs. r = linord_of_list xs \<and> distinct xs \<and> set xs = ys"
using %invisible finite_sorted_on_distinct_unique[of r ys] sorted_on_linord_of_list[of r] assms
by simp (metis distinct_rev linord_of_list_sorted_on rev_rev_ident set_rev)

(*<*)

end
(*>*)
