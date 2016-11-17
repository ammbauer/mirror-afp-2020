(*
    Authors:      Jose Divasón
                  Sebastiaan Joosten
                  René Thiemann
                  Akihisa Yamada
*)
subsection \<open>A fast coprimality approximation\<close>

text \<open>We adapt the integer polynomial gcd algorithm so that it 
  first tests whether $f$ and $g$ are coprime modulo a few primes.
  If so, we are immediately done.\<close>

theory Gcd_Finite_Field_Impl
imports 
  Suitable_Prime 
  Hensel_Lifting (* for poly_mod_prime *)
  Code_Abort_Gcd
begin

definition coprime_approx_main :: "int \<Rightarrow> 'i arith_ops_record \<Rightarrow> int poly \<Rightarrow> int poly \<Rightarrow> bool" where
  "coprime_approx_main p ff_ops f g = (gcd_poly_i ff_ops (of_int_poly_i ff_ops (poly_mod.Mp p f))
     (of_int_poly_i ff_ops (poly_mod.Mp p g)) = one_poly_i ff_ops)" 

lemma (in prime_field_gen) coprime_approx_main: 
  assumes F: "(F :: 'a mod_ring poly) = of_int_poly (Mp f)"
    and G: "(G :: 'a mod_ring poly) = of_int_poly (Mp g)"
  shows "coprime_approx_main p ff_ops f g \<Longrightarrow> coprime_m f g" 
proof -
  let ?f' = "of_int_poly_i ff_ops (Mp f)" 
  let ?g' = "of_int_poly_i ff_ops (Mp g)" 
  define f'' where "f'' \<equiv> of_int_poly (Mp f) :: 'a mod_ring poly"
  define g'' where "g'' \<equiv> of_int_poly (Mp g) :: 'a mod_ring poly"
  have rel_f[transfer_rule]: "poly_rel ?f' f''" 
    by (rule poly_rel_coeffs_Mp_of_int_poly[OF refl], simp add: f''_def)
  have rel_f[transfer_rule]: "poly_rel ?g' g''" 
    by (rule poly_rel_coeffs_Mp_of_int_poly[OF refl], simp add: g''_def)
  have id: "(gcd_poly_i ff_ops (of_int_poly_i ff_ops (Mp f)) (of_int_poly_i ff_ops (Mp g)) = one_poly_i ff_ops)
    = coprime f'' g''"
    unfolding square_free_i_def by transfer_prover
  have fF: "MP_Rel (Mp f) F" unfolding F MP_Rel_def
    by (simp add: Mp_f_representative)
  have gG: "MP_Rel (Mp g) G" unfolding G MP_Rel_def
    by (simp add: Mp_f_representative)
  have "coprime f'' g'' = coprime F G" unfolding f''_def F g''_def G by simp
  also have "\<dots> = coprime_m (Mp f) (Mp g)"
    using coprime_MP_Rel[unfolded rel_fun_def, rule_format, OF fF gG] by simp
  also have "\<dots> = coprime_m f g" unfolding coprime_m_def dvdm_def equivalent_def by simp
  finally have id2: "coprime f'' g'' = coprime_m f g" .
  show "coprime_approx_main p ff_ops f g \<Longrightarrow> coprime_m f g" unfolding coprime_approx_main_def
    id id2 by auto
qed

lemma coprime_approx_main_uint32: assumes 
  p: "prime p" and
  res: "coprime_approx_main p (finite_field_ops32 (uint32_of_int p)) f g" and
  small: "p \<le> 65535"     
  shows "poly_mod.coprime_m p f g"
proof -
  have ne: "{0..<p} \<noteq> {}" using prime_ge_2_int[OF p] by auto
  {
    assume "\<exists>(Rep :: 'b \<Rightarrow> int) Abs. type_definition Rep Abs {0 ..< p :: int}"
    from prime_type_prime_card[OF p this]
    have "class.prime_card TYPE('b)" and p: "p = int CARD('b)" by auto
    from prime_field_gen.coprime_approx_main[OF 
        prime_field.prime_field_finite_field_ops32, unfolded prime_field_def mod_ring_locale_def,
      internalize_sort "'a :: prime_card", OF this small refl refl res]
    have ?thesis .
  }
  from this[cancel_type_definition, OF ne] show ?thesis .
