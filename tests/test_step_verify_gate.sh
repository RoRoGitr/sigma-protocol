#!/usr/bin/env bash
# Test: step-verify-gate.cjs Stop hook. Synthetic step transcripts + a temp project cwd whose
# output files exist or don't, asserting advisory/blocking/allow per the contract.
set -u
HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.claude/hooks/step-verify-gate.cjs"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export STEP_VERIFY_GATE_CACHE_DIR="$TMP/cache"   # hermetic loop-guard
pass=0; fail=0
ok(){ echo "  ✅ $1"; pass=$((pass+1)); }
no(){ echo "  ❌ $1"; fail=$((fail+1)); }

# Build a transcript fixture. $1=outfile $2=mode. The verification block varies by mode.
mkfix(){
python3 - "$1" "$2" <<'PY'
import json,sys
out,mode=sys.argv[1],sys.argv[2]
HEAD="# /step-1-ideation — Ideation\n"
def vt(rows_md):  # wrap a verification block
    return HEAD+"<verification>\n"+rows_md+"\n</verification>\n$END$"
BLK={
 "pass":      vt("| Item | Path | Points |\n|---|---|---|\n| PRD | docs/out.md | 10 |"),
 "advisory":  vt("| Item | Path | Points |\n|---|---|---|\n| PRD | docs/out.md | 10 |"),
 "enforce":   vt("| Item | Path | Points |\n|---|---|---|\n| PRD | docs/out.md | 10 |"),
 "glob_pass": vt("| Item | Path | Points |\n|---|---|---|\n| Screens | docs/screens/*.html | 8 |"),
 "glob_fail": vt("| Item | Path | Points |\n|---|---|---|\n| Screens | docs/screens/*.html | 8 |"),
 "minsize":   vt("| File | Path | Min Size | Points |\n|---|---|---|---|\n| PRD | docs/out.md | 4KB | 10 |"),
 "section":   vt("dummy\n<VERIFY-ASSERT>\nsection_has docs/out.md \"Problem Statement\"\n</VERIFY-ASSERT>"),
 "track":     vt("| Track | Item | Path | Points |\n|---|---|---|---|\n| A | Bundle | docs/bundle.md | 5 |"),
 "or_pass":   vt("| Item | Path | Points |\n|---|---|---|\n| Out | docs/a.md OR docs/b.md | 5 |"),
 "loop":      vt("| Item | Path | Points |\n|---|---|---|\n| PRD | docs/out.md | 10 |"),
 "off":       vt("| Item | Path | Points |\n|---|---|---|\n| PRD | docs/out.md | 10 |"),
 "cmd":       vt("dummy\n<VERIFY-ASSERT>\ncmd_exit0 node scripts/verify/nope.mjs\n</VERIFY-ASSERT>"),
 "craft_clean": vt("dummy\n<VERIFY-ASSERT>\ncraft_antislop docs/out.html\n</VERIFY-ASSERT>"),
 "craft_placeholder": vt("dummy\n<VERIFY-ASSERT>\ncraft_antislop docs/out.html\n</VERIFY-ASSERT>"),
 "div_missing": vt("dummy\n<VERIFY-ASSERT>\ndivergence_proof docs/design\n</VERIFY-ASSERT>"),
 "div_ok":      vt("dummy\n<VERIFY-ASSERT>\ndivergence_proof docs/design\n</VERIFY-ASSERT>"),
 "dna_missing_std":  vt("dummy\n<VERIFY-ASSERT>\ndna_conformance docs/out.html\n</VERIFY-ASSERT>"),
 "dna_conforms":     vt("dummy\n<VERIFY-ASSERT>\ndna_conformance docs/out.html\n</VERIFY-ASSERT>"),
 "dna_violates":     vt("dummy\n<VERIFY-ASSERT>\ndna_conformance docs/out.html\n</VERIFY-ASSERT>"),
}
if mode=="nostep":
    content="just discussing a step, no command header\n<verification>\n| Item | Path | Points |\n|---|---|---|\n| X | docs/out.md | 1 |\n</verification>"
elif mode=="noslash":
    content="# step-1-ideation — a DISCUSSED heading (no command slash)\n<verification>\n| Item | Path | Points |\n|---|---|---|\n| X | docs/out.md | 1 |\n</verification>"
elif mode=="failopen":
    content=None
else:
    content=BLK[mode]
rows=[]
if mode=="failopen":
    pass  # write garbage below
else:
    rows=[{"type":"user","message":{"content":content}},{"type":"assistant","message":{"content":[{"type":"text","text":"done"}]}}]
with open(out,"w") as f:
    if mode=="failopen": f.write("not json at all\n{broken")
    else:
        for r in rows: f.write(json.dumps(r)+"\n")
PY
}

