(*
    Authors:      Jose Divasón
                  Sebastiaan Joosten
                  René Thiemann
                  Akihisa Yamada
*)
subsection \<open>Finding a Suitable Prime\<close>

text \<open>The Berlekamp-Zassenhaus algorithm demands for an input polynomial $f$ to determine
  a prime $p$ such that $f$ is square-free mod $p$ and such that $p$ and the leading coefficient
  of $f$ are coprime. To this end, we first prove that such a prime always exists, provided that 
  $f$ is square-free over the integers. Second, we provide a generic algorithm which searches for 
  primes have a certain property $P$. Combining both results gives us the suitable prime for
  the Berlekamp-Zassenhaus algorithm.\<close>

theory Suitable_Prime
imports 
  Polynomial_Record_Based
  Finite_Field_Record_Based
  Poly_Mod
  Square_Free_Int_To_Square_Free_GFp
  Poly_Mod_Finite_Field_Record_Based
  "~~/src/HOL/Types_To_Sets/Types_To_Sets"
begin

lemma square_free_coprime_pderiv_GFp: fixes f :: "'a :: prime_card mod_ring poly"
  assumes card: "CARD('a) > degree f"
  and sf: "square_free f" 
  shows "coprime f (pderiv f)"
proof (rule ccontr)
  assume "\<not> coprime f (pderiv f)" 
  from square_free_coprime_pderiv_main[OF sf this]
  obtain g k where *: "f = g * k" "degree g \<noteq> 0" and g0: "pderiv g = 0" by auto
  from assms have f: "f \<noteq> 0" unfolding square_free_def by auto
  have "degree f = degree g + degree k" using f unfolding *(1)
    by (subst degree_mult_eq, auto)
  with card have card: "degree g < CARD('a)" by auto
  from *(2) obtain n where deg: "degree g = Suc n" by (cases "degree g", auto)
  from *(2) have cg: "coeff g (degree g) \<noteq> 0" by auto
  from g0 have "coeff (pderiv g) n = 0" by auto
  from this[unfolded coeff_pderiv, folded deg] cg
  have "of_nat (degree g) = (0 :: 'a mod_ring)" by auto
  from of_nat_0_mod_ring_dvd[OF this] have "CARD('a) dvd degree g" .
  with card show False by (simp add: deg nat_dvd_not_less)
qed
  
lemma square_free_iff_coprime_GFp: assumes "degree f < CARD('a)" 
  shows "square_free (f :: 'a :: prime_card mod_ring poly) = (coprime f (pderiv f))"
  using coprime_pderiv_imp_square_free[of f] square_free_coprime_pderiv_GFp[OF assms] by auto

definition square_free_impl_main :: "int \<Rightarrow> 'i arith_ops_record \<Rightarrow> int poly \<Rightarrow> bool" where
  "square_free_impl_main p ff_ops f = square_free_i ff_ops (of_int_poly_i ff_ops (poly_mod.Mp p f))" 

lemma (in prime_field_gen) square_free_impl: 
  assumes F: "(F :: 'a mod_ring poly) = of_int_poly (Mp f)" 
  shows "square_free_impl_main p ff_ops f \<Longrightarrow> square_free_m f" 
  "CARD('a) > degree_m f \<Longrightarrow> CARD('a) > square_free_bound f \<Longrightarrow> square_free f 
   \<Longrightarrow> square_free_impl_main p ff_ops f" unfolding square_free_impl_main_def