qed


lemma coprime_mod_imp_coprime: assumes 
  p: "prime p" and 
  cop_m: "poly_mod.coprime_m p f g" and 
  cop: "coprime (lead_coeff f) p \<or> coprime (lead_coeff g) p" and
  cnt: "content f = 1 \<or> content g = 1" 
  shows "coprime f g"
proof -
  interpret poly_mod_prime p by (standard, rule p)
  from cop_m[unfolded coprime_m_def] have cop_m: "\<And> h. dvdm h f \<Longrightarrow> dvdm h g \<Longrightarrow> dvdm h 1"  by auto
  show ?thesis 
  proof (rule coprimeI)
    fix h
    assume dvd: "h dvd f" "h dvd g" 
    hence "dvdm h f" "dvdm h g" unfolding dvdm_def equivalent_def dvd_def by auto
    from cop_m[OF this] obtain k where unit: "Mp (h * Mp k) = 1" unfolding dvdm_def equivalent_def by auto
    from content_dvd_1[of _ h] dvd cnt have cnt: "content h = 1" by auto 
    let ?k = "Mp k" 
    from unit have h0: "h \<noteq> 0" by auto
    from unit have k0: "?k \<noteq> 0" by fastforce
    from p have p0: "p \<noteq> 0" by auto
    from dvd have "lead_coeff h dvd lead_coeff f" "lead_coeff h dvd lead_coeff g" 
      by (metis dvd_def lead_coeff_mult)+
    with cop have coph: "coprime (lead_coeff h) p" by (metis coprime_divisors dvd_def mult.right_neutral)
    let ?k = "Mp k"  
    from arg_cong[OF unit, of degree] have degm0: "degree_m (h * ?k) = 0" unfolding degree_m_def by simp
    have "lead_coeff ?k \<in> {0 ..< p}" unfolding lead_coeff_def Mp_coeff M_def using m1 by simp
    with k0 have lk: "lead_coeff ?k \<ge> 1" "lead_coeff ?k < p"
      by (auto simp add: int_one_le_iff_zero_less order.not_eq_order_implies_strict)
    have id: "lead_coeff (h * ?k) = lead_coeff h * lead_coeff ?k" unfolding lead_coeff_mult ..
    have "coprime (lead_coeff h * lead_coeff ?k) p" 
    proof (cases "lead_coeff ?k = 1")
      case True thus ?thesis using coph by auto
    next
      case False 
      with lk have "coprime (lead_coeff ?k) p"
        by (simp add: gcd.commute int_one_le_iff_zero_less prime prime_imp_coprime zdvd_not_zless)
      with coph show ?thesis by (simp add: gcd_mult_cancel)
    qed    
    with id have cop_prod: "coprime (lead_coeff (h * ?k)) p" by simp
    from h0 k0 have lc0: "lead_coeff (h * ?k) \<noteq> 0" unfolding lead_coeff_mult by auto
    from cop_prod[unfolded gcd_non_0[OF p0]] have lcp: "lead_coeff (h * ?k) mod p \<noteq> 0" using p
      by (metis M_def gcd_mod2 inverse_mod_coprime mod_mult_self1_is_0 mod_self mult.commute zero_neq_one)
    have deg_eq: "degree_m (h * ?k) = degree (h * Mp k)" 
      by (rule degree_m_eq[OF _ m1], unfold lead_coeff_def[symmetric], insert lcp)
    from this[unfolded degm0] have "degree (h * Mp k) = 0" by simp
    with degree_mult_eq[OF h0 k0] have deg0: "degree h = 0" by auto
    from degree0_coeffs[OF this] obtain h0 where h: "h = [:h0:]" by auto
    have "content h = abs h0" unfolding content_def h by (cases "h0 = 0", auto simp: list_gcd_def)
    hence "abs h0 = 1" using cnt by auto
    hence "h0 \<in> {-1,1}" by auto
    hence "h = 1 \<or> h = -1" unfolding h by (auto)
    thus "is_unit h" by auto
  qed
