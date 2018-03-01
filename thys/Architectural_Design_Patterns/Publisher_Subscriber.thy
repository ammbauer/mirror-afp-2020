section "A Theory of Publisher-Subscriber Architectures"
text{*
  In the following, we formalize the specification of the publisher subscriber pattern as described in~\cite{Marmsoler2018c}.
*}
  
theory Publisher_Subscriber
imports Singleton
begin

subsection "Subscriptions"

datatype ('id, 'evt) subscription = sub 'id 'evt | unsub 'id 'evt

subsection "Publisher-Subscriber Architectures"

locale publisher_subscriber =
  pb: singleton pbactive pbcmp +
  sb: dynamic_component sbcmp sbactive
    for pbactive :: "'pid \<Rightarrow> cnf \<Rightarrow> bool"
    and pbcmp :: "'pid \<Rightarrow> cnf \<Rightarrow> 'PB"
    and sbactive :: "'sid \<Rightarrow> cnf \<Rightarrow> bool"
    and sbcmp :: "'sid \<Rightarrow> cnf \<Rightarrow> 'SB" +
  fixes pbsb :: "'PB \<Rightarrow> ('sid,'evt set) subscription set"
    and pbnt :: "'PB \<Rightarrow> ('evt \<times> 'msg) set"             
    and sbnt :: "'SB \<Rightarrow> ('evt \<times> 'msg) set"
    and sbsb :: "'SB \<Rightarrow> ('sid,'evt set) subscription"
  assumes conn1: "\<And>k pid. pbactive pid k
      \<Longrightarrow> pbsb (pbcmp pid k) = (\<Union>sid\<in>{sid. sbactive sid k}. {sbsb (sbcmp sid k)})"
    and conn2: "\<And>t n n'' sid pid E e m.
      \<lbrakk>t \<in> arch; sbactive sid (t n); sub sid E = sbsb (sbcmp sid (t n)); n''\<ge> n; e \<in> E;
      \<nexists>n' E'. n' \<ge> n \<and> n' \<le> n'' \<and> sbactive sid (t n') \<and> unsub sid E' = sbsb (sbcmp sid (t n')) \<and> e \<in> E';
      (e, m) \<in> pbnt (pbcmp pid (t n'')); sbactive sid (t n'')\<rbrakk>
      \<Longrightarrow> sbnt (sbcmp sid (t n'')) = pbnt (pbcmp pid (t n''))"
begin

notation pb.imp (infixl "\<longrightarrow>\<^sup>p" 10)
notation pb.or (infixl "\<or>\<^sup>p" 15)
notation pb.and (infixl "\<and>\<^sup>p" 20)
notation pb.not ("\<not>\<^sup>p _" [19]19)
no_notation pb.all (binder "\<forall>\<^sub>b" 10)
no_notation pb.exists (binder "\<exists>\<^sub>b" 10)
notation pb.all (binder "\<forall>\<^sub>p" 10)
notation pb.exists (binder "\<exists>\<^sub>p" 10)

notation sb.imp (infixl "\<longrightarrow>\<^sup>s" 10)
notation sb.or (infixl "\<or>\<^sup>s" 15)  
notation sb.and (infixl "\<and>\<^sup>s" 20)
notation sb.not ("\<not>\<^sup>s _" [19]19)
no_notation sb.all (binder "\<forall>\<^sub>b" 10)
no_notation sb.exists (binder "\<exists>\<^sub>b" 10)
notation sb.all (binder "\<forall>\<^sub>s" 10)
notation sb.exists (binder "\<exists>\<^sub>s" 10)

abbreviation the_publisher :: "'pid" where
"the_publisher \<equiv> pb.the_singleton"

text {*
  The following theorem ensures that a subscriber indeed receives all messages associated with an event for which he is subscribed.
*}
theorem msgDelivery:
  fixes t n n'' sid E e m
  assumes "t \<in> arch"
    and "sbactive sid (t n)"
    and "sub sid E = sbsb (sbcmp sid (t n))"
    and "n'' \<ge> n"
    and "\<nexists>n' E'. n' \<ge> n \<and> n' \<le> n'' \<and> sbactive sid (t n') \<and> unsub sid E' = sbsb(sbcmp sid (t n'))
          \<and> e \<in> E'"
    and "e \<in> E"
    and "(e,m) \<in> pbnt (pbcmp the_publisher (t n''))"
    and "sbactive sid (t n'')"
  shows "(e,m) \<in> sbnt (sbcmp sid (t n''))" using assms conn2 by simp

text {*
  Since a publisher is actually a singleton, we can provide an alternative version of constraint @{thm[source] conn1}.
*}
lemma conn1A:
  fixes k
  shows "pbsb (pbcmp the_publisher k) = (\<Union>sid\<in>{sid. sbactive sid k}. {sbsb (sbcmp sid k)})"
  using conn1[OF pb.the_active] .
end
  
end