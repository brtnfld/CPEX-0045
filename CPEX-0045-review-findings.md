# CPEX 0045 v3 Review Findings

**Document**: `CPEX-0045-high-order-interpolation.tex` (v3, 2290 lines, 37 pp.)
**Date**: 2026-08-01
**Verified against**: `CGNS-develop` at `origin/CPEX45_high_order_wip` (`src/cgnslib.{c,h}`,
`src/tools/cgnscheck.c`) — the branch the document names as its implementation evidence —
plus `develop` for the pre-CPEX baseline; `cgns.github.io`
(`docs/html/_sources/standard/SIDS/highorder.rst`, `source/standard/SIDS/*.rst`,
`source/current/CPEX.rst`); the document's own `figures/coord-*.jpg`;
`CPEX-0047_...IntegrationPointDefinition_v3.pdf`; and `CPEX-0050-dof-storage.tex`.
Settled items were checked against `COMMITTEE-DECISIONS.md` so as not to re-raise them.

---

## Executive Summary

This is a mature document — materially stronger than CPEX-0050 was at the equivalent stage. It
builds cleanly (0 errors, 0 undefined references, **0 overfull boxes**), the mathematics that
matters is right (Lagrange space cardinalities, the pyramid formula, the Pascal traversal orders,
the modal binomial count), the reader/writer validation rules and error-code semantics are
unusually complete for a CPEX, and the v2-quote-plus-v3-annotation structure makes the delta from
the approved version genuinely auditable. Most of it is ready.

Two defects are critical, and they are the same defect seen twice: **the reference element domain
for simplices is stated incorrectly, and one compliance test point is wrong under every
convention.**

`§7.9 Coordinate-System Conventions` says TRI/TETRA/PENTA use the *unit* simplex
(`{uᵢ ≥ 0, Σuᵢ ≤ 1}`). The document's own **Figure 1** shows TRI with vertices at
(−1,−1), (1,−1), (−1,1) — the *bi-unit* simplex, hypotenuse `u+v = 0` — and the CGNS
documentation states the bi-unit domains as a **"Critical Interoperability Requirement,"**
explicitly warning that a `[0,1]`-based system "will produce **incompatible** CGNS files."
Because the document also states that the library does not enforce coordinate ranges, a writer
following §7.9 and a reader following Figure 1 disagree on every simplex control point, silently.

The remaining findings are one under-specified enumeration that is nonetheless in the adoption
Motion and fully implemented, two internal encoding inconsistencies, and two cross-CPEX
sequencing collisions that matter because 45, 49 and 50 are being voted at one meeting.

**Recommendation**: fix C1 and C2 before the vote — both are single-paragraph edits. M1–M3 should
be fixed before adoption because they change what a second implementer builds. M4/M5 are
minute-book items, not document defects.

---

## Findings Table