qed

text \<open>We have did not try to optimize the set of chosen primes. They have just been picked 
  randomly from a list of primes.\<close>

definition gcd_primes :: "int list" where
  "gcd_primes = [383, 467, 811, 983, 997]" 
  
lemma gcd_primes: "p \<in> set (gcd_primes) \<Longrightarrow> prime p \<and> p \<le> 65535" 
proof -
  have "list_all (\<lambda> p. prime p \<and> p \<le> 65535) gcd_primes" by eval
  thus "p \<in> set (gcd_primes) \<Longrightarrow> prime p \<and> p \<le> 65535" by (auto simp: list_all_iff)
qed

definition coprime_heuristic :: "int poly \<Rightarrow> int poly \<Rightarrow> bool" where
  "coprime_heuristic f g = (let lcf = lead_coeff f; lcg = lead_coeff g in 
    find (\<lambda> p. (coprime lcf p \<or> coprime lcg p) \<and> coprime_approx_main p (finite_field_ops32 (uint32_of_int p)) f g) 
    gcd_primes \<noteq> None)" 

lemma coprime_heuristic: assumes "coprime_heuristic f g" 
  and "content f = 1 \<or> content g = 1" 
  shows "coprime f g" 
proof (cases "find (\<lambda>p. (coprime (lead_coeff f) p \<or> coprime (lead_coeff g) p) \<and>
            coprime_approx_main p (finite_field_ops32 (uint32_of_int p)) f g)
   gcd_primes")
  case (Some p)
  from find_Some_D[OF Some] gcd_primes have p: "prime p" and small: "p \<le> 65535" 
    and cop: "coprime (lead_coeff f) p \<or> coprime (lead_coeff g) p" 
    and copp: "coprime_approx_main p (finite_field_ops32 (uint32_of_int p)) f g" by auto
  from coprime_approx_main_uint32[OF p copp small] have "poly_mod.coprime_m p f g" by auto
  from coprime_mod_imp_coprime[OF p this cop assms(2)] show "coprime f g" .
qed (insert assms(1)[unfolded coprime_heuristic_def], auto simp: Let_def)

definition gcd_int_poly :: "int poly \<Rightarrow> int poly \<Rightarrow> int poly" where
  "gcd_int_poly f g =
    (if f = 0 then normalize g
     else if g = 0 then normalize f
          else let ct = gcd (Polynomial_Factorial.content f) (Polynomial_Factorial.content g);
            ff = primitive_part f; 
            gg = primitive_part g
          in if coprime_heuristic ff gg then [:ct:] else smult ct (gcd_poly_code_aux ff gg))" 
  
lemma content_same: "Polynomial_Factorial.content f = content f"
proof -
  obtain xs where id: "coeffs f = xs" by auto
  show ?thesis unfolding Polynomial_Factorial.content_def content_def id list_gcd_def
    by (induct xs, auto)
qed
  
lemma gcd_int_poly_code[code_unfold]: "gcd = gcd_int_poly" 
proof (intro ext)
  fix f g :: "int poly"
  let ?ff = "primitive_part f" 
  let ?gg = "primitive_part g" 
  note d = gcd_int_poly_def gcd_poly_code gcd_poly_code_def
  show "gcd f g = gcd_int_poly f g" 
  proof (cases "f = 0 \<or> g = 0 \<or> \<not> coprime_heuristic ?ff ?gg")
    case True
    thus ?thesis unfolding d by auto
  next
    case False
    hence cop: "coprime_heuristic ?ff ?gg" by simp
    from False have "f \<noteq> 0" by auto
    from content_primitive_part[OF this] have cnt: "content ?ff = 1" unfolding content_same .
    have id: "coprime ?ff ?gg" 
      by (rule coprime_heuristic[OF cop], insert cnt, auto)
    show ?thesis unfolding gcd_poly_decompose[of f g] unfolding gcd_int_poly_def Let_def id
      using False by auto
  qed
qed

end