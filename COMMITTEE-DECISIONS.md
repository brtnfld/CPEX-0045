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

Open items carry **no recommendation**. Where the draft already implements one of the options,
that is a *placeholder* — chosen so the document stays internally consistent while the question
is open — and is not advocacy. The 2026-08-04 agenda follows the same convention.

Implementation effort is not a decision factor. Nothing in CPEX-45 has been released, so no
option is constrained by shipped code or archival files.

Note that the placeholder framing does not fully succeed: the first reviewer to respond read it
as an "implicit recommendation". Recording which option the draft implements appears to be
unavoidably suggestive, so treat concurrence with a draft position as weaker evidence than an
independently reasoned answer.

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

**Design notes.** Option 3 is the only option that eliminates the redundancy rather than
managing it — under options 1 and 2 the two children coexist and the precedence rule is what
keeps them consistent. Its storage saving, sometimes cited in its favour, is in fact small:
`ElementInterpolation_t` hangs off `Family_t`, so the coordinate array is already shared across
all elements of a type and order rather than stored per element. So option 3 should be judged on
removing the redundancy, not on file size.

**Draft position (placeholder, not a preference).** The draft implements option 1, with an
explicit precedence rule so the "inconsistent in general" case is defined rather than left to
implementations. This is only so the document is internally consistent while the question is
open. Option 3 remains fully available: it is the only option under which the two children
cannot contradict each other, because only one of them would be present.

**Reviewer response (2026-07-30, Tobias Leicht).** Supports option 1 — what the draft does. No
argument advanced for option 2 or 3.

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

**Scope, verified against the draft.** Nothing here constrains the choice:

- The enumerator appears only as an argument *value* (`loc` in `cg_sol_ptset_write`), never
  in a function name. A rename changes no API signature.
- `cg_solution_interpolation_points_write` and siblings are named for the
  `LagrangeControlPoints` array, not for this enumerator, and are already rejected for
  modal types. They are unaffected.
- No released CGNS version writes value 9, so there is no archival-file compatibility to
  protect.

**Arguments for keeping the current name.** Every other `GridLocation_t` value names a place —
`Vertex`, `CellCenter`, `FaceCenter`, `EdgeCenter` — so `InterpolationDOF` would sit oddly in
that list. And no name repairs the underlying awkwardness: applying `GridLocation` to modal
coefficients is an abuse whatever it is called, since coefficients are not located anywhere.
A better name is less wrong, not right.

**Timing.** Once the enumerator is approved and the value ships, the name is effectively
permanent, so this is best settled now rather than deferred — a point about reversibility, not
about effort.

**Reviewer response (2026-07-30, Tobias Leicht).** Supports keeping `InterpolationPoints`,
while maintaining that the name is not "correct". Reasoning: the underlying problem is probably
not resolvable, because `GridLocation` must be specified but in the modal case there is no
location; and `InterpolationDOF` is not clearly better for intuitive understandability. Given
that, keeping `InterpolationPoints` is the most consistent choice — it matches the concept of
`GridLocation` — provided the generalised meaning in the monomial case is documented briefly
but clearly.

This converges with the draft, and independently reaches the same conclusion the register
records above: no name repairs the abuse, so a better name would be less wrong rather than
right. The reviewer asked for the gloss to be brief as well as clear; §New `GridLocation_t`
Value currently spends a full paragraph on it, which may be worth tightening.

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

**Scope, verified 2026-07-29.** Option 2 would reach the `cg_sol_interpolation_order_{read,write}`
signatures with their `os`/`ot` arguments, and the on-disk `InterpolationOrders` node name.
**None of these are released:** `cg_sol_interpolation_order` and `InterpolationOrders` appear zero
times on both `origin/master` and `origin/develop`, existing only on `CPEX45_high_order_wip`. So
there is no compatibility constraint here either.

The one consideration that is not about effort: "order" is the term used in the v2 text the
Committee has already approved, so renaming means the v3 amendment departs from approved wording.
`InterpolationPoints` in D-02 has no such v2 precedent, being itself a v3 addition.

**Draft position (placeholder, not a preference).** The draft implements option 1: a normative
note in §Conventions stating that order means degree, that $p=1$ is linear and $q=0$ is
constant in time, and that this differs from the order $=$ degree $+1$ convention. The
confusing "order-2 modal interpolation" example has been reworded to "degree $p=2$
(quadratic)". Surfaced to the committee regardless, because if anyone *does* want the rename it
has to happen alongside the other v3 wire-format changes rather than later.

**Reviewer response (2026-07-30, Tobias Leicht).** Supports option 1 — keep the names, document
the meaning. Note that this reviewer is the one who raised the issue, so the objection is
satisfied by documentation rather than by a rename.

---

### Interactions between the open items

