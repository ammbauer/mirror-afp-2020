theory Poly_Mapping_Finite_Map
  imports
    "More_MPoly_Type"
    "HOL-Library.Finite_Map"
begin

text \<open>In this theory, type @{typ "('a, 'b) poly_mapping"} is represented as association lists.
  Code equations are proved in order actually perform computations (addition, multiplication, etc.).\<close>

subsection \<open>Utilities\<close>

instantiation poly_mapping :: (type, "{equal, zero}") equal
begin
definition equal_poly_mapping::"('a, 'b) poly_mapping \<Rightarrow> ('a, 'b) poly_mapping \<Rightarrow> bool" where
  "equal_poly_mapping p q \<equiv> (\<forall>t. lookup p t = lookup q t)"

instance by standard (auto simp: equal_poly_mapping_def poly_mapping_eq_iff)

end

definition "clearjunk0 m = fmfilter (\<lambda>k. fmlookup m k \<noteq> Some 0) m"

definition "fmlookup_default d m x = (case fmlookup m x of Some v \<Rightarrow> v | None \<Rightarrow> d)"
abbreviation "lookup0 \<equiv> fmlookup_default 0"

lemma fmlookup_default_add[simp]:
  "fmlookup_default d (m ++\<^sub>f n) x =
    (if x |\<in>| fmdom n then the (fmlookup n x)
    else fmlookup_default d m x)"
  by (auto simp: fmlookup_default_def)

lemma fmlookup_default_if[simp]:
  "fmlookup ys a = Some r \<Longrightarrow> fmlookup_default d ys a = r"
  "fmlookup ys a = None \<Longrightarrow> fmlookup_default d ys a = d"
  by (auto simp: fmlookup_default_def)

lemma finite_lookup_default:
  "finite {x. fmlookup_default d xs x \<noteq> d}"