proof -
  let ?f' = "of_int_poly_i ff_ops (Mp f)" 
  define f'' where "f'' \<equiv> of_int_poly (Mp f) :: 'a mod_ring poly"
  have rel_f[transfer_rule]: "poly_rel ?f' f''" 
    by (rule poly_rel_coeffs_Mp_of_int_poly[OF refl], simp add: f''_def)
  have id: "square_free_i ff_ops ?f' = coprime f'' (pderiv f'')"
    unfolding square_free_i_def by transfer_prover
  have Mprel [transfer_rule]: "MP_Rel (Mp f) F" unfolding F MP_Rel_def
    by (simp add: Mp_f_representative)
  have "square_free f'' = square_free F" unfolding f''_def F by simp
  also have "\<dots> = square_free_m (Mp f)"
    by (transfer, simp)
  also have "\<dots> = square_free_m f" by simp
  finally have id2: "square_free f'' = square_free_m f" .
  from coprime_pderiv_imp_square_free[of f'']
  show "square_free_i ff_ops ?f' \<Longrightarrow> square_free_m f"
    unfolding id id2 by auto
  let ?m = "map_poly (of_int :: int \<Rightarrow> 'a mod_ring)" 
  let ?f = "?m f" 
  assume "CARD('a) > degree_m f" and bnd: "int CARD('a) > square_free_bound f" 
    and sf: "square_free f" 
  with rel_funD[OF degree_MP_Rel Mprel]
  have "CARD('a) > degree F" by simp
  hence "CARD('a) > degree f''" unfolding f''_def F by simp
  from square_free_iff_coprime_GFp[OF this]
  have "square_free_i ff_ops ?f' = square_free f''" unfolding id id2 by simp
  also have "\<dots> = square_free F" unfolding f''_def F by simp
  also have "F = ?f" unfolding F
    by (rule poly_eqI, (subst coeff_map_poly, force)+, unfold Mp_coeff, 
    auto simp: M_def, transfer, auto simp: p)
  also have "square_free ?f" using square_free_int_imp_square_free_mod_ring[where 'a = 'a, OF sf bnd] .
  finally
  show "square_free_i ff_ops ?f'" .
qed

lemma square_free_impl_int: assumes 
  p: "prime p" and
  res: "square_free_impl_main p (finite_field_ops p) f = sf" 
  shows "sf \<Longrightarrow> poly_mod.square_free_m p f"
    "nat p > poly_mod.degree_m p f \<Longrightarrow> nat p > square_free_bound f \<Longrightarrow> square_free f 
    \<Longrightarrow> sf" 
proof -
  have ne: "{0..<p} \<noteq> {}" using prime_ge_2_int[OF p] by auto
  {
    assume "\<exists>(Rep :: 'b \<Rightarrow> int) Abs. type_definition Rep Abs {0 ..< p :: int}"
    from prime_type_prime_card[OF p this]
    have "class.prime_card TYPE('b)" and p: "p = int CARD('b)" by auto
    from prime_field_gen.square_free_impl[OF 
        prime_field.prime_field_finite_field_ops, unfolded prime_field_def mod_ring_locale_def,
      internalize_sort "'a :: prime_card", OF this refl, of f]
    have "sf \<Longrightarrow> poly_mod.square_free_m p f" 
      "nat p > poly_mod.degree_m p f \<Longrightarrow> nat p > square_free_bound f \<Longrightarrow> square_free f \<Longrightarrow> 
      sf" unfolding p res[symmetric] by auto
  }
  from this[cancel_type_definition, OF ne]
  show "sf \<Longrightarrow> poly_mod.square_free_m p f" 
    "nat p > poly_mod.degree_m p f \<Longrightarrow> nat p > square_free_bound f \<Longrightarrow> square_free f 
    \<Longrightarrow> sf" by auto
qed

lemma square_free_impl_uint32: assumes 
  p: "prime p" and
  res: "square_free_impl_main p (finite_field_ops32 (uint32_of_int p)) f = sf" and
  small: "p \<le> 65535"     
  shows "sf \<Longrightarrow> poly_mod.square_free_m p f"
    "nat p > poly_mod.degree_m p f \<Longrightarrow> nat p > square_free_bound f \<Longrightarrow> square_free f 
    \<Longrightarrow> sf" 
proof -
  have ne: "{0..<p} \<noteq> {}" using prime_ge_2_int[OF p] by auto
  {
    assume "\<exists>(Rep :: 'b \<Rightarrow> int) Abs. type_definition Rep Abs {0 ..< p :: int}"
    from prime_type_prime_card[OF p this]
    have "class.prime_card TYPE('b)" and p: "p = int CARD('b)" by auto
    from prime_field_gen.square_free_impl[OF 
        prime_field.prime_field_finite_field_ops32, unfolded prime_field_def mod_ring_locale_def,
      internalize_sort "'a :: prime_card", OF this small refl, of f]
    have "sf \<Longrightarrow> poly_mod.square_free_m p f" 
      "nat p > poly_mod.degree_m p f \<Longrightarrow> nat p > square_free_bound f \<Longrightarrow> square_free f \<Longrightarrow> 
      sf" unfolding p res[symmetric] by auto
  }
  from this[cancel_type_definition, OF ne]
  show "sf \<Longrightarrow> poly_mod.square_free_m p f" 
    "nat p > poly_mod.degree_m p f \<Longrightarrow> nat p > square_free_bound f \<Longrightarrow> square_free f 
    \<Longrightarrow> sf" by auto
