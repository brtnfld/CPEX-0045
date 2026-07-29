# CPEX-0045 v3 — Committee Decision Register

Tracks decisions the CGNS Steering Committee needs to make on the v3 amendment, so they
can be put on a meeting agenda and worked through systematically rather than rediscovered
from review threads.

Not part of the published spec. `CPEX-0045-high-order-interpolation.tex` remains the source
of truth for normative text; this file records *what still needs deciding* and *what was
decided during review*.

The register is organised as follows.

- **A. Open decisions** — need a committee call before the amendment is final. Agenda items.
- **B. Ballot items** — the `[NEW]` change-list entries, which require a vote regardless of
  whether anyone has objected to them.
- **C. Decisions taken during review** — settled in the draft; recorded so the committee can
  ratify or reopen, not re-litigate silently.
- **D. Closed** — resolved, kept for the audit trail.

Status values: `OPEN`, `NEEDS-VOTE`, `DECIDED`, `CLOSED`.

Open items deliberately carry **no recommendation**. Where the draft already implements one of
the options, that is recorded as a *placeholder* — chosen so the document stays internally
consistent while the question is open — and must not be read as advocacy. The published
2026-08-04 agenda follows the same convention.

---

## A. Open decisions

### D-01 — Is `LagrangeControlPointDistribution` required or recommended?

- **Status:** `OPEN`
- **Raised by:** reviewer comment on the change-list entry (Overleaf); raised a second time,
  independently, against the `ElementInterpolation_t` node definition
- **Spec refs:** §Lagrange Control Point Distribution; change-list item 1; File Mapping (both
  node tables); Validation Requirements (Reader); Cross-Validation Rules (Writer);
  Compliance Tests
- **Current draft:** recommended, not required; coordinates authoritative on conflict

**Background.** The original rationale claimed a reader "cannot reconstruct basis functions
from control-point positions alone." That is false as the format stands.
`LagrangeControlPoints` stores the parametric coordinates explicitly, and the element type
and order fix the reference domain and the polynomial space, so the nodal basis is uniquely
determined by $\lambda_i(\mathbf{u}_j)=\delta_{ij}$ wherever the stored point set is
unisolvent. The attribute is derivable from the data, not needed to interpret it.

The same reviewer raised this a second time against the `ElementInterpolation_t` node
definition, and added the sharper form of the objection: the two children are *redundant at
best and inconsistent in general*. That exposed a real gap — the draft had no rule for what a
reader should do when the stored coordinates and the named distribution disagree. It now has
one (see "Resolved sub-question" below), but the committee should still settle the
required-versus-recommended question itself.

**Resolved sub-question (editorial, no vote needed).** Precedence on conflict. The draft now
states that the coordinates are authoritative and the name is advisory: a reader must build a
basis interpolating at the stored coordinates, may use the named family only after confirming
agreement within tolerance, must fall back to the coordinates and warn otherwise, and must
never silently substitute the family's nodes. A mismatch is explicitly *not* grounds for
rejecting the file. Writers must not record a disagreeing name, and `cgnscheck` reports a
mismatch (error under `-s`, warning otherwise) with the remedy being to fix or drop the name,
never to alter the coordinates. This mirrors the existing `CharacteristicLength` rule, where
writers record the factors they actually used and readers must not recompute a formula.

**Question.** Which of these does the committee want?

1. **Recommended (current draft).** Justified by conditioning (closed-form barycentric
   weights beat inverting an ill-conditioned Vandermonde matrix at high $p$), precision
   (stored coordinates are `R8`-rounded, whereas the interior nodes of the non-equidistant
   families are irrational at all but the lowest orders), and validation (`cgnscheck` can
   cross-check the stored points against the named family).
2. **Required.** Keeps the stronger conformance statement, but the spec would be mandating
   an attribute that carries no information a conforming reader needs.
3. **Make it load-bearing.** Allow `LagrangeControlPoints` to be *omitted* when the
   distribution is named, implying the points from family + order + element type. This is
   the only option under which the original rationale is correct as written.

**Cost notes.** Option 3 is the largest change and would need new normative text plus
implementation work. Its space saving is modest: `ElementInterpolation_t` hangs off
`Family_t`, so the coordinate array is already shared across all elements of a type and
order rather than stored per element. Option 3 is also the only option that eliminates the
redundancy rather than managing it — under options 1 and 2 the two children coexist and the
precedence rule is what keeps them consistent.

**Draft position (placeholder, not a preference).** The draft implements option 1, with an
explicit precedence rule so the "inconsistent in general" case is defined rather than left to
implementations. This is only so the document is internally consistent while the question is
open. Option 3 remains fully available: it is the only option under which the two children
cannot contradict each other, because only one of them would be present.

---

### D-02 — Keep the `InterpolationPoints` enumerator name, or rename?

