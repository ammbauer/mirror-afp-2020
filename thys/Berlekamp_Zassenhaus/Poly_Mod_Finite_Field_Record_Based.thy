(*
    Authors:      Jose Divasón
                  Sebastiaan Joosten
                  René Thiemann
                  Akihisa Yamada
*)
subsubsection \<open>Over a Finite Field\<close>
theory Poly_Mod_Finite_Field_Record_Based
imports
  Poly_Mod_Finite_Field
  Finite_Field_Record_Based
  Polynomial_Record_Based
begin

lemma prime_type_prime_card: assumes p: "prime p" 
  and "\<exists>(Rep :: 'a \<Rightarrow> int) Abs. type_definition Rep Abs {0 ..< p :: int}"
  shows "class.prime_card (TYPE('a)) \<and> int CARD('a) = p"
proof -
  from p have p2: "p \<ge> 2" by (rule prime_ge_2_int)
  from assms obtain rep :: "'a \<Rightarrow> int" and abs :: "int \<Rightarrow> 'a" where t: "type_definition rep abs {0 ..< p}" by auto
  have "card (UNIV :: 'a set) = card {0 ..< p}" using t by (rule type_definition.card)
  also have "\<dots> = p" using p2 by auto
  finally have bn: "int CARD ('a) = p" .
  hence "class.prime_card (TYPE('a))" unfolding class.prime_card_def
    using p p2 by auto
  with bn show ?thesis by blast
qed

definition of_int_poly_i :: "'i arith_ops_record \<Rightarrow> int poly \<Rightarrow> 'i list" where
  "of_int_poly_i ops f = map (arith_ops_record.of_int ops) (coeffs f)" 

definition to_int_poly_i :: "'i arith_ops_record \<Rightarrow> 'i list \<Rightarrow> int poly" where
  "to_int_poly_i ops f = poly_of_list (map (arith_ops_record.to_int ops) f)" 

locale prime_field_gen = field_ops ff_ops R for ff_ops :: "'i arith_ops_record" and
  R :: "'i \<Rightarrow> 'a :: prime_card mod_ring \<Rightarrow> bool" +
  fixes p :: int 
  assumes p: "p = int CARD('a)"
  and of_int: "0 \<le> x \<Longrightarrow> x < p \<Longrightarrow> R (arith_ops_record.of_int ff_ops x) (of_int x)" 
  and to_int: "R y z \<Longrightarrow> arith_ops_record.to_int ff_ops y = to_int_mod_ring z" 
begin

lemma nat_p: "nat p = CARD('a)" unfolding p by simp

sublocale poly_mod_type p "TYPE('a)"
  by (unfold_locales, rule p)

notation equivalent (infixl "=m" 50)

lemma coeffs_to_int_poly: "coeffs (to_int_poly (x :: 'a mod_ring poly)) = map to_int_mod_ring (coeffs x)" 
  by (rule coeffs_map_poly, auto)

lemma coeffs_of_int_poly: "coeffs (of_int_poly (Mp x) :: 'a mod_ring poly) = map of_int (coeffs (Mp x))" 
proof (rule coeffs_map_poly)
  fix y
  assume "y \<in> range (coeff (Mp x))" 
  then obtain i where y: "y = coeff (Mp x) i" by auto
  from this[unfolded Mp_coeff]
  show "(of_int y = (0 :: 'a mod_ring)) = (y = 0)"
    using M_0 M_def mod_mod_trivial of_int_mod_ring.rep_eq of_int_mod_ring_0 p by (metis of_int_of_int_mod_ring)
qed

lemma to_int_poly_i: assumes "poly_rel f g" shows "to_int_poly_i ff_ops f = to_int_poly g"
proof -
  have *: "map (arith_ops_record.to_int ff_ops) f = coeffs (to_int_poly g)"
    unfolding coeffs_to_int_poly 
    by (rule nth_equalityI, insert assms, auto simp: list_all2_conv_all_nth poly_rel_def to_int)
  show ?thesis unfolding to_int_poly_i_def poly_of_list_def coeffs_eq_iff coeffs_Poly * by simp
qed

lemma poly_rel_coeffs_Mp_of_int_poly: assumes id: "f' = of_int_poly_i ff_ops (Mp f)" "f'' = of_int_poly (Mp f)" 
  shows "poly_rel f' f''" unfolding id poly_rel_def
  unfolding list_all2_conv_all_nth coeffs_of_int_poly of_int_poly_i_def length_map
  by (rule conjI[OF refl], intro allI impI, simp add: nth_coeffs_coeff Mp_coeff M_def, rule of_int,
    insert p, auto)

end

context prime_field
begin
lemma prime_field_finite_field_ops: "prime_field_gen (finite_field_ops p) mod_ring_rel p" 
proof -
  interpret field_ops "finite_field_ops p" mod_ring_rel by (rule finite_field_ops)
  show ?thesis
    by (unfold_locales, rule p, 
      auto simp: finite_field_ops_def p mod_ring_rel_def of_int_of_int_mod_ring)
qed
end

end
