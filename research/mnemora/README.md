# Mnemora

## Learnable Memory Policies for Continual AGI Agents

> **Research question:** Can an intelligent agent learn what is worth remembering?

Mnemora investigates memory as a **learned cognitive control problem** rather than a fixed vector database. The project studies whether an agent can learn when to retain, compress, discard, and retrieve information according to downstream utility.

## Why this matters

Most practical agent memory systems separate storage and reasoning: information is written into a store, then retrieved with a fixed similarity rule. This is useful, but it leaves a deeper question open:

**What should an agent remember when its future needs are unknown?**

A general-purpose system faces bounded context, noisy observations, changing goals, distribution shift, and interference between old and new knowledge. Memory therefore becomes a sequential decision problem.

## Hypothesis

A memory controller trained against downstream utility can outperform fixed top-k retrieval and simple heuristic policies under the same memory budget, especially on long-horizon tasks and distribution shifts.

## Research model

The initial prototype compares three families:

1. **Static retrieval** — embedding similarity + top-k retrieval.
2. **Heuristic memory** — importance/recency-based retention and retrieval.
3. **Learnable memory policy** — a controller that predicts the expected future utility of storing, compressing, forgetting, or retrieving an item.

### Memory lifecycle

```text
Observation
    ↓
Candidate Memory
    ↓
┌──────────────────────────────┐
│ Learned Memory Controller    │
│                              │
│ retain / compress / forget   │
│ retrieve / defer             │
└──────────────────────────────┘
    ↓
Bounded Memory Store
    ↓
Task Context → Agent Action
    ↓
Outcome / Utility Signal
    ↺
Controller Update
```

## Evaluation

The project will measure:

| Metric | Question |
|---|---|
| Long-horizon retention | Can useful information survive many interactions? |
| Memory efficiency | How much useful information fits inside a fixed budget? |
| Retrieval precision | Are retrieved memories actually useful? |
| Retrieval recall | Are important memories recoverable? |
| Forgetting | Does the system discard information that later becomes important? |
| Interference | Does new information damage old capabilities? |
| Adaptation | Does memory behavior improve after distribution shift? |
| Operation cost | How much compute is spent per useful memory operation? |

## Experimental design

The first benchmark should use synthetic sequential tasks before moving to realistic agent workloads. Each episode exposes the agent to facts, instructions, distractors, and delayed queries. The useful information is deliberately separated from the moment at which it becomes relevant.

The central variable is the **memory budget**. Policies are evaluated at equal storage and retrieval budgets so that gains cannot simply come from storing more information.

## Core experiment

For each episode:

1. Stream observations to the agent.
2. Allow the memory policy to decide what to store.
3. Apply a strict memory budget.
4. Introduce delayed queries requiring earlier information.
5. Measure answer quality and memory operations.
6. Repeat under changed task distributions.
7. Compare policies across multiple random seeds.

## Expected contribution

The goal is not to claim AGI from a memory module. The goal is to establish a reproducible experimental framework for studying one component that may matter for more general intelligence: **adaptive, utility-driven long-term memory**.

## Research principles

- Reproducibility over demos
- Ablations over anecdotes
- Equal budgets for fair comparisons
- Explicit uncertainty about conclusions
- Small experiments before large models
- Open benchmarks and failure cases

## Roadmap

- [ ] Formalize memory-policy objective
- [ ] Implement static retrieval baseline
- [ ] Implement heuristic baseline
- [ ] Implement learnable controller
- [ ] Build bounded-memory benchmark
- [ ] Add distribution-shift evaluation
- [ ] Run ablation studies
- [ ] Publish results and failure analysis
- [ ] Test with open-weight language models

## Status

**Stage:** Research proposal / initial implementation

This repository is an ongoing research experiment. Results should be treated as empirical findings rather than evidence of AGI.

## License

TBD — licensing will be selected before external reuse of implementation code.
