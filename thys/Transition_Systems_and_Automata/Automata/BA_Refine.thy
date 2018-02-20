section {* Relations on Büchi Automata *}

theory BA_Refine
imports
  "BA"
  "../Transition_Systems/Transition_System_Refine"
begin

  definition ba_rel :: "('label\<^sub>1 \<times> 'label\<^sub>2) set \<Rightarrow> ('state\<^sub>1 \<times> 'state\<^sub>2) set \<Rightarrow> ('more\<^sub>1 \<times> 'more\<^sub>2) set \<Rightarrow>
    (('label\<^sub>1, 'state\<^sub>1, 'more\<^sub>1) ba_scheme \<times> ('label\<^sub>2, 'state\<^sub>2, 'more\<^sub>2) ba_scheme) set" where
    [to_relAPP]: "ba_rel L S M \<equiv> {(A\<^sub>1, A\<^sub>2).
      (alphabet A\<^sub>1, alphabet A\<^sub>2) \<in> \<langle>L\<rangle> set_rel \<and>
      (initial A\<^sub>1, initial A\<^sub>2) \<in> \<langle>S\<rangle> set_rel \<and>
      (succ A\<^sub>1, succ A\<^sub>2) \<in> L \<rightarrow> S \<rightarrow> \<langle>S\<rangle> set_rel \<and>
      (accepting A\<^sub>1, accepting A\<^sub>2) \<in> S \<rightarrow> bool_rel \<and>
      (ba.more A\<^sub>1, ba.more A\<^sub>2) \<in> M}"

  lemma ba_param[param]:
    "(ba_ext, ba_ext) \<in> \<langle>L\<rangle> set_rel \<rightarrow> \<langle>S\<rangle> set_rel \<rightarrow> (L \<rightarrow> S \<rightarrow> \<langle>S\<rangle> set_rel) \<rightarrow> (S \<rightarrow> bool_rel) \<rightarrow>
      M \<rightarrow> \<langle>L, S, M\<rangle> ba_rel"
    "(alphabet, alphabet) \<in> \<langle>L, S, M\<rangle> ba_rel \<rightarrow> \<langle>L\<rangle> set_rel"
    "(initial, initial) \<in> \<langle>L, S, M\<rangle> ba_rel \<rightarrow> \<langle>S\<rangle> set_rel"
    "(succ, succ) \<in> \<langle>L, S, M\<rangle> ba_rel \<rightarrow> L \<rightarrow> S \<rightarrow> \<langle>S\<rangle> set_rel"
    "(accepting, accepting) \<in> \<langle>L, S, M\<rangle> ba_rel \<rightarrow> S \<rightarrow> bool_rel"
    "(ba.more, ba.more) \<in> \<langle>L, S, M\<rangle> ba_rel \<rightarrow> M"
    unfolding ba_rel_def fun_rel_def by auto

  lemma ba_rel_id[simp]: "\<langle>Id, Id, Id\<rangle> ba_rel = Id" unfolding ba_rel_def by auto
  lemma ba_rel_comp[trans]:
    assumes [param]: "(A, B) \<in> \<langle>L\<^sub>1, S\<^sub>1, M\<^sub>1\<rangle> ba_rel" "(B, C) \<in> \<langle>L\<^sub>2, S\<^sub>2, M\<^sub>2\<rangle> ba_rel"
    shows "(A, C) \<in> \<langle>L\<^sub>1 O L\<^sub>2, S\<^sub>1 O S\<^sub>2, M\<^sub>1 O M\<^sub>2\<rangle> ba_rel"
  proof -
    have "(accepting A, accepting B) \<in> S\<^sub>1 \<rightarrow> bool_rel" by parametricity
    also have "(accepting B, accepting C) \<in> S\<^sub>2 \<rightarrow> bool_rel" by parametricity
    finally have 1: "(accepting A, accepting C) \<in> S\<^sub>1 O S\<^sub>2 \<rightarrow> bool_rel" by simp
    have "(succ A, succ B) \<in> L\<^sub>1 \<rightarrow> S\<^sub>1 \<rightarrow> \<langle>S\<^sub>1\<rangle> set_rel" by parametricity
    also have "(succ B, succ C) \<in> L\<^sub>2 \<rightarrow> S\<^sub>2 \<rightarrow> \<langle>S\<^sub>2\<rangle> set_rel" by parametricity
    finally have 2: "(succ A, succ C) \<in> L\<^sub>1 O L\<^sub>2 \<rightarrow> S\<^sub>1 O S\<^sub>2 \<rightarrow> \<langle>S\<^sub>1\<rangle> set_rel O \<langle>S\<^sub>2\<rangle> set_rel" by simp
    show ?thesis
      unfolding ba_rel_def mem_Collect_eq prod.case set_rel_compp
      using 1 2
      using ba_param(2 - 6)[THEN fun_relD, OF assms(1)]
      using ba_param(2 - 6)[THEN fun_relD, OF assms(2)]
      by auto
  qed
  lemma ba_rel_converse[simp]: "(\<langle>L, S, M\<rangle> ba_rel)\<inverse> = \<langle>L\<inverse>, S\<inverse>, M\<inverse>\<rangle> ba_rel"
  proof -
    have 1: "\<langle>L\<rangle> set_rel = (\<langle>L\<inverse>\<rangle> set_rel)\<inverse>" by simp
    have 2: "\<langle>S\<rangle> set_rel = (\<langle>S\<inverse>\<rangle> set_rel)\<inverse>" by simp
    have 3: "L \<rightarrow> S \<rightarrow> \<langle>S\<rangle> set_rel = (L\<inverse> \<rightarrow> S\<inverse> \<rightarrow> \<langle>S\<inverse>\<rangle> set_rel)\<inverse>" by simp
    have 4: "S \<rightarrow> bool_rel = (S\<inverse> \<rightarrow> bool_rel)\<inverse>" by simp
    show ?thesis unfolding ba_rel_def unfolding 3 unfolding 1 2 4 by fastforce
  qed

  lemma ba_rel_eq: "(A, A) \<in> \<langle>Id_on (alphabet A), Id_on (nodes A), Id\<rangle> ba_rel"
    unfolding ba_rel_def by auto

  lemma enableds_param[param]: "(enableds, enableds) \<in> \<langle>L, S, M\<rangle> ba_rel \<rightarrow> S \<rightarrow> \<langle>L \<times>\<^sub>r S\<rangle> set_rel"
    using ba_param(2, 4) unfolding ba.enableds_def fun_rel_def set_rel_def by fastforce
  lemma paths_param[param]: "(paths, paths) \<in> \<langle>L, S, M\<rangle> ba_rel \<rightarrow> S \<rightarrow> \<langle>\<langle>L \<times>\<^sub>r S\<rangle> list_rel\<rangle> set_rel"
    unfolding paths_def by (intro fun_relI paths_param, fold enableds_def) (parametricity+)
  lemma runs_param[param]: "(runs, runs) \<in> \<langle>L, S, M\<rangle> ba_rel \<rightarrow> S \<rightarrow> \<langle>\<langle>L \<times>\<^sub>r S\<rangle> stream_rel\<rangle> set_rel"
    unfolding runs_def by (intro fun_relI runs_param, fold enableds_def) (parametricity+)

  lemma reachable_param[param]: "(reachable, reachable) \<in> \<langle>L, S, M\<rangle> ba_rel \<rightarrow> S \<rightarrow> \<langle>S\<rangle> set_rel"
  proof -
    have 1: "reachable A p = (\<lambda> wr. target wr p) ` paths A p"
      for A :: "('label, 'state, 'more) ba_scheme" and p
      unfolding ba.reachable_alt_def ba.paths_def by auto
    show ?thesis unfolding 1 by parametricity
  qed
  lemma nodes_param[param]: "(nodes, nodes) \<in> \<langle>L, S, M\<rangle> ba_rel \<rightarrow> \<langle>S\<rangle> set_rel"
    unfolding ba.nodes_alt_def Collect_mem_eq by parametricity

  lemma language_param[param]: "(language, language) \<in> \<langle>L, S, M\<rangle> ba_rel \<rightarrow> \<langle>\<langle>L\<rangle> stream_rel\<rangle> set_rel"
  proof -
    have 1: "language A = (\<Union> p \<in> initial A. \<Union> wr \<in> runs A p.
      if infs (accepting A) (trace wr p) then {smap fst wr} else {})"
      for A :: "('label, 'state, 'more) ba_scheme"
      unfolding language_def ba.runs_def image_def by (auto iff: split_szip_ex)
    show ?thesis unfolding 1 by parametricity
  qed

end