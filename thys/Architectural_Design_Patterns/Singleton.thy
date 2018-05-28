(*
  Title:      Singleton.thy
  Author:     Diego Marmsoler
*)
section "A Theory of Singletons"
text{*
  In the following, we formalize the specification of the singleton pattern as described in~\cite{Marmsoler2018c}.
*}
  
theory Singleton
imports DynamicArchitectures.Dynamic_Architecture_Calculus
begin
subsection Singletons

locale singleton = dynamic_component cmp active
    for active :: "'id \<Rightarrow> cnf \<Rightarrow> bool" ("\<parallel>_\<parallel>\<^bsub>_\<^esub>" [0,110]60)
    and cmp :: "'id \<Rightarrow> cnf \<Rightarrow> 'cmp" ("\<sigma>\<^bsub>_\<^esub>(_)" [0,110]60) +
assumes alwaysActive: "\<And>k. \<exists>id. \<parallel>id\<parallel>\<^bsub>k\<^esub>"
    and unique: "\<exists>id. \<forall>k. \<forall>id'. (\<parallel>id'\<parallel>\<^bsub>k\<^esub> \<longrightarrow> id = id')"
begin

definition "the_singleton \<equiv> THE id. \<forall>k. \<forall>id'. \<parallel>id'\<parallel>\<^bsub>k\<^esub> \<longrightarrow> id' = id"

lemma the_unique:
  fixes k::cnf and id::'id
  assumes "\<parallel>id\<parallel>\<^bsub>k\<^esub>"
  shows "id = the_singleton"
proof -
  have "(THE id. \<forall>k. \<forall>id'. \<parallel>id'\<parallel>\<^bsub>k\<^esub> \<longrightarrow> id' = id) = id"
  proof (rule the_equality)
    show "\<forall>k id'. \<parallel>id'\<parallel>\<^bsub>k\<^esub> \<longrightarrow> id' = id"
    proof
      fix k show "\<forall>id'. \<parallel>id'\<parallel>\<^bsub>k\<^esub> \<longrightarrow> id' = id"
      proof
        fix id' show "\<parallel>id'\<parallel>\<^bsub>k\<^esub> \<longrightarrow> id' = id"
        proof
          assume "\<parallel>id'\<parallel>\<^bsub>k\<^esub>"
          from unique have "\<exists>id. \<forall>k. \<forall>id'. (\<parallel>id'\<parallel>\<^bsub>k\<^esub> \<longrightarrow> id = id')" .
          then obtain i'' where "\<forall>k. \<forall>id'. (\<parallel>id'\<parallel>\<^bsub>k\<^esub> \<longrightarrow> i'' = id')" by auto
          with `\<parallel>id'\<parallel>\<^bsub>k\<^esub>` have "id=i''" and "id'=i''" using assms by auto
          thus "id' = id" by simp
        qed
      qed
    qed
  next
    fix i'' show "\<forall>k id'. \<parallel>id'\<parallel>\<^bsub>k\<^esub> \<longrightarrow> id' = i'' \<Longrightarrow> i'' = id" using assms by auto
  qed
  thus ?thesis by (simp add: the_singleton_def)
qed

lemma the_active[simp]:
  fixes k
  shows "\<parallel>the_singleton\<parallel>\<^bsub>k\<^esub>"
proof -
  from alwaysActive obtain id where "\<parallel>id\<parallel>\<^bsub>k\<^esub>" by blast
  with the_unique have "id = the_singleton" by simp
  with `\<parallel>id\<parallel>\<^bsub>k\<^esub>` show ?thesis by simp
qed
  
lemma lNact_active[simp]:
  fixes cid t n
  shows "\<langle>the_singleton \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> = n"
  using lNact_active the_active by auto

lemma lNxt_active[simp]:
  fixes cid t n
  shows "\<langle>the_singleton \<rightarrow> t\<rangle>\<^bsub>n\<^esub> = n"
by (simp add: nxtAct_active)
    
lemma assI[intro]:
  fixes t n a
  assumes "\<phi> (\<sigma>\<^bsub>the_singleton\<^esub>(t n))"
  shows "eval the_singleton t t' n (ass \<phi>)" using assms by (simp add: assIANow)
  