qed

definition square_free_impl :: "int \<Rightarrow> int poly \<Rightarrow> bool" where
  "square_free_impl p = ( 
    if p \<le> 65535 
    then square_free_impl_main p (finite_field_ops32 (uint32_of_int p))
    else square_free_impl_main p (finite_field_ops p))" 

lemma square_free_mod_imp_square_free: assumes 
  p: "prime p" and sf: "poly_mod.square_free_m p f" and cop: "coprime (lead_coeff f) p" 
  shows "square_free f"
proof -
  interpret poly_mod p .
  from sf[unfolded square_free_m_def] have f0: "Mp f \<noteq> 0" and ndvd: "\<And> g. degree_m g \<noteq> 0 \<Longrightarrow> \<not> dvdm (g * g) f" 
    unfolding equivalent_def by auto
  from f0 have ff0: "f \<noteq> 0" by auto
  show "square_free f" unfolding square_free_def
  proof (intro conjI[OF ff0] allI impI notI)
    fix g
    assume deg: "degree g \<noteq> 0" and dvd: "g * g dvd f" 
    then obtain h where f: "f = g * g * h" unfolding dvd_def by auto
    from arg_cong[OF this, of Mp] have "dvdm (g * g) f" unfolding dvdm_def equivalent_def by auto
    with ndvd[of g] have deg0: "degree_m g = 0" by auto
    hence g0: "M (lead_coeff g) = 0" unfolding Mp_def using deg
      by (metis M_0 Mp_def Ring_Hom_Poly.degree_map_poly degree_m_def)
    from p have p0: "p \<noteq> 0" by auto
    from arg_cong[OF f, of lead_coeff] have "lead_coeff f = lead_coeff g * lead_coeff g * lead_coeff h" 
      by (auto simp: lead_coeff_mult)
    hence "lead_coeff g dvd lead_coeff f" by auto
    with cop have cop: "coprime (lead_coeff g) p" by (metis coprime_divisors dvd_def mult.right_neutral)
    with p0 have "coprime (lead_coeff g mod p) p" by simp
    also have "lead_coeff g mod p = 0"
      using M_def g0 by simp
    finally show False using p
      apply simp
        unfolding prime_int_iff
      by (simp add: prime_int_iff)
  qed
qed

lemma square_free_impl: assumes 
  p: "prime p"
  shows "square_free_impl p f \<Longrightarrow> poly_mod.square_free_m p f"
    "nat p > poly_mod.degree_m p f \<Longrightarrow> nat p > square_free_bound f \<Longrightarrow> square_free f 
    \<Longrightarrow> square_free_impl p f" 
proof -
  show one: "square_free_impl p f \<Longrightarrow> poly_mod.square_free_m p f" and
    "nat p > poly_mod.degree_m p f \<Longrightarrow> nat p > square_free_bound f \<Longrightarrow> square_free f 
    \<Longrightarrow> square_free_impl p f"
    using square_free_impl_int[OF p refl, of f] square_free_impl_uint32[OF p refl, of f]
    unfolding square_free_impl_def by (auto split: if_splits)
qed
  

lemma coprime_lead_coeff_large_prime: assumes prime: "prime (p :: int)" 
  and large: "p > abs (lead_coeff f)" 
  and f: "f \<noteq> 0" 
  shows "coprime (lead_coeff f) p"
proof -
  {
    fix lc 
    assume assms:"0 < lc" "lc < p" 
    from prime have "coprime lc p" 
      by (metis (no_types) assms gcd.commute prime_imp_coprime zdvd_not_zless)
  } note main = this
  define lc where "lc = lead_coeff f" 
  from f have lc0: "lc \<noteq> 0" unfolding lc_def by auto
  from large have large: "p > abs lc" unfolding lc_def by auto
  have "coprime lc p" 
  proof (cases "lc > 0")
    case True
    from large have "p > lc" by auto
    from main[OF True this] show ?thesis .
  next
    case False
    let ?mlc = "- lc" 
    from large False lc0 have "?mlc > 0" "p > ?mlc" by auto
    from main[OF this] show ?thesis by simp
  qed
  thus ?thesis unfolding lc_def by auto
