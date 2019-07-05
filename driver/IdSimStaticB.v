Require Import Sem SimProg Skeleton Mod ModSem SimMod SimModSem SimSymb SimMem Sound SimSymb.
Require Import Cop Ctypes ClightC.
Require SimMemId SimMemExt SimMemInj.
Require SoundTop UnreachC.
Require SimSymbId SimSymbDrop.
Require Import StaticMutrecA StaticMutrecBspec StaticMutrecBproof.
Require Import CoqlibC.
Require Import ValuesC.
Require Import LinkingC.
Require Import MapsC.
Require Import AxiomsC.
Require Import Ord.
Require Import MemoryC.
Require Import SmallstepC.
Require Import Events.
Require Import Preservation.
Require Import Integers.
Require Import LocationsC Conventions.

Require Import MatchSimModSem.
Require Import ClightStepInj ClightStepExt.
Require Import IdSimExtra IdSimClightExtra.
Require Import CtypingC.
Require Import CopC.
Require Import sflib.

Set Implicit Arguments.

Local Opaque Z.mul Z.add Z.sub Z.div.

Inductive match_states_ext_b (sm_arg: SimMemExt.t')
  : unit -> state -> state -> SimMemExt.t' -> Prop :=
| match_ext_Callstate
    i m_src m_tgt sm0
    (MWFSRC: m_src = sm0.(SimMemExt.src))
    (MWFTGT: m_tgt = sm0.(SimMemExt.tgt))
    (MWF: Mem.extends m_src m_tgt)
  :
    match_states_ext_b
      sm_arg tt
      (Callstate i m_src)
      (Callstate i m_tgt)
      sm0
| match_inter_Callstate
    i m_src m_tgt sm0
    (MWFSRC: m_src = sm0.(SimMemExt.src))
    (MWFTGT: m_tgt = sm0.(SimMemExt.tgt))
    (MWF: Mem.extends m_src m_tgt)
  :
    match_states_ext_b
      sm_arg tt
      (Interstate i m_src)
      (Interstate i m_tgt)
      sm0
| match_return_Callstate
    i m_src m_tgt sm0
    (MWFSRC: m_src = sm0.(SimMemExt.src))
    (MWFTGT: m_tgt = sm0.(SimMemExt.tgt))
    (MWF: Mem.extends m_src m_tgt)
  :
    match_states_ext_b
      sm_arg tt
      (Returnstate i m_src)
      (Returnstate i m_tgt)
      sm0.

Section BEXT.

  Variable se: Senv.t.
  Variable ge: SkEnv.t.

  Lemma b_step_preserve_extension
        sm_arg u st_src0 st_tgt0 st_src1 sm0 tr
        (MATCH: match_states_ext_b sm_arg u st_src0 st_tgt0 sm0)
        (STEP: step se ge st_src0 tr st_src1)
  :
    exists st_tgt1 sm1,
      (<<STEP: step se ge st_tgt0 tr st_tgt1>>) /\
      (<<MATCH: match_states_ext_b sm_arg u st_src1 st_tgt1 sm1>>).
  Proof.
    inv STEP; inv MATCH.
    - esplits. econs. econs; eauto.
    - esplits. econs 2; eauto. econs; eauto.
  Qed.

End BEXT.

Section BSOUNDSTATE.

  Variable skenv_link: SkEnv.t.
  Variable su: Sound.t.

  Inductive sound_state_b
    : state -> Prop :=
  | sound_Callstate
      i m
      (WF: Sound.wf su)
      (MEM: UnreachC.mem' su m)
      (SKE: su.(Unreach.ge_nb) = skenv_link.(Genv.genv_next))
    :
      sound_state_b (Callstate i m)
  | sound_Interstate
      i m
      (WF: Sound.wf su)
      (MEM: UnreachC.mem' su m)
      (SKE: su.(Unreach.ge_nb) = skenv_link.(Genv.genv_next))
      (NZERO: Int.intval i <> 0)
    :
      sound_state_b (Interstate i m)
  | sound_Returnstate
      i m
      (WF: Sound.wf su)
      (MEM: UnreachC.mem' su m)
      (SKE: su.(Unreach.ge_nb) = skenv_link.(Genv.genv_next))
    :
      sound_state_b (Returnstate i m)
  .

End BSOUNDSTATE.


Section BSOUND.

  Variable skenv_link: SkEnv.t.

  Lemma b_unreach_local_preservation
    :
      exists sound_state, <<PRSV: local_preservation (modsem skenv_link tt) sound_state>>
  .
  Proof.
    esplits.
    eapply local_preservation_strong_horizontal_spec with (sound_state := sound_state_b skenv_link); eauto.
    econs; ss; i.
    - inv INIT. ss. inv SUARG. des. esplits.
      + refl.
      + econs; eauto.
        * inv SKENV. eauto.
      + instantiate (1:=get_mem). ss. refl.
    - exists su0. esplits; eauto.
      + refl.
      + inv STEP; eauto.
        { inv SUST. econs; eauto. }
        { inv SUST. econs; eauto. }
          (* ss. des_ifs. *)
      + inv STEP; eauto.
        { ss. refl. }
        { ss. refl. }
    - inv AT; inv SUST; ss.
      split.
      + rr. refl.
      + inversion WF; subst.
        exists su0.
        esplits.
        * econs; ss; eauto.
          { ss. ii. split.
            - ii. clarify. eapply WFLO in H.
              rewrite SKE in H.
              unfold Genv.find_symbol in FINDG.
              exploit Genv.genv_symb_range; eauto. i. ss. xomega.
            - clarify.
              inv MEM. ss. rewrite NB.
              exploit Genv.genv_symb_range; eauto. i. ss.
              rewrite SKE in GENB.
              eapply Plt_Ple_trans; eauto. }
          esplits; eauto.
          econs; ss.
        * refl.
        * i.
          destruct retv. ss.
          rr in RETV. des; ss. inv MEM0.
          exists su_ret.
          inv AFTER.
          esplits; eauto.
          { econs; ss; eauto.
            inv LE. ss. des. rewrite <- GENB0. eauto. }
          { ss. refl. }
    - exists su0. inv SUST; inv FINAL; ss.
      esplits; try refl. ss.
  Qed.

End BSOUND.

Inductive match_states_b_internal:
  state -> state -> meminj -> mem -> mem -> Prop :=
| match_Callstate
    i m_src m_tgt j
  :
    match_states_b_internal
      (Callstate i m_src)
      (Callstate i m_tgt)
      j m_src m_tgt
| match_Interstate
    i m_src m_tgt j
  :
    match_states_b_internal
      (Interstate i m_src)
      (Interstate i m_tgt)
      j m_src m_tgt
| match_Returnstate
    i m_src m_tgt j
  :
    match_states_b_internal
      (Returnstate i m_src)
      (Returnstate i m_tgt)
      j m_src m_tgt
.

Inductive match_states_b (sm_arg: SimMemInj.t')
  : unit -> state -> state -> SimMemInj.t' -> Prop :=
| match_states_clight_intro
    st_src st_tgt j m_src m_tgt sm0
    (MWFSRC: m_src = sm0.(SimMemInj.src))
    (MWFTGT: m_tgt = sm0.(SimMemInj.tgt))
    (MWFINJ: j = sm0.(SimMemInj.inj))
    (MATCHST: match_states_b_internal st_src st_tgt j m_src m_tgt)
    (MWF: SimMemInj.wf' sm0)
  :
    match_states_b
      sm_arg tt st_src st_tgt sm0
.

Lemma b_id
  :
    exists mp,
      (<<SIM: @ModPair.sim SimMemId.SimMemId SimMemId.SimSymbId SoundTop.Top mp>>)
      /\ (<<SRC: mp.(ModPair.src) = (StaticMutrecBspec.module)>>)
      /\ (<<TGT: mp.(ModPair.tgt) = (StaticMutrecBspec.module)>>)
.
Proof.
  eexists (ModPair.mk _ _ _); s.
  esplits; eauto. instantiate (1:=tt).
  econs; ss; i.
  rewrite SIMSKENVLINK in *.
  eapply match_states_sim; ss.
  - apply unit_ord_wf.
  - eapply SoundTop.sound_state_local_preservation.
  - instantiate (1:= fun sm_arg _ st_src st_tgt sm0 =>
                       (<<EQ: st_src = st_tgt>>) /\
                       (<<MWF: sm0.(SimMemId.src) = sm0.(SimMemId.tgt)>>) /\
                       (<<stmwf: st_src.(StaticMutrecBspec.get_mem) =
                                 sm0.(SimMemId.src)>>)).
    ss.
    destruct args_src, args_tgt, sm_arg. ii. inv SIMARGS; ss; clarify.
    clear SAFESRC. dup INITTGT. inv INITTGT. ss.
    eexists. eexists (SimMemId.mk tgt tgt). esplits; eauto; ss.
  - ii. destruct args_src, args_tgt, sm_arg. inv SIMARGS; ss; clarify.
  - ii. ss. des. clarify.
  - i. ss. des. clarify. esplits; eauto.
    + inv CALLSRC. ss. clarify.
    + instantiate (1:=top4). ss.
  - i. clear HISTORY. ss. destruct sm_ret, retv_src, retv_tgt.
    inv SIMRET. des. ss. clarify. eexists (SimMemId.mk _ _). esplits; eauto.
    inv AFTERSRC. ss.
  - i. ss. des. destruct sm0. ss. clarify.
    eexists (SimMemId.mk (get_mem st_tgt0) (get_mem st_tgt0)).
    esplits; eauto.
    inv FINALSRC. ss.
  - right. ii. des. destruct sm0. ss. clarify. esplits; eauto.
    + i. exploit H; ss.
      * econs 1.
      * i. des; clarify. econs; eauto.
    + i. exists tt, st_tgt1.
      eexists (SimMemId.mk (get_mem st_tgt1) (get_mem st_tgt1)).
      esplits; eauto.
      left. econs; eauto; [econs 1|]. symmetry. apply E0_right.
Qed.

Lemma b_ext_unreach
  :
    exists mp,
      (<<SIM: @ModPair.sim SimMemExt.SimMemExt SimMemExt.SimSymbExtends UnreachC.Unreach mp>>)
      /\ (<<SRC: mp.(ModPair.src) = (StaticMutrecBspec.module)>>)
      /\ (<<TGT: mp.(ModPair.tgt) = (StaticMutrecBspec.module)>>)
.
Proof.
  eexists (ModPair.mk _ _ _); s.
  esplits; eauto. instantiate (1:=tt).
  econs; ss; i.
  destruct SIMSKENVLINK.
  exploit b_unreach_local_preservation. i. des.
  eapply match_states_sim with (match_states := match_states_ext_b); ss.
  - apply unit_ord_wf.
  - ss. eauto.
  - i. ss.
    inv INITTGT. inv SAFESRC. inv H. clarify.
    inv SIMARGS. ss.
    esplits; eauto.
    + econs; eauto.
    + assert (i = i0).
      { destruct args_src, args_tgt; ss. clarify.
        ss. inv VALS. inv H2. auto. }
      subst. econs; eauto.
      rewrite MEMTGT. eauto.
  - i. ss. des. inv SAFESRC. esplits. econs; ss.
    + inv SIMARGS. ss. inv FPTR. eauto.
    + inv SIMARGS. ss. inv FPTR0; eauto.
      rewrite <- H0 in *. clarify.
    + eauto.
    + inv SIMARGS. ss. rewrite VS in *. inv VALS. inv H2. inv H3. eauto.
  - i. ss. inv MATCH; eauto.

  - i. ss. clear SOUND. inv CALLSRC. inv MATCH. ss.
    esplits; eauto.
    + econs. eauto.
    + econs; ss; eauto.
    + instantiate (1:=top4). ss.

  - i. ss. clear SOUND HISTORY.
    exists sm_ret.
    inv AFTERSRC. inv MATCH.
    esplits; eauto.
    + econs; eauto.
      inv SIMRET. ss. inv RETV; ss. rewrite <- H0 in *. clarify.
    + inv SIMRET; ss. econs; eauto.
      rewrite MEMSRC, MEMTGT. eauto.

  - i. ss. inv FINALSRC. inv MATCH.
    esplits; eauto.
    + econs.
    + econs; eauto.
      econs.

  - right. ii. des.
    esplits.
    + i. inv MATCH; ss.
      * unfold ModSem.is_step. do 2 eexists. ss. econs; eauto.
      * unfold safe_modsem in H.
        exploit H. eapply star_refl. ii. des; clarify. inv EVSTEP.
      * ss. exfalso. eapply NOTRET. econs. ss.
    + ii. inv STEPTGT; inv MATCH; ss.
      * esplits; eauto.
        { left. eapply plus_one. econs. }
        econs; eauto.
      * esplits; eauto.
        { left. eapply plus_one. econs 2. eauto. }
        econs; eauto.
Qed.

Lemma b_ext_top
  :
    exists mp,
      (<<SIM: @ModPair.sim SimMemExt.SimMemExt SimMemExt.SimSymbExtends SoundTop.Top mp>>)
      /\ (<<SRC: mp.(ModPair.src) = (StaticMutrecBspec.module)>>)
      /\ (<<TGT: mp.(ModPair.tgt) = (StaticMutrecBspec.module)>>)
.
Proof.
  eexists (ModPair.mk _ _ _); s.
  esplits; eauto. instantiate (1:=tt).
  econs; ss; i.
  destruct SIMSKENVLINK.
  eapply match_states_sim with (match_states := match_states_ext_b); ss.
  - apply unit_ord_wf.
  - eapply SoundTop.sound_state_local_preservation.
  - i. ss.
    inv INITTGT. inv SAFESRC. inv H. clarify.
    inv SIMARGS. ss.
    esplits; eauto.
    + econs; eauto.
    + assert (i = i0).
      { destruct args_src, args_tgt; ss. clarify.
        ss. inv VALS. inv H2. auto. }
      subst. econs; eauto.
      rewrite MEMTGT. eauto.
  - i. ss. des. inv SAFESRC. esplits. econs; ss.
    + inv SIMARGS. ss. inv FPTR. eauto.
    + inv SIMARGS. ss. inv FPTR0; eauto.
      rewrite <- H0 in *. clarify.
    + eauto.
    + inv SIMARGS. ss. rewrite VS in *. inv VALS. inv H2. inv H3. eauto.
  - i. ss. inv MATCH; eauto.

  - i. ss. clear SOUND. inv CALLSRC. inv MATCH. ss.
    esplits; eauto.
    + econs. eauto.
    + econs; ss; eauto.
    + instantiate (1:=top4). ss.

  - i. ss. clear SOUND HISTORY.
    exists sm_ret.
    inv AFTERSRC. inv MATCH.
    esplits; eauto.
    + econs; eauto.
      inv SIMRET. ss. inv RETV; ss. rewrite <- H0 in *. clarify.
    + inv SIMRET; ss. econs; eauto.
      rewrite MEMSRC, MEMTGT. eauto.

  - i. ss. inv FINALSRC. inv MATCH.
    esplits; eauto.
    + econs.
    + econs; eauto.
      econs.

  - right. ii. des.
    esplits.
    + i. inv MATCH; ss.
      * unfold ModSem.is_step. do 2 eexists. ss. econs; eauto.
      * unfold safe_modsem in H.
        exploit H. eapply star_refl. ii. des; clarify. inv EVSTEP.
      * ss. exfalso. eapply NOTRET. econs. ss.
    + ii. inv STEPTGT; inv MATCH; ss.
      * esplits; eauto.
        { left. eapply plus_one. econs. }
        econs; eauto.
      * esplits; eauto.
        { left. eapply plus_one. econs 2. eauto. }
        econs; eauto.
Qed.

Lemma b_inj_drop_bot
      (WF: Sk.wf (StaticMutrecBspec.module))
  :
    exists mp,
      (<<SIM: @ModPair.sim SimMemInjC.SimMemInj SimSymbDrop.SimSymbDrop SoundTop.Top mp>>)
      /\ (<<SRC: mp.(ModPair.src) = (StaticMutrecBspec.module)>>)
      /\ (<<TGT: mp.(ModPair.tgt) = (StaticMutrecBspec.module)>>)
      /\ (<<SSBOT: mp.(ModPair.ss) = bot1>>)
.
Proof.
  eexists (ModPair.mk _ _ _); s.
  esplits; eauto.
  econs; ss; i.
  { econs; ss; i; clarify.
    inv WF. auto. }
  eapply match_states_sim with (match_states := match_states_b); ss.
  - apply unit_ord_wf.
  - eapply SoundTop.sound_state_local_preservation.

  - i. ss.
    inv INITTGT. inv SAFESRC. inv SIMARGS. inv H. ss.
    eauto.
    esplits; eauto.
    + econs; eauto.
    + refl.
    + econs; eauto.
      assert (i = i0).
      { destruct args_src, args_tgt; ss. inv VALS; ss.
        destruct vl, vl'; ss. clarify. inv H. auto. }
      rewrite MEMTGT, MEMSRC. subst i0. econs.

  - i. ss. exploit SimSymbDrop_match_globals.
    { inv SIMSKENV. ss. eauto. }
    instantiate (1 := prog). intros GEMATCH.
    des. inv SAFESRC. inv SIMARGS.
    inv GEMATCH. exploit SYMBLE; eauto. i. des; eauto.
    esplits. econs; ss; eauto.
    + clear -MWF INJ FPTR FPTR0.
      rewrite FPTR in FPTR0. inv FPTR0; ss.
      rewrite H2 in INJ. clarify.
    + rewrite VS in VALS. inv VALS; ss. inv H3. inv H2. auto.

  - i. ss. inv MATCH; eauto.

  - i. ss. clear SOUND. inv CALLSRC. inv MATCH. inv MATCHST. inversion SIMSKENV; subst. ss.
    i. ss. exploit SimSymbDrop_match_globals.
    { inv SIMSKENV. ss. eauto. }
    instantiate (2 := prog). intros GEMATCH.
    inv GEMATCH. exploit SYMBLE; eauto. i. des; eauto.
    esplits; eauto.
    + econs; ss; eauto.
    + econs; ss; econs; eauto.
    + refl.
    + instantiate (1:=top4). ss.

  - i. ss. clear SOUND HISTORY.
    exists (SimMemInj.unlift' sm_arg sm_ret).
    inv AFTERSRC. inv MATCH. inv MATCHST.
    esplits; eauto.
    + econs; eauto. inv SIMRET. rewrite INT in *. inv RETV. ss.
    + inv SIMRET. econs; eauto. econs; eauto.
    + refl.

  - i. ss. inv FINALSRC. inv MATCH. inv MATCHST.
    esplits; eauto.
    + econs.
    + econs; eauto. econs.
    + refl.

  - right. ii. des.
    esplits.
    + i. inv MATCH. inv MATCHST.
      * unfold ModSem.is_step. do 2 eexists. ss. econs; eauto.
      * unfold safe_modsem in H.
        exploit H. eapply star_refl. ii. des; clarify. inv EVSTEP.
      * ss. exfalso. eapply NOTRET. econs. ss.
    + ii. inv STEPTGT; inv MATCH; inv MATCHST.
      * esplits; eauto.
        { left. eapply plus_one. econs. }
        refl.
        econs; eauto. econs.
      * esplits; eauto.
        { left. eapply plus_one. econs 2. eauto. }
        refl.
        econs; eauto. econs.
Qed.

Lemma b_inj_drop
      (WF: Sk.wf (StaticMutrecBspec.module))
  :
    exists mp,
      (<<SIM: @ModPair.sim SimMemInjC.SimMemInj SimSymbDrop.SimSymbDrop SoundTop.Top mp>>)
      /\ (<<SRC: mp.(ModPair.src) = (StaticMutrecBspec.module)>>)
      /\ (<<TGT: mp.(ModPair.tgt) = (StaticMutrecBspec.module)>>)
.
Proof.
  exploit b_inj_drop_bot; eauto. i. des. eauto.
Qed.

Lemma b_inj_id
      (WF: Sk.wf (StaticMutrecBspec.module))
  :
    exists mp,
      (<<SIM: @ModPair.sim SimMemInjC.SimMemInj SimMemInjC.SimSymbId SoundTop.Top mp>>)
      /\ (<<SRC: mp.(ModPair.src) = (StaticMutrecBspec.module)>>)
      /\ (<<TGT: mp.(ModPair.tgt) = (StaticMutrecBspec.module)>>)
.
Proof.
  apply sim_inj_drop_bot_id. apply b_inj_drop_bot; auto.
Qed.