- **Status:** `OPEN`
- **Raised by:** reviewer comment on the change-list entry (Overleaf)
- **Spec refs:** §New `GridLocation_t` Value: `InterpolationPoints`; change-list item 2;
  ~20 further mentions
- **Current draft:** name kept; explanatory gloss added

**Background.** "Interpolation points" describes the Lagrange case accurately but not the
modal types, where the stored entries are expansion coefficients with no associated point.
The reviewer confirmed the *content* is correct — the sizing rule and element-index
semantics are stated once and hold for both flavours — and scoped the objection to naming.

**Question.** Keep `InterpolationPoints`, or rename to something flavour-neutral such as
`InterpolationDOF`?

**Cost notes.** Lower than it first appears, and verified against the draft:

- The enumerator appears only as an argument *value* (`loc` in `cg_sol_ptset_write`), never
  in a function name. A rename changes no API signature.
- `cg_solution_interpolation_points_write` and siblings are named for the
  `LagrangeControlPoints` array, not for this enumerator, and are already rejected for
  modal types. They are unaffected.
- No released CGNS version writes value 9, so there is no archival-file compatibility to
  protect. The churn is this document plus the `CPEX45_high_order_wip` branch.

**For keeping it.** Every other `GridLocation_t` value names a place — `Vertex`,
`CellCenter`, `FaceCenter`, `EdgeCenter` — so `InterpolationDOF` would sit oddly in that
list. And no name repairs the underlying awkwardness: applying `GridLocation` to modal
coefficients is an abuse whatever it is called, since coefficients are not located anywhere.
A better name is less wrong, not right.

**Timing.** Pre-vote is the cheapest this will ever be. Once the enumerator is approved and
the value ships, the name is effectively permanent.

---

### D-03 — Is "order" the right word for what is actually a polynomial degree?

- **Status:** `OPEN`
- **Raised by:** reviewer comment on the modal cardinality passage (Overleaf)
- **Spec refs:** §Conventions ("Order denotes polynomial degree"); §Parametric Modal
  Interpolation; `InterpolationOrders`, `SpatialOrder`, `TemporalOrder` throughout
- **Current draft:** names kept; explicit terminology note added in §Conventions

**Background.** The spec uses *order* to mean polynomial *degree*, whereas the common
convention is order $=$ degree $+1$. So `SpatialOrder = 2` here is quadratic, not the linear
approximation a reader expecting the other convention would infer. The reviewer noted this is
not a v3 slip but inherited from v2 — and the draft bears that out in v2's own words:

- v2's principles text describes the modal choices as "the maximum **degree** of a Pascal
  polynomial space", while the recorded field is named `Order`.
- A v2 quote defines the purely spatial case as "the (default) temporal order $q=0$" —
  constant in time, which under order semantics would be order 1.

So the usage is consistent and traceable, just mis-named.

**Question.** Which does the committee want?

1. **Keep the v2 names, document the meaning (current draft).** `InterpolationOrders`,
   `SpatialOrder` and `TemporalOrder` are established on-disk node and API argument names;
   renaming them breaks v2 compatibility for no change in information content.
2. **Rename to degree** (`SpatialDegree`, `TemporalDegree`, …). Terminologically correct, but
   changes on-disk names and API signatures, and diverges from approved v2 text.
3. **Keep the names but change the prose convention**, always saying "degree" in narrative
   text and treating "order" purely as a field name. This is close to option 1 and is what
   the draft now does for the numeric cases.

**Cost notes.** Unlike **D-02**, this one *does* reach API signatures
(`cg_sol_interpolation_order_{read,write}`, the `os`/`ot` arguments) and the on-disk
`InterpolationOrders` node name, and it contradicts text already approved in v2. Option 2 is
substantially more disruptive than the other two open items.

**Draft position (placeholder, not a preference).** The draft implements option 1: a normative
note in §Conventions stating that order means degree, that $p=1$ is linear and $q=0$ is
constant in time, and that this differs from the order $=$ degree $+1$ convention. The
confusing "order-2 modal interpolation" example has been reworded to "degree $p=2$
(quadratic)". Surfaced to the committee regardless, because if anyone *does* want the rename it
has to happen alongside the other v3 wire-format changes rather than later.

---

### Interactions between the open items

**D-02 and D-03 look alike but are not.** Both ask whether to rename something, and in both the
draft keeps the existing name. The costs differ sharply:

- **D-02** (`InterpolationPoints`) touches no API signature and no released file. The
  enumerator appears only as an argument *value*, and no released CGNS version writes value 9.
- **D-03** (`SpatialOrder` / `TemporalOrder`) reaches the on-disk `InterpolationOrders` node
  name, the `cg_sol_interpolation_order_{read,write}` signatures, *and* text already approved
  in v2.

If both are taken up in one session, a decision on either must not be read as a decision on the
other.

