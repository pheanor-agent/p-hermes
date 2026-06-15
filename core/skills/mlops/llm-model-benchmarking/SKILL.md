---
name: llm-model-benchmarking
description: Framework for comparing and validating multiple LLMs across specific capabilities (reasoning, coding, multilingual, tool-calling).
---

# LLM Model Benchmarking Workflow

This skill defines a systematic approach to compare two or more LLMs to determine the optimal model for specific task categories.

## 1. Benchmarking Process

### Phase 1: Metric Definition
Define a capability matrix to avoid generic "which is better" conclusions. 
- **Reasoning**: Logical puzzles, mathematical proofs, paradox resolution.
- **Tool-calling**: API orchestration, JSON schema adherence, multi-step planning.
- **Coding**: Algorithm implementation, refactoring, bug detection.
- **Multilingual**: Cultural nuance translation, cross-lingual retrieval.
- **General**: Instruction following, verbosity control, speed.

### Phase 2: Prompt Engineering (Killer Prompts)
Create "Killer Prompts" that are designed to fail on average models but succeed on specialized ones.
- Avoid simple Q&A.
- Use constraints (e.g., "Answer in exactly 3 sentences, starting with a question").
- Use complex logic (e.g., Einstein's Riddle variants).

### Phase 3: Execution (Cross-Testing)
1. Set Model A as default $\rightarrow$ Run all prompts $\rightarrow$ Save results to `model_a_results.md`.
2. Set Model B as default $\rightarrow$ Run all prompts $\rightarrow$ Save results to `model_b_results.md`.
3. Ensure identical temperature (preferably 0) and parameters for consistency.

### Phase 4: Evaluation & Analysis
- **Binary (Pass/Fail)**: For coding and logic puzzles.
- **Qualitative (1-5)**: For nuance and style.
- **Comparison**: Side-by-side analysis of the reasoning trace.

## 2. Pitfalls & Lessons Learned

- **API Masking**: When using scripts to call models via `curl` or API, be mindful of API key masking in logs which can lead to authentication failures if the script doesn't handle tokens securely.
- **Shell Quoting**: Complex prompts with quotes/newlines often break shell commands. Use `shlex.quote()` in Python or heredocs in bash to prevent `unexpected EOF` errors.
- **Model State**: Always verify the active model via `hermes config show` before starting a batch run to prevent mixing results.

## 3. Model Selection Guide (Template)
Final output should be a matrix:
| Scenario | Primary Model | Fallback | Reason |
| :--- | :--- | :--- | :--- |
| Complex Logic | [Model X] | [Model Y] | Better reasoning trace |
| Python Coding | [Model Y] | [Model X] | Higher accuracy in O(n) tasks |