qed

lemma prime_for_berlekamp_zassenhaus_exists: assumes sf: "square_free f" 
  shows "\<exists> p. prime p \<and> (coprime (lead_coeff f) p \<and> square_free_impl p f)"
proof (rule ccontr)
  from assms have f0: "f \<noteq> 0" unfolding square_free_def by auto
  define n where "n = max (max (abs (lead_coeff f)) (degree f)) (square_free_bound f)" 
  assume contr: "\<not> ?thesis"
  {
    fix p :: int
    let ?ops = "finite_field_ops p" 
    interpret poly_mod p .
    assume prime: "prime p" and n: "p > n" 
    from n have large: "p > abs (lead_coeff f)" "nat p > degree f" "nat p > square_free_bound f" 
      unfolding n_def by auto
    from coprime_lead_coeff_large_prime[OF prime large(1) f0]
    have cop: "coprime (lead_coeff f) p" by auto
    with prime contr have nsf: "\<not> square_free_impl p f" by auto
    from large(2) have "nat p > degree_m f" using degree_m_le[of f] by auto
    from square_free_impl(2)[OF prime this large(3) sf] nsf have False by auto
  }
  hence no_large_prime: "\<And> p. prime p \<Longrightarrow> p > n \<Longrightarrow> False" by auto
  from bigger_prime[of "nat n"] obtain p where *: "prime p" "p > nat n" by auto
  define q where "q \<equiv> int p" 
  from * have "prime q" "q > n" unfolding q_def by auto
  from no_large_prime[OF this]
  show False .
qed

definition next_primes :: "nat \<Rightarrow> nat \<times> nat list" where
  "next_primes n = (if n = 0 then next_candidates 0 else 
    let (m,ps) = next_candidates n in (m,filter prime ps))"

