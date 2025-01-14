Require Import Events.
Require Import ValuesC.
Require Import AST.
Require Import Memory.
Require Import Globalenvs.
Require Import Smallstep.
Require Import CoqlibC.
Require Import Skeleton.
Require Import Integers.
Require Import ASTC.
Require Import LinkingC.
Require Import Maps.

Require Import SimMem.
Require Import System.
Require Import ModSem.

Set Implicit Arguments.


Module SimSymb.

  Inductive skenv_func_bisim (sim_val: val -> val -> Prop) (skenv_src skenv_tgt: SkEnv.t): Prop :=
  | skenv_func_bisim_intro
      (FUNCFSIM: forall fptr_src fptr_tgt def_src
          (SIMFPTR: sim_val fptr_src fptr_tgt)
          (FUNCSRC: skenv_src.(Genv.find_funct) fptr_src = Some def_src),
          exists def_tgt, <<FUNCSRC: skenv_tgt.(Genv.find_funct) fptr_tgt = Some def_tgt>> /\ <<SIM: def_src = def_tgt>>).

  (* TODO: Try moving t into argument? sim_symb coercion gets broken and I don't know how to fix it. *)
  Class class (SM: SimMem.class) :=
    { t: Type;
      le: t -> t -> Prop;
      src: t -> Sk.t;
      tgt: t -> Sk.t;

      le_PreOrder :> PreOrder le;

      wf: t -> Prop;
      wf_preserves_wf: forall ss0
          (SIMSK: wf ss0)
          (WFSRC: Sk.wf ss0.(src)),
          <<WFTGT: Sk.wf ss0.(tgt)>>;

      wf_link: forall ss0 ss1 sk_src
          (SIMSK: wf ss0)
          (SIMSK: wf ss1)
          (LINKSRC: link ss0.(src) ss1.(src) = Some sk_src)
          (WFSRC0: Sk.wf ss0.(src))
          (WFSRC1: Sk.wf ss1.(src))
          (WFTGT0: Sk.wf ss0.(tgt))
          (WFTGT1: Sk.wf ss1.(tgt)),
          exists ss sk_tgt,
            <<LINKTGT: link ss0.(tgt) ss1.(tgt) = Some sk_tgt>> /\
            <<SKSRC: ss.(src) = sk_src>> /\
            <<SKTGT: ss.(tgt) = sk_tgt>> /\
            <<LE0: le ss0 ss>> /\
            <<LE1: le ss1 ss>> /\
            <<SIMSK: wf ss>>;

      sim_skenv: SimMem.t -> t -> SkEnv.t -> SkEnv.t -> Prop;

      sim_skenv_public_symbols: forall sm0 ss0 skenv_src skenv_tgt
          (SIMSKE: sim_skenv sm0 ss0 skenv_src skenv_tgt),
          skenv_src.(Genv.public_symbol) = skenv_tgt.(Genv.public_symbol);

      wf_load_sim_skenv: forall ss skenv_src skenv_tgt m_src
          (SIMSK: wf ss)
          (LOADSRC: ss.(src).(Sk.load_skenv) = skenv_src)
          (LOADTGT: ss.(tgt).(Sk.load_skenv) = skenv_tgt)
          (LOADMEMSRC: ss.(src).(Sk.load_mem) = Some m_src),
          exists m_tgt sm,
            (<<LOADMEMTGT: ss.(tgt).(Sk.load_mem) = Some m_tgt>>) /\
            (<<SIMSKENV: sim_skenv sm ss skenv_src skenv_tgt>>) /\
            (<<MEMSRC: sm.(SimMem.src) = m_src>>) /\
            (<<MEMTGT: sm.(SimMem.tgt) = m_tgt>>) /\
            (<<MWF: sm.(SimMem.wf)>>) /\
            (<<MAINSIM: SimMem.sim_val sm (Genv.symbol_address skenv_src ss.(src).(prog_main) Ptrofs.zero)
                                       (Genv.symbol_address skenv_tgt ss.(tgt).(prog_main) Ptrofs.zero)>>);

      (* mle_preserves_sim_skenv: forall *)
      (*     sm0 sm1 *)
      (*     (MLE: SimMem.le sm0 sm1) *)
      (*     ss skenv_src skenv_tgt *)
      (*     (SIMSKENV: sim_skenv sm0 ss skenv_src skenv_tgt) *)
      (*   , *)
      (*     <<SIMSKENV: sim_skenv sm1 ss skenv_src skenv_tgt>> *)
      (* ; *)

      mlepriv_preserves_sim_skenv: forall sm0 sm1 ss skenv_src skenv_tgt
          (MLE: SimMem.lepriv sm0 sm1)
          (SIMSKENV: sim_skenv sm0 ss skenv_src skenv_tgt),
          <<SIMSKENV: sim_skenv sm1 ss skenv_src skenv_tgt>>;

      (* sim_skenv_monotone_ss: forall *)
      (*     sm ss_link skenv_src skenv_tgt *)
      (*     (SIMSKENV: sim_skenv sm ss_link skenv_src skenv_tgt) *)
      (*     ss *)
      (*     (LE: linkorder ss ss_link) *)
      (*   , *)
      (*     <<SIMSKENV: sim_skenv sm ss skenv_src skenv_tgt>> *)
      (* (* Note: this should be trivial. kept becomes smaller *) *)
      (* ; *)

      (* (* TODO: Can we separate sim_skenv_monotone_skenv, like sim_skenv_monotone_ss? *) *)
      (* sim_skenv_monotone_skenv: forall *)
      (*     sm ss skenv_link_src skenv_link_tgt *)
      (*     (SIMSKENV: sim_skenv sm ss skenv_link_src skenv_link_tgt) *)
      (*     (* F_src V_src F_tgt V_tgt *) *)
      (*     (* (flesh_src: list (ident * globdef (AST.fundef F_src) V_src)) *) *)
      (*     (* (flesh_tgt: list (ident * globdef (AST.fundef F_tgt) V_tgt)) *) *)
      (*     sk_src sk_tgt *)
      (*     (SIMSK: sim_sk ss sk_src sk_tgt) *)
      (*     skenv_src skenv_tgt *)
      (*     (LESRC: skenv_link_src.(SkEnv.project) sk_src.(defs) skenv_src) *)
      (*     (LETGT: skenv_link_tgt.(SkEnv.project) sk_tgt.(defs) skenv_tgt) *)
      (*   , *)
      (*     <<SIMSKENV: sim_skenv sm ss skenv_src skenv_tgt>> *)
      (* ; *)

      (* TODO: Can we separate sim_skenv_monotone_skenv, like sim_skenv_monotone_ss? *)
      sim_skenv_monotone: forall
          sm ss_link skenv_link_src skenv_link_tgt
          ss skenv_src skenv_tgt
          (WFSRC: SkEnv.wf skenv_link_src)
          (WFTGT: SkEnv.wf skenv_link_tgt)
          (SIMSKENV: sim_skenv sm ss_link skenv_link_src skenv_link_tgt)
          (* F_src V_src F_tgt V_tgt *)
          (* (flesh_src: list (ident * globdef (AST.fundef F_src) V_src)) *)
          (* (flesh_tgt: list (ident * globdef (AST.fundef F_tgt) V_tgt)) *)
          (SIMSK: wf ss)
          (LE: le ss ss_link)
          (INCLSRC: SkEnv.includes skenv_link_src ss.(src))
          (INCLTGT: SkEnv.includes skenv_link_tgt ss.(tgt))
          (LESRC: SkEnv.project skenv_link_src ss.(src) = skenv_src)
          (LETGT: SkEnv.project skenv_link_tgt ss.(tgt) = skenv_tgt),
          <<SIMSKENV: sim_skenv sm ss skenv_src skenv_tgt>>;

      sim_skenv_func_bisim: forall sm ss skenv_src skenv_tgt
          (SIMSKENV: sim_skenv sm ss skenv_src skenv_tgt),
          <<DEF: skenv_func_bisim sm.(SimMem.sim_val) skenv_src skenv_tgt>>;

      system_sim_skenv: forall sm ss skenv_src skenv_tgt
          (SIMSKENV: sim_skenv sm ss skenv_src skenv_tgt),
          <<SIMSKENV: sim_skenv sm ss skenv_src.(System.skenv) skenv_tgt.(System.skenv)>>;
      (* system_sim_skenv_sim_ge: forall *)
      (*     sm ss_sys ss sk_src sk_tgt *)
      (*     skenv_src skenv_tgt *)
      (*     (LOADSRC: sk_src.(Sk.load_skenv) = skenv_src) *)
      (*     (LOADTGT: sk_tgt.(Sk.load_skenv) = skenv_tgt) *)
      (*     (SIMSK: sim_sk ss sk_src sk_tgt) *)
      (*     (* (LE: SimSymb.le ss_sys ss) *) *)
      (*     (SIMSKENV: sim_skenv sm ss_sys skenv_src.(System.skenv) skenv_tgt.(System.skenv)) *)
      (*   , *)
      (*     <<SIMGE: sim_skenv sm ss_sys skenv_src.(System.globalenv) skenv_tgt.(System.globalenv)>> *)
      (* ; *)
      system_axiom: forall
          sm0 ss_sys skenv_sys_src skenv_sys_tgt
          args_src args_tgt tr retv_src ef
          (SIMSKENV: sim_skenv sm0 ss_sys skenv_sys_src skenv_sys_tgt)
          (MWF: SimMem.wf sm0)
          (CSTYLE: Args.is_cstyle args_src)
          (CSTYLE: Retv.is_cstyle retv_src)
          (ARGS: SimMem.sim_args args_src args_tgt sm0)
          (SYSSRC: external_call ef skenv_sys_src (args_src.(Args.vs)) (args_src.(Args.m))
                                 tr
                                 (retv_src.(Retv.v)) (retv_src.(Retv.m))),
          (* exists sm_lift, SimMem.lepriv sm0 sm_lift /\ *)
          exists sm1 retv_tgt,
            (<<SYSTGT: external_call ef skenv_sys_tgt (args_tgt.(Args.vs)) (args_tgt.(Args.m))
                                     tr
                                     (retv_tgt.(Retv.v)) (retv_tgt.(Retv.m))>>)
            /\ (<<RETV: SimMem.sim_retv retv_src retv_tgt sm1>>)
            /\ (<<MLE0: SimMem.le sm0 sm1>>)
            /\ (<<MWF: SimMem.wf sm1>>);
            (* /\ exists sm_unlift, (<<MLE1: SimMem.le sm0 sm_unlift>>) /\ (<<MLE2: SimMem.lepriv sm1 sm_unlift>>) *)
    }.

  Lemma mle_preserves_sim_skenv: forall
      `{SM: SimMem.class} `{SS: @class SM}
      sm0 sm1 ss skenv_src skenv_tgt
      (MLE: SimMem.le sm0 sm1)
      (SIMSKENV: sim_skenv sm0 ss skenv_src skenv_tgt),
      <<SIMSKENV: sim_skenv sm1 ss skenv_src skenv_tgt>>.
  Proof. ii. eapply mlepriv_preserves_sim_skenv; et. Qed.

  Lemma mfuture_preserves_sim_skenv
        `{SM: SimMem.class} `{SS: @class SM}
        sm0 sm1 ss skenv_src skenv_tgt
        (MFUTURE: SimMem.future sm0 sm1)
        (SIMSKENV: sim_skenv sm0 ss skenv_src skenv_tgt):
      <<SIMSKENV: sim_skenv sm1 ss skenv_src skenv_tgt>>.
  Proof.
    induction MFUTURE; ss. des.
    - eapply IHMFUTURE; eauto. eapply mlepriv_preserves_sim_skenv; eauto.
    - eapply IHMFUTURE; eauto. eapply mle_preserves_sim_skenv; eauto.
  Qed.

  Lemma simskenv_func_fsim
        `{SM: SimMem.class} `{SS: @class SM}
        ss0 sm0 skd v_src v_tgt skenv_link_src skenv_link_tgt
        (SIMSKENV: sim_skenv sm0 ss0 skenv_link_src skenv_link_tgt)
        (SIMV: sm0.(SimMem.sim_val) v_src v_tgt)
        (FIND: Genv.find_funct skenv_link_src v_src = Some skd):
      Genv.find_funct skenv_link_tgt v_tgt = Some skd.
  Proof. exploit SimSymb.sim_skenv_func_bisim; eauto. i; des. inv H. exploit FUNCFSIM; eauto. i; des. clarify. Qed.

End SimSymb.
