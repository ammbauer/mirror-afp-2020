(*  Title:       NaturalTransformation
    Author:      Eugene W. Stark <stark@cs.stonybrook.edu>, 2016
    Maintainer:  Eugene W. Stark <stark@cs.stonybrook.edu>
*)

chapter NaturalTransformation

theory NaturalTransformation
imports Functor
begin

  section "Definition of a Natural Transformation"
    
  text{*
    As is the case for functors, the ``object-free'' definition of category
    makes it possible to view natural transformations as functions on arrows.
    In particular, a natural transformation between functors
    @{term F} and @{term G} from @{term A} to @{term B} can be represented by
    the map that takes each arrow @{term f} of @{term A} to the diagonal of the
    square in @{term B} corresponding to the transformation of @{term "F f"}
    to @{term "G f"}.  The images of the identities of @{term A} under this
    map are the usual components of the natural transformation.
    This representation exhibits natural transformations as a kind of generalization
    of functors, and in fact we can directly identify functors with identity
    natural transformations.
    However, functors are still necessary to state the defining conditions for
    a natural transformation, as the domain and codomain of a natural transformation
    cannot be recovered from the map on arrows that represents it.

    Like functors, natural transformations preserve arrows and map non-arrows to null.
    Natural transformations also ``preserve'' domain and codomain, but in a more general
    sense than functors. The naturality conditions, which express the two ways of factoring
    the diagonal of a commuting square, are degenerate in the case of an identity transformation.
  *}

  locale natural_transformation =
    A: category A + B: category B + 
    F: "functor" A B F + G: "functor" A B G
  for A :: "'a comp"
  and B :: "'b comp"
  and F :: "'a \<Rightarrow> 'b"
  and G :: "'a \<Rightarrow> 'b"
  and \<tau> :: "'a \<Rightarrow> 'b" +
  assumes is_extensional [simp]: "\<not>A.arr f \<Longrightarrow> \<tau> f = B.null"
  and preserves_dom [iff]: "A.arr f \<Longrightarrow> B.dom (\<tau> f) = F (A.dom f)"
  and preserves_cod [iff]: "A.arr f \<Longrightarrow> B.cod (\<tau> f) = G (A.cod f)"
  and is_natural_1 [iff]: "A.arr f \<Longrightarrow> B (G f) (\<tau> (A.dom f)) = \<tau> f"
  and is_natural_2 [iff]: "A.arr f \<Longrightarrow> B (\<tau> (A.cod f)) (F f) = \<tau> f"
  begin

    lemma preserves_arr [simp]:
    assumes "A.arr f"
    shows "B.arr (\<tau> f)"
      using assms B.arr_dom_iff_arr F.preserves_arr F.preserves_dom preserves_dom by force

    lemma preserves_hom [intro]:
    assumes "f \<in> A.hom a b"
    shows "\<tau> f \<in> B.hom (F a) (G b)"
      using assms preserves_arr by auto

    lemma preserves_comp_1:
    assumes "A.seq f' f"
    shows "\<tau> (A f' f) = B (G f') (\<tau> f)"
    proof -
      have "\<tau> (A f' f) = B (G (A f' f)) (\<tau> (A.dom f))"
        using assms by (metis A.arr_comp A.dom_comp is_natural_1)
      also have "... = B (G f') (\<tau> f)"
        using assms by simp
      finally show ?thesis by auto
    qed

    lemma preserves_comp_2:
    assumes "A.seq f' f"
    shows "\<tau> (A f' f) = B (\<tau> f') (F f)"
    proof -
      have "\<tau> (A f' f) = B (\<tau> (A.cod f')) (F (A f' f))"
        using assms by (metis A.arr_comp A.cod_comp is_natural_2)
      also have "... = B (\<tau> (A.cod f')) (B (F f') (F f))"
        using assms by simp
      also have "... = B (B (\<tau> (A.cod f')) (F f')) (F f)"
        using assms by (metis B.comp_assoc' B.ex_un_null B.match_1 B.match_2)
      also have "... = B (\<tau> f') (F f)"
        using assms by simp
      finally show ?thesis by auto
    qed

    text{*
      The following fact for natural transformations provides us with the same advantages
      as the corresponding fact for functors.
    *}

    lemma reflects_arr:
    assumes "B.arr (\<tau> f)"
    shows "A.arr f"
      using assms by (metis B.not_arr_null is_extensional)

    text{*
      A natural transformation that also happens to be a functor is equal to
      its own domain and codomain.
    *}

    lemma functor_implies_equals_dom:
    assumes "functor A B \<tau>"
    shows "F = \<tau>"
    proof
      interpret \<tau>: "functor" A B \<tau> using assms by auto
      fix f
      show "F f = \<tau> f"
      proof -
        have "\<not>A.arr f \<Longrightarrow> F f = \<tau> f" by simp
        moreover have "A.arr f \<Longrightarrow> F f = \<tau> f"
        proof -
          assume a1: "A.arr f"
          hence "A.dom (A.cod f) = A.cod f"
            by (meson A.category_axioms category.dom_cod)
          thus ?thesis
            using a1
            by (metis (no_types) A.ideD(1) B.comp_cod_arr A.ide_cod
                F.preserves_seq \<tau>.preserves_cod \<tau>.preserves_seq is_natural_2
                preserves_dom)
        qed
        ultimately show ?thesis by blast
      qed
    qed

    lemma functor_implies_equals_cod:
    assumes "functor A B \<tau>"
    shows "G = \<tau>"
    proof
      interpret \<tau>: "functor" A B \<tau> using assms by auto
      fix f
      show "G f = \<tau> f"
      proof -
        have "\<not>A.arr f \<Longrightarrow> G f = \<tau> f" by simp
        moreover have "A.arr f \<Longrightarrow> G f = \<tau> f"
          using is_natural_1
          by (metis A.arr_dom_iff_arr A.cod_dom B.category_axioms B.ide_dom G.preserves_arr
                    G.preserves_dom \<tau>.preserves_cod category.comp_arr_ide preserves_cod)
        ultimately show ?thesis by blast
      qed
    qed
          
  end

  section "Components of a Natural Transformation"

  text{*
    The values taken by a natural transformation on objects are the \emph{components}
    of the transformation.  We have the following basic technique for proving two natural
    transformations equal: show that they have the same components.
  *}

  lemma eqI:
  assumes "natural_transformation A B F G \<sigma>" and "natural_transformation A B F G \<sigma>'"
  and "\<And>a. category.ide A a \<Longrightarrow> \<sigma> a = \<sigma>' a"
  shows "\<sigma> = \<sigma>'"
  proof -
    interpret A: category A using assms(1) natural_transformation_def by blast
    interpret \<sigma>: natural_transformation A B F G \<sigma> using assms(1) by auto
    interpret \<sigma>': natural_transformation A B F G \<sigma>' using assms(2) by auto
    have "\<And>f. \<sigma> f = \<sigma>' f"
      using assms(3) \<sigma>.is_natural_2 \<sigma>'.is_natural_2 \<sigma>.is_extensional \<sigma>'.is_extensional A.ide_cod
      by metis
    thus ?thesis by auto
  qed

  text{*
    As equality of natural transformations is determined by equality of components,
    a natural transformation may be uniquely defined by specifying its components.
    The extension to all arrows is given by @{prop is_natural_1} or equivalently
    by @{prop is_natural_2}.
  *}

  locale transformation_by_components =
    A: category A + B: category B + 
    F: "functor" A B F + G: "functor" A B G
  for A :: "'a comp"
  and B :: "'b comp"
  and F :: "'a \<Rightarrow> 'b"
  and G :: "'a \<Rightarrow> 'b"
  and t :: "'a \<Rightarrow> 'b" +
  assumes maps_ide_in_hom [intro]: "A.ide a \<Longrightarrow> t a \<in> B.hom (F a) (G a)"
  and is_natural: "A.arr f \<Longrightarrow> B (t (A.cod f)) (F f) = B (G f) (t (A.dom f))"
  begin

    definition map
    where "map f = (if A.arr f then B (t (A.cod f)) (F f) else B.null)"

    (*
     * It seems best to have only this limited case as a default simplification.
     *)
    lemma map_simp_ide [simp]:
    assumes "A.ide a"
    shows "map a = t a"
      using assms map_def maps_ide_in_hom by simp

    lemma arr_map_iff_arr [iff]:
    shows "B.arr (map a) \<longleftrightarrow> A.arr a"
      using B.not_arr_null map_def maps_ide_in_hom by auto

    lemma is_natural_transformation:
    shows "natural_transformation A B F G map"
      apply (unfold_locales)
      using map_def maps_ide_in_hom is_natural by auto

  end

  sublocale transformation_by_components \<subseteq> natural_transformation A B F G map
    using is_natural_transformation by auto

  lemma transformation_by_components_idem [simp]:
  assumes "natural_transformation A B F G \<tau>"
  shows "transformation_by_components.map A B F \<tau> = \<tau>"
  proof -
    interpret \<tau>: natural_transformation A B F G \<tau> using assms by blast
    interpret \<tau>': transformation_by_components A B F G \<tau>
      apply unfold_locales using \<tau>.preserves_hom \<tau>.is_natural_1 by auto
    show ?thesis
      using assms \<tau>'.map_simp_ide \<tau>'.is_natural_transformation eqI by blast
  qed

  section "Functors as Natural Transformations"

  text{*
    A functor is a special case of a natural transformation, in the sense that the same map
    that defines the functor also defines an identity natural transformation.
  *}

  lemma functor_is_transformation [simp]:
  assumes "functor A B F"
  shows "natural_transformation A B F F F"
  proof -
    interpret "functor" A B F using assms by auto
    show "natural_transformation A B F F F"
      apply unfold_locales by auto
  qed

  sublocale "functor" \<subseteq> natural_transformation A B F F F
    by (simp add: functor_axioms)

  section "Constant Natural Transformations"

  text{*
    A constant natural transformation is one whose components are all the same arrow.
  *}

  locale constant_transformation =
    A: category A +
    B: category B +
    F: constant_functor A B "B.dom g" +
    G: constant_functor A B "B.cod g"
  for A :: "'a comp"
  and B :: "'b comp"
  and g :: 'b +
  assumes value_is_arr: "B.arr g"
  begin

    definition map
    where "map f \<equiv> if A.arr f then g else B.null"

    lemma map_simp [simp]:
    assumes "A.arr f"
    shows "map f = g"
      using assms map_def by auto

    lemma is_natural_transformation:
    shows "natural_transformation A B F.map G.map map"
      apply unfold_locales using map_def value_is_arr by auto

    lemma is_functor_if_value_is_ide:
    assumes "B.ide g"
    shows "functor A B map"
      apply unfold_locales using assms map_def by auto

  end

  sublocale constant_transformation \<subseteq> natural_transformation A B F.map G.map map
    using is_natural_transformation by auto

  context constant_transformation
  begin

    lemma equals_dom_if_value_is_ide [simp]:
    assumes "B.ide g"
    shows "map = F.map"
    proof -
      show "map = F.map"
        using assms map_def functor_implies_equals_dom is_functor_if_value_is_ide
        by simp
    qed

    lemma equals_cod_if_value_is_ide [simp]:
    assumes "B.ide g"
    shows "map = G.map"
    proof -
      show "map = G.map"
        using assms map_def functor_implies_equals_dom is_functor_if_value_is_ide
        by simp
    qed

  end

  section "Vertical Composition"

  text{*
    Vertical composition is a way of composing natural transformations @{text "\<sigma>: F \<rightarrow> G"}
    and @{text "\<tau>: G \<rightarrow> H"}, between parallel functors @{term F}, @{term G}, and @{term H}
    to obtain a natural transformation from @{term F} to @{term H}.
    The composite is traditionally denoted by @{text "\<tau> o \<sigma>"}, however in the present
    setting this notation is misleading because it is horizontal composite, rather than
    vertical composite, that coincides with composition of natural transformations as
    functions on arrows.
  *}

  locale vertical_composite =
    A: category A +
    B: category B +
    F: "functor" A B F +
    G: "functor" A B G +
    H: "functor" A B H +
    \<sigma>: natural_transformation A B F G \<sigma> +
    \<tau>: natural_transformation A B G H \<tau>
    for A :: "'a comp"
    and B :: "'b comp"
    and F :: "'a \<Rightarrow> 'b"
    and G :: "'a \<Rightarrow> 'b"
    and H :: "'a \<Rightarrow> 'b"
    and \<sigma> :: "'a \<Rightarrow> 'b"
    and \<tau> :: "'a \<Rightarrow> 'b"
  begin

    text{*
      The vertical composite takes an arrow @{term "f \<in> A.hom a b"} to an arrow in
      @{term "B.hom (F a) (G b)"}, which we can obtain by forming either of
      the composites @{term "B (\<tau> b) (\<sigma> f)"} or @{term "B (\<tau> f) (\<sigma> a)"}, which are
      equal to each other.
    *}

    definition map
    where "map f = (if A.arr f then B (\<tau> (A.cod f)) (\<sigma> f) else B.null)"

    lemma map_seq:
    assumes "A.arr f"
    shows "B.seq (\<tau> (A.cod f)) (\<sigma> f)"
      using assms \<sigma>.preserves_hom \<tau>.preserves_hom by simp

    lemma map_simp_ide:
    assumes "A.ide a"
    shows "map a = B (\<tau> a) (\<sigma> a)"
      using assms by (simp add: map_def)

    lemma map_simp_1:
    assumes "A.arr f"
    shows "map f = B (\<tau> (A.cod f)) (\<sigma> f)"
      using assms by (simp add: map_def)

    lemma map_simp_2:
    assumes "A.arr f"
    shows "map f = B (\<tau> f) (\<sigma> (A.dom f))"
    proof -
      have "B (G f) (\<sigma> (A.dom f)) = \<sigma> f"
        using assms by blast
      thus ?thesis
        by (metis (full_types) A.arr_dom_iff_arr A.cod_dom B.category_axioms G.preserves_arr
            G.preserves_cod G.preserves_dom \<sigma>.preserves_cod \<tau>.is_natural_2 map_seq assms
            category.comp_assoc vertical_composite.map_simp_1 vertical_composite_axioms)
    qed

    lemma is_natural_transformation:
    shows "natural_transformation A B F H map"
      using map_def map_simp_1
      apply (unfold_locales, simp_all)
      by (metis B.comp_assoc' B.comp_null(2) B.match_1 B.not_arr_null
                \<tau>.is_natural_1 \<tau>.preserves_arr map_simp_1 map_simp_2)

  end

  sublocale vertical_composite \<subseteq> natural_transformation A B F H map
    using is_natural_transformation by auto

  text{*
    Functors are the identities for vertical composition.
  *}

  lemma vcomp_ide_dom [simp]:
  assumes "natural_transformation A B F G \<tau>"
  shows "vertical_composite.map A B F \<tau> = \<tau>"
    apply (intro eqI)
    (* 3 *) using assms apply auto[2]
    (* 2 *) using assms
            apply (metis functor_is_transformation natural_transformation_def
                         vertical_composite.is_natural_transformation vertical_composite_def)
    (* 1 *)
    proof -
      fix a :: 'a
      have "vertical_composite A B F F G F \<tau>"
        by (meson assms functor_is_transformation natural_transformation.axioms(1)
                  natural_transformation.axioms(2) natural_transformation.axioms(3)
                  natural_transformation.axioms(4) vertical_composite.intro)
      moreover have "partial_magma.arr A a \<longrightarrow> B (\<tau> (category.cod A a)) (F a) = \<tau> a"
        by (meson assms natural_transformation.is_natural_2)
      ultimately show "vertical_composite.map A B F \<tau> a = \<tau> a"
        using assms natural_transformation.is_extensional vertical_composite.map_def
        by fastforce
    qed
    
  lemma vcomp_ide_cod [simp]:
  assumes "natural_transformation A B F G \<tau>"
  shows "vertical_composite.map A B \<tau> G = \<tau>"
    apply (intro eqI)
    (* 3 *) using assms apply auto[2]
    (* 2 *) using assms
            apply (metis functor_def functor_is_transformation
                         natural_transformation.axioms(3) natural_transformation.axioms(4)
                         vertical_composite.is_natural_transformation vertical_composite_def)
    (* 1 *)
  proof -
    fix a :: 'a
    assume a1: "category.ide A a"
    have "vertical_composite A B F G G \<tau> G"
    by (meson assms functor_is_transformation natural_transformation.axioms(1)
              natural_transformation.axioms(2) natural_transformation.axioms(3)
              natural_transformation.axioms(4) vertical_composite.intro)
    then show "vertical_composite.map A B \<tau> G a = \<tau> a"
      using a1
      by (metis (full_types) assms category.ide_is_iso category.iso_is_arr
          natural_transformation.axioms(1) natural_transformation.is_natural_1
          vertical_composite.map_simp_2)
  qed

  text{*
    Vertical composition is associative.
  *}

  lemma vcomp_assoc [iff]:
  assumes "natural_transformation A B F G \<rho>"
  and "natural_transformation A B G H \<sigma>"
  and "natural_transformation A B H K \<tau>"
  shows "vertical_composite.map A B (vertical_composite.map A B \<rho> \<sigma>) \<tau>
            = vertical_composite.map A B \<rho> (vertical_composite.map A B \<sigma> \<tau>)"
  proof -
    interpret A: category A
      using assms(1) natural_transformation_def functor_def by blast
    interpret B: category B
      using assms(1) natural_transformation_def functor_def by blast
    interpret \<rho>: natural_transformation A B F G \<rho> using assms(1) by auto
    interpret \<sigma>: natural_transformation A B G H \<sigma> using assms(2) by auto
    interpret \<tau>: natural_transformation A B H K \<tau> using assms(3) by auto
    interpret \<rho>\<sigma>: vertical_composite A B F G H \<rho> \<sigma> ..
    interpret \<sigma>\<tau>: vertical_composite A B G H K \<sigma> \<tau> ..
    interpret \<rho>_\<sigma>\<tau>: vertical_composite A B F G K \<rho> \<sigma>\<tau>.map ..
    interpret \<rho>\<sigma>_\<tau>: vertical_composite A B F H K \<rho>\<sigma>.map \<tau> ..
    show ?thesis
      apply (intro eqI)
      (* 3 *) using `natural_transformation A B F K \<rho>\<sigma>_\<tau>.map` apply simp
      (* 2 *) using \<rho>_\<sigma>\<tau>.natural_transformation_axioms apply blast
      (* 1 *) by (simp add: \<rho>\<sigma>.map_def \<rho>\<sigma>_\<tau>.map_def \<rho>_\<sigma>\<tau>.map_simp_2 \<sigma>\<tau>.map_def)
  qed

  section "Natural Isomorphisms"

  text{*
    A natural isomorphism is a natural transformation each of whose components
    is an isomorphism.  Equivalently, a natural isomorphism is a natural transformation
    that is invertible with respect to vertical composition.
  *}

  locale natural_isomorphism = natural_transformation A B F G \<tau>
  for A :: "'a comp"
  and B :: "'b comp"
  and F :: "'a \<Rightarrow> 'b"
  and G :: "'a \<Rightarrow> 'b"
  and \<tau> :: "'a \<Rightarrow> 'b" +
  assumes components_are_iso: "A.ide a \<Longrightarrow> B.iso (\<tau> a)"

  definition naturally_isomorphic
  where "naturally_isomorphic A B F G = (\<exists>\<tau>. natural_isomorphism A B F G \<tau>)"

  locale inverse_transformation =
    A: category A +
    B: category B +
    F: "functor" A B F +
    G: "functor" A B G +
    \<tau>: natural_isomorphism A B F G \<tau>
  for A :: "'a comp"
  and B :: "'b comp"
  and F :: "'a \<Rightarrow> 'b"
  and G :: "'a \<Rightarrow> 'b"
  and \<tau> :: "'a \<Rightarrow> 'b"
  begin

    interpretation \<tau>': transformation_by_components A B G F "\<lambda>a. B.inv (\<tau> a)"
    proof
      fix a :: 'a
      assume A: "A.ide a"
      show "B.inv (\<tau> a) \<in> B.hom (G a) (F a)"
      proof -
        have "B.inverse_arrows (\<tau> a) (B.inv (\<tau> a))"
          using A \<tau>.components_are_iso B.ide_is_iso B.inv_is_inverse B.inverse_arrows_def
          by blast
        thus ?thesis
          using A B.inverse_arrows_def \<tau>.preserves_hom by force
      qed
      next
      have 1: "\<And>a. A.ide a \<Longrightarrow> B.inverse_arrows (\<tau> a) (B.inv (\<tau> a))"
        using \<tau>.components_are_iso B.ide_is_iso B.inv_is_inverse B.inverse_arrows_def by blast
      fix f :: 'a
      assume f: "A.arr f"
      show "B (B.inv (\<tau> (A.cod f))) (G f) = B (F f) (B.inv (\<tau> (A.dom f)))"
      proof -
        have "B (B.inv (\<tau> (A.cod f))) (B (G f) (\<tau> (A.dom f))) = F f"
        proof -
          have "B.arr (\<tau> (A.cod f)) \<and> B.arr (B.inv (\<tau> (A.cod f))) \<and>
                B.dom (\<tau> (A.cod f)) = B.cod (B.inv (\<tau> (A.cod f))) \<and>
                B.cod (\<tau> (A.cod f)) = B.dom (B.inv (\<tau> (A.cod f))) \<and>
                B.ide (B (B.inv (\<tau> (A.cod f))) (\<tau> (A.cod f))) \<and>
                B.ide (B (\<tau> (A.cod f)) (B.inv (\<tau> (A.cod f))))"
            using 1 A.ide_cod f by blast
          moreover have "B (G f) (\<tau> (A.dom f)) = B (\<tau> (A.cod f)) (F f)"
            using f by simp
          ultimately show ?thesis
            by (metis (no_types) A.arr_cod_iff_arr A.dom_cod B.category_axioms B.ide_comp_simp
                F.is_natural_2 F.preserves_arr F.preserves_cod
                \<tau>.preserves_dom category.comp_assoc f)
        qed
        hence 2: "B (B (B.inv (\<tau> (A.cod f))) (G f)) (\<tau> (A.dom f)) = F f"
          using f by (metis B.comp_assoc' B.ex_un_null B.match_1 B.match_2)
        show ?thesis
        proof -
          have "B.arr (\<tau> (A.dom f)) \<and> B.arr (B.inv (\<tau> (A.dom f))) \<and>
                 B.dom (\<tau> (A.dom f)) = B.cod (B.inv (\<tau> (A.dom f))) \<and>
                 B.cod (\<tau> (A.dom f)) = B.dom (B.inv (\<tau> (A.dom f))) \<and>
                 B.ide (B (B.inv (\<tau> (A.dom f))) (\<tau> (A.dom f))) \<and>
                 B.ide (B (\<tau> (A.dom f)) (B.inv (\<tau> (A.dom f))))"
            using 1 A.ide_dom f by blast
          thus ?thesis
            using 2 f F.preserves_arr B.arr_compD(2)
            by (metis (no_types) 2 B.comp_arr_dom B.ide_comp_simp B.arr_compD(3) B.comp_assoc)
          qed
      qed
    qed

    definition map
    where "map = \<tau>'.map"

    lemma map_ide_simp [simp]:
    assumes "A.ide a"
    shows "map a = B.inv (\<tau> a)"
      using assms map_def by fastforce

    lemma map_simp:
    assumes "A.arr f"
    shows "map f = B (B.inv (\<tau> (A.cod f))) (G f)"
      using assms map_def \<tau>'.map_simp_ide by (simp add: \<tau>'.map_def)

    lemma is_natural_transformation:
    shows "natural_transformation A B G F map"
      by (simp add: \<tau>'.natural_transformation_axioms map_def)

    lemma inverts_components:
    assumes "A.ide a"
    shows "B.inverse_arrows (\<tau> a) (map a)"
      using assms \<tau>.components_are_iso B.ide_is_iso B.inv_is_inverse B.inverse_arrows_def map_def
      by (metis \<tau>'.map_simp_ide)

  end

  sublocale inverse_transformation \<subseteq> natural_transformation A B G F map
    using is_natural_transformation by auto

  sublocale inverse_transformation \<subseteq> natural_isomorphism A B G F map
    by (meson B.category_axioms B.iso_def category.inverse_arrows_sym inverts_components
              natural_isomorphism.intro natural_isomorphism_axioms.intro
              natural_transformation_axioms)

  lemma inverse_inverse_transformation [simp]:
  assumes "natural_isomorphism A B F G \<tau>"
  shows "inverse_transformation.map A B F (inverse_transformation.map A B G \<tau>) = \<tau>"
    using assms
          category.inverse_arrows_sym category.inverse_unique category.isoI eqI
          inverse_transformation.intro inverse_transformation.inverts_components
          inverse_transformation.is_natural_transformation natural_isomorphism.axioms(1)
          natural_isomorphism.intro natural_isomorphism_axioms.intro natural_transformation_def
    by metis

  locale inverse_transformations =
    A: category A +
    B: category B +
    F: "functor" A B F +
    G: "functor" A B G +
    \<tau>: natural_transformation A B F G \<tau> +
    \<tau>': natural_transformation A B G F \<tau>'
  for A :: "'a comp"
  and B :: "'b comp"
  and F :: "'a \<Rightarrow> 'b"
  and G :: "'a \<Rightarrow> 'b"
  and \<tau> :: "'a \<Rightarrow> 'b"
  and \<tau>' :: "'a \<Rightarrow> 'b" +
  assumes inv: "A.ide a \<Longrightarrow> B.inverse_arrows (\<tau> a) (\<tau>' a)"

  sublocale inverse_transformations \<subseteq> natural_isomorphism A B F G \<tau>
    by (meson B.category_axioms \<tau>.natural_transformation_axioms category.iso_def inv
              natural_isomorphism.intro natural_isomorphism_axioms.intro)
  sublocale inverse_transformations \<subseteq> natural_isomorphism A B G F \<tau>'
    by (meson category.inverse_arrows_sym category.iso_def inverse_transformations_axioms
              inverse_transformations_axioms_def inverse_transformations_def
              natural_isomorphism.intro natural_isomorphism_axioms.intro)

  lemma inverse_transformations_sym:
  assumes "inverse_transformations A B F G \<sigma> \<sigma>'"
  shows "inverse_transformations A B G F \<sigma>' \<sigma>"
    using assms
    by (simp add: category.inverse_arrows_sym inverse_transformations_axioms_def
                  inverse_transformations_def)

  lemma inverse_transformations_inverse:
  assumes "inverse_transformations A B F G \<sigma> \<sigma>'"
  shows "vertical_composite.map A B \<sigma> \<sigma>' = F"
  and "vertical_composite.map A B \<sigma>' \<sigma> = G"
  proof -
    interpret A: category A
      using assms(1) inverse_transformations_def natural_transformation_def by blast
    interpret inv: inverse_transformations A B F G \<sigma> \<sigma>' using assms by auto
    interpret \<sigma>\<sigma>': vertical_composite A B F G F \<sigma> \<sigma>' ..
    show "vertical_composite.map A B \<sigma> \<sigma>' = F"
      apply (intro eqI)
      (* 3 *) using \<sigma>\<sigma>'.is_natural_transformation apply blast
      (* 2 *) using inv.F.natural_transformation_axioms apply simp
      (* 1 *) using A.ideD(1) A.ideD(3) \<sigma>\<sigma>'.preserves_dom \<sigma>\<sigma>'.vertical_composite_axioms
                   inv.B.ideD(2) inv.F.preserves_dom inv.F.preserves_ide inv.inv
                   vertical_composite.map_def
              by (metis inv.B.inverse_arrowsD(2))
    interpret inv': inverse_transformations A B G F \<sigma>' \<sigma>
      using assms inverse_transformations_sym by blast
    interpret \<sigma>'\<sigma>: vertical_composite A B G F G \<sigma>' \<sigma> ..
    show "vertical_composite.map A B \<sigma>' \<sigma> = G"
      apply (intro eqI)
      (* 3 *) using \<sigma>'\<sigma>.is_natural_transformation apply blast
      (* 2 *) using inv.G.natural_transformation_axioms apply simp
      (* 1 *) using A.ideD(1) A.ideD(3) \<sigma>'\<sigma>.preserves_cod \<sigma>'\<sigma>.vertical_composite_axioms
                    inv'.inv inv.B.ideD(3) vertical_composite.map_def
                    inv.B.inverse_arrows_def inv.\<tau>.preserves_cod
              by metis
  qed

  lemma inverse_transformations_compose:
  assumes "inverse_transformations A B F G \<sigma> \<sigma>'"
  and "inverse_transformations A B G H \<tau> \<tau>'"
  shows "inverse_transformations A B F H (vertical_composite.map A B \<sigma> \<tau>)
                                         (vertical_composite.map A B \<tau>' \<sigma>')"
  proof -
    interpret A: category A using assms(1) inverse_transformations_def by blast
    interpret B: category B using assms(1) inverse_transformations_def by blast
    interpret \<sigma>\<sigma>': inverse_transformations A B F G \<sigma> \<sigma>' using assms(1) by auto
    interpret \<tau>\<tau>': inverse_transformations A B G H \<tau> \<tau>' using assms(2) by auto
    interpret \<sigma>\<tau>: vertical_composite A B F G H \<sigma> \<tau> ..
    interpret \<tau>'\<sigma>': vertical_composite A B H G F \<tau>' \<sigma>' ..
    show ?thesis
    proof
      fix a
      assume A: "A.ide a"
      show "B.inverse_arrows (\<sigma>\<tau>.map a) (\<tau>'\<sigma>'.map a)"
        using A
        by (simp add: B.inverse_arrows_compose \<sigma>\<sigma>'.inv \<sigma>\<tau>.map_simp_1 \<tau>'\<sigma>'.map_simp_1 \<tau>\<tau>'.inv)
    qed
  qed

  lemma vertical_composite_iso_inverse [simp]:
  assumes "natural_isomorphism A B F G \<tau>"
  shows "vertical_composite.map A B \<tau> (inverse_transformation.map A B G \<tau>) = F"
  proof -
    interpret \<tau>: natural_isomorphism A B F G \<tau> using assms by auto
    interpret \<tau>': inverse_transformation A B F G \<tau> ..
    interpret \<tau>\<tau>': vertical_composite A B F G F \<tau> \<tau>'.map ..
    show ?thesis
      apply (intro eqI)
      (* 3 *) using \<tau>\<tau>'.is_natural_transformation \<tau>.F.natural_transformation_axioms \<tau>'.inverts_components
                    \<tau>.B.inverse_arrows_def \<tau>\<tau>'.map_simp_ide
              apply simp
      (* 2 *) using \<tau>.F.natural_transformation_axioms apply simp
      (* 1 *) using \<tau>'.inverts_components \<tau>.B.inverse_arrows_def \<tau>.B.ide_comp_simp \<tau>\<tau>'.map_simp_ide
              by (metis \<tau>'.preserves_cod \<tau>.A.ideD(1) \<tau>.A.ideD(3))
  qed

  lemma vertical_composite_inverse_iso [simp]:
  assumes "natural_isomorphism A B F G \<tau>"
  shows "vertical_composite.map A B (inverse_transformation.map A B G \<tau>) \<tau> = G"
  proof -
    interpret \<tau>: natural_isomorphism A B F G \<tau> using assms by auto
    interpret \<tau>': inverse_transformation A B F G \<tau> ..
    interpret \<tau>'\<tau>: vertical_composite A B G F G \<tau>'.map \<tau> ..    
    show ?thesis
      apply (intro eqI)
      using \<tau>'\<tau>.is_natural_transformation \<tau>.G.natural_transformation_axioms \<tau>'.inverts_components
            \<tau>'\<tau>.map_simp_ide \<tau>.B.inverse_arrows_def \<tau>.B.ide_comp_simp
      by auto
  qed

  lemma natural_isomorphisms_compose:
  assumes "natural_isomorphism A B F G \<sigma>" and "natural_isomorphism A B G H \<tau>"
  shows "natural_isomorphism A B F H (vertical_composite.map A B \<sigma> \<tau>)"
  proof -
    interpret A: category A
      using assms(1) natural_isomorphism_def natural_transformation_def by blast
    interpret B: category B
      using assms(1) natural_isomorphism_def natural_transformation_def by blast
    interpret \<sigma>: natural_isomorphism A B F G \<sigma> using assms(1) by auto
    interpret \<tau>: natural_isomorphism A B G H \<tau> using assms(2) by auto
    interpret \<sigma>\<tau>: vertical_composite A B F G H \<sigma> \<tau> ..
    interpret natural_isomorphism A B F H \<sigma>\<tau>.map
    proof
      show "\<And>a. A.ide a \<Longrightarrow> B.iso (\<sigma>\<tau>.map a)"
        using B.isos_compose \<sigma>.components_are_iso \<tau>.components_are_iso \<tau>.preserves_hom
        by (auto simp add: \<sigma>\<tau>.map_simp_1)
    qed
    show ?thesis ..
  qed

  section "Horizontal Composition"

  text{*
    Horizontal composition is a way of composing parallel natural transformations
    @{term \<sigma>} from @{term F} to @{term G} and @{term \<tau>} from @{term H} to @{term K},
    where functors @{term F} and @{term G} map @{term A} to @{term B} and
    @{term H} and @{term K} map @{term B} to @{term C}, to obtain a natural transformation
    from @{term "H o F"} to @{term "K o G"}.
  *}

  locale horizontal_composite =
    A: category A +
    B: category B +
    C: category C +
    F: "functor" A B F +
    G: "functor" A B G +
    H: "functor" B C H +
    K: "functor" B C K +
    \<sigma>: natural_transformation A B F G \<sigma> +
    \<tau>: natural_transformation B C H K \<tau>
    for A :: "'a comp"
    and B :: "'b comp"
    and C :: "'c comp"
    and F :: "'a \<Rightarrow> 'b"
    and G :: "'a \<Rightarrow> 'b"
    and H :: "'b \<Rightarrow> 'c"
    and K :: "'b \<Rightarrow> 'c"
    and \<sigma> :: "'a \<Rightarrow> 'b"
    and \<tau> :: "'b \<Rightarrow> 'c"
  begin

    abbreviation map
    where "map \<equiv> \<tau> o \<sigma>"

    lemma is_natural_transformation:
    shows "natural_transformation A C (H o F) (K o G) map"
    proof -
      interpret HF: composite_functor A B C F H ..
      interpret KG: composite_functor A B C G K ..
      show "natural_transformation A C (H o F) (K o G) (\<tau> o \<sigma>)"
        apply unfold_locales
        (* 5 *) apply (metis \<sigma>.reflects_arr \<tau>.is_extensional comp_apply)
        (* 4 *) apply simp
        (* 3 *) apply simp
      proof -
        fix f
        assume f: "A.arr f"
        have "C ((K \<circ> G) f) ((\<tau> \<circ> \<sigma>) (A.dom f)) = C (K (G f)) (\<tau> (\<sigma> (A.dom f)))"
          by simp
        also have "... = \<tau> (\<sigma> f)"
          using f \<sigma>.natural_transformation_axioms \<tau>.natural_transformation_axioms
                natural_transformation.is_natural_1
          by (metis A.arr_dom_iff_arr A.cod_dom G.natural_transformation_axioms
                  \<sigma>.preserves_cod \<tau>.preserves_comp_1 natural_transformation.preserves_arr
                  natural_transformation.preserves_dom)
        finally show "C ((K \<circ> G) f) ((\<tau> \<circ> \<sigma>) (A.dom f)) = (\<tau> o \<sigma>) f" by auto
        have " C ((\<tau> \<circ> \<sigma>) (A.cod f)) ((H \<circ> F) f) = C (\<tau> (\<sigma> (A.cod f))) (H (F f))"
          by simp
        also have "... = \<tau> (\<sigma> f)"
          using f \<sigma>.natural_transformation_axioms \<tau>.natural_transformation_axioms
                natural_transformation.is_natural_2
          by (metis (full_types) A.arr_cod_iff_arr A.dom_cod F.functor_axioms
              F.natural_transformation_axioms \<sigma>.preserves_dom \<tau>.preserves_comp_2
              functor.preserves_cod natural_transformation.preserves_arr)
        finally show "C ((\<tau> \<circ> \<sigma>) (A.cod f)) ((H \<circ> F) f) = (\<tau> o \<sigma>) f" by auto
      qed
    qed

  end

  sublocale horizontal_composite \<subseteq> natural_transformation A C "H o F" "K o G" "\<tau> o \<sigma>"
    using is_natural_transformation by auto

  context horizontal_composite
  begin

    interpretation KF: composite_functor A B C F K ..
    interpretation HG: composite_functor A B C G H ..
    interpretation \<tau>F: horizontal_composite A B C F F H K F \<tau> ..
    interpretation \<tau>G: horizontal_composite A B C G G H K G \<tau> ..
    interpretation H\<sigma>: horizontal_composite A B C F G H H \<sigma> H ..
    interpretation K\<sigma>: horizontal_composite A B C F G K K \<sigma> K ..
    interpretation K\<sigma>_\<tau>F: vertical_composite A C "H o F" "K o F" "K o G" "\<tau> o F" "K o \<sigma>" ..
    interpretation \<tau>G_H\<sigma>: vertical_composite A C "H o F" "H o G" "K o G" "H o \<sigma>" "\<tau> o G" ..

    lemma map_simp_1:
    assumes "A.arr f"
    shows "(\<tau> o \<sigma>) f = K\<sigma>_\<tau>F.map f"
      using assms \<sigma>.preserves_arr \<sigma>.preserves_dom \<sigma>.is_natural_1 \<tau>.is_natural_1
            K\<sigma>_\<tau>F.map_simp_2 K\<sigma>_\<tau>F.is_natural_1
      by (metis comp_apply)

    lemma map_simp_2:
    assumes "A.arr f"
    shows "(\<tau> o \<sigma>) f = \<tau>G_H\<sigma>.map f"
      using assms \<tau>.is_natural_2 \<sigma>.is_natural_2 \<sigma>.preserves_arr \<sigma>.preserves_cod
            \<tau>G_H\<sigma>.map_def \<tau>G_H\<sigma>.is_natural_2
      by (metis comp_apply)

  end

  lemma hcomp_ide_dom [simp]:
  assumes "natural_transformation A B F G \<tau>"
  shows "\<tau> o (identity_functor.map A) = \<tau>"
  proof -
    interpret \<tau>: natural_transformation A B F G \<tau> using assms by auto
    interpret iA: identity_functor A ..
    show "\<tau> o iA.map = \<tau>"
      using iA.map_def \<tau>.is_extensional \<tau>.A.not_arr_null by fastforce
  qed

  lemma hcomp_ide_cod [simp]:
  assumes "natural_transformation A B F G \<tau>"
  shows "(identity_functor.map B) o \<tau> = \<tau>"
  proof -
    interpret \<tau>: natural_transformation A B F G \<tau> using assms by auto
    interpret iB: identity_functor B ..
    show "iB.map o \<tau> = \<tau>"
    proof
      fix f
      have "\<not>\<tau>.A.arr f \<Longrightarrow> (iB.map o \<tau>) f = \<tau> f"
        using iB.map_def \<tau>.is_extensional \<tau>.B.not_arr_null by fastforce
      moreover have "\<tau>.A.arr f \<Longrightarrow> (iB.map o \<tau>) f = \<tau> f"
        using iB.map_def by fastforce
      ultimately show "(iB.map o \<tau>) f = \<tau> f" by blast
    qed
  qed

  text{*
    Horizontal composition of a functor with a vertical composite.
  *}

  lemma hcomp_functor_vcomp:
  assumes "functor A B F"
  and "natural_transformation B C H K \<tau>"
  and "natural_transformation B C K L \<tau>'"
  shows "(vertical_composite.map B C \<tau> \<tau>') o F = vertical_composite.map A C (\<tau> o F) (\<tau>' o F)"
  proof -
    interpret F: "functor" A B F using assms(1) by auto
    interpret \<tau>: natural_transformation B C H K \<tau> using assms(2) by auto
    interpret \<tau>': natural_transformation B C K L \<tau>' using assms(3) by auto
    interpret HF: composite_functor A B C F H ..
    interpret KF: composite_functor A B C F K ..
    interpret LF: composite_functor A B C F L ..
    interpret \<tau>F: horizontal_composite A B C F F H K F \<tau> ..
    interpret \<tau>'F: horizontal_composite A B C F F K L F \<tau>' ..
    interpret \<tau>'o\<tau>: vertical_composite B C H K L \<tau> \<tau>' ..
    interpret \<tau>'o\<tau>_F: horizontal_composite A B C F F H L F \<tau>'o\<tau>.map ..
    interpret \<tau>'Fo\<tau>F: vertical_composite A C "H o F" "K o F" "L o F" "\<tau> o F" "\<tau>' o F" ..
    show ?thesis
    proof
      fix f
      have "\<not>F.A.arr f \<Longrightarrow> (\<tau>'o\<tau>.map o F) f = \<tau>'Fo\<tau>F.map f"
        using \<tau>'Fo\<tau>F.map_def \<tau>'o\<tau>.map_def \<tau>'o\<tau>_F.is_extensional by auto
      moreover have "F.A.arr f \<Longrightarrow> (\<tau>'o\<tau>.map o F) f = \<tau>'Fo\<tau>F.map f"
        using \<tau>'Fo\<tau>F.map_def \<tau>'o\<tau>.map_def by simp
      ultimately show "(\<tau>'o\<tau>.map o F) f = \<tau>'Fo\<tau>F.map f" by blast
    qed
  qed

  text{*
    Horizontal composition of a vertical composite with a functor.
  *}

  lemma hcomp_vcomp_functor:
  assumes "functor B C K"
  and "natural_transformation A B F G \<tau>"
  and "natural_transformation A B G H \<tau>'"
  shows "K o (vertical_composite.map A B \<tau> \<tau>') = vertical_composite.map A C (K o \<tau>) (K o \<tau>')"
  proof -
    interpret K: "functor" B C K using assms(1) by auto
    interpret \<tau>: natural_transformation A B F G \<tau> using assms(2) by auto
    interpret \<tau>': natural_transformation A B G H \<tau>' using assms(3) by auto
    interpret KF: composite_functor A B C F K ..
    interpret KG: composite_functor A B C G K ..
    interpret KH: composite_functor A B C H K ..
    interpret \<tau>'o\<tau>: vertical_composite A B F G H \<tau> \<tau>' ..
    interpret K\<tau>: horizontal_composite A B C F G K K \<tau> K ..
    interpret K\<tau>': horizontal_composite A B C G H K K \<tau>' K ..
    interpret K_\<tau>'o\<tau>: horizontal_composite A B C F H K K \<tau>'o\<tau>.map K ..
    interpret K\<tau>'oK\<tau>: vertical_composite A C "K o F" "K o G" "K o H" "K o \<tau>" "K o \<tau>'" ..
    show "K o \<tau>'o\<tau>.map = K\<tau>'oK\<tau>.map"
    proof
      fix f
      have "\<not>\<tau>.A.arr f \<Longrightarrow> (K o \<tau>'o\<tau>.map) f = K\<tau>'oK\<tau>.map f"
        using K\<tau>'oK\<tau>.map_def \<tau>'o\<tau>.map_def K_\<tau>'o\<tau>.is_extensional by auto
      moreover have "\<tau>.A.arr f \<Longrightarrow> (K o \<tau>'o\<tau>.map) f = K\<tau>'oK\<tau>.map f"
        using K\<tau>'oK\<tau>.map_def \<tau>'o\<tau>.map_def by simp
      ultimately show "(K o \<tau>'o\<tau>.map) f = K\<tau>'oK\<tau>.map f" by blast
    qed
  qed

end