lemma assE[elim]:
  fixes t n a
  assumes "eval the_singleton t t' n (ass \<phi>)"                      
  shows "\<phi> (\<sigma>\<^bsub>the_singleton\<^esub>(t n))" using assms by (simp add: assEANow)

lemma evtE[elim]:
  fixes t id n a
  assumes "eval the_singleton t t' n (evt \<gamma>)"
  shows "\<exists>n'\<ge>n. eval the_singleton t t' n' \<gamma>"
proof -
  have "\<parallel>the_singleton\<parallel>\<^bsub>t n\<^esub>" by simp
  with assms obtain n' where "n'\<ge>\<langle>the_singleton \<rightarrow> t\<rangle>\<^bsub>n\<^esub>" and "(\<exists>i\<ge>n'. \<parallel>the_singleton\<parallel>\<^bsub>t i\<^esub> \<and>
    (\<forall>n''\<ge>\<langle>the_singleton \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>. n'' \<le> \<langle>the_singleton \<rightarrow> t\<rangle>\<^bsub>n'\<^esub> \<longrightarrow> eval the_singleton t t' n'' \<gamma>)) \<or>
    \<not> (\<exists>i\<ge>n'. \<parallel>the_singleton\<parallel>\<^bsub>t i\<^esub>) \<and> eval the_singleton t t' n' \<gamma>" using evtEA[of n "the_singleton" t] by blast
  moreover have "\<parallel>the_singleton\<parallel>\<^bsub>t n'\<^esub>" by simp
  ultimately have
    "\<forall>n''\<ge>\<langle>the_singleton \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>. n'' \<le> \<langle>the_singleton \<rightarrow> t\<rangle>\<^bsub>n'\<^esub> \<longrightarrow> eval the_singleton t t' n'' \<gamma>" by auto
  hence "eval the_singleton t t' n' \<gamma>" by simp
  moreover from `n'\<ge>\<langle>the_singleton \<rightarrow> t\<rangle>\<^bsub>n\<^esub>` have "n'\<ge>n" by (simp add: nxtAct_active)
  ultimately show ?thesis by auto
qed
  
lemma globE[elim]:
  fixes t id n a
  assumes "eval the_singleton t t' n (glob \<gamma>)"
  shows "\<forall>n'\<ge>n. eval the_singleton t t' n' \<gamma>"
proof
  fix n' show "n \<le> n' \<longrightarrow> eval the_singleton t t' n' \<gamma>"
  proof
    assume "n\<le>n'"
    hence "\<langle>the_singleton \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<le> n'" by simp
    moreover have "\<parallel>the_singleton\<parallel>\<^bsub>t n\<^esub>" by simp
    ultimately show "eval the_singleton t t' n' \<gamma>"
      using `eval the_singleton t t' n (glob \<gamma>)` globEA by blast
  qed
qed

lemma untilI[intro]:
  fixes t::"nat \<Rightarrow> cnf"
    and t'::"nat \<Rightarrow> 'cmp"
    and n::nat
    and n'::nat
  assumes "n'\<ge>n"
    and "eval the_singleton t t' n' \<gamma>"
    and "\<And>n''. \<lbrakk>n\<le>n''; n''<n'\<rbrakk> \<Longrightarrow> eval the_singleton t t' n'' \<gamma>'"
  shows "eval the_singleton t t' n (\<gamma>' \<UU> \<gamma>)"
proof -
  have "\<parallel>the_singleton\<parallel>\<^bsub>t n\<^esub>" by simp 
  moreover from `n'\<ge>n` have "\<langle>the_singleton \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<le> n'" by simp
  moreover have "\<parallel>the_singleton\<parallel>\<^bsub>t n'\<^esub>" by simp
  moreover have
    "\<exists>n''\<ge>\<langle>the_singleton \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>. n'' \<le> \<langle>the_singleton \<rightarrow> t\<rangle>\<^bsub>n'\<^esub> \<and> eval the_singleton t t' n'' \<gamma> \<and>
    (\<forall>n'''\<ge>\<langle>the_singleton \<rightarrow> t\<rangle>\<^bsub>n\<^esub>. n''' < \<langle>the_singleton \<Leftarrow> t\<rangle>\<^bsub>n''\<^esub> \<longrightarrow>
      (\<exists>n''''\<ge>\<langle>the_singleton \<Leftarrow> t\<rangle>\<^bsub>n'''\<^esub>. n'''' \<le> \<langle>the_singleton \<rightarrow> t\<rangle>\<^bsub>n'''\<^esub> \<and> eval the_singleton t t' n'''' \<gamma>'))"
  proof -
    have "n'\<ge>\<langle>the_singleton \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>" by simp
    moreover have "n' \<le> \<langle>the_singleton \<rightarrow> t\<rangle>\<^bsub>n'\<^esub>" by simp
    moreover from assms(3) have "(\<forall>n''\<ge>\<langle>the_singleton \<rightarrow> t\<rangle>\<^bsub>n\<^esub>. n'' < \<langle>the_singleton \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub> \<longrightarrow>
      (\<exists>n'''\<ge>\<langle>the_singleton \<Leftarrow> t\<rangle>\<^bsub>n''\<^esub>. n''' \<le> \<langle>the_singleton \<rightarrow> t\<rangle>\<^bsub>n''\<^esub> \<and> eval the_singleton t t' n''' \<gamma>'))"
      by auto
    ultimately show ?thesis using `eval the_singleton t t' n' \<gamma>` by auto
  qed
  ultimately show ?thesis using untilIA[of n "the_singleton" t n' t' \<gamma> \<gamma>'] by blast
qed

lemma untilE[elim]:
  fixes t id n \<gamma>' \<gamma>
  assumes "eval the_singleton t t' n (until \<gamma>' \<gamma>)"
  shows "\<exists>n'\<ge>n. eval the_singleton t t' n' \<gamma> \<and> (\<forall>n''\<ge>n. n'' < n' \<longrightarrow> eval the_singleton t t' n'' \<gamma>')"
proof -
  have "\<parallel>the_singleton\<parallel>\<^bsub>t n\<^esub>" by simp
  with `eval the_singleton t t' n (until \<gamma>' \<gamma>)` obtain n' where "n'\<ge>\<langle>the_singleton \<rightarrow> t\<rangle>\<^bsub>n\<^esub>" and
   "(\<exists>i\<ge>n'. \<parallel>the_singleton\<parallel>\<^bsub>t i\<^esub>) \<and>
   (\<forall>n''\<ge>\<langle>the_singleton \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>. n'' \<le> \<langle>the_singleton \<rightarrow> t\<rangle>\<^bsub>n'\<^esub> \<longrightarrow> eval the_singleton t t' n'' \<gamma>) \<and>
   (\<forall>n''\<ge>\<langle>the_singleton \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>. n'' < \<langle>the_singleton \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub> \<longrightarrow> eval the_singleton t t' n'' \<gamma>') \<or>
   \<not> (\<exists>i\<ge>n'. \<parallel>the_singleton\<parallel>\<^bsub>t i\<^esub>) \<and>
   eval the_singleton t t' n' \<gamma> \<and> (\<forall>n''\<ge>\<langle>the_singleton \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>. n'' < n' \<longrightarrow> eval the_singleton t t' n'' \<gamma>')"
  using untilEA[of n "the_singleton" t t' \<gamma>' \<gamma>] by auto
  moreover have "\<parallel>the_singleton\<parallel>\<^bsub>t n'\<^esub>" by simp
  ultimately have
    "(\<forall>n''\<ge>\<langle>the_singleton \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>. n'' \<le> \<langle>the_singleton \<rightarrow> t\<rangle>\<^bsub>n'\<^esub> \<longrightarrow> eval the_singleton t t' n'' \<gamma>) \<and>
    (\<forall>n''\<ge>\<langle>the_singleton \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>. n'' < \<langle>the_singleton \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub> \<longrightarrow> eval the_singleton t t' n'' \<gamma>')" by auto
  hence "eval the_singleton t t' n' \<gamma>" and "(\<forall>n''\<ge>n. n'' < n' \<longrightarrow> eval the_singleton t t' n'' \<gamma>')" by auto
  with `eval the_singleton t t' n' \<gamma>` `n'\<ge>\<langle>the_singleton \<rightarrow> t\<rangle>\<^bsub>n\<^esub>` show ?thesis by auto
qed
end

end
