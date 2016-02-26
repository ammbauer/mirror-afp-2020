(*  
    Title:      Euclidean_Algorithm_Extension.thy
    Author:     Jose Divasón <jose.divasonm at unirioja.es>
    Author:     Jesús Aransay <jesus-maria.aransay at unirioja.es>
    Maintainer: Jose Divasón <jose.divasonm at unirioja.es>
*)

section "Euclidean Algorithm Extension"


theory Euclidean_Algorithm_Extension
imports 
  Euclidean_Algorithm
  "~~/src/HOL/Library/Polynomial"
begin

instantiation nat :: euclidean_semiring_gcd
begin

lemma Lcm_nat_altdef: "Lcm_eucl (A::nat set) 
  = (if finite A then Finite_Set.fold lcm_eucl (1::nat) A else 0)"
proof (cases "finite A")
  assume "\<not>finite A"
  hence "Lcm_eucl A = 0"
  proof (intro Lcm_eucl_no_multiple impI allI)
    fix m :: nat assume "m \<noteq> 0"
    from `\<not>finite A` have "\<forall>m. \<exists>n\<in>A. n > m" using finite_nat_set_iff_bounded_le 
      by (auto simp: not_le)
    then obtain x where "x \<in> A" and "x > m" by blast
    moreover with `m \<noteq> 0` have "\<not>x dvd m" by (auto dest: dvd_imp_le)
    ultimately show "\<exists>x\<in>A. \<not>x dvd m" by blast
  qed
  thus "Lcm_eucl A = (if finite A then Finite_Set.fold lcm_eucl (1::nat) A else 0)"
    using `\<not>finite A` by simp
qed (simp add: Lcm_eucl_finite)

instance
proof
  show gcd: "(gcd :: nat \<Rightarrow> nat \<Rightarrow> nat) = gcd_eucl"
  proof (rule ext)+
    fix a b :: nat show "gcd a b = gcd_eucl a b"
      by (induction a b rule: gcd_eucl.induct)
    (subst gcd_nat.simps, subst gcd_eucl.simps, simp_all)
  qed
  then show lcm: "(lcm :: nat \<Rightarrow> nat \<Rightarrow> nat) = lcm_eucl"
    by (intro ext) (simp add: lcm_nat_def lcm_eucl_def)
  show "(Lcm :: nat set \<Rightarrow> nat) = Lcm_eucl"
  proof
    fix M :: "nat set" show "Lcm M = Lcm_eucl M"
    by (induct M rule: infinite_finite_induct)
      (simp_all add: lcm Lcm_nat_infinite, simp add: Lcm_nat_altdef)
  qed
  then show "(Gcd :: nat set \<Rightarrow> nat) = Gcd_eucl"
    by (simp add: fun_eq_iff Gcd_nat_def Gcd_eucl_def)
qed

end

instantiation int :: euclidean_ring_gcd
begin

lemma Lcm_int_altdef: "Lcm_eucl (A::int set) 
  = (if finite A then Finite_Set.fold lcm_eucl (1::int) A else 0)"
proof (cases "finite A")
  assume "\<not>finite A"
  hence "Lcm_eucl A = 0"
  proof (intro Lcm_eucl_no_multiple impI allI)
    fix m :: int assume "m \<noteq> 0"
    from `\<not>finite A` have "\<not>(\<exists>m\<ge>0. \<forall>n\<in>A. \<bar>n\<bar> \<le> m)" 
      using finite_int_set_iff_bounded_le by simp
    hence "\<And>m. m \<ge> 0 \<Longrightarrow> \<exists>n\<in>A. \<bar>n\<bar> > m" by (case_tac "m < 0") (auto simp: not_le)
    from this[of "\<bar>m\<bar>"] obtain x where "x \<in> A" and "\<bar>x\<bar> > \<bar>m\<bar>" by auto
    hence "nat \<bar>x\<bar> > nat \<bar>m\<bar>" by (simp add: nat_less_eq_zless)
    moreover from `m \<noteq> 0` have "nat \<bar>m\<bar> \<noteq> 0" by simp
    ultimately have "\<not>nat \<bar>x\<bar> dvd nat \<bar>m\<bar>" by (auto dest: dvd_imp_le)
    hence "\<not>x dvd m" by (simp add: transfer_nat_int_relations)
    with `x \<in> A` show "\<exists>x\<in>A. \<not>x dvd m" by blast
  qed
  thus "Lcm_eucl A = (if finite A then Finite_Set.fold lcm_eucl (1::int) A else 0)"
    using `\<not>finite A` by simp
qed (simp add: Lcm_eucl_finite)



