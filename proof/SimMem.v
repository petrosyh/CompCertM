Require Import CoqlibC.
Require Import Memory.
Require Import Values.
Require Import Maps.
Require Import Events.
Require Import Globalenvs.
Require Import sflib.
Require Import RelationClasses.
Require Import FSets.
Require Import Ordered.
Require Import AST.
Require Import Integers.

Require Import ModSem.

Set Implicit Arguments.






Module SimMem.

  Class class :=
  { t: Type;
    src: t -> mem;
    tgt: t -> mem;
    wf: t -> Prop;
    le: t -> t -> Prop;
    lepriv: t -> t -> Prop;
    (* Time order: unlift second arg into first arg. *)
    (* TODO: reorder arg? from->to? *)

    le_PreOrder :> PreOrder le;

    pub_priv: forall sm0 sm1, le sm0 sm1 -> lepriv sm0 sm1;
    (* lift_le: forall mrel, le mrel (lift mrel); *)
    (* lift_spec: forall mrel0 mrel1, le (lift mrel0) mrel1 -> wf mrel0 -> le mrel0 (unlift mrel0 mrel1); *)

    sim_val: t -> val -> val -> Prop;
    sim_val_list: t -> list val -> list val -> Prop;
    le_sim_val: forall mrel0 mrel1 (MLE: le mrel0 mrel1), sim_val mrel0 <2= sim_val mrel1;
    sim_val_list_spec: forall sm0, (List.Forall2 sm0.(sim_val) = sm0.(sim_val_list));
    sim_val_int: forall sm0 v_src v_tgt, sim_val sm0 v_src v_tgt -> forall i, v_src = Vint i -> v_tgt = Vint i;
  }.

  (* Lemma le_sim_val *)
  (*       `{SM: class} *)
  (*       mrel0 mrel1 *)
  (*       (MWF: SimMem.wf mrel0) *)
  (*       (MLE: le mrel0 mrel1): *)
  (*     sim_val mrel0 <2= sim_val mrel1. *)
  (* Proof. eapply lepriv_sim_val; et. eapply pub_priv; et. Qed. *)

  Lemma sim_val_list_length
        `{SM: class} (sm0: t)
        vs_src vs_tgt
        (SIMVS: sm0.(sim_val_list) vs_src vs_tgt):
      length vs_src = length vs_tgt.
  Proof. rewrite <- sim_val_list_spec in SIMVS. ginduction SIMVS; ii; ss. congruence. Qed.

  Definition sim_block `{SM: class} (sm0: t) (blk_src blk_tgt: block): Prop :=
    sm0.(sim_val) (Vptr blk_src Ptrofs.zero) (Vptr blk_tgt Ptrofs.zero).

  (* Definition lifted `{SM: class} (sm0 sm1: t): Prop := SimMem.lift sm0 = sm1 /\ SimMem.wf sm0. *)

  Definition future `{SM: class}: t -> t -> Prop := rtc (lepriv \2/ le).

  (* Definition sim_regset `{SM: class} (sm0: t) (rs_src rs_tgt: regset): Prop := *)
  (*   forall pr, sm0.(sim_val) (rs_src pr) (rs_tgt pr) *)
  (* . *)

  Definition sim_regset `{SM: class} (sm0: SimMem.t) (rs_src rs_tgt: Asm.regset): Prop := forall pr, sm0.(sim_val) (rs_src pr) (rs_tgt pr).

  Inductive sim_args `{SM: class} (args_src args_tgt: Args.t) (sm0: SimMem.t): Prop :=
  | sim_args_Cstyle
      fptr_src vs_src m_src fptr_tgt vs_tgt m_tgt
      (CSRC: args_src = Args.Cstyle fptr_src vs_src m_src)
      (CTGT: args_tgt = Args.Cstyle fptr_tgt vs_tgt m_tgt)
      (FPTR: sm0.(SimMem.sim_val) fptr_src fptr_tgt)
      (VALS: sm0.(SimMem.sim_val_list) vs_src vs_tgt)
      (MEMSRC: m_src = sm0.(SimMem.src))
      (MEMTGT: m_tgt = sm0.(SimMem.tgt))
  | sim_args_Asmstyle
      rs_src m_src rs_tgt m_tgt
      (ASMSRC: args_src = Args.Asmstyle rs_src m_src)
      (ASMTGT: args_tgt = Args.Asmstyle rs_tgt m_tgt)
      (RS: sm0.(sim_regset) rs_src rs_tgt)
      (MEMSRC: m_src = sm0.(SimMem.src))
      (MEMTGT: m_tgt = sm0.(SimMem.tgt)).

  Inductive sim_retv `{SM: class} (retv_src retv_tgt: Retv.t) (sm0: SimMem.t): Prop :=
  | sim_retv_Cstyle
      v_src m_src v_tgt m_tgt
      (CSRC: retv_src = Retv.Cstyle v_src m_src)
      (CTGT: retv_tgt = Retv.Cstyle v_tgt m_tgt)
      (RETV: sm0.(SimMem.sim_val) v_src v_tgt)
      (MEMSRC: m_src = sm0.(SimMem.src))
      (MEMTGT: m_tgt = sm0.(SimMem.tgt))
  | sim_retv_Asmstyle
      rs_src m_src rs_tgt m_tgt
      (ASMSRC: retv_src = Retv.Asmstyle rs_src m_src)
      (ASMTGT: retv_tgt = Retv.Asmstyle rs_tgt m_tgt)
      (RS: sm0.(sim_regset) rs_src rs_tgt)
      (MEMSRC: m_src = sm0.(SimMem.src))
      (MEMTGT: m_tgt = sm0.(SimMem.tgt)).

  Lemma sim_args_sim_fptr `{SM: class}: forall sm0 args_src args_tgt (ARGS: sim_args args_src args_tgt sm0),
      sm0.(sim_val) args_src.(Args.get_fptr) args_tgt.(Args.get_fptr).
  Proof. i. inv ARGS; ss. Qed.

  Lemma sim_val_list_le
        `{SM: class}
        sm0 sm1 vs_src vs_tgt
        (LEPRIV: SimMem.le sm0 sm1)
        (SIMVS: SimMem.sim_val_list sm0 vs_src vs_tgt):
      <<SIMVS: SimMem.sim_val_list sm1 vs_src vs_tgt>>.
  Proof.
    rewrite <- sim_val_list_spec in *. induction SIMVS; ii; ss.
    econs; eauto. eapply le_sim_val; et.
  Qed.

End SimMem.

Hint Unfold SimMem.future.

Hint Resolve SimMem.pub_priv.
