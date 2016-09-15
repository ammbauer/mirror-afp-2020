(*  
    Author:      René Thiemann 
                 Akihisa Yamada
    License:     BSD
*)
section \<open>Polynomial Divisibility\<close>

text \<open>We make a connection between irreducibility of Missing-Polynomial and Factorial-Ring.\<close>


theory Polynomial_Divisibility
imports
  "../Polynomial_Interpolation/Missing_Polynomial"
begin

lemma dvd_gcd_mult: fixes p :: "'a :: semiring_gcd"
  assumes dvd: "k dvd p * q" "k dvd p * r"
  shows "k dvd p * gcd q r"
  by (rule dvd_trans, rule gcd_greatest[OF dvd])
     (auto intro!: mult_dvd_mono simp: gcd_mult_left)

lemma poly_gcd_monic_factor:
  "monic p \<Longrightarrow>  gcd (p * q) (p * r) = p * gcd q r"
  by (rule gcdI [symmetric]) (simp_all add: normalize_mult normalize_monic dvd_gcd_mult)

context
  assumes "SORT_CONSTRAINT('a :: field)"
begin
lemma irreducible_connect:
  assumes irr: "Missing_Polynomial.irreducible (p::'a poly)" shows "Factorial_Ring.irreducible p"
  unfolding Factorial_Ring.irreducible_def
proof (intro conjI impI allI)
  from irr have deg: "degree p \<noteq> 0" and p: "p \<noteq> 0"
    unfolding Missing_Polynomial.irreducible_def by auto
  note unit = is_unit_iff_degree[OF p]
  from p deg show "p \<noteq> 0" "\<not> is_unit p" unfolding unit by auto
  fix f g
  assume pfg: "p = f * g"
  with p have f: "f \<noteq> 0" and g: "g \<noteq> 0" by auto
  show "is_unit f \<or> is_unit g" unfolding is_unit_iff_degree[OF f] is_unit_iff_degree[OF g]
    using irreducibleD(2)[OF irr, unfolded pfg] deg[unfolded pfg] f g
    using degree_mult_eq by fastforce
qed

lemma irreducible_prime_elem:
  assumes irr: "Missing_Polynomial.irreducible (p::'a poly)" shows "prime_elem p"
  using field_poly_irreducible_imp_prime[OF irreducible_connect[OF irr]] .

lemma irreducible_dvd_mult: assumes irr: "irreducible (p :: 'a poly)"
  and dvd: "p dvd q * r"
  shows "p dvd q \<or> p dvd r" using prime_elem_dvd_multD[OF irreducible_prime_elem[OF irr] dvd] .

lemma irreducible_dvd_pow: fixes p :: "'a poly" 
  assumes irr: "irreducible p"  
  shows "p dvd q ^ n \<Longrightarrow> p dvd q"
  using irreducible_prime_elem[OF irr] by (rule prime_elem_dvd_power)

lemma irreducible_dvd_setprod: fixes p :: "'a poly"
  assumes irr: "irreducible p"
  and dvd: "p dvd setprod f as"
  shows "\<exists> a \<in> as. p dvd f a"
proof -
  from irr[unfolded irreducible_def] have deg: "degree p \<noteq> 0" by auto
  hence p1: "\<not> p dvd 1" unfolding dvd_def
    by (metis degree_1 div_mult_self1_is_id div_poly_less linorder_neqE_nat mult_not_zero not_less0 zero_neq_one)
  from dvd show ?thesis
  proof (induct as rule: infinite_finite_induct)
    case (insert a as)
    hence "setprod f (insert a as) = f a * setprod f as" by auto
    from irreducible_dvd_mult[OF irr insert(4)[unfolded this]]
    show ?case using insert(3) by auto
  qed (insert p1, auto)
qed

lemma irreducible_dvd_prod_list: fixes p :: "'a poly"
  assumes irr: "irreducible p"
  and dvd: "p dvd prod_list as"
  shows "\<exists> a \<in> set as. p dvd a"
proof -
  from irr[unfolded irreducible_def] have deg: "degree p \<noteq> 0" by auto
  hence p1: "\<not> p dvd 1" unfolding dvd_def
    by (metis degree_1 div_mult_self1_is_id div_poly_less linorder_neqE_nat mult_not_zero not_less0 zero_neq_one)
  from dvd show ?thesis
  proof (induct as)
    case (Cons a as)
    hence "prod_list (Cons a as) = a * prod_list as" by auto
    from irreducible_dvd_mult[OF irr Cons(2)[unfolded this]] Cons(1)
    show ?case by auto
  qed (insert p1, auto)
qed


lemma dvd_mult: fixes p :: "'a poly" 
  assumes "p dvd q * r"
  and "degree p \<noteq> 0" 
shows "\<exists> s t. irreducible s \<and> p = s * t \<and> (s dvd q \<or> s dvd r)"
proof -
  from irreducible_factor[OF assms(2)] obtain s t
  where irred: "irreducible s" and p: "p = s * t" by auto
  from `p dvd q * r` p have s: "s dvd q * r" unfolding dvd_def by auto
  from irreducible_dvd_mult[OF irred s] p irred show ?thesis by auto
qed  
end

end