partial_function (tailrec) find_prime_main :: 
  "(nat \<Rightarrow> bool) \<Rightarrow> nat \<Rightarrow> nat list \<Rightarrow> nat" where
  [code]: "find_prime_main f np ps = (case ps of [] \<Rightarrow> 
    let (np',ps') = next_primes np
      in find_prime_main f np' ps'
    | (p # ps) \<Rightarrow> if f p then p else find_prime_main f np ps)" 
  
definition find_prime :: "(nat \<Rightarrow> bool) \<Rightarrow> nat" where
  "find_prime f = find_prime_main f 0 []"
  

lemma next_primes: assumes res: "next_primes n = (m,ps)"
  and n: "candidate_invariant n"
  shows "candidate_invariant m" "sorted ps" "distinct ps" "n < m" 
  "set ps = {i. prime i \<and> n \<le> i \<and> i < m}" 
proof -
  have "candidate_invariant m \<and> sorted ps \<and> distinct ps \<and> n < m \<and>
    set ps = {i. prime i \<and> n \<le> i \<and> i < m}"
  proof (cases "n = 0")
    case True    
    with res[unfolded next_primes_def] have nc: "next_candidates 0 = (m,ps)" by auto
    from this[unfolded next_candidates_def] have ps: "ps = primes_1000" and m: "m = 1001" by auto
    have ps: "set ps = {i. prime i \<and> n \<le> i \<and> i < m}" unfolding m True ps 
      by (auto simp: primes_1000)
    with next_candidates[OF nc n[unfolded True]] True
    show ?thesis by simp
  next
    case False
    with res[unfolded next_primes_def Let_def] obtain qs where nc: "next_candidates n = (m, qs)"
      and ps: "ps = filter prime qs" by (cases "next_candidates n", auto)
    have "sorted qs \<Longrightarrow> sorted ps" unfolding ps using sorted_filter[of id qs prime] by auto
    with next_candidates[OF nc n] show ?thesis unfolding ps by auto
  qed
  thus "candidate_invariant m" "sorted ps" "distinct ps" "n < m" 
    "set ps = {i. prime i \<and> n \<le> i \<and> i < m}" by auto
qed

lemma find_prime: assumes "\<exists> n. prime n \<and> f n"
  shows "prime (find_prime f) \<and> f (find_prime f)" 
proof -
  from assms obtain n where fn: "prime n" "f n" by auto
  {
    fix i ps m
    assume "candidate_invariant i" 
      and "n \<in> set ps \<or> n \<ge> i"
      and "m = (Suc n - i, length ps)"
      and "\<And> p. p \<in> set ps \<Longrightarrow> prime p" 
    hence "prime (find_prime_main f i ps) \<and> f (find_prime_main f i ps)"
    proof (induct m arbitrary: i ps rule: wf_induct[OF wf_measures[of "[fst, snd]"]])
      case (1 m i ps)
      note IH = 1(1)[rule_format]
      note can = 1(2)
      note n = 1(3)
      note m = 1(4)
      note ps = 1(5)
      note simps [simp] = find_prime_main.simps[of f i ps]
      show ?case 
      proof (cases ps)
        case Nil
        with n have i_n: "i \<le> n" by auto
        obtain j qs where np: "next_primes i = (j,qs)" by force
        note j = next_primes[OF np can]
        from j(4) i_n m have meas: "((Suc n - j, length qs), m) \<in> measures [fst, snd]" by auto 
        have n: "n \<in> set qs \<or> j \<le> n" unfolding j(5) using i_n fn by auto
        show ?thesis unfolding simps using IH[OF meas j(1) n refl] j(5) by (simp add: Nil np)
      next
        case (Cons p qs)
        show ?thesis
        proof (cases "f p")
          case True
          thus ?thesis unfolding simps using ps unfolding Cons by simp
        next
          case False
          have m: "((Suc n - i, length qs), m) \<in> measures [fst, snd]" using m unfolding Cons by simp
          have n: "n \<in> set qs \<or> i \<le> n" using False n fn by (auto simp: Cons)
          from IH[OF m can n refl ps]
          show ?thesis unfolding simps using Cons False by simp
        qed
      qed
    qed
  } note main = this
  have "candidate_invariant 0" by (simp add: candidate_invariant_def)
  from main[OF this _ refl, of Nil] show ?thesis unfolding find_prime_def by auto
qed 

definition suitable_prime_bz :: "int poly \<Rightarrow> int" where
  "suitable_prime_bz f \<equiv> let lc = lead_coeff f in int (find_prime (\<lambda> n. let p = int n in 
       coprime lc p \<and> square_free_impl p f))"
  
lemma suitable_prime_bz: assumes sf: "square_free f" and p: "p = suitable_prime_bz f" 
  shows "prime p" "coprime (lead_coeff f) p" 
    "poly_mod.square_free_m p f"
proof -
  let ?lc = "lead_coeff f" 
  from prime_for_berlekamp_zassenhaus_exists[OF sf, unfolded Let_def]
  obtain P where *: "prime P \<and> coprime ?lc P \<and> square_free_impl P f" 
    by auto
  hence "prime (nat P)" using prime_int_nat_transfer by blast
  with * have "\<exists> p. prime p \<and> coprime ?lc (int p) \<and> square_free_impl p f"
    by (intro exI[of _ "nat P"], auto)
  from find_prime[OF this]
  have prime: "prime p" and cop: "coprime ?lc p" 
    and sf: "square_free_impl p f" 
    unfolding p suitable_prime_bz_def Let_def by auto
  with square_free_impl(1)[OF prime sf]
  show "prime p" "coprime ?lc p" "poly_mod.square_free_m p f" by auto  
qed

definition square_free_heuristic :: "int poly \<Rightarrow> int option" where
  "square_free_heuristic f = (let lc = lead_coeff f in 
    find (\<lambda> p. coprime lc p \<and> square_free_impl p f) [2, 3, 5, 7, 11, 13, 17, 19, 23])" 

lemma find_Some_D: "find f xs = Some y \<Longrightarrow> y \<in> set xs \<and> f y" unfolding find_Some_iff by auto
  
lemma square_free_heuristic: assumes "square_free_heuristic f = Some p" 
  shows "coprime (lead_coeff f) p \<and> square_free_impl p f \<and> prime p" 
proof -
  from find_Some_D[OF assms[unfolded square_free_heuristic_def Let_def]]
  show ?thesis by auto
qed
 
end