# run: $1=transcript $2=session $3=proj-cwd  (extra env via caller)
run(){ printf '{"transcript_path":"%s","session_id":"%s","cwd":"%s"}' "$1" "$2" "$3" | node "$HOOK" 2>/dev/null; }

echo "TEST step-verify-gate"
P="$TMP/proj"

# 1. all output present -> ALLOW
rm -rf "$P"; mkdir -p "$P/docs"; echo "content" > "$P/docs/out.md"
f="$TMP/pass.jsonl"; mkfix "$f" pass; o=$(run "$f" s1 "$P")
[ -z "$o" ] && ok "all outputs present -> allow" || no "pass -> expected allow; got: $o"

# 2. missing output, advisory (default) -> systemMessage, NOT block
rm -rf "$P"; mkdir -p "$P/docs"
f="$TMP/adv.jsonl"; mkfix "$f" advisory; o=$(run "$f" s2 "$P")
{ echo "$o" | grep -q 'systemMessage' && ! echo "$o" | grep -q '"decision":"block"'; } \
  && ok "missing output advisory -> systemMessage, no block" || no "advisory -> expected systemMessage no-block; got: $o"

# 3. missing output, ENFORCE -> block naming the path
rm -rf "$P"; mkdir -p "$P/docs"
f="$TMP/enf.jsonl"; mkfix "$f" enforce
o=$(printf '{"transcript_path":"%s","session_id":"%s","cwd":"%s"}' "$f" s3 "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
{ echo "$o" | grep -q '"decision":"block"' && echo "$o" | grep -q 'docs/out.md'; } \
  && ok "missing output + enforce -> block names path" || no "enforce -> expected block w/ path; got: $o"

# 4. glob with a matching file -> ALLOW
rm -rf "$P"; mkdir -p "$P/docs/screens"; echo x > "$P/docs/screens/a.html"
f="$TMP/gp.jsonl"; mkfix "$f" glob_pass; o=$(run "$f" s4 "$P")
[ -z "$o" ] && ok "glob match present -> allow" || no "glob_pass -> expected allow; got: $o"

# 5. glob with NO match, enforce -> block
rm -rf "$P"; mkdir -p "$P/docs/screens"
f="$TMP/gf.jsonl"; mkfix "$f" glob_fail
o=$(printf '{"transcript_path":"%s","session_id":"%s","cwd":"%s"}' "$f" s5 "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
echo "$o" | grep -q '"decision":"block"' && ok "glob no-match + enforce -> block" || no "glob_fail -> expected block; got: $o"

# 6. min-size: file below threshold, enforce -> block; padded -> allow
rm -rf "$P"; mkdir -p "$P/docs"; echo "tiny" > "$P/docs/out.md"
f="$TMP/ms.jsonl"; mkfix "$f" minsize
o=$(printf '{"transcript_path":"%s","session_id":"%s","cwd":"%s"}' "$f" s6 "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
echo "$o" | grep -q '"decision":"block"' && ok "min-size too small + enforce -> block" || no "minsize -> expected block; got: $o"
head -c 5000 /dev/zero | tr '\0' 'x' > "$P/docs/out.md"
o=$(run "$f" s6b "$P"); [ -z "$o" ] && ok "min-size padded -> allow" || no "minsize padded -> expected allow; got: $o"

# 7. section_has missing heading, enforce -> block
rm -rf "$P"; mkdir -p "$P/docs"; echo "# Other Heading" > "$P/docs/out.md"
f="$TMP/sec.jsonl"; mkfix "$f" section
o=$(printf '{"transcript_path":"%s","session_id":"%s","cwd":"%s"}' "$f" s7 "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
echo "$o" | grep -q '"decision":"block"' && ok "section_has absent + enforce -> block" || no "section -> expected block; got: $o"

# 8. track-column table (soft) missing file, enforce -> still ALLOW
rm -rf "$P"; mkdir -p "$P/docs"
f="$TMP/trk.jsonl"; mkfix "$f" track
o=$(printf '{"transcript_path":"%s","session_id":"%s","cwd":"%s"}' "$f" s8 "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
[ -z "$o" ] && ok "track-soft missing + enforce -> allow (soft)" || no "track -> expected allow; got: $o"

# 9. OR row with one arm present -> ALLOW
rm -rf "$P"; mkdir -p "$P/docs"; echo y > "$P/docs/b.md"
f="$TMP/or.jsonl"; mkfix "$f" or_pass; o=$(run "$f" s9 "$P")
[ -z "$o" ] && ok "OR row one arm present -> allow" || no "or_pass -> expected allow; got: $o"

# 10. loop-guard: enforce + missing, 3x same session+step -> block,block,allow
rm -rf "$P"; mkdir -p "$P/docs"
f="$TMP/loop.jsonl"; mkfix "$f" loop
b1=$(printf '{"transcript_path":"%s","session_id":"sL","cwd":"%s"}' "$f" "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
b2=$(printf '{"transcript_path":"%s","session_id":"sL","cwd":"%s"}' "$f" "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
b3=$(printf '{"transcript_path":"%s","session_id":"sL","cwd":"%s"}' "$f" "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
{ echo "$b1" | grep -q block && echo "$b2" | grep -q block && [ -z "$b3" ]; } \
  && ok "loop-guard enforce -> block,block,allow" || no "loop -> expected block,block,allow; got [$b1|$b2|$b3]"

# 11. OFF override -> allow despite missing
rm -rf "$P"; mkdir -p "$P/docs"
f="$TMP/off.jsonl"; mkfix "$f" off
o=$(printf '{"transcript_path":"%s","session_id":"sO","cwd":"%s"}' "$f" "$P" | STEP_VERIFY_GATE_ENFORCE=1 STEP_VERIFY_GATE_OFF=1 node "$HOOK" 2>/dev/null)
[ -z "$o" ] && ok "STEP_VERIFY_GATE_OFF=1 -> allow" || no "off -> expected allow; got: $o"

# 12. no command header (quoted discussion) -> ALLOW (no false-positive)
f="$TMP/ns.jsonl"; mkfix "$f" nostep
o=$(printf '{"transcript_path":"%s","session_id":"sN","cwd":"%s"}' "$f" "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
[ -z "$o" ] && ok "no command header -> allow (no false-positive)" || no "nostep -> expected allow; got: $o"

# 13. cmd_exit0 without STEP_VERIFY_ALLOW_CMD -> skipped (only assertion) -> ALLOW even under enforce
rm -rf "$P"; mkdir -p "$P"
f="$TMP/cmd.jsonl"; mkfix "$f" cmd
o=$(printf '{"transcript_path":"%s","session_id":"sC","cwd":"%s"}' "$f" "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
[ -z "$o" ] && ok "cmd_exit0 disabled -> skipped -> allow" || no "cmd -> expected allow; got: $o"

# 14. fail-open: garbage transcript -> ALLOW (no crash)
f="$TMP/bad.jsonl"; mkfix "$f" failopen
o=$(run "$f" sB "$P"); [ -z "$o" ] && ok "garbage transcript -> allow (fail-open)" || no "failopen -> expected allow; got: $o"

# 15. C1a craft_antislop: clean output -> ALLOW
rm -rf "$P"; mkdir -p "$P/docs"; printf '<style>font-family: "Sohne", serif; color:#0a3d2a</style><h1>Real Product</h1>' > "$P/docs/out.html"
f="$TMP/cc.jsonl"; mkfix "$f" craft_clean; o=$(run "$f" sCC "$P")
[ -z "$o" ] && ok "craft_antislop clean -> allow" || no "craft_clean -> expected allow; got: $o"

# 16. C1a craft_antislop: intentional familiar styles are allowed; only unfinished placeholders block
rm -rf "$P"; mkdir -p "$P/docs"; printf '<style>font-family: Inter, sans-serif; color:#7c3aed; display:grid; grid-template-columns:1fr 1fr 1fr</style><a>Get Started</a>' > "$P/docs/out.html"
f="$TMP/cd.jsonl"; mkfix "$f" craft_clean
o=$(printf '{"transcript_path":"%s","session_id":"sCD","cwd":"%s"}' "$f" "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
[ -z "$o" ] && ok "craft_antislop intentional styles -> allow" || no "craft styles -> expected allow; got: $o"

printf '<main><h1>Project board</h1><section><h2>Todo</h2><article>Review proposal</article></section></main>' > "$P/docs/out.html"
o=$(printf '{"transcript_path":"%s","session_id":"sTodoUI","cwd":"%s"}' "$f" "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
[ -z "$o" ] && ok "craft_antislop legitimate Todo UI -> allow" || no "Todo UI -> expected allow; got: $o"

printf '<main><!-- TODO: implement account form --></main>' > "$P/docs/out.html" # stub-ok: fixture asserting the gate blocks a real TODO marker
o=$(printf '{"transcript_path":"%s","session_id":"sTodoMarker","cwd":"%s"}' "$f" "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
echo "$o" | grep -q '"decision":"block"' && ok "craft_antislop unfinished comment -> block" || no "TODO marker -> expected block; got: $o"

rm -rf "$P"; mkdir -p "$P/docs"; printf '<h1>[placeholder: product name]</h1>' > "$P/docs/out.html"
f="$TMP/cp.jsonl"; mkfix "$f" craft_placeholder
o=$(printf '{"transcript_path":"%s","session_id":"sCP","cwd":"%s"}' "$f" "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
{ echo "$o" | grep -q '"decision":"block"' && echo "$o" | grep -qi 'placeholder'; } \
  && ok "craft_antislop placeholder + enforce -> block" || no "craft placeholder -> expected block; got: $o"

# 17. C1a divergence_proof: missing DNA-REFERENCES.md + enforce -> block
rm -rf "$P"; mkdir -p "$P/docs/design"
f="$TMP/dm.jsonl"; mkfix "$f" div_missing
o=$(printf '{"transcript_path":"%s","session_id":"sDM","cwd":"%s"}' "$f" "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
echo "$o" | grep -q '"decision":"block"' && ok "divergence_proof missing refs + enforce -> block" || no "div_missing -> expected block; got: $o"

# 18. C1a divergence_proof: complete proof -> ALLOW
rm -rf "$P"; mkdir -p "$P/docs/design"
printf '# DNA References\n- https://awwwards.com/x (2025-03)\n- https://godly.website/y\n- https://mobbin.com/z\n## Direction 1: Tidewater\n## Direction 2: Foundry\nChosen direction: Tidewater\n' > "$P/docs/design/DNA-REFERENCES.md"
f="$TMP/do.jsonl"; mkfix "$f" div_ok
o=$(printf '{"transcript_path":"%s","session_id":"sDO","cwd":"%s"}' "$f" "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
[ -z "$o" ] && ok "divergence_proof complete -> allow" || no "div_ok -> expected allow; got: $o"

# 20. no-slash header ("# step-N" discussed, not "# /step-N" command) -> ALLOW (codex review finding)
f="$TMP/nsl.jsonl"; mkfix "$f" noslash
o=$(printf '{"transcript_path":"%s","session_id":"sNSL","cwd":"%s"}' "$f" "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
[ -z "$o" ] && ok "no-slash header -> allow (codex false-positive fix)" || no "noslash -> expected allow; got: $o"

# 21. C1b dna_conformance: .sigma/standards.json missing -> advisory skip (not a fail) even under enforce
rm -rf "$P"; mkdir -p "$P/docs"
printf '<style>font-family: Inter, sans-serif;</style>' > "$P/docs/out.html"
f="$TMP/dna_ms.jsonl"; mkfix "$f" dna_missing_std
o=$(printf '{"transcript_path":"%s","session_id":"sDNAms","cwd":"%s"}' "$f" "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
[ -z "$o" ] && ok "dna_conformance: missing standards.json -> advisory skip (allow)" || no "dna_missing_std -> expected allow (skip); got: $o"

# 22. C1b dna_conformance: explicit standards constraint + intentional familiar styles -> ALLOW
rm -rf "$P"; mkdir -p "$P/.sigma" "$P/docs"
printf '{"version":1,"awardStandard":true,"qualityBar":"95+/100","dnaName":"Machined Slate","dnaDoc":"docs/design/machined-slate-DNA.md","uiProfile":"docs/design/ui-profile.json","antiSlopRules":["No rounded cards — use the approved sharp-corner component language"],"generatedAt":"2026-06-15T00:00:00Z"}' > "$P/.sigma/standards.json"
printf '<style>font-family: Inter, sans-serif; color: #7c3aed; display:grid; grid-template-columns:1fr 1fr 1fr</style><h1>Actual Product Copy</h1>' > "$P/docs/out.html"
f="$TMP/dna_ok.jsonl"; mkfix "$f" dna_conforms
o=$(printf '{"transcript_path":"%s","session_id":"sDNAok","cwd":"%s"}' "$f" "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
[ -z "$o" ] && ok "dna_conformance: standards.json present + clean output -> allow" || no "dna_conforms -> expected allow; got: $o"

# 23. C1b dna_conformance: explicit DNA constraint still fails under enforce
rm -rf "$P"; mkdir -p "$P/.sigma" "$P/docs"
printf '{"version":1,"awardStandard":true,"qualityBar":"95+/100","dnaName":"Machined Slate","dnaDoc":"docs/design/machined-slate-DNA.md","uiProfile":null,"antiSlopRules":["No Inter/Roboto/Arial/Helvetica as primary font-family — use the DNA typography invariant"],"generatedAt":"2026-06-15T00:00:00Z"}' > "$P/.sigma/standards.json"
printf '<style>font-family: Inter, sans-serif;</style><h1>Actual Product Copy</h1>' > "$P/docs/out.html"
f="$TMP/dna_vio.jsonl"; mkfix "$f" dna_violates
o=$(printf '{"transcript_path":"%s","session_id":"sDNAvio","cwd":"%s"}' "$f" "$P" | STEP_VERIFY_GATE_ENFORCE=1 node "$HOOK" 2>/dev/null)
{ echo "$o" | grep -q '"decision":"block"' && echo "$o" | grep -qi 'DNA\|violation\|conformance\|Inter\|AI-purple'; } \
  && ok "dna_conformance: violation present + enforce -> block names violation" || no "dna_violates -> expected block w/ violation detail; got: $o"

echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
