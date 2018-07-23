Require Import CoqlibC.
Require Import SmallstepC.
Require Import Simulation.
Require Import Mod ModSem AsmregsC GlobalenvsC MemoryC ASTC.
Require Import Skeleton SimMod SimModSem SimMem SimSymb.

Set Implicit Arguments.


Section MATCHSIMFORWARD.

  Context {SM: SimMem.class} {SS: SimSymb.class SM}.

  Variable mp: ModPair.t.
  Variable skenv_link_src skenv_link_tgt: SkEnv.t.
  Variable sm_init_link: SimMem.t.
  Let msp: ModSemPair.t := (ModPair.to_msp skenv_link_src skenv_link_tgt sm_init_link mp).
  Variable index: Type.
  Variable order: index -> index -> Prop.
  Hypothesis WFORD: well_founded order.
  Let ms_src: ModSem.t := msp.(ModSemPair.src).
  Let ms_tgt: ModSem.t := msp.(ModSemPair.tgt).

  Hypothesis SIMSK: SimSymb.sim_sk mp.(ModPair.ss) mp.(ModPair.src) mp.(ModPair.tgt).

  Variable match_states: forall
      (sm_arg: SimMem.t)
      (idx: index) (st_src0: ms_src.(ModSem.state)) (st_tgt0: ms_tgt.(ModSem.state)) (sm0: SimMem.t)
    ,
      Prop
  .

  Hypothesis INITBSIM: forall
      sm_arg
      (SIMSKENVLINK: exists ss_link,
          <<SSLE: SimSymb.le mp.(ModPair.ss) mp.(ModPair.src) mp.(ModPair.tgt) ss_link>>
          /\ <<SIMSKENVLINK: SimSymb.sim_skenv sm_arg ss_link skenv_link_src skenv_link_tgt>>)
      (SIMSKENV: ModSemPair.sim_skenv msp sm_arg)
      (MWF: SimMem.wf sm_arg)
      args_src args_tgt
      (SIMARGS: sim_args args_src args_tgt sm_arg)
      st_init_tgt
      (INITTGT: ms_tgt.(ModSem.initial_frame) args_tgt st_init_tgt)
    ,
      exists st_init_src sm_init idx_init,
        (<<INITSRC: ms_src.(ModSem.initial_frame) args_src st_init_src>>)
        /\
        (<<MLE: SimMem.le sm_arg sm_init>>)
        /\
        (<<MATCH: match_states sm_arg
                               idx_init st_init_src st_init_tgt sm_init>>)
  .

  Hypothesis INITPROGRESS: forall
      sm_arg
      (SIMSKENV: ModSemPair.sim_skenv msp sm_arg)
      (MWF: SimMem.wf sm_arg)
      args_src args_tgt
      (SIMARGS: sim_args args_src args_tgt sm_arg)
      (SAFESRC: exists st_init_src, ms_src.(ModSem.initial_frame) args_src st_init_src)
    ,
      exists st_init_tgt,
        (<<INITTGT: ms_tgt.(ModSem.initial_frame) args_tgt st_init_tgt>>)
  .

  Hypothesis ATFSIM: forall
      sm_init
      idx0 st_src0 st_tgt0 sm0
      (MATCH: match_states sm_init idx0 st_src0 st_tgt0 sm0)
      args_src
      (CALLSRC: ms_src.(ModSem.at_external) st_src0 args_src)
    ,
      (<<MWF: SimMem.wf sm0>>)
      /\
      exists args_tgt sm_arg,
        (<<CALLTGT: ms_tgt.(ModSem.at_external) st_tgt0 args_tgt>>)
        /\
        (<<SIMARGS: sim_args args_src args_tgt sm_arg>>)
        /\
        (<<MLE: SimMem.le sm0 sm_arg>>)
        /\
        (<<MWF: SimMem.wf sm_arg>>)
  .

  Hypothesis AFTERFSIM: forall
      sm_init
      idx0 st_src0 st_tgt0 sm0
      (MATCH: match_states sm_init idx0 st_src0 st_tgt0 sm0)
      sm_arg
      (MLE: SimMem.le sm0 sm_arg)
      (* (MWF: SimMem.wf sm_arg) *)
      sm_ret
      (MLE: SimMem.le (SimMem.lift sm_arg) sm_ret)
      (MWF: SimMem.wf sm_ret)
      retv_src retv_tgt
      (SIMRSRET: sim_retv retv_src retv_tgt sm_ret)
      st_src1
      (AFTERSRC: ms_src.(ModSem.after_external) st_src0 retv_src st_src1)
    ,
      exists idx1 st_tgt1,
        (<<AFTERTGT: ms_tgt.(ModSem.after_external) st_tgt0 retv_tgt st_tgt1>>)
        /\
        (<<MATCH: match_states sm_init idx1 st_src1 st_tgt1 (SimMem.unlift sm_arg sm_ret)>>)
  .

  Hypothesis FINALFSIM: forall
      sm_init
      idx0 st_src0 st_tgt0 sm0
      (MATCH: match_states sm_init idx0 st_src0 st_tgt0 sm0)
      retv_src
      (FINALSRC: ms_src.(ModSem.final_frame) st_src0 retv_src)
    ,
      exists retv_tgt,
        (<<FINALTGT: ms_tgt.(ModSem.final_frame) st_tgt0 retv_tgt>>)
        /\
        (<<SIMRS: sim_retv retv_src retv_tgt sm0>>)
        /\
        (<<MWF: SimMem.wf sm0>>)
  .

  Hypothesis STEPFSIM: forall
      sm_init idx0 st_src0 st_tgt0 sm0
      (NOTCALL: ~ ModSem.is_call ms_src st_src0)
      (NOTRET: ~ ModSem.is_return ms_src st_src0)
      (MATCH: match_states sm_init idx0 st_src0 st_tgt0 sm0)
    ,
      (<<RECEP: receptive_at ms_src st_src0>>)
      /\
      (<<STEPFSIM: forall
             tr st_src1
             (STEPSRC: Step ms_src st_src0 tr st_src1)
           ,
             exists idx1 st_tgt1 sm1,
               (<<PLUS: DPlus ms_tgt st_tgt0 tr st_tgt1>> \/
                           <<STAR: DStar ms_tgt st_tgt0 tr st_tgt1 /\ order idx1 idx0>>)
               /\ (<<MLE: SimMem.le sm0 sm1>>)
               (* Note: We require le for mle_preserves_sim_ge, but we cannot require SimMem.wf, beacuse of DCEproof *)
               /\ (<<MATCH: match_states sm_init idx1 st_src1 st_tgt1 sm1>>)
                    >>)
  .

  Hypothesis BAR: bar_True.

  Definition to_idx (i0: index): Ord.idx := (Ord.mk WFORD i0).

  Hint Unfold to_idx.

  Lemma to_idx_spec
        i0 i1
        (ORD: order i0 i1)
    :
      <<ORD: Ord.ord i0.(to_idx) i1.(to_idx)>>
  .
  Proof.
    econs; eauto. cbn. instantiate (1:= eq_refl). cbn. ss.
  Qed.

  Lemma match_states_lxsim
        sm_init i0 st_src0 st_tgt0 sm0
        (SIMSKENV: ModSemPair.sim_skenv msp sm0)
        (MLE: SimMem.le sm_init sm0)
        (* (MWF: SimMem.wf sm0) *)
        (* (MCOMPAT: mem_compat st_src0 st_tgt0 sm0) *)
        (MATCH: match_states sm_init i0 st_src0 st_tgt0 sm0)
    :
      <<LXSIM: lxsim ms_src ms_tgt sm_init i0.(to_idx) st_src0 st_tgt0 sm0>>
  .
  Proof.
    revert_until BAR.
    pcofix CIH. i. pfold.
    generalize (classic (ModSem.is_call ms_src st_src0)). intro CALLSRC; des.
    {
      - u in CALLSRC. des.
        exploit ATFSIM; eauto. i; des.
        eapply lxsim_at_external; eauto.
        i.
        determ_tac ModSem.at_external_dtm. clear_tac.
        esplits; eauto. i.
        exploit AFTERFSIM; try apply SAFESRC; try apply SIMRS; eauto.
        i; des.
        esplits; eauto.
        right.
        eapply CIH; eauto.
        { eapply SimSymb.mle_preserves_sim_skenv; eauto.
          etransitivity; eauto. eapply SimMem.unlift_spec; eauto. }
        { etransitivity; cycle 1.
          - eapply SimMem.unlift_spec; eauto.
          - etransitivity; eauto.
        }
    }
    generalize (classic (ModSem.is_return ms_src st_src0)). intro RETSRC; des.
    {
      u in RETSRC. des.
      exploit FINALFSIM; eauto. i; des.
      eapply lxsim_final; eauto.
    }
    {
      eapply lxsim_step_forward; eauto.
      exploit STEPFSIM; eauto. i; des.
      econs 1; eauto.
      ii. exploit STEPFSIM0; eauto. i; des_safe.
      esplits; eauto.
      - des.
        + left. eauto.
        + right. esplits; eauto. eapply to_idx_spec; eauto.
      - right. eapply CIH; eauto.
        { eapply SimSymb.mle_preserves_sim_skenv; eauto. }
        { etransitivity; eauto. }
    }
  Qed.

  Theorem match_states_sim_mp
    :
      <<SIM: mp.(ModPair.sim)>>
  .
  Proof.
    econs; eauto.
    ii; ss.
    assert(SIMSKENV: ModSemPair.sim_skenv (ModPair.to_msp skenv_link_src0 skenv_link_tgt0 sm_init_link0 mp)
                                          sm_init_link0).
    { u.
      eapply SimSymb.sim_skenv_monotone; eauto.
      - admit "ez".
      - admit "ez".
      - eapply Mod.get_modsem_projected_sk.
      - eapply Mod.get_modsem_projected_sk.
    }
    econs; eauto.
    ii.
    assert(SIMSKENV0: ModSemPair.sim_skenv (ModPair.to_msp skenv_link_src0 skenv_link_tgt0 sm_init_link0 mp)
                                          sm_arg).
    { eapply SimSymb.mfuture_preserves_sim_skenv; eauto. }
    exploit SimSymb.sim_skenv_func_bisim; try apply SIMSKENV0; eauto. intro FSIM; des.
    inv FSIM. exploit FUNCFSIM; eauto. { apply SIMARGS. } i; des. clarify.
    split; ii.
    - exploit INITBSIM; eauto.
      { esplits; eauto. eapply SimSymb.mfuture_preserves_sim_skenv; eauto. ss. }
      i; des.
      esplits; eauto.
      eapply match_states_lxsim; eauto.
      { eapply SimSymb.mle_preserves_sim_skenv; eauto. }
    - exploit INITPROGRESS; eauto.
  Qed.


  Theorem match_states_sim_msp
    :
      <<SIM: msp.(ModSemPair.sim)>>
  .
  Proof.
    econs.
    ii; ss.
    u in SIMSKENV.
    exploit SimSymb.sim_skenv_func_bisim; eauto. intro FSIM; des.
    Print SimSymb.sim_skenv.
    inv FSIM. exploit FUNCFSIM; eauto. { apply SIMARGS. } i; des.
    split; ii.
    - exploit INITBSIM; eauto. i; des.
      esplits; eauto.
      eapply match_states_lxsim; eauto.
      { eapply SimSymb.mle_preserves_sim_skenv; eauto. }
    - exploit INITPROGRESS; eauto.
  Qed.

End MATCHSIMFORWARD.

