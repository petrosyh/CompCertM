Require Import CoqlibC Errors.
Require Import Integers ASTC Linking.
Require Import ValuesC MemoryC Separation Events GlobalenvsC Smallstep.
Require Import LTL Op Locations LinearC MachC.
(* Require Import BoundsC Conventions StacklayoutC Lineartyping. *)
Require Import Bounds Conventions Stacklayout Lineartyping.
Require Import Stacking.

Local Open Scope sep_scope.

(* newly added *)
Require Import sflib.
Require Export StackingproofC0.
Require Import SimModSem.
Require Import SimMemInj.
Require SimSymb.
Require Import AsmregsC.

Set Implicit Arguments.



Section ALIGN.

  Lemma align_refl
        x
        (NONNEG: x >= 0)
  :
    <<ALIGN: align x x = x>>
  .
  Proof.
    destruct (Z.eqb x 0) eqn: T.
    { rewrite Z.eqb_eq in T. clarify. }
    rewrite Z.eqb_neq in T.
    red.
    unfold align.
    replace ((x + x - 1) / x) with 1.
    { xomega. }
    replace (x + x - 1) with (1 * x + (1 * x + (- 1))); cycle 1.
    { xomega. }
    rewrite Z.div_add_l; try eassumption.
    rewrite Z.div_add_l; try eassumption.
    replace (Z.div (Zneg xH) x) with (Zneg xH).
    { xomega. }
    destruct x; ss.
    clear - p.
    unfold Z.div. des_ifs.
    ginduction p; i; ss; des_ifs.
  Qed.

  Lemma align_zero
        x
    :
      <<ALIGN: align x 0 = 0>>
  .
  Proof.
    unfold align. red. ss.
    xomega.
  Qed.

  Lemma align_divisible
        z y
        (DIV: (y | z))
        (NONNEG: y > 0)
    :
      <<ALIGN: align z y = z>>
  .
  Proof.
    red.
    unfold align.
    replace ((z + y - 1) / y) with (z / y + (y - 1) / y); cycle 1.
    {
      unfold Z.divide in *. des. clarify.
      rewrite Z_div_mult; ss.
      replace (z0 * y + y - 1) with (z0 * y + (y - 1)); cycle 1.
      { xomega. }
      rewrite Z.div_add_l with (b := y); ss.
      xomega.
    }
    replace ((y - 1) / y) with 0; cycle 1.
    { erewrite Zdiv_small; ss. xomega. }
    unfold Z.divide in *. des. clarify.
    rewrite Z_div_mult; ss.
    rewrite Z.add_0_r.
    xomega.
  Qed.

  Lemma align_idempotence
        x y
        (NONNEG: y > 0)
    :
      <<ALIGN: align (align x y) y = align x y>>
  .
  Proof.
    apply align_divisible; ss.
    apply align_divides; ss.
  Qed.

End ALIGN.

Hint Rewrite align_refl: align.
Hint Rewrite align_zero: align.
Hint Rewrite align_idempotence: align.




Local Opaque Z.add Z.mul Z.div.

(* Section DUMMY_FUNCTION. *)

(*   Variable sg: signature. *)
  
(*   Lemma dummy_function_used_callee_save *)
(*     : *)
(*     (dummy_function sg).(function_bounds).(used_callee_save) = [] *)
(*   . *)
(*   Proof. ss. Qed. *)

(*   Lemma dummy_function_bound_local *)
(*     : *)
(*       (dummy_function sg).(function_bounds).(bound_local) = 0 *)
(*   . *)
(*   Proof. ss. Qed. *)

(*   Lemma dummy_function_bound_outgoing *)
(*     : *)
(*       (dummy_function sg).(function_bounds).(bound_outgoing) = (size_arguments sg) *)
(*   . *)
(*   Proof. *)
(*     ss. unfold dummy_function. cbn. *)
(*     rewrite Z.max_l; try xomega. rewrite Z.max_r; try xomega. *)
(*     generalize (size_arguments_above sg). i. xomega. *)
(*   Qed. *)

