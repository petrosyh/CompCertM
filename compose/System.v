Require Import EventsC.
Require Import Values.
Require Import AST.
Require Import Memory.
Require Import Globalenvs.
Require Import Smallstep Simulation.
Require Import CoqlibC.

Require Import Mod ModSem Skeleton.

Set Implicit Arguments.



Section SYSMODSEM.

  Variable skenv_link: SkEnv.t.

  Definition genvtype: Type := SkEnv.t.

  Definition globalenv: genvtype := skenv_link.

  Definition skenv: SkEnv.t :=
    skenv_link.(Genv_map_defs)(fun _ gd =>
                                 match gd with
                                 | Gfun (External ef) => Some (Gfun (Internal (Some ef.(ef_sig))))
                                 | Gfun _ => None
                                 | Gvar gv => Some gd
                                 end)
  .

  Lemma skenv_globlaenv_equiv
    :
      Senv.equiv skenv globalenv
  .
  Proof.
    rr. splits; ii; ss; eauto.
    unfold skenv, globalenv.
    (* unfold skenv, globalenv. *)
    unfold Genv.block_is_volatile, Genv.find_var_info.
    des_ifs; repeat (apply_all_once Genv_map_defs_def; des); ss; des_ifs.
    eapply_all_once Genv_map_defs_def_inv.
    all_once_fast ltac:(fun H => try erewrite H in *; ss).
  Qed.

  Inductive state: Type :=
  | Callstate
      (fptr: val)
      (vs: list val)
      (m: mem)
  | Returnstate
      (v: val)
      (m: mem)
  .

  Inductive step (se: Senv.t) (ge: genvtype): state -> trace -> state -> Prop :=
  | step_intro
      ef
      fptr vs m0 v m1
      (FPTR: ge.(Genv.find_funct) fptr = Some (External ef))
      tr
      (EXTCALL: external_call ef ge vs m0 tr v m1)
    :
      step se ge (Callstate fptr vs m0) tr (Returnstate v m1)
  .

  Inductive initial_frame (args: Args.t): state -> Prop :=
  | initial_frame_intro
      fptr vs m
      (CSTYLE: args = Args.Cstyle fptr vs m)
    :
      initial_frame args (Callstate fptr vs m)
  .

  Inductive final_frame: state -> Retv.t -> Prop :=
  | final_frame_intro
      v m
    :
      final_frame (Returnstate v m) (Retv.Cstyle v m)
  .

  Program Definition modsem: ModSem.t := {|
    ModSem.state := state;
    ModSem.genvtype := genvtype;
    ModSem.step := step;
    ModSem.at_external := bot2;
    ModSem.initial_frame := initial_frame;
    ModSem.final_frame := final_frame;
    ModSem.after_external := bot3;
    ModSem.globalenv:= globalenv;
    ModSem.skenv := skenv;
    ModSem.skenv_link := skenv_link;
  |}
  .
  Next Obligation. all_prop_inv; ss. Qed.
  Next Obligation. all_prop_inv; ss. Qed.
  Next Obligation. all_prop_inv; ss. Qed.
  Next Obligation. ii; des; ss; all_prop_inv; ss. Qed.
  Next Obligation. ii; des; ss; all_prop_inv; ss. Qed.
  Next Obligation. ii; des; ss; all_prop_inv; ss. Qed.

  Lemma modsem_receptive
        st
    :
      receptive_at modsem st
  .
  Proof.
    econs; ii; ss.
    - inv H. exploit external_call_receptive; eauto. i; des.
      esplits; et. econs; et.
    - inv H. eapply external_call_trace_length; et.
  Qed.

  Lemma modsem_determinate
        st
    :
      determinate_at modsem st
  .
  Proof.
    econs; ii; ss.
    - inv H; inv H0. clarify.
      determ_tac external_call_match_traces.
      esplits; et.
      i; clarify.
      determ_tac external_call_deterministic.
    - inv H. eapply external_call_trace_length; et.
  Qed.

End SYSMODSEM.








(* Section SYSMOD. *)

(*   Variable prog_main: ident. *)

(*   Program Definition mod: Mod.t := {| *)
(*     Mod.datatype := unit; *)
(*     Mod.get_sk := fun _ => (mkprogram [] [] prog_main); *)
(*     Mod.get_modsem := fun skenv _ => modsem skenv; *)
(*     Mod.data := tt; *)
(*   |} *)
(*   . *)

(* End SYSMOD. *)