| ID | Location | Area | Severity | Finding | Recommendation |
|----|----------|------|----------|---------|----------------|
| C1 | `.tex:2054-2064` | Technical Accuracy | **Critical** | §Coordinate-System Conventions states simplices use the unit simplex `{uᵢ ≥ 0, Σuᵢ ≤ 1}` and PENTA a base of `{u,v ≥ 0, u+v ≤ 1}`. This contradicts (a) the document's own Figure 1 (`figures/coord-tri.jpg`, `coord-tetra.jpg`), which show vertices at (−1,−1)/(1,−1)/(−1,1) and the bi-unit tetra — i.e. `u+v ≤ 0` and `u+v+w ≤ −1`; (b) the TRI compliance test point (−0.5,−0.3) at `:2181`, which lies outside the unit simplex but inside the bi-unit one; (c) the `Equidistant` definition `uᵢ = −1 + 2i/p` at `:585`, a `[−1,1]` formula applied to all element types; (d) `:571`, which treats a "`[0,1]`-versus-`[−1,1]` domain convention" as a *writer error* `cgnscheck` should catch; and (e) `highorder.rst:112-149`, which states the bi-unit domains under a "**Critical Interoperability Requirement**" heading warning that `[0,1]` "will produce **incompatible** CGNS files." Since `:2065` states the library does not enforce these ranges, the disagreement is silent: control points written per §7.9 and read per Figure 1 are wrong with no diagnostic. | Replace the simplex and prism entries with the bi-unit domains: TRI `{u ≥ −1, v ≥ −1, u+v ≤ 0}`; TETRA `{u,v,w ≥ −1, u+v+w ≤ −1}`; PENTA that triangle extruded along `w ∈ [−1,1]`. This makes §7.9 agree with Figure 1, the test points, the distribution formulae, and the published documentation. §7.9 is the only place stating the unit simplex — no other text needs to change. |
| C2 | `.tex:2181` | Technical Accuracy | **Critical** | The TETRA partition-of-unity test point (−0.6, −0.2, −0.1) sums to −0.9. The bi-unit reference tetrahedron requires `u+v+w ≤ −1`, so the point is **outside** it; the unit simplex requires `uᵢ ≥ 0`, so it is outside that too. The point is invalid under both conventions, and the test is specified "for any **u** in the parametric domain." An implementer coding the compliance suite literally will either test outside the domain or reject the point. (Partition of unity happens to hold identically for a polynomial basis, so the test may still *pass* — which makes this worse, not better: it will not be caught by running it.) | Replace with a point that is interior, e.g. (−0.6, −0.5, −0.4) (sum −1.5 ≤ −1). While there, state explicitly that the listed points are interior to the reference domain, so the constraint is checkable. |
| M1 | `.tex:236,379,1192,1262,1490` | Completeness | **Major** | `LagrangeControlPointDistribution_t` is named as an enumeration in the change list (`:236`) and in the adoption **Motion** (`:379`, item 1), and the implementation on `CPEX45_high_order_wip` defines it as a full CGNS enumeration — `cgnslib.h:1020-1031`: `LagrangeControlPointDistributionNull`/`UserDefined`/`GaussLobattoLegendre`/`Equidistant`/`GaussLegendre`/`WarpAndBlend`, plus `NofValidLagrangeControlPointDistributions 6`, a `LagrangeControlPointDistributionName[]` table, and `cg_LagrangeControlPointDistributionName`. But the **document never defines the enumeration**: the SIDS node definitions declare the child as `DataArray_t<Character>` (`:1192`, `:1262`), the allowed values appear only as prose bullets (`:580-591`), there is no Chapter 4 enumeration section, and the type name appears in the normative body only inside a parameter-table cell (`:1490`). A second implementer working from the CPEX — which is the normative artifact — would build a free-form string field, not an enumeration, and would ship neither the name table nor the name helper. | Add a Chapter 4 enumeration definition for `LagrangeControlPointDistribution_t` with the four values, the `Null`/`UserDefined` members, the count constant, the name table and `cg_LagrangeControlPointDistributionName`, mirroring how `InterpolationType_t` is handled. The Motion already puts the enum to the vote, so this is aligning the text with what is being adopted. |
| M2 | `.tex:1259` vs `:1192,1262` | Standards Compliance | **Major** | Two enumerations in the same parent node are stored two different ways. `InterpolationType_t` is a **labelled enumeration node** — `:1259` declares `InterpolationType_t InterpolationType;` and reader validation (`:1950`) requires "exactly one `InterpolationType_t` child named `InterpolationType`". The distribution is a `DataArray_t` distinguished only by its **name** (`:1192`, `:1262`, filemap `:1660`), so its type is not discoverable by label and validation has to whitelist names instead (`:1946-1949`). Every comparable CGNS enumeration (`GridLocation_t`, `DataClass_t`, `ArbitraryGridMotionType_t`) is a labelled node with C1 data. | Store the distribution as a labelled `LagrangeControlPointDistribution_t` node with C1 data, consistent with `InterpolationType` and with the rest of CGNS. If the `DataArray_t` encoding is deliberate, state the reason — the asymmetry within one node will otherwise read as an oversight. |
| M3 | `.tex:1189` vs `:1626-1629,1937` | Technical Accuracy | **Major** | The `ElementInterpolation_t` SIDS block declares `ElementType_t Element; (r)`, which in SIDS notation is a *required child node*. The File Mapping (`:1626-1629`) instead gives the node itself `datatype = I4, dimensions = 1, dimension values = 1, data = <element type>`, and reader validation (`:1937`) requires "payloads that are **not** `I4` scalar" to be rejected — i.e. the element type is the node's **own payload**, not a child. The sibling `SolutionInterpolation_t` block gets this right, showing its payload in bold as `int[3] InterpolationData;` with an explanatory note (`:1258`, `:1273`). | Present `ElementInterpolation_t`'s payload the same way — e.g. `**int Element;** (r) /* ElementType */` — with a note matching `:1273`. As written, the SIDS block and the filemap specify two incompatible encodings of the required datum. |
| M4 | `.tex:636` | Cross-CPEX | **Major** | `InterpolationPoints = 9` is correct against today's library (`develop`: `EdgeCenter = 8`, `NofValidGridLocation 9`), and the wip branch implements 9 with the count bumped to 10 and the name-table entry added. But **CPEX-0047 appends `IntegrationPoint` to the same enumeration at the same position** (v3 PDF, §A.1.1, extending SIDS 4.5 `GridLocation_t`), so it also claims 9. CPEX-0047 is open (issue #621). Whichever is adopted second must take 10. Scope note: `GridLocation` is stored on disk as a C1 string, so this is a source/ABI clash only — it does **not** affect file compatibility, and should not be overstated as such. | Add a sequencing note of the kind already present for Chapter 12 (`:1150`), stating that the numeric value is assigned at adoption time and that files are unaffected because the token is stored as a string. |
| M5 | `.tex:486,1145-1150` | Cross-CPEX | **Major** | The Chapter 12 renumbering is handled carefully and correctly (new 12.10/12.11; `UserDefinedData_t` 12.10→12.12, `Gravity_t` 12.11→12.13 — verified against `misc.rst`, where 12.10 and 12.11 are currently those two nodes). No equivalent note covers **Chapter 4**, where two other proposals also insert: CPEX-0047 adds a new 4.9 `MapName_t`, and CPEX-0050 adds a new 4.5 and a new 4.9. CPEX-0045 itself adds a new **section 3.4** (`:486`) and, if M1 is adopted, a Chapter 4 enumeration section too — at which point it joins the collision. | Extend the sequencing note to Chapter 4, and coordinate with the CPEX-0047 and CPEX-0050 insertion points. With three proposals inserting into Chapters 4 and 12 in one meeting, the minutes should record the adopted order. |
| M6 | `.tex:1583-1592` | Clarity | **Major** | A retained v2 quote states "the solution is supposed to be attached to `CellCenter`", directly contradicting the v3 normative requirement that high-order solutions use `InterpolationPoints` (`:660`, `:663`, `:1994`). The **identical** v2 claim at `:1318-1325` is immediately followed by "Implementation note 2" correcting it; this occurrence has no annotation, and it sits inside the MLL section where an implementer is most likely to be reading for behaviour. | Add the same correcting note after `:1592`, or cross-reference Implementation note 2. The document's v2-quote convention is otherwise applied consistently, which makes the one gap conspicuous. |
| m1 | `.tex` §Implementation Specification | Completeness | Minor | The Implementation Specification is detailed about order limits, on-disk layout, reader validation, writer cross-validation, error codes, defaults and coordinate conventions, but never states the enumeration-table mechanics that adding a `GridLocation_t` value requires: bumping `NofValidGridLocation` 9→10 and appending `"InterpolationPoints"` to `GridLocationName[]`. Both are implemented on the wip branch (`cgnslib.h:466`, `cgnslib.c:237-241`), and they matter because `cgi_GridLocation` maps strings by iterating `i < NofValidGridLocation` — omit the bump and the new value is unreadable. | Add one line to the Implementation Specification. Not a design gap, but the section is otherwise complete enough that the omission stands out. |
| m2 | `.tex:2063,805,850-860` | Completeness | Minor | The PYRA parametric domain is deferred entirely to `[BCD10]` (`:2063`), while every other element type gets an explicit domain. The CGNS documentation does state one — `{−1 ≤ w ≤ 1, |u| ≤ (1−w)/2, |v| ≤ (1−w)/2}` (`highorder.rst:153`). For a standard whose own documentation warns that a differing reference system yields incompatible files, "see the reference" is weaker than the requirement demands. The cardinality and element tags for PYRA *are* fully specified (`:850-860`, and `PYRA_30`/`PYRA_55` verified present in `cgnslib.h`), so only the domain is missing. | State the domain inline, matching `highorder.rst`, retaining the `[BCD10]` citation for the basis construction. |
| m3 | `.tex:585,593-597` | Clarity | Minor | `Equidistant` is defined once, globally, as `uᵢ = −1 + 2i/p` — a 1-D `[−1,1]` formula. §Multi-dimensional construction then says simplices need `WarpAndBlend` or Fekete for `p>2` and that "equidistant points may be used at `p=2`", but on a simplex the equidistant nodes are barycentric, not `−1 + 2i/p`. The formula does not define what `Equidistant` means on TRI/TETRA. | State the simplex construction explicitly (equispaced barycentric coordinates), or restrict `Equidistant` to tensor-product elements. |
| m4 | `.tex:596` | Completeness | Minor | Fekete distributions are named as one of the two acceptable choices for simplices at `p>2`, but `Fekete` is not among the four enumeration values, so a writer that uses Fekete nodes — which this sentence says is required — has no value to record and must fall back to `LagrangeControlPointDistributionUserDefined`. The document does not say so. | Either add `Fekete` to the enumeration, or state that Fekete nodes are recorded as `UserDefined`. Since the coordinates are authoritative (`:599-608`), the second is sufficient and cheaper. |
| m5 | bibliography | Standards Compliance | Minor | Four of eight bibliography entries are never `\cite`d: `CPEX0036` and `CPEX0038` (referred to in prose at `:452-453` but not cited), `HW08`, and `Mathex`. `HW08` is the natural citation for the reference-element conventions at issue in C1, and `Mathex` is not referred to anywhere in the text at all. | Cite `CPEX0036`/`CPEX0038` at `:452`, cite `HW08` where the reference domains are fixed (which also strengthens C1's fix), and either cite `Mathex` or drop it. |
| m6 | build | Style | Minor | 5 package warnings: `caption` reporting `hypcap=true` ignored, and `hyperref` "Ignoring empty anchor on input line 773" (the `\footnotetext` construction at `:771-773`). No overfull boxes — better than most CGNS CPEX drafts. | Give the footnote an explicit anchor or use `\footnotemark`/`\footnotetext` with a manual label. |
| s1 | `.tex:1937-1959` | Standards Compliance | Suggestion | The reader-validation list is a genuine strength — it is more specific than any other current CPEX. Two additions would close it: nothing validates that `LagrangeControlPoints` has `DataSize = [Dimension, N]` with `N` equal to the cardinality returned by `cg_*_lagrange_interpolation_size` for the declared type and order, and nothing validates `MonomialCoefficients` length against `cg_*_monomial_size`. Both are exactly checkable from data already in the file. | Add both as reader-rejection rules. |
| s2 | `.tex:669-675` | Clarity | Suggestion | Under `InterpolationPoints` with a point set, indices are element indices, and without one the block covers "every element of the zone in element order". As CPEX-0050's review established for its own ordering rule, "element order" needs anchoring: element numbering is global via each `Elements_t` section's `ElementRange`, and sections need not be stored in ascending `ElementRange` order. | State that the traversal is by ascending element index as determined by `ElementRange`, not by section storage order. This is the same correction CPEX-0050 applied to its §3.8.3, and the two should match. |
| s3 | `.tex:1583-1592` | Clarity | Suggestion | The v2-quote convention is effective but there is no legend explaining it. A reader encountering a shaded quote that contradicts the normative text (M6) has no way to know the shading means "approved v2 text, superseded below". | Add one sentence to the front matter defining the `v2quote` convention and stating that v3 annotations following a quote govern where they conflict. |

---

## Assessment Areas Key

| Area | Description |
|------|-------------|
| Technical Accuracy | Correctness of mathematics, domains, and claims about CGNS |
| Completeness | Cases and mechanics the specification leaves undefined |
| Standards Compliance | Conformance to CGNS conventions and the CPEX process checklist |
| Clarity | Precision and internal consistency |
| Cross-CPEX | Interaction with 0047 and 0050, both live at the same meeting |

---

## Detail on the Critical Findings

### C1 — The simplex domain, five ways

Every source except one agrees on the bi-unit simplex:

| Source | TRI domain |
|---|---|
| `figures/coord-tri.jpg` (Figure 1, normative) | vertices (−1,−1), (1,−1), (−1,1) ⇒ `u+v ≤ 0` |
| `.tex:2181` TRI test point (−0.5,−0.3) | inside bi-unit; outside unit |
| `.tex:585` `Equidistant` = `−1 + 2i/p` | `[−1,1]`-based |
| `.tex:571` `cgnscheck` rule | treats `[0,1]` as the *error* case |
| `highorder.rst:112` (published docs) | `{u ≥ −1, v ≥ −1, u+v ≤ 0}`, under "**Critical Interoperability Requirement**" |
| **`.tex:2059` §Coordinate-System Conventions** | **`{uᵢ ≥ 0, Σuᵢ ≤ 1}`** — the outlier |

The February 2026 documentation review (`CPEX45_review_findings.md`, F01–F04) found the RST stating
`u+v ≤ 1` against bi-unit vertices and recommended `u+v ≤ 0`. That recommendation was correct and
has been applied to the documentation. What was not done is reconciling §7.9 of the proposal, which
still carries a third, different convention. The fix is confined to that one paragraph.

Why it is critical rather than editorial: `.tex:2065` states plainly that "the library does *not*
enforce these ranges on user-supplied control points; any `double` value is accepted." There is
therefore no diagnostic. A writer that reads §7.9, emits TETRA control points in `[0,1]`, and a
reader that follows Figure 1 will exchange a file that is structurally valid, passes `cgnscheck`,
and is geometrically wrong.

### C2 — The TETRA test point is outside both domains

Bi-unit reference tetrahedron: vertices (−1,−1,−1), (1,−1,−1), (−1,1,−1), (−1,−1,1); the far face
is the plane `u+v+w = −1`; the interior satisfies `u+v+w < −1` (check: the vertex (−1,−1,−1) gives
−3). The stated point (−0.6, −0.2, −0.1) sums to **−0.9 > −1** — outside. Under the unit simplex it
fails `uᵢ ≥ 0` on all three coordinates — also outside.

This is independent of how C1 is resolved, which is why it is listed separately.

---

## What is solid

Recorded so it does not get re-litigated:

- **The mathematics that carries the standard is correct.** Verified by hand: `TRI` `N=(p+1)(p+2)/2`;
  `TETRA` `(p+1)(p+2)(p+3)/6`; `QUAD`/`HEXA` `(p+1)^d`; `PENTA` `(p+1)²(p+2)/2` as the stated tensor
  product; QUAD edge-serendipity `N=4p` (p=1→4, p=2→8, matching `QUAD_8`); the pyramid formula
  `(p+1)(p+2)(2p+3)/6` giving 5/14/30/55 for p=1..4. The February review's F06 — an ad-hoc pyramid
  formula that evaluated to 16 rather than 14 — is **not present** in this document; it uses the
  correct general formula.
- **The Pascal traversals are correct.** Both the 2-D and 3-D loops enumerate exactly the monomials
  of total degree ≤ p (exponents sum to the loop index `i`), and the counts agree with
  `binom(p+d, d)`. The space-time variants correctly reduce to the spatial case at `q=0`.
- **The order-means-degree convention** is stated explicitly, justified from v2's own wording, and
  applied consistently — this is D-03 and the document's position is well argued.
- **Element tags verified present** in `cgnslib.h`: `PYRA_30` (33), `PYRA_55` (50), `TETRA_35` (47),
  `QUAD_25`, `HEXA_125`. The claim that the pyramid cardinalities "consume" these tags is accurate.
- **`InterpolationPoints = 9` is the correct next free value**, and the wip branch implements the
  value, the count bump to 10, and the name-table entry.
- **`cgnscheck -s` exists** — `options[] = "vVuUw:es"` with the usage line "strict CPEX-0045
  high-order validation" on `CPEX45_high_order_wip`. My initial check against `develop` was the
  wrong baseline; the document's implementation-evidence claim is accurate.
- **The Chapter 12 renumbering is right**, verified against `misc.rst`: 12.6 `Family_t`, and 12.10 /
  12.11 currently `UserDefinedData_t` / `Gravity_t`, which is what the document says it displaces.
- **The precedence rule** — stored coordinates authoritative, distribution name advisory, reader
  must not silently substitute, mismatch is a warning not a rejection — is coherent, consistently
  applied across `LagrangeControlPointDistribution` and `CharacteristicLength`, and correctly
  reflected in C-03/C-04 of the decision register.
- **Reader validation, writer cross-validation, and error-code semantics** are more complete than in
  any other current CPEX draft, including the treatment of `CG_NODE_NOT_FOUND` as normal control
  flow and the requirement to exclude `CharacteristicLength` from the field list.
- **Build health**: 0 errors, 0 undefined references, 0 undefined citations, **0 overfull boxes**.

---

## Resolution Log

**C1 and C2 fixed** (2026-08-01). Build remains clean: 0 errors, 0 undefined references,
0 undefined citations, **0 overfull boxes**, 37 pp.

| ID | Resolution |
|----|-----------|
| C1 | §Coordinate-System Conventions rewritten to the bi-unit domains, with `TRI` and `TETRA` given explicitly (constraint *and* vertex list, so the two cannot drift apart again), `PENTA` defined by reference to the corrected `TRI`, and the tensor-product entry relabelled "bi-unit cube" (`[-1,1]^d` is not the unit cube). Adds a lead sentence stating that all elements use `[-1,1]` rather than `[0,1]`, and that Figure 1 is normative. The closing paragraph now states this as an interoperability requirement and explains *why* a `[0,1]` simplex convention is undetectable after the fact — the previous text mentioned non-enforcement without saying what it implied. |
| C2 | TETRA test point (−0.6,−0.2,−0.1) → **(−0.6,−0.5,−0.4)**, `u+v+w = −1.5 < −1`. All four points now carry their interiority condition inline, and the sentence states they are strictly interior to the domains of the corrected section. Verified programmatically: QUAD, HEXA, TRI and TETRA points are all strictly interior. |
| m2 | **Fixed.** The PYRA parametric domain is now stated inline --- `{-1 <= w <= 1, |u| <= (1-w)/2, |v| <= (1-w)/2}`, the square base `[-1,1]^2` at `w = -1` contracting to the apex `(0,0,1)` --- verified against `figures/coord-pyra.jpg` (apex vertex 5 on the `w` axis at `+1`, square base vertices 1-4 at `w = -1`) and matching `highorder.rst:153`. `[BCD10]` is retained for what it actually supplies, the non-polynomial functional space, with a cross-reference to the cardinality formula. Every element type now has an explicit domain. |
| m5 (part) | `HW08` is now cited, at the corrected reference-domain definition — its natural home. `CPEX0036`, `CPEX0038` and `Mathex` remain uncited. |

Added `\label{sec:coord-conventions}` so the compliance tests can point at the domain definitions.

**Not applied** — the remaining findings are unchanged and still open: M1 (the
`LagrangeControlPointDistribution_t` enumeration is voted on and implemented but never defined in
the document), M2, M3, M4, M5, M6, m1, m3, m4, m6, s1–s3.