(*   Lemma dummy_function_bound_stack_data *)
(*     : *)
(*       (dummy_function sg).(function_bounds).(bound_stack_data) = 0 *)
(*   . *)
(*   Proof. ss. Qed. *)

(*   Lemma dummy_function_size_callee_save_area *)
(*         ofs *)
(*     : *)
(*       (dummy_function sg).(function_bounds).(size_callee_save_area) ofs = ofs *)
(*   . *)
(*   Proof. ss. Qed. *)

(*   Lemma dummy_function_fe_ofs_local *)
(*     : *)
(*       (dummy_function sg).(function_bounds).(make_env).(fe_ofs_local) = (align (4 * size_arguments sg) 8 + 8) *)
(*   . *)
(*   Proof. *)
(*     unfold make_env. ss. des_ifs_safe. *)
(*     cbn. des_ifs_safe. rewrite Z.max_l; try xomega. rewrite Z.max_r; cycle 1. *)
(*     { generalize (size_arguments_above sg). i. xomega. } *)
(*     rewrite align_divisible; try xomega. *)
(*     apply Z.divide_add_r; try xomega. *)
(*     - apply align_divides; auto. xomega. *)
(*     - reflexivity. *)
(*   Qed. *)

(*   Lemma dummy_function_fe_ofs_link *)
(*     : *)
(*       (dummy_function sg).(function_bounds).(make_env).(fe_ofs_link) = (align (4 * size_arguments sg) 8) *)
(*   . *)
(*   Proof. *)
(*     unfold make_env. ss. des_ifs_safe. *)
(*     cbn. des_ifs_safe. rewrite Z.max_l; try xomega. rewrite Z.max_r; cycle 1. *)
(*     { generalize (size_arguments_above sg). i. xomega. } *)
(*     ss. *)
(*   Qed. *)

(*   Lemma dummy_function_fe_ofs_retaddr *)
(*     : *)
(*       (dummy_function sg).(function_bounds).(make_env).(fe_ofs_retaddr) = (align (4 * size_arguments sg) 8 + 8) *)
(*   . *)
(*   Proof. *)
(*     unfold make_env. ss. des_ifs_safe. *)
(*     cbn. des_ifs_safe. rewrite Z.max_l; try xomega. rewrite Z.max_r; cycle 1. *)
(*     { generalize (size_arguments_above sg). i. xomega. } *)
(*     rewrite Z.mul_0_r. rewrite ! Z.add_0_r. *)
(*     rewrite align_divisible; try xomega; cycle 1. *)
(*     { apply align_divides. xomega. } *)
(*     rewrite align_divisible; try xomega; cycle 1. *)
(*     { apply align_divides. xomega. } *)
(*     rewrite align_divisible; try xomega; cycle 1. *)
(*     apply Z.divide_add_r; try xomega. *)
(*     - apply align_divides; auto. xomega. *)
(*     - reflexivity. *)
(*   Qed. *)

(*   Lemma dummy_function_fe_size *)
(*     : *)
(*       (dummy_function sg).(function_bounds).(make_env).(fe_size) = (align (4 * size_arguments sg) 8 + 8 + 8) *)
(*   . *)
(*   Proof. *)
(*     unfold make_env. *)
(*     (*??????????????? simpl. -> inf loop, but cbn works!!!!!!!!!!!!! *) *)
(*     cbn. des_ifs_safe. rewrite Z.max_l; try xomega. rewrite Z.max_r; cycle 1. *)
(*     { generalize (size_arguments_above sg). i. xomega. } *)
(*     rewrite Z.mul_0_r. rewrite ! Z.add_0_r. *)
(*     rewrite align_divisible; try xomega; cycle 1. *)
(*     { apply align_divides. xomega. } *)
(*     rewrite align_divisible; try xomega; cycle 1. *)
(*     { apply align_divides. xomega. } *)
(*     rewrite align_divisible; try xomega; cycle 1. *)
(*     apply Z.divide_add_r; try xomega. *)
(*     - apply align_divides; auto. xomega. *)
(*     - reflexivity. *)
(*   Qed. *)

(* End DUMMY_FUNCTION. *)

