# LLMQuant/quant-mind  ·  ⭐1913  ·  watch  ·  emerging
https://github.com/LLMQuant/quant-mind · pushed 2026-06-04 · triaged 2026-07-08 · seen on user-submitted

**What it is:** LLM knowledge-extraction + retrieval framework for quant finance — ingests
papers/news/blogs/SEC filings → parser/tagger pipeline → semantic knowledge base →
RAG / DeepResearch / "Data MCP" retrieval. Python, MIT, NeurIPS 2025 GenAI-in-Finance
workshop paper. 1.9k stars in ~16 months but last push a month ago; roadmap-heavy README.

**Reusable for us:** Not the framework itself (embeddings + knowledge-graph stack is far
heavier than the tradingdesk datalake needs at a 34-symbol universe). Transferable bits:
(a) the two-stage decoupled architecture (extract→store vs retrieve) matches what the
tradingdesk datalake already does — validates the design; (b) their parser/tagger
prompt patterns for financial-text tagging could inform the MX news tagger; (c) the
"Data MCP" retrieval scenario is a pattern to steal if the datalake ever grows a
query interface for agents.

**Token / effectiveness angle:** Negative if adopted wholesale — a fine-tuned-LLM +
embedding pipeline is a cost center; our thrift posture (Max subscription, `claude -p`)
argues against it. Positive only as design reference.

**How to adopt:** Watch. Re-check if (1) the tradingdesk datalake needs semantic/RAG
retrieval over accumulated news for the model-analysis loop, or (2) they ship the Data
MCP as a standalone server worth mounting. No install now.
