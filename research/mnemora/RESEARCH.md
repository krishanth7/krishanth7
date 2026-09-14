# Research Specification

## 1. Problem

Long-context and retrieval-augmented agents can access large quantities of information, but access alone does not define a useful memory system. A continual agent must decide which observations deserve persistent representation when future relevance is uncertain.

Mnemora frames this as a sequential decision problem under a bounded memory budget.

## 2. Formalization

At time `t`, an agent observes `x_t` and maintains memory state `M_t` with capacity `B`.

The controller chooses an operation `a_t` from:

`{store, compress, update, forget, retrieve, defer}`

The objective is to maximize downstream task utility while penalizing memory and retrieval cost:

`J = E[U_task - λ_storage C_storage - λ_retrieval C_retrieval]`

The key difficulty is delayed credit assignment: the utility of a memory item may only become observable many steps after it was stored.

## 3. Baselines

### B0 — No persistent memory

The agent only receives the current context window.

### B1 — Top-k semantic retrieval

Store observations as embeddings and retrieve the nearest `k` items for each query.

### B2 — Recency + importance heuristic

Rank memories using a weighted combination of recency, estimated importance, and access frequency.

### B3 — Learnable controller

Train a policy to estimate expected downstream utility of memory operations.

## 4. Benchmark dimensions

### Horizon

Short: 10–25 steps

Medium: 50–100 steps

Long: 250+ steps

### Memory budget

Evaluate several fixed budgets so that methods cannot win by retaining unlimited context.

### Distribution shift

Train and test task distributions should differ in vocabulary, distractor frequency, query delay, and relevance patterns.

### Interference

Introduce conflicting or superseded facts to test whether the controller can update representations instead of accumulating contradictory memories.

## 5. Primary hypotheses

**H1:** Learned memory policies improve delayed-query accuracy at equal memory budgets.

**H2:** Learned policies reduce unnecessary memory operations while preserving important information.

**H3:** Adaptive policies degrade more gracefully than static retrieval under distribution shift.

**H4:** The largest gains appear at long horizons where fixed recency/similarity heuristics become unreliable.

## 6. Required ablations

- Remove compression.
- Remove forgetting.
- Remove delayed utility signal.
- Replace learned controller with random policy.
- Vary memory budget.
- Vary query delay.
- Vary distractor density.
- Disable distribution-shift training.

## 7. Failure analysis

Every reported improvement should be accompanied by examples where the policy:

- stored irrelevant information,
- forgot information that later became useful,
- retrieved a semantically similar but causally irrelevant memory,
- preserved contradictory information,
- or spent excessive compute deciding what to remember.

## 8. Scientific standard

A positive result is only meaningful if it survives multiple seeds, fixed evaluation budgets, baseline tuning, and ablations. If the learned policy does not outperform simple baselines, that result is still valuable: it identifies conditions under which adaptive memory is unnecessary or poorly specified.

## 9. Future direction

If the small-scale benchmark produces robust results, the next stage can test the memory controller with open-weight language models and tool-using agents. The research should then examine whether learned memory policies improve planning, multi-step tool use, and cross-session task continuity.