(* Hint Rewrite dummy_function_used_callee_save: dummy. *)
(* Hint Rewrite dummy_function_bound_local: dummy. *)
(* Hint Rewrite dummy_function_bound_outgoing: dummy. *)
(* Hint Rewrite dummy_function_bound_stack_data: dummy. *)
(* Hint Rewrite dummy_function_size_callee_save_area: dummy. *)
(* Hint Rewrite dummy_function_fe_ofs_local: dummy. *)
(* Hint Rewrite dummy_function_fe_ofs_link: dummy. *)
(* Hint Rewrite dummy_function_fe_ofs_retaddr: dummy. *)
(* Hint Rewrite dummy_function_fe_size: dummy. *)

Print typesize.
Print loc_arguments_64. (* always + 2 *)
(* Lemma loc_arguments_64_complete *)
(*       x tys ir fr *)
(*       (SIZE0: x < 4 * size_arguments_64 tys ir fr 0) *)
(*       (SIZE1: 0 <= x) *)
(*       (IR: 0 <= ir) *)
(*       (FR: 0 <= fr) *)
(*   : *)
(*     exists sl pos ty, <<IN: In (S sl pos ty) (loc_arguments_64 tys ir fr 0).(regs_of_rpairs)>> *)
(*                             /\ <<OFS: pos <= x < pos + 4 * ty.(typesize)>> *)
(* . *)
(* Proof. *)
(*   ginduction tys; ii; ss. *)
(*   { xomega. } *)
(*   destruct a; ss. *)
(*   - des. *)
(*     des_ifs; try (exploit IHtys; eauto; try xomega; i; des; []; esplits; eauto; ss; right; eauto). *)
(*     assert(6 <= ir). *)
(*     { xomega. } *)
(*     ss. esplits; eauto; try xomega. ss. rewrite Z.add_0_l in *. rewrite Z.mul_1_r. *)
(*     unfold size_arguments_64 in SIZE0. ss. des_ifs. *)
(*     u in SIZE0. *)
(*     destruct ir; try xomega. *)
(*     ss. *)
(*   - *)
(* Qed. *)

(* Lemma size_arguments_loc_arguments *)
(*       ofs sg *)
(*       (SIZE: 0 <= ofs < 4 * size_arguments sg) *)
(*   : *)
(*     exists sl pos ty, In (S sl pos ty) (loc_arguments sg).(regs_of_rpairs) *)
(* . *)
(* Proof. *)
(*   destruct sg; ss. unfold size_arguments in *. unfold loc_arguments in *. des_ifs_safe. ss. clear_tac. *)
(*   ginduction sig_args; ii; ss. *)
(*   { xomega. } *)
(* Qed. *)




