Require Import CoqlibC.
Require Import Simulation.
Require Import LinkingC.
Require Import Skeleton.
Require Import Values.
Require Import JMeq.
Require Import Smallstep.
Require Import Integers.
Require Import Events.

Require Import Skeleton ModSem Mod Sem.
Require Import SimSymb SimMem SimMod SimModSem SimProg (* SimLoad *) SimProg.
Require Import SemProps Ord.
Require Import Sound Preservation.
Require Import Memory.

Set Implicit Arguments.




Section ADQSOUND.

  Context `{SM: SimMem.class}.
  Context {SS: SimSymb.class SM}.
  Context `{SU: Sound.class}.

  Variable pp: ProgPair.t.
  Hypothesis SIMPROG: ProgPair.sim pp.
  Let p_src := pp.(ProgPair.src).
  Let p_tgt := pp.(ProgPair.tgt).
  Hypothesis (WFSKSRC: forall md (IN: In md p_src), <<WF: Sk.wf md>>).
  Hypothesis (WFSKTGT: forall md (IN: In md p_tgt), <<WF: Sk.wf md>>).

  Variable sk_link_src sk_link_tgt: Sk.t.
  Hypothesis LINKSRC: (link_sk p_src) = Some sk_link_src.
  Hypothesis LINKTGT: (link_sk p_tgt) = Some sk_link_tgt.
  Let sem_src := Sem.sem p_src.
  Let sem_tgt := Sem.sem p_tgt.

  Let skenv_link_src := sk_link_src.(Sk.load_skenv).
  Let skenv_link_tgt := sk_link_tgt.(Sk.load_skenv).

  Variable ss_link: SimSymb.t.
  Hypothesis (SIMSKENV: exists sm, SimSymb.sim_skenv sm ss_link skenv_link_src skenv_link_tgt).

  Hypothesis INCLSRC: forall mp (IN: In mp pp), SkEnv.includes skenv_link_src mp.(ModPair.src).(Mod.sk).
  Hypothesis INCLTGT: forall mp (IN: In mp pp), SkEnv.includes skenv_link_tgt mp.(ModPair.tgt).(Mod.sk).
  Hypothesis SSLE: forall mp (IN: In mp pp), SimSymb.le mp.(ModPair.ss) mp.(ModPair.src) mp.(ModPair.tgt) ss_link.

  Let WFSKLINKSRC: Sk.wf sk_link_src. eapply link_list_preserves_wf_sk; et. Qed.
  Let WFSKLINKTGT: Sk.wf sk_link_tgt. eapply link_list_preserves_wf_sk; et. Qed.

  (* Let ge: Ge.t := sem_src.(Smallstep.globalenv). *)

  Inductive sound_ge (su0: Sound.t) (m0: mem): Prop :=
  | sound_ge_intro
      (GE: Forall (fun ms => su0.(Sound.skenv) m0 ms.(ModSem.skenv)) sem_src.(Smallstep.globalenv).(fst)).

  Lemma lepriv_preserves_sound_ge
        m0 su0 su1
        (GE: sound_ge su0 m0)
        (LE: Sound.lepriv su0 su1):
      <<GE: sound_ge su1 m0>>.
  Proof.
    inv GE. econs; eauto. rewrite Forall_forall in *. ii. eapply Sound.skenv_lepriv; eauto.
  Qed.

  Lemma hle_preserves_sound_ge
        m0 su0 su1
        (WF: Sound.wf su0)
        (GE: sound_ge su0 m0)
        (LE: Sound.hle su0 su1):
      <<GE: sound_ge su1 m0>>.
  Proof.
    eapply lepriv_preserves_sound_ge; eauto. eapply Sound.hle_lepriv; et.
  Qed.

  Lemma mle_preserves_sound_ge
        m0 m1 su0
        (GE: sound_ge su0 m0)
        (LE: Sound.mle su0 m0 m1):
      <<GE: sound_ge su0 m1>>.
  Proof.
    inv GE. econs; eauto. rewrite Forall_forall in *. ii. eapply Sound.skenv_mle; eauto.
  Qed.

  (* stack can go preservation when su0 is given *)
  Inductive sound_stack (args: Args.t): list Frame.t -> Prop :=
  | sound_stack_nil
      (EXSU: exists su_ex, Sound.args su_ex args /\ sound_ge su_ex args.(Args.get_m)):
      sound_stack args []
  | sound_stack_cons
      args_tail tail ms lst0
      (TL: sound_stack args_tail tail)
      (FORALLSU: forall su0
          (SUARGS: Sound.args su0 args_tail)
          (SUGE: sound_ge su0 args_tail.(Args.get_m)),
          (<<HD: forall
                 sound_state_all
                 (PRSV: local_preservation_noguarantee ms sound_state_all),
                 <<SUST: sound_state_all su0 args_tail.(Args.get_m) lst0>>>>)
          /\
          (<<K: forall
                 sound_state_all
                 (PRSV: local_preservation_noguarantee ms sound_state_all),
                 (* (<<SUST: sound_state_all su0 args.(Args.get_m) lst0>>) *)
                 (* /\ *)
                 exists su_gr,
                   (<<ARGS: Sound.args su_gr args>>) /\
                   (<<LE: Sound.lepriv su0 su_gr>>) /\
                   (<<K: forall retv lst1 su_ret
                       (LE: Sound.hle su_gr su_ret)
                       (SURETV: Sound.retv su_ret retv)
                       (MLE: Sound.mle su_gr args.(Args.get_m) retv.(Retv.get_m))
                       (AFTER: ms.(ModSem.after_external) lst0 retv lst1),
                       (* sound_state_all su0 args.(Args.get_m) lst1>>) *)
                       sound_state_all su0 args_tail.(Args.get_m) lst1>>)
             >>)
          /\
          (<<MLE: Sound.mle su0 args_tail.(Args.get_m) args.(Args.get_m)>>)
      )
      (EXSU: exists su_ex, Sound.args su_ex args_tail /\ sound_ge su_ex args_tail.(Args.get_m))
      (EX: exists sound_state_ex, local_preservation ms sound_state_ex):
      sound_stack args ((Frame.mk ms lst0) :: tail).

  Inductive sound_state: mem -> state -> Prop :=
  | sound_state_normal
      args_tail tail ms lst0 m_arg
      (TL: sound_stack args_tail tail)
      (EXSU: exists su_ex, Sound.args su_ex args_tail /\ sound_ge su_ex m_arg)
      (FORALLSU: forall su0
          (SUARGS: Sound.args su0 args_tail)
          (SUGE: sound_ge su0 args_tail.(Args.get_m)),
          (<<HD: forall
              sound_state_all
              (PRSV: local_preservation_noguarantee ms sound_state_all),
              <<SUST: sound_state_all su0 m_arg lst0>>>>))
      (EX: exists sound_state_ex, local_preservation ms sound_state_ex)
      (ABCD: args_tail.(Args.get_m) = m_arg)
    :
      sound_state m_arg (State ((Frame.mk ms lst0) :: tail))
  | sound_state_call
      m_tail frs args
      (* (ARGS: Sound.args su0 args) *)
      (STK: sound_stack args frs)
      (* (MLE: Sound.mle su0 m_tail args.(Args.get_m)) *)
      (EQ: args.(Args.get_m) = m_tail)
      (EXSU: exists su_ex, Sound.args su_ex args /\ sound_ge su_ex m_tail):
      sound_state m_tail (Callstate args frs).

  Lemma sound_init
        st0
        (INIT: sem_src.(Smallstep.initial_state) st0):
      exists m_init0, <<MEM: Sk.load_mem sk_link_src = Some m_init0>> /\ <<SU: sound_state m_init0 st0>>.
  Proof.
    inv INIT. clarify. clear skenv_link_tgt p_tgt skenv_link_tgt sem_tgt LINKTGT INCLTGT WFSKTGT SIMSKENV.
    hexploit Sound.init_spec; eauto. i; des. esplits; eauto.
    assert(WFSKE: SkEnv.wf (Sk.load_skenv sk_link_src)).
    { eapply SkEnv.load_skenv_wf; et. }
    assert(GE: sound_ge su_init m_init).
    { econs. rewrite Forall_forall. intros ? IN. ss. des_ifs. u in IN.
      rewrite in_map_iff in IN. des; ss; clarify.
      + s. rewrite <- Sound.system_skenv; eauto.
      + assert(INCL: SkEnv.includes (Sk.load_skenv sk_link_src) x0.(Mod.sk)).
        { unfold p_src in IN0. unfold ProgPair.src in *. rewrite in_map_iff in IN0. des. clarify. eapply INCLSRC; et. }
        eapply Sound.skenv_project; eauto.
        { eapply link_load_skenv_wf_mem; et. }
        rewrite <- Mod.get_modsem_skenv_spec; ss. eapply SkEnv.project_impl_spec; et.
    }
    econs; eauto. econs; eauto.
    (* - eapply Sound.greatest_adq; eauto. *)
    (* - econs; eauto. *)
    (* - eapply vle_preserves_sound_ge; eauto. *)
    (*   eapply Sound.greatest_adq; eauto. *)
  Unshelve.
    all: ss.
  Qed.

  Lemma sound_progress
        st0 m_arg0 tr st1
        (SUST: sound_state m_arg0 st0)
        (STEP: Step sem_src st0 tr st1):
      <<SUST: exists m_arg1, sound_state m_arg1 st1>>.
  Proof.
    inv STEP.
    - (* CALL *)
      inv SUST. ss. des. exploit FORALLSU; eauto. { eapply local_preservation_noguarantee_weak; eauto. } intro T; des.
      inv EX. exploit CALL; eauto. i; des. esplits; eauto. econs; eauto; cycle 1.
      + esplits; eauto. eapply lepriv_preserves_sound_ge; eauto.
        { eapply mle_preserves_sound_ge; eauto. }
      + econs; eauto; cycle 1.
        { esplits; eauto. econs; eauto. }
        ii. esplits; eauto.
        * ii. exploit FORALLSU; try apply SUARGS; eauto.
        * ii. exploit FORALLSU; try apply SUARGS; eauto. intro U; des.
          inv PRSV. exploit CALL0; eauto. i; des. esplits; eauto. ii. eapply K0; eauto.
        * exploit FORALLSU; eauto.
          { eapply local_preservation_noguarantee_weak; eauto. econs; eauto. }
          i; des. exploit CALL; eauto. i; des. ss.
    - (* INIT *)
      inv SUST. ss. des_ifs. esplits; eauto. econs; eauto.
      + ii. esplits; eauto.
        * ii. inv PRSV. eapply INIT0; eauto. inv SUGE. rewrite Forall_forall in *. eapply GE. inv MSFIND. ss. des_ifs.
      + inv MSFIND. ss. rr in SIMPROG. rewrite Forall_forall in *. des; clarify.
        { eapply system_local_preservation. }
        u in MODSEM. rewrite in_map_iff in MODSEM. des; clarify. rename x into md_src.
        assert(exists mp, In mp pp /\ mp.(ModPair.src) = md_src).
        { clear - MODSEM0. rr in pp. rr in p_src. subst p_src. rewrite in_map_iff in *. des. eauto. }
        des. exploit SIMPROG; eauto. intros MPSIM. inv MPSIM.
        destruct SIMSKENV. exploit SIMMS.
        { eapply INCLSRC; et. }
        { eapply INCLTGT; et. }
        { eapply SkEnv.load_skenv_wf; et. }
        { eapply SkEnv.load_skenv_wf; et. }
        { eapply SSLE; eauto. }
        { eauto. }
        intro SIM; des. inv SIM. ss. esplits; eauto.
    - (* INTERNAL *)
      inv SUST. ss. esplits; eauto. econs; eauto. i. des.
      exploit FORALLSU; eauto. { eapply local_preservation_noguarantee_weak; eauto. } intro U; des. esplits; eauto. i. ss. inv PRSV.
      eapply STEP; eauto.
      + eapply FORALLSU; eauto. econs; eauto.
      + split; ii; ModSem.tac.
    - (* RETURN *)
      inv SUST. ss. rename ms into ms_top. rename args_tail into args_tail_top.
      inv TL. ss. unfold Frame.update_st. s. des. esplits; eauto. econs; eauto. ii. esplits; eauto.
      + ii. exploit FORALLSU0; eauto. i; des. exploit K; eauto. i; des. inv EX.
        exploit RET; eauto.
        { eapply FORALLSU; eauto.
          { eapply lepriv_preserves_sound_ge. { eapply mle_preserves_sound_ge; eauto. } eauto. }
          { eapply local_preservation_noguarantee_weak; eauto. econs; et. } }
        i; des.
        eapply K0; eauto.
  Unshelve.
    all: ss.
  Qed.

  Lemma sound_progress_star
        st0 m_arg0 tr st1
        (SUST: sound_state m_arg0 st0)
        (STEP: Star sem_src st0 tr st1):
      <<SUST: exists m_arg1, sound_state m_arg1 st1>>.
  Proof.
    generalize dependent m_arg0. induction STEP.
    - esplits; eauto.
    - clarify. i. exploit sound_progress; eauto. i; des. eapply IHSTEP; eauto.
  Qed.

  Lemma sound_progress_plus
        st0 m_arg0 tr st1
        (SUST: sound_state m_arg0 st0)
        (STEP: Plus sem_src st0 tr st1):
      <<SUST: exists m_arg1, sound_state m_arg1 st1>>.
  Proof.
    eapply sound_progress_star; eauto. eapply plus_star; eauto.
  Qed.

End ADQSOUND.
