section {* Explore and Enumerate Nodes of Büchi Automata *}

theory BA_Translate
imports BA_Explicit
begin

  subsection {* Syntax *}

  (* TODO: this syntax has unnecessarily high inner binding strength, requiring extra parentheses
    the regular let syntax correctly uses inner binding strength 0: ("(2_ =/ _)" 10) *)
  no_syntax "_do_let" :: "[pttrn, 'a] \<Rightarrow> do_bind" ("(2let _ =/ _)" [1000, 13] 13)
  syntax "_do_let" :: "[pttrn, 'a] \<Rightarrow> do_bind" ("(2let _ =/ _)" 13)

  section {* Image on Explicit Automata *}

  definition bae_image where "bae_image f A \<equiv> \<lparr> alphabete = alphabete A, initiale = f ` initiale A,
    transe = (\<lambda> (p, a, q). (f p, a, f q)) ` transe A, acceptinge = f ` acceptinge A, \<dots> = bae.more A \<rparr>"

  lemma bae_image_param[param]: "(bae_image, bae_image) \<in> (S \<rightarrow> T) \<rightarrow> \<langle>L, S, M\<rangle> bae_rel \<rightarrow> \<langle>L, T, M\<rangle> bae_rel"
    unfolding bae_image_def by parametricity

  lemma bae_image_id[simp]: "bae_image id = id" unfolding bae_image_def by auto
  lemma bae_image_ba_bae: "bae_image f (ba_bae A) = \<lparr>
    alphabete = alphabet A,
    initiale = f ` initial A,
    transe = (\<Union> p \<in> nodes A. \<Union> a \<in> alphabet A. f ` {p} \<times> {a} \<times> f ` succ A a p),
    acceptinge = f ` {p \<in> nodes A. accepting A p},
    \<dots> = ba.more A \<rparr>"
    unfolding ba_bae_def bae_image_def bae.simps Set.filter_def by force

  section {* Exploration and Translation *}

  definition to_baei :: "('state, 'label, 'more) ba_scheme \<Rightarrow> ('state, 'label, 'more) ba_scheme"
    where "to_baei \<equiv> id"

  (* TODO: generalize L *)
  (* TODO: make separate implementations for "ba_bae" and "op_set_enumerate \<bind> bae_image" *)
  schematic_goal to_baei_impl:
    fixes S :: "('statei \<times> 'state) set"
    assumes [simp]: "finite (nodes A)"
    assumes [autoref_ga_rules]: "is_bounded_hashcode S seq bhc"
    assumes [autoref_ga_rules]: "is_valid_def_hm_size TYPE('statei) hms"
    assumes [autoref_rules]: "(seq, HOL.eq) \<in> S \<rightarrow> S \<rightarrow> bool_rel"
    assumes [autoref_rules]: "(Ai, A) \<in> \<langle>Id, S, M\<rangle> bai_ba_rel"
    shows "(?f :: ?'a, do {
        let N = nodes A;
        f \<leftarrow> op_set_enumerate N;
        ASSERT (dom f = N);
        ASSERT (\<forall> p \<in> initial A. f p \<noteq> None);
        ASSERT (\<forall> p \<in> dom f. \<forall> a \<in> alphabet A. \<forall> q \<in> succ A a p. f q \<noteq> None);
        RETURN \<lparr> alphabete = alphabet A, initiale = (\<lambda> x. the (f x)) ` initial A,
          transe = \<Union> p \<in> N. \<Union> a \<in> alphabet A. (\<lambda> x. the (f x)) ` {p} \<times> {a} \<times>
          (\<lambda> x. the (f x)) ` succ A a p,
          acceptinge = (\<lambda> x. the (f x)) ` {p \<in> N. accepting A p}, \<dots> = ba.more A \<rparr>
      }) \<in> ?R"
    by autoref
  concrete_definition to_baei_impl uses to_baei_impl[unfolded bind_to_let_conv push_in_let_conv]
  lemma to_baei_impl_refine'':
    fixes S :: "('statei \<times> 'state) set"
    assumes "finite (nodes A)"
    assumes "is_bounded_hashcode S seq bhc"
    assumes "is_valid_def_hm_size TYPE('statei) hms"
    assumes "(seq, HOL.eq) \<in> S \<rightarrow> S \<rightarrow> bool_rel"
    assumes "(Ai, A) \<in> \<langle>Id, S, M\<rangle> bai_ba_rel"
    shows "(RETURN (to_baei_impl seq bhc hms Ai), do {
        f \<leftarrow> op_set_enumerate (nodes A);
        RETURN (bae_image (the \<circ> f) (ba_bae A))
      }) \<in> \<langle>\<langle>Id, nat_rel, M\<rangle> baei_bae_rel\<rangle> nres_rel"
  proof -
    note to_baei_impl.refine[OF assms]
    also have "(do {
        let N = nodes A;
        f \<leftarrow> op_set_enumerate N;
        ASSERT (dom f = N);
        ASSERT (\<forall> p \<in> initial A. f p \<noteq> None);
        ASSERT (\<forall> p \<in> dom f. \<forall> a \<in> alphabet A. \<forall> q \<in> succ A a p. f q \<noteq> None);
        RETURN \<lparr> alphabete = alphabet A, initiale = (\<lambda>x. the (f x)) ` initial A,
          transe = \<Union> p \<in> N. \<Union> a \<in> alphabet A. (\<lambda>x. the (f x)) ` {p} \<times> {a} \<times>
          (\<lambda>x. the (f x)) ` succ A a p,
          acceptinge = (\<lambda>x. the (f x)) ` {p \<in> N. accepting A p}, \<dots> = ba.more A \<rparr>
      },  do {
        f \<leftarrow> op_set_enumerate (nodes A);
        RETURN (bae_image (the \<circ> f) (ba_bae A))
      }) \<in> \<langle>Id\<rangle> nres_rel"
      unfolding Let_def bae_image_ba_bae comp_apply op_set_enumerate_def by refine_vcg auto
    finally show ?thesis unfolding nres_rel_comp by simp
  qed

  context
    fixes Ai A
    fixes seq bhc hms
    fixes S :: "('statei \<times> 'state) set"
    fixes M
    assumes a: "finite (nodes A)"
    assumes b: "is_bounded_hashcode S seq bhc"
    assumes c: "is_valid_def_hm_size TYPE('statei) hms"
    assumes d: "(seq, HOL.eq) \<in> S \<rightarrow> S \<rightarrow> bool_rel"
    assumes e: "(Ai, A) \<in> \<langle>Id, S, M\<rangle> bai_ba_rel"
  begin

    definition f' where "f' \<equiv> SOME f'.
      (to_baei_impl seq bhc hms Ai, bae_image (the \<circ> f') (ba_bae A)) \<in> \<langle>Id, nat_rel, M\<rangle> baei_bae_rel \<and>
      dom f' = nodes A \<and> inj_on f' (nodes A)"

    lemma 1: "\<exists> f'. (to_baei_impl seq bhc hms Ai, bae_image (the \<circ> f') (ba_bae A)) \<in>
      \<langle>Id, nat_rel, M\<rangle> baei_bae_rel \<and> dom f' = nodes A \<and> inj_on f' (nodes A)"
      using to_baei_impl_refine''[
        OF a b c d e,
        unfolded op_set_enumerate_def bind_RES_RETURN_eq,
        THEN nres_relD,
        THEN RETURN_ref_SPECD]
      by force

    lemma f'_refine: "(to_baei_impl seq bhc hms Ai, bae_image (the \<circ> f') (ba_bae A)) \<in>
      \<langle>Id, nat_rel, M\<rangle> baei_bae_rel" using someI_ex[OF 1, folded f'_def] by auto
    lemma f'_dom: "dom f' = nodes A" using someI_ex[OF 1, folded f'_def] by auto
    lemma f'_inj: "inj_on f' (nodes A)" using someI_ex[OF 1, folded f'_def] by auto

    definition f where "f \<equiv> the \<circ> f'"
    definition g where "g = inv_into (nodes A) f"
    lemma inj_f[intro!, simp]: "inj_on f (nodes A)"
      using f'_inj f'_dom unfolding f_def by (simp add: inj_on_map_the)
    lemma inj_g[intro!, simp]: "inj_on g (f ` nodes A)"
      unfolding g_def by (simp add: inj_on_inv_into)

    definition rel where "rel \<equiv> {(f p, p) |p. p \<in> nodes A}"
    lemma rel_alt_def: "rel = (br f (\<lambda> p. p \<in> nodes A))\<inverse>"
      unfolding rel_def by (auto simp: in_br_conv)
    lemma rel_inv_def: "rel = br g (\<lambda> k. k \<in> f ` nodes A)"
      unfolding rel_alt_def g_def by (auto simp: in_br_conv)
    lemma rel_domain[simp]: "Domain rel = f ` nodes A" unfolding rel_def by force
    lemma rel_range[simp]: "Range rel = nodes A" unfolding rel_def by auto
    lemma [intro!, simp]: "bijective rel" unfolding rel_inv_def by (simp add: bijective_alt)
    lemma [simp]: "Id_on (f ` nodes A) O rel = rel" unfolding rel_def by auto
    lemma [simp]: "rel O Id_on (nodes A) = rel" unfolding rel_def by auto

    lemma [param]: "(f, f) \<in> Id_on (Range rel) \<rightarrow> Id_on (Domain rel)" unfolding rel_alt_def by auto
    lemma [param]: "(g, g) \<in> Id_on (Domain rel) \<rightarrow> Id_on (Range rel)" unfolding rel_inv_def by auto
    lemma [param]: "(id, f) \<in> rel \<rightarrow> Id_on (Domain rel)" unfolding rel_alt_def by (auto simp: in_br_conv)
    lemma [param]: "(f, id) \<in> Id_on (Range rel) \<rightarrow> rel" unfolding rel_alt_def by (auto simp: in_br_conv)
    lemma [param]: "(id, g) \<in> Id_on (Domain rel) \<rightarrow> rel" unfolding rel_inv_def by (auto simp: in_br_conv)
    lemma [param]: "(g, id) \<in> rel \<rightarrow> Id_on (Range rel)" unfolding rel_inv_def by (auto simp: in_br_conv)

    lemma to_baei_impl_refine':
      "(to_baei_impl seq bhc hms Ai, to_baei A) \<in> \<langle>Id_on (alphabet A), rel, M\<rangle> baei_ba_rel"
    proof -
      have "(bae_ba (bae (to_baei_impl seq bhc hms Ai)), bae_ba (id (bae_image f (ba_bae A)))) \<in>
        \<langle>Id, nat_rel, M\<rangle> ba_rel" using f'_refine[folded f_def] by parametricity auto
      also have "(bae_ba (id (bae_image f (ba_bae A))), bae_ba (id (bae_image id (ba_bae A)))) \<in>
        \<langle>Id_on (alphabet A), rel, Id\<rangle> ba_rel" using ba_rel_eq by parametricity auto
      also have "bae_ba (id (bae_image id (ba_bae A))) = (bae_ba \<circ> ba_bae) A" by simp
      also have "(\<dots>, id A) \<in> \<langle>Id_on (alphabet A), Id_on (nodes A), Id\<rangle> ba_rel" by parametricity
      also have "id A = to_baei A" unfolding to_baei_def by simp
      finally show ?thesis unfolding baei_ba_rel_def by simp
    qed

  end

  context
  begin

    interpretation autoref_syn by this

    lemma to_baei_impl_refine[autoref_rules]:
      fixes S :: "('statei \<times> 'state) set"
      assumes "SIDE_PRECOND (finite (nodes A))"
      assumes "SIDE_GEN_ALGO (is_bounded_hashcode S seq bhc)"
      assumes "SIDE_GEN_ALGO (is_valid_def_hm_size TYPE('statei) hms)"
      assumes "GEN_OP seq HOL.eq (S \<rightarrow> S \<rightarrow> bool_rel)"
      assumes "(Ai, A) \<in> \<langle>Id, S, M\<rangle> bai_ba_rel"
      shows "(to_baei_impl seq bhc hms Ai,
        (OP to_baei ::: \<langle>Id, S, M\<rangle> bai_ba_rel \<rightarrow>
        \<langle>Id_on (alphabet A), rel Ai A seq bhc hms M, M\<rangle> baei_ba_rel) $ A) \<in>
        \<langle>Id_on (alphabet A), rel Ai A seq bhc hms M, M\<rangle> baei_ba_rel"
      using to_baei_impl_refine' assms unfolding autoref_tag_defs by this

  end

end