Section SEPARATIONC.

  Lemma disjoint_footprint_drop_empty
        P Q0 Q1
        (EMPTY: Q0.(m_footprint) <2= bot2)
        (DISJ: disjoint_footprint P Q1)
  :
    <<DISJ: disjoint_footprint P (Q0 ** Q1)>>
  .
  Proof.
    ii. ss. unfold disjoint_footprint in *. des; eauto.
    eapply EMPTY; eauto.
  Qed.

  Lemma disjoint_footprint_mconj
        P Q0 Q1
        (DISJ0: disjoint_footprint P Q0)
        (DISJ1: disjoint_footprint P Q1)
  :
    <<DISJ: disjoint_footprint P (mconj Q0 Q1)>>
  .
  Proof.
    ii. ss. unfold disjoint_footprint in *. des; eauto.
  Qed.

  Lemma disjoint_footprint_sepconj
        P Q0 Q1
        (DISJ0: disjoint_footprint P Q0)
        (DISJ1: disjoint_footprint P Q1)
  :
    <<DISJ: disjoint_footprint P (Q0 ** Q1)>>
  .
  Proof.
    ii. ss. unfold disjoint_footprint in *. des; eauto.
  Qed.

  (* Lemma mconj_sym *)
  (*       P Q *)
  (*   : *)
  (*     <<EQ: massert_eqv (mconj P Q) (mconj Q P)>> *)
  (* . *)
  (* Proof. *)
  (*   red. *)
  (*   split; ii. *)
  (*   - econs. *)
  (*     + ii. unfold mconj in *. ss. des; ss. *)
  (*     + ii. ss. des; eauto. *)
  (*   - econs. *)
  (*     + ii. unfold mconj in *. ss. des; ss. *)
  (*     + ii. ss. des; eauto. *)
  (* Qed. *)

  Lemma massert_eq
        pred0 footprint0 INVAR0 VALID0
        pred1 footprint1 INVAR1 VALID1
        (EQ0: pred0 = pred1)
        (EQ1: footprint0 = footprint1)
    :
      Build_massert pred0 footprint0 INVAR0 VALID0 = Build_massert pred1 footprint1 INVAR1 VALID1
  .
  Proof.
    clarify.
    f_equal.
    apply Axioms.proof_irr.
    apply Axioms.proof_irr.
  Qed.

  Axiom prop_ext: ClassicalFacts.prop_extensionality.

  Lemma mconj_sym
        P Q
    :
      <<EQ: (mconj P Q) = (mconj Q P)>>
  .
  Proof.
    apply massert_eq; ss.
    - apply Axioms.functional_extensionality. ii; ss.
      apply prop_ext.
      split; i; des; split; ss.
    - apply Axioms.functional_extensionality. ii; ss.
      apply Axioms.functional_extensionality. ii; ss.
      apply prop_ext.
      split; i; des; eauto.
  Qed.

End SEPARATIONC.





Section PRESERVATION.