**Implementation effort is not a decision factor, and neither is compatibility.** Nothing in
CPEX-45 has been released. Verified 2026-07-29: `cg_sol_interpolation_order` and
`InterpolationOrders` appear **zero** times on both `origin/master` and `origin/develop`, and no
released CGNS version writes `GridLocation` value 9. Every name under discussion exists only on
`CPEX45_high_order_wip`. There are therefore no archival files, no shipped APIs, and no
downstream users to protect, and each of these questions should be settled on what is correct
for the standard.

**D-02 and D-03 are both purely naming questions.** In both the draft keeps the existing name,
and in both the choice is unconstrained by anything already shipped. The one substantive
difference is not effort: "order" is the term used in the v2 text the Committee has already
approved, so renaming in D-03 means the v3 amendment departs from approved wording, whereas
`InterpolationPoints` is itself a v3 addition with no v2 precedent. If both are taken up in one
session, a decision on either must not be read as a decision on the other.

**D-01 has a consequence for C-04.** The `cgnscheck` change recorded in C-04 follows from the
option-1 placeholder, so options 2 and 3 would each mean revisiting it. Noted for tracking, not
as an argument for option 1.

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

**Reviewer position (2026-07-30, Tobias Leicht).** Would vote yes on all six. One reviewer, not
a quorum — the motions still stand.

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
§Lagrange Control Point Distribution assigns to `cgnscheck` is **not implemented**, so the spec
currently asserts behaviour that does not exist; it must either be implemented or the sentence
withdrawn. (For scoping only, not as an argument either way: it would need Legendre and
Warp&Blend node generation the library does not yet contain, `Equidistant` being the one trivial
case.) And no test in the tree references the attribute at all, so the new
`ElementInterpolation_t` branch is unexercised.

If the committee chooses option 2 or 3 under D-01, this change must be revisited.

---

### C-05 — Mesh interpolation restricted to nodal; element-side modal API removed

`DECIDED` (editorial, no vote; spec `66e9742`). Review asked why `ElementInterpolation_t` had a
`MonomialCoefficients` child when the v2 principles restrict mesh geometry to control points.
It should not have. The third v2 principle states that the mesh is always defined by control
points in parametric space, and the second offers the three-way choice for the *solution*
interpolation. Allowing modal geometry would also have required changing the element
connectivity description, which v2 explicitly set out to preserve.

An `ElementInterpolation_t` now carries no `MonomialCoefficients`, and its interpolation type is
either `ParametricLagrange` or `IsoParametric`. Removed across thirteen spec sites, and from the
implementation on `CPEX45_high_order_wip`: `cg_element_monomial_size` and
`cg_element_interpolation_coefficients_{read,write}` in `cgnslib.h`/`cgnslib.c` and the Fortran
bindings, the `monomialCoeff` field on the element struct, the reader branch in
`cgns_internals.c` (which now rejects the child by name), and the element-modal tests.

Two notes from the implementation pass. `test_modal_interpolation.c` had a `test_cartesian_modal`
case writing `CartesianMonomialsPascal` onto an `ElementInterpolation_t` — a combination the
document forbade *before* this change, so the suite was exercising something already invalid.
Deleting it removes the only Cartesian-modal round-trip coverage in the tree; a solution-side
replacement is worth adding. And no test asserted the element-modal path was rejected, so the
new rejection is unexercised.

### C-06 — `cg_element_interpolation_points_read` keeps returning `CG_NODE_NOT_FOUND` for `IsoParametric`

`DECIDED` (design, no vote). Review asked whether returning `CG_NODE_NOT_FOUND` was a needless
implementation choice, given the call could return the convention points as a convenience.

It is deliberate, for a reason the draft had not stated: the return value distinguishes a file
that recorded its own control-point distribution from one that did not. A writer storing
`LagrangeControlPoints` may place them anywhere unisolvent — GLL, say — whereas `IsoParametric`
means the equidistant lattice of the standard layout. Synthesising points would erase exactly
the distinction the array exists to record, and it is the same distinction D-01 turns on.

The reviewer's underlying need is nonetheless real, and wider than the read call: verified
2026-07-31, the library has no route to those coordinates at all. `cg_npe_ho`,
`cg_element_dimension`, `cg_element_basic_element_type` and
`cg_element_lagrange_interpolation_size` are all file-independent element-type queries, but none
returns locations, and neither does anything else. What resolves it is that the locations are not
implementation-defined: they are the equidistant lattice on the element's reference domain in the
standard node order, both normative in §Standard Coordinate Systems, so a reader reconstructs
them from the element type alone. The spec now says so at the point of confusion, and records a
convenience helper returning that lattice as a candidate addition — deliberately not a
requirement, since the library currently holds neither the coordinates nor the high-order node
ordering in any form, and a wrong table would be worse than none.

---

## D. Closed

*None yet.*