instance proof
  show A: "gcd = (gcd_eucl :: int \<Rightarrow> int \<Rightarrow> int)"
  proof (intro ext)
    fix a b :: int show "gcd a b = gcd_eucl a b"
    proof (induction a b rule: gcd_eucl.induct)
      fix a b::int assume hyp: "(b \<noteq> 0 \<Longrightarrow> gcd b (a mod b) = gcd_eucl b (a mod b))" 
      show "gcd a b = gcd_eucl a b"
        by (subst gcd_int_def, subst gcd_eucl.simps, simp_all)
      (metis abs_zero div_by_0 div_mult_self2_is_id gcd.commute gcd_int_def 
        gcd_eucl_mod1 gcd_red_int hyp mult.commute mult_sgn_abs mult_zero_right)
    qed
  qed
  show l: "lcm = (lcm_eucl :: int \<Rightarrow> int \<Rightarrow> int)"
  proof (intro ext)
    fix x xa::int
    show "lcm x xa = lcm_eucl x xa"
      by (auto simp add: lcm_int_def lcm_lcm_eucl lcm_eucl_def)
    (metis A abs_ge_zero div_mult_mult2 gcd_abs_int gcd_gcd_eucl int_nat_eq mult.commute
      mult_eq_0_iff mult_sgn_abs nat_abs_mult_distrib transfer_int_nat_gcd(1) zdiv_int)
  qed
  show L: "(Lcm::int set \<Rightarrow> int) = Lcm_eucl"
  proof (intro ext)
    fix X::"int set"
    show "Lcm X = Lcm_eucl X"
    proof (cases "finite X")
      case False 
      have n: "nat_set (abs ` X)" unfolding nat_set_def by fastforce
      have "infinite (nat ` abs ` X)" 
        unfolding transfer_int_nat_set_relations(1) [OF n, symmetric] using False 
        unfolding finite_int_set_iff_bounded_le by (auto simp add: image_image)
      then have "infinite ((nat \<circ> abs) ` X)"
        by (simp add: image_comp)
      with False show ?thesis unfolding Lcm_int_def Lcm_nat_def
        by (simp add: Lcm_int_altdef)
    next
      case True
      thus ?thesis by (induct X, simp_all add: l)
    qed 
  qed
  show "(Gcd :: int set \<Rightarrow> int) = Gcd_eucl"
    apply (rule ext)
    apply (rule associated_eqI)
    apply simp_all
    apply (smt normalisation_factor_Gcd_eucl normalisation_factor_int_def sgn_less)
    done
qed

end

instantiation poly :: (field) euclidean_ring
begin

text{*In mathematics, the degree of zero polynomial is @{text "- \<infinity>"}, then the euclidean size for
  polynomials is defined as @{text "2 ^ (degree p)"}. However, in Isabelle we have 
  @{text "degree 0 = 0"}, so the euclidean size has to be adapted:*}

definition "euclidean_size_poly p = (if p = 0 then 0 else (2::nat) ^ (degree p))"

  (*The following one is an alternative definition: *)
  (*definition "euclidean_size_poly p = (if p = 0 then 0 else (degree p) + 1)"*)

definition "normalisation_factor_poly p = [:coeff p (degree p):]"

instance
proof
  fix a b::"'a poly" 
  assume b: "b \<noteq> 0" 
  show "euclidean_size a \<le> euclidean_size (a * b)" 
    unfolding euclidean_size_poly_def
    using b
    by (auto, metis dvdI dvd_imp_degree_le mult_eq_0_iff)
  show "euclidean_size (a mod b) < euclidean_size b" 
    using b
    unfolding euclidean_size_poly_def by (auto, metis b degree_mod_less)
next
  fix a b::"'a poly"
  show n_0: "normalisation_factor (0::'a poly) = 0" 
    unfolding normalisation_factor_poly_def by auto
  show "normalisation_factor (a * b) = normalisation_factor a * normalisation_factor b"
  proof (cases "a*b=0")
    case True 
    have "a=0 \<or> b=0" using True by auto
    thus ?thesis using n_0 by auto
  next
    case False
    have a_not_0: "a \<noteq> 0" and b_not_0: "b \<noteq> 0" using False by simp+
    show ?thesis unfolding normalisation_factor_poly_def
      unfolding last_coeffs_eq_coeff_degree[OF b_not_0]
      unfolding last_coeffs_eq_coeff_degree[OF a_not_0]
      unfolding last_coeffs_eq_coeff_degree[OF False]
      unfolding degree_mult_eq[OF a_not_0 b_not_0]
      unfolding coeff_mult_degree_sum by simp
  qed
  assume a: "a \<noteq> 0" show "is_unit (normalisation_factor a)" 
    unfolding normalisation_factor_poly_def
    unfolding is_unit_def unfolding one_poly_def unfolding dvd_def 
    by (rule exI[of _ "[:1/(coeff a (degree a)):]"], simp add: a)
next
  fix a::"'a poly" assume u: "is_unit a"
  show "normalisation_factor a = a" 
    using u
    unfolding normalisation_factor_poly_def is_unit_def dvd_def
    by (auto, metis (erased, hide_lams) coeff_pCons_0 degree_pCons_0 dvdI 
      dvd_imp_degree_le eq_iff le0 add.left_neutral mult.commute mult_zero_left 
      one_neq_zero one_poly_def synthetic_div_correct' synthetic_div_eq_0_iff)
qed

end

end