proof -
  have "{x. fmlookup_default d xs x \<noteq> d} \<subseteq> fmdom' xs"
    by (auto simp: fmlookup_default_def fmdom'I split: option.splits)
  also have "finite \<dots>"
    by (simp add: fmdom'.rep_eq)
  finally (finite_subset) show ?thesis .
qed

lemma lookup0_clearjunk0: "lookup0 xs s = lookup0 (clearjunk0 xs) s"
  unfolding clearjunk0_def fmlookup_default_def
  by auto

lemma clearjunk0_nonzero:
  assumes "t \<in> fmdom' (clearjunk0 xs)"
  shows "fmlookup xs t \<noteq> Some 0"
  using assms unfolding clearjunk0_def by simp

lemma clearjunk0_map_of_SomeD:
  assumes a1: "fmlookup xs t = Some c" and "c \<noteq> 0"
  shows "t \<in> fmdom' (clearjunk0 xs)"
  using assms
  by (auto simp: clearjunk0_def fmdom'I)


subsection \<open>Implementation of Polynomial Mappings as Association Lists\<close>

lift_definition Pm_fmap::"('a, 'b::zero) fmap \<Rightarrow> 'a \<Rightarrow>\<^sub>0 'b" is lookup0
  by (rule finite_lookup_default)

lemmas [simp] = Pm_fmap.rep_eq

code_datatype Pm_fmap

lemma PM_clearjunk0_cong:
  "Pm_fmap (clearjunk0 xs) = Pm_fmap xs"
  by (metis Pm_fmap.rep_eq lookup0_clearjunk0 poly_mapping_eqI)

lemma PM_all_2:
  assumes "P 0 0"
  shows "(\<forall>x. P (lookup (Pm_fmap xs) x) (lookup (Pm_fmap ys) x)) =
    fmpred (\<lambda>k v. P (lookup0 xs k) (lookup0 ys k)) (xs ++\<^sub>f ys)"
  using assms unfolding list_all_def
  by (force simp: fmlookup_default_def fmlookup_dom_iff
      split: option.splits if_splits)

lemma compute_keys_pp[code]: "keys (Pm_fmap xs) = fmdom' (clearjunk0 xs)"
  by transfer
    (auto simp: fmlookup_dom'_iff clearjunk0_def fmlookup_default_def fmdom'I split: option.splits)

lemma compute_zero_pp[code]: "0 = Pm_fmap fmempty"
  by (auto intro!: poly_mapping_eqI simp: fmlookup_default_def)

lemma compute_plus_pp[code]:
  "Pm_fmap xs + Pm_fmap ys = Pm_fmap (fmmap_keys (\<lambda>k v. lookup0 xs k + lookup0 ys k) (xs ++\<^sub>f ys))"
  by (auto intro!: poly_mapping_eqI
      simp: fmlookup_default_def lookup_add fmlookup_dom_iff
      split: option.splits)

lemma compute_lookup_pp[code]:
  "lookup (Pm_fmap xs) x = lookup0 xs x"
  by (transfer, simp)

lemma compute_minus_pp[code]:
  "Pm_fmap xs - Pm_fmap ys = Pm_fmap (fmmap_keys (\<lambda>k v. lookup0 xs k - lookup0 ys k) (xs ++\<^sub>f ys))"
  by (auto intro!: poly_mapping_eqI
      simp: fmlookup_default_def lookup_minus fmlookup_dom_iff
      split: option.splits)

lemma compute_uminus_pp[code]:
  "- Pm_fmap ys = Pm_fmap (fmmap_keys (\<lambda>k v. - lookup0 ys k) ys)"
  by (auto intro!: poly_mapping_eqI
      simp: fmlookup_default_def
      split: option.splits)

lemma compute_equal_pp[code]:
  "equal_class.equal (Pm_fmap xs) (Pm_fmap ys) = fmpred (\<lambda>k v. lookup0 xs k = lookup0 ys k) (xs ++\<^sub>f ys)"
  unfolding equal_poly_mapping_def by (simp only: PM_all_2)

lemma compute_map_pp[code]:
  "Poly_Mapping.map f (Pm_fmap xs) = Pm_fmap (fmmap (\<lambda>x. f x when x \<noteq> 0) xs)"
  by (auto intro!: poly_mapping_eqI
      simp: fmlookup_default_def map.rep_eq
      split: option.splits)

lemma fmran'_fmfilter_eq: "fmran' (fmfilter p fm) = {y | y. \<exists>x \<in> fmdom' fm. p x \<and> fmlookup fm x = Some y}"
  by (force simp: fmlookup_ran'_iff fmdom'I split: if_splits)

lemma compute_range_pp[code]:
  "Poly_Mapping.range (Pm_fmap xs) = fmran' (clearjunk0 xs)"
  by (force simp: range.rep_eq clearjunk0_def fmran'_fmfilter_eq fmdom'I
      fmlookup_default_def split: option.splits)


subsection \<open>Code setup for type MPoly\<close>

lift_definition mpoly_of_sparse::"((nat \<times> nat) list \<times> 'a::zero) list \<Rightarrow> 'a mpoly"
  is "\<lambda>xs. Pm_fmap (fmap_of_list (map (apfst (Pm_fmap o fmap_of_list)) xs))" .

definition "mpoly_of_dense xs = mpoly_of_sparse (map (\<lambda>(xs, c). (zip [0..<length xs] xs, c)) xs)"

definition "monom_of_list xs c = mpoly_of_dense [(xs, c)]"

instantiation mpoly::("{equal, zero}")equal begin

lift_definition equal_mpoly:: "'a mpoly \<Rightarrow> 'a mpoly \<Rightarrow> bool" is HOL.equal .

instance proof standard qed (transfer, rule equal_eq)

end

experiment begin

abbreviation "M  \<equiv> monom_of_list"

lemma "content_primitive (M [1,2,3] (4::int) + M [2, 0, 4] 6 + M [2,0,5] 8) =
    (2, (M [1,2,3] (2::int) + M [2, 0, 4] 3 + M [2,0,5] 4))"
  by eval

end

end