Local Existing Instance Val.mi_normal.
Context `{SimSymbId: @SimSymb.SimSymb.class SimMemInj}.
Variable prog: Linear.program.
Variable tprog: Mach.program.
Hypothesis TRANSF: match_prog prog tprog.
Variable return_address_offset: function -> code -> ptrofs -> Prop.
Let match_states := match_states prog tprog return_address_offset.

Lemma functions_translated_inject
      j
      (GENV: True)
      fptr_src fd_src
      (FUNCSRC: Genv.find_funct (Genv.globalenv prog) fptr_src = Some fd_src)
      fptr_tgt
      (INJ: Val.inject j fptr_src fptr_tgt)
  :
    exists fd_tgt,
      <<FUNCTGT: Genv.find_funct (Genv.globalenv tprog) fptr_tgt = Some fd_tgt>>
      /\ <<TRANSF: transf_fundef fd_src = OK fd_tgt>>
.
Proof.
  admit "easy".
Qed.

Definition msp: ModSemPair.t :=
  ModSemPair.mk (LinearC.modsem prog) (MachC.modsem return_address_offset tprog) (admit "simsymb") Nat.lt.

Local Transparent dummy_stack.

Ltac sep_split := econs; [|split]; swap 2 3.
Hint Unfold fe_ofs_arg.
Hint Unfold SimMem.SimMem.sim_regset. (* TODO: move to proper place *)
Hint Unfold mregset_of.
Ltac perm_impl_tac := eapply Mem.perm_implies with Writable; [|eauto with mem].

Lemma match_stack_contents
      sm_init
      (MWF: SimMem.SimMem.wf sm_init)
      ra_blk delta_ra
      rs_init_src rs_init_tgt
      (RSREL: (SimMem.SimMem.sim_regset) sm_init rs_init_src rs_init_tgt)
      (RA: rs_init_tgt RA = Vptr ra_blk delta_ra true)
      fd_src fd_tgt
      (FINDFSRC: Genv.find_funct (Genv.globalenv prog) (rs_init_src PC) = Some (Internal fd_src))
      (FINDFTGT: Genv.find_funct (Genv.globalenv tprog) (rs_init_tgt PC) = Some (Internal fd_tgt))
      (TRANSFF: transf_function fd_src = OK fd_tgt)
      ls_init vs_init m_init_src
      (LOADARGSSRC: load_arguments rs_init_src (src_mem sm_init) (Linear.fn_sig fd_src) vs_init m_init_src)
      (LOCSET: fill_arguments (Locmap.init Vundef) vs_init (Linear.fn_sig fd_src).(loc_arguments)
               = Some ls_init)
      sp_src sp_tgt delta_sp
      (RSPSRC: rs_init_src RSP = Vptr sp_src Ptrofs.zero true)
      (RSPTGT: rs_init_tgt RSP = Vptr sp_tgt (Ptrofs.repr delta_sp) true)
      (RSPINJ: inj sm_init sp_src = Some (sp_tgt, delta_sp))
  :
    <<MATCHSTACK:
    sm_init.(tgt_mem) |= stack_contents tprog return_address_offset (inj sm_init)
                      [LinearC.dummy_stack (Linear.fn_sig fd_src) ls_init]
                      [dummy_stack (rs_init_tgt RSP) (Vptr ra_blk delta_ra true)] **
                      minjection (inj sm_init) m_init_src **
                      globalenv_inject (Genv.globalenv prog) sm_init.(inj)>>
.
Proof.
  u in RSREL.
Local Opaque sepconj.
Local Opaque function_bounds.
Local Opaque make_env.
  rewrite RSPTGT. u.
  unfold dummy_frame_contents.
  rewrite sep_comm. rewrite sep_assoc.
  inv LOADARGSSRC. rename PERM into PERMSRC. rename VAL into VALSRC. rename DROP into DROPSRC.
  rewrite RSPSRC in *. clarify. rename sp into sp_src.
  assert(DELTA: 0 < size_arguments (Linear.fn_sig fd_src) ->
                0 <= delta_sp <= Ptrofs.max_unsigned
                /\ 4 * size_arguments (Linear.fn_sig fd_src) + delta_sp <= Ptrofs.max_unsigned).
  {
    i.
    Print Mem.inject'.
    split.
    - exploit Mem.mi_representable; try apply MWF; eauto; cycle 1.
      { instantiate (1:= Ptrofs.zero). rewrite Ptrofs.unsigned_zero. xomega. }
      left. rewrite Ptrofs.unsigned_zero. eapply Mem.perm_cur_max.
      perm_impl_tac. eapply PERMSRC. split; try xomega.
    -
      assert(SZARGBOUND: 4 * size_arguments (Linear.fn_sig fd_src) <= Ptrofs.max_unsigned).
      {
        hexploit size_no_overflow; eauto. intro OVERFLOW.
        clear - OVERFLOW.
        Local Transparent function_bounds.
        Local Transparent make_env.
        u in *.
        ss.
        des_ifs. unfold function_bounds in *. cbn in *.
        admit "Add this in initial_frame of LinearC".
      }
      exploit Mem.mi_representable; try apply MWF; eauto; cycle 1.
      { instantiate (1:= (4 * size_arguments (Linear.fn_sig fd_src)).(Ptrofs.repr)).
        rewrite Ptrofs.unsigned_repr; cycle 1.
        { split; try xomega. }
        i. des. xomega.
      }
      right.
      rewrite Ptrofs.unsigned_repr; cycle 1.
      { split; try xomega. }
      eapply Mem.perm_cur_max. perm_impl_tac.
      eapply PERMSRC. split; try xomega.
  }
  assert(MINJ: Mem.inject (inj sm_init) m_init_src (tgt_mem sm_init)).
  { eapply Mem_set_perm_none_left_inject; eauto. apply MWF. }
  sep_split.
  { simpl. eassumption. }
  { apply disjoint_footprint_drop_empty.
    { ss. }
    intros ? delta INJDUP. ii. ss. des. clarify.
    rename delta into ofstgt. rename b0 into sp_src'. rename delta0 into delta_sp'.
    destruct (classic (0 < size_arguments (Linear.fn_sig fd_src))); cycle 1.
    { omega. }
    special DELTA; ss. clear_tac.
    rewrite Ptrofs.unsigned_repr in *; try omega.
    (* exploit Mem_set_perm_none_impl; eauto. clear INJDUP0. intro INJDUP0. *)
    assert(sp_src' = sp_src).
    { apply NNPP. intro DISJ.
      hexploit Mem.mi_no_overlap; try apply MWF. intro OVERLAP.
      exploit OVERLAP; eauto.
      { eapply Mem_set_perm_none_impl; eauto. }
      { eapply Mem.perm_cur_max. perm_impl_tac. eapply PERMSRC. instantiate (1:= ofstgt - delta_sp). xomega. }
      { intro TMP. des; eauto. apply TMP; eauto. rewrite ! Z.sub_add. ss. }
    }
    clarify.
    hexploit Mem_set_perm_none_spec; eauto. i; des.
    eapply INSIDE; eauto. omega.
  }
  sep_split.
  { ss. admit "sim_genv". }
  { ss. }
  ss. rewrite Ptrofs.unsigned_repr_eq.
  assert(POSBOUND: forall p, 0 <= p mod Ptrofs.modulus < Ptrofs.modulus).
  { i. eapply Z.mod_pos_bound; eauto. generalize Ptrofs.modulus_pos. xomega. }
  split; eauto.
  split; eauto.
  { eapply POSBOUND. }
  destruct (classic (0 < size_arguments (Linear.fn_sig fd_src))); cycle 1.
  { esplits; auto.
    - specialize (POSBOUND delta_sp). xomega.
    - ii. xomega.
    - i. generalize (typesize_pos ty). i. xomega.
  }
  special DELTA; ss.
  des.
  specialize (POSBOUND delta_sp). unfold Ptrofs.max_unsigned in *.
  erewrite Z.mod_small; try xomega.
  split; try xomega.
  Ltac dsplit_r := let name := fresh "DSPLIT" in eapply dependent_split_right; [|intro name].
  dsplit_r; try xomega.
  { rewrite Z.add_comm.
    change (delta_sp) with (0 + delta_sp).
    eapply Mem.range_perm_inject; try apply MWF; eauto.
  }
  ii; des.
  {
    rename H1 into OFS0. rename H2 into OFS1. rename H3 into OFS2.
    clear - VALSRC LOCSET PERMSRC DSPLIT (* DROPSRC *) RSPSRC RSPTGT RSPINJ OFS0 OFS1 OFS2 MWF.
    abstr (Linear.fn_sig fd_src) sg.
    unfold extcall_arguments in *.
    exploit fill_arguments_spec_slot; eauto.
    { admit "Add this in initial_frame of LinearC". }
    i; des.
    set (loc_arguments sg) as locs in *.
    assert(LOADTGT: exists v, Mem.load (chunk_of_type ty) (tgt_mem sm_init) sp_tgt (delta_sp + 4 * ofs) = Some v).
    { eapply Mem.valid_access_load; eauto.
      hnf.
      rewrite align_type_chunk. rewrite <- PLAYGROUND.typesize_chunk.
      split; try xomega.
      - ii. perm_impl_tac. eapply DSPLIT. xomega.
      - apply Z.divide_add_r.
        + rewrite <- align_type_chunk.
          eapply Mem.mi_align; try apply MWF; eauto.
          instantiate (1:= Nonempty).
          instantiate (1:= 0).
          rewrite Z.add_0_l.
          ii. apply Mem.perm_cur_max. perm_impl_tac. eapply PERMSRC.
          rewrite <- PLAYGROUND.typesize_chunk in *. xomega.
        + apply Z.mul_divide_mono_l. ss.
    }
    destruct (classic (In (S Outgoing ofs ty) (regs_of_rpairs locs))).
    - exploit INSIDE; eauto. i; des.
      + rewrite Z.add_comm.
        eapply Mem.load_inject; try apply MWF; eauto.
      + rewrite UNDEF.
        esplits; eauto.
    - exploit OUTSIDE; eauto. intro LOCSRC; des.
      rewrite LOCSRC.
      exploit Mem.valid_access_load; eauto.
      { hnf. instantiate (2:= chunk_of_type ty).
        rewrite align_type_chunk. rewrite <- PLAYGROUND.typesize_chunk.
        instantiate (1:= delta_sp + 4 * ofs).
        instantiate (1:= sp_tgt).
        instantiate (1:= sm_init.(tgt_mem)).
        split; try xomega.
        - ii. perm_impl_tac. eapply DSPLIT. xomega.
        - apply Z.divide_add_r.
          + rewrite <- align_type_chunk.
            eapply Mem.mi_align; try apply MWF; eauto.
            instantiate (1:= Nonempty).
            instantiate (1:= 0).
            rewrite Z.add_0_l.
            ii. apply Mem.perm_cur_max. perm_impl_tac. eapply PERMSRC.
            rewrite <- PLAYGROUND.typesize_chunk in *. xomega.
          + apply Z.mul_divide_mono_l. ss.
      }
  }
Qed.

Theorem init_match_states
        (sm_init: SimMem.SimMem.t) fptr_init_src fptr_init_tgt
        (FPTRREL: Val.inject (inj sm_init) fptr_init_src fptr_init_tgt)
        rs_init_src rs_init_tgt
        (RSREL: SimMem.SimMem.sim_regset sm_init rs_init_src rs_init_tgt)
        (WF: wf' sm_init)
        (SIMSKENV: ModSemPair.sim_skenv msp sm_init)
        st_init_src
        (INITSRC: LinearC.initial_frame prog rs_init_src sm_init.(src_mem) st_init_src)
  :
    exists st_init_tgt,
      <<INITTGT: initial_frame tprog rs_init_tgt (tgt_mem sm_init) st_init_tgt>>
                               /\ <<MATCH: match_states st_init_src st_init_tgt>>
.
Proof.
  ss. u in *. unfold ModSemPair.sim_skenv in *. ss. clear SIMSKENV.
  inv INITSRC.
  exploit (functions_translated_inject); eauto. intro FPTRTGT; des.
  destruct fd_tgt; ss; unfold bind in *; ss; des_ifs.
  rename fd into fd_src. rename f into fd_tgt.
  assert(RSPINJ:= RSREL SP).
  ss. rewrite RSPPTR in *. inv RSPINJ.
  rename H1 into RSPPTRTGT. symmetry in RSPPTRTGT. rename H2 into RSPINJ.
  rename sp into sp_src. rename b2 into sp_tgt. rename m_init into m_init_src.
  rewrite Ptrofs.add_zero_l in *.
  esplits; eauto.
  - econs; eauto.
  -
    assert(PTRRA: is_real_ptr (rs_init_tgt RA)).
    { admit "add to sem (of LinearC)". }
    u in PTRRA. des_ifs. clear_tac.
    rename b into ra. rename i into delta_ra. rename delta into delta_sp. clear_tac.

    econs; eauto.
    + econs 1; eauto; cycle 1.
      { rewrite RSPPTRTGT. ss. }
      i.
      assert(ACC: loc_argument_acceptable (S Outgoing ofs ty)).
      { eapply loc_arguments_acceptable_2; eauto. }
      assert(VALID: slot_valid (dummy_function (Linear.fn_sig fd_src)) Outgoing ofs ty).
      { destruct ACC. unfold slot_valid, proj_sumbool.
        rewrite zle_true by omega. rewrite pred_dec_true by auto. reflexivity. }
      {
        intros; red.
          eapply Z.le_trans with (size_arguments _); eauto.
          apply loc_arguments_bounded; eauto.
        u.
        xomega.
      }
    + ii.
      u in RSREL.
      u in RSREL. u.
      u.
      assert((ls_init (R r)) = Vundef \/ (ls_init (R r)) = rs_init_src (preg_of r)).
      { hexploit fill_arguments_spec_reg; eauto.
        { apply LOADARG. }
        i; des.
        specialize (H r). des.
        destruct (classic (In (R r) (regs_of_rpairs (loc_arguments (Linear.fn_sig fd_src))))).
        - special INSIDE; ss. des; eauto.
        - special OUTSIDE; ss. eauto. }
      des.
      * rewrite H. econs; eauto.
      * rewrite H. eapply RSREL.
    + ii. des_ifs.
    + eapply match_stack_contents; eauto. ss.
Qed.

Theorem sim
  :
    ModSemPair.sim msp
.
Proof.
  econs; eauto.
  { admit "garbage". }
  ii.
  ss.
  split; ss.
Qed.

End PRESERVATION.