**Both renames are one-way doors.** Pre-vote is the cheapest either will ever be. Once the
enumerator value and the node names ship, they are effectively permanent — so "defer" is not a
cost-free option for D-02 or D-03 the way it is for most items.

**D-01 gates implementation work.** The `cgnscheck` change recorded in C-04 follows from the
option-1 placeholder. Options 2 and 3 would each require reworking it, and option 3 would need
new normative text plus new library code.

**One spec claim currently outruns the implementation.** §Lagrange Control Point Distribution
states that `cgnscheck` compares the stored coordinates against the named distribution. It does
not — see C-04. Whichever way D-01 goes, either that check gets implemented or that sentence
gets softened; leaving both as they are ships a spec that promises absent behaviour.

---

## B. Ballot items (`[NEW]` — require a vote)

Six wire-format additions. Each needs a motion; D-01 and D-02 above determine the final
wording of B-1 and B-2 respectively.

- **B-1** — `LagrangeControlPointDistribution_t` enum.
  Wording contingent on **D-01**.
- **B-2** — `GridLocation_t` enumerator `InterpolationPoints` (value 9).
  Name contingent on **D-02**; reclassified from `[CLARIFICATION]`, see **C-01**.
- **B-3** — Mandatory coordinate normalisation for Cartesian modal, with normative
  `CharacteristicLength` encoding (isotropic rank-1 / per-axis rank-2).
  Both encodings ship on `CPEX45_high_order_wip`.
- **B-4** — Mid-Level Library API: full C and Fortran 2003 interface. New normative section.
- **B-5** — SIDS File Mapping: on-disk shapes, data types, DOF ordering. New normative section.
- **B-6** — Implementation Specification: order limits, validation, error codes, defaults.
  New normative section.

The four `[CLARIFICATION]` items (`InterpolationOrders` encoding; `CharacteristicLength` is
metadata not a field; element-tag normalisation; practical order ceiling of the monomial
bases) assert no semantic change to the approved v2 standard and should not need separate
motions — but the committee may want to confirm that characterisation, since C-01 shows one
item was previously mislabelled.

---

## C. Decisions taken during review

### C-01 — `InterpolationPoints` reclassified `[CLARIFICATION]` → `[NEW]`

`DECIDED` (commit `3925f57`). It adds a `GridLocation_t` enumerator and moves the
field-array sizing rule away from the `CellCenter` that v2's own text specified, so it is a
wire-format change and needs a vote like the other new items. Reviewers working from an
Overleaf snapshot older than `3925f57` will still see it as `[CLARIFICATION]`.

### C-02 — Amendment status corrected to "pending Steering Committee vote"

`DECIDED` (commit `3925f57`). The document previously showed SIDS/Filemap/MLL as accepted
while also carrying an unsigned motion and vote block. A proposal cannot be both accepted
and awaiting a vote. All three tracks now read "v2 accepted; v3 amendment pending Steering
Committee vote", with the reference implementation branch listed separately.

### C-03 — Reader validation must not reject `LagrangeControlPointDistribution`

`DECIDED` (editorial, no vote). The reader-validation rule required rejecting any
`DataArray_t` child of `ElementInterpolation_t` / `SolutionInterpolation_t` not named
`LagrangeControlPoints` or `MonomialCoefficients`. Since
`LagrangeControlPointDistribution` *is* a `DataArray_t<Character>`, the rule as written
obliged a conforming reader to reject the very node the spec required. Added to the
allowed-names list.

**This was a document-only defect.** `cgns_internals.c` already accepted the attribute name
in both the element and solution paths, so no reader was ever actually affected — the spec's
validation list had fallen behind the implementation, not the reverse.

### C-04 — `cgnscheck` no longer errors on a missing distribution

`DECIDED` (implementation, follows from the D-01 draft position; commit `b2ca56f` on
`CPEX45_high_order_wip`). `cgnscheck` raised an error under `-s` when
`LagrangeControlPointDistribution` was absent from a `ParametricLagrange` node, and otherwise
warned that "readers will have to assume a default distribution" — both contradicting the
revised text. Replaced in the `ElementInterpolation_t` and `SolutionInterpolation_t` paths
with a single level-2 warning stating the attribute is recommended and the basis is taken
from the coordinates. `cgnscheck -s` on `high_order.cgns` went from 1 error to 0; the 8
high-order, modal and characteristic-length tests pass.

Two gaps remain. The coordinates-versus-distribution consistency check that
§Lagrange Control Point Distribution assigns to `cgnscheck` is **not implemented** — it needs
Legendre and Warp&Blend node generation the library does not contain. If the committee defers
it, that sentence in the spec should be softened, since it currently promises behaviour that
does not exist. And no test in the tree references the attribute at all, so the new
`ElementInterpolation_t` branch is unexercised.

If the committee chooses option 2 or 3 under D-01, this change must be revisited.

---

## D. Closed

*None yet.*
