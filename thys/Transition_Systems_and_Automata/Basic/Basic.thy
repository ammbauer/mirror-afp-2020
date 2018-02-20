section {* Basics *}

theory Basic
imports Main
begin

  subsection {* Miscellaneous *}

  abbreviation (input) "const x \<equiv> \<lambda> _. x"

  lemma if_apply: "(if c then f else g) x = (if c then f x else g x)" by simp

  lemmas if_distribs = if_distrib if_apply

  lemma prod_UNIV[iff]: "A \<times> B = UNIV \<longleftrightarrow> A = UNIV \<and> B = UNIV" by auto

  lemma infinite_subset[trans]: "infinite A \<Longrightarrow> A \<subseteq> B \<Longrightarrow> infinite B" using infinite_super by this
  lemma finite_subset[trans]: "A \<subseteq> B \<Longrightarrow> finite B \<Longrightarrow> finite A" using finite_subset by this

  declare infinite_coinduct[case_names infinite, coinduct pred: infinite]
  lemma infinite_psubset_coinduct[case_names infinite, consumes 1]:
    assumes "R A"
    assumes "\<And> A. R A \<Longrightarrow> \<exists> B \<subset> A. R B"
    shows "infinite A"
  proof
    assume "finite A"
    then show "False" using assms by (induct rule: finite_psubset_induct) (auto)
  qed

  (* TODO: why are there two copies of this theorem? *)
  thm inj_on_subset subset_inj_on

end
